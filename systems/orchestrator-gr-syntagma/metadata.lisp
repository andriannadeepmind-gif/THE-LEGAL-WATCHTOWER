;;;; systems/orchestrator-gr-syntagma/metadata.lisp
;;;; ELI URIs for Greek Constitution

(in-package :orchestrator.gr-syntagma)

(defun generate-eli-uri (article-number)
  "Generate ELI URI for Constitution article
  
  Args:
    article-number: Article number (1-120)
  
  Returns:
    ELI URI string"
  (format nil "http://data.europa.eu/eli/const/gr/1975/article-~3,'0D"
          article-number))
