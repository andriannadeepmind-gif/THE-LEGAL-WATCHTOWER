# BEAT THE CANON — Adversarial Litigation-Strategy Report against LAWMAX-Ω

**Author role:** Adversarial legal-strategy team (litigators + systems architects) tasked to design the system/strategy that beats a firm running the LAWMAX-Ω canon in real Greek/EU litigation.
**Target read:** `LAWMAX-OMEGA-CANON/{00-MISSION,01-INVARIANT,02-ARCHITECTURE,06-TRANSITION}.md`.
**Discipline:** every substantive claim carries exactly one status tag — THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN. Nothing here is IMPLEMENTED/DEMONSTRATED/EMPIRICAL by us; the incumbent's own artifacts are the only IMPLEMENTED claims and we do not inspect their code, only the canon. Litigation-efficacy predictions are HYPOTHESIS; readings of what the architecture structurally can/cannot do are DESIGN-ENTAILED against the canon text.

**Ethics/legality boundary (binding on the counter-system we design).** The brief demands *maximum lawful, ethical, technically feasible* superiority, no fabrication. We therefore split every attack into (i) **lawful advocacy plays** the counter-system may adopt, and (ii) **unlawful/unethical plays** (witness tampering, ex parte judicial influence, fabricated evidence) that a real rich opponent *will* use and that the incumbent must survive, but that our counter-system may **not** adopt. Confusing the two would be the report's biggest error, so it is made explicit at each exploit. A central finding is that the incumbent's radical honesty exceeds the *ethical floor* of Greek advocacy (Κώδικας Δικηγόρων) and thereby self-handicaps against a merely-normal ethical advocate — that gap is lawful to exploit.

---

## PART 0 — The incumbent in one paragraph, and the shape of the attack

LAWMAX-Ω is a **proof machine for the game it models**: a turn-based, disclosure-bound contest resolved over a single verified legal world, where law-as-computation is subsumed under machine-checked certificates, the opponent's *legal* move-space is exhaustively enumerated and pre-countered, completeness is honestly coverage-stamped, and every trusted emission is gated by a human and a certificate. **Inside that model it is, on the computational-law axis, genuinely unbeatable** (DESIGN-ENTAILED, and we concede it — see Part 5). Therefore the entire attack is a single meta-move: **force the fight out of the game it models** — into (a) one-shot procedural time where precompute-then-navigate has no next round, (b) the human-discretion / free-evaluation-of-evidence terrain where proofs do not decide, (c) the survivable-but-unproven region its honesty leaves on UNKNOWN, (d) the off-record / cross-forum / attrition game its model does not contain, and (e) the human-confirmation bottleneck its invariant makes mandatory. The incumbent's own coverage stamp is the map that tells the attacker where these regions are.

### The five load-bearing assumptions we attack

| # | Assumption (canon locus) | Status in real GR/EU litigation |
|---|---|---|
| LA-1 | **Precompute, then navigate**: everything certifiable is certified before the live session; live = lookup; a novel move is flagged NOVEL and queued for "recess/next procedural round" (§7, one-round absorption, 00-MISSION). | FALSE at one-shot moments (ασφαλιστικά μέτρα, προσωρινή διαταγή, on-the-spot objections, appeal-deadline forfeitures). No next round exists there. |
| LA-2 | **Single verified world = "the only truth"**; case law as *precedential constraint* (Horty forcing); priors "order, never prune/decide" (L2; P4 invariance guard). | Greek courts have **no binding precedent** for lower courts and **free evaluation of evidence** (ΚΠολΔ 340). The decider is a discretion-laden human, not a proof-adopter. |
| LA-3 | **Coverage-stamp / four-valued honesty**: architecturally incapable of unstamped completeness or unjustified trusted claim; answers UNKNOWN honestly (INV; §4). | Publishes the firm's confidence topology to any opponent who reads its filings; forbids calibrated aggression that normal lawful advocacy permits. |
| LA-4 | **Human in every trusted loop**: critical facts need human confirmation; creator «εγκρίνω» gates phases/merges/SEV; "the lawyer speaks" (00-MISSION honest limits; P1; BO-33). | A small, fixed, saturable resource. Fronts-per-human is the binding constraint, and the rich opponent has more humans. |
| LA-5 | **Turn-based game with mandatory disclosure** — "to use an idea the opponent must reveal it" is the explicit basis of the one-round absorption guarantee (00-MISSION). | Greek civil procedure has **weak discovery**; ambush is *more* available. Settlement, attrition, cross-forum pressure, bench selection, and psychology happen **off the record, out of turn**. |

An important honest correction that sharpens (not weakens) the attack: the 2015/2021 Greek **νέα τακτική** reform front-loaded ordinary civil procedure into a **written, document-based, deadline-bounded** contest (προτάσεις + all evidence within 100 days / 130 for foreign-domiciled; προσθήκη-αντίκρουση within 15 days; file then closes; witnesses mostly replaced by pre-prepared ένορκες βεβαιώσεις). This terrain **plays to the incumbent's strengths** — it is exactly the computable, turn-based, disclosure-forced game the canon models. **Conclusion (DESIGN-ENTAILED + HYPOTHESIS): do not fight the incumbent on the ordinary-track merits.** Every exploit below deliberately relocates the contest to interim/urgent proceedings, admissibility, the discretion axis, tempo/appeals, and the off-record game.

---

## PART 1 — THE ATTACK PLAYBOOK

Each exploit: **the move → why the architecture fails structurally → status → lawful/unlawful split**.

### EXPLOIT 1 — One-shot procedural traps defeat precompute-then-navigate (the tempo kill)

**Move.** Relocate the decisive contest to **ασφαλιστικά μέτρα (interim measures)** and **προσωρινή διαταγή (temporary restraining order)**: oral, fast, discretion-heavy, quasi-final in practical effect (a προσωρινή διαταγή can freeze/authorize action for months; an interim-measures ruling often decides the commercial reality before the ordinary trial ever matters). Introduce the case-deciding characterization or document **inside** that hearing, at the last admissible instant. Similarly weaponize **διαταγή πληρωμής** (ex parte payment order) and the finite **ανακοπή** opposition deadline, and every **on-the-spot objection** whose non-raising is instant preclusion.

**Why the architecture fails structurally (DESIGN-ENTAILED).** §7 is explicit: live support is "lookup + flagging," and "a genuinely novel move is flagged honestly as NOVEL … and queued for the recess/next procedural round — the one-round absorption law at zero navigation latency." The **one-round absorption guarantee presupposes a next round exists and matters** (00-MISSION §"one un-closable residue"). At a προσωρινή διαταγή hearing there is no next round for *that* ruling; by the time the ordinary trial arrives, the harm is done or the leverage is spent. The incumbent's honest "NOVEL — queued" is, at a one-shot node, **operationally identical to conceding the point**. The canon has no primitive for *fresh certification at speech latency*; it deliberately forbids it ("live settings cannot run heavyweight certification"). So the attacker's dominant move is to maximize the density of genuinely-novel state at precisely the nodes with no recess.

**Lawful.** Yes — timing your strongest lawful evidence/characterization for interim proceedings is ordinary tactics. **Amplifier (unlawful, incumbent-must-survive):** deliberate ambush by surprise-fabricated documents is illegal and out of scope for the counter.

---

### EXPLOIT 2 — Fight on free evaluation of evidence and discretion, where proofs do not decide (the single-world kill)

**Move.** Keep every dispositive question on the **facts and the open-textured standards** decided in the ουσία (merits) courts under **free evaluation of evidence (ΚΠολΔ 340)** and under καλή πίστη / χρηστά ήθη / αναλογικότητα / καταχρηστική άσκηση δικαιώματος (ΑΚ 281). Avoid pure questions of law (where αναίρεση before the Άρειος Πάγος rewards the incumbent's certified correctness). Win the case on **credibility, equity, and narrative** — axes the judge resolves by discretion, not by subsumption.

**Why the architecture fails structurally (DESIGN-ENTAILED).** The canon's L2 is "the only truth" and case law enters as *precedential constraint* (Horty factor-forcing). But **Greek lower courts are not bound by precedent**, and the finder of fact enjoys free evaluation. The incumbent's most valuable output — a machine-checked subsumption certificate — has *no privileged force* over a judge exercising discretion; it is one persuasive artifact among many, and the canon's own P4 invariance guard forbids the judge-model from *deciding* strategy ("empirical priors … may order search, never prune"). So the incumbent structurally **refuses to optimize for the specific human decider**, precisely where the specific human decides everything. Worse (Exploit 4 below), P3 forbids "stylistically softening" open-texture nodes and bars any LLM between certification and emission — so on the exact axis where persuasion wins, the incumbent has **disarmed its persuasive register by design**.

**Lawful.** Fully — narrative and equity advocacy is the core of the trial lawyer's craft.

---

### EXPLOIT 3 — Steer into UNKNOWN: the coverage stamp is a targeting map (the honesty-topology kill)

**Move.** Read the firm's filings and outputs; the four-valued discipline means it files confidently only where **PROVED**, and hedges or goes silent where **UNKNOWN / STABLE-UNDER-UNKNOWN**. This **publishes the firm's confidence topology**. Map it, then relocate the whole dispute into its UNKNOWN regions: novel characterizations not in its precomputed Qualifikation lattice; **thin reference classes** (which the anti-gerrymandering guard, BO-29, *forces* to honest UNKNOWN); open-textured multi-factor balances with no clean authority; freshly-changed law not yet ingested.

**Why the architecture fails structurally (DESIGN-ENTAILED).** By Axiom Υ and the INV, the system is *architecturally incapable* of an unstamped completeness claim and refuses rather than guesses. Its honesty is not a policy but a structural property — it **cannot suppress the signal**. The anti-gerrymandering guard *guarantees* that thin classes yield UNKNOWN, so the attacker can reliably manufacture UNKNOWNs by choosing sufficiently specific/novel fact-patterns. The one-round absorption "closes the gap after first use" — so the counter's rule is: **use each novel weapon exactly once per matter, in matters that end (one-shot) before absorption pays off**, and never reuse a weapon the firm has already ingested.

**Lawful.** Yes — choosing the terrain of novelty is legitimate.

---

### EXPLOIT 4 — The honesty tax: confident-but-unproven assertion beats honest hedging on the discretion axis (the INV kill)

**Move.** On every genuinely-arguable open-textured point, **assert confidently as settled** (lawful: the point is arguable, the client attests the facts, and no rule requires a lawyer to volunteer their own uncertainty). Force the incumbent to answer an assertion-of-certainty with a **"defeasible argument with explicit, contestable assumptions."** To a time-pressed judge on a discretionary call, the confident frame reads as strength and the honestly-hedged one reads as concession.

**Why the architecture fails structurally (DESIGN-ENTAILED — this is the deepest fault).** INV: the system is "architecturally **incapable** of emitting an unjustified trusted claim"; §4's four-valued discipline makes "confident guessing … unrepresentable"; P3 forbids stylistic softening of open-texture and bars any LLM between certification and emission. The incumbent **conflates two distinct things**: *trusted internal belief* (which SHOULD be justified) and *advocacy assertion* (which lawfully may exceed what one can prove, so long as it is arguable and non-fabricated). Because everything the firm emits is routed through K with a certificate, it has **no primitive for calibrated aggression under uncertainty** — the ordinary advocate's staple of asserting an arguable position at full confidence and making the opponent spend to rebut it. The incumbent bets on Axiom Φ ("value is measured after challenge; unsurvivable claims have value ≤ 0"). **The counter attacks the idealization in Φ:** in real forums many confident-but-unproven assertions go *unrebutted* (opponent misses it, runs out of time, or the judge adopts it), so their **realized** forum payoff is positive, not ≤ 0. Φ treats challenge as certain and perfect; it is neither. This is the single most important structural gap: it is not a bug to patch but a consequence of the root invariant, and closing it would require abandoning INV (Part 4).

**Lawful — and this is the crux.** Asserting arguable positions at full confidence, declining to volunteer weaknesses, and burden-shifting are **standard, ethical Greek advocacy**. The incumbent's radical honesty is *above* the ethical floor; the counter operates *at* the floor and thereby dominates on the discretion axis without any fabrication.

---

### EXPLOIT 5 — Saturate the human confirmation / approval bottleneck (the throughput kill)

**Move.** Open more simultaneous lawful fronts than the firm's humans can service: colliding hearing dates, parallel motions across related matters, a lawful **document avalanche (καταιγισμός εγγράφων)** where every load-bearing fact requires human confirmation, and phase/merge approvals timed to collide. The rich opponent's structural advantage — **more human litigators** — is aimed exactly at the incumbent's binding constraint.

**Why the architecture fails structurally (DESIGN-ENTAILED).** The canon puts a human in every trusted loop *by design and by invariant*: "critical facts require human confirmation" (00-MISSION honest limits); the trusted path's throughput is gated by human attention; creator «εγκρίνω» is mandatory for every phase, merge, and SEV admission (BO-33: "**heteronomous in authority**"); and live emission requires the lawyer to speak (§7). The machine's precompute can be superhuman, but **the trusted-emission rate is bounded by a small, fixed human pool.** This cannot be removed without violating A4/INV (silent self-modification re-admits the drift class), so the bottleneck is **structural, not operational** — mitigable (triage, pre-confirmed fact classes, more partners) but not eliminable. The mission's own beneficiary — the under-resourced firm/client — is the party *least* able to add humans, so the exploit hits the mission at its root.

**Lawful.** Multi-front litigation and voluminous (genuine) document production are lawful; **vexatious** filing is sanctionable and out of scope for the counter — but the line is wide, and the incumbent's fail-closed honesty makes it slow to counter-sanction (Exploit 8).

---

### EXPLOIT 6 — The off-record / attrition / psychological game the model does not contain (the LA-5 kill)

**Move.** Win without ever entering the game the incumbent models. Against the incumbent's typically **under-resourced client**, run **attrition**: maximize time-to-resolution and the client's emotional/financial cost until they settle or abandon a *winning* legal position. Layer **settlement game theory** (anchored offers timed to the client's cashflow crises), **reputational pressure**, and **cross-forum coordination** — a lawful parallel μήνυση (criminal complaint), a regulatory/tax referral, a related civil action — each raising the client's cost-to-continue without ever being a "turn" in the civil matter. Play the **who-decides** meta-game: lawful venue/section selection, εξαίρεση δικαστή (recusal challenges) to change the bench, interlocutory maneuvers to reset tempo.

**Why the architecture fails structurally (DESIGN-ENTAILED).** 00-MISSION rests the one-round absorption guarantee on the premise that "litigation is a turn-based game with mandatory disclosure." **Off-record attrition, settlement psychology, cross-forum pressure, and bench selection are none of those** — no turn, no disclosure, no mandatory response window. The canon has organs for hearings (BO-40), a client desk (BO-39), and preclusion (BO-27), but **no adversarial model of the opponent's off-record strategy against the firm's own client.** Its preventive "born-won" deployment helps ex ante and does nothing once the poor client is already in a war of attrition. **A machine that wins in four years is worthless to a client who is bankrupt in six months** — and the mission explicitly exists to protect exactly that client. This is the exploit that most directly negates the incumbent's stated purpose.

**Lawful vs. unlawful (critical split).** Lawful and counter-adoptable: legitimate settlement pressure, genuine parallel legal claims, time-value tactics, lawful recusal, forum selection. **Unlawful and NOT counter-adoptable (but incumbent-must-survive):** improper ex parte judicial contact, witness intimidation, fabricated parallel complaints filed in bad faith, media campaigns that defame. The counter-system models the *lawful* attrition game maximally; it names the unlawful game only as a threat surface the incumbent must harden against.

---

### EXPLOIT 7 — Weaponize fail-closed against the firm's own deadlines (the availability kill)

**Move.** Feed the firm sources, exhibits, and citations crafted to sit **exactly on the boundary of admissibility** — provenance that will not cleanly validate, citations the grammar-total FSM recognizer (BO-20) rejects, characterizations that cannot be coverage-certified in the available time. Time these against the firm's own hard deadlines.

**Why the architecture fails structurally (DESIGN-ENTAILED).** "Fail-closed everywhere: exception ⇒ refusal" (P1, K). Availability and deadline-compliance are **correctness requirements** (brief condition 5). An attacker who can reliably drive an organ or the gate into refusal at a deadline converts the incumbent's safety property into a **liveness denial-of-service**: the firm refuses to emit rather than emit-uncertainly, and misses the window. A normal advocate would file the best available argument under time pressure; the incumbent, structurally, may **refuse**. The canon's degraded/MANUAL modes preserve *truth*, "never … speed and autonomy" (§6) — but at a one-shot deadline, lost speed **is** lost correctness.

**Lawful.** Serving genuine-but-boundary-case material is lawful; deliberately fabricated malformed evidence is not (out of scope for counter).

---

### EXPLOIT 8 — Bait the cross-matter consistency guard into self-estoppel (the BO-36 kill)

**Move.** As an opponent (or a coordinating network of opponents) who can observe the firm across matters, **engineer positional conflicts**: induce the firm to assert predicate P in matter A, then structure matter B so that winning requires ¬P. Also exploit that fluent **alternative/arguendo pleading** ("even if X, then still Y") sits in tension with a hard consistency scanner.

**Why the architecture fails structurally (DESIGN-ENTAILED).** BO-36 is a "deterministic contradiction scan (same predicate asserted/denied across live matters …); **blocking flag** at strategy/drafting time." Intellectual consistency is honest, but litigation lawfully permits a firm to take **different positions for different clients on different facts**, and to plead in the alternative. A hard blocking guard converts a virtue into a **self-imposed estoppel** an opponent can trigger: the firm binds itself where an ordinary firm would not. The incumbent could tag positions with fact-context to distinguish them — but any residual hard-blocking behavior is baitable, and the *arguendo* register (assert A while also arguing "even if not-A") strains a system whose four-valued discipline wants a single truth-value per predicate.

**Lawful.** Fully — taking distinct client-specific and alternative positions is core advocacy.

---

### EXPLOIT 9 — Keep the fight on facts and discretion so αναίρεση (the incumbent's home turf) never arrives (the appellate-terrain kill)

**Move.** Because the **Άρειος Πάγος** reviews questions of **law** (αναίρεση), not fact, and the incumbent's certified-correctness edge is strongest there, deny it that terrain: settle, or lose/win on **factual and discretionary** grounds in the ουσία courts, so the case never becomes a clean legal question. Where an appeal is unavoidable, contest **admissibility and procedure** (απαράδεκτο, standing, deadlines) rather than merits — give a docket-pressured court an easy procedural off-ramp.

**Why the architecture fails structurally (DESIGN-ENTAILED).** The incumbent's supremacy is sharpest on computational law and machine-checkable submission ("if tribunals … consume machine-checkable submissions, answer-as-proof is that world's native format"). Today's tribunals do not, and the fact/discretion courts are where cases are actually decided. The exhaustive merits certificate is **worthless if the case is disposed on a procedural technicality** the incumbent's own honesty flagged as merely "arguable." The attacker maximizes procedural-disposition surface.

**Lawful.** Yes.

---

### EXPLOIT 10 — Novelty-once, then vanish: defeat one-round absorption by never giving a second use (the absorption kill)

**Move.** Treat every novel weapon as **single-use per opponent**. The one-round absorption law makes any revealed weapon the firm's permanent asset *after one use* — so never reuse. Rotate characterizations, theories, and reference-class-breaking fact patterns so the firm's ingested-memory advantage (P5) has nothing to compound. Concentrate novel weapons in **one-shot matters** (interim proceedings, payment orders, single-hearing disputes) that terminate before the absorbed counter can be deployed in a "next round" that never comes.

**Why the architecture fails structurally (DESIGN-ENTAILED).** The canon's compounding advantage — "the firm gets monotonically smarter and never forgets" (P5) — is **realized only across repeated exposure to the same weapon**. Against an opponent who never repeats and who fights in one-shot fora, the absorption asset is stranded. The guarantee is honestly stated as *one-round* — the attacker simply denies the round.

**Lawful.** Yes.

---

### EXPLOIT 11 — Injection of the *judge*, not the *system*: bias the human decider the model refuses to model

**Move.** The canon hardens against prompt injection of its *organs* (P1, no-egress, injection CI). But the real soft target is the **human judge**. Lawfully: frame the case to the judge's known disposition patterns, procedural-economy incentives, and equities. The incumbent's actor-keyed views *know* these patterns but are **forbidden from using them to decide or persuade** (invariance guard: order-only). The attacker faces no such rule and tunes the entire presentation to the specific bench.

**Why the architecture fails structurally (DESIGN-ENTAILED).** P4 invariance guard: "empirical priors (judge/opponent models) may order search, **never prune**"; the mutation-adversary test *proves* the decided output is **bit-for-bit invariant under any prior perturbation**. This is a deliberate anti-gaming property — and it means the incumbent's strategy is, by construction, **the same regardless of which judge hears it.** The attacker's strategy is the opposite: maximally judge-specific. On a discretion-decided call, judge-specific beats judge-invariant (HYPOTHESIS). The incumbent bought integrity/robustness at the price of the single most powerful lawful persuasion lever.

**Lawful vs. unlawful.** Tuning lawful argument to a judge's known jurisprudential leanings is legitimate; ex parte contact or improper influence is not (out of scope for counter; threat surface for incumbent).

---

## PART 2 — WHY THE ARCHITECTURE FAILS EACH, CONSOLIDATED

The exploits are not eleven accidents; they cluster into **four structural roots**, each a direct consequence of a canon commitment:

1. **Precompute-then-navigate has no fresh-certification-at-speed primitive** (§7, by explicit design). → Exploits 1, 7, 10. Any contest whose decisive act happens faster than heavyweight certification, at a node with no next round, is a region the incumbent enters honest-but-unarmed.

2. **Single verified world + prior-invariant decision** (L2; P4 invariance guard). → Exploits 2, 9, 11. The incumbent optimizes the *content* to perfection and **refuses to optimize for the specific human decider**, on terrain (free evaluation, discretion, no binding precedent) where the specific human decides.

3. **The INV honesty is structural, not tunable** (INV; §4; P3 de-rhetoricization). → Exploits 3, 4, 8. It cannot bluff, cannot suppress its confidence topology, cannot stylistically win an open-textured call, and can be baited into self-estoppel. Its honesty exceeds the ethical floor and thereby self-handicaps against a normal ethical advocate.

4. **Mandatory human authority + turn/disclosure premise** (P1, BO-33; LA-5). → Exploits 5, 6, 11. The human loop is a saturable bottleneck, and the entire off-record/attrition/cross-forum/psychological war is outside the modeled game — the region where the rich opponent actually breaks the poor client.

**Meta-observation (DESIGN-ENTAILED):** every root is a *deliberate* canon choice defended in `01-INVARIANT.md` as dominant under Axioms Φ and Υ. The attacks do not find the canon *inconsistent with its axioms* — they find that **Axioms Φ and Υ are idealizations of a forum that, in the real Greek/EU order, is only partly turn-based, only partly disclosure-forced, only partly a post-challenge meritocracy, and mostly decided by discretion-laden humans under time pressure.** The supremacy proof is valid **relative to its axioms**; the attack is on the **fit of the axioms to the real forum** — exactly the gap the canon's own "honest limits" section concedes but does not close.

---

## PART 3 — THE COUNTER-ARCHITECTURE (mechanisms, not slogans)

A system built to beat LAWMAX-Ω keeps everything the incumbent gets right on computational law (we do not out-prove a prover — Part 5) and adds **six organs the incumbent structurally lacks**. Status: this is a DESIGN; efficacy is HYPOTHESIS.

### CA-1 — Real-time fresh-certification engine (beats precompute-then-navigate)
Not "navigate a precomputed tree" but **bounded fresh reasoning at speech/hearing latency**. Mechanism: a tiered inference budget where interim-proceeding and on-the-spot windows get a **fast, lower-assurance but *live* certification path** (proof-search with anytime bounds, returning the best-justified answer *by the deadline* rather than refusing). Explicit **one-shot-node detector** over Greek procedure (ασφαλιστικά, προσωρινή διαταγή, διαταγή πληρωμής/ανακοπή deadlines, on-the-spot objection points) that switches the system from "queue for next round" to "must answer now, at whatever assurance the clock allows, and say so." Where the incumbent *refuses*, CA-1 *acts under a stated, calibrated confidence*.

### CA-2 — Judge/panel-conditioned decision policy (beats single-world, prior-invariant strategy)
A **Bayesian model of the specific decider** — realized dispositions, discretion patterns, procedural-economy tendencies, credibility-weighting habits — used not merely to *order search* but to **select strategy and shape presentation** to maximize P(win | this bench, this framing, this tempo). Deliberately **prior-driven**, the exact inverse of the incumbent's prior-invariant guard. Trades the incumbent's anti-gaming robustness for maximal judge-specific persuasion.

### CA-3 — Calibrated-aggression advocacy layer (beats the honesty tax)
Two separated registers: an **internal-belief layer** (calibrated, honest, never fabricating) and an **advocacy-output layer** that optimizes *forum payoff* = expected value over the opponent's realized rebuttal probability and the judge's adoption probability. On arguable open-textured points where P(unrebutted ∨ adopted) is high, it **asserts at full confidence** — lawful, non-fabricating, and exactly what a normal elite advocate does. It mines the entire **survivable-but-unproven** region the incumbent leaves on UNKNOWN. Hard ethical rail: never assert known falsehood, never cite non-existent authority — but *never volunteer* one's own uncertainty either.

### CA-4 — The off-record / attrition / cross-forum organ (beats LA-5; the "dark game" engine, lawful subset)
Explicit adversarial models of: **opponent-and-client psychology and risk/cashflow profiles**; a **settlement game-theory engine** (optimal offer timing against the opponent's cost-to-continue and our client's break point); a **cross-forum coordination planner** (lawful parallel criminal/regulatory/civil pressure, timed); a **who-decides meta-game module** (lawful venue/section/recusal tactics, bench-composition modeling); and — mission-critically — a **time-to-relief objective** that treats the client's survival horizon as a first-class constraint, so the system optimizes *fast enough relief*, not *eventual perfect victory*. This is the organ the incumbent most conspicuously lacks and the one that most directly protects the poor client.

### CA-5 — Throughput/multi-front resilience with reduced human criticality (beats the bottleneck)
Where the incumbent puts a human in every trusted loop, CA-5 **pre-authorizes fact-classes and low-stakes emissions** under standing policy (human sets the policy once; machine acts within it), reserving human confirmation for genuinely load-bearing/high-stakes nodes. It **absorbs multi-front load** by parallelizing the *un*-gated work and triaging the gated work by deadline-criticality. (This is the counter's most ethically/architecturally delicate move — it deliberately relaxes the incumbent's A4 discipline in exchange for throughput; see Part 4.)

### CA-6 — Coverage/confidence concealment + opponent-topology mapper (beats the honesty-signal leak)
Inversely to the incumbent, CA-6 **does not publish its confidence topology**: internal UNKNOWNs are not signaled in filings; the advocacy layer (CA-3) presents a uniform confident surface. Simultaneously it runs the **incumbent-mapping** the incumbent cannot stop leaking: read the LAWMAX firm's filings, infer its coverage boundary and UNKNOWN regions, and steer the dispute there. Asymmetry: the counter reads the incumbent's honesty; the incumbent cannot read the counter's (concealed) topology.

---

## PART 4 — ABSORBABLE vs. FUNDAMENTALLY CONTRADICTORY

The decisive analytic question: **which counter-organs can the incumbent bolt on without breaking INV, and which require abandoning it?** (DESIGN-ENTAILED against the canon's own stated invariants.)

### Absorbable — the incumbent SHOULD add these; they are gaps, not contradictions

- **CA-4 (off-record/attrition/cross-forum organ).** Fully absorbable as new **untrusted L3 faculties + new P5 indices**. Nothing in INV forbids *modeling* the off-record game; these are proposals, not trusted emissions. The incumbent's socket architecture (§8, BO-31) is built to accept exactly this. **This is the incumbent's most important missing organ and its absence is a design defect, not a principled choice** — and its own mission (protect the poor client from a rich attritional opponent) *demands* it. The **time-to-relief objective** is likewise absorbable and arguably mandatory: it is a new optimization constraint, not a violation of any invariant.
- **CA-2 for persuasion-targeting and search — but NOT for decision.** The incumbent already has actor-keyed judge views "feeding search ordering only." Extending them to **persuasion targeting** (how to frame, not what is true) is absorbable as an L3 organ. **But using priors to *decide/prune* strategy contradicts the P4 invariance guard** and is un-absorbable (see below).
- **CA-1's one-shot-node detector.** Absorbable: a new organ that classifies procedural windows and flags irreversibility is compatible with — indeed close to — the BO-27 preclusion engine. The incumbent can *know* it is at a one-shot node. What it cannot do while honoring §7 is *certify fresh at speed* (see below).
- **CA-5's policy-pre-authorization, partially.** The incumbent can pre-confirm *fact-classes* and add human capacity operationally. This **mitigates** the bottleneck but cannot **eliminate** it without touching A4.
- **CA-6's opponent-mapping (the reading half).** Absorbable — an intelligence organ that maps opponents is a normal L3 faculty. The **concealment half** is not (below).

### Fundamentally contradictory — cannot be absorbed without abandoning the root invariant

- **CA-3 (calibrated-aggression advocacy) directly violates INV.** The invariant makes the system "architecturally **incapable** of emitting an unjustified trusted claim," and §4 makes "confident guessing … unrepresentable." An output layer that asserts survivable-but-unproven positions at full confidence is **the exact failure class INV was built to make unrepresentable.** The incumbent can present these only as defeasible arguments with flagged assumptions — which *is* the honesty tax. **To absorb CA-3, the incumbent would have to separate advocacy-assertion from trusted-claim and let the former exceed the latter — dissolving the single-gate discipline that is its whole identity.** This is the irreducible fault line. *(Honest counter-caveat: the incumbent's designers would argue Axiom Φ makes CA-3 self-defeating over a long book of matters — sanctions and credibility loss eventually dominate. Whether Φ or CA-3 wins is EMPIRICAL and UNKNOWN; it turns on how often real challenge is imperfect. Neither side may claim it as proven.)*

- **CA-2-for-decision violates the P4 invariance guard.** The canon *proves* (via the mutation-adversary test) that the decided output is bit-for-bit invariant under prior perturbation — a deliberate anti-gaming, anti-bias property. A judge-conditioned *decision* policy is prior-*driven* by construction. **The two are logical negations; you cannot have both.** The incumbent trades away maximal judge-specific persuasion to buy integrity/reproducibility; the counter trades the reverse.

- **CA-1's fresh-certification-at-speed contradicts §7's founding principle** ("everything certifiable is certified BEFORE the live session; live settings cannot run heavyweight certification"). The incumbent could add a *fast lower-assurance* path only by admitting a **second, weaker trust tier that emits under time pressure without full certification** — which reintroduces the "unjustified trusted claim under a deadline" class INV forbids. Detecting the one-shot node is absorbable; *acting* at it under sub-certified confidence is not.

- **CA-5's reduced human criticality contradicts A4 / BO-33 heteronomy.** "Autopoietic in labor, heteronomous in authority" and "silent self-modification re-admits the silent-drift failure class" make the human seal mandatory for trusted emission. Pre-authorizing machine emission within a standing policy is exactly the **silent-drift-adjacent** move A4 exists to forbid. Absorbable for *labor* throughput; **un-absorbable for the authority seal.** The bottleneck is therefore reducible but has a hard floor the incumbent cannot cross while remaining itself.

- **CA-6's concealment contradicts INV honesty.** The incumbent *cannot* conceal its confidence topology because its outputs are structurally honest (coverage stamps, four-valued discipline, un-softened open-texture flags). Concealment is the negation of its defining property.

### The partition, stated as the fault line

**Absorbable = everything about *modeling more of the world* (off-record game, judge patterns, procedural tempo, opponent mapping, time-to-relief).** The incumbent's socket architecture is genuinely extensible and these are real, fixable gaps — its designers should treat CA-4 especially as a mandatory addition.

**Contradictory = everything about *emitting differently than the truth it can justify* (bluffing, prior-driven decision, sub-certified speed, machine-sealed authority, concealment).** These are not gaps; they are the **exact negations of INV, A4, and the P4 invariance guard.** A system that adopts them **is not a better LAWMAX-Ω — it is a different animal** that has traded the incumbent's guarantees (no unjustified trusted claim, prior-invariant integrity, bit-for-bit reproducibility, human-sealed authority) for forum-payoff aggression, judge-specificity, speed, and throughput.

**The choice between them is not resolvable by proof.** It is the empirical bet at the center of the whole design: **does the real Greek/EU forum reward the honest prover or the calibrated aggressor?** The incumbent bets on Axiom Φ (challenge is real and eventually punishes the aggressor). The counter bets Φ is an idealization (challenge is imperfect, the poor client dies of attrition first, and discretion rewards the confident frame). That bet is **EMPIRICAL and currently UNKNOWN** — and, per the canon's own `07-VERIFICATION.md` honesty, neither side may assert victory before the backtesting/reproduction regime rules on it.

---

## PART 5 — WHAT THE ATTACK CANNOT BEAT (honest concessions; no oversell)

Claim-status discipline forbids overclaiming the attack. The following are terrains where the incumbent is genuinely dominant and the counter must *avoid*, not engage (DESIGN-ENTAILED):

1. **Pure computational law** — deadlines, thresholds, amounts, elements of a claim, procedural-step correctness. Machine-checked subsumption over verified law is unbeatable here; no aggressor out-argues a correct proof of a deadline. **Do not litigate the counter's case on computational law.**
2. **αναίρεση / clean questions of law** before the Άρειος Πάγος — the incumbent's home turf. The counter must keep cases off it (Exploit 9).
3. **The front-loaded ordinary track (νέα τακτική) on the merits** — written, document-based, deadline-bounded, disclosure-forced: the exact game the canon models. The counter must relocate to interim/urgent/discretionary/off-record terrain.
4. **Source poisoning and system-level injection** — genuinely hardened (P1/K recompute-and-seal; no-egress organs; injection CI). The counter's system-level attacks fail; only the *human judge* and the *human bottleneck* remain soft.
5. **One-round absorption when the round exists** — against a *repeat* opponent in *multi-round* proceedings, the incumbent compounds and the counter's novelty-once strategy degrades. The counter's edge requires one-shot fora and non-repetition (Exploit 10).

The attack is therefore **not** "LAWMAX-Ω is weak." It is: **LAWMAX-Ω is supreme inside a strict sub-game and structurally blind to the larger, messier, human, off-record, time-pressured, discretion-decided game that is most of real Greek/EU litigation — and its defining honesty, while ethically admirable, is a lawful-to-exploit handicap on the discretion axis.** The winning counter does not beat it at its own game; it refuses to play that game.

---

## Appendix — Claim-status ledger (selected load-bearing claims)

- "Incumbent is unbeatable on computational law" — **DESIGN-ENTAILED** (from P2/P3 + machine-checking).
- "Greek lower courts have no binding precedent; free evaluation of evidence (ΚΠολΔ 340)" — **THEOREM-of-law / EMPIRICAL-legal** (settled Greek doctrine; stated as background, not our invention).
- "νέα τακτική front-loads ordinary procedure into a written, deadline-bounded contest" — **EMPIRICAL-legal** (2015/2021 ΚΠολΔ reforms).
- "One-shot nodes defeat precompute-then-navigate" — **DESIGN-ENTAILED** (from §7 text) as to the *architectural gap*; **HYPOTHESIS** as to *winning real cases*.
- "Calibrated aggression yields positive realized forum payoff" — **HYPOTHESIS / EMPIRICAL-UNKNOWN** (the central contested bet; not proven by either side).
- "CA-3, CA-2-decision, CA-1-speed, CA-5-authority, CA-6-concealment contradict INV/A4/invariance-guard" — **DESIGN-ENTAILED** (logical negation of stated invariants).
- "CA-4 off-record organ is absorbable and mission-mandatory" — **DESIGN-ENTAILED** (absorbability, from §8 socket extensibility) + **HYPOTHESIS** (mission-criticality).
- "The honest-prover-vs-calibrated-aggressor question is resolvable only empirically" — **DESIGN-ENTAILED** (it turns on the fit of Axiom Φ to the real forum, which is an empirical, not a logical, matter).
