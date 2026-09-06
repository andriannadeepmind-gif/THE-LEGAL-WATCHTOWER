<!-- AUTHORED ADJUDICATION — NOT GENERATED, NOT A TEMPLATE.
     Every block below is authored reasoning: normative justification, risk acceptance and the decision the Root
     Operator signs. `build_decision_packet.py` inserts these blocks into the packet VERBATIM and may compute
     nothing in them except the model-derived values marked {{...}}, which the gate recomputes independently.
     Review-3 §15 M3: the packet's MECHANICAL skeleton — headings, fields, tables, counts, inventories,
     generated references and the verdict skeleton — lives in PACKET-TEMPLATE.md. Authored rationale does NOT,
     and moving any of the prose below into that template would be a defect, not a simplification. -->

<!-- BLOCK: assurance -->
> SINGLE_OPERATOR_ASSURANCE: machines processed the complete repository volume; this packet is the bounded set of
> changed facts + evidence the Root Operator adjudicates and signs. No gate requires exhaustive human repository review.

<!-- BLOCK: ledger-note -->
Every v1.6-v1.8 source fact class is enumerated exactly once in `deferred-imports.sexp` (mapped to its source
file + a finite migration batch); none is silently omitted and none is left as an open architecture decision.

<!-- BLOCK: batch-note -->
(batch scopes are declared in `build_deferred.py`; DEFERRED_DATA_IMPORT means enumerated + scheduled, NOT
dropped). This pass imported only the structural seat/topology classes. None of those batches has been started.

<!-- BLOCK: authority-note -->
The split is not prose: `authority` is a required, enum-constrained field of every `source-class` fact, both
verification paths enforce it, and the gate recomputes the totals above from the model. The model additionally
carries a `promotion` fact whose GLOBAL scope is **{{global-promotion}}** — a machine-checkable statement that
global single-source-of-truth status is withheld while any class remains authoritative at its source.

<!-- BLOCK: invariants -->
All model laws: L1 well-formedness (declared fact type, required keys, permitted value kinds, closed enum
domains), L2 one seat (duplicate seat, duplicate key, id owned by one type), L3 closed typed references against
each field's declared target universe, L4 acyclicity of every declared from/to relation, L5 public/private
isolation with every consumer of undecidable kind failing closed, L6 complete requirement->seat->test->WP
mapping, L7 exact module/hash universe with the model-root digest recomputed from the ordered pins.

<!-- BLOCK: receipts -->
None attached in this pass. AI reviewers have no canonical-write authority; agreement reduces workload but is not
proof; disagreement auto-escalates; no model/tool/reviewer self-certifies independence. This model has been
through two external independent reviews, both of which FAILED it and required correction; a fresh independent
review of the corrected model, generator, kernel and second-checker independence is awaited.

<!-- BLOCK: unresolved -->
Migration conflicts: see MODEL-MIGRATION-CONFLICT-LEDGER.md — every row of that ledger is reconciled against
this model by the gate in both directions. None escalated to creator approval.

<!-- BLOCK: consequence -->
A wrong classification of a file role or a mis-migrated fact could let a real architecture drift pass
structurally. Mitigation: exact hash-pinned modules, a recomputed model root, an independent second path bound
to an identical fact-set commitment, and golden/property/held-out fixtures. This is NOT semantic, legal,
security, operational or qualification proof.

<!-- BLOCK: rollback -->
Migration: the one-time model emitter plus build_deferred.py and build_inventory.py, in the order declared by
`generation-order.sexp`. Rollback: revert this commit; the v1.6-v1.8 registries and the legacy v1.8 harness
(frozen at {{parent-commit}}) are preserved unchanged as migration input and HISTORICAL_EVIDENCE, and the
harness is no longer a dependency of anything on the live path.

<!-- BLOCK: decision -->
The options below are bounded by the authority split in §2b-i. There is deliberately NO option to promote this
model as the global architecture source of truth, because {{deferred-classes}} source classes covering
{{deferred-forms}} source forms are still authoritative at their declared legacy sources; the model's own
`promotion` fact records that state as **{{global-promotion}}**, and it is the gate, not this prose, that
enforces it.

- **APPROVE (bounded)** — accept this canonical model root as the source of truth **for the imported classes
  only**, leaving every deferred class authoritative at its declared legacy source. This authorizes a fresh
  independent review; it does NOT authorize DDI-1, and it does not make this model globally canonical.
- **REJECT** — discard; keep the registries as source.
- **DEFER** — request the fresh independent review before deciding anything.

Global single-source-of-truth status becomes available only after DDI-1…DDI-4 are complete and each has been
independently reviewed. Final canonical promotion requires the Root Operator's signed approval. This packet
asserts NO freeze, NO qualification, and NO independent verification: an internal PASS authorizes a fresh
independent review and nothing else.
