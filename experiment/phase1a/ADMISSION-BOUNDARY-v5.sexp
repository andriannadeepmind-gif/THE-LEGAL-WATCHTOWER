;;;; experiment/phase1a/ADMISSION-BOUNDARY-v5.sexp
;;;; ΤΟ ΟΡΙΟ ΑΠΟΔΟΧΗΣ ΜΕΤΑ ΤΗ ΔΙΟΡΘΩΣΗ ΚΑΤΑΣΚΕΥΗΣ
;;;;
;;;; Αντικαθιστά το L1-ADMISSION-BOUNDARY.sexp, που είναι πλέον
;;;; HISTORIC-V4/SUPERSEDED: παρήχθη με πύλη που είχε στατική λίστα
;;;; επεκτάσεων, δεν άγγιζε filesystem, και δεχόταν προθέματα tokens.

(:lawmax-admission-boundary/5
 :verdict :FRONTIER-BLOCKED
 :gate-receipt "experiment/artifacts/gate-receipts/20260824T224445Z/RECEIPT.json"
 :supersedes "experiment/phase1a/L1-ADMISSION-BOUNDARY.sexp"

 ;; ── ΤΙ ΑΠΟΔΕΙΚΝΥΕΙ Η ΠΥΛΗ, ΚΑΙ ΤΙ ΟΧΙ ────────────────────────────────
 :verdict-name :RECOGNIZED-CITATION-INTEGRITY
 :proves "Κάθε token παραπομπής ΠΟΥ ΑΝΑΓΝΩΡΙΣΤΗΚΕ δείχνει σε πραγματικά bytes
          και πραγματικό εύρος του παγωμένου snapshot, με ανάγνωση
          descriptor-anchored (openat2 · RESOLVE_BENEATH|NO_SYMLINKS|NO_XDEV)."
 :does-not-prove
 ((:id :CLAIM-CITATION-COVERAGE :status :OPEN
   :requires "μητρώο claim-id → citation IDs· ΤΟΥΛΑΧΙΣΤΟΝ μία έγκυρη
              παραπομπή ανά claim block")
  (:id :CLAIM-ENTAILMENT :status :OPEN
   :requires "απόδειξη ότι το cited span ΣΤΗΡΙΖΕΙ τον ισχυρισμό")
  (:id :READ-LEDGER :status :OPEN)
  (:id :MACRO-LAYER :status :OPEN))
 :forbidden-phrasing "«citation gates passed» με την ευρύτερη έννοια"

 ;; ── ΚΑΤΑΣΤΑΣΗ ΑΝΑ ΔΙΑΔΡΟΜΗ ──────────────────────────────────────────
 :lanes
 ((:lane "Φ1A-L2" :dossier "experiment/phase1a/systems-rev2.sexp"
   :sha256 "54849c597201ccb0de29b6b86c1c87829cf2f1d255011180f1c855a3c7613521"
   :citations 296 :resolved 296 :problems 0 :status :CURRENT-ADMISSIBLE)
  (:lane "Φ1A-L3" :dossier "experiment/phase1a/authority-v2-rev4.sexp"
   :sha256 "fa93d9e2cab1d31d1e3dc2798c0d0c4ffd679bd8df1ebd1652ff482d122f39ff"
   :citations 211 :resolved 211 :problems 0 :status :CURRENT-ADMISSIBLE)
  (:lane "Φ1A-L5" :dossier "experiment/phase1a/deployment-state-rev4.sexp"
   :sha256 "39dc5cafe52cba8ba786c46dbb3dc0794f26cf8b70ab25447721be35338a04fd"
   :citations 189 :resolved 189 :problems 0 :status :CURRENT-ADMISSIBLE)
  (:lane "Φ1A-L6" :dossier "experiment/phase1a/harness-rev4.sexp"
   :sha256 "8aab586cbe336d4aa1d23e681d4807f7f689026347d46f6fcceb443547d74ba3"
   :citations 144 :resolved 144 :problems 0 :status :CURRENT-ADMISSIBLE)
  (:lane "Φ1A-L1" :dossier "experiment/phase1a/source-rev3.sexp"
   :sha256 "5bb2675adb08e55fe735861a87c55dd862085b87747dd33e8b2986ba8e06b5ea"
   :citations 360 :resolved 348 :problems 12 :status :QUARANTINED)
  (:lane "Φ1A-L4" :dossier "experiment/phase1a/deployment-specs-rev3.sexp"
   :sha256 "56abf057df4f144ff1a079cd748a9e3963d7ddc1a654af558764f5fd4d160dcc"
   :citations 290 :resolved 285 :problems 5 :status :QUARANTINED)
  (:lane "Φ1A-L7" :dossier "experiment/phase1a/contracts-rev3.sexp"
   :sha256 "0b0116df0f8eb913c8a3e5bee74f001c2407c0b40aa31a5b20b082d2bab7886c"
   :citations 164 :resolved 154 :problems 10 :status :QUARANTINED
   :predecessor "contracts.sexp (6ab0457e…) — HISTORICALLY-SEALED /
                 NOT-CURRENTLY-ADMISSIBLE-UNDER-V6· ΑΝΕΠΑΦΟ"))
 :aggregate (:unique-citation-keys 1654 :resolved 1627 :problems 27)

 ;; ── ΤΑΞΙΝΟΜΗΣΗ ΤΩΝ 27 ΥΠΟΛΟΙΠΩΝ ─────────────────────────────────────
 :residual-arithmetic "21 + 1 + 5 = 27 ✓  (η προηγούμενη καταγραφή έλεγε
                        22 + 1 + 4 — ΛΑΘΟΣ ΚΑΤΑΝΟΜΗ: το άθροισμα ήταν σωστό
                        αλλά η κατανομή όχι· το άκυρο εύρος της L1 είχε
                        προσμετρηθεί λάθος και ένα L4 token έλειπε)"
 :residual-taxonomy
 ((:class :SYNTAX-ONLY :count 0
   :meaning "μηχανικά κανονικοποιήσιμο χωρίς καμία κρίση"
   :note "ΕΞΑΝΤΛΗΘΗΚΕ. Και τα 1.627 κανονικοποιήθηκαν ντετερμινιστικά.")
  (:class :AMBIGUOUS-PATH :count 21 :breakdown (:Φ1A-L1 11 :Φ1A-L7 10)
   :meaning "η ΔΙΑΔΡΟΜΗ δεν προσδιορίζεται μονοσήμαντα· μόνο η διαδρομή
             που έγραψε τον ισχυρισμό ξέρει ποιο αρχείο διάβασε")
  (:class :INVALID-RANGE :count 1 :breakdown (:Φ1A-L1 1)
   :meaning "το αρχείο ταυτοποιείται· το εύρος ΔΕΝ υπάρχει")
  (:class :SEMANTIC-DECISION :count 5 :breakdown (:Φ1A-L4 5)
   :meaning "αφράγματο εύρος «+» — απαιτεί απόφαση για το ΤΕΛΟΣ")
  (:class :ENTAILMENT-FAILURE :count :NOT-DETERMINABLE-BY-THIS-GATE
   :meaning "το span υπάρχει αλλά ΔΕΝ στηρίζει τον ισχυρισμό"
   :why "Η πύλη ΔΕΝ αξιολογεί στήριξη. Η κλάση υπάρχει στην ταξινομία και
         παραμένει ΑΜΕΤΡΗΤΗ μέχρι να κατασκευαστεί CLAIM-ENTAILMENT."))

 ;; ── ΟΙ ΧΩΡΙΣΤΕΣ ΕΝΤΟΛΕΣ — ΠΡΟΕΤΟΙΜΑΣΜΕΝΕΣ, ΜΗ ΕΚΚΙΝΗΜΕΝΕΣ ──────────
 :charges
 ((:lane "Φ1A-L1" :tokens 12 :files 4 :status :PREPARED-NOT-DISPATCHED
   :items
   ((:kind :AMBIGUOUS-PATH :count 11
     :detail "γυμνά ονόματα: config.lisp ×4 · memory.lisp ×4 · protocols.lisp ×3.
              Τα config.lisp/memory.lisp/protocols.lisp έχουν ΠΟΛΛΑΠΛΟΥΣ
              υποψηφίους στο corpus (source/ · systems/ · third-party/).
              Ένα από αυτά («memory.lisp:110,164») είναι ΚΑΙ λίστα κόμματος.")
    (:kind :INVALID-RANGE :count 1
     :detail "capability-registry.lisp:40-207 σε αρχείο 206 γραμμών. Οι ΑΛΛΕΣ
              δύο παραπομπές στο ίδιο αρχείο είναι έγκυρες, άρα ΔΕΝ πρόκειται
              για λάθος αρχείο αλλά για υπέρβαση ορίου κατά μία γραμμή."))
   :permitted "ΜΟΝΟ στα claim blocks που αγγίζουν αυτές τις 12: διόρθωση,
               υποβάθμιση, ανάκληση, ή :anchor-lost όταν το ΠΡΑΓΜΑΤΙΚΟ span
               ΔΕΝ στηρίζει τον ισχυρισμό."
   :forbidden ("επανάγνωση των 133 αρχείων" "νέα αρχαιολογία"
               "μεταβολή οποιασδήποτε από τις 348 λυμένες"))
  (:lane "Φ1A-L4" :tokens 5 :root-causes 2 :status :PREPARED-NOT-DISPATCHED
   :items
   ((:kind :SEMANTIC-DECISION :count 4
     :detail "deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:L79+ (και τρεις
              συνδυασμοί που το περιέχουν). Το αρχείο έχει 351 γραμμές· ΠΟΙΟ
              είναι το τέλος του εύρους ΔΕΝ προκύπτει μηχανικά.")
    (:kind :SEMANTIC-DECISION :count 1
     :detail "deployment/verify/vectors/merkle/vectors.json:L1-8+ σε αρχείο
              127 γραμμών."))
   :note "Τα 3 έγκυρα στοιχεία (L9-37 · L40-76 · L28-29) έμειναν legacy επειδή
          συνυπάρχουν στο ΙΔΙΟ token με το «L79+» — fail-closed: ποτέ δεν
          γίνεται δεκτό έγκυρο ΠΡΟΘΕΜΑ κακοσχηματισμένου token."
   :permitted "ΜΟΝΟ στα claim blocks αυτών των 5.")
  (:lane "Φ1A-L7" :tokens 10 :status :PREPARED-NOT-DISPATCHED
   :items
   ((:kind :AMBIGUOUS-PATH :count 10
     :detail "«README:300-305», «README:20-21», «README:18», «README:19»,
              «README:332», «README:64-65», «README:230», «README:174-181»,
              «README:19-21», «README:185-187».
              ΜΗΧΑΝΙΚΑ ΕΠΑΛΗΘΕΥΜΕΝΟ: ΔΕΝ υπάρχει «README» στη ρίζα του corpus.
              Υπάρχει «README.md» (389 γραμμές) ΚΑΙ 47 «third-party/*/README».
              Η αντιστοίχιση σε «README.md» είναι ΠΙΘΑΝΗ αλλά ΟΧΙ μηχανική."))
   :permitted "ΜΟΝΟ στα claim blocks αυτών των 10."))

 :locked ("ΚΑΜΙΑ reconciliation" "ΚΑΜΙΑ σφράγιση φάσης"
          "ΚΑΜΙΑ αξίωση πλήρους citation coverage ή entailment"
          "ΚΑΝΕΝΑΣ πράκτορας δεν εκκινήθηκε"))
