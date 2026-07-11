;;;; systems/orchestrator-cli/commands.lisp
;;;; CLI commands with maximum CL expressiveness

(in-package :orchestrator.cli)

;;; ============================================================================
;;; FULL BUILD COMMAND
;;; ============================================================================

(defun run-full-build (&key config-path corpus-name)
  "Run full pipeline build
  
  Args:
    config-path: Path to config file
    corpus-name: Corpus to process (defaults to :gr-syntagma)
  
  Returns:
    Exit code (0 for success)"
  (let* ((config (when config-path (load-config config-path)))
         (corpus (orchestrator.meta:get-corpus (or corpus-name :gr-syntagma)))
         (pipeline (orchestrator.meta:get-pipeline :greek-constitution-pipeline))
         (context (orchestrator.core:make-pipeline-context
                   :pipeline pipeline
                   :config config)))
    
    (orchestrator.core:set-context-value context :corpus corpus)
    
    (format t "~&[INFO] Running full build for corpus: ~A~%" corpus-name)
    
    (handler-case
        (progn
          (orchestrator.spec:run-pipeline pipeline context)
          (format t "~&[INFO] Build completed successfully~%")
          0)
      (error (e)
        (format t "~&[ERROR] Build failed: ~A~%" e)
        1))))

;;; ============================================================================
;;; FULL BUILD + AI EXPORT COMMAND
;;; ============================================================================

(defun run-full-build-ai (&key
                           config-path
                           (corpus-name :gr-syntagma)
                           (output-dir #p"outputs-final/")
                           (deterministic nil)
                           (timestamp-override nil)
                           ai-config-path
                           ai-config)
  "Run full corpus build + AI exports (manifest + provenance).
   This is the unified command for deterministic, research-grade output.
  
  Args:
    config-path: Path to main config file (YAML)
    corpus-name: Corpus to process (defaults to :gr-syntagma)
    output-dir: Base output directory (default: outputs-final/)
    deterministic: Use deterministic timestamps (default: NIL)
    timestamp-override: Specific timestamp for deterministic builds
    ai-config-path: Path to AI-specific config YAML (optional)
    ai-config: Pre-loaded AI config object (optional)
  
  Returns:
    Plist with :exit-code, :manifest-path, :provenance-files, :stats"
  
  (let ((*package* (find-package :orchestrator.cli)))
    
    ;; Load or construct AI configuration
    (let ((effective-ai-config
           (cond
             ;; Use provided AI config object
             (ai-config ai-config)
             
             ;; Load from AI config file
             (ai-config-path 
              (orchestrator.ai-core:load-ai-config-from-yaml ai-config-path))
             
             ;; Try to extract from main config
             (config-path
              (let ((main-config (load-config config-path)))
                (orchestrator.ai-core:parse-ai-config-from-plist main-config)))
             
             ;; Create default config with CLI overrides
             (t 
              (orchestrator.ai-core:make-ai-export-config
               :output-root (merge-pathnames "ai/" output-dir)
               :deterministic deterministic
               :fixed-timestamp timestamp-override)))))
      
      ;; Apply deterministic overrides from CLI (take precedence over config file)
      (when deterministic
        (setf (orchestrator.ai-core:config-deterministic effective-ai-config) t))
      (when timestamp-override
        (setf (orchestrator.ai-core:config-fixed-timestamp effective-ai-config) 
              timestamp-override))
      
      ;; Set up deterministic mode if requested — χρόνος ΜΟΝΟ από δηλωμένη
      ;; αρχή (ρητό fixed-timestamp ή SOURCE_DATE_EPOCH), ποτέ μαγικός αριθμός.
      (when (orchestrator.ai-core:config-deterministic effective-ai-config)
        (setf orchestrator.ai-core:*build-timestamp-override*
              (orchestrator.ai-core:effective-deterministic-timestamp effective-ai-config)))
      
      (handler-case
          (progn
            (log:info () "═══════════════════════════════════════════════════════")
            (log:info () "FULL BUILD + AI EXPORT")
            (log:info () "Corpus: ~A" corpus-name)
            (log:info () "Deterministic: ~A" (orchestrator.ai-core:config-deterministic effective-ai-config))
            (log:info () "Output Root: ~A" (orchestrator.ai-core:config-output-root effective-ai-config))
            (log:info () "Dataset: ~A v~A" 
                     (orchestrator.ai-core:config-dataset-name effective-ai-config)
                     (orchestrator.ai-core:config-dataset-version effective-ai-config))
            (log:info () "═══════════════════════════════════════════════════════")
            
            ;; PHASE 1: Run full corpus build
            (log:info () "PHASE 1: Running corpus build...")
            (let ((build-result (run-full-build :config-path config-path
                                               :corpus-name corpus-name)))
              (unless (zerop build-result)
                (error "Corpus build failed with exit code ~A" build-result)))
            
            ;; Get corpus object
            (let ((corpus (orchestrator.meta:get-corpus corpus-name)))
              (unless corpus
                (error "Corpus not found: ~A" corpus-name))
              
              ;; PHASE 2: Generate AI ingest manifest with config
              (log:info () "PHASE 2: Generating AI ingest manifest...")
              (let ((actual-manifest-path
                     (orchestrator.ai-core:write-ai-ingest-manifest-with-config
                      corpus
                      effective-ai-config)))
                
                (log:info () "  ✓ Manifest written to: ~A" actual-manifest-path)
                
                ;; Validate manifest
                (multiple-value-bind (valid errors total)
                    (orchestrator.ai-core:validate-manifest actual-manifest-path)
                  (if valid
                      (log:info () "  ✓ Manifest validation passed (~D entries)" total)
                      (log:warn () "  ⚠ Manifest has errors in lines: ~A" errors)))
                
                ;; PHASE 3: Generate per-article provenance with config
                (log:info () "PHASE 3: Generating article provenance files...")
                (let ((provenance-files
                       (orchestrator.ai-core:write-corpus-provenance-with-config
                        corpus
                        effective-ai-config)))
                  
                  (log:info () "  ✓ Generated ~D provenance files" (length provenance-files))
                  
                  ;; PHASE 4: Generate statistics
                  (log:info () "PHASE 4: Computing statistics...")
                  (let ((stats (orchestrator.ai-core:manifest-stats actual-manifest-path)))
                    (log:info () "  Articles: ~D total, ~D anchored, ~D live (~,1F% complete)"
                             (getf stats :total)
                             (getf stats :anchored)
                             (getf stats :live)
                             (getf stats :completion-percentage))
                    
                    ;; Success!
                    (log:info () "═══════════════════════════════════════════════════════")
                    (log:info () "✓ FULL BUILD + AI EXPORT COMPLETED SUCCESSFULLY")
                    (log:info () "═══════════════════════════════════════════════════════")
                    
                    ;; Return comprehensive result
                    `(:exit-code 0
                      :corpus ,corpus-name
                      :manifest-path ,actual-manifest-path
                      :provenance-directory ,(orchestrator.ai-core:config-output-root effective-ai-config)
                      :provenance-files ,(length provenance-files)
                      :stats ,stats
                      :ai-config (,:dataset-name ,(orchestrator.ai-core:config-dataset-name effective-ai-config)
                                  :dataset-version ,(orchestrator.ai-core:config-dataset-version effective-ai-config)
                                  :publisher ,(orchestrator.ai-core:config-publisher effective-ai-config))
                      :deterministic ,(orchestrator.ai-core:config-deterministic effective-ai-config)))))))
        
        ;; Error handling with restarts
        (error (e)
          (log:error () "═══════════════════════════════════════════════════════")
          (log:error () "✗ FULL BUILD + AI EXPORT FAILED")
          (log:error () "Error: ~A" e)
          (log:error () "═══════════════════════════════════════════════════════")
          
          `(:exit-code 1
            :error ,(format nil "~A" e)))))))

;;; ============================================================================
;;; AI-ONLY EXPORT COMMAND (skips corpus build)
;;; ============================================================================

(defun run-ai-export-only (&key
                            (corpus-name :gr-syntagma)
                            config-path
                            ai-config-path
                            (deterministic nil)
                            (timestamp-override nil))
  "Run AI export only (no corpus build).
   Useful when corpus is already built and you want to regenerate AI exports.
  
  Args:
    corpus-name: Corpus to export
    config-path: Path to main config with ai_export section
    ai-config-path: Path to dedicated AI config file
    deterministic: Use deterministic timestamps
    timestamp-override: Specific timestamp for deterministic builds
  
  Returns:
    Plist with export results"
  
  ;; Load configuration
  (let ((ai-config
         (cond
           (ai-config-path 
            (orchestrator.ai-core:load-ai-config-from-yaml ai-config-path))
           (config-path
            (orchestrator.ai-core:parse-ai-config-from-plist
             (load-config config-path)))
           (t
            (orchestrator.ai-core:make-default-ai-export-config)))))
    
    ;; Apply overrides
    (when deterministic
      (setf (orchestrator.ai-core:config-deterministic ai-config) t))
    (when timestamp-override
      (setf (orchestrator.ai-core:config-fixed-timestamp ai-config) timestamp-override))
    
    ;; Apply deterministic mode — χρόνος ΜΟΝΟ από δηλωμένη αρχή.
    (when (orchestrator.ai-core:config-deterministic ai-config)
      (setf orchestrator.ai-core:*build-timestamp-override*
            (orchestrator.ai-core:effective-deterministic-timestamp ai-config)))
    
    ;; Get corpus
    (let ((corpus (orchestrator.meta:get-corpus corpus-name)))
      (unless corpus
        (return-from run-ai-export-only
          `(:exit-code 1 :error ,(format nil "Corpus not found: ~A" corpus-name))))
      
      ;; Generate manifest
      (log:info () "[AI-Export] Generating manifest for ~A..." corpus-name)
      (let ((manifest-path
             (orchestrator.ai-core:write-ai-ingest-manifest-with-config corpus ai-config)))
        
        ;; Generate provenance
        (log:info () "[AI-Export] Generating provenance files...")
        (let ((provenance-files
               (orchestrator.ai-core:write-corpus-provenance-with-config corpus ai-config)))
          
          ;; Stats
          (let ((stats (orchestrator.ai-core:manifest-stats manifest-path)))
            (log:info () "[AI-Export] Complete: ~D articles, ~D anchored"
                     (getf stats :total)
                     (getf stats :anchored))
            
            `(:exit-code 0
              :corpus ,corpus-name
              :manifest-path ,manifest-path
              :provenance-files ,(length provenance-files)
              :stats ,stats)))))))

;;; ============================================================================
;;; VALIDATION COMMANDS
;;; ============================================================================

(defun validate-pipeline (pipeline-name)
  "Validate pipeline structure
  
  Args:
    pipeline-name: Pipeline name
  
  Returns:
    T if valid"
  (let ((pipeline (orchestrator.meta:get-pipeline pipeline-name)))
    (if pipeline
        (orchestrator.spec:validate-pipeline pipeline)
        (error "Pipeline not found: ~A" pipeline-name))))

;;; ============================================================================
;;; REPORT GENERATION
;;; ============================================================================

(defun generate-report (pipeline-name output-path)
  "Generate pipeline report
  
  Args:
    pipeline-name: Pipeline name
    output-path: Output file path
  
  Returns:
    Output path"
  (let* ((pipeline (orchestrator.meta:get-pipeline pipeline-name))
         (context (orchestrator.core:make-pipeline-context :pipeline pipeline))
         (report (orchestrator.meta:generate-json-report pipeline context)))
    (alexandria:write-string-into-file report output-path
                                       :if-exists :supersede)
    output-path))
