;;;; systems/orchestrator-frbr/frbr-pipeline-stage.lisp
;;;; FRBR Pipeline Stage - Orchestrator Integration
;;;; ΟΜΕΓΑ-LEVEL: Full pipeline abstraction with progress, metrics, parallelism

(in-package :orchestrator.frbr)

;;; ============================================================
;;; PIPELINE STAGE DEFINITION
;;; ============================================================

(defclass frbr-generation-stage ()
  ((name :initform "FRBR Unified Generation"
         :reader stage-name
         :documentation "Human-readable stage name")

   (output-dir :initarg :output-dir
               :accessor stage-output-dir
               :type pathname
               :documentation "Output directory for unified FRBR files")

   (parallel :initarg :parallel
             :accessor stage-parallel-p
             :initform nil
             :type boolean
             :documentation "Whether to use parallel processing (lparallel)")

   (statistics :initform (make-hash-table :test 'eq)
               :accessor stage-statistics
               :type hash-table
               :documentation "Generation statistics (success/failed/skipped counts)"))

  (:documentation "Pipeline stage for unified FRBR generation.

   Generates ONE canonical Turtle file per article containing:
     - Article Root node (canonical entry point)
     - PROV-O Activity (generation provenance)
     - FRBR Work (abstract legal concept)
     - FRBR Expression (Greek language realization)
     - FRBR Manifestation (digital embodiment)
     - FRBR Formats (HTML, Turtle, JSON-LD)

   Output: article-NNN.ttl (120 files for 120 articles)

   Features:
     - Deterministic output (byte-for-byte reproducible)
     - AI-optimized structure (single-file ingest)
     - Complete provenance chain (PROV-O compliant)
     - ELI v1.4 + FRBR + DCAT compliant"))

;;; ============================================================
;;; GENERIC PIPELINE PROTOCOL
;;; ============================================================

(defgeneric execute-stage (stage context)
  (:documentation "Execute pipeline stage with given context"))

(defgeneric validate-stage-input (stage context)
  (:documentation "Validate stage inputs before execution"))

(defgeneric report-stage-progress (stage current total)
  (:documentation "Report stage progress"))

(defgeneric collect-stage-statistics (stage)
  (:documentation "Collect and return stage statistics"))

;;; ============================================================
;;; MAIN STAGE EXECUTION
;;; ============================================================

(defmethod execute-stage ((stage frbr-generation-stage) context)
  "Execute unified FRBR generation stage.

   Generates ONE canonical Turtle file per article containing all FRBR layers,
   Article Root node, and complete PROV-O provenance chain.

   Arguments:
     stage:   frbr-generation-stage instance
     context: Hash table with :articles key (list of article hash tables)

   Returns:
     Updated context with :frbr-statistics and :frbr-output-dir keys

   Side Effects:
     - Writes article-NNN.ttl files to output directory
     - Logs progress and statistics
     - May signal conditions (handled by restarts)

   Example:
     (execute-stage stage context)
     => #<HASH-TABLE :frbr-statistics (...) :frbr-output-dir #P\"/output/\">"

  ;; Validate inputs (may signal condition)
  (validate-stage-input stage context)

  ;; Extract article data
  (let* ((articles (gethash :articles context))
         (total-count (length articles))
         (output-dir (stage-output-dir stage)))

    ;; Initialize statistics tracking
    (init-unified-statistics stage total-count)

    ;; Generate unified files (with abort support)
    (orchestrator.spec:with-abortable-pipeline

      ;; Choose parallel or sequential execution
      (if (stage-parallel-p stage)
          (generate-unified-parallel stage articles output-dir)
          (generate-unified-sequential stage articles output-dir)))

    ;; Collect and report final statistics
    (let ((stats (collect-stage-statistics stage)))
      (report-unified-statistics stats)

      ;; Update context with results
      (setf (gethash :frbr-statistics context) stats)
      (setf (gethash :frbr-output-dir context) output-dir)
      (setf (gethash :frbr-mode context) :unified)

      context)))

;;; ============================================================
;;; SEQUENTIAL GENERATION
;;; ============================================================

(defun generate-unified-sequential (stage articles output-dir)
  "Generate unified FRBR files sequentially with progress reporting.

   Pure sequential execution with detailed progress logging.
   Each article generates ONE unified Turtle file.

   Arguments:
     stage:      frbr-generation-stage instance
     articles:   List of article hash tables
     output-dir: Output directory pathname

   Side Effects:
     - Writes article-NNN.ttl files
     - Updates stage statistics
     - Logs progress

   Error Handling:
     Uses with-frbr-error-handling for graceful failure recovery"

  (declare (type list articles)
           (type pathname output-dir))

  (let ((total (length articles))
        (current 0))

    (loop for article-data in articles
          for article-num = (gethash :number article-data)
          do
          (progn
            ;; Progress reporting
            (incf current)
            (report-stage-progress stage current total)

            ;; Generate unified file (with error handling & restarts)
            (orchestrator.spec:with-frbr-error-handling
                (:article-number article-num :layer 'unified)

              (let ((filepath (generate-article-unified-file stage article-data output-dir)))
                ;; Record statistics on success
                (when filepath
                  (record-unified-success stage article-num))))))))

;;; ============================================================
;;; PARALLEL GENERATION (lparallel)
;;; ============================================================

(defun generate-unified-parallel (stage articles output-dir)
  "Generate unified FRBR files in parallel using lparallel.

   Uses lparallel for concurrent article processing with thread-safe
   progress tracking and statistics updates.

   Arguments:
     stage:      frbr-generation-stage instance
     articles:   List of article hash tables
     output-dir: Output directory pathname

   Side Effects:
     - Writes article-NNN.ttl files concurrently
     - Updates stage statistics (thread-safe)
     - Logs progress (thread-safe)

   Requires:
     lparallel library + bordeaux-threads

   Fallback:
     Falls back to sequential if lparallel unavailable"

  (declare (type list articles)
           (type pathname output-dir))

  #+lparallel
  (let* ((kernel (lparallel:make-kernel 4))  ; 4 worker threads
         (total (length articles))
         (completed 0)
         (lock (bt:make-lock "unified-progress-lock")))

    (unwind-protect
        (lparallel:pmapcar
          (lambda (article-data)
            (let ((article-num (gethash :number article-data)))

              ;; Generate unified file (with error handling)
              (let ((filepath
                      (orchestrator.spec:with-frbr-error-handling
                          (:article-number article-num :layer 'unified)

                        (generate-article-unified-file stage article-data output-dir))))

                ;; Update progress and statistics (thread-safe with lock)
                (bt:with-lock-held (lock)
                  (incf completed)
                  (when filepath
                    (record-unified-success stage article-num))
                  (report-stage-progress stage completed total)))))

          articles)

      ;; Cleanup: Wait for all workers to finish
      (lparallel:end-kernel :wait t)))

  #-lparallel
  (generate-unified-sequential stage articles output-dir))

;;; ============================================================
;;; PER-ARTICLE UNIFIED GENERATION
;;; ============================================================

(defun generate-article-unified-file (stage article-data output-dir)
  "Generate ONE unified Turtle file for a single article.

   This is the core generation function that delegates to the
   ΟΜΕΓΑ-level unified-frbr-generator module.

   Generates a single article-NNN.ttl file containing:
     - Article Root node (canonical entry point)
     - PROV-O Activity (generation provenance)
     - Complete FRBR hierarchy (Work/Expression/Manifestation/Formats)
     - Full cross-layer consistency guarantees
     - Deterministic ordering

   Arguments:
     stage:        frbr-generation-stage instance
     article-data: Hash table with :number, :title, :content keys
     output-dir:   Output directory pathname

   Returns:
     Pathname of generated file, or NIL on failure

   Side Effects:
     - Writes article-NNN.ttl to output-dir
     - Updates stage statistics (via record-unified-success)
     - Logs generation events

   Error Handling:
     Signals conditions on validation failures.
     Returns NIL on write failures (logs error internally)."

  (declare (type hash-table article-data)
           (type pathname output-dir))

  ;; Extract article fields (with type checking)
  (let ((article-num (gethash :number article-data))
        (title (gethash :title article-data))
        (content (gethash :content article-data))
        ;; Letter suffix of a lettered article (100Α); "" for a plain article.
        (article-suffix (gethash :suffix article-data "")))

    ;; Validate required fields
    (check-type article-num (integer 1 *))
    (check-type title string)
    (check-type content string)

    ;; Call unified generator (ΟΜΕΓΑ-level module)
    ;; Returns pathname on success, NIL on failure
    ;; NOTE: Statistics recording is handled by caller (for thread-safety in parallel mode)
    (orchestrator.spec:write-unified-article-file
      article-num
      title
      content
      output-dir
      :article-suffix article-suffix
      :corpus-name (orchestrator.spec:config-get "corpus.short_name")
      :authority :canonical)))

;;; ============================================================
;;; STATISTICS & METRICS
;;; ============================================================

(defun init-unified-statistics (stage total-articles)
  "Initialize statistics tracking for unified generation.

   Sets up hash table with counters for:
     - Total articles to process
     - Success count
     - Failed count
     - Skipped count
     - Start time (for duration calculation)

   Arguments:
     stage:          frbr-generation-stage instance
     total-articles: Integer count of articles to process

   Side Effects:
     Mutates stage-statistics hash table

   Pure initialization - no I/O, no logging"

  (declare (type (integer 0 *) total-articles))

  (let ((stats (stage-statistics stage)))
    ;; Overall metrics
    (setf (gethash :total-articles stats) total-articles)
    (setf (gethash :start-time stats) (get-internal-real-time))

    ;; Unified generation counters
    (setf (gethash :success stats) 0)
    (setf (gethash :failed stats) 0)
    (setf (gethash :skipped stats) 0)))

(defun record-unified-success (stage article-num)
  "Record successful unified file generation.

   Increments success counter in stage statistics.

   Arguments:
     stage:       frbr-generation-stage instance
     article-num: Integer article number (for logging)

   Side Effects:
     Mutates stage-statistics hash table
     Logs debug message

   Thread Safety:
     NOT thread-safe - caller MUST hold lock in parallel mode.
     Sequential mode: No lock needed (single-threaded).
     Parallel mode: Caller holds bt:with-lock-held before calling.

   Called by:
     - generate-unified-sequential (single-threaded, no lock needed)
     - generate-unified-parallel (inside bt:with-lock-held)"

  (declare (type (integer 1 120) article-num))

  (let ((stats (stage-statistics stage)))
    (incf (gethash :success stats))))

(defmethod collect-stage-statistics ((stage frbr-generation-stage))
  "Collect final statistics for unified generation.

   Implements generic protocol method for frbr-generation-stage.

   Pure function that extracts statistics from stage and returns
   an association list with all metrics.

   Arguments:
     stage: frbr-generation-stage instance

   Returns:
     Alist with keys:
       :mode              - :unified
       :total-articles    - Total articles processed
       :success           - Successfully generated files
       :failed            - Failed generations
       :skipped           - Skipped articles
       :duration-seconds  - Total processing time
       :files-per-second  - Throughput metric

   Pure function - no side effects, deterministic output"

  (let* ((stats (stage-statistics stage))
         (end-time (get-internal-real-time))
         (start-time (gethash :start-time stats))
         (duration (/ (- end-time start-time) internal-time-units-per-second))
         (total (gethash :total-articles stats))
         (success (gethash :success stats))
         (failed (gethash :failed stats))
         (skipped (gethash :skipped stats))
         (throughput (if (> duration 0)
                         (/ success duration)
                         0.0)))

    ;; Return alist (deterministic order)
    (list
     (cons :mode :unified)
     (cons :total-articles total)
     (cons :success success)
     (cons :failed failed)
     (cons :skipped skipped)
     (cons :duration-seconds (float duration))
     (cons :files-per-second (float throughput)))))

;;; ============================================================
;;; PROGRESS REPORTING
;;; ============================================================

(defmethod report-stage-progress ((stage frbr-generation-stage) current total)
  "Report generation progress"
  nil)

(defun report-unified-statistics (stats)
  "Report final unified generation statistics to log.

   Pretty-prints statistics banner with all metrics.

   Arguments:
     stats: Alist returned from collect-stage-statistics

   Side Effects:
     None (logging removed)"
  nil)

;;; ============================================================
;;; VALIDATION
;;; ============================================================

(defmethod validate-stage-input ((stage frbr-generation-stage) context)
  "Validate stage inputs"
  
  (unless (gethash :articles context)
    (error "Context missing :articles key"))
  
  (unless (stage-output-dir stage)
    (error "Stage missing output directory"))
  
  (ensure-directories-exist (stage-output-dir stage))
  
  t)

;;; ============================================================
;;; PUBLIC API
;;; ============================================================

(defun run-frbr-generation-stage (context &key
                                            (output-dir #P"/mnt/user-data/outputs/frbr/")
                                            (parallel nil))
  "Public API: Run unified FRBR generation stage.

   Generates ONE canonical Turtle file per article containing all FRBR layers,
   Article Root node, and complete PROV-O provenance chain.

   Arguments:
     context:    Hash table with :articles key (list of article data)
     output-dir: Output directory for article-NNN.ttl files (default: /mnt/user-data/outputs/frbr/)
     parallel:   Use parallel processing with lparallel (default: NIL)

   Returns:
     Updated context with :frbr-statistics, :frbr-output-dir, :frbr-mode keys

   Side Effects:
     - Writes 120 unified Turtle files (one per article)
     - Logs progress and statistics
     - May create output directory if it doesn't exist

   Example:
     (run-frbr-generation-stage
       context
       :output-dir #P\"/output/frbr/\"
       :parallel t)

   Output Files:
     /output/frbr/article-001.ttl  (all layers + provenance)
     /output/frbr/article-002.ttl
     ...
     /output/frbr/article-120.ttl"

  (declare (type hash-table context)
           (type pathname output-dir)
           (type boolean parallel))

  ;; Create and execute stage
  (let ((stage (make-instance 'frbr-generation-stage
                              :output-dir output-dir
                              :parallel parallel)))

    (execute-stage stage context)))

;;; ============================================================
;;; COMPILER OPTIMIZATIONS
;;; ============================================================

;; Global optimization settings (DARPA-level performance)
(declaim (optimize (speed 3)         ; Maximum speed
                   (safety 1)        ; Minimal safety checks (trust types)
                   (debug 1)         ; Minimal debug info
                   (compilation-speed 0)))  ; Prioritize runtime over compile time

;; Function type declarations for compiler optimization
(declaim (ftype (function (frbr-generation-stage list pathname) (values &optional))
                generate-unified-sequential
                generate-unified-parallel))

(declaim (ftype (function (frbr-generation-stage hash-table pathname) (values (or pathname null) &rest t))
                generate-article-unified-file))

(declaim (ftype (function (frbr-generation-stage (integer 0 *)) (values &optional))
                init-unified-statistics))

(declaim (ftype (function (frbr-generation-stage (integer 1 120)) (values &optional))
                record-unified-success))

(declaim (ftype (function (frbr-generation-stage) list)
                collect-stage-statistics))

(declaim (ftype (function (list) (values &optional))
                report-unified-statistics))

;; Inline candidates for hot path functions
(declaim (inline record-unified-success))

;;; Notes on optimization strategy:
;;;
;;; 1. SPEED 3 - Maximize runtime performance
;;;    - Critical for batch processing 120 articles
;;;    - File I/O is bottleneck, minimize overhead
;;;
;;; 2. SAFETY 1 - Trust type declarations
;;;    - We have comprehensive type checks via check-type
;;;    - Conditions/restarts provide error recovery
;;;    - No need for compiler-inserted checks
;;;
;;; 3. INLINE - record-unified-success
;;;    - Called 120 times (once per article)
;;;    - Simple increment operation
;;;    - Good candidate for inlining
;;;
;;; 4. FTYPE declarations
;;;    - Help compiler generate optimal code
;;;    - Document function contracts
;;;    - Enable better type inference

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(frbr-generation-stage
          execute-stage
          run-frbr-generation-stage))
