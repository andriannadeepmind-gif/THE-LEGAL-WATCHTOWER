# LAWMAX OMEGA — PUBLIC OBSERVATORY IMPLEMENTATION BOOK v1.1 (CONSTRUCTION-DETAIL CLOSURE)

**ΚΑΤΑΣΤΑΣΗ: `IMPLEMENTATION BOOK v1.1 CONSTRUCTION-READY — EXECUTION NOT AUTHORIZED`.**

```
BOUND_FROZEN_SHA = 88129099be1ad69feb80d40337ede6c286b83223   (SPEC unchanged, frozen)
RELATION_TO_v1.0 = v1.0 stays the master EXECUTION MAP (subsystems, WP order). v1.1 adds
                   CONSTRUCTION DETAIL (reconciled inventory, machine dep-graph, per-WP files,
                   toolchain freeze, machine traceability). One seat per concept — v1.1 does not
                   restate v1.0's map; it refines it. No frozen NORMATIVE file was modified.
```
No new architecture, ceiling search, swarm, destruction pass, implementation or refactoring. No
code was written/moved/refactored. `RAW-JOURNAL-PARTIAL.jsonl` untouched. Reproducible checks live
under `IMPLEMENTATION-BOOK/tools/` (they are verifiers over the frozen repo + this book, the same
class of artifact as `V1.4-CONTRADICTION-OMISSION-AUDIT.sh` — not system code).

## §1. INVENTORY RECONCILIATION (deliverable 1 — reproducible, not asserted)
Check: `python3 IMPLEMENTATION-BOOK/tools/inventory-reconcile.py` → exit 0 (7/7 PASS).

Two **distinct** denominators were conflated in v1.0; v1.1 separates them:
- **181 = the Lisp universe** = `source/*.lisp` (133) + `systems/orchestrator-cli/*.lisp` (48). Each
  file carries **exactly one** disposition in crosswalk §A.3/§A.4 (§A.3+§A.4 = 181 tokens):
  **KEEP(REUSE) 119 · MODIFY(EXTEND) 52 · REPLACE 0 · REMOVE 2 · DEFER-KEEP(DEFER_PRIVATE) 8 = 181.**
- **249 = the whole-§A component universe** = disposition tokens over files **and** directories **and**
  doc-families across all five sub-tables: A.1 arch docs 18 + A.2 canonical texts 26 + A.3 source 133
  + A.4 cli 48 + A.5 verify/scripts 24 = 249. By token: REUSE 155 · EXTEND 75 · REPLACE 7 · REMOVE 4
  · DEFER_PRIVATE 8. **249 − 181 = 68 non-lisp tokens.**
- **"0 orphan" is now proved, not claimed:** the check asserts every one of the 181 lisp files is
  listed exactly once in §A.3/§A.4 (0 missing, 0 extra). **REPLACE among lisp files = 0** (all 7
  REPLACE are non-lisp docs/CI); **REMOVE among lisp files = 2** (`blockchain-authority.lisp` +
  `systems/orchestrator-cli` one). v1.0's "REMOVE 4 / REPLACE 7 over files" was the §A token count,
  not the lisp count — corrected here.

## §2. AS-IS DEPENDENCY INVENTORY (deliverable 2 — machine-reproducible)
Tool: `python3 IMPLEMENTATION-BOOK/tools/asis-inventory.py` → `AS-IS-FILE-INVENTORY.tsv`,
`AS-IS-ASDF-GRAPH.tsv`, `AS-IS-PACKAGE-EDGES.tsv`.
- **file → package → top-level symbols** : SOUND (syntactic). 181 files, 131 distinct packages, **4053
  top-level defined symbols**, 1 CFFI/foreign-binding file (the libsodium seat — no homemade crypto).
- **ASDF system graph** (declared, authoritative): 16 systems, 53 orchestrator-internal edges,
  **dependency cycle = NONE**. This is the **real source dependency graph**, kept **separate** from
  the WP scheduling DAG (§5) and the target derivation graph (§3).
- **package → package edges**: 226, an **APPROX lower bound** from *qualified* references
  `orchestrator.X:sym` only.
- **Declared UNKNOWN (honest):** unqualified references, macro-generated calls, runtime
  `INTERN`/`FIND-SYMBOL`, and generic dispatch are **not** statically provable and are reported as
  UNKNOWN, never as 0. A fully sound Lisp call graph is undecidable here.

## §3. TARGET DEPENDENCY GRAPH (deliverable 3 — allowed/forbidden, with a failing check)
Doc: `TARGET-DEPENDENCY-GRAPH.md`. Check: `python3 IMPLEMENTATION-BOOK/tools/target-depgraph-check.py`
→ exit 0. It proves the target subsystem **derivation** graph is acyclic (21 nodes, 36 edges), carries
no forbidden edge, has one write authority per store, and isolates compiler A/B — and it is
**non-vacuous**: it self-tests by injecting each forbidden edge (F1 neural→journal, F3 A↔B, F4
core←public, F5 multi-write, and a cycle) and asserts the detector fires (5/5 detected). Data ownership
+ write authority (single seat per store) are in the doc; cockpit intent is a **write** (through the
one `write-authority.lisp` seat, proposer-blind), not a derivation edge — which is why no
request/response cycle appears.

## §4–§5. ELEMENT DETAIL + WORK PACKETS (deliverables 4, 5, 8, 10)
`WORK-PACKETS/WP-00.md` through `WP-14.md` — one executable file per packet. Each carries: Requirement →
rationale → architecture seat → **exact files/symbols** (path · package/domain · disposition · public
surface) → contracts (input/output schemas, error taxonomy, forbidden dependencies, data ownership) →
ordered edits → tests/kill tests → exact commands → toolchain freeze / decision gate → migration →
rollback → evidence → **binary exit gate** → paper dry-run (bound to its vertical slice). The WP
scheduling DAG (execution order, distinct from §2/§3) is v1.0 §5: critical path 0→1→2→3→4→6→11→12→13→14.

**Construction-detail granularity (honest):** NEW/MODIFY elements are specified at the **contract +
key-symbol** level (closed types, I/O schemas, error taxonomy, ordered edits, exit gate). The exact
per-parameter Lisp lambda-list / Rust signature of each new symbol is **derived from the frozen
contract during that WP's first edit** — a mechanical derivation from a frozen schema, not a new design
decision (so each WP stays executable without new design).

## §6. PUBLIC LEGAL DISCERNMENT ENGINE (deliverable 6 — full synthesis, no new seat)
The engine is the **composition** of existing subsystem seats, orchestrated as one end-to-end pipeline
(WP-07 → WP-08 → WP-09 → WP-11). No second engine, no new seat:
```
L5 hypothesis branching        proposals.lisp / fluid-induction.lisp        (WP-07, PLANE-3→candidate)
 → Legal IR                    legal-ast.lisp (typed, non-executable)       (WP-03)
 → symbolic/deontic/defeasible  legal-inference-engine / legal-deontic /     (WP-08)
   reasoning                    legal-event-calculus.lisp
 → argument / counterargument   legal-dialectic.lisp (open_objections)       (WP-08)
 → L6 adversarial review        review-service.lisp / review-queue.lisp      (WP-12, proposer-blind M5)
 → jurisprudence authority      citation-authority.lisp / line-of-authority  (WP-09, authority_weight)
   weighting
 → typed uncertainty / conflict USC §8 / ConflictPolicyBundle (adopted)      (WP-08; absent⇒UNKNOWN,
                                                                              incompatible⇒CONFLICTING)
 → InstitutionalAct adoption    reviewer_adoption_act (kid)                   (WP-09, KW-36)
 → proof-carrying answer        proof-carrying.lisp / proof-carrying-answer/1 (WP-11)
```
Invariant of the whole: **discernment = proof-carrying distinction (IN / OUT / UNKNOWN with proof or
typed abstention), never a guess.** A schema-valid candidate that passes structural+symbolic validation
stays VALIDATED, never ADOPTED/CANONICAL without provenance + authorized source/competence + adoption
policy (Secure Ingress §4). One write seat (`write-authority.lisp`); neural never writes the journal.

## §7. COMPILER A / B PHYSICAL SEPARATION (deliverable 7)
| axis | domain A (WP-04) | domain B (WP-05) | meeting point |
|---|---|---|---|
| language | Common Lisp (SBCL) | Rust | — |
| code | `orchestrator.consolidation` seats | `compilers/legal-compiler-b/` crate | **none shared** |
| build image | image A (SBCL) | image B (Rust) | **none shared** |
| dependency lock | `deps.lock`-A | `Cargo.lock`-B | **none shared** |
| signing key | `kid_A` (delegated) | `kid_B` (delegated) | **none shared** |
| hashing | ironclad SHA-256 | RustCrypto SHA-256 | — |
| output | `legal_state_root_A` | `legal_state_root_B` | **`S8g` comparison/quarantine gate** reads both roots as opaque bytes |
No shared evaluator code, build image, dependency lock, or signing key between A and B — enforced by
`target-depgraph-check.py` F3 (`S8a↔S8b` forbidden). They meet only at the independent gate `S8g`,
which never lives inside A or B; divergence ⇒ `compiler-divergence` ⇒ `QUARANTINED`, 0 releases.

## §8. TOOLCHAIN FREEZE / DECISION GATES (deliverable 8 — no homemade crypto)
| WP | frozen now | decision gate (criteria pre-specified; mechanical pick, no new design) |
|---|---|---|
| WP-00 | SBCL, Docker, cosign, fiveam | WP-00-a: pinned SBCL version + base image digest (reproducible, maintained LTS) |
| WP-01 | SBCL, drakma, local-time, ironclad SHA-256 | WP-01-a: court publishability list (U-7, external); WP-01-b: freshness budgets (U-1) |
| WP-02 | SBCL, jonathan/yason (post-decoder), cxml (entities off), chipz (caps) | WP-02-a: sandbox isolation mechanism (capability-less, out-of-process, deterministic) |
| WP-03 | SBCL, local-time, TLA+/TLC | — |
| WP-04 | SBCL, ironclad, canonical-representation | — |
| WP-05 | Rust | WP-05-a: Rust edition + minimal crate set (U-5; no crate shared with A semantics, own Cargo.lock) |
| WP-06 | Ed25519 (libsodium 1.0.18 / Go crypto/ed25519 / Node OpenSSL), RFC 3161, FROST-Ed25519 | WP-06-a: ML-DSA backend (FIPS 204 + **official NIST ACVP/KAT vectors**, maintained); WP-06-b: registries (U-2) |
| WP-07 | Python + ONNX Runtime (external, PLANE-3), cxml/SHACL | WP-07-a: held-out set + threshold (U-6/U-1); WP-07-b: neural model/runtime pin (reproducible manifest) |
| WP-08 | SBCL (all reasoning is repo Lisp) | — (substantive conflict canons = legal review, PENDING_LEGAL_VALIDATION) |
| WP-09 | SBCL, ECLI/ELI emitters | WP-09-a: doctrine/full-text licensing + anonymization policy (U-3, external) |
| WP-10 | SBCL, cxml/RDF/SHACL | — |
| WP-11 | OpenAPI 3.x, jonathan/yason, cxml, SDKs Py/TS/Rust | WP-11-a: SDK packaging/versioning (LOC-ceiling, no trust logic) |
| WP-12 | SBCL http-server | WP-12-a: app-shell front-end stack (renders only proof-carrying answers + dual citation) |
| WP-13 | Prometheus, SBOM scanner | WP-13-a: final RTO/RPO numbers (U-1) |
| WP-14 | all prior toolchains (regression) | WP-14-a: independent auditor set (U-2, **hard external gate**) |
**Cryptography rule (enforced):** only named, maintained backends (libsodium, Go crypto/ed25519,
Node/OpenSSL, RustCrypto, a FIPS-204 ML-DSA library) with **official test vectors**. Homemade
cryptography is forbidden (the experimental `ed25519_pure.py` was already removed pre-freeze).

## §9. MACHINE TRACEABILITY (deliverable 9)
Build+check: `python3 IMPLEMENTATION-BOOK/tools/traceability-build.py` → `TRACEABILITY-MACHINE.tsv`,
exit 0. One row per **R-01..R-134**: Requirement → WP → subsystem → seat file → test(Q/KW/VS) →
evidence. **134/134 requirements map to exactly one WP** (verified), each with a non-empty seat and test
(R-118 = the predeclared programme, explicitly not executed). Symbol column: bound at the WP-element
granularity for the **construction surface** (new/modified symbols). **Honest UNKNOWN:** per-symbol
Requirement+test binding for the **4053 pre-existing REUSE symbols** is NOT done in this pass — those
files are KEEP (consumed as-is, verified per `AS-IS-EVIDENCE-MANIFEST.md`); their per-symbol legal/
functional binding is evidence category [3] (legal review) / [4] (security tests), never faked as bound.

## §10. PAPER DRY-RUN (deliverable 10 — not "presence of words")
Each `WP-nn.md` carries a **paper dry-run** with a concrete input, expected output, failure path and
rollback, **bound to its frozen vertical slice** (`VERTICAL-SLICES.md` VS-01..15), which already fix a
defined input, ordered steps, a printed expected output, a negative witness (3–5 mutations) and a binary
exit criterion. A WP passes its dry-run only when both the positive scenario and its negative witness
yield the defined typed result — never from the mere presence of a table. Slice→WP coverage: VS-01
(WP-02/03/04/11), VS-02 (WP-03/10), VS-03 (WP-02), VS-04/05 (WP-07), VS-06/07 (WP-08), VS-08 (WP-09),
VS-09/10 (WP-05), VS-11 (WP-06/11), VS-12 (WP-06), VS-13 (WP-01), VS-14 (WP-12), VS-15 (WP-00/13).

## §11. CLOSED vs GENUINELY UNKNOWN (the honest ledger)
**CLOSED in this pass (reproducible where marked):**
1. Inventory reconciliation 181 vs 249, single denominator per category, 0-orphan proved — `inventory-reconcile.py` exit 0.
2. AS-IS dependency inventory (file→package→symbol→qualified-refs→disposition, ASDF graph acyclic) — `asis-inventory.py`, 3 TSVs.
3. Target dependency graph: allowed/forbidden edges, data ownership, single write authority, acyclic, non-vacuous forbidden-edge check — `target-depgraph-check.py` exit 0.
4. 15 executable WP files with the full 12-field structure + binary exit gate + rollback + paper dry-run.
5. Public Legal Discernment Engine synthesis (composition, one seat each, no second engine).
6. Compiler A/B physical separation (language/code/image/lock/key), gate-enforced.
7. Toolchain freeze table with per-WP frozen tools + enumerated decision gates; no-homemade-crypto rule.
8. Machine traceability R-01..R-134 → one WP each, non-empty seat+test — `traceability-build.py` exit 0.

**GENUINELY UNKNOWN / decision-gated (finite, explicit — none is an architecture decision):**
- **Standing externals U-1..U-8** (frozen as per-WP entry conditions): U-1 SLO/freshness/RTO/RPO numbers
  (measurement), U-2 auditor+witness registries (institutional), U-3 doctrine/full-text licensing +
  anonymization (external), U-4 benchmark verification (external), U-5 Rust crate set (WP-05-a), U-6
  held-out truth set (WP-07-a), U-7 court publishability list (WP-01-a), U-8 AS-IS R-1..6 executable
  tests (close at WP-00).
- **Per-WP library/version picks** (criteria frozen, mechanical selection): WP-00-a, WP-02-a, WP-05-a,
  WP-06-a (ML-DSA + NIST vectors), WP-07-b, WP-11-a, WP-12-a. WP-14-a (auditor set) is a **hard external
  gate**, not a design pick.
- **Per-parameter formal signatures** of the ~30 NEW symbols: derived from the frozen contract at each
  WP's first edit (mechanical, not new design) — specified here at contract+key-symbol level, not per-lambda-list.
- **Per-symbol Requirement+test binding for the 4053 pre-existing REUSE symbols**: UNKNOWN — evidence
  category [3]/[4], not this documentation pass.
- **Static Lisp caller-graph soundness**: the package-edge graph is an APPROX lower bound; unqualified/
  dynamic references are UNKNOWN (undecidable). Declared, not hidden.
- **Legal content**: all ST entries + substantive classifications remain `PENDING_LEGAL_VALIDATION`
  (evidence category [3]). SIK-1..9 remain UNEXECUTED (executed at WP-02).

**Why CONSTRUCTION-READY and not BLOCKED:** the architecture is frozen and complete (0 open
architecture decisions); the inventory is reconciled and orphan-free (reproducible); the dependency
graph is acyclic with an enforced, non-vacuous forbidden-edge check; every requirement traces to exactly
one WP with a test; every WP has contracts, ordered edits, a binary exit gate, rollback and a paper
dry-run. Every remaining item above is a **per-WP entry condition** (an external U-n or a library pick
with pre-specified criteria) that resolves just-in-time before that WP — **not** a blocker of the map or
of any WP's construction plan. No WP requires a new architecture or design decision to begin.

## §12. STATUS
`IMPLEMENTATION BOOK v1.1 CONSTRUCTION-READY — EXECUTION NOT AUTHORIZED`.
No Work Packet starts without the separate creator order `ΕΓΚΡΙΝΩ IMPLEMENTATION BOOK — ΞΕΚΙΝΑ WORK PACKET 0`.
