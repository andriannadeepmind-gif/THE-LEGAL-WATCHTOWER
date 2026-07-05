;;;; systems/orchestrator-model/metaclasses.lisp
;;;; Custom metaclasses using MOP for validation and lazy evaluation

(in-package :orchestrator.model)

;;; ============================================================================
;;; VALIDATED-CLASS METACLASS
;;; ============================================================================

(defclass validated-class (standard-class)
  ((validators
    :initarg :validators
    :accessor class-validators
    :initform nil
    :documentation "List of validation functions"))
  (:documentation "Metaclass that provides automatic slot validation"))

(defmethod validate-superclass ((class validated-class) (superclass standard-class))
  t)

(defmethod initialize-instance :after ((class validated-class) &key validators &allow-other-keys)
  "Initialize validators for the class"
  (when validators
    (setf (class-validators class) validators)))

(defmethod (setf slot-value-using-class) :before (new-value (class validated-class) instance slot-def)
  "Validate slot value before setting (only if instance is finalized)"
  ;; Skip validation during initialization
  (when (slot-exists-p instance 'orchestrator.model::number) ; proxy for finalized
    (let ((slot-name (slot-definition-name slot-def))
          (validators (class-validators class)))
      ;; Run class-level validators
      (dolist (validator validators)
        (funcall validator instance slot-name new-value)))))

;;; ============================================================================
;;; ARTICLE-CLASS METACLASS
;;; ============================================================================

(defclass article-class (validated-class)
  ((eli-uri-generator
    :initarg :eli-uri-generator
    :accessor class-eli-uri-generator
    :initform nil
    :documentation "Function to generate ELI URI"))
  (:documentation "Metaclass for article classes with ELI URI generation"))

(defmethod validate-superclass ((class article-class) (superclass validated-class))
  t)

(defmethod validate-superclass ((class article-class) (superclass standard-class))
  t)

(defmethod initialize-instance :after ((class article-class) &key eli-uri-generator &allow-other-keys)
  "Initialize ELI URI generator"
  (when eli-uri-generator
    (setf (class-eli-uri-generator class) eli-uri-generator)))

;;; ============================================================================
;;; CORPUS-CLASS METACLASS
;;; ============================================================================

(defclass corpus-class (validated-class)
  ((article-limit
    :initarg :article-limit
    :accessor class-article-limit
    :initform nil
    :documentation "Maximum number of articles allowed"))
  (:documentation "Metaclass for corpus classes with article management"))

(defmethod validate-superclass ((class corpus-class) (superclass validated-class))
  t)

(defmethod validate-superclass ((class corpus-class) (superclass standard-class))
  t)

;;; ============================================================================
;;; ARTIFACT-CLASS METACLASS
;;; ============================================================================

(defclass artifact-class (validated-class)
  ((content-type
    :initarg :content-type
    :accessor class-content-type
    :initform :binary
    :documentation "Default content type for artifacts of this class"))
  (:documentation "Metaclass for artifact classes"))

(defmethod validate-superclass ((class artifact-class) (superclass validated-class))
  t)

(defmethod validate-superclass ((class artifact-class) (superclass standard-class))
  t)

;;; ============================================================================
;;; LAZY SLOT MIXIN
;;; ============================================================================

(defclass lazy-slot-mixin ()
  ()
  (:documentation "Mixin for lazy slot evaluation"))

(defclass lazy-direct-slot-definition (standard-direct-slot-definition)
  ((lazy-p
    :initarg :lazy
    :initform nil
    :reader slot-definition-lazy-p)
   (lazy-function
    :initarg :lazy-function
    :initform nil
    :reader slot-definition-lazy-function))
  (:documentation "Direct slot definition for lazy slots"))

(defclass lazy-effective-slot-definition (standard-effective-slot-definition)
  ((lazy-p
    :initarg :lazy
    :initform nil
    :reader slot-definition-lazy-p)
   (lazy-function
    :initarg :lazy-function
    :initform nil
    :reader slot-definition-lazy-function))
  (:documentation "Effective slot definition for lazy slots"))

(defmethod direct-slot-definition-class ((class validated-class) &rest initargs)
  "Use lazy slot definition if :lazy t is specified"
  (if (getf initargs :lazy)
      (find-class 'lazy-direct-slot-definition)
      (call-next-method)))

(defmethod effective-slot-definition-class ((class validated-class) &rest initargs)
  "Use lazy effective slot definition if needed"
  (if (getf initargs :lazy)
      (find-class 'lazy-effective-slot-definition)
      (call-next-method)))

(defmethod compute-effective-slot-definition ((class validated-class) name direct-slots)
  "Compute effective slot definition preserving lazy properties"
  (let ((effective-slot (call-next-method)))
    (dolist (direct-slot direct-slots)
      (when (typep direct-slot 'lazy-direct-slot-definition)
        (when (slot-definition-lazy-p direct-slot)
          (setf (slot-value effective-slot 'lazy-p) t)
          (when (slot-definition-lazy-function direct-slot)
            (setf (slot-value effective-slot 'lazy-function)
                  (slot-definition-lazy-function direct-slot))))))
    effective-slot))

(defmethod slot-value-using-class :around ((class validated-class) instance slot-def)
  "Compute lazy slot value on first access"
  (if (and (typep slot-def 'lazy-effective-slot-definition)
           (slot-definition-lazy-p slot-def)
           (not (slot-boundp-using-class class instance slot-def)))
      (let ((lazy-fn (slot-definition-lazy-function slot-def)))
        (if lazy-fn
            (let ((computed-value (funcall lazy-fn instance)))
              (setf (slot-value-using-class class instance slot-def) computed-value)
              computed-value)
            (call-next-method)))
      (call-next-method)))

;;; ============================================================================
;;; VALIDATION HELPERS
;;; ============================================================================

(defun validate-article-number (instance slot-name new-value)
  "Validate article number is positive integer"
  (declare (ignore instance slot-name))
  (unless (and (integerp new-value) (> new-value 0))
    (error 'orchestrator.spec:validation-error
           :message (format nil "Article number must be positive integer, got: ~A" new-value)
           :validation-type :article-number)))

(defun validate-eli-uri (instance slot-name new-value)
  "Validate ELI URI format"
  (declare (ignore instance slot-name))
  (unless (typep new-value 'orchestrator.spec:eli-uri)
    (error 'orchestrator.spec:validation-error
           :message (format nil "Invalid ELI URI: ~A" new-value)
           :validation-type :eli-uri)))

(defun validate-language-code (instance slot-name new-value)
  "Validate language code"
  (declare (ignore instance slot-name))
  (unless (typep new-value 'orchestrator.spec:language-code)
    (error 'orchestrator.spec:validation-error
           :message (format nil "Invalid language code: ~A" new-value)
           :validation-type :language-code)))
