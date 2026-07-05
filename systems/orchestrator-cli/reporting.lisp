;;;; systems/orchestrator-cli/reporting.lisp
;;;; Report generation

(in-package :orchestrator.cli)

(defun print-summary (context)
  "Print execution summary
  
  Args:
    context: Pipeline context"
  (let ((metrics (orchestrator.core:get-pipeline-metrics context)))
    (format t "~%=== EXECUTION SUMMARY ===~%")
    (format t "Duration: ~,2F seconds~%" 
            (/ (getf metrics :total-duration) internal-time-units-per-second))
    (format t "Stages: ~D total, ~D succeeded, ~D failed~%"
            (getf metrics :stage-count)
            (getf metrics :success-count)
            (getf metrics :failure-count))
    (format t "Errors: ~D~%" (getf metrics :error-count))))
