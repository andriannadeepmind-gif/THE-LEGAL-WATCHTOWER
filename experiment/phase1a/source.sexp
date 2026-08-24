(:lawmax-phase1a-cluster/1
 :cluster "source"
 :status :partial
 :files-read 13
 :files-total 133
 :read-so-far ("cognition.lisp" "safe-read.lisp" "merkle-authority.lisp" "proof-carrying.lisp"
               "deterministic-time.lisp" "journal.lisp" "self-constitution.lisp" "document-fetch.lisp"
               "constitutional-gate.lisp" "write-authority.lisp" "hash-authority.lisp"
               "institution.lisp" "config.lisp")

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
   :evidence "config.lisp:7-49"))

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
   :evidence "deterministic-time.lisp:202-220"))

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
   :evidence "cognition.lisp:69-89"))

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
           "journal.lisp:352-361 (%validate-serializable — read-from-string, ΤΡΙΤΟΣ reader)")))

 :unknowns
 ("Ποιος θέτει το *advisor* και με ποιο μοντέλο — δεν βρίσκεται στα αρχεία που διάβασα."
  "Ποιος καλεί το orchestrator.constitution:evaluate και αν η μεσολάβηση είναι πράγματι καθολική."
  "Αν το fetch-command προέρχεται από αρχείο ρύθμισης ελεγχόμενο από τον operator ή από corpus δεδομένα.")

 :remaining
 ("adoption-decision.lisp" "ai-citation-strategy.lisp" "ai-corpus-dump.lisp" "ai-ingest-manifest.lisp"
  "akoma-ntoso-emitter.lisp" "amendment-extractor.lisp" "anomaly-detection.lisp" "archive-authority.lisp"
  "asn1-der.lisp" "ast-gate.lisp" "authority-evidence-replay.lisp" "authority-proof-bundle.lisp"
  "autonomy.lisp" "blockchain-authority.lisp" "canonical-representation.lisp" "canonical-uris.lisp"
  "capability-api.lisp" "capability-registry.lisp" "circuit-breaker.lisp" "citation-authority.lisp"
  "component-scan.lisp" "components.lisp" "consolidation-bridge.lisp" "consolidation-engine.lisp"
  "consolidation-feed.lisp" "consolidation-proof.lisp" "contracts.lisp" "corpus-diff.lisp"
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
  "pdf-authority.lisp" "proposals.lisp" "protocols.lisp" "provenance-link.lisp" "rdfs-inference.lisp"
  "reasoning-authority.lisp" "review-queue.lisp" "review-service.lisp" "self-history.lisp" "self-model.lisp"
  "semantic-authority.lisp" "semantic-versioning-system.lisp" "shacl-validator.lisp"
  "signed-embedding-manifest.lisp" "source-profile.lisp" "sparql-endpoint.lisp" "static-site.lisp"
  "text-canonicalizer.lisp" "timestamp-authority.lisp" "trace-core.lisp" "turtle-parser.lisp"
  "typographic-classifier.lisp" "validate-ast.lisp" "validate-layout-graph.lisp"
  "validate-logical-blocks.lisp" "validation-authority.lisp" "version-graph.lisp" "what-if.lisp"
  "x509-authority.lisp"))
