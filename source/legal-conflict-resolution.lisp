;;;; source/legal-conflict-resolution.lisp
;;;; ============================================================================
;;;; BRAIN L2 — CONFLICT RESOLUTION (lex superior) + hierarchy validity
;;;; ============================================================================
;;;;
;;;; L1 (legal-inference-engine) derives the CONSEQUENCES of a change. L2 answers the
;;;; harder jurist's question: when two provisions CONFLICT, WHICH ONE PREVAILS — and
;;;; is a purported amendment even VALID under the hierarchy of sources? It does so
;;;; deterministically, with a proof for every verdict, by joining two things already
;;;; built:
;;;;
;;;;   • the RANKED sources-of-law from GREEK-LEGISLATION-ONTOLOGY (Σύνταγμα ‹ τυπικός
;;;;     νόμος ‹ π.δ. ‹ υπ. απόφαση …), and
;;;;   • the JTMS forward-chaining engine + rule DSL from LEGAL-INFERENCE-ENGINE.
;;;;
;;;; The elegant part (maximal reuse, no engine change): the ontology's rank knowledge
;;;; is COMPILED INTO FACTS — (:outranks SUPERIOR INFERIOR) for every ordered pair of
;;;; source types — so the rules stay pure declarative patterns and inherit JTMS
;;;; proofs for free. Add a source type to the ontology and lex-superior instantly
;;;; reasons about it; nothing here changes.
;;;;
;;;; L2 vocabulary (facts an adapter supplies):
;;;;   (:conflict CODE-A ART-A CODE-B ART-B)   — two provisions are in normative conflict
;;;;   (:source-type CODE ART SOURCE-URI)      — the source type of a provision
;;;;                                             (SOURCE-URI = an ontology concept URI,
;;;;                                              e.g. "FormalLaw", "PresidentialDecree")
;;;;   (:purports-to-amend CODE-A ART-A CODE-B ART-B) — A claims to amend/override B
;;;;
;;;; Derived:
;;;;   (:prevails CA A :over CB B :by lex-superior)
;;;;   (:invalid-override CA A :of CB B :reason subordinate-cannot-override-superior)

(defpackage :orchestrator.conflict
  (:use :cl :orchestrator.inference)
  (:export #:ontology-outranks-facts #:seed-hierarchy #:resolve-conflicts
           #:hierarchy-violations))

(in-package :orchestrator.conflict)

;;; ============================================================================
;;; Ontology → facts: compile the ranked source hierarchy into (:outranks …)
;;; ============================================================================

(defun ontology-outranks-facts ()
  "Every (:outranks SUPERIOR INFERIOR) pair implied by the ontology's source ranks —
   SUPERIOR strictly outranks INFERIOR (lower rank number = higher authority). Source
   types are named by their ontology concept URI (a string), so the facts line up with
   the (:source-type …) facts an adapter emits. Reflects the ontology automatically:
   a new DEFCONCEPT source with a rank is included here with no code change."
  (let* ((ont  (find-package :orchestrator.legal-ontology))
         (all  (funcall (find-symbol "ALL-CONCEPTS" ont)))
         (rank (find-symbol "CONCEPT-RANK" ont))
         (uri  (find-symbol "CONCEPT-URI" ont))
         ;; keep only ranked concepts (the sources of law)
         (sources (remove-if-not (lambda (c) (funcall rank c)) all))
         (facts '()))
    (dolist (a sources facts)
      (dolist (b sources)
        (when (< (funcall rank a) (funcall rank b))   ; A strictly outranks B
          (push (list :outranks (funcall uri a) (funcall uri b)) facts))))))

;;; ============================================================================
;;; L2 RULES — declarative, proof-carrying (fire only when conflict facts exist)
;;; ============================================================================

;; Conflict is SYMMETRIC: derive the reverse so the resolution rules fire regardless of
;; the order the adapter supplied the pair in (terminates — the reverse of the reverse
;; is the original, already present, so no new justification is added).
(defrule conflict-is-symmetric
  :when ((:conflict ?ca ?a ?cb ?b))
  :then (:conflict ?cb ?b ?ca ?a))

;; LEX SUPERIOR: of two conflicting provisions, the one from the higher-ranked source
;; prevails. With conflict symmetry above, this fires in whichever direction the
;; higher-ranked source is the FIRST party — so exactly the true winner is concluded.
(defrule lex-superior-resolves
  :when ((:conflict ?ca ?a ?cb ?b)
         (:source-type ?ca ?a ?sa)
         (:source-type ?cb ?b ?sb)
         (:outranks ?sa ?sb))
  :then (:prevails ?ca ?a :over ?cb ?b :by lex-superior))

;; HIERARCHY VALIDITY: a subordinate act cannot amend/override a provision that sits
;; higher in the source hierarchy (e.g. a ministerial decision purporting to amend a
;; formal law, or any act purporting to amend the Constitution). This is a genuine
;; validity check — the "amendment" is void, not merely lower-priority.
(defrule invalid-subordinate-override
  :when ((:purports-to-amend ?ca ?a ?cb ?b)
         (:source-type ?ca ?a ?sa)
         (:source-type ?cb ?b ?sb)
         (:outranks ?sb ?sa))          ; the TARGET outranks the amender
  :then (:invalid-override ?ca ?a :of ?cb ?b :reason subordinate-cannot-override-superior))

;; LEX SPECIALIS: the more specific of two conflicting provisions of the SAME code
;; prevails over the general one — UNLESS the specific one has been repealed. This is
;; the defeasible form the well-founded engine now makes expressible.
(defrule lex-specialis-resolves
  :when   ((:conflict ?c ?g ?c ?s)
           (:more-specific ?c ?s ?c ?g))
  :unless ((:repealed ?c ?s))
  :then   (:prevails ?c ?s :over ?c ?g :by lex-specialis))

;; LEX POSTERIOR: between two conflicting provisions of the SAME rank, the later
;; prevails — UNLESS the earlier one is the more specific, because LEX SPECIALIS
;; DEROGAT LEGI POSTERIORI GENERALI (the specific-but-earlier defeats the later-general).
;; The :unless clause encodes that classic priority declaratively.
(defrule lex-posterior-resolves
  :when   ((:conflict ?ca ?a ?cb ?b)
           (:same-rank ?ca ?a ?cb ?b)
           (:later ?ca ?a ?cb ?b))
  :unless ((:more-specific ?cb ?b ?ca ?a))
  :then   (:prevails ?ca ?a :over ?cb ?b :by lex-posterior))

;;; ============================================================================
;;; Entry points — seed the ontology facts, run, read verdicts WITH PROOFS
;;; ============================================================================

(defun seed-hierarchy (engine)
  "Load the ontology-derived (:outranks …) facts into ENGINE as premises, so the L2
   rules can resolve conflicts by authority. Returns ENGINE."
  (add-facts engine (ontology-outranks-facts))
  engine)

(defun resolve-conflicts (engine)
  "Run inference and return every resolved conflict as
     (WINNER-CODE WINNER-ART LOSER-CODE LOSER-ART BASIS . PROOF)
   Each verdict carries its full JTMS derivation (WHY it prevails)."
  (run-inference engine)
  (loop for (fact . nil) in (query engine '(:prevails ?ca ?a :over ?cb ?b :by ?basis))
        collect (list* (second fact) (third fact) (fifth fact) (sixth fact)
                       (eighth fact) (explain (engine-jtms engine) fact))))

(defun hierarchy-violations (engine)
  "Run inference and return every INVALID override (a subordinate act purporting to
   overrule a higher source) with its proof — a hard legal-validity failure."
  (run-inference engine)
  (loop for (fact . nil) in (query engine '(:invalid-override ?ca ?a :of ?cb ?b :reason ?r))
        collect (list* (second fact) (third fact) (fifth fact) (sixth fact)
                       (explain (engine-jtms engine) fact))))
