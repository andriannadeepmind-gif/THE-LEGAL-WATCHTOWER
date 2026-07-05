;;;; source/legal-deontic.lisp
;;;; ============================================================================
;;;; BRAIN L5 — ΔΕΟΝΤΙΚΟ ΕΠΙΠΕΔΟ: τι ΠΡΟΣΤΑΖΕΙ ο κανόνας (O / F / P), όχι ποιος
;;;; παραπέμπει σε ποιον
;;;; ============================================================================
;;;;
;;;; Ο γράφος παραπομπών ξέρει «ποιος δείχνει σε ποιον». Οι εγκέφαλοι L1–L4 ξέρουν
;;;; επίπτωση αλλαγής, σύγκρουση πηγών, χρόνο, δεδικασμένο. Κανένας όμως δεν ξέρει
;;;; ΤΙ ΠΡΟΣΤΑΖΕΙ μια διάταξη: υποχρέωση, απαγόρευση ή άδεια. Αυτό είναι το δεοντικό
;;;; περιεχόμενο του κανόνα — και είναι η προϋπόθεση για να πει το σύστημα «αυτοί οι
;;;; δύο κανόνες συγκρούονται ΚΑΝΟΝΙΣΤΙΚΑ» (ο ένας επιτάσσει ό,τι ο άλλος απαγορεύει),
;;;; πέρα από τη σύγκρουση πηγών.
;;;;
;;;; Καμία νέα μηχανή: πατά στο ΙΔΙΟ well-founded JTMS (orchestrator.inference) και
;;;; ΓΕΦΥΡΩΝΕΤΑΙ με την υπάρχουσα επίλυση συγκρούσεων (orchestrator.conflict: lex
;;;; superior/specialis/posterior) — η δεοντική σύγκρουση γίνεται (:conflict …) και
;;;; την κρίνει ο υπάρχων L2, με το δικό του δέντρο απόδειξης. Ευθυγραμμίζεται με τη
;;;; δεοντική τυπολογία της οντολογίας (obligation/prohibition/permission).
;;;;
;;;; Ένας ΚΑΝΟΝΑΣ (norm) γεννιέται — όπως κάθε ισχυρισμός του συστήματος — ΜΕ ΠΗΓΗ
;;;; (0 λάθος: κανένα κανονιστικό περιεχόμενο ανώνυμα). Το ΠΟΙΑ διάταξη εκφράζει
;;;; ποιον δεοντικό τύπο είναι εξαγωγή από το κείμενο (νευρο-συμβολικό: ο σύμβουλος
;;;; προτείνει, ο συμβολικός πυρήνας επαληθεύει) — εδώ ζει η ΜΗΧΑΝΗ και ο πυρήνας·
;;;; η μαζική τροφοδότηση όλου του corpus είναι το επόμενο, δηλωμένο βήμα, ΟΧΙ
;;;; προσποιητό δεδομένο.
;;;;
;;;; Λεξιλόγιο (facts):
;;;;   (:norm ID MODALITY SOURCE)             — ένας κανόνας, με προέλευση (πηγή)
;;;;   (:norm-scope ID SCOPE)                 — πεδίο (:penal/:civil/:procedural…)
;;;;   <antecedent literals>                  — οι προϋποθέσεις εφαρμογής του (case facts)
;;;; Παράγωγα:
;;;;   (:deontic MODALITY ACT :by ID)         — η δεοντική θέση για μια συγκεκριμένη πράξη
;;;;   (:deontic-conflict ACT IDA IDB)        — δύο κανόνες σε κανονιστική σύγκρουση
;;;;   (:conflict CA A CB B)                  — γέφυρα προς τον L2 (κρίνεται εκεί)

(defpackage :orchestrator.deontic
  (:use :cl :orchestrator.inference)
  (:export #:norm #:make-norm #:norm-p #:norm-id #:norm-modality #:norm-antecedent
           #:norm-consequent #:norm-scope #:norm-source #:norm-corpus #:norm-article
           #:norm-defeaters
           #:*norms* #:register-norm #:all-norms #:clear-norms #:find-norm
           #:norm-facts #:seed-norms #:apply-norms
           #:evaluate-deontic #:deontic-report))

(in-package :orchestrator.deontic)

;;; ============================================================================
;;; Ο ΚΑΝΟΝΑΣ ως first-class δομή — με ΠΗΓΗ εκ κατασκευής
;;; ============================================================================

(defstruct (norm (:constructor %make-norm))
  (id        nil :read-only t)   ; μοναδικό αναγνωριστικό — άγκυρα προέλευσης
  (modality  nil :read-only t)   ; :obligation / :prohibition / :permission
  (antecedent nil :read-only t)  ; λίστα προϋποθέσεων (conjunction, με ?vars)· nil = ανεπιφύλακτος
  (consequent nil :read-only t)  ; η ρυθμιζόμενη πράξη (literal, μοιράζεται ?vars με το antecedent)
  (scope     nil :read-only t)   ; πεδίο δικαίου — για lex specialis/mitior
  (source    nil :read-only t)   ; ΠΗΓΗ «corpus:article» — ΥΠΟΧΡΕΩΤΙΚΗ
  (defeaters nil :read-only t))  ; ΛΟΓΟΙ ΑΡΣΗΣ (:unless patterns, μοιράζονται ?vars
                                 ; με το antecedent) — η αναιρεσιμότητα του κανόνα

(defparameter +modalities+ '(:obligation :prohibition :permission)
  "Οι δεοντικοί τελεστές, ευθυγραμμισμένοι με την τυπολογία της οντολογίας.")

(defun make-norm (&key id modality antecedent consequent scope source defeaters)
  "Κατασκεύασε κανόνα, επιβάλλοντας τα αναλλοίωτα: μοναδικό id, έγκυρη δεοντική
   τυπικότητα, ρυθμιζόμενη πράξη, και ΠΗΓΗ (καμία κανονιστική δήλωση ανώνυμα)."
  (unless id (error "κανόνας ΧΩΡΙΣ id — αδύνατο"))
  (unless (member modality +modalities+)
    (error "άγνωστη δεοντική τυπικότητα ~S — αναμένεται μία από ~S" modality +modalities+))
  (unless consequent (error "κανόνας ~S ΧΩΡΙΣ ρυθμιζόμενη πράξη (consequent)" id))
  (unless (and source (stringp source) (find #\: source))
    (error "κανόνας ~S ΧΩΡΙΣ έγκυρη πηγή «corpus:article» — προέλευση εκ κατασκευής" id))
  (%make-norm :id id :modality modality :antecedent antecedent
              :consequent consequent :scope scope :source source
              :defeaters defeaters))

(defun norm-corpus (norm)
  "Ο κώδικας-πηγή, από το «corpus:article»."
  (let ((s (norm-source norm))) (subseq s 0 (position #\: s))))
(defun norm-article (norm)
  "Το άρθρο-πηγή, από το «corpus:article»."
  (let ((s (norm-source norm))) (subseq s (1+ (position #\: s)))))

;;; ── Μητρώο κανόνων (open set· η μαζική τροφοδότηση έρχεται από την εξαγωγή) ──
(defvar *norms* (make-hash-table :test 'equal :synchronized t)
  "Οι εγγεγραμμένοι κανόνες, ανά id — synchronized: η έγκριση γράφει και το serve διαβάζει.")
(defun register-norm (norm) (setf (gethash (norm-id norm) *norms*) norm) norm)
(defun find-norm (id) (gethash id *norms*))
(defun all-norms () (loop for n being the hash-values of *norms* collect n))
(defun clear-norms () (clrhash *norms*))

;;; ============================================================================
;;; Εφαρμογή κανόνων — data-driven πάνω στο ΙΔΙΟ JTMS (unify + tms-justify)
;;; ============================================================================

;;; Το συζευκτικό ταίριασμα είναι το ΕΝΑ του συστήματος: match-patterns του
;;; engine (ευρετηριασμένο, Φάση 2) — καμία δεύτερη υλοποίηση join εδώ.

(defun norm-facts (&optional (norms (all-norms)))
  "Τα premises προέλευσης κάθε κανόνα — ώστε ο κανόνας να είναι ερωτήσιμος και
   κάθε δεοντική θέση να πατά (και) στην πηγή του."
  (loop for n in norms
        collect (list :norm (norm-id n) (norm-modality n) (norm-source n)) into fs
        when (norm-scope n)
          collect (list :norm-scope (norm-id n) (norm-scope n)) into fs
        finally (return fs)))

(defun seed-norms (engine &optional (norms (all-norms)))
  "Φόρτωσε τα premises προέλευσης των κανόνων στον engine."
  (add-facts engine (norm-facts norms))
  engine)

(defun apply-norms (engine &optional (norms (all-norms)))
  "Για κάθε κανόνα του οποίου η σύζευξη προϋποθέσεων ικανοποιείται από τα
   πιστευόμενα facts, δικαιολόγησε τη δεοντική θέση (:deontic MODALITY ACT :by ID)
   στο JTMS — in-list οι προϋποθέσεις που ταίριαξαν (ή η πηγή, για ανεπιφύλακτο
   κανόνα). Καμία νέα μηχανή· η θέση φέρει το δικό της δέντρο απόδειξης."
  (let ((jtms (engine-jtms engine)))
    (recompute-beliefs jtms)
    ;; ΕΝΑ ευρετήριο για ΟΛΟΥΣ τους κανόνες — όχι σάρωση των facts ανά κανόνα
    (let ((facts (make-fact-index (jtms-believed-facts jtms))))
      (dolist (nm norms)
        (dolist (state (match-patterns (norm-antecedent nm) facts))
          (destructuring-bind (binding . used) state
            (let* ((act (instantiate (norm-consequent nm) binding))
                   (datum (list :deontic (norm-modality nm) act :by (norm-id nm)))
                   (support (or used
                                (list (list :norm (norm-id nm)
                                            (norm-modality nm) (norm-source nm)))))
                   ;; Σ4: οι ΛΟΓΟΙ ΑΡΣΗΣ του κανόνα, στιγμιοποιημένοι υπό το ίδιο
                   ;; binding, γίνονται defeaters της αιτιολόγησης — η αναιρεσιμότητα
                   ;; κρίνεται από το well-founded μοντέλο, όχι από εμάς
                   (outs (mapcar (lambda (d) (instantiate d binding))
                                 (norm-defeaters nm))))
              (tms-justify jtms datum
                           (mapcar (lambda (d) (tms-intern jtms d)) support)
                           (mapcar (lambda (d) (tms-intern jtms d)) outs)
                           (norm-id nm)))))))
    (recompute-beliefs jtms)
    engine))

;;; ============================================================================
;;; ΔΕΟΝΤΙΚΟΙ ΚΑΝΟΝΕΣ — σύγκρουση κανονιστική + γέφυρα προς τον L2
;;; ============================================================================

;; Κανονιστική σύγκρουση: ο ένας κανόνας ΕΠΙΤΑΣΣΕΙ ό,τι ο άλλος ΑΠΑΓΟΡΕΥΕΙ.
;; Αυτό δεν είναι σύγκρουση πηγών — είναι σύγκρουση περιεχομένου (O(a) ∧ F(a)).
(defrule deontic-conflict-obligation-vs-prohibition
  :when ((:deontic :obligation ?act :by ?na)
         (:deontic :prohibition ?act :by ?nb))
  :then (:deontic-conflict ?act ?na ?nb))

;; Ρητή ΑΔΕΙΑ έναντι ΑΠΑΓΟΡΕΥΣΗΣ της ίδιας πράξης: επίσης κανονιστική σύγκρουση —
;; ποιος υπερισχύει το κρίνει ο L2 (η ειδικότερη/υπέρτερη/μεταγενέστερη διάταξη).
(defrule deontic-conflict-permission-vs-prohibition
  :when ((:deontic :permission ?act :by ?np)
         (:deontic :prohibition ?act :by ?nf))
  :then (:deontic-conflict ?act ?np ?nf))

;; ΓΕΦΥΡΑ προς τον L2: η δεοντική σύγκρουση δύο κανόνων γίνεται σύγκρουση των
;; διατάξεων-πηγών τους, ώστε lex superior/specialis/posterior να αποφανθεί ΠΟΙΟΣ
;; υπερισχύει — χωρίς να ξαναγραφεί καμία λογική επίλυσης.
(defrule deontic-conflict-bridges-to-sources
  :when ((:deontic-conflict ?act ?na ?nb)
         (:norm ?na ?ma ?sa)
         (:norm ?nb ?mb ?sb))
  :then (:conflict-of-norms ?sa ?sb :on ?act :from ?na ?nb))

(defun evaluate-deontic (case-facts &optional (norms (all-norms)))
  "Ο πλήρης δεοντικός κύκλος πάνω σε μια υπόθεση: φόρτωσε τα case-facts + την
   προέλευση των κανόνων, εφάρμοσε τους κανόνες (δεοντικές θέσεις), τρέξε τους
   κανόνες σύγκρουσης. Επιστρέφει (values engine deontic-positions deontic-conflicts)."
  (let ((engine (make-inference-engine)))
    (add-facts engine case-facts)
    (seed-norms engine norms)
    (apply-norms engine norms)
    (run-inference engine)
    (apply-norms engine norms)          ; νέα facts μπορεί να ενεργοποίησαν κι άλλους κανόνες
    (run-inference engine)
    (values engine
            (query engine '(:deontic ?m ?act :by ?n))
            (query engine '(:deontic-conflict ?act ?na ?nb)))))

(defun deontic-report (case-facts &optional (norms (all-norms))
                                            (stream *standard-output*))
  "Τρέξε τον δεοντικό κύκλο και τύπωσε τις δεοντικές θέσεις + κάθε κανονιστική
   σύγκρουση ΜΕ ΤΟ ΔΕΝΤΡΟ ΑΠΟΔΕΙΞΗΣ της. Επιστρέφει (values n-positions n-conflicts)."
  (multiple-value-bind (engine positions conflicts) (evaluate-deontic case-facts norms)
    (let ((label (lambda (m) (ecase m (:obligation "ΟΦΕΙΛΕΙ")
                                       (:prohibition "ΑΠΑΓΟΡΕΥΕΤΑΙ")
                                       (:permission "ΕΠΙΤΡΕΠΕΤΑΙ")))))
      (format stream "~%── ΔΕΟΝΤΙΚΗ ΑΝΑΛΥΣΗ: ~D θέσεις · ~D κανονιστικές συγκρούσεις ──~%"
              (length positions) (length conflicts))
      (loop for (fact . nil) in positions do
        (destructuring-bind (kw m act by n) fact (declare (ignore kw by))
          (format stream "  • ~A: ~S  [~A ~A]~%"
                  (funcall label m) act n
                  (let ((nm (find-norm n))) (if nm (norm-source nm) ";")))))
      (loop for (fact . nil) in conflicts do
        (destructuring-bind (kw act na nb) fact (declare (ignore kw))
          (format stream "~%  ⚔ ΚΑΝΟΝΙΣΤΙΚΗ ΣΥΓΚΡΟΥΣΗ επί ~S: ~A ↔ ~A~%~A~%"
                  act na nb
                  (explanation->string (explain (engine-jtms engine) fact) 6))))
      (values (length positions) (length conflicts)))))
