;;;; systems/orchestrator-cli/draft-commands.lisp
;;;; ============================================================================
;;;; Ε12 — ΤΟ ΠΑΡΑΔΟΤΕΟ: Σημείωμα Υπαγωγής με ΑΠΟΔΕΙΞΗ ΣΕ ΚΑΘΕ ΠΡΟΤΑΣΗ
;;;; ============================================================================
;;;;
;;;; «Ο δικηγόρος πληρώνεται για το δικόγραφο, όχι για το fixpoint» (κριτής
;;;; πληρότητας, 05-07-2026). Το πρώτο proof-carrying νομικό έγγραφο του
;;;; συστήματος: αφήγηση → γεγονότα → υπαγωγή → δομημένο σημείωμα όπου
;;;; ΚΑΘΕ κρίση φέρει τον κανόνα της (με άρθρο), το δέντρο απόδειξης, τον
;;;; ασθενέστερο κρίκο θεμελίωσης, και ΚΑΘΕ κενό/όριο δηλώνεται ονομαστικά.
;;;; Η πειθαρχία Lexis/Thomson εκτελέσιμη: κανένα συμπέρασμα χωρίς πηγή,
;;;; κανένα output χωρίς ταυτότητα (SHA-256) και ίχνος στη βιογραφία.
;;;;
;;;; ΣΥΝΘΕΣΗ υπαρχόντων ειδικών — ΚΑΜΙΑ νέα λογική: parse-narrative
;;;; (γραμματική), subsume/narrate-position/norm-gaps/conclusion-status
;;;; (υπαγωγή+Σ10), fact->string (η μία εκτύπωση), sha256-hex (ημερολόγιο).
;;;; Ντετερμινιστικό: ίδια αφήγηση ⇒ byte-ίδιο σώμα ⇒ ίδιο αποτύπωμα.

(in-package :orchestrator.cli)

(defun %memo-fact-line (f stream)
  "Μία γραμμή ιστορικού με το είδος της: γεγονός, άρνηση, ή κατηγοριακή γνώση."
  (cond
    ((eq (first f) :άρνηση)
     (destructuring-bind (k α πράξη θ) f
       (declare (ignore k))
       (format stream "   • ΑΡΝΗΣΗ: ο/η ~A ΔΕΝ ~A ~A   [πηγή: αφήγηση εντολέα]~%"
               (orchestrator.knowledge:fact->string α)
               (orchestrator.knowledge:fact->string πράξη)
               (orchestrator.knowledge:fact->string θ))))
    (t (format stream "   • ~A   [πηγή: αφήγηση εντολέα]~%"
               (orchestrator.knowledge:fact->string f)))))

;;; ── Ε13: Ο ΒΡΟΧΟΣ ΑΠΟΣΑΦΗΝΙΣΗΣ — από το ονομασμένο κενό στην ΕΡΩΤΗΣΗ ──
;;; Abduction επί των missing patterns: αντί για σιωπηλό nil, το σύστημα
;;; ρωτά ΤΙ ακριβώς θα έκανε τη θέση να στοιχειοθετηθεί — ντετερμινιστικά,
;;; από το ίδιο το κενό (καμία γεννήτρια κειμένου, κανένα LLM).

(defun %term->el (x)
  "Όρος κενού → φυσικά ελληνικά για ΕΡΩΤΗΣΗ: ?μεταβλητή → «κάποιος»,
   keyword → λέξη χωρίς άνω-κάτω τελεία, αλλιώς όπως είναι."
  (cond ((and (symbolp x) (plusp (length (symbol-name x)))
              (char= #\? (char (symbol-name x) 0)))
         "κάποιος")
        ((keywordp x) (string-downcase (symbol-name x)))
        ((consp x) (format nil "~{~A~^ ~}" (mapcar #'%term->el x)))
        (t (princ-to-string x))))

(defun %question-from-gap (pattern norm)
  "Μία ερώτηση προς τον εντολέα από ένα missing pattern ενός κανόνα."
  (destructuring-bind (head &rest parts) pattern
    (declare (ignore head))
    (format nil "Ισχύει ότι ~{~A~^ ~}; — αν ΝΑΙ, στοιχειοθετείται ο ~A (άρθρο ~A ~A)· αν ΟΧΙ ή άγνωστο, δηλώστε το."
            (mapcar #'%term->el parts)
            (orchestrator.deontic:norm-id norm)
            (orchestrator.deontic:norm-article norm)
            (orchestrator.deontic:norm-corpus norm))))

(defun gap-questions (facts)
  "ΟΛΕΣ οι ερωτήσεις αποσαφήνισης: για κάθε κανόνα που ΑΓΓΙΖΕΤΑΙ αλλά δεν
   στοιχειοθετείται, μία ερώτηση ανά ονομασμένο κενό. Ντετερμινιστική σειρά."
  (let ((qs '()))
    (dolist (nm (orchestrator.subsumption:case-norms) (nreverse qs))
      (when (orchestrator.deontic:norm-antecedent nm)
        (multiple-value-bind (have missing)
            (orchestrator.subsumption:norm-gaps nm facts)
          (when (and have missing)
            (dolist (p missing)
              (push (%question-from-gap p nm) qs))))))))

(defun %memo-body (narrative)
  "Το ΣΩΜΑ του σημειώματος ως string — χωρίς χρονοσφραγίδα μέσα του, ώστε το
   αποτύπωμα να είναι ντετερμινιστικό: ίδια αφήγηση ⇒ ίδιο SHA-256."
  (with-output-to-string (s)
    (multiple-value-bind (facts unparsed timeline)
        (orchestrator.casegrammar:parse-narrative narrative)
      (multiple-value-bind (engine positions)
          (orchestrator.subsumption:subsume facts)
        (format s "════════════════════════════════════════════════════════════~%")
        (format s "  ΣΗΜΕΙΩΜΑ ΥΠΑΓΩΓΗΣ — κάθε κρίση με την απόδειξή της~%")
        (format s "════════════════════════════════════════════════════════════~%")
        ;; Ι. ΙΣΤΟΡΙΚΟ — τα γεγονότα όπως ΔΙΑΒΑΣΤΗΚΑΝ, με την πηγή τους
        (format s "~%Ι. ΙΣΤΟΡΙΚΟ (~D γεγονότα από την αφήγηση)~%" (length facts))
        (dolist (f facts) (%memo-fact-line f s))
        (when (null facts)
          (format s "   (κανένα αξιοποιήσιμο γεγονός — βλ. τμήμα V)~%"))
        ;; Ια. ΧΡΟΝΟΛΟΓΙΟ (Λ7): οι χρονολογημένες προτάσεις, ταξινομημένες από
        ;; τον ΕΝΑΝ ημερολογιακό λογισμό (ymd->day με πιστοποιητικό) — η
        ;; εγκυρότητα κρίνεται ΕΚΕΙ: ανύπαρκτη ημερομηνία ΔΗΛΩΝΕΤΑΙ, ποτέ
        ;; δεν «διορθώνεται» σιωπηλά. Μπαίνουν ΚΑΙ οι αδιάβαστες προτάσεις:
        ;; η χρονική τους θέση είναι γνώση, έστω κι αν η πράξη δεν διαβάστηκε.
        (format s "~%Ια. ΧΡΟΝΟΛΟΓΙΟ (~D χρονολογημένες προτάσεις)~%" (length timeline))
        (if timeline
            (let ((entries
                    (loop for (d . sent) in timeline
                          collect (list d sent
                                        (handler-case
                                            (orchestrator.metaeval:meta-eval
                                             (list 'ymd->day d))
                                          (error () nil))))))
              (dolist (e (sort (remove-if-not #'third entries) #'< :key #'third))
                (format s "   ~A — «~A»   [πηγή: αφήγηση εντολέα]~%"
                        (first e) (second e)))
              (dolist (e (remove-if #'third entries))
                (format s "   ⚠ «~A»: η ημερομηνία ~A ΑΠΟΡΡΙΦΘΗΚΕ από τον ημερολογιακό λογισμό (ανύπαρκτη) — δηλώνεται, δεν διορθώνεται.~%"
                        (second e) (first e))))
            (format s "   (καμία χρονολογημένη πρόταση στην αφήγηση)~%"))
        ;; ΙΙ. ΝΟΜΙΚΟ ΠΛΑΙΣΙΟ — μόνο κανόνες που ΑΓΓΙΖΟΥΝ την υπόθεση, με πηγή
        (format s "~%ΙΙ. ΝΟΜΙΚΟ ΠΛΑΙΣΙΟ (κανόνες που αγγίζουν τα γεγονότα)~%")
        (let ((touched 0))
          (dolist (nm (orchestrator.subsumption:case-norms))
            (when (orchestrator.deontic:norm-antecedent nm)
              (multiple-value-bind (have missing)
                  (orchestrator.subsumption:norm-gaps nm facts)
                (declare (ignore missing))
                (when have
                  (incf touched)
                  (format s "   § ~A — άρθρο ~A ~A   [πηγή: ~A]~%"
                          (orchestrator.deontic:norm-id nm)
                          (orchestrator.deontic:norm-article nm)
                          (orchestrator.deontic:norm-corpus nm)
                          (orchestrator.deontic:norm-source nm))))))
          (when (zerop touched)
            (format s "   (κανένας εγγεγραμμένος κανόνας δεν αγγίζει τα γεγονότα)~%")))
        ;; ΙΙΙ. ΥΠΑΓΩΓΗ — κάθε θέση με δέντρο απόδειξης + ασθενέστερο κρίκο (Σ10)
        (format s "~%ΙΙΙ. ΥΠΑΓΩΓΗ (~D αποδεδειγμένες θέσεις)~%" (length positions))
        (dolist (p positions)
          (orchestrator.subsumption:narrate-position (car p) (cdr p) s))
        (when (null positions)
          (format s "   Καμία δεοντική θέση δεν στοιχειοθετείται — βλ. τμήμα IV.~%"))
        ;; IV. ΤΙ ΛΕΙΠΕΙ / ΤΙ ΑΙΡΕΤΑΙ — η μετα-γνώση της άγνοιας, ονομαστικά
        (format s "~%IV. ΕΛΛΕΙΨΕΙΣ ΚΑΙ ΑΡΣΕΙΣ (τι πρέπει να αποδειχθεί ακόμη)~%")
        (let ((n 0))
          (dolist (nm (orchestrator.subsumption:case-norms))
            (when (orchestrator.deontic:norm-antecedent nm)
              (multiple-value-bind (status)
                  (orchestrator.subsumption:conclusion-status engine nm facts)
                (multiple-value-bind (have missing)
                    (orchestrator.subsumption:norm-gaps nm facts)
                  (cond
                    ((and have missing)
                     (incf n)
                     (format s "   ⚠ ~A: ΔΕΝ στοιχειοθετείται — λείπει: ~{~A~^ · ~}~%"
                             (orchestrator.deontic:norm-id nm)
                             (mapcar #'orchestrator.knowledge:fact->string missing)))
                    ((and have (null missing) (eq status :out))
                     (incf n)
                     (format s "   ⚖ ~A: πλήρης ειδική υπόσταση αλλά ΑΙΡΕΤΑΙ (λόγος άρσης ενεργός)~%"
                             (orchestrator.deontic:norm-id nm))))))))
          (when (zerop n) (format s "   (καμία εκκρεμότητα στους κανόνες που αγγίζουν)~%")))
        ;; V. ΔΗΛΩΜΕΝΑ ΟΡΙΑ — ό,τι ΔΕΝ αξιοποιήθηκε, ονομαστικά (καμία σιωπή)
        (format s "~%V. ΔΗΛΩΜΕΝΑ ΟΡΙΑ ΑΝΑΓΝΩΣΗΣ~%")
        (if unparsed
            (dolist (u unparsed)
              (format s "   ⚠ ΔΕΝ αξιοποιήθηκε (καμία εικασία): «~A»~%" u))
            (format s "   Όλες οι προτάσεις της αφήγησης αξιοποιήθηκαν.~%"))
        ;; VI. Ο ΒΡΟΧΟΣ ΑΠΟΣΑΦΗΝΙΣΗΣ (Ε13) — το σύστημα ΡΩΤΑ, δεν σωπαίνει:
        ;; κάθε ερώτηση παράγεται από ονομασμένο κενό (abduction), και λέει
        ;; ΤΙ ξεκλειδώνει η απάντηση — συνέντευξη εντολέα ως λογισμός.
        (format s "~%VI. ΕΡΩΤΗΣΕΙΣ ΠΡΟΣ ΤΟΝ ΕΝΤΟΛΕΑ (αποσαφήνιση από τα κενά)~%")
        (let ((qs (gap-questions facts)))
          (if qs
              (loop for q in qs for i from 1
                    do (format s "   ~D. ~A~%" i q))
              (format s "   Καμία ερώτηση — ο φάκελος επαρκεί για τους κανόνες που αγγίζει.~%")))
        ;; VII. ΣΤΡΑΤΗΓΙΚΑ ΣΕΝΑΡΙΑ (Ε14) — Η ΕΙΚΑΣΙΑ ΩΣ ΕΙΚΑΣΙΑ: η στρατηγική
        ;; σκέψη ΕΠΙΤΡΕΠΕΤΑΙ, αρκεί να φοράει την ετικέτα της. Κανένα σενάριο
        ;; δεν μπαίνει στο έμπιστο μονοπάτι (Σύνταγμα, άρθρο 2) — αλλά ο
        ;; δικηγόρος βλέπει ΤΙ ΘΑ ΓΙΝΟΤΑΝ: υποθέσεις που στοιχειοθετούν, και
        ;; κρίσιμα ερείσματα που αν πέσουν, πέφτει η θέση (Σ6, ακριβές ablation).
        (format s "~%VII. ΣΤΡΑΤΗΓΙΚΑ ΣΕΝΑΡΙΑ — ΕΙΚΑΣΙΕΣ, ΔΗΛΩΜΕΝΕΣ ΩΣ ΤΕΤΟΙΕΣ~%")
        (let ((any nil))
          ;; (α) θετικές εικασίες: ΑΝ αποδεικνυόταν το κενό, τι στοιχειοθετείται;
          (dolist (nm (orchestrator.subsumption:case-norms))
            (when (orchestrator.deontic:norm-antecedent nm)
              (multiple-value-bind (have missing)
                  (orchestrator.subsumption:norm-gaps nm facts)
                (when (and have missing)
                  (let* ((assumed (mapcar (lambda (p) (%groundify p)) missing))
                         (hypo (append facts assumed)))
                    (multiple-value-bind (engine2)
                        (orchestrator.subsumption:subsume hypo)
                      (multiple-value-bind (status2)
                          (orchestrator.subsumption:conclusion-status engine2 nm hypo)
                        (when (member status2 '(:in :out))
                          (setf any t)
                          (format s "   ◈ ΕΙΚΑΣΙΑ [σενάριο — ΟΧΙ συμπέρασμα]: ΑΝ αποδειχθεί ~{«~A»~^ και ~},~%     ~A ο ~A (άρθρο ~A ~A)~@[ — ΠΡΟΣΟΧΗ: υπό το σενάριο ενεργοποιείται και λόγος άρσης~*~]~%"
                                  (mapcar #'orchestrator.knowledge:fact->string assumed)
                                  (if (eq status2 :in) "στοιχειοθετείται" "θα στοιχειοθετούνταν αλλά ΑΙΡΕΤΑΙ")
                                  (orchestrator.deontic:norm-id nm)
                                  (orchestrator.deontic:norm-article nm)
                                  (orchestrator.deontic:norm-corpus nm)
                                  (eq status2 :out))))))))))
          ;; (β) κίνδυνοι επί των αποδεδειγμένων: τα ΚΡΙΣΙΜΑ ερείσματα (Σ6)
          (dolist (p positions)
            (let* ((datum (car p)) (id (fifth datum))
                   (nm (and id (orchestrator.deontic:find-norm id))))
              (when nm
                (multiple-value-bind (critical idle basis-p)
                    (orchestrator.counterfactual:critical-facts facts nm)
                  (declare (ignore idle))
                  (when (and basis-p critical)
                    (setf any t)
                    (format s "   ⚠ ΚΙΝΔΥΝΟΣ: η θέση κατά τον ~A στηρίζεται ΚΡΙΣΙΜΑ σε: ~{«~A»~^ · ~}~%     — αν ο αντίδικος ανατρέψει έστω ένα, η θέση ΠΕΦΤΕΙ (ακριβές ablation Σ6).~%"
                            (orchestrator.deontic:norm-id nm)
                            (mapcar #'orchestrator.knowledge:fact->string critical)))))))
          (unless any
            (format s "   Κανένα σενάριο — ούτε κενά προς υπόθεση ούτε αποδεδειγμένες θέσεις προς δοκιμασία.~%")))
        ;; VIII. ΧΑΡΤΗΣ ΑΝΤΙΔΙΚΟΥ (Επίπεδο 5 — adversarial self-review):
        ;; το σύστημα ΑΝΤΙΔΙΚΕΙ με τον εαυτό του: για κάθε ιστάμενη θέση,
        ;; ΤΙ θα επιδιώξει να αποδείξει ο αντίδικος — ντετερμινιστικά, από
        ;; τους ΕΓΓΕΓΡΑΜΜΕΝΟΥΣ λόγους άρσης του ίδιου του κανόνα (τους ίδιους
        ;; που ο JTMS θα σεβαστεί αν αποδειχθούν: όχι ρητορική — μηχανική).
        (format s "~%VIII. ΧΑΡΤΗΣ ΑΝΤΙΔΙΚΟΥ (τι θα αντιτάξει — και τι θα συμβεί αν το αποδείξει)~%")
        (let ((any8 nil))
          (dolist (nm (orchestrator.subsumption:case-norms))
            (when (orchestrator.deontic:norm-antecedent nm)
              (multiple-value-bind (status datum binding)
                  (orchestrator.subsumption:conclusion-status engine nm facts)
                (declare (ignore datum))
                (when (eq status :in)
                  (setf any8 t)
                  (let ((defs (orchestrator.deontic:norm-defeaters nm)))
                    (if defs
                        (dolist (d defs)
                          (format s "   ▸ Κατά της θέσης εκ του ~A (άρθρο ~A ~A): θα επιδιώξει να αποδείξει «~{~A~^ ~}»~%     — αν το αποδείξει, η θέση ΑΙΡΕΤΑΙ ΑΥΤΟΜΑΤΑ (truth maintenance, όχι υπόσχεση).~%"
                                  (orchestrator.deontic:norm-id nm)
                                  (orchestrator.deontic:norm-article nm)
                                  (orchestrator.deontic:norm-corpus nm)
                                  (mapcar #'%term->el
                                          (rest (orchestrator.inference:instantiate d binding)))))
                        (format s "   ▸ ~A: ΚΑΝΕΝΑΣ εγγεγραμμένος λόγος άρσης — μη εγγεγραμμένες εξαιρέσεις: ΔΗΛΩΜΕΝΟ όριο γνώσης.~%"
                                (orchestrator.deontic:norm-id nm))))))))
          (unless any8
            (format s "   Καμία ιστάμενη θέση — ο αντίδικος δεν έχει τι να ανατρέψει (ή εμείς τι να στηρίξουμε).~%")))))))

(defun %groundify (pattern)
  "Γείωσε ένα missing pattern για ΥΠΟΘΕΤΙΚΟ σενάριο: ?μεταβλητές → :άγνωστος.
   Το αποτέλεσμα μπαίνει ΜΟΝΟ σε υποθετική μηχανή — ποτέ στο έμπιστο μονοπάτι."
  (cond ((and (symbolp pattern) (plusp (length (symbol-name pattern)))
              (char= #\? (char (symbol-name pattern) 0)))
         :άγνωστος)
        ((consp pattern) (mapcar #'%groundify pattern))
        (t pattern)))

(defun draft-memo (narrative &key (stream *standard-output*))
  "Τύπωσε το Σημείωμα Υπαγωγής + την ΤΑΥΤΟΤΗΤΑ του (SHA-256 του σώματος).
   Επιστρέφει το αποτύπωμα — η ρίζα του audit trail του παραδοτέου."
  (let* ((body (%memo-body narrative))
         (sha (orchestrator.journal:sha256-hex body)))
    (write-string body stream)
    (format stream "~%── ΤΑΥΤΟΤΗΤΑ ΕΓΓΡΑΦΟΥ ──~%")
    (format stream "   SHA-256: ~A~%" sha)
    (format stream "   (ίδια αφήγηση ⇒ ίδιο αποτύπωμα — το παραδοτέο είναι αναπαραγώγιμο)~%")
    ;; ΙΧΝΟΣ ΠΡΟΕΛΕΥΣΗΣ: το παραδοτέο-τέχνημα δένεται στην εκτέλεση που το γέννησε
    (orchestrator.trace:emit! :artifact
     :symbol "draft-memo" :package "orchestrator.cli"
     :source "systems/orchestrator-cli/draft-commands.lisp"
     :data (list :artifact :σημείωμα-υπαγωγής :sha sha))
    sha))

(defun run-draft (args)
  "--draft \"αφήγηση\" : το σημείωμα + εγγραφή του αποτυπώματος στη βιογραφία
   (audit trail) + ΠΕΡΙΕΡΓΕΙΑ (Ε14): κάθε άγνοια του παραδοτέου — αδιάβαστη
   πρόταση, ανοιχτό κενό κανόνα — γίνεται ΜΑΘΗΜΑ (lessons.jsonl) που τρέφει
   τον βρόχο αυτομελέτης (--self-extend / βούληση): η άρνηση δεν είναι
   στατική φόρμα — είναι η ΑΡΧΗ της επόμενης μάθησης."
  (let ((narrative (format nil "~{~A~^ ~}" args)))
    (if (zerop (length (string-trim " " narrative)))
        (progn (format t "χρήση: --draft \"Ο Χ αφαίρεσε το … της Ψ.\"~%") 1)
        (let ((sha (draft-memo narrative))
              (lessons 0))
          ;; ΠΕΡΙΕΡΓΕΙΑ: ό,τι ΔΕΝ κατάλαβε/δεν έκλεισε, καταγράφεται προς μάθηση
          (multiple-value-bind (facts unparsed)
              (orchestrator.casegrammar:parse-narrative narrative)
            (dolist (u unparsed)
              (%lesson "sentence-unread" u "πρόταση παραδοτέου που η γραμματική δεν διάβασε")
              (incf lessons))
            (dolist (nm (orchestrator.subsumption:case-norms))
              (when (orchestrator.deontic:norm-antecedent nm)
                (multiple-value-bind (have missing)
                    (orchestrator.subsumption:norm-gaps nm facts)
                  (when (and have missing)
                    (%lesson "norm-gap"
                             (string (orchestrator.deontic:norm-id nm))
                             (format nil "~{~A~^ · ~}"
                                     (mapcar #'orchestrator.knowledge:fact->string missing)))
                    (incf lessons))))))
          (when (plusp lessons)
            (format t "~%   ↻ ΠΕΡΙΕΡΓΕΙΑ: ~D μαθήματα καταγράφηκαν προς αυτομελέτη (--lessons / --self-extend)~%" lessons))
          (ignore-errors
            (orchestrator.self-history:record!
             :draft-issued
             (format nil "Εξέδωσα Σημείωμα Υπαγωγής με αποτύπωμα ~A — κάθε κρίση με απόδειξη, κάθε κενό δηλωμένο~@[, ~D μαθήματα προς αυτομελέτη~]." sha (and (plusp lessons) lessons))))
          0))))

(register-command "--draft" (lambda (a) (run-draft a)))

;;; ── Η ΠΥΛΗ ΤΟΥ ΠΑΡΑΔΟΤΕΟΥ ────────────────────────────────────────────────

(defun run-draft-gate ()
  "--draft-gate : το παραδοτέο, κλειδωμένο — δομή, αποδείξεις, κενά, άρνηση,
   ντετερμινισμός. 100% ή κόκκινο."
  (orchestrator.knowledge-packs:ensure-fresh)
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label))))
             (memo (n) (%memo-body n)))
      (format t "~%── ΠΥΛΗ ΠΑΡΑΔΟΤΕΟΥ (Ε12): σημείωμα με απόδειξη σε κάθε πρόταση ──~%")
      (let ((m (memo "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας για να το ιδιοποιηθεί.")))
        (check "πλήρης υπόθεση: και τα 5 τμήματα παρόντα"
               (and (search "Ι. ΙΣΤΟΡΙΚΟ" m) (search "ΙΙ. ΝΟΜΙΚΟ ΠΛΑΙΣΙΟ" m)
                    (search "ΙΙΙ. ΥΠΑΓΩΓΗ" m) (search "IV. ΕΛΛΕΙΨΕΙΣ" m)
                    (search "V. ΔΗΛΩΜΕΝΑ ΟΡΙΑ" m)))
        (check "η κρίση φέρει κανόνα+άρθρο+ΘΕΜΕΛΙΩΣΗ+ασθενέστερο κρίκο (Σ10)"
               (and (search "ΑΠΑΓΟΡΕΥΣΗ" m) (search "372" m)
                    (search "ΘΕΜΕΛΙΩΣΗ" m) (search "ασθενέστερος κρίκος" m)))
        (check "κάθε γεγονός του ιστορικού φέρει την πηγή του"
               (search "[πηγή: αφήγηση εντολέα]" m))
        (check "το νομικό πλαίσιο φέρει πηγή κανόνα"
               (search "[πηγή: poinikos:" m)))
      (let ((m (memo "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας.")))
        (check "ελλιπής υπόθεση: το κενό ΟΝΟΜΑΖΕΤΑΙ (λείπει ο σκοπός ιδιοποίησης)"
               (and (search "ΔΕΝ στοιχειοθετείται" m)
                    (search "λείπει" m)
                    (search "σκοπ" (string-downcase m))))
        ;; Ε13: ο βρόχος αποσαφήνισης — το σύστημα ΡΩΤΑ και λέει τι ξεκλειδώνει
        (check "Ε13 ΑΠΟΣΑΦΗΝΙΣΗ: ερώτηση από το κενό, με τον κανόνα που ξεκλειδώνει"
               (and (search "VI. ΕΡΩΤΗΣΕΙΣ" m)
                    (search "Ισχύει ότι" m)
                    (search "σκοπός" m)
                    (search "αν ΝΑΙ, στοιχειοθετείται ο NORM-KLOPI-372" m)))
        (check "Ε13: ?μεταβλητές στις ερωτήσεις γίνονται «κάποιος» — ποτέ ωμά ?vars"
               (let ((vi (subseq m (search "VI. ΕΡΩΤΗΣΕΙΣ" m))))
                 (not (find #\? (remove #\; vi))))))
      (let ((m (memo "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας για να το ιδιοποιηθεί.")))
        (check "Ε13: πλήρης φάκελος ⇒ ερωτήσεις ΜΟΝΟ για ό,τι πράγματι μένει ανοιχτό"
               (and (search "VI. ΕΡΩΤΗΣΕΙΣ" m)
                    ;; ο 372 στοιχειοθετήθηκε — ΚΑΜΙΑ ερώτηση γι' αυτόν
                    (not (search "στοιχειοθετείται ο NORM-KLOPI-372 (άρθρο"
                                 (subseq m (search "VI. ΕΡΩΤΗΣΕΙΣ" m)))))))
      (let ((m (memo "Ο Ανδρέας δεν αφαίρεσε το πορτοφόλι της Μαρίας.")))
        (check "άρνηση: καταγράφεται ως ΑΡΝΗΣΗ και ΚΑΜΙΑ κατηγορία δεν θεμελιώνεται"
               (and (search "ΑΡΝΗΣΗ" m)
                    (not (search "ΑΠΑΓΟΡΕΥΣΗ — στοιχειοθετείται" m)))))
      (let ((m (memo "Ο Ανδρέας αφαίρεσε το ρολόι της Μαρίας. Η βροχή έπεφτε όλη νύχτα.")))
        (check "άσχετη πρόταση: δηλώνεται στο V — ποτέ σιωπηλή απόρριψη"
               (search "ΔΕΝ αξιοποιήθηκε" m)))
      ;; Λ7 ΧΡΟΝΟΛΟΓΙΟ: ταξινόμηση από τον ΕΝΑΝ λογισμό, τιμιότητα στα άκυρα
      (let ((m (memo "Στις 15/02/2026 ο Ανδρέας επέστρεψε το ρολόι. Στις 10/01/2026 ο Ανδρέας αφαίρεσε το ρολόι της Μαρίας.")))
        (check "Λ7 ΧΡΟΝΟΛΟΓΙΟ: ανακατεμένες ημερομηνίες ⇒ ταξινομημένο χρονολόγιο (10/01 πριν 15/02)"
               (let ((p1 (search "2026-01-10" m)) (p2 (search "2026-02-15" m)))
                 (and (search "Ια. ΧΡΟΝΟΛΟΓΙΟ (2" m) p1 p2 (< p1 p2)))))
      (let ((m (memo "Στις 30/02/2026 ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας.")))
        (check "Λ7 ΧΡΟΝΟΛΟΓΙΟ: ανύπαρκτη ημερομηνία (30/02) ⇒ ΑΠΟΡΡΙΦΘΗΚΕ δηλωμένα, όχι «διόρθωση»"
               (and (search "ΑΠΟΡΡΙΦΘΗΚΕ" m) (search "δεν διορθώνεται" m))))
      (let ((m (memo "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας.")))
        (check "Λ7 ΧΡΟΝΟΛΟΓΙΟ: αφήγηση χωρίς ημερομηνίες ⇒ δηλώνεται κενό"
               (search "καμία χρονολογημένη" m)))
      ;; Ε14: Η ΕΙΚΑΣΙΑ ΩΣ ΕΙΚΑΣΙΑ — στρατηγικά σενάρια με ετικέτα, ποτέ κρυφά
      (let ((m (memo "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας.")))
        (check "Ε14 ΕΙΚΑΣΙΑ: το σενάριο δηλώνεται [ΟΧΙ συμπέρασμα] και ονομάζει την υπόθεσή του"
               (and (search "VII. ΣΤΡΑΤΗΓΙΚΑ ΣΕΝΑΡΙΑ" m)
                    (search "ΕΙΚΑΣΙΑ [σενάριο — ΟΧΙ συμπέρασμα]" m)
                    (search "ΑΝ αποδειχθεί" m)
                    (search "σκοπός" m))))
      (let ((m (memo "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας για να το ιδιοποιηθεί.")))
        (check "Ε14 ΚΙΝΔΥΝΟΣ: τα κρίσιμα ερείσματα της αποδεδειγμένης θέσης ονομάζονται (Σ6)"
               (and (search "ΚΙΝΔΥΝΟΣ" m) (search "ΚΡΙΣΙΜΑ" m)
                    (search "η θέση ΠΕΦΤΕΙ" m)))
        (check "Ε14: η εικασία ΔΕΝ μολύνει την υπαγωγή — το ΙΙΙ μένει μόνο με αποδεδειγμένα"
               (let ((iii (subseq m (search "ΙΙΙ. ΥΠΑΓΩΓΗ" m) (search "IV. ΕΛΛΕΙΨΕΙΣ" m))))
                 (not (search "ΕΙΚΑΣΙΑ" iii))))
        ;; ΕΠΙΠΕΔΟ 5 — ο χάρτης αντιδίκου από τους λόγους άρσης του κανόνα
        (check "Λ5 ΧΑΡΤΗΣ ΑΝΤΙΔΙΚΟΥ: ονομάζει τι θα επιδιώξει να αποδείξει (συναίνεση) και τη συνέπεια"
               (and (search "VIII. ΧΑΡΤΗΣ ΑΝΤΙΔΙΚΟΥ" m)
                    (search "θα επιδιώξει να αποδείξει" m)
                    (search "συναίνεση" (string-downcase m))
                    (search "η θέση ΑΙΡΕΤΑΙ ΑΥΤΟΜΑΤΑ" m))))
      (check "ΝΤΕΤΕΡΜΙΝΙΣΜΟΣ: ίδια αφήγηση ⇒ byte-ίδιο σώμα ⇒ ίδιο αποτύπωμα"
             (let ((n "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας για να το ιδιοποιηθεί."))
               (string= (orchestrator.journal:sha256-hex (memo n))
                        (orchestrator.journal:sha256-hex (memo n)))))
      (check "η ταυτότητα εγγράφου είναι έγκυρο SHA-256 (64 hex)"
             (let ((sha (let ((*standard-output* (make-broadcast-stream)))
                          (draft-memo "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας."))))
               (and (stringp sha) (= 64 (length sha))
                    (every (lambda (c) (digit-char-p c 16)) sha)))))
    (format t "~%── ΠΥΛΗ ΠΑΡΑΔΟΤΕΟΥ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--draft-gate" (lambda (a) (declare (ignore a)) (run-draft-gate)))

(orchestrator.self-model:declare-capability! "παραδοτέο"
 :description "Σημείωμα Υπαγωγής: απόδειξη σε κάθε πρόταση, χρονολόγιο, εικασίες με ετικέτα, χάρτης αντιδίκου, SHA ταυτότητα"
 :package :orchestrator.cli :functions '("draft-memo" "gap-questions")
 :gate "--draft-gate"
 :depends-on '("γλωσσική-αντίληψη" "υπαγωγή" "αντιδικία" "υποθετικός-λόγος" "λογισμός-φραγμών"))

;;; ── ΣΥΜΒΟΛΑΙΑ ΠΑΡΟΧΩΝ (δεσμευτική αυτοπεριγραφή — βλ. --contract-gate) ──

(orchestrator.contracts:defcontract "draft-memo" :function
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "παραδοτέο" :role "χειρισμός-υποθέσεων"
 :purpose "Σημείωμα Υπαγωγής: κάθε πρόταση με απόδειξη ή ετικέτα ΕΙΚΑΣΙΑΣ, ποτέ γυμνός ισχυρισμός"
 :inputs '("φάκελος υπόθεσης") :outputs '("σημείωμα 8 τμημάτων + SHA-256 ταυτότητα σώματος")
 :preconditions '("η υπαγωγή/αντιδικία/κρίσιμα έχουν τρέξει στον ίδιο φάκελο")
 :postconditions '("ντετερμινιστικό σώμα: ίδιος φάκελος ⇒ ίδιο SHA-256"
                   "άκυρη ημερομηνία ⇒ ΑΠΟΡΡΙΨΗ με λόγο, όχι διόρθωση")
 :legal-critical t :policy-level :φραγή
 :proof-obligations '("κάθε νομική πρόταση δείχνει corpus:άρθρο ή κόμβο απόδειξης")
 :tests '("--draft-gate"))

(orchestrator.contracts:defcontract "gap-questions" :function
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "παραδοτέο" :role "χειρισμός-υποθέσεων"
 :purpose "τα κενά της υπόθεσης → ερωτήσεις προς τον εντολέα (abduction, περιέργεια)"
 :outputs '("ερωτήσεις δεμένες σε ονοματισμένα κενά")
 :legal-critical t :policy-level :φραγή
 :tests '("--draft-gate"))
