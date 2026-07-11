;;;; deployment/verify/vectors/build-vectors.lisp
;;;; ============================================================================
;;;; L7-A ΓΕΝΝΗΤΗΣ ΔΙΑΝΥΣΜΑΤΩΝ ΕΠΑΛΗΘΕΥΣΗΣ RELEASE (Wycheproof-style)
;;;; ============================================================================
;;;;
;;;; Παράγει ΜΙΚΡΑ, αυτοτελή census-εποχής releases (2 συνθετικά άρθρα) ΜΕΣΩ
;;;; ΤΩΝ ΙΔΙΩΝ ΕΔΡΩΝ που χτίζουν τα πραγματικά (orchestrator.merkle, census,
;;;; jws-authority) — ώστε το ΘΕΤΙΚΟ διάνυσμα να είναι ΓΝΗΣΙΑ έγκυρο — και μετά
;;;; τα ΑΡΝΗΤΙΚΑ με τεκμηριωμένη μετάλλαξη (κάθε εύρημα κριτή = διάνυσμα).
;;;;
;;;; Το προϊόν (vectors/*/ + INDEX.json) είναι Η ΠΡΟΔΙΑΓΡΑΦΗ του L7: κάθε
;;;; verifier, σε ΚΑΘΕ γλώσσα, οφείλει να δίνει την ετυμηγορία του INDEX για
;;;; κάθε διάνυσμα — αλλιώς ΔΕΝ είναι συμμορφούμενος.
;;;;
;;;; Ντετερμινισμός: σταθερό test κλειδί (vectors/test-key/, fixtures ΜΟΝΟ,
;;;; ΠΟΤΕ production root), σταθερό περιεχόμενο άρθρων, SOURCE_DATE_EPOCH.
;;;; RSASSA-PKCS1-v1_5 ντετερμινιστικό ⇒ byte-σταθερή υπογραφή.
;;;;
;;;; Τρέξιμο (μέσα στο runtime image ή με φορτωμένο orchestrator-cli):
;;;;   sbcl ... --eval '(load "deployment/verify/vectors/build-vectors.lisp")'
;;;; ============================================================================

(in-package :orchestrator.epistemic)

(defparameter *vec-root*
  (merge-pathnames "deployment/verify/vectors/"
                   (uiop:ensure-directory-pathname
                    (orchestrator.paths:institution-root))))

(defparameter *vec-key-dir* (merge-pathnames "test-key/" *vec-root*))
(defparameter *vec-work* (merge-pathnames ".work/" *vec-root*))

;;; --- σταθερό test κλειδί (fixtures ΜΟΝΟ) ---
(defun %ensure-test-key ()
  (let ((priv (merge-pathnames "private.pem" *vec-key-dir*))
        (pub  (merge-pathnames "public.pem"  *vec-key-dir*)))
    (unless (and (probe-file priv) (probe-file pub))
      (ensure-directories-exist *vec-key-dir*)
      (let ((kp (orchestrator.jws-authority:generate-rsa-keypair :bits 2048)))
        (orchestrator.jws-authority:save-rsa-keypair kp priv pub)))
    (values priv pub)))

;;; --- τα 8 βασικά canonical με ΣΤΑΘΕΡΟ μικρό περιεχόμενο (η εγκυρότητα ενός
;;;     vector = εσωτερική συνέπεια, όχι το «νόημα» της μετα-οντολογίας) ---
(defparameter +vec-base-files+
  '(("meta-ontology.ttl"        . "# vector meta-ontology (fixed)~%")
    ("lineage-graph.ttl"        . "# vector lineage (fixed)~%")
    ("negation.ttl"             . "# vector negation (fixed)~%")
    ("stability-policy.ttl"     . "# vector stability (fixed)~%")
    ("stability-policy.md"      . "# vector stability policy (fixed)~%")
    ("shapes/article-shape.ttl" . "# vector article shape (fixed)~%")
    ("shapes/manifest-shape.ttl". "# vector manifest shape (fixed)~%")
    ("shapes/lineage-shape.ttl" . "# vector lineage shape (fixed)~%")))

(defun %write-fixed (dir rel content)
  (let ((p (merge-pathnames rel dir)))
    (ensure-directories-exist p)
    (alexandria:write-string-into-file (format nil content) p :if-exists :supersede)
    p))

(defun %write-article-files (base-dir a)
  "Per-article ttl/jsonld/html/txt (FLAT στο base-dir, όπως το output/<corpus>/
   — από εκεί τα σταθμεύει η έδρα stage-per-article-artifacts)."
  (let* ((fid (orchestrator.model:article-file-id a))
         (adir (uiop:ensure-directory-pathname base-dir)))
    (ensure-directories-exist adir)
    (flet ((w (ext body)
             (alexandria:write-string-into-file
              (format nil body fid)
              (merge-pathnames (format nil "article-~A.~A" fid ext) adir)
              :if-exists :supersede)))
      (w "ttl"    "# article ~A ttl~%")
      (w "jsonld" "{\"@id\":\"art:~A\"}~%")
      (w "html"   "<article id=\"~A\"></article>~%")
      (w "txt"    "Άρθρο ~A — συνθετικό κείμενο διανύσματος.~%"))))

;;; --- ΧΤΙΣΙΜΟ ΤΟΥ ΘΕΤΙΚΟΥ RELEASE ---
(defun %build-valid-release (dest-parent)
  "Χτίζει ένα γνήσια έγκυρο census-εποχής release κάτω από DEST-PARENT.
   Επιστρέφει (values release-dir root-hex)."
  (ensure-directories-exist *vec-work*)
  (uiop:delete-directory-tree *vec-work* :validate t :if-does-not-exist :ignore)
  (let* ((base (merge-pathnames "base/" *vec-work*))     ; πηγή per-article
         (staging (merge-pathnames "staging/" *vec-work*))
         (releases (merge-pathnames "releases/" *vec-work*)) ; για prev-root (κενό)
         (arts (list (orchestrator.model:make-article :number 1 :content "a1")
                     (orchestrator.model:make-article :number 2 :content "a2"))))
    (ensure-directories-exist base)
    (ensure-directories-exist staging)
    (ensure-directories-exist releases)
    (dolist (a arts) (%write-article-files base a))
    ;; 8 βασικά canonical στο staging
    (loop for (rel . body) in +vec-base-files+ do (%write-fixed staging rel body))
    ;; census.json (9ο) — η έδρα σταθμεύει τα per-article στο staging/articles/
    (write-artifact-census arts "vector" base staging releases)
    ;; verify/verify.lisp (10ο canonical) = ο L6 πυρήνας
    (let ((kern (merge-pathnames "deployment/verify/kernel-verify.lisp"
                                 (orchestrator.paths:institution-root))))
      (ensure-directories-exist (merge-pathnames "verify/" staging))
      (uiop:copy-file kern (merge-pathnames "verify/verify.lisp" staging)))
    ;; manifests (όχι canonical, αλλά ο kernel/spine τα αγνοούν· τα γράφουμε
    ;; για ρεαλισμό — δεν επηρεάζουν root)
    (%write-fixed staging "manifest.ttl" "# vector manifest~%")
    (%write-fixed staging "manifest.jsonld" "{\"@context\":{}}~%")
    ;; ΡΙΖΑ πάνω στα 10 canonical (η έδρα)
    (multiple-value-bind (priv pub) (%ensure-test-key)
      (let* ((root (merkle-tree-root
                    (build-merkle-tree (collect-epistemic-artifacts staging))))
             (id (%root->release-id root))
             (rel-dir (merge-pathnames (format nil "~A/" id)
                                       (uiop:ensure-directory-pathname dest-parent))))
        ;; υπογραφή του root + public.jwk (fail-closed έδρα)
        (sign-manifest-jws root
                           (merge-pathnames "temporal-proof/signature.jws" staging)
                           :private-key-path (namestring priv)
                           :public-key-path (namestring pub)
                           :public-key-jwk-path (merge-pathnames "verify/public.jwk" staging))
        ;; ονομασία = ταυτότητα περιεχομένου
        (ensure-directories-exist (uiop:ensure-directory-pathname dest-parent))
        (uiop:delete-directory-tree (uiop:ensure-directory-pathname rel-dir)
                                    :validate t :if-does-not-exist :ignore)
        (rename-file (uiop:ensure-directory-pathname staging)
                     (uiop:ensure-directory-pathname rel-dir))
        (values rel-dir (subseq root 7))))))

;;; --- helpers μετάλλαξης ---
(defun %cp-tree (src dst)
  (uiop:delete-directory-tree (uiop:ensure-directory-pathname dst)
                              :validate t :if-does-not-exist :ignore)
  (ensure-directories-exist (uiop:ensure-directory-pathname dst))
  ;; αντιγραφή ΠΕΡΙΕΧΟΜΕΝΟΥ (src/.) μέσα στο dst — όχι φωλιασμένο src-όνομα.
  (uiop:run-program (list "cp" "-a"
                          (concatenate 'string (string-right-trim "/" (namestring src)) "/.")
                          (string-right-trim "/" (namestring dst)))
                    :output t :error-output t))

(defun %flip-first-byte (path)
  "Αλλάζει 1 byte του αρχείου (tamper) — κρατά μήκος."
  (let ((b (alexandria:read-file-into-byte-vector path)))
    (setf (aref b 0) (logxor (aref b 0) 1))
    (with-open-file (s path :direction :output :element-type '(unsigned-byte 8)
                            :if-exists :supersede)
      (write-sequence b s))))

;;; --- Ο ΠΙΝΑΚΑΣ ΔΙΑΝΥΣΜΑΤΩΝ ---
(defun build-all-vectors ()
  (let ((cases '()))
    (flet ((record (name verdict reason)
             (push (list name verdict reason) cases)))
      ;; 1. ΘΕΤΙΚΟ
      (multiple-value-bind (valid-dir root-hex) (%build-valid-release *vec-root*)
        (let ((valid-name (car (last (pathname-directory
                                      (uiop:ensure-directory-pathname valid-dir))))))
          (record valid-name :pass "γνήσια έγκυρο census-εποχής release")
          ;; pinned root αρχείο δίπλα (out-of-band άγκυρα)
          (alexandria:write-string-into-file
           (format nil "~A~%" root-hex)
           (merge-pathnames (format nil "~A.pinned-root" valid-name) *vec-root*)
           :if-exists :supersede)

          ;; --- ΑΡΝΗΤΙΚΑ (μετάλλαξη αντιγράφου) ---
          (labels ((neg (suffix reason mutate)
                     (let ((d (merge-pathnames (format nil "~A--~A/" valid-name suffix) *vec-root*)))
                       (%cp-tree valid-dir d)
                       (funcall mutate d)
                       (record (format nil "~A--~A" valid-name suffix) :fail reason))))
            ;; tampered article txt (περιεχόμενο ≠ census text_leaf)
            (neg "tampered-article"
                 "πειραγμένο article-001.txt (text_leaf/root αναντιστοιχία)"
                 (lambda (d) (%flip-first-byte (merge-pathnames "articles/article-001.txt" d))))
            ;; tampered ttl (sha512 census αναντιστοιχία)
            (neg "tampered-ttl"
                 "πειραγμένο article-002.ttl (census sha512 αναντιστοιχία)"
                 (lambda (d) (%flip-first-byte (merge-pathnames "articles/article-002.ttl" d))))
            ;; stripped census.json = epoch-downgrade (sha256 dir χωρίς census)
            (neg "stripped-census"
                 "αφαιρεμένο census.json (epoch-downgrade — sha256 dir εκτός frozen)"
                 (lambda (d) (delete-file (merge-pathnames "census.json" d))))
            ;; stripped signature (F2)
            (neg "stripped-signature"
                 "αφαιρεμένη signature.jws+public.jwk (signature stripping, F2)"
                 (lambda (d)
                   (delete-file (merge-pathnames "temporal-proof/signature.jws" d))
                   (delete-file (merge-pathnames "verify/public.jwk" d))))
            ;; attached-payload JWS (F1): βάζουμε μη-κενό payload segment
            (neg "attached-payload-jws"
                 "JWS με μη-κενό ενσωματωμένο payload (payload substitution, F1)"
                 (lambda (d)
                   (let* ((jp (merge-pathnames "temporal-proof/signature.jws" d))
                          (jws (string-trim '(#\Space #\Newline #\Return)
                                            (uiop:read-file-string jp)))
                          (dot1 (position #\. jws))
                          (dot2 (position #\. jws :start (1+ dot1)))
                          (evil (concatenate 'string (subseq jws 0 (1+ dot1))
                                             "ZXZpbA" (subseq jws dot2))))
                     (alexandria:write-string-into-file evil jp :if-exists :supersede))))
            ;; μη-canonical: πειραγμένο verify/verify.lisp (10ο canonical ⇒ root mismatch)
            (neg "tampered-verifier"
                 "πειραγμένο verify/verify.lisp (10ο canonical ⇒ root ≠ όνομα)"
                 (lambda (d)
                   (with-open-file (s (merge-pathnames "verify/verify.lisp" d)
                                      :direction :output :if-exists :append)
                     (format s "~%;; tamper~%")))))))
      ;; --- INDEX.json ---
      (let ((idx (with-output-to-string (o)
                   (format o "{~%\"schema\":\"lawmax-release-vectors-1\",~%\"vectors\":[~%")
                   (loop for (name verdict reason) in (nreverse cases)
                         for firstp = t then nil
                         do (format o "~:[,~;~]{\"name\":~S,\"verdict\":~S,\"reason\":~S}~%"
                                    firstp name (string-downcase (symbol-name verdict)) reason))
                   (format o "]~%}~%"))))
        (alexandria:write-string-into-file idx (merge-pathnames "INDEX.json" *vec-root*)
                                           :if-exists :supersede))
      ;; καθάρισμα work
      (uiop:delete-directory-tree *vec-work* :validate t :if-does-not-exist :ignore)
      (format t "~&✓ vectors: ~D (1 pass + ~D fail) στο ~A~%"
              (length cases) (1- (length cases)) *vec-root*))))

(build-all-vectors)
