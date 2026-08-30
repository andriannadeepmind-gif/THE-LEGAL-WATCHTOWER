# AGENT-SYSTEMS — The 2026-Realistic Agentic Substrate for LAWMAX-Ω

**Team:** AGENT-SYSTEMS. **Date:** 2026-08-28. **Scope:** architecture, orchestration,
memory, tool-contracts, coordination-failure containment, adversarial-search certificates,
multi-model heterogeneity. **Out of scope:** corpus volume/quality, cost, scheduling (per brief §4/§6).

**Claim-status discipline (mandatory, per brief).** Every substantive claim carries exactly one tag:
`THEOREM` / `DESIGN-ENTAILED` / `IMPLEMENTED` / `DEMONSTRATED` / `EMPIRICAL` / `HYPOTHESIS` / `UNKNOWN`.
Rules that are non-negotiable and repeated wherever they bite:
- **Model access ≠ idea inclusion.** Running N models is a substrate fact, never an idea-coverage claim (§8).
- **Proof-checking ≠ correctness of the natural-language formalization** (the formalization gap; frontier-2026 §6b) — the substrate never launders a solver's success into "correct."
- **Benchmark score ≠ practice correctness.** No aggregate accuracy number is a supremacy claim.
- **Vendor marketing ≠ evidence.** Any convergent-vendor pattern (frontier-2026 §5) is a baseline to exceed, not a design proof.
- Unresolved contradictions are kept **BLOCKING**, never smoothed into "engineering details."

**Grounding in the existing repo (from OMEGA-2 repo-paths inventory).** LAWMAX already has: a
per-concept "one seat" discipline; an append-only hash-chained journal (`source/journal.lisp`),
episode-stream memory (`source/memory.lisp`), a 114-defun bitemporal `source/version-graph.lisp`,
a Merkle/RFC-6962 authority (`source/merkle-authority.lisp`), ~19 structural gates under
`systems/orchestrator-cli/*-gate.lisp` mediated by a CLOS-`around` `constitutional-dispatch.lisp`,
and authority-emit seats (`write-authority.lisp:emit-graph`, `validation-authority.lisp`). This
report designs the **agentic substrate that sits ON those seats** — it does not re-invent them, and
where it needs a property the seats already provide it names the seat. **One BLOCKING inheritance:**
`constitutional-gate.lisp` is *fail-OPEN* on predicate error (repo-paths §2a). The entire substrate
below assumes a **fail-CLOSED** admission boundary; §5.4 and §6 treat that fail-open as a substrate-level
blocker, not a local bug.

---

## 0. Substrate thesis (the one design commitment everything else discharges)

> **The agent layer is UNTRUSTED by construction. It is a *proposal generator and search
> engine* whose entire output crosses a fail-closed, provenance-checking admission boundary
> before it can become an authority-bearing artifact. No agent, no model, no orchestration
> topology is ever on the trusted path.** `[DESIGN-ENTAILED]`

This is the direct entailment of the program's own laws ("κανένα LLM στο trusted path", "τίμια
άγνοια", fail-closed Publication Gateway) *and* of the frontier finding that the commodity is the
model and the moat is the trust boundary (frontier-2026 §11). Concretely it forces a two-region
architecture with a single, typed, non-bypassable seam between them:

```
┌─────────────────────── UNTRUSTED REGION (the agentic substrate, this report) ───────────────────────┐
│  routing · planner/worker/critic · debate · tournament · blackboard · N heterogeneous models ·      │
│  episodic scratch memory · adversarial search · tool *proposals*                                     │
│  Property: may be wrong, may be adversarial, may be non-deterministic. Assumed hostile.              │
└───────────────────────────────────────────┬──────────────────────────────────────────────────────────┘
                                             │  ONE seam: typed, signed, provenance-complete PROPOSAL objects
                                             ▼   (never natural-language "trust me"; never a raw model string)
┌─────────────────────── TRUSTED REGION (existing seats — gates/authority/journal) ─────────────────────┐
│  constitutional-dispatch → gates → validation-authority → emit-graph → merkle-authority → journal     │
│  Property: deterministic, replayable, fail-closed, append-only, admits nothing it cannot re-derive.   │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Consequences that recur below.** (a) Every agent output is a *claim with provenance*, never an
authority. (b) The substrate's job is **coverage and adversarial pressure**, not final correctness —
correctness is the trusted region's job via re-derivation. (c) "Honest ignorance" is a first-class
substrate output: the correct answer to a search that did not close is a **budget/coverage
certificate saying so** (§7), never a guess. (d) The formalization gap means even a formally
"verified" agent proposal re-enters as a *proposal*; faithfulness of NL→formal is discharged in the
trusted region by redundant independent formalization + semantic-equivalence check (ARc-style,
frontier-2026 §6b), not asserted by the agent.

---

## 1. Task-adaptive routing

### 1.1 Task-class taxonomy (the routing key)
Routing is only as honest as its key. `[DESIGN-ENTAILED]` The router keys on a **declared, typed
TaskClass**, not on a learned embedding of the prompt, because the failure cost is asymmetric:
mis-routing a privileged-matter drafting task to a cheap short-horizon path is a correctness/privilege
failure, not a latency blip. Minimum task-class axes (each a typed enum, journaled):

| axis | values (illustrative) | why it changes routing |
|------|----------------------|------------------------|
| horizon | single-shot · bounded-multi-step · open-horizon | selects topology (§2) + checkpoint cadence (§3) |
| jurisdiction/order | Greek-civil · Greek-criminal · EU · ECHR · cross | selects corpus/authority seat + the statutory-article-ID hardening (frontier-2026 §7, GreekBarBench weak point) |
| epistemic type | retrieval · extraction · normative-judgment · formalization · drafting · adversarial-red-team | debate/tournament only earn their cost on normative-judgment & red-team (§2.4) |
| stakes | log-only · human-gate · publication-gated | sets verifier depth (the Verifier Tax is horizon-dependent, frontier-2026 §6c) |
| reversibility | reversible-scratch · irreversible-authority | irreversible ⇒ must pass the seam (§0); router cannot shortcut |

### 1.2 Declared routing FIRST, learned routing as a *ranked suggestion under a declared ceiling*
`[DESIGN-ENTAILED]` The trusted-path prohibition on LLMs (CLAUDE.md) extends to routing decisions
that gate irreducible actions. Therefore:

- **Declared routing** is a deterministic policy table `TaskClass → RoutePlan`, versioned in the
  repo (a `route-registry.sexp` seat, one seat per §CLAUDE.md), signed, and journaled. It is the
  authority. For any irreversible/publication-gated class it is the *sole* decider. `[DESIGN-ENTAILED]`
- **Learned routing** (a model or bandit that observes features and *ranks* candidate routes) is
  allowed ONLY to (a) pick among routes the declared table already marks admissible for the class,
  and (b) propose a *new* route to the human curator for promotion into the declared table. It never
  widens the admissible set at runtime. `[DESIGN-ENTAILED]`
- **Honest framing of "learned routing works":** any claim that the learned router improves outcomes
  is `EMPIRICAL` at best and requires a held-out, matter-disjoint evaluation (no train/test matter
  leakage — same contamination discipline as §4.3). Absent that, it is `HYPOTHESIS`. A router that
  looks good because it memorized which matters are easy is the routing analogue of benchmark-gaming.

This is strictly stronger than the vendor "dynamic harness" pattern (LexisNexis Legal Intelligence
Engine, frontier-2026 §3): those select models/agents/skills per task with *no public evidence of a
declared ceiling or an audited fallback contract*. LAWMAX's router is auditable-by-construction — the
journal replays the exact route chosen and why. `[DESIGN-ENTAILED]` (Superiority over the vendor
pattern is `DESIGN-ENTAILED` at the *auditability* property; it is **not** a capability-superiority
claim — that would require the independent evaluation the field does not yet have, frontier-2026 §10.2.)

### 1.3 Fallback ladders (typed, monotone, fail-closed)
A fallback ladder is a **total order of routes for a class, each a strictly more conservative
option**, terminating in refusal. `[DESIGN-ENTAILED]` Design invariants:

1. **Monotone conservatism.** Each rung down trades capability/latitude for verifiability. Never a
   lateral "try a different model and hope" — that is thrash (§5.2), not fallback.
2. **Terminal rung is always `honest-ignorance`** — emit a coverage certificate (§7) + route to the
   human queue (`source/review-queue.lisp` exists). Never a silent lower-confidence answer. This is
   the structural encoding of "λέει «δεν ξέρω» αντί να μαντεύει."
3. **A rung is taken on a *typed trigger*, not a timeout alone.** Triggers: verifier-reject,
   tool-contract violation (§5), budget exhaustion with open coverage (§7), drift alarm (§3.4),
   sandbox denial. A bare wall-clock timeout on an open-horizon task triggers *checkpoint + resume*
   (§3), not a capability downgrade — downgrading on latency alone silently degrades correctness to
   meet a deadline, which is the exact economics-over-correctness error the brief forbids (§5).
4. **Deadline-awareness is a correctness input (brief §5), routed explicitly.** A procedural deadline
   is modeled as a *hard constraint on the route plan*, so the ladder is pre-computed to guarantee
   *some* admissible rung (possibly "escalate to human now") completes before the deadline — the
   system never discovers at T-minus-zero that only the slow route was viable. `[DESIGN-ENTAILED]`

**Anti-pattern rejected:** the common "retry with a bigger model" ladder. Bigger ≠ more conservative;
it can *increase* confident-wrongness (sycophancy, §5.5). The ladder axis is **verifiability**, not
model size. `[DESIGN-ENTAILED]`

---

## 2. Orchestration topologies — when each genuinely wins

**Framing discipline.** A topology is chosen because it changes the *error structure*, not because it
"feels more thorough." Each below states the error mode it attacks and the mode it *introduces*
(there is no free topology). `[DESIGN-ENTAILED]`

### 2.1 Planner / Worker / Critic (the default spine)
- **Wins when:** the task decomposes into verifiable sub-goals and the dominant risk is *compounding
  per-step error over a horizon* (frontier-2026 §6c). Plan→execute→verify→replan is the literature's
  convergent reliability pattern. `[EMPIRICAL that the pattern reduces long-horizon error in published
  agent studies; DESIGN-ENTAILED as LAWMAX's default.]`
- **Attacks:** silent context loss across handoffs (brittle handoffs are the named MAS failure).
- **Introduces:** critic sycophancy / evaluator collusion if planner and critic share a model or
  context (§5.5, §5.6). **Mitigation is structural:** the critic runs as an *independent adversarial
  agent with fresh context and no access to the planner's rationale* — exactly the program's own
  internal-adversary protocol (CLAUDE.md, [0047]). The critic's verdict is a *proposal*, still
  crossing the seam.
- **Non-negotiable:** the critic is necessary but **not sufficient** — a passing critic does not admit
  anything. Admission is the trusted region's re-derivation. This defeats the "the critic said it's
  fine" laundering.

### 2.2 Debate (two+ agents argue to a judge)
- **Wins when:** the task is a **normative/interpretive judgment with a genuine two-sided legal
  question** (statutory interpretation, application of an open-textured standard) where the value is
  *surfacing the strongest opposing argument*, not converging. `[DESIGN-ENTAILED]`
- **Attacks:** one-sided reasoning / motivated confirmation; it forces the counter-case into the record.
- **Introduces:** **persuasion ≠ correctness.** Debate optimizes for a judge's verdict, which can
  reward rhetoric over law (the sycophancy failure at judge level). It is `HYPOTHESIS`, not
  established, that debate converges on truth for legal questions; treat debate output as *a
  structured argument pair*, and let the trusted region check each side's *citations and holdings*
  against authority. Debate is a **coverage device (both sides on the record), never an adjudicator.**
- **Rejected use:** debate to *decide* anything admissible. Only the human + fail-closed gates decide.

### 2.3 Tournament (bracket of candidates, pairwise/round elimination)
- **Wins when:** you have **many independently generated candidate artifacts** (e.g. alternative
  brief drafts, alternative statute formalizations) and a *cheap, sound* dominance test to eliminate
  strictly-worse ones — e.g. a candidate that cites a non-existent authority is eliminated by a
  deterministic citation-existence check (a sound filter, not a taste judgment). `[DESIGN-ENTAILED]`
- **Attacks:** variance/luck in single-sample generation; keeps the best-of-N by an *objective* test.
- **Introduces:** **collapse to a correlated winner** if candidates are drawn from correlated sources
  (§8) and the elimination metric is a subjective judge. Guard: elimination edges must be **sound
  dominance relations** (A eliminates B only if A ≥ B on a checkable property), else the tournament
  just amplifies a shared bias. A subjective-judge tournament is a diversity-destroyer, not a
  coverage device. `[DESIGN-ENTAILED]`

### 2.4 Blackboard (shared workspace, opportunistic contributors)
- **Wins when:** the task is **open-ended assembly from heterogeneous specialists** with no clean
  a-priori decomposition — e.g. building a matter theory where a facts-agent, a statute-agent, a
  precedent-agent, and an ECHR-agent each contribute when they have something, and contributions
  interlock unpredictably. `[DESIGN-ENTAILED]`
- **Attacks:** premature/over-rigid decomposition (the planner's weakness) on genuinely
  ill-structured problems.
- **Introduces:** **silent divergence and provenance loss** — the blackboard's shared mutable state is
  where "who claimed what, on what basis" gets lost. **Mitigation is that the blackboard is not free
  memory: every write is a provenance-carrying, append-only entry** on the journal seat
  (`source/journal.lisp`), and reads are typed queries, not ambient context. A blackboard without
  provenance discipline is a contamination engine (§4.3). `[DESIGN-ENTAILED]`

### 2.5 Selection rule (declared, not vibes)
`[DESIGN-ENTAILED]` The router (§1) selects topology from the task-class key:

| epistemic type × horizon | topology |
|---|---|
| retrieval/extraction, bounded | planner/worker/critic, single worker |
| normative-judgment, any | planner/worker/critic **+ debate** for the judgment sub-goal |
| formalization, bounded | tournament over redundant independent formalizations + semantic-equivalence check (ARc-style) |
| drafting, open-horizon | blackboard of specialists, planner supervising, tournament over drafts |
| adversarial red-team (the internal Critic mandate) | independent adversarial agents, fresh context (CLAUDE.md [0047]) |

Topology choice is journaled and replayable. **No topology is a correctness argument** — each is a
*coverage/pressure* argument; correctness is the seam + trusted region. `[DESIGN-ENTAILED]`

---

## 3. Long-horizon reliability

**Load-bearing empirical premise (frontier-2026 §6c):** single-shot pass rates *systematically
overstate* long-horizon reliability ("Beyond pass@1"), and verification is *not free* ("The Verifier
Tax"). Therefore reliability is engineered as an **architectural property**, not hoped for from a base
model. `[EMPIRICAL premise → DESIGN-ENTAILED architecture.]`

### 3.1 Context management (compaction is lossy — treat it as such)
- Context is **tiered and typed**, never a growing undifferentiated blob: (i) *pinned invariants*
  (matter id, jurisdiction, deadline, privilege class) — never compacted; (ii) *working set* (current
  sub-goal state) — checkpointed verbatim; (iii) *retrieved evidence* — referenced by provenance
  handle, never inlined as free text that loses its source (§4.2). `[DESIGN-ENTAILED]`
- **Compaction is a lossy transform and is logged as one.** Any summarization of history that feeds a
  further step is itself a model output → untrusted → journaled with a pointer to the pre-compaction
  state so the reasoning is *replayable from the raw record*, not only from the summary. This is the
  antidote to "loss of decision-relevant context" (the named MAS failure). `[DESIGN-ENTAILED]`

### 3.2 Checkpointing (state, not transcript)
- A checkpoint is a **typed, serialized, content-addressed snapshot** of {pinned invariants, working
  set, open sub-goals, tool-effect ledger, coverage certificate-so-far}. It is written to a
  content-addressed store and **hash-chained into the journal** (the seat already gives append-only +
  SHA-256 chaining — `journal.lisp`, `self-history.sexp` pattern). `[DESIGN-ENTAILED; seats IMPLEMENTED]`
- **Checkpoint cadence is a declared function of the task-class**, and is forced *before every
  irreversible effect* and *before every seam crossing*, so a crash can never strand an
  authority-emit mid-flight. `[DESIGN-ENTAILED]`

### 3.3 Resumability (deterministic replay, idempotent re-entry)
- Resume = load latest valid checkpoint + **replay** the tool-effect ledger through idempotent
  contracts (§5.3), never "re-run and hope." Because tool effects are idempotency-keyed, replay does
  not double-apply. `[DESIGN-ENTAILED]`
- **Resumability is a testable property, not a promise:** a chaos harness that kills the agent at every
  checkpoint boundary and asserts identical final admission is the acceptance test. Until that harness
  runs green, resumability is `HYPOTHESIS`; after, `DEMONSTRATED` for the covered cases. (The repo's
  `determinism/` harness is the natural home. `[repo determinism/ IMPLEMENTED; property UNKNOWN until run]`)

### 3.4 Drift detection (three distinct drifts, three distinct detectors)
"Drift" is overloaded; separate it or you cannot contain it. `[DESIGN-ENTAILED]`
1. **Goal drift** — the agent is optimizing a mutated goal. Detector: the pinned goal-invariant is
   re-stated and *checked* at each sub-goal boundary against the original typed goal object; mismatch
   → halt + human. (Not "ask the model if it's on track" — that is self-report, unreliable.)
2. **Context/semantic drift** — the working meaning of a term has slid (e.g. "the debtor" now
   silently refers to a different party). Detector: entity/reference resolution is grounded in the
   provenance store; an unresolvable or newly-ambiguous reference is a typed alarm.
3. **Distributional drift** — inputs/tool responses leave the envelope the route was validated for.
   Detector: input-type guards + tool-output schema checks (§5); out-of-envelope → conservative rung
   (§1.3).
Each detector emits a typed event to the journal; **none is an LLM asked to introspect.** `[DESIGN-ENTAILED]`

---

## 4. Memory architecture for agents

### 4.1 Three memories, kept structurally distinct (not one vector store)
`[DESIGN-ENTAILED]` Conflating these is the root of both contamination and confident-wrongness:

| memory | content | store | mutability | admissibility |
|--------|---------|-------|-----------|---------------|
| **episodic** | what happened in *this matter/session* — steps, tool effects, observations | per-matter episode stream (`source/memory.lisp` is the seat) | append-only | scratch; crosses seam only as provenance-bearing proposal |
| **semantic** | matter-independent *knowledge* — statutes, holdings, ontology | authority-emit seats + version-graph (bitemporal) | versioned, never in-place | authority ONLY after gates/emit; agents *read* it, never *write* it directly |
| **procedural** | *how to do a task class* — route plans, workflow skills, checklists | declared registries (route-registry, gate-registry.sexp) | curated, human-promoted | authority = the declared policy; learned refinements are proposals |

**Key discipline:** an agent may **write** episodic freely (it is scratch), may **propose** semantic
and procedural updates, but may **never** write semantic/procedural memory directly. This makes
"an agent poisoned semantic memory" *structurally impossible*, not merely forbidden — the write
seat is the gated authority-emit path (CLAUDE.md: eliminate the error class, don't guard it).
`[DESIGN-ENTAILED; write seats IMPLEMENTED]`

### 4.2 Provenance-carrying memory (every remembered fact traces to a span)
`[DESIGN-ENTAILED]` No memory entry is a bare string. Each carries: `{content, source-handle
(document+span or tool-effect id), derivation (which agent/model/route, journaled), matter-id,
temporal validity (bitemporal — version-graph seat), signature}`. Retrieval returns the *provenance
object*, and the substrate is forbidden from inlining content stripped of its source (§3.1). This is
strictly the discipline Hebbia's cell-level "Verifiable Fact Layer" gestures at (frontier-2026 §5a)
but enforced as an *invariant of the memory type*, not a UI feature. **Faithfulness caveat:** the
provenance object proves *where a claim came from*, not that the claim is a correct reading of the
source — that is the trusted region's holding-alignment check, not a memory property. `[DESIGN-ENTAILED;
no conflation of provenance with correctness]`

### 4.3 Retrieval discipline — matter isolation (the privilege-critical invariant)
Brief §1–2: all matters/client data STRICTLY private. Cross-matter contamination is both a
correctness failure and a **privilege/ethics breach**. `[DESIGN-ENTAILED — BLOCKING if violated]`

- **Episodic memory is matter-partitioned at the store level**, not filtered at query time. A retrieval
  query is *typed with a matter-id capability*; the store cannot return another matter's episodes
  because they are not in the addressable set — isolation by construction, not by a `WHERE` clause an
  agent could omit. (This mirrors the capability-gate seat pattern.) `[DESIGN-ENTAILED]`
- **Semantic memory is shared** (statutes are not privileged) but **retrieval into a matter carries a
  contamination barrier**: nothing from matter A's episodic stream may become part of matter B's
  context, and the *fact of retrieval* is journaled per matter for the privilege audit the Publication
  Gateway needs. `[DESIGN-ENTAILED]`
- **No cross-matter "learning" at runtime.** Any generalization from matter A that could help matter B
  goes through human-gated promotion into semantic/procedural memory, stripped of privileged
  specifics by the same DLP/redaction path as the Publication Gateway. Runtime cross-matter transfer
  is **structurally blocked**, not policy-forbidden. `[DESIGN-ENTAILED]`
- **Retrieval poisoning / contamination test:** an adversarial matter designed to leak into a sibling
  matter is a standing red-team case (§5, CLAUDE.md [0047]). Until it runs green, isolation is
  `HYPOTHESIS`; after, `DEMONSTRATED` for the covered attack. `[status UNKNOWN until harnessed]`

---

## 5. Tool-use contracts & the coordination-failure catalogue

### 5.1 Typed tool IO
`[DESIGN-ENTAILED]` Every tool has a **declared, machine-checked contract**: typed input schema,
typed output schema, declared side-effect class (pure / read / effectful / irreversible), declared
error type set. A tool call whose output fails its schema is a **typed contract violation → fallback
rung (§1.3)**, never a silently-coerced string. The agent never sees a raw untyped tool string; it
sees a validated typed object or a typed error. This kills the class of "the tool returned garbage and
the agent hallucinated over it."

### 5.2 Sandboxing
`[DESIGN-ENTAILED]` Tools execute under **capability-scoped, deny-by-default sandboxes**: a tool gets
exactly the matter-id capability, filesystem/network scope, and effect-class it declared, nothing
ambient. Network egress from any agent/tool is deny-by-default (aligns with the existing egress-gated
posture; frontier-2026 recon itself hit the egress proxy). A sandbox denial is a typed event, not a
crash. **This is the fail-closed default the constitutional-gate fail-open (repo-paths §2a) currently
violates — see §5.4.** `[DESIGN-ENTAILED; blocked by inherited fail-open]`

### 5.3 Idempotency
`[DESIGN-ENTAILED]` Every effectful tool call carries an **idempotency key** derived from
{matter-id, sub-goal, canonical-input-hash}. The effect ledger records applied keys; a replay (§3.3)
or retry (§1.3) with a seen key returns the recorded effect instead of re-applying. Irreversible
effects (authority emit, any external filing) additionally require a seam crossing + human gate, so
idempotency is a *safety* property (no double-filing), not only an efficiency one.

### 5.4 Replayability
`[DESIGN-ENTAILED]` The tool-effect ledger + typed IO + idempotency keys make the whole agent run
**deterministically replayable from the journal**: given the recorded inputs and tool effects, the
admission decision re-derives identically. This is the property that makes the untrusted region
*auditable* despite containing non-deterministic models — you replay the *effects and the seam
crossings*, not the model's internal sampling. Replayability is the technical substrate for the AI-Act
Art. 12 event-logging obligation (frontier-2026 §8) **and** for the program's own replayable-proof law.
**BLOCKING dependency:** replayable audit is only trustworthy if the admission boundary is fail-closed;
the inherited `constitutional-gate` fail-open (a crashing predicate ⇒ ALLOW, repo-paths §2a) means a
replay could faithfully record an *unsafe admission*. The agentic substrate cannot fix this on its own
seat; it is flagged here as a **BLOCKING cross-team dependency on the gate seat** and the substrate
treats the gate as untrustworthy-until-closed (the seam re-validates rather than assuming the gate held).

### 5.5–5.6 Coordination-failure catalogue (detection + containment)
`[DESIGN-ENTAILED throughout; each detector is a typed check or a structural invariant, never a model
asked to introspect.]`

| # | failure | what it is | detection | containment |
|---|---------|-----------|-----------|-------------|
| 1 | **Deadlock** | agents mutually waiting (blackboard locks, tool handoff cycle) | wait-for graph over the coordinator; cycle detection; per-agent liveness heartbeat with typed progress metric | timeout → checkpoint (§3.2) + coordinator breaks the cycle by aborting the lowest-priority waiter to its fallback rung; journaled |
| 2 | **Thrash** | repeated lateral re-attempts with no monotone progress (retry-different-model loop) | progress metric non-increasing over N steps; route-history shows lateral (non-monotone) moves (§1.3) | force a *downward* (more conservative) rung, or terminate to honest-ignorance; ban lateral retries structurally (ladder is a total order) |
| 3 | **Silent divergence** | two agents/branches build on incompatible assumptions without anyone noticing | shared assumptions are typed facts on the journal; a contradiction check runs on the blackboard's fact set (deterministic, not LLM) | contradiction → halt the diverging branches, surface both to the coordinator/human; contradiction stays BLOCKING (never auto-reconciled — CLAUDE.md B-reconciliation prohibition) |
| 4 | **Error cascade** | one wrong intermediate poisons all downstream steps (compounding error) | provenance DAG lets a later-detected error be traced to its origin; per-step verifier gates catch before propagation | quarantine the tainted provenance subtree; re-derive only affected sub-goals from last clean checkpoint; the taint is journaled so nothing downstream of it is admissible |
| 5 | **Sycophancy loop** | agent (or critic) agrees with a user/peer's wrong premise, fabricates support (the exact Stanford failure, frontier-2026 §7) | premise-independence check: the critic runs with **fresh context and no access to the proposer's stated premise/rationale** (CLAUDE.md [0047]); disagreement rate near zero across independent critics is itself an alarm | on suspected sycophancy, escalate to an *adversarial* critic explicitly tasked to break the claim; the trusted region checks cited support *exists and holds*, so fabricated support cannot be admitted regardless |
| 6 | **Evaluator collusion** | critic/judge shares model, context, or incentive with the proposer and rubber-stamps | structural: proposer and evaluator must differ in model family AND context AND have no shared reward signal; a collusion probe injects known-bad proposals ("honeypots") and asserts the evaluator rejects them | an evaluator that passes a honeypot is disabled and its recent verdicts are marked non-admissible pending human review; evaluator diversity is a *declared, checked* property, not assumed |

**Cross-cutting containment invariant:** none of the above containments *admit* anything. The worst
case for every failure is **halt + honest-ignorance certificate + human queue**, never a degraded
silent answer. That is what makes the failure catalogue safe rather than merely monitored. `[DESIGN-ENTAILED]`

**Honesty note on the catalogue.** These detectors *reduce* the failure probability of an *untrusted*
region; they do **not** make the region trusted. The claim "the substrate cannot admit a wrong
authority" rests on the seam + fail-closed gates (§0), NOT on the catalogue. Presenting the catalogue
as a correctness guarantee would be the "guard around the error class" anti-pattern the program forbids.
`[DESIGN-ENTAILED — scope honesty]`

---

## 6. Anytime adversarial search with budget/coverage certificates

**The honest-ignorance problem, made precise.** For any non-trivial legal search (find every
controlling authority; find every counter-argument; find every inconsistency in a formalization) the
space is not exhaustively enumerable in general. The supremacy-fallacy is to report "we found the
answer" when what happened is "we found *an* answer and stopped." The substrate instead emits a
**certificate of what was and was not searched.** `[DESIGN-ENTAILED]`

### 6.1 What a coverage certificate may honestly assert
`[DESIGN-ENTAILED — and explicitly bounded]` A certificate over a search may state ONLY things that are
*checkably true*:
- **Enumerated-and-exhausted (strong):** the search space was a *defined finite set* S (e.g. all
  articles of a specified code; all cases in a defined authority set) and every element of S was
  examined by a stated sound test. "We searched S of S" is then a `THEOREM`-grade claim *relative to
  the definition of S* — with the load-bearing caveat that **S's completeness as a model of "the
  relevant law" is itself a formalization claim** (frontier-2026 §6b) and is NOT certified here. The
  certificate says "exhausted the defined set S," never "found all relevant law."
- **Bounded-sample (honest partial):** the space is not finite/enumerable; the search drew K samples
  under a declared strategy (e.g. adversarial prompt diversification, N independent models). The
  certificate reports K, the strategy, the coverage *proxy* (e.g. distinct authorities touched, novelty
  curve — see §6.3), and states explicitly **"this is a sample, not a proof of completeness."** It is
  `EMPIRICAL` about what was found, `UNKNOWN` about the unsearched remainder. It must never be phrased
  as a fraction of the true space, because the true space's size is unknown.
- **Budget-terminated (anytime):** the search is anytime — at any interruption it returns the best
  result *so far* plus the certificate of coverage *so far*. Terminating on budget is journaled as
  budget-termination, not dressed up as completion.

**Forbidden certificate claims (each would be a supremacy fallacy):** "we searched 90% of the space"
when the space is unbounded; "exhaustive" when only a sample ran; "verified complete" when only a
sound-but-incomplete filter ran. `[DESIGN-ENTAILED — these are named and blocked.]`

### 6.2 Adversarial search structure
`[DESIGN-ENTAILED]` The search is adversarial in the program's sense (CLAUDE.md [0047]): independent
agents with fresh context are tasked to *find the missing authority / the breaking counter-example /
the inconsistency*, not to confirm. Diversity of the searchers is what buys coverage — and its honest
statistical framing is §8 (correlated searchers do not add coverage). The adversary's *failures to
break* are logged as coverage evidence; its *successes* are BLOCKING findings closed on-seat.

### 6.3 Coverage proxies that are honest
`[DESIGN-ENTAILED]` Since true coverage of an unbounded space is unknowable, the certificate reports
**proxies with stated limitations**: (i) a **novelty/saturation curve** — new distinct authorities or
arguments found per additional unit of search; a flattened curve is *evidence of, not proof of,
diminishing returns* (`EMPIRICAL`, with the caveat that a flat curve can also mean correlated searchers
stuck in the same basin — §8); (ii) **diversity of searchers actually achieved** (§8 statistic);
(iii) **the defined set fraction** where and only where a defined set exists (§6.1 strong case). No
single proxy is reported as "coverage" unqualified.

---

## 7. Honest-ignorance as the terminal output (tying §1.3, §6, §5 together)

`[DESIGN-ENTAILED]` The substrate has exactly three terminal outputs, and this is a closed set:
1. **A provenance-complete proposal** that crosses the seam and is admitted by the fail-closed trusted
   region (the only path to an authority-bearing artifact).
2. **A budget/coverage certificate of an incomplete search** (§6) → human queue.
3. **A refusal / honest-ignorance** ("δεν ξέρω") with the reason typed → human queue.
There is **no fourth output** "a lower-confidence answer emitted anyway." Encoding this as a closed
enum in the seam type is what makes "silently guessing under deadline pressure" *structurally
impossible* rather than merely discouraged (brief §5: deadlines are correctness constraints, and the
correct behavior under an impossible deadline is a certified refusal + escalation, not a guess).

---

## 8. Multi-model heterogeneity — the honest statistical framing

**The core discipline (brief, verbatim intent): do NOT equate model access with idea inclusion.**
Running N models is a *substrate* fact. Whether N models add *coverage* is an *empirical, measurable,
and usually overstated* claim. `[DESIGN-ENTAILED framing; the numbers below are EMPIRICAL-per-deployment,
never assumed.]`

### 8.1 The ensemble-diversity theorem (why N models ≠ N× coverage)
`[THEOREM — standard result, correctly applied]` For an ensemble to reduce error over its best member,
member errors must be **less than perfectly correlated**. Formally, the ensemble's effective coverage
scales not with N but with the *effective number of independent members* — governed by the pairwise
error correlation ρ. In the idealized equicorrelated case, the variance-reduction factor behaves like
`(1-ρ)/N + ρ`: as ρ→1 the ensemble collapses to a single model *no matter how large N is*; the benefit
lives entirely in the `(1-ρ)/N` term. **Consequence:** ten models fine-tuned from the same base,
trained on overlapping corpora, prompted identically, are close to **one** model wearing ten hats — high
ρ, near-zero added coverage. `[THEOREM (the decomposition); its applicability to a given model set is
EMPIRICAL and must be measured, not assumed.]`

### 8.2 The specifically legal correlation trap
`[DESIGN-ENTAILED]` Legal models correlate *more* than generic ensembles because: (i) shared
foundation models under the vendors (frontier-2026: multiple legal products sit on the *same* Claude
Agent SDK / same base families); (ii) shared training corpora (the same published cases and statutes);
(iii) **shared blind spots** — every model is weak on the *same* rare thing (GreekBarBench: models fail
*most* on statutory-article identification, frontier-2026 §7). Stacking N models that share the Greek-
statute blind spot yields N confidently-wrong-in-the-same-way answers — high agreement, which naive
ensembling reads as *confidence*. **This is the sycophancy failure (§5.5) at the population level:
agreement among correlated models is not evidence.** `[DESIGN-ENTAILED — and this is precisely why
LAWMAX must not equate model access with idea inclusion.]`

### 8.3 When N models GENUINELY add coverage
`[DESIGN-ENTAILED]` Heterogeneity earns its place only when the members differ on an axis that
*decorrelates the relevant errors*:
- different **base families** (genuinely different pretraining), not siblings;
- different **modalities of reasoning** applied to the *same* problem — e.g. a retrieval-grounded LLM
  vs. a **symbolic/deterministic engine** (the neuro-symbolic split, frontier-2026 §6). This is the
  highest-value heterogeneity because the symbolic member's errors are *structurally* uncorrelated with
  the LLM's (it fails on formalization faithfulness, not on hallucination) — and it is the one the
  trusted region already relies on;
- different **elicited roles** — proposer vs. adversarial critic vs. red-team — which decorrelates by
  *task framing* even at fixed model, and is cheaper diversity than adding base families. (Caveat:
  same-base role-play diversity has a ceiling; it cannot escape a shared factual blind spot.)

### 8.4 Measuring realized diversity (never assuming it)
`[DESIGN-ENTAILED]` The substrate **measures** the ensemble's realized pairwise disagreement on a
held-out, matter-disjoint probe set and reports the **effective number of independent members** as part
of the coverage certificate (§6.3). A route that declares "N models" but measures an effective count of
~1 is flagged: it is paying N× compute for ~1× coverage, and — more importantly — its *agreement is not
admissible as confidence*. **The certificate reports effective-independent-members, not N.** This is the
operational form of "model access ≠ idea inclusion." Any claim that the ensemble improves outcomes is
`EMPIRICAL` and requires the disjoint probe; absent it, `HYPOTHESIS`.

### 8.5 What heterogeneity does NOT buy
`[DESIGN-ENTAILED — anti-fallacy]` (i) It does not close the formalization gap — N models agreeing a
formalization is faithful is not faithfulness; that needs redundant *independent* formalizations checked
for semantic equivalence in the trusted region (frontier-2026 §6b). (ii) It does not manufacture ideas
absent from all members' training — an ensemble cannot cover a legal theory none of its members can
represent (the honest limit on "coverage"). (iii) It does not make the untrusted region trusted — all
members' outputs still cross the seam.

---

## 9. Contradictions kept BLOCKING (not smoothed)

1. **Inherited fail-OPEN gate vs. fail-CLOSED substrate premise.** `constitutional-gate.lisp` admits on
   predicate error (repo-paths §2a). The entire §0 architecture assumes fail-closed admission. **BLOCKING
   cross-team dependency** — the substrate treats the gate as untrustworthy-until-closed and re-validates
   at the seam, but the program-level guarantee "cannot admit a wrong authority" is *not discharged* until
   the gate seat is made fail-closed. Not an engineering detail. `[BLOCKING]`
2. **AI-Act Art. 12 immutable ≥6-month logging vs. GDPR data-minimization vs. privilege** (frontier-2026
   §8, §10.3). The substrate's replayable journal (§5.4) *maximizes* retained reasoning traces — directly
   in tension with data-minimization and with privilege over internal reasoning. Cannot be resolved inside
   the agent layer; must be reconciled at the trust-boundary/retention-policy level. The substrate exposes
   the knob (what is journaled, retention class per entry) but does not decide the policy. `[BLOCKING]`
3. **"Learned routing/ensemble improves outcomes" vs. no matter-disjoint independent evaluation.** Every
   efficacy claim in §1.2 and §8.4 is `HYPOTHESIS` until a contamination-free evaluation runs. The
   substrate must not cite its own routing/ensemble as superiority evidence before that. (Mirrors
   frontier-2026 §10.2: the 2026 agentic frontier is essentially unmeasured independently.) `[BLOCKING for
   any supremacy claim; non-blocking for building the harnessed capability.]`
4. **Debate/tournament convergence-on-truth for legal questions** is `HYPOTHESIS`, not established
   (§2.2–2.3). Using either as an *adjudicator* is forbidden; both are coverage devices only. `[BLOCKING
   against mis-use.]`

---

## 10. Claim-status ledger (what this report actually established)

- **THEOREM:** the ensemble error-correlation decomposition (§8.1) — standard, correctly applied;
  its *applicability* to any model set is EMPIRICAL.
- **DESIGN-ENTAILED:** the two-region untrusted/trusted architecture and its seam (§0); declared-first
  routing with learned suggestion under a ceiling (§1); topology selection rules and their
  error-structure framing (§2); tiered context, state-checkpointing, three-drift detection (§3); the
  three-way memory split with structural write-prohibition and matter-partition-by-construction (§4);
  typed/idempotent/replayable/sandboxed tool contracts (§5.1–5.4); the six-entry failure catalogue with
  halt-to-honest-ignorance containment (§5.5); the closed set of three terminal outputs (§7); honest
  coverage-certificate semantics and forbidden claims (§6); measured effective-independent-members (§8.4).
- **IMPLEMENTED (inherited seats the substrate builds on, not built here):** journal, memory episode
  stream, bitemporal version-graph, Merkle authority, gate battery, dispatch, authority-emit,
  review-queue, determinism harness.
- **EMPIRICAL (premises borrowed, not re-measured here):** pass@1 overstates long-horizon reliability;
  the Verifier Tax; Stanford hallucination/sycophancy; GreekBarBench statutory-article weak point.
- **HYPOTHESIS (must be harnessed before relied upon):** resumability property (§3.3), matter-isolation
  under adversarial leak (§4.3), learned-routing/ensemble efficacy (§1.2/§8.4), debate/tournament truth
  convergence (§2.2–2.3).
- **UNKNOWN / BLOCKING:** the four contradictions in §9.

---

## 11. Minimal seat map (where this lands in the repo, one seat per concept)

`[DESIGN-ENTAILED naming; existing seats marked IMPLEMENTED]`
- `route-registry.sexp` (new seat) — declared routing table + fallback ladders (§1). Read by the router.
- Router as an untrusted proposer; **the seam** is a typed `Proposal` object validated by the existing
  `constitutional-dispatch` → gate battery → `validation-authority` → `write-authority:emit-graph`
  (IMPLEMENTED seats; the substrate produces Proposals, it does not emit authority).
- Episodic scratch → `source/memory.lisp` (IMPLEMENTED), matter-partitioned by capability.
- Checkpoints/effect-ledger → `source/journal.lisp` hash-chaining (IMPLEMENTED); content-addressed
  snapshot store (new seat) referenced from the journal.
- Coverage-certificate type (new seat) — one definition, emitted by every search; consumed by the
  human queue (`source/review-queue.lisp`, IMPLEMENTED).
- Tool-contract registry (new seat) — typed IO + effect-class + idempotency-key derivation (§5).
- Effective-independent-members probe (new seat under `determinism/` or a sibling) — measures §8.4.

**No wrappers, one entry per function** (CLAUDE.md): the substrate adds *proposer/search/coverage*
seats and reuses every existing trusted seat unchanged; it introduces no second authority-emit path and
no LLM anywhere on the trusted path.
