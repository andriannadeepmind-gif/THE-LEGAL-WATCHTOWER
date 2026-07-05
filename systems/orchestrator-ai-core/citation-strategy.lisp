;;;; systems/orchestrator-ai-core/citation-strategy.lisp
;;;; AI citation strategy

(in-package :orchestrator.ai-core)

(defun compute-citation-weight (article)
  "Compute citation authority weight for article
  
  Args:
    article: Article object
  
  Returns:
    Weight score (0.0-1.0)"
  (declare (ignore article))
  1.0)
