;;;; source/layout-types.lisp
;;;; ============================================================================
;;;; LAYOUT-TYPES - Layer 1 Structures for Layout Graph
;;;; ============================================================================
;;;;
;;;; LAYER 1: PDF → LAYOUT GRAPH
;;;;
;;;; This module defines the foundational types for extracting and representing
;;;; the visual/geometric structure of PDF pages BEFORE any semantic analysis.
;;;;
;;;; HIERARCHY (bottom-up):
;;;;   bbox   → span   → line   → block   → page   → document
;;;;   ────────────────────────────────────────────────────────
;;;;   Pure geometry → text fragments → text flow → regions
;;;;
;;;; DESIGN PRINCIPLES:
;;;;   1. GEOMETRY FIRST: Extract positions before meaning
;;;;   2. IMMUTABLE: Once created, structures don't change
;;;;   3. TRACEABLE: Every structure carries trace-info
;;;;   4. COMPOSABLE: Structures can be combined/split
;;;;
;;;; ============================================================================
;;;; COMMON LISP FEATURES UTILIZED
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ DEFSTRUCT                │ Efficient bbox representation (no CLOS)      │
;;;; │                          │ • :type vector for memory efficiency         │
;;;; │                          │ • :constructor for named args                │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CLOS (Classes)           │ span, line, block, page, document classes    │
;;;; │                          │ • Typed slots with defaults                  │
;;;; │                          │ • print-object specialization                │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ GENERIC FUNCTIONS        │ Polymorphic operations                       │
;;;; │                          │ • element-bbox: get bbox from any element    │
;;;; │                          │ • element-text: extract text from any level  │
;;;; │                          │ • element-children: tree navigation          │
;;;; │                          │ • element-to-form: homoiconicity             │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Rich returns for geometric operations        │
;;;; │                          │ • bbox-corners → (x1 y1 x2 y2)               │
;;;; │                          │ • bbox-center → (cx cy)                      │
;;;; │                          │ • reading-order-score → (score confidence)   │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CONDITIONS               │ Layout-specific error hierarchy              │
;;;; │                          │ • layout-error, bbox-error, overlap-error    │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MACROS                   │ DSL for layout construction                  │
;;;; │                          │ • with-page-coordinates                      │
;;;; │                          │ • deflayout-element                          │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ HOMOICONICITY            │ All structures serializable as Lisp forms    │
;;;; │                          │ • element-to-form / form-to-element          │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(defpackage :orchestrator.layout-types
  (:use :cl)
  (:import-from :orchestrator.trace-core
                #:trace-info
                #:make-trace-info
                #:trace-id
                #:trace-pages
                #:trace-bboxes
                #:generate-deterministic-trace-id)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; BOUNDING BOX (DEFSTRUCT - efficient)
   ;; ══════════════════════════════════════════════════════════════════
   #:bbox
   #:make-bbox
   #:bbox-x
   #:bbox-y
   #:bbox-width
   #:bbox-height
   #:bbox-p
   #:copy-bbox

   ;; Bbox operations
   #:bbox-x2
   #:bbox-y2
   #:bbox-corners
   #:bbox-center
   #:bbox-area
   #:bbox-union
   #:bbox-intersection
   #:bbox-contains-p
   #:bbox-overlaps-p
   #:bbox-overlap-area
   #:bbox-distance
   #:bbox-equal-p
   #:bbox-valid-p
   #:normalize-bbox

   ;; ══════════════════════════════════════════════════════════════════
   ;; FONT INFO (DEFSTRUCT)
   ;; ══════════════════════════════════════════════════════════════════
   #:font-info
   #:make-font-info
   #:font-info-name
   #:font-info-size
   #:font-info-bold-p
   #:font-info-italic-p
   #:font-info-monospace-p
   #:font-info-p

   ;; ══════════════════════════════════════════════════════════════════
   ;; SPAN (Character-level unit)
   ;; ══════════════════════════════════════════════════════════════════
   #:layout-span
   #:make-layout-span
   #:span-id
   #:span-text
   #:span-bbox
   #:span-font
   #:span-color
   #:span-baseline
   #:span-char-spacing
   #:span-trace

   ;; ══════════════════════════════════════════════════════════════════
   ;; LINE (Collection of spans)
   ;; ══════════════════════════════════════════════════════════════════
   #:layout-line
   #:make-layout-line
   #:line-id
   #:line-spans
   #:line-bbox
   #:line-baseline
   #:line-reading-order
   #:line-trace
   #:line-text

   ;; ══════════════════════════════════════════════════════════════════
   ;; BLOCK (Collection of lines)
   ;; ══════════════════════════════════════════════════════════════════
   #:layout-block
   #:make-layout-block
   #:block-id
   #:block-lines
   #:block-bbox
   #:block-reading-order
   #:block-column-index
   #:block-trace
   #:block-text

   ;; ══════════════════════════════════════════════════════════════════
   ;; PAGE (Collection of blocks)
   ;; ══════════════════════════════════════════════════════════════════
   #:layout-page
   #:make-layout-page
   #:page-number
   #:page-blocks
   #:page-width
   #:page-height
   #:page-rotation
   #:page-trace

   ;; ══════════════════════════════════════════════════════════════════
   ;; DOCUMENT (Collection of pages)
   ;; ══════════════════════════════════════════════════════════════════
   #:layout-document
   #:make-layout-document
   #:document-id
   #:document-source-file
   #:document-pages
   #:document-trace

   ;; ══════════════════════════════════════════════════════════════════
   ;; GENERIC FUNCTIONS (Polymorphic operations)
   ;; ══════════════════════════════════════════════════════════════════
   #:element-bbox
   #:element-text
   #:element-children
   #:element-trace
   #:element-id
   #:element-to-form
   #:form-to-element

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONDITIONS
   ;; ══════════════════════════════════════════════════════════════════
   #:layout-error
   #:layout-error-message
   #:layout-decode-error
   #:bbox-error
   #:bbox-invalid-error
   #:overlap-error
   #:reading-order-error

   ;; ══════════════════════════════════════════════════════════════════
   ;; READING ORDER & COLUMN DETECTION
   ;; ══════════════════════════════════════════════════════════════════
   #:compute-reading-order
   #:reading-order-score
   #:sort-by-reading-order
   #:detect-column-count

   ;; ══════════════════════════════════════════════════════════════════
   ;; DSL MACROS
   ;; ══════════════════════════════════════════════════════════════════
   #:with-page-coordinates
   #:deflayout-element))

(in-package :orchestrator.layout-types)

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition layout-error (error)
  ((message :initarg :message :reader layout-error-message :initform "Layout error"))
  (:report (lambda (c s)
             (format s "Layout Error: ~A" (layout-error-message c)))))

(define-condition bbox-error (layout-error)
  ((bbox :initarg :bbox :reader bbox-error-bbox :initform nil))
  (:report (lambda (c s)
             (format s "Bbox Error~@[ (~A)~]: ~A"
                     (bbox-error-bbox c)
                     (layout-error-message c)))))

(define-condition bbox-invalid-error (bbox-error)
  ((reason :initarg :reason :reader bbox-invalid-reason :initform "invalid"))
  (:report (lambda (c s)
             (format s "Invalid Bbox: ~A" (bbox-invalid-reason c)))))

(define-condition overlap-error (layout-error)
  ((element1 :initarg :element1 :reader overlap-error-element1)
   (element2 :initarg :element2 :reader overlap-error-element2))
  (:report (lambda (c s)
             (format s "Overlap Error between ~A and ~A"
                     (overlap-error-element1 c)
                     (overlap-error-element2 c)))))

(define-condition reading-order-error (layout-error)
  ((elements :initarg :elements :reader reading-order-error-elements))
  (:report (lambda (c s)
             (format s "Reading Order Error: ~A"
                     (layout-error-message c)))))

;;; ============================================================================
;;; BOUNDING BOX (DEFSTRUCT for efficiency)
;;; ============================================================================
;;;
;;; Using defstruct instead of defclass for bbox:
;;;   - More memory efficient (no slot allocation overhead)
;;;   - Faster access (direct structure access vs CLOS dispatch)
;;;   - BOX used in thousands of instances per page
;;;
;;; Coordinate system: PDF standard (origin at bottom-left)
;;;   x: horizontal position from left edge
;;;   y: vertical position from bottom edge
;;;   width: horizontal extent (must be >= 0)
;;;   height: vertical extent (must be >= 0)

(defstruct (bbox (:constructor %make-bbox (x y width height))
                 (:copier copy-bbox)
                 (:predicate bbox-p))
  "Bounding box with PDF coordinates (origin bottom-left)."
  (x 0.0 :type single-float :read-only t)
  (y 0.0 :type single-float :read-only t)
  (width 0.0 :type single-float :read-only t)
  (height 0.0 :type single-float :read-only t))

(defun make-bbox (&key (x 0.0) (y 0.0) (width 0.0) (height 0.0))
  "Create a bounding box with validation.

   Args:
     x: Left edge x-coordinate
     y: Bottom edge y-coordinate
     width: Horizontal extent (>= 0)
     height: Vertical extent (>= 0)

   Returns:
     bbox structure

   Signals:
     bbox-invalid-error if width or height is negative"
  (let ((fx (coerce x 'single-float))
        (fy (coerce y 'single-float))
        (fw (coerce width 'single-float))
        (fh (coerce height 'single-float)))
    (when (< fw 0.0)
      (error 'bbox-invalid-error
             :reason (format nil "Negative width: ~A" fw)))
    (when (< fh 0.0)
      (error 'bbox-invalid-error
             :reason (format nil "Negative height: ~A" fh)))
    (%make-bbox fx fy fw fh)))

;;; ============================================================================
;;; BBOX OPERATIONS
;;; ============================================================================

(defun bbox-x2 (bbox)
  "Return right edge x-coordinate."
  (+ (bbox-x bbox) (bbox-width bbox)))

(defun bbox-y2 (bbox)
  "Return top edge y-coordinate."
  (+ (bbox-y bbox) (bbox-height bbox)))

(defun bbox-corners (bbox)
  "Return all four corner coordinates.

   Returns: (values x1 y1 x2 y2)
     x1, y1: bottom-left corner
     x2, y2: top-right corner"
  (values (bbox-x bbox)
          (bbox-y bbox)
          (bbox-x2 bbox)
          (bbox-y2 bbox)))

(defun bbox-center (bbox)
  "Return center point of bbox.

   Returns: (values cx cy)"
  (values (+ (bbox-x bbox) (/ (bbox-width bbox) 2.0))
          (+ (bbox-y bbox) (/ (bbox-height bbox) 2.0))))

(defun bbox-area (bbox)
  "Return area of bounding box."
  (* (bbox-width bbox) (bbox-height bbox)))

(defun bbox-valid-p (bbox)
  "Check if bbox is structurally valid."
  (and (bbox-p bbox)
       (>= (bbox-width bbox) 0.0)
       (>= (bbox-height bbox) 0.0)))

(defun normalize-bbox (bbox)
  "Normalize bbox to ensure positive width/height.

   If width or height is negative, flip coordinates."
  (let ((x1 (bbox-x bbox))
        (y1 (bbox-y bbox))
        (x2 (bbox-x2 bbox))
        (y2 (bbox-y2 bbox)))
    (make-bbox :x (min x1 x2)
               :y (min y1 y2)
               :width (abs (- x2 x1))
               :height (abs (- y2 y1)))))

(defun bbox-union (bbox1 bbox2)
  "Return smallest bbox containing both inputs.

   Returns: new bbox"
  (multiple-value-bind (ax1 ay1 ax2 ay2) (bbox-corners bbox1)
    (multiple-value-bind (bx1 by1 bx2 by2) (bbox-corners bbox2)
      (let ((x1 (min ax1 bx1))
            (y1 (min ay1 by1))
            (x2 (max ax2 bx2))
            (y2 (max ay2 by2)))
        (make-bbox :x x1 :y y1
                   :width (- x2 x1)
                   :height (- y2 y1))))))

(defun bbox-intersection (bbox1 bbox2)
  "Return intersection of two bboxes, or NIL if no overlap.

   Returns: bbox or NIL"
  (multiple-value-bind (ax1 ay1 ax2 ay2) (bbox-corners bbox1)
    (multiple-value-bind (bx1 by1 bx2 by2) (bbox-corners bbox2)
      (let ((x1 (max ax1 bx1))
            (y1 (max ay1 by1))
            (x2 (min ax2 bx2))
            (y2 (min ay2 by2)))
        (when (and (<= x1 x2) (<= y1 y2))
          (make-bbox :x x1 :y y1
                     :width (- x2 x1)
                     :height (- y2 y1)))))))

(defun bbox-contains-p (outer inner)
  "Check if OUTER bbox fully contains INNER bbox."
  (multiple-value-bind (ox1 oy1 ox2 oy2) (bbox-corners outer)
    (multiple-value-bind (ix1 iy1 ix2 iy2) (bbox-corners inner)
      (and (<= ox1 ix1) (<= oy1 iy1)
           (>= ox2 ix2) (>= oy2 iy2)))))

(defun bbox-overlaps-p (bbox1 bbox2)
  "Check if two bboxes overlap."
  (not (null (bbox-intersection bbox1 bbox2))))

(defun bbox-overlap-area (bbox1 bbox2)
  "Return area of overlap between two bboxes (0 if none)."
  (let ((intersection (bbox-intersection bbox1 bbox2)))
    (if intersection
        (bbox-area intersection)
        0.0)))

(defun bbox-distance (bbox1 bbox2)
  "Return minimum distance between two bboxes.
   Returns 0 if they overlap.

   Returns: (values distance dx dy)
     distance: Euclidean distance
     dx: horizontal gap (negative if overlapping)
     dy: vertical gap (negative if overlapping)"
  (multiple-value-bind (ax1 ay1 ax2 ay2) (bbox-corners bbox1)
    (multiple-value-bind (bx1 by1 bx2 by2) (bbox-corners bbox2)
      (let ((dx (cond ((< ax2 bx1) (- bx1 ax2))  ; bbox1 left of bbox2
                      ((< bx2 ax1) (- ax1 bx2))  ; bbox2 left of bbox1
                      (t 0.0)))                   ; overlap in x
            (dy (cond ((< ay2 by1) (- by1 ay2))  ; bbox1 below bbox2
                      ((< by2 ay1) (- ay1 by2))  ; bbox2 below bbox1
                      (t 0.0))))                  ; overlap in y
        (values (sqrt (+ (* dx dx) (* dy dy)))
                dx
                dy)))))

(defun bbox-equal-p (bbox1 bbox2 &key (tolerance 0.001))
  "Check if two bboxes are equal within tolerance."
  (and (< (abs (- (bbox-x bbox1) (bbox-x bbox2))) tolerance)
       (< (abs (- (bbox-y bbox1) (bbox-y bbox2))) tolerance)
       (< (abs (- (bbox-width bbox1) (bbox-width bbox2))) tolerance)
       (< (abs (- (bbox-height bbox1) (bbox-height bbox2))) tolerance)))

;;; ============================================================================
;;; FONT INFO (DEFSTRUCT for efficiency)
;;; ============================================================================

(defstruct (font-info (:constructor make-font-info
                                    (&key name size bold-p italic-p monospace-p))
                      (:predicate font-info-p))
  "Font information for a text span."
  (name "Unknown" :type string :read-only t)
  (size 12.0 :type single-float :read-only t)
  (bold-p nil :type boolean :read-only t)
  (italic-p nil :type boolean :read-only t)
  (monospace-p nil :type boolean :read-only t))

;;; ============================================================================
;;; LAYOUT-SPAN (Character-level unit with CLOS)
;;; ============================================================================

(defvar *span-counter* 0)

(defclass layout-span ()
  ((id
    :accessor span-id
    :initarg :id
    :type string
    :documentation "Unique identifier for this span")

   (text
    :accessor span-text
    :initarg :text
    :initform ""
    :type string
    :documentation "Text content of this span")

   (bbox
    :accessor span-bbox
    :initarg :bbox
    :type bbox
    :documentation "Bounding box of this span")

   (font
    :accessor span-font
    :initarg :font
    :initform nil
    :type (or null font-info)
    :documentation "Font information")

   (color
    :accessor span-color
    :initarg :color
    :initform nil
    :type (or null list)  ; (r g b) 0-255
    :documentation "Text color as RGB list")

   (baseline
    :accessor span-baseline
    :initarg :baseline
    :initform nil
    :type (or null single-float)
    :documentation "Y-coordinate of text baseline")

   (char-spacing
    :accessor span-char-spacing
    :initarg :char-spacing
    :initform 0.0
    :type single-float
    :documentation "Character spacing adjustment")

   (trace
    :accessor span-trace
    :initarg :trace
    :initform nil
    :type (or null trace-info)
    :documentation "Traceability info"))

  (:documentation "Character-level text unit with position and style.

   A span is the atomic unit of the layout graph - a contiguous run
   of characters with uniform style (font, size, color)."))

(defun make-layout-span (&key text bbox font color baseline char-spacing
                              source-file page-number)
  "Create a layout span with auto-generated ID and trace."
  (let* ((id (format nil "SPAN-~A" (incf *span-counter*)))
         (trace (when (and source-file page-number bbox)
                  (make-trace-info
                   :source-file source-file
                   :source-pages (list page-number)
                   :source-bboxes (list (list (bbox-x bbox)
                                              (bbox-y bbox)
                                              (bbox-width bbox)
                                              (bbox-height bbox)))
                   :raw-text text
                   :layout-block-ids (list id)
                   :layer :layout))))
    (make-instance 'layout-span
                   :id id
                   :text (or text "")
                   :bbox bbox
                   :font font
                   :color color
                   :baseline baseline
                   :char-spacing (or char-spacing 0.0)
                   :trace trace)))

(defmethod print-object ((span layout-span) stream)
  (print-unreadable-object (span stream :type t :identity nil)
    (format stream "~A ~S" (span-id span)
            (if (> (length (span-text span)) 20)
                (concatenate 'string (subseq (span-text span) 0 20) "...")
                (span-text span)))))

;;; ============================================================================
;;; LAYOUT-LINE (Collection of spans)
;;; ============================================================================

(defvar *line-counter* 0)

(defclass layout-line ()
  ((id
    :accessor line-id
    :initarg :id
    :type string)

   (spans
    :accessor line-spans
    :initarg :spans
    :initform '()
    :type list
    :documentation "List of layout-span objects in reading order")

   (bbox
    :accessor line-bbox
    :initarg :bbox
    :type (or null bbox)
    :documentation "Bounding box of entire line")

   (baseline
    :accessor line-baseline
    :initarg :baseline
    :initform nil
    :type (or null single-float)
    :documentation "Common baseline for all spans")

   (reading-order
    :accessor line-reading-order
    :initarg :reading-order
    :initform 0
    :type integer
    :documentation "Position in reading order (0-indexed)")

   (trace
    :accessor line-trace
    :initarg :trace
    :initform nil
    :type (or null trace-info)))

  (:documentation "A line of text composed of spans.

   Lines are horizontal sequences of spans that form a logical text line.
   The bbox is computed from the union of all span bboxes."))

(defun make-layout-line (&key spans reading-order source-file page-number)
  "Create a layout line from spans, computing bbox automatically."
  (let* ((id (format nil "LINE-~A" (incf *line-counter*)))
         (computed-bbox (when spans
                          (reduce #'bbox-union
                                  (mapcar #'span-bbox spans))))
         (combined-text (format nil "~{~A~}"
                                (mapcar #'span-text spans)))
         (trace (when (and source-file page-number computed-bbox)
                  (make-trace-info
                   :source-file source-file
                   :source-pages (list page-number)
                   :source-bboxes (when computed-bbox
                                    (list (list (bbox-x computed-bbox)
                                                (bbox-y computed-bbox)
                                                (bbox-width computed-bbox)
                                                (bbox-height computed-bbox))))
                   :raw-text combined-text
                   :layout-block-ids (cons id (mapcar #'span-id spans))
                   :layer :layout))))
    (make-instance 'layout-line
                   :id id
                   :spans (or spans '())
                   :bbox computed-bbox
                   :reading-order (or reading-order 0)
                   :trace trace)))

(defun line-text (line)
  "Extract concatenated text from all spans in line."
  (format nil "~{~A~}" (mapcar #'span-text (line-spans line))))

(defmethod print-object ((line layout-line) stream)
  (print-unreadable-object (line stream :type t :identity nil)
    (format stream "~A ~D spans" (line-id line) (length (line-spans line)))))

;;; ============================================================================
;;; LAYOUT-BLOCK (Collection of lines)
;;; ============================================================================

(defvar *block-counter* 0)

(defclass layout-block ()
  ((id
    :accessor block-id
    :initarg :id
    :type string)

   (lines
    :accessor block-lines
    :initarg :lines
    :initform '()
    :type list
    :documentation "List of layout-line objects in reading order")

   (bbox
    :accessor block-bbox
    :initarg :bbox
    :type (or null bbox))

   (reading-order
    :accessor block-reading-order
    :initarg :reading-order
    :initform 0
    :type integer
    :documentation "Position in page reading order")

   (column-index
    :accessor block-column-index
    :initarg :column-index
    :initform 0
    :type integer
    :documentation "Column index for multi-column layouts (0-indexed)")

   (trace
    :accessor block-trace
    :initarg :trace
    :initform nil
    :type (or null trace-info)))

  (:documentation "A block of text composed of lines.

   Blocks are rectangular regions containing related lines.
   Used for paragraphs, headers, footers, sidebars, etc."))

(defun make-layout-block (&key lines reading-order column-index
                               source-file page-number)
  "Create a layout block from lines, computing bbox automatically."
  (let* ((id (format nil "BLOCK-~A" (incf *block-counter*)))
         (computed-bbox (when lines
                          (reduce #'bbox-union
                                  (remove nil (mapcar #'line-bbox lines)))))
         (combined-text (format nil "~{~A~%~}"
                                (mapcar #'line-text lines)))
         (trace (when (and source-file page-number computed-bbox)
                  (make-trace-info
                   :source-file source-file
                   :source-pages (list page-number)
                   :source-bboxes (when computed-bbox
                                    (list (list (bbox-x computed-bbox)
                                                (bbox-y computed-bbox)
                                                (bbox-width computed-bbox)
                                                (bbox-height computed-bbox))))
                   :raw-text combined-text
                   :layout-block-ids (cons id (mapcar #'line-id lines))
                   :layer :layout))))
    (make-instance 'layout-block
                   :id id
                   :lines (or lines '())
                   :bbox computed-bbox
                   :reading-order (or reading-order 0)
                   :column-index (or column-index 0)
                   :trace trace)))

(defun block-text (block)
  "Extract concatenated text from all lines in block."
  (format nil "~{~A~%~}" (mapcar #'line-text (block-lines block))))

(defmethod print-object ((block layout-block) stream)
  (print-unreadable-object (block stream :type t :identity nil)
    (format stream "~A ~D lines col:~D"
            (block-id block)
            (length (block-lines block))
            (block-column-index block))))

;;; ============================================================================
;;; LAYOUT-PAGE (Collection of blocks)
;;; ============================================================================

(defclass layout-page ()
  ((page-number
    :accessor page-number
    :initarg :page-number
    :initform 0
    :type integer
    :documentation "Page number (0-indexed)")

   (blocks
    :accessor page-blocks
    :initarg :blocks
    :initform '()
    :type list
    :documentation "List of layout-block objects in reading order")

   (width
    :accessor page-width
    :initarg :width
    :initform 612.0  ; Letter size default
    :type single-float)

   (height
    :accessor page-height
    :initarg :height
    :initform 792.0  ; Letter size default
    :type single-float)

   (rotation
    :accessor page-rotation
    :initarg :rotation
    :initform 0
    :type integer
    :documentation "Page rotation in degrees (0, 90, 180, 270)")

   (trace
    :accessor page-trace
    :initarg :trace
    :initform nil
    :type (or null trace-info)))

  (:documentation "A single page of the document.

   Contains all blocks for this page with dimensions and rotation."))

(defun make-layout-page (&key page-number blocks width height rotation
                              source-file)
  "Create a layout page with trace."
  (let* ((computed-bbox (make-bbox :x 0.0 :y 0.0
                                   :width (or width 612.0)
                                   :height (or height 792.0)))
         (trace (when source-file
                  (make-trace-info
                   :source-file source-file
                   :source-pages (list (or page-number 0))
                   :source-bboxes (list (list 0.0 0.0
                                              (or width 612.0)
                                              (or height 792.0)))
                   :layout-block-ids (when blocks
                                       (mapcar #'block-id blocks))
                   :layer :layout))))
    (make-instance 'layout-page
                   :page-number (or page-number 0)
                   :blocks (or blocks '())
                   :width (coerce (or width 612.0) 'single-float)
                   :height (coerce (or height 792.0) 'single-float)
                   :rotation (or rotation 0)
                   :trace trace)))

(defmethod print-object ((page layout-page) stream)
  (print-unreadable-object (page stream :type t :identity nil)
    (format stream "P~D ~Dx~D ~D blocks"
            (page-number page)
            (round (page-width page))
            (round (page-height page))
            (length (page-blocks page)))))

;;; ============================================================================
;;; LAYOUT-DOCUMENT (Collection of pages)
;;; ============================================================================

(defvar *document-counter* 0)

(defclass layout-document ()
  ((id
    :accessor document-id
    :initarg :id
    :type string)

   (source-file
    :accessor document-source-file
    :initarg :source-file
    :type (or null string pathname)
    :documentation "Path to source PDF file")

   (pages
    :accessor document-pages
    :initarg :pages
    :initform '()
    :type list
    :documentation "List of layout-page objects")

   (trace
    :accessor document-trace
    :initarg :trace
    :initform nil
    :type (or null trace-info)))

  (:documentation "Complete layout graph for a document.

   Root of the layout hierarchy containing all pages."))

(defun make-layout-document (&key source-file pages)
  "Create a layout document with trace."
  (let* ((id (format nil "DOC-~A" (incf *document-counter*)))
         (page-numbers (when pages
                         (mapcar #'page-number pages)))
         (trace (when source-file
                  (make-trace-info
                   :source-file source-file
                   :source-pages page-numbers
                   :layout-block-ids (list id)
                   :layer :layout))))
    (make-instance 'layout-document
                   :id id
                   :source-file source-file
                   :pages (or pages '())
                   :trace trace)))

(defmethod print-object ((doc layout-document) stream)
  (print-unreadable-object (doc stream :type t :identity nil)
    (format stream "~A ~D pages"
            (document-id doc)
            (length (document-pages doc)))))

;;; ============================================================================
;;; GENERIC FUNCTIONS (Polymorphic operations)
;;; ============================================================================

(defgeneric element-bbox (element)
  (:documentation "Get bounding box of any layout element."))

(defmethod element-bbox ((span layout-span))
  (span-bbox span))

(defmethod element-bbox ((line layout-line))
  (line-bbox line))

(defmethod element-bbox ((block layout-block))
  (block-bbox block))

(defmethod element-bbox ((page layout-page))
  (make-bbox :x 0.0 :y 0.0
             :width (page-width page)
             :height (page-height page)))

(defgeneric element-text (element)
  (:documentation "Extract text from any layout element."))

(defmethod element-text ((span layout-span))
  (span-text span))

(defmethod element-text ((line layout-line))
  (line-text line))

(defmethod element-text ((block layout-block))
  (block-text block))

(defmethod element-text ((page layout-page))
  (format nil "~{~A~}" (mapcar #'block-text (page-blocks page))))

(defmethod element-text ((doc layout-document))
  (format nil "~{~A~}" (mapcar #'element-text (document-pages doc))))

(defgeneric element-children (element)
  (:documentation "Get child elements in hierarchy."))

(defmethod element-children ((span layout-span))
  nil)  ; Spans have no children

(defmethod element-children ((line layout-line))
  (line-spans line))

(defmethod element-children ((block layout-block))
  (block-lines block))

(defmethod element-children ((page layout-page))
  (page-blocks page))

(defmethod element-children ((doc layout-document))
  (document-pages doc))

(defgeneric element-trace (element)
  (:documentation "Get trace info from any layout element."))

(defmethod element-trace ((span layout-span))
  (span-trace span))

(defmethod element-trace ((line layout-line))
  (line-trace line))

(defmethod element-trace ((block layout-block))
  (block-trace block))

(defmethod element-trace ((page layout-page))
  (page-trace page))

(defmethod element-trace ((doc layout-document))
  (document-trace doc))

(defgeneric element-id (element)
  (:documentation "Get unique ID of any layout element."))

(defmethod element-id ((span layout-span))
  (span-id span))

(defmethod element-id ((line layout-line))
  (line-id line))

(defmethod element-id ((block layout-block))
  (block-id block))

(defmethod element-id ((page layout-page))
  (format nil "PAGE-~D" (page-number page)))

(defmethod element-id ((doc layout-document))
  (document-id doc))

;;; ============================================================================
;;; HOMOICONICITY - ELEMENT TO/FROM FORM
;;; ============================================================================

;;; [ARCH Phase 1] ΑΝΑΒΑΘΜΙΣΗ (όχι αφαίρεση): το παλιό ζεύγος παρήγαγε
;;; (make-instance …) ΚΩΔΙΚΑ και τον ΕΚΤΕΛΟΥΣΕ με form-to-element = (eval form) —
;;; «Data becomes code becomes data» = homoiconic RCE seat (αυθαίρετη εκτέλεση από
;;; «σχήμα»). Η ΙΚΑΝΟΤΗΤΑ (serialize↔reconstruct layout element) διατηρείται με τα
;;; ΙΔΙΑ exported ονόματα· ο ΜΗΧΑΝΙΣΜΟΣ αναβαθμίζεται: element-to-form παράγει
;;; DATA-ONLY versioned plist (keywords/strings/numbers/lists — κανένα constructor
;;; symbol) και form-to-element είναι TYPED DECODER που ανασυγκροτεί μέσω των
;;; κανονικών constructors, ΧΩΡΙΣ eval. data ≠ code· reconstruct ≠ eval.

(defparameter +layout-schema-tags+
  '(:layout-bbox/1 :layout-font/1 :layout-span/1 :layout-line/1
    :layout-block/1 :layout-page/1 :layout-document/1)
  "Κλειστό σύνολο έγκυρων tags της data-only layout αναπαράστασης.")

(define-condition layout-decode-error (layout-error)
  ((datum :initarg :datum :reader layout-decode-error-datum :initform nil))
  (:report (lambda (c s)
             (format s "layout-decode: ~A~@[ [~S]~]"
                     (layout-error-message c) (layout-decode-error-datum c)))))

(defgeneric element-to-form (element)
  (:documentation "Serialize layout element σε DATA-ONLY versioned plist (όχι κώδικα).
   Αντίστροφο: form-to-element (typed decoder, καμία eval)."))

(defmethod element-to-form ((bbox bbox))
  (list :layout-bbox/1 :x (bbox-x bbox) :y (bbox-y bbox)
        :width (bbox-width bbox) :height (bbox-height bbox)))

(defmethod element-to-form ((font font-info))
  (list :layout-font/1 :name (font-info-name font) :size (font-info-size font)
        :bold-p (and (font-info-bold-p font) t)
        :italic-p (and (font-info-italic-p font) t)
        :monospace-p (and (font-info-monospace-p font) t)))

(defmethod element-to-form ((span layout-span))
  (list :layout-span/1
        :id (span-id span) :text (span-text span)
        :bbox (when (span-bbox span) (element-to-form (span-bbox span)))
        :font (when (span-font span) (element-to-form (span-font span)))
        :color (span-color span)
        :baseline (span-baseline span) :char-spacing (span-char-spacing span)))

(defmethod element-to-form ((line layout-line))
  (list :layout-line/1
        :id (line-id line)
        :spans (mapcar #'element-to-form (line-spans line))
        :bbox (when (line-bbox line) (element-to-form (line-bbox line)))
        :baseline (line-baseline line) :reading-order (line-reading-order line)))

(defmethod element-to-form ((block layout-block))
  (list :layout-block/1
        :id (block-id block)
        :lines (mapcar #'element-to-form (block-lines block))
        :bbox (when (block-bbox block) (element-to-form (block-bbox block)))
        :reading-order (block-reading-order block) :column-index (block-column-index block)))

(defmethod element-to-form ((page layout-page))
  (list :layout-page/1
        :page-number (page-number page)
        :blocks (mapcar #'element-to-form (page-blocks page))
        :width (page-width page) :height (page-height page) :rotation (page-rotation page)))

(defmethod element-to-form ((doc layout-document))
  (list :layout-document/1
        :id (document-id doc)
        :source-file (when (document-source-file doc) (namestring (document-source-file doc)))
        :pages (mapcar #'element-to-form (document-pages doc))))

(defun %layout-plist (data tag allowed required)
  "[κύκλος-2] STRICT: DATA = (TAG :k v …) με ΑΡΤΙΟ plist, keyword κλειδιά, ΚΑΝΕΝΑ διπλό,
   ΚΑΝΕΝΑ unknown (keys ⊆ ALLOWED) και ΟΛΑ τα REQUIRED παρόντα. Επιστρέφει το plist."
  (unless (and (consp data) (eq (first data) tag) (evenp (length (rest data))))
    (error 'layout-decode-error :message (format nil "περίμενα άρτιο ~A plist" tag) :datum data))
  (let* ((plist (rest data))
         (keys (loop for (k) on plist by #'cddr collect k)))
    (unless (every #'keywordp keys)
      (error 'layout-decode-error :message "μη-keyword κλειδί" :datum data))
    (unless (= (length keys) (length (remove-duplicates keys)))
      (error 'layout-decode-error :message "διπλό κλειδί" :datum data))
    (let ((unknown (set-difference keys allowed)))
      (when unknown (error 'layout-decode-error :message (format nil "άγνωστα πεδία: ~S" unknown) :datum data)))
    (dolist (r required)
      (unless (member r keys)
        (error 'layout-decode-error :message (format nil "λείπει υποχρεωτικό πεδίο ~S" r) :datum data)))
    plist))

(defun %num (v where) (unless (numberp v) (error 'layout-decode-error :message (format nil "~A: όχι αριθμός" where) :datum v)) v)
(defun %str? (v where) (when v (unless (stringp v) (error 'layout-decode-error :message (format nil "~A: όχι string" where) :datum v))) v)
(defun %bool (v where)
  "[κύκλος-2] STRICT boolean: ΜΟΝΟ t/:t ⇒ t, nil/:nil ⇒ nil· ΟΤΙΔΗΠΟΤΕ ΑΛΛΟ (:evil, \"yes\",
   123) ⇒ layout-decode-error — ΟΧΙ σιωπηλή μετατροπή σε false."
  (cond ((or (eq v t) (eq v :t)) t)
        ((or (null v) (eq v :nil)) nil)
        (t (error 'layout-decode-error :message (format nil "~A: όχι boolean (t/:t/nil/:nil)" where) :datum v))))
(defun %color? (v)
  (unless (or (null v) (keywordp v) (stringp v) (and (listp v) (every #'numberp v)))
    (error 'layout-decode-error :message "color: μόνο keyword/string/number-list/nil" :datum v))
  v)

(defun form-to-element (form)
  "TYPED DECODER: validated DATA-ONLY layout plist → layout element ΧΩΡΙΣ eval. STRICT:
   allowed+required key set ανά schema, strict boolean, tag-specific child types (spans μόνο
   layout-span, lines μόνο layout-line, blocks μόνο layout-block, pages μόνο layout-page)·
   άγνωστο/κακοσχηματισμένο tag ⇒ layout-decode-error (fail-closed)."
  (labels ((child (v where type)
             (let ((el (form-to-element v)))
               (unless (typep el type)
                 (error 'layout-decode-error
                        :message (format nil "~A: περίμενα ~A, βρέθηκε ~A" where type (type-of el)) :datum v))
               el))
           (opt-child (v where type) (and v (child v where type)))   ; nested ή nil
           (children (v where type)
             (unless (listp v) (error 'layout-decode-error :message (format nil "~A: όχι λίστα" where) :datum v))
             (mapcar (lambda (x) (child x where type)) v)))
    (unless (and (consp form) (member (first form) +layout-schema-tags+))
      (error 'layout-decode-error :message "άγνωστο/κακοσχηματισμένο layout tag"
                                  :datum (and (consp form) (first form))))
    (ecase (first form)
      (:layout-bbox/1
       (let ((p (%layout-plist form :layout-bbox/1 '(:x :y :width :height) '(:x :y :width :height))))
         (make-bbox :x (%num (getf p :x) :x) :y (%num (getf p :y) :y)
                    :width (%num (getf p :width) :width) :height (%num (getf p :height) :height))))
      (:layout-font/1
       (let ((p (%layout-plist form :layout-font/1 '(:name :size :bold-p :italic-p :monospace-p)
                               '(:name :size :bold-p :italic-p :monospace-p))))
         (make-font-info :name (%str? (getf p :name) :name) :size (%num (getf p :size) :size)
                         :bold-p (%bool (getf p :bold-p) :bold-p) :italic-p (%bool (getf p :italic-p) :italic-p)
                         :monospace-p (%bool (getf p :monospace-p) :monospace-p))))
      (:layout-span/1
       (let ((p (%layout-plist form :layout-span/1 '(:id :text :bbox :font :color :baseline :char-spacing)
                               '(:id :text :bbox :font :color :baseline :char-spacing))))
         (make-instance 'layout-span
                        :id (%str? (getf p :id) :id) :text (%str? (getf p :text) :text)
                        :bbox (opt-child (getf p :bbox) :bbox 'bbox)
                        :font (opt-child (getf p :font) :font 'font-info)
                        :color (%color? (getf p :color))
                        :baseline (%num (getf p :baseline) :baseline)
                        :char-spacing (%num (getf p :char-spacing) :char-spacing))))
      (:layout-line/1
       (let ((p (%layout-plist form :layout-line/1 '(:id :spans :bbox :baseline :reading-order)
                               '(:id :spans :bbox :baseline :reading-order))))
         (make-instance 'layout-line
                        :id (%str? (getf p :id) :id)
                        :spans (children (getf p :spans) :spans 'layout-span)
                        :bbox (opt-child (getf p :bbox) :bbox 'bbox)
                        :baseline (%num (getf p :baseline) :baseline)
                        :reading-order (%num (getf p :reading-order) :reading-order))))
      (:layout-block/1
       (let ((p (%layout-plist form :layout-block/1 '(:id :lines :bbox :reading-order :column-index)
                               '(:id :lines :bbox :reading-order :column-index))))
         (make-instance 'layout-block
                        :id (%str? (getf p :id) :id)
                        :lines (children (getf p :lines) :lines 'layout-line)
                        :bbox (opt-child (getf p :bbox) :bbox 'bbox)
                        :reading-order (%num (getf p :reading-order) :reading-order)
                        :column-index (%num (getf p :column-index) :column-index))))
      (:layout-page/1
       (let ((p (%layout-plist form :layout-page/1 '(:page-number :blocks :width :height :rotation)
                               '(:page-number :blocks :width :height :rotation))))
         (make-instance 'layout-page
                        :page-number (%num (getf p :page-number) :page-number)
                        :blocks (children (getf p :blocks) :blocks 'layout-block)
                        :width (%num (getf p :width) :width) :height (%num (getf p :height) :height)
                        :rotation (%num (getf p :rotation) :rotation))))
      (:layout-document/1
       (let ((p (%layout-plist form :layout-document/1 '(:id :source-file :pages)
                               '(:id :source-file :pages))))
         (make-instance 'layout-document
                        :id (%str? (getf p :id) :id)
                        :source-file (%str? (getf p :source-file) :source-file)
                        :pages (children (getf p :pages) :pages 'layout-page)))))))

;;; ============================================================================
;;; READING ORDER COMPUTATION
;;; ============================================================================
;;;
;;; Reading order in multi-column documents is complex:
;;;   1. Standard left-to-right, top-to-bottom within columns
;;;   2. Column detection based on horizontal gaps
;;;   3. Headers/footers handled specially
;;;
;;; Algorithm:
;;;   1. Detect columns by clustering x-coordinates
;;;   2. Sort blocks within each column by y (descending for PDF coords)
;;;   3. Order columns left-to-right
;;;   4. Merge column orders

(defun reading-order-score (element &key (page-height 792.0) (page-width 612.0) (num-columns 1))
  "Compute reading order score for an element.

   Lower score = earlier in reading order.

   NSA-GRADE: Proper multi-column support for FEK documents.

   Args:
     element: Layout element (block, line, span)
     page-height: Page height in points
     page-width: Page width in points (used for column detection)
     num-columns: Number of detected columns (default 1)

   Returns: (values score confidence)
     score: Numeric sort key
     confidence: 0.0-1.0 confidence in reading order"
  (let* ((bbox (element-bbox element))
         (cx (if bbox (+ (bbox-x bbox) (/ (bbox-width bbox) 2.0)) 0.0))
         (cy (if bbox (bbox-y bbox) 0.0))
         ;; Column detection: divide page into equal columns
         (column-width (/ page-width (max 1 num-columns)))
         (column (min (1- num-columns) (floor (/ cx column-width))))
         ;; Y-position (inverted for top-to-bottom)
         (y-score (- page-height cy))
         ;; Combined score: column major, y minor
         (score (+ (* column page-height) y-score)))
    (values score 0.8)))  ; Default confidence

(defun detect-column-count (blocks &key (page-width 612.0) (min-gap 30.0))
  "Detect number of columns in a page based on block X-positions.

   NSA-GRADE: Automatic column detection for FEK 2-column layouts.

   Algorithm:
     1. Collect all block center-X values
     2. Find gaps in X distribution
     3. Large gap (>min-gap) indicates column boundary

   Args:
     blocks: List of layout-block objects
     page-width: Page width in points
     min-gap: Minimum gap to consider column boundary

   Returns:
     Integer number of columns (1 or 2)"
  (when (or (null blocks) (< (length blocks) 2))
    (return-from detect-column-count 1))

  (let* (;; Collect center-X values of all blocks
         (x-centers (sort (mapcar (lambda (b)
                                    (let ((bbox (element-bbox b)))
                                      (if bbox
                                          (+ (bbox-x bbox) (/ (bbox-width bbox) 2.0))
                                          0.0)))
                                  blocks)
                          #'<))
         ;; Find gaps between consecutive centers
         (gaps (loop for (x1 x2) on x-centers
                     when x2
                     collect (cons (- x2 x1) (/ (+ x1 x2) 2.0))))
         ;; Find maximum gap (potential column divider)
         (max-gap (when gaps
                    (reduce (lambda (a b) (if (> (car a) (car b)) a b)) gaps)))
         ;; Check if gap is significant (>min-gap) and near page center
         (page-center (/ page-width 2.0)))

    (if (and max-gap
             (> (car max-gap) min-gap)
             ;; Gap should be near page center (within 30% of center)
             (< (abs (- (cdr max-gap) page-center)) (* page-width 0.3)))
        2
        1)))

(defun compute-reading-order (blocks &key (page-height 792.0) (page-width 612.0))
  "Compute reading order for a list of blocks.

   NSA-GRADE: Automatic 2-column detection for FEK documents.

   Algorithm:
     1. Detect number of columns from block positions
     2. Assign column index to each block
     3. Sort by column first, then by Y (top to bottom)

   Args:
     blocks: List of layout-block objects
     page-height: Page height for coordinate transform
     page-width: Page width for column detection

   Returns:
     blocks sorted in reading order"
  (when (null blocks)
    (return-from compute-reading-order nil))

  ;; Detect column layout
  (let* ((num-columns (detect-column-count blocks :page-width page-width))
         (column-width (/ page-width num-columns)))

    ;; Assign column index to each block
    (dolist (block blocks)
      (let* ((bbox (element-bbox block))
             (cx (if bbox (+ (bbox-x bbox) (/ (bbox-width bbox) 2.0)) 0.0))
             (col-idx (min (1- num-columns) (floor (/ cx column-width)))))
        (setf (block-column-index block) col-idx)))

    ;; Sort blocks by column then by Y (top to bottom)
    (let* ((scored (mapcar (lambda (b)
                             (cons (reading-order-score b
                                                        :page-height page-height
                                                        :page-width page-width
                                                        :num-columns num-columns)
                                   b))
                           blocks))
           (sorted (sort scored #'< :key #'car))
           (ordered (mapcar #'cdr sorted)))

      ;; Assign reading-order indices
      (loop for block in ordered
            for i from 0
            do (setf (block-reading-order block) i))

      ;; Log column detection for debugging
      (when (> num-columns 1)
        (format t "~&[READING-ORDER] Detected ~D-column layout~%" num-columns))

      ordered)))

(defun sort-by-reading-order (elements)
  "Sort any list of layout elements by their reading order score."
  (sort (copy-list elements) #'<
        :key (lambda (e) (reading-order-score e))))

;;; ============================================================================
;;; DSL MACROS
;;; ============================================================================

(defvar *page-width* 612.0)
(defvar *page-height* 792.0)

(defmacro with-page-coordinates ((&key width height) &body body)
  "Establish page coordinate context.

   Usage:
     (with-page-coordinates (:width 595.0 :height 842.0)  ; A4
       (make-layout-span ...))"
  `(let ((*page-width* ,(or width '*page-width*))
         (*page-height* ,(or height '*page-height*)))
     ,@body))

(defmacro deflayout-element (name superclass slots &body options)
  "Define a new layout element type.

   Automatically adds standard slots: id, bbox, trace.
   Generates constructor and print-object method.

   Usage:
     (deflayout-element margin-note (layout-block)
       ((note-type :initarg :note-type :accessor note-type))
       (:documentation \"A margin note element\"))"
  (let ((constructor-name (intern (format nil "MAKE-~A" name)))
        (counter-var (intern (format nil "*~A-COUNTER*" name))))
    `(progn
       (defvar ,counter-var 0)

       (defclass ,name (,superclass)
         ,slots
         ,@options)

       (defun ,constructor-name (&rest initargs)
         ,(format nil "Create a ~A instance." name)
         (let ((instance (apply #'make-instance ',name initargs)))
           (unless (slot-boundp instance 'id)
             (setf (slot-value instance 'id)
                   (format nil "~A-~A" ',name (incf ,counter-var))))
           instance))

       (defmethod print-object ((obj ,name) stream)
         (print-unreadable-object (obj stream :type t :identity nil)
           (format stream "~A" (element-id obj)))))))

;;; ============================================================================
;;; RESET COUNTERS (for testing)
;;; ============================================================================

(defun reset-layout-counters ()
  "Reset all layout element counters to 0."
  (setf *span-counter* 0
        *line-counter* 0
        *block-counter* 0
        *document-counter* 0)
  t)

;;; ============================================================================
;;; END OF LAYOUT-TYPES.LISP
;;; ============================================================================
