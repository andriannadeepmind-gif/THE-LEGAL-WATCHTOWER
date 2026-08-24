;;;; experiment/phase1a/LANE-STATE-LEDGER.sexp
;;;; ΠΑΡΑΓΩΓΗ ΟΨΗ ΚΑΤΑΣΤΑΣΗΣ — ΟΧΙ APPEND-ONLY, ΚΑΙ ΔΕΝ ΤΟ ΙΣΧΥΡΙΖΕΤΑΙ
;;;;
;;;; ΔΙΟΡΘΩΣΗ ΔΙΑΤΥΠΩΣΗΣ: η προηγούμενη έκδοση αυτοαποκαλούνταν «append-only»
;;;; ενώ ήταν ένα απλό αρχείο sexp που μπορούσε να ξαναγραφτεί ολόκληρο χωρίς
;;;; ίχνος. Ο όρος ήταν ΑΝΑΛΗΘΗΣ. Αντί να χαλαρώσει απλώς η ονομασία,
;;;; ΚΑΤΑΣΚΕΥΑΣΤΗΚΕ η ισχυρή ιδιότητα: το ΠΡΑΓΜΑΤΙΚΟ append-only μητρώο είναι
;;;; το experiment/phase1a/EVENT-LEDGER.jsonl, με hash-chain
;;;;     entry_hash(n) = SHA256("LAWMAX-EVENT/1\0" ‖ prev_hash(n) ‖ canonical(payload))
;;;; και επαληθεύεται με `experiment/runner/event-ledger.py verify`.
;;;; ΑΥΤΟ εδώ είναι ΠΑΡΑΓΩΓΗ ΟΨΗ της τρέχουσας κατάστασης — αναγνώσιμη από
;;;; άνθρωπο, ΧΩΡΙΣ αξίωση αμεταβλητότητας. Δεν συμμετέχει στην επίλυση.

(:lawmax-lane-state-view/2
 :nature :DERIVED-VIEW
 :append-only nil
 :append-only-lives-in "experiment/phase1a/EVENT-LEDGER.jsonl"
 :event-chain-head "sha256:e8818e16813d4d3352a411ff40f523852a8787bdd701c149ae879be054c72c48"
 :event-chain-links 14
 :never-consulted-by-resolver t
 :scope-authority "experiment/phase1a/LANE-SCOPE-AUTHORITY.sexp"
 :scope-authority-sha256 "dad69668f4ee083d873fe017fc8d13f94ec9bb231a2649a898f4685e70dce6f5"
 :gate-receipt "experiment/artifacts/gate-receipts/20260824T224445Z/RECEIPT.json"

 :status-vocabulary
 ((:status :delivered  :means "η διαδρομή παρέδωσε dossier")
  (:status :complete   :means "η διαδρομή δηλώνει κάλυψη — ΑΥΤΟΑΝΑΦΟΡΑ")
  (:status :current-admissible
   :means "ΥΠΑΡΧΕΙ receipt RECOGNIZED-CITATION-INTEGRITY υπό τον τρέχοντα resolver")
  (:status :quarantined :means "η πύλη ΑΠΕΤΥΧΕ και δεν έχει αρθεί")
  (:status :lane-sealed :means "ΔΕΝ απονέμεται αυτόματα· απαιτεί read-ledger
                                ΚΑΙ claim-citation coverage ΚΑΙ ρητή απόφαση"))
 :non-implication
 "ΤΟ :complete ΔΕΝ ΣΥΝΕΠΑΓΕΤΑΙ :current-admissible.
  ΤΟ :current-admissible ΔΕΝ ΣΥΝΕΠΑΓΕΤΑΙ :lane-sealed.
  ΚΑΜΙΑ διαδρομή ΔΕΝ είναι :lane-sealed."

 :lane-state
 ((:lane "Φ1A-L1" :dossier "experiment/phase1a/source-rev3.sexp" :revision 3
   :dossier-sha256 "5bb2675adb08e55fe735861a87c55dd862085b87747dd33e8b2986ba8e06b5ea"
   :delivered t :complete t :current-admissible nil :quarantined t :lane-sealed nil
   :gate (:citations 360 :resolved 348 :problems 12)
   :blocker "12 κλειδιά σε 4 αρχεία: 11 AMBIGUOUS-PATH + 1 INVALID-RANGE")
  (:lane "Φ1A-L2" :dossier "experiment/phase1a/systems-rev2.sexp" :revision 2
   :dossier-sha256 "54849c597201ccb0de29b6b86c1c87829cf2f1d255011180f1c855a3c7613521"
   :delivered t :complete t :current-admissible t :quarantined nil :lane-sealed nil
   :gate (:citations 296 :resolved 296 :problems 0))
  (:lane "Φ1A-L3" :dossier "experiment/phase1a/authority-v2-rev4.sexp" :revision 4
   :dossier-sha256 "fa93d9e2cab1d31d1e3dc2798c0d0c4ffd679bd8df1ebd1652ff482d122f39ff"
   :delivered t :complete t :current-admissible t :quarantined nil :lane-sealed nil
   :gate (:citations 211 :resolved 211 :problems 0))
  (:lane "Φ1A-L4" :dossier "experiment/phase1a/deployment-specs-rev3.sexp" :revision 3
   :dossier-sha256 "56abf057df4f144ff1a079cd748a9e3963d7ddc1a654af558764f5fd4d160dcc"
   :delivered t :complete t :current-admissible nil :quarantined t :lane-sealed nil
   :gate (:citations 290 :resolved 285 :problems 5)
   :blocker "2 ΣΗΜΑΣΙΟΛΟΓΙΚΕΣ ΑΠΟΦΑΣΕΙΣ («L1-8+» · «L79+») που δηλητηριάζουν 5 κλειδιά")
  (:lane "Φ1A-L5" :dossier "experiment/phase1a/deployment-state-rev4.sexp" :revision 4
   :dossier-sha256 "39dc5cafe52cba8ba786c46dbb3dc0794f26cf8b70ab25447721be35338a04fd"
   :delivered t :complete t :current-admissible t :quarantined nil :lane-sealed nil
   :gate (:citations 189 :resolved 189 :problems 0))
  (:lane "Φ1A-L6" :dossier "experiment/phase1a/harness-rev4.sexp" :revision 4
   :dossier-sha256 "8aab586cbe336d4aa1d23e681d4807f7f689026347d46f6fcceb443547d74ba3"
   :delivered t :complete t :current-admissible t :quarantined nil :lane-sealed nil
   :gate (:citations 144 :resolved 144 :problems 0))
  (:lane "Φ1A-L7" :dossier "experiment/phase1a/contracts-rev3.sexp" :revision 3
   :dossier-sha256 "0b0116df0f8eb913c8a3e5bee74f001c2407c0b40aa31a5b20b082d2bab7886c"
   :delivered t :complete t :current-admissible nil :quarantined t :lane-sealed nil
   :gate (:citations 164 :resolved 154 :problems 10)
   :blocker "10 «README:NNN» — ΔΕΝ υπάρχει «README» στη ρίζα του corpus"
   :predecessor
   (:dossier "experiment/phase1a/contracts.sexp"
    :sha256 "6ab0457e1a7b2993941b95ce8bbf431910876892157e103c7a797d2f4731352d"
    :status :HISTORICALLY-SEALED/NOT-CURRENTLY-ADMISSIBLE-UNDER-V6
    :untouched t)))

 :phase-verdict :FRONTIER-BLOCKED
 :phase-blockers
 ((:id :L1-TWELVE :status :OPEN :count 12)
  (:id :L4-FIVE :status :OPEN :count 5)
  (:id :L7-TEN :status :OPEN :count 10)
  (:id :CLAIM-CITATION-COVERAGE :status :OPEN
   :detail "κανένα μητρώο claim-id → citation IDs")
  (:id :CLAIM-ENTAILMENT :status :OPEN
   :detail "καμία απόδειξη ότι το span ΣΤΗΡΙΖΕΙ τον ισχυρισμό")
  (:id :READ-LEDGER-ABSENT :status :OPEN)
  (:id :MACRO-LAYER-UNEXAMINED :status :OPEN)
  (:id :CORPUS-AUTHORITY-INCOMPLETE :status :CLOSED
   :closed-by "schema 4 · git-tree απαρίθμηση · 35.640 φύλλα ·
               domain-separated ταυτότητα · per-path attestation")
  (:id :ACTUAL-FILE-VERIFICATION-ABSENT :status :CLOSED
   :closed-by "openat2 RESOLVE_BENEATH|NO_SYMLINKS|NO_XDEV ανά παραπεμπόμενο αρχείο")
  (:id :EXTENSION-WHITELIST :status :CLOSED
   :closed-by "αφαιρέθηκε ολοσχερώς· αναγνώριση manifest-driven")
  (:id :UNSAFE-TERMINAL-BOUNDARY :status :CLOSED
   :closed-by "«/» «%» «?» «#» «=» δεν τερματίζουν· κανένα πρόθεμα δεκτό")
  (:id :FAKE-APPEND-ONLY :status :CLOSED
   :closed-by "γνήσια hash-chained αλυσίδα σε EVENT-LEDGER.jsonl")
  (:id :SOURCE-IMMOBILITY-OVERCLAIM :status :CLOSED
   :closed-by "ιδιωτικό mount namespace + tmpfs snapshot από git objects —
               ΔΕΝ υπάρχει διαδρομή προς αυτό από έξω· η σύγκριση δύο άκρων
               δεν χρειάζεται πλέον ως υποκατάστατο"))

 :locked ("ΚΑΜΙΑ reconciliation" "ΚΑΜΙΑ σφράγιση φάσης" "ΚΑΝΕΝΑΣ πράκτορας"))
