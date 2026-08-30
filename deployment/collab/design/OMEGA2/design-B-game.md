# Design B — The Adversarial Game

**Architecture Team B (first principles).** Entry point: *what actually wins real litigation against elite opponents?* — derive the architecture backwards from victory conditions.

**Scope discipline.** Exclusive internal system for a Greek law practice (EU/ECHR law inside the Greek order). Strictly private matters/strategies/traces; only final outputs may ever go public, through a separate fail-closed Publication Gateway. Cost/time/compute/staffing are not constraints. Deadlines, latency, availability, reliability ARE correctness requirements. No fabrication.

**Claim-status legend.** Every substantive claim carries exactly one tag:
`THEOREM` (proved in a stated formal system) · `DESIGN-ENTAILED` (follows from a design decision if built as specified) · `IMPLEMENTED` (code exists) · `DEMONSTRATED` (shown to work on a case) · `EMPIRICAL` (measured over data) · `HYPOTHESIS` (plausible, untested) · `UNKNOWN`.

In this document almost everything is `DESIGN-ENTAILED` or `HYPOTHESIS`: no code is built. I mark exceptions. I never equate proof-checking with correctness of the natural-language formalization, nor model access with idea inclusion.

---

## Part 0 — The wrong way to start, and why we reject it

The tempting starting point is: "build a very strong legal reasoning engine, then apply it to cases." That is the *knowledge-first* frame. It is presumptively wrong for this problem, for a reason that is decision-theoretic, not technical:

> **Litigation is not a knowledge-maximization game. It is an adversarial game with hidden information, asymmetric stakes, hard deadlines, irreversible moves, one-shot events, and a human decision-maker (the judge) whose discretion is not a computable function of the law.** `DESIGN-ENTAILED`

A system optimized to *know the law best* can still lose to an opponent who knows less law but plays the game better: files first, frames the issue, controls the record, forces the deadline, picks the forum, settles at the right number, or simply avoids the one move that hands the other side an irreversible advantage. Therefore the architecture must be derived from **victory conditions**, and legal knowledge is a subordinate resource that those conditions consume.

This does not mean knowledge is unimportant. It means knowledge is necessary and radically insufficient, and an architecture that treats "better answers" as the top-level objective is optimizing the wrong quantity. `HYPOTHESIS` (strong, but a claim about what wins, not a theorem).

---

## Part 1 — Victory conditions: what actually wins

I decompose "winning" into the levers that decide real cases, and for each I state **where computation genuinely helps** and **where it structurally cannot**. This table is the load-bearing part of the whole design; everything downstream is built to serve it.

### 1.1 The eight levers

**L1 — Information asymmetry.** Cases are won by knowing something the opponent does not, or by knowing that the opponent knows something and preparing for it. This includes the factual record, the opponent's likely theory, the judge's known tendencies, and the gaps in one's own case.
- *Computation helps* (strong): exhaustive record ingestion; cross-document contradiction detection; timeline reconstruction; "what does each document prove / disprove / leave open" mapping; adversary-model enumeration ("if I were them, what would I do with document X"). `HYPOTHESIS`
- *Computation cannot* (structural): it cannot obtain information the firm does not lawfully have. No scraping of opponent privilege, no illicit intelligence. The asymmetry the system can create is *analytical depth over the same evidence*, not illicit access. This is a hard ethical boundary, not a capability gap to be closed later. `DESIGN-ENTAILED`

**L2 — Timing and deadlines.** A missed προθεσμία (procedural deadline) loses cases that were otherwise won. Filing first can seize framing, forum, and burden. Delay can be a weapon or a trap.
- *Computation helps* (very strong, and this is arguably the single highest-value, lowest-open-texture function): deadline computation from procedural events under the Greek Code of Civil Procedure (ΚΠολΔ), administrative and penal timelines, ECHR six-month/four-month rules, service/notification rules, holiday and court-recess calendars; monotone countdowns; escalation. This is *computational law* in the strict sense — a mostly-decidable calculation over dated events and statutory intervals. `DESIGN-ENTAILED` (that it is computable), `HYPOTHESIS` (that a given corpus encodes every rule correctly).
- *Computation cannot*: it cannot decide *whether to use* time as a weapon — that is strategy under the lawyer's authority. And it must never *silently* assume a deadline; an unmodeled procedural rule is an honest "UNKNOWN," never a guess. `DESIGN-ENTAILED`

**L3 — Irreversible moves.** Some moves cannot be unwound: admissions, waivers, elections of remedy, disclosed positions, consented jurisdiction, filed pleadings that fix the cause of action (αντικείμενο της δίκης). The cost of error is asymmetric — a reversible mistake is cheap, an irreversible one can be terminal.
- *Computation helps*: classify every candidate move by reversibility; force a higher evidentiary/deliberative bar before irreversible moves; simulate downstream consequences; maintain a "point of no return" ledger. `DESIGN-ENTAILED`
- *Computation cannot*: it cannot bear the responsibility for an irreversible move. Irreversible moves are **human-authority points** by construction (Part 10). `DESIGN-ENTAILED`

**L4 — One-shot events.** Cross-examination, the hearing (συζήτηση), oral argument before a bench, a settlement window that closes. No replay. Preparation quality dominates because there is no second attempt.
- *Computation helps*: exhaustive preparation — anticipated questions and answers, contradiction maps for each witness, document bundles indexed to arguments, "what breaks if the judge asks X." Rehearsal generation, not live autonomy. `HYPOTHESIS`
- *Computation cannot*: it cannot be in the room performing. Live human judgment, credibility, and rhetoric are out of scope for autonomy; the system is a preparation engine, not an advocate. `DESIGN-ENTAILED`

**L5 — Judicial discretion.** Greek and ECHR practice leave large zones where the outcome is not entailed by the legal text — open texture (Hart), proportionality (αναλογικότητα), good faith (καλή πίστη), abuse of right (καταχρηστική άσκηση), discretionary balancing, sentencing, provisional-measures (ασφαλιστικά μέτρα) discretion.
- *Computation helps*: map the discretionary space; assemble the strongest arguments *on each side* of a balancing test; surface how this bench (or this court, or this line of authority) has resolved similar balances; identify which facts move the discretion. `HYPOTHESIS`
- *Computation cannot* (structural, and this is the deepest limit): discretion is, by legal design, *not* a function computable from the legal materials. Predicting a judge is empirical and bounded; *deriving* the "correct" discretionary answer is a category error. The system must represent discretion as **genuinely open**, never collapse it to a point prediction presented as law. `DESIGN-ENTAILED` (that it must represent it as open); the limit itself is `THEOREM`-adjacent only in the trivial sense that no rule-set entails its own discretionary exceptions.

**L6 — Settlement leverage.** Most matters end in settlement. Leverage is a function of BATNA (best alternative to negotiated agreement) on both sides, cost/time exposure, reputational stakes, and information asymmetry (L1).
- *Computation helps*: structured BATNA analysis; decision-tree / expected-value modeling of litigate-vs-settle with explicit, inspectable probability inputs; sensitivity analysis ("the recommendation flips if P(win on liability) drops below 0.4"); identifying the opponent's cost pressures. `HYPOTHESIS`
- *Computation cannot*: it cannot supply the true probabilities. It can only make the *assumptions explicit and their consequences legible*. The danger is false precision; the design must foreground the assumptions, not the number. `DESIGN-ENTAILED`

**L7 — Hearing dynamics and procedural traps.** Burden of proof allocation, admissibility, preclusion (δεδικασμένο / res judicata, and the concentration of grounds), objection timing, the difference between what is *in the record* and what is *true*. Elite opponents win by procedural traps: a defect in service, a missed objection that waives a defense, an inadmissible late-filed document.
- *Computation helps* (strong): procedural-state tracking as a formal object (what has been pleaded, admitted, precluded, what burden lies where, what is still open); trap detection ("if you do not object now, you waive"); admissibility pre-checks; completeness checks against the required elements of the cause of action. `DESIGN-ENTAILED`
- *Computation cannot*: it cannot fully formalize every procedural subtlety; residual open texture remains and must be flagged. `DESIGN-ENTAILED`

**L8 — Forum, framing, and the choice of battle.** Which court, which cause of action, which remedy, which order to raise issues, whether to bifurcate, whether to seek provisional measures first. These structural choices often matter more than the merits argument.
- *Computation helps*: enumerate the option space; map each option's procedural consequences, reversibility, and burden implications; find dominated options. `HYPOTHESIS`
- *Computation cannot*: the final election is strategic and human. `DESIGN-ENTAILED`

### 1.2 The derived design invariants

From the L1–L8 analysis, four invariants fall out that constrain every later choice:

- **INV-1 (Honest ignorance beats confident error).** Because irreversible moves (L3) and deadlines (L2) have catastrophic, asymmetric downside, the system's dominant failure mode to avoid is *confident wrongness*. A system that says "I do not know whether this deadline rule applies" is more valuable than one that guesses right 95% of the time, because the 5% is unbounded loss. **No LLM in the trusted path; guessing is a defect, not a feature.** `DESIGN-ENTAILED`
- **INV-2 (Many worlds, not one truth).** L5 (discretion), L1 (competing theories), and evidence (alternative factual worlds) mean a single "one truth" world model is presumptively wrong. The epistemic core must be *pluralist*: competing interpretations, conflicting authorities, and alternative factual reconstructions coexist as first-class objects. `DESIGN-ENTAILED`
- **INV-3 (Procedural state is a first-class formal object.)** L2, L3, L7, L8 all operate on the *procedural position*, not the substantive merits. The most computable, highest-leverage, lowest-open-texture surface is the procedural machine. The architecture centers a formally-tracked procedural state, not a chat interface. `DESIGN-ENTAILED`
- **INV-4 (The system prepares; humans decide and act.)** L3, L4, L5, L6, L8 all terminate in a human authority point. The system's autonomy ends at the water's edge of any irreversible or in-room act. This is a *trust-boundary* decision, encoded structurally (Part 10), not a policy hope. `DESIGN-ENTAILED`

---

## Part 2 — Trust boundaries and the TCB

### 2.1 The central trust question

The distinctive security fact of this domain: the most powerful reasoning components (large language models, learned predictors) are exactly the components you *cannot* trust to be correct or non-fabricating. Therefore the architecture's spine is a separation between:

- **The Trusted Computing Base (TCB)** — small, auditable, deterministic, no LLM inside it — which is the only thing allowed to *assert* legal facts, compute deadlines, gate publication, enforce isolation, and record what happened.
- **The untrusted reasoning periphery** — LLMs, agents, predictors, search — which may *propose, draft, argue, and rank* but may never *assert as ground truth* nor *act* without passing through the TCB. `DESIGN-ENTAILED`

This is the inversion that makes a small TCB possible: **capability lives outside the TCB; authority lives inside it.**

### 2.2 What is in the TCB (and why it can be small)

The TCB contains only components whose *correctness is checkable and whose behavior is deterministic*:

1. **The Authority Store (append-only, content-addressed).** The canonical corpus of legal authorities (statutes, case-law, procedural rules), each with provenance, version, validity dates, and a cryptographic hash. It stores *authorities*, not conclusions. It never runs an LLM. `DESIGN-ENTAILED`
2. **The Deadline/Procedure Kernel.** A deterministic calculator over dated events and statutory intervals (L2, L7). Pure functions; property-tested; every rule traceable to an authority id. Output is either a computed deadline *with its derivation* or `UNKNOWN`. `DESIGN-ENTAILED`
3. **The Procedural-State Machine.** A formal representation of each matter's procedural position (what is pleaded, admitted, precluded, burden allocation, open issues, points of no return). State transitions are typed and validated; illegal transitions are structurally rejected. `DESIGN-ENTAILED`
4. **The Claim-Ledger and Provenance Graph.** Every assertion the system surfaces carries a status tag (THEOREM…UNKNOWN) and a provenance chain to Authority Store ids or to a named human. Unprovenanced assertions cannot be marked as anything above HYPOTHESIS. `DESIGN-ENTAILED`
5. **The Policy Enforcement Point (PEP) / reference monitor.** Mediates *every* dataflow crossing a trust boundary: matter isolation, ethical walls, egress, publication. Complete mediation, tamperproof, small enough to verify. `DESIGN-ENTAILED`
6. **The Audit Log (append-only, hash-chained, WORM).** Immutable record of every decision, every boundary crossing, every human approval. `DESIGN-ENTAILED`

**Why the TCB can be small (and honest caveat):** none of these contain machine learning; each is a deterministic program over structured data. Smallness is a *design goal*, achievable *if* we resist the temptation to let "helpful" LLM logic leak inside. The honest caveat: the TCB is only as correct as (a) its code and (b) *the natural-language-to-formal translation of legal rules into the kernel*. Proof-checking the kernel's code does **not** prove the kernel encodes Greek procedure correctly. That translation is a permanent `HYPOTHESIS`/`EMPIRICAL` surface, validated by human legal review and regression against decided cases, never "proved." This is stated as a first-class weakness in Part 13. `DESIGN-ENTAILED`

### 2.3 What is explicitly NOT in the TCB

LLMs, agent orchestration, retrieval/search, argument generation, prediction models, the drafting surface, external model vendors. All untrusted. Their outputs are *proposals* that live at status ≤ HYPOTHESIS until a TCB component or a human elevates them with provenance. `DESIGN-ENTAILED`

### 2.4 Primary trust boundaries (enumerated)

- **B1: Untrusted reasoning ↔ TCB.** Proposals cross inward; only provenanced, status-tagged assertions and validated state transitions are accepted. Nothing an LLM says becomes "true" by being said.
- **B2: Matter ↔ Matter.** Hard isolation between client matters (Part 8). Default deny.
- **B3: Ethical wall boundaries.** Sub-partitions within the firm for conflicted teams (e.g., both sides of a dispute historically, or lateral-hire screens). Default deny.
- **B4: Internal ↔ External model/vendor.** Any call to a component outside the firm's control (Part 8.4). Default deny egress; scrubbed, minimized, logged.
- **B5: Private ↔ Public (the Publication Gateway).** The only path to the outside world (Part 11). Fail-closed.
- **B6: System ↔ Human authority.** Where the system stops and a licensed human decides/acts (Part 10). `DESIGN-ENTAILED`

---

## Part 3 — Dataflow

Canonical flow for a unit of work ("the system helps with matter M"):

```
[Matter intake] --(PEP: matter-scoped capability token)--> [Working context for M]
        |
        v
[Untrusted reasoning periphery]  -- retrieves --> [Authority Store, read-only, versioned]
   (agents, LLMs, search)        -- proposes  --> {drafts, arguments, rankings, predictions}
        |                                              each tagged status<=HYPOTHESIS
        v
[TCB ingestion]
   - Deadline Kernel: recompute independently (never trust the LLM's arithmetic)
   - Procedural-State Machine: validate any proposed transition
   - Claim-Ledger: attach provenance; refuse to elevate unprovenanced claims
        |
        v
[Human authority point]  -- lawyer reviews, edits, DECIDES --> [Decision recorded, signed]
        |                                                          (irreversible moves gated here)
        v
[Audit Log: hash-chained append]
        |
        v
(optional, separate) [Publication Gateway B5]  -- fail-closed --> [Public release + receipt]
```

Key dataflow rules (`DESIGN-ENTAILED`):
- **DF-1.** Retrieval is read-only against a *pinned version* of the Authority Store; every retrieved authority is cited by id+hash+validity-date so the same query is replayable.
- **DF-2.** The Deadline Kernel **never** ingests an LLM-computed date as authoritative; it recomputes from primitive events. The LLM may *explain*; the kernel *decides*.
- **DF-3.** No dataflow crosses B2–B5 without the PEP mediating; there is no side channel (Part 8).
- **DF-4.** Every artifact the lawyer sees carries its status tags and provenance inline — the human never sees an un-tagged assertion.

---

## Part 4 — Control plane

The control plane is deliberately **not** an LLM planner. An LLM may *suggest* a plan, but the executor of plans is a deterministic **Matter Orchestrator** in the trusted zone that:

- issues **matter-scoped capability tokens** (object-capability model): an agent gets a token that names exactly the matter, the authority versions, and the operations it may perform; it can do nothing outside that token. No ambient authority. `DESIGN-ENTAILED`
- enforces **typed workflows**: procedural workflows (deadline tracking, admissibility checks, completeness checks) are typed state machines, not free-form agent loops. The agent fills slots; it does not redefine the machine. `DESIGN-ENTAILED`
- separates **advisory** tasks (open-ended, LLM-heavy, low-stakes: brainstorm arguments) from **gated** tasks (deadline computation, procedural transitions, publication) that require TCB validation and/or human approval. `DESIGN-ENTAILED`
- is **interruptible and resumable**: because deadlines are correctness requirements (condition 5), long tasks checkpoint and the control plane guarantees liveness on time-critical paths (Part 9). `DESIGN-ENTAILED`

**Why not an LLM planner in control:** giving an LLM the plan-and-execute authority reintroduces confident error (INV-1) into the trusted path and makes matter isolation depend on the model's good behavior. The control plane's job is precisely to *not* trust the model. `DESIGN-ENTAILED`

---

## Part 5 — Agent topology

Agents are **untrusted specialists** with narrow charters, each running against a matter-scoped token. They are workers, never authorities. Topology:

- **Advocate agents (per side).** For any contested issue, at least two independent adversarial agents are instantiated: one building the firm's strongest case, one *red-teaming it as the opponent would*, with **fresh context and no access to the other's private reasoning** (this mirrors the creator's internal-adversary protocol and is here a *design* requirement, not decoration). The opponent-agent's job is to *break* the firm's theory. Their disagreement is preserved as competing worlds (INV-2), not averaged into consensus. `DESIGN-ENTAILED`
- **Evidence agents.** Ingest the record, build timelines, detect contradictions, map each document to what it proves/disproves/leaves open. Output alternative factual reconstructions (Part 6), never a single "what happened." `DESIGN-ENTAILED`
- **Procedure agents.** Propose procedural moves and flag traps (L7); *all* their outputs are validated by the Procedural-State Machine before they count. `DESIGN-ENTAILED`
- **Authority agents.** Retrieve and rank authorities, surface conflicts *without resolving them*, distinguish binding vs persuasive, current vs superseded. `DESIGN-ENTAILED`
- **Critic/adversary agents (cross-cutting).** Independent agents that attack the *system's own* work product for mediocrity, hidden assumptions, unprovenanced claims, and fabrication, before any human sees a recommendation. Findings are closed at their seat or logged as residue. `DESIGN-ENTAILED`
- **Devil's-advocate on every recommendation.** No recommendation reaches the lawyer without a paired strongest-counter-recommendation. The interface presents the tension; it does not hide it. `DESIGN-ENTAILED`

**Topology invariant:** agents *never* talk to the outside world, *never* write to the Authority Store, *never* execute an irreversible move, and *never* elevate their own claims' status. They propose; the TCB and humans dispose. `DESIGN-ENTAILED`

---

## Part 6 — Epistemic representation (the heart)

A single "one truth" world is presumptively wrong (INV-2). The epistemic core is a **multi-world, multi-authority, defeasible representation**:

### 6.1 Legal knowledge
- **Authorities as versioned, dated objects.** Every statute/case/rule carries validity intervals (in force from/to), hierarchy (constitutional/EU/ECHR/statute/case), and bindingness. Retrieval is *as-of-a-date* and *as-of-a-version*. The law "as it was on the filing date" and "as it is now" are both queryable (Part 7). `DESIGN-ENTAILED`
- **Rules as defeasible, not monotone.** Legal rules have exceptions, and exceptions have exceptions. The representation is *defeasible logic* with explicit priorities (lex superior, lex specialis, lex posterior) — but priorities that are themselves *contested* are represented as contested, not silently resolved. `DESIGN-ENTAILED`

### 6.2 Competing interpretations and conflicting authorities
- Represented as a **conflict graph**: nodes are interpretations/authorities; edges are "supports," "conflicts-with," "distinguishes," "overrules," "is-persuasive-against." The system's job is to *render the conflict legible and assemble each side's strongest case*, **not** to declare a winner where the law itself is unsettled. Where a conflict is genuinely open, the output status is `UNKNOWN`/HYPOTHESIS with the competing lines shown, never a fabricated resolution. `DESIGN-ENTAILED`

### 6.3 Alternative factual worlds
- Evidence rarely fixes one history. The system maintains **multiple factual reconstructions** consistent with the record, each with the evidence that supports/undercuts it and each with its procedural/burden consequences. "Which world is true" is not asserted; "under world W, the following follows; the evidence bearing on W is …" is asserted. `DESIGN-ENTAILED`

### 6.4 Procedural uncertainty
- The Procedural-State Machine carries **known / assumed / unknown** flags on every element. An assumed rule is visibly assumed; an unmodeled rule is visibly `UNKNOWN`, never treated as satisfied. Deadlines computed under an assumption are labeled with that assumption. `DESIGN-ENTAILED`

### 6.5 Discretion (L5) as an explicit non-collapsed object
- Discretionary questions are typed as **discretionary**: the representation refuses to emit a point-value "the court will hold X" as law. It emits (a) the space of permissible outcomes, (b) the factors and their directions, (c) *empirical* base rates where available (clearly tagged `EMPIRICAL`, with sample and caveats), and (d) the strongest argument on each side. Collapsing discretion to a prediction-presented-as-law is a structural error the type system forbids. `DESIGN-ENTAILED`

---

## Part 7 — Reasoning modes and memory/versioning

### 7.1 Four reasoning modes, kept distinct
1. **Computational law** (decidable-ish): deadlines, jurisdictional thresholds, element-completeness, admissibility mechanics. Handled by the TCB kernels; output deterministic and provenanced. Highest trust. `DESIGN-ENTAILED`
2. **Precedent reasoning** (analogical, defeasible): analogize/distinguish cases; handled by authority+advocate agents; output is *arguments*, status ≤ HYPOTHESIS until a human adopts. `DESIGN-ENTAILED`
3. **Open texture / discretion** (Part 6.5): never collapsed; multi-sided. `DESIGN-ENTAILED`
4. **Evidence reasoning** (abductive, probabilistic): multiple factual worlds, explicit and inspectable probabilities, sensitivity analysis, no false precision. `DESIGN-ENTAILED`

Keeping these distinct matters because they have different truth conditions; blending them (e.g., letting a precedent LLM "compute" a deadline) is exactly how confident error enters. `DESIGN-ENTAILED`

### 7.2 Memory and versioning
Two replay guarantees, both required:
- **Same-version replay (reproducibility).** Given a matter, a question, and a pinned Authority-Store version + model versions + seeds, the system reproduces the *same* work product. Needed for audit, for defending a recommendation later, and for regression. Achieved via content-addressed authorities, recorded model/version/seed, and deterministic TCB. `DESIGN-ENTAILED`
- **Current-version re-evaluation (change detection).** The *same* matter can be re-run against the *current* Authority Store to detect "the law changed under us": a new precedent, a statutory amendment, an overruling. The system surfaces the delta ("your position relied on X; X was distinguished on 2026-06-01"). `DESIGN-ENTAILED`

Memory is **matter-scoped by construction** (Part 8): a matter's memory is a partition; cross-matter learning happens only through de-identified, human-approved distillation into the shared Authority/heuristic layer (Part 12), never by ambient recall of another client's facts. `DESIGN-ENTAILED`

---

## Part 8 — Security model

### 8.1 Matter isolation (B2)
- Each matter is a **hard partition**: separate encryption keys, separate storage namespace, separate capability tokens. An agent working matter M *cannot name* objects in matter M′ — isolation is by capability, not by filter (you cannot filter what you were never given a handle to). Default deny. `DESIGN-ENTAILED`
- Cross-matter queries (e.g., "have we seen this issue before") are served *only* by the de-identified shared knowledge layer, and *only* through the PEP, which strips client-identifying facts. `DESIGN-ENTAILED`

### 8.2 Ethical walls (B3)
- Conflicts (Chinese walls, lateral-hire screens, both-sides history) are enforced as **capability revocations**: screened personnel/agents are not issued tokens for the walled matter. Because isolation is capability-based, a wall is the *absence* of a handle, which is stronger than an access-control check that could be misconfigured to "allow." Wall definitions are themselves in the TCB and audit-logged. `DESIGN-ENTAILED`

### 8.3 Insider threat
- **Every** access is logged (hash-chained, WORM) with the human/agent identity, matter, and purpose. Bulk access, cross-matter access attempts, and egress are anomaly-flagged. No single human can both approve a publication and be its author (separation of duties, Part 11). No single admin can silently alter the Authority Store or Audit Log (append-only + multi-party control on schema/authority changes). `DESIGN-ENTAILED`
- Honest limit: insider threat cannot be *eliminated*, only *contained and made evident after the fact*. WORM audit makes tampering detectable; it does not make a malicious authorized read impossible. Stated as a weakness (Part 13). `DESIGN-ENTAILED`

### 8.4 Egress and vendor/model risk (B4)
- **Default-deny egress.** No component reaches the network except through the PEP. Prompts/data sent to any model are minimized and scrubbed; the PEP logs exactly what left. `DESIGN-ENTAILED`
- **Vendor risk.** External models are untrusted *both* for correctness (already handled: they never enter the TCB) *and* for confidentiality (they might retain/leak). Therefore: prefer models running inside the firm's controlled boundary for anything touching client facts; if an external model is used, it sees only minimized/de-identified input, and the *legal conclusion* is never taken from it — it is a drafting/brainstorming aid whose output is re-grounded against the Authority Store. Model diversity (multiple independent models) is used to detect model-specific fabrication by disagreement. `DESIGN-ENTAILED`
- **Supply-chain / model-swap risk.** Model identities and versions are pinned and recorded; a silent model swap breaks replay and is detected. `DESIGN-ENTAILED`

### 8.5 The anti-fabrication stance
Because "no fabrication" is a binding condition, the security model treats *fabricated authority* as a security event equivalent to data corruption: any cited authority is verified against the Authority Store by id+hash before it can appear at status > HYPOTHESIS. A citation that does not resolve is quarantined and flagged, never shown as valid. `DESIGN-ENTAILED`

---

## Part 9 — Failure containment and the deadline-liveness requirement

- **Fail toward honesty.** On uncertainty, components emit `UNKNOWN` and escalate, rather than guess (INV-1). A component that cannot verify does not assert. `DESIGN-ENTAILED`
- **Fail-closed on boundaries.** If the PEP cannot decide whether a crossing is permitted, it denies. If publication checks cannot complete, publication is blocked. `DESIGN-ENTAILED`
- **But deadlines fail *loud*, not silent.** Availability/latency are correctness requirements (condition 5). The Deadline Kernel is the highest-availability component: redundant, monotone countdowns that escalate to humans through independent channels as a deadline nears; if the *system* is down, the deadline calendar must still alarm. A silent failure that lets a προθεσμία lapse is the worst outcome in the whole design, so the deadline path has independent redundancy and its liveness is monitored separately from the rest of the system. `DESIGN-ENTAILED`
- **Blast radius = one matter.** Because of capability isolation, a compromised agent or corrupted context is contained to its matter's partition. `DESIGN-ENTAILED`
- **Contradictions stay BLOCKING.** An unresolved contradiction (e.g., two TCB kernels disagree, or a citation fails to verify) blocks the affected work product from reaching "ready for decision" status until a human resolves it. Contradictions are never auto-resolved by picking one side. `DESIGN-ENTAILED`

---

## Part 10 — Human authority points

The system is a **preparation and analysis engine; licensed humans decide and act** (INV-4). Non-negotiable human authority points, enforced structurally (the system *cannot* perform these):

- **HA-1: Every irreversible move (L3).** Filing, admission, waiver, election, consent, settlement acceptance. The system may draft and analyze; a named lawyer signs. The "point of no return" ledger forces explicit human sign-off with a recorded rationale. `DESIGN-ENTAILED`
- **HA-2: Every in-room / one-shot act (L4).** Hearings, cross-examination, oral argument. System prepares; human performs. No autonomy. `DESIGN-ENTAILED`
- **HA-3: Adoption of any conclusion above HYPOTHESIS in a substantive (non-computational) legal question.** A human must adopt an argument for it to become the firm's position. `DESIGN-ENTAILED`
- **HA-4: Publication (Part 11).** Separate human approval, separated from authorship. `DESIGN-ENTAILED`
- **HA-5: Merging any self-improvement into the shared knowledge/heuristic layer (Part 12).** No self-merge. `DESIGN-ENTAILED`

These are trust-boundary B6. The system's UI makes the human's authority *the* action; the system's outputs are always framed as proposals to a decision-maker. `DESIGN-ENTAILED`

---

## Part 11 — Publication boundary (fail-closed gateway, B5)

The **only** path from private to public. Per conditions, only final outputs (e.g., codified statutes/case-law publications) may ever go public. The gateway is fail-closed and multi-stage; a release requires **all** stages to pass:

1. **Privilege review.** Automated privilege/work-product detection flags anything that could be privileged; a human privilege reviewer must clear it. Fail → block.
2. **Confidentiality / DLP.** Scan for client-identifying data, matter facts, internal strategy, model traces. Any hit → block.
3. **Redaction.** Applied and *verified* (re-scan after redaction; residual hit → block).
4. **Authority validation.** Every legal statement in the public output resolves to a verified Authority-Store id+hash; no unverifiable/fabricated authority may be published. Fail → block.
5. **Human approval, with separation of duties.** The approver is *not* the author (insider-threat control). A named human signs the release.
6. **Immutable release receipt.** A hash-chained receipt recording exactly what was released, its source version, the approver, and the checks that passed. `DESIGN-ENTAILED`

Fail-closed means: any stage that errors, times out, or cannot verify **blocks** the release; nothing leaks on failure. The gateway is a distinct trust boundary with its own reference monitor; it does not share code paths with internal drafting so that an internal bug cannot open an egress. `DESIGN-ENTAILED`

---

## Part 12 — Self-improvement without self-merge

The system must get better over time *without* the ability to promote its own changes into the trusted or shared layers.

**Mechanism (propose → adversarial-test → human-merge):**
1. **Candidate generation.** From completed matters, the system proposes de-identified improvements: new procedural rules for the kernel, corrected deadline logic, better heuristics, new argument templates, detected corpus errors. Candidates are generated in a *staging* partition, isolated from production. `DESIGN-ENTAILED`
2. **Independent adversarial evaluation.** Fresh critic agents (no access to the proposer's reasoning) attack each candidate: does it break existing regression cases? does it introduce a fabrication path? is it a patch around a wrong model rather than an elimination of the error class? Findings block or reshape the candidate. `DESIGN-ENTAILED`
3. **Regression against replay.** Every candidate is run against the same-version replay corpus (Part 7.2): it must not change any decided-and-approved outcome except where a human explicitly intends the change. `DESIGN-ENTAILED`
4. **Human merge, never self-merge (HA-5).** A candidate enters the shared Authority/heuristic layer or the TCB *only* by explicit, signed human approval, per-change. The system has **no capability token** that permits writing to production TCB or shared knowledge — that write handle is only ever held by a human-gated release process. Self-merge is impossible by capability, not merely forbidden by policy. `DESIGN-ENTAILED`
5. **Versioned, reversible, receipted.** Every merge is a new version with a receipt; any merge can be rolled back; the old version remains replayable. `DESIGN-ENTAILED`

**Honest caveat:** "self-improvement" here is *candidate generation + human-gated integration*, not autonomous self-modification. Presenting it as more than that would be a false capability claim. The improvement rate is bounded by human review throughput, which is *by design* — the alternative (autonomous merge) reintroduces INV-1 risk into the trusted core. `DESIGN-ENTAILED`

---

## Part 13 — FALSIFIABLE WEAKNESSES

Where this design can fail, and how an evaluator would detect each. I do not self-grade; these are real, and several are structural rather than fixable.

**W1 — The formalization gap (deepest).** The Deadline/Procedure kernels are only as correct as the human translation of Greek procedural law (ΚΠολΔ, admin, penal, ECHR) into formal rules. **Proof-checking the kernel code does not prove the law was encoded correctly.** *Detection:* build a held-out set of real decided procedural questions with known correct answers; measure kernel error rate; every kernel error is a formalization defect. A nonzero rate is expected and permanent. *Consequence:* the "0 λάθος / no guessing" ambition is bounded by this gap — the system can be honestly-ignorant safely, but a *wrong-but-confident* kernel rule would violate INV-1 silently. This is the single most dangerous failure and it is not eliminable, only measured and shrunk. `HYPOTHESIS`/`EMPIRICAL`

**W2 — Prediction dressed as law (L5).** Despite the type-level ban on collapsing discretion, an evaluator should probe whether, in practice, empirical base rates get read by users as "the law says." *Detection:* user-study / red-team the interface — present discretionary outputs and check whether reviewers mistake `EMPIRICAL` base rates for `THEOREM`/DESIGN-ENTAILED conclusions. If they do, the representation failed regardless of the type system. `HYPOTHESIS`

**W3 — Adversarial-agent theater.** The two-independent-agent design *claims* genuine adversarial pressure. If both agents share the same base model and prompt scaffolding, their "independence" may be illusory (correlated blind spots). *Detection:* measure whether the opponent-agent ever finds defects the proposer's own errors would predict it to miss; inject known flaws and see if the adversary catches them. Correlated failure across agents falsifies the "adversary forces the top implementation" claim. `HYPOTHESIS`

**W4 — Isolation via capability assumes a correct PEP.** Matter isolation is only as strong as the reference monitor's completeness. A single missed mediation path (a side channel, a cache, a shared embedding index that leaks) breaks B2/B3. *Detection:* red-team for cross-matter leakage — can an agent in M surface any fact from M′? Any positive is a critical finding. Shared vector indices are a classic leak; the design mandates per-matter indices, but that must be *tested*, not assumed. `HYPOTHESIS`

**W5 — The human bottleneck.** By forbidding self-merge and requiring human authority at every irreversible/substantive point, the system's throughput and improvement rate are capped by human review. Under deadline pressure (L2), a fatigued human may rubber-stamp system proposals, converting "human authority" into a rubber stamp and silently reintroducing confident error. *Detection:* measure edit-rate and time-spent on human approvals under deadline pressure; near-zero edits with fast approvals indicates automation bias, not genuine authority. This is a socio-technical failure the architecture cannot fix alone. `HYPOTHESIS`

**W6 — Availability vs fail-closed tension.** Deadlines must fail-loud (Part 9) while boundaries fail-closed. A subtle failure mode: the fail-closed PEP blocks a component whose output was needed to *compute* a deadline, and the fail-loud alarm never fires because the deadline was never computed. *Detection:* fault-injection — kill the authority-retrieval path and verify the deadline alarm still fires from the independent calendar. If deadline liveness depends on the same components as everything else, this design goal is unmet. `HYPOTHESIS`

**W7 — "No LLM in the trusted path" can be quietly violated.** The strongest guarantee (INV-1) erodes if, over time, "helpful" LLM logic creeps into TCB components (e.g., an LLM pre-normalizes dates before the kernel). *Detection:* static audit of TCB dependencies for any ML component; any inbound ML call inside the TCB is a violation. The claim is only as good as ongoing enforcement. `DESIGN-ENTAILED` (the check is definable) / `HYPOTHESIS` (that it stays true).

**W8 — The system optimizes the game it can model, not the real game.** The whole design derives from the L1–L8 victory-condition model (Part 1). If that model of "what wins" is wrong or incomplete (e.g., relationships, reputation, and off-record dynamics dominate in ways not captured), the architecture is superbly built for the wrong objective. *Detection:* outcome study — do matters where the system was used *actually* fare better against elite opponents, controlling for merits? Absent that, the supremacy claim is `HYPOTHESIS`, and I do not assert it. `HYPOTHESIS`

**W9 — Publication gateway false-negative.** DLP/privilege scanners have nonzero miss rates; a fail-closed gateway blocks on *detected* risk but cannot block *undetected* leakage. *Detection:* seed known-sensitive canaries into pre-publication material and verify the gateway blocks; measure miss rate. A single missed canary that would have been published is a critical finding. `HYPOTHESIS`

**W10 — Replay determinism vs model reality.** Same-version replay (Part 7.2) assumes model determinism given fixed seeds/versions. Many production models are not bit-reproducible. If replay is not actually deterministic, the audit/defense guarantee is weaker than claimed. *Detection:* run the same pinned query twice; diff outputs; nonzero substantive drift falsifies the reproducibility claim for the ML periphery (the TCB remains deterministic; the periphery may not). `HYPOTHESIS`

---

## Part 14 — What this design does NOT claim

- It does **not** claim to know the law better in a way that entails winning (Part 1 rejects that frame). `DESIGN-ENTAILED`
- It does **not** claim to resolve genuinely unsettled law or discretion — it claims to *represent* them honestly. `DESIGN-ENTAILED`
- It does **not** claim its TCB is *correct*, only that its TCB is *small, deterministic, and checkable*, with a stated, measurable formalization gap (W1). `DESIGN-ENTAILED`
- It does **not** claim autonomy at any irreversible or in-room point — those are human by construction. `DESIGN-ENTAILED`
- It does **not** self-grade or declare supremacy. Supremacy over an equally-resourced opponent is `HYPOTHESIS` (W8), testable only by outcome study, and is left unproven here. `HYPOTHESIS`

---

## Appendix A — Mapping victory conditions to components (traceability)

| Lever | Primary components | Human authority | Status of computational help |
|---|---|---|---|
| L1 Information asymmetry | Evidence agents, contradiction maps, adversary-model | HA-3 | HYPOTHESIS (analysis), hard ethical boundary on acquisition |
| L2 Timing/deadlines | Deadline Kernel (TCB), fail-loud alarms | HA-1 (use of timing) | DESIGN-ENTAILED (computable), W1 caveat |
| L3 Irreversible moves | Point-of-no-return ledger, reversibility classifier | HA-1 (mandatory) | DESIGN-ENTAILED |
| L4 One-shot events | Prep/rehearsal agents | HA-2 (mandatory) | HYPOTHESIS |
| L5 Judicial discretion | Discretion-typed epistemic core, base rates | HA-3 | DESIGN-ENTAILED (represent-as-open), W2 |
| L6 Settlement leverage | BATNA/decision-tree with explicit inputs | HA-1 (acceptance) | HYPOTHESIS, false-precision risk |
| L7 Hearing dynamics/traps | Procedural-State Machine (TCB), trap detector | HA-3 | DESIGN-ENTAILED |
| L8 Forum/framing | Option-space enumerator, dominated-option finder | HA-1 (election) | HYPOTHESIS |

## Appendix B — Trust-boundary summary

| ID | Boundary | Default | Enforcement |
|---|---|---|---|
| B1 | Reasoning ↔ TCB | proposals only | provenance + status-tag gate |
| B2 | Matter ↔ Matter | deny | capability isolation, per-matter keys/indices |
| B3 | Ethical walls | deny | capability revocation (absence of handle) |
| B4 | Internal ↔ External model | deny egress | PEP scrub/minimize/log |
| B5 | Private ↔ Public | fail-closed | Publication Gateway (6 stages) |
| B6 | System ↔ Human | human decides | irreversible/in-room acts are human-only |

*End of Design B.*
