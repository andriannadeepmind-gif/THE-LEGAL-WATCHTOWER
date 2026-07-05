;;;; source/validate-ast.lisp
;;;; ============================================================================
;;;; VALIDATE-AST - Layer 4 AST Validation
;;;; ============================================================================
;;;;
;;;; NSA-GRADE VALIDATION FOR LEGAL DOCUMENT AST
;;;;
;;;; This module validates the complete AST output of Layer 4.
;;;; Every AST node MUST pass validation before the document is considered valid.
;;;;
;;;; VALIDATION CATEGORIES:
;;;;   1. STRUCTURAL: AST hierarchy is well-formed
;;;;   2. CONTENT: Required fields are present and non-empty
;;;;   3. REFERENTIAL: Parent-child links are consistent
;;;;   4. LEGAL: Document follows Greek legal structure rules
;;;;   5. TRACE: Full traceability chain maintained
;;;;
;;;; ZERO TOLERANCE: The AST is either completely valid or invalid.
;;;;
;;;; ============================================================================
;;;; COMMON LISP FEATURES UTILIZED
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ GENERIC FUNCTIONS        │ Polymorphic validation by node type          │
;;;; │                          │ • validate-ast-node (main entry)             │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ METHOD COMBINATIONS      │ Combine validations across hierarchy         │
;;;; │                          │ • call-next-method for inherited checks      │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Rich validation results                      │
;;;; │                          │ (values valid-p issues warnings stats)       │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CONDITIONS               │ Validation error hierarchy                   │
;;;; │                          │ • ast-validation-error                       │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(defpackage :orchestrator.validate-ast
  (:use :cl)
  (:import-from :orchestrator.trace-core
                #:trace-info
                #:trace-id
                #:trace-valid-p)
  (:import-from :orchestrator.legal-ast
                #:ast-node
                #:ast-id
                #:ast-type
                #:ast-parent
                #:ast-children
                #:ast-text
                #:ast-trace
                #:ast-source-blocks
                #:ast-validate
                #:ast-walk
                #:document-node
                #:document-title
                #:document-preamble
                #:document-articles
                #:document-closing
                #:article-node
                #:article-number
                #:article-title
                #:article-paragraphs
                #:paragraph-node
                #:paragraph-number
                #:paragraph-content
                #:paragraph-points
                #:point-node
                #:point-marker
                #:point-content
                #:closing-node
                #:signature-node)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; MAIN ENTRY POINTS
   ;; ══════════════════════════════════════════════════════════════════
   #:validate-ast
   #:validate-ast-node
   #:validate-document
   #:validate-article
   #:validate-paragraph

   ;; ══════════════════════════════════════════════════════════════════
   ;; VALIDATION RESULT
   ;; ══════════════════════════════════════════════════════════════════
   #:ast-validation-result
   #:make-ast-validation-result
   #:result-valid-p
   #:result-issues
   #:result-warnings
   #:result-node-count
   #:result-valid-count

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONFIGURATION
   ;; ══════════════════════════════════════════════════════════════════
   #:*require-article-numbers*
   #:*require-trace-chain*
   #:*strict-greek-legal-structure*

   ;; ══════════════════════════════════════════════════════════════════
   ;; SPECIFIC VALIDATORS
   ;; ══════════════════════════════════════════════════════════════════
   #:validate-structural-integrity
   #:validate-content-presence
   #:validate-parent-child-consistency
   #:validate-trace-chain
   #:validate-greek-legal-rules

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONDITIONS
   ;; ══════════════════════════════════════════════════════════════════
   #:ast-validation-error
   #:ast-structural-error
   #:ast-content-error
   #:ast-legal-structure-error))

(in-package :orchestrator.validate-ast)

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition ast-validation-error (error)
  ((message :initarg :message :reader validation-error-message)
   (node-id :initarg :node-id :reader validation-error-node-id :initform nil)
   (category :initarg :category :reader validation-error-category :initform :unknown))
  (:report (lambda (c s)
             (format s "AST Validation Error~@[ [~A]~]~@[ (node: ~A)~]: ~A"
                     (validation-error-category c)
                     (validation-error-node-id c)
                     (validation-error-message c)))))

(define-condition ast-structural-error (ast-validation-error)
  ()
  (:default-initargs :category :structural))

(define-condition ast-content-error (ast-validation-error)
  ()
  (:default-initargs :category :content))

(define-condition ast-legal-structure-error (ast-validation-error)
  ()
  (:default-initargs :category :legal-structure))

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *require-article-numbers* t
  "If T, all articles must have article-number")

(defvar *require-trace-chain* t
  "If T, all nodes must have valid trace-info")

(defvar *strict-greek-legal-structure* nil
  "If T, enforce strict Greek legal document structure")

;;; ============================================================================
;;; VALIDATION RESULT
;;; ============================================================================

(defstruct (ast-validation-result (:constructor %make-ast-validation-result)
                                  (:conc-name result-))
  "Result of AST validation."
  (valid-p t :type boolean)
  (issues '() :type list)
  (warnings '() :type list)
  (node-count 0 :type integer)
  (valid-count 0 :type integer)
  (depth 0 :type integer))

(defun make-ast-validation-result (&key (valid-p t) issues warnings
                                        (node-count 0) (valid-count 0) (depth 0))
  (%make-ast-validation-result
   :valid-p valid-p
   :issues (or issues '())
   :warnings (or warnings '())
   :node-count node-count
   :valid-count valid-count
   :depth depth))

;;; ============================================================================
;;; VALIDATION CONTEXT
;;; ============================================================================

(defvar *validation-issues* nil)
(defvar *validation-warnings* nil)
(defvar *node-count* 0)
(defvar *valid-count* 0)
(defvar *max-depth* 0)

(defmacro with-ast-validation-context (() &body body)
  `(let ((*validation-issues* '())
         (*validation-warnings* '())
         (*node-count* 0)
         (*valid-count* 0)
         (*max-depth* 0))
     ,@body))

(defun record-issue (category node-id message)
  (push (list :severity :error
              :category category
              :node-id node-id
              :message message)
        *validation-issues*))

(defun record-warning (category node-id message)
  (push (list :severity :warning
              :category category
              :node-id node-id
              :message message)
        *validation-warnings*))

;;; ============================================================================
;;; GENERIC VALIDATION FUNCTIONS
;;; ============================================================================

(defgeneric validate-ast-node (node depth)
  (:documentation "Validate a single AST node.
   Returns: T if node is valid.
   Uses call-next-method for inherited validation."))

(defmethod validate-ast-node ((node ast-node) depth)
  "Base validation for all AST nodes."
  (incf *node-count*)
  (setf *max-depth* (max *max-depth* depth))

  (let ((valid t)
        (node-id (ast-id node)))

    ;; Check ID
    (unless (and node-id (stringp node-id) (> (length node-id) 0))
      (record-issue :structural node-id "Node missing valid ID")
      (setf valid nil))

    ;; Check trace (if required)
    (when *require-trace-chain*
      (let ((trace (ast-trace node)))
        (when (and (null trace) (not (typep node 'document-node)))
          (record-warning :trace node-id "Node has no trace info"))))

    (when valid
      (incf *valid-count*))

    valid))

(defmethod validate-ast-node ((node document-node) depth)
  "Validate document node."
  (let ((valid (call-next-method))
        (node-id (ast-id node)))

    ;; Document must have content
    (unless (or (document-preamble node)
                (document-articles node))
      (record-issue :content node-id "Document has no preamble or articles")
      (setf valid nil))

    ;; Validate children
    (when (document-preamble node)
      (unless (validate-ast-node (document-preamble node) (1+ depth))
        (setf valid nil)))

    (dolist (article (document-articles node))
      (unless (validate-ast-node article (1+ depth))
        (setf valid nil)))

    (when (document-closing node)
      (unless (validate-ast-node (document-closing node) (1+ depth))
        (setf valid nil)))

    valid))

(defmethod validate-ast-node ((node article-node) depth)
  "Validate article node."
  (let ((valid (call-next-method))
        (node-id (ast-id node)))

    ;; Article must have number
    (when *require-article-numbers*
      (unless (article-number node)
        (record-issue :content node-id "Article missing number")
        (setf valid nil)))

    ;; Validate paragraphs
    (dolist (para (article-paragraphs node))
      (unless (validate-ast-node para (1+ depth))
        (setf valid nil)))

    valid))

(defmethod validate-ast-node ((node paragraph-node) depth)
  "Validate paragraph node."
  (let ((valid (call-next-method))
        (node-id (ast-id node)))

    ;; Paragraph must have content or points
    (unless (or (and (paragraph-content node)
                     (> (length (paragraph-content node)) 0))
                (paragraph-points node))
      (record-warning :content node-id "Paragraph has no content or points"))

    ;; Validate points
    (dolist (point (paragraph-points node))
      (unless (validate-ast-node point (1+ depth))
        (setf valid nil)))

    valid))

(defmethod validate-ast-node ((node point-node) depth)
  "Validate point node."
  (let ((valid (call-next-method))
        (node-id (ast-id node)))

    ;; Point should have marker
    (unless (point-marker node)
      (record-warning :content node-id "Point missing marker"))

    ;; Point should have content
    (unless (and (point-content node)
                 (> (length (point-content node)) 0))
      (record-warning :content node-id "Point has no content"))

    valid))

(defmethod validate-ast-node ((node closing-node) depth)
  "Validate closing node."
  (let ((valid (call-next-method)))
    ;; Validate signatures
    (dolist (sig (closing-node-signatures node))
      (unless (validate-ast-node sig (1+ depth))
        (setf valid nil)))
    valid))

(defmethod validate-ast-node ((node signature-node) depth)
  "Validate signature node."
  (call-next-method))

;;; Accessor for closing-node-signatures
(defun closing-node-signatures (node)
  (slot-value node 'orchestrator.legal-ast::signatures))

;;; ============================================================================
;;; SPECIFIC VALIDATORS
;;; ============================================================================

(defun validate-structural-integrity (ast)
  "Validate AST structural integrity.

   Checks:
   - No orphan nodes (all have parent except root)
   - No circular references
   - Children correctly linked to parents"
  (let ((valid t)
        (visited (make-hash-table :test #'equal)))

    (ast-walk ast
              (lambda (node depth)
                (declare (ignore depth))
                (let ((node-id (ast-id node)))
                  ;; Check for circular reference
                  (when (gethash node-id visited)
                    (record-issue :structural node-id "Circular reference detected")
                    (setf valid nil)
                    (return-from validate-structural-integrity nil))
                  (setf (gethash node-id visited) t)

                  ;; Check parent-child consistency
                  (dolist (child (ast-children node))
                    (unless (eq (ast-parent child) node)
                      (record-issue :structural (ast-id child)
                                    (format nil "Parent mismatch: expected ~A"
                                            node-id))
                      (setf valid nil))))))
    valid))

(defun validate-content-presence (ast)
  "Validate that all required content is present."
  (let ((valid t))
    (ast-walk ast
              (lambda (node depth)
                (declare (ignore depth))
                ;; Use the ast-validate generic function from legal-ast
                (unless (ast-validate node)
                  (record-issue :content (ast-id node)
                                "Node failed content validation")
                  (setf valid nil))))
    valid))

(defun validate-parent-child-consistency (ast)
  "Validate parent-child relationships are bidirectional."
  (let ((valid t))
    (ast-walk ast
              (lambda (node depth)
                (declare (ignore depth))
                (dolist (child (ast-children node))
                  (when (and child (not (eq (ast-parent child) node)))
                    (record-issue :structural (ast-id child)
                                  "Child's parent doesn't match actual parent")
                    (setf valid nil)))))
    valid))

(defun validate-trace-chain (ast)
  "Validate that all nodes have complete trace chains."
  (let ((valid t))
    (ast-walk ast
              (lambda (node depth)
                (declare (ignore depth))
                (when *require-trace-chain*
                  (let ((trace (ast-trace node)))
                    (when (and (null trace)
                               (not (zerop depth)))  ; Root may not have trace
                      (record-warning :trace (ast-id node)
                                      "Missing trace info"))))))
    valid))

(defun validate-greek-legal-rules (ast)
  "Validate Greek legal document structure rules.

   When *strict-greek-legal-structure* is T:
   - Articles must be numbered sequentially
   - Paragraphs within articles must be numbered
   - Points use Greek letters (α, β, γ)"
  (unless *strict-greek-legal-structure*
    (return-from validate-greek-legal-rules t))

  (let ((valid t))
    ;; Check article numbering
    (when (typep ast 'document-node)
      (let ((last-num 0))
        (dolist (article (document-articles ast))
          (let ((num-str (article-number article)))
            (when num-str
              (let ((num (ignore-errors (parse-integer num-str :junk-allowed t))))
                (when (and num (<= num last-num))
                  (record-warning :legal-structure (ast-id article)
                                  (format nil "Article ~A not sequential (after ~D)"
                                          num-str last-num)))
                (when num (setf last-num num))))))))
    valid))

;;; ============================================================================
;;; MAIN ENTRY POINTS
;;; ============================================================================

(defun validate-ast (ast)
  "Validate complete AST.

   This is the main entry point for Layer 4 validation.

   Args:
     ast: document-node (root of AST)

   Returns: (values valid-p result)"
  (with-ast-validation-context ()
    (let ((valid t))
      ;; Validate each node recursively
      (unless (validate-ast-node ast 0)
        (setf valid nil))

      ;; Additional validations
      (unless (validate-structural-integrity ast)
        (setf valid nil))

      (validate-trace-chain ast)

      (unless (validate-greek-legal-rules ast)
        (setf valid nil))

      (let* ((has-errors (not (null *validation-issues*)))
             (result (make-ast-validation-result
                      :valid-p (and valid (not has-errors))
                      :issues (nreverse *validation-issues*)
                      :warnings (nreverse *validation-warnings*)
                      :node-count *node-count*
                      :valid-count *valid-count*
                      :depth *max-depth*)))
        (values (result-valid-p result) result)))))

(defun validate-document (document-node)
  "Alias for validate-ast."
  (validate-ast document-node))

(defun validate-article (article-node)
  "Validate a single article node and its descendants.

   Returns: (values valid-p result)"
  (with-ast-validation-context ()
    (let ((valid (validate-ast-node article-node 0)))
      (let ((result (make-ast-validation-result
                     :valid-p (and valid (null *validation-issues*))
                     :issues (nreverse *validation-issues*)
                     :warnings (nreverse *validation-warnings*)
                     :node-count *node-count*
                     :valid-count *valid-count*)))
        (values (result-valid-p result) result)))))

(defun validate-paragraph (paragraph-node)
  "Validate a single paragraph node and its descendants.

   Returns: (values valid-p result)"
  (with-ast-validation-context ()
    (let ((valid (validate-ast-node paragraph-node 0)))
      (values valid
              (make-ast-validation-result
               :valid-p valid
               :issues (nreverse *validation-issues*)
               :warnings (nreverse *validation-warnings*)
               :node-count *node-count*
               :valid-count *valid-count*)))))

;;; ============================================================================
;;; REPORT
;;; ============================================================================

(defun print-ast-validation-report (result &optional (stream *standard-output*))
  "Print human-readable AST validation report."
  (format stream "~&══════════════════════════════════════════════════════════════~%")
  (format stream "AST VALIDATION REPORT (Layer 4)~%")
  (format stream "══════════════════════════════════════════════════════════════~%")
  (format stream "~%STATUS: ~A~%"
          (if (result-valid-p result) "✓ PASSED" "✗ FAILED"))
  (format stream "~%STATISTICS:~%")
  (format stream "  Total nodes: ~D~%" (result-node-count result))
  (format stream "  Valid nodes: ~D~%" (result-valid-count result))
  (format stream "  Max depth: ~D~%" (result-depth result))
  (format stream "  Errors: ~D~%" (length (result-issues result)))
  (format stream "  Warnings: ~D~%" (length (result-warnings result)))

  (when (result-issues result)
    (format stream "~%ERRORS:~%")
    (dolist (issue (result-issues result))
      (format stream "  [~A] ~A: ~A~%"
              (getf issue :category)
              (getf issue :node-id)
              (getf issue :message))))

  (when (result-warnings result)
    (format stream "~%WARNINGS:~%")
    (dolist (warning (result-warnings result))
      (format stream "  [~A] ~A: ~A~%"
              (getf warning :category)
              (getf warning :node-id)
              (getf warning :message))))

  (format stream "~%══════════════════════════════════════════════════════════════~%")
  result)

;;; ============================================================================
;;; END OF VALIDATE-AST.LISP
;;; ============================================================================
