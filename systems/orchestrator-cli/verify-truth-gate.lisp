;;;; systems/orchestrator-cli/verify-truth-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΤΙΜΙΟΤΗΤΑΣ ΕΠΑΛΗΘΕΥΣΗΣ (FF3 · verify-truth) — docs ≡ CI
;;;; ============================================================================
;;;;
;;;; Ο κανόνας τιμιότητας [0012]: ό,τι ισχυρίζεται το README για ΤΟ ΠΩΣ
;;;; επαληθεύεται το σύστημα πρέπει να ταυτίζεται με ΤΟ ΤΙ ΤΡΕΧΕΙ ΠΡΑΓΜΑΤΙΚΑ το
;;;; CI. Δύο κανονικές εντολές, τεκμηριωμένες παντού ίδια:
;;;;   • ΟΡΘΟΤΗΤΑ = `--gates`  (η ολομέλεια — gates-runner)
;;;;   • TESTS    = docker `--target standalone-test`  (η μία gated σουίτα)
;;;; Η πύλη διαβάζει τα ΠΡΑΓΜΑΤΙΚΑ αρχεία του repo (μέσω της FF1 έδρας ρίζας,
;;;; χωρίς literal /app) και κοκκινίζει σε ΚΑΘΕ απόκλιση README↔CI. Νέα πύλη =
;;;; αυτόματα μέλος της ολομέλειας --gates (μητρώο «-gate»).
;;;;
;;;; Ο φρουρός αποδεικνύεται εξίσου αυστηρός με τον ισχυρισμό: η καθαρή
;;;; %vt-check ελέγχεται σε synthetic fixtures με ΑΚΡΙΒΗ why-codes (θετικά +
;;;; ΚΑΘΕ αρνητικό), πριν εφαρμοστεί στα ζωντανά αρχεία.

(in-package :orchestrator.cli)

;;; ── Κανονικές συμβολοσειρές-αλήθειας (η ΜΙΑ έδρα του τι θεωρείται κανονικό) ──
(defparameter +vt-correctness-command+ "--gates"
  "Η ΜΙΑ κανονική εντολή ορθότητας — η ολομέλεια πυλών (gates-runner).")
(defparameter +vt-tests-command+ "--target standalone-test"
  "Η ΜΙΑ κανονική εντολή tests — το gated docker standalone-test stage.")
(defparameter +vt-escape-suite-token+ "escape-sequences"
  "Η escape σουίτα, απορροφημένη στο standalone-test loop (FF3).")
(defparameter +vt-retired-tokens+
  '("docker-compose.test.yml" "scripts/run-gates.lisp" "run-tests-docker.lisp")
  "Αποσυρμένοι μηχανισμοί: το README ΔΕΝ επιτρέπεται να τους διαφημίζει ως
   τρόπο επαλήθευσης/tests (θα ήταν ψευδής documented διαδρομή).")

(defun %vt-slurp (subpath)
  "Περιεχόμενο αρχείου κάτω από τη ρίζα του Ιδρύματος (FF1 institution-dir) ή
   NIL αν λείπει/δεν διαβάζεται. Χειρισμένο — ποτέ crash στην ολομέλεια."
  (let ((path (orchestrator.paths:institution-dir subpath)))
    (handler-case
        (and (probe-file path) (uiop:read-file-string path))
      (serious-condition () nil))))

(defun %vt-has (haystack needle)
  "Το NEEDLE υπάρχει (ως substring) στο HAYSTACK; NIL-safe."
  (and haystack needle (search needle haystack) t))

(defun %vt-check (readme ci dockerfile run-tests-docker-present)
  "Ο ΚΑΘΑΡΟΣ κανόνας τιμιότητας (testable). Επιστρέφει (values verdict why):
   verdict :ok (docs≡CI) ή :invalid (κλειστός why). Καμία παρενέργεια/IO.
     • README/CI/Dockerfile: το πλήρες κείμενο (ή NIL αν λείπει).
     • run-tests-docker-present: υπάρχει ο αποσυρμένος escape driver;"
  (block check
    ;; 0. τα τρία αρχεία-πηγές πρέπει να ΥΠΑΡΧΟΥΝ
    (unless readme     (return-from check (values :invalid :readme_missing)))
    (unless ci         (return-from check (values :invalid :ci_missing)))
    (unless dockerfile (return-from check (values :invalid :dockerfile_missing)))
    ;; L1 ΟΡΘΟΤΗΤΑ κανονική: το CI ΤΡΕΧΕΙ --gates ΚΑΙ το README το τεκμηριώνει
    (unless (and (%vt-has ci +vt-correctness-command+)
                 (%vt-has readme +vt-correctness-command+))
      (return-from check (values :invalid :correctness_command_divergent)))
    ;; L2 TESTS κανονικά: το CI ΧΤΙΖΕΙ --target standalone-test ΚΑΙ το README το τεκμηριώνει
    (unless (and (%vt-has ci +vt-tests-command+)
                 (%vt-has readme +vt-tests-command+))
      (return-from check (values :invalid :tests_command_divergent)))
    ;; L3 κανένας αποσυρμένος μηχανισμός δεν διαφημίζεται στο README
    (dolist (tok +vt-retired-tokens+)
      (when (%vt-has readme tok)
        (return-from check (values :invalid :retired_mechanism_advertised))))
    ;; L4 escape σουίτα gated: στο standalone-test loop ΚΑΙ ο αποσυρμένος driver λείπει
    (unless (%vt-has dockerfile +vt-escape-suite-token+)
      (return-from check (values :invalid :escape_suite_ungated)))
    (when run-tests-docker-present
      (return-from check (values :invalid :retired_driver_present)))
    (values :ok nil)))

(defun %vt-live ()
  "Εφαρμογή του κανόνα στα ΖΩΝΤΑΝΑ αρχεία του repo. (values verdict why),
   verdict ∈ {:ok :invalid :skipped}.
   SOURCE-TREE GATE: όταν ΚΑΝΕΝΑ doc/CI αρχείο-πηγή δεν υπάρχει (π.χ. μέσα στο
   minimal runtime image, όπου το repo source ΔΕΝ αντιγράφεται — ίδια
   ανεκτικότητα με το architecture-gate στο απόν constitution), ο κανόνας ΔΕΝ
   εφαρμόζεται ΕΔΩ· επιβάλλεται όπου υπάρχει source tree (dev/CI checkout). Έτσι
   η in-image ολομέλεια δεν κοκκινίζει ψευδώς, ενώ κάθε απόκλιση στο source
   πιάνεται. Μερική παρουσία (README ναι, CI όχι) ⇒ γνήσιο :invalid (σπασμένο
   checkout), όχι skip."
  (let ((readme (%vt-slurp "README.md"))
        (ci (%vt-slurp ".github/workflows/docker-orchestrator.yml"))
        (dockerfile (%vt-slurp "Dockerfile"))
        (rtd (and (%vt-slurp "run-tests-docker.lisp") t)))
    (if (and (null readme) (null ci) (null dockerfile))
        (values :skipped :source_tree_absent)
        (%vt-check readme ci dockerfile rtd))))

(defun %vt-selftest ()
  "Απόδειξη φρουρού: synthetic fixtures με ΑΚΡΙΒΗ why-codes (θετικό + κάθε
   αρνητικό). Επιστρέφει (values fails total)."
  (let ((fails '()) (total 0))
    (flet ((expect (label readme ci df rtd want-verdict want-why)
             (incf total)
             (multiple-value-bind (v w) (%vt-check readme ci df rtd)
               (if (and (eq v want-verdict) (eq w want-why))
                   (format t "  ✓ ~A~%" label)
                   (progn (push label fails)
                          (format t "  ✗ ~A (πήρα ~A/~A)~%" label v w))))))
      (let ((ok-readme (format nil "run --gates· δες docker build ~A" +vt-tests-command+))
            (ok-ci (format nil "docker run … --gates~%docker build ~A ." +vt-tests-command+))
            (ok-df (format nil "for t in … ~A …; do sbcl …; done" +vt-escape-suite-token+)))
        ;; θετικό: docs≡CI, escape gated, driver αποσυρμένος
        (expect "① docs≡CI πλήρες ⇒ :ok" ok-readme ok-ci ok-df nil :ok nil)
        ;; L0: αρχεία-πηγές λείπουν
        (expect "② README λείπει ⇒ :readme_missing" nil ok-ci ok-df nil :invalid :readme_missing)
        (expect "③ CI λείπει ⇒ :ci_missing" ok-readme nil ok-df nil :invalid :ci_missing)
        (expect "④ Dockerfile λείπει ⇒ :dockerfile_missing" ok-readme ok-ci nil nil :invalid :dockerfile_missing)
        ;; L1: το README δεν τεκμηριώνει --gates ενώ το CI το τρέχει
        (expect "⑤ README χωρίς --gates ⇒ :correctness_command_divergent"
                (format nil "δες docker build ~A" +vt-tests-command+) ok-ci ok-df nil
                :invalid :correctness_command_divergent)
        ;; L1: το CI δεν τρέχει --gates
        (expect "⑥ CI χωρίς --gates ⇒ :correctness_command_divergent"
                ok-readme (format nil "docker build ~A ." +vt-tests-command+) ok-df nil
                :invalid :correctness_command_divergent)
        ;; L2: το README δεν τεκμηριώνει το standalone-test
        (expect "⑦ README χωρίς standalone-test ⇒ :tests_command_divergent"
                "run --gates μόνο" ok-ci ok-df nil :invalid :tests_command_divergent)
        ;; L2: το CI δεν χτίζει standalone-test
        (expect "⑧ CI χωρίς standalone-test ⇒ :tests_command_divergent"
                ok-readme "docker run … --gates" ok-df nil :invalid :tests_command_divergent)
        ;; L3: το README διαφημίζει αποσυρμένο μηχανισμό
        (expect "⑨ README διαφημίζει docker-compose.test.yml ⇒ :retired_mechanism_advertised"
                (format nil "~A· δες docker-compose.test.yml για All tests" ok-readme) ok-ci ok-df nil
                :invalid :retired_mechanism_advertised)
        (expect "⑩ README αναφέρει scripts/run-gates.lisp ⇒ :retired_mechanism_advertised"
                (format nil "~A· τρέξε scripts/run-gates.lisp" ok-readme) ok-ci ok-df nil
                :invalid :retired_mechanism_advertised)
        (expect "⑩β README αναφέρει run-tests-docker.lisp ⇒ :retired_mechanism_advertised"
                (format nil "~A· δες run-tests-docker.lisp" ok-readme) ok-ci ok-df nil
                :invalid :retired_mechanism_advertised)
        ;; L4: escape σουίτα ΔΕΝ είναι στο loop
        (expect "⑪ Dockerfile χωρίς escape-sequences ⇒ :escape_suite_ungated"
                ok-readme ok-ci "for t in source-profile …; do …; done" nil
                :invalid :escape_suite_ungated)
        ;; L4: ο αποσυρμένος driver υπάρχει ακόμη
        (expect "⑫ run-tests-docker.lisp παρών ⇒ :retired_driver_present"
                ok-readme ok-ci ok-df t :invalid :retired_driver_present)))
    (values fails total)))

(defun run-verify-truth-gate ()
  "--verify-truth-gate : ο κανόνας τιμιότητας [0012] — README ≡ CI, κλειδωμένος.
   (1) απόδειξη φρουρού σε fixtures· (2) εφαρμογή στα ΖΩΝΤΑΝΑ αρχεία. Κόκκινο
   αν οτιδήποτε αποκλίνει — ποτέ «φαίνεται σωστό»."
  (format t "~%── ΠΥΛΗ ΤΙΜΙΟΤΗΤΑΣ ΕΠΑΛΗΘΕΥΣΗΣ (FF3): docs ≡ CI ──~%")
  (multiple-value-bind (fails total) (%vt-selftest)
    (multiple-value-bind (verdict why) (%vt-live)
      ;; :ok (source tree, ταυτίζεται) ΚΑΙ :skipped (source tree απόν — minimal
      ;; image) μετρούν ως πέρασμα· μόνο :invalid (γνήσια απόκλιση) κοκκινίζει.
      (let ((live-ok (member verdict '(:ok :skipped))))
        (case verdict
          (:ok      (format t "  ✓ ⑬ ζωντανά αρχεία repo: README ≡ CI (ορθότητα=--gates, tests=--target standalone-test)~%"))
          (:skipped (format t "  ⊘ ⑬ source tree απόν (minimal image) — verify-truth επιβάλλεται στο source, όχι εδώ~%"))
          (t        (format t "  ✗ ⑬ ζωντανά αρχεία repo: ΑΠΟΚΛΙΣΗ ⇒ ~A~%" why)))
        (let ((total+1 (1+ total))
              (ok-count (+ (- total (length fails)) (if live-ok 1 0))))
          (format t "── ΤΙΜΙΟΤΗΤΑ ΕΠΑΛΗΘΕΥΣΗΣ: ~D/~D · canonical: ορθότητα=~A tests=~A ──~%"
                  ok-count total+1 +vt-correctness-command+ +vt-tests-command+)
          (if (and (null fails) live-ok) 0 1))))))

(register-command "--verify-truth-gate"
  (lambda (a) (declare (ignore a)) (run-verify-truth-gate)))

(orchestrator.self-model:declare-capability! "τιμιότητα-επαλήθευσης"
 :description "FF3 verify-truth: το README ταυτίζεται με το τι τρέχει πραγματικά το CI — δύο κανονικές εντολές (--gates, --target standalone-test), καμία ψευδής documented διαδρομή"
 :package :orchestrator.cli :functions '("run-verify-truth-gate" "%vt-check")
 :gate "--verify-truth-gate")

(orchestrator.contracts:defcontract "verify-truth-protocol" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "τιμιότητα-επαλήθευσης" :role "έλεγχος"
 :purpose "docs ≡ CI: το README τεκμηριώνει ΑΚΡΙΒΩΣ τις εντολές που τρέχει το CI (--gates ορθότητα, --target standalone-test tests)· κανένας αποσυρμένος μηχανισμός δεν διαφημίζεται"
 :preconditions '("README.md, .github/workflows/docker-orchestrator.yml, Dockerfile υπάρχουν κάτω από τη ρίζα του Ιδρύματος")
 :postconditions '("κάθε απόκλιση README↔CI ⇒ κόκκινη ολομέλεια· ο φρουρός αποδεδειγμένος σε fixtures με ακριβή why-codes")
 :legal-critical nil :policy-level :φραγή
 :tests '("--verify-truth-gate"))
