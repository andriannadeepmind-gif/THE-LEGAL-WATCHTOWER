;;;; systems/orchestrator-cli/dialogue-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΤΟΥ ΔΙΑΛΟΓΟΥ — εκτελέσιμη μη-παλινδρόμηση της ΚΑΤΑΝΟΗΣΗΣ
;;;; ============================================================================
;;;;
;;;; Ό,τι έσπασε ΜΙΑ φορά σε ζωντανή συνομιλία γίνεται ΓΙΑ ΠΑΝΤΑ test: η σουίτα
;;;; κωδικοποιεί (α) τις ερωτήσεις που απέτυχαν στην πράξη (πώς σε λένε; τι είναι
;;;; νόμος;), (β) παραλλαγές κλίσης/τόνου/σίγμα — απόδειξη ότι η κατανόηση δουλεύει
;;;; σε ΛΗΜΜΑΤΑ, όχι σε γράμματα, και (γ) την ΤΙΜΙΑ ΑΓΝΟΙΑ: ό,τι δεν θεμελιώνεται
;;;; ΠΡΕΠΕΙ να απαντά «δεν κατάλαβα» (ένα σύστημα που «απαντά» τα πάντα μαντεύει).
;;;;
;;;; Δηλωτική: κάθε περίπτωση = (ερώτηση . προσδοκία), όπου προσδοκία:
;;;;   (:contains S...)  — η απάντηση υπάρχει ΚΑΙ περιέχει όλα τα S
;;;;   :understood       — απλώς υπάρχει απάντηση
;;;;   :unknown          — ΔΕΝ υπάρχει απάντηση (τίμια άγνοια)
;;;; Νέα περίπτωση = μία γραμμή δεδομένων. Καμία λογική ανά περίπτωση.

(in-package :orchestrator.cli)

(defparameter *dialogue-suite*
  '(;; ── ταυτότητα / εαυτός (τα «πώς σε λένε;» και «γιατί να σε ρωτήσω;» ΕΣΠΑΣΑΝ ζωντανά) ──
    ;; ── ΕΠΙΠΕΔΟ 1 (κλίμακα κριτών): αυτογνωσία ΚΑΤΑΣΤΑΣΗΣ μέσα από τον ΔΙΑΛΟΓΟ —
    ;;    όλα υπολογισμένα ζωντανά από τα μητρώα, ποτέ αποστηθισμένα ──
    ("ποια έκδοση είσαι;"                    . (:contains "Έκδοση"))
    ("ποιες πύλες αυτοελέγχου έχεις;"        . (:contains "draft-gate"))
    ("τι corpus έχεις φορτωμένο;"            . (:contains "αποφάσεις"))
    ("ποια τεστ πέρασαν;"                    . (:contains "--gates"))
    ("ποια γνώση σου είναι έμπιστη και ποια σκιώδης;" . (:contains "προτάσεις"))
    ("ποιος είσαι;"                          . (:contains "LAWMAX"))
    ("Τι είσαι?"                             . (:contains "LAWMAX"))
    ("Πως σε λένε?"                          . (:contains "LAWMAX"))
    ("πώς σε λένε;"                          . (:contains "LAWMAX"))
    ("ποιο είναι το όνομά σου;"              . (:contains "LAWMAX"))
    ("Γιατι να σε ρωτησω κατι?"              . :understood)
    ("τι μπορείς να κάνεις;"                 . :understood)
    ("ποιον υπηρετείς;"                      . (:contains "Σταυρόπουλο"))
    ("ποιος σε έφτιαξε;"                     . (:contains "Σταυρόπουλος"))
    ("γεια σου"                              . (:contains "LAWMAX"))
    ;; ── Σ4β: αφήγηση περιστατικών στον διάλογο ⇒ ζωντανή ΥΠΑΓΩΓΗ ──
    ("Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας για να το ιδιοποιηθεί." . (:contains "ΥΠΑΓΩΓΗ" "372"))
    ("Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας." . (:contains "ΥΠΑΓΩΓΗ"))
    ;; ── αλυσίδα συλλογισμού: ο σχεδιαστής απόδειξης στον διάλογο ──
    ("τι χρειάζεται για να στοιχειοθετηθεί κλοπή;" . (:contains "ΑΛΥΣΙΔΑ" "372"))
    ("ποιες είναι οι προϋποθέσεις της υπεξαίρεσης;" . (:contains "ΑΛΥΣΙΔΑ" "375"))
    ;; ορίζοντας πράξεων: ερώτηση για πράξη ΧΩΡΙΣ λήμμα-σκανδάλη ⇒ σκέψη, όχι «δεν κατάλαβα»
    ("πότε τιμωρείται η ανθρωποκτονία;"              . (:contains "ΑΛΥΣΙΔΑ" "299"))
    ;; δάπεδο κατανόησης: ΑΓΝΩΣΤΗ λέξη ⇒ επιφανειακή αναζήτηση στα κείμενα, με πηγές
    ("τι είναι βιβλίο;"                              . (:contains "ΟΡΙΖΕΤΑΙ" "444" "Πηγές"))
    ;; ό,τι λέω, το εξηγώ — και στην αμφισβήτηση απαντώ με τη ΖΩΝΤΑΝΗ μηχανή μου
    ("Τι εννοεις γειωμενο?"                          . (:contains "διάταξη νόμου"))
    ("δηλαδη εχεις απαντησεις ετοιμες και δεν εχεις ιδεα τι λες σωστα?" . (:contains "ΠΩΣ ΔΟΥΛΕΥΩ"))
    ;; ── ζωντανή κριτική δημιουργού (γύρος 3): μη-γειωμένες έννοιες, μνήμη, κώδικας ──
    ;; «τι είναι Χ» ΧΩΡΙΣ γείωση ⇒ αναζήτηση μνειών σε ΟΛΟ το corpus (όχι άγνοια)
    ("Τι είναι πραγματικό περιστατικό?"      . (:contains "μνημονεύουν"))
    ("Τι είναι συμβόλαιο ?"                  . (:contains "γειωμένο ορισμό" "ΑΚ"))
    ;; αυτογνωσία μνήμης: ζωντανή αυτοανάγνωση (τεκμηρίωση+μετρήσεις), όχι τσιτάτα
    ("πόσα ηδη μνημης εχεις?"                . (:contains "βιωματικό υπόστρωμα" "ΕΠΕΙΣΟΔΙΑΚΗ"))
    ;; αυτοδιαφάνεια ΚΩΔΙΚΑ: MOP/introspection από τη ζωντανή εικόνα
    ("τι κάνει η chained-append;"            . (:contains "ΑΤΟΜΙΚΗ πράξη" "source/journal.lisp"))
    ("ποιες υποκλάσεις έχει η legal-rule;"   . (:contains "ΚΛΑΣΗ" "υποκλάσεις"))
    ("τι είναι η *graph* ;"                  . (:contains "ΜΕΤΑΒΛΗΤΗ" "knowledge-graph"))
    ;; ── ορισμοί εννοιών σε ΠΟΛΛΕΣ κλίσεις (το «τι είναι νόμος;» ΕΣΠΑΣΕ ζωντανά) ──
    ("Τι ειναι νόμος?"                       . (:contains "ΑΚ" "Πηγές του δικαίου"))
    ("τι είναι ο νόμος;"                     . (:contains "άρθρο 1"))
    ("τι είναι οι νόμοι;"                    . (:contains "άρθρο 1"))
    ("τι σημαίνει νόμου;"                    . (:contains "άρθρο 1"))
    ("τι είναι το δίκαιο;"                   . (:contains "νόμους" "έθιμα"))
    ("ορισμός του δικαίου"                   . (:contains "άρθρο 1"))
    ("τι είναι τα έθιμα;"                    . (:contains "άρθρο 1"))
    ("τι σημαίνει έθιμο;"                    . (:contains "άρθρο 1"))
    ("τι είναι η αναδρομικότητα του νόμου;"  . (:contains "άρθρο 2" "μέλλον"))
    ("τι είναι η αναδρομική δύναμη του νόμου;" . (:contains "άρθρο 2"))
    ("τι είναι η αναδρομική ισχύς του νόμου;" . (:contains "άρθρο 2"))
    ("τι ειναι το εθιμο"                     . (:contains "άρθρο 1"))
    ("ΤΙ ΕΙΝΑΙ ΝΟΜΟΣ"                        . (:contains "άρθρο 1"))
    ("τι είναι η δημόσια τάξη;"              . (:contains "άρθρο 3"))
    ("τι σημαίνουν οι πηγές του δικαίου;"    . (:contains "άρθρο 1"))
    ;; ── γράμμα του νόμου (πυρήνας) ──
    ("τι λέει το άρθρο 380 του ποινικού κώδικα;" . (:contains "Ληστεία"))
    ("τι λέει το άρθρο 1 ΑΚ;"                . (:contains "Πηγές του δικαίου"))
    ("τι λέει το άρθρο 57 ΑΚ;"               . (:contains "προσωπικότητα"))
    ;; ── ζωντανή συνεδρία δ' (πράξεις λόγου + γλωσσάρι εαυτού + ακρίβεια σχέσης) ──
    ("τι ικανότητες έχεις μέχρι σήμερα;"     . :understood)
    ("τι σημαίνει το «δεν κατάλαβα»;"        . (:contains "πρόθεση"))
    ("πού καταγράφηκε;"                      . (:contains "lessons"))
    ("τι σημαίνει τίμια;"                    . (:contains "πηγή"))
    ("μήπως απλά παπαγαλίζεις;"              . (:contains "δόγμα"))
    ("είσαι το πιο έξυπνο σύστημα;"          . (:contains "μετρι"))
    ("ποια είναι η διαφορά κανόνα δικαίου και νόμου;" . (:contains "κατονομάζεται"))
    ("Μα το άρθρο 1 λέει τι είναι οι κανόνες" . (:contains "παρατήρηση"))
    ("τι είναι ο νόμος τελικά;"              . (:contains "δεν τον ορίζει"))  ; ορθό γένος: ο νόμος
    ;; ── ζωντανή συνεδρία ε' (ενδοσκόπηση/ατζέντα/ρολόι/«1 Σ») ──
    ("πώς λειτουργείς;"                      . (:contains "ΠΩΣ ΔΟΥΛΕΥΩ"))
    ("πως δουλευεις προγραμματιστικα?"       . (:contains "προθέσεις"))
    ("τι αντζεντα εχεις?"                    . (:contains "ΑΤΖΕΝΤΑ"))
    ("τι εκκρεμεί;"                          . (:contains "στόχοι"))
    ("τι μέρα είναι σήμερα;"                 . (:contains "ρολόι"))
    ("αρθρο 1 Σ?"                            . (:contains "άρθρο 1 Σ"))
    ;; ── ΤΙΜΙΑ ΑΓΝΟΙΑ: αυτά ΠΡΕΠΕΙ να μένουν αναπάντητα (όχι μάντεμα) ──
    ;; ΝΕΑ ΠΡΟΔΙΑΓΡΑΦΗ D (self-understanding audit): γενική ερώτηση ⇒ ΤΙΜΙΑ
    ;; διάκριση «κατάλαβα τη γλώσσα / δεν έχω την ικανότητα» — όχι «δεν κατάλαβα»
    ("τι είναι η κβαντομηχανική;"            . (:contains "ΓΕΝΙΚΗΣ γνώσης"))
    ("ποια είναι η πρωτεύουσα της Γαλλίας;"  . (:contains "ΓΕΝΙΚΗΣ γνώσης"))
    ("γράψε μου ένα ποίημα"                  . :unknown))
  "Η ζωντανή σπονδυλική στήλη της κατανόησης: ερώτηση → προσδοκία.")

(defun %gate-check (answer expect)
  "Πληροί η ANSWER την EXPECT; Επιστρέφει (values ok reason)."
  (cond
    ((eq expect :understood)
     (if answer (values t nil) (values nil "περίμενα απάντηση, πήρα άγνοια")))
    ((eq expect :unknown)
     (if answer (values nil (format nil "περίμενα τίμια άγνοια, πήρα: ~A"
                                    (subseq answer 0 (min 60 (length answer)))))
         (values t nil)))
    ((and (consp expect) (eq (car expect) :contains))
     (cond ((null answer) (values nil "περίμενα απάντηση, πήρα άγνοια"))
           ((find-if-not (lambda (s) (search s answer)) (cdr expect))
            (values nil (format nil "λείπει το «~A»"
                                (find-if-not (lambda (s) (search s answer)) (cdr expect)))))
           (t (values t nil))))
    (t (values nil (format nil "άγνωστη προσδοκία ~S" expect)))))

;;; ── Δοκιμαστικά frames της αυτο-κριτικής (στάδιο 4.5): ΜΟΝΟ για την πύλη ──

(defclass %critique-probe-frame (orchestrator.cognition:frame) ())
(defmethod orchestrator.cognition:synthesize ((f %critique-probe-frame) cog)
  (declare (ignore cog)) "ΠΡΟΣΧΕΔΙΟ-ΜΕ-ΠΡΟΒΛΗΜΑ")
(defmethod orchestrator.cognition:critique ((f %critique-probe-frame) draft cog)
  (declare (ignore cog))
  ;; η κριτική ΒΛΕΠΕΙ το προσχέδιο — αυτό κλειδώνει η πύλη
  (values nil (format nil "δοκιμαστικό ζήτημα (είδα: ~A)" draft) nil))

(defclass %empty-draft-frame (orchestrator.cognition:frame) ())
(defmethod orchestrator.cognition:synthesize ((f %empty-draft-frame) cog)
  (declare (ignore cog)) "")

(defun %critique-gate-checks ()
  "Έλεγχοι του σταδίου 4.5 πάνω στο ΠΡΑΓΜΑΤΙΚΟ μονοπάτι (%run-stages)."
  (flet ((answer-for (frame)
           (let ((cog (orchestrator.cognition::make-cognition
                       :input "x" :frame frame
                       :memory (make-instance 'orchestrator.cognition:working-memory))))
             (orchestrator.cognition::%run-stages cog nil)
             (orchestrator.cognition:cog-answer cog))))
    (let ((a1 (answer-for (make-instance '%critique-probe-frame :input "x")))
          (a2 (answer-for (make-instance '%empty-draft-frame :input "x"))))
      (list (cons "αυτο-κριτική: βλέπει το ΠΡΟΣΧΕΔΙΟ και το ζήτημα ΔΗΛΩΝΕΤΑΙ στην απάντηση"
                  (and (stringp a1)
                       (search "ΑΥΤΟΚΡΙΤΙΚΗ" a1)
                       (search "είδα: ΠΡΟΣΧΕΔΙΟ-ΜΕ-ΠΡΟΒΛΗΜΑ" a1)))
            (cons "αυτο-κριτική: κενό προσχέδιο ⇒ τίμια άγνοια (nil), όχι κενή απάντηση"
                  (null a2))))))

(defun run-dialogue-gate ()
  "--dialogue-gate : τρέξε ΟΛΗ τη σουίτα κατανόησης. Κάθε περίπτωση με ΚΑΘΑΡΗ μνήμη
   διαλόγου (ανεξάρτητη). Μία αποτυχία ⇒ exit 1 — η πύλη ΚΟΒΕΙ την παλινδρόμηση."
  (orchestrator.knowledge-packs:ensure-fresh)
  (let ((fails '()) (n 0))
    (dolist (case-entry *dialogue-suite*)
      (destructuring-bind (q . expect) case-entry
        (incf n)
        ;; απομόνωση αυτόματη: κάθε process-request χωρίς :memory παίρνει ΦΡΕΣΚΙΑ
        ;; μνήμη εργασίας — η κατάσταση διαλόγου ζει ΕΚΕΙ, όχι σε global
        (let ((answer (handler-case (orchestrator.cognition:process-request q)
                        (error (e) (format nil "[ΣΦΑΛΜΑ: ~A]" e)))))
          (multiple-value-bind (ok reason) (%gate-check answer expect)
            (if ok
                (format t "  ✓ ~A~%" q)
                (progn (push (list q reason) fails)
                       (format t "  ✗ ~A~%      → ~A~%" q reason)))))))
    ;; ── SELF-UNDERSTANDING / DIALOGUE AUDIT v1 (A–G): αυτοκατανόηση,
    ;;    follow-up, έκθεση ικανοτήτων, επιθεωρήσιμο μητρώο άγνοιας ──
    (flet ((chk (label ok)
             (incf n)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push (list label "απέτυχε") fails)
                        (format t "  ✗ ~A~%" label)))))
      (let ((mem (make-instance 'orchestrator.cognition:working-memory)))
        ;; A: αυτο/μετα — από το self-model, ΟΧΙ corpus keyword search
        (let ((a (orchestrator.cognition:process-request "τι σκέφτεσαι τώρα;" :memory mem)))
          (chk "Α① «τι σκέφτεσαι τώρα;» ⇒ ζωντανή γνωσιακή κατάσταση (όχι άρνηση/κενό)"
               (and a (search "γνωσιακή" a) (search "στόχοι" a)
                    (not (search "δεν έχω ακόμη δομημένη" a)))))
        (let ((a (orchestrator.cognition:process-request "τι δεν μπορείς να κάνεις;" :memory mem)))
          (chk "Α② «τι ΔΕΝ μπορείς;» ⇒ δηλωμένα χρέη καθρέφτη + συνταγματικά όρια"
               (and a (search "ΧΡΕΟΣ" a) (search "Συνταγματικά αδύνατα" a))))
        (let ((a (orchestrator.cognition:process-request "τι σημαίνει δομημένη απάντηση;" :memory mem)))
          (chk "Α③/G «δομημένη απάντηση» ⇒ γλωσσάρι ΕΑΥΤΟΥ — ποτέ τυφλό corpus scan της λέξης"
               (and a (search "ΠΡΟΘΕΣΗ" (string-upcase a))
                    (not (search "ΟΡΙΖΕΤΑΙ στα κείμενα" a)))))
        ;; B: follow-up πάνω στο χωρίο του προηγούμενου γυρίσματος (κοινή μνήμη)
        (let* ((m2 (make-instance 'orchestrator.cognition:working-memory))
               (a1 (orchestrator.cognition:process-request
                    "τι λέει το άρθρο 280 του κώδικα πολιτικής δικονομίας;" :memory m2))
               (a2 (orchestrator.cognition:process-request
                    "τι εννοείς να έχει απαντήσει στην ουσία;" :memory m2)))
          (chk "Β follow-up: «τι εννοείς …;» δένεται στο χωρίο μου (280), όχι νέα αναζήτηση"
               (and a1 a2 (search "προηγούμενο γύρισμα" a2)
                    (search "χωρίο" a2))))
        ;; C: αριθμητική μέσω ΥΠΑΡΧΟΥΣΑΣ γλώσσας φραγμών (guard-metaeval)
        (let ((a (orchestrator.cognition:process-request "1+1=?" :memory mem)))
          (chk "C «1+1=?» ⇒ 2 μέσω guard-metaeval, ΜΗ νομική έξοδος"
               (and a (search "= 2" a) (search "guard-metaeval" a))))
        ;; E: το «καταγράφηκε» είναι ΕΠΙΘΕΩΡΗΣΙΜΟ — όχι ρητορική
        (let* ((m3 (make-instance 'orchestrator.cognition:working-memory))
               (a1 (orchestrator.cognition:process-request
                    "ποιο είναι το βάθος του Ειρηνικού;" :memory m3))
               (a2 (orchestrator.cognition:process-request
                    "πού το κατέγραψες;" :memory m3)))
          (declare (ignore a1))
          (chk "Ε «πού το κατέγραψες;» ⇒ μητρώο άγνοιας: αρχείο + εγγραφές + προτάσεις"
               (and a2 (search "lessons" a2) (search "επεισόδια" a2)
                    (search "προτάσεις" a2))))))
    ;; ── στάδιο 4.5: η αυτο-κριτική βλέπει και κρίνει το προσχέδιο ──
    (dolist (pair (%critique-gate-checks))
      (incf n)
      (if (cdr pair)
          (format t "  ✓ ~A~%" (car pair))
          (progn (push (list (car pair) "απέτυχε") fails)
                 (format t "  ✗ ~A~%" (car pair)))))
    (format t "~%── ΠΥΛΗ ΔΙΑΛΟΓΟΥ: ~D/~D πέρασαν ──~%" (- n (length fails)) n)
    (cond ((null fails) 0)
          (t (format t "~%ΑΠΟΤΥΧΙΕΣ (~D):~%" (length fails))
             (dolist (f (nreverse fails)) (format t "  • ~A — ~A~%" (first f) (second f)))
             1))))

(register-command "--dialogue-gate" (lambda (a) (declare (ignore a)) (run-dialogue-gate)))

(orchestrator.self-model:declare-capability! "διάλογος"
 :description "κατανόηση ερωτημάτων με τίμια άγνοια, αυτογνωσία κατάστασης, σκέψη σε βήματα"
 :package :orchestrator.cognition :functions '("process-request")
 :gate "--dialogue-gate" :depends-on '("γλωσσική-αντίληψη"))

;;; ── ΣΥΜΒΟΛΑΙΑ ΠΑΡΟΧΩΝ (δεσμευτική αυτοπεριγραφή — βλ. --contract-gate) ──

(orchestrator.contracts:defcontract "dialogue-protocol" :protocol
 :package :orchestrator.cognition :system "orchestrator-cli"
 :capability "διάλογος" :role "νόηση"
 :purpose "ερώτημα → frame → απάντηση από τα ζωντανά μητρώα (process-request) με τίμια άγνοια"
 :postconditions '("ό,τι δεν καταλαβαίνει το δηλώνει και ρωτά — δεν προσποιείται")
 :policy-level :συμβουλευτικό :tests '("--dialogue-gate"))
