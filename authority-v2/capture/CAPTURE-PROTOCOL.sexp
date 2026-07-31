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
  (:id :openat2-unavailable    :detail "ο πυρήνας δεν υποστηρίζει openat2 — ΚΑΜΙΑ σιωπηλή υποβάθμιση"))

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
               ΚΑΘΕ δέντρο n=0..17 απέναντι στα COMMITTED
               deployment/verify/vectors/merkle/vectors.json. Απόκλιση/απουσία ⇒ ΑΡΝΗΣΗ."
  :differential-proof "authority-v2/tests/capture-seat-differential-test.sh — τρέχει ΚΑΙ ΤΙΣ
                       ΔΥΟ έδρες (capture.py ΚΑΙ ο ΠΑΡΑΓΩΓΙΚΟΣ Lisp πυρήνας) στα ΙΔΙΑ bytes
                       και συγκρίνει byte-για-byte, με αρνητικό μάρτυρα (1 byte αλλάζει ⇒
                       αλλάζουν ΚΑΙ ΟΙ ΔΥΟ) και έλεγχο ότι η σειρά δεσμεύεται.")

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
