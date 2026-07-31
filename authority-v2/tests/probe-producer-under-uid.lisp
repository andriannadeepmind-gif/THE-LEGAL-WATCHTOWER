;;;; Τρέχει ΩΣ PRODUCER UID, μέσα σε ιδιωτικό mount namespace, με το legacy
;;;; releases/ bind-mounted READ-ONLY. Καλεί τις ΠΡΑΓΜΑΤΙΚΕΣ παραγωγικές
;;;; συναρτήσεις — όχι απομιμήσεις — και αναφέρει τι κατάφερε να γράψει.
(require :asdf) (require :sb-posix)
(defvar cl-user::*root* (uiop:ensure-directory-pathname (or (uiop:getenv "LAWMAX_REPO") (uiop:getcwd))))
(setf asdf:*central-registry*
      (append (list cl-user::*root*) (directory (merge-pathnames "systems/*/" cl-user::*root*))))
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(merge-pathnames "third-party/" cl-user::*root*)) :inherit-configuration))
(locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (handler-bind ((warning #'muffle-warning))
    (asdf:load-system :alexandria) (asdf:load-system :log4cl)
    (asdf:load-system :orchestrator-cli)))

(defvar *base* (uiop:ensure-directory-pathname (second sb-ext:*posix-argv*)))
(defvar *findings* '())
(defun note (k v) (push (format nil "~A=~A" k v) *findings*))

;; ① Η ΠΡΑΓΜΑΤΙΚΗ create-staging-directory: πού στοχεύει;
(let ((sd (handler-case
              (funcall (find-symbol "CREATE-STAGING-DIRECTORY" :orchestrator.epistemic)
                       ;; universal-time (ντετερμινιστικό) — ο τύπος που
                       ;; περιμένει η format-iso8601, όχι string.
                       *base* (encode-universal-time 0 0 0 31 7 2026 0))
            (error (e) (format nil "ERROR:~A" (type-of e))))))
  (note "staging" (if (stringp sd) sd
                      (let ((n (namestring sd)))
                        (cond ((search "/candidates/" n) "IN-CANDIDATES")
                              ((search "/releases/" n) "IN-RELEASES")
                              (t "ELSEWHERE"))))))

;; ② Η ΠΡΑΓΜΑΤΙΚΗ run-attest-release: αρνείται πριν γράψει;
(note "attest"
      (handler-case
          (progn (funcall (find-symbol "RUN-ATTEST-RELEASE" :orchestrator.cli) "probe") "NOT-REFUSED")
        (orchestrator.epistemic:legacy-authority-seat-removed () "REFUSED")
        (error (e) (format nil "OTHER:~A" (type-of e)))))

;; ③ Απευθείας απόπειρα εγγραφής στο read-only releases/ (ό,τι θα έκανε ο παλιός κώδικας)
(note "direct-write"
      (handler-case
          (progn (with-open-file (o (merge-pathnames "releases/pwned.txt" *base*)
                                    :direction :output :if-exists :supersede
                                    :if-does-not-exist :create)
                   (write-string "PWNED" o))
                 "SUCCEEDED")
        (error () "REFUSED-BY-KERNEL")))

(format t "~{~A~^ ~}~%" (nreverse *findings*))
(sb-ext:exit :code 0)
