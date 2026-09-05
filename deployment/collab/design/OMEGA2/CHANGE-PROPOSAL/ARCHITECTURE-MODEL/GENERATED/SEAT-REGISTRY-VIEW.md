<!-- GENERATED — DO NOT EDIT. Regenerate: python3 ARCHITECTURE-MODEL/regenerate.py -->
# Seat Registry View — every declared seat, its status and its artifact (GENERATED VIEW — DO NOT EDIT)

- generator: `generate_views.py/3`
- canonical-model-root-digest: `46bf277330e42ef431350ae96d7bb845b755ae6e157b88587cf3a21d46f9f5ce`
- regeneration command: `python3 ARCHITECTURE-MODEL/regenerate.py`

Review-2 N-10: a seat is BUILT or DOCUMENT_SEAT only when it names a tracked path, and a seat that is not built carries the rationale and the work packet that will build it. No seat is a bare string.

| seat | status | path | packet | rationale |
|---|---|---|---|---|
| SEAT-AI-CORPUS-DUMP | BUILT | source/ai-corpus-dump.lisp | — | — |
| SEAT-APPROVAL-POLICY | BUILT | systems/orchestrator-cli/approval-policy.lisp | — | — |
| SEAT-BOUNDARY-SHAPES | DOCUMENT_SEAT | deployment/shapes/legal-shapes.ttl | — | — |
| SEAT-CANONICAL-URIS | BUILT | source/canonical-uris.lisp | — | — |
| SEAT-CAPABILITY-API | BUILT | source/capability-api.lisp | — | — |
| SEAT-CAPABILITY-REGISTRY | BUILT | source/capability-registry.lisp | — | — |
| SEAT-CITATION-AUTHORITY | BUILT | source/citation-authority.lisp | — | — |
| SEAT-COVERAGE-LEDGER | DESIGN_TARGET | — | WP-01 | RAT-WP-HONESTY |
| SEAT-COVERAGE-OWNER | DESIGN_TARGET | — | WP-01 | RAT-WP-HONESTY |
| SEAT-EMBODIMENT-INTERFACES | DEFERRED_PRIVATE | — | — | RAT-PUBPRIV |
| SEAT-INGESTION-DAEMON | BUILT | source/ingestion-daemon.lisp | — | — |
| SEAT-JOURNAL | BUILT | source/journal.lisp | — | — |
| SEAT-KERNEL-VERIFY | BUILT | deployment/verify/kernel-verify.lisp | — | — |
| SEAT-LEGAL-AST | BUILT | source/legal-ast.lisp | — | — |
| SEAT-LEGAL-EVENT-CALCULUS | BUILT | source/legal-event-calculus.lisp | — | — |
| SEAT-LEGAL-EXTRACTION-VERIFY | BUILT | source/legal-extraction-verify.lisp | — | — |
| SEAT-LEGAL-HYPERGRAPH | BUILT | source/legal-hypergraph.lisp | — | — |
| SEAT-MEMORY | BUILT | source/memory.lisp | — | — |
| SEAT-MLTP-THRESHOLD-CUSTODY | DESIGN_TARGET | — | WP-06 | RAT-WP-HONESTY |
| SEAT-NO-WRITER | NO_WRITER | — | — | RAT-ONE-SEAT |
| SEAT-OBSERVATORY-COLLECTOR | DESIGN_TARGET | — | WP-13 | RAT-WP-HONESTY |
| SEAT-PRIVATE-MATTER-PROFILE | DEFERRED_PRIVATE | — | — | RAT-PUBPRIV |
| SEAT-PROOF-CARRYING | BUILT | source/proof-carrying.lisp | — | — |
| SEAT-RA-T-SIGNER | DESIGN_TARGET | — | WP-11 | RAT-WP-HONESTY |
| SEAT-REALTIME-ASSISTANCE | DEFERRED_PRIVATE | — | — | RAT-PUBPRIV |
| SEAT-RELEASE-GATE | BUILT | systems/orchestrator-cli/release-gate.lisp | — | — |
| SEAT-SECURITY-CELLS | DESIGN_TARGET | — | WP-06 | RAT-WP-HONESTY |
| SEAT-SHACL-VALIDATOR | BUILT | source/shacl-validator.lisp | — | — |
| SEAT-SOURCE-TYPE-AUTHORITY-REGISTRY | DOCUMENT_SEAT | deployment/LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md | — | — |
| SEAT-STATIC-SITE | BUILT | source/static-site.lisp | — | — |
| SEAT-TENANT-PROFILE | INTERFACE_ONLY | — | — | RAT-PUBPRIV |
| SEAT-VERSION-GRAPH | BUILT | source/version-graph.lisp | — | — |
| SEAT-WRITE-AUTHORITY | BUILT | source/write-authority.lisp | — | — |

Seats: 33 total — 20 BUILT, 3 DEFERRED_PRIVATE, 6 DESIGN_TARGET, 2 DOCUMENT_SEAT, 1 INTERFACE_ONLY, 1 NO_WRITER.
