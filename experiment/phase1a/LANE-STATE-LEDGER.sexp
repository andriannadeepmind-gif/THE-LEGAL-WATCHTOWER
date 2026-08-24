;;;; experiment/phase1a/LANE-STATE-LEDGER.sexp
;;;; APPEND-ONLY ΜΗΤΡΩΟ ΚΑΤΑΣΤΑΣΗΣ — ΔΕΝ ΣΥΜΜΕΤΕΧΕΙ ΠΟΤΕ ΣΤΗΝ ΕΠΙΛΥΣΗ
;;;;
;;;; ΤΟ ΠΑΛΙΟ LANE-REGISTRY.sexp ΑΠΟΣΥΡΘΗΚΕ. Κουβαλούσε ΤΑΥΤΟΧΡΟΝΑ αμετάβλητη
;;;; αυθεντία εμβέλειας ΚΑΙ μεταβλητή κατάσταση, άρα κάθε γεγονός κατάστασης
;;;; άλλαζε το hash της αυθεντίας που ΕΠΙΛΥΕΙ παραπομπές, και κάθε receipt
;;;; δενόταν σε κινούμενο στόχο. Διασπάστηκε:
;;;;   · LANE-SCOPE-AUTHORITY.sexp — αμετάβλητη· ΜΟΝΟ αυτή δεσμεύει receipts
;;;;   · LANE-STATE-LEDGER.sexp    — αυτό εδώ· append-only· ΚΑΜΙΑ επίλυση
;;;; Ο resolver ΔΕΝ διαβάζει ΠΟΤΕ αυτό το αρχείο.

(:lawmax-lane-state-ledger/1
 :append-only t
 :never-consulted-by-resolver t
 :scope-authority "experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp"
 :scope-authority-sha256 "30df3ec548d86ce31f2d7c8250589a36afd14d34785a8eaeee9cbb57c9936b83"

 :identity-policy
 "Οι runtime χειριστές πρακτόρων είναι ΕΦΗΜΕΡΑ αναγνωριστικά συνεδρίας. Ως
  ΠΡΩΤΟΚΟΛΛΙΚΗ ταυτότητα ισχύουν ΔΙΑΡΚΗ lane IDs (Φ1A-L1..L7), δεμένα σε
  (συστάδα × sha256 συμβολαίου × διαδρομή dossier)."

 ;; ── ΔΙΑΚΡΙΤΕΣ ΚΑΤΑΣΤΑΣΕΙΣ — ΚΑΜΙΑ ΔΕΝ ΣΥΝΕΠΑΓΕΤΑΙ ΤΗΝ ΕΠΟΜΕΝΗ ─────────
 :status-vocabulary
 ((:status :delivered      :means "η διαδρομή παρέδωσε dossier")
  (:status :complete       :means "η διαδρομή δηλώνει ότι κάλυψε τη συστάδα της — ΑΥΤΟΑΝΑΦΟΡΑ")
  (:status :citation-pass  :means "ΥΠΑΡΧΕΙ receipt CITATION-INTEGRITY-PASS υπό τον τρέχοντα resolver")
  (:status :quarantined    :means "η πύλη ΑΠΕΤΥΧΕ και δεν έχει αρθεί")
  (:status :lane-sealed    :means "ΔΕΝ απονέμεται αυτόματα. Απαιτεί ρητή απόφαση ΚΑΙ read-ledger."))
 :non-implication
 "ΤΟ :complete ΔΕΝ ΣΥΝΕΠΑΓΕΤΑΙ :citation-pass. ΤΟ :citation-pass ΔΕΝ
  ΣΥΝΕΠΑΓΕΤΑΙ :lane-sealed. Καμία κατάσταση δεν απονέμεται σιωπηρά."

 ;; ── ΤΡΕΧΟΥΣΑ ΚΑΤΑΣΤΑΣΗ ΑΝΑ ΔΙΑΔΡΟΜΗ — ΜΕΤΑ ΤΗΝ ΚΑΝΟΝΙΚΟΠΟΙΗΣΗ ────────
 :gate-run "experiment/artifacts/gate-receipts/20260824T214933Z/RECEIPT.sexp"
 :lane-state
 ((:lane "Φ1A-L1" :dossier "experiment/phase1a/source-rev3.sexp" :revision 3
   :dossier-sha256 "5bb2675adb08e55fe735861a87c55dd862085b87747dd33e8b2986ba8e06b5ea"
   :supersedes-sha256 "858f4c903e91a11289d3e4830541dbca687a14cd403883758fa04ea559f68807"
   :delivered t :complete t :recognized-citation-integrity nil
   :quarantined t :lane-sealed nil
   :gate (:citations 360 :resolved 348 :problems 12)
   :blocker "ΑΚΡΙΒΩΣ 12 ΚΛΕΙΔΙΑ ΠΑΡΑΠΟΜΠΗΣ σε 4 αρχεία:
             11 ΑΜΦΙΣΗΜΑ γυμνά ονόματα — config.lisp ×4 · memory.lisp ×4 ·
             protocols.lisp ×3 — και 1 ΑΚΥΡΟ ΕΥΡΟΣ:
             capability-registry.lisp:40-207 σε αρχείο 206 γραμμών.
             Απαιτούν κρίση της διαδρομής — ΟΧΙ μηχανική επίλυση."
   :count-correction
    "Το πλήθος ήταν 11 πριν κλείσει η τυφλότητα κόμματος. Είναι 12 τώρα επειδή
     το «memory.lisp:110,164» είναι ΞΕΧΩΡΙΣΤΟ κλειδί από το «memory.lisp:110» —
     πριν συνέπιπταν, γιατί ο σαρωτής έκοβε στο κόμμα. ΤΑ ΑΡΧΕΙΑ παραμένουν 4·
     αυξήθηκε η ΟΡΑΤΟΤΗΤΑ, όχι το πρόβλημα.")
  (:lane "Φ1A-L2" :dossier "experiment/phase1a/systems-rev2.sexp" :revision 2
   :dossier-sha256 "54849c597201ccb0de29b6b86c1c87829cf2f1d255011180f1c855a3c7613521"
   :supersedes-sha256 "e11b7b76d7fdb18cd7cf4d348eac7b81529cc9c004f8d6d56cc93a644ae9c141"
   :delivered t :complete t :recognized-citation-integrity t
   :quarantined nil :lane-sealed nil :current-admissible t
   :gate (:citations 296 :resolved 296 :problems 0))
  (:lane "Φ1A-L3" :dossier "experiment/phase1a/authority-v2-rev2.sexp" :revision 2
   :dossier-sha256 "5f4506e44973dc792439039b26c32df75b42a3766eaacdfc7ba2a66d450dbda4"
   :supersedes-sha256 "c3bf9ce0fe3dd0db3f3a0084201093af969b986afd9cc28843713866935c78f9"
   :delivered t :complete t :recognized-citation-integrity t
   :quarantined nil :lane-sealed nil :current-admissible t
   :gate (:citations 203 :resolved 203 :problems 0))
  (:lane "Φ1A-L4" :dossier "experiment/phase1a/deployment-specs-rev2.sexp" :revision 2
   :dossier-sha256 "d48c47d92ec1e529ca9ede7e9752601deaa537ef8743f5cce6dc3de3cf6490b8"
   :supersedes-sha256 "f895deb6721317b7979ffe44346628c064a2c0c1682b2642658e94f9d507730b"
   :delivered t :complete t :recognized-citation-integrity nil
   :quarantined t :lane-sealed nil
   :gate (:citations 289 :resolved 284 :problems 5)
   :blocker "2 ΡΙΖΙΚΕΣ ΑΙΤΙΕΣ που δηλητηριάζουν 5 κλειδιά:
             ① deployment/verify/vectors/merkle/vectors.json:L1-8+
             ② deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:L79+
             Το «+» σημαίνει «και εξής» — ΑΦΡΑΓΜΑΤΟ εύρος, μη αγκυρώσιμο.
             Επιπλέον 3 κλειδιά (L9-37 · L40-76 · L28-29) έμειναν legacy επειδή
             συνυπήρχαν στο ΙΔΙΟ token με το «L79+»: ο μετασχηματιστής ΔΕΝ
             δέχεται ΠΟΤΕ έγκυρο ΠΡΟΘΕΜΑ κακοσχηματισμένου token — fail-closed.
             Το πραγματικό αρχείο έχει 351 γραμμές· ΠΟΙΟ είναι το τέλος του
             εύρους ΔΕΝ προκύπτει μηχανικά.")
  (:lane "Φ1A-L5" :dossier "experiment/phase1a/deployment-state-rev2.sexp" :revision 2
   :dossier-sha256 "6897eb6486c83b799a8edf7febafef90b8e896949ab3a9a9c55a5e24b8bdb2bd"
   :supersedes-sha256 "27dfbfc852110beade15117a7d02e01ab48485377a623b040dc9f92b1ae79923"
   :delivered t :complete t :recognized-citation-integrity t
   :quarantined nil :lane-sealed nil :current-admissible t
   :gate (:citations 183 :resolved 183 :problems 0))
  (:lane "Φ1A-L6" :dossier "experiment/phase1a/harness-rev2.sexp" :revision 2
   :dossier-sha256 "8e5910f4dc6d328410cc5e72d4bbe4004f19656678215f6653756c9c2919eb9e"
   :supersedes-sha256 "9ddd1820acf40205c1256bccac8c8d689e1683ae7512566168df4ae302237ea9"
   :delivered t :complete t :recognized-citation-integrity t
   :quarantined nil :lane-sealed nil :current-admissible t
   :gate (:citations 121 :resolved 121 :problems 0))
  (:lane "Φ1A-L7" :dossier "experiment/phase1a/contracts-rev2.sexp" :revision 2
   :dossier-sha256 "e7ae502e8fb3469ac232c7e8808461459220e36eac90cea70c9f59d05b1bcc22"
   :supersedes-sha256 "6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"
   :delivered t :complete t :recognized-citation-integrity t
   :quarantined nil :lane-sealed nil :current-admissible t
   :gate (:citations 104 :resolved 104 :problems 0)
   :predecessor-status
    (:dossier "experiment/phase1a/contracts.sexp"
     :sha256 "6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"
     :status :HISTORICALLY-SEALED/NOT-CURRENTLY-ADMISSIBLE-UNDER-V5
     :untouched t
     :why "Σφραγισμένο artifact προηγούμενης admission epoch. ΔΕΝ
           τροποποιείται. Δεν είναι αποδεκτό υπό την τρέχουσα γραμματική."))) 

 ;; ── ΓΕΓΟΝΟΤΑ ΚΑΤΑΣΚΕΥΗΣ (append-only) ────────────────────────────────
 :events
 ((:seq 1 :what :ATTEMPT-1-BLOCKED
   :detail "API session limit· 7 διαδρομές επηρεάστηκαν, 0 dossiers.
            Κατά §12: εξάντληση πόρου ⇒ ΠΟΤΕ FINAL.")
  (:seq 2 :what :CONTRACT-V1 :sha256 "e0a176a26b5aab4fcf1098aa38227a701e0e002887157061222910501225b3f5")
  (:seq 3 :what :CONTRACT-V2 :sha256 "54e0025d981860cada005c5a51ea5e856565b955d7c9f6fa6f766c24dff78040"
   :delta "ΥΠΟΧΡΕΩΤΙΚΟ ΣΤΑΔΙΑΚΟ CHECKPOINT ανά ~15-20 αρχεία")
  (:seq 4 :what :ATTEMPT-2-ALL-SEVEN-DELIVERED :contract 2)
  (:seq 5 :what :GATE-V4-EXPOSED-V3-GUESSING
   :detail "Ο v3 έλυνε γυμνά ονόματα με existence-based guessing. Η L1 έπεσε
            286→3. Η δήλωση «1220/1220» ανακλήθηκε.")
  (:seq 6 :what :L1-DETERMINISTIC-CITATION-ONLY-MIGRATION
   :detail "272 μονοσήμαντα· 327 αντικαταστάσεις· αμφίδρομη απόδειξη· rev2.
            ΧΩΡΙΣ πράκτορα. 11 κρατήθηκαν για κρίση της διαδρομής.")
  (:seq 7 :what :FROZEN-MOUNT-LOST-AND-RESTORED
   :detail "Το /frozen/ro βρέθηκε ΚΕΝΟ (0 leaves· καμία εγγραφή στο
            /proc/self/mountinfo). Τα mounts ΔΕΝ επιβιώνουν μεταξύ κλήσεων σε
            αυτό το περιβάλλον. Επανήλθε με ensure-ro-mount.sh και
            επαληθεύτηκε: 35.640 leaves, 6 symlinks, ταύτιση με το git tree.
            ΣΥΝΕΠΕΙΑ ΓΙΑ ΤΙΣ ΠΡΟΗΓΟΥΜΕΝΕΣ ΑΠΟΔΕΙΞΕΙΣ: ο v4 ΔΕΝ άγγιζε το
            filesystem — έκρινε ΜΟΝΟ από το TSV. Άρα οι πύλες του περνούσαν
            ΚΑΙ ΜΕ ΝΕΚΡΟ MOUNT. Αυτό ΕΙΝΑΙ το ελάττωμα που έκλεισε ο v5.")
  (:seq 8 :what :CORPUS-AUTHORITY-CORRECTED-TO-GIT-TREE
   :detail "Το os.walk έχανε 6 symlinks (35.634 αντί 35.640). Η απαρίθμηση
            μεταφέρθηκε στο git ls-tree. Νέα ταυτότητα PATH-AND-KIND-COMPLETE.
            Η παλιά content-only ρίζα υποβιβάστηκε σε LEGACY-ARTIFACT.")
  (:seq 9 :what :GATE-V5-FOUND-TWO-MORE-BLOCKED-LANES
   :detail "Ο v5 απορρίπτει κακοσχηματισμένες παραπομπές αντί να τις αγνοεί
            σιωπηλά. Βρέθηκαν L4 (2) και L7 (1). Η δήλωση «μόνο το L1
            μπλοκάρει» ΗΤΑΝ ΨΕΥΔΗΣ.")
  (:seq 10 :what :COMMA-LIST-BLINDNESS-DISCOVERED
   :detail "Ο σαρωτής κάθε προηγούμενης έκδοσης έβλεπε ΜΟΝΟ το ΠΡΩΤΟ στοιχείο
            μιας λίστας κόμματος («path:L21-22,L98,L103»). 506 αναφορές
            γραμμών σε ΚΑΙ ΤΑ ΕΠΤΑ dossiers ήταν ΑΟΡΑΤΕΣ στην πύλη: ούτε
            επαληθευμένες ούτε καταμετρημένες. Η πύλη μετρούσε ~71% των
            πραγματικών αγκυρών. Οι λίστες κόμματος ΑΠΑΓΟΡΕΥΤΗΚΑΝ και
            επεκτάθηκαν σε χωριστές κανονικές παραπομπές.")
  (:seq 11 :what :CONSOLIDATED-CANONICALIZATION
   :detail "ΜΙΑ πεπερασμένη migration σε ΚΑΙ ΤΑ ΕΠΤΑ dossiers. 1475
            μετασχηματισμοί: 360 μονές γραμμές · 834 εύρη · 281 λίστες
            κόμματος που έφεραν 427 πρώην αόρατες αναφορές μέσα στην πύλη.
            Αντίστροφη απόδειξη ΑΝΑ DOSSIER: PASS σε 7/7.
            Ορατά μοναδικά κλειδιά: 1221 → 1555.")
  (:seq 12 :what :L7-AUTHORIZED-SPLIT
   :detail "«DEPENDENCY-CONTRACT.md:194+213» ΔΕΝ είναι εύρος. Επαληθεύτηκε στο
            παγωμένο αρχείο (258 γραμμές): γραμμή 194 = «docker/verify-deps.sh»,
            γραμμή 213 = «   docker/verify-deps.sh». ΔΥΟ χωριστές γραμμές.
            Έγινε ΔΥΟ κανονικές παραπομπές L194-L194 και L213-L213.
            ΟΧΙ «194-213» — αυτό θα εισήγαγε ΨΕΥΔΗ ισχυρισμό για 20 γραμμές.")
  (:seq 13 :what :LANE-REGISTRY-RETIRED
   :detail "Διασπάστηκε σε LANE-SCOPE-AUTHORITY (αμετάβλητη) και σε αυτό το
            μητρώο. Το παλιό αρχείο ΔΕΝ υπάρχει πλέον — μία έδρα ανά έννοια."))

 ;; ── ΤΙ ΜΠΛΟΚΑΡΕΙ ΤΗ ΦΑΣΗ ─────────────────────────────────────────────
 :phase-verdict :FRONTIER-BLOCKED
 :phase-blockers
 ((:id :L1-ELEVEN-UNRESOLVED :lane "Φ1A-L1" :count 11 :status :OPEN
   :detail "10 ΑΜΦΙΣΗΜΑ + 1 ΑΚΥΡΟ ΕΥΡΟΣ — απαιτούν κρίση της διαδρομής")
  (:id :L4-MALFORMED-UNBOUNDED-RANGES :lane "Φ1A-L4" :status :OPEN
   :root-causes 2 :affected-keys 5
   :detail "«L1-8+» και «L79+» — αφράγματα εύρη· συν 3 κλειδιά που
            δηλητηριάστηκαν στο ίδιο token")
  (:id :L7-ONE-MALFORMED :lane "Φ1A-L7" :status :CLOSED
   :closed-by "εξουσιοδοτημένος διαχωρισμός σε L194-L194 και L213-L213,
               επαληθευμένος στο πραγματικό παγωμένο αρχείο")
  (:id :CLAIM-CITATION-COVERAGE :status :OPEN
   :detail "ΔΕΝ υπάρχει μητρώο claim-id → citation IDs. Καμία απόδειξη ότι
            κάθε claim block έχει ΤΟΥΛΑΧΙΣΤΟΝ μία έγκυρη παραπομπή.
            ΑΠΑΓΟΡΕΥΕΤΑΙ η φράση «citation gates passed» με την ευρύτερη
            έννοια πριν υπάρξει αυτό.")
  (:id :CLAIM-ENTAILMENT :status :OPEN
   :detail "Καμία απόδειξη ότι το cited span ΣΤΗΡΙΖΕΙ τον ισχυρισμό.
            Η πύλη αποδεικνύει ΥΠΑΡΞΗ span, όχι ΣΤΗΡΙΞΗ.")
  (:id :COMMA-LIST-BLINDNESS :status :CLOSED
   :closed-by "απαγόρευση λιστών κόμματος + επέκταση σε χωριστές παραπομπές·
               427 πρώην αόρατες αναφορές μπήκαν στην πύλη")
  (:id :READ-LEDGER-ABSENT :status :OPEN
   :detail "Κανένα coverage claim δεν είναι δεμένο με read ledger ανά αρχείο
            (canonical path · manifest hash · bytes/εύρη · tool receipt · lane ID).
            ΟΛΩΝ των διαδρομών το CLUSTER-COVERAGE παραμένει :PROVISIONAL.
            Ο χρόνος εκτέλεσης ΔΕΝ είναι ούτε απόδειξη ούτε διάψευση.")
  (:id :MACRO-LAYER-UNEXAMINED :status :OPEN
   :detail "Καμία ανεξάρτητη διαδρομή για reader conditionals, dispatch macros,
            macro-generated execution constructs. Ο sexp tokenizer είναι
            SYNTACTIC CALL-SITE CENSUS, ΟΧΙ runtime call graph.")
  (:id :CORPUS-AUTHORITY-INCOMPLETE :status :CLOSED
   :closed-by "manifest schema 3 — απαρίθμηση από git tree, 35.640 leaves,
               PATH-AND-KIND-COMPLETE ταυτότητα, per-path mount attestation")
  (:id :ACTUAL-FILE-VERIFICATION-ABSENT :status :CLOSED
   :closed-by "resolver v5 — lstat, κανονικό αρχείο, κανένα symlink component,
               containment μετά από canonical resolution, πραγματικά
               sha256/bytes/γραμμές, εύρος έναντι ΠΡΑΓΜΑΤΙΚΩΝ γραμμών"))

 :locked
 ("ΚΑΜΙΑ reconciliation" "ΚΑΜΙΑ προαγωγή σε B⁻" "ΚΑΜΙΑ σφράγιση φάσης"
  "ΚΑΜΙΑ επόμενη φάση"))
