;;;; logging.lisp
;;;; Structured JSON logging with correlation IDs and context management

(defpackage #:orchestrator.logging
  (:use :cl :alexandria :local-time)
  (:shadow #:warn #:error #:debug #:trace)
  (:export #:log-event
           #:with-log-context
           #:set-log-level
           #:get-log-level           ; NEW: For testing
           #:get-correlation-id
           #:*correlation-id*
           #:*log-context*
           #:initialize-logging
           #:log-info
           #:log-warn
           #:log-error
           #:log-debug
           #:log-trace
           ;; Short aliases for convenience
           #:info
           #:warn
           #:error
           #:debug
           #:trace))

(in-package :orchestrator.logging)

;;;; ========================================================================
;;;; CONSTANTS
;;;; ========================================================================

(defconstant +default-log-level+ :info
  "Default logging level")

(defconstant +max-correlation-id-length+ 50
  "Maximum length of correlation ID")

(defconstant +log-buffer-size+ 1024
  "Size of log buffer in bytes")

;;;; ========================================================================
;;;; GLOBAL STATE
;;;; ========================================================================

(defvar *correlation-id* nil
  "Current correlation ID for request tracing")

(defvar *log-context* nil
  "Current logging context (alist of key-value pairs)")

(defvar *log-level* :info
  "Current log level")

(defvar *log-output* *standard-output*
  "Output stream for logs")

(defparameter *log-levels*
  '(:trace 0 :debug 1 :info 2 :warn 3 :error 4 :fatal 5)
  "Log level hierarchy")

;;;; ========================================================================
;;;; CORRELATION ID MANAGEMENT
;;;; ========================================================================

(defun generate-correlation-id ()
  "Generate a unique correlation ID.

   DARPA-GRADE: Uses CSPRNG instead of weak cl:random.
   Predictable correlation IDs could allow request trace forgery."
  (declare (optimize (speed 3) (safety 1)))
  (format nil "~A-~A"
          (orchestrator.time:get-unix-timestamp)
          (ironclad:byte-array-to-hex-string (ironclad:random-data 8))))

(defun get-correlation-id ()
  "Get or create current correlation ID"
  (declare (optimize (speed 3) (safety 1)))
  (or *correlation-id* 
      (setf *correlation-id* (generate-correlation-id))))

;;;; ========================================================================
;;;; LOG LEVEL MANAGEMENT
;;;; ========================================================================

(defun set-log-level (level)
  "Set global log level"
  (declare (type symbol level))
  (declare (optimize (speed 3) (safety 1)))
  (assert (member level '(:trace :debug :info :warn :error :fatal)))
  (check-type level symbol)
  (setf *log-level* level))

(defun get-log-level ()
  "Get current log level"
  (declare (optimize (speed 3) (safety 1)))
  *log-level*)

(defun log-level-value (level)
  "Get numeric value for log level"
  (declare (type symbol level))
  (declare (optimize (speed 3) (safety 1)))
  (getf *log-levels* level 0))

(defun should-log-p (level)
  "Check if message at given level should be logged"
  (declare (type symbol level))
  (declare (optimize (speed 3) (safety 1)))
  (>= (log-level-value level) 
      (log-level-value *log-level*)))

;;;; ========================================================================
;;;; CONTEXT MANAGEMENT
;;;; ========================================================================

(defmacro with-log-context (bindings &body body)
  "Execute body with additional logging context"
  `(let ((*log-context* (append (list ,@(loop for (k v) in bindings
                                              collect `(cons ,k ,v)))
                                *log-context*))
         (*correlation-id* (or *correlation-id* (generate-correlation-id))))
     ,@body))

;;;; ========================================================================
;;;; CORE LOGGING
;;;; ========================================================================

(defun format-log-entry (level message &key error context)
  "Format log entry as JSON"
  (let* ((timestamp (orchestrator.time:get-iso8601-timestamp))
         (entry (list (cons "timestamp" timestamp)
                     (cons "level" (string-downcase (symbol-name level)))
                     (cons "message" message)
                     (cons "correlation_id" (get-correlation-id)))))
    
    ;; Add context
    (when *log-context*
      (setf entry (append entry *log-context*)))
    
    ;; Add additional context
    (when context
      (setf entry (append entry context)))
    
    ;; Add error details if present
    (when error
      (setf entry (append entry 
                         (list (cons "error_type" (type-of error))
                               (cons "error_message" (princ-to-string error))))))
    
    ;; Convert to JSON-like format
    (format nil "{~{~A~^, ~}}"
            (mapcar (lambda (pair)
                      (format nil "\"~A\": ~S" 
                              (if (stringp (car pair))
                                  (car pair)
                                  (string-downcase (symbol-name (car pair))))
                              (cdr pair)))
                    entry))))

(defun log-event (level message &key error context)
  "Log an event at specified level"
  (declare (type symbol level))
  (declare (type string message))
  (declare (optimize (speed 3) (safety 1)))
  (check-type level symbol)
  (check-type message string)
  (when (should-log-p level)
    (let ((entry (format-log-entry level message 
                                   :error error 
                                   :context context)))
      (format *log-output* "~A~%" entry)
      (force-output *log-output*)
      entry)))

;;;; ========================================================================
;;;; CONVENIENCE FUNCTIONS
;;;; ========================================================================

(defun log-trace (message &rest args)
  "Log at TRACE level"
  (declare (type string message))
  (declare (optimize (speed 3) (safety 1)))
  (log-event :trace (apply #'format nil message args)))

(defun log-debug (message &rest args)
  "Log at DEBUG level"
  (declare (type string message))
  (declare (optimize (speed 3) (safety 1)))
  (log-event :debug (apply #'format nil message args)))

(defun log-info (message &rest args)
  "Log at INFO level"
  (declare (type string message))
  (declare (optimize (speed 3) (safety 1)))
  (log-event :info (apply #'format nil message args)))

(defun log-warn (message &rest args)
  "Log at WARN level"
  (declare (type string message))
  (declare (optimize (speed 3) (safety 1)))
  (log-event :warn (apply #'format nil message args)))

(defun log-error (message &key error &allow-other-keys)
  "Log at ERROR level with optional error object"
  (declare (type string message))
  (declare (optimize (speed 3) (safety 1)))
  (log-event :error message :error error))

;;;; ========================================================================
;;;; INITIALIZATION
;;;; ========================================================================

(defun initialize-logging (&key (level :info) (output *standard-output*))
  "Initialize logging system"
  (declare (type symbol level))
  (declare (type stream output))
  (declare (optimize (speed 3) (safety 1)))
  (check-type level symbol)
  (check-type output stream)
  (setf *log-level* level
        *log-output* output)
  (log-info "Logging initialized at level ~A" level))

;; Initialize with defaults
(initialize-logging)

;;;; ========================================================================
;;;; SHORT ALIASES
;;;; ========================================================================

;; Provide short aliases for convenience (info, warn, error, debug, trace)
;; This allows calling (log:info ...) instead of (log:log-info ...)
;; Note: warn, error, debug, trace are shadowed to avoid conflicts with CL symbols
(setf (fdefinition 'info) #'log-info)
(setf (fdefinition 'warn) #'log-warn)
(setf (fdefinition 'error) #'log-error)
(setf (fdefinition 'debug) #'log-debug)
(setf (fdefinition 'trace) #'log-trace)
