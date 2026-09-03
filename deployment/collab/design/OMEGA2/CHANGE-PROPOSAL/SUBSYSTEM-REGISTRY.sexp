;;;; LAWMAX OMEGA — SUBSYSTEM-REGISTRY (v1.6 CANDIDATE · single source of truth)
;;;; Machine-readable. Human tables (ARCHITECTURE-CLOSURE-MATRIX, crosswalk) are GENERATED from this —
;;;; NOT a second hand-maintained truth (v1.6 :V6I-17). Design-only; parent 112379cc; frozen 88129099 intact.
;;;; Each subsystem maps EXACTLY once: reason -> subsystem -> requirement -> interface -> data owner ->
;;;; test -> future WP -> migration -> rollback. Reuses the existing 18 CPEI subsystems + v1.6 additions.
;;;; Dispositions: KEEP | EXTEND | SPLIT | MOVE | DEFER_PRIVATE | REMOVE (no file MOVE is executed now).

(registry-version "subsystem-registry-v1.6" :status :CANDIDATE :generated-source-of-truth t
 :classification :NORMATIVE :emits "ARCHITECTURE-CLOSURE-MATRIX rows + crosswalk seats (generated)")

;; ---- existing 18 CPEI subsystems (reused verbatim; disposition for v1.6) ----
(define-subsystem S01 :mission MIS-2 :name "National Legal Census / Radar (M1·L9)"
  :requirement R-132 :interface "CensusSpaceClassification/1 + census-coverage-decision" :owner "coverage-ledger.lisp"
  :test Q01 :future-wp WP-01 :migration KEEP :rollback "coverage ledger checkpoint")
(define-subsystem S02 :mission MIS-1 :name "Multimodal acquisition (M2·L1/L3)"
  :requirement R-16 :interface "PerceptionEnvelope/1 (v1.6)" :owner "acquirer/1 + ingestion-daemon.lisp"
  :test Q16 :future-wp WP-02 :migration EXTEND :rollback "re-acquire from source bytes")
(define-subsystem S03 :mission MIS-1 :name "Model-agnostic SemanticProposer plane (was 'neuro-symbolic bridge' §4.3/§4.4)"
  :requirement R-25 :interface "SemanticProposer + CandidateInterpretation/1 (v1.6, ONNX optional adapter)"
  :owner "legal-extraction-verify.lisp (epistemic wall)" :test Q22 :future-wp WP-02
  :migration EXTEND :rollback "drop all proposers ⇒ SafetyMode :SYMBOLIC_ONLY")
(define-subsystem S04 :mission MIS-1 :name "Symbolic Common Lisp core + Public Language Cognition Layer (v1.6 §4)"
  :requirement R-129 :interface "LanguageCognitionLayer/1 + LegalIR/1 (existing engine, one seat)"
  :owner "greek-nlp-core.lisp + legal-ast.lisp + legal-inference-engine.lisp" :test Q08 :future-wp WP-06
  :migration EXTEND :rollback "disable cognition layer ⇒ structural-only Legal IR")
(define-subsystem S05 :mission MIS-3 :name "Bitemporal Legal Digital Twin (M3·L2)"
  :requirement R-35 :interface "legal-timeline/1 + audit-timeline/1" :owner "version-graph.lisp + legal-temporal.lisp"
  :test Q41 :future-wp WP-04 :migration EXTEND :rollback "journal replay to checkpoint")
(define-subsystem S06 :mission MIS-4 :name "Unified legal hypergraph"
  :requirement R-40 :interface "LegalIR/1 nodes/edges" :owner "legal graph store"
  :test Q06 :future-wp WP-07 :migration KEEP :rollback "graph rebuild from journal")
(define-subsystem S07 :mission MIS-4 :name "Jurisprudence evolution plane (M4·§4.9)"
  :requirement R-51 :interface "line-of-authority + later-treatment (v1.5 D1.5)" :owner "legal-event-calculus.lisp"
  :test Q06 :future-wp WP-07 :migration KEEP :rollback "re-derive from journal")
(define-subsystem S08 :mission MIS-5 :name "Dual independent compilation (M5·§4.6)"
  :requirement R-126 :interface "verify_a.go + verify_b.mjs (two compilers, no shared evaluator)"
  :owner "release-gate.lisp" :test Q43 :future-wp WP-05 :migration KEEP :rollback "QUARANTINED on root_A≠root_B")
(define-subsystem S09 :mission MIS-5 :name "Proof-carrying query engine (M6·§4.7)"
  :requirement R-122 :interface "CertifiedResult + citation/1" :owner "proof layer"
  :test Q42 :future-wp WP-08 :migration KEEP :rollback "re-issue certified result")
(define-subsystem S10 :mission MIS-1 :name "MLTP trust layer (§4.10) + crypto agility"
  :requirement R-130 :interface "TrustBundle/1 + LocalTrustState + suite registry" :owner "MLTP v3"
  :test Q28 :future-wp WP-03 :migration EXTEND :rollback "pinned root + epoch rollback")
(define-subsystem S11 :mission MIS-9 :name "Nation-state security cells (§4.14/§4.22)"
  :requirement R-134 :interface "threshold+n-of-m root, independent failure domains" :owner "security cells"
  :test Q28 :future-wp WP-03 :migration KEEP :rollback "revocation/recovery/rebuild")
(define-subsystem S12 :mission MIS-6 :name "Cockpit (§4.12)"
  :requirement R-118 :interface "Plan/1 + ActionIntent/1 + Approval/1 (v1.6)" :owner "approval-policy.lisp + decisions.lisp"
  :test Q19 :future-wp WP-12 :migration EXTEND :rollback "reject intent; rollback_target")
(define-subsystem S13 :mission MIS-6 :name "Public search + website (§4.12)"
  :requirement R-124 :interface "static-site.lisp + canonical URLs" :owner "static-site.lisp"
  :test Q16 :future-wp WP-13 :migration KEEP :rollback "regenerate from projection")
(define-subsystem S14 :mission MIS-5 :name "OpenAPI / MCP / SDKs / feeds (§4.15)"
  :requirement R-102 :interface "OpenAPI 3.x + MCP tools + thin SDKs (adapters)" :owner "capability-api"
  :test Q27 :future-wp WP-14 :migration EXTEND :rollback "version pin; deprecate")
(define-subsystem S15 :mission MIS-9 :name "Observatories: citation/security/coverage (§4.13/§4.14)"
  :requirement R-124 :interface "monitoring reports" :owner "observatory"
  :test Q42 :future-wp WP-13 :migration KEEP :rollback "re-run monitor")
(define-subsystem S16 :mission MIS-2 :name "Source-type authority registry (§4.20)"
  :requirement R-132 :interface "SourceTypeEntry + census_coverage_state (v1.5 D2/F3)" :owner "LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md"
  :test Q29 :future-wp WP-01 :migration EXTEND :rollback "registry version rollback")
(define-subsystem S17 :mission MIS-8 :name "Ontology & validation governance (§4.19)"
  :requirement R-131 :interface "ontology-bundle + shacl-validation-receipt" :owner "shacl-validator.lisp"
  :test Q40 :future-wp WP-09 :migration KEEP :rollback "shapes digest pin")
(define-subsystem S18 :mission MIS-10 :name "Public→private boundary (§1.3/§1.4)"
  :requirement R-111 :interface "one-way monotonic boundary; DeclassificationReceipt/1" :owner "boundary schemas"
  :test Q20 :future-wp WP-10 :migration EXTEND :rollback "block flow; require receipt")

;; ---- v1.6 ADDITIONS (new subsystems introduced by this candidate; each ONE seat) ----
(define-subsystem S19 :mission MIS-1 :name "Memory Kernel (v1.6 §5 complete taxonomy)"
  :requirement R-V6-MEM :interface "MemoryEvent/1 + MemoryProjection/1 + MemoryPolicy/1" :owner "memory.lisp (ONE seat, EXTEND)"
  :test V6Q-02 :future-wp WP-11 :migration EXTEND :rollback "byte-verifiable memory replay to checkpoint")
(define-subsystem S20 :mission MIS-1 :name "Adapter replaceability plane (v1.6 §8)"
  :requirement R-V6-ADP :interface "CapabilityManifest/1 + ToolInvocation/1 + adapter contracts" :owner "capability registry"
  :test V6Q-17 :future-wp WP-14 :migration EXTEND :rollback "shadow→canary→rollback; fail-closed")
(define-subsystem S21 :mission MIS-1 :name "SafetyState + SYMBOLIC_ONLY mode (v1.6 §0/§3)"
  :requirement R-V6-SAFE :interface "SafetyState/1 + SafetyMode enum" :owner "safe-mode controller (EXTEND write-authority.lisp)"
  :test V6Q-01 :future-wp WP-00 :migration EXTEND :rollback "fail-closed to :SYMBOLIC_ONLY")
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
   S19 memory has ONE seat (memory.lisp EXTEND); S04 cognition has ONE seat (existing engine EXTEND). The
   architecture gate (V1.6-CONTRADICTION-OMISSION-AUDIT.sh) rejects any violation.")
