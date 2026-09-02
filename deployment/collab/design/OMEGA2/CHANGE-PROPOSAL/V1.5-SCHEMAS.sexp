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
  (derivation_independence_evidence_ref      :F    :F    :C)   ; D1.6 — SA-2 candidate record; F2: REQUIRED (valid) at the SA-2-canonical-admission gate
  (residual_independence_assumption          :F    :F    :C)   ; D1.6/F2 — SA-2 CANDIDATE-only holder; NEVER admits to CANONICAL (see SA-2-canonical-admission)
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

;; D1.6 / F7 — real derivation independence. Distinct derivation_family_id ALONE is INSUFFICIENT. The
;; evidence has a DEFINED validity + trust root (R7): issuer, scope, freshness, revocation, candidate binding.
(define-record DerivationIndependenceEvidence/1
  (:candidate_id :type id) (:event_ref :type ref)   ; R7.1: bind the EXACT SA-2 candidate + event
  (:derivation_a_ref :type ref) (:derivation_b_ref :type ref)
  (:distinct_specification_source :type ref)   ; different spec/grammar/rules, not a shared spec
  (:distinct_provenance_toolchain :type ref)   ; different toolchain/provenance
  (:distinct_failure_domain :type ref)         ; different runtime/library/host failure domain
  (:evidence_issuer :type id)                  ; R7.1: issuer, scope-checked in the MLTP qualification registry
  (:valid_from :type instant) (:valid_to :type instant)
  (:freshness_policy_ref :type ref) (:revocation_ref :type ref)
  (:digest :type sha256) (:signature :type sig))   ; signed canonical body binding all above
;; R7.2-R7.5 — validity + trust root REUSE the existing LocalTrustState + MLTP qualification registry.
(define-rule derivation-independence-trust-root
  (:trust-root "REUSE the existing LocalTrustState + MLTP qualification registry and trust root; NO parallel
     trust protocol. The signature verifies under a qualification-registry-pinned issuer key.")
  (:issuer-scope "only an issuer whose qualification-registry scope authorizes attestation of DERIVATION
     INDEPENDENCE may attest it; out-of-scope issuer ⇒ evidence does NOT count")
  (:self-issued "self-issued / operator-issued evidence (evidence_issuer = an operator/producer of either
     derivation) does NOT count under strict SA-2 unless the consumer-local policy independently authorizes
     it; DEFAULT = rejection")
  (:validity "VALID := signature verifies AND issuer in qualification registry AND issuer scope authorizes
     derivation-independence attestation AND now in [valid_from, valid_to] AND fresh per freshness_policy_ref
     AND not revoked per revocation_ref AND (candidate_id, event_ref) bind the exact SA-2 candidate")
  (:fail-closed "missing / expired / revoked / untrusted / out-of-scope / wrong-candidate / shared-toolchain
     / shared-failure-domain evidence ⇒ NO canonical promotion (INDEPENDENCE_UNKNOWN)"))
(define-invariant :V5I-D1-indep
  "Independence for SA-2 holds only with a VALID DerivationIndependenceEvidence/1 binding distinct
   specification source AND provenance/toolchain AND failure domain. Distinct family_id or distinct
   artifact_digest alone ⇒ INDEPENDENCE_INSUFFICIENT. If independence is assumed but not evidenced,
   residual_independence_assumption MUST record the assumption explicitly (never silent).")
(define-invariant :V5I-F7-derivation-trust
  "F7: DerivationIndependenceEvidence/1 has a defined validity + trust root (issuer, scope, freshness,
   revocation, candidate binding), reusing LocalTrustState/MLTP qualification — no parallel trust protocol.
   The SA-2-canonical-admission gate VERIFIES the evidence, not merely the presence of a reference.
   Self/operator-attestation never satisfies strict SA-2 by default (kill V5KW-F7).")

(define-closed-enum DivergenceState
  (:AGREED) (:DETERMINISTIC_DIVERGENCE) (:INTERPRETIVE_DISAGREEMENT)
  (:INDEPENDENCE_INSUFFICIENT) (:UNKNOWN))

(define-invariant :V5I-01
  "SA-2 MUST NOT transition ADOPTED -> CANONICAL unless its SemanticAdmissionEvidence obligation is
   satisfied per the cardinality matrix (independent_check_ref AND independent_derivation_ref AND
   divergence_state=:AGREED AND a VALID DerivationIndependenceEvidence/1 AND adoption_act_ref). There is
   NO assumption alternative in this gate (F2). A schema-valid but wrong SA-2 event is QUARANTINED even
   if downstream compilers agree.")

;; F2 — SA-2 canonical-promotion gate. residual_independence_assumption is NEVER an alternative to evidence.
(define-gate SA-2-canonical-admission
  :from :ADOPTED :to :CANONICAL
  :requires (independent_check_ref
             independent_derivation_ref
             (divergence_state :is :AGREED)
             derivation_independence_evidence_ref     ; MUST resolve to a VALID DerivationIndependenceEvidence/1
             adoption_act_ref)
  :verify ("resolve derivation_independence_evidence_ref and VERIFY it per derivation-independence-trust-root
            (signature, issuer in qualification registry, issuer scope, freshness, revocation, and
            candidate_id/event binding to THIS candidate) — presence of the reference is NOT sufficient (R7.6)")
  :forbids-alternative residual_independence_assumption
  :assumption-disposition (:candidate-only (:CANDIDATE :UNKNOWN :QUARANTINED))
  :note "A record whose independence rests on residual_independence_assumption (no valid
         DerivationIndependenceEvidence/1) is inadmissible for ADOPTED->CANONICAL and for PUBLISHED
         machine-reliance; it is held at most at CANDIDATE/UNKNOWN/QUARANTINED.")

;; R8.2 — candidate_id identity/reference discipline.
(define-rule candidate-id-discipline
  (:identity "candidate_id = hex(sha256(id_domain ‖ 0x1F ‖ canonical(candidate BODY))); BODY excludes id +
     signatures + detached refs")
  (:target "every field that names a candidate (SemanticAdmissionEvidence/1.candidate_id,
     DerivationIndependenceEvidence/1.candidate_id, the SA-2-canonical-admission subject) resolves to this
     one content-addressed candidate_id — no ambient/implicit candidate"))

;; R8.5 — fail-closed handling of unregistered / future state-mutating event kinds.
(define-rule unregistered-state-event
  (:rule "any event NOT in the closed StateEventKind that is CAPABLE of mutating canonical legal state is
     treated as SA-2 and QUARANTINED pending a versioned StateEventKind taxonomy update; it is NEVER
     downgraded to SA-0/SA-1 (fail-closed)"))
(define-invariant :V5I-D1-unregistered-event
  "R8.5: an unregistered or future state-mutating event kind is SA-2/QUARANTINED pending a versioned
   taxonomy update — never SA-0/SA-1. Admitting such an event as SA-0/SA-1 ⇒ kill V5KW-R8-event.")
(define-invariant :V5I-D1-no-assumption-canonical
  "STRUCTURAL: the SA-2 ADOPTED->CANONICAL gate (SA-2-canonical-admission) contains NO assumption
   alternative — derivation_independence_evidence_ref (a VALID DerivationIndependenceEvidence/1) is a hard
   requirement, and residual_independence_assumption appears ONLY under :assumption-disposition as a
   CANDIDATE/UNKNOWN/QUARANTINED holder, never as an admission path to CANONICAL or PUBLISHED
   machine-reliance. Assumption ⇒ never canonical.")
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

;; D2.4 / F3 — TYPE DECISION (eliminates the ambiguity AND the shadow definition): the CANONICAL
;; census/coverage state is the FROZEN v1.4 enum — it is NOT redefined, renamed, or shrunk here.
;; Frozen v1.4 (CHANGE-PROPOSAL-v1.4.md §4.1, 88129099): state ∈ {INGESTED, EXPLICITLY-ABSENT,
;; QUARANTINED, UNKNOWN}. v1.5 reuses it EXACTLY (INGESTED not renamed to PRESENT; QUARANTINED kept).
;; NOT_OBSERVED_IN_DECLARED_SOURCE and COVERED_STATE_NON_PUBLIC are SEPARATE observation / availability
;; DIMENSIONS that MAP INTO this frozen state, never members of it.
(define-frozen-enum-reference census_coverage_state
  :canonical-in "CHANGE-PROPOSAL-v1.4.md §4.1 (frozen 88129099)"
  :members (:INGESTED :EXPLICITLY-ABSENT :QUARANTINED :UNKNOWN)   ; EXACT v1.4 enum; reused, not redefined
  :reuses-frozen t :adds-member nil :removes-member nil :renames-member nil)
(define-closed-enum observation_state              ; dimension (input), NOT a census_coverage_state member
  (:OBSERVED) (:NOT_OBSERVED_IN_DECLARED_SOURCE) (:UNKNOWN))
(define-closed-enum availability_state             ; dimension (input), NOT a census_coverage_state member
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

;; R3 (B-1) — TYPED INPUTS to the coverage decision. `OBSERVED` alone does NOT mean `INGESTED`.
(define-closed-enum acquisition_state           ; did lawful acquisition of the object succeed?
  (:ACQUIRED_LAWFUL) (:ACQUISITION_FAILED) (:NOT_ATTEMPTED) (:UNKNOWN))
(define-closed-enum validation_state            ; did validation pass?
  (:VALIDATED) (:VALIDATION_FAILED) (:NOT_VALIDATED) (:UNKNOWN))
(define-closed-enum admission_obligation_state  ; SA-obligation (D1) for a mutating candidate
  (:SATISFIED) (:UNMET) (:NOT_APPLICABLE) (:UNKNOWN))
(define-closed-enum negative_evidence_validity  ; qualifying fresh negative evidence?
  (:FRESH_QUALIFYING) (:INSUFFICIENT) (:EXPIRED) (:ABSENT) (:UNKNOWN))

;; R3 (B-1) — ONE total, deterministic, single-valued decision function over the eight typed inputs, output
;; is the FROZEN v1.4 census_coverage_state {INGESTED, EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN}. Ordered
;; precedence (first matching clause wins ⇒ single-valued); the final :otherwise makes it total.
(define-decision-function census-coverage-decision
  :inputs (observation acquisition validation admission divergence availability enumerability negative_evidence)
  :output census_coverage_state
  :ordered-clauses
  (;; (1-3) QUARANTINED dominates: deterministic divergence, failed validation, or unmet mandatory admission.
   ((:divergence :DETERMINISTIC_DIVERGENCE)                                   :QUARANTINED)
   ((:validation :VALIDATION_FAILED)                                          :QUARANTINED)
   ((:admission  :UNMET)                                                      :QUARANTINED)
   ;; (4) INGESTED requires successful lawful acquisition AND validation AND required admission — not mere observation.
   ((:observation :OBSERVED) (:acquisition :ACQUIRED_LAWFUL) (:validation :VALIDATED)
    (:admission (:member :SATISFIED :NOT_APPLICABLE))                         :INGESTED)
   ;; (5) EXPLICITLY-ABSENT requires the qualifying fresh negative evidence over a completeness/serial space.
   ((:negative_evidence :FRESH_QUALIFYING)
    (:enumerability (:member :AUTHORITATIVE_COMPLETE_INDEX :AUTHENTICATED_SERIAL_SPACE)) :EXPLICITLY-ABSENT)
   ;; (6) every remaining combination is UNKNOWN (fail-closed, total).
   (:otherwise                                                               :UNKNOWN))
  :precedence "QUARANTINED > INGESTED > EXPLICITLY-ABSENT > UNKNOWN (clauses are evaluated top-to-bottom)")
(define-invariant :V5I-04
  "R3/B-1: census-coverage-decision is TOTAL, deterministic and SINGLE-VALUED over the finite input product.
   INGESTED requires lawful acquisition + validation + required admission (not mere OBSERVED). QUARANTINED
   dominates on deterministic divergence / validation failure / unmet admission. EXPLICITLY-ABSENT requires
   fresh qualifying NegativeEvidence/1 over an AUTHORITATIVE_COMPLETE_INDEX, or an AUTHENTICATED_SERIAL_SPACE
   whose serial_position_semantics_ref PROVES gaps are non-reservable/void/cancelled/unused. Every remaining
   combination ⇒ UNKNOWN. A serial gap alone is NEVER EXPLICITLY-ABSENT. Audit V5G enumerates the product:
   zero uncovered, zero multi-output, exactly one frozen state per combination.")
(define-invariant :V5I-05
  "F3: v1.5 does NOT define a coverage-state type. The canonical census/coverage state is the FROZEN v1.4
   enum census_coverage_state = {INGESTED, EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN} (INGESTED not renamed
   to PRESENT; QUARANTINED preserved). observation_state and availability_state are separate DIMENSIONS
   that map into it (dimensions->census_coverage_state); NOT_OBSERVED_IN_DECLARED_SOURCE and
   COVERED_STATE_NON_PUBLIC are dimension members, never census_coverage_state members. Insufficient/
   expired negative evidence, or missing completeness assertion ⇒ UNKNOWN (fail-closed).")

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

;; F4 — WHO signs ActorIndependenceEvidence, and how the verification key is selected.
(define-invariant :V5I-D3-issuer-signing
  "ActorIndependenceEvidence/1 is signed by the issuer named in evidence_issuer. Its verification key is
   the IssuerEntry.issuer_public_key resolved by issuer_id in the LocalTrustState-pinned, content-addressed
   TrustedIssuerRegistry/1; no matching / expired / revoked / out-of-authority entry ⇒ evidence does NOT
   count. Self-issued (evidence_issuer = actor_identity) is IA-0 DECLARED and NEVER counts as independent
   attestation under a strict policy.")

;; R5 (C-1) — DomainAssertion is TYPED MEMBERSHIP, not a unary same/distinct verdict: "actor/key belongs to
;; domain identifier X, in accepted namespace N, for independence dimension D". Domain identifiers are only
;; comparable WITHIN the same accepted namespace (or via a root-authorized equivalence); two issuers using
;; DIFFERENT namespace vocabularies for the same real owner cannot fake independence.
(define-record DomainAssertion/1
  (:dimension :type IndependenceDimension)
  (:subject_actor_id :type id) (:subject_kid :type kid)
  (:namespace_id :type id)                            ; the accepted namespace this identifier lives in
  (:domain_identifier :type id)                       ; the domain id AS WRITTEN in that namespace
  (:normalized_domain_id :type id)                    ; normalized per the namespace's normalization/version rule
  (:issuer_id :type id) (:source_evidence_ref :type ref)   ; issuer resolved + scope-checked in the pinned registry
  (:valid_from :type instant) (:valid_to :type instant) (:revocation_ref :type ref)
  (:digest :type sha256) (:signature :type sig))

;; R5.3/R5.4 — a domain-identifier NAMESPACE is authorized per dimension inside the pinned trust registry.
(define-record DomainNamespaceAuthorization/1
  (:namespace_id :type id) (:dimension :type IndependenceDimension)
  (:namespace_authority :type id)                     ; who governs/assigns identifiers in this namespace
  (:normalization_rule_ref :type ref) (:version :type semver)
  (:uniqueness_guarantee :type (member :true :false)) ; does the namespace guarantee globally-unique ids?
  (:issuer_id :type id) (:valid_from :type instant) (:valid_to :type instant) (:revocation_ref :type ref))

;; R5.5 — cross-namespace comparison ONLY through content-addressed, root-authorized equivalence records
;; kept in the same pinned registry/trust seat. No equivalence ⇒ different namespaces do NOT prove independence.
(define-record NamespaceEquivalence/1
  (:equivalence_id :type id)                          ; content-addressed
  (:dimension :type IndependenceDimension)
  (:namespace_a :type id) (:normalized_domain_a :type id)
  (:namespace_b :type id) (:normalized_domain_b :type id)
  (:root_authorized_by :type id)                      ; root authority in the pinned trust seat
  (:valid_from :type instant) (:valid_to :type instant) (:revocation_ref :type ref)
  (:digest :type sha256) (:signature :type sig))

(define-rule domain-namespace-comparison
  (:same-namespace "same namespace_id + same normalized_domain_id ⇒ SHARED domain (R5.7)")
  (:distinct-same-namespace "different normalized_domain_id in the SAME namespace ⇒ independent ONLY if that
     namespace's DomainNamespaceAuthorization has uniqueness_guarantee = true and the required evidence is
     valid (R5.8); otherwise fail-closed potentially-shared")
  (:cross-namespace "different namespaces ⇒ compared ONLY via a valid, non-revoked, root-authorized
     NamespaceEquivalence/1 for the dimension; without one, differing namespaces do NOT prove independence
     ⇒ fail-closed INDEPENDENCE_UNKNOWN / merged potential-control domain (R5.6)")
  (:conflict "conflicting accepted DomainAssertions for the SAME actor+dimension (contradictory memberships)
     ⇒ INDEPENDENCE_UNKNOWN, NEVER implementation-order selection (R5.9)")
  (:issuer-scope "the issuer of a DomainAssertion / equivalence / namespace authorization must be
     scope-authorized in the pinned registry for that dimension+namespace; out-of-authority ⇒ not counted (R5.10)")
  (:bundle "a delivered bundle CANNOT substitute the pinned registry, namespaces, or equivalences"))
(define-invariant :V5I-D3-domainassertion
  "R5/C-1: control-domain-partition consumes typed-membership DomainAssertion/1 compared under
   domain-namespace-comparison. Same namespace+normalized id ⇒ shared. Cross-namespace requires a valid
   root-authorized NamespaceEquivalence/1. No equivalence, unauthorized namespace, stale/revoked equivalence,
   contradictory assertions, or bundle substitution ⇒ fail-closed (edge / INDEPENDENCE_UNKNOWN), never a
   silent independence win. ActorIndependenceEvidence.control_domain_id is a convenience summary, NEVER input.")

;; D3.3 / F4 / R5.4 — typed trusted issuer registry: versioned, content-addressed, pinned by LocalTrustState.
;; It also holds the per-dimension domain-identifier namespace authorizations and namespace equivalences (R5).
(define-record TrustedIssuerRegistry/1
  (:registry_id :type id)                    ; = hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY))); content-addressed
  (:version :type semver) (:entries :type (list IssuerEntry/1))
  (:domain_namespace_authorizations :type (list DomainNamespaceAuthorization/1))   ; R5.4
  (:namespace_equivalences :type (list NamespaceEquivalence/1))                     ; R5.5
  (:supersedes :type (or id null))           ; monotonic update chain (previous registry_id or null)
  (:digest :type sha256) (:signature :type sig))
(define-record IssuerEntry/1
  (:issuer_id :type id) (:issuer_public_key :type pubkey)
  (:issuer_authority :type (list IndependenceDimension))   ; what this issuer may attest
  (:scope :type scope) (:delegated_from :type (or id null))
  (:valid_from :type instant) (:valid_to :type instant) (:revocation_ref :type ref))
(define-rule trusted-issuer-registry-pinning
  (:pinned-by "LocalTrustState.independence_issuer_registry_ref = a content-addressed registry_id")
  (:authenticity "the registry signature verifies under a LocalTrustState-pinned root key; an unpinned or
     unsigned registry is NOT accepted")
  (:update "monotonic: a new registry_id with supersedes = the pinned one, signed under the pinned root;
     consumer-local adoption only; a delivered bundle CANNOT change the pinned registry")
  (:evidence-issuer-key-selection "ActorIndependenceEvidence.evidence_issuer -> IssuerEntry with matching
     issuer_id in the PINNED registry; verification key = that entry's issuer_public_key; no entry /
     expired / revoked / out-of-authority ⇒ evidence does NOT count"))

;; D3.4 — revocation requiredness + verification semantics.
(define-rule revocation-semantics
  (:revocation_ref-required-when "the accepting IssuerEntry or IndependencePolicy declares the issuer
     supports revocation")
  (:verify "resolve revocation source; if it shows revoked at t_use ⇒ evidence does NOT count")
  (:fail-closed "under a strict IndependencePolicy, evidence whose revocation status cannot be resolved
     ⇒ treated as UNKNOWN (never silently counted)"))

;; D3.5 / F4 / R5 — deterministic equivalence-class algorithm consuming TYPED-MEMBERSHIP DomainAssertion/1
;; records, comparing domain identifiers under domain-namespace-comparison (namespace-aware, fail-closed).
(define-algorithm control-domain-partition
  :input  (actors domain-assertions registry policy)
  :steps  ((1 "nodes := actors")
           (2 "for each unordered pair (a,b) and each dimension d in policy.prohibited_shared_dimensions:
               take a's and b's fresh, non-revoked, issuer-scope-authorized DomainAssertion/1 for d")
           (3 "SHARED(a,b,d) iff (same namespace_id AND same normalized_domain_id) OR (a valid, non-revoked,
               root-authorized NamespaceEquivalence/1 for d maps a's (namespace,normalized id) to b's).
               edge(a,b) if SHARED for any prohibited d")
           (4 "fail-closed: if for any prohibited d the membership is missing, unauthorized-namespace,
               cross-namespace WITHOUT an accepted equivalence, contradictory (conflicting assertions for the
               same actor+dimension), or otherwise :unknown ⇒ add the edge (treat as potentially-shared)")
           (5 "components := union-find connected components over (nodes, edges)  ; deterministic, order-independent")
           (6 "each component is one INDEPENDENT CONTROL DOMAIN (equivalence class)"))
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
  (:accepted_issuer_registry_ref :type ref)              ; -> content-addressed TrustedIssuerRegistry/1.registry_id, pinned by LocalTrustState (F4)
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
;; Seats: LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md (epistemic node set {Fact,Norm,Claim,Proof,Counterproof,
;; Hypothesis}, L5/L6 proof-dependency graph) + InstitutionalAct + L2 bitemporal event-ledger/audit-timeline.
;; NOT a new engine/store/primitive. Represents the existing :argument. IMMUTABLE identity-bearing records
;; carry NO lifecycle; lifecycle is a DETACHED overlay in the existing InstitutionalAct + event-ledger seat.

(define-closed-enum ArgumentScheme
  (:TEXTUAL) (:TELEOLOGICAL) (:SYSTEMATIC) (:HISTORICAL) (:ANALOGY) (:A_CONTRARIO)
  (:PRECEDENT) (:PRINCIPLE_BALANCING) (:OTHER))

;; R8.1 — the exact statement target: an EXISTING Legal-IR epistemic node of a proposition kind
;; (subset of the frozen node set {Fact, Norm, Claim, Proof, Counterproof, Hypothesis}).
(define-closed-enum StatementTargetKind (:Norm) (:Fact))

;; ---- IMMUTABLE identity-bearing records (R2). *_id = hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY)));
;;      BODY excludes id + signatures + every detached field. NO adoption_status / adoption_act_ref /
;;      withdrawal_ref / status / support_edges / attack_edges in ANY identity-bearing body. ----

;; R6 — CanonRule/1: immutable typed canon (F5: not opaque; R2: no lifecycle in the body).
(define-record CanonRule/1
  (:canon_id :type id)                             ; content-addressed; BODY excludes lifecycle
  (:version :type semver) (:canon_kind :type ArgumentScheme)
  (:applicability :type scope) (:authority_basis :type ref) (:source_anchors :type (list anchor)))

;; R6 — CanonPolicy/1 is the SOLE canonical owner of the ordered/scoped canon list, by content-addressed
;; canon_id references (NOT embedded duplicate CanonRule records). Delegates conflict to v1.4 ConflictPolicyBundle.
(define-record CanonPolicy/1
  (:policy_id :type id) (:version :type semver)
  (:canon_id_refs :type (list id))                 ; -> CanonRule/1.canon_id (content-addressed refs, single source)
  (:ordering :type (member :ordered :unordered :scoped-by-adopted-conflict-policy))
  (:conflict_policy_bundle_ref :type ref)          ; -> EXISTING v1.4 ConflictPolicyBundle (§4.17); no invented priority
  (:applicability :type scope) (:authority_basis :type ref))

;; R6.3 — InterpretiveProfile/1 carries ONLY canon_policy_ref; the embedded methodology_canons list is GONE.
(define-record InterpretiveProfile/1
  (:profile_id :type id) (:version :type semver)
  (:canon_policy_ref :type ref)                    ; R6: -> CanonPolicy/1.policy_id (the single canon source)
  (:precedence_stance :type (member :precedential :non-precedential :persuasive))
  (:applicability :type scope) (:authority_basis :type ref)
  (:conflict_handling :type (member :coexist :scoped-priority-by-adopted-policy :unresolved-conflicting))
  (:source_anchors :type (list anchor)))
;; R6.4 — a convenience canon list, if exposed, is a DERIVED projection (never identity-bearing).
(define-projection InterpretiveProfileCanons
  :derivation "resolve InterpretiveProfile/1.canon_policy_ref -> CanonPolicy/1.canon_id_refs -> CanonRule/1"
  :identity :none :hash-bearing nil :derived t)
(define-invariant :V5I-C1-canon
  "F5/R6/D-1: interpretive canons are typed CanonRule/1 (versioned, scoped, source-anchored); the SOLE
   ordered/scoped canon list lives in CanonPolicy/1 (content-addressed canon_id_refs). InterpretiveProfile/1
   holds ONLY canon_policy_ref (no second embedded list to diverge). Ordering/conflict delegates to the
   existing v1.4 ConflictPolicyBundle (§4.17) — never an invented universal Greek priority. No covering
   adopted policy ⇒ UNKNOWN(no-applicable-conflict-policy); incompatible adopted policies ⇒ CONFLICTING.
   No new engine, no new seat.")

;; R1 — ClaimRecord/1 immutable; statement_ref -> an existing Norm|Fact epistemic node; NO argument ref, NO status.
(define-record ClaimRecord/1
  (:claim_id :type id) (:kind :type (member :claim :hypothesis))
  (:statement_ref :type ref) (:statement_kind :type StatementTargetKind)   ; existing epistemic Norm|Fact node
  (:interpretive_profile_ref :type ref))           ; -> InterpretiveProfile/1.profile_id (already constructed)

;; R1.1 — ArgumentRecord/1 immutable; NO support_edges/attack_edges and NO adoption/status in the body.
(define-record ArgumentRecord/1
  (:argument_id :type id) (:interpretive_profile_ref :type ref)
  (:claim_ref :type ref)                           ; -> ClaimRecord/1.claim_id
  (:premises :type (list ref))                     ; -> Norm|Fact|Claim node or source anchor (see ref-classification)
  (:conclusion :type ref)                          ; -> ClaimRecord/1.claim_id (the concluded claim)
  (:argument_scheme :type ArgumentScheme)
  (:source_anchors :type (list anchor)) (:authority_scope :type scope)
  (:uncertainty :type uncertainty)                 ; typed lawmax/uncertainty/1
  (:constitution_primitive :type keyword :fixed :argument))   ; represents existing primitive; NOT a new one

;; R1.2/R1.3/R1.4 — argument-to-argument support/attack is a TYPED RELATION in the existing L5/L6
;; proof-dependency graph, constructed AFTER both endpoint ids exist; it references only already-immutable
;; ids and is NOT part of any argument's identity (so mutual support/attack cannot form a hash cycle).
(define-record ArgumentRelation/1
  (:relation_id :type id)                          ; content-addressed over the relation body (two existing ids)
  (:relation :type (member :supports :attacks))
  (:from_argument_ref :type ref)                   ; -> ArgumentRecord/1.argument_id (already constructed)
  (:to_target_ref :type ref)                       ; -> ArgumentRecord/1.argument_id OR ClaimRecord/1.claim_id
  (:to_target_kind :type (member :argument :claim))
  (:source_anchors :type (list anchor)))
(define-invariant :V5I-C1-relation-detached
  "R1: ArgumentRelation/1 is constructed AFTER both endpoint ids exist and references only already-immutable
   ids. support/attack are NOT fields of ArgumentRecord/1, so mutual support/attack cannot create an
   ArgumentID <-> ArgumentID content-hash cycle (the relation's own id is not an input to either endpoint).")

;; R2 — DETACHED lifecycle overlay in the EXISTING InstitutionalAct + L2 event-ledger/audit-timeline seat.
;; It NEVER changes a subject's *_id. Current status is a reproducible PROJECTION of the immutable subject +
;; the ordered LifecycleRecord chain. No new store/engine.
(define-record LifecycleRecord/1
  (:lifecycle_record_id :type id)                  ; content-addressed over THIS record's body
  (:subject_id :type id)                           ; the IMMUTABLE subject id (claim/argument/profile/canon/policy)
  (:subject_kind :type (member :ClaimRecord :ArgumentRecord :InterpretiveProfile :CanonRule :CanonPolicy))
  (:transition :type (member :propose :adopt :withdraw :correct :revoke :supersede))
  (:act_ref :type ref)                             ; -> existing InstitutionalAct (adopting/withdrawing/correcting)
  (:legal_time :type instant) (:audit_time :type instant)   ; lawmax/legal-timeline/1 + audit-timeline/1
  (:supersedes :type (or id null))                 ; previous LifecycleRecord/1 id (ordered chain)
  (:signer :type id) (:evidence_ref :type ref)
  (:digest :type sha256) (:signature :type sig))
(define-projection SubjectCurrentStatus
  :derivation "fold the ordered LifecycleRecord/1 chain for subject_id over the immutable subject ->
               {none|proposed|adopted|withdrawn|corrected|revoked|superseded}"
  :identity :none :hash-bearing nil :derived t)
(define-rule lifecycle-overlay
  (:proposed "no adoption/withdrawal act required; a :propose LifecycleRecord may exist or not")
  (:adopted  "requires a valid adoption InstitutionalAct in act_ref")
  (:withdrawn "requires a valid withdrawal InstitutionalAct AND a preserved prior adoption chain (supersedes)")
  (:correction "a :correct LifecycleRecord supersedes the corrected state via the supersedes chain; the
     subject id is unchanged; the prior record is preserved")
  (:revocation "a :revoke LifecycleRecord marks the subject withdrawn-by-revocation from audit_time forward;
     historical records survive; no retroactive identity change")
  (:supersession ":supersede sets supersedes -> the prior LifecycleRecord id; the immutable subject and its
     *_id are never rewritten"))
(define-invariant :V5I-A2-immutable-id
  "R2/A-2: ClaimRecord/ArgumentRecord/InterpretiveProfile/CanonRule/CanonPolicy bodies carry NO
   adoption/withdrawal/status field; each *_id is a pure function of the immutable body. Lifecycle is the
   detached LifecycleRecord/1 overlay keyed to subject_id. Flipping adoption/withdrawal emits a NEW
   LifecycleRecord and CANNOT change the subject's *_id (kill V5KW-A2).")

;; R8.3 — ClaimArgumentIndex has ONE canonical derivation definition (no :over/:maps ambiguity).
(define-projection ClaimArgumentIndex
  :derivation "over the existing L5/L6 proof-dependency graph: claim_id -> { argument_id :
               ArgumentRecord/1.claim_ref = claim_id }"
  :identity :none :hash-bearing nil :derived t)

;; R1.5/R1.6 — EVERY ref-bearing field classified EXACTLY ONCE (hash-bearing | detached | derived) with its
;; allowed target(s). The cycle audit (V5G) cross-checks this list against the ACTUAL record fields and
;; FAILS if any ref-bearing field of a C1 record is absent here (understated graph).
(define-ref-classification
  ;; --- hash-bearing (part of the subject's content-addressed identity) ---
  (CanonRule/1.authority_basis              :hash-bearing (AuthorityBasis))
  (CanonPolicy/1.canon_id_refs              :hash-bearing (CanonRule/1))
  (CanonPolicy/1.conflict_policy_bundle_ref :hash-bearing (ConflictPolicyBundle))
  (CanonPolicy/1.authority_basis            :hash-bearing (AuthorityBasis))
  (InterpretiveProfile/1.canon_policy_ref   :hash-bearing (CanonPolicy/1))
  (InterpretiveProfile/1.authority_basis    :hash-bearing (AuthorityBasis))
  (ClaimRecord/1.statement_ref              :hash-bearing (StatementTargetKind))    ; Norm|Fact epistemic node
  (ClaimRecord/1.interpretive_profile_ref   :hash-bearing (InterpretiveProfile/1))
  (ArgumentRecord/1.interpretive_profile_ref :hash-bearing (InterpretiveProfile/1))
  (ArgumentRecord/1.claim_ref               :hash-bearing (ClaimRecord/1))
  (ArgumentRecord/1.premises                :hash-bearing (Norm Fact ClaimRecord/1 anchor))
  (ArgumentRecord/1.conclusion              :hash-bearing (ClaimRecord/1))
  (ArgumentRecord/1.authority_scope         :hash-bearing (scope))
  (ArgumentRelation/1.from_argument_ref     :hash-bearing (ArgumentRecord/1))
  (ArgumentRelation/1.to_target_ref         :hash-bearing (ArgumentRecord/1 ClaimRecord/1))
  ;; --- detached lifecycle/evidence (NOT part of identity) ---
  (LifecycleRecord/1.subject_id             :detached (ClaimRecord/1 ArgumentRecord/1 InterpretiveProfile/1 CanonRule/1 CanonPolicy/1))
  (LifecycleRecord/1.act_ref                :detached (InstitutionalAct))
  (LifecycleRecord/1.supersedes             :detached (LifecycleRecord/1))
  (LifecycleRecord/1.evidence_ref           :detached (Evidence))
  ;; --- derived projection (recomputable, no identity) ---
  (ClaimArgumentIndex                       :derived (ArgumentRecord/1 ClaimRecord/1))
  (InterpretiveProfileCanons                :derived (CanonPolicy/1 CanonRule/1))
  (SubjectCurrentStatus                     :derived (LifecycleRecord/1)))

;; R1.7/R6.5 — ONE complete ACYCLIC construction order (dependencies BEFORE consumers).
(define-construction-order legal-ir-interpretive
  (1  CanonRule/1)                ; immutable; refs only AuthorityBasis/anchors
  (2  ConflictPolicyBundle)       ; existing v1.4 record (frozen seat)
  (3  CanonPolicy/1)              ; refs CanonRule/1 (1) + ConflictPolicyBundle (2)
  (4  InterpretiveProfile/1)      ; refs CanonPolicy/1 (3) — NEVER before its canon dependencies
  (5  statement)                  ; existing epistemic Norm|Fact node (StatementTargetKind)
  (6  ClaimRecord/1)              ; refs InterpretiveProfile/1 (4) + statement (5)
  (7  ArgumentRecord/1)           ; refs ClaimRecord/1 (6) + InterpretiveProfile/1 (4)
  (8  ArgumentRelation/1)         ; refs already-built ArgumentRecord/1 (7) / ClaimRecord/1 (6)
  (9  LifecycleRecord/1)          ; detached overlay keyed to any immutable subject (1,3,4,6,7)
  (10 ClaimArgumentIndex)         ; derived projection over (7)
  (11 InterpretiveProfileCanons)  ; derived projection over (3)
  (12 SubjectCurrentStatus))      ; derived projection over (9)
(define-invariant :V5I-C1-acyclic
  "STRUCTURAL: the content-addressing dependency graph over ALL hash-bearing ref fields (derived from the
   actual record fields, cross-checked against define-ref-classification) is ACYCLIC. Identity-bearing
   bodies contain NO argument_id/argument_ref/argument_refs on a Claim and NO support_edges/attack_edges on
   an Argument; argument<->argument relations are the detached ArgumentRelation/1; Claim is built before
   Argument (legal-ir-interpretive). Any cycle among hash-bearing records, or any unclassified ref field,
   ⇒ kill (V5KW-C1-9 / V5KW-A1).")

(define-invariant :V5I-08
  "Competing interpretations coexist: Claim-X -> Profile-A and Claim-Y -> Profile-B, no forced winner.
   Every interpretive ClaimRecord/ArgumentRecord MUST carry interpretive_profile_ref; a verifier that
   cannot distinguish two profile-scoped conclusions is a kill (V5KW-C1-1).")
(define-invariant :V5I-09
  "InstitutionalAct adoption (via the detached LifecycleRecord/1 overlay) changes institutional/epistemic
   status, NOT the objective truth of an interpretation. Adoption presented as proof of objective truth is
   a kill (V5KW-C1-3). A hidden free-text interpretive premise (no premise ref/anchor) is a kill (V5KW-C1-4).")

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
