;;;; source/legal-subsumption.lisp
;;;; ============================================================================
;;;; Σ4 — ΥΠΑΓΩΓΗ: πραγματικά περιστατικά → κανόνες → συμπέρασμα ΜΕ απόδειξη
;;;; ============================================================================
;;;;
;;;; Το θεμέλιο της σκάλας νόησης (ΧΑΡΤΗΣ-ΝΟΗΣΗΣ Σ4): μια ΥΠΟΘΕΣΗ είναι σύνολο
;;;; γεγονότων (:γεγονός <υποκείμενο> <κατηγόρημα> <αντικείμενο> …) και η υπαγωγή
;;;; είναι η εφαρμογή των norms του L5 — που τώρα φέρουν ΕΙΔΙΚΗ ΥΠΟΣΤΑΣΗ
;;;; (antecedent) και ΛΟΓΟΥΣ ΑΡΣΗΣ (defeaters) — πάνω στο ΙΔΙΟ well-founded JTMS.
;;;; ΚΑΜΙΑ νέα μηχανή: ο κύκλος είναι ο evaluate-deontic του L5.
;;;;
;;;; Εδώ ΞΥΠΝΑ και ο μετα-εγκέφαλος (orchestrator.knowledge): το satisfy-patterns
;;;; απαντά «ΤΙ ΛΕΙΠΕΙ για να στοιχειοθετηθεί ο κανόνας» — η μετα-γνώση της
;;;; άγνοιας, το πιο πολύτιμο εργαλείο του δικηγόρου.
;;;;
;;;; Η γνώση των ειδικών υποστάσεων μπαίνει ΩΣ ΓΝΩΣΗ (πακέτο :tatbestand),
;;;; υπό το ίδιο επιστημικό καθεστώς με όλα: SHA, ζωντανή φόρτωση, σκιώδης
;;;; εκτέλεση, ποτέ ανώνυμα (κάθε κανόνας με πηγή «corpus:article»).

(defpackage :orchestrator.subsumption
  (:use :cl)
  (:export #:subsume #:subsumption-report #:norm-gaps #:conclusion-status #:case-norms
           #:parse-case-facts #:narrate-position #:proof-grade
           #:norm-planning-rules))

(in-package :orchestrator.subsumption)

;;; ── Ανάγνωση γεγονότων υπόθεσης (από CLI/πακέτα): keyword package, χωρίς eval.
;;; Μεταβλητές: :?χ (keyword με «?») → πραγματικές μεταβλητές ενοποίησης.
;;; ΔΗΛΩΜΕΝΟΣ μετασχηματισμός — τα πακέτα διαβάζονται σε keyword package,
;;; οι μεταβλητές του engine είναι non-keyword σύμβολα με πρόθεμα «?».

(defun %devar (tree)
  "Κάθε keyword :?Χ του δέντρου γίνεται μεταβλητή ενοποίησης ?Χ."
  (cond ((consp tree) (mapcar #'%devar tree))
        ((and (keywordp tree) (plusp (length (symbol-name tree)))
              (char= (char (symbol-name tree) 0) #\?))
         (intern (symbol-name tree) :orchestrator.subsumption))
        (t tree)))

(defun parse-case-facts (string)
  "Διάβασε γεγονότα υπόθεσης από STRING — λίστα από tuples, *read-eval* nil,
   keyword package (καμία εκτέλεση κώδικα από δεδομένα)."
  (let ((*read-eval* nil)
        (*package* (find-package :keyword)))
    (let ((form (read-from-string string)))
      (unless (and (listp form) (every #'consp form))
        (error "περιμένω λίστα γεγονότων ((:γεγονός …) …), βρέθηκε: ~S" form))
      (%devar form))))

;;; ── Η ΥΠΑΓΩΓΗ: ο κύκλος του L5, με τους κανόνες-ειδικές υποστάσεις ──

(defun case-norms ()
  "Οι κανόνες που ΥΠΑΓΟΥΝ: μόνο όσοι έχουν ΕΙΔΙΚΗ ΥΠΟΣΤΑΣΗ (antecedent). Οι
   ανεπιφύλακτοι (πχ δεοντικές ταξινομήσεις διατάξεων) ρυθμίζουν ΚΕΙΜΕΝΑ, όχι
   πραγματικά περιστατικά — δεν συμμετέχουν στην υπαγωγή υπόθεσης."
  (remove-if-not #'orchestrator.deontic:norm-antecedent
                 (orchestrator.deontic:all-norms)))

(defun norm-planning-rules (&optional (norms (case-norms)))
  "Η όψη των δεοντικών κανόνων ως ΚΑΝΟΝΩΝ ΣΧΕΔΙΑΣΜΟΥ (ίδια σημασιολογία,
   καμία αντιγραφή): :when = ειδική υπόσταση, :unless = λόγοι άρσης,
   :then = η δεοντική θέση. Δένεται στο orchestrator.knowledge:*extra-rules*
   ώστε ο σχεδιαστής απόδειξης (plan-goal/pursue/think) να συλλογίζεται
   ΑΝΑΠΟΔΑ πάνω στο tatbestand — «τι πρέπει να αποδειχθεί για να…»."
  (loop for nm in norms
        collect (make-instance 'orchestrator.inference:legal-rule
                  :name (orchestrator.deontic:norm-id nm)
                  :when (orchestrator.deontic:norm-antecedent nm)
                  :unless (orchestrator.deontic:norm-defeaters nm)
                  :then (list :deontic (orchestrator.deontic:norm-modality nm)
                              (orchestrator.deontic:norm-consequent nm)
                              :by (orchestrator.deontic:norm-id nm)))))

(defun subsume (facts &key (norms (case-norms)))
  "Υπάγαγε τα ΓΕΓΟΝΟΤΑ στους κανόνες. Επιστρέφει (values engine θέσεις) όπου
   θέσεις = ((datum . proof-tree)…) για κάθε αποδεδειγμένη δεοντική θέση.
   Ο ΙΔΙΟΣ κύκλος με τον L5 (evaluate-deontic) — καμία δεύτερη μηχανή."
  (multiple-value-bind (engine positions)
      (orchestrator.deontic:evaluate-deontic (append facts *taxonomy*) norms)
    (let ((out (loop for (datum . nil) in positions
                     collect (cons datum
                                   (orchestrator.inference:explain
                                    (orchestrator.inference:engine-jtms engine) datum)))))
      ;; ΙΧΝΟΣ ΠΡΟΕΛΕΥΣΗΣ: το νομικό συμπέρασμα δένεται στην ΠΡΑΓΜΑΤΙΚΗ εκτέλεση —
      ;; γεγονότα-είσοδος, κανόνες που πυροδότησαν, θέσεις, δεσμός απόδειξης.
      (let ((id (orchestrator.trace:emit! :conclusion
                 :symbol "subsume" :package "orchestrator.subsumption"
                 :source "source/legal-subsumption.lisp"
                 :data (list :facts-count (length facts)
                             :rules (remove-duplicates
                                     (loop for (datum . nil) in out
                                           for tail = (member :by datum)
                                           when tail collect (second tail))
                                     :test #'equal)
                             :positions (mapcar #'car out)
                             :positions-p (and out t)
                             :proofs-p (and (every #'cdr out) t)))))
        (when id (orchestrator.trace:note-conclusion! id)))
      (values engine out))))

(defun conclusion-status (engine norm facts)
  "Η ΤΡΙΤΙΜΗ τύχη του συμπεράσματος του NORM πάνω στα FACTS: (values status
   datum binding) με status :in/:undefined/:out/:not-triggered. Το binding
   προκύπτει από την πλήρη ικανοποίηση της ειδικής υπόστασης (μετα-εγκέφαλος)."
  (multiple-value-bind (binding satisfied missing)
      (orchestrator.knowledge:satisfy-patterns
       (orchestrator.deontic:norm-antecedent norm)
       ;; πάνω στα ΠΙΣΤΕΥΟΜΕΝΑ — περιλαμβάνουν και τα παράγωγα των γενών
       ;; (συλλογισμός Barbara), όχι μόνο τα ρητώς δοθέντα
       (orchestrator.inference:jtms-believed-facts
        (orchestrator.inference:engine-jtms engine))
       '())
    (declare (ignore satisfied facts))
    (if missing
        (values :not-triggered nil nil)
        (let ((datum (list :deontic (orchestrator.deontic:norm-modality norm)
                           (orchestrator.inference:instantiate
                            (orchestrator.deontic:norm-consequent norm) binding)
                           :by (orchestrator.deontic:norm-id norm))))
          (values (orchestrator.inference:fact-status
                   (orchestrator.inference:engine-jtms engine) datum)
                  datum binding)))))

(defun norm-gaps (norm facts)
  "ΤΙ ΛΕΙΠΕΙ για να στοιχειοθετηθεί ο NORM στα FACTS — η μετα-γνώση της άγνοιας
   (ο κοιμισμένος μετα-εγκέφαλος, ξύπνιος): (values έχει λείπουν binding)."
  (multiple-value-bind (binding have missing)
      (orchestrator.knowledge:satisfy-patterns
       (orchestrator.deontic:norm-antecedent norm) facts '())
    (values (mapcar (lambda (p) (orchestrator.inference:instantiate p binding)) have)
            (mapcar (lambda (p) (orchestrator.inference:instantiate p binding)) missing)
            binding)))

;;; ── Σ10: ΠΡΟΕΛΕΥΣΙΑΚΗ ΒΕΒΑΙΟΤΗΤΑ — από ΤΙ στηρίζεται η απόδειξη ──
;;; Όχι πιθανότητες-μαντεψιές: κάθε φύλλο του δέντρου ταξινομείται κατά το
;;; ΕΙΔΟΣ του ερείσματος, και ο βαθμός του συμπεράσματος είναι ο ΑΣΘΕΝΕΣΤΕΡΟΣ
;;; ΚΡΙΚΟΣ — αυτό λέει στον δικηγόρο ΤΙ πρέπει να αποδείξει στο ακροατήριο.

(defparameter +grade-order+
  '(:κανόνας-πηγής :γνώση-κατηγοριών :δεδομένο-υπόθεσης)
  "Ιεραρχία ερεισμάτων, ισχυρότερο→ασθενέστερο: κανόνας με πηγή νόμου >
   δηλωμένη γνώση κατηγοριών > δεδομένο υπόθεσης (θέλει απόδειξη στο ακροατήριο).")

(defun %leaf-grade (datum)
  (cond ((and (consp datum) (member (first datum) '(:γένος :διαίρεσις)))
         :γνώση-κατηγοριών)
        ((and (consp datum) (eq (first datum) :norm)) :κανόνας-πηγής)
        (t :δεδομένο-υπόθεσης)))

(defun proof-grade (proof)
  "(values ασθενέστερος-κρίκος ανάλυση): περπάτα το δέντρο απόδειξης, ταξινόμησε
   κάθε φύλλο-δεδομένο, και βαθμολόγησε το όλον από τον ασθενέστερο κρίκο του."
  (let ((seen '()))
    (labels ((walk (p)
               (case (first p)
                 (:premise (pushnew (%leaf-grade (second p)) seen))
                 (:derived
                  ;; ο κανόνας που παράγει το βήμα είναι κι αυτός έρεισμα:
                  ;; πληροφοριοδότης (:by) εγγεγραμμένος κανόνας με πηγή νόμου
                  ;; ⇒ μετρά ως :κανόνας-πηγής
                  (let ((by (getf (cddr p) :by)))
                    (when (and by (keywordp by) (orchestrator.deontic:find-norm by))
                      (pushnew :κανόνας-πηγής seen)))
                  (mapc #'walk (getf (cddr p) :from)))
                 (t nil))))
      (walk proof))
    (values (find-if (lambda (g) (member g seen)) (reverse +grade-order+))
            seen)))

;;; ── Αφήγηση σε σωστά ελληνικά ──

(defparameter +modality-phrases+
  '((:prohibition . "ΑΠΑΓΟΡΕΥΣΗ — στοιχειοθετείται")
    (:obligation  . "ΥΠΟΧΡΕΩΣΗ — στοιχειοθετείται")
    (:permission  . "ΑΔΕΙΑ — αναγνωρίζεται")))

(defun narrate-position (datum proof &optional (stream *standard-output*))
  "Αφήγηση μίας δεοντικής θέσης: τυπικότητα, πράξη, κανόνας+πηγή, ΑΠΟΔΕΙΞΗ."
  (destructuring-bind (kw modality act by id) datum
    (declare (ignore kw by))
    (let ((nm (orchestrator.deontic:find-norm id)))
      (multiple-value-bind (weakest kinds) (proof-grade proof)
        (format stream "~%  ⚖ ~A: ~S~%     κατά τον κανόνα ~A (άρθρο ~A ~A)~%~A     ΘΕΜΕΛΙΩΣΗ: ~{~(~A~)~^ + ~} — ασθενέστερος κρίκος: ~(~A~)~:[~; (θέλει απόδειξη στο ακροατήριο)~]~%"
                (or (cdr (assoc modality +modality-phrases+)) modality)
                act id
                (and nm (orchestrator.deontic:norm-article nm))
                (and nm (orchestrator.deontic:norm-corpus nm))
                (orchestrator.inference:explanation->string proof 5)
                kinds weakest (eq weakest :δεδομένο-υπόθεσης))))))

(defun subsumption-report (facts &key (norms (case-norms))
                                      (stream *standard-output*))
  "Η ΠΛΗΡΗΣ υπαγωγή: αποδεδειγμένες θέσεις με τα δέντρα τους, ΚΑΙ — για κάθε
   κανόνα που ΑΓΓΙΖΕΙ τα γεγονότα χωρίς να στοιχειοθετείται — ΤΙ ΛΕΙΠΕΙ.
   Επιστρέφει (values πλήθος-θέσεων πλήθος-κενών)."
  (multiple-value-bind (engine positions) (subsume facts :norms norms)
    (format stream "~%── ΥΠΑΓΩΓΗ: ~D γεγονότα · ~D κανόνες · ~D θέσεις ──~%"
            (length facts) (length norms) (length positions))
    (dolist (p positions)
      (narrate-position (car p) (cdr p) stream))
    ;; ΤΙ ΛΕΙΠΕΙ: κανόνες με ≥1 ικανοποιημένη προϋπόθεση αλλά όχι πλήρεις —
    ;; και κανόνες πλήρεις που ΑΝΑΙΡΕΘΗΚΑΝ (ο λόγος άρσης, ονομασμένος)
    (let ((gaps 0))
      (dolist (nm norms)
        (when (orchestrator.deontic:norm-antecedent nm)
          (multiple-value-bind (status datum binding) (conclusion-status engine nm facts)
            (declare (ignore datum))
            (case status
              (:not-triggered
               (multiple-value-bind (have missing) (norm-gaps nm facts)
                 (when have          ; αγγίζει την υπόθεση — αξίζει να πούμε τι λείπει
                   (incf gaps)
                   (format stream "~%  ◔ ~A (άρθρο ~A ~A): ΔΕΝ στοιχειοθετείται — έχω~{ ~S~}~%     ΛΕΙΠΕΙ:~{ ~S~}~%"
                           (orchestrator.deontic:norm-id nm)
                           (orchestrator.deontic:norm-article nm)
                           (orchestrator.deontic:norm-corpus nm)
                           have missing))))
              (:out
               (incf gaps)
               (let ((active (loop for d in (orchestrator.deontic:norm-defeaters nm)
                                   for inst = (orchestrator.inference:instantiate d binding)
                                   when (eq :in (orchestrator.inference:fact-status
                                                 (orchestrator.inference:engine-jtms engine) inst))
                                     collect inst)))
                 (format stream "~%  ⊘ ~A (άρθρο ~A ~A): η ειδική υπόσταση ΠΛΗΡΗΣ αλλά ΑΙΡΕΤΑΙ~@[ — λόγος άρσης:~{ ~S~}~]~%"
                         (orchestrator.deontic:norm-id nm)
                         (orchestrator.deontic:norm-article nm)
                         (orchestrator.deontic:norm-corpus nm)
                         active)))
              (:undefined
               (incf gaps)
               (format stream "~%  ◐ ~A: ΑΝΑΠΟΦΑΣΙΣΤΟ — ισοπαλία επιχειρημάτων, δηλωμένη (όχι κρυμμένη ως «όχι»)~%"
                       (orchestrator.deontic:norm-id nm)))))))
      (when (and (null positions) (zerop gaps))
        (format stream "  Κανένας εγγεγραμμένος κανόνας δεν αγγίζει αυτά τα γεγονότα — τίμια.~%"))
      (values (length positions) gaps))))

;;; ============================================================================
;;; ΟΡΓΑΝΟΝ — Κατηγορίαι + Αναλυτικά Πρότερα: η συλλογιστική των ΓΕΝΩΝ
;;; ============================================================================
;;;
;;; Ο πρώτος συλλογισμός του Αριστοτέλη (Barbara, 1ο σχήμα): «κάθε Σ είναι Γ·
;;; το χ είναι Σ· άρα το χ είναι Γ». Στη γλώσσα γεγονότων: αν (:γένος Σ Γ) και
;;; (:γεγονός ?x :είναι Σ), τότε (:γεγονός ?x :είναι Γ) — ΩΣ ΚΑΝΟΝΑΣ ΤΟΥ
;;; ΕΓΚΕΦΑΛΟΥ (defrule: MOP auto-discovery, μεταβατικό μέσω fixpoint), με
;;; απόδειξη σε κάθε βήμα. Έτσι η υπαγωγή δεν απαιτεί να ειπωθεί το αυτονόητο:
;;; «τα χρήματα είναι κινητό» έπεται από το γένος τους. Τα γένη = ΓΝΩΣΗ
;;; (πακέτο :taxonomy) — οι Κατηγορίαι ως δηλώσεις, όχι ως κώδικας.

(orchestrator.inference:defrule syllogism-barbara
  :when ((:γεγονός ?x :είναι ?είδος)
         (:γένος ?είδος ?γένος))
  :then (:γεγονός ?x :είναι ?γένος))

;; Barbara ΥΠΟ ΟΡΟΥΣ — γένος ΜΕ ΔΙΑΦΟΡΑ (η αναφορική πρόταση του νόμου):
;; «τα βιβλία ΠΟΥ ΤΗΡΟΥΝ οι έμποροι θεωρούνται ιδιωτικά έγγραφα» ⇒ ο δεσμός
;; ισχύει ΜΟΝΟ για το x που φέρει τον όρο. ΔΗΛΩΜΕΝΟ ΟΡΙΟ: μία διαφορά ανά
;; δεσμό (κατηγόρημα+τιμή) — η συνήθης μορφή των νομοθετικών ορισμών.
(orchestrator.inference:defrule syllogism-barbara-conditional
  :when ((:γεγονός ?x :είναι ?είδος)
         (:γένος-όταν ?είδος ?γένος ?όρος ?τιμή)
         (:γεγονός ?x ?όρος ?τιμή))
  :then (:γεγονός ?x :είναι ?γένος))

;; Περί Ερμηνείας — η ΑΡΧΗ ΤΗΣ ΜΗ-ΑΝΤΙΦΑΣΗΣ: όταν δύο είδη δηλωμένα ΔΙΑΙΡΕΤΑ
;; (:διαίρεσις Α Β — αντικείμενα δεν είναι και τα δύο) αποδοθούν στο ίδιο
;; πράγμα, η ΑΝΤΙΦΑΣΗ γίνεται συμπέρασμα με απόδειξη — ποτέ σιωπηλή ασυνέπεια.
(orchestrator.inference:defrule non-contradiction
  :when ((:γεγονός ?x :είναι ?α)
         (:διαίρεσις ?α ?β)
         (:γεγονός ?x :είναι ?β))
  :then (:αντίφασις ?x ?α ?β))

(defvar *taxonomy* '()
  "Οι δηλωμένες σχέσεις γένους — μπαίνουν ως premises σε κάθε υπαγωγή.")

(orchestrator.knowledge-packs:define-knowledge-kind :taxonomy
 :doc "Κατηγορίαι: (:γένος ΕΙΔΟΣ ΓΕΝΟΣ) — «κάθε ΕΙΔΟΣ είναι ΓΕΝΟΣ». Τροφοδοτεί
 τον συλλογισμό Barbara της μηχανής (μεταβατικά, με απόδειξη ανά βήμα)."
 :install (lambda (entries)
            (dolist (e entries)
              (destructuring-bind (k a b &optional πρ τιμή) e
                (ecase k
                  (:γένος     (pushnew (list :γένος a b) *taxonomy* :test #'equal))
                  ;; γένος ΜΕ ΔΙΑΦΟΡΑ: ο δεσμός ισχύει μόνο υπό τον όρο
                  (:γένος-όταν (pushnew (list :γένος-όταν a b πρ τιμή)
                                        *taxonomy* :test #'equal))
                  ;; η διαίρεση είναι συμμετρική — δηλώνεται μία, ισχύει διπλή
                  (:διαίρεσις (pushnew (list :διαίρεσις a b) *taxonomy* :test #'equal)
                              (pushnew (list :διαίρεσις b a) *taxonomy* :test #'equal))))))
 :snapshot (lambda () (copy-tree *taxonomy*))
 :restore  (lambda (st) (setf *taxonomy* st)))

;;; ============================================================================
;;; Η ΕΙΔΙΚΗ ΥΠΟΣΤΑΣΗ ΩΣ ΓΝΩΣΗ — πακέτο :tatbestand
;;; ============================================================================
;;; Entry: (:norm ID MODALITY "corpus:article" SCOPE ANTECEDENT CONSEQUENT
;;;         [DEFEATERS]) — μεταβλητές γράφονται :?χ (γίνονται ?χ στην εγκατάσταση).

(orchestrator.knowledge-packs:define-knowledge-kind :tatbestand
 :doc "Ειδικές υποστάσεις: (:norm ID MODALITY ΠΗΓΗ SCOPE ΠΡΟΫΠΟΘΕΣΕΙΣ ΠΡΑΞΗ [ΛΟΓΟΙ-ΑΡΣΗΣ])
 — μεταβλητές ως :?χ. Ο κανόνας εγγράφεται στον L5 με αναιρεσιμότητα well-founded."
 :install
 (lambda (entries)
   (dolist (e entries)
     (destructuring-bind (k id modality source scope antecedent consequent
                          &optional defeaters) e
       (assert (eq k :norm) () "άγνωστο entry ~S στο πακέτο :tatbestand" k)
       (orchestrator.deontic:register-norm
        (orchestrator.deontic:make-norm
         :id id :modality modality :source source :scope scope
         :antecedent (%devar antecedent)
         :consequent (%devar consequent)
         :defeaters (%devar defeaters))))))
 :snapshot
 (lambda () (loop for n in (orchestrator.deontic:all-norms)
                  collect (cons (orchestrator.deontic:norm-id n) n)))
 :restore
 (lambda (st)
   (orchestrator.deontic:clear-norms)
   (loop for (nil . n) in st do (orchestrator.deontic:register-norm n))))
