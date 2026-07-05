;;;; systems/orchestrator-meta/reports.lisp
;;;; Report generation (JSON/TTL)

(in-package :orchestrator.meta)

(defun generate-json-report (pipeline context)
  "Generate JSON report of pipeline execution
  
  Args:
    pipeline: Pipeline object
    context: Pipeline context
  
  Returns:
    JSON string"
  (jonathan:to-json
   `(:|pipeline| ,(orchestrator.spec:pipeline-name pipeline)
     :|metrics| ,(orchestrator.core:get-pipeline-metrics context)
     :|errors| ,(length (orchestrator.core:context-errors context)))
   :from :alist))

(defun generate-ttl-report (pipeline context)
  "Generate Turtle report of pipeline execution
  
  Args:
    pipeline: Pipeline object
    context: Pipeline context
  
  Returns:
    Turtle string"
  (format nil "@prefix orch: <https://orchestrator.stavropouloslaw.com/vocab#> .

<#run> a orch:PipelineRun ;
    orch:pipeline \"~A\" ;
    orch:timestamp \"~A\" .
"
          (orchestrator.spec:pipeline-name pipeline)
          (orchestrator.time:now :source :system)))
