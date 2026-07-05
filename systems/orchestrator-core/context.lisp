;;;; systems/orchestrator-core/context.lisp
;;;; Pipeline execution context

(in-package :orchestrator.core)

;;; ============================================================================
;;; PIPELINE CONTEXT CLASS
;;; ============================================================================

(defclass pipeline-context ()
  ((pipeline
    :accessor context-pipeline
    :initarg :pipeline
    :documentation "Pipeline being executed")
   
   (config
    :accessor context-config
    :initarg :config
    :initform nil
    :documentation "Pipeline configuration")
   
   (artifacts
    :accessor context-artifacts
    :initform (make-hash-table :test 'eq)
    :documentation "Hash table of artifact-name -> artifact")
   
   (errors
    :accessor context-errors
    :initform nil
    :documentation "List of errors encountered during execution")
   
   (trace
    :accessor context-trace
    :initform nil
    :documentation "Execution trace for debugging")
   
   (bindings
    :accessor context-bindings
    :initform nil
    :type list
    :documentation "Dynamic bindings as plist")
   
   (start-time
    :accessor context-start-time
    :initform (get-internal-real-time)
    :documentation "Pipeline start time")
   
   (stage-metrics
    :accessor context-stage-metrics
    :initform (make-hash-table :test 'eq)
    :documentation "Hash table of stage-name -> metrics"))
  (:documentation "Execution context for a pipeline run"))

(defmethod print-object ((context pipeline-context) stream)
  "Print context in readable format"
  (print-unreadable-object (context stream :type t :identity t)
    (format stream "artifacts:~D errors:~D"
            (hash-table-count (context-artifacts context))
            (length (context-errors context)))))

;;; ============================================================================
;;; CONTEXT CONSTRUCTION
;;; ============================================================================

(defun make-pipeline-context (&rest args &key pipeline config &allow-other-keys)
  "Create a new pipeline context
  
  Args:
    pipeline: Pipeline object or name
    config: Configuration plist
  
  Returns:
    Pipeline context instance"
  (declare (ignore args))
  (make-instance 'pipeline-context
                 :pipeline pipeline
                 :config config))

(defun cleanup-pipeline-context (context)
  "Cleanup resources associated with context
  
  Args:
    context: Pipeline context
  
  Returns:
    NIL"
  (when context
    ;; Clear artifacts
    (clrhash (context-artifacts context))
    ;; Clear metrics
    (clrhash (context-stage-metrics context))
    ;; Clear errors and trace
    (setf (context-errors context) nil)
    (setf (context-trace context) nil)
    (setf (context-bindings context) nil))
  nil)

;;; ============================================================================
;;; CONTEXT ACCESSORS
;;; ============================================================================

(defun get-context-value (context key &optional default)
  "Get value from context bindings
  
  Args:
    context: Pipeline context
    key: Binding key (keyword)
    default: Default value if not found
  
  Returns:
    Binding value or default"
  (getf (context-bindings context) key default))

(defun set-context-value (context key value)
  "Set value in context bindings
  
  Args:
    context: Pipeline context
    key: Binding key (keyword)
    value: Value to set
  
  Returns:
    Value"
  (setf (getf (context-bindings context) key) value))

(defsetf get-context-value set-context-value)

;;; ============================================================================
;;; ARTIFACT MANAGEMENT
;;; ============================================================================

(defun add-artifact-to-context (context artifact-name artifact)
  "Add artifact to context
  
  Args:
    context: Pipeline context
    artifact-name: Artifact identifier
    artifact: Artifact object
  
  Returns:
    Artifact"
  (setf (gethash artifact-name (context-artifacts context)) artifact))

(defun get-artifact-from-context (context artifact-name)
  "Get artifact from context
  
  Args:
    context: Pipeline context
    artifact-name: Artifact identifier
  
  Returns:
    Artifact or NIL"
  (gethash artifact-name (context-artifacts context)))

(defun context-has-artifact-p (context artifact-name)
  "Check if context has artifact
  
  Args:
    context: Pipeline context
    artifact-name: Artifact identifier
  
  Returns:
    T if artifact exists, NIL otherwise"
  (nth-value 1 (gethash artifact-name (context-artifacts context))))

;;; ============================================================================
;;; ERROR HANDLING
;;; ============================================================================

(defun record-error (context error-info)
  "Record error in context
  
  Args:
    context: Pipeline context
    error-info: Error information (condition or plist)
  
  Returns:
    Error info"
  (push error-info (context-errors context))
  error-info)

(defun has-errors-p (context)
  "Check if context has any errors
  
  Args:
    context: Pipeline context
  
  Returns:
    T if context has errors, NIL otherwise"
  (not (null (context-errors context))))

;;; ============================================================================
;;; TRACE
;;; ============================================================================

(defun add-trace-entry (context message &optional data)
  "Add entry to execution trace
  
  Args:
    context: Pipeline context
    message: Trace message
    data: Optional trace data
  
  Returns:
    Trace entry"
  (let ((entry (list :timestamp (orchestrator.time:now :source :system)
                    :message message
                    :data data)))
    (push entry (context-trace context))
    entry))

(defun get-trace (context)
  "Get execution trace (most recent first)
  
  Args:
    context: Pipeline context
  
  Returns:
    List of trace entries"
  (reverse (context-trace context)))
