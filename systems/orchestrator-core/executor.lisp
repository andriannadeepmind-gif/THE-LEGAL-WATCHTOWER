;;;; systems/orchestrator-core/executor.lisp
;;;; Sequential pipeline executor

(in-package :orchestrator.core)

;;; ============================================================================
;;; MODE DETECTION (DARPA-grade deterministic)
;;; ============================================================================

(defun detect-executor-mode ()
  "Detect if running in interactive or production mode

  Returns: :interactive or :production

  Decision tree:
  1. Check ORCHESTRATOR_MODE env var (explicit override)
  2. Check for REPL/editor features (Swank/Slynk)
  3. Default to :production (safe default)"
  (let ((env-mode (uiop:getenv "ORCHESTRATOR_MODE")))
    (cond
      ;; Explicit env var override
      ((and env-mode (string-equal env-mode "interactive"))
       :interactive)

      ;; REPL/editor detection (SLIME/Sly)
      ((or (find :swank *features*)
           (find-package :swank)
           (find-package :slynk))
       :interactive)

      ;; Default to production (DARPA safe default)
      (t :production))))

;;; ============================================================================
;;; SEQUENTIAL EXECUTOR
;;; ============================================================================

(defclass sequential-executor ()
  ((max-retries
    :accessor executor-max-retries
    :initarg :max-retries
    :initform 3
    :type integer
    :documentation "Maximum retries per stage")
   (mode
    :accessor executor-mode
    :initarg :mode
    :initform nil
    :type (or null (member :interactive :production))
    :documentation "Execution mode: :interactive (REPL) or :production (CI/Docker)"))
  (:documentation "Sequential pipeline executor"))

(defmethod initialize-instance :after ((executor sequential-executor) &key)
  "Initialize executor mode if not explicitly set"
  (unless (executor-mode executor)
    (setf (executor-mode executor) (detect-executor-mode)))
  (log:info () "EXECUTOR-MODE: ~A" (executor-mode executor)))

(defmethod orchestrator.spec:run-pipeline ((pipeline orchestrator.spec:pipeline)
                                           (context pipeline-context))
  "Execute pipeline sequentially"
  (let ((executor (make-instance 'sequential-executor
                                :max-retries (or (getf (context-config context) :max-retries) 3))))
    (execute-pipeline executor pipeline context)))

(defmethod execute-pipeline ((executor sequential-executor) pipeline context)
  "Execute pipeline using sequential executor
  
  Args:
    executor: Sequential executor instance
    pipeline: Pipeline to execute
    context: Execution context
  
  Returns:
    Context with results"
  (add-trace-entry context "Starting pipeline execution" 
                  (list :pipeline (orchestrator.spec:pipeline-name pipeline)))
  
  ;; Build dependency graph and get execution order
  (let* ((graph (build-dependency-graph pipeline))
         (order (execution-order graph))
         (stages (orchestrator.spec:pipeline-stages pipeline)))
    
    (add-trace-entry context "Execution order determined" 
                    (list :order order))
    
    ;; Execute stages in order
    (dolist (stage-name order)
      (let ((stage (find stage-name stages
                        :key #'orchestrator.spec:stage-name)))
        (when stage
          (handler-case
              (execute-stage executor stage context)

            (error (e)
              (record-error context
                          (list :stage stage-name
                                :error e
                                :timestamp (orchestrator.time:now :source :system)))
              (add-trace-entry context "Stage failed"
                             (list :stage stage-name :error (princ-to-string e)))

              ;; DARPA CONTROL FLOW: mode-gated error handling
              (ecase (executor-mode executor)
                (:production
                 ;; Production: NO restarts, immediate propagation
                 ;; Single choke point - error MUST reach top-level
                 (log:error () "Stage ~A failed in PRODUCTION mode - propagating error" stage-name)
                 (error e))

                (:interactive
                 ;; Interactive: restarts available for debugging
                 (restart-case
                     (error 'orchestrator.spec:stage-error
                            :message (format nil "Stage ~A failed: ~A" stage-name e)
                            :stage-name stage-name)
                   (skip-article ()
                     :report "Skip this article and continue"
                     (add-trace-entry context "Skipping article"
                                    (list :stage stage-name)))
                   (mark-degraded-and-continue ()
                     :report "Mark as degraded and continue"
                     (add-trace-entry context "Marked degraded"
                                    (list :stage stage-name)))
                   (abort-pipeline ()
                     :report "Abort entire pipeline"
                     (add-trace-entry context "Pipeline aborted"
                                    (list :stage stage-name))
                     (return-from execute-pipeline context))))))))))
    
    (add-trace-entry context "Pipeline execution completed")
    context))


(defmethod execute-stage ((executor sequential-executor) stage context)
  "Execute a single stage with retries
  
  Args:
    executor: Sequential executor instance
    stage: Stage to execute
    context: Execution context
  
  Returns:
    Stage result"
  (let ((stage-name (orchestrator.spec:stage-name stage))
        (stage-fn (orchestrator.spec:stage-function stage))
        (retry-count 0)
        (max-retries (executor-max-retries executor)))
    
    (add-trace-entry context "Starting stage" 
                    (list :stage stage-name))
    (record-stage-start context stage-name)
    
    (loop
      (handler-case
          (progn
            ;; Execute stage function
            (let ((result (funcall stage-fn context)))
              (record-stage-end context stage-name :success)
              (add-trace-entry context "Stage completed"
                             (list :stage stage-name))
              (return result)))

        ;; DARPA CONTROL FLOW: validation-error MUST NOT retry
        ;; Immediate propagation (no retry, no restarts)
        (orchestrator.spec:validation-error (e)
          (record-stage-end context stage-name :failure)
          (add-trace-entry context "VALIDATION FAILURE - NO RETRY"
                         (list :stage stage-name :error (princ-to-string e)))
          (error e))

        (error (e)
          (incf retry-count)

          ;; DARPA CONTROL FLOW: mode-gated retry logic (generic errors only)
          (if (< retry-count max-retries)
              (progn
                (add-trace-entry context "Stage failed, retrying"
                               (list :stage stage-name
                                     :retry retry-count
                                     :error (princ-to-string e)))

                (ecase (executor-mode executor)
                  (:production
                   ;; Production: retry WITHOUT restarts
                   (log:warn () "Stage ~A failed (attempt ~D/~D) - retrying in production mode"
                             stage-name retry-count max-retries))

                  (:interactive
                   ;; Interactive: retry WITH restarts
                   (restart-case
                       (error e)
                     (retry-stage (&optional new-config)
                       :report "Retry the stage"
                       (when new-config
                         (setf (context-config context) new-config)))
                     (retry-with-backoff (wait-seconds)
                       :report "Retry after waiting"
                       (sleep wait-seconds))))))

              ;; Max retries exhausted - fail
              (progn
                (record-stage-end context stage-name :failure)
                (error e))))))))


(defmethod orchestrator.spec:run-stage ((stage orchestrator.spec:stage)
                                        (context pipeline-context))
  "Run a single stage (convenience method)"
  (let ((executor (make-instance 'sequential-executor)))
    (execute-stage executor stage context)))

;;; ============================================================================
;;; INSTRUMENTATION HOOKS
;;; ============================================================================

(defun record-stage-start (context stage-name)
  "Record stage start time
  
  Args:
    context: Pipeline context
    stage-name: Name of stage
  
  Returns:
    NIL"
  (let ((metrics (gethash stage-name (context-stage-metrics context))))
    (unless metrics
      (setf metrics (list :start-time (get-internal-real-time)
                         :attempts 0)
            (gethash stage-name (context-stage-metrics context)) metrics))
    (incf (getf metrics :attempts))
    (setf (getf metrics :start-time) (get-internal-real-time)))
  nil)

(defun record-stage-end (context stage-name status)
  "Record stage end time and status
  
  Args:
    context: Pipeline context
    stage-name: Name of stage
    status: :success or :failure
  
  Returns:
    NIL"
  (let ((metrics (gethash stage-name (context-stage-metrics context))))
    (when metrics
      (setf (getf metrics :end-time) (get-internal-real-time))
      (setf (getf metrics :duration)
            (- (getf metrics :end-time)
               (getf metrics :start-time)))
      (setf (getf metrics :status) status)))
  nil)

(defun get-stage-metrics (context stage-name)
  "Get metrics for a stage
  
  Args:
    context: Pipeline context
    stage-name: Name of stage
  
  Returns:
    Metrics plist or NIL"
  (gethash stage-name (context-stage-metrics context)))

(defun get-pipeline-metrics (context)
  "Get metrics for entire pipeline
  
  Args:
    context: Pipeline context
  
  Returns:
    Plist with pipeline metrics"
  (let ((total-duration (- (get-internal-real-time)
                          (context-start-time context)))
        (stage-metrics (context-stage-metrics context))
        (stage-count 0)
        (success-count 0)
        (failure-count 0))
    
    (maphash (lambda (stage-name metrics)
              (declare (ignore stage-name))
              (incf stage-count)
              (case (getf metrics :status)
                (:success (incf success-count))
                (:failure (incf failure-count))))
            stage-metrics)
    
    (list :total-duration total-duration
          :stage-count stage-count
          :success-count success-count
          :failure-count failure-count
          :error-count (length (context-errors context)))))
