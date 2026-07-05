;;;; systems/orchestrator-core/instrumentation.lisp
;;;; Timing, logging, and performance instrumentation

(in-package :orchestrator.core)

;;; ============================================================================
;;; SIMPLE LOGGING (replacement for log4cl)
;;; ============================================================================

(defun log-info (format-string &rest args)
  "Log an info message"
  (format *trace-output* "~&[INFO] ~?~%" format-string args))

(defun log-error (format-string &rest args)
  "Log an error message"
  (format *error-output* "~&[ERROR] ~?~%" format-string args))

;;; ============================================================================
;;; INSTRUMENTATION MACRO
;;; ============================================================================

(defmacro with-instrumentation ((context label) &body body)
  "Execute body with timing and logging instrumentation
  
  Syntax:
    (with-instrumentation (ctx \"Operation Name\")
      ... body ...)
  
  Records start/end times and logs execution"
  (let ((start-var (gensym "START"))
        (result-var (gensym "RESULT"))
        (duration-var (gensym "DURATION")))
    `(let ((,start-var (get-internal-real-time)))
       (add-trace-entry ,context (format nil "Starting: ~A" ,label))
       (log-info "Starting: ~A" ,label)
       (let ((,result-var
              (handler-case
                  (progn ,@body)
                (error (e)
                  (let ((,duration-var (- (get-internal-real-time) ,start-var)))
                    (add-trace-entry ,context 
                                   (format nil "Failed: ~A" ,label)
                                   (list :duration ,duration-var
                                         :error (princ-to-string e)))
                    (log-error "Failed: ~A after ~,3F seconds: ~A" 
                             ,label
                             (/ ,duration-var internal-time-units-per-second)
                             e))
                  (error e)))))
         (let ((,duration-var (- (get-internal-real-time) ,start-var)))
           (add-trace-entry ,context 
                          (format nil "Completed: ~A" ,label)
                          (list :duration ,duration-var))
           (log-info "Completed: ~A in ~,3F seconds" 
                   ,label
                   (/ ,duration-var internal-time-units-per-second)))
         ,result-var))))

;;; ============================================================================
;;; PERFORMANCE METRICS
;;; ============================================================================

(defclass performance-metrics ()
  ((operation-name
    :accessor metrics-operation-name
    :initarg :operation-name
    :type string)
   (start-time
    :accessor metrics-start-time
    :initform (get-internal-real-time))
   (end-time
    :accessor metrics-end-time
    :initform nil)
   (duration
    :accessor metrics-duration
    :initform nil)
   (memory-before
    :accessor metrics-memory-before
    :initform nil)
   (memory-after
    :accessor metrics-memory-after
    :initform nil)
   (gc-runs-before
    :accessor metrics-gc-runs-before
    :initform nil)
   (gc-runs-after
    :accessor metrics-gc-runs-after
    :initform nil))
  (:documentation "Performance metrics for an operation"))

(defun start-metrics (operation-name)
  "Start collecting performance metrics
  
  Args:
    operation-name: Name of operation being measured
  
  Returns:
    Performance metrics instance"
  (let ((metrics (make-instance 'performance-metrics
                               :operation-name operation-name)))
    (setf (metrics-start-time metrics) (get-internal-real-time))
    #+sbcl
    (progn
      (setf (metrics-memory-before metrics)
            (sb-ext:get-bytes-consed))
      ;; gc-count may not be available in all SBCL versions
      (setf (metrics-gc-runs-before metrics) 0))
    metrics))

(defun end-metrics (metrics)
  "End performance metrics collection
  
  Args:
    metrics: Performance metrics instance
  
  Returns:
    Metrics with end time and duration"
  (setf (metrics-end-time metrics) (get-internal-real-time))
  (setf (metrics-duration metrics)
        (- (metrics-end-time metrics)
           (metrics-start-time metrics)))
  #+sbcl
  (progn
    (setf (metrics-memory-after metrics)
          (sb-ext:get-bytes-consed))
    ;; gc-count may not be available in all SBCL versions
    (setf (metrics-gc-runs-after metrics) 0))
  metrics)

(defun format-metrics (metrics)
  "Format performance metrics as plist
  
  Args:
    metrics: Performance metrics instance
  
  Returns:
    Plist with formatted metrics"
  (list :operation (metrics-operation-name metrics)
        :duration-seconds (when (metrics-duration metrics)
                           (/ (metrics-duration metrics)
                              internal-time-units-per-second))
        :memory-used (when (and (metrics-memory-before metrics)
                               (metrics-memory-after metrics))
                      (- (metrics-memory-after metrics)
                         (metrics-memory-before metrics)))
        :gc-runs (when (and (metrics-gc-runs-before metrics)
                           (metrics-gc-runs-after metrics))
                  (- (metrics-gc-runs-after metrics)
                     (metrics-gc-runs-before metrics)))))

;;; ============================================================================
;;; LOGGING UTILITIES
;;; ============================================================================

(defun log-stage-execution (stage-name status duration)
  "Log stage execution
  
  Args:
    stage-name: Name of stage
    status: :success or :failure
    duration: Duration in internal time units"
  (let ((seconds (/ duration internal-time-units-per-second)))
    (if (eq status :success)
        (log-info "Stage ~A completed successfully in ~,3F seconds" 
                 stage-name seconds)
        (log-error "Stage ~A failed after ~,3F seconds" 
                  stage-name seconds))))

(defun log-pipeline-summary (context)
  "Log pipeline execution summary
  
  Args:
    context: Pipeline context"
  (let ((metrics (get-pipeline-metrics context)))
    (log-info "Pipeline execution summary:")
    (log-info "  Total duration: ~,3F seconds" 
             (/ (getf metrics :total-duration) internal-time-units-per-second))
    (log-info "  Stages: ~D total, ~D succeeded, ~D failed"
             (getf metrics :stage-count)
             (getf metrics :success-count)
             (getf metrics :failure-count))
    (log-info "  Errors: ~D" (getf metrics :error-count))))

;;; ============================================================================
;;; PROFILING
;;; ============================================================================

#+sbcl
(defmacro with-profiling (&body body)
  "Execute body with SBCL statistical profiler
  
  Syntax:
    (with-profiling
      ... code to profile ...)
  
  Prints profiling report after execution"
  `(progn
     (sb-profile:profile)
     (unwind-protect
          (progn ,@body)
       (sb-profile:report)
       (sb-profile:unprofile))))

#-sbcl
(defmacro with-profiling (&body body)
  "Profiling not available on this implementation"
  `(progn ,@body))

;;; ============================================================================
;;; MEMORY TRACKING
;;; ============================================================================

#+sbcl
(defun current-memory-usage ()
  "Get current memory usage in bytes
  
  Returns:
    Memory usage in bytes"
  (sb-ext:get-bytes-consed))

#-sbcl
(defun current-memory-usage ()
  "Memory tracking not available on this implementation"
  0)

(defun format-bytes (bytes)
  "Format bytes as human-readable string
  
  Args:
    bytes: Number of bytes
  
  Returns:
    Formatted string (e.g., \"1.5 MB\")"
  (cond
    ((< bytes 1024) (format nil "~D B" bytes))
    ((< bytes (* 1024 1024)) (format nil "~,2F KB" (/ bytes 1024.0)))
    ((< bytes (* 1024 1024 1024)) (format nil "~,2F MB" (/ bytes 1024.0 1024.0)))
    (t (format nil "~,2F GB" (/ bytes 1024.0 1024.0 1024.0)))))
