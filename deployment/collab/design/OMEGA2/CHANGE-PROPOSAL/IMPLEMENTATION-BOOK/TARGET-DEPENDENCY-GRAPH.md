# TARGET-DEPENDENCY-GRAPH — LAWMAX OMEGA Public Observatory (Implementation Book v1.1)

**Bound to frozen SHA `88129099`.** Design-only. This is the **TARGET** (to-build) subsystem
**derivation** graph. It is distinct from two other graphs, which must never be conflated:
- **AS-IS source graph** — `tools/asis-inventory.py` → `AS-IS-ASDF-GRAPH.tsv` (16 ASDF systems,
  acyclic) + `AS-IS-PACKAGE-EDGES.tsv` (226 qualified-ref edges, APPROX lower bound).
- **WP scheduling DAG** — Book v1.1 §5 (execution order WP-00..WP-14).

**Executable check:** `tools/target-depgraph-check.py` (exit 0 = valid). It proves the graph is
acyclic, carries no forbidden edge, has a single write authority per store, and isolates compiler
A/B — and it is **non-vacuous** (self-tests by injecting each forbidden edge and asserting the
detector fires).

## 1. NODES (18 subsystems, Book §2; S8 refined into A/B/gate)
`S1` Census/Radar · `S2` Acquisition/Ingress · `S3` Neuro-symbolic bridge (PLANE-3) ·
`S4` Symbolic Legal-IR core · `S5` Bitemporal event store (L1/L2) · `S6` Hypergraph ·
`S7` Jurisprudence plane · `S8` Dual compilation (`S8a` compiler A · `S8b` compiler B ·
`S8g` comparison/quarantine gate) · `S9` Proof-carrying query · `S10` MLTP trust layer ·
`S11` Security cells / custody · `S12` Cockpit · `S13` Website · `S14` API/MCP/SDK ·
`S15` Observatories · `S16` Source-type registry · `S17` Ontology governance · `S18` Public→private boundary.

## 2. ALLOWED EDGES (derivation: `A → B` = "A is derived from / depends on B's output")
Roots (depend on nothing): `S11`, `S16`, `S17`, `S18`.
```
S1→S16
S2→S1, S2→S16
S3→S2, S3→S17
S4→S2, S4→S3, S4→S16, S4→S17
S5→S4
S6→S5, S6→S4
S7→S5, S7→S6, S7→S4
S8a→S5, S8b→S5, S8g→S8a, S8g→S8b, S8→S8g
S9→S8, S9→S6, S9→S7, S9→S10
S10→S11
S12→S9, S12→S18
S13→S8, S13→S9
S14→S9, S14→S10
S15→S8, S15→S9, S15→S10, S15→S13, S15→S14   (read-only metric edges)
```
A valid topological order (proves acyclicity): `S11, S16, S17, S18, S1, S2, S3, S4, S5, S6, S7,
S8a, S8b, S8g, S8, S10, S9, S12, S13, S14, S15`.

## 3. FORBIDDEN EDGES/PATTERNS (any present ⇒ check FAILS)
| id | forbidden | why |
|---|---|---|
| **F1** | `S5→S3` (event store derives directly from neural PLANE-3) | neural is non-authoritative; every candidate must pass the `S4` symbolic gate (I-4.3a) |
| **F2** | `S4→RAWEVAL` (core evaluates external bytes as Lisp forms) | external bytes ≠ Lisp forms; only the non-evaluating decoder crosses the boundary (Secure Ingress §0) |
| **F3** | `S8a↔S8b` (compiler A and B share any derivation) | dual independence: no shared evaluator/build/lock/key; they meet only at `S8g` |
| **F4** | `S5/S8/S8a/S8b ← S12/S13/S14` (core store derives from cockpit/site/API) | public services are **projections only**, never a second source of truth |
| **F5** | any store with ≠1 write authority | single write seat per store (below) |
| **F6** | cockpit as a `release_root` writer | cockpit emits signed intent → M5; never direct-publish (VS-14, KW-57) |

## 4. DATA OWNERSHIP + WRITE AUTHORITY (single seat per store)
| store | owner / write authority (one seat) | rule |
|---|---|---|
| `L1_journal` (Event Ledger) | `write-authority.lisp` | append-only; every write journaled; proposer-blind; intents enter here as events, not as releases |
| `PLANE0_vault` (bytes) | `corpus-provenance.lisp` | append-only; no external/public writer; loss ⇒ typed UNKNOWN, never cache-fill |
| `release_root` | `release-authority.lisp` (via M5) | only after dual-attestation A=B; single canonical root |
| `census_universe` | `ingestion-daemon.lisp` | root-signed `RegistrySnapshot`; total-function coverage |
| `trust_root` | `authority-v2/` custody | n-of-m + witnesses; single-zone ≠ canonical authority |

Cockpit intent flow is a **write** (`S12` appends an intent-event through `write-authority.lisp`,
proposer-blind), **not** a derivation edge — which is why `S12` is a graph source and no
`S8/S9/S12` request/response cycle appears in the derivation DAG.

## 5. CHECK OUTPUT (reproducible)
```
python3 tools/target-depgraph-check.py
  nodes=21 edges=36 write-stores=5
  [PASS] acyclic derivation graph
  [PASS] no forbidden edge/pattern
  [PASS] non-vacuity self-test (F1:detected, F3:detected, F4:detected, F5:detected, cycle:detected)
  ### TARGET GRAPH VALID   (exit 0)
```
Any future WP that introduces a forbidden edge (e.g. a neural write to the journal, or a shared
A/B dependency) makes this check exit 1 — the gate that keeps construction inside the frozen
architecture.
