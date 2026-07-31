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
   :statement "census ΚΑΙ root ΕΠΑΝΥΠΟΛΟΓΙΖΟΝΤΑΙ ΜΕΣΑ στο quarantine, από τα
               αντιγραμμένα bytes — ΠΟΤΕ από δηλώσεις του producer"
   :rationale "ό,τι δηλώνει ο producer είναι ισχυρισμός, όχι δεδομένο")
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
  (:id :declared-root-mismatch :detail "ο δηλωμένος root ≠ ο επανυπολογισμένος"))

 ;; ── ΟΡΙΟΘΕΤΗΣΗ ───────────────────────────────────────────────────────────
 :out-of-scope
 ("Η ΠΑΡΑΓΩΓΙΚΗ υλοποίηση του capture θα είναι μέρος του imperative shell της
   authority process (εξαγόμενο artifact) — ΔΕΝ γράφεται σε Common Lisp ώστε να
   μη δημιουργηθεί δεύτερη έδρα."
  "Η υλοποίηση αναφοράς εδώ είναι ΑΝΤΙΠΑΛΙΚΟ HARNESS: αποδεικνύει ότι οι
   επιθέσεις απορρίπτονται, ΔΕΝ είναι production writer."
  "Το production writer παραμένει ΑΠΕΝΕΡΓΟΠΟΙΗΜΕΝΟ (STORAGE-API)."))
