# ROOT-OPERATOR-DECISION-PACKET — canonical architecture model (initial import)

> SINGLE_OPERATOR_ASSURANCE: machines processed the complete repository volume; this packet is the bounded set of
> changed facts + evidence the Root Operator adjudicates and signs. No gate requires exhaustive human repository review.

<!-- PACKET-RECONCILIATION
total-facts 1439
modules 11
model-root-digest 9202ad3aa7bc5bdc3592569b6dff222c05e641bd587edc1e8cf7a95fb1e7dcd4
family component 2
family consumes 102
family dir-rule 65
family file 989
family gen-edge 4
family gen-step 5
family inventory-total 1
family rationale 5
family req-map 29
family requirement 24
family source-class 66
family stage 8
family stage-edge 8
family store 10
family subsystem 26
family test 21
family type 60
family wp 14
commitment kernel 6b8d037edfd10db06ea61919a8f1e3746aba7d957d5a07800a84445bb611124a
commitment checker 6b8d037edfd10db06ea61919a8f1e3746aba7d957d5a07800a84445bb611124a
-->

## 1. Change summary
Initial import of the canonical ARCHITECTURE-MODEL: 1439 facts across 11 hash-pinned modules, migrated from the
v1.6-v1.8 registries. Parent architecture commit `4787b342282f8d5f2ec4b9e64b11e32b7a64813a`. Canonical model-root digest `9202ad3aa7bc5bdc3592569b6dff222c05e641bd587edc1e8cf7a95fb1e7dcd4`, RECOMPUTED from the
ordered module pins by both verification paths rather than read from the file.

## 2. Affected model facts (per family)
| family | count |
|---|---|
| component | 2 |
| consumes | 102 |
| dir-rule | 65 |
| file | 989 |
| gen-edge | 4 |
| gen-step | 5 |
| inventory-total | 1 |
| rationale | 5 |
| req-map | 29 |
| requirement | 24 |
| source-class | 66 |
| stage | 8 |
| stage-edge | 8 |
| store | 10 |
| subsystem | 26 |
| test | 21 |
| type | 60 |
| wp | 14 |
| **total** | **1439** |

Per pinned module:

| module | facts |
|---|---|
| deferred-imports.sexp | 66 |
| dependencies-and-boundaries.sexp | 118 |
| files-and-roles.sexp | 1055 |
| generation-order.sexp | 9 |
| interfaces-and-types.sexp | 62 |
| rationale-references.sexp | 5 |
| requirements-tests-workpackets.sexp | 88 |
| stores-and-authorities.sexp | 10 |
| subsystems.sexp | 26 |

## 2b. Migration-scope ledger — imported vs DEFERRED_DATA_IMPORT
Every v1.6-v1.8 source fact class is enumerated exactly once in `deferred-imports.sexp` (mapped to its source
file + a finite migration batch); none is silently omitted and none is left as an open architecture decision.
Ledger verification (multiset-aware re-derivation from the sources): **PASS** — `DEFERRED-IMPORT LEDGER: PASS (rows=66 source-classes=66 exact-universe multiset-checked deferred=56 all-batched)`.

| status | source-classes |
|---|---|
| DEFERRED_DATA_IMPORT | 56 |
| IMPORTED | 4 |
| OUT_OF_MIGRATION_SCOPE | 6 |

Deferred fact classes by finite batch: DDI-1=12, DDI-2=18, DDI-3=10, DDI-4=16 (batch scopes are declared in `build_deferred.py`;
DEFERRED_DATA_IMPORT means enumerated + scheduled, NOT dropped). This pass imported only the structural
seat/topology classes; the deferred data is a finite, batched follow-up. No freeze claim follows from this pass,
and none of those batches has been started.

## 2c. Tracked-file inventory
36622 tracked paths are classified exactly once: 989 carry an individual `file` fact and 35633 are counted by 65 `dir-rule` facts.

## 3. Invariants affected
All model laws: L1 well-formedness (declared fact type, required keys, permitted value kinds, closed enum
domains), L2 one seat (duplicate seat, duplicate key, id owned by one type), L3 closed typed references against
each field's declared target universe, L4 acyclicity of every declared from/to relation, L5 public/private
isolation with every consumer of undecidable kind failing closed, L6 complete requirement->seat->test->WP
mapping, L7 exact module/hash universe with the model-root digest recomputed from the ordered pins.

## 4. Pass/fail evidence
- SBCL model-law kernel: **PASS** (exit 0). SHA-256 from a vetted external provider over raw bytes.
- Independent clingo checker (derives every model law from its own reading of the model): **PASS** (exit 0).
- Golden fixtures + generated property families, each run through BOTH paths: **PASS** — `golden fixtures=8  generated properties=22  failures=0`.

## 5. Independent-checker agreement
The two paths **AGREE**. Agreement is not asserted from two verdict strings: each path publishes a fact-set
commitment (total, per-module and per-family counts and digests) and the checker refuses to issue a verdict
unless its commitment is byte-identical to the kernel's. Commitment digest: `6b8d037edfd10db06ea61919a8f1e3746aba7d957d5a07800a84445bb611124a`.

## 6. Independent AI review receipts and independence evidence
None attached in this pass. AI reviewers have no canonical-write authority; agreement reduces workload but is not
proof; disagreement auto-escalates; no model/tool/reviewer self-certifies independence. This model has been
through one external independent review, which FAILED it and required correction; a fresh independent review of
the corrected model, generator, kernel and second-checker independence is awaited.

## 7. Unresolved / CONFLICTING items
Migration conflicts: see MODEL-MIGRATION-CONFLICT-LEDGER.md — every row of that ledger is reconciled against
this model by the gate in both directions. None escalated to creator approval.

## 8. Worst credible consequence
A wrong classification of a file role or a mis-migrated fact could let a real architecture drift pass
structurally. Mitigation: exact hash-pinned modules, a recomputed model root, an independent second path bound
to an identical fact-set commitment, and golden/property/held-out fixtures. This is NOT semantic, legal,
security, operational or qualification proof.

## 9. Migration and rollback
Migration: build_model.py + build_deferred.py + build_inventory.py, in the order declared by
`generation-order.sexp`. Rollback: revert this commit; the v1.6-v1.8 registries and the legacy v1.8 harness
(frozen at 4787b342282f8d5f2ec4b9e64b11e32b7a64813a) are preserved unchanged as migration input and HISTORICAL_EVIDENCE, and the harness is no longer
a dependency of anything on the live path.

## 10. Decision
- **APPROVE** — promote this canonical model root as the architecture source of truth.
- **REJECT** — discard; keep the registries as source.
- **DEFER** — request the fresh independent review first.

Final canonical promotion requires the Root Operator's signed approval. This packet asserts NO freeze and NO
qualification.
