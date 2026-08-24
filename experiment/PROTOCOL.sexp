;;;; experiment/PROTOCOL.sexp — ΤΟ ΠΡΩΤΟΚΟΛΛΟ ΤΟΥ ΠΕΙΡΑΜΑΤΟΣ
;;;; Ελάχιστο και δεσμευτικό: κάθε ρήτρα αντιστοιχεί σε ονομασμένη proof
;;;; obligation. Ό,τι δεν αντιστοιχεί, δεν μπαίνει.

(:lawmax-experiment-protocol/1
 :frozen-corpus (:commit "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"
                 :merkle "sha256:ad8fd575cce147a8b765cd32fafa77f670491b8def589c88feb09f265d5f346b"
                 :files 35634 :mount :read-only :writes :overlay-upper-only)
 :runner-image "lawmax-runner:frozen"

 :phases
 ((:id 1 :name "Current-system archaeology"
   :inputs (:frozen-corpus :objective-constitution)
   :outputs ("baseline.sexp" "current-system-map.sexp")
   :isolation :none-required
   :obligation "T1 BASELINE-PRESERVATION — το baseline είναι ΜΕΤΡΗΜΕΝΟ, όχι δηλωμένο")
  (:id 2 :name "Blind frontier discovery"
   :inputs (:frozen-corpus :objective-constitution)
   :forbidden-inputs (:phase-1-artifacts :ceiling-crosswalk :incumbent-architecture)
   :isolation :structural
   :enforcement "ΞΕΧΩΡΙΣΤΟ worktree στο ΙΔΙΟ commit + artifacts Φ1 ΕΚΤΟΣ του δέντρου· ο runner ΑΡΝΕΙΤΑΙ εκκίνηση αν ο κατάλογος Φ1 είναι προσπελάσιμος από το cwd"
   :agents :independent-fresh-context
   :obligation "T15 PHASE-NONINTERFERENCE")
  (:id 3 :name "Adversarial dominance judgment"
   :inputs (:frozen-corpus :objective-constitution :phase-1-artifacts :phase-2-proposals)
   :forbidden-inputs (:proposer-rationale :proposer-transcripts)
   :isolation :structural
   :agents :independent-fresh-context
   :duty "ΔΕΝ βαθμολογεί: κατασκευάζει καλύτερη admissible αρχιτεκτονική, counterexample, μη μοντελοποιημένη οικογένεια, ή hidden assumption"
   :obligation "T7 DOMINANCE-CLOSURE · T11 PRUNING-SOUNDNESS")
  (:id 4 :name "Synthesis"
   :inputs :all
   :obligation "T8 (scoped) · T9/T13 CONSTRUCTIVE-REFINEMENT · T4 FINAL-IMPLEMENTABILITY"))

 :citation-format "path:Lstart-Lend@sha256:<12>"
 :citation-rule "Κάθε ισχυρισμός λύνεται στο corpus-manifest.tsv. Παραπομπή που δεν λύνεται ⇒ Η ΦΑΣΗ ΚΟΚΚΙΝΙΖΕΙ. Καμία αφηγηματική βεβαίωση χωρίς άγκυρα."

 :budgets (:unit :wallclock-and-turns
           :on-exhaustion :SUSPENDED-with-checkpoint
           :never :FINAL
           :proved-by "experiment/formal/runner.pml — SPIN, errors: 0")

 :closure-certificate-kinds
 (:violates-hard-invariant :not-implementable-today :equivalent-to-examined-class
  :provably-dominated :branch-upper-bound-below-incumbent)
 :forbidden-pruning-grounds
 ("LLM score" "φαίνεται χειρότερο" "κόστος/tokens" "χρόνος" "στασιμότητα"
  "αριθμός γύρων" "πλειοψηφία πρακτόρων" "ατεκμηρίωτη πρακτική κρίση")

 :anti-self-certification
 "Το closure certificate ΔΕΝ υπογράφεται από τον πράκτορα που παρήγαγε τον υποψήφιο. Ο checker απορρίπτει self-signed closure."

 :final-gate-flags
 (CURRENT_SYSTEM_MAP_COMPLETE FULL_SUITE_CENSUS_COMPLETE TOOLCHAIN_REPRODUCIBLE
  FROZEN_CORPUS_UNCHANGED PUBLIC_FRONTIER_RECONSTRUCTED
  MULTIPLE_ARCHITECTURE_FAMILIES_EXPLORED PARETO_ARCHIVE_NONEMPTY
  NO_BASELINE_REGRESSION INDEPENDENT_COUNTERDESIGN_COMPLETE
  FORMAL_CLOSURE_CERTIFICATE_VALID IMPLEMENTATION_BLUEPRINT_COMPLETE
  NO_OPEN_PROOF_OBLIGATION)

 :permitted-final-states
 (ABSOLUTE-WITHIN-FORMAL-DOMAIN-PROVED PARETO-FRONTIER-COMPLETE-WITHIN-FORMAL-DOMAIN
  CEILING-PROOF-BLOCKED FORMAL-DOMAIN-INCOMPLETE OPEN-WORLD-ABSOLUTE-NOT-DECIDABLE)
 :forbidden-verdicts
 ("best effort" "state of the art χωρίς theorem" "likely optimal"
  "no better solution found" "all agents agreed" "excellent architecture"))
