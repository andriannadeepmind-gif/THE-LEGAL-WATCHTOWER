(:lawmax-phase1a-cluster/1
 :cluster "systems"
 :status :partial
 :files-read 5

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
   :evidence "systems/orchestrator-cli/decisions.lisp:L168-L183 · source/pdf-authority.lisp:L1386-L1441"))

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
   :evidence "systems/orchestrator-cli/decisions.lisp:L192-L204"))

 :duplicate-seats
 ((:concept "ανάγνωση κειμένου PDF"
   :seats ("systems/orchestrator-cli/decisions.lisp:L173 (extract-text-any)"
           "systems/orchestrator-cli/main.lisp:L174 (extract-text-from-pdf)"
           "systems/orchestrator-cli/ingestion-commands.lisp:L294,L431 (find-symbol EXTRACT-TEXT-FROM-PDF)"
           "systems/orchestrator-engine-sbcl/adapters/pdf-adapter.lisp:L2144"))
  (:concept "διαθεσιμότητα OCR"
   :seats ("source/pdf-authority.lisp:L1386 (ocr-available-p — η έδρα)"
           "source/pdf-authority.lisp:L1403 (extract-text-via-ocr, εσωτερικός επανέλεγχος)"
           "systems/orchestrator-cli/decisions.lisp:L181 (τρίτος, ανεξάρτητος επανέλεγχος μόνο για διατύπωση μηνύματος)")))

 :unknowns
 ("Δεν έχω ακόμη διαβάσει 170/175 αρχεία της συστάδας."
  "Ο admission kernel της authority-v2 είναι εκτός συστάδας — η επιβολή του OS ορίου δεν επαληθεύεται από εδώ."
  "Αν το ORCHESTRATOR_DEV_MODE ελέγχεται/απαγορεύεται από κάποια πύλη CI: :unknown σε αυτό το στάδιο.")

 :remaining
 ("orchestrator-cli/: 47 αρχεία (main.lisp, release-authority.lisp, advisor.lisp, cognition-self.lisp, self-reflection.lisp, όλες οι *-gate.lisp, κλπ)"
  "orchestrator-epistemic/: 15 αρχεία (artifact-census, lineage-authority, merkle-tree, meta-ontology, negation-layer, package, primary-anchor, release-manifest, release-spine, shacl-shapes, stability-policy, temporal-proof, vocabularies, shapes/*.ttl)"
  "orchestrator-tests/: 13 αρχεία (ΔΕΥΤΕΡΗ ΕΔΡΑ ΔΟΚΙΜΩΝ)"
  "orchestrator-engine-sbcl/: 25 · orchestrator-omega-modules/: 25 · orchestrator-model/: 8 · orchestrator-spec/: 8 · orchestrator-core/: 8 · orchestrator-ai-core/: 7 · orchestrator-gr-syntagma/: 7 · orchestrator-meta/: 7 · orchestrator-omega.asd"))
