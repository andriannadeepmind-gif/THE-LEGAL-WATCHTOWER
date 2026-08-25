;;;; experiment/artifacts/ISOLATION-MANIFEST.sexp
;;;; ΤΙ ΕΙΝΑΙ ΣΦΡΑΓΙΣΜΕΝΟ ΚΑΙ ΠΩΣ ΕΠΙΒΑΛΛΕΤΑΙ Η ΑΠΟΜΟΝΩΣΗ

(:lawmax-isolation-manifest/1
 :sealed-at "2026-08-24T14:30:26Z"

 ;; ── ① ΣΦΡΑΓΙΣΜΕΝΑ ΚΕΙΜΕΝΑ ────────────────────────────────────────────
 (constitution "sha256:5b3ab5bf9561d535adbf5049b975ac2ab8e9a63db32dfb14a07d82d78b729be6" "experiment/OBJECTIVE-CONSTITUTION.json")
 (constitution-checker "sha256:ea8dc8d18e06922dc7c0646c4199fe8c5c8fec45bb0ec24ecab9d08d3c29a0d9" "experiment/runner/constitution-checker.py")
 (capability-schema "sha256:2755b6974117568d72ec60db397b0137d136c01b275cc2a10c096998d999532d" "experiment/CAPABILITY-SCHEMA.sexp")
 (protocol "sha256:33a8f59108a757da70deb5875c3eab65b083a3ff90e0fbd1763c57d94f68bd22" "experiment/PROTOCOL.sexp")
 (phase1a-agent-prompt "sha256:e0a176a26b5aab4fcf1098aa38227a701e0e002887157061222910501225b3f5" "experiment/agents/PHASE-1A-PROMPT.md")
 (architecture-family-census "sha256:d3d5d632ddb4e3827600c862c8312e8c3e13c528cd164ce03485a9136294452c" "experiment/artifacts/architecture-family-census.sexp")
 (tcb-manifest "sha256:d570b28e170ebc4cea621746050dc3df4c5af45ad40558d2a0e97ac8354f95ac" "experiment/artifacts/TRUSTED-BASE-MANIFEST.json")
 (runner-fsm-model "sha256:8dd351f32ffa450bc58647ec029891066c7d2488cc4c6d91eaccb427b878e697" "experiment/formal/runner.pml")

 ;; ── ② ΤΟ ΠΑΓΩΜΕΝΟ CORPUS ─────────────────────────────────────────────
 :frozen-corpus (:commit "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
                 :merkle "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
                 :files 35634)

 ;; ── ③ ΕΠΙΒΟΛΗ ΑΠΟΜΟΝΩΣΗΣ ΣΕ ΕΠΙΠΕΔΟ OS (όχι υπόσχεση) ───────────────
 :read-only-mount
  (:target "/frozen/ro" :options "ro,relatime,resv_strict,resuid=65534,resgid=65534"
   :positive-witness "ανάγνωση README.md επιτυγχάνει"
   :negative-witness-write "touch ⇒ EROFS ΑΠΟΡΡΙΦΘΗΚΕ"
   :negative-witness-delete "rm ⇒ ΑΠΟΡΡΙΦΘΗΚΕ"
   :root-after "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b")

 :suite-isolation
  (:corpus-mount ":ro bind" :overlay "lowerdir=/corpus upperdir=/work/upper"
   :effect "ΚΑΘΕ εγγραφή σουίτας προσγειώνεται στο upper layer· το corpus δεν μεταβάλλεται"
   :measured "10 σουίτες ΕΠΙΧΕΙΡΗΣΑΝ εγγραφή — καταγράφηκαν ονομαστικά")

 ;; ── ④ ΑΠΟΜΟΝΩΣΗ ΦΑΣΕΩΝ ──────────────────────────────────────────────
 :phase-isolation
  ((:phase 1 :name "static archaeology" :isolation :none-required
    :inputs ("/frozen/ro" "constitution" "capability-schema"))
   (:phase 2 :name "blind discovery" :isolation :structural
    :inputs ("/frozen/ro" "constitution")
    :forbidden-inputs ("experiment/phase1a/**" "ceiling-crosswalk" "incumbent")
    :enforcement "ΞΕΧΩΡΙΣΤΟ worktree στο ίδιο commit· τα artifacts Φ1 ΕΚΤΟΣ του δέντρου· ο runner αρνείται εκκίνηση αν είναι προσπελάσιμα")
   (:phase 3 :name "adversarial" :isolation :structural
    :forbidden-inputs ("proposer rationale" "proposer transcripts"))))

 ;; ── ⑤ ΑΠΑΓΟΡΕΥΣΗ ΑΥΤΟΠΙΣΤΟΠΟΙΗΣΗΣ ──────────────────────────────────
 :anti-self-certification
  (:rule "closure certificate ΔΕΝ υπογράφεται από τον πράκτορα που παρήγαγε τον υποψήφιο"
   :model-checked "experiment/formal/runner.pml — SPIN errors: 0"
   :status :MODEL-CHECKED  ; ΟΧΙ implementation-proved (§14.10)
   :missing-for-implementation-proof ("refinement relation μοντέλου→runner" "non-vacuity witness"))

 ;; ── ⑥ ΤΙ ΞΑΝΑΝΟΙΓΕΙ ΤΟ PREFLIGHT (§15) ─────────────────────────────
 :preflight-reopen-triggers
  ("ταυτότητα corpus" "ακεραιότητα runner" "phase isolation" "σφραγισμένο Σύνταγμα"))
