;;;; source/legal-hypergraph.lisp
;;;; ============================================================================
;;;; LEGAL HYPERGRAPH — N-ary knowledge model (CLOS + MOP)
;;;; ============================================================================
;;;;
;;;; Law is N-ary: one amending act touches a SET of articles at once; a combined
;;;; reference binds a SET; a concept groups a SET. A binary (article→article) graph
;;;; fragments these. This module models them as first-class HYPEREDGES.
;;;;
;;;; CLOS / MOP (the design IS the demonstration):
;;;;   ✓ HYPEREDGE abstract class → typed subclasses (AMENDMENT-EDGE today; add a type
;;;;     by subclassing — nothing else changes).
;;;;   ✓ POLYMORPHIC serialization: EDGE->TURTLE is a generic with ONE default method
;;;;     (the W3C n-ary skeleton) that calls EDGE-TYPE-URI + EDGE-EXTRA-TURTLE — the
;;;;     template-method pattern. A new edge type supplies two methods; the emitter and
;;;;     every caller stay untouched. Serialization lives HERE, once — no duplication.
;;;;   ✓ MOP edge-type discovery via SB-MOP:CLASS-DIRECT-SUBCLASSES (same idiom as the
;;;;     content-rule registry) — no hand-maintained type list.
;;;;
;;;; Emitted as RDF (Turtle) with the W3C n-ary relations pattern, so the hypergraph
;;;; stays SPARQL-queryable on the existing triplestore — not a niche hypergraph DB.

(defpackage :orchestrator.hypergraph
  (:use :cl)
  (:export #:hyperedge #:edge-subject #:edge-members #:edge-provenance
           #:edge-type-uri #:edge-extra-turtle #:edge->turtle
           #:amendment-edge #:make-amendment-edge
           #:edge-fek #:edge-effective #:edge-operations
           #:reference-edge #:make-reference-edge #:edge-source
           #:concept-edge #:make-concept-edge #:edge-label
           #:legal-hypergraph #:make-legal-hypergraph #:hypergraph-add
           #:hypergraph-edges #:emit-hypergraph-ttl #:edge-types))

(in-package :orchestrator.hypergraph)

;;; ----------------------------------------------------------------------------
;;; the abstract hyperedge + protocol
;;; ----------------------------------------------------------------------------

(defclass hyperedge ()
  ((subject    :initarg :subject    :reader edge-subject    :initform "edge")
   (members    :initarg :members    :reader edge-members    :initform nil)  ; list of article ids
   (provenance :initarg :provenance :reader edge-provenance :initform nil))
  (:documentation "Abstract N-ary legal relation over a SET of member nodes."))

(defun %ttl-lit (value)
  "Render VALUE as a properly-escaped double-quoted Turtle literal. Lisp ~S (prin1)
   only escapes \" and \\ — NOT newline/return/tab, which are illegal inside a
   \"...\" literal and let attacker-controlled text (fek strings, labels, operation
   hashes drawn from parsed gazette/config data) break the grammar or inject
   triples. This is the single escaping choke point for the hypergraph emitter."
  (with-output-to-string (s)
    (write-char #\" s)
    (loop for ch across (princ-to-string (or value ""))
          do (case ch
               (#\" (write-string "\\\"" s))
               (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s))
               (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s))
               (t (write-char ch s))))
    (write-char #\" s)))

(defgeneric edge-type-uri (edge)
  (:documentation "The RDF class (CURIE) of this hyperedge, e.g. \"slw:AmendmentEvent\"."))

(defgeneric edge-extra-turtle (edge stream eli)
  (:documentation "Emit the subclass's own predicates (each ending in ' ;'). Default: none.")
  (:method ((edge hyperedge) stream eli) (declare (ignore edge stream eli)) nil))

(defgeneric edge->turtle (edge stream eli)
  (:documentation "Serialize EDGE to Turtle via the W3C n-ary pattern. Template method:
   the skeleton (typed node + slw:involves the member set + slw:memberCount) is shared;
   EDGE-TYPE-URI and EDGE-EXTRA-TURTLE specialise it per subclass.")
  (:method ((edge hyperedge) stream eli)
    (format stream "<~A/hyperedge/~A> a ~A ;~%" eli (edge-subject edge) (edge-type-uri edge))
    (when (edge-members edge)
      (format stream "    slw:involves ~{<~A>~^, ~} ;~%"
              (mapcar (lambda (m) (format nil "~A/art/~A" eli m)) (edge-members edge))))
    (edge-extra-turtle edge stream eli)
    (format stream "    slw:memberCount ~D .~%~%" (length (edge-members edge)))))

;;; ----------------------------------------------------------------------------
;;; AMENDMENT-EDGE — one amending act as a hyperedge over the articles it touched
;;; ----------------------------------------------------------------------------

(defclass amendment-edge (hyperedge)
  ((fek        :initarg :fek        :reader edge-fek        :initform nil)
   (effective  :initarg :effective  :reader edge-effective  :initform nil)
   ;; operations: list of (op-kind target-id before-hash after-hash) — the proof
   (operations :initarg :operations :reader edge-operations :initform nil))
  (:documentation "An amending act (ΦΕΚ) as a hyperedge: its member set is every article
   it modified; each operation carries before/after hashes — the L2 replay proof."))

(defun make-amendment-edge (&key subject members fek effective operations)
  (make-instance 'amendment-edge :subject subject :members members
                                 :fek fek :effective effective :operations operations))

(defmethod edge-type-uri ((edge amendment-edge)) "slw:AmendmentEvent")

(defmethod edge-extra-turtle ((edge amendment-edge) stream eli)
  (when (edge-fek edge)
    (format stream "    slw:fek ~A ;~%" (%ttl-lit (edge-fek edge))))
  (when (edge-effective edge)
    (format stream "    prov:atTime ~A^^xsd:date ;~%"
            (%ttl-lit (edge-effective edge))))
  (dolist (op (edge-operations edge))
    (destructuring-bind (kind target before after) op
      (format stream "    slw:operation [ a slw:Operation ; slw:op ~A ; slw:target <~A/art/~A> ; slw:beforeHash ~A ; slw:afterHash ~A ] ;~%"
              (%ttl-lit (string-downcase (princ-to-string kind))) eli target
              (%ttl-lit (or before "")) (%ttl-lit (or after ""))))))

;;; ----------------------------------------------------------------------------
;;; REFERENCE-EDGE — an article's whole citation set as ONE N-ary relation
;;; ----------------------------------------------------------------------------
;;;
;;; Proof that the model extends WITHOUT touching EDGE->TURTLE or the emitter: a new
;;; edge type is a subclass + EDGE-TYPE-URI + (optionally) EDGE-EXTRA-TURTLE. Done.

(defclass reference-edge (hyperedge)
  ((source :initarg :source :reader edge-source :initform nil))
  (:documentation "The full citation set of one article as a single N-ary relation:
   the citing article (SOURCE) → the SET of articles it cites (members)."))

(defun make-reference-edge (&key subject source members)
  (make-instance 'reference-edge :subject subject :source source :members members))

(defmethod edge-type-uri ((edge reference-edge)) "slw:CitationSet")

(defmethod edge-extra-turtle ((edge reference-edge) stream eli)
  (when (edge-source edge)
    (format stream "    slw:citingArticle <~A/art/~A> ;~%" eli (edge-source edge))))

;;; ----------------------------------------------------------------------------
;;; CONCEPT-EDGE — a legal concept over the SET of articles that express it
;;; ----------------------------------------------------------------------------
;;;
;;; Class + methods are ready; populated from a concept source (EuroVoc / heading
;;; clustering) when available. Included to show the model is open for extension.

(defclass concept-edge (hyperedge)
  ((label :initarg :label :reader edge-label :initform nil))
  (:documentation "A concept (e.g. a EuroVoc term) linking the SET of articles under it."))

(defun make-concept-edge (&key subject label members)
  (make-instance 'concept-edge :subject subject :label label :members members))

(defmethod edge-type-uri ((edge concept-edge)) "slw:ConceptCluster")

(defmethod edge-extra-turtle ((edge concept-edge) stream eli)
  (declare (ignore eli))
  (when (edge-label edge)
    (format stream "    slw:conceptLabel ~A ;~%" (%ttl-lit (edge-label edge)))))

;;; ----------------------------------------------------------------------------
;;; the hypergraph container + serialization
;;; ----------------------------------------------------------------------------

(defclass legal-hypergraph ()
  ((edges :initarg :edges :accessor hypergraph-edges :initform nil))
  (:documentation "A set of hyperedges over a corpus (insertion order preserved)."))

(defun make-legal-hypergraph () (make-instance 'legal-hypergraph))

(defun hypergraph-add (hg edge)
  "Add EDGE to HG (returns HG). Edges are kept in insertion order."
  (setf (hypergraph-edges hg) (nconc (hypergraph-edges hg) (list edge)))
  hg)

(defun emit-hypergraph-ttl (hg stream eli &key title)
  "Serialize the whole hypergraph to Turtle. Each edge dispatches to its own
   EDGE->TURTLE — the emitter is type-agnostic (add an edge type, this never changes)."
  (format stream "@prefix slw: <https://stavropouloslaw.com/ontology/legal#> .~%")
  (format stream "@prefix eli: <http://data.europa.eu/eli/ontology#> .~%")
  (format stream "@prefix prov: <http://www.w3.org/ns/prov#> .~%")
  (format stream "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .~%~%")
  (when title
    (format stream "# ~A — legal HYPERGRAPH (N-ary hyperedges; W3C n-ary relations pattern).~%~%" title))
  (dolist (e (hypergraph-edges hg) hg)
    (edge->turtle e stream eli)))

;;; ----------------------------------------------------------------------------
;;; MOP: discover the concrete edge types from the class graph (no manual registry)
;;; ----------------------------------------------------------------------------

(defun edge-types ()
  "Every concrete HYPEREDGE subclass, discovered from the MOP class graph. Define a new
   edge type by subclassing HYPEREDGE; it is found here automatically."
  (labels ((leaves (class)
             (let ((subs (sb-mop:class-direct-subclasses class)))
               (if subs (mapcan #'leaves subs) (list class)))))
    (mapcan #'leaves (sb-mop:class-direct-subclasses (find-class 'hyperedge)))))
