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
;; Στήνουμε ΠΡΑΓΜΑΤΙΚΟ legacy release με evidence και μετράμε αν αγγίχτηκε.
(let* ((base (uiop:ensure-directory-pathname
              (merge-pathnames (format nil "attest-~D/" (random 100000000))
                               (uiop:temporary-directory))))
       (rel (merge-pathnames "releases/sha256-aaa/temporal-proof/" base))
       (marker (merge-pathnames "existing.txt" rel)))
  (ensure-directories-exist rel)
  (with-open-file (o marker :direction :output :if-exists :supersede) (write-string "EVIDENCE" o))
  (let* ((before (uiop:read-file-string marker))
         (result
           (handler-case
               (progn (funcall (find-symbol "RUN-ATTEST-RELEASE" :orchestrator.cli)
                               "probe" :release-id-arg "sha256-aaa")
                      :accepted)
             (orchestrator.epistemic:legacy-authority-seat-removed () :refused)
             (error (e) (if (search "attest-release" (princ-to-string e)) :other-error :other-error))))
         (after (uiop:read-file-string marker))
         (tsr (probe-file (merge-pathnames "timestamp.tsr" rel))))
    (format t "~A~%"
            (cond ((not (eq result :refused)) (format nil "NOT-REFUSED(~A)" result))
                  (tsr "REFUSED-BUT-TSR-WRITTEN")
                  ((not (equal before after)) "REFUSED-BUT-EVIDENCE-MUTATED")
                  (t "REFUSED-BEFORE-WRITE (κανένα byte στο releases/)")))
    (ignore-errors (uiop:delete-directory-tree base :validate (constantly t)))))
(sb-ext:exit :code 0)
