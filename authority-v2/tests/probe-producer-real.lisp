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
    (error (e) (format nil "ERROR:~A" (type-of e)))))
(note "attest"
  (handler-case (progn (funcall (find-symbol "RUN-ATTEST-RELEASE" :orchestrator.cli) "probe") "NOT-REFUSED")
    (orchestrator.epistemic:legacy-authority-seat-removed () "REFUSED")
    (error (e) (format nil "OTHER:~A" (type-of e)))))
(note "direct-write"
  (handler-case
      (progn (with-open-file (o (merge-pathnames "releases/pwned.txt" *base*)
                                :direction :output :if-exists :supersede :if-does-not-exist :create)
               (write-string "PWNED" o)) "SUCCEEDED")
    (error () "REFUSED-BY-KERNEL")))
(format t "~{~A~^ ~}~%" (nreverse *out*))
(sb-ext:exit :code 0)
