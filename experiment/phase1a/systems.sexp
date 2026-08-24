(:lawmax-phase1a-cluster/1
 :cluster "systems"
 :status :partial
 :files-read 48

 :capabilities
 ((:name "transparency-log (RFC 6962) — ΜΟΝΟ ΑΝΑΓΝΩΣΗ/ΕΠΑΛΗΘΕΥΣΗ"
   :presence :present
   :domain "releases/transparency-log.json ενός corpus: entries (release roots), log_root, checkpoints."
   :assumptions "Το αρχείο υπάρχει στο δίσκο και είναι version=\"tlog-1\"· τα Merkle μαθηματικά ζουν στο orchestrator.merkle."
   :guarantees "tlog-verify: (α) log_root ≡ MTH(entries)· (β) κάθε αποθηκευμένο checkpoint {size m, root} επαληθεύεται με consistency-proof RFC6962 §2.1.2. Αποτυχία ⇒ validation-error."
   :failure-semantics "fail-closed (error). Απόν αρχείο ⇒ (values :absent nil) — ρητά τίμιο, ο καλών αποφασίζει."
   :operating-model "Ο ΜΗΧΑΝΙΣΜΟΣ ΕΓΓΡΑΦΗΣ ΔΕΝ ΥΠΑΡΧΕΙ πλέον σε κανένα ASDF system (σχόλιο [Δ2])· tlog-append-root! σφάλλει πάντα με legacy-authority-seat-removed."
   :materiality "Το ίδιο το αρχείο δηλώνει ΡΗΤΑ ότι ΔΕΝ αποδεικνύει append-only: ολική αντικατάσταση ή διαγραφή περνά τον εσωτερικό έλεγχο."
   :evidence "systems/orchestrator-epistemic/transparency-log.lisp:L19-L31,L45-L72,L117-L169")

  (:name "legacy authority seat removal (fail-closed άρνηση)"
   :presence :present
   :domain "Τρεις παλιές έδρες authority: tlog-append-root!, release-attested-p, promote-latest!."
   :assumptions "Ο κώδικας φορτώνεται· καμία άλλη διαδρομή δεν αναπαράγει τη λειτουργία."
   :guarantees "Κάθε κλήση σηματοδοτεί condition legacy-authority-seat-removed — δεν υπάρχει fallback."
   :failure-semantics "error, πάντα· κανένα return value."
   :operating-model "%seat-removed = (error 'legacy-authority-seat-removed ...)."
   :materiality "Ο αποκλεισμός είναι σε επίπεδο ΚΩΔΙΚΑ (Lisp condition), όχι OS. Το OS-enforced μέρος δηλώνεται ότι ζει στο authority-v2 (εκτός συστάδας)."
   :evidence "systems/orchestrator-epistemic/authority-boundary.lisp:L21-L37 · transparency-log.lisp:L131-L132 · deploy-epistemic.lisp:L952-L953,L967-L968")

  (:name "candidate boundary — emit-candidate-bundle!"
   :presence :present
   :domain "candidates/<release-id>.candidate.json + candidates/<release-id>/ bundle."
   :assumptions "Ο producer είναι ΙΔΙΟΚΤΗΤΗΣ του candidates/ (ρητά δηλωμένο ως ΜΕΤΑΒΛΗΤΟ/TOCTOU)."
   :guarantees "Δεν γράφει latest/log/releases· ο δείκτης φέρει :authority :false."
   :failure-semantics "with-open-file :if-exists :error, αλλά προστατευμένο από (unless (probe-file marker)) ⇒ TOCTOU παράθυρο."
   :operating-model "content-addressed όνομα· η πραγματική αμεταβλητότητα δηλώνεται ότι ζει στο authority-v2/capture."
   :materiality "Το ίδιο το αρχείο ΑΝΑΚΑΛΕΙ τον χαρακτηρισμό «immutable» ως ΨΕΥΔΗ."
   :evidence "systems/orchestrator-epistemic/authority-boundary.lisp:L44-L58,L64-L96")

  (:name "content-addressed candidate publish (atomic-publish-release)"
   :presence :present
   :domain "staging/ → candidates/<sha256-root>/"
   :assumptions "Το staging περιέχει τα canonical αρχεία της εποχής του."
   :guarantees "Το staging ΕΠΑΝΑΫΠΟΛΟΓΙΖΕΤΑΙ και πρέπει να παράγει το δηλωμένο release-id· υπάρχων κατάλογος με ΞΕΝΟ (επαναϋπολογισμένο) root ⇒ validation-error, δεν αγγίζεται."
   :failure-semantics "fail-closed validation-error· ταυτόσημο περιεχόμενο ⇒ reuse + διαγραφή staging."
   :operating-model "rename-file (ίδιο filesystem)· ΔΕΝ γράφει ποτέ στο releases/."
   :materiality "Το epoch-downgrade κλείνεται δομικά: sha256-named χωρίς census.json και εκτός +frozen-legacy-release-ids+ (18 ids) ⇒ ΣΦΑΛΜΑ."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L790-L854,L876-L937")

  (:name "material gate release (validate-epistemic-stage)"
   :presence :present
   :domain "18 απαιτούμενα αρχεία + TSA-CA exactly-one-of + signature material."
   :assumptions "probe-file αρκεί για «ύπαρξη»."
   :guarantees "Λείπον απαιτούμενο ⇒ NIL ⇒ ο καλών σφάλλει. TSA-CA: ΑΚΡΙΒΩΣ ένα από {δομικά έγκυρο X.509 tsa-ca.pem, tsa-ca.MISSING.txt με canonical sentinel}."
   :failure-semantics "Επιστρέφει NIL· ο deploy-epistemic-stage το μετατρέπει σε validation-error."
   :operating-model "Καθαρά υλικός έλεγχος — ΡΗΤΑ δηλώνεται ότι ΔΕΝ τρέχει SHACL processor."
   :materiality "Η υπογραφή (signature.jws/public.jwk) γίνεται ΠΡΟΑΙΡΕΤΙΚΗ όταν ORCHESTRATOR_DEV_MODE ∈ {1,true,yes}."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L1133-L1204 · L255-L258 · L315-L346")

  (:name "τίμια απουσία TSA CA (sentinel note)"
   :presence :present
   :domain "verify/tsa-ca.pem | verify/tsa-ca.MISSING.txt"
   :assumptions "Η CA παρέχεται από τον χειριστή (env TSA_CA_BUNDLE ή <institution>/keys/tsa-ca.pem)."
   :guarantees "Ποτέ ψευδο-cert: άκυρη παρεχόμενη CA ⇒ ΣΦΑΛΜΑ (assert-valid-x509-pem, chain-aware)· καμία CA ⇒ σημείωση με canonical sentinel +tsa-ca-missing-sentinel+."
   :failure-semantics "fail-closed για άκυρη CA· τίμια δηλωμένο κενό για απούσα."
   :operating-model "Μία έδρα εκπομπής (%emit-tsa-ca-or-honest-note) + ανεξάρτητη πύλη (%tsa-ca-material-ok-p)."
   :materiality "Ρητά δηλώνεται ότι η ΠΛΗΡΗΣ RFC-3161 επαλήθευση αλυσίδας είναι δηλωμένη φάση P4+ — ΔΕΝ υπάρχει."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L264-L346")

  (:name "fail-closed πολιτική κλειδιών (ensure-crypto-keys-exist)"
   :presence :present
   :domain "keys/private.pem, public.pem, certificate.pem"
   :assumptions "Το trust root υπάρχει ήδη· γένεση μόνο με ρητό opt-in."
   :guarantees "Λείπον ιδιωτικό κλειδί ΚΑΙ χωρίς LAWMAX_ALLOW_KEY_GENESIS ∈ {1,true,yes,ΝΑΙ} ⇒ validation-error."
   :failure-semantics "fail-closed· με opt-in παράγεται RSA-4096 + self-signed X.509 100 ετών με ηχηρή προειδοποίηση σε stdout."
   :operating-model "Καθαρό Common Lisp (Ironclad) — χωρίς OpenSSL."
   :materiality "Η προειδοποίηση «ΔΕΝ ΠΡΕΠΕΙ ΝΑ ΥΠΟΓΡΑΨΕΙ ΔΗΜΟΣΙΟ RELEASE» είναι ΜΟΝΟ κείμενο σε stdout — δεν αποτυπώνεται σε κανένα artifact του release."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L348-L418")

  (:name "intake αποφάσεων από το ίδιο το κείμενο (%decision-intake)"
   :presence :present
   :domain "input/decisions/*.{pdf,html,txt} → <slug>/<tag>_<έτος>_<αριθμός>.<type>"
   :assumptions "Το δικαστήριο αναγνωρίζεται από 7 σταθερές συμβολοσειρές του *court-registry*· η ταυτότητα από regex στο κείμενο ή στο ΟΝΟΜΑ αρχείου."
   :guarantees "Ό,τι δεν κατανοείται ΔΕΝ αρχειοθετείται: εκτυπώνεται λόγος και γράφεται lesson (needs-ocr / unknown-court)."
   :failure-semantics "Per-file handler-case ⇒ το σφάλμα εκτυπώνεται και το intake συνεχίζει με τα υπόλοιπα αρχεία."
   :operating-model "rename-file στο ίδιο δέντρο· ένα αρχείο τη φορά."
   :materiality "Άγνωστη ταυτότητα ΔΕΝ γράφει lesson (μόνο εκτυπώνει) — βλ. defects."
   :evidence "systems/orchestrator-cli/decisions.lisp:L150-L216")

  (:name "μνήμη αναστοχασμού (lessons.jsonl)"
   :presence :present
   :domain "<state-dir>/lessons.jsonl — JSONL {date,kind,subject,detail}"
   :assumptions "Ο state dir είναι εγγράψιμος."
   :guarantees "Append-only· 8+ σημεία κλήσης· μία έδρα ανάγνωσης (%lessons-aggregate) που μοιράζονται --lessons και run-reflect."
   :failure-semantics "ΟΛΟΚΛΗΡΟ το %lesson είναι τυλιγμένο σε (ignore-errors ...) ⇒ αποτυχία εγγραφής εξαφανίζεται σιωπηλά ΚΑΙ αφήνει *gap-created-this-turn* = NIL."
   :operating-model "Χειροκίνητη κλήση σε κάθε σημείο αποτυχίας — όχι δομικά υποχρεωτική."
   :materiality "Το *gap-created-this-turn* τροφοδοτεί το envelope gap_created του run-ask."
   :evidence "systems/orchestrator-cli/decisions.lisp:L88-L112,L115-L132,L134-L149")

  (:name "OCR fallback για σαρωμένες αποφάσεις (ΚΑΤΑΝΑΛΩΤΗΣ, έδρα εκτός συστάδας)"
   :presence :present
   :domain "PDF χωρίς text layer· κλήση orchestrator.pdf-authority:extract-text-any / ocr-available-p"
   :assumptions "pdftoppm + tesseract με γλώσσα ell στο PATH."
   :guarantees "Ο καλών παίρνει ΠΑΝΤΑ (values text source) με source ∈ {:text-layer,:ocr,:none}."
   :failure-semantics "extract-text-any επιστρέφει :none· ο καλών decisions.lisp ματαιώνει το intake."
   :operating-model "Η ΕΔΡΑ ζει σε source/pdf-authority.lisp (ΕΚΤΟΣ systems/)· το systems/ είναι μόνο καταναλωτής."
   :materiality "Η διάκριση «λείπει OCR» vs «OCR δεν απέδωσε» υπάρχει ΜΟΝΟ ως κείμενο stdout — βλ. defects."
   :evidence "systems/orchestrator-cli/decisions.lisp:L168-L183 · source/pdf-authority.lisp:L1386-L1441")

  (:name "μητρώο εντολών με νόμο ΜΙΑΣ ΕΔΡΑΣ (register-command)"
   :presence :present
   :domain "133 εγγραφές register-command σε 30+ αρχεία του orchestrator-cli."
   :assumptions "orchestrator.paths:current-load-file δίνει αποδώσιμη ταυτότητα αρχείου κατά το load."
   :guarantees "Δεύτερη εγγραφή ίδιου ονόματος από ΑΛΛΟ αρχείο ⇒ command-seat-collision (error). Επανεγγραφή καταργημένου ονόματος ⇒ error. retire-command! σε ΕΝΕΡΓΟ όνομα ⇒ error."
   :failure-semantics "fail-closed κατά το load· ανώνυμο runtime site ΔΕΝ μπορεί να διεκδικήσει υπάρχουσα έδρα."
   :operating-model "Δύο hash-tables (*commands*, *command-owners*) + *retired-commands*· resolve-command = η ΜΙΑ έδρα επίλυσης (:registered|:retired|:unknown)."
   :materiality "Το --gates ΠΑΡΑΚΑΜΠΤΕΙ το resolve-command/execute-command (βλ. hidden-execution-paths)."
   :evidence "systems/orchestrator-cli/cli-util.lisp:L23-L140")

  (:name "συνταγματικός φραγμός δρομολόγησης (CLOS :around)"
   :presence :present
   :domain "Κάθε εντολή που περνά από execute-command."
   :assumptions "orchestrator.constitution:evaluate κρίνει το όνομα της εντολής (έδρα εκτός συστάδας)."
   :guarantees "Αντισυνταγματική πράξη ⇒ ΔΕΝ εκτελείται (exit 1) με αιτιολογία στο άρθρο· κάθε πράξη γίνεται root span ιχνών."
   :failure-semantics "Άρνηση με μήνυμα· η παράκαμψη είναι ρητή (--force + LAWMAX_OVERRIDE_REASON, ή LAWMAX_OVERRIDE=<name> + LAWMAX_OVERRIDE_REASON)."
   :operating-model "CLOS method combination — ο φραγμός είναι το μεσολαβούν στρώμα, όχι κλήση."
   :materiality "Η καταγραφή της παράκαμψης στη βιογραφία είναι σε (ignore-errors ...) ⇒ μπορεί να χαθεί σιωπηλά ενώ η πράξη εκτελείται."
   :evidence "systems/orchestrator-cli/constitutional-dispatch.lisp:L22-L76")

  (:name "ολομέλεια πυλών (--gates)"
   :presence :present
   :domain "25 εγγεγραμμένες εντολές που λήγουν σε «-gate»."
   :assumptions "Το σύνολο παράγεται ΑΠΟ το μητρώο εντολών, όχι από χειρόγραφη λίστα."
   :guarantees "Ό,τι δεν επιστρέφει ρητό 0 ⇒ ΑΠΕΤΥΧΕ· εκπέμπεται data-only GATE-PLENARY-MANIFEST με :completed t ΜΟΝΟ μετά από ΟΛΕΣ τις πύλες (crash ⇒ κανένα manifest ⇒ όχι false-green)."
   :failure-semantics "Ανεξέλεγκτο σφάλμα σε ΜΙΑ πύλη ματαιώνει ΟΛΗ την ολομέλεια πριν το manifest (δεν υπάρχει per-gate handler-case)."
   :operating-model "(funcall (gethash name *commands*) nil) — ΑΠΕΥΘΕΙΑΣ από το hash-table."
   :materiality "Παρακάμπτεται ο συνταγματικός φραγμός και το resolve-command."
   :evidence "systems/orchestrator-cli/gates-runner.lisp:L17-L63")

  (:name "πύλη αμεταβλήτων εκδόσεων (--release-gate)"
   :presence :present
   :domain "output/*/releases/** — δύο εποχές (census / legacy), latest, latest.json, transparency log."
   :assumptions "Οι έδρες του orchestrator.epistemic προσπελαύνονται με find-symbol κατά το runtime."
   :guarantees "census-εποχή: recomputed RFC-6962 root ≡ όνομα ≡ δηλωμένο + spine + γέφυρα prev_release_root· anti-deletion (κάθε census-era attested root ∈ log entries)· exact-set κάλυψη κατά *served-corpora*."
   :failure-semantics "read-only· I/O σφάλμα = ΑΠΟΤΥΧΙΑ, όχι σιωπηλό πράσινο."
   :operating-model "Καταναλώνει τις ΙΔΙΕΣ έδρες με τον παραγωγό (%release-recomputed-root, %root->release-id, tlog-verify)."
   :materiality "ΔΥΟ από τους ελέγχους της καλούν RELEASE-ATTESTED-P — έδρα που ΠΑΝΤΑ σφάλλει (βλ. defects P0)."
   :evidence "systems/orchestrator-cli/release-gate.lisp:L33-L239")

  (:name "σύμβουλος LLM εκτός εμπιστοσύνης (advisor)"
   :presence :present
   :domain "OpenAI-συμβατό /chat/completions endpoint· δύο σκοποί: ταξινόμηση πρόθεσης, «όνειρο» γραμματικής."
   :assumptions "LAWMAX_ADVISOR_URL ορισμένο· αλλιώς η υποδοχή είναι ΚΕΝΗ και η λειτουργία καθαρά συμβολική."
   :guarantees "Η απάντηση διαβάζεται με *read-eval* nil, *package* :keyword, όριο 2000 χαρ.· μόνο 3 πλαίσια λευκού καταλόγου· κάθε πρόταση περνά συμβολική επαλήθευση (corpus ∈ +law-tag-corpus-map+, άρθρο ψηφία, έννοια γειωμένη σε διάταξη)· το «όνειρο» γίνεται γνώση ΜΟΝΟ αν εξηγεί τον ΠΑΡΑΤΗΡΗΜΕΝΟ τύπο."
   :failure-semantics "Κάθε αποτυχία (δίκτυο/μορφή/επαλήθευση) ⇒ nil — τίμια άγνοια, ο πυρήνας συνεχίζει συμβολικά."
   :operating-model "drakma:http-request POST, :connection-timeout 10, χωρίς ρητή ρύθμιση επαλήθευσης TLS και χωρίς read timeout."
   :materiality "Η ΕΙΣΟΔΟΣ ΤΟΥ ΧΡΗΣΤΗ στέλνεται αυτούσια στο endpoint όταν κανένας συμβολικός ταξινομητής δεν πιάνει."
   :evidence "systems/orchestrator-cli/advisor.lisp:L23-L198,L215-L290")

  (:name "ταυτότητα δημιουργού για ΚΑΘΕ HTTP επιφάνεια"
   :presence :present
   :domain "/ask, /cmd, cockpit — %creator-request-authorised-p."
   :assumptions "«προσωπική τοπική εγκατάσταση»."
   :guarantees "Με LAWMAX_CREATOR_TOKEN ορισμένο, απαιτείται ?key=… που ταιριάζει ΑΚΡΙΒΩΣ."
   :failure-semantics "ΧΩΡΙΣ token (ή με κενό/whitespace token) επιστρέφει ΠΑΝΤΑ T — κάθε αιτών είναι ο δημιουργός."
   :operating-model "(equal tok key) — σύγκριση μεταβλητού χρόνου· το μυστικό ταξιδεύει σε query string."
   :materiality "Μία έδρα, καταναλώνεται από όλες τις επιφάνειες· το προεπιλεγμένο άνοιγμα δεν επιβάλλεται από τίποτα."
   :evidence "systems/orchestrator-cli/cli-util.lisp:L192-L199")

  (:name "δοκιμές FiveAM (ΔΕΥΤΕΡΗ ΕΔΡΑ, εκτός tests/*-test.lisp)"
   :presence :present
   :domain "orchestrator-tests/: 4 def-suite (master + unit + integration + reproducibility), 12 αρχεία, 30 (test …) forms."
   :assumptions "Τα fixtures γράφουν σε ΣΤΑΘΕΡΑ απόλυτα μονοπάτια /tmp/orchestrator-test-ai/ και /tmp/orchestrator-integration-test/."
   :guarantees "run-all-tests ⇒ T μόνο όταν (fiveam:results-status results) = NIL."
   :failure-semantics "Επιστρέφει NIL· ο καλών (--run-tests / ASDF test-op / entrypoint) αποφασίζει."
   :operating-model "Καθαρά in-process· καμία δοκιμή δεν διασχίζει όριο διεργασίας."
   :materiality "Οι «reproducibility» δοκιμές συγκρίνουν δύο κλήσεις ΜΕΣΑ στην ΙΔΙΑ εικόνα — δεν μπορούν να πιάσουν μη-ντετερμινισμό μεταξύ εκτελέσεων/μηχανών."
   :evidence "systems/orchestrator-tests/suite.lisp:L11-L98 · reproducibility/hash-stability-test.lisp:L8-L13 · unit/test-ai-core.lisp:L13,L417-L452 · integration/ai-export-integration-test.lisp:L15-L16,L192-L215")
)

 :authorities
 ((:name "admission kernel της authority-v2 (ΕΚΤΟΣ ΣΥΣΤΑΔΑΣ — μόνο δηλωμένος)"
   :what-it-can-decide "Προαγωγή candidate → authoritative release/log/latest· πλήρης TSA επαλήθευση."
   :who-can-invoke ":unknown από τη συστάδα systems/ — καμία κλήση προς αυτόν δεν υπάρχει εδώ."
   :enforcement :os
   :evidence "systems/orchestrator-epistemic/authority-boundary.lisp:L5-L15,L52-L58 · deploy-epistemic.lisp:L947-L950")

  (:name "legacy producer (ολόκληρο το systems/)"
   :what-it-can-decide "ΜΟΝΟ παραγωγή candidate bundles· καμία authoritative εγγραφή."
   :who-can-invoke "deploy-epistemic-stage από το pipeline."
   :enforcement :code
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L1103-L1127")

  (:name "χειριστής μέσω μεταβλητών περιβάλλοντος"
   :what-it-can-decide "ORCHESTRATOR_DEV_MODE (παρακάμπτει JWS gate + signature material gate)· LAWMAX_ALLOW_KEY_GENESIS (γεννά trust root)· TSA_CA_BUNDLE· PRIVATE_KEY_PATH· RELEASE_CERT_PATH."
   :who-can-invoke "Οποιοσδήποτε ελέγχει το περιβάλλον της διεργασίας."
   :enforcement :none
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L255-L258,L348-L354,L430-L442,L1195-L1202")

  (:name "HTTP επιφάνειες /ask, /cmd, cockpit"
   :what-it-can-decide "/ask: ακροατήριο :creator (ενδοσκόπηση/ατζέντα) έναντι :guest. /cmd: εκτέλεση --auto-update ή --failures. cockpit /api: ask/pending/decide/publish/catalog."
   :who-can-invoke "ΧΩΡΙΣ LAWMAX_CREATOR_TOKEN: οποιοσδήποτε φτάνει τη θύρα (το serve-corpus δεσμεύεται στο 0.0.0.0). ΜΕ token: όποιος ξέρει το ?key=."
   :enforcement :none
   :evidence "systems/orchestrator-cli/main.lisp:L803-L850,L911 · systems/orchestrator-cli/cli-util.lisp:L192-L199 · systems/orchestrator-cli/cockpit.lisp:L258-L268")

  (:name "ολομέλεια πυλών --gates / --auto-update"
   :what-it-can-decide "Ενιαία ετυμηγορία «100% του συστήματος» + GATE-PLENARY-MANIFEST."
   :who-can-invoke "CLI, cron, και (μέσω --auto-update) το δημόσιο /cmd."
   :enforcement :code
   :evidence "systems/orchestrator-cli/gates-runner.lisp:L17-L63 · systems/orchestrator-cli/main.lisp:L1351-L1355")

  (:name "*court-registry* — αναγνώριση δικαστηρίου"
   :what-it-can-decide "Σε ποιον φάκελο αρχειοθετείται μια απόφαση (7 δικαστήρια)."
   :who-can-invoke "%intake-one· επέκταση = μία γραμμή στο defparameter."
   :enforcement :code
   :evidence "systems/orchestrator-cli/decisions.lisp:L77-L87"))

 :invariants
 ((:statement "log_root ≡ MTH(entries) και κάθε checkpoint επεκτείνεται από το τρέχον δέντρο"
   :enforced-by "tlog-verify — επανυπολογισμός + RFC6962 consistency proof"
   :evidence "systems/orchestrator-epistemic/transparency-log.lisp:L134-L169")
  (:statement "Το όνομα του candidate καταλόγου ≡ sha256 του Merkle root των canonical αρχείων του"
   :enforced-by "atomic-publish-release: %release-dir-root στο staging + %release-recomputed-root στον υπάρχοντα"
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L831-L851")
  (:statement "sha256-named release χωρίς census.json και εκτός του παγωμένου συνόλου των 18 ⇒ ΣΦΑΛΜΑ (κανένα epoch-downgrade)"
   :enforced-by "%release-canonical-era"
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L908-L922")
  (:statement "Το υλικό TSA CA ενός release είναι ΑΚΡΙΒΩΣ ένα από {έγκυρο pem, sentinel note}"
   :enforced-by "%tsa-ca-material-ok-p (ανεξάρτητα από την έδρα εκπομπής)"
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L315-L346,L1188-L1193")
  (:statement "Το trust root δεν γεννιέται σιωπηλά ανά run"
   :enforced-by "ensure-crypto-keys-exist + %key-genesis-explicitly-allowed-p"
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L348-L377"))

 :defects
 ((:what "«✓ ALL PROOF GATES PASSED» εκτυπώνεται ΑΝΕΞΑΡΤΗΤΑ από το αν πέρασαν: GATE 2 (RFC-3161) μπορεί να απέτυχε σε ΟΛΕΣ τις TSA και GATE 3 (JWS) να παραλείφθηκε σε dev-mode· η γραμμή L529 δεν εξαρτάται από κανένα από τα δύο αποτελέσματα."
   :severity :p0
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L497-L529"
   :is-it-in-the-known-defect-list :unknown)
  (:what "ORCHESTRATOR_DEV_MODE (env, χωρίς καμία επιβολή) υποβαθμίζει ΔΥΟ πύλες: παραλείπει την υπογραφή JWS και δέχεται release χωρίς signature.jws/public.jwk. Δεν αποτυπώνεται στο ίδιο το release ότι παρήχθη σε dev-mode."
   :severity :p0
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L255-L258,L513-L525,L1195-L1202"
   :is-it-in-the-known-defect-list :unknown)
  (:what "%lesson τυλιγμένο ολόκληρο σε ignore-errors: αποτυχία εγγραφής lessons.jsonl εξαφανίζει το κενό ΚΑΙ αφήνει *gap-created-this-turn* = NIL, οπότε το envelope δηλώνει gap_created ψευδώς αρνητικό."
   :severity :p1
   :evidence "systems/orchestrator-cli/decisions.lisp:L94-L112"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Στο %intake-one η αποτυχία εύρεσης ταυτότητας (ούτε κείμενο ούτε όνομα) ΔΕΝ γράφει %lesson — μόνο εκτυπώνει· η αντίστοιχη αποτυχία δικαστηρίου γράφει. Ασύμμετρη καταγραφή κενών."
   :severity :p2
   :evidence "systems/orchestrator-cli/decisions.lisp:L186-L191,L205-L208"
   :is-it-in-the-known-defect-list :unknown)
  (:what "emit-candidate-bundle!: (unless (probe-file marker) (with-open-file ... :if-exists :error)) — TOCTOU· επίσης αν ο δείκτης προϋπάρχει με ΞΕΝΟ περιεχόμενο δεν επαληθεύεται καθόλου (σε αντίθεση με το atomic-publish-release που επαναϋπολογίζει)."
   :severity :p1
   :evidence "systems/orchestrator-epistemic/authority-boundary.lisp:L82-L95"
    :is-it-in-the-known-defect-list :unknown)
  (:what "Η --release-gate καλεί ΔΥΟ ΦΟΡΕΣ την orchestrator.epistemic::release-attested-p, η οποία είναι ΚΑΤΑΡΓΗΜΕΝΗ ΕΔΡΑ και σηματοδοτεί ΠΑΝΤΑ legacy-authority-seat-removed. Καμία από τις δύο κλήσεις δεν είναι σε handler-case ⇒ (α) legacy release με timestamp.tsr, ή (β) content-addressed latest, ΑΝΑΤΙΝΑΖΟΥΝ την πύλη με ανεξέλεγκτο condition — και μέσα στο --gates ματαιώνουν ΟΛΗ την ολομέλεια πριν εκπεμφθεί το GATE-PLENARY-MANIFEST. Οι μόνοι παραγωγικοί καλούντες της καταργημένης έδρας σε ΟΛΟ το repo είναι αυτές οι δύο γραμμές· τα tests (tests/level7-disarm-test.lisp:L63-L65) επιβεβαιώνουν την κατάργηση αλλά ο ΚΑΤΑΝΑΛΩΤΗΣ δεν ενημερώθηκε."
   :severity :p0
   :evidence "systems/orchestrator-cli/release-gate.lisp:L66-L72,L189-L198 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L939-L953"
   :is-it-in-the-known-defect-list :no)
  (:what "Το --gates εκτελεί κάθε πύλη με (funcall (gethash name *commands*) nil) — ΠΑΡΑΚΑΜΠΤΟΝΤΑΣ και το resolve-command και τη συνταγματική :around του execute-command. Το main.lisp δηλώνει ρητά ότι το εύρημα «30 builtin εντολές εκτελούνται ΕΚΤΟΣ της πύλης του ΕΓΩ» έκλεισε «στη ρίζα της δρομολόγησης» — για τις 25 πύλες της ολομέλειας ΔΕΝ έκλεισε."
   :severity :p0
   :evidence "systems/orchestrator-cli/gates-runner.lisp:L28-L37 · systems/orchestrator-cli/main.lisp:L2529-L2544 · systems/orchestrator-cli/constitutional-dispatch.lisp:L49-L76"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Το engine stage καλεί ΔΕΥΤΕΡΗ φορά την validate-epistemic-stage πάνω στο ΤΕΛΙΚΟ candidate dir και, σε αποτυχία, μόνο ΠΡΟΕΙΔΟΠΟΙΕΙ (log:warn «some files may be missing») ενώ επιστρέφει κανονικά το context. Η ΙΔΙΑ συνάρτηση στο Step 8 του παραγωγού είναι σκληρή πύλη (error). Δύο έδρες της ίδιας πύλης με ΑΝΤΙΘΕΤΗ σημασιολογία επιβολής."
   :severity :p0
   :evidence "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L156-L161 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L1096-L1101"
   :is-it-in-the-known-defect-list :unknown)
  (:what "%creator-request-authorised-p: χωρίς LAWMAX_CREATOR_TOKEN (ή με κενό token) ΚΑΘΕ αιτών σε /ask, /cmd, cockpit ταυτοποιείται ως ο δημιουργός. Με token, η σύγκριση (equal tok key) δεν είναι σταθερού χρόνου και το μυστικό μεταφέρεται σε query string (?key=…)."
   :severity :p0
   :evidence "systems/orchestrator-cli/cli-util.lisp:L192-L199"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Η καταγραφή της συνταγματικής ΠΑΡΑΚΑΜΨΗΣ στη βιογραφία είναι τυλιγμένη σε (ignore-errors …): αν αποτύχει, η πράξη ΕΚΤΕΛΕΙΤΑΙ ούτως ή άλλως και το ίχνος της παράβασης χάνεται σιωπηλά — ενώ το ίδιο το αρχείο δηλώνει «Ποτέ σιωπηλή παράβαση»."
   :severity :p1
   :evidence "systems/orchestrator-cli/constitutional-dispatch.lisp:L14,L41-L47,L71-L74"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Αποτυχία φόρτωσης των πακέτων γνώσης στο startup είναι ΜΟΝΟ προειδοποίηση στο stderr· η εκτέλεση συνεχίζει και «οι κρίσεις θα είναι ελλιπείς» — καμία πύλη/έξοδος δεν φέρει αυτή τη σημαία."
   :severity :p1
   :evidence "systems/orchestrator-cli/main.lisp:L2517-L2525"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Το δημόσιο :export του πακέτου orchestrator.cli διαφημίζει ΠΕΝΤΕ ονόματα (run-full-build, run-full-build-ai, run-ai-export-only, validate-pipeline, generate-report) που είναι ΟΛΑ αποσυρμένα tombstones και σφάλλουν με retired-entrypoint. Το δημόσιο συμβόλαιο του πακέτου δηλώνει ικανότητες που δεν υπάρχουν."
   :severity :p1
   :evidence "systems/orchestrator-cli/package.lisp:L9-L16 · systems/orchestrator-cli/commands.lisp:L26-L67"
   :is-it-in-the-known-defect-list :yes)
  (:what "suite.lisp: οι run-orchestrator-tests (L32-L63) και run-all-tests (L69-L98) είναι ΤΑΥΤΟΣΗΜΑ σώματα — διπλή έδρα εκτέλεσης της σουίτας μέσα στο ΙΔΙΟ αρχείο· επιπλέον το (export …) στο L100 εξάγει σύμβολο εκτός defpackage."
   :severity :p1
   :evidence "systems/orchestrator-tests/suite.lisp:L32-L100 · systems/orchestrator-tests/package.lisp:L6-L13"
   :is-it-in-the-known-defect-list :unknown)
  (:what "«Reproducibility» δοκιμές που είναι ταυτολογίες: hash-reproducibility καλεί δύο φορές την ΙΔΙΑ συνάρτηση στην ΙΔΙΑ εικόνα· deterministic-manifest-reproducibility, deterministic-provenance-hash και integration-deterministic-build κάνουν το ίδιο με σταθερό timestamp override. Καμία δεν διασχίζει όριο διεργασίας/μηχανής, άρα δεν μπορεί να πιάσει τη μη-αναπαραγωγιμότητα που ονομάζει."
   :severity :p1
   :evidence "systems/orchestrator-tests/reproducibility/hash-stability-test.lisp:L8-L13 · systems/orchestrator-tests/unit/test-ai-core.lisp:L417-L439,L441-L452 · systems/orchestrator-tests/integration/ai-export-integration-test.lisp:L192-L215"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Οι δοκιμές γράφουν και ΔΙΑΓΡΑΦΟΥΝ ΔΕΝΔΡΑ σε σταθερά απόλυτα μονοπάτια (/tmp/orchestrator-test-ai/, /tmp/orchestrator-integration-test/, /tmp/orchestrator-test/) — συγκρούσεις μεταξύ παράλληλων εκτελέσεων στον ίδιο host και έκθεση σε προϋπάρχον /tmp περιεχόμενο."
   :severity :p2
   :evidence "systems/orchestrator-tests/unit/test-ai-core.lisp:L13,L51-L54 · systems/orchestrator-tests/integration/ai-export-integration-test.lisp:L15-L16 · systems/orchestrator-tests/fixtures/mock-data.lisp:L21-L24"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Το engine stage γράφει στο context :epistemic-attested ← (getf result :attested) και :epistemic-latest ← (getf result :latest-symlink)· ο εσωτερικός deploy-epistemic-stage ΔΕΝ επιστρέφει κανένα από τα δύο κλειδιά ⇒ και τα δύο είναι ΠΑΝΤΑ NIL. Το --cut-release τυπώνει «ATTESTED» από αυτή τη NIL τιμή· η άγνοια («δεν ξέρω») δεν διακρίνεται από την άρνηση («όχι»)."
   :severity :p1
   :evidence "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L108-L118,L124 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L1121-L1127 · systems/orchestrator-cli/release-authority.lisp:L142-L148"
   :is-it-in-the-known-defect-list :unknown)
  (:what "%write-cursor τυλίγει την ατομική εγγραφή σε (ignore-errors …): αποτυχία διατήρησης του cursor εξαφανίζεται και η επόμενη εκτέλεση ξαναρχίζει από την ίδια θέση χωρίς καμία ένδειξη."
   :severity :p2
   :evidence "systems/orchestrator-cli/cli-util.lisp:L238-L244"
    :is-it-in-the-known-defect-list :unknown)
  (:what "Το serve-corpus δεσμεύεται ΑΝΕΞΑΙΡΕΤΑ στο 0.0.0.0 και εκθέτει /ask και /cmd. Και τα δύο κρίνουν ταυτότητα ΜΟΝΟ με %creator-request-authorised-p, που ΧΩΡΙΣ LAWMAX_CREATOR_TOKEN επιστρέφει T για ΟΠΟΙΟΝΔΗΠΟΤΕ. Δεν υπάρχει Host-allowlist ούτε custom-header CSRF φραγή (σε αντίθεση με το cockpit που έχει και τα δύο). Συνέπεια σε προεπιλεγμένη ανάπτυξη χωρίς token: κάθε απομακρυσμένος πελάτης παίρνει ακροατήριο :creator στο /ask ΚΑΙ μπορεί να εκτελέσει --auto-update μέσω /cmd?name=--auto-update (πλήρης κύκλος: δικτυακή λήψη, ξαναγράψιμο όλων των outputs, έκδοση υπογεγραμμένων αποδείξεων, προαιρετική δημοσίευση site)."
   :severity :p0
   :evidence "systems/orchestrator-cli/main.lisp:L900-L912,L803-L850,L1295-L1368 · systems/orchestrator-cli/cli-util.lisp:L192-L199 · systems/orchestrator-cli/cockpit.lisp:L228-L268"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Τρίτο προνομιακό μονοπάτι δρομολόγησης: το /cmd εκτελεί (funcall (find-command name) nil), δηλαδή απευθείας τον χειριστή από το μητρώο, παρακάμπτοντας resolve-command ΚΑΙ τη συνταγματική :around — όπως και το --gates."
   :severity :p0
   :evidence "systems/orchestrator-cli/main.lisp:L843-L850"
   :is-it-in-the-known-defect-list :unknown)
  (:what "%cockpit-host-ok-p: ο κλάδος COCKPIT_ALLOWED_HOSTS βραχυκυκλώνει ΠΡΙΝ από την απαίτηση token — δημόσιο bind με allowlist και ΧΩΡΙΣ LAWMAX_CREATOR_TOKEN περνά τον host-guard και μετά ο έλεγχος key επιστρέφει T για όλους."
   :severity :p1
   :evidence "systems/orchestrator-cli/cockpit.lisp:L228-L244,L252-L268 · systems/orchestrator-cli/cli-util.lisp:L192-L199"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Λήψη τροποποιητικών νόμων: το προσωρινό αρχείο είναι (format nil \"/tmp/amend-~A-~A.pdf\" num (random 100000)) — το num προέρχεται ΑΠΕΥΘΕΙΑΣ από απομακρυσμένα δεδομένα (πεδίο \"number\") χωρίς κανένα φιλτράρισμα διαδρομής, και το (random …) χωρίς seed είναι ντετερμινιστικό ανά εικόνα ⇒ προβλέψιμο όνομα, χωρίς O_EXCL."
   :severity :p1
   :evidence "systems/orchestrator-cli/ingestion-commands.lisp:L442-L465"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Η στιγμιαία διαθεσιμότητα blockchain anchor δεν είναι πύλη: *anchor-require-at-least-one* = NIL ⇒ το στάδιο ολοκληρώνεται με ΜΗΔΕΝ επιτυχημένες αλυσίδες και ο deploy συνεχίζει με blockchain-anchor «pending». Επιπλέον γράφεται (:anchor-timestamp . (get-universal-time)) — ρολόι συστήματος μέσα σε build που αλλού απαιτεί require-deterministic-time."
   :severity :p1
   :evidence "systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp:L23-L27,L62-L91 · systems/orchestrator-epistemic/deploy-epistemic.lisp:L976"
   :is-it-in-the-known-defect-list :unknown)
  (:what "generate-trace-id χρησιμοποιεί (get-universal-time) + (random 100000) — δεύτερη έδρα χρόνου/τυχαιότητας εκτός orchestrator.time, μέσα στο μονοπάτι parsing του gr-syntagma."
   :severity :p2
   :evidence "systems/orchestrator-gr-syntagma/parsing.lisp:L132-L144"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Δεκάδες προσωρινά αρχεία πυλών ονομάζονται (format nil \"…-~D.sexp\" (get-universal-time)) μέσα στο uiop:temporary-directory — προβλέψιμα ονόματα σε κοινό κατάλογο, χωρίς αποκλειστική δημιουργία."
   :severity :p2
   :evidence "systems/orchestrator-cli/self-extension.lisp:L104,L160,L248,L507-L509 · generation-gate.lisp:L67 · inference-gate.lisp:L400 · memory-commands.lisp:L110 · approval-policy.lisp:L202-L204 · advisor.lisp:L266-L269"
   :is-it-in-the-known-defect-list :unknown))

 :hidden-execution-paths
 ((:path "Παράκαμψη υπογραφής μέσω μεταβλητής περιβάλλοντος"
   :trigger "ORCHESTRATOR_DEV_MODE=1|true|yes"
   :why-hidden "Δεν εμφανίζεται σε κανένα CLI flag, σε κανένα artifact του release, και το τελικό μήνυμα εξακολουθεί να λέει ALL PROOF GATES PASSED."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L255-L258,L519-L522,L1199-L1201")
  (:path "Γένεση trust root κατά τη διάρκεια build"
   :trigger "LAWMAX_ALLOW_KEY_GENESIS=1|true|yes|ΝΑΙ και απόν private.pem"
   :why-hidden "Παράγει self-signed X.509 100 ετών μέσα στο deploy stage· η προειδοποίηση ζει μόνο σε stdout."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L348-L414")
  (:path "Ανακατεύθυνση ιδιωτικού κλειδιού / certificate μέσω env"
   :trigger "PRIVATE_KEY_PATH / RELEASE_CERT_PATH (φιλτράρονται μόνο για \"..\" και \"~\")"
   :why-hidden "Απόλυτο μονοπάτι εκτός institution γίνεται δεκτό — ο έλεγχος δεν είναι containment check."
   :evidence "systems/orchestrator-epistemic/deploy-epistemic.lisp:L430-L442")
  (:path "Ταυτότητα απόφασης από το ΟΝΟΜΑ ΑΡΧΕΙΟΥ όταν το OCR δεν διαβάζει τον σφραγισμένο αριθμό"
   :trigger "Απουσία regex «Αριθμός N/ΕΕΕΕ» στο κείμενο και ύπαρξη «N_ΕΕΕΕ» στο filename"
   :why-hidden "Δεύτερη, ασθενέστερη πηγή αλήθειας· εκτυπώνεται (◌) αλλά δεν αποτυπώνεται σε μόνιμη κατάσταση."
    :evidence "systems/orchestrator-cli/decisions.lisp:L192-L204")
  (:path "Ολομέλεια πυλών εκτός συντάγματος"
   :trigger "--gates"
   :why-hidden "Οι 25 πύλες καλούνται απευθείας από το *commands* hash-table· ο χρήστης βλέπει «ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ» αλλά καμία δεν πέρασε από το execute-command."
   :evidence "systems/orchestrator-cli/gates-runner.lisp:L28-L37")
  (:path "Συνταγματική παράκαμψη μέσω περιβάλλοντος"
   :trigger "LAWMAX_OVERRIDE=<όνομα-εντολής> + LAWMAX_OVERRIDE_REASON=…, ή --force + LAWMAX_OVERRIDE_REASON"
   :why-hidden "Δεν είναι εγγεγραμμένη εντολή· η οδηγία εμφανίζεται μόνο στο κείμενο της άρνησης· η καταγραφή στη βιογραφία μπορεί να αποτύχει σιωπηλά."
   :evidence "systems/orchestrator-cli/constitutional-dispatch.lisp:L37-L47,L71-L74")
  (:path "Αποστολή της ερώτησης του χρήστη σε εξωτερικό LLM endpoint"
   :trigger "LAWMAX_ADVISOR_URL ορισμένο ΚΑΙ κανένας συμβολικός ταξινομητής δεν πιάνει την είσοδο"
   :why-hidden "Δεν υπάρχει flag στη γραμμή εντολών· ενεργοποιείται από μεταβλητή περιβάλλοντος στο install-advisor!· η ίδια η ερώτηση φεύγει αυτούσια στο δίκτυο· καμία ρητή ρύθμιση επαλήθευσης TLS."
   :evidence "systems/orchestrator-cli/advisor.lisp:L154-L198")
  (:path "Σύζευξη κλειδιών υπογραφής δικηγόρου από το περιβάλλον στο startup"
   :trigger "REVIEW_SIGNING_KEY / REVIEW_SIGNER_ID / REVIEW_VERIFY_KEY"
   :why-hidden "Γίνεται μέσα στο main πριν από κάθε dispatch· η καθαρή έδρα orchestrator.review δεν διαβάζει env, οπότε η προέλευση του κλειδιού δεν φαίνεται από εκεί."
   :evidence "systems/orchestrator-cli/main.lisp:L2483-L2496")
  (:path "Αλλαγή προφίλ ιχνών που καθορίζει αν επιτρέπεται έμπιστη legal-critical έξοδος"
   :trigger "ORCHESTRATOR_TRACE_PROFILE=off|minimal|legal-critical|full-debug"
   :why-hidden "Καθορίζει το require-provenance-or-untrusted κάθε legal-critical πύλης· άγνωστη τιμή αγνοείται με προειδοποίηση στο stderr και κρατιέται η προηγούμενη."
   :evidence "systems/orchestrator-cli/main.lisp:L2500-L2516 · systems/orchestrator-cli/cli-util.lisp:L251-L260")
  (:path "Ανακατεύθυνση του καταλόγου μόνιμης κατάστασης"
   :trigger "STATE_DIR (και FEK_STATE_FILE για τον legacy cursor)"
   :why-hidden "Μετακινεί lessons.jsonl και όλους τους cursors έξω από το bind-mounted deployment/state/."
   :evidence "systems/orchestrator-cli/cli-util.lisp:L213-L228")
  (:path "Εκτέλεση εντολών μητρώου από το δημόσιο HTTP /cmd"
   :trigger "GET /cmd?name=--auto-update (ή --failures) στη θύρα του serve-corpus"
   :why-hidden "Παρακάμπτει resolve-command + σύνταγμα· χωρίς LAWMAX_CREATOR_TOKEN κάθε πελάτης περνά τον έλεγχο ταυτότητας."
   :evidence "systems/orchestrator-cli/main.lisp:L784-L789,L825-L850")
  (:path "Ανακατεύθυνση/επανακλείδωμα των golden αποτυπωμάτων"
   :trigger "GOLDEN_DIR=<κατάλογος> (και GOLDEN_WRITE=1 στο --verify-corpus)"
   :why-hidden "Ο ratchet συγκρίνει και «αποδεικνύει read-only» πάνω σε ΟΠΟΙΟΝ κατάλογο δείχνει το env· η ίδια ανάλυση μονοπατιού είναι γραμμένη δύο φορές."
   :evidence "systems/orchestrator-cli/golden-gate.lisp:L48-L57,L99-L107 · systems/orchestrator-cli/main.lisp:L1588-L1598,L1611-L1616")
  (:path "Παράλειψη ολομέλειας πυλών στον «πλήρη κύκλο»"
   :trigger "AUTO_UPDATE_GATES=0 · AUTO_UPDATE_FETCH=0 · AUTO_UPDATE_PUBLISH=1"
   :why-hidden "Τυπώνεται «[7/7] Πύλες: ΠΑΡΑΛΕΙΦΘΗΚΑΝ» αλλά η τελική ετυμηγορία μπορεί να είναι rc=0 («όλα καθαρά») χωρίς καμία πύλη να έχει τρέξει."
   :evidence "systems/orchestrator-cli/main.lisp:L1311-L1313,L1351-L1368"))

 :duplicate-seats
 ((:concept "ανάγνωση κειμένου PDF"
   :seats ("systems/orchestrator-cli/decisions.lisp:L173 (extract-text-any)"
           "systems/orchestrator-cli/main.lisp:L174 (extract-text-from-pdf)"
           "systems/orchestrator-cli/ingestion-commands.lisp:L294,L431 (find-symbol EXTRACT-TEXT-FROM-PDF)"
           "systems/orchestrator-engine-sbcl/adapters/pdf-adapter.lisp:L2144"))
  (:concept "διαθεσιμότητα OCR"
   :seats ("source/pdf-authority.lisp:L1386 (ocr-available-p — η έδρα)"
           "source/pdf-authority.lisp:L1403 (extract-text-via-ocr, εσωτερικός επανέλεγχος)"
            "systems/orchestrator-cli/decisions.lisp:L181 (τρίτος, ανεξάρτητος επανέλεγχος μόνο για διατύπωση μηνύματος)"))
  (:concept "εκτέλεση της σουίτας δοκιμών (ταυτόσημα σώματα)"
   :seats ("systems/orchestrator-tests/suite.lisp:L32" "systems/orchestrator-tests/suite.lisp:L69"))
  (:concept "απόδειξη ντετερμινισμού μέσα στην ίδια εικόνα"
   :seats ("systems/orchestrator-tests/reproducibility/hash-stability-test.lisp:L8"
           "systems/orchestrator-tests/unit/test-ai-core.lisp:L417"
           "systems/orchestrator-tests/unit/test-ai-core.lisp:L441"
           "systems/orchestrator-tests/integration/ai-export-integration-test.lisp:L192"))
  (:concept "υλική πύλη release (validate-epistemic-stage) — ΔΥΟ κλήσεις, ΔΙΑΦΟΡΕΤΙΚΗ επιβολή"
   :seats ("systems/orchestrator-epistemic/deploy-epistemic.lisp:L1097 (error)"
           "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L157 (log:warn)"))
  (:concept "συνάρτηση με όνομα deploy-epistemic-stage σε δύο πακέτα/αρχεία"
   :seats ("systems/orchestrator-epistemic/deploy-epistemic.lisp:L974 (articles base-output-dir &key)"
           "systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp:L30 (context)"))
  (:concept "καταγραφή σε log μέσα στο πακέτο orchestrator.cli"
   :seats ("systems/orchestrator-cli/log.lisp:L6-L15 (log-info/log-warn/log-error μακροεντολές)"
           "systems/orchestrator-cli/package.lisp:L8 (local-nickname log → orchestrator.logging, χρήση log:info/log:warn)"))
  (:concept "ανάγνωση YAML διαμόρφωσης"
   :seats ("systems/orchestrator-cli/config-loader.lisp:L6 (load-config, cl-yaml:parse)"
           "systems/orchestrator-cli/decisions.lisp:L224-L229 (%decision-fetch-template, cl-yaml:parse)"
           "systems/orchestrator-cli/release-authority.lisp:L99 (orchestrator.spec:ensure-config-loaded)"))
  (:concept "παράκαμψη της δρομολόγησης μέσω απευθείας κλήσης χειριστή εντολής"
   :seats ("systems/orchestrator-cli/gates-runner.lisp:L29 (funcall (gethash name *commands*) nil)"
           "systems/orchestrator-cli/main.lisp:L846 (funcall (find-command name) nil)"
           "systems/orchestrator-cli/main.lisp:L2537 (execute-command — η ΔΗΛΩΜΕΝΗ ΜΙΑ έδρα)"))
  (:concept "ανάλυση μονοπατιού golden (GOLDEN_DIR/ORCHESTRATOR_ROOT) — δύο αντίγραφα"
   :seats ("systems/orchestrator-cli/golden-gate.lisp:L52-L55" "systems/orchestrator-cli/main.lisp:L1593-L1597"))
  (:concept "HTTP επιφάνεια δημιουργού με ΑΣΥΜΜΕΤΡΕΣ φραγές γύρω από την ΙΔΙΑ έδρα ταυτότητας"
   :seats ("systems/orchestrator-cli/cockpit.lisp:L258-L268 (Host allowlist + CSRF header + key)"
           "systems/orchestrator-cli/main.lisp:L803-L824 (/ask — μόνο key)"
           "systems/orchestrator-cli/main.lisp:L825-L850 (/cmd — μόνο key + whitelist)"))
  (:concept "χρόνος"
   :seats ("orchestrator.time:require-deterministic-time (η δηλωμένη έδρα — deploy-epistemic.lisp:L975)"
           "systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp:L91 (get-universal-time)"
           "systems/orchestrator-gr-syntagma/parsing.lisp:L138,L193,L232,L242,L251,L1045"
           "systems/orchestrator-cli/main.lisp:L769")))

 :unknowns
 ("Δεν έχω ακόμη διαβάσει 170/175 αρχεία της συστάδας."
  "Ο admission kernel της authority-v2 είναι εκτός συστάδας — η επιβολή του OS ορίου δεν επαληθεύεται από εδώ."
  "Αν το ORCHESTRATOR_DEV_MODE ελέγχεται/απαγορεύεται από κάποια πύλη CI: :unknown σε αυτό το στάδιο.")

 :remaining
 ("orchestrator-cli/ (35 αδιάβαστα): approval-policy architecture-gate autonomy-missions capability-gate case-workspace cockpit cognition-legal cognition-self component-gate content-validation contract-gate deontic-gate dialogue-gate draft-commands event-gate evolution-gate external-benchmark-gate fluid-gate generation-gate golden-gate graph-import inference-gate ingestion-commands iq-gate jurisprudence-judge legal-eval memory-commands provenance-gate self-extension self-reflection subsumption-commands understanding-learning verify-truth-gate version-graph-import· επίσης main.lisp/decisions.lisp/advisor.lisp διαβάστηκαν ΜΕΡΙΚΩΣ"
  "orchestrator-epistemic/ (15): artifact-census authority(package) lineage-authority merkle-tree meta-ontology negation-layer package primary-anchor release-manifest release-spine shacl-shapes stability-policy temporal-proof vocabularies shapes/citation-shape.ttl shapes/manifest-validation-extended.ttl"
  "orchestrator-engine-sbcl/ (24 αδιάβαστα)"
  "orchestrator-omega-modules/ (25) · orchestrator-model/ (8) · orchestrator-spec/ (8) · orchestrator-core/ (8) · orchestrator-ai-core/ (7) · orchestrator-gr-syntagma/ (7) · orchestrator-meta/ (7) · orchestrator-omega.asd"))
