(:lawmax-phase1a-cluster/1
 :cluster "source"
 :status :partial
 :files-read 52
 :files-total 133
 :read-since-checkpoint-2 ("asn1-der.lisp" "circuit-breaker.lisp" "component-scan.lisp"
   "consolidation-proof.lisp" "consolidation-feed.lisp" "corpus-provenance.lisp" "corpus-diff.lisp"
   "consolidation-engine.lisp" "consolidation-bridge.lisp" "corpus-fingerprint.lisp"
   "corpus-intelligence.lisp" "corpus-search.lisp" "paths.lisp" "http-server.lisp"
   "jws-authority.lisp" "x509-authority.lisp" "timestamp-authority.lisp" "memory.lisp"
   "proposals.lisp" "self-history.lisp" "introspection.lisp" "what-if.lisp" "self-model.lisp"
   "review-queue.lisp")
 :read-so-far ("cognition.lisp" "safe-read.lisp" "merkle-authority.lisp" "proof-carrying.lisp"
               "deterministic-time.lisp" "journal.lisp" "self-constitution.lisp" "document-fetch.lisp"
               "constitutional-gate.lisp" "write-authority.lisp" "hash-authority.lisp"
               "institution.lisp" "config.lisp" "authority-proof-bundle.lisp" "version-graph.lisp"
               "amendment-extractor.lisp" "pdf-authority.lisp" "adoption-decision.lisp"
               "anomaly-detection.lisp" "ast-gate.lisp" "autonomy.lisp" "components.lisp"
               "archive-authority.lisp" "capability-api.lisp" "capability-registry.lisp"
               "contracts.lisp" "canonical-representation.lisp" "canonical-uris.lisp")

 :capabilities
 ((:name "data-only s-expression deserialization (ΜΙΑ έδρα)"
   :presence :present
   :domain "Ανάγνωση αρχείων/strings που περιέχουν s-expressions ως ΔΕΔΟΜΕΝΑ (όχι κώδικα)."
   :assumptions "Ο caller δίνει path/string· τα data stores είναι keywords/strings/numbers/lists/t/nil."
   :guarantees "*read-eval* NIL· wholesale #-deny readtable (+ ` , ' deny)· pre-scan βάθους+atoms ΠΡΙΝ τον reader· byte-cap· *package* :keyword σταθερό· double-float σταθερό· one-form EOF law· ΟΛΙΚΟΣ %data-only-p έλεγχος στο ΑΠΟΤΕΛΕΣΜΑ."
   :failure-semantics "(values nil <status>) με ονομαστικό status ∈ {:empty :trailing :too-large :too-deep :too-many-atoms :unreadable :disallowed-symbol :resource-exhausted}. Καμία σιωπή."
   :operating-model "Καθαρή συνάρτηση· μηδέν global μετάλλαξη (μόνο dynamic let)· καμία εξάρτηση πλην :cl."
   :materiality "Ο τοίχος κατά RCE από κάθε data store του συστήματος."
   :evidence "safe-read.lisp:39-349")

  (:name "canonical data-only serialization (write side)"
   :presence :present
   :domain "FORM → string που το read-data-string ξαναδιαβάζει ακέραιο."
   :assumptions "Το form είναι data-only."
   :guarantees "%data-only-p ΠΡΙΝ την εγγραφή (fail-closed)· *print-readably* NIL (αποφυγή #A(...) literals)· keyword package· double-float· χωρίς pretty/circle· byte-cap στο αποτέλεσμα."
   :failure-semantics "safe-read-error (σφάλμα, όχι NIL) σε μη-data-only form ή υπέρβαση cap."
   :operating-model "Καθαρή συνάρτηση."
   :materiality "Συμμετρία γραφής/ανάγνωσης — «ό,τι γράφεται μπορεί να διαβαστεί»."
   :evidence "safe-read.lisp:312-339")

  (:name "RFC 6962/9162 Merkle (leaf/node domain separation, unbalanced split)"
   :presence :present
   :domain "Δέντρα Merkle: ρίζα, inclusion path, consistency proof, επαλήθευση."
   :assumptions "hashes σε μορφή 'sha256:HEX'· η ΣΕΙΡΑ των φύλλων είναι μέρος του commitment."
   :guarantees "leaf=SHA256(0x00‖bytes), node=SHA256(0x01‖raw(L)‖raw(R))· ΟΧΙ duplicate-last (κλάση CVE-2012-2459 δομικά αδύνατη)· verify-consistency fail-closed ακόμη και σε κακοσχηματισμένα hashes."
   :failure-semantics "verify-inclusion/verify-consistency ⇒ NIL σε κάθε απόκλιση· merkle-tree-hash σε κενό εύρος ⇒ error· inclusion-path σε out-of-range index ⇒ error."
   :operating-model "Καθαρές συναρτήσεις πάνω σε ironclad."
   :materiality "Ο σκελετός κάθε απόδειξης του ιδρύματος."
   :evidence "merkle-authority.lisp:54-235")

  (:name "proof-carrying provision (text→leaf→path→root→JWS)"
   :presence :present
   :domain "Ανά-διάταξη φορητή απόδειξη + corpus-level υπογεγραμμένος anchor + δημόσιος verifier σε JSON."
   :assumptions "Η υπογραφή απαιτεί ΦΟΡΤΩΜΕΝΟ orchestrator.jws-authority (αναζήτηση με find-symbol)."
   :guarantees "verify-provision-proof: αλλοιωμένο byte ⇒ :text-hash-mismatch· πλαστό path ⇒ :inclusion-failed· verify-full-chain ελέγχει ΚΑΙ root-match ΚΑΙ υπογραφή· ΡΗΤΟ trust_status ('signed'|'unsigned-explicit') μέσα στο JSON· +max-path-length+ 64 (DoS bound)."
   :failure-semantics "(values nil reason) ονομαστικά· κενό corpus ⇒ ΣΦΑΛΜΑ empty-corpus-publication (ΟΧΙ σιωπηλό no-op)."
   :operating-model "Καθαρό/ντετερμινιστικό· γράφει αρχεία JSON στο output-dir."
   :materiality "Το «trust root» που τρίτοι επαληθεύουν χωρίς να μας εμπιστεύονται."
   :evidence "proof-carrying.lisp:50-295")

  (:name "append-only chained journal (single-writer, receipts)"
   :presence :present
   :domain "Ημερολόγια plist-ανά-γραμμή με SHA-256 αλυσίδα (βιογραφία, προτάσεις, επεισόδια, version-graph)."
   :assumptions "Ένα plist ανά record· :at σε canonical UTC ISO-8601 σταθερού πλάτους· SBCL (sb-posix/sb-alien/flock)."
   :guarantees "thread mutex + flock(2) LOCK_EX ανά path (cross-process single writer)· compare-and-append (STALE-CHAIN-LINK πριν γραφτεί οτιδήποτε)· προ-εγγραφικός έλεγχος σειριοποίησης (UNSERIALIZABLE-RECORD)· μονοτονία transaction-time (NON-MONOTONIC-TRANSACTION-TIME)· fsync fail-closed (SYNC-FAILURE ⇒ ΠΟΤΕ :durable)· write-file-atomic = tmp+fsync+rename+fsync(dir)."
   :failure-semantics "receipt :durability ∈ {:durable :sync-failed :failed-verification :ephemeral-replica :degraded-memory-only}· require-durable! υψώνει NOT-DURABLE. Κολοβή γραμμή ⇒ ΔΗΛΩΝΕΤΑΙ στο *error-output* και προσπερνιέται."
   :operating-model "Stateful (in-memory cache ανά path)· side-effects στον δίσκο."
   :materiality "Η μοναδική έδρα «γράφτηκε πραγματικά;» όλου του θεσμού."
   :evidence "journal.lisp:104-576")

  (:name "constitutional gate (κανόνας-μητρώο + ρητή παράκαμψη)"
   :presence :present
   :domain "Κρίση «επιτρέπεται αυτή η πράξη;» πριν από εκτέλεση εντολής."
   :assumptions "Οι κανόνες δηλώνονται από τους καταναλωτές (open/closed)· η ΜΕΣΟΛΑΒΗΣΗ γίνεται αλλού (CLOS method-combination στον καταναλωτή)."
   :guarantees "Πρώτη παράβαση ⇒ (values nil article reason id)· η παράκαμψη απαιτεί ΚΑΙ εμβέλεια (--force ή LAWMAX_OVERRIDE=<cmd>) ΚΑΙ αιτιολογία (LAWMAX_OVERRIDE_REASON)."
   :failure-semantics "ΣΦΑΛΜΑ ΜΕΣΑ ΣΕ ΚΑΝΟΝΑ ⇒ FAIL-OPEN (ο κανόνας θεωρείται ότι επιτρέπει)."
   :operating-model "Global mutable *rules* list· καμία λογική πεδίου εδώ."
   :materiality "Ο δηλωμένος «υπέρτατος φραγμός»."
   :evidence "constitutional-gate.lisp:22-71")

  (:name "deterministic time"
   :presence :present
   :domain "Ενιαία πηγή χρονοσφραγίδων για αναπαραγώγιμα artifacts."
   :assumptions "SOURCE_DATE_EPOCH ή ρητή κλήση configure-deterministic-time."
   :guarantees "require-deterministic-time ΣΦΑΛΛΕΙ αν δεν είναι ενεργή η ντετερμινιστική λειτουργία (καμία σιωπηλή wall-clock)· (now :source …) απαιτεί ΡΗΤΟ source."
   :failure-semantics "ΜΙΚΤΗ: require-deterministic-time = error· (now :source :deterministic) = ΣΙΩΠΗΛΟ fallback σε get-universal-time."
   :operating-model "Global μεταβλητές *deterministic-mode*/*fixed-timestamp*· αυτο-αρχικοποίηση στο LOAD από env."
   :materiality "Κάθε byte-identical δημοσίευση εξαρτάται από εδώ."
   :evidence "deterministic-time.lisp:52-220")

  (:name "cognitive pipeline (5 στάδια, LLM σύμβουλος ΕΚΤΟΣ εμπιστοσύνης)"
   :presence :present
   :domain "Φυσική γλώσσα → frame → πλάνο → επαληθευμένα βήματα → απάντηση."
   :assumptions "*advisor* είναι κλείσιμο (purpose input)→spec|nil· nil ⇒ καθαρά συμβολική λειτουργία."
   :guarantees "Ο σύμβουλος ΠΡΟΤΕΙΝΕΙ μόνο αποδόμηση (στάδιο 1)· τα στάδια 2/3/5 είναι CLOS generics· απόρριψη αυτο-κριτικής ΔΗΛΩΝΕΤΑΙ στην απάντηση· κενό προσχέδιο ⇒ NIL (τίμια άγνοια)."
   :failure-semantics "decompose ⇒ nil ⇒ (values nil cog): «δεν αποδομήθηκε»."
   :operating-model "Global *advisor*/*classifiers*· synchronized working-memory."
   :materiality "Το σημείο όπου LLM αγγίζει το σύστημα."
   :evidence "cognition.lisp:62-184")

  (:name "εξωτερική λήψη εγγράφου (ΦΕΚ/PDF/DOCX) με SSRF φρουρό"
   :presence :present
   :domain "Κατέβασμα ΦΕΚ από public Azure blob, PDF/DOCX από αυθαίρετο URL, ή μέσω εξωτερικού shell fetcher."
   :assumptions "drakma vendored· ο operator ορίζει το fetch-command· {{out}} placeholder."
   :guarantees "Έλεγχος magic bytes (%PDF- / PK\\03\\04) — anti-bot HTML ΑΠΟΡΡΙΠΤΕΤΑΙ· redirects ακολουθούνται ΧΕΙΡΟΚΙΝΗΤΑ (≤5) με SSRF έλεγχο ΑΝΑ HOP· loopback επιτρέπεται μόνο υπό dynamic *allow-loopback-fetch* (όχι env flag)."
   :failure-semantics "(values nil status) ονομαστικά· ΠΟΤΕ throw."
   :operating-model "Δίκτυο + εκτέλεση /bin/sh."
   :materiality "Το μοναδικό σημείο εισόδου εξωτερικού περιεχομένου στο corpus."
   :evidence "document-fetch.lisp:92-323")

  (:name "system self-constitution (ανάγνωση + μετρήσιμη αποστολή)"
   :presence :present
   :domain "deployment/SYSTEM-CONSTITUTION.sexp: ποιον υπηρετεί, άρθρα, αποστολές."
   :assumptions "Η θέση επιλύεται στο RUNTIME μέσω orchestrator.paths:institution-dir."
   :guarantees "SHA-256 ταυτότητα· άκυρο κείμενο ⇒ κρατιέται το προηγούμενο ΚΑΙ δηλώνεται· αποστολή χωρίς εγγεγραμμένη μέτρηση δηλώνεται ΑΜΕΤΡΗΤΗ (ποτέ «εκπληρωμένη»)."
   :failure-semantics "Απουσία αρχείου ⇒ *constitution* μένει NIL, describe επιστρέφει 1."
   :operating-model "Global *constitution* + *measures* registry (αντίστροφη εξάρτηση: ο μετρητής εγγράφεται)."
   :materiality "Η δηλωμένη ταυτότητα του συστήματος."
   :evidence "self-constitution.lisp:29-132")

  (:name "generic content hash authority"
   :presence :present
   :domain "Αυθαίρετο περιεχόμενο → hex hash με ΡΗΤΟ algorithm."
   :assumptions "Δηλωμένη ΑΚΡΙΒΗΣ εμβέλεια: ΔΕΝ είναι η μόνη hash — protocol-local hashes (JWS/X.509/TSA/Merkle/keccak) ζουν αλλού, με μητρώο deployment/verify/hash-seat-registry.sexp."
   :guarantees "Σφάλμα αν λείπει/είναι άγνωστο το :algorithm."
   :failure-semantics "error (fail-fast)."
   :operating-model "Καθαρή συνάρτηση."
   :materiality "Content-addressing."
   :evidence "hash-authority.lisp:11-59")

  (:name "RDF write authority scope"
   :presence :present
   :domain "Εγγραφή TTL/RDF περιεχομένου με ρητή αυθεντία (:canonical|:provenance)."
   :assumptions "ΔΗΛΩΝΕΙ ότι είναι «the ONLY authorized write function for RDF content»."
   :guarantees "Σφάλμα χωρίς :authority· σφάλμα σε scope violation· σφάλμα σε φωλιασμένο with-write-authority."
   :failure-semantics "error (fail-fast)."
   :operating-model "Dynamic *current-write-authority*."
   :materiality "Διαχωρισμός canonical/provenance γράφων."
   :evidence "write-authority.lisp:12-73")

  (:name "institution ontology (Ίδρυμα + ρόλοι)"
   :presence :present
   :domain "Δηλωμένη θεσμική ταυτότητα: ένα Ίδρυμα, ρόλοι/αίθουσες."
   :assumptions "Οι δηλώσεις γίνονται από αλλού (declare-institution!/declare-role!)."
   :guarantees "Idempotent αντικατάσταση κατά όνομα· «δεν υπάρχει δεύτερο Ίδρυμα» (ένα global)."
   :failure-semantics :unknown
   :operating-model "Global mutable structs."
   :materiality "Ονοματολογία/ταυτότητα, όχι μηχανισμός επιβολής."
   :evidence "institution.lisp:26-61")

  (:name "YAML global configuration"
   :presence :present
   :domain "Global key/value config από configs/constitution.yaml."
   :assumptions "Δηλώνει «YAML is single source of truth· NO hardcoded URIs»."
   :guarantees "load-default-config ΣΦΑΛΛΕΙ αν λείπει το configs/constitution.yaml."
   :failure-semantics "load-config: σφάλμα ⇒ WARN + NIL (σιωπηλή αποτυχία στο επίπεδο της συνάρτησης)· ο καλών load-default-config την μετατρέπει σε error."
   :operating-model "Global mutable hash-table· relative path (εξαρτάται από cwd)."
   :materiality "Πηγή canonical URIs."
   :evidence "config.lisp:7-49")

  (:name "hermetic fail-closed επαληθευτής αλυσίδας εξουσίας (APB)"
   :presence :present
   :domain "Επαλήθευση release bundle: JWS release-statement, census, receipt-set, tlog inclusion, RFC-3161 TSR, owner Ed25519 delegation/revocation, consistency vs consumer checkpoint."
   :assumptions "ΟΛΑ τα σημεία εμπιστοσύνης δίνονται ΕΞΩΘΕΝ (trusted owner JWK ή RFC-7638 thumbprint, pinned TSA CA path, known-revocations, policy) — ΠΟΤΕ από το bundle."
   :guarantees "Κλειστή διατεταγμένη taxonomy βαθμίδων· κάθε κατηγόρημα ανεξάρτητο + fail-closed (εξαίρεση = αποτυχία με ονομαστικό λόγο)· ενριξιμότητα canonical δήλωσης (separators #x1e/#x1f απαγορευμένοι, length-prefixed verifier-set)· cross-type replay αδύνατο (ένα tag ανά τύπο)· delegation ελέγχεται στο genTime ΤΟΥ TSR, όχι σε caller clock· anti-rollback (:min-tlog-leaf-index, :gentime-floor)· offset-bearing χρόνοι ΑΠΟΡΡΙΠΤΟΝΤΑΙ."
   :failure-semantics "apb-verdict με :awarded-tier = η ΑΝΩΤΑΤΗ με ΟΛΟ το σύνολο περασμένο· :reasons ονομαστικά· :delegation-state ∈ {:active :revoked :expired :not-yet :absent :stale :floor-unparseable}."
   :operating-model "Καθαρή συνάρτηση πάνω σε bundle + εξωτερικά pins."
   :materiality "Η δεύτερη βαθμίδα εμπιστοσύνης — τι μπορεί να αποδείξει τρίτος."
   :evidence "authority-proof-bundle.lisp:295-658")

  (:name "διτεμπορικός γράφος εκδόσεων (νομικός χρόνος)"
   :presence :present
   :domain "Αμετάβλητοι κόμβοι-κείμενα × typed ακμές τροποποίησης × καθεστωτικές ακμές × αιρέσεις έναρξης ισχύος, με [valid-from,valid-until) × [recorded-from,recorded-until)."
   :assumptions "Το journal είναι η αυθεντία· η προβολή μνήμης ξαναχτίζεται με ΠΛΗΡΕΣ replay· legal-date/legal-instant typed (γνήσιος γρηγοριανός έλεγχος, ASCII-only ψηφία)."
   :guarantees "G1 replay-then-append (ασυμφωνία ⇒ καραντίνα)· G2 ολική διάταξη· G3 payload-hash + chain ανά γραμμή (αλλοίωση ΟΠΟΙΟΥΔΗΠΟΤΕ πεδίου σπάει το replay)· G5 retract αντί διαγραφής· καραντίνα ΩΣ ΤΥΠΟΣ (αόρατη στην επιλογή)· μη υποστηριζόμενες πράξεις ⇒ ΡΗΤΟ :unsupported-op· scope :unknown ⇒ typed SCOPE-UNCERTAIN ή ρητό :conservative με μη-αφαιρέσιμο analytical marker."
   :failure-semantics "invalid-edge (client) vs journal-corruption (server-integrity) — ΞΕΧΩΡΙΣΤΟΙ τύποι· temporal-uncertainty αντί μαντεψιάς· κενό γνώσης δηλωμένο."
   :operating-model "Stateful προβολή· κάθε πράξη journal-first."
   :materiality "Η απάντηση «τι ίσχυε πότε, κατά τη γνώση του πότε»."
   :evidence "version-graph.lisp:221-1459")

  (:name "deterministic effectivity attestation (χωρίς online κλειδί)"
   :presence :present
   :domain "Πιστοποιητικό ισχύος διάταξης στην τομή (valid-at, known-at) — value-canonical string + sha256."
   :assumptions "Ο anchor είναι OPAQUE τύπος: verified κατασκευάζεται ΜΟΝΟ από release-anchor-for (private constructor)· provisional από δημόσιο make-provisional-anchor."
   :guarantees "Καμία υπογραφή — ο verifier ΑΝΑΠΑΡΑΓΕΙ byte-wise· plist που «μοιάζει» anchored ΔΕΝ γίνεται δεκτό· assurance μέσα στο hash· read-only slots (provisional δεν «βάφεται» verified)."
   :failure-semantics "outcome sum type: resolved | no-version-in-force | not-yet-effective | suspended | scope-uncertain | unknown-provision | uncertain."
   :operating-model "Καθαρή συνάρτηση πάνω στον γράφο."
   :materiality "Το εξαγόμενο πιστοποιητικό προς τρίτους."
   :evidence "version-graph.lisp:2458-2613")

  (:name "ντετερμινιστική εξαγωγή νομοτεχνικών πράξεων από ΦΕΚ"
   :presence :present
   :domain "Κείμενο τροποποιητικού → λίστα πράξεων (:replace-text/:repeal/:insert/:mark-amended) με scope routing."
   :assumptions "Ελληνικοί νομοτεχνικοί τύποι· ο resolver έρχεται από το registry (orchestrator.legal-id) — ΧΩΡΙΣ resolver καμία δρομολόγηση."
   :guarantees "Balanced «…» (καμία περικοπή)· μάσκα παραθέσεων (νέο κείμενο δεν ξαναδρομολογεί)· scope ΑΥΣΤΗΡΑ ενδο-ενοτικό· αυτο-αναφορά σε δικό του άρθρο ⇒ :low + :self-reference· αντίφαση με census ⇒ :identity :contradicted."
   :failure-semantics "Χαμηλής εμπιστοσύνης πράξεις ΑΝΑΓΝΩΡΙΖΟΝΤΑΙ, ποτέ δεν πέφτουν σιωπηλά· μόνο :high αυτο-εφαρμόζεται."
   :operating-model "Καθαρή συνάρτηση (regex/cl-ppcre)· κανένα LLM."
   :materiality "Ο κρίκος «δημοσιευμένο ΦΕΚ → ενοποίηση»."
   :evidence "amendment-extractor.lisp:340-546")

  (:name "PDF text/layout extraction (libpoppler CFFI) + OCR κλιμάκωση"
   :presence :present
   :domain "PDF → κείμενο (plain / header-footer clipped / column-reflowed) και layout graph (spans/lines/blocks/pages)."
   :assumptions "libpoppler-glib φορτώνεται ΤΕΜΠΕΛΙΚΑ στο runtime (όχι στο save-core)· OCR απαιτεί pdftoppm+tesseract+ell."
   :guarantees "extract-text-any επιστρέφει ΚΑΙ την ΠΗΓΗ (:text-layer|:ocr|:none)· ocr-available-p ρητό· XY-cut reflow καθαρή/δοκιμασμένη συνάρτηση."
   :failure-semantics "typed conditions (pdf-not-found/pdf-open-error/pdf-layout-error)· αλλά ανά-σελίδα σφάλμα layout ⇒ ΚΕΝΗ σελίδα με warn."
   :operating-model "FFI + εξωτερικές διεργασίες + /tmp."
   :materiality "Η μοναδική ανάγνωση αυθεντικών ΦΕΚ bytes."
   :evidence "pdf-authority.lisp:381-1439")

  (:name "capability registry + transport-agnostic API projection"
   :presence :present
   :domain "Δηλωτικό συμβόλαιο ανά δυνατότητα (name/params/result/trust/proof/fn)· HTTP/MCP/CLI = προβολές."
   :assumptions "Κλειστό +param-types+ = {:string :keyword :any :integer :boolean}."
   :guarantees "ΝΟΜΟΣ ΜΙΑΣ ΕΔΡΑΣ: επανεγγραφή από ΑΛΛΟ αρχείο ⇒ capability-seat-collision· ανώνυμο runtime site ΔΕΝ επαναδιεκδικεί· :trust επιβάλλεται ΔΙΠΛΑ (pre-check + invoke)· coercion fail-closed· ΚΑΝΕΝΑ intern σε μη-έμπιστη είσοδο (find-symbol μόνο) — intern-DoS δομικά αδύνατο."
   :failure-semantics "403/404/400/500 ονομαστικά· καμία εξαίρεση δεν διαφεύγει."
   :operating-model "Global hash-tables (*capabilities*, *capability-owners*)."
   :materiality "Το σημείο όπου «κανένα LLM στο trusted path» γίνεται μηχανισμός."
   :evidence "capability-registry.lisp:40-207 · capability-api.lisp:37-147")

  (:name "μητρώο συμβολαίων + μηχανικός επικυρωτής"
   :presence :present
   :domain "Δηλωμένες υποσχέσεις ανά συνάρτηση/πρωτόκολλο/εντολή με legal-critical/policy-level/tests/audit/rollback."
   :assumptions "Τα κατηγορήματα ύπαρξης (capability/role/test) δίνονται ΑΠΟ ΤΟΝ ΚΑΛΟΥΝΤΑ (διαχωρισμός στρωμάτων)."
   :guarantees "legal-critical ΧΩΡΙΣ policy-level/tests ⇒ παράβαση· με side-effects ΧΩΡΙΣ audit/rollback ⇒ παράβαση· ανύπαρκτη ικανότητα/ρόλος/τεστ ⇒ παράβαση."
   :failure-semantics "Λίστα παραβάσεων (strings)· ΔΕΝ μπλοκάρει από μόνο του — ο καλών (πύλη) το κάνει."
   :operating-model "Global διατεταγμένη λίστα *contracts*."
   :materiality "Η μηχανική μορφή των υποσχέσεων."
   :evidence "contracts.lisp:43-167")

  (:name "canonical JSON (RFC 8785 JCS) + canonical vector bytes + canonical ids"
   :presence :present
   :domain "Ντετερμινιστική σειριοποίηση για hashing/υπογραφή· IEEE-754 binary32 little-endian για embeddings· περιεχομενο-παραγόμενα @id."
   :assumptions "ΔΗΛΩΝΕΙ συμμόρφωση RFC 8785 και «bit-perfect reproducibility across implementations»."
   :guarantees "Ταξινόμηση κλειδιών, χωρίς κενά, πεζά \\u escapes, NaN/Inf → 0.0 στα διανύσματα."
   :failure-semantics "etypecase ⇒ σφάλμα σε μη υποστηριζόμενο τύπο."
   :operating-model "Καθαρές συναρτήσεις."
   :materiality "Κάθε version-hash/edge-hash του version-graph περνά από εδώ (canonical-hash)."
   :evidence "canonical-representation.lisp:91-278")

  (:name "canonical URI sovereignty"
   :presence :present
   :domain "Η ΜΙΑ πηγή όλων των URI (base/eli/corpus/identity/policy/ontology) από configs/constitution.yaml."
   :assumptions "ΚΑΝΕΝΑ default — «If configuration is missing, the system MUST fail hard»."
   :guarantees "Κάθε getter ΣΦΑΛΛΕΙ αν λείπει η ρύθμιση· validate-uri/assert-canonical-uri· ωμός ακέραιος ως ταυτότητα άρθρου εκπέμπει ΟΡΑΤΟ :identity-debt ίχνος."
   :failure-semantics "error (fail-hard)."
   :operating-model "Global hash-table *canonical-config*."
   :materiality "Η μία ταυτότητα του συστήματος στο διαδίκτυο."
   :evidence "canonical-uris.lisp:53-264")

  (:name "αυτόνομος οδηγός αποστολών"
   :presence :present
   :domain "Στόχος + αντικείμενα + βήμα → εκτέλεση με προϋπολογισμό, δρομέα στη μνήμη, στάση σε συστηματική αποτυχία."
   :assumptions "Το ΒΗΜΑ είναι υπεύθυνο να επαληθεύει (ο οδηγός δεν εμπιστεύεται, καταγράφει)."
   :guarantees "Καμία αυτόνομη μετάλλαξη: ό,τι παράγεται πάει σε ΟΥΡΑ ΠΡΟΤΑΣΕΩΝ· N συνεχόμενα σφάλματα ⇒ ΣΤΑΣΗ + αναφορά· ατζέντα κλείνει ΜΟΝΟ όταν καλυφθούν όλα."
   :failure-semantics "Σφάλμα βήματος ⇒ :error μετρημένο και δηλωμένο (όχι σιωπή)."
   :operating-model "Global μητρώο αποστολών· γράφει στη μνήμη/ιστορία."
   :materiality "Το «τρέχει μόνο του» του συστήματος."
   :evidence "autonomy.lisp:26-124")

  (:name "μητρώο συστατικών + γράφος ακμών"
   :presence :present
   :domain "Ταυτότητα κάθε συστατικού (system/file/package/symbol/gate) + ακμές εξάρτησης."
   :assumptions "Η ΚΑΤΑΣΚΕΥΗ ζει στο component-scan — εδώ μόνο ταυτότητες/ακμές."
   :guarantees "Διπλό id ⇒ ΣΦΑΛΜΑ duplicate-component-id (ποτέ σιωπηλή αντικατάσταση)· role NIL = ΟΡΑΤΟ χρέος."
   :failure-semantics "error."
   :operating-model "Global hash-table + λίστα ακμών."
   :materiality "«Ό,τι δεν ταυτοποιείται δεν θεωρείται γνωστό»."
   :evidence "components.lisp:26-98")

  (:name "υποβολή στο Archive.org (Wayback) ως «100-year proof»"
   :presence :spec-only
   :domain "Δημόσια τρίτη μαρτυρία χρονικής ύπαρξης release."
   :assumptions "drakma· δίκτυο."
   :guarantees "ΚΑΜΙΑ επαληθεύσιμη: δεν ελέγχεται HTTP status, δεν εξάγεται το πραγματικό archived URL, δεν επαληθεύεται η αρχειοθέτηση."
   :failure-semantics "Σφάλμα ⇒ plist :status :failed (τίμιο)· ΑΛΛΑ η «επιτυχία» δηλώνεται χωρίς τεκμήριο."
   :operating-model "Δίκτυο, χωρίς SSRF φρουρό, χωρίς ντετερμινιστικό χρόνο."
   :materiality "Δηλώνεται ως απόδειξη χρονικής προτεραιότητας."
   :evidence "archive-authority.lisp:56-159")

  (:name "AST δομική πύλη πάνω στο σερβιρισμένο corpus"
   :presence :present
   :domain "Ανύψωση ενοποιημένου corpus σε legal-ast document-node και εκτέλεση των Layer-4 validators."
   :assumptions "Οι accessors της consolidation επιλύονται ΔΥΝΑΜΙΚΑ (find-symbol) — «defensive pattern» κοινό με άλλα modules."
   :guarantees "Lettered article ids (100Α) μένουν strings (η διακριτότητα διατηρείται)· *require-trace-chain* NIL εδώ (δηλωμένο)."
   :failure-semantics "(values valid-p result) — ΣΥΜΒΟΥΛΕΥΤΙΚΗ πύλη, δεν μπλοκάρει."
   :operating-model "Καθαρό CLOS."
   :materiality "Ζωντανεύει προηγουμένως νεκρούς validators."
   :evidence "ast-gate.lisp:53-127")

  (:name "ανίχνευση ανωμαλιών εξαγωγής ανά άρθρο"
   :presence :present
   :domain "Υπογραφές σφάλματος εξαγωγής: κενό, καθόλου ελληνικά, χαμηλός λόγος ελληνικών, υπολειμματικός θόρυβος (URL/print chrome)."
   :assumptions "Ελληνικό corpus."
   :guarantees "Ντετερμινιστικό, υψηλής ακρίβειας· δεν τιμωρεί σύντομα/καταργημένα άρθρα."
   :failure-semantics "(values ok-p findings) με ονομαστικούς λόγους ανά άρθρο."
   :operating-model "Καθαρή συνάρτηση + find-symbol accessors."
   :materiality "Τροφοδοτεί την ουρά ανθρώπινου ελέγχου."
   :evidence "anomaly-detection.lisp:54-93")

  (:name "ledger υιοθετήσεων (what-if governed adoption)"
   :presence :present
   :domain "Απόφαση υιοθέτησης πρότασης: verdict ∈ {:allowed :requires-human :shadow-only :denied} + διαρκές ledger."
   :assumptions "Η υιοθέτηση ΧΩΡΙΣ what-if είναι «αδύνατη εκ κατασκευής»· απαιτείται δηλωμένο Ίδρυμα, αρχεία, σχέδιο σκιάς."
   :guarantees "Ελλείψεις ⇒ :denied· legal-critical χωρίς άνθρωπο/πολιτική ⇒ :requires-human· require-durable! στο ledger· validate-adoption-records επαληθεύει υπογραφή + ύπαρξη πρότασης."
   :failure-semantics "NOT-DURABLE σφάλμα αν δεν αποθηκεύτηκε."
   :operating-model "Journal ledger + trace emit."
   :materiality "«Τίποτα δεν γίνεται trusted επειδή δουλεύει»."
   :evidence "adoption-decision.lisp:23-132"))

 :authorities
 ((:name "safe-read: η ΜΙΑ έδρα cl:read σε data path"
   :what-it-can-decide "Τι είναι «δεδομένο» (data-only υποσύνολο) και τι απορρίπτεται· τα caps βάθους/atoms/bytes."
   :who-can-invoke "Κάθε module που διαβάζει sexp store (self-constitution, trace-core, legal-ast, component-scan, greek-nlp-core, knowledge-graph, version-graph, legal-subsumption, what-if…)."
   :enforcement :code
   :evidence "safe-read.lisp:152-186")

  (:name "constitutional override (δημιουργός)"
   :what-it-can-decide "Παράκαμψη ΟΠΟΙΟΥΔΗΠΟΤΕ συνταγματικού κανόνα για συγκεκριμένη εντολή."
   :who-can-invoke "Όποιος ελέγχει τα ορίσματα CLI (--force) Ή τις env vars LAWMAX_OVERRIDE + LAWMAX_OVERRIDE_REASON της διεργασίας."
   :enforcement :code
   :evidence "constitutional-gate.lisp:49-71")

  (:name "journal require-durable! («id ⟺ durable»)"
   :what-it-can-decide "Αν μια θεσμική ταυτότητα (πρόταση/υιοθέτηση/πολιτική) επιτρέπεται να εκδοθεί."
   :who-can-invoke "Κάθε ΘΕΣΜΙΚΟΣ συγγραφέας ημερολογίου."
   :enforcement :code
   :evidence "journal.lisp:343-350")

  (:name "publication gate: κενό corpus ΔΕΝ υπογράφεται"
   :what-it-can-decide "Άρνηση δημοσίευσης corpus με leaf_count = 0."
   :who-can-invoke "write-provision-proofs (η μία πύλη δημοσίευσης PCL)."
   :enforcement :code
   :evidence "proof-carrying.lisp:185-207")

  (:name "write-authority: ποιος γράφει RDF και με ποια ιδιότητα"
   :what-it-can-decide ":canonical vs :provenance· φωλιασμένο scope απαγορεύεται."
   :who-can-invoke "Κάθε high-level RDF writer — ΑΛΛΑ μόνο κατά σύμβαση (τίποτα δεν εμποδίζει απευθείας with-open-file)."
   :enforcement :convention
   :evidence "write-authority.lisp:16-51")

  (:name "*advisor* (LLM εκτός εμπιστοσύνης)"
   :what-it-can-decide "ΜΟΝΟ πρόταση αποδόμησης (στάδιο 1)· δεν αποφασίζει απάντηση."
   :who-can-invoke "Όποιος κάνει setf στο orchestrator.cognition:*advisor* (global, χωρίς φρουρό)."
   :enforcement :convention
   :evidence "cognition.lisp:62-89")

  (:name "*allow-loopback-fetch* (SSRF χαλάρωση)"
   :what-it-can-decide "Επιτρέπει loopback fetch — ΜΟΝΟ ως dynamic binding, ΟΧΙ env flag (απόφαση [0036] Δ1)."
   :who-can-invoke "Test harness εντός δυναμικής εμβέλειας."
   :enforcement :code
   :evidence "document-fetch.lisp:228-256")

  (:name "LAWMAX_REPLICA (εφήμερα ημερολόγια)"
   :what-it-can-decide "Αν η διεργασία γράφει ΠΟΤΕ στον δίσκο· διαβάζεται ΜΙΑ φορά στο LOAD (defvar)."
   :who-can-invoke "Το περιβάλλον της διεργασίας."
   :enforcement :os
   :evidence "journal.lisp:180-187")

  (:name "SOURCE_DATE_EPOCH (ντετερμινιστικός χρόνος)"
   :what-it-can-decide "Αν κάθε output-bound timestamp είναι παγωμένος· εφαρμόζεται αυτόματα στο LOAD."
   :who-can-invoke "Το περιβάλλον της διεργασίας."
   :enforcement :os
   :evidence "deterministic-time.lisp:202-220")

  (:name "capability seat owner (ΝΟΜΟΣ ΜΙΑΣ ΕΔΡΑΣ)"
   :what-it-can-decide "Ποιο αρχείο κατέχει μια δυνατότητα· εμποδίζει σιωπηλή αντικατάσταση trust/fn/schema/proof από άλλο αρχείο."
   :who-can-invoke "register-capability στο LOAD (μέσω orchestrator.paths:current-load-file)."
   :enforcement :code
   :evidence "capability-registry.lisp:122-134")

  (:name ":trust της δυνατότητας (κανένα LLM στο trusted path)"
   :what-it-can-decide "Αν μια δυνατότητα εκτελείται σε trusted επιφάνεια· διπλή επιβολή (pre-check + έδρα)."
   :who-can-invoke "Ο δηλωτής της δυνατότητας ορίζει το :trust· η επιφάνεια ορίζει το :require-trust."
   :enforcement :code
   :evidence "capability-api.lisp:108-111 · capability-registry.lisp:195-206")

  (:name "opaque release anchor (verified vs provisional)"
   :what-it-can-decide "Ποιο assurance μπορεί να φέρει ένα attestation· verified ΜΟΝΟ από private constructor."
   :who-can-invoke "release-anchor-for (verified)· οποιοσδήποτε (provisional)."
   :enforcement :code
   :evidence "version-graph.lisp:2479-2522")

  (:name "hygiene waiver (πόρτα εισδοχής κειμένου)"
   :what-it-can-decide "Αν κείμενο με σύνταξη-μεταφοράς εισέρχεται στον γράφο· απαιτείται waiver που ΚΑΤΟΝΟΜΑΖΕΙ ΑΚΡΙΒΩΣ τα ευρήματα."
   :who-can-invoke "Ο καλών της make-version-spec (import/bootstrap)."
   :enforcement :code
   :evidence "version-graph.lisp:645-686")

  (:name "policy του καταναλωτή στο APB (required-tier, freshness floors, witness)"
   :what-it-can-decide "Ποια βαθμίδα αρκεί, αν απαιτείται checkpoint/μάρτυρας, ποιο είναι το anti-rollback κατώφλι."
   :who-can-invoke "Ο ΕΞΩΤΕΡΙΚΟΣ καταναλωτής — ποτέ το bundle."
   :enforcement :code
   :evidence "authority-proof-bundle.lisp:295-330,646-657"))

 :invariants
 ((:statement "Καμία εκτέλεση κώδικα από δεδομένα: *read-eval* NIL + ολική #-deny + %data-only-p στο αποτέλεσμα."
   :enforced-by "code (safe-read %with-data-env + +data-readtable+ + %data-only-p)"
   :evidence "safe-read.lisp:82-99,152-186")
  (:statement "Ό,τι γράφεται μπορεί να ξαναδιαβαστεί (συμμετρία data-to-string ↔ read-data-string)."
   :enforced-by "code (fail-closed %data-only-p πριν την prin1)"
   :evidence "safe-read.lisp:326-339")
  (:statement "Δύο διαφορετικά σύνολα φύλλων ΔΕΝ δίνουν ίδια Merkle ρίζα (όχι duplicate-last)."
   :enforced-by "code (unbalanced split)"
   :evidence "merkle-authority.lisp:101-119")
  (:statement "Ο θεσμός ΔΕΝ υπογράφει δέσμευση για κενό corpus."
   :enforced-by "code (error empty-corpus-publication πριν από κάθε υπογραφή/εγγραφή)"
   :evidence "proof-carrying.lisp:206-207")
  (:statement "id ⟺ durable: καμία θεσμική ταυτότητα χωρίς επιβεβαιωμένο fsync."
   :enforced-by "code (require-durable! + receipt)"
   :evidence "journal.lisp:343-350,469-479")
  (:statement "Ένας συγγραφέας ανά ημερολόγιο, ΚΑΙ μεταξύ διεργασιών."
   :enforced-by "os+code (flock(2) LOCK_EX σε <journal>.lock + recursive thread mutex)"
   :evidence "journal.lisp:126-170")
  (:statement "Καμία διχάλα αλυσίδας: ο δεσμός του νέου record αντιπαραβάλλεται με την πραγματική ουρά."
   :enforced-by "code (chained-append compare-and-append ⇒ STALE-CHAIN-LINK)"
   :evidence "journal.lisp:531-542")
  (:statement "Μονοτονία transaction-time: :at ποτέ γνησίως παλαιότερο από το τελευταίο committed."
   :enforced-by "code (%check-monotonic-at! πριν τον δίσκο)"
   :evidence "journal.lisp:369-381")
  (:statement "Καμία σιωπηλή wall-clock σε δημοσιευμένη χρονική αξίωση."
   :enforced-by "code — ΜΟΝΟ στο require-deterministic-time· ΟΧΙ στο (now :source :deterministic)"
   :evidence "deterministic-time.lisp:155-176")
  (:statement "Καμία λήψη προς loopback/private/link-local/metadata host (SSRF), ανά redirect hop."
   :enforced-by "code (url-fetch-allowed-p σε κάθε hop· drakma :redirect nil)"
   :evidence "document-fetch.lisp:243-291")
  (:statement "Anti-bot HTML ΠΟΤΕ δεν εισάγεται ως έγγραφο (magic-byte έλεγχος)."
   :enforced-by "code (%magic-file-p· μία πηγή magic table)"
   :evidence "document-fetch.lisp:46-90")
  (:statement "Αποστολή χωρίς εγγεγραμμένη μέτρηση δηλώνεται ΑΜΕΤΡΗΤΗ, ποτέ εκπληρωμένη."
   :enforced-by "code (mission-status)"
   :evidence "self-constitution.lisp:105-115"))

 :defects
 ((:what "Ο ΣΥΝΤΑΓΜΑΤΙΚΟΣ ΦΡΑΓΜΟΣ ΕΙΝΑΙ FAIL-OPEN: σφάλμα μέσα σε predicate κανόνα ⇒ (values t nil) ⇒ η πράξη ΕΠΙΤΡΕΠΕΤΑΙ. Ένας κανόνας που σπάει (π.χ. λόγω απόντος corpus/αρχείου) εξαφανίζεται σιωπηλά αντί να μπλοκάρει."
   :severity :p0
   :evidence "constitutional-gate.lisp:44-45"
   :is-it-in-the-known-defect-list :unknown)
  (:what "get-unix-timestamp επιστρέφει UNIX epoch σε ντετερμινιστική λειτουργία αλλά (get-universal-time) [epoch 1900] αλλιώς — διαφορά 2.208.988.800s στην ΙΔΙΑ συνάρτηση, χωρίς καμία ένδειξη."
   :severity :p1
   :evidence "deterministic-time.lisp:93-101"
   :is-it-in-the-known-defect-list :unknown)
  (:what "(now :source :deterministic) πέφτει ΣΙΩΠΗΛΑ σε get-universal-time όταν το deterministic mode είναι ανενεργό — ενώ το docstring το ορίζει για «ANY timestamp serialized into output artifacts». Δεύτερη, χαλαρή έδρα δίπλα στο fail-closed require-deterministic-time."
   :severity :p1
   :evidence "deterministic-time.lisp:155-158"
   :is-it-in-the-known-defect-list :unknown)
  (:what "advise: (ignore-errors (funcall *advisor* …)) — ο σύμβουλος καταπίνεται ΣΙΩΠΗΛΑ. Κρίση: ΤΙΜΙΑ ΑΓΝΟΙΑ (η επιστροφή NIL ελέγχεται ρητά από τον καλούντα decompose, και το συμβόλαιο είναι «spec|nil»), αλλά ΧΩΡΙΣ ΚΑΜΙΑ ΚΑΤΑΓΡΑΦΗ: αποτυχία συμβούλου δεν διακρίνεται από «δεν είχε πρόταση»."
   :severity :p2
   :evidence "cognition.lisp:65-66,88-89"
   :is-it-in-the-known-defect-list :unknown)
  (:what "decompose: (ignore-errors (funcall fn input)) ανά classifier — ΣΠΑΣΜΕΝΟΣ ταξινομητής προσπερνιέται σιωπηλά και το σύστημα πέφτει στον LLM σύμβουλο χωρίς να το δηλώσει. Ο καλών ΔΕΝ μπορεί να διακρίνει «κανείς δεν ταίριαξε» από «ο ταξινομητής έσπασε»."
   :severity :p1
   :evidence "cognition.lisp:85-87"
   :is-it-in-the-known-defect-list :unknown)
  (:what "write-authority δηλώνει «the ONLY authorized write function for RDF content» αλλά η αποκλειστικότητα είναι ΣΥΜΒΑΣΗ — καμία μηχανική απαγόρευση direct with-open-file."
   :severity :p2
   :evidence "write-authority.lisp:29-30"
   :is-it-in-the-known-defect-list :unknown)
  (:what "config.lisp: load-config σε σχετικό path 'configs/constitution.yaml' — εξαρτάται από cwd· ΠΑΡΑΚΑΜΠΤΕΙ την έδρα paths.lisp (institution-dir) που υπάρχει ακριβώς γι' αυτό."
   :severity :p2
   :evidence "config.lisp:44"
   :is-it-in-the-known-defect-list :unknown)
  (:what "%magic-file-p τυλίγει ΟΛΟΚΛΗΡΟ το σώμα σε ignore-errors: I/O σφάλμα (permission, ΕΙΟ) δεν διακρίνεται από «δεν είναι PDF». Κρίση: ΟΡΙΑΚΑ τίμιο (ο caller παίρνει NIL και το μεταφράζει σε :not-a-pdf) αλλά η ΑΙΤΙΑ χάνεται."
   :severity :p2
   :evidence "document-fetch.lisp:71-79"
   :is-it-in-the-known-defect-list :unknown)
  (:what "ΔΙΠΛΗ ΕΔΡΑ canonical sexp serialization με ΨΕΥΔΗ δήλωση ανάθεσης: το journal.lisp:67 γράφει «Καταναλωτές: version-graph (%canon-sexp deleg.)» αλλά το version-graph.lisp:471-497 έχει ΔΙΚΗ ΤΟΥ πανομοιότυπη υλοποίηση, ΟΧΙ κλήση της journal:canon-sexp. Κάθε payload-hash/chain/condition-id/regime-id/attestation-hash του δικαιικού χρόνου παράγεται από το ΑΝΤΙΓΡΑΦΟ — απόκλιση των δύο εδρών θα έσπαγε σιωπηλά κάθε αποθηκευμένη ταυτότητα. (Το memory.lisp ΟΝΤΩΣ αναθέτει: memory.lisp:110,164.)"
   :severity :p1
   :evidence "journal.lisp:61-86 · version-graph.lisp:471-497 · memory.lisp:110"
   :is-it-in-the-known-defect-list :unknown)
  (:what "canonical-representation δηλώνει RFC 8785 (JCS) και «bit-perfect reproducibility across implementations», αλλά: (α) η αριθμητική σειριοποίηση είναι (format ~,17G) + regex καθάρισμα, ΟΧΙ ο αλγόριθμος ECMAScript Number::toString που ορίζει το RFC 8785 §3.2.2.3 — αποκλίνει από ΚΑΘΕ συμμορφούμενη ξένη υλοποίηση σε πολλά doubles· (β) η ταξινόμηση κλειδιών γίνεται με string< (code points), ενώ το RFC απαιτεί UTF-16 code units — διαφορά σε κλειδιά εκτός BMP."
   :severity :p1
   :evidence "canonical-representation.lisp:162-192,227-241"
   :is-it-in-the-known-defect-list :unknown)
  (:what "canonicalize-json ΑΜΦΙΣΗΜΙΑ τύπου: λίστα από plists (π.χ. ((:a 1) (:b 2))) ταξινομείται ως ALIST ⇒ σειριοποιείται ως JSON object αντί για array of objects, με τιμές (cdr) ως arrays. Η ίδια Lisp τιμή δεν διακρίνεται από πίνακα αντικειμένων — σε έδρα κανονικοποίησης που τροφοδοτεί hashes/υπογραφές."
   :severity :p1
   :evidence "canonical-representation.lisp:141-160"
   :is-it-in-the-known-defect-list :unknown)
  (:what "archive-authority: το «100-year proof» ΔΕΝ επαληθεύεται. Δεν ελέγχεται HTTP status· όταν το σώμα είναι string επιστρέφεται ως :archived-url η URL ΥΠΟΒΟΛΗΣ (save-url), όχι η πραγματική αρχειοθετημένη URL· και δηλώνεται :status :success ανεξαρτήτως. Επιπλέον καμία SSRF πύλη (drakma :redirect 10 σε αυθαίρετο URL) — αντίθετα με το document-fetch που έχει φρουρό ανά hop."
   :severity :p1
   :evidence "archive-authority.lisp:70-94"
   :is-it-in-the-known-defect-list :unknown)
  (:what "adoption-decision: η ΥΠΟΓΡΑΦΗ της απόφασης παράγεται με (prin1-to-string decision) — αναπαράσταση, ΟΧΙ αξία. Είναι ακριβώς η κλάση σφάλματος που γέννησε τη canon-sexp (non-simple strings ⇒ #A(...)): ένα decision plist με format-παραγόμενο string μπορεί να δώσει ΑΛΛΟ sha μετά από round-trip, και το validate-adoption-records να το κηρύξει πλαστό."
   :severity :p1
   :evidence "adoption-decision.lisp:90-95,126-131"
   :is-it-in-the-known-defect-list :unknown)
  (:what "extract-layout-graph: σφάλμα εξαγωγής σελίδας ⇒ ΚΕΝΗ σελίδα-placeholder με μόνο (warn) — σιωπηλή απώλεια περιεχομένου σε αγωγό corpus. Ο καλών δεν μπορεί να διακρίνει «σελίδα χωρίς κείμενο» από «σελίδα που απέτυχε»."
   :severity :p1
   :evidence "pdf-authority.lisp:1360-1370"
   :is-it-in-the-known-defect-list :unknown)
  (:what "extract-text-via-ocr: προσωρινός κατάλογος /tmp/lawmax-ocr-<get-universal-time>/ — ΠΡΟΒΛΕΨΙΜΟ όνομα σε κοινόχρηστο /tmp (κίνδυνος pre-creation/symlink) και χρήση wall-clock αντί της έδρας χρόνου. Επιπλέον (error () nil) καταπίνει ΚΑΘΕ αιτία αποτυχίας OCR."
   :severity :p2
   :evidence "pdf-authority.lisp:1399-1425"
   :is-it-in-the-known-defect-list :unknown)
  (:what "path-to-uri: μόνο τα κενά κωδικοποιούνται ως %20· #, %, ?, [ ] σε όνομα αρχείου παράγουν λάθος file:// URI (το # κόβει το path). Ένα ΦΕΚ με # στο όνομα δεν ανοίγει, ή ανοίγει άλλο αρχείο."
   :severity :p2
   :evidence "pdf-authority.lisp:349-355"
   :is-it-in-the-known-defect-list :unknown)
  (:what "%ngz: (funcall (find-symbol \"NORMALIZE-GREEK\" :orchestrator.legal-id) s) ΧΩΡΙΣ έλεγχο — αν το πακέτο/σύμβολο λείπει, funcall πάνω σε NIL (undefined-function). Το ΙΔΙΟ αρχείο ελέγχει σωστά στη make-registry-resolver (L196-198): ασύμμετρη άμυνα στο ίδιο εξαρτησιακό όριο."
   :severity :p2
   :evidence "amendment-extractor.lisp:189-190 vs 196-198"
   :is-it-in-the-known-defect-list :unknown)
  (:what "APB: ο ΕΜΠΙΣΤΟΣ owner thumbprint υπολογίζεται με (ignore-errors (ed25519-jwk-thumbprint trusted-owner-root-jwk)) — κακοσχηματισμένο ΕΜΠΙΣΤΟ pin γίνεται σιωπηλά NIL, το OWN1 αποτυγχάνει και η βαθμίδα υποβαθμίζεται σε internally-release-consistent ΧΩΡΙΣ να ειπωθεί ότι το ίδιο το pin ήταν άκυρο. Κρίση: fail-closed ως προς τη βαθμίδα, αλλά η ΑΙΤΙΑ καταπίνεται — ο καταναλωτής δεν μαθαίνει ότι έδωσε χαλασμένη ρίζα."
   :severity :p2
   :evidence "authority-proof-bundle.lisp:507-511"
   :is-it-in-the-known-defect-list :unknown)
  (:what "version-graph: δύο διαφορετικές κανονικοποιήσεις ταυτότητας συνυπάρχουν στο ΙΔΙΟ αρχείο — %version-hash-2/%edge-hash μέσω canonical-representation:canonical-hash (canonical JSON), ενώ condition/regime/event/attestation ids μέσω journal:sha256-hex πάνω σε %canon-sexp (canonical sexp). Δύο σχήματα ταυτότητας για μία έννοια («ταυτότητα εγγραφής») στην ίδια έδρα."
   :severity :p2
   :evidence "version-graph.lisp:288-300,407-418 vs 1727-1729,2096-2104,2595-2596"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Ο ΕΛΕΓΚΤΗΣ ΤΟΥ AUDIT TRAIL ΑΠΟΤΥΓΧΑΝΕΙ ΠΑΝΤΑ, ΜΕ ΔΥΟ ΑΝΕΞΑΡΤΗΤΑ ΣΦΑΛΜΑΤΑ: (α) το log-activity δίνει :previous-hash NIL στην ΠΡΩΤΗ εγγραφή, ενώ το verify-audit-trail ξεκινά με previous-hash \"GENESIS\" — (equal NIL \"GENESIS\") ⇒ «Hash chain broken» στην πρώτη εγγραφή ΚΑΘΕ trail· (β) η επαλήθευση JWS καλεί (verify-jws signature *signing-public-key-path* :expected-payload content) ενώ η υπογραφή είναι (verify-jws jws payload public-key) — ΤΕΣΣΕΡΑ ορίσματα σε ΤΡΙΩΝ-παραμέτρων συνάρτηση, ΚΑΙ με τα ορίσματα σε λάθος θέσεις ⇒ program-error, που το handler-case το μετατρέπει σε log:warn + NIL ⇒ «Invalid signature». Άρα: με ενεργή κρυπτογραφική υπογραφή το audit trail ΔΕΝ επαληθεύεται ΠΟΤΕ, και η αιτία κρύβεται σε warning."
   :severity :p0
   :evidence "legal-audit-system.lisp:233-236,486-509,545-554 · jws-authority.lisp:394"
   :is-it-in-the-known-defect-list :unknown)
  (:what "compute-entry-hash (audit) χρησιμοποιεί «~A|~A|~A|…» — ΜΗ ΕΝΡΙΞΙΜΗ κωδικοποίηση: μετατόπιση του «|» μεταξύ actor/target/action δίνει ΙΔΙΟ hash για ΔΙΑΦΟΡΕΤΙΚΕΣ εγγραφές (ίδια κλάση που το review-queue ΔΙΟΡΘΩΣΕ ρητά με %canon-encode και το authority-proof-bundle με separator-deny). Η αλυσίδα audit είναι πλαστογραφήσιμη με field-shifting."
   :severity :p1
   :evidence "legal-audit-system.lisp:271-283 vs review-queue.lisp:100-117"
   :is-it-in-the-known-defect-list :unknown)
  (:what "generate-uuid του audit: (random (expt 2 32)) με το ΠΡΟΕΠΙΛΕΓΜΕΝΟ *random-state* — ΟΧΙ CSPRNG και, στο SBCL, ΙΔΙΑ ακολουθία σε κάθε εκκίνηση εικόνας. Τα entry-id/trail-id είναι προβλέψιμα ΚΑΙ επαναλαμβανόμενα μεταξύ εκτελέσεων· το trail-entry-index (equal hash) τα αντικαθιστά σιωπηλά σε σύγκρουση. (Το ίδιο μοτίβο στο generate-activity-id.)"
   :severity :p1
   :evidence "legal-audit-system.lisp:780-793"
   :is-it-in-the-known-defect-list :unknown)
  (:what "government-source %pdf->text καλεί το ΜΗ-ΕΞΑΓΟΜΕΝΟ extract-pdf-text — τη διαδρομή που ΠΕΦΤΕΙ ΣΙΩΠΗΛΑ στον regex «fallback PDF parser» με μόνο (warn) όταν λείπει η poppler. Άρα η κρατική ροή εισαγωγής μπορεί να τροφοδοτήσει τον amendment-extractor με αποσπασματικό κείμενο, και οι :high-confidence πράξεις που προκύπτουν αυτο-εφαρμόζονται."
   :severity :p1
   :evidence "government-source.lisp:487-502 · pdf-authority.lisp:904-964"
   :is-it-in-the-known-defect-list :unknown)
  (:what "mcp-server *corpus-list-fn*: ελέγχει (find-package :orchestrator.spec) αλλά κάνει find-symbol στο :orchestrator.cli (λάθος φρουρός — απόν package ⇒ σφάλμα), και σε αποτυχία επιστρέφει ΣΤΑΘΕΡΗ λίστα '(\"syntagma\" \"poinikos\"). Ένας AI πράκτορας που ρωτά «ποιους κώδικες σερβίρεις» παίρνει ΜΑΝΤΕΨΙΑ, όχι το μητρώο."
   :severity :p1
   :evidence "mcp-server.lisp:102-107"
   :is-it-in-the-known-defect-list :unknown)
  (:what "GATE-5 (validation-authority) ΕΙΝΑΙ ΔΟΜΙΚΑ ΝΕΚΡΟ: ΕΞΙ εσωτερικές κλήσεις περνούν το CONTEXT ΘΕΣΙΑΚΑ σε συναρτήσεις που το δηλώνουν ως &key — (check-broken-patterns ttl-content context) vs (defun check-broken-patterns (ttl &key context)) κ.λπ. Κάθε τέτοια κλήση σηματοδοτεί program-error («odd number of &KEY arguments») ΠΡΙΝ γίνει οποιοσδήποτε έλεγχος. Άρα το validate-canonical-ttl ΠΟΤΕ δεν επικυρώνει: ή σκάει με σφάλμα άσχετο με το περιεχόμενο, ή (αν ο καλών το τυλίγει) η επικύρωση απουσιάζει εντελώς. Καταναλωτής υπάρχει: systems/orchestrator-omega-modules/unified-frbr-generator.lisp:434."
   :severity :p0
   :evidence "validation-authority.lisp:67,70,73,77,93,173,210,213,216,220,230,250"
   :is-it-in-the-known-defect-list :unknown)
  (:what "ΕΓΚΡΙΣΗ ΠΡΟΤΑΣΗΣ ΣΦΡΑΓΙΖΕΤΑΙ ΑΚΟΜΗ ΚΙ ΑΝ Η ΕΝΕΡΓΕΙΑ ΑΠΕΤΥΧΕ: το %transition τρέχει το ON-APPROVE hook (αυτό που ΕΦΑΡΜΟΖΕΙ πραγματικά την πρόταση) μέσα σε (ignore-errors …) και ΣΥΝΕΧΙΖΕΙ να γράψει status «approved» στο append-only ledger. Ο παράμετρος FAIL-MSG υπάρχει αλλά είναι (declare (ignorable …)) και δεν χρησιμοποιείται ΠΟΤΕ — αποδεικτικό ότι το μονοπάτι σφάλματος εγκαταλείφθηκε. Η θεσμική εγγραφή λέει «εγκρίθηκε» ενώ τίποτα δεν εφαρμόστηκε."
   :severity :p0
   :evidence "proposals.lisp:129-140"
   :is-it-in-the-known-defect-list :unknown)
  (:what "verify-consolidation-ledger είναι ΤΑΥΤΟΛΟΓΙΑ, όχι επαλήθευση: «independently REPLAY» σημαίνει ΞΑΝΑΤΡΕΧΕΙ την ΙΔΙΑ consolidate με τα ΙΔΙΑ ορίσματα και συγκρίνει base-hash/result-hash/ΠΛΗΘΟΣ βημάτων. Τα καταγεγραμμένα before/after hashes των βημάτων ΔΕΝ συγκρίνονται ποτέ. Ένα ledger με πλαστά step hashes (ίδιο πλήθος) περνά· και η «απόδειξη» εξαρτάται από τον ΙΔΙΟ κώδικα που παρήγαγε το αποτέλεσμα — κανένας ανεξάρτητος verifier δεν υπάρχει."
   :severity :p1
   :evidence "consolidation-proof.lisp:113-123"
   :is-it-in-the-known-defect-list :unknown)
  (:what "corpus-provenance ΠΑΡΑΚΑΜΠΤΕΙ τη «fail hard» πολιτική των canonical URIs: το %ensure-uris ΓΡΑΦΕΙ σιωπηλά default base-uri «https://stavropouloslaw.com/eli» στο global *canonical-config* ώστε «οι PROV-O generators να μη σφάλλουν ποτέ» — ακριβώς το αντίθετο του canonical-uris.lisp:58-63 («NO fallback defaults… MUST fail hard»). Ένα module παρουσίασης καθορίζει την ταυτότητα του Ιδρύματος."
   :severity :p1
   :evidence "corpus-provenance.lisp:26-33 vs canonical-uris.lisp:57-63"
   :is-it-in-the-known-defect-list :unknown)
  (:what "corpus-provenance %ts: ημερομηνία απούσα/κακοσχηματισμένη ⇒ ΣΙΩΠΗΛΗ αντικατάσταση με σταθερό 2025-01-01 μέσα σε PROV-O έγγραφο προέλευσης. Το τεκμήριο προέλευσης φέρει ΚΑΤΑΣΚΕΥΑΣΜΕΝΗ χρονοσφραγίδα που δεν διακρίνεται από αληθινή."
   :severity :p1
   :evidence "corpus-provenance.lisp:35-39"
   :is-it-in-the-known-defect-list :unknown)
  (:what "component-scan: file-hash τυλιγμένο σε ignore-errors ⇒ NIL, ΚΑΙ το stale-components θεωρεί ΡΗΤΑ «(null now) ⇒ ΟΧΙ stale». Άρα οποιοδήποτε I/O σφάλμα (permissions, EIO) πάνω σε αρχείο πηγής μετατρέπει την ανίχνευση απόκλισης hash σε σιωπηλό «καθαρό». Ο έλεγχος ακεραιότητας απενεργοποιείται από αποτυχία ανάγνωσης."
   :severity :p1
   :evidence "component-scan.lisp:26-28,305-316"
   :is-it-in-the-known-defect-list :unknown)
  (:what "component-scan freeze-components!: το manifest ταυτοτήτων γράφεται με (prin1 all s) — ΟΧΙ μέσω της ΜΙΑΣ έδρας εγγραφής (safe-read:data-to-string), ενώ ΔΙΑΒΑΖΕΤΑΙ από τη safe-read (+data-readtable+ που ΑΠΟΡΡΙΠΤΕΙ κάθε #-σύνταξη). Ένα specialized base-char string θα τυπωνόταν #A(...) και το manifest θα γινόταν μη αναγνώσιμο — ακριβώς η κλάση που η data-to-string υπάρχει για να εξαλείψει."
   :severity :p2
   :evidence "component-scan.lisp:139-149 vs safe-read.lisp:312-339"
   :is-it-in-the-known-defect-list :unknown)
  (:what "component-scan %scan-file-text: οι ΕΔΡΕΣ δηλώσεων (defpackage/defcontract/declare-capability!) ανιχνεύονται με REGEX πάνω στο κείμενο του αρχείου — ένα αναφερόμενο όνομα μέσα σε σχόλιο/string μετριέται ως έδρα. Η «ταυτότητα συστατικού» στηρίζεται σε λεξικογραφική εικασία, όχι σε ανάγνωση κώδικα."
   :severity :p2
   :evidence "component-scan.lisp:45-56"
   :is-it-in-the-known-defect-list :unknown)
  (:what "corpus-intelligence: το define-corpus-check τυλίγει ΚΑΘΕ σώμα ελέγχου σε handler-case ⇒ ΟΠΟΙΟΔΗΠΟΤΕ σφάλμα γίνεται finding :skipped, και το report-clean-p ΑΓΝΟΕΙ ρητά τα skips («advisories / skips do not count»). Άρα ένας ΣΠΑΣΜΕΝΟΣ έλεγχος παράγει «καθαρός κώδικας». Η αποτυχία επαλήθευσης γίνεται επιτυχία."
   :severity :p1
   :evidence "corpus-intelligence.lisp:75-93,175-177"
   :is-it-in-the-known-defect-list :unknown)
  (:what "paths.lisp with-temp-file: το όνομα προσωρινού αρχείου είναι «orch-<unix-timestamp>.tmp» σε κοινό :temp κατάλογο — ΠΡΟΒΛΕΨΙΜΟ (symlink/pre-creation attack) και, υπό ντετερμινιστικό χρόνο, ΤΑΥΤΟ σε κάθε εκτέλεση (σύγκρουση). Επιπλέον κληρονομεί το epoch bug του get-unix-timestamp."
   :severity :p2
   :evidence "paths.lisp:311-323"
   :is-it-in-the-known-defect-list :unknown)
  (:what "http-server: το +status-text+ δεν περιέχει 503 (ούτε 403/429), ενώ ο κώδικας εκπέμπει 503 στο overload — το reason phrase γίνεται (or … \"OK\") ⇒ αποστέλλεται «HTTP/1.1 503 OK». Το ίδιο για κάθε 403 της capability-api."
   :severity :p2
   :evidence "http-server.lisp:51-54,157,206-213"
   :is-it-in-the-known-defect-list :unknown)
  (:what "circuit-breaker: ο έλεγχος κατάστασης «(when (eq (cb-state breaker) :open) …)» γίνεται ΕΚΤΟΣ του κλειδώματος, αμέσως μετά το κλείσιμό του — TOCTOU: ταυτόχρονο άνοιγμα κυκλώματος δεν τηρείται. Επίσης οι προεπιλογές υπάρχουν σε ΤΡΕΙΣ θέσεις (defconstant +default-*+, defclass initform, make-circuit-breaker lambda list) και τα +default-*+ είναι ΝΕΚΡΑ."
   :severity :p2
   :evidence "circuit-breaker.lisp:23-33,52-71,112-129,211-218"
   :is-it-in-the-known-defect-list :unknown)
  (:what "memory fire-due-intentions: (ignore-errors (funcall fn …)) — μια ΣΠΑΣΜΕΝΗ συνθήκη πρόθεσης δεν διακρίνεται από «ψευδής». Το docstring δηλώνει τιμιότητα μόνο για ΑΓΝΩΣΤΗ συνθήκη· η σφάλλουσα καταπίνεται σιωπηλά."
   :severity :p2
   :evidence "memory.lisp:258-272"
   :is-it-in-the-known-defect-list :unknown)
  (:what "memory *session*: ταυτότητα συνεδρίας = (format nil \"s~36R\" (get-universal-time)) στο LOAD — δύο διεργασίες που ξεκινούν το ίδιο δευτερόλεπτο μοιράζονται ταυτότητα συνεδρίας, και σε ντετερμινιστικό build είναι σταθερή."
   :severity :p2
   :evidence "memory.lisp:48-50"
   :is-it-in-the-known-defect-list :unknown)
  (:what "consolidation-bridge %extract-ops/%op-applicable: (and f …) πάνω σε find-symbol — αν το πακέτο του extractor δεν είναι φορτωμένο, το law->record επιστρέφει NIL, δηλαδή «ο νόμος ΔΕΝ τροποποιεί αυτόν τον κώδικα». Απούσα εξάρτηση γίνεται σιωπηλά «καμία τροποποίηση» στον αυτόνομο βρόχο ενοποίησης."
   :severity :p1
   :evidence "consolidation-bridge.lisp:258-270,272-305"
   :is-it-in-the-known-defect-list :unknown)
  (:what "corpus-diff/corpus-search: τοπικά jstr JSON escapers που ΔΕΝ κωδικοποιούν control chars < 0x20 (σε αντίθεση με το %j του proof-carrying) — ένα άρθρο με U+0001 παράγει ΑΚΥΡΟ JSON στο δημόσιο endpoint."
   :severity :p2
   :evidence "corpus-diff.lisp:36-44 · corpus-search.lisp:70-78 vs proof-carrying.lisp:88-99"
   :is-it-in-the-known-defect-list :unknown)
  (:what "pdf-authority load-poppler-libraries: το *poppler-load-attempted* latch δεν καθαρίζεται ΠΟΤΕ — μία παροδική αποτυχία φόρτωσης παγιδεύει τη διεργασία μόνιμα σε «poppler μη διαθέσιμη» με μόνο log:warn, ενώ κάθε PDF λειτουργία μετά σφάλλει."
   :severity :p2
   :evidence "pdf-authority.lisp:139-174"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Το ΜΟΤΙΒΟ «(apply (find-symbol \"X\" :orchestrator.consolidation) args)» επαναλαμβάνεται αυτούσιο σε ≥2 αρχεία, ρητά δηλωμένο ως «the same defensive pattern the other intelligence modules use» — αντιγραμμένο boilerplate που μετατρέπει απούσα εξάρτηση σε undefined-function αντί για δηλωμένη άγνοια."
   :severity :p2
   :evidence "anomaly-detection.lisp:24-31 · ast-gate.lisp:40-47"
   :is-it-in-the-known-defect-list :unknown))

 :hidden-execution-paths
 ((:path "run-fetch-command → uiop:run-program (/bin/sh -c COMMAND) με ΠΛΗΡΕΣ posix-environ"
   :trigger "fetch-pdf με fetch-command από ρύθμιση πηγής"
   :why-hidden "Αυθαίρετη εκτέλεση shell από δεδομένο ρύθμισης, μέσα σε module που αλλού διαφημίζει «pure Lisp»· το περιβάλλον κληρονομείται ΟΛΟΚΛΗΡΟ (sb-ext:posix-environ)."
   :evidence "document-fetch.lisp:92-106,308-323")
  (:path "config.lisp → (funcall (intern \"LOAD-CANONICAL-URIS-FROM-CONFIG\" :orchestrator.uris) *config*)"
   :trigger "load-default-config όταν υπάρχει το package :orchestrator.uris"
   :why-hidden "Δυναμική αποστολή μέσω intern σε συμβολοσειρά — καμία στατική εξάρτηση/έλεγχος τύπου· αν το package υπάρχει αλλά το σύμβολο όχι, το intern το ΔΗΜΙΟΥΡΓΕΙ και το funcall σφάλλει (undefined-function)."
   :evidence "config.lisp:48-49")
  (:path "config.lisp → (funcall (intern \"INITIALIZE-LOGGING\" :orchestrator.logging) …) υπό handler-case ⇒ warn+nil"
   :trigger "setup-logging"
   :why-hidden "Ίδιο μοτίβο intern-dispatch· η αποτυχία αρχικοποίησης καταγραφής γίνεται προειδοποίηση."
   :evidence "config.lisp:51-60")
  (:path "proof-carrying %jws-fn → find-symbol/fboundp σε :orchestrator.jws-authority"
   :trigger "sign-root / verify-signed-root"
   :why-hidden "Αν το JWS package δεν είναι φορτωμένο, το sign-root επιστρέφει NIL και το corpus δημοσιεύεται ως 'unsigned-explicit' — ΔΗΛΩΜΕΝΟ στο JSON, αλλά η μετάβαση signed→unsigned είναι σιωπηλή στη ροή."
   :evidence "proof-carrying.lisp:143-155,168-183")
  (:path "deterministic-time: (eval-when (:load-toplevel :execute) (initialize-from-environment))"
   :trigger "Απλή φόρτωση του αρχείου με SOURCE_DATE_EPOCH στο περιβάλλον"
   :why-hidden "Το LOAD του module ΜΕΤΑΛΛΑΣΣΕΙ global κατάσταση χρόνου ΚΑΙ τυπώνει στο stdout — καμία ρητή κλήση από κανέναν."
   :evidence "deterministic-time.lisp:202-220")
  (:path "journal *ephemeral* = defvar από LAWMAX_REPLICA στο LOAD"
   :trigger "env var κατά τη φόρτωση"
   :why-hidden "Ολόκληρη η durability του συστήματος αλλάζει από env var που διαβάζεται ΜΙΑ φορά, σε defvar· καμία μεταγενέστερη αλλαγή δεν έχει αποτέλεσμα, και το receipt γίνεται :ephemeral-replica που το require-durable! ΔΕΧΕΤΑΙ ως έγκυρο."
   :evidence "journal.lisp:180-187,347-349")
  (:path "constitutional-gate: LAWMAX_OVERRIDE / LAWMAX_OVERRIDE_REASON"
   :trigger "env vars της διεργασίας"
   :why-hidden "Πλήρης παράκαμψη του «υπέρτατου φραγμού» χωρίς άγγιγμα κώδικα ή CLI."
   :evidence "constitutional-gate.lisp:59-65")
  (:path "journal *clock-override* και *fsync-fault* — TEST-ONLY ένεση σε παραγωγικό image"
   :trigger "setf/dynamic bind των ειδικών μεταβλητών"
   :why-hidden "Δηλωμένα «ΠΟΤΕ σε παραγωγικό μονοπάτι» αλλά υπαρκτά και εξαγόμενα στο παραγωγικό package: το ένα ψεύδεται για τον χρόνο, το άλλο για την durability."
   :evidence "journal.lisp:45-48,210-213")
  (:path "cognition: register-classifier / *advisor* — αυθαίρετα κλεισίματα σε global λίστα"
   :trigger "Οποιοδήποτε φορτωμένο module"
   :why-hidden "Τα κλεισίματα τρέχουν μέσα στο decompose υπό ignore-errors — κώδικας που εκτελείται στο trusted μονοπάτι χωρίς μητρώο/έλεγχο."
   :evidence "cognition.lisp:69-89")
  (:path "anomaly-detection / ast-gate → (apply (find-symbol \"…\" :orchestrator.consolidation) args)"
   :trigger "Κάθε κλήση των %legal-document-provisions/%provision-text/…"
   :why-hidden "Τα ονόματα δένονται ΩΣ STRINGS σε macrolet-παραγόμενες συναρτήσεις· καμία στατική εξάρτηση, καμία ένδειξη αν το πακέτο δεν φορτώθηκε."
   :evidence "anomaly-detection.lisp:24-31 · ast-gate.lisp:40-47")
  (:path "amendment-extractor %ngz → find-symbol NORMALIZE-GREEK σε :orchestrator.legal-id"
   :trigger "Κάθε %all-quoted-spans/%segment-starts"
   :why-hidden "Δυναμική επίλυση χωρίς έλεγχο· η ΜΙΑ έδρα δρομολόγησης εισάγεται με string lookup."
   :evidence "amendment-extractor.lisp:189-199")
  (:path "pdf-authority → uiop:run-program (\"which\"…, \"pdftoppm\"…, \"tesseract\"…)"
   :trigger "extract-text-any όταν το text layer έχει < 600 χαρακτήρες"
   :why-hidden "Αυτόματη κλιμάκωση σε ΤΡΕΙΣ εξωτερικές διεργασίες + εγγραφή σε προβλέψιμο /tmp path, ενεργοποιούμενη από ένα κατώφλι μήκους κειμένου."
   :evidence "pdf-authority.lisp:1386-1439")
  (:path "pdf-authority: lazy CFFI load-poppler-libraries με *poppler-load-attempted* latch"
   :trigger "Πρώτη κλήση οποιασδήποτε PDF λειτουργίας"
   :why-hidden "Μία αποτυχία φόρτωσης ΚΛΕΙΔΩΝΕΙ μόνιμα τη διεργασία σε «μη διαθέσιμο» (το latch δεν καθαρίζεται) — παροδικό σφάλμα γίνεται μόνιμη υποβάθμιση, με μόνο log:warn."
   :evidence "pdf-authority.lisp:139-174")
  (:path "extract-pdf-text → extract-text-fallback (regex «PDF parser»)"
   :trigger "prefer-poppler NIL ή μη φορτωμένη poppler"
   :why-hidden "Δεύτερη, κρυφή διαδρομή ανάγνωσης PDF που παράγει αποσπασματικό κείμενο με regex πάνω σε latin-1 bytes και μόνο (warn) — ενώ η δηλωμένη ΜΙΑ έδρα είναι η extract-text-any."
   :evidence "pdf-authority.lisp:904-964 vs 1427-1439")
  (:path "instrument-kind-entries / scope-dimension-entries: ΜΟΝΙΜΟ closure cache"
   :trigger "Πρώτη ανάγνωση των μητρώων deployment/data/*.sexp"
   :why-hidden "(let ((cache nil)) …) — το μητρώο διαβάζεται ΜΙΑ φορά ανά διεργασία· αλλαγή του αρχείου δεν γίνεται ποτέ ορατή, χωρίς invalidation ή δήλωση."
   :evidence "version-graph.lisp:1497-1531,1557-1591")
  (:path "*scope-assumptions* — δυναμική μεταβλητή που μεταφέρει «υποθέσεις» έξω από την επιστροφή"
   :trigger "version-at με :scope-mode :conservative και scope-covers-p = :unknown"
   :why-hidden "Πλευρικό κανάλι: ένα pushnew μέσα σε φιλτράρισμα καθορίζει αν το αποτέλεσμα θα σημανθεί analytical-not-authoritative· η σήμανση εξαρτάται από τη ΣΕΙΡΑ αποτίμησης των κατηγορημάτων."
   :evidence "version-graph.lisp:193-195,1020-1028,2137-2162"))

 :duplicate-seats
 ((:concept "«χρόνος για δημοσιευμένο artifact»"
   :seats ("deterministic-time.lisp:164-176 (require-deterministic-time — fail-closed)"
           "deterministic-time.lisp:129-162 (now :source :deterministic — σιωπηλό fallback)"
           "deterministic-time.lisp:84-119 (get-current-timestamp/get-unix-timestamp/get-iso8601)"
           "journal.lisp:50-59 (iso-now — δικό του ρολόι, get-universal-time, ΑΝΕΞΑΡΤΗΤΟ από το deterministic mode)"))
  (:concept "canonical sexp serialization"
   :seats ("safe-read.lisp:312-339 (data-to-string)"
           "journal.lisp:61-86 (canon-sexp)"
           "journal.lisp:399-402 (format ~S με ειδικά print bindings — ΤΡΙΤΗ παραλλαγή στην ίδια έδρα εγγραφής)"))
  (:concept "ανάγνωση sexp δεδομένων"
   :seats ("safe-read.lisp:275-308 (η δηλωμένη ΜΙΑ έδρα)"
           "journal.lisp:265-292 (%load-lines — δικός του tolerant read loop με *read-eval* nil, ΧΩΡΙΣ #-deny/caps/%data-only-p· ρητά εξαιρεμένος στο safe-read.lisp:32)"
           "journal.lisp:352-361 (%validate-serializable — read-from-string, ΤΡΙΤΟΣ reader)"))
  (:concept "canonical sexp της ΑΞΙΑΣ (value-canonical)"
   :seats ("journal.lisp:61-86 (canon-sexp — δηλωμένη ΜΙΑ έδρα)"
           "version-graph.lisp:471-497 (%canon-sexp — ΠΑΝΟΜΟΙΟΤΥΠΟ αντίγραφο, ενώ το journal δηλώνει ότι το version-graph «deleg.»)"))
  (:concept "ταυτότητα εγγραφής (record identity hashing)"
   :seats ("version-graph.lisp:288-300 (%version-hash-2 → canonical-representation:canonical-hash / canonical JSON)"
           "version-graph.lisp:1727-1729 (condition id → journal:sha256-hex ∘ %canon-sexp / canonical sexp)"
           "version-graph.lisp:2096-2104 (%regime-hash — canonical sexp)"
           "adoption-decision.lisp:90-94 (prin1-to-string + ironclad απευθείας — ΤΡΙΤΟ σχήμα)"))
  (:concept "«η ΜΙΑ ανάγνωση PDF εγγράφου»"
   :seats ("pdf-authority.lisp:1427-1439 (extract-text-any — δηλωμένη η ΜΙΑ)"
           "pdf-authority.lisp:944-964 (extract-pdf-text — δεύτερη ενιαία είσοδος με fallback)"
           "pdf-authority.lisp:381-446 / 508-537 / 658-697 (τρεις παράλληλες πλήρεις διαδρομές εξαγωγής, καθεμία με δικό της άνοιγμα εγγράφου)"))
  (:concept "εξερχόμενη HTTP λήψη"
   :seats ("document-fetch.lisp:258-291 (%fetch-url-to-file — SSRF φρουρός ανά hop, :redirect nil)"
           "archive-authority.lisp:70-94 (drakma:http-request :redirect 10 — ΚΑΝΕΝΑΣ φρουρός)"))
  (:concept "generic content hash"
   :seats ("hash-authority.lisp:11-46 (compute-hash — δηλωμένη έδρα γενικού hash)"
           "journal.lisp:88-92 (sha256-hex — δεύτερη γενική έδρα, ironclad απευθείας)"
           "adoption-decision.lisp:91-94 και 128-131 (ironclad απευθείας, τρίτη)"
           "canonical-representation.lisp:338-342 (generate-manifest-id — ironclad απευθείας, ΕΝΩ το ίδιο αρχείο αλλού χρησιμοποιεί hash:compute-hash)"))
  (:concept "«ώρα δημιουργίας/υποβολής» μέσα στο ίδιο αρχείο"
   :seats ("archive-authority.lisp:87 ((get-universal-time))"
           "archive-authority.lisp:131-132 (orchestrator.time:now :source :system)")))

 :unknowns
 ("Ποιος θέτει το *advisor* και με ποιο μοντέλο — δεν βρίσκεται στα αρχεία που διάβασα."
  "Ποιος καλεί το orchestrator.constitution:evaluate και αν η μεσολάβηση είναι πράγματι καθολική."
  "Αν το fetch-command προέρχεται από αρχείο ρύθμισης ελεγχόμενο από τον operator ή από corpus δεδομένα.")

 :remaining
 ("ai-citation-strategy.lisp" "ai-corpus-dump.lisp" "ai-ingest-manifest.lisp"
  "akoma-ntoso-emitter.lisp"
  "asn1-der.lisp" "authority-evidence-replay.lisp"
  "blockchain-authority.lisp"
  "circuit-breaker.lisp" "citation-authority.lisp"
  "component-scan.lisp" "consolidation-bridge.lisp" "consolidation-engine.lisp"
  "consolidation-feed.lisp" "consolidation-proof.lisp" "corpus-diff.lisp"
  "corpus-eu-links.lisp" "corpus-fingerprint.lisp" "corpus-intelligence.lisp" "corpus-provenance.lisp"
  "corpus-search.lisp" "corpus-service.lisp" "corpus-sparql.lisp" "deliberation.lisp"
  "embeddings-authority.lisp" "eu-interop-layer.lisp" "execution-trace.lisp" "fluid-induction.lisp"
  "generation.lisp" "government-source.lisp" "graph-reasoning.lisp" "greek-legislation-ontology.lisp"
  "greek-lemmatizer.lisp" "greek-nlp-core.lisp" "greek-tokenizer-advanced.lisp" "guard-metaeval.lisp"
  "guard-ops-pack.lisp" "http-server.lisp" "ingestion-daemon.lisp" "injection.lisp" "introspection.lisp"
  "json-emit.lisp" "jws-authority.lisp" "knowledge-graph.lisp" "knowledge-packs.lisp" "layout-types.lisp"
  "legal-ast.lisp" "legal-audit-system.lisp" "legal-authority-receipt.lisp" "legal-casegrammar.lisp"
  "legal-conflict-resolution.lisp" "legal-counterfactual.lisp" "legal-decisions.lisp" "legal-deontic.lisp"
  "legal-dialectic.lisp" "legal-event-calculus.lisp" "legal-extraction-verify.lisp" "legal-hypergraph.lisp"
  "legal-hypo.lisp" "legal-id-registry.lisp" "legal-identity.lisp" "legal-inference-engine.lisp"
  "legal-knowledge.lisp" "legal-penalty.lisp" "legal-precedent.lisp" "legal-qa.lisp"
  "legal-reasoning-bridge.lisp" "legal-references.lisp" "legal-strategy.lisp" "legal-subsumption.lisp"
  "legal-temporal.lisp" "legislation-ingestion.lisp" "lexicon-neurolingo.lisp" "logging.lisp"
  "mcp-server.lisp" "memory.lisp" "narrative-provenance.lisp" "orthography-lexicon.lisp" "paths.lisp"
  "proposals.lisp" "protocols.lisp" "provenance-link.lisp" "rdfs-inference.lisp"
  "reasoning-authority.lisp" "review-queue.lisp" "review-service.lisp" "self-history.lisp" "self-model.lisp"
  "semantic-authority.lisp" "semantic-versioning-system.lisp" "shacl-validator.lisp"
  "signed-embedding-manifest.lisp" "source-profile.lisp" "sparql-endpoint.lisp" "static-site.lisp"
  "text-canonicalizer.lisp" "timestamp-authority.lisp" "trace-core.lisp" "turtle-parser.lisp"
  "typographic-classifier.lisp" "validate-ast.lisp" "validate-layout-graph.lisp"
  "validate-logical-blocks.lisp" "validation-authority.lisp" "what-if.lisp"
  "x509-authority.lisp"))
