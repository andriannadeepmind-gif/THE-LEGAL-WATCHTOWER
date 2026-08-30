# 05 — GROUND TRUTH: the repository today (B0)

Baseline: `andriannadeepmind-gif/THE-LEGAL-WATCHTOWER` @ commit `e621dbe1` ("B0").
Full census: `EVIDENCE/CENSUS-MASTER.md` (all 2,486 files classified; 169 executing
seats — gates/writers/stores/proofs; debt register of 13 P0 classes). Per-axis capability
grounding: `EVIDENCE/B0-capability-map.md`. Coverage/quality adversaries confirmed the
census 12/12 on real code (`EVIDENCE/census-*-adversary.md`).

## 1. What already runs (real code, above the commercial floor)

| Seat (B0 file) | What it does | Canon pillar it grounds |
|---|---|---|
| `authority-evidence-replay.lisp` | Recompute-and-compare source verification — trusts no stored datum; rebuilds from the original and diffs | P2/P3 grounding |
| `merkle-authority.lisp` | Single authoritative Merkle-committed write path | P1 single writer, P5 |
| `journal.lisp`, `memory.lisp` | Append-only journal chain; institutional memory | P5 |
| `version-graph.lisp` | Temporal state of law — "what was in force when" | P2 temporal validity |
| `inference-gate.lisp` (JTMS) | Justification-tracking inference; retracts conclusions when their base falls | P2/P5 retraction |
| Adversarial gates (release path) | Try-to-break-the-system checks before every release | P4 seed |
| `constitutional-dispatch.lisp` / constitutional gate | Rule-dispatch over actions | P1 seed — **defective, see below** |

## 2. What is broken or missing (the honest picture — 13 P0 classes, headline items)

1. **The admission kernel K does not exist as code.** `admission-model.sexp` is a spec;
   nothing implements the total/decidable/deterministic decider. (→ BO-02/03)
2. **Fail-open constitutional gate.** `constitutional-gate.lisp:44-45`: a rule that
   errors ALLOWS the action instead of blocking. Direct INV violation. (→ BO-02)
3. **Writes are not crash-safe** outside the single seat (e.g., `emit-graph`,
   `deploy.lisp`): interruption can leave torn state. (→ BO-13)
4. **0/17 formal theorems discharged** — proof toolchain (Lean) not runnable in the dev
   sandbox (network-blocked); CI path exists but unproven end-to-end. (→ P1 phase, BO-03…)
5. **Non-determinism residue** in the trusted path (intra-tier ordering, wall-clock
   leakage). (→ BO-11/12)
6. **No generative zone**: no scouts, no organ sockets, no multimodal ingestion — the
   entire L1/L3 side is design-only. (→ Phase P4)
7. **Legal coverage is minimal**: a handful of Greek norms formalized; ELI codification
   pipeline absent. This is the real bottleneck, conceded as content (out of
   architecture-supremacy scope, but on the critical path to usefulness). (→ Phase P5)
8. Citation validation clamp (≤120-char grammar shortcut), aggregate-only consolidation
   hashes, silent fallbacks, prose-typed UNKNOWN causes (`meta-ontology.lisp`) — each a
   named BO. (→ BO-20/21/22)

## 3. Delta statement (what "transformation" means)

B0 → Canon is a **re-seating, not a rewrite**: every running seat above is kept and
re-anchored under K (single point of issuance); every defect class is eliminated at its
seat (never guarded); everything absent (K itself, L1 scouts, L3 organs, ELI pipeline,
proof corpus) is built new under the invariant. The precise, file-anchored program is
`06-TRANSITION.md`.
