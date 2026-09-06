<!-- MECHANICAL PACKET SKELETON — headings, fields, tables, counts, inventories, generated references and the
     verdict skeleton of ROOT-OPERATOR-DECISION-PACKET.md. Review-3 §15 M3.
     {{name}} is replaced by a value RECOMPUTED from the canonical model at generation time; the gate recomputes
     every one of them again from the model and both verification commitments (`gate_checks.py packet`).
     {{block:name}} inserts an AUTHORED block from PACKET-ADJUDICATION.md verbatim. No authored rationale,
     normative reasoning, justification, risk acceptance or decision prose belongs in this file. -->
# ROOT-OPERATOR-DECISION-PACKET — canonical architecture model (initial import)

{{block:assurance}}

<!-- PACKET-RECONCILIATION
{{reconciliation}}
-->

## 1. Change summary
Initial import of the canonical ARCHITECTURE-MODEL: {{total-facts}} facts across {{modules}} hash-pinned modules,
migrated from the v1.6-v1.8 registries. Parent architecture commit `{{parent-commit}}`. Canonical model-root
digest `{{root-digest}}`, RECOMPUTED from the ordered module pins by both verification paths rather than read
from the file.

## 2. Affected model facts (per family)
| family | count |
|---|---|
{{family-table}}
| **total** | **{{total-facts}}** |

Per pinned module:

| module | facts |
|---|---|
{{module-table}}

## 2b. Migration-scope ledger — imported vs DEFERRED_DATA_IMPORT
{{block:ledger-note}}
Ledger verification (multiset-aware re-derivation from the sources): **{{ledger-verdict}}** — `{{ledger-line}}`.

| status | source-classes | source forms |
|---|---|---|
{{status-table}}

Deferred fact classes by finite batch, with the number of SOURCE FORMS each batch actually carries:
{{batch-summary}}
{{block:batch-note}}

### 2b-i. Typed authority split — what this model is, and is not, authoritative for
| authority | applies to | meaning |
|---|---|---|
| `CANONICAL_IN_MODEL` | the {{imported-classes}} IMPORTED classes ({{imported-forms}} source forms) | the detail lives here; this model is the source of truth for them |
| `AUTHORITATIVE_AT_SOURCE` | the {{deferred-classes}} DEFERRED classes ({{deferred-forms}} source forms) and the {{out-of-scope-classes}} out-of-scope classes | the detail still lives in the declared legacy registry and is authoritative THERE until that class's DDI batch is complete AND independently reviewed |

{{block:authority-note}}

## 2c. Tracked-file inventory
{{inventory-sentence}}

## 2d. Acceptance trusted computing base
{{tcb-sentence}}

## 3. Invariants affected
{{block:invariants}}

## 4. Pass/fail evidence
- SBCL model-law kernel: **{{kernel-verdict}}** (exit {{kernel-exit}}). SHA-256 from a vetted external provider over raw bytes.
- Independent clingo checker (derives every model law from its own reading of the model): **{{checker-verdict}}** (exit {{checker-exit}}).
- Golden fixtures + generated property families, each run through BOTH paths: **{{fixtures-verdict}}** — `{{fixtures-line}}`.

## 5. Independent-checker agreement
The two paths **{{path-agreement}}**. Agreement is not asserted from two verdict strings: each path publishes a
fact-set commitment (total, per-module and per-family counts and digests) and the checker refuses to issue a
verdict unless its commitment is byte-identical to the kernel's. Commitment digest: `{{commitment-digest}}`.

## 6. Independent AI review receipts and independence evidence
{{block:receipts}}

## 7. Unresolved / CONFLICTING items
{{block:unresolved}}

## 8. Worst credible consequence
{{block:consequence}}

## 9. Migration and rollback
{{block:rollback}}

## 10. Decision
{{block:decision}}
