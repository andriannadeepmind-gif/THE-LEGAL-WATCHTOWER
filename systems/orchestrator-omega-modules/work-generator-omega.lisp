;;;; systems/orchestrator-frbr/work-generator.lisp
;;;; FRBR Work Layer Generator - ΟΜΕΓΑ-LEVEL CLOS Implementation
;;;; Uses: defmethod, DSL macros, deterministic generation

(in-package :orchestrator.frbr)

;;; ============================================================
;;; PRIMARY METHOD - Work Layer RDF Generation
;;; ============================================================

(defmethod orchestrator.spec:generate-rdf ((work orchestrator.model:frbr-work))
  "Generate Work layer RDF - Abstract legal concept (language-independent)
   
   DETERMINISTIC: Same input → same output (byte-for-byte)
   STATELESS: No dependencies on external state
   PURE: No side effects during generation"
  
  (with-output-to-string (*standard-output*)
    
    ;; Use DSL for clean Turtle generation
    (orchestrator.dsl.turtle:with-turtle-output
        (*standard-output*
         :prefixes '(("dcat" . "http://www.w3.org/ns/dcat#")
                     ("dct" . "http://purl.org/dc/terms/")
                     ("eli" . "http://data.europa.eu/eli/ontology#")
                     ("odrl" . "http://www.w3.org/ns/odrl/2/")
                     ("owl" . "http://www.w3.org/2002/07/owl#")
                     ("pav" . "http://purl.org/pav/")
                     ("prov" . "http://www.w3.org/ns/prov#")
                     ("schema" . "https://schema.org/")
                     ("stavropoulos" . "https://stavropouloslaw.com/ontology/")
                     ("void" . "http://rdfs.org/ns/void#")
                     ("xsd" . "http://www.w3.org/2001/XMLSchema#")))
      
      ;; Header
      (emit-work-header work)
      
      ;; Main resource
      (emit-work-resource work)
      
      ;; Footer
      (emit-work-footer work))))

;;; ============================================================
;;; HEADER EMISSION
;;; ============================================================

(defun emit-work-header (work)
  "Emit Turtle file header with metadata"
  
  (orchestrator.dsl.turtle:emit-separator)
  (orchestrator.dsl.turtle:emit-comment
    (format nil "FRBR WORK LAYER - Article ~A"
            (orchestrator.model:frbr-article-id work)))
  (orchestrator.dsl.turtle:emit-comment
    "Abstract legal resource (language-independent)")
  (orchestrator.dsl.turtle:emit-separator)
  (orchestrator.dsl.turtle:emit-comment
    (format nil "URI: ~A" (orchestrator.model:resource-uri work)))
  (orchestrator.dsl.turtle:emit-comment
    "Generator: ORCHESTRATOR v1.3")
  (orchestrator.dsl.turtle:emit-comment
    "Standards: W3C RDF 1.1, ELI v1.4, FRBR, PROV-O, Schema.org")
  (orchestrator.dsl.turtle:emit-separator)
  (terpri))

;;; ============================================================
;;; WORK RESOURCE EMISSION - Using DSL
;;; ============================================================

(defun emit-work-resource (work)
  "Emit main Work resource with all properties
   
   DETERMINISTIC ORDER:
   1. Type declarations (eli, schema)
   2. ELI properties (sorted alphabetically)
   3. Dublin Core properties (sorted)
   4. Schema.org properties (sorted)
   5. FRBR relationships
   6. Provenance metadata"
  
  (let ((uri (orchestrator.model:resource-uri work)))

    ;; Main resource
    (format t "<~A>~%" uri)
    
    ;; ──────────────────────────────────────────────────────
    ;; SECTION 1: Type Declarations
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent "a" "eli:LegalResource, schema:Legislation")
    
    ;; ──────────────────────────────────────────────────────
    ;; SECTION 2: ELI Properties (alphabetical order)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "eli:date_document"
      (format-literal (orchestrator.model:issued-date work) :datatype "xsd:date"))

    (emit-triple-indent
      "eli:id_local"
      (format-literal (orchestrator.model:eli-identifier work)))

    (emit-triple-indent
      "eli:is_part_of"
      (format nil "<~A>" (orchestrator.model:part-of work)))

    (emit-triple-indent
      "eli:is_realized_by"
      (format nil "<~A/exp/ell>" uri))

    ;; Inverse relation to Article Root (ELI: is_part_of, not partOf)
    (when (slot-boundp work 'orchestrator.model::article-root-uri)
      (emit-triple-indent
        "eli:is_part_of"
        (format nil "<~A>" (orchestrator.model:article-root-uri work))))
    
    (emit-triple-indent
      "eli:jurisdiction"
      "<http://publications.europa.eu/resource/authority/country/GRC>")
    
    (emit-triple-indent
      "eli:type_document"
      (format nil "<~A>" (orchestrator.model:law-type-eu-resource-uri
                           (orchestrator.model:document-type work))))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 3: Dublin Core Properties (alphabetical)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "dct:contributor"
      (format nil "<~A>" (orchestrator.spec:person-webid)))

    (emit-triple-indent
      "dct:issued"
      (format-literal (orchestrator.model:issued-date work) :datatype "xsd:date"))

    (emit-triple-indent
      "dct:publisher"
      (format nil "<~A>" (orchestrator.spec:org-webid)))

    (emit-triple-indent
      "dct:type"
      (format nil "<~A>" (orchestrator.model:law-type-eu-resource-uri
                           (orchestrator.model:document-type work))))
    
    ;; ──────────────────────────────────────────────────────
    ;; SECTION 4: Schema.org Properties (alphabetical)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "schema:identifier"
      (format-literal (orchestrator.model:eli-identifier work)))

    (emit-triple-indent
      "schema:inLanguage"
      (format-literal "el"))

    (emit-triple-indent
      "schema:legislationDate"
      (format-literal (orchestrator.model:issued-date work) :datatype "xsd:date"))

    ;; P1b [0052]#Ε1: η ΚΑΝΟΝΙΚΗ ταυτότητα (ART/5Α) — το γυμνό ~D της βάσης
    ;; εξέπεμπε ΤΟ ΙΔΙΟ legislationIdentifier για το 5 και το 5Α (σύγκρουση
    ;; ταυτότητας δύο διαφορετικών νομικών οντοτήτων).
    (emit-triple-indent
      "schema:legislationIdentifier"
      (format-literal (format nil "ELI/GR/~A/~A/ART/~A"
                              (string-upcase (orchestrator.model:document-type work))
                              (orchestrator.model:law-year work)
                              (orchestrator.model:frbr-article-id work))))

    (emit-triple-indent
      "schema:legislationJurisdiction"
      (format-literal (orchestrator.model:jurisdiction work)))

    (emit-triple-indent
      "schema:legislationLegalForce"
      (format-literal "InForce"))

    (emit-triple-indent
      "schema:legislationType"
      (format-literal (orchestrator.model:law-type-schema-legislation-type
                        (orchestrator.model:document-type work))))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 5: Linked Data & External References
    ;; ──────────────────────────────────────────────────────

    ;; VoID Dataset membership (Linked Data discovery)
    ;; Emit only when a non-NIL dataset URI is present; corpora without one
    ;; omit the triple rather than emitting an invalid blank <NIL> URI.
    (when (and (slot-boundp work 'orchestrator.model::dataset-uri)
               (orchestrator.model:dataset-uri work))
      (emit-triple-indent
        "void:inDataset"
        (format nil "<~A>" (orchestrator.model:dataset-uri work))))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 6: Provenance (PROV-O)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "prov:wasAttributedTo"
      (format nil "<~A>" (orchestrator.spec:person-webid)))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 7: Enhanced Metadata (LEVEL 300)
    ;; ──────────────────────────────────────────────────────

    ;; PAV curation metadata (critical for citation authority)
    (emit-triple-indent
      "pav:curatedBy"
      (format nil "<~A>" (orchestrator.spec:person-webid)))

    ;; W3C ODRL Attribution Policy (AI citation enforcement)
    (when (orchestrator.spec:odrl-enabled-p)
      (emit-triple-indent
        "odrl:hasPolicy"
        (format nil "<~A>" (orchestrator.spec:odrl-policy-uri))
        :terminator "."))

    ;; End of resource
    (terpri)))

;;; ============================================================
;;; FOOTER EMISSION
;;; ============================================================

(defun emit-work-footer (work)
  "Emit file footer"
  
  (terpri)
  (orchestrator.dsl.turtle:emit-separator)
  (orchestrator.dsl.turtle:emit-comment "END OF WORK LAYER")
  (orchestrator.dsl.turtle:emit-separator))

;;; ============================================================
;;; HELPER FUNCTIONS - Deterministic Triple Emission
;;; ============================================================

(defun emit-triple-indent (predicate object &key (terminator ";"))
  "Emit triple with proper indentation and terminator"
  (format t "    ~A ~A~A~%" predicate object terminator))

(defun format-literal (text &key lang datatype)
  "Format Turtle literal with language or datatype"
  (let ((escaped (orchestrator.dsl.turtle:escape-turtle-literal text)))
    (cond
      (lang (format nil "\"\"\"~A\"\"\"@~A" escaped lang))
      (datatype (format nil "\"~A\"^^~A" escaped datatype))
      (t (format nil "\"~A\"" escaped)))))

;;; ============================================================
;;; COMPILER OPTIMIZATIONS
;;; ============================================================

(declaim (optimize (speed 3) (safety 1) (debug 1)))

(declaim (ftype (function (orchestrator.model:frbr-work) string)
                emit-work-resource))

(declaim (inline emit-triple-indent format-literal))

;;; ============================================================
;;; EXPORTS
;;; ============================================================
;;;
;;; This file provides the ΟΜΕΓΑ primary generate-rdf method for frbr-work
;;; (used by the unified single-emission path: write-unified-article-file).
;;; The former per-layer file writers (write-work-layer, generate-all-work-layers)
;;; were removed: they duplicated the unified path and emitted obsolete
;;; per-layer .work.ttl files. No exports — generate-rdf is the public surface
;;; via the orchestrator.spec protocol.
