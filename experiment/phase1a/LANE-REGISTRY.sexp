;;;; experiment/phase1a/LANE-REGISTRY.sexp
;;;; ΜΗΤΡΩΟ ΔΙΑΔΡΟΜΩΝ ΦΑΣΗΣ 1A — ΚΑΜΙΑ ΔΙΑΔΡΟΜΗ ΔΕΝ ΕΞΑΦΑΝΙΖΕΤΑΙ
;;;;
;;;; ΔΙΟΡΘΩΣΗ ΔΗΜΙΟΥΡΓΟΥ (δεκτή): η δήλωση «η Φάση 1A δεν χρειάζεται πράκτορες»
;;;; ΗΤΑΝ ΛΑΝΘΑΣΜΕΝΗ. Η κεντρική μηχανική διαδρομή είναι ΠΡΟΣΘΕΤΗ, ΔΕΝ
;;;; αντικαθιστά τις επτά ανεξάρτητες. Η Φάση 1A ΔΕΝ σφραγίζεται χωρίς επτά
;;;; χωριστά dossiers, χωρίς μεταξύ τους πρόσβαση, με χωριστά hashes, και
;;;; reconciliation ΜΟΝΟ μετά τη σφράγισή τους.

(:lawmax-phase1a-lane-registry/1
 :phase-status "PHASE-1A: ALL SEVEN LANES DELIVERED — CITATION GATES PASSED — PHASE SEAL BLOCKED"
 :seal-blockers "read-ledger absent (§3) · macro layer unexamined (§6) — βλ. SEVEN-DOSSIERS-STATUS.sexp"
 :corpus "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
 :read-source "/frozen/ro (OS-level read-only· πύλη πριν από κάθε σάρωση)"

 :identity-policy
 "Οι runtime χειριστές πρακτόρων είναι ΕΦΗΜΕΡΑ αναγνωριστικά της συνεδρίας:
  αλλάζουν σε κάθε spawn και δεν έχουν καμία διάρκεια πέρα από αυτήν. Ως
  ΠΡΩΤΟΚΟΛΛΙΚΗ ταυτότητα καταχωρούνται ΔΙΑΡΚΗ lane IDs (Φ1A-L1..L7), δεμένα σε
  (συστάδα × sha256 συμβολαίου × διαδρομή dossier). Αυτό είναι ΑΝΩΤΕΡΟ από τον
  εφήμερο χειριστή: επιβιώνει επανεκκίνησης, επιτρέπει αντικαταστάτη πράκτορα
  στην ίδια διαδρομή, και είναι επαληθεύσιμο από τρίτον."

 :cluster-root-semantics
 "ΔΗΛΩΜΕΝΗ, ΟΧΙ ΕΥΡΕΤΙΚΗ. Κάθε στοιχείο του :cluster-roots είναι ΜΗ ΚΕΝΟ και
  ερμηνεύεται με ΑΚΡΙΒΩΣ έναν από δύο τρόπους, χωρίς τρίτη ανάγνωση:
    ① ΧΩΡΙΣ «*» ⇒ ΚΑΤΑΛΟΓΟΣ. Ταιριάζει το ίδιο το μονοπάτι ή οτιδήποτε ΚΑΤΩ
      από αυτό (rel == d  ή  rel αρχίζει με d+\"/\").
    ② ΜΕ «*» ⇒ GLOB πάνω σε ΟΛΟΚΛΗΡΟ το σχετικό μονοπάτι, όπου το «*»
      ΔΕΝ διασχίζει «/». Άρα «*» = αρχείο ρίζας του corpus· «deployment/*.js»
      = άμεσο παιδί του deployment/ με κατάληξη .js.
  ΤΑ CLUSTER-ROOTS ΔΕΝ ΕΠΙΛΥΟΥΝ ΠΑΡΑΠΟΜΠΕΣ. Χρησιμεύουν ΜΟΝΟ στην αναφορά
  περιεκτικότητας (εντός/εκτός συστάδας). Η επίλυση γίνεται ΠΑΝΤΑ ως προς τη
  ρίζα του corpus — καμία cluster-relative επίλυση, καμία fallback δοκιμή."

 :cluster-roots-provenance
 "Κάθε σύνολο roots αντιγράφεται από το :scope / :cluster ΤΟΥ ΙΔΙΟΥ σφραγισμένου
  dossier της διαδρομής, ΟΧΙ από τις παραπομπές του (αυτό θα ήταν κυκλικό):
    L1 source.sexp:2 · L2 systems.sexp:2 · L3 authority-v2.sexp:2
    L4 deployment-specs.sexp:2,6 (θετική απαρίθμηση των 38 top-level specs +
       shapes/verify/templates/mcp — ΟΧΙ αποκλεισμός)
    L5 deployment-state.sexp:2 · L6 harness.sexp:2 · L7 contracts.sexp:6
  ΔΙΟΡΘΩΣΗ ΕΛΕΓΧΟΥ: οι προηγούμενες ΕΝΙΚΕΣ :cluster-root ήταν ΨΕΥΔΕΙΣ για
  L4/L5 (και οι δύο «deployment», ενώ οι συστάδες είναι ξένες μεταξύ τους),
  για L6 («tests», ενώ docker/ και scripts/ ΔΕΝ είναι κάτω από tests/) και
  για L7 (κενή συμβολοσειρά — καμία σημασία). Αντικαταστάθηκαν από σύνολα."

 :contract
 ((:version 1 :sha256 "e0a176a26b5aab4fcf1098aa38227a701e0e002887157061222910501225b3f5"
   :used-in :attempt-1)
  (:version 2 :sha256 "54e0025d981860cada005c5a51ea5e856565b955d7c9f6fa6f766c24dff78040"
   :used-in :attempt-2
   :delta "Προστέθηκε ΥΠΟΧΡΕΩΤΙΚΟ ΣΤΑΔΙΑΚΟ CHECKPOINT: εγγραφή dossier νωρίς και
           κάθε ~15-20 αρχεία, με :status :partial, :files-read και :remaining
           ονομαστικά, ώστε διακοπή να ΜΗΝ μηδενίζει τη διαδρομή."))

 :attempt-1
 (:status :BLOCKED
  :cause "API session limit του λογαριασμού (reset 19:20 UTC)"
  :lanes-affected 7 :dossiers-produced 0
  :verdict "ΔΕΝ διαγράφεται από το πρωτόκολλο. Καταγράφεται ως αποτυχημένη
            απόπειρα με ονομαστική αιτία, κατά §12: εξάντληση πόρου ⇒ ποτέ FINAL.")

 :attempt-2 (:status :ALL-DELIVERED :contract-version 2
  :dossier-hashes "experiment/phase1a/SEVEN-DOSSIERS-STATUS.sexp")

 :lanes
 ((:lane "Φ1A-L1" :cluster "source/" :files 133
   :cluster-roots ("source")
   :dossier "experiment/phase1a/source.sexp"
   :focus "πυρήνας Common Lisp· cognition/merkle-authority/proof-carrying/
           deterministic-time/version-graph/authority-proof-bundle/document-fetch/
           pdf-authority/amendment-*/journal/self-constitution"
   :special-charge "ονομαστική κρίση των ignore-errors: σιωπηλό fallback ή
                    δηλωμένη τίμια άγνοια με υποχρέωση ελέγχου από τον καλούντα"
   :status :QUARANTINED
   :status-note "ΟΧΙ sealed. ΟΧΙ complete. Η πύλη v4 απέτυχε στο πρωτότυπο
                 (283/286) και εξακολουθεί να αποτυγχάνει στο μεταναστευμένο
                 (11/286). Πλήρες μητρώο: experiment/phase1a/L1-ADMISSION-BOUNDARY.sexp"
   :revisions
   ((:rev 1 :path "experiment/phase1a/source.sexp"
     :sha256 "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef"
     :gate-v4 (:citations 286 :resolved 3 :problems 283 :verdict :FAIL)
     :status :SUPERSEDED-BUT-IMMUTABLE)
    (:rev 2 :path "experiment/phase1a/source-rev2.sexp"
     :sha256 "858f4c903e91a11289d3e4830541dbca687a14cd403883758fa04ea559f68807"
     :supersedes-sha256 "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef"
     :produced-by :DETERMINISTIC-CITATION-ONLY-MIGRATION
     :produced-by-note "ΟΧΙ από πράκτορα. Μηχανικός μετασχηματισμός με
                        αμφίδρομη απόδειξη ότι κανένα byte ισχυρισμού δεν
                        άλλαξε (αντίστροφη ανακατασκευή → ίδιο sha256)."
     :gate-v4 (:citations 286 :resolved 275 :problems 11 :verdict :FAIL)
     :status :CURRENT-GATE-FAILED
     :remaining "10 AMBIGUOUS + 1 INVALID-RANGE — απαιτούν κρίση της διαδρομής"))
   :current-revision 2)
  (:lane "Φ1A-L2" :cluster "systems/" :files 175
   :cluster-roots ("systems")
   :dossier "experiment/phase1a/systems.sexp"
   :focus "ASDF συστήματα· έδρες εγγραφής authoritative state· epistemic/cli/
           infrastructure· η ΔΕΥΤΕΡΗ έδρα δοκιμών (12 αρχεία FiveAM εκτός tests/)"
   :special-charge "decisions.lisp:181 — ποια απόφαση εξαρτάται από ocr-available-p
                    και αν η άγνοια διαδίδεται τίμια προς τα έξω"
   :status :running :dossier-sha256 :pending)
  (:lane "Φ1A-L3" :cluster "authority-v2/" :files 63
   :cluster-roots ("authority-v2")
   :dossier "experiment/phase1a/authority-v2.sexp"
   :focus "Level-7 VCCT-RSM· kernel/schema/capability/roles/store/log/capture/
           genesis/proofs/toolchain"
   :special-charge "ΜΗΝ δεχτείς δήλωση της μήτρας: επαλήθευσε ΚΑΘΕ :proved /
                    :implemented-not-proved / :externally-blocked στον κώδικα"
   :status :running :dossier-sha256 :pending)
  (:lane "Φ1A-L4" :cluster "deployment/ (κανονικές προδιαγραφές)"
   :cluster-roots ("deployment/*.md" "deployment/*.sexp" "deployment/*.ttl"
                    "deployment/*.json" "deployment/*.jsonld"
                    "deployment/shapes" "deployment/verify"
                    "deployment/templates" "deployment/mcp")
   :dossier "experiment/phase1a/deployment-specs.sexp"
   :focus "LAWMAX-*, SYSTEM-CONSTITUTION, PROOF-CARRYING-LAW, *.ttl, shapes/,
           verify/, templates/, mcp/"
   :special-charge "αντιφάσεις μεταξύ προδιαγραφών· προδιαγραφή που διδάσκει
                    ΛΑΘΟΣ Merkle ⇒ τρίτος βγάζει λάθος ρίζα ⇒ P0"
   :status :running :dossier-sha256 :pending)
  (:lane "Φ1A-L5" :cluster "deployment/ (κατάσταση & γνώση)"
   :cluster-roots ("deployment/self" "deployment/self-study" "deployment/knowledge"
                    "deployment/data" "deployment/state" "deployment/collab"
                    "deployment/*.js" "deployment/*.sh")
   :dossier "experiment/phase1a/deployment-state.sexp"
   :focus "self/, self-study/, knowledge/, data/, state/, collab/, *.js, *.sh"
   :special-charge "κάθε .js/.sh: τι κάνει, τι δίκτυο αγγίζει, τι γράφει, ΠΟΙΟΣ
                    το καλεί, και αν είναι σε έμπιστο μονοπάτι"
   :status :running :dossier-sha256 :pending)
  (:lane "Φ1A-L6" :cluster "tests/ + docker/ + scripts/" :files 176
   :cluster-roots ("tests" "docker" "scripts")
   :dossier "experiment/phase1a/harness.sexp"
   :focus "ΤΙ ΕΓΓΥΩΝΤΑΙ οι σουίτες, όχι τι τεστάρουν· ταυτολογίες· τι ΔΕΝ
           καλύπτει ο μηχανισμός απογραφής"
   :special-charge "τα 4 μετρημένα σφάλματα: hash-seat-registry, merkle-single-truth,
                    proof-carrying, mcp-live-resolver — corpus ή harness;"
   :status :running :dossier-sha256 :pending)
  (:lane "Φ1A-L7" :cluster "ρίζα + configs + docs + .github + cloudflare + tools" :files 79
   :cluster-roots ("*" "configs" "docs" ".github" "cloudflare" "tools")
   :dossier "experiment/phase1a/contracts.sexp"
   :focus "η ΑΠΟΣΤΑΣΗ δήλωσης από μηχανισμό επιβολής"
   :special-charge "ΒΡΕΣ την GATE-4 (README:304 «no subprocess»): πού υλοποιείται,
                    τι σαρώνει, ΑΝ καλύπτει το source/pdf-authority.lisp"
   :status :SEALED
   :dossier-sha256 "6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"
   :files-read 79 :dossier-lines 408
   :gates (:citation-resolver "101/101 μετά από 2 διορθώσεις της ΙΔΙΑΣ της διαδρομής"
           :constitution-checker :pass)
   :correction-note "2 γυμνές παραπομπές διορθώθηκαν ΑΠΟ ΤΗ ΔΙΑΔΡΟΜΗ σε πλήρεις
                     διαδρομές systems/orchestrator-omega-modules/…"))

 :central-mechanical-lane
 (:id "Φ1A-C0" :nature :ADDITIONAL-NOT-SUBSTITUTE
  :artifacts ("experiment/phase1a/mechanical-map.sexp"
              "experiment/phase1a/PARTIAL-FINDINGS.sexp")
  :scope-honest
   "552 αρχεία ΜΟΝΟ με κατάληξη .lisp/.asd/.sh/.py/.js εκτός third-party/ και
    εκτός data roots. ΔΕΝ είναι ανάγνωση των 35.634 αρχείων του corpus, ΔΕΝ είναι
    ανάγνωση των 1.365 first-party, και ΔΕΝ είναι σημασιολογική ανάγνωση κανενός.
    Είναι απογραφή ΣΥΓΚΕΚΡΙΜΕΝΗΣ ΕΠΙΦΑΝΕΙΑΣ με regex."
  :status :active)

 :seal-conditions
 ("Επτά dossiers παραδομένα, ένα ανά διαδρομή"
  "Κάθε dossier με ΔΙΚΟ ΤΟΥ sha256 καταχωρημένο σε αυτό το μητρώο"
  "Καμία διαδρομή δεν διάβασε το dossier άλλης διαδρομής"
  "Κάθε dossier με :status :complete και :files-read ≥ το μέγεθος της συστάδας"
  "Η reconciliation γίνεται ΜΟΝΟ ΜΕΤΑ τη σφράγιση και των επτά"
  "Η κεντρική μηχανική διαδρομή ΔΕΝ μετράει ως καμία από τις επτά")

 :not-sealed t)
