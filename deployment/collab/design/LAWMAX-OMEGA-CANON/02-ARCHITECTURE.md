# 02 — ARCHITECTURE (derived from INV; nothing here is an add-on)

## 1. Three layers, one boundary

```
 L1  SCOUTS (untrusted watchers)          — continuously observe official sources:
     ΦΕΚ/Government Gazette, court decision registries, doctrine/legal literature.
     They fetch, extract, PROPOSE. Zero authority. May be wrong; may be fed fakes.
        │  proposals (candidate law / candidate decisions / candidate doctrine)
        ▼
 GATE  ADMISSION KERNEL K (trusted, tiny) — total, decidable, deterministic; the ONLY
     component that admits anything into the world or issues anything out of it.
     Fail-closed: exception ⇒ refusal. Every "no" is recorded.
        │  admitted, provenance-sealed, temporally-stamped objects
        ▼
 L2  VERIFIED LEGAL WORLD (the only truth) — statutes-as-code (ELI-keyed), case law as
     precedential constraint, doctrine as defeasible argument material, all with
     provenance, temporal validity intervals, tamper-evident memory.
        ▲  reads (whole world)                    │ certified conclusions
        │                                          ▼
 L3  MIND (untrusted, multi-model faculties) — analysis, strategy, drafting, simulation.
     Reads everything; decides nothing. Every conclusion it wants trusted goes back
     through K with a certificate.
```

The L3/L2 boundary is the most important line in the system. Blur it and the design
regresses to "trust the model" — the commercial floor.

## 2. The five pillars — as consequences of INV, with all sharpenings native

### P1 — TRUST INVERSION
All intelligence (LLMs, agents, faculties) is untrusted and only proposes; a tiny, total,
decidable, deterministic admission kernel **K** is the only decider. Physical single
writer; external cosigning witness quorum for the authoritative log. Fail-closed
everywhere: a crashed check can never yield a green. **Native clause (multi-model
mandate):** the untrusted side is specified as *sockets for every available frontier
model*, all competing to propose, none identified in the trusted path — this is what
makes dominance-by-inclusion (`00-MISSION.md` §3) real. Consequence of INV: since no
proposer is trusted, proposer strength is pure upside; unlimited AI power is safe by
construction.

### P2 — LAW-AS-CODE with an honest boundary
Where law is computational — deadlines, thresholds, amounts, procedural steps, elements
of a claim — statutes compile to executable formal objects (Catala-class δ-calculus;
default logic with exceptions), keyed by ELI, carrying temporal validity
`[in-force-from, in-force-to]`. Subsumption becomes computation. Case law enters as
**precedential constraint** (Horty-style factor-based forcing), a distinct knowledge type.
Doctrine enters only as **defeasible argument material** — a position that can lose,
never ground truth. Where law is open-textured (good faith, proportionality), the system
builds structured defeasible arguments over an acceptance relation satisfying the
Caminada–Amgoud rationality postulates — never fake code. **Native clause (declared
coverage boundary):** the construal generator's coverage boundary is a first-class typed
object; K is architecturally incapable of emitting an unqualified "complete" — every
completeness verdict carries the stamp "relative to declared coverage C", and a missing
coverage certificate is a hard refusal.

### P3 — ANSWER-AS-PROOF
Every trusted conclusion ships a machine-checkable certificate, checked by a **minimal,
itself-verified, independently reproducible checker**; trust bottoms out at mathematics,
not at any vendor, model, or program. Open-texture conclusions ship structured arguments
with explicit assumptions instead of proofs (typed differently — never conflated).
**Native clause (reproduction discipline):** independent reproduction prefers a
foundationally distinct kernel where naturally expressible; a second-foundation
cross-check runs as a NON-blocking flag for the highest-stakes tier only (blocking
unanimity was adjudicated compensatory — worse liveness — and rejected; see EVIDENCE).
**Native clause (tribunal-adoption output contract / outcome sovereignty):** winning is
adoption, not possession. A deterministic compiler renders every certified conclusion into
the tribunal's own issuing schema — confirmed facts → law by ELI citation → node-by-node
subsumption → operative part — each node linked to re-fetchable provenance, minimizing the
judge's verify-and-sign cost. Two hard constraints: no LLM between certification and
emission; open-texture nodes are structurally flagged in the output type, never
stylistically softened.

### P4 — ADVERSARIAL EXHAUSTION
The engine does not "find good arguments"; it **enumerates the opponent's whole
move-space and certifies the line that dominates it**, over verified law and confirmed
facts. **Native clause (interpretive completeness / the Qualifikation lattice):** the
search domain is the pruned product
`{admissible construals of each open predicate} × {admissible fact-characterizations} × {moves}` —
because the elite adversary's highest-value move is shifting the characterization
(sale-vs-lease, employee-vs-contractor), not playing inside a fixed reading. Each
construal is emitted by an untrusted generator and admitted only with a real,
re-fetchable supporting authority; readings dominated by higher-priority interpretive
canons are pruned; completeness verdicts are coverage-stamped (P2 clause). **Native
clause (preclusion control):** exhaustion is lifted from reactive node-dominance ("we can
win every line") to a forward controllable-predecessor / safety-game fixpoint over the
irreversibility doctrines of P2 (res judicata/δεδικασμένο, estoppel, waiver,
prescription/παραγραφή, procedural defaults), emitting **preclusion certificates**: a
whole class of opponent moves is provably inadmissible and stays empty under all
reachable play — deleting a branch strictly dominates winning it — PLUS a mandatory
second proof that the same irreversibility does not adversely self-bind the client.
**Invariance guard:** empirical priors (judge/opponent models) may order search, never
prune; a mandatory mutation-adversary test proves the enumerated set and the decided
output are bit-for-bit invariant under any prior perturbation.

### P5 — PERFECT, VERIFIED, REPRODUCIBLE MEMORY
Every matter, fact, argument, judge behavior, and decision lands in tamper-evident,
append-only, Merkle-committed (RFC 6962-class) memory, replayable bit-for-bit; the firm
gets monotonically smarter and never forgets; every past answer re-derives identically.
**Native clause (realized-outcome loop):** the memory is also a falsifiable experiment
log — BEFORE an outcome, each open-textured argument line is pre-registered with a
MECHANICALLY-APPLICABLE reference-class predicate and a predicted disposition; the later
provenance-anchored judgment closes the prediction; confidence becomes replayable
arithmetic (prevail rate, Brier score, n) over the pre-registered class —
proof-carrying-over-data, never a model self-report. Anti-gerrymandering guard is
mandatory: predicates pre-registered and mechanically applied; a thin class yields an
honest UNKNOWN. **Native clause (actor-keyed views):** per-judge / per-opponent /
per-firm indices over the same memory (lawful, public-record-sourced), feeding search
ordering only (see P4 invariance guard).

## 3. The one-round absorption law (system-level behavior)

Any weapon revealed against the firm (a filing, an argument, a characterization shift) is
ingested by L1/L3, verified against L2, countered within the procedural response window,
and stored permanently in P5 — the opponent's innovation becomes the firm's asset after
one use. This is a consequence of P1+P4+P5, stated as a law so it is tested as one.

## 4. Four-valued answer discipline

Every query resolves to exactly one of: **PROVED / REFUTED / UNKNOWN /
STABLE-UNDER-UNKNOWN** (robust whichever way the unknown part falls) — with certificate,
coverage stamp, and assumption list. No fifth value exists; confident guessing is
unrepresentable.

## 5. Threat model — the opponent attacks the SYSTEM, not just the case

The elite adversary's cheapest move may be against the weapon itself. Structural answers:

- **Adversarial input (prompt injection).** Opponent filings, exhibits, and scraped
  sources are ATTACKER-CONTROLLED content consumed by LLM organs. Injection resistance is
  structural (P1: organ output is only ever a proposal), but two further guarantees are
  mandatory: (a) organs run with **no egress** except their typed proposal channel — an
  injected instruction can steer a proposal, never exfiltrate or write; (b) a standing
  **injection test-suite** in CI feeds hostile filings to every organ and asserts the
  decided output is unchanged (same discipline as the prior-perturbation test).
- **Source poisoning.** A fake or tampered "law/decision" cannot enter L2: admission
  recomputes from the authoritative source and seals provenance (P2/K). Poisoning the
  scout only wastes the scout.
- **Confidentiality & privilege (δικηγορικό απόρρητο).** Client and strategy data never
  reach an external model API unprotected. The inference boundary is a typed gateway with
  exactly three creator-selectable postures per data class: on-prem/local inference;
  redaction/minimization before external inference; or no external inference. The gateway
  is the ONLY egress path to any model vendor (one seat).
- **Keys & storage.** Writer and witness-quorum signing keys in HSM-class custody with
  rotation; private partitions encrypted at rest; key ceremonies recorded in P5.

## 6. Operating-mode ladder (typed system states, not improvisation)

- **FULL** — all organ sockets live (external + local models).
- **DEGRADED** — local/on-prem models only (vendor outage or confidentiality posture).
- **MANUAL** — zero LLM: humans enter structured facts; the entire trusted spine
  (K, subsumption, exhaustion over the compiled space, deadlines, proofs, memory)
  operates at full guarantee. Loss of speed and autonomy, never of truth.
Mode is a recorded, typed state; every certificate names the mode it was produced under.

## 7. The real-time layer (courtroom & client meetings) — precompute, then navigate

Live settings cannot run heavyweight certification. The design principle: **everything
certifiable is certified BEFORE the live session; the live layer is an untrusted
navigator over that precomputed body.** The P4 exhaustion tree already holds a prepared,
certified counter for every anticipated opponent move — live support is therefore
**lookup + flagging at speech latency**, not fresh computation. A genuinely novel move is
flagged honestly as NOVEL (never improvised as if prepared) and queued for the
recess/next procedural round — the one-round absorption law at zero navigation latency.
Live outputs are proposals on the lawyer's private screen; the lawyer speaks. Local
(on-prem) models are the default inference posture for live audio (privilege). Audio
capture posture is venue-typed: courtroom recording in Greece may require the court's
leave — the live organ runs identically in NO-AUDIO mode (a human types cues; navigation
is unchanged); client meetings record only with logged consent.

## 8. Change without demolition (the experimentation fabric)

"Try things without tearing anything out" is a structural property, derived from one
rule: **interfaces frozen, implementations swappable.**

- **Frozen interfaces:** an organ is anything that speaks the typed proposal protocol;
  K's admission interface and the certificate formats are the only sacred surfaces.
  Anything behind them can be replaced, duplicated, or retired freely.
- **Typed configuration, not code edits:** postures, thresholds, socket rosters, and
  feature flags are versioned P5 objects — changing behavior is a recorded config
  change, reversible by construction.
- **Shadow workspaces:** any candidate change (new organ, new model, new strategy
  policy, alternate config) runs in a clone-on-write shadow against the replay corpus
  AND, when desired, in parallel with live matters as a SHADOW RUN — its outputs go
  nowhere, they are only diffed against production's. Zero risk, full evidence.
- **Promotion path:** shadow evidence → SEV upgrade certificate → creator «εγκρίνω» →
  production. Rollback is a config/version step, not surgery, because every prior state
  is a replayable P5 point.
The creator can experiment daily; the system cannot be demolished from the edges,
because the edges are sockets and the core only changes through the ceremony.

## 9. What is deliberately absent (adjudicated and rejected — see EVIDENCE)

- Blocking N-kernel cross-foundational unanimity (compensatory: kills liveness; TCB bloat).
- Any learning inside the trusted path (violates P1/A4).
- "Antifragile ratchet" as a separate mechanism (reducible to P2+P4+P5; content-volume
  gains are out of architecture scope).
