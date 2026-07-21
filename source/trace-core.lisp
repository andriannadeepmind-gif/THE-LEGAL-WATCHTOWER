;;;; source/trace-core.lisp
;;;; ============================================================================
;;;; TRACE-CORE - Foundation Layer for Pipeline Traceability
;;;; ============================================================================
;;;;
;;;; ZERO-LEVEL TRUST FOUNDATION
;;;;
;;;; This module provides the traceability infrastructure for the entire
;;;; PDF legal parser pipeline. Every node, every transformation, every
;;;; output MUST carry trace information that links it back to:
;;;;
;;;;   1. Source PDF file
;;;;   2. Page number(s)
;;;;   3. Bounding box(es) on page
;;;;   4. Raw text before transformation
;;;;   5. Parent trace IDs (provenance chain)
;;;;
;;;; WITHOUT TRACE: A node is NOT VALID.
;;;; WITHOUT AUDIT: A pipeline is NOT TRUSTWORTHY.
;;;;
;;;; NSA-GRADE AUDITABILITY REQUIREMENTS:
;;;;   - Deterministic trace-id generation (reproducible)
;;;;   - Complete provenance chain (no orphan nodes)
;;;;   - Immutable trace records (no mutation after creation)
;;;;   - Serializable to plist/JSON for external audit
;;;;
;;;; ============================================================================
;;;; COMMON LISP FEATURES UTILIZED (≥90% TARGET)
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CONDITIONS & RESTARTS    │ trace-error hierarchy with recovery restarts │
;;;; │                          │ • USE-EMPTY-TRACE: fallback for debugging    │
;;;; │                          │ • SKIP-VALIDATION: non-fatal continue        │
;;;; │                          │ • PROVIDE-TRACE: caller substitution         │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CLOS (Classes)           │ trace-info class with typed slots            │
;;;; │                          │ • print-object specialization                │
;;;; │                          │ • describe-object integration                │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ GENERIC FUNCTIONS        │ Extensible layer-specific behavior           │
;;;; │                          │ • trace-summary                              │
;;;; │                          │ • trace-merge-strategy                       │
;;;; │                          │ • trace-validate (with eql specializers)     │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ EQL SPECIALIZERS         │ Method dispatch on layer keywords            │
;;;; │                          │ (defmethod trace-validate ((trace trace-info)│
;;;; │                          │                            (layer (eql :ast))│
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Rich return values for validation/stats      │
;;;; │                          │ • validate-trace-with-details                │
;;;; │                          │ • trace-statistics                           │
;;;; │                          │ • trace-registry-statistics                  │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MACROS (DSL)             │ Declarative trace construction               │
;;;; │                          │ • with-trace-context                         │
;;;; │                          │ • with-trace-restarts                        │
;;;; │                          │ • deftrace                                   │
;;;; │                          │ • quote-trace                                │
;;;; │                          │ • trace-transform                            │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ HOMOICONICITY            │ Code-as-data / data-as-code                  │
;;;; │                          │ • trace-to-data: trace → data-only plist     │
;;;; │                          │ • form-to-trace: Lisp form → trace           │
;;;; │                          │ • save-traces-to-file: audit as Lisp code    │
;;;; │                          │ • load-traces-from-file: just LOAD it        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ SPECIAL VARIABLES        │ Dynamic scope for context                    │
;;;; │                          │ • *trace-registry*                           │
;;;; │                          │ • *trace-context-file*                       │
;;;; │                          │ • *trace-context-pages*                      │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ READER/PRINTER           │ Readable trace serialization                 │
;;;; │                          │ • *print-readably* / *print-pretty*          │
;;;; │                          │ • read-from-string / prin1                   │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ TYPE DECLARATIONS        │ Slot types in CLOS class                     │
;;;; │                          │ • check-type for runtime validation          │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(defpackage :orchestrator.trace-core
  (:use :cl)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; TRACE ID GENERATION
   ;; ══════════════════════════════════════════════════════════════════
   #:generate-trace-id
   #:generate-deterministic-trace-id
   #:trace-id-p
   #:*trace-id-prefix*

   ;; ══════════════════════════════════════════════════════════════════
   ;; TRACE INFO CLASS & ACCESSORS
   ;; ══════════════════════════════════════════════════════════════════
   #:trace-info
   #:make-trace-info
   #:trace-id
   #:trace-source-file
   #:trace-pages
   #:trace-bboxes
   #:trace-raw-text
   #:trace-layout-ids
   #:trace-logical-ids
   #:trace-canonical-ids
   #:trace-ast-node-id
   #:trace-parents
   #:trace-timestamp
   #:trace-layer

   ;; ══════════════════════════════════════════════════════════════════
   ;; TRACE OPERATIONS
   ;; ══════════════════════════════════════════════════════════════════
   #:extend-trace
   #:bundle-traces
   #:trace-to-plist
   #:plist-to-trace

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONDITIONS (Full Lisp Condition System)
   ;; ══════════════════════════════════════════════════════════════════
   #:trace-error
   #:trace-error-message
   #:trace-error-trace-id
   #:trace-error-context
   #:trace-incomplete-error
   #:trace-incomplete-missing-fields
   #:trace-invalid-error
   #:trace-invalid-reason
   #:trace-not-found-error
   #:trace-not-found-id

   ;; ══════════════════════════════════════════════════════════════════
   ;; RESTARTS MACRO
   ;; ══════════════════════════════════════════════════════════════════
   #:with-trace-restarts

   ;; ══════════════════════════════════════════════════════════════════
   ;; VALIDATION
   ;; ══════════════════════════════════════════════════════════════════
   #:validate-trace-completeness
   #:trace-complete-p
   #:trace-valid-p
   #:validate-trace-with-details  ; Multiple values return

   ;; ══════════════════════════════════════════════════════════════════
   ;; PROVENANCE PATH
   ;; ══════════════════════════════════════════════════════════════════
   #:trace-provenance-path
   #:trace-full-lineage

   ;; ══════════════════════════════════════════════════════════════════
   ;; GENERIC FUNCTIONS (CLOS Extensibility)
   ;; ══════════════════════════════════════════════════════════════════
   #:trace-summary
   #:trace-merge-strategy
   #:trace-validate

   ;; ══════════════════════════════════════════════════════════════════
   ;; MULTIPLE VALUES - STATISTICS
   ;; ══════════════════════════════════════════════════════════════════
   #:trace-statistics
   #:trace-registry-statistics

   ;; ══════════════════════════════════════════════════════════════════
   ;; DSL MACROS (Declarative Trace Construction)
   ;; ══════════════════════════════════════════════════════════════════
   #:with-trace-context
   #:deftrace
   #:*trace-context-file*
   #:*trace-context-pages*

   ;; ══════════════════════════════════════════════════════════════════
   ;; DATA-ONLY PERSISTENCE ([re-review adv2-F3]: data ≠ executable Lisp)
   ;; ══════════════════════════════════════════════════════════════════
   ;; Ο εκτελέσιμος κύκλος (trace-to-form=(make-trace-info …)· form-to-trace/
   ;; read-trace-from-string/trace-to-readable-string/trace-transform=(eval …)·
   ;; load-traces-from-file=cl:load) ΔΙΑΓΡΑΦΗΚΕ/ΑΝΤΙΚΑΤΑΣΤΑΘΗΚΕ: το trace σειριοποιείται
   ;; ως data-only versioned plist (trace-to-data) και ανασυγκροτείται typed (%trace-decode)
   ;; μέσω της safe-read έδρας — καμία εκτέλεση κώδικα από trace δεδομένα.
   #:trace-to-data
   #:trace-decode-error
   #:save-traces-to-file
   #:load-traces-from-file
   #:quote-trace
   #:trace-describe

   ;; ══════════════════════════════════════════════════════════════════
   ;; REGISTRY (AUDIT TRAIL)
   ;; ══════════════════════════════════════════════════════════════════
   #:*trace-registry*
   #:register-trace
   #:lookup-trace
   #:clear-trace-registry
   #:export-trace-registry-to-plist))

(in-package :orchestrator.trace-core)

;; Defined (with defvar) further down but referenced by earlier default-arg
;; forms; declare special up-front so those functions compile cleanly.
(declaim (special *trace-registry*))

;;; ============================================================================
;;; CONDITIONS & RESTARTS (Full Lisp Condition System)
;;; ============================================================================
;;;
;;; Lisp's condition system allows:
;;;   - Separation of error detection from error handling
;;;   - Multiple recovery strategies via restarts
;;;   - Non-local control flow without stack unwinding
;;;
;;; Restarts provided:
;;;   USE-EMPTY-TRACE: Continue with empty trace (for debugging)
;;;   SKIP-VALIDATION: Skip validation and continue
;;;   PROVIDE-TRACE: Let caller provide replacement trace

(define-condition trace-error (error)
  ((message :initarg :message :reader trace-error-message)
   (trace-id :initarg :trace-id :reader trace-error-trace-id :initform nil)
   (context :initarg :context :reader trace-error-context :initform nil))
  (:report (lambda (c s)
             (format s "Trace Error~@[ (trace-id: ~A)~]~@[ [~A]~]: ~A"
                     (trace-error-trace-id c)
                     (trace-error-context c)
                     (trace-error-message c)))))

(define-condition trace-incomplete-error (trace-error)
  ((missing-fields :initarg :missing-fields :reader trace-incomplete-missing-fields))
  (:report (lambda (c s)
             (format s "Trace Incomplete~@[ (trace-id: ~A)~]: Missing fields: ~{~A~^, ~}"
                     (trace-error-trace-id c)
                     (trace-incomplete-missing-fields c)))))

(define-condition trace-invalid-error (trace-error)
  ((reason :initarg :reason :reader trace-invalid-reason :initform "unknown"))
  (:report (lambda (c s)
             (format s "Trace Invalid~@[ (trace-id: ~A)~]: ~A"
                     (trace-error-trace-id c)
                     (trace-invalid-reason c)))))

(define-condition trace-not-found-error (trace-error)
  ((requested-id :initarg :requested-id :reader trace-not-found-id))
  (:report (lambda (c s)
             (format s "Trace Not Found: ~A" (trace-not-found-id c)))))

;;; ============================================================================
;;; RESTART UTILITIES
;;; ============================================================================

(defmacro with-trace-restarts ((&key default-trace) &body body)
  "Execute BODY with standard trace-related restarts available.

   Restarts:
     USE-EMPTY-TRACE: Return a minimal empty trace
     SKIP-VALIDATION: Skip and return nil
     PROVIDE-TRACE: Use caller-provided trace

   Usage:
     (with-trace-restarts (:default-trace *fallback*)
       (validate-trace-completeness some-trace))"
  `(restart-case
       (progn ,@body)
     (use-empty-trace ()
       :report "Use an empty trace and continue"
       (make-trace-info :layer :error-recovery))
     (skip-validation ()
       :report "Skip validation and continue"
       nil)
     (provide-trace (new-trace)
       :report "Provide a replacement trace"
       ;; [re-review adv2-F3] Το παλιό :interactive έκανε (eval (read)) — αυθαίρετη
       ;; εκτέλεση από stdin. ΑΦΑΙΡΕΘΗΚΕ: το restart καλείται ΠΡΟΓΡΑΜΜΑΤΙΚΑ με trace-info
       ;; όρισμα (invoke-restart 'provide-trace <trace>)· καμία read-then-eval οδός.
       new-trace)
     ,@(when default-trace
         `((use-default ()
             :report ,(format nil "Use default trace")
             ,default-trace)))))

;;; ============================================================================
;;; TRACE ID GENERATION
;;; ============================================================================
;;;
;;; Two modes:
;;;   1. Deterministic: SHA-256 hash of seed (reproducible across runs)
;;;   2. Non-deterministic: Timestamp + counter (unique but not reproducible)
;;;
;;; For audit purposes, ALWAYS prefer deterministic when possible.

(defvar *trace-counter* 0
  "Counter for non-deterministic trace ID generation")

(defvar *trace-id-prefix* "TRC"
  "Prefix for all trace IDs")

(defun generate-deterministic-trace-id (seed)
  "Generate deterministic trace ID from seed string.

   Uses SHA-256 hash, truncated to 16 hex characters.
   REPRODUCIBLE: Same seed always produces same trace-id.

   Args:
     seed: String to hash (e.g., 'file.pdf:page:1:bbox:0,0,100,50')

   Returns:
     String: 'TRC-<16 hex chars>'"
  (check-type seed string)
  (let* ((octets (babel:string-to-octets seed :encoding :utf-8))
         (hash (ironclad:digest-sequence :sha256 octets))
         (hex (ironclad:byte-array-to-hex-string hash)))
    (format nil "~A-~A" *trace-id-prefix* (subseq hex 0 16))))

(defun generate-trace-id (&optional seed)
  "Generate trace ID.

   If SEED is provided: deterministic (reproducible)
   If SEED is NIL: non-deterministic (unique)

   Args:
     seed: Optional string for deterministic generation

   Returns:
     String trace ID"
  (if seed
      (generate-deterministic-trace-id seed)
      ;; Non-deterministic: timestamp + counter
      (let ((timestamp (get-universal-time))
            (counter (incf *trace-counter*)))
        (generate-deterministic-trace-id
         (format nil "~A:~A:~A" timestamp counter (random 1000000))))))

(defun trace-id-p (obj)
  "Check if OBJ is a valid trace ID string"
  (and (stringp obj)
       (> (length obj) 4)
       (string= (subseq obj 0 3) *trace-id-prefix*)))

;;; ============================================================================
;;; TRACE INFO CLASS
;;; ============================================================================
;;;
;;; Immutable record of traceability information.
;;; Once created, a trace-info should NOT be mutated.

(defclass trace-info ()
  ((trace-id
    :accessor trace-id
    :initarg :trace-id
    :type string
    :documentation "Unique identifier for this trace record")

   (source-file
    :accessor trace-source-file
    :initarg :source-file
    :initform nil
    :type (or null string pathname)
    :documentation "Path to source PDF file")

   (source-pages
    :accessor trace-pages
    :initarg :source-pages
    :initform '()
    :type list
    :documentation "List of page numbers (0-indexed) that contributed to this node")

   (source-bboxes
    :accessor trace-bboxes
    :initarg :source-bboxes
    :initform '()
    :type list
    :documentation "List of bounding boxes (x y width height) from source")

   (raw-text
    :accessor trace-raw-text
    :initarg :raw-text
    :initform nil
    :type (or null string)
    :documentation "Original raw text before any transformation")

   (layout-block-ids
    :accessor trace-layout-ids
    :initarg :layout-block-ids
    :initform '()
    :type list
    :documentation "IDs of layout blocks (Layer 1) that produced this")

   (logical-block-ids
    :accessor trace-logical-ids
    :initarg :logical-block-ids
    :initform '()
    :type list
    :documentation "IDs of logical blocks (Layer 2) that produced this")

   (canonical-block-ids
    :accessor trace-canonical-ids
    :initarg :canonical-block-ids
    :initform '()
    :type list
    :documentation "IDs of canonical blocks (Layer 3) that produced this")

   (ast-node-id
    :accessor trace-ast-node-id
    :initarg :ast-node-id
    :initform nil
    :type (or null string)
    :documentation "ID of AST node (Layer 4) if applicable")

   (parent-trace-ids
    :accessor trace-parents
    :initarg :parent-trace-ids
    :initform '()
    :type list
    :documentation "Trace IDs of parent nodes (provenance chain)")

   (timestamp
    :accessor trace-timestamp
    :initarg :timestamp
    :initform (get-universal-time)
    :type integer
    :documentation "Creation timestamp (universal time)")

   (layer
    :accessor trace-layer
    :initarg :layer
    :initform :unknown
    :type keyword
    :documentation "Pipeline layer: :layout, :logical, :canonical, :ast"))

  (:documentation
   "Immutable traceability record for pipeline nodes.

    Every node in the pipeline MUST have a trace-info attached.
    The trace provides:
    - Unique identification (trace-id)
    - Source provenance (file, pages, bboxes)
    - Transformation history (parent-trace-ids)
    - Layer identification

    IMMUTABILITY: Once created, do not modify. Create new trace instead."))

(defun make-trace-info (&key trace-id source-file source-pages source-bboxes
                             raw-text layout-block-ids logical-block-ids
                             canonical-block-ids ast-node-id parent-trace-ids
                             timestamp layer (register t))
  "Constructor for trace-info.

   If TRACE-ID is not provided, generates deterministic ID from content.
   [κύκλος-2] REGISTER (default T): auto-register στο audit registry. Το data-only
   %trace-decode το καλεί με :register NIL ⇒ ΚΑΜΙΑ παρενέργεια κατά το decode/validate
   (η εγγραφή στο registry γίνεται ΑΤΟΜΙΚΑ από το load-traces-from-file, ΜΟΝΟ αφού ΟΛΑ
   τα records επικυρωθούν — κανένα διπλό register, καμία μερική εγγραφή σε αποτυχία)."
  (let* ((computed-trace-id
           (or trace-id
               (generate-deterministic-trace-id
                (format nil "~A:~A:~A:~A"
                        (or source-file "unknown")
                        source-pages
                        source-bboxes
                        (or raw-text "")))))
         (trace (make-instance 'trace-info
                               :trace-id computed-trace-id
                               :source-file source-file
                               :source-pages (or source-pages '())
                               :source-bboxes (or source-bboxes '())
                               :raw-text raw-text
                               :layout-block-ids (or layout-block-ids '())
                               :logical-block-ids (or logical-block-ids '())
                               :canonical-block-ids (or canonical-block-ids '())
                               :ast-node-id ast-node-id
                               :parent-trace-ids (or parent-trace-ids '())
                               :timestamp (or timestamp (get-universal-time))
                               :layer (or layer :unknown))))
    ;; Auto-register for audit trail (εκτός αν :register NIL — data-only decode path)
    (when register (register-trace trace))
    trace))

(defmethod print-object ((trace trace-info) stream)
  (print-unreadable-object (trace stream :type t :identity nil)
    (format stream "~A ~A pages:~A"
            (trace-id trace)
            (trace-layer trace)
            (trace-pages trace))))

;;; ============================================================================
;;; TRACE OPERATIONS
;;; ============================================================================

(defun extend-trace (parent-trace &key new-layer layout-block-ids logical-block-ids
                                       canonical-block-ids ast-node-id
                                       additional-bboxes additional-raw-text)
  "Create new trace extending from parent trace.

   Used when transforming data from one layer to the next.
   The new trace inherits source info from parent and adds layer-specific IDs.

   Args:
     parent-trace: trace-info to extend from
     new-layer: keyword for new layer (:logical, :canonical, :ast)
     layout-block-ids: IDs from Layer 1 (if applicable)
     logical-block-ids: IDs from Layer 2 (if applicable)
     canonical-block-ids: IDs from Layer 3 (if applicable)
     ast-node-id: ID from Layer 4 (if applicable)
     additional-bboxes: New bboxes to add
     additional-raw-text: Additional raw text to append

   Returns:
     New trace-info with parent in provenance chain"
  (check-type parent-trace trace-info)
  (make-trace-info
   :source-file (trace-source-file parent-trace)
   :source-pages (trace-pages parent-trace)
   :source-bboxes (append (trace-bboxes parent-trace)
                          (or additional-bboxes '()))
   :raw-text (if additional-raw-text
                 (format nil "~@[~A~]~@[~%~A~]"
                         (trace-raw-text parent-trace)
                         additional-raw-text)
                 (trace-raw-text parent-trace))
   :layout-block-ids (or layout-block-ids (trace-layout-ids parent-trace))
   :logical-block-ids (or logical-block-ids (trace-logical-ids parent-trace))
   :canonical-block-ids (or canonical-block-ids (trace-canonical-ids parent-trace))
   :ast-node-id (or ast-node-id (trace-ast-node-id parent-trace))
   :parent-trace-ids (cons (trace-id parent-trace)
                           (trace-parents parent-trace))
   :layer (or new-layer (trace-layer parent-trace))))

(defun bundle-traces (traces &key layer)
  "Bundle multiple traces into one.

   Used when combining multiple source nodes into one target node.
   Merges all source info, deduplicates IDs.

   Args:
     traces: List of trace-info objects
     layer: Keyword for resulting layer

   Returns:
     New trace-info combining all inputs"
  (check-type traces list)
  (when (null traces)
    (error 'trace-error :message "Cannot bundle empty trace list"))

  (let ((all-pages '())
        (all-bboxes '())
        (all-raw-texts '())
        (all-layout-ids '())
        (all-logical-ids '())
        (all-canonical-ids '())
        (all-parent-ids '())
        (source-file nil))

    (dolist (trace traces)
      (check-type trace trace-info)
      ;; Use first source-file found
      (unless source-file
        (setf source-file (trace-source-file trace)))
      ;; Collect all data
      (setf all-pages (union all-pages (trace-pages trace)))
      (setf all-bboxes (append all-bboxes (trace-bboxes trace)))
      (when (trace-raw-text trace)
        (push (trace-raw-text trace) all-raw-texts))
      (setf all-layout-ids (union all-layout-ids (trace-layout-ids trace) :test #'equal))
      (setf all-logical-ids (union all-logical-ids (trace-logical-ids trace) :test #'equal))
      (setf all-canonical-ids (union all-canonical-ids (trace-canonical-ids trace) :test #'equal))
      ;; All bundled traces become parents
      (push (trace-id trace) all-parent-ids))

    (make-trace-info
     :source-file source-file
     :source-pages (sort (copy-list all-pages) #'<)
     :source-bboxes all-bboxes
     :raw-text (when all-raw-texts
                 (format nil "~{~A~^~%~}" (nreverse all-raw-texts)))
     :layout-block-ids all-layout-ids
     :logical-block-ids all-logical-ids
     :canonical-block-ids all-canonical-ids
     :parent-trace-ids (nreverse all-parent-ids)
     :layer (or layer :bundled))))

;;; ============================================================================
;;; SERIALIZATION
;;; ============================================================================

(defun trace-to-plist (trace)
  "Convert trace-info to plist for logging/export/audit.

   Returns:
     Plist representation suitable for JSON export"
  (check-type trace trace-info)
  (list :trace-id (trace-id trace)
        :source-file (when (trace-source-file trace)
                       (namestring (trace-source-file trace)))
        :pages (trace-pages trace)
        :bboxes (trace-bboxes trace)
        :raw-text (trace-raw-text trace)
        :layout-ids (trace-layout-ids trace)
        :logical-ids (trace-logical-ids trace)
        :canonical-ids (trace-canonical-ids trace)
        :ast-node-id (trace-ast-node-id trace)
        :parents (trace-parents trace)
        :timestamp (trace-timestamp trace)
        :layer (trace-layer trace)))

(defun plist-to-trace (plist)
  "Reconstruct trace-info from plist.

   Args:
     plist: Plist as produced by trace-to-plist

   Returns:
     trace-info instance"
  (make-trace-info
   :trace-id (getf plist :trace-id)
   :source-file (getf plist :source-file)
   :source-pages (getf plist :pages)
   :source-bboxes (getf plist :bboxes)
   :raw-text (getf plist :raw-text)
   :layout-block-ids (getf plist :layout-ids)
   :logical-block-ids (getf plist :logical-ids)
   :canonical-block-ids (getf plist :canonical-ids)
   :ast-node-id (getf plist :ast-node-id)
   :parent-trace-ids (getf plist :parents)
   :timestamp (getf plist :timestamp)
   :layer (getf plist :layer)))

;;; ============================================================================
;;; VALIDATION
;;; ============================================================================

(defun validate-trace-completeness (trace &key (layer nil) (strict t))
  "Validate that trace has all required fields for its layer.

   Args:
     trace: trace-info to validate
     layer: Expected layer (uses trace's layer if nil)
     strict: If T, signals error on failure; if NIL, returns nil

   Returns:
     T if valid

   Signals:
     trace-incomplete-error if missing required fields (when strict)"
  (check-type trace trace-info)
  (let ((check-layer (or layer (trace-layer trace)))
        (missing '()))

    ;; Universal requirements
    (unless (trace-id trace)
      (push :trace-id missing))
    (unless (trace-pages trace)
      (push :pages missing))
    (unless (trace-bboxes trace)
      (push :bboxes missing))

    ;; Layer-specific requirements
    (case check-layer
      (:layout
       (unless (trace-layout-ids trace)
         (push :layout-ids missing)))
      (:logical
       (unless (or (trace-layout-ids trace) (trace-logical-ids trace))
         (push :logical-ids missing)))
      (:canonical
       (unless (or (trace-logical-ids trace) (trace-canonical-ids trace))
         (push :canonical-ids missing)))
      (:ast
       (unless (trace-ast-node-id trace)
         (push :ast-node-id missing))))

    (if missing
        (if strict
            (error 'trace-incomplete-error
                   :message "Trace validation failed"
                   :trace-id (trace-id trace)
                   :missing-fields (nreverse missing))
            nil)
        t)))

(defun trace-complete-p (trace &key (layer nil))
  "Check if trace is complete (non-strict version of validate).

   Returns:
     T if complete, NIL otherwise"
  (validate-trace-completeness trace :layer layer :strict nil))

(defun trace-valid-p (trace)
  "Check if trace is structurally valid.

   Returns:
     T if valid structure, NIL otherwise"
  (and (typep trace 'trace-info)
       (trace-id-p (trace-id trace))
       (listp (trace-pages trace))
       (listp (trace-bboxes trace))))

;;; ============================================================================
;;; PROVENANCE PATH
;;; ============================================================================

(defun trace-provenance-path (trace)
  "Get the provenance path as list of trace IDs.

   Returns:
     List starting with this trace's ID, followed by all ancestors"
  (check-type trace trace-info)
  (cons (trace-id trace) (trace-parents trace)))

(defun trace-full-lineage (trace &key (registry *trace-registry*))
  "Get full lineage as list of trace-info objects.

   Looks up each parent trace in registry to build complete chain.

   Args:
     trace: Starting trace
     registry: Trace registry hash-table

   Returns:
     List of trace-info objects from current to oldest ancestor"
  (check-type trace trace-info)
  (let ((lineage (list trace)))
    (dolist (parent-id (trace-parents trace))
      (let ((parent (gethash parent-id registry)))
        (when parent
          (push parent lineage))))
    (nreverse lineage)))

;;; ============================================================================
;;; TRACE REGISTRY (AUDIT TRAIL)
;;; ============================================================================
;;;
;;; Global registry for all traces created during pipeline execution.
;;; Enables:
;;;   - Lookup of any trace by ID
;;;   - Complete audit trail
;;;   - Lineage reconstruction

(defvar *trace-registry* (make-hash-table :test #'equal)
  "Global registry mapping trace-id -> trace-info for audit")

(defun register-trace (trace)
  "Register trace in global registry.

   Called automatically by make-trace-info.

   Args:
     trace: trace-info to register

   Returns:
     The trace-id"
  (check-type trace trace-info)
  (setf (gethash (trace-id trace) *trace-registry*) trace)
  (trace-id trace))

(defun lookup-trace (trace-id)
  "Lookup trace by ID in registry.

   Args:
     trace-id: String trace ID

   Returns:
     trace-info or NIL if not found"
  (gethash trace-id *trace-registry*))

(defun clear-trace-registry ()
  "Clear all traces from registry.

   Call before processing new document to avoid cross-contamination."
  (clrhash *trace-registry*)
  (setf *trace-counter* 0)
  t)

;;; ============================================================================
;;; GENERIC FUNCTIONS (CLOS Extensibility)
;;; ============================================================================
;;;
;;; Generic functions allow future extension without modifying this file.
;;; New layer types can specialize these methods.

(defgeneric trace-summary (trace)
  (:documentation "Return human-readable summary of trace.
   Specialize for different trace types/layers."))

(defmethod trace-summary ((trace trace-info))
  "Default summary for trace-info"
  (format nil "[~A] ~A: ~D pages, ~D bboxes, ~D parents"
          (trace-layer trace)
          (trace-id trace)
          (length (trace-pages trace))
          (length (trace-bboxes trace))
          (length (trace-parents trace))))

(defgeneric trace-merge-strategy (trace1 trace2)
  (:documentation "Determine how to merge two traces.
   Returns: :UNION, :INTERSECTION, :FIRST, :SECOND, or custom strategy"))

(defmethod trace-merge-strategy ((t1 trace-info) (t2 trace-info))
  "Default merge strategy: union all fields"
  :union)

(defgeneric trace-validate (trace layer)
  (:documentation "Validate trace for specific layer.
   Specialize for layer-specific validation rules."))

(defmethod trace-validate ((trace trace-info) (layer (eql :layout)))
  "Validation for layout layer"
  (and (trace-pages trace)
       (trace-bboxes trace)
       (trace-layout-ids trace)))

(defmethod trace-validate ((trace trace-info) (layer (eql :logical)))
  "Validation for logical layer"
  (and (trace-pages trace)
       (or (trace-layout-ids trace) (trace-logical-ids trace))))

(defmethod trace-validate ((trace trace-info) (layer (eql :canonical)))
  "Validation for canonical layer"
  (and (trace-pages trace)
       (or (trace-logical-ids trace) (trace-canonical-ids trace))))

(defmethod trace-validate ((trace trace-info) (layer (eql :ast)))
  "Validation for AST layer"
  (and (trace-pages trace)
       (trace-ast-node-id trace)))

(defmethod trace-validate ((trace trace-info) layer)
  "Default validation: check basic structure"
  (declare (ignore layer))
  (trace-valid-p trace))

;;; ============================================================================
;;; MULTIPLE VALUES - Rich Returns
;;; ============================================================================

(defun validate-trace-with-details (trace &key (layer nil))
  "Validate trace and return detailed results.

   Returns: (values valid-p missing-fields warnings)
     valid-p: T if trace is valid for layer
     missing-fields: List of missing required fields
     warnings: List of non-critical issues"
  (check-type trace trace-info)
  (let ((check-layer (or layer (trace-layer trace)))
        (missing '())
        (warnings '()))

    ;; Universal requirements
    (unless (trace-id trace)
      (push :trace-id missing))
    (unless (trace-pages trace)
      (push :pages missing))
    (unless (trace-bboxes trace)
      (push :bboxes missing))

    ;; Layer-specific requirements
    (case check-layer
      (:layout
       (unless (trace-layout-ids trace)
         (push :layout-ids missing)))
      (:logical
       (unless (or (trace-layout-ids trace) (trace-logical-ids trace))
         (push :logical-ids missing)))
      (:canonical
       (unless (or (trace-logical-ids trace) (trace-canonical-ids trace))
         (push :canonical-ids missing)))
      (:ast
       (unless (trace-ast-node-id trace)
         (push :ast-node-id missing))))

    ;; Warnings (non-fatal)
    (unless (trace-raw-text trace)
      (push "No raw text preserved" warnings))
    (when (null (trace-parents trace))
      (push "No parent traces (root node?)" warnings))
    (when (> (length (trace-bboxes trace)) 100)
      (push "Large number of bboxes (>100)" warnings))

    (values (null missing)
            (nreverse missing)
            (nreverse warnings))))

(defun trace-statistics (trace)
  "Return statistics about trace.

   Returns: (values page-count bbox-count parent-count layer depth)"
  (check-type trace trace-info)
  (values (length (trace-pages trace))
          (length (trace-bboxes trace))
          (length (trace-parents trace))
          (trace-layer trace)
          (1+ (length (trace-parents trace)))))  ; Depth in tree

;;; ============================================================================
;;; DSL MACROS - Declarative Trace Construction
;;; ============================================================================

(defmacro with-trace-context ((source-file &key pages) &body body)
  "Establish trace context for a block of operations.

   All traces created within BODY will inherit SOURCE-FILE and PAGES.

   Usage:
     (with-trace-context (\"doc.pdf\" :pages '(0 1 2))
       (make-trace-info :layer :layout ...))"
  (let ((file-var (gensym "FILE"))
        (pages-var (gensym "PAGES")))
    `(let ((,file-var ,source-file)
           (,pages-var ,pages))
       (declare (special *trace-context-file* *trace-context-pages*))
       (let ((*trace-context-file* ,file-var)
             (*trace-context-pages* ,pages-var))
         ,@body))))

(defvar *trace-context-file* nil
  "Current source file in trace context")
(defvar *trace-context-pages* nil
  "Current pages in trace context")

(defmacro deftrace (name (&rest args) &body options)
  "Define a trace constructor with preset options.

   Usage:
     (deftrace layout-trace (block-ids bboxes)
       :layer :layout
       :require (:pages :bboxes))

   Generates a function (make-layout-trace block-ids bboxes &key ...)"
  (let ((layer (getf options :layer :unknown))
        (require (getf options :require '())))
    `(defun ,(intern (format nil "MAKE-~A" name)) (,@args &key source-file source-pages raw-text parent-trace-ids)
       ,(format nil "Create ~A trace.~%Required: ~A" name require)
       (make-trace-info
        :source-file (or source-file *trace-context-file*)
        :source-pages (or source-pages *trace-context-pages*)
        :raw-text raw-text
        :parent-trace-ids parent-trace-ids
        :layer ,layer
        ,@(case (first args)
            (block-ids `(:layout-block-ids ,args))
            (logical-ids `(:logical-block-ids ,args))
            (canonical-ids `(:canonical-block-ids ,args))
            (t nil))))))

;;; ============================================================================
;;; HOMOICONICITY - CODE AS DATA
;;; ============================================================================
;;;
;;; Lisp's homoiconicity allows traces to be:
;;;   - Represented as readable/writable Lisp forms
;;;   - Reconstructed from their printed representation
;;;   - Transformed programmatically
;;;   - Used as both data AND executable specifications
;;;
;;; This enables:
;;;   - Trace serialization to files as Lisp code
;;;   - Trace reconstruction by simply reading the file
;;;   - Trace transformation via macros
;;;   - Self-describing audit trails

;;; ============================================================================
;;; DATA-ONLY TRACE PERSISTENCE ([re-review adv2-F3]: data serialization ≠ executable Lisp)
;;; ============================================================================
;;; ΑΡΧΗ (εντολή δημιουργού): read ≠ eval· trace restore ≠ load. Το παλιό trace-to-form
;;; παρήγαγε `(make-trace-info …)` — ΕΚΤΕΛΕΣΙΜΟ constructor call — και το load-traces-from-file
;;; έκανε cl:load (εκτέλεση κώδικα από αρχείο). Πλέον το trace σειριοποιείται ως DATA-ONLY
;;; versioned plist, φορτώνεται μέσω της safe-read έδρας, και ανασυγκροτείται από typed
;;; decoder ΧΩΡΙΣ eval/load. Καμία δυνατότητα εκτέλεσης κώδικα από trace δεδομένα.

(defparameter +trace-schema+ :lawmax-trace/1
  "Version tag του data-only trace schema. Άλλαγη = ρητή έκδοση + migration.")

(defparameter +trace-data-keys+
  '(:trace-id :source-file :source-pages :source-bboxes :raw-text
    :layout-block-ids :logical-block-ids :canonical-block-ids
    :ast-node-id :parent-trace-ids :timestamp :layer)
  "Το ΚΛΕΙΣΤΟ σύνολο πεδίων ενός serialized trace. Άγνωστο/διπλό πεδίο ⇒ decode error.")

(defparameter +trace-max-list+ 1000000
  "Ανώτατο μήκος λίστας-πεδίου (DoS bound στο decode).")
(defparameter +trace-max-string+ (* 8 1024 1024)
  "Ανώτατο μήκος string-πεδίου (DoS bound στο decode).")

(define-condition trace-decode-error (trace-error)
  ((reason :initarg :reason :reader trace-decode-reason :initform "unknown"))
  (:report (lambda (c s) (format s "Trace decode error: ~A" (trace-decode-reason c)))))

(defun trace-to-data (trace)
  "DATA-ONLY αναπαράσταση: (+trace-schema+ :k v …). ΟΛΑ keywords/strings/numbers/lists —
   ΚΑΝΕΝΑ constructor-call, κανένα eval-bait. Αντικαθιστά το εκτελέσιμο trace-to-form."
  (check-type trace trace-info)
  (list +trace-schema+
        :trace-id (trace-id trace)
        :source-file (let ((f (trace-source-file trace))) (and f (namestring f)))
        :source-pages (trace-pages trace)
        :source-bboxes (trace-bboxes trace)
        :raw-text (trace-raw-text trace)
        :layout-block-ids (trace-layout-ids trace)
        :logical-block-ids (trace-logical-ids trace)
        :canonical-block-ids (trace-canonical-ids trace)
        :ast-node-id (trace-ast-node-id trace)
        :parent-trace-ids (trace-parents trace)
        :timestamp (trace-timestamp trace)
        :layer (trace-layer trace)))

(defun %trace-decode (data)
  "Typed decoder: validated DATA plist → trace-info ΧΩΡΙΣ eval. Απαιτεί ακριβές schema/
   version, γνωστά+μη-διπλά πεδία, σωστούς τύπους, όρια μεγέθους. Χτίζει μέσω make-trace-info
   (κανένα eval). Η είσοδος έρχεται από safe-read (data-only ⇒ μόνο keywords/strings/
   numbers/lists· κανένα constructor symbol δεν μπορεί να υπάρχει)."
  (unless (and (consp data) (eq (first data) +trace-schema+))
    (error 'trace-decode-error :reason
           (format nil "άγνωστο schema/version: ~S" (and (consp data) (first data)))))
  (let ((plist (rest data)))
    ;; [κύκλος-2] ΑΡΤΙΟ plist (αλλιώς getf «ολισθαίνει» — δομικό σφάλμα, όχι σιωπή).
    (unless (evenp (length plist))
      (error 'trace-decode-error :reason "μη-άρτιο plist (κακοσχηματισμένο)"))
    (let ((keys (loop for (k) on plist by #'cddr collect k)))
      (unless (every #'keywordp keys)
        (error 'trace-decode-error :reason "μη-keyword κλειδί"))
      (let ((unknown (set-difference keys +trace-data-keys+)))
        (when unknown (error 'trace-decode-error :reason (format nil "άγνωστα πεδία: ~S" unknown))))
      (unless (= (length keys) (length (remove-duplicates keys)))
        (error 'trace-decode-error :reason "διπλό πεδίο"))
      ;; [κύκλος-2 SECURITY] ΥΠΟΧΡΕΩΤΙΚΑ πεδία ταυτότητας/χρόνου/επιπέδου: αν λείπουν, ο
      ;; constructor θα ΚΑΤΑΣΚΕΥΑΖΕ νέο trace-id/timestamp/layer (forgery: αλλοιωμένο
      ;; persisted trace θα φορτωνόταν με ΝΕΑ ταυτότητα/χρόνο αντί να ΑΠΟΡΡΙΦΘΕΙ). Τώρα:
      ;; απόντα ⇒ trace-decode-error (καμία fabrication).
      (dolist (req '(:trace-id :timestamp :layer))
        (unless (member req keys)
          (error 'trace-decode-error :reason (format nil "λείπει υποχρεωτικό πεδίο ~S" req)))))
    (labels ((g (k) (getf plist k))
             (bstr (v n req)                         ; bounded string (req ⇒ υποχρεωτικό μη-κενό)
               (cond ((and (null v) (not req)) nil)
                     ((and (stringp v) (<= (length v) +trace-max-string+)
                           (or (not req) (plusp (length v)))) v)
                     (t (error 'trace-decode-error :reason (format nil "~A: όχι έγκυρο bounded string" n)))))
             (blist (v n elem-ok elem-desc)          ; bounded list + ΒΑΘΥΣ έλεγχος στοιχείου
               (when v
                 (unless (and (listp v) (<= (length v) +trace-max-list+))
                   (error 'trace-decode-error :reason (format nil "~A: όχι bounded list" n)))
                 (dolist (e v)
                   (unless (funcall elem-ok e)
                     (error 'trace-decode-error :reason (format nil "~A: στοιχείο όχι ~A (~S)" n elem-desc e)))))
               v)
             (num-p (x) (numberp x))
             (str-p (x) (stringp x))
             (numlist-p (x) (and (listp x) (every #'numberp x)))  ; bbox = λίστα αριθμών
             (kw (v n) (unless (keywordp v) (error 'trace-decode-error :reason (format nil "~A: όχι keyword" n))) v)
             (int (v n) (unless (integerp v) (error 'trace-decode-error :reason (format nil "~A: όχι integer" n))) v))
      (make-trace-info
       :register nil                                 ; ΚΑΜΙΑ παρενέργεια κατά το decode
       :trace-id (bstr (g :trace-id) :trace-id t)    ; ΥΠΟΧΡΕΩΤΙΚΟ μη-κενό
       :source-file (bstr (g :source-file) :source-file nil)
       :source-pages (blist (g :source-pages) :source-pages #'num-p "αριθμός")
       :source-bboxes (blist (g :source-bboxes) :source-bboxes #'numlist-p "λίστα αριθμών")
       :raw-text (bstr (g :raw-text) :raw-text nil)
       :layout-block-ids (blist (g :layout-block-ids) :layout-block-ids #'str-p "string")
       :logical-block-ids (blist (g :logical-block-ids) :logical-block-ids #'str-p "string")
       :canonical-block-ids (blist (g :canonical-block-ids) :canonical-block-ids #'str-p "string")
       :ast-node-id (bstr (g :ast-node-id) :ast-node-id nil)
       :parent-trace-ids (blist (g :parent-trace-ids) :parent-trace-ids #'str-p "string")
       :timestamp (int (g :timestamp) :timestamp)    ; ΥΠΟΧΡΕΩΤΙΚΟ
       :layer (kw (g :layer) :layer)))))             ; ΥΠΟΧΡΕΩΤΙΚΟ

;; [re-review adv2-F3] ΔΙΑΓΡΑΦΗΚΑΝ (0 runtime callers, RCE-shaped):
;;   form-to-trace         — (eval form): αυθαίρετη εκτέλεση από «δεδομένα»
;;   trace-to-readable-string — παρήγαγε string «to be READ and EVAL'd»
;;   read-trace-from-string   — (form-to-trace (read-from-string s)): read ΧΩΡΙΣ *read-eval*
;;                              nil ⇒ #. στο read + eval μετά = διπλό RCE
;; Η σειριοποίηση traces γίνεται DATA-ONLY μέσω save-traces-to-file (prin1 του trace-to-data)·
;; η επαναφορά μέσω load-traces-from-file (safe-read + %trace-decode· κανένα cl:load/eval).

(defun save-traces-to-file (filepath &key (registry *trace-registry*))
  "Save traces ως DATA-ONLY (ένα (+trace-schema+ …) plist ανά γραμμή, prin1 υπό
   standard-io-syntax + keyword package). [re-review adv2-F3] ΚΑΝΕΝΑΣ κώδικας: κανένα
   (make-trace-info)/(in-package)/(clear-trace-registry) — το αρχείο ΔΕΝ είναι πρόγραμμα,
   είναι δεδομένα. Επαναφορά ΜΟΝΟ μέσω load-traces-from-file (safe-read + typed decoder)."
  ;; [κύκλος-2] DETERMINISTIC (ταξινομημένο κατά trace-id) + ΑΤΟΜΙΚΗ ανθεκτική εγγραφή
  ;; (write-file-atomic: temp+fsync+rename — ποτέ μισο-γραμμένο/άδειο). Το παλιό maphash
  ;; έδινε μη-ντετερμινιστική σειρά· το :supersede δεν ήταν ατομικό/ανθεκτικό.
  (let ((entries '()))
    (maphash (lambda (id trace) (push (cons id trace) entries)) registry)
    (setf entries (sort entries #'string< :key #'car))
    (orchestrator.journal:write-file-atomic
     filepath
     (with-output-to-string (s)
       (dolist (e entries)                                       ; ΜΙΑ έδρα εγγραφής (data-to-string)
         (write-string (orchestrator.safe-read:data-to-string (trace-to-data (cdr e))) s)
         (terpri s)))))
  filepath)

(defun load-traces-from-file (filepath &key (on-existing :error))
  "Load traces ΜΕΣΩ της ΜΙΑΣ safe-read έδρας + typed decoder — ΚΑΝΕΝΑ cl:load/eval.
   [re-review adv2-F3] Κάθε γραμμή είναι data-only (+trace-schema+ …)· διαβάζεται με
   read-data-file-sequence (*read-eval* nil + #-deny + caps + %data-only-p) και
   ανασυγκροτείται typed (%trace-decode) — καμία εκτέλεση κώδικα από trace δεδομένα.

   [κύκλος-2] ΠΛΗΡΗΣ ΣΥΝΑΛΛΑΚΤΙΚΗ (transactional) επαναφορά:
     1. decode+validate ΟΛΑ (register nil ⇒ καμία παρενέργεια)·
     2. staging hash-table με ΑΠΟΡΡΙΨΗ duplicate trace-id ΜΕΣΑ στο αρχείο (κανένα σιωπηλό
        overwrite του ενός record από το άλλο)·
     3. collision policy vs ΥΠΑΡΧΟΝ *trace-registry* — ON-EXISTING:
          :error   (default) ⇒ trace-decode-error αν οποιοδήποτε id υπάρχει ήδη (τίποτα δεν μπαίνει)·
          :skip    ⇒ υπάρχοντα διατηρούνται, μπαίνουν μόνο τα νέα·
          :replace ⇒ υπάρχοντα αντικαθίστανται·
     4. ΑΤΟΜΙΚΗ commit ΜΟΝΟ αφού περάσουν όλοι οι έλεγχοι (όλα ή τίποτα).
   Επιστρέφει το πλήθος των traces που γράφτηκαν στο registry."
  (check-type on-existing (member :error :skip :replace))
  (multiple-value-bind (forms status)
      (orchestrator.safe-read:read-data-file-sequence filepath)
    (unless (member status '(:ok :empty))
      (error 'trace-decode-error :reason
             (format nil "μη αναγνώσιμο trace αρχείο (safe-read: ~A)" status)))
    ;; 1. decode+validate ΟΛΑ (καμία παρενέργεια)
    (let ((decoded (mapcar #'%trace-decode forms))
          (staging (make-hash-table :test 'equal)))
      ;; 2. staging + απόρριψη duplicate id ΜΕΣΑ στο αρχείο
      (dolist (tr decoded)
        (let ((id (trace-id tr)))
          (when (gethash id staging)
            (error 'trace-decode-error :reason
                   (format nil "διπλό trace-id ΜΕΣΑ στο αρχείο: ~S" id)))
          (setf (gethash id staging) tr)))
      ;; 3. collision policy vs υπάρχον registry — ΠΡΙΝ κάθε commit (fail-closed για :error)
      (when (eq on-existing :error)
        (maphash (lambda (id tr) (declare (ignore tr))
                   (when (nth-value 1 (gethash id *trace-registry*))
                     (error 'trace-decode-error :reason
                            (format nil "trace-id υπάρχει ήδη στο registry: ~S (:on-existing :error)" id))))
                 staging))
      ;; 4. ΑΤΟΜΙΚΗ commit (όλοι οι έλεγχοι πέρασαν)· :skip παρακάμπτει υπάρχοντα
      (let ((committed 0))
        (maphash (lambda (id tr)
                   (unless (and (eq on-existing :skip)
                                (nth-value 1 (gethash id *trace-registry*)))
                     (register-trace tr)
                     (incf committed)))
                 staging)
        committed))))

(defmacro quote-trace (trace-expr)
  "Capture a trace expression as data without evaluating.

   Usage:
     (quote-trace (make-trace-info :layer :layout ...))
   Returns the unevaluated form."
  `',trace-expr)

;; [re-review adv2-F3] trace-transform ΔΙΑΓΡΑΦΗΚΕ: 0 callers + βασιζόταν στο
;; διαγραμμένο form-to-trace (eval). Homoiconic transforms σε trusted forms γίνονται
;; απευθείας μέσω trace-to-data + typed decoder, όχι eval.

;;; ============================================================================
;;; SELF-DESCRIBING TRACES
;;; ============================================================================

(defun trace-describe (trace &optional (stream *standard-output*))
  "Print a self-describing representation of trace.

   Includes both human-readable summary AND reconstructable form."
  (check-type trace trace-info)
  (format stream "~&;;; === TRACE: ~A ===~%" (trace-id trace))
  (format stream ";;; Layer: ~A~%" (trace-layer trace))
  (format stream ";;; Pages: ~A~%" (trace-pages trace))
  (format stream ";;; Parents: ~D~%" (length (trace-parents trace)))
  (format stream ";;; Bboxes: ~D~%" (length (trace-bboxes trace)))
  (format stream ";;;~%")
  (format stream ";;; Data representation:~%")
  (let ((*print-pretty* t)
        (*print-right-margin* 80))
    (pprint (trace-to-data trace) stream))
  (format stream "~%;;; === END TRACE ===~%")
  trace)

(defmethod describe-object ((trace trace-info) stream)
  "CLOS integration: (describe trace) shows full info"
  (trace-describe trace stream))

;;; ============================================================================
;;; AUDIT EXPORT
;;; ============================================================================

(defun export-trace-registry-to-plist ()
  "Export entire trace registry as plist for audit.

   Returns:
     Plist with :trace-count, :traces (list of trace plists)"
  (let ((traces '()))
    (maphash (lambda (id trace)
               (declare (ignore id))
               (push (trace-to-plist trace) traces))
             *trace-registry*)
    (list :trace-count (hash-table-count *trace-registry*)
          :export-timestamp (get-universal-time)
          :traces (nreverse traces))))

(defun trace-registry-statistics ()
  "Return statistics about the trace registry.

   Returns: (values total-count by-layer-counts max-depth orphan-count)"
  (let ((by-layer (make-hash-table))
        (max-depth 0)
        (orphan-count 0))
    (maphash (lambda (id trace)
               (declare (ignore id))
               (incf (gethash (trace-layer trace) by-layer 0))
               (let ((depth (1+ (length (trace-parents trace)))))
                 (when (> depth max-depth)
                   (setf max-depth depth)))
               (when (null (trace-parents trace))
                 (incf orphan-count)))
             *trace-registry*)
    (values (hash-table-count *trace-registry*)
            (let ((alist '()))
              (maphash (lambda (k v) (push (cons k v) alist)) by-layer)
              alist)
            max-depth
            orphan-count)))

;;; ============================================================================
;;; END OF TRACE-CORE.LISP
;;; ============================================================================
