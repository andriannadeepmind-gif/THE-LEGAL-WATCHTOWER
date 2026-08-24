(:lawmax-phase1a-cluster/1
 :cluster "authority-v2"
 :status :complete
 :files-read 61
 :frozen-mount "/frozen/ro/authority-v2 (commit e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03)"
 :remaining ()

 ;; ── ΑΠΟΓΡΑΦΗ ΤΗΣ ΣΥΣΤΑΔΑΣ (μετρημένη, όχι δηλωμένη) ─────────────────────────
 :inventory
 (:regular-files 61                  ; η ανάθεση έλεγε 63· find -type f δίνει 61
  :breakdown ((:dir "." :n 5)        ; MATRIX, PROOF-CENSUS, proof-manifest, run-all.sh, run-proofs.sh
              (:dir "capability" :n 1) (:dir "capture" :n 3) (:dir "fixtures" :n 8)
              (:dir "genesis" :n 7) (:dir "kernel" :n 1) (:dir "log" :n 1)
              (:dir "proofs" :n 15) (:dir "roles" :n 2) (:dir "schema" :n 2)
              (:dir "store" :n 1) (:dir "tests" :n 12) (:dir "toolchain" :n 3))
  :census-entries 35                 ; 15 αποδείξεις + 4 tools + 16 helpers
  :executable-code-files 35          ; ΟΛΑ τα .py/.sh/.lisp — ταξινομημένα ΑΚΡΙΒΩΣ ΜΙΑ ΦΟΡΑ
  :declarative-artifacts 13          ; 3 πύλες/απογραφή + 8 αδρανή + canonical-profile + genesis-policy
  :declarative-artifacts-with-zero-code-readers 8
  :data-and-fixture-files 13         ; genesis/out 3 + fixtures 8 + toolchain Dockerfiles 2
  :capabilities-present 13 :capabilities-spec-only 8
  :defects (:p0 2 :p1 10 :p2 10)
  :matrix-summary (:total 13 :proved 0 :implemented-not-proved 3 :externally-blocked 7 :not-started 3)
  :manifest-summary (:total 17 :proved 0 :blocked-toolchain 17))

 ;; ═══════════════════════════════════════════════════════════════════════════
 ;; ΙΚΑΝΟΤΗΤΕΣ
 ;; ═══════════════════════════════════════════════════════════════════════════
 :capabilities
 ((:name "OS-enforced write-capability closure (authority/producer/reader uid separation)"
   :presence :present
   :domain "Filesystem DAC στο /var/lib/lawmax/authority και /var/lib/lawmax/candidates"
   :assumptions "root+setpriv+useradd κατά την εγκατάσταση· kernel DAC ορθός· καμία διεργασία
                 δεν τρέχει ως root στην παραγωγή· ΚΑΝΕΝΑ MAC profile (SELinux/AppArmor)"
   :guarantees "authority store: lawmax-authority(11001):lawmax-readers(11010) 0750 ⇒ μόνος
                writer· candidates: lawmax-producer(11002):lawmax-readers 0750· reader(11003)
                read-only και στα δύο· producer ΚΑΜΙΑ πρόσβαση στο store· τα uid/gid είναι
                ΚΑΡΦΩΜΕΝΑ ώστε το compose να τα δηλώνει ντετερμινιστικά"
   :failure-semantics "identities.sh: exit 1 χωρίς root· exit 1 αν το καρφωμένο uid είναι
                       πιασμένο από άλλον (καμία σιωπηλή επαναχρήση ταυτότητας).
                       verify-capability-closure.sh: exit 2 BLOCKED χωρίς root/setpriv, exit 2
                       αν λείπει ταυτότητα, exit 1 σε παραβίαση· θετικός μάρτυρας μη-κενότητας:
                       αν ο authority ΔΕΝ γράψει ⇒ FAIL «ΚΕΝΟΣ ΜΑΡΤΥΡΑΣ»"
   :operating-model "Δύο ξεχωριστές έδρες: εγκαταστάτης (capability/identities.sh, tool-requires-root,
                     τρέχει ΠΡΩΤΟ από τον runner) και εκτελεστικός μάρτυρας
                     (proofs/verify-capability-closure.sh, requires-root). Ο μάρτυρας εκτελεί
                     ΠΡΑΓΜΑΤΙΚΕΣ εγγραφές ως κάθε uid μέσω setpriv --init-groups."
   :materiality "Η ΜΟΝΗ ικανότητα της συστάδας που επιβάλλεται από OS και όχι από σύμβαση κώδικα.
                 Η STORAGE-API της αναθέτει ρητά το :single-writer obligation."
   :evidence "authority-v2/capability/identities.sh:L28-L88@sha256:814455cc6b0a ·
              authority-v2/proofs/verify-capability-closure.sh:L14-L86@sha256:a0eaba8f338a ·
              authority-v2/store/STORAGE-API.sexp:L48-L50@sha256:e8ccb6e50589")

  (:name "Candidate capture σε ιδιωτικό quarantine (TOCTOU-ανθεκτική, openat2/RESOLVE_*)"
   :presence :present
   :domain "Ανάγνωση εχθρικού candidates/ και παραγωγή αμετάβλητου snapshot + δύο Merkle ριζών"
   :assumptions "Linux ≥ 5.6 (openat2)· απουσία ⇒ ΑΡΝΗΣΗ openat2-unavailable, ΠΟΤΕ fallback.
                 Τα golden Merkle vectors (deployment/verify/vectors/merkle/vectors.json) είναι
                 αυθεντικά — ΔΕΝ είναι pinned (βλ. defect P1)."
   :guarantees "ΦΑΣΗ Α: αντιγραφή ΧΩΡΙΣ κανένα hash· ΦΑΣΗ Β: μέτρηση ΑΠΟΚΛΕΙΣΤΙΚΑ από το
                quarantine· διασταύρωση (path,size) ΚΑΙ total_bytes· ΔΕΥΤΕΡΗ πλήρης μέτρηση
                ΜΕΣΑ στην capture() (fixed-point-violation)· σταθεροποίηση ΟΛΟΥ ΤΟΥ ΣΥΝΟΛΟΥ
                (set-mutated-during-capture) ΚΑΙ ανά αρχείο (mutated-during-capture)·
                capability τύποι σφραγισμένοι και μη κατασκευάσιμοι (ιδιωτικό _MINT)· canonical
                profile pinned by sha256 (ΕΠΑΛΗΘΕΥΤΗΚΕ: 7c1005ae… == πραγματικό digest του
                αρχείου)· άρνηση hardlink/non-regular/symlink/traversal/non-UTF8/προϋπάρχοντος
                quarantine· ΚΑΘΕ fd κλείνει αμέσως (O(βάθος), όχι O(αρχεία))"
   :failure-semantics "CaptureRefused σε ΚΑΘΕ ανωμαλία· ΚΑΘΕ OSError μεταφράζεται σε ελεγχόμενη
                       άρνηση (fd-exhausted/quarantine-no-space/io-error/quarantine-read-only/
                       os-error)· μερικό quarantine καθαρίζεται με descriptor-based purge και
                       η αποτυχία καθαρισμού είναι ΟΡΑΤΗ (cleanup-incomplete)"
   :operating-model "1017 γραμμές Python. Ταξινομημένη ως `helper` στην απογραφή ⇒ ΔΕΝ τρέχει
                     από τον runner και ΔΕΝ είναι απόδειξη. Ρητά ΟΧΙ production writer:
                     «υλοποίηση αναφοράς / ΑΝΤΙΠΑΛΙΚΟ HARNESS»."
   :materiality "Το μόνο ουσιαστικά εκτελέσιμο μέρος της συστάδας που κάνει authority-σχετική
                 δουλειά. Η παραγωγική έδρα δηλώνεται ως μελλοντικό εξαγόμενο artifact."
   :evidence "authority-v2/capture/capture.py:L143-L160@sha256:9593561c6c06 (openat2) · L223-288 (open_anchor,
              διάσχιση κάθε συνιστώσας από «/») · L317-360 (_Sealed capability types) ·
              L595-657 (pinned canonical profile) · L673-740 (ΦΑΣΗ Α) · L743-785 (σταθεροποίηση
              συνόλου) · L792-888 (ΦΑΣΗ Β / measure) · L895-991 (capture + διασταύρωση + fixed point)")

  (:name "Merkle έδρα με ΔΥΟ δομικά διαφορετικούς αλγορίθμους MTH + golden vectors n=0..64"
   :presence :present
   :domain "release_root (MTH πάνω σε hash-leaf-file, ΣΤΗ ΣΕΙΡΑ του profile) και snapshot_root
            (MTH πάνω σε length-prefixed εγγραφές path/size/file-leaf)"
   :assumptions "SHA-256· τα committed vectors είναι αυθεντικά (ΔΕΝ pinned)"
   :guarantees "leaf = SHA-256(0x00‖bytes)· node = SHA-256(0x01‖L‖R)· RFC 9162 §2.1.1
                unbalanced split, ΠΟΤΕ duplicate-last (CVE-2012-2459)· κάθε ρίζα υπολογίζεται
                ΚΑΙ με αναδρομική διάσπαση ΚΑΙ με επαυξητική στοίβα και οι δύο ΟΦΕΙΛΟΥΝ να
                συμφωνούν για ΚΑΘΕ n ⇒ merkle-internal-divergence"
   :failure-semantics "verify_merkle_seat() ΠΡΙΝ από κάθε byte· απόκλιση/απουσία vectors ⇒
                       merkle-seat-divergence / merkle-seat-unverified"
   :operating-model "Ο ισχυρισμός «δομικά αδύνατη απόκλιση» είναι ΡΗΤΑ ΑΠΟΣΥΡΜΕΝΟΣ και στα δύο
                     αρχεία (RETRACTED_CLAIMS / :retracted-claims): ό,τι ισχύει είναι ΑΝΙΧΝΕΥΣΗ."
   :materiality "Είναι το μόνο σημείο της συστάδας όπου ένας ισχυρισμός ΑΠΟΣΥΡΘΗΚΕ αντί να
                 ενισχυθεί — και η απόσυρση καταγράφεται σε τρία αρχεία."
   :evidence "authority-v2/capture/capture.py:L181-L246@sha256:9593561c6c06 (_leaf/_node/_mth_recursive/_mth_streaming/_mth) ·
              L248-292 (verify_merkle_seat) · L84-92 (RETRACTED_CLAIMS) ·
              authority-v2/capture/CAPTURE-PROTOCOL.sexp:L114-L152@sha256:e119bee77c97")

  (:name "Μάρτυρας μεταλλάξεων της capture (μετα-απόδειξη: «περνάει» ≠ «ελέγχει»)"
   :presence :present
   :domain "Απόδειξη ότι το αντιπαλικό harness ΟΝΤΩΣ ελέγχει τις ιδιότητες που ισχυρίζεται"
   :assumptions "κάθε μετάλλαξη εφαρμόζεται ΑΚΡΙΒΩΣ μία φορά (src.count(old)==1), αλλιώς
                 FAIL «ΚΕΝΗ ΜΕΤΑΛΛΑΞΗ»"
   :guarantees "21 μεταλλάξεις· 18 ΠΡΕΠΕΙ να σκοτωθούν· 3 δηλώνονται ΜΗ ΠΑΡΑΤΗΡΗΣΙΜΕΣ με
                ΔΙΑΨΕΥΣΙΜΗ δήλωση (αν σκοτωθούν ⇒ FAIL: «η ΔΗΛΩΣΗ ΕΙΝΑΙ ΨΕΥΔΗΣ»)· θετικός
                μάρτυρας: ο αμετάλλακτος κώδικας ΠΡΕΠΕΙ να περνά"
   :failure-semantics "exit 1 σε ανεξήγητο επιζώντα ή σε ψευδή δήλωση μη-παρατηρησιμότητας"
   :operating-model "Χτίζει πλήρες μίνι-δέντρο σε tmp με ΜΕΤΑΛΛΑΓΜΕΝΗ capture.py και ΑΥΤΟΥΣΙΟ
                     harness· symlink στα ΠΡΑΓΜΑΤΙΚΑ deployment/ golden vectors· καμία
                     αγκίστρωση (env/flag) στον παραγωγικό κώδικα."
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΕ ΑΡΙΘΜΗΤΙΚΑ: 21 MUTANTS − 3 NON_OBSERVABLE = 18 φονεύσιμες,
                 + 1 θετικός μάρτυρας = 19 assertions ⇒ η δήλωση «19/0, 18/18» του matrix
                 (L119) ΕΙΝΑΙ ΑΚΡΙΒΗΣ."
   :evidence "authority-v2/proofs/capture-mutation-witness.py:L50-L162@sha256:9b3a416ab601 · L174-186 · L190-197 ·
              L200-213 (build_tree) · L225-231 · L233-267 ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L119-L119@sha256:7c82bef1def3")

  (:name "Διαφορικός έλεγχος έδρας: capture.py έναντι του παραγωγικού Lisp πυρήνα"
   :presence :present
   :domain "Ταύτιση release_root ΚΑΙ ταύτιση του canonical συνόλου/σειράς"
   :assumptions "sbcl παρόν· αλλιώς exit 2 BLOCKED"
   :guarantees "① canonical-profile.json ≡ +EPISTEMIC-CANONICAL-FILES+ ΜΕ ΤΗ ΣΕΙΡΑ που παράγει
                η collect-epistemic-artifacts (ΚΑΛΕΙΤΑΙ ο πυρήνας, δεν αντιγράφεται)·
                ② ίδια bytes ⇒ ίδια ρίζα· ③ ένα byte αλλάζει ⇒ ΚΑΙ ΟΙ ΔΥΟ ρίζες αλλάζουν και
                παραμένουν ίσες (αρνητικός μάρτυρας κατά ταυτολογικής ρίζας)· ④ αντίστροφη
                σειρά ⇒ διαφορετική ρίζα (η σειρά ΔΕΣΜΕΥΕΤΑΙ)"
   :failure-semantics "exit 2 χωρίς sbcl ή αν το core δεν χτιστεί· exit 1 σε απόκλιση"
   :operating-model "8 assertions· καλεί orchestrator.merkle:merkle-root-of-files μέσω probe."
   :materiality "Είναι η μόνη γέφυρα μεταξύ της συστάδας authority-v2 και του παραγωγικού
                 Lisp πυρήνα που ΕΛΕΓΧΕΤΑΙ εκτελεστικά αντί να δηλώνεται."
   :evidence "authority-v2/proofs/capture-seat-differential-test.sh:L24-L115@sha256:766fc5d4ff9b ·
              authority-v2/tests/probe-canonical-files.lisp:L15-L22@sha256:943a1770c0a4 ·
              authority-v2/tests/probe-merkle-root-of-files.lisp:L28-L34@sha256:1a368b4f99b7")

  (:name "Απογραφή αποδείξεων με αναδρομική σάρωση και ΕΝΑΝ κατάλογο εισόδων"
   :presence :present
   :domain "Αδυνατότητα «ξεχασμένης απόδειξης» κάτω από authority-v2/"
   :assumptions "ΚΡΙΣΙΜΟ: ο κώδικας αναγνωρίζεται ΑΠΟ ΤΗΝ ΚΑΤΑΛΗΞΗ .py/.sh/.lisp — βλ. defect P1"
   :guarantees "κανένα symlink κάτω από authority-v2/· proofs/ ΕΠΙΠΕΔΟΣ (καμία υποκατηγορία)·
                κάθε αρχείο στο proofs/ εγγεγραμμένο· καμία νεκρή εγγραφή· καμία ΒΑΠΤΙΣΗ
                απόδειξης ως tool/helper· κλειστό σχήμα 7 τρόπων· καμία διπλότυπη εγγραφή·
                καμία απόδειξη δηλωμένη εκτός proofs/"
   :failure-semantics "exit 1 σε απόκλιση προς ΟΠΟΙΑΔΗΠΟΤΕ κατεύθυνση· BLOCKED ⇒ exit 3
                       (ΠΟΤΕ 0)· AUTHORITY_V2_REQUIRE_ALL=1 ⇒ το BLOCKED γίνεται ΣΦΑΛΜΑ"
   :operating-model "bash· find -type f αναδρομικά· 15 αποδείξεις + 4 tools + 16 helpers.
                     Ο αντίπαλος (proof-census-adversarial-test.py) τρέχει τον ΙΔΙΟ runner
                     πάνω σε 15 τεχνητά αποθετήρια όπου η αλήθεια είναι γνωστή."
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΕ ΑΡΙΘΜΗΤΙΚΑ: 15 cases + 4 έλεγχοι της ΠΡΑΓΜΑΤΙΚΗΣ απογραφής = 19
                 ⇒ η δήλωση «proof-census-adversarial 19/0» (matrix L120) ΕΙΝΑΙ ΑΚΡΙΒΗΣ."
   :evidence "authority-v2/run-proofs.sh:L37-L195@sha256:a47922d94bb5 · authority-v2/PROOF-CENSUS.txt:L20-L84@sha256:331b0e5a3316 ·
              authority-v2/proofs/proof-census-adversarial-test.py:L95-L189@sha256:0490322908af")

  (:name "Μηχανικές πύλες συνέπειας του matrix και του proof-manifest"
   :presence :present
   :domain "ΣΥΝΤΑΚΤΙΚΗ και ΑΡΙΘΜΗΤΙΚΗ αυτο-συνέπεια ΤΩΝ ΔΥΟ ΔΗΛΩΤΙΚΩΝ ΚΕΙΜΕΝΩΝ"
   :assumptions "τα αρχεία διαβάζονται ως ΚΕΙΜΕΝΟ με regex· καμία ανάγνωση s-expression"
   :guarantees "κλειστό λεξιλόγιο status· 10 υποχρεωτικά πεδία ανά γραμμή· :proved απαιτεί
                actual-result χωρίς «NOT-EXECUTED» ΚΑΙ μη-κενά proof-objects· gate ≠ :passed
                όσο φέρουσα γραμμή ≠ :proved ΚΑΙ gate ≠ :not-passed αν όλες είναι proved·
                summary υπολογισμένο ≠ δηλωμένο ⇒ ΑΠΟΡΡΙΨΗ"
   :failure-semantics "exit 1 με απαρίθμηση ασυνεπειών· κενός πίνακας/manifest ⇒ fail-closed"
   :operating-model "Δύο verifiers + 12 αρνητικά fixtures που τους επιτίθενται σε αντίγραφα tmp
                     (2 θετικοί μάρτυρες + 6 matrix + 4 manifest)."
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΕ ΑΡΙΘΜΗΤΙΚΑ: matrix 13 γραμμές (3 inp + 7 eb + 3 ns) ΤΑΙΡΙΑΖΕΙ με
                 το δηλωμένο summary· proof-manifest 17 θεωρήματα (T1-T9, P1-P2, S1-S2, C1,
                 R1-R3) ΤΑΙΡΙΑΖΕΙ με :total 17· gate-negative-fixtures = 12 cases ⇒ «12/12»
                 ΑΚΡΙΒΗΣ. Το ΟΡΙΟ τους: επαληθεύουν κείμενο, ΟΧΙ εκτέλεση (βλ. defect P1)."
   :evidence "authority-v2/proofs/verify-completion-matrix.py:L21-L104@sha256:ce297276ed75 ·
              authority-v2/proofs/verify-proof-manifest.py:L17-L78@sha256:cc4a0f5dc5f9 ·
              authority-v2/proofs/gate-negative-fixtures.py:L71-L124@sha256:f14bc571beb7")

  (:name "Καθαρός admission kernel K(old,candidate,evidence,policy) + 9 conjuncts + 9 θεωρήματα"
   :presence :spec-only
   :domain "Αποδοχή/απόρριψη candidate release — η κεντρική πράξη εξουσίας του συστήματος"
   :assumptions "ολικότητα (total)· καμία I/O, ρολόι, τυχαιότητα, μεταβλητή κατάσταση·
                 ο χρόνος μπαίνει ΜΟΝΟ ως TSA genTime μέσα στο evidence"
   :guarantees "Accept ⟺ ΚΑΘΕ conjunct αληθές· ένα ψευδές ⇒ Reject ΜΕ ΟΛΟΥΣ τους λόγους.
                Conjuncts: authorization, sequence-monotonic, no-rollback, profile-continuity,
                census-completeness, source-binding, tsa-full-verification (ΜΟΝΟ :pinned),
                log-consistency, unique-latest."
   :failure-semantics "Reject([+reason]) — δηλωμένη «τρίτη έξοδος» ανύπαρκτη· ΑΝΕΠΑΛΗΘΕΥΤΗ
                       (δεν υπάρχει κώδικας να ελεγχθεί)"
   :operating-model "ΚΑΝΕΝΑΣ ΕΚΤΕΛΕΣΙΜΟΣ ΚΩΔΙΚΑΣ πουθενά. Το αρχείο δηλώνει ρητά
                     :implementation-status :specification-only και :implementation-language-target
                     «F* (verified) — ΟΧΙ Common Lisp», με ρητή αιτιολόγηση (δεύτερη έδρα)."
   :materiality "Φέρουσες απαιτήσεις 2 και 4 του matrix. Η υπηρεσία authority-signer δηλώνεται
                 ότι ΑΡΝΕΙΤΑΙ ΡΗΤΑ («ADMISSION KERNEL ΜΗ ΥΛΟΠΟΙΗΜΕΝΟΣ») αντί να προσποιείται."
   :evidence "authority-v2/kernel/admission-model.sexp:L18-L33@sha256:e2b4f4ea09eb · L38-70 · L74-111 · L113-118 ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L127-L127@sha256:7c82bef1def3 ·
              authority-v2/proofs/docker-e2e-test.sh:L86-L91@sha256:10d9da1b5d66")

  (:name "Κλειστό CDDL σχήμα transition-certificate (15 δεσμευμένα πεδία)"
   :presence :spec-only
   :domain "Wire format του transition certificate (deterministic CBOR, RFC 8949 §4.2)"
   :assumptions "EverCDDL/EverParse ως ο ΜΟΝΟΣ επικυρωτής· καμία float· κλειστές maps"
   :guarantees "άγνωστο κλειδί ⇒ απόρριψη κατά το parsing (όχι σιωπηλή αγνόηση)· ΜΟΝΟ pinned
                TSA (κλειστό literal «pinned»)· raw DER request ΚΑΙ response δεσμευμένα ώστε ο
                checker να επαναλάβει ΟΛΗ την RFC-3161 επαλήθευση"
   :failure-semantics :unknown        ; δεν υπάρχει parser που να υλοποιεί την απόρριψη
   :operating-model "Κείμενο CDDL χωρίς παραγόμενο parser. ΚΑΝΕΝΑ εργαλείο της συστάδας δεν
                     διαβάζει ή επικυρώνει αυτά τα .cddl αρχεία (μηχανικά επαληθευμένο)."
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΑ ΠΕΔΙΟ-ΠΡΟΣ-ΠΕΔΙΟ: και τα 15 απαριθμούμενα της απαίτησης 4
                 ΥΠΑΡΧΟΥΝ όντως στο σχήμα."
   :evidence "authority-v2/schema/transition-certificate.cddl:L28-L39@sha256:909a91aa4bac (ρίζα) · L41-45 · L47-51 ·
              L53-62 · L64-68 · L73-89 (TSA + revocation) · L91-100 · L102-105 · L107-123 ·
              L125-129")

  (:name "Authority state / rejection certificate σχήμα (unique-latest ΤΥΠΙΚΑ)"
   :presence :spec-only
   :domain "Authoritative state, log state, profile lineage, απόρριψη"
   :assumptions "ίδια με το transition-certificate.cddl"
   :guarantees "latest = null / ΕΝΑ map — δεν υπάρχει σχήμα που να επιτρέπει δεύτερο latest·
                rejection-certificate δεσμεύει state-hash-ΠΡΙΝ ΚΑΙ state-hash-ΜΕΤΑ ώστε η
                ισότητα να είναι ελέγξιμη από τρίτο· profile-link φέρει ed25519 υπογραφή root"
   :failure-semantics :unknown
   :operating-model "Κείμενο CDDL· κανένας παραγόμενος parser· 0 αναγνώστες στη συστάδα."
   :materiality "Η unique-latest είναι ΔΟΜΙΚΗ στο σχήμα (όχι έλεγχος) — αλλά χωρίς parser
                 κανείς δεν επιβάλλει το σχήμα."
   :evidence "authority-v2/schema/state.cddl:L18-L27@sha256:77f42d146a16 · L29-35 · L37-48 · L50-63 · L65-69 · L71-85")

  (:name "Authority store transactional API (6-item atomic commit)"
   :presence :spec-only
   :domain "Persistence της αποδεκτής μετάβασης"
   :assumptions "Perennial 2.0 / GoTxn υπόστρωμα ΜΕ ΑΠΟΔΕΙΞΗ — ΑΠΟΝ"
   :guarantees "ΟΛΑ τα έξι (certificate, state, release-ref, log-entry, checkpoint, latest)
                ορατά ή ΚΑΝΕΝΑ· recovery ΠΡΙΝ ή ΜΕΤΑ, ποτέ υβρίδιο· startup recheck ΟΛΗΣ της
                αλυσίδας πριν σερβιριστεί οτιδήποτε"
   :failure-semantics "production writer :disabled — «κάθε κλήση fail-closed» ΔΗΛΩΜΕΝΟ, ΟΧΙ
                       επαληθευμένο: δεν υπάρχει κώδικας κλήσης να ελεγχθεί"
   :operating-model ":implementation-status :absent-by-design· :forbidden-substitutes
                     απαριθμεί intent-log/SQLite/atomic-rename ως ΑΠΑΓΟΡΕΥΜΕΝΑ· ο αρνητικός
                     μάρτυρας της γραμμής 7 είναι ΑΚΡΙΒΩΣ η ΑΠΟΥΣΙΑ υλοποίησης"
   :materiality "Απαίτηση 7. Το :single-writer obligation ανατίθεται στην OS capability —
                 δηλαδή είναι το ΜΟΝΟ από τα τρία obligations με μη-blocked φορέα."
   :evidence "authority-v2/store/STORAGE-API.sexp:L17-L27@sha256:e8ccb6e50589 · L31-50 · L52-57 · L59-73")

  (:name "Witness quorum/freshness policy (format-agnostic)"
   :presence :spec-only
   :domain "Πολιτική συν-υπογραφής checkpoint από ανεξάρτητους μάρτυρες"
   :assumptions "wire format C2SP (tlog-tiles@v0.1.0/tlog-checkpoint/tlog-witness@v1.0.0)
                 :blocked-spec-input — ΚΑΜΙΑ σειριοποίηση δεν υποτίθεται"
   :guarantees "3 υπογραφές από 3 ανεξάρτητους φορείς· κοινό κριτήριο ανεξαρτησίας ⇒ μετρούν
                ως ΕΝΑΣ· checkpoint > 86400s ⇒ απόρριψη· witness lag > 3600s ⇒ απόρριψη·
                τοπικοί fake witnesses :counts-toward-quorum nil"
   :failure-semantics ":enforcement :fail-closed· current-state: κανένας ανεξάρτητος μάρτυρας
                       ⇒ η πύλη είναι ΑΝΕΝΕΡΓΗ (disabled), ρητά ΟΧΙ «0-of-3 ok»"
   :operating-model "Πολιτική σε s-expression με 0 αναγνώστες κώδικα. Το proof που δηλώνεται
                     γι' αυτήν ΞΑΝΑΥΛΟΠΟΙΕΙ την πολιτική inline (βλ. defect P1)."
   :materiality ":split-view-resistance-claim nil — ρητή ΑΡΝΗΣΗ ισχυρισμού."
   :evidence "authority-v2/log/witness-policy.sexp:L19-L28@sha256:68b5978b3e38 · L30-41 · L43-59 · L61-69 · L71-78")

  (:name "TUF-class roles model (5 ρόλοι, 1-of-1 offline root, 5 υποχρεωτικές άμυνες)"
   :presence :spec-only
   :domain "Ιεραρχία κλειδιών/ρόλων και άμυνες rollback/freeze/rotation/revocation/lineage"
   :assumptions "TUF v1.0.35 κείμενο :blocked-spec-input· :tuf-conformance-claim nil"
   :guarantees "root offline (ΠΟΤΕ σε μηχάνημα που τρέχει authority)· threshold 1 keyids 1
                ΣΗΜΕΡΑ, ρητά «κανένα ψεύτικο 3-of-5»· rotation = self-signed chain·
                revocation = explicit list· 5 mandatory-protections"
   :failure-semantics "ΟΛΕΣ οι 5 άμυνες φέρουν :status :specified — ΚΑΜΙΑ :implemented"
   :operating-model "Μοντέλο σε s-expression με 0 αναγνώστες κώδικα· το ceremony.sh καρφώνει
                     ανεξάρτητα τους ίδιους ρόλους (βλ. duplicate-seats)."
   :materiality "Απαίτηση 9· ο ρητός stop-point είναι το production root key."
   :evidence "authority-v2/roles/ROLES-MODEL.sexp:L19-L24@sha256:e12ce36e8b17 · L28-65 · L68-87 · L90-95")

  (:name "Ceremony tooling (genesis/rotation/revocation/recovery) με πραγματικά ed25519 test keys"
   :presence :present
   :domain "Πρόβα τελετών ρίζας με openssl· δομικό stop point πριν από production ρίζα"
   :assumptions "openssl παρόν· LAWMAX_CEREMONY_WORK ορισμένο (αλλιώς γράφει ΜΕΣΑ στο repo)"
   :guarantees "4 τελετές εκτελούνται ΠΡΑΓΜΑΤΙΚΑ (5 κλειδιά, 4 delegations, self-binding,
                αλυσίδα rotation, υπογεγραμμένη ανάκληση, ανάκτηση 4 ρόλων από offline root)·
                αρνητικός μάρτυρας: το ΝΕΟ root ΔΕΝ αυτο-επικυρώνεται χωρίς την αλυσίδα"
   :failure-semantics "MODE=production ή production-* εντολή ⇒ exit 3 ΠΑΝΤΑ· κάθε αποτυχία
                       επαλήθευσης ⇒ die (exit 1)"
   :operating-model "8 assertions στο ceremony-rehearsal-test.sh (4 rehearse + 3 production
                     stop + 1 MODE=production). ΕΠΑΛΗΘΕΥΤΗΚΕ: 8 ⇒ «8/0» ΑΚΡΙΒΗΣ."
   :materiality "Ο μόνος τόπος όπου παράγεται και επαληθεύεται πραγματικό κρυπτογραφικό υλικό."
   :evidence "authority-v2/roles/ceremony.sh:L30-L44@sha256:c7fff2b735af (stop point) · L64-81 · L83-100 · L102-115 ·
              L117-131 · L133-137 · authority-v2/proofs/ceremony-rehearsal-test.sh:L10-L21@sha256:65fe29eeef29")

  (:name "Producer OS boundary: η άρνηση αποδίδεται στο MOUNT, όχι σε δικαιώματα"
   :presence :present
   :domain "Απόδειξη ότι το read-only bind mount είναι ο μηχανισμός, με ΑΦΑΙΡΕΣΗ κάθε άλλης εξήγησης"
   :assumptions "root + setpriv + unshare + CAP_SYS_ADMIN· αλλιώς exit 2"
   :guarantees "το releases/ ανήκει ΣΤΟΝ ΙΔΙΟ ΤΟΝ PRODUCER με πλήρη δικαιώματα (καμία άμυνα
                από permissions)· θετικός έλεγχος χωρίς mount: ο producer ΓΡΑΦΕΙ· με ro bind
                mount το errno ΠΡΕΠΕΙ να είναι ΑΡΙΘΜΗΤΙΚΑ 30 (EROFS), ΟΧΙ 13 (EACCES)·
                η ro κατάσταση επιβεβαιώνεται από /proc/self/mountinfo, όχι από exit code·
                θετικός μάρτυρας: candidates/ παραμένει εγγράψιμο στο ΙΔΙΟ namespace"
   :failure-semantics "exit 2 αν ο θετικός έλεγχος αποτύχει (ΑΚΥΡΟΣ ΕΛΕΓΧΟΣ)· exit 2 αν το ro
                       mount δεν επιβεβαιωθεί· ΠΟΤΕ σιωπηλή υποβάθμιση σε chmod"
   :operating-model "11 assertions· καλεί τις ΠΡΑΓΜΑΤΙΚΕΣ παραγωγικές συναρτήσεις υπό producer
                     uid μέσω saved SBCL core. ΕΠΑΛΗΘΕΥΤΗΚΕ: 11 ⇒ «11/0» ΑΚΡΙΒΗΣ."
   :materiality "Είναι το ισχυρότερο μεθοδολογικά κομμάτι της συστάδας: κλείνει την ετυμηγορία
                 «η άρνηση εξηγείται πλήρως από απλά δικαιώματα» με ΔΟΜΙΚΗ αφαίρεση, όχι με
                 επιπλέον έλεγχο."
   :evidence "authority-v2/proofs/producer-os-boundary-test.sh:L40-L51@sha256:6e085a0beb91 · L67-75 · L78-126 ·
              L129-167 · authority-v2/tests/probe-producer-real.lisp:L1-L33@sha256:c29440c0d33c")

  (:name "Δηλωμένη τοπολογία ρόλων του docker-compose (ΟΧΙ εκτέλεση)"
   :presence :present
   :domain "Στατικός έλεγχος του docker-compose.yml: ρόλος ανά service, mounts, env, caps"
   :assumptions "PyYAML παρόν (αλλιώς exit 2 BLOCKED)· το docker-compose.yml είναι ΕΚΤΟΣ συστάδας"
   :guarantees "ΚΑΘΕ service ταξινομείται ΑΚΡΙΒΩΣ ΜΙΑ φορά (producer/reader/authority/proof-runner)·
                αταξινόμητο runtime ⇒ ΣΦΑΛΜΑ· ΥΠΑΡΞΗ ιδιωτικού κλειδιού (έστω :ro ή σε env)
                σε μη-authority ⇒ ΣΦΑΛΜΑ· /app/output και /app/deployment ro· tmpfs /run/lawmax·
                read_only rootfs + cap_drop [ALL] + no-new-privileges· runtime = ΟΤΙ ΧΤΙΖΕΤΑΙ
                από ΤΟ Dockerfile, το TAG ΔΕΝ είναι κριτήριο (κλείσιμο του image-tag bypass)"
   :failure-semantics "exit 2 χωρίς PyYAML· exit 1 σε οποιαδήποτε παραβίαση· 9 μεταλλαγμένες
                       τοπολογίες ΠΡΕΠΕΙ να απορριφθούν (μη-κενότητα)"
   :operating-model "ΤΙΜΙΟ ΟΡΙΟ δηλωμένο στο ίδιο το αρχείο: «ελέγχεται η ΔΗΛΩΜΕΝΗ τοπολογία·
                     η ΕΚΤΕΛΕΣΗ απαιτεί docker daemon»."
   :materiality "Οι εγγυήσεις της είναι για ΚΕΙΜΕΝΟ YAML, όχι για τρέχοντα container."
   :evidence "authority-v2/proofs/producer-topology-test.py:L31-L46@sha256:74942b063a3a · L84-166 · L169-207 · L209-250")

  (:name "Genesis: ντετερμινιστικός legacy snapshot + conformance + sequence-0 adoption certificate"
   :presence :present
   :domain "Δέσμευση ΟΛΗΣ της παλιάς ιστορίας ως evidence-only, χωρίς κληρονομιά εξουσίας"
   :assumptions "git παρόν (source_commit από `git rev-parse`, όχι δήλωση)"
   :guarantees "adoption-mode :evidence-only· inherited-authority/attestation/conformance = nil·
                legacy :read-only-preserved, destructive-operations-allowed nil·
                first-authoritative-sequence 1· 13 υποχρεωτικά πεδία, απόν ⇒ ΑΚΥΡΟ·
                6 conjuncts C1-C6 κρίνουν ΚΑΘΕ legacy release με ΑΚΡΙΒΗ λόγο ανά conjunct"
   :failure-semantics "fail-closed σε απόν evidence/policy· signature_status = unsigned-draft·
                       production signature ΚΑΙ TSA :fail-closed-pending-owner-root-ceremony"
   :operating-model "3 python helpers ΕΚΤΟΣ κάθε πύλης (ταξινομημένα helper· ο runner ΔΕΝ τα
                     τρέχει ΠΟΤΕ). Τα αποτελέσματα είναι committed JSON στο genesis/out/."
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΕ ΑΠΟ ΕΜΕΝΑ: genesis_policy_hash 9a04b3cd… ΤΑΙΡΙΑΖΕΙ με το
                 πραγματικό sha256 του genesis-policy.sexp· detail_digest ΤΑΙΡΙΑΖΕΙ με το
                 legacy-conformance.json· 13/13 πεδία παρόντα· conformance = 0/24 (τίμιο
                 εύρημα: ΚΑΝΕΝΑ legacy release δεν περνά τα νέα κριτήρια).
                 ΑΛΛΑ: legacy_manifest_digest ΔΕΝ ταιριάζει (βλ. defect P0)."
   :evidence "authority-v2/genesis/genesis-policy.sexp:L19-L78@sha256:9a04b3cd8970 ·
              authority-v2/genesis/legacy-snapshot.py:L36-L41@sha256:4b260f80ea54 authority-v2/genesis/legacy-snapshot.py:L199-L259@sha256:4b260f80ea54 ·
              authority-v2/genesis/conformance-check.py:L29-L43@sha256:2ab75cc33e93 authority-v2/genesis/conformance-check.py:L96-L155@sha256:2ab75cc33e93 ·
              authority-v2/genesis/build-adoption-certificate.py:L37-L42@sha256:1b6defdfb37d authority-v2/genesis/build-adoption-certificate.py:L66-L138@sha256:1b6defdfb37d")

  (:name "Παγωμένα legacy-tlog fixtures με επαληθεύσιμο RFC 6962 root"
   :presence :present
   :domain "Ιστορικά bytes του legacy transparency log, μετά την αφαίρεση του writer (Δ2)"
   :assumptions "τα bytes «παρήχθησαν ΑΝΕΞΑΡΤΗΤΑ από τον αφαιρεμένο writer» — ΑΝΕΠΑΛΗΘΕΥΤΟ
                 (κανένας generator δεν είναι committed)"
   :guarantees "MANIFEST με sha256 ανά fixture + provenance_commit 57c0cd86…· 5 corruption
                mutants (flip σε entry/log_root/checkpoint, αποκοπή, σκουπίδια) ΠΡΕΠΕΙ να
                σκοτωθούν από τον reader· θετικός μάρτυρας: τα γνήσια bytes ΠΡΕΠΕΙ να περνούν"
   :failure-semantics "delta23 exit 1 σε mismatch sha256 ή λάθος provenance_commit"
   :operating-model "Ο writer έχει ΑΦΑΙΡΕΘΕΙ· διατηρείται ιστορικό αντίγραφο ως .txt που
                     ΑΠΑΓΟΡΕΥΕΤΑΙ να δηλωθεί σε .asd (ελέγχεται)."
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΕ ΑΠΟ ΕΜΕΝΑ: και τα 3 sha256 του MANIFEST ταιριάζουν· και τα 3
                 log_root ΑΝΑΠΑΡΑΓΟΝΤΑΙ με RFC 6962 MTH πάνω στα entries· provenance_commit
                 υπάρχει και είναι 57c0cd868c80f87df8e298c9aa75b8ccf2503391."
   :evidence "authority-v2/fixtures/legacy-tlog/MANIFEST.json:L1-L24@sha256:45a21968e310 ·
              authority-v2/fixtures/legacy-tlog/REMOVED-tlog-writers.lisp.txt:L1-L26@sha256:05b4af8402ac ·
              authority-v2/tests/probe-frozen-mutants.lisp:L11-L51@sha256:c264e50e7e9d ·
              authority-v2/proofs/delta23-evidence-bundle.sh:L72-L87@sha256:eb0d61ed6b78 authority-v2/proofs/delta23-evidence-bundle.sh:L98-L107@sha256:eb0d61ed6b78")

  (:name "Υπογεγραμμένο genesis fixture (ed25519, επαληθεύσιμο εσαεί / μη επανυπογράψιμο)"
   :presence :present
   :domain "Το ΜΟΝΟ κρυπτογραφικά υπογεγραμμένο artifact ολόκληρης της συστάδας"
   :assumptions "το ιδιωτικό κλειδί ΣΚΟΠΙΜΑ ΔΕΝ είναι committed (repo guard *.key)"
   :guarantees "payload + .sig + .pub committed· κάθε artifact με αυτά τα κλειδιά φέρει
                signature_status=test-fixture-only· ΚΑΜΙΑ εξουσία"
   :failure-semantics :none           ; κανένα gate δεν το επαληθεύει αυτόματα
   :operating-model "Η επαλήθευση τεκμηριώνεται ως ΧΕΙΡΟΚΙΝΗΤΗ εντολή openssl στο README·
                     κανένα proof δεν την εκτελεί."
   :materiality "ΕΠΑΛΗΘΕΥΤΗΚΕ ΑΠΟ ΕΜΕΝΑ ΕΠΙΤΟΠΟΥ: openssl pkeyutl -verify ⇒ «Signature Verified
                 Successfully». Η υπογραφή είναι γνήσια. ΑΛΛΑ το υπογεγραμμένο περιεχόμενο
                 έχει αποκλίνει από το παραγόμενο (βλ. defect P1)."
   :evidence "authority-v2/fixtures/genesis-cert-fixture.json · .sig (64 bytes) ·
              authority-v2/fixtures/test-keys/genesis-test-ed25519.pub:L1-L3@sha256:79407cf2dbfb ·
              authority-v2/fixtures/test-keys/README.md:L1-L30@sha256:6d65cbac89b7")

  (:name "Hermetic toolchain builds ως δηλωμένο μονοπάτι άρσης των :externally-blocked"
   :presence :spec-only
   :domain "F*/EverParse (απαίτηση 3) και Coq/Perennial/GoTxn (απαίτηση 7)"
   :assumptions "docker daemon (ΑΠΩΝ)· δίκτυο (403)· ΚΑΙ ένας κατάλογος toolchain-sources/
                 που ΔΕΝ ΥΠΑΡΧΕΙ (βλ. defect)"
   :guarantees "όλα τα pins είναι PIN-REQUIRED ⇒ το build ΑΠΟΤΥΓΧΑΝΕΙ ΣΚΟΠΙΜΑ (fail-closed)·
                καμία εικασία commit/sha256 από μνήμη· sha256sum -c ΠΡΙΝ από κάθε extraction"
   :failure-semantics "exit 1 στο pin-gate πριν από οτιδήποτε άλλο"
   :operating-model "Τα Dockerfiles ΔΕΝ έχουν εκτελεστεί ΠΟΤΕ (NOT-EXECUTED στο matrix)."
   :materiality "Είναι η ΜΟΝΗ δηλωμένη διέξοδος για 7 από τις 13 απαιτήσεις· η ατέλειά της
                 (βλ. defect) αφορά ολόκληρο το χρέος απόδειξης."
   :evidence "authority-v2/toolchain/everparse.Dockerfile:L21-L72@sha256:b041f71c2b5b ·
              authority-v2/toolchain/perennial.Dockerfile:L17-L57@sha256:0518176d8d72 ·
              authority-v2/toolchain/trusted-toolchain-manifest.sexp:L25-L69@sha256:f2e3a4f320f1 ·
              authority-v2/proof-manifest.sexp:L20-L26@sha256:b56b4cbb392f")

  (:name "End-to-end refinement obligation (spec→source→binary→rebuild→runtime)"
   :presence :spec-only
   :domain "Αλυσίδα 5 κρίκων με υποχρέωση, εργαλείο και status ανά κρίκο"
   :assumptions "F*/Coq/KaRaMeL/Goose/CompCert ΑΠΟΝΤΑ· CompCert απαιτεί ΚΑΙ εμπορική άδεια"
   :guarantees "κρίκος 1,2 :blocked-toolchain· 3 :externally-blocked (άδεια)· 4 :not-started·
                5 :declared-residual· gate-9b :not-passed έως ότου ΚΑΘΕ κρίκος :discharged·
                κλειστός κατάλογος residual TCB (11 στοιχεία) με ρητό «τι ΔΕΝ αποδεικνύει»
                ανά εργαλείο· το SBCL δηλώνεται ρητά ως ΜΗ ΕΜΠΙΣΤΟ"
   :failure-semantics :none           ; 0 αναγνώστες κώδικα, κανένα gate δεν το επιβάλλει
   :operating-model "Κείμενο s-expression χωρίς κανέναν μηχανικό ελεγκτή."
   :materiality "Η μόνη δήλωση στη συστάδα που ονομάζει το trusting-trust πρόβλημα ρητά."
   :evidence "authority-v2/toolchain/trusted-toolchain-manifest.sexp:L18-L105@sha256:f2e3a4f320f1"))

 ;; ═══════════════════════════════════════════════════════════════════════════
 ;; ΑΥΘΕΝΤΙΕΣ — ΠΟΙΑ ΕΠΙΒΑΛΛΕΤΑΙ ΑΠΟ ΤΙ
 ;; ═══════════════════════════════════════════════════════════════════════════
 :authorities
 ((:name "lawmax-authority (uid 11001)"
   :what-it-can-decide "Ο ΜΟΝΟΣ που γράφει στο authority store"
   :who-can-invoke "όποιος έχει uid 11001 (setpriv / docker user:)"
   :enforcement :os
   :evidence "authority-v2/capability/identities.sh:L46-L46@sha256:814455cc6b0a authority-v2/capability/identities.sh:L76-L77@sha256:814455cc6b0a ·
              authority-v2/proofs/verify-capability-closure.sh:L47-L53@sha256:a0eaba8f338a")
  (:name "lawmax-producer (uid 11002)"
   :what-it-can-decide "Γράφει ΜΟΝΟ candidates· EACCES στο authority store· ΜΗ ΕΜΠΙΣΤΟΣ εξ ορισμού"
   :who-can-invoke "uid 11002" :enforcement :os
   :evidence "authority-v2/capability/identities.sh:L47-L47@sha256:814455cc6b0a authority-v2/capability/identities.sh:L80-L81@sha256:814455cc6b0a ·
              authority-v2/proofs/verify-capability-closure.sh:L56-L61@sha256:a0eaba8f338a authority-v2/proofs/verify-capability-closure.sh:L70-L75@sha256:a0eaba8f338a ·
              authority-v2/toolchain/trusted-toolchain-manifest.sexp:L95-L97@sha256:f2e3a4f320f1")
  (:name "lawmax-reader (uid 11003, ομάδα lawmax-readers 11010)"
   :what-it-can-decide "Διαβάζει authority store και candidates· δεν γράφει πουθενά"
   :who-can-invoke "uid 11003" :enforcement :os
   :evidence "authority-v2/capability/identities.sh:L48-L49@sha256:814455cc6b0a authority-v2/capability/identities.sh:L70-L70@sha256:814455cc6b0a ·
              authority-v2/proofs/verify-capability-closure.sh:L62-L67@sha256:a0eaba8f338a authority-v2/proofs/verify-capability-closure.sh:L77-L82@sha256:a0eaba8f338a")
  (:name "read-only bind mount πάνω στο legacy releases/"
   :what-it-can-decide "Καμία εγγραφή στο παρελθόν, ΑΝΕΞΑΡΤΗΤΑ από uid/δικαιώματα"
   :who-can-invoke "όποιος έχει CAP_SYS_ADMIN για να το στήσει"
   :enforcement :os
   :evidence "authority-v2/proofs/producer-os-boundary-test.sh:L78-L126@sha256:6e085a0beb91 (EROFS=30, όχι EACCES=13)")
  (:name "openat2 RESOLVE_BENEATH|NO_SYMLINKS|NO_XDEV κάτω από την άγκυρα"
   :what-it-can-decide "Κανένα άνοιγμα δεν ξεφεύγει από το candidate root ή το quarantine"
   :who-can-invoke "η capture(), και ΜΟΝΟ μέσω επαληθευμένων Anchor dirfds — ποτέ pathname"
   :enforcement :os
   :evidence "authority-v2/capture/capture.py:L94-L99@sha256:9593561c6c06 authority-v2/capture/capture.py:L143-L160@sha256:9593561c6c06 authority-v2/capture/capture.py:L168-L170@sha256:9593561c6c06 · L895-912")
  (:name "_CapabilityToken / _Sealed (Anchor, CanonicalProfile)"
   :what-it-can-decide "Ποιος μπορεί να ΚΑΤΑΣΚΕΥΑΣΕΙ ή να ΜΕΤΑΒΑΛΕΙ ένα capability object"
   :who-can-invoke "ΜΟΝΟ οι έδρες open_anchor()/load_canonical_profile() (ιδιωτικό _MINT)"
   :enforcement :code   ; γλωσσικός τύπος, όχι OS — παρακάμψιμος με object.__setattr__
   :evidence "authority-v2/capture/capture.py:L317-L360@sha256:9593561c6c06 · L595-623")
  (:name "PINNED_CANONICAL_PROFILE_SHA256"
   :what-it-can-decide "Ποιο ΑΚΡΙΒΩΣ αρχείο profile γίνεται δεκτό (τα bytes, όχι το id)"
   :who-can-invoke "όποιος αλλάξει τη σταθερά σε commit"
   :enforcement :code
   :evidence "authority-v2/capture/capture.py:L77-L81@sha256:9593561c6c06 authority-v2/capture/capture.py:L648-L656@sha256:9593561c6c06 (ΕΠΑΛΗΘΕΥΤΗΚΕ: ταιριάζει)")
  (:name "owner root role (offline)"
   :what-it-can-decide "Υπογράφει κλειδιά άλλων ρόλων, profile-lineage links, τον εαυτό της σε rotation"
   :who-can-invoke "κάτοχος του root ιδιωτικού κλειδιού — ΔΕΝ ΥΠΑΡΧΕΙ production key (stop point)"
   :enforcement :convention
   :evidence "authority-v2/roles/ROLES-MODEL.sexp:L28-L37@sha256:e12ce36e8b17 authority-v2/roles/ROLES-MODEL.sexp:L90-L95@sha256:e12ce36e8b17 · authority-v2/roles/ceremony.sh:L30-L44@sha256:c7fff2b735af")
  (:name "release role"
   :what-it-can-decide "Υπογράφει transition certificates (η καθημερινή πράξη εξουσίας)"
   :who-can-invoke "online authority host" :enforcement :convention
   :evidence "authority-v2/roles/ROLES-MODEL.sexp:L39-L44@sha256:e12ce36e8b17 ·
              authority-v2/schema/transition-certificate.cddl:L125-L129@sha256:909a91aa4bac")
  (:name "PROOF-CENSUS.txt (ο κλειστός κατάλογος εισόδων)"
   :what-it-can-decide "Τι μετράει ως απόδειξη και τι επιτρέπεται να υπάρχει ως κώδικας"
   :who-can-invoke "όποιος τρέχει τον run-proofs.sh"
   :enforcement :code
   :evidence "authority-v2/run-proofs.sh:L75-L126@sha256:a47922d94bb5 · authority-v2/PROOF-CENSUS.txt:L20-L84@sha256:331b0e5a3316")
  (:name "LEVEL7-COMPLETION-MATRIX.sexp + proof-manifest.sexp (οι πύλες τιμιότητας)"
   :what-it-can-decide "Αν το σύστημα επιτρέπεται να λέγεται Level-7 / formally-verified"
   :who-can-invoke "όποιος τρέχει τους δύο verifiers"
   :enforcement :code   ; συντακτικός/αριθμητικός έλεγχος ΚΕΙΜΕΝΟΥ, όχι εκτέλεσης
   :evidence "authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L23-L25@sha256:7c82bef1def3 authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L252-L259@sha256:7c82bef1def3 ·
              authority-v2/proof-manifest.sexp:L16-L18@sha256:b56b4cbb392f authority-v2/proof-manifest.sexp:L60-L64@sha256:b56b4cbb392f")
  (:name "LAWMAX_CEREMONY_MODE=production (το stop point)"
   :what-it-can-decide "Τίποτα — αρνείται ΠΑΝΤΑ με exit 3, ακόμη και για rehearse εντολές"
   :who-can-invoke "οποιοσδήποτε· η άρνηση είναι άνευ όρων σε αυτό το περιβάλλον"
   :enforcement :code
   :evidence "authority-v2/roles/ceremony.sh:L30-L44@sha256:c7fff2b735af authority-v2/roles/ceremony.sh:L133-L137@sha256:c7fff2b735af")
  (:name "AUTHORITY_V2_REQUIRE_ALL=1"
   :what-it-can-decide "Μετατρέπει κάθε BLOCKED σε ΣΦΑΛΜΑ (προορίζεται για CI)"
   :who-can-invoke "όποιος θέτει τη μεταβλητή περιβάλλοντος· ΤΟ CI ΔΕΝ ΕΧΕΙ ΤΡΕΞΕΙ ΠΟΤΕ"
   :enforcement :code
   :evidence "authority-v2/run-proofs.sh:L26-L26@sha256:a47922d94bb5 authority-v2/run-proofs.sh:L163-L180@sha256:a47922d94bb5 ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L130-L130@sha256:7c82bef1def3"))

 ;; ═══════════════════════════════════════════════════════════════════════════
 :invariants
 ((:statement "unique-latest: το σχήμα ΔΕΝ ΕΠΙΤΡΕΠΕΙ δεύτερο latest (τυπικά, όχι με έλεγχο)"
   :enforced-by "CDDL τύπος latest = null / {…} — ΟΧΙ λίστα. Κανένας parser δεν το επιβάλλει σήμερα."
   :evidence "authority-v2/schema/state.cddl:L29-L35@sha256:77f42d146a16")
  (:statement "rejection ⇒ καμία μεταβολή κατάστασης (state-hash ΠΡΙΝ == ΜΕΤΑ, ελέγξιμο από τρίτο)"
   :enforced-by "πεδία 2 και 3 του rejection-certificate"
   :evidence "authority-v2/schema/state.cddl:L71-L85@sha256:77f42d146a16")
  (:statement "TSA ΜΟΝΟ pinned — ΠΟΤΕ unpinned"
   :enforced-by "κλειστό literal «pinned» ως τιμή του key 9 στο tsa-evidence"
   :evidence "authority-v2/schema/transition-certificate.cddl:L82-L82@sha256:909a91aa4bac ·
              authority-v2/kernel/admission-model.sexp:L58-L63@sha256:e2b4f4ea09eb")
  (:statement "new.sequence = old.sequence + 1 ΑΚΡΙΒΩΣ, χωρίς κενά"
   :enforced-by "conjunct :sequence-monotonic (προδιαγραφή) + key 3 του previous-checkpoint"
   :evidence "authority-v2/kernel/admission-model.sexp:L43-L44@sha256:e2b4f4ea09eb ·
              authority-v2/schema/transition-certificate.cddl:L44-L44@sha256:909a91aa4bac")
  (:statement "Η K ΔΕΝ τρέχει ΠΟΤΕ πάνω στο candidates/ — μόνο πάνω σε συλληφθέν snapshot"
   :enforced-by "πρωτόκολλο 5 βημάτων· στην πράξη η capture() δέχεται ΜΟΝΟ Anchor, ποτέ pathname"
   :evidence "authority-v2/capture/CAPTURE-PROTOCOL.sexp:L27-L61@sha256:e119bee77c97 ·
              authority-v2/capture/capture.py:L895-L912@sha256:9593561c6c06")
  (:statement "τοπικοί fake witnesses ΔΕΝ μετρούν ΠΟΤΕ στο κβόρουμ"
   :enforced-by ":counts-toward-quorum nil (δηλωμένο ΔΟΜΙΚΟ)· στον κώδικα του test:
                 `if not w.independent: continue`"
   :evidence "authority-v2/log/witness-policy.sexp:L71-L78@sha256:68b5978b3e38 ·
              authority-v2/proofs/witness-quorum-test.py:L71-L77@sha256:909a8bccea9c")
  (:statement "BLOCKED ΔΕΝ ΕΙΝΑΙ ΠΟΤΕ PASS — τοπικά exit 3 (ΑΤΕΛΕΣ), σε CI ΣΦΑΛΜΑ"
   :enforced-by "run-proofs.sh ③④ και run-all.sh τελικό ισοζύγιο· κάθε requires-* script
                 αυτο-μπλοκάρεται με exit 2"
   :evidence "authority-v2/run-proofs.sh:L163-L194@sha256:a47922d94bb5 · authority-v2/run-all.sh:L29-L33@sha256:3c2ba7169352 authority-v2/run-all.sh:L70-L72@sha256:3c2ba7169352 ·
              authority-v2/proofs/docker-e2e-test.sh:L25-L27@sha256:10d9da1b5d66")
  (:statement "ΚΑΘΕ .py/.sh/.lisp κάτω από authority-v2/ ταξινομείται ΑΚΡΙΒΩΣ ΜΙΑ ΦΟΡΑ"
   :enforced-by "run-proofs.sh ①② — ΑΛΛΑ μόνο για αυτές τις τρεις καταλήξεις (βλ. defect)"
   :evidence "authority-v2/run-proofs.sh:L62-L73@sha256:a47922d94bb5 authority-v2/run-proofs.sh:L98-L125@sha256:a47922d94bb5")
  (:statement "καμία απόδειξη δεν ζει έξω από το proofs/ και κανένα εργαλείο μέσα του"
   :enforced-by "run-proofs.sh έλεγχοι stray/baptised/απογραφή-εκτός-proofs"
   :evidence "authority-v2/run-proofs.sh:L106-L125@sha256:a47922d94bb5")
  (:statement "κανένα symlink κάτω από το authority-v2/"
   :enforced-by "find -type l ⇒ exit 1"
   :evidence "authority-v2/run-proofs.sh:L53-L57@sha256:a47922d94bb5")
  (:statement "καμία CL/Python υλοποίηση CBOR δεν μπαίνει στο TCB ούτε παγιώνει wire format"
   :enforced-by :convention   ; ρητή εντολή· κανένας μηχανικός έλεγχος δεν την επιβάλλει
   :evidence "authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L85-L87@sha256:7c82bef1def3 ·
              authority-v2/toolchain/everparse.Dockerfile:L11-L12@sha256:b041f71c2b5b")
  (:statement "καμία υλοποίηση πίσω από το STORAGE-API (absent-by-design)"
   :enforced-by :convention   ; ο «αρνητικός μάρτυρας» είναι η ΑΠΟΥΣΙΑ, όχι έλεγχος
   :evidence "authority-v2/store/STORAGE-API.sexp:L20-L27@sha256:e8ccb6e50589 ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L155-L155@sha256:7c82bef1def3")
  (:statement "τα legacy δεδομένα ΔΕΝ διαγράφονται/μετακινούνται/ξαναγράφονται"
   :enforced-by "genesis-policy :destructive-operations-allowed nil (δήλωση) ΚΑΙ εκτελεστικά
                 από το ro bind mount του producer-os-boundary-test"
   :evidence "authority-v2/genesis/genesis-policy.sexp:L30-L36@sha256:9a04b3cd8970 ·
              authority-v2/proofs/producer-os-boundary-test.sh:L125-L126@sha256:6e085a0beb91 authority-v2/proofs/producer-os-boundary-test.sh:L165-L167@sha256:6e085a0beb91")
  (:statement "κανένα legacy release δεν κληρονομεί authority (evidence-only)"
   :enforced-by "genesis-policy + adoption certificate· ΕΠΑΛΗΘΕΥΜΕΝΟ ΑΠΟΤΕΛΕΣΜΑ: 0/24 conforming"
   :evidence "authority-v2/genesis/genesis-policy.sexp:L24-L28@sha256:9a04b3cd8970 ·
              authority-v2/genesis/out/legacy-conformance.json:L1-L1@sha256:72e35810db61"))

 ;; ═══════════════════════════════════════════════════════════════════════════
 ;; ΕΛΑΤΤΩΜΑΤΑ — ΟΠΟΥ Η ΔΗΛΩΣΗ ΔΕΝ ΣΤΗΡΙΖΕΤΑΙ ΑΠΟ ΤΟΝ ΚΩΔΙΚΑ
 ;; ═══════════════════════════════════════════════════════════════════════════
 :defects
 ((:what "ΤΟ ΚΕΝΤΡΙΚΟ ΕΥΡΗΜΑ — 8 ΑΠΟ ΤΑ 13 ΔΗΛΩΤΙΚΑ ΑΡΤΕΦΑΚΤΑ ΕΧΟΥΝ ΜΗΔΕΝ ΑΝΑΓΝΩΣΤΕΣ ΚΩΔΙΚΑ.
          Μηχανική επαλήθευση: αναζήτηση του ΟΝΟΜΑΤΟΣ ΑΡΧΕΙΟΥ σε ΚΑΘΕ .py/.sh/.lisp κάτω από
          authority-v2/:
            kernel/admission-model.sexp                → 0
            store/STORAGE-API.sexp                     → 0
            log/witness-policy.sexp                    → 0
            roles/ROLES-MODEL.sexp                     → 0
            capture/CAPTURE-PROTOCOL.sexp              → 0
            schema/transition-certificate.cddl         → 0
            schema/state.cddl                          → 0
            toolchain/trusted-toolchain-manifest.sexp  → 0
          Διαβάζονται ΜΟΝΟ: LEVEL7-COMPLETION-MATRIX.sexp, proof-manifest.sexp, PROOF-CENSUS.txt,
          capture/canonical-profile.json, genesis/genesis-policy.sexp.
          ΣΥΝΕΠΕΙΑ: οποιαδήποτε αλλαγή σε αυτά τα 8 αρχεία — συμπεριλαμβανομένης της διαγραφής
          conjunct, της αλλαγής threshold, της χαλάρωσης του κβόρουμ ή της αφαίρεσης πεδίου από
          το CDDL — ΔΕΝ ΜΠΟΡΕΙ ΝΑ ΑΠΟΤΥΧΕΙ ΚΑΜΙΑ ΑΠΟΔΕΙΞΗ. Η συστάδα είναι δύο ξένα συστήματα:
          (α) εκτελέσιμος πυρήνας capture/merkle + λογιστική απογραφής, (β) αδρανές κείμενο."
   :severity :p0
   :evidence "authority-v2/kernel/admission-model.sexp:L1-L118@sha256:e2b4f4ea09eb ·
              authority-v2/store/STORAGE-API.sexp:L1-L73@sha256:e8ccb6e50589 ·
              authority-v2/log/witness-policy.sexp:L1-L78@sha256:68b5978b3e38 ·
              authority-v2/roles/ROLES-MODEL.sexp:L1-L95@sha256:e12ce36e8b17 ·
              authority-v2/capture/CAPTURE-PROTOCOL.sexp:L1-L174@sha256:e119bee77c97 ·
              authority-v2/schema/transition-certificate.cddl:L1-L129@sha256:909a91aa4bac ·
              authority-v2/schema/state.cddl:L1-L85@sha256:77f42d146a16 ·
              authority-v2/toolchain/trusted-toolchain-manifest.sexp:L1-L105@sha256:f2e3a4f320f1 ·
              authority-v2/PROOF-CENSUS.txt:L50-L84@sha256:331b0e5a3316 (ο κατάλογος όσων τρέχουν)"
   :is-it-in-the-known-defect-list :no)

  (:what "ΣΠΑΣΜΕΝΗ ΑΥΤΟ-ΔΕΣΜΕΥΣΗ ΤΟΥ SEQUENCE-0 CERTIFICATE ΣΤΟ ΠΑΓΩΜΕΝΟ ΔΕΝΤΡΟ. Το committed
          genesis/out/legacy-adoption-certificate.unsigned.json δηλώνει
            legacy_manifest_digest = sha256:5d59acffa31c085ab6fc12c73dcd0f1dd51b2a1e4cac8a52778642469c45e2c0
          ενώ το πραγματικό sha256 του committed genesis/out/legacy-snapshot.json είναι
            sha256:fed7db72e87cd83b6c1f268926e5b8bbc688c4d768d02582cf65e5effc16fdc5.
          ΔΕΝ ΤΑΙΡΙΑΖΟΥΝ. Ο αδελφός δεσμός (new_verifier_result.detail_digest ↔
          legacy-conformance.json) ΤΑΙΡΙΑΖΕΙ, άρα δεν πρόκειται για σφάλμα υπολογισμού αλλά για
          ΞΕΠΕΡΑΣΜΕΝΟ committed artifact. Το matrix γραμμή 4 επικαλείται ΑΥΤΟ ΑΚΡΙΒΩΣ το
          certificate ως «υπάρχει ήδη με 13/13 πεδία». Τα 13/13 ισχύουν· η δέσμευση όχι."
   :severity :p0
   :evidence "authority-v2/genesis/out/legacy-adoption-certificate.unsigned.json:L1-L1@sha256:5139d99fcef0 ·
              authority-v2/genesis/out/legacy-snapshot.json:L1-L1@sha256:fed7db72e87c ·
              authority-v2/genesis/build-adoption-certificate.py:L73-L73@sha256:1b6defdfb37d ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L103-L103@sha256:7c82bef1def3"
   :is-it-in-the-known-defect-list :no)

  (:what "ΟΙ ΔΥΟ «ΠΥΛΕΣ ΤΙΜΙΟΤΗΤΑΣ» ΕΠΑΛΗΘΕΥΟΥΝ ΚΕΙΜΕΝΟ, ΟΧΙ ΕΚΤΕΛΕΣΗ. Το :actual-result είναι
          ελεύθερη συμβολοσειρά και ο ΜΟΝΟΣ έλεγχος είναι ότι δεν περιέχει το literal
          «NOT-EXECUTED». Καμία γραμμή δεν συνδέεται με artifact, log, hash ή πραγματική
          εκτέλεση. Το :proof-artifact ελέγχεται ως ΥΠΑΡΞΗ ΤΗΣ ΛΕΞΗΣ μέσα στο body, όχι ως
          αρχείο που υπάρχει. Το :implementation δεν ελέγχεται καθόλου ότι δείχνει σε υπαρκτά
          αρχεία. Και ο έλεγχος «prover ΔΕΝ ΥΠΑΡΧΕΙ ⇒ αδύνατο :proved» ΠΑΡΑΚΑΜΠΤΕΤΑΙ σιωπηλά
          για provers που δεν είναι στη λίστα :provers (KaRaMeL/Goose, byte comparison).
          Άρα η δήλωση «αδύνατη η χειροκίνητη βαθμολογία» ισχύει ΜΟΝΟ για τα αριθμητικά
          αθροίσματα. Τα 12 αρνητικά fixtures μεταλλάσσουν ΜΟΝΟ συντακτικά· κανένα δεν
          κατασκευάζει ψευδές :actual-result."
   :severity :p1
   :evidence "authority-v2/proofs/verify-completion-matrix.py:L11-L12@sha256:ce297276ed75 (ο ισχυρισμός) · L68-76 ·
              authority-v2/proofs/verify-proof-manifest.py:L54-L59@sha256:cc4a0f5dc5f9 ·
              authority-v2/proofs/gate-negative-fixtures.py:L77-L121@sha256:f14bc571beb7 (όλες οι μεταλλάξεις)"
   :is-it-in-the-known-defect-list :no)

  (:what "Ο ΙΣΧΥΡΙΣΜΟΣ «Καμία εξάρτηση από όνομα ή bit εκτέλεσης» ΕΙΝΑΙ ΨΕΥΔΗΣ ΣΤΟΝ ΙΔΙΟ ΤΟΝ
          ΚΩΔΙΚΑ ΠΟΥ ΤΟΝ ΔΙΑΤΥΠΩΝΕΙ. Η ταξινόμηση κώδικα ΕΚΤΟΣ του proofs/ γίνεται με
          `case $f in *.py|*.sh|*.lisp)` — δηλαδή ΑΚΡΙΒΩΣ με ευρετικό ΟΝΟΜΑΤΟΣ (κατάληξη).
          Αρχείο ΧΩΡΙΣ κατάληξη (π.χ. authority-v2/other/forgotten-proof) ή με .pl/.rb/.js/
          .bash/.mjs/.pm ΔΕΝ ταξινομείται καθόλου και διαφεύγει σιωπηλά — η ΑΚΡΙΒΩΣ κλάση που
          η διόρθωση υποτίθεται ότι εξάλειψε. Ο αντίπαλος (proof-census-adversarial-test.py)
          φυτεύει ΜΟΝΟ .py και .lisp, άρα δεν αγγίζει την κλάση."
   :severity :p1
   :evidence "authority-v2/run-proofs.sh:L40-L41@sha256:a47922d94bb5 authority-v2/run-proofs.sh:L43-L48@sha256:a47922d94bb5 (ο ισχυρισμός) · L71 (η υλοποίηση) ·
              authority-v2/PROOF-CENSUS.txt:L34-L36@sha256:331b0e5a3316 (ο ίδιος ισχυρισμός) ·
              authority-v2/proofs/proof-census-adversarial-test.py:L130-L164@sha256:0490322908af (τα strays)"
   :is-it-in-the-known-defect-list :no)

  (:what "ΑΣΥΜΜΕΤΡΙΑ PINNING ΜΕΣΑ ΣΤΟΝ ΙΔΙΟ ΕΛΕΓΧΟ. Το canonical profile ελέγχεται απέναντι σε
          ΚΑΡΦΩΜΕΝΟ sha256 — ρητό κλείσιμο ετυμηγορίας P1 του δημιουργού («φορτώνεται από
          αυθαίρετο pathname ΧΩΡΙΣ pinned digest ⇒ ένα ΔΙΑΦΟΡΕΤΙΚΟ profile με το σωστό
          profile-id μπορεί να γίνει δεκτό»). ΑΛΛΑ τα golden Merkle vectors — η ΜΟΝΗ εξωτερική
          είσοδος της verify_merkle_seat(), που τρέχει ΠΡΙΝ ΑΠΟ ΚΑΘΕ BYTE — διαβάζονται με
          σκέτο open() από ΠΑΡΑΜΕΤΡΟ pathname, ΧΩΡΙΣ pinned digest, ΧΩΡΙΣ anchor, ΧΩΡΙΣ
          O_NOFOLLOW: `def verify_merkle_seat(vectors_path=GOLDEN_VECTORS)`. Το αντιπαλικό
          harness δοκιμάζει την ΤΑΥΤΟΣΗΜΗ επίθεση για το profile και ΚΑΜΙΑ για τα vectors.
          Το αποτέλεσμα δεν είναι πλαστογράφηση ρίζας αλλά ΑΠΕΝΕΡΓΟΠΟΙΗΣΗ ΤΗΣ ΑΝΙΧΝΕΥΣΗΣ —
          ακριβώς της άμυνας που αντικατέστησε τον αποσυρμένο ισχυρισμό «δομικά αδύνατη»."
   :severity :p1
   :evidence "authority-v2/capture/capture.py:L72-L75@sha256:9593561c6c06 (GOLDEN_VECTORS) · L248,L255-261 ·
              L77-81,L648-656 (το profile ΕΙΝΑΙ pinned) ·
              authority-v2/proofs/capture-adversarial-test.py:L357-L364@sha256:664bc26df207 (η επίθεση ΜΟΝΟ για profile)"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΕΣΤ-ΤΑΥΤΟΛΟΓΙΑ ΜΕ ΔΙΠΛΗ ΕΔΡΑ ΣΤΟΥΣ ΜΑΡΤΥΡΕΣ. Το witness-quorum-test.py, που το matrix
          γραμμή 8 παρουσιάζει ως την ΕΚΤΕΛΕΣΜΕΝΗ απόδειξη της πολιτικής (και το witness-policy.sexp
          ως το implementation), ΔΕΝ ΑΝΟΙΓΕΙ ΠΟΤΕ το .sexp. Ξαναδηλώνει τις σταθερές inline
          (MAX_CHECKPOINT_AGE=86400, MAX_OBSERVATION_LAG=3600, REQUIRED_SIGNATURES=3) και
          ΞΑΝΑΥΛΟΠΟΙΕΙ την κρίση (evaluate_quorum). Τα «8 passed» επαληθεύουν το ΔΙΚΟ ΤΟΥΣ
          μοντέλο. Αλλαγή του :required-signatures από 3 σε 1 μέσα στο witness-policy.sexp
          ΔΕΝ κοκκινίζει τίποτα."
   :severity :p1
   :evidence "authority-v2/proofs/witness-quorum-test.py:L17-L19@sha256:909a8bccea9c · L52-78 · L1-117 (μηδέν αναφορές) ·
              authority-v2/log/witness-policy.sexp:L48-L49@sha256:68b5978b3e38 authority-v2/log/witness-policy.sexp:L63-L64@sha256:68b5978b3e38 ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L164-L170@sha256:7c82bef1def3"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ ΙΔΙΟ ΣΧΗΜΑ ΣΤΟΥΣ ΡΟΛΟΥΣ: το ceremony.sh καρφώνει τα 5 ονόματα ρόλων και τα 4
          delegations στον κώδικα (`new_key root; new_key release; …` και
          `for r in release targets snapshot timestamp`) και ΔΕΝ διαβάζει το ROLES-MODEL.sexp.
          Η «πρόβα 4 τελετών» επαληθεύει έναν ΔΕΥΤΕΡΟ, ανεξάρτητο ορισμό των ίδιων ρόλων, όχι
          το μοντέλο που το matrix δηλώνει ως implementation της γραμμής 9."
   :severity :p1
   :evidence "authority-v2/roles/ceremony.sh:L67-L67@sha256:c7fff2b735af authority-v2/roles/ceremony.sh:L70-L70@sha256:c7fff2b735af authority-v2/roles/ceremony.sh:L124-L124@sha256:c7fff2b735af ·
              authority-v2/roles/ROLES-MODEL.sexp:L28-L65@sha256:e12ce36e8b17 ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L181-L185@sha256:7c82bef1def3"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ ΜΟΝΑΔΙΚΟ ΥΠΟΓΕΓΡΑΜΜΕΝΟ ARTIFACT ΕΧΕΙ ΑΠΟΚΛΙΝΕΙ ΑΠΟ ΤΟ ΠΑΡΑΓΟΜΕΝΟ. Το
          fixtures/genesis-cert-fixture.json (η υπογραφή ΕΠΑΛΗΘΕΥΤΗΚΕ ΕΠΙΤΟΠΟΥ: openssl
          pkeyutl -verify ⇒ Signature Verified Successfully) φέρει source_commit
          57c0cd868c80f87df8e298c9aa75b8ccf2503391 ενώ το τρέχον draft φέρει
          b26abbd68caf49481714288f06bfc2cb387ecdd2. ΔΙΑΦΕΡΟΥΝ ΚΑΙ ΔΟΜΙΚΑ: στο fixture λείπουν
          τα πεδία historical_run_artifacts και legacy_release_count_by_naming, το
          legacy_releases είναι λίστα ΣΥΜΒΟΛΟΣΕΙΡΩΝ αντί λίστα ΑΝΤΙΚΕΙΜΕΝΩΝ, και διαφέρουν τα
          legacy_manifest_digest, new_verifier_result και known_divergences. Άρα η ΜΟΝΗ
          κρυπτογραφική δέσμευση της συστάδας πιστοποιεί ΑΛΛΟ σχήμα certificate από αυτό που
          παράγει ο κώδικας, και το fixture είναι ΜΗ ΕΠΑΝΥΠΟΓΡΑΨΙΜΟ εξ ορισμού."
   :severity :p1
   :evidence "authority-v2/fixtures/genesis-cert-fixture.json:L1-L1@sha256:22288c825837 ·
              authority-v2/fixtures/genesis-cert-fixture.sig ·
              authority-v2/fixtures/test-keys/genesis-test-ed25519.pub:L1-L3@sha256:79407cf2dbfb ·
              authority-v2/fixtures/test-keys/README.md:L10-L17@sha256:6d65cbac89b7 ·
              authority-v2/genesis/out/legacy-adoption-certificate.unsigned.json:L1-L1@sha256:5139d99fcef0"
   :is-it-in-the-known-defect-list :no)

  (:what "ΟΛΟΚΛΗΡΟ ΤΟ genesis/ ΕΙΝΑΙ ΕΚΤΟΣ ΚΑΘΕ ΠΥΛΗΣ. Τα 3 python αρχεία είναι ταξινομημένα
          `helper`, δηλαδή ο runner ΔΕΝ τα τρέχει ΠΟΤΕ (run-proofs.sh L120,L161). Μηχανικός
          έλεγχος σε ΟΛΟ το repo: 0 αναφορές σε «genesis-cert-fixture» και
          «legacy-adoption-certificate» εκτός του ίδιου του builder. Κανένα proof δεν
          επαληθεύει την υπογραφή του fixture, τη δέσμευση του certificate στο snapshot, ή
          την αναπαραγωγιμότητα του snapshot. Οι μόνες δεσμεύσεις που ελέγχθηκαν ελέγχθηκαν
          ΑΠΟ ΕΜΕΝΑ, χειροκίνητα."
   :severity :p1
   :evidence "authority-v2/PROOF-CENSUS.txt:L69-L72@sha256:331b0e5a3316 ·
              authority-v2/run-proofs.sh:L119-L125@sha256:a47922d94bb5 authority-v2/run-proofs.sh:L159-L161@sha256:a47922d94bb5 ·
              authority-v2/genesis/build-adoption-certificate.py:L45-L138@sha256:1b6defdfb37d"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ ΔΗΛΩΜΕΝΟ ΜΟΝΟΠΑΤΙ ΑΡΣΗΣ ΤΩΝ 7 :externally-blocked ΑΠΑΙΤΗΣΕΩΝ ΕΙΝΑΙ ΑΤΕΛΕΣ. Και τα
          δύο hermetic Dockerfiles κάνουν `COPY toolchain-sources/ /build/sources/` και μετά
          `sha256sum -c` σε fstar/karamel/everparse/perennial/goose/gotxn tarballs. Ο κατάλογος
          toolchain-sources/ ΔΕΝ ΥΠΑΡΧΕΙ πουθενά στο repo και ΚΑΝΕΝΑ άλλο αρχείο δεν τον
          αναφέρει (μηχανικός έλεγχος: μόνο τα δύο Dockerfiles). Άρα ακόμη και με συμπληρωμένα
          τα PIN-REQUIRED, η εντολή του matrix
          `docker build -f authority-v2/toolchain/everparse.Dockerfile --target cddl-gate .`
          αποτυγχάνει στο COPY: η ΠΡΟΜΗΘΕΙΑ των tarballs δεν έχει καμία ορισμένη διαδικασία,
          και το proof-manifest δηλώνει αυτά τα Dockerfiles ως :unblock-path και για τα 17 θεωρήματα."
   :severity :p1
   :evidence "authority-v2/toolchain/everparse.Dockerfile:L50-L54@sha256:b041f71c2b5b authority-v2/toolchain/everparse.Dockerfile:L64-L72@sha256:b041f71c2b5b ·
              authority-v2/toolchain/perennial.Dockerfile:L43-L47@sha256:0518176d8d72 authority-v2/toolchain/perennial.Dockerfile:L49-L57@sha256:0518176d8d72 ·
              authority-v2/proof-manifest.sexp:L20-L26@sha256:b56b4cbb392f ·
              authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L82-L82@sha256:7c82bef1def3 authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L153-L153@sha256:7c82bef1def3"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ delta23-evidence-bundle.sh ΔΗΛΩΝΕΙ ΤΗΝ ΥΠΟΧΡΕΩΣΗ ② ΩΣ «Η ΦΕΡΟΥΣΑ ΑΠΟΔΕΙΞΗ» ΚΑΙ ΤΗΝ
          ΠΑΡΑΛΕΙΠΕΙ ΧΩΡΙΣ ΚΟΣΤΟΣ. Αν δεν υπάρχει root/setpriv/unshare, τυπώνει «BLK» αλλά ΔΕΝ
          αυξάνει το f, ΔΕΝ μετράει blocked, και ΔΕΝ αλλάζει τον κωδικό εξόδου. Το script είναι
          εγγεγραμμένο ως `requires-sbcl` (ΟΧΙ requires-root), άρα ο runner το τρέχει χωρίς root
          και το μετράει PASSED ενώ η ίδια του η φέρουσα υποχρέωση δεν εκτελέστηκε. Αυτό είναι
          ΣΙΩΠΗΛΟ FALLBACK μέσα σε script που το ρητό του θέμα είναι η μη-σιωπηλότητα."
   :severity :p1
   :evidence "authority-v2/proofs/delta23-evidence-bundle.sh:L3-L4@sha256:eb0d61ed6b78 authority-v2/proofs/delta23-evidence-bundle.sh:L48-L61@sha256:eb0d61ed6b78 authority-v2/proofs/delta23-evidence-bundle.sh:L118-L119@sha256:eb0d61ed6b78 ·
              authority-v2/PROOF-CENSUS.txt:L64-L64@sha256:331b0e5a3316"
   :is-it-in-the-known-defect-list :no)

  (:what "verify-capability-closure.sh ΣΥΜΠΕΡΑΙΝΕΙ ΑΡΝΗΣΗ ΑΠΟ ΟΠΟΙΟΔΗΠΟΤΕ ΜΗ ΜΗΔΕΝΙΚΟ EXIT, όχι
          από EACCES. Η try_write() τρέχει `setpriv … /bin/sh -c \"printf x > path 2>/dev/null\"`
          με όλη την έξοδο σε /dev/null και επιστρέφει σκέτο exit status. Οποιαδήποτε αποτυχία
          του setpriv (nologin shell, αποτυχία --init-groups, απόν /bin/sh) διαβάζεται ως
          «ok producer ⇒ EACCES». Ο θετικός μάρτυρας μη-κενότητας υπάρχει ΜΟΝΟ για την ταυτότητα
          authority — οι δύο ΑΡΝΗΤΙΚΕΣ ταυτότητες δεν έχουν καμία απόδειξη ότι ο μηχανισμός τους
          δοκιμάστηκε καθόλου. Αντίθεση: το producer-os-boundary-test.sh ελέγχει ΑΡΙΘΜΗΤΙΚΟ
          errno (30 vs 13) ακριβώς για να αποκλείσει αυτή την κλάση."
   :severity :p1
   :evidence "authority-v2/proofs/verify-capability-closure.sh:L40-L45@sha256:a0eaba8f338a · L47-53 · L55-67 ·
              authority-v2/proofs/producer-os-boundary-test.sh:L108-L116@sha256:6e085a0beb91 (η ανώτερη μέθοδος, δίπλα)"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ ΛΕΞΙΛΟΓΙΟ ΑΠΟΡΡΙΨΕΩΝ ΤΟΥ ΠΡΩΤΟΚΟΛΛΟΥ ΔΕΝ ΣΥΜΦΩΝΕΙ ΜΕ ΤΟΝ ΚΩΔΙΚΑ ΚΑΙ ΚΑΝΕΝΑ GATE
          ΔΕΝ ΤΟ ΕΛΕΓΧΕΙ. Η CAPTURE-PROTOCOL.sexp δηλώνει 25 :rejection-reasons· η capture.py
          παράγει 44 διακριτούς λόγους. 21 παραγόμενοι ΔΕΝ είναι δηλωμένοι (anchor-stale,
          anchor-not-owned, capability-forgery, capability-immutable, canonical-profile-unpinned,
          canonical-profile-not-validated, cleanup-incomplete, set-mutated-during-capture,
          limit-exceeded, os-error, open-refused, quarantine-no-space, quarantine-preexisting,
          empty-candidate, canonical-missing, anchor-required, anchor-role-unknown,
          anchor-owner-mismatch, anchor-mount-mismatch, anchor-world-writable,
          anchor-group-world-writable). 2 δηλωμένοι ΔΕΝ παράγονται ΠΟΤΕ: :symlink-present και
          :declared-root-mismatch. Το :symlink-present είναι η ΕΠΙΚΕΦΑΛΗΣ άρνηση του βήματος 1
          του πρωτοκόλλου — στην πράξη ένα symlink μέσα στο candidate εμφανίζεται ως
          escapes-root μέσω της χαρτογράφησης ELOOP."
   :severity :p2
   :evidence "authority-v2/capture/CAPTURE-PROTOCOL.sexp:L63-L89@sha256:e119bee77c97 (L65 :symlink-present,
              L72 :declared-root-mismatch) · authority-v2/capture/capture.py:L155-L156@sha256:9593561c6c06 (ELOOP ⇒
              escapes-root) · L111-118 · L317-360 · L614-623"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ canonical-profile.json ΔΕΙΧΝΕΙ ΣΕ ΑΝΥΠΑΡΚΤΟ ΜΟΝΟΠΑΤΙ ΚΑΙ ΤΟ PINNING ΤΟ ΠΑΓΩΝΕΙ:
          λέει ότι η ταύτιση ελέγχεται από «authority-v2/tests/capture-seat-differential-test.sh»
          ενώ το αρχείο ζει στο authority-v2/proofs/. Επειδή το profile είναι PINNED BY SHA256
          μέσα στην capture.py, η διόρθωση του σχολίου απαιτεί ΚΑΙ αλλαγή του καρφωμένου digest —
          δηλαδή το λάθος είναι κρυπτογραφικά κλειδωμένο."
   :severity :p2
   :evidence "authority-v2/capture/canonical-profile.json:L3-L3@sha256:7c1005aec472 ·
              authority-v2/capture/CAPTURE-PROTOCOL.sexp:L135-L135@sha256:e119bee77c97 (σωστό μονοπάτι) ·
              authority-v2/capture/capture.py:L77-L81@sha256:9593561c6c06"
   :is-it-in-the-known-defect-list :no)

  (:what "Η capture() ΑΝΤΙΚΑΘΙΣΤΑ ΤΗΝ ΑΙΤΙΑ ΤΗΣ ΑΡΝΗΣΗΣ ΟΤΑΝ ΑΠΟΤΥΓΧΑΝΕΙ Ο ΚΑΘΑΡΙΣΜΟΣ. Το
          `finally` σηκώνει CaptureRefused('cleanup-incomplete')· αν η αρχική άρνηση ήταν
          επίσης CaptureRefused (π.χ. hardlink-present σε πραγματική επίθεση), ο καλών βλέπει
          «cleanup-incomplete» και η αιτία της επίθεσης μένει μόνο ως __context__. Fail-closed
          διατηρείται, η ΔΙΑΓΝΩΣΗ όχι."
   :severity :p2
   :evidence "authority-v2/capture/capture.py:L981-L991@sha256:9593561c6c06"
   :is-it-in-the-known-defect-list :no)

  (:what "ΝΕΚΡΟΙ HELPERS ΠΟΥ Η ΑΠΟΓΡΑΦΗ ΝΟΜΙΜΟΠΟΙΕΙ ΜΟΝΙΜΑ. Η απογραφή ελέγχει ΝΕΚΡΕΣ ΕΓΓΡΑΦΕΣ
          (εγγραφή χωρίς αρχείο) αλλά ΟΧΙ νεκρά αρχεία (helper χωρίς καλούντα). Μηχανικός
          έλεγχος: authority-v2/tests/probe-attest-refusal.lisp (35 γραμμές) και
          authority-v2/tests/probe-producer-under-uid.lisp (50 γραμμές) ΔΕΝ καλούνται από
          ΚΑΝΕΝΑ αρχείο του repo. Το δεύτερο είναι λειτουργικά αντικατεστημένο από το
          probe-producer-real.lisp που ΚΑΛΕΙΤΑΙ όντως."
   :severity :p2
   :evidence "authority-v2/tests/probe-attest-refusal.lisp:L1-L35@sha256:deb0595fdfb0 ·
              authority-v2/tests/probe-producer-under-uid.lisp:L1-L50@sha256:407bb5a0ec69 ·
              authority-v2/tests/probe-producer-real.lisp:L1-L33@sha256:c29440c0d33c (ο ενεργός) ·
              authority-v2/PROOF-CENSUS.txt:L31-L36@sha256:331b0e5a3316 authority-v2/PROOF-CENSUS.txt:L75-L75@sha256:331b0e5a3316 authority-v2/PROOF-CENSUS.txt:L83-L83@sha256:331b0e5a3316 · authority-v2/run-proofs.sh:L105-L105@sha256:a47922d94bb5"
   :is-it-in-the-known-defect-list :no)

  (:what "ΤΟ MATRIX ΔΙΝΕΙ ΔΥΟ ΔΙΑΦΟΡΕΤΙΚΟΥΣ ΑΡΙΘΜΟΥΣ ΓΙΑ ΤΑ ΙΔΙΑ TESTS ΧΩΡΙΣ ΣΥΜΦΙΛΙΩΣΗ:
          γραμμή 5 (2026-08-01) «level7-disarm 20/0 · transparency-log 21/0» ενώ γραμμή 12
          (2026-07-31) «level7-disarm 9/0 · transparency-log 23/0». Το transparency-log
          ΜΕΙΩΝΕΤΑΙ από 23 σε 21 χωρίς εξήγηση. Επιπλέον η γραμμή 5 απαριθμεί ΟΝΟΜΑΣΤΙΚΑ 11
          από τις 14 αποδείξεις που πέρασαν — λείπουν τα delta23-evidence-bundle.sh,
          verify-completion-matrix.py και verify-proof-manifest.py."
   :severity :p2
   :evidence "authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L115-L122@sha256:7c82bef1def3 · L246 ·
              authority-v2/PROOF-CENSUS.txt:L51-L66@sha256:331b0e5a3316 (15 αποδείξεις)"
   :is-it-in-the-known-defect-list :no)

  (:what "Το ceremony.sh, αν κληθεί ΧΩΡΙΣ LAWMAX_CEREMONY_WORK, γράφει ed25519 ΙΔΙΩΤΙΚΑ ΚΛΕΙΔΙΑ
          ΜΕΣΑ στο δέντρο του repository (authority-v2/fixtures/ceremony). Μόνο το
          ceremony-rehearsal-test.sh θέτει mktemp -d· η άμεση κλήση — που η απογραφή επιτρέπει
          ρητά ως tool-declared — δεν το κάνει."
   :severity :p2
   :evidence "authority-v2/roles/ceremony.sh:L25-L25@sha256:c7fff2b735af authority-v2/roles/ceremony.sh:L46-L51@sha256:c7fff2b735af ·
              authority-v2/proofs/ceremony-rehearsal-test.sh:L5-L5@sha256:65fe29eeef29 ·
              authority-v2/PROOF-CENSUS.txt:L42-L44@sha256:331b0e5a3316"
   :is-it-in-the-known-defect-list :no)

  (:what "verify-capability-closure.sh: στις ΘΕΤΙΚΕΣ περιπτώσεις καθαρίζει τα probe αρχεία ΩΣ Ο
          ΧΡΗΣΤΗΣ με `|| true`, ενώ στις ΑΡΝΗΤΙΚΕΣ ως root. Αν το rm ως χρήστης αποτύχει, το
          .cap-probe-authority μένει ΜΕΣΑ στο authority store και καμία επόμενη εκτέλεση δεν
          το καταγγέλλει — ένα ξένο αρχείο επιβιώνει σιωπηλά στον χώρο της αυθεντίας."
   :severity :p2
   :evidence "authority-v2/proofs/verify-capability-closure.sh:L48-L53@sha256:a0eaba8f338a authority-v2/proofs/verify-capability-closure.sh:L56-L58@sha256:a0eaba8f338a authority-v2/proofs/verify-capability-closure.sh:L62-L64@sha256:a0eaba8f338a authority-v2/proofs/verify-capability-closure.sh:L70-L75@sha256:a0eaba8f338a"
   :is-it-in-the-known-defect-list :no)

  (:what "Ο έλεγχος παλινδρόμησης ⑥ του capture-mountpoint-test.sh είναι ΠΕΡΙΒΑΛΛΟΝΤΙΚΑ
          ΕΞΑΡΤΩΜΕΝΟΣ και παράγει FAIL (όχι BLOCKED) όταν το περιβάλλον δεν έχει το mountpoint
          που χρειάζεται: `ACCEPTED) no \"η παλιά λογική ΔΕΝ απορρίπτει εδώ\"`. Ένα νόμιμο
          περιβάλλον χωρίς ξεχωριστό fs στο /tmp κοκκινίζει τη σουίτα για λόγο άσχετο με τη
          σωστότητα του κώδικα."
   :severity :p2
   :evidence "authority-v2/proofs/capture-mountpoint-test.sh:L113-L142@sha256:348977712438"
   :is-it-in-the-known-defect-list :no)

  (:what "Οι γραμμές 5 και 12 του matrix δηλώνουν implementation ΕΚΤΟΣ της συστάδας
          (systems/orchestrator-epistemic/*.lisp, tests/*.lisp, docker/suite-census.txt).
          Επαλήθευσα ότι ΟΛΑ ΤΑ 7 ΑΡΧΕΙΑ ΥΠΑΡΧΟΥΝ στο παγωμένο δέντρο, αλλά το περιεχόμενό
          τους είναι εκτός της συστάδας authority-v2 και δεν κρίνεται εδώ. Κανένας μηχανικός
          έλεγχος δεν επιβεβαιώνει ούτε καν την ΥΠΑΡΞΗ αυτών των μονοπατιών."
   :severity :p2
   :evidence "authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L110-L112@sha256:7c82bef1def3 authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:L239-L243@sha256:7c82bef1def3 ·
              authority-v2/proofs/verify-completion-matrix.py:L22-L24@sha256:ce297276ed75 (το :implementation
              ελέγχεται μόνο ως ΠΑΡΟΥΣΙΑ ΠΕΔΙΟΥ)"
   :is-it-in-the-known-defect-list :no)

  (:what "probe-producer-real.lisp και probe-producer-under-uid.lisp αποδίδουν ΚΑΘΕ error στον
          πυρήνα: `(error () \"REFUSED-BY-KERNEL\")`. Οποιοδήποτε σφάλμα (λάθος pathname, απούσα
          συνάρτηση, σφάλμα φόρτωσης) αναφέρεται ως άρνηση του kernel — ίδια κλάση με το
          verify-capability-closure. Το περιβάλλον όμως μετριάζει: το ro mount επιβεβαιώνεται
          ανεξάρτητα από το /proc/self/mountinfo πριν τρέξει το probe."
   :severity :p2
   :evidence "authority-v2/tests/probe-producer-real.lisp:L26-L31@sha256:c29440c0d33c ·
              authority-v2/tests/probe-producer-under-uid.lisp:L40-L47@sha256:407bb5a0ec69 ·
              authority-v2/proofs/producer-os-boundary-test.sh:L144-L152@sha256:6e085a0beb91"
   :is-it-in-the-known-defect-list :no))

 ;; ═══════════════════════════════════════════════════════════════════════════
 :hidden-execution-paths
 ((:path "authority-v2/proofs/producer-os-boundary-test.sh ΕΚΤΕΛΕΙ ΤΟΝ ΕΓΚΑΤΑΣΤΑΤΗ identities.sh"
   :trigger "αν λείπει ο χρήστης lawmax-producer, το ΙΔΙΟ ΤΟ PROOF τρέχει
             `bash authority-v2/capability/identities.sh` ΧΩΡΙΣ ΟΡΙΣΜΑΤΑ"
   :why-hidden "μια «απόδειξη» δημιουργεί ΜΟΝΙΜΟΥΣ system users (uid 11001/11002/11003, gid 11010)
                και καταλόγους στο /var/lib/lawmax/ του host· η απογραφή το ταξινομεί ως
                requires-root proof, όχι ως tool-requires-root"
   :evidence "authority-v2/proofs/producer-os-boundary-test.sh:L34-L35@sha256:6e085a0beb91 ·
              authority-v2/capability/identities.sh:L73-L81@sha256:814455cc6b0a")
  (:path "authority-v2/proofs/delta23-evidence-bundle.sh ΕΚΤΕΛΕΙ ΔΥΟ ΑΛΛΕΣ ΑΠΟΔΕΙΞΕΙΣ ΜΕΣΑ ΤΟΥ"
   :trigger "καλεί producer-os-boundary-test.sh (②) και capture-adversarial-test.py (⑦)"
   :why-hidden "και οι δύο είναι ΗΔΗ ξεχωριστές εγγραφές της απογραφής· άρα τρέχουν δύο φορές
                και μετρώνται σε δύο διαφορετικά ισοζύγια, με το εσωτερικό αποτέλεσμα να
                συμπτύσσεται σε ΕΝΑ assertion"
   :evidence "authority-v2/proofs/delta23-evidence-bundle.sh:L52-L61@sha256:eb0d61ed6b78 authority-v2/proofs/delta23-evidence-bundle.sh:L110-L115@sha256:eb0d61ed6b78 ·
              authority-v2/PROOF-CENSUS.txt:L52-L52@sha256:331b0e5a3316 authority-v2/PROOF-CENSUS.txt:L56-L56@sha256:331b0e5a3316 authority-v2/PROOF-CENSUS.txt:L64-L64@sha256:331b0e5a3316")
  (:path "authority-v2/proofs/docker-e2e-test.sh ΕΚΤΕΛΕΙΤΑΙ ΔΥΟ ΦΟΡΕΣ ΑΝΑ run-all.sh"
   :trigger "run-all.sh καλεί run-proofs.sh (που το τρέχει ως requires-docker εγγραφή) ΚΑΙ ΜΕΤΑ
             το ξανακαλεί ρητά"
   :why-hidden "μετριέται στο ισοζύγιο των 15 αποδείξεων ΚΑΙ ξεχωριστά στο τελικό ΣΥΝΟΛΟ"
   :evidence "authority-v2/run-all.sh:L40-L41@sha256:3c2ba7169352 authority-v2/run-all.sh:L60-L61@sha256:3c2ba7169352 · authority-v2/PROOF-CENSUS.txt:L55-L55@sha256:331b0e5a3316")
  (:path "authority-v2/roles/ceremony.sh ΓΡΑΦΕΙ ΙΔΙΩΤΙΚΑ ΚΛΕΙΔΙΑ ΣΤΟ REPO ΩΣ DEFAULT"
   :trigger "άμεση κλήση χωρίς LAWMAX_CEREMONY_WORK (επιτρεπτή: tool-declared)"
   :why-hidden "ο προορισμός είναι $ROOT/authority-v2/fixtures/ceremony — μέσα στο εργαζόμενο
                δέντρο· ο δημιουργός θα το ανακάλυπτε μόνο από το git status"
   :evidence "authority-v2/roles/ceremony.sh:L25-L25@sha256:c7fff2b735af authority-v2/roles/ceremony.sh:L46-L51@sha256:c7fff2b735af")
  (:path "authority-v2/tests/build-authority-core.lisp ΦΟΡΤΩΝΕΙ ΟΛΟ ΤΟΝ ΠΑΡΑΓΩΓΙΚΟ ΠΥΡΗΝΑ"
   :trigger "καλείται από 3 σημεία (run-all, seat-differential, producer-os-boundary)"
   :why-hidden "μια συστάδα που δηλώνει ότι ο producer είναι ΜΗ ΕΜΠΙΣΤΟΣ φορτώνει το
                orchestrator-cli μέσα στη διαδικασία απόδειξης και αποθηκεύει saved core"
   :evidence "authority-v2/tests/build-authority-core.lisp:L4-L14@sha256:b8c377fdd104 · authority-v2/run-all.sh:L44-L54@sha256:3c2ba7169352")
  (:path "capture-mutation-witness.py ΤΡΕΧΕΙ 22 ΦΟΡΕΣ ΤΟ ΠΛΗΡΕΣ ADVERSARIAL HARNESS"
   :trigger "1 θετικός μάρτυρας + 21 μεταλλάξεις, καθεμία με timeout 1800s"
   :why-hidden "το κόστος (έως ~11 ώρες θεωρητικά) δεν δηλώνεται πουθενά· ένα timeout
                καταγράφεται ως rc=124 ⇒ «ΣΚΟΤΩΘΗΚΕ», δηλαδή ένα timeout μετράει ως ΦΟΝΟΣ"
   :evidence "authority-v2/proofs/capture-mutation-witness.py:L216-L219@sha256:9b3a416ab601 authority-v2/proofs/capture-mutation-witness.py:L248-L252@sha256:9b3a416ab601 authority-v2/proofs/capture-mutation-witness.py:L263-L264@sha256:9b3a416ab601")
  (:path "verify_merkle_seat(vectors_path=…) ΔΕΧΕΤΑΙ ΑΥΘΑΙΡΕΤΟ PATHNAME"
   :trigger "οποιοσδήποτε caller της βιβλιοθήκης capture μπορεί να δώσει άλλα vectors"
   :why-hidden "η δημόσια υπογραφή προσφέρει παράκαμψη της ΜΟΝΗΣ ανίχνευσης Merkle απόκλισης,
                σε αντίθεση με το _require_profile() που κλείνει την ταυτόσημη τρύπα"
   :evidence "authority-v2/capture/capture.py:L248-L248@sha256:9593561c6c06 · L614-623 (ο φρουρός που ΥΠΑΡΧΕΙ για το profile)"))

 ;; ═══════════════════════════════════════════════════════════════════════════
 :duplicate-seats
 ((:concept "ΠΟΛΙΤΙΚΗ ΚΒΟΡΟΥΜ/ΦΡΕΣΚΑΔΑΣ ΜΑΡΤΥΡΩΝ — δύο ανεξάρτητοι ορισμοί, κανένας σύνδεσμος"
   :seats ("authority-v2/log/witness-policy.sexp:L47-L69@sha256:68b5978b3e38"
           "authority-v2/proofs/witness-quorum-test.py:L17-L19@sha256:909a8bccea9c authority-v2/proofs/witness-quorum-test.py:L52-L78@sha256:909a8bccea9c"))
  (:concept "ΣΥΝΟΛΟ ΡΟΛΩΝ ΚΑΙ DELEGATIONS — μοντέλο vs καρφωμένος κώδικας τελετής"
   :seats ("authority-v2/roles/ROLES-MODEL.sexp:L28-L65@sha256:e12ce36e8b17"
           "authority-v2/roles/ceremony.sh:L67-L67@sha256:c7fff2b735af authority-v2/roles/ceremony.sh:L70-L70@sha256:c7fff2b735af authority-v2/roles/ceremony.sh:L124-L124@sha256:c7fff2b735af"))
  (:concept "MTH / Merkle αλγόριθμος — ΠΕΝΤΕ υλοποιήσεις (οι τρεις είναι ΣΚΟΠΙΜΕΣ ως διαφορικές)"
   :seats ("authority-v2/capture/capture.py:L196-L205@sha256:9593561c6c06 (_mth_recursive)"
           "authority-v2/capture/capture.py:L208-L225@sha256:9593561c6c06 (_mth_streaming)"
           "authority-v2/genesis/legacy-snapshot.py:L57-L71@sha256:4b260f80ea54 (mth — ΤΕΤΑΡΤΗ, χωρίς διαφορικό έλεγχο)"
           "deployment/verify/verify-merkle.py (ανεξάρτητη, καλείται από το harness)"
           "orchestrator.merkle:merkle-root-of-files (παραγωγικός Lisp πυρήνας, μέσω probe)"))
  (:concept "ΤΑ ΠΡΩΤΟΓΟΝΑ ΤΟΥ ΣΧΗΜΑΤΟΣ (sha256-digest, ed25519-sig/pub, sequence-no,
             utc-seconds, profile-id) ορίζονται ΔΥΟ ΦΟΡΕΣ"
   :seats ("authority-v2/schema/transition-certificate.cddl:L20-L25@sha256:909a91aa4bac"
           "authority-v2/schema/state.cddl:L9-L14@sha256:77f42d146a16"))
  (:concept "ΤΟ CANONICAL ΣΥΝΟΛΟ — json profile ΚΑΙ +EPISTEMIC-CANONICAL-FILES+ του πυρήνα
             (ΔΗΛΩΜΕΝΗ διπλή έδρα ΜΕ εκτελεστική γέφυρα — η μόνη γεφυρωμένη)"
   :seats ("authority-v2/capture/canonical-profile.json:L5-L16@sha256:7c1005aec472"
           "systems/orchestrator-epistemic/release-manifest.lisp μέσω
            authority-v2/tests/probe-canonical-files.lisp:L15-L22@sha256:943a1770c0a4"))
  (:concept "PROBE ΤΟΥ PRODUCER ΥΠΟ UID — δύο σχεδόν ταυτόσημα αρχεία, το ένα νεκρό"
   :seats ("authority-v2/tests/probe-producer-real.lisp:L1-L33@sha256:c29440c0d33c (ενεργό)"
           "authority-v2/tests/probe-producer-under-uid.lisp:L1-L50@sha256:407bb5a0ec69 (κανένας καλών)"))
  (:concept "ΔΗΛΩΣΗ ΓΝΩΣΤΩΝ ΑΠΟΚΛΙΣΕΩΝ — τρεις έδρες με ΔΙΑΦΟΡΕΤΙΚΟ περιεχόμενο"
   :seats ("authority-v2/genesis/genesis-policy.sexp:L65-L78@sha256:9a04b3cd8970 (3 divergences)"
           "authority-v2/genesis/build-adoption-certificate.py:L88-L113@sha256:1b6defdfb37d (5 divergences)"
           "authority-v2/fixtures/genesis-cert-fixture.json (παλαιότερη διατύπωση)"))
  (:concept "ΕΚΤΕΛΕΣΗ ΤΟΥ docker-e2e — καταγράφεται δύο φορές ανά run-all"
   :seats ("authority-v2/run-proofs.sh:L159-L184@sha256:a47922d94bb5 (ως εγγραφή απογραφής)"
           "authority-v2/run-all.sh:L60-L61@sha256:3c2ba7169352 (ρητή δεύτερη κλήση)")))

 ;; ═══════════════════════════════════════════════════════════════════════════
 :unknowns
 ("Αν το ΠΕΡΙΕΧΟΜΕΝΟ των αρχείων εκτός συστάδας που δηλώνει το matrix (systems/orchestrator-epistemic/
   authority-boundary.lisp, deploy-epistemic.lisp, transparency-log.lisp, tests/level7-disarm-test.lisp,
   tests/release-authority-test.lisp, tests/transparency-log-test.lisp, docker/suite-census.txt)
   στηρίζει τις γραμμές 5 και 12 — ΕΠΑΛΗΘΕΥΣΑ ΜΟΝΟ ΟΤΙ ΥΠΑΡΧΟΥΝ"
  "Αν τα legacy-tlog fixtures «παρήχθησαν ΑΝΕΞΑΡΤΗΤΑ από τον αφαιρεμένο writer» — κανένας
   generator δεν είναι committed· ο ισχυρισμός είναι ανεπαλήθευτος με στατική ανάγνωση"
  "Αν το legacy-snapshot.py είναι ΠΡΑΓΜΑΤΙΚΑ ντετερμινιστικό στο σημερινό δέντρο — δεν το
   εκτέλεσα· η ασυμφωνία του legacy_manifest_digest ΔΕΝ αποδεικνύει μη-ντετερμινισμό, μόνο
   ότι ο snapshot και το certificate δεν παρήχθησαν στο ίδιο πέρασμα"
  "Ο πραγματικός αριθμός assertions του producer-topology-test.py (δηλωμένος 24) — εξαρτάται
   από το πλήθος services του docker-compose.yml που είναι ΕΚΤΟΣ της συστάδας"
  "Αν τα δηλωμένα actual-result του matrix (ημερομηνίες 2026-07-31 και 2026-08-01) αντιστοιχούν
   σε πραγματικές εκτελέσεις — κανένα log, transcript ή hash εκτέλεσης δεν είναι committed"
  "Αν το everparse.sh --cddl είναι έγκυρη επίκληση του EverParse toolchain — δεν το κρίνω,
   δεν υπάρχει τρόπος να ελεγχθεί χωρίς το toolchain"
  "Αν το repo guard `*.key` υπάρχει όντως (αναφέρεται στο authority-v2/fixtures/test-keys/README.md:L10-L11@sha256:6d65cbac89b7)
   — δεν το αναζήτησα εκτός της συστάδας"
  "Αν το LAWMAX_AUTHORITY_UID/PRODUCER_UID/READER_UID αναφέρονται όντως «αυτούσια στο
   docker-compose.yml» όπως ισχυρίζεται το authority-v2/capability/identities.sh:L44-L45@sha256:814455cc6b0a — το compose είναι εκτός συστάδας"))
