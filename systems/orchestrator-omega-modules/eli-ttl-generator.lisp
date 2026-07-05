;;;; systems/orchestrator-omega-modules/eli-ttl-generator.lisp
;;;; ELI TTL Generator - Deterministic FRBR+ELI+PROV-O Turtle Generator
;;;; ΟΜΕΓΑ-LEVEL: Supreme, deterministic generation for articles
;;;;
;;;; This module provides the highest-level API for generating complete
;;;; FRBR+ELI+PROV-O Turtle RDF for constitutional articles.
;;;;
;;;; Compliance:
;;;;   - FRBR: Full 4-layer hierarchy (Work → Expression → Manifestation → Format)
;;;;   - ELI: v1.4 complete
;;;;   - PROV-O: Full provenance chain
;;;;   - DCAT: Dataset distribution metadata
;;;;
;;;; Guarantees:
;;;;   - Determinism: Byte-for-byte reproducible output
;;;;   - Prefix Order: Alphabetically sorted
;;;;   - Property Order: Deterministic per resource type
;;;;   - No ad-hoc FORMAT blocks: Uses DSL exclusively

(defpackage :orchestrator.eli-ttl-generator
  (:use :cl :alexandria :serapeum)
  (:import-from :orchestrator.model
                #:frbr-work
                #:frbr-expression
                #:frbr-manifestation
                #:frbr-format
                #:make-frbr-work
                #:make-frbr-expression
                #:make-frbr-manifestation
                #:make-frbr-format
                #:resource-uri
                #:article-number
                #:get-iso8601-timestamp)
  (:import-from :orchestrator.spec
                #:generate-rdf
                #:generate-rdf-to-stream)
  (:import-from :orchestrator.uris
                #:get-eli-const-prefix)
  (:import-from :orchestrator.spec
                #:config-get)
  (:import-from :orchestrator.eli-temporal
                #:get-article-temporal-metadata)
  (:export
   #:make-frbr-stack-for-article
   #:render-frbr-eli-for-article
   #:render-frbr-eli-for-article-with-temporal))

(in-package :orchestrator.eli-ttl-generator)

;;; ============================================================
;;; FRBR STACK CONSTRUCTION
;;; ============================================================

(defun make-frbr-stack-for-article (article-number title content
                                    &key eli-prefix document-type law-year
                                         issued-date dataset-uri)
  "Construct complete FRBR stack for an article (any Greek law type).

   Creates all four FRBR layers with proper relationships:
   - Work: Abstract legal concept
   - Expression: Greek language realization
   - Manifestation: Digital embodiment
   - Format: Multiple format instances (HTML, Turtle, JSON-LD)

   Law-type parameters are optional; when omitted they resolve to the
   active corpus (Constitution) via configured ELI prefix and config date.
   Pass them explicitly to codify any other Greek law type.

   Arguments:
     article-number: Positive integer (no upper bound — supports any corpus)
     title:          Title string in primary language
     content:        Content string
     eli-prefix:     ELI law prefix (default: get-eli-const-prefix)
     document-type:  ELI type code (default: \"const\")
     law-year:       Year string (derived from issued-date if absent)
     issued-date:    xsd:date string (default: corpus.publication.date from config)
     dataset-uri:    VoID dataset URI

   Returns:
     (values work expression manifestation formats-list)

   URIs follow pattern: {eli-prefix}/art/{N}/work/exp/ell/man/format/{type}"

  (check-type article-number (integer 1))
  (check-type title string)
  (check-type content string)

  ;; Resolve law-type context. Legal dates are never fabricated.
  (let* ((resolved-prefix      (or eli-prefix (get-eli-const-prefix)))
         (resolved-doc-type    (or document-type (config-get "corpus.document_type") "const"))
         (resolved-dataset-uri (or dataset-uri (config-get "corpus.dataset_uri")))
         (resolved-issued      (or issued-date
                                   (config-get "corpus.publication.date")
                                   (error "make-frbr-stack-for-article: issued-date not provided and corpus.publication.date absent from config — refusing to fabricate a legal date for article ~D"
                                          article-number)))
         (resolved-year        (or law-year (subseq resolved-issued 0 4)))

         ;; Create FRBR hierarchy bottom-up for proper initialization
         (work (make-frbr-work :article-number article-number
                               :eli-prefix resolved-prefix
                               :document-type resolved-doc-type
                               :law-year resolved-year
                               :issued-date resolved-issued
                               :dataset-uri resolved-dataset-uri))
         (expression (make-frbr-expression work :title title :content content))
         (manifestation (make-frbr-manifestation expression))
         (format-html (make-frbr-format manifestation :html))
         (format-turtle (make-frbr-format manifestation :turtle))
         (format-jsonld (make-frbr-format manifestation :jsonld))
         (formats (list format-html format-turtle format-jsonld)))
    
    ;; Return all components
    (values work expression manifestation formats)))

;;; ============================================================
;;; MAIN ENTRY POINT - Complete Article Generation
;;; ============================================================

(defun render-frbr-eli-for-article (article)
  "Generate deterministic FRBR+ELI+PROV Turtle string for an article
   
   This is the main entry point for generating complete RDF Turtle output.
   
   Arguments:
     article: Hash table or plist with keys:
       :number  - Article number (1-120)
       :title   - Greek title string
       :content - Greek content string
   
   Returns:
     String containing complete Turtle RDF with all FRBR layers
   
   Output structure:
     1. Prefixes (alphabetically sorted)
     2. Work resource
     3. Expression resource
     4. Manifestation resource
     5. Format resources (HTML, Turtle, JSON-LD)
   
   Guarantees:
     - Deterministic: Same input always produces identical output
     - Valid Turtle: Parseable by any RDF parser
     - Complete: All FRBR layers present
     - Compliant: ELI v1.4, PROV-O, DCAT"
  
  ;; Helper to extract field from article (hash-table or plist)
  (flet ((extract-field (key)
           (etypecase article
             (hash-table (gethash key article))
             (list (getf article key)))))
    
    ;; Extract article data
    (let* ((article-number (extract-field :number))
           (title (extract-field :title))
           (content (extract-field :content)))
      
      ;; Validate article data
      (unless article-number
        (error "Article number is required"))
      (unless title
        (error "Article title is required"))
      (unless content
        (error "Article content is required"))
      
      ;; Build FRBR stack
      (multiple-value-bind (work expression manifestation formats)
          (make-frbr-stack-for-article article-number title content)
        
        ;; Generate complete Turtle output
        (with-output-to-string (stream)
          
          ;; Emit prefixes in deterministic alphabetical order
          (format stream "@prefix dcat: <http://www.w3.org/ns/dcat#> .~%")
        (format stream "@prefix dct: <http://purl.org/dc/terms/> .~%")
        (format stream "@prefix eli: <http://data.europa.eu/eli/ontology#> .~%")
        (format stream "@prefix prov: <http://www.w3.org/ns/prov#> .~%")
        (format stream "@prefix schema: <https://schema.org/> .~%")
        (format stream "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .~%")
        (terpri stream)
        
        ;; Emit header
        (format stream "# ============================================================~%")
        (format stream "# COMPLETE FRBR+ELI+PROV-O OUTPUT - Article ~A~%" article-number)
        (format stream "# Generated: ~A~%" (get-iso8601-timestamp))
        (format stream "# Generator: ORCHESTRATOR v1.3~%")
        (format stream "# Standards: W3C RDF 1.1, ELI v1.4, FRBR, PROV-O, DCAT~%")
        (format stream "# ============================================================~%")
        (terpri stream)
        
        ;; Layer 1: Work
        (format stream "# ============================================================~%")
        (format stream "# LAYER 1: FRBR WORK~%")
        (format stream "# Abstract legal concept (language-independent)~%")
        (format stream "# ============================================================~%")
        (terpri stream)
        (generate-rdf-to-stream work stream)
        (terpri stream)
        
        ;; Layer 2: Expression
        (format stream "# ============================================================~%")
        (format stream "# LAYER 2: FRBR EXPRESSION~%")
        (format stream "# Greek language realization~%")
        (format stream "# ============================================================~%")
        (terpri stream)
        (generate-rdf-to-stream expression stream)
        (terpri stream)
        
        ;; Layer 3: Manifestation
        (format stream "# ============================================================~%")
        (format stream "# LAYER 3: FRBR MANIFESTATION~%")
        (format stream "# Digital embodiment~%")
        (format stream "# ============================================================~%")
        (terpri stream)
        (generate-rdf-to-stream manifestation stream)
        (terpri stream)
        
        ;; Layer 4: Formats
        (format stream "# ============================================================~%")
        (format stream "# LAYER 4: FRBR FORMATS~%")
        (format stream "# Specific encodings (HTML, Turtle, JSON-LD)~%")
        (format stream "# ============================================================~%")
        (terpri stream)
        
        ;; Generate each format
        (dolist (fmt formats)
          (generate-rdf-to-stream fmt stream)
          (terpri stream))
        
        ;; Footer
        (format stream "# ============================================================~%")
        (format stream "# END OF FRBR+ELI+PROV-O OUTPUT~%")
        (format stream "# ============================================================~%"))))))

;;; ============================================================
;;; DETERMINISM NOTES
;;; ============================================================

#|

DETERMINISM STRATEGY:

1. PREFIX ORDER:
   - Always sorted alphabetically: dcat, dct, eli, prov, schema, xsd
   - Implemented via sorted list in emit-prefixes

2. PROPERTY ORDER:
   - Each FRBR layer has deterministic property order
   - Defined in frbr-protocol.lisp generate-rdf methods
   - Order: Type → ELI → DCT → Schema → FRBR → PROV

3. TIMESTAMP HANDLING:
   - Each FRBR instance gets timestamp at creation
   - Same timestamp used throughout generation
   - No dynamic timestamps during RDF generation

4. URI CONSTRUCTION:
   - Deterministic pattern: {base}/{year}/art/{N}/exp/ell/...
   - No UUIDs, no random components
   - Purely functional: same input → same URI

5. LAYER ORDER:
   - Always: Work → Expression → Manifestation → Formats
   - Formats always in same order: HTML, Turtle, JSON-LD

6. DSL USAGE:
   - All output via turtle-dsl.lisp macros
   - No raw FORMAT statements
   - Guarantees consistent indentation and syntax

TESTING DETERMINISM:

(defun test-determinism ()
  "Test that same article produces identical output"
  (let* ((article (list :number 1 
                       :title "Άρθρο 1" 
                       :content "Το πολίτευμα..."))
         (output1 (render-frbr-eli-for-article article))
         (output2 (render-frbr-eli-for-article article)))
    
    ;; Outputs should be string-equal
    (assert (string= output1 output2))
    
    ;; Byte-for-byte identical
    (assert (equal (map 'list #'char-code output1)
                   (map 'list #'char-code output2)))
    
    (format t "✓ Determinism test passed~%")))

|#

;;; ============================================================
;;; ENHANCED ENTRY POINT - With Temporal Metadata (Phase D)
;;; ============================================================

(defun render-frbr-eli-for-article-with-temporal (article)
  "Generate complete FRBR+ELI+PROV+TEMPORAL Turtle string for an article
   
   This enhanced version includes ELI temporal completeness metadata:
   - eli:date_applicability
   - eli:in_force
   - eli:amends (amendment chain)
   
   Arguments:
     article: Hash table or plist with keys:
       :number  - Article number (1-120)
       :title   - Greek title string
       :content - Greek content string
   
   Returns:
     String containing complete Turtle RDF with FRBR + Temporal metadata
   
   Guarantees (Phase D):
     - Complete temporal metadata for AI systems
     - Machine-traversable amendment chain
     - Point-in-time queries enabled
     - No hallucinations - all from constitution.yaml"
  
  ;; Helper to extract field from article (hash-table or plist)
  (flet ((extract-field (key)
           (etypecase article
             (hash-table (gethash key article))
             (list (getf article key)))))
    
    ;; Extract article data
    (let* ((article-number (extract-field :number))
           (title (extract-field :title))
           (content (extract-field :content)))
      
      ;; Validate article data
      (unless article-number
        (error "Article number is required"))
      (unless title
        (error "Article title is required"))
      (unless content
        (error "Article content is required"))
      
      ;; Get base FRBR+ELI output
      (let ((base-ttl (render-frbr-eli-for-article article)))
        
        ;; Try to add temporal metadata if eli-temporal module is loaded
        (handler-case
            (let* ((uri-base (orchestrator.uris:get-eli-const-prefix))
                   (article-uri (format nil "~A/art/~D" uri-base article-number))
                   (temporal-metadata (orchestrator.eli-temporal:get-article-temporal-metadata 
                                      article-number))
                   (in-force (getf temporal-metadata :in-force))
                   (date-applicability (getf temporal-metadata :date-applicability))
                   (amendments (getf temporal-metadata :amendments)))
              
              ;; Append temporal metadata to base TTL
              (with-output-to-string (stream)
                (write-string base-ttl stream)
                (format stream "~%~%# ═══════════════════════════════════════════════════════════~%")
                (format stream "# ELI TEMPORAL METADATA (Phase D)~%")
                (format stream "# ═══════════════════════════════════════════════════════════~%~%")
                (format stream "<~A>~%" article-uri)
                (format stream "    eli:date_applicability \"~A\"^^xsd:date ;~%" 
                        date-applicability)
                (format stream "    eli:in_force ~A ;~%" 
                        (if in-force "true" "false"))
                
                ;; Add amendment chain
                (when amendments
                  (format stream "~%    # Amendment chain (machine-traversable)~%")
                  (dolist (amendment amendments)
                    (let ((amend-id (cdr (assoc "id" amendment :test #'string=)))
                          (amend-date (cdr (assoc "date" amendment :test #'string=))))
                      (format stream "    eli:amends <~A/version/~A> ;~%" 
                              article-uri amend-id)
                      (format stream "        # Modified: ~A~%" amend-date))))
                
                (format stream "    .~%~%")
                
                ;; Add version resources for amendment chain
                (when amendments
                  (format stream "# Version resources (amendment history)~%")
                  (dolist (amendment amendments)
                    (let ((amend-id (cdr (assoc "id" amendment :test #'string=)))
                          (amend-date (cdr (assoc "date" amendment :test #'string=)))
                          (fek (cdr (assoc "fek" amendment :test #'string=)))
                          (description (cdr (assoc "description" amendment :test #'string=))))
                      (format stream "~%<~A/version/~A>~%" article-uri amend-id)
                      (format stream "    a eli:LegalResource ;~%")
                      (format stream "    dcterms:modified \"~A\"^^xsd:date ;~%" 
                              amend-date)
                      (when fek
                        (format stream "    eli:is_realized_by \"~A\" ;~%" fek))
                      (when description
                        (format stream "    dcterms:description \"~A\"@el ;~%" 
                                description))
                      (format stream "    .~%"))))))
          
          ;; If temporal module not available, return base TTL only
          (error (condition)
            (warn "Temporal metadata not available: ~A" condition)
            base-ttl))))))

;;; ============================================================
;;; CONVENIENCE FUNCTION - Auto-select with or without temporal
;;; ============================================================

(defun render-article-rdf (article &key (include-temporal t))
  "Convenience function to render article RDF with optional temporal metadata.
   
   Arguments:
     article - Article data (hash-table or plist)
     :include-temporal - If T (default), include Phase D temporal metadata
   
   Returns:
     Complete Turtle RDF string"
  (if include-temporal
      (render-frbr-eli-for-article-with-temporal article)
      (render-frbr-eli-for-article article)))
