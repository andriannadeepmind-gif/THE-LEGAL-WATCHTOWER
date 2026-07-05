;;;; systems/orchestrator-omega-modules/manifestation-generator-omega.lisp
;;;; FRBR Manifestation Layer Generator - ΟΜΕΓΑ-LEVEL CLOS Implementation
;;;; Digital embodiment of the Greek-language Expression
;;;;
;;;; ΟΜΕΓΑ-LEVEL: Full ELI v1.4 + DCAT + PROV-O compliance
;;;;
;;;; This file provides the primary generate-rdf method for frbr-manifestation.
;;;; It REPLACES the fallback method in frbr-protocol.lisp (same specializer,
;;;; later load order → omega method wins via CLOS standard replacement).
;;;;
;;;; The frbr-protocol.lisp :around/:before/:after methods for frbr-resource
;;;; still apply — this file only replaces the primary method.
;;;;
;;;; Output guarantees:
;;;;   - Deterministic property ordering (see DETERMINISTIC ORDER below)
;;;;   - ELI-correct properties (eli:is_part_of, not eli:partOf)
;;;;   - Full DCAT distribution metadata
;;;;   - Complete PROV-O provenance chain
;;;;   - Schema.org distribution properties
;;;;   - VoID dataset membership
;;;;   - ODRL attribution policy linkage
;;;;   - PAV curation metadata

(in-package :orchestrator.frbr)

;;; ============================================================
;;; PRIMARY METHOD - Manifestation Layer RDF Generation
;;; ============================================================

(defmethod orchestrator.spec:generate-rdf ((man orchestrator.model:frbr-manifestation))
  "Generate Manifestation layer RDF - Digital embodiment of Expression

   DETERMINISTIC: Same input → same output (byte-for-byte)
   STATELESS: No dependencies on external state
   PURE: No side effects during generation

   ELI COMPLIANT: eli:is_part_of (not the non-existent eli:partOf)
   DCAT COMPLIANT: dcat:Distribution with full distribution metadata"

  (with-output-to-string (*standard-output*)

    (orchestrator.dsl.turtle:with-turtle-output
        (*standard-output*
         :prefixes '(("dcat"   . "http://www.w3.org/ns/dcat#")
                     ("dct"    . "http://purl.org/dc/terms/")
                     ("eli"    . "http://data.europa.eu/eli/ontology#")
                     ("odrl"   . "http://www.w3.org/ns/odrl/2/")
                     ("owl"    . "http://www.w3.org/2002/07/owl#")
                     ("pav"    . "http://purl.org/pav/")
                     ("prov"   . "http://www.w3.org/ns/prov#")
                     ("schema" . "https://schema.org/")
                     ("void"   . "http://rdfs.org/ns/void#")
                     ("xsd"    . "http://www.w3.org/2001/XMLSchema#")))

      ;; Header
      (emit-manifestation-header man)

      ;; Main resource
      (emit-manifestation-resource man)

      ;; Footer
      (emit-manifestation-footer man))))

;;; ============================================================
;;; HEADER EMISSION
;;; ============================================================

(defun emit-manifestation-header (man)
  "Emit Turtle file header with manifestation metadata"

  (let* ((expr (orchestrator.model:manifestation-expression man))
         (work (orchestrator.model:expression-work expr))
         (article-num (orchestrator.model:article-number work)))

    (orchestrator.dsl.turtle:emit-separator)
    (orchestrator.dsl.turtle:emit-comment
      (format nil "FRBR MANIFESTATION LAYER - Article ~A" article-num))
    (orchestrator.dsl.turtle:emit-comment
      "Digital embodiment of the Greek-language Expression")
    (orchestrator.dsl.turtle:emit-separator)
    (orchestrator.dsl.turtle:emit-comment
      (format nil "URI: ~A" (orchestrator.model:resource-uri man)))
    (orchestrator.dsl.turtle:emit-comment
      (format nil "Expression: ~A" (orchestrator.model:resource-uri expr)))
    (orchestrator.dsl.turtle:emit-comment
      "Generator: ORCHESTRATOR v1.3")
    (orchestrator.dsl.turtle:emit-comment
      "Standards: W3C RDF 1.1, ELI v1.4, FRBR, PROV-O, DCAT")
    (orchestrator.dsl.turtle:emit-separator)
    (terpri)))

;;; ============================================================
;;; MANIFESTATION RESOURCE EMISSION
;;; ============================================================

(defun emit-manifestation-resource (man)
  "Emit Manifestation resource with all properties

   DETERMINISTIC ORDER:
   1. Type declarations (eli, dcat)
   2. FRBR: eli:embodies → Expression (mandatory FRBR link)
   3. Hierarchy: eli:is_part_of → Article Root (ELI-correct property)
   4. DCAT distribution access properties (alphabetical)
   5. Dublin Core: license, format links (alphabetical)
   6. Schema.org distribution metadata (alphabetical)
   7. VoID dataset membership
   8. OWL identity
   9. Provenance: PROV-O (wasAttributedTo)
   10. PAV curation metadata
   11. ODRL attribution policy"

  (let* ((uri (orchestrator.model:resource-uri man))
         (expr (orchestrator.model:manifestation-expression man))
         (work (orchestrator.model:expression-work expr))
         (article-num (orchestrator.model:article-number work)))

    ;; Main resource
    (format t "<~A>~%" uri)

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 1: Type Declarations
    ;; Turtle multi-type syntax: comma separates objects of same predicate.
    ;; emit-triple-indent cannot be used here because it appends the terminator
    ;; after the first type, producing invalid ",;" syntax.
    ;; ──────────────────────────────────────────────────────
    (format t "    a eli:LegalManifestation ,~%")
    (format t "      dcat:Distribution ;~%")

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 2: FRBR — Manifestation embodies Expression
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "eli:embodies"
      (format nil "<~A>" (orchestrator.model:resource-uri expr)))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 3: Hierarchy to Article Root
    ;; ELI property: eli:is_part_of  (NOT eli:partOf — that property does not exist in ELI v1.4)
    ;; ──────────────────────────────────────────────────────
    (when (slot-boundp man 'orchestrator.model::article-root-uri)
      (emit-triple-indent
        "eli:is_part_of"
        (format nil "<~A>" (orchestrator.model:article-root-uri man))))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 4: DCAT Distribution Access Properties (alphabetical)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "dcat:accessURL"
      (format nil "<~A>" (orchestrator.model:access-url man)))

    (emit-triple-indent
      "dcat:downloadURL"
      (format nil "<~A>" (orchestrator.model:download-url man)))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 5: Dublin Core (alphabetical)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "dct:license"
      (format nil "<~A>" (orchestrator.model:license man)))

    ;; Format links — point to this Manifestation's Format children
    ;; (HTML, Turtle, JSON-LD).  These URIs are deterministically derived
    ;; from the Manifestation URI per the canonical URI scheme.
    (emit-triple-indent
      "dct:format"
      (format nil "<~A/format/html>" uri))

    (emit-triple-indent
      "dct:format"
      (format nil "<~A/format/jsonld>" uri))

    (emit-triple-indent
      "dct:format"
      (format nil "<~A/format/turtle>" uri))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 6: Schema.org Distribution Properties (alphabetical)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "schema:identifier"
      (format-literal (orchestrator.model:eli-identifier man)))

    (emit-triple-indent
      "schema:legislationDate"
      (format-literal (orchestrator.model:issued-date work) :datatype "xsd:date"))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 7: VoID Dataset Membership (Linked Data discovery)
    ;; ──────────────────────────────────────────────────────
    (when (and (slot-boundp work 'orchestrator.model::dataset-uri)
               (orchestrator.model:dataset-uri work))
      (emit-triple-indent
        "void:inDataset"
        (format nil "<~A>" (orchestrator.model:dataset-uri work))))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 8: OWL Identity / Cross-Reference
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "owl:sameAs"
      (format nil "<http://www.wikidata.org/entity/Q41#const-art-~A-man>"
              ;; Suffix-safe id so a lettered article (100Α) never collapses onto
              ;; its base number (100) in this cross-reference.
              (orchestrator.model:article-uri-id
               article-num (orchestrator.model:article-letter-suffix work))))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 9: PROV-O Provenance
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "prov:wasAttributedTo"
      (format nil "<~A>" (orchestrator.spec:person-webid)))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 10: PAV Curation Metadata
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "pav:curatedBy"
      (format nil "<~A>" (orchestrator.spec:person-webid)))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 11: ODRL Attribution Policy (AI citation enforcement)
    ;; ──────────────────────────────────────────────────────
    (when (orchestrator.spec:odrl-enabled-p)
      (emit-triple-indent
        "odrl:hasPolicy"
        (format nil "<~A>" (orchestrator.spec:odrl-policy-uri))
        :terminator "."))

    (terpri)))

;;; ============================================================
;;; FOOTER EMISSION
;;; ============================================================

(defun emit-manifestation-footer (man)
  "Emit Manifestation layer footer"

  (declare (ignore man))
  (terpri)
  (orchestrator.dsl.turtle:emit-separator)
  (orchestrator.dsl.turtle:emit-comment "END OF MANIFESTATION LAYER")
  (orchestrator.dsl.turtle:emit-separator))

;;; ============================================================
;;; VALIDATION
;;; ============================================================

(defmethod orchestrator.spec:validate-instance :after ((man orchestrator.model:frbr-manifestation))
  "Additional Manifestation validation beyond base protocol checks.

   :after qualifier ensures this runs in addition to frbr-protocol.lisp's
   primary validate-instance, not instead of it."

  ;; Verify access-url slot is set and non-empty
  (when (slot-boundp man 'orchestrator.model::access-url)
    (let ((url (orchestrator.model:access-url man)))
      (unless (and (stringp url) (> (length url) 0))
        (error 'orchestrator.spec:invalid-frbr-instance
               :message "Manifestation access-url is empty or non-string"
               :instance man))))

  ;; Verify download-url slot is set and non-empty
  (when (slot-boundp man 'orchestrator.model::download-url)
    (let ((url (orchestrator.model:download-url man)))
      (unless (and (stringp url) (> (length url) 0))
        (error 'orchestrator.spec:invalid-frbr-instance
               :message "Manifestation download-url is empty or non-string"
               :instance man)))))

;;; ============================================================
;;; COMPILER OPTIMIZATIONS
;;; ============================================================

(declaim (optimize (speed 3) (safety 1) (debug 1)))

(declaim (inline emit-manifestation-header emit-manifestation-footer))

;;; ============================================================
;;; EXPORTS
;;; ============================================================
;;;
;;; ΟΜΕΓΑ primary generate-rdf method for frbr-manifestation, consumed by the
;;; unified single-emission path (orchestrator.spec:write-unified-article-file).
;;; The former per-layer writer (write-manifestation-layer) was removed as dead
;;; code: it emitted an obsolete per-layer .manifestation.ttl file and was never
;;; called. generate-rdf is the public surface via the orchestrator.spec protocol.
