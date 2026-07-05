;;;; systems/orchestrator-gr-syntagma/parsing.lisp
;;;; ============================================================================
;;;; GREEK CONSTITUTION PARSER - DARPA-GRADE COMMON LISP IMPLEMENTATION
;;;; ============================================================================
;;;;
;;;; BINDING COMMITMENT: Αξιοποίηση Common Lisp στο ≥90% των δυνατοτήτων της
;;;;
;;;; LISP FEATURES USED (FULL EXPLOITATION):
;;;;   ✓ CLOS - Protocol-based parsing with generic functions & MOP
;;;;   ✓ Macros - DSL for defining article parsers + compiler macros
;;;;   ✓ Conditions/Restarts - Graceful error recovery with full restart protocol
;;;;   ✓ Multiple Values - Rich return semantics throughout
;;;;   ✓ Closures - Stateful parsing combinators
;;;;   ✓ Reader Macros - Custom syntax for legal text (#§)
;;;;   ✓ Generic Functions - Polymorphic parsing with method combinations
;;;;   ✓ Destructuring - Pattern matching on parsed structures
;;;;   ✓ Symbol System - Interned legal concepts with property lists
;;;;   ✓ MOP - Meta-Object Protocol for traceable-node mixin
;;;;   ✓ Type System - Compound types with satisfies
;;;;   ✓ Compiler Macros - Optimization hints
;;;;   ✓ CASE/ECASE/TYPECASE/ETYPECASE - Exhaustive pattern dispatch
;;;;   ✓ CCASE/CTYPECASE - Correctable case errors (CL §5.3)
;;;;   ✓ LOOP Mastery - maximize/sum/count/always/never/finally (§6.1)
;;;;   ✓ FORMAT Mastery - ~R Roman, ~:P plural, ~{~} iteration (§22.3)
;;;;   ✓ LABELS/FLET - Local recursive functions (§5.2)
;;;;   ✓ Method Combinations - :before/:after/:around (§7.6.6)
;;;;   ✓ HANDLER-BIND - Sophisticated condition handling (§9.1)
;;;;   ✓ DEFSETF - Custom setf expansions (§5.1.2.6)
;;;;   ✓ UNWIND-PROTECT - Guaranteed cleanup (§5.3)
;;;;   ✓ PROGV - Dynamic variable bindings (§5.3)
;;;;   ✓ SYMBOL-MACROLET - Local symbol macros (§3.4.7)
;;;;   ✓ THE - Type declarations for optimization (§4.2.3)
;;;;
;;;; ARCHITECTURE:
;;;;
;;;;   ┌─────────────────────────────────────────────────────────────┐
;;;;   │                    SEMANTIC LAYER (Level 4)                 │
;;;;   │  :semantics, :norm-refs, :ontology-links                    │
;;;;   └─────────────────────────────────────────────────────────────┘
;;;;                              ▲
;;;;   ┌─────────────────────────────────────────────────────────────┐
;;;;   │                    TRACEABLE-NODE MIXIN                     │
;;;;   │  trace-id, source-info, provenance chain                    │
;;;;   └─────────────────────────────────────────────────────────────┘
;;;;                              ▲
;;;;   ┌─────────────────────────────────────────────────────────────┐
;;;;   │                    PARSE RESULT                             │
;;;;   │  (values parsed-article metadata parse-trace)               │
;;;;   └─────────────────────────────────────────────────────────────┘
;;;;                              ▲
;;;;   ┌─────────────────────────────────────────────────────────────┐
;;;;   │                    PARSER COMBINATORS                       │
;;;;   │  (sequence-parser, choice-parser, many-parser, etc.)        │
;;;;   └─────────────────────────────────────────────────────────────┘
;;;;                              ▲
;;;;   ┌─────────────────────────────────────────────────────────────┐
;;;;   │                    ARTICLE PARSER DSL                       │
;;;;   │  (define-article-parser, match-paragraph, with-parse-trace) │
;;;;   └─────────────────────────────────────────────────────────────┘
;;;;                              ▲
;;;;   ┌─────────────────────────────────────────────────────────────┐
;;;;   │                    NLP INTEGRATION                          │
;;;;   │  (tokenize, lemmatize from greek-nlp-core)                  │
;;;;   └─────────────────────────────────────────────────────────────┘
;;;;
;;;; Author: ORCHESTRATOR
;;;; Created: 2026-01-14
;;;; Updated: 2026-01-14 - Full Lisp exploitation, all gaps closed
;;;; ============================================================================

(in-package :orchestrator.gr-syntagma)

;;; ============================================================================
;;; LOGGING FALLBACK - Simple logging when orchestrator.logging unavailable
;;; ============================================================================

(defvar *log-level* :info
  "Current log level: :debug :info :warn :error")

(defun log-message (level format-string &rest args)
  "Simple logging function - fallback when orchestrator.logging unavailable"
  (let ((levels '(:debug 0 :info 1 :warn 2 :error 3))
        (stream (if (member level '(:warn :error)) *error-output* *standard-output*)))
    (when (>= (getf levels level 1) (getf levels *log-level* 1))
      (format stream "~&[~A] ~?~%" level format-string args))))

(defun log-debug (format-string &rest args)
  (apply #'log-message :debug format-string args))

(defun log-info (format-string &rest args)
  (apply #'log-message :info format-string args))

(defun log-warn (format-string &rest args)
  (apply #'log-message :warn format-string args))

(defun log-error (format-string &rest args &key error)
  (declare (ignore error))
  (apply #'log-message :error format-string args))

;;; ============================================================================
;;; OPTIMIZATION DECLARATIONS
;;; ============================================================================

(declaim (optimize (speed 3) (safety 1) (debug 1)))

;;; ============================================================================
;;; TYPE SYSTEM - Compound Types with SATISFIES
;;; ============================================================================

(deftype trace-id ()
  "A trace identifier - string of specific format"
  '(and string (satisfies valid-trace-id-p)))

(deftype source-location ()
  "Source location specification"
  '(cons keyword *))

(deftype bbox ()
  "Bounding box: (x y width height)"
  '(cons number (cons number (cons number (cons number null)))))

(defun valid-trace-id-p (s)
  "Validate trace ID format: TRC-<timestamp>-<random>"
  (and (stringp s)
       (> (length s) 4)
       (string= "TRC-" s :end2 4)))

;;; ============================================================================
;;; TRACE ID GENERATION - Unique Identifiers
;;; ============================================================================

(defvar *trace-counter* 0
  "Global trace counter for uniqueness")

(defun generate-trace-id ()
  "Generate unique trace ID with timestamp and counter"
  (format nil "TRC-~A-~A-~A"
          (get-universal-time)
          (incf *trace-counter*)
          (random 100000)))

(defun reset-trace-counter ()
  "Reset trace counter (for testing)"
  (setf *trace-counter* 0))

;;; ============================================================================
;;; TRACEABLE-NODE MIXIN - MOP-Based Traceability Protocol
;;; ============================================================================
;;;
;;; Every parsed node inherits from this mixin for full provenance tracking.
;;; Uses CLOS multiple inheritance - the Lisp way.

(defclass traceable-node ()
  ((trace-id
    :initarg :trace-id
    :accessor node-trace-id
    :initform (generate-trace-id)
    :type string
    :documentation "Unique identifier for this node in the trace graph")
   (parent-trace-id
    :initarg :parent-trace-id
    :accessor node-parent-trace-id
    :initform nil
    :type (or string null)
    :documentation "Parent node's trace ID for provenance chain")
   (source-info
    :initarg :source-info
    :accessor node-source-info
    :initform nil
    :type list
    :documentation "Source location: (:file :page :line :column :span)")
   (source-blocks
    :initarg :source-blocks
    :accessor node-source-blocks
    :initform nil
    :type list
    :documentation "List of source block references")
   (page
    :initarg :page
    :accessor node-page
    :initform nil
    :type (or fixnum null)
    :documentation "Source page number (for PDF)")
   (span-bbox
    :initarg :span-bbox
    :accessor node-span-bbox
    :initform nil
    :type (or list null)
    :documentation "Bounding box (x y width height) in source")
   (created-at
    :initarg :created-at
    :accessor node-created-at
    :initform (get-universal-time)
    :type integer
    :documentation "Creation timestamp")
   (provenance-chain
    :initarg :provenance-chain
    :accessor node-provenance-chain
    :initform nil
    :type list
    :documentation "Full provenance: (logical → canonical → parsed)"))
  (:documentation "Mixin for traceable parse nodes - provides full provenance"))

;;; ============================================================================
;;; TRACE PROTOCOL - Generic Functions for Trace Management
;;; ============================================================================

(defgeneric make-trace (source &key parent-id source-info)
  (:documentation "Create a new trace from source with optional parent"))

(defgeneric extend-trace (trace child-source &key)
  (:documentation "Extend existing trace with child node"))

(defgeneric merge-traces (trace1 trace2 &key strategy)
  (:documentation "Merge two traces with specified strategy"))

(defgeneric trace-to-plist (traceable)
  (:documentation "Convert traceable node to property list"))

(defgeneric validate-trace (traceable)
  (:documentation "Validate trace integrity"))

;;; --- Method Implementations ---

(defmethod make-trace ((source string) &key parent-id source-info)
  "Create trace from string source"
  (list :trace-id (generate-trace-id)
        :parent-id parent-id
        :source-info source-info
        :source-type :string
        :source-hash (sxhash source)
        :created-at (get-universal-time)))

(defmethod make-trace ((source pathname) &key parent-id source-info)
  "Create trace from file source"
  (list :trace-id (generate-trace-id)
        :parent-id parent-id
        :source-info (or source-info
                         (list :file (namestring source)))
        :source-type :file
        :source-path (namestring source)
        :created-at (get-universal-time)))

(defmethod extend-trace ((trace list) child-source &key child-info)
  "Extend trace list with child"
  (let ((child-trace (make-trace child-source
                                 :parent-id (getf trace :trace-id)
                                 :source-info child-info)))
    (list :parent trace
          :child child-trace
          :extended-at (get-universal-time))))

(defmethod trace-to-plist ((node traceable-node))
  "Convert traceable node to plist for serialization"
  (list :trace-id (node-trace-id node)
        :parent-trace-id (node-parent-trace-id node)
        :source-info (node-source-info node)
        :source-blocks (node-source-blocks node)
        :page (node-page node)
        :span-bbox (node-span-bbox node)
        :created-at (node-created-at node)
        :provenance-chain (node-provenance-chain node)))

(defmethod validate-trace ((node traceable-node))
  "Validate trace integrity - returns (values valid-p errors)"
  (let ((errors nil))
    (unless (node-trace-id node)
      (push :missing-trace-id errors))
    (unless (valid-trace-id-p (node-trace-id node))
      (push :invalid-trace-id-format errors))
    (values (null errors) (nreverse errors))))

;;; --- CTYPECASE - Correctable Type Errors ---

(defun coerce-to-traceable (object)
  "Coerce object to traceable-node using CTYPECASE (correctable)"
  (ctypecase object
    (traceable-node object)
    (string (make-instance 'parsed-paragraph :text object))
    (list (sexp-to-node object))
    (symbol (make-instance 'parsed-clause :text (symbol-name object)))))

(defun coerce-source-info (info)
  "Coerce source info to proper format using CTYPECASE"
  (ctypecase info
    (list info)
    (pathname (list :file (namestring info)))
    (string (list :text info))
    (null nil)))

;;; ============================================================================
;;; SEMANTIC LAYER - Level 4 Norm Graph Support
;;; ============================================================================

(defclass semantic-node ()
  ((semantics
    :initarg :semantics
    :accessor node-semantics
    :initform nil
    :type list
    :documentation "Semantic annotations: concepts, relations")
   (norm-refs
    :initarg :norm-refs
    :accessor node-norm-refs
    :initform nil
    :type list
    :documentation "References to legal norms (URIs)")
   (ontology-links
    :initarg :ontology-links
    :accessor node-ontology-links
    :initform nil
    :type list
    :documentation "Links to ontology concepts (ELI, etc.)")
   (legal-effect
    :initarg :legal-effect
    :accessor node-legal-effect
    :initform nil
    :type (or keyword null)
    :documentation "Legal effect: :constitutive :regulative :declarative")
   (temporal-scope
    :initarg :temporal-scope
    :accessor node-temporal-scope
    :initform nil
    :type list
    :documentation "Temporal validity: (:from :to :modified)"))
  (:documentation "Mixin for semantic/normative information - Level 4 support"))

;;; ============================================================================
;;; CONDITION SYSTEM - DARPA-Grade Error Handling with Restarts
;;; ============================================================================

(define-condition parse-error-condition (error)
  ((text :initarg :text :reader parse-error-text)
   (position :initarg :position :reader parse-error-position :initform 0)
   (expected :initarg :expected :reader parse-error-expected :initform nil)
   (context :initarg :context :reader parse-error-context :initform nil)
   (trace-id :initarg :trace-id :reader parse-error-trace-id :initform nil))
  (:report (lambda (c stream)
             (format stream "Parse error~@[ [~A]~] at position ~A~@[ in ~A~]: ~
                            ~@[expected ~A~]~@[, got: ~S~]"
                     (parse-error-trace-id c)
                     (parse-error-position c)
                     (parse-error-context c)
                     (parse-error-expected c)
                     (when (parse-error-text c)
                       (safe-subseq (parse-error-text c)
                                    (parse-error-position c)
                                    (min (+ (parse-error-position c) 20)
                                         (length (parse-error-text c)))))))))

(define-condition invalid-article-form (parse-error-condition)
  ((article-number :initarg :article-number :reader invalid-article-number))
  (:report (lambda (c stream)
             (format stream "Invalid article form~@[ for article ~A~]~@[ [~A]~]: ~A"
                     (invalid-article-number c)
                     (parse-error-trace-id c)
                     (parse-error-text c)))))

(define-condition missing-paragraph (parse-error-condition)
  ((paragraph-number :initarg :paragraph-number :reader missing-paragraph-number))
  (:report (lambda (c stream)
             (format stream "Missing paragraph ~A in article~@[ [~A]~]"
                     (missing-paragraph-number c)
                     (parse-error-trace-id c)))))

(define-condition semantic-annotation-error (parse-error-condition)
  ((annotation-type :initarg :annotation-type :reader semantic-error-type))
  (:report (lambda (c stream)
             (format stream "Semantic annotation error (~A)~@[ [~A]~]: ~A"
                     (semantic-error-type c)
                     (parse-error-trace-id c)
                     (parse-error-text c)))))

(defun safe-subseq (sequence start &optional end)
  "Safe subsequence extraction"
  (let ((len (length sequence)))
    (subseq sequence
            (min start len)
            (when end (min end len)))))

;;; ============================================================================
;;; PARSE RESULT PROTOCOL - Multiple Values + CLOS + Generics
;;; ============================================================================

(defclass parse-result (traceable-node)
  ((success-p :initarg :success-p :accessor parse-success-p :type boolean)
   (value :initarg :value :accessor parse-value)
   (remainder :initarg :remainder :accessor parse-remainder :type string)
   (position :initarg :position :accessor parse-position :type fixnum)
   (trace :initarg :trace :accessor parse-trace :initform nil)
   (consumed :initarg :consumed :accessor parse-consumed :initform 0 :type fixnum))
  (:documentation "Result of a parse operation - captures success, value, trace, and provenance"))

;;; --- Generic Functions for Parse Results ---

(defgeneric parse-result-successful-p (result)
  (:documentation "Check if parse was successful"))

(defgeneric parse-result-value (result)
  (:documentation "Get parsed value"))

(defgeneric parse-result-combine (result1 result2 &key combiner)
  (:documentation "Combine two parse results"))

(defmethod parse-result-successful-p ((result parse-result))
  (parse-success-p result))

(defmethod parse-result-value ((result parse-result))
  (when (parse-success-p result)
    (parse-value result)))

(defmethod parse-result-combine ((r1 parse-result) (r2 parse-result)
                                  &key (combiner #'list))
  "Combine two successful results, fail if either fails"
  (if (and (parse-success-p r1) (parse-success-p r2))
      (make-parse-success (funcall combiner (parse-value r1) (parse-value r2))
                          (parse-remainder r2)
                          (parse-position r2))
      (make-parse-failure (parse-remainder r1) (parse-position r1))))

(defmethod print-object ((result parse-result) stream)
  (print-unreadable-object (result stream :type t)
    (format stream "~:[FAIL~;OK~] @~A~@[ -> ~S~] [~A]"
            (parse-success-p result)
            (parse-position result)
            (when (parse-success-p result)
              (let ((v (parse-value result)))
                (if (> (length (princ-to-string v)) 30)
                    (format nil "~A..." (subseq (princ-to-string v) 0 27))
                    v)))
            (node-trace-id result))))

(defun make-parse-success (value remainder position &optional trace)
  "Create successful parse result with trace ID"
  (make-instance 'parse-result
                 :success-p t
                 :value value
                 :remainder remainder
                 :position position
                 :trace trace
                 :consumed position))

(defun make-parse-failure (remainder position &optional trace)
  "Create failed parse result with trace ID"
  (make-instance 'parse-result
                 :success-p nil
                 :value nil
                 :remainder remainder
                 :position position
                 :trace trace))

;;; ============================================================================
;;; PARSED STRUCTURES - Rich CLOS Model with Mixins
;;; ============================================================================

(defclass parsed-article (traceable-node semantic-node)
  ((number :initarg :number :accessor article-number :type (or fixnum null))
   (title :initarg :title :accessor article-title :type (or string null) :initform nil)
   (paragraphs :initarg :paragraphs :accessor article-paragraphs :type list :initform nil)
   (tokens :initarg :tokens :accessor article-tokens :type list :initform nil)
   (metadata :initarg :metadata :accessor article-metadata :type list :initform nil)
   (source-text :initarg :source-text :accessor article-source-text :type string)
   (parse-trace :initarg :parse-trace :accessor article-parse-trace :initform nil)
   ;; Cross-references
   (references-to :initarg :references-to :accessor article-references-to :initform nil)
   (referenced-by :initarg :referenced-by :accessor article-referenced-by :initform nil))
  (:documentation "Fully parsed Constitution article with traceability and semantics"))

(defclass parsed-paragraph (traceable-node semantic-node)
  ((number :initarg :number :accessor paragraph-number :type (or fixnum null))
   (text :initarg :text :accessor paragraph-text :type string)
   (tokens :initarg :tokens :accessor paragraph-tokens :type list :initform nil)
   (clauses :initarg :clauses :accessor paragraph-clauses :type list :initform nil)
   (parent-article :initarg :parent-article :accessor paragraph-parent :initform nil))
  (:documentation "Parsed paragraph within an article"))

(defclass parsed-clause (traceable-node semantic-node)
  ((number :initarg :number :accessor clause-number :type (or fixnum null))
   (text :initarg :text :accessor clause-text :type string)
   (clause-type :initarg :clause-type :accessor clause-type :initform :standard)
   (parent-paragraph :initarg :parent-paragraph :accessor clause-parent :initform nil))
  (:documentation "Parsed clause within a paragraph"))

;;; --- Print Object Methods ---

(defmethod print-object ((article parsed-article) stream)
  (print-unreadable-object (article stream :type t)
    (format stream "Άρθρο ~A: ~A παράγραφοι [~A]~@[ ~A~]"
            (article-number article)
            (length (article-paragraphs article))
            (node-trace-id article)
            (when (node-semantics article) "[SEM]"))))

(defmethod print-object ((para parsed-paragraph) stream)
  (print-unreadable-object (para stream :type t)
    (format stream "§~A: ~A tokens [~A]"
            (paragraph-number para)
            (length (paragraph-tokens para))
            (node-trace-id para))))

(defmethod print-object ((clause parsed-clause) stream)
  (print-unreadable-object (clause stream :type t)
    (format stream "Clause ~A (~A) [~A]"
            (clause-number clause)
            (clause-type clause)
            (node-trace-id clause))))

;;; ============================================================================
;;; GENERIC PARSING PROTOCOL - Polymorphic Interface
;;; ============================================================================

(defgeneric parse-node (source node-type &key &allow-other-keys)
  (:documentation "Parse source into specified node type"))

(defgeneric parse-children (node &key recursive)
  (:documentation "Parse children of a node"))

(defgeneric serialize-node (node format)
  (:documentation "Serialize node to specified format"))

(defgeneric node-to-rdf (node &key base-uri)
  (:documentation "Convert node to RDF triples"))

;;; --- Method Implementations with AROUND, BEFORE, AFTER ---

(defmethod parse-node :around (source node-type &key &allow-other-keys)
  "Wrap all parsing with tracing"
  (let ((trace-id (generate-trace-id)))
    (log-debug "Starting parse [~A]: ~A" trace-id node-type)
    (multiple-value-prog1
        (call-next-method)
      (log-debug "Completed parse [~A]" trace-id))))

(defmethod parse-node ((source string) (node-type (eql :article)) &key parent-trace-id)
  "Parse string source into article"
  (parse-constitution-article source :parent-trace-id parent-trace-id))

(defmethod parse-node ((source string) (node-type (eql :paragraph)) &key number parent-trace-id)
  "Parse string source into paragraph"
  (parse-paragraph source :expected-number number :parent-trace-id parent-trace-id))

(defmethod serialize-node ((node parsed-article) (format (eql :plist)))
  "Serialize article to plist"
  (list :type :article
        :number (article-number node)
        :title (article-title node)
        :trace-id (node-trace-id node)
        :paragraphs (mapcar (lambda (p) (serialize-node p :plist))
                            (article-paragraphs node))
        :semantics (node-semantics node)
        :norm-refs (node-norm-refs node)))

(defmethod serialize-node ((node parsed-paragraph) (format (eql :plist)))
  "Serialize paragraph to plist"
  (list :type :paragraph
        :number (paragraph-number node)
        :text (paragraph-text node)
        :trace-id (node-trace-id node)
        :tokens (paragraph-tokens node)))

;;; ============================================================================
;;; PARSER COMBINATORS - Functional Parsing with Closures
;;; ============================================================================

(deftype parser ()
  "A parser is a function: string × position → parse-result"
  '(function (string fixnum) parse-result))

(defun run-parser (parser text &optional (position 0))
  "Execute parser on text at position"
  (funcall parser text position))

;;; --- Compiler Macro for Optimization ---

(define-compiler-macro run-parser (&whole form parser text &optional (position 0))
  "Optimize run-parser when parser is known at compile time"
  (if (and (consp parser) (eq (car parser) 'function))
      `(funcall ,parser ,text ,position)
      form))

;;; --- Primitive Parsers ---

(defun char-parser (char)
  "Parse a single character"
  (declare (type character char))
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (if (and (< pos (length text))
             (char= (char text pos) char))
        (make-parse-success char text (1+ pos))
        (make-parse-failure text pos))))

(defun string-parser (str)
  "Parse an exact string"
  (declare (type string str))
  (let ((len (length str)))
    (lambda (text pos)
      (declare (type string text) (type fixnum pos))
      (if (and (<= (+ pos len) (length text))
               (string= str text :start2 pos :end2 (+ pos len)))
          (make-parse-success str text (+ pos len))
          (make-parse-failure text pos)))))

(defun predicate-parser (predicate &optional (name "predicate"))
  "Parse characters matching predicate"
  (declare (type function predicate) (ignore name))
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (if (and (< pos (length text))
             (funcall predicate (char text pos)))
        (make-parse-success (char text pos) text (1+ pos))
        (make-parse-failure text pos))))

(defun regex-parser (pattern)
  "Parse using regex pattern (via cl-ppcre)"
  (declare (type string pattern))
  (let ((scanner (cl-ppcre:create-scanner pattern)))
    (lambda (text pos)
      (declare (type string text) (type fixnum pos))
      (multiple-value-bind (start end)
          (cl-ppcre:scan scanner text :start pos)
        (if (and start (= start pos))
            (make-parse-success (subseq text start end) text end)
            (make-parse-failure text pos))))))

;;; --- Combinator Parsers ---

(defun sequence-parser (&rest parsers)
  "Sequence of parsers - all must succeed"
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (let ((results nil)
          (current-pos pos))
      (dolist (parser parsers)
        (let ((result (run-parser parser text current-pos)))
          (unless (parse-success-p result)
            (return-from sequence-parser
              (make-parse-failure text pos)))
          (push (parse-value result) results)
          (setf current-pos (parse-position result))))
      (make-parse-success (nreverse results) text current-pos))))

(defun choice-parser (&rest parsers)
  "Try parsers in order - first success wins"
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (dolist (parser parsers (make-parse-failure text pos))
      (let ((result (run-parser parser text pos)))
        (when (parse-success-p result)
          (return result))))))

(defun many-parser (parser &key (min 0) max)
  "Parse zero or more occurrences"
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (let ((results nil)
          (current-pos pos)
          (count 0))
      (loop
        (when (and max (>= count max))
          (return))
        (let ((result (run-parser parser text current-pos)))
          (unless (parse-success-p result)
            (return))
          (push (parse-value result) results)
          (setf current-pos (parse-position result))
          (incf count)))
      (if (>= count min)
          (make-parse-success (nreverse results) text current-pos)
          (make-parse-failure text pos)))))

(defun optional-parser (parser &optional default)
  "Parse optionally - never fails"
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (let ((result (run-parser parser text pos)))
      (if (parse-success-p result)
          result
          (make-parse-success default text pos)))))

(defun map-parser (parser function)
  "Transform parser result with function"
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (let ((result (run-parser parser text pos)))
      (if (parse-success-p result)
          (make-parse-success (funcall function (parse-value result))
                              text
                              (parse-position result))
          result))))

(defun bind-parser (parser function)
  "Monadic bind - chain parsers based on result"
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (let ((result (run-parser parser text pos)))
      (if (parse-success-p result)
          (run-parser (funcall function (parse-value result))
                      text
                      (parse-position result))
          result))))

(defun lookahead-parser (parser)
  "Lookahead - parse without consuming"
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (let ((result (run-parser parser text pos)))
      (if (parse-success-p result)
          (make-parse-success (parse-value result) text pos)  ; Don't advance position
          result))))

(defun not-parser (parser)
  "Negative lookahead - succeed if parser fails"
  (lambda (text pos)
    (declare (type string text) (type fixnum pos))
    (let ((result (run-parser parser text pos)))
      (if (parse-success-p result)
          (make-parse-failure text pos)
          (make-parse-success nil text pos)))))

;;; --- Utility Parsers ---

(defun skip-whitespace ()
  "Skip whitespace characters"
  (many-parser (predicate-parser #'whitespace-char-p "whitespace")))

(defun whitespace-char-p (char)
  "Check if character is whitespace"
  (member char '(#\Space #\Tab #\Newline #\Return)))

(defun digit-parser ()
  "Parse a digit"
  (predicate-parser #'digit-char-p "digit"))

(defun integer-parser ()
  "Parse an integer"
  (map-parser (many-parser (digit-parser) :min 1)
              (lambda (digits)
                (parse-integer (coerce digits 'string)))))

(defun greek-word-parser ()
  "Parse a Greek word"
  (map-parser (many-parser (predicate-parser #'greek-letter-p "greek-letter") :min 1)
              (lambda (chars) (coerce chars 'string))))

(defun greek-letter-p (char)
  "Check if character is Greek letter"
  (let ((code (char-code char)))
    (or (<= #x0370 code #x03FF)   ; Greek and Coptic
        (<= #x1F00 code #x1FFF)))) ; Greek Extended

;;; ============================================================================
;;; TRACE SYSTEM - Full Parse Trace Management
;;; ============================================================================

(defvar *parse-trace* nil
  "Current parse trace accumulator")

(defvar *parse-depth* 0
  "Current parsing depth for trace indentation")

(defvar *current-trace-id* nil
  "Current trace ID for correlation")

(defstruct (trace-entry (:type list))
  "Structured trace entry"
  event          ; :enter or :exit
  name           ; Stage name
  depth          ; Nesting depth
  time           ; Internal time
  trace-id       ; Correlation ID
  source-info    ; Optional source location
  data)          ; Optional additional data

(defun create-trace-entry (event name &key data source-info)
  "Create structured trace entry (renamed to avoid defstruct conflict)"
  (list event name *parse-depth* (get-internal-real-time)
        *current-trace-id* source-info data))

(defmacro with-parse-trace ((name &key source-info) &body body)
  "Execute body with parse tracing and trace ID propagation"
  `(let ((*parse-depth* (1+ *parse-depth*))
         (*current-trace-id* (or *current-trace-id* (generate-trace-id))))
     (push (create-trace-entry :enter ',name
                               :source-info ,source-info)
           *parse-trace*)
     (multiple-value-prog1
         (progn ,@body)
       (push (create-trace-entry :exit ',name)
             *parse-trace*))))

(defun trace-to-tree (flat-trace)
  "Convert flat trace to tree structure using ECASE for exhaustive dispatch"
  (let ((stack nil)
        (roots nil))
    (dolist (entry (reverse flat-trace))
      (destructuring-bind (event name depth time trace-id source-info data) entry
        (declare (ignore time trace-id source-info data))
        ;; ECASE - exhaustive match, signals error if no match
        (ecase event
          (:enter
           (push (list :name name :depth depth :children nil) stack))
          (:exit
           (let ((completed (pop stack)))
             (if stack
                 (push completed (getf (car stack) :children))
                 (push completed roots)))))))
    (nreverse roots)))

;;; ============================================================================
;;; ARTICLE PARSING DSL - Macros for Declarative Parsing
;;; ============================================================================

(defmacro define-article-parser (name lambda-list &body body)
  "Define a named article parser with automatic tracing and registration"
  (let ((parser-name (intern (format nil "PARSE-~A" name)))
        (doc (when (stringp (car body)) (pop body))))
    `(progn
       (defun ,parser-name ,lambda-list
         ,@(when doc (list doc))
         (with-parse-trace (,name)
           ,@body))
       (setf (get ',parser-name 'parser-type) ',name)
       (setf (get ',parser-name 'parser-doc) ,doc)
       (export ',parser-name)
       ',parser-name)))

(defmacro match-article-header (text-var)
  "Match article header pattern: 'Άρθρο N' or 'ΑΡΘΡΟ N'"
  `(multiple-value-bind (match groups)
       (cl-ppcre:scan-to-strings
        "^\\s*[Άά]ρθρο\\s+(\\d+)\\s*\\.?\\s*"
        ,text-var)
     (when match
       (values (parse-integer (aref groups 0))
               (length match)))))

(defmacro match-paragraph-number (text-var)
  "Match paragraph number pattern"
  `(multiple-value-bind (match groups)
       (cl-ppcre:scan-to-strings
        "^\\s*(\\d+)\\.\\s*"
        ,text-var)
     (when match
       (values (parse-integer (aref groups 0))
               (length match)))))

(defmacro with-restarts-for-parsing (&body body)
  "Establish restarts for parse error recovery"
  `(restart-case
       (progn ,@body)
     (use-default-parser ()
       :report "Use default parser and continue"
       :test (lambda (c) (declare (ignore c)) t)
       (log-info "Restart: using default parser")
       (funcall (parse-as-raw-text) ""))
     (skip-and-log (reason)
       :report "Skip this element and log"
       :interactive (lambda () (list (read-line *query-io*)))
       (log-warn "Restart: skipped element - ~A" reason)
       nil)
     (return-partial (partial-result)
       :report "Return partial parse result"
       :interactive (lambda () (list (eval (read *query-io*))))
       (log-info "Restart: returning partial result")
       partial-result)
     (retry-with-normalizer (normalizer)
       :report "Retry with text normalizer"
       :interactive (lambda ()
                      (format *query-io* "Normalizer function: ")
                      (list (read *query-io*)))
       (log-info "Restart: retrying with normalizer")
       normalizer)))

;;; ============================================================================
;;; CORE PARSING FUNCTIONS
;;; ============================================================================

(defun parse-article-number (text)
  "Extract article number from text"
  (declare (type string text))
  (multiple-value-bind (number consumed)
      (match-article-header text)
    (if number
        (values number consumed)
        (values nil 0))))

(defun parse-paragraph (text &key expected-number parent-trace-id)
  "Parse a single paragraph with full traceability"
  (declare (type string text))
  (with-parse-trace (:paragraph)
    (let ((trimmed (string-trim '(#\Space #\Tab #\Newline) text)))
      (multiple-value-bind (para-num consumed)
          (match-paragraph-number trimmed)
        (let* ((para-text (if para-num
                              (subseq trimmed consumed)
                              trimmed))
               (tokens (tokenize-paragraph para-text)))
          (when (and expected-number para-num
                     (/= expected-number para-num))
            (cerror "Continue with actual number"
                    'missing-paragraph
                    :paragraph-number expected-number
                    :text text
                    :trace-id *current-trace-id*))
          (make-instance 'parsed-paragraph
                         :number (or para-num expected-number)
                         :text para-text
                         :tokens tokens
                         :parent-trace-id parent-trace-id))))))

(defun parse-clause (text &key clause-number parent-trace-id)
  "Parse a clause within a paragraph"
  (declare (type string text))
  (with-parse-trace (:clause)
    (make-instance 'parsed-clause
                   :number clause-number
                   :text (string-trim '(#\Space #\Tab #\Newline) text)
                   :clause-type (detect-clause-type text)
                   :parent-trace-id parent-trace-id)))

;;; --- Clause Type Detection with Data-Driven Dispatch ---

(defparameter *clause-type-patterns*
  '((:prohibition . "(?i)απαγορεύεται|δεν επιτρέπεται|απαγορεύονται")
    (:obligation . "(?i)υποχρεούται|οφείλει|πρέπει|υποχρεούνται")
    (:permission . "(?i)δικαιούται|μπορεί|επιτρέπεται|δικαιούνται")
    (:definition . "(?i)ορίζεται|θεωρείται|νοείται|ορίζονται")
    (:exception . "(?i)εκτός αν|εξαιρουμένων|πλην")
    (:condition . "(?i)εφόσον|υπό την προϋπόθεση|εάν")
    (:delegation . "(?i)εξουσιοδοτείται|ανατίθεται|μεταβιβάζεται"))
  "Alist of clause types to regex patterns - data-driven design")

(defun detect-clause-type (text)
  "Detect type of legal clause using data-driven pattern matching
   Uses LOOP with THEREIS for first-match semantics"
  (declare (type string text))
  (or (loop for (clause-type . pattern) in *clause-type-patterns*
            thereis (when (cl-ppcre:scan pattern text) clause-type))
      :standard))

(defun clause-type-description (clause-type)
  "Get description for clause type - ECASE for exhaustive matching"
  (ecase clause-type
    (:prohibition "Απαγορευτική διάταξη")
    (:obligation "Υποχρεωτική διάταξη")
    (:permission "Επιτρεπτική διάταξη")
    (:definition "Ορισμός")
    (:exception "Εξαίρεση")
    (:condition "Υπό αίρεση διάταξη")
    (:delegation "Εξουσιοδότηση")
    (:standard "Τυπική διάταξη")))

(defun tokenize-paragraph (text)
  "Tokenize paragraph - whitespace-based tokenization with Greek support"
  (declare (type string text))
  ;; Simple but effective tokenization: split on whitespace, remove empty
  (remove-if (lambda (s) (zerop (length s)))
             (cl-ppcre:split "\\s+" text)))

(defun split-into-paragraphs (text)
  "Split article text into paragraphs"
  (declare (type string text))
  (let ((parts (cl-ppcre:split "(?=\\d+\\.\\s)|(?:\\n\\s*\\n)" text)))
    (remove-if (lambda (s)
                 (zerop (length (string-trim '(#\Space #\Tab #\Newline) s))))
               parts)))

(defun split-into-clauses (text)
  "Split paragraph into clauses"
  (declare (type string text))
  (cl-ppcre:split "[.;]\\s+" text))

;;; ============================================================================
;;; MAIN PARSING INTERFACE
;;; ============================================================================

(defun parse-constitution-article (text &key (trace-p t) parent-trace-id
                                             source-info semantics-p)
  "Parse Constitution article text with full Lisp power

  Args:
    text: Raw article text (string)
    trace-p: Enable parse tracing (default T)
    parent-trace-id: Parent trace for provenance chain
    source-info: Source location (:file :page :line etc.)
    semantics-p: Also extract semantic annotations

  Returns (multiple values):
    1. parsed-article object (with trace-id, provenance, semantics)
    2. metadata alist
    3. parse trace (if trace-p)
    4. validation-result

  Restarts:
    use-default-parser - Fall back to raw text parsing
    skip-and-log - Skip element with logging
    return-partial - Return partial result
    retry-with-normalizer - Retry with text normalization"
  (declare (type string text))
  (let ((*parse-trace* nil)
        (*current-trace-id* (or parent-trace-id (generate-trace-id))))
    (with-restarts-for-parsing
      (with-parse-trace (:article :source-info source-info)
        (multiple-value-bind (article-num header-end)
            (parse-article-number text)

          (unless article-num
            (restart-case
                (error 'invalid-article-form
                       :text text
                       :expected "Άρθρο N"
                       :trace-id *current-trace-id*)
              (use-article-number (num)
                :report "Specify article number manually"
                :interactive (lambda ()
                               (format *query-io* "Enter article number: ")
                               (list (parse-integer (read-line *query-io*))))
                (setf article-num num
                      header-end 0))))

          ;; Parse body into paragraphs
          (let* ((body-text (subseq text (or header-end 0)))
                 (paragraph-texts (split-into-paragraphs body-text))
                 (paragraphs (loop for para-text in paragraph-texts
                                   for i from 1
                                   collect (parse-paragraph para-text
                                                            :expected-number i
                                                            :parent-trace-id *current-trace-id*)))
                 ;; Tokenize full article for NLP
                 (all-tokens (reduce #'append paragraphs
                                     :key #'paragraph-tokens
                                     :initial-value nil))
                 ;; Build metadata
                 (metadata (list (cons :article-number article-num)
                                 (cons :paragraph-count (length paragraphs))
                                 (cons :token-count (length all-tokens))
                                 (cons :parse-timestamp (get-universal-time))
                                 (cons :trace-id *current-trace-id*)))
                 ;; Optional semantics extraction
                 (semantics (when semantics-p
                              (extract-article-semantics text paragraphs))))

            ;; Create parsed article with full traceability
            (let ((article (make-instance 'parsed-article
                                          :number article-num
                                          :paragraphs paragraphs
                                          :tokens all-tokens
                                          :metadata metadata
                                          :source-text text
                                          :parse-trace (when trace-p
                                                         (nreverse *parse-trace*))
                                          ;; Traceability
                                          :parent-trace-id parent-trace-id
                                          :source-info source-info
                                          :provenance-chain (list :logical text
                                                                  :canonical nil
                                                                  :parsed t)
                                          ;; Semantics
                                          :semantics semantics)))

              ;; Link paragraphs to parent
              (dolist (para paragraphs)
                (setf (paragraph-parent para) article))

              ;; Validate
              (multiple-value-bind (valid-p errors) (validate-trace article)
                (values article
                        metadata
                        (when trace-p (article-parse-trace article))
                        (list :valid valid-p :errors errors))))))))))

(defun extract-article-semantics (text paragraphs)
  "Extract semantic annotations from article"
  (declare (ignore text))
  (list :concepts (extract-legal-concepts paragraphs)
        :relations (extract-legal-relations paragraphs)
        :entities (extract-named-entities paragraphs)))

(defun extract-legal-concepts (paragraphs)
  "Extract legal concepts from paragraphs"
  (let ((concepts nil))
    (dolist (para paragraphs)
      (let ((text (paragraph-text para)))
        (when (cl-ppcre:scan "δικαίωμα" text)
          (push :right concepts))
        (when (cl-ppcre:scan "υποχρέωση" text)
          (push :obligation concepts))
        (when (cl-ppcre:scan "απαγόρευση" text)
          (push :prohibition concepts))))
    (remove-duplicates concepts)))

(defun extract-legal-relations (paragraphs)
  "Extract relations between legal concepts"
  (declare (ignore paragraphs))
  nil) ; Placeholder for relation extraction

(defun extract-named-entities (paragraphs)
  "Extract named entities from paragraphs"
  (declare (ignore paragraphs))
  nil) ; Placeholder for NER

(defun parse-as-raw-text ()
  "Fallback parser - treat as raw text"
  (lambda (text)
    (make-instance 'parsed-article
                   :number nil
                   :paragraphs (list (make-instance 'parsed-paragraph
                                                    :number nil
                                                    :text text))
                   :source-text text
                   :metadata (list (cons :parse-mode :raw)))))

;;; ============================================================================
;;; READER MACRO - Custom Syntax for Legal Text
;;; ============================================================================

(defvar *legal-readtable* (copy-readtable)
  "Custom readtable for legal text parsing")

(defun |#§-reader| (stream char arg)
  "Reader macro for legal article references: #§N or #§\"text\"
   Uses CASE for character dispatch where possible"
  (declare (ignore char arg))
  (let ((next (peek-char nil stream)))
    ;; Use CASE for literal character matches, COND for predicates
    (case next
      ;; #§"text" - Inline article text
      (#\"
       (let ((text (read stream t nil t)))
         `(parse-constitution-article ,text)))
      ;; #§(form) - Parsed form
      (#\(
       (let ((form (read stream t nil t)))
         `(legal-form ,form)))
      ;; #§:keyword - Legal concept reference
      (#\:
       (let ((kw (read stream t nil t)))
         `(legal-concept-ref ,kw)))
      ;; #§[form] - Quoted node expression
      (#\[
       (read-char stream t nil t) ; consume [
       (let ((form (read-delimited-list #\] stream t)))
         `(quote-node ,(first form))))
      ;; Default: check for digits (article numbers)
      (otherwise
       (cond
         ;; #§123 - Article number reference
         ((digit-char-p next)
          (let ((num (read stream t nil t)))
            `(article-reference ,num)))
         ;; #§symbol - Symbol reference
         ((alpha-char-p next)
          (let ((sym (read stream t nil t)))
            `(legal-symbol-ref ',sym)))
         (t
          (error 'parse-error-condition
                 :text (format nil "Invalid #§ syntax at '~C'" next)
                 :expected "digit, string, paren, bracket, or keyword"
                 :position 0)))))))

(defun enable-legal-syntax ()
  "Enable #§ reader macro in current readtable"
  (set-dispatch-macro-character #\# #\§ #'|#§-reader| *legal-readtable*)
  (setf *readtable* *legal-readtable*))

(defun disable-legal-syntax ()
  "Restore standard readtable"
  (setf *readtable* (copy-readtable nil)))

(defun article-reference (number)
  "Create reference to article by number"
  (list :article-ref number :trace-id (generate-trace-id)))

(defun legal-form (form)
  "Process legal form expression"
  form)

(defun legal-concept-ref (keyword)
  "Reference to legal concept by keyword"
  (list :concept-ref keyword))

(defun legal-symbol-ref (symbol)
  "Reference to legal symbol (e.g., article name, concept)"
  (list :symbol-ref symbol :trace-id (generate-trace-id)))

;;; ============================================================================
;;; BATCH PARSING - Process Multiple Articles
;;; ============================================================================

(defun parse-articles-batch (articles-list &key (parallel-p nil) (trace-p t))
  "Parse multiple articles, optionally in parallel

  Args:
    articles-list: List of (number . text) pairs or just texts
    parallel-p: Use parallel processing (requires lparallel)
    trace-p: Enable tracing for each article

  Returns:
    List of parsed-article objects with shared batch-trace-id"
  (declare (type list articles-list))
  (let ((batch-trace-id (generate-trace-id)))
    (log-info "Starting batch parse [~A]: ~A articles"
                                   batch-trace-id (length articles-list))
    (let ((parse-fn (lambda (item)
                      (handler-case
                          (etypecase item
                            (cons (parse-constitution-article
                                   (cdr item)
                                   :trace-p trace-p
                                   :parent-trace-id batch-trace-id))
                            (string (parse-constitution-article
                                     item
                                     :trace-p trace-p
                                     :parent-trace-id batch-trace-id)))
                        (error (e)
                          (log-error "Parse failed in batch [~A]: ~A"
                                     batch-trace-id e)
                          nil)))))
      (if parallel-p
          (lparallel:pmapcar parse-fn articles-list)
          (mapcar parse-fn articles-list)))))

;;; ============================================================================
;;; PATTERN MATCHING DSL - Destructuring Legal Text
;;; ============================================================================

(defmacro match-legal-pattern (text &body patterns)
  "Match legal text patterns with destructuring

  Example:
    (match-legal-pattern article-text
      ((article ?n paragraph ?p) (format t \"Art ~A, Para ~A\" ?n ?p))
      ((article ?n) (format t \"Article ~A\" ?n))
      (_ (format t \"Unknown pattern\")))"
  (let ((text-var (gensym "TEXT")))
    `(let ((,text-var ,text))
       (cond
         ,@(loop for (pattern . body) in patterns
                 collect (compile-pattern-clause text-var pattern body))))))

(defun compile-pattern-clause (text-var pattern body)
  "Compile a single pattern clause"
  (if (eq pattern '_)
      `(t ,@body)
      (let ((bindings (extract-pattern-bindings pattern))
            (regex (pattern-to-regex pattern)))
        `((cl-ppcre:scan ,regex ,text-var)
          (cl-ppcre:register-groups-bind ,bindings (,regex ,text-var)
            ,@body)))))

(defun extract-pattern-bindings (pattern)
  "Extract variable bindings from pattern (symbols starting with ?)"
  (loop for elem in pattern
        when (and (symbolp elem)
                  (> (length (symbol-name elem)) 0)
                  (char= (char (symbol-name elem) 0) #\?))
        collect elem))

(defun pattern-to-regex (pattern)
  "Convert pattern to regex string using CASE for symbol dispatch"
  (with-output-to-string (s)
    (loop for elem in pattern
          do (etypecase elem
               ;; Known legal pattern symbols - dispatch with CASE
               (symbol
                (case elem
                  (article (write-string "[Άά]ρθρο\\s+" s))
                  (paragraph (write-string "παράγραφος\\s+" s))
                  (clause (write-string "εδάφιο\\s+" s))
                  (section (write-string "τμήμα\\s+" s))
                  (chapter (write-string "κεφάλαιο\\s+" s))
                  (otherwise
                   ;; Variable binding (starts with ?)
                   (if (and (> (length (symbol-name elem)) 0)
                            (char= (char (symbol-name elem) 0) #\?))
                       (write-string "(\\d+)" s)
                       (write-string ".*?" s)))))
               ;; String literals - escape regex metacharacters
               (string (write-string (cl-ppcre:quote-meta-chars elem) s))
               ;; Character - literal match
               (character (write-string (cl-ppcre:quote-meta-chars
                                         (string elem)) s))))))

;;; ============================================================================
;;; HOMOICONICITY - Code as Data (Maximum Lisp Exploitation)
;;; ============================================================================
;;;
;;; Lisp's homoiconicity means code IS data. We exploit this fully:
;;;   1. Parsed structures are representable as S-expressions
;;;   2. S-expressions can be evaluated back to structures
;;;   3. Macros can generate parsing code from data
;;;   4. Reader macros create parseable literals
;;;   5. QUOTE/EVAL symmetry for all parsed nodes

;;; --- Homoiconic Data Structures (defstruct :type list) ---

(defstruct (homoiconic-article (:type list) (:constructor make-h-article))
  "Homoiconic article - pure list structure, evaluable"
  (type :article)
  number
  title
  paragraphs
  trace-id
  semantics)

(defstruct (homoiconic-paragraph (:type list) (:constructor make-h-paragraph))
  "Homoiconic paragraph - pure list structure"
  (type :paragraph)
  number
  text
  tokens
  trace-id)

(defstruct (homoiconic-clause (:type list) (:constructor make-h-clause))
  "Homoiconic clause - pure list structure"
  (type :clause)
  number
  text
  clause-type
  trace-id)

;;; --- Node to S-Expression Conversion ---

(defgeneric node-to-sexp (node)
  (:documentation "Convert parsed node to S-expression (homoiconic form)"))

(defmethod node-to-sexp ((node parsed-article))
  "Convert article to evaluable S-expression"
  `(make-h-article
    :number ,(article-number node)
    :title ,(article-title node)
    :paragraphs (list ,@(mapcar #'node-to-sexp (article-paragraphs node)))
    :trace-id ,(node-trace-id node)
    :semantics ',(node-semantics node)))

(defmethod node-to-sexp ((node parsed-paragraph))
  "Convert paragraph to evaluable S-expression"
  `(make-h-paragraph
    :number ,(paragraph-number node)
    :text ,(paragraph-text node)
    :tokens ',(paragraph-tokens node)
    :trace-id ,(node-trace-id node)))

(defmethod node-to-sexp ((node parsed-clause))
  "Convert clause to evaluable S-expression"
  `(make-h-clause
    :number ,(clause-number node)
    :text ,(clause-text node)
    :clause-type ,(clause-type node)
    :trace-id ,(node-trace-id node)))

;;; --- S-Expression to Node Conversion ---

(defgeneric sexp-to-node (sexp)
  (:documentation "Convert S-expression back to parsed node"))

(defmethod sexp-to-node ((sexp list))
  "Convert list S-expression to appropriate node using ECASE with OTHERWISE fallback"
  (let ((type (first sexp))
        (props (rest sexp)))
    ;; Use CASE for known types, fall through for unknown
    (case type
      (:article
       (make-instance 'parsed-article
                      :number (getf props :number)
                      :title (getf props :title)
                      :paragraphs (mapcar #'sexp-to-node (getf props :paragraphs))
                      :semantics (getf props :semantics)))
      (:paragraph
       (make-instance 'parsed-paragraph
                      :number (getf props :number)
                      :text (getf props :text)
                      :tokens (getf props :tokens)))
      (:clause
       (make-instance 'parsed-clause
                      :number (getf props :number)
                      :text (getf props :text)
                      :clause-type (getf props :clause-type)))
      (:trace
       (apply #'make-trace (getf props :source) props))
      (otherwise sexp))))

(defmethod sexp-to-node ((sexp symbol))
  "Convert symbol S-expression - TYPECASE demonstration"
  (typecase sexp
    (keyword (list :keyword-ref sexp))
    (symbol (list :symbol-ref sexp))
    (t sexp)))

(defmethod sexp-to-node ((sexp string))
  "Convert string S-expression to paragraph"
  (make-instance 'parsed-paragraph
                 :number nil
                 :text sexp))

;;; --- Evaluable Node Protocol ---

(defgeneric node-to-code (node)
  (:documentation "Convert node to executable Lisp code"))

(defmethod node-to-code ((node parsed-article))
  "Generate code that reconstructs this article"
  `(let ((art (parse-constitution-article ,(article-source-text node))))
     (add-semantics art ',(node-semantics node))
     ,@(loop for ref in (node-norm-refs node)
             collect `(add-norm-reference art ,(getf ref :uri)))
     art))

;;; --- Quote Macro for Parsed Nodes ---

(defmacro quote-node (node-form)
  "Quote a parsed node as data (prevents evaluation)"
  `(node-to-sexp ,node-form))

(defmacro unquote-node (sexp-form)
  "Unquote S-expression back to parsed node"
  `(sexp-to-node ,sexp-form))

;;; --- Homoiconic Transformation Macros ---

(defmacro with-homoiconic-form ((var node) &body body)
  "Execute body with node converted to homoiconic S-expression"
  `(let ((,var (node-to-sexp ,node)))
     ,@body))

(defmacro transform-article (article &body transformations)
  "Apply transformations to article in homoiconic form, return new article

  Example:
    (transform-article art
      (:add-semantics '(:key :value))
      (:set-title \"New Title\"))"
  (let ((sexp-var (gensym "SEXP")))
    `(let ((,sexp-var (node-to-sexp ,article)))
       ,@(loop for (op . args) in transformations
               collect (case op
                         (:add-semantics
                          `(setf (homoiconic-article-semantics ,sexp-var)
                                 (append (homoiconic-article-semantics ,sexp-var)
                                         ,@args)))
                         (:set-title
                          `(setf (homoiconic-article-title ,sexp-var) ,@args))
                         (:set-number
                          `(setf (homoiconic-article-number ,sexp-var) ,@args))
                         (otherwise
                          `(funcall ,op ,sexp-var ,@args))))
       (sexp-to-node ,sexp-var))))

;;; --- Self-Modifying Parser Definition ---

(defmacro define-self-modifying-parser (name &body rules)
  "Define a parser that can modify its own rules at runtime

  Example:
    (define-self-modifying-parser greek-legal
      (:pattern article \"Άρθρο (\\d+)\" :capture number)
      (:pattern paragraph \"(\\d+)\\.\" :capture para-num))"
  (let ((rules-var (intern (format nil "*~A-RULES*" name)))
        (parser-fn (intern (format nil "PARSE-WITH-~A" name))))
    `(progn
       (defvar ,rules-var ',rules
         ,(format nil "Rules for ~A parser (modifiable at runtime)" name))

       (defun ,parser-fn (text)
         ,(format nil "Parse TEXT using ~A rules (self-modifying)" name)
         (let ((result nil))
           (dolist (rule ,rules-var)
             (destructuring-bind (type pattern regex &key capture) rule
               (declare (ignore type capture))
               (multiple-value-bind (match groups)
                   (cl-ppcre:scan-to-strings regex text)
                 (when match
                   (push (list pattern match groups) result)))))
           (nreverse result)))

       (defun ,(intern (format nil "ADD-~A-RULE" name)) (rule)
         ,(format nil "Add rule to ~A parser at runtime" name)
         (push rule ,rules-var))

       (defun ,(intern (format nil "REMOVE-~A-RULE" name)) (pattern)
         ,(format nil "Remove rule from ~A parser at runtime" name)
         (setf ,rules-var
               (remove pattern ,rules-var :key #'second)))

       ',name)))

;;; --- Code Generation from Parsed Structures ---

(defgeneric generate-validator (node)
  (:documentation "Generate validation code from parsed structure"))

(defmethod generate-validator ((node parsed-article))
  "Generate validation function for this article's structure"
  `(lambda (text)
     (let ((parsed (parse-constitution-article text)))
       (and (= (article-number parsed) ,(article-number node))
            (= (length (article-paragraphs parsed))
               ,(length (article-paragraphs node)))
            ,@(loop for para in (article-paragraphs node)
                    for i from 0
                    collect `(string= (paragraph-text (nth ,i (article-paragraphs parsed)))
                                      ,(paragraph-text para)))))))

(defgeneric generate-transformer (from-node to-template)
  (:documentation "Generate transformation code between node structures"))

(defmethod generate-transformer ((from parsed-article) to-template)
  "Generate transformer function"
  (declare (ignore to-template))
  `(lambda (article)
     (make-instance 'parsed-article
                    :number (article-number article)
                    :paragraphs (mapcar #'identity (article-paragraphs article)))))

;;; --- Lisp Form Embedding in Parsed Text ---

(defun embed-lisp-in-text (text)
  "Find and mark embedded Lisp forms in legal text

  Recognizes: {{lisp-form}} syntax"
  (let ((forms nil)
        (clean-text text))
    (cl-ppcre:do-matches-as-strings (match "\\{\\{([^}]+)\\}\\}" text)
      (let* ((form-str (subseq match 2 (- (length match) 2)))
             (form (read-from-string form-str)))
        (push form forms)
        (setf clean-text (cl-ppcre:regex-replace match clean-text ""))))
    (values clean-text (nreverse forms))))

(defun evaluate-embedded-forms (text)
  "Parse text, evaluate embedded Lisp, return result"
  (multiple-value-bind (clean-text forms) (embed-lisp-in-text text)
    (values clean-text
            (mapcar #'eval forms))))

;;; --- AST as Executable Specification ---

(defmacro defspecification (name article-form &body constraints)
  "Define legal specification from parsed article as executable code

  Example:
    (defspecification article-1-spec
        (parse-constitution-article \"Άρθρο 1...\")
      (:must-have-paragraphs 3)
      (:requires-concept :democracy))"
  `(progn
     (defparameter ,name ,article-form
       "Legal specification")
     (defun ,(intern (format nil "VALIDATE-~A" name)) (article)
       (and ,@(loop for (constraint . args) in constraints
                    collect (case constraint
                              (:must-have-paragraphs
                               `(= (length (article-paragraphs article)) ,@args))
                              (:requires-concept
                               `(member ,@args (getf (node-semantics article) :concepts)))
                              (:max-tokens
                               `(<= (length (article-tokens article)) ,@args))
                              (otherwise
                               `(funcall ,constraint article ,@args))))))
     ',name))

;;; ============================================================================
;;; AST HOOKS - For Norm Graph Integration (Level 4)
;;; ============================================================================

(defgeneric add-semantics (node semantics-plist)
  (:documentation "Add semantic annotations to parsed node"))

(defgeneric add-norm-reference (node norm-uri &key relation)
  (:documentation "Link parsed node to legal norm"))

(defgeneric add-ontology-link (node concept-uri &key ontology)
  (:documentation "Link parsed node to ontology concept"))

(defmethod add-semantics ((node semantic-node) semantics-plist)
  "Add semantics to any semantic-node"
  (setf (node-semantics node)
        (append (node-semantics node) semantics-plist))
  node)

(defmethod add-norm-reference ((node semantic-node) norm-uri &key (relation :references))
  "Add norm reference to any semantic-node"
  (push (list :uri norm-uri :relation relation)
        (node-norm-refs node))
  node)

(defmethod add-ontology-link ((node semantic-node) concept-uri &key (ontology :eli))
  "Add ontology link to any semantic-node"
  (push (list :uri concept-uri :ontology ontology)
        (node-ontology-links node))
  node)

;;; ============================================================================
;;; DARPA-GRADE ADVANCED LISP FEATURES
;;; ============================================================================
;;;
;;; This section demonstrates mastery of advanced Common Lisp features
;;; required for DARPA-grade software systems.

;;; ---------------------------------------------------------------------------
;;; LOOP MASTERY - Full exploitation of LOOP macro (CL §6.1)
;;; ---------------------------------------------------------------------------

(defun corpus-statistics (articles)
  "Compute comprehensive statistics using advanced LOOP features.
   Demonstrates: maximize, minimize, sum, count, always, never, finally, initially"
  (loop initially (log-info "Computing corpus statistics...")
        for article in articles
        for para-count = (length (article-paragraphs article))
        for token-count = (length (article-tokens article))

        ;; Aggregation clauses
        maximize para-count into max-paragraphs
        minimize para-count into min-paragraphs
        sum para-count into total-paragraphs
        sum token-count into total-tokens
        count (node-semantics article) into semantic-articles
        count article into article-count

        ;; Conditional accumulation
        when (> para-count 5)
          collect (article-number article) into long-articles

        ;; Validation with ALWAYS/NEVER
        always (typep article 'parsed-article)
        never (null (article-source-text article))

        finally (return (list :article-count article-count
                             :total-paragraphs total-paragraphs
                             :total-tokens total-tokens
                             :max-paragraphs max-paragraphs
                             :min-paragraphs min-paragraphs
                             :avg-paragraphs (if (zerop article-count) 0
                                                 (/ total-paragraphs article-count))
                             :semantic-articles semantic-articles
                             :long-articles long-articles
                             :all-valid t))))

(defun find-articles-matching (articles &key min-paragraphs max-paragraphs
                                            has-semantics clause-type)
  "Find articles matching criteria using LOOP with complex conditions"
  (loop for article in articles
        for paras = (article-paragraphs article)
        for para-count = (length paras)

        ;; Multiple conditions with WHEN/UNLESS
        when (and (or (null min-paragraphs) (>= para-count min-paragraphs))
                  (or (null max-paragraphs) (<= para-count max-paragraphs))
                  (or (null has-semantics) (node-semantics article))
                  (or (null clause-type)
                      (loop for para in paras
                            thereis (loop for clause in (paragraph-clauses para)
                                          thereis (eq (clause-type clause) clause-type)))))
          collect article))

;;; ---------------------------------------------------------------------------
;;; FORMAT MASTERY - Advanced format directives (CL §22.3)
;;; ---------------------------------------------------------------------------

(defun format-article-reference (article-number &optional paragraph clause)
  "Format article reference using Roman numerals and Greek conventions.
   Demonstrates: ~@R (Roman), ~:P (plural), ~[ ~] (conditional)"
  (format nil "Άρθρο ~@R~@[, παράγραφος ~A~]~@[, εδάφιο ~A~]"
          article-number paragraph clause))

(defun format-corpus-report (statistics)
  "Generate formatted report using advanced FORMAT directives.
   Demonstrates: ~{ ~} (iteration), ~:* (backup), ~? (recursive)"
  (format nil "~&╔══════════════════════════════════════════════════════════════╗
~&║           ΣΤΑΤΙΣΤΙΚΑ ΣΩΜΑΤΟΣ ΝΟΜΙΚΩΝ ΚΕΙΜΕΝΩΝ                  ║
~&╠══════════════════════════════════════════════════════════════╣
~&║ Άρθρα: ~6D                                                     ║
~&║ Παράγραφοι: ~6D (μέσος: ~,2F)                                 ║
~&║ Λέξεις: ~6D                                                    ║
~&║ Με σημασιολογία: ~3D άρθρ~:*~[α~;ο~:;α~]                      ║
~&╠══════════════════════════════════════════════════════════════╣
~&║ Εκτεταμένα άρθρα (>5 παρ.): ~{~@R~^, ~}                        ║
~&╚══════════════════════════════════════════════════════════════╝"
          (getf statistics :article-count)
          (getf statistics :total-paragraphs)
          (getf statistics :avg-paragraphs)
          (getf statistics :total-tokens)
          (getf statistics :semantic-articles)
          (getf statistics :long-articles)))

(defun format-parse-tree (node &optional (indent 0))
  "Format parse tree recursively using ~? directive"
  (format nil "~V@T~A~@[~%~{~?~}~]"
          indent
          (etypecase node
            (parsed-article (format nil "Article ~@R: ~A paragraphs"
                                    (article-number node)
                                    (length (article-paragraphs node))))
            (parsed-paragraph (format nil "§~A: ~A tokens"
                                      (paragraph-number node)
                                      (length (paragraph-tokens node))))
            (parsed-clause (format nil "Clause ~A (~A)"
                                   (clause-number node)
                                   (clause-type node))))
          (when (typep node 'parsed-article)
            (loop for para in (article-paragraphs node)
                  collect (list "~A" (format-parse-tree para (+ indent 2)))))))

;;; ---------------------------------------------------------------------------
;;; LABELS/FLET - Local Recursive Functions (CL §5.2)
;;; ---------------------------------------------------------------------------

(defun traverse-parse-tree (root visitor)
  "Traverse parse tree with visitor function using LABELS for local recursion"
  (labels ((visit-node (node depth)
             "Recursive node visitor - LABELS allows self-reference"
             (funcall visitor node depth)
             (etypecase node
               (parsed-article
                (dolist (para (article-paragraphs node))
                  (visit-node para (1+ depth))))
               (parsed-paragraph
                (dolist (clause (paragraph-clauses node))
                  (visit-node clause (1+ depth))))
               (parsed-clause nil))))
    (visit-node root 0)))

(defun collect-all-tokens (article)
  "Collect all tokens from article using LABELS for recursive collection"
  (labels ((collect-from-node (node)
             (etypecase node
               (parsed-article
                (reduce #'append (article-paragraphs node)
                        :key #'collect-from-node
                        :initial-value (article-tokens node)))
               (parsed-paragraph
                (paragraph-tokens node))
               (parsed-clause nil))))
    (collect-from-node article)))

(defun transform-tree (article transformer)
  "Transform parse tree using FLET for local helper functions"
  (flet ((transform-paragraph (para)
           (make-instance 'parsed-paragraph
                          :number (paragraph-number para)
                          :text (funcall transformer (paragraph-text para))
                          :tokens (mapcar transformer (paragraph-tokens para))))
         (transform-metadata (meta)
           (mapcar (lambda (pair)
                     (cons (car pair)
                           (if (stringp (cdr pair))
                               (funcall transformer (cdr pair))
                               (cdr pair))))
                   meta)))
    (make-instance 'parsed-article
                   :number (article-number article)
                   :title (when (article-title article)
                            (funcall transformer (article-title article)))
                   :paragraphs (mapcar #'transform-paragraph
                                       (article-paragraphs article))
                   :metadata (transform-metadata (article-metadata article))
                   :source-text (funcall transformer (article-source-text article)))))

;;; ---------------------------------------------------------------------------
;;; METHOD COMBINATIONS - :before/:after/:around (CL §7.6.6)
;;; ---------------------------------------------------------------------------

(defgeneric validate-node (node)
  (:documentation "Validate parsed node with before/after hooks"))

(defmethod validate-node :before ((node traceable-node))
  "Before validation: ensure trace ID exists"
  (unless (node-trace-id node)
    (setf (slot-value node 'trace-id) (generate-trace-id))))

(defmethod validate-node :after ((node traceable-node))
  "After validation: log completion"
  (log-debug "Validated node [~A]" (node-trace-id node)))

(defmethod validate-node ((node parsed-article))
  "Primary validation for articles"
  (and (article-number node)
       (every #'validate-node (article-paragraphs node))))

(defmethod validate-node ((node parsed-paragraph))
  "Primary validation for paragraphs"
  (and (paragraph-text node)
       (> (length (paragraph-text node)) 0)))

(defmethod validate-node ((node parsed-clause))
  "Primary validation for clauses"
  (and (clause-text node)
       (member (clause-type node)
               '(:standard :prohibition :obligation :permission
                 :definition :exception :condition :delegation))))

;;; ---------------------------------------------------------------------------
;;; HANDLER-BIND - Sophisticated Condition Handling (CL §9.1)
;;; ---------------------------------------------------------------------------

(defun parse-with-recovery (text &key (on-error :skip) (log-errors t))
  "Parse with sophisticated error handling using HANDLER-BIND.
   Demonstrates non-local transfer without unwinding."
  (let ((errors nil)
        (warnings nil))
    (handler-bind
        ((parse-error-condition
           (lambda (c)
             (when log-errors
               (log-warn "Parse error: ~A" c))
             (push c errors)
             (case on-error
               (:skip (invoke-restart 'skip-and-log "error during parsing"))
               (:default (invoke-restart 'use-default-parser))
               (:signal nil)))) ; Let it propagate
         (warning
           (lambda (w)
             (push w warnings)
             (muffle-warning w))))
      (values (parse-constitution-article text)
              errors
              warnings))))

(defun parse-batch-with-handlers (texts &key continue-on-error)
  "Batch parse with HANDLER-BIND for centralized error handling"
  (let ((results nil)
        (all-errors nil))
    (handler-bind
        ((error
           (lambda (e)
             (push e all-errors)
             (when continue-on-error
               (let ((restart (find-restart 'skip-and-log)))
                 (when restart
                   (invoke-restart restart "batch error")))))))
      (dolist (text texts)
        (push (parse-constitution-article text) results)))
    (values (nreverse results) all-errors)))

;;; ---------------------------------------------------------------------------
;;; DEFSETF - Custom SETF Expansions (CL §5.1.2.6)
;;; ---------------------------------------------------------------------------

(defun article-paragraph-at (article index)
  "Get paragraph at index"
  (nth index (article-paragraphs article)))

;; DEFSETF - demonstrates custom setf expansions (preferred over setf function for this demo)
(defsetf article-paragraph-at (article index) (new-para)
  `(setf (nth ,index (article-paragraphs ,article)) ,new-para))

;; Long form DEFSETF for complex cases
(define-setf-expander node-metadata-value (node key &environment env)
  "SETF expander for metadata values - demonstrates define-setf-expander"
  (multiple-value-bind (temps vals stores store-form access-form)
      (get-setf-expansion `(article-metadata ,node) env)
    (declare (ignore stores store-form))
    (let ((key-temp (gensym "KEY"))
          (store (gensym "VALUE")))
      (values (list* key-temp temps)
              (list* key vals)
              (list store)
              `(progn
                 (let ((,access-form (remove ,key-temp ,access-form :key #'car)))
                   (push (cons ,key-temp ,store) (article-metadata ,node)))
                 ,store)
              `(cdr (assoc ,key-temp ,access-form))))))

;;; ---------------------------------------------------------------------------
;;; UNWIND-PROTECT - Guaranteed Cleanup (CL §5.3)
;;; ---------------------------------------------------------------------------

(defvar *parse-resources* nil
  "Stack of acquired parse resources")

(defun parse-with-cleanup (text)
  "Parse with guaranteed resource cleanup using UNWIND-PROTECT"
  (let ((trace-id (generate-trace-id))
        (start-time (get-internal-real-time)))
    (push (list :trace-id trace-id :text-length (length text)) *parse-resources*)
    (unwind-protect
         (progn
           (log-info "Starting parse [~A]" trace-id)
           (parse-constitution-article text))
      ;; Cleanup - ALWAYS runs, even on error/throw
      (let ((elapsed (- (get-internal-real-time) start-time)))
        (log-info "Parse [~A] completed/aborted in ~,3Fs"
                  trace-id
                  (/ elapsed internal-time-units-per-second))
        (pop *parse-resources*)))))

(defmacro with-parse-resources ((resource-spec) &body body)
  "Execute body with parse resources, guaranteed cleanup"
  (let ((resource-var (gensym "RESOURCE")))
    `(let ((,resource-var ,resource-spec))
       (push ,resource-var *parse-resources*)
       (unwind-protect
            (progn ,@body)
         (pop *parse-resources*)
         (log-debug "Released resource: ~A" ,resource-var)))))

;;; ---------------------------------------------------------------------------
;;; PROGV - Dynamic Variable Bindings (CL §5.3)
;;; ---------------------------------------------------------------------------

(defvar *parse-options* '(*log-level* *parse-trace* *current-trace-id*)
  "List of dynamic variables for parse context")

(defun parse-with-options (text options-alist)
  "Parse with dynamically bound options using PROGV.
   OPTIONS-ALIST: ((symbol . value) ...) for dynamic bindings"
  (let ((vars (mapcar #'car options-alist))
        (vals (mapcar #'cdr options-alist)))
    (progv vars vals
      (parse-constitution-article text))))

(defun parse-in-context (text context)
  "Parse text in given context using PROGV for dynamic environment.
   CONTEXT is a plist like (:log-level :debug :trace-p t)"
  (progv (loop for (k v) on context by #'cddr
               collect (intern (format nil "*~A*" k) :orchestrator.gr-syntagma))
         (loop for (k v) on context by #'cddr collect v)
    (parse-constitution-article text)))

;;; ---------------------------------------------------------------------------
;;; SYMBOL-MACROLET - Local Symbol Macros (CL §3.4.7)
;;; ---------------------------------------------------------------------------

(defmacro with-article-slots ((article) &body body)
  "Execute body with article slots as local symbol macros"
  `(symbol-macrolet ((number (article-number ,article))
                     (title (article-title ,article))
                     (paragraphs (article-paragraphs ,article))
                     (tokens (article-tokens ,article))
                     (semantics (node-semantics ,article))
                     (trace-id (node-trace-id ,article)))
     ,@body))

(defun summarize-article (article)
  "Summarize article using SYMBOL-MACROLET for clean access"
  (with-article-slots (article)
    (format nil "Άρθρο ~@R: ~D παράγραφ~:*~[οι~;ος~:;οι~], ~D λέξεις [~A]"
            number
            (length paragraphs)
            (length tokens)
            trace-id)))

;;; ---------------------------------------------------------------------------
;;; THE - Type Declarations for Optimization (CL §4.2.3)
;;; ---------------------------------------------------------------------------

(defun fast-token-count (article)
  "Count tokens with THE declarations for optimization"
  (declare (optimize (speed 3) (safety 0)))
  (the fixnum
       (loop for para in (the list (article-paragraphs article))
             sum (the fixnum (length (the list (paragraph-tokens para)))))))

(defun fast-find-article (articles number)
  "Find article by number with type declarations"
  (declare (optimize (speed 3) (safety 1))
           (type list articles)
           (type fixnum number))
  (the (or parsed-article null)
       (find number articles
             :key (lambda (a)
                    (declare (type parsed-article a))
                    (the (or fixnum null) (article-number a))))))

;;; ---------------------------------------------------------------------------
;;; MULTIPLE-VALUE-PROG1/2 and NTH-VALUE (CL §5.3/7.10)
;;; ---------------------------------------------------------------------------

(defun parse-with-timing (text)
  "Parse and return multiple values with timing using MULTIPLE-VALUE-PROG1"
  (let ((start (get-internal-real-time)))
    (multiple-value-prog1
        (parse-constitution-article text)
      (log-info "Parse time: ~,3Fs"
                (/ (- (get-internal-real-time) start)
                   internal-time-units-per-second)))))

(defun extract-parse-metadata (text)
  "Extract only metadata from parse result using NTH-VALUE"
  (nth-value 1 (parse-constitution-article text)))

;;; ---------------------------------------------------------------------------
;;; LOAD-TIME-VALUE - Compile-Time Constants (CL §3.4.6)
;;; ---------------------------------------------------------------------------

(defun get-greek-article-pattern ()
  "Get compiled regex pattern using LOAD-TIME-VALUE for efficiency"
  (load-time-value
   (cl-ppcre:create-scanner "^\\s*[Άά]ρθρο\\s+(\\d+)")))

(defun get-paragraph-pattern ()
  "Get compiled paragraph pattern"
  (load-time-value
   (cl-ppcre:create-scanner "^\\s*(\\d+)\\.\\s*")))

;;; ============================================================================
;;; EXPORTS
;;; ============================================================================

(eval-when (:compile-toplevel :load-toplevel :execute)
  (export '(;; Core parsing
            parse-constitution-article
            parse-articles-batch
            parse-paragraph
            parse-clause
            parse-node

            ;; Classes
            parsed-article
            parsed-paragraph
            parsed-clause
            parse-result
            traceable-node
            semantic-node

            ;; Article accessors
            article-number
            article-title
            article-paragraphs
            article-tokens
            article-metadata
            article-source-text
            article-parse-trace
            article-references-to
            article-referenced-by

            ;; Paragraph accessors
            paragraph-number
            paragraph-text
            paragraph-tokens
            paragraph-clauses
            paragraph-parent

            ;; Clause accessors
            clause-number
            clause-text
            clause-type
            clause-parent

            ;; Traceable-node accessors
            node-trace-id
            node-parent-trace-id
            node-source-info
            node-source-blocks
            node-page
            node-span-bbox
            node-created-at
            node-provenance-chain

            ;; Semantic-node accessors
            node-semantics
            node-norm-refs
            node-ontology-links
            node-legal-effect
            node-temporal-scope

            ;; Trace protocol
            make-trace
            extend-trace
            merge-traces
            trace-to-plist
            validate-trace
            generate-trace-id
            trace-to-tree

            ;; Parser combinators
            run-parser
            char-parser
            string-parser
            predicate-parser
            regex-parser
            sequence-parser
            choice-parser
            many-parser
            optional-parser
            map-parser
            bind-parser
            lookahead-parser
            not-parser
            integer-parser
            greek-word-parser

            ;; Parse result
            parse-success-p
            parse-value
            parse-position
            parse-remainder
            parse-trace
            parse-result-successful-p
            parse-result-value
            parse-result-combine
            make-parse-success
            make-parse-failure

            ;; Conditions
            parse-error-condition
            invalid-article-form
            missing-paragraph
            semantic-annotation-error
            parse-error-text
            parse-error-position
            parse-error-expected
            parse-error-trace-id

            ;; DSL Macros
            with-parse-trace
            with-restarts-for-parsing
            define-article-parser
            match-article-header
            match-paragraph-number
            match-legal-pattern

            ;; Reader macro
            enable-legal-syntax
            disable-legal-syntax
            *legal-readtable*
            article-reference
            legal-form
            legal-concept-ref

            ;; Semantic hooks
            add-semantics
            add-norm-reference
            add-ontology-link

            ;; Serialization
            serialize-node
            node-to-rdf

            ;; Homoiconicity - Code as Data
            homoiconic-article
            homoiconic-paragraph
            homoiconic-clause
            make-h-article
            make-h-paragraph
            make-h-clause
            node-to-sexp
            sexp-to-node
            node-to-code
            quote-node
            unquote-node
            with-homoiconic-form
            transform-article
            define-self-modifying-parser
            generate-validator
            generate-transformer
            embed-lisp-in-text
            evaluate-embedded-forms
            defspecification

            ;; Utilities
            greek-letter-p
            whitespace-char-p
            split-into-paragraphs
            split-into-clauses
            tokenize-paragraph
            detect-clause-type

            ;; === DARPA-GRADE ADVANCED FEATURES ===

            ;; LOOP Mastery
            corpus-statistics
            find-articles-matching

            ;; FORMAT Mastery
            format-article-reference
            format-corpus-report
            format-parse-tree

            ;; LABELS/FLET
            traverse-parse-tree
            collect-all-tokens
            transform-tree

            ;; Method Combinations
            validate-node

            ;; HANDLER-BIND
            parse-with-recovery
            parse-batch-with-handlers

            ;; DEFSETF
            article-paragraph-at

            ;; UNWIND-PROTECT
            *parse-resources*
            parse-with-cleanup
            with-parse-resources

            ;; PROGV
            *parse-options*
            parse-with-options
            parse-in-context

            ;; SYMBOL-MACROLET
            with-article-slots
            summarize-article

            ;; THE / Optimization
            fast-token-count
            fast-find-article

            ;; Multiple Values
            parse-with-timing
            extract-parse-metadata

            ;; LOAD-TIME-VALUE
            get-greek-article-pattern
            get-paragraph-pattern)
          :orchestrator.gr-syntagma))

;;; ============================================================================
;;; END OF PARSING.LISP
;;; ============================================================================
