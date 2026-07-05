;;;; source/greek-legislation-ontology.lisp
;;;; ============================================================================
;;;; GREEK LEGISLATION ONTOLOGY — the TBox the reasoning brain reasons over
;;;; ============================================================================
;;;;
;;;; The corpus already models IDENTITY, PROVENANCE and DOCUMENT STRUCTURE (FRBR via
;;;; slw:hasWork/Expression/Manifestation, ELI, PROV-O, the epistemic meta-ontology).
;;;; This module adds the missing half: a formal, substantive DOMAIN ontology of Greek
;;;; law — the conceptual map that lets the system MODEL the legislation, not merely
;;;; store its text, and gives OWL/RDFS reasoning (reasoning-authority) and the
;;;; legal-inference-engine a real schema to reason over:
;;;;
;;;;   • Sources of law + their RANK (Σύνταγμα › τυπικός νόμος › π.δ. › υπ. απόφαση …)
;;;;     — the substrate of *lex superior* (L2 conflict resolution).
;;;;   • Structural units (Βιβλίο/Μέρος/Τμήμα/Κεφάλαιο/Άρθρο/παράγραφος/εδάφιο/
;;;;     περίπτωση) — aligned to Akoma Ntoso elements.
;;;;   • Norm typology (obligation/prohibition/permission/definition/sanction/…)
;;;;     — the substrate of deontic reasoning (L4).
;;;;   • Legal events (enactment/amendment/repeal/entry-into-force).
;;;;
;;;; CL exploited to the maximum — the ontology is NOT a separate data file the code
;;;; drifts from; the CLOS CLASS GRAPH *is* the TBox:
;;;;   ✓ Each concept is a CLOS class under LEGAL-CONCEPT; CL subclassing IS
;;;;     rdfs:subClassOf. One truth for the hierarchy — homoiconic.
;;;;   ✓ DEFCONCEPT — a macro DSL: one form declares the class, its Greek/English
;;;;     labels, its rank, and its alignment to ELI / Akoma Ntoso standards.
;;;;   ✓ MOP discovery — the whole TBox is walked from the class graph
;;;;     (SB-MOP:CLASS-DIRECT-SUBCLASSES / -SUPERCLASSES); a new concept = a
;;;;     DEFCONCEPT, and it appears in the emitted OWL and is reasoned over
;;;;     automatically. Nothing to register by hand.
;;;;   ✓ Emitted as OWL 2 / RDFS Turtle so reasoning-authority (OWL 2 RL) and any
;;;;     external triplestore consume it directly — standards, not a private format.

(defpackage :orchestrator.legal-ontology
  (:use :cl)
  (:export #:legal-concept #:defconcept #:concept-metadata #:all-concepts
           #:concept-uri #:concept-rank #:concept-label #:concept-superconcepts
           #:find-concept #:source-of-law #:structural-unit #:legal-norm #:legal-event
           #:rank<= #:overriding-source #:emit-ontology-ttl #:*ontology-base*))

(in-package :orchestrator.legal-ontology)

(defparameter *ontology-base* "https://stavropouloslaw.com/ontology/legal#"
  "Base IRI of the slw: legal ontology namespace.")

;;; ============================================================================
;;; The concept metaclass registry — metadata keyed by class, hierarchy by MOP
;;; ============================================================================

(defvar *concepts* (make-hash-table :test 'eq)
  "class-name (symbol) -> metadata plist (:uri :el :en :rank :eli :akn :doc).")

(defclass legal-concept () ()
  (:documentation "Root of the Greek-legislation TBox. Every legal concept is a CLOS
   class under this root; the class graph is the rdfs:subClassOf hierarchy."))

(defmacro defconcept (name (&rest supers) &key uri (el "") (en "") rank eli akn doc)
  "Declare an ontology concept: a CLOS class NAME under SUPERS (which become its
   rdfs:subClassOf parents) plus its metadata. URI defaults to the CamelCase of NAME.
   EL/EN are rdfs:labels; RANK orders sources of law (lower = higher authority); ELI
   and AKN are alignment CURIEs (skos:closeMatch) to the ELI ontology / Akoma Ntoso."
  (let ((parents (or supers '(legal-concept))))
    `(progn
       (defclass ,name ,parents ()
         (:documentation ,(or doc (format nil "~A / ~A" el en))))
       (setf (gethash ',name *concepts*)
             (list :uri ,(or uri (%default-uri name)) :el ,el :en ,en
                   :rank ,rank :eli ,eli :akn ,akn :doc ,doc))
       ',name)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun %default-uri (name)
    "CamelCase URI local-name from a Lisp class symbol (source-of-law → SourceOfLaw)."
    (with-output-to-string (s)
      (loop with up = t
            for ch across (string-downcase (symbol-name name))
            do (cond ((char= ch #\-) (setf up t))
                     (up (write-char (char-upcase ch) s) (setf up nil))
                     (t (write-char ch s)))))))

(defun concept-metadata (name) (gethash name *concepts*))
(defun concept-uri (name) (getf (concept-metadata name) :uri))
(defun concept-rank (name) (getf (concept-metadata name) :rank))
(defun concept-label (name &optional (lang :el))
  (getf (concept-metadata name) (if (eq lang :en) :en :el)))

(defun all-concepts ()
  "Every concept class (the whole TBox), discovered from the MOP class graph under
   LEGAL-CONCEPT — internal nodes and leaves alike. Order: breadth-first from root."
  (let ((seen (make-hash-table :test 'eq)) (out '()) (queue (list (find-class 'legal-concept))))
    (loop while queue do
      (let ((c (pop queue)))
        (dolist (sub (sb-mop:class-direct-subclasses c))
          (unless (gethash sub seen)
            (setf (gethash sub seen) t)
            (push sub out)
            (setf queue (append queue (list sub)))))))
    (nreverse (mapcar #'class-name out))))

(defun find-concept (name) (and (gethash name *concepts*) name))

(defun concept-superconcepts (name)
  "The direct super-concepts of NAME (its rdfs:subClassOf parents), excluding the
   bare LEGAL-CONCEPT root."
  (loop for super in (sb-mop:class-direct-superclasses (find-class name))
        for sn = (class-name super)
        when (and (not (eq sn 'legal-concept)) (gethash sn *concepts*))
        collect sn))

;;; ============================================================================
;;; AXIS 1 — SOURCES OF LAW (with RANK → the substrate of lex superior)
;;;   Lower rank = higher authority. The Constitution overrides a formal law,
;;;   which overrides a presidential decree, which overrides a ministerial act.
;;; ============================================================================

(defconcept source-of-law () :el "Πηγή δικαίου" :en "Source of law"
  :eli "eli:LegalResource"
  :doc "An authoritative source that produces binding legal norms.")

(defconcept constitution (source-of-law) :el "Σύνταγμα" :en "Constitution"
  :rank 1 :eli "eli:LegalResource" :akn "akn:act")
(defconcept international-treaty (source-of-law) :el "Διεθνής σύμβαση" :en "International treaty"
  :rank 2 :doc "Ratified international convention (Const. art. 28) — supra-legislative.")
(defconcept eu-law (source-of-law) :el "Ενωσιακό δίκαιο" :en "EU law"
  :rank 2 :eli "eli:LegalResource" :doc "Primacy of Union law over ordinary national law.")
(defconcept formal-law (source-of-law) :el "Τυπικός νόμος" :en "Formal law (statute)"
  :rank 3 :eli "eli:LegalResource" :akn "akn:act")
(defconcept legislative-act (formal-law) :el "Πράξη νομοθετικού περιεχομένου" :en "Act of legislative content"
  :rank 3 :doc "Const. art. 44 §1 — emergency act with statute force, ratified later.")
(defconcept presidential-decree (source-of-law) :el "Προεδρικό διάταγμα" :en "Presidential decree"
  :rank 4 :akn "akn:act")
(defconcept ministerial-decision (source-of-law) :el "Υπουργική απόφαση" :en "Ministerial decision"
  :rank 5)
(defconcept joint-ministerial-decision (ministerial-decision) :el "Κοινή υπουργική απόφαση (ΚΥΑ)" :en "Joint ministerial decision"
  :rank 5)
(defconcept regulatory-act (source-of-law) :el "Κανονιστική πράξη" :en "Regulatory act"
  :rank 6 :doc "Other subordinate regulatory acts of the administration.")

;;; ============================================================================
;;; AXIS 2 — STRUCTURAL UNITS (aligned to Akoma Ntoso hierarchy)
;;; ============================================================================

(defconcept structural-unit () :el "Δομική μονάδα" :en "Structural unit"
  :akn "akn:hierarchicalStructure"
  :doc "A hierarchical division of a legislative text.")

(defconcept book       (structural-unit) :el "Βιβλίο"     :en "Book"        :akn "akn:book")
(defconcept part-unit  (structural-unit) :el "Μέρος"      :en "Part"        :akn "akn:part"  :uri "Part")
(defconcept section-unit (structural-unit) :el "Τμήμα"    :en "Section"     :akn "akn:section" :uri "Section")
(defconcept chapter    (structural-unit) :el "Κεφάλαιο"   :en "Chapter"     :akn "akn:chapter")
(defconcept article    (structural-unit) :el "Άρθρο"      :en "Article"     :akn "akn:article"
  :eli "eli:LegalResourceSubdivision")
(defconcept paragraph  (structural-unit) :el "Παράγραφος" :en "Paragraph"   :akn "akn:paragraph")
(defconcept subparagraph (structural-unit) :el "Εδάφιο"   :en "Subparagraph" :akn "akn:subparagraph")
(defconcept case-item  (structural-unit) :el "Περίπτωση"  :en "Point/case"  :akn "akn:point" :uri "CaseItem")
(defconcept subcase-item (case-item)     :el "Υποπερίπτωση" :en "Sub-point" :akn "akn:point" :uri "SubcaseItem")

;;; ============================================================================
;;; AXIS 3 — NORM TYPOLOGY (the substrate of deontic reasoning, L4)
;;; ============================================================================

(defconcept legal-norm () :el "Κανόνας δικαίου" :en "Legal norm"
  :doc "The normative content a provision expresses.")

(defconcept obligation (legal-norm)  :el "Επιταγή/Υποχρέωση" :en "Obligation"  :doc "Deontic: OBLIGATORY.")
(defconcept prohibition (legal-norm) :el "Απαγόρευση"        :en "Prohibition" :doc "Deontic: FORBIDDEN.")
(defconcept permission (legal-norm)  :el "Άδεια/Ευχέρεια"    :en "Permission"  :doc "Deontic: PERMITTED.")
(defconcept definition-norm (legal-norm) :el "Ορισμός" :en "Definition" :uri "DefinitionNorm")
(defconcept sanction   (legal-norm)  :el "Κύρωση/Ποινή"      :en "Sanction")
(defconcept competence (legal-norm)  :el "Αρμοδιότητα"       :en "Competence")
(defconcept procedural-norm (legal-norm) :el "Δικονομικός κανόνας" :en "Procedural norm" :uri "ProceduralNorm")

;;; ============================================================================
;;; AXIS 4 — LEGAL EVENTS (align with the existing slw: mutation vocabulary)
;;; ============================================================================

(defconcept legal-event () :el "Νομικό γεγονός" :en "Legal event"
  :doc "An event in a provision's lifecycle.")

(defconcept enactment (legal-event) :el "Θέσπιση" :en "Enactment")
(defconcept amendment (legal-event) :el "Τροποποίηση" :en "Amendment" :akn "akn:activeModifications")
(defconcept repeal    (legal-event) :el "Κατάργηση"   :en "Repeal")
(defconcept entry-into-force (legal-event) :el "Έναρξη ισχύος" :en "Entry into force"
  :eli "eli:first_date_entry_in_force")

;;; ============================================================================
;;; lex superior — comparing the authority of two sources by RANK
;;; ============================================================================

(defun rank<= (a b)
  "True iff source concept A is at least as authoritative as B (rank A ≤ rank B).
   NIL ranks (non-sources) never dominate."
  (let ((ra (concept-rank a)) (rb (concept-rank b)))
    (and ra rb (<= ra rb))))

(defun overriding-source (a b)
  "Of two source-of-law concepts, the one that prevails under LEX SUPERIOR (higher
   authority = lower rank); NIL if equal or incomparable."
  (let ((ra (concept-rank a)) (rb (concept-rank b)))
    (cond ((or (null ra) (null rb) (= ra rb)) nil)
          ((< ra rb) a)
          (t b))))

;;; ============================================================================
;;; EMITTER — the CLOS class graph → OWL 2 / RDFS Turtle
;;; ============================================================================

(defun %ttl-esc (s)
  (with-output-to-string (o)
    (loop for ch across (or s "")
          do (case ch (#\" (write-string "\\\"" o)) (#\\ (write-string "\\\\" o))
                      (#\Newline (write-string "\\n" o)) (t (write-char ch o))))))

(defun emit-ontology-ttl (stream)
  "Serialize the whole TBox to OWL 2 / RDFS Turtle by walking the CLOS class graph.
   Each concept → owl:Class with rdfs:subClassOf (from CL superclasses), bilingual
   rdfs:label, slw:rank where defined, and skos:closeMatch alignments to ELI /
   Akoma Ntoso. A new DEFCONCEPT appears here automatically — the emitter is
   type-agnostic, exactly like the hypergraph serializer."
  (format stream "@prefix owl:  <http://www.w3.org/2002/07/owl#> .~%")
  (format stream "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .~%")
  (format stream "@prefix skos: <http://www.w3.org/2004/02/skos/core#> .~%")
  (format stream "@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .~%")
  (format stream "@prefix eli:  <http://data.europa.eu/eli/ontology#> .~%")
  (format stream "@prefix akn:  <http://docs.oasis-open.org/legaldocml/ns/akn/3.0#> .~%")
  (format stream "@prefix slw:  <~A> .~%~%" *ontology-base*)
  (format stream "<~A> a owl:Ontology ;~%    rdfs:label \"Greek Legislation Ontology\"@en, \"Οντολογία Ελληνικής Νομοθεσίας\"@el .~%~%"
          *ontology-base*)
  (dolist (name (all-concepts))
    (let* ((md (concept-metadata name))
           (uri (getf md :uri))
           (supers (concept-superconcepts name))
           (clauses '()))
      (flet ((clause (fmt &rest args) (push (apply #'format nil fmt args) clauses)))
        (clause "a owl:Class")
        (when supers
          (clause "rdfs:subClassOf ~{slw:~A~^, ~}" (mapcar #'concept-uri supers)))
        (when (plusp (length (or (getf md :el) "")))
          (clause "rdfs:label \"~A\"@el" (%ttl-esc (getf md :el))))
        (when (plusp (length (or (getf md :en) "")))
          (clause "rdfs:label \"~A\"@en" (%ttl-esc (getf md :en))))
        (when (getf md :rank)
          (clause "slw:rank ~D" (getf md :rank)))
        (when (getf md :eli)
          (clause "skos:closeMatch ~A" (getf md :eli)))
        (when (getf md :akn)
          (clause "skos:closeMatch ~A" (getf md :akn)))
        (when (plusp (length (or (getf md :doc) "")))
          (clause "rdfs:comment \"~A\"@el" (%ttl-esc (getf md :doc)))))
      ;; one subject, its predicate-object clauses joined by " ;", closed by " .".
      (format stream "slw:~A ~{~A~^ ;~%    ~} .~%~%" uri (nreverse clauses)))))
