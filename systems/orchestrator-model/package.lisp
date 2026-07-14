;;;; systems/orchestrator-model/package.lisp
;;;; Package definition for Orchestrator Data Model

(in-package :cl-user)

(defpackage #:orchestrator.model
  (:use :cl)
  (:import-from :closer-mop
                ;; Core metaclass inheritance
                #:standard-class
                #:standard-direct-slot-definition
                #:standard-effective-slot-definition
                #:validate-superclass
                #:finalize-inheritance
                #:compute-effective-slot-definition
                ;; Slot access
                #:class-slots
                #:slot-definition-name
                #:slot-definition-initargs
                #:slot-definition-initform
                #:slot-definition-type
                #:slot-boundp-using-class
                #:slot-value-using-class
                ;; Slot definition classes
                #:direct-slot-definition-class
                #:effective-slot-definition-class)
  (:import-from :orchestrator.time
                #:get-iso8601-timestamp)
  (:export
   ;; === METACLASSES ===
   #:validated-class
   #:article-class
   #:corpus-class
   #:artifact-class
   
   ;; === ARTICLE CLASS ===
   #:article
   #:article-number
   #:article-label
   #:article-file-id
   #:pad-article-id
   #:article-uri-id
   #:article-identity-segment
   #:article-base-number
   #:article-label-suffix
   #:article-suffix-ordinal
   #:article-identity          ; [0088 Φ6γ] typed identity segment από την έδρα
   #:article-uri               ; [0088 Φ6γ-Δ2] object-level uri προβολή («5Α»)
   #:article-identity<
   #:articles-in-identity-order
   #:article-title
   #:article-content
   #:article-processing-state
   #:article-eli-uri
   #:article-rdf-turtle
   #:article-json-ld
   #:article-html
   #:article-hash
   #:article-blockchain-proof
   #:article-errors
   #:article-retry-count
   #:article-metadata
   
   ;; === CORPUS CLASS ===
   #:corpus
   #:corpus-name
   #:corpus-short-name
   #:corpus-articles
   #:corpus-eli-prefix
   #:corpus-publication-date
   #:corpus-language
   #:corpus-webid
   #:corpus-orcid
   #:corpus-blockchain-manifest
   #:corpus-master-hash
   #:corpus-qes-signature
   #:corpus-metadata
   
   ;; === ARTIFACT PROTOCOL ===
   #:artifact
   #:artifact-name
   #:artifact-output-type
   #:artifact-content
   #:artifact-hash-value
   #:artifact-dependency-list
   #:artifact-metadata
   
   ;; === BUILDERS ===
   #:make-article
   #:make-corpus
   #:make-artifact
   
   ;; === SCHEMA INTROSPECTION ===
   #:get-class-schema
   #:list-all-article-classes
   #:list-all-corpus-classes
   #:class-has-slot-p
   #:get-slot-definition

   ;; === FRBR CLASSES ===
   #:frbr-resource-class
   #:frbr-resource
   #:frbr-work
   #:frbr-expression
   #:frbr-manifestation
   #:frbr-format

   ;; === FRBR ACCESSORS - Common ===
   #:resource-uri
   #:eli-identifier
   #:created-at
   #:resource-provenance

   ;; === FRBR ACCESSORS - Work ===
   #:article-number
   #:article-root-uri
   #:jurisdiction
   #:document-type
   #:issued-date
   #:law-year
   #:dataset-uri
   #:dataset-version
   #:part-of
   #:realizations

   ;; === FRBR ACCESSORS - Expression ===
   #:expression-work
   #:expression-language
   #:expression-title
   #:expression-content
   #:embodiments
   #:paragraphs

   ;; === FRBR ACCESSORS - Manifestation ===
   #:manifestation-expression
   #:access-url
   #:download-url
   #:license
   #:formats

   ;; === FRBR ACCESSORS - Format ===
   #:format-manifestation
   #:format-type
   #:media-type
   #:dct-format
   #:file-extension
   #:byte-size
   #:format-byte-size

   ;; === FRBR ARTICLE ROOT ===
   #:frbr-article-root
   #:make-frbr-article-root
   #:article-letter-suffix
   #:work-uri
   #:parent-document

   ;; === FRBR URI COLLECTIONS ===
   #:expression-uris
   #:manifestation-uris
   #:format-uris

   ;; === FRBR CONSTRUCTORS ===
   #:make-frbr-work
   #:make-frbr-expression
   #:make-frbr-manifestation
   #:make-frbr-format

   ;; === PROV-O ACTIVITY ===
   #:prov-activity
   #:make-prov-activity
   #:activity-article-number
   #:activity-corpus-name
   #:activity-start-time
   #:activity-end-time
   #:activity-human-agent
   #:activity-software-agent
   #:activity-source-text-uri
   #:add-generated-entity

   ;; === GREEK LAW TYPE REGISTRY (also exported via runtime export in greek-law-types.lisp) ===
   #:law-type-eu-resource-uri
   #:law-type-schema-legislation-type
   #:law-type-greek-name
   #:law-type-eli-code
   #:law-type-fek-issue
   #:law-type-keyword-from-eli-code
   #:find-law-type-entry
   #:list-all-law-types
   #:build-eli-law-prefix
   #:build-eli-article-uri
   #:+greek-law-type-registry+

   ;; === FRBR HELPERS ===
   #:get-iso8601-timestamp
   #:get-media-type
   #:get-dct-format
   #:get-file-extension

   ;; === NORMALIZED INPUT - IIR ===
   #:normalized-article-input
   #:make-normalized-article-input
   #:article-to-normalized-input
   #:normalize-text
   #:article-label
   #:source-type
   #:source-path
   #:extraction-timestamp
   #:extraction-confidence
   #:source-metadata))
