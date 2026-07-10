;;;; systems/orchestrator-omega-modules/article-root-generator-omega.lisp
;;;; Article Root Node RDF Generator - Canonical Entry Point
;;;; ΟΜΕΓΑ-LEVEL:  AI-ROOT-AUTHORITY CANONICAL ARTIFACT
;;;;
;;;; Generates RDF for the Article Root Node (canonical container).
;;;;
;;;; The Article Root serves as: 
;;;;   - Primary entry point for AI/LLM ingest
;;;;   - DCAT Dataset container
;;;;   - Forward relation hub (eli:hasWork, eli:hasExpression, eli:hasManifestation)
;;;;   - PROV-O entity with complete provenance
;;;;
;;;; Output guarantees:
;;;;   - Deterministic property ordering
;;;;   - All forward relations to FRBR layers
;;;;   - Complete PROV-O chain
;;;;   - ELI v1. 4 + DCAT compliant

(in-package :orchestrator.spec)

;;; ============================================================
;;; ARTICLE ROOT RDF GENERATION
;;; ============================================================

(defmethod generate-rdf ((article orchestrator.model:frbr-article-root))
  "Generate RDF for Article Root Node - DETERMINISTIC

   The Article Root is the canonical entry point for each article.
   It contains forward relations to all FRBR layers. 

   Property Order (DETERMINISTIC):
     1. Type declarations
     2. ELI properties (alphabetical)
     3. Dublin Core properties (alphabetical)
     4. DCAT properties
     5. Schema. org properties
     6. Forward FRBR relations (hasWork, hasExpression, hasManifestation)
     7.  PROV-O provenance"

  (with-output-to-string (*standard-output*)
    (let ((uri (orchestrator.model:resource-uri article))
          (article-num (orchestrator.model:article-number article))
          (title (orchestrator.model:article-title article))
          (work-uri (orchestrator.model:work-uri article))
          (parent-uri (orchestrator.model:parent-document article))
          (issued (orchestrator.model:issued-date article))
          (version (orchestrator.model:dataset-version article))
          (eli-id (orchestrator.model:eli-identifier article)))

      ;; Resource opening
      (format t "<~A>~%" uri)

      ;; 1. TYPE DECLARATIONS
      (format t "    a eli:LegalResource ,~%")
      (format t "      dcat:Dataset ,~%")
      (format t "      schema:Legislation ;~%")
      (format t "~%")

      ;; 2. ELI PROPERTIES (alphabetical)
      (let ((doc-type (orchestrator.model:document-type article)))
        (format t "    # ELI Core Properties~%")
        (format t "    eli:date_document ~S^^xsd:date ;~%" issued)
        (format t "    eli:is_part_of <~A> ;~%" parent-uri)
        (format t "    eli:jurisdiction <http://publications.europa.eu/resource/authority/country/GRC> ;~%")
        ;; eli:number is the base article number (xsd:integer per the SHACL shape).
        ;; The letter suffix of a lettered article (348Β) is carried by the URI,
        ;; the eli-identifier and the title — which already disambiguate it.
        (format t "    eli:number ~D ;~%" article-num)
        (format t "    eli:type_document <~A> ;~%"
                (orchestrator.model:law-type-eu-resource-uri doc-type)))
      (format t "~%")

      ;; 3. DUBLIN CORE PROPERTIES (alphabetical)
      (format t "    # Dublin Core Metadata~%")
      (format t "    dct:identifier ~S ;~%" eli-id)
      (format t "    dct:issued ~S^^xsd:date ;~%" issued)
      (format t "    dct:language \"el\" ;~%")
      (format t "    dct:title \"\"\"~A\"\"\"@el ;~%" title)
      (format t "    dct:type \"Article\" ;~%")
      (format t "~%")

      ;; 4. DCAT PROPERTIES
      (let ((greek-name (orchestrator.model:law-type-greek-name
                          (orchestrator.model:document-type article))))
        (format t "    # DCAT Dataset Properties~%")
        (format t "    dcat:keyword ~S@el ;~%" greek-name)
        (format t "    dcat:version \"~A\" ;~%" version))
      (format t "~%")

      ;; 5. SCHEMA.ORG PROPERTIES
      (format t "    # Schema.org Properties~%")
      (format t "    schema:inLanguage \"el\" ;~%")
      (format t "    schema:isPartOf <~A> ;~%" parent-uri)
      (format t "    schema:legislationIdentifier ~S ;~%" eli-id)
      (format t "~%")

      ;; 6. FORWARD FRBR RELATIONS (Article → layers)
      ;; Using stavropouloslaw: namespace — eli: has no hasWork/hasExpression/hasManifestation properties
      (format t "    # Forward Relations to FRBR Layers~%")
      (format t "    stavropouloslaw:hasWork <~A> ;~%" work-uri)

      ;; Expression URIs (primary Greek + any future languages)
      (let ((expr-uris (orchestrator.model:expression-uris article)))
        (if expr-uris
            (progn
              (format t "    stavropouloslaw:hasExpression ~{<~A>~^,~%                         ~} ;~%" expr-uris))
            ;; Default: construct primary Greek expression URI
            (format t "    stavropouloslaw:hasExpression <~A/work/exp/ell> ;~%" uri)))

      ;; Manifestation URIs
      (let ((man-uris (orchestrator.model:manifestation-uris article)))
        (if man-uris
            (progn
              (format t "    stavropouloslaw:hasManifestation ~{<~A>~^,~%                            ~} ;~%" man-uris))
            ;; Default: construct primary manifestation URI
            (format t "    stavropouloslaw:hasManifestation <~A/work/exp/ell/man> ;~%" uri)))
      (format t "~%")

      ;; 7. PROV-O PROVENANCE
      (format t "    # Provenance Metadata~%")
      (format t "    prov:wasAttributedTo <https://stavropouloslaw.com/identity#spyridon-stavropoulos>~%")

      ;; Resource closing
      (format t " .~%")
      (format t "~%"))))

;;; ============================================================
;;; VALIDATION
;;; ============================================================

(defmethod validate-instance ((article orchestrator.model:frbr-article-root))
  "Validate Article Root instance (primary method)"

  ;; Required fields
  (unless (slot-boundp article 'orchestrator.model::article-number)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Article Root missing article-number"
           :instance article))

  (unless (slot-boundp article 'orchestrator.model::article-title)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Article Root missing article-title"
           :instance article))

  (unless (slot-boundp article 'orchestrator.model::work-uri)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Article Root missing work-uri"
           :instance article))

  (unless (slot-boundp article 'orchestrator.model::uri)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Article Root missing URI"
           :instance article))

  ;; URI consistency
  (let ((uri (orchestrator.model:resource-uri article))
        (num (orchestrator.model:article-number article)))
    (unless (search (format nil "/art/~D" num) uri)
      (error 'orchestrator.spec:invalid-frbr-instance
             :message (format nil "Article URI ~A inconsistent with number ~D" uri num)
             :instance article)))

  t)

;;; ============================================================
;;; UTILITY - WRITE ARTICLE ROOT TO FILE
;;; ============================================================

(defun write-article-root-layer (article output-dir &key authority)
  "Write Article Root RDF to file

   Generates: article-NNN.root.ttl

   Arguments:
     article:    frbr-article-root instance
     output-dir: Output directory path
     authority:  REQUIRED - :canonical or :provenance

   Returns:
     File path if successful, NIL if failed"

  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :canonical or :authority :provenance"))

  (handler-case
      (let* (;; Suffix-safe filename via the single source of truth (100Α ≠ 100).
             (filename (format nil "article-~A.root.ttl" (orchestrator.model:article-file-id article)))
             (filepath (merge-pathnames filename output-dir))
             (rdf-content (generate-rdf article)))

        ;; Validate RDF content
        (unless (search "eli:LegalResource" rdf-content)
          (error "Generated RDF missing eli:LegalResource type"))

        (unless (search "stavropouloslaw:hasWork" rdf-content)
          (error "Generated RDF missing stavropouloslaw:hasWork relation"))

        ;; Write file via unified authority
        (orchestrator.write-authority:emit-graph rdf-content filepath :authority authority)

        (format *error-output* "~&INFO: Article Root written: ~A~%" filepath)
        filepath)

    (error (e)
      (format *error-output* "~&ERROR:  Failed to write Article Root for article ~A: ~A~%"
              (orchestrator.model:frbr-article-id article)
              e)
      nil)))

;;; ============================================================
;;; EXPORTS
;;; ============================================================

;; write-article-root-layer is now internal-only (GATE-4A: Single Emission Law)
;; Public write path: orchestrator.spec:write-unified-article-file