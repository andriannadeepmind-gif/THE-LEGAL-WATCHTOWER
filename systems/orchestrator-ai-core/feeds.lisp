;;;; systems/orchestrator-ai-core/feeds.lisp
;;;; AI feeds generation

(in-package :orchestrator.ai-core)

(defun generate-ai-feed (corpus)
  "Generate AI feed for corpus
  
  Args:
    corpus: Corpus object
  
  Returns:
    Feed data"
  (list :corpus (orchestrator.model:corpus-name corpus)
        :articles (orchestrator.spec:corpus-article-count corpus)
        :timestamp (orchestrator.time:now :source :system)))
