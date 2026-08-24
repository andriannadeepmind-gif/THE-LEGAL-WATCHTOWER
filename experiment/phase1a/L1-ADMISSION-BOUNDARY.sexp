;;;; experiment/phase1a/L1-ADMISSION-BOUNDARY.sexp
;;;; ΜΗΤΡΩΟ ΤΟΥ ΟΡΙΟΥ ΑΠΟΔΟΧΗΣ Φ1A-L1 × RESOLVER v4
;;;;
;;;; ΕΞΩΤΕΡΙΚΟ ΑΡΧΕΙΟ, ΟΧΙ ΜΕΣΑ ΣΕ DOSSIER. Ο ενορχηστρωτής ΔΕΝ γράφει πρόζα
;;;; μέσα στο κείμενο μιας διαδρομής — αυτό θα ήταν μόλυνση της απομόνωσης.
;;;; Γι' αυτό το `source-rev2.sexp` ΔΕΝ φέρει κεφαλίδα :revision/:supersedes:
;;;; είναι ΚΑΘΑΡΗ, ΑΠΟΔΕΔΕΙΓΜΕΝΑ ΜΟΝΟ-ΠΡΟΘΕΜΑΤΙΚΗ εικόνα του πρωτοτύπου, και
;;;; τα μεταδεδομένα αναθεώρησης ζουν ΕΔΩ. Μία έδρα ανά έννοια.

(:lawmax-l1-admission-boundary/1
 :verdict :FRONTIER-BLOCKED
 :frontier-location "ΑΠΟΚΛΕΙΣΤΙΚΑ στο όριο αποδοχής L1 × v4. Καμία άλλη διαδρομή."
 :lane-status :QUARANTINED
 :explicitly-not-sealed t

 ;; ── §1 ΠΑΓΩΜΕΝΕΣ ΤΑΥΤΟΤΗΤΕΣ (ΠΛΗΡΗ SHA-256, ΠΟΤΕ ΠΡΟΘΕΜΑ) ──────────────
 :frozen-identities
 ((:what "L1 dossier — ΠΡΩΤΟΤΥΠΟ" :path "experiment/phase1a/source.sexp"
   :sha256 "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef"
   :bytes 168086 :immutable t)
  (:what "L1 dossier — ΜΕΤΑΝΑΣΤΕΥΜΕΝΟ" :path "experiment/phase1a/source-rev2.sexp"
   :sha256 "858f4c903e91a11289d3e4830541dbca687a14cd403883758fa04ea559f68807"
   :bytes 170375
   :supersedes-sha256 "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef")
  (:what "resolver v4" :path "experiment/runner/citation-resolver.py"
   :sha256 "24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9")
  (:what "resolver v3 — ΤΟ ΕΛΑΤΤΩΜΑΤΙΚΟ" :path "experiment/runner/citation-resolver.py@5ca9ea16"
   :sha256 "d552d4171bc6166986bf216dda567bfe540fac09f9aafe067a9ffcf579846046"
   :sha256-status :RECOVERED-FROM-GIT
   :prefix-recorded-at-the-time "d552d4171bc61669"
   :prefix-matches-recovered t
   :recovery-command "git show 5ca9ea16:experiment/runner/citation-resolver.py | sha256sum")
  (:what "witness suite v4" :path "experiment/runner/resolver-witnesses.py"
   :sha256 "3b75fc5d67dea3664e0e2385db09fe8ea7c273fd6f39a95d3c4084d539650024")
  (:what "manifest v2 (tsv)" :path "experiment/artifacts/corpus-manifest.tsv"
   :sha256 "29cf2b0ce1af2c9b08711d4aca0a7177f41fcb77d40d68904f170fa6abd41c7e")
  (:what "manifest v2 (sexp)" :path "experiment/artifacts/corpus-manifest.sexp"
   :sha256 "4fdf3bb02ec83001399942679b436f4699138d51cfbb54850e2027190551285f")
  (:what "corpus Merkle root" :commit "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
   :sha256 "ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b")
  (:what "LANE-REGISTRY — ΤΕΛΙΚΟ (μετά τη σήμανση QUARANTINED)"
   :path "experiment/phase1a/LANE-REGISTRY.sexp"
   :sha256 "051d66fa24ebeff43e6e29fdcdca7f2783d49c1082bf60987ee79f2b54f63364"
   :roots-unchanged-by-the-update t
   :roots-proof "load_lane_roots(\"Φ1A-L1\") επιστρέφει (\"source\") ΚΑΙ ΠΡΙΝ ΚΑΙ
                 ΜΕΤΑ την ενημέρωση — η αλλαγή αφορούσε ΜΟΝΟ :status/:revisions,
                 άρα η κατάταξη των 283 ΔΕΝ επηρεάζεται.")
  (:what "LANE-REGISTRY — κατά τη λήψη του raw log"
   :sha256 "fffdc910bf95986a549244388a6914211034a5478daf0dea1860b6be7a51f404"
   :status :SUPERSEDED-SAME-ROOTS)
  (:what "ΤΕΛΙΚΕΣ ΑΠΟΔΕΙΞΕΙΣ ΠΥΛΗΣ, ΚΑΙ ΟΙ ΕΠΤΑ"
   :path "experiment/artifacts/l1-admission-forensics/FINAL-GATE-RECEIPTS.txt")
  (:what "RAW gate log — ΑΥΤΟΥΣΙΟ, 283 αποτυχίες"
   :path "experiment/artifacts/l1-admission-forensics/GATE-v4-L1-RAW.log"
   :sha256 "3bfb9dd242eba1068a7fbd593d179346238727c4fa077ece38a99ff0a1b2124d"
   :lines 290 :failure-lines 283 :immutable t))

 ;; ── §2 ΤΟ ΟΡΙΟ ΤΩΝ ΜΑΡΤΥΡΩΝ — ΤΙ ΔΕΝ ΑΠΟΔΕΙΚΝΥΕΙ ΤΟ 36/36 ─────────────
 :witness-suite-scope
 (:claim-granted "Οι 36 μάρτυρες αποδεικνύουν ότι ο v4 κοκκινίζει σε κάθε
                  ΠΡΟΚΑΤΑΣΚΕΥΑΣΜΕΝΟ μονοπάτι απόρριψης που δηλώθηκε."
  :claim-refused "ΔΕΝ αποδεικνύουν ότι ο v4 ερμηνεύει σωστά την ΠΡΑΓΜΑΤΙΚΗ
                  μορφή παραπομπών της L1. Αυτό είναι ΑΛΛΟ ερώτημα και
                  απαντήθηκε ΧΩΡΙΣΤΑ, με τη μηχανική κατάταξη του §4."
  :how-it-was-actually-settled
   "Η κατάταξη έτρεξε τον resolver ΑΥΤΟΥΣΙΟ (byte-for-byte), έπιασε το
    SystemExit του, και κάλεσε τη ΔΙΚΗ ΤΟΥ load_lane_roots / normalize /
    load_manifest / CITATION από το ΔΙΚΟ ΤΟΥ namespace. Δεν ξαναγράφτηκε
    ούτε μία γραμμή της λογικής του για τη διάγνωση — άρα το §3 είναι
    ΠΑΡΑΤΗΡΗΣΗ του parser, όχι ανακατασκευή του.")

 ;; ── §3 ΤΙ ΠΑΡΗΓΑΓΕ ΠΡΑΓΜΑΤΙΚΑ Ο PARSER ───────────────────────────────
 :roots-as-produced-by-parser
 (:call "load_lane_roots(\"Φ1A-L1\")"
  :returned ("source")
  :count 1
  :semantics "«source» ⇒ ΚΑΤΑΛΟΓΟΣ, αναδρομικά (rel == \"source\" ή rel αρχίζει
              με \"source/\"). Κανένα glob."
  :registry-source "LANE-REGISTRY.sexp — εγγραφή Φ1A-L1, :cluster-roots (\"source\")"
  :cross-check "Η ίδια η πύλη τύπωσε στο raw log: «lane Φ1A-L1 · cluster-roots
                ['source']» — ΤΑΥΤΙΖΕΤΑΙ.")

 ;; ── §4 ΜΗΧΑΝΙΚΗ ΚΑΤΑΤΑΞΗ ΚΑΙ ΤΩΝ 283 ─────────────────────────────────
 :classification
 (:total 283
  :classes
  ((:code :A :name "VALID-CORPUS-ROOT-RELATIVE" :count 0
    :meaning "το token ως-έχει είναι έγκυρο κλειδί manifest"
    :implication-if-nonzero "ΘΑ ΗΤΑΝ ΕΛΑΤΤΩΜΑ RESOLVER")
   (:code :B :name "VALID-LANE-RELATIVE (μοναδική root)" :count 272
    :meaning "«source/<token>» υπάρχει, εύρος έγκυρο, ΚΑΝΕΝΑΣ άλλος υποψήφιος
              πουθενά στο corpus")
   (:code :C :name "REGISTRY/ROOT-PARSER-DEFECT" :count 0
    :implication-if-nonzero "ΘΑ ΗΤΑΝ ΕΛΑΤΤΩΜΑ ΥΠΟΔΟΜΗΣ")
   (:code :D :name "AMBIGUOUS" :count 10
    :meaning "λύνει υπό τη δηλωμένη root ΑΛΛΑ το ίδιο basename υπάρχει και
              αλλού στο corpus — η επιλογή ΔΕΝ είναι μηχανικά μονοσήμαντη")
   (:code :E :name "OUT-OF-DECLARED-SCOPE" :count 0)
   (:code :F :name "NONEXISTENT-FILE" :count 0)
   (:code :G :name "INVALID-RANGE-OR-HASH" :count 1
    :meaning "το αρχείο ταυτοποιείται αλλά το εύρος γραμμών ΔΕΝ υπάρχει"))
  :arithmetic "272 + 10 + 1 = 283 ✓"
  :gate-error-histogram ((:code "ΑΓΝΩΣΤΗ ΔΙΑΔΡΟΜΗ στο manifest" :count 283))
  :histogram-note
   "Η πύλη εξέδωσε ΕΝΑΝ ΜΟΝΟ κωδικό για όλες. Αυτό είναι ΣΩΣΤΟ ως προς την
    πύλη — από τη σκοπιά της, γυμνό όνομα ΕΙΝΑΙ άγνωστη διαδρομή — αλλά
    ΑΠΟΚΡΥΠΤΕΙ ότι πίσω από τον ίδιο κωδικό κρύβονται ΤΡΕΙΣ διαφορετικές
    πραγματικές καταστάσεις (B/D/G). Γι' αυτό η κατάταξη έγινε ΧΩΡΙΣΤΑ και
    ΔΕΝ βασίστηκε στον κωδικό της πύλης."
  :full-record "experiment/artifacts/l1-admission-forensics/CLASSIFICATION.json"
  :human-readable "experiment/artifacts/l1-admission-forensics/FORENSICS.txt")

 ;; ── §5 ΠΛΗΡΕΙΣ ΜΑΡΤΥΡΕΣ ΑΝΑ ΜΗ ΚΕΝΗ ΚΑΤΗΓΟΡΙΑ ────────────────────────
 :witnesses
 ((:class :B
   :token "safe-read.lisp:39-349"
   :allowed-roots ("source")
   :computed-manifest-key "source/safe-read.lisp"
   :in-manifest t
   :corpus-wide-candidates ("source/safe-read.lisp")
   :result "ΜΟΝΟΣΗΜΑΝΤΟ — ένας και μόνο υποψήφιος, εύρος έγκυρο")
  (:class :D
   :token "config.lisp:44"
   :allowed-roots ("source")
   :computed-manifest-key "source/config.lisp"
   :in-manifest t
   :corpus-wide-candidates ("source/config.lisp"
                            "systems/orchestrator-ai-core/config.lisp"
                            "third-party/cl+ssl-20250622-git/src/config.lisp"
                            "third-party/lparallel-v2.8.4/src/util/config.lisp")
   :result "ΤΕΣΣΕΡΙΣ υποψήφιοι. Η επιλογή «source/» είναι ΕΙΚΑΣΙΑ, όχι απόδειξη.")
  (:class :G
   :token "capability-registry.lisp:40-207"
   :allowed-roots ("source")
   :computed-manifest-key "source/capability-registry.lisp"
   :in-manifest t
   :corpus-wide-candidates ("source/capability-registry.lisp")
   :result "RANGE-OUT: το αρχείο έχει 206 λογικές γραμμές, ζητήθηκε 40-207"
   :sharpness "ΟΙ ΑΛΛΕΣ ΔΥΟ παραπομπές στο ΙΔΙΟ αρχείο (122-134, 195-206) είναι
               ΕΓΚΥΡΕΣ. Άρα δεν πρόκειται για λάθος αρχείο αλλά για υπέρβαση
               ορίου κατά ΜΙΑ γραμμή — ΓΝΗΣΙΟ ΕΛΑΤΤΩΜΑ DOSSIER που ο v3
               ΔΕΝ ΘΑ ΕΠΙΑΝΕ ΠΟΤΕ, επειδή δεχόταν nlines+1."))

 ;; ── §6 ΑΠΟΦΑΣΗ ΚΑΤΑ ΤΟ ΔΕΝΤΡΟ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ ────────────────────────
 :decision
 (:branch-taken "ΜΟΝΟΣΗΜΑΝΤΗ ΑΛΛΑΓΗ ΣΥΝΤΑΞΗΣ ⇒ deterministic citation-only migration"
  :why-not-infrastructure-fix
   "A = 0 ΚΑΙ C = 0. Καμία παραπομπή δεν ήταν έγκυρη ως-έχει, και καμία δεν
    απέτυχε λόγω λάθους parser ή registry. Ο v4 ΔΕΝ φταίει. Το όριο αποδοχής
    του είναι ΣΩΣΤΟ: γυμνό όνομα αρχείου ΔΕΝ είναι δηλωμένη μορφή."
  :why-not-agent
   "Τα 272 της κλάσης B είναι ΜΗΧΑΝΙΚΑ μονοσήμαντα: ένας υποψήφιος σε ΟΛΟ το
    παγωμένο manifest, εύρος έγκυρο. Δεν χρειάζεται κρίση, άρα δεν χρειάζεται
    πράκτορας. Ο πράκτορας που είχε ξεκινήσει ΤΕΡΜΑΤΙΣΤΗΚΕ πριν γράψει
    οτιδήποτε — επιβεβαιωμένο: source.sexp αμετάβλητο, source-rev2 ανύπαρκτο
    τη στιγμή του τερματισμού."
  :migration
  (:kind :CITATION-ONLY
   :transform "εισαγωγή του ΠΡΟΘΕΜΑΤΟΣ «source/» ΜΟΝΟ μπροστά από το τμήμα
               διαδρομής των tokens της κλάσης B"
   :unique-keys-migrated 272
   :text-replacements 327
   :why-more-replacements-than-keys
    "Ορισμένα tokens εμφανίζονται ΠΟΛΛΑΠΛΕΣ ΦΟΡΕΣ στο κείμενο. Η πύλη τα
     μετράει μία φορά (dedup ανά κλειδί)· η μετανάστευση τα άλλαξε ΟΛΑ."
   :bytes-before 168086 :bytes-after 170375 :byte-delta 2289
   :delta-arithmetic "327 × 7 bytes («source/») = 2289 ✓"
   :proof-no-claim-byte-changed
    (:method :REVERSE-RECONSTRUCTION
     :procedure "Από το ΝΕΟ κείμενο αφαιρέθηκαν ΑΚΡΙΒΩΣ 7 bytes σε καθεμιά από
                 τις 327 καταγεγραμμένες θέσεις, και το αποτέλεσμα συγκρίθηκε
                 με το ΠΡΩΤΟΤΥΠΟ."
     :reconstructed-sha256 "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef"
     :original-sha256      "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef"
     :identical t
     :what-this-establishes
      "Η ΜΟΝΗ διαφορά μεταξύ των δύο κειμένων είναι οι 327 εισαγωγές του
       προθέματος. ΚΑΝΕΝΑ byte ισχυρισμού, ονόματος, κρίσης, εύρους γραμμών ή
       hash δεν άλλαξε. Η απόδειξη είναι ΑΜΦΙΔΡΟΜΗ, όχι δειγματοληπτική.")
   :full-mapping "experiment/artifacts/l1-admission-forensics/MIGRATION-MAP.json"
   :mapping-fields "old_token · new_token · old_char_offset · new_char_offset ·
                    old_path · new_path · line_in_dossier — ΑΝΑ ΑΝΤΙΚΑΤΑΣΤΑΣΗ")
  :held-back
  (:count 11 :classes (:D 10 :G 1)
   :left-byte-identical t
   :verified "και τα 11 tokens επιβεβαιώθηκαν ΑΥΤΟΥΣΙΑ μέσα στο source-rev2.sexp"
   :tokens ("config.lisp:7-49" "config.lisp:44" "config.lisp:48-49" "config.lisp:51-60"
            "memory.lisp:110" "memory.lisp:258-272" "memory.lisp:48-50"
            "protocols.lisp:1-263" "protocols.lisp:145-149" "protocols.lisp:56"
            "capability-registry.lisp:40-207")))

 ;; ── §7 ΑΠΟΔΕΙΞΗ ΤΗΣ ΠΥΛΗΣ ΓΙΑ ΤΟ ΜΕΤΑΝΑΣΤΕΥΜΕΝΟ ─────────────────────
 :rev2-gate-receipt
 (:resolver 4
  :resolver-sha256 "24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
  :dossier "experiment/phase1a/source-rev2.sexp"
  :dossier-sha256 "858f4c903e91a11289d3e4830541dbca687a14cd403883758fa04ea559f68807"
  :citations 286 :resolved 275 :problems 11 :exit 1
  :verdict :CITATION-INTEGRITY-FAIL
  :forms (:mount-anchored 0 :corpus-relative 275)
  :coverage (:in-cluster 272 :out-of-cluster 3)
  :log "experiment/artifacts/l1-admission-forensics/GATE-v4-L1-REV2.log"
  :interpretation
   "Η μετανάστευση ΔΕΝ σφραγίζει τη διαδρομή και ΔΕΝ την κάνει πράσινη.
    Μετακίνησε το όριο από 283 σε 11 και το ΕΝΤΟΠΙΣΕ ΑΚΡΙΒΩΣ. Τα 11 είναι
    ΑΚΡΙΒΩΣ όσα απαιτούν κρίση που ο ενορχηστρωτής ΔΕΝ δικαιούται να κάνει.")

 ;; ── §8 Η ΕΝΤΟΛΗ ΠΟΥ ΕΠΙΣΤΡΕΦΕΙ ΣΤΗ ΔΙΑΔΡΟΜΗ — ΔΕΝ ΕΧΕΙ ΕΚΚΙΝΗΘΕΙ ────
 :charge-for-lane
 (:status :PREPARED-NOT-DISPATCHED
  :why-not-dispatched "Ο δημιουργός σταμάτησε ρητά την εκκίνηση πράκτορα. Η
                       εντολή προετοιμάζεται και ΑΝΑΜΕΝΕΙ ρητή έγκριση."
  :scope-hard-limit 11
  :forbidden ("επανάληψη ανάγνωσης των 133 αρχείων"
              "οποιαδήποτε νέα αρχαιολογία"
              "μεταβολή οποιουδήποτε ισχυρισμού, ευρήματος ή κρίσης"
              "μεταβολή οποιασδήποτε από τις 275 ήδη λυμένες παραπομπές")
  :required
  ((:for :D
    :question "Για καθένα από τα 10: ΠΟΙΟ αρχείο διαβάστηκε πραγματικά όταν
               γράφτηκε ο ισχυρισμός δίπλα στην παραπομπή;"
    :candidates-must-be-weighed t
    :evidence-required "άνοιγμα του εύρους στο /frozen/ro και αντιπαραβολή
                        ΠΕΡΙΕΧΟΜΕΝΟΥ με τον ισχυρισμό — ΟΧΙ επιλογή επειδή
                        «η συστάδα μου είναι source/»")
   (:for :G
    :question "capability-registry.lisp:40-207 σε αρχείο 206 γραμμών: ποιο
               είναι το ΣΩΣΤΟ εύρος, ή χάνεται η άγκυρα;"
    :evidence-required "αν βρεθεί σωστό εύρος στο ΙΔΙΟ αρχείο, καταγράφεται
                        ονομαστικά· αλλιώς ο ισχυρισμός σημειώνεται
                        :anchor-lost t με ρητή εξήγηση — ΠΟΤΕ διαγραφή"))
  :deliverable "νέα revision με :supersedes-sha256
                858f4c903e91a11289d3e4830541dbca687a14cd403883758fa04ea559f68807"
  :gate-to-pass "python3 experiment/runner/citation-resolver.py --lane Φ1A-L1 <νέο>")

 ;; ── §9 ΤΙ ΠΑΡΑΜΕΝΕΙ ΚΛΕΙΔΩΜΕΝΟ ──────────────────────────────────────
 :locked
 ("ΚΑΜΙΑ reconciliation — παραμένει κλειδωμένη"
  "ΚΑΜΙΑ προαγωγή ευρήματος σε B⁻"
  "ΚΑΜΙΑ σφράγιση της Φάσης 1A"
  "Η Φ1A-L1 ΔΕΝ είναι sealed — είναι :QUARANTINED")
 :other-six-lanes
 (:status :VALID-UNDER-THEIR-OWN-v4-RECEIPTS
  :re-run :NO
  :note "Πέρασαν με τα ΙΔΙΑ sha256 dossier υπό τον v4. Το πράσινό τους είναι
         ΔΙΚΟ ΤΟΥΣ, όχι προϊόν της πύλης. Δεν ξανατρέχουν."))
