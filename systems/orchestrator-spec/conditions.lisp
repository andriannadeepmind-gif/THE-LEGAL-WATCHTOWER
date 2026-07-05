;;;; systems/orchestrator-spec/conditions.lisp
;;;; Condition hierarchy and restart definitions

(in-package :orchestrator.spec)

;;; ============================================================================
;;; BASE CONDITION
;;; ============================================================================

(define-condition orchestrator-error (error)
  ((message
    :initarg :message
    :reader error-message
    :type string
    :documentation "Human-readable error message")
   (component
    :initarg :component
    :reader error-component
    :initform nil
    :documentation "Component where error occurred")
   (article
    :initarg :article
    :reader error-article
    :initform nil
    :documentation "Article being processed (if applicable)")
   (context
    :initarg :context
    :reader error-context
    :initform nil
    :documentation "Additional context information"))
  (:report (lambda (condition stream)
             (format stream "Orchestrator Error~@[ in ~A~]: ~A~@[ (Article: ~A)~]~@[ Context: ~A~]"
                     (error-component condition)
                     (error-message condition)
                     (error-article condition)
                     (error-context condition))))
  (:documentation "Base condition for all orchestrator errors"))

;;; ============================================================================
;;; PARSING ERRORS
;;; ============================================================================

(define-condition xml-parse-error (orchestrator-error)
  ((line-number
    :initarg :line-number
    :reader error-line-number
    :initform nil
    :type (or null integer))
   (column-number
    :initarg :column-number
    :reader error-column-number
    :initform nil
    :type (or null integer)))
  (:report (lambda (condition stream)
             (format stream "XML Parse Error: ~A~@[ at line ~D~]~@[ column ~D~]"
                     (error-message condition)
                     (error-line-number condition)
                     (error-column-number condition))))
  (:documentation "XML/HTML parsing error"))

;;; ============================================================================
;;; RDF ERRORS
;;; ============================================================================

(define-condition rdf-error (orchestrator-error)
  ((rdf-format
    :initarg :rdf-format
    :reader error-rdf-format
    :initform :turtle
    :type keyword))
  (:report (lambda (condition stream)
             (format stream "RDF Error (~A): ~A"
                     (error-rdf-format condition)
                     (error-message condition))))
  (:documentation "RDF generation or parsing error"))

;;; ============================================================================
;;; VALIDATION ERRORS
;;; ============================================================================

(define-condition validation-error (orchestrator-error)
  ((validation-type
    :initarg :validation-type
    :reader error-validation-type
    :initform :shacl
    :type keyword)
   (violations
    :initarg :violations
    :reader error-violations
    :initform nil
    :type list))
  (:report (lambda (condition stream)
             (format stream "Validation Error (~A): ~A~@[~%Violations: ~{~A~^, ~}~]"
                     (error-validation-type condition)
                     (error-message condition)
                     (error-violations condition))))
  (:documentation "SHACL or other validation error"))

;;; ============================================================================
;;; BLOCKCHAIN ERRORS
;;; ============================================================================

(define-condition blockchain-error (orchestrator-error)
  ((backend
    :initarg :backend
    :reader error-backend
    :initform nil
    :type (or null keyword))
   (transaction-hash
    :initarg :transaction-hash
    :reader error-transaction-hash
    :initform nil
    :type (or null string)))
  (:report (lambda (condition stream)
             (format stream "Blockchain Error~@[ (~A)~]: ~A~@[ TX: ~A~]"
                     (error-backend condition)
                     (error-message condition)
                     (error-transaction-hash condition))))
  (:documentation "Blockchain anchoring error"))

;;; ============================================================================
;;; CONFIGURATION ERRORS
;;; ============================================================================

(define-condition config-error (orchestrator-error)
  ((config-key
    :initarg :config-key
    :reader error-config-key
    :initform nil
    :type (or null string keyword)))
  (:report (lambda (condition stream)
             (format stream "Configuration Error~@[ (key: ~A)~]: ~A"
                     (error-config-key condition)
                     (error-message condition))))
  (:documentation "Configuration loading or validation error"))

;;; ============================================================================
;;; DEPENDENCY ERRORS
;;; ============================================================================

(define-condition dependency-error (orchestrator-error)
  ((missing-artifact
    :initarg :missing-artifact
    :reader error-missing-artifact
    :initform nil
    :type (or null symbol))
   (required-by
    :initarg :required-by
    :reader error-required-by
    :initform nil
    :type (or null symbol)))
  (:report (lambda (condition stream)
             (format stream "Dependency Error: ~A~@[ (missing: ~A)~]~@[ (required by: ~A)~]"
                     (error-message condition)
                     (error-missing-artifact condition)
                     (error-required-by condition))))
  (:documentation "Missing or circular dependency error"))

;;; ============================================================================
;;; STAGE ERRORS
;;; ============================================================================

(define-condition stage-error (orchestrator-error)
  ((stage-name
    :initarg :stage-name
    :reader error-stage-name
    :initform nil
    :type (or null symbol))
   (retry-count
    :initarg :retry-count
    :reader error-retry-count
    :initform 0
    :type integer))
  (:report (lambda (condition stream)
             (format stream "Stage Error~@[ in ~A~]: ~A (retries: ~D)"
                     (error-stage-name condition)
                     (error-message condition)
                     (error-retry-count condition))))
  (:documentation "Pipeline stage execution error"))

;;; ============================================================================
;;; ARTIFACT ERRORS
;;; ============================================================================

(define-condition artifact-error (orchestrator-error)
  ((artifact-type
    :initarg :artifact-type
    :reader error-artifact-type
    :initform nil
    :type (or null keyword)))
  (:report (lambda (condition stream)
             (format stream "Artifact Error~@[ (~A)~]: ~A"
                     (error-artifact-type condition)
                     (error-message condition))))
  (:documentation "Artifact building or serialization error"))

;;; ============================================================================
;;; RESTART DEFINITIONS
;;; ============================================================================

(defun retry-stage (&optional (new-config nil))
  "Restart: Retry the failed stage with optional new configuration"
  (let ((restart (find-restart 'retry-stage)))
    (when restart
      (invoke-restart restart new-config))))

(defun skip-article ()
  "Restart: Skip the current article and continue with next"
  (let ((restart (find-restart 'skip-article)))
    (when restart
      (invoke-restart restart))))

(defun mark-degraded-and-continue ()
  "Restart: Mark current artifact as degraded but continue pipeline"
  (let ((restart (find-restart 'mark-degraded-and-continue)))
    (when restart
      (invoke-restart restart))))

(defun abort-pipeline ()
  "Restart: Abort the entire pipeline execution"
  (let ((restart (find-restart 'abort-pipeline)))
    (when restart
      (invoke-restart restart))))

(defun use-cached-artifact (artifact)
  "Restart: Use a cached artifact instead of rebuilding"
  (let ((restart (find-restart 'use-cached-artifact)))
    (when restart
      (invoke-restart restart artifact))))

(defun retry-with-backoff (wait-seconds)
  "Restart: Retry after waiting specified seconds"
  (let ((restart (find-restart 'retry-with-backoff)))
    (when restart
      (invoke-restart restart wait-seconds))))
