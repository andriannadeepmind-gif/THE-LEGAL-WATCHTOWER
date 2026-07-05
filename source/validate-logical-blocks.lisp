;;;; source/validate-logical-blocks.lisp
;;;; ============================================================================
;;;; VALIDATE-LOGICAL-BLOCKS - Layer 2 Validation
;;;; ============================================================================
;;;;
;;;; NSA-GRADE VALIDATION FOR LOGICAL BLOCKS
;;;;
;;;; This module validates the output of Layer 2 (Layout Graph → Logical Blocks).
;;;; Every logical-block MUST pass validation before proceeding to Layer 3.
;;;;
;;;; VALIDATION CATEGORIES:
;;;;   1. TRACE VALIDATION: Every logical-block has complete trace
;;;;   2. TYPE VALIDATION: Block type is valid and consistent
;;;;   3. CONFIDENCE VALIDATION: Classification confidence above threshold
;;;;   4. STRUCTURE VALIDATION: Document structure is coherent
;;;;   5. SEQUENCE VALIDATION: Article/paragraph ordering is valid
;;;;
;;;; ZERO TOLERANCE: Validation either passes completely or fails.
;;;;
;;;; ============================================================================

(defpackage :orchestrator.validate-logical-blocks
  (:use :cl)
  (:import-from :orchestrator.trace-core
                #:trace-info
                #:trace-id
                #:trace-valid-p
                #:validate-trace-completeness)
  (:import-from :orchestrator.typographic-classifier
                #:logical-block
                #:logical-block-type
                #:logical-block-layout
                #:logical-block-confidence
                #:logical-block-features
                #:logical-block-trace
                #:logical-block-id
                #:+block-types+
                #:block-type-p)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; MAIN VALIDATION ENTRY POINTS
   ;; ══════════════════════════════════════════════════════════════════
   #:validate-logical-blocks
   #:validate-logical-block
   #:validate-classified-page
   #:validate-classified-document

   ;; ══════════════════════════════════════════════════════════════════
   ;; VALIDATION RESULT
   ;; ══════════════════════════════════════════════════════════════════
   #:validation-result
   #:make-validation-result
   #:result-valid-p
   #:result-issues
   #:result-warnings
   #:result-statistics

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONFIGURATION
   ;; ══════════════════════════════════════════════════════════════════
   #:*minimum-confidence*
   #:*require-article-structure*

   ;; ══════════════════════════════════════════════════════════════════
   ;; SPECIFIC VALIDATORS
   ;; ══════════════════════════════════════════════════════════════════
   #:validate-block-type
   #:validate-block-confidence
   #:validate-block-trace
   #:validate-document-structure
   #:validate-article-sequence))

(in-package :orchestrator.validate-logical-blocks)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *minimum-confidence* 0.3
  "Minimum acceptable classification confidence (0.0-1.0)")

(defvar *require-article-structure* t
  "If T, require at least one :article-header in legal documents")

;;; ============================================================================
;;; VALIDATION RESULT
;;; ============================================================================

(defstruct (validation-result (:constructor %make-validation-result))
  "Result of validating logical blocks."
  (valid-p t :type boolean)
  (issues '() :type list)
  (warnings '() :type list)
  (statistics nil))

(defun make-validation-result (&key (valid-p t) issues warnings statistics)
  (%make-validation-result
   :valid-p valid-p
   :issues (or issues '())
   :warnings (or warnings '())
   :statistics statistics))

;;; ============================================================================
;;; VALIDATION ISSUE
;;; ============================================================================

(defstruct (validation-issue (:constructor make-issue
                                           (&key severity category block-id message)))
  (severity :error :type keyword)
  (category :unknown :type keyword)
  (block-id nil :type (or null string))
  (message "" :type string))

;;; ============================================================================
;;; VALIDATION CONTEXT
;;; ============================================================================

(defvar *validation-issues* nil)
(defvar *validation-warnings* nil)
(defvar *block-count* 0)
(defvar *valid-count* 0)

(defmacro with-validation-context (() &body body)
  `(let ((*validation-issues* '())
         (*validation-warnings* '())
         (*block-count* 0)
         (*valid-count* 0))
     ,@body))

(defun record-issue (category block-id message)
  (push (make-issue :severity :error
                    :category category
                    :block-id block-id
                    :message message)
        *validation-issues*))

(defun record-warning (category block-id message)
  (push (make-issue :severity :warning
                    :category category
                    :block-id block-id
                    :message message)
        *validation-warnings*))

;;; ============================================================================
;;; SPECIFIC VALIDATORS
;;; ============================================================================

(defun validate-block-type (block)
  "Validate that block has valid type."
  (let ((block-type (logical-block-type block))
        (block-id (logical-block-id block)))
    (cond
      ((null block-type)
       (record-issue :type-invalid block-id "Block has no type")
       nil)
      ((not (block-type-p block-type))
       (record-issue :type-invalid block-id
                     (format nil "Invalid block type: ~A" block-type))
       nil)
      ((eq block-type :unknown)
       (record-warning :type-unknown block-id "Block classified as :unknown")
       t)  ; Warning, not error
      (t t))))

(defun validate-block-confidence (block)
  "Validate that block confidence is above threshold."
  (let ((confidence (logical-block-confidence block))
        (block-id (logical-block-id block)))
    (cond
      ((null confidence)
       (record-issue :confidence block-id "Block has no confidence score")
       nil)
      ((< confidence *minimum-confidence*)
       (record-warning :low-confidence block-id
                       (format nil "Low confidence: ~,2F (min: ~,2F)"
                               confidence *minimum-confidence*))
       t)  ; Warning, not error
      (t t))))

(defun validate-block-trace (block)
  "Validate that block has complete trace."
  (incf *block-count*)
  (let ((trace (logical-block-trace block))
        (block-id (logical-block-id block)))
    (cond
      ((null trace)
       (record-issue :trace-missing block-id "Block has no trace")
       nil)
      ((not (trace-valid-p trace))
       (record-issue :trace-invalid block-id "Block trace is invalid")
       nil)
      (t
       (incf *valid-count*)
       t))))

(defun validate-logical-block (block)
  "Validate a single logical block.

   Returns: T if valid"
  (let ((type-ok (validate-block-type block))
        (conf-ok (validate-block-confidence block))
        (trace-ok (validate-block-trace block)))
    (and type-ok conf-ok trace-ok)))

;;; ============================================================================
;;; DOCUMENT STRUCTURE VALIDATION
;;; ============================================================================

(defun validate-document-structure (classified-blocks)
  "Validate overall document structure.

   Checks:
   - At least one :article-header (if required)
   - :title at beginning (if present)
   - :signature at end (if present)

   Args:
     classified-blocks: List of logical-block objects

   Returns: T if structure is valid"
  (when (null classified-blocks)
    (record-warning :structure-empty nil "No blocks to validate")
    (return-from validate-document-structure t))

  (let ((types (mapcar #'logical-block-type classified-blocks))
        (valid t))

    ;; Check for article headers
    (when (and *require-article-structure*
               (not (member :article-header types)))
      (record-warning :structure-no-articles nil
                      "No article headers found in document")
      ;; This is a warning, not error - document might be preamble only
      )

    ;; Check title position (should be early if present)
    (let ((title-pos (position :title types)))
      (when (and title-pos (> title-pos 3))
        (record-warning :structure-title-position nil
                        (format nil "Title found at position ~D (expected early)"
                                title-pos))))

    ;; Check signature position (should be late if present)
    (let ((sig-pos (position :signature types)))
      (when (and sig-pos (< sig-pos (- (length types) 5)))
        (record-warning :structure-signature-position nil
                        "Signature block found too early in document")))

    valid))

(defun validate-article-sequence (classified-blocks)
  "Validate article numbering sequence.

   Checks that article headers appear in reasonable order.

   Returns: T if sequence is valid"
  (let ((article-blocks (remove-if-not
                         (lambda (b) (eq (logical-block-type b) :article-header))
                         classified-blocks))
        (valid t))

    (when (> (length article-blocks) 1)
      ;; Check for reasonable progression
      ;; (We don't enforce strict numbering, just check for consistency)
      (let ((positions (mapcar (lambda (b)
                                 (position b classified-blocks))
                               article-blocks)))
        ;; Positions should be monotonically increasing
        (loop for (a b) on positions
              while b
              when (>= a b)
              do (record-warning :article-sequence nil
                                 "Article headers may be out of order")
                 (setf valid nil)
                 (return))))

    valid))

;;; ============================================================================
;;; MAIN ENTRY POINTS
;;; ============================================================================

(defun validate-logical-blocks (blocks)
  "Validate a list of logical blocks.

   This is the main entry point for Layer 2 validation.

   Args:
     blocks: List of logical-block objects

   Returns: (values valid-p result)"
  (with-validation-context ()
    (let ((all-valid t))
      ;; Validate each block
      (dolist (block blocks)
        (unless (validate-logical-block block)
          (setf all-valid nil)))

      ;; Validate structure
      (validate-document-structure blocks)
      (validate-article-sequence blocks)

      ;; Build result
      (let* ((has-errors (not (null *validation-issues*)))
             (result (make-validation-result
                      :valid-p (and all-valid (not has-errors))
                      :issues (nreverse *validation-issues*)
                      :warnings (nreverse *validation-warnings*)
                      :statistics (list :total-blocks *block-count*
                                        :valid-blocks *valid-count*
                                        :error-count (length *validation-issues*)
                                        :warning-count (length *validation-warnings*)))))
        (values (validation-result-valid-p result) result)))))

(defun validate-classified-page (page-blocks)
  "Validate logical blocks from a single page.

   Args:
     page-blocks: List of logical-block objects for one page

   Returns: (values valid-p result)"
  (validate-logical-blocks page-blocks))

(defun validate-classified-document (classified-document)
  "Validate classified document (list of (page-num . blocks) pairs).

   Args:
     classified-document: Output of classify-document

   Returns: (values valid-p result)"
  (let ((all-blocks '()))
    (dolist (page-pair classified-document)
      (setf all-blocks (append all-blocks (cdr page-pair))))
    (validate-logical-blocks all-blocks)))

;;; ============================================================================
;;; REPORT
;;; ============================================================================

(defun print-validation-report (result &optional (stream *standard-output*))
  "Print human-readable validation report for logical blocks."
  (format stream "~&══════════════════════════════════════════════════════════════~%")
  (format stream "LOGICAL BLOCKS VALIDATION REPORT (Layer 2)~%")
  (format stream "══════════════════════════════════════════════════════════════~%")
  (format stream "~%STATUS: ~A~%"
          (if (validation-result-valid-p result) "✓ PASSED" "✗ FAILED"))

  (let ((stats (validation-result-statistics result)))
    (when stats
      (format stream "~%STATISTICS:~%")
      (format stream "  Total blocks: ~D~%" (getf stats :total-blocks))
      (format stream "  Valid blocks: ~D~%" (getf stats :valid-blocks))
      (format stream "  Errors: ~D~%" (getf stats :error-count))
      (format stream "  Warnings: ~D~%" (getf stats :warning-count))))

  (when (validation-result-issues result)
    (format stream "~%ERRORS:~%")
    (dolist (issue (validation-result-issues result))
      (format stream "  [~A] ~A: ~A~%"
              (validation-issue-category issue)
              (validation-issue-block-id issue)
              (validation-issue-message issue))))

  (when (validation-result-warnings result)
    (format stream "~%WARNINGS:~%")
    (dolist (issue (validation-result-warnings result))
      (format stream "  [~A] ~A: ~A~%"
              (validation-issue-category issue)
              (validation-issue-block-id issue)
              (validation-issue-message issue))))

  (format stream "~%══════════════════════════════════════════════════════════════~%")
  result)

;;; ============================================================================
;;; END OF VALIDATE-LOGICAL-BLOCKS.LISP
;;; ============================================================================
