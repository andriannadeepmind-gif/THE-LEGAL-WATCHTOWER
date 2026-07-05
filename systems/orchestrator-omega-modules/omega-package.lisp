;;;; systems/orchestrator-omega-modules/omega-package.lisp
;;;; ΟΜΕΓΑ Unified Package Definition
;;;; Re-exports all FRBR functionality from component packages

(defpackage :orchestrator.omega
  (:use :cl
        :orchestrator.model
        :orchestrator.frbr
        :orchestrator.dsl.turtle)

  ;; orchestrator.spec symbols imported explicitly (not :use) to avoid CORPUS-NAME conflict
  (:import-from :orchestrator.spec
                #:generate-rdf
                #:generate-rdf-with-activity
                #:emit-triples
                #:validate-instance
                #:compute-provenance
                #:layer-name
                #:frbr-generation-error
                #:invalid-frbr-instance
                #:article-data-missing
                #:rdf-output-invalid
                #:file-write-error
                #:skip-article-restart
                #:use-default-value-restart
                #:retry-generation-restart
                #:abort-pipeline-restart
                #:with-frbr-error-handling
                #:with-abortable-pipeline)

  (:nicknames :omega :ω)
  
  (:documentation 
   "ΟΜΕΓΑ-LEVEL FRBR Generation System
    
    This package provides DARPA-class semantic web generation capabilities
    using the full power of Common Lisp:
    
    • CLOS with MOP metaclasses for type-safe FRBR modeling
    • Macro-based DSL for deterministic RDF generation  
    • Generic function protocol with method combinations
    • Condition/restart system for robust error handling
    • Compiler declarations for optimized performance
    
    Usage:
      (ql:quickload \"orchestrator-omega\")
      (omega:run-frbr-generation-stage context
        :layers '(:work :expression)
        :output-dir #P\"/output/frbr/\"
        :parallel t)")
  
  (:export
   ;; CLOS Classes from orchestrator.model
   #:frbr-resource-class
   #:frbr-resource
   #:frbr-work
   #:frbr-expression
   #:frbr-manifestation
   #:frbr-format
   
   ;; Constructors from orchestrator.model
   #:make-frbr-work
   #:make-frbr-expression
   #:make-frbr-manifestation
   #:make-frbr-format
   
   ;; Accessors from orchestrator.model
   #:resource-uri
   #:eli-identifier
   #:article-number
   #:expression-work
   #:expression-title
   #:expression-content
   #:expression-language
   
   ;; Generic Protocol from orchestrator.spec
   #:generate-rdf
   #:emit-triples
   #:validate-instance
   #:compute-provenance
   #:layer-name
   
   ;; DSL Macros from orchestrator.dsl.turtle
   #:with-turtle-output
   #:with-resource
   #:with-frbr-context
   #:define-rdf-generator
   #:emit-triple
   #:emit-prefixes
   
   ;; Conditions from orchestrator.spec
   #:frbr-generation-error
   #:invalid-frbr-instance
   #:article-data-missing
   #:rdf-output-invalid
   #:file-write-error
   
   ;; Restarts from orchestrator.spec
   #:skip-article-restart
   #:use-default-value-restart
   #:retry-generation-restart
   #:abort-pipeline-restart
   
   ;; Error Handling Macros from orchestrator.spec
   #:with-frbr-error-handling
   #:with-abortable-pipeline
   
   ;; Pipeline from orchestrator.frbr
   ;; NOTE: per-layer writers and generate-all-*-layers batch generators were
   ;; removed as dead code; the unified single-emission path
   ;; (orchestrator.spec:write-unified-article-file) is the canonical writer.
   #:frbr-generation-stage
   #:execute-stage
   #:run-frbr-generation-stage))

(in-package :orchestrator.omega)

;;; Package loaded - all ΟΜΕΓΑ functionality is now available
