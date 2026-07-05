;;;; systems/orchestrator-core/package.lisp
;;;; Package definition for Orchestrator Core Execution Engine

(in-package :cl-user)

(defpackage #:orchestrator.core
  (:use :cl)
  (:import-from :orchestrator.spec
                #:run-pipeline
                #:run-stage
                #:validate-pipeline
                #:orchestrator-error
                #:stage-error
                #:dependency-error)
  (:import-from :orchestrator.model
                #:article
                #:corpus
                #:artifact)
  (:export
   ;; === PIPELINE CONTEXT ===
   #:pipeline-context
   #:make-pipeline-context
   #:cleanup-pipeline-context
   #:get-context-value
   #:set-context-value
   #:context-pipeline
   #:context-config
   #:context-artifacts
   #:context-errors
   #:context-trace
   #:context-bindings
   
   ;; === DEPENDENCY GRAPH ===
   #:build-dependency-graph
   #:topological-sort
   #:detect-circular-dependencies
   #:get-stage-dependencies
   
   ;; === EXECUTORS ===
   #:sequential-executor
   #:parallel-executor
   #:execute-pipeline
   #:execute-stage
   
   ;; === ARTIFACT CACHE ===
   #:artifact-cache
   #:make-artifact-cache
   #:cache-artifact
   #:lookup-artifact
   #:cache-has-artifact-p
   #:cache-clear
   #:cache-size
   
   ;; === INSTRUMENTATION ===
   #:with-instrumentation
   #:record-stage-start
   #:record-stage-end
   #:get-stage-metrics
   #:get-pipeline-metrics

   ;; === SOURCE DETECTION (Generic - no hardcoded paths) ===
   #:get-env
   #:validate-directory-path
   #:validate-file-path
   #:find-pdf-in-dir
   #:detect-source-config
   #:get-runtime-source-config))
