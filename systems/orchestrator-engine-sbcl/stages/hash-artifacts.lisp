;;;; systems/orchestrator-engine-sbcl/stages/hash-artifacts.lisp
;;;; Blake3 hashing stage

(in-package :orchestrator.engine.sbcl)

(defun hash-artifacts-stage (context)
  "Compute Blake3 hashes for all articles"
  (let ((articles (orchestrator.core:get-context-value context :articles)))
    (unless articles
      (error 'orchestrator.spec:config-error
             :message "No articles in context"
             :config-key :articles))
    
    (log:info () "Computing hashes for ~D articles" (length articles))
    
    (loop for article in articles
          do (hash-article-artifacts article))
    
    (orchestrator.core:set-context-value context :articles articles)
    context))

(defun hash-article-artifacts (article)
  "Hash canonical article content using SHA-512"
  (orchestrator.spec:transition article :hashing)

  (let ((canonical-ttl (orchestrator.model:article-rdf-turtle article)))
    (unless canonical-ttl
      (error "Cannot hash article ~A: no canonical TTL content"
             (orchestrator.model:article-file-id article)))

    (let ((hash (orchestrator.hash-authority:compute-hash canonical-ttl :algorithm :sha512)))
      (setf (orchestrator.model:article-hash article) hash)
      (log:info () "Article ~A hash: ~A"
                (orchestrator.model:article-file-id article) hash)
      (orchestrator.spec:transition article :anchoring)
      article)))