# CONVERGENCE AUDIT — Designs A / B / C

**Role:** Convergence Auditor (adversarial). **Date:** 2026-08-28.
**Inputs read in full:** `design-A-epistemic.md`, `design-B-game.md`, `design-C-institution.md`,
`formal-boundaries.md`, `agent-systems.md`; plus `beat-the-canon.md`, `frontier-2026.md` for the
blind-spot analysis.
**Claim-status discipline (mandatory):** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED /
EMPIRICAL / HYPOTHESIS / UNKNOWN. Two prohibitions enforced verbatim: *proof-checking ≠ correctness
of a natural-language formalization*; *model access ≠ idea inclusion*. Unresolved contradictions are
kept **BLOCKING**. No supremacy is asserted; no hidden trade-offs.

The three teams converged on: propose/check split · small non-LLM TCB · multi-world epistemics ·
capability-based matter isolation · fail-closed publication gateway · human authority at irreversible
points · no self-merge. This audit asks three adversarial questions about that convergence.

---

## Q1 — Is the convergence genuine signal, or an artifact of correlated priors / a shared blind spot?

**Verdict: mostly artifact, with a thin genuine-signal core — and the artifact is not the innocent
kind. The convergence is *overdetermined by a shared, explicit prompt*, which strips it of most of
its evidential value, and the residue is signal about pre-existing legal theory, not about the
architecture being optimal.** `[DESIGN-ENTAILED, from the input texts themselves]`

The correct move is to *stratify* the convergence into three layers, because they have radically
different evidential status and lumping them together is exactly the error the brief warns against.

### Layer (a) — Prompt-dictated core: ~zero evidential value

Several of the "converged" elements are not discoveries at all; they are **restatements of the
constitution and the brief the three teams were both handed.** CLAUDE.md mandates verbatim:
`κανένα LLM στο trusted path` → forces the propose/check split and the LLM-free TCB;
`τίμια άγνοια` → forces fail-closed / honest-UNKNOWN; `εξάλειψη της κλάσης σφάλματος` → forces
"isolation by construction, not by policy"; `μόνο ο δημιουργός συγχωνεύει` → forces no-self-merge.
The brief itself names the "fail-closed Publication Gateway" and "human authority at irreversible
points" as *binding conditions*. Three agents agreeing on what their shared instructions told them
to build is **convergence by construction, not by triangulation** — it is the multi-model
correlation trap of `agent-systems.md §8.2` at the level of the *prompt*: identical inputs, high ρ,
near-zero added coverage. Each design even cites CLAUDE.md by phrase while "deriving" these. Treating
this layer as evidence that the architecture is *right* is a circular-supremacy move; it only shows
the teams can follow instructions. `[DESIGN-ENTAILED]`

### Layer (b) — Problem-forced structure: genuine but not about the *architecture*

Multi-world epistemics, defeasibility, conflicting-authority partial orders, and human-reserved
discretion are **not** in CLAUDE.md. They converge because they are consequences of *legal theory
that predates all three models*: defeasibility (non-monotonicity), open texture (Hart), validity ≠
truth, standards-of-proof as qualitative thresholds. Design A tags these THEOREM "given the
definitions"; they are theorems *of jurisprudence*, encoded in the training corpus of every model.
So convergence here is real signal — but it is signal that **the models correctly recalled settled
legal theory**, not that the *system architecture* built on top of it is superior. It rules out gross
misdesign (a single-truth-world KB would be wrong); it does **not** distinguish this architecture
from other architectures that also respect defeasibility. `[DESIGN-ENTAILED]`

### Layer (c) — The unexamined shared frame: the actual blind spot

All three model the task as **"generate arguments about a legal question, then verify their form,
then gate the output"** — a static-artifact, single-firm, verification-and-refusal machine. This
frame is invisible *because all three share it*, and it is the shared blind spot itself (developed in
Q3). The tell: all three independently confess the **same** limitations — correlated-model
independence (A-W4/W8, B-W3, C-item1), the formalization gap (all), discretion irreducibility (all),
record-replay ≠ model-replay (all). **When independent teams converge on the solution AND on an
identical list of confessed weaknesses, that is the signature of a shared frame's boundary, not of
independently triangulated truth.** A genuinely independent team need not even rank the formalization
gap as central, or might refuse to treat discretion as off-limits (see Q3). `[HYPOTHESIS — but it is
the diagnostic the brief asks for]`

### The concrete test that distinguishes signal from artifact

Inter-model agreement is *not* the test — `agent-systems.md §8.1` proves agreement among correlated
members is near-worthless as ρ→1. The distinguishing test must (i) break the correlation and (ii)
touch ground truth outside all the models' priors. Three-part protocol, each part falsifiable:

1. **Prompt-ablation (breaks the Layer-a artifact).** Re-run the design exercise with CLAUDE.md
   *removed*, and separately with an *inverted* constitution (e.g. "an LLM MAY sit on the trusted
   path if empirically more accurate," "prefer a single best answer"). Also swap in *non-Claude* base
   families (genuinely different pretraining, not siblings). *Prediction that would vindicate the
   convergence:* propose/check + small-TCB + fail-closed still re-emerges as the dominant design when
   the prompt no longer prescribes it. *Prediction that would expose it as artifact:* it dissolves,
   and teams instead center accuracy/latency trade-offs. `[EMPIRICAL — untested; this is the single
   most decisive experiment and it has not been run]`

2. **Ground-truth adversarial contest (breaks the Layer-c frame).** Instantiate the convergent
   architecture and have an **independent human red team** (practicing Greek litigators + security
   researchers, no access to the design rationale) try to defeat it in *real procedural positions*.
   `beat-the-canon.md` is a preview of the result: the architecture is dominant inside a
   turn-based / verifiable / merits sub-game and structurally loses outside it (one-shot interim
   proceedings, free evaluation of evidence, off-record attrition, the human-approval bottleneck).
   *A convergence that is genuine signal wins where it claims to; a convergence that is a shared
   frame wins only inside the frame.* The existing evidence says the latter. `[DESIGN-ENTAILED against
   the canon text; HYPOTHESIS as to real cases]`

3. **Divergent-frame human baseline.** Commission architectures from humans with *deliberately
   different* entry frames — an institutional economist, a Bayesian decision theorist, an appellate
   judge. If they reproduce the propose/check core, that is cross-frame corroboration (signal). If a
   Bayesian decision theorist produces something the three could not represent (they cannot — see
   Q3), the convergence was frame-bound. `[EMPIRICAL — untested]`

**Bottom line on Q1:** the convergence is *reassuring but not evidential* where it echoes the prompt,
*genuine but about jurisprudence not architecture* where it recalls legal theory, and *most
dangerous exactly where it is most unanimous* — the unanimity on the verification-machine frame and
on an identical weakness-list is the fingerprint of a shared blind spot, and only tests (1) and (2),
which have **not been run**, can settle it. Until then, "three teams agreed" must never be cited as
supremacy evidence. **BLOCKING** for any such citation.

---

## Q2 — Diff table: genuine disagreements vs. vocabulary-only

### Part A — SAME MECHANISM, different vocabulary (NOT real disagreements; do not adjudicate)

| Concept | Design A | Design B | Design C | Verdict |
|---|---|---|---|---|
| Trusted deterministic core | "Epistemic Kernel" (B0/T1) | "TCB kernels" | "Policy Kernel + Ring 1" | Identical: small, non-LLM, deterministic. Vocabulary. |
| The master seam | "Propose/Check split" | "reasoning periphery ↔ TCB, B1" | "Ring 3 → capability broker" | Identical inbound-proposal-only boundary. Vocabulary. |
| Matter isolation | capability-scoped compartments | capability tokens, per-matter keys | capability set per matter | Identical: isolation = *absence of a handle*. Vocabulary. |
| Ethical walls | deny-by-default ACL, no capability minted | capability revocation | absence of capability | Identical. Vocabulary. |
| Publication gateway | 6-stage fail-closed (§12) | 6-stage fail-closed (Part 11) | 7-stage fail-closed (Part 9) | Same pipeline, ±1 stage granularity. Vocabulary. |
| Multi-world facts | "admissible factual worlds" + ASPIC+ | "alternative factual reconstructions" + conflict graph | "factual hypotheses" + conflict edges | Identical epistemic commitment. Vocabulary. |
| Conflicting authorities | partial order + defeasible meta-norms | conflict graph, contested priorities | conflict edges + resolution-rule nodes | Identical. Vocabulary. |
| Memory / replay | same-version + current-version, record-replay caveat | same-version + current-version, same caveat | same-version + current-version, same caveat | Identical, *including the caveat*. Vocabulary. |
| Provenance | AuthorityRef@interval | provenance graph / claim-ledger | provenance-first record | Identical. Vocabulary. |
| Self-improvement | propose → adversarial gauntlet → human merge | propose → adversarial test → human merge | propose → replay+adversary → 2-person merge | Identical. Vocabulary. |
| Internal adversary | Breaker agents, fresh context [0047] | opponent-agent, fresh context | adversarial reasoner, no author state | Identical (all cite the same CLAUDE.md protocol). Vocabulary. |

Eleven of the "convergent" points are one mechanism under three names. This is what Q1-Layer-a/b
predicts.

### Part B — GENUINE DISAGREEMENTS (real trade-offs; a human must decide)

| # | Axis | Design A | Design B | Design C | The trade-off to decide |
|---|---|---|---|---|---|
| **D1** | **Top-level objective** | Honest *representation* of the argument space is the goal; "superiority" = maximal honest coverage under a checker. | *Winning the adversarial game* is the goal; "knowledge is necessary and radically insufficient" (Part 0). Adds an entire strategy layer: L1–L8 victory levers, BATNA/settlement, forum/tempo. | *Accountable institutional properties* (recall, review-independence, isolation, auditability) are the goal; explicitly **no** advantage claimed on judgment. | Is the system a **truth-engine** (A/C) or a **game-engine** (B)? A/C build a prover; B alone even names settlement, tempo, forum, opponent-modelling. This is the deepest real divergence and it decides what the system optimizes and measures. `beat-the-canon.md` confirms A/C build the "proof machine that is blind to the larger game"; B is a partial exception. |
| **D2** | **Discretion / judge prediction** | Irreducible CHOICE node; **refuses** to predict; surfaces options only. | **Offers empirical base rates** — "how this bench resolved similar balances," tagged EMPIRICAL, with its own risk-flag W2 (prediction-dressed-as-law). | Reserves to human; **refuses** point-prediction ("weights that are arguments, not scalar confidence"). | Should the system quantify likely discretionary outcomes (B: useful decision-support, risk of misread) or refuse (A/C: austere, honest, less useful)? Genuine value/ethics trade-off. |
| **D3** | **Is a probabilistic classifier INSIDE the TCB?** | No — DLP is a "deterministic scan"; all classifiers pushed to untrusted side. | No — DLP "deterministic scan," classifiers untrusted. | **Yes, admittedly** — "the Gate Evaluators must include at least one inherently-imperfect classifier (confidentiality/PII over free text)… the honest crack in the small-TCB story" (Part 2). | A/B claim confidentiality/DLP can be a deterministic predicate; C says detection over free text is *irreducibly* a classifier and therefore a false-negative sits at TCB level. **C is more honest and `formal-boundaries.md` sides with C** (DLP over free text is A1-tested at best, never A3). This is a decidable technical disagreement with real security consequences. |
| **D4** | **What "superiority" denotes (⇒ what you benchmark)** | Argument-space **coverage** under a sound checker (partial order, refuses a global best). | **Outcome** — did matters fare better vs. elite opponents (outcome study, W8). | Enumerable **institutional axes** (recall/independence/isolation/auditability), never judgment. | Determines the whole evaluation regime. A measures coverage vs. expert annotation; B demands an outcome study; C measures reviewable-surface and isolation red-teams. Not reconcilable into one metric — a human must choose the yardstick. |
| **D5** | **Deadline liveness vs. fail-closed** | Named as *weakness* W9, not architected away. | **Architected**: independent, redundant, high-availability deadline "watchtower" that fails **loud**, separate from the reasoning plane (Part 9). | **Architected**: same watchtower pattern (Part 11), deadline path HA-independent of reasoning plane. | A leaves the fail-closed-vs-missed-deadline tension open; B/C resolve it with a dedicated independent liveness path. Closer to a completeness gap in A than a true three-way disagreement, but the resolution differs enough to decide. |

**Net Q2:** the *headline* convergence (Part A, 11 items) is real but low-information — it is the
prompt echoing back. The *decisions that actually require a human* are D1–D5, and on the two biggest
(D1 objective, D3 classifier-in-TCB) the designs genuinely part ways. Note D1 and D2 are the same
fault line `beat-the-canon.md` isolates: A/C are austere provers; B reaches toward the game and the
decider, and is the only one that would not be "honest-but-unarmed" on the discretion axis — yet even
B stays a *preparation* engine and does not build the off-record organ.

---

## Q3 — The shared blind spot: a strong architecture ALL THREE failed to consider

### The shared commitment that hides it

All three equate **"trusted"** with **"deductive / deterministic checking of a static artifact,"**
and equate **"quantified uncertainty"** with **"dishonest guessing to be refused."** This is a single
unexamined prior, and it is enforced *explicitly and identically*:
- A §7.4: **refuses** scalar probability, calls representing burdens as Bayesian "a dishonest
  formalization"; any probabilistic model is a "proposer heuristic… never enters the trusted
  labeling."
- C §7.2: rejects "scalar confidence pretending to be probability."
- B §6.4/L6: *uses* "explicit inspectable probabilities" for BATNA but with **no verification
  regime**, and disclaims "it cannot supply the true probabilities… foreground the assumptions, not
  the number."

Consequently the system's only trustworthy epistemic act is deductive form-checking, and its only
honest response to uncertainty is a partition of worlds plus UNKNOWN. **The entire branch of
*verifiable probabilistic reasoning* is unexplored** — and its absence is corroborated at the
meta-level: `formal-boundaries.md`'s assurance lattice (A0–A4, F0–F3) is **wholly deductive**; it has
**no axis for a calibrated-forecast guarantee.** The blind spot is shared even by the formal-methods
team. `[DESIGN-ENTAILED — visible directly in the four documents]`

### The unexplored alternative (concrete): a co-equal **Calibration / Forecast-Verification spine**

Add a *second trusted spine* whose job is not "is this deduction valid?" but "is this probability
**calibrated**, with a machine-checkable coverage guarantee?" Concretely:

- **Conformal prediction** gives distribution-free, finite-sample **coverage THEOREMS**: it emits a
  *prediction set* guaranteed to contain the true outcome with probability ≥ 1−α under exchangeability
  — e.g. "under this bench, on this balancing test, the outcome lies in {grant, partial-grant} with
  guaranteed ≥90% coverage." This is neither a fabricated point prediction (A/C's fear) nor a refusal
  (the honest-ignorance default) — it is a *quantified honest answer with a real guarantee*.
  `[THEOREM for the coverage property under exchangeability; EMPIRICAL for whether legal data is
  exchangeable — see limits]`
- **Proper scoring + backtesting** as the verification discipline: the forecast layer is trusted the
  way a weather service is trusted — not by inspecting its reasoning but by *empirically demonstrated
  calibration* against realized outcomes (reliability diagrams, Brier/log-score over a held-out,
  matter-disjoint outcome set). This is a genuine, non-deductive assurance stratum the whole corpus
  lacks — call it an **F-for-forecast axis** orthogonal to `formal-boundaries.md`'s A/F axes.
- **Decision-theoretic layer** on top: settle/fight, forum choice, and *which deadline-risk to
  accept* become explicit expected-value / minimax-regret decisions over the calibrated distribution,
  surfaced to the human authority — not replacing the human, informing the irreducible choice B's L6
  and A's discretion node both leave under-served.

### Why it is plausibly superior — and precisely where

It directly attacks the exact axis all three concede they *lose* on and that `beat-the-canon.md`
Exploits 2/4/6 weaponize: **discretion, settlement, evidence-weighing, and deadline-risk trade-offs.**
Crucially it does so **without abandoning honesty** — which is why the corpus missed it. The corpus
frames the choice as binary: honest-refusal (A/C) vs. dishonest-confidence (beat-the-canon's CA-3,
which it correctly rules a *contradiction* of the honesty invariant). Conformal coverage is a **third
option the binary hides**: a probability that is *itself a theorem-backed object*, so it can sit on a
trusted path without violating "no guessing." It threads the needle the whole corpus believes cannot
be threaded. On D2 it dominates both A/C's refusal and B's uncalibrated base rates (B's own W2 risk —
base rates misread as law — is exactly what a *coverage guarantee with stated α* mitigates).
`[HYPOTHESIS — superiority is plausible and argued, not demonstrated]`

### Honest limits (no free lunch — stated, not hidden)

- **Exchangeability is the probabilistic formalization gap.** Conformal guarantees assume the future
  resembles the calibration set; law is non-stationary (statutes amend, CJEU/ECHR rulings shift the
  distribution) and the **reference-class problem** (which prior cases are "like" this one) is a
  modelling choice made silently — the exact analog of the NL→formal gap, and the exact thing
  `beat-the-canon.md`'s anti-gerrymandering guard (BO-29) forces to UNKNOWN. So the second spine has
  its *own* irreducible fidelity ceiling; it converts refusal into a *guaranteed-but-assumption-laden*
  answer, which is progress, not a solve. `[THEOREM-adjacent: the coverage guarantee is conditional
  on exchangeability, which is empirical and defeasible]`
- **Goodhart / gaming:** a forecast target can be gamed; calibration must be measured on
  outcomes the system did not choose. `[HYPOTHESIS]`
- It is **additive, not corrective:** it does not replace the deductive spine; it adds a component
  with a *different, empirical* assurance regime — and adding it re-opens `formal-boundaries.md §6`'s
  BLOCKING tension between "0 error" and empirically-bounded claims, now for probabilities too.

### A second, structurally different unexplored architecture (secondary)

**Externally-verifiable trust via zero-knowledge attestation.** All three keep the checker and
authority store *internal* — the firm asks the world to trust its private fail-closed gateway. None
considered making the gateway's guarantees **externally checkable without disclosure**: ZK proofs
that "every citation in this filing resolves to a real authority in a versioned store" and "no
privileged datum crossed the egress predicate," verifiable by an auditor, opponent, or court *without
revealing privileged content*. In the `frontier-2026.md` environment (1,490+ AI-fabrication
sanctions, first bar suspension), the ability to *prove non-fabrication and non-leakage to a third
party* is a real, unexplored superiority axis. **Limit:** it proves *form and provenance*, not
*legal fidelity* (same formalization gap), and tribunals do not yet consume such certificates —
`beat-the-canon.md` Part 5 concedes exactly this ("if tribunals consume machine-checkable
submissions… today's do not"). Superior on auditability/credibility; inert until adoption.
`[HYPOTHESIS]`

### The scope-level blind spot (named for completeness, not novel to this audit)

A and C are additionally blind to the **off-record / attrition / tempo / discretion game**; B
partially sees it (Part 1) but still stops at "prepare; human acts." `beat-the-canon.md` already
surfaces this and (correctly) classifies the missing organs as *absorbable* scope gaps rather than an
architectural alternative — so it is a real shared gap of A/C but not the *architecture* the brief
asks me to name. The two architectures above (calibration spine; ZK attestation) are the genuinely
unexplored *architectures*.

---

## BLOCKING items carried forward (not smoothed)

1. **"Three teams converged" is not evidence.** Layer-a convergence echoes the shared prompt; the
   distinguishing prompt-ablation (Q1 test 1) and ground-truth red-team (test 2) are **unrun**. No
   supremacy or "right architecture" claim may cite the convergence until at least test 1 runs.
   **BLOCKING.**
2. **D3 (classifier in the TCB) is an unresolved three-way technical contradiction.** A/B assert a
   deterministic DLP predicate; C and `formal-boundaries.md` say confidentiality-over-free-text is
   irreducibly a classifier at TCB level. This decides whether "small honest TCB" is real.
   **BLOCKING until resolved.**
3. **The verification-machine frame (Q1-Layer-c) is a shared blind spot by construction.** The
   corpus's own honesty regime cannot detect a blind spot the corpus shares; only a genuinely
   divergent-frame baseline (Q1 test 3) or the calibration-spine / ZK alternatives (Q3) probe it.
   **BLOCKING against treating the confessed-weakness list as exhaustive.**
