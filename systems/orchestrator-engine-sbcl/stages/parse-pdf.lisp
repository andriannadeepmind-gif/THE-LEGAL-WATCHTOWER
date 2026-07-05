;;;; systems/orchestrator-engine-sbcl/stages/parse-pdf.lisp
;;;; PARSE-PDF stage - NSA-GRADE (5-Layer Pipeline)
;;;;
;;;; Parses PDF files through 5-layer pipeline with full traceability
;;;;
;;;; Responsibility:
;;;;   - ONLY handles :pdf source type
;;;;   - Skips if :source-type != :pdf (with logged reason)
;;;;   - Calls pdf-adapter (5-layer pipeline) to extract IIR instances
;;;;   - Validates pipeline output (trace completeness)
;;;;   - Writes :articles to context with full provenance
;;;;
;;;; Orthogonality:
;;;;   - No JSON routing/handling
;;;;   - No XML/HTML/Markdown handling
;;;;   - Single semantic transformation: PDF → IIR
;;;;
;;;; ============================================================================
;;;; COMMON LISP FEATURES UTILIZED
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CONDITIONS & RESTARTS    │ Recoverable pipeline errors                  │
;;;; │                          │ • use-legacy-mode restart                    │
;;;; │                          │ • skip-validation restart                    │
;;;; │                          │ • continue-with-warnings restart             │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Rich returns with validation metadata        │
;;;; │                          │ (values articles validation-result)          │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ HANDLER-BIND             │ Fine-grained error handling with restarts    │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *parse-pdf-use-pipeline* t
  "If T, use 5-layer pipeline; if NIL, use legacy mode")

(defvar *parse-pdf-validate-traces* t
  "If T, validate trace completeness of IIR results")

(defvar *parse-pdf-strict-validation* nil
  "If T, fail on validation warnings (not just errors)")

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition parse-pdf-error (orchestrator.spec:stage-error)
  ((source-path :initarg :source-path :reader error-source-path)
   (pipeline-layer :initarg :pipeline-layer :initform nil :reader error-pipeline-layer))
  (:report (lambda (c stream)
             (format stream "Parse-PDF error~@[ at layer ~A~]: ~A (source: ~A)"
                     (error-pipeline-layer c)
                     (orchestrator.spec:error-message c)
                     (error-source-path c)))))

(define-condition parse-pdf-validation-warning (warning)
  ((source-path :initarg :source-path :reader warning-source-path)
   (issues :initarg :issues :reader warning-issues))
  (:report (lambda (c stream)
             (format stream "Parse-PDF validation warnings for ~A: ~D issues"
                     (warning-source-path c)
                     (length (warning-issues c))))))

;;; ============================================================================
;;; TRACE VALIDATION
;;; ============================================================================

(defun validate-iir-traces (articles source-path)
  "Validate that all IIR articles have complete trace information.

   Checks:
     - Each article has :trace-id in source-metadata
     - Each article has :extraction-confidence ≥ threshold
     - Pipeline method is recorded

   Returns: (values valid-p issues)"
  (let ((issues '())
        (valid t))

    (loop for article in articles
          for idx from 1
          for metadata = (orchestrator.model:source-metadata article)
          for trace-id = (getf metadata :trace-id)
          for extractor = (getf metadata :extractor)
          for confidence = (orchestrator.model:extraction-confidence article)
          do
             ;; Check trace-id presence
             (unless trace-id
               (push (format nil "Article ~D missing trace-id" idx) issues)
               (setf valid nil))

             ;; Check extractor method (informational — does not fail validation)
             (unless (member extractor '("5-layer-pipeline" "pdf-state-machine") :test #'equal)
               (push (format nil "Article ~D unknown extractor: ~A" idx extractor) issues))

             ;; Check confidence
             (when (and confidence (< confidence 0.5))
               (push (format nil "Article ~D low confidence: ~,2F" idx confidence)
                     issues)))

    ;; Log validation result
    (if issues
        (log:warn () "IIR trace validation: ~D issues for ~A" (length issues) source-path)
        (log:info () "IIR trace validation: PASSED for ~A (~D articles)"
                  source-path (length articles)))

    (values valid (nreverse issues))))

;;; ============================================================================
;;; PIPELINE EXECUTION WITH RESTARTS
;;; ============================================================================

(defun parse-pdf-with-pipeline (source-path)
  "Execute PDF parsing with 5-layer pipeline and restarts.

   Provides restarts:
     USE-LEGACY-MODE - Fall back to legacy text extraction
     SKIP-VALIDATION - Continue without trace validation
     CONTINUE-WITH-WARNINGS - Accept despite validation warnings

   Returns: List of IIR articles"
  (restart-case
      (handler-bind
          ((orchestrator.spec:stage-error
             (lambda (c)
               (log:error () "Pipeline error: ~A" c)
               ;; Allow recovery via restarts
               (when (find-restart 'use-legacy-mode)
                 (invoke-restart 'use-legacy-mode)))))

        ;; Execute pipeline
        (let ((articles (pdf-adapter source-path :use-pipeline t)))

          ;; Validate traces if enabled
          (when *parse-pdf-validate-traces*
            (multiple-value-bind (valid-p issues)
                (validate-iir-traces articles source-path)
              (when (and (not valid-p) *parse-pdf-strict-validation*)
                (restart-case
                    (error 'parse-pdf-error
                           :stage-name :parse-pdf
                           :message (format nil "Trace validation failed: ~{~A~^, ~}" issues)
                           :source-path source-path
                           :pipeline-layer 5)
                  (continue-with-warnings ()
                    :report "Continue despite validation warnings"
                    (log:warn () "Continuing with ~D validation warnings" (length issues)))))

              ;; Signal warning even if not strict
              (when issues
                (warn 'parse-pdf-validation-warning
                      :source-path source-path
                      :issues issues))))

          articles))

    ;; RESTART: Fall back to legacy mode
    (use-legacy-mode ()
      :report "Use legacy text extraction (no pipeline)"
      (log:warn () "Falling back to legacy mode for ~A" source-path)
      (pdf-adapter source-path :use-pipeline nil))

    ;; RESTART: Skip validation
    (skip-validation ()
      :report "Skip trace validation"
      (let ((*parse-pdf-validate-traces* nil))
        (pdf-adapter source-path :use-pipeline t)))))

;;; ============================================================================
;;; STATISTICS COLLECTION
;;; ============================================================================

(defun collect-parse-statistics (articles source-path)
  "Collect statistics about parsed articles for context metadata."
  (let ((total (length articles))
        (with-trace 0)
        (high-confidence 0)
        (avg-confidence 0.0))

    (dolist (article articles)
      (let ((metadata (orchestrator.model:source-metadata article))
            (confidence (orchestrator.model:extraction-confidence article)))

        (when (getf metadata :trace-id)
          (incf with-trace))

        (when (and confidence (> confidence 0.9))
          (incf high-confidence))

        (when confidence
          (incf avg-confidence confidence))))

    (when (> total 0)
      (setf avg-confidence (/ avg-confidence total)))

    (list :source-path source-path
          :total-articles total
          :articles-with-trace with-trace
          :high-confidence-count high-confidence
          :average-confidence avg-confidence
          :pipeline-mode *parse-pdf-use-pipeline*)))

;;; ============================================================================
;;; MAIN STAGE ENTRY POINT
;;; ============================================================================

(defun parse-pdf-stage (context)
  "Parse PDF documents through 5-layer pipeline - NSA-GRADE

   PRECONDITION:
     - source-normalize-stage must have run first
     - context must contain :source-type and :source-path

   EXECUTION LOGIC:
     - If :source-type = :pdf → execute 5-layer pipeline
     - If :source-type ≠ :pdf → skip (with logged reason)

   INPUT:
     context with :source-type :pdf and :source-path

   OUTPUT:
     context with:
       :articles (list of normalized-article-input with full trace)
       :parse-statistics (pipeline statistics)

   ARCHITECTURE:
     - Stage orthogonality: ONLY PDF
     - 5-Layer Pipeline: Layout → Logical → Canonical → AST → IIR
     - Full traceability at each layer
     - Conditions & Restarts for graceful error recovery

   COMMON LISP FEATURES:
     - HANDLER-BIND with restarts for pipeline errors
     - Multiple values for validation results
     - Condition system for structured errors"

  (handler-case
      (let* ((source-type (orchestrator.core:get-context-value context :source-type))
             (source-path (orchestrator.core:get-context-value context :source-path))
             (sources (orchestrator.core:get-context-value context :sources))
             (all-statistics '()))

        ;; ================================================================
        ;; MULTI-SOURCE MODE (5-Layer Pipeline)
        ;; ================================================================
        (when sources
          (log:info () "parse-pdf: Multi-source mode detected (pipeline=~A)"
                    *parse-pdf-use-pipeline*)
          ;; Filter only PDF sources
          (let ((pdf-sources (remove-if-not (lambda (s) (eq (getf s :type) :pdf)) sources)))
            (if pdf-sources
                (let ((all-articles '()))
                  (dolist (source pdf-sources)
                    (let* ((path (getf source :path))
                           (articles (if *parse-pdf-use-pipeline*
                                         (parse-pdf-with-pipeline path)
                                         (pdf-adapter path :use-pipeline nil))))
                      (log:info () "parse-pdf: Parsed ~D articles from ~A" (length articles) path)
                      (push (collect-parse-statistics articles path) all-statistics)
                      (setf all-articles (nconc all-articles articles))))

                  ;; Store results
                  (orchestrator.core:set-context-value context :articles all-articles)
                  (orchestrator.core:set-context-value context :parse-statistics
                                                       (nreverse all-statistics))
                  (log:info () "parse-pdf: Total ~D articles from ~D PDF sources"
                            (length all-articles) (length pdf-sources))
                  (return-from parse-pdf-stage context))

                (progn
                  (log:info () "parse-pdf: No PDF sources in multi-source list → SKIP")
                  (return-from parse-pdf-stage context)))))

        ;; ================================================================
        ;; SINGLE-SOURCE MODE: TYPE GUARD
        ;; ================================================================
        (unless (eq source-type :pdf)
          (log:info () "parse-pdf: source-type=~A (not :pdf) → SKIP stage" source-type)
          (return-from parse-pdf-stage context))

        ;; ================================================================
        ;; EXECUTE: Parse PDF through 5-Layer Pipeline
        ;; ================================================================
        (log:info () "parse-pdf: source-type=:pdf → EXECUTE (pipeline=~A)"
                  *parse-pdf-use-pipeline*)
        (log:info () "parse-pdf: Processing ~A" source-path)

        ;; Validate path exists
        (unless source-path
          (error 'orchestrator.spec:config-error
                 :message "parse-pdf: :source-path not found in context (source-normalize-stage must run first)"
                 :config-key :source-path))

        ;; Execute pipeline with restarts
        (let ((articles (if *parse-pdf-use-pipeline*
                            (parse-pdf-with-pipeline source-path)
                            (pdf-adapter source-path :use-pipeline nil))))

          ;; Collect statistics
          (let ((statistics (collect-parse-statistics articles source-path)))
            (orchestrator.core:set-context-value context :parse-statistics (list statistics)))

          ;; Write to context
          (orchestrator.core:set-context-value context :articles articles)
          (log:info () "parse-pdf: Extracted ~D articles with ~:[legacy~;pipeline~] mode"
                    (length articles) *parse-pdf-use-pipeline*)

          ;; Return context
          context))

    ;; Handle pipeline-specific errors
    (parse-pdf-error (e)
      (log:error () "parse-pdf-stage pipeline error: ~A" e)
      (error e))

    ;; Handle generic errors
    (error (e)
      (log:error () "parse-pdf-stage failed: ~A" e)
      (error e))))

;;; ============================================================================
;;; END OF PARSE-PDF.LISP
;;; ============================================================================
