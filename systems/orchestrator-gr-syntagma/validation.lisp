;;;; systems/orchestrator-gr-syntagma/validation.lisp
;;;; Domain validation for Constitution

(in-package :orchestrator.gr-syntagma)

(defun validate-constitution-article (article)
  "Validate Constitution article
  
  Args:
    article: Article object
  
  Returns:
    T if valid, signals error otherwise"
  (valid-article-number-p (orchestrator.model:article-number article)))
