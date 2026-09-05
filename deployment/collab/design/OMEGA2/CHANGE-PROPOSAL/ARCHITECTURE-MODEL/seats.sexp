;;;; seats.sexp — the ONE typed seat universe (Review-2 N-10).
;;;;
;;;; Before this pass `subsystem :owner-seat`, `store :owner` and `store :writer` were unconstrained strings.
;;;; The independent review showed that `ghost-does-not-exist.lisp`, `:owner ghost` and `:writer ghost-writer`
;;;; all passed on BOTH verification paths, and that 21 of 26 owner-seat values resolved to no tracked path at
;;;; all — they were English descriptions such as "legal graph store", "proof layer", "MLTP v3" and
;;;; "security cells". A claim of "requirement -> seat -> test -> WP completeness" over strings like those is
;;;; an assertion, not a closure.
;;;;
;;;; A seat is now a first-class fact with a declared STATUS, and the schema's conditional rules make the
;;;; distinction structural rather than conventional:
;;;;   BUILT / DOCUMENT_SEAT  -> :path is REQUIRED and must be a tracked path of the candidate tree
;;;;                             (enforced by `gate_checks.py seats`, which is the seat that owns git access);
;;;;                             :rationale and :packet are FORBIDDEN — a built seat is not a plan.
;;;;   DESIGN_TARGET          -> :path is FORBIDDEN, so a design target can never be dressed as a real file;
;;;;                             :rationale and :packet are REQUIRED, so every unbuilt seat names why it is
;;;;                             deferred and which work packet will build it.
;;;;   DEFERRED_PRIVATE / INTERFACE_ONLY / NO_WRITER -> contract-only or absent-by-declaration seats; :path is
;;;;                             FORBIDDEN and :rationale is REQUIRED. "none" as a bare word is not an answer.
;;;;
;;;; Seats are keyed by ARTIFACT, not by referrer, so a subsystem and a store that mean the same place name the
;;;; same seat. That is what makes "one canonical seat per concept" checkable instead of aspirational: two ids
;;;; for one artifact would be a duplicate seat, and the same artifact under two writers is a conflict.
;;;;
;;;; Every adjudication below was made against the candidate tree with `git ls-files`, one seat at a time.

;; ───────────────────────────────────────────────────────────── BUILT: the artifact exists in the tree today
(fact seat SEAT-INGESTION-DAEMON :status BUILT :path "source/ingestion-daemon.lisp"
      :note "Multimodal acquisition plane (S02). The v1.6 registry wrote 'acquirer/1 + ingestion-daemon.lisp'; acquirer/1 is an interface identifier, not a file, so the seat is the daemon.")
(fact seat SEAT-LEGAL-EXTRACTION-VERIFY :status BUILT :path "source/legal-extraction-verify.lisp"
      :note "Model-agnostic SemanticProposer plane (S03) — the epistemic wall between machine inference and admitted structure.")
(fact seat SEAT-LEGAL-AST :status BUILT :path "source/legal-ast.lisp"
      :note "Symbolic Common Lisp core (S04) and the owning seat of the legal-ir store. greek-nlp-core.lisp and legal-inference-engine.lisp are further artifacts of the same subsystem, not further seats.")
(fact seat SEAT-VERSION-GRAPH :status BUILT :path "source/version-graph.lisp"
      :note "Bitemporal Legal Digital Twin (S05); legal-temporal.lisp is a second artifact of the same subsystem.")
(fact seat SEAT-LEGAL-HYPERGRAPH :status BUILT :path "source/legal-hypergraph.lisp"
      :note "Unified legal hypergraph (S06). The registry said 'legal graph store'; this is the artifact that is that store.")
(fact seat SEAT-LEGAL-EVENT-CALCULUS :status BUILT :path "source/legal-event-calculus.lisp"
      :note "Jurisprudence evolution plane (S07).")
(fact seat SEAT-RELEASE-GATE :status BUILT :path "systems/orchestrator-cli/release-gate.lisp"
      :note "Dual independent compilation gate (S08).")
(fact seat SEAT-PROOF-CARRYING :status BUILT :path "source/proof-carrying.lisp"
      :note "Proof-carrying query engine (S09). The registry said 'proof layer'; this is the engine artifact.")
(fact seat SEAT-KERNEL-VERIFY :status BUILT :path "deployment/verify/kernel-verify.lisp"
      :note "MLTP trust layer (S10) and the owning seat of the trust-bundle store. The registry said 'MLTP v3'.")
(fact seat SEAT-APPROVAL-POLICY :status BUILT :path "systems/orchestrator-cli/approval-policy.lisp"
      :note "Cockpit approval plane (S12); decisions.lisp is a second artifact of the same subsystem.")
(fact seat SEAT-STATIC-SITE :status BUILT :path "source/static-site.lisp"
      :note "Public search and website (S13), and the owning seat of the static-site store.")
(fact seat SEAT-CAPABILITY-API :status BUILT :path "source/capability-api.lisp"
      :note "OpenAPI / MCP / SDK / feed surface (S14).")
(fact seat SEAT-CITATION-AUTHORITY :status BUILT :path "source/citation-authority.lisp"
      :note "Observatories (S15) and the owning seat of the citation-observatory store. Only the CITATION observatory is built; the security and coverage observatories named in the same registry entry are not, and are carried by SEAT-COVERAGE-LEDGER and SEAT-SECURITY-CELLS.")
(fact seat SEAT-SHACL-VALIDATOR :status BUILT :path "source/shacl-validator.lisp"
      :note "Ontology and validation governance (S17).")
(fact seat SEAT-MEMORY :status BUILT :path "source/memory.lisp"
      :note "Memory Kernel (S19) and the owning seat of the memory store — ONE seat, per the v1.6 registry.")
(fact seat SEAT-CAPABILITY-REGISTRY :status BUILT :path "source/capability-registry.lisp"
      :note "Adapter replaceability plane (S20). The registry said 'capability registry'.")
(fact seat SEAT-WRITE-AUTHORITY :status BUILT :path "source/write-authority.lisp"
      :note "SafetyState / SYMBOLIC_ONLY controller (S21), declared by the registry as an EXTEND of this seat, and the single writer of the journal and legal-ir stores.")
(fact seat SEAT-CANONICAL-URIS :status BUILT :path "source/canonical-uris.lisp"
      :note "Universal Legal Resolver (S25) and the owning seat of the resolver-dataset store; legal-identity.lisp is a second artifact of the same subsystem.")
(fact seat SEAT-AI-CORPUS-DUMP :status BUILT :path "source/ai-corpus-dump.lisp"
      :note "Owning seat of the dataset-distribution store (WP-11).")
(fact seat SEAT-JOURNAL :status BUILT :path "source/journal.lisp"
      :note "Owning seat of the journal store (WP-03).")

;; ───────────────────────────────────────────────────────────── DOCUMENT_SEAT: the seat is a document, not code
(fact seat SEAT-SOURCE-TYPE-AUTHORITY-REGISTRY :status DOCUMENT_SEAT
      :path "deployment/LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md"
      :note "Source-type authority registry (S16). The authority of this subsystem is a normative document, and saying so is more honest than naming a source file that does not implement it.")
(fact seat SEAT-BOUNDARY-SHAPES :status DOCUMENT_SEAT :path "deployment/shapes/legal-shapes.ttl"
      :note "Public->private boundary schemas (S18). The boundary is declared as SHACL shapes; eli-shapes.ttl is a second artifact of the same seat.")

;; ───────────────────────────────────────────────────────────── DESIGN_TARGET: not built; never a fake path
(fact seat SEAT-COVERAGE-LEDGER :status DESIGN_TARGET :rationale RAT-WP-HONESTY :packet WP-01
      :note "National Legal Census / Radar (S01) and the owning seat of the coverage-ledger store. The v1.6 registry already marked this '[design-target]'; no coverage-ledger.lisp is tracked in the candidate tree and none is invented here.")
(fact seat SEAT-SECURITY-CELLS :status DESIGN_TARGET :rationale RAT-WP-HONESTY :packet WP-06
      :note "Nation-state security cells (S11). source/guard-metaeval.lisp and source/guard-ops-pack.lisp exist but implement metaevaluation and ops guards, which is a different concern; the security-cell seat itself is unbuilt.")
(fact seat SEAT-OBSERVATORY-COLLECTOR :status DESIGN_TARGET :rationale RAT-WP-HONESTY :packet WP-13
      :note "Declared writer of the citation-observatory store. The collector role is named by the v1.6 registry; no collector artifact is tracked.")
(fact seat SEAT-COVERAGE-OWNER :status DESIGN_TARGET :rationale RAT-WP-HONESTY :packet WP-01
      :note "Declared writer of the coverage-ledger store; unbuilt for the same reason as SEAT-COVERAGE-LEDGER.")
(fact seat SEAT-RA-T-SIGNER :status DESIGN_TARGET :rationale RAT-WP-HONESTY :packet WP-11
      :note "Declared writer of the dataset-distribution store. RA-T-signer appears only as a role in the MLTP fixtures; there is no signer artifact in the candidate tree.")
(fact seat SEAT-MLTP-THRESHOLD-CUSTODY :status DESIGN_TARGET :rationale RAT-WP-HONESTY :packet WP-06
      :note "Declared writer of the trust-bundle store — threshold custody of the MLTP root. Named by the v1.8 registry; the custody artifact is unbuilt.")

;; ───────────────────────────────────────────────────────────── contract-only and absent-by-declaration seats
(fact seat SEAT-PRIVATE-MATTER-PROFILE :status DEFERRED_PRIVATE :rationale RAT-PUBPRIV
      :note "Private Matter Profile (S22) — extension contract ONLY. Deliberately has no public seat; the public/private boundary forbids one.")
(fact seat SEAT-REALTIME-ASSISTANCE :status DEFERRED_PRIVATE :rationale RAT-PUBPRIV
      :note "Real-time assistance (S23) — extension contract ONLY.")
(fact seat SEAT-EMBODIMENT-INTERFACES :status DEFERRED_PRIVATE :rationale RAT-PUBPRIV
      :note "Embodiment interfaces (S24) — extension contract ONLY.")
(fact seat SEAT-TENANT-PROFILE :status INTERFACE_ONLY :rationale RAT-PUBPRIV
      :note "Provider / institutional tenant profiles (S26) and the owning seat of the tenant-profile store — an interface with no implementation on the public side, by design.")
(fact seat SEAT-NO-WRITER :status NO_WRITER :rationale RAT-ONE-SEAT
      :note "The explicit absence of a write authority, for stores that are derived or read-only: resolver-dataset, static-site and tenant-profile. Naming this seat is what replaces the bare word 'none', so 'no writer' is a declared state rather than an unparsed string.")
