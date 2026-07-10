;;;; systems/orchestrator-omega-modules/unified-frbr-generator.lisp
;;;; Unified FRBR Stack Generator - ONE FILE PER ARTICLE
;;;; ΟΜΕΓΑ-LEVEL: AI-ROOT-AUTHORITY CANONICAL ARTIFACT
;;;;
;;;; Generates complete, unified Turtle file containing:
;;;;   - Canonical prefixes
;;;;   - Article Root node
;;;;   - FRBR Work
;;;;   - FRBR Expression
;;;;   - FRBR Manifestation
;;;;   - FRBR Formats (HTML, Turtle, JSON-LD)
;;;;   - PROV-O Activity
;;;;   - Complete provenance chain
;;;;
;;;; Output guarantees:
;;;;   - ONE file per article: article-NNN.ttl
;;;;   - Deterministic ordering
;;;;   - Complete cross-layer consistency
;;;;   - AI-ingest optimized
;;;;   - Byte-for-byte reproducible

(in-package :orchestrator.spec)

;;; ============================================================
;;; UNIFIED FRBR STACK CREATION
;;; ============================================================

(defun make-complete-frbr-stack (article-number title content
                                 &key
                                 (article-suffix "")
                                 (corpus-name (config-get "corpus.short_name"))
                                 (activity-start-time (orchestrator.model:get-iso8601-timestamp))
                                 (activity-end-time activity-start-time)
                                 eli-prefix
                                 document-type
                                 law-year
                                 issued-date
                                 dataset-uri)
  "Create complete FRBR stack with Article Root, Activity, and all layers.

   Law-type parameters are required for any corpus other than Constitution.
   For Constitution, defaults are derived from configured ELI prefix.

   Arguments:
     article-number:       Integer
     title:                Title string in primary language
     content:              Full text content
     corpus-name:          Corpus identifier (default: 'syntagma')
     activity-start-time:  ISO-8601 timestamp string
     activity-end-time:    ISO-8601 timestamp string
     eli-prefix:           ELI law prefix (e.g. https://.../eli/gr/const/1975)
     document-type:        ELI type code string (\"const\", \"l\", \"pd\", etc.)
     law-year:             Year string (derived from eli-prefix or issued-date if absent)
     issued-date:          xsd:date string (e.g. \"1975-06-11\")
     dataset-uri:          VoID dataset URI for void:inDataset

   Returns:
     (values article-root work expression manifestation formats activity)

   All instances are fully linked with proper URI chains."

  (let* (;; Resolve ELI context — Constitution uses configured prefix; others must pass explicitly
         (resolved-eli-prefix (or eli-prefix (orchestrator.uris:get-eli-const-prefix)))
         (resolved-doc-type   (or document-type (config-get "corpus.document_type") "const"))
         ;; Dataset URI is corpus-level metadata sourced from config (single source
         ;; of truth). May be NIL for corpora that do not declare one — generators
         ;; then omit void:inDataset rather than emitting an invalid blank URI.
         (resolved-dataset-uri (or dataset-uri (config-get "corpus.dataset_uri")))
         ;; Legal dates are NEVER guessed. Use the explicitly passed date,
         ;; else the active corpus config (corpus.publication.date), else fail hard.
         ;; A fabricated legal date is worse than a build failure.
         (resolved-issued     (or issued-date
                                  (config-get "corpus.publication.date")
                                  (error "make-complete-frbr-stack: issued-date not provided and corpus.publication.date absent from config — refusing to fabricate a legal date for article ~D"
                                         article-number)))
         (resolved-year       (or law-year (subseq resolved-issued 0 4)))

         ;; Parse content into paragraphs for atomic granularity
         (paragraphs (orchestrator.spec:parse-article-into-paragraphs content))

         ;; Create Article Root (top-level container)
         (article-root (orchestrator.model:make-frbr-article-root
                         :article-number article-number
                         :article-suffix article-suffix
                         :article-title title
                         :eli-prefix resolved-eli-prefix
                         :document-type resolved-doc-type
                         :law-year resolved-year
                         :issued-date resolved-issued))

         (article-root-uri (orchestrator.model:resource-uri article-root))

         ;; Create Work (abstract concept)
         (work (orchestrator.model:make-frbr-work
                 :article-number article-number
                 :article-suffix article-suffix
                 :article-root-uri article-root-uri
                 :eli-prefix resolved-eli-prefix
                 :document-type resolved-doc-type
                 :law-year resolved-year
                 :issued-date resolved-issued
                 :dataset-uri resolved-dataset-uri))

         ;; Create Expression (Greek language realization) with paragraphs
         (expression (orchestrator.model:make-frbr-expression
                       work
                       :title title
                       :content content
                       :paragraphs paragraphs))

         ;; Create Manifestation (digital embodiment)
         (manifestation (orchestrator.model:make-frbr-manifestation expression))

         ;; Create Formats (HTML, Turtle, JSON-LD)
         (format-html (orchestrator.model:make-frbr-format manifestation :html))
         (format-turtle (orchestrator.model:make-frbr-format manifestation :turtle))
         (format-jsonld (orchestrator.model:make-frbr-format manifestation :jsonld))
         (formats (list format-html format-turtle format-jsonld))

         ;; Create PROV-O Activity — η ταυτότητά του από τα ΚΑΝΟΝΙΚΟΠΟΙΗΜΕΝΑ
         ;; slots του root (αληθινή βάση + γυμνό επίθημα), ποτέ από το ωμό
         ;; article-number του καλούντος (P1b [0050]#2).
         (activity (orchestrator.model:make-prov-activity
                     :article-number (orchestrator.model:article-number article-root)
                     :article-suffix (orchestrator.model:article-letter-suffix article-root)
                     :corpus-name corpus-name
                     :start-time activity-start-time
                     :end-time activity-end-time
                     :source-text-uri (format nil "~A/source" article-root-uri))))

    ;; Populate Article Root with layer URIs
    (setf (orchestrator.model:expression-uris article-root)
          (list (orchestrator.model:resource-uri expression)))

    (setf (orchestrator.model:manifestation-uris article-root)
          (list (orchestrator.model:resource-uri manifestation)))

    (setf (orchestrator.model:format-uris article-root)
          (mapcar #'orchestrator.model:resource-uri formats))

    ;; Register all entities with Activity
    (orchestrator.model:add-generated-entity activity article-root-uri)
    (orchestrator.model:add-generated-entity activity (orchestrator.model:resource-uri work))
    (orchestrator.model:add-generated-entity activity (orchestrator.model:resource-uri expression))
    (orchestrator.model:add-generated-entity activity (orchestrator.model:resource-uri manifestation))
    (dolist (fmt formats)
      (orchestrator.model:add-generated-entity activity (orchestrator.model:resource-uri fmt)))

    ;; Validate complete stack before returning
    (validate-frbr-stack article-root work expression manifestation formats)

    ;; Return all components
    (values article-root work expression manifestation formats activity)))

;;; ============================================================
;;; PREFIX STRIPPING - Remove redundant @prefix blocks
;;; ============================================================

(defun strip-leading-prefix-block (ttl)
  "Remove @prefix/@base declarations from the start of a Turtle string.

   Individual FRBR generators emit their own prefix block for standalone use.
   When assembling a unified file that already has one canonical prefix block,
   call this function on each layer's output before writing it to the stream.

   Skips all leading @prefix and @base lines, then skips exactly one
   blank line that typically follows the prefix block, then returns the rest."
  (let ((pos 0)
        (len (length ttl)))
    (loop
      (when (>= pos len) (return))
      (let* ((eol (or (position #\Newline ttl :start pos) len))
             (line (subseq ttl pos eol)))
        (cond
          ((and (>= (length line) 7) (string= "@prefix" (subseq line 0 7)))
           (setf pos (min len (1+ eol))))
          ((and (>= (length line) 6) (string= "@base " (subseq line 0 6)))
           (setf pos (min len (1+ eol))))
          ;; Blank line immediately after prefix block: skip it and stop scanning
          ((string= "" (string-trim " " line))
           (setf pos (min len (1+ eol)))
           (return))
          ;; First non-prefix content line: stop scanning
          (t (return)))))
    (subseq ttl (min pos len))))

;;; ============================================================
;;; UNIFIED TTL GENERATION
;;; ============================================================

(defun generate-unified-article-ttl (article-root work expression manifestation formats activity)
  "Generate complete unified Turtle file for article

   Arguments:
     article-root:  frbr-article-root instance
     work:          frbr-work instance
     expression:    frbr-expression instance
     manifestation: frbr-manifestation instance
     formats:       List of frbr-format instances
     activity:      prov-activity instance

   Returns:
     String containing complete Turtle RDF

   Output structure:
     1. File header
     2. Canonical prefixes
     3. Identity Triples (Person + Organization for Knowledge Panel)
     4. ODRL Attribution Policy (AI citation enforcement)
     5. Article Root node
     6. PROV-O Activity node
     7. FRBR Work
     8. FRBR Expression
     9. FRBR Manifestation
     10. FRBR Formats (HTML, Turtle, JSON-LD)
     11. Paragraph Subdivisions
     12. File footer"

  (with-output-to-string (stream)
    (let ((article-num (orchestrator.model:article-number article-root)))

      ;; 1. FILE HEADER
      (emit-canonical-file-header stream
                                   :article-number article-num
                                   :layer "COMPLETE FRBR+ELI+PROV-O")

      ;; 2. CANONICAL PREFIXES
      (emit-canonical-prefixes stream)

      ;; 3. IDENTITY TRIPLES (Person + Organization for Knowledge Panel)
      (format stream "# ============================================================~%")
      (format stream "# RICH ENTITY IDENTITY - Knowledge Panel Ready~%")
      (format stream "# ============================================================~%")
      (terpri stream)
      (write-string (orchestrator.spec:generate-identity-triples) stream)
      (terpri stream)

      ;; 4. ODRL ATTRIBUTION POLICY (AI Citation Enforcement)
      (when (orchestrator.spec:odrl-enabled-p)
        (format stream "# ============================================================~%")
        (format stream "# W3C ODRL ATTRIBUTION POLICY~%")
        (format stream "# ============================================================~%")
        (terpri stream)
        (write-string (orchestrator.spec:generate-odrl-policy) stream)
        (terpri stream))

      ;; 5. VOID DATASET DESCRIPTOR (Linked Data Context)
      (format stream "# ============================================================~%")
      (format stream "# VOID DATASET - Linked Data Discovery~%")
      (format stream "# ============================================================~%")
      (terpri stream)
      (write-string (strip-leading-prefix-block
                     (orchestrator.spec:generate-void-dataset-descriptor)) stream)
      (terpri stream)

      ;; 6. ARTICLE ROOT NODE
      (format stream "# ============================================================~%")
      (format stream "# ARTICLE ROOT NODE - Canonical Entry Point~%")
      (format stream "# ============================================================~%")
      (terpri stream)
      (write-string (strip-leading-prefix-block (generate-rdf article-root)) stream)
      (terpri stream)

      ;; 7. PROV-O ACTIVITY NODE
      ;; Note: generate-rdf is used directly — the Activity IS the generation event,
      ;; so it must not reference itself via prov:wasGeneratedBy.
      (format stream "# ============================================================~%")
      (format stream "# PROV-O ACTIVITY - Generation Process~%")
      (format stream "# ============================================================~%")
      (terpri stream)
      (write-string (strip-leading-prefix-block
                     (generate-rdf activity)) stream)
      (terpri stream)

      ;; 8. FRBR WORK LAYER
      (format stream "# ============================================================~%")
      (format stream "# FRBR WORK LAYER - Abstract Legal Concept~%")
      (format stream "# ============================================================~%")
      (terpri stream)
      (write-string (strip-leading-prefix-block
                     (generate-rdf-with-activity work activity)) stream)
      (terpri stream)

      ;; 9. FRBR EXPRESSION LAYER
      (format stream "# ============================================================~%")
      (format stream "# FRBR EXPRESSION LAYER - Greek Language Realization~%")
      (format stream "# ============================================================~%")
      (terpri stream)
      (write-string (strip-leading-prefix-block
                     (generate-rdf-with-activity expression activity)) stream)
      (terpri stream)

      ;; 10. FRBR MANIFESTATION LAYER
      (format stream "# ============================================================~%")
      (format stream "# FRBR MANIFESTATION LAYER - Digital Embodiment~%")
      (format stream "# ============================================================~%")
      (terpri stream)
      (write-string (strip-leading-prefix-block
                     (generate-rdf-with-activity manifestation activity)) stream)
      (terpri stream)

      ;; 11. FRBR FORMAT LAYERS
      (format stream "# ============================================================~%")
      (format stream "# FRBR FORMAT LAYERS - Specific Encodings~%")
      (format stream "# ============================================================~%")
      (terpri stream)
      (dolist (fmt (sort (copy-list formats) #'string<
                         :key (lambda (f)
                                (symbol-name (orchestrator.model:format-type f)))))
        (write-string (strip-leading-prefix-block
                       (generate-rdf-with-activity fmt activity)) stream)
        (terpri stream))

      ;; 12. PARAGRAPH SUBDIVISIONS (Atomic Granularity)
      (let ((paragraphs (orchestrator.model:paragraphs expression)))
        (when paragraphs
          (format stream "# ============================================================~%")
          (format stream "# PARAGRAPH SUBDIVISIONS - Atomic Content Nodes~%")
          (format stream "# ============================================================~%")
          (terpri stream)
          (loop for para in paragraphs
                for para-num = (getf para :number)
                for para-text = (getf para :text)
                do (progn
                     (format stream "<~A/par/~D>~%"
                             (orchestrator.model:resource-uri article-root)
                             para-num)
                     (format stream "    a eli:LegalResourceSubdivision ;~%")
                     (format stream "    eli:number \"~D\" ;~%" para-num)
                     (format stream "    schema:text ~A .~%~%"
                             (orchestrator.spec:canonical-literal
                              (format nil "~D. ~A" para-num para-text)
                              :lang "el"))))))

      ;; 13. FILE FOOTER
      (format stream "# ============================================================~%")
      (format stream "# END OF UNIFIED FRBR+ELI+PROV-O OUTPUT~%")
      (format stream "# Article ~D - Complete Canonical Representation~%" article-num)
      (format stream "# ============================================================~%"))))

;;; ============================================================
;;; RDF GENERATION WITH ACTIVITY LINKAGE
;;; ============================================================

(defgeneric generate-rdf-with-activity (frbr-instance activity)
  (:documentation "Generate RDF with prov:wasGeneratedBy linkage"))

(defmethod generate-rdf-with-activity (frbr-instance activity)
  "Default: Generate RDF and append Activity linkage"

  (let ((base-rdf (generate-rdf frbr-instance))
        (activity-uri (orchestrator.model:resource-uri activity)))

    ;; Insert prov:wasGeneratedBy before final period
    (let ((last-dot-pos (position #\. base-rdf :from-end t)))
      (if last-dot-pos
          (format nil "~A ;~%    prov:wasGeneratedBy <~A>~A"
                  (subseq base-rdf 0 last-dot-pos)
                  activity-uri
                  (subseq base-rdf last-dot-pos))
          ;; Fallback if no period found
          (format nil "~A~%    prov:wasGeneratedBy <~A> .~%"
                  base-rdf
                  activity-uri)))))

;;; ============================================================
;;; PUBLIC API - WRITE UNIFIED FILE
;;; ============================================================

(defun write-unified-article-file (article-number title content output-dir
                                    &key
                                    (article-suffix "")
                                    (corpus-name (config-get "corpus.short_name"))
                                    authority)
  "Public API: Generate and write unified article Turtle file

   GATE-5: Validation is UNCONDITIONAL (no :validate parameter)

   Arguments:
     article-number: Integer (1-120)
     title:          Greek title
     content:        Greek content
     output-dir:     Output directory path
     corpus-name:    Corpus identifier
     authority:      REQUIRED - :canonical or :provenance

   Returns:
     File path if successful, NIL if failed

   Output file: article-NNN.ttl

   Guarantees:
     - UNCONDITIONAL validation before emit-graph
     - Valid input → same output (deterministic)
     - Invalid input → HARD FAIL before write"

  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :canonical or :authority :provenance"))

  ;; Determine the intended output path up-front for error reporting.
  ;; This is computed outside the handler-case so it is available in the error clause
  ;; even when the inner body has not yet run (e.g., make-complete-frbr-stack fails).
  (let ((intended-filepath (merge-pathnames
                             ;; Suffix-safe filename via the single source of truth,
                             ;; so a lettered article (100Α) never overwrites its base.
                             (format nil "article-~A.ttl"
                                     (orchestrator.model:pad-article-id article-number article-suffix))
                             output-dir)))

    (handler-case
        (multiple-value-bind (article-root work expression manifestation formats activity)
            (make-complete-frbr-stack article-number title content
                                      :article-suffix article-suffix
                                      :corpus-name corpus-name)

          ;; UNCONDITIONAL FRBR stack validation (object-level)
          (validate-frbr-stack article-root work expression manifestation formats)

          ;; Generate unified TTL
          (let* ((ttl-content (generate-unified-article-ttl
                                article-root work expression manifestation formats activity))
                 ;; Normalize TTL content for deterministic validation
                 (normalized-ttl (normalize-ttl-content ttl-content))
                 (filepath intended-filepath))

            ;; GATE-5: UNCONDITIONAL contract validation before emit-graph
            ;; (Deterministic, zero external deps, fail-fast)
            (orchestrator.validation-authority:validate-canonical-ttl
              normalized-ttl :context article-number)

            ;; Write file via unified authority
            (orchestrator.write-authority:emit-graph normalized-ttl filepath :authority authority)

            filepath))

      ;; ── ERROR HANDLER ───────────────────────────────────────────────────────
      ;; POLICY: NO SILENT DATA LOSS.
      ;;
      ;; Formerly this clause returned NIL, silently discarding the error and
      ;; allowing the pipeline to continue as if nothing had happened. That
      ;; behaviour constitutes silent data loss: callers cannot distinguish
      ;; "file was not written" from "file was written successfully".
      ;;
      ;; The correct approach is:
      ;;   1. Log a FATAL entry with full diagnostic context.
      ;;   2. Re-signal as a structured unified-generation-error so that callers
      ;;      using with-frbr-error-handling or handler-case can react explicitly.
      ;;
      ;; Callers that previously checked (null result) must now use
      ;; with-frbr-error-handling or handler-case on unified-generation-error.
      ;; ────────────────────────────────────────────────────────────────────────
      (error (e)
        ;; Emit full diagnostic log before re-signaling.
        (format *error-output*
                "~&~%FATAL: write-unified-article-file FAILED~%~
                 ~&FATAL: Article number : ~D~%~
                 ~&FATAL: Intended output: ~A~%~
                 ~&FATAL: Condition type : ~S~%~
                 ~&FATAL: Condition      : ~A~%~
                 ~&FATAL: No output file written — pipeline integrity preserved.~%~%"
                article-number
                intended-filepath
                (type-of e)
                e)
        ;; Re-signal as a fully typed structured condition.
        ;; unified-generation-error inherits from frbr-generation-error,
        ;; so with-frbr-error-handling and with-abortable-pipeline catch it.
        (error 'unified-generation-error
               :article-number article-number
               :cause e
               :output-path intended-filepath
               :message (format nil
                                "Unified article file generation failed for article ~D: ~A"
                                article-number
                                e))))))

(defun normalize-ttl-content (ttl-content)
  "Normalize TTL content for deterministic validation.

   - Ensure string type
   - Ensure trailing newline
   - Trim excessive trailing whitespace

   Returns: Normalized string"

  (unless (stringp ttl-content)
    (error "TTL content must be a string, got: ~A" (type-of ttl-content)))

  (let ((normalized (string-right-trim '(#\Space #\Tab) ttl-content)))
    ;; Ensure trailing newline
    (if (and (> (length normalized) 0)
             (not (char= (char normalized (1- (length normalized))) #\Newline)))
        (concatenate 'string normalized (string #\Newline))
        normalized)))

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(make-complete-frbr-stack
          generate-unified-article-ttl
          generate-rdf-with-activity
          strip-leading-prefix-block
          write-unified-article-file
          normalize-ttl-content))
