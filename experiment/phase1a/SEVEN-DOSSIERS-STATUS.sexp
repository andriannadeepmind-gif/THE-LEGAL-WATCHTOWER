;;;; experiment/phase1a/SEVEN-DOSSIERS-STATUS.sexp
;;;; ΚΑΙ ΟΙ ΕΠΤΑ ΔΙΑΔΡΟΜΕΣ ΠΑΡΕΔΩΣΑΝ — ΑΤΟΜΙΚΗ ΣΦΡΑΓΙΣΗ, ΟΧΙ ΣΦΡΑΓΙΣΗ ΦΑΣΗΣ
;;;;
;;;; ΤΟ ΚΡΙΣΙΜΟ: η παράδοση και των επτά ΔΕΝ σφραγίζει τη Φάση 1A. Εκκρεμούν
;;;; δύο ρητές απαιτήσεις του δημιουργού που ΔΕΝ έχουν εκπληρωθεί (§3, §6).
;;;; Καμία reconciliation. Καμία προαγωγή σε B⁻. Καμία συνολική κρίση.

(:lawmax-seven-dossiers-status/1
 :phase-status "PHASE-1A: ALL SEVEN LANES DELIVERED — CITATION GATES PASSED — PHASE SEAL BLOCKED"
 :corpus "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
 :corpus-merkle-after-all-gates "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
 :corpus-unchanged t
 :frozen-corpus-paths-unchanged :PASS
 :resolver "v3 sha256:d552d4171bc61669"
 :manifest "sha256:92394c037b133743"

 :dossiers
 ((:lane "Φ1A-L1" :cluster-root "source" :dossier "experiment/phase1a/source.sexp"
   :sha256 "dd3ce7cc6bd973d284dd00adb417afa3e1030bcdca9da32997b435fb4c5e8aef"
   :status :complete :files-read 133 :cluster-size 133 :lines 1202
   :citations 286 :resolved 286 :problems 0
   :self-reported (:capabilities 29 :authorities 14 :invariants 12
                   :defects 111 :hidden-paths 26 :duplicate-seats 28))
  (:lane "Φ1A-L2" :cluster-root "systems" :dossier "experiment/phase1a/systems.sexp"
   :sha256 "e11b7b76d7fdb18cd7cf4d348eac7b81529cc9c004f8d6d56cc93a644ae9c141"
   :status :complete :files-opened 88 :files-mechanically-scanned 87 :cluster-size 175
   :citations 214 :resolved 214 :problems 0
   :self-reported (:capabilities 32 :authorities 9 :invariants 13
                   :defects 33 :hidden-paths 17 :duplicate-seats 19))
  (:lane "Φ1A-L3" :cluster-root "authority-v2" :dossier "experiment/phase1a/authority-v2.sexp"
   :sha256 "c3bf9ce0fe3dd0db3f3a0084201093af969b986afd9cc28843713866935c78f9"
   :status :complete :files-read 61 :cluster-size 61
   :cluster-size-note "η ανάθεση έλεγε 63· find -type f δίνει 61 — η lane το διόρθωσε"
   :citations 165 :resolved 165 :problems 0
   :self-reported (:capabilities 21 :authorities 13 :invariants 14
                   :defects 22 :hidden-paths 7 :duplicate-seats 8))
  (:lane "Φ1A-L4" :cluster-root "deployment" :dossier "experiment/phase1a/deployment-specs.sexp"
   :sha256 "f895deb6721317b7979ffe44346628c064a2c0c1682b2642658e94f9d507730b"
   :status :complete :files-read 66 :lines 576
   :citations 200 :resolved 200 :problems 0
   :self-reported (:capabilities 18 :authorities 10 :invariants 17
                   :defects 28 :hidden-paths 11 :duplicate-seats 14))
  (:lane "Φ1A-L5" :cluster-root "deployment" :dossier "experiment/phase1a/deployment-state.sexp"
   :sha256 "27dfbfc852110beade15117a7d02e01ab48485377a623b040dc9f92b1ae79923"
   :status :complete :files-read 388
   :files-read-breakdown "66 άμεσα + 322 προγραμματικά (SHA-256) + 113 από ευρετήριο"
   :citations 156 :resolved 156 :problems 0
   :self-reported (:capabilities 22 :authorities 8 :invariants 14
                   :defects 46 :hidden-paths 10 :duplicate-seats 12)
   :integrity-note "Η lane ΥΠΟΒΑΘΜΙΣΕ 3 δικούς της ισχυρισμούς αφού τους έλεγξε
                    στην πηγή, και διόρθωσε 2 λάθος εύρη γραμμών.")
  (:lane "Φ1A-L6" :cluster-root "tests" :dossier "experiment/phase1a/harness.sexp"
   :sha256 "9ddd1820acf40205c1256bccac8c8d689e1683ae7512566168df4ae302237ea9"
   :status :complete :files-opened 51 :files-mechanically-scanned 144 :cluster-size 176
   :citations 98 :resolved 98 :problems 0
   :self-reported (:capabilities 9 :authorities 8 :invariants 8
                   :defects 28 :hidden-paths 9 :duplicate-seats 8))
  (:lane "Φ1A-L7" :cluster-root "" :dossier "experiment/phase1a/contracts.sexp"
   :sha256 "6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"
   :status :complete :files-read 79 :cluster-size 79 :lines 408
   :citations 101 :resolved 101 :problems 0
   :self-reported (:capabilities 18 :authorities 7 :invariants 13
                   :defects 30 :hidden-paths 8 :duplicate-seats 8)))

 :aggregate-citations (:total 1220 :resolved 1220 :problems 0)

 ;; ── ΤΙ ΜΠΛΟΚΑΡΕΙ ΤΗ ΣΦΡΑΓΙΣΗ ΤΗΣ ΦΑΣΗΣ ──────────────────────────────────
 :phase-seal-blockers
 ((:id :READ-LEDGER-ABSENT :from "EARLY CORRECTION §3"
   :requirement "Το coverage claim κάθε lane πρέπει να δεθεί με read ledger:
                 canonical path · frozen-manifest hash · bytes ή line ranges που
                 διαβάστηκαν · tool receipt · lane ID — ΑΝΑ ΑΡΧΕΙΟ."
   :current-state "Τα :files-read είναι SELF-REPORTED metadata. Ο citation
                   resolver αποδεικνύει ΑΓΚΥΡΩΣΗ ΙΣΧΥΡΙΣΜΩΝ, ΟΧΙ ανάγνωση."
   :verdict "ΟΛΩΝ ΤΩΝ LANES το CLUSTER-COVERAGE παραμένει :PROVISIONAL"
   :explicit-non-evidence "Ο χρόνος εκτέλεσης ΔΕΝ χρησιμοποιείται ούτε ως
                           απόδειξη ούτε ως διάψευση κάλυψης.")
  (:id :MACRO-LAYER-UNEXAMINED :from "EARLY CORRECTION §6"
   :requirement "Ανεξάρτητη διαδρομή για reader conditionals, dispatch macros
                 και macro-generated execution constructs, ΧΩΡΙΣ read-time
                 evaluation. Να ΜΗΝ επαναλάβει τις υπάρχουσες σαρώσεις."
   :current-state "Ο sexp tokenizer ταξινομείται SYNTACTIC CALL-SITE CENSUS —
                   ΟΧΙ πλήρες runtime call graph. Δεν βλέπει κλήσεις που
                   παράγονται από μακροεντολές ούτε #+/#- κλάδους."
   :verdict "ΕΚΚΡΕΜΕΙ — απαιτείται πριν από τη σφράγιση της Φάσης 1A"))

 ;; ── ΤΙ ΔΕΝ ΓΙΝΕΤΑΙ ΤΩΡΑ ─────────────────────────────────────────────────
 :explicitly-not-done
 ("ΚΑΜΙΑ reconciliation μεταξύ των επτά dossiers"
  "ΚΑΜΙΑ προαγωγή ευρήματος σε B⁻ — όλα παραμένουν UNRECONCILED-CANDIDATE-DEFECTS"
  "ΚΑΜΙΑ συνολική κρίση, καμία ιεράρχηση, κανένας συνολικός αριθμός ελαττωμάτων"
  "ΚΑΜΙΑ διασταύρωση ευρημάτων μεταξύ lanes"
  "ΚΑΜΙΑ αρχιτεκτονική πρόταση")

 :isolation-held
 "Καμία lane δεν διάβασε dossier άλλης lane. Ο ενορχηστρωτής δεν μετέφερε
  ευρήματα από lane σε lane. Οι διορθώσεις παραπομπών που ζητήθηκαν αφορούσαν
  ΑΠΟΚΛΕΙΣΤΙΚΑ τη μορφή διαδρομών του ΙΔΙΟΥ dossier κάθε lane."

 :phase-not-sealed t)
