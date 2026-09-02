;;;; LAWMAX OMEGA — SPEC v1.5 NARROW-DELTA — MACHINE-READABLE SCHEMAS (CANDIDATE, NOT FROZEN)
;;;; Semantic type-closure micro-pass. Parent 2be68e16 · frozen v1.4 baseline 88129099 (unchanged).
;;;; Design-only. Data, not code. Scope: close type defects inside the existing D1/D2/D3/C1 candidate.
;;;; No new architecture/plane/engine/store/trust-protocol; no new datastore/journal/twin.

(spec-version "v1.5-narrow-delta-candidate-type-closed"
 :status :CANDIDATE :not-frozen t :not-qualified t :implementation :BLOCKED
 :successor-of "CHANGE-PROPOSAL-v1.4.md" :frozen-baseline "88129099" :micro-pass "semantic-type-closure")

;; ============================ D1 — INDEPENDENT SEMANTIC ADMISSION ============================
;; Seat: LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md (adoption boundary). No universal N-version.

(define-closed-enum SemanticAdmissionAssuranceProfile
  (:SA-0 :label "STRUCTURAL"      :obligation :schema+anchors-only)
  (:SA-1 :label "CHECKABLE"       :obligation :derivation+independent-check)
  (:SA-2 :label "STATE_MUTATING"  :obligation :independent-derivation+independent-check+divergence-gate+adoption))

;; D1.4 — COMPLETE state-mutating event classification. Every kind that mutates the canonical
;; in-force / authority state is SA-2. SA-1 = source-checkable non-mutating. SA-0 = structural.
(define-closed-enum StateEventKind
  ;; SA-0 (structural, anchors-only, non-mutating)
  (:ANCHOR :sa :SA-0) (:CITATION_ANCHOR :sa :SA-0) (:OBSERVATION :sa :SA-0)
  ;; SA-1 (checkable, source-verifiable, non-mutating)
  (:CLASSIFICATION :sa :SA-1) (:CROSS_REFERENCE :sa :SA-1)
  (:LATER_TREATMENT_EXTRACTION :sa :SA-1)   ; D1.5 — verifiable from an explicit citation in the citing text
  ;; SA-2 (state-mutating — mutate the canonical in-force / authority / effectivity state)
  (:ENACTMENT :sa :SA-2) (:AMENDMENT :sa :SA-2) (:COMMENCEMENT :sa :SA-2) (:REPEAL :sa :SA-2)
  (:SUSPENSION :sa :SA-2) (:REVIVAL :sa :SA-2) (:ANNULMENT :sa :SA-2) (:CORRECTION :sa :SA-2)
  (:DELEGATED_AUTHORITY_CHANGE :sa :SA-2) (:REGIME_EFFECTIVITY_TRANSITION :sa :SA-2)
  (:CONSTITUTIONAL_REVIEW_STATE_CHANGE :sa :SA-2) (:JUDICIAL_REVIEW_STATE_CHANGE :sa :SA-2)
  (:LINE_OF_AUTHORITY_MUTATION :sa :SA-2))  ; D1.5 — adopted mutation of the authority graph (≠ extraction)

(define-record SemanticAdmissionEvidence/1
  (:candidate_id :type id) (:assurance_profile :type SemanticAdmissionAssuranceProfile)
  (:source_manifestation_id :type usc-id) (:source_anchors :type (list anchor))
  (:derivation_family_id :type id) (:derivation_artifact_digest :type sha256)
  (:transformation_proof_ref :type ref) (:independent_check_ref :type ref)
  (:independent_derivation_ref :type ref) (:divergence_state :type DivergenceState)
  (:derivation_independence_evidence_ref :type ref) (:residual_independence_assumption :type text)
  (:adoption_act_ref :type ref)
  (:policy_ref :type ref) (:schema_id :type id) (:version :type semver))

;; D1.1 — per-profile cardinality of EVERY field: :R required · :F forbidden · :C conditional.
;; Machine-checkable: exactly one code per (field × {SA-0,SA-1,SA-2}); audit V5S-D1a parses this.
(define-cardinality-matrix SemanticAdmissionEvidence/1
  ;; field                                   SA-0  SA-1  SA-2
  (candidate_id                              :R    :R    :R)
  (assurance_profile                         :R    :R    :R)
  (source_manifestation_id                   :R    :R    :R)
  (source_anchors                            :R    :R    :R)
  (policy_ref                                :R    :R    :R)
  (schema_id                                 :R    :R    :R)
  (version                                   :R    :R    :R)
  (derivation_family_id                      :F    :R    :R)
  (derivation_artifact_digest                :F    :R    :R)
  (transformation_proof_ref                  :F    :R    :R)   ; D1.2 — FORBIDDEN for SA-0 (no transformation exists)
  (independent_check_ref                     :F    :R    :R)   ; D1.3 — required for SA-1 and SA-2
  (independent_derivation_ref                :F    :F    :R)   ; D1.3 — required for SA-2 only
  (divergence_state                          :F    :R    :R)   ; SA-0 has no derivation ⇒ no divergence
  (derivation_independence_evidence_ref      :F    :F    :C)   ; D1.6 — SA-2: this XOR residual_independence_assumption
  (residual_independence_assumption          :F    :F    :C)   ; D1.6 — SA-2: required iff independence not evidence-proven
  (adoption_act_ref                          :F    :F    :R))  ; SA-2 only

;; D1.3 — NORMATIVE RATIONALE (single): SA-2 requires BOTH independent_check_ref AND
;; independent_derivation_ref because they cover DISJOINT failure modes — independent_check_ref
;; proves the produced event is source-CHECKABLE by a distinct-mechanism checker (catches a
;; self-consistent but source-inconsistent derivation), while independent_derivation_ref proves the
;; event was independently RE-DERIVED from source by a distinct family (catches shared-spec /
;; shared-artifact errors a mere re-check cannot). Neither subsumes the other; both are required.
(define-invariant :V5I-D1-both
  "SA-2 admission requires independent_check_ref AND independent_derivation_ref (disjoint failure
   modes: check vs re-derive). Missing either ⇒ semantic-admission-obligation-unmet ⇒ QUARANTINED.")

;; D1.6 — real derivation independence. Distinct derivation_family_id ALONE is INSUFFICIENT.
(define-record DerivationIndependenceEvidence/1
  (:derivation_a_ref :type ref) (:derivation_b_ref :type ref)
  (:distinct_specification_source :type ref)   ; different spec/grammar/rules, not a shared spec
  (:distinct_provenance_toolchain :type ref)   ; different toolchain/provenance
  (:distinct_failure_domain :type ref)         ; different runtime/library/host failure domain
  (:digest :type sha256) (:signature :type sig))
(define-invariant :V5I-D1-indep
  "Independence for SA-2 holds only with DerivationIndependenceEvidence/1 binding distinct
   specification source AND provenance/toolchain AND failure domain. Distinct family_id or distinct
   artifact_digest alone ⇒ INDEPENDENCE_INSUFFICIENT. If independence is assumed but not evidenced,
   residual_independence_assumption MUST record the assumption explicitly (never silent).")

(define-closed-enum DivergenceState
  (:AGREED) (:DETERMINISTIC_DIVERGENCE) (:INTERPRETIVE_DISAGREEMENT)
  (:INDEPENDENCE_INSUFFICIENT) (:UNKNOWN))

(define-invariant :V5I-01
  "SA-2 MUST NOT transition ADOPTED -> CANONICAL unless its SemanticAdmissionEvidence obligation is
   satisfied per the cardinality matrix (independent_check_ref AND independent_derivation_ref AND
   divergence_state=:AGREED AND independence-evidence-or-recorded-assumption AND adoption_act_ref). A
   schema-valid but wrong SA-2 event is QUARANTINED even if downstream compilers agree.")
(define-invariant :V5I-02
  "INTERPRETIVE_DISAGREEMENT (D1.5: distinct from DETERMINISTIC_DIVERGENCE) is never a compiler error
   and never resolved by majority vote; it stays a typed hypothesis/argument/UNKNOWN/CONFLICTING in
   the existing L5/L6 seat (C1). DETERMINISTIC_DIVERGENCE on a source-verifiable fact ⇒ QUARANTINED.")

;; ============================ D2 — CENSUS ENUMERABILITY + NEGATIVE EVIDENCE ==================
;; Seats: LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md, LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md, census.

(define-closed-enum enumerability_class
  (:AUTHORITATIVE_COMPLETE_INDEX) (:AUTHENTICATED_SERIAL_SPACE)
  (:AUTHORITATIVE_PARTIAL_INDEX) (:OBSERVATIONAL_OPEN_WORLD_SOURCE) (:UNKNOWN))
(define-closed-enum availability_class
  (:PUBLICLY_AVAILABLE) (:LEGALLY_UNAVAILABLE_OR_NON_PUBLIC)
  (:ACCESS_RESTRICTED) (:LICENSING_RESTRICTED) (:UNKNOWN))

;; D2.4 — TYPE DECISION (eliminates the ambiguity): the CANONICAL coverage-state type has EXACTLY
;; three members; NOT_OBSERVED_IN_DECLARED_SOURCE and COVERED_STATE_NON_PUBLIC are NOT members of it —
;; they are SEPARATE observation / availability DIMENSIONS that map INTO coverage_state.
(define-closed-enum coverage_state                 ; canonical, fail-closed
  (:PRESENT) (:EXPLICITLY_ABSENT) (:UNKNOWN))
(define-closed-enum observation_state              ; dimension (input), NOT a coverage_state member
  (:OBSERVED) (:NOT_OBSERVED_IN_DECLARED_SOURCE) (:UNKNOWN))
(define-closed-enum availability_state             ; dimension (input), NOT a coverage_state member
  (:PUBLIC_PRESENT) (:COVERED_STATE_NON_PUBLIC) (:ACCESS_RESTRICTED) (:LICENSING_RESTRICTED) (:UNKNOWN))

;; D2.1 — typed negative evidence.
(define-record NegativeEvidence/1
  (:census_space_ref :type id) (:issuing_authority_ref :type id) (:source_ref :type id)
  (:scope :type scope) (:observation_time :type instant)
  (:completeness_or_serial_rule_ref :type ref)     ; the authority rule that makes absence provable
  (:evidence_artifact_digest :type sha256) (:expiry :type instant) (:signature :type sig))

(define-record CensusSpaceClassification/1
  (:space_id :type id) (:enumerability_class :type enumerability_class)
  (:availability_class :type availability_class) (:negative_evidence_policy :type ref)
  (:authoritative_index_ref :type ref) (:serial_authority_ref :type ref)
  (:completeness_assertion_ref :type ref)          ; D2.3 — required for COMPLETE_INDEX AND SERIAL_SPACE
  (:serial_position_semantics_ref :type ref)       ; D2.2 — authority rule: are gaps reservable/void/cancelled?
  (:gap_evidence_requirements :type (list requirement))
  (:valid_from :type instant) (:valid_to :type (or instant null))
  (:revocation_correction_semantics :type ref))

;; D2.3 — required refs per enumerability_class (machine-checkable, audit V5S-D2c):
(define-required-refs CensusSpaceClassification/1
  (:AUTHORITATIVE_COMPLETE_INDEX  authoritative_index_ref completeness_assertion_ref)
  (:AUTHENTICATED_SERIAL_SPACE    serial_authority_ref completeness_assertion_ref serial_position_semantics_ref)
  (:AUTHORITATIVE_PARTIAL_INDEX   authoritative_index_ref)
  (:OBSERVATIONAL_OPEN_WORLD_SOURCE)
  (:UNKNOWN))

;; D2.2 / D2.4 / D2.5 — strict gap -> coverage_state mapping (canonical output ∈ {PRESENT,EXPLICITLY_ABSENT,UNKNOWN}):
(define-mapping gap->coverage_state
  ;; EXPLICITLY_ABSENT only with fresh authenticated NegativeEvidence over a space whose serial/
  ;; completeness rule PROVES the position cannot be reserved/void/cancelled/legally-unused.
  ((:enum :AUTHORITATIVE_COMPLETE_INDEX :neg-evidence :fresh-authenticated) :EXPLICITLY_ABSENT)
  ((:enum :AUTHENTICATED_SERIAL_SPACE   :neg-evidence :fresh-authenticated
          :serial-rule :dense-non-reservable-proven)                        :EXPLICITLY_ABSENT)
  ((:enum :AUTHENTICATED_SERIAL_SPACE   :serial-rule :reservable-or-void-or-unknown) :UNKNOWN) ; D2.2 fail-closed
  ((:enum :AUTHORITATIVE_PARTIAL_INDEX) :UNKNOWN)   ; observation_state=NOT_OBSERVED_IN_DECLARED_SOURCE
  ((:enum :OBSERVATIONAL_OPEN_WORLD_SOURCE) :UNKNOWN)
  ((:availability :LEGALLY_UNAVAILABLE_OR_NON_PUBLIC) :UNKNOWN) ; availability_state=COVERED_STATE_NON_PUBLIC (not crawler failure)
  ((:neg-evidence :insufficient-or-expired) :UNKNOWN))          ; D2.5 fail-closed

(define-invariant :V5I-04
  "EXPLICITLY_ABSENT requires fresh authenticated NegativeEvidence/1 over an AUTHORITATIVE_COMPLETE_INDEX,
   or over an AUTHENTICATED_SERIAL_SPACE whose serial_position_semantics_ref PROVES gaps cannot be
   reserved/void/cancelled/legally-unused. A serial gap alone is NEVER EXPLICITLY_ABSENT (⇒ UNKNOWN).")
(define-invariant :V5I-05
  "coverage_state is exactly {PRESENT, EXPLICITLY_ABSENT, UNKNOWN}. NOT_OBSERVED_IN_DECLARED_SOURCE and
   COVERED_STATE_NON_PUBLIC are observation_state / availability_state DIMENSIONS, not coverage_state
   members. Insufficient/expired negative evidence, or missing completeness assertion ⇒ coverage_state
   = UNKNOWN (fail-closed).")

;; ============================ D3 — EVIDENCE-BACKED INDEPENDENCE QUORUMS ======================
;; Seat: MACHINE-LEGAL-TRUST-PROTOCOL.md (§10 mesh) + LocalTrustState + qualification. One quorum seat.

;; D3.1 — SEPARATE assurance profile for independence (distinct from D1 SemanticAdmissionAssuranceProfile).
(define-closed-enum IndependenceAssuranceProfile
  (:IA-0 :label "DECLARED"    :binding :self-declared)          ; lowest; never counts under strict
  (:IA-1 :label "ATTESTED"    :binding :third-party-attested)
  (:IA-2 :label "CRYPTO_BOUND":binding :cryptographic-identity+custody))

(define-closed-enum IndependenceDimension
  (:LEGAL_BENEFICIAL_CONTROL) (:PRIVILEGED_ADMINISTRATION) (:KEY_CUSTODY)
  (:INFRASTRUCTURE_DEPENDENCY) (:CONFLICT_OF_INTEREST))

;; D3.2 — cryptographically bind actor identity, kid/public key, control domain, evidence subject.
(define-record ActorIndependenceEvidence/1
  (:actor_identity :type id) (:actor_kid :type kid) (:actor_public_key :type pubkey)
  (:control_domain_id :type id) (:evidence_subject_digest :type sha256)   ; the attested subject, bound
  (:evidence_issuer :type id) (:evidence_type :type IndependenceDimension)
  (:assurance_profile :type IndependenceAssuranceProfile)
  (:valid_from :type instant) (:valid_to :type instant)
  (:legal_beneficial_control_evidence :type ref) (:privileged_administration_evidence :type ref)
  (:key_custody_evidence :type ref) (:infrastructure_dependency_evidence :type ref)
  (:conflict_of_interest_evidence :type ref)
  (:digest :type sha256) (:signature :type sig)        ; signature over canonical(BODY) binding all above
  (:revocation_ref :type ref))
(define-invariant :V5I-D3-bind
  "ActorIndependenceEvidence signature MUST cover a canonical body binding actor_identity + actor_kid +
   actor_public_key + control_domain_id + evidence_subject_digest. Evidence not so bound ⇒ ignored
   (INDEPENDENCE_UNKNOWN under strict profile).")

;; D3.3 — typed trusted issuer registry (consumer-local).
(define-record TrustedIssuerRegistry/1 (:registry_id :type id) (:entries :type (list IssuerEntry/1)))
(define-record IssuerEntry/1
  (:issuer_id :type id) (:issuer_public_key :type pubkey)
  (:issuer_authority :type (list IndependenceDimension))   ; what this issuer may attest
  (:scope :type scope) (:delegated_from :type (or id null))
  (:valid_from :type instant) (:valid_to :type instant) (:revocation_ref :type ref))

;; D3.4 — revocation requiredness + verification semantics.
(define-rule revocation-semantics
  (:revocation_ref-required-when "the accepting IssuerEntry or IndependencePolicy declares the issuer
     supports revocation")
  (:verify "resolve revocation source; if it shows revoked at t_use ⇒ evidence does NOT count")
  (:fail-closed "under a strict IndependencePolicy, evidence whose revocation status cannot be resolved
     ⇒ treated as UNKNOWN (never silently counted)"))

;; D3.5 — deterministic pairwise/group equivalence-class algorithm for independent control domains.
(define-algorithm control-domain-partition
  :input  (actors evidence policy)
  :steps  ((1 "nodes := actors")
           (2 "for each unordered pair (a,b): edge(a,b) iff they SHARE any dimension in
               policy.prohibited_shared_dimensions, proven by accepted, fresh, non-revoked evidence
               (same control_domain_id | same privileged administrator | same key custody | same infra
               dependency | declared COI)")
           (3 "under strict policy: if a shared/not-shared status is UNKNOWN, add the edge (fail-closed:
               treat as potentially-shared)")
           (4 "components := union-find connected components over (nodes, edges)  ; deterministic, order-independent")
           (5 "each component is one INDEPENDENT CONTROL DOMAIN (equivalence class)"))
  :output "a deterministic partition of actors into control-domain equivalence classes")

;; D3.6 — strict UNKNOWN / DEGRADE.
(define-closed-enum unknown_handling
  (:FAIL_CLOSED)   ; UNKNOWN/insufficient/expired/unresolvable-revocation actor NEVER counts toward a strict quorum
  (:DEGRADE))      ; quorum result explicitly downgraded (e.g. UNVERIFIED_FOR_MACHINE_RELIANCE); UNKNOWN excluded, never silent
(define-invariant :V5I-D3-unknown
  "Under :FAIL_CLOSED an actor with UNKNOWN/insufficient/expired independence evidence is excluded from
   the independent-component count and MUST NOT count toward a strict quorum. Under :DEGRADE the result
   is an explicit downgrade, never a silent pass.")

(define-record IndependencePolicy/1
  (:required_distinct_dimensions :type (list IndependenceDimension))
  (:prohibited_shared_dimensions :type (list IndependenceDimension))
  (:accepted_issuer_registry_ref :type ref)              ; -> TrustedIssuerRegistry/1
  (:evidence_freshness :type duration)
  (:min_independence_assurance :type IndependenceAssuranceProfile)
  (:unknown_handling :type unknown_handling)
  (:quorum :type quorum-spec))

;; D3.7 — final quorum predicate (normative + machine-readable). ONE seat; replaces distinct-valid-kids.
(define-quorum-predicate mesh-independence-quorum
  :was "distinct-valid-kids(members)"
  :now "let VALID   = { a in members : independence-evidence-valid(a, evidence, policy) }
              ; valid := fresh AND non-revoked AND issuer in accepted registry AND assurance >= policy.min
        let COMPS   = control-domain-partition(VALID, evidence, policy)
        let INDEP   = distinct-components(COMPS)
        in  |INDEP| >= policy.quorum.n
            AND covers(policy.required_distinct_dimensions, VALID, evidence)
            AND no-prohibited-shared-dimension(INDEP, evidence, policy)
            AND (policy.unknown_handling = :FAIL_CLOSED
                 => no member with UNKNOWN independence counted in INDEP)"
  :result-when-insufficient :INDEPENDENCE_UNKNOWN)
(define-invariant :V5I-06
  "Distinct kid does NOT prove independence. Self-signed (IA-0 under strict) does not count. Expired/
   revoked does not count. Insufficient evidence => INDEPENDENCE_UNKNOWN. The quorum counts distinct
   control-domain equivalence classes, never distinct kids.")
(define-invariant :V5I-07
  "The consumer-local verifier decides IndependencePolicy; LAWMAX/auditors cannot self-certify their own
   independence; a bundle cannot change consumer-local policy. A shared provider/cloud is not universally
   disqualifying — evaluated per IndependenceAssuranceProfile and control domain.")

;; ============================ C1 — INTERPRETIVE PROFILE CLOSURE =============================
;; Seats: LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md + CPEI L6 + Architecture Constitution :argument.
;; NOT a new engine, NOT a new top-level constitutional primitive. Represents the existing :argument.

;; C1.1 — expanded, non-opaque interpretive profile.
(define-record InterpretiveProfile/1
  (:profile_id :type id) (:version :type semver)
  (:methodology_canons :type (list canon))        ; e.g. textual, teleological, systematic, historical
  (:precedence_stance :type (member :precedential :non-precedential :persuasive))
  (:applicability :type scope)                     ; jurisdiction/subject/time
  (:authority_basis :type ref)
  (:conflict_handling :type (member :coexist :scoped-priority-by-adopted-policy :unresolved-conflicting))
  (:adoption_status :type (member :proposed :adopted :withdrawn))
  (:adoption_act_ref :type (or ref null)) (:withdrawal_ref :type (or ref null))
  (:source_anchors :type (list anchor)))

(define-closed-enum ArgumentScheme
  (:TEXTUAL) (:TELEOLOGICAL) (:SYSTEMATIC) (:HISTORICAL) (:ANALOGY) (:A_CONTRARIO)
  (:PRECEDENT) (:PRINCIPLE_BALANCING) (:OTHER))

;; C1.2/C1.3 — no circular self argument_ref; explicit content; represents the Constitution :argument.
(define-record ArgumentRecord/1
  (:argument_id :type id) (:interpretive_profile_ref :type ref)
  (:claim_ref :type ref)                           ; -> ClaimRecord/1 (no self argument_ref)
  (:premises :type (list ref))                     ; premise refs/anchors
  (:conclusion :type ref)
  (:support_edges :type (list id))                 ; -> other argument_ids/claims it supports
  (:attack_edges :type (list id))                  ; -> other argument_ids/claims it attacks
  (:argument_scheme :type ArgumentScheme)
  (:source_anchors :type (list anchor)) (:authority_scope :type scope)
  (:uncertainty :type uncertainty)                 ; typed lawmax/uncertainty/1
  (:adoption_status :type (member :unadopted :adopted :withdrawn))
  (:adoption_act_ref :type (or ref null))
  (:constitution_primitive :type keyword :fixed :argument))   ; represents existing primitive; NOT a new one

;; C1.4 — Claim/Hypothesis bound to profile + arguments in the machine schema.
(define-record ClaimRecord/1
  (:claim_id :type id) (:kind :type (member :claim :hypothesis))
  (:statement_ref :type ref) (:interpretive_profile_ref :type ref)
  (:argument_refs :type (list id))                 ; -> ArgumentRecord/1 ids
  (:status :type (member :open :adopted :conflicting :unknown)))

(define-invariant :V5I-08
  "Competing interpretations coexist: Claim-X -> Profile-A and Claim-Y -> Profile-B, no forced winner.
   Every interpretive ClaimRecord/ArgumentRecord MUST carry interpretive_profile_ref; a verifier that
   cannot distinguish two profile-scoped conclusions is a kill (V5KW-C1-1).")
(define-invariant :V5I-09
  "InstitutionalAct adoption (adoption_status/adoption_act_ref) changes institutional/epistemic status,
   NOT the objective truth of an interpretation. Adoption presented as proof of objective truth is a
   kill (V5KW-C1-3). A hidden free-text interpretive premise (no premise ref/anchor) is a kill (V5KW-C1-4).")

;; C1.5 — FORMAL machine-readable Constitution reference/invariant (replaces the inert comment). This is
;; a reference/invariant DATA form; it adds NO primitive, NO engine, NO gate. Mirrored in the
;; constitution .sexp as a (v1.5-interpretive-binding) reference form.
(define-constitution-reference v1.5-interpretive-binding
  :represents-primitive :argument
  :by-record "ArgumentRecord/1"
  :claims-record "ClaimRecord/1"
  :profile-record "InterpretiveProfile/1"
  :adds-primitive nil :adds-engine nil :adds-gate nil
  :invariant "ArgumentRecord/1 REPRESENTS the existing Constitution :argument primitive; it does not
              extend :primitives, create a reasoning engine, or add a gate. L6 Adversarial Parliament
              consumes these records as typed arguments with proof/counterproof.")

;; ============================ GLOBAL TRUST INVARIANT (unchanged wording) =====================
(define-invariant :V5I-10
  "NO SINGLE POINT OF BLIND TRUST — ALL TRUST ASSUMPTIONS EXPLICIT, MINIMIZED, SCOPED AND, WHERE
   POSSIBLE, INDEPENDENTLY VERIFIABLE. (The absolute no-required-trust claim is NOT used.) De jure
   boundary unchanged: State and courts issue the acts; LAWMAX/auditors verify authenticity,
   representation, process and publication, and never substitute sovereign authority.")
