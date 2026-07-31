;;;; authority-v2/tests/staging-helper.lisp
;;;; Κοινός κατασκευαστής staging για τα probes της Δ2–Δ3 απόδειξης.
;;;; ΔΕΝ δηλώνεται σε κανένα .asd — φορτώνεται ΜΟΝΟ από probes/tests.
(in-package :cl-user)

(defun make-probe-staging (base tag)
  "Χτίζει πλήρες canonical staging και επιστρέφει (values staging root id)."
  (let* ((staging (merge-pathnames (format nil ".staging-~A/" tag) base)))
    (ensure-directories-exist (merge-pathnames "shapes/" staging))
    (ensure-directories-exist (merge-pathnames "verify/" staging))
    (ensure-directories-exist (merge-pathnames "temporal-proof/" staging))
    (dolist (f orchestrator.epistemic::+epistemic-canonical-files+)
      (with-open-file (o (merge-pathnames f staging) :direction :output
                         :if-exists :supersede :external-format :utf-8)
        (format o "~A περιεχόμενο ~A~%" f tag)))
    (let ((root (orchestrator.epistemic::merkle-tree-root
                 (orchestrator.epistemic::build-merkle-tree
                  (orchestrator.epistemic::collect-epistemic-artifacts staging)))))
      (with-open-file (o (merge-pathnames "temporal-proof/merkle-tree.json" staging)
                         :direction :output :if-exists :supersede)
        (format o "{\"root\":~S,\"totalFiles\":~D}~%"
                root (length orchestrator.epistemic::+epistemic-canonical-files+)))
      (values staging root (orchestrator.epistemic::%root->release-id root)))))
