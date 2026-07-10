;;;; orchestrator-cli.asd
;;;; ASDF System Definition for Orchestrator CLI
;;;; Generic, corpus-agnostic command-line interface

(asdf:defsystem #:orchestrator-cli
  :description "Generic, corpus-agnostic CLI for Greek Legal Corpus Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "0.9.0"
  :homepage "https://stavropouloslaw.com"
  
  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-core
               #:orchestrator-engine-sbcl
               #:orchestrator-gr-syntagma  ; Greek Constitution corpus (used in main.lisp)
               #:orchestrator-meta
               #:orchestrator-ai-core
               #:orchestrator-infrastructure  ; Required for orchestrator.time package
               #:alexandria
               #:cl-yaml
               #:uiop)
  
  :serial t
  :components
  ((:module "systems/orchestrator-cli"
    :components
    ((:file "package")
     (:file "log")
     (:file "cli-util")             ; θεμελιώδεις κοινοί βοηθοί (string, state, cursors)
     (:file "constitutional-dispatch") ; ΤΟ ΕΓΩ: CLOS around στη δρομολόγηση — ο συνταγματικός φραγμός ως ιδιότητα (πριν το main που δρομολογεί)
     (:file "config-loader")
     (:file "commands")
     (:file "reporting")
     (:file "content-validation")   ; Level-2 content-sanity gate (before main uses it)
     (:file "main")
     (:file "builtin-commands")      ; Φάση 1 διάσπασης main: οι πρώην-builtin ως εγγραφές μητρώου — το main είναι σκέτος αγωγός parse→σύνταγμα→μητρώο
     (:file "decisions")             ; εντολές νομολογίας — φορτώνονται ΤΕΛΕΥΤΑΙΕΣ, εγγράφονται στο μητρώο
     (:file "self-reflection")       ; ΤΟ ΕΓΩ: εγγραφές τομέα (παρατηρητές+είδη προτάσεων) + εντολές --reflect/--thoughts/--approve/--reject
     (:file "understanding-learning") ; ΜΑΘΗΣΗ ΚΑΤΑΝΟΗΣΗΣ: failure ledger → feature-rule proposals → σκιά → ουρά υπογραφής· διερμηνέας υιοθετημένων κανόνων ΠΡΩΤΟΣ (phrase-patch αδύνατο εκ κατασκευής)
     (:file "architecture-gate")     ; ΑΡΧΙΤΕΚΤΟΝΙΚΟ ΣΥΝΤΑΓΜΑ: read-only ontological closure (13 primitives, πλήρης χαρτογράφηση, --architecture-constitution-gate)
     (:file "golden-gate")           ; ΧΡΥΣΟ RATCHET: --golden-gate — κάθε committed golden ≡ φρέσκο ίδιας-μεθόδου αποτύπωμα (read-only, μετά το main για build-consolidated-for/%fingerprint-method)
     (:file "external-benchmark-gate") ; CPEI L11 EXTERNAL ATTESTATION: dry-run επικύρωση hidden bundle του Κριτή (σχήμα+detached fingerprint+no-leak) — ποτέ εκτέλεση items (--external-benchmark-gate)
     (:file "cognition-self")        ; ΓΝΩΣΙΑΚΟ ΠΕΔΙΟ: frames+σύνθεση για τον διάλογο εαυτού (πάνω στα 5 στάδια) — τέλος στο μονολιθικό σεντόνι
     (:file "cognition-legal")       ; ΓΝΩΣΙΑΚΟ ΠΕΔΙΟ: νομικός διάλογος (άρθρα/νομολογία/αποφάσεις/δικαστές) ως frames — τέλος στην παλιά cond
     (:file "advisor")               ; Ο ΣΥΜΒΟΥΛΟΣ (εκτός εμπιστοσύνης): LLM προτείνει πλαίσιο, ο πυρήνας επαληθεύει (--advisor/--advisor-gate)
     (:file "graph-import")           ; ΕΙΣΑΓΩΓΗ στον ενιαίο γράφο (εαυτός+corpus+αποφάσεις) + εντολή --graph
     (:file "dialogue-gate")           ; Η ΠΥΛΗ ΤΟΥ ΔΙΑΛΟΓΟΥ: εκτελέσιμη μη-παλινδρόμηση της κατανόησης (--dialogue-gate)
     (:file "deontic-gate")            ; Η ΠΥΛΗ ΤΟΥ ΔΕΟΝΤΙΚΟΥ: τα πρότυπα αστοχίας των κριτών, κλειδωμένα ως tests (--deontic-gate)
     (:file "inference-gate")          ; Η ΠΥΛΗ ΤΟΥ ΣΥΜΠΕΡΑΣΜΟΥ: μηχανή L1/JTMS + BFS επιπτώσεων, κλειδωμένα (--inference-gate)
     (:file "iq-gate")                 ; Η ΠΥΛΗ IQ: τυχαία προβλήματα + ανεξάρτητος κριτής — 100% ή κόκκινο (--iq-gate)
     (:file "fluid-gate")              ; Σ12-ΡΕΥΣΤΟ: πύλη κρυφών προγραμμάτων + --arc-eval σε πραγματικά ARC tasks
     (:file "event-gate")              ; Α5 Η ΠΥΛΗ ΤΗΣ ΙΣΤΟΡΙΑΣ: event calculus — γεγονότα→καταστάσεις→κρίση, με πιστοποιητικά χρόνου
     (:file "draft-commands")          ; Ε12 ΤΟ ΠΑΡΑΔΟΤΕΟ: Σημείωμα Υπαγωγής με απόδειξη σε κάθε πρόταση (--draft) + πύλη
     (:file "subsumption-commands")
     (:file "case-workspace")          ; Ο ΧΩΡΟΣ ΥΠΟΘΕΣΗΣ: deterministic blackboard — όλοι οι ειδικοί σε μία αρένα (--case)    ; Σ4-Σ6: --subsume/--argue/--what-if + πύλη --subsumption-gate
     (:file "jurisprudence-judge")     ; Ο ΚΡΙΤΗΣ-ΝΟΜΟΛΟΓΙΑ: μετρημένη ικανότητα leave-one-out στη νομολογία (--judge)
     (:file "autonomy-missions")       ; ΑΠΟΣΤΟΛΕΣ αυτόνομου οδηγού: δεοντική σάρωση κωδίκων → ουρά προτάσεων (--autonomous)
     (:file "self-extension")          ; Σ11 ΑΥΤΟ-ΕΠΕΚΤΑΣΗ: κενά→αυτο-προτάσεις γνώσης, σκιωδώς δοκιμασμένες (--self-extend) + πύλη
     (:file "approval-policy")        ; Φ5: ΕΓΚΡΙΣΕΙΣ ΚΑΤΑ ΚΛΑΣΗ με μετρημένη ακρίβεια (--policies/--policy-approve) + πύλη
     (:file "memory-commands")         ; ΜΝΗΜΗ: --memory/--recall/--agenda/--intend/--intentions + πύλη --memory-gate
     (:file "generation-gate")         ; Η ΠΥΛΗ ΤΗΣ ΓΡΑΜΜΑΤΙΚΗΣ: ορθή κλίση/συμφωνία/τελικό-ν + κύκλος γένεση→κατανόηση (--generation-gate)
     (:file "ingestion-commands")      ; εντολές ΦΕΚ/δαίμονα — ομοίως, μητρώο
     (:file "provenance-gate")         ; Η ΠΥΛΗ ΠΡΟΕΛΕΥΣΗΣ: runtime execution provenance + trace queries + αρνητικά (--provenance-gate)
     (:file "evolution-gate")          ; Η ΠΥΛΗ ΑΥΤΟΕΞΕΛΙΞΗΣ: what-if governed adoption + αρνητικά (--self-evolution-gate)
     (:file "component-gate")          ; Η ΠΥΛΗ ΣΥΣΤΑΤΙΚΩΝ: canonical component registry + typed article identity + αρνητικά (--component-gate)
     (:file "contract-gate")           ; Η ΠΥΛΗ ΣΥΜΒΟΛΑΙΩΝ: επικυρωτής + θεσμική ταυτότητα + article-identity εκτελέσιμα + αρνητικά (--contract-gate)
     (:file "verify-truth-gate")       ; FF3 Η ΠΥΛΗ ΤΙΜΙΟΤΗΤΑΣ ΕΠΑΛΗΘΕΥΣΗΣ: README ≡ CI (ορθότητα=--gates, tests=--target standalone-test) — καμία ψευδής documented διαδρομή (--verify-truth-gate)
     (:file "release-authority")       ; P1R [0046] CONTENT-ADDRESSED RELEASES: ταυτότητα=Merkle root (overwrite δομικά αδύνατο)· χρόνος=append-only attestation· --cut-release/--attest-release (καμία wrapper λογική)
     (:file "release-gate")            ; Η ΠΥΛΗ ΑΜΕΤΑΒΛΗΤΩΝ ΕΚΔΟΣΕΩΝ: recomputed root ≡ δηλωμένο ≡ όνομα· latest ⇒ attested (--release-gate, read-only)
     (:file "gates-runner")))))        ; Η ΟΛΟΜΕΛΕΙΑ: --gates τρέχει ΟΛΕΣ τις πύλες του μητρώου — μία εντολή, μία ετυμηγορία
