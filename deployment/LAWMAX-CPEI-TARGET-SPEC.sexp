;;;; deployment/LAWMAX-CPEI-TARGET-SPEC.sexp
;;;; ============================================================================
;;;; LAWMAX Ω — CONSTITUTIONAL PROOF-CARRYING EPISTEMIC INSTITUTION (target)
;;;; ============================================================================
;;;; Μηχανικά αναγνώσιμο ζεύγος του LAWMAX-CPEI-TARGET-SPEC.md.
;;;; Data-only: *read-eval* NIL, keyword package. SPECIFICATION-ONLY —
;;;; καμία υλοποίηση, κανένα νέο subsystem, τίποτα δεν ξεμπλοκάρεται.

(:lawmax-cpei-target-spec 1
 :authored-at-commit "11bd9a6c"
 :status :specification-only
 :target-name "Constitutional Proof-Carrying Epistemic Institution"

 :axioms-unchanged
 (:zero-error-as-mechanism :honest-ignorance :one-home-per-concept
  :no-llm-in-trusted-path :inalienable-human-sovereignty :no-pseudo-completion)

 ;; ── Τα 12 στρώματα: παρούσα έδρα + status + τι λείπει ──
 ;; status: :present-gated | :partial | :declared-gap
 :layers
 ((:n 1 :layer :immutable-experience-ledger
   :seat ("deployment/self/episodes.sexp (SHA-256 chain)"
          "deployment/state/failure-ledger.jsonl (append+read-back P0)")
   :status :partial
   :missing "ενοποίηση κάτω από universal turn id (M1)· ledger ΟΛΩΝ των πράξεων")
  (:n 2 :layer :bitemporal-epistemic-graph
   :seat ("graph-reasoning" "legal-temporal" "graph-snapshot.sexp")
   :status :partial
   :missing "valid-time × transaction-time (πότε ίσχυε × πότε το έμαθε)")
  (:n 3 :layer :typed-epistemic-memory-objects
   :seat ("LAWMAX-MEMORY-KERNEL-SPEC (13 τύποι)" "typed article-id" "trace events")
   :status :partial
   :missing "κλειστή τυποθεωρία Fact/Proof/Hypothesis/Norm/Claim με μετατροπές-μόνο-με-απόδειξη")
  (:n 4 :layer :proof-disproof-layer
   :seat ("inference WFS" "proof-carrying De Bruijn" "subsumption trees" "defeaters")
   :status :present-gated
   :missing "ρητό counterproof αντικείμενο σε ΚΑΘΕ πράξη")
  (:n 5 :layer :hypothesis-counterfactual-workspace
   :seat ("advisor dreams" "legal-hypo" "counterfactual" "fluid-induction")
   :status :present-gated
   :missing "μόνιμος χώρος υποθέσεων με κύκλο ζωής")
  (:n 6 :layer :adversarial-parliament
   :seat ("legal-dialectic")
   :status :partial
   :missing "N ανεξάρτητοι εσωτερικοί κριτές ανά πράξη")
  (:n 7 :layer :legal-world-simulator
   :seat ("what-if" "event-calculus" "strategy")
   :status :partial
   :missing "ενιαίος simulator πάνω σε όλο το corpus με χρονικές γραμμές")
  (:n 8 :layer :governance-adoption-quarantine
   :seat ("adoption engine can-adopt" "shadow" "policies" "QUARANTINE verdicts")
   :status :present-gated
   :missing nil)
  (:n 9 :layer :self-model-meta-memory
   :seat ("self-model" "mirror" "memory kernel" "gap ledger" "mission measures")
   :status :present-gated
   :missing "meta-memory των δικών του αλλαγών ως ιστορία (δένει με M4)")
  (:n 10 :layer :constitutional-compiler
   :seat ("LAWMAX-ARCHITECTURE-CONSTITUTION.sexp" "--architecture-constitution-gate 12/12")
   :status :partial
   :missing "από ελεγκτής → μεταγλωττιστής: το Σύνταγμα να ΠΑΡΑΓΕΙ δεσμεύσεις")
  (:n 11 :layer :reproducible-substrate
   :seat ("Docker hermetic deps.lock/SBOM" "NixOS LEVEL 0-8 σχεδιασμένο")
   :status :partial
   :missing "L1+ flake/derivations/generations — ΜΠΛΟΚΑΡΙΣΜΕΝΟ μέχρι PASS-CANDIDATE")
  (:n 12 :layer :human-sovereignty-interface
   :seat ("--thoughts/--approve/--reject" "policies μετρημένης ακρίβειας" "signed decisions")
   :status :present-gated
   :missing nil))

 :layers-summary (:present-gated 4 :partial 8 :declared-gap 0
                  :note "κανένα στρώμα χωρίς έδρα — το target είναι ΩΡΙΜΑΝΣΗ, όχι νέο subsystem")

 ;; ── InstitutionalAct: το σχήμα κάθε εξόδου (target) ──
 ;; envelope-now: πώς/αν εκπέμπεται σήμερα στο TRUST ENVELOPE (υπολογισμένο)
 ;; status: :emitted-computed | :partial | :declared-gap
 :institutional-act-schema
 ((:field :act_id              :envelope-now nil :status :declared-gap :note "παράγωγο του M1")
  (:field :turn_id             :envelope-now nil :status :declared-gap :note "M1 — P1 debt 62570e60")
  (:field :jurisdiction        :envelope-now nil :status :declared-gap :note "σιωπηρά ελληνικό δίκαιο — να δηλώνεται ρητά")
  (:field :authority           :envelope-now "capability_used/contract_used/component_used"
   :status :partial :note "λείπει η νομιμοποιητική αλυσίδα από το Σύνταγμα")
  (:field :facts               :envelope-now "γεγονότα υπαγωγής με πηγές (draft-gate)"
   :status :emitted-computed)
  (:field :proof               :envelope-now "δέντρα απόδειξης + De Bruijn + proof_required/available"
   :status :emitted-computed)
  (:field :counterproof        :envelope-now "ενστάσεις αντιδικίας (μόνο subsume/draft)"
   :status :partial)
  (:field :temporal_validity   :envelope-now "legal-temporal σε corpus επίπεδο"
   :status :partial :note "όχι ανά πράξη — δένει με bitemporal στρώμα 2")
  (:field :trust_status        :envelope-now "output_status + mode"
   :status :emitted-computed)
  (:field :weakest_link        :envelope-now "ασθενέστερος κρίκος στο παραδοτέο (Σ10)"
   :status :partial :note "μόνο στο draft, όχι σε κάθε πράξη")
  (:field :memory_events       :envelope-now "failure_id/memory_recorded/gap_id/gap_created (P0 επαληθευμένα)"
   :status :emitted-computed)
  (:field :source_events       :envelope-now "trace_id + provenance δεσμοί"
   :status :emitted-computed)
  (:field :gate_results        :envelope-now "ολομέλεια on-demand"
   :status :partial :note "ανά πράξη: ποιες πύλες κάλυπταν τη διαδρομή της")
  (:field :system_generation   :envelope-now "--version / manifest"
   :status :partial :note "πλήρες με NixOS generations (L4+)")
  (:field :rollback_context    :envelope-now "μόνο σε adoption decisions"
   :status :partial)
  (:field :human_approval_policy :envelope-now "policy_decision + requires-human + signed"
   :status :emitted-computed))

 :act-schema-summary (:emitted-computed 6 :partial 7 :declared-gap 3
                      :rule "το TRUST ENVELOPE είναι το ΕΜΒΡΥΟ του InstitutionalAct — ωριμάζει, δεν αντικαθίσταται· απαγορεύεται δεύτερο παράλληλο envelope (μία έδρα: %ask-envelope)")

 ;; ── Δεσμεύσεις ──
 :commitments
 ((:no-implementation-now t)
  (:keystone-first-when-approved :M1-turn-id
   :why "act_id/turn_id = ο γονέας που ενοποιεί ledger+proof+trace+envelope")
  (:blocking-unchanged (:runner :refactor :code-witness :nixos-l1+ :legal-expansion))
  (:progress-metric "πεδία InstitutionalAct εκπεμπόμενα υπολογισμένα (6/16) + στρώματα present-gated (4/12)"))

 :text-hierarchy
 (:this-defines :target
  :omega-plan :road
  :memory-kernel-spec :memory
  :architecture-constitution :present-enforced))
