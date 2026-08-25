;;;; experiment/phase1a/GATE-LEDGER.sexp
;;;; ΜΗΤΡΩΟ ΠΥΛΩΝ — ΚΑΘΕ αποτέλεσμα δεμένο με το hash του checker που το παρήγαγε.
;;;;
;;;; EARLY CORRECTION §2: ο citation resolver είναι VERSIONED GATE. Κάθε αλλαγή
;;;; του hash του καθιστά κάθε προηγούμενο αποτέλεσμα STALE μέχρι μηχανικό
;;;; re-gating. Τα προηγούμενα ΔΕΝ διαγράφονται — μένουν ως SUPERSEDED.

(:lawmax-gate-ledger/1
 :corpus "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"

 ;; ΔΙΟΡΘΩΣΗ ΕΛΕΓΧΟΥ: ΠΛΗΡΗ SHA-256 ΠΑΝΤΟΥ, ΠΟΤΕ ΠΡΟΘΕΜΑ. Ένα prefix 16
 ;; χαρακτήρων δεν είναι δέσμευση — είναι υπόδειξη. Κάθε απόδειξη δένεται με
 ;; ΟΛΟΚΛΗΡΟ hash σε ΚΑΘΕ έναν από τους πέντε άξονες ταυτότητας.
 :binding-axes
 ("corpus-merkle-root  — τι δέντρο μετρήθηκε"
  "manifest-sha256     — ποιο ευρετήριο του δέντρου χρησιμοποιήθηκε"
  "registry-sha256     — ποιος ορισμός διαδρομών ίσχυε"
  "lane-cluster-roots  — ποια συστάδα δηλώθηκε για ΑΥΤΗ τη διαδρομή"
  "dossier-sha256      — ποιο ΑΚΡΙΒΩΣ κείμενο κρίθηκε")

 :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
 :manifest-sha256    "29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
 :manifest-schema 2
 :manifest-schema-note
  "schema 2: path·kind·sha256·bytes·logical_lines·class·trailing_newline (7 πεδία).
   Το logical_lines είναι ΑΚΡΙΒΕΣ (αρχείο χωρίς τελικό newline μετρά και την
   τελευταία ημιτελή γραμμή· κενό αρχείο = 0· δυαδικό = -1). Η μετάβαση
   schema 1→2 ΔΕΝ άλλαξε τη ρίζα Merkle — μόνο το ευρετήριο.
   ΠΡΟΗΓΟΥΜΕΝΟ manifest (schema 1): sha256
   92394c037b1337435adc1d78c719e91a141e7d67d9a14b89e4a3362bdb35b631 — SUPERSEDED."
 :registry-sha256    "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"

 ;; ── ΕΚΔΟΣΕΙΣ ΤΟΥ RESOLVER ────────────────────────────────────────────────
 :resolver-versions
 ((:version 1 :sha256 "6c41e041aea11aafc6adf0c365ab9ad2ea9a46b78900242f40ddcf56d7427750"
   :limitation "το \\b δεν πιάνει διαδρομές με αρχικό «.» (.github/…)"
   :status :SUPERSEDED)
  (:version 2 :sha256 "79bf79efef764b70bb13f7f738d00e665c5acd0e39fa78ade82a866c93fe852a"
   :delta "αρχικό «.» + ευρετική αφαίρεση 3 mount prefixes"
   :limitation "ΕΥΡΕΤΙΚΗ κανονικοποίηση — δεχόταν /app/ και /frozen/watchtower/,
                χωρίς έλεγχο traversal, χωρίς cluster-root, χωρίς symlink έλεγχο"
   :status :SUPERSEDED)
  (:version 3 :sha256-prefix "d552d4171bc61669"
   :sha256 "d552d4171bc6166986bf216dda567bfe540fac09f9aafe067a9ffcf579846046"
   :sha256-provenance "ΑΝΑΚΤΗΘΗΚΕ ΑΠΟ ΤΟ GIT, ΔΕΝ ΜΑΝΤΕΥΤΗΚΕ:
     git show 5ca9ea16:experiment/runner/citation-resolver.py | sha256sum
    Το πρόθεμα που είχε καταγραφεί τότε («d552d4171bc61669») ΤΑΥΤΙΖΕΤΑΙ με τους
    πρώτους 16 χαρακτήρες του ανακτημένου — άρα η ανάκτηση επαληθεύεται από
    την ΙΔΙΑ την παλιά εγγραφή."
   :delta "EARLY CORRECTION §4: ΔΗΛΩΜΕΝΗ κανονικοποίηση — ΜΟΝΟ ακριβές
           /frozen/ro/· απόρριψη «..»· απόρριψη κάθε άλλου absolute· απόρριψη
           symlink· cluster-relative ΜΟΝΟ ως προς σφραγισμένο cluster-root·
           εκτύπωση resolver+manifest hash σε ΚΑΘΕ αποτέλεσμα"
   :witnesses (:positive 3 :negative 5
               :negative-cases ("path traversal ..", "absolute /app/",
                                "absolute /frozen/watchtower/",
                                "εκτός manifest υπό /frozen/ro/",
                                "ανύπαρκτο σχετικό"))
   :FATAL-DEFECT
    "EXISTENCE-BASED GUESSING. Ο v3 περιείχε τη γραμμή
       if rel not in index and cluster_root: rel = cluster_root + \"/\" + rel
     Δηλαδή: όταν μια παραπομπή ΔΕΝ έλυνε, ο resolver ΜΑΝΤΕΥΕ βάζοντας μπροστά
     το cluster-root και ΔΕΧΟΤΑΝ το αποτέλεσμα αν το αρχείο ΤΥΧΑΙΝΕ να υπάρχει.
     Αυτό ΔΕΝ είναι επίλυση — είναι αναζήτηση μέχρι να βρεθεί κάτι που υπάρχει.
     ΣΥΝΕΠΕΙΑ: κάθε ΠΡΑΣΙΝΟ αποτέλεσμα του v3 σε dossier με γυμνά ονόματα
     αρχείων ήταν ΚΑΤΑΣΚΕΥΑΣΜΕΝΟ ΑΠΟ ΤΗΝ ΠΥΛΗ, όχι κερδισμένο από το dossier."
   :status :SUPERSEDED)
  (:version 4
   :sha256 "24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
   :delta "Κλείσιμο ΕΝΝΕΑ ευρημάτων ανεξάρτητου ελέγχου:
     §1 data-only sexp parser για το registry (ΟΧΙ regex «.*?» με re.S που
        μπορούσε να διασχίσει όρια διαδρομών)· απαιτείται ΑΚΡΙΒΩΣ 1 εγγραφή.
     §2 ΔΥΟ ΚΑΙ ΜΟΝΟ ΔΥΟ μορφές παραπομπής (mount-anchored | corpus-relative)·
        ΚΑΤΑΡΓΗΘΗΚΕ η fallback cluster-relative επίλυση.
     §3 --lane ΥΠΟΧΡΕΩΤΙΚΟ και ΜΟΝΑΔΙΚΟ· :cluster-roots = ΣΥΝΟΛΟ, όχι ενικό·
        δηλωμένη σημασιολογία root (κατάλογος αναδρομικά | glob που ΔΕΝ
        διασχίζει «/»)· τα roots ΔΕΝ επιλύουν, μόνο αναφέρουν περιεκτικότητα.
     §4 ΚΑΘΕ είσοδος πρέπει να υπάρχει — τέλος το σιωπηλό φιλτράρισμα
        ανύπαρκτων αρχείων με os.path.isfile.
     §5 errors=\"strict\" στην αποκωδικοποίηση — τέλος η σιωπηλή αλλοίωση.
     §6 ΑΚΡΙΒΕΣ όριο γραμμής: hi > nlines (ΟΧΙ nlines+1) — η γραμμή n+1
        ΑΠΟΡΡΙΠΤΕΤΑΙ.
     §7 ΑΥΣΤΗΡΟ manifest: 7 πεδία, καμία διπλή διαδρομή, kind ∈ {file,symlink},
        πλήρες 64-ψήφιο sha256, αριθμητικά πεδία, κανένα σιωπηλό skip.
     §8 VERDICT: CITATION-INTEGRITY-PASS — ΡΗΤΑ ΟΧΙ claim-entailment.
     §9 (αφορά MODEL-EVENTS.sexp, κλείστηκε εκεί)"
   :witnesses
    (:file "experiment/runner/resolver-witnesses.py"
     :sha256 "3b75fc5d67dea3664e0e2385db09fe8ea7c273fd6f39a95d3c4084d539650024"
     :positive 8 :negative 28 :total 36 :result :ALL-PASS
     :why "Πύλη χωρίς αποδεδειγμένο ΑΡΝΗΤΙΚΟ μάρτυρα δεν είναι πύλη: δεν
           ξέρουμε αν μπορεί ΠΟΤΕ να κοκκινίσει. Κάθε δηλωμένο μονοπάτι
           απόρριψης εκτελείται σε ΣΥΝΘΕΤΙΚΟ δέντρο και ελέγχεται ΑΚΡΙΒΩΣ
           (exit code + υπογραφή αιτίας)."
     :negative-classes
      ("--lane απών/διπλό" "lane άγνωστο/διπλοεγγεγραμμένο"
       "cluster-roots απόν/κενό/απόλυτο/με «..»"
       "dossier απών" "καμία είσοδος" "μηδέν παραπομπές" "κακοσχηματισμένο UTF-8"
       "manifest: λάθος πλήθος πεδίων/διπλή διαδρομή/άγνωστο kind/κομμένο
        sha256/0 bytes με >0 γραμμές/κενό"
       "παραπομπή με «..»" "absolute εκτός /frozen/ro/" "άγνωστη διαδρομή"
       "symlink" "δυαδικό" "γραμμή n+1" "τέλος εύρους εκτός" "γραμμή 0"
       "λάθος sha256 prefix"
       "ΚΑΜΙΑ cluster-relative fallback επίλυση — ο μάρτυρας N28 δίνει «a.lisp»
        ενώ υπάρχει «alpha/a.lisp»: ο v3 θα το μάντευε, ο v4 το ΑΠΟΡΡΙΠΤΕΙ")
     :positive-classes
      ("corpus-relative" "mount-anchored" "ΤΕΛΕΥΤΑΙΑ γραμμή (όριο)"
       "αρχείο χωρίς τελικό newline" "glob «*» = μόνο ρίζα"
       "glob «d/*.md» δεν διασχίζει «/»" "dir root αναδρομικό"
       "σωστό sha256 prefix"))
   :command "python3 experiment/runner/resolver-witnesses.py"
   :status :CURRENT))

 ;; ── ΑΠΟΤΕΛΕΣΜΑΤΑ ΤΗΣ ΠΥΛΗΣ v4 — ΚΑΘΕ ΑΠΟΔΕΙΞΗ ΔΕΜΕΝΗ ΣΕ 5 ΑΞΟΝΕΣ ─────
 ;;
 ;; ΤΟ ΚΥΡΙΟ ΕΥΡΗΜΑ ΤΟΥ RE-GATE: έξι από τις επτά διαδρομές πέρασαν ΑΜΕΤΑΒΛΗΤΕΣ.
 ;; Η Φ1A-L1 ΚΑΤΕΡΡΕΥΣΕ: 286 → 3 λυμένες, 283 προβληματικές. Το προηγούμενο
 ;; «286/286 PASS» ΔΕΝ ΗΤΑΝ ΑΠΟΤΕΛΕΣΜΑ ΤΟΥ DOSSIER — ήταν προϊόν του
 ;; existence-based guessing του v3. Καταγράφεται ως ΑΠΟΤΥΧΙΑ ΠΥΛΗΣ.
 :gate-run
 (:resolver 4
  :resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
  :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
  :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
  :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
  :re-gated-without-rerunning-agents t
  :re-gate-note "Τα ΙΔΙΑ σφραγισμένα κείμενα, νέα πύλη. Κανένας πράκτορας
                 αρχαιολογίας δεν επανεκτελέστηκε γι\' αυτό το re-gate.")

 :current-results
 ((:lane "Φ1A-L2" :dossier "experiment/phase1a/systems.sexp"
   :verdict :CITATION-INTEGRITY-PASS :exit 0
   :citations 214 :resolved 214 :problems 0
   :forms (:mount-anchored 0 :corpus-relative 214)
   :coverage (:in-cluster 209 :out-of-cluster 5)
   :bound
    (:resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
     :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
     :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
     :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
     :cluster-roots ("systems")
     :dossier-sha256 "sha256:e11b7b76d7fdb18cd7cf4d348eac7b81529cc9c004f8d6d56cc93a644ae9c141"))
  (:lane "Φ1A-L3" :dossier "experiment/phase1a/authority-v2.sexp"
   :verdict :CITATION-INTEGRITY-PASS :exit 0
   :citations 165 :resolved 165 :problems 0
   :forms (:mount-anchored 0 :corpus-relative 165)
   :coverage (:in-cluster 165 :out-of-cluster 0)
   :bound
    (:resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
     :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
     :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
     :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
     :cluster-roots ("authority-v2")
     :dossier-sha256 "sha256:c3bf9ce0fe3dd0db3f3a0084201093af969b986afd9cc28843713866935c78f9"))
  (:lane "Φ1A-L4" :dossier "experiment/phase1a/deployment-specs.sexp"
   :verdict :CITATION-INTEGRITY-PASS :exit 0
   :citations 200 :resolved 200 :problems 0
   :forms (:mount-anchored 0 :corpus-relative 200)
   :coverage (:in-cluster 195 :out-of-cluster 5)
   :bound
    (:resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
     :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
     :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
     :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
     :cluster-roots ("deployment/*.md" "deployment/*.sexp" "deployment/*.ttl" "deployment/*.json"
                     "deployment/*.jsonld" "deployment/shapes" "deployment/verify"
                     "deployment/templates" "deployment/mcp")
     :dossier-sha256 "sha256:f895deb6721317b7979ffe44346628c064a2c0c1682b2642658e94f9d507730b"))
  (:lane "Φ1A-L5" :dossier "experiment/phase1a/deployment-state.sexp"
   :verdict :CITATION-INTEGRITY-PASS :exit 0
   :citations 156 :resolved 156 :problems 0
   :forms (:mount-anchored 155 :corpus-relative 1)
   :coverage (:in-cluster 136 :out-of-cluster 20)
   :bound
    (:resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
     :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
     :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
     :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
     :cluster-roots ("deployment/self" "deployment/self-study" "deployment/knowledge"
                     "deployment/data" "deployment/state" "deployment/collab"
                     "deployment/*.js" "deployment/*.sh")
     :dossier-sha256 "sha256:27dfbfc852110beade15117a7d02e01ab48485377a623b040dc9f92b1ae79923"))
  (:lane "Φ1A-L6" :dossier "experiment/phase1a/harness.sexp"
   :verdict :CITATION-INTEGRITY-PASS :exit 0
   :citations 98 :resolved 98 :problems 0
   :forms (:mount-anchored 0 :corpus-relative 98)
   :coverage (:in-cluster 84 :out-of-cluster 14)
   :bound
    (:resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
     :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
     :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
     :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
     :cluster-roots ("tests" "docker" "scripts")
     :dossier-sha256 "sha256:9ddd1820acf40205c1256bccac8c8d689e1683ae7512566168df4ae302237ea9"))
  (:lane "Φ1A-L7" :dossier "experiment/phase1a/contracts.sexp"
   :verdict :CITATION-INTEGRITY-PASS :exit 0
   :citations 101 :resolved 101 :problems 0
   :forms (:mount-anchored 0 :corpus-relative 101)
   :coverage (:in-cluster 86 :out-of-cluster 15)
   :bound
    (:resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
     :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
     :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
     :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
     :cluster-roots ("*" "configs" "docs" ".github" "cloudflare" "tools")
     :dossier-sha256 "sha256:6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"))
  (:lane "Φ1A-L1" :dossier "experiment/phase1a/source.sexp" :revision 1
   :verdict :CITATION-INTEGRITY-FAIL :exit 1
   :citations 286 :resolved 3 :problems 283
   :forms (:mount-anchored 0 :corpus-relative 3)
   :coverage (:in-cluster 0 :out-of-cluster 3)
   :bound
    (:resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
     :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
     :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
     :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
     :cluster-roots ("source")
     :dossier-sha256 "sha256:dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef")
   :failure-class :UNDECLARED-CITATION-FORM
   :diagnosis
    "283 από 286 παραπομπές είναι ΓΥΜΝΑ ΟΝΟΜΑΤΑ ΑΡΧΕΙΩΝ χωρίς κατάλογο
     (π.χ. «safe-read.lisp:39-349», «merkle-authority.lisp:54-235»), σε 101
     διακριτά αρχεία. Δεν είναι ΚΑΜΙΑ από τις δύο δηλωμένες μορφές. Το dossier
     ΔΕΝ δηλώνει καμία βάση επίλυσης στην κεφαλίδα του (source.sexp:1-13)."
   :why-the-orchestrator-does-not-fix-it
    "Μηχανική προσθήκη «source/» θα ήταν ΑΚΡΙΒΩΣ το ίδιο μάντεμα που
     καταδικάστηκε. ΜΕΤΡΗΘΗΚΕ ΣΤΟ ΠΑΓΩΜΕΝΟ MANIFEST — από τα 101 γυμνά
     ονόματα, 98 έχουν μοναδικό υποψήφιο αλλά ΤΡΙΑ ΕΙΝΑΙ ΑΜΦΙΣΗΜΑ:
       config.lisp    → 4 υποψήφιοι (source/ · systems/orchestrator-ai-core/ ·
                        third-party/cl+ssl-20250622-git/src/ ·
                        third-party/lparallel-v2.8.4/src/util/)
       memory.lisp    → 2 υποψήφιοι (source/ · third-party/cffi-20250622-git/tests/)
       protocols.lisp → 2 υποψήφιοι (source/ · systems/orchestrator-spec/)
     Άρα το μάντεμα είναι ΑΠΟΔΕΔΕΙΓΜΕΝΑ μη μοναδικό, όχι θεωρητικά."
   :precedent
    "Στη Φ1A-L2 διορθώθηκαν 49 γυμνά ονόματα ΑΠΟ ΤΗΝ ΙΔΙΑ ΤΗ ΔΙΑΔΡΟΜΗ. ΔΥΟ από
     αυτά είχαν ΚΑΙ ΛΑΘΟΣ ΕΥΡΟΣ ΓΡΑΜΜΩΝ (reports.lisp L86-99→L6-19,
     mock-data.lisp L21-24→L6-9), επειδή οι αριθμοί προέρχονταν από συνενωμένο
     «cat -n». Το λάθος φάνηκε ΜΟΝΟ αφού ταυτοποιήθηκε το πραγματικό αρχείο.
     Προσθήκη προθέματος από τον ενορχηστρωτή ΘΑ ΕΙΧΕ ΚΡΥΨΕΙ αυτή την τάξη
     σφάλματος πίσω από πράσινη πύλη."
   :disposition :SUPERSEDED-BY-REVISION-2
   :forensics "experiment/phase1a/L1-ADMISSION-BOUNDARY.sexp"
   :classification-of-the-283
    (:A-valid-corpus-root-relative 0
     :B-valid-lane-relative-unique 272
     :C-registry-or-parser-defect 0
     :D-ambiguous 10
     :E-out-of-declared-scope 0
     :F-nonexistent-file 0
     :G-invalid-range-or-hash 1
     :arithmetic "272+10+1 = 283 ✓"
     :verdict-on-infrastructure
      "A = 0 ΚΑΙ C = 0 ⇒ ούτε ο resolver ούτε το registry φταίνε. Το όριο
       αποδοχής του v4 είναι ΣΩΣΤΟ. Η αποτυχία είναι ΓΝΗΣΙΑ ιδιότητα του
       κειμένου της διαδρομής, ΟΧΙ αστοχία της υποδομής."))

  (:lane "Φ1A-L1" :dossier "experiment/phase1a/source-rev2.sexp" :revision 2
   :verdict :CITATION-INTEGRITY-FAIL :exit 1
   :citations 286 :resolved 275 :problems 11
   :forms (:mount-anchored 0 :corpus-relative 275)
   :coverage (:in-cluster 272 :out-of-cluster 3)
   :bound
    (:resolver-sha256 "sha256:24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
     :corpus-merkle-root "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
     :manifest-sha256 "sha256:29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e"
     :registry-sha256 "sha256:051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
     :cluster-roots ("source")
     :dossier-sha256 "sha256:858f4c903e91a11289d3e4830541dbca687a14cd403883758fa04ea559f68807"
     :supersedes-sha256 "sha256:dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef")
   :produced-by :DETERMINISTIC-CITATION-ONLY-MIGRATION
   :migration-proof
    (:method :REVERSE-RECONSTRUCTION
     :text-replacements 327 :unique-keys 272 :byte-delta 2289
     :arithmetic "327 × 7 («source/») = 2289 ✓"
     :reconstructed-sha256 "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef"
     :identical-to-original t
     :establishes "ΚΑΝΕΝΑ byte ισχυρισμού δεν άλλαξε — αμφίδρομα, όχι δειγματοληπτικά"
     :map "experiment/artifacts/l1-admission-forensics/MIGRATION-MAP.json")
   :remaining-11 (:D-ambiguous 10 :G-invalid-range 1)
   :disposition :QUARANTINED-PENDING-LANE-JUDGEMENT
   :charge-status :PREPARED-NOT-DISPATCHED))

 ;; ── SUPERSEDED ΑΠΟΤΕΛΕΣΜΑΤΑ (διατηρούνται, δεν διαγράφονται) ────────────
 ;;
 ;; ΚΑΘΟΛΙΚΗ ΑΚΥΡΩΣΗ v3: ΚΑΘΕ αποτέλεσμα του v3 είναι STALE, ακόμη κι όσα
 ;; επιβεβαιώθηκαν ξανά από τον v4. Λόγος: ο v3 έφερε το existence-based
 ;; guessing, άρα ένα πράσινο του v3 ΔΕΝ αποδεικνύει από μόνο του ότι το
 ;; dossier ήταν σωστό — μπορεί η πύλη να έλυσε αντ' αυτού. Όπου ο v4
 ;; συμφωνεί, ισχύει Η ΜΕΤΡΗΣΗ ΤΟΥ v4, όχι η επικύρωση του v3.
 :v3-blanket-invalidation
 (:affected-lanes ("Φ1A-L1" "Φ1A-L2" "Φ1A-L3" "Φ1A-L4" "Φ1A-L5" "Φ1A-L6" "Φ1A-L7")
  :re-measured-under-v4 7
  :agreed-with-v3 6
  :contradicted-v3 1
  :contradiction "Φ1A-L1: v3 έδινε 286/286 PASS· v4 δίνει 3/286 FAIL."
  :retracted-aggregate
   "Η προηγούμενη συνολική δήλωση «1220/1220 παραπομπές λυμένες» ΑΝΑΚΑΛΕΙΤΑΙ.
    Ήταν αληθής ΩΣ ΠΡΟΣ ΤΟΝ v3 και ΨΕΥΔΗΣ ως δήλωση ακεραιότητας παραπομπών.
    Το ΑΛΗΘΕΣ σύνολο υπό v4 είναι 937/1220 με 283 προβληματικές, ΟΛΕΣ στη L1."
  :arithmetic "3+214+165+200+156+98+101 = 937 · 937+283 = 1220 ✓")

 :superseded-results
 ((:lane "Φ1A-L7" :resolver 1 :dossier-sha256-prefix "3274504db73ffd44"
   :citations 101 :resolved 90 :problems 11 :exit 1
   :why-superseded "resolver v1 limitation + 2 γνήσια ελαττώματα dossier")
  (:lane "Φ1A-L7" :resolver 2 :dossier-sha256-prefix "6ab0457e1a7b2993"
   :citations 101 :resolved 101 :problems 0 :exit 0
   :why-superseded "ο resolver v2 αντικαταστάθηκε από τον v3· το αποτέλεσμα
                    επιβεβαιώθηκε ΞΑΝΑ με v3 (ίδιο 101/101)")
  (:lane "Φ1A-L3" :resolver 2 :citations 154 :resolved 154 :problems 0
   :why-superseded "v2→v3· επιβεβαιώθηκε ξανά, τώρα 165 παραπομπές λόγω
                    διευρυμένου καταλόγου επεκτάσεων του v3 (+cddl/mjs/ts/zip)")
  (:lane "Φ1A-L6" :resolver 2 :citations 98 :resolved 98 :problems 0
   :why-superseded "v2→v3· επιβεβαιώθηκε ξανά, ίδιο αποτέλεσμα")
  (:lane "Φ1A-L5" :resolver 2 :citations 152 :resolved 138 :problems 14
   :why-superseded "πριν από τη διόρθωση της lane· τώρα 156/156 με v3")
  (:lane "Φ1A-L2" :resolver 3 :dossier-sha256-prefix "8dafb52f355eb458"
   :citations 224 :resolved 175 :problems 49
   :why-superseded "πριν από τη διόρθωση της lane· τώρα 214/214"))

 ;; ── ΣΥΜΦΙΛΙΩΣΗ ΤΩΝ ΑΡΧΙΚΩΝ 11 (§2/§5) — ΑΚΡΙΒΕΣ DISPOSITION ────────────
 :l7-initial-eleven
 (:original-result "resolver v1 × dossier 3274504db73ffd44 ⇒ 101 · 90 λύθηκαν · 11 προβληματικές"
  :reproduced-mechanically t
  :reproduction-command "python3 <resolver-v1> <dossier-pre>"
  :dispositions
  ((:class :resolver-limitation :count 9
    :cause "το \\b δεν ταιριάζει μεταξύ κενού και «.», άρα η σύλληψη ξεκινούσε
            από το «g» και αναζητούσε «github/…» αντί «.github/…»"
    :items (".github/workflows/docker-orchestrator.yml:292-308"
            ".github/workflows/docker-orchestrator.yml:298-299"
            ".github/workflows/docker-orchestrator.yml:359-378"
            ".github/workflows/docker-orchestrator.yml:228-234"
            ".github/workflows/docker-orchestrator.yml:338-346"
            ".github/workflows/docker-orchestrator.yml:306"
            ".github/workflows/docker-orchestrator.yml:371"
            ".github/workflows/provenance.yml:128"
            ".github/workflows/provenance.yml:143-151")
    :fixed-by "resolver v2 (αρχικό «.»)· διατηρείται στον v3"
    :dossier-changed nil)
   (:class :genuine-dossier-defect :count 2
    :cause "γυμνά ονόματα αρχείου χωρίς κατάλογο"
    :items ("article-root-generator-omega.lisp:175 → systems/orchestrator-omega-modules/article-root-generator-omega.lisp:175"
            "hybrid-generator-phase1.lisp:289 → systems/orchestrator-omega-modules/hybrid-generator-phase1.lisp:289")
    :fixed-by "Η ΙΔΙΑ Η ΔΙΑΔΡΟΜΗ Φ1A-L7, με επαλήθευση στο /frozen/ro"
    :dossier-changed t
    :dossier-sha256-before "3274504db73ffd44ea367494a0a29c296bf9d5b1829fc744afbd831c1748b9ee"
    :dossier-sha256-after  "6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"))
  :arithmetic "9 + 2 = 11 ✓"
  :my-earlier-error "Είχα αναφέρει «7 + 2 = 9». ΛΑΘΟΣ ΜΕΤΡΗΣΗ ΔΙΚΗ ΜΟΥ: διάβασα
                     κομμένη έξοδο (head -8) και δεν επαλήθευσα το άθροισμα.
                     Τα 4 που έλειπαν ονομάζονται παραπάνω."
  :seal-timing "Η διόρθωση των 2 έγινε ΠΡΙΝ από κάθε σφράγιση. Το σφραγισμένο
                hash είναι το ΜΕΤΑ (6ab0457e…). ΚΑΝΕΝΑ σφραγισμένο dossier δεν
                τροποποιήθηκε επιτόπου — §3 τηρήθηκε εξ αρχής.")

 ;; ── ΠΟΛΙΤΙΚΗ ΑΝΑΘΕΩΡΗΣΕΩΝ (§3) ──────────────────────────────────────────
 :revision-policy
 (:rule "ΣΦΡΑΓΙΣΜΕΝΟ dossier ΔΕΝ τροποποιείται ΠΟΤΕ επιτόπου."
  :procedure ("η lane δημιουργεί ΝΕΑ revision"
              "η νέα revision δηλώνει :supersedes-sha256"
              "το παλιό hash ΜΕΝΕΙ σε αυτό το ledger"
              "το LANE-REGISTRY δείχνει ποια revision είναι :current")
  :applies-from :now
  :status-of-past "Καμία παραβίαση: όλες οι διορθώσεις έγιναν σε ΜΗ σφραγισμένα
                   dossiers. Το μόνο σφραγισμένο (L7) σφραγίστηκε ΜΕΤΑ τη
                   διόρθωσή του και δεν έχει αγγιχτεί έκτοτε."))
