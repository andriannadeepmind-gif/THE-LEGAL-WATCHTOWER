;;;; LAWMAX OMEGA — SPEC v1.6 FUTURE-EXTENSIBILITY & PUBLIC COGNITION — MACHINE-READABLE SCHEMAS
;;;; CANDIDATE (NOT FROZEN, NOT QUALIFIED, IMPLEMENTATION BLOCKED). Parent 112379cc.
;;;; Frozen v1.4 baseline 88129099 UNCHANGED. Successor of the SAME CPEI Public Observatory Profile.
;;;; Design-only. Data, not code. We lock legal meanings/invariants/interfaces, NOT tools.
;;;; No new architecture/plane/engine/store/journal/trust-protocol; no new datastore/twin. One source of truth.
;;;; EXISTING canonical types are REFERENCED by identity/version (define-reference), never redefined here.

(spec-version "v1.6-future-extensibility-public-cognition"
 :status :CANDIDATE :not-frozen t :not-qualified t :implementation :BLOCKED
 :successor-of "CHANGE-PROPOSAL-v1.5.md" :same-profile "CPEI Public Observatory Profile v1.4"
 :frozen-baseline "88129099" :parent "112379cc"
 :integrates "all valid v1.5 repairs (D1/D2/D3/C1 + F1-F5 + R1-R8/A-1..D-1/F7)")

;; ============================ 0. NON-NEGOTIABLE GLOBAL INVARIANTS =============================
(define-invariant :V6I-01-lock-meanings-not-tools
  "v1.6 locks legal meanings, invariants and interfaces — NEVER tools. Any tool is a replaceable adapter.")
(define-invariant :V6I-02-no-mandatory-model
  "No model, ONNX runtime, Python runtime, cloud or provider is mandatory anywhere in the public build.
   Their absence NEVER degrades correctness or safety — only optional enrichment.")
(define-closed-enum SafetyMode
  (:SYMBOLIC_ONLY)   ; full safe path with ZERO external proposer/model/cloud — canonical default-safe
  (:ENRICHED)        ; optional proposers/adapters present; still symbolic-judged, no trusted-path model
  (:DEGRADED)        ; some optional adapter unavailable; fail-closed to SYMBOLIC_ONLY semantics
  (:OFFLINE))        ; no network; local-only; canonical operation preserved
(define-invariant :V6I-03-symbolic-only-complete
  "SYMBOLIC_ONLY is a COMPLETE architectural path: acquisition, census, admission, Legal IR, reasoning,
   proof/counterproof, memory, publication all operate with NO proposer/model/cloud. Removing every
   proposer yields SafetyMode :SYMBOLIC_ONLY, never a broken state.")
(define-invariant :V6I-04-adapter-no-canonical-authority
  "Every external tool is a replaceable adapter with NO canonical write authority, NO keys, NO
   self-certification. It only emits typed, anchored candidates through the non-evaluating ingress decoder.")
(define-invariant :V6I-05-memory-owned-by-lawmax
  "Memory belongs to LAWMAX, not to any model. A model receives a scoped projection and returns a
   candidate; canonical memory writes are made ONLY by the authorized write authority.")
(define-invariant :V6I-06-critical-result-carries
  "Every critical result carries source, time, uncertainty and proof/counterproof. Ambiguity or missing
   knowledge yields UNKNOWN / CONFLICTING / QUARANTINED / a clarification question — never a guess.")
(define-invariant :V6I-07-public-independent-of-private
  "The Public Profile NEVER depends on the Private Matter Profile or any embodied device. Private consumes
   signed public releases or versioned proof-carrying interfaces — never public-store internals.")
(define-invariant :V6I-08-self-improvement-gated
  "No self-improvement becomes canonical without test + authorization + journaled adoption + rollback.")
(define-invariant :V6I-09-future-tech-is-adapter
  "New technology is added ONLY as an adapter, capability or profile. It NEVER forces a change to legal
   identity, Legal IR, memory, temporality, proofs or trust boundaries. Guarantee = stable contracts +
   migration + isolation, NOT knowledge of the future (no claim to foresee 2040 tech).")

;; ============================ 1. MODEL-AGNOSTIC SEMANTIC PROPOSER =============================
;; Replaces the 'neural plane' framing: the existing typed protocol `lawmax/neural-candidate/1` (v1.4 §4.3)
;; is now the model-agnostic CandidateInterpretation. ONNX/embeddings/LLM/OCR are OPTIONAL adapters.
(define-closed-enum ProposerKind
  (:SYMBOLIC_RULE)      ; a Common Lisp symbolic proposer (in trusted language, still non-authoritative here)
  (:LOCAL_MODEL)        ; optional local model adapter
  (:EXTERNAL_MODEL)     ; optional external/cloud model adapter
  (:OCR_PERCEPTION)     ; optional OCR/layout adapter
  (:HEURISTIC))         ; deterministic heuristic
(define-protocol SemanticProposer
  :generic-functions (propose-candidates negotiate-capability declare-limitations)   ; CLOS generic fns
  :input  PerceptionEnvelope/1
  :output "(list CandidateInterpretation/1)"
  :constraints ("emits ONLY typed, anchored candidates"
                "holds NO keys; writes NO journal/canonical state; never self-certifies"
                "score is NEVER converted to legal truth"
                "passes EXCLUSIVELY through the non-evaluating ingress decoder (no cl:read/eval/macro/compile)"
                "removable with NO loss of memory or canonical data")
  :absent-behavior "when all proposers are absent, SafetyMode = :SYMBOLIC_ONLY and the public system operates")
(define-adapter-contract ONNXProposerAdapter
  :implements SemanticProposer :kind :EXTERNAL_MODEL
  :mandatory nil :replaceable t :canonical-write-authority nil
  :note "ONNX is an OPTIONAL adapter ONLY; removed from every mandatory architecture/toolchain assumption (v1.6 §3).")
(define-adapter-contract OCRPerceptionAdapter
  :implements SemanticProposer :kind :OCR_PERCEPTION
  :mandatory nil :replaceable t :canonical-write-authority nil
  :note "No specific OCR engine/runtime is a source of truth; same bytes ⇒ same manifestation identity.")
(define-invariant :V6I-10-proposer-never-authority
  "A proposer produces PerceptionEnvelope-derived CandidateInterpretation only. The epistemic wall
   (legal-extraction-verify.lisp) judges symbolically; write-authority.lisp is the ONE write seat. A
   malicious proposer produces ZERO canonical writes (kill V6KW-05).")

;; ============================ 2. UNIVERSAL STABLE CONTRACTS (§6) ==============================
;; 13 universal contracts. EXISTING canonical types are `define-reference` (identity + version + canonical
;; seat; NO redefined fields — one source of truth, V6I-REF). Contracts genuinely introduced by v1.6 are
;; `define-record`. Contracts that reuse a canonical base AND add v1.6 fields are `define-record` carrying an
;; explicit `:extends` pointer to the canonical seat (the base is referenced, never re-originated).
(define-record PerceptionEnvelope/1        ; NEW — raw perception (bytes) boundary, adapter-fed
  (:envelope_id :type id)                  ; = hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY)))
  (:version :type semver) (:media_type :type mime) (:source_bytes_digest :type sha256)
  (:source_spans :type (list span)) (:observation_time :type instant)
  (:acquisition_receipt_ref :type ref) (:provenance :type ref)
  (:adapter_id :type id) (:capability_manifest_ref :type ref)
  (:signature :type sig))
(define-reference CandidateInterpretation/1   ; REFERENCE — the existing lawmax/neural-candidate/1 (v1.4 §4.3)
  :canonical "source/*.lisp neural-candidate/1 protocol (v1.4 §4.3)" :identity "lawmax/neural-candidate/1"
  :version "1" :owner-wp "WP-07"
  :note "model-agnostic proposer output; typed + anchored + non-executable; NOT redefined here.")
(define-reference LegalIR/1                    ; REFERENCE — frozen epistemic node set {Fact,Norm,Claim,Proof,Counterproof,Hypothesis}
  :canonical "legal-ast.lisp + LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md (v1.5 C1 records)" :identity "lawmax/legal-ir/1"
  :version "1" :owner-wp "WP-03"
  :note "the canonical Legal IR node/edge model; REFERENCED by identity, never re-declared as a v1.6 record.")
(define-record MemoryEvent/1                ; PUBLIC BASE (defect 4) — projection over the memory.lisp substrate
  :canonical-substrate "memory.lisp (:orchestrator.memory record-episode/record-goal/verify-episode-chain)"
  (:memory_event_id :type id) (:version :type semver)
  (:memory_type :type PublicMemoryType) (:scope :type PublicMemoryScope)   ; PUBLIC-ONLY type/scope — no client/matter/private
  (:subject_ref :type ref) (:content_ref :type ref) (:provenance :type ref)
  (:valid_time :type instant) (:known_time :type instant)      ; bitemporal (reuse L2)
  (:supersedes :type (or id null)) (:uncertainty :type uncertainty)
  (:write_authority_id :type id) (:signature :type sig))
(define-record CapabilityManifest/1         ; NEW — the adapter replaceability contract (§8)
  (:manifest_id :type id) (:version :type semver)
  (:adapter_id :type id) (:interface_version :type semver)
  (:declared_limitations :type (list text)) (:runtime_build_digest :type sha256) (:provenance :type ref)
  (:conformance_suite_ref :type ref) (:golden_corpus_ref :type ref)
  (:quality_slo :type ref) (:security_profile :type ref)
  (:expiration :type instant) (:fail_closed :type (member :true :false)) (:signature :type sig))
(define-record ToolInvocation/1             ; EXTENDS neural-task/1 — bounded adapter call (adds v1.6 adapter fields)
  :extends "source/*.lisp lawmax/neural-task/1 (v1.4) — referenced, not re-originated"
  (:invocation_id :type id) (:version :type semver)
  (:adapter_id :type id) (:capability_manifest_ref :type ref)
  (:input_projection_ref :type ref)         ; a scoped projection only; never raw canonical store
  (:requested_at :type instant) (:latency_budget :type duration) (:mode :type SafetyMode)
  (:signature :type sig))
(define-record Plan/1                        ; EXTENDS cockpit_intent — planning aggregate (adds goal/steps)
  :extends "cockpit_intent + decisions.lisp (v1.4 §4.12) — referenced, not re-originated"
  (:plan_id :type id) (:version :type semver)
  (:goal_ref :type ref) (:steps :type (list ref)) (:preconditions :type (list ref))
  (:owner :type id) (:created_at :type instant) (:signature :type sig))
(define-reference ActionIntent/1             ; REFERENCE — the existing cockpit_intent (kind=proposal)
  :canonical "cockpit_intent (v1.4 §4.12) kind=proposal; approval-policy.lisp" :identity "lawmax/cockpit-intent/1"
  :version "1" :owner-wp "WP-12"
  :note "signed action intent (action_kind/risk_class/requires_approval are cockpit_intent attributes).")
(define-reference Approval/1                    ; REFERENCE — approval-policy.lisp + release-authority.lisp (L12)
  :canonical "approval-policy.lisp + release-authority.lisp (L12)" :identity "lawmax/approval/1"
  :version "1" :owner-wp "WP-12"
  :note "RBAC/MFA-evidenced approve/reject/revoke with rollback_target; REFERENCED, not redefined.")
(define-record ExecutionReceipt/1            ; NEW — outcome of an approved+executed action
  (:receipt_id :type id) (:version :type semver)
  (:approval_ref :type ref) (:invocation_refs :type (list ref)) (:outcome :type (member :ok :failed :aborted))
  (:evidence :type ref) (:executed_at :type instant) (:signature :type sig))
(define-record SafetyState/1                 ; NEW — the current safe-mode envelope
  (:state_id :type id) (:version :type semver)
  (:mode :type SafetyMode) (:degraded_reasons :type (list text)) (:as_of :type instant)
  (:emergency_stop :type (member :armed :engaged)) (:signature :type sig))
(define-reference TrustBundle/1                 ; REFERENCE — existing trust_bundle (bnd1:) / MLTP LocalTrustState
  :canonical "MLTP LocalTrustState + trust_bundle_ref (bnd1:) — WP-06 IssuedClaim/TrustBundle/VerificationReceipt"
  :identity "lawmax/trust-bundle/1" :version "1" :owner-wp "WP-06"
  :note "pinned roots / registries / checkpoint; REFERENCED by identity, never re-declared.")
(define-reference DeclassificationReceipt/1     ; REFERENCE — private→public declassification gateway
  :canonical "boundary schemas (§1.3/§1.4) DeclassificationReceipt gateway" :identity "lawmax/declassification-receipt/1"
  :version "1" :owner-wp "WP-12"
  :note "subject_digest + from_scope→to_scope + authority + policy; the ONE monotonic private→public gate.")
(define-invariant :V6I-11-contracts-closed-noncircular
  "Every universal contract is type-closed and non-circular; identity = content-address of the immutable
   BODY (excludes id + signatures + detached refs); lifecycle/adoption is the detached LifecycleRecord/1
   overlay (v1.5 R2), never a mutable field in a hash-bearing body.")
(define-invariant :V6I-12-no-vendor-in-core
  "No vendor-specific identifier or format enters canonical Legal IR or memory. Adapter-specific data lives
   only inside CapabilityManifest/PerceptionEnvelope and is normalized before any canonical write.")
(define-invariant :V6I-REF-single-source-of-truth
  "LegalIR/1, TrustBundle/1, CandidateInterpretation/1, ActionIntent/1, Approval/1 and DeclassificationReceipt/1
   are `define-reference` to their existing canonical seats — NOT redefined as simplified v1.6 records. A type
   defined as BOTH a record and a reference, or defined twice, is a duplicate source of truth and is REJECTED
   by the architecture gate (audit V6S13).")

;; ============================ 3. PUBLIC LEGAL LANGUAGE COGNITION LAYER (§4) ====================
;; INSIDE the existing Public Legal Discernment Engine (WP-08 core) — NOT a second reasoning engine. A
;; construction contract: an ordered stage DAG over typed I/O records, reusing existing Lisp seats.
;; legal-casegrammar SPLIT: general Greek mechanisms public; client-fact schemas + matter-solving private.
(define-closed-enum CognitionCapability
  (:UNICODE_NORMALIZATION+SEGMENTATION) (:REVERSIBLE_TOKENIZATION_WITH_SPANS)
  (:MORPHOLOGICAL_LATTICE) (:CONSTRAINT_SYNTAX+PACKED_FOREST)
  (:COREFERENCE+ANAPHORA+DISCOURSE) (:INTER_SENTENCE+DOCUMENT_LINKING)
  (:LEGAL_ENTITIES+CITATIONS+TERMS_OF_ART) (:TEMPORAL+DEONTIC+CONDITIONAL+EXCEPTION+SCOPE_SEMANTICS)
  (:MULTIPLE_INTERPRETIVE_PROFILES) (:CANDIDATE_TO_LEGALIR_PROMOTION)
  (:EXPLICIT_AMBIGUITY+CLARIFICATION) (:CONTROLLED_NLG_WITH_CITATION+PROOF)
  (:MULTILINGUAL_EXTENSION_POINT) (:DECLARED_COVERAGE+UNKNOWN_OUTSIDE)
  (:NO_PERFECT_UNDERSTANDING_CLAIM))
(define-closed-enum CognitionError                 ; error taxonomy — every stage fails to a typed error, never a guess
  (:UNSEGMENTABLE_BYTES) (:UNKNOWN_TOKEN) (:NO_MORPH_ANALYSIS) (:AMBIGUOUS_MORPH)
  (:NO_PARSE) (:AMBIGUOUS_PARSE) (:UNRESOLVED_REFERENCE) (:DISCOURSE_GAP)
  (:UNKNOWN_ENTITY) (:CITATION_UNRESOLVED) (:INTERPRETIVE_DIVERGENCE)
  (:OUTSIDE_DECLARED_COVERAGE) (:CLARIFICATION_REQUIRED) (:PROMOTION_REJECTED))
;; ---- typed cognition I/O records (each hash-bearing, provenance-carrying, symbolic-only) ----
(define-record MorphLattice/1
  (:lattice_id :type id) (:version :type semver) (:token_ref :type ref)
  (:readings :type (list ref)) (:uncertainty :type uncertainty) (:provenance :type ref))
(define-record PackedParseForest/1
  (:forest_id :type id) (:version :type semver) (:input_ref :type ref)
  (:packed_nodes :type (list ref)) (:ambiguity :type uncertainty) (:provenance :type ref))
(define-record CoreferenceRecord/1
  (:coref_id :type id) (:version :type semver) (:mention_ref :type ref)
  (:antecedent_ref :type (or ref null)) (:confidence :type uncertainty) (:provenance :type ref))
(define-record DiscourseState/1
  (:state_id :type id) (:version :type semver) (:segment_refs :type (list ref))
  (:cross_sentence_links :type (list ref)) (:document_links :type (list ref)) (:as_of :type instant))
(define-record LegalSemanticAlternative/1
  (:alt_id :type id) (:version :type semver) (:interpretation_ref :type ref)
  (:profile_ref :type ref) (:score :type uncertainty) (:support :type (list ref)))
(define-record ClarificationState/1                ; explicit clarification state machine
  (:clarify_id :type id) (:version :type semver) (:question_ref :type ref)
  (:status :type (member :OPEN :ANSWERED :ABANDONED)) (:blocking :type (member :true :false)))
(define-record PromotionEvidence/1                 ; symbolic promotion evidence: candidate → Legal IR
  (:evidence_id :type id) (:version :type semver) (:candidate_ref :type ref)
  (:symbolic_checks :type (list ref)) (:outcome :type (member :PROMOTED :REJECTED :UNKNOWN)) (:provenance :type ref))
(define-record CognitionResult/1                   ; the layer's typed output (public hash-bearing root)
  (:result_id :type id) (:version :type semver) (:layer_ref :type ref)
  (:legalir_refs :type (list ref)) (:alternatives :type (list ref)) (:clarifications :type (list ref))
  (:errors :type (list CognitionError)) (:coverage :type (member :INSIDE :OUTSIDE))
  (:safety_mode :type SafetyMode) (:provenance :type ref))
(define-record LanguageCognitionLayer/1
  (:layer_id :type id) (:version :type semver)
  (:capabilities :type (list CognitionCapability))
  (:analyzer_registry_ref :type ref)         ; incremental/hot-swappable analyzers via capability registry
  (:coverage_declaration_ref :type ref)      ; declared coverage; outside ⇒ UNKNOWN
  (:controlling_text_declaration :type ref)  ; multilingual: which text controls
  (:stage_dag_ref :type ref))                ; the ordered construction DAG (cognition-stage-dag)
;; ---- ordered stage DAG (construction contract): each stage has typed in/out and a symbolic-only guarantee ----
(define-construction-order cognition-stage-dag
  (:stage COG-1-SEGMENT        :in PerceptionEnvelope/1 :out MorphLattice/1  :seat "greek-nlp-core.lisp"                 :symbolic-only t)
  (:stage COG-2-TOKENIZE       :in MorphLattice/1       :out MorphLattice/1  :seat "greek-tokenizer-advanced.lisp"      :symbolic-only t)
  (:stage COG-3-MORPH          :in MorphLattice/1       :out MorphLattice/1  :seat "greek-lemmatizer.lisp + legal-casegrammar.lisp[general]" :symbolic-only t)
  (:stage COG-4-PARSE          :in MorphLattice/1       :out PackedParseForest/1 :seat "legal-casegrammar.lisp[general]" :symbolic-only t)
  (:stage COG-5-REFERENCE      :in PackedParseForest/1  :out CoreferenceRecord/1 :seat "greek-nlp-core.lisp (EXTEND)"     :symbolic-only t)
  (:stage COG-6-DISCOURSE      :in CoreferenceRecord/1  :out DiscourseState/1     :seat "greek-nlp-core.lisp (EXTEND)"    :symbolic-only t)
  (:stage COG-7-ENTITY         :in DiscourseState/1     :out LegalSemanticAlternative/1 :seat "greek-legislation-ontology.lisp" :symbolic-only t)
  (:stage COG-8-LEGAL-SEMANTIC :in LegalSemanticAlternative/1 :out LegalSemanticAlternative/1 :seat "legal-deontic.lisp + legal-event-calculus.lisp" :symbolic-only t)
  (:stage COG-9-PROFILES       :in LegalSemanticAlternative/1 :out LegalSemanticAlternative/1 :seat "InterpretiveProfile/1 (v1.5 C1)" :symbolic-only t)
  (:stage COG-10-CLARIFY       :in LegalSemanticAlternative/1 :out ClarificationState/1  :seat "legal-dialectic.lisp + condition/restart" :symbolic-only t)
  (:stage COG-11-PROMOTE       :in ClarificationState/1 :out PromotionEvidence/1  :seat "legal-extraction-verify.lisp + legal-ast.lisp + legal-reasoning-bridge.lisp" :symbolic-only t)
  (:stage COG-12-NLG           :in PromotionEvidence/1  :out CognitionResult/1    :seat "legal-qa.lisp + citation/1" :symbolic-only t))
;; ---- capability → seat map: EVERY CognitionCapability mapped EXACTLY once (existing seat OR declared extension) ----
(define-mapping cognition->existing-lisp-seat
  ((:UNICODE_NORMALIZATION+SEGMENTATION)        "greek-nlp-core.lisp (REUSE)")
  ((:REVERSIBLE_TOKENIZATION_WITH_SPANS)        "greek-tokenizer-advanced.lisp (REUSE)")
  ((:MORPHOLOGICAL_LATTICE)                     "greek-lemmatizer.lisp + legal-casegrammar.lisp[general] (SPLIT->public)")
  ((:CONSTRAINT_SYNTAX+PACKED_FOREST)           "legal-casegrammar.lisp[general] (SPLIT->public)")
  ((:COREFERENCE+ANAPHORA+DISCOURSE)            "greek-nlp-core.lisp (EXTEND)")
  ((:INTER_SENTENCE+DOCUMENT_LINKING)           "greek-nlp-core.lisp discourse (EXTEND)")
  ((:LEGAL_ENTITIES+CITATIONS+TERMS_OF_ART)     "greek-legislation-ontology.lisp (REUSE)")
  ((:TEMPORAL+DEONTIC+CONDITIONAL+EXCEPTION+SCOPE_SEMANTICS) "legal-deontic.lisp + legal-event-calculus.lisp (REUSE)")
  ((:MULTIPLE_INTERPRETIVE_PROFILES)            "InterpretiveProfile/1 (v1.5 C1) (REUSE)")
  ((:CANDIDATE_TO_LEGALIR_PROMOTION)            "legal-extraction-verify.lisp + legal-ast.lisp + legal-reasoning-bridge.lisp (EXTEND)")
  ((:EXPLICIT_AMBIGUITY+CLARIFICATION)          "legal-dialectic.lisp + condition/restart (EXTEND)")
  ((:CONTROLLED_NLG_WITH_CITATION+PROOF)        "legal-qa.lisp + citation/1 (REUSE/EXTEND)")
  ((:MULTILINGUAL_EXTENSION_POINT)              "controlling_text_declaration (DECLARED EXTENSION; interface point, no impl)")
  ((:DECLARED_COVERAGE+UNKNOWN_OUTSIDE)         "coverage_declaration_ref + legal-qa.lisp UNKNOWN path (DECLARED EXTENSION)")
  ((:NO_PERFECT_UNDERSTANDING_CLAIM)            "invariant :V6I-13 (DECLARED; honest-ignorance, no seat)"))
(define-rule casegrammar-split
  (:public "general Greek morphology, case frames and ambiguity detection ⇒ shared/public language layer")
  (:private "client-fact schemas and matter-solving ⇒ private/deferred (DEFER_PRIVATE)")
  (:no-copy "NO second implementation of any general mechanism; the private layer CONSUMES the public one"))
(define-rule common-lisp-cognition-usage
  (:clos "CLOS protocols + generic functions for adapters/analyzers")
  (:conditions "condition/restart system for controlled ambiguity and recovery")
  (:macros "macros/DSLs for grammar, morphology, Legal IR and rules")
  (:compile-time "compile-time schema/invariant generation")
  (:packages "package boundaries + declared forbidden dependencies")
  (:immutable "immutable/versioned internal objects")
  (:hot-swap "incremental/hot-swappable analyzers via capability registry")
  (:no-external-eval "NO cl:read / eval / macroexpand / compile over external bytes")
  (:no-python-in-lisp "NO 'Python-in-Lisp' reimplementation"))
(define-invariant :V6I-13-cognition-one-seat
  "The Language Cognition Layer has ONE seat (inside the Public Legal Discernment Engine, WP-08); it reuses the
   existing Lisp seats and never forks a second implementation. Outside declared coverage ⇒ UNKNOWN; no
   claim of perfect understanding without measurable corpus evidence.")
(define-invariant :V6I-COG-symbolic-only
  "The ENTIRE cognition-stage-dag executes with NO proposer/model: every stage carries :symbolic-only t and
   consumes only symbolic seats. Optional proposers may enrich MorphLattice/PackedParseForest candidates ONLY
   through the non-evaluating ingress decoder; removing them yields SafetyMode :SYMBOLIC_ONLY with the full
   symbolic (structural) analysis intact — never a broken layer (kill V6KW-01).")
(define-invariant :V6I-COG-one-to-one
  "Every CognitionCapability maps EXACTLY once in cognition->existing-lisp-seat (existing seat or DECLARED
   EXTENSION). An unmapped or multiply-mapped capability is REJECTED by the architecture gate (audit V6S14).")

;; ============================ 4. COMPLETE MEMORY ARCHITECTURE (§5) =============================
;; ONE memory seat: the existing Memory Kernel / memory.lisp (:orchestrator.memory). EXTEND it — no second
;; memory system. PUBLIC base (PublicMemoryType/PublicMemoryScope) carries NO client/matter/private type or
;; scope (defect 4); the private extension lives in §5 with :public-dependency nil.
(define-closed-enum PublicMemoryType                ; PUBLIC-only memory types — excludes :PRIVATE_CLIENT_MATTER
  (:WORKING_CONTEXT) (:EPISODIC_INTERACTION) (:SEMANTIC) (:PROCEDURAL) (:PROSPECTIVE_GOALS)
  (:SOURCE_PROVENANCE) (:TEMPORAL) (:ARGUMENT_COUNTERARGUMENT) (:UNCERTAINTY_CONTRADICTION)
  (:USER_PREFERENCE) (:SKILL_CAPABILITY) (:META_MEMORY))
(define-closed-enum PublicMemoryScope (:public) (:user) (:ephemeral))   ; PUBLIC-only — excludes :client :matter
;; full type/scope spaces (declared for the PRIVATE extension + declassification only; NOT used by the public base)
(define-closed-enum MemoryType
  (:WORKING_CONTEXT) (:EPISODIC_INTERACTION) (:SEMANTIC) (:PROCEDURAL) (:PROSPECTIVE_GOALS)
  (:SOURCE_PROVENANCE) (:TEMPORAL) (:ARGUMENT_COUNTERARGUMENT) (:UNCERTAINTY_CONTRADICTION)
  (:USER_PREFERENCE) (:SKILL_CAPABILITY) (:META_MEMORY) (:PRIVATE_CLIENT_MATTER))   ; last = deferred private type
(define-closed-enum MemoryScope (:public) (:user) (:client) (:matter) (:ephemeral))
(define-record MemoryPolicy/1
  (:policy_id :type id) (:version :type semver)
  (:retention :type ref) (:forgetting :type ref) (:consolidation :type ref)
  (:explainable_recall :type (member :true :false)) (:correction_supersession :type ref)
  (:scope_isolation :type (list MemoryScope)))
(define-record MemoryProjection/1            ; the ONLY thing a model receives
  (:projection_id :type id) (:scope :type PublicMemoryScope) (:as_of :type instant)
  (:content_ref :type ref) (:derivable :type (member :true :false)))   ; recomputable; not authoritative
(define-invariant :V6I-14-memory-model-boundary
  "No model owns or directly mutates memory. It receives a scoped MemoryProjection/1 and returns a
   CandidateInterpretation/1; canonical MemoryEvent/1 writes are made ONLY by the authorized write
   authority. Replacing any model MUST preserve byte-verifiable memory continuity (kill V6KW-02).")
(define-invariant :V6I-15-memory-scope-isolation
  "Memory scope isolation is strict: public | user | client | matter | ephemeral. The PUBLIC MemoryEvent/1
   base carries only PublicMemoryType × PublicMemoryScope (no client/matter/private). A private (client/matter)
   datum reaches a public flow ONLY through a valid DeclassificationReceipt/1 (kill V6KW-11).")
(define-invariant :V6I-MEM-public-base-clean
  "The PUBLIC hash-bearing memory contract (MemoryEvent/1) has NO transitive dependency on :PRIVATE_CLIENT_MATTER,
   :client, :matter, PrivateMemoryEvent/1 or any :DEFERRED_PRIVATE record. Any such leakage in the public
   transitive type closure is REJECTED by the architecture gate (audit V6S12).")

;; ============================ 5. FUTURE EXTENSION CONTRACTS (§7) ===============================
;; Interfaces ONLY. These contracts MUST NOT become dependencies of the public build (acyclic).
(define-record PrivateMemoryEvent/1 :status :DEFERRED_PRIVATE :public-dependency nil   ; the private memory extension (defect 4)
  (:private_event_id :type id) (:version :type semver)
  (:base_ref :type ref)                     ; consumes the public MemoryEvent/1 base by ref; never the reverse
  (:memory_type :type MemoryType) (:scope :type MemoryScope)   ; full private-bearing type/scope
  (:matter_ref :type ref) (:privilege_label :type ref) (:declassification_gateway :type ref) (:signature :type sig))
(define-record PrivateMatterProfile/1 :status :DEFERRED_PRIVATE :public-dependency nil
  (:client_matter_identity :type ref) (:conflict_checks :type ref) (:privilege_confidentiality_labels :type ref)
  (:encryption_key_per_matter :type ref) (:evidence_vault :type ref) (:litigation_timeline :type ref)
  (:hypotheses_competing_theories :type ref) (:argument_counterargument :type ref) (:strategy_simulation :type ref)
  (:procedural_deadlines :type ref) (:drafting_negotiation_assistance :type ref) (:audit_trail :type ref)
  (:retention_deletion :type ref) (:declassification_gateway :type ref))
(define-record RealTimeAssistance/1 :status :DEFERRED_PRIVATE :public-dependency nil
  (:streaming_event_contract :type ref) (:synchronized_timestamps :type ref) (:cancellation_interruption :type ref)
  (:latency_budget_policy :type ref) (:offline_edge_mode :type ref) (:reconnect_signed_sync :type ref)
  (:speaker_labelled_audio :type ref) (:ephemeral_transcript :type ref) (:no_recording_mode :type ref)
  (:earpiece_short+fullscreen_explanation :type ref) (:consent_policy_state :type ref) (:human_final_authority :type ref))
(define-record EmbodimentInterfaces/1 :status :DEFERRED_PRIVATE :public-dependency nil
  (:sensor_adapter :type ref) (:embodiment_adapter :type ref) (:actuator_capability :type ref)
  (:hardware_device_identity :type ref) (:remote_attestation :type ref) (:calibration_receipt :type ref)
  (:spatial_temporal_grounding :type ref) (:world_state_causal_observations :type ref)
  (:multi_agent_coordination :type ref) (:physical_safety_envelope :type ref) (:autonomy_levels :type ref)
  (:independent_emergency_stop :type ref) (:sim_hil_gate :type ref) (:authorization_before_high_risk :type ref))
(define-invariant :V6I-16-extension-isolation
  "PrivateMemoryEvent/1, PrivateMatterProfile/1, RealTimeAssistance/1 and EmbodimentInterfaces/1 are extension
   contracts, never public-build dependencies. Public → private/embodiment edges are FORBIDDEN; the boundary is
   ACYCLIC (kill V6KW-09). High-risk legal or physical action requires prior Approval/1; independent emergency
   stop and a sim/HIL gate precede any embodiment action.")

;; ============================ 6. PUBLIC/PRIVATE/EMBODIMENT BOUNDARY (acyclic) ==================
;; The public-build roots below are the ENTRY points; the real check is the TRANSITIVE type closure over these
;; roots (audit V6S12), which must contain NO :DEFERRED_PRIVATE record or private-bearing enum — the manual
;; list is only the seed, not the proof (defect 5).
(define-ref-classification-v6
  (public-build   :hash-bearing (LegalIR/1 MemoryEvent/1 TrustBundle/1 LanguageCognitionLayer/1 CognitionResult/1))
  (private-profile :consumes    (SignedPublicRelease ProofCarryingInterface))   ; never public-store internals
  (embodiment      :adapter-only (SensorAdapter EmbodimentAdapter ActuatorCapability)))
(define-invariant :V6I-17-one-source-of-truth
  "Human tables are GENERATED from the machine-readable registries (SUBSYSTEM-REGISTRY.sexp,
   INTERFACE-AND-SCHEMA-REGISTRY.sexp) — never a second hand-maintained truth. Every file and significant
   symbol maps EXACTLY once: reason -> subsystem -> requirement -> interface -> data owner -> test ->
   future WP -> migration -> rollback. Orphans, dual seats, undocumented deps, multiple write owners,
   public→private deps, adapter-specific canonical types, referenced-but-undefined contracts, duplicated
   normative type definitions, wrong WP assignments and unmapped cognition capabilities are all rejected by
   the architecture gate (audit V6S1-V6S17).")
