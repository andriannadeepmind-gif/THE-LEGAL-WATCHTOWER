;;;; systems/orchestrator-meta/queries.lisp
;;;; Query API for meta-system

(in-package :orchestrator.meta)

(defun describe-pipeline (name)
  "Describe a registered pipeline
  
  Args:
    name: Pipeline name
  
  Returns:
    Description plist"
  (let ((pipeline (get-pipeline name)))
    (when pipeline
      (orchestrator.spec:describe-pipeline pipeline))))

(defun describe-corpus (name)
  "Describe a registered corpus
  
  Args:
    name: Corpus name
  
  Returns:
    Description plist"
  (let ((corpus (get-corpus name)))
    (when corpus
      (list :name (orchestrator.model:corpus-name corpus)
            :short-name (orchestrator.model:corpus-short-name corpus)
            :article-count (orchestrator.spec:corpus-article-count corpus)
            :eli-prefix (orchestrator.model:corpus-eli-prefix corpus)))))
