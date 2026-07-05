;;;; source/legal-dialectic.lisp
;;;; ============================================================================
;;;; Σ5 — ΑΝΤΙΔΙΚΙΑ: και οι ΔΥΟ πλευρές, καθεμία με την απόδειξή της
;;;; ============================================================================
;;;;
;;;; Dung grounded semantics = το μαθηματικό δίδυμο της well-founded που ΗΔΗ
;;;; τρέχει η μηχανή — ο ίδιος εναλλασσόμενος fixpoint, δεύτερη ανάγνωση:
;;;;   ΘΕΣΗ      = αποδεδειγμένη δεοντική θέση (fact-status :in) με το δέντρο της
;;;;   ΕΝΣΤΑΣΗ   = λόγος άρσης του κανόνα (defeater)· ΚΕΡΔΙΖΕΙ όταν είναι :in
;;;;               (και τότε η θέση πέφτει), ΧΑΝΕΙ όταν :out
;;;;   ΙΣΟΠΑΛΙΑ  = :undefined — ΔΗΛΩΝΕΤΑΙ ως αναποφάσιστη, ποτέ δεν κρύβεται
;;;; Το υπόμνημα βγαίνει δομημένο: θέση/ένσταση/τύχη καθεμιάς, όλα με πηγή.

(defpackage :orchestrator.dialectic
  (:use :cl)
  (:export #:dialectic-report))

(in-package :orchestrator.dialectic)

(defun dialectic-report (facts &key (norms (orchestrator.subsumption:case-norms))
                                    (stream *standard-output*))
  "Το ΥΠΟΜΝΗΜΑ της αντιδικίας πάνω στα FACTS: για κάθε κανόνα με ΠΛΗΡΗ ειδική
   υπόσταση, η θέση ΚΑΙ οι ενστάσεις (λόγοι άρσης) με την τύχη τους — απόδειξη
   παντού, ισοπαλία δηλωμένη. Επιστρέφει (values θέσεις-όρθιες ενστάσεις-νικήτριες
   αναποφάσιστα)."
  (multiple-value-bind (engine) (orchestrator.subsumption:subsume facts :norms norms)
    (let ((jtms (orchestrator.inference:engine-jtms engine))
          (standing 0) (upheld-objections 0) (undecided 0))
      (format stream "~%── ΑΝΤΙΔΙΚΙΑ: θέση ↔ ένσταση, με αποδείξεις ──~%")
      (dolist (nm norms)
        (when (orchestrator.deontic:norm-antecedent nm)
          (multiple-value-bind (status datum binding)
              (orchestrator.subsumption:conclusion-status engine nm facts)
            (unless (eq status :not-triggered)
              (format stream "~%▌ Κανόνας ~A (άρθρο ~A ~A):~%"
                      (orchestrator.deontic:norm-id nm)
                      (orchestrator.deontic:norm-article nm)
                      (orchestrator.deontic:norm-corpus nm))
              ;; Η ΘΕΣΗ
              (case status
                (:in
                 (incf standing)
                 (format stream "  ΘΕΣΗ — ΙΣΤΑΤΑΙ:~%~A"
                         (orchestrator.inference:explanation->string
                          (orchestrator.inference:explain jtms datum) 3)))
                (:out
                 (format stream "  ΘΕΣΗ — ΠΙΠΤΕΙ (βλ. ένσταση παρακάτω)~%"))
                (:undefined
                 (incf undecided)
                 (format stream "  ΘΕΣΗ — ΑΝΑΠΟΦΑΣΙΣΤΗ: ισοπαλία επιχειρημάτων, δηλωμένη~%")))
              ;; ΟΙ ΕΝΣΤΑΣΕΙΣ (λόγοι άρσης), καθεμία με την τύχη της
              (dolist (d (orchestrator.deontic:norm-defeaters nm))
                (let* ((inst (orchestrator.inference:instantiate d binding))
                       (dstat (orchestrator.inference:fact-status jtms inst)))
                  (case dstat
                    (:in
                     (incf upheld-objections)
                     (format stream "  ΕΝΣΤΑΣΗ ~S — ΚΕΡΔΙΖΕΙ:~%~A"
                             inst
                             (orchestrator.inference:explanation->string
                              (orchestrator.inference:explain jtms inst) 3)))
                    (:undefined
                     (format stream "  ΕΝΣΤΑΣΗ ~S — ΑΝΑΠΟΦΑΣΙΣΤΗ (μετέωρη — γι' αυτό και η θέση)~%" inst))
                    (t
                     (format stream "  ΕΝΣΤΑΣΗ ~S — δεν θεμελιώνεται στα γεγονότα~%" inst)))))))))
      (format stream "~%  Σύνοψη: ~D θέσεις ίστανται · ~D ενστάσεις κερδίζουν · ~D αναποφάσιστα~%"
              standing upheld-objections undecided)
      (values standing upheld-objections undecided))))
