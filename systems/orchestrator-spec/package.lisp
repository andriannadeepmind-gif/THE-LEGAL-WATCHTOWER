;;;; systems/orchestrator-spec/package.lisp
;;;; Package definition for Orchestrator Specification Layer

(in-package :cl-user)

(defpackage #:orchestrator.spec
  (:use :cl)
  (:export
   ;; === PROTOCOLS ===
   ;; Pipeline protocols
   #:run-pipeline
   #:run-stage
   #:validate-pipeline
   #:introspect-pipeline
   #:valid-transition-p
   #:transition
   #:add-article
   #:get-article
   #:corpus-article-count
   
   ;; Artifact protocols
   #:build-artifact
   #:serialize-artifact
   #:deserialize-artifact
   #:anchor-artifact
   #:artifact-dependencies
   #:artifact-hash
   
   ;; === CONDITIONS ===
   ;; Base condition
   #:orchestrator-error
   #:error-message
   #:error-component
   #:error-article
   #:error-context
   
   ;; Specific errors
   #:xml-parse-error
   #:rdf-error
   #:validation-error
   #:blockchain-error
   #:config-error
   #:dependency-error
   #:stage-error
   #:artifact-error
   #:error-validation-type
   
   ;; === RESTARTS ===
   #:retry-stage
   #:skip-article
   #:mark-degraded-and-continue
   #:abort-pipeline
   #:use-cached-artifact
   #:retry-with-backoff
   
   ;; === TYPES ===
   #:article-state
   #:pipeline-state
   #:backend-type
   #:artifact-type
   #:stage-name
   #:eli-uri
   #:language-code
   #:valid-eli-uri-p
   #:valid-language-code-p

   ;; === VERSION ===
   ;; System version (canonical source)
   #:+system-version+
   #:+pipeline-version+
   #:+version+

   ;; === DSL ===
   ;; Pipeline DSL macro
   #:defpipeline
   #:defstage
   #:pipeline
   #:stage
   #:with-pipeline-context
   
   ;; Pipeline data structure accessors
   #:pipeline-name
   #:pipeline-stages
   #:pipeline-corpus
   #:pipeline-config
   #:pipeline-metadata
   
   #:stage-name
   #:stage-function
   #:stage-dependencies
   #:stage-produces
   #:stage-condition-handlers
   
   ;; === INTROSPECTION ===
   #:list-all-pipelines
   #:list-all-stages
   #:describe-pipeline
   #:describe-stage
   #:find-pipeline
   #:find-stage
   #:pipeline-dependency-graph
   #:stage-artifact-flow

   ;; === ΩMEGA ENGINE - FRBR GENERATION ===
   #:make-complete-frbr-stack
   #:generate-unified-article-ttl
   #:validate-frbr-stack
   #:generate-rdf
   #:generate-rdf-with-activity

   ;; === ΩMEGA ENGINE - CORPUS ROOT ===
   #:corpus-root
   #:make-corpus-root
   #:generate-corpus-manifest-ttl
   #:corpus-id
   #:corpus-name
   #:corpus-uri
   #:issued-date
   #:modified-date
   #:article-uris
   #:publisher
   #:contributor

   ;; === CONFIG ACCESSORS (LEVEL 300) ===
   #:load-constitution-config
   #:ensure-config-loaded
   #:config-get
   
   ;; Required config infrastructure
   #:missing-required-config
   #:missing-config-key
   #:missing-config-path
   #:required-config
   #:validate-required-config

   ;; Person identity
   #:person-webid
   #:person-name
   #:person-given-name
   #:person-family-name
   #:person-orcid
   #:person-bar-number
   #:person-job-title
   #:person-email
   #:person-telephone
   #:person-linkedin
   #:person-twitter
   #:person-university
   #:person-degree
   #:person-graduation-year

   ;; Organization identity
   #:org-webid
   #:org-name
   #:org-legal-name
   #:org-trademark
   #:org-url
   #:org-logo
   #:org-email
   #:org-telephone
   #:org-address-street
   #:org-address-city
   #:org-address-postal-code
   #:org-address-region
   #:org-address-country
   #:org-founded
   #:org-founding-location
   #:org-linkedin
   #:org-twitter

   ;; ODRL policy
   #:odrl-enabled-p
   #:odrl-policy-uri
   #:odrl-attribution-text
   #:odrl-attribution-url

   ;; HTML generation
   #:html-enabled-p
   #:html-output-directory
   #:html-include-organization-p
   #:html-include-ceo-p
   #:html-include-founder-p
   #:html-include-address-p
   #:html-include-social-proof-p
   #:html-canonical-base
   #:html-robots
   #:canonical-base-uri

   ;; Corpus selection (multi-law support)
   #:select-corpus
   #:*corpus-config-registry*

   ;; VoID Dataset
   #:generate-void-dataset-descriptor

   ;; Cryptographic utilities
   #:calculate-sha256-hash

   ;; Hybrid generator functions
   #:generate-hybrid-phase1-ttl
   #:parse-article-into-paragraphs
   #:split-article-paragraph-chunks
   #:generate-identity-triples
   #:generate-odrl-policy

   ;; FRBR error handling
   #:frbr-generation-error
   #:invalid-frbr-instance
   #:article-data-missing
   #:rdf-output-invalid
   #:file-write-error
   #:with-frbr-error-handling
   #:with-abortable-pipeline
   #:validate-article-data
   #:write-rdf-file-safe
   #:skip-article-restart
   #:use-default-value-restart
   #:retry-generation-restart
   #:abort-pipeline-restart

   ;; Unified FRBR generator
   #:make-complete-frbr-stack
   #:generate-unified-article-ttl
   #:generate-rdf-with-activity
   #:write-unified-article-file

   ;; HTML RDFa generator (TIER 2)
   #:generate-html-head
   #:generate-jsonld-organization
   #:generate-jsonld-breadcrumb
   #:generate-jsonld-faq
   #:generate-jsonld-article
   #:generate-html-with-rdfa

   #:escape-turtle-string
   #:escape-json-string
   #:escape-html))
