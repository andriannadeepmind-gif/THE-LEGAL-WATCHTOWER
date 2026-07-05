;;;; source/shacl-validator.lisp
;;;; ============================================================================
;;;; SHACL CORE VALIDATOR (pure Common Lisp)
;;;; ============================================================================
;;;;
;;;; A real SHACL (Shapes Constraint Language) validation engine. Shapes are
;;;; themselves an RDF graph (Turtle), as the standard prescribes: this is not a
;;;; bespoke string-pattern checker but an engine that reads sh:NodeShape /
;;;; sh:property definitions and evaluates SHACL Core constraint components
;;;; against a data graph, producing a sh:ValidationReport.
;;;;
;;;; Supported targets:
;;;;   sh:targetClass, sh:targetNode, sh:targetSubjectsOf, sh:targetObjectsOf
;;;;
;;;; Supported constraint components (on property shapes via sh:path):
;;;;   sh:minCount  sh:maxCount  sh:datatype  sh:nodeKind  sh:pattern
;;;;   sh:minLength sh:maxLength sh:hasValue  sh:in        sh:class
;;;;
;;;; Output: VALIDATION-REPORT (conforms + results) and a Turtle serialization
;;;; (sh:ValidationReport / sh:ValidationResult), deterministic in document
;;;; order.
;;;;
;;;; Depends on: orchestrator.turtle (parser) and cl-ppcre (sh:pattern).
;;;; ============================================================================

(defpackage :orchestrator.shacl
  (:use :cl)
  (:import-from :orchestrator.turtle
                #:parse-turtle #:rdf-term-kind #:rdf-term-value
                #:rdf-term-datatype #:rdf-term-lang
                #:term-iri-p #:term-literal-p #:term-blank-p #:term= #:iri #:literal
                #:triple-s #:triple-p #:triple-o)
  (:export
   #:make-graph #:graph-from-turtle
   #:validation-report #:validation-report-conforms #:validation-report-results
   #:validation-result #:validation-result-focus-node #:validation-result-path
   #:validation-result-value #:validation-result-component
   #:validation-result-message #:validation-result-severity
   #:validate #:validate-turtle #:report->ttl #:conforms-p))

(in-package :orchestrator.shacl)

(defparameter +sh+ "http://www.w3.org/ns/shacl#")
(defparameter +rdf-type+ "http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
(defparameter +rdf-first+ "http://www.w3.org/1999/02/22-rdf-syntax-ns#first")
(defparameter +rdf-rest+ "http://www.w3.org/1999/02/22-rdf-syntax-ns#rest")
(defparameter +rdf-nil+ "http://www.w3.org/1999/02/22-rdf-syntax-ns#nil")
(defparameter +xsd-string+ "http://www.w3.org/2001/XMLSchema#string")
(defparameter +rdf-langstring+ "http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")
(defun sh (local) (concatenate 'string +sh+ local))

;;; ============================================================================
;;; GRAPH MODEL
;;; ============================================================================

(defstruct graph
  (triples nil :type list)
  (spo (make-hash-table :test 'equal) :type hash-table)) ; subject-value -> list of (p . o)

(defun add-spo (g s-val p-term o-term)
  (push (cons p-term o-term) (gethash s-val (graph-spo g))))

(defun make-graph-from-triples (triples)
  (let ((g (make-graph :triples triples)))
    (dolist (tr triples)
      (let ((s (triple-s tr)))
        (add-spo g (rdf-term-value s) (triple-p tr) (triple-o tr))))
    ;; restore document order within each subject bucket
    (maphash (lambda (k v) (setf (gethash k (graph-spo g)) (nreverse v))) (graph-spo g))
    g))

(defun graph-from-turtle (text) (make-graph-from-triples (parse-turtle text)))
(defun make-graph* (text) (graph-from-turtle text))

(defun po-of (g subject-term)
  "All (predicate . object) pairs for SUBJECT-TERM, in document order."
  (gethash (rdf-term-value subject-term) (graph-spo g)))

(defun values-of (g subject-term predicate-iri)
  "Object terms where (subject predicate ?) and predicate value = PREDICATE-IRI."
  (loop for (p . o) in (po-of g subject-term)
        when (and (term-iri-p p) (string= (rdf-term-value p) predicate-iri))
        collect o))

(defun one-value (g subject-term predicate-iri)
  (first (values-of g subject-term predicate-iri)))

(defun node-types (g node-term)
  (mapcar #'rdf-term-value
          (remove-if-not #'term-iri-p (values-of g node-term +rdf-type+))))

(defun node-of-class-p (g node-term class-iri)
  (and (member class-iri (node-types g node-term) :test #'string=) t))

(defun all-subjects (g)
  (let ((seen (make-hash-table :test 'equal)) (out '()))
    (dolist (tr (graph-triples g))
      (let* ((s (triple-s tr)) (k (rdf-term-value s)))
        (unless (gethash k seen) (setf (gethash k seen) t) (push s out))))
    (nreverse out)))

(defun rdf-list->terms (g head)
  "Decode an RDF collection (rdf:first/rdf:rest) starting at HEAD into a list."
  (loop for node = head then (one-value g node +rdf-rest+)
        while (and node (not (and (term-iri-p node)
                                  (string= (rdf-term-value node) +rdf-nil+))))
        for item = (one-value g node +rdf-first+)
        while item
        collect item))

;;; ============================================================================
;;; SHAPE MODEL
;;; ============================================================================

(defstruct property-shape
  path           ; predicate IRI (string)
  min-count max-count
  datatype nodeKind pattern flags
  min-length max-length
  has-value      ; rdf-term
  in-list        ; list of rdf-terms
  class          ; class IRI
  message severity)

(defstruct node-shape
  id
  target-classes target-nodes target-subjects-of target-objects-of
  properties)    ; list of property-shape

(defun lit-string (term) (and term (rdf-term-value term)))

(defun parse-property-shape (sg pnode)
  "Parse a property shape blank/iri node PNODE from the shapes graph SG."
  (flet ((v1 (local) (one-value sg pnode (sh local))))
    (let ((path (v1 "path"))
          (in (v1 "in")))
      (make-property-shape
       :path (and path (rdf-term-value path))
       :min-count (let ((x (v1 "minCount"))) (and x (parse-integer (rdf-term-value x))))
       :max-count (let ((x (v1 "maxCount"))) (and x (parse-integer (rdf-term-value x))))
       :datatype (let ((x (v1 "datatype"))) (and x (rdf-term-value x)))
       :nodeKind (let ((x (v1 "nodeKind"))) (and x (rdf-term-value x)))
       :pattern (lit-string (v1 "pattern"))
       :flags (lit-string (v1 "flags"))
       :min-length (let ((x (v1 "minLength"))) (and x (parse-integer (rdf-term-value x))))
       :max-length (let ((x (v1 "maxLength"))) (and x (parse-integer (rdf-term-value x))))
       :has-value (v1 "hasValue")
       :in-list (and in (rdf-list->terms sg in))
       :class (let ((x (v1 "class"))) (and x (rdf-term-value x)))
       :message (lit-string (v1 "message"))
       :severity (let ((x (v1 "severity"))) (and x (rdf-term-value x)))))))

(defun parse-shapes (shapes-graph)
  "Extract all sh:NodeShape definitions from SHAPES-GRAPH."
  (let ((sg shapes-graph) (shapes '()))
    (dolist (s (all-subjects sg))
      (when (node-of-class-p sg s (sh "NodeShape"))
        (push (make-node-shape
               :id (rdf-term-value s)
               :target-classes (mapcar #'rdf-term-value (values-of sg s (sh "targetClass")))
               :target-nodes (values-of sg s (sh "targetNode"))
               :target-subjects-of (mapcar #'rdf-term-value (values-of sg s (sh "targetSubjectsOf")))
               :target-objects-of (mapcar #'rdf-term-value (values-of sg s (sh "targetObjectsOf")))
               :properties (mapcar (lambda (pn) (parse-property-shape sg pn))
                                   (values-of sg s (sh "property"))))
              shapes)))
    (nreverse shapes)))

;;; ============================================================================
;;; TARGET SELECTION
;;; ============================================================================

(defun focus-nodes (g shape)
  "Compute focus nodes for SHAPE in data graph G, de-duplicated, document order."
  (let ((seen (make-hash-table :test 'equal)) (out '()))
    (flet ((add (term) (let ((k (rdf-term-value term)))
                         (unless (gethash k seen) (setf (gethash k seen) t) (push term out)))))
      (dolist (c (node-shape-target-classes shape))
        (dolist (s (all-subjects g)) (when (node-of-class-p g s c) (add s))))
      (dolist (n (node-shape-target-nodes shape)) (add n))
      (dolist (p (node-shape-target-subjects-of shape))
        (dolist (tr (graph-triples g))
          (when (and (term-iri-p (triple-p tr)) (string= (rdf-term-value (triple-p tr)) p))
            (add (triple-s tr)))))
      (dolist (p (node-shape-target-objects-of shape))
        (dolist (tr (graph-triples g))
          (when (and (term-iri-p (triple-p tr)) (string= (rdf-term-value (triple-p tr)) p))
            (add (triple-o tr))))))
    (nreverse out)))

;;; ============================================================================
;;; RESULTS
;;; ============================================================================

(defstruct validation-result focus-node path value source-shape component message severity)
(defstruct validation-report conforms results)

(defun effective-datatype (term)
  (cond ((rdf-term-datatype term) (rdf-term-datatype term))
        ((rdf-term-lang term) +rdf-langstring+)
        (t +xsd-string+)))

(defun nodekind-ok-p (term kind-iri)
  (let ((k (and kind-iri (subseq kind-iri (length +sh+)))))
    (cond
      ((string= k "IRI") (term-iri-p term))
      ((string= k "Literal") (term-literal-p term))
      ((string= k "BlankNode") (term-blank-p term))
      ((string= k "BlankNodeOrIRI") (or (term-blank-p term) (term-iri-p term)))
      ((string= k "IRIOrLiteral") (or (term-iri-p term) (term-literal-p term)))
      ((string= k "BlankNodeOrLiteral") (or (term-blank-p term) (term-literal-p term)))
      (t t))))

;;; ============================================================================
;;; CONSTRAINT EVALUATION
;;; ============================================================================

(defun eval-property-shape (g focus ps shape-id collect)
  "Evaluate property shape PS against FOCUS in graph G; call COLLECT on each
   violation (a validation-result)."
  (let* ((path (property-shape-path ps))
         (values (and path (values-of g focus path)))
         (sev (or (property-shape-severity ps) (sh "Violation"))))
    (flet ((viol (component value &optional msg)
             (funcall collect
                      (make-validation-result
                       :focus-node (rdf-term-value focus)
                       :path path :value value :source-shape shape-id
                       :component component
                       :message (or (property-shape-message ps) msg component)
                       :severity sev))))
      ;; Cardinality
      (let ((n (length values)))
        (when (and (property-shape-min-count ps) (< n (property-shape-min-count ps)))
          (viol "MinCountConstraintComponent" nil
                (format nil "expected at least ~D value(s), got ~D"
                        (property-shape-min-count ps) n)))
        (when (and (property-shape-max-count ps) (> n (property-shape-max-count ps)))
          (viol "MaxCountConstraintComponent" nil
                (format nil "expected at most ~D value(s), got ~D"
                        (property-shape-max-count ps) n))))
      ;; hasValue (at least one value equals)
      (when (property-shape-has-value ps)
        (unless (some (lambda (v) (term= v (property-shape-has-value ps))) values)
          (viol "HasValueConstraintComponent" nil "required value absent")))
      ;; Per-value constraints
      (dolist (v values)
        (when (property-shape-datatype ps)
          (unless (and (term-literal-p v)
                       (string= (effective-datatype v) (property-shape-datatype ps)))
            (viol "DatatypeConstraintComponent" v
                  (format nil "datatype must be ~A" (property-shape-datatype ps)))))
        (when (property-shape-nodeKind ps)
          (unless (nodekind-ok-p v (property-shape-nodeKind ps))
            (viol "NodeKindConstraintComponent" v
                  (format nil "nodeKind must be ~A" (property-shape-nodeKind ps)))))
        (when (property-shape-pattern ps)
          (let* ((case-insensitive (and (property-shape-flags ps)
                                        (find #\i (property-shape-flags ps))))
                 (scanner (cl-ppcre:create-scanner (property-shape-pattern ps)
                                                   :case-insensitive-mode case-insensitive)))
            (unless (and (term-literal-p v) (cl-ppcre:scan scanner (rdf-term-value v)))
              (viol "PatternConstraintComponent" v
                    (format nil "must match pattern ~A" (property-shape-pattern ps))))))
        (when (property-shape-min-length ps)
          (when (< (length (rdf-term-value v)) (property-shape-min-length ps))
            (viol "MinLengthConstraintComponent" v
                  (format nil "min length ~D" (property-shape-min-length ps)))))
        (when (property-shape-max-length ps)
          (when (> (length (rdf-term-value v)) (property-shape-max-length ps))
            (viol "MaxLengthConstraintComponent" v
                  (format nil "max length ~D" (property-shape-max-length ps)))))
        (when (property-shape-class ps)
          (unless (and (or (term-iri-p v) (term-blank-p v))
                       (node-of-class-p g v (property-shape-class ps)))
            (viol "ClassConstraintComponent" v
                  (format nil "value must be of class ~A" (property-shape-class ps)))))
        (when (property-shape-in-list ps)
          (unless (some (lambda (x) (term= v x)) (property-shape-in-list ps))
            (viol "InConstraintComponent" v "value not in allowed set")))))))

;;; ============================================================================
;;; PUBLIC: VALIDATE
;;; ============================================================================

(defun validate (data-graph shapes-graph)
  "Validate DATA-GRAPH against SHAPES-GRAPH. Returns a VALIDATION-REPORT.
   Both arguments are GRAPH structs."
  (let ((results '()))
    (dolist (shape (parse-shapes shapes-graph))
      (dolist (focus (focus-nodes data-graph shape))
        (dolist (ps (node-shape-properties shape))
          (eval-property-shape data-graph focus ps (node-shape-id shape)
                               (lambda (r) (push r results))))))
    (setf results (nreverse results))
    (make-validation-report
     :conforms (notany (lambda (r) (string= (validation-result-severity r) (sh "Violation")))
                       results)
     :results results)))

(defun validate-turtle (data-ttl shapes-ttl)
  "Convenience: validate Turtle DATA-TTL against Turtle SHAPES-TTL."
  (validate (graph-from-turtle data-ttl) (graph-from-turtle shapes-ttl)))

(defun conforms-p (report) (validation-report-conforms report))

;;; ============================================================================
;;; REPORT SERIALIZATION (sh:ValidationReport)
;;; ============================================================================

(defun %ttl-str (s)
  (with-output-to-string (out)
    (loop for ch across (or s "")
          do (case ch (#\" (write-string "\\\"" out))
                      (#\\ (write-string "\\\\" out))
                      (#\Newline (write-string "\\n" out))
                      (#\Return (write-string "\\r" out))
                      (#\Tab (write-string "\\t" out))
                      (#\Backspace (write-string "\\b" out))
                      (#\Page (write-string "\\f" out))
                      (t (if (< (char-code ch) #x20)
                             (format out "\\u~4,'0x" (char-code ch))
                             (write-char ch out)))))))

(defun report->ttl (report)
  "Serialize a VALIDATION-REPORT as a sh:ValidationReport in Turtle."
  (with-output-to-string (s)
    (format s "@prefix sh: <~A> .~%" +sh+)
    (format s "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .~%~%")
    (format s "[] a sh:ValidationReport ;~%")
    (format s "    sh:conforms ~A" (if (validation-report-conforms report) "true" "false"))
    (if (validation-report-results report)
        (progn
          (format s " ;~%")
          (loop for r in (validation-report-results report)
                for firstp = t then nil
                do (format s "    sh:result [~%")
                   (format s "        a sh:ValidationResult ;~%")
                   (format s "        sh:focusNode <~A> ;~%" (validation-result-focus-node r))
                   (when (validation-result-path r)
                     (format s "        sh:resultPath <~A> ;~%" (validation-result-path r)))
                   (when (validation-result-value r)
                     (let ((v (validation-result-value r)))
                       (format s "        sh:value ~A ;~%"
                               (if (term-iri-p v) (format nil "<~A>" (rdf-term-value v))
                                   (format nil "\"~A\"" (%ttl-str (rdf-term-value v)))))))
                   (format s "        sh:sourceConstraintComponent sh:~A ;~%"
                           (validation-result-component r))
                   (format s "        sh:resultSeverity <~A> ;~%" (validation-result-severity r))
                   (format s "        sh:resultMessage \"~A\"~%"
                           (%ttl-str (validation-result-message r)))
                   (format s "    ]"))
          (format s " .~%"))
        (format s " .~%"))))
