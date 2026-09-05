# ROOT-OPERATOR-DECISION-PACKET — canonical architecture model (initial import)

> SINGLE_OPERATOR_ASSURANCE: machines processed the complete repository volume; this packet is the bounded set of
> changed facts + evidence the Root Operator adjudicates and signs. No gate requires exhaustive human repository review.

<!-- PACKET-RECONCILIATION
total-facts 1567
modules 13
model-root-digest 46bf277330e42ef431350ae96d7bb845b755ae6e157b88587cf3a21d46f9f5ce
family component 2
family consumes 102
family dir-rule 65
family falsifier 52
family file 998
family fixture 8
family gen-artifact 12
family gen-edge 4
family gen-step 5
family harness 2
family inventory-total 1
family promotion 2
family property-family 5
family rationale 5
family req-map 29
family requirement 24
family seat 33
family source-class 66
family stage 8
family stage-edge 8
family store 10
family subsystem 26
family test 21
family tool 5
family type 60
family wp 14
deferred-classes 56
deferred-source-forms 332
imported-classes 4
global-promotion FORBIDDEN_UNTIL_DDI_COMPLETE
commitment kernel fcc68723880d4b2707d414f766305b218d99f3c029bd527ca2f9e9ffd2e2e618
commitment checker fcc68723880d4b2707d414f766305b218d99f3c029bd527ca2f9e9ffd2e2e618
-->

## 1. Change summary
Initial import of the canonical ARCHITECTURE-MODEL: 1567 facts across 13 hash-pinned modules, migrated from the
v1.6-v1.8 registries. Parent architecture commit `4787b342282f8d5f2ec4b9e64b11e32b7a64813a`. Canonical model-root digest `46bf277330e42ef431350ae96d7bb845b755ae6e157b88587cf3a21d46f9f5ce`, RECOMPUTED from the
ordered module pins by both verification paths rather than read from the file.

## 2. Affected model facts (per family)
| family | count |
|---|---|
| component | 2 |
| consumes | 102 |
| dir-rule | 65 |
| falsifier | 52 |
| file | 998 |
| fixture | 8 |
| gen-artifact | 12 |
| gen-edge | 4 |
| gen-step | 5 |
| harness | 2 |
| inventory-total | 1 |
| promotion | 2 |
| property-family | 5 |
| rationale | 5 |
| req-map | 29 |
| requirement | 24 |
| seat | 33 |
| source-class | 66 |
| stage | 8 |
| stage-edge | 8 |
| store | 10 |
| subsystem | 26 |
| test | 21 |
| tool | 5 |
| type | 60 |
| wp | 14 |
| **total** | **1567** |

Per pinned module:

| module | facts |
|---|---|
| TOOLCHAIN.sexp | 5 |
| deferred-imports.sexp | 68 |
| dependencies-and-boundaries.sexp | 118 |
| files-and-roles.sexp | 1064 |
| generation-order.sexp | 21 |
| interfaces-and-types.sexp | 62 |
| rationale-references.sexp | 5 |
| requirements-tests-workpackets.sexp | 88 |
| seats.sexp | 33 |
| stores-and-authorities.sexp | 10 |
| subsystems.sexp | 26 |
| verification-corpus.sexp | 67 |

## 2b. Migration-scope ledger — imported vs DEFERRED_DATA_IMPORT
Every v1.6-v1.8 source fact class is enumerated exactly once in `deferred-imports.sexp` (mapped to its source
file + a finite migration batch); none is silently omitted and none is left as an open architecture decision.
Ledger verification (multiset-aware re-derivation from the sources): **PASS** — `DEFERRED-IMPORT LEDGER: PASS (rows=66 source-classes=66 exact-universe multiset-checked deferred=56 all-batched)`.

| status | source-classes | source forms |
|---|---|---|
| DEFERRED_DATA_IMPORT | 56 | 332 |
| IMPORTED | 4 | 97 |
| OUT_OF_MIGRATION_SCOPE | 6 | 6 |

Deferred fact classes by finite batch, with the number of SOURCE FORMS each batch actually carries: DDI-1=12 classes / 40 forms, DDI-2=18 classes / 156 forms, DDI-3=10 classes / 12 forms, DDI-4=16 classes / 124 forms
(batch scopes are declared in `build_deferred.py`; DEFERRED_DATA_IMPORT means enumerated + scheduled, NOT
dropped). This pass imported only the structural seat/topology classes. None of those batches has been started.

### 2b-i. Typed authority split — what this model is, and is not, authoritative for
| authority | applies to | meaning |
|---|---|---|
| `CANONICAL_IN_MODEL` | the 4 IMPORTED classes (97 source forms) | the detail lives here; this model is the source of truth for them |
| `AUTHORITATIVE_AT_SOURCE` | the 56 DEFERRED classes (332 source forms) and the 6 out-of-scope classes | the detail still lives in the declared legacy registry and is authoritative THERE until that class's DDI batch is complete AND independently reviewed |

The split is not prose: `authority` is a required, enum-constrained field of every `source-class` fact, both
verification paths enforce it, and the gate recomputes the totals above from the model. The model additionally
carries a `promotion` fact whose GLOBAL scope is **FORBIDDEN_UNTIL_DDI_COMPLETE** — a machine-checkable statement that global
single-source-of-truth status is withheld while any class remains authoritative at its source.

## 2c. Tracked-file inventory
36631 tracked paths are classified exactly once: 998 carry an individual `file` fact and 35633 are counted by 65 `dir-rule` facts.

## 3. Invariants affected
All model laws: L1 well-formedness (declared fact type, required keys, permitted value kinds, closed enum
domains), L2 one seat (duplicate seat, duplicate key, id owned by one type), L3 closed typed references against
each field's declared target universe, L4 acyclicity of every declared from/to relation, L5 public/private
isolation with every consumer of undecidable kind failing closed, L6 complete requirement->seat->test->WP
mapping, L7 exact module/hash universe with the model-root digest recomputed from the ordered pins.

## 4. Pass/fail evidence
- SBCL model-law kernel: **PASS** (exit 0). SHA-256 from a vetted external provider over raw bytes.
- Independent clingo checker (derives every model law from its own reading of the model): **PASS** (exit 0).
- Golden fixtures + generated property families, each run through BOTH paths: **PASS** — `golden fixtures=8  generated properties=83  failures=0`.

## 5. Independent-checker agreement
The two paths **AGREE**. Agreement is not asserted from two verdict strings: each path publishes a fact-set
commitment (total, per-module and per-family counts and digests) and the checker refuses to issue a verdict
unless its commitment is byte-identical to the kernel's. Commitment digest: `fcc68723880d4b2707d414f766305b218d99f3c029bd527ca2f9e9ffd2e2e618`.

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
The options below are bounded by the authority split in §2b-i. There is deliberately NO option to promote this
model as the global architecture source of truth, because 56 source classes covering 332 source forms are still
authoritative at their declared legacy sources; the model's own `promotion` fact records that state as **FORBIDDEN_UNTIL_DDI_COMPLETE**,
and it is the gate, not this prose, that enforces it.

- **APPROVE (bounded)** — accept this canonical model root as the source of truth **for the imported classes
  only**, leaving every deferred class authoritative at its declared legacy source. This authorizes a fresh
  independent review; it does NOT authorize DDI-1, and it does not make this model globally canonical.
- **REJECT** — discard; keep the registries as source.
- **DEFER** — request the fresh independent review before deciding anything.

Global single-source-of-truth status becomes available only after DDI-1…DDI-4 are complete and each has been
independently reviewed. Final canonical promotion requires the Root Operator's signed approval. This packet
asserts NO freeze, NO qualification, and NO independent verification: an internal PASS authorizes a fresh
independent review and nothing else.
