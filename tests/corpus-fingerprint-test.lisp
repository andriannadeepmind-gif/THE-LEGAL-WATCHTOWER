;;;; tests/corpus-fingerprint-test.lisp
;;;; Correctness guarantee: deterministic fingerprint, golden regression, and
;;;; the structural invariants — proven on a deterministic synthetic corpus that
;;;; mirrors the real codification shape (base + lettered + repealed + nested).
;;;;
;;;; Set WRITE_GOLDEN=1 to (re)generate the committed golden manifest.

(in-package :orchestrator.fingerprint)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mk-art (eid num heading text &optional children)
  (orchestrator.consolidation:make-provision
   :eid eid :kind :article :num num :heading heading :text text :children children))

(defun mk-para (eid num text)
  (orchestrator.consolidation:make-provision
   :eid eid :kind :paragraph :num num :text text))

;; A deterministic corpus shaped like the real thing: articles 1..4, a lettered
;; 2Α (must stay distinct from 2), article 4 repealed (kept in tree), and a
;; multi-paragraph article 3.
(defun build-corpus ()
  (orchestrator.consolidation:make-legal-document
   :id "synthetic" :title "Δοκιμαστικός Κώδικας" :language "el"
   :provisions
   (list
    (mk-art "art_001" "1" "Πεδίο εφαρμογής" "Ο παρών κώδικας εφαρμόζεται σε όλους.")
    (mk-art "art_002" "2" "Ορισμοί" "Για τους σκοπούς του παρόντος ισχύουν οι ορισμοί.")
    (mk-art "art_002Α" "2" "Συμπληρωματικοί ορισμοί" "Προστέθηκε με μεταγενέστερο νόμο.")
    (mk-art "art_003" "3" "Αρχές" nil
            (list (mk-para "art_003__para_1" "1" "Πρώτη αρχή.")
                  (mk-para "art_003__para_2" "2" "Δεύτερη αρχή.")))
    (let ((a (mk-art "art_004" "4" "Καταργηθέν" "Το άρθρο αυτό καταργήθηκε.")))
      (setf (orchestrator.consolidation:provision-status a) :repealed)
      a))))

(defparameter *golden-path*
  (merge-pathnames "golden/synthetic-corpus.fingerprint.sexp"
                   (or *load-pathname* *default-pathname-defaults*)))

;; ---------------------------------------------------------------------------
(format t "~%== Determinism ==~%")
(let* ((doc (build-corpus))
       (m1 (corpus-fingerprint doc))
       (m2 (corpus-fingerprint (build-corpus))))
  (check "two fingerprints of identical corpora are equal" (equal m1 m2))
  (check "root is a 64-hex SHA-256" (and (stringp (manifest-root m1))
                                         (= 64 (length (manifest-root m1)))))
  (check "count is 5 (lettered 2Α counted separately from 2)" (= 5 (manifest-count m1)))
  (let ((tmp (merge-pathnames "fp-roundtrip.sexp" #p"/tmp/")))
    (write-fingerprint-manifest m1 tmp)
    (check "serialize -> read round-trip is byte-identical"
           (equal m1 (read-fingerprint-manifest tmp)))))

;; ---------------------------------------------------------------------------
(format t "~%== Golden regression ==~%")
(when (uiop:getenv "WRITE_GOLDEN")
  (write-fingerprint-manifest (corpus-fingerprint (build-corpus)) *golden-path*)
  (format t "  (wrote golden -> ~A)~%" *golden-path*))
(let ((golden (read-fingerprint-manifest *golden-path*)))
  (check "committed golden manifest exists" golden)
  (when golden
    (multiple-value-bind (ok diff) (fingerprint-matches-golden (build-corpus) golden)
      (declare (ignore diff))
      (check "current corpus matches the committed golden (no drift)" ok))))

;; ---------------------------------------------------------------------------
(format t "~%== Drift detection (locate the exact article) ==~%")
(let ((golden (corpus-fingerprint (build-corpus))))
  ;; one altered character in one article
  (let* ((doc (build-corpus))
         (a (find "art_002" (orchestrator.consolidation:legal-document-provisions doc)
                  :key #'orchestrator.consolidation:provision-eid :test #'string=)))
    (setf (orchestrator.consolidation:provision-text a) "Αλλοιωμένο κείμενο.")
    (let ((diff (fingerprint-diff golden (corpus-fingerprint doc))))
      (check "a single edit is detected" (not (diff-clean-p diff)))
      (check "drift names EXACTLY the changed article" (equal '("art_002") (getf diff :changed)))
      (check "no false positives elsewhere" (and (null (getf diff :added))
                                                 (null (getf diff :removed))))
      (check "root changed" (getf diff :root-changed))))
  ;; a change deep in a paragraph bubbles up to its article
  (let* ((doc (build-corpus))
         (a (find "art_003" (orchestrator.consolidation:legal-document-provisions doc)
                  :key #'orchestrator.consolidation:provision-eid :test #'string=))
         (p (first (orchestrator.consolidation:provision-children a))))
    (setf (orchestrator.consolidation:provision-text p) "Τροποποιημένη πρώτη αρχή.")
    (let ((diff (fingerprint-diff golden (corpus-fingerprint doc))))
      (check "a nested paragraph edit surfaces as the parent article"
             (equal '("art_003") (getf diff :changed)))))
  ;; a dropped article
  (let ((doc (build-corpus)))
    (setf (orchestrator.consolidation:legal-document-provisions doc)
          (remove "art_002Α" (orchestrator.consolidation:legal-document-provisions doc)
                  :key #'orchestrator.consolidation:provision-eid :test #'string=))
    (let ((diff (fingerprint-diff golden (corpus-fingerprint doc))))
      (check "a dropped article is reported as removed" (equal '("art_002Α") (getf diff :removed)))
      (check "count delta is -1" (= -1 (getf diff :count-delta)))))
  ;; an added article
  (let ((doc (build-corpus)))
    (setf (orchestrator.consolidation:legal-document-provisions doc)
          (append (orchestrator.consolidation:legal-document-provisions doc)
                  (list (mk-art "art_005" "5" "Νέο" "Νέο άρθρο."))))
    (let ((diff (fingerprint-diff golden (corpus-fingerprint doc))))
      (check "an added article is reported as added" (equal '("art_005") (getf diff :added))))))

;; ---------------------------------------------------------------------------
(format t "~%== Invariants ==~%")
(multiple-value-bind (ok vs) (verify-corpus-invariants (build-corpus))
  (declare (ignore vs))
  (check "a correct corpus passes every invariant" ok))
(check "expected-count match passes"
       (verify-corpus-invariants (build-corpus) :expected-count 5))
(multiple-value-bind (ok vs) (verify-corpus-invariants (build-corpus) :expected-count 999)
  (check "wrong expected-count fails"
         (and (not ok) (member :count-mismatch (mapcar (lambda (v) (getf v :kind)) vs)))))

;; lettered article preserved (distinct from its base number)
(let* ((m (corpus-fingerprint (build-corpus)))
       (eids (mapcar (lambda (r) (getf r :eid)) (manifest-articles m))))
  (check "both art_002 and art_002Α are present and distinct"
         (and (member "art_002" eids :test #'string=)
              (member "art_002Α" eids :test #'string=)))
  (check "their fingerprints differ (no collapse / overwrite)"
         (not (string= (getf (find "art_002" (manifest-articles m)
                                   :key (lambda (r) (getf r :eid)) :test #'string=) :hash)
                       (getf (find "art_002Α" (manifest-articles m)
                                   :key (lambda (r) (getf r :eid)) :test #'string=) :hash)))))

;; duplicate eId
(let ((doc (build-corpus)))
  (setf (orchestrator.consolidation:legal-document-provisions doc)
        (append (orchestrator.consolidation:legal-document-provisions doc)
                (list (mk-art "art_001" "1" "Διπλό" "Διπλότυπο."))))
  (multiple-value-bind (ok vs) (verify-corpus-invariants doc)
    (check "duplicate eId is caught"
           (and (not ok)
                (find-if (lambda (v) (and (eq (getf v :kind) :duplicate-eid)
                                          (string= (getf v :eid) "art_001"))) vs)))))

;; empty article (silent text loss)
(let ((doc (build-corpus)))
  (setf (orchestrator.consolidation:legal-document-provisions doc)
        (append (orchestrator.consolidation:legal-document-provisions doc)
                (list (mk-art "art_006" "6" "Κενό" ""))))
  (multiple-value-bind (ok vs) (verify-corpus-invariants doc)
    (check "empty article (text loss) is caught"
           (and (not ok)
                (find-if (lambda (v) (eq (getf v :kind) :empty-article)) vs)))))

;; sequence gap (drop a middle number entirely)
(let ((doc (build-corpus)))
  (setf (orchestrator.consolidation:legal-document-provisions doc)
        (remove-if (lambda (p)
                     (member (orchestrator.consolidation:provision-eid p)
                             '("art_002" "art_002Α") :test #'string=))
                   (orchestrator.consolidation:legal-document-provisions doc)))
  (multiple-value-bind (ok vs) (verify-corpus-invariants doc)
    (check "a sequence gap (missing art 2) is caught"
           (and (not ok) (member :gap (mapcar (lambda (v) (getf v :kind)) vs))))))

;; ---------------------------------------------------------------------------
(format t "~%== Output manifest (real emitted codification: article-*.hash) ==~%")
(let ((dir (merge-pathnames "fp-emitted-test/" #p"/tmp/")))
  (uiop:delete-directory-tree dir :validate (constantly t) :if-does-not-exist :ignore)
  (ensure-directories-exist dir)
  ;; emit article-001/002/002Α/010.hash  (note 2Α kept distinct, lettered)
  (flet ((emit (fid hash)
           (with-open-file (s (merge-pathnames (format nil "article-~A.hash" fid) dir)
                              :direction :output :if-exists :supersede
                              :if-does-not-exist :create :external-format :utf-8)
             (write-string hash s))))
    (emit "001" "aaaa1111")
    (emit "010" "dddd4444")      ; written out of order on purpose
    (emit "002" "bbbb2222")
    (emit "002Α" "cccc3333"))
  (check "output-codified-p detects emitted hashes" (output-codified-p dir))
  (let ((m (output-manifest dir :id "emitted")))
    (check "output manifest counts every emitted article" (= 4 (manifest-count m)))
    (check "articles are ordered by real number (1,2,2Α,10)"
           (equal '("art_001" "art_002" "art_002Α" "art_010")
                  (mapcar (lambda (r) (getf r :eid)) (manifest-articles m))))
    (check "lettered 2Α preserved distinctly from 2"
           (and (member "art_002Α" (mapcar (lambda (r) (getf r :eid)) (manifest-articles m))
                        :test #'string=)
                (member "art_002" (mapcar (lambda (r) (getf r :eid)) (manifest-articles m))
                        :test #'string=)))
    (check "output manifest passes invariants (no gap among 1,2,10? -> gap 2..10)"
           ;; 1,2,10 DOES have a gap (3..9). allow-gaps to assert the happy fields.
           (verify-manifest-invariants m :allow-gaps t))
    (check "gap among emitted articles is caught when not allowed"
           (not (verify-manifest-invariants m)))
    ;; determinism: rebuild -> identical
    (check "output manifest is deterministic" (equal m (output-manifest dir :id "emitted")))
    ;; drift: change one emitted hash -> exactly that article changes
    (with-open-file (s (merge-pathnames "article-002.hash" dir)
                       :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string "ZZZZ9999" s))
    (let ((diff (fingerprint-diff m (output-manifest dir :id "emitted"))))
      (check "re-emitted change is located to the exact article"
             (equal '("art_002") (getf diff :changed))))))

(format t "~%========================================~%")
(format t "Corpus fingerprint tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
