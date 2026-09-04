# MODEL-MIGRATION-CONFLICT-LEDGER — every disagreement/normalization surfaced during migration.

ADJUDICATION RECORD of the one-time migration from the v1.6-v1.8 registries into the canonical model. The rows
are enumerated deterministically by `build_model.py` (sorted adjacency, sorted start order, each data-flow cycle
canonicalised to its lexicographically smallest rotation and de-duplicated); the adjudication in the final
paragraph is a decision, not a derivation, which is why this file is classified ARCHITECTURE_DECISION and not
GENERATED_VIEW. No silent normalization: each row records the conflict, its resolution, the governing invariant,
what was preserved/retired, the migration consequence, rollback, and whether creator adjudication is required.
Every row is reconciled against the canonical model by the gate (`gate_checks.py conflict-ledger`), in both
directions: a row that the model does not exhibit fails, and a normalization the model exhibits without a row
fails too.

CORRECTION (this pass): the five DATAFLOW-CYCLE rows previously recorded cycles enumerated in Python set-iteration
order, which is not reproducible between runs. The enumeration is now deterministic and the rows below are the
canonical cycles. The set of cycles is unchanged in substance — the same subsystems participate — only their
starting point and duplicate rotations were arbitrary before.

| # | kind | source | fact | proposed canonical resolution | governing invariant | preserved/retired | rollback | disposition |
|---|---|---|---|---|---|---|---|---|
| 1 | DATAFLOW-CYCLE | subsystem consumer/data-flow graph | `S03->S10->S11->S25->S13->S09->S04->S03` | RECORD as non-invariant: the acyclic law (L4) governs the PERMITTED processing pipeline (stage graph), not runtime data-flow; data-flow legitimately cycles (reactive cockpit<->cognition<->trust). | :V6I-17 + pipeline symbolic-only-path | both graphs preserved | none | no creator approval required |
| 2 | DATAFLOW-CYCLE | subsystem consumer/data-flow graph | `S04->S19->S10->S11->S25->S13->S09->S04` | RECORD as non-invariant: the acyclic law (L4) governs the PERMITTED processing pipeline (stage graph), not runtime data-flow; data-flow legitimately cycles (reactive cockpit<->cognition<->trust). | :V6I-17 + pipeline symbolic-only-path | both graphs preserved | none | no creator approval required |
| 3 | DATAFLOW-CYCLE | subsystem consumer/data-flow graph | `S10->S11->S10` | RECORD as non-invariant: the acyclic law (L4) governs the PERMITTED processing pipeline (stage graph), not runtime data-flow; data-flow legitimately cycles (reactive cockpit<->cognition<->trust). | :V6I-17 + pipeline symbolic-only-path | both graphs preserved | none | no creator approval required |
| 4 | DATAFLOW-CYCLE | subsystem consumer/data-flow graph | `S13->S25->S13` | RECORD as non-invariant: the acyclic law (L4) governs the PERMITTED processing pipeline (stage graph), not runtime data-flow; data-flow legitimately cycles (reactive cockpit<->cognition<->trust). | :V6I-17 + pipeline symbolic-only-path | both graphs preserved | none | no creator approval required |
| 5 | DATAFLOW-CYCLE | subsystem consumer/data-flow graph | `S14->S15->S14` | RECORD as non-invariant: the acyclic law (L4) governs the PERMITTED processing pipeline (stage graph), not runtime data-flow; data-flow legitimately cycles (reactive cockpit<->cognition<->trust). | :V6I-17 + pipeline symbolic-only-path | both graphs preserved | none | no creator approval required |
| 6 | COMPOSITE-WP | SUBSYSTEM-REGISTRY S20 | `WP-07+WP-11+WP-14` | SPLIT into one wp-map fact per WP token (each resolves to a declared wp fact). | :SR-V6-one-seat | all WP tokens preserved | revert to single composite token | none |
| 7 | COMPOSITE-WP | SUBSYSTEM-REGISTRY S21 | `WP-07+WP-08` | SPLIT into one wp-map fact per WP token (each resolves to a declared wp fact). | :SR-V6-one-seat | all WP tokens preserved | revert to single composite token | none |
| 8 | NON-SUBSYSTEM-CONSUMER | INTERFACE-AND-SCHEMA-REGISTRY consumers | `legal-extraction-verify.lisp` | declare as a `component` fact owned by its subsystem (S03) so reference-closure holds. | closed typed references | consumer preserved as component | drop component fact | none |
| 9 | NON-SUBSYSTEM-CONSUMER | INTERFACE-AND-SCHEMA-REGISTRY consumers | `proposers` | declare as a `component` fact owned by its subsystem (S03) so reference-closure holds. | closed typed references | consumer preserved as component | drop component fact | none |

**Adjudication:** every conflict above is a mechanical normalization with an explicit governing invariant; none
changes architecture meaning, so none is escalated to creator approval. The data-flow cycles are RECORDED as a
non-invariant — the acyclic law L4 governs the permitted pipeline stage DAG, not runtime data-flow.
