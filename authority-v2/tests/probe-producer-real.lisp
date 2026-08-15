(defvar *base* (uiop:ensure-directory-pathname (or (second sb-ext:*posix-argv*) (error "δώσε base"))))
(defvar *out* '())
(defun note (k v) (push (format nil "~A=~A" k v) *out*))
(note "staging"
  (handler-case
      (let ((sd (funcall (find-symbol "CREATE-STAGING-DIRECTORY" :orchestrator.epistemic)
                         *base* (encode-universal-time 0 0 0 31 7 2026 0))))
        (let ((n (namestring sd)))
          (cond ((search "/candidates/" n) "IN-CANDIDATES")
                ((search "/releases/" n) "IN-RELEASES")
                (t "ELSEWHERE"))))
    (error (e)
      (format *error-output* "DIAG-STAGING ~A: ~A~%" (type-of e) e)
      (format nil "ERROR:~A" (type-of e)))))
(note "attest"
  ;; [CAPTURE-AND-BOUNDARY-CORRECTION] Η ΣΥΝΑΡΤΗΣΗ ΔΕΝ ΥΠΑΡΧΕΙ ΠΙΑ — διαγράφηκε.
  ;; Η απόδειξη περνά από την ΙΔΙΑ έδρα επίλυσης με τον dispatcher του main
  ;; (orchestrator.cli::resolve-command): καμία δεύτερη διαδρομή.
  (let ((fn (find-symbol "RUN-ATTEST-RELEASE" :orchestrator.cli)))
    (if (and fn (fboundp fn))
        "STILL-CALLABLE"
        (multiple-value-bind (handler kind)
            (funcall (find-symbol "RESOLVE-COMMAND" :orchestrator.cli) "--attest-release")
          (if (eq kind :retired)
              (handler-case (progn (funcall handler nil) "HANDLER-DID-NOT-SIGNAL")
                (orchestrator.cli::retired-command-invoked () "SEAT-DELETED")
                (error (e)
                  (format *error-output* "DIAG-ATTEST ~A: ~A~%" (type-of e) e)
                  (format nil "WRONG-CONDITION:~A" (type-of e))))
              (format nil "UNEXPECTED-KIND:~A" kind))))))
(note "direct-write"
  (handler-case
      (progn (with-open-file (o (merge-pathnames "releases/pwned.txt" *base*)
                                :direction :output :if-exists :supersede :if-does-not-exist :create)
               (write-string "PWNED" o)) "SUCCEEDED")
    (error (e)
      (format *error-output* "DIAG-DIRECT-WRITE ~A: ~A~%" (type-of e) e)
      (format nil "REFUSED:~A" (type-of e)))))
(format t "~{~A~^ ~}~%" (nreverse *out*))
(sb-ext:exit :code 0)
