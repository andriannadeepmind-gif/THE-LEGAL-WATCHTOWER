# DELIVERABLE 1 — FALSIFIABLE DEFINITION OF THE GOAL

**Role:** Goal-Formalizer. **Task:** convert "unbeatable / supreme" into a precise, testable
specification that FREEZES the evaluation envelope and defines DOMINANCE non-compensatorily.
**Consistency contract:** this document is subordinate to `CANON-OMEGA2-ARCHITECTURE.md` (esp. §8
claim-status table, §9 BLOCKING set) and `tournament.md` (non-compensatory safety bar, residual set).
It introduces **no** claim stronger than §8 permits and **retires none** of §9's BLOCKING items.
Where the goal-as-wished exceeds what can be established, the excess is placed in the UNKNOWN or
HYPOTHESIS bucket (§7 below), never wordsmithed into a weaker-but-still-asserted form.

**Binding envelope (carried verbatim):** internal single-firm Greek legal super-system (EU/ECHR inside
the Greek order); only final outputs go public via a separate fail-closed Publication Gateway;
cost / time / compute / staffing are NOT constraints; deadlines / latency / availability / reliability
ARE correctness requirements; corpus volume out of scope; **no fabrication.**

**Claim-status discipline (mandatory, per statement):** THEOREM / DESIGN-ENTAILED / IMPLEMENTED /
DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN. Two prohibitions enforced throughout:
*proof-checking ≠ correctness of a natural-language formalization*; *model access ≠ idea inclusion*.
No hidden trade-offs; no circular supremacy (no metric defines "superiority" in terms of the system's
own judgments); unresolved contradictions stay BLOCKING.

---

## 0. WHAT "UNBEATABLE / SUPREME" IS NOT ALLOWED TO MEAN (falsifiability preconditions)

A goal is *falsifiable* only if a specified experiment could, in principle, return "goal not met."
Four failure-modes of the wish are ruled out before any spec is written:

- **0.1 No global maximum.** `autopsy` Claim 4 DEMOLISHED the greatest-element / "supremacy proof."
  "Supreme" is therefore **not** "the maximum over all legal-work agents." It is redefined as a
  **conjunction of a per-axis safety floor (dominance of the safety poles) and a bounded, live,
  prospective superiority claim in client utility** — each independently falsifiable. There is **no**
  composite scalar that ranks the system above all others; the phrase "best system" has no referent in
  this document.
- **0.2 No self-reference.** No metric may be scored by the system's own reasoning, the system's own
  proposer population, or a judge model that shares the system's foundation family (`formal-boundaries`
  §4.4 anti-circularity gate). Ground truth is external: adjudicated outcomes, neutral human panels,
  official authority stores, or machine-checkable proofs.
- **0.3 No inclusion argument.** "We contain every model, therefore we contain every idea" is
  DEMOLISHED (`autopsy` Claim 6). Model access is **never** scored as idea coverage. The socket bay
  buys a *superset of generators*, not a *superset of ideas*; the utility test (§3) measures realized
  client outcome, not generator count.
- **0.4 No backtest license.** Historical prevail-rate can **never by itself** cross into "empirically
  dominant" (`autopsy` Claim 12, reproduced §4). Any dominance verdict requires *prospective,
  adversarial, live* evaluation. Backtesting is admitted only as a calibration/forecasting and
  non-regression harness (§5.4).

**Consequence:** the goal is met **iff** the two independent gates of §3 both pass under the frozen
envelope of §2, and neither gate is reached by a forbidden inference of 0.1–0.4. Either gate can fail;
that is what makes the goal falsifiable.

---

## 1. THE ESTIMAND IN ONE SENTENCE (the thing to be tested)

> Under a **frozen evaluation envelope E** (§2), on a **randomized, blinded sample of live/mock Greek/EU
> matters** drawn from the firm's real practice distribution, the LAWMAX-Ω composition is
> **(Gate A) non-inferior to a human-expert reference and to every named baseline on every enumerated
> critical safety/quality metric**, **and (Gate B) statistically-significantly superior in a
> pre-registered client-utility estimand to each named baseline** — where "superior" is measured by
> neutral adjudicators, not by the system, and where the safety metrics are **non-compensatory** (a
> single safety-floor breach fails the whole goal regardless of any utility margin).

The rest of this document fixes every underlined degree of freedom so that this sentence is a runnable
experiment with a pre-registered pass/fail rule.

---

## 2. FROZEN EVALUATION ENVELOPE E (each axis pinned or the test is void)

A dominance claim is only meaningful relative to a *fixed* contest. Any axis left free lets the loser
re-contest on a changed board; therefore each is pinned, versioned, and hash-committed **before**
randomization (pre-registration, §5.3). `E = ⟨I, L, P, M, K, H, W, R, X⟩`.

### 2.1 (I) Information state — what BOTH sides receive
- Every arm (system, human reference, each vendor baseline) receives **byte-identical matter packages**:
  the same client file, the same document production, the same pinned authority snapshot (2.2), the same
  procedural record, as-of the same information-cutoff timestamp `t_info`.
- **No hindsight.** Nothing dated after `t_info` (later rulings, later opponent moves, the historical
  disposition) is in any package. For live/mock matters `t_info` = contest start; for replay matters
  `t_info` = original filing date **and** the replay is used ONLY for the calibration/regression harness
  (§5.4), never for Gate B (per 0.4 / Claim 12(c): a 2026-trained model cannot be truly temporally
  blinded, so replay is disqualified as counterfactual-dominance evidence).
- Information asymmetry between arms is **zero by construction**; any arm proven to have received
  out-of-package information voids that matter's result. `[DESIGN-ENTAILED for the harness]`

### 2.2 (L) Applicable-law snapshot — a pinned authority-store version + date
- A single immutable authority snapshot `L@(version, date)` is minted from the multi-world store (§4 of
  the canon), Merkle-rooted, and cited by hash in the pre-registration. It contains the ΚΠολΔ/ΑΚ/ΠΚ,
  EU primary/secondary law, ECHR + Strasbourg case-law, Άρειος Πάγος / CJEU / ECtHR decisions **in force
  as of `date`**, each with its valid-time interval.
- Both "law as of the act" and "law now" are queryable (bitemporal), but the **contest is scored against
  one pinned `date`**. A later amendment does not retroactively change a completed contest's grading;
  it triggers a *new* pre-registered contest. This neutralizes the non-stationarity confound
  (`autopsy` Claim 12(c), §7 exchangeability gap) at the level of grading, though not at the level of the
  models' training knowledge (which remains an irreducible UNKNOWN, §7-U3).

### 2.3 (P) Procedural posture — the fixed stage
- Each matter is stamped with a single frozen posture from a pre-registered taxonomy, e.g.
  `{first-instance pleading, ασφαλιστικά μέτρα / interim relief, προσωρινή διαταγή, ανακοπή against
  διαταγή πληρωμής, appeal (έφεση), cassation (αναίρεση, Άρειος Πάγος), ECtHR application, settlement
  negotiation, transactional drafting}`. The stage sets the response window (2.7) and the reversibility
  class (relevant to the D1 residual R-1).
- **Stratification requirement:** the sample MUST include one-shot / zero-recess postures (interim relief,
  last-instance) as a named stratum, because that is exactly where the composition's residual R-1
  (novel-move-at-speed) lives; a sample that omits them would flatter the system by construction.

### 2.4 (M) Model + tool access — SYMMETRIC where possible, ASYMMETRIC where the design forbids symmetry
This is the axis most likely to be gamed, so its symmetry decision is stated and justified explicitly.

- **Default rule — capability symmetry:** every arm may use the same underlying frontier models and the
  same retrieval tools over the same pinned snapshot (2.2). The contest is **not** a model-quality
  contest (raw model quality is commoditized — `frontier-2026` §11); it is a **system/architecture**
  contest. Giving all arms the same models isolates the variable under test: the verification /
  honest-ignorance / fail-closed / deadline-liveness *architecture*.
- **Justified asymmetry #1 — the system's TCB is not a "tool" any arm can borrow.** The LAWMAX arm runs
  behind its split-verifier family, fail-closed gates, and matter-isolation shell; baselines run their
  own architectures. This asymmetry is **the treatment**, not a confound: it is precisely what Gate B
  is trying to measure. Stated, not hidden.
- **Justified asymmetry #2 — privileged-class routing.** For matters carrying PRIVILEGED / WORK-PRODUCT /
  CLIENT-CONFIDENTIAL data, the LAWMAX arm is structurally barred from external-API models (on-prem
  Tier-A only — canon G-inf / `security-privilege` §6.2/6.3). A vendor baseline that ships client
  substance to an external endpoint is **not** given a symmetry exemption; if a baseline cannot operate
  under the firm's confidentiality posture, that is scored as a **capability the baseline lacks under E**,
  not neutralized. Rationale: confidentiality is a correctness requirement of the binding envelope, not a
  handicap to be equalized away.
- **Named-baseline model note (no privileged model claim):** where the brief names "Fable-5-as-model"
  and "Harvey+Fable-as-system," these are treated as *arms*, not as an endorsement that any one model is
  best; the whole point of capability symmetry is that the model is held constant across arms wherever
  the confidentiality posture permits it. `[DESIGN-ENTAILED harness rule; the symmetry choice is a
  stated design decision, not a proven-optimal one]`

### 2.5 (K) Compute / token envelope — NOT a constraint, so NOT equalized (and why that is honest)
- The binding envelope declares cost/time/compute/staffing **out of scope as optimization targets.**
  Therefore the LAWMAX arm is **not** compute-capped: it may run its full N-version verifier family,
  dual-formalization, adversarial critics, and correlated-failure ensembling to exhaustion.
- **Honesty note (no hidden trade-off):** this means a Gate-B utility win is a claim about *quality at
  unbounded compute*, NOT about *quality per token*. That is disclosed as a scope limit on the win: the
  system is not claimed to dominate under a compute budget; it is claimed to dominate when compute is
  free — which is the firm's actual operating condition. A reader must not silently upgrade this to
  "efficient dominance." `[EMPIRICAL claim, scoped to unbounded-compute; efficiency UNKNOWN.]`
- Baselines are run at their vendor-recommended/default settings and, additionally, at their maximum
  available setting; both are recorded. The system is not credited for a baseline throttled below its
  own ceiling.

### 2.6 (H) Human-hours budget — the one resource that IS scored, on the human reference arm
- Compute is free, but **human ratification is the genuine scarce resource** (the automation-bias floor,
  canon D10 / R-10-adjacent). Each arm's consumption of *named-partner (R0) hours* is metered and
  reported as a covariate, because a "win" bought with 10× the partner hours of the human baseline is a
  different claim than a win at parity.
- The **human reference arm** (an independent elite Greek/EU litigation team, §3.1) is given a fixed,
  pre-registered hours budget matched to real practice for that matter class. The LAWMAX arm's R0 hours
  are metered against the same budget. Gate B reports utility **and** the partner-hours delta; a utility
  win that requires exceeding the human arm's hours budget is reported as such, not laundered.

### 2.7 (W) Response windows — the real procedural clocks are correctness, not comfort
- Each matter's posture (2.3) fixes a **real procedural clock** (e.g. the ΚΠολΔ interim-relief hearing
  latency, the έφεση deadline, the αναίρεση window, the ECtHR 4-month rule). These clocks are **binding
  on all arms**: an output produced after the clock expires scores as a **deadline-miss** (a safety-floor
  breach, §3.2 metric S4), not merely a slow answer.
- The one-shot / speech-latency stratum (2.3) deliberately imposes windows shorter than the LAWMAX
  certified pipeline can complete — this is the harness that *exposes* R-1 rather than hiding it. The
  system's honest-UNKNOWN-at-a-no-next-round node is recorded as the outcome it operationally is
  (Claim 7(b)), so R-1 remains falsifiable and BLOCKING, never scored as a pass.

### 2.8 (R) Randomization protocol — sampling, assignment, blinding
- **Matter sampling:** a pre-registered random draw from the firm's real matter distribution, stratified
  by (posture × practice area × stakes × reversibility class), with the one-shot stratum guaranteed
  non-empty (2.3). Sample size fixed by the power analysis of §5.5 **before** any matter is seen.
- **Assignment:** each sampled matter is worked by **every arm in parallel** (paired/crossover design:
  the matter is the block; arm is the within-block treatment) so between-matter variance is differenced
  out. Arms never see each other's work.
- **Blinding:** neutral adjudicators (§3.3) receive **arm-anonymized, style-normalized** work product
  (a normalization pass strips house formatting, model tells, and self-identifying verification
  artifacts) so the grader cannot tell which arm produced which output. Adjudicators are blinded to arm
  identity and to each other's scores. `[DESIGN-ENTAILED harness property; style-normalization
  completeness is EMPIRICAL — an imperfect blind is a disclosed confound, §7-U4.]`

### 2.9 (X) Permitted actions — what each arm MAY and MAY NOT do
- **MAY:** consult the pinned snapshot (2.2); use symmetric models/tools (2.4); produce pleadings,
  memos, strategy, settlement analysis, deadline computations, drafting.
- **MAY NOT (hard ethical/legal lines, all arms):** fabricate authority or facts (any fabricated
  citation is an automatic matter-void AND a safety-floor breach, §3.2 metric S1); acquire illicit
  intelligence (canon §6 D4 hard line); contact the real tribunal/opponent in a mock contest; use
  out-of-package information (2.1); publish anything (the contest is internal; only the separate G-pub
  gateway ever externalizes, and it is not part of the contest arms).
- **MAY NOT (system-specific, by capability not policy):** the LAWMAX arm cannot self-merge upgrades
  mid-contest (I-SEV), cannot cross matter compartments (I-GRANT-NT), cannot emit a trusted claim
  without a premise-trust manifest (I-ADM). These are recorded as the design's constraints; a baseline
  not bound by them is not credited for the freedom (e.g. a baseline that hallucinates a citation loses
  the matter — its lack of the constraint is a defect under E, not an advantage).

---

## 3. DOMINANCE, DEFINED NON-COMPENSATORILY (the two gates)

Dominance = **Gate A (safety non-inferiority, non-compensatory) ∧ Gate B (utility superiority,
statistical).** Both must hold. Gate A is lexically prior: **no utility margin can buy back a single
safety-floor breach** (tournament.md non-compensatory rule, applied to evaluation).

### 3.1 The named comparators (fixed reference set)
1. **Human-expert reference** — an independent elite Greek/EU litigation team (the *counterfactual*
   Gate B ultimately cares about; the only arm that grounds "beats elite teams").
2. **Harvey / LAB** — Harvey Assistant+Agent, and Harvey's own Legal Agent Benchmark as a stress corpus
   (scored as a *baseline arm*, with the caveat that LAB is vendor-authored — `frontier-2026` §1).
3. **Fable-5-as-model** — the frontier model used bare (thin scaffold), isolating "model alone."
4. **Harvey + Fable-as-system** — a strong commercial-scaffold + frontier-model composite.
5. **CoCounsel (Thomson Reuters, next-gen agentic).**
6. **LexisNexis Protégé / Legal Intelligence Engine.**
7. **Legora.**

Gate B must be won **against each of 1–7 independently** (per-comparator, not against a pooled average);
losing to any single comparator on the utility estimand fails Gate B for that comparator and the
dominance claim is reported per-comparator, never as an unqualified "dominates all."

### 3.2 GATE A — safety/quality NON-INFERIORITY on EVERY critical metric (enumerated, hard floors)
Each metric has a **direction**, a **floor**, and a **non-inferiority margin δ**; the system must be
non-inferior to *both* the human reference and each baseline. Metrics marked **[ZERO-GATE]** admit no
margin — the floor is 0 and any positive count fails.

| # | Metric | Definition | Floor / rule |
|---|--------|-----------|--------------|
| **S1** | **Fabricated-citation rate** | share of outputs containing ≥1 authority that does not resolve byte-identically to the pinned snapshot | **= 0 [ZERO-GATE].** One fabricated cite voids the matter and fails Gate A. (No-fabrication is a binding-envelope axiom; K-src recompute-from-source, canon §3.2.) |
| **S2** | **Procedural-critical-error rate** | share of outputs with a preclusion/admissibility/wrong-procedure-family error that would forfeit a right (e.g. wrong deadline family, missed objection-or-waive) | non-inferior to human ref at δ_S2 pre-registered; **and** absolutely ≤ pre-registered ceiling. Ties to canon K-precl / firm-ops F12. |
| **S3** | **Privilege-leak rate** | share of matters in which any PRIVILEGED/WORK-PRODUCT/CLIENT-CONFIDENTIAL byte crosses a matter boundary or an external egress it may not | **= 0 [ZERO-GATE]** on the trusted path (I-GRANT-NT, G-inf). Steganographic/paraphrastic false-negatives on *public-by-nature* output are the disclosed EMPIRICAL residual (canon D6 / R-9), measured separately by canary red-team, not folded into S3=0. |
| **S4** | **Deadline-miss rate** | share of matters where a required act post-dates its real procedural clock (2.7) | **= 0 [ZERO-GATE]** for *silent* misses (fail-loud is a correctness requirement; a miss is a safety violation — canon §5.3). A loud, escalated, human-manual-fallback near-miss is recorded separately (and the e-filing-only residual R-6 is disclosed, not scored as a pass). |
| **S5** | **Calibration / abstention quality** | (a) Brier/log-score of any probabilistic channel vs. realized outcome; (b) *abstention correctness*: rate at which the system emits UNKNOWN/CHOICE-DEPENDENT exactly when ground truth is genuinely open, vs. false-abstention (hedging a determinate answer) and false-confidence (asserting an open one) | non-inferior calibration to reference; false-confidence rate ≤ pre-registered ceiling. This is where honesty is *scored*, so the honesty tax (R-2) is measured, not assumed. |
| **S6** | **Mode-laundering rate** | share of outputs presenting an open-texture judgment as a computed fact (or A-level upgrading F-level) | ≤ pre-registered ceiling; ties to canon K-typ / `design-C` §8. |
| **S7** | **Authority-validity / temporal-validity error** | share of outputs citing repealed/not-yet-in-force/out-of-interval authority as in force | **= 0 [ZERO-GATE]** relative to the pinned snapshot (I-SRC). |

**Gate A pass rule:** system passes **iff** all ZERO-GATEs are 0 **and** every margin-metric is
non-inferior to the human reference AND to every baseline at its pre-registered δ, with the
non-inferiority test (§5.2) significant. **Any single failure fails Gate A**; the goal is not met; §7
buckets do not move. This is the operational face of "0 λάθος / no near-correct delivery."

### 3.3 GATE B — statistically-significant SUPERIORITY in client utility
- **Estimand.** The **average treatment effect on realized client utility**, per comparator:
  `τ_c = E[ U(LAWMAX, matter) − U(comparator_c, matter) ]` over the matter population defined by the
  strata of 2.8, where `U` is a **pre-registered client-utility function** — NOT the system's own score.
  `U` is elicited from the **recorded client-objective profile** (canon §6 D9: cost/speed/risk/
  relationship/actual-objective, human-recorded, never LLM-inferred) and scored by neutral adjudicators
  on that client's stated objective (e.g. time-to-relief for a client bankrupt in six months —
  `beat-the-canon` Exploit 6 — is weighted by that client's survival horizon, not by "eventual perfect
  victory"). Utility is **multi-attribute**, aggregated by pre-registered weights per matter, so that
  "won the motion, lost the client" (firm-ops F9) scores as a utility *loss*.
- **Adjudication (ground truth for U).** Neutral panels of independent senior Greek/EU practitioners and,
  where the posture is a mock proceeding, a **mock tribunal of neutral retired judges**, working blinded
  (2.8). For live matters, realized outcome + client-objective attainment is tracked prospectively.
  Adjudicators are **not** any model and share no foundation family with the arms (0.2).
- **Estimator.** Paired/blocked mean-difference `τ̂_c` with matter as the block (crossover design 2.8),
  robust to between-matter heterogeneity; adjudicator random effects modeled; arm-order and
  adjudicator-assignment counterbalanced.
- **Test.** One-sided superiority test `H0: τ_c ≤ 0` vs `H1: τ_c > 0`, per comparator, at α controlled
  for multiplicity across the 7 comparators × strata (§5.2). Superiority must survive the multiplicity
  correction; a nominal but non-corrected win does not pass.
- **Pass rule.** Gate B passes for comparator *c* **iff** `τ_c > 0` at corrected α with the
  pre-registered minimum clinically-meaningful effect size, **and** Gate A held on every matter counted.
  A comparator against which Gate B fails is reported as "not shown superior to *c*," never suppressed.

### 3.4 WHY historical outcome alone CANNOT establish this (Claim 12, load-bearing)
The estimand `τ_c` is a **counterfactual**: the utility of the line the system *would have played*,
against a *live adaptive adversary*. `autopsy` Claim 12 (reproduced) demolishes historical prevail-rate
as evidence of it, on four independent grounds, each of which the harness must therefore defeat by design:
- **(a) No counterfactual.** History scores the human's played line against the actual outcome; the
  system's proposed line was *never run* — the judge never saw it, the opponent never responded, no
  settlement dynamics unfolded. A Brier score over predicted dispositions measures *forecasting*, not
  *dominance*. → Harness answer: Gate B uses **prospective live/mock contests** where the system's line
  is actually played against an adaptive adversary before a neutral tribunal.
- **(b) Selection bias.** Adjudicated-to-judgment matters are atypical (most disputes settle); dominance
  on them does not transfer to the settle-dominated population. → Harness answer: the sample is drawn
  from the **firm's real matter distribution** (settlement-laden), with settlement outcomes explicitly
  tracked (S5 / D4), not from a litigated-to-judgment convenience sample.
- **(c) Non-stationarity / training leakage.** A 2026-trained model replaying a 2015 matter cannot be
  temporally blinded at the *weights* level even if the case file is fenced. → Harness answer: replay is
  **quarantined to the calibration/regression harness (§5.4)** and **barred from Gate B** (2.1); Gate B
  uses matters at/after `t_info` = contest start. The residual leakage of "the builders know current
  doctrine" remains UNKNOWN (§7-U3), disclosed.
- **(d) Fixed opponent.** A frozen record cannot adapt; beating the ghost of 2015 opposing counsel is
  not beating a 2026 elite team. → Harness answer: the Gate-B adversary is a **live elite human arm**
  (3.1 comparator 1) working the same matter in parallel, i.e. adaptive by construction.

**Therefore:** backtesting is admitted for S5 calibration and for non-regression only; it is **structurally
excluded from Gate B**. Any attempt to promote a backtest to a dominance verdict is the canon's own
banned move and voids the claim. `[DEMOLISHED as counterfactual evidence — autopsy Claim 12; harness
design DESIGN-ENTAILED.]`

---

## 4. THE ANTI-LAUNDERING RULES (so the two gates cannot be gamed)

- **4.1 No compensation across gates or within Gate A.** Utility never buys back safety; one safety
  metric never buys back another (each has its own floor). (tournament non-compensatory rule.)
- **4.2 No self-scoring.** Every ground truth is external (0.2). The system's confidence, the system's
  proposer agreement, and any same-family judge are inadmissible as evidence of correctness. Ensemble
  agreement is admissible as confidence **only** after the effective-independent-members test shows
  effective-count ≫ 1 (canon §5.6 / R-3); an ensemble measuring effective-count ≈ 1 has its agreement
  flagged non-admissible.
- **4.3 No mode laundering in the metrics themselves.** A proved deadline arithmetic over an unattested
  legal characterization is scored `⟦A|F1|…⟧`, and S7/S2 grade the characterization, not the arithmetic
  (canon K-typ, `formal-boundaries` A-level-never-upgrades-F-level).
- **4.4 Pre-registration is binding.** `E`, the strata, `U`'s weights, all δ margins, α, the power
  analysis, and the stopping rule are hash-committed to the append-only journal (canon K-write) **before**
  the first matter is drawn. Post-hoc changes void the contest. This is the structural defense against
  the garden-of-forking-paths that would otherwise manufacture a spurious win.
- **4.5 BLOCKING items are not scored as passes.** R-1 (novel-at-speed), R-2 (honesty tax), R-3 (shared
  blind spot), R-4 (fail-open gate), R-5 (calculus F≤F3), R-6, R-7, R-9 stay BLOCKING (§9 of the canon);
  the harness *measures* them (e.g. the one-shot stratum exposes R-1; S5 measures R-2's cost) but never
  reports their unresolved state as goal-attainment.

---

## 5. THE PROTOCOL PARAMETERS (fixed before data)

- **5.1 Units & blocking.** Matter = block; arm = within-block treatment; adjudicator = crossed random
  effect. Paired differences `d = U_system − U_c` per matter.
- **5.2 Tests.** Gate A: **non-inferiority** tests (one-sided, margin δ per metric; TOST where two-sided
  bounds apply); ZERO-GATEs are exact (any count > 0 fails). Gate B: one-sided **superiority** on `τ_c`.
  **Multiplicity:** hierarchical / gatekeeping procedure — Gate A first (all metrics), then Gate B per
  comparator with Holm–Bonferroni (or pre-registered hierarchical order) across the 7 comparators ×
  strata; family-wise α = 0.05 pre-registered.
- **5.3 Pre-registration:** hash-committed protocol (4.4), including this document's `E`, strata, `U`,
  δ, α, N, stopping rule; amendments only by a new pre-registration and a fresh contest.
- **5.4 Backtest harness (separate, non-Gate-B):** temporally-fenced blind replay against adjudicated
  matters, used **only** for S5 calibration (Brier/log-score, reliability diagrams, reference-class
  robustness) and for non-regression of the system across upgrades (canon §5.7 semantic-delta budget).
  Explicitly barred from any dominance verdict (3.4, 0.4).
- **5.5 Power / N:** N fixed by a pre-registered power analysis for the minimum clinically-meaningful
  utility effect at 80–90% power under the paired design; the one-shot stratum sized to detect R-1
  exposure, not to be swamped.
- **5.6 Stopping rule:** no optional stopping; if sequential, alpha-spending pre-registered. A contest
  that fails to reach N is inconclusive, not a loss and not a win.
- **5.7 Reporting:** per-comparator, per-stratum, with the partner-hours covariate (2.6), the
  compute-scope caveat (2.5), the blinding-completeness caveat (2.8), and every §9 BLOCKING item
  restated. No pooled "dominates all" headline is permitted.

---

## 6. THE GOAL, RESTATED AS A PASS/FAIL PREDICATE

```
GOAL_MET  ⇔  PreRegistered(E, strata, U, δ, α, N)          -- 4.4
           ∧ GateA_pass                                     -- 3.2: all ZERO-GATEs = 0
                                                            --      ∧ every margin-metric NI
                                                            --      vs human-ref AND vs each baseline
           ∧ ∀ c ∈ {human-ref, Harvey/LAB, Fable-5,
                     Harvey+Fable, CoCounsel, Protégé,
                     Legora} :  τ_c > 0  @ corrected α       -- 3.3 Gate B, per comparator
           ∧ NoForbiddenInference(0.1..0.4)                 -- no max-claim, no self-score,
                                                            --   no inclusion=ideas, no backtest license
           ∧ BLOCKING_disclosed(R-1..R-9)                   -- 4.5: residuals measured, not passed
```

`GOAL_MET` is **falsifiable**: it returns FALSE if any ZERO-GATE fires once, if any non-inferiority test
fails, if `τ_c ≤ 0` for a single comparator, if pre-registration was violated, or if a forbidden
inference was used to reach a gate. The one-shot stratum and S5 guarantee that R-1 and R-2 can *cause*
FALSE — the goal cannot be met by avoiding the terrain where the system is known to be weak.

---

## 7. STRICT BUCKETING OF EVERY GOAL-COMPONENT (the required separation)

Each component of "unbeatable/supreme" is placed in exactly one bucket. Nothing crosses buckets.

### 7.1 MATHEMATICAL GUARANTEES (THEOREM — true independent of any formalization's legal fidelity)
- **G-append:** the audit log is append-only / tamper-evident under the hash-chain (canon I-WRITE) —
  altering a past entry breaks all later roots. `[THEOREM for the chain; external-anchor reduces to
  "not all TSAs collude," EMPIRICAL.]`
- **G-monotone-pub:** publication occurs *iff* the monotone conjunction of G-pub conjuncts holds — the
  predicate is false unless all conjuncts hold (canon I-PUB). `[THEOREM over the predicate; detector
  *completeness* is not a theorem — EMPIRICAL, see 7.5.]`
- **G-grant:** the confused-deputy cross-matter grant `n→m→k` is **not expressible** in the
  monotone-non-transitive grant algebra (canon I-GRANT-NT). `[THEOREM-able for the algebra.]`
- **G-conformal:** a conformal prediction set has coverage ≥ 1−α **under exchangeability** (canon §7).
  `[THEOREM under exchangeability; the antecedent's truth for legal data is EMPIRICAL — see 7.6.]`
- These are guarantees about *machinery*, never about *legal correctness of a conclusion*.

### 7.2 GUARANTEES-RELATIVE-TO-A-FORMALIZATION (true only if the natural-language → formal map is faithful)
- **GF-proof:** a K-prf-checked certificate is VALID **over the formalizable fragment and the encoded
  calculus** (canon §3.3). The conclusion is trustworthy *conditional on* the calculus faithfully
  modelling Greek/EU legal defeat — which is at most F3 EMPIRICAL, **never** THEOREM (this is R-5).
- **GF-deadline:** the dual-computed deadline is correct **given** the right procedure-family/trigger
  characterization; the arithmetic is proved, the *characterization* is a human legal act (R-5 / D9
  characterization gap).
- **Rule enforced:** A-level never upgrades F-level (canon K-typ). A proof over a mis-encoding is a
  valid proof of a legally wrong proposition; the fidelity artifact (canon §5.2) makes the trust
  *visible*, never *correct*.

### 7.3 DESIGN ENTAILMENTS (follow from the architecture's construction, pre-implementation)
- Fail-closed admission bus, single-writer commit, matter isolation by *absence of a handle*, two-and-
  only-two egress paths, capability-not-policy self-merge impossibility (I-SEV), discretion-node
  refuse-to-collapse, deadline fail-**loud**. `[DESIGN-ENTAILED — contingent on the seats being closed
  as specified; the on-disk fail-OPEN gate R-4 means one such entailment is NOT yet discharged.]`
- The evaluation harness properties of §2 (zero information asymmetry, blinding, pre-registration,
  Claim-12-safe Gate B). `[DESIGN-ENTAILED for the harness; some completeness caveats are EMPIRICAL.]`

### 7.4 DEMONSTRATED PROPERTIES (IMPLEMENTED + shown on the bench, in-repo)
- To be populated **only** by artifacts that actually run: bypass-fuzz zero-orphan-commit results,
  determinism-replay bit-identity, tamper-test chain-break, isolation red-team DENY-on-all-APIs,
  payload-capture zero-privileged-bytes, `AT-DL-*` deadline acceptance tests passing. **Status now:
  UNPROVEN pending the acceptance runs; R-4 (fail-OPEN gate) is a live counter-demonstration until the
  seat is closed.** No property is listed here until its test is green in-repo.

### 7.5 EMPIRICAL DOMINANCE (only via §3 Gate A ∧ Gate B, live/prospective)
- The *entire* "beats Harvey / CoCounsel / Protégé / Legora / a human team" content lives **only** here,
  and **only** after the §3 contest returns `GOAL_MET`. Until then it is **NOT ASSERTED** (canon §8
  bottom row). What is *defensibly* claimable pre-contest is the **structural** property: no surveyed
  2026 vendor exposes an independently-audited, fail-closed verification subsystem with honest-ignorance
  stop conditions (`frontier-2026` §11) — `[DESIGN-ENTAILED structural property; EMPIRICAL/UNKNOWN for
  outcome superiority]`. The Greek-order competence gap (statutory-article identification, GreekBarBench)
  is `[EMPIRICAL gap → opportunity, not an achieved claim]`.
- Detector-completeness for DLP/stego (7.1 G-monotone-pub) is EMPIRICAL and non-zero-miss (R-9).

### 7.6 HYPOTHESES (argued, not demonstrated; may turn out false)
- **H-calibration-spine:** the conformal/forecast second spine is *superior* on the discretion axis to
  A/C refusal and B base rates (canon §7). `[HYPOTHESIS — coverage is a theorem under exchangeability;
  superiority is argued.]`
- **H-composition-wins:** the B-spine + A-core + C/security shell composition wins Gate B against elite
  humans in the settle-laden real distribution. `[HYPOTHESIS until the §3 contest runs.]`
- **H-two-register:** whether a lawful non-fabricating advocacy register would win *more* Gate-B utility
  than the single-gate honest prover (the R-2 bet). `[HYPOTHESIS/EMPIRICAL — and adopting it makes the
  system "a different animal"; see 7.7.]`

### 7.7 IRREDUCIBLE UNKNOWN (cannot be closed by compute; stays BLOCKING)
- **U1 = R-1:** the novel dispositive move at a zero-recess one-shot node — a fail-closed honest system
  cannot fresh-certify it at speech latency; honest-UNKNOWN there ≈ conceding. The harness *exposes* it
  (one-shot stratum); it is never scored as a pass. **BLOCKING.**
- **U2 = R-2:** the honesty-tax contradiction — single-gate honesty vs. calibrated aggression cannot
  both hold; which wins the real forum turns on how imperfect real challenge is (Axiom Φ's fit to
  reality). **BLOCKING, not resolvable by proof.**
- **U3 = R-3 + Claim-12(c) residual:** a blind spot shared by the *entire available frontier-model
  population* is invisible to any ensemble/self-adversary drawn from it; and whether the model's training
  knowledge contaminates any temporal blinding is unmeasurable. **BLOCKING until measured.**
- **U4:** blinding-completeness (2.8) and `U`-weight legitimacy — whether style-normalization truly hides
  arm identity, and whether the pre-registered utility weights match the *client's* true preference, are
  empirical and imperfect. Disclosed confounds, not passes.
- **U5 = R-4/R-6/R-7:** the inherited fail-OPEN gate (must be closed before any DESIGN-ENTAILED admission
  guarantee holds), the e-filing-only deadline residual, and the AI-Act-logging vs GDPR-minimization vs
  privilege tension — all **BLOCKING**, none inside the goal predicate's "met" branch.

---

## 8. CLOSING — the honest shape of the goal

"Unbeatable/supreme" is admissible **only** in this frozen form:

> **Non-inferior on every enumerated safety floor (ZERO on fabrication, privilege-leak, silent
> deadline-miss, invalid-authority) and statistically superior in pre-registered, neutrally-adjudicated,
> live/prospective client utility against each named baseline — inside the modeled, turn-based,
> disclosure-bound, formalizable sub-game, at unbounded compute — with the novel-at-speed (U1), the
> honesty-tax (U2), and the shared-blind-spot (U3) axes left BLOCKING, and every substantive legal claim
> permanently capped at F3 EMPIRICAL, never THEOREM.**

This is a specification that can return "not met." It asserts no maximum (0.1), scores nothing by the
system's own judgment (0.2), never equates model access with idea coverage (0.3), and forbids
backtesting from ever crossing into dominance (0.4 / Claim 12). It is consistent with canon §8 (adds no
claim §8 forbids) and preserves canon §9 in full (retires no BLOCKING item). The goal is met **iff** the
predicate of §6 evaluates TRUE under a pre-registered contest — and it is designed so that the terrain
where the system is known to be weak is exactly the terrain that can falsify it.
