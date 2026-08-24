(:lawmax-phase1a-cluster/1
 :cluster "source"
 :status :complete
 :files-read 133
 :files-total 133
 :read-since-checkpoint-6 ("ai-citation-strategy.lisp" "ai-ingest-manifest.lisp" "citation-authority.lisp" "corpus-service.lisp"
   "eu-interop-layer.lisp" "greek-lemmatizer.lisp" "greek-nlp-core.lisp" "greek-tokenizer-advanced.lisp"
   "layout-types.lisp" "legal-casegrammar.lisp" "legal-decisions.lisp" "legal-extraction-verify.lisp"
   "legal-inference-engine.lisp" "lexicon-neurolingo.lisp" "narrative-provenance.lisp" "orthography-lexicon.lisp"
   "rdfs-inference.lisp" "reasoning-authority.lisp" "semantic-authority.lisp" "semantic-versioning-system.lisp"
   "sparql-endpoint.lisp" "static-site.lisp" "typographic-classifier.lisp" "validate-ast.lisp"
   "validate-layout-graph.lisp" "validate-logical-blocks.lisp")
 :read-since-checkpoint-5 ("fluid-induction.lisp" "legal-knowledge.lisp" "shacl-validator.lisp" "legal-subsumption.lisp"
   "signed-embedding-manifest.lisp" "embeddings-authority.lisp" "text-canonicalizer.lisp" "turtle-parser.lisp"
   "source-profile.lisp")
 :read-since-checkpoint-4 ("guard-ops-pack.lisp" "legal-temporal.lisp" "legal-event-calculus.lisp" "legal-dialectic.lisp" "legal-hypo.lisp" "legal-counterfactual.lisp"
   "graph-reasoning.lisp" "corpus-sparql.lisp" "execution-trace.lisp" "legal-strategy.lisp" "legal-conflict-resolution.lisp"
   "legal-qa.lisp" "legal-precedent.lisp" "provenance-link.lisp" "ai-corpus-dump.lisp" "legal-references.lisp"
   "corpus-eu-links.lisp" "legal-reasoning-bridge.lisp" "legal-penalty.lisp" "legal-hypergraph.lisp" "legal-deontic.lisp"
   "akoma-ntoso-emitter.lisp" "generation.lisp" "greek-legislation-ontology.lisp" "protocols.lisp")
 :read-since-checkpoint-3 ("injection.lisp" "guard-metaeval.lisp" "trace-core.lisp" "logging.lisp"
   "legal-identity.lisp" "legal-id-registry.lisp" "json-emit.lisp" "deliberation.lisp" "mcp-server.lisp"
   "review-service.lisp" "knowledge-graph.lisp" "knowledge-packs.lisp" "government-source.lisp"
   "ingestion-daemon.lisp" "legislation-ingestion.lisp" "validation-authority.lisp" "legal-ast.lisp"
   "legal-audit-system.lisp" "legal-authority-receipt.lisp" "authority-evidence-replay.lisp"
   "blockchain-authority.lisp")
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
   :evidence "source/safe-read.lisp:L39-L349@sha256:590133b311d0")

  (:name "canonical data-only serialization (write side)"
   :presence :present
   :domain "FORM → string που το read-data-string ξαναδιαβάζει ακέραιο."
   :assumptions "Το form είναι data-only."
   :guarantees "%data-only-p ΠΡΙΝ την εγγραφή (fail-closed)· *print-readably* NIL (αποφυγή #A(...) literals)· keyword package· double-float· χωρίς pretty/circle· byte-cap στο αποτέλεσμα."
   :failure-semantics "safe-read-error (σφάλμα, όχι NIL) σε μη-data-only form ή υπέρβαση cap."
   :operating-model "Καθαρή συνάρτηση."
   :materiality "Συμμετρία γραφής/ανάγνωσης — «ό,τι γράφεται μπορεί να διαβαστεί»."
   :evidence "source/safe-read.lisp:L312-L339@sha256:590133b311d0")

  (:name "RFC 6962/9162 Merkle (leaf/node domain separation, unbalanced split)"
   :presence :present
   :domain "Δέντρα Merkle: ρίζα, inclusion path, consistency proof, επαλήθευση."
   :assumptions "hashes σε μορφή 'sha256:HEX'· η ΣΕΙΡΑ των φύλλων είναι μέρος του commitment."
   :guarantees "leaf=SHA256(0x00‖bytes), node=SHA256(0x01‖raw(L)‖raw(R))· ΟΧΙ duplicate-last (κλάση CVE-2012-2459 δομικά αδύνατη)· verify-consistency fail-closed ακόμη και σε κακοσχηματισμένα hashes."
   :failure-semantics "verify-inclusion/verify-consistency ⇒ NIL σε κάθε απόκλιση· merkle-tree-hash σε κενό εύρος ⇒ error· inclusion-path σε out-of-range index ⇒ error."
   :operating-model "Καθαρές συναρτήσεις πάνω σε ironclad."
   :materiality "Ο σκελετός κάθε απόδειξης του ιδρύματος."
   :evidence "source/merkle-authority.lisp:L54-L235@sha256:ad734ad2052d")

  (:name "proof-carrying provision (text→leaf→path→root→JWS)"
   :presence :present
   :domain "Ανά-διάταξη φορητή απόδειξη + corpus-level υπογεγραμμένος anchor + δημόσιος verifier σε JSON."
   :assumptions "Η υπογραφή απαιτεί ΦΟΡΤΩΜΕΝΟ orchestrator.jws-authority (αναζήτηση με find-symbol)."
   :guarantees "verify-provision-proof: αλλοιωμένο byte ⇒ :text-hash-mismatch· πλαστό path ⇒ :inclusion-failed· verify-full-chain ελέγχει ΚΑΙ root-match ΚΑΙ υπογραφή· ΡΗΤΟ trust_status ('signed'|'unsigned-explicit') μέσα στο JSON· +max-path-length+ 64 (DoS bound)."
   :failure-semantics "(values nil reason) ονομαστικά· κενό corpus ⇒ ΣΦΑΛΜΑ empty-corpus-publication (ΟΧΙ σιωπηλό no-op)."
   :operating-model "Καθαρό/ντετερμινιστικό· γράφει αρχεία JSON στο output-dir."
   :materiality "Το «trust root» που τρίτοι επαληθεύουν χωρίς να μας εμπιστεύονται."
   :evidence "source/proof-carrying.lisp:L50-L295@sha256:c18f7ddb07b1")

  (:name "append-only chained journal (single-writer, receipts)"
   :presence :present
   :domain "Ημερολόγια plist-ανά-γραμμή με SHA-256 αλυσίδα (βιογραφία, προτάσεις, επεισόδια, version-graph)."
   :assumptions "Ένα plist ανά record· :at σε canonical UTC ISO-8601 σταθερού πλάτους· SBCL (sb-posix/sb-alien/flock)."
   :guarantees "thread mutex + flock(2) LOCK_EX ανά path (cross-process single writer)· compare-and-append (STALE-CHAIN-LINK πριν γραφτεί οτιδήποτε)· προ-εγγραφικός έλεγχος σειριοποίησης (UNSERIALIZABLE-RECORD)· μονοτονία transaction-time (NON-MONOTONIC-TRANSACTION-TIME)· fsync fail-closed (SYNC-FAILURE ⇒ ΠΟΤΕ :durable)· write-file-atomic = tmp+fsync+rename+fsync(dir)."
   :failure-semantics "receipt :durability ∈ {:durable :sync-failed :failed-verification :ephemeral-replica :degraded-memory-only}· require-durable! υψώνει NOT-DURABLE. Κολοβή γραμμή ⇒ ΔΗΛΩΝΕΤΑΙ στο *error-output* και προσπερνιέται."
   :operating-model "Stateful (in-memory cache ανά path)· side-effects στον δίσκο."
   :materiality "Η μοναδική έδρα «γράφτηκε πραγματικά;» όλου του θεσμού."
   :evidence "source/journal.lisp:L104-L576@sha256:ee440c102989")

  (:name "constitutional gate (κανόνας-μητρώο + ρητή παράκαμψη)"
   :presence :present
   :domain "Κρίση «επιτρέπεται αυτή η πράξη;» πριν από εκτέλεση εντολής."
   :assumptions "Οι κανόνες δηλώνονται από τους καταναλωτές (open/closed)· η ΜΕΣΟΛΑΒΗΣΗ γίνεται αλλού (CLOS method-combination στον καταναλωτή)."
   :guarantees "Πρώτη παράβαση ⇒ (values nil article reason id)· η παράκαμψη απαιτεί ΚΑΙ εμβέλεια (--force ή LAWMAX_OVERRIDE=<cmd>) ΚΑΙ αιτιολογία (LAWMAX_OVERRIDE_REASON)."
   :failure-semantics "ΣΦΑΛΜΑ ΜΕΣΑ ΣΕ ΚΑΝΟΝΑ ⇒ FAIL-OPEN (ο κανόνας θεωρείται ότι επιτρέπει)."
   :operating-model "Global mutable *rules* list· καμία λογική πεδίου εδώ."
   :materiality "Ο δηλωμένος «υπέρτατος φραγμός»."
   :evidence "source/constitutional-gate.lisp:L22-L71@sha256:33522d186e21")

  (:name "deterministic time"
   :presence :present
   :domain "Ενιαία πηγή χρονοσφραγίδων για αναπαραγώγιμα artifacts."
   :assumptions "SOURCE_DATE_EPOCH ή ρητή κλήση configure-deterministic-time."
   :guarantees "require-deterministic-time ΣΦΑΛΛΕΙ αν δεν είναι ενεργή η ντετερμινιστική λειτουργία (καμία σιωπηλή wall-clock)· (now :source …) απαιτεί ΡΗΤΟ source."
   :failure-semantics "ΜΙΚΤΗ: require-deterministic-time = error· (now :source :deterministic) = ΣΙΩΠΗΛΟ fallback σε get-universal-time."
   :operating-model "Global μεταβλητές *deterministic-mode*/*fixed-timestamp*· αυτο-αρχικοποίηση στο LOAD από env."
   :materiality "Κάθε byte-identical δημοσίευση εξαρτάται από εδώ."
   :evidence "source/deterministic-time.lisp:L52-L220@sha256:6dbda9c2fc1c")

  (:name "cognitive pipeline (5 στάδια, LLM σύμβουλος ΕΚΤΟΣ εμπιστοσύνης)"
   :presence :present
   :domain "Φυσική γλώσσα → frame → πλάνο → επαληθευμένα βήματα → απάντηση."
   :assumptions "*advisor* είναι κλείσιμο (purpose input)→spec|nil· nil ⇒ καθαρά συμβολική λειτουργία."
   :guarantees "Ο σύμβουλος ΠΡΟΤΕΙΝΕΙ μόνο αποδόμηση (στάδιο 1)· τα στάδια 2/3/5 είναι CLOS generics· απόρριψη αυτο-κριτικής ΔΗΛΩΝΕΤΑΙ στην απάντηση· κενό προσχέδιο ⇒ NIL (τίμια άγνοια)."
   :failure-semantics "decompose ⇒ nil ⇒ (values nil cog): «δεν αποδομήθηκε»."
   :operating-model "Global *advisor*/*classifiers*· synchronized working-memory."
   :materiality "Το σημείο όπου LLM αγγίζει το σύστημα."
   :evidence "source/cognition.lisp:L62-L184@sha256:f54ace6cb73d")

  (:name "εξωτερική λήψη εγγράφου (ΦΕΚ/PDF/DOCX) με SSRF φρουρό"
   :presence :present
   :domain "Κατέβασμα ΦΕΚ από public Azure blob, PDF/DOCX από αυθαίρετο URL, ή μέσω εξωτερικού shell fetcher."
   :assumptions "drakma vendored· ο operator ορίζει το fetch-command· {{out}} placeholder."
   :guarantees "Έλεγχος magic bytes (%PDF- / PK\\03\\04) — anti-bot HTML ΑΠΟΡΡΙΠΤΕΤΑΙ· redirects ακολουθούνται ΧΕΙΡΟΚΙΝΗΤΑ (≤5) με SSRF έλεγχο ΑΝΑ HOP· loopback επιτρέπεται μόνο υπό dynamic *allow-loopback-fetch* (όχι env flag)."
   :failure-semantics "(values nil status) ονομαστικά· ΠΟΤΕ throw."
   :operating-model "Δίκτυο + εκτέλεση /bin/sh."
   :materiality "Το μοναδικό σημείο εισόδου εξωτερικού περιεχομένου στο corpus."
   :evidence "source/document-fetch.lisp:L92-L323@sha256:bb114b83fd80")

  (:name "system self-constitution (ανάγνωση + μετρήσιμη αποστολή)"
   :presence :present
   :domain "deployment/SYSTEM-CONSTITUTION.sexp: ποιον υπηρετεί, άρθρα, αποστολές."
   :assumptions "Η θέση επιλύεται στο RUNTIME μέσω orchestrator.paths:institution-dir."
   :guarantees "SHA-256 ταυτότητα· άκυρο κείμενο ⇒ κρατιέται το προηγούμενο ΚΑΙ δηλώνεται· αποστολή χωρίς εγγεγραμμένη μέτρηση δηλώνεται ΑΜΕΤΡΗΤΗ (ποτέ «εκπληρωμένη»)."
   :failure-semantics "Απουσία αρχείου ⇒ *constitution* μένει NIL, describe επιστρέφει 1."
   :operating-model "Global *constitution* + *measures* registry (αντίστροφη εξάρτηση: ο μετρητής εγγράφεται)."
   :materiality "Η δηλωμένη ταυτότητα του συστήματος."
   :evidence "source/self-constitution.lisp:L29-L132@sha256:24cfed7c844e")

  (:name "generic content hash authority"
   :presence :present
   :domain "Αυθαίρετο περιεχόμενο → hex hash με ΡΗΤΟ algorithm."
   :assumptions "Δηλωμένη ΑΚΡΙΒΗΣ εμβέλεια: ΔΕΝ είναι η μόνη hash — protocol-local hashes (JWS/X.509/TSA/Merkle/keccak) ζουν αλλού, με μητρώο deployment/verify/hash-seat-registry.sexp."
   :guarantees "Σφάλμα αν λείπει/είναι άγνωστο το :algorithm."
   :failure-semantics "error (fail-fast)."
   :operating-model "Καθαρή συνάρτηση."
   :materiality "Content-addressing."
   :evidence "source/hash-authority.lisp:L11-L59@sha256:280a7c5bb315")

  (:name "RDF write authority scope"
   :presence :present
   :domain "Εγγραφή TTL/RDF περιεχομένου με ρητή αυθεντία (:canonical|:provenance)."
   :assumptions "ΔΗΛΩΝΕΙ ότι είναι «the ONLY authorized write function for RDF content»."
   :guarantees "Σφάλμα χωρίς :authority· σφάλμα σε scope violation· σφάλμα σε φωλιασμένο with-write-authority."
   :failure-semantics "error (fail-fast)."
   :operating-model "Dynamic *current-write-authority*."
   :materiality "Διαχωρισμός canonical/provenance γράφων."
   :evidence "source/write-authority.lisp:L12-L73@sha256:f2fbb95e2a76")

  (:name "institution ontology (Ίδρυμα + ρόλοι)"
   :presence :present
   :domain "Δηλωμένη θεσμική ταυτότητα: ένα Ίδρυμα, ρόλοι/αίθουσες."
   :assumptions "Οι δηλώσεις γίνονται από αλλού (declare-institution!/declare-role!)."
   :guarantees "Idempotent αντικατάσταση κατά όνομα· «δεν υπάρχει δεύτερο Ίδρυμα» (ένα global)."
   :failure-semantics :unknown
   :operating-model "Global mutable structs."
   :materiality "Ονοματολογία/ταυτότητα, όχι μηχανισμός επιβολής."
   :evidence "source/institution.lisp:L26-L61@sha256:8c8f820e39b5")

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
   :evidence "source/authority-proof-bundle.lisp:L295-L658@sha256:1946af4ad92b")

  (:name "διτεμπορικός γράφος εκδόσεων (νομικός χρόνος)"
   :presence :present
   :domain "Αμετάβλητοι κόμβοι-κείμενα × typed ακμές τροποποίησης × καθεστωτικές ακμές × αιρέσεις έναρξης ισχύος, με [valid-from,valid-until) × [recorded-from,recorded-until)."
   :assumptions "Το journal είναι η αυθεντία· η προβολή μνήμης ξαναχτίζεται με ΠΛΗΡΕΣ replay· legal-date/legal-instant typed (γνήσιος γρηγοριανός έλεγχος, ASCII-only ψηφία)."
   :guarantees "G1 replay-then-append (ασυμφωνία ⇒ καραντίνα)· G2 ολική διάταξη· G3 payload-hash + chain ανά γραμμή (αλλοίωση ΟΠΟΙΟΥΔΗΠΟΤΕ πεδίου σπάει το replay)· G5 retract αντί διαγραφής· καραντίνα ΩΣ ΤΥΠΟΣ (αόρατη στην επιλογή)· μη υποστηριζόμενες πράξεις ⇒ ΡΗΤΟ :unsupported-op· scope :unknown ⇒ typed SCOPE-UNCERTAIN ή ρητό :conservative με μη-αφαιρέσιμο analytical marker."
   :failure-semantics "invalid-edge (client) vs journal-corruption (server-integrity) — ΞΕΧΩΡΙΣΤΟΙ τύποι· temporal-uncertainty αντί μαντεψιάς· κενό γνώσης δηλωμένο."
   :operating-model "Stateful προβολή· κάθε πράξη journal-first."
   :materiality "Η απάντηση «τι ίσχυε πότε, κατά τη γνώση του πότε»."
   :evidence "source/version-graph.lisp:L221-L1459@sha256:d6b181de2ad1")

  (:name "deterministic effectivity attestation (χωρίς online κλειδί)"
   :presence :present
   :domain "Πιστοποιητικό ισχύος διάταξης στην τομή (valid-at, known-at) — value-canonical string + sha256."
   :assumptions "Ο anchor είναι OPAQUE τύπος: verified κατασκευάζεται ΜΟΝΟ από release-anchor-for (private constructor)· provisional από δημόσιο make-provisional-anchor."
   :guarantees "Καμία υπογραφή — ο verifier ΑΝΑΠΑΡΑΓΕΙ byte-wise· plist που «μοιάζει» anchored ΔΕΝ γίνεται δεκτό· assurance μέσα στο hash· read-only slots (provisional δεν «βάφεται» verified)."
   :failure-semantics "outcome sum type: resolved | no-version-in-force | not-yet-effective | suspended | scope-uncertain | unknown-provision | uncertain."
   :operating-model "Καθαρή συνάρτηση πάνω στον γράφο."
   :materiality "Το εξαγόμενο πιστοποιητικό προς τρίτους."
   :evidence "source/version-graph.lisp:L2458-L2613@sha256:d6b181de2ad1")

  (:name "ντετερμινιστική εξαγωγή νομοτεχνικών πράξεων από ΦΕΚ"
   :presence :present
   :domain "Κείμενο τροποποιητικού → λίστα πράξεων (:replace-text/:repeal/:insert/:mark-amended) με scope routing."
   :assumptions "Ελληνικοί νομοτεχνικοί τύποι· ο resolver έρχεται από το registry (orchestrator.legal-id) — ΧΩΡΙΣ resolver καμία δρομολόγηση."
   :guarantees "Balanced «…» (καμία περικοπή)· μάσκα παραθέσεων (νέο κείμενο δεν ξαναδρομολογεί)· scope ΑΥΣΤΗΡΑ ενδο-ενοτικό· αυτο-αναφορά σε δικό του άρθρο ⇒ :low + :self-reference· αντίφαση με census ⇒ :identity :contradicted."
   :failure-semantics "Χαμηλής εμπιστοσύνης πράξεις ΑΝΑΓΝΩΡΙΖΟΝΤΑΙ, ποτέ δεν πέφτουν σιωπηλά· μόνο :high αυτο-εφαρμόζεται."
   :operating-model "Καθαρή συνάρτηση (regex/cl-ppcre)· κανένα LLM."
   :materiality "Ο κρίκος «δημοσιευμένο ΦΕΚ → ενοποίηση»."
   :evidence "source/amendment-extractor.lisp:L340-L546@sha256:407642a40548")

  (:name "PDF text/layout extraction (libpoppler CFFI) + OCR κλιμάκωση"
   :presence :present
   :domain "PDF → κείμενο (plain / header-footer clipped / column-reflowed) και layout graph (spans/lines/blocks/pages)."
   :assumptions "libpoppler-glib φορτώνεται ΤΕΜΠΕΛΙΚΑ στο runtime (όχι στο save-core)· OCR απαιτεί pdftoppm+tesseract+ell."
   :guarantees "extract-text-any επιστρέφει ΚΑΙ την ΠΗΓΗ (:text-layer|:ocr|:none)· ocr-available-p ρητό· XY-cut reflow καθαρή/δοκιμασμένη συνάρτηση."
   :failure-semantics "typed conditions (pdf-not-found/pdf-open-error/pdf-layout-error)· αλλά ανά-σελίδα σφάλμα layout ⇒ ΚΕΝΗ σελίδα με warn."
   :operating-model "FFI + εξωτερικές διεργασίες + /tmp."
   :materiality "Η μοναδική ανάγνωση αυθεντικών ΦΕΚ bytes."
   :evidence "source/pdf-authority.lisp:L381-L1439@sha256:c4e2054c0e4f")

  (:name "capability registry + transport-agnostic API projection"
   :presence :present
   :domain "Δηλωτικό συμβόλαιο ανά δυνατότητα (name/params/result/trust/proof/fn)· HTTP/MCP/CLI = προβολές."
   :assumptions "Κλειστό +param-types+ = {:string :keyword :any :integer :boolean}."
   :guarantees "ΝΟΜΟΣ ΜΙΑΣ ΕΔΡΑΣ: επανεγγραφή από ΑΛΛΟ αρχείο ⇒ capability-seat-collision· ανώνυμο runtime site ΔΕΝ επαναδιεκδικεί· :trust επιβάλλεται ΔΙΠΛΑ (pre-check + invoke)· coercion fail-closed· ΚΑΝΕΝΑ intern σε μη-έμπιστη είσοδο (find-symbol μόνο) — intern-DoS δομικά αδύνατο."
   :failure-semantics "403/404/400/500 ονομαστικά· καμία εξαίρεση δεν διαφεύγει."
   :operating-model "Global hash-tables (*capabilities*, *capability-owners*)."
   :materiality "Το σημείο όπου «κανένα LLM στο trusted path» γίνεται μηχανισμός."
   :evidence "capability-registry.lisp:40-207 · source/capability-api.lisp:L37-L147@sha256:493200e4807d")

  (:name "μητρώο συμβολαίων + μηχανικός επικυρωτής"
   :presence :present
   :domain "Δηλωμένες υποσχέσεις ανά συνάρτηση/πρωτόκολλο/εντολή με legal-critical/policy-level/tests/audit/rollback."
   :assumptions "Τα κατηγορήματα ύπαρξης (capability/role/test) δίνονται ΑΠΟ ΤΟΝ ΚΑΛΟΥΝΤΑ (διαχωρισμός στρωμάτων)."
   :guarantees "legal-critical ΧΩΡΙΣ policy-level/tests ⇒ παράβαση· με side-effects ΧΩΡΙΣ audit/rollback ⇒ παράβαση· ανύπαρκτη ικανότητα/ρόλος/τεστ ⇒ παράβαση."
   :failure-semantics "Λίστα παραβάσεων (strings)· ΔΕΝ μπλοκάρει από μόνο του — ο καλών (πύλη) το κάνει."
   :operating-model "Global διατεταγμένη λίστα *contracts*."
   :materiality "Η μηχανική μορφή των υποσχέσεων."
   :evidence "source/contracts.lisp:L43-L167@sha256:e9e619500aee")

  (:name "canonical JSON (RFC 8785 JCS) + canonical vector bytes + canonical ids"
   :presence :present
   :domain "Ντετερμινιστική σειριοποίηση για hashing/υπογραφή· IEEE-754 binary32 little-endian για embeddings· περιεχομενο-παραγόμενα @id."
   :assumptions "ΔΗΛΩΝΕΙ συμμόρφωση RFC 8785 και «bit-perfect reproducibility across implementations»."
   :guarantees "Ταξινόμηση κλειδιών, χωρίς κενά, πεζά \\u escapes, NaN/Inf → 0.0 στα διανύσματα."
   :failure-semantics "etypecase ⇒ σφάλμα σε μη υποστηριζόμενο τύπο."
   :operating-model "Καθαρές συναρτήσεις."
   :materiality "Κάθε version-hash/edge-hash του version-graph περνά από εδώ (canonical-hash)."
   :evidence "source/canonical-representation.lisp:L91-L278@sha256:a72286188ff9")

  (:name "canonical URI sovereignty"
   :presence :present
   :domain "Η ΜΙΑ πηγή όλων των URI (base/eli/corpus/identity/policy/ontology) από configs/constitution.yaml."
   :assumptions "ΚΑΝΕΝΑ default — «If configuration is missing, the system MUST fail hard»."
   :guarantees "Κάθε getter ΣΦΑΛΛΕΙ αν λείπει η ρύθμιση· validate-uri/assert-canonical-uri· ωμός ακέραιος ως ταυτότητα άρθρου εκπέμπει ΟΡΑΤΟ :identity-debt ίχνος."
   :failure-semantics "error (fail-hard)."
   :operating-model "Global hash-table *canonical-config*."
   :materiality "Η μία ταυτότητα του συστήματος στο διαδίκτυο."
   :evidence "source/canonical-uris.lisp:L53-L264@sha256:3481b0caf826")

  (:name "αυτόνομος οδηγός αποστολών"
   :presence :present
   :domain "Στόχος + αντικείμενα + βήμα → εκτέλεση με προϋπολογισμό, δρομέα στη μνήμη, στάση σε συστηματική αποτυχία."
   :assumptions "Το ΒΗΜΑ είναι υπεύθυνο να επαληθεύει (ο οδηγός δεν εμπιστεύεται, καταγράφει)."
   :guarantees "Καμία αυτόνομη μετάλλαξη: ό,τι παράγεται πάει σε ΟΥΡΑ ΠΡΟΤΑΣΕΩΝ· N συνεχόμενα σφάλματα ⇒ ΣΤΑΣΗ + αναφορά· ατζέντα κλείνει ΜΟΝΟ όταν καλυφθούν όλα."
   :failure-semantics "Σφάλμα βήματος ⇒ :error μετρημένο και δηλωμένο (όχι σιωπή)."
   :operating-model "Global μητρώο αποστολών· γράφει στη μνήμη/ιστορία."
   :materiality "Το «τρέχει μόνο του» του συστήματος."
   :evidence "source/autonomy.lisp:L26-L124@sha256:4c36bb35f209")

  (:name "μητρώο συστατικών + γράφος ακμών"
   :presence :present
   :domain "Ταυτότητα κάθε συστατικού (system/file/package/symbol/gate) + ακμές εξάρτησης."
   :assumptions "Η ΚΑΤΑΣΚΕΥΗ ζει στο component-scan — εδώ μόνο ταυτότητες/ακμές."
   :guarantees "Διπλό id ⇒ ΣΦΑΛΜΑ duplicate-component-id (ποτέ σιωπηλή αντικατάσταση)· role NIL = ΟΡΑΤΟ χρέος."
   :failure-semantics "error."
   :operating-model "Global hash-table + λίστα ακμών."
   :materiality "«Ό,τι δεν ταυτοποιείται δεν θεωρείται γνωστό»."
   :evidence "source/components.lisp:L26-L98@sha256:62460c81018c")

  (:name "υποβολή στο Archive.org (Wayback) ως «100-year proof»"
   :presence :spec-only
   :domain "Δημόσια τρίτη μαρτυρία χρονικής ύπαρξης release."
   :assumptions "drakma· δίκτυο."
   :guarantees "ΚΑΜΙΑ επαληθεύσιμη: δεν ελέγχεται HTTP status, δεν εξάγεται το πραγματικό archived URL, δεν επαληθεύεται η αρχειοθέτηση."
   :failure-semantics "Σφάλμα ⇒ plist :status :failed (τίμιο)· ΑΛΛΑ η «επιτυχία» δηλώνεται χωρίς τεκμήριο."
   :operating-model "Δίκτυο, χωρίς SSRF φρουρό, χωρίς ντετερμινιστικό χρόνο."
   :materiality "Δηλώνεται ως απόδειξη χρονικής προτεραιότητας."
   :evidence "source/archive-authority.lisp:L56-L159@sha256:36f78fe7b609")

  (:name "AST δομική πύλη πάνω στο σερβιρισμένο corpus"
   :presence :present
   :domain "Ανύψωση ενοποιημένου corpus σε legal-ast document-node και εκτέλεση των Layer-4 validators."
   :assumptions "Οι accessors της consolidation επιλύονται ΔΥΝΑΜΙΚΑ (find-symbol) — «defensive pattern» κοινό με άλλα modules."
   :guarantees "Lettered article ids (100Α) μένουν strings (η διακριτότητα διατηρείται)· *require-trace-chain* NIL εδώ (δηλωμένο)."
   :failure-semantics "(values valid-p result) — ΣΥΜΒΟΥΛΕΥΤΙΚΗ πύλη, δεν μπλοκάρει."
   :operating-model "Καθαρό CLOS."
   :materiality "Ζωντανεύει προηγουμένως νεκρούς validators."
   :evidence "source/ast-gate.lisp:L53-L127@sha256:65724a01525c")

  (:name "ανίχνευση ανωμαλιών εξαγωγής ανά άρθρο"
   :presence :present
   :domain "Υπογραφές σφάλματος εξαγωγής: κενό, καθόλου ελληνικά, χαμηλός λόγος ελληνικών, υπολειμματικός θόρυβος (URL/print chrome)."
   :assumptions "Ελληνικό corpus."
   :guarantees "Ντετερμινιστικό, υψηλής ακρίβειας· δεν τιμωρεί σύντομα/καταργημένα άρθρα."
   :failure-semantics "(values ok-p findings) με ονομαστικούς λόγους ανά άρθρο."
   :operating-model "Καθαρή συνάρτηση + find-symbol accessors."
   :materiality "Τροφοδοτεί την ουρά ανθρώπινου ελέγχου."
   :evidence "source/anomaly-detection.lisp:L54-L93@sha256:43c44bf86b01")

  (:name "ledger υιοθετήσεων (what-if governed adoption)"
   :presence :present
   :domain "Απόφαση υιοθέτησης πρότασης: verdict ∈ {:allowed :requires-human :shadow-only :denied} + διαρκές ledger."
   :assumptions "Η υιοθέτηση ΧΩΡΙΣ what-if είναι «αδύνατη εκ κατασκευής»· απαιτείται δηλωμένο Ίδρυμα, αρχεία, σχέδιο σκιάς."
   :guarantees "Ελλείψεις ⇒ :denied· legal-critical χωρίς άνθρωπο/πολιτική ⇒ :requires-human· require-durable! στο ledger· validate-adoption-records επαληθεύει υπογραφή + ύπαρξη πρότασης."
   :failure-semantics "NOT-DURABLE σφάλμα αν δεν αποθηκεύτηκε."
   :operating-model "Journal ledger + trace emit."
   :materiality "«Τίποτα δεν γίνεται trusted επειδή δουλεύει»."
   :evidence "source/adoption-decision.lisp:L23-L132@sha256:fd26b0d91f89"))

 :authorities
 ((:name "safe-read: η ΜΙΑ έδρα cl:read σε data path"
   :what-it-can-decide "Τι είναι «δεδομένο» (data-only υποσύνολο) και τι απορρίπτεται· τα caps βάθους/atoms/bytes."
   :who-can-invoke "Κάθε module που διαβάζει sexp store (self-constitution, trace-core, legal-ast, component-scan, greek-nlp-core, knowledge-graph, version-graph, legal-subsumption, what-if…)."
   :enforcement :code
   :evidence "source/safe-read.lisp:L152-L186@sha256:590133b311d0")

  (:name "constitutional override (δημιουργός)"
   :what-it-can-decide "Παράκαμψη ΟΠΟΙΟΥΔΗΠΟΤΕ συνταγματικού κανόνα για συγκεκριμένη εντολή."
   :who-can-invoke "Όποιος ελέγχει τα ορίσματα CLI (--force) Ή τις env vars LAWMAX_OVERRIDE + LAWMAX_OVERRIDE_REASON της διεργασίας."
   :enforcement :code
   :evidence "source/constitutional-gate.lisp:L49-L71@sha256:33522d186e21")

  (:name "journal require-durable! («id ⟺ durable»)"
   :what-it-can-decide "Αν μια θεσμική ταυτότητα (πρόταση/υιοθέτηση/πολιτική) επιτρέπεται να εκδοθεί."
   :who-can-invoke "Κάθε ΘΕΣΜΙΚΟΣ συγγραφέας ημερολογίου."
   :enforcement :code
   :evidence "source/journal.lisp:L343-L350@sha256:ee440c102989")

  (:name "publication gate: κενό corpus ΔΕΝ υπογράφεται"
   :what-it-can-decide "Άρνηση δημοσίευσης corpus με leaf_count = 0."
   :who-can-invoke "write-provision-proofs (η μία πύλη δημοσίευσης PCL)."
   :enforcement :code
   :evidence "source/proof-carrying.lisp:L185-L207@sha256:c18f7ddb07b1")

  (:name "write-authority: ποιος γράφει RDF και με ποια ιδιότητα"
   :what-it-can-decide ":canonical vs :provenance· φωλιασμένο scope απαγορεύεται."
   :who-can-invoke "Κάθε high-level RDF writer — ΑΛΛΑ μόνο κατά σύμβαση (τίποτα δεν εμποδίζει απευθείας with-open-file)."
   :enforcement :convention
   :evidence "source/write-authority.lisp:L16-L51@sha256:f2fbb95e2a76")

  (:name "*advisor* (LLM εκτός εμπιστοσύνης)"
   :what-it-can-decide "ΜΟΝΟ πρόταση αποδόμησης (στάδιο 1)· δεν αποφασίζει απάντηση."
   :who-can-invoke "Όποιος κάνει setf στο orchestrator.cognition:*advisor* (global, χωρίς φρουρό)."
   :enforcement :convention
   :evidence "source/cognition.lisp:L62-L89@sha256:f54ace6cb73d")

  (:name "*allow-loopback-fetch* (SSRF χαλάρωση)"
   :what-it-can-decide "Επιτρέπει loopback fetch — ΜΟΝΟ ως dynamic binding, ΟΧΙ env flag (απόφαση [0036] Δ1)."
   :who-can-invoke "Test harness εντός δυναμικής εμβέλειας."
   :enforcement :code
   :evidence "source/document-fetch.lisp:L228-L256@sha256:bb114b83fd80")

  (:name "LAWMAX_REPLICA (εφήμερα ημερολόγια)"
   :what-it-can-decide "Αν η διεργασία γράφει ΠΟΤΕ στον δίσκο· διαβάζεται ΜΙΑ φορά στο LOAD (defvar)."
   :who-can-invoke "Το περιβάλλον της διεργασίας."
   :enforcement :os
   :evidence "source/journal.lisp:L180-L187@sha256:ee440c102989")

  (:name "SOURCE_DATE_EPOCH (ντετερμινιστικός χρόνος)"
   :what-it-can-decide "Αν κάθε output-bound timestamp είναι παγωμένος· εφαρμόζεται αυτόματα στο LOAD."
   :who-can-invoke "Το περιβάλλον της διεργασίας."
   :enforcement :os
   :evidence "source/deterministic-time.lisp:L202-L220@sha256:6dbda9c2fc1c")

  (:name "capability seat owner (ΝΟΜΟΣ ΜΙΑΣ ΕΔΡΑΣ)"
   :what-it-can-decide "Ποιο αρχείο κατέχει μια δυνατότητα· εμποδίζει σιωπηλή αντικατάσταση trust/fn/schema/proof από άλλο αρχείο."
   :who-can-invoke "register-capability στο LOAD (μέσω orchestrator.paths:current-load-file)."
   :enforcement :code
   :evidence "source/capability-registry.lisp:L122-L134@sha256:d9161b5bc1cd")

  (:name ":trust της δυνατότητας (κανένα LLM στο trusted path)"
   :what-it-can-decide "Αν μια δυνατότητα εκτελείται σε trusted επιφάνεια· διπλή επιβολή (pre-check + έδρα)."
   :who-can-invoke "Ο δηλωτής της δυνατότητας ορίζει το :trust· η επιφάνεια ορίζει το :require-trust."
   :enforcement :code
   :evidence "source/capability-api.lisp:L108-L111@sha256:493200e4807d · source/capability-registry.lisp:L195-L206@sha256:d9161b5bc1cd")

  (:name "opaque release anchor (verified vs provisional)"
   :what-it-can-decide "Ποιο assurance μπορεί να φέρει ένα attestation· verified ΜΟΝΟ από private constructor."
   :who-can-invoke "release-anchor-for (verified)· οποιοσδήποτε (provisional)."
   :enforcement :code
   :evidence "source/version-graph.lisp:L2479-L2522@sha256:d6b181de2ad1")

  (:name "hygiene waiver (πόρτα εισδοχής κειμένου)"
   :what-it-can-decide "Αν κείμενο με σύνταξη-μεταφοράς εισέρχεται στον γράφο· απαιτείται waiver που ΚΑΤΟΝΟΜΑΖΕΙ ΑΚΡΙΒΩΣ τα ευρήματα."
   :who-can-invoke "Ο καλών της make-version-spec (import/bootstrap)."
   :enforcement :code
   :evidence "source/version-graph.lisp:L645-L686@sha256:d6b181de2ad1")

  (:name "policy του καταναλωτή στο APB (required-tier, freshness floors, witness)"
   :what-it-can-decide "Ποια βαθμίδα αρκεί, αν απαιτείται checkpoint/μάρτυρας, ποιο είναι το anti-rollback κατώφλι."
   :who-can-invoke "Ο ΕΞΩΤΕΡΙΚΟΣ καταναλωτής — ποτέ το bundle."
   :enforcement :code
   :evidence "source/authority-proof-bundle.lisp:L295-L330@sha256:1946af4ad92b source/authority-proof-bundle.lisp:L646-L657@sha256:1946af4ad92b"))

 :invariants
 ((:statement "Καμία εκτέλεση κώδικα από δεδομένα: *read-eval* NIL + ολική #-deny + %data-only-p στο αποτέλεσμα."
   :enforced-by "code (safe-read %with-data-env + +data-readtable+ + %data-only-p)"
   :evidence "source/safe-read.lisp:L82-L99@sha256:590133b311d0 source/safe-read.lisp:L152-L186@sha256:590133b311d0")
  (:statement "Ό,τι γράφεται μπορεί να ξαναδιαβαστεί (συμμετρία data-to-string ↔ read-data-string)."
   :enforced-by "code (fail-closed %data-only-p πριν την prin1)"
   :evidence "source/safe-read.lisp:L326-L339@sha256:590133b311d0")
  (:statement "Δύο διαφορετικά σύνολα φύλλων ΔΕΝ δίνουν ίδια Merkle ρίζα (όχι duplicate-last)."
   :enforced-by "code (unbalanced split)"
   :evidence "source/merkle-authority.lisp:L101-L119@sha256:ad734ad2052d")
  (:statement "Ο θεσμός ΔΕΝ υπογράφει δέσμευση για κενό corpus."
   :enforced-by "code (error empty-corpus-publication πριν από κάθε υπογραφή/εγγραφή)"
   :evidence "source/proof-carrying.lisp:L206-L207@sha256:c18f7ddb07b1")
  (:statement "id ⟺ durable: καμία θεσμική ταυτότητα χωρίς επιβεβαιωμένο fsync."
   :enforced-by "code (require-durable! + receipt)"
   :evidence "source/journal.lisp:L343-L350@sha256:ee440c102989 source/journal.lisp:L469-L479@sha256:ee440c102989")
  (:statement "Ένας συγγραφέας ανά ημερολόγιο, ΚΑΙ μεταξύ διεργασιών."
   :enforced-by "os+code (flock(2) LOCK_EX σε <journal>.lock + recursive thread mutex)"
   :evidence "source/journal.lisp:L126-L170@sha256:ee440c102989")
  (:statement "Καμία διχάλα αλυσίδας: ο δεσμός του νέου record αντιπαραβάλλεται με την πραγματική ουρά."
   :enforced-by "code (chained-append compare-and-append ⇒ STALE-CHAIN-LINK)"
   :evidence "source/journal.lisp:L531-L542@sha256:ee440c102989")
  (:statement "Μονοτονία transaction-time: :at ποτέ γνησίως παλαιότερο από το τελευταίο committed."
   :enforced-by "code (%check-monotonic-at! πριν τον δίσκο)"
   :evidence "source/journal.lisp:L369-L381@sha256:ee440c102989")
  (:statement "Καμία σιωπηλή wall-clock σε δημοσιευμένη χρονική αξίωση."
   :enforced-by "code — ΜΟΝΟ στο require-deterministic-time· ΟΧΙ στο (now :source :deterministic)"
   :evidence "source/deterministic-time.lisp:L155-L176@sha256:6dbda9c2fc1c")
  (:statement "Καμία λήψη προς loopback/private/link-local/metadata host (SSRF), ανά redirect hop."
   :enforced-by "code (url-fetch-allowed-p σε κάθε hop· drakma :redirect nil)"
   :evidence "source/document-fetch.lisp:L243-L291@sha256:bb114b83fd80")
  (:statement "Anti-bot HTML ΠΟΤΕ δεν εισάγεται ως έγγραφο (magic-byte έλεγχος)."
   :enforced-by "code (%magic-file-p· μία πηγή magic table)"
   :evidence "source/document-fetch.lisp:L46-L90@sha256:bb114b83fd80")
  (:statement "Αποστολή χωρίς εγγεγραμμένη μέτρηση δηλώνεται ΑΜΕΤΡΗΤΗ, ποτέ εκπληρωμένη."
   :enforced-by "code (mission-status)"
   :evidence "source/self-constitution.lisp:L105-L115@sha256:24cfed7c844e"))

 :defects
 ((:what "Ο ΣΥΝΤΑΓΜΑΤΙΚΟΣ ΦΡΑΓΜΟΣ ΕΙΝΑΙ FAIL-OPEN: σφάλμα μέσα σε predicate κανόνα ⇒ (values t nil) ⇒ η πράξη ΕΠΙΤΡΕΠΕΤΑΙ. Ένας κανόνας που σπάει (π.χ. λόγω απόντος corpus/αρχείου) εξαφανίζεται σιωπηλά αντί να μπλοκάρει."
   :severity :p0
   :evidence "source/constitutional-gate.lisp:L44-L45@sha256:33522d186e21"
   :is-it-in-the-known-defect-list :unknown)
  (:what "get-unix-timestamp επιστρέφει UNIX epoch σε ντετερμινιστική λειτουργία αλλά (get-universal-time) [epoch 1900] αλλιώς — διαφορά 2.208.988.800s στην ΙΔΙΑ συνάρτηση, χωρίς καμία ένδειξη."
   :severity :p1
   :evidence "source/deterministic-time.lisp:L93-L101@sha256:6dbda9c2fc1c"
   :is-it-in-the-known-defect-list :unknown)
  (:what "(now :source :deterministic) πέφτει ΣΙΩΠΗΛΑ σε get-universal-time όταν το deterministic mode είναι ανενεργό — ενώ το docstring το ορίζει για «ANY timestamp serialized into output artifacts». Δεύτερη, χαλαρή έδρα δίπλα στο fail-closed require-deterministic-time."
   :severity :p1
   :evidence "source/deterministic-time.lisp:L155-L158@sha256:6dbda9c2fc1c"
   :is-it-in-the-known-defect-list :unknown)
  (:what "advise: (ignore-errors (funcall *advisor* …)) — ο σύμβουλος καταπίνεται ΣΙΩΠΗΛΑ. Κρίση: ΤΙΜΙΑ ΑΓΝΟΙΑ (η επιστροφή NIL ελέγχεται ρητά από τον καλούντα decompose, και το συμβόλαιο είναι «spec|nil»), αλλά ΧΩΡΙΣ ΚΑΜΙΑ ΚΑΤΑΓΡΑΦΗ: αποτυχία συμβούλου δεν διακρίνεται από «δεν είχε πρόταση»."
   :severity :p2
   :evidence "source/cognition.lisp:L65-L66@sha256:f54ace6cb73d source/cognition.lisp:L88-L89@sha256:f54ace6cb73d"
   :is-it-in-the-known-defect-list :unknown)
  (:what "decompose: (ignore-errors (funcall fn input)) ανά classifier — ΣΠΑΣΜΕΝΟΣ ταξινομητής προσπερνιέται σιωπηλά και το σύστημα πέφτει στον LLM σύμβουλο χωρίς να το δηλώσει. Ο καλών ΔΕΝ μπορεί να διακρίνει «κανείς δεν ταίριαξε» από «ο ταξινομητής έσπασε»."
   :severity :p1
   :evidence "source/cognition.lisp:L85-L87@sha256:f54ace6cb73d"
   :is-it-in-the-known-defect-list :unknown)
  (:what "write-authority δηλώνει «the ONLY authorized write function for RDF content» αλλά η αποκλειστικότητα είναι ΣΥΜΒΑΣΗ — καμία μηχανική απαγόρευση direct with-open-file."
   :severity :p2
   :evidence "source/write-authority.lisp:L29-L30@sha256:f2fbb95e2a76"
   :is-it-in-the-known-defect-list :unknown)
  (:what "config.lisp: load-config σε σχετικό path 'configs/constitution.yaml' — εξαρτάται από cwd· ΠΑΡΑΚΑΜΠΤΕΙ την έδρα paths.lisp (institution-dir) που υπάρχει ακριβώς γι' αυτό."
   :severity :p2
   :evidence "config.lisp:44"
   :is-it-in-the-known-defect-list :unknown)
  (:what "%magic-file-p τυλίγει ΟΛΟΚΛΗΡΟ το σώμα σε ignore-errors: I/O σφάλμα (permission, ΕΙΟ) δεν διακρίνεται από «δεν είναι PDF». Κρίση: ΟΡΙΑΚΑ τίμιο (ο caller παίρνει NIL και το μεταφράζει σε :not-a-pdf) αλλά η ΑΙΤΙΑ χάνεται."
   :severity :p2
   :evidence "source/document-fetch.lisp:L71-L79@sha256:bb114b83fd80"
   :is-it-in-the-known-defect-list :unknown)
  (:what "ΔΙΠΛΗ ΕΔΡΑ canonical sexp serialization με ΨΕΥΔΗ δήλωση ανάθεσης: το source/journal.lisp:L67-L67@sha256:ee440c102989 γράφει «Καταναλωτές: version-graph (%canon-sexp deleg.)» αλλά το source/version-graph.lisp:L471-L497@sha256:d6b181de2ad1 έχει ΔΙΚΗ ΤΟΥ πανομοιότυπη υλοποίηση, ΟΧΙ κλήση της journal:canon-sexp. Κάθε payload-hash/chain/condition-id/regime-id/attestation-hash του δικαιικού χρόνου παράγεται από το ΑΝΤΙΓΡΑΦΟ — απόκλιση των δύο εδρών θα έσπαγε σιωπηλά κάθε αποθηκευμένη ταυτότητα. (Το memory.lisp ΟΝΤΩΣ αναθέτει: memory.lisp:110,164.)"
   :severity :p1
   :evidence "source/journal.lisp:L61-L86@sha256:ee440c102989 · source/version-graph.lisp:L471-L497@sha256:d6b181de2ad1 · memory.lisp:110"
   :is-it-in-the-known-defect-list :unknown)
  (:what "canonical-representation δηλώνει RFC 8785 (JCS) και «bit-perfect reproducibility across implementations», αλλά: (α) η αριθμητική σειριοποίηση είναι (format ~,17G) + regex καθάρισμα, ΟΧΙ ο αλγόριθμος ECMAScript Number::toString που ορίζει το RFC 8785 §3.2.2.3 — αποκλίνει από ΚΑΘΕ συμμορφούμενη ξένη υλοποίηση σε πολλά doubles· (β) η ταξινόμηση κλειδιών γίνεται με string< (code points), ενώ το RFC απαιτεί UTF-16 code units — διαφορά σε κλειδιά εκτός BMP."
   :severity :p1
   :evidence "source/canonical-representation.lisp:L162-L192@sha256:a72286188ff9 source/canonical-representation.lisp:L227-L241@sha256:a72286188ff9"
   :is-it-in-the-known-defect-list :unknown)
  (:what "canonicalize-json ΑΜΦΙΣΗΜΙΑ τύπου: λίστα από plists (π.χ. ((:a 1) (:b 2))) ταξινομείται ως ALIST ⇒ σειριοποιείται ως JSON object αντί για array of objects, με τιμές (cdr) ως arrays. Η ίδια Lisp τιμή δεν διακρίνεται από πίνακα αντικειμένων — σε έδρα κανονικοποίησης που τροφοδοτεί hashes/υπογραφές."
   :severity :p1
   :evidence "source/canonical-representation.lisp:L141-L160@sha256:a72286188ff9"
   :is-it-in-the-known-defect-list :unknown)
  (:what "archive-authority: το «100-year proof» ΔΕΝ επαληθεύεται. Δεν ελέγχεται HTTP status· όταν το σώμα είναι string επιστρέφεται ως :archived-url η URL ΥΠΟΒΟΛΗΣ (save-url), όχι η πραγματική αρχειοθετημένη URL· και δηλώνεται :status :success ανεξαρτήτως. Επιπλέον καμία SSRF πύλη (drakma :redirect 10 σε αυθαίρετο URL) — αντίθετα με το document-fetch που έχει φρουρό ανά hop."
   :severity :p1
   :evidence "source/archive-authority.lisp:L70-L94@sha256:36f78fe7b609"
   :is-it-in-the-known-defect-list :unknown)
  (:what "adoption-decision: η ΥΠΟΓΡΑΦΗ της απόφασης παράγεται με (prin1-to-string decision) — αναπαράσταση, ΟΧΙ αξία. Είναι ακριβώς η κλάση σφάλματος που γέννησε τη canon-sexp (non-simple strings ⇒ #A(...)): ένα decision plist με format-παραγόμενο string μπορεί να δώσει ΑΛΛΟ sha μετά από round-trip, και το validate-adoption-records να το κηρύξει πλαστό."
   :severity :p1
   :evidence "source/adoption-decision.lisp:L90-L95@sha256:fd26b0d91f89 source/adoption-decision.lisp:L126-L131@sha256:fd26b0d91f89"
   :is-it-in-the-known-defect-list :unknown)
  (:what "extract-layout-graph: σφάλμα εξαγωγής σελίδας ⇒ ΚΕΝΗ σελίδα-placeholder με μόνο (warn) — σιωπηλή απώλεια περιεχομένου σε αγωγό corpus. Ο καλών δεν μπορεί να διακρίνει «σελίδα χωρίς κείμενο» από «σελίδα που απέτυχε»."
   :severity :p1
   :evidence "source/pdf-authority.lisp:L1360-L1370@sha256:c4e2054c0e4f"
   :is-it-in-the-known-defect-list :unknown)
  (:what "extract-text-via-ocr: προσωρινός κατάλογος /tmp/lawmax-ocr-<get-universal-time>/ — ΠΡΟΒΛΕΨΙΜΟ όνομα σε κοινόχρηστο /tmp (κίνδυνος pre-creation/symlink) και χρήση wall-clock αντί της έδρας χρόνου. Επιπλέον (error () nil) καταπίνει ΚΑΘΕ αιτία αποτυχίας OCR."
   :severity :p2
   :evidence "source/pdf-authority.lisp:L1399-L1425@sha256:c4e2054c0e4f"
   :is-it-in-the-known-defect-list :unknown)
  (:what "path-to-uri: μόνο τα κενά κωδικοποιούνται ως %20· #, %, ?, [ ] σε όνομα αρχείου παράγουν λάθος file:// URI (το # κόβει το path). Ένα ΦΕΚ με # στο όνομα δεν ανοίγει, ή ανοίγει άλλο αρχείο."
   :severity :p2
   :evidence "source/pdf-authority.lisp:L349-L355@sha256:c4e2054c0e4f"
   :is-it-in-the-known-defect-list :unknown)
  (:what "%ngz: (funcall (find-symbol \"NORMALIZE-GREEK\" :orchestrator.legal-id) s) ΧΩΡΙΣ έλεγχο — αν το πακέτο/σύμβολο λείπει, funcall πάνω σε NIL (undefined-function). Το ΙΔΙΟ αρχείο ελέγχει σωστά στη make-registry-resolver (L196-198): ασύμμετρη άμυνα στο ίδιο εξαρτησιακό όριο."
   :severity :p2
   :evidence "source/amendment-extractor.lisp:L189-L190@sha256:407642a40548 vs 196-198"
   :is-it-in-the-known-defect-list :unknown)
  (:what "APB: ο ΕΜΠΙΣΤΟΣ owner thumbprint υπολογίζεται με (ignore-errors (ed25519-jwk-thumbprint trusted-owner-root-jwk)) — κακοσχηματισμένο ΕΜΠΙΣΤΟ pin γίνεται σιωπηλά NIL, το OWN1 αποτυγχάνει και η βαθμίδα υποβαθμίζεται σε internally-release-consistent ΧΩΡΙΣ να ειπωθεί ότι το ίδιο το pin ήταν άκυρο. Κρίση: fail-closed ως προς τη βαθμίδα, αλλά η ΑΙΤΙΑ καταπίνεται — ο καταναλωτής δεν μαθαίνει ότι έδωσε χαλασμένη ρίζα."
   :severity :p2
   :evidence "source/authority-proof-bundle.lisp:L507-L511@sha256:1946af4ad92b"
   :is-it-in-the-known-defect-list :unknown)
  (:what "version-graph: δύο διαφορετικές κανονικοποιήσεις ταυτότητας συνυπάρχουν στο ΙΔΙΟ αρχείο — %version-hash-2/%edge-hash μέσω canonical-representation:canonical-hash (canonical JSON), ενώ condition/regime/event/attestation ids μέσω journal:sha256-hex πάνω σε %canon-sexp (canonical sexp). Δύο σχήματα ταυτότητας για μία έννοια («ταυτότητα εγγραφής») στην ίδια έδρα."
   :severity :p2
   :evidence "source/version-graph.lisp:L288-L300@sha256:d6b181de2ad1 source/version-graph.lisp:L407-L418@sha256:d6b181de2ad1 vs 1727-1729,2096-2104,2595-2596"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Ο ΕΛΕΓΚΤΗΣ ΤΟΥ AUDIT TRAIL ΑΠΟΤΥΓΧΑΝΕΙ ΠΑΝΤΑ, ΜΕ ΔΥΟ ΑΝΕΞΑΡΤΗΤΑ ΣΦΑΛΜΑΤΑ: (α) το log-activity δίνει :previous-hash NIL στην ΠΡΩΤΗ εγγραφή, ενώ το verify-audit-trail ξεκινά με previous-hash \"GENESIS\" — (equal NIL \"GENESIS\") ⇒ «Hash chain broken» στην πρώτη εγγραφή ΚΑΘΕ trail· (β) η επαλήθευση JWS καλεί (verify-jws signature *signing-public-key-path* :expected-payload content) ενώ η υπογραφή είναι (verify-jws jws payload public-key) — ΤΕΣΣΕΡΑ ορίσματα σε ΤΡΙΩΝ-παραμέτρων συνάρτηση, ΚΑΙ με τα ορίσματα σε λάθος θέσεις ⇒ program-error, που το handler-case το μετατρέπει σε log:warn + NIL ⇒ «Invalid signature». Άρα: με ενεργή κρυπτογραφική υπογραφή το audit trail ΔΕΝ επαληθεύεται ΠΟΤΕ, και η αιτία κρύβεται σε warning."
   :severity :p0
   :evidence "source/legal-audit-system.lisp:L233-L236@sha256:53613cdd00f0 source/legal-audit-system.lisp:L486-L509@sha256:53613cdd00f0 source/legal-audit-system.lisp:L545-L554@sha256:53613cdd00f0 · source/jws-authority.lisp:L394-L394@sha256:0d57d11e3cf7"
   :is-it-in-the-known-defect-list :unknown)
  (:what "compute-entry-hash (audit) χρησιμοποιεί «~A|~A|~A|…» — ΜΗ ΕΝΡΙΞΙΜΗ κωδικοποίηση: μετατόπιση του «|» μεταξύ actor/target/action δίνει ΙΔΙΟ hash για ΔΙΑΦΟΡΕΤΙΚΕΣ εγγραφές (ίδια κλάση που το review-queue ΔΙΟΡΘΩΣΕ ρητά με %canon-encode και το authority-proof-bundle με separator-deny). Η αλυσίδα audit είναι πλαστογραφήσιμη με field-shifting."
   :severity :p1
   :evidence "source/legal-audit-system.lisp:L271-L283@sha256:53613cdd00f0 vs source/review-queue.lisp:L100-L117@sha256:21c06b13b40e"
   :is-it-in-the-known-defect-list :unknown)
  (:what "generate-uuid του audit: (random (expt 2 32)) με το ΠΡΟΕΠΙΛΕΓΜΕΝΟ *random-state* — ΟΧΙ CSPRNG και, στο SBCL, ΙΔΙΑ ακολουθία σε κάθε εκκίνηση εικόνας. Τα entry-id/trail-id είναι προβλέψιμα ΚΑΙ επαναλαμβανόμενα μεταξύ εκτελέσεων· το trail-entry-index (equal hash) τα αντικαθιστά σιωπηλά σε σύγκρουση. (Το ίδιο μοτίβο στο generate-activity-id.)"
   :severity :p1
   :evidence "source/legal-audit-system.lisp:L780-L793@sha256:53613cdd00f0"
   :is-it-in-the-known-defect-list :unknown)
  (:what "government-source %pdf->text καλεί το ΜΗ-ΕΞΑΓΟΜΕΝΟ extract-pdf-text — τη διαδρομή που ΠΕΦΤΕΙ ΣΙΩΠΗΛΑ στον regex «fallback PDF parser» με μόνο (warn) όταν λείπει η poppler. Άρα η κρατική ροή εισαγωγής μπορεί να τροφοδοτήσει τον amendment-extractor με αποσπασματικό κείμενο, και οι :high-confidence πράξεις που προκύπτουν αυτο-εφαρμόζονται."
   :severity :p1
   :evidence "source/government-source.lisp:L487-L502@sha256:1b747a0bcb7a · source/pdf-authority.lisp:L904-L964@sha256:c4e2054c0e4f"
   :is-it-in-the-known-defect-list :unknown)
  (:what "mcp-server *corpus-list-fn*: ελέγχει (find-package :orchestrator.spec) αλλά κάνει find-symbol στο :orchestrator.cli (λάθος φρουρός — απόν package ⇒ σφάλμα), και σε αποτυχία επιστρέφει ΣΤΑΘΕΡΗ λίστα '(\"syntagma\" \"poinikos\"). Ένας AI πράκτορας που ρωτά «ποιους κώδικες σερβίρεις» παίρνει ΜΑΝΤΕΨΙΑ, όχι το μητρώο."
   :severity :p1
   :evidence "source/mcp-server.lisp:L102-L107@sha256:084246b54052"
   :is-it-in-the-known-defect-list :unknown)
  (:what "GATE-5 (validation-authority) ΕΙΝΑΙ ΔΟΜΙΚΑ ΝΕΚΡΟ: ΕΞΙ εσωτερικές κλήσεις περνούν το CONTEXT ΘΕΣΙΑΚΑ σε συναρτήσεις που το δηλώνουν ως &key — (check-broken-patterns ttl-content context) vs (defun check-broken-patterns (ttl &key context)) κ.λπ. Κάθε τέτοια κλήση σηματοδοτεί program-error («odd number of &KEY arguments») ΠΡΙΝ γίνει οποιοσδήποτε έλεγχος. Άρα το validate-canonical-ttl ΠΟΤΕ δεν επικυρώνει: ή σκάει με σφάλμα άσχετο με το περιεχόμενο, ή (αν ο καλών το τυλίγει) η επικύρωση απουσιάζει εντελώς. Καταναλωτής υπάρχει: systems/orchestrator-omega-modules/unified-frbr-generator.lisp:L434-L434@sha256:6499660bbe1f."
   :severity :p0
   :evidence "source/validation-authority.lisp:L67-L67@sha256:562d7ec7585c source/validation-authority.lisp:L70-L70@sha256:562d7ec7585c source/validation-authority.lisp:L73-L73@sha256:562d7ec7585c source/validation-authority.lisp:L77-L77@sha256:562d7ec7585c source/validation-authority.lisp:L93-L93@sha256:562d7ec7585c source/validation-authority.lisp:L173-L173@sha256:562d7ec7585c source/validation-authority.lisp:L210-L210@sha256:562d7ec7585c source/validation-authority.lisp:L213-L213@sha256:562d7ec7585c source/validation-authority.lisp:L216-L216@sha256:562d7ec7585c source/validation-authority.lisp:L220-L220@sha256:562d7ec7585c source/validation-authority.lisp:L230-L230@sha256:562d7ec7585c source/validation-authority.lisp:L250-L250@sha256:562d7ec7585c"
   :is-it-in-the-known-defect-list :unknown)
  (:what "ΕΓΚΡΙΣΗ ΠΡΟΤΑΣΗΣ ΣΦΡΑΓΙΖΕΤΑΙ ΑΚΟΜΗ ΚΙ ΑΝ Η ΕΝΕΡΓΕΙΑ ΑΠΕΤΥΧΕ: το %transition τρέχει το ON-APPROVE hook (αυτό που ΕΦΑΡΜΟΖΕΙ πραγματικά την πρόταση) μέσα σε (ignore-errors …) και ΣΥΝΕΧΙΖΕΙ να γράψει status «approved» στο append-only ledger. Ο παράμετρος FAIL-MSG υπάρχει αλλά είναι (declare (ignorable …)) και δεν χρησιμοποιείται ΠΟΤΕ — αποδεικτικό ότι το μονοπάτι σφάλματος εγκαταλείφθηκε. Η θεσμική εγγραφή λέει «εγκρίθηκε» ενώ τίποτα δεν εφαρμόστηκε."
   :severity :p0
   :evidence "source/proposals.lisp:L129-L140@sha256:7c955512cf54"
   :is-it-in-the-known-defect-list :unknown)
  (:what "verify-consolidation-ledger είναι ΤΑΥΤΟΛΟΓΙΑ, όχι επαλήθευση: «independently REPLAY» σημαίνει ΞΑΝΑΤΡΕΧΕΙ την ΙΔΙΑ consolidate με τα ΙΔΙΑ ορίσματα και συγκρίνει base-hash/result-hash/ΠΛΗΘΟΣ βημάτων. Τα καταγεγραμμένα before/after hashes των βημάτων ΔΕΝ συγκρίνονται ποτέ. Ένα ledger με πλαστά step hashes (ίδιο πλήθος) περνά· και η «απόδειξη» εξαρτάται από τον ΙΔΙΟ κώδικα που παρήγαγε το αποτέλεσμα — κανένας ανεξάρτητος verifier δεν υπάρχει."
   :severity :p1
   :evidence "source/consolidation-proof.lisp:L113-L123@sha256:4416d1aec20e"
   :is-it-in-the-known-defect-list :unknown)
  (:what "corpus-provenance ΠΑΡΑΚΑΜΠΤΕΙ τη «fail hard» πολιτική των canonical URIs: το %ensure-uris ΓΡΑΦΕΙ σιωπηλά default base-uri «https://stavropouloslaw.com/eli» στο global *canonical-config* ώστε «οι PROV-O generators να μη σφάλλουν ποτέ» — ακριβώς το αντίθετο του source/canonical-uris.lisp:L58-L63@sha256:3481b0caf826 («NO fallback defaults… MUST fail hard»). Ένα module παρουσίασης καθορίζει την ταυτότητα του Ιδρύματος."
   :severity :p1
   :evidence "source/corpus-provenance.lisp:L26-L33@sha256:a34e93dd0294 vs source/canonical-uris.lisp:L57-L63@sha256:3481b0caf826"
   :is-it-in-the-known-defect-list :unknown)
  (:what "corpus-provenance %ts: ημερομηνία απούσα/κακοσχηματισμένη ⇒ ΣΙΩΠΗΛΗ αντικατάσταση με σταθερό 2025-01-01 μέσα σε PROV-O έγγραφο προέλευσης. Το τεκμήριο προέλευσης φέρει ΚΑΤΑΣΚΕΥΑΣΜΕΝΗ χρονοσφραγίδα που δεν διακρίνεται από αληθινή."
   :severity :p1
   :evidence "source/corpus-provenance.lisp:L35-L39@sha256:a34e93dd0294"
   :is-it-in-the-known-defect-list :unknown)
  (:what "component-scan: file-hash τυλιγμένο σε ignore-errors ⇒ NIL, ΚΑΙ το stale-components θεωρεί ΡΗΤΑ «(null now) ⇒ ΟΧΙ stale». Άρα οποιοδήποτε I/O σφάλμα (permissions, EIO) πάνω σε αρχείο πηγής μετατρέπει την ανίχνευση απόκλισης hash σε σιωπηλό «καθαρό». Ο έλεγχος ακεραιότητας απενεργοποιείται από αποτυχία ανάγνωσης."
   :severity :p1
   :evidence "source/component-scan.lisp:L26-L28@sha256:c9413bd50c2c source/component-scan.lisp:L305-L316@sha256:c9413bd50c2c"
   :is-it-in-the-known-defect-list :unknown)
  (:what "component-scan freeze-components!: το manifest ταυτοτήτων γράφεται με (prin1 all s) — ΟΧΙ μέσω της ΜΙΑΣ έδρας εγγραφής (safe-read:data-to-string), ενώ ΔΙΑΒΑΖΕΤΑΙ από τη safe-read (+data-readtable+ που ΑΠΟΡΡΙΠΤΕΙ κάθε #-σύνταξη). Ένα specialized base-char string θα τυπωνόταν #A(...) και το manifest θα γινόταν μη αναγνώσιμο — ακριβώς η κλάση που η data-to-string υπάρχει για να εξαλείψει."
   :severity :p2
   :evidence "source/component-scan.lisp:L139-L149@sha256:c9413bd50c2c vs source/safe-read.lisp:L312-L339@sha256:590133b311d0"
   :is-it-in-the-known-defect-list :unknown)
  (:what "component-scan %scan-file-text: οι ΕΔΡΕΣ δηλώσεων (defpackage/defcontract/declare-capability!) ανιχνεύονται με REGEX πάνω στο κείμενο του αρχείου — ένα αναφερόμενο όνομα μέσα σε σχόλιο/string μετριέται ως έδρα. Η «ταυτότητα συστατικού» στηρίζεται σε λεξικογραφική εικασία, όχι σε ανάγνωση κώδικα."
   :severity :p2
   :evidence "source/component-scan.lisp:L45-L56@sha256:c9413bd50c2c"
   :is-it-in-the-known-defect-list :unknown)
  (:what "corpus-intelligence: το define-corpus-check τυλίγει ΚΑΘΕ σώμα ελέγχου σε handler-case ⇒ ΟΠΟΙΟΔΗΠΟΤΕ σφάλμα γίνεται finding :skipped, και το report-clean-p ΑΓΝΟΕΙ ρητά τα skips («advisories / skips do not count»). Άρα ένας ΣΠΑΣΜΕΝΟΣ έλεγχος παράγει «καθαρός κώδικας». Η αποτυχία επαλήθευσης γίνεται επιτυχία."
   :severity :p1
   :evidence "source/corpus-intelligence.lisp:L75-L93@sha256:56ef2b5920c8 source/corpus-intelligence.lisp:L175-L177@sha256:56ef2b5920c8"
   :is-it-in-the-known-defect-list :unknown)
  (:what "paths.lisp with-temp-file: το όνομα προσωρινού αρχείου είναι «orch-<unix-timestamp>.tmp» σε κοινό :temp κατάλογο — ΠΡΟΒΛΕΨΙΜΟ (symlink/pre-creation attack) και, υπό ντετερμινιστικό χρόνο, ΤΑΥΤΟ σε κάθε εκτέλεση (σύγκρουση). Επιπλέον κληρονομεί το epoch bug του get-unix-timestamp."
   :severity :p2
   :evidence "source/paths.lisp:L311-L323@sha256:1eba7353aca4"
   :is-it-in-the-known-defect-list :unknown)
  (:what "http-server: το +status-text+ δεν περιέχει 503 (ούτε 403/429), ενώ ο κώδικας εκπέμπει 503 στο overload — το reason phrase γίνεται (or … \"OK\") ⇒ αποστέλλεται «HTTP/1.1 503 OK». Το ίδιο για κάθε 403 της capability-api."
   :severity :p2
   :evidence "source/http-server.lisp:L51-L54@sha256:e3854504b380 source/http-server.lisp:L157-L157@sha256:e3854504b380 source/http-server.lisp:L206-L213@sha256:e3854504b380"
   :is-it-in-the-known-defect-list :unknown)
  (:what "circuit-breaker: ο έλεγχος κατάστασης «(when (eq (cb-state breaker) :open) …)» γίνεται ΕΚΤΟΣ του κλειδώματος, αμέσως μετά το κλείσιμό του — TOCTOU: ταυτόχρονο άνοιγμα κυκλώματος δεν τηρείται. Επίσης οι προεπιλογές υπάρχουν σε ΤΡΕΙΣ θέσεις (defconstant +default-*+, defclass initform, make-circuit-breaker lambda list) και τα +default-*+ είναι ΝΕΚΡΑ."
   :severity :p2
   :evidence "source/circuit-breaker.lisp:L23-L33@sha256:00ac735a0170 source/circuit-breaker.lisp:L52-L71@sha256:00ac735a0170 source/circuit-breaker.lisp:L112-L129@sha256:00ac735a0170 source/circuit-breaker.lisp:L211-L218@sha256:00ac735a0170"
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
   :evidence "source/consolidation-bridge.lisp:L258-L270@sha256:89f64cc69da1 source/consolidation-bridge.lisp:L272-L305@sha256:89f64cc69da1"
   :is-it-in-the-known-defect-list :unknown)
  (:what "corpus-diff/corpus-search: τοπικά jstr JSON escapers που ΔΕΝ κωδικοποιούν control chars < 0x20 (σε αντίθεση με το %j του proof-carrying) — ένα άρθρο με U+0001 παράγει ΑΚΥΡΟ JSON στο δημόσιο endpoint."
   :severity :p2
   :evidence "source/corpus-diff.lisp:L36-L44@sha256:b69bdbac9560 · source/corpus-search.lisp:L70-L78@sha256:8effbaf5f62f vs source/proof-carrying.lisp:L88-L99@sha256:c18f7ddb07b1"
   :is-it-in-the-known-defect-list :unknown)
  (:what "pdf-authority load-poppler-libraries: το *poppler-load-attempted* latch δεν καθαρίζεται ΠΟΤΕ — μία παροδική αποτυχία φόρτωσης παγιδεύει τη διεργασία μόνιμα σε «poppler μη διαθέσιμη» με μόνο log:warn, ενώ κάθε PDF λειτουργία μετά σφάλλει."
   :severity :p2
   :evidence "source/pdf-authority.lisp:L139-L174@sha256:c4e2054c0e4f"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Το ΜΟΤΙΒΟ «(apply (find-symbol \"X\" :orchestrator.consolidation) args)» επαναλαμβάνεται αυτούσιο σε ≥2 αρχεία, ρητά δηλωμένο ως «the same defensive pattern the other intelligence modules use» — αντιγραμμένο boilerplate που μετατρέπει απούσα εξάρτηση σε undefined-function αντί για δηλωμένη άγνοια."
   :severity :p2
   :evidence "source/anomaly-detection.lisp:L24-L31@sha256:43c44bf86b01 · source/ast-gate.lisp:L40-L47@sha256:65724a01525c"
   :is-it-in-the-known-defect-list :unknown)

  (:what "blockchain-authority: ethereum-anchor και arweave-upload επιστρέφουν NIL «σιωπηλά αν δεν έχει ρυθμιστεί» (ρητό σχόλιο «CONDITIONAL: Skip silently if not configured»), και ο συγκεντρωτής anchor-to-chains κάνει (when result (push …)) — άρα ΑΠΟΥΣΙΑ ρύθμισης παράγει ΚΕΝΟ σύνολο αγκυρών χωρίς καμία διάκριση από «δοκιμάστηκε και απέτυχε». Ο καλών δεν μπορεί να ξεχωρίσει «δεν αγκυρώθηκε γιατί δεν υπάρχει RPC» από «αγκυρώθηκε σε 0 αλυσίδες»."
   :severity :p1
   :evidence "source/blockchain-authority.lisp:L640-L641@sha256:caadc9c75a98 source/blockchain-authority.lisp:L749-L750@sha256:caadc9c75a98 source/blockchain-authority.lisp:L906-L909@sha256:caadc9c75a98"
   :is-it-in-the-known-defect-list :unknown)

  (:what "blockchain-authority verify-anchor: το τελικό (t nil) του case σημαίνει ότι ΑΓΝΩΣΤΗ αλυσίδα, ΜΗ ρυθμισμένο *ethereum-rpc-url*, και «η συναλλαγή δεν επαληθεύτηκε» δίνουν ΤΟ ΙΔΙΟ NIL. Boolean επιστροφή αντί για τριαδική (verified/unverified/unknown) ⇒ η άγνοια κωδικοποιείται ως αρνητική επαλήθευση."
   :severity :p1
   :evidence "source/blockchain-authority.lisp:L912-L944@sha256:caadc9c75a98"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-ast ast-copy: αντιγράφει ΜΟΝΟ τα τέσσερα slots της βάσης ast-node (id/type/text/source-blocks) + children· ΟΛΑ τα slots των 16 υποκλάσεων χάνονται σιωπηλά. Αντίγραφο amendment-node χάνει amendment-type/target-law/target-article/target-paragraph — δηλαδή ΤΙ τροποποιεί· αντίγραφο article-node χάνει article-number/article-title. Καμία προειδοποίηση, καμία δήλωση απώλειας."
   :severity :p1
   :evidence "source/legal-ast.lisp:L1904-L1918@sha256:3735c7d8e763 · υποκλάσεις με ίδια slots: source/legal-ast.lisp:L427-L445@sha256:3735c7d8e763 source/legal-ast.lisp:L841-L865@sha256:3735c7d8e763"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-ast when-let: το docstring δηλώνει ρητά «This matches the Alexandria when-let convention» και «execute BODY only if ALL values are non-nil», αλλά η υλοποίηση παίρνει (first bindings) και ΑΓΝΟΕΙ σιωπηλά κάθε επόμενο binding. Δεύτερη έδρα του ονόματος when-let σε repo που φορτώνει ήδη alexandria (η ίδια alexandria:when-let χρησιμοποιείται στο source/blockchain-authority.lisp:L953-L971@sha256:caadc9c75a98)."
   :severity :p2
   :evidence "source/legal-ast.lisp:L2138-L2148@sha256:3735c7d8e763 · alexandria:when-let σε χρήση: source/blockchain-authority.lisp:L953-L971@sha256:caadc9c75a98"
   :is-it-in-the-known-defect-list :unknown)

  (:what "blockchain-authority: το mod-inverse (εκτεταμένος Ευκλείδης, κρίσιμο για ECDSA/RSA) υλοποιείται ΔΕΥΤΕΡΗ φορά, αυτούσιο, ενώ υπάρχει ήδη έδρα στο jws-authority.lisp. Δύο ανεξάρτητες υλοποιήσεις της ίδιας αριθμοθεωρητικής πράξης σε δύο μονοπάτια υπογραφής."
   :severity :p2
   :evidence "source/blockchain-authority.lisp:L259-L269@sha256:caadc9c75a98 · source/jws-authority.lisp:L711-L711@sha256:0d57d11e3cf7"
   :is-it-in-the-known-defect-list :unknown)

  (:what "blockchain-authority: όλα τα :timestamp των αποδείξεων αγκύρωσης προέρχονται από (get-universal-time) — ΟΧΙ από την έδρα orchestrator.time, ΟΧΙ ντετερμινιστικά, και ΟΧΙ από την ίδια την αλυσίδα (η αλυσίδα έχει block timestamp). Η «απόδειξη χρόνου» της αγκύρωσης είναι το τοπικό ρολόι του κόμβου που την κατέγραψε."
   :severity :p2
   :evidence "source/blockchain-authority.lisp:L710-L710@sha256:caadc9c75a98 source/blockchain-authority.lisp:L794-L794@sha256:caadc9c75a98 source/blockchain-authority.lisp:L879-L879@sha256:caadc9c75a98"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Η ΓΕΦΥΡΑ ΤΟΥ ΔΕΟΝΤΙΚΟΥ L5 ΠΡΟΣ ΤΟΝ L2 ΕΙΝΑΙ ΝΕΚΡΗ. Η κεφαλίδα του legal-deontic δηλώνει ρητά ότι «η δεοντική σύγκρουση γίνεται (:conflict …) και την κρίνει ο υπάρχων L2» (lex superior/specialis/posterior), αλλά ο κανόνας-γέφυρα παράγει (:conflict-of-norms ?sa ?sb :on ?act :from ?na ?nb) — ΔΙΑΦΟΡΕΤΙΚΟ κατηγόρημα από το (:conflict CA A CB B) που ταιριάζουν ΟΛΟΙ οι κανόνες του L2, ΚΑΙ με τις πηγές ως ΕΝΙΑΙΑ strings «corpus:article» αντί για δύο χωριστούς όρους. Το σύμβολο :conflict-of-norms εμφανίζεται ΑΚΡΙΒΩΣ ΜΙΑ φορά σε ΟΛΟ το παγωμένο repo — στο σημείο παραγωγής του. ΜΗΔΕΝ καταναλωτές: καμία δεοντική σύγκρουση δεν φτάνει ποτέ στην επίλυση συγκρούσεων."
   :severity :p0
   :evidence "source/legal-deontic.lisp:L14-L18@sha256:3b584b2845ae source/legal-deontic.lisp:L34-L34@sha256:3b584b2845ae source/legal-deontic.lisp:L160-L167@sha256:3b584b2845ae (παραγωγή) · source/legal-conflict-resolution.lisp:L69-L112@sha256:eae756342fff (οι κανόνες L2 ταιριάζουν :conflict, όχι :conflict-of-norms) · grep -rn conflict-of-norms /frozen/ro ⇒ 1 σημείο, μόνο η παραγωγή"
   :is-it-in-the-known-defect-list :unknown)

  (:what "ΕΝΤΕΚΑ ΕΔΡΕΣ JSON string escaping, ΤΕΣΣΕΡΙΣ από τις οποίες παράγουν ΑΚΥΡΟ JSON. Τα corpus-eu-links:113-121, government-source:239-250, corpus-diff:36-44 και corpus-search:70-78 έχουν (t (write-char ch s)) ως τελευταία περίπτωση: οι χαρακτήρες ελέγχου U+0000–U+001F πλην \\n \\r \\t περνούν ΑΚΑΤΕΡΓΑΣΤΟΙ, κάτι που το RFC 8259 §7 απαγορεύει — αυστηρός parser ΑΠΟΡΡΙΠΤΕΙ το έγγραφο. Στο ΙΔΙΟ repo τα review-service:190-204, mcp-server:41-53, legal-qa:95-106, ai-corpus-dump:40-50 ΚΑΝΟΥΝ τη σωστή \\u-διαφυγή — και η ΔΗΛΩΜΕΝΗ έδρα json-emit:39-58 (write-json-value, ολική) δεν χρησιμοποιείται από καμία τους. Το σώμα είναι OCR-αρισμένα PDF ΦΕΚ, όπου οι χαρακτήρες ελέγχου είναι αναμενόμενοι."
   :severity :p1
   :evidence "source/corpus-eu-links.lisp:L113-L121@sha256:63fb33b5c39b · source/government-source.lisp:L239-L250@sha256:1b747a0bcb7a · source/corpus-diff.lisp:L36-L44@sha256:b69bdbac9560 · source/corpus-search.lisp:L70-L78@sha256:8effbaf5f62f · (σωστές) source/review-service.lisp:L190-L204@sha256:7e0378ae7c28 · source/mcp-server.lisp:L41-L53@sha256:084246b54052 · source/legal-qa.lisp:L95-L106@sha256:8c10f4e56920 · source/ai-corpus-dump.lisp:L40-L50@sha256:b1d9f34c24ae · (δηλωμένη έδρα) source/json-emit.lisp:L39-L58@sha256:5f1b1b7d8d91 · (11η, inline) source/corpus-sparql.lisp:L102-L104@sha256:8b1997dd98b1"
   :is-it-in-the-known-defect-list :unknown)

  (:what "ΔΥΟ ΑΣΥΜΒΑΤΕΣ ΕΔΡΕΣ ΣΥΓΚΡΙΣΗΣ ΝΟΜΙΚΩΝ ΗΜΕΡΟΜΗΝΙΩΝ, με ΨΕΥΔΗ δήλωση αποκλειστικότητας. Το legal-temporal δηλώνει στην κεφαλίδα του «η ΜΙΑ έδρα» ημερολογιακής αριθμητικής και υλοποιεί date< / date<= ως ΣΚΕΤΟ string< / string<= (λεξικογραφικά), με την ΕΠΙΚΥΡΩΣΗ μορφής ρητά ανατεθειμένη σε ΣΧΟΛΙΟ («ευθύνη της typed έδρας version-graph:legal-date-p») — καμία επιβολή στον κώδικα. Παράλληλα ο μετακυκλικός αποτιμητής φραγμών έχει ΠΛΗΡΕΣ δεύτερο ημερολόγιο (DATE<, DATE<=, DATE>, DATE>=, DAYS-BETWEEN, WITHIN-DAYS, ΗΜΕΡΑ-ΕΒΔΟΜΑΔΑΣ, ΕΡΓΑΣΙΜΗ-P, ΕΠΟΜΕΝΗ-ΕΡΓΑΣΙΜΗ) υλοποιημένο ΑΡΙΘΜΗΤΙΚΑ μέσω (ymd->day …). Οι δύο έδρες τροφοδοτούν ΔΙΑΦΟΡΕΤΙΚΑ trusted μονοπάτια: το event calculus παίρνει τα πιστοποιητικά date</date<= από τον αποτιμητή, ενώ η κρίση ΕΜΠΡΟΘΕΣΜΟ/ΕΚΠΡΟΘΕΣΜΟ της στρατηγικής Σ9 στηρίζεται στο string<=."
   :severity :p1
   :evidence "source/legal-temporal.lisp:L3-L3@sha256:74ec15418b7c source/legal-temporal.lisp:L16-L20@sha256:74ec15418b7c (αξίωση «ΜΙΑ έδρα»),41-46 (string< / string<=) · source/guard-metaeval.lisp:L652-L666@sha256:6c11b3a60282 (δεύτερο πλήρες ημερολόγιο) · source/legal-event-calculus.lisp:L47-L47@sha256:ff1a2f83f6ff source/legal-event-calculus.lisp:L56-L56@sha256:ff1a2f83f6ff (:where date<= / date<) · source/legal-strategy.lisp:L62-L63@sha256:1268e149217a (ΕΜΠΡΟΘΕΣΜΟ μέσω string<=)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "penalty-severity/milder-penalty ΔΕΝ ΕΧΟΥΝ :unknown — το μέτρο του «επιεικέστερου» (άρθρο 2 ΠΚ) απαντά ΠΑΝΤΑ. Άγνωστο ελάχιστο γίνεται 0 και άγνωστο μέγιστο most-positive-fixnum, οπότε αποτυχία ανάλυσης ορίων εμφανίζεται ως ΕΓΚΥΡΟ εύρος· και όταν το κείμενο δίνει μόνο το είδος («τιμωρείται με κάθειρξη») μπαίνουν ΣΙΩΠΗΛΑ τα εκ του νόμου όρια (or mn lo)/(or mx hi), ώστε δύο διαφορετικές διατάξεις με μη-αναλυμένα όρια συγκρίνονται ως :equal. Το πεδίο τιμών του WHICH είναι {:a :b :equal} — δεν υπάρχει τρόπος να πει «δεν ξέρω ποια είναι ηπιότερη» σε ΠΟΙΝΙΚΟ μονοπάτι."
   :severity :p1
   :evidence "source/legal-penalty.lisp:L111-L115@sha256:7ea6f2047ce9 source/legal-penalty.lisp:L126-L137@sha256:7ea6f2047ce9 (σιωπηλά εκ του νόμου όρια) · 153-158 (0 / most-positive-fixnum) · 165-176 (WHICH ∈ {:a :b :equal}, καμία :unknown)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Ο γράφος παραπομπών ΔΕΝ ΑΝΑΠΤΥΣΣΕΙ ΕΥΡΗ, ενώ το δηλώνει. Το docstring του extract-article-refs λέει «Handles single citations, comma lists and ranges» και η κεφαλίδα φέρνει ως παράδειγμα «των άρθρων 235 - 263Α», αλλά ο κώδικας συλλέγει ΜΟΝΟ τα αριθμητικά tokens του run: το «235 - 263Α» δίνει ΔΥΟ κόμβους (235, 263Α) αντί για 29. Επιπλέον το reference-graph ΠΕΤΑΕΙ κάθε παραπομπή που δεν επιλύεται σε υπαρκτό άρθρο, και ο έλεγχος verify-references είναι ρητά «ADVISORY … not a hard failure». Η ΑΝΑΛΥΣΗ ΕΠΙΠΤΩΣΗΣ χτίζεται αποκλειστικά από αυτές τις ακμές — άρα απαντά υπο-περιεκτικά, σιωπηλά."
   :severity :p1
   :evidence "source/legal-references.lisp:L6-L8@sha256:d5c1a0763803 source/legal-references.lisp:L58-L69@sha256:d5c1a0763803 (αξίωση ranges vs υλοποίηση),101-112 (απόρριψη ανεπίλυτων),129-144 (advisory) · source/legal-reasoning-bridge.lisp:L32-L45@sha256:ba8a680fbe54 (τα facts μόνο από graph-edges)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "source/protocols.lisp: 263 γραμμές, 40 defgeneric, ΜΗΔΕΝ μέθοδοι, ΜΗΔΕΝ καταναλωτές. Καμία μέθοδος δεν ορίζεται για validate-rdf, anchor-to-blockchain, validate-data, store-corpus, log-audit-event, create-session, get-config-value, resolve-path, compute-hash, call-service, initialize-component, handle-error, circuit-breaker-state — κάθε κλήση θα έδινε no-applicable-method. Κανένα αρχείο του repo δεν αναφέρει το πακέτο :orchestrator.protocols εκτός από το ίδιο. Δηλώνει compute-hash (δεύτερη έδρα ονόματος έναντι της δηλωμένης hash-authority), circuit-breaker-state, resolve-path, log-audit-event — ονόματα που ΗΔΗ έχουν πραγματικές έδρες αλλού. Και το generate-rdf ορίζεται ΔΕΥΤΕΡΗ φορά ως defgeneric με ΑΣΥΜΒΑΤΗ lambda-list σε άλλο σύστημα. Το αρχείο φορτώνεται από το orchestrator-infrastructure.asd:L188-L188@sha256:eafe37e8517f."
   :severity :p1
   :evidence "protocols.lisp:1-263 (40 defgeneric χωρίς defmethod)· 56 (generate-rdf (object &key format)) vs systems/orchestrator-omega-modules/frbr-protocol.lisp:L11-L11@sha256:15edc8b34f1b (generate-rdf (frbr-instance)) · 145 (compute-hash) vs source/hash-authority.lisp:L11-L46@sha256:280a7c5bb315 · 200-263 (δεύτερο, περιττό export των ίδιων 40 συμβόλων) · orchestrator-infrastructure.asd:L188-L188@sha256:eafe37e8517f"
   :is-it-in-the-known-defect-list :unknown)

  (:what "execution-trace: το μαγαζί ιχνών δηλώνεται «append-only εντός συνεδρίας» και το σχόλιο του +max-events+ λέει ότι πέραν του ορίου «τα ΑΡΧΑΙΟΤΕΡΑ μισά συμπυκνώνονται (δηλωμένα)» — ο κώδικας ΔΕΝ συμπυκνώνει τίποτα: κρατά το νεότερο μισό και ΠΕΤΑΕΙ τα 10.000 αρχαιότερα γεγονότα ΧΩΡΙΣ σύνοψη, χωρίς γεγονός-δείκτη, χωρίς μετρητή απορριφθέντων. Τα ids συνεχίζουν μονότονα, άρα find-event σε πεταμένο id δίνει NIL — αδιάκριτο από «δεν υπήρξε ποτέ». Η προέλευση εκτέλεσης χάνεται σιωπηλά ακριβώς στις μακριές συνεδρίες."
   :severity :p1
   :evidence "source/execution-trace.lisp:L14-L15@sha256:70aa123251f4 source/execution-trace.lisp:L46-L47@sha256:70aa123251f4 (αξίωση append-only) · 52-53 (σχόλιο «συμπυκνώνονται (δηλωμένα)») · 61-64 (η πραγματική απόρριψη) · 101-102 (find-event)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "provenance-link declare-trace-debt!: ΟΠΟΙΟΣΔΗΠΟΤΕ εντός εικόνας μπορεί να δηλώσει «χρέος» για ΟΠΟΙΟΔΗΠΟΤΕ σύμβολο, και το σύμβολο ΕΞΑΙΡΕΙΤΑΙ αμέσως από την παράβαση «εκτελέστηκε ΧΩΡΙΣ συμβόλαιο» και μετακινείται από το ΑΠΑΡΑΔΕΚΤΟ σύνολο silent στο αποδεκτό debts. Καμία αυθεντικοποίηση, καμία καταγραφή σε journal, κανένα receipt, καμία έγκριση — ο επικυρωτής προέλευσης απενεργοποιείται κατά σύμβολο με μία κλήση συνάρτησης. Επιπλέον ο έλεγχος «ξεπερασμένο hash πηγής» παρακάμπτεται ΣΙΩΠΗΛΑ όταν το known-file-hash δίνει NIL."
   :severity :p1
   :evidence "source/provenance-link.lisp:L19-L27@sha256:5354f41c3f06 (declare-trace-debt!) · 66-71 (η εξαίρεση) · 101-105 (silent→debts) · 84-88 (σιωπηλή παράκαμψη σε NIL hash)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-hypergraph: το %ttl-lit αυτοδηλώνεται «the single escaping choke point for the hypergraph emitter» και τεκμηριώνει ρητά τον κίνδυνο έγχυσης triples από «attacker-controlled text» — αλλά φρουρεί ΜΟΝΟ τα literals. Τα IRIs χτίζονται με ΑΦΙΛΤΡΑΡΙΣΤΗ παρεμβολή των ΙΔΙΩΝ δεδομένων από το σώμα: <~A/hyperedge/~A> από το edge-subject, <~A/art/~A> από κάθε member, από το target κάθε operation και από το edge-source. Ένα id που περιέχει «>» ή κενό σπάει τη γραμματική· ένα id της μορφής «x> . <y> <p> <o> . <z» ΕΓΧΕΕΙ ΤΡΙΠΛΕΤΕΣ στον γράφο."
   :severity :p1
   :evidence "source/legal-hypergraph.lisp:L46-L51@sha256:a5eeb778d594 (η αξίωση «single choke point») · 75-81 (subject+members ανεπίδραστα) · 101-111 (target) · 130-132 (edge-source)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "corpus-eu-links %year-number: για διψήφιο έτος, (>= ai 70) ⇒ 1900+ai αλλιώς 2000+ai. Κάθε ενωσιακή πράξη ΠΡΙΝ ΤΟ 1970 (π.χ. «Οδηγία 69/335/ΕΟΚ», που πράγματι μνημονεύεται στην ελληνική φορολογική νομοθεσία) αποδίδεται στο ΕΤΟΣ 2069 και παράγει CELEX «32069L0335» και ELI «…/dir/2069/335/oj». Το module διαφημίζεται ότι «mints the OFFICIAL European identifiers» και τα εκπέμπει ως «celex»/«eli» χωρίς κανένα πεδίο αβεβαιότητας ή επαλήθευσης ύπαρξης."
   :severity :p1
   :evidence "source/corpus-eu-links.lisp:L9-L12@sha256:63fb33b5c39b (αξίωση «OFFICIAL»),47-55 (η ευρετική),57-67 (μιντάρισμα),123-128 (εκπομπή χωρίς σήμανση)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "graph-reasoning: ΔΥΟ ΔΙΑΦΟΡΕΤΙΚΕΣ ΠΟΛΙΤΙΚΕΣ ΟΡΙΖΟΝΤΑ στο ΙΔΙΟ αρχείο. Το impact μετρά ρητά τους κόμβους πέραν του ορίου και τους επιστρέφει ως δεύτερη τιμή, με σχόλιο «καταμέτρησε, μην σιωπήσεις». Το explain — που παράγει ΔΕΝΤΡΟ ΑΠΟΔΕΙΞΗΣ — απλώς σταματά στο max-depth 8 και επιστρέφει (:derived κανόνας NIL)· το explanation->string το τυπώνει σαν κανόνα ΧΩΡΙΣ προϋποθέσεις, δηλαδή σαν ΠΛΗΡΗ απόδειξη. Η κολοβωμένη απόδειξη είναι οπτικά αδιάκριτη από την πλήρη."
   :severity :p1
   :evidence "source/graph-reasoning.lisp:L24-L39@sha256:81d3b4593cdd (σιωπηλή κοπή),41-51 (η εκτύπωση δεν σημαίνει κοπή) · 54-90 (η τίμια πολιτική του impact, ιδίως 61-63,88-89)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Τα πακέτα γνώσης εγκαθίστανται με ΤΡΕΙΣ ΑΣΥΜΒΑΤΕΣ πολιτικές ατομικότητας. Το :guard-ops δουλεύει σε ΑΝΤΙΓΡΑΦΟ και δημοσιεύει ατομικά, με ρητό σχόλιο ότι αυτό ήταν εύρημα επιθεώρησης («αναγνώστες σε άλλα νήματα βλέπουν πάντα ΠΛΗΡΗ γλώσσα»). Το :procedure ΜΕΤΑΒΑΛΛΕΙ το καθολικό *operators* εντός βρόχου, ένα entry τη φορά — αναγνώστης σε άλλο νήμα βλέπει μισο-εγκατεστημένο δικονομικό δίκαιο. Το :lexicon γράφει ΠΡΩΤΑ στο *generation-lexicon* και ΜΕΤΑ υπολογίζει τις μορφές, άρα άγνωστη κλιτική κλάση αφήνει ΜΙΣΟ-ΕΓΚΑΤΕΣΤΗΜΕΝΟ λήμμα και σφάλμα τύπου αντί για δηλωμένη απόρριψη. Η ίδια κλάση σφάλματος κλείστηκε σε μία έδρα και άφησε τις άλλες δύο ανοιχτές."
   :severity :p1
   :evidence "source/guard-ops-pack.lisp:L17-L29@sha256:6c3c38bd1d0c (COW, ατομικό) · source/legal-strategy.lisp:L32-L41@sha256:1268e149217a (setf στο καθολικό ανά entry) · source/generation.lisp:L50-L63@sha256:e92ce44484e9 (γράψιμο πριν τον υπολογισμό μορφών),215-227 (:install καλεί define-noun με δεδομένα πακέτου)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-strategy plan-course: η ΤΑΥΤΟΤΗΤΑ ΚΑΤΑΣΤΑΣΗΣ του BFS είναι (sort (mapcar (lambda (f) (format nil \"~S\" f)) st) #'string<) — εξαρτάται από τις δυναμικές μεταβλητές του εκτυπωτή. Με δεσμευμένο *print-length* ή *print-level* (συνήθες σε REPL/debug/error handler) διαφορετικές καταστάσεις τυπώνονται κολοβωμένες και ΣΥΓΚΡΟΥΟΝΤΑΙ ως ίδιες, οπότε το seen κόβει σιωπηλά υπαρκτές δικονομικές πορείες· *package* και *print-case* αλλάζουν επίσης το κλειδί. Μη-εγχυτική ταυτότητα σε μονοπάτι που αποφαίνεται «ΔΕΝ υπάρχει παραδεκτή πορεία»."
   :severity :p1
   :evidence "source/legal-strategy.lisp:L87-L91@sha256:1268e149217a source/legal-strategy.lisp:L107-L109@sha256:1268e149217a source/legal-strategy.lisp:L131-L136@sha256:1268e149217a"
   :is-it-in-the-known-defect-list :unknown)

  (:what "evaluate-deontic ΔΕΝ είναι fixpoint: εκτελεί apply-norms → run-inference ΑΚΡΙΒΩΣ ΔΥΟ φορές, με το ίδιο το σχόλιο να παραδέχεται ότι «νέα facts μπορεί να ενεργοποίησαν κι άλλους κανόνες». Αν ο τρίτος γύρος ενεργοποιούσε κανόνα, η δεοντική θέση ΔΕΝ παράγεται και δεν δηλώνεται τίποτα — το αποτέλεσμα παρουσιάζεται ως πλήρης «δεοντική ανάλυση» με μετρητές θέσεων/συγκρούσεων."
   :severity :p1
   :evidence "source/legal-deontic.lisp:L169-L183@sha256:3b584b2845ae (ιδίως 176-179) · deontic-report 184-205"
   :is-it-in-the-known-defect-list :unknown)

  (:what "akoma-ntoso-emitter xml-text-escape/xml-attr-escape διαφεύγουν ΜΟΝΟ & < > (και \" στα attributes). Οι χαρακτήρες ελέγχου C0 πλην TAB/LF/CR είναι ΑΠΑΓΟΡΕΥΜΕΝΟΙ στο XML 1.0 και ΔΕΝ διαφεύγουν ούτε ως αριθμητικές αναφορές: κείμενο από OCR-αρισμένο ΦΕΚ που τους περιέχει παράγει Akoma Ntoso που ΚΑΘΕ συμμορφούμενος parser απορρίπτει. Επιπλέον νέες γραμμές/tab μέσα σε τιμές attribute υφίστανται σιωπηλή κανονικοποίηση από τον parser, αλλοιώνοντας eId/refersTo/date."
   :severity :p1
   :evidence "source/akoma-ntoso-emitter.lisp:L46-L53@sha256:650a0e0fe875 source/akoma-ntoso-emitter.lisp:L55-L63@sha256:650a0e0fe875 · χρήση σε 117-133 (eId, num, heading, text),148-183 (FRBR, eventRef)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "akoma-ntoso-emitter akn-element-name: η ρήτρα (otherwise \"hcontainer\") βρίσκεται μέσα σε ECASE. Στο ecase το otherwise ΔΕΝ είναι προεπιλογή — είναι κανονικό κλειδί (το σύμβολο otherwise). Άρα η «προεπιλογή» είναι ΝΕΚΡΟΣ ΚΩΔΙΚΑΣ και οποιοδήποτε provision-kind εκτός των έξι απαριθμημένων σηματοδοτεί type-error αντί να πέσει σε hcontainer. Το slot είναι τυποποιημένο ως ελεύθερο keyword. (Λανθάνον: οι σημερινοί παραγωγοί εκπέμπουν μόνο :article/:paragraph.)"
   :severity :p2
   :evidence "source/akoma-ntoso-emitter.lisp:L71-L80@sha256:650a0e0fe875 · source/consolidation-engine.lisp:L93-L93@sha256:b70c25f2d524 ((kind :article :type keyword)) · source/consolidation-bridge.lisp:L71-L71@sha256:89f64cc69da1 source/consolidation-bridge.lisp:L81-L81@sha256:89f64cc69da1 (οι μόνοι σημερινοί παραγωγοί)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Η οντολογία εκπέμπεται με ΜΗ ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ ΣΕΙΡΑ: το all-concepts διατρέχει το sb-mop:class-direct-subclasses, του οποίου η σειρά αδελφών είναι ΑΠΡΟΣΔΙΟΡΙΣΤΗ από το πρότυπο MOP. Το emit-ontology-ttl παράγει το TTL με αυτή τη σειρά (άρα όχι byte-σταθερό μεταξύ εικόνων), και το ontology-outranks-facts του L2 χτίζει με αυτήν τη λίστα (:outranks …) που τροφοδοτεί τη σειρά εισαγωγής facts στο JTMS. Το ίδιο ισχύει για το edge-types του hypergraph."
   :severity :p2
   :evidence "source/greek-legislation-ontology.lisp:L87-L98@sha256:f6c6abee3574 source/greek-legislation-ontology.lisp:L214-L219@sha256:f6c6abee3574 (αξίωση type-agnostic emitter),229 · source/legal-conflict-resolution.lisp:L44-L60@sha256:eae756342fff · source/legal-hypergraph.lisp:L186-L192@sha256:a5eeb778d594"
   :is-it-in-the-known-defect-list :unknown)

  (:what "ΤΡΙΤΗ έδρα Turtle literal escaping με ΔΙΑΦΟΡΕΤΙΚΗ κάλυψη: το %ttl-esc της οντολογίας διαφεύγει \", \\ και \\n αλλά ΟΧΙ \\r — και το CR ΑΠΑΓΟΡΕΥΕΤΑΙ μέσα σε STRING_LITERAL_QUOTE της Turtle 1.1, οπότε ετικέτα/σχόλιο με CR παράγει άκυρο TTL. Το %ttl-lit του hypergraph (ίδια έννοια) καλύπτει \\r και \\t."
   :severity :p2
   :evidence "source/greek-legislation-ontology.lisp:L208-L212@sha256:f6c6abee3574 · source/legal-hypergraph.lisp:L46-L62@sha256:a5eeb778d594"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-reasoning-bridge: ΔΥΟ εξαγόμενες έδρες «ανάλυση επίπτωσης», μία θεμελιωμένη και μία όχι. Το grounded-impact επιβάλλει ΟΛΑ τα κλειδιά, δένει body↔graph, και ταιριάζει receipt-hash με tv-version-hash (θάνατος TRUST-01). Το reason-impact/impact-report παραμένουν εξαγόμενα και εκτυπώνουν ΤΗΝ ΙΔΙΑ ανάλυση χωρίς ΚΑΜΙΑ θεμελίωση, χωρίς valid-at/known-at, χωρίς receipts και χωρίς προειδοποίηση. Επιπλέον η μακρόβια μηχανή ανά doc βασίζεται σε ΣΧΟΛΙΟ («ίδιο αντικείμενο ⇒ ίδια facts εγγυημένα») — τα provision structs είναι μεταβλητά και τίποτα δεν το επιβάλλει, άρα επιτόπια μεταβολή σερβίρει μπαγιάτικα citation facts από την cache."
   :severity :p1
   :evidence "source/legal-reasoning-bridge.lisp:L96-L170@sha256:ba8a680fbe54 (θεμελιωμένη) · 20-22,69-89,172-181 (αθεμελίωτη, εξαγόμενη) · 47-67 (η cache και η υπόθεση αμεταβλητότητας)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "execution-trace clear-events!: εξαγόμενη συνάρτηση που ΣΒΗΝΕΙ ΟΛΟΚΛΗΡΟ το ίχνος εκτέλεσης και το *last-conclusion*. Το docstring λέει «ΜΟΝΟ για πύλες/δοκιμές σε σκιά — η παραγωγή δεν σβήνει ίχνη», αλλά δεν υπάρχει ΚΑΝΕΝΑΣ έλεγχος σκιώδους λειτουργίας, κανένα gate, καμία καταγραφή της ίδιας της διαγραφής. Αυθεντία με επιβολή :none πάνω στο μοναδικό μαγαζί προέλευσης εκτέλεσης."
   :severity :p1
   :evidence "source/execution-trace.lisp:L116-L118@sha256:70aa123251f4 · η εξαγωγή στη γραμμή 29"
   :is-it-in-the-known-defect-list :unknown)

  (:what "corpus-sparql: η επέκταση προθεμάτων είναι ΚΕΙΜΕΝΙΚΗ, όχι λεξική. Το %expand-one αντικαθιστά κάθε «prefix:local» ΟΠΟΥΔΗΠΟΤΕ στο ερώτημα — ΚΑΙ ΜΕΣΑ ΣΕ ΚΥΡΙΟΛΕΚΤΙΚΑ: το «eli:x» μέσα σε \"…\" γίνεται IRI. Ταυτόχρονα το %expand-prefixes ΣΒΗΝΕΙ με regex κάθε δήλωση PREFIX του χρήστη αλλά επεκτείνει ΜΟΝΟ τα τρία ενσωματωμένα, οπότε τα δικά του προθέματα μένουν ανεπέκτατα αντί να απορριφθούν. Και το τελικό error JSON χτίζεται με (substitute #\\Space #\\\") — δεν διαφεύγει backslash ούτε χαρακτήρες ελέγχου."
   :severity :p1
   :evidence "source/corpus-sparql.lisp:L42-L60@sha256:8b1997dd98b1 (κειμενική αντικατάσταση),62-67 (διαγραφή δηλώσεων PREFIX),94-104 (error JSON) · 73-74,100-101 (find-symbol χωρίς έλεγχο NIL)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-counterfactual minimal-blockers: πλήρης απαρίθμηση συνδυασμών έως max-size με ΠΛΗΡΗ επανυπαγωγή (νέα μηχανή subsume) ανά υποσύνολο — O(n^max-size) πλήρεις συμπερασμούς, χωρίς fuel, χωρίς χρονικό όριο, χωρίς φραγμό στο πλήθος γεγονότων. Η δικαιολόγηση «το %derive είναι γραμμικό, άρα η συστηματική δοκιμή είναι φθηνή» είναι ΣΧΟΛΙΟ, όχι μετρημένος ή επιβεβλημένος φραγμός."
   :severity :p2
   :evidence "source/legal-counterfactual.lisp:L9-L12@sha256:80d15b90e05d (η αξίωση),20-23 (%concluded-p χτίζει ΝΕΑ μηχανή ανά κλήση),38-60"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-hypo case-factors: η αφαίρεση ενός γεγονότος εξαρτάται από το ΥΠΟΛΟΙΠΟ σύνολο γεγονότων — ένα keyword θεωρείται «οντότητα» (και άρα πέφτει από τον παράγοντα) μόνο αν εμφανίζεται στο cddr ΑΛΛΟΥ γεγονότος. Προσθήκη ενός άσχετου γεγονότος μεταβάλλει σιωπηλά τον παράγοντα από (pred obj) σε (pred), αλλάζοντας κοινούς παράγοντες, διακρίσεις CATO, κατάταξη προηγουμένων και την πρόβλεψη knn-verdict."
   :severity :p2
   :evidence "source/legal-hypo.lisp:L23-L39@sha256:872011401024 (ιδίως 33-38) · 47-66 (η κατάταξη) · 68-84 (η πρόβλεψη)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "provenance-link validate-provenance: οι έλεγχοι ανά γεγονός είναι ΑΠΟΚΛΕΙΣΤΙΚΟΙ κλάδοι ενός cond — γεγονός χωρίς σύμβολο δεν ελέγχεται ούτε για συμβόλαιο ούτε για συστατικό, και γεγονός χωρίς συμβόλαιο δεν ελέγχεται για συστατικό. Ένα γεγονός με τρεις παραβάσεις αναφέρει μία· η λίστα παραβάσεων υποεκτιμά συστηματικά."
   :severity :p2
   :evidence "source/provenance-link.lisp:L60-L88@sha256:5354f41c3f06 (το cond στις 64-75)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-penalty %unit-days: όταν καμία μονάδα χρόνου δεν αναγνωρίζεται, η προεπιλογή είναι (t 365) — «κάθειρξη μετριέται πάντα σε έτη». Κάθε αριθμός σε απόσπασμα ποινής χωρίς αναγνωρίσιμη μονάδα πολλαπλασιάζεται ΣΙΩΠΗΛΑ επί 365. Ταυτόχρονα το %amount παίρνει τον ΠΡΩΤΟ αριθμό του tail (όλο το κείμενο μετά τη λέξη-ποινή), οπότε ένας αριθμός παραπομπής («ν. 4619/2019») μπορεί να διαβαστεί ως όριο ποινής."
   :severity :p2
   :evidence "source/legal-penalty.lisp:L82-L86@sha256:7ea6f2047ce9 · 67-76 (%amount στο tail) · 126-137 (το tail = subseq μετά τη λέξη)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "text-canonicalizer remove-fek-noise: ΔΙΑΓΡΑΦΕΙ ΚΕΙΜΕΝΟ ΝΟΜΟΥ με άπληστες regex, ΕΝΕΡΓΟ ΕΞ ΟΡΙΣΜΟΥ, ως ΤΕΛΕΥΤΑΙΟ στάδιο του προεπιλεγμένου pipeline. Τα μοτίβα «ΜΕΡΟΣ\\s+[…][Α-Ωα-ωά-ώA-Za-z\\s]+», «ΚΕΦΑΛΑΙΟ\\s+[…][Α-Ωα-ωά-ώA-Za-z\\s]+» περιλαμβάνουν το \\s στην ΕΠΑΝΑΛΑΜΒΑΝΟΜΕΝΗ κλάση — καταναλώνουν λέξεις ΚΑΙ αλλαγές γραμμής πέρα από τον τίτλο· το «ΤΜΗΜΑ\\s+[Α-ΩA-Z][΄]?[^.]*» με [^.]* καταπίνει τα ΠΑΝΤΑ ως την πρώτη τελεία. Το αποτέλεσμα γράφεται με regex-replace-all σε \"\" — δηλαδή αφαιρείται από το ΚΑΝΟΝΙΚΟ ΚΕΙΜΕΝΟ που κατόπιν κατακερματίζεται, δημοσιεύεται και σερβίρεται. Η κεφαλίδα του ίδιου αρχείου δηλώνει «PRESERVE MEANING: No semantic changes»."
   :severity :p0
   :evidence "source/text-canonicalizer.lisp:L19-L19@sha256:747fad14d692 (η αξίωση) · 138-146 (:remove-fek-noise στο προεπιλεγμένο pipeline) · 610-612 (*enable-fek-noise-removal* t) · 624-632 (τα άπληστα μοτίβα) · 655-668 (η διαγραφή) · 664 (και συμπτύσσει \\s{2,} σε ένα κενό, ακυρώνοντας το προηγούμενο normalize-line-breaks)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "text-canonicalizer: το ΑΡΧΕΙΟ ΜΕΤΑΣΧΗΜΑΤΙΣΜΩΝ είναι ΕΤΙΚΕΤΕΣ, όχι επεξεργασίες — η κανονικοποίηση είναι ΜΗ ΑΝΤΙΣΤΡΕΨΙΜΗ ενώ δηλώνει «REVERSIBLE (where possible): Track transformations» και «TRACEABLE: Maintain provenance chain». Κάθε transformation-record φέρει :before/:after ΠΕΡΙΓΡΑΦΕΣ («multiple spaces»→«single space», «σ (medial at word end)»→«ς (final)», «hyphen+space»→«joined») και :position ΠΑΝΤΑ 0 (με σχόλιο «Could track actual position if needed»). Ένα record ανά ΚΛΑΣΗ μετασχηματισμού, ανεξαρτήτως πλήθους αντικαταστάσεων. Το πρωτότυπο κείμενο δεν ανακατασκευάζεται από το ίχνος."
   :severity :p1
   :evidence "source/text-canonicalizer.lisp:L18-L22@sha256:747fad14d692 (οι αξιώσεις) · 197-204 (position 0, before/after ως strings-ετικέτες) · σημεία καταγραφής: 314,320,326,332,352-357,362-367,398-402,437-441,494-499,507-512,525-529,560-565"
   :is-it-in-the-known-defect-list :unknown)

  (:what "text-canonicalizer normalize-greek tonos: (cl-ppcre:regex-replace-all \"\\\\x{0301}\" result \"\\\\x{0384}\") — το ΔΕΥΤΕΡΟ όρισμα είναι ΣΥΜΒΟΛΟΣΕΙΡΑ ΑΝΤΙΚΑΤΑΣΤΑΣΗΣ, όχι regex: το cl-ppcre δεν ερμηνεύει εκεί \\x{…}. Το συνδυαστικό οξεία U+0301 ΔΕΝ γίνεται U+0384 — αντικαθίσταται από τους ΚΥΡΙΟΛΕΚΤΙΚΟΥΣ χαρακτήρες. Και η ίδια η πρόθεση είναι εσφαλμένη: το U+0384 είναι ΑΠΟΣΤΑΤΙΚΟΣ τόνος, όχι συνδυαστικός — η ορθή NFC θα συνέθετε α+U+0301 ⇒ U+03AC. Η καταγραφή δηλώνει «before: combining acute / after: Greek tonos»."
   :severity :p1
   :evidence "source/text-canonicalizer.lisp:L503-L513@sha256:747fad14d692"
   :is-it-in-the-known-defect-list :unknown)

  (:what "text-canonicalizer: η NFC κανονικοποίηση ΔΗΛΩΝΕΤΑΙ και ΔΕΝ ΥΠΑΡΧΕΙ. Η κεφαλίδα υπόσχεται «UNICODE: NFC normalization for consistent encoding» και το *enable-unicode-normalization* είναι T· η normalize-unicode κάνει ΤΕΣΣΕΡΙΣ αντικαταστάσεις στίξης (curly quotes→\", ‘’→', en/em dash→-, …→...) και τίποτε άλλο, με δικό της docstring που παραδέχεται «Full NFC requires SBCL unicode support». Η αντικατάσταση – — από - καταστρέφει τα ΕΥΡΗ παραπομπών («άρθρα 235–263») που κατόπιν διαβάζει ο εξαγωγέας παραπομπών."
   :severity :p1
   :evidence "source/text-canonicalizer.lisp:L13-L13@sha256:747fad14d692 (αξίωση NFC) · 376-407 (η υλοποίηση) · 392-395 (οι αντικαταστάσεις) · source/legal-references.lisp:L44-L48@sha256:d5c1a0763803 (ο καταναλωτής των ευρών)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "text-canonicalizer: το ταυτοτικό των κανονικών μπλοκ είναι ΚΑΘΟΛΙΚΟΣ ΜΕΤΡΗΤΗΣ ΕΙΚΟΝΑΣ («CBLOCK-~A» από (incf *canonical-block-counter*)) — εξαρτάται από το πόσα μπλοκ κανονικοποιήθηκαν ΝΩΡΙΤΕΡΑ στην ίδια εικόνα, όχι από το περιεχόμενο. Το id μπαίνει στην ΑΛΥΣΙΔΑ ΠΡΟΕΛΕΥΣΗΣ (extend-trace :canonical-block-ids). Η κεφαλίδα δηλώνει «DETERMINISTIC: Same input → same output»."
   :severity :p1
   :evidence "source/text-canonicalizer.lisp:L20-L20@sha256:747fad14d692 (η αξίωση) · 210 · 263-278 · 811-813 (χειροκίνητο reset — σύμβαση, όχι δομή)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "source-profile: Η ΣΥΝΑΙΝΕΣΗ ΠΟΛΛΑΠΛΩΝ ΠΗΓΩΝ ΣΥΓΚΡΙΝΕΙ ΟΝΟΜΑΤΑ ΑΡΧΕΙΩΝ, ΟΧΙ ΚΕΙΜΕΝΟ. Το %dir->records παράγει (:identity ΟΝΟΜΑ :content ΟΝΟΜΑ :payload διαδρομή) — το content-hash είναι ο κατακερματισμός του ΟΝΟΜΑΤΟΣ ΑΡΧΕΙΟΥ. Το %resolve-group αποφασίζει ΣΥΜΦΩΝΙΑ μετρώντας διακριτά content-hash. Άρα δύο κανάλια βασισμένα σε κατάλογο (institutional feed-dir ΚΑΙ manual-drop χρησιμοποιούν και τα δύο το %dir->records) με ομώνυμα αρχεία ΔΙΑΦΟΡΕΤΙΚΟΥ ΠΕΡΙΕΧΟΜΕΝΟΥ πιστοποιούνται ως :agreed με corroboration — «επιβεβαίωση» χωρίς καμία σύγκριση κειμένου."
   :severity :p0
   :evidence "source/source-profile.lisp:L434-L441@sha256:3a7df8a07d26 (%dir->records) · 442-458 (institutional feed-dir → %dir->records) · 496-501 (manual-drop → %dir->records) · 341-353 (η απόφαση συμφωνίας από content-hash) · 6-9,28-31 (η αξίωση «never trusts a single fragile scrape when a higher channel can confirm it»)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "source-profile: ΑΠΟΤΥΧΙΑ ΚΑΝΑΛΙΟΥ ⇒ ΣΙΩΠΗΛΗ ΑΝΑΒΑΘΜΙΣΗ ΣΕ ΕΜΠΙΣΤΟ. Το acquire τυλίγει τον acquirer σε (handler-case … (error () nil)), οπότε δίκτυο/parse/auth σφάλμα δίνει NIL — αδιάκριτο από «τίποτα νέο». Το %resolve-group τότε βλέπει ΜΙΑ πηγή, βρίσκει 1 διακριτό hash και τη σημαίνει :sole, την οποία το acquire-with-consensus κατατάσσει στα TRUSTED «safe to apply automatically». Έτσι η πτώση του διασταυρωτικού καναλιού μετατρέπει ασυνεπίβεβαιωτο scrape (authority 40, «fragile and legally grey») σε αυτόματα εφαρμοστέο κείμενο, παρά το *auto-trust-authority* 80 που φρουρεί ΜΟΝΟ τον κλάδο της διαφωνίας."
   :severity :p1
   :evidence "source/source-profile.lisp:L263-L270@sha256:3a7df8a07d26 (η κατάποση) · 345-353 (:sole) · 370-374 (τα :sole στα TRUSTED) · 306-310 (το κατώφλι που δεν εφαρμόζεται εδώ)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "source-profile make-consensus-source: (ignore-errors (funcall on-conflict conflicts)) — ο ΧΕΙΡΙΣΤΗΣ ΣΥΓΚΡΟΥΣΕΩΝ, δηλαδή ΑΚΡΙΒΩΣ ο μηχανισμός που στέλνει τη διαφωνία σε άνθρωπο, έχει τα σφάλματά του καταπιεμένα. Οι συγκρουόμενες διατάξεις έχουν ΗΔΗ εξαιρεθεί από τα trusted, οπότε αποτυχία της ουράς ελέγχου τις εξαφανίζει τελείως: ούτε δημοσιεύονται ούτε τις βλέπει κανείς. Η αξίωση του module είναι «human-in-the-loop exactly where they do not [agree]»."
   :severity :p1
   :evidence "source/source-profile.lisp:L33-L34@sha256:3a7df8a07d26 (η αξίωση) · 539-552 (ιδίως 542-543)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "source-profile %canonical: η «deterministic, order-stable» μορφή σύγκρισης εξαρτάται από τις μεταβλητές του ΕΚΤΥΠΩΤΗ — (format nil \"~S\" x) για strings και για κάθε άγνωστο τύπο (επηρεάζεται από *package* στα σύμβολα) και (princ-to-string (car e)) για κλειδιά alist (επηρεάζεται από *print-case*). Επιπλέον ΣΥΓΚΡΟΥΟΝΤΑΙ δομές: το plist (:a \"b\") και το alist ((\"A\" . \"b\")) δίνουν ΤΟ ΙΔΙΟ {A=\"b\"} και άρα το ίδιο content-hash — δύο πηγές με διαφορετική δομή δεδομένων πιστοποιούνται ως σύμφωνες."
   :severity :p1
   :evidence "source/source-profile.lisp:L209-L232@sha256:3a7df8a07d26 (ιδίως 215,226-231,232) · 234-239 (το content-hash) · 341-353 (η χρήση στη συναίνεση)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "signed-embedding-manifest: Ο ΚΥΚΛΟΣ export→load→verify ΕΙΝΑΙ ΔΟΜΙΚΑ ΑΔΥΝΑΤΟΣ. Η υπογραφή καλύπτει 20 πεδία (id, eli-uri, url, τίτλους, textHash, textLength, model, dimensions, vectorHash, author, dateCreated, γλώσσα, δικαιοδοσία, άδεια, blockchainAnchor), αλλά η δυαδική μορφή .embedding αποθηκεύει ΜΟΝΟ magic/version/flags/dimensions/text-hash/reserved/vector/signature. Το load-signed-manifest ανασυγκροτεί manifest με 5 από τα 22 πεδία — όλα τα υπόλοιπα NIL — και το verify-manifest-signature ξαναχτίζει το ωφέλιμο φορτίο ΑΠΟ ΑΥΤΟ. Το φορτίο δεν μπορεί ποτέ να ταυτιστεί με το υπογεγραμμένο. Δεύτερος, ανεξάρτητος λόγος: το διάνυσμα γράφεται ως float32 (απωλεστικά) ενώ το vectorHash υπολογίστηκε πάνω στο πρωτότυπο."
   :severity :p0
   :evidence "source/signed-embedding-manifest.lisp:L241-L266@sha256:b66e205e29a5 (τι καλύπτει η υπογραφή) · 453-538 (τι αποθηκεύει η δυαδική μορφή· 517-522 float32) · 544-615 (ο φορτωτής: 5 πεδία) · 304-321 (η επαλήθευση ξαναχτίζει από το κενό manifest) · 163-168 (το vectorHash του πρωτοτύπου)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "signed-embedding-manifest verify-manifest-signature: (handler-case (jws:verify-jws …) (error () nil)) ισοπεδώνει ΚΑΘΕ σφάλμα — απόν αρχείο δημόσιου κλειδιού, μη αναγνώσιμο PEM, μη υποστηριζόμενος αλγόριθμος, I/O — σε «η υπογραφή απέτυχε», και μετά σηματοδοτεί signature-verification-error με ΣΥΓΚΕΚΡΙΜΕΝΟ, ΨΕΥΔΗ λόγο «JWS signature verification failed». Το «δεν μπόρεσα να ελέγξω» παρουσιάζεται ως «έλεγξα και είναι άκυρη»."
   :severity :p1
   :evidence "source/signed-embedding-manifest.lisp:L304-L321@sha256:b66e205e29a5"
   :is-it-in-the-known-defect-list :unknown)

  (:what "signed-embedding-manifest: οι «Placeholder accessors (should be defined in article model)» ΦΑΒΡΙΚΑΡΟΥΝ δεδομένα αντί να αποτύχουν: article-number επιστρέφει 1, article-text επιστρέφει \"\", article-title-el/en επιστρέφουν \"\" για κάθε μη-λίστα. Το create-corpus-manifests τα καλεί, οπότε ένα σώμα από μη-plist αντικείμενα παράγει manifests ΟΛΑ με number 1 (που γράφουν το ίδιο article-001.jsonld/.ttl/.embedding) και ΚΕΝΟ κείμενο — δηλαδή υπογεγραμμένα embeddings του κενού string."
   :severity :p1
   :evidence "source/signed-embedding-manifest.lisp:L695-L706@sha256:b66e205e29a5 (τα stubs, με το ίδιο τους το σχόλιο) · 644-679 (η χρήση τους)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "shacl-validator: το «conforms» ΔΕΝ είναι ορθό ως προς τα shapes που του δόθηκαν. Αποτιμώνται ΜΟΝΟ οι περιορισμοί κάτω από sh:property· κάθε άλλο συστατικό SHACL Core που εμφανίζεται στο γράφο shapes (sh:node, sh:or, sh:not, sh:and, sh:xone, sh:closed, sh:qualifiedValueShape, sh:equals, sh:disjoint, sh:lessThan, sh:uniqueLang, sh:languageIn) καθώς και οι περιορισμοί στο ΙΔΙΟ το node shape ΑΓΝΟΟΥΝΤΑΙ ΣΙΩΠΗΛΑ — δεν απαριθμούνται, δεν αναφέρονται ως μη υποστηριζόμενα. Το VALIDATION-REPORT επιστρέφει conforms=true με πλήρη σιωπή για ό,τι δεν ελέγχθηκε."
   :severity :p1
   :evidence "source/shacl-validator.lisp:L132-L167@sha256:a0339815440c (ο parser κρατά μόνο 10 συστατικά) · 218-280 (η αποτίμηση) · 286-299 (conforms = notany Violation)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "shacl-validator rdf-list->terms: αποκωδικοποιεί rdf:first/rdf:rest ΧΩΡΙΣ φρουρό κύκλου — γράφος shapes με κυκλική αλυσίδα rdf:rest δεν φτάνει ποτέ σε rdf:nil και ο βρόχος ΔΕΝ ΤΕΡΜΑΤΙΖΕΙ. Χρησιμοποιείται για το sh:in, δηλαδή σε δεδομένα shapes που ο επικυρωτής δέχεται από έξω. Παράλληλα το sh:pattern μεταγλωττίζεται με cl-ppcre ΑΝΑ ΤΙΜΗ (όχι ανά shape) και χωρίς φραγμό υπολογισμού — κατά-στροφική οπισθοδρόμηση σε shapes αρχείο κρεμάει τον επικυρωτή, και κακοσχηματισμένη regex ματαιώνει ΟΛΟΚΛΗΡΟ το validate χάνοντας όλα τα ήδη ευρεθέντα αποτελέσματα."
   :severity :p1
   :evidence "source/shacl-validator.lisp:L102-L109@sha256:a0339815440c (χωρίς φρουρό κύκλου) · 246-264 (create-scanner εντός του dolist των τιμών) · 139-146 (parse-integer χωρίς handler)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "turtle-parser: το @base ΑΝΑΓΝΩΡΙΖΕΤΑΙ, ΑΠΟΘΗΚΕΥΕΤΑΙ ΚΑΙ ΔΕΝ ΔΙΑΒΑΖΕΤΑΙ ΠΟΤΕ. Το parser-base γράφεται στη γραμμή 360 και το σύμβολο δεν εμφανίζεται πουθενά αλλού σε ΟΛΟ το παγωμένο repo· το read-iriref επιστρέφει το IRI αυτούσιο χωρίς επίλυση ως προς τη βάση. Άρα τα ΣΧΕΤΙΚΑ IRI αποθηκεύονται ως «article/1» και συγκρίνονται με string= έναντι πλήρων IRI στον SHACL — οι στόχοι δεν βρίσκονται και οι περιορισμοί σιωπηλά δεν πυροδοτούν. Η κεφαλίδα δηλώνει «@prefix / @base directives» ως υποστηριζόμενα."
   :severity :p1
   :evidence "source/turtle-parser.lisp:L8-L8@sha256:4c1fb3a38dce (η αξίωση) · 113-132 (καμία επίλυση) · 180,358-362 (γράφεται, ποτέ δεν διαβάζεται· grep -rn parser-base /frozen/ro ⇒ 1 σημείο)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "turtle-parser: οι ακολουθίες διαφυγής \\uXXXX/\\UXXXXXXXX διαβάζονται με (loop repeat 4/8 collect (lx-next lx)) και το lx-next ΔΕΝ ελέγχει όρια. Κολοβό αρχείο στο τέλος μιας διαφυγής δίνει ΩΜΟ σφάλμα δείκτη πίνακα, ΟΧΙ την turtle-parse-error που δηλώνει το module — καλών που πιάνει turtle-parse-error δεν το πιάνει. Επίσης (code-char …) πάνω σε τιμή surrogate (D800–DFFF) δίνει NIL στο SBCL και το επόμενο write-char σηματοδοτεί σφάλμα τύπου."
   :severity :p2
   :evidence "source/turtle-parser.lisp:L93-L93@sha256:4c1fb3a38dce (lx-next χωρίς έλεγχο) · 125-130 (IRI) · 158-163 (literal) · 33-38 (η δηλωμένη συνθήκη)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-knowledge: ΤΡΕΙΣ ΔΙΑΦΟΡΕΤΙΚΕΣ ΑΙΤΙΕΣ ΕΜΦΑΝΙΖΟΝΤΑΙ ΩΣ ΜΙΑ «ΑΓΝΟΙΑ». Το plan-goal σημαίνει :frontier όταν (α) κανένας κανόνας δεν οδηγεί στον στόχο, (β) εξαντλήθηκε το *max-depth* 8, (γ) εντοπίστηκε κύκλος στο visited. Και οι τρεις τυπώνονται ως «✗ … δεν το θεμελιώνω· βαρύνει εσένα να το αποδείξεις» και συγκεντρώνονται από το plan-frontier ως «τα αδιάσπαστα κενά» / «το μέτωπο της άγνοιάς μου». Όριο αναζήτησης παρουσιάζεται στον χρήστη ως κενό γνώσης."
   :severity :p1
   :evidence "source/legal-knowledge.lisp:L144-L146@sha256:d0c50f4e981e · 176-218 (ιδίως 184-185) · 232-240 · 320-329 (η φράση :missing) · 278-284"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-knowledge: *resolvers* και *extra-rules* ΕΝΕΙΟΥΝ ΓΕΓΟΝΟΤΑ ΚΑΙ ΚΑΝΟΝΕΣ ΣΤΟΝ ΕΝΟΠΟΙΗΜΕΝΟ ΣΥΛΛΟΓΙΣΤΗ ΧΩΡΙΣ ΚΑΜΙΑ ΠΥΛΗ. Το register-resolver δέχεται ΑΥΘΑΙΡΕΤΗ συνάρτηση· το %acquire την καλεί κατά τον σχεδιασμό απόδειξης· τα επιστρεφόμενα «αποκτημένα» γεγονότα μπαίνουν με (append acquired facts) ως ΠΡΟΚΕΙΜΕΝΑ στη μηχανή και το αποτέλεσμα τυπώνεται «✓ Το απέδειξα». Τα αποκτημένα γεγονότα δεν φέρουν πηγή, receipt ή διάκριση μέσα στο δέντρο απόδειξης — είναι αδιάκριτα από τα δοθέντα. Το ίδιο το docstring δηλώνει «καμία σύζευξη εδώ», δηλαδή η απόφαση εμπιστοσύνης ανατίθεται εξ ολοκλήρου σε ανώνυμους καλούντες."
   :severity :p1
   :evidence "source/legal-knowledge.lisp:L27-L35@sha256:d0c50f4e981e (*extra-rules* στους planning-rules) · 148-154 (register-resolver) · 168-174 (%acquire) · 260-277 (τα αποκτημένα ως προκείμενα + «✓ Το απέδειξα»)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "ΔΥΟ ΔΙΑΦΟΡΕΤΙΚΕΣ ΣΗΜΑΣΙΟΛΟΓΙΕΣ ΤΑΙΡΙΑΣΜΑΤΟΣ ΓΙΑ ΤΟ ΙΔΙΟ ΕΡΩΤΗΜΑ, ΣΤΗΝ ΙΔΙΑ ΑΝΑΦΟΡΑ. Το apply-norms του L5 στοιχειοθετεί με το ευρετηριασμένο match-patterns (πλήρες join με οπισθοδρόμηση). Το conclusion-status και το norm-gaps του Σ4 κρίνουν «στοιχειοθετείται / ΤΙ ΛΕΙΠΕΙ» με το satisfy-patterns, που είναι ρητά GREEDY: παίρνει το ΠΡΩΤΟ γεγονός που ενοποιείται ανά πρότυπο και ΔΕΝ οπισθοδρομεί. Άρα το subsumption-report μπορεί να τυπώσει «ΔΕΝ στοιχειοθετείται — ΛΕΙΠΕΙ Χ» για κανόνα που το subsume ΟΝΤΩΣ συμπέρανε, και η «μετα-γνώση της άγνοιας» υπολογίζεται από ασθενέστερο ταιριαστή από αυτόν που αποφασίζει."
   :severity :p1
   :evidence "source/legal-deontic.lisp:L113-L141@sha256:3b584b2845ae (match-patterns) · source/legal-knowledge.lisp:L68-L77@sha256:d0c50f4e981e (satisfy-patterns, greedy) · source/legal-subsumption.lisp:L137-L160@sha256:a09f4835a11c (conclusion-status),162-171 (norm-gaps),225-270 (η αναφορά)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "fluid-induction solve-task: ΤΡΙΤΗ, ΑΔΗΛΩΤΗ ΕΚΒΑΣΗ. Το πρόγραμμα επικυρώνεται ότι εξηγεί ΟΛΑ τα ζεύγη ΕΚΠΑΙΔΕΥΣΗΣ, μετά εφαρμόζεται στο test-input μέσω apply-program που τυλίγει τα πάντα σε (handler-case … (error () nil)). Αν το πρόγραμμα σφάλει στη ΔΟΚΙΜΗ (π.χ. %strip-border σε μικρό πλέγμα, %guard-cells υπέρβαση), επιστρέφεται (values NIL πρόγραμμα NIL) — πρόβλεψη NIL ΧΩΡΙΣ λόγο, ενώ το συμβόλαιο δηλώνει «Τίποτα; ⇒ (nil nil λόγος)». Επιπλέον το %map-programs είναι χειροκίνητα ξετυλιγμένο έως βάθος 3: max-depth 5 ψάχνει έως 3 αλλά το μήνυμα τιμιότητας τυπώνει «βάθος ≤5»."
   :severity :p1
   :evidence "source/fluid-induction.lisp:L176-L189@sha256:3c12a25e4863 (apply-program) · 211-225 (ξετύλιγμα έως 3) · 236-251 (το συμβόλαιο και το μήνυμα)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "embeddings-authority: ΟΛΟΚΛΗΡΟ ΤΟ ΤΟΠΙΚΟ ΜΟΝΟΠΑΤΙ ΕΝΣΩΜΑΤΩΣΕΩΝ ΣΗΜΑΤΟΔΟΤΕΙ ΠΑΝΤΑ. Το ensure-model-loaded σφάλλει επειδή «word-vector ingestion is not a current capability» (ο loader διαγράφηκε), οπότε embed-text, embed-texts, similarity, find-similar, compute-similarity-matrix, cluster-by-similarity, oov-words, vocabulary-coverage είναι εξαγόμενα και μη λειτουργικά — ενώ η κεφαλίδα διαφημίζει «GloVe/Word2Vec (fallback - no external dependency)» ως διαθέσιμο backend. Επιπλέον cosine-similarity/euclidean-distance/dot-product ΔΕΝ ελέγχουν ισότητα διαστάσεων: διάνυσμα μεγαλύτερο από το πρώτο αγνοείται σιωπηλά στην ουρά του, δίνοντας ΛΑΘΟΣ ομοιότητα αντί για σφάλμα."
   :severity :p1
   :evidence "source/embeddings-authority.lisp:L6-L8@sha256:0f08cd969fc6 (η αξίωση fallback) · 217-224,440-444 (τα διαγραμμένα) · 450-454 · 229-263 · 296-316,318-328,348-351 (χωρίς έλεγχο διαστάσεων)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "embeddings-authority: το *openai-endpoint* είναι ΑΠΛΗ defvar και το κλειδί έρχεται από τη μεταβλητή περιβάλλοντος OPENAI_API_KEY — μεταβολή της μεταβλητής endpoint στέλνει το ΜΥΣΤΙΚΟ σε αυθαίρετο host μέσω κεφαλίδας Authorization. Καμία καρφίτσωση host, κανένας φρουρός SSRF, καμία καταγραφή. Είναι το δεύτερο μυστικό που εισάγεται από περιβάλλον στην εικόνα (το πρώτο: ETHEREUM_PRIVATE_KEY στο blockchain-authority)."
   :severity :p1
   :evidence "source/embeddings-authority.lisp:L61-L68@sha256:0f08cd969fc6 source/embeddings-authority.lisp:L70-L82@sha256:0f08cd969fc6 source/embeddings-authority.lisp:L111-L125@sha256:0f08cd969fc6 source/embeddings-authority.lisp:L162-L175@sha256:0f08cd969fc6 · source/blockchain-authority.lisp:L951-L972@sha256:caadc9c75a98"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-subsumption %devar: το φράγμα +max-distinct-vars+ 256 είναι ΑΝΑ ΚΛΗΣΗ (ο πίνακας vars είναι φρέσκος προεπιλεγμένος όρος), όχι καθολικό — τα σύμβολα δεν αποδεσμεύονται ποτέ από το πακέτο. Απεριόριστες κλήσεις με νέα ονόματα εξακολουθούν να αυξάνουν μόνιμα το πακέτο κατά 256 σύμβολα τη φορά, ενώ το docstring δηλώνει ότι εμποδίζει input-derived ονόματα να «γεμίζουν ΜΟΝΙΜΑ το package». Ρυθμιστής ρυθμού, όχι εξάλειψη της κλάσης σφάλματος."
   :severity :p2
   :evidence "source/legal-subsumption.lisp:L33-L37@sha256:a09f4835a11c source/legal-subsumption.lisp:L48-L66@sha256:a09f4835a11c"
   :is-it-in-the-known-defect-list :unknown)

  (:what "text-canonicalizer normalize-quotes: μετατρέπει κάθε ζεύγος ευθειών εισαγωγικών σε γαλλικά («…») όταν το κείμενο περιέχει ελληνικό γράμμα. Στην ελληνική νομοθεσία το εισαγωγικό περιεχόμενο ΕΙΝΑΙ το κείμενο αντικατάστασης μιας τροποποιητικής διάταξης («αντικαθίσταται ως εξής: …»): η αλλαγή χαρακτήρων αλλάζει το κανονικό κείμενο που κατακερματίζεται. Με περιττό πλήθος εισαγωγικών η ζευγαροποίηση από το \"([^\"]+)\" είναι αυθαίρετη. Το ίδιο το σχόλιο παραδέχεται «This is simplified - real implementation would track nesting»."
   :severity :p2
   :evidence "source/text-canonicalizer.lisp:L571-L597@sha256:747fad14d692 (ιδίως 583-586)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "narrative-provenance: ΤΟ ΙΧΝΟΣ ΠΡΟΕΛΕΥΣΗΣ ΕΙΝΑΙ ΦΑΒΡΙΚΑΡΙΣΜΕΝΟ ΚΑΙ ΣΤΑΘΕΡΟ — δεν διαβάζει το αντικείμενο narrative. Από τους 12 συγγραφείς φάσεων, ΟΙ 11 δεν αναφέρουν καθόλου την παράμετρο (μόνο το write-narrative-overview τη διαβάζει, 8 φορές)· τα write-chronological-timeline, write-agent-contributions, write-instruments-registry, write-evidence-trail έχουν ΜΗΔΕΝ αναφορές. Εκπέμπονται ως PROV-O/schema.org γεγονότα για ΠΡΑΓΜΑΤΙΚΟ νομικό σώμα: σταθερή συναλλαγή Ethereum «0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7» με blockNumber «18500000» και gasUsed «150000», το κανονικό IPFS παράδειγμα-CID «QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco», κατακερματισμοί κυριολεκτικά «sha256:abc123...» / «sha256:def456...», commit «abc123def456», και URL επαλήθευσης QES σε ΠΡΑΓΜΑΤΙΚΟ κυβερνητικό τομέα «https://validate.aped.gov.gr/QES-2024-STAV-001». Ο χρόνος έναρξης κάθε αφήγησης είναι το σταθερό initform «2019-01-01T00:00:00Z»."
   :severity :p0
   :evidence "source/narrative-provenance.lisp:L266-L266@sha256:bb5aaa7b01a0 (generate-narrative-trail) · 597-635 (write-anchoring-phase: σταθερές ώρες, tx hash, gas, IPFS CID· μηδέν αναφορές στο narrative) · 798-844 (write-evidence-trail: placeholder hashes, QES URL, commit· μηδέν αναφορές) · 664-696,697-743,744-797 (μηδέν αναφορές) · 79-80 (σταθερό start-time)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "ΔΥΟ ΤΑΥΤΟΛΟΓΙΚΟΙ ΕΠΑΛΗΘΕΥΤΕΣ ΠΟΥ ΔΕΝ ΜΠΟΡΟΥΝ ΝΑ ΕΠΙΣΤΡΕΨΟΥΝ NIL, ΜΕ ΤΟ ΙΔΙΟ ΙΔΙΩΜΑ, ΣΕ ΔΥΟ ΑΡΧΕΙΑ. Και το verify-provenance-chain και το verify-authority-chain χτίζουν λίστα checks κάνοντας ΜΟΝΟ (push (cons :κλειδί T)) μέσα σε (when …) — καμία διαδρομή δεν σπρώχνει NIL — και τελειώνουν με (values (every #'cdr checks) checks). Αποτυχία ελέγχου σημαίνει ΑΠΟΥΣΙΑ στοιχείου, όχι ψευδές στοιχείο· και αν ΟΛΟΙ οι έλεγχοι αποτύχουν, checks = NIL και το (every #'cdr NIL) είναι T. Δηλαδή: αφήγηση χωρίς δραστηριότητες/βήματα/ελέγχους και με ασυνεπές χρονολόγιο επιστρέφει «η αλυσίδα προέλευσης επαληθεύτηκε»· ισχυρισμός αυθεντίας χωρίς QES, χωρίς αγκύρωση, χωρίς IPFS, χωρίς αποδόσεις και χωρίς διαπιστευτήρια επιστρέφει «η αλυσίδα αυθεντίας επαληθεύτηκε»."
   :severity :p0
   :evidence "source/narrative-provenance.lisp:L907-L930@sha256:bb5aaa7b01a0 · source/semantic-authority.lisp:L730-L754@sha256:3b7ab18ddb0a"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-extraction-verify: Η ΠΥΛΗ ΤΟΥ ΣΥΜΒΟΥΛΟΥ ΕΠΑΛΗΘΕΥΕΙ ΤΟ ΠΑΡΑΘΕΜΑ, ΟΧΙ ΤΟΝ ΙΣΧΥΡΙΣΜΟ. Το V2 απαιτεί το χωρίο-απόδειξη να υπάρχει αυτολεξεί στο κείμενο ΚΑΙ να φέρει δεοντικό τελεστή· το V3 ελέγχει το CONSEQUENT μόνο για (null consequent). ΤΙΠΟΤΑ δεν δένει το consequent — τη ΡΥΘΜΙΖΟΜΕΝΗ ΠΡΑΞΗ που θα καταχωρηθεί ως κανόνας στο L5 και θα υπαχθεί σε πραγματικά περιστατικά — με το κείμενο της διάταξης. Ο σύμβουλος παραθέτει γνήσιο χωρίο και δηλώνει ΟΠΟΙΑΔΗΠΟΤΕ πράξη: η πύλη το δέχεται. Επιπλέον το deontic-marker-in δέχεται αν ΕΣΤΩ ΜΙΑ πρόταση του χωρίου φέρει τη ζητούμενη τυπικότητα, οπότε μακρύ παράθεμα με ανάμεικτες τυπικότητες τεκμηριώνει όποια από αυτές συμφέρει."
   :severity :p0
   :evidence "source/legal-extraction-verify.lisp:L356-L361@sha256:d03e8fa588fd (V3) · 362-370 (V2) · 383-387 (ο κανόνας χτίζεται με το consequent του συμβούλου) · 321-327 (αρκεί μία πρόταση)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-extraction-verify: ο συμβολικός «κριτής» του συμβούλου είναι ΕΥΡΕΤΙΚΟΣ ΤΑΞΙΝΟΜΗΤΗΣ ΕΛΛΗΝΙΚΩΝ ΣΥΜΒΟΛΟΣΕΙΡΩΝ με ΔΗΛΩΜΕΝΗ ορθότητα ~81,5%. Τα ίδια τα σχόλια καταγράφουν τη μέτρηση (163 δείγματα, 5 κριτές· 56% → 81,5% → γ' γύρος) — δηλαδή περίπου 1 στις 5 ταξινομήσεις είναι λάθος. Το verdict struct ΔΕΝ φέρει βαθμό βεβαιότητας και το verify-and-register καταχωρεί τον κανόνα ως επαληθευμένο, σε module που δηλώνει «έτσι … ΧΩΡΙΣ να πέφτει το 0 λάθος»."
   :severity :p0
   :evidence "source/legal-extraction-verify.lisp:L38-L40@sha256:d03e8fa588fd (η μέτρηση) · 303-313 (το docstring με τα ποσοστά) · 53-102 (οι λίστες στελεχών) · 333-337 (verdict χωρίς βεβαιότητα) · 389-395 (η καταχώρηση)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "legal-extraction-verify: το ID του κανόνα παράγεται ΜΟΝΟ από την πηγή — (intern (format nil \"NORM-~A\" source) :keyword) — και το register-norm γράφει σε hash κατά id. Δεύτερη επαληθευμένη πρόταση για ΤΟ ΙΔΙΟ άρθρο ΣΒΗΝΕΙ ΣΙΩΠΗΛΑ την πρώτη, ανεξαρτήτως τυπικότητας ή πράξης: μια διάταξη που φέρει και υποχρέωση και άδεια μπορεί να κρατήσει μόνο μία. Και ο ίδιος ο έλεγχος αυτο-αντίφασης V4 ψάχνει στα all-norms, από όπου ο προηγούμενος κανόνας έχει ήδη εξαφανιστεί. Ο κανόνας παράγεται πάντα με :antecedent nil, δηλαδή ΑΝΕΠΙΦΥΛΑΚΤΟΣ — και το case-norms της υπαγωγής κρατά ΜΟΝΟ όσους ΕΧΟΥΝ antecedent, οπότε κανένας κανόνας αυτής της πύλης δεν συμμετέχει ποτέ σε υπαγωγή υπόθεσης."
   :severity :p1
   :evidence "source/legal-extraction-verify.lisp:L383-L387@sha256:d03e8fa588fd source/legal-extraction-verify.lisp:L389-L395@sha256:d03e8fa588fd · source/legal-deontic.lisp:L87-L87@sha256:3b584b2845ae (register-norm) · source/legal-subsumption.lisp:L88-L93@sha256:a09f4835a11c (case-norms) · source/legal-extraction-verify.lisp:L371-L380@sha256:d03e8fa588fd (V4)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "sparql-endpoint: το ORDER BY ΔΗΛΩΝΕΤΑΙ ΚΑΙ ΔΕΝ ΕΦΑΡΜΟΖΕΤΑΙ ΠΟΤΕ. Η κεφαλίδα το απαριθμεί δύο φορές ως υποστηριζόμενο και υπάρχει slot order-by, αλλά το σύμβολο δεν εμφανίζεται σε κανένα μονοπάτι αποτίμησης — δεν τίθεται καν από το parse-modifiers. Το sparql-select εφαρμόζει DISTINCT, OFFSET και LIMIT πάνω σε ΑΤΑΞΙΝΟΜΗΤΟ σύνολο, οπότε «ORDER BY ?x LIMIT 10» επιστρέφει δέκα ΑΥΘΑΙΡΕΤΕΣ γραμμές παρουσιασμένες ως τις πρώτες δέκα κατά σειρά."
   :severity :p1
   :evidence "source/sparql-endpoint.lisp:L10-L10@sha256:8528099d891a source/sparql-endpoint.lisp:L117-L117@sha256:8528099d891a (οι αξιώσεις) · 80 (το slot) · 313-337 (parse-modifiers) · 388-415 (η αποτίμηση: DISTINCT/OFFSET/LIMIT, καμία ταξινόμηση)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "sparql-endpoint results-to-json / results-to-xml: ΚΑΘΕ δέσμευση εκπέμπεται με τύπο «uri» ανεξαρτήτως τι είναι — κυριολεκτικά, αριθμοί, boolean αναφέρονται στον πελάτη ως IRI, παραβιάζοντας τη μορφή αποτελεσμάτων SPARQL 1.1. Επιπλέον το XML γράφει <uri>~A</uri> ΧΩΡΙΣ ΚΑΜΙΑ ΔΙΑΦΥΓΗ XML: τιμή με < > & παράγει κακοσχηματισμένο XML και τιμή με «</uri><uri>» εγχέει δεσμεύσεις. Και το results-to-json κάνει (intern var :keyword) πάνω σε ΟΝΟΜΑ ΜΕΤΑΒΛΗΤΗΣ ΤΟΥ ΠΕΛΑΤΗ — απεριόριστο intern από μη αυθεντικοποιημένο αίτημα, ακριβώς το sink που το legal-subsumption θωράκισε με δηλωμένο φράγμα."
   :severity :p1
   :evidence "source/sparql-endpoint.lisp:L554-L573@sha256:8528099d891a (τύπος uri + intern) · 576-600 (XML χωρίς διαφυγή) · source/legal-subsumption.lisp:L33-L66@sha256:a09f4835a11c (η θωρακισμένη έδρα του ίδιου sink)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "eu-interop-layer generate-did: η ΤΑΥΤΟΤΗΤΑ (DID) με την οποία ο οργανισμός εγγράφεται στο EBSI παράγεται από (format nil \"~A-~A\" (now :source :system) (random 1000000)) και κατακερματίζεται. Το random χρησιμοποιεί το ΠΡΟΕΠΙΛΕΓΜΕΝΟ *random-state*, που το SBCL αρχικοποιεί ΤΑΥΤΟΣΗΜΑ σε κάθε εκκίνηση εικόνας — άρα η ακολουθία είναι αναπαραγώγιμη και η εντροπία το πολύ ~20 bits συν το ρολόι. Κρυπτογραφική ταυτότητα χωρίς CSPRNG. Ίδια κλάση σφάλματος με το generate-uuid του audit."
   :severity :p1
   :evidence "source/eu-interop-layer.lisp:L376-L387@sha256:a3807069a264 (και EBSI_DID από περιβάλλον, γρ. 378) · source/legal-audit-system.lisp:L780-L787@sha256:53613cdd00f0 (η ίδια κλάση)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "Η ΚΛΑΣΗ ΣΦΑΛΜΑΤΟΣ «σιωπηλό fallback σε RDF namespace» ΚΛΕΙΣΤΗΚΕ ΣΕ ΜΙΑ ΕΔΡΑ ΚΑΙ ΕΜΕΙΝΕ ΑΝΟΙΧΤΗ ΣΕ ΤΡΕΙΣ. Το ai-ingest-manifest τεκμηριώνει ρητά τη διόρθωση («ΔΕΝ get-base-uri … ΟΥΤΕ σιωπηλό (ignore-errors) fallback. Ένα RDF prefix ΟΦΕΙΛΕΙ να είναι σταθερό») και ορίζει σταθερά +institution-vocabulary-base+. Το narrative-provenance (3 prefixes + το corpus-uri initform), το ai-citation-strategy (3 prefixes) και το semantic-versioning-system (delta prefix) εξακολουθούν να χρησιμοποιούν (or (ignore-errors (get-base-uri)) \"https://…\"): σφάλμα της αρχής URI αλλάζει ΣΙΩΠΗΛΑ την ταυτότητα ΚΑΘΕ κατηγορήματος του εκπεμπόμενου γράφου, χωρίς καμία σήμανση."
   :severity :p1
   :evidence "source/ai-ingest-manifest.lisp:L30-L38@sha256:60194efad04d (η κλεισμένη έδρα) · source/narrative-provenance.lisp:L32-L34@sha256:bb5aaa7b01a0 source/narrative-provenance.lisp:L76-L76@sha256:bb5aaa7b01a0 · source/ai-citation-strategy.lisp:L31-L33@sha256:af9cd72d5bf2 source/ai-citation-strategy.lisp:L389-L389@sha256:af9cd72d5bf2 · source/semantic-versioning-system.lisp:L43-L43@sha256:14fe14638ea7"
   :is-it-in-the-known-defect-list :unknown)

  (:what "rdfs-inference run-inference και reasoning-authority compute-closure: ΚΟΛΟΒΟ ΚΛΕΙΣΙΜΟ ΔΗΛΩΝΕΤΑΙ ΩΣ ΠΛΗΡΕΣ. Και οι δύο σταματούν στο max-iterations (100 / 1000), εκπέμπουν (warn …) στο *error-output* και ΕΠΙΣΤΡΕΦΟΥΝ κανονικά· το rdfs-inference θέτει επιπλέον (knowledge-base-inferred-p kb) t και τυπώνει «RDFS inference complete». Ο καλών που ελέγχει το inferred-p ΔΕΝ μπορεί να ξεχωρίσει πλήρες κλείσιμο από κομμένο. Το ίδιο μοτίβο και στο pagerank του citation-authority, που τυπώνει «Reached max iterations» και επιστρέφει μη συγκλίνουσα κεντρικότητα ως αποτέλεσμα."
   :severity :p1
   :evidence "source/rdfs-inference.lisp:L399-L431@sha256:cc47768ad655 (ιδίως 417-420,428-431) · source/reasoning-authority.lisp:L455-L480@sha256:c4da9cef6085 · source/citation-authority.lisp:L408-L476@sha256:f4ad0fd3855e (ιδίως 475)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "validate-logical-blocks: η ΠΥΛΗ ΠΟΙΟΤΗΤΑΣ ΤΟΥ ΕΠΙΠΕΔΟΥ 2 ΠΕΡΝΑΕΙ ΑΚΡΙΒΩΣ ΤΙΣ ΔΥΟ ΣΥΝΘΗΚΕΣ ΑΠΟΤΥΧΗΜΕΝΗΣ ΤΑΞΙΝΟΜΗΣΗΣ. Μπλοκ ταξινομημένο ως :unknown δίνει record-warning και ΕΠΙΣΤΡΕΦΕΙ T («Warning, not error»)· μπλοκ με βεβαιότητα ΚΑΤΩ από το *minimum-confidence* δίνει record-warning και ΕΠΙΣΤΡΕΦΕΙ T. Ταυτόχρονα οι ίδιες οι «βεβαιότητες» του ταξινομητή είναι ΣΤΑΘΕΡΕΣ ΚΥΡΙΟΛΕΞΙΕΣ ανά κλάδο μοτίβου (0.95, 0.98), όχι μετρήσεις — άρα το κατώφλι συγκρίνει σταθερά με σταθερά και δεν φράζει τίποτα."
   :severity :p1
   :evidence "source/validate-logical-blocks.lisp:L148-L163@sha256:f8714abbe650 (:unknown ⇒ T),165-179 (χαμηλή βεβαιότητα ⇒ T) · source/typographic-classifier.lisp:L458-L473@sha256:d08a6d8588c3 (οι σταθερές βεβαιότητες)"
   :is-it-in-the-known-defect-list :unknown)

  (:what "ai-citation-strategy send-prometheus-metric: το resource και το agent παρεμβάλλονται ΑΦΙΛΤΡΑΡΙΣΤΑ στη γραμμή έκθεσης Prometheus — (format nil \"resource=\\\"~A\\\",agent=\\\"~A\\\"\" …) και μετά \"~A{~A} 1~%\" — και γίνονται POST σε αυθαίρετο ρυθμισμένο endpoint. Το agent προέρχεται από παρακολούθηση αιτημάτων (User-Agent), άρα τιμή με εισαγωγικό ή αλλαγή γραμμής εγχέει αυθαίρετες μετρικές στο pushgateway."
   :severity :p2
   :evidence "source/ai-citation-strategy.lisp:L589-L601@sha256:af9cd72d5bf2"
   :is-it-in-the-known-defect-list :unknown)

  (:what "lexicon-neurolingo: η κεφαλίδα δηλώνει «1.2M+ Greek Morphological Entries» ενώ η μόνη διαθέσιμη υλοποίηση είναι make-placeholder-lexicon με ΤΡΕΙΣ λέξεις. Η ένδειξη έλλειψης είναι (warn …) σε :before μέθοδο — ΔΕΝ αρνείται: το lexicon-lookup συνεχίζει και επιστρέφει NIL για καθετί εκτός των τριών, αδιάκριτο από «δεν είναι λέξη». Παρόμοια, greek-lemmatizer και reasoning-authority αυτοδηλώνουν «STATUS: Not yet loaded by any .asd - pending integration»."
   :severity :p2
   :evidence "source/lexicon-neurolingo.lisp:L3-L4@sha256:aebdb35a0ab8 (η αξίωση),246-265 (το stub και το warn) · source/greek-lemmatizer.lisp:L5-L6@sha256:12b56d83d333 · source/reasoning-authority.lisp:L5-L6@sha256:c4da9cef6085"
   :is-it-in-the-known-defect-list :unknown)

  (:what "semantic-authority generate-authority-manifest: κάθε παραγόμενο manifest προσθέτει ΑΝΕΥ ΟΡΩΝ απόδοση στον «Spyridon Stavropoulos» ως «Creator» ΚΑΙ επαληθεύσιμο διαπιστευτήριο τύπου :qes με εκδότη «APED» — τη ΠΡΑΓΜΑΤΙΚΗ ελληνική αρχή διαπίστευσης ηλεκτρονικών υπογραφών — και proof την κυριολεξία «signature-proof». Η ίδια συνάρτηση σωστά απαιτεί qes-hash και blockchain-uri fail-closed («no hardcoded defaults»), αλλά το διαπιστευτήριο που δηλώνει ποιος το πιστοποίησε είναι σταθερό placeholder."
   :severity :p1
   :evidence "source/semantic-authority.lisp:L757-L790@sha256:3b7ab18ddb0a (ιδίως 767-768 η αξίωση, 779-788 η σταθερή απόδοση/διαπιστευτήριο)"
   :is-it-in-the-known-defect-list :unknown))

 :hidden-execution-paths
 ((:path "run-fetch-command → uiop:run-program (/bin/sh -c COMMAND) με ΠΛΗΡΕΣ posix-environ"
   :trigger "fetch-pdf με fetch-command από ρύθμιση πηγής"
   :why-hidden "Αυθαίρετη εκτέλεση shell από δεδομένο ρύθμισης, μέσα σε module που αλλού διαφημίζει «pure Lisp»· το περιβάλλον κληρονομείται ΟΛΟΚΛΗΡΟ (sb-ext:posix-environ)."
   :evidence "source/document-fetch.lisp:L92-L106@sha256:bb114b83fd80 source/document-fetch.lisp:L308-L323@sha256:bb114b83fd80")
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
   :evidence "source/proof-carrying.lisp:L143-L155@sha256:c18f7ddb07b1 source/proof-carrying.lisp:L168-L183@sha256:c18f7ddb07b1")
  (:path "deterministic-time: (eval-when (:load-toplevel :execute) (initialize-from-environment))"
   :trigger "Απλή φόρτωση του αρχείου με SOURCE_DATE_EPOCH στο περιβάλλον"
   :why-hidden "Το LOAD του module ΜΕΤΑΛΛΑΣΣΕΙ global κατάσταση χρόνου ΚΑΙ τυπώνει στο stdout — καμία ρητή κλήση από κανέναν."
   :evidence "source/deterministic-time.lisp:L202-L220@sha256:6dbda9c2fc1c")
  (:path "journal *ephemeral* = defvar από LAWMAX_REPLICA στο LOAD"
   :trigger "env var κατά τη φόρτωση"
   :why-hidden "Ολόκληρη η durability του συστήματος αλλάζει από env var που διαβάζεται ΜΙΑ φορά, σε defvar· καμία μεταγενέστερη αλλαγή δεν έχει αποτέλεσμα, και το receipt γίνεται :ephemeral-replica που το require-durable! ΔΕΧΕΤΑΙ ως έγκυρο."
   :evidence "source/journal.lisp:L180-L187@sha256:ee440c102989 source/journal.lisp:L347-L349@sha256:ee440c102989")
  (:path "constitutional-gate: LAWMAX_OVERRIDE / LAWMAX_OVERRIDE_REASON"
   :trigger "env vars της διεργασίας"
   :why-hidden "Πλήρης παράκαμψη του «υπέρτατου φραγμού» χωρίς άγγιγμα κώδικα ή CLI."
   :evidence "source/constitutional-gate.lisp:L59-L65@sha256:33522d186e21")
  (:path "journal *clock-override* και *fsync-fault* — TEST-ONLY ένεση σε παραγωγικό image"
   :trigger "setf/dynamic bind των ειδικών μεταβλητών"
   :why-hidden "Δηλωμένα «ΠΟΤΕ σε παραγωγικό μονοπάτι» αλλά υπαρκτά και εξαγόμενα στο παραγωγικό package: το ένα ψεύδεται για τον χρόνο, το άλλο για την durability."
   :evidence "source/journal.lisp:L45-L48@sha256:ee440c102989 source/journal.lisp:L210-L213@sha256:ee440c102989")
  (:path "cognition: register-classifier / *advisor* — αυθαίρετα κλεισίματα σε global λίστα"
   :trigger "Οποιοδήποτε φορτωμένο module"
   :why-hidden "Τα κλεισίματα τρέχουν μέσα στο decompose υπό ignore-errors — κώδικας που εκτελείται στο trusted μονοπάτι χωρίς μητρώο/έλεγχο."
   :evidence "source/cognition.lisp:L69-L89@sha256:f54ace6cb73d")
  (:path "anomaly-detection / ast-gate → (apply (find-symbol \"…\" :orchestrator.consolidation) args)"
   :trigger "Κάθε κλήση των %legal-document-provisions/%provision-text/…"
   :why-hidden "Τα ονόματα δένονται ΩΣ STRINGS σε macrolet-παραγόμενες συναρτήσεις· καμία στατική εξάρτηση, καμία ένδειξη αν το πακέτο δεν φορτώθηκε."
   :evidence "source/anomaly-detection.lisp:L24-L31@sha256:43c44bf86b01 · source/ast-gate.lisp:L40-L47@sha256:65724a01525c")
  (:path "amendment-extractor %ngz → find-symbol NORMALIZE-GREEK σε :orchestrator.legal-id"
   :trigger "Κάθε %all-quoted-spans/%segment-starts"
   :why-hidden "Δυναμική επίλυση χωρίς έλεγχο· η ΜΙΑ έδρα δρομολόγησης εισάγεται με string lookup."
   :evidence "source/amendment-extractor.lisp:L189-L199@sha256:407642a40548")
  (:path "pdf-authority → uiop:run-program (\"which\"…, \"pdftoppm\"…, \"tesseract\"…)"
   :trigger "extract-text-any όταν το text layer έχει < 600 χαρακτήρες"
   :why-hidden "Αυτόματη κλιμάκωση σε ΤΡΕΙΣ εξωτερικές διεργασίες + εγγραφή σε προβλέψιμο /tmp path, ενεργοποιούμενη από ένα κατώφλι μήκους κειμένου."
   :evidence "source/pdf-authority.lisp:L1386-L1439@sha256:c4e2054c0e4f")
  (:path "pdf-authority: lazy CFFI load-poppler-libraries με *poppler-load-attempted* latch"
   :trigger "Πρώτη κλήση οποιασδήποτε PDF λειτουργίας"
   :why-hidden "Μία αποτυχία φόρτωσης ΚΛΕΙΔΩΝΕΙ μόνιμα τη διεργασία σε «μη διαθέσιμο» (το latch δεν καθαρίζεται) — παροδικό σφάλμα γίνεται μόνιμη υποβάθμιση, με μόνο log:warn."
   :evidence "source/pdf-authority.lisp:L139-L174@sha256:c4e2054c0e4f")
  (:path "extract-pdf-text → extract-text-fallback (regex «PDF parser»)"
   :trigger "prefer-poppler NIL ή μη φορτωμένη poppler"
   :why-hidden "Δεύτερη, κρυφή διαδρομή ανάγνωσης PDF που παράγει αποσπασματικό κείμενο με regex πάνω σε latin-1 bytes και μόνο (warn) — ενώ η δηλωμένη ΜΙΑ έδρα είναι η extract-text-any."
   :evidence "source/pdf-authority.lisp:L904-L964@sha256:c4e2054c0e4f vs 1427-1439")
  (:path "instrument-kind-entries / scope-dimension-entries: ΜΟΝΙΜΟ closure cache"
   :trigger "Πρώτη ανάγνωση των μητρώων deployment/data/*.sexp"
   :why-hidden "(let ((cache nil)) …) — το μητρώο διαβάζεται ΜΙΑ φορά ανά διεργασία· αλλαγή του αρχείου δεν γίνεται ποτέ ορατή, χωρίς invalidation ή δήλωση."
   :evidence "source/version-graph.lisp:L1497-L1531@sha256:d6b181de2ad1 source/version-graph.lisp:L1557-L1591@sha256:d6b181de2ad1")
  (:path "*scope-assumptions* — δυναμική μεταβλητή που μεταφέρει «υποθέσεις» έξω από την επιστροφή"
   :trigger "version-at με :scope-mode :conservative και scope-covers-p = :unknown"
   :why-hidden "Πλευρικό κανάλι: ένα pushnew μέσα σε φιλτράρισμα καθορίζει αν το αποτέλεσμα θα σημανθεί analytical-not-authoritative· η σήμανση εξαρτάται από τη ΣΕΙΡΑ αποτίμησης των κατηγορημάτων."
   :evidence "source/version-graph.lisp:L193-L195@sha256:d6b181de2ad1 source/version-graph.lisp:L1020-L1028@sha256:d6b181de2ad1 source/version-graph.lisp:L2137-L2162@sha256:d6b181de2ad1")
  (:path "blockchain-authority.lisp → (initialize-from-environment) σε load-toplevel"
   :trigger "ΑΠΛΗ ΦΟΡΤΩΣΗ του αρχείου — καμία κλήση, καμία απόφαση, κανένα gate"
   :why-hidden "Πέντε μεταβλητές περιβάλλοντος (ETHEREUM_RPC_URL, ETHEREUM_PRIVATE_KEY, ETHEREUM_CHAIN_ID, ARWEAVE_WALLET_PATH, IPFS_API_URL) μεταβάλλουν ΚΑΤΑ ΤΗ ΦΟΡΤΩΣΗ αν το σύστημα θα αγκυρώνει σε αλυσίδα ή θα σιωπά, ΚΑΙ εισάγουν ΙΔΙΩΤΙΚΟ ΚΛΕΙΔΙ στην εικόνα. Δεν καταγράφεται σε journal, δεν εκπέμπεται receipt, δεν αναφέρεται σε κανένα capability report. Κακοσχηματισμένο ETHEREUM_CHAIN_ID γίνεται (warn) και η μεταβλητή μένει στην προηγούμενη τιμή."
   :evidence "source/blockchain-authority.lisp:L951-L972@sha256:caadc9c75a98")
  (:path "legal-ast: τοπικός ορισμός when-let που ΣΚΙΑΖΕΙ τη σύμβαση της alexandria"
   :trigger "Οποιοσδήποτε γράψει (when-let ((a x) (b y)) …) μέσα στο orchestrator.legal-ast"
   :why-hidden "Το ίδιο όνομα, το ίδιο docstring-συμβόλαιο, ΔΙΑΦΟΡΕΤΙΚΗ σημασιολογία: τα bindings πέραν του πρώτου εξαφανίζονται· η αναφορά στο body γίνεται unbound variable αντί για «όλα non-nil»."
   :evidence "source/legal-ast.lisp:L2138-L2148@sha256:3735c7d8e763")
  (:path ":guard-ops — πακέτο ΓΝΩΣΗΣ (δεδομένα) που ΕΠΕΚΤΕΙΝΕΙ ΤΗ ΓΛΩΣΣΑ των φραγμών"
   :trigger "Φόρτωση πακέτου γνώσης είδους :guard-ops· κάθε entry (:op όνομα (παράμετροι) σώμα) περνά στο define-derived"
   :why-hidden "Το ΣΩΜΑ του νέου τελεστή είναι ΔΕΔΟΜΕΝΟ από αρχείο πακέτου και γίνεται εκτελέσιμος τελεστής του μετακυκλικού αποτιμητή που παράγει τα πιστοποιητικά των αποδείξεων. Ο αποτιμητής απαγορεύει επανορισμό ΠΡΩΤΟΓΕΝΟΥΣ και δεσμευμένης ειδικής μορφής, αλλά η επιφάνεια «δεδομένα → γλώσσα απόδειξης» υπάρχει και δεν φαίνεται σε κανένα call graph."
   :evidence "source/guard-ops-pack.lisp:L15-L31@sha256:6c3c38bd1d0c · source/guard-metaeval.lisp:L216-L228@sha256:6c11b3a60282 (οι φρουροί του define-derived)")
  (:path "orchestrator.protocols — 40 defgeneric χωρίς καμία μέθοδο, φορτωμένα στην εικόνα"
   :trigger "Φόρτωση του orchestrator-infrastructure (asd:188)"
   :why-hidden "Καταλαμβάνουν ΟΝΟΜΑΤΑ εννοιών που έχουν πραγματικές έδρες αλλού (compute-hash, resolve-path, log-audit-event, circuit-breaker-state, validate-data). Μια κλήση δεν αποτυγχάνει «δεν υπάρχει» αλλά με no-applicable-method, και ένα (defmethod compute-hash …) οπουδήποτε θα προσαρτούσε σιωπηλά συμπεριφορά σε αυτή τη ΣΚΙΩΔΗ έδρα αντί για τη δηλωμένη."
   :evidence "protocols.lisp:1-263 · orchestrator-infrastructure.asd:L188-L188@sha256:eafe37e8517f · source/hash-authority.lisp:L11-L46@sha256:280a7c5bb315 (η πραγματική έδρα)")
  (:path "define-noun στο load-toplevel καλεί orchestrator.citation-authority:add-lemma-forms"
   :trigger "Φόρτωση του generation.lisp — 15 κλήσεις define-noun στις γραμμές 175-189"
   :why-hidden "Η ΦΟΡΤΩΣΗ ενός αρχείου γένεσης λόγου ΜΕΤΑΒΑΛΛΕΙ το λεξικό ΚΑΤΑΝΟΗΣΗΣ ενός άλλου πακέτου (citation-authority), με 6 μορφές ανά λήμμα. Διασταυρούμενη μεταβολή κατάστασης μεταξύ πακέτων τη στιγμή του load, χωρίς gate ή receipt."
   :evidence "source/generation.lisp:L50-L63@sha256:e92ce44484e9 source/generation.lisp:L175-L189@sha256:e92ce44484e9 · 215-227 (η ίδια πόρτα ανοιχτή σε πακέτα γνώσης)")
  (:path "orchestrator.knowledge:*resolvers* — abduction που ΚΑΛΕΙ αυθαίρετη συνάρτηση και εισάγει το αποτέλεσμά της ως ΠΡΟΚΕΙΜΕΝΟ"
   :trigger "plan-goal → %acquire, όταν ένας ground υπο-στόχος δεν παράγεται από κανόνα"
   :why-hidden "Δεν φαίνεται σε κανένα call graph: η συνάρτηση καταχωρείται δυναμικά από τον καλούντα και εκτελείται στο μέσο του σχεδιασμού απόδειξης. Τα «αποκτημένα» γεγονότα μπαίνουν αδιάκριτα δίπλα στα δοθέντα και η έξοδος λέει «✓ Το απέδειξα»."
   :evidence "source/legal-knowledge.lisp:L148-L154@sha256:d0c50f4e981e source/legal-knowledge.lisp:L168-L174@sha256:d0c50f4e981e source/legal-knowledge.lisp:L260-L277@sha256:d0c50f4e981e")
  (:path "signed-embedding-manifest → embeddings-authority:embed-via-openai → δίκτυο OpenAI, και το αποτέλεσμα ΥΠΟΓΡΑΦΕΤΑΙ με JWS"
   :trigger "create-embedding-manifest χωρίς :pre-computed-vector"
   :why-hidden "Μη ντετερμινιστικό, εξωτερικό, δικτυακό περιεχόμενο αποκτά κρυπτογραφική σφραγίδα προέλευσης, ORCID πραγματικού προσώπου και άδεια CC-BY, και εκπέμπεται ως emb:SignedEmbedding. Η υπογραφή βεβαιώνει ακεραιότητα, ποτέ ορθότητα· τίποτα στο artifact δεν δηλώνει ότι το διάνυσμα προήλθε από τρίτο πάροχο."
   :evidence "source/signed-embedding-manifest.lisp:L158-L161@sha256:b66e205e29a5 source/signed-embedding-manifest.lisp:L68-L79@sha256:b66e205e29a5 source/signed-embedding-manifest.lisp:L186-L186@sha256:b66e205e29a5 · source/embeddings-authority.lisp:L99-L148@sha256:0f08cd969fc6")
  (:path "source-profile: ΟΛΟΙ οι backends ενώνονται μέσω find-symbol σε πακέτα που μπορεί να λείπουν"
   :trigger "default-source-profiles / make-consensus-source σε εικόνα χωρίς orchestrator.gov-source, orchestrator.eu-interop, orchestrator.ingestion ή drakma"
   :why-hidden "Το κανάλι δεν σφάλλει — γίνεται απλώς ΜΗ ΔΙΑΘΕΣΙΜΟ και εξαφανίζεται από τη συναίνεση χωρίς μήνυμα. Η στοίβα απόκτησης μπορεί να συρρικνωθεί σε ένα μόνο κανάλι από απούσα εξάρτηση, και το αποτέλεσμα σημαίνεται :sole ⇒ TRUSTED."
   :evidence "source/source-profile.lisp:L415-L432@sha256:3a7df8a07d26 source/source-profile.lisp:L447-L458@sha256:3a7df8a07d26 source/source-profile.lisp:L462-L468@sha256:3a7df8a07d26 source/source-profile.lisp:L473-L481@sha256:3a7df8a07d26 source/source-profile.lisp:L487-L493@sha256:3a7df8a07d26 · 529-535 · 263-270,345-353")
  (:path "legal-extraction-verify V1 → (funcall (find-symbol \"NODE\" :orchestrator.graph) …) χωρίς έλεγχο NIL"
   :trigger "verify-proposal με :graph, σε εικόνα όπου το πακέτο/σύμβολο λείπει"
   :why-hidden "Η ΠΥΛΗ του μη-έμπιστου συμβούλου ματαιώνεται με ΩΜΟ σφάλμα funcall-NIL αντί για δηλωμένη απόρριψη· το verify-and-register δεν καταχωρεί, αλλά ο καλών δεν λαμβάνει verdict με λόγους."
   :evidence "source/legal-extraction-verify.lisp:L348-L355@sha256:d03e8fa588fd")
  (:path "orchestrator.protocols + MOP-ανακάλυψη κανόνων ⇒ ΜΗ ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ ΕΠΙΛΟΓΗ ΑΠΟΔΕΙΞΗΣ"
   :trigger "plan-goal/pursue/think σε οποιοδήποτε ερώτημα που κλείνει με ≥2 κανόνες"
   :why-hidden "Το all-legal-rules παράγει τη λίστα κανόνων από sb-mop:class-direct-subclasses, του οποίου η σειρά αδελφών είναι απροσδιόριστη· το plan-goal κρατά τον ΠΡΩΤΟ κανόνα που κλείνει. Η ΤΙΜΗ ΑΛΗΘΕΙΑΣ είναι σταθερή (well-founded fixpoint), αλλά η ΑΠΟΔΕΙΞΗ που παρουσιάζεται στον άνθρωπο μπορεί να διαφέρει μεταξύ εικόνων για το ίδιο ερώτημα και τα ίδια δεδομένα."
   :evidence "source/legal-inference-engine.lisp:L514-L520@sha256:947062df7119 · source/legal-knowledge.lisp:L190-L207@sha256:d0c50f4e981e source/legal-knowledge.lisp:L32-L35@sha256:d0c50f4e981e"))

 :duplicate-seats
 ((:concept "«χρόνος για δημοσιευμένο artifact»"
   :seats ("source/deterministic-time.lisp:L164-L176@sha256:6dbda9c2fc1c (require-deterministic-time — fail-closed)"
           "source/deterministic-time.lisp:L129-L162@sha256:6dbda9c2fc1c (now :source :deterministic — σιωπηλό fallback)"
           "source/deterministic-time.lisp:L84-L119@sha256:6dbda9c2fc1c (get-current-timestamp/get-unix-timestamp/get-iso8601)"
           "source/journal.lisp:L50-L59@sha256:ee440c102989 (iso-now — δικό του ρολόι, get-universal-time, ΑΝΕΞΑΡΤΗΤΟ από το deterministic mode)"))
  (:concept "canonical sexp serialization"
   :seats ("source/safe-read.lisp:L312-L339@sha256:590133b311d0 (data-to-string)"
           "source/journal.lisp:L61-L86@sha256:ee440c102989 (canon-sexp)"
           "source/journal.lisp:L399-L402@sha256:ee440c102989 (format ~S με ειδικά print bindings — ΤΡΙΤΗ παραλλαγή στην ίδια έδρα εγγραφής)"))
  (:concept "ανάγνωση sexp δεδομένων"
   :seats ("source/safe-read.lisp:L275-L308@sha256:590133b311d0 (η δηλωμένη ΜΙΑ έδρα)"
           "source/journal.lisp:L265-L292@sha256:ee440c102989 (%load-lines — δικός του tolerant read loop με *read-eval* nil, ΧΩΡΙΣ #-deny/caps/%data-only-p· ρητά εξαιρεμένος στο source/safe-read.lisp:L32-L32@sha256:590133b311d0)"
           "source/journal.lisp:L352-L361@sha256:ee440c102989 (%validate-serializable — read-from-string, ΤΡΙΤΟΣ reader)"))
  (:concept "canonical sexp της ΑΞΙΑΣ (value-canonical)"
   :seats ("source/journal.lisp:L61-L86@sha256:ee440c102989 (canon-sexp — δηλωμένη ΜΙΑ έδρα)"
           "source/version-graph.lisp:L471-L497@sha256:d6b181de2ad1 (%canon-sexp — ΠΑΝΟΜΟΙΟΤΥΠΟ αντίγραφο, ενώ το journal δηλώνει ότι το version-graph «deleg.»)"))
  (:concept "ταυτότητα εγγραφής (record identity hashing)"
   :seats ("source/version-graph.lisp:L288-L300@sha256:d6b181de2ad1 (%version-hash-2 → canonical-representation:canonical-hash / canonical JSON)"
           "source/version-graph.lisp:L1727-L1729@sha256:d6b181de2ad1 (condition id → journal:sha256-hex ∘ %canon-sexp / canonical sexp)"
           "source/version-graph.lisp:L2096-L2104@sha256:d6b181de2ad1 (%regime-hash — canonical sexp)"
           "source/adoption-decision.lisp:L90-L94@sha256:fd26b0d91f89 (prin1-to-string + ironclad απευθείας — ΤΡΙΤΟ σχήμα)"))
  (:concept "«η ΜΙΑ ανάγνωση PDF εγγράφου»"
   :seats ("source/pdf-authority.lisp:L1427-L1439@sha256:c4e2054c0e4f (extract-text-any — δηλωμένη η ΜΙΑ)"
           "source/pdf-authority.lisp:L944-L964@sha256:c4e2054c0e4f (extract-pdf-text — δεύτερη ενιαία είσοδος με fallback)"
           "source/pdf-authority.lisp:L381-L446@sha256:c4e2054c0e4f / 508-537 / 658-697 (τρεις παράλληλες πλήρεις διαδρομές εξαγωγής, καθεμία με δικό της άνοιγμα εγγράφου)"))
  (:concept "εξερχόμενη HTTP λήψη"
   :seats ("source/document-fetch.lisp:L258-L291@sha256:bb114b83fd80 (%fetch-url-to-file — SSRF φρουρός ανά hop, :redirect nil)"
           "source/archive-authority.lisp:L70-L94@sha256:36f78fe7b609 (drakma:http-request :redirect 10 — ΚΑΝΕΝΑΣ φρουρός)"))
  (:concept "generic content hash"
   :seats ("source/hash-authority.lisp:L11-L46@sha256:280a7c5bb315 (compute-hash — δηλωμένη έδρα γενικού hash)"
           "source/journal.lisp:L88-L92@sha256:ee440c102989 (sha256-hex — δεύτερη γενική έδρα, ironclad απευθείας)"
           "source/adoption-decision.lisp:L91-L94@sha256:fd26b0d91f89 και 128-131 (ironclad απευθείας, τρίτη)"
           "source/canonical-representation.lisp:L338-L342@sha256:a72286188ff9 (generate-manifest-id — ironclad απευθείας, ΕΝΩ το ίδιο αρχείο αλλού χρησιμοποιεί hash:compute-hash)"))
  (:concept "«ώρα δημιουργίας/υποβολής» μέσα στο ίδιο αρχείο"
   :seats ("source/archive-authority.lisp:L87-L87@sha256:36f78fe7b609 ((get-universal-time))"
           "source/archive-authority.lisp:L131-L132@sha256:36f78fe7b609 (orchestrator.time:now :source :system)"))
  (:concept "modular multiplicative inverse (εκτεταμένος Ευκλείδης) σε μονοπάτι υπογραφής"
   :seats ("source/jws-authority.lisp:L711-L711@sha256:0d57d11e3cf7 (mod-inverse — RSA CRT qinv, source/jws-authority.lisp:L697-L697@sha256:0d57d11e3cf7)"
           "source/blockchain-authority.lisp:L259-L269@sha256:caadc9c75a98 (mod-inverse — secp256k1 point add/double/ecrecover, L306,L312,L351)"))
  (:concept "when-let"
   :seats ("source/legal-ast.lisp:L2138-L2148@sha256:3735c7d8e763 (τοπικός ορισμός, ΜΟΝΟ πρώτο binding)"
           "alexandria:when-let (σε ενεργή χρήση στο ίδιο repo: source/blockchain-authority.lisp:L953-L971@sha256:caadc9c75a98)"))
  (:concept "JSON string escaping"
   :seats ("source/json-emit.lisp:L39-L58@sha256:5f1b1b7d8d91 (Η ΔΗΛΩΜΕΝΗ ΕΔΡΑ — ολική write-json-value)"
           "orchestrator.spec:json-string-escape (καταναλώνεται από source/corpus-intelligence.lisp:L206-L206@sha256:56ef2b5920c8, source/citation-authority.lisp:L716-L716@sha256:f4ad0fd3855e)"
           "source/legal-qa.lisp:L95-L106@sha256:8c10f4e56920 (ορθό)" "source/ai-corpus-dump.lisp:L40-L50@sha256:b1d9f34c24ae (ορθό)"
           "source/review-service.lisp:L190-L204@sha256:7e0378ae7c28 (ορθό)" "source/mcp-server.lisp:L41-L53@sha256:084246b54052 (ορθό)"
           "source/corpus-eu-links.lisp:L113-L121@sha256:63fb33b5c39b (ΑΚΥΡΟ JSON σε control chars)"
           "source/government-source.lisp:L239-L250@sha256:1b747a0bcb7a (ΑΚΥΡΟ)" "source/corpus-diff.lisp:L36-L44@sha256:b69bdbac9560 (ΑΚΥΡΟ)"
           "source/corpus-search.lisp:L70-L78@sha256:8effbaf5f62f (ΑΚΥΡΟ)"
           "source/corpus-sparql.lisp:L102-L104@sha256:8b1997dd98b1 (inline (substitute #\\Space #\\\"))"))
  (:concept "σύγκριση/αριθμητική νομικών ημερομηνιών"
   :seats ("source/legal-temporal.lisp:L28-L53@sha256:74ec15418b7c (date-plus-days/date</date<= — λεξικογραφικά, αξιώνει «η ΜΙΑ έδρα»)"
           "source/guard-metaeval.lisp:L652-L666@sha256:6c11b3a60282 (DATE</DATE<=/DATE>/DATE>=/DAYS-BETWEEN/WITHIN-DAYS/ΕΡΓΑΣΙΜΗ-P — αριθμητικά μέσω ymd->day)"
           "version-graph.lisp legal-date-p/%time-key (typed έδρα στην οποία τα άλλα δύο ΑΝΑΘΕΤΟΥΝ με σχόλιο)"))
  (:concept "Turtle literal escaping"
   :seats ("source/legal-hypergraph.lisp:L46-L62@sha256:a5eeb778d594 (%ttl-lit — \", \\\\, \\n, \\r, \\t)"
           "source/greek-legislation-ontology.lisp:L208-L212@sha256:f6c6abee3574 (%ttl-esc — ΧΩΡΙΣ \\r, ΧΩΡΙΣ \\t)"))
  (:concept "«ανάλυση επίπτωσης άρθρου»"
   :seats ("source/legal-reasoning-bridge.lisp:L96-L170@sha256:ba8a680fbe54 (grounded-impact — διτεμπορικά θεμελιωμένη, receipts)"
           "source/legal-reasoning-bridge.lisp:L69-L89@sha256:ba8a680fbe54 source/legal-reasoning-bridge.lisp:L172-L181@sha256:ba8a680fbe54 (reason-impact/impact-report — αθεμελίωτη, εξαγόμενη)"
           "source/graph-reasoning.lisp:L54-L90@sha256:81d3b4593cdd (impact πάνω στον ενιαίο γράφο — τρίτη, διαφορετικό υπόστρωμα)"))
  (:concept "compute-hash (γενικό hash ως ΟΝΟΜΑ έδρας)"
   :seats ("source/hash-authority.lisp:L11-L46@sha256:280a7c5bb315 (η δηλωμένη έδρα)"
           "protocols.lisp:145-149 (defgeneric compute-hash/verify-hash/supported-hash-types — ΜΗΔΕΝ μέθοδοι)"))
  (:concept "εγκατάσταση πακέτου γνώσης (ατομικότητα)"
   :seats ("source/guard-ops-pack.lisp:L17-L29@sha256:6c3c38bd1d0c (copy-on-write + ατομική δημοσίευση)"
           "source/legal-strategy.lisp:L32-L41@sha256:1268e149217a (in-place setf καθολικού ανά entry)"
           "source/generation.lisp:L215-L227@sha256:e92ce44484e9 → 50-63 (γράψιμο πριν την επικύρωση, χωρίς rollback)"))
  (:concept "generate-rdf (defgeneric)"
   :seats ("protocols.lisp:56 ((object &key format) — 0 μέθοδοι)"
           "systems/orchestrator-omega-modules/frbr-protocol.lisp:L11-L11@sha256:15edc8b34f1b ((frbr-instance) — 12 μέθοδοι, ΑΣΥΜΒΑΤΗ lambda-list)"))
  (:concept "Turtle literal escaping (πλήρης απαρίθμηση εδρών)"
   :seats ("source/legal-hypergraph.lisp:L46-L62@sha256:a5eeb778d594 (%ttl-lit — αυτοδηλωμένο «single choke point»)"
           "source/greek-legislation-ontology.lisp:L208-L212@sha256:f6c6abee3574 (%ttl-esc — χωρίς \\r/\\t)"
           "source/shacl-validator.lisp:L311-L323@sha256:a0339815440c (%ttl-str — πλήρες)"
           "source/signed-embedding-manifest.lisp:L383-L396@sha256:b66e205e29a5 (%ttl-lit — πλήρες)"))
  (:concept "κλάση ελληνικών χαρακτήρων για regex"
   :seats ("source/legal-references.lisp:L39-L42@sha256:d5c1a0763803 (+gl+ — U+0370-U+03FF, U+1F00-U+1FFF)"
           "source/corpus-eu-links.lisp:L27-L27@sha256:63fb33b5c39b (+gl+ — ρητή απαρίθμηση)"
           "source/embeddings-authority.lisp:L286-L286@sha256:0f08cd969fc6 (κλάση εντός tokenize)"
           "source/legal-penalty.lisp:L65-L65@sha256:7ea6f2047ce9 (*num-token*)"
           "source/text-canonicalizer.lisp:L313-L313@sha256:747fad14d692 source/text-canonicalizer.lisp:L318-L318@sha256:747fad14d692 source/text-canonicalizer.lisp:L324-L324@sha256:747fad14d692 source/text-canonicalizer.lisp:L330-L330@sha256:747fad14d692 (τέσσερα διαφορετικά εύρη ανά μοτίβο)"))
  (:concept "«συναίνεση/επιβεβαίωση περιεχομένου μεταξύ πηγών»"
   :seats ("source/source-profile.lisp:L341-L353@sha256:3a7df8a07d26 (content-hash του %canonical — και για κατάλογο = όνομα αρχείου)"
           "authority-evidence-replay.lisp (byte-ισοδυναμία πηγή→spans→εξαγωγή→graph-text — πραγματική)"))
  (:concept "αποτίμηση «τι λείπει για να ισχύσει ο κανόνας»"
   :seats ("source/legal-knowledge.lisp:L68-L77@sha256:d0c50f4e981e (satisfy-patterns — greedy, χωρίς οπισθοδρόμηση)"
           "source/legal-deontic.lisp:L113-L141@sha256:3b584b2845ae (apply-norms → match-patterns — ευρετηριασμένο, πλήρες)"))
  (:concept "«επαλήθευση αλυσίδας» με ταυτολογικό (every #'cdr checks)"
   :seats ("source/narrative-provenance.lisp:L907-L930@sha256:bb5aaa7b01a0 (verify-provenance-chain)"
           "source/semantic-authority.lisp:L730-L754@sha256:3b7ab18ddb0a (verify-authority-chain)"))
  (:concept "κλείσιμο RDFS (apply-rdfs-rules + βρόχος fixpoint)"
   :seats ("source/rdfs-inference.lisp:L283-L431@sha256:cc47768ad655 (apply-rdfs2..11 + apply-rdfs-rules + run-inference, max 100)"
           "source/reasoning-authority.lisp:L417-L480@sha256:c4da9cef6085 (apply-rdfs-rules + compute-closure, max 1000, «not yet loaded by any .asd»)"))
  (:concept "σιωπηλό fallback ρίζας RDF namespace"
   :seats ("source/ai-ingest-manifest.lisp:L30-L38@sha256:60194efad04d (ΚΛΕΙΣΤΗΚΕ: ονομασμένη σταθερά +institution-vocabulary-base+)"
           "source/narrative-provenance.lisp:L32-L34@sha256:bb5aaa7b01a0 source/narrative-provenance.lisp:L76-L76@sha256:bb5aaa7b01a0 (ανοιχτό)"
           "source/ai-citation-strategy.lisp:L31-L33@sha256:af9cd72d5bf2 source/ai-citation-strategy.lisp:L389-L389@sha256:af9cd72d5bf2 (ανοιχτό)"
           "source/semantic-versioning-system.lisp:L43-L43@sha256:14fe14638ea7 (ανοιχτό)"))
  (:concept "μη-κρυπτογραφικό (random …) σε ταυτότητα/αναγνωριστικό"
   :seats ("source/legal-audit-system.lisp:L780-L787@sha256:53613cdd00f0 (generate-uuid του audit trail)"
           "source/eu-interop-layer.lisp:L381-L387@sha256:a3807069a264 (generate-did για εγγραφή στο EBSI)"))
  (:concept "HTML escaping"
   :seats ("source/static-site.lisp:L61-L68@sha256:7493c7a7dc89 (%esc — πλήρες)"
           "source/akoma-ntoso-emitter.lisp:L46-L63@sha256:650a0e0fe875 (xml-text-escape/xml-attr-escape — μερικό, XML)"
           "source/sparql-endpoint.lisp:L576-L600@sha256:8528099d891a (results-to-xml — ΚΑΜΙΑ διαφυγή)"))
  (:concept "μηχανή συμπερασμού πάνω σε γεγονότα"
   :seats ("legal-inference-engine.lisp (JTMS + Van Gelder alternating fixpoint — η δηλωμένη έδρα)"
           "rdfs-inference.lisp (forward-chaining RDFS πάνω σε triples)"
           "reasoning-authority.lisp (OWL-RL/RDFS, τρίτη)"
           "guard-metaeval.lisp (μετακυκλικός αποτιμητής φραγμών, τέταρτη σημασιολογία)")))

 :unknowns
 ("Ποιος θέτει το *advisor* και με ποιο μοντέλο — δεν βρίσκεται στα αρχεία που διάβασα."
  "Ποιος καλεί το orchestrator.constitution:evaluate και αν η μεσολάβηση είναι πράγματι καθολική."
  "Αν το fetch-command προέρχεται από αρχείο ρύθμισης ελεγχόμενο από τον operator ή από corpus δεδομένα.")

 :remaining ()   ; ΟΛΑ τα 133 αρχεία του /frozen/ro/source διαβάστηκαν
 :note-on-completion
 "ΟΛΑ τα 133 .lisp του /frozen/ro/source διαβάστηκαν. Κάθε ισχυρισμός φέρει άγκυρα path:Lx-Ly.
  Οι ικανότητες που δεν είχαν και τα 7 πεδία με τεκμήριο ΔΕΝ γράφτηκαν ως :present.
  Οι κρίσεις ignore-errors είναι ονομαστικές μέσα στα :defects (σιωπηλή κατάποση vs
  δηλωμένη τίμια άγνοια με ρητή επιστροφή NIL που ο καλών ΥΠΟΧΡΕΟΥΤΑΙ να ελέγξει).")
