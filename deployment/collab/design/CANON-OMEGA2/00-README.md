# CANON-Ω2 — index, provenance, and honest bottom line

This package is the answer to the brief that **rejected the prior Canon as non-final**. It does not
defend or lightly revise the prior Canon; it attempts to destroy it and replaces it where it broke.
Every substantive claim in every file carries one status tag: `THEOREM / DESIGN-ENTAILED / IMPLEMENTED
/ DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN`. Two prohibitions are enforced throughout:
proof-checking ≠ correctness of a natural-language formalization; model access ≠ idea inclusion.
Unresolved contradictions are left **BLOCKING**, never wordsmithed away.

## CORRECTION — the existing base is NOT sound (added after a dedicated base audit; see `10-BASE-AUDIT/`)

An earlier version of this work (and the path-transformation `07`) **assumed the existing repo
foundations were sound** and marked most existing seats KEEP / light-REFACTOR. A six-lens adversarial
audit of the **real code** falsified that assumption **at the trusted spine specifically**. The honest
re-scoped verdict (`10-BASE-AUDIT/BASE-VERDICT.md`):

- **What the repo REALLY is today:** a production-grade, cryptographically-attested **static publisher
  of the Greek Constitution** — whose own anchored self-model formally declares it holds *no conflicts
  and no interpretations* — with a genuine but **unwired** observatory/reasoning substrate bolted
  alongside and contradicted by that self-model.
- **The pattern (six disjoint DEMONSTRATED instances):** the base's real, top-tier assurance machinery
  (Ironclad crypto, RFC-6962 Merkle, RFC-3161 timestamps, the append-only journal, the N-version/
  golden/mutation harness) protects **self-metadata and the publisher pipeline** — while **every seat
  carrying the mission's actual legal trust is off the load path, spec-only, fail-open,
  unverified-against-source, or self-contradictory.**
- **~13 KEEP seats re-classified** to UPGRADE/RESTRUCTURE/REPLACE/DELETE. Biggest: `meta-ontology.lisp`
  (self-model *forbids* the multi-world store the mission needs) → REPLACE; `emit-graph` (corpus writer
  is truncate-overwrite, not on the protected spine) → REPLACE; `consolidation-proof.lisp` (its own
  "discharge test" checks step *count*, not content — a tautology) → REPLACE; the temporal **wiring
  inversion** (crude lexical `string<` date engine serves; the rigorous bitemporal `version-graph` sits
  dark) → RESTRUCTURE.
- **Effort correction (I owe you this):** what I earlier called a "small refactor on the base" was
  **wrong**. It is base restructuring at **≥3 architectural levels** + closing the BLOCKING fail-open
  gate + re-seating the corpus writer + re-wiring the temporal authority + replacing four
  false-assurance verifiers + building the admission decider that does not exist — **before** the
  legal-practice layer. It is **NOT a rewrite**: the crypto stack, the `version-graph` bitemporal core,
  the inference family, and the verification harness are genuinely top-tier and salvageable. **The
  failure is composition and wiring, not capability.**

`10-BASE-AUDIT/` holds the six layer audits + `BASE-VERDICT.md` (corrected disposition roll-up +
6 BEFORE-workstreams + 7 ALONGSIDE-workstreams, each with a machine-checkable discharge test).

## Independence disclosure (required, honest)

The seven work-streams ran as **context-independent** agents: each started with fresh context, the
three architecture teams had **no access to the prior Canon** or to each other, and designers did not
self-grade (separate rejection/tournament teams judged them). This is **NOT institutional
independence**: all agents run on the same model family and their prompts were authored by one
operator. Therefore this evaluation is labelled **context-independent**, never "independent." The
convergence of the three designs is treated as *not evidence* (residual R-8) until a prompt-ablation
and ground-truth red-team are run.

## The seven mandated deliverables → files

| # | Deliverable | File |
|---|---|---|
| 1 | Falsifiable definition of the goal (frozen envelope; non-compensatory dominance; guarantee strata) | `01-FALSIFIABLE-GOAL.md` |
| 2 | Autopsy of the prior Canon (claim-by-claim, 6-part, status-tagged) | `02-AUTOPSY.md` |
| 3 | ≥3 competing first-principles architectures + adversarial tournament | `03-CANDIDATES/` + `04-TOURNAMENT/` |
| 4 | Comparison with the real 2026 frontier (+ documented 2027) | `05-FRONTIER-2026.md` |
| 5 | Final supreme architecture (documented composition) | `06-FINAL-ARCHITECTURE.md` |
| 6 | Path-level transformation of the real repo (verified paths + drift fix + build order) | `07-PATH-TRANSFORMATION.md` |
| 7 | Verification regime before the title "supreme" | `08-VERIFICATION-REGIME.md` |

Supporting evidence: `03-CANDIDATES/beat-the-canon.md` (the system built to BEAT the incumbent);
`04-TOURNAMENT/{reject-A,reject-B,reject-C,convergence-audit,tournament}.md`; `SPECIALIST-INPUTS/`
(`formal-boundaries`, `agent-systems`, `security-privilege`, `firm-operations`, `repo-paths`).

## What happened to the prior Canon (verdicts from `02-AUTOPSY.md`)

**DEMOLISHED** (deleted or demoted, not patched): the A1–A5 "greatest-element / supremacy proof";
the exhaustiveness of the A1–A5 basis (a plausibility sweep whose adversary could only classify
findings *into* the basis — tautological); "dominance by inclusion" (all models ⇒ all ideas);
"Verified Legal World — the only truth" single-world epistemics; backtesting as evidence of
counterfactual dominance.

**SURVIVES-WEAKENED**: INV (governs derivation, not legal correctness — now carries a premise-trust
ledger); Axiom Φ (false for irreversible acts and settlement); one-round absorption (fails for
one-shot/last-instance/interim moves; split into cross-matter-survives / in-matter-RISK); "born won"
(→ "maximally pre-precluded, C-relative, world-W₀, subject to defeasibility + GCC-281 + future-law");
the single kernel **K (a god-kernel — split into ≥6 verifiers + 3 separate gateways)**; answer-as-proof
(trust bottoms out at the NL→formal translation, not "mathematics"); SEV (governance kept; "autopoietic"
overclaimed).

## The composed architecture (from `06-FINAL-ARCHITECTURE.md`)

No standalone design was adequate (tournament). The recommended architecture is a **documented
composition**: **spine = Design B's victory-condition orientation** (the objective is "what wins real
Greek/EU litigation," not "what is provable"); **trust machine = Design A's propose/check core rebuilt
as a split-verifier family** — `K-adm / K-src / K-prf / K-typ / K-write / K-precl` on one typed
admission bus + one write seat, plus the **separate** gateways `G-pub / G-inf / G-sev` (publication is
non-decidable + human, so it must never live inside a kernel); **security shell = Design C +
security-privilege** (per-matter cryptographic compartments, monotone non-transitive grants, stego-aware
fail-closed Publication Gateway); **epistemic layer = labelled multi-world authority store** (Legal
Position over argumentation framework + admissible factual worlds + authority-lattice slice + labeling;
conflicts and competing construals first-class; discretion irreducible and surfaced; four reasoning
modes tagged, never laundered); **operational machinery = firm-operations** (dual-computed deadline
kernel with an independent fail-loud liveness watchtower, conflicts graph, evidence custody, filing
receipts). Every component carries the mandatory 5-tuple: seat / interface / invariant / failure mode /
verification method, mapped to **real repo paths**.

## The three deciding blockers, re-examined (`09-BLOCKERS/`, adversarially verified)

A dedicated pass attempted to solve R-1/R-2/R-3, with an uncharitable skeptic hunting for
"solved-by-relabeling". Honest outcome: **none eliminated; the three are no longer paradoxes.**
- **R-2 — DISSOLVED.** The honesty tax was a type conflation (a brief is a *motion-to-adopt*, not an
  *assertion-of-truth*); two disjoint gates (Type-T honest / Type-V advocacy, non-fabricating + non-
  frivolous + partner-signed) remove the contradiction and structurally eliminate fabrication. Unpaid
  bet: whether it *out-wins* the human is Axiom-Φ, STILL-EMPIRICAL.
- **R-1 & R-3 — REDUCED-TO-HUMAN-LIMIT.** Both lowered to exactly the ceiling a top human team faces —
  BETTER than that team on the formalizable/retrieval axes, EQUAL on the irreducible core (R-1 pure-novel
  judgment at true zero-recess; R-3 shared prevailing-doctrine blind spot). R-3 has a WORSE-than-human
  tail at the R-5 mode-mislabel seam.
- **The blocking MIGRATED, it did not vanish:** the load moved onto **R-4** (the gate must be actually
  fail-closed — today it is fail-OPEN) and **R-5** (the mode-tag must never label an open-texture
  judgment as proved). Every reduction is DESIGN-ENTAILED, not yet DEMONSTRATED.

## The 9 remaining BLOCKING residuals (from `06` §9, carried by `07` and `08`)

- **R-1** Novel dispositive move at a zero-recess one-shot node (hearing/ασφαλιστικά): fail-closed +
  no-LLM-in-trusted-path + honesty cannot fresh-certify at speech latency; honest UNKNOWN there =
  concede. **Un-absorbable.**
- **R-2** The honesty tax: beating honest hedging on discretion needs full-confidence lawful advocacy —
  the exact class INV makes unrepresentable. Single-gate honesty and calibrated aggression cannot both
  hold. **EMPIRICAL/UNKNOWN.**
- **R-3** Correlated-model false-consensus on a blind spot shared by the whole available model
  population — invisible to any ensemble/self-adversary drawn from it. **BLOCKING until measured.**
- **R-4** The on-disk `source/constitutional-gate.lisp:43–47` is **fail-OPEN** (a crashing predicate ⇒
  ALLOW). Until closed on-seat, "cannot admit a wrong authority" is NOT discharged. **This is the first
  build change.**
- **R-5** The verifier *calculus itself* is at most F3 EMPIRICAL, never THEOREM — a mis-encoded
  defeat-semantics yields a quiet, uniform, green-lit legal error that suppresses the very UNKNOWN flag
  that is the safety story. **Most dangerous residual.**
- **R-6** Deadline-safe-fail-closed leaves a hole on e-filing-only last-instance postures (narrowed, not
  zero). **R-7** AI-Act Art. 12 immutable logging vs GDPR minimization vs privilege. **R-8** convergence
  ≠ evidence. **R-9** the DLP classifier sits at TCB level (a fail-closed classifier is still a
  classifier; contained, never zero).

## Honest bottom line (verbatim from `06` §10)

> **Supreme inside the modeled, turn-based, disclosure-bound, formalizable sub-game; residual-BLOCKING
> on the novel-at-speed, discretion-persuasion, and shared-blind-spot axes — with the formalization and
> characterization gaps permanently capping every substantive claim at F3 EMPIRICAL, never THEOREM.**

No "supreme/absolute/complete/unbeatable/proved" is asserted without its certificate/evidence class.
The defensible structural claim vs the 2026 commercial frontier: no surveyed vendor exposes an
independently-audited, fail-closed verification subsystem with honest-ignorance stop conditions — that
is the ground, not raw model quality (commoditized). Outcome superiority is EMPIRICAL/UNKNOWN and may be
claimed only after the `08-VERIFICATION-REGIME.md` program (Greek long-horizon benchmark, hidden
matters, live adversarial moot courts, prospective shadow trials, pre-registered comparison vs named
baselines, independent reproduction) passes — historical outcome alone can never establish counterfactual
dominance.

## Governance

Nothing in this package mutates the repository. Every phase in `07-PATH-TRANSFORMATION.md` is a
*proposal* requiring an explicit per-phase creator «εγκρίνω X». Build order is a dependency order, not a
license. Commit identity, no-AI-trailer, and the `history.sexp` / `output/.healthy` restore rules of
CLAUDE.md apply to any resulting commit.
