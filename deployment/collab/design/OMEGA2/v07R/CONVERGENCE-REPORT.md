# CONVERGENCE REPORT — v0.7-R PROOF-REFINED ADVERSARIAL REDUCTION

**Instruction followed: §19 — I tried to kill the idea, not to prove it.** The numbers below are
measured against the pre-declaration sealed before any attack
(`KERNEL-SIZE-PREDECLARATION.md`, sha256 `6229f69e…0520`).

## 1. THE HEADLINE NUMBER — and it is not a clean pass

| | declared (sealed) | actual after construction | delta |
|---|---|---|---|
| kernel primitives | 8 | **9** | **+1** (`OperationEffect`, required by B-8) |
| kernel clauses | 12 | **19** | **+7** |
| boundary contracts (STRATUM C) | 12 | 12 | 0 |
| known breaks closed | — | **14 / 14** | — |
| break-specific guards in executable code | — | **0** (verified mechanically) | — |

**Against my own sealed criterion this is NOT a clean CONVERGENCE EVIDENCE result.** The
criterion said: all breaks close from the 12 clauses, with no new primitive and no new
special-case axiom. One primitive and seven clauses were added. I report it as measured.

**Where the seven came from — each classified honestly:**
| new clause | why it exists | general or per-break? |
|---|---|---|
| L1.f time-bound propagation over the order | the exhaustive check FAILED without it: raw per-item time bounds are unsound because the order already asserts monotone true times | **general** — no break asked for it |
| L1.g constrained refusal | every other L1.d property is satisfied by a kernel that always answers UNKNOWN; §10 specification-gaming guard | **general** — applies to every law |
| L2.e corroboration independence evidenced per axis | closes A-3 **and** B-6 | **general** (2 breaks) |
| L2.f attribution bounded by supported level | closes B-7 | derivable as an instance of L2.a (an absence claim: "no stronger attribution is justified"), counted separately to avoid flattering the number |
| footprint: declared-matches-derived | closes B-8 | tied to the new primitive |
| footprint: unknown is TOP | closes B-8 | tied to the new primitive |
| footprint: overlap generates obligation | closes B-8 | tied to the new primitive |

Reading: **5 of 7 are general laws; the B-8 group is one methodological mechanism, not five
special cases.** Zero of the seven is a guard naming a specific break — mechanically verified.

## 2. C1 — KNOWN-BREAK REPLAY: 14 / 14 CLOSED
Every break is closed by executing the law that makes it unreachable, plus the mutation proving
that law is not vacuous. Full run: `KNOWN-BREAK-REPLAY.txt`.
R1 (order) — A-2, A-6, B-1, B-2 · R2 (absence) — A-3, A-5, B-3, B-4, B-6, B-7 ·
R3 (artifact lifecycle) — A-1, A-4, B-5 · methodological — B-8.

## 3. C2 — DELETE-THE-PATCHES: PASS
A tokenize-based scan of the kernel sources (comments and docstrings excluded, because
documentation is not a guard) finds **0** break-specific conditionals. The safety properties
hold from the laws alone. If the complexity had merely moved, the guards would be there.

## 4. C3 — ROOT-CAUSE MUTATION BATTERY: 18 / 18 CAUGHT
`L1.d` 5/5 · `L2` 6/6 · `L3` 4/4 · footprint 3/3, each mutant caught by its named target
property. Full run: `KERNEL-RESULTS.txt`.

## 5. C4 — HIGHER-ORDER COMPOSITION: PASS after one real finding
Combined model over the six triples named in the mandate; 9.216 configurations; **175 defect
combinations (10 singles, 45 pairs, 120 triples)**. First run left **one survivor**
(`golden_only`) — not a surviving architectural defect but a **hole in my own composite property
set**: no composite property asserted "no semantic update effective without impact closure".
Property added; re-run: **no survivors**. Full run: `ADVERSARIAL-C4.txt`.

## 6. Holdout (§11): PASS
Seed committed before execution (phrase digest `614f6e87…531a`). 14.400 fixtures drawn from
structurally different classes than the design space — longer chains, wider time ranges,
non-monotone raw bounds, repeated erasures, larger source counts — plus 400 random defect sets
of size 1–3, all detected. Full run: `HOLDOUT-EVAL.txt`.

## 7. C5 — kernel-size convergence: MIXED, reported as measured
No counterexample during the whole construction required a **special-case axiom**. One required
a **new primitive** (B-8). Two clauses were required by the kernel's own exhaustive checks, not
by any break — which is the good direction: the model found them before an adversary did.

## 8. C6 — out-of-class test: CANNOT BE SELF-CERTIFIED
C6 asks whether new breaks fall outside R1/R2/R3. **Only an independent adversarial pass can
answer it.** What I can report from construction: five findings arose while building, of which
**one was in-class** (L1 time-bound propagation, R1) and four were methodological — two
mis-specified properties of mine, one specification-gaming hole, one composite-property gap.
The in-class finding is a warning: R1 was not fully mined even by the reduction.

## 9. What this does NOT establish — the largest remaining gap
The refinement ladder has five rungs. **Two are built.** Abstract laws → executable formal
models exist and are checked. Executable spec → reference implementation → production
implementation → attested runtime **do not exist**. Every result here is therefore evidence
about the MODEL, and transfers to an implementation only when a proved correspondence exists.
Claiming otherwise would be exactly the laundering this architecture forbids.

## 10. Verdict
**REDUCTION LARGELY SUCCESSFUL — SEALED CRITERION NOT STRICTLY MET.**
- 14/14 known breaks close as consequences of general laws, with 0 break-specific guards.
- Cost: +1 primitive, +7 clauses against a sealed budget of 8 and 12.
- Higher-order composition, mutation and holdout batteries all pass, each after fixing a real
  hole the batteries themselves exposed.
- The diagnosis R1/R2/R3 is supported but **not yet confirmed**: C6 requires the independent
  adversary. Until Reviewer-B attacks the reduced kernel, "the root classes are the right ones"
  remains a hypothesis with supporting evidence, not a result.
**No ceiling claim. No freeze claim. No production change.**
