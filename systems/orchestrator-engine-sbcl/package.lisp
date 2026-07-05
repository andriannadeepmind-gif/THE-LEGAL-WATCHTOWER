;;;; systems/orchestrator-engine-sbcl/package.lisp
;;;; Package definition for SBCL-specific Engine

(in-package :cl-user)

(defpackage #:orchestrator.engine.sbcl
  (:use :cl)
  (:import-from :orchestrator.spec
                #:run-stage
                #:build-artifact
                #:serialize-artifact
                #:anchor-artifact
                #:orchestrator-error
                #:rdf-error
                #:validation-error
                #:blockchain-error
                #:escape-turtle-string
                #:escape-html)
  (:import-from :orchestrator.model
                #:article
                #:corpus
                #:article-number
                #:article-title
                #:article-content
                #:article-eli-uri
                #:article-rdf-turtle
                #:article-json-ld
                #:article-html
                #:article-hash
                #:corpus-eli-prefix
                #:corpus-webid
                #:corpus-orcid
                #:corpus-short-name)
  (:import-from :orchestrator.core
                #:pipeline-context
                #:get-context-value
                #:set-context-value)
  (:import-from :orchestrator.ai-core
                #:generate-article-manifest-entry
                #:manifest-entry-to-json)
  (:import-from :closer-mop
                #:generic-function-methods
                #:method-specializers
                #:method-qualifiers
                #:eql-specializer
                #:eql-specializer-object)
  (:export
   ;; === STAGES ===
   #:source-normalize-stage
   #:load-json-source-stage
   #:parse-pdf-stage
   #:pdf-adapter
   #:+article-suffix-regex+
   #:parse-raw-text-stage
   #:generate-rdf-stage
   #:consolidate-stage
   #:test-escaping-stage
   #:*test-escaping-stage-executed*  ; Legacy tripwire flag
   #:*test-escaping-proof*  ; Execution proof (PHASE 2)
   #:test-escaping-proof  ; Struct type
   #:valid-proof-p
   #:compute-proof-hash
   #:test-escaping-proof-proof-hash
   #:test-escaping-proof-graph-position
   #:validate-shacl-stage
   #:hash-artifacts-stage
   #:anchor-blockchain-stage
   #:deploy-stage
   #:deploy-epistemic-stage
   
   ;; === BACKENDS ===
   #:ethereum-backend
   #:arweave-backend
   #:ipfs-backend
   #:mock-backend
   
   ;; Backend operations
   #:backend-anchor
   #:backend-upload
   #:backend-retrieve
   
   ;; === TEMPLATES ===
   #:render-turtle
   #:render-json-ld
   #:render-html-rdfa
   
   ;; === ADAPTERS ===
   #:raw-text-adapter
   #:raw-text->iir-articles
   #:group-text-into-layout-document
   ;; .docx (Office Open XML) authoritative-source adapter
   #:docx-adapter
   #:docx->text
   #:docx-error
   #:docx-backend-missing
   #:docx-malformed
   ;; raw-text adapter conditions
   #:raw-text-error
   #:raw-text-empty-source
   #:raw-text-no-articles
   #:raw-text-layer-error
   #:raw-text-iir-warning
   #:raw-text-fek-not-implemented
   #:rte-layer
   #:rte-block-count
   ;; raw-text pre-processor (normalize PDF artifacts before FSM)
   #:normalize-greek-legal-text
   ;; raw-text demo + self-test (Layer 1 end-to-end, no external modules needed)
   #:demo-raw-text-pipeline
   ;; raw-text MOP introspection (static: method definitions)
   #:collect-fsm-transitions
   #:describe-fsm
   #:validate-fsm-coverage
   ;; raw-text runtime audit (dynamic: actual dispatch calls)
   #:auditing-generic-function
   #:gf-transition-count
   #:gf-audit-table
   #:describe-advance-audit
   ;; declarative FSM macro
   #:deftransition
   ;; SATISFIES domain types
   #:non-empty-string
   #:article-header-text
   #:raw-text-fsm-state
   ;; raw-text named readtable + dynamic scope macro
   #:orchestrator.raw-text           ; readtable name keyword
   #:with-raw-text-readtable

   ;; === FILESYSTEM ===
   #:ensure-output-directory
   #:write-artifact-to-file
   #:read-artifact-from-file))
