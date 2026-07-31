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
   :status :externally-blocked
   :load-bearing t
   :implementation ("authority-v2/kernel/admission-model.sexp (ΠΡΟΔΙΑΓΡΑΦΗ: υπογραφή,
                     ολότητα, 9 conjuncts, 9 θεωρήματα, out-of-scope)")
   :proof-objects ("authority-v2/proof-manifest.sexp :T1..:T9 — όλα :blocked-toolchain")
   :command "python3 authority-v2/verify-proof-manifest.py"
   :actual-result "EXECUTED 2026-07-31: 17 θεωρήματα, 0 proved, 17 blocked-toolchain, gate :not-passed, manifest ΣΥΝΕΠΕΣ"
   :negative-witness "authority-v2/tests/gate-negative-fixtures.py — 12/12: θεώρημα :proved χωρίς artifact, gate :passed με blocked φέροντα, ασύμφωνο summary, επινοημένο status ⇒ ΟΛΑ απορρίπτονται"
   :residual-assumptions ("Η ΥΛΟΠΟΙΗΣΗ της K είναι ΣΚΟΠΙΜΑ απούσα σε Common Lisp: θα ήταν
                          δεύτερη έδρα που αργότερα θα χρειαζόταν migration (ρητή απαγόρευση).
                          Στόχος υλοποίησης: F* — ΑΠΩΝ (403)."
                          "certificates/bounded checking ΔΕΝ αναβαθμίζουν status (§5)"))

  ;; ── 3 ────────────────────────────────────────────────────────────────────
  (:id 3
   :title "Deterministic CBOR + CDDL μέσω EverCBOR/EverCDDL/EverParse· JSON/HTML μόνο προβολές"
   :status :externally-blocked
   :load-bearing t
   :implementation ("authority-v2/schema/transition-certificate.cddl (κλειστό σχήμα, χωρίς floats)"
                    "authority-v2/schema/state.cddl (state/log/profile-lineage/rejection)"
                    "authority-v2/toolchain/everparse.Dockerfile (hermetic — το μονοπάτι άρσης)")
   :proof-objects ("proof-manifest :P1-cddl-parser-soundness, :P2-deterministic-encoding — blocked")
   :command "docker build -f authority-v2/toolchain/everparse.Dockerfile --target cddl-gate ."
   :actual-result "NOT-EXECUTED — BLOCKED-TOOLCHAIN (F* απόν· δίκτυο 403· κανένας docker daemon). Το Dockerfile ΑΠΟΤΥΓΧΑΝΕΙ ΣΚΟΠΙΜΑ όσο τα pins είναι PIN-REQUIRED"
   :negative-witness "τα pins είναι PIN-REQUIRED ⇒ fail-closed· καμία εικασία commit/sha256 από μνήμη"
   :residual-assumptions ("ΚΑΜΙΑ CL υλοποίηση CBOR δεν μπήκε στο TCB ούτε πάγιωσε wire format (ρητή εντολή)"
                          "τα staging artifacts φέρουν canonical_encoding=PENDING-EVERPARSE"
                          "ο canonical parser gate παραμένει ΚΟΚΚΙΝΟΣ"))

  ;; ── 4 ────────────────────────────────────────────────────────────────────
  (:id 4
   :title "Transition certificate που δεσμεύει και τα 15 απαιτούμενα πεδία"
   :status :externally-blocked
   :load-bearing t
   :implementation ("authority-v2/schema/transition-certificate.cddl — ΟΛΑ τα απαιτούμενα:
                     previous checkpoint+state hash, sequence, candidate root, ΠΛΗΡΕΣ census,
                     source/evidence roots, profile-id + predecessor hash, owner/release
                     signature, raw TSA request/response, nonce, requested policy, TSA chain +
                     revocation evidence, νέο state hash, log entry, signed checkpoint")
   :proof-objects ()
   :command nil
   :actual-result "NOT-EXECUTED — η ΕΚΠΟΜΠΗ απαιτεί τον verified parser (γραμμή 3)"
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
   :command "bash authority-v2/tests/run-authority-v2-proofs.sh   (Η ΜΙΑ ΕΔΡΑ: inventory από filesystem ≡ committed PROOF-CENSUS.txt)"
   :actual-result "EXECUTED 2026-07-31 [CAPTURE-AND-BOUNDARY-CORRECTION]: authority-v2 proofs 8 passed / 0 failed / 0 blocked (από 8 απογεγραμμένες)·
                   capture-seat-differential 8/0 — η capture.py ΚΑΙ ο ΠΑΡΑΓΩΓΙΚΟΣ orchestrator.merkle:merkle-root-of-files δίνουν ΤΗΝ ΙΔΙΑ ρίζα
                     sha256:bbe1817c91837dc89b4affd213e32cb21baab23fb1c02da50bec0c4c638be6f9 στα ΙΔΙΑ αρχεία, ΚΑΙ αλλάζουν ΜΑΖΙ σε 1-byte μετάλλαξη ΚΑΙ σε εναλλαγή σειράς·
                   capture-adversarial + fixed point 11/0 (10 σενάρια, ΚΑΘΕ καθαρή σύλληψη περνά ΥΠΟΧΡΕΩΤΙΚΑ από fixed point ①②③)·
                   capture-mutation-witness 8/0 — 7/7 μεταλλάξεις ΣΚΟΤΩΘΗΚΑΝ + θετικός μάρτυρας·
                   producer-os-boundary 11/0 — EROFS(30) ΟΧΙ EACCES(13), με τον producer ΙΔΙΟΚΤΗΤΗ του releases/ και θετικό έλεγχο ότι ΧΩΡΙΣ mount γράφει·
                   level7-disarm 20/0 (με 6 νέους ελέγχους Δ3δ)· release-authority 14/0· transparency-log 21/0"
   :negative-witness "ΜΑΡΤΥΡΑΣ ΜΕΤΑΛΛΑΞΕΩΝ (authority-v2/tests/capture-mutation-witness.py): κάθε ένα από τα ευρήματα του δημιουργού ΞΑΝΑΕΙΣΑΓΕΤΑΙ επίτηδες στον κώδικα και ΠΡΕΠΕΙ να σκοτωθεί —
                      M1 release_root ως hash-of-hash (ΤΟ ΑΚΡΙΒΕΣ P0), M2 φύλλο χωρίς 0x00, M3 duplicate-last MTH, M4 μερική εγγραφή, M5 κατάργηση fingerprint (TOCTOU), M6 κατάργηση άρνησης hardlink (διαρροή secret), M7 κατάργηση διασταύρωσης φάσεων.
                      Ο ΙΔΙΟΣ ο μάρτυρας βρήκε ΔΥΟ κενά σενάρια (αρχείο < chunk ανάγνωσης· round-robin αντίπαλος) και τα έκλεισε στην ΑΙΤΙΑ τους.
                      Στο OS όριο: ο producer ΕΙΝΑΙ ιδιοκτήτης με 0700 και ΓΡΑΦΕΙ χωρίς mount — άρα η άρνηση ΔΕΝ εξηγείται από δικαιώματα· το errno ελέγχεται ΑΡΙΘΜΗΤΙΚΑ."
   :residual-assumptions ("[ΑΝΑΚΛΗΣΗ ΙΣΧΥΕΙ] Δ2 = IMPLEMENTED-NOT-PROVED, Δ3 = IMPLEMENTED-NOT-PROVED. Ο χαρακτηρισμός CLOSED παραμένει ΑΠΟΣΥΡΜΕΝΟΣ."
                          "ΚΛΕΙΣΤΑ ΣΕ ΑΥΤΟ ΤΟ COMMIT (εκτελεστικά, όχι τυπικά): ταύτιση Merkle έδρας με την παραγωγή· επαναμέτρηση ΑΠΟΚΛΕΙΣΤΙΚΑ από το quarantine· write-all· κλείσιμο ΟΛΩΝ των descriptors· deadline ανά αρχείο ΚΑΙ ανά ανάγνωση· πραγματικό fixed point· mount-attributable άρνηση· συρμάτωση σε CI."
                          "το TSA conjunct του νέου kernel ΔΕΝ έχει υλοποιηθεί ακόμη (απαίτηση 2/4)"
                          "η κατάργηση είναι σε επίπεδο κώδικα ΚΑΙ OS (απαίτηση 1) — όχι τυπικά αποδεδειγμένη· η capture είναι υλοποίηση αναφοράς σε Python, ΟΧΙ ο τελικός verified checker (απαίτηση 6)"
                          "ΤΟ COMPOSE SERVICE authority-v2-proofs ΔΕΝ ΕΚΤΕΛΕΣΤΗΚΕ: `docker compose config` ΕΠΙΚΥΡΩΘΗΚΕ (exit 0), αλλά ΔΕΝ υπάρχει διαθέσιμος docker daemon σε αυτό το περιβάλλον. BLOCKED — NOT EXECUTED, ΠΟΤΕ pass."
                          "ΤΟ CI JOB authority-v2-boundary ΔΕΝ ΕΧΕΙ ΤΡΕΞΕΙ ΑΚΟΜΗ σε GitHub Actions τη στιγμή της συγγραφής — δηλώνεται ΩΣ ΣΥΡΜΑΤΩΜΕΝΟ, ΟΧΙ ΩΣ ΠΡΑΣΙΝΟ."))

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
   :implementation ("authority-v2/store/STORAGE-API.sexp (διεπαφή + η ΜΙΑ συναλλαγή των έξι
                     στοιχείων + startup recheck + derived-caches κανόνας)"
                    "authority-v2/toolchain/perennial.Dockerfile (hermetic — μονοπάτι άρσης)")
   :proof-objects ("proof-manifest :S1-transaction-atomicity, :S2-crash-recovery — blocked")
   :command "docker build -f authority-v2/toolchain/perennial.Dockerfile --target store-proof ."
   :actual-result "NOT-EXECUTED — BLOCKED-TOOLCHAIN (Coq απόν· 403· κανένας docker daemon)"
   :negative-witness "το API δηλώνει ρητά :forbidden-substitutes (intent-log/SQLite/atomic-rename-με-crash-tests) και :implementation-status :absent-by-design — καμία υλοποίηση δεν μπήκε πίσω από το interface"
   :residual-assumptions ("ΚΑΝΕΝΑ προσωρινό intent-log ΔΕΝ μπήκε πίσω από το τελικό interface (ρητή εντολή)"
                          "το production writer παραμένει ΑΠΕΝΕΡΓΟΠΟΙΗΜΕΝΟ"))

  ;; ── 8 ────────────────────────────────────────────────────────────────────
  (:id 8
   :title "C2SP tiles/checkpoints + Ed25519 log signature + witness iface/quorum (external disabled)"
   :status :externally-blocked
   :load-bearing t
   :implementation ("authority-v2/log/witness-policy.sexp (FORMAT-AGNOSTIC witness interface,
                     quorum policy με ΚΡΙΤΗΡΙΑ ΑΝΕΞΑΡΤΗΣΙΑΣ, freshness/anti-freeze policy,
                     fake witnesses με :counts-toward-quorum nil)"
                    "authority-v2/tests/witness-quorum-test.py")
   :proof-objects ()
   :command "python3 authority-v2/tests/witness-quorum-test.py"
   :actual-result "EXECUTED 2026-07-31: 8 passed, 0 failed — ΜΟΝΟ η ΠΟΛΙΤΙΚΗ (κβόρουμ/φρεσκάδα/αντιφατική εικόνα). ΤΟ WIRE FORMAT ΠΑΡΑΜΕΝΕΙ BLOCKED-SPEC-INPUT: τα κανονικά κείμενα tlog-tiles@v0.1.0 / tlog-checkpoint / tlog-witness@v1.0.0 δεν ανακτώνται (403) και ΑΠΑΓΟΡΕΥΕΤΑΙ υλοποίηση από μνήμη"
   :negative-witness "3 fake witnesses ⇒ ΔΕΝ σχηματίζουν κβόρουμ· 2 μάρτυρες με κοινό φορέα μετρούν ως 1· έγκυρο ΑΛΛΑ παλιό checkpoint ΑΠΟΡΡΙΠΤΕΤΑΙ· ένας μάρτυρας με αντιφατική εικόνα ρίχνει τα πάντα (όχι 2-of-3)· external disabled ⇒ ΑΝΕΝΕΡΓΗ πύλη, ΠΟΤΕ «0-of-3 ok»"
   :residual-assumptions ("ΑΠΑΓΟΡΕΥΕΤΑΙ υλοποίηση από μνήμη (ρητή εντολή §2) — καμία γραμμή του witness-policy δεν υποθέτει σειριοποίηση"
                          "external_quorum_status=disabled· ΚΑΜΙΑ δήλωση split-view resistance"
                          "με ΜΟΝΟ τοπικούς fake witnesses ΔΕΝ υπάρχει ανεξαρτησία — και δεν προσποιούμαστε ότι υπάρχει"))

  ;; ── 9 ────────────────────────────────────────────────────────────────────
  (:id 9
   :title "TUF-class roles (offline root 1-of-1, release/targets/snapshot/timestamp) + rotation/revocation/rollback-freeze + lineage"
   :status :externally-blocked
   :load-bearing t
   :implementation ("authority-v2/roles/ROLES-MODEL.sexp (5 ρόλοι, threshold σχήμα έτοιμο
                     για πραγματικό quorum, 5 υποχρεωτικές άμυνες, ρητό stop point·
                     :tuf-conformance-claim nil — ΚΑΜΙΑ δήλωση συμμόρφωσης)"
                    "authority-v2/roles/ceremony.sh (genesis/rotation/revocation/recovery)"
                    "authority-v2/tests/ceremony-rehearsal-test.sh")
   :proof-objects ()
   :command "bash authority-v2/tests/ceremony-rehearsal-test.sh"
   :actual-result "EXECUTED 2026-07-31: 8 passed, 0 failed — 4 τελετές προβαρίστηκαν ΠΡΑΓΜΑΤΙΚΑ με test keys (5 ρόλοι, 4 delegations, self-binding, rotation αλυσίδα, υπογεγραμμένη ανάκληση, ανάκτηση 4 ρόλων από offline root)· και οι 3 production εντολές ΣΤΑΜΑΤΗΣΑΝ με exit 3"
   :negative-witness "rotation: το ΝΕΟ root ΔΕΝ αυτο-επικυρώνεται χωρίς την αλυσίδα (η πρόβα το ελέγχει ρητά και θα σκάσει αν στεκόταν μόνο του)· MODE=production ⇒ ΑΚΟΜΗ ΚΑΙ οι rehearse εντολές σταματούν"
   :residual-assumptions ("ΚΑΤΑΣΚΕΥΑΣΤΗΚΑΝ ΠΛΗΡΩΣ και ΠΡΟΒΑΡΙΣΤΗΚΑΝ: ceremony/rotation/revocation/recovery/fixtures/rehearsal. ΣΤΑΜΑΤΑ ΜΟΝΟ η δημιουργία/χρήση ΠΡΑΓΜΑΤΙΚΟΥ production root key (air-gap/HSM/μάρτυρες/out-of-band δημοσίευση = ενέργεια δημιουργού)"
                          "η ΣΥΜΜΟΡΦΩΣΗ με TUF v1.0.35 παραμένει BLOCKED-SPEC-INPUT: το κανονικό κείμενο δεν ανακτάται (403) και ΑΠΑΓΟΡΕΥΕΤΑΙ υλοποίηση από μνήμη"
                          "end-to-end refinement obligation (spec→source→binary) + reproducible-build comparison + trusted-toolchain manifest: βλ. γραμμή 9b"))

  ;; ── 9b (προσθήκη διορθωτικής: refinement obligation) ──────────────────────
  (:id "9b"
   :title "End-to-end refinement obligation: formal spec → generated source → compiled binary + reproducible build + trusted-toolchain manifest"
   :status :externally-blocked
   :load-bearing t
   :implementation ("authority-v2/toolchain/trusted-toolchain-manifest.sexp — αλυσίδα 5 κρίκων
                     (spec→ορισμοί→παραγόμενος→binary→rebuild) με υποχρέωση ανά κρίκο,
                     CompCert license gate, trusted-tools με ρητό «τι ΔΕΝ αποδεικνύει»,
                     κλειστός κατάλογος residual TCB")
   :proof-objects ("proof-manifest :R1-extraction-soundness, :R2-compiler-correctness, :R3-reproducible-build — blocked")
   :command nil
   :actual-result "NOT-EXECUTED — κρίκοι 1,2 blocked (F*/Coq), κρίκος 3 externally-blocked (CompCert άδεια), κρίκος 4 not-started, κρίκος 5 declared-residual"
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
   :command "sbcl --script <runner> tests/level7-disarm-test.lisp && sbcl --script <runner> tests/release-authority-test.lisp && sbcl --script <runner> tests/transparency-log-test.lisp && python3 authority-v2/tests/gate-negative-fixtures.py && bash authority-v2/tests/ceremony-rehearsal-test.sh && python3 authority-v2/tests/witness-quorum-test.py"
   :actual-result "EXECUTED 2026-07-31: level7-disarm 9/0 · release-authority 14/0 · transparency-log 23/0 · gate-negative-fixtures 12/0 · ceremony-rehearsal 8/0 · witness-quorum 8/0"
   :negative-witness "κάθε αναδιατυπωμένος έλεγχος κατοχυρώνει ΑΡΝΗΣΗ εκεί που πριν κατοχύρωνε ΑΠΟΔΟΧΗ (⑦β πλαστό receipt)· η απόσυρση δύο ελέγχων bootstrap δηλώνεται ΡΗΤΑ αντί να αναστηθεί η νεκρή έδρα στα fixtures"
   :residual-assumptions ("crash-at-every-write-boundary ΔΕΝ υπάρχει ακόμη — απαιτεί το store (7)"
                          "τα tests είναι regression layer, ΟΧΙ φέρουσα απόδειξη (ρητή εντολή)")))

 ;; ── ΣΥΝΟΨΗ (υπολογίζεται από τις γραμμές· καμία χειροκίνητη βαθμολογία) ──
 :summary
 (:total 13
  :proved 0
  :implemented-not-proved 3
  :externally-blocked 7
  :not-started 3
  :level7 nil
  :statement "0/13 PROVED ⇒ ΤΟ ΣΥΣΤΗΜΑ ΔΕΝ ΕΙΝΑΙ LEVEL-7. Καμία απαίτηση δεν αντικαταστάθηκε από κατώτερη· τα :externally-blocked παραμένουν ανοιχτά με hermetic build ως μονοπάτι άρσης."))
