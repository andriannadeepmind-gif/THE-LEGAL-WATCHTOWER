(:lawmax-phase1a-cluster/1
 :cluster "authority-v2"
 :status :partial
 :files-read 11
 :frozen-mount "/frozen/ro/authority-v2  (commit e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03)"
 :file-inventory-note
 "find -type f κάτω από /frozen/ro/authority-v2 δίνει 61 regular files (όχι 63 όπως
  λέει η ανάθεση). Αναλυτικά: 2 στη ρίζα (LEVEL7-COMPLETION-MATRIX.sexp,
  PROOF-CENSUS.txt) + proof-manifest.sexp + run-all.sh + run-proofs.sh
  + capability/1 + capture/3 + fixtures/8 + genesis/6 + kernel/1 + log/1
  + proofs/15 + roles/2 + schema/2 + store/1 + tests/12 + toolchain/3."

 :capabilities
 ((:name "OS-enforced write-capability closure (authority/producer/reader uid separation)"
   :presence :present
   :domain "Filesystem DAC στο /var/lib/lawmax/authority και /var/lib/lawmax/candidates"
   :assumptions "root+setpriv+useradd διαθέσιμα κατά την εγκατάσταση· kernel DAC ορθός·
                 καμία διεργασία δεν τρέχει ως root στην παραγωγή· κανένα MAC profile"
   :guarantees "authority store: owner lawmax-authority(11001):lawmax-readers(11010) 0750
                ⇒ μόνος writer· candidates: owner lawmax-producer(11002) 0750·
                reader(11003) read-only και στα δύο· producer ΚΑΜΙΑ πρόσβαση στο store"
   :failure-semantics "identities.sh: exit 1 χωρίς root (L39)· exit 1 αν το καρφωμένο uid
                       είναι πιασμένο από άλλον (L59-61) — καμία σιωπηλή επαναχρήση.
                       verify-capability-closure.sh: exit 2 BLOCKED χωρίς root/setpriv
                       (L26-29), exit 2 αν λείπει ταυτότητα (L30-32), exit 1 σε παραβίαση."
   :operating-model "Δύο ξεχωριστά scripts: εγκαταστάτης (capability/identities.sh) και
                     εκτελεστικός μάρτυρας (proofs/verify-capability-closure.sh). Ο μάρτυρας
                     κάνει ΠΡΑΓΜΑΤΙΚΕΣ εγγραφές ως κάθε uid μέσω setpriv --init-groups."
   :materiality "Είναι η ΜΟΝΗ ικανότητα της συστάδας που επιβάλλεται από OS και όχι από
                 σύμβαση κώδικα· η STORAGE-API τη δηλώνει ως τον φορέα του :single-writer
                 obligation (store/STORAGE-API.sexp:L48-50)."
   :evidence "authority-v2/capability/identities.sh:L28-88 · authority-v2/proofs/verify-capability-closure.sh:L14-86")

  (:name "Καθαρός admission kernel K(old,candidate,evidence,policy)"
   :presence :spec-only
   :domain "Αποδοχή/απόρριψη candidate release"
   :assumptions "totality· καμία I/O, ρολόι, τυχαιότητα· ο χρόνος μπαίνει μόνο ως TSA genTime"
   :guarantees "9 conjuncts όλα αληθή ⇒ Accept· ένα ψευδές ⇒ Reject ΜΕ ΟΛΟΥΣ τους λόγους"
   :failure-semantics "Reject([+reason]) — δηλωμένη ως ολική συνάρτηση, χωρίς τρίτη έξοδο"
   :operating-model "ΔΕΝ υπάρχει εκτελέσιμος κώδικας πουθενά στη συστάδα. Το αρχείο δηλώνει
                     ρητά :implementation-status :specification-only και
                     :implementation-language-target 'F* — ΟΧΙ Common Lisp'."
   :materiality "Είναι η φέρουσα απαίτηση 2 και 4 του matrix· χωρίς αυτήν δεν υπάρχει
                 μηχανή αποδοχής — μόνο περιγραφή της."
   :evidence "authority-v2/kernel/admission-model.sexp:L18-33 (signature/purity/totality) ·
              L38-70 (9 conjuncts) · L74-111 (9 θεωρήματα, όλα :blocked-toolchain) ·
              L20-22 (:specification-only)")

  (:name "Κλειστό CDDL σχήμα transition-certificate (15 δεσμευμένα πεδία)"
   :presence :spec-only
   :domain "Wire format του transition certificate (deterministic CBOR, RFC 8949 §4.2)"
   :assumptions "EverCDDL/EverParse ως ο ΜΟΝΟΣ επικυρωτής· κανένα float· κλειστές maps"
   :guarantees "άγνωστο κλειδί ⇒ απόρριψη κατά το parsing· ΜΟΝΟ pinned TSA (κλειστό literal
                'pinned' στο tsa-evidence key 9)· raw DER request ΚΑΙ response δεσμευμένα"
   :failure-semantics :unknown  ; δεν υπάρχει parser που να υλοποιεί την απόρριψη
   :operating-model "Κείμενο CDDL χωρίς παραγόμενο parser. Κανένα εργαλείο στη συστάδα δεν
                     διαβάζει ή επικυρώνει αυτά τα .cddl αρχεία."
   :materiality "Είναι το μοναδικό μέρος όπου τα 15 πεδία της απαίτησης 4 υπάρχουν όντως·
                 επαληθεύτηκε πεδίο-προς-πεδίο ότι και τα 15 απαριθμούμενα υπάρχουν."
   :evidence "authority-v2/schema/transition-certificate.cddl:L28-129 (prev checkpoint L41-45,
              candidate root L48, census L53-62, source/evidence roots L65-66,
              TSA raw req/resp/nonce/policy/chain/revocation L73-89, profile+predecessor
              L91-100, policy-request L102-105, new state hash L108, log entry L112-115,
              signed checkpoint L116-123, owner/release signature L125-129)")

  (:name "Authority state / rejection certificate σχήμα (unique-latest τυπικά)"
   :presence :spec-only
   :domain "Authoritative state, log state, profile lineage, rejection"
   :assumptions "ίδια με το transition-certificate.cddl"
   :guarantees "latest = null / ΕΝΑ map — δεν υπάρχει σχήμα που να επιτρέπει δεύτερο latest·
                rejection-certificate δεσμεύει state-hash-ΠΡΙΝ ΚΑΙ state-hash-ΜΕΤΑ ώστε η
                ισότητα να είναι ελέγξιμη· profile-link φέρει ed25519 υπογραφή owner root"
   :failure-semantics :unknown
   :operating-model "Κείμενο CDDL· κανένας παραγόμενος parser."
   :materiality "Η unique-latest είναι δομική στο σχήμα (όχι έλεγχος), αλλά χωρίς parser
                 κανείς δεν επιβάλλει το σχήμα."
   :evidence "authority-v2/schema/state.cddl:L18-27 · L29-35 (latest) · L54-63 (profile-lineage)
              · L74-85 (rejection-certificate)")

  (:name "Authority store transactional API (6-item atomic commit)"
   :presence :spec-only
   :domain "Persistence της αποδεκτής μετάβασης"
   :assumptions "Perennial 2.0 / GoTxn υπόστρωμα με απόδειξη — ΑΠΟΝ"
   :guarantees "ΟΛΑ τα έξι στοιχεία ορατά ή κανένα· recovery ΠΡΙΝ ή ΜΕΤΑ, ποτέ υβρίδιο"
   :failure-semantics "production writer :disabled — κάθε κλήση fail-closed (δηλωμένο, όχι
                       επαληθευμένο: δεν υπάρχει κώδικας κλήσης να ελεγχθεί)"
   :operating-model ":implementation-status :absent-by-design — ρητά ΚΑΜΙΑ υλοποίηση πίσω
                     από το interface· :forbidden-substitutes απαριθμεί intent-log/SQLite/
                     atomic-rename ως απαγορευμένα"
   :materiality "Απαίτηση 7· και το :single-writer obligation ανατίθεται στην OS capability."
   :evidence "authority-v2/store/STORAGE-API.sexp:L17-27 · L31-50 · L60-73")

  (:name "Witness quorum/freshness policy (format-agnostic)"
   :presence :spec-only
   :domain "Πολιτική συν-υπογραφής checkpoint από ανεξάρτητους μάρτυρες"
   :assumptions "wire format C2SP :blocked-spec-input — ΚΑΜΙΑ σειριοποίηση δεν υποτίθεται"
   :guarantees "3 υπογραφές από 3 ανεξάρτητους φορείς· κοινό κριτήριο ανεξαρτησίας ⇒ μετρούν
                ως ΕΝΑΣ· checkpoint > 86400s ⇒ απόρριψη· witness lag > 3600s ⇒ απόρριψη"
   :failure-semantics ":enforcement :fail-closed· current-state: κανένας ανεξάρτητος μάρτυρας
                       ⇒ η πύλη είναι ΑΝΕΝΕΡΓΗ (disabled), ρητά ΟΧΙ '0-of-3 ok'"
   :operating-model "Πολιτική σε s-expression· ασκείται από proofs/witness-quorum-test.py
                     (ΔΕΝ έχει ακόμη επαληθευτεί από εμένα αν το test διαβάζει το αρχείο)"
   :materiality ":split-view-resistance-claim nil — ρητή άρνηση ισχυρισμού."
   :evidence "authority-v2/log/witness-policy.sexp:L19-28 · L47-59 · L62-69 · L72-78")

  (:name "TUF-class roles model (5 ρόλοι, 1-of-1 offline root)"
   :presence :spec-only
   :domain "Ιεραρχία κλειδιών/ρόλων και υποχρεωτικές άμυνες"
   :assumptions "TUF v1.0.35 κείμενο :blocked-spec-input· :tuf-conformance-claim nil"
   :guarantees "root offline, threshold 1 keyids 1 σήμερα· rotation = self-signed chain·
                revocation = explicit list· 5 mandatory-protections όλες :specified"
   :failure-semantics "stop-point: δημιουργία/χρήση ΠΡΑΓΜΑΤΙΚΟΥ production root key σταματά"
   :operating-model "Μοντέλο σε s-expression· η ceremony.sh το ασκεί (εκκρεμεί επαλήθευση)"
   :materiality "Όλες οι 5 άμυνες φέρουν :status :specified — ΚΑΜΙΑ :implemented."
   :evidence "authority-v2/roles/ROLES-MODEL.sexp:L19-24 · L28-65 · L68-87 · L90-95"))

 :authorities
 ((:name "lawmax-authority (uid 11001)"
   :what-it-can-decide "Ο ΜΟΝΟΣ που γράφει στο authority store"
   :who-can-invoke "όποιος έχει το uid 11001 (setpriv/docker user:)"
   :enforcement :os
   :evidence "authority-v2/capability/identities.sh:L46-48,L76-77 · proofs/verify-capability-closure.sh:L47-53")
  (:name "lawmax-producer (uid 11002)"
   :what-it-can-decide "Γράφει ΜΟΝΟ candidates· EACCES στο authority store"
   :who-can-invoke "uid 11002" :enforcement :os
   :evidence "authority-v2/capability/identities.sh:L47,L80-81 · proofs/verify-capability-closure.sh:L56-61,L70-75")
  (:name "lawmax-reader (uid 11003, ομάδα lawmax-readers 11010)"
   :what-it-can-decide "Διαβάζει authority store και candidates· δεν γράφει πουθενά"
   :who-can-invoke "uid 11003" :enforcement :os
   :evidence "authority-v2/capability/identities.sh:L48-49,L70 · proofs/verify-capability-closure.sh:L62-67,L77-82")
  (:name "owner root role (offline)"
   :what-it-can-decide "Υπογράφει κλειδιά άλλων ρόλων, profile-lineage links, τον εαυτό της σε rotation"
   :who-can-invoke "κάτοχος του root ιδιωτικού κλειδιού — ΔΕΝ υπάρχει production key (stop-point)"
   :enforcement :convention   ; μοντέλο μόνο· καμία εκτελέσιμη επιβολή στη συστάδα (εκκρεμεί ceremony.sh)
   :evidence "authority-v2/roles/ROLES-MODEL.sexp:L28-37 · L90-95")
  (:name "release role"
   :what-it-can-decide "Υπογράφει transition certificates"
   :who-can-invoke "online authority host" :enforcement :convention
   :evidence "authority-v2/roles/ROLES-MODEL.sexp:L39-44 · schema/transition-certificate.cddl:L125-129"))

 :invariants
 ((:statement "unique-latest: το σχήμα δεν επιτρέπει δεύτερο latest (τυπικά, όχι με έλεγχο)"
   :enforced-by "CDDL τύπος latest = null / {…} — ΟΧΙ λίστα"
   :evidence "authority-v2/schema/state.cddl:L29-35")
  (:statement "rejection ⇒ καμία μεταβολή κατάστασης (state-hash ΠΡΙΝ == ΜΕΤΑ)"
   :enforced-by "πεδία 2 και 3 του rejection-certificate — ελέγξιμο από τρίτο"
   :evidence "authority-v2/schema/state.cddl:L74-81")
  (:statement "TSA ΜΟΝΟ pinned — ποτέ unpinned"
   :enforced-by "κλειστό literal 'pinned' ως τιμή του key 9 στο tsa-evidence"
   :evidence "authority-v2/schema/transition-certificate.cddl:L82 · kernel/admission-model.sexp:L58-63")
  (:statement "new.sequence = old.sequence + 1 ΑΚΡΙΒΩΣ, χωρίς κενά"
   :enforced-by "conjunct :sequence-monotonic (προδιαγραφή) + πεδίο 3 του previous-checkpoint"
   :evidence "authority-v2/kernel/admission-model.sexp:L43-44 · schema/transition-certificate.cddl:L44")
  (:statement "τοπικοί fake witnesses ΔΕΝ μετρούν ποτέ στο κβόρουμ"
   :enforced-by ":counts-toward-quorum nil στην πολιτική (δηλωμένο ως ΔΟΜΙΚΟ)"
   :evidence "authority-v2/log/witness-policy.sexp:L72-78"))

 :defects
 ((:what "verify-capability-closure.sh συμπεραίνει ΑΡΝΗΣΗ από ΟΠΟΙΟΔΗΠΟΤΕ μη-μηδενικό exit
          του setpriv/sh, όχι από EACCES ειδικά. Αν το setpriv αποτύχει για άλλο λόγο
          (π.χ. λείπει /bin/sh στο περιβάλλον του χρήστη, nologin shell, σφάλμα --init-groups),
          το script το μετράει ως 'ok producer ⇒ EACCES'. Ο θετικός μάρτυρας καλύπτει μόνο
          την ταυτότητα authority, όχι τις δύο αρνητικές ταυτότητες."
   :severity :p1
   :evidence "authority-v2/proofs/verify-capability-closure.sh:L40-45 (try_write επιστρέφει
              σκέτο exit status, 2>/dev/null) · L56-67 (οι δύο αρνητικοί έλεγχοι) ·
              L47-53 (ο θετικός μάρτυρας υπάρχει ΜΟΝΟ για τον authority)"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Το matrix δίνει ΔΥΟ ΔΙΑΦΟΡΕΤΙΚΟΥΣ αριθμούς για τα ΙΔΙΑ tests χωρίς να συμφιλιώνονται:
          γραμμή 5 (2026-08-01) 'level7-disarm 20/0 · transparency-log 21/0' ενώ γραμμή 12
          (2026-07-31) 'level7-disarm 9/0 · transparency-log 23/0'. Το transparency-log
          ΜΕΙΩΝΕΤΑΙ από 23 σε 21 χωρίς εξήγηση."
   :severity :p2
   :evidence "authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L122 · L246"
   :is-it-in-the-known-defect-list :unknown)
  (:what "Η γραμμή 5 του matrix δηλώνει implementation ΕΚΤΟΣ της συστάδας
          (systems/orchestrator-epistemic/*.lisp) και η γραμμή 12 (tests/*.lisp,
          docker/suite-census.txt). Δεν είναι επαληθεύσιμα από τη συστάδα authority-v2 μόνη."
   :severity :p2
   :evidence "authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L110-112 · L239-243"
   :is-it-in-the-known-defect-list :unknown))

 :hidden-execution-paths ()
 :duplicate-seats
 ((:concept "sha256-digest / ed25519-sig / ed25519-pub / sequence-no / utc-seconds / profile-id
             ορίζονται ΔΥΟ ΦΟΡΕΣ, μία σε κάθε .cddl αρχείο"
   :seats ("authority-v2/schema/transition-certificate.cddl:L20-25"
           "authority-v2/schema/state.cddl:L9-14")))

 :unknowns
 ("Αν τα .cddl διαβάζονται/επικυρώνονται από οποιοδήποτε εργαλείο της συστάδας"
  "Αν το witness-quorum-test.py διαβάζει όντως το witness-policy.sexp ή κωδικοποιεί τη πολιτική ξανά"
  "Αν το ceremony-rehearsal-test.sh ασκεί όντως το ceremony.sh"
  "Όλα τα υπόλοιπα 50 αρχεία")

 :remaining
 ("capture/CAPTURE-PROTOCOL.sexp" "capture/canonical-profile.json" "capture/capture.py"
  "fixtures/genesis-cert-fixture.json" "fixtures/genesis-cert-fixture.sig"
  "fixtures/legacy-authority/REMOVED-attest-release.lisp.txt"
  "fixtures/legacy-tlog/MANIFEST.json" "fixtures/legacy-tlog/REMOVED-tlog-writers.lisp.txt"
  "fixtures/legacy-tlog/tlog-n1.json" "fixtures/legacy-tlog/tlog-n2.json"
  "fixtures/legacy-tlog/tlog-n3.json" "fixtures/test-keys/README.md"
  "fixtures/test-keys/genesis-test-ed25519.pub"
  "genesis/build-adoption-certificate.py" "genesis/conformance-check.py"
  "genesis/genesis-policy.sexp" "genesis/legacy-snapshot.py"
  "genesis/out/legacy-adoption-certificate.unsigned.json" "genesis/out/legacy-conformance.json"
  "genesis/out/legacy-snapshot.json"
  "proofs/capture-adversarial-test.py" "proofs/capture-mountpoint-test.sh"
  "proofs/capture-mutation-witness.py" "proofs/capture-seat-differential-test.sh"
  "proofs/ceremony-rehearsal-test.sh" "proofs/delta23-evidence-bundle.sh"
  "proofs/docker-e2e-test.sh" "proofs/gate-negative-fixtures.py"
  "proofs/producer-os-boundary-test.sh" "proofs/producer-topology-test.py"
  "proofs/proof-census-adversarial-test.py" "proofs/verify-completion-matrix.py"
  "proofs/verify-proof-manifest.py" "proofs/witness-quorum-test.py"
  "roles/ceremony.sh" "run-all.sh" "run-proofs.sh"
  "tests/_mutator.py" "tests/build-authority-core.lisp" "tests/probe-attest-refusal.lisp"
  "tests/probe-candidate-bundle.lisp" "tests/probe-canonical-files.lisp"
  "tests/probe-emit-load-graph.lisp" "tests/probe-frozen-mutants.lisp"
  "tests/probe-load-graph.lisp" "tests/probe-merkle-root-of-files.lisp"
  "tests/probe-producer-real.lisp" "tests/probe-producer-under-uid.lisp"
  "tests/staging-helper.lisp"
  "toolchain/everparse.Dockerfile" "toolchain/perennial.Dockerfile"
  "toolchain/trusted-toolchain-manifest.sexp"))
