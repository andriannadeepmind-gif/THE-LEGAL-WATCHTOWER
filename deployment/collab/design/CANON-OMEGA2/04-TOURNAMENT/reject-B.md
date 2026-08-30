# REJECT-B — Skeptical Rejection Team vs. Design B (The Adversarial Game)

**Target:** `design-B-game.md`. **Mandate:** try only to KILL. I do not design.
**Method:** three strongest kill-shots with exact failing scenarios and why each is
unrecoverable *within this design's own invariants*; verdict; most dangerous residual +
real-matter cost. Special probes (from brief): (i) does deriving everything from the
L1–L8 victory model bake in a wrong theory of winning — its own W8? (ii) does centering
the procedural state machine under-serve substantive/merits reasoning?
**Claim-status discipline:** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED /
EMPIRICAL / HYPOTHESIS / UNKNOWN on every load-bearing claim. Readings of what the
architecture structurally can/cannot do are DESIGN-ENTAILED *against the design text*;
predictions about real matters are HYPOTHESIS.

**One-paragraph orientation.** Design B is unusually honest: Part 14 disclaims supremacy,
W8 pre-concedes the "wrong game" risk, and the assurance spine (small deterministic TCB,
capability isolation, fail-closed gateway, no-self-merge) is sound and largely coincides
with Design A. The attack therefore is *not* "it is broken." It is: **the L1–L8 derivation
is not load-bearing — it changes the motivation but not the machine — and the two invariants
that make the machine "honest" (INV-1 no-guessing, INV-2 refuse-to-collapse) structurally
forbid the design from doing the one thing its own Part 1 says wins cases: committing to a
merits theory and to a judge-specific line on the discretion/persuasion/settlement axes.**
The design delivers structural superiority on L2/L7 (the procedural/computational spine) and
tags L1/L4/L5/L6/L8 — where it *itself* says matters are decided — as HYPOTHESIS terminating
in "the human decides." That is W8, and it sits at the invariant layer, not the periphery.

---

## KILL-SHOT 1 — The victory-condition derivation is decorative: it universalizes L2/L3's payoff structure into INV-1 and then delivers the *same* machine an epistemics-first team delivers, with structural edge on only 2 of its own 8 levers.

**The claim under attack (design's own words).** Part 0: the knowledge-first frame is
"presumptively wrong"; the architecture is "derived from victory conditions." Part 1.1: the
L1–L8 table "is the load-bearing part of the whole design; everything downstream is built to
serve it." INV-1: "Honest ignorance beats confident error … No LLM in the trusted path;
guessing is a defect, not a feature." (`DESIGN-ENTAILED`, per the design.)

**Where the derivation breaks.** Trace each lever to what the architecture actually builds:

| Lever | Design's own verdict on computation | What gets built | Structural edge? |
|---|---|---|---|
| L1 info asymmetry | "helps (analysis); *cannot* acquire" — `HYPOTHESIS` | evidence agents (untrusted, ≤HYPOTHESIS) | analytical depth only |
| L2 deadlines | "very strong … computable" — `DESIGN-ENTAILED` | Deadline Kernel (TCB) | **YES** |
| L3 irreversible | "cannot bear responsibility" → HA-1 human | reversibility classifier + human gate | human-gated |
| L4 one-shot | "cannot be in the room" — `HYPOTHESIS` | prep agents | prep only |
| L5 discretion | "cannot derive the answer" — represent-as-open | discretion-typed core, refuse-collapse | **refuses to commit** |
| L6 settlement | "cannot supply the true probabilities" — `HYPOTHESIS` | BATNA decision-tree | assumptions-explicit only |
| L7 traps | "strong … formal object" — `DESIGN-ENTAILED` | Procedural-State Machine (TCB) | **YES** |
| L8 forum/framing | "final election is human" — `HYPOTHESIS` | option enumerator | human-decided |

The architecture's *structural* superiority (the TCB, the only place authority lives) lands
on **L2 and L7 alone**. Every other lever resolves to "computation cannot" + "human decides"
+ untrusted proposals capped at HYPOTHESIS. Now strip Part 0–1's game-theoretic rhetoric and
read Parts 2–13: propose/check split, small deterministic TCB, multi-world epistemics,
capability isolation, fail-closed publication gateway, human authority points, self-improve-
without-self-merge. **That is Design A, component for component.** The victory-condition
derivation produced no distinctive machine; it re-badged an epistemic-honesty substrate with
a "what wins" story that its own lever-analysis cannot cash out. The design's founding thesis
(Part 0: knowledge-first is wrong, derive from victory) is *contradicted by its own output* —
the derivation changed the preface, not the architecture. (`DESIGN-ENTAILED` against the text:
compare B Parts 2–13 to A §§2–13 — the trust boundaries, TCB contents, dataflow, gateway
stages, and self-improvement loop are isomorphic.)

**Exact failing scenario.** A firm adopts B *because* Part 0 promised an architecture that
beats a knowledge-first system at the real game. In practice, on a live matter the system's
only *committed, high-trust* outputs are the deadline computation (L2) and the procedural-trap
map (L7). On L1/L4/L5/L6/L8 it emits organized-but-uncommitted HYPOTHESIS material for a human
to synthesize — indistinguishable from what a well-run associate pool + Design A produce. The
firm paid for a victory engine and received a superb procedural-compliance-and-organization
engine. Against an equally-resourced elite team (the brief's benchmark), the procedural spine
is real but narrow; on L5/L6/L8 — which the design *itself* calls the levers that "often matter
more than the merits argument" (L8) — B provides no committed strategic product at all.

**Why unrecoverable within this design.** To make the derivation load-bearing, B would have to
deliver *committed* strategic output on L5/L6/L8 (a chosen frame, a bet on this bench, a
committed settlement posture). But committing on L5 violates Part 6.5 ("refuses to emit a
point-value … Collapsing discretion to a prediction is a structural error the type system
forbids"); committing a substantive conclusion above HYPOTHESIS without a human violates INV-1
+ HA-3. The invariants that give B its honesty are exactly what bar it from cashing the victory
thesis. You cannot keep INV-1/INV-2/Part-6.5 *and* deliver on Part 0. **The thesis and the
invariants are mutually exclusive; the design chose the invariants and kept the thesis as
decoration.** (`DESIGN-ENTAILED`.)

---

## KILL-SHOT 2 — Centering the procedural state machine (INV-3) under-serves the merits: the system multiplies the substantive option-space and never reduces it, pushing all synthesis onto the human bottleneck under deadline. It confuses *representing* the merits with *reasoning to a conclusion* on them.

**The claim under attack.** INV-3: "Procedural state is a first-class formal object … the most
computable, highest-leverage, lowest-open-texture surface is the procedural machine. The
architecture centers a formally-tracked procedural state, not a chat interface." INV-2:
many-worlds, "competing interpretations … coexist as first-class objects." Part 6.2: the
system's job is "to render the conflict legible and assemble each side's strongest case, **not**
to declare a winner." Part 5: "No recommendation reaches the lawyer without a paired strongest-
counter-recommendation." (all `DESIGN-ENTAILED`, per design.)

**Where it breaks.** The procedural surface (L2/L7) is genuinely the low-open-texture,
computable surface — and B puts it in the TCB. But *matters are won on the merits and the
discretion axis*, and there the architecture is, by construction, a **divergent** engine: it
generates multiple factual worlds (6.3), a conflict graph of authorities that it "does not
resolve" (6.2), both sides of every balancing test (6.5), and a mandatory paired counter for
every recommendation (Part 5). It never converges. A litigator does not need the argument space
enumerated; a competent associate can enumerate. A litigator needs a **theory of the case**: one
committed selection of factual world + characterization + narrative that will actually be argued,
*with the losing alternatives pruned and the reason for pruning owned*. Design B structurally
refuses to produce this — pruning on discretion is "a structural error the type system forbids"
(6.5); elevating a merits selection is reserved to a human (HA-3). So the system's substantive
work product is a *pile that grows*, and the entire cognitive act of reduction — the actual legal
reasoning — is displaced onto the human, who is the design's own scarcest, most saturable, most
deadline-pressured resource (W5). **INV-3 optimizes the surface where reduction is easy and
already cheap; it leaves the surface where reduction is hard and decisive entirely to the human.**
The design mistakes *faithful representation of the merits* (which it does well, honestly, per
INV-2) for *reasoning on the merits* (which it declines to do at all). (`DESIGN-ENTAILED`.)

**Exact failing scenario.** A commercial matter turns on whether a limitation/waiver clause is
καταχρηστική άσκηση δικαιώματος (abuse of right, ΑΚ 281) and on a καλή πίστη (good-faith)
balancing — pure L5 discretion, decided by a specific bench under free evaluation of evidence
(ΚΠολΔ 340). B delivers: three admissible factual worlds; a conflict graph with two unresolved
authority lines; the strongest argument on each side of the ΑΚ 281 balance; EMPIRICAL base rates
"clearly tagged with sample and caveats"; and a paired counter-recommendation. It refuses to say
which line wins (6.5 forbids collapse). The associate now must, under a 100-day νέα-τακτική
προτάσεις deadline, do the entire synthesis and commitment *unaided by the system on the
dispositive node* — and the system's procedural rigor (proof-checked deadline, formal state
machine, WORM audit) radiates an aura of "this is handled" over a package whose decisive content
is un-adjudicated. The opposing elite team, unburdened by refuse-to-collapse, commits early to a
bench-tuned narrative and wins the discretionary call. B was honest and lost, and lost on the very
axis (L5) it enumerated as a victory lever.

**Why unrecoverable within this design.** Merits synthesis requires either (a) the system
committing a substantive conclusion — barred by INV-1/HA-3, or (b) collapsing the many-worlds on
discretion — barred by INV-2/6.5. The two "honesty" invariants jointly forbid the convergence
that winning requires. B could add a human *faster* (does not scale — W5) or present the pile
*better* (does not reduce it). There is no move inside B's invariant set that turns the divergent
representation engine into a convergent reasoning engine on the merits. (`DESIGN-ENTAILED`; the
downstream litigation loss is `HYPOTHESIS`.)

---

## KILL-SHOT 3 — INV-1 bakes in a one-sided theory of winning (avoid-error ≫ seize-advantage): it universalizes L2/L3's asymmetric-downside payoff into a global invariant, making the design structurally blind to the failure class of *timid under-commitment*. This IS its W8, and it lives at the invariant layer, not the periphery.

**The claim under attack.** INV-1: "Because irreversible moves (L3) and deadlines (L2) have
catastrophic, asymmetric downside, the system's dominant failure mode to avoid is *confident
wrongness*. … guessing is a defect, not a feature." Derived as `DESIGN-ENTAILED` from L2/L3.

**Where it breaks — the derivation over-generalizes a local truth.** The asymmetric-downside
argument is *correct for L2/L3*: a missed προθεσμία or a botched irreversible move is unbounded
loss, so on that class honest-ignorance strictly dominates. But INV-1 does not stay on L2/L3 — it
is stated as *the* dominant failure mode of the whole system and enforced structurally ("no LLM in
the trusted path," guessing "unrepresentable"). Litigation has a second, equally large failure
class with the *opposite* payoff geometry: **timid under-commitment** — failing to assert an
arguable winning position, failing to commit to a theory of the case, failing to move at speed at a
one-shot node, presenting a hedged both-sides picture where a committed confident frame would have
carried a discretionary call. On L5/L6/L8 the realized forum payoff of a confident-but-unproven
arguable assertion is frequently *positive*, because challenge is imperfect: the opponent misses
it, runs out of time, or the judge adopts it (see beat-the-canon Exploit 4; this attacks the
idealization in the design's implicit Φ). INV-1 codes *every* instance of that move as a "defect."
So the design's theory of winning is: **minimize confident error, at the cost of being structurally
unable to represent calibrated aggression.** That is a *substantive, contestable bet about what
wins*, dressed as a derived invariant. It is precisely W8 ("the system optimizes the game it can
model") — and B files W8 under Part 13 as a *peripheral, empirically-testable HYPOTHESIS*, when in
fact it is *entailed by INV-1's over-generalization* and sits in the load-bearing core.

**Compounding: the L1–L8 basis is asserted, not proven exhaustive, and omits decisive levers.**
Part 1.1 gives no argument that L1–L8 is complete or that the levers are independent — it is a
plausibility list ("I decompose 'winning' into the levers that decide real cases"). At least two
decisive dynamics are absent as *levers the system acts on*, appearing only as "computation cannot"
footnotes:
- **The off-record attrition / cross-forum / time-to-relief war.** L6 is modeled as a static
  BATNA decision-tree, not the dynamic contest where a rich opponent bankrupts an under-resourced
  client before the merits are reached. "A machine that wins in four years is worthless to a client
  bankrupt in six months" — and B's likely client (a single Greek firm's clientele) is the party
  least able to outlast attrition. B has no *time-to-relief-as-survival-constraint* objective.
- **Judge-specific persuasion.** L5 explicitly *refuses* to optimize for the specific decider
  (6.5: base rates are EMPIRICAL-only, no point prediction). But a discretionary call is won by
  tuning the argument to *this* bench — the single most powerful lawful persuasion lever, absent by
  invariant (INV-2 + refuse-to-collapse).

**Honesty about recoverability (claim-status discipline).** Not all of kill-shot 3 is
unrecoverable. The attrition / time-to-relief organ *is* absorbable: it is untrusted modeling, a
new proposer faculty, violating no invariant — B *should* add it and its absence is a fixable gap,
not a principled bar. But the two that decide elite matters are **not** recoverable: judge-specific
*decision/strategy* negates 6.5's refuse-to-collapse and the many-worlds honesty; calibrated-
aggression advocacy negates INV-1 (it is the exact "confident guessing" INV-1 makes
unrepresentable). To absorb either, B would have to separate *advocacy assertion* from *trusted
claim* and let the former exceed the latter — dissolving the single-gate "authority lives inside the
TCB" discipline that is B's identity. That is not a better B; it is a different animal.
(`DESIGN-ENTAILED` for the invariant negations; `HYPOTHESIS` for "these levers decide elite
matters.")

**Exact failing scenario.** Interim-measures (ασφαλιστικά μέτρα) / προσωρινή διαταγή hearing:
oral, fast, discretion-heavy, quasi-final in practical effect, *no next round*. The decisive move
must be made now at speech latency. B's design (Part 4/9) is precompute-then-navigate with
fail-toward-honesty; a genuinely novel characterization at that node is emitted as UNKNOWN and
escalated. INV-1 makes "answer now at calibrated confidence" a defect. Operationally, "honest
UNKNOWN at a one-shot node" = concede the point. The opponent, playing calibrated aggression tuned
to the interim judge, takes the ruling; the ordinary-track certainty B is superb at never gets to
matter because the commercial reality was fixed at the interim stage. (`HYPOTHESIS` on the loss;
`DESIGN-ENTAILED` on B's structural refusal to act fresh at speed.)

---

## DIRECT ANSWERS TO THE MANDATED PROBES

**Probe (i): Does deriving everything from L1–L8 bake in a wrong theory of winning — its own W8?
YES, at the invariant layer.** The derivation privileges L2/L3's asymmetric-downside payoff and
universalizes it into INV-1 as *the* global failure mode ("guessing is a defect"). That is a
one-sided theory of winning — avoid-confident-error over seize-lawful-advantage — true for
deadlines/irreversible moves, false as a global axiom on the discretion/settlement/framing/one-shot
axes where under-commitment is the dominant failure mode and calibrated aggression has positive
realized payoff. B treats W8 as a peripheral empirical HYPOTHESIS (Part 13); it is in fact
*entailed* by INV-1's over-generalization and INV-3's procedural centering, and is unfixable
without abandoning those invariants. The design is "superbly built for the wrong objective" on 6 of
its own 8 levers — and it half-admits this in W8 while continuing to present the L1–L8 derivation as
load-bearing.

**Probe (ii): Does centering the procedural state machine under-serve substantive/merits reasoning?
YES, structurally.** INV-3 correctly identifies the procedural surface as the computable one and
puts it in the TCB — but this concentrates the design's *committed, high-trust* output on L2/L7,
while the merits (L1/L5/L6/L8) live in the untrusted periphery as an ever-growing, never-reduced
pile of HYPOTHESIS-tagged worlds, conflict graphs, and both-sides arguments that the system is
*forbidden by INV-2/6.5 to adjudicate*. The system represents the merits faithfully but reasons to
no conclusion on them; all synthesis and commitment — the actual legal reasoning that wins — is
displaced onto the human bottleneck under deadline. The procedural rigor also lends the
un-adjudicated merits package a false aura of "handled." Centering procedure does not merely
under-serve the merits; the honesty invariants make committed merits reasoning *structurally
unavailable*.

---

## VERDICT: **SURVIVES-WOUNDED.**

The wound is to Design B's *distinctiveness and central thesis*, not to its soundness. As an
assurance substrate B survives intact and is genuinely strong: the small deterministic TCB, the
capability-based isolation (B2/B3), the Deadline Kernel's fail-loud liveness (Part 9), the
fail-closed six-stage Publication Gateway (Part 11), and the no-self-merge governance (Part 12) are
correct and best-in-class. It does not reach FATAL-FLAW for three reasons required by claim-status
discipline: (a) it never actually asserts supremacy — Part 14 disclaims it and W8 pre-concedes the
wound, so nothing decisive is *hidden* (a hidden unrecoverable contradiction would be fatal; a
pre-conceded structural limit is a wound); (b) its honesty invariants, though they cap its ceiling,
never produce a *wrong confident* output on the merits — it fails safe, not loud; (c) the
procedural/computational spine is a real, defensible edge.

But the kill-shots are not survivable *as a victory-derived design*: (1) the L1–L8 derivation is
decorative — strip it and B *is* Design A; (2) the two honesty invariants structurally forbid the
committed merits/discretion reasoning that Part 1 says decides matters; (3) INV-1 bakes in a
one-sided theory of winning and the basis omits the attrition and judge-specific-persuasion levers,
with the decisive omissions unrecoverable without dissolving B's identity. **B survives as "Design A
with heavier procedural emphasis"; it dies as "the architecture that beats elite opponents by
deriving from victory conditions."** Against the brief's benchmark — maximum superiority over an
equally-resourced elite team — a design whose structural edge is confined to L2/L7 and which
under-serves L1/L4/L5/L6/L8 by invariant does not deliver superiority on the game that decides
matters. Wounded, not dead; but the wound is to exactly the claim that made it Design B.

---

## MOST DANGEROUS RESIDUAL + REAL-MATTER COST

**The residual: rigor-aura over an un-adjudicated dispositive node (Kill-shot 2 × W5).** The
procedural spine — proof-checked deadlines, a formal typed state machine, WORM hash-chained audit,
verified-citation gating — surrounds every work product with signals of certified rigor. The
decisive content of a hard matter, however, is a discretion/merits node the system is *forbidden to
resolve* and hands over as a balanced both-sides package. Under deadline pressure a fatigued human
(W5, automation bias) reads the rigorous frame as authority and under-scrutinizes the one node that
actually decides the case. The design's own metrics cannot catch this: all gates green, deadline
met, citations verified, contradiction ledger clean — because the loss occurs on the axis the
architecture deliberately does not adjudicate and does not score.

**Real-matter cost.** A ΑΚ 281 abuse-of-right / καλή πίστη balancing before a specific bench under
ΚΠολΔ 340 free evaluation. B delivers three factual worlds, an unresolved authority conflict graph,
both sides of the balance, base rates tagged EMPIRICAL, and a paired counter — refusing to commit
(6.5). The associate, trusting the certified spine and out of time, adopts the base-rate-favored
line. Opposing counsel, committing early to a bench-tuned confident narrative (calibrated aggression
B cannot represent, judge-specificity B refuses), carries the discretionary call. Client loses a
winnable matter. Post-mortem: every B invariant held, every gate was green, the deadline was met —
and the system's honest, un-adjudicated merits package was *causally* the loss. The failure is
invisible to B's assurance model because it lives on the merits/discretion axis that INV-1/INV-2/
INV-3 route around by design. For an under-resourced client the cost compounds: layer the absent
attrition/time-to-relief objective (Kill-shot 3) and the client may be bankrupt before the
four-year ordinary-track certainty B is superb at ever matters.

---

## CLAIM-STATUS LEDGER (load-bearing claims)

- "B Parts 2–13 are component-isomorphic to Design A" — `DESIGN-ENTAILED` (textual comparison).
- "Structural (TCB) superiority lands on L2/L7 only; L1/L4/L5/L6/L8 terminate in human/HYPOTHESIS"
  — `DESIGN-ENTAILED` (from the design's own lever verdicts + Appendix A).
- "INV-1/INV-2/6.5 forbid committed merits/discretion reasoning" — `DESIGN-ENTAILED`.
- "INV-1 universalizes L2/L3's payoff into a global no-guessing invariant = a one-sided theory of
  winning = W8 at the invariant layer" — `DESIGN-ENTAILED` (reading of INV-1's derivation).
- "Calibrated-aggression and judge-specific-decision organs are invariant-negations, unrecoverable
  without dissolving the single-gate discipline" — `DESIGN-ENTAILED`.
- "Attrition / time-to-relief organ is absorbable (recoverable gap)" — `DESIGN-ENTAILED`.
- "These absent/refused levers decide elite matters; B loses the scenarios above" — `HYPOTHESIS`
  (the central contested empirical bet; not proven by either side, per beat-the-canon Part 4).
- "B's assurance spine (TCB, isolation, deadline liveness, gateway, no-self-merge) is sound" —
  `DESIGN-ENTAILED` (and coincides with the parts the autopsy left standing for the canon).
- Verdict SURVIVES-WOUNDED — `DESIGN-ENTAILED` given the above, with FATAL withheld because the
  design hides nothing decisive (Part 14 + W8 pre-concede) and fails safe rather than confidently
  wrong.

*End of REJECT-B.*
