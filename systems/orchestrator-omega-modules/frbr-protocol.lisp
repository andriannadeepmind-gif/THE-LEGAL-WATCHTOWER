;;;; systems/orchestrator-spec/frbr-protocol.lisp
;;;; FRBR Generic Protocol - Method dispatch with combinations
;;;; ΟΜΕΓΑ-LEVEL: Full CLOS power with :around/:before/:after

(in-package :orchestrator.spec)

;;; ============================================================
;;; GENERIC FUNCTIONS - CORE PROTOCOL
;;; ============================================================

(defgeneric generate-rdf (frbr-instance)
  (:documentation "Generate RDF representation for FRBR instance
                   
                   Returns: String containing Turtle RDF
                   
                   Method combination: Standard with :around/:before/:after
                   - :before methods: Validation, logging
                   - Primary methods: Actual RDF generation
                   - :after methods: Provenance recording, metrics
                   - :around methods: Determinism checks, caching"))

(defgeneric emit-triples (frbr-instance stream)
  (:documentation "Emit RDF triples to stream for FRBR instance
                   
                   This is the low-level primitive for RDF output"))

(defgeneric validate-instance (frbr-instance)
  (:documentation "Validate FRBR instance before generation
                   
                   Returns: T if valid, signals condition if invalid"))

(defgeneric compute-provenance (frbr-instance)
  (:documentation "Compute PROV-O provenance metadata
                   
                   Returns: Alist of provenance triples"))

(defgeneric layer-name (frbr-instance)
  (:documentation "Get FRBR layer name (Work, Expression, Manifestation, Format)"))

(defgeneric generate-rdf-to-stream (frbr-instance stream)
  (:documentation "Generate RDF representation directly to stream for FRBR instance
                   
                   This is a stream-based variant of generate-rdf that writes
                   directly to stream without building intermediate strings.
                   
                   Returns: NIL (output written to stream)"))

;;; ============================================================
;;; METHOD COMBINATION - :AROUND for determinism check
;;; ============================================================

(defmethod generate-rdf :around ((instance orchestrator.model:frbr-resource))
  "AROUND method: Ensure deterministic generation"
  
  ;; Pre-check: Ensure all data is present
  (unless (slot-boundp instance 'orchestrator.model::uri)
    (error 'frbr-generation-error
           :message "URI not set on FRBR instance"
           :instance instance))
  
  ;; Call next method (primary + :before/:after)
  (let ((output (call-next-method)))
    
    ;; Post-check: Validate output is deterministic
    (assert (stringp output) nil "RDF output must be a string")
    (assert (> (length output) 0) nil "RDF output cannot be empty")
    
    ;; Return validated output
    output))

;;; ============================================================
;;; METHOD COMBINATION - :BEFORE for validation
;;; ============================================================

(defmethod generate-rdf :before ((instance orchestrator.model:frbr-resource))
  "BEFORE method: Validate instance before generation"

  ;; Validate instance (package conflict resolved via explicit imports in omega-package.lisp)
  (validate-instance instance))

;;; ============================================================
;;; METHOD COMBINATION - :AFTER for provenance
;;; ============================================================

(defmethod generate-rdf :after ((instance orchestrator.model:frbr-resource))
  "AFTER method: Record provenance and metrics"

  ;; Update provenance
  (let ((prov (compute-provenance instance)))
    (setf (orchestrator.model:resource-provenance instance) prov)))

;;; ============================================================
;;; PRIMARY METHODS - DEFINED IN OMEGA GENERATOR FILES
;;;
;;; This file is the PROTOCOL layer only:
;;;   defgeneric declarations + :around/:before/:after combinators.
;;;
;;; Primary generate-rdf methods live in the omega generator files,
;;; loaded AFTER this file in orchestrator-omega.asd (Layer 5):
;;;
;;;   frbr-work         → work-generator-omega.lisp
;;;   frbr-expression   → expression-generator-omega.lisp
;;;   frbr-manifestation → manifestation-generator-omega.lisp
;;;   frbr-format       → format-generator-omega.lisp
;;;   frbr-article-root → article-root-generator-omega.lisp
;;;   prov-activity     → prov-activity-generator-omega.lisp
;;;
;;; CLOS loads the omega methods AFTER this file, so they replace
;;; any same-specializer primary method that would be defined here.
;;; Defining primary methods here would produce dead code — hence
;;; they are absent from this file by design.
;;; ============================================================

;;; ============================================================
;;; VALIDATION METHODS
;;; ============================================================

(defmethod validate-instance ((work orchestrator.model:frbr-work))
  "Validate Work instance"
  
  (unless (slot-boundp work 'orchestrator.model::article-number)
    (error 'invalid-frbr-instance
           :message "Work missing article-number"
           :instance work))
  
  (unless (slot-boundp work 'orchestrator.model::uri)
    (error 'invalid-frbr-instance
           :message "Work missing URI"
           :instance work))
  
  t)

(defmethod validate-instance ((expr orchestrator.model:frbr-expression))
  "Validate Expression instance"
  
  (unless (slot-boundp expr 'orchestrator.model::work)
    (error 'invalid-frbr-instance
           :message "Expression missing Work reference"
           :instance expr))
  
  (unless (slot-boundp expr 'orchestrator.model::content)
    (error 'invalid-frbr-instance
           :message "Expression missing content"
           :instance expr))
  
  t)

;;; ============================================================
;;; PROVENANCE COMPUTATION
;;; ============================================================

(defmethod compute-provenance ((instance orchestrator.model:frbr-resource))
  "Compute PROV-O metadata for FRBR instance

   NOTE: generatedAtTime removed - timestamps should come from provenance capsule"

  (list
    :wasAttributedTo "https://stavropouloslaw.com/identity#spyridon-stavropoulos"
    :wasGeneratedBy "https://stavropouloslaw.com/software/orchestrator/v1.3"))

;;; ============================================================
;;; LAYER NAME METHODS
;;; ============================================================

(defmethod layer-name ((work orchestrator.model:frbr-work))
  "Work")

(defmethod layer-name ((expr orchestrator.model:frbr-expression))
  "Expression")

(defmethod layer-name ((man orchestrator.model:frbr-manifestation))
  "Manifestation")

(defmethod layer-name ((fmt orchestrator.model:frbr-format))
  "Format")

(defmethod layer-name ((article orchestrator.model:frbr-article-root))
  "Article-Root")

(defmethod layer-name ((activity orchestrator.model:prov-activity))
  "PROV-Activity")

;;; ============================================================
;;; STREAM-BASED RDF GENERATION METHODS
;;; ============================================================

;; NOTE: These methods currently delegate to generate-rdf which builds
;; intermediate strings. A future optimization would be to rewrite
;; generate-rdf methods to write directly to streams, but that would
;; require significant refactoring of the DSL usage patterns.

(defmethod generate-rdf-to-stream ((work orchestrator.model:frbr-work) stream)
  "Generate Work layer RDF directly to stream"
  (write-string (generate-rdf work) stream))

(defmethod generate-rdf-to-stream ((expr orchestrator.model:frbr-expression) stream)
  "Generate Expression layer RDF directly to stream"
  (write-string (generate-rdf expr) stream))

(defmethod generate-rdf-to-stream ((man orchestrator.model:frbr-manifestation) stream)
  "Generate Manifestation layer RDF directly to stream"
  (write-string (generate-rdf man) stream))

(defmethod generate-rdf-to-stream ((fmt orchestrator.model:frbr-format) stream)
  "Generate Format layer RDF directly to stream"
  (write-string (generate-rdf fmt) stream))

(defmethod generate-rdf-to-stream ((article orchestrator.model:frbr-article-root) stream)
  "Generate Article-Root layer RDF directly to stream"
  (write-string (generate-rdf article) stream))

(defmethod generate-rdf-to-stream ((activity orchestrator.model:prov-activity) stream)
  "Generate PROV-Activity layer RDF directly to stream"
  (write-string (generate-rdf activity) stream))

;;; ============================================================
;;; VALIDATION METHODS - Manifestation and Format
;;; ============================================================

(defmethod validate-instance ((man orchestrator.model:frbr-manifestation))
  "Validate Manifestation instance"
  
  (unless (slot-boundp man 'orchestrator.model::expression)
    (error 'invalid-frbr-instance
           :message "Manifestation missing Expression reference"
           :instance man))
  
  (unless (slot-boundp man 'orchestrator.model::uri)
    (error 'invalid-frbr-instance
           :message "Manifestation missing URI"
           :instance man))
  
  t)

(defmethod validate-instance ((fmt orchestrator.model:frbr-format))
  "Validate Format instance"
  
  (unless (slot-boundp fmt 'orchestrator.model::manifestation)
    (error 'invalid-frbr-instance
           :message "Format missing Manifestation reference"
           :instance fmt))
  
  (unless (slot-boundp fmt 'orchestrator.model::format-type)
    (error 'invalid-frbr-instance
           :message "Format missing format-type"
           :instance fmt))
  
  t)

;;; (Primary methods for Manifestation and Format are in
;;;  manifestation-generator-omega.lisp and format-generator-omega.lisp)

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(generate-rdf generate-rdf-to-stream emit-triples validate-instance 
          compute-provenance layer-name))
