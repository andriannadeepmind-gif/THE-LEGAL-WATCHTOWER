;;;; LAWMAX OMEGA — SPEC v1.8 FINAL PRE-FREEZE INTEGRATION — MACHINE-READABLE SCHEMAS
;;;; CANDIDATE (NOT FROZEN, NOT QUALIFIED, IMPLEMENTATION BLOCKED). Parent 04cca6ed. Successor of v1.7.
;;;; Frozen v1.4 baseline 88129099 UNCHANGED. SAME CPEI Public Observatory Profile. One architecture.
;;;; Design/spec only. EXISTING canonical types/symbols are REFERENCED (define-reference) with a real
;;;; :canonical-file + :locator the audit OPENS and greps (DFT-03). No second architecture/store/IR/engine/memory.

(spec-version "v1.8-final-pre-freeze-integration"
 :status :CANDIDATE :not-frozen t :not-qualified t :implementation :BLOCKED
 :successor-of "CHANGE-PROPOSAL-v1.7.md" :same-profile "CPEI Public Observatory Profile v1.4"
 :frozen-baseline "88129099" :parent "04cca6ed"
 :integrates "v1.7 10 defects (DFT-01..10) + 7 RA deltas (EPOCH/CONT/CORR/JUR-NS/MARK/K/SIDE) + FROST/PQ precision")

;; ============================ 0. INVARIANTS (carry V7I/RA + v1.8) =============================
(define-invariant :V8I-01-certifies-not-replaces
  "LAWMAX is the Machine Legal Trust Root / citation root / default verification layer via MEASURABLE
   superiority, never self-declaration. State/court bodies remain the issuers of primary acts (carry :RA-I-1).")
(define-invariant :V8I-02-no-mandatory-model
  "No model/ONNX/Python/runtime/cloud/provider is mandatory anywhere in the public build (carry V6I-02). Removing
   every proposer leaves a semantically-equivalent SYMBOLIC_ONLY mandatory path (audit V8-SYM).")
(define-invariant :V8I-03-one-seat
  "Every concept has ONE canonical seat (constitution :no-duplicate). v1.8 EXTENDS existing seats/registries;
   no parallel subsystem, no duplicate store/write-owner/type (audit V8-OWN/V8-XREF).")

;; ============================ 1. COGNITION LIFECYCLE (DFT-06 + DFT-07) =========================
;; ClarifiedInterpretation with CONDITIONAL cardinality; a REAL clarification lifecycle (request/response/
;; suspend/resume/expiry/cancel/terminal); the cognition graph is a typed graph with branch/resume/terminal
;; edges, NOT a linear list carrying a :branch annotation.
(define-closed-enum ClarificationLifecycleState
  (:REQUESTED) (:SUSPENDED) (:RESPONDED) (:RESUMED) (:EXPIRED) (:CANCELLED)
  (:TERMINAL_UNDERDETERMINED) (:TERMINAL_CONFLICTING) (:TERMINAL_ABSTAINED) (:TERMINAL_ERROR))
(define-closed-enum MergeSemanticsV8 (:EXPLICIT_SELECTION) (:EXPLICIT_MERGE) (:ABSTAIN))
(define-record ClarificationRequest/1
  (:request_id :type id) (:version :type semver) (:cognition_instance_ref :type ref)
  (:question_ref :type ref) (:blocking :type (member :true :false))
  (:issued_at :type instant) (:expiry :type instant) (:preserved_alternatives :type (list ref)))
(define-record ClarificationResponse/1
  (:response_id :type id) (:version :type semver) (:request_ref :type ref)
  (:resume_binding_ref :type ref)                    ; binds the EXACT suspended cognition instance
  (:answer_ref :type (or ref null)) (:cancelled :type (member :true :false)) (:responded_at :type instant))
(define-record ClarifiedInterpretation/1             ; DFT-06 — conditional cardinality; no hidden forced winner
  (:interp_id :type id) (:version :type semver) (:decision_ref :type ref)
  (:merge_semantics :type MergeSemanticsV8)
  (:selected_alternative_ref :type (or ref null))    ; ABSTAIN⇒null; EXPLICIT_SELECTION⇒exactly one; EXPLICIT_MERGE⇒null (see merged_result_ref)
  (:merged_result_ref :type (or ref null))           ; required IFF EXPLICIT_MERGE; preserves provenance of ALL inputs
  (:retained_alternatives :type (list ref)) (:input_provenance_refs :type (list ref))
  (:source_anchors :type (list ref)) (:uncertainty :type uncertainty) (:provenance :type ref))
(define-invariant :V8I-CLARIFY-cardinality
  "ClarifiedInterpretation cardinality is conditional on :merge_semantics — :ABSTAIN ⇒ selected_alternative_ref
   null AND merged_result_ref null (no hidden winner); :EXPLICIT_SELECTION ⇒ exactly one selected_alternative_ref
   AND merged_result_ref null; :EXPLICIT_MERGE ⇒ merged_result_ref present preserving ALL input_provenance_refs
   AND selected_alternative_ref null. Audit V8-CLARIFY with a mutation that makes ABSTAIN carry a selection.")
;; the cognition graph as a TYPED GRAPH (nodes + edges), branch/resume/terminal edges declared
(define-cognition-graph cognition-graph-v8
  :nodes (PERCEIVE SEGMENT TOKENIZE MORPH PARSE REFERENCE DISCOURSE ENTITY SEMANTICS PROFILES
          CLARIFY-DECIDE RESOLVE PROMOTE RESULT
          CLARIFY-SUSPEND CLARIFY-RESUME TERM-UNDERDETERMINED TERM-CONFLICTING TERM-ABSTAINED TERM-ERROR)
  :flow-edges ((PERCEIVE SEGMENT) (SEGMENT TOKENIZE) (TOKENIZE MORPH) (MORPH PARSE) (PARSE REFERENCE)
               (REFERENCE DISCOURSE) (DISCOURSE ENTITY) (ENTITY SEMANTICS) (SEMANTICS PROFILES)
               (PROFILES CLARIFY-DECIDE) (CLARIFY-DECIDE RESOLVE) (RESOLVE PROMOTE) (PROMOTE RESULT))
  :branch-edges ((CLARIFY-DECIDE CLARIFY-SUSPEND) (CLARIFY-DECIDE RESOLVE))   ; explicit branch: suspend | passthrough
  :resume-edges ((CLARIFY-SUSPEND CLARIFY-RESUME) (CLARIFY-RESUME RESOLVE))   ; resume binds back to RESOLVE
  :terminal-edges ((CLARIFY-DECIDE TERM-UNDERDETERMINED) (RESOLVE TERM-CONFLICTING) (RESOLVE TERM-ABSTAINED)
                   (PROMOTE TERM-ERROR))
  :terminals (TERM-UNDERDETERMINED TERM-CONFLICTING TERM-ABSTAINED TERM-ERROR RESULT)
  :entry PERCEIVE)
(define-invariant :V8I-COGGRAPH-acyclic-except-resume
  "cognition-graph-v8 is acyclic over flow+branch+terminal edges; the ONLY re-entrant edges are the explicit
   resume edges (SUSPEND→RESUME→RESOLVE), which bind the exact suspended instance (ClarificationResponse
   resume_binding_ref). Every terminal is reachable and has no outgoing flow edge (no orphan terminal); every
   edge is type-compatible. Audit V8-COGLIFE accepts branch/resume/terminal, rejects an injected cycle,
   an orphan terminal, and an incompatible-type edge (3 witnesses).")

;; ============================ 2. ROOT-AUTHORITY PRODUCT STATE + PROJECTION (DFT-10 + §2) ========
;; No scalar stored truth. Orthogonal product state; deterministic DERIVED projection preserving all causes.
(define-closed-enum DimensionState (:OK) (:DEGRADED) (:FAILED) (:UNKNOWN))
(define-record RootAuthorityStatus/1                 ; the ORTHOGONAL product state (stored)
  (:status_id :type id) (:version :type semver)
  (:security :type DimensionState) (:proof_integrity :type DimensionState)   ; proof_integrity MANDATORY + SEPARATE from security
  (:freshness :type DimensionState) (:rights :type DimensionState) (:coverage :type DimensionState)
  (:availability_ops :type DimensionState) (:juris_access :type DimensionState) (:qualification :type DimensionState)
  (:cause_refs :type (list ref))                     ; full simultaneous causes, never collapsed
  (:measured_at :type instant) (:policy_epoch :type semver) (:signature :type sig))
(define-closed-enum RelianceClass (:FULL_RELIANCE) (:ATTRIBUTED_RELIANCE) (:MACHINE_UNVERIFIED) (:WITHHELD))
(define-record RelianceProjection/1                  ; DERIVED, not stored truth
  (:projection_id :type id) (:status_ref :type ref) (:reliance :type RelianceClass)
  (:blocking_dimensions :type (list ref))            ; every failing MANDATORY dimension named (causes preserved)
  (:advisory_dimensions :type (list ref)) (:derived :type (member :true :false)) (:as_of :type instant))
(define-dimension-policy root-authority-dimensions
  (:dimension :security          :class :MANDATORY :failure :WITHHELD          :recovery-evidence "red-team + patch attestation" :authority "security cell")
  (:dimension :proof_integrity   :class :MANDATORY :failure :MACHINE_UNVERIFIED :recovery-evidence "authenticity/provenance/tlog/witness/MLTP re-verify" :authority "MLTP root")
  (:dimension :freshness         :class :MANDATORY :failure :ATTRIBUTED_RELIANCE :recovery-evidence "freshness SLO measurement" :authority "coverage owner")
  (:dimension :rights            :class :MANDATORY :failure :WITHHELD          :recovery-evidence "rights clearance / legal validation" :authority "legal counsel")
  (:dimension :coverage          :class :MANDATORY :failure :ATTRIBUTED_RELIANCE :recovery-evidence "census completeness evidence" :authority "coverage owner")
  (:dimension :availability_ops  :class :ADVISORY  :failure :ATTRIBUTED_RELIANCE :recovery-evidence "DR/SLO drill" :authority "observatory")
  (:dimension :juris_access      :class :MANDATORY :failure :WITHHELD          :recovery-evidence "lawful access + DPA review" :authority "legal counsel")
  (:dimension :qualification     :class :ADVISORY  :failure :ATTRIBUTED_RELIANCE :recovery-evidence "QSR / MISSION auditor sign" :authority "independent auditor"))
(define-invariant :V8I-RASTATUS-product
  "RootAuthorityStatus/1 is an ORTHOGONAL product of 8 typed dimensions; proof_integrity is a SEPARATE MANDATORY
   dimension (authenticity/provenance/tlog/witness/MLTP failures map HERE, never merged into security).
   RelianceProjection/1 is DERIVED, total, deterministic, preserves ALL simultaneous causes, separates
   mandatory/advisory, never turns recovery of one dimension into silent recovery of another, has journaled
   per-dimension recovery, and forbids self-qualification. Audit V8-RASTATUS with a mutation that MERGES
   proof_integrity into security (must fail).")

;; ============================ 3. RA-EPOCH — citation identity + crypto commitments =============
;; CanonicalCitationURI is an ADDRESS over the existing USC Work→Expression→Manifestation→Item, not a 2nd identity.
(define-reference USC-expression :canonical-file "deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md"
  :identity "lawmax/expression/1" :version "1" :locator "lawmax/expression/1")
(define-closed-enum CitationTemporalResolution (:EXPRESSION_VERSION) (:FULLY_DETERMINED_TEMPORAL_SLICE) (:CURRENT_VIEW_QUERY))
(define-record CanonicalCitationURI/1
  (:uri_id :type id) (:version :type semver) (:jurisdiction :type keyword)
  (:source_type :type keyword) (:work_designator :type ref) (:subdivision_anchor :type (or ref null))
  (:expression_ref :type (or ref null))              ; exactly one Expression when canonical
  (:temporal_resolution :type CitationTemporalResolution)
  (:temporal_slice :type (or ref null)) (:timezone :type (or keyword null)) (:calendar :type (or keyword null)))
(define-record ResolutionRecord/1
  (:resolution_id :type id) (:version :type semver) (:uri_ref :type ref)
  (:resolved_expression_ref :type (or ref null)) (:ambiguity_ref :type (or ref null)) (:resolver_receipt_ref :type ref))
(define-record MultiCommitment/1
  (:commitment_id :type id) (:version :type semver)
  (:algorithms :type (list keyword))                 ; >=2 DISTINCT hash families, with domain separation
  (:domain_separation :type ref) (:expression_ref :type ref) (:manifestation_ref :type ref) (:item_ref :type ref)
  (:independent_timestamp :type ref) (:tlog_inclusion :type ref) (:witness_checkpoints :type (list ref)))
(define-record ReAnchoringManifest/1
  (:manifest_id :type id) (:version :type semver) (:prior_commitment_refs :type (list ref))   ; pre-transition, pre-existing
  (:prior_timestamps :type (list ref)) (:prior_witnesses :type (list ref)) (:archival_bytes_ref :type ref)
  (:new_commitment_ref :type ref) (:signature :type sig))
(define-invariant :V8I-EPOCH-one-expression
  "A CanonicalCitationURI resolves to EXACTLY ONE Expression. A bare calendar as-of date is INSUFFICIENT when
   more than one change can occur the same day (temporal_resolution must be :EXPRESSION_VERSION or
   :FULLY_DETERMINED_TEMPORAL_SLICE with timezone/calendar). A URI without version/temporal segment is a
   :CURRENT_VIEW_QUERY, NEVER a canonical citation. Every MultiCommitment carries >=2 distinct hash families with
   domain separation from FIRST publication. Re-anchoring requires pre-existing pre-transition commitments +
   timestamps + witnesses + available archival bytes — a root signature alone is NOT sufficient; the same
   versioned citation URI NEVER resolves to a different Expression. Jurisdiction is a dimension (GR first, EU/
   federation later) with NO change to the identifier grammar.")

;; ============================ 4. RA-CONT — continuity, separated authorities ===================
(define-closed-enum ContinuityRole (:INSTITUTIONAL_AUTHORITY) (:APPROVAL_AUTHORITY) (:KEY_SHARE_CUSTODY) (:TECHNICAL_SIGNING))
(define-record ContinuityPolicy/1                    ; versioned; NO arbitrary frozen constants
  (:policy_id :type id) (:version :type semver) (:council_size :type ref) (:threshold :type ref)
  (:separation_of_duties :type ref) (:no_single_succession_authority :type (member :true :false))
  (:incapacity_death_evidence :type ref) (:time_locked_succession :type ref) (:independent_witnesses :type ref)
  (:collusion_capture_controls :type ref) (:recovery_drills :type ref) (:policy_epoch :type semver) (:supersession :type (or ref null)))
(define-record EmergencyFreeze/1
  (:freeze_id :type id) (:version :type semver) (:invoked_by :type ref) (:scope :type (member :PUBLISH_FREEZE))
  (:time_limited_until :type instant)                ; one person may ONLY invoke a temporary, time-limited freeze
  (:extension_requires_quorum :type (member :true)) (:thaw_requires_quorum :type (member :true)) (:signature :type sig))
(define-invariant :V8I-CONT-separated
  "Institutional authority, approval authority, key/share custody and technical signing are SEPARATE
   (ContinuityRole). Custodians NEVER gain institutional or approval authority. Council size / threshold /
   durations are versioned ContinuityPolicy fields, NOT frozen universal constants; separation of duties is
   mandatory; there is no single point of succession authority. One person may invoke ONLY a temporary
   time-limited EmergencyFreeze (PUBLISH_FREEZE); extension or thaw REQUIRES quorum (no permanent single-custodian
   denial-of-service). A veto/dead-man control names exactly who may exercise it, when it holds, how it is
   revoked, and death/incapacity behaviour. The specific people, numbers and legal instruments are EXTERNAL
   governance gates (PENDING_LEGAL_VALIDATION).")

;; ============================ 5. RA-CORR — public correction with privacy ======================
(define-record PublicCorrectionEvent/1
  (:event_id :type id) (:version :type semver) (:subject_citation_ref :type ref)
  (:status :type (member :REPLACED :WITHDRAWN)) (:replacement_ref :type (or ref null))
  (:no_republished_content :type (member :true)) (:no_personal_data_in_tombstone :type (member :true))
  (:citation_resolvable :type (member :true)) (:signature :type sig))
(define-record RestrictedForensicRecord/1 :status :DEFERRED_PRIVATE :public-dependency nil
  (:record_id :type id) (:version :type semver) (:access_policy :type ref) (:retention :type ref)
  (:legal_hold :type ref) (:deletion_policy :type ref) (:signature :type sig))
(define-invariant :V8I-CORR-privacy
  "A PublicCorrectionEvent does NOT re-publish the problematic content, carries NO personal data in the tombstone,
   points to replacement/withdrawal status, and stays citation-resolvable. Restricted forensic evidence has its
   own access/retention/legal-hold/deletion. Crypto-shredding / salted commitments are technical capabilities
   with PENDING_LEGAL_VALIDATION, NOT automatic legal compliance; digests may themselves be sensitive/correlatable.
   The chain verifies with `content unavailable/withdrawn` WITHOUT retaining withdrawn content in the public
   journal.")

;; ============================ 6. RA-K — tiered reproducibility ==================================
(define-closed-enum MetricAssuranceClass (:PUBLICLY_REPRODUCIBLE) (:INDEPENDENTLY_AUDITED_RESTRICTED) (:AGGREGATE_ONLY) (:UNQUALIFIED))
(define-closed-enum ReproTier (:T1_PUBLIC) (:T2_DELAYED_PUBLIC) (:T3_SEALED_RESTRICTED))
(define-record CitationMetricV8/1                    ; supersedes CitationSupremacyMetric raw-publication invariant
  (:metric_id :type id) (:version :type semver) (:panel_ref :type ref) (:tier :type ReproTier)
  (:assurance_class :type MetricAssuranceClass) (:redistribution_forbidden :type (member :true :false))
  (:public_methodology_ref :type ref) (:commitments_ref :type ref) (:aggregate_derivation_ref :type (or ref null))
  (:independent_audit_ref :type (or ref null)) (:no_citation_exposed :type (member :true :false)) (:provenance :type ref))
(define-invariant :V8I-RA-K-tiered
  "Reproducibility is TIERED (T1 public methodology/code/sampling/commitments/aggregate; T2 delayed-public retired
   datasets where privacy/licensing/contracts allow; T3 sealed live holdouts + restricted evidence for
   independent auditors). A metric is :PUBLICLY_REPRODUCIBLE ONLY when its data can be published + reproduced
   publicly; otherwise the highest attainable class is :INDEPENDENTLY_AUDITED_RESTRICTED / :AGGREGATE_ONLY from
   INDEPENDENT audit, never self-claim. Hidden holdouts are not revealed before retirement; redistribution-forbidden
   is stated explicitly. Provider exposing no citation ⇒ UNKNOWN, never 0. Metrics are never legal correctness.")

;; ============================ 7. RA-SIDE — sidecar profile (capture-only spec) =================
(define-record SidecarSourceProfile/1 :status :SPECIFICATION_ONLY :creator-gated t :public-dependency nil
  (:profile_id :type id) (:version :type semver) (:source_classification :type ref)
  (:lawful_basis_ref :type ref)                      ; validated per source/controller/purpose — PENDING_LEGAL_VALIDATION
  (:data_classification :type (member :PERSONAL :SPECIAL :CRIMINAL :NON_PERSONAL :UNKNOWN))
  (:minimization :type ref) (:access_class :type ref) (:retention :type ref)
  (:correction_deletion_legal_hold :type ref) (:encryption :type ref) (:rights_licensing_state :type ref)
  (:fail_closed :type (member :true)))
(define-invariant :V8I-SIDE-gdpr-honest
  "SidecarSourceProfile is SPECIFICATION-ONLY and creator-gated (not implemented this pass; no exception to
   'updated Implementation Book before code'). Article 6(1)(f) and Article 89 are NOT locked as universal lawful
   basis — the real basis is per source/controller/purpose and PENDING_LEGAL_VALIDATION. NO source, not even the
   Government Gazette (ΦΕΚ), is classed 'zero GDPR weight'.")

;; ============================ 8. RA-MARK — status vs mark separation ============================
(define-record LawmaxStatusVsMark/1
  (:sep_id :type id) (:version :type semver)
  (:cryptographic_status_ref :type ref)              ; technical validity — independent of any visual logo
  (:trademark :type (or ref null)) (:certification_mark :type (or ref null)) (:attribution_text :type ref)
  (:cc_by_attribution :type ref) (:enterprise_contractual :type (or ref null)))
(define-invariant :V8I-MARK-separated
  "Cryptographically-verifiable LAWMAX status, trademark, certification mark, attribution text, CC BY attribution
   and enterprise contractual obligations are SEPARATE. Technical validity does NOT depend on a visual logo.
   Trademark/certification protection is an EXTERNAL legal gate. No extra restriction is introduced inside the
   open (CC BY) licence (carry :V7I-RA-L-no-unlicensed).")

;; ============================ 9. FROST / PQ — precise claims only ===============================
(define-closed-enum CryptoMaturity (:FROZEN) (:PENDING_IMPLEMENTATION_REVIEW))
(define-record CryptoSuiteRegistry/1
  (:registry_id :type id) (:version :type semver) (:suites :type (list ref)) (:ceremony_roles :type ref)
  (:policy_epochs :type (list ref)) (:separation_of_duties :type ref) (:witness_delay :type ref)
  (:downgrade_resistance :type ref) (:recovery_procedure :type ref)
  (:frost_dkg_maturity :type CryptoMaturity) (:hsm_maturity :type CryptoMaturity)
  (:signature :type sig))
(define-record RecoveryEpoch/1                        ; emergency transition = NEW monotonic epoch, NOT demotion
  (:epoch_id :type id) (:epoch_number :type ref) (:supersedes_epoch :type ref)
  (:algorithm_retirement_reason :type ref) (:precommitted_recovery_policy :type ref) (:governance_quorum :type ref)
  (:surviving_independent_signatures :type (list ref)) (:public_delay :type ref)
  (:tlog_witness_evidence :type ref) (:signature :type sig))
(define-invariant :V8I-FROST-precise
  "FROZEN: versioned suite registry, ceremony roles, policy epochs, separation of duties, witness/delay,
   downgrade resistance, recovery procedure. NOT frozen (explicit): FROST key-generation/DKG is OUTSIDE RFC 9591;
   independent n-of-m ML-DSA signatures are NOT threshold ML-DSA; DKG/share-refresh/HSM maturity is
   :PENDING_IMPLEMENTATION_REVIEW; no homemade cryptography. An emergency transition is NOT an 'epoch demotion' —
   it creates a NEW monotonically-increasing RECOVERY_EPOCH N+1 (reasoned algorithm retirement, pre-committed
   recovery policy, governance quorum, surviving independent signatures, public delay, tlog/witness evidence). The
   verifier NEVER silently reverts to an older epoch nor accepts a silent single-algorithm fallback.")

;; ============================ 10. CAPABILITY→SEAT CLOSURE (DFT-05 corrected) ====================
;; Two seat kinds: :CODE (real file + real defpackage + real symbol, audit greps source) and :DOCUMENT (real
;; normative .md/.sexp + section, NO pseudo-package). The audit OPENS the file and verifies existence (V8-CAP).
(define-capability-seat :capability :RESOLVE_IDENTIFIER :kind :CODE :file "source/canonical-uris.lisp" :package "orchestrator.uris" :symbol "get-eli-law-prefix" :subsystem S25 :requirement RA-I :test RA-Q-RESOLVE)
(define-capability-seat :capability :PUBLIC_RETRIEVAL   :kind :CODE :file "source/static-site.lisp"    :package "orchestrator.static-site" :symbol "emit-corpus-site" :subsystem S13 :requirement RA-R :test RA-Q-RETRIEVE)
(define-capability-seat :capability :CITATION_MEASURE   :kind :CODE :file "source/ai-citation-strategy.lisp" :package "orchestrator.ai-citation" :symbol "export-citation-metrics" :subsystem S15 :requirement RA-K :test RA-Q-CITE)
(define-capability-seat :capability :DATASET_DISTRIBUTE :kind :CODE :file "source/ai-corpus-dump.lisp"  :package "orchestrator.corpus" :symbol "ai-corpus-dump" :subsystem S14 :requirement RA-T :test RA-Q-DATASET)
(define-capability-seat :capability :JURIS_RATIO        :kind :CODE :file "source/legal-decisions.lisp" :package "orchestrator.decisions" :symbol "decision-ratio" :subsystem S07 :requirement RA-J :test RA-Q-JURIS)
(define-capability-seat :capability :RIGHTS_LICENSE     :kind :DOCUMENT :file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/LAWMAX-LICENSE-POLICY.md" :section "RightsMatrix/1" :subsystem S25 :requirement RA-L :test RA-Q-LICENSE)
(define-capability-seat :capability :EXPRESSION_TRANSLATE :kind :DOCUMENT :file "deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md" :section "lawmax/expression/1" :subsystem S16 :requirement RA-E :test RA-Q-TRANSLATE)
(define-invariant :V8I-CAP-real
  "Every capability names a REAL seat the audit opens: :CODE ⇒ file (source/*.lisp) + real defpackage + real
   defun/defmethod/defclass/defstruct symbol; :DOCUMENT ⇒ real normative file + a section string that occurs in
   it. NO pseudo-package is used for a Markdown/document seat (DFT-05). NO_PERFECT_UNDERSTANDING_CLAIM is an
   invariant boundary, never a capability. Audit V8-CAP greps the real files with a bogus-symbol mutation.")

;; ============================ 11. PUBLIC EDGE FAMILIES + CLOSURE ROOTS (DFT-01) =================
;; The public/private transitive closure follows EVERY declared edge family; each family has its OWN mutation
;; witness (audit V8-PUBPRIV-<family>). A private target reachable via ANY family fails.
(define-ra-closure-roots
  (public-roots (LegalIR/1 MemoryEvent/1 TrustBundle/1 CognitionResult/1 CanonicalRetrievalView/1
                 ResolverResult/1 CitationMetricV8/1 DatasetSnapshot/1 RightsMatrix/1 RootAuthorityStatus/1))
  (private-forbidden (TenantProfile/1 PrivateMemoryEvent/1 PrivateMatterProfile/1 RealTimeAssistance/1
                      EmbodimentInterfaces/1 RestrictedForensicRecord/1 SidecarSourceProfile/1))
  (edge-families (field-type ref-target interface-io subsystem-dep store-owner-writer api-mcp-schema
                  publication declassification)))
(define-public-edge :family field-type       :from CanonicalCitationURI/1 :to CitationTemporalResolution)
(define-public-edge :family ref-target        :from ResolutionRecord/1 :to CanonicalCitationURI/1)
(define-public-edge :family interface-io      :from S13 :to CanonicalRetrievalView/1)
(define-public-edge :family subsystem-dep     :from S25 :to S13)
(define-public-edge :family store-owner-writer :from "static-site" :to "WP-12 static-site.lisp")
(define-public-edge :family api-mcp-schema    :from "mcp:get_article" :to CanonicalRetrievalView/1)
(define-public-edge :family publication       :from CognitionResult/1 :to CanonicalRetrievalView/1)
(define-public-edge :family declassification  :from DeclassificationReceipt/1 :to MemoryEvent/1)
(define-invariant :V8I-PUBPRIV-all-families
  "The public dependency closure follows ALL edge families (field-type, ref-target, interface-io, subsystem-dep,
   store-owner-writer, api-mcp-schema, publication, declassification) and contains ZERO :DEFERRED_PRIVATE /
   :INTERFACE_ONLY / :SPECIFICATION_ONLY record and zero private-bearing enum. Audit V8-PUBPRIV runs an
   INDEPENDENT mutation witness PER edge family (inject a private target via that family ⇒ closure flips). No
   universal-closure claim is made for a family that is not checked.")

;; ============================ 12. STORE / WRITE-AUTHORITY (DFT-04 universal) ====================
(define-write-authority :store "journal"               :owner "WP-03 journal.lisp"                :write-authority "write-authority.lisp" :writers 1)
(define-write-authority :store "memory"                :owner "memory.lisp"                       :write-authority "write-authority.lisp" :writers 1)
(define-write-authority :store "legal-ir"              :owner "WP-03 legal-ast.lisp"              :write-authority "write-authority.lisp" :writers 1)
(define-write-authority :store "trust-bundle"          :owner "WP-06 MLTP-root"                   :write-authority "MLTP-threshold-custody" :writers 1)
(define-write-authority :store "coverage-ledger"       :owner "WP-01 coverage-ledger.lisp[design-target]" :write-authority "coverage-owner" :writers 1)
(define-write-authority :store "citation-observatory"  :owner "WP-13 citation-authority.lisp"     :write-authority "observatory-collector" :writers 1)
(define-write-authority :store "dataset-distribution"  :owner "WP-11 ai-corpus-dump.lisp"         :write-authority "RA-T-signer" :writers 1)
(define-write-authority :store "static-site"           :owner "WP-12 static-site.lisp"            :write-authority "none" :writers 0 :read-only t)
(define-write-authority :store "resolver-dataset"      :owner "RA-S25 canonical-uris.lisp"        :write-authority "none" :writers 0 :read-only t)
(define-write-authority :store "tenant-profile"        :owner "RA-S26 [interface-only]"           :write-authority "none" :writers 0 :read-only t)
(define-invariant :V8I-OWN-universal
  "Every store id is UNIQUE with exactly one owner and, where writes occur, exactly one canonical writer;
   read-only projections have 0 writers; owners agree with the subsystem/interface registries. A duplicate store
   id with a different owner or writer FAILS. Audit V8-OWN (mutation: duplicate store with a second owner).")

;; ============================ 13. WP RECONCILIATION (DFT-02, grep-able evidence) ================
;; Each :evidence is a string the audit greps INSIDE the named WP-NN.md (real file open). Unowned ⇒ FUTURE.
(define-wp-reconciliation
  (:concept COGNITION_DAG            :wp WP-08 :file "WP-08.md" :evidence "Public Legal Discernment")
  (:concept NEURAL_PROPOSER          :wp WP-07 :file "WP-07.md" :evidence "neural runtime")
  (:concept SECURE_INGRESS           :wp WP-02 :file "WP-02.md" :evidence "Secure Semantic Ingress")
  (:concept LEGAL_IR                 :wp WP-03 :file "WP-03.md" :evidence "Legal IR")
  (:concept TRUST_BUNDLE             :wp WP-06 :file "WP-06.md" :evidence "TrustBundle")
  (:concept PUBLIC_PRIVATE_BOUNDARY  :wp WP-12 :file "WP-12.md" :evidence "public")
  (:concept PROOF_CARRYING_QUERY     :wp WP-11 :file "WP-11.md" :evidence "proof-carrying")
  (:concept ECLI                     :wp WP-09 :file "WP-09.md" :evidence "ECLI")
  (:concept CITATION_MEASUREMENT     :wp WP-13 :file "WP-13.md" :evidence "citation observatory")
  (:concept DATASET_DISTRIBUTION     :wp WP-11 :file "WP-11.md" :evidence "delta feeds")
  (:concept PROVIDER_REGISTRY        :wp WP-14 :file "WP-14.md" :evidence "provider")
  (:concept MEMORY_KERNEL            :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :file "none" :evidence "no WP owns a memory kernel")
  (:concept UNIFIED_RESOLVER         :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :file "none" :evidence "CELEX in zero packets")
  (:concept LICENSE_RIGHTS_MATRIX    :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :file "none" :evidence "only decision gates")
  (:concept TENANT_PROFILES          :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :file "none" :evidence "no tenant-profile abstraction")
  (:concept ROOT_AUTHORITY_FLYWHEEL  :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :file "none" :evidence "NEW_GAP"))
(define-invariant :V8I-WP-real
  "V8-WP OPENS each named WP-NN.md and confirms the :evidence string occurs in it; MEMORY_KERNEL stays
   FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED (never WP-11). Mutation: an :evidence string absent from its WP
   file, or memory mapped to WP-11, fails.")

;; ============================ 14. SYMBOLIC-ONLY PATH (DFT-08, exact mutation count) =============
(define-pipeline symbolic-only-path
  :entry ACQUIRE :exit PUBLISH
  :nodes (ACQUIRE CENSUS ADMIT IR REASON COMPILE PROOF PUBLISH)
  :mandatory-nodes (ACQUIRE CENSUS IR COMPILE PROOF PUBLISH)
  :edges ((ACQUIRE CENSUS) (ACQUIRE ADMIT) (ADMIT IR) (IR REASON) (IR COMPILE) (REASON PROOF) (COMPILE PROOF) (PROOF PUBLISH))
  :symbolic-only-nodes (ACQUIRE CENSUS ADMIT IR REASON COMPILE PROOF PUBLISH)
  :proposer-optional-nodes (ADMIT IR REASON)
  :proposer-mandatory-nodes ()
  :mutation-count 4
  :mutations (broken-edge unreachable-mandatory-stage mandatory-model-node proposer-removal-inequivalence))
(define-invariant :V8I-SYM-exact
  "V8-SYM proves: all mandatory-nodes reachable entry→exit; every edge node-type compatible; proposer-mandatory
   empty; and after removing ALL proposer contributions the mandatory path is SEMANTICALLY EQUIVALENT (same
   mandatory node sequence ACQUIRE→CENSUS→IR→COMPILE→PROOF→PUBLISH still connected). EXACTLY 4 real mutation
   tests (broken-edge, unreachable-mandatory-stage, mandatory-model-node, proposer-removal-inequivalence) — the
   prior '5/3/2' ambiguity is retired.")

;; ============================ 15. CANONICAL REFERENCES (DFT-03, real file+locator) ==============
;; Each reference names a real :canonical-file and a :locator string that MUST occur in it (audit opens+greps).
(define-reference LegalIR/1 :canonical-file "deployment/LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md" :identity "lawmax/legal-ir/1" :version "1" :locator "Counterproof")
(define-reference TrustBundle/1 :canonical-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md" :identity "lawmax/trust-bundle/1" :version "1" :locator "TrustBundle")
(define-reference MemoryEvent/1 :canonical-file "source/memory.lisp" :identity "lawmax/memory-event/1" :version "1" :locator "record-episode")
(define-reference CognitionResult/1 :canonical-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.6-SCHEMAS.sexp" :identity "lawmax/cognition-result/1" :version "1" :locator "CognitionResult/1")
(define-reference DeclassificationReceipt/1 :canonical-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.6-SCHEMAS.sexp" :identity "lawmax/declassification-receipt/1" :version "1" :locator "DeclassificationReceipt/1")
(define-reference ResolverResult/1 :canonical-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-SCHEMAS.sexp" :identity "lawmax/resolver-result/1" :version "1" :locator "ResolverResult/1")
(define-reference DatasetSnapshot/1 :canonical-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-SCHEMAS.sexp" :identity "lawmax/dataset-snapshot/1" :version "1" :locator "DatasetSnapshot/1")
(define-reference RightsMatrix/1 :canonical-file "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-SCHEMAS.sexp" :identity "lawmax/rights-matrix/1" :version "1" :locator "RightsMatrix/1")
(define-invariant :V8I-XREF-real
  "V8-XREF OPENS each :canonical-file and confirms the :locator string occurs in it (the type/symbol really
   exists), plus a declared :identity and :version. A nonexistent file, or a locator absent from it, FAILS
   (mutation: point a reference at a nonexistent file).")
