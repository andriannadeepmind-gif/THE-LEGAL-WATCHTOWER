;;;; authority-v2/capture/CAPTURE-PROTOCOL.sexp
;;;; ============================================================================
;;;; CANDIDATE CAPTURE — ΤΟ candidates/ ΕΙΝΑΙ ΕΧΘΡΙΚΗ ΜΕΤΑΒΛΗΤΗ ΕΙΣΟΔΟΣ
;;;; ============================================================================
;;;; ΔΙΟΡΘΩΣΗ ΔΗΜΙΟΥΡΓΟΥ: «Ο producer είναι ιδιοκτήτης του candidates/, άρα δεν
;;;; πρέπει να ονομαστεί immutable.» ΟΡΘΟ ΚΑΙ ΚΡΙΣΙΜΟ. Το προηγούμενο κείμενό
;;;; μου έλεγε «immutable candidate bundle» — ΛΑΘΟΣ: ο κάτοχος ενός καταλόγου
;;;; μπορεί πάντα να τον αλλάξει. Ο χαρακτηρισμός αποσύρεται παντού.
;;;;
;;;; ΤΟ ΜΟΝΤΕΛΟ ΑΠΕΙΛΗΣ: ο producer είναι ΜΗ ΕΜΠΙΣΤΟΣ και ΕΝΕΡΓΟΣ αντίπαλος.
;;;; Μπορεί: να αλλάξει bytes ΜΕΤΑ τον έλεγχο και ΠΡΙΝ τη χρήση (TOCTOU), να
;;;; βάλει symlink που δείχνει εκτός του candidate root, hardlink σε
;;;; authoritative αρχείο, path με «..», ονόματα που ξεφεύγουν από κανονικοποίηση,
;;;; ή να αντικαταστήσει ολόκληρο τον κατάλογο ενώ διαβάζουμε.
;;;;
;;;; Η ΑΠΑΝΤΗΣΗ: Η K ΔΕΝ ΤΡΕΧΕΙ ΠΟΤΕ ΠΑΝΩ ΣΤΟ candidates/. Τρέχει πάνω σε
;;;; ΣΥΛΛΗΦΘΕΝ SNAPSHOT μέσα σε ιδιωτικό authority quarantine.

(:lawmax-capture-protocol/1

 :assurance-status :under-construction
 :threat-model :producer-is-active-adversary
 :retracted-claim "«immutable candidate bundle» — ΑΠΟΣΥΡΘΗΚΕ: ο producer είναι
                   ιδιοκτήτης του candidates/ και μπορεί να το αλλάξει ανά πάσα
                   στιγμή. Ο μόνος αμετάβλητος είναι ο ΣΥΛΛΗΦΘΕΙΣ snapshot."

 ;; ── ΤΑ ΠΕΝΤΕ ΒΗΜΑΤΑ, ΜΕ ΑΥΤΗ ΤΗ ΣΕΙΡΑ ────────────────────────────────────
 :steps
 ((:n 1 :id :refuse-hostile-entries
   :statement "ΑΡΝΗΣΗ symlinks, hardlinks (nlink>1), path traversal, απόλυτων
               paths, κενών/«.»/«..» συνιστωσών, NUL, και ΚΑΘΕ non-regular file
               (device/fifo/socket)"
   :rationale "ένα symlink μέσα στο candidate μπορεί να δείχνει στο authority
               store· ένα hardlink μπορεί να μοιράζεται inode με authoritative
               αρχείο· το «..» ξεφεύγει από το root")
  (:n 2 :id :open-beneath-root-only
   :statement "ΚΑΘΕ άνοιγμα γίνεται ΜΟΝΟ beneath του candidate root, με
               O_NOFOLLOW σε κάθε συνιστώσα (openat + resolve beneath)"
   :rationale "η επαλήθευση path ΠΡΙΝ το open είναι TOCTOU· η επιβολή πρέπει να
               γίνεται ΣΤΟ ΙΔΙΟ syscall")
  (:n 3 :id :copy-to-private-quarantine
   :statement "ΑΝΤΙΓΡΑΦΗ σε ιδιωτικό authority quarantine (mode 0700, ιδιοκτησία
               authority, ΕΚΤΟΣ κάθε producer-writable μονοπατιού) ΠΡΙΝ από
               οποιαδήποτε κρίση"
   :rationale "από τη στιγμή της αντιγραφής και μετά, ο producer ΔΕΝ μπορεί να
               αλλάξει αυτό που κρίνεται — το TOCTOU παύει να υπάρχει")
  (:n 4 :id :recompute-in-quarantine
   :statement "census ΚΑΙ ΟΙ ΔΥΟ ρίζες ΕΠΑΝΥΠΟΛΟΓΙΖΟΝΤΑΙ ΜΕΣΑ στο quarantine, με
               ΞΑΝΑΔΙΑΒΑΣΜΑ ΚΑΘΕ byte από το ΑΝΤΙΓΡΑΦΟ — ΠΟΤΕ από δηλώσεις του
               producer ΚΑΙ ΠΟΤΕ από τα bytes που διαβάστηκαν στη ΦΑΣΗ Α"
   :rationale "ό,τι δηλώνει ο producer είναι ισχυρισμός, όχι δεδομένο· και ό,τι
               διαβάστηκε ΑΠΟ ΤΗΝ ΕΧΘΡΙΚΗ ΠΗΓΗ δεν επιτρέπεται να γίνει δέσμευση.
               ΔΥΟ ΑΥΣΤΗΡΑ ΔΙΑΚΡΙΤΕΣ ΦΑΣΕΙΣ: Α = αντιγραφή ΧΩΡΙΣ κανένα hash·
               Β = μέτρηση ΑΠΟΚΛΕΙΣΤΙΚΑ από το quarantine. Η διασταύρωση
               (path,size) των δύο φάσεων ⇒ quarantine-diverged σε κάθε απόκλιση
               (πιάνει μερική εγγραφή/ENOSPC). Έτσι η κλάση «hash από εχθρικά
               bytes» δεν φυλάσσεται — ΔΕΝ ΥΠΑΡΧΕΙ ως δυνατότητα.")
  (:n 5 :id :k-on-captured-snapshot-only
   :statement "η K εκτελείται ΑΠΟΚΛΕΙΣΤΙΚΑ πάνω στο συλληφθέν snapshot"
   :rationale "η καθαρότητα της K προϋποθέτει ΑΜΕΤΑΒΛΗΤΗ είσοδο· το
               candidates/ δεν είναι αμετάβλητο, το quarantine είναι"))

 ;; ── ΤΙ ΑΠΟΡΡΙΠΤΕΤΑΙ ΚΑΙ ΜΕ ΠΟΙΟ ΟΝΟΜΑ ────────────────────────────────────
 :rejection-reasons
 ((:id :symlink-present        :detail "οποιοδήποτε symlink εντός candidate")
  (:id :hardlink-present       :detail "regular file με nlink > 1")
  (:id :path-traversal         :detail "συνιστώσα «..» ή απόλυτο path")
  (:id :non-regular-file       :detail "device/fifo/socket/άλλο")
  (:id :escapes-root           :detail "το πραγματικό realpath βγαίνει εκτός root")
  (:id :nul-or-empty-component :detail "NUL byte ή κενή συνιστώσα στο path")
  (:id :mutated-during-capture :detail "τα bytes άλλαξαν μεταξύ δύο αναγνώσεων")
  (:id :declared-root-mismatch :detail "ο δηλωμένος root ≠ ο επανυπολογισμένος")
  (:id :short-write            :detail "η os.write έγραψε λιγότερα από όσα ζητήθηκαν")
  (:id :quarantine-diverged    :detail "ό,τι γράφτηκε (ΦΑΣΗ Α) ≠ ό,τι μετρήθηκε (ΦΑΣΗ Β)")
  (:id :quarantine-corrupt     :detail "μη κανονικό αρχείο ή nlink≠1 ΜΕΣΑ στο quarantine")
  (:id :merkle-seat-unverified :detail "τα committed golden vectors δεν διαβάστηκαν/δεν ταιριάζει το profile")
  (:id :merkle-seat-divergence :detail "τα πρωτόγονα ΑΥΤΗΣ της υλοποίησης ≠ committed vectors")
  (:id :openat2-unavailable    :detail "ο πυρήνας δεν υποστηρίζει openat2 — ΚΑΜΙΑ σιωπηλή υποβάθμιση")
  (:id :symlink-in-anchor      :detail "symlink σε ΟΠΟΙΑΔΗΠΟΤΕ συνιστώσα της άγκυρας (inbox/vault)")
  (:id :anchor-not-absolute    :detail "η άγκυρα δεν είναι απόλυτο μονοπάτι")
  (:id :non-utf8-name          :detail "όνομα αρχείου που ΔΕΝ είναι έγκυρο UTF-8")
  (:id :fd-exhausted           :detail "EMFILE/ENFILE — ΕΛΕΓΧΟΜΕΝΗ άρνηση, ποτέ ακατέργαστη εξαίρεση")
  (:id :io-error               :detail "EIO κατά την ανάγνωση/εγγραφή")
  (:id :quarantine-read-only   :detail "EROFS στο quarantine")
  (:id :fixed-point-violation  :detail "η ΔΕΥΤΕΡΗ πλήρης μέτρηση διαφέρει από την πρώτη")
  (:id :merkle-internal-divergence :detail "οι ΔΥΟ αλγόριθμοι MTH διαφώνησαν")
  (:id :canonical-profile-unreadable :detail "το καρφωμένο canonical profile δεν διαβάζεται")
  (:id :canonical-profile-invalid    :detail "κενή λίστα / λάθος id / μη έγκυρη εγγραφή")
  (:id :canonical-profile-duplicate  :detail "διπλότυπο canonical αρχείο ⇒ δύο ρίζες για τα ΙΔΙΑ bytes"))

 ;; ── ΑΓΚΥΡΩΣΗ: ΚΑΝΕΝΑ ΑΥΘΑΙΡΕΤΟ PATHNAME ────────────────────────────────
 :anchoring
 (:statement "Candidate και quarantine ΔΕΝ δίνονται ως αυθαίρετα μονοπάτια αλλά ως
              ΟΝΟΜΑΤΑ μέσα σε ΕΜΠΙΣΤΑ parent dirfds. Οι άγκυρες (inbox, vault)
              ανοίγονται με διάσχιση ΚΑΘΕ συνιστώσας από το «/» με openat2
              RESOLVE_STRICT."
  :closes "Εύρημα δημιουργού: «ενδιάμεσο symlink στο ίδιο το candidate_root έγινε
           δεκτό — το openat2 προστατεύει τους απογόνους, όχι τον αρχικό αυθαίρετο
           pathname»."
  :rejection :symlink-in-anchor)

 ;; ── CANONICAL PROFILE: ΥΠΟΧΡΕΩΤΙΚΟ, ΚΑΡΦΩΜΕΝΟ, ΜΟΝΑΔΙΚΟ ────────────────
 :canonical-profile
 (:file "authority-v2/capture/canonical-profile.json"
  :id "lawmax-candidate-canonical-v1"
  :mirrors "orchestrator.epistemic::+EPISTEMIC-CANONICAL-FILES+ — η ταύτιση
            ΕΛΕΓΧΕΤΑΙ εκτελεστικά (capture-seat-differential-test.sh ①), δεν
            υπόσχεται σχόλιο."
  :rules ("ΥΠΟΧΡΕΩΤΙΚΟ — release_root ΔΕΝ είναι ΠΟΤΕ None"
          "ΧΩΡΙΣ διπλότυπα — αλλιώς δύο ρίζες για το ΙΔΙΟ σύνολο bytes"
          "ΜΗ ΚΕΝΟ — αλλιώς ρίζα κενού δέντρου για ΟΠΟΙΟΔΗΠΟΤΕ περιεχόμενο"
          "Η ΣΕΙΡΑ ΕΙΝΑΙ ΜΕΡΟΣ ΤΗΣ ΔΕΣΜΕΥΣΗΣ"))

 ;; ── Η MERKLE ΕΔΡΑ ΕΙΝΑΙ Η ΠΑΡΑΓΩΓΙΚΗ, ΚΑΙ ΤΟ ΑΠΟΔΕΙΚΝΥΕΙ ────────────────
 :merkle-seat
 (:profile "lawmax-merkle-sha256-v1"
  :leaf "SHA-256(0x00 ‖ ΩΜΑ BYTES ΑΡΧΕΙΟΥ)  ≡ orchestrator.merkle:hash-leaf-file"
  :node "SHA-256(0x01 ‖ raw(L) ‖ raw(R))     ≡ orchestrator.merkle:hash-node"
  :mth  "RFC 9162 §2.1.1 unbalanced split — ΠΟΤΕ duplicate-last (CVE-2012-2459)"
  :release-root "MTH πάνω σε hash-leaf-file φύλλα, ΣΤΗ ΣΕΙΡΑ των canonical files
                 (η σειρά ΕΙΝΑΙ μέρος της δέσμευσης) ≡ merkle-root-of-files"
  :snapshot-root "MTH πάνω σε φύλλα εγγραφών:
                  leaf( «lawmax-snapshot-entry-v1\\0» ‖ u64be(len(path)) ‖ path ‖
                        u64be(size) ‖ raw32(file-leaf) ) — αναμφίσημη, length-prefixed,
                  δεσμεύει ΤΟ ΙΔΙΟ per-file φύλλο με το release_root"
  :self-check "verify_merkle_seat() ΠΡΙΝ από κάθε byte: κενή ρίζα + ΚΑΘΕ leaf vector +
               ΚΑΘΕ δέντρο ΚΑΙ ΟΛΟ το differential range (n=0..64) απέναντι στα
               COMMITTED deployment/verify/vectors/merkle/vectors.json.
               Απόκλιση/απουσία ⇒ ΑΡΝΗΣΗ."
  :second-algorithm "Κάθε ρίζα υπολογίζεται ΚΑΙ ΜΕ ΔΕΥΤΕΡΟ, ΔΟΜΙΚΑ ΔΙΑΦΟΡΕΤΙΚΟ
                     αλγόριθμο (επαυξητική στοίβα τέλειων υποδέντρων, η κανονική
                     μηχανική των CT logs) και οι δύο ΟΦΕΙΛΟΥΝ να συμφωνούν — για
                     ΚΑΘΕ n, όχι μόνο για τα πινακοποιημένα. Διαφορά ⇒
                     merkle-internal-divergence."
  :differential-proof "authority-v2/proofs/capture-seat-differential-test.sh — τρέχει ΚΑΙ ΤΙΣ
                       ΔΥΟ έδρες (capture.py ΚΑΙ ο ΠΑΡΑΓΩΓΙΚΟΣ Lisp πυρήνας) στα ΙΔΙΑ bytes
                       και συγκρίνει byte-για-byte, με αρνητικό μάρτυρα (1 byte αλλάζει ⇒
                       αλλάζουν ΚΑΙ ΟΙ ΔΥΟ) και έλεγχο ότι η σειρά δεσμεύεται.")

 ;; ── ΑΠΟΣΥΡΜΕΝΟΙ ΙΣΧΥΡΙΣΜΟΙ (ρητή εντολή δημιουργού) ──────────────────────
 :retracted-claims
 ((:claim "«Η απόκλιση της Merkle έδρας είναι ΔΟΜΙΚΑ ΑΔΥΝΑΤΗ»"
   :status :retracted
   :why "Ο δημιουργός κατασκεύασε μετάλλαξη που αστοχεί ΜΟΝΟ σε δέντρο 18 φύλλων:
         πέρασε και τους 22 ελέγχους της τότε verify_merkle_seat() και έγινε δεκτή
         με λάθος snapshot_root. Πεπερασμένα vectors ελέγχουν πεπερασμένα n."
   :what-holds-now "ΑΝΙΧΝΕΥΣΗ, όχι αδυνατότητα: (α) committed vectors για ΟΛΟ το
                    n=0..64· (β) δεύτερος δομικά διαφορετικός αλγόριθμος MTH που
                    συγκρίνεται σε ΚΑΘΕ κλήση, για κάθε n· (γ) διαφορικό test
                    απέναντι στον ΠΑΡΑΓΩΓΙΚΟ Lisp πυρήνα."
   :returns-when "Υπάρξει ΚΟΙΝΟΣ ΑΠΟΔΕΔΕΙΓΜΕΝΟΣ πυρήνας (formally verified),
                  όχι νωρίτερα."))

 ;; ── ΤΙ ΔΕΝ ΙΣΧΥΡΙΖΕΤΑΙ Η CAPTURE (τίμια άγνοια) ──────────────────────────
 :non-claims
 ("Η capture ΔΕΝ ισχυρίζεται ότι το candidates/ είχε αυτό το περιεχόμενο σε ΜΙΑ
   στιγμή. Ο producer μπορεί να αλλάξει το αρχείο Β αφού διαβαστεί το Α· ένα
   ατομικό στιγμιότυπο ΟΛΟΥ του δέντρου δεν είναι διαθέσιμο χωρίς υποστήριξη
   filesystem (snapshot/reflink)."
  "Ο ΙΣΧΥΡΙΣΜΟΣ ΠΟΥ ΟΝΤΩΣ ΓΙΝΕΤΑΙ: το quarantine περιέχει ΑΥΤΑ ΑΚΡΙΒΩΣ τα bytes,
   οι δύο ρίζες τα δεσμεύουν, και η K κρίνει ΑΠΟΚΛΕΙΣΤΙΚΑ αυτά. Το candidates/
   ΔΕΝ είναι είσοδος καμίας απόφασης — άρα η μη-ατομικότητά του δεν μολύνει
   καμία κρίση· μπορεί μόνο να οδηγήσει σε ΑΡΝΗΣΗ (fail-closed)."
  "Το ανά-αρχείο fingerprint (πριν/μετά) ανιχνεύει μεταβολή ΤΟΥ ΙΔΙΟΥ inode μέσα
   στο παράθυρο ανάγνωσης· ΔΕΝ ανιχνεύει αλλαγή αρχείου που έχει ΗΔΗ διαβαστεί.")

 ;; ── ΟΡΙΟΘΕΤΗΣΗ ───────────────────────────────────────────────────────────
 :out-of-scope
 ("Η ΠΑΡΑΓΩΓΙΚΗ υλοποίηση του capture θα είναι μέρος του imperative shell της
   authority process (εξαγόμενο artifact) — ΔΕΝ γράφεται σε Common Lisp ώστε να
   μη δημιουργηθεί δεύτερη έδρα."
  "Η υλοποίηση αναφοράς εδώ είναι ΑΝΤΙΠΑΛΙΚΟ HARNESS: αποδεικνύει ότι οι
   επιθέσεις απορρίπτονται, ΔΕΝ είναι production writer."
  "Το production writer παραμένει ΑΠΕΝΕΡΓΟΠΟΙΗΜΕΝΟ (STORAGE-API)."))
