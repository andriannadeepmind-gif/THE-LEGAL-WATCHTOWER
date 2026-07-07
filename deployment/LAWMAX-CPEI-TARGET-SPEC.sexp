;;;; deployment/LAWMAX-CPEI-TARGET-SPEC.sexp — v2
;;;; ============================================================================
;;;; LAWMAX Ω — CONSTITUTIONAL PROOF-CARRYING EPISTEMIC INSTITUTION (target)
;;;; ============================================================================
;;;; Ζεύγος του LAWMAX-CPEI-TARGET-SPEC.md v2. Data-only: *read-eval* NIL,
;;;; keyword package. SPECIFICATION-ONLY — καμία υλοποίηση, κανένα νέο store/
;;;; writer/gate/subsystem, κανένας ισχυρισμός learning, τίποτα δεν ξεμπλοκάρεται.
;;;; ΠΑΡΟΝ = απογραφή με evidence · TARGET = βούληση, :requires-ok ανά φάση.

(:lawmax-cpei-target-spec 2
 :authored-at-commit "47bae07d"
 :status :specification-only
 :target-name "Constitutional Proof-Carrying Epistemic Institution"
 :definition "εκτελέσιμο ψηφιακό νομικό Ίδρυμα που παράγει κάθε έξοδο ως θεσμική πράξη γνώσης — με απόδειξη, αντίλογο, χρονική ισχύ, μνήμη, provenance, governance και rollback"
 :not-a (:memory-system :agent)

 :axioms-unchanged
 (:zero-error-as-mechanism :honest-ignorance :one-home-per-concept
  :no-llm-in-trusted-path :inalienable-human-sovereignty :no-pseudo-completion)

 :the-13-primitives
 (:self :law :authority :fact :proof :hypothesis :argument :matter
  :output-trust :evolution :institution :memory :substrate)
 :primitives-rule "κανένα στρώμα δεν εισάγει νέο primitive· κανένα δεν είναι top-level subsystem εκτός Συντάγματος"

 ;; ══ ULTIMATE TARGET — EXECUTABLE EPISTEMIC INSTITUTION: τα 12 στρώματα ══
 ;; coverage: :present-gated | :partial | :missing
 :ultimate-target-layers
 ((:n 1 :layer :immutable-experience-ledger :primitives (:memory)
   :existing-seat ("deployment/self/episodes.sexp (SHA-256 chain)"
                   "deployment/state/failure-ledger.jsonl (append+read-back P0)")
   :coverage :partial
   :evidence ("source/memory.lisp:96 chained-append" "understanding-learning.lisp:188 P0")
   :future-phase :Φ1-M1-turn-id
   :gate-required "--memory-gate (10/10) + μελλοντικός «κάθε πράξη στο ledger»"
   :risk-if-absent "εμπειρία χωρίς ενιαία ραχοκοκαλιά — πράξεις μη ανασυστάσιμες")
  (:n 2 :layer :bitemporal-epistemic-graph :primitives (:law :fact)
   :existing-seat ("graph-reasoning" "legal-temporal" "graph-snapshot.sexp")
   :coverage :partial
   :evidence ("graph-import.lisp:186,223" "legal-temporal έδρα (ontology map)")
   :future-phase :Ω2-bitemporal
   :gate-required "επέκταση --inference-gate: bitemporal serialization roundtrip"
   :risk-if-absent "«τι ίσχυε όταν κρίθηκε» ≠ «τι ήξερε όταν έκρινε» — άδικος αναδρομικός έλεγχος")
  (:n 3 :layer :typed-epistemic-memory-objects :primitives (:fact :proof :hypothesis)
   :existing-seat ("MEMORY-KERNEL-SPEC :memory-types (13)" "typed article-id" "trace events")
   :coverage :partial
   :evidence ("component-gate ⑥⑦⑧ typed ids" "memory kernel taxonomy")
   :future-phase :Ω3-closed-type-theory
   :gate-required "νέος: καμία σιωπηλή μετατροπή τύπου (πρότυπο component-gate ⑧)"
   :risk-if-absent "υπόθεση μεταμφιέζεται σε γεγονός — μόλυνση έμπιστου μονοπατιού")
  (:n 4 :layer :proof-disproof-layer :primitives (:proof)
   :existing-seat ("inference WFS" "proof-carrying De Bruijn" "subsumption trees" "defeaters")
   :coverage :present-gated
   :evidence ("--inference-gate 63/63" "--subsumption-gate 29/29" "--iq-gate 4/4")
   :future-phase :Ω4-counterproof-per-act
   :gate-required "υπάρχοντα + «πράξη χωρίς counterproof slot ⇒ κόκκινο»"
   :risk-if-absent "μονομερής απόδειξη — θεσμός χωρίς αντίλογο δεν είναι δικαιικός")
  (:n 5 :layer :hypothesis-counterfactual-workspace :primitives (:hypothesis)
   :existing-seat ("advisor dreams" "legal-hypo" "counterfactual" "fluid-induction")
   :coverage :present-gated
   :evidence ("--advisor-gate" "draft-gate Ε14: εικασία δεν μολύνει υπαγωγή")
   :future-phase :Ω5-hypothesis-lifecycle
   :gate-required "υπάρχοντα + κύκλος ζωής υπόθεσης"
   :risk-if-absent "υποθέσεις χάνονται ή λιμνάζουν αθάνατες")
  (:n 6 :layer :adversarial-parliament :primitives (:argument)
   :existing-seat ("legal-dialectic")
   :coverage :partial
   :evidence ("subsumption-gate: ένσταση κερδίζει/θέση πίπτει")
   :future-phase :Ω6-multi-judge
   :gate-required "νέος: κάθε legal-critical πράξη από ≥N ανεξάρτητους κριτές"
   :risk-if-absent "ομοφωνία-εκ-κατασκευής — τυφλά σημεία ενός μονοπατιού")
  (:n 7 :layer :legal-world-simulator :primitives (:hypothesis :matter)
   :existing-seat ("what-if" "event-calculus" "strategy")
   :coverage :partial
   :evidence ("--event-gate 8/8" "self-evolution-gate ①-④ what-if")
   :future-phase :Ω7-corpus-wide-simulation
   :gate-required "επέκταση event-gate σε corpus-wide σενάρια"
   :risk-if-absent "συμβουλή χωρίς προσομοίωση συνεπειών — στρατηγική στα τυφλά")
  (:n 8 :layer :governance-adoption-quarantine :primitives (:evolution :institution)
   :existing-seat ("adoption engine can-adopt" "shadow" "policies" "QUARANTINE verdicts")
   :coverage :present-gated
   :evidence ("--self-evolution-gate 23/23" "--policy-gate 12/12" "understanding-gate ⑤⑧")
   :future-phase nil
   :gate-required "υπάρχοντα"
   :risk-if-absent "ανεξέλεγκτη αυτο-τροποποίηση (γι' αυτό υπάρχει ήδη)")
  (:n 9 :layer :self-model-meta-memory :primitives (:self :memory)
   :existing-seat ("self-model" "mirror" "memory kernel" "gap ledger" "mission measures")
   :coverage :present-gated
   :coverage-note "self-model ✅ · meta-memory :partial"
   :evidence ("--mirror-gate 9/9" "gap-ledger-frame" "signed adoption decisions")
   :future-phase :Φ4-M4-consolidation
   :gate-required "mirror-gate + μελλοντικός έλεγχος meta-ιστορίας"
   :risk-if-absent "δεν θυμάται ΠΩΣ έγινε αυτό που είναι — τυφλή εξέλιξη")
  (:n 10 :layer :constitutional-compiler :primitives (:institution :substrate)
   :existing-seat ("LAWMAX-ARCHITECTURE-CONSTITUTION.sexp" "--architecture-constitution-gate 12/12")
   :coverage :partial
   :evidence ("architecture-gate ①-⑫ read-only ratchet — κοκκίνισε στη δική του εντολή")
   :future-phase :Ω10-compiler
   :gate-required "roundtrip: ό,τι παράγεται ταυτίζεται με ό,τι επιβάλλεται"
   :risk-if-absent "διπλή αλήθεια — Σύνταγμα και πραγματικότητα αποκλίνουν σιωπηλά")
  (:n 11 :layer :reproducible-substrate :primitives (:substrate)
   :existing-seat ("Docker hermetic deps.lock/SBOM/cosign" "NixOS L0 ζωντανό· L1-8 σχεδιασμένα")
   :coverage :partial
   :evidence ("Dockerfile multi-stage" "LAWMAX-NIXOS-COGNITIVE-SUBSTRATE.md LEVEL ladder")
   :future-phase :L1-plus-blocked-until-pass-candidate
   :gate-required "nix flake check = πύλες ως build invariant (N4)"
   :risk-if-absent "«έμαθε» που δεν ξαναχτίζεται = ανέκδοτο, όχι γνώση")
  (:n 12 :layer :human-sovereignty-interface :primitives (:institution :authority)
   :existing-seat ("--thoughts/--approve/--reject" "policies μετρημένης ακρίβειας"
                   "signed decisions" "revocation")
   :coverage :present-gated
   :evidence ("--policy-gate 12/12: ανάκληση, force-με-αιτιολογία, όχι καθολικό override")
   :future-phase nil
   :gate-required "υπάρχοντα — κάθε νέο στρώμα ΥΠΟΧΡΕΟΥΤΑΙ να περνά από εδώ"
   :risk-if-absent "ακυρώνει ΟΛΟ το οικοδόμημα — αναπαλλοτρίωτο"))

 :layers-summary (:present-gated 4 :partial 8 :missing 0
                  :rule "target = ωρίμανση υπαρχουσών εδρών, ΟΧΙ νέα top-level subsystems")

 ;; ══ InstitutionalAct — schema concept (TARGET) ══
 ;; status: :emitted-computed | :partial | :declared-gap
 :institutional-act-schema
 ((:field :act_id :envelope-now nil :status :declared-gap :note "παράγωγο M1")
  (:field :turn_id :envelope-now nil :status :declared-gap :note "M1 — P1 debt 62570e60")
  (:field :jurisdiction :envelope-now "σιωπηρά ελληνικό δίκαιο" :status :declared-gap)
  (:field :mode :envelope-now "mode: legal-trusted/legal-diagnostic/self-meta/general/conversation-reference"
   :status :emitted-computed)
  (:field :authority :envelope-now "capability_used/contract_used/component_used"
   :status :partial :note "λείπει νομιμοποιητική αλυσίδα από Σύνταγμα")
  (:field :claim :envelope-now "σώμα απάντησης + θέσεις υπαγωγής"
   :status :partial :note "όχι δομημένο Claim αντικείμενο ανά πράξη")
  (:field :facts :envelope-now "γεγονότα με πηγές (draft-gate)" :status :emitted-computed)
  (:field :proof :envelope-now "δέντρα απόδειξης + De Bruijn + proof_required/available"
   :status :emitted-computed)
  (:field :counterproof :envelope-now "ενστάσεις αντιδικίας (μόνο subsume/draft)" :status :partial)
  (:field :temporal_validity :envelope-now "legal-temporal corpus επίπεδο"
   :status :partial :note "δένει με L2")
  (:field :trust_status :envelope-now "output_status + trusted_output_allowed"
   :status :emitted-computed)
  (:field :weakest_link :envelope-now "Σ10 μόνο στο draft" :status :partial)
  (:field :memory_events :envelope-now "failure_id/memory_recorded/gap_id/gap_created (P0)"
   :status :emitted-computed)
  (:field :source_events :envelope-now "trace_id + provenance δεσμοί" :status :emitted-computed)
  (:field :gate_results :envelope-now "ολομέλεια on-demand" :status :partial
   :note "target: ποιες πύλες κάλυπταν τη διαδρομή της πράξης")
  (:field :system_generation :envelope-now "--version/manifest" :status :partial
   :note "πλήρες με NixOS generations L4+")
  (:field :rollback_context :envelope-now "μόνο adoption decisions" :status :partial)
  (:field :human_approval_policy :envelope-now "policy_decision + requires-human + signed"
   :status :emitted-computed))

 :act-schema-summary
 (:emitted-computed 7 :partial 8 :declared-gap 3
  :rule "TRUST ENVELOPE = έμβρυο του InstitutionalAct — ωριμάζει, δεν αντικαθίσταται· απαγορεύεται δεύτερο παράλληλο envelope (μία έδρα: %ask-envelope)"
  :keystone :M1-turn-id)

 ;; ══ Constitutional Compiler — TARGET ══
 :constitutional-compiler-target
 (:present "δηλωτικό κείμενο + read-only gate που ΕΠΙΒΑΛΛΕΙ (ratchet)"
  :target "το Σύνταγμα ΜΕΤΑΓΛΩΤΤΙΖΕΤΑΙ — από αυτό παράγονται:"
  :compiles-to (:contracts :gates :tests :memory-policies :trust-invariants
                :approval-policies :rollback-constraints :runtime-constraints)
  :correctness :roundtrip
  :roundtrip-rule "ό,τι παράγει ο compiler ταυτίζεται με ό,τι επιβάλλει η πύλη· απόκλιση = κόκκινο build"
  :until-then "χειρόγραφα gates + read-only ratchet παραμένουν η αλήθεια")

 ;; ══ ΚΡΙΣΙΜΗ ΑΡΧΗ ══
 :critical-principle
 (:name :memory-types-are-not-stores
  :statement "τα (έως 50) είδη μνήμης ΔΕΝ γίνονται 50 stores· γίνονται cognitive memory CAPABILITIES πάνω σε ΕΝΙΑΙΟ epistemic substrate"
  :substrate (:events :epistemic-graph :typed-objects :projections :governance)
  :consequences
  ((:new-memory-kind "νέα ΙΚΑΝΟΤΗΤΑ με πύλη στο μητρώο — ΟΧΙ νέο store χωρίς ρητή εγγραφή :canonical-stores με έγκριση")
   (:projections "ΠΑΡΑΓΩΓΑ των events — ξαναχτίζονται από ledger, ποτέ source of truth, ποτέ δικός τους writer αλήθειας")
   (:mechanical-guard "architecture-gate ⑨: ένας ρόλος ανά store, κανένα αδήλωτο store — ήδη ενεργός")))

 ;; ══ APPENDIX — FULL AGENTIC MEMORY COVERAGE MAP ══
 ;; category: :event | :object | :projection | :policy | :graph-relation
 ;; coverage: :existing | :partial | :missing
 :full-agentic-memory-coverage-map
 ((:type :episodic-interactions :category :event :coverage :existing
   :current-store "deployment/self/episodes.sexp"
   :future-source-of-truth "unified event ledger υπό turn_id (Φ1)"
   :provenance :sha256-chain :gate "--memory-gate" :phase :Φ0-done
   :risk-if-absent "καμία εμπειρία")
  (:type :dialogue-failures :category :event :coverage :existing
   :current-store "deployment/state/failure-ledger.jsonl"
   :future-source-of-truth "ίδιο, υπό turn_id"
   :provenance :append-plus-readback :gate "--understanding-gate" :phase :Φ0-done
   :risk-if-absent "ψευδής μνήμη — ο trust bug που έπιασε το blind test")
  (:type :adoption-decisions :category :event :coverage :existing
   :current-store "signed decision files"
   :future-source-of-truth "ίδιο, υπό turn_id"
   :provenance :sha256-signature :gate "--self-evolution-gate" :phase :Φ0-done
   :risk-if-absent "ανιστόρητη εξέλιξη")
  (:type :execution-trace :category :event :coverage :partial
   :current-store "*events* (RAM)"
   :future-source-of-truth "persisted spans ανά πράξη"
   :provenance :provenance-links :gate "--provenance-gate" :phase :Φ1
   :risk-if-absent "πράξη χωρίς ίχνος")
  (:type :biographical-genesis :category :object :coverage :existing
   :current-store "deployment/self/history.sexp"
   :future-source-of-truth "ίδιο"
   :provenance :bootstrap-tracked :gate "architecture-gate ⑨" :phase nil
   :risk-if-absent "απώλεια ταυτότητας")
  (:type :component-identity :category :object :coverage :existing
   :current-store "deployment/self/component-manifest.sexp"
   :future-source-of-truth "ίδιο + δήλωση ρόλου στο Σύνταγμα (δηλωμένο χρέος)"
   :provenance :sha256-per-file :gate "--component-gate" :phase :declared-debt
   :risk-if-absent "αταυτοποίητη ύλη")
  (:type :proposals :category :object :coverage :existing
   :current-store "deployment/self/proposals.sexp"
   :future-source-of-truth "ίδιο"
   :provenance :shadow-results :gate "--extension-gate/--self-evolution-gate" :phase nil
   :risk-if-absent "ανεξέλεγκτη γνώση")
  (:type :candidate-packs :category :object :coverage :existing
   :current-store "deployment/self/candidates/"
   :future-source-of-truth "ίδιο"
   :provenance :shadow-plus-revert :gate "--extension-gate" :phase nil
   :risk-if-absent "μόλυνση σταθερού εαυτού")
  (:type :hypothesis-workspace-state :category :object :coverage :partial
   :current-store "εκκρεμή dreams σε proposals"
   :future-source-of-truth "typed Hypothesis objects (Ω3/Ω5)"
   :provenance :judge-verdicts :gate "--advisor-gate" :phase :Ω5
   :risk-if-absent "αθάνατες ή χαμένες υποθέσεις")
  (:type :semantic-learned-concepts :category :object :coverage :missing
   :current-store nil
   :note "knowledge packs = ΓΝΩΣΗ/bootstrap, ΟΧΙ μνήμη — δεν συγχέονται"
   :future-source-of-truth "consolidation από events (Φ4) ως ΠΡΟΤΑΣΕΙΣ προς έγκριση"
   :provenance :proposal-plus-human-approval :gate "νέος (Φ4)" :phase :Φ4
   :risk-if-absent "θυμάται συμβάντα, όχι μοτίβα")
  (:type :procedural-learned-skills :category :object :coverage :partial
   :current-store "capabilities registry (δηλωμένες, όχι μαθημένες)"
   :future-source-of-truth "adopted rules μέσω governance"
   :provenance :shadow-plus-signature :gate "--understanding-gate" :phase :Φ4+
   :risk-if-absent "δεξιότητα μόνο χειροποίητη")
  (:type :prospective-intentions-agenda :category :object :coverage :existing
   :current-store "agenda/intentions (memory subsystem)"
   :future-source-of-truth "ίδιο, υπό turn_id"
   :provenance :episode-link :gate "--memory-gate" :phase nil
   :risk-if-absent "ξεχνά τι σκόπευε")
  (:type :working-last-answer :category :projection :coverage :existing
   :current-store "*ask-memory* (RAM, ανά process)"
   :future-source-of-truth "projection του event ledger (Φ2)"
   :provenance :ephemeral :gate "--dialogue-gate Β" :phase :Φ2
   :risk-if-absent "κανένα follow-up")
  (:type :session-continuity :category :projection :coverage :missing
   :current-store nil
   :future-source-of-truth "session projection, rebuild από events (Φ2)"
   :provenance :rebuild-from-events :gate "νέος (Φ2)" :phase :Φ2
   :risk-if-absent "κάθε run «χωρίς χθες»")
  (:type :recall-index :category :projection :coverage :missing
   :current-store nil :note "recall = γραμμική σάρωση"
   :future-source-of-truth "index ΠΑΡΑΓΩΓΟ των episodes (Φ3)"
   :provenance :rebuild-verified :gate "νέος (Φ3)" :phase :Φ3
   :risk-if-absent "O(n) ανάκληση — δεν κλιμακώνει")
  (:type :reflection-aggregate :category :projection :coverage :existing
   :current-store "deployment/state/lessons.jsonl"
   :future-source-of-truth "μακροπρόθεσμα παράγωγο του ledger"
   :provenance :single-writer-%lesson :gate "--understanding-gate ⑬" :phase nil
   :risk-if-absent "χωρίς αναστοχασμό")
  (:type :progress-cursors :category :projection :coverage :existing
   :current-store "deployment/state/<key>-last-seen.txt"
   :future-source-of-truth "ίδιο + δήλωση ρόλου (δηλωμένο χρέος)"
   :provenance :idempotent-overwrite :gate "architecture-gate ⑨" :phase :declared-debt
   :risk-if-absent "ο δαίμονας ξεχνά πού έμεινε")
  (:type :meta-memory-how-i-changed :category :projection :coverage :partial
   :current-store "mirror + signed decisions"
   :future-source-of-truth "ιστορία αλλαγών ως προβολή decisions (Φ4/L9)"
   :provenance :signed-decisions :gate "--mirror-gate" :phase :Φ4
   :risk-if-absent "τυφλή εξέλιξη")
  (:type :approval-policies :category :policy :coverage :existing
   :current-store "deployment/self/policies.sexp"
   :future-source-of-truth "compiled από Σύνταγμα (Ω10)"
   :provenance :signed-plus-accuracy-measured :gate "--policy-gate" :phase :Ω10
   :risk-if-absent "ανεξέλεγκτη αυτο-έγκριση")
  (:type :review-queue :category :policy :coverage :existing
   :current-store "review-queue.sexp"
   :future-source-of-truth "ίδιο + δήλωση ρόλου (δηλωμένο χρέος)"
   :provenance nil :gate "architecture-gate ⑨" :phase :declared-debt
   :risk-if-absent "εκκρεμότητες χάνονται")
  (:type :memory-write-recall-policies :category :policy :coverage :partial
   :current-store "MEMORY-KERNEL-SPEC (κείμενο)"
   :future-source-of-truth "compiled από Σύνταγμα (Ω10)"
   :provenance :roundtrip-check :gate "--architecture-constitution-gate" :phase :Ω10
   :risk-if-absent "πολιτική = αφήγηση")
  (:type :source-memory-where-from :category :graph-relation :coverage :partial
   :current-store "provenance links + knowledge pack hashes"
   :future-source-of-truth "epistemic graph edges (Ω2)"
   :provenance :hash-bound :gate "--provenance-gate" :phase :Ω2
   :risk-if-absent "γνώση χωρίς καταγωγή")
  (:type :temporal-validity-bitemporal :category :graph-relation :coverage :partial
   :current-store "legal-temporal (corpus)"
   :future-source-of-truth "bitemporal graph (Ω2)"
   :provenance :dual-timestamps :gate "--inference-gate extension" :phase :Ω2
   :risk-if-absent "άδικος αναδρομικός έλεγχος")
  (:type :concept-grounding-relations :category :graph-relation :coverage :existing
   :current-store "concept-grounding packs + graph-snapshot"
   :future-source-of-truth "epistemic graph (Ω2)"
   :provenance :article-binding :gate "--extension-gate" :phase nil
   :risk-if-absent "αγείωτοι ορισμοί")
  (:type :cross-act-relations :category :graph-relation :coverage :missing
   :current-store nil
   :future-source-of-truth "act-graph υπό act_id (μετά Φ1)"
   :provenance :proof-links :gate "νέος" :phase :after-Φ1
   :risk-if-absent "η νομολογία του εαυτού του χαμένη"))

 :coverage-map-summary
 (:types 25 :categories 5 :new-stores 0
  :rule "τα :missing/:partial είναι capabilities-to-be πάνω στο υπόστρωμα — ΟΧΙ αρχεία")

 ;; ══ Απαγορεύσεις & συμμόρφωση ══
 :does-not
 (:runtime-code :behavior-change :runner :new-store :new-writer :new-gate
  :refactor :code-witness :nixos :legal-knowledge-expansion :learning-claim)
 :learning-status "ΜΗ αποδεδειγμένη — κανένας υιοθετημένος κανόνας από ζωντανή αποτυχία"

 :acceptance-criteria-selfcheck
 ((:1 :current-vs-target "ΠΑΡΟΝ/TARGET ρητά διαχωρισμένα σε κάθε τμήμα")
  (:2 :memory-vs-knowledge "knowledge packs ρητά ΕΚΤΟΣ μνήμης (semantic entry + kernel §1)")
  (:3 :types-not-stores ":critical-principle δεσμευτικό + coverage map με 0 νέα stores")
  (:4 :bound-to-13-primitives "κάθε στρώμα φέρει :primitives ⊆ των 13 — κανένα νέο")
  (:5 :no-new-toplevel-subsystem "όλα = ωρίμανση υπαρχουσών εδρών υπό architecture-gate"))

 :one-seat-binding
 (:memory-inventory-seat "LAWMAX-MEMORY-KERNEL-SPEC.{md,sexp}"
  :rule "αυτό το κείμενο ΔΕΝ επαναλαμβάνει την απογραφή μνήμης και ΔΕΝ ιδρύει δεύτερη αρχιτεκτονική μνήμης — παραπέμπει και χτίζει το target ΠΑΝΩ της"
  :five-levels
  ((:level 1 :name :current-inventory       :seat "MEMORY-KERNEL-SPEC §1-2 + Σύνταγμα :canonical-stores")
   (:level 2 :name :memory-kernel           :seat "MEMORY-KERNEL-SPEC §3-8")
   (:level 3 :name :ultimate-target-layers  :seat "CPEI-TARGET-SPEC :ultimate-target-layers")
   (:level 4 :name :full-agentic-memory-coverage-map :seat "CPEI-TARGET-SPEC :full-agentic-memory-coverage-map")
   (:level 5 :name :cpei-institutional-act  :seat "CPEI-TARGET-SPEC :institutional-act-schema + :constitutional-compiler-target")))

 :text-hierarchy
 (:this-defines :target :omega-plan :road :memory-kernel-spec :memory
  :architecture-constitution :present-enforced))
