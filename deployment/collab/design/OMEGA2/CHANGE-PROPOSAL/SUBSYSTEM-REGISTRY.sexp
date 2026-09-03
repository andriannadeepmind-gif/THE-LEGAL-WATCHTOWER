;;;; LAWMAX OMEGA — SUBSYSTEM-REGISTRY (v1.6 CANDIDATE · single source of truth)
;;;; Machine-readable. Human tables (ARCHITECTURE-CLOSURE-MATRIX, crosswalk) are GENERATED from this —
;;;; NOT a second hand-maintained truth (v1.6 :V6I-17). Design-only; parent 112379cc; frozen 88129099 intact.
;;;; Each subsystem maps EXACTLY once: reason -> subsystem -> requirement -> interface -> data owner ->
;;;; test -> future WP -> migration -> rollback. Reuses the existing 18 CPEI subsystems + v1.6 additions.
;;;; Dispositions: KEEP | EXTEND | SPLIT | MOVE | DEFER_PRIVATE | REMOVE (no file MOVE is executed now).

(registry-version "subsystem-registry-v1.6" :status :CANDIDATE :generated-source-of-truth t
 :classification :NORMATIVE :emits "ARCHITECTURE-CLOSURE-MATRIX rows + crosswalk seats (generated)")

;; ---- Implementation-Book Work-Packet purposes (EVIDENCE: IMPLEMENTATION-BOOK/WORK-PACKETS/WP-NN.md:1/5/6) ----
;; This is the audit's WP-assignment cross-check source of truth (V1.6-CONTRADICTION-OMISSION-AUDIT.sh V6S11).
;; Every `:future-wp` token below must resolve to one of these WP ids (or FUTURE_BOOK_REVISION / DEFERRED).
;; `:owns` = the requirement ranges each WP owns per WP-NN.md:5. Grounded, not asserted.
(define-wp-purpose WP-00 :purpose "clean reproducible base + genuinely green CI (prerequisite of every WP)" :owns "R-1..R-6 R-85..R-88 R-99 R-100")
(define-wp-purpose WP-01 :purpose "national source/court census + total coverage ledger" :owns "R-01..R-13 R-132")
(define-wp-purpose WP-02 :purpose "acquisition, provenance, authenticity + Secure Semantic Ingress sandbox (non-evaluating decoder; external trust boundary)" :owns "R-14..R-23 R-133")
(define-wp-purpose WP-03 :purpose "typed Legal IR + bitemporal event store (valid x known); nearest substrate to memory (temporal/provenance/episodic only)" :owns "R-31..R-38")
(define-wp-purpose WP-04 :purpose "first deterministic Legal Compiler (Common Lisp, domain A); legal-state root + unified hypergraph" :owns "R-40 R-43")
(define-wp-purpose WP-05 :purpose "second independent compiler (Rust, domain B) + differential verification/quarantine" :owns "R-39 R-41 R-42")
(define-wp-purpose WP-06 :purpose "MLTP v3, offline verifier, Trust Mesh + crypto agility; OWNS TrustBundle (IssuedClaim/TrustBundle/VerificationReceipt) + nation-state" :owns "R-57..R-70 R-89 R-90 R-92 R-94 R-125..R-128 R-130 R-134")
(define-wp-purpose WP-07 :purpose "multimodal acquisition + EXTERNAL neural runtime (non-authoritative, disableable) + ontology alignment; toolchain-freeze WP-07.md:25 pins Python+ONNX and MUST become optional adapter" :owns "R-24..R-30 R-131")
(define-wp-purpose WP-08 :purpose "neuro-symbolic reasoning + epistemic wall (Public Legal Discernment core); HOSTS the Language Cognition Layer (Deliverable 6 composition S3+S4+S6+S7+S9)" :owns "R-129")
(define-wp-purpose WP-09 :purpose "full jurisprudence-evolution plane (line-of-authority, authority_weight)" :owns "R-51..R-56")
(define-wp-purpose WP-10 :purpose "National Legal Digital Twin + normative-impact projection engine" :owns "R-48..R-50")
(define-wp-purpose WP-11 :purpose "proof-carrying query API / MCP / thin SDKs (adapters) + Citation-Bound Verification Profile" :owns "R-44..R-47 R-71..R-73 R-101..R-110 R-119..R-124")
(define-wp-purpose WP-12 :purpose "website, cockpit, publication workflow + public->private enforcement; OWNS DeclassificationReceipt (R-111)" :owns "R-74..R-81 R-111")
(define-wp-purpose WP-13 :purpose "citation observatory + security/operational observatory" :owns "R-82..R-84 R-93 R-95..R-98")
(define-wp-purpose WP-14 :purpose "mission-scale qualification + provider adoption; provider registry + adoption attestations" :owns "R-112..R-118")
(define-wp-purpose FUTURE_BOOK_REVISION :purpose "NO existing WP owns this v1.6 concept; a future Implementation-Book revision must declare an owner — do not invent a false mapping" :owns "none")

;; ---- existing 18 CPEI subsystems (reused verbatim; disposition for v1.6) ----
;; NOTE: `:future-wp` now names the WP that actually OWNS each subsystem's `:requirement` (per define-wp-purpose
;; above), corrected from the earlier v1.6 candidate where several were misassigned.
(define-subsystem S01 :mission MIS-2 :name "National Legal Census / Radar (M1·L9)"
  :requirement R-132 :interface "CensusSpaceClassification/1 + census-coverage-decision" :owner "coverage-ledger.lisp"
  :test Q01 :future-wp WP-01 :migration KEEP :rollback "coverage ledger checkpoint")
(define-subsystem S02 :mission MIS-1 :name "Multimodal acquisition (M2·L1/L3)"
  :requirement R-16 :interface "PerceptionEnvelope/1 (v1.6)" :owner "acquirer/1 + ingestion-daemon.lisp"
  :test Q16 :future-wp WP-02 :migration EXTEND :rollback "re-acquire from source bytes")
(define-subsystem S03 :mission MIS-1 :name "Model-agnostic SemanticProposer plane (was 'neuro-symbolic bridge' §4.3/§4.4)"
  :requirement R-25 :interface "SemanticProposer + CandidateInterpretation/1 (v1.6, ONNX optional adapter)"
  :owner "legal-extraction-verify.lisp (epistemic wall)" :test Q22 :future-wp WP-07
  :migration EXTEND :rollback "drop all proposers ⇒ SafetyMode :SYMBOLIC_ONLY")
(define-subsystem S04 :mission MIS-1 :name "Symbolic Common Lisp core + Public Language Cognition Layer (v1.6 §4)"
  :requirement R-129 :interface "LanguageCognitionLayer/1 (references LegalIR/1; existing engine, one seat)"
  :owner "greek-nlp-core.lisp + legal-ast.lisp + legal-inference-engine.lisp" :test Q08 :future-wp WP-08
  :migration EXTEND :rollback "disable cognition layer ⇒ structural-only Legal IR")
(define-subsystem S05 :mission MIS-3 :name "Bitemporal Legal Digital Twin (M3·L2)"
  :requirement R-35 :interface "legal-timeline/1 + audit-timeline/1" :owner "version-graph.lisp + legal-temporal.lisp"
  :test Q41 :future-wp WP-03 :migration EXTEND :rollback "journal replay to checkpoint")
(define-subsystem S06 :mission MIS-4 :name "Unified legal hypergraph"
  :requirement R-40 :interface "LegalIR/1 nodes/edges" :owner "legal graph store"
  :test Q06 :future-wp WP-04 :migration KEEP :rollback "graph rebuild from journal")
(define-subsystem S07 :mission MIS-4 :name "Jurisprudence evolution plane (M4·§4.9)"
  :requirement R-51 :interface "line-of-authority + later-treatment (v1.5 D1.5)" :owner "legal-event-calculus.lisp"
  :test Q06 :future-wp WP-09 :migration KEEP :rollback "re-derive from journal")
(define-subsystem S08 :mission MIS-5 :name "Dual independent compilation (M5·§4.6)"
  :requirement R-126 :interface "verify_a.go + verify_b.mjs (two compilers, no shared evaluator)"
  :owner "release-gate.lisp" :test Q43 :future-wp WP-06 :migration KEEP :rollback "QUARANTINED on root_A≠root_B"
  :wp-note "the dual-compilation MECHANISM is built at WP-04/WP-05; R-126 executable-closure is OWNED by WP-06")
(define-subsystem S09 :mission MIS-5 :name "Proof-carrying query engine (M6·§4.7)"
  :requirement R-122 :interface "CertifiedResult + citation/1" :owner "proof layer"
  :test Q42 :future-wp WP-11 :migration KEEP :rollback "re-issue certified result")
(define-subsystem S10 :mission MIS-1 :name "MLTP trust layer (§4.10) + crypto agility"
  :requirement R-130 :interface "TrustBundle/1 + LocalTrustState + suite registry" :owner "MLTP v3"
  :test Q28 :future-wp WP-06 :migration EXTEND :rollback "pinned root + epoch rollback")
(define-subsystem S11 :mission MIS-9 :name "Nation-state security cells (§4.14/§4.22)"
  :requirement R-134 :interface "threshold+n-of-m root, independent failure domains" :owner "security cells"
  :test Q28 :future-wp WP-06 :migration KEEP :rollback "revocation/recovery/rebuild")
(define-subsystem S12 :mission MIS-6 :name "Cockpit (§4.12)"
  :requirement R-118 :interface "Plan/1 + ActionIntent/1 + Approval/1 (v1.6)" :owner "approval-policy.lisp + decisions.lisp"
  :test Q19 :future-wp WP-12 :migration EXTEND :rollback "reject intent; rollback_target"
  :wp-note "concept=§4.12 cockpit (WP-12, R-74..R-81); R-118 is a WP-14 qualification cross-ref, not the owner")
(define-subsystem S13 :mission MIS-6 :name "Public search + website (§4.12)"
  :requirement R-124 :interface "static-site.lisp + canonical URLs" :owner "static-site.lisp"
  :test Q16 :future-wp WP-12 :migration KEEP :rollback "regenerate from projection")
(define-subsystem S14 :mission MIS-5 :name "OpenAPI / MCP / SDKs / feeds (§4.15)"
  :requirement R-102 :interface "OpenAPI 3.x + MCP tools + thin SDKs (adapters)" :owner "capability-api"
  :test Q27 :future-wp WP-11 :migration EXTEND :rollback "version pin; deprecate")
(define-subsystem S15 :mission MIS-9 :name "Observatories: citation/security/coverage (§4.13/§4.14)"
  :requirement R-124 :interface "monitoring reports" :owner "observatory"
  :test Q42 :future-wp WP-13 :migration KEEP :rollback "re-run monitor"
  :wp-note "concept=§4.13/§4.14 observatory (WP-13, R-82..R-84); R-124 citation-bound is cross-owned by WP-11")
(define-subsystem S16 :mission MIS-2 :name "Source-type authority registry (§4.20)"
  :requirement R-132 :interface "SourceTypeEntry + census_coverage_state (v1.5 D2/F3)" :owner "LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md"
  :test Q29 :future-wp WP-01 :migration EXTEND :rollback "registry version rollback")
(define-subsystem S17 :mission MIS-8 :name "Ontology & validation governance (§4.19)"
  :requirement R-131 :interface "ontology-bundle + shacl-validation-receipt" :owner "shacl-validator.lisp"
  :test Q40 :future-wp WP-07 :migration KEEP :rollback "shapes digest pin")
(define-subsystem S18 :mission MIS-10 :name "Public→private boundary (§1.3/§1.4)"
  :requirement R-111 :interface "one-way monotonic boundary; DeclassificationReceipt/1" :owner "boundary schemas"
  :test Q20 :future-wp WP-12 :migration EXTEND :rollback "block flow; require receipt")

;; ---- v1.6 ADDITIONS (new subsystems introduced by this candidate; each ONE seat) ----
(define-subsystem S19 :mission MIS-1 :name "Memory Kernel (v1.6 §5 complete taxonomy)"
  :requirement R-V6-MEM :interface "MemoryEvent/1 + MemoryProjection/1 + MemoryPolicy/1" :owner "memory.lisp (ONE seat, EXTEND)"
  :test V6Q-02 :future-wp FUTURE_BOOK_REVISION :migration EXTEND :rollback "byte-verifiable memory replay to checkpoint"
  :wp-note "NO existing WP owns a memory kernel; nearest substrate = WP-03 bitemporal store (temporal/provenance/episodic only). FUTURE BOOK REVISION REQUIRED before construction")
(define-subsystem S20 :mission MIS-1 :name "Adapter replaceability plane (v1.6 §8)"
  :requirement R-V6-ADP :interface "CapabilityManifest/1 + ToolInvocation/1 + adapter contracts" :owner "capability registry"
  :test V6Q-17 :future-wp WP-07+WP-11+WP-14 :migration EXTEND :rollback "shadow→canary→rollback; fail-closed"
  :wp-note "neural-runtime adapter=WP-07; thin-SDK/MCP adapters=WP-11; provider adoption/conformance=WP-14. Unified CapabilityManifest/1 type = FUTURE BOOK REVISION (no single seat)")
(define-subsystem S21 :mission MIS-1 :name "SafetyState + SYMBOLIC_ONLY mode (v1.6 §0/§3)"
  :requirement R-V6-SAFE :interface "SafetyState/1 + SafetyMode enum" :owner "safe-mode controller (EXTEND write-authority.lisp)"
  :test V6Q-01 :future-wp WP-07+WP-08 :migration EXTEND :rollback "fail-closed to :SYMBOLIC_ONLY"
  :wp-note "model independence = WP-07 (external non-authoritative neural); SYMBOLIC_ONLY completeness = WP-08 (epistemic wall). Typed SafetyState/1 envelope = FUTURE BOOK REVISION (WP-00 is base/CI only)")
(define-subsystem S22 :mission MIS-10 :name "Private Matter Profile (extension contract ONLY)"
  :requirement R-V6-PRIV :interface "PrivateMatterProfile/1 (interfaces only)" :owner "DEFERRED_PRIVATE (no public dependency)"
  :test V6Q-09 :future-wp DEFERRED :migration DEFER_PRIVATE :rollback "n/a — never a public dependency")
(define-subsystem S23 :mission MIS-10 :name "Real-time assistance (extension contract ONLY)"
  :requirement R-V6-RT :interface "RealTimeAssistance/1 (interfaces only)" :owner "DEFERRED_PRIVATE"
  :test V6Q-13 :future-wp DEFERRED :migration DEFER_PRIVATE :rollback "n/a")
(define-subsystem S24 :mission MIS-10 :name "Embodiment interfaces (extension contract ONLY)"
  :requirement R-V6-EMB :interface "EmbodimentInterfaces/1 (interfaces only)" :owner "DEFERRED_PRIVATE"
  :test V6Q-13 :future-wp DEFERRED :migration DEFER_PRIVATE :rollback "independent emergency stop; sim/HIL gate")

;; ---- casegrammar SPLIT (a file-level disposition surfaced for the migration map) ----
(define-file-disposition "legal-casegrammar.lisp"
  :was DEFER_PRIVATE :now SPLIT
  :public "general Greek morphology / case frames / ambiguity detection -> S04 Language Cognition Layer (shared/public)"
  :private "client-fact schemas + matter-solving -> S22 PrivateMatterProfile (DEFER_PRIVATE)"
  :no-copy "no second implementation; private consumes the public general mechanisms")

(define-invariant :SR-V6-one-seat
  "Every subsystem has exactly ONE owner seat. No dual seats, no orphan subsystem, no multiple write owners.
   S19 memory has ONE seat (memory.lisp EXTEND); S04 cognition has ONE seat (existing engine EXTEND). Every
   `:future-wp` token resolves to a `define-wp-purpose` WP id (or FUTURE_BOOK_REVISION / DEFERRED); the
   architecture gate (V1.6-CONTRADICTION-OMISSION-AUDIT.sh V6S11) rejects a dangling or invented WP.")
(define-invariant :SR-V6-wp-honesty
  "WP assignment is grounded in WP-NN.md, not asserted. Where NO existing WP owns a v1.6 concept the registry
   says FUTURE_BOOK_REVISION (memory kernel S19; unified adapter type S20) rather than inventing a false
   mapping. Cognition is WP-08 (Public Legal Discernment core), NOT WP-06; TrustBundle is WP-06, NOT WP-03;
   the neural/proposer plane is WP-07, NOT WP-02; DeclassificationReceipt is WP-12, NOT WP-10.")
