;;;; systems/orchestrator-spec/pipeline-dsl.lisp
;;;; DEFPIPELINE macro for declaring pipelines

(in-package :orchestrator.spec)

;;; ============================================================================
;;; PIPELINE DATA STRUCTURES
;;; ============================================================================

(defclass pipeline ()
  ((name
    :initarg :name
    :accessor pipeline-name
    :type symbol
    :documentation "Pipeline name")
   (stages
    :initarg :stages
    :accessor pipeline-stages
    :initform nil
    :type list
    :documentation "List of stage objects")
   (corpus
    :initarg :corpus
    :accessor pipeline-corpus
    :initform nil
    :documentation "Associated corpus (optional)")
   (config
    :initarg :config
    :accessor pipeline-config
    :initform nil
    :documentation "Pipeline configuration")
   (metadata
    :initarg :metadata
    :accessor pipeline-metadata
    :initform nil
    :type list
    :documentation "Additional metadata as plist"))
  (:documentation "Pipeline data structure"))

(defclass stage ()
  ((name
    :initarg :name
    :accessor stage-name
    :type symbol
    :documentation "Stage name")
   (function
    :initarg :function
    :accessor stage-function
    :type (or symbol function)
    :documentation "Function to execute for this stage")
   (dependencies
    :initarg :dependencies
    :accessor stage-dependencies
    :initform nil
    :type list
    :documentation "List of stage names this depends on")
   (produces
    :initarg :produces
    :accessor stage-produces
    :initform nil
    :type list
    :documentation "List of artifact types this stage produces")
   (condition-handlers
    :initarg :condition-handlers
    :accessor stage-condition-handlers
    :initform nil
    :type list
    :documentation "List of (condition-type . handler-function) pairs"))
  (:documentation "Pipeline stage data structure"))

;;; ============================================================================
;;; PIPELINE REGISTRY
;;; ============================================================================

(defvar *pipeline-registry* (make-hash-table :test 'eq)
  "Global registry of all defined pipelines")

(defun register-pipeline (name pipeline)
  "Register a pipeline in the global registry"
  (setf (gethash name *pipeline-registry*) pipeline))

(defun find-pipeline (name)
  "Find a pipeline by name in the registry"
  (gethash name *pipeline-registry*))

(defun list-all-pipelines ()
  "List all registered pipeline names"
  (alexandria:hash-table-keys *pipeline-registry*))

;;; ============================================================================
;;; STAGE REGISTRY
;;; ============================================================================

(defvar *stage-registry* (make-hash-table :test 'eq)
  "Global registry of all defined stages")

(defun register-stage (name stage)
  "Register a stage in the global registry"
  (setf (gethash name *stage-registry*) stage))

(defun find-stage (name)
  "Find a stage by name in the registry"
  (gethash name *stage-registry*))

(defun list-all-stages ()
  "List all registered stage names"
  (alexandria:hash-table-keys *stage-registry*))

;;; ============================================================================
;;; DEFPIPELINE MACRO
;;; ============================================================================

(defmacro defpipeline (name &body body)
  "Define a pipeline with stages and configuration
  
  Syntax:
    (defpipeline pipeline-name
      (:corpus corpus-spec)
      (:config config-spec)
      (:stages
        (stage-name :function fn :depends-on (...) :produces (...))
        ...))
  
  Example:
    (defpipeline greek-constitution-pipeline
      (:corpus :gr-syntagma)
      (:config '(:parallel t :max-retries 3))
      (:stages
        (parse-pdf :function parse-pdf-stage :produces (:articles))
        (generate-rdf :function generate-rdf-stage 
                      :depends-on (parse-pdf) 
                      :produces (:rdf-turtle :json-ld))
        (validate :function validate-stage 
                  :depends-on (generate-rdf) 
                  :produces (:validation-report))))
  "
  (let ((corpus-spec nil)
        (config-spec nil)
        (stages-spec nil)
        (metadata-spec nil))
    
    ;; Parse body
    (dolist (clause body)
      (when (consp clause)
        (case (first clause)
          (:corpus (setf corpus-spec (second clause)))
          (:config (setf config-spec (second clause)))
          (:stages (setf stages-spec (rest clause)))
          (:metadata (setf metadata-spec (rest clause))))))
    
    ;; Build pipeline object
    `(progn
       ;; Create pipeline object
       (let* ((stages (list ,@(mapcar #'compile-stage-spec stages-spec)))
              (pipeline (make-instance 'pipeline
                                      :name ',name
                                      :stages stages
                                      :corpus ,corpus-spec
                                      :config ,config-spec
                                      :metadata ',metadata-spec)))
         
         ;; Register stages
         (dolist (stage stages)
           (register-stage (stage-name stage) stage))
         
         ;; Register pipeline
         (register-pipeline ',name pipeline)
         
         ;; Validate pipeline structure
         (validate-pipeline pipeline)
         
         ;; Return pipeline
         pipeline))))

(defun compile-stage-spec (stage-spec)
  "Compile a stage specification into a stage object creation form"
  (destructuring-bind (stage-name &key function depends-on produces handlers) stage-spec
    `(make-instance 'stage
                    :name ',stage-name
                    :function ',function
                    :dependencies ',depends-on
                    :produces ',produces
                    :condition-handlers ',handlers)))

;;; ============================================================================
;;; DEFSTAGE MACRO
;;; ============================================================================

(defmacro defstage (name (&rest params) &body body)
  "Define a standalone stage function
  
  Syntax:
    (defstage stage-name (context article)
      \"Documentation\"
      ... body ...)
  
  Example:
    (defstage parse-pdf-stage (context article)
      \"Parse PDF and extract article content\"
      (let ((pdf-path (get-context-value context :pdf-path)))
        (parse-pdf-file pdf-path article)))
  "
  (let ((docstring (when (stringp (first body)) (first body)))
        (real-body (if (stringp (first body)) (rest body) body)))
    `(defun ,name ,params
       ,@(when docstring (list docstring))
       (block ,name
         ,@real-body))))

;;; ============================================================================
;;; PIPELINE CONTEXT MACRO
;;; ============================================================================

(defmacro with-pipeline-context ((var &rest init-args) &body body)
  "Execute body with a pipeline context
  
  Syntax:
    (with-pipeline-context (ctx :pipeline pipeline :config config)
      ... body ...)
  "
  `(let ((,var (make-pipeline-context ,@init-args)))
     (unwind-protect
          (progn ,@body)
       (cleanup-pipeline-context ,var))))

;;; Helper functions (to be implemented in orchestrator-core)
(defun make-pipeline-context (&rest args)
  "Create a pipeline context (stub - implemented in orchestrator-core)"
  (declare (ignore args))
  (error "make-pipeline-context not implemented - load orchestrator-core"))

(defun cleanup-pipeline-context (context)
  "Cleanup a pipeline context (stub - implemented in orchestrator-core)"
  (declare (ignore context))
  nil)

(defun get-context-value (context key)
  "Get value from context (stub - implemented in orchestrator-core)"
  (declare (ignore context key))
  (error "get-context-value not implemented - load orchestrator-core"))
