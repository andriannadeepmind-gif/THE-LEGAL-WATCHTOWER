;;;; LAWMAX OMEGA — SPEC v1.5 NARROW-DELTA — MACHINE-READABLE SCHEMAS (CANDIDATE, NOT FROZEN)
;;;; Parent 182399b1 · frozen v1.4 baseline 88129099 (unchanged). Design-only. Data, not code.
;;;; Scope: exactly D1 (Independent Semantic Admission), D2 (Census Enumerability + Negative
;;;; Evidence), D3 (Evidence-Backed Independence Quorums), C1 (Interpretive Profile closure).
;;;; No new datastore, no new journal/twin/engine, no new constitutional primitive, no new axis.

(spec-version "v1.5-narrow-delta-candidate"
 :status :CANDIDATE :not-frozen t :not-qualified t :implementation :BLOCKED
 :successor-of "CHANGE-PROPOSAL-v1.4.md" :frozen-baseline "88129099")

;; ============================ D1 — INDEPENDENT SEMANTIC ADMISSION ============================
;; Seat: LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md (adoption boundary). No universal N-version.

(define-closed-enum SemanticAdmissionAssuranceProfile
  (:SA-0 :label "STRUCTURAL"      :obligation :schema+anchors-only)
  (:SA-1 :label "CHECKABLE"       :obligation :derivation+independent-check)
  (:SA-2 :label "STATE_MUTATING"  :obligation :independent-derivation+divergence-gate))

(define-record SemanticAdmissionEvidence/1
  (:candidate_id                 :type id            :required t)
  (:assurance_profile            :type SemanticAdmissionAssuranceProfile :required t)
  (:source_manifestation_id      :type usc-id        :required t)
  (:source_anchors               :type (list anchor) :required t)
  (:derivation_family_id         :type id            :required t)   ; mechanism family, not kid
  (:derivation_artifact_digest   :type sha256        :required t)
  (:transformation_proof_ref     :type ref           :required t)
  (:independent_check_ref        :type ref           :required (:when (member assurance_profile (:SA-1 :SA-2))))
  (:independent_derivation_ref   :type ref           :required (:when (eq assurance_profile :SA-2)))
  (:divergence_state             :type DivergenceState :required t)
  (:adoption_act_ref             :type ref           :required (:when (eq assurance_profile :SA-2)))
  (:policy_ref :type ref :required t) (:schema_id :type id :required t) (:version :type semver :required t))

(define-closed-enum DivergenceState
  (:AGREED)                       ; independent derivations agree by mechanism diversity
  (:DETERMINISTIC_DIVERGENCE)     ; extraction/derivation differ on a deterministic fact ⇒ QUARANTINED
  (:INTERPRETIVE_DISAGREEMENT)    ; legitimate legal disagreement ⇒ typed hypothesis/argument, NOT error
  (:INDEPENDENCE_INSUFFICIENT)    ; derivations not shown mechanism-diverse ⇒ obligation unmet
  (:UNKNOWN))

;; event kind -> minimum assurance profile (SA of the *state effect*, not of the wrapper)
(define-mapping event-kind->assurance
  (:ANCHOR :SA-0) (:CITATION_ANCHOR :SA-0) (:OBSERVATION :SA-0)
  (:CLASSIFICATION :SA-1) (:LATER_TREATMENT_LINK :SA-1) (:CROSS_REFERENCE :SA-1)
  (:ENACTMENT :SA-2) (:AMENDMENT :SA-2) (:COMMENCEMENT :SA-2) (:REPEAL :SA-2))

;; INVARIANT V5I-01 (hard):
(define-invariant :V5I-01
  "SA-2 MUST NOT transition ADOPTED -> CANONICAL unless its SemanticAdmissionEvidence obligation is
   satisfied (independent_derivation_ref present AND divergence_state = :AGREED AND adoption_act_ref
   present). A schema-valid but wrong state-mutating event is QUARANTINED even if downstream
   compilers agree (compiler agreement is NOT a semantic-admission substitute).")
(define-invariant :V5I-02
  "INTERPRETIVE_DISAGREEMENT is never a compiler error and never resolved by majority vote; it stays a
   typed hypothesis/argument/UNKNOWN/CONFLICTING in the existing L5/L6 seat (see C1).")
(define-invariant :V5I-03
  "Mechanism diversity requires distinct derivation_family_id AND distinct derivation_artifact_digest
   over an independent source->event path; two binaries over the same spec/artifact do NOT prove it
   (INDEPENDENCE_INSUFFICIENT).")

;; ============================ D2 — CENSUS ENUMERABILITY + NEGATIVE EVIDENCE ==================
;; Seats: LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md, LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md, census.

(define-closed-enum enumerability_class
  (:AUTHORITATIVE_COMPLETE_INDEX)     ; a signed authoritative index enumerates the whole set
  (:AUTHENTICATED_SERIAL_SPACE)       ; contiguous authenticated serial (issue x year x number)
  (:AUTHORITATIVE_PARTIAL_INDEX)      ; authoritative but declared-partial index
  (:OBSERVATIONAL_OPEN_WORLD_SOURCE)  ; selective/observational, no completeness claim
  (:UNKNOWN))

(define-closed-enum availability_class
  (:PUBLICLY_AVAILABLE)
  (:LEGALLY_UNAVAILABLE_OR_NON_PUBLIC)
  (:ACCESS_RESTRICTED)
  (:LICENSING_RESTRICTED)
  (:UNKNOWN))

(define-record CensusSpaceClassification/1
  (:space_id :type id :required t)
  (:enumerability_class :type enumerability_class :required t)
  (:availability_class  :type availability_class  :required t)
  (:negative_evidence_policy :type ref :required t)
  (:authoritative_index_ref  :type ref :required (:when (member enumerability_class (:AUTHORITATIVE_COMPLETE_INDEX :AUTHORITATIVE_PARTIAL_INDEX))))
  (:serial_authority_ref     :type ref :required (:when (eq enumerability_class :AUTHENTICATED_SERIAL_SPACE)))
  (:completeness_assertion_ref :type ref :required (:when (eq enumerability_class :AUTHORITATIVE_COMPLETE_INDEX)))
  (:gap_evidence_requirements :type (list requirement) :required t)
  (:valid_from :type instant :required t) (:valid_to :type (or instant null) :required t)
  (:revocation_correction_semantics :type ref :required t))

;; gap position -> coverage state (STRICT):
(define-mapping gap-classification
  ((:enumerability :AUTHORITATIVE_COMPLETE_INDEX :authenticated-negative-evidence t) :EXPLICITLY_ABSENT)
  ((:enumerability :AUTHENTICATED_SERIAL_SPACE   :authenticated-negative-evidence t) :EXPLICITLY_ABSENT)
  ((:enumerability :AUTHORITATIVE_PARTIAL_INDEX)  :NOT_OBSERVED_IN_DECLARED_SOURCE)
  ((:enumerability :OBSERVATIONAL_OPEN_WORLD_SOURCE) :UNKNOWN)
  ((:availability :LEGALLY_UNAVAILABLE_OR_NON_PUBLIC) :COVERED_STATE_NON_PUBLIC)   ; not crawler failure
  ((:completeness-assertion :expired-or-missing) :UNKNOWN))                        ; never absence proof

(define-invariant :V5I-04
  "EXPLICITLY_ABSENT requires admissible authenticated negative evidence over an
   AUTHORITATIVE_COMPLETE_INDEX or AUTHENTICATED_SERIAL_SPACE. Non-appearance in a partial or
   observational source is NEVER proof of non-existence.")
(define-invariant :V5I-05
  "An expired or missing completeness_assertion_ref can never yield EXPLICITLY_ABSENT; the position is
   UNKNOWN. Legally non-public material is a declared coverage state, not a crawler failure.")

;; ============================ D3 — EVIDENCE-BACKED INDEPENDENCE QUORUMS ======================
;; Seat: MACHINE-LEGAL-TRUST-PROTOCOL.md (§10 mesh) + LocalTrustState + qualification. One quorum seat.

(define-record ActorIndependenceEvidence/1
  (:actor_identity :type id :required t)
  (:evidence_issuer :type id :required t)
  (:evidence_type :type IndependenceDimension :required t)
  (:valid_from :type instant :required t) (:valid_to :type instant :required t)
  (:legal_beneficial_control_evidence :type ref)
  (:privileged_administration_evidence :type ref)
  (:key_custody_evidence :type ref)
  (:infrastructure_dependency_evidence :type ref)
  (:conflict_of_interest_evidence :type ref)
  (:digest :type sha256 :required t) (:signature :type sig :required t) (:revocation_ref :type ref))

(define-closed-enum IndependenceDimension
  (:LEGAL_BENEFICIAL_CONTROL) (:PRIVILEGED_ADMINISTRATION) (:KEY_CUSTODY)
  (:INFRASTRUCTURE_DEPENDENCY) (:CONFLICT_OF_INTEREST))

(define-record IndependencePolicy/1
  (:required_distinct_dimensions :type (list IndependenceDimension) :required t)
  (:prohibited_shared_dimensions :type (list IndependenceDimension) :required t)
  (:accepted_evidence_issuers :type (list id) :required t)
  (:evidence_freshness :type duration :required t)
  (:unknown_handling :type (member :FAIL_CLOSED :DEGRADE) :required t)
  (:assurance_profile :type SemanticAdmissionAssuranceProfile :required t)
  (:quorum :type quorum-spec :required t))

;; quorum predicate change (ONE seat, no new seat):
(define-quorum-rule mesh-independence-quorum
  :was  (distinct-valid-kids members)
  :now  (and (distinct-valid-kids members)
             (satisfies local_independence_policy accepted_evidence members))
  :result-when-insufficient :INDEPENDENCE_UNKNOWN)

(define-invariant :V5I-06
  "Distinct kid does NOT prove independence. Self-signed independence declaration does not count.
   Expired/revoked evidence does not count. Insufficient evidence => INDEPENDENCE_UNKNOWN.")
(define-invariant :V5I-07
  "The consumer-local verifier decides the IndependencePolicy; LAWMAX/auditors cannot self-certify
   their own independence; a bundle cannot change consumer-local policy. A shared provider/cloud is
   NOT universally disqualifying — evaluated per assurance profile and control domain.")

;; ============================ C1 — INTERPRETIVE PROFILE CLOSURE =============================
;; Seats: LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md + CPEI L6 + Architecture Constitution :argument.
;; NOT a new engine, NOT a new top-level constitutional primitive. Represents existing :argument.

(define-record InterpretiveProfile/1
  (:profile_id :type id :required t) (:version :type semver :required t)
  (:scope :type scope :required t)   ; jurisdiction/authority/subject/time-scoped
  (:source_anchors :type (list anchor) :required t))

(define-record ArgumentRecord/1              ; representation of the existing Constitution :argument
  (:argument_id :type id :required t)
  (:interpretive_profile_ref :type ref :required t)
  (:argument_ref :type ref :required t)      ; -> Constitution :argument / L6 parliament record
  (:proof_ref :type ref :required t)
  (:counterproof_ref :type ref :required t)
  (:adoption_act_ref :type (or ref null) :required nil))   ; optional; InstitutionalAct

(define-invariant :V5I-08
  "Competing interpretations coexist: Claim-X -> Profile-A and Claim-Y -> Profile-B, with no forced
   winner. Every interpretive conclusion MUST carry interpretive_profile_ref + argument_ref; a
   verifier that cannot distinguish two profile-scoped conclusions is a kill (V5KW-C1-1).")
(define-invariant :V5I-09
  "InstitutionalAct adoption changes institutional/epistemic status, NOT the objective truth of an
   interpretation. Adoption presented as proof of objective truth is a kill (V5KW-C1-3).")

;; ============================ GLOBAL TRUST INVARIANT (unchanged wording) =====================
(define-invariant :V5I-10
  "NO SINGLE POINT OF BLIND TRUST — ALL TRUST ASSUMPTIONS EXPLICIT, MINIMIZED, SCOPED AND, WHERE
   POSSIBLE, INDEPENDENTLY VERIFIABLE. (The absolute no-required-trust claim is NOT used.) De jure
   boundary unchanged: State and courts issue the acts; LAWMAX/auditors verify authenticity,
   representation, process and publication, and never substitute sovereign authority.")
