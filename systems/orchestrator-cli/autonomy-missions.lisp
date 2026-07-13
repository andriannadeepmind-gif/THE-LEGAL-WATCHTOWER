;;;; systems/orchestrator-cli/autonomy-missions.lisp
;;;; ============================================================================
;;;; ΑΠΟΣΤΟΛΕΣ ΤΟΥ ΑΥΤΟΝΟΜΟΥ ΟΔΗΓΟΥ — ο νομικός τομέας εγγράφει, ο οδηγός εκτελεί
;;;; ============================================================================
;;;;
;;;; Πρώτη αποστολή: ΔΕΟΝΤΙΚΗ ΣΑΡΩΣΗ ενός κώδικα. Για κάθε άρθρο, ο προτείνων
;;;; (σήμερα ντετερμινιστικός: εντοπίζει την πρόταση-φορέα του δεοντικού τελεστή·
;;;; αύριο ο σύμβουλος — pluggable, η ΑΡΧΙΤΕΚΤΟΝΙΚΗ δεν αλλάζει) παράγει υποψήφια
;;;; ταξινόμηση (τυπικότητα + χωρίο-απόδειξη), ο ΕΠΑΛΗΘΕΥΤΗΣ (orchestrator.extraction)
;;;; την κρίνει με τους 4 ελέγχους, και ό,τι περνά μπαίνει στην ΟΥΡΑ ΠΡΟΤΑΣΕΩΝ —
;;;; η γνώση ενεργοποιείται ΜΟΝΟ με έγκριση του δημιουργού (--approve), οπότε και
;;;; εγγράφεται στο L5 (register-norm). Οι εγκεκριμένες ΞΑΝΑΖΟΥΝ σε κάθε εκκίνηση
;;;; από το ίδιο το μητρώο προτάσεων — καμία δεύτερη αποθήκη.

(in-package :orchestrator.cli)

(defparameter +corpus-scope+
  '(("poinikos" . :penal) ("kpoinikis" . :penal)
    ("astikos" . :civil) ("kpolitikis" . :civil)
    ("kdioikitikis" . :administrative) ("syntagma" . :constitutional))
  "Πεδίο δικαίου ανά κώδικα — για lex specialis/mitior αργότερα.")

(defun %norm-classification-payload (p)
  (let ((*read-eval* nil))
    (read-from-string (orchestrator.proposals:proposal-payload p))))

;;; Έγκριση ⇒ η ταξινόμηση γίνεται ΚΑΝΟΝΑΣ στο L5 (με πηγή, εκ κατασκευής).
(orchestrator.proposals:register-proposal-kind :norm-classification
 :on-approve
 (lambda (p)
   (let* ((pl (%norm-classification-payload p))
          (source (getf pl :source)) (modality (getf pl :modality)))
     (orchestrator.deontic:register-norm
      (orchestrator.deontic:make-norm
       :id (intern (format nil "NORM-~:@(~A-~A~)" source modality) :keyword)
       :modality modality :antecedent nil
       :consequent (list :ρυθμίζει source)
       :scope (getf pl :scope) :source source))))
 :describe
 (lambda (p)
   (let ((pl (%norm-classification-payload p)))
     (format nil "~A: ~A — «~A»" (getf pl :source) (getf pl :modality)
             (getf pl :evidence)))))

;;; Οι ήδη εγκεκριμένες ταξινομήσεις ξαναζούν από το μητρώο — μία πηγή αλήθειας.
(dolist (p (orchestrator.proposals:proposals))
  (when (and (eq (orchestrator.proposals:proposal-kind p) :norm-classification)
             (string= (orchestrator.proposals:proposal-status p) "approved"))
    (handler-case
        (funcall (getf (gethash :norm-classification orchestrator.proposals::*kinds*) :on-approve) p)
      (error () nil))))

(defun %corpus-articles (corpus)
  "Τα άρθρα ενός κώδικα ως ((num . text)…) από το materialized corpus.jsonl."
  (let ((path (merge-pathnames (format nil "output/~A/corpus.jsonl" (%corpus-outdir corpus))
                               (orchestrator.paths:institution-root)))
        (acc '()))
    (when (probe-file path)
      (with-open-file (s path :external-format :utf-8)
        (loop for line = (read-line s nil) while line do
          (let ((rec (ignore-errors (jonathan:parse line :as :alist))))
            (when rec
              (let ((num (cdr (assoc "number" rec :test #'string=)))
                    (text (cdr (assoc "text" rec :test #'string=))))
                (when (and num (stringp text) (plusp (length text)))
                  (push (cons num text) acc))))))))
    (nreverse acc)))

;; Ο τεμαχισμός προτάσεων ζει στην έδρα της γλωσσικής γνώσης
;; (orchestrator.extraction:split-sentences) — καμία τοπική εκδοχή.

;;; ── ΠΡΩΤΟΚΟΛΛΟ ΠΡΟΤΕΙΝΟΝΤΩΝ (open/closed) ──
;;; Ο προτείνων ΔΕΝ είναι έμπιστος — παράγει ΥΠΟΨΗΦΙΕΣ ((:modality :evidence)…)·
;;; την αλήθεια την κρίνει ΠΑΝΤΑ ο επαληθευτής και την ενεργοποιεί ΜΟΝΟ η έγκριση.
;;; Έτσι ο σύμβουλος (LLM) κουμπώνει αύριο ως ακόμη ένας προτείνων, με πλουσιότερες
;;; προτάσεις (προϋποθέσεις→συνέπεια) — και η αρχιτεκτονική ΔΕΝ αλλάζει κατά γράμμα.

(defvar *norm-proposers* '()
  "alist (όνομα . fn), fn: (corpus scope num text) → λίστα plists (:modality :evidence …).")

(defun register-norm-proposer (name fn)
  (setf *norm-proposers* (cons (cons name fn) (remove name *norm-proposers* :key #'car))))

;; Ο ντετερμινιστικός προτείνων: ΚΑΘΕ πρόταση ταξινομείται ΜΙΑ φορά από τον
;; ταξινομητή προτεραιότητας (όχι τρεις ανεξάρτητες σαρώσεις — η προτεραιότητα
;; των τελεστών κρίνεται ΜΕΣΑ στην πρόταση)· πρώτη πρόταση ανά τυπικότητα.
(register-norm-proposer :marker-scan
 (lambda (corpus scope num text)
   (declare (ignore corpus scope num))
   (let ((found '()))
     (dolist (s (orchestrator.extraction:split-sentences text))
       (multiple-value-bind (modality op)
           (orchestrator.extraction:classify-deontic-sentence s)
         (declare (ignore op))
         (when (and modality (not (assoc modality found)))
           (push (cons modality s) found))))
     (loop for (modality . evidence) in (nreverse found)
           collect (list :modality modality :evidence evidence)))))

(defun %deontic-scan-step (corpus scope item)
  "Ένα βήμα της σάρωσης: ΟΛΟΙ οι εγγεγραμμένοι προτείνοντες παράγουν υποψήφιες για
   ΕΝΑ άρθρο· καθεμία περνά από τον επαληθευτή. Στην ουρά ΜΟΝΟ ό,τι αποδεικνύεται."
  (destructuring-bind (num . text) item
    (let* ((source (format nil "~A:~A" corpus num))
           (queued 0) (auto 0) (cut 0) (last-reason nil) (seen '()))
      (dolist (entry *norm-proposers*)
        (dolist (cand (funcall (cdr entry) corpus scope num text))
          (let ((modality (getf cand :modality)))
            ;; ίδια (πηγή, τυπικότητα) μία φορά — ανεξάρτητα από το ποιος την πρότεινε
            (unless (member modality seen)
              (push modality seen)
              (let ((v (orchestrator.extraction:verify-proposal
                        :modality modality :consequent (list :ρυθμίζει source)
                        :source source :scope scope :text text
                        :evidence (getf cand :evidence))))
                (cond
                  ((orchestrator.extraction:verdict-accepted-p v)
                   (let ((id (orchestrator.proposals:propose!
                              :sig (format nil "norm-classification ~A ~A" source modality)
                              :kind :norm-classification
                              :why (format nil "δεοντική σάρωση ~A (~(~A~)): το άρθρο ~A φέρει τελεστή ~A"
                                           corpus (car entry) num modality)
                              :payload (prin1-to-string
                                        (list :source source :modality modality :scope scope
                                              :evidence (getf cand :evidence))))))
                     (when id
                       (incf queued)
                       ;; Φάση 5: ενεργή πολιτική κλάσης ⇒ έγκριση ΤΩΡΑ (μετρημένη
                       ;; ακρίβεια, απόφαση δημιουργού) — ο ένας-εγκρίνων κλιμακώνει
                       (when (%maybe-auto-approve id modality) (incf auto)))))
                  (t (incf cut)
                     (setf last-reason (first (orchestrator.extraction:verdict-reasons v))))))))))
      (cond ((plusp queued)
             (values :accepted (format nil "~D ταξινομήσεις~@[ (~D αυτο-εγκρίθηκαν κατά πολιτική)~]"
                                       queued (and (plusp auto) auto))))
            ((plusp cut)    (values :rejected (or last-reason "κόπηκε από τον επαληθευτή")))
            (t              (values :skipped "χωρίς δεοντικό τελεστή"))))))

;;; ── Εγγραφή αποστολών: μία ανά κώδικα, ίδιος μηχανισμός ──
(dolist (entry +corpus-scope+)
  (destructuring-bind (corpus . scope) entry
    (orchestrator.autonomy:define-mission
     (intern (format nil "DEONTIC-SCAN-~:@(~A~)" corpus) :keyword)
     :title (format nil "Δεοντική σάρωση ~A" corpus)
     :goal "κάθε άρθρο ταξινομημένο δεοντικά με χωρίο-απόδειξη, στην ουρά έγκρισης"
     :items-fn (let ((c corpus)) (lambda () (%corpus-articles c)))
     :step-fn (let ((c corpus) (s scope))
                (lambda (item) (%deontic-scan-step c s item))))))

(defun run-autonomous (args)
  "--autonomous [αποστολή] [όριο] : τρέξε αποστολή αυτόνομα (χωρίς όρισμα: κατάλογος).
   Ό,τι παράγεται πάει στην ΟΥΡΑ ΠΡΟΤΑΣΕΩΝ — έλεγχος με --reflect, ενεργοποίηση με
   --approve <id>. Ο οδηγός δεν αγγίζει τη γνώση κατευθείαν."
  (let ((name (first args))
        (limit (and (second args) (parse-integer (second args) :junk-allowed t))))
    (cond
      ((null name)
       (format t "~%Διαθέσιμες αποστολές:~%")
       (dolist (m (sort (orchestrator.autonomy:all-missions) #'string<
                        :key (lambda (m) (symbol-name (orchestrator.autonomy:mission-name m)))))
         (format t "  • ~(~A~) — ~A~%"
                 (orchestrator.autonomy:mission-name m)
                 (orchestrator.autonomy:mission-title m)))
       (format t "~%χρήση: --autonomous <αποστολή> [όριο αντικειμένων]~%")
       0)
      (t
       (let ((m (orchestrator.autonomy:find-mission
                 (intern (string-upcase name) :keyword))))
         (cond
           ((null m) (format t "Άγνωστη αποστολή «~A» — δες τον κατάλογο με σκέτο --autonomous.~%" name) 1)
           (t (let ((report (orchestrator.autonomy:run-mission m :limit limit)))
                (format t "~%Έλεγχος ουράς: --reflect · έγκριση: --approve <id>~%")
                (if (getf report :aborted-p) 1 0)))))))))

(register-command "--autonomous" (lambda (a) (run-autonomous a)))
(register-command "--αυτόνομα"   (lambda (a) (run-autonomous a)))
