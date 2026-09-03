;;;; LAWMAX OMEGA — SPEC v1.7 NO-LOSS ROOT-AUTHORITY & PUBLIC COGNITION — MACHINE-READABLE SCHEMAS
;;;; CANDIDATE (NOT FROZEN, NOT QUALIFIED, IMPLEMENTATION BLOCKED). Parent f05f5514. Successor of v1.6.
;;;; Frozen v1.4 baseline 88129099 UNCHANGED. SAME CPEI Public Observatory Profile. One architecture.
;;;; Design-only. Data, not code. EXISTING canonical types are REFERENCED (define-reference), never redefined.
;;;; No new architecture / second canonical store / second Legal IR / second reasoning engine / second memory.

(spec-version "v1.7-no-loss-root-authority-public-cognition"
 :status :CANDIDATE :not-frozen t :not-qualified t :implementation :BLOCKED
 :successor-of "CHANGE-PROPOSAL-v1.6.md" :same-profile "CPEI Public Observatory Profile v1.4"
 :frozen-baseline "88129099" :parent "f05f5514"
 :integrates "all valid v1.4/v1.5/v1.6 seats; D1/D2/D3/C1 + repairs preserved; closes C-1..C-11")

;; ============================ 0. ROOT-AUTHORITY INVARIANTS (RA-*) ==============================
(define-invariant :RA-I-1-root-authority-certifies-not-replaces
  "LAWMAX certifies identity/provenance/temporality/coding/completeness/relations/interpretation/machine-trust
   of a legal object. The act of enactment belongs to the real issuer. LAWMAX NEVER replaces the issuer.")
(define-invariant :RA-I-2-citation-primacy-no-false-certainty
  "Citation primacy is pursued via superior representation/coverage/freshness/proofs/resolver/integration —
   NEVER via false certainty, hidden UNKNOWN, provisional-as-verified, source alteration or reduced provenance.")
(define-invariant :RA-I-3-no-mandatory-model
  "No model/ONNX/Python/runtime/cloud/provider is mandatory anywhere in the public build (carries V6I-02).
   Removing every proposer leaves a functional SYMBOLIC_ONLY path. Memory and identities belong to LAWMAX.")
(define-invariant :RA-I-4-public-independent-of-private
  "The Public Profile has ZERO dependency on private/real-time/embodiment records (transitive, audit V7S-PUBPRIV).
   Private consumes signed public releases / proof-carrying interfaces only.")
(define-invariant :RA-I-5-one-seat-per-concept
  "Every concept has ONE canonical seat (LAWMAX-ARCHITECTURE-CONSTITUTION.sexp :no-duplicate). RA-* deltas EXTEND
   existing seats; a second store/emitter/registry/ledger for an already-seated concept is REJECTED.")

;; ============================ 1. TYPE-CORRECT COGNITION DAG (C-2) ==============================
;; Information-preserving DAG. Distinct in/out types per stage; source anchors + provenance on EVERY stage;
;; alternative identity + uncertainty never dropped; explicit branch/merge; no silent forced winner; promotion
;; binds the EXACT semantic candidate. Reused v1.6 records are REFERENCED; new intermediate types defined here.
(define-reference PerceptionEnvelope/1 :canonical "V1.6-SCHEMAS.sexp §2" :identity "lawmax/perception-envelope/1" :version "1")
(define-reference MorphLattice/1 :canonical "V1.6-SCHEMAS.sexp §3" :identity "lawmax/morph-lattice/1" :version "1")
(define-reference PackedParseForest/1 :canonical "V1.6-SCHEMAS.sexp §3" :identity "lawmax/packed-parse-forest/1" :version "1")
(define-reference DiscourseState/1 :canonical "V1.6-SCHEMAS.sexp §3" :identity "lawmax/discourse-state/1" :version "1")
(define-reference PromotionEvidence/1 :canonical "V1.6-SCHEMAS.sexp §3" :identity "lawmax/promotion-evidence/1" :version "1")
(define-reference CognitionResult/1 :canonical "V1.6-SCHEMAS.sexp §3" :identity "lawmax/cognition-result/1" :version "1")
(define-closed-enum CognitionErrorV7                ; typed failure — never a guess, never a silent forced winner
  (:UNNORMALIZABLE) (:UNSEGMENTABLE) (:UNTOKENIZABLE) (:NO_MORPH) (:NO_PARSE) (:UNRESOLVED_REFERENCE)
  (:DISCOURSE_GAP) (:UNKNOWN_ENTITY) (:NO_ALTERNATIVE) (:INTERPRETIVE_DIVERGENCE) (:CLARIFICATION_REQUIRED)
  (:UNDERDETERMINED) (:CONFLICTING) (:INSUFFICIENT_EVIDENCE) (:PROMOTION_REJECTED))
;; new intermediate typed I/O records (each carries source_anchors + provenance; alt/uncertainty where present)
(define-record NormalizedDocument/1
  (:doc_id :type id) (:version :type semver) (:input_ref :type ref)
  (:normalized_text_ref :type ref) (:source_anchors :type (list ref)) (:provenance :type ref))
(define-record SegmentSequence/1
  (:seq_id :type id) (:version :type semver) (:doc_ref :type ref)
  (:segments :type (list ref)) (:source_anchors :type (list ref)) (:provenance :type ref))
(define-record TokenStream/1
  (:stream_id :type id) (:version :type semver) (:segment_ref :type ref)
  (:tokens :type (list ref)) (:reversible :type (member :true :false)) (:source_anchors :type (list ref)) (:provenance :type ref))
(define-record ReferenceGraph/1                     ; coreference + anaphora resolved (supersedes v1.6 CoreferenceRecord/1 singular)
  (:graph_id :type id) (:version :type semver) (:parse_ref :type ref)
  (:mentions :type (list ref)) (:coref_edges :type (list ref))
  (:source_anchors :type (list ref)) (:uncertainty :type uncertainty) (:provenance :type ref))
(define-record LegalEntityGraph/1
  (:graph_id :type id) (:version :type semver) (:discourse_ref :type ref)
  (:entities :type (list ref)) (:citations :type (list ref)) (:terms_of_art :type (list ref))
  (:source_anchors :type (list ref)) (:uncertainty :type uncertainty) (:provenance :type ref))
(define-record LegalSemanticAlternativeSet/1        ; the SET (alternative identity preserved), not one winner
  (:set_id :type id) (:version :type semver) (:entity_graph_ref :type ref)
  (:alternatives :type (list ref))                  ; each alternative has stable identity + uncertainty
  (:source_anchors :type (list ref)) (:uncertainty :type uncertainty) (:provenance :type ref))
(define-record InterpretiveProfileEvaluation/1      ; evaluates the set under InterpretiveProfile/1 (v1.5 C1) — no forced winner
  (:eval_id :type id) (:version :type semver) (:alternative_set_ref :type ref) (:profile_ref :type ref)
  (:ranked_alternatives :type (list ref)) (:no_forced_winner :type (member :true :false))
  (:source_anchors :type (list ref)) (:uncertainty :type uncertainty) (:provenance :type ref))
(define-record ClarificationDecision/1              ; explicit branch: passthrough OR clarification-required
  (:decision_id :type id) (:version :type semver) (:evaluation_ref :type ref)
  (:branch :type (member :NO_CLARIFICATION_PASSTHROUGH :CLARIFICATION_REQUIRED))
  (:question_ref :type (or ref null)) (:preserved_alternatives :type (list ref))
  (:source_anchors :type (list ref)) (:uncertainty :type uncertainty) (:provenance :type ref))
(define-record ClarifiedInterpretation/1            ; merged/selected WITHOUT silent forcing; retains losing alternatives by ref
  (:interp_id :type id) (:version :type semver) (:decision_ref :type ref)
  (:selected_alternative_ref :type ref) (:retained_alternatives :type (list ref))
  (:merge_semantics :type (member :EXPLICIT_SELECTION :EXPLICIT_MERGE :ABSTAIN))
  (:source_anchors :type (list ref)) (:uncertainty :type uncertainty) (:provenance :type ref))
(define-construction-order cognition-stage-dag-v7
  (:stage COG7-01-PERCEIVE     :in PerceptionEnvelope/1            :out NormalizedDocument/1            :seat "greek-nlp-core.lisp"                    :symbolic-only t :preserves (anchors provenance))
  (:stage COG7-02-SEGMENT      :in NormalizedDocument/1            :out SegmentSequence/1               :seat "greek-nlp-core.lisp"                    :symbolic-only t :preserves (anchors provenance))
  (:stage COG7-03-TOKENIZE     :in SegmentSequence/1               :out TokenStream/1                   :seat "greek-tokenizer-advanced.lisp"          :symbolic-only t :preserves (anchors provenance))
  (:stage COG7-04-MORPH        :in TokenStream/1                   :out MorphLattice/1                  :seat "greek-lemmatizer.lisp"                  :symbolic-only t :preserves (anchors provenance))
  (:stage COG7-05-PARSE        :in MorphLattice/1                  :out PackedParseForest/1             :seat "legal-casegrammar.lisp[general]"        :symbolic-only t :preserves (anchors provenance))
  (:stage COG7-06-REFERENCE    :in PackedParseForest/1             :out ReferenceGraph/1                :seat "greek-nlp-core.lisp (EXTEND)"           :symbolic-only t :preserves (anchors provenance uncertainty))
  (:stage COG7-07-DISCOURSE    :in ReferenceGraph/1                :out DiscourseState/1                :seat "greek-nlp-core.lisp (EXTEND)"           :symbolic-only t :preserves (anchors provenance uncertainty))
  (:stage COG7-08-ENTITY       :in DiscourseState/1                :out LegalEntityGraph/1              :seat "greek-legislation-ontology.lisp"        :symbolic-only t :preserves (anchors provenance uncertainty))
  (:stage COG7-09-SEMANTICS    :in LegalEntityGraph/1              :out LegalSemanticAlternativeSet/1   :seat "legal-deontic.lisp + legal-event-calculus.lisp" :symbolic-only t :preserves (anchors provenance alternatives uncertainty))
  (:stage COG7-10-PROFILES     :in LegalSemanticAlternativeSet/1   :out InterpretiveProfileEvaluation/1 :seat "InterpretiveProfile/1 (v1.5 C1)"        :symbolic-only t :preserves (anchors provenance alternatives uncertainty) :no-forced-winner t)
  (:stage COG7-11-CLARIFY      :in InterpretiveProfileEvaluation/1 :out ClarificationDecision/1         :seat "legal-dialectic.lisp + condition/restart" :symbolic-only t :preserves (anchors provenance alternatives uncertainty) :branch (:NO_CLARIFICATION_PASSTHROUGH :CLARIFICATION_REQUIRED))
  (:stage COG7-12-RESOLVE      :in ClarificationDecision/1         :out ClarifiedInterpretation/1       :seat "legal-dialectic.lisp"                   :symbolic-only t :preserves (anchors provenance alternatives uncertainty) :no-forced-winner t)
  (:stage COG7-13-PROMOTE      :in ClarifiedInterpretation/1       :out PromotionEvidence/1             :seat "legal-extraction-verify.lisp + legal-ast.lisp" :symbolic-only t :preserves (anchors provenance) :binds-exact-candidate t)
  (:stage COG7-14-RESULT       :in PromotionEvidence/1             :out CognitionResult/1               :seat "legal-qa.lisp + citation/1"             :symbolic-only t :preserves (anchors provenance)))
(define-invariant :V7I-COG-info-preserving
  "cognition-stage-dag-v7 is information-preserving: (a) each stage :out type equals the next stage :in type
   (typed, connected); (b) every stage preserves source anchors + provenance; (c) alternative identity and
   uncertainty are preserved from COG7-09 through COG7-12 and never silently dropped; (d) COG7-11 is an EXPLICIT
   branch (passthrough | clarification-required); (e) no silent forced winner (COG7-10/12 :no-forced-winner t);
   (f) COG7-13 binds the EXACT ClarifiedInterpretation candidate (:binds-exact-candidate t). Audit V7S-COGDAG
   + V7S-INFO, each with an injected-mutation self-test.")

;; ============================ 2. PUBLIC-SYSTEM MEMORY PRIVACY SCOPES (C-9) =====================
;; Replaces the vague (:public :user :ephemeral) with typed scopes carrying per-scope policy. ONE memory seat.
(define-closed-enum MemoryScopeV7 (:PUBLIC_CANONICAL) (:SERVICE_INTERNAL) (:USER_PRIVATE) (:EPHEMERAL))
(define-record MemoryScopePolicy/1
  (:scope :type MemoryScopeV7) (:version :type semver)
  (:encryption :type ref) (:access_control :type ref) (:retention :type ref)
  (:publication :type (member :ALLOWED :FORBIDDEN)) (:deletion :type ref) (:audit :type ref)
  (:declassification :type (or ref null)))          ; only USER_PRIVATE/SERVICE_INTERNAL may carry a gateway ref
(define-invariant :V7I-MEM-user-private-no-auto-public
  "USER_PRIVATE (and SERVICE_INTERNAL) memory is NEVER promoted to PUBLIC_CANONICAL without an explicit, valid
   consent/DeclassificationReceipt/1. PUBLIC_CANONICAL :publication :ALLOWED; USER_PRIVATE :publication :FORBIDDEN
   absent a receipt. Public memory carries no client/matter/private datum (carries V6I-MEM-public-base-clean).")
(define-invariant :V7I-MEM-one-owner
  "Memory kernel has ONE canonical seat (source/memory.lisp, EXTEND) and no owning Work-Packet yet ⇒ owner =
   FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED (C-1). No second memory store; knowledge/ontology and the
   bitemporal temporal graph are distinct seats, not memory.")

;; ============================ 3. RA-L RIGHTS / LICENSE (LAWMAX-LICENSE-POLICY.md) ==============
(define-closed-enum ArtifactRightsClass
  (:OFFICIAL_SOURCE_TEXT) (:LAWMAX_CONSOLIDATION_CODIFICATION) (:METADATA_IDENTITY_GRAPH)
  (:HEADNOTE_SUMMARY_TRANSLATION) (:PROOF_RECEIPT) (:DATASET_SNAPSHOT) (:SPECIFICATION_SCHEMA) (:SOFTWARE))
(define-closed-enum RightsDisposition (:GRANTED) (:GRANTED_WITH_CONDITION) (:DENIED) (:RIGHTS_UNKNOWN))
(define-closed-enum LegalReviewState (:UNREVIEWED) (:IN_REVIEW) (:LEGALLY_VALIDATED) (:DISPUTED) (:WITHDRAWN))
(define-record RightsMatrix/1
  (:matrix_id :type id) (:version :type semver) (:artifact_class :type ArtifactRightsClass)
  (:rights_basis :type ref) (:copyright_status :type ref) (:database_right_status :type ref)
  (:public_domain_status :type (member :PUBLIC_DOMAIN :NOT_PUBLIC_DOMAIN :RIGHTS_UNKNOWN))
  (:reproduction :type RightsDisposition) (:transformation :type RightsDisposition)
  (:redistribution :type RightsDisposition) (:commercial_api_use :type RightsDisposition)
  (:attribution :type ref) (:privacy_anonymization_restriction :type (or ref null))
  (:license_version :type semver) (:effective_period :type ref) (:provenance :type ref)
  (:legal_review_state :type LegalReviewState))
(define-record LicensePolicy/1
  (:license_policy_id :type id) (:version :type semver) (:matrices :type (list ref))
  (:citation_dataset_manifest_ref :type ref)        ; bound to the existing manifest (RA-K/RA-T); NOT a second store
  (:signature :type sig))
(define-invariant :V7I-RA-L-no-unlicensed
  "No LAWMAX license grant for material LAWMAX does not hold a right to. Absent proof ⇒ RIGHTS_UNKNOWN and no
   redistribution. :PUBLIC_DOMAIN requires legal_review_state :LEGALLY_VALIDATED. Free verification is never
   paywalled. Attribution binding is reasonable (no extra restriction inside CC BY).")

;; ============================ 4. RA-I UNIVERSAL LEGAL RESOLVER (NEW RA-S25) ====================
;; Read-only. EXTENDS canonical-uris.lisp (ELI) + legal-identity.lisp; deterministic grammar; offline dataset;
;; NO new canonical identity; typed ambiguity; no fuzzy/LLM silent choice in the trusted path.
(define-closed-enum ResolverInputKind
  (:ELI) (:ECLI) (:CELEX) (:ADA) (:FEK) (:LAW_YEAR) (:PD_YA_KYA) (:COURT_NUMBER_YEAR)
  (:GREEK_CITATION) (:ARTICLE_CODE) (:ALIAS) (:HISTORICAL_NAME))
(define-record ResolverQuery/1
  (:query_id :type id) (:version :type semver) (:input_kind :type ResolverInputKind)
  (:raw_input :type text) (:as_of :type (or instant null)))
(define-record AmbiguityResult/1
  (:ambiguity_id :type id) (:candidates :type (list ref)) (:reason :type text))
(define-record ResolverResult/1
  (:result_id :type id) (:version :type semver) (:query_ref :type ref)
  (:lawmax_identity :type (or ref null)) (:source_identity :type (or ref null))
  (:expressions :type (list ref)) (:manifestations :type (list ref))
  (:current_view :type (or ref null)) (:historical_views :type (list ref)) (:temporal_slice :type (or ref null))
  (:related_jurisprudence :type (list ref)) (:proof_bundle :type (or ref null))
  (:citation_formats :type (list ref)) (:ambiguity :type (or ref null))   ; AmbiguityResult when non-unique
  (:resolver_receipt :type ref))
(define-record ResolverReceipt/1
  (:receipt_id :type id) (:version :type semver) (:dataset_digest :type sha256)
  (:grammar_version :type semver) (:deterministic :type (member :true :false)) (:signature :type sig))
(define-invariant :V7I-RA-I-deterministic
  "The resolver trusted path is a DETERMINISTIC grammar over an offline content-addressed dataset; NO fuzzy/LLM
   silent selection. Non-unique input ⇒ typed AmbiguityResult/1, never a guess. The resolver mints NO new
   canonical identity; it maps external identifiers to existing identity, emitting a ResolverReceipt/1.")

;; ============================ 5. RA-R PUBLIC RETRIEVAL (EXTEND S13 static-site.lisp) ===========
(define-closed-enum RetrievalFormat (:HTML) (:MARKDOWN) (:JSON) (:JSON_LD) (:RDF_ELI) (:AKOMA_NTOSO) (:PROOF_BUNDLE))
(define-record CanonicalRetrievalView/1
  (:view_id :type id) (:version :type semver) (:legal_identity_ref :type ref) (:temporal_view :type ref)
  (:canonical_uri :type url)                        ; one canonical URI per legal identity × temporal view
  (:anchors :type (list ref))                       ; article/paragraph/subparagraph/passage — from AST/layout identity
  (:available_formats :type (list RetrievalFormat)) ; content negotiation on the SAME uri
  (:verification_state :type ref) (:uncertainty :type uncertainty)
  (:redirect_tombstone_ref :type (or ref null)) (:provenance :type ref))
(define-invariant :V7I-RA-R-proof-carrying-pages
  "Public pages are proof-carrying (never free SEO text); anchors derive from existing AST/layout identity (no
   second identity); content negotiation serves HTML/MD/JSON/JSON-LD/RDF-ELI/Akoma-Ntoso/proof from one canonical
   URI; sitemaps come from the coverage ledger; a withdrawn/moved citation leaves a tombstone/redirect (never a
   silent 404). llms.txt/discovery are replaceable adapters, not trust foundations. EXTENDS static-site.lisp
   (%sitemap, article-canonical-text) — no second emitter.")

;; ============================ 6. RA-K CITATION SUPREMACY (EXTEND S15) ==========================
(define-record CitationPanel/1
  (:panel_id :type id) (:version :type semver) (:strata :type (list ref)) (:hidden_holdout :type (member :true :false))
  (:prompts_digest :type sha256) (:locale :type keyword))
(define-record CitationSupremacyMetric/1
  (:metric_id :type id) (:version :type semver) (:panel_ref :type ref)
  (:provider :type text) (:model :type text) (:measured_at :type instant)
  (:citation_share :type (or uncertainty null)) (:position_prominence :type (or uncertainty null))
  (:citation_correctness :type (or uncertainty null)) (:verified_answer_share :type (or uncertainty null))
  (:broken_link_rate :type (or uncertainty null)) (:stale_citation_rate :type (or uncertainty null))
  (:no_citation_exposed :type (member :true :false))  ; when provider hides citation ⇒ metric = UNKNOWN, never 0
  (:confidence_interval :type (or ref null)) (:provenance :type ref))
(define-invariant :V7I-RA-K-metrics-not-truth
  "Citation metrics are NEVER evidence of legal correctness. A provider that exposes no citation is UNKNOWN, not
   0%. Panels are reproducible, stratified, versioned, with hidden holdouts and anti-gaming rules. EXTENDS the
   citation observatory (citation-authority.lisp + ai-citation-strategy.lisp) — no second citation subsystem.")

;; ============================ 7. RA-T DATASET DISTRIBUTION (EXTEND S14) ========================
(define-record DatasetSnapshot/1
  (:snapshot_id :type id) (:version :type semver) (:content_manifest_digest :type sha256)
  (:provenance :type ref) (:checksums :type (list ref)) (:license_policy_ref :type ref)
  (:transparency_registration :type ref) (:projections :type (list ref)) (:signature :type sig))
(define-record DatasetDelta/1
  (:delta_id :type id) (:version :type semver) (:from_snapshot_ref :type ref) (:to_snapshot_ref :type ref)
  (:content_manifest_digest :type sha256) (:correction_withdrawal_notice :type (or ref null)) (:signature :type sig))
(define-invariant :V7I-RA-T-lawmax-canonical-home
  "Every external distribution channel is a CapabilityManifest-bearing adapter; the canonical home is ALWAYS
   LAWMAX. A mirror/third platform is NEVER a source of truth. Snapshots/deltas are signed, content-addressed,
   license-bound (RA-L). EXTENDS ai-corpus-dump.lisp / ai-ingest-manifest.lisp — no second distribution store.")

;; ============================ 8. RA-J anonymization + RA-E translation + RA-INST tenants ========
(define-record AnonymizationReceipt/1               ; RA-J (EXTEND legal-decisions.lisp)
  (:receipt_id :type id) (:version :type semver) (:decision_ref :type ref) (:method :type ref)
  (:redacted_fields :type (list ref)) (:reviewer :type ref) (:residual_reidentification_assessment :type ref)
  (:legal_basis :type ref) (:emergency_withdrawal :type (or ref null)) (:signature :type sig))
(define-record NonAuthoritativeTranslation/1        ; RA-E (EXTEND USC expression model)
  (:translation_id :type id) (:version :type semver) (:derived_from :type ref) (:controlling_text_ref :type ref)
  (:language :type keyword) (:passage_alignment_map :type ref) (:translation_method :type ref)
  (:reviewer_state :type LegalReviewState) (:uncertainty :type uncertainty)
  (:status :type (member :NON_AUTHORITATIVE_TRANSLATION)))
(define-record TenantProfile/1 :status :INTERFACE_ONLY :public-dependency nil   ; RA-INST (NEW RA-S26, interfaces only)
  (:tenant_id :type id) (:version :type semver)
  (:tenant_kind :type (member :AI_PROVIDER :STATE_BODY :COURT :BAR_ASSOCIATION :UNIVERSITY :ENTERPRISE :PUBLISHER))
  (:scoped_namespace :type ref) (:delegated_signing :type (or ref null))
  (:may_submit_signed_proposals :type (member :true :false)) (:may_consume_exports :type (member :true :false))
  (:public_canonical_write :type (member :false)) (:root_rotation :type (member :false))
  (:adoption_bypass :type (member :false)) (:cross_tenant_access :type (member :false)))
(define-invariant :V7I-RA-INST-no-authority
  "A tenant may submit signed proposals/evidence, hold a scoped namespace, use delegated signing, receive signed
   exports and verify offline. A tenant NEVER gains public canonical write authority, root-rotation authority,
   the ability to bypass LAWMAX adoption, or access to another tenant / private matter. Interface-only, no public
   dependency (audit V7S-PUBPRIV).")

;; ============================ 9. RA ROOT-AUTHORITY QUALIFICATION STATE =========================
(define-closed-enum RootAuthorityState (:UNQUALIFIED) (:PROVISIONAL) (:QUALIFIED) (:DOWNGRADED) (:EXPIRED) (:REVOKED))
(define-record RootAuthorityQualification/1
  (:qual_id :type id) (:version :type semver) (:state :type RootAuthorityState)
  (:coverage :type ref) (:freshness :type ref) (:provenance :type ref)
  (:resolver_correctness :type ref) (:proof_verification :type ref) (:jurisprudence_coverage :type ref)
  (:citation_adoption :type ref) (:provider_adoption :type ref) (:institutional_adoption :type ref)
  (:security :type ref) (:recovery :type ref) (:qualification :type ref)
  (:expiry :type instant) (:auto_downgrade_on_expiry :type (member :true :false)) (:signature :type sig))
(define-invariant :V7I-RA-qual-revocable
  "ROOT_AUTHORITY is a typed, measurable, revocable, EXPIRING state — never a permanent marketing label. Failure
   of any mandatory threshold expires or downgrades it (auto_downgrade_on_expiry). Thresholds are finite external
   gates in V1.7-ROOT-AUTHORITY-ACCEPTANCE-MATRIX.md; the STATE MACHINE here is fully internal.")

;; ============================ 10. C-11 CORRECTED COVERAGE DECISION (availability LIVE) =========
;; Supersedes census-coverage-decision (v1.5 R3): availability is now a LIVE input (guard clause + INGESTED
;; requires public availability). v1.5 files are NOT edited; this is the v1.7 corrected seat.
(define-reference availability_state :canonical "V1.5-SCHEMAS.sexp:188" :identity "lawmax/availability-state" :version "1")
(define-reference census_coverage_state :canonical "V1.5-SCHEMAS.sexp:184 (frozen v1.4 enum)" :identity "lawmax/census-coverage-state" :version "1")
(define-decision-function census-coverage-decision-v7
  :supersedes "census-coverage-decision (v1.5 R3/B-1)"
  :inputs (observation acquisition validation admission divergence availability enumerability negative_evidence)
  :output census_coverage_state
  :clauses
  (;; (1-3) QUARANTINED dominates
   ((:divergence :DETERMINISTIC_DIVERGENCE)                                   :QUARANTINED)
   ((:validation :VALIDATION_FAILED)                                          :QUARANTINED)
   ((:admission  :UNMET)                                                      :QUARANTINED)
   ;; (4) C-11 AVAILABILITY GUARD — legally non-public / restricted NEVER becomes public INGESTED
   ((:availability (:member :COVERED_STATE_NON_PUBLIC :ACCESS_RESTRICTED :LICENSING_RESTRICTED :UNKNOWN)) :UNKNOWN)
   ;; (5) INGESTED requires lawful acquisition AND validation AND required admission AND public availability
   ((:observation :OBSERVED) (:acquisition :ACQUIRED_LAWFUL) (:validation :VALIDATED)
    (:admission (:member :SATISFIED :NOT_APPLICABLE)) (:availability :PUBLIC_PRESENT) :INGESTED)
   ;; (6) EXPLICITLY-ABSENT requires fresh authoritative negative evidence over a completeness/serial space
   ((:negative_evidence :VALID_AUTHORITATIVE_FRESH)
    (:enumerability (:member :AUTHORITATIVE_COMPLETE_INDEX :AUTHENTICATED_SERIAL_SPACE)) :EXPLICITLY-ABSENT)
   ;; (7) otherwise ⇒ UNKNOWN (expired/insufficient/partial/open-world)
   (:otherwise :UNKNOWN))
  :precedence "QUARANTINED > (availability guard ⇒ UNKNOWN) > INGESTED > EXPLICITLY-ABSENT > UNKNOWN"
  :total t :single-valued t)
(define-invariant :V7I-COV-availability-live
  "census-coverage-decision-v7 is TOTAL and SINGLE-VALUED; `availability` is a LIVE input (guard clause 4 AND the
   :PUBLIC_PRESENT requirement of the INGESTED clause). Legally non-public/access/licensing-restricted material
   never becomes public INGESTED; expired/insufficient ⇒ UNKNOWN; EXPLICITLY-ABSENT requires valid authoritative
   negative evidence. Audit V7S-COV: availability appears in a clause condition; mutation removing the guard flips.")

;; ============================ 11. PUBLIC/PRIVATE DEPENDENCY CLOSURE ROOTS (C-4) ================
;; The transitive closure (audit V7S-PUBPRIV) starts from these canonical public roots and follows record field
;; types, refs, extensions, interface I/O, subsystem deps, stores, owner/write-authority, API/MCP schema refs and
;; publication/declassification edges. It MUST contain no INTERFACE_ONLY/DEFERRED_PRIVATE record.
(define-ra-closure-roots
  (public-roots (LegalIR/1 MemoryEvent/1 TrustBundle/1 LanguageCognitionLayer/1 CognitionResult/1
                 CanonicalRetrievalView/1 ResolverResult/1 CitationSupremacyMetric/1 DatasetSnapshot/1
                 RightsMatrix/1 RootAuthorityQualification/1))
  (edge-kinds (field-type ref ref-target extension interface-io subsystem-dep consumes produces store
               owner write-authority api-schema publication declassification))
  (private-forbidden (TenantProfile/1 PrivateMemoryEvent/1 PrivateMatterProfile/1 RealTimeAssistance/1 EmbodimentInterfaces/1)))
(define-invariant :V7I-PUBPRIV-acyclic
  "The public dependency closure follows ALL edge kinds above and contains ZERO INTERFACE_ONLY / DEFERRED_PRIVATE
   record and ZERO private-bearing enum. Public → private/real-time/embodiment edges are FORBIDDEN and
   structurally absent (audit V7S-PUBPRIV, non-vacuous via injected ref/interface/store/api/extension/declass leaks).")
(define-invariant :V7I-no-mandatory-model-v7
  "No define-adapter-contract or requirement is :mandatory t for any model/ONNX/provider/runtime. Removing every
   proposer yields SafetyMode :SYMBOLIC_ONLY over the full acquisition→publication path (audit V7S-SYM/V7S-NOMODEL).")

;; ============================ 12. SYMBOLIC-ONLY PIPELINE acquisition→publication (C-3) =========
;; A connected DAG. Reachable entry→exit over symbolic-only nodes with NO proposer-mandatory node; every edge
;; type-compatible; proposers only enrich the :proposer-optional nodes and are removable (path still connects).
(define-pipeline symbolic-only-path
  :entry ACQUIRE :exit PUBLISH
  :nodes (ACQUIRE CENSUS ADMIT IR REASON COMPILE PROOF PUBLISH)
  :edges ((ACQUIRE CENSUS) (ACQUIRE ADMIT) (ADMIT IR) (IR REASON) (IR COMPILE) (REASON PROOF) (COMPILE PROOF) (PROOF PUBLISH))
  :symbolic-only-nodes (ACQUIRE CENSUS ADMIT IR REASON COMPILE PROOF PUBLISH)
  :proposer-optional-nodes (ADMIT IR REASON)          ; proposers only enrich; removable with no path loss
  :proposer-mandatory-nodes ()                        ; MUST be empty (C-10 / V6I-02)
  :node-types ((ACQUIRE "PerceptionEnvelope/1") (CENSUS "census_coverage_state") (ADMIT "SemanticAdmissionEvidence/1")
               (IR "LegalIR/1") (REASON "CognitionResult/1") (COMPILE "legal_state_root") (PROOF "proof_bundle")
               (PUBLISH "CanonicalRetrievalView/1")))
(define-invariant :V7I-SYM-reachable
  "symbolic-only-path: entry ACQUIRE reaches exit PUBLISH over symbolic-only nodes; proposer-mandatory-nodes is
   EMPTY; removing every proposer (all :proposer-optional enrichment) leaves entry→exit connected; a broken edge
   or unknown node type fails CLOSED. Audit V7S-SYM with 5 mutations (broken edge, incompatible type, unreachable
   stage, mandatory model dependency, proposer removal).")

;; ============================ 13. DATA OWNERSHIP / WRITE-AUTHORITY MATRIX (C-7) ================
;; Each store: exactly one canonical owner, exactly one write authority where writes are allowed, zero writers on
;; a read-only projection. `[design-target]` marks a registry-declared seat with no source file yet (honest).
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
(define-invariant :V7I-OWN-single-writer
  "Every store has exactly ONE owner and, where writes are allowed, exactly ONE write authority; read-only
   projections have zero writers; the ONE canonical write seat is write-authority.lisp for the journal/memory/IR.
   Audit V7S-OWN with 4 mutations (zero owner, two owners, two writers, writer on read-only store).")

;; ============================ 14. CAPABILITY → SEAT CLOSURE (C-8) ==============================
;; Every capability maps file→package→symbol→subsystem→requirement→test. NO_PERFECT_UNDERSTANDING_CLAIM is an
;; INVARIANT/qualification boundary (:V6I-13), NEVER a capability-seat. Cognition capabilities are closed by the
;; v1.6 cognition->existing-lisp-seat map (audit V6S14); the RA capabilities are closed here.
(define-capability-seat :capability :RESOLVE_IDENTIFIER :file "canonical-uris.lisp" :package "orchestrator.uris" :symbol "get-eli-law-prefix" :subsystem RA-S25 :requirement RA-I :test RA-Q-RESOLVE)
(define-capability-seat :capability :PUBLIC_RETRIEVAL   :file "static-site.lisp"    :package "orchestrator.static-site" :symbol "emit-corpus-site" :subsystem S13 :requirement RA-R :test RA-Q-RETRIEVE)
(define-capability-seat :capability :CITATION_MEASURE   :file "ai-citation-strategy.lisp" :package "orchestrator.ai-citation" :symbol "export-citation-metrics" :subsystem S15 :requirement RA-K :test RA-Q-CITE)
(define-capability-seat :capability :DATASET_DISTRIBUTE :file "ai-corpus-dump.lisp"  :package "orchestrator.corpus" :symbol "ai-corpus-dump" :subsystem S14 :requirement RA-T :test RA-Q-DATASET)
(define-capability-seat :capability :JURIS_ANONYMIZE    :file "legal-decisions.lisp" :package "orchestrator.decisions" :symbol "decision-ratio" :subsystem S07 :requirement RA-J :test RA-Q-JURIS)
(define-capability-seat :capability :EXPRESSION_TRANSLATE :file "LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md" :package "usc.expression" :symbol "lawmax/expression/1" :subsystem S16 :requirement RA-E :test RA-Q-TRANSLATE)
(define-capability-seat :capability :RIGHTS_LICENSE     :file "LAWMAX-LICENSE-POLICY.md" :package "ra.license" :symbol "RightsMatrix/1" :subsystem RA-S25 :requirement RA-L :test RA-Q-LICENSE)
(define-invariant :V7I-CAP-seat-closure
  "Every RA capability names a real file→package→symbol→subsystem→requirement→test. An arbitrary string is not a
   seat. NO_PERFECT_UNDERSTANDING_CLAIM is an invariant boundary, not an executable capability. Audit V7S-CAP with
   an injected empty-symbol mutation.")

;; ============================ 15. FULL PUBLIC SOURCE-TYPE COVERAGE (§6) ========================
;; The Source-Type Registry (LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md, ST-01..ST-28 + ST-UNKNOWN) is the
;; ONE seat (EXTEND, versioned, open). Category ≠ binding force. Unknown fails closed. Required families:
(define-source-type-coverage
  :registry "LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md"
  :required-families (:CONSTITUTION :FORMAL_LAW :SPECIAL_LAW :CODE :EXECUTIVE_RATIFYING_LAW :COMPULSORY_LAW
    :LEGISLATIVE_DECREE :ROYAL_PRESIDENTIAL_DECREE :ACT_OF_LEGISLATIVE_CONTENT :PARLIAMENT_REGULATION :PYS
    :MINISTERIAL_DECISION :JOINT_MINISTERIAL_DECISION :INDEPENDENT_AUTHORITY_DECISION :REGIONAL_MUNICIPAL_ACT
    :CIRCULAR_GUIDELINE :REGULATORY_INDIVIDUAL_ADMIN_ACT :INTERNATIONAL_CONVENTION :RATIFICATION_ACT
    :COLLECTIVE_AGREEMENT_PUBLIC :EU_PRIMARY :EU_SECONDARY :EU_REGULATION :EU_DIRECTIVE :EU_DECISION
    :EU_DELEGATED_ACT :EU_IMPLEMENTING_ACT :SOFT_LAW_NON_BINDING :GREEK_JURISPRUDENCE :CJEU :ECTHR
    :COURT_OF_AUDIT :LEGAL_COUNCIL_OF_STATE :TRAVAUX_PREPARATOIRES :DOCTRINE_EPISTEMIC :HISTORICAL_FUTURE_TYPE)
  :unknown-fail-closed t :versioned t :open-extension t
  :relations-not-title-labels "(general/special, lex superior/specialis/posterior, binding effect) are scoped, evidence-backed relations/policies — never immutable title labels")
(define-invariant :V7I-SRC-open-fail-closed
  "The source-type registry covers every required family, is versioned + open to extension, and classifies from
   authority evidence (never from act title). An unknown source type FAILS CLOSED and enters only via versioned
   registry extension + legal validation. Audit V7S-SRC with a removed-family mutation.")

;; ============================ 16. ACTUAL WP RECONCILIATION (C-6) ===============================
;; v1.7 concept → the WP that REALLY owns it (validated against WP-NN.md), or FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED.
(define-wp-reconciliation
  (:concept COGNITION_DAG            :wp WP-08 :evidence "WP-08.md:19 Public Legal Discernment core")
  (:concept NEURAL_PROPOSER          :wp WP-07 :evidence "WP-07.md:25 external neural runtime")
  (:concept SECURE_INGRESS           :wp WP-02 :evidence "WP-02.md:6 non-evaluating decoder")
  (:concept LEGAL_IR                 :wp WP-03 :evidence "WP-03.md typed Legal IR")
  (:concept BITEMPORAL_TWIN          :wp WP-03 :evidence "WP-03.md valid×known event store")
  (:concept TRUST_BUNDLE             :wp WP-06 :evidence "WP-06.md:20 IssuedClaim/TrustBundle")
  (:concept PUBLIC_PRIVATE_BOUNDARY  :wp WP-12 :evidence "WP-12.md:5 R-111 public→private")
  (:concept PROOF_CARRYING_QUERY     :wp WP-11 :evidence "WP-11.md proof-carrying-answer/1")
  (:concept RESOLVER_URIS            :wp WP-11 :evidence "WP-11.md canonical-uris.lisp (ELI only)")
  (:concept ECLI                     :wp WP-09 :evidence "WP-09.md NEW ECLI impl")
  (:concept PUBLIC_RETRIEVAL_SITE    :wp WP-12 :evidence "WP-12.md static-site.lisp /lawmax/{path}")
  (:concept CITATION_MEASUREMENT     :wp WP-13 :evidence "WP-13.md citation observatory")
  (:concept DATASET_DISTRIBUTION     :wp WP-11 :evidence "WP-11.md ai-corpus-dump.lisp signed delta feeds")
  (:concept PROVIDER_REGISTRY        :wp WP-14 :evidence "WP-14.md LocalTrustState.provider_registry")
  (:concept MEMORY_KERNEL            :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :evidence "no WP owns a memory kernel; WP-03 event store overlaps only")
  (:concept UNIFIED_RESOLVER         :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :evidence "ELI/ECLI/CELEX scattered; CELEX in zero packets")
  (:concept LICENSE_RIGHTS_MATRIX    :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :evidence "only decision gates WP-01-a/WP-09-a; no matrix")
  (:concept CONTENT_NEGOTIATION_SITEMAPS :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :evidence "content-negotiation in zero packets")
  (:concept TENANT_PROFILES          :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :evidence "provider registry exists, no tenant-profile abstraction")
  (:concept ROOT_AUTHORITY_FLYWHEEL  :wp FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED :evidence "NEW_GAP; no integrated flywheel seat"))
(define-invariant :V7I-WP-honest
  "Every v1.7 concept maps to the WP that REALLY owns it (WP-NN.md evidence) or to
   FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED — never a false mapping. MEMORY_KERNEL is NOT WP-11 (C-1). Audit
   V7S-WP: a concept mapping to a WP whose evidence does not name it, or memory mapped to WP-11, flips the check.")
