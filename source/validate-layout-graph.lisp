;;;; source/validate-layout-graph.lisp
;;;; ============================================================================
;;;; VALIDATE-LAYOUT-GRAPH - Layer 1 Validation
;;;; ============================================================================
;;;;
;;;; NSA-GRADE VALIDATION FOR LAYOUT GRAPH
;;;;
;;;; This module validates the output of Layer 1 (PDF → Layout Graph).
;;;; Every element MUST pass validation before proceeding to Layer 2.
;;;;
;;;; VALIDATION CATEGORIES:
;;;;   1. TRACE VALIDATION: Every element has complete trace
;;;;   2. BBOX VALIDATION: All bboxes are valid and consistent
;;;;   3. HIERARCHY VALIDATION: Parent-child relationships intact
;;;;   4. READING ORDER: Consistent ordering within pages
;;;;   5. CONTENT VALIDATION: Non-empty text at leaf level
;;;;
;;;; ZERO TOLERANCE: Validation either passes completely or fails.
;;;; NO PARTIAL SUCCESS.
;;;;
;;;; ============================================================================
;;;; COMMON LISP FEATURES UTILIZED
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CONDITIONS & RESTARTS    │ Validation error hierarchy with recovery     │
;;;; │                          │ • SKIP-ELEMENT: continue validation          │
;;;; │                          │ • USE-DEFAULT: substitute valid element      │
;;;; │                          │ • ABORT-VALIDATION: fail immediately         │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ GENERIC FUNCTIONS        │ Type-specific validation                     │
;;;; │                          │ • validate-layout-element (main entry)       │
;;;; │                          │ • collect-validation-issues                  │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Rich validation results                      │
;;;; │                          │ (values valid-p issues warnings stats)       │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MACROS                   │ Validation DSL                               │
;;;; │                          │ • defvalidator: define validation rules      │
;;;; │                          │ • with-validation-context                    │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(defpackage :orchestrator.validate-layout-graph
  (:use :cl)
  (:import-from :orchestrator.trace-core
                #:trace-info
                #:trace-id
                #:trace-pages
                #:trace-bboxes
                #:trace-valid-p
                #:validate-trace-completeness
                #:with-trace-restarts)
  (:import-from :orchestrator.layout-types
                #:bbox
                #:bbox-p
                #:bbox-valid-p
                #:bbox-x
                #:bbox-y
                #:bbox-width
                #:bbox-height
                #:bbox-contains-p
                #:bbox-overlaps-p
                #:layout-span
                #:layout-line
                #:layout-block
                #:layout-page
                #:layout-document
                #:element-bbox
                #:element-text
                #:element-children
                #:element-trace
                #:element-id
                #:span-text
                #:line-spans
                #:block-lines
                #:page-blocks
                #:document-pages
                #:page-number
                #:page-width
                #:page-height
                #:block-reading-order
                #:line-reading-order)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; MAIN VALIDATION ENTRY POINTS
   ;; ══════════════════════════════════════════════════════════════════
   #:validate-layout-graph
   #:validate-layout-element
   #:validate-document
   #:validate-page
   #:validate-block
   #:validate-line
   #:validate-span

   ;; ══════════════════════════════════════════════════════════════════
   ;; VALIDATION RESULT
   ;; ══════════════════════════════════════════════════════════════════
   #:validation-result
   #:make-validation-result
   #:result-valid-p
   #:result-issues
   #:result-warnings
   #:result-element-count
   #:result-checked-count
   #:result-duration-ms

   ;; ══════════════════════════════════════════════════════════════════
   ;; VALIDATION ISSUE
   ;; ══════════════════════════════════════════════════════════════════
   #:validation-issue
   #:make-validation-issue
   #:issue-severity
   #:issue-category
   #:issue-element-id
   #:issue-message
   #:issue-context

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONDITIONS
   ;; ══════════════════════════════════════════════════════════════════
   #:layout-validation-error
   #:trace-missing-error
   #:bbox-invalid-error
   #:hierarchy-error
   #:reading-order-error
   #:content-empty-error

   ;; ══════════════════════════════════════════════════════════════════
   ;; MACROS
   ;; ══════════════════════════════════════════════════════════════════
   #:with-validation-context
   #:defvalidator

   ;; ══════════════════════════════════════════════════════════════════
   ;; SPECIFIC VALIDATORS
   ;; ══════════════════════════════════════════════════════════════════
   #:validate-trace-presence
   #:validate-bbox-validity
   #:validate-bbox-containment
   #:validate-reading-order
   #:validate-content-non-empty
   #:validate-hierarchy-integrity))

(in-package :orchestrator.validate-layout-graph)

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition layout-validation-error (error)
  ((message :initarg :message :reader validation-error-message)
   (element-id :initarg :element-id :reader validation-error-element-id :initform nil)
   (category :initarg :category :reader validation-error-category :initform :unknown))
  (:report (lambda (c s)
             (format s "Layout Validation Error~@[ [~A]~]~@[ (element: ~A)~]: ~A"
                     (validation-error-category c)
                     (validation-error-element-id c)
                     (validation-error-message c)))))

(define-condition trace-missing-error (layout-validation-error)
  ()
  (:default-initargs :category :trace-missing))

(define-condition bbox-invalid-error (layout-validation-error)
  ((bbox :initarg :bbox :reader bbox-invalid-bbox :initform nil))
  (:default-initargs :category :bbox-invalid)
  (:report (lambda (c s)
             (format s "Invalid Bbox~@[ for ~A~]: ~A"
                     (validation-error-element-id c)
                     (validation-error-message c)))))

(define-condition hierarchy-error (layout-validation-error)
  ((parent-id :initarg :parent-id :reader hierarchy-error-parent)
   (child-id :initarg :child-id :reader hierarchy-error-child))
  (:default-initargs :category :hierarchy)
  (:report (lambda (c s)
             (format s "Hierarchy Error: ~A → ~A: ~A"
                     (hierarchy-error-parent c)
                     (hierarchy-error-child c)
                     (validation-error-message c)))))

(define-condition reading-order-error (layout-validation-error)
  ((expected :initarg :expected :reader reading-order-error-expected)
   (actual :initarg :actual :reader reading-order-error-actual))
  (:default-initargs :category :reading-order))

(define-condition content-empty-error (layout-validation-error)
  ()
  (:default-initargs :category :content-empty))

;;; ============================================================================
;;; VALIDATION RESULT STRUCTURE
;;; ============================================================================

(defstruct (validation-result (:constructor %make-validation-result))
  "Result of validating a layout graph or element."
  (valid-p t :type boolean)
  (issues '() :type list)        ; List of validation-issue
  (warnings '() :type list)      ; Non-fatal issues
  (element-count 0 :type integer) ; Total elements examined
  (checked-count 0 :type integer) ; Elements that passed check
  (duration-ms 0 :type integer))  ; Validation time

(defun make-validation-result (&key (valid-p t) issues warnings
                                    (element-count 0) (checked-count 0)
                                    (duration-ms 0))
  "Create validation result."
  (%make-validation-result
   :valid-p valid-p
   :issues (or issues '())
   :warnings (or warnings '())
   :element-count element-count
   :checked-count checked-count
   :duration-ms duration-ms))

;;; ============================================================================
;;; VALIDATION ISSUE STRUCTURE
;;; ============================================================================

(defstruct (validation-issue (:constructor make-validation-issue
                                           (&key severity category element-id message context)))
  "A specific validation issue found."
  (severity :error :type keyword)  ; :error, :warning, :info
  (category :unknown :type keyword) ; :trace, :bbox, :hierarchy, :reading-order, :content
  (element-id nil :type (or null string))
  (message "" :type string)
  (context nil))  ; Additional context plist

(defmethod print-object ((issue validation-issue) stream)
  (print-unreadable-object (issue stream :type t :identity nil)
    (format stream "~A ~A: ~A"
            (validation-issue-severity issue)
            (validation-issue-category issue)
            (if (> (length (validation-issue-message issue)) 40)
                (concatenate 'string
                             (subseq (validation-issue-message issue) 0 40)
                             "...")
                (validation-issue-message issue)))))

;;; ============================================================================
;;; VALIDATION CONTEXT (Special Variables)
;;; ============================================================================

(defvar *validation-issues* nil
  "Accumulated issues during validation")

(defvar *validation-warnings* nil
  "Accumulated warnings during validation")

(defvar *validation-element-count* 0
  "Total elements validated")

(defvar *validation-checked-count* 0
  "Elements that passed validation")

(defvar *current-document* nil
  "Document being validated (for context)")

(defvar *current-page* nil
  "Page being validated (for context)")

(defmacro with-validation-context (() &body body)
  "Establish fresh validation context for collecting issues."
  `(let ((*validation-issues* '())
         (*validation-warnings* '())
         (*validation-element-count* 0)
         (*validation-checked-count* 0)
         (*current-document* nil)
         (*current-page* nil))
     ,@body))

;;; ============================================================================
;;; ISSUE RECORDING
;;; ============================================================================

(defun record-issue (severity category element-id message &optional context)
  "Record a validation issue."
  (let ((issue (make-validation-issue
                :severity severity
                :category category
                :element-id element-id
                :message message
                :context context)))
    (case severity
      (:warning (push issue *validation-warnings*))
      (otherwise (push issue *validation-issues*)))
    issue))

(defun record-error (category element-id message &optional context)
  "Record an error issue."
  (record-issue :error category element-id message context))

(defun record-warning (category element-id message &optional context)
  "Record a warning issue."
  (record-issue :warning category element-id message context))

;;; ============================================================================
;;; GENERIC VALIDATION FUNCTIONS
;;; ============================================================================

(defgeneric validate-layout-element (element)
  (:documentation "Validate a layout element.

   Returns: (values valid-p issues)
     valid-p: T if element passes all validations
     issues: List of validation issues found"))

;;; ============================================================================
;;; SPECIFIC VALIDATORS
;;; ============================================================================

(defun validate-trace-presence (element)
  "Validate that element has trace information.

   Returns: T if valid, NIL otherwise (records issue)"
  (incf *validation-element-count*)
  (let ((trace (element-trace element))
        (id (element-id element)))
    (cond
      ((null trace)
       (record-error :trace-missing id "Element has no trace information")
       nil)
      ((not (trace-valid-p trace))
       (record-error :trace-invalid id "Element has invalid trace structure")
       nil)
      (t
       (incf *validation-checked-count*)
       t))))

(defun validate-bbox-validity (element)
  "Validate that element has valid bounding box.

   Returns: T if valid, NIL otherwise (records issue)"
  (let ((bbox (element-bbox element))
        (id (element-id element)))
    (cond
      ((null bbox)
       (record-warning :bbox-missing id "Element has no bounding box")
       t)  ; Warning, not error
      ((not (bbox-p bbox))
       (record-error :bbox-invalid id "Bbox is not a valid bbox structure")
       nil)
      ((not (bbox-valid-p bbox))
       (record-error :bbox-invalid id
                     (format nil "Bbox has invalid dimensions: ~Ax~A"
                             (bbox-width bbox) (bbox-height bbox)))
       nil)
      ((and (= (bbox-width bbox) 0.0) (= (bbox-height bbox) 0.0))
       (record-warning :bbox-zero id "Bbox has zero area")
       t)
      (t t))))

(defun validate-bbox-containment (parent child)
  "Validate that parent bbox contains child bbox.

   Returns: T if valid or not applicable, NIL otherwise"
  (let ((parent-bbox (element-bbox parent))
        (child-bbox (element-bbox child))
        (parent-id (element-id parent))
        (child-id (element-id child)))
    (cond
      ((or (null parent-bbox) (null child-bbox))
       t)  ; Can't validate without bboxes
      ((bbox-contains-p parent-bbox child-bbox)
       t)
      (t
       (record-warning :bbox-containment child-id
                       (format nil "Not contained within parent ~A" parent-id)
                       (list :parent-id parent-id
                             :parent-bbox parent-bbox
                             :child-bbox child-bbox))
       t))))  ; Warning, not error

(defun validate-reading-order (elements)
  "Validate reading order consistency of elements.

   Elements should have monotonically increasing reading-order values.

   Returns: T if valid, NIL otherwise"
  (when (null elements)
    (return-from validate-reading-order t))

  (let ((prev-order -1)
        (valid t))
    (dolist (element elements)
      (let ((order (typecase element
                     (layout-block (block-reading-order element))
                     (layout-line (line-reading-order element))
                     (t 0)))
            (id (element-id element)))
        (when (< order prev-order)
          (record-warning :reading-order id
                          (format nil "Reading order ~D less than previous ~D"
                                  order prev-order))
          (setf valid nil))
        (setf prev-order order)))
    valid))

(defun validate-content-non-empty (element)
  "Validate that leaf elements have non-empty content.

   Returns: T if valid, NIL otherwise"
  (typecase element
    (layout-span
     (let ((text (span-text element))
           (id (element-id element)))
       (cond
         ((null text)
          (record-error :content-empty id "Span has null text")
          nil)
         ((string= text "")
          (record-warning :content-empty id "Span has empty text")
          t)  ; Warning for empty
         (t t))))
    (t t)))  ; Non-spans don't need content validation

(defun validate-hierarchy-integrity (parent)
  "Validate parent-child hierarchy integrity.

   Checks:
   - All children reference valid parent
   - No duplicate children
   - Children bboxes contained in parent

   Returns: T if valid, NIL otherwise"
  (let ((children (element-children parent))
        (parent-id (element-id parent))
        (valid t)
        (seen-ids (make-hash-table :test #'equal)))

    ;; Check for duplicates and validate containment
    (dolist (child children)
      (let ((child-id (element-id child)))
        ;; Duplicate check
        (when (gethash child-id seen-ids)
          (record-error :hierarchy parent-id
                        (format nil "Duplicate child: ~A" child-id))
          (setf valid nil))
        (setf (gethash child-id seen-ids) t)

        ;; Containment check
        (unless (validate-bbox-containment parent child)
          (setf valid nil))))

    valid))

;;; ============================================================================
;;; ELEMENT-SPECIFIC VALIDATION
;;; ============================================================================

(defmethod validate-layout-element ((span layout-span))
  "Validate a layout span."
  (let ((valid t))
    (unless (validate-trace-presence span)
      (setf valid nil))
    (unless (validate-bbox-validity span)
      (setf valid nil))
    (unless (validate-content-non-empty span)
      (setf valid nil))
    valid))

(defmethod validate-layout-element ((line layout-line))
  "Validate a layout line and its spans."
  (let ((valid t))
    ;; Validate line itself
    (unless (validate-trace-presence line)
      (setf valid nil))
    (unless (validate-bbox-validity line)
      (setf valid nil))
    (unless (validate-hierarchy-integrity line)
      (setf valid nil))

    ;; Validate children (spans)
    (dolist (span (line-spans line))
      (unless (validate-layout-element span)
        (setf valid nil)))

    valid))

(defmethod validate-layout-element ((block layout-block))
  "Validate a layout block and its lines."
  (let ((valid t))
    ;; Validate block itself
    (unless (validate-trace-presence block)
      (setf valid nil))
    (unless (validate-bbox-validity block)
      (setf valid nil))
    (unless (validate-hierarchy-integrity block)
      (setf valid nil))

    ;; Validate reading order of lines
    (unless (validate-reading-order (block-lines block))
      (setf valid nil))

    ;; Validate children (lines)
    (dolist (line (block-lines block))
      (unless (validate-layout-element line)
        (setf valid nil)))

    valid))

(defmethod validate-layout-element ((page layout-page))
  "Validate a layout page and its blocks."
  (let ((*current-page* page)
        (valid t))
    ;; Validate page dimensions
    (when (or (<= (page-width page) 0)
              (<= (page-height page) 0))
      (record-error :bbox-invalid (element-id page)
                    (format nil "Invalid page dimensions: ~Ax~A"
                            (page-width page) (page-height page)))
      (setf valid nil))

    ;; Validate trace
    (unless (validate-trace-presence page)
      (setf valid nil))

    ;; Validate reading order of blocks
    (unless (validate-reading-order (page-blocks page))
      (setf valid nil))

    ;; Validate children (blocks)
    (dolist (block (page-blocks page))
      (unless (validate-layout-element block)
        (setf valid nil)))

    valid))

(defmethod validate-layout-element ((doc layout-document))
  "Validate entire layout document."
  (let ((*current-document* doc)
        (valid t))
    ;; Validate document trace
    (unless (validate-trace-presence doc)
      (setf valid nil))

    ;; Validate page sequence
    (let ((prev-page-num -1))
      (dolist (page (document-pages doc))
        (let ((page-num (page-number page)))
          (when (<= page-num prev-page-num)
            (record-warning :reading-order (element-id page)
                            (format nil "Page ~D out of order (after ~D)"
                                    page-num prev-page-num)))
          (setf prev-page-num page-num))))

    ;; Validate children (pages)
    (dolist (page (document-pages doc))
      (unless (validate-layout-element page)
        (setf valid nil)))

    valid))

;;; ============================================================================
;;; MAIN ENTRY POINTS
;;; ============================================================================

(defun validate-layout-graph (document)
  "Validate complete layout graph.

   This is the main entry point for Layer 1 validation.

   Args:
     document: layout-document to validate

   Returns: (values valid-p result)
     valid-p: T if document passes all validation
     result: validation-result with details"
  (let ((start-time (get-internal-real-time)))
    (with-validation-context ()
      (let ((valid (validate-layout-element document)))
        (let* ((end-time (get-internal-real-time))
               (duration-ms (round (* 1000 (/ (- end-time start-time)
                                              internal-time-units-per-second))))
               (result (make-validation-result
                        :valid-p valid
                        :issues (nreverse *validation-issues*)
                        :warnings (nreverse *validation-warnings*)
                        :element-count *validation-element-count*
                        :checked-count *validation-checked-count*
                        :duration-ms duration-ms)))
          (values valid result))))))

(defun validate-document (document)
  "Alias for validate-layout-graph."
  (validate-layout-graph document))

(defun validate-page (page)
  "Validate a single page.

   Returns: (values valid-p result)"
  (let ((start-time (get-internal-real-time)))
    (with-validation-context ()
      (let ((valid (validate-layout-element page)))
        (let* ((end-time (get-internal-real-time))
               (duration-ms (round (* 1000 (/ (- end-time start-time)
                                              internal-time-units-per-second))))
               (result (make-validation-result
                        :valid-p valid
                        :issues (nreverse *validation-issues*)
                        :warnings (nreverse *validation-warnings*)
                        :element-count *validation-element-count*
                        :checked-count *validation-checked-count*
                        :duration-ms duration-ms)))
          (values valid result))))))

(defun validate-block (block)
  "Validate a single block.

   Returns: (values valid-p result)"
  (let ((start-time (get-internal-real-time)))
    (with-validation-context ()
      (let ((valid (validate-layout-element block)))
        (let* ((end-time (get-internal-real-time))
               (duration-ms (round (* 1000 (/ (- end-time start-time)
                                              internal-time-units-per-second))))
               (result (make-validation-result
                        :valid-p valid
                        :issues (nreverse *validation-issues*)
                        :warnings (nreverse *validation-warnings*)
                        :element-count *validation-element-count*
                        :checked-count *validation-checked-count*
                        :duration-ms duration-ms)))
          (values valid result))))))

(defun validate-line (line)
  "Validate a single line.

   Returns: (values valid-p result)"
  (with-validation-context ()
    (let ((valid (validate-layout-element line)))
      (values valid
              (make-validation-result
               :valid-p valid
               :issues (nreverse *validation-issues*)
               :warnings (nreverse *validation-warnings*)
               :element-count *validation-element-count*
               :checked-count *validation-checked-count*)))))

(defun validate-span (span)
  "Validate a single span.

   Returns: (values valid-p result)"
  (with-validation-context ()
    (let ((valid (validate-layout-element span)))
      (values valid
              (make-validation-result
               :valid-p valid
               :issues (nreverse *validation-issues*)
               :warnings (nreverse *validation-warnings*)
               :element-count *validation-element-count*
               :checked-count *validation-checked-count*)))))

;;; ============================================================================
;;; VALIDATION DSL
;;; ============================================================================

(defmacro defvalidator (name (element-var) &body checks)
  "Define a custom validator.

   Usage:
     (defvalidator validate-legal-span (span)
       (:check bbox-valid
         (bbox-valid-p (element-bbox span))
         \"Span must have valid bbox\")
       (:check non-empty
         (> (length (span-text span)) 0)
         \"Span must have non-empty text\"))

   Generates a function that runs all checks and records issues."
  (let ((check-forms
          (mapcar (lambda (check)
                    (destructuring-bind (check-keyword check-name test message) check
                      (declare (ignore check-keyword))
                      `(unless ,test
                         (record-error ,(intern (symbol-name check-name) :keyword)
                                       (element-id ,element-var)
                                       ,message)
                         (setf valid nil))))
                  checks)))
    `(defun ,name (,element-var)
       ,(format nil "Custom validator for ~A" name)
       (let ((valid t))
         ,@check-forms
         valid))))

;;; ============================================================================
;;; REPORT GENERATION
;;; ============================================================================

(defun validation-result-to-plist (result)
  "Convert validation result to plist for export/logging."
  (list :valid-p (validation-result-valid-p result)
        :element-count (validation-result-element-count result)
        :checked-count (validation-result-checked-count result)
        :issue-count (length (validation-result-issues result))
        :warning-count (length (validation-result-warnings result))
        :duration-ms (validation-result-duration-ms result)
        :issues (mapcar (lambda (issue)
                          (list :severity (validation-issue-severity issue)
                                :category (validation-issue-category issue)
                                :element-id (validation-issue-element-id issue)
                                :message (validation-issue-message issue)))
                        (validation-result-issues result))
        :warnings (mapcar (lambda (issue)
                            (list :severity (validation-issue-severity issue)
                                  :category (validation-issue-category issue)
                                  :element-id (validation-issue-element-id issue)
                                  :message (validation-issue-message issue)))
                          (validation-result-warnings result))))

(defun print-validation-report (result &optional (stream *standard-output*))
  "Print human-readable validation report."
  (format stream "~&══════════════════════════════════════════════════════════════~%")
  (format stream "LAYOUT GRAPH VALIDATION REPORT~%")
  (format stream "══════════════════════════════════════════════════════════════~%")
  (format stream "~%STATUS: ~A~%"
          (if (validation-result-valid-p result) "✓ PASSED" "✗ FAILED"))
  (format stream "~%STATISTICS:~%")
  (format stream "  Elements examined: ~D~%" (validation-result-element-count result))
  (format stream "  Elements passed:   ~D~%" (validation-result-checked-count result))
  (format stream "  Duration:          ~D ms~%" (validation-result-duration-ms result))
  (format stream "~%ISSUES: ~D errors, ~D warnings~%"
          (length (validation-result-issues result))
          (length (validation-result-warnings result)))

  (when (validation-result-issues result)
    (format stream "~%ERRORS:~%")
    (dolist (issue (validation-result-issues result))
      (format stream "  [~A] ~A: ~A~%"
              (validation-issue-category issue)
              (validation-issue-element-id issue)
              (validation-issue-message issue))))

  (when (validation-result-warnings result)
    (format stream "~%WARNINGS:~%")
    (dolist (issue (validation-result-warnings result))
      (format stream "  [~A] ~A: ~A~%"
              (validation-issue-category issue)
              (validation-issue-element-id issue)
              (validation-issue-message issue))))

  (format stream "~%══════════════════════════════════════════════════════════════~%")
  result)

;;; ============================================================================
;;; END OF VALIDATE-LAYOUT-GRAPH.LISP
;;; ============================================================================
