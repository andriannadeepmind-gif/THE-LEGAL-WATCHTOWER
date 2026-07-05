;;;; injection.lisp
;;;; Dependency injection container with lifecycle management

(defpackage #:orchestrator.injection
  (:use :cl :alexandria :bordeaux-threads)
  (:export #:*container*
           #:make-container
           #:register
           #:resolve
           #:register-singleton
           #:register-factory
           #:register-transient
           #:with-scope
           #:clear-container
           #:has-binding-p
           #:remove-binding
           #:list-bindings))

(in-package :orchestrator.injection)

;;;; ========================================================================
;;;; CONTAINER CLASS
;;;; ========================================================================

(defclass container ()
  ((bindings
    :initform (make-hash-table :test 'eq)
    :accessor container-bindings
    :documentation "Service bindings")
   
   (instances
    :initform (make-hash-table :test 'eq)
    :accessor container-instances
    :documentation "Singleton instances")
   
   (scopes
    :initform nil
    :accessor container-scopes
    :documentation "Scoped instance stacks")
   
   (lock
    :initform (make-lock "container-lock")
    :accessor container-lock
    :documentation "Lock for thread-safe operations")
   
   (dependency-graph
    :initform (make-hash-table :test 'eq)
    :accessor container-dependency-graph
    :documentation "Dependency graph for circular detection")))

;;;; ========================================================================
;;;; BINDING TYPES
;;;; ========================================================================

(deftype binding-lifetime ()
  '(member :singleton :transient :scoped :factory))

(defstruct binding
  "Service binding configuration"
  (name nil :type symbol)
  (lifetime :transient :type binding-lifetime)
  (factory nil :type (or function symbol))
  (dependencies nil :type list))

;;;; ========================================================================
;;;; CONSTANTS
;;;; ========================================================================

(defconstant +default-container-size+ 32
  "Default hash table size for container bindings")

(defconstant +max-dependency-depth+ 50
  "Maximum dependency resolution depth to prevent infinite recursion")

;;;; ========================================================================
;;;; CONTAINER CREATION
;;;; ========================================================================

(defvar *container* nil
  "Global default container")

(defun make-container ()
  "Create a new DI container"
  (declare (optimize (speed 3) (safety 1)))
  (make-instance 'container))

(defun ensure-container ()
  "Ensure global container exists"
  (declare (optimize (speed 3) (safety 1)))
  (unless *container*
    (setf *container* (make-container)))
  *container*)

;;;; ========================================================================
;;;; REGISTRATION
;;;; ========================================================================

(defun register (name factory &key (lifetime :transient) (dependencies nil))
  "Register a service in the container"
  (declare (type symbol name))
  (declare (type (or function symbol) factory))
  (declare (type binding-lifetime lifetime))
  (declare (type list dependencies))
  (declare (optimize (speed 3) (safety 1)))
  (check-type name symbol)
  (check-type lifetime binding-lifetime)
  (let ((container (ensure-container)))
    (with-lock-held ((container-lock container))
      (setf (gethash name (container-bindings container))
            (make-binding :name name
                         :lifetime lifetime
                         :factory factory
                         :dependencies dependencies))
      
      ;; Record dependencies for circular detection
      (setf (gethash name (container-dependency-graph container))
            dependencies)
      
      name)))

(defun register-singleton (name factory &key dependencies)
  "Register a singleton service"
  (declare (type symbol name))
  (declare (type (or function symbol) factory))
  (declare (type list dependencies))
  (declare (optimize (speed 3) (safety 1)))
  (register name factory :lifetime :singleton :dependencies dependencies))

(defun register-factory (name factory &key dependencies)
  "Register a factory service (creates new instance each time)"
  (declare (type symbol name))
  (declare (type (or function symbol) factory))
  (declare (type list dependencies))
  (declare (optimize (speed 3) (safety 1)))
  (register name factory :lifetime :factory :dependencies dependencies))

(defun register-transient (name factory &key dependencies)
  "Register a transient service"
  (declare (type symbol name))
  (declare (type (or function symbol) factory))
  (declare (type list dependencies))
  (declare (optimize (speed 3) (safety 1)))
  (register name factory :lifetime :transient :dependencies dependencies))

;;;; ========================================================================
;;;; CIRCULAR DEPENDENCY DETECTION
;;;; ========================================================================

(defun detect-circular-dependencies (container name &optional (visited nil))
  "Detect circular dependencies in the dependency graph"
  (when (member name visited)
    (error "Circular dependency detected: ~A" 
           (reverse (cons name visited))))
  
  (let ((deps (gethash name (container-dependency-graph container))))
    (when deps
      (dolist (dep deps)
        (detect-circular-dependencies container dep (cons name visited))))))

;;;; ========================================================================
;;;; RESOLUTION
;;;; ========================================================================

(defun resolve-dependency (container name)
  "Resolve a single dependency"
  (let ((binding (gethash name (container-bindings container))))
    (unless binding
      (error "No binding found for ~A" name))
    
    ;; Check for circular dependencies
    (detect-circular-dependencies container name)
    
    (ecase (binding-lifetime binding)
      (:singleton
       (resolve-singleton container binding))
      
      (:transient
       (resolve-transient container binding))
      
      (:factory
       (resolve-factory container binding))
      
      (:scoped
       (resolve-scoped container binding)))))

(defun resolve-singleton (container binding)
  "Resolve singleton instance (create if not exists)"
  (let ((name (binding-name binding)))
    (or (gethash name (container-instances container))
        (setf (gethash name (container-instances container))
              (create-instance container binding)))))

(defun resolve-transient (container binding)
  "Resolve transient instance (always create new)"
  (create-instance container binding))

(defun resolve-factory (container binding)
  "Resolve factory instance (call factory function)"
  (funcall (binding-factory binding)))

(defun resolve-scoped (container binding)
  "Resolve scoped instance (per-scope singleton)"
  (let* ((name (binding-name binding))
         (scope (first (container-scopes container))))
    (unless scope
      (error "No active scope for scoped service ~A" name))
    
    (or (gethash name scope)
        (setf (gethash name scope)
              (create-instance container binding)))))

(defun create-instance (container binding)
  "Create instance by calling factory with resolved dependencies"
  (let* ((factory (binding-factory binding))
         (deps (binding-dependencies binding))
         (resolved-deps (mapcar (lambda (dep) 
                                  (resolve-dependency container dep))
                                deps)))
    (apply (if (functionp factory) factory (symbol-function factory))
           resolved-deps)))

(defun resolve (name &optional (container *container*))
  "Resolve a service from the container"
  (declare (type symbol name))
  (declare (type (or null container) container))
  (declare (optimize (speed 3) (safety 1)))
  (check-type name symbol)
  (check-type container (or null container))
  (unless container
    (error "No container available"))
  
  (with-lock-held ((container-lock container))
    (resolve-dependency container name)))

;;;; ========================================================================
;;;; SCOPE MANAGEMENT
;;;; ========================================================================

(defmacro with-scope ((&optional (container '*container*)) &body body)
  "Execute body within a new dependency scope"
  (with-gensyms (scope-table result)
    `(let ((,scope-table (make-hash-table :test 'eq)))
       (unwind-protect
            (progn
              (push ,scope-table (container-scopes ,container))
              (let ((,result (progn ,@body)))
                ,result))
         (pop (container-scopes ,container))))))

;;;; ========================================================================
;;;; CONTAINER MANAGEMENT
;;;; ========================================================================

(defun clear-container (&optional (container *container*))
  "Clear all bindings and instances from container"
  (declare (type (or null container) container))
  (declare (optimize (speed 3) (safety 1)))
  (when container
    (with-lock-held ((container-lock container))
      (clrhash (container-bindings container))
      (clrhash (container-instances container))
      (clrhash (container-dependency-graph container))
      (setf (container-scopes container) nil))))

(defun has-binding-p (name &optional (container *container*))
  "Check if container has a binding for name"
  (declare (type symbol name))
  (declare (type (or null container) container))
  (declare (optimize (speed 3) (safety 1)))
  (when container
    (with-lock-held ((container-lock container))
      (nth-value 1 (gethash name (container-bindings container))))))

(defun remove-binding (name &optional (container *container*))
  "Remove a binding from the container"
  (declare (type symbol name))
  (declare (type (or null container) container))
  (declare (optimize (speed 3) (safety 1)))
  (when container
    (with-lock-held ((container-lock container))
      (remhash name (container-bindings container))
      (remhash name (container-instances container))
      (remhash name (container-dependency-graph container)))))

(defun list-bindings (&optional (container *container*))
  "List all registered bindings"
  (declare (type (or null container) container))
  (declare (optimize (speed 3) (safety 1)))
  (when container
    (with-lock-held ((container-lock container))
      (loop for binding being the hash-values of (container-bindings container)
            collect (list :name (binding-name binding)
                         :lifetime (binding-lifetime binding)
                         :dependencies (binding-dependencies binding))))))

;;;; ========================================================================
;;;; INITIALIZATION
;;;; ========================================================================

(defun initialize-container ()
  "Initialize the global container with default services"
  (declare (optimize (speed 3) (safety 1)))
  (setf *container* (make-container))
  
  ;; Register path resolver
  (register-singleton 'orchestrator.paths:resolve-path
                     (lambda () #'orchestrator.paths:resolve-path))
  
  ;; Register logging
  (register-singleton 'orchestrator.logging:log-event
                     (lambda () #'orchestrator.logging:log-event))
  
  *container*)

;; Initialize on load
(initialize-container)
