# 00 — MISSION

## Purpose

A **private** legal superweapon for one law firm (Stavropoulos Law®), whose mission is
**equality of arms** (Art. 6 ECHR): the advocate of the under-resourced client becomes
objectively unbeatable, so that a poor citizen cannot lose to a rich party's elite legal
team. The system is not a public product. The **only public surface** is the already-public
statutes, codified (ELI — European Legislation Identifier). Everything else — office
operations, case analysis, lawful public-record person research, strategy, drafting —
is private.

## The operator model

The user experience is a **virtual law firm**: the lawyer directs what feels like hundreds
of elite specialists (litigators, clerks, accountants, psychologists, rhetoricians,
investigators, a managing partner). The machine underneath is NOT hundreds of agents with
authority — it is the faculty architecture of `02-ARCHITECTURE.md`/`03-ORGANS.md`: many
untrusted capability organs, one admission gate, one verified world, one proof per answer.

## "Unbeatable at the level of the feasible" — exact definition

The claim decomposes into four components with different guarantee classes:

1. **Correctness — absolute ceiling, guaranteed.** No agent can be "more correct" than a
   machine-checked proof over verified law. Answer-as-proof (Pillar 3) closes this
   component outright.
2. **Completeness — guaranteed within declared coverage.** Within the searched space
   (moves × admissible construals × fact-characterizations), no opponent wins with a line
   that was inside: it was enumerated, evaluated, countered (Pillar 4). The guarantee is
   always stamped "complete relative to declared coverage C" (see the Υ axiom in
   `01-INVARIANT.md`).
3. **Idea/strategy generation — dominance by inclusion.** The system does not need to be
   the best generator; it is the best **verifier with access to ALL generators**. Because
   every model is untrusted (Pillar 1), every frontier LLM can be socketed as a competing
   proposer. Any idea available to an opponent-using-model-X is therefore available to us;
   the gate selects and certifies the best. Formally: our generator set is a superset of
   any single opponent's; we cannot guarantee no better idea exists anywhere, but we CAN
   guarantee no better idea exists **that cannot become ours**.
4. **Drafting — correctness + calibrated persuasion.** "Better pleading" = more correct
   (won by component 1) + more persuasive (multi-model drafting candidates, the
   judge-model, and calibration against realized outcomes — what actually prevailed in
   comparable matters, never what "sounds good").

**The one un-closable residue, and why litigation minimizes it:** no architecture can
guarantee against a genuinely novel idea at its FIRST appearance. But litigation is a
**turn-based game with mandatory disclosure**: to use an idea, the opponent must reveal it
(pleadings, hearings), and the law guarantees a right of response (αντίκρουση, deadlines,
remedies). The system therefore carries a **one-round absorption guarantee**: any novel
weapon used against the firm is ingested into verified memory (Pillar 5), analyzed,
countered in the next procedural round, and becomes the firm's permanent asset for every
future matter. The inventor used it once.

## Preventive deployment — disputes born won

Above "win every dispute" sits "the client cannot lose because the dispute is born
already won". The same machine, applied at **instrument-drafting time**: before a
contract/notice/corporate act is executed, the exhaustion engine (Pillar 4, incl.
preclusion control) runs against the DRAFT — enumerating every future dispute the
instrument could spawn and rewriting it until each such dispute is pre-computed in the
client's favor, with a preclusion certificate. This is not a second system; it is the same
pillars bound earlier in time (see BO-32). Mission ordering: engineered-position ⊃
litigation-win ⊃ never-burns-the-client.

## Honest limits (stated so the mission cannot be oversold)

- **Facts from evidence are never certain.** Readings of photos, handwriting, documents are
  probabilistic proposals with provenance + confidence; critical facts require human
  confirmation. Subsumption is exact but conditional: "IF these facts (each with its
  source), THEN this law applies, with proof."
- **Open-textured law** (good faith, proportionality, reasonableness) is never faked as
  computation; it is structured defeasible argument with explicit, contestable assumptions.
- **"Best on the planet" is a measurable claim, not an a-priori one.** It is earned via the
  backtesting and independent-reproduction regime of `07-VERIFICATION.md`, and may not be
  asserted before that regime passes. Until then the permitted claim is: "the strongest
  design buildable today, foundations already running above the commercial floor, every
  next step named."
