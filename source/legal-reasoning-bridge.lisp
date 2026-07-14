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
  (:export #:reference-facts #:reason-impact #:impact-report
           ;; [0088 Φ5γ] TRUST-01: θεμελιωμένος συλλογισμός με receipt-ids
           #:grounded-impact #:ungrounded-reasoning #:ungrounded-why))

(in-package :orchestrator.reasoning)

(define-condition ungrounded-reasoning (error)
  ;; [0088 Φ5-κριτής Β 4.1] TYPED: ο αθεμελίωτος συλλογισμός δεν είναι γενικό
  ;; error — είναι ρητή άρνηση εκτέλεσης πάνω σε μη-δεσμευμένο θεμέλιο.
  ((why :initarg :why :reader ungrounded-why))
  (:report (lambda (c s) (format s "Αθεμελίωτος συλλογισμός: ~A" (ungrounded-why c)))))

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

(defun %bare-label (id)
  "eId «art_299»/«299» → «299» (η μία κανονικοποίηση προς την identity έδρα)."
  (let ((s (princ-to-string (or id ""))))
    (if (and (>= (length s) 4) (string-equal "art_" (subseq s 0 4))) (subseq s 4) s)))

(defun grounded-impact (doc code article &key body graph receipts valid-at known-at)
  "[0088 Φ5γ — θάνατος TRUST-01] Impact analysis όπου ΚΑΘΕ συμπέρασμα είναι
   ΘΕΜΕΛΙΩΜΕΝΟ στη διτεμπορική τομή (VALID-AT, KNOWN-AT):
     • η δομή (ποιος παραπέμπει ποιον) έρχεται από το reason-impact (JTMS proof),
     • η ΥΠΟΣΤΑΣΗ κάθε εμπλεκόμενης διάταξης επιλύεται με version-at στον
       ΓΡΑΦΟ (όχι γυμνό citation graph) και δένεται με το receipt της:
       {provision-id, receipt-id, content-hash, valid-from}.
   ΟΛΑ τα keys ΥΠΟΧΡΕΩΤΙΚΑ (καμία σιωπηλή «τώρα»/αθεμελίωτη τομή). RECEIPTS:
   λίστα ή hash provision-id→receipt (π.χ. από build-receipts-for-graph στην
   ΙΔΙΑ τομή). Επιστρέφει (values grounded ungrounded), όπου grounded =
   plists (:article :provision-id :receipt-id :content-hash :valid-from
   :proof) και ungrounded = plists (:article :provision-id :why) — διάταξη
   χωρίς επιλύσιμη έκδοση/receipt στην τομή ΔΗΛΩΝΕΤΑΙ, δεν σερβίρεται ως
   συμπέρασμα. Το ΙΔΙΟ το ερωτώμενο άρθρο πρέπει να θεμελιώνεται, αλλιώς
   σφάλμα — συλλογισμός πάνω σε ανύπαρκτη-στην-τομή διάταξη δεν εκτελείται."
  (unless (and body graph receipts valid-at known-at)
    (error 'ungrounded-reasoning
           :why "body/graph/receipts/valid-at/known-at ΟΛΑ υποχρεωτικά — δεν εκτελείται (TRUST-01)"))
  (unless (equal (orchestrator.identity:body-id-string body)
                 (orchestrator.version-graph:graph-body graph))
    (error 'ungrounded-reasoning
           :why (format nil "BODY ~A ≠ σώμα του γράφου ~A"
                        (orchestrator.identity:body-id-string body)
                        (orchestrator.version-graph:graph-body graph))))
  (let* ((index (if (hash-table-p receipts)
                    receipts
                    (let ((h (make-hash-table :test 'equal)))
                      (dolist (r receipts h)
                        (setf (gethash (orchestrator.legal-receipt:lr-provision-id r) h) r)))))
         (grounded '()) (ungrounded '()))
    (flet ((ground (label)
             ;; (values plist-ή-nil why) για ΜΙΑ διάταξη στην τομή
             (let ((pid (handler-case
                            (orchestrator.identity:provision-id-string
                             (orchestrator.identity:article-provision-id
                              body (%bare-label label)))
                          (error (e) (return-from ground
                                       (values nil (format nil "άκυρη ταυτότητα: ~A" e)))))))
               (handler-case
                   (multiple-value-bind (v basis)
                       (orchestrator.version-graph:version-at
                        graph pid :valid-at valid-at :known-at known-at)
                     (declare (ignore basis))
                     (if (null v)
                         (values nil (format nil "~A: καμία έκδοση στην τομή" pid))
                         (let ((r (gethash pid index)))
                           (cond
                             ((null r)
                              (values nil (format nil "~A: χωρίς receipt στην τομή" pid)))
                             ((not (equal (orchestrator.legal-receipt:lr-content-hash r)
                                          (orchestrator.version-graph:tv-version-hash v)))
                              (values nil (format nil "~A: receipt ≠ έκδοση τομής" pid)))
                             (t (values (list :provision-id pid
                                              :receipt-id (orchestrator.legal-receipt:lr-receipt-id r)
                                              :content-hash (orchestrator.version-graph:tv-version-hash v)
                                              :valid-from (orchestrator.version-graph:tv-valid-from v))
                                        nil))))))
                 (orchestrator.version-graph:temporal-uncertainty (e)
                   (values nil (format nil "~A: δηλωμένη αβεβαιότητα (~A)" pid e)))
                 (orchestrator.version-graph:unknown-provision ()
                   (values nil (format nil "~A: άγνωστη διάταξη στον γράφο" pid)))))))
      ;; το ερωτώμενο άρθρο ΠΡΕΠΕΙ να θεμελιώνεται
      (multiple-value-bind (g why) (ground article)
        (unless g
          (error 'ungrounded-reasoning
                 :why (format nil "το ερωτώμενο άρθρο ~A δεν θεμελιώνεται στην τομή (~A, ~A): ~A"
                              article valid-at known-at why))))
      (dolist (r (reason-impact doc code article))
        (multiple-value-bind (g why) (ground (car r))
          (if g
              (push (append (list :article (%bare-label (car r))) g
                            (list :proof (cdr r)))
                    grounded)
              (push (list :article (%bare-label (car r)) :why why) ungrounded))))
      (values (nreverse grounded) (nreverse ungrounded)))))

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
