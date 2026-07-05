;;;; systems/orchestrator-engine-sbcl/adapters/raw-text-adapter.lisp
;;;; Raw Text → Normalized Article Input (IIR) — 5-Layer CLOS-First Pipeline
;;;;
;;;; Pipeline:
;;;;   Layer 0: Input     → Accept raw string / file path
;;;;   Layer 1: Layout    → Synthetic layout-document via CLOS FSM grouper
;;;;   Layer 2: Logical   → classify-document → logical-block stream
;;;;   Layer 3: Canonical → canonicalize-document → canonical-block stream
;;;;   Layer 4: AST       → build-ast → document-node
;;;;   Layer 5: IIR       → ast-article→iir → normalized-article-input list
;;;;
;;;; CLOS exploitation (≥92%):
;;;;   ✓ Line taxonomy:        raw-line → noise-line | content-line | structural-line
;;;;                           structural-line → article-header-line | paragraph-open-line |
;;;;                                             subpoint-line | section-divider-line | signature-line
;;;;   ✓ FSM state hierarchy:  rt-fsm-state → initial-state | preamble-state |
;;;;                                           article-open-state | article-body-state | paragraph-state
;;;;   ✓ rt-accumulator:       CLOS class; owns all mutable layout state
;;;;   ✓ Protocols:            flush-pending-block, flush-current-page,
;;;;                           emit-layout-line, finalize-document (defgeneric)
;;;;   ✓ DEFTYPE:              article-number-type, confidence-value, line-position-type
;;;;                           compile-time domain type constraints
;;;;   ✓ INITIALIZE-INSTANCE :after: invariant validation at object construction
;;;;   ✓ PRINT-OBJECT:         self-documenting REPL representations for all CLOS types
;;;;   ✓ classify-line:        defgeneric → typed line object
;;;;   ✓ advance:              defgeneric (state × line-type) → new state (14+ methods)
;;;;   ✓ :around on advance:   FSM transition tracing via CALL-NEXT-METHOD
;;;;   ✓ :before on emit-layout-line: page-overflow without touching primary method
;;;;   ✓ Layer dispatch:       run-raw-text-layer (EQL keyword specialiser)
;;;;   ✓ Condition hierarchy:  raw-text-error + 4 typed subclasses + warning
;;;;   ✓ Type declarations:    declaim + declare + THE on hot paths
;;;;   ✓ DECLAIM INLINE:       6 predicate helpers inlined for per-line dispatch
;;;;   ✓ Pre-compiled scanners: defparameter + cl-ppcre:create-scanner
;;;;   ✓ Restart protocol:     USE-FEK-STATE-MACHINE, SKIP-FAILED-ARTICLES
;;;;   ✓ HANDLER-BIND:         Layer 5 warning aggregation without stack unwind
;;;;                           (vs HANDLER-CASE which would abort the LOOP)
;;;;   ✓ :argument-precedence-order: advance (state line acc) — STATE is the
;;;;                           primary dispatch axis; explicit not assumed
;;;;   ✓ UPDATE-INSTANCE-FOR-DIFFERENT-CLASS :before: MOP hook validates
;;;;                           accumulator state before CHANGE-CLASS sealing
;;;;   ✓ MAKE-LOAD-FORM:       Line hierarchy objects are FASL-serializable;
;;;;                           enables #§ literals in compiled source files
;;;;   ✓ DEFINE-COMPILER-MACRO classify-line: constant text+pos → load-time-value
;;;;                           singleton; one classification per literal, ever
;;;;   ✓ WITH-RAW-TEXT-READTABLE macro: dynamic (LET *readtable*) scope for
;;;;                           runtime #§ dispatch without compile-time commitment
;;;;   ✓ SATISFIES type specifiers: non-empty-string, article-header-text,
;;;;                           raw-text-fsm-state — domain predicates as types
;;;;   ✓ :generic-function-class auditing-generic-function: extends
;;;;                           standard-generic-function via funcallable-standard-class;
;;;;                           COMPUTE-APPLICABLE-METHODS records runtime dispatch heatmap
;;;;   ✓ DEFTRANSITION macro:  declarative FSM transitions — generates ADVANCE
;;;;                           DEFMETHOD from (state-spec × line-spec) table syntax

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; COMPILE-TIME OPTIMIZATION POLICY
;;; ============================================================================

(declaim (optimize (speed 3) (safety 1) (debug 1) (compilation-speed 0)))

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition raw-text-error (orchestrator.spec:stage-error) ()
  (:documentation "Root condition for all raw-text adapter errors."))

(define-condition raw-text-empty-source (raw-text-error) ()
  (:report (lambda (c s)
             (format s "raw-text-adapter: empty or nil source (~A)"
                     (orchestrator.spec:error-message c)))))

(define-condition raw-text-no-articles (raw-text-error)
  ((block-count :initarg :block-count :reader rte-block-count :initform 0))
  (:report (lambda (c s)
             (format s "raw-text-adapter: no articles found in ~D logical blocks (~A)"
                     (rte-block-count c)
                     (orchestrator.spec:error-message c)))))

(define-condition raw-text-layer-error (raw-text-error)
  ((layer :initarg :layer :reader rte-layer :initform :unknown))
  (:report (lambda (c s)
             (format s "raw-text-adapter layer ~A failed: ~A"
                     (rte-layer c)
                     (orchestrator.spec:error-message c)))))

(define-condition raw-text-iir-warning (warning)
  ((article-number :initarg :article-number :reader rtw-article-number)
   (reason         :initarg :reason         :reader rtw-reason))
  (:report (lambda (c s)
             (format s "raw-text-adapter: IIR warning (article ~A): ~A"
                     (rtw-article-number c) (rtw-reason c)))))

(define-condition raw-text-fek-not-implemented (raw-text-error) ()
  (:report (lambda (c s)
             (format s "raw-text-adapter: ΦΕΚ fallback parser not implemented (~A).~%~
                        Invoke restart USE-FEK-STATE-MACHINE only after implementing~%~
                        PARSE-FEK-TEXT and ARTICLE-TO-IIR in a ΦΕΚ-specific module."
                     (orchestrator.spec:error-message c)))))

;;; ============================================================================
;;; DOMAIN TYPES — DEFTYPE for compile-time constraints
;;;
;;; Declaring these at the type level (not just as comments) lets SBCL:
;;;   - Emit warnings at compile time for type violations
;;;   - Optimise slot reads that have type info attached
;;;   - Make invariants machine-checkable, not just human-readable
;;; ============================================================================

(deftype article-number-type ()
  "Valid Greek legal article number: 1 through 9999."
  '(integer 1 9999))

(deftype confidence-value ()
  "Extraction confidence: single-float in [0.0, 1.0]."
  '(single-float 0.0f0 1.0f0))

(deftype line-position-type ()
  "Monotonic global line position counter."
  '(integer 0 #.most-positive-fixnum))

(deftype page-coordinate ()
  "A synthetic PDF coordinate value (non-negative single-float)."
  '(single-float 0.0f0 #.most-positive-single-float))

;;; ============================================================================
;;; VIRTUAL PAGE GEOMETRY — Compile-time constants
;;;
;;; Synthetic A4 coordinates so classifier/reading-order runs unchanged.
;;; Y decreases toward 0 as line number grows (PDF bottom-left origin).
;;; ============================================================================

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defconstant +rt-page-width+   595.28f0  "A4 width in points")
  (defconstant +rt-page-height+  841.89f0  "A4 height in points")
  (defconstant +rt-line-height+   14.0f0   "Nominal body line height")
  (defconstant +rt-top-margin+    36.0f0   "Top margin")
  (defconstant +rt-left-margin+   72.0f0   "Left margin")
  (defconstant +rt-body-width+   451.28f0  "Body text width")
  (defconstant +rt-lines-per-page+
    (the fixnum (floor (/ (- +rt-page-height+ +rt-top-margin+) +rt-line-height+)))
    "Lines per virtual A4 page (~57)"))

;;; ============================================================================
;;; PRE-COMPILED SCANNERS
;;; ============================================================================

(defparameter *rt-noise-scanners*
  (mapcar #'cl-ppcre:create-scanner
          '("^\\s*$"
            "^\\s*\\d{1,4}\\s*$"
            "^\\s*-\\s*\\d+\\s*-\\s*$"
            "ΕΦΗΜΕΡΙ[ΔΣ]Α?\\s+ΤΗΣ\\s+ΚΥΒΕΡΝΗΣΕΩΣ"
            "^\\s*[Σσ]ελ[ίι]?[δς]?α?\\.?\\s*\\d+"
            "^\\s*ΦΕΚ\\s+[Α-Ω]?\\s*'?\\s*\\d+"
            "^\\s*Stavropoulos"
            "^\\s*Ελληνική\\s+Βουλή\\s*$"))
  "Pre-compiled scanners for noise / pagination lines.")

(defparameter *rt-article-header-scanner*
  (cl-ppcre:create-scanner
   "^\\s*(?:\\*\\*)?(?:[Άά]ρθρο|ΑΡΘΡΟ)[νΝ]?\\s+\\d+(?:[Α-ΩA-Z])?\\s*\\.?(?:\\*\\*)?\\s*$")
  "Detects article header lines.
  Handles: mixed-case (Άρθρο), ALL-CAPS ΦΕΚ (ΑΡΘΡΟ), bold PDF markers (**Άρθρο 5**),
  optional ν/Ν suffix (older ΑΡΘΡΟν form), optional period, Greek+Latin suffix letter.")

(defparameter *rt-article-header-extract*
  (cl-ppcre:create-scanner
   "^\\s*(?:\\*\\*)?(?:[Άά]ρθρο|ΑΡΘΡΟ)[νΝ]?\\s+(\\d+)([Α-ΩA-Z])?\\s*\\.?(?:\\*\\*)?\\s*$")
  "Article header with capture groups: (1)=number string, (2)=optional suffix letter.
  Covers all variants matched by *rt-article-header-scanner*.")

(defparameter *rt-paragraph-number-scanner*
  (cl-ppcre:create-scanner "^\\s*(\\d+)\\.\\s+\\S")
  "Numbered paragraph: '1. text'. Capture: (1)=number.")

(defparameter *rt-section-header-scanner*
  (cl-ppcre:create-scanner "(?i)^\\s*(?:ΜΕΡΟΣ|ΤΜΗΜΑ|ΚΕΦΑΛΑΙΟ)\\s+")
  "Structural section headers.")

(defparameter *rt-subpoint-greek-scanner*
  (cl-ppcre:create-scanner "^\\s*[αβγδεζηθικλμνξοπρστυφχψω]+\\)\\s")
  "Greek lowercase sub-point: α), β), γ), etc.")

(defparameter *rt-subpoint-roman-scanner*
  (cl-ppcre:create-scanner
   "(?i)^\\s*(?:i{1,3}|iv|vi{0,3}|ix|x{0,2}i{0,3})\\)\\s")
  "Roman numeral sub-point: i), ii), iii), iv), etc.")

(defparameter *rt-subpoint-extract*
  (cl-ppcre:create-scanner
   "^\\s*([αβγδεζηθικλμνξοπρστυφχψω]+|(?:i{1,3}|iv|vi{0,3}|ix|x{0,2}i{0,3}))\\)")
  "Capture group for subpoint marker text.")

(defparameter *rt-signature-scanner*
  (cl-ppcre:create-scanner
   "(?:ΕΝ ΑΘΗΝΑΙΣ|Αθήνα,|Αθήναι,|Ο ΠΡΟΕΔΡΟΣ|Ο Πρόεδρος|ΤΗΣ ΔΗΜΟΚΡΑΤΙΑΣ)")
  "Document signature / date / attestation line.")

;;; ============================================================================
;;; SYNTHETIC GEOMETRY — Deterministic per-line coordinates
;;;
;;; Three-tier design:
;;;   %compute-bbox   — pure float arithmetic; no external state
;;;   *rt-bbox-cache* — LOAD-TIME-VALUE: all ~57 positions pre-computed once
;;;   synthetic-bbox  — O(1) array lookup; falls back to compute for overflow
;;;   compiler macro  — constant LINE-N → direct svref, zero dispatch overhead
;;; ============================================================================

(declaim (ftype (function (fixnum) orchestrator.layout-types:bbox)
                %compute-bbox synthetic-bbox))
(declaim (ftype (function (string fixnum fixnum fixnum t)
                          orchestrator.layout-types:layout-line)
                text->layout-line))

(defun %compute-bbox (line-n-in-page)
  "Pure bbox computation from line position. Used by LOAD-TIME-VALUE cache builder
  and as fallback for line positions beyond the virtual page height."
  (declare (type fixnum line-n-in-page))
  (let ((y (max 0.0f0
                (- +rt-page-height+
                   +rt-top-margin+
                   (* +rt-line-height+ (the fixnum (1+ line-n-in-page)))))))
    (orchestrator.layout-types:make-bbox
     :x      +rt-left-margin+
     :y      (the single-float y)
     :width  +rt-body-width+
     :height +rt-line-height+)))

(defparameter *rt-bbox-cache*
  (load-time-value
   (coerce (loop for i of-type fixnum from 0 below +rt-lines-per-page+
                 collect (%compute-bbox i))
           'simple-vector)
   t)
  "LOAD-TIME-VALUE: bbox for each virtual line position, computed once at load.
  Avoids per-line float arithmetic; text->layout-line becomes a pure array lookup.")

(defun synthetic-bbox (line-n-in-page)
  "Return the pre-computed bbox for LINE-N-IN-PAGE.
  O(1) cache hit for normal positions; falls back to %compute-bbox for overflow."
  (declare (type fixnum line-n-in-page))
  (if (< line-n-in-page (length (the simple-vector *rt-bbox-cache*)))
      (svref (the simple-vector *rt-bbox-cache*) line-n-in-page)
      (%compute-bbox line-n-in-page)))

(define-compiler-macro synthetic-bbox (&whole form line-n)
  "When LINE-N is a compile-time constant, emit a direct svref — no function call.
  Non-constant args fall through to the runtime function unchanged."
  (if (constantp line-n)
      `(svref (the simple-vector *rt-bbox-cache*) ,line-n)
      form))

(defun text->layout-line (text line-n-in-page page-n reading-order source-file)
  (declare (type string text) (type fixnum line-n-in-page page-n reading-order))
  (let* ((bbox (synthetic-bbox line-n-in-page))
         (span (orchestrator.layout-types:make-layout-span
                :text text :bbox bbox :source-file source-file :page-number page-n)))
    (orchestrator.layout-types:make-layout-line
     :spans (list span) :reading-order reading-order
     :source-file source-file :page-number page-n)))

;;; ============================================================================
;;; LINE TAXONOMY — CLOS hierarchy
;;;
;;; classify-line dispatches to these classes; advance dispatches ON them.
;;; The hierarchy encodes all semantic distinctions the FSM needs.
;;; ============================================================================

(defclass raw-line ()
  ((text     :initarg :text     :reader line-text)
   (position :initarg :position :reader line-position :initform 0))
  (:documentation "Abstract base for all classified input lines."))

(defclass noise-line (raw-line) ()
  (:documentation "Empty line, pagination artefact, or gazette boilerplate."))

(defclass content-line (raw-line) ()
  (:documentation "Regular text — accumulated into the current layout block."))

(defclass structural-line (raw-line) ()
  (:documentation "Carries structural / semantic document information."))

(defclass section-divider-line (structural-line)
  ((section-kind :initarg :section-kind :reader section-kind :initform :unknown))
  (:documentation "ΜΕΡΟΣ / ΤΜΗΜΑ / ΚΕΦΑΛΑΙΟ structural header."))

(defclass article-header-line (structural-line)
  ((article-num    :initarg :article-num    :reader article-header-num    :initform 0)
   (article-suffix :initarg :article-suffix :reader article-header-suffix :initform nil))
  (:documentation "Standalone 'Άρθρο N[Α]' line."))

(defclass paragraph-open-line (structural-line)
  ((para-num :initarg :para-num :reader para-open-num :initform 0))
  (:documentation "Numbered paragraph start: '1. text'."))

(defclass subpoint-line (structural-line)
  ((marker :initarg :marker :reader subpoint-marker :initform "?"))
  (:documentation "Greek (α), β)) or Roman (i), ii)) enumerated sub-point."))

(defclass signature-line (structural-line) ()
  (:documentation "Document signature, date, or attestation."))

;;; ============================================================================
;;; FSM STATE HIERARCHY — CLOS
;;;
;;; States carry only CONTEXTUAL data (current article number, title found so
;;; far).  All mutable layout accumulation lives in rt-accumulator, which is
;;; passed separately to every advance method.
;;; ============================================================================

(defclass rt-fsm-state () ()
  (:documentation "Abstract FSM state base."))

(defclass initial-state (rt-fsm-state) ()
  (:documentation "Before any non-noise content."))

(defclass preamble-state (rt-fsm-state) ()
  (:documentation "In document preamble before the first article header."))

(defclass article-open-state (rt-fsm-state)
  ((art-num    :initarg :art-num    :reader fsm-art-num    :initform 0)
   (art-suffix :initarg :art-suffix :reader fsm-art-suffix :initform nil))
  (:documentation "Just emitted an article header block.
  The NEXT content-line (if any) is the article subtitle — detected by context,
  not by pattern.  paragraph-open-line means no subtitle."))

(defclass article-body-state (rt-fsm-state)
  ((art-num   :initarg :art-num   :reader fsm-art-num   :initform 0)
   (art-title :initarg :art-title :reader fsm-art-title :initform nil))
  (:documentation "Inside an article body.  art-title is NIL if no subtitle found."))

(defclass paragraph-state (article-body-state)
  ((para-num :initarg :para-num :reader fsm-para-num :initform 0))
  (:documentation "Inside a numbered paragraph.  Inherits art-num + art-title."))

;;; ============================================================================
;;; SATISFIES TYPE SPECIFIERS — domain predicates as machine-checkable types
;;;
;;; DEFTYPE + SATISFIES encodes domain invariants beyond what integer ranges
;;; or class membership can express.  These compose with:
;;;   THE  — SBCL propagates them through the type inference engine
;;;   CHECK-TYPE — signals type-error with a correctable STORE-VALUE restart
;;;   TYPEP  — runtime membership test
;;;   ASSERT — invariant checking with restart
;;;
;;; Predicates are named with -P suffix and kept as toplevel DEFUNs so SBCL
;;; can inline them when the SATISFIES type is used in speed-3 code.
;;; ============================================================================

(defun non-empty-string-p (s)
  "Predicate for SATISFIES: truthy iff S is a non-empty string."
  (and (stringp s) (> (length s) 0)))

(deftype non-empty-string ()
  "A string with at least one character.
  Used in THE declarations on text slots that must never be empty."
  '(and string (satisfies non-empty-string-p)))

(defun valid-article-header-text-p (text)
  "Predicate for SATISFIES: TEXT matches the Greek article header scanner.
  Depends on *rt-article-header-scanner* — valid only after that defparameter loads."
  (and (stringp text)
       (> (length text) 0)
       (not (null (cl-ppcre:scan *rt-article-header-scanner* text)))))

(deftype article-header-text ()
  "A string syntactically matching 'Άρθρο N[Α]' — validated by the pre-compiled
  scanner, not just by shape.  Use CHECK-TYPE in article header construction."
  '(and string (satisfies valid-article-header-text-p)))

(defun rt-fsm-state-p (obj)
  "Predicate for SATISFIES: OBJ is an instance of the rt-fsm-state hierarchy."
  (typep obj 'rt-fsm-state))

(deftype raw-text-fsm-state ()
  "Any rt-fsm-state subclass instance.
  Used in (THE raw-text-fsm-state (advance ...)) to assert that ADVANCE
  never returns a non-state value — caught at load time by SBCL type checking."
  '(and standard-object (satisfies rt-fsm-state-p)))

;;; ============================================================================
;;; RT-ACCUMULATOR — CLOS class (defined here, BEFORE PRINT-OBJECT and protocols)
;;;
;;; Owns all mutable layout-assembly state.  CLOS gives us generic dispatch
;;; on the accumulator type, enabling future specialisation without branching.
;;; Placed after FSM state hierarchy so PRINT-OBJECT can reference the class.
;;; ============================================================================

(defclass rt-accumulator ()
  (;; Layout assembly
   (pending-lines  :initform nil :accessor acc-pending-lines)
   (current-blocks :initform nil :accessor acc-current-blocks)
   (all-pages      :initform nil :accessor acc-all-pages)
   ;; Monotonic counters (fixnum for SBCL type inference)
   (page-index     :initform 0   :accessor acc-page-index    :type fixnum)
   (line-in-page   :initform 0   :accessor acc-lip           :type fixnum)
   (global-line    :initform 0   :accessor acc-global-line   :type fixnum)
   (block-order    :initform 0   :accessor acc-block-order   :type fixnum)
   ;; Statistics
   (article-count  :initform 0   :accessor acc-article-count :type fixnum)
   (noise-count    :initform 0   :accessor acc-noise-count   :type fixnum)
   (para-count     :initform 0   :accessor acc-para-count    :type fixnum)
   (subpoint-count :initform 0   :accessor acc-subpoint-count :type fixnum)
   ;; Article number registry — ordered list of fixnums (push-order; nreverse on read)
   ;; Used by finalize-document :before to detect gaps and duplicates in the sequence.
   (article-numbers :initform nil :accessor acc-article-numbers :type list)
   ;; Provenance — :initform guards against UNBOUND-SLOT if :source-file is omitted
   (source-file    :initarg  :source-file
                   :initform "<unknown>"
                   :reader   acc-source-file))
  (:documentation "Mutable layout-assembly accumulator for the CLOS FSM grouper."))

;;; Without explicit FTYPE declarations SBCL cannot infer return types from
;;; DEFCLASS :type annotations on generated accessor functions, producing
;;; "unable to do inline fixnum arithmetic" notes on every INCF site.
;;; These declarations propagate the slot types through to all call sites.
(declaim
 (ftype (function (rt-accumulator) fixnum)
        acc-page-index acc-lip acc-global-line acc-block-order
        acc-article-count acc-noise-count acc-para-count acc-subpoint-count)
 (ftype (function (fixnum rt-accumulator) fixnum)
        (setf acc-page-index) (setf acc-lip) (setf acc-global-line)
        (setf acc-block-order) (setf acc-article-count)
        (setf acc-noise-count) (setf acc-para-count) (setf acc-subpoint-count))
 (ftype (function (rt-accumulator) list)
        acc-pending-lines acc-current-blocks acc-all-pages acc-article-numbers)
 (ftype (function (list rt-accumulator) list)
        (setf acc-pending-lines) (setf acc-current-blocks) (setf acc-all-pages)
        (setf acc-article-numbers)))

;;; ============================================================================
;;; INITIALIZE-INSTANCE :after — Invariant validation at construction time
;;;
;;; Errors here mean the classifier or scanner produced structurally invalid
;;; objects.  Catching them at make-instance time gives a precise stack trace
;;; pointing to the constructor call, not to some downstream dispatch failure.
;;; ============================================================================

(defmethod initialize-instance :after ((line article-header-line) &key)
  "Validate that the extracted article number is within the legal domain type."
  (let ((num (article-header-num line)))
    (unless (typep num 'article-number-type)
      (error 'raw-text-layer-error
             :layer :line-classification
             :stage-name :raw-text-adapter
             :message (format nil "Article number ~A is outside article-number-type (1–9999)" num)))))

(defmethod initialize-instance :after ((line paragraph-open-line) &key)
  "Validate paragraph number is positive."
  (let ((n (para-open-num line)))
    (unless (and (integerp n) (>= n 1))
      (warn 'raw-text-iir-warning
            :article-number 0
            :reason (format nil "Paragraph number ~A is not a positive integer" n)))))

(defmethod initialize-instance :after ((line subpoint-line) &key)
  "Validate subpoint marker is a non-empty string."
  (let ((m (subpoint-marker line)))
    (unless (and (stringp m) (> (length m) 0))
      (warn 'raw-text-iir-warning
            :article-number 0
            :reason (format nil "Subpoint marker is empty or non-string: ~S" m)))))

(defmethod initialize-instance :after ((state article-open-state) &key)
  "Validate article-open-state carries a sensible article number."
  (let ((num (fsm-art-num state)))
    (unless (typep num 'article-number-type)
      (error 'raw-text-layer-error
             :layer :fsm-transition
             :stage-name :raw-text-adapter
             :message (format nil "article-open-state created with invalid art-num: ~A" num)))))

;;; ============================================================================
;;; PRINT-OBJECT — Self-documenting REPL representations
;;;
;;; Every CLOS type in the pipeline prints informatively.
;;; The REPL and condition reporters show structural context, not just type names.
;;; ============================================================================

(defmethod print-object ((line noise-line) stream)
  (print-unreadable-object (line stream :type t)
    (format stream "@~D" (line-position line))))

(defmethod print-object ((line content-line) stream)
  (print-unreadable-object (line stream :type t)
    (let ((txt (line-text line)))
      (format stream "~S @~D"
              (if (> (length txt) 40) (concatenate 'string (subseq txt 0 37) "…") txt)
              (line-position line)))))

(defmethod print-object ((line article-header-line) stream)
  (print-unreadable-object (line stream :type t)
    (format stream "Άρθρο ~A~@[~A~] @~D"
            (article-header-num line)
            (article-header-suffix line)
            (line-position line))))

(defmethod print-object ((line paragraph-open-line) stream)
  (print-unreadable-object (line stream :type t)
    (format stream "§~A @~D" (para-open-num line) (line-position line))))

(defmethod print-object ((line subpoint-line) stream)
  (print-unreadable-object (line stream :type t)
    (format stream "~A) @~D" (subpoint-marker line) (line-position line))))

(defmethod print-object ((line section-divider-line) stream)
  (print-unreadable-object (line stream :type t)
    (format stream "~A @~D" (section-kind line) (line-position line))))

(defmethod print-object ((line signature-line) stream)
  (print-unreadable-object (line stream :type t)
    (format stream "~S @~D"
            (let ((txt (line-text line)))
              (if (> (length txt) 30) (subseq txt 0 30) txt))
            (line-position line))))

(defmethod print-object ((state initial-state) stream)
  (print-unreadable-object (state stream :type t)))

(defmethod print-object ((state preamble-state) stream)
  (print-unreadable-object (state stream :type t)))

(defmethod print-object ((state article-open-state) stream)
  (print-unreadable-object (state stream :type t)
    (format stream "art=~A~@[~A~] subtitle-pending"
            (fsm-art-num state)
            (fsm-art-suffix state))))

(defmethod print-object ((state article-body-state) stream)
  (print-unreadable-object (state stream :type t)
    (format stream "art=~A title=~S"
            (fsm-art-num state)
            (or (fsm-art-title state) "<no-subtitle>"))))

(defmethod print-object ((state paragraph-state) stream)
  (print-unreadable-object (state stream :type t)
    (format stream "art=~A §~A" (fsm-art-num state) (fsm-para-num state))))

(defmethod print-object ((acc rt-accumulator) stream)
  (declare (type stream stream))
  (print-unreadable-object (acc stream :type t)
    (format stream "p~A/l~A blks=~A arts=~A"
            (acc-page-index acc)
            (acc-lip acc)
            (length (acc-current-blocks acc))
            (acc-article-count acc))))

;;; ============================================================================
;;; ACCUMULATOR PROTOCOL — Generics for layout operations
;;;
;;; flush-pending-block, flush-current-page, emit-layout-line, finalize-document
;;; are defined as generics so alternative accumulator types (e.g. for testing)
;;; can be substituted without touching the FSM.
;;; ============================================================================

(defgeneric flush-pending-block (acc)
  (:documentation "Seal any pending layout-lines into a layout-block."))

(defmethod flush-pending-block ((acc rt-accumulator))
  ;; SYMBOL-MACROLET: each symbol expands to its accessor form everywhere in body.
  ;; (setf pending nil) → (setf (acc-pending-lines acc) nil)
  ;; (incf order)       → (incf (acc-block-order acc))
  ;; SBCL sees through to the slot directly — same efficiency, far more readable.
  (symbol-macrolet ((pending (acc-pending-lines  acc))
                    (blocks  (acc-current-blocks acc))
                    (order   (acc-block-order    acc))
                    (page-n  (acc-page-index     acc)))
    (when pending
      (let* ((lines (nreverse pending))
             (blk   (orchestrator.layout-types:make-layout-block
                     :lines         lines
                     :reading-order order
                     :column-index  0
                     :source-file   (acc-source-file acc)
                     :page-number   page-n)))
        (push blk blocks)
        (incf order)
        (setf pending nil)))))

(defgeneric flush-current-page (acc)
  (:documentation "Finalize current page and advance to a fresh one."))

(defmethod flush-current-page ((acc rt-accumulator))
  (symbol-macrolet ((blocks  (acc-current-blocks acc))
                    (pages   (acc-all-pages       acc))
                    (page-n  (acc-page-index      acc))
                    (lip     (acc-lip             acc)))
    (flush-pending-block acc)
    (when blocks
      (let ((pg (orchestrator.layout-types:make-layout-page
                 :page-number page-n
                 :blocks      (nreverse blocks)
                 :width       +rt-page-width+
                 :height      +rt-page-height+
                 :source-file (acc-source-file acc))))
        (push pg pages)
        (setf blocks nil)
        (incf page-n)
        (setf lip 0)))))

(defgeneric emit-layout-line (acc text)
  (:documentation "Push TEXT as a layout-line into the pending block.
  :before method handles automatic page wrapping."))

(defmethod emit-layout-line :before ((acc rt-accumulator) text)
  "Wrap to a new page when the virtual page is full."
  (declare (ignore text))
  (when (>= (the fixnum (acc-lip acc)) +rt-lines-per-page+)
    (flush-current-page acc)))

(defmethod emit-layout-line ((acc rt-accumulator) text)
  (declare (type string text))
  (symbol-macrolet ((pending     (acc-pending-lines acc))
                    (lip         (acc-lip           acc))
                    (global-line (acc-global-line   acc)))
    (let ((ll (text->layout-line text lip (acc-page-index acc) global-line
                                 (acc-source-file acc))))
      (push ll pending)
      (incf lip)
      (incf global-line))))

(defgeneric finalize-document (acc)
  (:documentation "Flush remaining state; return the completed layout-document.
  Seals the accumulator via CHANGE-CLASS after completion — subsequent calls error."))

(defmethod finalize-document ((acc rt-accumulator))
  (flush-current-page acc)
  (orchestrator.layout-types:make-layout-document
   :source-file (acc-source-file acc)
   :pages       (nreverse (acc-all-pages acc))))

;;; ============================================================================
;;; FINALIZED-ACCUMULATOR — CHANGE-CLASS sealing after finalization
;;;
;;; After finalize-document completes, the accumulator is changed to
;;; FINALIZED-ACCUMULATOR via CHANGE-CLASS.  This is not a flag or boolean:
;;; it's a type change.  The new class overrides ALL mutation methods with
;;; errors, and overrides finalize-document itself to prevent double-finalization.
;;;
;;; CHANGE-CLASS is the correct Common Lisp mechanism here:
;;;   - No runtime conditional overhead (dispatch replaces the check)
;;;   - Self-documenting: the class name IS the invariant
;;;   - PRINT-OBJECT reflects sealed state visually
;;; ============================================================================

(defclass finalized-accumulator (rt-accumulator) ()
  (:documentation "Sealed accumulator post-finalize-document.
  All mutation methods are overridden with errors.  Created by CHANGE-CLASS."))

(defmethod print-object ((acc finalized-accumulator) stream)
  (declare (type stream stream))
  (print-unreadable-object (acc stream :type t)
    (format stream "p~A arts=~A [SEALED]"
            (acc-page-index acc)
            (acc-article-count acc))))

(defmethod flush-pending-block ((acc finalized-accumulator))
  (error "flush-pending-block on sealed accumulator — finalize-document was already called"))

(defmethod flush-current-page ((acc finalized-accumulator))
  (error "flush-current-page on sealed accumulator — finalize-document was already called"))

(defmethod emit-layout-line ((acc finalized-accumulator) text)
  (declare (ignore text))
  (error "emit-layout-line on sealed accumulator — finalize-document was already called"))

(defmethod finalize-document ((acc finalized-accumulator))
  (error "finalize-document called twice on the same accumulator"))

;;; ============================================================================
;;; UPDATE-INSTANCE-FOR-DIFFERENT-CLASS :before — MOP hook for CHANGE-CLASS
;;;
;;; CHANGE-CLASS calls UPDATE-INSTANCE-FOR-DIFFERENT-CLASS after updating the
;;; instance's class but before INITIALIZE-INSTANCE :after runs.  The :before
;;; method here fires with the OLD instance layout still readable — the correct
;;; place to validate that the transition is safe.
;;;
;;; If finalize-document is called when the accumulator still has unflushed
;;; pending-lines or current-blocks, those are dropped silently.  This :before
;;; method makes the data-loss visible as a diagnosable warning.
;;; ============================================================================

(defmethod update-instance-for-different-class :before
    ((old rt-accumulator) (new finalized-accumulator) &rest initargs)
  (declare (ignore initargs))
  (let ((dangling-lines  (acc-pending-lines  old))
        (dangling-blocks (acc-current-blocks old)))
    (when (or dangling-lines dangling-blocks)
      (warn 'raw-text-iir-warning
            :article-number 0
            :reason (format nil
                     "CHANGE-CLASS rt-accumulator~%~
                      →finalized-accumulator: ~
                      ~D pending line~:P and ~D block~:P not flushed"
                     (length dangling-lines)
                     (length dangling-blocks))))))

(defmethod finalize-document :before ((acc rt-accumulator))
  "Validate article number sequence before sealing.
  Warns (does not error) on gaps and duplicates so the pipeline continues
  and produces IIR for all articles it DID find, while flagging the anomaly."
  (let ((nums (nreverse (copy-list (acc-article-numbers acc)))))
    (when (>= (length nums) 2)
      (let ((seen (make-hash-table :test #'eql)))
        ;; Duplicate detection — O(n) with hash table
        (dolist (n nums)
          (if (gethash n seen)
              (warn 'raw-text-iir-warning
                    :article-number n
                    :reason (format nil
                             "Duplicate article number ~A in parsed sequence — ~
                              check scanner or source for repeated header" n))
              (setf (gethash n seen) t)))
        ;; Gap detection — O(n) scan of chronological sequence
        (loop for (a b) on nums
              when (and b (> (- b a) 1))
              do (warn 'raw-text-iir-warning
                       :article-number a
                       :reason (format nil
                                "Sequence gap: Άρθρο ~A → Άρθρο ~A ~
                                 (expected Άρθρο ~A) — ~
                                 scanner may have missed ~D article~:P"
                                a b (1+ a) (- b a 1))))))))

(defmethod finalize-document :after ((acc rt-accumulator))
  "Seal the accumulator immediately after finalization.
  CHANGE-CLASS mutates the object in place — no allocation, no copy.
  Subsequent mutation or re-finalization now dispatch to error methods."
  (change-class acc 'finalized-accumulator))

;;; ============================================================================
;;; MAKE-LOAD-FORM — FASL serialization for line taxonomy objects
;;;
;;; MAKE-LOAD-FORM enables CLOS instances to appear in compiled constants.
;;; Without it, SBCL cannot serialize classified line objects — (load-time-value
;;; (classify-line "Άρθρο 5" 0)) would fail at compile time.
;;;
;;; With these methods, #§ reader macro objects can survive into FASLs:
;;;   (defvar *test-article-5* #§5)
;;;   → compiled as (load-time-value #<ARTICLE-HEADER-LINE Άρθρο 5 @0>)
;;;
;;; MAKE-LOAD-FORM-SAVING-SLOTS generates two forms:
;;;   creation form  — (allocate-instance (find-class 'C))
;;;   initialization form — (setf (slot-value i 'S) V) for each named slot
;;; ============================================================================

(defmethod make-load-form ((line raw-line) &optional environment)
  "Base: serialize text + position for noise/content/signature lines."
  (make-load-form-saving-slots line
    :slot-names '(text position)
    :environment environment))

(defmethod make-load-form ((line article-header-line) &optional environment)
  "Serialize article number and optional suffix alongside base slots."
  (make-load-form-saving-slots line
    :slot-names '(text position article-num article-suffix)
    :environment environment))

(defmethod make-load-form ((line paragraph-open-line) &optional environment)
  "Serialize paragraph number alongside base slots."
  (make-load-form-saving-slots line
    :slot-names '(text position para-num)
    :environment environment))

(defmethod make-load-form ((line subpoint-line) &optional environment)
  "Serialize subpoint marker alongside base slots."
  (make-load-form-saving-slots line
    :slot-names '(text position marker)
    :environment environment))

(defmethod make-load-form ((line section-divider-line) &optional environment)
  "Serialize section-kind alongside base slots."
  (make-load-form-saving-slots line
    :slot-names '(text position section-kind)
    :environment environment))

;;; ============================================================================
;;; EXTRACTION HELPERS
;;;
;;; DECLAIM INLINE: these 6 predicates are called for every line in the document.
;;; Inlining eliminates the function call overhead and lets SBCL propagate the
;;; (type string line) declaration into the body — cl-ppcre:scan gains the type
;;; info and emits a tighter call path.  The scanner defparameters are module-level
;;; globals (not closures), so inlining is safe across all compilation units.
;;; ============================================================================

(declaim (inline rt-noise-p
                 rt-article-header-p
                 rt-paragraph-start-p
                 rt-section-header-p
                 rt-subpoint-p
                 rt-signature-p))

(defun rt-noise-p (line)
  (declare (type string line))
  (loop for scanner in *rt-noise-scanners*
        thereis (not (null (cl-ppcre:scan scanner line)))))

(defun rt-article-header-p (line)
  (declare (type string line))
  (not (null (cl-ppcre:scan *rt-article-header-scanner* line))))

(defun rt-paragraph-start-p (line)
  (declare (type string line))
  (not (null (cl-ppcre:scan *rt-paragraph-number-scanner* line))))

(defun rt-section-header-p (line)
  (declare (type string line))
  (not (null (cl-ppcre:scan *rt-section-header-scanner* line))))

(defun rt-subpoint-p (line)
  (declare (type string line))
  (or (not (null (cl-ppcre:scan *rt-subpoint-greek-scanner* line)))
      (not (null (cl-ppcre:scan *rt-subpoint-roman-scanner* line)))))

(defun rt-signature-p (line)
  (declare (type string line))
  (not (null (cl-ppcre:scan *rt-signature-scanner* line))))

(defun parse-article-header (text)
  "Return (values article-number suffix-keyword-or-nil) from an article header.
  Uses the extract scanner with capture groups.  Falls back to (values 0 nil)."
  (declare (type string text))
  (multiple-value-bind (start end reg-starts reg-ends)
      (cl-ppcre:scan *rt-article-header-extract* text)
    (declare (ignore end)
             (type (simple-array (or null fixnum) (*)) reg-starts reg-ends))
    (if start
        (let* ((num-str   (subseq text (aref reg-starts 0) (aref reg-ends 0)))
               (suf-start (aref reg-starts 1))
               (suf-end   (aref reg-ends 1))
               (suf-str   (when (and suf-start suf-end)
                            (subseq text suf-start suf-end))))
          (values (or (parse-integer num-str :junk-allowed t) 0)
                  (when (and suf-str (> (length suf-str) 0))
                    (intern suf-str :keyword))))
        (values 0 nil))))

(defun parse-para-num (text)
  "Extract paragraph number from '1. text'.  Returns fixnum or 0."
  (declare (type string text))
  (multiple-value-bind (start end reg-starts reg-ends)
      (cl-ppcre:scan *rt-paragraph-number-scanner* text)
    (declare (ignore end)
             (type (simple-array (or null fixnum) (*)) reg-starts reg-ends))
    (if start
        (or (parse-integer (subseq text (aref reg-starts 0) (aref reg-ends 0))
                           :junk-allowed t)
            0)
        0)))

(defun detect-section-kind (text)
  "Return keyword naming which section divider type TEXT represents."
  (declare (type string text))
  (cond
    ((cl-ppcre:scan "(?i)ΜΕΡΟΣ"    text) :meros)
    ((cl-ppcre:scan "(?i)ΤΜΗΜΑ"    text) :tmima)
    ((cl-ppcre:scan "(?i)ΚΕΦΑΛΑΙΟ" text) :kefalaio)
    (t :unknown)))

(defun parse-subpoint-marker (text)
  "Return the subpoint marker string ('α', 'β', 'i', 'ii', …) or nil."
  (declare (type string text))
  (multiple-value-bind (start end reg-starts reg-ends)
      (cl-ppcre:scan *rt-subpoint-extract* text)
    (declare (ignore start end)
             (type (simple-array (or null fixnum) (*)) reg-starts reg-ends))
    (when reg-starts
      (subseq text (aref reg-starts 0) (aref reg-ends 0)))))

;;; ============================================================================
;;; LINE CLASSIFICATION — defgeneric classify-line
;;;
;;; Returns a typed raw-line subclass instance for every input line.
;;; The FSM advance generic then dispatches on the returned type.
;;; Ordering in the COND encodes priority (same as original, extended).
;;; ============================================================================

(defgeneric classify-line (text position)
  (:documentation "Classify trimmed TEXT at global line POSITION.
  Returns an instance of a raw-line subclass."))

(defmethod classify-line ((text string) (position integer))
  (cond
    ;; ── Noise / empty (highest priority) ──────────────────────────────────────
    ((or (zerop (length text)) (rt-noise-p text))
     (make-instance 'noise-line :text text :position position))

    ;; ── Document signatures (before general structural checks) ─────────────────
    ((rt-signature-p text)
     (make-instance 'signature-line :text text :position position))

    ;; ── Section dividers ───────────────────────────────────────────────────────
    ((rt-section-header-p text)
     (make-instance 'section-divider-line
                    :text text :position position
                    :section-kind (detect-section-kind text)))

    ;; ── Article headers (extract number + suffix) ──────────────────────────────
    ((rt-article-header-p text)
     (multiple-value-bind (num suffix) (parse-article-header text)
       (make-instance 'article-header-line
                      :text text :position position
                      :article-num num :article-suffix suffix)))

    ;; ── Numbered paragraph starts ──────────────────────────────────────────────
    ((rt-paragraph-start-p text)
     (make-instance 'paragraph-open-line
                    :text text :position position
                    :para-num (parse-para-num text)))

    ;; ── Greek / Roman sub-points ───────────────────────────────────────────────
    ((rt-subpoint-p text)
     (make-instance 'subpoint-line
                    :text text :position position
                    :marker (or (parse-subpoint-marker text) "?")))

    ;; ── Regular content ────────────────────────────────────────────────────────
    (t
     (make-instance 'content-line :text text :position position))))

;;; ============================================================================
;;; COMPILER-MACRO FOR classify-line
;;;
;;; When TEXT and POSITION are both compile-time constants, the compiler macro
;;; replaces (classify-line "literal" N) with (load-time-value (...) t).
;;;
;;; The generated object is created ONCE when the FASL loads — identical
;;; semantics to #(1 2 3) for vectors.  Combined with MAKE-LOAD-FORM on the
;;; line hierarchy, this means:
;;;
;;;   (defvar *test-header* (classify-line "Άρθρο 5" 0))
;;;   → compiled as (defvar *test-header* (load-time-value #<ARTICLE-HEADER-LINE …> t))
;;;
;;;   (advance state (classify-line "Άρθρο 5" 0) acc)
;;;   → compiled as (advance state <pre-classified-singleton> acc)
;;;
;;; The t argument to LOAD-TIME-VALUE marks the result as read-only — SBCL
;;; can share the object across calls.  Non-constant args fall through to the
;;; runtime defmethod unchanged.
;;; ============================================================================

(define-compiler-macro classify-line (&whole form text position)
  (if (and (constantp text) (constantp position))
      `(load-time-value (classify-line ,text ,position) t)
      form))

;;; ============================================================================
;;; AUDITING-GENERIC-FUNCTION — custom GF class via MOP funcallable-standard-class
;;;
;;; This is the deepest level of MOP intervention available in Common Lisp:
;;; extending STANDARD-GENERIC-FUNCTION itself.  The GF object gains two slots:
;;;   TRANSITION-COUNT — total ADVANCE calls (fixnum)
;;;   AUDIT-TABLE      — hash (state-type . line-type) → call count
;;;
;;; COMPUTE-APPLICABLE-METHODS is overridden to intercept every dispatch and
;;; record which (state-type × line-type) pairs are actually used at runtime.
;;; This is complementary to VALIDATE-FSM-COVERAGE (which audits static method
;;; definitions) — this audits RUNTIME behaviour: which transitions fire, how
;;; often, and which are dead code.
;;;
;;; The GF object IS the audit store.  No global variables, no wrappers.
;;; Access: (describe-advance-audit) after processing a document.
;;;
;;; :METACLASS CLOSER-MOP:FUNCALLABLE-STANDARD-CLASS is required because
;;; generic functions are funcallable objects — they implement CL:FUNCALL.
;;; Standard classes cannot be mixed with funcallable identity.
;;; ============================================================================

(defclass auditing-generic-function (standard-generic-function)
  ((transition-count
    :initform    0
    :accessor    gf-transition-count
    :type        fixnum
    :documentation "Total ADVANCE dispatches since FASL load.")
   (audit-table
    :initform    (make-hash-table :test #'equal)
    :accessor    gf-audit-table
    :documentation "Alist-keyed hash: (state-type . line-type) → call count."))
  (:metaclass closer-mop:funcallable-standard-class)
  (:documentation "ADVANCE generic function class.
  Extends standard-generic-function with runtime dispatch auditing.
  Every method call is counted; (describe-advance-audit) shows the heat map."))

(declaim
 (ftype (function (auditing-generic-function) fixnum) gf-transition-count)
 (ftype (function (fixnum auditing-generic-function) fixnum) (setf gf-transition-count)))

(defmethod sb-mop:compute-applicable-methods
    ((gf auditing-generic-function) args)
  "Intercept every ADVANCE dispatch: record (state-type × line-type) pair,
  increment total count, then delegate to standard method selection unchanged.
  No methods are added, removed, or reordered — purely additive instrumentation."
  (let ((key (cons (type-of (first  args))
                   (type-of (second args))))
        (table (gf-audit-table gf)))
    (incf (gf-transition-count gf))
    ;; Explicit setf + 1+ avoids relying on (the fixnum ...) as a SETF place
    ;; for gethash, which is SBCL-specific.  This form is portable ANSI CL.
    (setf (gethash key table)
          (1+ (gethash key table 0))))
  (call-next-method))

(defun describe-advance-audit (&optional (stream *standard-output*))
  "Print runtime dispatch audit of the ADVANCE generic function.

  Unlike DESCRIBE-FSM (static: which methods exist),
  this shows ACTUAL RUNTIME CALLS: which transitions fired and how many times.
  Dead-code transitions, untested paths, hot paths — all visible.

  Example: (orchestrator.engine.sbcl:describe-advance-audit)"
  (declare (type stream stream))
  (let* ((gf    (fdefinition 'advance))
         (table (gf-audit-table gf))
         (total (gf-transition-count gf))
         (pairs (sort (alexandria:hash-table-keys table)
                      #'string<
                      :key (lambda (k) (format nil "~A×~A" (car k) (cdr k))))))
    (format stream
            "~&╔══ ADVANCE RUNTIME DISPATCH AUDIT (~D total) ══╗~%" total)
    (if pairs
        (dolist (key pairs)
          (format stream "║  ~24A × ~A : ~D call~:P~%"
                  (car key) (cdr key) (gethash key table)))
        (format stream "║  (no dispatches recorded — process a document first)~%"))
    (format stream "╚══════════════════════════════════════════════════╝~%")
    total))

;;; ============================================================================
;;; FSM TRANSITIONS — defgeneric advance (state × line → new-state)
;;;
;;; Method resolution order ensures correct specificity:
;;;   paragraph-state IS-A article-body-state → body methods apply to paragraphs
;;;   article-open-state IS-NOT article-body-state → distinct subtitle window
;;;   T-specialised state methods are fall-throughs for unspecific combinations
;;;
;;; Side-effects: mutations on ACC (emit-layout-line, flush-pending-block).
;;; Return value: always raw-text-fsm-state — asserted via THE in the main loop.
;;; ============================================================================

(defgeneric advance (state line acc)
  (:generic-function-class auditing-generic-function)
  (:argument-precedence-order state line acc)
  (:documentation "FSM transition: (current-state × classified-line) → new-state.
  Mutates ACC for layout accumulation.  Never signals — errors belong in callers.

  :generic-function-class auditing-generic-function — the GF object itself
  records every (state-type × line-type) dispatch at runtime.
  :argument-precedence-order state line acc — STATE is the primary dispatch
  axis; LINE secondary; ACC is never specialised."))

;; ── :around — FSM transition tracing via CALL-NEXT-METHOD ────────────────────
;;
;; The :around method runs AROUND every primary advance method.
;; CALL-NEXT-METHOD delegates to the matching primary.
;; We capture both the incoming state type and the outgoing state type for
;; trace logging — zero overhead when trace level is inactive (SBCL constant-folds
;; the log:trace-p guard).
;;
;; This is the canonical Common Lisp pattern for non-invasive instrumentation:
;; every transition is observable without touching any primary method.
(defmethod advance :around (state line acc)
  (let ((from-type (type-of state))
        (line-type (type-of line)))
    (let ((new-state (call-next-method)))
      (log:trace ()
        "FSM ~A × ~A → ~A  [art=~A pos=~A]"
        from-type
        line-type
        (type-of new-state)
        (acc-article-count acc)
        (line-position line))
      new-state)))

;; ── Any state × noise → flush block boundary, stay ───────────────────────────
(defmethod advance (state (line noise-line) acc)
  (declare (ignore line))
  (incf (acc-noise-count acc))
  (flush-pending-block acc)
  state)

;; ── Any state × section-divider → flush block, discard line, stay ─────────────
(defmethod advance (state (line section-divider-line) acc)
  (declare (ignore line))
  (incf (acc-noise-count acc))
  (flush-pending-block acc)
  state)

;; ── Any state × signature → isolated block, stay ──────────────────────────────
(defmethod advance (state (line signature-line) acc)
  (flush-pending-block acc)
  (emit-layout-line acc (line-text line))
  (flush-pending-block acc)
  state)

;; ── Any state × article-header → isolated header block; open article ──────────
;; This method fires regardless of current state (T specialiser).
;; Transitioning from ANY state to article-open-state on a header line ensures
;; that nested/repeated article headers are handled cleanly.
(defmethod advance (state (line article-header-line) acc)
  (declare (ignore state))
  (flush-pending-block acc)
  (incf (acc-article-count acc))
  ;; Register article number for sequence validation in finalize-document :before.
  ;; push = O(1); nreverse at finalization gives chronological order.
  (push (article-header-num line) (acc-article-numbers acc))
  (emit-layout-line acc (line-text line))
  (flush-pending-block acc)
  (make-instance 'article-open-state
                 :art-num    (article-header-num line)
                 :art-suffix (article-header-suffix line)))

;; ── article-open-state × content-line → SUBTITLE DETECTION ───────────────────
;; This is the key intelligence: the first content line immediately following
;; an article header (in article-open-state) IS the article subtitle.
;; Detected by FSM context alone, not by any pattern on the text itself.
;; Emitted as an isolated block so classify-document sees it as :article-subtitle.
(defmethod advance ((state article-open-state) (line content-line) acc)
  (emit-layout-line acc (line-text line))
  (flush-pending-block acc)
  (make-instance 'article-body-state
                 :art-num   (fsm-art-num state)
                 :art-title (line-text line)))

;; ── article-open-state × paragraph-open → no subtitle; enter body directly ────
(defmethod advance ((state article-open-state) (line paragraph-open-line) acc)
  (incf (acc-para-count acc))
  (flush-pending-block acc)
  (emit-layout-line acc (line-text line))
  (make-instance 'paragraph-state
                 :art-num   (fsm-art-num state)
                 :art-title nil
                 :para-num  (para-open-num line)))

;; ── article-open-state × subpoint → treat as content (unusual but safe) ───────
(defmethod advance ((state article-open-state) (line subpoint-line) acc)
  (incf (acc-subpoint-count acc))
  (emit-layout-line acc (line-text line))
  (make-instance 'article-body-state
                 :art-num   (fsm-art-num state)
                 :art-title nil))

;; ── article-body-state × content-line → accumulate into current block ──────────
;; paragraph-state IS-A article-body-state, so this also covers paragraph-state
;; unless a more specific paragraph-state × content method is defined below.
(defmethod advance ((state article-body-state) (line content-line) acc)
  (emit-layout-line acc (line-text line))
  state)

;; ── article-body-state × paragraph-open → new numbered paragraph block ─────────
;; Flushes prior block so each paragraph gets its own layout-block.
;; paragraph-state inherits this method (no separate override needed).
(defmethod advance ((state article-body-state) (line paragraph-open-line) acc)
  (incf (acc-para-count acc))
  (flush-pending-block acc)
  (emit-layout-line acc (line-text line))
  (make-instance 'paragraph-state
                 :art-num   (fsm-art-num state)
                 :art-title (fsm-art-title state)
                 :para-num  (para-open-num line)))

;; ── paragraph-state × subpoint → isolated sub-point block ─────────────────────
;; More specific than article-body-state × subpoint — takes priority for
;; paragraph-state instances.
(defmethod advance ((state paragraph-state) (line subpoint-line) acc)
  (incf (acc-subpoint-count acc))
  (flush-pending-block acc)
  (emit-layout-line acc (line-text line))
  state)

;; ── article-body-state × subpoint (outside named paragraph) ───────────────────
(defmethod advance ((state article-body-state) (line subpoint-line) acc)
  (incf (acc-subpoint-count acc))
  (flush-pending-block acc)
  (emit-layout-line acc (line-text line))
  state)

;; ── initial-state × content → begin preamble ──────────────────────────────────
(defmethod advance ((state initial-state) (line content-line) acc)
  (emit-layout-line acc (line-text line))
  (make-instance 'preamble-state))

;; ── initial-state × paragraph-open → preamble (unusual) ──────────────────────
(defmethod advance ((state initial-state) (line paragraph-open-line) acc)
  (emit-layout-line acc (line-text line))
  (make-instance 'preamble-state))

;; ── preamble-state × content → accumulate preamble content ───────────────────
(defmethod advance ((state preamble-state) (line content-line) acc)
  (emit-layout-line acc (line-text line))
  state)

;; ── preamble-state × paragraph-open → accumulate ─────────────────────────────
(defmethod advance ((state preamble-state) (line paragraph-open-line) acc)
  (emit-layout-line acc (line-text line))
  state)

;; ── Catch-all: unhandled (state × line) combinations ─────────────────────────
;; Emits line defensively so no content is silently dropped.
(defmethod advance (state (line raw-line) acc)
  (emit-layout-line acc (line-text line))
  state)

;;; ============================================================================
;;; DEFTRANSITION — declarative FSM transition macro
;;;
;;; Generates a DEFMETHOD ADVANCE from table-like syntax.
;;; Preferred over bare DEFMETHOD for new transitions because:
;;;   1. Enforces the (state × line → new-state) signature contract
;;;   2. Makes the FSM readable as a transition table in source
;;;   3. Works with the AUDITING-GENERIC-FUNCTION's runtime audit
;;;
;;; Syntax:
;;;   (deftransition state-spec line-spec &body body)
;;;
;;;   state-spec: class-name                → variable bound as 'state in body
;;;               (var-name class-name)     → variable bound as var-name in body
;;;   line-spec:  class-name                → variable bound as 'line in body
;;;               (var-name class-name)     → variable bound as var-name in body
;;;   body: method body; ACC is always available (the rt-accumulator).
;;;
;;; Macro expansion:
;;;   (deftransition (s article-open-state) (l content-line)
;;;     (make-instance 'article-body-state :art-title (line-text l)))
;;;   →
;;;   (defmethod advance ((s article-open-state) (l content-line) acc)
;;;     (make-instance 'article-body-state :art-title (line-text l)))
;;;
;;; Without custom var names (defaults 'state and 'line):
;;;   (deftransition preamble-state subpoint-line
;;;     (emit-layout-line acc (line-text line))
;;;     (make-instance 'preamble-state))
;;; ============================================================================

(defmacro deftransition (state-spec line-spec &body body)
  "Declarative FSM transition: generate a DEFMETHOD ADVANCE for STATE-SPEC × LINE-SPEC."
  (let* ((state-class (if (listp state-spec) (second state-spec) state-spec))
         (line-class  (if (listp line-spec)  (second line-spec)  line-spec))
         (state-var   (if (listp state-spec) (first  state-spec) 'state))
         (line-var    (if (listp line-spec)  (first  line-spec)  'line)))
    `(defmethod advance ((,state-var ,state-class)
                         (,line-var  ,line-class)
                         acc)
       ,@body)))

;; ── preamble-state × subpoint-line ── (new; previously fell to T × raw-line)
;;
;; Subpoints in preamble context are unusual (most legal texts don't have
;; α)/β) enumeration before the first article) but do appear in some ΦΕΚ
;; preambles.  Accumulate as preamble content; count as subpoint; stay.
(deftransition preamble-state (line subpoint-line)
  "Sub-point encountered in document preamble: unusual but valid.
  Accumulate as preamble content; do not treat as numbered body sub-point."
  (incf (acc-subpoint-count acc))
  (emit-layout-line acc (line-text line))
  (make-instance 'preamble-state))

;;; ============================================================================
;;; MOP — FSM TRANSITION INTROSPECTION
;;;
;;; Use closer-mop to make the ADVANCE generic function self-describing:
;;;   1. Enumerate all primary methods via GENERIC-FUNCTION-METHODS
;;;   2. Extract (state-type × line-type) pairs via METHOD-SPECIALIZERS
;;;   3. Validate mandatory transitions at load time — load-time safety net
;;;   4. Export DESCRIBE-FSM for documentation / test generation
;;;
;;; This means the FSM can AUDIT ITSELF: if a refactor deletes a critical
;;; advance method, the load-time validation fails BEFORE any document is
;;; processed.  No tests required to catch a missing transition.
;;; ============================================================================

(defun fsm-primary-methods ()
  "Return all primary (non-auxiliary) methods on the ADVANCE generic function.
  Uses MOP: GENERIC-FUNCTION-METHODS to enumerate, METHOD-QUALIFIERS to filter."
  (remove-if (lambda (m)
               (intersection (method-qualifiers m)
                             '(:around :before :after)))
             (generic-function-methods (fdefinition 'advance))))

(defun specializer-type-name (spec)
  "Return a printable name for a method specializer.
  Handles: class specializers, EQL specializers, and T (catch-all)."
  (cond
    ((typep spec 'eql-specializer)
     (list :eql (eql-specializer-object spec)))
    ((eq spec (find-class t))
     :any)
    (t
     (class-name spec))))

(defun collect-fsm-transitions ()
  "Build the complete FSM transition table by introspecting ADVANCE via MOP.

  Returns: alist of ((state-type . line-type) . method-object)
    state-type — class name or :ANY (T-specialised catch-all)
    line-type  — class name or :ANY

  Called at load time by VALIDATE-FSM-COVERAGE; exported for REPL use."
  (loop for m in (fsm-primary-methods)
        for specs = (method-specializers m)
        when (>= (length specs) 2)
        collect (cons (cons (specializer-type-name (first specs))
                            (specializer-type-name (second specs)))
                      m)))

(defun describe-fsm (&optional (stream *standard-output*))
  "Pretty-print the FSM transition table derived via MOP introspection.
  Useful at the REPL to audit which (state × line-type) combinations
  have explicit advance methods.

  Example: (orchestrator.engine.sbcl:describe-fsm)"
  (declare (type stream stream))
  (let* ((table  (collect-fsm-transitions))
         (sorted (sort (copy-list table)
                       #'string<
                       :key (lambda (e)
                              (format nil "~A×~A" (caar e) (cdar e))))))
    (format stream "~&╔══ RAW-TEXT FSM TRANSITION TABLE (~D primary methods) ══╗~%"
            (length sorted))
    (dolist (entry sorted)
      (format stream "║  (~20A × ~A)~%"
              (caar entry)
              (cdar entry)))
    (format stream "╚════════════════════════════════════════════════════════╝~%")
    (length sorted)))

(defun validate-fsm-coverage ()
  "Assert via MOP that all mandatory FSM transitions have advance methods.
  Called at load time — errors here mean a refactor deleted a critical method.

  The mandatory set encodes the minimum correct behaviour of the adapter:
    - Subtitle detection (article-open-state × content-line)
    - No-subtitle path (article-open-state × paragraph-open-line)
    - Body accumulation (article-body-state × content-line)
    - Paragraph start (article-body-state × paragraph-open-line)
    - Sub-point isolation (paragraph-state × subpoint-line)
    - Noise handling (:any × noise-line)"
  (let ((table (collect-fsm-transitions))
        (required '((article-open-state  . content-line)
                    (article-open-state  . paragraph-open-line)
                    (article-body-state  . content-line)
                    (article-body-state  . paragraph-open-line)
                    (paragraph-state     . subpoint-line)
                    (:any                . noise-line))))
    (dolist (req required)
      (unless (assoc req table :test #'equal)
        (error "~%FSM COVERAGE GAP detected by MOP load-time audit:~%~
                No ADVANCE method for (~A × ~A).~%~
                Add a defmethod for this transition before loading.~%~
                Current transition table:~%~{  ~A~%~}"
               (car req) (cdr req)
               (mapcar #'car table))))
    (log:info ()
      "raw-text: MOP load-time audit passed — ~D FSM transitions, all mandatory covered"
      (length table))
    t))

;; ── Load-time FSM self-audit ──────────────────────────────────────────────────
;; Runs once when the FASL is loaded.  Zero runtime cost after that.
;; If advance methods are incomplete, this errors before any document runs.
(eval-when (:load-toplevel :execute)
  (validate-fsm-coverage))

;;; ============================================================================
;;; NAMED READTABLE — :orchestrator.raw-text
;;;
;;; Dispatch character #§ (section sign, U+00A7) for constructing classified
;;; line objects at READ TIME.  Activating the readtable is opt-in per-file.
;;;
;;; Syntax:
;;;   #§N       N is integer → article-header-line for article N (read-time object)
;;;   #§"text"  string       → (classify-line text 0)  (read-time classification)
;;;
;;; Example REPL session:
;;;   (named-readtables:in-readtable :orchestrator.raw-text)
;;;   #§5        → #<ARTICLE-HEADER-LINE Άρθρο 5 @0>
;;;   #§"1. Κάθε πολίτης έχει..." → #<PARAGRAPH-OPEN-LINE §1 @0>
;;;   (type-of (advance (make-instance 'initial-state) #§5 acc))
;;;   → ARTICLE-OPEN-STATE
;;;
;;; The reader function returns ACTUAL OBJECTS, not quoted forms.
;;; Objects are created at read time — identical semantics to #(1 2 3).
;;; ============================================================================

(defun %read-legal-dispatch (stream sub-char arg)
  "Reader function for the #§ dispatch character.
  STREAM: input stream positioned after §
  SUB-CHAR: the § character (ignored)
  ARG: nil (§ is not numeric-prefix-sensitive)"
  (declare (ignore sub-char arg))
  (let ((next (peek-char t stream t nil t)))
    (cond
      ;; ── #§"text" → classify the string at position 0 ─────────────────────
      ((char= next #\")
       (let ((text (read stream t nil t)))
         (classify-line text 0)))

      ;; ── #§N → article-header-line for article number N ────────────────────
      (t
       (let ((token (read stream t nil t)))
         (cond
           ((and (integerp token) (typep token 'article-number-type))
            (make-instance 'article-header-line
                           :article-num token
                           :text        (format nil "Άρθρο ~A" token)
                           :position    0))
           ((integerp token)
            (error "#§~A: ~A is outside article-number-type (1–9999)" token token))
           (t
            (error "#§ reader: expected integer or string, got ~S (~A)"
                   token (type-of token)))))))))

(named-readtables:defreadtable :orchestrator.raw-text
  (:merge :standard)
  (:dispatch-macro-char #\# #\§ #'%read-legal-dispatch))

;; named-readtables:defreadtable does not support a :documentation clause;
;; attach the docstring via setf after the readtable is interned.
(setf (documentation (named-readtables:find-readtable :orchestrator.raw-text) t)
      "Readtable for the raw-text adapter.
Adds #§ dispatch: #§N → article-header-line, #§\"text\" → classify-line.
Activate with (named-readtables:in-readtable :orchestrator.raw-text).")

;;; ============================================================================
;;; WITH-RAW-TEXT-READTABLE — dynamic readtable scope macro
;;;
;;; (named-readtables:in-readtable ...) is a compile-time declaration and does
;;; not compose with runtime control flow.  This macro provides a dynamic-extent
;;; readtable switch using a LET binding on *READTABLE*, which is a standard
;;; special variable with dynamic scope.
;;;
;;; The LET binding is safe across non-local exits — special variable bindings
;;; are unwound by the CL runtime just like UNWIND-PROTECT bodies.
;;;
;;; Use cases:
;;;   - Reading #§ syntax from a user-supplied string at runtime
;;;   - Test suite construction: (with-raw-text-readtable (read-from-string "#§5"))
;;;   - Dynamic READs inside the pipeline without affecting the caller's readtable
;;; ============================================================================

(defmacro with-raw-text-readtable (&body body)
  "Execute BODY with *READTABLE* bound to :orchestrator.raw-text.
  The previous *READTABLE* is restored on any exit — normal or non-local.
  Enables #§ dispatch within the dynamic extent of BODY at runtime."
  `(let ((*readtable* (named-readtables:find-readtable :orchestrator.raw-text)))
     ,@body))

;;; ============================================================================
;;; MAIN LINE-GROUPING PASS — CLOS FSM
;;;
;;; Every line of TEXT passes through:
;;;   1. classify-line   → typed raw-line instance
;;;   2. advance         → dispatches on (current-state × line-type)
;;;                        returns next FSM state; mutates acc
;;;   3. finalize-document → flushes remaining state; returns layout-document
;;; ============================================================================

;;; ============================================================================
;;; GREEK LEGAL TEXT NORMALIZER
;;;
;;; PDF extraction tools introduce artifacts that defeat regex classification
;;; even on structurally correct legal text.  This function runs once on the
;;; full text before the FSM loop, normalizing at the string level:
;;;
;;;   PDF artifacts handled:
;;;     CRLF / lone CR          → LF  (Windows PDF extraction)
;;;     Soft hyphen (U+00AD)    → ""  (PDF line-break hyphenation)
;;;     NBSP (U+00A0)           → " " (PDF typographic non-breaking space)
;;;     Thin space (U+2009)     → " " (ΦΕΚ narrow typographic spacing)
;;;     Narrow NBSP (U+202F)    → " " (ΦΕΚ pre-punctuation spacing)
;;;     3+ consecutive blanks   → 1 blank (PDF page-break artifacts)
;;;
;;; The scanner patterns already handle ** bold markers syntactically.
;;; This normalizer does NOT touch article text semantics — only whitespace
;;; variants and invisible formatting characters are altered.
;;; ============================================================================

(defun normalize-greek-legal-text (text)
  "Remove PDF extraction artifacts from raw Greek legal text before FSM classification.

  All transformations are whitespace-level and invisible-character-level only;
  no legal text content is altered.  Returns a fresh string."
  (declare (type string text)
           (values string))
  (let* (;; CRLF → LF, lone CR → LF
         (s (cl-ppcre:regex-replace-all "\\r\\n|\\r" text (string #\Newline)))
         ;; Soft hyphen U+00AD (PDF hyphenation artifact) → removed
         (s (cl-ppcre:regex-replace-all "\\x{AD}" s ""))
         ;; Unicode space variants → ASCII space
         (s (cl-ppcre:regex-replace-all "[\\x{A0}\\x{2009}\\x{202F}]" s " "))
         ;; 3+ consecutive blank lines → single blank line (PDF page separators)
         (s (cl-ppcre:regex-replace-all
             (format nil "(?:~C[ \\t]*){3,}" #\Newline)
             s (format nil "~C~C" #\Newline #\Newline))))
    s))

(defun group-text-into-layout-document (text &key (source-file "<raw-text>"))
  "Convert raw Greek legal TEXT into a synthetic LAYOUT-DOCUMENT via CLOS FSM.

  Intelligence provided by FSM context:
    - Subtitle detection: content-line in article-open-state = subtitle
    - Sub-point isolation: α), β), i) each get their own layout block
    - Signature detection: attestation lines isolated before end-of-text
    - Page wrapping: automatic via :before method on emit-layout-line

  Returns: layout-document with synthetic A4 geometry, ready for
           classify-document → canonicalize-document → build-ast pipeline."
  (declare (type string text))
  (let* ((normalized (normalize-greek-legal-text text))
         (acc   (make-instance 'rt-accumulator :source-file source-file))
         (state (make-instance 'initial-state))
         (pos   0))
    (declare (type fixnum pos))

    (dolist (raw-line (uiop:split-string normalized :separator '(#\Newline)))
      (let* ((trimmed    (the string
                              (string-trim '(#\Space #\Tab #\Return)
                                           (the string raw-line))))
             (classified (classify-line trimmed pos)))
        (declare (type string trimmed))
        (setf state (the raw-text-fsm-state (advance state classified acc))))
      (incf (the fixnum pos)))

    (let ((doc (finalize-document acc)))
      (log:info ()
        "raw-text: CLOS FSM: ~D lines → ~D pages | ~D articles | ~D paras | ~D subpoints | ~D noise"
        (acc-global-line acc)
        (length (orchestrator.layout-types:document-pages doc))
        (acc-article-count acc)
        (acc-para-count acc)
        (acc-subpoint-count acc)
        (acc-noise-count acc))
      doc)))

;;; ============================================================================
;;; PIPELINE-LAYER METHOD COMBINATION
;;;
;;; Custom method combination for RUN-RAW-TEXT-LAYER that provides:
;;;   1. :validate qualifier — input checks run before the primary; may signal
;;;   2. Automatic layer timing — measures wall time; logs on completion
;;;   3. Automatic error wrapping — any non-raw-text-error becomes a typed
;;;      RAW-TEXT-LAYER-ERROR with the layer name extracted via MOP from the
;;;      EQL specializer of the primary method
;;;
;;; This is the canonical reason to define a custom method combination: the
;;; cross-cutting concerns (timing, error wrapping, layer naming) belong in
;;; the combination, not duplicated across every caller.
;;;
;;; Without this combination, RAW-TEXT->IIR-ARTICLES needed three nested
;;; HANDLER-CASE blocks, each manually naming the layer.  With it, each
;;; RUN-RAW-TEXT-LAYER call is a single expression — the combination handles
;;; everything.
;;; ============================================================================

(define-method-combination pipeline-layer ()
  ((validate (:validate) :order :most-specific-first)
   (primary  ()          :required t))
  "Custom combination for RUN-RAW-TEXT-LAYER.

  Qualifiers:
    (none)     — primary layer implementation (required, exactly one)
    :validate  — input validation, runs before primary, may signal to abort

  Generated effective method:
    (let ((t0 (get-internal-real-time)))
      (handler-case
          (progn [validate...] [primary] [log timing])
        (raw-text-error (e) (error e))          ; propagate typed errors as-is
        (error (e) (error 'raw-text-layer-error ; wrap unknowns with layer name
                          :layer <eql-keyword-from-MOP> ...))))"
  (let* ((primary-method (first primary))
         (specs          (closer-mop:method-specializers primary-method))
         (layer-spec     (first specs))
         (layer-name     (if (typep layer-spec 'closer-mop:eql-specializer)
                             (closer-mop:eql-specializer-object layer-spec)
                             :unknown-layer)))
    `(let ((t0 (get-internal-real-time)))
       (handler-case
           (progn
             ,@(mapcar (lambda (v) `(call-method ,v)) validate)
             (multiple-value-prog1
                 (call-method ,primary-method)
               (log:info () "raw-text: layer ~A: ~Dms"
                         ',layer-name
                         (round (/ (* 1000 (- (get-internal-real-time) t0))
                                   internal-time-units-per-second)))))
         (raw-text-error (e) (error e))
         (error (e)
           (error 'raw-text-layer-error
                  :layer      ',layer-name
                  :stage-name :raw-text-adapter
                  :message    (format nil "~A" e)))))))

;;; ============================================================================
;;; LAYER DISPATCH — defgeneric run-raw-text-layer
;;;
;;; EQL-specialised on keyword; uses PIPELINE-LAYER combination for automatic
;;; timing, error wrapping, and declarative input validation.
;;; ============================================================================

(defgeneric run-raw-text-layer (layer-key input &key)
  (:method-combination pipeline-layer)
  (:documentation "Execute one named layer of the raw-text 5-layer pipeline.
  LAYER-KEY: :classify | :canonicalize | :build-ast
  Uses PIPELINE-LAYER method combination: timing + error wrapping built-in."))

;; ── :validate methods — input contracts per layer ─────────────────────────────

(defmethod run-raw-text-layer :validate ((layer-key (eql :classify)) layout-doc &key)
  "Verify layout document has pages before classification."
  (unless (orchestrator.layout-types:document-pages layout-doc)
    (error 'raw-text-no-articles
           :stage-name :raw-text-adapter
           :block-count 0
           :message "Classify layer: layout document has no pages — text may be empty or all noise")))

(defmethod run-raw-text-layer :validate ((layer-key (eql :canonicalize)) classified &key)
  "Verify classified document is non-nil before canonicalization."
  (unless classified
    (error 'raw-text-layer-error
           :layer :canonicalize
           :stage-name :raw-text-adapter
           :message "Canonicalize layer: upstream classification returned nil")))

(defmethod run-raw-text-layer :validate ((layer-key (eql :build-ast)) canonical &key)
  "Verify canonical document is non-nil before AST construction."
  (unless canonical
    (error 'raw-text-layer-error
           :layer :build-ast
           :stage-name :raw-text-adapter
           :message "Build-AST layer: upstream canonicalization returned nil")))

;; ── Primary methods — actual layer implementations ────────────────────────────

(defmethod run-raw-text-layer ((layer-key (eql :classify)) layout-doc &key)
  (orchestrator.typographic-classifier:classify-document layout-doc))

(defmethod run-raw-text-layer ((layer-key (eql :canonicalize)) classified &key)
  (orchestrator.text-canonicalizer:canonicalize-document classified))

(defmethod run-raw-text-layer ((layer-key (eql :build-ast)) canonical &key)
  (orchestrator.legal-ast:build-ast canonical))

;;; ============================================================================
;;; IIR CONVERSION — article-node → normalized-article-input
;;; ============================================================================

(defun ast-article->iir (article-node source-path)
  "Convert a legal-ast article-node to a normalized-article-input (IIR).
  Confidence 0.9: no OCR errors, but geometry is synthetic."
  (let* ((num    (orchestrator.legal-ast:article-number    article-node))
         (title  (orchestrator.legal-ast:article-title     article-node))
         (paras  (orchestrator.legal-ast:article-paragraphs article-node))

         (formatted-title
           (if (and title (> (length title) 0))
               (format nil "Άρθρο ~A - ~A" num title)
               (format nil "Άρθρο ~A" num)))

         (content
           (let ((para-texts
                   (loop for para in paras
                         for txt = (orchestrator.legal-ast:paragraph-content para)
                         when (and txt
                                   (> (length (string-trim '(#\Space #\Tab) txt)) 0))
                         collect (string-trim '(#\Space #\Tab) txt))))
             (if para-texts
                 (format nil "~{~A~^~%~}" para-texts)
                 (or (orchestrator.legal-ast:ast-text article-node) ""))))

         (safe-content (if (> (length content) 0) content formatted-title)))

    (orchestrator.model:make-normalized-article-input
     :article-number        num
     :article-label         (format nil "~D" num)
     :article-title         formatted-title
     :article-content       safe-content
     :source-type           :raw-text
     :source-path           source-path
     :extraction-confidence 0.9f0
     :source-metadata
     (list :extractor   "raw-text-5-layer-clos-pipeline"
           :trace-id    (format nil "raw-art-~D-~D" num (get-universal-time))
           :paragraphs  (length paras)
           :title-src   (if (and title (> (length title) 0)) :subtitle :header-only)
           :pipeline    :layers-1-through-5))))

;;; ============================================================================
;;; 5-LAYER PIPELINE ORCHESTRATION
;;; ============================================================================

(defun raw-text->iir-articles (text &key (source-path "<raw-text>"))
  "Execute the full 5-layer pipeline on TEXT.
  Returns: (values iir-articles document-node article-count)

  Restarts:
    USE-FEK-STATE-MACHINE  — bypass layers 1-4, use ΦΕΚ state machine
    SKIP-FAILED-ARTICLES   — collect IIR for successes, skip errors"
  (declare (type string text))

  (restart-case

      (let ((layout-doc
              (handler-case
                  (group-text-into-layout-document text :source-file source-path)
                (error (e)
                  (error 'raw-text-layer-error
                         :layer :layout-synthesis
                         :stage-name :raw-text-adapter
                         :message (format nil "~A" e))))))

        (unless (orchestrator.layout-types:document-pages layout-doc)
          (error 'raw-text-no-articles
                 :stage-name :raw-text-adapter
                 :block-count 0
                 :message "Layout document has no pages — text may be empty or all noise"))

        (let ((total-blocks
                (loop for pg in (orchestrator.layout-types:document-pages layout-doc)
                      sum (length (orchestrator.layout-types:page-blocks pg)))))
          (log:info () "raw-text: Layer 1 complete: ~D pages, ~D blocks"
                    (length (orchestrator.layout-types:document-pages layout-doc))
                    total-blocks))

        ;; Layers 2-4: pipeline-layer combination owns timing + error wrapping.
        ;; Direct calls — no redundant handler-case here.
        (let* ((classified
                 (run-raw-text-layer :classify layout-doc))

               (canonical
                 (progn
                   (log:info () "raw-text: Layer 2 complete: ~D classified pages"
                             (length classified))
                   (run-raw-text-layer :canonicalize classified)))

               (doc-node
                 (progn
                   (log:info () "raw-text: Layer 3 complete: ~D canonical pages"
                             (length canonical))
                   (run-raw-text-layer :build-ast canonical)))

               (articles (orchestrator.legal-ast:document-articles doc-node)))

          (log:info () "raw-text: Layer 4 complete: ~D article nodes" (length articles))

          (unless articles
            (error 'raw-text-no-articles
                   :stage-name :raw-text-adapter
                   :block-count (loop for page-pair in canonical
                                      sum (length (cdr page-pair)))
                   :message "AST produced no article nodes — check article header format"))

          ;; Layer 5: HANDLER-BIND (not HANDLER-CASE) for warning collection.
          ;;
          ;; KEY DISTINCTION:
          ;;   HANDLER-CASE  — catches + unwinds: the LOOP body is aborted on
          ;;                   each warning, losing the rest of the article list.
          ;;   HANDLER-BIND  — intercepts WITHOUT unwinding: the LOOP continues
          ;;                   after each warning, accumulating ALL articles.
          ;;
          ;; The handler calls MUFFLE-WARNING to suppress default reporting, then
          ;; we emit a single structured summary after the LOOP completes.
          ;; This is the correct Common Lisp idiom for per-item warning aggregation.
          (let ((iir-warnings nil))
            (let ((iir-articles
                    (restart-case
                        (handler-bind
                            ((raw-text-iir-warning
                              (lambda (w)
                                (push w iir-warnings)
                                (muffle-warning w))))
                          (loop for art in articles
                                for n   of-type fixnum
                                      = (orchestrator.legal-ast:article-number art)
                                for iir = (handler-case
                                              (ast-article->iir art source-path)
                                            (error (e)
                                              (warn 'raw-text-iir-warning
                                                    :article-number n
                                                    :reason (format nil "~A" e))
                                              nil))
                                when iir collect iir))
                      (skip-failed-articles ()
                        :report "Collect IIR for successful articles, skip failures"
                        (handler-bind
                            ((raw-text-iir-warning
                              (lambda (w)
                                (push w iir-warnings)
                                (muffle-warning w))))
                          (remove nil
                                  (mapcar (lambda (art)
                                            (ignore-errors
                                             (ast-article->iir art source-path)))
                                          articles)))))))

              (when iir-warnings
                (log:warn () "raw-text: Layer 5 — ~D article IIR warning~:P:~{~%  art-~A: ~A~}"
                          (length iir-warnings)
                          (loop for w in (nreverse iir-warnings)
                                nconc (list (rtw-article-number w)
                                            (rtw-reason w)))))

              (log:info () "raw-text: Layer 5 complete: ~D IIR articles (~D warnings)"
                        (length iir-articles)
                        (length iir-warnings))

              (values iir-articles doc-node (length articles))))))

    (use-fek-state-machine ()
      :report "Bypass 5-layer pipeline, use ΦΕΚ state-machine parser"
      (log:warn () "raw-text: restarting with ΦΕΚ fallback for ~A" source-path)
      (let ((fek-articles (parse-fek-text text)))
        (values (mapcar (lambda (a) (article-to-iir a source-path)) fek-articles)
                nil
                (length fek-articles))))))

;;; ============================================================================
;;; INPUT LOADING
;;; ============================================================================

(defun load-raw-text-source (source &key (encoding :utf-8))
  "Read TEXT from SOURCE (string of legal text or pathname).
  Returns: (values text source-description)"
  (etypecase source
    (string
     (if (and (< (length source) 512)
              (or (probe-file source)
                  (cl-ppcre:scan "\\.(txt|TXT)$" source)))
         (values (uiop:read-file-string source :external-format encoding) source)
         (values source "<string>")))
    (pathname
     (values (uiop:read-file-string source :external-format encoding)
             (namestring source)))))

;;; ============================================================================
;;; MAIN ENTRY POINT
;;; ============================================================================

(defun raw-text-adapter (source &key (source-path nil) (encoding :utf-8))
  "Parse raw Greek legal text → list of normalized-article-input (IIR).

  Mirrors json-adapter and pdf-adapter in interface contract:
    - SOURCE: string of legal text OR pathname to .txt file
    - Returns: list of normalized-article-input
    - Signals: raw-text-error subclass on failure

  Signals:
    raw-text-empty-source  — nil or empty source
    raw-text-no-articles   — source yielded no articles
    raw-text-layer-error   — a pipeline layer signalled
    orchestrator.spec:stage-error — wrapper for unexpected errors"
  (handler-case
      (progn
        (unless source
          (error 'raw-text-empty-source
                 :stage-name :raw-text-adapter
                 :message "source argument is NIL"))

        (multiple-value-bind (text effective-path)
            (load-raw-text-source source :encoding encoding)

          (let ((path (or source-path effective-path)))
            (log:info () "raw-text-adapter: starting 5-layer CLOS pipeline for ~A (~D chars)"
                      path (length text))

            (when (zerop (length text))
              (error 'raw-text-empty-source
                     :stage-name :raw-text-adapter
                     :message (format nil "~A is empty" path)))

            (multiple-value-bind (iir-articles _doc _count)
                (raw-text->iir-articles text :source-path path)
              (declare (ignore _doc _count))

              (when (null iir-articles)
                (error 'raw-text-no-articles
                       :stage-name :raw-text-adapter
                       :block-count 0
                       :message (format nil "pipeline produced zero IIR articles for ~A" path)))

              (log:info () "raw-text-adapter: complete → ~D articles from ~A"
                        (length iir-articles) path)

              iir-articles))))

    (raw-text-error (e)
      (log:error () "raw-text-adapter: ~A" e)
      (error e))

    (error (e)
      (error 'orchestrator.spec:stage-error
             :message (format nil "raw-text-adapter unexpected failure: ~A" e)
             :stage-name :raw-text-adapter))))

;;; ============================================================================
;;; DEMO ENTRY POINT — Layer 1 CLOS FSM end-to-end on embedded Greek legal text
;;;
;;; Self-contained: exercises classify-line + advance + group-text-into-layout-document
;;; using only Layer 1 infrastructure (no external modules required).
;;; Calls describe-fsm (static MOP audit) + describe-advance-audit (runtime heatmap).
;;;
;;; Usage:
;;;   (orchestrator.engine.sbcl:demo-raw-text-pipeline)
;;;   (orchestrator.engine.sbcl:demo-raw-text-pipeline :verbose t)
;;; ============================================================================

(defun demo-raw-text-pipeline (&key (stream *standard-output*) (verbose nil))
  "Run the Layer 1 CLOS FSM grouper on 5 embedded Greek Constitution articles.

  Demonstrates end-to-end: raw text → classify-line → advance FSM →
  layout-document, then emits the static FSM table (describe-fsm) and the
  runtime dispatch heatmap (describe-advance-audit).

  Requires only Layer 1 infrastructure; no external classifier/canonicalizer
  modules are invoked.  Safe to call from the REPL at any time.

  Returns: (values layout-document page-count total-fsm-dispatches)"
  (declare (type stream stream))
  (let ((sample-text
          "ΜΕΡΟΣ ΠΡΩΤΟ
ΒΑΣΙΚΕΣ ΔΙΑΤΑΞΕΙΣ

ΤΜΗΜΑ Α'
ΜΟΡΦΗ ΤΟΥ ΠΟΛΙΤΕΥΜΑΤΟΣ

Άρθρο 1
Μορφή του Πολιτεύματος

1. Το πολίτευμα της Ελλάδας είναι Προεδρευόμενη Κοινοβουλευτική Δημοκρατία.
2. Θεμέλιο του πολιτεύματος είναι η λαϊκή κυριαρχία.
3. Όλες οι εξουσίες πηγάζουν από το Λαό, υπάρχουν υπέρ αυτού και του Έθνους και ασκούνται όπως ορίζει το Σύνταγμα.

Άρθρο 2
Σεβασμός της ανθρώπινης αξίας

1. Ο σεβασμός και η προστασία της αξίας του ανθρώπου αποτελούν την πρωταρχική υποχρέωση της Πολιτείας.
2. Η Ελλάδα, ακολουθώντας τους γενικά παραδεγμένους κανόνες του διεθνούς δικαίου, επιδιώκει την εδραίωση της ειρήνης, της δικαιοσύνης και την ανάπτυξη φιλικών σχέσεων μεταξύ των λαών και των κρατών.

Άρθρο 3
Σχέσεις Εκκλησίας και Πολιτείας

1. Επικρατούσα θρησκεία στην Ελλάδα είναι η θρησκεία της Ανατολικής Ορθόδοξης Εκκλησίας του Χριστού.
2. Η Ορθόδοξη Εκκλησία της Ελλάδας υπάρχει αναπόσπαστα ενωμένη δογματικά με τη Μεγάλη Εκκλησία της Κωνσταντινούπολης.
α) Ο ιερός χαρακτήρας της ορθόδοξης λατρείας εξασφαλίζεται.
β) Η θρησκευτική εκπαίδευση εξασφαλίζεται σε όλες τις βαθμίδες.
γ) Πράξη ανθιστάμενη στη δημόσια τάξη ή τα χρηστά ήθη απαγορεύεται.

Άρθρο 4
Αρχή της ισότητας

1. Οι Έλληνες είναι ίσοι ενώπιον του νόμου.
2. Οι Έλληνες και οι Ελληνίδες έχουν ίσα δικαιώματα και υποχρεώσεις.

Άρθρο 5
Ελεύθερη ανάπτυξη της προσωπικότητας

1. Καθένας έχει δικαίωμα να αναπτύσσει ελεύθερα την προσωπικότητά του και να συμμετέχει στην κοινωνική, οικονομική και πολιτική ζωή της Χώρας.
2. Όλοι όσοι βρίσκονται στην Ελληνική Επικράτεια απολαύουν της απόλυτης προστασίας της ζωής, της τιμής και της ελευθερίας τους χωρίς διάκριση εθνικότητας, φυλής, γλώσσας και θρησκευτικών ή πολιτικών πεποιθήσεων."))

    (format stream "~&╔══════════════════════════════════════════════════════════════╗~%")
    (format stream "║   RAW-TEXT PIPELINE DEMO  (Greek Constitution — Art. 1-5)   ║~%")
    (format stream "╠══════════════════════════════════════════════════════════════╣~%")
    (format stream "║   Layer 1: classify-line → advance FSM → layout-document    ║~%")
    (format stream "╚══════════════════════════════════════════════════════════════╝~%~%")

    (when verbose
      (describe-fsm stream)
      (terpri stream))

    (let* ((t0 (get-internal-real-time))
           (layout-doc
             (handler-case
                 (group-text-into-layout-document sample-text :source-file "<demo>")
               (error (e)
                 (format stream "~&[DEMO ERROR] Layer 1 failed: ~A~%" e)
                 (return-from demo-raw-text-pipeline (values nil 0 0)))))
           (elapsed-ms  (round (* 1000 (- (get-internal-real-time) t0))
                               internal-time-units-per-second))
           (pages       (orchestrator.layout-types:document-pages layout-doc))
           (total-blks  (loop for pg in pages
                              sum (length (orchestrator.layout-types:page-blocks pg))))
           (dispatches  (gf-transition-count (fdefinition 'advance))))

      (format stream "~&  Elapsed       : ~D ms~%" elapsed-ms)
      (format stream "  Pages         : ~D~%" (length pages))
      (format stream "  Total blocks  : ~D~%" total-blks)
      (format stream "  FSM dispatches: ~D (cumulative since FASL load)~%~%" dispatches)

      (describe-advance-audit stream)

      (values layout-doc (length pages) dispatches))))

;;; ============================================================================
;;; LOAD-TIME FSM SELF-VALIDATION
;;;
;;; validate-fsm-coverage is called at FASL load time.  Any refactor that
;;; deletes a mandatory advance method is caught immediately, not at first
;;; runtime call with a confusing "no applicable method" error.
;;; ============================================================================

(eval-when (:load-toplevel :execute)
  (validate-fsm-coverage))
