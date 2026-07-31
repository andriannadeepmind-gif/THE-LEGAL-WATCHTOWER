(require :asdf) (require :sb-posix)
(defvar cl-user::*root* (uiop:ensure-directory-pathname (or (uiop:getenv "LAWMAX_REPO") (uiop:getcwd))))
(setf asdf:*central-registry*
      (append (list cl-user::*root*) (directory (merge-pathnames "systems/*/" cl-user::*root*))))
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(merge-pathnames "third-party/" cl-user::*root*)) :inherit-configuration))
(locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (handler-bind ((warning #'muffle-warning))
    (asdf:load-system :alexandria) (asdf:load-system :log4cl)
    (asdf:load-system :orchestrator-epistemic)))
;; ① Στη ΦΟΡΤΩΜΕΝΗ παραγωγική εικόνα: κανένας writer του legacy log.
(let ((w (find-symbol "%TLOG-WRITE" :orchestrator.epistemic))
      (w1 (find-symbol "%TLOG-WRITE-1" :orchestrator.epistemic))
      (r (find-symbol "%TLOG-READ" :orchestrator.epistemic)))
  (format t "~A~%"
          (cond ((and w (fboundp w)) "WRITE-PRESENT(%tlog-write fbound)")
                ((and w1 (fboundp w1)) "WRITE-PRESENT(%tlog-write-1 fbound)")
                ((not (and r (fboundp r))) "READER-MISSING")
                (t "WRITE-ABSENT reader-present"))))
(sb-ext:exit :code 0)
