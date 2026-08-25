;;;; experiment/phase1a/GATE-LEDGER.sexp
;;;; ΜΗΤΡΩΟ ΠΥΛΩΝ — ΠΛΗΡΗ SHA-256 ΠΑΝΤΟΥ, ΠΟΤΕ ΠΡΟΘΕΜΑΤΑ
;;;; Ιστορικό v1-v4: GATE-LEDGER-v3-v4.historic.sexp (δεν επαναλαμβάνεται εδώ)

(:lawmax-gate-ledger/3
 :corpus-commit "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
 :corpus-tree-sha1 "23b7a6f4450f50d151d38e13020bee9872e73bcd"
 :protocol-epoch 2
 :gate-receipt "experiment/artifacts/gate-receipts/20260824T224445Z/RECEIPT.json"

 ;; ── ΚΑΤΑΣΚΕΥΗ ΠΟΥ ΠΑΡΗΓΑΓΕ ΤΟ ΑΠΟΤΕΛΕΣΜΑ ────────────────────────────
 :construction
 (:runner            "sha256:c1c707e7d8442a829c75d59e9a457ef46c98279973c268c607ce01fc6a0baebe"
  :resolver          "sha256:4c197d081bcb5e77bc3f918fb36a8c633f9badd66705fc95991649ff3ed6371a"
  :citation-grammar  "sha256:852cb59481cc016a246ac7a500d0dbb231d07e5ff4f510cbb2a61b5237994161"
  :frozen-access     "sha256:bab208bc2a6e5ac4260ae26c0b0de506391fec869b530be7667ccb7856d66aae"
  :manifest-generator "sha256:c28b185cb2356a6843c1540444cc379b8a04b61aaebcc2f365a42c42e31a4817"
  :canonicalizer     "sha256:564edf65afafe5e3de776be301073c615d4add3bed376929c18b6edbeba386f5"
  :migration-verifier "sha256:b4047bdfd53d288f374dcfbb52345f4de0a305fa58a5b575255eb71eb7ea4c49"
  :witnesses         "sha256:bf0b1a3062a05f3da560cc4d72302d51302954d05612db5eff6f2af2f5c3240b"
  :event-ledger-tool "sha256:5fd26b7c183c2557783073deb314c728ce0d29dc8c4b3c594996d0eb087b74f6"
  :protocol-epoch-2  "sha256:aacd64895d8e7e5312ab55a5e51cc1727274c348a56f542e909d02f7a86e9814"
  :scope-authority   "sha256:dad69668f4ee083d873fe017fc8d13f94ec9bb231a2649a898f4685e70dce6f5"
  :manifest-tsv      "sha256:1bde12ccac8e924c7be50adbd311813e991aef4d1c9ae9f54ced16c2ad370ec5"
  :corpus-identity   "sha256:99602490aedba5f942413ec2454d189a5ccbc503deb64efdd146f9640e0f03a6")

 ;; ── ΕΚΔΟΣΕΙΣ RESOLVER ───────────────────────────────────────────────
 :resolver-versions
 ((:version 3 :sha256 "d552d4171bc6166986bf216dda567bfe540fac09f9aafe067a9ffcf579846046"
   :status :SUPERSEDED
   :fatal "EXISTENCE-BASED GUESSING — έβαζε cluster-root και δεχόταν αν
           το αρχείο ΤΥΧΑΙΝΕ να υπάρχει")
  (:version 4 :sha256 "24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
   :status :SUPERSEDED
   :fatal "ΤΟ TSV ΗΤΑΝ ΑΥΘΕΝΤΙΑ — καμία επαφή με filesystem· οι πύλες
           περνούσαν ΚΑΙ ΜΕ ΝΕΚΡΟ MOUNT· σιωπηλή αγνόηση κακοσχηματισμένων")
  (:version 5 :status :INTERMEDIATE-SUPERSEDED
   :intermediate-hashes ("sha256:8939605723dd0772f5e142c9ae4d140746d395a95ba2e8c165e53bda2e584a12"
                         "sha256:070ad89c114f4b7c379dce7d74db905a09c88bca4ef74d961ca404357f329c12"
                         "sha256:6ead7296028cf95cce37b3fe38bda165e117a2988d6755ca40817d1470a4ae1d")
   :final-hash "sha256:6ead7296028cf95cce37b3fe38bda165e117a2988d6755ca40817d1470a4ae1d"
   :ledger-correction
    "ΤΟ ΜΗΤΡΩΟ ΕΙΧΕ ΚΑΤΑΓΡΑΨΕΙ ΞΕΠΕΡΑΣΜΕΝΑ ΕΝΔΙΑΜΕΣΑ ΩΣ CURRENT. Τα δύο
     πρώτα hashes ήταν στιγμιότυπα κατά την επεξεργασία, ποτέ η τελική μορφή.
     Καταγράφονται ονομαστικά ως INTERMEDIATE ώστε καμία απόδειξη να μην
     δείχνει σε ανύπαρκτη κατασκευή."
   :fatal ("ΣΤΑΤΙΚΗ ΛΙΣΤΑ ΕΠΕΚΤΑΣΕΩΝ — αγνοούσε σιωπηλά Dockerfile,
            .gitignore, .dockerignore, .env.example, deps.lock,
            MANIFEST.sha256, everparse.Dockerfile και κάθε extensionless"
           "ΑΝΑΣΦΑΛΗΣ ΤΕΡΜΑΤΙΣΜΟΣ — δεχόταν έγκυρο ΠΡΟΘΕΜΑ token
            («…@sha256:<12>/garbage»)"
           "lstat→open: δύο αναλύσεις της ίδιας συμβολοσειράς, παράθυρο TOCTOU"))
  (:version 6 :sha256 "4c197d081bcb5e77bc3f918fb36a8c633f9badd66705fc95991649ff3ed6371a"
   :status :CURRENT
   :delta
   ("① ΑΝΑΓΝΩΡΙΣΗ MANIFEST-DRIVEN. Η λίστα επεκτάσεων ΑΦΑΙΡΕΘΗΚΕ ΟΛΟΣΧΕΡΩΣ.
      Υποψήφια διαδρομή είναι ό,τι στέκεται αριστερά της άνω τελείας· η
      ΕΠΙΛΥΣΗ γίνεται με ΑΚΡΙΒΗ αντιστοίχιση στο manifest. Extensionless,
      dotfiles, σύνθετα επιθήματα και executable leaves καλύπτονται εξ ορισμού."
    "② ΑΣΦΑΛΗΣ ΤΕΡΜΑΤΙΣΜΟΣ. «/», «%», «?», «#», «=» ΔΕΝ τερματίζουν· κάθε
      τέτοιο byte ακυρώνει ΟΛΟΚΛΗΡΟ το token. Καμία αποδοχή προθέματος."
    "③ ΕΝΑ BUFFER. Το dossier διαβάζεται ΜΙΑ φορά· hash, αποκωδικοποίηση και
      κρίση στα ΙΔΙΑ bytes."
    "④ openat2 με RESOLVE_BENEATH|NO_SYMLINKS|NO_XDEV|NO_MAGICLINKS — ο
      ΠΥΡΗΝΑΣ επιβάλλει την ιδιότητα κατά την ανάλυση· δεν υπάρχει έλεγχος
      να παρακαμφθεί, άρα ούτε παράθυρο."
    "⑤ Ο resolver γράφει JSON receipt — καμία ετυμηγορία με grep."
    "⑥ Απαιτεί mount με ro,nodev,nosuid,noexec.")
   :witnesses
   (:file "experiment/runner/resolver-witnesses.py"
    :sha256 "sha256:bf0b1a3062a05f3da560cc4d72302d51302954d05612db5eff6f2af2f5c3240b"
    :positive 10 :negative 47 :total 57 :result :ALL-PASS
    :comparison :EXACT-OUTPUT
    :new-coverage
     ("ΧΩΡΙΣ ΕΠΕΚΤΑΣΗ (Dockerfile) · DOTFILE (.gitignore) · ΣΥΝΘΕΤΟ ΕΠΙΘΗΜΑ
       (a.tar.gz) · EXECUTABLE LEAF (mode 100755)"
      "τερματικός φραγμός: «/» «%» «?» «#» «=» «%00» · ουρά ψηφίου · ουρά
       μη-δεκαεξαδικού γράμματος · λίστα κόμματος"
      "ΚΕΝΟ text αρχείο ⇒ 0 γραμμές ΚΑΙ trailing_newline 0"
      "mount χωρίς nodev/nosuid/noexec ⇒ ΑΠΟΡΡΙΨΗ"))))

 ;; ── ΤΕΛΙΚΗ ΜΟΝΑΔΙΚΗ ΕΚΤΕΛΕΣΗ ────────────────────────────────────────
 :gate-run
 (:single-shot t :agents-rerun nil
  :isolation
  (:mount-namespace "ΙΔΙΩΤΙΚΟ — unshare --mount --propagation private"
   :exclusive-lock "flock --nonblock /run/lawmax-citation-gates.lock"
   :snapshot "tmpfs ΜΕΣΑ στο ιδιωτικό namespace, γεμισμένο από git objects
              (git archive), επαληθευμένο ανά διαδρομή, μετά read-only"
   :reachable-from-outside nil
   :mount-options "ro,nosuid,nodev,noexec,relatime"
   :write-probe "EROFS (errno 30) — ΑΚΡΙΒΗΣ έλεγχος, όχι «οποιαδήποτε αποτυχία»"
   :unmount "trap EXIT INT TERM HUP + θάνατος namespace"
   :supersedes-claim
    "ΑΝΑΚΛΗΘΗΚΕ το «source-immobile» που στηριζόταν σε σύγκριση αποτυπώματος
     πριν/μετά πάνω στο ΕΓΓΡΑΨΙΜΟ /frozen/watchtower. Αυτό απεδείκνυε
     ΙΣΟΔΥΝΑΜΙΑ ΑΚΡΩΝ, όχι ακινησία. Αντί για ασθενέστερη ονομασία,
     ΚΑΤΑΣΚΕΥΑΣΤΗΚΕ η ισχυρή ιδιότητα.")
  :results
  ((:lane "Φ1A-L1" :dossier "experiment/phase1a/source-rev3.sexp"
    :dossier-sha256 "sha256:5bb2675adb08e55fe735861a87c55dd862085b87747dd33e8b2986ba8e06b5ea"
    :citations 360 :resolved 348 :problems 12 :exit 1 :verdict :FAIL)
   (:lane "Φ1A-L2" :dossier "experiment/phase1a/systems-rev2.sexp"
    :dossier-sha256 "sha256:54849c597201ccb0de29b6b86c1c87829cf2f1d255011180f1c855a3c7613521"
    :citations 296 :resolved 296 :problems 0 :exit 0
    :verdict :RECOGNIZED-CITATION-INTEGRITY)
   (:lane "Φ1A-L3" :dossier "experiment/phase1a/authority-v2-rev4.sexp"
    :dossier-sha256 "sha256:fa93d9e2cab1d31d1e3dc2798c0d0c4ffd679bd8df1ebd1652ff482d122f39ff"
    :citations 211 :resolved 211 :problems 0 :exit 0
    :verdict :RECOGNIZED-CITATION-INTEGRITY)
   (:lane "Φ1A-L4" :dossier "experiment/phase1a/deployment-specs-rev3.sexp"
    :dossier-sha256 "sha256:56abf057df4f144ff1a079cd748a9e3963d7ddc1a654af558764f5fd4d160dcc"
    :citations 290 :resolved 285 :problems 5 :exit 1 :verdict :FAIL)
   (:lane "Φ1A-L5" :dossier "experiment/phase1a/deployment-state-rev4.sexp"
    :dossier-sha256 "sha256:39dc5cafe52cba8ba786c46dbb3dc0794f26cf8b70ab25447721be35338a04fd"
    :citations 189 :resolved 189 :problems 0 :exit 0
    :verdict :RECOGNIZED-CITATION-INTEGRITY)
   (:lane "Φ1A-L6" :dossier "experiment/phase1a/harness-rev4.sexp"
    :dossier-sha256 "sha256:8aab586cbe336d4aa1d23e681d4807f7f689026347d46f6fcceb443547d74ba3"
    :citations 144 :resolved 144 :problems 0 :exit 0
    :verdict :RECOGNIZED-CITATION-INTEGRITY)
   (:lane "Φ1A-L7" :dossier "experiment/phase1a/contracts-rev3.sexp"
    :dossier-sha256 "sha256:0b0116df0f8eb913c8a3e5bee74f001c2407c0b40aa31a5b20b082d2bab7886c"
    :citations 164 :resolved 154 :problems 10 :exit 1 :verdict :FAIL))
  :aggregate (:unique-citation-keys 1654 :resolved 1627 :problems 27)
  :aggregate-note
   "ΤΡΕΙΣ διαδρομές ΚΟΚΚΙΝΕΣ. Το άθροισμα ΔΕΝ είναι πρόοδος και το σύνολο
    ΔΕΝ σφραγίζεται με μερικό άθροισμα.")

 ;; ── ΑΝΕΞΑΡΤΗΤΗ ΕΠΑΛΗΘΕΥΣΗ ──────────────────────────────────────────
 :independent-verification
 (:tool "experiment/runner/migration-verifier.py"
  :sha256 "sha256:b4047bdfd53d288f374dcfbb52345f4de0a305fa58a5b575255eb71eb7ea4c49"
  :receipt "experiment/artifacts/INDEPENDENT-VERIFICATION-RECEIPT.json"
  :imports-none-of ("citation-resolver.py" "canonicalize-citations.py"
                    "citation_grammar.py" "frozen_access.py")
  :checks 30 :result :PASS
  :central-invariant
   "ΣΚΕΛΕΤΟΣ(rev_n) == ΣΚΕΛΕΤΟΣ(rev_n+1) BYTE-FOR-BYTE, όπου ΣΚΕΛΕΤΟΣ είναι
    το κείμενο με κάθε αναγνωρισμένη παραπομπή αντικατεστημένη από σημάδι και
    κάθε ακολουθία σημαδιών χωρισμένων με κενό συμπτυγμένη σε ένα.
    ΙΣΧΥΡΟΤΕΡΟ ΑΠΟ ΕΛΕΓΧΟ ΧΑΡΤΗ: δεν εμπιστεύεται τον χάρτη — ΞΑΝΑΠΑΡΑΓΕΙ
    την ιδιότητα με ανεξάρτητη υλοποίηση."
  :covers ("και οι 15 μεταβάσεις αναθεώρησης των 7 διαδρομών"
           "1.650 κανονικές παραπομπές των τελικών αναθεωρήσεων έναντι
            ΠΡΑΓΜΑΤΙΚΩΝ bytes και ευρών"
           "ο εξουσιοδοτημένος διαχωρισμός L7, με ανεξάρτητη ανάγνωση των
            γραμμών 194 και 213 του παγωμένου αρχείου"
           "ότι ΔΕΝ δημιουργήθηκε ψευδές εύρος L194-L213"))

 ;; ── ΑΝΑΚΛΗΣΕΙΣ ─────────────────────────────────────────────────────
 :retractions
 ((:claim "1220/1220 παραπομπές λυμένες" :status :RETRACTED
   :cause "existence-based guessing του v3")
  (:claim "ALL SEVEN LANES — CITATION GATES PASSED" :status :RETRACTED
   :cause "ΤΡΕΙΣ διαδρομές αποτυγχάνουν")
  (:claim "μόνο το L1 μπλοκάρει" :status :RETRACTED
   :cause "σιωπηλή αγνόηση κακοσχηματισμένων από τον v4")
  (:claim "506 κρυμμένες αναφορές λίστας κόμματος" :status :RETRACTED
   :recomputed 437 :in-tokens 290
   :cause "το 506 παρήχθη με ΕΥΡΕΤΙΚΟ regex ΕΚΤΟΣ της πύλης, με στατική λίστα
           επεκτάσεων και χωρίς manifest-driven φιλτράρισμα. Ο ΜΗΧΑΝΙΚΟΣ
           αριθμός, με την ΙΔΙΑ γραμματική που κρίνει, είναι 437.")
  (:claim "source-immobile" :status :RETRACTED-AND-SUPERSEDED
   :cause "η σύγκριση δύο χρονικών άκρων αποδεικνύει ΙΣΟΔΥΝΑΜΙΑ ΑΚΡΩΝ, όχι
           συνεχή ακινησία"
   :replaced-by "ιδιωτικό mount namespace + tmpfs snapshot από git objects")
  (:claim "η leaf root δεσμεύει commit και tree" :status :RETRACTED
   :cause "ήταν διπλανά πεδία, ΕΚΤΟΣ preimage"
   :replaced-by "domain-separated ταυτότητα με schema/commit/tree ΜΕΣΑ στο preimage")
  (:claim "LANE-STATE-LEDGER είναι append-only" :status :RETRACTED
   :cause "ήταν απλό αρχείο sexp, ξαναγράψιμο χωρίς ίχνος"
   :replaced-by "γνήσια hash-chained αλυσίδα σε EVENT-LEDGER.jsonl")
  (:claim "unmount-on-trap" :under "run-citation-gates-v5.sh" :status :RETRACTED
   :cause "το script έκανε remount προϋπάρχοντος mount αλλά ΔΕΝ το αποπροσάρτωνε"
   :replaced-by "ιδιόκτητο mount σε κάθε run + ανεξαίρετο umount στο trap")
  (:claim "κενό text αρχείο ⇒ trailing_newline 1" :status :RETRACTED
   :cause "δεν υπάρχει newline να τερματίσει· η τιμή είναι 0"
   :affected-rows 14))

 :terminology
 (:counted-unit "ΜΟΝΑΔΙΚΑ ΚΛΕΙΔΙΑ ΠΑΡΑΠΟΜΠΗΣ" :not "textual occurrences")
 :where-state-lives "experiment/phase1a/LANE-STATE-LEDGER.sexp (ΠΑΡΑΓΩΓΗ ΟΨΗ)"
 :where-events-live "experiment/phase1a/EVENT-LEDGER.jsonl (hash-chained)"
 :where-boundary-lives "experiment/phase1a/ADMISSION-BOUNDARY-v5.sexp")
