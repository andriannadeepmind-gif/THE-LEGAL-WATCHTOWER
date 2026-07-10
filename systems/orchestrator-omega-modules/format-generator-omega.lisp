;;;; systems/orchestrator-omega-modules/format-generator-omega.lisp
;;;; FRBR Format Layer Generator - ΟΜΕΓΑ-LEVEL CLOS Implementation
;;;; Specific encoding specification (HTML, Turtle, JSON-LD)
;;;;
;;;; ΟΜΕΓΑ-LEVEL: Full ELI v1.4 + DCAT + PROV-O compliance
;;;;
;;;; This file provides the primary generate-rdf method for frbr-format.
;;;; It REPLACES the fallback method in frbr-protocol.lisp (same specializer,
;;;; later load order → omega method wins via CLOS standard replacement).
;;;;
;;;; The frbr-protocol.lisp :around/:before/:after methods for frbr-resource
;;;; still apply — this file only replaces the primary method.
;;;;
;;;; Output guarantees:
;;;;   - Deterministic property ordering (see DETERMINISTIC ORDER below)
;;;;   - ELI-correct properties (eli:is_part_of, not eli:partOf)
;;;;   - Full DCAT distribution metadata with IANA media type
;;;;   - Schema.org encoding properties
;;;;   - PROV-O provenance chain
;;;;   - PAV curation metadata
;;;;   - ODRL attribution policy linkage

(in-package :orchestrator.frbr)

;;; ============================================================
;;; PRIMARY METHOD - Format Layer RDF Generation
;;; ============================================================

(defmethod orchestrator.spec:generate-rdf ((fmt orchestrator.model:frbr-format))
  "Generate Format layer RDF - Specific encoding of a Manifestation

   DETERMINISTIC: Same input → same output (byte-for-byte)
   STATELESS: No dependencies on external state
   PURE: No side effects during generation

   ELI COMPLIANT: eli:is_part_of (not the non-existent eli:partOf)
   DCAT COMPLIANT: dcat:Distribution with full encoding metadata"

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
      (emit-format-header fmt)

      ;; Main resource
      (emit-format-resource fmt)

      ;; Footer
      (emit-format-footer fmt))))

;;; ============================================================
;;; HEADER EMISSION
;;; ============================================================

(defun emit-format-header (fmt)
  "Emit Turtle file header with format metadata"

  (let* ((man (orchestrator.model:format-manifestation fmt))
         (expr (orchestrator.model:manifestation-expression man))
         (work (orchestrator.model:expression-work expr))
         (article-id (orchestrator.model:frbr-article-id work))
         (type-name (string-downcase (symbol-name (orchestrator.model:format-type fmt)))))

    (orchestrator.dsl.turtle:emit-separator)
    (orchestrator.dsl.turtle:emit-comment
      (format nil "FRBR FORMAT LAYER (~A) - Article ~A"
              (string-upcase type-name)
              article-id))
    (orchestrator.dsl.turtle:emit-comment
      (format nil "~A encoding of the Manifestation" (string-upcase type-name)))
    (orchestrator.dsl.turtle:emit-separator)
    (orchestrator.dsl.turtle:emit-comment
      (format nil "URI: ~A" (orchestrator.model:resource-uri fmt)))
    (orchestrator.dsl.turtle:emit-comment
      (format nil "Media-type: ~A" (orchestrator.model:media-type fmt)))
    (orchestrator.dsl.turtle:emit-comment
      "Generator: ORCHESTRATOR v1.3")
    (orchestrator.dsl.turtle:emit-comment
      "Standards: W3C RDF 1.1, ELI v1.4, FRBR, DCAT, PROV-O")
    (orchestrator.dsl.turtle:emit-separator)
    (terpri)))

;;; ============================================================
;;; FORMAT RESOURCE EMISSION
;;; ============================================================

(defun emit-format-resource (fmt)
  "Emit Format resource with all properties

   DETERMINISTIC ORDER:
   1. Type declaration (dcat:Distribution)
   2. FRBR: dcat:accessService → Manifestation (service link)
   3. Hierarchy: eli:is_part_of → Article Root (ELI-correct property)
   4. DCAT encoding properties: mediaType (alphabetical)
   5. Dublin Core: format URI (EU authority file)
   6. Schema.org encoding metadata (alphabetical)
   7. VoID dataset membership
   8. OWL identity / cross-reference
   9. Provenance: PROV-O (wasAttributedTo)
   10. PAV curation metadata
   11. ODRL attribution policy"

  (let* ((uri (orchestrator.model:resource-uri fmt))
         (man (orchestrator.model:format-manifestation fmt))
         (expr (orchestrator.model:manifestation-expression man))
         (work (orchestrator.model:expression-work expr))
         (article-num (orchestrator.model:article-number work))
         (type-name (string-downcase (symbol-name (orchestrator.model:format-type fmt)))))

    ;; Main resource
    (format t "<~A>~%" uri)

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 1: Type Declaration
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent "a" "dcat:Distribution")

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 2: FRBR — Format served by Manifestation
    ;; dcat:accessService is the correct DCAT property for linking
    ;; a distribution to the data service that provides it.
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "dcat:accessService"
      (format nil "<~A>" (orchestrator.model:resource-uri man)))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 3: Hierarchy to Article Root
    ;; ELI property: eli:is_part_of  (NOT eli:partOf — that property does not exist in ELI v1.4)
    ;; ──────────────────────────────────────────────────────
    (when (slot-boundp fmt 'orchestrator.model::article-root-uri)
      (emit-triple-indent
        "eli:is_part_of"
        (format nil "<~A>" (orchestrator.model:article-root-uri fmt))))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 4: DCAT Encoding Properties (alphabetical)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "dcat:mediaType"
      (format-literal (orchestrator.model:media-type fmt)))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 5: Dublin Core Format URI (EU authority file)
    ;; dct:format references the authoritative EU format vocabulary URI
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "dct:format"
      (orchestrator.model:dct-format fmt))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 6: Schema.org Encoding Properties (alphabetical)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "schema:encodingFormat"
      (format-literal (orchestrator.model:file-extension fmt)))

    (emit-triple-indent
      "schema:fileFormat"
      (format-literal (orchestrator.model:media-type fmt)))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 7: VoID Dataset Membership (Linked Data discovery)
    ;; ──────────────────────────────────────────────────────
    (emit-triple-indent
      "void:inDataset"
      (format nil "<~A>"
              (or (orchestrator.spec:config-get "corpus.dataset_uri")
                  (error "corpus.dataset_uri not configured"))))

    ;; ──────────────────────────────────────────────────────
    ;; SECTION 8: OWL Identity / Cross-Reference
    ;; P1b [0052]#Ε6: ΜΟΝΟ με ΡΗΤΑ διαμορφωμένο wikidata_qid — το σιωπηλό
    ;; fallback «41» (= η οντότητα «Ελλάδα») έγραφε ΨΕΥΔΗ διασταύρωση στα
    ;; corpora χωρίς qid. Χωρίς qid, το triple ΠΑΡΑΛΕΙΠΕΤΑΙ.
    ;; ──────────────────────────────────────────────────────
    (let ((qid (orchestrator.spec:config-get "corpus.wikidata_qid"))
          (corpus-slug (orchestrator.spec:required-config "corpus.short_name")))
      (when qid
        (emit-triple-indent
          "owl:sameAs"
          (format nil "<http://www.wikidata.org/entity/Q~A#~A-art-~A-man-~A>"
                  qid
                  corpus-slug
                  ;; Suffix-safe id so a lettered article (100Α) never collapses
                  ;; onto its base number (100) in this cross-reference.
                  (orchestrator.model:frbr-article-id work)
                  type-name))))

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

(defun emit-format-footer (fmt)
  "Emit Format layer footer"

  (let ((type-name (string-upcase (symbol-name (orchestrator.model:format-type fmt)))))
    (terpri)
    (orchestrator.dsl.turtle:emit-separator)
    (orchestrator.dsl.turtle:emit-comment
      (format nil "END OF FORMAT LAYER (~A)" type-name))
    (orchestrator.dsl.turtle:emit-separator)))

;;; ============================================================
;;; VALIDATION
;;; ============================================================

(defmethod orchestrator.spec:validate-instance :after ((fmt orchestrator.model:frbr-format))
  "Additional Format validation beyond base protocol checks.

   :after qualifier ensures this runs in addition to frbr-protocol.lisp's
   primary validate-instance, not instead of it."

  ;; Verify media-type slot is set and non-empty
  (when (slot-boundp fmt 'orchestrator.model::media-type)
    (let ((mt (orchestrator.model:media-type fmt)))
      (unless (and (stringp mt) (> (length mt) 0))
        (error 'orchestrator.spec:invalid-frbr-instance
               :message "Format media-type is empty or non-string"
               :instance fmt))))

  ;; Verify dct-format slot is set
  (unless (slot-boundp fmt 'orchestrator.model::dct-format)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Format missing dct-format (EU authority file URI)"
           :instance fmt))

  ;; Verify file-extension slot is set
  (unless (slot-boundp fmt 'orchestrator.model::file-extension)
    (error 'orchestrator.spec:invalid-frbr-instance
           :message "Format missing file-extension"
           :instance fmt)))

;;; ============================================================
;;; COMPILER OPTIMIZATIONS
;;; ============================================================

(declaim (optimize (speed 3) (safety 1) (debug 1)))

(declaim (inline emit-format-header emit-format-footer))

;;; ============================================================
;;; EXPORTS
;;; ============================================================
;;;
;;; ΟΜΕΓΑ primary generate-rdf method for frbr-format, consumed by the unified
;;; single-emission path (orchestrator.spec:write-unified-article-file).
;;; The former per-layer writer (write-format-layer) was removed as dead code:
;;; it emitted obsolete per-layer .format-*.ttl files and was never called.
;;; generate-rdf is the public surface via the orchestrator.spec protocol.
