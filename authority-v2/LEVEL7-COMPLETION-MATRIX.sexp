;;;; authority-v2/LEVEL7-COMPLETION-MATRIX.sexp
;;;; ============================================================================
;;;; LEVEL-7 COMPLETION MATRIX — μηχανικά αναγνώσιμη, μία γραμμή ανά απαίτηση
;;;; ============================================================================
;;;; ΚΑΝΟΝΑΣ (διορθωτική εντολή): η εργασία ΔΕΝ χαρακτηρίζεται ολοκληρωμένη και
;;;; το σύστημα ΔΕΝ χαρακτηρίζεται Level-7 όσο ΟΠΟΙΑΔΗΠΟΤΕ φέρουσα απαίτηση
;;;; είναι διαφορετική από PROVED. Το BLOCKED επιτρέπει να συνεχιστούν οι
;;;; ανεξάρτητες φάσεις — ΔΕΝ επιτρέπει αντικατάσταση της απαίτησης ούτε
;;;; δήλωση ολοκλήρωσης.
;;;;
;;;; ΕΠΙΤΡΕΠΤΕΣ ΚΑΤΑΣΤΑΣΕΙΣ (και ΜΟΝΟ αυτές):
;;;;   :not-started · :implemented-not-proved · :proved · :externally-blocked
;;;;
;;;; Κάθε γραμμή: implementation, proof-objects, command, actual-result,
;;;; negative-witness, residual-assumptions.
;;;; Τα actual-result είναι ΠΡΑΓΜΑΤΙΚΕΣ εκτελέσεις — ό,τι δεν έτρεξε γράφεται
;;;; NOT-EXECUTED, ποτέ PASS.

(:lawmax-level7-completion-matrix/1

 :branch "claude/lawmax-level7-vcct-rsm"
 :base-commit "57c0cd868c80f87df8e298c9aa75b8ccf2503391"
 :assurance-status :under-construction
 :level7-gate :not-passed
 :level7-gate-rule "PASS μόνο όταν ΚΑΘΕ φέρουσα απαίτηση = :proved"

 ;; Το περιβάλλον που παράγει τα :externally-blocked (γεγονότα, όχι δικαιολογίες)
 :environment-facts
 ((:tool "fstar/EverParse/EverCBOR/EverCDDL" :present nil :reason "δεν υπάρχει στο image· δίκτυο 403 σε κάθε πηγή")
  (:tool "coq/Perennial/Goose/GoTxn"        :present nil :reason "δεν υπάρχει στο image· δίκτυο 403")
  (:tool "CompCert (ccomp)"                 :present nil :reason "απόν· ΚΑΙ εμπορική άδεια απαιτούμενη για production")
  (:tool "ACL2"                             :present nil :reason "απόν· δίκτυο 403")
  (:tool "docker daemon"                    :present nil :reason "/var/run/docker.sock ανύπαρκτο")
  (:tool "go"        :present t)
  (:tool "openssl"   :present t)
  (:tool "sbcl"      :present t)
  (:tool "setpriv/useradd (root)" :present t))

 :requirements

 ;; ── 1 ─────────────────────────────────────────────────────────────────────
 ((:id 1
   :title "Μία authority process + OS-enforced write capability (όχι source-code gate)"
   :status :implemented-not-proved
   :load-bearing t
   :implementation ("authority-v2/capability/identities.sh"
                    "authority-v2/capability/verify-capability-closure.sh")
   :proof-objects ()
   :command "bash authority-v2/capability/verify-capability-closure.sh /var/lib/lawmax/authority /var/lib/lawmax/candidates"
   :actual-result "EXECUTED 2026-07-31: 5 ok, 0 FAIL — producer⇒EACCES, reader⇒EACCES, authority γράφει, producer γράφει candidates, reader διαβάζει"
   :negative-witness "θετικός μάρτυρας μη-κενότητας: αν ο authority ΔΕΝ μπορεί να γράψει, το script το καταγγέλλει ως ΚΕΝΟ ΜΑΡΤΥΡΑ· χωρίς root/setpriv ⇒ exit 2 BLOCKED, ΠΟΤΕ pass"
   :residual-assumptions ("kernel DAC (uid/gid/mode) ορθός"
                          "καμία διεργασία δεν τρέχει ως root στην παραγωγή"
                          "δεν υπάρχει ακόμη MAC (SELinux/AppArmor) profile"
                          "η απόδειξη είναι εκτελεστική, ΟΧΙ τυπική (δεν υπάρχει μοντέλο του kernel)"))

  ;; ── 2 ────────────────────────────────────────────────────────────────────
  (:id 2
   :title "Καθαρή κλειστού σχήματος K(old,candidate,evidence,policy) + 9 μηχανικές αποδείξεις"
   :status :not-started
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED"
   :negative-witness nil
   :residual-assumptions ("οι 9 ιδιότητες (authorization, completeness, no-rollback, unique-latest, monotonic-sequence, deterministic-replay, rejection-without-state-change, profile-continuity, certificate-soundness) απαιτούν prover — βλ. απαίτηση 5"))

  ;; ── 3 ────────────────────────────────────────────────────────────────────
  (:id 3
   :title "Deterministic CBOR + CDDL μέσω EverCBOR/EverCDDL/EverParse· JSON/HTML μόνο προβολές"
   :status :externally-blocked
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED — BLOCKED-TOOLCHAIN (F* απόν, δίκτυο 403)"
   :negative-witness nil
   :residual-assumptions ("ΚΑΜΙΑ CL υλοποίηση CBOR δεν μπήκε στο TCB ούτε πάγιωσε wire format (ρητή εντολή)"
                          "τα staging artifacts φέρουν canonical_encoding=PENDING-EVERPARSE"
                          "ο canonical parser gate παραμένει ΚΟΚΚΙΝΟΣ"))

  ;; ── 4 ────────────────────────────────────────────────────────────────────
  (:id 4
   :title "Transition certificate που δεσμεύει και τα 15 απαιτούμενα πεδία"
   :status :not-started
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED"
   :negative-witness nil
   :residual-assumptions ("το sequence-0 adoption certificate (απαίτηση γένεσης) υπάρχει ήδη με 13/13 πεδία — διαφορετικό σχήμα από το transition certificate"))

  ;; ── 5 ────────────────────────────────────────────────────────────────────
  (:id 5
   :title "Κατάργηση release-attested-p / promote-latest! ως authority seats· πλήρης TSA ως conjunct"
   :status :implemented-not-proved
   :load-bearing t
   :implementation ("systems/orchestrator-epistemic/authority-boundary.lisp"
                    "systems/orchestrator-epistemic/deploy-epistemic.lisp (seats ⇒ fail-closed)"
                    "systems/orchestrator-epistemic/transparency-log.lisp (write seat ⇒ fail-closed)")
   :proof-objects ()
   :command "sbcl --script <runner> tests/level7-disarm-test.lisp"
   :actual-result "EXECUTED 2026-07-31: 9 passed, 0 failed — ΚΑΙ ΟΙ ΤΡΕΙΣ έδρες αρνούνται καθολικά· κανένα latest/log δεν γράφτηκε"
   :negative-witness "το ΑΚΡΙΒΕΣ πλαστό receipt που ΠΡΙΝ γινόταν δεκτό (⑦β: .tsr με μόνο το imprint) τώρα ΑΡΝΕΙΤΑΙ· η άρνηση κατονομάζει την έδρα· επιπλέον οι legacy suites release-authority (14/0) και transparency-log (23/0) κατοχυρώνουν πλέον την ΑΡΝΗΣΗ"
   :residual-assumptions ("το TSA conjunct του νέου kernel ΔΕΝ έχει υλοποιηθεί ακόμη (απαίτηση 2/4)"
                          "η κατάργηση είναι σε επίπεδο κώδικα ΚΑΙ OS (απαίτηση 1) — όχι τυπικά αποδεδειγμένη"))

  ;; ── 6 ────────────────────────────────────────────────────────────────────
  (:id 6
   :title "Μικρός ανεξάρτητος certificate checker, formally proved sound (EverParse/EverCrypt/CompCert)"
   :status :not-started
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED"
   :negative-witness nil
   :residual-assumptions ("η soundness απόδειξη είναι :externally-blocked (F*)· ο checker ως ΚΩΔΙΚΑΣ δεν είναι"))

  ;; ── 7 ────────────────────────────────────────────────────────────────────
  (:id 7
   :title "Crash-safe authority store πάνω σε Perennial 2.0/GoTxn με απόδειξη atomicity/recovery"
   :status :externally-blocked
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED — BLOCKED-TOOLCHAIN (Coq/Perennial απόντα, δίκτυο 403)"
   :negative-witness nil
   :residual-assumptions ("ΚΑΝΕΝΑ προσωρινό intent-log ΔΕΝ μπήκε πίσω από το τελικό interface (ρητή εντολή)"
                          "το production writer παραμένει ΑΠΕΝΕΡΓΟΠΟΙΗΜΕΝΟ"))

  ;; ── 8 ────────────────────────────────────────────────────────────────────
  (:id 8
   :title "C2SP tiles/checkpoints + Ed25519 log signature + witness iface/quorum (external disabled)"
   :status :externally-blocked
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED — BLOCKED-SPEC-INPUT (τα κανονικά κείμενα tlog-tiles@v0.1.0 / tlog-checkpoint / tlog-witness@v1.0.0 δεν ανακτώνται· 403)"
   :negative-witness nil
   :residual-assumptions ("ΑΠΑΓΟΡΕΥΕΤΑΙ υλοποίηση από μνήμη (ρητή εντολή §2)"
                          "external_quorum_status=disabled· ΚΑΜΙΑ δήλωση split-view resistance"))

  ;; ── 9 ────────────────────────────────────────────────────────────────────
  (:id 9
   :title "TUF-class roles (offline root 1-of-1, release/targets/snapshot/timestamp) + rotation/revocation/rollback-freeze + lineage"
   :status :externally-blocked
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED — BLOCKED-SPEC-INPUT (TUF specification v1.0.35 δεν ανακτάται· 403)"
   :negative-witness nil
   :residual-assumptions ("ceremony tooling/rotation/revocation/recovery/rehearsal κατασκευάζονται ΩΣ ΔΟΜΗ· ΜΟΝΟ η δημιουργία/χρήση του ΠΡΑΓΜΑΤΙΚΟΥ production root key σταματά"
                          "end-to-end refinement obligation (spec→source→binary) + reproducible-build comparison + trusted-toolchain manifest: βλ. γραμμή 9b"))

  ;; ── 9b (προσθήκη διορθωτικής: refinement obligation) ──────────────────────
  (:id "9b"
   :title "End-to-end refinement obligation: formal spec → generated source → compiled binary + reproducible build + trusted-toolchain manifest"
   :status :not-started
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED"
   :negative-witness nil
   :residual-assumptions ("η production CompCert εκτέλεση = :externally-blocked μέχρι εμπορική άδεια (βλ. 6)"
                          "η υπόλοιπη υποδομή (manifest, reproducible comparison) ΔΕΝ είναι blocked"))

  ;; ── 10 ───────────────────────────────────────────────────────────────────
  (:id 10
   :title "Site/latest/proofs ΜΟΝΟ από committed accepted state· byte-for-byte rebuild· startup recheck"
   :status :not-started
   :load-bearing t
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED"
   :negative-witness nil
   :residual-assumptions ("εξαρτάται από 7 (store) για το 'committed accepted state'"))

  ;; ── 11 ───────────────────────────────────────────────────────────────────
  (:id 11
   :title "ERS (RFC 4998) renewal chain + algorithm-agility metadata, χωρίς αλλαγή αρχικής canonical μορφής"
   :status :not-started
   :load-bearing nil          ; ρητά «επόμενη φάση» στην αρχική εντολή
   :implementation ()
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED"
   :negative-witness nil
   :residual-assumptions ("εξαρτάται από 3 (canonical μορφή) ώστε να μην την αλλάξει"))

  ;; ── 12 ───────────────────────────────────────────────────────────────────
  (:id 12
   :title "Ανά στρώμα: mutation witnesses, negative fixtures, crash-at-every-write-boundary, committed census/ratchet"
   :status :implemented-not-proved
   :load-bearing t
   :implementation ("tests/level7-disarm-test.lisp"
                    "authority-v2/capability/verify-capability-closure.sh"
                    "docker/suite-census.txt (+level7-disarm)"
                    "tests/release-authority-test.lisp (αναδιατυπωμένο)"
                    "tests/transparency-log-test.lisp (αναδιατυπωμένο)")
   :proof-objects ()
   :command "sbcl --script <runner> tests/level7-disarm-test.lisp && sbcl --script <runner> tests/release-authority-test.lisp && sbcl --script <runner> tests/transparency-log-test.lisp"
   :actual-result "EXECUTED 2026-07-31: level7-disarm 9/0 · release-authority 14/0 · transparency-log 23/0"
   :negative-witness "κάθε αναδιατυπωμένος έλεγχος κατοχυρώνει ΑΡΝΗΣΗ εκεί που πριν κατοχύρωνε ΑΠΟΔΟΧΗ (⑦β πλαστό receipt)· η απόσυρση δύο ελέγχων bootstrap δηλώνεται ΡΗΤΑ αντί να αναστηθεί η νεκρή έδρα στα fixtures"
   :residual-assumptions ("crash-at-every-write-boundary ΔΕΝ υπάρχει ακόμη — απαιτεί το store (7)"
                          "τα tests είναι regression layer, ΟΧΙ φέρουσα απόδειξη (ρητή εντολή)")))

 ;; ── ΣΥΝΟΨΗ (υπολογίζεται από τις γραμμές· καμία χειροκίνητη βαθμολογία) ──
 :summary
 (:total 13
  :proved 0
  :implemented-not-proved 3
  :externally-blocked 4
  :not-started 6
  :level7 nil
  :statement "0/13 PROVED ⇒ ΤΟ ΣΥΣΤΗΜΑ ΔΕΝ ΕΙΝΑΙ LEVEL-7. Καμία απαίτηση δεν αντικαταστάθηκε από κατώτερη· τα :externally-blocked παραμένουν ανοιχτά με hermetic build ως μονοπάτι άρσης."))
