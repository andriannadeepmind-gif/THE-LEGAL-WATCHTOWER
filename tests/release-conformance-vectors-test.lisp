;;;; tests/release-conformance-vectors-test.lisp
;;;; ============================================================================
;;;; L7 CONFORMANCE VECTORS — η προδιαγραφή ΩΣ εκτελέσιμο σώμα διανυσμάτων
;;;; (Wycheproof/CT πρότυπο). Κάθε vector = μια μετάλλαξη ενός ΓΝΗΣΙΟΥ census-era
;;;; release + η ΑΝΑΜΕΝΟΜΕΝΗ ετυμηγορία. ΔΥΟ ανεξάρτητες υλοποιήσεις τρέχουν
;;;; ΚΑΘΕ vector και ΠΡΕΠΕΙ να συμφωνούν με την αναμενόμενη ετυμηγορία ΚΑΙ
;;;; μεταξύ τους:
;;;;   (α) η spine έδρα (orchestrator.epistemic:verify-release-spine, in-process)
;;;;   (β) ο L6 πυρήνας (deployment/verify/kernel-verify.lisp, subprocess sbcl)
;;;;
;;;; Έτσι η ορθότητα του verifier παύει να είναι ισχυρισμός: γίνεται μηχανικά
;;;; ελέγξιμη, γλωσσο-ανεξάρτητη ιδιότητα. Τα αρνητικά vectors ΚΩΔΙΚΟΠΟΙΟΥΝ τα
;;;; ευρήματα των αντιπαλικών κριτών (F1 payload-substitution, F2 signature-
;;;; stripping, tamper, wrong-key, epoch-downgrade) — ΚΑΘΕ μελλοντικός verifier,
;;;; σε ΟΠΟΙΑ γλώσσα, οφείλει να τα φράζει για να λέγεται συμμορφούμενος.
;;;;
;;;; SKIP (exit 0) όταν δεν υπάρχει census-era release βάση ή δεν τρέχει sbcl
;;;; subprocess — ασφαλές σε ελάχιστο περιβάλλον· ο owner/CI το κάνει σκληρή πύλη.
;;;; ============================================================================

(in-package :orchestrator.epistemic)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro ck (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %repo-root ()
  (let ((here (or *load-truename* *load-pathname*)))
    (truename (merge-pathnames "../" (make-pathname :directory (pathname-directory here))))))

(defun %find-base-release ()
  "Πρώτο census-era release (census.json + signature.jws + public.jwk) στο output/."
  (let ((out (merge-pathnames "output/" (%repo-root))))
    (when (probe-file out)
      (dolist (corpus (ignore-errors (uiop:subdirectories out)))
        (let ((rels (merge-pathnames "releases/" corpus)))
          (when (probe-file rels)
            (dolist (d (ignore-errors (uiop:subdirectories rels)))
              (let ((leaf (car (last (pathname-directory d)))))
                (when (and (stringp leaf) (eql 0 (search "sha256-" leaf))
                           (probe-file (merge-pathnames "census.json" d))
                           (probe-file (merge-pathnames "temporal-proof/signature.jws" d))
                           (probe-file (merge-pathnames "verify/public.jwk" d)))
                  (return-from %find-base-release d))))))))))

(defun %kernel-verdict (dir)
  "Ετυμηγορία του L6 πυρήνα (subprocess): :pass / :fail / :error."
  (let ((kernel (merge-pathnames "deployment/verify/kernel-verify.lisp" (%repo-root))))
    (handler-case
        (let ((code (nth-value 2 (uiop:run-program
                                  (list "sbcl" "--script" (namestring kernel) (namestring dir))
                                  :ignore-error-status t
                                  :output nil :error-output nil))))
          (case code (0 :pass) (1 :fail) (t :error)))
      (error () :error))))

(defun %spine-verdict (dir)
  (if (verify-release-spine dir) :pass :fail))

(defun %cp-tree (src dst)
  (uiop:run-program (list "cp" "-a" (namestring src) (namestring dst))
                    :ignore-error-status nil))

(defun %flip-byte (path)
  "Αλλάζει 1 byte στη μέση του αρχείου (ελάχιστη αλλοίωση)."
  (let ((bytes (alexandria:read-file-into-byte-vector path)))
    (when (plusp (length bytes))
      (let ((i (floor (length bytes) 2)))
        (setf (aref bytes i) (logxor (aref bytes i) 1))))
    (alexandria:write-byte-vector-into-file bytes path :if-exists :supersede)))

(defun %first-article-file (dir ext)
  (first (sort (directory (merge-pathnames (format nil "articles/article-*.~A" ext) dir))
               #'string< :key #'namestring)))

;;; --- vectors: (name mutate-fn expected) ---------------------------------
(defparameter *vectors*
  (list
   (list "positive: ανέπαφο release ⇒ PASS"
         (lambda (d) (declare (ignore d)) nil) :pass)
   (list "tamper article .txt ⇒ FAIL (census text_leaf mismatch)"
         (lambda (d) (%flip-byte (%first-article-file d "txt"))) :fail)
   (list "tamper article .ttl ⇒ FAIL (per-article sha512 mismatch)"
         (lambda (d) (%flip-byte (%first-article-file d "ttl"))) :fail)
   (list "tamper census.json ⇒ FAIL (root shift ⇒ JWS invalid + name)"
         (lambda (d) (%flip-byte (merge-pathnames "census.json" d))) :fail)
   (list "strip signature.jws ⇒ FAIL (F2 signature stripping)"
         (lambda (d) (delete-file (merge-pathnames "temporal-proof/signature.jws" d))) :fail)
   (list "epoch-downgrade: rm census.json ⇒ FAIL (canonical λείπει)"
         (lambda (d) (delete-file (merge-pathnames "census.json" d))) :fail)
   (list "wrong-key: ξένο public.jwk ⇒ FAIL (JWS invalid)"
         (lambda (d)
           (let* ((kp (orchestrator.jws-authority:generate-rsa-keypair :bits 2048))
                  (pub (getf kp :public-key)))
             (alexandria:write-string-into-file
              (jonathan:to-json (orchestrator.jws-authority:export-jwk pub :kid "attacker"))
              (merge-pathnames "verify/public.jwk" d) :if-exists :supersede)))
         :fail)
   (list "F1: attached-payload JWS token ⇒ FAIL (payload substitution)"
         (lambda (d)
           (let* ((jp (merge-pathnames "temporal-proof/signature.jws" d))
                  (jws (string-trim '(#\Space #\Newline #\Return) (uiop:read-file-string jp)))
                  (dot1 (position #\. jws))
                  (dot2 (position #\. jws :start (1+ dot1)))
                  (evil (orchestrator.jws-authority:base64url-encode "attacker"))
                  (tampered (concatenate 'string (subseq jws 0 (1+ dot1)) evil (subseq jws dot2))))
             (alexandria:write-string-into-file tampered jp :if-exists :supersede)))
         :fail)))

(let ((base (%find-base-release)))
  (cond
    ((null base)
     (format t "~%⚠ SKIP: δεν βρέθηκε census-era release βάση στο output/ (exit 0)~%")
     (sb-ext:exit :code 0))
    ((not (ignore-errors
            (zerop (nth-value 2 (uiop:run-program '("sbcl" "--version")
                                                  :ignore-error-status t :output nil)))))
     (format t "~%⚠ SKIP: sbcl subprocess μη διαθέσιμο (exit 0)~%")
     (sb-ext:exit :code 0))
    (t
     (format t "~%== L7 conformance vectors (βάση: ~A) ==~%"
             (car (last (pathname-directory base))))
     (let ((tmp (uiop:ensure-directory-pathname
                 (merge-pathnames (format nil "lawmax-vectors-~D/" (sb-posix:getpid))
                                  (uiop:temporary-directory))))
           (leaf (car (last (pathname-directory base)))))
       (ensure-directories-exist tmp)
       (unwind-protect
            (loop for v in *vectors* for n from 0 do
              (destructuring-bind (name mutate expected) v
                ;; φρέσκο αντίγραφο ανά vector
                (let ((vd (uiop:ensure-directory-pathname
                           (merge-pathnames (format nil "case-~D/" n) tmp))))
                  (ensure-directories-exist vd)
                  (%cp-tree base vd)
                  (let ((rel (merge-pathnames (format nil "~A/" leaf) vd)))
                    (funcall mutate rel)
                    (let ((sv (%spine-verdict rel))
                          (kv (%kernel-verdict rel)))
                      (ck (format nil "~A [spine=~A kernel=~A]" name sv kv)
                          (and (eq sv expected) (eq kv expected) (eq sv kv))))))))
         (ignore-errors (uiop:delete-directory-tree tmp :validate t :if-does-not-exist :ignore)))))))

(format t "~%========================================~%")
(format t "L7 conformance vectors: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
