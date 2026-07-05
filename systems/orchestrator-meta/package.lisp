;;;; systems/orchestrator-meta/package.lisp
;;;; Package definition for Meta-Introspection System

(in-package :cl-user)

(defpackage #:orchestrator.meta
  (:use :cl)
  (:export
   ;; === REGISTRIES ===
   #:*pipeline-registry*
   #:*corpus-registry*
   #:*backend-registry*
   #:register-pipeline
   #:register-corpus
   #:register-backend
   #:get-pipeline
   #:get-corpus
   #:get-backend
   
   ;; === QUERIES ===
   #:list-pipelines
   #:list-corpora
   #:list-backends
   #:describe-pipeline
   #:describe-corpus
   
   ;; === TOOL VERSIONS ===
   #:capture-tool-versions
   #:get-tool-version
   
   ;; === REPORTS ===
   #:generate-json-report
   #:generate-ttl-report))
