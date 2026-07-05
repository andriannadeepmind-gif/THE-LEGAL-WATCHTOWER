 ;;;; systems/orchestrator-engine-sbcl/stages/generate-rdf.lisp
;;;; RDF generation stage - GREEKLAW v2.0 CANONICAL AUTHORITY
;;;;
;;;; ΩMEGA ENGINE ACTIVATED:
;;;;    - FRBR generation now uses orchestrator-omega modules
;;;;    - Complete CLOS-based FRBR stack (Article Root + Work/Expression/Manifestation/Formats)
;;;;    - PROV-O Activity tracking
;;;;    - Deterministic RDF canonicalization
;;;;    - Production-grade semantic web generation

(in-package :orchestrator.engine.sbcl)

;;; ============================================================
;;; CONFIGURATION - CANONICAL PARAMETERS
;;; ============================================================

;; NOTE: *uri-base* is DEPRECATED. Use orchestrator.uris:get-eli-const-prefix instead.
(defparameter *uri-base* nil
  "DEPRECATED: Use orchestrator.uris:get-eli-const-prefix instead")

;;; ============================================================
;;; MAIN STAGE FUNCTION
;;; ============================================================

(defun generate-rdf-stage (context)
  "Generate RDF with FRBR structure and canonical URIs

   IIR TRANSFORMATION POINT:
     Input:  normalized-article-input instances (IIR)
     Output: article instances with complete FRBR+RDF

   This is where parser-independent IIR becomes semantic artifacts."
  (let ((normalized-inputs (orchestrator.core:get-context-value context :articles))
        (corpus (orchestrator.core:get-context-value context :corpus)))

    (unless normalized-inputs
      (error 'orchestrator.spec:config-error
             :message "No normalized inputs in context"
             :config-key :articles))

    (unless corpus
      (error 'orchestrator.spec:config-error
             :message "Corpus not specified"
             :config-key :corpus))

    (log:info () "Generating CANONICAL RDF for ~D normalized inputs" (length normalized-inputs))

    ;; Transform IIR → Article with FRBR
    (let ((articles (loop for normalized-input in normalized-inputs
                          collect (generate-canonical-rdf normalized-input corpus))))

      ;; Generate global manifest using Ωmega Corpus Root
      (let* ((article-uris (loop for article in articles
                                 collect (orchestrator.model:article-eli-uri article)))
             (issued-date  (or (orchestrator.spec:config-get "corpus.publication.date")
                               (error "generate-rdf-stage: corpus.publication.date not configured")))
             (corpus-root (orchestrator.spec:make-corpus-root
                            :corpus-id :gr-syntagma
                            :corpus-name (or (orchestrator.spec:config-get "corpus.name")
                                             (error "generate-rdf-stage: corpus.name not configured"))
                            :corpus-uri (orchestrator.uris:get-eli-const-prefix)
                            :issued-date issued-date
                            :modified-date (or (orchestrator.spec:config-get "corpus.modified_date")
                                               issued-date)
                            :article-uris article-uris))
             (manifest (orchestrator.spec:generate-corpus-manifest-ttl corpus-root)))
        (orchestrator.core:set-context-value context :syntagma-manifest manifest))

      ;; Store Article instances (NOT IIR) in context
      (orchestrator.core:set-context-value context :articles articles)
      context)))

;;; ============================================================
;;; CANONICAL URI GENERATION
;;; ============================================================

(defun make-canonical-uri (article-number &optional (suffix "") (article-label nil))
  "Generate stable canonical URI using configured ELI prefix.
   Uses article-label (e.g. '5Α') when provided, falling back to article-number integer."
  (format nil "~A/art/~A~A"
          (orchestrator.uris:get-eli-const-prefix)
          (or article-label article-number)
          suffix))

(defun make-expression-uri (article-number)
  "Generate expression URI (Greek language)"
  (make-canonical-uri article-number "/exp/ell"))

(defun make-format-uri (article-number format-type)
  "Generate format manifestation URI"
  (make-canonical-uri article-number 
    (format nil "/exp/ell/format/~A" format-type)))

;;; ============================================================
;;; ARTICLE RDF GENERATION
;;; ============================================================

(defun generate-canonical-rdf (normalized-input corpus)
  "Generate canonical RDF from normalized input (IIR) → Article instance

   CRITICAL IIR TRANSFORMATION:
     Input:  normalized-article-input (parser-independent)
     Output: article instance (with FRBR+RDF)

   Arguments:
     normalized-input: normalized-article-input instance (IIR)
     corpus:            Corpus name (e.g., 'syntagma')

   Returns:
     article instance with complete RDF artifacts"
  (declare (ignore corpus))

  (let* ((article-num   (orchestrator.model:article-number normalized-input))
         (article-label (orchestrator.model:article-label normalized-input)))
    (log:info () "Generating canonical RDF for Article ~A (from IIR)" article-label)

    (handler-case
        (let* (;; Extract from IIR
               (title (orchestrator.model:article-title normalized-input))
               (content (orchestrator.model:article-content normalized-input))
               (source-type (orchestrator.model:source-type normalized-input))
               (source-path (orchestrator.model:source-path normalized-input))
               (extraction-metadata (orchestrator.model:source-metadata normalized-input))

               ;; Generate FRBR+RDF using Ωmega Engine
               (canonical-uri (make-canonical-uri article-num "" article-label))
               (turtle-rdf (generate-frbr-unified-from-iir normalized-input))

               ;; Create Article instance with FRBR results
               (article (make-instance 'orchestrator.model:article
                                      :number article-num
                                      :label article-label
                                      :title title
                                      :content content
                                      :state :generating  ; Start in :generating state (IIR already parsed)
                                      :metadata (append (list :source-type source-type
                                                              :source-path source-path)
                                                        extraction-metadata))))

          ;; Set canonical URI
          (setf (orchestrator.model:article-eli-uri article) canonical-uri)

          ;; ΩΜΕΓΑ: Set unified Turtle RDF (ONE FILE PER ARTICLE)
          ;; This contains EVERYTHING: Article Root, Work, Expression,
          ;; Manifestation, Formats, PROV-O Activity
          ;; 1. RDF/TURTLE (machine-readable semantic data)
          (setf (orchestrator.model:article-rdf-turtle article) turtle-rdf)

          ;; 2. HTML+RDFa+JSON-LD (human & machine readable)
          ;; Contains: Schema.org structured data, embedded JSON-LD for search engines
          ;; Multi-format serialization for maximum interoperability
          (setf (orchestrator.model:article-json-ld article) (render-canonical-jsonld article))
          (setf (orchestrator.model:article-html article) (render-canonical-html article))

          ;; State transition
          (orchestrator.spec:transition article :validating)
          article)

      (error (e)
        (error 'orchestrator.spec:rdf-error
               :message (format nil "RDF generation failed for article ~D: ~A" article-num e)
               :article article-num)))))

;;; ============================================================
;;; FRBR PIPELINE INTEGRATION (Ω-LEVEL) - ACTIVE
;;; ============================================================

(defun generate-frbr-unified-from-iir (normalized-input)
  "Generate UNIFIED FRBR stack with complete ELI compliance

   ACCEPTS IIR (normalized-article-input) - NOT Article

   UNIFIED FRBR Architecture (DeepMind Standard):
   - Article Root (top-level container)
   - FRBR Work (abstract legal concept)
   - FRBR Expression (Greek language realization)
   - FRBR Manifestation (digital embodiment)
   - FRBR Formats (HTML, Turtle, JSON-LD) ← ELI REQUIRED
   - PROV-O Activity (complete provenance tracking)
   - Paragraph-level subdivisions (eli:LegalResourceSubdivision)
   - SHA-256 cryptographic hashing
   - Personal authority metadata (pav:curatedBy from config)
   - W3C ODRL Attribution Policy
   - Saturation metrics

   Arguments:
     normalized-input: normalized-article-input instance (IIR)

   Returns:
     String containing complete Turtle RDF (UNIFIED FRBR+ELI+PROV-O)"

  (let* ((article-num (orchestrator.model:article-number normalized-input))
         ;; Letter suffix (e.g. "Α" for 100Α) derived from the label, so the FRBR
         ;; URIs/eIds keep 100 and 100Α distinct. "" for a plain article.
         (article-suffix (let ((lbl (orchestrator.model:article-label normalized-input)))
                           (if lbl (string-left-trim "0123456789 " lbl) "")))
         (title (extract-title-only (orchestrator.model:article-title normalized-input)))
         (content (orchestrator.model:article-content normalized-input)))

    ;; Generate UNIFIED FRBR stack
    ;; Includes: ALL FRBR layers + ELI Format nodes + PROV-O Activity + Paragraphs
    (multiple-value-bind (article-root work expression manifestation formats activity)
        (orchestrator.spec:make-complete-frbr-stack article-num title content
                                                     :article-suffix article-suffix
                                                     :corpus-name (orchestrator.spec:config-get "corpus.short_name"))

      ;; Generate complete unified TTL
      (orchestrator.spec:generate-unified-article-ttl
        article-root work expression manifestation formats activity))))

;;; ============================================================
;;; JSON-LD RENDERER
;;; ============================================================

(defun render-canonical-jsonld (article)
  "Render article as JSON-LD with LEVEL 300 config-driven metadata

   Uses orchestrator.spec:generate-jsonld-organization and generate-jsonld-article
   which pull metadata from constitution.yaml (CEO, founded date, etc.)"
  (let* ((article-num (or (orchestrator.model:article-label article)
                          (princ-to-string (orchestrator.model:article-number article))))
         (title (extract-title-only (orchestrator.model:article-title article)))
         (content (orchestrator.model:article-content article))
         (content-hash (orchestrator.spec:calculate-sha256-hash content)))

    ;; Combine organization and article JSON-LD
    (with-output-to-string (s)
      (write-string (orchestrator.spec:generate-jsonld-organization) s)
      (terpri s)
      (write-string (orchestrator.spec:generate-jsonld-article article-num title content-hash) s))))

;;; ============================================================
;;; HTML RENDERER - CANONICAL FORMAT
;;; ============================================================

(defun render-canonical-html (article)
  "Render article as HTML with LEVEL 300 config-driven metadata

   Uses orchestrator.spec:generate-html-with-rdfa which:
   - Embeds JSON-LD with CEO metadata (founded: 1977, ORCID, etc.)
   - Includes RDFa markup for SEO
   - Pulls all identity data from constitution.yaml"
  (let* ((article-num (or (orchestrator.model:article-label article)
                          (princ-to-string (orchestrator.model:article-number article))))
         (title (extract-title-only (orchestrator.model:article-title article)))
         (content (orchestrator.model:article-content article))
         (paragraphs (orchestrator.spec:parse-article-into-paragraphs content))
         (content-hash (orchestrator.spec:calculate-sha256-hash content)))

    ;; Call LEVEL 300 HTML generator from html-rdfa-generator.lisp
    (orchestrator.spec:generate-html-with-rdfa
      article-num title content paragraphs content-hash)))

;;; ============================================================
;;; HELPER FUNCTIONS
;;; ============================================================

(defun extract-title-only (full-title)
  "Extract the bare title from 'Άρθρο N - Title'. When there is no distinct
   title (the value is just 'Άρθρο N', the no-title fallback), return \"\" so the
   generator shows a clean 'Άρθρο N' instead of 'Άρθρο N - Άρθρο N'."
  (let ((pos (search " - " full-title)))
    (if pos
        (subseq full-title (+ pos 3))
        "")))

(defun html-escape (text)
  "Escape HTML special characters"
  (with-output-to-string (out)
    (loop for char across text
          do (case char
               (#\& (write-string "&amp;" out))
               (#\< (write-string "&lt;" out))
               (#\> (write-string "&gt;" out))
               (#\" (write-string "&quot;" out))
               (#\' (write-string "&#39;" out))
               (t (write-char char out))))))