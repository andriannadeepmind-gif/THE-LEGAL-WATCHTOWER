(require :asdf) (require :sb-posix)
(defvar cl-user::*root* (uiop:ensure-directory-pathname (or (uiop:getenv "LAWMAX_REPO") (uiop:getcwd))))
(setf asdf:*central-registry*
      (append (list cl-user::*root*) (directory (merge-pathnames "systems/*/" cl-user::*root*))))
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(merge-pathnames "third-party/" cl-user::*root*)) :inherit-configuration))
(locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (handler-bind ((warning #'muffle-warning))
    (asdf:load-system :alexandria) (asdf:load-system :log4cl)
    (asdf:load-system :orchestrator-epistemic)
    (ignore-errors (asdf:load-system :orchestrator-core-runtime))
    (ignore-errors (asdf:load-system :orchestrator-cli))))
;; Ο ΠΡΑΓΜΑΤΙΚΟΣ production load graph — ΟΧΙ parsing κειμένου .asd.
;; Ρωτάμε το ΙΔΙΟ το ASDF ποια cl-source-file components ανήκουν στα
;; παραγωγικά systems. Ό,τι δεν είναι εδώ, ΔΕΝ φορτώνεται στην παραγωγή.
(let ((seen (make-hash-table :test #'equal)))
  (labels ((walk (c)
             (typecase c
               (asdf:cl-source-file
                (let ((p (asdf:component-pathname c)))
                  (when (and p (probe-file p))
                    (setf (gethash (namestring (truename p)) seen) t))))
               (asdf:parent-component
                (dolist (ch (asdf:component-children c)) (walk ch))))))
    (dolist (sys '("orchestrator-epistemic" "orchestrator-core-runtime" "orchestrator-cli"
                   "orchestrator-core" "orchestrator-model" "orchestrator-spec"
                   "orchestrator-infrastructure" "orchestrator-engine-sbcl"))
      (let ((s (ignore-errors (asdf:find-system sys nil))))
        (when s (walk s)))))
  (let ((files (sort (loop for k being the hash-keys of seen collect k) #'string<)))
    (dolist (f files) (format t "~A~%" f))))
(sb-ext:exit :code 0)
