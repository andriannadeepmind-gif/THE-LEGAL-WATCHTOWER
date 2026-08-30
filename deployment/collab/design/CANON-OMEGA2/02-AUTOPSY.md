# CANON AUTOPSY — LAWMAX-Ω, hostile claim-by-claim

Scope: `LAWMAX-OMEGA-CANON/` files START-HERE, 00-INDEX, 00-MISSION, 01-INVARIANT,
02-ARCHITECTURE, 03-ORGANS, 04-OFFICE, 05-GROUND-B0, 06-TRANSITION, 07-VERIFICATION.
Method: for each major claim — (1) strongest valid reading; (2) concrete counterexample /
attack; (3) hidden assumption; (4) failure mode in real litigation/operations;
(5) verdict; (6) precise replacement. Claim-status tags per statement:
THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN.

Ground state as declared by the canon itself (05-GROUND-B0): K does not exist as code;
0/17 theorems discharged; fail-open constitutional gate present; no scouts, organs, or
ingestion built; legal coverage minimal. Therefore **every claim below whose status the
canon states as proved is, at the artifact level, HYPOTHESIS or DESIGN-ENTAILED, not
IMPLEMENTED/DEMONSTRATED.** The canon concedes this in its status ladder (07 §1) and
mostly disciplines its language — that discipline is the strongest thing in the package
and it is honored where noted. The autopsy attacks the *design* claims that survive even
if every proof were discharged.

---

## HEADLINE VERDICTS (read this first)

| # | Claim | Verdict |
|---|---|---|
| 1 | Root Invariant INV | SURVIVES-WEAKENED (scope-limited to *machine-decidable* trust; silent on the untrusted-input trust it cannot remove) |
| 2 | Axiom Φ (post-challenge value) | SURVIVES-WEAKENED (true for arguments; false as applied to irreversible acts and settlement value) |
| 3 | Axiom Υ (construal undecidability) | SURVIVES (and is the canon's most honest move) |
| 4 | A1–A5 "complete disjunction" supremacy proof | DEMOLISHED as a supremacy theorem; SURVIVES-WEAKENED as a per-axis dominance argument over a *chosen* basis |
| 5 | Exhaustiveness of the A1–A5 basis | DEMOLISHED (plausibility sweep, not a completeness proof; missing axes named below) |
| 6 | Dominance by inclusion (all models ⇒ all ideas) | DEMOLISHED (verifier-completeness ≠ generator-completeness; the gate cannot recognize what it cannot formalize) |
| 7 | One-round absorption | SURVIVES-WEAKENED (holds for reusable argument-forms; fails for one-shot and out-of-window moves) |
| 8 | Disputes born won / preclusion | SURVIVES-WEAKENED (real and valuable at drafting time; "born won" is oversold — bilateral, discretionary, and future-law-dependent) |
| 9 | Single admission kernel K | SURVIVES-WEAKENED — but **K as written is a god-kernel**; must be split into ≥6 seats |
| 10 | "Verified Legal World — the only truth" single world | DEMOLISHED as single-world; SURVIVES only as a multi-world / labelled-authority store |
| 11 | Answer-as-proof + checker | SURVIVES-WEAKENED (sound where formalizable; the formalization gap is the real trust root, not "mathematics") |
| 12 | Backtesting as counterfactual-dominance evidence | DEMOLISHED as counterfactual proof (selection bias, no counterfactual, non-stationarity); SURVIVES as weak observational signal |
| 13 | SEV self-improvement loop | SURVIVES-WEAKENED (governance is sound; "autopoietic" is overclaimed; replay-regression cannot see semantic regressions it doesn't already encode) |
| 14 | Multi-model socket mandate | SURVIVES (as engineering); the *supremacy* work it is asked to do (see #6) it cannot bear |

Two BLOCKING contradictions are recorded at the end and are not resolved by the canon.

---

## CLAIM 1 — The Root Invariant (INV)

> "Nothing becomes trusted except through justification checkable by an independent third
> party; and the system is architecturally incapable of emitting (a) an unjustified trusted
> claim, or (b) an unstamped completeness claim." (01 §1)

**(1) Strongest valid interpretation.** A typed-emission discipline: the output type of the
trusted core has no constructor for "trusted-but-unjustified" or "complete-but-unstamped".
This is a genuine and strong design invariant — it converts a class of errors from
*forbidden* to *unrepresentable*, which is the correct engineering move. Status:
DESIGN-ENTAILED (if the kernel is actually built and proven; today HYPOTHESIS — 05 says K
does not exist and the extant constitutional gate is fail-open, a live INV violation).

**(2) Counterexample / attack.** INV governs the *emission* boundary but is silent on the
*input trust* the system cannot avoid. Every "justification checkable by a third party"
bottoms out in facts, and the canon concedes facts are probabilistic proposals requiring
human confirmation (00 Honest limits; O3). So the trusted core routinely emits conclusions
of the form "IF facts F THEN law L, proof P". The trust the client actually consumes is
"F holds" — which is *never* third-party-checkable by the machine and is asserted by a
human. INV does not eliminate trust; it *relocates* it to (i) the human fact-confirmer and
(ii) the formalizer who wrote the statute-as-code and the certificate schema. Neither is
inside INV's guarantee. A wrong formalization of a statute produces a machine-checked proof
of a legally false proposition, and INV emits it as "trusted".

**(3) Hidden assumption.** That "justification checkable by an independent third party"
and "correct" coincide. They do not. INV guarantees *checkability of a derivation*, not
*soundness of the premises or of the natural-language→formal map*. The canon's own
discipline warns against exactly this conflation ("never equate proof-checking with
correctness of a formalization") — but INV's plain wording invites the reader to hear
"cannot emit a wrong trusted claim", which is false.

**(4) Failure mode.** A deadline is compiled from a procedural article whose exception
clause was mis-encoded (a real, common formalization defect). K certifies "filing timely,
proof attached." The proof checks. The filing is late. The client's claim is time-barred.
INV fired green on a fatal error because the error was upstream of the checkable boundary.

**(5) Verdict: SURVIVES-WEAKENED.** INV is a real and valuable invariant over the
*derivation* layer. It is not, and must never be presented as, an invariant over *legal
correctness*.

**(6) Replacement / repair.** Restate INV with an explicit **premise-trust ledger**: every
trusted emission must additionally carry a typed, enumerated list of its *unchecked* trust
dependencies — {fact-confirmations by whom; formalization artifacts and their validation
status; coverage stamp}. INV's guarantee is then honest: "no trusted emission without a
checkable derivation *and* a complete manifest of what the derivation is trusting."
Formalization validation (statute-as-code ⇔ statute text) becomes a first-class, separately
attested obligation — not folded into "proof checks."

---

## CLAIM 2 — Axiom Φ (adversarial-forum payoff semantics)

> "The value of a claim is measured AFTER challenge; a claim that cannot survive scrutiny
> has value ≤ 0, however true." (01 §2)

**(1) Strongest reading.** In contested adjudication, unsupportable assertions are worse
than useless (sanctions, credibility). As a *definition of the forum's payoff for
argumentative claims*, this is sound and is doing real work: it justifies "prefer justified
outputs" as dominance, not mere caution.

**(2) Counterexample.** Φ is false for the two things litigation most turns on:
(a) **Irreversible acts.** A party performs — pays, transfers title, waives, lets a
deadline pass. The "value" of that act is realized *at performance*, not after any later
challenge; there is no post-challenge re-measurement. (b) **Settlement.** The overwhelming
majority of matters resolve without a merits challenge. Their value is set by *perceived*
strength, timing, and the parties' risk tolerance — often by claims that would *not* have
survived challenge but were never challenged. Φ mis-prices the actual game.

**(3) Hidden assumption.** That every claim of value is eventually challenged in a forum
that re-prices it. Real disputes are dominated by *unchallenged* moves and *pre-forum*
economics (leverage, delay, cost asymmetry). Φ smuggles a "full-information, fully-litigated
world" into an axiom.

**(4) Failure mode.** The system, optimizing for "claims that survive challenge," under-weights
a bluff-and-settle strategy that a human elite team would correctly play, because such a
strategy scores ≤ 0 under Φ despite being the value-maximizing move. It also has no native
model of *irreversibility-as-value* (that comes in only later, awkwardly, via preclusion).

**(5) Verdict: SURVIVES-WEAKENED.** Correct for the argument-scoring subgame; wrong as a
global payoff axiom.

**(6) Replacement.** Split Φ into Φ-arg (post-challenge scoring for *contestable claims*,
retain) and add Φ-act: **irreversible acts and elapsed procedural windows are priced at
commission, independent of any later challenge.** Add an explicit **settlement/leverage
payoff model** as a first-class value channel, not a residue. Otherwise the system is
provably supreme at a subgame that most matters never enter.

---

## CLAIM 3 — Axiom Υ (undecidability of the construal space)

> "'Every interpretation a court could be persuaded to accept' admits no effective
> enumeration; hence unbounded interpretive-completeness claims are sometimes false; any
> competitor claiming total interpretive completeness is provably lying." (01 §2)

**(1) Strongest reading.** The set of persuadable construals is open-ended and not
recursively enumerable in any faithful model; therefore only coverage-*relative*
completeness can be always-true. This is the single most honest and most defensible move in
the canon: it forecloses the fantasy of total completeness *from the inside* and forces the
coverage stamp.

**(2) Counterexample / attack.** The axiom is well-taken; the *attack* is that the canon
then leans on Υ asymmetrically. Υ is invoked to (a) kill competitors ("provably lying") and
(b) excuse the system's own gaps as "honestly bounded." But Υ equally undercuts the canon's
own Pillar-4 "enumerates the opponent's whole move-space" language: if the construal space
is non-enumerable, then "exhaustion" is *always and only* exhaustion-relative-to-C, and the
word "whole" in "whole move-space" is exactly the overclaim Υ forbids. The canon uses Υ as a
sword against rivals and forgets to point it at Pillar 4's own rhetoric.

**(3) Hidden assumption.** That "no effective enumeration" and "no *useful bounded*
enumeration" are the operative distinction — fine — but also that the *boundary C itself* is
well-defined and stable. In practice C is chosen by an untrusted generator (P4/BO-28); its
edges are exactly where the elite adversary lives. Υ guarantees the map is incomplete; it
does not guarantee the system *knows where* its own C ends relative to a live opponent.

**(4) Failure mode.** None fatal — but the canon's phrase "no opponent wins with a line that
was inside" (00 §2) is true only tautologically ("inside C"). The dangerous line is the one
just *outside* C that the coverage stamp faithfully discloses but the lawyer, trusting the
system, does not pursue.

**(5) Verdict: SURVIVES.** The axiom is correct and load-bearing.

**(6) Repair (not replacement).** Enforce Υ *symmetrically*: strike "whole move-space" and
"complete disjunction / exhaustion" as unqualified terms everywhere in 01/02, replacing with
"C-relative." Add a required **boundary-proximity signal**: when the opponent's actual move
lands within ε of C's edge, that is a first-class alert, because Υ says that edge is where
defeat is manufactured.

---

## CLAIM 4 — The A1–A5 "complete disjunction" supremacy proof (greatest element)

> "Under Φ and Υ, the architecture derived from INV is the greatest element of the design
> space; no architecture is strictly superior." (01 §3)

**(1) Strongest reading.** For each of five binary design questions, the "justified/verified/
bounded/gated/tamper-evident" pole weakly dominates its opposite under Φ (you keep every
good conclusion and shed a ≤0-value failure class), the five tops are jointly realizable,
and nothing is defined "above" a top. As a *per-axis, same-capability dominance argument*
this is basically valid and is a clean way to justify the five pillars.

**(2) Counterexample / attack — the proof is not a supremacy theorem.** Three independent
defects:
- **(a) The order is partial; "greatest element" requires more than five dominated axes.**
  "Greatest element" means: dominates *every* other architecture on *every* axis. The
  argument only shows dominance on the five *chosen* axes. Two architectures agreeing on
  A1–A5 can differ arbitrarily on everything the basis omits (idea generation quality,
  latency, judicial-persuasion modeling, settlement strategy, human-factors). On those,
  this design is *not* shown to dominate. A greatest element of a *sub*-lattice is not a
  greatest element of the lattice. Status of "greatest element": DEMOLISHED. Status of
  "greatest element of the {A1..A5} sublattice": DESIGN-ENTAILED (weak).
- **(b) Step 2's dominance construction hides a real cost as "engineering effort."** "S′ = S +
  justification requirement; every justifiable true conclusion of S is expressible in S′."
  This assumes the justification requirement is *free of expressiveness loss*. It is not:
  conclusions that are *true and valuable but not currently formalizable* (open-texture
  judgments, persuasive-but-informal framing) are demoted from "trusted" to "defeasible
  argument," i.e. S′ trusts a strictly smaller set than a well-calibrated S might act on.
  The canon waves this away as "cost is engineering effort, not capability" (A2) — that is
  the banned move (hiding a trade-off as an engineering detail). There is a real
  non-compensatory tension: justification-completeness vs. actionable coverage.
- **(c) "Above a top nothing is defined" is an argument from lack of imagination.** Step 4
  asserts no architecture beats "independently checkable justification." But an architecture
  with *checkable justification PLUS a calibrated measure of premise-formalization fidelity*
  strictly dominates one with checkable justification alone (it sheds the mis-formalization
  failure class of Claim 1). The canon's own later "native clauses" *are* such higher points
  discovered after the fact — proving the tops were not tops.

**(3) Hidden assumption.** That the design space is *exhausted by binary axes* and that the
axes are *independent and non-compensatory*. Neither is established. The "non-compensatory"
stipulation is asserted to dodge the fact that real architecture choices trade axes against
each other (the canon itself rejects blocking N-kernel unanimity precisely because it trades
assurance for liveness — a compensatory choice, admitted in 02 §9, contradicting the
non-compensatory framing).

**(4) Failure mode in operations.** The proof's rhetorical force ("greatest element,"
"supremacy proof") will be used internally to *stop search* — "we proved it's the top, so we
needn't look for a better generator/persuasion model/settlement engine." That is the exact
mediocrity the creator contract forbids, licensed by a mislabeled theorem.

**(5) Verdict: DEMOLISHED as a supremacy/greatest-element theorem. SURVIVES-WEAKENED as a
per-axis dominance argument for adopting the five poles.**

**(6) Replacement.** Retitle to what it is: **"Per-axis dominance of the five safety poles
under Φ (weak, over a declared basis)."** Drop "greatest element of the design space."
State explicitly: the design dominates only on the assurance/memory/gating axes; on
generation quality, persuasion, and settlement it makes *no* dominance claim and competes
empirically. Move A2's and the compatibility step's costs out of "engineering detail" into
a named, non-compensatory trade-off register. This is *strictly stronger* (per CLAUDE.md
§1's own rule: the higher conception is the honest one) and removes a self-inflicted INV
violation (a completeness/supremacy overclaim).

---

## CLAIM 5 — Exhaustiveness of the {A1..A5} basis (the "named residue")

> Residue = exhaustiveness of the basis. Defense: (a) derivational — survival decomposes
> "exactly into" A1..A5; (b) empirical — a six-lens adversarial search found "no orthogonal
> sixth axis." (01 §3 Step 5)

**(1) Strongest reading.** A best-effort argument that the five axes carve the assurance
space at its joints, plus adversarial evidence that attacks kept reducing to the existing
pillars. Honest about being a residue.

**(2) Counterexample / attack — this is a plausibility sweep, NOT a completeness proof, and
the canon nearly says so.** The "derivational" defense is a bare assertion that "survival
decomposes *exactly* into (what justifies, on what ground, over what scope, how it evolves,
how it recorded)." No proof that these five are jointly exhaustive and mutually irreducible
is given; the word "exactly" is doing unearned work. The "empirical" defense is an
adversarial search that *by its own account* returned only `UPGRADE_TO_EXISTING_PILLAR`
verdicts — but a search that classifies every finding into the existing basis *cannot, by
construction, discover an axis orthogonal to the basis*; the classification scheme presupposes
the answer. That is a tautological test (a banned pattern). Concretely, axes the basis omits:
- **A6 — generative/creative adequacy** (the quality of the proposals the verifier gets to
  choose among). The canon offloads this to "dominance by inclusion" (Claim 6), which fails.
- **A7 — human-interface fidelity** (whether the human confirmations, adoptions, and
  sign-offs INV depends on are elicited without inducing error). The whole trusted chain
  rests on human acts the architecture treats as oracles.
- **A8 — temporal/procedural liveness under real deadlines** (can the certified answer be
  *produced in time*; a correct proof after the filing window is value ≤ 0 under the canon's
  own Φ). This is named as a "correctness requirement" in the brief but is not an assurance
  axis in the basis.
- **A9 — adversarial epistemics of the forum itself** (judicial discretion, panel
  composition, extra-legal persuasion) — orthogonal to all five internal axes.

**(3) Hidden assumption.** That an adversarial search *scored by whether attacks reduce to
the pillars* can falsify the pillars' completeness. It cannot; it can only confirm.

**(4) Failure mode.** "No sixth axis exists" hardens into doctrine; A6–A9 defects surface in
production (a lost matter from a persuasion/discretion failure) and are mis-triaged as
implementation bugs rather than a missing architectural axis, because the canon "proved"
there is no sixth axis.

**(5) Verdict: DEMOLISHED (as exhaustiveness). The residue is larger than "the basis might
be incomplete" — at least four candidate orthogonal axes are visible without deep search.**

**(6) Replacement.** Downgrade Step 5 from "named residue, adversarially closed" to **"open
basis; five assurance axes established, generative/human/temporal/forensic-forum axes
explicitly OUT of the current basis and UNRESOLVED."** Change the adversary's rubric so a
finding *may* be classified `NEW_ORTHOGONAL_AXIS`, not only `UPGRADE_TO_EXISTING_PILLAR` —
otherwise the search is a ratchet that can only ever confirm. Until then, exhaustiveness is
HYPOTHESIS and must not appear in any supremacy statement.

---

## CLAIM 6 — Dominance by inclusion (all models ⇒ all ideas)

> "The system is the best verifier with access to ALL generators. Any idea available to an
> opponent-using-model-X is available to us; the gate selects the best. No better idea
> exists that cannot become ours." (00 §3; 02 P1 native clause)

**(1) Strongest reading.** Because every model is untrusted and socketed as a proposer, the
firm's *generator set* is a superset of any single opponent's model set; the verifier then
certifies the best admissible proposal. Superset-of-generators is genuinely true and useful.

**(2) Counterexample / attack — superset of *generators* is not superset of *ideas*, and the
gate cannot select what it cannot recognize.** Four independent breaks:
- **(a) Same model ≠ same idea.** "Any idea available to an opponent using model X is
  available to us" is false. Ideas are elicited by *prompting, context, decomposition, and
  human insight*, not by mere model access. The opponent's brilliant human lawyer using
  model X with a decomposition we never posed produces an idea our identical socket never
  emits. Model access is a necessary, wildly insufficient condition. (The brief's discipline
  names this exact fallacy: "never equate model access with idea inclusion.")
- **(b) The gate is a *recognizer*, not an *oracle*.** "The gate selects and certifies the
  best" assumes the best idea is *expressible as an admissible, authority-anchored,
  formalizable proposal the gate can rank.* The highest-value legal ideas are frequently
  open-textured, novel-characterization, or extra-doctrinal (a policy framing that moves a
  judge). Under the canon these enter only as *defeasible argument*, and the gate cannot
  *certify* them as dominant — it can only pass them through untyped. So "the gate selects
  the best" collapses precisely where ideas matter most: the verifier can rank formal
  proposals, but cannot recognize the superiority of an unformalizable-but-decisive one.
- **(c) Selection needs an oracle the canon doesn't have.** To "select the best" proposal you
  need a correct ordering over proposals. For formal claims, proof-checking gives it. For
  strategy/persuasion, the only ordering offered is the realized-outcome loop (P5) — which is
  backward-looking, thin on novel matters, and (Claim 12) not a counterfactual. So on the
  axis where "all ideas" matters, there is no trustworthy selector.
- **(d) Adversary can poison the socket bay.** N competing models fed an attacker-controlled
  filing can be steered to a *consensus wrong construal* (correlated failure across models
  sharing training priors). "More models" raises a false-consensus risk the canon's
  invariance guard (prior-perturbation) does not test — that guard perturbs *priors used for
  ordering*, not the *generator population's shared blind spots*.

**(3) Hidden assumption.** That legal ideation ≈ sampling from a model, and that value is
recognizable at selection time by an available checker. Both false for the decisive class of
ideas.

**(4) Failure mode.** The firm believes it "cannot be out-idea'd because it has every model,"
declines to invest in human-lawyer ideation and prompting craft, and is beaten by a smaller
team whose human posed a better question to the *same* model — the canon's own residue,
under-mitigated because "dominance by inclusion" told the firm the problem was solved.

**(5) Verdict: DEMOLISHED as stated. The true, weaker claim survives: *superset of
generators*, not *superset of ideas*, and only *formal* proposals are gate-selectable.**

**(6) Replacement.** Restate as **"generator-superiority by inclusion (weak): our proposer
population ⊇ any single opponent's models; therefore no *model-reachable, formalizable*
proposal is unavailable to us. This does NOT entail idea-superiority: elicitation, human
decomposition, and unformalizable insight are outside the guarantee and are the residue
one-round-absorption is meant to catch."** Then invest explicitly in an **elicitation/prompt-
strategy organ** and **human-ideation seats** as first-class, since that is where the real
gap lives — the canon currently has no seat for "asking the models the right question."

---

## CLAIM 7 — One-round absorption

> "Any novel weapon used against the firm is ingested, analyzed, countered in the next
> procedural round, and becomes a permanent asset. The inventor used it once." (00 §2; 02 §3)

**(1) Strongest reading.** Litigation is turn-based with mandatory disclosure and a
guaranteed right of response; a *reusable argument-form* revealed by the opponent can be
verified, countered within the response window, and stored forever. For the class of
reusable doctrinal/argumentative innovations, this is real and strong.

**(2) Counterexample / attack — "one round" assumes the harm is deferrable to the next
round; much litigation harm is not.**
- **(a) One-shot procedural consequences.** The novel move *is* the harm and it completes
  in-round: a surprise at an oral hearing that triggers an immediate adverse ruling; an
  admission extracted in live cross; a preliminary injunction granted on a novel theory that
  moves assets before the response window. "Countered next round" is worthless when the asset
  is gone or the interim order sets irreversible facts.
- **(b) Out-of-window / no next round.** Courts of last instance, single-hearing procedures,
  strict preclusion (a point not raised is waived), and appellate novelty bars: there often
  *is* no "next procedural round" in which to deploy the absorbed counter *for this client*.
  Absorption benefits *future* matters; it does not save *this* client — but the mission is
  "the client cannot lose," and this client just did.
- **(c) Absorption latency vs. window.** "Ingest → verify → certify counter" is the heavy
  certified pipeline; the response window may be days. The canon's real-time layer explicitly
  *cannot* certify live and flags novelty as NOVEL for "the recess/next round." So one-round
  absorption and the real-time design *agree* that novel moves are punted — which contradicts
  the mission-level promise that novelty costs the opponent only "one use."

**(3) Hidden assumption.** That every novel move (i) is disclosed *before* it does
irreversible damage, and (ii) can be answered *within the same matter's remaining procedure*.
Disclosure-before-harm is false for interim relief and live-hearing moves; same-matter
answerability is false at last instance and under preclusion.

**(4) Failure mode.** A novel characterization raised for the first time at the Areios Pagos
(Greek supreme court) hearing, or a novel ex parte injunction theory — absorbed beautifully
into P5 for the *next* client, while *this* client loses irreversibly. The "born won"
mission is violated in exactly the high-stakes tail it was written for.

**(5) Verdict: SURVIVES-WEAKENED.** True and valuable for reusable argument-forms across
matters; false as a *per-matter* guarantee and false for one-shot/irreversible/last-round
moves.

**(6) Replacement.** Split the law: **(i) cross-matter absorption (survives, keep as stated,
scope = future matters)**; **(ii) in-matter novelty exposure = a distinct RISK, not a solved
problem** — mitigated by *pre-emptive* exhaustion (drive novelty discovery *before* the
opponent, via preventive deployment) and by an explicit, honest "irreversible-harm-this-round"
alarm class. Never state absorption as a per-client guarantee.

---

## CLAIM 8 — Disputes born won / preclusion (P4 preclusion, BO-27, BO-32)

> "Instruments compiled so disputes are born won: exhaustion runs against the DRAFT,
> rewriting until each future dispute is pre-computed in the client's favor, with a
> preclusion certificate — a class of opponent moves is provably inadmissible and stays
> empty under all reachable play." (00 §; 02 P4; 06 BO-32)

**(1) Strongest reading.** A controllable-predecessor / safety-game fixpoint over the
*irreversibility doctrines that are genuinely computational* (limitation periods,
res judicata, contractual waivers, procedural defaults) can prove that certain opponent
moves are foreclosed, and drafting can be optimized to maximize such foreclosure — plus a
mandatory second proof that the same irreversibility doesn't self-bind the client. This is a
real, novel, valuable capability at drafting time.

**(2) Counterexample / attack.**
- **(a) The safety game is not solitaire.** "Stays empty under all reachable play" models the
  dispute as a game the drafter controls the reachable set of. But contract disputes are
  *bilateral and world-coupled*: the opponent's future acts, third parties, supervening
  facts, and *future changes in law* expand the move-set after drafting. A limitation defense
  is not "empty under all play" — it can be interrupted, tolled, waived by the client's own
  later conduct, or overridden by a later mandatory-law amendment. The fixpoint is over a
  *frozen* rule-set and a *frozen* world; reality unfreezes both.
- **(b) Preclusion doctrines are themselves discretionary/defeasible.** Estoppel, abuse of
  right (καταχρηστική άσκηση δικαιώματος, GCC 281), good faith — the very tools that create
  preclusion are open-textured and can be turned *against* an over-aggressive "born won"
  clause (a court voiding a one-sided term as abusive). A clause engineered to foreclose all
  opponent moves is exactly the profile a court polices under GCC 281 / consumer law /
  unfair-terms directives. "Born won" can boomerang into "void for over-reach."
- **(c) Certificate ≠ outcome.** A "preclusion certificate" certifies foreclosure *relative to
  the encoded doctrine set and the frozen world*. Under Υ (Claim 3) that set is C-relative.
  So the certificate says "won relative to coverage C and world W₀," which is not "born won."

**(3) Hidden assumption.** That future disputes are foreclosed by drafting-time-computable,
non-defeasible, unilateral doctrines over a static legal order. The valuable preclusion
doctrines are partly discretionary, bilateral, and time-varying.

**(4) Failure mode.** A contract "born won" via aggressive waiver/limitation engineering is
struck as abusive under GCC 281, or the limitation defense is tolled by the client's own
later acknowledgment, or a 2028 mandatory-law amendment retroactively reopens the class —
and the "born won" certificate, relied on, discouraged the belt-and-suspenders drafting a
cautious human would have kept.

**(5) Verdict: SURVIVES-WEAKENED.** Preclusion-maximizing drafting with a non-self-binding
proof is a real advance; "disputes born won" is an overclaim.

**(6) Replacement.** Rename "born won" → **"maximally pre-precluded, C-relative, world-W₀,
subject to defeasibility and future-law risk."** Require every preclusion certificate to (i)
name its frozen rule-set version and world assumptions, (ii) carry an *abuse-of-right /
unfair-terms self-attack* (does foreclosure itself create a voidability handle?), and (iii)
carry a *future-law sensitivity* flag for mandatory-law domains. Keep the client-non-self-
binding proof — that part is excellent.

---

## CLAIM 9 — The single admission kernel K (god-kernel probe)

> "K — trusted, tiny; total, decidable, deterministic; the ONLY component that admits
> anything into the world or issues anything out of it. Fail-closed." (02 §1)

**(1) Strongest reading.** A single, minimal, formally verified choke point for *admission
and issuance* is the correct way to make INV structural — one place to prove total,
deterministic, fail-closed, rather than N places to audit.

**(2) Counterexample / attack — as *written*, K is a god-kernel: the canon assigns it a
sprawling, heterogeneous responsibility set that cannot all be one tiny verified thing.**
Enumerating everything the canon routes through K / "K's side":
1. Admission of scout-proposed **law** into L2 (recompute-from-source, ELI keying, temporal
   stamping, provenance seal). (02 §1, 03 O1)
2. Admission of **facts/exhibits** (readings + confidence + human-confirmation gating). (03 O3)
3. Admission of **case-law** as precedential constraint (Horty forcing certificates). (02 P2, BO-06)
4. Admission of **doctrine** as defeasible material. (02 P2)
5. **Proof/certificate checking** for every trusted conclusion (answer-as-proof). (02 P3, O11)
6. **Coverage-stamp typing** — refusing unstamped-complete. (02 P2 native clause)
7. **Four-valued answer** enforcement (PROVED/REFUTED/UNKNOWN/STABLE). (02 §4)
8. **Emission/issuance** of outputs (the only egress). (02 §1)
9. **Single physical writer** + witness-quorum cosigning of the authoritative log. (02 P1)
10. **Preclusion-certificate** admission + non-self-binding proof. (02 P4, BO-27)
11. **Cross-matter consistency guard** ("at K's side"). (03, BO-36)
12. **Operating-mode stamp** ("at K's side"). (03, BO-37)
13. **SEV upgrade-certificate** admission for changes to the system itself. (BO-33)
14. **Publication-gateway** decision to the public ELI surface (the wall). (04 §1)
15. The **inference-boundary gateway** posture enforcement is a separate "trusted egress
    seat" (03 O14) — already tacitly conceded to be *not* K, which proves the point.

That is at least six *different trust foundations* (recompute-from-source verification;
proof-checking over a proof system; type-checking; cryptographic write/quorum;
game-theoretic fixpoint checking; DLP/privilege publication review) collapsed under one
name. A "tiny, total, decidable, deterministic" kernel cannot be all of these: a proof
checker for the certificate corpus is not tiny, a Horty forcing checker is a different
artifact, DLP/privilege review for publication is *not decidable* and needs human approval
(the brief's own Publication Gateway), and SEV admission is a different ceremony entirely.
Bundling them means a change to any one re-verifies the whole TCB and a bug anywhere is a
bug in "the only decider."

**(3) Hidden assumption.** That "single choke point for issuance" (good) implies "single
implemented artifact K" (unnecessary and dangerous). One *invariant* (nothing trusted
without a check) does not require one *verifier*.

**(4) Failure mode.** TCB bloat: K grows to hold every checker; "tiny and verified" becomes
aspirational; the fail-open constitutional gate defect (05 §2) is exactly the failure mode of
a decider doing too much. Worse: coupling publication-review (non-decidable, human,
DLP-laden) into the same seat as deterministic admission violates the brief's fail-closed
*separate* Publication Gateway requirement.

**(5) Verdict: SURVIVES-WEAKENED — the *principle* (one issuance boundary, fail-closed)
survives; the *artifact* K as a single god-kernel is rejected.**

**(6) Replacement — split K into a *family of small verifiers behind one typed admission
bus*, each independently minimal and proven:**
- **K-adm** — structural admission/totality/determinism/fail-closed decider (the genuinely
  tiny kernel; only this needs to be the CakeML/Lean-class minimal core).
- **K-src** — recompute-from-source authority verifier (law/case-law provenance).
- **K-prf** — proof/certificate checker(s), one per proof system (Lean/LRAT/Horty), each
  independently reproducible; *not* one blob.
- **K-typ** — coverage-stamp & four-valued type enforcer.
- **K-write** — single-writer + witness-quorum commit seat (crypto foundation, separate).
- **K-precl** — preclusion/safety-game certificate checker.
- **G-pub** — the **Publication Gateway** as a *separate fail-closed pipeline* (privilege
  review, DLP, redaction, authority validation, **human approval**, immutable receipt) — must
  NOT live in K; it is non-decidable and human-in-the-loop by mandate.
- **G-inf** — inference-boundary/egress gateway (already separate in O14 — keep it separate).
- **G-sev** — SEV upgrade-admission ceremony (certificate + human «εγκρίνω»), separate.
All share *one typed admission protocol and one write seat*, so "one seat per concept" is
honored *per concept*, not "one seat for all concepts." This is strictly stronger: each
verifier is small enough to actually prove, and a bug in the Horty checker cannot fail-open
the deadline decider.

---

## CLAIM 10 — "Verified Legal World — the only truth" (single-world epistemics)

> "L2 VERIFIED LEGAL WORLD (the only truth) — statutes-as-code, case law as precedential
> constraint, doctrine as defeasible material, all with provenance and temporal validity."
> (02 §1)

**(1) Strongest reading.** A single, provenance-sealed, temporally-versioned store is the one
authoritative *record of admitted sources*; "only truth" means "only trusted store," not
"only interpretation." Read charitably, L2 already holds case-law as *constraint* and
doctrine as *defeasible* — i.e. it is not claiming a single interpretation.

**(2) Counterexample / attack — but "the only truth," "the world," and the L2 diagram
(reads *whole world*) commit to a single-world epistemics that cannot represent the four
things litigation is made of:**
- **(a) Conflicting authorities of equal rank.** Two Areios Pagos chambers split; a directive
  and a national statute conflict pending CJEU reference; ECtHR vs. domestic constitutional
  reading. There is no single "in force" truth — there are *competing valid authorities*. A
  single world with one temporal validity interval per norm cannot hold "norm N means X per
  chamber A and ¬X per chamber B, both live."
- **(b) Competing interpretations.** Even the charitable reading (doctrine defeasible) puts
  *statutes-as-code* in the single world as executable objects. But an open-textured statutory
  term has *multiple admissible construals* (the P4 Qualifikation lattice!) — the architecture
  elsewhere *requires* many construals, yet L2 is described as one world. The construal
  multiplicity lives in L3/P4 but must be *anchored in L2 authorities*; the single-world
  framing has no type for "same norm, plural admitted construals."
- **(c) Alternative factual worlds.** Litigation is argued over *contested* fact-sets (the
  client's theory vs. the opponent's), often several live simultaneously (pleaded in the
  alternative). "The only truth" cannot host mutually inconsistent factual worlds that must
  *both* be reasoned in. The canon confines facts to {reading, source, confidence} — that is
  per-datum uncertainty, not *alternative coherent world-theories*.
- **(d) Procedural uncertainty.** Whether a filing was timely, whether service was valid,
  whether a court has jurisdiction — these are *contested procedural states* that are
  themselves the dispute. A single world with derived-deadline certainty (O4 "trusted")
  mis-models the frequent case where the procedural fact is *litigated*, not *derived*.

**(3) Hidden assumption.** That law admits a function `norm → single meaning at time t`. Law
admits, at best, `norm → set of admissible-meanings-with-authority-weights at time t, per
forum`. The single-world model is a category error about what legal truth is.

**(4) Failure mode.** The system reports "the law is X (proof attached)" where in fact there
is a live split the opponent will exploit; or it reasons in one factual world and is
blindsided by the alternative pleading; or it treats a contested jurisdictional fact as
settled. Each is a lost matter *caused by the epistemic model*, not by a bug.

**(5) Verdict: DEMOLISHED as "single world / only truth." SURVIVES as a *provenance store*
if re-architected to be explicitly multi-world / labelled.**

**(6) Replacement.** Re-seat L2 as a **labelled, multi-world authority store**:
- Norms carry not one meaning but a **set of admitted construals**, each with authority
  weight, forum scope, and temporal interval; *conflicts are first-class objects* ("split:
  N means X (auth a₁, forum f₁) vs ¬X (auth a₂, forum f₂), unresolved").
- Facts are organized into **named alternative world-theories** (client-theory, opponent-
  theory, court-found), reasoned over in parallel, never merged into "the truth."
- Procedural states that are *contested* are typed as **disputed**, not derived, with the
  litigation over them modeled explicitly.
- Rename "the only truth" → **"the only *trusted record of admitted authorities and their
  conflicts*"**. Answer-as-proof then proves "X follows *in world W under construal set S*,"
  which is the honest and litigable form. This is strictly stronger and it is what P4 already
  needs underneath it.

---

## CLAIM 11 — Answer-as-proof and its checker story

> "Every trusted conclusion ships a machine-checkable certificate, checked by a minimal,
> itself-verified, independently reproducible checker; trust bottoms out at mathematics, not
> at any vendor, model, or program." (02 P3)

**(1) Strongest reading.** Proof-carrying answers with a small verified checker, second-
foundation cross-check for the top tier, deterministic rendering into the tribunal's schema
with no LLM after certification. For the *formalizable* fragment this is best-in-class and
genuinely above the commercial floor.

**(2) Counterexample / attack.**
- **(a) "Trust bottoms out at mathematics" is false; it bottoms out at the
  natural-language→formal *translation*.** The checker proves `Γ ⊢ φ`. Whether `Γ` (the
  statute-as-code, the case-law forcing relation, the fact encodings) *faithfully means the
  law and the facts* is a human modeling act with no proof. This is the same gap as Claim 1,
  and it is the *actual* trust root. The canon's own BO-18 (trace-vs-explanation harness) and
  the honest-limits section acknowledge fragments of this, but P3's headline sentence
  overclaims the foundation.
- **(b) Verified-checker regress.** "Itself-verified" checker — verified *by what*? At some
  point a checker is trusted axiomatically or cross-checked by a second checker whose own
  verification also terminates in trust. The canon handles this well (second-foundation,
  independent reproduction) but the regress means the honest statement is "trust bottoms out
  at *a small, cross-checked, human-audited core*," not "at mathematics."
- **(c) Open-texture escape hatch swallows the hard cases.** "Open-texture conclusions ship
  structured arguments instead of proofs, typed differently." Correct — but this means the
  *decisive* legal reasoning (proportionality, good faith, reasonableness, discretion) is
  *outside* answer-as-proof. So "every trusted conclusion ships a proof" is true only because
  the un-provable conclusions are re-typed as "not trusted conclusions." The guarantee is
  real but its *domain* is the computational fragment, which is not where elite matters are won.

**(3) Hidden assumption.** That the value-bearing legal conclusions live in the
proof-checkable fragment. The canon's own honest-limits section concedes they largely do not.

**(4) Failure mode.** Over-trust in the certified fragment: a matter turns on a proportionality
judgment (defeasible, un-certified) but the certified deadline/subsumption spine radiates an
aura of "proven," and the human under-scrutinizes the actually-dispositive open-texture node.

**(5) Verdict: SURVIVES-WEAKENED.** Excellent for the formal fragment; the "bottoms out at
mathematics" and "every trusted conclusion" framings overstate scope and foundation.

**(6) Replacement.** Restate P3 root as **"trust bottoms out at a small, independently
cross-checked verification core *plus* a separately-attested formalization-fidelity
obligation."** Make **formalization fidelity** (statute-code ⇔ statute text; fact-encoding ⇔
confirmed fact) a first-class, human-attested, versioned artifact that ships *with* every
proof — the proof is worthless without it and the canon currently leaves it implicit.

---

## CLAIM 12 — Backtesting as evidence of counterfactual dominance

> "Blind replay: the system receives the case file as of filing date (no hindsight),
> produces strategy + pleading; metrics include prevail-rate of the chosen line vs. the
> historical line ... the 'beats elite teams' claim, made measurable." (07 §3; 00 honest
> limits)

**(1) Strongest reading.** A pre-registered, temporally-fenced blind replay against
adjudicated matters, with calibration (Brier) and citation-validity gates, is a serious,
honest attempt to make a supremacy claim *falsifiable* rather than asserted — far better than
the industry norm. As a *measurement discipline* it is commendable.

**(2) Counterexample / attack — backtesting cannot establish *counterfactual* dominance;
it is at best weak observational evidence:**
- **(a) No counterfactual.** "Prevail-rate of the chosen line vs. the historical line" compares
  the system's *proposed* line to the *actual outcome under the human's line*. But the outcome
  under the *system's* line was never run — the judge never saw it, the opponent never
  responded to it, no settlement dynamics unfolded. You cannot score a move that was never
  played against a live adversary. This is the fundamental identification problem; a Brier
  score over *predicted dispositions* measures *forecasting*, not *dominance*.
- **(b) Selection bias.** Adjudicated matters are a *biased sample* — most disputes settle;
  those that reach judgment are the atypical, often close or idiosyncratic ones. Dominance on
  litigated-to-judgment matters does not transfer to the settle-dominated population where the
  firm actually operates (see Φ, Claim 2).
- **(c) Non-stationarity / leakage.** The system is *built and tuned by people who know
  current law and recent doctrine*. "Temporal view enforced (no hindsight leakage)" fences the
  *case file* but cannot fence the *builders' and models' training knowledge* of how that era's
  law later developed. The models were trained on post-hoc corpora. True temporal blinding of a
  2026-trained model replaying a 2015 matter is impossible.
- **(d) Opponent is fixed.** Backtesting freezes the historical opponent. A supremacy claim is
  *relative to an adaptive elite adversary*; a frozen record cannot adapt. Beating the ghost of
  the 2015 opposing counsel is not beating a 2026 elite team.

**(3) Hidden assumption.** That "predicted disposition accuracy + prevail-rate on adjudicated
matters" is a valid estimator of "dominates elite teams in live, adaptive, settlement-laden
practice." It is not; the estimand and the estimator differ.

**(4) Failure mode.** A strong backtest score is promoted to "empirically dominant,
independently reproduced" (the VERIFIED rung, 07 §1) and used to authorize the SUPREME claim —
converting a forecasting benchmark on a biased, non-counterfactual sample into a supremacy
license. That is the canon's own banned move (backtesting as evidence of counterfactual
dominance).

**(5) Verdict: DEMOLISHED as counterfactual-dominance evidence. SURVIVES as (i) a *forecasting/
calibration* benchmark and (ii) a *regression* harness.**

**(6) Replacement.** Re-scope backtesting to what it can support: **calibration and
forecasting quality, and non-regression** — never "prevail-rate dominance." For any dominance
claim, require *prospective, adversarial, live* evaluation: (i) blinded head-to-head where
independent elite human teams and the system work the *same live/mock matter* before a mock
tribunal, adjudicated by neutrals; (ii) explicit settlement-outcome tracking. State plainly:
absent live adversarial trials, the permitted claim stays at "strongest design," and
backtesting *can never by itself* reach VERIFIED/SUPREME. Fix the status ladder (07 §1)
accordingly — as written it lets backtesting alone cross into "empirically dominant."

---

## CLAIM 13 — The SEV self-improvement loop (BO-33)

> "Autopoietic seat: standing self-adversary → untrusted multi-model builders design/implement
> the upgrade → isolated sandbox (full proof CI, gates, mutation adversary, bit-for-bit replay
> over the entire P5 corpus) → upgrade certificate → creator «εγκρίνω». Autopoietic in labor,
> heteronomous in authority. Self-merge structurally impossible." (BO-33; 07 §5)

**(1) Strongest reading.** The system continuously attacks *itself*, auto-generates candidate
fixes, proves them in an isolated sandbox with full regression, and *cannot self-merge* —
every change needs a valid certificate *and* the creator's explicit approval. The governance
(labor autonomous, authority heteronomous) is exactly right and is the correct answer to
"self-improving AI safety." Best-in-class.

**(2) Counterexample / attack.**
- **(a) "Bit-for-bit replay regression over the entire P5 corpus" cannot catch the regressions
  that matter.** Replay proves *old decisions re-derive identically* — i.e. it protects against
  *changing* past answers. But a genuine improvement *should* change some answers (better
  coverage, corrected construal). The canon allows this via "declared semantic deltas." The gap:
  replay can only tell you *that* an output changed, not whether the change is *legally better
  or worse* — that judgment is exactly the open-texture, un-certifiable reasoning outside
  answer-as-proof. So the automated evidence bounds *stability*, not *correctness of change*.
  A subtly wrong construal-generator upgrade that changes 200 answers passes CI (all proofs
  green, all deltas "declared") and lands on the creator's desk as a certificate the creator
  cannot feasibly adjudicate 200 legal deltas for.
- **(b) The self-adversary shares the system's blind spots.** A standing self-adversary built
  from the same models/foundations as the system inherits its correlated blind spots (same as
  Claim 6d). "The system attacks itself" is bounded by what the system can conceive as an
  attack — it cannot self-discover an *orthogonal axis* (Claim 5) it has no representation for.
  Autopoiesis over a fixed representational basis is refinement, not open-ended improvement.
- **(c) "Autopoietic" is overclaimed.** The system regenerates *components within a fixed
  architecture and fixed pillar basis*; it does not regenerate its own invariant, basis, or
  ontology. That is *homeostasis/self-maintenance*, not autopoiesis. The canon even admits the
  Method (the real meta-level) re-derivation is a *human*-driven event ("if a genuinely new
  axis is ever revealed, the Method re-derives"). So the truly generative level is heteronomous
  in *labor* too, not just authority — contradicting "autopoietic in labor."
- **(d) Approval bottleneck vs. mission.** "Creator's role collapses to reading the certificate
  and approving." For a self-evolving system generating frequent upgrades each carrying possibly
  hundreds of declared legal deltas, meaningful human approval is *infeasible at volume* — the
  approval becomes rubber-stamp, silently re-admitting the drift the design was meant to
  prevent (a de-facto A4 violation through human-factors, not architecture).

**(3) Hidden assumption.** That "proofs green + replay-stable + deltas declared" ≈ "the change
is an improvement," and that a human can authority-review at the system's production rate.

**(4) Failure mode.** SEV lands a construal-generator "improvement" that is legally worse on a
class of matters; every gate is green; the creator approves the certificate without adjudicating
each semantic delta; the firm silently regresses on that class — discovered only via a lost
matter and the incident protocol (BO-38), which feeds SEV, which "fixes" it with another
under-reviewed delta. The loop can drift.

**(5) Verdict: SURVIVES-WEAKENED.** Governance model is excellent and should be kept verbatim.
"Autopoietic in labor," the sufficiency of replay-regression as a correctness gate, and the
feasibility of meaningful high-volume human approval are overclaimed.

**(6) Replacement.** (i) Rename "autopoietic" → **"self-maintaining within a fixed basis;
basis-change is human"** — say plainly the generative meta-level is heteronomous in labor too.
(ii) Add a **semantic-delta adjudication budget**: an upgrade may carry only as many
open-texture-affecting deltas as a human can actually review; larger changes are split or
staged. Deltas outside the certified fragment require *sampled human legal review*, not just
"declared." (iii) Add an **independent (differently-founded) self-adversary** so the self-attack
does not share the system's blind spots. (iv) Make explicit that replay-regression gates
*stability*, not *correctness*, and that correctness of change on the un-certified fragment has
*no automated gate* — it is a standing residue.

---

## CLAIM 14 — The multi-model socket mandate (BO-31, P1 native clause)

> "Every generative organ is a socket bay: N frontier models run the same brief in parallel,
> propose competing outputs, K/the certificate layer adjudicates; model identity never in the
> trusted path; adding a model = registering a socket, zero redesign." (03; 02 P1; BO-31)

**(1) Strongest reading.** As an *engineering* pattern — untrusted, hot-swappable proposer
sockets behind a typed proposal protocol, identity-blinded from the trusted path — this is
clean, correct, and makes model progress a pure upside with no TCB change. Genuinely good.

**(2) Counterexample / attack.**
- **(a) It is asked to carry the supremacy weight of Claim 6 and cannot.** The mandate's stated
  purpose is "what makes dominance-by-inclusion real" (02 P1). Since dominance-by-inclusion is
  demolished (Claim 6), the *mandate stands as engineering but the supremacy justification for
  it collapses* — sockets give you a superset of *generators*, not of *ideas*, and the
  adjudicator can only rank the *formalizable* subset.
- **(b) Correlated failure / false consensus.** N models from a shrinking pool of foundation
  families share training data and biases. "Competing proposals" can *agree wrongly*; the
  canon's invariance guard tests prior-perturbation, not generator-population blind spots. More
  sockets can *increase* confidence in a shared error.
- **(c) Adjudication oracle gap (again).** "K adjudicates the best" — for proofs, fine; for
  strategy/persuasion/framing, the only selector is the realized-outcome loop, which is thin,
  backward-looking, and non-counterfactual (Claim 12). So on the generative axis the socket bay
  produces many candidates and has *no trustworthy way to pick the best*.
- **(d) Confidentiality tension.** "Every available frontier model" competes — but most frontier
  models are *external vendor APIs*, and privilege (δικηγορικό απόρρητο) forbids sending client
  strategy off-prem except through the gateway under posture. So the *actual* live socket
  population for privileged work is DEGRADED-mode local models, not "every frontier model." The
  mandate's power and the privilege mandate are in direct tension the canon notes (O14/modes)
  but does not price into the supremacy story.

**(3) Hidden assumption.** That more diverse proposers monotonically improve outcomes and that a
trustworthy selector exists across all organ types. True for proofs; unestablished for
generation; false under correlated failure.

**(4) Failure mode.** Firm believes "N models = unbeatable ideation," but for privileged matters
runs 2 local models that share a foundation and agree on a wrong characterization; no counterfactual
selector catches it; the false consensus is certified as "best of N."

**(5) Verdict: SURVIVES (as engineering).** Keep the socket architecture. Kill its use as the
*justification* for a supremacy claim.

**(6) Replacement / repair.** Keep BO-31 verbatim as infrastructure. Sever it from
dominance-by-inclusion. Add (i) a **generator-diversity requirement** (distinct foundation
families, not just distinct vendors) and a **correlated-failure test** (do N proposers fail
together on adversarial inputs?); (ii) an explicit statement that for the *generative* (non-proof)
fragment there is **no trusted selector** — selection is heuristic and its output is defeasible,
never certified-best; (iii) a privilege-honest socket-population model (what actually runs for
privileged vs. public work).

---

## THE MANDATED PROBES — direct answers

**P-A. Does A1–A5 have a completeness proof or only a plausibility sweep?**
Only a plausibility sweep. The "derivational" defense asserts (does not prove) that survival
"decomposes exactly into" the five axes; the "empirical" defense is a search whose rubric can
only classify findings *into* the existing basis (`UPGRADE_TO_EXISTING_PILLAR`), making
discovery of an orthogonal axis structurally impossible — a tautological test. At least four
candidate orthogonal axes (generation, human-interface, temporal-liveness, forum-epistemics)
are visible without deep search. **No completeness proof exists; exhaustiveness is HYPOTHESIS.**

**P-B. Does formal assurance transfer to legal superiority?**
No — not on its own. Formal assurance (INV, answer-as-proof, tamper-evident memory) governs the
*derivation and record* layers over the *formalizable fragment*. Legal superiority is
overwhelmingly decided by (i) fact-finding and human confirmation (outside proof), (ii)
open-texture judgment/discretion (re-typed as defeasible, un-certified), (iii) ideation and
elicitation (Claim 6), (iv) persuasion and settlement dynamics (Claim 2, Φ), (v) timeliness
(Claim 5). Formal assurance is *necessary infrastructure and a real edge on the computational
spine*, but the transfer "proven-derivation ⇒ wins-the-matter" is invalid. The canon's honest
limits concede pieces of this; its headline supremacy language does not.

**P-C. Do one-shot procedural consequences, irreversible acts, and judicial discretion break
"absorption" and "born won"?**
Yes, all three.
- *One-shot consequences* break one-round absorption: the harm completes in-round (interim
  relief, live-hearing surprise, last-instance novelty) with no "next round" for *this* client
  (Claim 7).
- *Irreversible acts* break Φ (value realized at commission, not post-challenge, Claim 2) and
  cap "born won" (the frozen-world safety game is reopened by supervening acts and future law,
  Claim 8).
- *Judicial discretion* breaks both: it is the A9 forum-epistemics axis the basis omits; a
  discretionary ruling (abuse-of-right, proportionality, admissibility) can defeat a formally
  dominant line and can void an over-engineered "born won" clause (GCC 281).

**P-D. Is K a god-kernel?** Yes. The canon assigns K (and "K's side") at least 15 heterogeneous
responsibilities spanning six distinct trust foundations (recompute-verification, proof-checking,
type-checking, cryptographic write/quorum, game-theoretic fixpoint checking, and non-decidable
DLP/privilege publication review). It **must be split** (Claim 9 §6) into: K-adm (the true tiny
kernel), K-src, K-prf (per proof system), K-typ, K-write, K-precl, plus *separate gateways* that
must NOT be in K — G-pub (Publication Gateway: human, non-decidable, mandated separate and
fail-closed by the brief), G-inf (inference boundary, already separate), G-sev (upgrade ceremony).
Bundling publication review into a "total, decidable, deterministic" kernel is both impossible
(it is non-decidable and human) and a violation of the required separate Publication Gateway.

**P-E. Does a single "only truth" world represent conflicting authorities, competing
interpretations, alternative factual worlds, procedural uncertainty?**
No, no, no, and no (Claim 10). A `norm → single meaning at t` store cannot hold equal-rank
authority splits, plural admissible construals of one norm, mutually inconsistent factual
world-theories pleaded in the alternative, or *contested* (vs. derived) procedural states. L2
must be re-seated as a **labelled multi-world authority store** with first-class conflict
objects, named alternative fact-worlds, and a *disputed* type for contested procedure.

**P-F. Is the enterprise security story complete?**
No. Present and good: injection resistance (structural, P1), no-egress organ sandboxes, source-
poisoning resistance (recompute-from-source), inference-boundary gateway with per-data-class
posture, HSM key custody, tamper-evident memory. **Missing or under-specified:**
- *Matter isolation / ethical walls:* the canon has a **cross-matter consistency guard (BO-36)
  that deliberately reads *across* all live matters** — this is in direct tension with the
  ethical-wall/Chinese-wall duty (a lawyer screened from matter B must not have B's positions
  surfaced via A). There is **no matter-level access-control or need-to-know model**; "one world,
  read whole world" (02 §1) is the *opposite* of matter isolation. BLOCKING.
- *Insider threat:* single-writer + witness quorum protects the *log's integrity*, not against a
  *privileged insider* (a partner) exfiltrating or mis-using client data; no separation-of-duties,
  no per-matter authorization, no audit of *reads* is specified.
- *Publication control:* the brief mandates a *separate fail-closed Publication Gateway* (privilege
  review, DLP, redaction, authority validation, human approval, immutable receipt). The canon's
  wall is only *structural read-restriction* to the ELI partition (04 §1) — it has **no DLP, no
  privilege-review step, no human approval gate** on what gets published. "Public = codified
  statutes only" assumes the partition boundary is the whole control; it is not (a codified
  statute annotated with firm strategy, or a mis-partitioned object, needs DLP + human review).
  BLOCKING.
- *Multi-tenancy of confidentiality within the firm:* GDPR erasure is addressed (BO-25) but
  purpose-limitation and access-logging across the firm's own staff are not.

---

## BLOCKING CONTRADICTIONS (unresolved; must not be closed by wording)

**BLOCK-1 — Cross-matter guard vs. ethical walls.** BO-36 (firm-wide position registry,
deterministic contradiction scan across live matters) and the "one world, read whole world"
epistemics structurally *defeat* the ethical-wall/screening duty and matter-level
confidentiality. Either matters are isolated (walls) or the firm reasons across them (guard) —
the canon wants both without a reconciling access-control architecture. Resolution requires a
first-class **matter-authorization + screening model** with *typed* cross-matter checks that
run *without disclosing* the screened matter's content (e.g., conflict/contradiction detection
over commitments the walled attorney is *entitled* to see, or via a neutral compliance seat).
Until designed, BLOCKING.

**BLOCK-2 — Publication Gateway.** The binding brief mandates a *separate fail-closed
Publication Gateway* with human approval and DLP; the canon replaces it with a mere structural
read-partition and folds "issuance" into K. This both under-delivers the mandated control and
overloads K with a non-decidable, human-in-the-loop function. Resolution: extract **G-pub** as a
separate pipeline per Claim 9 §6. Until designed, BLOCKING.

**BLOCK-3 — Supremacy-language vs. status ladder.** The status ladder (07 §1) forbids claiming
above the current rung, yet 01–02 deploy "greatest element," "supremacy proof," "whole
move-space," "the only truth," "born won," and "dominance by inclusion" at DESIGN status. Under
the canon's own INV, uttering an over-scoped completeness/supremacy claim is an INV violation.
These phrasings must be demoted to their C-relative / per-axis / weak forms (Claims 4,5,6,7,8,10)
or the canon violates itself at the headline level. Until reconciled, BLOCKING.

---

## WHAT SURVIVES INTACT (so the autopsy is not read as nihilism)

- **INV as a derivation-layer invariant** (with a premise-trust ledger, Claim 1).
- **Axiom Υ** (applied symmetrically, Claim 3).
- **Per-axis dominance of the five safety poles** as *reasons to adopt the pillars* (not as a
  supremacy theorem, Claim 4).
- **Answer-as-proof over the formalizable fragment** with independent reproduction (Claim 11).
- **Preclusion-maximizing drafting with a client-non-self-binding proof** (Claim 8) — a real
  novel edge.
- **The SEV *governance* model** (labor autonomous, authority heteronomous, no self-merge) —
  keep verbatim (Claim 13).
- **The socket architecture as engineering** (Claim 14).
- **The four-valued answer discipline and the coverage stamp** — genuinely above the floor.
- **The status ladder and the honest-limits section** — the best parts of the package; the fix
  is to make the headline claims *obey* them.

The design is a strong assurance-and-record substrate mislabeled as a supremacy theorem. Strip
the theorem language, split K, make L2 multi-world, extract the Publication Gateway, resolve the
ethical-wall contradiction, re-scope backtesting to calibration, and demote dominance-by-inclusion
to generator-superset — and what remains is defensible, honest, and genuinely strong on the
computational spine, while telling the truth about the (large) fragment where legal victory is
actually decided.
