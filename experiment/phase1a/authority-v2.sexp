(:lawmax-phase1a-cluster/1
 :cluster "authority-v2"
 :status :partial
 :files-read 40
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

  (:name "Candidate capture σε ιδιωτικό quarantine (TOCTOU-ανθεκτική, openat2)"
   :presence :present
   :domain "Ανάγνωση εχθρικού candidates/ και παραγωγή αμετάβλητου snapshot + δύο Merkle ριζών"
   :assumptions "Linux ≥ 5.6 (openat2)· απουσία ⇒ ΑΡΝΗΣΗ openat2-unavailable, ποτέ fallback
                 (capture.py:L152-154)· τα golden vectors στο deployment/verify/vectors/merkle/
                 vectors.json είναι αυθεντικά (ΔΕΝ είναι pinned — βλ. defect)"
   :guarantees "ΦΑΣΗ Α αντιγράφει ΧΩΡΙΣ κανένα hash· ΦΑΣΗ Β μετράει ΑΠΟΚΛΕΙΣΤΙΚΑ από το
                quarantine· διασταύρωση (path,size)+total_bytes· δεύτερη πλήρης μέτρηση ΜΕΣΑ
                στην capture() ⇒ fixed-point-violation· σταθεροποίηση ΟΛΟΥ ΤΟΥ ΣΥΝΟΛΟΥ
                (set-mutated-during-capture) ΚΑΙ ανά αρχείο (mutated-during-capture)·
                capability τύποι σφραγισμένοι και μη κατασκευάσιμοι (_MINT)· canonical profile
                pinned by sha256"
   :failure-semantics "CaptureRefused σε ΚΑΘΕ ανωμαλία· κάθε OSError μεταφράζεται σε ελεγχόμενη
                       άρνηση (_ERRNO_REASON)· μερικό quarantine καθαρίζεται και η αποτυχία
                       καθαρισμού είναι ΟΡΑΤΗ (cleanup-incomplete)"
   :operating-model "ΕΚΤΕΛΕΣΙΜΟΣ ΚΩΔΙΚΑΣ (1017 γραμμές Python) — αλλά ταξινομημένος ως `helper`
                     στην απογραφή, δηλαδή ΔΕΝ τρέχει από τον runner και ΔΕΝ είναι απόδειξη·
                     ρητά ΟΧΙ production writer (CAPTURE-PROTOCOL :out-of-scope L169-174)"
   :materiality "Είναι το ΜΟΝΟ ουσιαστικά εκτελέσιμο μέρος της συστάδας που κάνει authority-
                 σχετική δουλειά. Η παραγωγική του έδρα δηλώνεται ως μελλοντικό εξαγόμενο artifact."
   :evidence "authority-v2/capture/capture.py:L143-160 (openat2) · L223-288 (open_anchor) ·
              L317-360 (_Sealed capability types) · L626-657 (pinned profile) ·
              L673-740 (ΦΑΣΗ Α) · L743-785 (σταθεροποίηση συνόλου) · L792-888 (ΦΑΣΗ Β) ·
              L895-991 (capture + διασταύρωση + fixed point)")

  (:name "Μετα-απόδειξη: μάρτυρας μεταλλάξεων της capture"
   :presence :present
   :domain "Απόδειξη ότι το αντιπαλικό harness ΟΝΤΩΣ ελέγχει τις ιδιότητες που ισχυρίζεται"
   :assumptions "κάθε μετάλλαξη πρέπει να εφαρμοστεί ΑΚΡΙΒΩΣ μία φορά (src.count(old)==1),
                 αλλιώς FAIL ΚΕΝΗ ΜΕΤΑΛΛΑΞΗ"
   :guarantees "21 μεταλλάξεις· 18 ΠΡΕΠΕΙ να σκοτωθούν· 3 δηλώνονται ΜΗ ΠΑΡΑΤΗΡΗΣΙΜΕΣ και η
                δήλωση είναι ΔΙΑΨΕΥΣΙΜΗ: αν σκοτωθούν ⇒ FAIL (L253-262)· θετικός μάρτυρας:
                ο αμετάλλακτος κώδικας ΠΡΕΠΕΙ να περνά"
   :failure-semantics "exit 1 σε οποιονδήποτε ανεξήγητο επιζώντα ή ψευδή δήλωση"
   :operating-model "Χτίζει πλήρες μίνι-δέντρο σε tmp με μεταλλαγμένη capture.py και ΑΥΤΟΥΣΙΟ
                     harness· symlink στα ΠΡΑΓΜΑΤΙΚΑ deployment/ golden vectors (L212)"
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΕ ΑΡΙΘΜΗΤΙΚΑ: 21 entries − 3 NON_OBSERVABLE = 18 φονεύσιμες,
                 + 1 θετικός μάρτυρας = 19 assertions ⇒ η δήλωση «19/0, 18/18» του matrix L119
                 ΕΙΝΑΙ ΑΚΡΙΒΗΣ."
   :evidence "authority-v2/proofs/capture-mutation-witness.py:L50-162 (21 MUTANTS) ·
              L174-186 (3 NON_OBSERVABLE) · L190-197 (COMBOS) · L225-231 (θετικός μάρτυρας) ·
              L253-267 (κριτήριο) · LEVEL7-COMPLETION-MATRIX.sexp:L119")

  (:name "Μηχανικές πύλες συνέπειας του matrix και του proof-manifest"
   :presence :present
   :domain "Συντακτική/αριθμητική συνέπεια των ΔΥΟ δηλωτικών αρχείων"
   :assumptions "τα αρχεία διαβάζονται ως ΚΕΙΜΕΝΟ με regex — καμία ανάγνωση s-expression"
   :guarantees "κλειστό λεξιλόγιο status· υποχρεωτικά πεδία· :proved απαιτεί μη-NOT-EXECUTED
                actual-result ΚΑΙ μη-κενά proof-objects· gate ≠ :passed όσο φέρουσα ≠ :proved·
                summary υπολογισμένο ≠ δηλωμένο ⇒ ΑΠΟΡΡΙΨΗ"
   :failure-semantics "exit 1 με απαρίθμηση ασυνεπειών· κενός πίνακας ⇒ fail-closed"
   :operating-model "Δύο verifiers + 12 αρνητικά fixtures που τους επιτίθενται σε αντίγραφα tmp"
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΕ ΑΡΙΘΜΗΤΙΚΑ: matrix 13 γραμμές (3 inp + 7 eb + 3 ns) ταιριάζει με
                 το δηλωμένο summary· proof-manifest 17 θεωρήματα (T1-T9, P1-P2, S1-S2, C1,
                 R1-R3) ταιριάζει με :total 17. Οι δύο δηλώσεις είναι ΑΡΙΘΜΗΤΙΚΑ ΣΩΣΤΕΣ."
   :evidence "authority-v2/proofs/verify-completion-matrix.py:L21-24,L58-104 ·
              authority-v2/proofs/verify-proof-manifest.py:L17,L49-78 ·
              authority-v2/proofs/gate-negative-fixtures.py:L71-121 (12 cases)")

  (:name "Απογραφή αποδείξεων με αναδρομική σάρωση και ΕΝΑΝ κατάλογο εισόδων"
   :presence :present
   :domain "Αδυνατότητα 'ξεχασμένης απόδειξης' κάτω από authority-v2/"
   :assumptions "ΤΟ ΚΡΙΣΙΜΟ: ο κώδικας αναγνωρίζεται ΑΠΟ ΤΗΝ ΚΑΤΑΛΗΞΗ .py/.sh/.lisp (βλ. defect)"
   :guarantees "κανένα symlink κάτω από authority-v2/· proofs/ ΕΠΙΠΕΔΟΣ· κάθε αρχείο στο proofs/
                εγγεγραμμένο· καμία νεκρή εγγραφή· καμία ΒΑΠΤΙΣΗ απόδειξης ως tool/helper·
                κλειστό σχήμα τρόπων· απαγόρευση διπλότυπης εγγραφής"
   :failure-semantics "exit 1 σε απόκλιση προς οποιαδήποτε κατεύθυνση· BLOCKED ⇒ exit 3 (ΠΟΤΕ 0)·
                       AUTHORITY_V2_REQUIRE_ALL=1 ⇒ BLOCKED γίνεται ΣΦΑΛΜΑ"
   :operating-model "bash· find -type f· σύγκριση με PROOF-CENSUS.txt· 15 αποδείξεις + 4 tools
                     + 16 helpers = 35 καταχωρήσεις"
   :materiality "Είναι η απάντηση σε ρητή ετυμηγορία δημιουργού για glob-based census."
   :evidence "authority-v2/run-proofs.sh:L37-126 · authority-v2/PROOF-CENSUS.txt:L39-84")

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
   :is-it-in-the-known-defect-list :unknown)

  (:what "ΑΣΥΜΜΕΤΡΙΑ PINNING ΣΤΟΝ ΙΔΙΟ ΕΛΕΓΧΟ: το canonical profile ελέγχεται απέναντι σε
          ΚΑΡΦΩΜΕΝΟ sha256 (κλείσιμο ρητού P1 του δημιουργού «αυθαίρετο pathname ΧΩΡΙΣ pinned
          digest ⇒ άλλο profile με σωστό id γίνεται δεκτό»), ΑΛΛΑ τα golden Merkle vectors —
          η ΜΟΝΗ εξωτερική αναφορά της verify_merkle_seat() — διαβάζονται με σκέτο open()
          από παράμετρο pathname, ΧΩΡΙΣ pinned digest, ΧΩΡΙΣ anchor, ΧΩΡΙΣ O_NOFOLLOW.
          Η verify_merkle_seat(vectors_path=…) δέχεται ΟΠΟΙΟΔΗΠΟΤΕ αρχείο. Το αντιπαλικό
          harness ΔΕΝ έχει σενάριο για αυτό: το capture-adversarial-test.py δοκιμάζει την
          ΤΑΥΤΟΣΗΜΗ επίθεση για το profile (L357-364) και ΚΑΜΙΑ για τα vectors."
   :severity :p1
   :evidence "authority-v2/capture/capture.py:L74-75 (GOLDEN_VECTORS από pathname) ·
              L248,L256-261 (open() χωρίς digest) · L80-81,L648-656 (το profile ΕΙΝΑΙ pinned) ·
              authority-v2/proofs/capture-adversarial-test.py:L357-364 (η επίθεση δοκιμάζεται
              ΜΟΝΟ για το profile)"
   :is-it-in-the-known-defect-list :no)

  (:what "Ο ισχυρισμός «Καμία εξάρτηση από όνομα ή bit εκτέλεσης» της απογραφής ΕΙΝΑΙ ΨΕΥΔΗΣ
          στον ίδιο τον κώδικα που τον διατυπώνει: η ταξινόμηση κώδικα ΕΚΤΟΣ του proofs/
          γίνεται με `case $f in *.py|*.sh|*.lisp)` — δηλαδή ΑΚΡΙΒΩΣ με ευρετικό ΟΝΟΜΑΤΟΣ
          (κατάληξη). Αρχείο χωρίς κατάληξη (π.χ. authority-v2/other/forgotten-proof), ή με
          .pl/.rb/.js/.bash/.mjs, ΔΕΝ ταξινομείται καθόλου και διαφεύγει σιωπηλά. Το
          proof-census-adversarial-test.py φυτεύει ΜΟΝΟ .py/.lisp, άρα δεν πιάνει την κλάση."
   :severity :p1
   :evidence "authority-v2/run-proofs.sh:L48 (ο ισχυρισμός) · L43-47 (η δήλωση «ΚΑΘΕ αρχείο
              κώδικα») · L71 (η υλοποίηση: *.py|*.sh|*.lisp) ·
              authority-v2/PROOF-CENSUS.txt:L34-36 (ο ίδιος ισχυρισμός)"
   :is-it-in-the-known-defect-list :no)

  (:what "Οι δύο «πύλες τιμιότητας» (verify-completion-matrix.py, verify-proof-manifest.py)
          επαληθεύουν ΜΟΝΟ ΣΥΝΤΑΚΤΙΚΗ ΑΥΤΟ-ΣΥΝΕΠΕΙΑ ΤΟΥ ΚΕΙΜΕΝΟΥ. Το :actual-result είναι
          ελεύθερο κείμενο: ο μόνος έλεγχος είναι ότι δεν περιέχει τη συμβολοσειρά
          'NOT-EXECUTED'. Καμία γραμμή δεν συνδέεται με artifact, log, hash ή εκτέλεση. Το
          :proof-artifact ελέγχεται ως ΥΠΑΡΞΗ ΤΗΣ ΛΕΞΗΣ μέσα στο body, όχι ως αρχείο που
          υπάρχει. Ούτε το :implementation ελέγχεται ότι δείχνει σε υπαρκτά αρχεία. Άρα ο
          ισχυρισμός «αδύνατη η χειροκίνητη βαθμολογία» ισχύει ΜΟΝΟ για τα αριθμητικά
          αθροίσματα, ΟΧΙ για τα αποτελέσματα εκτέλεσης."
   :severity :p1
   :evidence "authority-v2/proofs/verify-completion-matrix.py:L68-76 (μόνο 'NOT-EXECUTED' in
              actual) · L11-12 (ο ισχυρισμός) ·
              authority-v2/proofs/verify-proof-manifest.py:L54-56 (':proof-artifact' not in
              body — substring) · L57-59 (ο έλεγχος prover ΠΑΡΑΚΑΜΠΤΕΤΑΙ για provers εκτός
              της λίστας :provers, π.χ. 'KaRaMeL/Goose', 'byte comparison')"
   :is-it-in-the-known-defect-list :no)

  (:what "Το λεξιλόγιο απορρίψεων της CAPTURE-PROTOCOL.sexp ΔΕΝ συμφωνεί με τον κώδικα και
          κανένα gate δεν το ελέγχει: το πρωτόκολλο δηλώνει 25 :rejection-reasons· η capture.py
          παράγει 44 διακριτούς λόγους, από τους οποίους 21 ΔΕΝ είναι δηλωμένοι (anchor-stale,
          capability-forgery, capability-immutable, canonical-profile-unpinned, cleanup-incomplete,
          set-mutated-during-capture, limit-exceeded, os-error, quarantine-no-space κ.ά.), ενώ
          2 δηλωμένοι ΔΕΝ παράγονται ΠΟΤΕ: :symlink-present και :declared-root-mismatch. Το
          :symlink-present είναι η επικεφαλής άρνηση του βήματος 1 του πρωτοκόλλου — symlink
          μέσα στο candidate εμφανίζεται στην πράξη ως escapes-root (ELOOP)."
   :severity :p2
   :evidence "authority-v2/capture/CAPTURE-PROTOCOL.sexp:L64-89 (25 δηλωμένοι· L65
              :symlink-present· L72 :declared-root-mismatch) ·
              authority-v2/capture/capture.py:L155-156 (symlink ⇒ escapes-root) ·
              L111-118,L121-131 (μη δηλωμένες κλάσεις) · L317-360 (capability-*)"
   :is-it-in-the-known-defect-list :no)

  (:what "Το capture/canonical-profile.json δείχνει σε ΑΝΥΠΑΡΚΤΟ μονοπάτι για το διαφορικό
          test: λέει 'authority-v2/tests/capture-seat-differential-test.sh' ενώ το αρχείο ζει
          στο authority-v2/proofs/. Επειδή το profile είναι PINNED BY SHA256, η διόρθωση του
          σχολίου απαιτεί ΚΑΙ αλλαγή του καρφωμένου digest στην capture.py."
   :severity :p2
   :evidence "authority-v2/capture/canonical-profile.json:L3 ·
              authority-v2/capture/CAPTURE-PROTOCOL.sexp:L135 (σωστό μονοπάτι) ·
              authority-v2/capture/capture.py:L80-81 (το pinning που παγώνει το λάθος)"
   :is-it-in-the-known-defect-list :no)

  (:what "Στην capture(), το `finally` block σηκώνει CaptureRefused('cleanup-incomplete') όταν
          αποτύχει ο καθαρισμός. Αν η αρχική άρνηση ήταν επίσης CaptureRefused (π.χ.
          hardlink-present σε πραγματική επίθεση), η ΑΙΤΙΑ ΑΝΤΙΚΑΘΙΣΤΑΤΑΙ: ο καλών βλέπει
          'cleanup-incomplete' αντί για τον λόγο της επίθεσης (η αρχική μένει μόνο ως
          __context__). Fail-closed διατηρείται, η ΔΙΑΓΝΩΣΗ όχι."
   :severity :p2
   :evidence "authority-v2/capture/capture.py:L983-991"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ ΚΕΝΤΡΙΚΟ ΕΥΡΗΜΑ ΤΗΣ ΣΥΣΤΑΔΑΣ — 7 ΑΠΟ ΤΑ 13 ΔΗΛΩΤΙΚΑ ΑΡΤΕΦΑΚΤΑ ΔΕΝ ΔΙΑΒΑΖΟΝΤΑΙ
          ΑΠΟ ΚΑΝΕΝΑΝ ΕΚΤΕΛΕΣΙΜΟ ΚΩΔΙΚΑ ΤΗΣ ΣΥΣΤΑΔΑΣ. Μηχανική επαλήθευση με αναζήτηση του
          ΟΝΟΜΑΤΟΣ ΑΡΧΕΙΟΥ σε ΚΑΘΕ .py/.sh/.lisp κάτω από authority-v2/:
            kernel/admission-model.sexp            → 0 αναγνώστες
            store/STORAGE-API.sexp                 → 0 αναγνώστες
            log/witness-policy.sexp                → 0 αναγνώστες
            roles/ROLES-MODEL.sexp                 → 0 αναγνώστες
            capture/CAPTURE-PROTOCOL.sexp          → 0 αναγνώστες
            schema/transition-certificate.cddl     → 0 αναγνώστες
            schema/state.cddl                      → 0 αναγνώστες
            toolchain/trusted-toolchain-manifest.sexp → 0 αναγνώστες
          Διαβάζονται ΜΟΝΟ: LEVEL7-COMPLETION-MATRIX.sexp, proof-manifest.sexp, PROOF-CENSUS.txt,
          capture/canonical-profile.json, genesis/genesis-policy.sexp.
          Συνέπεια: ΚΑΜΙΑ αλλαγή σε αυτά τα 8 αρχεία ΔΕΝ μπορεί να αποτύχει καμία απόδειξη."
   :severity :p0
   :evidence "authority-v2/kernel/admission-model.sexp:L1-118 (κανένας αναγνώστης) ·
              authority-v2/log/witness-policy.sexp:L1-78 · authority-v2/roles/ROLES-MODEL.sexp:L1-95 ·
              authority-v2/store/STORAGE-API.sexp:L1-73 · authority-v2/schema/state.cddl:L1-85 ·
              authority-v2/schema/transition-certificate.cddl:L1-129 ·
              authority-v2/capture/CAPTURE-PROTOCOL.sexp:L1-174 ·
              authority-v2/toolchain/trusted-toolchain-manifest.sexp:L1-105"
   :is-it-in-the-known-defect-list :no)

  (:what "ΣΠΑΣΜΕΝΗ ΑΥΤΟ-ΔΕΣΜΕΥΣΗ ΤΟΥ SEQUENCE-0 CERTIFICATE ΣΤΟ ΠΑΓΩΜΕΝΟ ΔΕΝΤΡΟ: το committed
          genesis/out/legacy-adoption-certificate.unsigned.json δηλώνει
          legacy_manifest_digest = sha256:5d59acffa31c085ab6fc12c73dcd0f1dd51b2a1e4cac8a52778642469c45e2c0,
          ενώ το sha256 του committed genesis/out/legacy-snapshot.json είναι
          sha256:fed7db72e87cd83b6c1f268926e5b8bbc688c4d768d02582cf65e5effc16fdc5. ΔΕΝ ΤΑΙΡΙΑΖΟΥΝ.
          (Ο αδελφός δεσμός detail_digest ΤΟΥ conformance ΤΑΙΡΙΑΖΕΙ — άρα δεν είναι σφάλμα
          υπολογισμού αλλά ΞΕΠΕΡΑΣΜΕΝΟ artifact.) Το matrix γραμμή 4 επικαλείται αυτό ακριβώς
          το certificate ως «υπάρχει ήδη με 13/13 πεδία»."
   :severity :p0
   :evidence "authority-v2/genesis/out/legacy-adoption-certificate.unsigned.json:L1 (πεδίο
              legacy_manifest_digest) · authority-v2/genesis/out/legacy-snapshot.json:L1 ·
              authority-v2/genesis/build-adoption-certificate.py:L73 (η δέσμευση) ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L103"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ ΜΟΝΑΔΙΚΟ ΥΠΟΓΕΓΡΑΜΜΕΝΟ ARTIFACT ΤΗΣ ΣΥΣΤΑΔΑΣ ΕΧΕΙ ΑΠΟΚΛΙΝΕΙ ΑΠΟ ΤΟ ΠΑΡΑΓΟΜΕΝΟ:
          το fixtures/genesis-cert-fixture.json (υπογραφή ΕΠΑΛΗΘΕΥΤΗΚΕ ΕΠΙΤΟΠΟΥ με
          openssl pkeyutl -verify → Signature Verified Successfully) φέρει
          source_commit 57c0cd868c80f87df8e298c9aa75b8ccf2503391, ενώ το τρέχον draft φέρει
          b26abbd68caf49481714288f06bfc2cb387ecdd2. Επιπλέον ΔΙΑΦΕΡΟΥΝ ΔΟΜΙΚΑ: το fixture
          δεν έχει τα πεδία historical_run_artifacts και legacy_release_count_by_naming, το
          legacy_releases είναι λίστα ΣΥΜΒΟΛΟΣΕΙΡΩΝ αντί λίστα ΑΝΤΙΚΕΙΜΕΝΩΝ, και τα
          legacy_manifest_digest / new_verifier_result διαφέρουν. Άρα η ΜΟΝΗ κρυπτογραφική
          δέσμευση της συστάδας πιστοποιεί ΑΛΛΟ σχήμα certificate από αυτό που παράγει ο κώδικας."
   :severity :p1
   :evidence "authority-v2/fixtures/genesis-cert-fixture.json:L1 ·
              authority-v2/fixtures/genesis-cert-fixture.sig (64 bytes, ed25519) ·
              authority-v2/fixtures/test-keys/genesis-test-ed25519.pub:L1-3 ·
              authority-v2/genesis/out/legacy-adoption-certificate.unsigned.json:L1 ·
              authority-v2/fixtures/test-keys/README.md:L19-24"
   :is-it-in-the-known-defect-list :no)

  (:what "ΟΛΟΚΛΗΡΟ ΤΟ genesis/ ΕΙΝΑΙ ΕΚΤΟΣ ΚΑΘΕ ΠΥΛΗΣ: τα 4 εκτελέσιμα (legacy-snapshot.py,
          conformance-check.py, build-adoption-certificate.py, genesis-policy.sexp) είναι
          ταξινομημένα ως `helper` στην απογραφή, δηλαδή ΔΕΝ τρέχουν ΠΟΤΕ από τον runner. Κανένα
          proof δεν αναφέρει τα genesis/out/*, το genesis-cert-fixture.json, ή την υπογραφή του.
          Μηχανικός έλεγχος: 0 αναφορές σε 'genesis-cert-fixture' και 'legacy-adoption-certificate'
          σε ΟΛΟΝ τον κώδικα του repo εκτός του ίδιου του builder. Οι μόνες δεσμεύσεις που
          επαληθεύτηκαν (από ΕΜΕΝΑ, όχι από πύλη): genesis_policy_hash ΤΑΙΡΙΑΖΕΙ,
          MANIFEST.json ↔ tlog-n1/2/3 ΤΑΙΡΙΑΖΟΥΝ, fixture signature ΕΠΑΛΗΘΕΥΕΤΑΙ."
   :severity :p1
   :evidence "authority-v2/PROOF-CENSUS.txt:L70-72 (helper) · authority-v2/run-proofs.sh:L120,L161
              (helpers ΠΑΡΑΚΑΜΠΤΟΝΤΑΙ) · authority-v2/genesis/build-adoption-certificate.py:L45-138"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ ΔΗΛΩΜΕΝΟ ΜΟΝΟΠΑΤΙ ΑΡΣΗΣ ΤΩΝ :externally-blocked ΕΙΝΑΙ ΑΤΕΛΕΣ: και τα δύο hermetic
          Dockerfiles κάνουν `COPY toolchain-sources/ /build/sources/` και μετά sha256sum -c σε
          fstar/karamel/everparse/perennial/goose/gotxn tarballs. Ο κατάλογος toolchain-sources/
          ΔΕΝ ΥΠΑΡΧΕΙ πουθενά στο repo και ΚΑΝΕΝΑ αρχείο, script ή τεκμηρίωση δεν τον αναφέρει
          εκτός των δύο Dockerfiles. Άρα ακόμη και με συμπληρωμένα τα PIN-REQUIRED, η εντολή του
          matrix (`docker build -f …everparse.Dockerfile --target cddl-gate .`) αποτυγχάνει στο
          COPY: η προμήθεια των tarballs δεν έχει καμία ορισμένη διαδικασία."
   :severity :p1
   :evidence "authority-v2/toolchain/everparse.Dockerfile:L50-54 ·
              authority-v2/toolchain/perennial.Dockerfile:L43-47 ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L82,L153 ·
              authority-v2/proof-manifest.sexp:L21-24"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΕΣΤ-ΤΑΥΤΟΛΟΓΙΑ ΜΕ ΔΙΠΛΗ ΕΔΡΑ: το witness-quorum-test.py, που το matrix γραμμή 8
          παρουσιάζει ως την εκτελεσμένη απόδειξη της πολιτικής μαρτύρων, ΔΕΝ ΑΝΟΙΓΕΙ ΠΟΤΕ
          το log/witness-policy.sexp. Ξαναδηλώνει τις σταθερές inline (MAX_CHECKPOINT_AGE=86400,
          MAX_OBSERVATION_LAG=3600, REQUIRED_SIGNATURES=3) και ΞΑΝΑΥΛΟΠΟΙΕΙ την κρίση
          (evaluate_quorum). Άρα τα «8 passed» επαληθεύουν το ΔΙΚΟ ΤΟΥΣ μοντέλο, όχι το
          artifact που δηλώνεται ως implementation. Αλλαγή του :required-signatures 3 σε 1
          μέσα στο witness-policy.sexp ΔΕΝ κοκκινίζει τίποτα."
   :severity :p1
   :evidence "authority-v2/proofs/witness-quorum-test.py:L17-19 (οι σταθερές ξανά) ·
              L52-78 (η πολιτική ξανά) · L1-117 (καμία αναφορά στο .sexp) ·
              authority-v2/log/witness-policy.sexp:L48-49,L63-64 (οι ΙΔΙΕΣ τιμές, άλλη έδρα) ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L164-170"
   :is-it-in-the-known-defect-list :no)

  (:what "Το ίδιο σχήμα στους ρόλους: το ceremony.sh καρφώνει τα 5 ονόματα ρόλων και τα 4
          delegations στον κώδικα (for r in release targets snapshot timestamp) και ΔΕΝ διαβάζει
          το roles/ROLES-MODEL.sexp. Άρα η «πρόβα 4 τελετών» δεν επαληθεύει το μοντέλο ρόλων —
          επαληθεύει έναν δεύτερο, ανεξάρτητο ορισμό των ίδιων ρόλων."
   :severity :p1
   :evidence "authority-v2/roles/ceremony.sh:L67 (5 ρόλοι καρφωμένοι) · L70,L124 (4 delegations) ·
              authority-v2/roles/ROLES-MODEL.sexp:L28-65 (η άλλη έδρα)"
   :is-it-in-the-known-defect-list :no)

  (:what "Το ceremony.sh, αν κληθεί ΧΩΡΙΣ το LAWMAX_CEREMONY_WORK, γράφει ed25519 ΙΔΙΩΤΙΚΑ
          ΚΛΕΙΔΙΑ μέσα στο δέντρο του repository (authority-v2/fixtures/ceremony). Μόνο το
          ceremony-rehearsal-test.sh θέτει mktemp -d· η άμεση κλήση (που η απογραφή επιτρέπει
          ρητά ως tool-declared) δεν το κάνει."
   :severity :p2
   :evidence "authority-v2/roles/ceremony.sh:L25 (WORK default = $ROOT/authority-v2/fixtures/ceremony) ·
              L46-51 (new_key γράφει .key) · authority-v2/proofs/ceremony-rehearsal-test.sh:L5"
   :is-it-in-the-known-defect-list :no)

  (:what "verify-capability-closure.sh: το `setpriv` τρέχεται ως root, άρα το script ΕΧΕΙ την
          ικανότητα να καθαρίσει μόνο του τα probe αρχεία — αλλά στις ΑΡΝΗΤΙΚΕΣ περιπτώσεις
          (L58, L64) καθαρίζει ως root, ενώ στις ΘΕΤΙΚΕΣ (L50, L72) ως ο χρήστης με `|| true`.
          Αν το rm ως χρήστης αποτύχει, το probe αρχείο μένει ΜΕΣΑ στο authority store και
          καμία επόμενη εκτέλεση δεν το καταγγέλλει."
   :severity :p2
   :evidence "authority-v2/proofs/verify-capability-closure.sh:L50,L58,L64,L72"
   :is-it-in-the-known-defect-list :unknown))

 :hidden-execution-paths
 ((:path "authority-v2/proofs/docker-e2e-test.sh εκτελείται ΔΥΟ ΦΟΡΕΣ ανά run-all.sh"
   :trigger "run-all.sh καλεί run-proofs.sh (που το τρέχει ως requires-docker εγγραφή της\n             απογραφής) ΚΑΙ ΜΕΤΑ το ξανακαλεί ρητά"
   :why-hidden "μετριέται σε ΔΥΟ διαφορετικά ισοζύγια — μία φορά στο 15-άρι της απογραφής\n                και μία φορά στο τελικό ΣΥΝΟΛΟ του run-all"
   :evidence "authority-v2/run-all.sh:L40-41 · L60-61 · authority-v2/PROOF-CENSUS.txt:L55"))
 :duplicate-seats
 ((:concept "ΠΟΛΙΤΙΚΗ ΚΒΟΡΟΥΜ/ΦΡΕΣΚΑΔΑΣ ΜΑΡΤΥΡΩΝ — δύο ανεξάρτητοι ορισμοί, κανένας σύνδεσμος"
   :seats ("authority-v2/log/witness-policy.sexp:L47-69"
           "authority-v2/proofs/witness-quorum-test.py:L17-19,L52-78"))
  (:concept "ΣΥΝΟΛΟ ΡΟΛΩΝ ΚΑΙ DELEGATIONS — μοντέλο vs καρφωμένος κώδικας τελετής"
   :seats ("authority-v2/roles/ROLES-MODEL.sexp:L28-65"
           "authority-v2/roles/ceremony.sh:L67,L70,L124"))
  (:concept "MTH / Merkle έδρα — τρεις υλοποιήσεις (η τριπλή είναι ΣΚΟΠΙΜΗ, καταγράφεται ως γεγονός)"
   :seats ("authority-v2/capture/capture.py:L196-205 (_mth_recursive)"
           "authority-v2/capture/capture.py:L208-225 (_mth_streaming)"
           "deployment/verify/verify-merkle.py (ανεξάρτητη, καλείται από το harness)"
           "orchestrator.merkle:merkle-root-of-files (παραγωγικός Lisp πυρήνας, μέσω probe)"))
  (:concept "canonical set — json profile ΚΑΙ σταθερά +EPISTEMIC-CANONICAL-FILES+ του πυρήνα
             (η ταύτιση ΕΛΕΓΧΕΤΑΙ εκτελεστικά — δηλωμένη διπλή έδρα με γέφυρα)"
   :seats ("authority-v2/capture/canonical-profile.json:L5-16"
           "systems/orchestrator-epistemic/release-manifest.lisp (μέσω authority-v2/tests/probe-canonical-files.lisp)"))
  (:concept "docker-e2e εκτέλεση — καταγράφεται δύο φορές ανά run-all"
   :seats ("authority-v2/run-proofs.sh:L159-184 (ως εγγραφή απογραφής)"
           "authority-v2/run-all.sh:L60-61 (ρητή δεύτερη κλήση)"))
  (:concept "sha256-digest / ed25519-sig / ed25519-pub / sequence-no / utc-seconds / profile-id
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
