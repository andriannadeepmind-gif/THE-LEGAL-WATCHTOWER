;;;; Χτίζει ΜΙΑ φορά ένα saved SBCL core με ΠΡΟΦΟΡΤΩΜΕΝΟ το orchestrator-cli.
;;;; Το OS-boundary test μετά ΦΟΡΤΩΝΕΙ αυτό το core (ms, καμία μεταγλώττιση) —
;;;; ώστε το όριο ασφαλείας να δοκιμάζεται ΚΑΘΑΡΟ, χωρίς fasl-cache θόρυβο.
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
(sb-ext:save-lisp-and-die (second sb-ext:*posix-argv*) :executable nil)
