;;;; source/legal-reasoning-bridge.lisp
;;;; ============================================================================
;;;; REASONING BRIDGE — lift the LIVE corpus into engine facts, run the brain
;;;; ============================================================================
;;;;
;;;; The brain (legal-inference-engine + ontology + L2 + L3) reasons over FACTS. This
;;;; bridge is the ONE place that turns the real corpus into those facts and runs the
;;;; reasoner — so the engine stays pure and nothing is duplicated:
;;;;
;;;;   • the citation graph (orchestrator.references) → (:references …) facts,
;;;;   • a hypothetical/actual article change → (:changed …),
;;;; and returns the derived conclusions WITH their proofs.
;;;;
;;;; This is what makes the brain operational on live data: an impact query
;;;; ("if article X changes, what is affected — and why") answered from the corpus's
;;;; own resolved citations, each answer carrying a machine-checkable derivation.

(defpackage :orchestrator.reasoning
  (:use :cl)
  (:export #:reference-facts #:reason-impact #:impact-report))

(in-package :orchestrator.reasoning)

(defun reference-facts (doc code)
  "Every resolved article→article citation in DOC as an engine fact
   (:references CODE SRC CODE TART). Reuses the existing citation graph — the edges
   are never recomputed here."
  (let* ((graph (orchestrator.references:reference-graph doc))
         (ids   (orchestrator.references:document-article-ids doc))
         (facts '()))
    (maphash
     (lambda (id present)
       (declare (ignore present))
       (dolist (tgt (orchestrator.references:graph-edges graph id))
         (push (list :references code id code tgt) facts)))
     ids)
    (nreverse facts)))

;;; ── ΜΑΚΡΟΒΙΕΣ ΜΗΧΑΝΕΣ (Φάση 2): μία μηχανή ανά ενοποιημένο κείμενο ──
;;; Ο δαίμονας ρωτά έως 5 άρθρα πάνω στο ΙΔΙΟ doc ανά κύκλο — χωρίς cache,
;;; 5 πανομοιότυπες μηχανές + 5 πλήρεις εξαγωγές παραπομπών. Το κλειδί είναι
;;; ΑΣΘΕΝΕΣ και είναι το ΙΔΙΟ το αντικείμενο του doc: ίδιο αντικείμενο ⇒ ίδια
;;; facts εγγυημένα (καμία σιωπηλή μπαγιάτικη αλήθεια — νέο doc, νέα μηχανή),
;;; και ο συλλέκτης απορριμμάτων καθαρίζει μαζί με το doc και τη μηχανή του.

(defvar *engine-lock* (sb-thread:make-mutex :name "reasoning-engines")
  "Ένας συλλογισμός επίπτωσης τη φορά — η μηχανή ανά doc δεν είναι reentrant.")

(defvar *engines* (make-hash-table :test 'eq :weakness :key)
  "doc → (code . inference-engine) με τα reference facts ήδη φορτωμένα.")

(defun %engine-for (doc code)
  (let ((cell (gethash doc *engines*)))
    (if (and cell (equal (car cell) code))
        (cdr cell)
        (let ((engine (orchestrator.inference:make-inference-engine)))
          (orchestrator.inference:add-facts engine (reference-facts doc code))
          (setf (gethash doc *engines*) (cons code engine))
          engine))))

(defun reason-impact (doc code article)
  "Seed the citation facts of DOC plus (:changed CODE ARTICLE), run the brain, and
   return the list of (AFFECTED-ARTICLE . PROOF-TREE) — every provision that is
   (transitively) affected by a change to ARTICLE, each with its JTMS derivation.
   Pure use of orchestrator.inference; no reasoning logic lives here.
   Η μηχανή ΖΕΙ ανά doc: το ερώτημα προσθέτει το (:changed …), συλλογίζεται,
   και το ΑΝΑΚΑΛΕΙ (tms-retract-premise) — το επόμενο ερώτημα στο ίδιο doc
   γειώνει ΜΟΝΟ το δικό του δέλτα (η γείωση ζει στη μηχανή)· η ΠΕΠΟΙΘΗΣΗ
   επανυπολογίζεται σε όλο το JTMS (γραμμικά — τίμιο, δηλωμένο κόστος)."
  (sb-thread:with-mutex (*engine-lock*)
    (let ((engine (%engine-for doc code))
          (changed (list :changed code article)))
      (orchestrator.inference:add-fact engine changed)
      ;; ΕΓΓΥΗΜΕΝΗ ανάκληση (unwind-protect): σφάλμα/διακοπή στο ενδιάμεσο δεν
      ;; αφήνει ποτέ ψευδές (:changed …) premise στη μακρόβια μηχανή του doc
      (unwind-protect
           (progn
             (orchestrator.inference:run-inference engine)
             (orchestrator.inference:affected-by engine code article))
        (orchestrator.inference:tms-retract-premise
         (orchestrator.inference:engine-jtms engine) changed)))))

(defun impact-report (doc code article &optional (stream *standard-output*))
  "Human-readable impact analysis for CODE/ARTICLE: the affected provisions and, for
   each, its proof tree. Returns the number of affected provisions."
  (let ((results (reason-impact doc code article)))
    (format stream "~&── ΑΝΑΛΥΣΗ ΕΠΙΠΤΩΣΗΣ: ~A άρθρο ~A — ~D επηρεαζόμεν~:[α άρθρα~;ο άρθρο~] ──~%"
            code article (length results) (= (length results) 1))
    (dolist (r results)
      (format stream "  • άρθρο ~A~%~A" (car r)
              (orchestrator.inference:explanation->string (cdr r) 2)))
    (length results)))
