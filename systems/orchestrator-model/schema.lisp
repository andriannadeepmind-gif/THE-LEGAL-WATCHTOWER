;;;; systems/orchestrator-model/schema.lisp
;;;; Introspection API for model classes

(in-package :orchestrator.model)

;;; ============================================================================
;;; CLASS SCHEMA INTROSPECTION
;;; ============================================================================

(defun get-class-schema (class-name)
  "Get schema information for a class
  
  Args:
    class-name: Symbol naming the class
  
  Returns:
    Plist with class schema information"
  (let ((class (find-class class-name)))
    (unless class
      (error "Class not found: ~A" class-name))
    
    (list :name class-name
          :metaclass (class-name (class-of class))
          :slots (mapcar #'slot-schema
                        (closer-mop:class-slots class))
          :superclasses (mapcar #'class-name
                               (closer-mop:class-direct-superclasses class))
          :documentation (documentation class 'type))))

(defun slot-schema (slot-definition)
  "Get schema information for a slot
  
  Args:
    slot-definition: Slot definition object
  
  Returns:
    Plist with slot schema information"
  (list :name (closer-mop:slot-definition-name slot-definition)
        :type (closer-mop:slot-definition-type slot-definition)
        :initform (when (closer-mop:slot-definition-initform slot-definition)
                   (closer-mop:slot-definition-initform slot-definition))
        :initargs (closer-mop:slot-definition-initargs slot-definition)
        :readers (closer-mop:slot-definition-readers slot-definition)
        :writers (closer-mop:slot-definition-writers slot-definition)
        :allocation (closer-mop:slot-definition-allocation slot-definition)
        :documentation (documentation slot-definition t)))

;;; ============================================================================
;;; CLASS QUERIES
;;; ============================================================================

(defun list-all-article-classes ()
  "List all classes with article-class metaclass
  
  Returns:
    List of class names"
  (let ((result nil))
    ;; Iterate through symbols in orchestrator.model package
    (do-external-symbols (sym (find-package :orchestrator.model))
      (when (and (find-class sym nil)
                 (typep (find-class sym) 'article-class))
        (push sym result)))
    (sort result #'string< :key #'symbol-name)))

(defun list-all-corpus-classes ()
  "List all classes with corpus-class metaclass
  
  Returns:
    List of class names"
  (let ((result nil))
    ;; Iterate through symbols in orchestrator.model package
    (do-external-symbols (sym (find-package :orchestrator.model))
      (when (and (find-class sym nil)
                 (typep (find-class sym) 'corpus-class))
        (push sym result)))
    (sort result #'string< :key #'symbol-name)))

(defun class-has-slot-p (class-name slot-name)
  "Check if class has a specific slot
  
  Args:
    class-name: Symbol naming the class
    slot-name: Symbol naming the slot
  
  Returns:
    T if class has slot, NIL otherwise"
  (let ((class (find-class class-name)))
    (when class
      (find slot-name
            (closer-mop:class-slots class)
            :key #'closer-mop:slot-definition-name))))

(defun get-slot-definition (class-name slot-name)
  "Get slot definition for a class
  
  Args:
    class-name: Symbol naming the class
    slot-name: Symbol naming the slot
  
  Returns:
    Slot definition object or NIL"
  (let ((class (find-class class-name)))
    (when class
      (find slot-name
            (closer-mop:class-slots class)
            :key #'closer-mop:slot-definition-name))))

;;; ============================================================================
;;; INSTANCE INTROSPECTION
;;; ============================================================================

(defun describe-instance (instance)
  "Get detailed description of instance
  
  Args:
    instance: Object instance
  
  Returns:
    Plist with instance information"
  (let ((class (class-of instance)))
    (list :class (class-name class)
          :metaclass (class-name (class-of class))
          :bound-slots (instance-bound-slots instance)
          :slot-values (instance-slot-values instance))))

(defun instance-bound-slots (instance)
  "Get list of bound slot names for instance
  
  Args:
    instance: Object instance
  
  Returns:
    List of slot names"
  (let ((class (class-of instance)))
    (loop for slot in (closer-mop:class-slots class)
          when (slot-boundp instance (closer-mop:slot-definition-name slot))
          collect (closer-mop:slot-definition-name slot))))

(defun instance-slot-values (instance)
  "Get plist of slot names and values for instance
  
  Args:
    instance: Object instance
  
  Returns:
    Plist of slot-name -> value"
  (let ((class (class-of instance))
        (result nil))
    (dolist (slot (closer-mop:class-slots class))
      (let ((slot-name (closer-mop:slot-definition-name slot)))
        (when (slot-boundp instance slot-name)
          (setf (getf result slot-name)
                (slot-value instance slot-name)))))
    result))

;;; ============================================================================
;;; VALIDATION
;;; ============================================================================

(defun validate-instance (instance)
  "Validate an instance against its schema
  
  Args:
    instance: Object instance
  
  Returns:
    T if valid, signals error otherwise"
  (let ((class (class-of instance)))
    ;; Check required slots are bound
    (dolist (slot (closer-mop:class-slots class))
      (let ((slot-name (closer-mop:slot-definition-name slot)))
        (unless (or (slot-boundp instance slot-name)
                   (closer-mop:slot-definition-initform slot))
          (error "Required slot ~A not bound in ~A"
                 slot-name
                 (class-name class)))))
    t))
