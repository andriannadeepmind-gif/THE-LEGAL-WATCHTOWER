;;;; systems/orchestrator-engine-sbcl/stages/source-normalize.lisp
;;;; SOURCE-NORMALIZE stage - ΩΜΕΓΑ GRADE
;;;;
;;;; Detects source type and normalizes source configuration
;;;; Writes canonical keys to context for downstream stages
;;;;
;;;; Responsibility:
;;;;   - Extract :type from :source-config
;;;;   - Validate source configuration
;;;;   - Write :source-type and :source-path to context
;;;;   - Deterministic, logged, fail-fast validation

(in-package :orchestrator.engine.sbcl)

(defun source-normalize-stage (context)
  "Detect and normalize source configuration - ΩΜΕΓΑ GRADE

   INPUT:
     context with :source-config or :sources or :pdf-path

   OUTPUT:
     context with canonical keys:
       :source-type   → keyword (:json, :pdf, :xml, :html, :markdown)
       :source-path   → string or pathname
       :source-count  → integer (for multi-source mode)

   ARCHITECTURE:
     - Pipeline planning depends on :source-type
     - Downstream stages use :source-type for skip decisions
     - No routing logic in parse stages (orthogonal stages)

   LOGGING:
     - Detected source type
     - Source path
     - Validation results"

  (handler-case
      (let* ((sources (orchestrator.core:get-context-value context :sources))
             (source-config (orchestrator.core:get-context-value context :source-config))
             (pdf-path (orchestrator.core:get-context-value context :pdf-path)))

        ;; Initialize canonical URI configuration from constitution.yaml.
        ;; orchestrator.spec:ensure-config-loaded loads the YAML into *loaded-config*.
        ;; orchestrator.uris:load-canonical-uris-from-config populates *canonical-config*
        ;; so that get-eli-const-prefix and friends work in downstream stages.
        (let ((yaml-config (orchestrator.spec:ensure-config-loaded)))
          (when yaml-config
            (orchestrator.uris:load-canonical-uris-from-config yaml-config)
            (log:info () "source-normalize: Canonical URIs initialized (base=~A)"
                      (orchestrator.uris:get-eli-const-prefix))))

        (cond
          ;; ================================================================
          ;; MULTI-SOURCE MODE
          ;; ================================================================
          (sources
           (log:info () "source-normalize: Multi-source mode detected (~D sources)" (length sources))

           ;; Validate all sources have :type and :path
           (loop for source in sources
                 for idx from 1
                 for type = (getf source :type)
                 for path = (getf source :path)
                 do (unless type
                      (error 'orchestrator.spec:config-error
                             :message (format nil "Source ~D missing :type" idx)
                             :config-key :type))
                    (unless path
                      (error 'orchestrator.spec:config-error
                             :message (format nil "Source ~D missing :path" idx)
                             :config-key :path))
                    (log:info () "source-normalize: Source ~D → type=~A path=~A" idx type path))

           ;; Write to context (multi-source mode deferred to sources directly)
           (orchestrator.core:set-context-value context :source-count (length sources))
           (log:info () "source-normalize: Multi-source validation complete"))

          ;; ================================================================
          ;; SINGLE-SOURCE MODE (with :source-config)
          ;; ================================================================
          (source-config
           (let ((type (getf source-config :type))
                 (path (getf source-config :path)))

             ;; HANDLE DEFERRED TYPE: paths resolved at runtime, with YAML config fallback.
             ;; Resolution order for json-path:
             ;;   1. :json-path in pipeline's source-config plist (explicit override)
             ;;   2. ORCHESTRATOR_JSON_PATH env var (handled inside get-runtime-source-config)
             ;;   3. source.json key in active corpus config YAML (corpus-specific default)
             (when (eq type :deferred)
               (log:info () "source-normalize: Deferred source config → detecting at runtime")
               (let* ((pdf-dir        (getf source-config :pdf-dir))
                      ;; Corpus-specific source document (never glob input/).
                      (pdf-path-config (orchestrator.spec:resolve-config-path "source.pdf"))
                      (json-path-config (or (getf source-config :json-path)
                                            (orchestrator.spec:resolve-config-path "source.json")))
                      (runtime-config (orchestrator.core:get-runtime-source-config
                                       :pdf-dir pdf-dir
                                       :pdf-path pdf-path-config
                                       :json-path json-path-config)))
                 (setf type (getf runtime-config :type))
                 (setf path (getf runtime-config :path))
                 (log:info () "source-normalize: Runtime detection → type=~A path=~A" type path)))

             ;; VALIDATION: type required
             (unless type
               (error 'orchestrator.spec:config-error
                      :message "Source configuration missing :type"
                      :config-key :type))

             ;; VALIDATION: type must be keyword
             (check-type type keyword)

             ;; ================================================================
             ;; AUTO MODE: PDF-first with JSON fallback
             ;; ================================================================
             (when (eq type :auto)
               (let ((pdf-path (getf source-config :pdf-path))
                     (json-path (getf source-config :json-path)))
                 (log:info () "source-normalize: AUTO mode - checking sources...")
                 (cond
                   ;; PDF exists → use it
                   ((and pdf-path (probe-file pdf-path))
                    (setf type :pdf)
                    (setf path pdf-path)
                    (log:info () "source-normalize: AUTO → PDF found at ~A" path))
                   ;; JSON fallback
                   ((and json-path (probe-file json-path))
                    (setf type :json)
                    (setf path json-path)
                    (log:info () "source-normalize: AUTO → PDF not found, using JSON fallback at ~A" path))
                   ;; Neither exists
                   (t
                    (error 'orchestrator.spec:config-error
                           :message (format nil "AUTO mode: Neither PDF (~A) nor JSON (~A) found"
                                           pdf-path json-path)
                           :config-key :source-config)))))

             ;; VALIDATION: path required (for non-auto, or after auto resolution)
             (unless path
               (error 'orchestrator.spec:config-error
                      :message "Source configuration missing :path"
                      :config-key :path))

             ;; VALIDATION: supported type (after auto resolution)
             (unless (member type '(:json :pdf :raw-text :docx :xml :html :markdown))
               (error 'orchestrator.spec:config-error
                      :message (format nil "Unsupported source type: ~A (must be :json, :pdf, :raw-text, :docx, :xml, :html, or :markdown)" type)
                      :config-key :type))

             ;; Log detection
             (log:info () "source-normalize: Detected source type → ~A" type)
             (log:info () "source-normalize: Source path → ~A" path)

             ;; Write canonical keys to context
             (orchestrator.core:set-context-value context :source-type type)
             (orchestrator.core:set-context-value context :source-path path)

             (log:info () "source-normalize: Normalization complete (type=~A)" type)))

          ;; ================================================================
          ;; LEGACY MODE (with :pdf-path)
          ;; ================================================================
          (pdf-path
           (log:info () "source-normalize: Legacy PDF mode detected")
           (log:info () "source-normalize: PDF path → ~A" pdf-path)

           ;; Write canonical keys
           (orchestrator.core:set-context-value context :source-type :pdf)
           (orchestrator.core:set-context-value context :source-path pdf-path)

           (log:info () "source-normalize: Legacy mode normalization complete"))

          ;; ================================================================
          ;; ERROR: No source configuration
          ;; ================================================================
          (t
           (error 'orchestrator.spec:config-error
                  :message "No source configuration provided. Use :sources, :source-config, or :pdf-path"
                  :config-key :source-config)))

        ;; Return context (executor pattern)
        context)

    (error (e)
      (log:error () "source-normalize-stage failed: ~A" e)
      (error e))))
