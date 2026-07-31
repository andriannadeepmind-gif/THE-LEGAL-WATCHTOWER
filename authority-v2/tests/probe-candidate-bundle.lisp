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
;; ③ ΠΡΑΓΜΑΤΙΚΟ bundle: το candidates/<id>/ πρέπει να περιέχει ΟΛΑ τα canonical
;;    αρχεία, όχι έναν marker. Ελέγχεται με ΠΡΑΓΜΑΤΙΚΗ κλήση του publish path.
(load (merge-pathnames "authority-v2/tests/staging-helper.lisp" cl-user::*root*))
(let* ((base (uiop:ensure-directory-pathname
              (merge-pathnames (format nil "l7bundle-~D/" (random 100000000))
                               (uiop:temporary-directory)))))
  (ensure-directories-exist base)
  (unwind-protect
       (multiple-value-bind (staging root id) (make-probe-staging base "bundle")
         (declare (ignore root))
         (let* ((final (orchestrator.epistemic::atomic-publish-release base staging id))
                (files (directory (merge-pathnames "**/*.*" (uiop:ensure-directory-pathname final))))
                (n (length files))
                (in-cand (search "candidates" (namestring final)))
                (no-rel (not (probe-file (merge-pathnames "releases/" base)))))
           (format t "~A~%"
                   (cond ((not in-cand) "NOT-IN-CANDIDATES")
                         ((not no-rel) "RELEASES-WAS-WRITTEN")
                         ((< n 5) (format nil "MARKER-ONLY(~D αρχεία)" n))
                         (t (format nil "BUNDLE-OK ~D αρχεία στο candidates/" n))))))
    (ignore-errors (uiop:delete-directory-tree base :validate (constantly t)))))
(sb-ext:exit :code 0)
