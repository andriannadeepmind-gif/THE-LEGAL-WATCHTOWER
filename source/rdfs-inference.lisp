;;;; source/rdfs-inference.lisp
;;;; ============================================================================
;;;; RDFS INFERENCE ENGINE - Pure Common Lisp Semantic Reasoning
;;;; ============================================================================
;;;;
;;;; Implements RDFS (RDF Schema) entailment rules for semantic inference:
;;;; - rdfs:subClassOf transitivity
;;;; - rdfs:subPropertyOf transitivity
;;;; - rdfs:domain / rdfs:range inference
;;;; - rdf:type propagation
;;;;
;;;; ARCHITECTURE:
;;;; ┌─────────────────────────────────────────────────────────────────────┐
;;;; │                    RDFS INFERENCE ENGINE                            │
;;;; ├─────────────────────────────────────────────────────────────────────┤
;;;; │                                                                     │
;;;; │   RDF Triples ────▶ Forward Chaining ────▶ Inferred Triples        │
;;;; │                            │                                        │
;;;; │                     ┌──────┴──────┐                                │
;;;; │                     │ RDFS Rules  │                                │
;;;; │                     ├─────────────┤                                │
;;;; │                     │ rdfs2: domain                                │
;;;; │                     │ rdfs3: range                                 │
;;;; │                     │ rdfs5: subPropertyOf                         │
;;;; │                     │ rdfs7: property inheritance                  │
;;;; │                     │ rdfs9: subClassOf                            │
;;;; │                     │ rdfs11: subClassOf transitivity              │
;;;; │                     └─────────────┘                                │
;;;; │                                                                     │
;;;; └─────────────────────────────────────────────────────────────────────┘
;;;;
;;;; DARPA-GRADE: Pure Lisp, no external reasoner, deterministic inference.
;;;; ============================================================================

(defpackage :orchestrator.rdfs-inference
  (:use :cl)
  (:local-nicknames (:alex :alexandria))
  (:export
   ;; Knowledge base
   #:make-knowledge-base
   #:kb-add-triple
   #:kb-add-triples
   #:kb-query
   #:kb-query-pattern
   #:kb-all-triples
   #:kb-size
   ;; Inference
   #:run-inference
   #:infer-closure
   #:apply-rdfs-rules
   ;; RDFS vocabulary
   #:+rdf-type+
   #:+rdfs-subclass-of+
   #:+rdfs-subproperty-of+
   #:+rdfs-domain+
   #:+rdfs-range+
   #:+rdfs-class+
   #:+rdfs-resource+
   #:+rdfs-literal+
   ;; Utilities
   #:triple
   #:triple-subject
   #:triple-predicate
   #:triple-object
   #:uri
   #:literal
   #:literal-value
   #:literal-datatype
   #:literal-language))

(in-package :orchestrator.rdfs-inference)

;;; ============================================================================
;;; RDF/RDFS VOCABULARY CONSTANTS
;;; ============================================================================

;; Use alexandria:define-constant to handle SBCL's strict defconstant semantics
(alex:define-constant +rdf+ "http://www.w3.org/1999/02/22-rdf-syntax-ns#" :test #'equal)
(alex:define-constant +rdfs+ "http://www.w3.org/2000/01/rdf-schema#" :test #'equal)
(alex:define-constant +xsd+ "http://www.w3.org/2001/XMLSchema#" :test #'equal)

(alex:define-constant +rdf-type+ (concatenate 'string +rdf+ "type") :test #'equal)
(alex:define-constant +rdf-property+ (concatenate 'string +rdf+ "Property") :test #'equal)

(alex:define-constant +rdfs-class+ (concatenate 'string +rdfs+ "Class") :test #'equal)
(alex:define-constant +rdfs-resource+ (concatenate 'string +rdfs+ "Resource") :test #'equal)
(alex:define-constant +rdfs-literal+ (concatenate 'string +rdfs+ "Literal") :test #'equal)
(alex:define-constant +rdfs-subclass-of+ (concatenate 'string +rdfs+ "subClassOf") :test #'equal)
(alex:define-constant +rdfs-subproperty-of+ (concatenate 'string +rdfs+ "subPropertyOf") :test #'equal)
(alex:define-constant +rdfs-domain+ (concatenate 'string +rdfs+ "domain") :test #'equal)
(alex:define-constant +rdfs-range+ (concatenate 'string +rdfs+ "range") :test #'equal)
(alex:define-constant +rdfs-label+ (concatenate 'string +rdfs+ "label") :test #'equal)
(alex:define-constant +rdfs-comment+ (concatenate 'string +rdfs+ "comment") :test #'equal)

;;; ============================================================================
;;; DATA STRUCTURES
;;; ============================================================================

(defstruct triple
  "RDF triple (subject, predicate, object)"
  (subject nil :type (or string symbol))
  (predicate nil :type (or string symbol))
  (object nil :type t))  ; Can be URI or literal

(defstruct literal
  "RDF literal value"
  (value nil :type t)
  (datatype nil :type (or null string))
  (language nil :type (or null string)))

(defstruct uri
  "RDF URI reference"
  (value nil :type string))

(defstruct knowledge-base
  "RDF knowledge base with indexing"
  ;; Primary storage: set of triples
  (triples (make-hash-table :test 'equal) :type hash-table)
  ;; Indexes for fast lookup
  (spo-index (make-hash-table :test 'equal) :type hash-table)  ; subject → triples
  (pos-index (make-hash-table :test 'equal) :type hash-table)  ; predicate → triples
  (osp-index (make-hash-table :test 'equal) :type hash-table)  ; object → triples
  ;; Inference state
  (inferred-p nil :type boolean)
  (inference-count 0 :type integer))

;;; ============================================================================
;;; KNOWLEDGE BASE OPERATIONS
;;; ============================================================================

(defun triple-key (triple)
  "Generate unique key for triple"
  (list (normalize-term (triple-subject triple))
        (normalize-term (triple-predicate triple))
        (normalize-term (triple-object triple))))

(defun normalize-term (term)
  "Normalize RDF term to string for hashing"
  (etypecase term
    (string term)
    (symbol (symbol-name term))
    (uri (uri-value term))
    (literal (format nil "\"~A\"~@[^^~A~]~@[@~A~]"
                     (literal-value term)
                     (literal-datatype term)
                     (literal-language term)))
    (number (format nil "~A" term))))

(defun kb-add-triple (kb subject predicate object &key inferred)
  "Add triple to knowledge base

   Args:
     kb: knowledge-base
     subject: Subject URI or symbol
     predicate: Predicate URI or symbol
     object: Object (URI, literal, or symbol)
     inferred: If T, mark as inferred (not asserted)

   Returns:
     T if triple was new, NIL if already existed"

  (let* ((triple (make-triple :subject subject
                              :predicate predicate
                              :object object))
         (key (triple-key triple)))

    ;; Check if already exists
    (when (gethash key (knowledge-base-triples kb))
      (return-from kb-add-triple nil))

    ;; Add to main storage
    (setf (gethash key (knowledge-base-triples kb)) triple)

    ;; Update indexes
    (push triple (gethash (normalize-term subject) (knowledge-base-spo-index kb)))
    (push triple (gethash (normalize-term predicate) (knowledge-base-pos-index kb)))
    (push triple (gethash (normalize-term object) (knowledge-base-osp-index kb)))

    ;; Track inference
    (when inferred
      (incf (knowledge-base-inference-count kb)))

    t))

(defun kb-add-triples (kb triples)
  "Add multiple triples to knowledge base

   Args:
     kb: knowledge-base
     triples: List of (subject predicate object) lists

   Returns:
     Number of new triples added"

  (let ((count 0))
    (dolist (triple triples)
      (when (apply #'kb-add-triple kb triple)
        (incf count)))
    count))

(defun kb-query (kb subject predicate object)
  "Query knowledge base for matching triples

   Use NIL as wildcard for any position.

   Args:
     kb: knowledge-base
     subject: Subject to match (or NIL for any)
     predicate: Predicate to match (or NIL for any)
     object: Object to match (or NIL for any)

   Returns:
     List of matching triples"

  (cond
    ;; All specified - direct lookup
    ((and subject predicate object)
     (let ((key (list (normalize-term subject)
                      (normalize-term predicate)
                      (normalize-term object))))
       (alexandria:if-let (triple (gethash key (knowledge-base-triples kb)))
         (list triple)
         nil)))

    ;; Subject specified - use SPO index
    ((and subject (not predicate) (not object))
     (gethash (normalize-term subject) (knowledge-base-spo-index kb)))

    ;; Predicate specified - use POS index
    ((and predicate (not subject) (not object))
     (gethash (normalize-term predicate) (knowledge-base-pos-index kb)))

    ;; Object specified - use OSP index
    ((and object (not subject) (not predicate))
     (gethash (normalize-term object) (knowledge-base-osp-index kb)))

    ;; Partial match - filter from index
    (t
     (let ((candidates
             (cond
               (subject (gethash (normalize-term subject) (knowledge-base-spo-index kb)))
               (predicate (gethash (normalize-term predicate) (knowledge-base-pos-index kb)))
               (object (gethash (normalize-term object) (knowledge-base-osp-index kb)))
               (t (kb-all-triples kb)))))
       (remove-if-not
        (lambda (triple)
          (and (or (null subject)
                   (equal (normalize-term subject)
                          (normalize-term (triple-subject triple))))
               (or (null predicate)
                   (equal (normalize-term predicate)
                          (normalize-term (triple-predicate triple))))
               (or (null object)
                   (equal (normalize-term object)
                          (normalize-term (triple-object triple))))))
        candidates)))))

(defun kb-query-pattern (kb pattern)
  "Query with pattern (s p o) using symbols :? as wildcards

   Example: (kb-query-pattern kb '(:? rdf:type rdfs:Class))"
  (destructuring-bind (s p o) pattern
    (kb-query kb
              (if (eq s :?) nil s)
              (if (eq p :?) nil p)
              (if (eq o :?) nil o))))

(defun kb-all-triples (kb)
  "Return all triples in knowledge base"
  (alexandria:hash-table-values (knowledge-base-triples kb)))

(defun kb-size (kb)
  "Return number of triples in knowledge base"
  (hash-table-count (knowledge-base-triples kb)))

;;; ============================================================================
;;; RDFS INFERENCE RULES
;;; ============================================================================
;;;;
;;;; Implements RDFS entailment rules from W3C RDF Semantics:
;;;; https://www.w3.org/TR/rdf11-mt/

(defun apply-rdfs2 (kb)
  "RDFS2: Domain inference

   If (p rdfs:domain C) and (s p o)
   Then (s rdf:type C)"

  (let ((new-triples 0))
    (dolist (domain-triple (kb-query kb nil +rdfs-domain+ nil))
      (let ((property (triple-subject domain-triple))
            (class (triple-object domain-triple)))
        (dolist (usage-triple (kb-query kb nil property nil))
          (let ((subject (triple-subject usage-triple)))
            (when (kb-add-triple kb subject +rdf-type+ class :inferred t)
              (incf new-triples))))))
    new-triples))

(defun apply-rdfs3 (kb)
  "RDFS3: Range inference

   If (p rdfs:range C) and (s p o)
   Then (o rdf:type C)"

  (let ((new-triples 0))
    (dolist (range-triple (kb-query kb nil +rdfs-range+ nil))
      (let ((property (triple-subject range-triple))
            (class (triple-object range-triple)))
        (dolist (usage-triple (kb-query kb nil property nil))
          (let ((object (triple-object usage-triple)))
            ;; Only apply to non-literals
            (unless (literal-p object)
              (when (kb-add-triple kb object +rdf-type+ class :inferred t)
                (incf new-triples)))))))
    new-triples))

(defun apply-rdfs5 (kb)
  "RDFS5: SubProperty transitivity

   If (p1 rdfs:subPropertyOf p2) and (p2 rdfs:subPropertyOf p3)
   Then (p1 rdfs:subPropertyOf p3)"

  (let ((new-triples 0))
    (dolist (t1 (kb-query kb nil +rdfs-subproperty-of+ nil))
      (let ((p1 (triple-subject t1))
            (p2 (triple-object t1)))
        (dolist (t2 (kb-query kb p2 +rdfs-subproperty-of+ nil))
          (let ((p3 (triple-object t2)))
            (when (kb-add-triple kb p1 +rdfs-subproperty-of+ p3 :inferred t)
              (incf new-triples))))))
    new-triples))

(defun apply-rdfs7 (kb)
  "RDFS7: Property inheritance via subPropertyOf

   If (p1 rdfs:subPropertyOf p2) and (s p1 o)
   Then (s p2 o)"

  (let ((new-triples 0))
    (dolist (subprop-triple (kb-query kb nil +rdfs-subproperty-of+ nil))
      (let ((sub-property (triple-subject subprop-triple))
            (super-property (triple-object subprop-triple)))
        (dolist (usage-triple (kb-query kb nil sub-property nil))
          (let ((subject (triple-subject usage-triple))
                (object (triple-object usage-triple)))
            (when (kb-add-triple kb subject super-property object :inferred t)
              (incf new-triples))))))
    new-triples))

(defun apply-rdfs9 (kb)
  "RDFS9: Type inheritance via subClassOf

   If (C1 rdfs:subClassOf C2) and (x rdf:type C1)
   Then (x rdf:type C2)"

  (let ((new-triples 0))
    (dolist (subclass-triple (kb-query kb nil +rdfs-subclass-of+ nil))
      (let ((sub-class (triple-subject subclass-triple))
            (super-class (triple-object subclass-triple)))
        (dolist (type-triple (kb-query kb nil +rdf-type+ sub-class))
          (let ((instance (triple-subject type-triple)))
            (when (kb-add-triple kb instance +rdf-type+ super-class :inferred t)
              (incf new-triples))))))
    new-triples))

(defun apply-rdfs11 (kb)
  "RDFS11: SubClass transitivity

   If (C1 rdfs:subClassOf C2) and (C2 rdfs:subClassOf C3)
   Then (C1 rdfs:subClassOf C3)"

  (let ((new-triples 0))
    (dolist (t1 (kb-query kb nil +rdfs-subclass-of+ nil))
      (let ((c1 (triple-subject t1))
            (c2 (triple-object t1)))
        (dolist (t2 (kb-query kb c2 +rdfs-subclass-of+ nil))
          (let ((c3 (triple-object t2)))
            (when (kb-add-triple kb c1 +rdfs-subclass-of+ c3 :inferred t)
              (incf new-triples))))))
    new-triples))

;;; ============================================================================
;;; INFERENCE ENGINE
;;; ============================================================================

(defun apply-rdfs-rules (kb)
  "Apply all RDFS entailment rules once

   Returns:
     Number of new triples inferred"

  (+ (apply-rdfs2 kb)   ; Domain
     (apply-rdfs3 kb)   ; Range
     (apply-rdfs5 kb)   ; SubProperty transitivity
     (apply-rdfs7 kb)   ; Property inheritance
     (apply-rdfs9 kb)   ; Type inheritance
     (apply-rdfs11 kb))) ; SubClass transitivity

(defun run-inference (kb &key (max-iterations 100))
  "Run forward-chaining inference until fixpoint

   Repeatedly applies RDFS rules until no new triples are inferred
   or max-iterations is reached.

   Args:
     kb: knowledge-base
     max-iterations: Maximum iterations to prevent infinite loops

   Returns:
     Total number of inferred triples"

  (let ((total-inferred 0)
        (iteration 0))

    (loop
      (incf iteration)
      (when (> iteration max-iterations)
        (warn "RDFS inference: max iterations (~D) reached" max-iterations)
        (return))

      (let ((new-triples (apply-rdfs-rules kb)))
        (incf total-inferred new-triples)

        ;; Fixpoint reached - no new inferences
        (when (zerop new-triples)
          (return))))

    (setf (knowledge-base-inferred-p kb) t)
    (format t "~&; RDFS inference complete: ~D iterations, ~D inferred triples~%"
            iteration total-inferred)
    total-inferred))

(defun infer-closure (kb)
  "Compute full RDFS closure of knowledge base

   Alias for run-inference with default parameters."
  (run-inference kb))

;;; ============================================================================
;;; LEGAL DOMAIN HELPERS
;;; ============================================================================

(defparameter *eli-namespace* "http://data.europa.eu/eli/ontology#")
(defparameter *legal-namespace* "https://stavropouloslaw.com/ontology/legal#")

(defun add-legal-ontology (kb)
  "Add basic legal ontology schema to knowledge base

   Defines classes and properties for Greek legal corpus."

  ;; Classes
  (kb-add-triple kb (strcat *legal-namespace* "LegalDocument")
                 +rdf-type+ +rdfs-class+)
  (kb-add-triple kb (strcat *legal-namespace* "Constitution")
                 +rdfs-subclass-of+ (strcat *legal-namespace* "LegalDocument"))
  (kb-add-triple kb (strcat *legal-namespace* "Article")
                 +rdfs-subclass-of+ (strcat *legal-namespace* "LegalDocument"))
  (kb-add-triple kb (strcat *legal-namespace* "Paragraph")
                 +rdfs-subclass-of+ (strcat *legal-namespace* "LegalDocument"))

  ;; ELI classes
  (kb-add-triple kb (strcat *eli-namespace* "LegalResource")
                 +rdf-type+ +rdfs-class+)
  (kb-add-triple kb (strcat *legal-namespace* "Article")
                 +rdfs-subclass-of+ (strcat *eli-namespace* "LegalResource"))

  ;; Properties
  (kb-add-triple kb (strcat *legal-namespace* "hasArticle")
                 +rdfs-domain+ (strcat *legal-namespace* "Constitution"))
  (kb-add-triple kb (strcat *legal-namespace* "hasArticle")
                 +rdfs-range+ (strcat *legal-namespace* "Article"))

  (kb-add-triple kb (strcat *legal-namespace* "hasParagraph")
                 +rdfs-domain+ (strcat *legal-namespace* "Article"))
  (kb-add-triple kb (strcat *legal-namespace* "hasParagraph")
                 +rdfs-range+ (strcat *legal-namespace* "Paragraph"))

  (kb-add-triple kb (strcat *legal-namespace* "cites")
                 +rdfs-domain+ (strcat *legal-namespace* "Article"))
  (kb-add-triple kb (strcat *legal-namespace* "cites")
                 +rdfs-range+ (strcat *legal-namespace* "Article"))

  ;; subPropertyOf for ELI compatibility
  (kb-add-triple kb (strcat *legal-namespace* "cites")
                 +rdfs-subproperty-of+ (strcat *eli-namespace* "cites"))

  (format t "~&; Added legal ontology schema (~D triples)~%" (kb-size kb)))

(defun strcat (&rest strings)
  "Concatenate strings"
  (apply #'concatenate 'string strings))

;;; ============================================================================
;;; QUERY UTILITIES
;;; ============================================================================

(defun get-all-types (kb subject)
  "Get all types of a subject (including inferred)

   Args:
     kb: knowledge-base (should have inference run)
     subject: Subject URI

   Returns:
     List of type URIs"

  (mapcar #'triple-object
          (kb-query kb subject +rdf-type+ nil)))

(defun get-all-instances (kb class)
  "Get all instances of a class (including inferred)

   Args:
     kb: knowledge-base (should have inference run)
     class: Class URI

   Returns:
     List of instance URIs"

  (mapcar #'triple-subject
          (kb-query kb nil +rdf-type+ class)))

(defun get-superclasses (kb class)
  "Get all superclasses of a class (including transitive)

   Args:
     kb: knowledge-base (should have inference run)
     class: Class URI

   Returns:
     List of superclass URIs"

  (mapcar #'triple-object
          (kb-query kb class +rdfs-subclass-of+ nil)))

(defun get-subclasses (kb class)
  "Get all subclasses of a class (including transitive)

   Args:
     kb: knowledge-base (should have inference run)
     class: Class URI

   Returns:
     List of subclass URIs"

  (mapcar #'triple-subject
          (kb-query kb nil +rdfs-subclass-of+ class)))

;;; ============================================================================
;;; SERIALIZATION
;;; ============================================================================

(defun kb-to-ntriples (kb &optional stream)
  "Serialize knowledge base as N-Triples

   Args:
     kb: knowledge-base
     stream: Output stream (or NIL for string)

   Returns:
     N-Triples string (if stream is NIL)"

  (flet ((serialize-term (term)
           (etypecase term
             (string (format nil "<~A>" term))
             (uri (format nil "<~A>" (uri-value term)))
             (literal
              (if (literal-language term)
                  (format nil "\"~A\"@~A"
                          (escape-ntriples (literal-value term))
                          (literal-language term))
                  (if (literal-datatype term)
                      (format nil "\"~A\"^^<~A>"
                              (escape-ntriples (literal-value term))
                              (literal-datatype term))
                      (format nil "\"~A\""
                              (escape-ntriples (literal-value term)))))))))

    (let ((out (or stream (make-string-output-stream))))
      (dolist (triple (kb-all-triples kb))
        (format out "~A ~A ~A .~%"
                (serialize-term (triple-subject triple))
                (serialize-term (triple-predicate triple))
                (serialize-term (triple-object triple))))
      (unless stream
        (get-output-stream-string out)))))

(defun escape-ntriples (string)
  "Escape string for N-Triples format"
  (with-output-to-string (out)
    (loop for char across string
          do (case char
               (#\\ (write-string "\\\\" out))
               (#\" (write-string "\\\"" out))
               (#\Newline (write-string "\\n" out))
               (#\Return (write-string "\\r" out))
               (#\Tab (write-string "\\t" out))
               (#\Backspace (write-string "\\b" out))
               (#\Page (write-string "\\f" out))
               (otherwise (if (< (char-code char) #x20)
                              (format out "\\u~4,'0x" (char-code char))
                              (write-char char out)))))))

;;; ============================================================================
;;; END OF RDFS-INFERENCE.LISP
;;; ============================================================================
