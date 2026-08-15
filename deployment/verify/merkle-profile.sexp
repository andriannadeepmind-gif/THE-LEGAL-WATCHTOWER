;;;; deployment/verify/merkle-profile.sexp
;;;; ============================================================================
;;;; MERKLE-SINGLE-TRUTH — Η ΜΙΑ ΚΑΝΟΝΙΚΗ ΠΗΓΗ ΤΗΣ MERKLE ΑΛΗΘΕΙΑΣ
;;;; ============================================================================
;;;; ΓΙΑΤΙ ΥΠΑΡΧΕΙ: το σύστημα είχε ΤΡΕΙΣ περιγραφές του ίδιου αλγορίθμου και οι
;;;; δύο ήταν ΛΑΘΟΣ:
;;;;   • deployment/PROOF-CARRYING-LAW.md §2 έλεγε «an odd node is paired with
;;;;     itself» ⇒ duplicate-last ⇒ κλάση CVE-2012-2459.
;;;;   • deployment/verify/README.md «the algorithm so you can re-implement it»
;;;;     παρέλειπε ΚΑΙ τα δύο domain prefixes (0x00/0x01) ⇒ second-preimage, ΚΑΙ
;;;;     δίδασκε duplicate-last.
;;;;   • source/merkle-authority.lisp έκανε το ΣΩΣΤΟ (unbalanced split + prefixes).
;;;; Τρίτος που ξανα-υλοποιούσε από τα κείμενα έπαιρνε ΔΙΑΦΟΡΕΤΙΚΗ ρίζα — δηλαδή
;;;; κατέρρεε ακριβώς η ιδιότητα για την οποία υπάρχει το PCL: η ανεξάρτητη
;;;; επαληθευσιμότητα. RELEASE BLOCKER.
;;;;
;;;; ΔΟΜΙΚΗ ΛΥΣΗ: αυτό το αρχείο είναι η ΜΟΝΗ κανονική πηγή. Από εδώ ΠΑΡΑΓΟΝΤΑΙ
;;;; (scripts/gen-merkle-truth.lisp) οι ενότητες των δύο κειμένων ΚΑΙ τα κοινά
;;;; golden vectors. Χειροκίνητη δεύτερη περιγραφή του αλγορίθμου = κόκκινο build.
;;;;
;;;; ΤΙ ΔΕΝ ΠΑΡΑΓΕΤΑΙ ΑΠΟ ΕΔΩ: οι τρεις υλοποιήσεις (Lisp/Python/Node) παραμένουν
;;;; ΑΝΕΞΑΡΤΗΤΕΣ. Η N-version ανεξαρτησία είναι άμυνα απέναντι σε σφάλμα
;;;; υλοποίησης· κοινός generator κώδικα θα την ΚΑΤΑΡΓΟΥΣΕ. Κοινά είναι ΜΟΝΟ τα
;;;; vectors — και αυτά είναι δεδομένα, όχι κώδικας.
;;;;
;;;; Data-only· διαβάζεται από τη ΜΙΑ έδρα safe-read (*read-eval* NIL).
;;;; ============================================================================

(:lawmax-merkle-profile/1

 :profile-id "lawmax-merkle-sha256-v1"

 ;; Κανονική αναφορά: το RFC 9162 ΑΝΤΙΚΑΤΕΣΤΗΣΕ το RFC 6962. Η αλγοριθμική
 ;; ταυτότητα του MTH είναι ίδια· η αναφορά εδώ είναι το ΙΣΧΥΟΝ πρότυπο.
 :normative-reference "RFC 9162 §2.1.1 (Merkle Tree Hash) — obsoletes RFC 6962"
 :normative-url "https://www.rfc-editor.org/rfc/rfc9162.html#section-2.1.1"

 :hash-algorithm "SHA-256"
 :hash-representation "sha256:<64 lowercase hex>"
 :leaf-prefix-byte "0x00"
 :node-prefix-byte "0x01"

 ;; ── Οι κανόνες του MTH, κανονικά και εξαντλητικά ──
 :rules
 ((:id :empty
   :statement "MTH({}) = SHA-256(\"\")  — ο hash του ΚΕΝΟΥ string"
   :rationale "RFC 9162 §2.1.1: το κενό δέντρο έχει ΟΡΙΣΜΕΝΗ ρίζα. Ο πρωτόγονος ΟΦΕΙΛΕΙ να τη δίνει· η ΠΟΛΙΤΙΚΗ δημοσίευσης χωριστά ΑΠΑΓΟΡΕΥΕΙ κενό corpus.")
  (:id :leaf
   :statement "MTH({d(0)}) = SHA-256(0x00 || d(0))"
   :rationale "Domain separation: χωρίς το 0x00 ένα 64-byte φύλλο είναι second-preimage εσωτερικού κόμβου.")
  (:id :node
   :statement "MTH(D[n]) = SHA-256(0x01 || MTH(D[0:k]) || MTH(D[k:n]))  για n > 1"
   :rationale "Το 0x01 σφραγίζει τον εσωτερικό κόμβο· συνενώνονται τα ΩΜΑ bytes των παιδιών, ΟΧΙ το hex κείμενό τους.")
  (:id :split
   :statement "k = η μεγαλύτερη δύναμη του 2 ΑΥΣΤΗΡΑ μικρότερη του n  (k < n <= 2k)"
   :rationale "Unbalanced split: το δέντρο καθορίζεται μονοσήμαντα από το n.")
  (:id :no-duplicate-last
   :statement "duplicate-last ΑΠΑΓΟΡΕΥΕΤΑΙ ΑΠΟΛΥΤΩΣ"
   :rationale "Κλάση CVE-2012-2459: με αντιγραφή του τελευταίου φύλλου, ΔΙΑΦΟΡΕΤΙΚΑ σύνολα φύλλων παράγουν ΙΔΙΑ ρίζα (π.χ. [a b c] και [a b c c]) — ανεπίτρεπτο όταν εκδίδονται inclusion proofs σε τρίτους.")
  (:id :order-sensitive
   :statement "node(L,R) != node(R,L) — η σειρά είναι μέρος της δέσμευσης"
   :rationale "Η θέση του φύλλου στο corpus είναι σημασιολογική."))

 ;; ── Byte-exact είσοδος: το κείμενο ΔΕΝ αγγίζεται πριν γίνει bytes ──
 :byte-encoding
 ((:id :utf8-no-bom
   :statement "text -> bytes = UTF-8, ΧΩΡΙΣ BOM")
  (:id :no-normalization
   :statement "ΚΑΜΙΑ Unicode normalization (ούτε NFC ούτε NFD ούτε NFKC/NFKD)"
   :rationale "Δύο ΟΠΤΙΚΑ ισοδύναμες ακολουθίες είναι ΔΙΑΦΟΡΕΤΙΚΑ φύλλα. Σιωπηλή κανονικοποίηση θα άλλαζε ρίζα χωρίς αλλαγή κειμένου.")
  (:id :no-eol-conversion
   :statement "ΚΑΜΙΑ μετατροπή LF/CRLF προς οποιαδήποτε κατεύθυνση")
  (:id :preserve-trailing-newline
   :statement "Το τελικό newline διατηρείται ΑΚΡΙΒΩΣ όπως είναι (ούτε προστίθεται ούτε αφαιρείται)"))

 ;; ── ΠΟΛΙΤΙΚΗ (χωριστή από τον μηχανισμό) ──
 :publication-policy
 ((:id :reject-empty-corpus
   :statement "Δημοσίευση/υπογραφή/checkpoint corpus με leaf_count = 0 ΑΠΟΡΡΙΠΤΕΤΑΙ fail-closed"
   :rationale "Ο πρωτόγονος ΟΦΕΙΛΕΙ να ξέρει τη ρίζα του κενού δέντρου (συμμόρφωση προτύπου)· ο ΘΕΣΜΟΣ δεν επιτρέπεται να υπογράψει δέσμευση για ΤΙΠΟΤΑ. Μηχανισμός != πολιτική· απαιτούνται ΑΝΕΞΑΡΤΗΤΑ tests για τις δύο ιδιότητες."))

 ;; ── ΕΙΣΟΔΟΙ VECTORS: hex ώστε να ΜΗΝ εμπιστευόμαστε κανέναν string parser ──
 ;; Το `:hex` είναι η ΑΥΘΕΝΤΙΑ. Το `:note` είναι μόνο ανθρώπινο σχόλιο.
 :leaf-inputs
 ((:id "ascii"            :hex "68656c6c6f"             :note "hello")
  (:id "greek"            :hex "ce86cf81ceb8cf81cebf2031" :note "Αρθρο 1 (με τόνο)")
  (:id "empty"            :hex ""                       :note "ΚΕΝΟ φύλλο — 0 bytes")
  (:id "embedded-lf"      :hex "ceb10aceb2"             :note "alpha LF beta")
  (:id "embedded-crlf"    :hex "ceb10d0aceb2"           :note "alpha CRLF beta — ΔΙΑΦΟΡΕΤΙΚΟ φύλλο από το LF")
  (:id "trailing-lf"      :hex "ceb10a"                 :note "alpha + τελικό LF")
  (:id "no-trailing-lf"   :hex "ceb1"                   :note "alpha ΧΩΡΙΣ τελικό LF — ΔΙΑΦΟΡΕΤΙΚΟ φύλλο")
  (:id "nfc-alpha-tonos"  :hex "ceac"                   :note "U+03AC — ΕΝΑ code point")
  (:id "nfd-alpha-tonos"  :hex "ceb1cc81"               :note "U+03B1 U+0301 — ΟΠΤΙΚΑ ισοδύναμο, ΔΙΑΦΟΡΕΤΙΚΟ φύλλο"))

 ;; Δεδομένα φύλλων για τα δέντρα μεγέθους n: το φύλλο i είναι τα ASCII bytes
 ;; της δεκαδικής αναπαράστασης του i ("0","1",...,"16"). Ρητό, ντετερμινιστικό,
 ;; αναπαραγώγιμο σε κάθε γλώσσα χωρίς κοινό κώδικα.
 :tree-leaf-rule "leaf data for index i = ASCII bytes of the decimal representation of i"

 ;; n=0..8 (όπου duplicate-last και unbalanced split ΑΠΟΚΛΙΝΟΥΝ στα 3,5,6,7)
 ;; + οι μεταβάσεις 15,16,17 (γύρω από τη δύναμη του 2)
 :tree-sizes (0 1 2 3 4 5 6 7 8 15 16 17)

 :inclusion-cases ((:n 1 :index 0) (:n 2 :index 0) (:n 2 :index 1)
                   (:n 3 :index 0) (:n 3 :index 1) (:n 3 :index 2)
                   (:n 5 :index 0) (:n 5 :index 2) (:n 5 :index 4)
                   (:n 6 :index 3) (:n 7 :index 6) (:n 8 :index 5)
                   (:n 15 :index 7) (:n 16 :index 0) (:n 17 :index 16))

 :consistency-cases ((:n 3 :m 1) (:n 3 :m 2) (:n 5 :m 3) (:n 7 :m 4)
                     (:n 8 :m 5) (:n 16 :m 8) (:n 17 :m 16) (:n 17 :m 1))

 ;; Differential test: κάθε μέγεθος σε αυτό το εύρος ελέγχεται και από τις τρεις
 ;; γλώσσες, ντετερμινιστικά (χωρίς τυχαιότητα — αναπαραγώγιμο).
 :differential-range (:from 0 :to 64)

 ;; ── ΥΠΟΧΡΕΩΤΙΚΟΙ ΜΑΡΤΥΡΕΣ ΜΕΤΑΛΛΑΞΗΣ ──
 ;; Κάθε ένας ΠΡΕΠΕΙ να εφαρμοστεί ΠΡΑΓΜΑΤΙΚΑ και να δώσει non-zero. Το μητρώο
 ;; αυτό είναι ΖΩΝΤΑΝΟ: το harness (merkle-mutation-witness.sh) διαβάζει τα ids
 ;; ΑΠΟ ΕΔΩ και απαιτεί ισότητα συνόλων μητρώου/εφαρμοσμένων — δηλωμένος-
 ;; ανεφάρμοστος ή εφαρμοσμένος-αδήλωτος μάρτυρας = αποτυχία της πύλης.
 :mutation-witnesses
 ((:id "duplicate-last"      :target :tree  :description "περιττός κόμβος ζευγαρώνει με τον εαυτό του αντί unbalanced split")
  (:id "no-leaf-prefix"      :target :leaf  :description "φύλλο χωρίς το 0x00")
  (:id "no-node-prefix"      :target :node  :description "εσωτερικός κόμβος χωρίς το 0x01")
  (:id "wrong-split"         :target :tree  :description "split στο μισό (floor n/2) αντί στη μεγαλύτερη δύναμη του 2")
  (:id "swap-left-right"     :target :node  :description "αντιστροφή σειράς παιδιών")
  (:id "unicode-normalize"   :target :input :description "σιωπηλή NFC κανονικοποίηση της εισόδου")
  (:id "crlf-normalize"      :target :input :description "μετατροπή CRLF -> LF στην είσοδο")
  (:id "publish-empty-corpus" :target :policy :description "δημοσίευση corpus με leaf_count = 0")
  ;; profile-drift: η ΜΙΑ πηγή δεν είναι διακοσμητική — αλλαγή ΜΟΝΟ του profile
  ;; οφείλει να κοκκινίζει τον generator (έδρα/oracle/σταθερές ασυμφωνούν).
  (:id "profile-drift-leaf-prefix" :target :profile :description "leaf-prefix-byte 0x00 -> 0x02 μόνο στο profile")
  (:id "profile-drift-node-prefix" :target :profile :description "node-prefix-byte 0x01 -> 0x00 μόνο στο profile")
  (:id "profile-drift-hash-alg"    :target :profile :description "hash-algorithm SHA-256 -> SHA-512 μόνο στο profile")
  ;; ΚΑΘΕ κανονιστικό πεδίο: μεταβολή του είτε αλλάζει υποχρεωτικά τα
  ;; παραγόμενα artifacts (⇒ --check κόκκινο) είτε ρίχνει τον generator.
  ;; Αδρανές πεδίο = δεν επιτρέπεται να υπάρχει σε αυτό το αρχείο.
  (:id "profile-field-drift" :target :profile :description "sweep: profile-id, normative-ref, hash-representation, tree-leaf-rule, tree-sizes, leaf-inputs, inclusion/consistency-cases, differential-range, rules, byte-encoding, publication-policy")
  ;; Οι πύλες των ΑΛΛΩΝ ΔΥΟ δημοσιευτών αποδεικνύονται ΦΕΡΟΥΣΕΣ εκτελέσιμα
  ;; (GUARDED απορρίπτει / UNGUARDED δέχεται), όχι με κειμενικό substring.
  (:id "census-empty-articles" :target :policy :description "build-artifact-census με κενό σύνολο άρθρων")
  (:id "tlog-invalid-root"     :target :policy :description "η retired tlog-append-root! απορρίπτει κάθε κλήση μέσω %seat-removed")))
