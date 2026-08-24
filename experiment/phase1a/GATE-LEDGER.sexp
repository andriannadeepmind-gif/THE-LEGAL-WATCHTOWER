;;;; experiment/phase1a/GATE-LEDGER.sexp
;;;; ΜΗΤΡΩΟ ΠΥΛΩΝ — ΚΑΘΕ ΑΠΟΤΕΛΕΣΜΑ ΔΕΜΕΝΟ ΣΕ ΑΜΕΤΑΒΛΗΤΕΣ ΤΑΥΤΟΤΗΤΕΣ
;;;;
;;;; ΠΛΗΡΗ SHA-256 ΠΑΝΤΟΥ. Ένα πρόθεμα 16 χαρακτήρων δεν είναι δέσμευση.
;;;; Το ιστορικό των v1-v4 ζει στο GATE-LEDGER-v3-v4.historic.sexp — δεν
;;;; διαγράφεται, δεν επαναλαμβάνεται εδώ.

(:lawmax-gate-ledger/2
 :corpus-commit "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
 :corpus-tree-sha1 "23b7a6f4450f50d151d38e13020bee9872e73bcd"

 ;; ── ΣΕ ΤΙ ΔΕΝΕΤΑΙ ΚΑΘΕ ΑΠΟΔΕΙΞΗ ─────────────────────────────────────
 :binding
 (:resolver "sha256:6ead7296028cf95cce37b3fe38bda165e117a2988d6755ca40817d1470a4ae1d"
  :scope-authority "sha256:30df3ec548d86ce31f2d7c8250589a36afd14d34785a8eaeee9cbb57c9936b83"
  :corpus-identity "sha256:3127f4941b899afcbffcd405b00d9e613fe4732301ba8ed990d22a0685514019"
  :manifest-tsv "sha256:2c3a759da7f806c9cd16efd09902e12e9414e540a190d390d304d1ffc4b3adc8"
  :rule "Τα receipts δένονται ΜΟΝΟ σε ΑΜΕΤΑΒΛΗΤΑ. ΚΑΝΕΝΑ πεδίο κατάστασης
         διαδρομής δεν συμμετέχει — αυτά ζουν στο LANE-STATE-LEDGER.sexp και
         ο resolver ΔΕΝ τα διαβάζει ΠΟΤΕ."
  :why "Πριν, η αυθεντία εμβέλειας και η κατάσταση ήταν στο ΙΔΙΟ αρχείο, άρα
        κάθε αλλαγή κατάστασης άλλαζε το hash που δέσμευε τις αποδείξεις.")

 ;; ── ΕΚΔΟΣΕΙΣ RESOLVER ────────────────────────────────────────────────
 :resolver-versions
 ((:version 3 :sha256 "d552d4171bc6166986bf216dda567bfe540fac09f9aafe067a9ffcf579846046"
   :status :SUPERSEDED
   :fatal "EXISTENCE-BASED GUESSING: όταν μια παραπομπή δεν έλυνε, έβαζε
           μπροστά το cluster-root και τη δεχόταν αν το αρχείο ΤΥΧΑΙΝΕ να
           υπάρχει. Κάθε πράσινο σε dossier με γυμνά ονόματα ήταν προϊόν ΤΗΣ
           ΠΥΛΗΣ, όχι του dossier.")
  (:version 4 :sha256 "24809ecd48b410ce656229cda4a87191256f25642f164844d465b1a581a925f9"
   :status :SUPERSEDED
   :closed "9 ευρήματα ελέγχου· κατάργηση του guessing· δηλωμένες μορφές·
            cluster-roots ως σύνολα· αυστηρό manifest· ακριβές όριο γραμμής"
   :fatal-remaining
   ("ΤΟ TSV ΗΤΑΝ ΑΥΘΕΝΤΙΑ: καμία επαφή με το filesystem. Κατασκευασμένη
     γραμμή για ΑΝΥΠΑΡΚΤΟ αρχείο περνούσε. Οι πύλες του περνούσαν ΚΑΙ ΜΕ
     ΝΕΚΡΟ MOUNT — επιβεβαιώθηκε: το /frozen/ro βρέθηκε ΚΕΝΟ ενώ τα receipts
     του v4 είχαν ήδη εκδοθεί."
    "ΣΙΩΠΗΛΗ ΑΓΝΟΗΣΗ: ό,τι δεν ταίριαζε στον regex ΔΕΝ ΥΠΗΡΧΕ. Έτσι
     «…md:194+213» μετρήθηκε ως γραμμή 194 και «…json:L1-8+» ως L1-8."
    "HASH 6-64 ΧΑΡΑΚΤΗΡΕΣ ενώ το PROTOCOL.sexp:35 ορίζει ΑΚΡΙΒΩΣ 12."))
  (:version 5 :sha256 "8939605723dd0772f5e142c9ae4d140746d395a95ba2e8c165e53bda2e584a12"
   :status :CURRENT
   :delta
   ("① ΤΟ TSV ΔΕΝ ΕΙΝΑΙ ΑΥΘΕΝΤΙΑ. Κάθε αρχείο που παραπέμπεται ελέγχεται ΣΤΟΝ
      ΔΙΣΚΟ: lstat · κανονικό αρχείο · ΚΑΝΕΝΑ symlink component σε κανέναν
      πρόγονο · containment μετά από canonical resolution · ΠΡΑΓΜΑΤΙΚΟ sha256
      · ΠΡΑΓΜΑΤΙΚΑ bytes · ΠΡΑΓΜΑΤΙΚΕΣ λογικές γραμμές · εύρος έναντι αυτών."
    "② Η ΤΑΥΤΟΤΗΤΑ ΞΑΝΑΫΠΟΛΟΓΙΖΕΤΑΙ από τις ίδιες τις γραμμές του TSV και
      αντιπαραβάλλεται με τη σφραγισμένη αυθεντία. Πείραγμα του TSV κοκκινίζει
      ΠΡΙΝ κοιταχτεί έστω μία παραπομπή."
    "③ FAIL-CLOSED ΓΡΑΜΜΑΤΙΚΗ: ανίχνευση ΕΠΙΤΡΕΠΤΙΚΗ, επικύρωση ΑΥΣΤΗΡΗ.
      Κακοσχηματισμένη παραπομπή ΑΝΑΦΕΡΕΤΑΙ, δεν αγνοείται."
    "④ ΓΡΑΜΜΑΤΙΚΗ ΚΑΤΑ PROTOCOL.sexp:35 — hash ΑΚΡΙΒΩΣ 12· τερματικός φραγμός
      που πιάνει trailing garbage· «path:» χωρίς ψηφίο = πρόζα, δεν μετριέται."
    "⑤ ΤΟ MOUNT ΕΙΝΑΙ ΠΥΛΗ: χωρίς επαληθευμένο read-only mount στο
      /proc/self/mountinfo καμία κρίση δεν εκδίδεται. (ΟΧΙ os.path.ismount —
      αποτυγχάνει σε bind mount στο ίδιο filesystem.)"
    "⑥ Ο parser απορρίπτει unterminated strings, dangling escapes, διπλά
      κλειδιά, διπλό :cluster-roots, μη-συμβολοσειρά roots."
    "⑦ Η διαδρομή του mount ΔΗΛΩΝΕΤΑΙ στη σφραγισμένη αυθεντία, δεν είναι
      σταθερά κώδικα — και δεσμεύεται σε κάθε receipt μέσω του hash της.")
   :witnesses
   (:file "experiment/runner/resolver-witnesses.py"
    :sha256 "727c1f1b4e131f44fd8a9bfcb441ecb5a37cf0ed25d4234a2da39100a927219e"
    :positive 9 :negative 45 :total 54 :result :ALL-PASS
    :comparison :EXACT-OUTPUT
    :comparison-note
     "ΟΧΙ exit code + υποσυμβολοσειρά — αυτό δεχόταν λάθος έξοδο αρκεί να
      περιείχε τη σωστή λέξη. Κάθε μάρτυρας δηλώνει την ΑΚΡΙΒΗ έξοδο και
      συγκρίνεται γραμμή προς γραμμή. Η ΜΟΝΗ δηλωμένη χαλάρωση: οι τιμές
      sha256 γίνονται «<SHA>», επειδή αλλάζουν ανά στημένο δέντρο."
    :real-mount "Οι μάρτυρες στήνουν ΠΡΑΓΜΑΤΙΚΟ read-only bind mount — ο v5
                 δεν κρίνει χωρίς αυτό, άρα ούτε οι μάρτυρές του."
    :new-negatives
     ("ΑΝΥΠΑΡΚΤΟ αρχείο με ΚΑΤΑΣΚΕΥΑΣΜΕΝΗ εγγραφή manifest"
      "λάθος bytes · λάθος sha256 · λάθος πλήθος γραμμών στο manifest"
      "ΠΑΡΑΛΕΙΨΗ αρχείου από το manifest"
      "ΤΑΥΤΟΤΗΤΑ manifest ≠ σφραγισμένη (πειραγμένο TSV)"
      "unterminated string · dangling escape · μη κλεισμένη παρένθεση"
      "διπλό κλειδί · διπλό :cluster-roots · μη-συμβολοσειρά root"
      "trailing citation suffix «:1+3» · sha256 μήκους 13"
      "LEGACY μονή γραμμή · LEGACY εύρος χωρίς hash · παράλειψη end"
      "ΛΙΣΤΑ ΚΟΜΜΑΤΟΣ κανονική ΚΑΙ legacy — απορρίπτεται ΟΛΟΚΛΗΡΗ"
      "κόμμα ΣΤΙΞΗΣ που ΔΕΝ πρέπει να επηρεάζει (θετικός)"
      "mount που ΔΕΝ είναι mount"))))

 ;; ── ΤΕΛΙΚΗ ΜΟΝΑΔΙΚΗ ΕΚΤΕΛΕΣΗ ────────────────────────────────────────
 :gate-run
 (:runner "experiment/runner/run-citation-gates-v5.sh"
  :runner-sha256 "sha256:967ab1e38eed2b15dea56fb39833b959c269abaacbad4c87475d2946a8483be4"
  :receipt "experiment/artifacts/gate-receipts/20260824T215725Z/RECEIPT.sexp"
  :single-shot t :same-mount-namespace t :agents-rerun nil
  :frozen-commit-explicit t :never-head t
  :mount-options "ro,nosuid,nodev,noexec,relatime"
  :source-immobility
   (:method "αποτύπωμα ΤΥΠΟΥ+MODE+ΜΕΓΕΘΟΥΣ+ΔΙΑΔΡΟΜΗΣ κάθε leaf της
             /frozen/watchtower, ΠΡΙΝ και ΜΕΤΑ τις πύλες"
    :why "Το read-only bind ΔΕΝ ακινητοποιεί την writable πηγή. Μόνο
          ΤΑΥΤΟΣΗΜΟ αποτύπωμα πριν/μετά το αποδεικνύει."
    :before "sha256:f5c7b21b52d56ec76cf6c288b63ea24b4b2157e8e1e6871a28f34b3fd7b70432"
    :after  "sha256:f5c7b21b52d56ec76cf6c288b63ea24b4b2157e8e1e6871a28f34b3fd7b70432"
    :identical t)
  :attestation-repeated-after-gates t
  :receipts-atomic "εγγραφή σε .tmp και mv — ποτέ επιτόπια"
  :unmount-on-trap t

  :results
  ((:lane "Φ1A-L1" :dossier "experiment/phase1a/source-rev3.sexp"
    :dossier-sha256 "sha256:5bb2675adb08e55fe735861a87c55dd862085b87747dd33e8b2986ba8e06b5ea"
    :citations 360 :resolved 348 :problems 12 :exit 1 :verdict :FAIL)
   (:lane "Φ1A-L2" :dossier "experiment/phase1a/systems-rev2.sexp"
    :dossier-sha256 "sha256:54849c597201ccb0de29b6b86c1c87829cf2f1d255011180f1c855a3c7613521"
    :citations 296 :resolved 296 :problems 0 :exit 0 :verdict :RECOGNIZED-CITATION-INTEGRITY)
   (:lane "Φ1A-L3" :dossier "experiment/phase1a/authority-v2-rev2.sexp"
    :dossier-sha256 "sha256:5f4506e44973dc792439039b26c32df75b42a3766eaacdfc7ba2a66d450dbda4"
    :citations 203 :resolved 203 :problems 0 :exit 0 :verdict :RECOGNIZED-CITATION-INTEGRITY)
   (:lane "Φ1A-L4" :dossier "experiment/phase1a/deployment-specs-rev2.sexp"
    :dossier-sha256 "sha256:d48c47d92ec1e529ca9ede7e9752601deaa537ef8743f5cce6dc3de3cf6490b8"
    :citations 289 :resolved 284 :problems 5 :exit 1 :verdict :FAIL)
   (:lane "Φ1A-L5" :dossier "experiment/phase1a/deployment-state-rev2.sexp"
    :dossier-sha256 "sha256:6897eb6486c83b799a8edf7febafef90b8e896949ab3a9a9c55a5e24b8bdb2bd"
    :citations 183 :resolved 183 :problems 0 :exit 0 :verdict :RECOGNIZED-CITATION-INTEGRITY)
   (:lane "Φ1A-L6" :dossier "experiment/phase1a/harness-rev2.sexp"
    :dossier-sha256 "sha256:8e5910f4dc6d328410cc5e72d4bbe4004f19656678215f6653756c9c2919eb9e"
    :citations 121 :resolved 121 :problems 0 :exit 0 :verdict :RECOGNIZED-CITATION-INTEGRITY)
   (:lane "Φ1A-L7" :dossier "experiment/phase1a/contracts-rev2.sexp"
    :dossier-sha256 "sha256:e7ae502e8fb3469ac232c7e8808461459220e36eac90cea70c9f59d05b1bcc22"
    :citations 104 :resolved 104 :problems 0 :exit 0 :verdict :RECOGNIZED-CITATION-INTEGRITY))

  :aggregate (:unique-citation-keys 1556 :resolved 1539 :problems 17)
  :aggregate-note
   "ΤΟ ΑΘΡΟΙΣΜΑ ΔΕΝ ΕΙΝΑΙ ΠΡΟΟΔΟΣ. ΔΥΟ διαδρομές είναι ΚΟΚΚΙΝΕΣ (L1, L4).
    Η αύξηση 1221→1555 ΔΕΝ είναι νέα ευρήματα: είναι 427 αναφορές γραμμών που
    ΥΠΗΡΧΑΝ ΠΑΝΤΑ μέσα σε λίστες κόμματος και ήταν ΑΟΡΑΤΕΣ στη σάρωση κάθε
    προηγούμενης έκδοσης. Η πύλη μετρούσε ~71% των πραγματικών αγκυρών.")

 ;; ── Η ΣΥΓΚΕΝΤΡΩΤΙΚΗ ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ─────────────────────────────────
 :canonicalization
 (:tool "experiment/runner/canonicalize-citations.py"
  :sha256 "sha256:c0a37e8239449fd9e6d4e60da1a8dd4528d2e255d17caca3b0f2dbb2f5d5003c"
  :single-pass t :dossiers 7 :transformations 1475
  :by-kind (:single-line 360 :range 834 :comma-list 281)
  :comma-list-effect "427 πρώην ΑΟΡΑΤΕΣ αναφορές γραμμών μπήκαν στην πύλη"
  :hash-source "ΠΑΝΤΑ από το ΕΠΑΛΗΘΕΥΜΕΝΟ ΠΡΑΓΜΑΤΙΚΟ αρχείο του παγωμένου mount"
  :reverse-proof (:per-dossier t :result "PASS 7/7"
   :method "αντικατάσταση κάθε κανονικού token με το καταγεγραμμένο legacy
            στη δηλωμένη θέση ⇒ ΤΑΥΤΟ κείμενο με το προηγούμενο")
  :claim-bytes-changed nil
  :never-touched
   ("παραπομπές που δεν λύνονται μονοσήμαντα (11 της Φ1A-L1)"
    "ΚΑΚΟΣΧΗΜΑΤΙΣΜΕΝΑ tokens — ΚΑΙ τα έγκυρα στοιχεία που συνυπάρχουν στο ΙΔΙΟ
     token: ποτέ δεν γίνεται δεκτό έγκυρο ΠΡΟΘΕΜΑ κακοσχηματισμένου token")
  :map "experiment/artifacts/l1-admission-forensics/CANONICALIZATION-MAP.json"
  :authorized-split
   (:token "DEPENDENCY-CONTRACT.md:194+213"
    :became "DEPENDENCY-CONTRACT.md:L194-L194@sha256:65a3f5df825c  +
             DEPENDENCY-CONTRACT.md:L213-L213@sha256:65a3f5df825c"
    :not "«194-213» — αυτό θα εισήγαγε ΨΕΥΔΗ ισχυρισμό για 20 γραμμές"
    :verified-in-frozen-file
     "γραμμή 194 = «docker/verify-deps.sh» · γραμμή 213 = «   docker/verify-deps.sh»
      · αρχείο 258 λογικών γραμμών"
    :record "experiment/artifacts/l1-admission-forensics/L7-AUTHORIZED-SPLIT.json"))

 ;; ── ΑΝΑΚΛΗΣΕΙΣ ──────────────────────────────────────────────────────
 :retractions
 ((:claim "1220/1220 παραπομπές λυμένες, 0 προβληματικές" :under :v3
   :status :RETRACTED :cause "existence-based guessing του v3")
  (:claim "ALL SEVEN LANES DELIVERED — CITATION GATES PASSED" :under :v3
   :status :RETRACTED :cause "ΤΡΕΙΣ διαδρομές αποτυγχάνουν υπό v5")
  (:claim "1221 είναι ο συνολικός αριθμός παραπομπών" :under "v5 πριν την κανονικοποίηση"
   :status :RETRACTED
   :cause "Οι λίστες κόμματος έκρυβαν 506 αναφορές γραμμών από τον σαρωτή.")
  (:claim "μόνο το L1 μπλοκάρει" :under :v4
   :status :RETRACTED
   :cause "Ο v4 αγνοούσε σιωπηλά κακοσχηματισμένες παραπομπές. Υπό v5 βρέθηκαν
           2 στη L4 και 1 στη L7. Η άρνηση αποδοχής ήταν ΟΡΘΗ.")
  (:claim "Φ1A-L7 :SEALED" :under :v3
   :status :RETRACTED
   :cause "Στηριζόταν σε receipt πύλης που δεν έβλεπε το «+213»."))

 ;; ── ΟΡΟΛΟΓΙΑ ────────────────────────────────────────────────────────
 :terminology
 (:counted-unit "ΜΟΝΑΔΙΚΑ ΚΛΕΙΔΙΑ ΠΑΡΑΠΟΜΠΗΣ (unique citation identities)"
  :not "textual occurrences"
  :example "Η μετανάστευση της L1 άγγιξε 327 ΕΜΦΑΝΙΣΕΙΣ ΚΕΙΜΕΝΟΥ που
            αντιστοιχούν σε 272 ΜΟΝΑΔΙΚΑ ΚΛΕΙΔΙΑ. Τα δύο νούμερα ΔΕΝ είναι
            εναλλάξιμα και δεν αναφέρονται το ένα ως το άλλο.")

 ;; ── ΑΝΕΞΑΡΤΗΤΗ ΕΠΑΛΗΘΕΥΣΗ ΜΕΤΑΝΑΣΤΕΥΣΗΣ ────────────────────────────
 :independent-migration-verification
 (:tool "experiment/runner/migration-verifier.py"
  :sha256 "sha256:cc0424743d0943c26d30acf0fa05bf55789d39887481cb8e32ed9d150158bd6a"
  :imports-resolver-code nil
  :independence "Δικός του σαρωτής, δική του απαρίθμηση (git ls-tree), δική
                 του ανάγνωση από το mount, δική του ταξινόμηση."
  :checks 15 :result :PASS
  :independently-confirmed
   ((:what "327 αντικαταστάσεις, όλες φέρουν το πρόθεμα στη δηλωμένη θέση")
    (:what "αντίστροφη ανακατασκευή ⇒ ΤΑΥΤΟ sha256 με το πρωτότυπο")
    (:what "byte delta 2289 = 327 × 7")
    (:what "3 ήδη έγκυρες · 272 μονοσήμαντα · 11 κρατούμενα")
    (:what "οι 3 και τα 11 ΑΥΤΟΥΣΙΑ στο rev2")
    (:what "και οι 272 λύνονται σε ΠΡΑΓΜΑΤΙΚΟ αρχείο και εύρος στο /frozen/ro")
    (:what "το σύνολο ονομάτων ταυτίζεται με το ανεξάρτητα υπολογισμένο"))
  :scope-limit "Επαληθεύει ΜΕΤΑΣΧΗΜΑΤΙΣΜΟ και ΑΓΚΥΡΩΣΗ. ΟΧΙ αλήθεια ισχυρισμών.")

 :classification-status
 (:artifact "experiment/artifacts/l1-admission-forensics/CLASSIFICATION.json"
  :produced-by :RESOLVER-CODE
  :standing :PROVISIONAL
  :must-not-be-cited-as "ανεξάρτητη απόδειξη ότι C=0"
  :why "Η κατάταξη κάλεσε τις ΙΔΙΕΣ συναρτήσεις του resolver. Συμφωνία με τον
        εαυτό του δεν είναι ανεξάρτητη επιβεβαίωση. Ο migration-verifier
        επιβεβαίωσε ΑΝΕΞΑΡΤΗΤΑ τα πλήθη 3/272/11 — ΟΧΙ τη γενική πρόταση C=0.")

 :where-state-lives "experiment/phase1a/LANE-STATE-LEDGER.sexp"
 :where-l1-forensics-live "experiment/phase1a/L1-ADMISSION-BOUNDARY.sexp"
 :where-v1-v4-history-lives "experiment/phase1a/GATE-LEDGER-v3-v4.historic.sexp")
