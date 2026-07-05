;;;; source/typographic-classifier.lisp
;;;; ============================================================================
;;;; TYPOGRAPHIC-CLASSIFIER - Layer 2 FSM for Logical Block Classification
;;;; ============================================================================
;;;;
;;;; LAYER 2: LAYOUT GRAPH → LOGICAL BLOCKS
;;;;
;;;; This module classifies layout blocks into logical types based on
;;;; TYPOGRAPHIC features only - no semantic analysis at this stage.
;;;;
;;;; CLASSIFICATION CATEGORIES:
;;;;   :TITLE           - Document title (large font, top position)
;;;;   :ARTICLE-HEADER  - "Άρθρο X" article headers
;;;;   :PARAGRAPH       - Normal body text paragraphs
;;;;   :PARAGRAPH-NUM   - Paragraph numbers (1., 2., etc.)
;;;;   :POINT           - Bullet points or lettered items (α., β., etc.)
;;;;   :HEADER          - Page headers
;;;;   :FOOTER          - Page footers
;;;;   :PAGE-NUMBER     - Page number indicators
;;;;   :CAPTION         - Figure/table captions
;;;;   :MARGINALIA      - Side notes, annotations
;;;;   :SIGNATURE       - Signature blocks
;;;;   :UNKNOWN         - Unclassified
;;;;
;;;; FSM APPROACH:
;;;;   The classifier uses a Finite State Machine to track document context
;;;;   and make better classification decisions based on what came before.
;;;;
;;;; ============================================================================
;;;; COMMON LISP FEATURES UTILIZED
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CLOS                     │ logical-block class, classifier class        │
;;;; │                          │ • State machine as object                    │
;;;; │                          │ • Method dispatch on block types             │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ GENERIC FUNCTIONS        │ Extensible classification rules              │
;;;; │                          │ • classify-block-type                        │
;;;; │                          │ • compute-typographic-features               │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ DEFSTRUCT                │ Efficient feature vectors                    │
;;;; │                          │ • typographic-features struct                │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Classification with confidence               │
;;;; │                          │ (values block-type confidence features)      │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MACROS                   │ Rule definition DSL                          │
;;;; │                          │ • defrule, with-classifier-state             │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CLOSURES                 │ Rule functions as first-class values         │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(defpackage :orchestrator.typographic-classifier
  (:use :cl)
  (:import-from :orchestrator.trace-core
                #:trace-info
                #:make-trace-info
                #:extend-trace
                #:trace-id)
  (:import-from :orchestrator.layout-types
                #:layout-block
                #:layout-line
                #:layout-span
                #:layout-page
                #:block-lines
                #:block-bbox
                #:block-text
                #:block-id
                #:block-trace
                #:line-spans
                #:line-bbox
                #:span-font
                #:span-text
                #:span-bbox
                #:font-info
                #:font-info-p
                #:font-info-size
                #:font-info-bold-p
                #:font-info-name
                #:page-blocks
                #:page-width
                #:page-height
                #:element-bbox
                #:bbox-x
                #:bbox-y
                #:bbox-width
                #:bbox-height
                #:page-number)
  (:import-from :cl-ppcre
                #:scan
                #:scan-to-strings
                #:split)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; LOGICAL BLOCK CLASS
   ;; ══════════════════════════════════════════════════════════════════
   #:logical-block
   #:make-logical-block
   #:logical-block-type
   #:logical-block-layout
   #:logical-block-confidence
   #:logical-block-features
   #:logical-block-trace
   #:logical-block-id

   ;; ══════════════════════════════════════════════════════════════════
   ;; TYPOGRAPHIC FEATURES
   ;; ══════════════════════════════════════════════════════════════════
   #:typographic-features
   #:make-typographic-features
   #:features-font-size
   #:features-is-bold
   #:features-is-centered
   #:features-relative-y
   #:features-line-count
   #:features-starts-with-number
   #:features-starts-with-article
   #:features-is-short
   #:features-has-greek-letters

   ;; ══════════════════════════════════════════════════════════════════
   ;; CLASSIFICATION
   ;; ══════════════════════════════════════════════════════════════════
   #:classify-block
   #:classify-page
   #:classify-document
   #:compute-typographic-features

   ;; ══════════════════════════════════════════════════════════════════
   ;; FSM CLASSIFIER
   ;; ══════════════════════════════════════════════════════════════════
   #:block-classifier
   #:make-block-classifier
   #:classifier-state
   #:classifier-reset
   #:classifier-process-block

   ;; ══════════════════════════════════════════════════════════════════
   ;; BLOCK TYPES
   ;; ══════════════════════════════════════════════════════════════════
   #:+block-types+
   #:block-type-p

   ;; ══════════════════════════════════════════════════════════════════
   ;; MACROS
   ;; ══════════════════════════════════════════════════════════════════
   #:defrule
   #:with-classifier-state

   ;; ══════════════════════════════════════════════════════════════════
   ;; DARPA-GRADE AUDIT
   ;; ══════════════════════════════════════════════════════════════════
   #:classification-audit-entry
   #:make-classification-audit-entry
   #:classifier-audit-report
   #:classifier-audit-to-sexp
   #:classifier-statistics

   ;; ══════════════════════════════════════════════════════════════════
   ;; GENERIC FUNCTION DISPATCH
   ;; ══════════════════════════════════════════════════════════════════
   #:classify-by-pattern
   #:defpattern
   #:apply-generic-patterns
   #:*pattern-types*

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONSOLIDATED PATTERN HELPERS
   ;; ══════════════════════════════════════════════════════════════════
   #:fek-header-pattern-p
   #:section-header-pattern-p))

(in-package :orchestrator.typographic-classifier)

;;; ============================================================================
;;; BLOCK TYPES
;;; ============================================================================

(defparameter +block-types+
  '(;; ══════════════════════════════════════════════════════════════════
    ;; DOCUMENT STRUCTURE
    ;; ══════════════════════════════════════════════════════════════════
    :title           ; Document title (ΣΥΝΤΑΓΜΑ ΤΗΣ ΕΛΛΑΔΟΣ)
    :subtitle        ; Document subtitle
    :chapter-header  ; ΜΕΡΟΣ / ΤΜΗΜΑ / ΚΕΦΑΛΑΙΟ headers
    :section-header  ; Section dividers

    ;; ══════════════════════════════════════════════════════════════════
    ;; LEGAL ARTICLE STRUCTURE (Άρθρο hierarchy)
    ;; ══════════════════════════════════════════════════════════════════
    :article-header  ; "Άρθρο X" headers
    :article-title   ; Article title (after Άρθρο X)
    :paragraph       ; Body text (παράγραφος content)
    :paragraph-num   ; Paragraph numbers (1., 2., 3.)
    :sub-paragraph   ; Sub-paragraph (εδάφιο)
    :point           ; Greek letter items (α., β., γ.)
    :sub-point       ; Sub-points (αα., ββ., i., ii.)
    :case-marker     ; "περίπτωση α'" markers

    ;; ══════════════════════════════════════════════════════════════════
    ;; LEGAL REFERENCES & AMENDMENTS
    ;; ══════════════════════════════════════════════════════════════════
    :law-reference   ; References: Ν. 1234/2020, ΠΔ 56/2021
    :fek-reference   ; ΦΕΚ Α' 123/2020
    :amendment       ; Amendment markers (τροποποιείται, αντικαθίσταται)
    :repeal          ; Repeal markers (καταργείται)
    :addition        ; Addition markers (προστίθεται)
    :transitional    ; Transitional provisions (μεταβατικές διατάξεις)
    :effective-date  ; Effective date markers (ισχύει από)

    ;; ══════════════════════════════════════════════════════════════════
    ;; PAGE ELEMENTS
    ;; ══════════════════════════════════════════════════════════════════
    :header          ; Page header
    :footer          ; Page footer
    :page-number     ; Page numbers
    :caption         ; Figure/table captions
    :marginalia      ; Side notes, annotations

    ;; ══════════════════════════════════════════════════════════════════
    ;; DOCUMENT CLOSING
    ;; ══════════════════════════════════════════════════════════════════
    :signature       ; Signature blocks
    :date-place      ; Date and place of signing
    :attestation     ; Attestation/certification

    ;; ══════════════════════════════════════════════════════════════════
    ;; CLASSIFICATION
    ;; ══════════════════════════════════════════════════════════════════
    :unknown)        ; Unclassified
  "Valid logical block types - Extended for Greek Legal Documents")

(defun block-type-p (type)
  "Check if TYPE is a valid block type keyword"
  (member type +block-types+))

;;; ============================================================================
;;; TYPOGRAPHIC FEATURES (DEFSTRUCT for efficiency)
;;; ============================================================================

(defstruct (typographic-features
            (:constructor make-typographic-features
                          (&key font-size is-bold is-italic is-centered
                                relative-x relative-y
                                line-count word-count char-count
                                starts-with-number starts-with-article
                                starts-with-greek-letter starts-with-chapter
                                starts-with-sub-point starts-with-case
                                contains-law-reference contains-fek-reference
                                contains-amendment contains-repeal contains-addition
                                contains-effective-date is-transitional is-date-place
                                is-short is-all-caps has-punctuation-end
                                indent-level greek-confidence
                                raw-text)))
  "Typographic features extracted from a layout block.
   Used for classification decisions.

   NSA-GRADE: Extended for Greek legal document recognition.

   LISP FEATURES:
     - DEFSTRUCT for memory efficiency
     - BOA constructor for typed initialization
     - Includes raw-text for pattern matching at rule-time"

  ;; ══════════════════════════════════════════════════════════════════
  ;; FONT CHARACTERISTICS
  ;; ══════════════════════════════════════════════════════════════════
  (font-size 12.0 :type single-float)
  (is-bold nil :type boolean)
  (is-italic nil :type boolean)

  ;; ══════════════════════════════════════════════════════════════════
  ;; POSITION (0.0-1.0 relative to page)
  ;; ══════════════════════════════════════════════════════════════════
  (is-centered nil :type boolean)
  (relative-x 0.0 :type single-float)  ; 0=left, 1=right
  (relative-y 0.0 :type single-float)  ; 0=bottom, 1=top

  ;; ══════════════════════════════════════════════════════════════════
  ;; CONTENT METRICS
  ;; ══════════════════════════════════════════════════════════════════
  (line-count 1 :type integer)
  (word-count 0 :type integer)
  (char-count 0 :type integer)

  ;; ══════════════════════════════════════════════════════════════════
  ;; LEGAL STRUCTURE PATTERNS
  ;; ══════════════════════════════════════════════════════════════════
  (starts-with-number nil :type boolean)        ; "1.", "2." etc
  (starts-with-article nil :type boolean)       ; "Άρθρο"
  (starts-with-greek-letter nil :type boolean)  ; "α)", "β)" etc
  (starts-with-chapter nil :type boolean)       ; ΜΕΡΟΣ, ΤΜΗΜΑ, ΚΕΦΑΛΑΙΟ
  (starts-with-sub-point nil :type boolean)     ; "αα)", "i)" etc
  (starts-with-case nil :type boolean)          ; "περίπτωση α'"

  ;; ══════════════════════════════════════════════════════════════════
  ;; LEGAL REFERENCE PATTERNS
  ;; ══════════════════════════════════════════════════════════════════
  (contains-law-reference nil :type boolean)    ; Ν. 1234/2020, ΠΔ, ΚΥΑ
  (contains-fek-reference nil :type boolean)    ; ΦΕΚ Α' 123
  (contains-amendment nil :type boolean)        ; τροποποιείται, αντικαθίσταται
  (contains-repeal nil :type boolean)           ; καταργείται
  (contains-addition nil :type boolean)         ; προστίθεται
  (contains-effective-date nil :type boolean)   ; ισχύει από
  (is-transitional nil :type boolean)           ; μεταβατικές διατάξεις
  (is-date-place nil :type boolean)             ; Αθήνα, 15 Ιανουαρίου

  ;; ══════════════════════════════════════════════════════════════════
  ;; TEXT CHARACTERISTICS
  ;; ══════════════════════════════════════════════════════════════════
  (is-short nil :type boolean)   ; < 50 chars
  (is-all-caps nil :type boolean)
  (has-punctuation-end nil :type boolean)

  ;; ══════════════════════════════════════════════════════════════════
  ;; STRUCTURE & CONFIDENCE
  ;; ══════════════════════════════════════════════════════════════════
  (indent-level 0 :type integer)
  (greek-confidence 0.0 :type single-float)  ; 0.0-1.0 Greek legal text confidence

  ;; ══════════════════════════════════════════════════════════════════
  ;; RAW TEXT (for rule-time pattern matching)
  ;; ══════════════════════════════════════════════════════════════════
  (raw-text "" :type string))

;;; ============================================================================
;;; FEATURE EXTRACTION
;;; ============================================================================

(defun extract-dominant-font-size (block)
  "Extract the most common font size from a block.
   Returns single-float."
  (let ((sizes '()))
    (dolist (line (block-lines block))
      (dolist (span (line-spans line))
        (when (and (span-font span) (font-info-p (span-font span)))
          (push (font-info-size (span-font span)) sizes))))
    (if sizes
        (coerce (/ (reduce #'+ sizes) (length sizes)) 'single-float)
        12.0)))

(defun extract-is-bold (block)
  "Check if majority of text in block is bold."
  (let ((bold-count 0)
        (total-count 0))
    (dolist (line (block-lines block))
      (dolist (span (line-spans line))
        (incf total-count)
        (when (and (span-font span)
                   (font-info-p (span-font span))
                   (font-info-bold-p (span-font span)))
          (incf bold-count))))
    (and (> total-count 0)
         (> (/ bold-count total-count) 0.5))))

(defun compute-relative-position (block page-width page-height)
  "Compute relative x,y position (0-1 scale).
   Returns: (values relative-x relative-y is-centered)"
  (let* ((bbox (block-bbox block))
         (x (if bbox (bbox-x bbox) 0.0))
         (y (if bbox (bbox-y bbox) 0.0))
         (w (if bbox (bbox-width bbox) 0.0))
         (center-x (+ x (/ w 2.0)))
         (page-center (/ page-width 2.0))
         (rel-x (if (> page-width 0) (/ center-x page-width) 0.0))
         (rel-y (if (> page-height 0) (/ y page-height) 0.0))
         ;; Centered if within 10% of page center
         (is-centered (< (abs (- center-x page-center)) (* page-width 0.1))))
    (values (coerce rel-x 'single-float)
            (coerce rel-y 'single-float)
            is-centered)))

(declaim (inline %scan-p))
(defun %scan-p (regex text)
  "Genuine BOOLEAN pattern test — the -p contract. Returns T iff REGEX matches
   somewhere in TEXT, else NIL. cl-ppcre:scan returns the match START POSITION, which
   is 0 at the beginning of a line; routing that bare integer into a :type boolean
   feature slot signals «0 is not of type BOOLEAN». The bug was latent on indented
   Isokratis PDF lines (match position > 0 or no match) and surfaced on clean .docx
   lines that begin at column 0. Every classifier predicate funnels through this one
   enforcement point, so the -p contract holds everywhere by construction."
  (and text (plusp (length text)) (cl-ppcre:scan regex text) t))

(defun text-starts-with-article-p (text)
  "Check if text starts with 'Άρθρο' pattern."
  (%scan-p "^\\s*[ΆΑ]ρθρ[οό]\\s*\\d" text))

(defun text-starts-with-number-p (text)
  "Check if text starts with a paragraph number pattern."
  (%scan-p "^\\s*\\d+[.):]\\s" text))

(defun text-starts-with-greek-letter-p (text)
  "Check if text starts with Greek letter enumeration (α), β), etc."
  (%scan-p "^\\s*[αβγδεζηθικλμνξοπρστυφχψω][.):]\\s" text))

;;; ============================================================================
;;; ADVANCED GREEK LEGAL PATTERN DETECTION
;;; ============================================================================
;;;
;;; NSA-GRADE: Comprehensive Greek legal document patterns
;;; Maximum Lisp: Closures, multiple values, generic functions
;;;

(defun text-starts-with-chapter-p (text)
  "Check for chapter/section headers: ΜΕΡΟΣ, ΤΜΗΜΑ, ΚΕΦΑΛΑΙΟ"
  (%scan-p "^\\s*(ΜΕΡΟΣ|ΤΜΗΜΑ|ΚΕΦΑΛΑΙ[ΟΑ]|ΕΝΟΤΗΤΑ|ΠΑΡΑΡΤΗΜΑ)\\s" text))

(defun text-starts-with-sub-point-p (text)
  "Check for sub-points: αα), ββ), i), ii), etc."
  (%scan-p "^\\s*([αβγδ]{2}|[ivxIVX]+)[.):]\\s" text))

(defun text-starts-with-case-p (text)
  "Check for 'περίπτωση' markers."
  (%scan-p "(?i)^\\s*περίπτωση\\s+[α-ω]" text))

(defun text-contains-law-reference-p (text)
  "Check for law references: Ν. 1234/2020, ν. 1234/2020, Π.Δ., ΠΔ, etc."
  (%scan-p "(Ν\\.|ν\\.|Π\\.?Δ\\.?|Κ\\.?Υ\\.?Α\\.?)\\s*\\d+" text))

(defun text-contains-fek-reference-p (text)
  "Check for ΦΕΚ references: ΦΕΚ Α' 123, ΦΕΚ Β 456, etc."
  (%scan-p "ΦΕΚ\\s*[ΑΒΓΔ]['']?\\s*\\d+" text))

(defun text-contains-amendment-p (text)
  "Check for amendment keywords."
  (%scan-p "(?i)(αντικαθίσταται|τροποποιείται|αντικατάσταση|τροποποίηση)" text))

(defun text-contains-repeal-p (text)
  "Check for repeal keywords."
  (%scan-p "(?i)(καταργείται|κατάργηση|καταργούνται)" text))

(defun text-contains-addition-p (text)
  "Check for addition keywords."
  (%scan-p "(?i)(προστίθεται|προσθήκη|προστίθενται)" text))

(defun text-contains-effective-date-p (text)
  "Check for effective date markers."
  (%scan-p "(?i)(ισχύει\\s+από|τίθεται\\s+σε\\s+ισχύ|έναρξη\\s+ισχύος)" text))

(defun text-is-date-place-p (text)
  "Check for date/place signatures: Αθήνα, 15 Ιανουαρίου 2020"
  (%scan-p "(Αθήνα|Θεσσαλονίκη),?\\s+\\d+\\s+(Ιανουαρίου|Φεβρουαρίου|Μαρτίου|Απριλίου|Μαΐου|Ιουνίου|Ιουλίου|Αυγούστου|Σεπτεμβρίου|Οκτωβρίου|Νοεμβρίου|Δεκεμβρίου)" text))

(defun text-is-transitional-p (text)
  "Check for transitional provisions."
  (%scan-p "(?i)(μεταβατικ[έή]ς?\\s+διατάξ|τελικ[έή]ς?\\s+διατάξ)" text))

;;; ============================================================================
;;; EXTENDED TYPOGRAPHIC FEATURES
;;; ============================================================================

(defun extract-greek-letter-marker (text)
  "Extract Greek letter marker from text. Returns: (values letter position confidence)"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings "^\\s*([α-ω])[.):]" text)
    (if match
        (values (aref groups 0) 0 0.95)
        (values nil nil 0.0))))

(defun extract-article-number-full (text)
  "Extract article number with optional Greek suffix (1α, 2β).
   Returns: (values number suffix confidence)"
  (multiple-value-bind (match groups)
      (cl-ppcre:scan-to-strings "[ΆΑ]ρθρ[οό]\\s*(\\d+)\\s*([α-ω])?" text)
    (if match
        (values (aref groups 0)
                (when (> (length groups) 1) (aref groups 1))
                0.98)
        (values nil nil 0.0))))

(defun compute-greek-text-confidence (text)
  "Compute confidence that text is Greek legal content.
   Returns: float 0.0-1.0"
  (let ((score 0.0)
        (checks 0))
    ;; Has Greek characters
    (when (cl-ppcre:scan "[α-ωά-ώ]" text)
      (incf score 0.3)
      (incf checks))
    ;; Has legal terms
    (when (cl-ppcre:scan "(?i)(άρθρο|παράγραφος|εδάφιο|νόμος|διάταξη)" text)
      (incf score 0.4)
      (incf checks))
    ;; Has proper punctuation
    (when (cl-ppcre:scan "[.;:]$" text)
      (incf score 0.15)
      (incf checks))
    ;; Reasonable length
    (when (< 10 (length text) 2000)
      (incf score 0.15)
      (incf checks))
    (if (> checks 0)
        (min 1.0 score)
        0.1)))

(defun compute-typographic-features (block &key (page-width 612.0) (page-height 792.0))
  "Compute all typographic features for a layout block.

   NSA-GRADE: Extended feature extraction for Greek legal documents.

   LISP FEATURES:
     - MULTIPLE-VALUE-BIND for position extraction
     - Pattern predicates as first-class functions
     - Confidence scoring

   Args:
     block: layout-block object
     page-width: Page width for relative positioning
     page-height: Page height for relative positioning

   Returns:
     typographic-features struct with all patterns detected"
  (let* ((text (block-text block))
         (line-count (length (block-lines block)))
         (char-count (if text (length text) 0))
         (word-count (if (and text (> (length text) 0))
                         (length (cl-ppcre:split "\\s+" text))
                         0)))
    (multiple-value-bind (rel-x rel-y is-centered)
        (compute-relative-position block page-width page-height)
      (make-typographic-features
       ;; Font
       :font-size (extract-dominant-font-size block)
       :is-bold (extract-is-bold block)
       :is-centered is-centered

       ;; Position
       :relative-x rel-x
       :relative-y rel-y

       ;; Content metrics
       :line-count line-count
       :word-count word-count
       :char-count char-count

       ;; Legal structure patterns
       :starts-with-number (text-starts-with-number-p text)
       :starts-with-article (text-starts-with-article-p text)
       :starts-with-greek-letter (text-starts-with-greek-letter-p text)
       :starts-with-chapter (text-starts-with-chapter-p text)
       :starts-with-sub-point (text-starts-with-sub-point-p text)
       :starts-with-case (text-starts-with-case-p text)

       ;; Legal reference patterns
       :contains-law-reference (text-contains-law-reference-p text)
       :contains-fek-reference (text-contains-fek-reference-p text)
       :contains-amendment (text-contains-amendment-p text)
       :contains-repeal (text-contains-repeal-p text)
       :contains-addition (text-contains-addition-p text)
       :contains-effective-date (text-contains-effective-date-p text)
       :is-transitional (text-is-transitional-p text)
       :is-date-place (text-is-date-place-p text)

       ;; Text characteristics
       :is-short (< char-count 50)
       :is-all-caps (and (not (%scan-p "[α-ω]" text))  ; no lowercase Greek
                         (%scan-p "[Α-Ω]" text)         ; has uppercase Greek → boolean
                         t)
       :has-punctuation-end (and text
                                  (> (length text) 0)
                                  ;; MEMBER returns the tail list, not a boolean — coerce.
                                  (member (char text (1- (length text)))
                                          '(#\. #\: #\; #\! #\?))
                                  t)

       ;; Confidence & raw text
       :greek-confidence (if text
                              (coerce (compute-greek-text-confidence text) 'single-float)
                              0.0)
       :raw-text (or text "")))))

;;; ============================================================================
;;; LOGICAL BLOCK CLASS
;;; ============================================================================

(defvar *logical-block-counter* 0)

(defclass logical-block ()
  ((id
    :accessor logical-block-id
    :initarg :id
    :type string)

   (block-type
    :accessor logical-block-type
    :initarg :block-type
    :initform :unknown
    :type keyword
    :documentation "Classification result: :title, :article-header, :paragraph, etc.")

   (layout-block
    :accessor logical-block-layout
    :initarg :layout-block
    :initform nil
    :type (or null layout-block)
    :documentation "Original layout block from Layer 1")

   (confidence
    :accessor logical-block-confidence
    :initarg :confidence
    :initform 0.5
    :type single-float
    :documentation "Classification confidence 0.0-1.0")

   (features
    :accessor logical-block-features
    :initarg :features
    :initform nil
    :type (or null typographic-features)
    :documentation "Extracted typographic features")

   (trace
    :accessor logical-block-trace
    :initarg :trace
    :initform nil
    :type (or null trace-info)
    :documentation "Traceability info extending from layout block"))

  (:documentation "A classified layout block with logical type.

   Layer 2 output: layout-block + type + confidence + features."))

(defun make-logical-block (&key block-type layout-block confidence features)
  "Create a logical block with auto-generated ID and trace."
  (let* ((id (format nil "LBLOCK-~A" (incf *logical-block-counter*)))
         (trace (when (and layout-block (block-trace layout-block))
                  (extend-trace (block-trace layout-block)
                                :new-layer :logical
                                :logical-block-ids (list id)))))
    (make-instance 'logical-block
                   :id id
                   :block-type (or block-type :unknown)
                   :layout-block layout-block
                   :confidence (or confidence 0.5)
                   :features features
                   :trace trace)))

(defmethod print-object ((lb logical-block) stream)
  (print-unreadable-object (lb stream :type t :identity nil)
    (format stream "~A ~A (conf:~,2F)"
            (logical-block-id lb)
            (logical-block-type lb)
            (logical-block-confidence lb))))

;;; ============================================================================
;;; FSM CLASSIFIER
;;; ============================================================================

(defclass block-classifier ()
  ((state
    :accessor classifier-state
    :initform :start
    :type keyword
    :documentation "Current FSM state")

   (page-context
    :accessor classifier-page-context
    :initform nil
    :documentation "Context from current page (header font size, etc.)")

   (last-block-type
    :accessor classifier-last-type
    :initform nil
    :type (or null keyword)
    :documentation "Type of last classified block")

   (article-count
    :accessor classifier-article-count
    :initform 0
    :type integer
    :documentation "Number of articles seen")

   (paragraph-count
    :accessor classifier-paragraph-count
    :initform 0
    :type integer
    :documentation "Paragraphs in current article")

   (current-article-number
    :accessor classifier-current-article
    :initform nil
    :documentation "Current article number being processed")

   (chapter-count
    :accessor classifier-chapter-count
    :initform 0
    :type integer
    :documentation "Number of chapters/sections seen")

   (baseline-font-size
    :accessor classifier-baseline-font
    :initform 12.0
    :type single-float
    :documentation "Baseline body text font size")

   (classification-log
    :accessor classifier-log
    :initform '()
    :type list
    :documentation "Log of classifications for debugging"))

  (:documentation "Finite State Machine for Greek legal document classification.

   NSA-GRADE: Extended for Greek legal documents with full context tracking.

   LISP FEATURES:
     - CLOS for stateful FSM
     - Method dispatch for state transitions
     - Logging for auditability

   States:
     :START            - Beginning of document
     :IN-PREAMBLE      - Before first article (title, introduction)
     :IN-CHAPTER       - Inside a chapter/section (ΜΕΡΟΣ, ΚΕΦΑΛΑΙΟ)
     :IN-ARTICLE       - Inside an article (after Άρθρο X)
     :IN-PARAGRAPH     - Processing paragraph content
     :IN-POINTS        - Processing lettered points (α, β, γ)
     :IN-AMENDMENT     - Processing amendment section
     :IN-TRANSITIONAL  - Processing transitional provisions
     :IN-CLOSING       - Closing section
     :IN-SIGNATURE     - Signature area at end"))

(defun make-block-classifier ()
  "Create a new block classifier FSM."
  (make-instance 'block-classifier))

(defun classifier-reset (classifier)
  "Reset classifier to initial state."
  (setf (classifier-state classifier) :start
        (classifier-last-type classifier) nil
        (classifier-article-count classifier) 0
        (classifier-baseline-font classifier) 12.0
        (classifier-page-context classifier) nil)
  classifier)

;;; ============================================================================
;;; CLASSIFICATION RULES (as closures)
;;; ============================================================================

(defparameter *classification-rules* '()
  "List of (name priority test-fn type) rules")

(defmacro defrule (name (&key (priority 50)) test-form result-type)
  "Define a classification rule.

   Usage:
     (defrule article-header (:priority 90)
       (features-starts-with-article features)
       :article-header)"
  `(push (list ',name ,priority
               (lambda (features state last-type)
                 (declare (ignorable features state last-type))
                 ,test-form)
               ,result-type)
         *classification-rules*))

;;; ============================================================================
;;; GENERIC FUNCTION DISPATCH (DARPA-GRADE extensibility)
;;; ============================================================================
;;;
;;; Allows classification rules to be defined as CLOS methods.
;;; This provides:
;;;   1. Extensibility via method specialization
;;;   2. Method combination for complex rules
;;;   3. :before/:after/:around methods for preprocessing
;;;
;;; Usage:
;;;   (defmethod classify-by-content ((type (eql :check-article)) features state)
;;;     (when (typographic-features-starts-with-article features)
;;;       (values :article-header 100)))
;;;

(defgeneric classify-by-pattern (pattern-type features fsm-state)
  (:documentation "DARPA-GRADE: Generic function for extensible classification.

   Specialize on pattern-type to add new classification rules:
     pattern-type: keyword identifying the pattern class
     features: typographic-features struct
     fsm-state: current FSM state

   Returns: (values block-type priority) or NIL if no match")
  (:method ((pattern-type t) features fsm-state)
    "Default method - no match"
    (declare (ignore pattern-type features fsm-state))
    nil))

;; Pattern type registry
(defparameter *pattern-types* '()
  "List of registered pattern types for generic dispatch")

(defmacro defpattern (name priority &body body)
  "DARPA-GRADE: Define a classification pattern using generic functions.

   Usage:
     (defpattern :article-pattern 100
       (when (typographic-features-starts-with-article features)
         :article-header))

   The body has access to: features, fsm-state
   Should return block-type keyword or NIL"
  (let ((method-name (intern (format nil "CLASSIFY-~A" name) :keyword)))
    `(progn
       (pushnew ,method-name *pattern-types*)
       (defmethod classify-by-pattern ((pattern-type (eql ,method-name)) features fsm-state)
         (declare (ignorable fsm-state))
         (let ((result (progn ,@body)))
           (when result
             (values result ,priority)))))))

(defun apply-generic-patterns (features fsm-state)
  "Apply all registered generic patterns.

   Returns: list of (block-type priority pattern-name) for all matches"
  (let ((matches '()))
    (dolist (pattern-type *pattern-types*)
      (multiple-value-bind (block-type priority)
          (classify-by-pattern pattern-type features fsm-state)
        (when block-type
          (push (list block-type priority pattern-type) matches))))
    matches))

;;; ============================================================================
;;; CLASSIFICATION RULES - NSA-GRADE GREEK LEGAL DOCUMENT RECOGNITION
;;; ============================================================================
;;;
;;; Priority levels:
;;;   100+ : Absolute patterns (Άρθρο, ΜΕΡΟΣ, etc.)
;;;   80-99: Strong patterns with context
;;;   60-79: Medium patterns
;;;   40-59: Weak patterns (need context)
;;;   10-39: Fallbacks
;;;

;; ══════════════════════════════════════════════════════════════════
;; HIGHEST PRIORITY: Absolute identifiers
;; ══════════════════════════════════════════════════════════════════

(defrule article-header (:priority 100)
  (typographic-features-starts-with-article features)
  :article-header)

(defrule article-subtitle (:priority 99)
  ;; Article subtitle/title: Greek text after article header
  ;; Examples: "Μορφή του Πολιτεύματος", "Βασικές διατάξεις"
  ;; FIXED: Allow uppercase Greek anywhere (not just at start)
  ;;
  ;; Must:
  ;;   - Start with Greek capital letter
  ;;   - NOT start with number (that's a paragraph)
  ;;   - Be short (3-100 chars)
  ;;   - NOT contain FEK headers or section markers
  (and (cl-ppcre:scan "^[Α-ΩΆ-Ώ]" (typographic-features-raw-text features))
       (not (cl-ppcre:scan "^\\d" (typographic-features-raw-text features)))
       (not (cl-ppcre:scan "^[α-ω][.)]" (typographic-features-raw-text features)))
       (> (typographic-features-char-count features) 3)
       (< (typographic-features-char-count features) 100)
       ;; Must be mostly Greek letters and spaces
       (cl-ppcre:scan "^[Α-Ωα-ωά-ώΆ-Ώ\\s]+$" (typographic-features-raw-text features))
       ;; Exclude FEK headers
       (not (cl-ppcre:scan "ΕΦΗΜΕΡΙ" (typographic-features-raw-text features)))
       ;; Exclude section headers (ΜΕΡΟΣ, ΤΜΗΜΑ, ΚΕΦΑΛΑΙΟ)
       (not (cl-ppcre:scan "^\\s*ΜΕΡΟΣ\\s" (typographic-features-raw-text features)))
       (not (cl-ppcre:scan "^\\s*ΤΜΗΜΑ\\s" (typographic-features-raw-text features)))
       (not (cl-ppcre:scan "^\\s*ΚΕΦΑΛΑΙΟ\\s" (typographic-features-raw-text features))))
  :article-subtitle)

(defrule chapter-header (:priority 98)
  (typographic-features-starts-with-chapter features)
  :chapter-header)

;; ══════════════════════════════════════════════════════════════════
;; HIGH PRIORITY: Structure markers
;; ══════════════════════════════════════════════════════════════════

(defrule paragraph-number (:priority 92)
  (and (typographic-features-starts-with-number features)
       (typographic-features-is-short features))
  :paragraph-num)

(defrule greek-point (:priority 90)
  (typographic-features-starts-with-greek-letter features)
  :point)

(defrule sub-point (:priority 88)
  (typographic-features-starts-with-sub-point features)
  :sub-point)

(defrule case-marker (:priority 86)
  (typographic-features-starts-with-case features)
  :case-marker)

;; ══════════════════════════════════════════════════════════════════
;; LEGAL REFERENCES & AMENDMENTS
;; ══════════════════════════════════════════════════════════════════

(defrule law-reference (:priority 82)
  (and (typographic-features-contains-law-reference features)
       (not (typographic-features-starts-with-article features)))
  :law-reference)

(defrule fek-reference (:priority 81)
  (typographic-features-contains-fek-reference features)
  :fek-reference)

(defrule amendment-block (:priority 78)
  (typographic-features-contains-amendment features)
  :amendment)

(defrule repeal-block (:priority 77)
  (typographic-features-contains-repeal features)
  :repeal)

(defrule addition-block (:priority 76)
  (typographic-features-contains-addition features)
  :addition)

(defrule effective-date (:priority 75)
  (typographic-features-contains-effective-date features)
  :effective-date)

(defrule transitional (:priority 74)
  (typographic-features-is-transitional features)
  :transitional)

;; ══════════════════════════════════════════════════════════════════
;; TITLE & POSITION-BASED
;; ══════════════════════════════════════════════════════════════════

(defrule title-by-position (:priority 80)
  (and (> (typographic-features-relative-y features) 0.8)
       (typographic-features-is-centered features)
       (typographic-features-is-bold features))
  :title)

(defrule title-all-caps (:priority 79)
  (and (typographic-features-is-all-caps features)
       (typographic-features-is-centered features)
       (typographic-features-is-short features)
       (> (typographic-features-font-size features) 14.0))
  :title)

;; ══════════════════════════════════════════════════════════════════
;; PAGE ELEMENTS
;; ══════════════════════════════════════════════════════════════════

(defrule page-number (:priority 72)
  (and (< (typographic-features-relative-y features) 0.1)
       (typographic-features-is-centered features)
       (< (typographic-features-char-count features) 10))
  :page-number)

(defrule header-top (:priority 70)
  (and (> (typographic-features-relative-y features) 0.95)
       (typographic-features-is-short features))
  :header)

(defrule footer-bottom (:priority 70)
  (and (< (typographic-features-relative-y features) 0.05)
       (typographic-features-is-short features))
  :footer)

;; ══════════════════════════════════════════════════════════════════
;; FEK-SPECIFIC DETECTION (CONSOLIDATED DARPA-GRADE)
;;
;; CRITICAL: FEK PDFs use mixed Greek/Latin lookalike characters
;; Common substitutions:
;;   Greek Δ (U+0394) vs Latin D or ∆ (U+2206)
;;   Greek Τ (U+03A4) vs Latin T    Greek Η (U+0397) vs Latin H
;;   Greek Ε (U+0395) vs Latin E    Greek Ρ (U+03A1) vs Latin P
;;   Greek Ο (U+039F) vs Latin O    Greek Μ (U+039C) vs Latin M
;;   Greek Α (U+0391) vs Latin A    Greek Σ (U+03A3) vs Latin S
;; ══════════════════════════════════════════════════════════════════

(defun fek-header-pattern-p (text)
  "DARPA-GRADE: Consolidated FEK header detection.
   Handles all Greek/Latin character variants in single function."
  (or ;; Full header: ΕΦΗΜΕΡΙΔΑ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ
      (cl-ppcre:scan "[ΕE][ΦF][ΗH][ΜM][ΕE][ΡP][ΙI].?[ΑA]\\s+[TΤ][HΗ][ΣS]\\s+[ΚK][ΥY][ΒB][ΕE][ΡP][ΝN][ΗH][ΣS][ΕE]" text)
      ;; Partial header with page number
      (and (cl-ppcre:scan "[ΕE][ΦF][ΗH][ΜM][ΕE][ΡP][ΙI]" text)
           (cl-ppcre:scan "\\d{3,5}" text))
      ;; Issue identifier: Τεύχος A' 211
      (cl-ppcre:scan "[ΤT][εe][ύu][χx][οo][ςs]\\s+[ΑΒΓΔABCD]['΄']?\\s*\\d+" text)))

(defun section-header-pattern-p (text)
  "DARPA-GRADE: Consolidated section header detection (ΜΕΡΟΣ/ΚΕΦΑΛΑΙΟ/ΤΜΗΜΑ).
   Handles all Greek/Latin character variants."
  (or ;; ΜΕΡΟΣ
      (cl-ppcre:scan "[MΜ][EΕ][PΡ][OΟ][SΣ]\\s+[A-ZΑ-Ω]" text)
      ;; ΚΕΦΑΛΑΙΟ
      (cl-ppcre:scan "[KΚ][EΕ][FΦ][AΑ][LΛ][AΑ][IΙ][OΟ]\\s" text)
      ;; ΤΜΗΜΑ
      (cl-ppcre:scan "[TΤ][MΜ][HΗ][MΜ][AΑ]\\s+[A-ZΑ-Ω]" text)
      ;; ΕΝΟΤΗΤΑ
      (cl-ppcre:scan "[EΕ][NΝ][OΟ][TΤ][HΗ][TΤ][AΑ]\\s" text)))

;; CONSOLIDATED RULES (using helper functions)

(defrule fek-header-consolidated (:priority 95)
  (fek-header-pattern-p (typographic-features-raw-text features))
  :header)

(defrule fek-page-element (:priority 91)
  ;; Page numbers at top or date at bottom
  (or (and (> (typographic-features-relative-y features) 0.85)
           (cl-ppcre:scan "^\\s*\\d{3,5}\\s*$" (typographic-features-raw-text features)))
      (and (< (typographic-features-relative-y features) 0.15)
           (cl-ppcre:scan "\\d{1,2}[./\\-]\\d{1,2}[./\\-]\\d{4}" (typographic-features-raw-text features))
           (< (typographic-features-char-count features) 30)))
  :header)

(defrule section-header-consolidated (:priority 96)
  (section-header-pattern-p (typographic-features-raw-text features))
  :section-header)

;; ══════════════════════════════════════════════════════════════════
;; LEGACY RULES (kept for backward compatibility but lower priority)
;; These will be matched by consolidated rules first
;; ══════════════════════════════════════════════════════════════════

(defrule section-kefalaio-anywhere (:priority 85)
  ;; ΚΕΦΑΛΑΙΟ appearing anywhere (not just at start)
  (cl-ppcre:scan "[KΚ][EΕ][FΦ][AΑ][LΛ][AΑ][IΙ][OΟ]\\s+[A-ZΑ-Ω]" (typographic-features-raw-text features))
  :section-header)

(defrule section-tmima (:priority 96)
  ;; "ΤΜΗΜΑ Α'" etc.
  ;; T/Τ, M/Μ, H/Η, A/Α
  (cl-ppcre:scan "^\\s*[TΤ][MΜ][HΗ][MΜ][AΑ]\\s" (typographic-features-raw-text features))
  :section-header)

(defrule section-tmima-anywhere (:priority 95)
  ;; ΤΜΗΜΑ appearing anywhere (not just at start)
  (cl-ppcre:scan "[TΤ][MΜ][HΗ][MΜ][AΑ]\\s+[A-ZΑ-Ω]['΄']?" (typographic-features-raw-text features))
  :section-header)

(defrule section-enothta (:priority 96)
  ;; "ΕΝΟΤΗΤΑ" section markers
  (cl-ppcre:scan "^\\s*[EΕ][NΝ][OΟ][TΤ][HΗ][TΤ][AΑ]\\s" (typographic-features-raw-text features))
  :section-header)

;; ══════════════════════════════════════════════════════════════════
;; CLOSING SECTION
;; ══════════════════════════════════════════════════════════════════

(defrule date-place (:priority 68)
  (typographic-features-is-date-place features)
  :date-place)

(defrule signature-block (:priority 65)
  (and (eq state :in-signature)
       (< (typographic-features-relative-y features) 0.3))
  :signature)

(defrule signature-by-content (:priority 64)
  (and (typographic-features-is-short features)
       (< (typographic-features-line-count features) 3)
       (typographic-features-is-centered features))
  :signature)

;; ══════════════════════════════════════════════════════════════════
;; FALLBACKS
;; ══════════════════════════════════════════════════════════════════

(defrule paragraph-default (:priority 10)
  t
  :paragraph)

;;; ============================================================================
;;; FSM STATE TRANSITIONS
;;; ============================================================================

(defun fsm-next-state (current-state block-type)
  "Compute next FSM state based on current state and classified block type.

   NSA-GRADE: Extended state machine for Greek legal documents.

   LISP FEATURES:
     - CASE dispatch for efficient state lookup
     - Nested CASE for transition matrix
     - Returns keyword for next state"
  (case current-state
    ;; ══════════════════════════════════════════════════════════════════
    ;; DOCUMENT START
    ;; ══════════════════════════════════════════════════════════════════
    (:start
     (case block-type
       (:title :in-preamble)
       (:chapter-header :in-chapter)
       (:article-header :in-article)
       (otherwise :in-preamble)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; PREAMBLE (before articles)
    ;; ══════════════════════════════════════════════════════════════════
    (:in-preamble
     (case block-type
       (:chapter-header :in-chapter)
       (:article-header :in-article)
       (:signature :in-signature)
       (:transitional :in-transitional)
       (otherwise :in-preamble)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; CHAPTER/SECTION (ΜΕΡΟΣ, ΚΕΦΑΛΑΙΟ)
    ;; ══════════════════════════════════════════════════════════════════
    (:in-chapter
     (case block-type
       (:chapter-header :in-chapter)  ; New chapter
       (:article-header :in-article)
       (:transitional :in-transitional)
       (:signature :in-signature)
       (otherwise :in-chapter)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; ARTICLE (Άρθρο X)
    ;; ══════════════════════════════════════════════════════════════════
    (:in-article
     (case block-type
       (:chapter-header :in-chapter)
       (:article-header :in-article)  ; New article
       (:paragraph-num :in-paragraph)
       (:point :in-points)
       (:amendment :in-amendment)
       (:transitional :in-transitional)
       (:signature :in-closing)
       (:date-place :in-closing)
       (otherwise :in-article)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; PARAGRAPH (inside article)
    ;; ══════════════════════════════════════════════════════════════════
    (:in-paragraph
     (case block-type
       (:chapter-header :in-chapter)
       (:article-header :in-article)
       (:paragraph-num :in-paragraph)  ; New paragraph
       (:point :in-points)
       (:sub-point :in-points)
       (:amendment :in-amendment)
       (:transitional :in-transitional)
       (:signature :in-closing)
       (otherwise :in-paragraph)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; POINTS (α, β, γ enumeration)
    ;; ══════════════════════════════════════════════════════════════════
    (:in-points
     (case block-type
       (:chapter-header :in-chapter)
       (:article-header :in-article)
       (:paragraph-num :in-paragraph)
       (:point :in-points)           ; Next point
       (:sub-point :in-points)       ; Sub-point
       (:case-marker :in-points)     ; περίπτωση
       (:signature :in-closing)
       (otherwise :in-points)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; AMENDMENT SECTION
    ;; ══════════════════════════════════════════════════════════════════
    (:in-amendment
     (case block-type
       (:chapter-header :in-chapter)
       (:article-header :in-article)
       (:amendment :in-amendment)    ; Chained amendments
       (:repeal :in-amendment)
       (:addition :in-amendment)
       (:transitional :in-transitional)
       (:signature :in-closing)
       (otherwise :in-amendment)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; TRANSITIONAL PROVISIONS
    ;; ══════════════════════════════════════════════════════════════════
    (:in-transitional
     (case block-type
       (:article-header :in-article)
       (:signature :in-closing)
       (:date-place :in-closing)
       (:effective-date :in-transitional)
       (otherwise :in-transitional)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; CLOSING SECTION
    ;; ══════════════════════════════════════════════════════════════════
    (:in-closing
     (case block-type
       (:signature :in-signature)
       (:date-place :in-closing)
       (:attestation :in-closing)
       (otherwise :in-closing)))

    ;; ══════════════════════════════════════════════════════════════════
    ;; SIGNATURE AREA (final)
    ;; ══════════════════════════════════════════════════════════════════
    (:in-signature
     :in-signature)  ; Terminal state

    ;; Default: stay in current state
    (otherwise current-state)))

;;; ============================================================================
;;; MAIN CLASSIFICATION LOGIC
;;; ============================================================================

(defun apply-rules (features state last-type)
  "Apply classification rules and return best match.

   Returns: (values block-type confidence)"
  (multiple-value-bind (block-type confidence rule-name alternatives)
      (apply-rules-with-audit features state last-type)
    (declare (ignore rule-name alternatives))
    (values block-type confidence)))

(defun apply-rules-with-audit (features state last-type)
  "DARPA-GRADE: Apply rules with full audit information.

   Returns: (values block-type confidence matched-rule-name alternative-matches)

   alternative-matches is a list of (rule-name priority result-type) for all
   rules that matched but weren't selected (lower priority)."
  (let ((sorted-rules (sort (copy-list *classification-rules*) #'>
                            :key #'second))
        (best-type :unknown)
        (best-priority 0)
        (best-rule-name nil)
        (alternatives '()))

    (dolist (rule sorted-rules)
      (destructuring-bind (name priority test-fn result-type) rule
        (when (funcall test-fn features state last-type)
          (if (> priority best-priority)
              ;; New best match
              (progn
                ;; Demote previous best to alternatives
                (when best-rule-name
                  (push (list best-rule-name best-priority best-type) alternatives))
                (setf best-type result-type
                      best-priority priority
                      best-rule-name name))
              ;; Lower priority match - add to alternatives
              (push (list name priority result-type) alternatives)))))

    ;; Confidence: base from priority + bonus for no close alternatives
    (let* ((base-confidence (/ (min best-priority 100) 100.0))
           ;; Penalty if there are high-priority alternatives (ambiguity)
           (closest-alt-priority (if alternatives
                                     (reduce #'max alternatives :key #'second)
                                     0))
           (ambiguity-penalty (if (> closest-alt-priority (* best-priority 0.8))
                                  0.1  ; Close alternative = less confident
                                  0.0))
           (final-confidence (max 0.1 (- base-confidence ambiguity-penalty))))

      (values best-type
              (coerce final-confidence 'single-float)
              best-rule-name
              alternatives))))

(defstruct classification-audit-entry
  "DARPA-GRADE: Audit trail entry for each classification decision."
  (timestamp (get-universal-time) :type integer)
  (block-id "" :type string)
  (input-text "" :type string)
  (fsm-state-before nil :type keyword)
  (fsm-state-after nil :type keyword)
  (matched-rule nil :type symbol)
  (rule-priority 0 :type integer)
  (result-type nil :type keyword)
  (confidence 0.0 :type single-float)
  (alternative-matches nil :type list))

(defun classifier-process-block (classifier block
                                 &key (page-width 612.0) (page-height 792.0))
  "Process a single block through the classifier FSM.

   DARPA-GRADE: Full audit trail for every classification decision.

   Args:
     classifier: block-classifier instance
     block: layout-block to classify
     page-width/height: For relative positioning

   Returns:
     logical-block with classification"
  ;; Extract features
  (let* ((features (compute-typographic-features block
                                                 :page-width page-width
                                                 :page-height page-height))
         (state-before (classifier-state classifier)))

    ;; Apply rules with full match info
    (multiple-value-bind (block-type confidence matched-rule alternatives)
        (apply-rules-with-audit features
                                (classifier-state classifier)
                                (classifier-last-type classifier))

      ;; Update FSM state
      (let ((state-after (fsm-next-state state-before block-type)))
        (setf (classifier-state classifier) state-after)
        (setf (classifier-last-type classifier) block-type)

        ;; Track articles
        (when (eq block-type :article-header)
          (incf (classifier-article-count classifier)))

        ;; DARPA-GRADE: Record audit entry
        (push (make-classification-audit-entry
               :block-id (or (block-id block) "unknown")
               :input-text (subseq (typographic-features-raw-text features)
                                   0 (min 80 (length (typographic-features-raw-text features))))
               :fsm-state-before state-before
               :fsm-state-after state-after
               :matched-rule matched-rule
               :rule-priority (or (second (find matched-rule *classification-rules* :key #'first)) 0)
               :result-type block-type
               :confidence confidence
               :alternative-matches alternatives)
              (classifier-log classifier))

        ;; Create logical block
        (make-logical-block
         :block-type block-type
         :layout-block block
         :confidence confidence
         :features features)))))

;;; ============================================================================
;;; HIGH-LEVEL CLASSIFICATION API
;;; ============================================================================

(defun classify-block (block &key (page-width 612.0) (page-height 792.0)
                                  (classifier nil))
  "Classify a single layout block.

   Args:
     block: layout-block to classify
     page-width/height: For relative positioning
     classifier: Optional FSM classifier (creates new if nil)

   Returns:
     logical-block"
  (let ((clf (or classifier (make-block-classifier))))
    (classifier-process-block clf block
                              :page-width page-width
                              :page-height page-height)))

(defun classify-page (page &key (classifier nil))
  "Classify all blocks on a page.

   Args:
     page: layout-page
     classifier: Optional classifier (creates new if nil)

   Returns:
     List of logical-block objects"
  (let ((clf (or classifier (make-block-classifier)))
        (page-w (page-width page))
        (page-h (page-height page)))
    (mapcar (lambda (block)
              (classifier-process-block clf block
                                        :page-width page-w
                                        :page-height page-h))
            (page-blocks page))))

(defun classify-document (document)
  "Classify all blocks in a document.

   Args:
     document: layout-document

   Returns:
     List of (page-number . logical-blocks) pairs"
  (let ((classifier (make-block-classifier)))
    (loop for page in (orchestrator.layout-types:document-pages document)
          collect (cons (orchestrator.layout-types:page-number page)
                        (classify-page page :classifier classifier)))))

;;; ============================================================================
;;; CONTEXT MACRO
;;; ============================================================================

(defmacro with-classifier-state ((classifier-var &key initial-state) &body body)
  "Execute body with a classifier in specified state.

   Usage:
     (with-classifier-state (clf :initial-state :in-article)
       (classify-block block :classifier clf))"
  `(let ((,classifier-var (make-block-classifier)))
     ,@(when initial-state
         `((setf (classifier-state ,classifier-var) ,initial-state)))
     ,@body))

;;; ============================================================================
;;; RESET COUNTERS
;;; ============================================================================

(defun reset-logical-block-counter ()
  "Reset logical block counter."
  (setf *logical-block-counter* 0))

;;; ============================================================================
;;; DARPA-GRADE AUDIT & DIAGNOSTICS
;;; ============================================================================

(defun classifier-audit-report (classifier &key (stream *standard-output*))
  "Generate human-readable audit report of classification decisions.

   DARPA-GRADE: Full transparency into classifier behavior."
  (format stream "~%═══════════════════════════════════════════════════════════════~%")
  (format stream "CLASSIFICATION AUDIT REPORT~%")
  (format stream "═══════════════════════════════════════════════════════════════~%")
  (format stream "Total blocks classified: ~D~%" (length (classifier-log classifier)))
  (format stream "Final FSM state: ~A~%" (classifier-state classifier))
  (format stream "Articles found: ~D~%" (classifier-article-count classifier))
  (format stream "───────────────────────────────────────────────────────────────~%")

  (dolist (entry (reverse (classifier-log classifier)))
    (format stream "~%[~A] ~A~%"
            (classification-audit-entry-block-id entry)
            (classification-audit-entry-input-text entry))
    (format stream "  State: ~A → ~A~%"
            (classification-audit-entry-fsm-state-before entry)
            (classification-audit-entry-fsm-state-after entry))
    (format stream "  Rule: ~A (priority ~D) → ~A (conf: ~,2F)~%"
            (classification-audit-entry-matched-rule entry)
            (classification-audit-entry-rule-priority entry)
            (classification-audit-entry-result-type entry)
            (classification-audit-entry-confidence entry))
    (when (classification-audit-entry-alternative-matches entry)
      (format stream "  Alternatives: ~{~A~^, ~}~%"
              (mapcar #'first (classification-audit-entry-alternative-matches entry)))))

  (format stream "~%═══════════════════════════════════════════════════════════════~%"))

(defun classifier-audit-to-sexp (classifier)
  "Export audit log as S-expression for programmatic analysis.

   DARPA-GRADE: Machine-readable audit trail."
  (list :classifier-audit
        :total-blocks (length (classifier-log classifier))
        :final-state (classifier-state classifier)
        :articles-found (classifier-article-count classifier)
        :entries
        (mapcar (lambda (entry)
                  (list :block-id (classification-audit-entry-block-id entry)
                        :text (classification-audit-entry-input-text entry)
                        :state-before (classification-audit-entry-fsm-state-before entry)
                        :state-after (classification-audit-entry-fsm-state-after entry)
                        :matched-rule (classification-audit-entry-matched-rule entry)
                        :priority (classification-audit-entry-rule-priority entry)
                        :result (classification-audit-entry-result-type entry)
                        :confidence (classification-audit-entry-confidence entry)
                        :alternatives (classification-audit-entry-alternative-matches entry)))
                (reverse (classifier-log classifier)))))

(defun classifier-statistics (classifier)
  "Compute classification statistics.

   Returns: plist with :type-counts :avg-confidence :ambiguous-count"
  (let ((type-counts (make-hash-table))
        (total-confidence 0.0)
        (ambiguous-count 0))

    (dolist (entry (classifier-log classifier))
      (incf (gethash (classification-audit-entry-result-type entry) type-counts 0))
      (incf total-confidence (classification-audit-entry-confidence entry))
      (when (> (length (classification-audit-entry-alternative-matches entry)) 2)
        (incf ambiguous-count)))

    (list :type-counts (loop for k being the hash-keys of type-counts
                             using (hash-value v)
                             collect (cons k v))
          :avg-confidence (if (> (length (classifier-log classifier)) 0)
                              (/ total-confidence (length (classifier-log classifier)))
                              0.0)
          :ambiguous-count ambiguous-count
          :total-blocks (length (classifier-log classifier)))))

;;; ============================================================================
;;; END OF TYPOGRAPHIC-CLASSIFIER.LISP
;;; ============================================================================
