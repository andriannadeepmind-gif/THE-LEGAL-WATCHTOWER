;;;; systems/orchestrator-engine-sbcl/stages/load-json-source.lisp
;;;; LOAD-JSON-SOURCE stage - ΩΜΕΓΑ GRADE
;;;;
;;;; Loads JSON source files and creates normalized-article-input (IIR)
;;;;
;;;; Responsibility:
;;;;   - ONLY handles :json source type
;;;;   - Skips if :source-type != :json (with logged reason)
;;;;   - Calls json-adapter to create IIR instances
;;;;   - Writes :articles to context
;;;;
;;;; Orthogonality:
;;;;   - No PDF routing/handling
;;;;   - No XML/HTML/Markdown handling
;;;;   - Single semantic transformation: JSON → IIR

(in-package :orchestrator.engine.sbcl)

(defun load-json-source-stage (context)
  "Load JSON source and create normalized-article-input (IIR) - ΩΜΕΓΑ GRADE

   PRECONDITION:
     - source-normalize-stage must have run first
     - context must contain :source-type and :source-path

   EXECUTION LOGIC:
     - If :source-type = :json → execute
     - If :source-type ≠ :json → skip (with logged reason)

   INPUT:
     context with :source-type :json and :source-path

   OUTPUT:
     context with :articles (list of normalized-article-input)

   ARCHITECTURE:
     - Stage orthogonality: ONLY JSON
     - Skip logic prevents execution for wrong type
     - No routing, no ecase, no type branching"

  (handler-case
      (let* ((source-type (orchestrator.core:get-context-value context :source-type))
             (source-path (orchestrator.core:get-context-value context :source-path))
             (sources (orchestrator.core:get-context-value context :sources)))

        ;; ================================================================
        ;; MULTI-SOURCE MODE
        ;; ================================================================
        (when sources
          (log:info () "load-json-source: Multi-source mode detected")
          ;; Filter only JSON sources
          (let ((json-sources (remove-if-not (lambda (s) (eq (getf s :type) :json)) sources)))
            (if json-sources
                (let ((articles (loop for source in json-sources
                                      for path = (getf source :path)
                                      do (log:info () "load-json-source: Loading JSON from ~A" path)
                                      append (json-adapter path))))
                  (orchestrator.core:set-context-value context :articles articles)
                  (log:info () "load-json-source: Loaded ~D articles from ~D JSON sources"
                            (length articles) (length json-sources))
                  (return-from load-json-source-stage context))
                (progn
                  (log:info () "load-json-source: No JSON sources in multi-source list → SKIP")
                  (return-from load-json-source-stage context)))))

        ;; ================================================================
        ;; SINGLE-SOURCE MODE: TYPE GUARD
        ;; ================================================================
        (unless (eq source-type :json)
          (log:info () "load-json-source: source-type=~A (not :json) → SKIP stage" source-type)
          (return-from load-json-source-stage context))

        ;; ================================================================
        ;; EXECUTE: Load JSON source
        ;; ================================================================
        (log:info () "load-json-source: source-type=:json → EXECUTE")
        (log:info () "load-json-source: Loading JSON from ~A" source-path)

        ;; Validate path exists
        (unless source-path
          (error 'orchestrator.spec:config-error
                 :message "load-json-source: :source-path not found in context (source-normalize-stage must run first)"
                 :config-key :source-path))

        ;; Call json-adapter (creates IIR instances)
        (let ((articles (json-adapter source-path)))

          ;; Write to context
          (orchestrator.core:set-context-value context :articles articles)
          (log:info () "load-json-source: Loaded ~D articles" (length articles))

          ;; Return context
          context))

    (error (e)
      (log:error () "load-json-source-stage failed: ~A" e)
      (error e))))
