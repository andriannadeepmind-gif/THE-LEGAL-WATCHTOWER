;;;; systems/orchestrator-cli/capability-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΤΗΣ ΙΚΑΝΟΤΗΤΑΣ: --capability-gate — το ΜΕΤΡΟ ως ratchet [ΤΑΒΑΝΙ #1]
;;;; ============================================================================
;;;;
;;;; «Πόσο καλό είναι;» απαντιέται με αριθμό που ΦΥΛΑΣΣΕΤΑΙ από πύλη — ό,τι κάνει
;;;; το golden-gate για το ΚΕΙΜΕΝΟ, αυτή η πύλη για την ΙΚΑΝΟΤΗΤΑ: η βαθμολογία
;;;; στα παγωμένα, ντετερμινιστικά benchmarks ΔΕΝ επιτρέπεται να πέσει ποτέ κάτω
;;;; από το committed baseline (deployment/verify/capability-baseline.sexp).
;;;;
;;;; Μετρικές — ΑΠΟΚΛΕΙΣΤΙΚΑ από τις υπάρχουσες ΜΙΕΣ έδρες (κανένα stdout
;;;; scraping, καμία δεύτερη υλοποίηση):
;;;;   · %legal-eval-run  (legal-eval.lisp)         — ①μηχανή-σε-gold ②end-to-end
;;;;     ⊕απαιτητικό: η σκάλα αφήγηση→γεγονότα→υπαγωγή σε 12 παγωμένες υποθέσεις.
;;;;   · %judge-metrics   (jurisprudence-judge.lisp) — leave-one-out hit@1/5/10
;;;;     στην πραγματική νομολογία + content-addressed :dataset-stamp.
;;;;
;;;; ΝΟΜΟΙ ΤΗΣ ΠΥΛΗΣ (fail-closed, καμία σιωπηλή σύγκριση ανόμοιων):
;;;;   1. Baseline ΑΠΟΝ/μη-αναγνώσιμο ⇒ ΚΟΚΚΙΝΟ (πύλη ικανότητας χωρίς μέτρο
;;;;      δεν είναι honest-skip — το μέτρο είναι committed υποχρέωση).
;;;;   2. Gold-συνέπεια: ①μηχανή-σε-gold = 100% ΠΑΝΤΑ (νόμος, όχι ratchet —
;;;;      ο συμβολικός κριτής πάνω σε σωστά γεγονότα δεν δικαιούται λάθος).
;;;;   3. Ίδιο μέτρο: eval-πληθυσμοί ίδιοι με baseline ΚΑΙ judge :dataset-stamp
;;;;      ταυτόσημο — αλλιώς ΚΟΚΚΙΝΟ «drift: συνειδητό re-baseline», ΟΧΙ
;;;;      σύγκριση σε άλλο σύνολο (νέα νομολογία = καλοδεχούμενη, αλλά το μέτρο
;;;;      ξανα-ευλογείται ρητά με --capability-baseline + commit).
;;;;   4. Ratchet: κάθε μετρική ≥ baseline. Βελτίωση = πράσινο + πρόσκληση
;;;;      re-baseline (η πύλη ΔΕΝ γράφει — read-only, όπως όλες).
;;;;   5. Scorecard: εκπέμπεται data-only μέσω της ΜΙΑΣ έδρας εγγραφής
;;;;      (orchestrator.safe-read:data-to-string) — μηχανικά αναγνώσιμο.
;;;;
;;;; Το ΚΡΥΦΟ σετ (hidden benchmark) ΔΕΝ ζει εδώ: παραμένει στην έδρα του
;;;; --external-benchmark-gate (bundle εκτός repo, κατοχή δημιουργού/Κριτή).
;;;; Εδώ: το ΕΣΩΤΕΡΙΚΟ παγωμένο μέτρο. Δύο ρόλοι, δύο έδρες, μηδέν επικάλυψη.

(in-package :orchestrator.cli)

(defparameter *capability-baseline-path* nil
  "Override του μονοπατιού baseline (tests/fixtures). NIL ⇒ το κανονικό
   committed: deployment/verify/capability-baseline.sexp υπό institution-root.")

(defun %capability-baseline-path ()
  (or *capability-baseline-path*
      (merge-pathnames "deployment/verify/capability-baseline.sexp"
                       (orchestrator.paths:institution-root))))

(defun %capability-metrics ()
  "Η ΜΙΑ σύνθεση μετρικών ικανότητας — καθαρό data-only plist από τις δύο έδρες.
   Ντετερμινιστικό: παγωμένα +legal-eval-cases+ + committed νομολογία γράφου."
  (let ((ev (%legal-eval-run))
        (jm (%judge-metrics)))
    (list :schema :capability-scorecard/1
          :legal-eval (list :engine-total (getf ev :engine-total)
                            :engine-ok (getf ev :engine-ok)
                            :e2e-total (getf ev :e2e-total)
                            :e2e-ok (getf ev :e2e-ok)
                            :pos-total (getf ev :pos-total)
                            :engine-pos (getf ev :engine-pos)
                            :e2e-pos (getf ev :e2e-pos))
          :judge (list :decisions (getf jm :decisions)
                       :multi (getf jm :multi)
                       :trials (getf jm :trials)
                       :predictable (getf jm :predictable)
                       :hit1 (getf jm :hit1)
                       :hit5 (getf jm :hit5)
                       :hit10 (getf jm :hit10))
          :judge-dataset-stamp (getf jm :dataset-stamp))))

(defun run-capability-baseline (&optional recorded-at)
  "--capability-baseline [YYYY-MM-DD] : ΣΥΝΕΙΔΗΤΗ καθιέρωση/ανανέωση του μέτρου
   (το ανάλογο του GOLDEN_WRITE — ξεχωριστή εντολή, ΟΧΙ μονοπάτι της πύλης).
   Γράφει το baseline ατομικά, μέσω της ΜΙΑΣ data-only έδρας εγγραφής."
  (let* ((m (%capability-metrics))
         (base (list :schema :capability-baseline/1
                     :recorded-at (or recorded-at
                                      (orchestrator.time:format-iso8601
                                       (orchestrator.time:now :source :deterministic)))
                     :legal-eval (getf m :legal-eval)
                     :judge (getf m :judge)
                     :judge-dataset-stamp (getf m :judge-dataset-stamp)))
         (path (%capability-baseline-path)))
    (orchestrator.journal:write-file-atomic
     path (orchestrator.safe-read:data-to-string base))
    (format t "✓ Capability baseline καθορίστηκε -> ~A~%" (namestring path))
    (format t "~A~%" (orchestrator.safe-read:data-to-string base))
    0))

(defun run-capability-gate ()
  "--capability-gate : η ικανότητα δεν οπισθοδρομεί ποτέ σιωπηλά. Read-only."
  (let ((total 0) (fails '()))
    (flet ((chk (label ok &optional detail)
             (incf total)
             (if ok (format t "  ✓ ~A~%" label)
                 (progn (push label fails)
                        (format t "  ✗ ~A~@[~%      → ~A~]~%" label detail)))))
      (format t "~%── ΠΥΛΗ ΙΚΑΝΟΤΗΤΑΣ (capability ratchet, read-only) ──~%")
      (let* ((path (%capability-baseline-path))
             (base (handler-case (orchestrator.safe-read:read-data-file path)
                     (error (e)
                       (chk "baseline παρόν και αναγνώσιμο (safe-read)" nil
                            (format nil "~A: ~A" (namestring path) e))
                       nil))))
        ;; ΑΠΟΝ/κενό baseline ⇒ ΚΟΚΚΙΝΟ ρητά — ΟΧΙ σιωπηλό πράσινο με μηδέν
        ;; ελέγχους (το read-data-file επιστρέφει NIL σε απόν αρχείο ΧΩΡΙΣ
        ;; σφάλμα· χωρίς αυτόν τον έλεγχο η πύλη θα προσπερνούσε τα πάντα —
        ;; false-green που έπιασε το αρνητικό fixture του proof, κλεισμένο εδώ).
        (when (and (null base) (null fails))
          (chk "baseline παρόν (το μέτρο είναι committed υποχρέωση)" nil
               (format nil "ΑΠΟΝ: ~A — τρέξε --capability-baseline + commit" (namestring path))))
        (when base
          (chk "baseline schema :capability-baseline/1"
               (eq :capability-baseline/1 (getf base :schema)))
          (let* ((m (%capability-metrics))
                 (ev (getf m :legal-eval)) (bev (getf base :legal-eval))
                 (jd (getf m :judge))     (bjd (getf base :judge)))
            ;; 2. Ο ΝΟΜΟΣ του gold: ο συμβολικός κριτής σε σωστά γεγονότα = 100%.
            (chk (format nil "① μηχανή-σε-gold = 100% (~D/~D) — νόμος, όχι ratchet"
                         (getf ev :engine-ok) (getf ev :engine-total))
                 (and (plusp (getf ev :engine-total))
                      (= (getf ev :engine-ok) (getf ev :engine-total))))
            (chk (format nil "① απαιτητικό (:in/:out) μηχανή = 100% (~D/~D)"
                         (getf ev :engine-pos) (getf ev :pos-total))
                 (and (plusp (getf ev :pos-total))
                      (= (getf ev :engine-pos) (getf ev :pos-total))))
            ;; 3. Ίδιο μέτρο — ποτέ σύγκριση ανόμοιων.
            (chk "eval-σύνολο ταυτόσημο με baseline (ίδιοι πληθυσμοί)"
                 (and (eql (getf ev :engine-total) (getf bev :engine-total))
                      (eql (getf ev :e2e-total) (getf bev :e2e-total))
                      (eql (getf ev :pos-total) (getf bev :pos-total)))
                 (format nil "τρέχον ~A/~A/~A ≠ baseline ~A/~A/~A — το παγωμένο σετ άλλαξε: συνειδητό re-baseline (--capability-baseline + commit)"
                         (getf ev :engine-total) (getf ev :e2e-total) (getf ev :pos-total)
                         (getf bev :engine-total) (getf bev :e2e-total) (getf bev :pos-total)))
            (chk "judge dataset-stamp ταυτόσημο με baseline (ίδια νομολογία)"
                 (equal (getf m :judge-dataset-stamp)
                        (getf base :judge-dataset-stamp))
                 (format nil "drift νομολογίας: τρέχον ~A ≠ baseline ~A — νέα/αλλαγμένη νομολογία απαιτεί συνειδητό re-baseline"
                         (getf m :judge-dataset-stamp) (getf base :judge-dataset-stamp)))
            ;; 4. RATCHET: καμία μετρική κάτω από το baseline.
            (flet ((ratchet (label cur old)
                     (chk (format nil "~A: ~D ≥ baseline ~D~@[ (ΒΕΛΤΙΩΣΗ +~D — σκέψου re-baseline)~]"
                                  label cur old (and cur old (> cur old) (- cur old)))
                          (and (integerp cur) (integerp old) (>= cur old))
                          (format nil "ΟΠΙΣΘΟΔΡΟΜΗΣΗ: ~A έπεσε ~A→~A — η ικανότητα δεν επιτρέπεται να χαθεί σιωπηλά" label old cur))))
              (ratchet "② end-to-end" (getf ev :e2e-ok) (getf bev :e2e-ok))
              (ratchet "⊕ end-to-end απαιτητικό" (getf ev :e2e-pos) (getf bev :e2e-pos))
              (ratchet "judge hit@1" (getf jd :hit1) (getf bjd :hit1))
              (ratchet "judge hit@5" (getf jd :hit5) (getf bjd :hit5))
              (ratchet "judge hit@10" (getf jd :hit10) (getf bjd :hit10))
              (ratchet "judge predictable (ταβάνι)" (getf jd :predictable)
                       (getf bjd :predictable)))
            ;; 5. Scorecard: machine-readable, μέσω της ΜΙΑΣ data-only έδρας.
            (format t "~%════ CAPABILITY-SCORECARD ════~%")
            (write-string (orchestrator.safe-read:data-to-string m))
            (format t "~%════ END-SCORECARD ════~%"))))
      (format t "~%── ΠΥΛΗ ΙΚΑΝΟΤΗΤΑΣ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
      (if fails 1 0))))

(register-command "--capability-gate"
  (lambda (a) (declare (ignore a)) (run-capability-gate)))
(register-command "--capability-baseline"
  (lambda (a) (run-capability-baseline (first a))))

(orchestrator.self-model:declare-capability! "μέτρο-ικανότητας"
 :description "capability ratchet: τα παγωμένα ντετερμινιστικά benchmarks (legal-eval σκάλα ①/②/⊕ + judge leave-one-out hit@1/5/10) συγκρίνονται με committed baseline σε ΚΑΘΕ ολομέλεια — οπισθοδρόμηση = ΚΟΚΚΙΝΟ, gold-συνέπεια 100% = νόμος, drift dataset = ρητό re-baseline, scorecard data-only· read-only πύλη + χωριστή συνειδητή εντολή καθιέρωσης --capability-baseline"
 :package :orchestrator.cli
 :functions '("run-capability-gate" "run-capability-baseline" "%capability-metrics")
 :gate "--capability-gate"
 :depends-on '())

(orchestrator.contracts:defcontract "capability-ratchet" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "μέτρο-ικανότητας" :role "έλεγχος"
 :purpose "η μετρημένη ικανότητα (γείωση + νομολογιακή πρόβλεψη) δεν οπισθοδρομεί ποτέ σιωπηλά: κάθε commit κρίνεται στον ΙΔΙΟ πάγκο (ταυτόσημοι πληθυσμοί + dataset-stamp) απέναντι στο committed μέτρο· βελτίωση περνά, πτώση κοκκινίζει, drift απαιτεί ρητή ευλογία"
 :inputs '("deployment/verify/capability-baseline.sexp (committed μέτρο)"
           "+legal-eval-cases+ (παγωμένο eval set)"
           "deployment/data/decisions/** (committed νομολογία → γράφος)")
 :outputs '("ετυμηγορία ανά μετρική + data-only scorecard (:capability-scorecard/1)")
 :preconditions '("οι έδρες %legal-eval-run και %judge-metrics είναι ντετερμινιστικές")
 :postconditions '("η πύλη δεν έγραψε τίποτα — read-only· baseline γράφεται ΜΟΝΟ από --capability-baseline")
 :side-effects '("καμία")
 :legal-critical t :policy-level :φραγή
 :audit "scorecard + baseline: πλήρεις αριθμοί και stamps, μηχανικά αναγνώσιμα"
 :rollback "revert του commit εισαγωγής"
 :tests '("--capability-gate" "tests/capability-gate-test.lisp"))
