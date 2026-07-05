;;;; systems/orchestrator-frbr/expression-generator.lisp
;;;; FRBR Expression Layer Generator - ΟΜΕΓΑ-LEVEL CLOS Implementation
;;;; Language-specific realization of Work

(in-package :orchestrator.frbr)

;;; ============================================================
;;; PRIMARY METHOD - Expression Layer RDF Generation
;;; ============================================================

(defmethod orchestrator.spec:generate-rdf ((expr orchestrator.model:frbr-expression))
  "Generate Expression layer RDF - Greek language realization
   
   DETERMINISTIC: Consistent output order
   LANGUAGE-AWARE: Proper Greek text handling (UTF-8)
   FRBR-COMPLIANT: Links to Work, points to Manifestation"
  
  (with-output-to-string (*standard-output*)
    
    (orchestrator.dsl.turtle:with-turtle-output
        (*standard-output*
         :prefixes '(("dcat" . "http://www.w3.org/ns/dcat#")
                     ("dct" . "http://purl.org/dc/terms/")
                     ("digest" . "http://www.w3.org/2000/10/swap/crypto#")
                     ("eli" . "http://data.europa.eu/eli/ontology#")
                     ("glass" . "http://www.w3.org/2000/10/swap/crypto#")
                     ("pav" . "http://purl.org/pav/")
                     ("prov" . "http://www.w3.org/ns/prov#")
                     ("schema" . "https://schema.org/")
                     ("xsd" . "http://www.w3.org/2001/XMLSchema#")))
      
      ;; Header
      (emit-expression-header expr)
      
      ;; Main resource
      (emit-expression-resource expr)
      
      ;; Footer
      (emit-expression-footer expr))))

;;; ============================================================
;;; HEADER EMISSION
;;; ============================================================

(defun emit-expression-header (expr)
  "Emit Expression layer header"
  
  (let* ((work (orchestrator.model:expression-work expr))
         (article-num (orchestrator.model:article-number work)))
    
    (orchestrator.dsl.turtle:emit-separator)
    (orchestrator.dsl.turtle:emit-comment 
      (format nil "FRBR EXPRESSION LAYER - Article ~A" article-num))
    (orchestrator.dsl.turtle:emit-comment 
      "Greek language realization of abstract Work")
    (orchestrator.dsl.turtle:emit-separator)
    (orchestrator.dsl.turtle:emit-comment 
      (format nil "URI: ~A" (orchestrator.model:resource-uri expr)))
    (orchestrator.dsl.turtle:emit-comment
      (format nil "Language: ~A (ELL)"
              (orchestrator.model:expression-language expr)))
    (orchestrator.dsl.turtle:emit-comment
      "Generator: ORCHESTRATOR v1.3")
    (orchestrator.dsl.turtle:emit-comment
      "Standards: W3C RDF 1.1, ELI v1.4, FRBR, PROV-O")
    (orchestrator.dsl.turtle:emit-separator)
    (terpri)))

;;; ============================================================
;;; EXPRESSION RESOURCE EMISSION
;;; ============================================================

(defun emit-expression-resource (expr)
  "Emit Expression resource with Greek text content
   
   DETERMINISTIC ORDER:
   1. Type declaration
   2. FRBR: realizes Work
   3. Language properties
   4. Title (Greek with @el)
   5. Content (Greek with @el)
   6. FRBR: embodied_by Manifestation
   7. Provenance"
  
  (let* ((uri (orchestrator.model:resource-uri expr))
         (work (orchestrator.model:expression-work expr))
         (work-uri (orchestrator.model:resource-uri work))
         (lang (orchestrator.model:expression-language expr))
         (title (orchestrator.model:expression-title expr))
         (content (orchestrator.model:expression-content expr)))
    
    ;; Main resource
    (format t "<~A>~%" uri)
    
    ;; ──────────────────────────────────────────────────────
    ;; Type
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent "a" "eli:LegalExpression")
    
    ;; ──────────────────────────────────────────────────────
    ;; FRBR: Expression → Work
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "eli:realizes"
      (format nil "<~A>" work-uri))

    ;; Inverse relation to Article Root (ELI: is_part_of, not partOf)
    (when (slot-boundp expr 'orchestrator.model::article-root-uri)
      (emit-triple-indent
        "eli:is_part_of"
        (format nil "<~A>" (orchestrator.model:article-root-uri expr))))

    ;; ──────────────────────────────────────────────────────
    ;; Language Properties
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "eli:language"
      "<http://publications.europa.eu/resource/authority/language/ELL>")
    
    (emit-triple-indent
      "dct:language"
      (format-literal lang))
    
    (emit-triple-indent
      "schema:inLanguage"
      (format-literal lang))
    
    ;; ──────────────────────────────────────────────────────
    ;; Title (Greek text with language tag)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "eli:title"
      (format-literal title :lang lang))
    
    (emit-triple-indent
      "dct:title"
      (format-literal title :lang lang))
    
    (emit-triple-indent
      "schema:name"
      (format-literal title :lang lang))
    
    ;; ──────────────────────────────────────────────────────
    ;; Content (Greek text with language tag)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "eli:description"
      (format-literal content :lang lang))

    (emit-triple-indent
      "schema:text"
      (format-literal content :lang lang))

    ;; ──────────────────────────────────────────────────────
    ;; Cryptographic Integrity (SHA-256) - W3C Subresource Integrity format
    ;; ──────────────────────────────────────────────────────
    (let ((content-hash (orchestrator.spec:calculate-sha256-hash content)))
      (emit-triple-indent
        "glass:digest"
        (format-literal (format nil "sha256-~A" content-hash)))
      ;; Legacy format for backwards compatibility
      (emit-triple-indent
        "digest:sha256"
        (format-literal content-hash)))

    ;; ──────────────────────────────────────────────────────
    ;; Atomic Subdivisions (Paragraphs) - if present
    ;; ──────────────────────────────────────────────────────
    (when (slot-boundp expr 'orchestrator.model::paragraphs)
      (let ((paragraphs (orchestrator.model:paragraphs expr))
            (article-num (orchestrator.model:article-number work)))
        (when paragraphs
          (loop for para in paragraphs
                for para-num = (getf para :number)
                do (emit-triple-indent
                     "eli:has_part"
                     (format nil "<~A/par/~D>"
                             (orchestrator.model:article-root-uri expr)
                             para-num))))))

    ;; ──────────────────────────────────────────────────────
    ;; FRBR: Expression → Manifestation
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "eli:is_embodied_by"
      (format nil "<~A/man>" uri))
    
    ;; ──────────────────────────────────────────────────────
    ;; Provenance
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "prov:wasAttributedTo"
      (format nil "<~A>" (orchestrator.spec:person-webid)))

    (emit-triple-indent
      "prov:wasDerivedFrom"
      (format nil "<~A>" work-uri)
      :terminator ".")

    (terpri)))

;;; ============================================================
;;; FOOTER EMISSION
;;; ============================================================

(defun emit-expression-footer (expr)
  "Emit Expression layer footer"
  (terpri)
  (orchestrator.dsl.turtle:emit-separator)
  (orchestrator.dsl.turtle:emit-comment "END OF EXPRESSION LAYER")
  (orchestrator.dsl.turtle:emit-separator))

;;; ============================================================
;;; COMPILER OPTIMIZATIONS
;;; ============================================================

(declaim (optimize (speed 3) (safety 1) (debug 1)))

(declaim (ftype (function (orchestrator.model:frbr-expression) string)
                emit-expression-resource))

;;; ============================================================
;;; EXPORTS
;;; ============================================================
;;;
;;; This file provides the ΟΜΕΓΑ primary generate-rdf method for frbr-expression
;;; (used by the unified single-emission path: write-unified-article-file).
;;; The former per-layer file writers (write-expression-layer,
;;; generate-all-expression-layers) were removed: they duplicated the unified
;;; path and emitted obsolete per-layer .expression.ttl files. No exports —
;;; generate-rdf is the public surface via the orchestrator.spec protocol.
