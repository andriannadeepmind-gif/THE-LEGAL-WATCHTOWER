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
(defparameter +vt-tests-command-2+ "--target verifier-conformance"
  "Η ΔΕΥΤΕΡΗ κανονική CI test διαδρομή (cross-language verifier). Αφού το README
   την τεκμηριώνει ως canonical, ΠΡΕΠΕΙ κι αυτή να είναι εντός του φρουρού
   (εύρημα Codex PR#2: αλλιώς μια documented CI test path μένει αφύλαχτη).")
(defparameter +vt-escape-suite-token+ "escape-sequences"
  "Η escape σουίτα, απορροφημένη στο standalone-test loop (FF3).")
;; [audit#3] Το verify-truth ήλεγχε ΠΑΡΟΥΣΙΑ εντολών (λέξεις), όχι την ΕΚΤΕΛΕΣΤΙΚΗ
;; καλωδίωση που τις κάνει ουσιαστικές. Αυτά τα tokens επιβάλλουν ότι η authoritative
;; ολομέλεια είναι FAIL-CLOSED (pipefail + η δοκιμασμένη έδρα κρίσης) και ότι το
;; standalone inventory ΠΑΡΑΓΕΤΑΙ (καμία χειρόγραφη λίστα) — «CI runs --gates» παύει να
;; είναι κούφιο. Ευθυγράμμιση με [audit#1] (false-green) + [audit#2] (test inventory).
(defparameter +vt-pipefail-token+ "pipefail"
  "Η authoritative --gates CI ΠΡΕΠΕΙ να φέρει pipefail (exit code του docker, όχι του tee).")
(defparameter +vt-plenary-assessor-token+ "assess-gate-plenary"
  "Η ΜΙΑ δοκιμασμένη έδρα κρίσης ολομέλειας — καμία grep-πολιτική στο YAML.")
(defparameter +vt-derived-runner-token+ "run-standalone-suites.sh"
  "Το standalone inventory ΠΑΡΑΓΕΤΑΙ από το filesystem (όχι χειρόγραφη λίστα).")
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

(defun %vt-strip-yaml-comments (text)
  "Αφαιρεί YAML σχόλια (# … έως τέλος γραμμής) ώστε ο έλεγχος «το CI ΤΡΕΧΕΙ την
   εντολή» να ΜΗΝ ικανοποιείται από αναφορά σε σχόλιο (εύρημα Codex PR#2: ένα
   σχόλιο που μνημονεύει --gates δεν σημαίνει ότι το CI τρέχει --gates). NIL-safe.
   Full-line σχόλιο (^\\s*#) φεύγει ολόκληρο· inline « #…» κόβεται από το κενό+#."
  (when text
    (with-output-to-string (out)
      (with-input-from-string (in text)
        (loop for line = (read-line in nil nil)
              while line
              do (let* ((trimmed (string-left-trim '(#\Space #\Tab) line))
                        (kept (cond
                                ;; full-line comment ⇒ κενή γραμμή
                                ((and (plusp (length trimmed))
                                      (char= (char trimmed 0) #\#)) "")
                                ;; inline « #» ⇒ κόψε από εκεί
                                (t (let ((p (search " #" line)))
                                     (if p (subseq line 0 p) line))))))
                   (write-line kept out)))))))

(defun %vt-gate-counts-in (text)
  "Όλοι οι ρητοί αριθμοί-πλήθους πυλών σε κείμενο: κάθε «N πύλες» / «N gates».
   Επιστρέφει λίστα integers (κενή αν κανένας). NIL-safe. Χρησιμεύει ώστε
   κανένας στατικός αριθμός πυλών στο README/CI να μη μένει stale (FF3 εύρημα
   [0029] #1): αν υπάρχει, ΠΡΕΠΕΙ να ταυτίζεται με τον ζωντανό αριθμό."
  (when text
    (mapcar #'parse-integer
            (cl-ppcre:all-matches-as-strings "\\d+(?=\\s*(?:πύλες|gates))" text))))

(defun %vt-check (readme ci dockerfile run-tests-docker-present live-gate-count)
  "Ο ΚΑΘΑΡΟΣ κανόνας τιμιότητας (testable). Επιστρέφει (values verdict why):
   verdict :ok (docs≡CI) ή :invalid (κλειστός why). Καμία παρενέργεια/IO.
     • README/CI/Dockerfile: το πλήρες κείμενο (ή NIL αν λείπει).
     • run-tests-docker-present: υπάρχει ο αποσυρμένος escape driver;
     • live-gate-count: ο ΖΩΝΤΑΝΟΣ αριθμός πυλών (μητρώο) — L5."
  (block check
    ;; 0. τα τρία αρχεία-πηγές πρέπει να ΥΠΑΡΧΟΥΝ
    (unless readme     (return-from check (values :invalid :readme_missing)))
    (unless ci         (return-from check (values :invalid :ci_missing)))
    (unless dockerfile (return-from check (values :invalid :dockerfile_missing)))
    ;; Το «το CI ΤΡΕΧΕΙ Χ» ελέγχεται στο CI ΧΩΡΙΣ σχόλια (εύρημα Codex PR#2): ένα
    ;; σχόλιο που μνημονεύει την εντολή δεν σημαίνει ότι το CI την τρέχει.
    (let ((ci-code (%vt-strip-yaml-comments ci)))
      ;; L1 ΟΡΘΟΤΗΤΑ κανονική: το CI ΤΡΕΧΕΙ --gates ΚΑΙ το README το τεκμηριώνει
      (unless (and (%vt-has ci-code +vt-correctness-command+)
                   (%vt-has readme +vt-correctness-command+))
        (return-from check (values :invalid :correctness_command_divergent)))
      ;; L2 TESTS κανονικά: το CI ΧΤΙΖΕΙ --target standalone-test ΚΑΙ το README το τεκμηριώνει
      (unless (and (%vt-has ci-code +vt-tests-command+)
                   (%vt-has readme +vt-tests-command+))
        (return-from check (values :invalid :tests_command_divergent)))
      ;; L2b: η ΔΕΥΤΕΡΗ documented CI test path (verifier-conformance) — CI τρέχει ≡ README τεκμηριώνει
      (unless (and (%vt-has ci-code +vt-tests-command-2+)
                   (%vt-has readme +vt-tests-command-2+))
        (return-from check (values :invalid :tests_command_2_divergent)))
      ;; L6 [audit#3] Η authoritative ολομέλεια είναι ΕΚΤΕΛΕΣΤΙΚΑ FAIL-CLOSED, όχι
      ;;    απλή αναφορά της εντολής: το CI (χωρίς σχόλια) ΠΡΕΠΕΙ να φέρει pipefail ΚΑΙ
      ;;    την δοκιμασμένη έδρα κρίσης (assess-gate-plenary). Αλλιώς «CI runs --gates»
      ;;    είναι κούφιο — crash/false-green (ο ίδιος ο κριτής #3: λέξεις όχι εκτέλεση).
      (unless (and (%vt-has ci-code +vt-pipefail-token+)
                   (%vt-has ci-code +vt-plenary-assessor-token+))
        (return-from check (values :invalid :authoritative_gates_not_failclosed))))
    ;; L7 [audit#3] Το standalone-test inventory ΠΑΡΑΓΕΤΑΙ (run-standalone-suites.sh),
    ;;    όχι χειρόγραφη λίστα — αλλιώς «--target standalone-test» δεν αποδεικνύει πλήρη
    ;;    σουίτα (ο κριτής #2 βρήκε 7 ξεχασμένες).
    (unless (%vt-has dockerfile +vt-derived-runner-token+)
      (return-from check (values :invalid :standalone_suites_not_derived)))
    ;; L3 κανένας αποσυρμένος μηχανισμός δεν διαφημίζεται στο README
    (dolist (tok +vt-retired-tokens+)
      (when (%vt-has readme tok)
        (return-from check (values :invalid :retired_mechanism_advertised))))
    ;; L4 escape σουίτα gated: στο standalone-test loop ΚΑΙ ο αποσυρμένος driver λείπει
    (unless (%vt-has dockerfile +vt-escape-suite-token+)
      (return-from check (values :invalid :escape_suite_ungated)))
    (when run-tests-docker-present
      (return-from check (values :invalid :retired_driver_present)))
    ;; L5 κανένας stale αριθμός πυλών: κάθε ρητό «N πύλες» σε README/CI ≡ ζωντανός
    ;; αριθμός (μητρώο). Προτίμηση: μηδενικός στατικός αριθμός (self-describing)·
    ;; αλλά αν κάποιος γράψει αριθμό, ΠΡΕΠΕΙ να είναι σωστός — αλλιώς κόκκινο.
    (dolist (txt (list readme ci))
      (dolist (claimed (%vt-gate-counts-in txt))
        (unless (= claimed live-gate-count)
          (return-from check (values :invalid :stale_gate_count)))))
    (values :ok nil)))

(defun %vt-live-gate-count ()
  "Ο ΖΩΝΤΑΝΟΣ αριθμός πυλών: εντολές του μητρώου που λήγουν σε «-gate» (ίδια
   λογική με την ολομέλεια run-all-gates). Η ΜΙΑ αλήθεια του πλήθους."
  (let ((n 0))
    (maphash (lambda (k v)
               (declare (ignore v))
               (when (and (> (length k) 5)
                          (string= "-gate" k :start2 (- (length k) 5)))
                 (incf n)))
             *commands*)
    n))

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
        (%vt-check readme ci dockerfile rtd (%vt-live-gate-count)))))

(defun %vt-selftest ()
  "Απόδειξη φρουρού: synthetic fixtures με ΑΚΡΙΒΗ why-codes (θετικό + κάθε
   αρνητικό). Επιστρέφει (values fails total)."
  (let ((fails '()) (total 0))
    (flet ((expect (label readme ci df rtd want-verdict want-why &optional (gc 23))
             (incf total)
             (multiple-value-bind (v w) (%vt-check readme ci df rtd gc)
               (if (and (eq v want-verdict) (eq w want-why))
                   (format t "  ✓ ~A~%" label)
                   (progn (push label fails)
                          (format t "  ✗ ~A (πήρα ~A/~A)~%" label v w))))))
      (let ((ok-readme (format nil "run --gates· δες docker build ~A· και ~A"
                               +vt-tests-command+ +vt-tests-command-2+))
            ;; [audit#3] ok-ci φέρει την ΕΚΤΕΛΕΣΤΙΚΗ καλωδίωση: pipefail + assess-gate-plenary.
            (ok-ci (format nil "set -o pipefail~%docker run … --gates … | tee log~%~
                                ./deployment/verify/assess-gate-plenary.sh log ${PIPESTATUS}~%~
                                docker build ~A .~%docker build ~A ."
                           +vt-tests-command+ +vt-tests-command-2+))
            ;; ok-df: derived suite runner + η escape σουίτα.
            (ok-df (format nil "RUN /app/docker/run-standalone-suites.sh …~%~
                                # inventory περιλαμβάνει ~A" +vt-escape-suite-token+)))
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
        ;; L6 [audit#3]: το CI αναφέρει όλες τις εντολές αλλά ΧΩΡΙΣ pipefail+assessor
        (expect "⑧β CI χωρίς pipefail/assessor ⇒ :authoritative_gates_not_failclosed"
                ok-readme
                (format nil "docker run … --gates~%docker build ~A .~%docker build ~A ."
                        +vt-tests-command+ +vt-tests-command-2+)
                ok-df nil :invalid :authoritative_gates_not_failclosed)
        ;; L7 [audit#3]: το Dockerfile ΔΕΝ παράγει το inventory (χειρόγραφη λίστα)
        (expect "⑧γ Dockerfile χωρίς derived runner ⇒ :standalone_suites_not_derived"
                ok-readme ok-ci
                (format nil "for t in source-profile … ~A …; do sbcl …; done" +vt-escape-suite-token+)
                nil :invalid :standalone_suites_not_derived)
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
                ok-readme ok-ci
                ;; derived runner παρών (περνά L7) αλλά ΧΩΡΙΣ escape-sequences (πέφτει L4)
                "RUN /app/docker/run-standalone-suites.sh …" nil
                :invalid :escape_suite_ungated)
        ;; L4: ο αποσυρμένος driver υπάρχει ακόμη
        (expect "⑫ run-tests-docker.lisp παρών ⇒ :retired_driver_present"
                ok-readme ok-ci ok-df t :invalid :retired_driver_present)
        ;; L5: stale αριθμός πυλών ([0029] #1) — «N πύλες» ≠ ζωντανός ⇒ κόκκινο
        (expect "⑬α README «22 πύλες» ενώ ζωντανά 23 ⇒ :stale_gate_count"
                (format nil "~A· σήμερα 22 πύλες" ok-readme) ok-ci ok-df nil
                :invalid :stale_gate_count 23)
        (expect "⑬β CI comment «22 πύλες» ενώ ζωντανά 23 ⇒ :stale_gate_count"
                ok-readme (format nil "~A· 22 πύλες" ok-ci) ok-df nil
                :invalid :stale_gate_count 23)
        (expect "⑬γ README «23 πύλες» == ζωντανά 23 ⇒ :ok (σωστός αριθμός επιτρέπεται)"
                (format nil "~A· σήμερα 23 πύλες" ok-readme) ok-ci ok-df nil
                :ok nil 23)
        (expect "⑬δ κανένας στατικός αριθμός (self-describing) ⇒ :ok"
                ok-readme ok-ci ok-df nil :ok nil 23)
        ;; #1 (Codex): verifier-conformance documented αλλά ΟΧΙ στο CI ⇒ divergent
        (expect "⑭α CI χωρίς verifier-conformance ⇒ :tests_command_2_divergent"
                ok-readme (format nil "docker run … --gates~%docker build ~A ." +vt-tests-command+)
                ok-df nil :invalid :tests_command_2_divergent)
        ;; #1: README χωρίς verifier-conformance ενώ το CI το τρέχει ⇒ divergent
        (expect "⑭β README χωρίς verifier-conformance ⇒ :tests_command_2_divergent"
                (format nil "run --gates· docker build ~A" +vt-tests-command+) ok-ci ok-df nil
                :invalid :tests_command_2_divergent)
        ;; #2 (Codex): το --gates ΜΟΝΟ σε YAML σχόλιο ⇒ ΔΕΝ μετρά ως «το CI τρέχει»
        (expect "⑮α --gates μόνο σε CI σχόλιο (# …) ⇒ :correctness_command_divergent"
                ok-readme
                (format nil "# comment: το --gates τρέχει εδώ~%steps:~%  run: docker build ~A .~%  run: docker build ~A ."
                        +vt-tests-command+ +vt-tests-command-2+)
                ok-df nil :invalid :correctness_command_divergent)
        ;; #2: standalone-test ΜΟΝΟ σε inline σχόλιο ⇒ ΔΕΝ μετρά
        (expect "⑮β standalone-test μόνο σε inline σχόλιο ( #…) ⇒ :tests_command_divergent"
                ok-readme
                (format nil "run: docker run --gates  # δες ~A αργότερα~%run: docker build ~A ."
                        +vt-tests-command+ +vt-tests-command-2+)
                ok-df nil :invalid :tests_command_divergent)))
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
          (:ok      (format t "  ✓ ⑭ ζωντανά αρχεία repo: README ≡ CI (ορθότητα=--gates, tests=--target standalone-test, ~D πύλες)~%" (%vt-live-gate-count)))
          (:skipped (format t "  ⊘ ⑭ source tree απόν (minimal image) — verify-truth επιβάλλεται στο source, όχι εδώ~%"))
          (t        (format t "  ✗ ⑭ ζωντανά αρχεία repo: ΑΠΟΚΛΙΣΗ ⇒ ~A~%" why)))
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
