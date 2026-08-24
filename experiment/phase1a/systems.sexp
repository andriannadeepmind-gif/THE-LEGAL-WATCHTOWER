(:lawmax-phase1a-cluster/1
 :cluster "systems"
 :status :complete
 :files-read 88

 ;; ΣΗΜΕΙΩΣΗ ΕΜΒΕΛΕΙΑΣ (τιμιότητα): η συστάδα systems/ έχει 175 αρχεία σε 11
 ;; καταλόγους + 1 εκφυλισμένο .asd. Από αυτά διάβασα ΠΛΗΡΩΣ ή ΟΥΣΙΩΔΩΣ 88·
 ;; τα υπόλοιπα 87 (κυρίως orchestrator-omega-modules γεννήτριες RDF,
 ;; orchestrator-engine-sbcl adapters, orchestrator-gr-syntagma, και 28 αρχεία
 ;; orchestrator-cli) σαρώθηκαν μηχανικά (defun/defparameter outlines, grep για
 ;; έδρες εγγραφής, getenv, ignore-errors, run-program) αλλά ΔΕΝ διαβάστηκαν
 ;; γραμμή-προς-γραμμή. Κάθε ισχυρισμός παρακάτω φέρει άγκυρα σε ΔΙΑΒΑΣΜΕΝΟ
 ;; κείμενο· ό,τι δεν διάβασα είναι στα :unknowns.
 ;;
 ;; ΔΙΟΡΘΩΣΗ ΤΗΣ ΠΕΡΙΓΡΑΦΗΣ ΣΥΣΤΑΔΑΣ: το «orchestrator-infrastructure» ΔΕΝ
 ;; υπάρχει ως κατάλογος στο systems/. Είναι το /frozen/ro/orchestrator-
 ;; infrastructure.asd (22 KB) που δηλώνει components στο module "source" —
 ;; δηλαδή ΕΚΤΟΣ της συστάδας. Οι 11 πραγματικοί κατάλογοι είναι:
 ;; ai-core cli core engine-sbcl epistemic gr-syntagma meta model
 ;; omega-modules spec tests.

 :capabilities
 ((:name "transparency-log (RFC 6962) — ΜΟΝΟ ΑΝΑΓΝΩΣΗ/ΕΠΑΛΗΘΕΥΣΗ"
   :presence :present
   :domain "releases/transparency-log.json ενός corpus: entries (release roots), log_root, checkpoints."
   :assumptions "Το αρχείο υπάρχει και είναι version=\"tlog-1\"· τα Merkle μαθηματικά ζουν ΜΟΝΟ στο orchestrator.merkle."
   :guarantees "tlog-verify: (α) log_root ≡ MTH(entries)· (β) κάθε αποθηκευμένο checkpoint {size m, root} επαληθεύεται με consistency-proof RFC6962 §2.1.2. Αποτυχία ⇒ validation-error."
   :failure-semantics "fail-closed (error). Απόν αρχείο ⇒ (values :absent nil) — ρητά τίμιο, ο καλών αποφασίζει."
   :operating-model "Ο ΜΗΧΑΝΙΣΜΟΣ ΕΓΓΡΑΦΗΣ ΔΕΝ ΥΠΑΡΧΕΙ σε κανένα ASDF system ([Δ2])· tlog-append-root! σφάλλει πάντα με legacy-authority-seat-removed."
   :materiality "Το ίδιο το αρχείο δηλώνει ΡΗΤΑ ότι ΔΕΝ αποδεικνύει append-only: ολική αντικατάσταση ή διαγραφή περνά τον εσωτερικό έλεγχο· την πιάνουν μόνο η release-gate [A1], εξωτερικός μάρτυρας, και το git."
   :evidence "systems/orchestrator-epistemic/transparency-log.lisp:L19-L31,L45-L72,L117-L169")

  (:name "κατάργηση legacy authority εδρών (fail-closed άρνηση)"
   :presence :present
   :domain "ΑΚΡΙΒΩΣ τρεις έδρες: tlog-append-root!, release-attested-p, promote-latest!."
   :assumptions "Ο κώδικας φορτώνεται· καμία άλλη διαδρομή δεν αναπαράγει τη λειτουργία."
   :guarantees "Κάθε κλήση σηματοδοτεί legacy-authority-seat-removed — κανένα fallback, κανένα return value."
   :failure-semantics "error, ΠΑΝΤΑ."
   :operating-model "%seat-removed = (error 'legacy-authority-seat-removed …)."
   :materiality "Ο αποκλεισμός είναι σε επίπεδο ΚΩΔΙΚΑ (Lisp condition), ΟΧΙ OS. Το OS-enforced μέρος δηλώνεται ότι ζει στο authority-v2 (εκτός συστάδας — δεν επαληθεύεται από εδώ)."
   :evidence "systems/orchestrator-epistemic/authority-boundary.lisp:L21-L37 · systems/orchestrator-epistemic/transparency-log.lisp:L131-L132 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L939-L953,L955-L968")

  (:name "candidate boundary — emit-candidate-bundle!"
   :presence :present
   :domain "candidates/<release-id>.candidate.json (δείκτης) + candidates/<release-id>/ (bundle)."
   :assumptions "Ο producer είναι ΙΔΙΟΚΤΗΤΗΣ του candidates/ — ρητά δηλωμένο ως ΜΕΤΑΒΛΗΤΟ/TOCTOU."
   :guarantees "Δεν γράφει latest/log/releases· ο δείκτης φέρει :authority :false και :note «candidate-only»."
   :failure-semantics ":if-exists :error, αλλά μέσα σε (unless (probe-file marker) …) ⇒ TOCTOU παράθυρο· προϋπάρχων δείκτης ΔΕΝ επαληθεύεται καθόλου."
   :operating-model "content-addressed όνομα· η πραγματική αμεταβλητότητα δηλώνεται ότι ζει στο authority-v2/capture."
   :materiality "Το ίδιο το αρχείο ΑΝΑΚΑΛΕΙ τον χαρακτηρισμό «immutable» ως ΨΕΥΔΗ (εντολή δημιουργού)."
   :evidence "systems/orchestrator-epistemic/authority-boundary.lisp:L44-L58,L64-L96")

  (:name "content-addressed candidate publish (atomic-publish-release)"
   :presence :present
   :domain "staging/ → candidates/sha256-<Merkle root>/"
   :assumptions "Το staging περιέχει τα canonical αρχεία της εποχής του."
   :guarantees "Το staging ΕΠΑΝΑΫΠΟΛΟΓΙΖΕΤΑΙ και πρέπει να παράγει το δηλωμένο release-id· υπάρχων κατάλογος με ΞΕΝΟ (επαναϋπολογισμένο) root ⇒ validation-error, δεν αγγίζεται· ταυτόσημο ⇒ reuse."
   :failure-semantics "fail-closed validation-error."
   :operating-model "rename-file (ίδιο filesystem)· ΔΕΝ γράφει ΠΟΤΕ στο releases/."
   :materiality "Το epoch-downgrade κλείνεται δομικά: sha256-named χωρίς census.json και εκτός των 18 +frozen-legacy-release-ids+ ⇒ ΣΦΑΛΜΑ."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L790-L854,L867-L937")

  (:name "material gate release (validate-epistemic-stage)"
   :presence :present
   :domain "18 απαιτούμενα αρχεία + TSA-CA exactly-one-of + signature material."
   :assumptions "probe-file αρκεί ως «ύπαρξη»."
   :guarantees "Λείπον απαιτούμενο ⇒ NIL. TSA-CA: ΑΚΡΙΒΩΣ ένα από {δομικά έγκυρο X.509 tsa-ca.pem, tsa-ca.MISSING.txt με canonical sentinel}."
   :failure-semantics "Επιστρέφει NIL· ΤΟ ΝΟΗΜΑ ΤΟΥ NIL ΕΞΑΡΤΑΤΑΙ ΑΠΟ ΤΟΝ ΚΑΛΟΥΝΤΑ (Step 8 ⇒ error· engine stage ⇒ log:warn)."
   :operating-model "Καθαρά υλικός έλεγχος — ΡΗΤΑ δηλώνεται ότι ΔΕΝ τρέχει SHACL processor."
   :materiality "signature.jws/public.jwk γίνονται ΠΡΟΑΙΡΕΤΙΚΑ όταν ORCHESTRATOR_DEV_MODE ∈ {1,true,yes}."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L1133-L1204,L255-L258,L315-L346")

  (:name "release spine verification (kernel diversity)"
   :presence :present
   :domain "census-1/2 release: per-article ttl/jsonld/html sha512 ≡ in-release bytes· text_leaf ≡ RFC-6962 φύλλο του .txt· pcl_text_root ≡ MTH(text leaves)· prev_release_root· JWS RS256 πάνω στο recomputed root."
   :assumptions "Ο verifier ΔΕΝ διαβάζει το δηλωμένο root — παίρνει/υπολογίζει το recomputed."
   :guarantees "Κάθε αστοχία ονοματίζεται σε λίστα failures· απούσα υπογραφή σε census-εποχή ⇒ ΑΠΟΤΥΧΙΑ (όχι «unsigned» downgrade)."
   :failure-semantics "(values ok failures)· read-only."
   :operating-model "Δεύτερη ανεξάρτητη υλοποίηση δίπλα στον L6 πυρήνα (deployment/verify/kernel-verify.lisp) — ΔΗΛΩΜΕΝΗ ως kernel diversity, όχι ως διπλή έδρα."
   :materiality "ΤΙΜΙΟ ΟΡΙΟ ΓΡΑΜΜΕΝΟ ΣΤΟΝ ΚΩΔΙΚΑ: το public.jwk διαβάζεται ΜΕΣΑ από το ίδιο το release ⇒ αποδεικνύεται ΣΥΝΕΠΕΙΑ, ΟΧΙ αυθεντικότητα. Χωρίς pinned root/TSR, κατασκευαστής φτιάχνει αυτο-συνεπές release με δικό του κλειδί."
   :evidence "systems/orchestrator-epistemic/release-spine.lisp:L38-L71,L73-L126")

  (:name "τίμια απουσία TSA CA (canonical sentinel)"
   :presence :present
   :domain "verify/tsa-ca.pem | verify/tsa-ca.MISSING.txt"
   :assumptions "Η CA παρέχεται από τον χειριστή (env TSA_CA_BUNDLE ή <institution>/keys/tsa-ca.pem)."
   :guarantees "Ποτέ ψευδο-cert: άκυρη παρεχόμενη CA ⇒ ΣΦΑΛΜΑ (assert-valid-x509-pem, chain-aware, ΚΑΘΕ block)· καμία CA ⇒ σημείωση με +tsa-ca-missing-sentinel+ «LAWMAX-TSA-CA-MISSING-v1»."
   :failure-semantics "fail-closed για άκυρη CA· ρητά δηλωμένο κενό για απούσα."
   :operating-model "Μία έδρα εκπομπής + ΑΝΕΞΑΡΤΗΤΗ πύλη επαλήθευσης του ίδιου αναλλοίωτου."
   :materiality "Ρητά δηλώνεται ότι η ΠΛΗΡΗΣ RFC-3161 επαλήθευση αλυσίδας είναι δηλωμένη φάση P4+ — ΔΕΝ υπάρχει."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L264-L346")

  (:name "fail-closed πολιτική κλειδιών υπογραφής release"
   :presence :present
   :domain "keys/private.pem, public.pem, certificate.pem"
   :guarantees "Λείπον ιδιωτικό κλειδί ΧΩΡΙΣ LAWMAX_ALLOW_KEY_GENESIS ∈ {1,true,yes,ΝΑΙ} ⇒ validation-error."
   :assumptions "Το trust root υπάρχει ήδη· γένεση μόνο με ρητό opt-in σε ΚΕΝΟ περιβάλλον."
   :failure-semantics "fail-closed· με opt-in παράγεται RSA-4096 + self-signed X.509 100 ετών (Ironclad, χωρίς OpenSSL)."
   :operating-model "Μία έδρα πολιτικής (%key-genesis-explicitly-allowed-p)."
   :materiality "Η προειδοποίηση «ΤΟ ΚΛΕΙΔΙ ΑΥΤΟ ΔΕΝ ΠΡΕΠΕΙ ΝΑ ΥΠΟΓΡΑΨΕΙ ΔΗΜΟΣΙΟ RELEASE» ζει ΜΟΝΟ σε stdout — δεν αποτυπώνεται σε κανένα artifact του release."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L348-L418")

  (:name "PCL — υπογεγραμμένες αποδείξεις ανά διάταξη + primary-source anchor"
   :presence :present
   :domain "article-<id>.proof.json + corpus-proof.json ανά σερβιριζόμενο κώδικα."
   :assumptions "PCL_SIGNING_KEY/PCL_PUBLIC_KEY δίνονται από τον χειριστή· source.pdf/docx υπάρχει."
   :guarantees "Απόν υλικό ⇒ ΣΦΑΛΜΑ (καμία σιωπηλή unsigned εκπομπή)· υλικό παρόν αλλά ΑΧΡΗΣΤΟ ⇒ ΣΦΑΛΜΑ ΠΑΝΤΑ (καμία υποβάθμιση)· αποτυχία anchor-assert (το σερβιριζόμενο κείμενο δεν αναπαράγεται από την πηγή) ⇒ ΣΦΑΛΜΑ."
   :failure-semantics "fail-closed, εκτός ΜΙΑΣ ρητής env παράκαμψης (ORCHESTRATOR_ALLOW_DEGRADED_PROOFS=1 ⇒ trust_status «unsigned-explicit», τυπωμένο)."
   :operating-model "%pcl-signing-material + %corpus-anchor-plist· find-symbol loose coupling."
   :materiality "ΕΝΑ env flag απενεργοποιεί ΔΥΟ διαφορετικές εγγυήσεις (υπογραφή ΚΑΙ αγκύρωση παραγώγησης)."
   :evidence "systems/orchestrator-cli/main.lisp:L1807-L1838,L1840-L1892,L1894-L1900")

  (:name "provenance gate του source.json"
   :presence :present
   :domain "source.json + sidecar <json>.prov.json (schema slw-source-prov/1)."
   :assumptions "Το sidecar γράφεται από τον ΙΔΙΟ τον παραγωγό αμέσως μετά το materialize."
   :guarantees "ΜΙΑ ετυμηγορία (%source-provenance-status): :valid|:unstamped|:tampered|:missing. Μόνο :valid προωθείται ως authoritative· κάθε άρνηση τυπώνεται με want/have hashes και τη διόρθωση."
   :failure-semantics "fail-closed, εκτός ORCHESTRATOR_ALLOW_UNVERIFIED_JSON=1 (και μόνο για υπαρκτό αρχείο)."
   :operating-model "content_sha256 του ΙΔΙΟΥ αρχείου· source_digest/extraction_method μπορεί να είναι :null."
   :materiality "ΤΟ SIDECAR ΕΙΝΑΙ ΑΥΤΟ-ΣΦΡΑΓΙΣΜΑ: αποδεικνύει «δεν άλλαξε από τότε που το σφράγισα», ΟΧΙ «προήλθε από αυθεντική πηγή». Ένα :valid με source_digest=null δεν διακρίνεται από ένα με πραγματική πηγή."
   :evidence "systems/orchestrator-cli/main.lisp:L267-L299,L1068-L1093,L1095-L1118")

  (:name "μητρώο εντολών με νόμο ΜΙΑΣ ΕΔΡΑΣ (register-command / retire-command!)"
   :presence :present
   :domain "133 κλήσεις register-command σε 30+ αρχεία του orchestrator-cli· 25 από αυτές λήγουν σε «-gate»."
   :assumptions "orchestrator.paths:current-load-file δίνει αποδώσιμη ταυτότητα αρχείου κατά το load."
   :guarantees "Δεύτερη εγγραφή ίδιου ονόματος από ΑΛΛΟ αρχείο ⇒ command-seat-collision (error). Επανεγγραφή ΚΑΤΑΡΓΗΜΕΝΟΥ ονόματος ⇒ error. retire-command! σε ΕΝΕΡΓΟ όνομα ⇒ error. Ανώνυμο runtime site ΔΕΝ διεκδικεί υπάρχουσα έδρα."
   :failure-semantics "fail-closed κατά το load."
   :operating-model "*commands* + *command-owners* + *retired-commands*· resolve-command = η ΔΗΛΩΜΕΝΗ ΜΙΑ έδρα επίλυσης (:registered|:retired|:unknown)."
   :materiality "ΤΟ ΙΔΙΟ ΑΥΣΤΗΡΟ ΜΟΝΤΕΛΟ ΔΕΝ ΙΣΧΥΕΙ για pipelines/corpora/backends: register-pipeline/register-corpus/register-backend είναι σκέτο (setf gethash) — σιωπηλή αντικατάσταση επιτρέπεται."
   :evidence "systems/orchestrator-cli/cli-util.lisp:L23-L140 · systems/orchestrator-meta/registry.lisp:L23-L54")

  (:name "συνταγματικός φραγμός δρομολόγησης (CLOS :around)"
   :presence :present
   :domain "Κάθε εντολή που περνά από execute-command."
   :assumptions "orchestrator.constitution:evaluate κρίνει το ΟΝΟΜΑ της εντολής (έδρα εκτός συστάδας)."
   :guarantees "Αντισυνταγματική πράξη ⇒ ΔΕΝ εκτελείται (exit 1) με αιτιολογία στο άρθρο· κάθε πράξη γίνεται root span ιχνών με :constitutional :allowed|:blocked."
   :failure-semantics "Άρνηση με μήνυμα· παράκαμψη ΜΟΝΟ ρητή (--force + LAWMAX_OVERRIDE_REASON, ή LAWMAX_OVERRIDE=<name> + LAWMAX_OVERRIDE_REASON)."
   :operating-model "CLOS method combination — ο φραγμός είναι το μεσολαβούν στρώμα, όχι κλήση που «καλείται»."
   :materiality "ΔΥΟ παραγωγικά μονοπάτια ΤΟΝ ΠΑΡΑΚΑΜΠΤΟΥΝ (--gates, HTTP /cmd)· η καταγραφή της παράκαμψης στη βιογραφία είναι σε (ignore-errors …)."
   :evidence "systems/orchestrator-cli/constitutional-dispatch.lisp:L22-L76")

  (:name "ολομέλεια πυλών (--gates) με data-only manifest"
   :presence :present
   :domain "Οι 25 εγγεγραμμένες εντολές που λήγουν σε «-gate», αλφαβητικά."
   :assumptions "Το σύνολο ΠΑΡΑΓΕΤΑΙ από το μητρώο, όχι από χειρόγραφη λίστα."
   :guarantees "Ό,τι δεν επιστρέφει ρητό 0 ⇒ ΑΠΕΤΥΧΕ· GATE-PLENARY-MANIFEST (:schema :gate-plenary/1 :completed t) εκπέμπεται ΜΟΝΟ μετά από ΟΛΕΣ τις πύλες ⇒ crash/OOM ⇒ κανένα manifest ⇒ όχι false-green."
   :failure-semantics "Ανεξέλεγκτο condition σε ΜΙΑ πύλη ματαιώνει ΟΛΗ την ολομέλεια πριν το manifest (κανένα per-gate handler-case)."
   :operating-model "(funcall (gethash name *commands*) nil) — ΑΠΕΥΘΕΙΑΣ, εκτός resolve-command/execute-command."
   :materiality "Ό,τι τυπώνεται ως «το 100% του συστήματος με ΜΙΑ εντολή» εκτελείται εκτός του συντάγματος."
   :evidence "systems/orchestrator-cli/gates-runner.lisp:L17-L63")

  (:name "πύλη αμεταβλήτων εκδόσεων (--release-gate)"
   :presence :present
   :domain "output/*/releases/** — δύο εποχές (census / legacy sealed), latest, latest.json, transparency log, exact-set κατά *served-corpora*."
   :assumptions "Οι έδρες του orchestrator.epistemic προσπελαύνονται με find-symbol στο runtime."
   :guarantees "census-εποχή: recomputed RFC-6962 root ≡ όνομα ≡ δηλωμένο + πλήρες spine + γέφυρα prev_release_root· [A1] anti-deletion (κάθε census-era attested root ∈ log entries)· κάθε υπηρετούμενο σώμα ΟΦΕΙΛΕΙ κατάλογο + ≥1 δημοσίευση· I/O σφάλμα = ΑΠΟΤΥΧΙΑ."
   :failure-semantics "read-only· κάθε αστοχία ονοματίζεται· rc=1."
   :operating-model "Καταναλώνει τις ΙΔΙΕΣ έδρες με τον παραγωγό (%release-recomputed-root, %root->release-id, verify-release-spine, tlog-verify)."
   :materiality "ΔΥΟ έλεγχοί της (legacy TSR seal, latest attested) καλούν την ΚΑΤΑΡΓΗΜΕΝΗ release-attested-p — βλ. defects P0#1."
   :evidence "systems/orchestrator-cli/release-gate.lisp:L33-L104,L106-L239")

  (:name "πύλη χρυσών αποτυπωμάτων (--golden-gate) — regression ratchet"
   :presence :present
   :domain "deployment/verify/golden/<short>.fingerprint.sexp για τα *served-corpora*."
   :assumptions "Το ΙΔΙΟ το golden ορίζει τη μέθοδο σύγκρισης από το σχήμα του (:file-id ⇒ :emitted, :num ⇒ :semantic)."
   :guarantees "Λείπον golden ⇒ ΚΟΚΚΙΝΟ· drift ⇒ ΚΟΚΚΙΝΟ με ονομαστικό diff· ρητός έλεγχος ότι κανένα golden δεν άλλαξε write-date από την αρχή ως το τέλος της πύλης· η πύλη ΔΕΝ γράφει."
   :failure-semantics "rc=1· καμία «διόρθωση» από την πύλη."
   :operating-model "Καταναλώνει orchestrator.fingerprint + build-consolidated-for + %fingerprint-method."
   :materiality "GOLDEN_DIR (env) ανακατευθύνει ΚΑΙ τη σύγκριση ΚΑΙ την «απόδειξη read-only»· ο έλεγχος ⑤ «ντετερμινισμός» είναι διπλός υπολογισμός ΜΕΣΑ στην ίδια εικόνα."
   :evidence "systems/orchestrator-cli/golden-gate.lisp:L42-L110 · systems/orchestrator-cli/main.lisp:L1588-L1598")

  (:name "πύλη ικανότητας (--capability-gate) — ratchet μέτρου"
   :presence :present
   :domain "deployment/verify/capability-baseline.sexp έναντι %legal-eval-run + %judge-metrics."
   :assumptions "Παγωμένα +legal-eval-cases+ και committed νομολογία γράφου."
   :guarantees "Baseline απόν/μη-αναγνώσιμο ⇒ ΚΟΚΚΙΝΟ (όχι honest-skip)· gold-συνέπεια = 100% ΠΑΝΤΑ· ίδιο μέτρο (ίδιοι πληθυσμοί + ταυτόσημο judge :dataset-stamp) αλλιώς ΚΟΚΚΙΝΟ· κάθε μετρική ≥ baseline· read-only."
   :failure-semantics "fail-closed."
   :operating-model "Το re-baseline είναι ΞΕΧΩΡΙΣΤΗ εντολή (--capability-baseline), ΟΧΙ μονοπάτι της πύλης."
   :materiality "*capability-baseline-path* είναι test-hook special var μέσα σε παραγωγικό κώδικα."
   :evidence "systems/orchestrator-cli/capability-gate.lisp:L18-L34,L38-L86")

  (:name "σύμβουλος LLM εκτός εμπιστοσύνης (advisor)"
   :presence :present
   :domain "OpenAI-συμβατό /chat/completions· δύο σκοποί: ταξινόμηση πρόθεσης, «όνειρο» γραμματικής (:dream-verb)."
   :assumptions "LAWMAX_ADVISOR_URL ορισμένο· αλλιώς η υποδοχή είναι ΚΕΝΗ (καθαρά συμβολική λειτουργία)."
   :guarantees "Η απάντηση διαβάζεται με *read-eval* nil, *package* :keyword, όριο 2000 χαρ.· ΜΟΝΟ 3 πλαίσια λευκού καταλόγου (:article-lookup :corpus-info :definition)· κάθε πρόταση περνά συμβολική επαλήθευση (corpus ∈ +law-tag-corpus-map+, άρθρο μόνο ψηφία, έννοια γειωμένη σε διάταξη)· το «όνειρο» γίνεται γνώση ΜΟΝΟ αν εξηγεί τον ΠΑΡΑΤΗΡΗΜΕΝΟ τύπο και το λήμμα είναι καθαρά ρηματικό."
   :failure-semantics "Κάθε αποτυχία (δίκτυο/μορφή/επαλήθευση) ⇒ nil — τίμια άγνοια· ο πυρήνας συνεχίζει συμβολικά."
   :operating-model "drakma:http-request POST, :connection-timeout 10, ΧΩΡΙΣ ρητή ρύθμιση επαλήθευσης TLS και ΧΩΡΙΣ read timeout."
   :materiality "Η ΕΙΣΟΔΟΣ ΤΟΥ ΧΡΗΣΤΗ (νομική ερώτηση) στέλνεται ΑΥΤΟΥΣΙΑ στο endpoint κάθε φορά που κανένας συμβολικός ταξινομητής δεν πιάνει."
   :evidence "systems/orchestrator-cli/advisor.lisp:L23-L70,L74-L88,L110-L152,L154-L198")

  (:name "αυτο-επέκταση με πύλες (--self-extend / --evolve)"
   :presence :present
   :domain "Πακέτα ΔΗΛΩΤΙΚΗΣ γνώσης (*.sexp) στον knowledge dir — ΠΟΤΕ κώδικας στο έμπιστο μονοπάτι (δηλωμένο όριο)."
   :assumptions "Τα κενά προέρχονται από τα καταγεγραμμένα lessons· ο advisor μπορεί να είναι συνδεδεμένος ή όχι."
   :guarantees "Κάθε τέχνημα: (1) συντακτική επικύρωση (load-pack)· (2) ΣΚΙΩΔΗΣ δοκιμή σε overlay (καμία μόλυνση της ενεργής γνώσης)· (3) κατάθεση ως ΠΡΟΤΑΣΗ. Το όνομα αρχείου περνά %assert-safe-pack-filename (μόνο basename *.sexp, όχι «/», «\\», «..», «:»)."
   :failure-semantics "Απόρριψη με τυπωμένο λόγο· η πρόταση μένει ΑΝΟΙΧΤΗ."
   :operating-model "Υιοθέτηση με --approve (πράξη δημιουργού) Ή ΑΥΤΟΜΑΤΑ μέσω %maybe-auto-approve όταν υπάρχει ενεργή πολιτική για την κλάση· το --evolve «τρέχει ΑΥΤΟΝΟΜΑ σε κάθε κύκλο του δαίμονα»."
   :materiality "ΜΟΝΟ η κλάση :dream-frame δέχεται πολιτική (+evolution-classes+)· όλες οι άλλες μένουν στο χέρι του δημιουργού — ΔΗΛΩΜΕΝΟ όριο."
   :evidence "systems/orchestrator-cli/self-extension.lisp:L1-L57,L26-L38,L465-L503 · systems/orchestrator-cli/approval-policy.lisp:L110-L121")

  (:name "πολιτικές αυτο-έγκρισης με «μετρημένη ακρίβεια»"
   :presence :present
   :domain "deployment/self/policies.sexp (append-only, fold: το τελευταίο γεγονός νικά)."
   :assumptions "Η ακρίβεια της κλάσης μετριέται πάνω σε ΚΛΕΙΔΩΜΕΝΗ σουίτα πριν ζητηθεί πολιτική."
   :guarantees "Η εγγραφή περνά από %policy-append! ⇒ append-line :verify t + require-durable! (η απόφαση δημιουργού δεν χάνεται σιωπηλά)· ανάκληση ανά πάσα στιγμή (--policy-revoke)· καμία πολιτική χωρίς μέτρηση ((0 0) ⇒ μη μετρήσιμη κλάση)."
   :failure-semantics "fail-closed στη διάρκεια της εγγραφής."
   :operating-model "policy-active-p ⇒ %maybe-auto-approve ⇒ orchestrator.proposals:approve!."
   :materiality "Η σουίτα +dream-precision-suite+ ΖΕΙ ΣΤΟ ΙΔΙΟ ΑΡΧΕΙΟ με τον μετρητή και το ίδιο το σχόλιο δηλώνει ότι οι εχθρικές περιπτώσεις «κλειδώθηκαν ΑΦΟΥ σκλήρυνε ο validate-dream» — η μέτρηση που εξουσιοδοτεί την αυτονομία είναι εκ κατασκευής 24/24."
   :evidence "systems/orchestrator-cli/approval-policy.lisp:L20-L47,L62-L94,L96-L113,L115-L121")

  (:name "μνήμη αναστοχασμού (lessons.jsonl)"
   :presence :present
   :domain "<state-dir>/lessons.jsonl — JSONL {date,kind,subject,detail}· 8+ σημεία κλήσης."
   :assumptions "Ο state dir (STATE_DIR ή deployment/state/) είναι εγγράψιμος."
   :guarantees "Append-only· ΜΙΑ έδρα ανάγνωσης (%lessons-aggregate) που μοιράζονται --lessons ΚΑΙ run-reflect· ≥3 επαναλήψεις ⇒ «ΕΠΑΝΑΛΑΜΒΑΝΟΜΕΝΟ — διόρθωσε στην ρίζα»."
   :failure-semantics "ΟΛΟΚΛΗΡΟ το %lesson είναι σε (ignore-errors …) ⇒ αποτυχία εγγραφής εξαφανίζεται σιωπηλά ΚΑΙ αφήνει *gap-created-this-turn* = NIL."
   :operating-model "Χειροκίνητη κλήση σε κάθε σημείο αποτυχίας — όχι δομικά υποχρεωτική· η κάλυψη είναι ασύμμετρη."
   :materiality "Το *gap-created-this-turn* τροφοδοτεί το πεδίο gap_created του envelope του run-ask."
   :evidence "systems/orchestrator-cli/decisions.lisp:L88-L112,L115-L132,L134-L149")

  (:name "intake αποφάσεων από το ίδιο το κείμενο (%decision-intake)"
   :presence :present
   :domain "input/decisions/*.{pdf,html,txt} → <slug>/<tag>_<έτος>_<αριθμός>.<type>"
   :assumptions "7 σταθερές συμβολοσειρές στο *court-registry*· ταυτότητα από regex στο κείμενο ή στο ΟΝΟΜΑ αρχείου."
   :guarantees "Ό,τι δεν κατανοείται ΔΕΝ αρχειοθετείται: τυπώνεται λόγος (σαρωμένο/άγνωστο δικαστήριο/μη ευρέσιμη ταυτότητα)."
   :failure-semantics "Per-file handler-case ⇒ το σφάλμα τυπώνεται και το intake συνεχίζει με τα υπόλοιπα."
   :operating-model "rename-file στο ίδιο δέντρο· ένα αρχείο τη φορά."
   :materiality "Η αποτυχία ΤΑΥΤΟΤΗΤΑΣ ΔΕΝ γράφει lesson (μόνο τυπώνει)· η αποτυχία ΔΙΚΑΣΤΗΡΙΟΥ γράφει."
   :evidence "systems/orchestrator-cli/decisions.lisp:L150-L216")

  (:name "OCR fallback για σαρωμένες αποφάσεις (ΚΑΤΑΝΑΛΩΤΗΣ· η έδρα εκτός συστάδας)"
   :presence :present
   :domain "PDF χωρίς text layer· κλήση orchestrator.pdf-authority:extract-text-any / ocr-available-p."
   :assumptions "pdftoppm + tesseract με γλώσσα ell στο PATH."
   :guarantees "Ο καλών παίρνει ΠΑΝΤΑ (values text source) με source ∈ {:text-layer,:ocr,:none} — «ξέρει ΠΑΝΤΑ από πού ήρθε το κείμενο»."
   :failure-semantics "extract-text-any ⇒ :none· ο καλών decisions.lisp ματαιώνει το intake και γράφει lesson :needs-ocr."
   :operating-model "Η ΕΔΡΑ ζει σε source/pdf-authority.lisp (ΕΚΤΟΣ systems/)· το systems/ είναι μόνο καταναλωτής· η κλιμάκωση σελίδες→PNG→tesseract γίνεται σε /tmp/lawmax-ocr-<universal-time>/."
   :materiality "Η διάκριση «λείπει OCR» vs «OCR δεν απέδωσε» υπάρχει ΜΟΝΟ ως κείμενο stdout — βλ. ΕΙΔΙΚΗ ΤΕΚΜΗΡΙΩΣΗ παρακάτω."
   :evidence "systems/orchestrator-cli/decisions.lisp:L168-L183 · source/pdf-authority.lisp:L1386-L1398,L1400-L1424,L1427-L1441")

  (:name "δοκιμές FiveAM — ΔΕΥΤΕΡΗ ΕΔΡΑ ΔΟΚΙΜΩΝ εκτός του glob tests/*-test.lisp"
   :presence :present
   :domain "orchestrator-tests/: 13 αρχεία (12 .lisp με περιεχόμενο δοκιμών + package.lisp), 4 def-suite (master + unit + integration + reproducibility), 12 (test …) forms σε unit/, 7 σε integration/, 1 σε reproducibility/."
   :assumptions "Τα fixtures γράφουν σε ΣΤΑΘΕΡΑ ΑΠΟΛΥΤΑ μονοπάτια /tmp/orchestrator-test-ai/, /tmp/orchestrator-integration-test/, /tmp/orchestrator-test/."
   :guarantees "run-all-tests ⇒ T ΜΟΝΟ όταν (fiveam:results-status results) = NIL· καλείται από orchestrator-tests.asd test-op, orchestrator-tests-runtime.asd test-op, entrypoint.lisp, και --run-tests."
   :failure-semantics "Επιστρέφει NIL· ο καλών αποφασίζει."
   :operating-model "Καθαρά in-process· ΚΑΜΙΑ δοκιμή δεν διασχίζει όριο διεργασίας ή μηχανής."
   :materiality "Οι δοκιμές «αναπαραγωγιμότητας» συγκρίνουν δύο κλήσεις ΜΕΣΑ στην ΙΔΙΑ εικόνα· καμία δεν αγγίζει release/authority/gate μονοπάτι — η συστάδα epistemic/cli ΔΕΝ καλύπτεται από αυτή τη δεύτερη έδρα καθόλου."
   :evidence "systems/orchestrator-tests/package.lisp:L6-L13 · systems/orchestrator-tests/suite.lisp:L11-L26,L69-L98 · systems/orchestrator-tests/unit/test-ai-core.lisp:L13,L64-L74,L417-L452 · systems/orchestrator-tests/integration/ai-export-integration-test.lisp:L15-L16,L192-L215 · systems/orchestrator-tests/reproducibility/hash-stability-test.lisp:L8-L13")

  (:name "mode-gated έλεγχος ροής εκτέλεσης (executor)"
   :presence :present
   :domain "sequential-executor: :production vs :interactive."
   :assumptions "Ασφαλής προεπιλογή :production."
   :guarantees ":production ⇒ ΚΑΝΕΝΑ restart, άμεση διάδοση σφάλματος· validation-error ΠΟΤΕ δεν ξαναδοκιμάζεται (καμία επανάληψη, κανένα restart)."
   :failure-semantics "Γενικό σφάλμα ⇒ έως 3 ΣΙΩΠΗΛΕΣ επαναλήψεις σταδίου, μετά διάδοση."
   :operating-model "detect-executor-mode: ORCHESTRATOR_MODE=interactive Ή ΠΑΡΟΥΣΙΑ πακέτου swank/slynk ⇒ :interactive."
   :materiality "Σε εικόνα που τυχαίνει να έχει φορτωμένο SLIME/Sly, το production γίνεται :interactive και ενεργοποιούνται τα restarts skip-article / mark-degraded-and-continue — υποβάθμιση χωρίς καμία ρητή εντολή."
   :evidence "systems/orchestrator-core/executor.lisp:L10-L32,L38-L57,L104-L129,L164-L204")

  (:name "auto-detection πηγής με JSON fallback"
   :presence :present
   :domain "ORCHESTRATOR_PDF_PATH → ORCHESTRATOR_PDF_INPUT_DIR (glob) → ORCHESTRATOR_JSON_PATH."
   :assumptions "Το corpus-specific pdf-path έχει προτεραιότητα και το directory ΔΕΝ globάρεται όταν δίνεται."
   :guarantees "Τυπώνεται [SOURCE-DETECT] ποιο μονοπάτι επιλέχθηκε· τίποτα ⇒ NIL."
   :failure-semantics "Το ρυθμισμένο PDF που ΔΕΝ υπάρχει ΔΕΝ σφάλλει — πέφτει στο JSON fallback."
   :operating-model "detect-source-config· ο καλών run-pipeline συνεχίζει με ό,τι βρέθηκε."
   :materiality "Το fallback μπορεί να είναι το committed placeholder JSON. Ο μόνος μηχανικός δείκτης είναι «<5 άρθρα» στο run-all-pipelines — που ΔΕΝ αλλάζει τον κωδικό εξόδου."
   :evidence "systems/orchestrator-core/source-detection.lisp:L105-L196 · systems/orchestrator-cli/main.lisp:L1448-L1485")

  (:name "blockchain anchoring (ethereum/arweave/ipfs)"
   :presence :spec-only
   :domain "Merkle root όλων των article hashes → configured chains."
   :assumptions "Οι credentials δίνονται εκτός· μη ρυθμισμένη αλυσίδα παρακάμπτεται."
   :guarantees "Ρυθμισμένη αλυσίδα που αποτυγχάνει καταγράφεται στα anchor-results."
   :failure-semantics "*anchor-require-at-least-one* = NIL ⇒ ΜΗΔΕΝ επιτυχείς αγκυρώσεις ΔΕΝ είναι σφάλμα· ο deploy συνεχίζει με blockchain-anchor «pending»."
   :operating-model "Delegation στο orchestrator.blockchain-authority (εκτός συστάδας)· υπάρχει και mock-backend με (random (expt 2 32)) tx-id."
   :materiality "Ως συμβόλαιο προς τα έξω δεν εγγυάται ΤΙΠΟΤΑ: κανένα release δεν εξαρτάται από επιτυχή αγκύρωση. Δεν είδα κανένα σημείο που να θέτει *anchor-require-at-least-one* σε T."
   :evidence "systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp:L23-L27,L62-L105 · systems/orchestrator-engine-sbcl/backends/mock.lisp:L13-L26 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L976")

  (:name "μετρικές γεγονότων γένεσης/σφάλματος (orchestrator.meta)"
   :presence :absent
   :domain "record-generation-event / record-error-event."
   :assumptions "—"
   :guarantees "Καμία. Και οι δύο συναρτήσεις επιστρέφουν NIL χωρίς παρενέργεια."
   :failure-semantics "Κάθε frbr-generation-error που «καταγράφεται στις μετρικές» εξαφανίζεται."
   :operating-model "Μόνιμο no-op stub με σχολιασμένη «REAL IMPLEMENTATION» μέσα στο ίδιο αρχείο."
   :materiality "Το αρχείο ζει στο orchestrator-omega-modules/ αλλά κάνει (in-package :orchestrator.meta) και (export …) — ορίζει δημόσια ΑΠΙ άλλου συστήματος· η κεφαλίδα του δηλώνει ψευδώς τη διαδρομή systems/orchestrator-meta/metrics-stub.lisp."
   :evidence "systems/orchestrator-omega-modules/metrics-stub.lisp:L1-L20 · systems/orchestrator-omega-modules/frbr-conditions.lisp:L166-L176")

  (:name "ταυτότητα δημιουργού για ΚΑΘΕ HTTP επιφάνεια"
   :presence :present
   :domain "/ask, /cmd (serve-corpus) και cockpit /api/* — %creator-request-authorised-p."
   :assumptions "«Προσωπική τοπική εγκατάσταση: η θύρα ΕΙΝΑΙ ο δημιουργός»."
   :guarantees "Με LAWMAX_CREATOR_TOKEN ορισμένο, απαιτείται ?key=… που ταιριάζει ΑΚΡΙΒΩΣ."
   :failure-semantics "ΧΩΡΙΣ token (ή με κενό/whitespace token) επιστρέφει ΠΑΝΤΑ T — κάθε αιτών είναι ο δημιουργός."
   :operating-model "(equal tok key) — σύγκριση μεταβλητού χρόνου· το μυστικό ταξιδεύει σε query string."
   :materiality "ΜΙΑ έδρα, ΤΡΕΙΣ καταναλωτές με ΑΣΥΜΜΕΤΡΕΣ περιβάλλουσες φραγές: το cockpit προσθέτει Host-allowlist + custom header· το /ask και /cmd ΤΙΠΟΤΑ, και το serve-corpus δεσμεύεται στο 0.0.0.0."
   :evidence "systems/orchestrator-cli/cli-util.lisp:L192-L199 · systems/orchestrator-cli/main.lisp:L803-L850,L911 · systems/orchestrator-cli/cockpit.lisp:L228-L268")

  (:name "cockpit — Host-guard + CSRF"
   :presence :present
   :domain "Κάθε /api αίτημα του cockpit."
   :assumptions "COCKPIT_HOST default 127.0.0.1."
   :guarantees "Σειρά fail-closed: Host (anti-DNS-rebinding) → X-LAWMAX-Cockpit header (anti simple-CORS CSRF) → key. Μη-loopback bind ΧΩΡΙΣ allowlist επιτρέπεται ΜΟΝΟ αν υπάρχει LAWMAX_CREATOR_TOKEN. Κάθε /api περνά require-trust (advisor δυνατότητα ⇒ 403, δεν φτάνει στο :fn)."
   :failure-semantics "403 με ονομαστική αιτία."
   :operating-model "Οι δυνατότητες ορίζονται ΜΙΑ φορά (define-capability) και η HTTP επιφάνεια είναι προβολή τους (api-dispatch)."
   :materiality "Ο κλάδος COCKPIT_ALLOWED_HOSTS βραχυκυκλώνει ΠΡΙΝ την απαίτηση token."
   :evidence "systems/orchestrator-cli/cockpit.lisp:L21-L25,L31-L40,L219-L268,L277-L299")

  (:name "ενιαία ταυτότητα γύρου (turn_id / root span)"
   :presence :present
   :domain "*current-turn-id*, *turn-root-span*, *turn-counter*, *turn-nonce*."
   :assumptions "Η γέννηση γίνεται σε ΕΝΑ σημείο (είσοδος run-ask)."
   :guarantees "sha256(input ‖ iso ‖ nonce ‖ counter)[0:12]· μηδενίζεται στην είσοδο ΚΑΘΕ εντολής ⇒ ποτέ stale· αμφίδρομη αντιστοίχιση turn_id ↔ root_span_id."
   :failure-semantics ":unknown (δεν διάβασα το run-ask)."
   :operating-model "Πεδίο που διατρέχει ΥΠΑΡΧΟΥΣΕΣ έδρες (envelope/episode/failure-ledger/root-span), ΟΧΙ νέο store."
   :materiality "Το nonce παράγεται από (get-universal-time)+(get-internal-real-time) — όχι CSPRNG· επαρκές για μη-σύγκρουση, όχι για μη-προβλεψιμότητα."
   :evidence "systems/orchestrator-cli/cli-util.lisp:L142-L182 · systems/orchestrator-cli/constitutional-dispatch.lisp:L53-L55")

  (:name "μόνιμη κατάσταση με keyed cursors"
   :presence :present
   :domain "<state-dir>/<key>-last-seen.txt (legacy «fek» τιμά FEK_STATE_FILE)."
   :assumptions "Το deployment/ είναι bind-mounted στο docker-compose."
   :guarantees "Εγγραφή ΑΤΟΜΙΚΑ (write-file-atomic: temp+fsync+rename) ⇒ crash δεν αφήνει μισό cursor."
   :failure-semantics "%write-cursor τυλιγμένο σε (ignore-errors …) ⇒ αποτυχία διατήρησης εξαφανίζεται σιωπηλά."
   :operating-model "STATE_DIR env μπορεί να μετακινήσει ΟΛΗ την κατάσταση (μαζί με τα lessons.jsonl)."
   :materiality "Το ίδιο το σχόλιο καταγράφει ότι state εκτός mount «πέθαινε με κάθε --rm container»."
   :evidence "systems/orchestrator-cli/cli-util.lisp:L209-L249")

  (:name "tombstones αποσυρμένων entrypoints"
   :presence :present
   :domain "5 συναρτήσεις: run-full-build, run-full-build-ai, run-ai-export-only, cli::validate-pipeline, cli::generate-report."
   :assumptions "Αποδείχθηκαν μη προσβάσιμες (static + runtime closure, commit b5953a04) — 163 εντολές στο μητρώο, καμία εδώ."
   :guarantees "Κάθε κλήση σφάλλει με orchestrator.spec:retired-entrypoint που ονομάζει τον canonical entrypoint· «Tombstone hit ⇒ η διαγραφή ΑΚΥΡΩΝΕΤΑΙ»."
   :failure-semantics "error, πάντα."
   :operating-model "Δηλωμένο ΕΝΑΣ κύκλος επαλήθευσης, μετά οριστική διαγραφή με έγκριση δημιουργού."
   :materiality "ΚΑΙ ΤΑ 5 ΟΝΟΜΑΤΑ ΠΑΡΑΜΕΝΟΥΝ ΣΤΟ :export ΤΟΥ ΠΑΚΕΤΟΥ orchestrator.cli — το δημόσιο συμβόλαιο διαφημίζει τάφους."
   :evidence "systems/orchestrator-cli/commands.lisp:L1-L67 · systems/orchestrator-cli/package.lisp:L9-L16"))

 :authorities
 ((:name "admission kernel της authority-v2 (ΕΚΤΟΣ ΣΥΣΤΑΔΑΣ — μόνο δηλωμένος)"
   :what-it-can-decide "Προαγωγή candidate → authoritative release/log/latest· πλήρης RFC-3161 TSA επαλήθευση ως ΥΠΟΧΡΕΩΤΙΚΟ conjunct εισδοχής."
   :who-can-invoke ":unknown από τη συστάδα systems/ — ΚΑΜΙΑ κλήση προς αυτόν δεν υπάρχει εδώ."
   :enforcement :os
   :evidence "systems/orchestrator-epistemic/authority-boundary.lisp:L5-L15,L52-L58 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L947-L950 · systems/orchestrator-cli/release-authority.lisp:L154-L163")

  (:name "legacy producer (ΟΛΟΚΛΗΡΟ το systems/)"
   :what-it-can-decide "ΜΟΝΟ παραγωγή candidate bundles· καμία authoritative εγγραφή."
   :who-can-invoke "deploy-epistemic-stage από το pipeline ή από το --cut-release."
   :enforcement :code
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L1103-L1127 · systems/orchestrator-cli/release-authority.lisp:L171-L191")

  (:name "ο δημιουργός μέσω --approve / --review-approve / --policy-approve"
   :what-it-can-decide "Υιοθέτηση πρότασης γνώσης (γράφει πακέτο στον knowledge dir)· έγκριση εγγραφής στην ουρά ελέγχου· ενεργοποίηση ΚΛΑΣΗΣ αυτο-έγκρισης."
   :who-can-invoke "CLI· cockpit /api/decide (μετά από Host+CSRF+key)· ΟΧΙ το /cmd (εκτός whitelist)."
   :enforcement :code
   :evidence "systems/orchestrator-cli/self-reflection.lisp:L195-L204,L665-L666 · systems/orchestrator-cli/cockpit.lisp:L60-L70 · systems/orchestrator-cli/approval-policy.lisp:L115-L121 · systems/orchestrator-cli/main.lisp:L784-L789")

  (:name "ενεργή πολιτική :dream-frame — ΑΥΤΟΝΟΜΗ εξουσία εγγραφής γνώσης"
   :what-it-can-decide "Αυτόματη έγκριση κάθε νέας πρότασης γραμματικής που περνά το validate-dream, ΧΩΡΙΣ ανθρώπινη πράξη ανά περίπτωση."
   :who-can-invoke "Ενεργοποιείται μία φορά από τον δημιουργό (--policy-approve dream-frame)· έπειτα ενεργεί ο δαίμονας μέσω --evolve. Η ΠΗΓΗ των προτάσεων μπορεί να είναι ο εξωτερικός LLM (LAWMAX_ADVISOR_URL)."
   :enforcement :code
   :evidence "systems/orchestrator-cli/approval-policy.lisp:L110-L121 · systems/orchestrator-cli/self-extension.lisp:L364-L440,L465-L490 · systems/orchestrator-cli/advisor.lisp:L99-L103,L184-L198")

  (:name "χειριστής μέσω μεταβλητών περιβάλλοντος"
   :what-it-can-decide "ORCHESTRATOR_DEV_MODE (παρακάμπτει JWS gate + signature material gate)· LAWMAX_ALLOW_KEY_GENESIS (γεννά trust root)· ORCHESTRATOR_ALLOW_DEGRADED_PROOFS (unsigned proofs ΚΑΙ proofs χωρίς primary anchor)· ORCHESTRATOR_ALLOW_UNVERIFIED_JSON (προωθεί μη επαληθευμένο source.json)· ORCHESTRATOR_ALLOW_SHRINK· GOLDEN_DIR / GOLDEN_WRITE· AUTO_UPDATE_GATES=0· ORCHESTRATOR_TRACE_PROFILE· ORCHESTRATOR_MODE· STATE_DIR· TSA_CA_BUNDLE· PRIVATE_KEY_PATH· RELEASE_CERT_PATH· LAWMAX_OVERRIDE(+_REASON)· LAWMAX_CREATOR_TOKEN· LAWMAX_ADVISOR_URL/KEY/MODEL· COCKPIT_HOST/ALLOWED_HOSTS."
   :who-can-invoke "Οποιοσδήποτε ελέγχει το περιβάλλον της διεργασίας."
   :enforcement :none
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L255-L258,L348-L354,L430-L442 · systems/orchestrator-cli/main.lisp:L280,L1187,L1834,L1888,L2500-L2516 · systems/orchestrator-cli/cli-util.lisp:L192-L199,L213-L228 · systems/orchestrator-cli/golden-gate.lisp:L48-L57 · systems/orchestrator-cli/constitutional-dispatch.lisp:L37-L39")

  (:name "HTTP επιφάνειες /ask, /cmd (serve-corpus, bind 0.0.0.0)"
   :what-it-can-decide "/ask: ακροατήριο :creator (ενδοσκόπηση/ατζέντα) έναντι :guest. /cmd: εκτέλεση --auto-update (πλήρης κύκλος: λήψη από δίκτυο → ξαναγράψιμο ΟΛΩΝ των outputs → υπογεγραμμένες αποδείξεις → προαιρετική δημοσίευση site) ή --failures."
   :who-can-invoke "ΧΩΡΙΣ LAWMAX_CREATOR_TOKEN: οποιοσδήποτε φτάνει τη θύρα."
   :enforcement :none
   :evidence "systems/orchestrator-cli/main.lisp:L784-L789,L803-L850,L900-L912,L1295-L1368 · systems/orchestrator-cli/cli-util.lisp:L192-L199")

  (:name "ολομέλεια πυλών --gates"
   :what-it-can-decide "Ενιαία ετυμηγορία «100% του συστήματος» + GATE-PLENARY-MANIFEST (:completed t)."
   :who-can-invoke "CLI, cron, --auto-update, και έμμεσα το δημόσιο /cmd."
   :enforcement :code
   :evidence "systems/orchestrator-cli/gates-runner.lisp:L17-L63 · systems/orchestrator-cli/main.lisp:L1351-L1355")

  (:name "*court-registry* — αναγνώριση δικαστηρίου"
   :what-it-can-decide "Σε ποιον φάκελο αρχειοθετείται μια απόφαση (7 δικαστήρια)."
   :who-can-invoke "%intake-one· επέκταση = μία γραμμή στο defparameter."
   :enforcement :code
   :evidence "systems/orchestrator-cli/decisions.lisp:L77-L87")

  (:name "*served-corpora* — το εύρος κάλυψης της πύλης εκδόσεων"
   :what-it-can-decide "Ποια σώματα ΟΦΕΙΛΟΥΝ υλοποιημένο output + ≥1 δημοσίευση (exact-set)."
   :who-can-invoke "defparameter στο main.lisp· καταναλώνεται από release-gate και golden-gate."
   :enforcement :code
   :evidence "systems/orchestrator-cli/main.lisp:L622 · systems/orchestrator-cli/release-gate.lisp:L209-L233 · systems/orchestrator-cli/golden-gate.lisp:L64"))

 :invariants
 ((:statement "log_root ≡ MTH(entries) και κάθε αποθηκευμένο checkpoint επεκτείνεται από το τρέχον δέντρο"
   :enforced-by "tlog-verify — επανυπολογισμός + RFC6962 §2.1.2 consistency proof"
   :evidence "systems/orchestrator-epistemic/transparency-log.lisp:L134-L169")
  (:statement "Το όνομα του candidate καταλόγου ≡ sha256 του Merkle root των canonical αρχείων του"
   :enforced-by "atomic-publish-release: %release-dir-root στο staging + %release-recomputed-root στον υπάρχοντα (ποτέ το δηλωμένο)"
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L831-L851")
  (:statement "sha256-named release χωρίς census.json ΚΑΙ εκτός του παγωμένου συνόλου των 18 ⇒ ΣΦΑΛΜΑ (κανένα epoch-downgrade με stripped census)"
   :enforced-by "%release-canonical-era + frozen-legacy-release-id-p· ξανά ανεξάρτητα στην πύλη"
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L876-L922 · systems/orchestrator-cli/release-gate.lisp:L38-L48")
  (:statement "Το υλικό TSA CA ενός release είναι ΑΚΡΙΒΩΣ ένα από {δομικά έγκυρο X.509 pem, σημείωση με canonical sentinel}"
   :enforced-by "%tsa-ca-material-ok-p — ανεξάρτητα από την έδρα εκπομπής"
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L315-L346,L1188-L1193")
  (:statement "Το trust root δεν γεννιέται σιωπηλά ανά run"
   :enforced-by "ensure-crypto-keys-exist + %key-genesis-explicitly-allowed-p"
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L348-L377")
  (:statement "Όταν υπάρχει transparency log, ΚΑΘΕ census-era attested root του corpus ΟΦΕΙΛΕΙ να είναι entry του (anti-deletion [A1])"
   :enforced-by "run-release-gate"
   :evidence "systems/orchestrator-cli/release-gate.lisp:L150-L173")
  (:statement "Μια εντολή έχει ΜΙΑ έδρα· καταργημένο όνομα δεν ανασταίνεται· ενεργό όνομα δεν δηλώνεται καταργημένο"
   :enforced-by "register-command / retire-command! (command-seat-collision, error)"
   :evidence "systems/orchestrator-cli/cli-util.lisp:L46-L64,L97-L106")
  (:statement "Η αλυσίδα σταδίων του --cut-release παράγεται από ΤΟΝ ΙΔΙΟ ορισμό pipeline (κλείσιμο υπο-DAG load-json-source→hash-artifacts), όχι από χειρόγραφο αντίγραφο"
   :enforced-by "%release-stage-chain (Kahn· κύκλος ⇒ ΣΦΑΛΜΑ· λείπον endpoint ⇒ ΣΦΑΛΜΑ)"
   :evidence "systems/orchestrator-cli/release-authority.lisp:L17-L90")
  (:statement "Το census-2 δεν κόβεται χωρίς δεσμευμένη διτεμπορική ιστορία (graph_root + receipt_set_root)"
   :enforced-by "deploy-epistemic-stage (engine): απόν :temporal-commitment ⇒ validation-error"
   :evidence "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L77-L85")
  (:statement "Το test-escaping-stage εκτελέστηκε με έγκυρο, μη παραποιημένο proof στη σωστή θέση του γράφου (:after generate-rdf :before validate-shacl)"
   :enforced-by "deploy-epistemic-stage (engine): τέσσερις διαδοχικοί έλεγχοι, καθένας fail-closed"
   :evidence "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L127-L154")
  (:statement "validation-error ΠΟΤΕ δεν ξαναδοκιμάζεται και ΠΟΤΕ δεν παίρνει restart"
   :enforced-by "execute-stage (orchestrator.core)"
   :evidence "systems/orchestrator-core/executor.lisp:L164-L170")
  (:statement "Όνομα πακέτου γνώσης = ΜΟΝΟ απλό basename *.sexp (καμία διαδρομή, κανένα ..)"
   :enforced-by "%assert-safe-pack-filename πριν από κάθε write-file-atomic υιοθέτησης"
   :evidence "systems/orchestrator-cli/self-extension.lisp:L26-L38,L48-L52")
  (:statement "Απόφαση πολιτικής του δημιουργού δεν χάνεται σιωπηλά"
   :enforced-by "%policy-append!: append-line :verify t + require-durable!"
   :evidence "systems/orchestrator-cli/approval-policy.lisp:L23-L30"))

 :defects
 ((:what "Η --release-gate καλεί ΔΥΟ ΦΟΡΕΣ την orchestrator.epistemic::release-attested-p, που είναι ΚΑΤΑΡΓΗΜΕΝΗ ΕΔΡΑ και σηματοδοτεί ΠΑΝΤΑ legacy-authority-seat-removed. Καμία από τις δύο κλήσεις δεν είναι σε handler-case ⇒ (α) legacy release με timestamp.tsr, ή (β) content-addressed latest, ανατινάζουν την πύλη με ανεξέλεγκτο condition· μέσα στο --gates αυτό ματαιώνει ΟΛΗ την ολομέλεια πριν εκπεμφθεί το GATE-PLENARY-MANIFEST. Οι ΜΟΝΟΙ παραγωγικοί καλούντες της καταργημένης έδρας σε ΟΛΟ το repo είναι αυτές οι δύο γραμμές· τα tests επιβεβαιώνουν την κατάργηση αλλά ο ΚΑΤΑΝΑΛΩΤΗΣ δεν ενημερώθηκε."
   :severity :p0
   :evidence "systems/orchestrator-cli/release-gate.lisp:L66-L72,L189-L198 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L939-L953 · tests/level7-disarm-test.lisp:L63-L65"
   :is-it-in-the-known-defect-list :no)

  (:what "Το serve-corpus δεσμεύεται ΑΝΕΞΑΙΡΕΤΑ στο 0.0.0.0 και εκθέτει /ask και /cmd. Και τα δύο κρίνουν ταυτότητα ΜΟΝΟ με %creator-request-authorised-p, που ΧΩΡΙΣ LAWMAX_CREATOR_TOKEN επιστρέφει T για ΟΠΟΙΟΝΔΗΠΟΤΕ. Δεν υπάρχει Host-allowlist ούτε custom-header CSRF φραγή — σε αντίθεση με το cockpit, που έχει και τα δύο και είναι fail-closed σε δημόσιο bind. Προεπιλεγμένη ανάπτυξη χωρίς token: κάθε απομακρυσμένος πελάτης παίρνει ακροατήριο :creator στο /ask ΚΑΙ εκτελεί --auto-update μέσω /cmd."
   :severity :p0
   :evidence "systems/orchestrator-cli/main.lisp:L900-L912,L803-L850,L1295-L1368 · systems/orchestrator-cli/cli-util.lisp:L192-L199 · systems/orchestrator-cli/cockpit.lisp:L228-L268"
   :is-it-in-the-known-defect-list :unknown)

  (:what "ΤΡΙΑ μονοπάτια δρομολόγησης, ΕΝΑ δηλωμένο. Το main δηλώνει ρητά ότι το εύρημα «30 builtin εντολές εκτελούνται ΕΚΤΟΣ της πύλης του ΕΓΩ» έκλεισε «στη ρίζα της δρομολόγησης» μέσω resolve-command + execute-command. Όμως το --gates εκτελεί (funcall (gethash name *commands*) nil) και το HTTP /cmd εκτελεί (funcall (find-command name) nil) — και τα δύο παρακάμπτουν και το resolve-command και τη συνταγματική :around."
   :severity :p0
   :evidence "systems/orchestrator-cli/gates-runner.lisp:L28-L37 · systems/orchestrator-cli/main.lisp:L843-L850,L2529-L2544 · systems/orchestrator-cli/constitutional-dispatch.lisp:L49-L76"
   :is-it-in-the-known-defect-list :unknown)

  (:what "«✓ ALL PROOF GATES PASSED» εκτυπώνεται ΑΝΕΞΑΡΤΗΤΑ από το αν πέρασαν: το GATE 2 (RFC-3161) μπορεί να απέτυχε σε ΟΛΕΣ τις TSA (τυπώνεται «⚠ UNATTESTED») και το GATE 3 (JWS) να παραλείφθηκε σε dev-mode· η γραμμή L529 δεν εξαρτάται από κανένα από τα δύο αποτελέσματα."
   :severity :p0
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L488-L504,L511-L527,L529"
   :is-it-in-the-known-defect-list :unknown)

  (:what "ORCHESTRATOR_DEV_MODE (env, χωρίς καμία επιβολή) υποβαθμίζει ΔΥΟ πύλες: παραλείπει την υπογραφή JWS στο GATE 3 και δέχεται release χωρίς signature.jws/public.jwk στο material gate. Το ίδιο το release ΔΕΝ φέρει καμία ένδειξη ότι παρήχθη σε dev-mode."
   :severity :p0
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L255-L258,L513-L525,L1195-L1202"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Το engine stage καλεί ΔΕΥΤΕΡΗ φορά την validate-epistemic-stage πάνω στο ΤΕΛΙΚΟ candidate dir και, σε αποτυχία, μόνο ΠΡΟΕΙΔΟΠΟΙΕΙ (log:warn «some files may be missing») ενώ επιστρέφει κανονικά το context. Η ΙΔΙΑ συνάρτηση στο Step 8 του παραγωγού είναι σκληρή πύλη (error). Δύο κλήσεις της ίδιας πύλης με ΑΝΤΙΘΕΤΗ σημασιολογία επιβολής — και η μη-επιβάλλουσα είναι αυτή που τρέχει πάνω στο ΔΗΜΟΣΙΕΥΜΕΝΟ artifact."
   :severity :p0
   :evidence "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L156-L161 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L1096-L1101"
   :is-it-in-the-known-defect-list :unknown)

  (:what "%creator-request-authorised-p: χωρίς LAWMAX_CREATOR_TOKEN (ή με κενό token) ΚΑΘΕ αιτών ταυτοποιείται ως ο δημιουργός. Με token, η σύγκριση (equal tok key) δεν είναι σταθερού χρόνου και το μυστικό μεταφέρεται σε query string (?key=…), όπου καταλήγει σε logs/referrers/ιστορικό."
   :severity :p0
   :evidence "systems/orchestrator-cli/cli-util.lisp:L192-L199"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Η «μετρημένη ακρίβεια» που εξουσιοδοτεί την ΑΥΤΟΝΟΜΗ υιοθέτηση γνώσης είναι αυτο-αναφορική: η +dream-precision-suite+ (24 περιπτώσεις) ζει στο ΙΔΙΟ αρχείο με τον μετρητή, μετράει τον ΙΔΙΟ τον validate-dream, και το σχόλιο L90-L92 δηλώνει ρητά ότι οι εχθρικές περιπτώσεις «κλειδώθηκαν ΑΦΟΥ σκλήρυνε ο ίδιος ο validate-dream». Η βαθμολογία είναι 24/24 εκ κατασκευής. Επιπλέον μετράει τον ΔΙΚΑΣΤΗ, όχι τον ΠΡΟΤΕΙΝΟΝΤΑ: μόλις ενεργοποιηθεί η πολιτική, κάθε πρόταση του εξωτερικού LLM που περνά τον δικαστή γράφεται στη γνώση χωρίς ανθρώπινη πράξη."
   :severity :p0
   :evidence "systems/orchestrator-cli/approval-policy.lisp:L62-L94,L96-L108,L115-L121 · systems/orchestrator-cli/self-extension.lisp:L364-L440,L465-L490"
   :is-it-in-the-known-defect-list :unknown)

  (:what "run-all-pipelines επιστρέφει 0 (ΕΠΙΤΥΧΙΑ) ακόμη κι όταν σώματα έπεσαν στο placeholder JSON fallback: το «<5 άρθρα ⇒ likely missing input PDF» είναι ΜΟΝΟ τυπωμένη προειδοποίηση και δεν μπαίνει στον κωδικό εξόδου (μόνο το failed>0 τον αλλάζει). Το --auto-update το χειρίζεται ως ΚΡΙΣΙΜΗ φάση μέσω crit-rc ⇒ κύκλος με placeholder corpora βγάζει «όλα καθαρά»."
   :severity :p0
   :evidence "systems/orchestrator-cli/main.lisp:L1448-L1485,L1341-L1342 · systems/orchestrator-core/source-detection.lisp:L173-L196"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Το πακέτο orchestrator.spec ορίζεται από ΔΥΟ καταλόγους: 7 αρχεία στο orchestrator-spec/ και 11 στο orchestrator-omega-modules/ (frbr-protocol, frbr-conditions, frbr-consistency-validator, rdf-canonicalization, article-root-generator-omega, prov-activity-generator-omega, corpus-root-generator, hybrid-generator-phase1, unified-frbr-generator, config-accessor, html-rdfa-generator). Ομοίως το orchestrator.model (7+4) και το orchestrator.meta (6+1). Οκτώ από αυτά τα αρχεία φέρουν κεφαλίδα που ΔΗΛΩΝΕΙ ΨΕΥΔΩΣ διαφορετική διαδρομή, δύο εκ των οποίων σε καταλόγους που ΔΕΝ ΥΠΑΡΧΟΥΝ (systems/orchestrator-frbr/, systems/orchestrator-dsl/)."
   :severity :p0
   :evidence "systems/orchestrator-omega-modules/frbr-classes.lisp:L1-L5 · systems/orchestrator-omega-modules/frbr-conditions.lisp:L1-L5 · systems/orchestrator-omega-modules/frbr-protocol.lisp:L1-L5 · systems/orchestrator-omega-modules/turtle-dsl.lisp:L1-L4 · systems/orchestrator-omega-modules/work-generator-omega.lisp:L1-L4 · systems/orchestrator-omega-modules/expression-generator-omega.lisp:L1-L4 · systems/orchestrator-omega-modules/frbr-pipeline-stage.lisp:L1-L4 · systems/orchestrator-omega-modules/metrics-stub.lisp:L1-L5"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Το README του orchestrator-omega-modules περιγράφει «8 αρχεία / ~2400 lines» ενώ ο κατάλογος έχει 25 αρχεία / 7295 γραμμές, και δίνει ως ΕΓΚΑΤΑΣΤΑΣΗ μια σειρά από cp εντολές που αντιγράφουν τα αρχεία σε systems/orchestrator-model/, systems/orchestrator-dsl/, systems/orchestrator-spec/, systems/orchestrator-frbr/ — δηλαδή χειροκίνητο copy-back ως τεκμηριωμένη διαδικασία."
   :severity :p1
   :evidence "systems/orchestrator-omega-modules/README.md:L1-L60"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Το systems/orchestrator-omega.asd δεν είναι ASDF αρχείο: είναι κανονικό αρχείο 25 bytes που περιέχει ΜΟΝΟ τη συμβολοσειρά «../orchestrator-omega.asd» χωρίς newline — symlink που υλοποιήθηκε ως regular file στο checkout. Ένα ASDF load από αυτό το μονοπάτι αποτυγχάνει."
   :severity :p1
   :evidence "systems/orchestrator-omega.asd:L1 (25 bytes, ASCII, no line terminator· ο πραγματικός στόχος /frozen/ro/orchestrator-omega.asd είναι 10829 bytes)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Η καταγραφή της συνταγματικής ΠΑΡΑΚΑΜΨΗΣ στη βιογραφία είναι τυλιγμένη σε (ignore-errors …): αν αποτύχει, η πράξη ΕΚΤΕΛΕΙΤΑΙ ούτως ή άλλως και το ίχνος της παράβασης χάνεται — ενώ το ίδιο το αρχείο δηλώνει «Ποτέ σιωπηλή παράβαση»."
   :severity :p1
   :evidence "systems/orchestrator-cli/constitutional-dispatch.lisp:L13-L14,L41-L47,L71-L74"
   :is-it-in-the-known-defect-list :unknown)

  (:what "%lesson τυλιγμένο ολόκληρο σε ignore-errors: αποτυχία εγγραφής lessons.jsonl εξαφανίζει το κενό ΚΑΙ αφήνει *gap-created-this-turn* = NIL, οπότε το envelope δηλώνει gap_created ψευδώς αρνητικό — ενώ η μεταβλητή τεκμηριώνεται ρητά ως «υπολογίζεται από τα ΠΡΑΓΜΑΤΙΚΑ %lesson»."
   :severity :p1
   :evidence "systems/orchestrator-cli/decisions.lisp:L88-L92,L94-L112"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Αποτυχία φόρτωσης των πακέτων γνώσης στο startup είναι ΜΟΝΟ προειδοποίηση στο stderr· η εκτέλεση συνεχίζει και «οι κρίσεις θα είναι ελλιπείς» — καμία πύλη, κανένα envelope, κανένα exit code δεν φέρει αυτή τη σημαία."
   :severity :p1
   :evidence "systems/orchestrator-cli/main.lisp:L2517-L2525"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Το δημόσιο :export του πακέτου orchestrator.cli διαφημίζει ΠΕΝΤΕ ονόματα (run-full-build, run-full-build-ai, run-ai-export-only, validate-pipeline, generate-report) που είναι ΟΛΑ αποσυρμένα tombstones και σφάλλουν με retired-entrypoint."
   :severity :p1
   :evidence "systems/orchestrator-cli/package.lisp:L9-L16 · systems/orchestrator-cli/commands.lisp:L26-L67"
   :is-it-in-the-known-defect-list :yes)

  (:what "suite.lisp: οι run-orchestrator-tests (L32-L63) και run-all-tests (L69-L98) έχουν ΤΑΥΤΟΣΗΜΑ σώματα — διπλή έδρα εκτέλεσης της σουίτας μέσα στο ΙΔΙΟ αρχείο· επιπλέον το (export …) στο L100 εξάγει σύμβολο εκτός defpackage."
   :severity :p1
   :evidence "systems/orchestrator-tests/suite.lisp:L32-L100 · systems/orchestrator-tests/package.lisp:L6-L13"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Τέσσερις «reproducibility/determinism» δοκιμές που είναι ταυτολογίες: hash-reproducibility καλεί δύο φορές την ΙΔΙΑ συνάρτηση στην ΙΔΙΑ εικόνα· deterministic-manifest-reproducibility, deterministic-provenance-hash και integration-deterministic-build κάνουν το ίδιο με σταθερό timestamp override. Καμία δεν διασχίζει όριο διεργασίας/μηχανής, άρα δεν μπορεί να πιάσει τη μη-αναπαραγωγιμότητα που ονομάζει. Ο ίδιος τύπος ταυτολογίας ζει και μέσα στην --golden-gate (έλεγχος ⑤)."
   :severity :p1
   :evidence "systems/orchestrator-tests/reproducibility/hash-stability-test.lisp:L8-L13 · systems/orchestrator-tests/unit/test-ai-core.lisp:L417-L439,L441-L452 · systems/orchestrator-tests/integration/ai-export-integration-test.lisp:L192-L215 · systems/orchestrator-cli/golden-gate.lisp:L88-L98"
   :is-it-in-the-known-defect-list :unknown)

  (:what "%cockpit-host-ok-p: ο κλάδος COCKPIT_ALLOWED_HOSTS βραχυκυκλώνει ΠΡΙΝ από την απαίτηση token — δημόσιο bind με allowlist και ΧΩΡΙΣ LAWMAX_CREATOR_TOKEN περνά τον host-guard, και μετά ο έλεγχος key επιστρέφει T για όλους."
   :severity :p1
   :evidence "systems/orchestrator-cli/cockpit.lisp:L228-L244,L252-L268 · systems/orchestrator-cli/cli-util.lisp:L192-L199"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Λήψη τροποποιητικών νόμων: το προσωρινό αρχείο είναι /tmp/amend-<num>-<random>.pdf όπου το <num> προέρχεται ΑΠΕΥΘΕΙΑΣ από απομακρυσμένα δεδομένα (πεδίο «number» του fetched item) χωρίς κανένα φιλτράρισμα διαδρομής, και το (random 100000) χωρίς seed είναι ντετερμινιστικό ανά εικόνα ⇒ προβλέψιμο όνομα, χωρίς αποκλειστική δημιουργία."
   :severity :p1
   :evidence "systems/orchestrator-cli/ingestion-commands.lisp:L442-L465"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Η αγκύρωση σε blockchain δεν είναι πύλη: *anchor-require-at-least-one* = NIL ⇒ το στάδιο ολοκληρώνεται με ΜΗΔΕΝ επιτυχείς αλυσίδες και ο deploy συνεχίζει με blockchain-anchor «pending». Επιπλέον γράφεται (:anchor-timestamp . (get-universal-time)) — ρολόι συστήματος μέσα σε build που αλλού απαιτεί require-deterministic-time."
   :severity :p1
   :evidence "systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp:L23-L27,L62-L91 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L976"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Το engine stage γράφει στο context :epistemic-attested ← (getf result :attested) και :epistemic-latest ← (getf result :latest-symlink)· ο εσωτερικός deploy-epistemic-stage ΔΕΝ επιστρέφει κανένα από τα δύο κλειδιά ⇒ και τα δύο είναι ΠΑΝΤΑ NIL. Το --cut-release τυπώνει «ATTESTED» από αυτή τη NIL τιμή· η άγνοια («δεν ξέρω») δεν διακρίνεται από την άρνηση («όχι»)."
   :severity :p1
   :evidence "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L108-L118,L124 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L1121-L1127 · systems/orchestrator-cli/release-authority.lisp:L142-L148"
   :is-it-in-the-known-defect-list :unknown)

  (:what "record-generation-event / record-error-event είναι μόνιμα no-op stubs: κάθε frbr-generation-error που «καταγράφεται στις μετρικές» εξαφανίζεται σιωπηλά. Το αρχείο ορίζει και ΕΞΑΓΕΙ σύμβολα στο πακέτο orchestrator.meta από άλλο ASDF system."
   :severity :p1
   :evidence "systems/orchestrator-omega-modules/metrics-stub.lisp:L5-L20 · systems/orchestrator-omega-modules/frbr-conditions.lisp:L166-L176"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Ο νόμος ΜΙΑΣ ΕΔΡΑΣ επιβάλλεται μόνο για εντολές: register-pipeline / register-corpus / register-backend είναι σκέτο (setf gethash) — σιωπηλή αντικατάσταση καταχωρισμένου pipeline/corpus/backend είναι δυνατή χωρίς καμία σύγκρουση."
   :severity :p1
   :evidence "systems/orchestrator-meta/registry.lisp:L23-L54 · αντιπαράδειγμα: systems/orchestrator-cli/cli-util.lisp:L46-L64"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Τρεις έδρες έκδοσης που ΔΕΝ συμφωνούν: orchestrator.spec:+system-version+ = «1.2.0», cli:*version* = «1.2.0», orchestrator.meta:capture-tool-versions :orchestrator-version = «2.0.0». Το +pipeline-version+ είναι τέταρτο, χειροκίνητο αντίγραφο του «1.2.0» αντί για alias."
   :severity :p2
   :evidence "systems/orchestrator-spec/version.lisp:L15-L23 · systems/orchestrator-cli/main.lisp:L6 · systems/orchestrator-meta/tool-versions.lisp:L11-L16"
   :is-it-in-the-known-defect-list :unknown)

  (:what "detect-executor-mode γυρίζει σε :interactive όχι μόνο με ρητό ORCHESTRATOR_MODE αλλά και από ΠΑΡΟΥΣΙΑ πακέτου swank/slynk στην εικόνα — οπότε σε production εικόνα με φορτωμένο SLIME ενεργοποιούνται τα restarts skip-article / mark-degraded-and-continue χωρίς καμία εντολή. Επιπλέον σε :production γίνονται έως 3 σιωπηλές επαναλήψεις σταδίου (μη ιδεμποτεντ στάδια)."
   :severity :p2
   :evidence "systems/orchestrator-core/executor.lisp:L10-L32,L104-L129,L172-L204"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Στο %intake-one η αποτυχία εύρεσης ταυτότητας (ούτε κείμενο ούτε όνομα) ΔΕΝ γράφει %lesson — μόνο τυπώνει· η αντίστοιχη αποτυχία δικαστηρίου γράφει. Ασύμμετρη καταγραφή κενών στην ίδια συνάρτηση."
   :severity :p2
   :evidence "systems/orchestrator-cli/decisions.lisp:L186-L191,L205-L208"
   :is-it-in-the-known-defect-list :unknown)

  (:what "emit-candidate-bundle!: (unless (probe-file marker) (with-open-file … :if-exists :error)) — TOCTOU· και αν ο δείκτης προϋπάρχει με ΞΕΝΟ περιεχόμενο δεν επαληθεύεται καθόλου, σε αντίθεση με το atomic-publish-release που επαναϋπολογίζει το root."
   :severity :p2
   :evidence "systems/orchestrator-epistemic/authority-boundary.lisp:L82-L95 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L838-L851"
   :is-it-in-the-known-defect-list :unknown)

  (:what "%write-cursor τυλίγει την ατομική εγγραφή σε (ignore-errors …): αποτυχία διατήρησης του cursor εξαφανίζεται και η επόμενη εκτέλεση ξαναρχίζει από την ίδια θέση χωρίς καμία ένδειξη."
   :severity :p2
   :evidence "systems/orchestrator-cli/cli-util.lisp:L238-L244"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Οι δοκιμές γράφουν και ΔΙΑΓΡΑΦΟΥΝ ΔΕΝΔΡΑ σε σταθερά απόλυτα μονοπάτια (/tmp/orchestrator-test-ai/, /tmp/orchestrator-integration-test/, /tmp/orchestrator-test/) — σύγκρουση μεταξύ παράλληλων εκτελέσεων στον ίδιο host και έκθεση σε προϋπάρχον /tmp περιεχόμενο."
   :severity :p2
   :evidence "systems/orchestrator-tests/unit/test-ai-core.lisp:L13,L51-L54 · systems/orchestrator-tests/integration/ai-export-integration-test.lisp:L15-L16 · systems/orchestrator-tests/fixtures/mock-data.lisp:L6-L9"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Δεκάδες προσωρινά αρχεία πυλών ονομάζονται (format nil \"…-~D.sexp\" (get-universal-time)) μέσα στο uiop:temporary-directory — προβλέψιμα ονόματα σε κοινό κατάλογο, χωρίς αποκλειστική δημιουργία· ίδιο μοτίβο και στο /tmp/lawmax-ocr-<universal-time>/ της έδρας OCR."
   :severity :p2
   :evidence "systems/orchestrator-cli/self-extension.lisp:L104,L160,L248,L507-L509 · systems/orchestrator-cli/generation-gate.lisp:L67 · systems/orchestrator-cli/inference-gate.lisp:L400 · systems/orchestrator-cli/memory-commands.lisp:L110 · systems/orchestrator-cli/approval-policy.lisp:L202-L204 · systems/orchestrator-cli/advisor.lisp:L266-L269,L314-L315 · source/pdf-authority.lisp:L1405"
   :is-it-in-the-known-defect-list :unknown)

  (:what "generate-trace-id χρησιμοποιεί (get-universal-time) + (random 100000) — δεύτερη έδρα χρόνου/τυχαιότητας εκτός orchestrator.time, μέσα στο μονοπάτι parsing του gr-syntagma· άλλα 5 σημεία του ίδιου αρχείου καλούν κατευθείαν get-universal-time."
   :severity :p2
   :evidence "systems/orchestrator-gr-syntagma/parsing.lisp:L132-L144,L193,L232,L242,L251,L1045"
   :is-it-in-the-known-defect-list :unknown)

  (:what "orchestrator.meta:generate-json-report περνά PLIST στο (jonathan:to-json … :from :alist) — λάθος κωδικοποιητής για τη δομή που δίνεται. Είναι η συνάρτηση που το tombstone cli::generate-report ονομάζει ως canonical entrypoint, με ΑΛΛΗ υπογραφή (pipeline context έναντι pipeline-name output-path)."
   :severity :p2
   :evidence "systems/orchestrator-meta/reports.lisp:L6-L19 · systems/orchestrator-cli/commands.lisp:L62-L67"
   :is-it-in-the-known-defect-list :unknown))

 :hidden-execution-paths
 ((:path "Παράκαμψη υπογραφής release μέσω μεταβλητής περιβάλλοντος"
   :trigger "ORCHESTRATOR_DEV_MODE=1|true|yes"
   :why-hidden "Δεν εμφανίζεται σε κανένα CLI flag, σε κανένα artifact του release, και το τελικό μήνυμα εξακολουθεί να λέει ALL PROOF GATES PASSED."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L255-L258,L519-L522,L529,L1199-L1201")

  (:path "Γένεση trust root κατά τη διάρκεια build"
   :trigger "LAWMAX_ALLOW_KEY_GENESIS=1|true|yes|ΝΑΙ και απόν private.pem"
   :why-hidden "Παράγει RSA-4096 + self-signed X.509 100 ετών μέσα στο deploy stage· η προειδοποίηση ζει μόνο σε stdout και δεν αποτυπώνεται στο release."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L348-L414")

  (:path "Unsigned proofs ΚΑΙ proofs χωρίς αγκύρωση στην πρωτογενή πηγή"
   :trigger "ORCHESTRATOR_ALLOW_DEGRADED_PROOFS=1"
   :why-hidden "ΕΝΑ flag απενεργοποιεί ΔΥΟ διαφορετικές εγγυήσεις σε δύο διαφορετικές συναρτήσεις (υπογραφή root· anchor-assert της παραγώγησης)."
   :evidence "systems/orchestrator-cli/main.lisp:L1834-L1836,L1887-L1892")

  (:path "Προώθηση μη επαληθευμένου source.json ως authoritative corpus"
   :trigger "ORCHESTRATOR_ALLOW_UNVERIFIED_JSON (getenvp — αρκεί η ΥΠΑΡΞΗ της μεταβλητής, οποιαδήποτε τιμή)"
   :why-hidden "Χρησιμοποιεί getenvp, όχι σύγκριση τιμής· δεν εμφανίζεται στη λίστα getenv «…»· επιτρέπει :unstamped ΚΑΙ :tampered."
   :evidence "systems/orchestrator-cli/main.lisp:L267-L284")

  (:path "Συρρίκνωση corpus χωρίς φραγή"
   :trigger "ORCHESTRATOR_ALLOW_SHRINK (getenvp)"
   :why-hidden "Απενεργοποιεί τη βάση SHRINK που εμποδίζει μερική/σκουπίδια εξαγωγή να αντικαταστήσει μεγάλο, καλό corpus."
   :evidence "systems/orchestrator-cli/main.lisp:L1187 · %source-json-count L1034-L1041")

  (:path "Ολομέλεια πυλών εκτός συντάγματος"
   :trigger "--gates (και έμμεσα --auto-update)"
   :why-hidden "Οι 25 πύλες καλούνται απευθείας από το *commands* hash-table· ο χρήστης βλέπει «ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ» αλλά καμία δεν πέρασε από το execute-command."
   :evidence "systems/orchestrator-cli/gates-runner.lisp:L28-L37")

  (:path "Εκτέλεση εντολών μητρώου από δημόσιο HTTP"
   :trigger "GET /cmd?name=--auto-update (ή --failures) στη θύρα του serve-corpus (0.0.0.0:$PORT, default 8080)"
   :why-hidden "Παρακάμπτει resolve-command + σύνταγμα· χωρίς LAWMAX_CREATOR_TOKEN κάθε πελάτης περνά τον έλεγχο ταυτότητας· καμία Host/CSRF φραγή."
   :evidence "systems/orchestrator-cli/main.lisp:L784-L789,L825-L850,L911")

  (:path "Συνταγματική παράκαμψη μέσω περιβάλλοντος"
   :trigger "LAWMAX_OVERRIDE=<όνομα-εντολής> + LAWMAX_OVERRIDE_REASON=…, ή --force + LAWMAX_OVERRIDE_REASON"
   :why-hidden "Δεν είναι εγγεγραμμένη εντολή· η οδηγία εμφανίζεται μόνο μέσα στο κείμενο της άρνησης· η καταγραφή στη βιογραφία μπορεί να αποτύχει σιωπηλά (ignore-errors)."
   :evidence "systems/orchestrator-cli/constitutional-dispatch.lisp:L37-L47,L71-L74")

  (:path "Αποστολή της ερώτησης του χρήστη σε εξωτερικό LLM endpoint"
   :trigger "LAWMAX_ADVISOR_URL ορισμένο ΚΑΙ κανένας συμβολικός ταξινομητής δεν πιάνει την είσοδο"
   :why-hidden "Δεν υπάρχει flag γραμμής εντολών· ενεργοποιείται σιωπηλά στο install-advisor!· η ίδια η νομική ερώτηση φεύγει αυτούσια στο δίκτυο· καμία ρητή ρύθμιση επαλήθευσης TLS· η μόνη ένδειξη είναι το --advisor status."
   :evidence "systems/orchestrator-cli/advisor.lisp:L154-L198,L200-L213")

  (:path "Αυτόνομη εγγραφή LLM-προτεινόμενης γνώσης χωρίς πράξη δημιουργού"
   :trigger "Ενεργή πολιτική :dream-frame + κύκλος δαίμονα (--evolve) + συνδεδεμένος advisor"
   :why-hidden "Η έγκριση γίνεται μέσα στο dream-grammar μέσω (ignore-errors (%maybe-auto-approve id :dream-frame)) — αν αποτύχει, ούτε αυτό φαίνεται."
   :evidence "systems/orchestrator-cli/self-extension.lisp:L436,L465-L490 · systems/orchestrator-cli/approval-policy.lisp:L115-L121")

  (:path "Ανακατεύθυνση/επανακλείδωμα των golden αποτυπωμάτων"
   :trigger "GOLDEN_DIR=<κατάλογος>· GOLDEN_WRITE=1 στο --verify-corpus"
   :why-hidden "Ο ratchet συγκρίνει ΚΑΙ «αποδεικνύει read-only» πάνω σε ΟΠΟΙΟΝ κατάλογο δείχνει το env· η ίδια ανάλυση μονοπατιού είναι γραμμένη δύο φορές σε δύο αρχεία."
   :evidence "systems/orchestrator-cli/golden-gate.lisp:L48-L57,L99-L107 · systems/orchestrator-cli/main.lisp:L1588-L1598,L1611-L1616")

  (:path "Παράλειψη ολομέλειας πυλών στον «πλήρη κύκλο»"
   :trigger "AUTO_UPDATE_GATES=0 (και AUTO_UPDATE_FETCH=0, AUTO_UPDATE_PUBLISH=1)"
   :why-hidden "Τυπώνεται «[7/7] Πύλες: ΠΑΡΑΛΕΙΦΘΗΚΑΝ» αλλά η τελική ετυμηγορία μπορεί να είναι rc=0 («όλα καθαρά») χωρίς καμία πύλη να έχει τρέξει."
   :evidence "systems/orchestrator-cli/main.lisp:L1311-L1313,L1351-L1368")

  (:path "Ανακατεύθυνση ιδιωτικού κλειδιού / certificate μέσω env"
   :trigger "PRIVATE_KEY_PATH / RELEASE_CERT_PATH (φιλτράρονται ΜΟΝΟ για \"..\" και \"~\")"
   :why-hidden "Απόλυτο μονοπάτι εκτός institution γίνεται δεκτό — ο έλεγχος δεν είναι containment check."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L430-L442")

  (:path "Αλλαγή προφίλ ιχνών που καθορίζει αν επιτρέπεται έμπιστη legal-critical έξοδος"
   :trigger "ORCHESTRATOR_TRACE_PROFILE=off|minimal|legal-critical|full-debug"
   :why-hidden "Καθορίζει το require-provenance-or-untrusted κάθε legal-critical πύλης· άγνωστη τιμή αγνοείται με προειδοποίηση στο stderr και κρατιέται η προηγούμενη."
   :evidence "systems/orchestrator-cli/main.lisp:L2500-L2516 · systems/orchestrator-cli/cli-util.lisp:L251-L260")

  (:path "Ενεργοποίηση restarts σε παραγωγή από την ΠΑΡΟΥΣΙΑ πακέτου"
   :trigger "ORCHESTRATOR_MODE=interactive Ή απλή ύπαρξη πακέτου swank/slynk στην εικόνα"
   :why-hidden "Δεν είναι εντολή ούτε ρύθμιση — είναι ιδιότητα του image· ενεργοποιεί skip-article / mark-degraded-and-continue σε αποτυχία σταδίου."
   :evidence "systems/orchestrator-core/executor.lisp:L19-L32,L111-L129")

  (:path "Ανακατεύθυνση του καταλόγου μόνιμης κατάστασης"
   :trigger "STATE_DIR (και FEK_STATE_FILE για τον legacy cursor)"
   :why-hidden "Μετακινεί lessons.jsonl και όλους τους cursors έξω από το bind-mounted deployment/state/ — η μνήμη αναστοχασμού αλλάζει ταυτότητα σιωπηλά."
   :evidence "systems/orchestrator-cli/cli-util.lisp:L213-L228")

  (:path "Ταυτότητα απόφασης από το ΟΝΟΜΑ ΑΡΧΕΙΟΥ όταν το OCR δεν διαβάζει τον σφραγισμένο αριθμό"
   :trigger "Απουσία regex «Αριθμός N/ΕΕΕΕ» στο κείμενο και ύπαρξη «N_ΕΕΕΕ» στο filename"
   :why-hidden "Δεύτερη, ασθενέστερη πηγή αλήθειας· τυπώνεται με ◌ αλλά δεν αποτυπώνεται σε καμία μόνιμη κατάσταση — το αρχειοθετημένο έγγραφο δεν φέρει καμία ένδειξη ότι η ταυτότητά του προήλθε από το όνομα."
   :evidence "systems/orchestrator-cli/decisions.lisp:L192-L204"))

 :duplicate-seats
 ((:concept "ορισμός του πακέτου orchestrator.spec"
   :seats ("systems/orchestrator-spec/ (7 αρχεία: escaping version pipeline-dsl types introspection conditions protocols)"
           "systems/orchestrator-omega-modules/frbr-protocol.lisp:L5"
           "systems/orchestrator-omega-modules/frbr-conditions.lisp:L5"
           "systems/orchestrator-omega-modules/frbr-consistency-validator.lisp:L17"
           "systems/orchestrator-omega-modules/rdf-canonicalization.lisp:L20"
           "systems/orchestrator-omega-modules/article-root-generator-omega.lisp:L19"
           "systems/orchestrator-omega-modules/prov-activity-generator-omega.lisp:L14"
           "systems/orchestrator-omega-modules/corpus-root-generator.lisp:L7"
           "systems/orchestrator-omega-modules/hybrid-generator-phase1.lisp:L13"
           "systems/orchestrator-omega-modules/unified-frbr-generator.lisp:L22"
           "systems/orchestrator-omega-modules/config-accessor.lisp:L11"
           "systems/orchestrator-omega-modules/html-rdfa-generator.lisp:L12"))

  (:concept "ορισμός του πακέτου orchestrator.model"
   :seats ("systems/orchestrator-model/ (7 αρχεία)"
           "systems/orchestrator-omega-modules/frbr-classes.lisp:L5"
           "systems/orchestrator-omega-modules/frbr-article-root.lisp:L21"
           "systems/orchestrator-omega-modules/greek-law-types.lisp:L22"
           "systems/orchestrator-omega-modules/prov-activity.lisp:L19"))

  (:concept "ορισμός/εξαγωγή στο πακέτο orchestrator.meta"
   :seats ("systems/orchestrator-meta/ (6 αρχεία)"
           "systems/orchestrator-omega-modules/metrics-stub.lisp:L5-L8 (in-package + export από άλλο system)"))

  (:concept "παράκαμψη της δρομολόγησης μέσω απευθείας κλήσης χειριστή εντολής"
   :seats ("systems/orchestrator-cli/main.lisp:L2537 (execute-command — η ΔΗΛΩΜΕΝΗ ΜΙΑ έδρα)"
           "systems/orchestrator-cli/gates-runner.lisp:L29 (funcall (gethash name *commands*) nil)"
           "systems/orchestrator-cli/main.lisp:L846 (funcall (find-command name) nil)"))

  (:concept "υλική πύλη release (validate-epistemic-stage) — ΔΥΟ κλήσεις, ΔΙΑΦΟΡΕΤΙΚΗ επιβολή"
   :seats ("systems/orchestrator-epistemic/deploy-epistemic.lisp:L1097 (error)"
           "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L157 (log:warn)"))

  (:concept "συνάρτηση με όνομα deploy-epistemic-stage σε δύο πακέτα και δύο ομώνυμα αρχεία"
   :seats ("systems/orchestrator-epistemic/deploy-epistemic.lisp:L974 (articles base-output-dir &key)"
           "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L30 (context)"))

  (:concept "εγγραφή NDJSON AI manifest (δύο βρόχοι εγγραφής, ΔΙΑΦΟΡΕΤΙΚΗ σημασιολογία αποτυχίας)"
   :seats ("systems/orchestrator-ai-core/ingest-manifest.lisp:L109-L155 (με restart-case skip-article/abort-manifest)"
           "systems/orchestrator-ai-core/config.lisp:L286-L325 (χωρίς restarts)"))

  (:concept "παραγωγή manifest entry / corpus provenance (ζεύγη «…-with-config»)"
   :seats ("systems/orchestrator-ai-core/ingest-manifest.lisp:L36 generate-article-manifest-entry"
           "systems/orchestrator-ai-core/config.lisp:L219 generate-article-manifest-entry-with-config (ΔΗΛΩΜΕΝΑ delegating)"
           "systems/orchestrator-ai-core/provenance-model.lisp:L288 write-corpus-provenance"
           "systems/orchestrator-ai-core/config.lisp:L326 write-corpus-provenance-with-config"))

  (:concept "εκτέλεση της σουίτας δοκιμών (ταυτόσημα σώματα στο ίδιο αρχείο)"
   :seats ("systems/orchestrator-tests/suite.lisp:L32 run-orchestrator-tests"
           "systems/orchestrator-tests/suite.lisp:L69 run-all-tests"))

  (:concept "απόδειξη ντετερμινισμού μέσα στην ίδια εικόνα (ταυτολογία σε 4 σημεία)"
   :seats ("systems/orchestrator-tests/reproducibility/hash-stability-test.lisp:L8"
           "systems/orchestrator-tests/unit/test-ai-core.lisp:L417"
           "systems/orchestrator-tests/unit/test-ai-core.lisp:L441"
           "systems/orchestrator-tests/integration/ai-export-integration-test.lisp:L192"
           "systems/orchestrator-cli/golden-gate.lisp:L88-L98"))

  (:concept "HTTP επιφάνεια δημιουργού με ΑΣΥΜΜΕΤΡΕΣ φραγές γύρω από την ΙΔΙΑ έδρα ταυτότητας"
   :seats ("systems/orchestrator-cli/cockpit.lisp:L258-L268 (Host allowlist + CSRF header + key)"
           "systems/orchestrator-cli/main.lisp:L803-L824 (/ask — μόνο key)"
           "systems/orchestrator-cli/main.lisp:L825-L850 (/cmd — μόνο key + whitelist)"))

  (:concept "ανάγνωση κειμένου PDF"
   :seats ("systems/orchestrator-cli/decisions.lisp:L173,L1072,L1248 (extract-text-any)"
           "systems/orchestrator-cli/main.lisp:L174,L2341 (extract-text-from-pdf)"
           "systems/orchestrator-cli/ingestion-commands.lisp:L294,L431 (find-symbol EXTRACT-TEXT-FROM-PDF)"
           "systems/orchestrator-engine-sbcl/adapters/pdf-adapter.lisp:L2144"))

  (:concept "διαθεσιμότητα OCR — τρεις ανεξάρτητοι έλεγχοι, δύο εκτός συστάδας"
   :seats ("source/pdf-authority.lisp:L1386 (ocr-available-p — η έδρα)"
           "source/pdf-authority.lisp:L1403 (extract-text-via-ocr, εσωτερικός επανέλεγχος)"
           "systems/orchestrator-cli/decisions.lisp:L181 (τρίτος επανέλεγχος, ΜΟΝΟ για τη διατύπωση μηνύματος)"))

  (:concept "ανάλυση μονοπατιού golden (GOLDEN_DIR/ORCHESTRATOR_ROOT) — δύο αντίγραφα που πρέπει να μένουν σε συγχρονισμό"
   :seats ("systems/orchestrator-cli/golden-gate.lisp:L52-L55" "systems/orchestrator-cli/main.lisp:L1593-L1597"))

  (:concept "βοηθός %non-blank"
   :seats ("systems/orchestrator-cli/cli-util.lisp:L188-L190" "systems/orchestrator-core/source-detection.lisp:L41-L47"))

  (:concept "καταγραφή σε log μέσα στο ΙΔΙΟ πακέτο orchestrator.cli"
   :seats ("systems/orchestrator-cli/log.lisp:L6-L15 (log-info/log-warn/log-error μακροεντολές)"
           "systems/orchestrator-cli/package.lisp:L8 (local-nickname log → orchestrator.logging, χρήση log:info/log:warn)"))

  (:concept "ανάγνωση YAML διαμόρφωσης"
   :seats ("systems/orchestrator-cli/config-loader.lisp:L6 (load-config, cl-yaml:parse)"
           "systems/orchestrator-cli/decisions.lisp:L224-L229 (%decision-fetch-template, cl-yaml:parse)"
           "systems/orchestrator-ai-core/config.lisp:L193 (load-ai-config-from-yaml)"
           "systems/orchestrator-cli/release-authority.lisp:L99 (orchestrator.spec:ensure-config-loaded)"))

  (:concept "έκδοση συστήματος"
   :seats ("systems/orchestrator-spec/version.lisp:L15 (+system-version+ «1.2.0»)"
           "systems/orchestrator-spec/version.lisp:L18 (+pipeline-version+ «1.2.0» — χειροκίνητο αντίγραφο, όχι alias)"
           "systems/orchestrator-cli/main.lisp:L6 (*version* «1.2.0»)"
           "systems/orchestrator-meta/tool-versions.lisp:L15 (:orchestrator-version «2.0.0» — ΔΙΑΦΩΝΕΙ)"))

  (:concept "χρόνος"
   :seats ("orchestrator.time:require-deterministic-time (η δηλωμένη έδρα — systems/orchestrator-epistemic/deploy-epistemic.lisp:L975)"
           "systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp:L91 (get-universal-time)"
           "systems/orchestrator-gr-syntagma/parsing.lisp:L138,L193,L232,L242,L251,L1045"
           "systems/orchestrator-cli/main.lisp:L769 (session TTL)"
           "systems/orchestrator-cli/cli-util.lisp:L172-L173,L205 (turn nonce, τρέχον έτος)")))

 :unknowns
 ("ΕΙΔΙΚΗ ΤΕΚΜΗΡΙΩΣΗ — systems/orchestrator-cli/decisions.lisp:L181 (orchestrator.pdf-authority:ocr-available-p) — ΠΛΗΡΗΣ ΑΠΑΝΤΗΣΗ, ΟΧΙ unknown:
   (α) ΠΟΙΑ ΑΠΟΦΑΣΗ ΕΞΑΡΤΑΤΑΙ: ΚΑΜΙΑ. Η κλήση εμφανίζεται ΑΠΟΚΛΕΙΣΤΙΚΑ ως το boolean
   όρισμα ενός format directive ~:[…~;…~] μέσα στο (format t …) των γραμμών L178-L181.
   Η ροή ελέγχου είναι ΤΑΥΤΟΣΗΜΗ και για T και για NIL: η συνθήκη που αποφασίζει είναι
   αποκλειστικά (< (length text) 600) στο L178· ό,τι κι αν επιστρέψει το ocr-available-p,
   εκτελούνται πάντα τα ΙΔΙΑ (%lesson :needs-ocr …) και (return-from %intake-one).
   Το αρχείο ΔΕΝ αρχειοθετείται σε καμία περίπτωση.
   (β) ΤΙ ΔΗΛΩΝΕΤΑΙ ΠΡΟΣ ΤΑ ΕΞΩ ΟΤΑΝ ΕΙΝΑΙ NIL: στο stdout τυπώνεται
   «⚠ <αρχείο>: σαρωμένο PDF (<N> χαρακτήρες) και το OCR λείπει (tesseract+ell) —
   παραμένει προς χειροκίνητη εξέταση». Όταν είναι non-NIL, η ΙΔΙΑ γραμμή λέει
   «…και το OCR δεν απέδωσε…». Η διάκριση αιτίας υπάρχει ΜΟΝΟ σε αυτό το ελεύθερο κείμενο.
   (γ) ΔΙΑΔΙΔΕΤΑΙ ΤΙΜΙΑ Η ΑΓΝΟΙΑ; ΜΕΡΙΚΩΣ — και η διάκριση ΕΞΑΦΑΝΙΖΕΤΑΙ σε τρία επίπεδα:
     1. Το %lesson γράφει (kind=:needs-ocr, subject=<filename>, detail=<αριθμός χαρακτήρων>).
        Η τιμή του ocr-available-p ΔΕΝ αποθηκεύεται πουθενά. Άρα στο lessons.jsonl —
        τη ΜΟΝΗ μηχανικά αναγνώσιμη μνήμη — «λείπει το εργαλείο» και «το εργαλείο απέτυχε»
        είναι ΤΟ ΙΔΙΟ γεγονός. Το --lessons και ο run-reflect δεν μπορούν να τα ξεχωρίσουν,
        άρα η οδηγία «ΕΠΑΝΑΛΑΜΒΑΝΟΜΕΝΟ — διόρθωσε στην ρίζα» δεν μπορεί να δείξει τη ρίζα.
     2. Το %lesson είναι ΟΛΟΚΛΗΡΟ σε (ignore-errors …): αν η εγγραφή αποτύχει, το κενό
        χάνεται ΚΑΙ το *gap-created-this-turn* μένει NIL ⇒ το envelope του γύρου δηλώνει
        gap_created ψευδώς αρνητικό. Τότε η άγνοια δεν διαδίδεται ΚΑΘΟΛΟΥ.
     3. Το ocr-available-p ΕΠΑΝΑ-ΑΝΙΧΝΕΥΕΙ (νέα which/tesseract --list-langs) τη στιγμή
        της ΜΟΡΦΟΠΟΙΗΣΗΣ ΤΟΥ ΜΗΝΥΜΑΤΟΣ, ενώ η ΠΡΑΓΜΑΤΙΚΗ αλήθεια της συγκεκριμένης
        προσπάθειας υπάρχει ήδη στη μεταβλητή SOURCE που επέστρεψε το extract-text-any
        (L172-L173): σε αυτόν τον κλάδο η SOURCE είναι ΠΑΝΤΑ :none (γιατί το
        extract-text-any επιστρέφει :ocr μόνο όταν το OCR απέδωσε ≥600 χαρακτήρες).
        Η SOURCE ΑΓΝΟΕΙΤΑΙ και η αιτία ΜΑΝΤΕΥΕΤΑΙ εκ νέου — δεύτερη, ανεξάρτητη και
        χρονικά μετατοπισμένη μέτρηση (TOCTOU) της ίδιας ιδιότητας.
   ΣΥΝΟΨΗ: η άγνοια δηλώνεται τίμια ΣΤΟΝ ΑΝΘΡΩΠΟ που κοιτά την κονσόλα εκείνη τη στιγμή,
   και εξαφανίζεται εντελώς για κάθε μηχανικό καταναλωτή. Καμία σιωπηλή ΑΠΟΔΟΧΗ του
   εγγράφου δεν συμβαίνει (αυτό είναι σωστό)· αυτό που χάνεται είναι η ΑΙΤΙΑ."

  "ΔΕΝ διάβασα γραμμή-προς-γραμμή 87 από τα 175 αρχεία. Ονομαστικά τα σημαντικότερα αδιάβαστα: orchestrator-cli/{understanding-learning cognition-legal cognition-self version-graph-import inference-gate evolution-gate architecture-gate subsumption-commands draft-commands verify-truth-gate graph-import dialogue-gate provenance-gate component-gate content-validation legal-eval contract-gate iq-gate memory-commands autonomy-missions jurisprudence-judge fluid-gate case-workspace deontic-gate event-gate generation-gate external-benchmark-gate}.lisp· orchestrator-engine-sbcl/adapters/{pdf-adapter raw-text-adapter html-parliament-adapter docx-adapter json-adapter errata-boundary}.lisp και stages/{parse-pdf generate-rdf source-normalize parse-raw-text consolidate deploy load-json-source validate-shacl hash-artifacts test-escaping}.lisp και backends/{ethereum arweave ipfs}.lisp και templates/rendering.lisp· orchestrator-omega-modules (22 γεννήτριες — μόνο κεφαλίδες)· orchestrator-gr-syntagma/{corpus historical structure validation pipeline package}.lisp και το μεγαλύτερο μέρος του parsing.lisp· orchestrator-model (8)· orchestrator-spec/{types introspection pipeline-dsl escaping}.lisp· orchestrator-core/{context dependency-graph instrumentation parallel-executor artifact-cache}.lisp· orchestrator-epistemic/{meta-ontology negation-layer stability-policy shacl-shapes vocabularies lineage-authority primary-anchor release-manifest}.lisp και τα δύο shapes/*.ttl."

  "Ο admission kernel της authority-v2, το OS-enforced όριο (ξεχωριστό uid + read-only bind mount, EROFS) και τα capture/quarantine πρωτόκολλα είναι ΕΚΤΟΣ της συστάδας (authority-v2/). Η συστάδα systems/ τα ΔΗΛΩΝΕΙ αλλά δεν τα καλεί και δεν τα επαληθεύει. Δεν μπορώ να κρίνω αν το δηλωμένο όριο υπάρχει πραγματικά."

  "Το orchestrator.constitution:evaluate και overridden-p (τι ακριβώς μπλοκάρεται και με ποια κριτήρια) ζουν εκτός συστάδας — δεν μπορώ να κρίνω πόσο περιοριστικός είναι ο συνταγματικός φραγμός στην πράξη."

  "Δεν μπόρεσα να κρίνω αν το ORCHESTRATOR_DEV_MODE, το ORCHESTRATOR_ALLOW_DEGRADED_PROOFS ή το ORCHESTRATOR_ALLOW_UNVERIFIED_JSON απαγορεύονται από κάποιο CI/Dockerfile gate εκτός συστάδας."

  "Δεν μπόρεσα να κρίνω αν η drakma:http-request του advisor επαληθεύει TLS: δεν δίνεται ρητή παράμετρος και η προεπιλογή της βιβλιοθήκης δεν ελέγχεται από αυτή τη συστάδα."

  "Δεν βρήκα «λίστα γνωστών ελαττωμάτων» μέσα στη συστάδα, οπότε το :is-it-in-the-known-defect-list είναι :unknown σχεδόν παντού· εξαιρέσεις: το tombstone σχόλιο [0115] (:yes για τα 5 αποσυρμένα entrypoints) και το :no για το release-attested-p, όπου το level7-disarm-test τεκμηριώνει την κατάργηση ΧΩΡΙΣ να αναφέρει τον σπασμένο καταναλωτή."

  "Η ΠΕΡΙΓΡΑΦΗ ΤΗΣ ΣΥΣΤΑΔΑΣ ΗΤΑΝ ΑΝΑΚΡΙΒΗΣ: δεν υπάρχει systems/orchestrator-infrastructure/. Το orchestrator-infrastructure.asd ζει στη ρίζα και τα components του δηλώνονται στο module «source» — εκτός systems/. Δεν το εξέτασα."))
