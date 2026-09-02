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
  :forbids-alternative residual_independence_assumption
  :assumption-disposition (:candidate-only (:CANDIDATE :UNKNOWN :QUARANTINED))
  :note "A record whose independence rests on residual_independence_assumption (no valid
         DerivationIndependenceEvidence/1) is inadmissible for ADOPTED->CANONICAL and for PUBLISHED
         machine-reliance; it is held at most at CANDIDATE/UNKNOWN/QUARANTINED.")
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

;; D2.2 / D2.4 / D2.5 / F3 — strict mapping of the (enumerability × observation × availability × neg-evidence
;; × divergence) DIMENSIONS INTO the FROZEN v1.4 census_coverage_state {INGESTED, EXPLICITLY-ABSENT,
;; QUARANTINED, UNKNOWN}. Output is the frozen enum; no shadow output type.
(define-mapping dimensions->census_coverage_state
  ((:observation :OBSERVED)                                                  :INGESTED)      ; present in census
  ;; EXPLICITLY-ABSENT only with fresh authenticated NegativeEvidence over a space whose serial/
  ;; completeness rule PROVES the position cannot be reserved/void/cancelled/legally-unused.
  ((:enum :AUTHORITATIVE_COMPLETE_INDEX :neg-evidence :fresh-authenticated)  :EXPLICITLY-ABSENT)
  ((:enum :AUTHENTICATED_SERIAL_SPACE   :neg-evidence :fresh-authenticated
          :serial-rule :dense-non-reservable-proven)                         :EXPLICITLY-ABSENT)
  ((:divergence :DETERMINISTIC_DIVERGENCE)                                    :QUARANTINED)   ; from D1 admission (kept, F3)
  ((:enum :AUTHENTICATED_SERIAL_SPACE   :serial-rule :reservable-or-void-or-unknown) :UNKNOWN) ; D2.2 fail-closed
  ((:observation :NOT_OBSERVED_IN_DECLARED_SOURCE)                           :UNKNOWN)        ; AUTHORITATIVE_PARTIAL_INDEX
  ((:enum :OBSERVATIONAL_OPEN_WORLD_SOURCE)                                   :UNKNOWN)
  ((:availability :COVERED_STATE_NON_PUBLIC)                                  :UNKNOWN)        ; LEGALLY_UNAVAILABLE (not crawler failure)
  ((:neg-evidence :insufficient-or-expired)                                  :UNKNOWN))       ; D2.5 fail-closed

(define-invariant :V5I-04
  "EXPLICITLY-ABSENT (frozen v1.4 census state) requires fresh authenticated NegativeEvidence/1 over an
   AUTHORITATIVE_COMPLETE_INDEX, or over an AUTHENTICATED_SERIAL_SPACE whose serial_position_semantics_ref
   PROVES gaps cannot be reserved/void/cancelled/legally-unused. A serial gap alone is NEVER
   EXPLICITLY-ABSENT (⇒ UNKNOWN).")
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

;; F4 — normalized, per-dimension DomainAssertion is the TYPED INPUT of the partition algorithm.
;; control_domain_id (a single id on ActorIndependenceEvidence) cannot represent all IndependenceDimension
;; relations and evidence refs are opaque; one DomainAssertion per (actor, dimension) makes them typed.
(define-record DomainAssertion/1
  (:dimension :type IndependenceDimension)
  (:subject_actor_id :type id) (:subject_kid :type kid)
  (:normalized_domain_id :type id)                    ; canonical id of the shared control domain for THIS dimension
  (:relation :type (member :same-domain :distinct-domain :unknown))
  (:source_evidence_ref :type ref) (:issuer_id :type id)   ; issuer resolved in the pinned registry (F4)
  (:valid_from :type instant) (:valid_to :type instant) (:revocation_ref :type ref)
  (:digest :type sha256) (:signature :type sig))
(define-invariant :V5I-D3-domainassertion
  "control-domain-partition consumes DomainAssertion/1 (one per (actor,dimension)). A pairwise relation is
   :same-domain only with fresh, non-revoked, registry-accepted assertions carrying the SAME
   normalized_domain_id for a prohibited dimension. :unknown, missing, or unaccepted ⇒ fail-closed edge
   (potentially shared). ActorIndependenceEvidence.control_domain_id is a convenience summary and is NEVER
   the partition input.")

;; D3.3 / F4 — typed trusted issuer registry: versioned, content-addressed, pinned by LocalTrustState.
(define-record TrustedIssuerRegistry/1
  (:registry_id :type id)                    ; = hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY))); content-addressed
  (:version :type semver) (:entries :type (list IssuerEntry/1))
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

;; D3.5 / F4 — deterministic equivalence-class algorithm consuming TYPED DomainAssertion/1 records.
(define-algorithm control-domain-partition
  :input  (actors domain-assertions policy)
  :steps  ((1 "nodes := actors")
           (2 "for each unordered pair (a,b) and each dimension d in policy.prohibited_shared_dimensions:
               edge(a,b) iff a fresh, non-revoked, registry-accepted DomainAssertion/1 pair places a and b
               on the SAME normalized_domain_id for d (relation = :same-domain)")
           (3 "under strict policy: if the relation for any prohibited d is :unknown or lacks an accepted
               DomainAssertion, add the edge (fail-closed: treat as potentially-shared)")
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
;; Seats: LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md + CPEI L6 + Architecture Constitution :argument.
;; NOT a new engine, NOT a new top-level constitutional primitive. Represents the existing :argument.

;; C1.1 / F5 — canons are NOT opaque. Each is a typed, versioned, scoped, source-anchored CanonRule/1;
;; ordering/conflict is an adopted scoped CanonPolicy/1 that DELEGATES to the existing v1.4
;; ConflictPolicyBundle (§4.17). No invented universal Greek priority; no new engine or seat.
(define-record CanonRule/1
  (:canon_id :type id) (:version :type semver)
  (:canon_kind :type ArgumentScheme)               ; textual/teleological/systematic/historical/analogy/etc.
  (:applicability :type scope)                     ; jurisdiction/subject/time
  (:authority_basis :type ref) (:source_anchors :type (list anchor))
  (:adoption_status :type (member :proposed :adopted :withdrawn))
  (:adoption_act_ref :type (or ref null)))
(define-record CanonPolicy/1
  (:policy_id :type id) (:version :type semver)
  (:canon_refs :type (list CanonRule/1))           ; the canons this policy orders/scopes
  (:ordering :type (member :ordered :unordered :scoped-by-adopted-conflict-policy))
  (:conflict_policy_bundle_ref :type ref)          ; -> EXISTING v1.4 ConflictPolicyBundle (§4.17); no invented priority
  (:applicability :type scope) (:authority_basis :type ref)
  (:adoption_status :type (member :proposed :adopted :withdrawn))
  (:adoption_act_ref :type (or ref null)))

;; C1.1 — expanded, non-opaque interpretive profile.
(define-record InterpretiveProfile/1
  (:profile_id :type id) (:version :type semver)
  (:methodology_canons :type (list CanonRule/1))   ; F5: typed canon rules, NOT an opaque (list canon)
  (:canon_policy_ref :type ref)                    ; F5: -> CanonPolicy/1 (ordering/conflict via adopted ConflictPolicyBundle)
  (:precedence_stance :type (member :precedential :non-precedential :persuasive))
  (:applicability :type scope)                     ; jurisdiction/subject/time
  (:authority_basis :type ref)
  (:conflict_handling :type (member :coexist :scoped-priority-by-adopted-policy :unresolved-conflicting))
  (:adoption_status :type (member :proposed :adopted :withdrawn))
  (:adoption_act_ref :type (or ref null)) (:withdrawal_ref :type (or ref null))
  (:source_anchors :type (list anchor)))
(define-invariant :V5I-C1-canon
  "F5: interpretive canons are typed CanonRule/1 (versioned, scoped, source-anchored, with adoption_status);
   ordering and conflict are an adopted scoped CanonPolicy/1 that DELEGATES to the existing v1.4
   ConflictPolicyBundle (§4.17) — never an invented universal Greek priority. No covering adopted policy
   ⇒ UNKNOWN(no-applicable-conflict-policy); incompatible adopted policies ⇒ CONFLICTING. Reuses the
   existing argument engine and ConflictPolicyBundle: no new engine, no new seat.")

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

;; C1.4 / F1 — Claim/Hypothesis. claim_id = hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY))); BODY excludes
;; id + signatures + detached. The hash-bearing BODY contains NO argument reference (acyclic construction).
(define-record ClaimRecord/1
  (:claim_id :type id) (:kind :type (member :claim :hypothesis))
  (:statement_ref :type ref) (:interpretive_profile_ref :type ref)   ; both -> ALREADY-EXISTING records
  (:status :type (member :open :adopted :conflicting :unknown)))
  ;; F1: NO argument_refs in the hash-bearing ClaimRecord body. The reverse claim->arguments lookup is the
  ;; derived projection ClaimArgumentIndex below, NOT part of claim identity.

;; F1 — reverse claim->arguments is a DERIVED projection over the EXISTING proof-dependency graph
;; (L5/L6 proof/counterproof edges). It carries no *_id in any hash-bearing body; it is recomputable.
(define-projection ClaimArgumentIndex
  :over "existing L5/L6 proof-dependency graph"
  :maps "claim_id -> { argument_id : ArgumentRecord/1.claim_ref = claim_id }"
  :identity :none :hash-bearing nil :derived t)

;; F1 — exact ACYCLIC construction order (each stage refers only to earlier-constructed, already-hashed records).
(define-construction-order legal-ir-interpretive
  (1 InterpretiveProfile/1)   ; refers to CanonRule/1 / CanonPolicy/1, never to Claim/Argument
  (2 statement)               ; the interpreted statement/anchor (statement_ref target)
  (3 ClaimRecord/1)           ; claim_id = hash(BODY); BODY refs only (1),(2) — NEVER an argument
  (4 ArgumentRecord/1)        ; argument_id = hash(BODY); BODY refs the ALREADY-EXISTING claim_id from (3)
  (5 ClaimArgumentIndex))     ; derived projection over (4); not hash-bearing identity

;; F1 — hash-bearing reference targets (the edges that define content-addressing identity). The
;; type-dependency-cycle audit builds a graph over these :hash-bearing edges and proves ACYCLICITY.
;; The derived projection's edges are explicitly excluded.
(define-ref-targets
  (InterpretiveProfile/1 :hash-bearing (canon_policy_ref -> CanonPolicy/1))
  (CanonPolicy/1         :hash-bearing (conflict_policy_bundle_ref -> ConflictPolicyBundle))
  (ClaimRecord/1         :hash-bearing (interpretive_profile_ref -> InterpretiveProfile/1))
  (ArgumentRecord/1      :hash-bearing (claim_ref -> ClaimRecord/1)
                                       (interpretive_profile_ref -> InterpretiveProfile/1))
  (ClaimArgumentIndex    :derived      (claim -> ClaimRecord/1) (arguments -> ArgumentRecord/1)))
(define-invariant :V5I-C1-acyclic
  "STRUCTURAL: the content-addressing dependency graph over hash-bearing bodies is ACYCLIC. ClaimRecord/1
   BODY MUST NOT contain any argument_id / argument_ref / argument_refs; ArgumentRecord/1 references an
   already-constructed claim_id (Claim built before Argument, per legal-ir-interpretive). The reverse
   claim->arguments relation is ClaimArgumentIndex (derived projection), never part of claim identity.
   A cycle among hash-bearing records ⇒ kill (V5KW-C1-9).")

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
