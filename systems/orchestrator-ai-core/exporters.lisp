;;;; systems/orchestrator-ai-core/exporters.lisp
;;;; Export provenance data

(in-package :orchestrator.ai-core)

(defun export-provenance-json (article)
  "Export article provenance as JSON
  
  Args:
    article: Article object
  
  Returns:
    JSON string"
  (jonathan:to-json
   `(:|article| ,(orchestrator.model:article-number article)
     :|hash| ,(orchestrator.model:article-hash article)
     :|proof| ,(orchestrator.model:article-blockchain-proof article))
   :from :alist))
