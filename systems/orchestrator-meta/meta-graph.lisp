;;;; systems/orchestrator-meta/meta-graph.lisp
;;;; Graph visualization of meta-model

(in-package :orchestrator.meta)

(defun pipeline-to-graph (pipeline)
  "Convert pipeline to graph representation
  
  Args:
    pipeline: Pipeline object
  
  Returns:
    Graph alist"
  (orchestrator.spec:pipeline-dependency-graph pipeline))
