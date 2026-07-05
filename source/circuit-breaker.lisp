;;;; circuit-breaker.lisp
;;;; Circuit breaker pattern implementation with states, metrics, and thread-safety

(defpackage #:orchestrator.circuit-breaker
  (:use :cl :alexandria :bordeaux-threads)
  (:export #:circuit-breaker
           #:make-circuit-breaker
           #:call-with-circuit-breaker
           #:circuit-breaker-state
           #:reset-circuit-breaker
           #:circuit-breaker-metrics
           #:*circuit-breaker-registry*
           #:register-circuit-breaker
           #:get-circuit-breaker
           #:with-circuit-breaker))

(in-package :orchestrator.circuit-breaker)

;;;; ========================================================================
;;;; CONSTANTS
;;;; ========================================================================

(defconstant +default-circuit-timeout+ 60
  "Default timeout in seconds before trying half-open state")

(defconstant +default-failure-threshold+ 5
  "Default number of failures before opening circuit")

(defconstant +default-success-threshold+ 2
  "Default number of successes in half-open before closing")

(defconstant +max-retry-attempts+ 3
  "Maximum number of retry attempts for circuit breaker operations")

;;;; ========================================================================
;;;; CIRCUIT BREAKER CLASS
;;;; ========================================================================

(defclass circuit-breaker ()
  ((name
    :initarg :name
    :accessor cb-name
    :type string
    :documentation "Name of the circuit breaker")
   
   (state
    :initform :closed
    :accessor cb-state
    :type (member :closed :open :half-open)
    :documentation "Current state of circuit breaker")
   
   (failure-threshold
    :initarg :failure-threshold
    :initform 5
    :accessor cb-failure-threshold
    :type integer
    :documentation "Number of failures before opening circuit")
   
   (success-threshold
    :initarg :success-threshold
    :initform 2
    :accessor cb-success-threshold
    :type integer
    :documentation "Number of successes in half-open before closing")
   
   (timeout
    :initarg :timeout
    :initform 60
    :accessor cb-timeout
    :type number
    :documentation "Seconds to wait before trying half-open")
   
   (failure-count
    :initform 0
    :accessor cb-failure-count
    :type integer)
   
   (success-count
    :initform 0
    :accessor cb-success-count
    :type integer)
   
   (last-failure-time
    :initform nil
    :accessor cb-last-failure-time
    :type (or null integer))
   
   (total-calls
    :initform 0
    :accessor cb-total-calls
    :type integer)
   
   (total-successes
    :initform 0
    :accessor cb-total-successes
    :type integer)
   
   (total-failures
    :initform 0
    :accessor cb-total-failures
    :type integer)
   
   (lock
    :initform (make-lock "circuit-breaker-lock")
    :accessor cb-lock
    :documentation "Lock for thread-safe operations")))

;;;; ========================================================================
;;;; CONSTRUCTION
;;;; ========================================================================

(defun make-circuit-breaker (name &key 
                                  (failure-threshold 5)
                                  (success-threshold 2)
                                  (timeout 60))
  "Create a new circuit breaker"
  (declare (type string name))
  (declare (type integer failure-threshold success-threshold))
  (declare (type number timeout))
  (declare (optimize (speed 3) (safety 1)))
  (check-type name string)
  (check-type failure-threshold integer)
  (check-type success-threshold integer)
  (check-type timeout number)
  (make-instance 'circuit-breaker
                 :name name
                 :failure-threshold failure-threshold
                 :success-threshold success-threshold
                 :timeout timeout))

;;;; ========================================================================
;;;; STATE MANAGEMENT
;;;; ========================================================================

(defun should-attempt-reset-p (breaker)
  "Check if enough time has passed to try half-open state"
  (and (eq (cb-state breaker) :open)
       (cb-last-failure-time breaker)
       (> (- (orchestrator.time:now :source :system) (cb-last-failure-time breaker))
          (cb-timeout breaker))))

(defun transition-to-half-open (breaker)
  "Transition from open to half-open state"
  (setf (cb-state breaker) :half-open
        (cb-success-count breaker) 0
        (cb-failure-count breaker) 0))

(defun record-success (breaker)
  "Record a successful call"
  (with-lock-held ((cb-lock breaker))
    (incf (cb-total-calls breaker))
    (incf (cb-total-successes breaker))
    
    (case (cb-state breaker)
      (:half-open
       (incf (cb-success-count breaker))
       (when (>= (cb-success-count breaker) (cb-success-threshold breaker))
         ;; Transition to closed
         (setf (cb-state breaker) :closed
               (cb-failure-count breaker) 0
               (cb-success-count breaker) 0)))
      
      (:closed
       ;; Reset failure count on success
       (setf (cb-failure-count breaker) 0)))))

(defun record-failure (breaker)
  "Record a failed call"
  (with-lock-held ((cb-lock breaker))
    (incf (cb-total-calls breaker))
    (incf (cb-total-failures breaker))
    (setf (cb-last-failure-time breaker) (orchestrator.time:now :source :system))
    
    (case (cb-state breaker)
      ((:closed :half-open)
       (incf (cb-failure-count breaker))
       (when (>= (cb-failure-count breaker) (cb-failure-threshold breaker))
         ;; Transition to open
         (setf (cb-state breaker) :open
               (cb-failure-count breaker) 0
               (cb-success-count breaker) 0))))))

(defun reset-circuit-breaker (breaker)
  "Manually reset circuit breaker to closed state"
  (declare (type circuit-breaker breaker))
  (declare (optimize (speed 3) (safety 1)))
  (check-type breaker circuit-breaker)
  (with-lock-held ((cb-lock breaker))
    (setf (cb-state breaker) :closed
          (cb-failure-count breaker) 0
          (cb-success-count breaker) 0
          (cb-last-failure-time breaker) nil)))

;;;; ========================================================================
;;;; CIRCUIT BREAKER EXECUTION
;;;; ========================================================================

(define-condition circuit-open-error (error)
  ((breaker-name :initarg :breaker-name :reader breaker-name))
  (:report (lambda (condition stream)
             (format stream "Circuit breaker ~A is OPEN" 
                     (breaker-name condition)))))

(defun call-with-circuit-breaker (breaker function)
  "Execute function with circuit breaker protection"
  (declare (type circuit-breaker breaker))
  (declare (type function function))
  (declare (optimize (speed 3) (safety 1)))
  (check-type breaker circuit-breaker)
  (check-type function function)
  (with-lock-held ((cb-lock breaker))
    ;; Check if we should attempt reset
    (when (should-attempt-reset-p breaker)
      (transition-to-half-open breaker)))
  
  ;; Check current state
  (when (eq (cb-state breaker) :open)
    (error 'circuit-open-error :breaker-name (cb-name breaker)))
  
  ;; Execute function
  (handler-case
      (let ((result (funcall function)))
        (record-success breaker)
        result)
    (error (e)
      (record-failure breaker)
      (error e))))

(defmacro with-circuit-breaker (breaker &body body)
  "Execute body with circuit breaker protection"
  `(call-with-circuit-breaker ,breaker (lambda () ,@body)))

;;;; ========================================================================
;;;; METRICS
;;;; ========================================================================

(defun circuit-breaker-metrics (breaker)
  "Get circuit breaker metrics"
  (declare (type circuit-breaker breaker))
  (declare (optimize (speed 3) (safety 1)))
  (with-lock-held ((cb-lock breaker))
    (list :name (cb-name breaker)
          :state (cb-state breaker)
          :total-calls (cb-total-calls breaker)
          :total-successes (cb-total-successes breaker)
          :total-failures (cb-total-failures breaker)
          :failure-rate (if (> (cb-total-calls breaker) 0)
                           (/ (cb-total-failures breaker) 
                              (cb-total-calls breaker))
                           0.0)
          :current-failure-count (cb-failure-count breaker)
          :current-success-count (cb-success-count breaker)
          :last-failure-time (cb-last-failure-time breaker))))

;;;; ========================================================================
;;;; REGISTRY
;;;; ========================================================================

(defvar *circuit-breaker-registry* (make-hash-table :test 'equal)
  "Global registry of circuit breakers")

(defvar *registry-lock* (make-lock "circuit-breaker-registry-lock")
  "Lock for registry operations")

(defun register-circuit-breaker (name &rest args)
  "Register a circuit breaker in the global registry"
  (declare (type string name))
  (declare (optimize (speed 3) (safety 1)))
  (check-type name string)
  (with-lock-held (*registry-lock*)
    (let ((breaker (apply #'make-circuit-breaker name args)))
      (setf (gethash name *circuit-breaker-registry*) breaker)
      breaker)))

(defun get-circuit-breaker (name &key (create-if-missing t))
  "Get circuit breaker from registry, optionally creating if missing"
  (declare (type string name))
  (declare (type boolean create-if-missing))
  (declare (optimize (speed 3) (safety 1)))
  (check-type name string)
  (with-lock-held (*registry-lock*)
    (or (gethash name *circuit-breaker-registry*)
        (when create-if-missing
          (register-circuit-breaker name)))))

(defun list-circuit-breakers ()
  "List all registered circuit breakers with their metrics"
  (with-lock-held (*registry-lock*)
    (loop for breaker being the hash-values of *circuit-breaker-registry*
          collect (circuit-breaker-metrics breaker))))

;;;; ========================================================================
;;;; INITIALIZATION
;;;; ========================================================================

(defun initialize-circuit-breakers ()
  "Initialize default circuit breakers for external services

   DARPA-GRADE: Only external HTTP endpoints need circuit breakers.
   Pure Lisp authorities (pdf, validation, reasoning) don't need them."
  (declare (optimize (speed 3) (safety 1)))

  ;; Blockchain services (pure Lisp JSON-RPC over HTTP)
  (register-circuit-breaker "blockchain-ethereum" :failure-threshold 3 :timeout 120)
  (register-circuit-breaker "blockchain-arweave" :failure-threshold 3 :timeout 120)
  (register-circuit-breaker "blockchain-ipfs" :failure-threshold 5 :timeout 60)

  ;; DEPRECATED: python-service - replaced by pure Lisp authorities (2026-01-03)
  ;; DEPRECATED: shacl-validator - replaced by validation-authority (pure Lisp)

  ;; External government/EU APIs
  (register-circuit-breaker "gov-api" :failure-threshold 5 :timeout 120)
  (register-circuit-breaker "eu-api" :failure-threshold 5 :timeout 120)

  ;; RFC 3161 TSA (pure Lisp Drakma HTTP)
  (register-circuit-breaker "tsa-freetsa" :failure-threshold 3 :timeout 60)

  ;; Certificate Transparency logs (pure Lisp Drakma HTTP)
  (register-circuit-breaker "ct-google-argon" :failure-threshold 3 :timeout 60)
  (register-circuit-breaker "ct-cloudflare" :failure-threshold 3 :timeout 60))

;; Initialize on load
(initialize-circuit-breakers)
