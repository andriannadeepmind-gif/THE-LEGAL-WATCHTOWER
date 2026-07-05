;;;; systems/orchestrator-engine-sbcl/stages/parse-raw-text.lisp
;;;; PARSE-RAW-TEXT stage - NSA-GRADE 5-Layer Pipeline for Text Sources
;;;;
;;;; Responsibility:
;;;;   - ONLY handles :raw-text source type
;;;;   - Skips if :source-type != :raw-text (with logged reason)
;;;;   - Calls raw-text-adapter (5-layer pipeline) to produce IIR instances
;;;;   - Supports both single-source and multi-source modes
;;;;   - Writes :articles to context
;;;;
;;;; Orthogonality (mirror of parse-pdf.lisp):
;;;;   - No JSON / PDF routing
;;;;   - Single semantic transformation: raw-text → IIR
;;;;   - Stage skip is a FIRST-CLASS operation, not an error
;;;;
;;;; Common Lisp features:
;;;;   ✓ CONDITIONS / HANDLER-CASE for structured error propagation
;;;;   ✓ RETURN-FROM for clean early exits (skip / multi-source)
;;;;   ✓ LOOP with NCONC for multi-source accumulation
;;;;   ✓ MULTIPLE-VALUES binding for statistics collection

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; STATISTICS COLLECTION
;;; ============================================================================

(defun collect-raw-text-statistics (articles source-path)
  "Collect aggregate statistics about parsed raw-text articles.

  Returns a plist suitable for storing in context metadata."
  (let* ((total      (length articles))
         (with-trace (loop for a in articles
                           count (getf (orchestrator.model:source-metadata a) :trace-id)))
         (avg-conf   (if (zerop total)
                         0.0
                         (/ (loop for a in articles
                                  sum (orchestrator.model:extraction-confidence a))
                            (float total)))))
    (list :source-path    source-path
          :total-articles total
          :with-trace     with-trace
          :avg-confidence avg-conf
          :pipeline-mode  :raw-text-5-layer)))

;;; ============================================================================
;;; MAIN STAGE ENTRY POINT
;;; ============================================================================

(defun parse-raw-text-stage (context)
  "Parse raw text through the 5-layer pipeline → IIR - NSA-GRADE

  PRECONDITION:
    source-normalize-stage has run; context contains
      :source-type = :raw-text
      :source-path = path to .txt file

  EXECUTION LOGIC:
    :source-type = :raw-text   → execute
    :source-type ≠ :raw-text   → skip with informational log

  OUTPUT:
    context with :articles (list of normalized-article-input)

  ARCHITECTURE:
    - Stage orthogonality: ONLY raw-text
    - Delegates to raw-text-adapter for full 5-layer pipeline
    - Collects parse statistics in :raw-text-statistics context key
    - HANDLER-CASE wraps entire stage for deterministic error classification"

  (handler-case
      (let* ((source-type (orchestrator.core:get-context-value context :source-type))
             (source-path (orchestrator.core:get-context-value context :source-path))
             (sources     (orchestrator.core:get-context-value context :sources))
             (all-stats   '()))

        ;; ── Multi-source mode ─────────────────────────────────────────────────
        (when sources
          (log:info () "parse-raw-text: multi-source mode detected")
          (let ((text-sources (remove-if-not
                               (lambda (s) (eq (getf s :type) :raw-text))
                               sources)))
            (if text-sources
                (let ((all-articles
                        (loop for src in text-sources
                              for path    = (getf src :path)
                              for text    = (uiop:read-file-string
                                             path :external-format :utf-8)
                              for articles = (raw-text-adapter text
                                                               :source-path path)
                              do (log:info () "parse-raw-text: ~D articles from ~A"
                                           (length articles) path)
                                 (push (collect-raw-text-statistics articles path)
                                       all-stats)
                              nconc articles)))
                  (orchestrator.core:set-context-value context :articles all-articles)
                  (orchestrator.core:set-context-value context
                                                       :raw-text-statistics
                                                       (nreverse all-stats))
                  (log:info () "parse-raw-text: multi-source total ~D articles from ~D sources"
                            (length all-articles) (length text-sources))
                  (return-from parse-raw-text-stage context))

                ;; No :raw-text sources in multi-source list → skip
                (progn
                  (log:info () "parse-raw-text: no :raw-text sources → SKIP")
                  (return-from parse-raw-text-stage context)))))

        ;; ── Single-source type guard ──────────────────────────────────────────
        (unless (eq source-type :raw-text)
          (log:info () "parse-raw-text: source-type=~A (not :raw-text) → SKIP stage"
                    source-type)
          (return-from parse-raw-text-stage context))

        ;; ── Execute: validate path, read file, run pipeline ───────────────────
        (log:info () "parse-raw-text: source-type=:raw-text → EXECUTE")

        (unless source-path
          (error 'orchestrator.spec:config-error
                 :message "parse-raw-text: :source-path not in context (source-normalize-stage must run first)"
                 :config-key :source-path))

        (unless (probe-file source-path)
          (error 'orchestrator.spec:config-error
                 :message (format nil "parse-raw-text: file not found: ~A" source-path)
                 :config-key :source-path))

        (let* ((text     (uiop:read-file-string source-path :external-format :utf-8))
               (articles (raw-text-adapter text :source-path source-path))
               (stats    (collect-raw-text-statistics articles source-path)))

          (orchestrator.core:set-context-value context :articles articles)
          (orchestrator.core:set-context-value context
                                               :raw-text-statistics
                                               (list stats))
          (log:info () "parse-raw-text: loaded ~D articles from ~A"
                    (length articles) source-path)

          context))

    ;; Parse-specific errors propagate unchanged (already typed)
    (raw-text-error (e)
      (log:error () "parse-raw-text-stage raw-text error: ~A" e)
      (error e))

    ;; Generic errors propagate unchanged (orchestrator.spec errors, etc.)
    (error (e)
      (log:error () "parse-raw-text-stage failed: ~A" e)
      (error e))))
