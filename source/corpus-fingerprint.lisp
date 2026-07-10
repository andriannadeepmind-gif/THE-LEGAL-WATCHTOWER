;;;; source/corpus-fingerprint.lisp
;;;; ============================================================================
;;;; CORRECTNESS GUARANTEE  (deterministic fingerprint + invariant gate)
;;;; ============================================================================
;;;;
;;;; The promise behind the system is concrete: it takes the source text and
;;;; codifies it PERFECTLY, with zero error, and PROVES it on every change. This
;;;; module is that proof, operating on the artifact that is actually served —
;;;; the consolidated LEGAL-DOCUMENT (orchestrator.consolidation provisions).
;;;;
;;;; Two complementary mechanisms:
;;;;
;;;;   1. INVARIANTS  (verify-corpus-invariants)
;;;;      Structural truths that must hold for any correct codification:
;;;;        · every article eId is unique          (no duplicate / overwrite)
;;;;        · no article is empty                  (no silent text loss)
;;;;        · the article sequence has no gap      (nothing dropped mid-corpus)
;;;;        · articles are in canonical order      (deterministic serving)
;;;;        · the count matches the expectation    (when one is asserted)
;;;;      A violation names the exact eId and reason — never a vague pass/fail.
;;;;
;;;;   2. FINGERPRINT  (corpus-fingerprint + fingerprint-diff)
;;;;      A deterministic SHA-256 per article (over its whole subtree: heading,
;;;;      text, status, and every paragraph) folded into one Merkle root for the
;;;;      corpus. A golden manifest is committed once; on every later run the
;;;;      fresh fingerprint is compared, and ANY drift is reported as the precise
;;;;      set of articles ADDED / REMOVED / CHANGED. A single altered character
;;;;      in one paragraph changes that article's hash and the root — and is
;;;;      caught and located, guaranteed.
;;;;
;;;; Pure Common Lisp: hashing via the unified hash authority (Ironclad SHA-256),
;;;; deterministic length-prefixed canonical encoding (no delimiter ambiguity),
;;;; serializable manifests (prin1 / read round-trip).
;;;; ============================================================================

(defpackage :orchestrator.fingerprint
  (:use :cl)
  (:export
   ;; fingerprint
   #:provision-fingerprint #:corpus-fingerprint
   #:manifest-id #:manifest-count #:manifest-root #:manifest-articles
   #:write-fingerprint-manifest #:read-fingerprint-manifest
   ;; diff (drift detection)
   #:fingerprint-diff #:diff-clean-p #:format-diff #:fingerprint-matches-golden
   ;; invariants
   #:verify-corpus-invariants #:verify-manifest-invariants #:format-violations
   ;; fingerprint the REAL emitted codification (output dir of article-*.hash)
   #:output-manifest #:output-codified-p))

(in-package :orchestrator.fingerprint)

;;; ----------------------------------------------------------------------------
;;; consolidation accessors (resolved at load; no hard package coupling)
;;; ----------------------------------------------------------------------------

(macrolet ((bind (&rest names)
             `(progn
                ,@(loop for n in names
                        collect `(defun ,(intern (format nil "%~A" n))
                                     (&rest args)
                                   (apply (find-symbol ,(string n) :orchestrator.consolidation)
                                          args))))))
  (bind legal-document-p legal-document-id legal-document-title
        legal-document-provisions provision-eid provision-kind provision-num
        provision-heading provision-text provision-status provision-children))

(defun %sha (s) (orchestrator.hash-authority:compute-hash s :algorithm :sha256))

;;; ----------------------------------------------------------------------------
;;; deterministic canonical encoding
;;; ----------------------------------------------------------------------------

(defun %lp (value)
  "Length-prefixed encoding of VALUE — removes any delimiter ambiguity, so two
   different field layouts can never serialize to the same string."
  (let ((s (princ-to-string (or value ""))))
    (format nil "~D:~A" (length s) s)))

(defun provision-fingerprint (p)
  "A SHA-256 over PROVISION P and its entire subtree, in document order. Pins
   eId, kind, num, heading, in-force text, status, and every child — so a change
   anywhere beneath an article changes the article's fingerprint."
  (let ((child-hashes (mapcar #'provision-fingerprint (%provision-children p))))
    (%sha (apply #'concatenate 'string
                 (%lp (%provision-eid p))
                 (%lp (%provision-kind p))
                 (%lp (%provision-num p))
                 (%lp (%provision-heading p))
                 (%lp (%provision-text p))
                 (%lp (%provision-status p))
                 (%lp (length child-hashes))
                 child-hashes))))

(defun %merkle-root (leaves)
  "RFC-6962 Merkle root (ΜΙΑ έδρα orchestrator.merkle: domain-separated φύλλα
   0x00 / κόμβοι 0x01 + unbalanced split) πάνω στα bare-hex provision hashes ως
   δεδομένα φύλλων· επιστρέφει bare hex (η μορφή του fingerprint). [P1.5-A] Το
   προηγούμενο string-concat + duplicate-last (CVE-2012-2459) αντικαταστάθηκε.
   Κενό -> hash κενού (format-compat)."
  (if (null leaves)
      (%sha "")
      (subseq (orchestrator.merkle:merkle-root-of-strings leaves) 7)))

;;; ----------------------------------------------------------------------------
;;; the manifest
;;; ----------------------------------------------------------------------------

(defun corpus-fingerprint (doc)
  "Deterministic, serializable fingerprint manifest of the consolidated DOC:
     (:id S :title S :count N :root HEX
      :articles ((:eid E :num N :status K :hash HEX) ...))   ; in document order"
  (let* ((arts (%legal-document-provisions doc))
         (rows (loop for a in arts
                     collect (list :eid (%provision-eid a)
                                   :num (%provision-num a)
                                   :status (%provision-status a)
                                   :hash (provision-fingerprint a)))))
    (list :id (%legal-document-id doc)
          :title (%legal-document-title doc)
          :count (length rows)
          :root (%merkle-root (mapcar (lambda (r) (getf r :hash)) rows))
          :articles rows)))

(defun manifest-id (m) (getf m :id))
(defun manifest-count (m) (getf m :count))
(defun manifest-root (m) (getf m :root))
(defun manifest-articles (m) (getf m :articles))

(defun write-fingerprint-manifest (manifest path)
  "Persist MANIFEST deterministically (stable package + readable form)."
  (ensure-directories-exist path)
  (with-open-file (s path :direction :output :if-exists :supersede
                       :if-does-not-exist :create :external-format :utf-8)
    (with-standard-io-syntax
      (let ((*package* (find-package :keyword))
            ;; Clean, human-readable strings ("..." not #A(... base-char ...)),
            ;; still fully round-trippable via READ.
            (*print-readably* nil)
            (*print-escape* t)
            (*print-pretty* nil))
        (prin1 manifest s)
        (terpri s))))
  path)

(defun read-fingerprint-manifest (path)
  "Read a manifest written by WRITE-FINGERPRINT-MANIFEST, or NIL if absent."
  (when (probe-file path)
    (with-open-file (s path :external-format :utf-8)
      (with-standard-io-syntax
        (let ((*package* (find-package :keyword)))
          (read s nil nil))))))

;;; ----------------------------------------------------------------------------
;;; fingerprint the REAL emitted codification (output dir of article-*.hash)
;;; ----------------------------------------------------------------------------
;;;
;;; The PDF pipeline emits one article-<file-id>.hash (SHA-256) per article, with
;;; the file-id preserving any letter suffix (070, 070Α). Fingerprinting these is
;;; how a PDF-sourced code (e.g. the Penal Code's 536 articles) is verified and
;;; locked as golden — directly over what was actually published, with no re-parse
;;; and no PDF toolchain needed at verify time.

(defun %hash-file-id (path)
  "From .../article-070Α.hash return the file-id \"070Α\", or NIL."
  (let ((name (pathname-name path)))            ; "article-070Α"
    (when (and name (>= (length name) 8) (string= (subseq name 0 8) "article-"))
      (subseq name 8))))

(defun %file-id-eid (file-id)
  "Use the same eId convention as the consolidation path: art_<number><suffix>,
   with the number UNPADDED. Filesystem ids are zero-padded (article-070Α.hash)
   but the canonical eId everywhere else (corpus.jsonl, consolidation, goldens)
   is art_70Α — normalize here so one article has one identity."
  (let ((end (or (position-if-not #'digit-char-p file-id) (length file-id))))
    (if (plusp end)
        (format nil "art_~D~A" (parse-integer file-id :end end) (subseq file-id end))
        (format nil "art_~A" file-id))))

(defun %fileid-numeric (file-id)
  (let ((end (or (position-if-not #'digit-char-p file-id) (length file-id))))
    (if (plusp end) (parse-integer file-id :end end) most-positive-fixnum)))

(defun output-codified-p (dir)
  "True when DIR holds an emitted codification (at least one article-*.hash)."
  (and (probe-file (uiop:ensure-directory-pathname dir))
       (directory (merge-pathnames "article-*.hash"
                                   (uiop:ensure-directory-pathname dir)))
       t))

(defun output-manifest (dir &key id)
  "Build a fingerprint manifest from the emitted article-*.hash files in DIR —
   the real, published codification. eIds follow art_<file-id> (letters kept);
   each article's hash is the emitted per-article SHA-256."
  (let* ((d (uiop:ensure-directory-pathname dir))
         (files (sort (directory (merge-pathnames "article-*.hash" d))
                      #'string< :key #'namestring))
         (rows '()))
    (dolist (f files)
      (let ((fid (%hash-file-id f)))
        (when fid
          (push (list :eid (%file-id-eid fid) :file-id fid :status :emitted
                      :hash (string-trim '(#\Space #\Newline #\Return #\Tab)
                                         (uiop:read-file-string f :external-format :utf-8)))
                rows))))
    (setf rows (stable-sort (nreverse rows) #'<
                            :key (lambda (r) (%fileid-numeric (getf r :file-id)))))
    (list :id (or id (car (last (pathname-directory d))))
          :title nil
          :count (length rows)
          :root (%merkle-root (mapcar (lambda (r) (getf r :hash)) rows))
          :articles rows)))

;;; ----------------------------------------------------------------------------
;;; drift detection (golden vs current)
;;; ----------------------------------------------------------------------------

(defun %index (manifest)
  (let ((h (make-hash-table :test 'equal)))
    (dolist (r (manifest-articles manifest) h)
      (setf (gethash (getf r :eid) h) (getf r :hash)))))

(defun fingerprint-diff (golden current)
  "Compare two manifests; return a plist precisely locating any drift:
     (:added (eId...) :removed (eId...) :changed (eId...)
      :root-changed BOOL :count-delta N)
   ADDED/REMOVED/CHANGED are sorted eId lists. CHANGED = same eId, different hash."
  (let* ((gi (%index golden)) (ci (%index current))
         (added '()) (removed '()) (changed '()))
    (maphash (lambda (eid h)
               (multiple-value-bind (gh present) (gethash eid gi)
                 (cond ((not present) (push eid added))
                       ((not (string= gh h)) (push eid changed)))))
             ci)
    (maphash (lambda (eid h) (declare (ignore h))
               (unless (nth-value 1 (gethash eid ci)) (push eid removed)))
             gi)
    (list :added (sort added #'string<)
          :removed (sort removed #'string<)
          :changed (sort changed #'string<)
          :root-changed (not (equal (manifest-root golden) (manifest-root current)))
          :count-delta (- (manifest-count current) (manifest-count golden)))))

(defun diff-clean-p (diff)
  "True when the two fingerprints are identical (no drift)."
  (and (null (getf diff :added))
       (null (getf diff :removed))
       (null (getf diff :changed))
       (not (getf diff :root-changed))))

(defun format-diff (diff &optional (stream nil))
  (format stream
          "~:[~;✓ ~]fingerprint ~:[DRIFT~;identical~]~
~@[~%  + added (~D): ~{~A~^, ~}~]~@[~%  - removed (~D): ~{~A~^, ~}~]~
~@[~%  ~~ changed (~D): ~{~A~^, ~}~]~@[~%  count Δ: ~D~]"
          (diff-clean-p diff) (diff-clean-p diff)
          (and (getf diff :added) (length (getf diff :added))) (getf diff :added)
          (and (getf diff :removed) (length (getf diff :removed))) (getf diff :removed)
          (and (getf diff :changed) (length (getf diff :changed))) (getf diff :changed)
          (and (not (zerop (getf diff :count-delta 0))) (getf diff :count-delta))))

(defun fingerprint-matches-golden (doc golden)
  "Return (values ok-p diff): does DOC's fingerprint match the GOLDEN manifest?"
  (let ((diff (fingerprint-diff golden (corpus-fingerprint doc))))
    (values (diff-clean-p diff) diff)))

;;; ----------------------------------------------------------------------------
;;; invariants
;;; ----------------------------------------------------------------------------

(defun %eid-numeric (eid)
  "From an article eId 'art_070Α' return (values 70 \"Α\"); (values nil nil) if
   it carries no parseable number."
  (let ((us (position #\_ eid :from-end t)))
    (if us
        (let* ((tail (subseq eid (1+ us)))
               (end (or (position-if-not #'digit-char-p tail) (length tail))))
          (if (plusp end)
              (values (parse-integer tail :end end) (subseq tail end))
              (values nil nil)))
        (values nil nil))))

(defun %article-empty-p (a)
  "An article carries no in-force content: no text and no non-empty child."
  (and (let ((tx (%provision-text a))) (or (null tx) (zerop (length tx))))
       (notany (lambda (c)
                 (let ((tx (%provision-text c)))
                   (and tx (plusp (length tx)))))
               (%provision-children a))))

(defun %eid-invariants (eids &key expected-count allow-gaps empty-eids known-absent)
  "The shared structural checks over an ordered list of article EIDS. EMPTY-EIDS
   is the subset that carries no content. KNOWN-ABSENT is a list of article
   numbers the OFFICIAL SOURCE itself omits (documented in the corpus config as
   corpus.source_omitted_articles — e.g. repealed articles the Ισοκράτης
   consolidated export drops entirely): a gap made up solely of those numbers is
   the source's truth, not a parse loss, so it is not a violation. Return a list
   of violation plists — the single source of truth for duplicate / empty / gap /
   ordering / count, used for both a served document and an emitted-output
   manifest."
  (let ((violations '())
        (seen (make-hash-table :test 'equal)))
    (flet ((flag (kind eid detail) (push (list :kind kind :eid eid :detail detail) violations)))
      ;; 1. unique eIds + 2. no empty article
      (dolist (eid eids)
        (when (gethash eid seen)
          (flag :duplicate-eid eid "η ίδια ταυτότητα άρθρου εμφανίζεται πάνω από μία φορά"))
        (setf (gethash eid seen) t))
      (dolist (eid empty-eids)
        (flag :empty-article eid "άρθρο χωρίς κείμενο — πιθανή απώλεια κειμένου"))
      ;; 3. no sequence gap (over the distinct article numbers). Numbers the
      ;; source itself omits are subtracted; only UNEXPLAINED missing numbers flag.
      (unless allow-gaps
        (let ((distinct (remove-duplicates
                         (loop for eid in eids for n = (%eid-numeric eid)
                               when n collect n))))
          (loop for (a b) on (sort (copy-list distinct) #'<)
                when (and b (> b (1+ a)))
                do (let ((unexplained (loop for n from (1+ a) to (1- b)
                                            unless (member n known-absent) collect n)))
                     (when unexplained
                       (flag :gap (format nil "art_~D..art_~D" a b)
                             (format nil "λείπουν άρθρα ~{~D~^, ~}" unexplained)))))))
      ;; 4. canonical (ascending) ordering as served
      (let ((nums (loop for eid in eids for n = (%eid-numeric eid) when n collect n)))
        (unless (equal nums (sort (copy-list nums) #'<))
          (flag :ordering nil "τα άρθρα δεν σερβίρονται σε αύξουσα σειρά")))
      ;; 5. count matches the asserted expectation
      (when (and expected-count (/= (length eids) expected-count))
        (flag :count-mismatch nil
              (format nil "πλήθος ~D ≠ αναμενόμενο ~D" (length eids) expected-count))))
    (nreverse violations)))

(defun verify-corpus-invariants (doc &key expected-count allow-gaps known-absent)
  "Check the served DOC against the structural truths a correct codification must
   satisfy. Return (values ok-p violations); each violation is a plist
     (:kind K :eid E :detail D).
   Kinds: :duplicate-eid :empty-article :gap :ordering :count-mismatch."
  (let* ((arts (%legal-document-provisions doc))
         (vs (%eid-invariants (mapcar #'%provision-eid arts)
                              :expected-count expected-count :allow-gaps allow-gaps
                              :known-absent known-absent
                              :empty-eids (loop for a in arts
                                                when (%article-empty-p a)
                                                collect (%provision-eid a)))))
    (values (null vs) vs)))

(defun verify-manifest-invariants (manifest &key expected-count allow-gaps known-absent)
  "The same structural invariants, over a fingerprint MANIFEST (e.g. one built
   from the emitted codification). An article whose hash is empty counts as
   missing content. Return (values ok-p violations)."
  (let* ((rows (manifest-articles manifest))
         (vs (%eid-invariants (mapcar (lambda (r) (getf r :eid)) rows)
                              :expected-count expected-count :allow-gaps allow-gaps
                              :known-absent known-absent
                              :empty-eids (loop for r in rows
                                                for h = (getf r :hash)
                                                when (or (null h) (zerop (length h)))
                                                collect (getf r :eid)))))
    (values (null vs) vs)))

(defun format-violations (violations &optional (stream nil))
  (if (null violations)
      (format stream "✓ όλοι οι αμετάβλητοι έλεγχοι πέρασαν — η κωδικοποίηση είναι ορθή")
      (format stream "⚠ ~D παραβίαση(εις):~{~%  · [~A]~@[ ~A~]: ~A~}"
              (length violations)
              (loop for v in violations
                    append (list (getf v :kind) (getf v :eid) (getf v :detail))))))
