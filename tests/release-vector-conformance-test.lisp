;;;; tests/release-vector-conformance-test.lisp
;;;; ============================================================================
;;;; L7-A CONFORMANCE: το release-vector corpus (deployment/verify/vectors/) ΕΙΝΑΙ
;;;; η προδιαγραφή. Κάθε υλοποίηση επαλήθευσης οφείλει να δίνει ΑΚΡΙΒΩΣ την
;;;; ετυμηγορία του INDEX.json για κάθε διάνυσμα:
;;;;   · spine έδρα (Common Lisp, orchestrator.epistemic:verify-release-spine)
;;;;   · δεύτερη γλώσσα (Python stdlib, deployment/verify/verify-release.py)
;;;; ΚΑΙ οι δύο πρέπει να συμφωνούν με το INDEX ΚΑΙ μεταξύ τους (L7 diversity).
;;;;
;;;; Python απών ⇒ ελέγχεται ΜΟΝΟ η spine έδρα (SKIP-ασφαλές). Τα διανύσματα
;;;; είναι δεσμευμένα fixtures· αν λείπουν, το τεστ SKIP (δεν είναι regression).
;;;; ============================================================================

(in-package :orchestrator.epistemic)

(defvar *vc-pass* 0) (defvar *vc-fail* 0)
(defmacro vck (name form)
  `(handler-case
       (if ,form (progn (incf *vc-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *vc-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *vc-fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %vc-repo-root ()
  (let ((here (or *load-truename* *load-pathname*)))
    (truename (merge-pathnames "../" (make-pathname :directory (pathname-directory here))))))

(defun %vc-which (program)
  (handler-case
      (let ((p (uiop:run-program (list "sh" "-c" (format nil "command -v ~A" program))
                                 :output '(:string :stripped t) :ignore-error-status t)))
        (and (plusp (length p)) p))
    (error () nil)))

(let* ((vroot (merge-pathnames "deployment/verify/vectors/" (%vc-repo-root)))
       (index (merge-pathnames "INDEX.json" vroot))
       (pyver (merge-pathnames "deployment/verify/verify-release.py" (%vc-repo-root)))
       (py (%vc-which "python3")))
  (format t "~%== L7-A release-vector conformance ==~%")
  (format t "  vectors=~A~%  python3=~A~%" vroot py)
  (cond
    ((not (probe-file index))
     (format t "~%  SKIP — δεν βρέθηκε INDEX.json (τα vectors δεν είναι παρόντα).~%")
     (sb-ext:exit :code 0))
    (t
     (let* ((doc (jonathan:parse (uiop:read-file-string index) :as :hash-table))
            (vectors (gethash "vectors" doc)))
       (dolist (v vectors)
         (let* ((name (gethash "name" v))
                (expect (gethash "verdict" v))       ; "pass" | "fail"
                (dir (merge-pathnames (format nil "~A/" name) vroot))
                (pinf (merge-pathnames (format nil "~A.pinned-root" name) vroot))
                (pinned (and (probe-file pinf)
                             (string-trim '(#\Space #\Newline #\Return)
                                          (uiop:read-file-string pinf)))))
           ;; --- spine έδρα (Lisp) ---
           (multiple-value-bind (ok failures) (verify-release-spine dir)
             (declare (ignore failures))
             ;; spine ελέγχει census+αλυσίδα+JWS· για census-εποχής vectors το
             ;; root recompute γίνεται εσωτερικά. Ετυμηγορία: ok ⇒ "pass".
             (let ((spine-verdict (if ok "pass" "fail")))
               (vck (format nil "~A: spine έδρα ≡ INDEX (~A)" name expect)
                    (string= spine-verdict expect))))
           ;; --- δεύτερη γλώσσα (Python) ---
           (when (and py (probe-file pyver))
             (let* ((args (append (list (namestring pyver) (namestring dir))
                                  (when pinned (list pinned))))
                    (code (nth-value 2 (uiop:run-program (cons py args)
                                                         :output nil :error-output nil
                                                         :ignore-error-status t)))
                    (py-verdict (if (zerop code) "pass" "fail")))
               (vck (format nil "~A: python verifier ≡ INDEX (~A)" name expect)
                    (string= py-verdict expect))))))))
    )
  (format t "~%========================================~%")
  (format t "Release-vector conformance: ~D passed, ~D failed~%" *vc-pass* *vc-fail*)
  (format t "========================================~%")
  (sb-ext:exit :code (if (zerop *vc-fail*) 0 1)))
