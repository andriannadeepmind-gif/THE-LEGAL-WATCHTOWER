;;;; LAWMAX OMEGA — INTERFACE-AND-SCHEMA-REGISTRY (v1.6 CANDIDATE · single source of truth)
;;;; Machine-readable. Every interface/schema/contract defined EXACTLY once, with owner subsystem,
;;;; definition seat, version, consumers, signature owner and classification. Referenced-but-undefined
;;;; contracts and adapter-specific canonical types are rejected by the architecture gate (:V6I-17).
;;;; Design-only; parent 112379cc; frozen 88129099 intact. Reuse > new (each entry marks :reuse or :new).

(registry-version "interface-and-schema-registry-v1.6" :status :CANDIDATE :generated-source-of-truth t
 :classification :NORMATIVE :definition-seat "V1.6-SCHEMAS.sexp + v1.5 seats (LegalIR, MLTP, memory)")

;; ---- 13 universal stable contracts (v1.6 §6) ----
(define-interface PerceptionEnvelope/1     :owner S02 :seat "V1.6-SCHEMAS.sexp §2" :version "1" :new t
  :signature-owner "acquisition adapter" :consumers (S03 SemanticProposer) :classification :NORMATIVE)
(define-interface CandidateInterpretation/1 :owner S03 :seat "V1.6-SCHEMAS.sexp §2" :version "1" :reuse "lawmax/neural-candidate/1 (v1.4 §4.3)"
  :signature-owner "proposer adapter" :consumers (S03 S04 "legal-extraction-verify.lisp") :classification :NORMATIVE)
(define-interface LegalIR/1                 :owner S04 :seat "LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md + legal-ast.lisp" :version "1" :reuse "frozen epistemic node set"
  :signature-owner "write-authority.lisp" :consumers (S05 S06 S07 S09) :classification :NORMATIVE)
(define-interface MemoryEvent/1             :owner S19 :seat "memory.lisp + V1.6-SCHEMAS.sexp §4" :version "1" :reuse "memory.lisp events (EXTEND)"
  :signature-owner "write-authority.lisp" :consumers (S12 S04) :classification :NORMATIVE)
(define-interface CapabilityManifest/1      :owner S20 :seat "V1.6-SCHEMAS.sexp §2/§8" :version "1" :new t
  :signature-owner "adapter provider" :consumers (S03 S14 S20) :classification :NORMATIVE)
(define-interface ToolInvocation/1          :owner S20 :seat "V1.6-SCHEMAS.sexp §2" :version "1" :reuse "neural-task/1 shape"
  :signature-owner "invoking subsystem" :consumers (S03 S20) :classification :NORMATIVE)
(define-interface Plan/1                     :owner S12 :seat "V1.6-SCHEMAS.sexp §2 + decisions.lisp" :version "1" :reuse "cockpit_intent"
  :signature-owner "cockpit owner" :consumers (S12) :classification :NORMATIVE)
(define-interface ActionIntent/1             :owner S12 :seat "V1.6-SCHEMAS.sexp §2 + cockpit_intent" :version "1" :reuse "cockpit_intent kind=proposal"
  :signature-owner "cockpit owner" :consumers (S12) :classification :NORMATIVE)
(define-interface Approval/1                 :owner S12 :seat "approval-policy.lisp + release-authority.lisp (L12)" :version "1" :reuse "approval policy"
  :signature-owner "authority (RBAC/MFA)" :consumers (S12 S08) :classification :NORMATIVE)
(define-interface ExecutionReceipt/1         :owner S12 :seat "V1.6-SCHEMAS.sexp §2" :version "1" :new t
  :signature-owner "executing subsystem" :consumers (S12 S15) :classification :NORMATIVE)
(define-interface SafetyState/1              :owner S21 :seat "V1.6-SCHEMAS.sexp §2/§0" :version "1" :new t
  :signature-owner "safe-mode controller" :consumers (S03 S12 S20) :classification :NORMATIVE)
(define-interface TrustBundle/1              :owner S10 :seat "MLTP v3 + V1.6-SCHEMAS.sexp §2" :version "1" :reuse "trust_bundle (bnd1:) / LocalTrustState"
  :signature-owner "MLTP root" :consumers (S03 S08 S10 S19) :classification :NORMATIVE)
(define-interface DeclassificationReceipt/1  :owner S18 :seat "V1.6-SCHEMAS.sexp §2 + boundary" :version "1" :reuse "declassification gateway"
  :signature-owner "declassification authority" :consumers (S18 S22) :classification :NORMATIVE)

;; ---- v1.6 language cognition + memory + proposer interfaces ----
(define-interface SemanticProposer          :owner S03 :seat "V1.6-SCHEMAS.sexp §1" :version "1" :new t :kind :protocol
  :signature-owner "n/a (protocol)" :consumers (S03) :classification :NORMATIVE)
(define-interface LanguageCognitionLayer/1   :owner S04 :seat "V1.6-SCHEMAS.sexp §3" :version "1" :new t
  :signature-owner "cognition layer owner" :consumers (S04 S06 S09) :classification :NORMATIVE)
(define-interface CognitionResult/1          :owner S04 :seat "V1.6-SCHEMAS.sexp §3" :version "1" :new t
  :signature-owner "cognition layer owner" :consumers (S04 S09 S12) :classification :NORMATIVE)
(define-interface MemoryProjection/1         :owner S19 :seat "V1.6-SCHEMAS.sexp §4" :version "1" :new t
  :signature-owner "memory kernel" :consumers (S03 "proposers") :classification :NORMATIVE)
(define-interface MemoryPolicy/1             :owner S19 :seat "V1.6-SCHEMAS.sexp §4" :version "1" :new t
  :signature-owner "memory kernel" :consumers (S19) :classification :NORMATIVE)

;; ---- extension contracts (interfaces ONLY; never public dependencies) ----
(define-interface PrivateMatterProfile/1     :owner S22 :seat "V1.6-SCHEMAS.sexp §5" :version "1" :new t :status :DEFERRED_PRIVATE
  :signature-owner "matter key authority" :consumers () :classification :NORMATIVE :public-dependency nil)
(define-interface RealTimeAssistance/1       :owner S23 :seat "V1.6-SCHEMAS.sexp §5" :version "1" :new t :status :DEFERRED_PRIVATE
  :signature-owner "session authority" :consumers () :classification :NORMATIVE :public-dependency nil)
(define-interface EmbodimentInterfaces/1     :owner S24 :seat "V1.6-SCHEMAS.sexp §5" :version "1" :new t :status :DEFERRED_PRIVATE
  :signature-owner "device attestation authority" :consumers () :classification :NORMATIVE :public-dependency nil)

;; ---- reused v1.5 contract families (defined in their v1.5 seats; registered here for closure) ----
(define-interface SemanticAdmissionEvidence/1 :owner S03 :seat "V1.5-SCHEMAS.sexp D1" :version "1" :reuse "v1.5 D1"
  :signature-owner "ingress" :consumers (S03) :classification :NORMATIVE)
(define-interface CensusSpaceClassification/1 :owner S01 :seat "V1.5-SCHEMAS.sexp D2" :version "1" :reuse "v1.5 D2/F3"
  :signature-owner "census authority" :consumers (S01 S16) :classification :NORMATIVE)
(define-interface IndependencePolicy/1        :owner S10 :seat "V1.5-SCHEMAS.sexp D3" :version "1" :reuse "v1.5 D3/C-1"
  :signature-owner "consumer-local" :consumers (S10) :classification :NORMATIVE)
(define-interface InterpretiveProfile/1       :owner S04 :seat "V1.5-SCHEMAS.sexp C1" :version "1" :reuse "v1.5 C1/D-1"
  :signature-owner "adopting authority" :consumers (S04 S09) :classification :NORMATIVE)

;; ---- reused v1.4 canonical payload types (defined in their v1.4 seats; registered for reference closure) ----
(define-interface legal-timeline/1            :owner S05 :seat "CHANGE-PROPOSAL-v1.4.md §4.5 (payload)" :version "1" :reuse "v1.4 lawmax/legal-timeline/1"
  :signature-owner "issuing authority" :consumers (S05 S07) :classification :NORMATIVE)
(define-interface audit-timeline/1            :owner S05 :seat "CHANGE-PROPOSAL-v1.4.md §4.5 (proof/audit layer)" :version "1" :reuse "v1.4 lawmax/audit-timeline/1"
  :signature-owner "audit layer" :consumers (S05) :classification :NORMATIVE)
(define-interface citation/1                  :owner S09 :seat "MACHINE-LEGAL-TRUST-PROTOCOL.md §2.10 (CertifiedResult)" :version "1" :reuse "v1.4 typed citation/1"
  :signature-owner "certified-result signer" :consumers (S09 S13) :classification :NORMATIVE)

;; ---- v1.7 Root-Authority interfaces (defined in V1.7-SCHEMAS.sexp; registered here for closure) ----
(define-interface ResolverQuery/1            :owner S25 :seat "V1.7-SCHEMAS.sexp §4" :version "1" :new t
  :signature-owner "resolver front" :consumers (S25) :classification :NORMATIVE)
(define-interface ResolverResult/1           :owner S25 :seat "V1.7-SCHEMAS.sexp §4" :version "1" :new t
  :signature-owner "resolver front" :consumers (S25 S11) :classification :NORMATIVE)
(define-interface AmbiguityResult/1          :owner S25 :seat "V1.7-SCHEMAS.sexp §4" :version "1" :new t
  :signature-owner "resolver front" :consumers (S25) :classification :NORMATIVE)
(define-interface ResolverReceipt/1          :owner S25 :seat "V1.7-SCHEMAS.sexp §4" :version "1" :new t
  :signature-owner "resolver front" :consumers (S25) :classification :NORMATIVE)
(define-interface CanonicalRetrievalView/1   :owner S13 :seat "V1.7-SCHEMAS.sexp §5" :version "1" :new t
  :signature-owner "static-site.lisp" :consumers (S13 S25) :classification :NORMATIVE)
(define-interface RightsMatrix/1             :owner S25 :seat "V1.7-SCHEMAS.sexp §3 + LAWMAX-LICENSE-POLICY.md" :version "1" :new t
  :signature-owner "license authority" :consumers (S14 S15) :classification :NORMATIVE)
(define-interface LicensePolicy/1            :owner S25 :seat "V1.7-SCHEMAS.sexp §3 + LAWMAX-LICENSE-POLICY.md" :version "1" :new t
  :signature-owner "license authority" :consumers (S14 S15) :classification :NORMATIVE)
(define-interface CitationSupremacyMetric/1  :owner S15 :seat "V1.7-SCHEMAS.sexp §6" :version "1" :new t
  :signature-owner "citation observatory" :consumers (S15) :classification :NORMATIVE)
(define-interface DatasetSnapshot/1          :owner S14 :seat "V1.7-SCHEMAS.sexp §7" :version "1" :new t
  :signature-owner "RA-T signer" :consumers (S14) :classification :NORMATIVE)
(define-interface AnonymizationReceipt/1     :owner S07 :seat "V1.7-SCHEMAS.sexp §8" :version "1" :new t
  :signature-owner "anonymization reviewer" :consumers (S07) :classification :NORMATIVE)
(define-interface NonAuthoritativeTranslation/1 :owner S16 :seat "V1.7-SCHEMAS.sexp §8" :version "1" :new t
  :signature-owner "translation reviewer" :consumers (S13 S16) :classification :NORMATIVE)
(define-interface TenantProfile/1            :owner S26 :seat "V1.7-SCHEMAS.sexp §8" :version "1" :new t :status :INTERFACE_ONLY
  :signature-owner "tenant delegated signer" :consumers () :classification :NORMATIVE :public-dependency nil)
(define-interface RootAuthorityQualification/1 :owner S14 :seat "V1.7-SCHEMAS.sexp §9" :version "1" :new t
  :signature-owner "qualification authority" :consumers (S14 S15) :classification :NORMATIVE)

;; ---- v1.8 contracts (defined ONCE in V1.8-SCHEMAS.sexp; registered here for seat closure — VR registry pass) ----
;; Registry index only: the single definition seat is V1.8-SCHEMAS.sexp (:seat points to the exact section).
;; Each entry carries owner subsystem · definition seat · version · classification · future WP · migration ·
;; rollback. Candidate-only contracts (no committed definition yet) are :status :CANDIDATE_DEFINITION. Private
;; contracts are RESTRICTED with an empty public :consumers and :public-dependency nil.
;; § ROOT-AUTHORITY product state + derived projection (V1.8-SCHEMAS.sexp §2) ----
(define-interface RootAuthorityStatus/1      :owner S14 :seat "V1.8-SCHEMAS.sexp §2" :version "1" :new t
  :signature-owner "root-authority aggregator" :consumers (S14 S15) :classification :NORMATIVE
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "RootAuthorityQualification/1 (v1.7) projection only; no orthogonal product state")
(define-interface RelianceProjection/1       :owner S14 :seat "V1.8-SCHEMAS.sexp §2" :version "1" :new t
  :signature-owner "root-authority aggregator" :consumers (S14 S15) :classification :NORMATIVE
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "no derived projection; status read directly (no deterministic reliance derivation)")
;; § COGNITION clarification lifecycle (V1.8-SCHEMAS.sexp §1) ----
(define-interface ClarifiedInterpretation/1  :owner S04 :seat "V1.8-SCHEMAS.sexp §1" :version "1" :new t
  :signature-owner "public cognition layer" :consumers (S04 S12) :classification :NORMATIVE
  :future-wp WP-08 :migration NEW :rollback "CandidateInterpretation/1 without conditional-cardinality clarification")
(define-interface ClarificationRequest/1     :owner S04 :seat "V1.8-SCHEMAS.sexp §1" :version "1" :new t
  :signature-owner "public cognition layer" :consumers (S04 S12) :classification :NORMATIVE
  :future-wp WP-08 :migration NEW :rollback "single-shot interpretation; no suspend/resume clarification loop")
(define-interface ClarificationResponse/1    :owner S04 :seat "V1.8-SCHEMAS.sexp §1" :version "1" :new t
  :signature-owner "public cognition layer" :consumers (S04 S12) :classification :NORMATIVE
  :future-wp WP-08 :migration NEW :rollback "no clarification response binding; interpretation cannot resume")
;; § RA-EPOCH citation identity + crypto commitments + resolver record (V1.8-SCHEMAS.sexp §3) ----
(define-interface CanonicalCitationURI/1     :owner S25 :seat "V1.8-SCHEMAS.sexp §3" :version "1" :new t
  :signature-owner "resolver / canonical-uris.lisp" :consumers (S25 S13) :classification :NORMATIVE
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "ELI/USC identity used directly; no RA-EPOCH address layer")
(define-interface MultiCommitment/1          :owner S25 :seat "V1.8-SCHEMAS.sexp §3" :version "1" :new t
  :signature-owner "commitment signer" :consumers (S25 S10) :classification :NORMATIVE
  :future-wp WP-06 :migration NEW :rollback "single-hash commitment (pre-RA-EPOCH multi-family anchoring)")
(define-interface ReAnchoringManifest/1      :owner S25 :seat "V1.8-SCHEMAS.sexp §3" :version "1" :new t
  :signature-owner "re-anchoring authority" :consumers (S25 S10) :classification :NORMATIVE
  :future-wp WP-06 :migration NEW :rollback "no re-anchoring; original commitments only")
(define-interface ResolutionRecord/1         :owner S25 :seat "V1.8-SCHEMAS.sexp §3" :version "1" :new t
  :signature-owner "resolver front" :consumers (S25) :classification :NORMATIVE
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "resolver returns ResolverResult/1 only; no persisted resolution record")
;; § RA-CONT continuity + emergency freeze (V1.8-SCHEMAS.sexp §4) ----
(define-interface ContinuityPolicy/1         :owner S11 :seat "V1.8-SCHEMAS.sexp §4" :version "1" :new t
  :signature-owner "continuity authority (separated)" :consumers (S11 S14) :classification :NORMATIVE
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "no versioned continuity policy; single authority")
(define-interface EmergencyFreeze/1          :owner S11 :seat "V1.8-SCHEMAS.sexp §4" :version "1" :new t
  :signature-owner "continuity authority (separated)" :consumers (S11 S14) :classification :NORMATIVE
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "no emergency freeze; standard authority path only")
;; § RA-CORR public correction + restricted forensic record (V1.8-SCHEMAS.sexp §5) ----
(define-interface PublicCorrectionEvent/1    :owner S18 :seat "V1.8-SCHEMAS.sexp §5" :version "1" :new t
  :signature-owner "correction authority" :consumers (S18 S13) :classification :NORMATIVE
  :future-wp WP-12 :migration NEW :rollback "correction via full republish; no privacy-preserving correction event")
(define-interface RestrictedForensicRecord/1 :owner S18 :seat "V1.8-SCHEMAS.sexp §5" :version "1" :new t :status :DEFERRED_PRIVATE
  :signature-owner "restricted forensic custodian" :consumers () :classification :RESTRICTED :public-dependency nil
  :future-wp WP-12 :migration NEW :rollback "no forensic record retained; correction unaudited")
;; § RA-K tiered reproducibility metric (V1.8-SCHEMAS.sexp §6) ----
(define-interface CitationMetricV8/1         :owner S15 :seat "V1.8-SCHEMAS.sexp §6" :version "1" :new t
  :signature-owner "citation observatory" :consumers (S15 S14) :classification :NORMATIVE
  :future-wp WP-13 :migration NEW :rollback "CitationSupremacyMetric/1 (v1.7) only; no tiered assurance class")
;; § RA-SIDE sidecar source profile (capture-only spec) (V1.8-SCHEMAS.sexp §7) ----
(define-interface SidecarSourceProfile/1     :owner S26 :seat "V1.8-SCHEMAS.sexp §7" :version "1" :status :CANDIDATE_DEFINITION
  :signature-owner "sidecar profile custodian" :consumers () :classification :RESTRICTED :public-dependency nil
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "no sidecar profile; spec-only, lawful basis PENDING_LEGAL_VALIDATION")
;; § RA-MARK status vs mark separation (V1.8-SCHEMAS.sexp §8) ----
(define-interface LawmaxStatusVsMark/1       :owner S25 :seat "V1.8-SCHEMAS.sexp §8" :version "1" :new t
  :signature-owner "status authority (mark-separated)" :consumers (S25 S13) :classification :NORMATIVE
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "status and trademark/certification not separated")
;; § FROST / PQ crypto suite registry + recovery epoch (V1.8-SCHEMAS.sexp §9) ----
(define-interface CryptoSuiteRegistry/1      :owner S10 :seat "V1.8-SCHEMAS.sexp §9" :version "1" :new t
  :signature-owner "MLTP root / crypto agility" :consumers (S10 S11) :classification :NORMATIVE
  :future-wp WP-06 :migration NEW :rollback "fixed crypto suite; no agility registry")
(define-interface RecoveryEpoch/1            :owner S11 :seat "V1.8-SCHEMAS.sexp §9" :version "1" :new t
  :signature-owner "security cells (independent domains)" :consumers (S11 S10) :classification :NORMATIVE
  :future-wp WP-06 :migration NEW :rollback "no recovery epoch; manual re-key (emergency = demotion, rejected)")
;; § RA-JUR-NS jurisdiction namespace (candidate) (V1.8-SCHEMAS.sexp RA-JUR-NS seat) ----
(define-interface JurisdictionNamespace/1    :owner S25 :seat "V1.8-SCHEMAS.sexp §RA-JUR-NS" :version "1" :status :CANDIDATE_DEFINITION
  :signature-owner "resolver / canonical-uris.lisp" :consumers (S25) :classification :NORMATIVE
  :future-wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :migration NEW :rollback "GR/EU jurisdiction implicit; no explicit namespace dimension")

(define-invariant :ISR-V6-closure
  "Every contract referenced by any subsystem or schema is DEFINED here exactly once with an owner and a
   definition seat. No adapter-specific (vendor) type is a canonical interface. No interface has two owners.
   Referenced-but-undefined ⇒ architecture-gate FAIL.")
