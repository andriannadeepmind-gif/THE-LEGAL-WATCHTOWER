# 07 — VERIFICATION REGIME (what VERIFIED means; what may be claimed when)

## 1. Status ladder and permitted claims (non-compensatory; UNKNOWN never counts as equal)

| Status | Requires | Permitted public/internal claim |
|---|---|---|
| DESIGN (current) | Canon complete; adversarial closure on the design | "Strongest design buildable today; foundations running above the commercial floor; every step named." |
| BUILT-PARTIAL | Phases P1..Pn exited with proofs | Per-phase factual claims only ("K is proven total/deterministic/fail-closed"). |
| BUILT | All BO-01..41 discharged; all proofs machine-checked (zero sorry, zero undeclared axioms) | "Every trusted answer carries an independently checkable proof." |
| VERIFIED | BUILT + independent reproduction + backtesting regime passed | "Empirically dominant on adjudicated matters; independently reproduced." |
| SUPREME (relative) | VERIFIED + standing adversarial closure maintained | The `01-INVARIANT.md` claim, with its axioms and residue stated. |

Claiming above the current rung is itself an INV violation; the system (and its builder)
must be structurally unable to do it.

## 2. Adversarial review protocol (every phase, before every proof)

Independent fresh-context adversaries (no access to the implementer's reasoning), two
mandatory axes: (a) **break-the-design** — attack the model/security; (b)
**mediocrity-hunt** — patches, wrappers, duplicate seats, silent fallbacks, tautological
tests. Every finding: closed AT ITS SEAT, or refuted with proof, or declared a residue
with a kill-phase. Findings and dispositions are appended to `EVIDENCE/` verbatim —
the proof that the search happened.

## 3. Backtesting protocol (the "beats elite teams" claim, made measurable)

- Corpus: adjudicated Greek matters (outcomes hidden), stratified by domain and era.
- Blind replay: the system receives the case file as of filing date (temporal view
  enforced by BO-10 — no hindsight leakage), produces strategy + pleading.
- Metrics: predicted-disposition accuracy; prevail-rate of the chosen line vs. the
  historical line; calibration (Brier) of pre-registered confidences (BO-29); citation
  validity rate (must be 100% by construction — any miss is a P0).
- Baselines: the historical human teams' actual filings; optionally contemporary
  commercial tools on the same blinded input.
- All runs pre-registered in the P5 ledger; results are replayable arithmetic.

## 4. Independent reproduction

A second, unaffiliated party rebuilds the checker from spec (foundationally distinct
kernel preferred), re-verifies the full certificate corpus, and re-runs the replay
bundle bit-for-bit. Divergence anywhere = not VERIFIED. The non-blocking
second-foundation cross-check flags (never blocks) the highest-stakes tier.

## 5. Builder protocol & self-evolution (BO-33 — the build itself obeys INV)

- The AI builder proposes; it never merges. Every diff lands only through: machine
  checks (proof CI green, gates green, mutation tests green) + creator approval
  («εγκρίνω»), with the commit-identity and artifact-hygiene rules of `START-HERE.md`.
- **Self-evolution (SEV) — the autopoietic loop:** the weaknesses it hunts are the
  SYSTEM'S OWN (a standing self-adversary attacks the proofs, organs, coverage
  boundaries, security posture and performance of the system itself — distinct from
  case-level opponent simulation). The mature system runs the whole loop autonomously —
  detect self-weakness → design → implement → execute in an isolated sandbox →
  replay-regress the full P5 corpus → package an upgrade certificate — and the creator's
  role collapses to reading the certificate and approving. It also self-maintains:
  regenerates broken components, refills deprecated model sockets, restores health
  invariants within proven bounds. Autopoietic in labor, heteronomous in authority. An upgrade without a valid certificate is
  unrepresentable at the gate; a self-merged upgrade is structurally impossible. This is
  the A4-supreme form of self-improvement: full autonomy of labor, zero autonomy of
  authority.
- The builder's self-reports are untrusted by definition; capability claims in docs are
  marked demonstrated-vs-declared.
- Session continuity: all decisions land in the repo dialogue protocol
  (`deployment/collab/dialogue/`, append-only) — no design state may live only in a
  conversation.

## 6. Standing instruments

- The 22 frozen measurement instruments and ceilings remain the per-axis measurement
  annex: `EVIDENCE/frozen-instruments-v2.json`, `EVIDENCE/22-ceilings-v2.json`.
- The mutation-adversary test (P4 invariance guard) runs in CI permanently: decided
  outputs bit-for-bit invariant under prior perturbation.
- The one-round absorption law is tested as a law: every ingested novel opponent move
  must produce a stored counter within one procedural window in the replay demo.
