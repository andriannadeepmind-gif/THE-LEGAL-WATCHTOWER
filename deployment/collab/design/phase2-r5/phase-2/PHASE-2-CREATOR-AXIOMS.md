# PHASE-2 CREATOR AXIOMS

Phase: 2 — BLIND FRONTIER ARCHITECTURE
Role: Blind Frontier Architect
Date: 2026-08-26
Creator directive SHA-256: c2f4b68d36530d47204ab748096947045d62d9be15dca209de594099d346b330

This document fixes the axiom set from which every Phase-2 requirement, invariant,
candidate evaluation and selection is derived. Axioms are of three kinds:

- **C-axioms (creator-given)** — extracted from the creator directive. Not
  negotiable, not re-derived, not weakened.
- **L-axioms (legal-order-given)** — facts about the Greek and European legal
  order established from primary sources. Falsifiable by better legal evidence;
  each carries a research-ledger reference.
- **A-axioms (architect-adopted)** — adopted by me in this phase because the
  C-axioms and L-axioms cannot be jointly satisfied without them. Each A-axiom
  states its justification and its falsifier.

Every A-axiom is a *commitment that can be attacked*. The hostile self-audit
(PHASE-2-REPORT.md §5) attacks them.

---

## 0. NOTATION

- `⊨` — "the architecture must make true".
- `⊥` — "is architecturally void" (not merely logged, not merely rejected: the act
  has no institutional effect and produces no state change other than the record
  of its voidness).
- **Office** — a bearer of institutional power inside the Watchtower.
- **Power** — a typed, exclusive capacity to bring about a specific class of
  institutional fact.
- **Warrant** — the evidence, presented at the moment of an act, that the acting
  office holds the power it purports to exercise.
- **Entry** — an immutable, ordered record appended to the institutional record.
- **Kernel** — the deterministic, effect-free derivation function from record to
  state.
- **Shell** — everything effectful: observation, I/O, scheduling, presentation.

---

## 1. C-AXIOMS (CREATOR-GIVEN)

### C1 — Institutional, not instrumental
The Watchtower is a persistent, institutionally organized, metacognitive
legal-intelligence entity. It is **not** an ingestion pipeline, a search engine, a
publishing application, a single opaque agent, or a collection of tools.
Architecturally: the unit of design is an **office holding power**, not a service
holding a queue.

### C2 — Categorical non-confusion
The system ⊨ distinguish, as distinct kinds with distinct owners and distinct
transitions:
observation | acquisition | evidence | legal authority | interpretation |
inference | publication | institutional decision.
No coercion between kinds may occur except by a warranted act that is itself
recorded as an entry of the target kind.

### C3 — Adapters confer nothing
A source adapter ⊨ never independently confer legal authority. Generalized in
A1 below.

### C4 — Metacognition is semantics, not presentation
Metacognition, self-modeling, intentionality, reflective memory, internal
adversarial deliberation, institutional alignment and temporal continuity are
architectural semantics. A design in which they are logging, telemetry, prompt
reflection or dashboards is inadmissible.

### C5 — Explicit self-model
The Watchtower ⊨ possess an explicit internal model of: identity and mandate;
roles, offices, jurisdiction, powers, authority boundaries; operational and
epistemic state; what it knows and why; what it does not know; unresolved
conflicts and defeaters; coverage, freshness, lag, confidence, uncertainty; goal
hierarchy and current intentions; prior decisions and their reasons; and whether
its own reasoning and institutional procedures remain valid.

### C6 — No unresolved delegation
No core semantic problem may be delegated to an unspecified model, database,
framework, service, adapter, verifier, or future phase. A named dependency is
admissible only where its semantics are pinned by a cited specification and the
residual gap is stated.

### C7 — No duplicate truth or hidden authority
No duplicate truth, no duplicate authority, no hidden mutable ownership, no
silent degradation, no wrapper around an unresolved capability.

### C8 — Non-optimization constraints
Time, implementation effort, compute, monetary cost and code volume are **not**
optimization constraints and ⊨ never appear in an objective vector. Public state
of the art is a lower bound, not a target.

### C9 — Falsification discipline
Every consequential decision ⊨ declare, before selection: hard invariants;
feasible candidate set; objective vector and ordering; materiality thresholds;
evidence required for acceptance; credible defeaters; residual uncertainty. Every
provisional selection ⊨ face a dominance challenge; every iteration, including
failed challenges, is recorded.

### C10 — Bounded claim strength
No claim of global optimality without a complete formal candidate domain and a
mechanically checked proof. The admissible conclusion is normally
"non-dominated among the evaluated frontier candidates under the declared
constraints and evidence."

### C11 — Lisp by evidence
Common Lisp ⊨ be exploited natively **wherever** specific Lisp semantics create a
material semantic, introspective, correctness, recovery, performance or
evolvability advantage — and ⊨ **not** be used cosmetically. Mechanisms are
evaluated, not mandated. Manual imitation of CLOS/conditions/MOP through string
dispatch, generic maps, central conditional registries, exception-only control,
passive record classes or service-container ceremony is forbidden.

### C12 — Blindness
Phase 2 is produced without access to the existing implementation or to any prior
study artifact, so that the existing implementation cannot anchor the target.

---

## 2. L-AXIOMS (LEGAL-ORDER-GIVEN)

Each L-axiom is a legal fact the architecture must be *shaped by*, not merely
store. Ledger IDs refer to PHASE-2-RESEARCH-LEDGER.jsonl.

### L1 — Publication is constitutive, not informational
Statutes voted by Parliament are promulgated and published by the President of the
Republic (Constitution of Greece, Art. 42 §1). No Greek statute is legally
operative before publication in the Government Gazette (Εφημερίδα της
Κυβερνήσεως). [ledger: RL-021, RL-022]

**Architectural consequence.** The publication event is a *constitutive fact*, not
a metadata field. The architecture must be able to represent "this instrument
exists as a text but is not yet law", and must never allow a text acquired from a
non-gazette channel to be treated as operative merely because its content matches.

### L2 — Entry into force is separate from publication
Under Art. 103 of the Introductory Law to the Greek Civil Code (ΕισΝΑΚ), a statute
enters into force ten days after publication in the Gazette unless it provides
otherwise. Statutes routinely provide otherwise, and routinely do so
**per provision**. [ledger: RL-023]

**Architectural consequence.** Commencement is a property of a *provision*, not of
a document, and is a *derived* fact that can be wrong. `t_publication` and
`t_force` are independent axes; a single "effective date" column is inadequate.

### L3 — Separation of powers is the domain's own organizing principle
Legislative power is exercised by Parliament and the President; executive power by
the President and the Government; judicial power by the courts (Constitution of
Greece, Art. 26). [ledger: RL-021]

**Architectural consequence.** Source authority is a function of the *organ* and
*instrument type*, not of the channel through which bytes arrive. A ministerial
circular published in Gazette series Β′ and a statute published in series Α′ are
not made equal by sharing a retrieval path.

### L4 — The Gazette is itself a signing authority
Each electronic issue of the Government Gazette bears a digital signature from an
authorised officer of the National Printing House; bodies submit texts for
publication under advanced electronic signature (Law 3469/2006 as amended).
[ledger: RL-024, RL-025]

**Architectural consequence.** The strongest evidentiary primitive available for
Greek legislation is *already attached to the artifact*. An architecture that
extracts text and discards the signed container destroys the best evidence it will
ever hold. Signature preservation and verification is therefore a first-class
requirement, not an optional integrity check.

### L5 — The Gazette can be wrong, and correcting it is a formal legal procedure
Correction of errors in published Gazette material ("διόρθωση σφάλματος") is a
formal procedure with statutory basis (Law 3469/2006, Art. 16 §§4–5), operated by
the National Printing House, producing a *further published instrument*.
[ledger: RL-026]

**Architectural consequence.** Text mutation at the source is *lawful and
expected*. A design that treats a digest change on a previously acquired document
as corruption is wrong; a design that treats it as a silent update is worse. The
correction/substitution distinction must be adjudicated, and both the superseded
and the corrected artifact retained.

### L6 — Codification is an institution with its own authority
Greek law provides for codification and law reform through designated organs
(Law 4622/2019, Arts. 65–66, establishing codification of legislation and the
Central Codification Committee), and the codified text has a legal status distinct
from a private consolidation. [ledger: RL-027]

**Architectural consequence.** "Consolidated text" is not one kind. Official
codification, official consolidated republication, and Watchtower-reconstructed
consolidation are three distinct evidentiary and authority classes and must never
share a representation.

### L7 — Cross-order authority is real and non-uniform
European Union law, ECHR jurisprudence and international instruments participate
in the Greek legal order with authority relations that are neither "same as
domestic" nor "merely persuasive". EU-level identity and metadata are carried by
ELI (Council conclusions 2012/C 325/02, 2017/C 441/05, 2019/C 360/01) and case-law
identity by ECLI (Council conclusions 2011/C 127/01). [ledger: RL-003, RL-004,
RL-005]

**Architectural consequence.** Authority is a *relation between an instrument and
a legal order at a time*, not an attribute of a document.

### L8 — Doctrine is not authority
Legal doctrine and theory are inputs to interpretation and are never, by
themselves, binding authority.

**Architectural consequence.** A doctrinal proposition must be architecturally
incapable of being a premise of an authority claim except as an explicitly
defeasible interpretive rule offered to an adjudicating office.

---

## 3. A-AXIOMS (ARCHITECT-ADOPTED)

### A1 — Jurisdictional limit of the Watchtower (generalisation of C3)
**Axiom.** *No component of the Watchtower confers legal authority. Legal authority
is conferred by the legal order. The Watchtower's mandate is limited to observing
the legal order, holding evidence about it, and reconstructing — defeasibly — what
that evidence shows.*

**Justification.** C3 forbids adapters from conferring authority. But an
architecture that forbids it only at the adapter and permits it at, say, a
"normalizer", a "knowledge-graph writer", or an "answering agent" has merely moved
the defect. The only stable form of C3 is a jurisdictional limit on the whole
institution. This axiom also converts the metacognitive requirement C5
("authority boundaries") from a description into a constitutional constraint.

**Falsifier.** If a required capability of the Watchtower can be shown to be
impossible without the system itself determining law (rather than determining what
the evidence shows about law), A1 is too strong and must be weakened with an
explicit, narrow, warranted exception.

**Status.** Adopted. Entrenched (see A10).

### A2 — Monotone record, non-monotone conclusions
**Axiom.** *The institutional record is append-only and monotone. Legal and
epistemic conclusions are non-monotone. Non-monotonicity is expressed exclusively
by appending defeat, correction and reopening entries — never by deletion,
overwrite, or in-place mutation.*

**Justification.** The domain is inherently non-monotone (L5, annulment,
retroactive amendment, defeasible interpretation), while evidentiary integrity
requires monotone history. The only way to have both is to make retraction a
*positive act recorded in the monotone layer*.

**Falsifier.** A required legal operation that cannot be expressed as an append —
e.g. a legally mandated erasure (data-protection erasure of personal data in a
judgment). This is a *real* falsifier and is handled explicitly, not denied: see
PHASE-2-FAILURE-AND-RECOVERY-MODEL.md §9 (redaction under sealed-void semantics).

**Status.** Adopted, with a named, bounded exception.

### A3 — Kernel purity and total order
**Axiom.** *There exists a pure, total, deterministic function K_v such that
`state = K_v(record_prefix, A|_R)` for every prefix of the record, where `A|_R`
is the artifact store restricted to the digests that prefix names.* All nondeterminism —
clock, randomness, network, filesystem, model output — enters only as recorded
entries, never as ambient effect inside K_v.*

**Justification.** Replay, backfill soundness, recovery, reproducible explanation,
and mechanically checkable proof obligations all reduce to this one property. It
is the single load-bearing structural axiom of the architecture.

**Falsifier.** A required derivation that cannot be made total or deterministic
(e.g. an argumentation semantics that is not computable within declared bounds).
This falsifier *fires* — see D08 and defeater DF-014 — and is handled by bounding
the admitted semantics and making incompleteness a first-class status rather than
a silent approximation.

**Status.** Adopted, with a declared incompleteness status.

### A4 — Evidence degrades monotonically under transformation
**Axiom.** *For every transformation `T` and artifact `x`,
`rank(T(x)) ≤ rank(x)` in the evidentiary lattice. No derivation may raise
evidentiary strength. Strength may be raised only by acquiring new evidence, and
only by the office holding the authentication power.*

**Justification.** The dominant failure mode in legal informatics is
strength laundering: an OCR of a scan of a gazette page acquires, through
successive "clean" representations, the apparent status of the gazette itself.
Making degradation a monotone algebraic property makes laundering a *provable*
impossibility rather than a review discipline.

**Falsifier.** A transformation that genuinely increases evidentiary strength
without new evidence. I could construct none: every candidate (e.g. "verified
against a second copy") is in fact *new evidence*, which A4 permits through the
authentication office.

**Status.** Adopted. Proof obligation PO-004.

### A5 — Every temporal legal fact is defeasible and evidenced
**Axiom.** *Dates of publication, commencement, applicability, amendment, repeal
and annulment are adjudicated propositions carrying evidence and defeaters — not
stored scalars.*

**Justification.** L2 and L5. The system will be wrong about dates; a design in
which it cannot *represent* being wrong about a date cannot correct itself and
cannot explain a correction.

**Falsifier.** If treating a date as a scalar never produces a wrong answer in the
Greek order. Falsified in the other direction by L5 (published corrections change
dates after the fact).

**Status.** Adopted.

### A6 — Metacognition must have truth conditions, a falsifier, and a power
**Axiom.** *A self-model proposition is admissible only if it declares (i) a
truth condition expressible over the record, (ii) an executable falsifier, and
(iii) at least one institutional consequence that follows causally from it. A
self-model proposition with no consequence is inadmissible; it is decoration.*

**Justification.** This is the operational content of C4. It is what separates an
"operational self-model with causal effect" from a dashboard. It also gives the
hostile audit a mechanical test: enumerate self-model propositions and check the
triple.

**Falsifier.** A self-model proposition that is clearly required, clearly true,
and has no institutional consequence. Candidate: "the institution was started at
time t." Resolution: such facts are *record facts*, not self-model propositions;
the self-model consists only of claims about the institution's own epistemic and
operational adequacy.

**Status.** Adopted. It is the primary anti-decoration test.

### A7 — Silence and blindness are different, and must be distinguishable
**Axiom.** *The architecture must be able to distinguish "the source published
nothing" from "the Watchtower failed to see what the source published", by
evidence, not by assumption. Any state in which the two are indistinguishable is
an explicit epistemic status (`INDETERMINATE-COVERAGE`) that suppresses
completeness claims.*

**Justification.** This is the sharpest metacognitive requirement latent in C5
("blind spots"). Almost every real system conflates the two and thereby reports
false completeness.

**Falsifier.** A source whose publication process offers no independent structural
signal (no enumeration, no index, no cross-reference, no cadence). For such
sources the axiom cannot be satisfied and coverage must be permanently reported as
`INDETERMINATE-COVERAGE`. This is an accepted, declared limit.

**Status.** Adopted, with declared unsatisfiable cases.

### A8 — Non-authority is testable by deletability
**Axiom.** *A store is non-authoritative if and only if it can be deleted in full
and rebuilt exactly from the record and the artifact store. Any store failing this
test is an authority and is therefore forbidden unless it is the record or the
artifact store.*

**Justification.** C7 forbids duplicate truth but gives no test. Deletability is a
mechanical test that can be *executed* (periodically, in the shell) rather than
merely asserted. It converts "no duplicate truth" from an intention into a
scheduled experiment.

**Falsifier.** A derived store that legitimately holds information not
reconstructible from the record — which would mean the record is incomplete, which
is itself the defect A8 is designed to detect.

**Status.** Adopted. This axiom is the single most useful auditing device in the
design.

### A9 — Machine-learned components hold no institutional power
**Axiom.** *A statistical or language model may occupy exactly two roles:
(i) proposal generator, whose output is written to the **proposal spool** — which
is neither the record nor the artifact store, and is **not an argument of the
derivation kernel** (I-45), so a proposal cannot be a premise because the
derivation cannot see it; and (ii) surface renderer of already-admitted
propositions, whose output can never add propositional content. No model output may enter the
epistemic store except through a deterministic verifier and a warranted act of an
office.*

**Justification.** Direct empirical evidence: the leading commercial
retrieval-augmented legal research tools were measured to produce incorrect or
misgrounded output on 17–33% of queries, against vendor claims of
hallucination-freedom (Magesh et al., *Journal of Empirical Legal Studies*, 2025).
[ledger: RL-030] Under C6 and C7, granting propositional authority to a component
with that error profile is a wrapper around an unresolved capability.

**Falsifier.** A model component with a *mechanically checkable* soundness
guarantee for a specific proposition class. If one existed, it would be a
verifier, and A9 already permits verifiers. So A9 is stable under this falsifier.

**Status.** Adopted.

### A10 — Entrenchment
**Axiom.** *A1, A2, A3, A6, A8, A9 and the exclusivity of the inspection power are
entrenched: they may not be amended by the Watchtower's own amendment procedure.
An entry purporting to amend them is ⊥.*

**Justification.** C7 forbids hidden authority. Without entrenchment, the
amendment power is a hidden universal authority: any invariant can be removed by
first amending the rule that protects it. Entrenchment bounds the amendment power.

**Falsifier / honest limit.** Entrenchment binds the *institution*, not the
*operator*. An operator with write access to the record files can do anything.
Entrenchment is therefore enforced against internal acts, and against external
tampering only to the extent of detection (external anchoring, witness
co-signature). This limit is stated, not concealed. See DF-007.

**Status.** Adopted, with an explicitly stated limit of effect.

### A11 — Interpretation is adjudicated, never computed
**Axiom.** *No interpretive conclusion enters the epistemic store except as the
outcome of a docket in which a contradictory position was actually constructed, or
in which the failure to construct one was recorded with its reason.*

**Justification.** C4 requires "internal adversarial deliberation" as semantics.
The only way to make adversarial deliberation structural rather than aspirational
is to make its absence an admissibility defect.

**Falsifier.** Classes of conclusion for which no contradiction is constructible
(e.g. purely definitional consequences of strict constitutional rules). For these
the docket records "no defeasible step; contradiction not constructible" and that
record is itself checkable — a strict-rule-only derivation is a syntactic
property.

**Status.** Adopted.

### A12 — The record is the institution's memory; the image is only a cache
**Axiom.** *Durable institutional identity resides in the record and the artifact
store. Any in-memory or on-image state, however convenient, is a cache subject to
A8.*

**Justification.** Follows from A3 and A8, but stated separately because the most
attractive Common Lisp persistence idiom — the prevalence/image model — invites
exactly the opposite arrangement, in which the live image *is* the truth. That
arrangement fails A8 and forfeits replay under kernel evolution.

**Falsifier.** A required state that is genuinely un-recordable (e.g. an open
network connection). Such state is *operational*, not institutional, and is
outside A12 by construction.

**Status.** Adopted.

---

## 4. OBJECTIVE VECTOR (DECLARED ONCE, USED EVERYWHERE)

Two **gates** (non-tradeable; failure is disqualifying):

- **G1 Categorical non-confusion** (C2, A1): the eight kinds are distinct, owned,
  and inter-convertible only by warranted acts.
- **G2 Single authority** (C7, A8): exactly one authority per fact class; every
  other store passes the deletability test.

Then a tiered objective vector. Within a tier, objectives trade against one
another only above the materiality threshold; between tiers, a material loss in a
higher tier is never compensated by a gain in a lower tier.

**Tier 1 — legal adequacy**
- O1 *Evidentiary fidelity* — preservation, verification and non-laundering of
  primary evidence, including source-applied signatures (L4).
- O2 *Temporal adequacy* — all legally distinct time axes, at provision
  granularity, with retroactivity, abrogation/annulment and correction (L2, L5).
- O3 *Defeasibility adequacy* — conflict, defeaters, legal meta-norms, reopening.

**Tier 2 — institutional integrity**
- O4 *Metacognitive causality* — A6 triple satisfied for every self-model claim.
- O5 *Determinism and replayability* — A3; exact recomputation; sound backfill.
- O6 *Recovery and durability* — bounded, specified behaviour under each declared
  fault.
- O7 *Blind-spot detection power* — A7; unknown-unknowns are reachable.

**Tier 3 — institutional continuity**
- O8 *Evolvability without semantic regression* — kernel and ontology change with
  discharged regression obligations.
- O9 *Mechanical verifiability* — invariants discharged by a named tool, with the
  unproved residual stated.
- O10 *Explanation quality* — citation, argument structure, disclosed unknowns.
- O11 *Authority containment of ML components* — A9.

**Tier 4 — operational**
- O12 *Liveness adequacy* — lag and throughput sufficient for the Greek corpus.

**Excluded by C8:** implementation effort, delivery time, code volume, monetary
cost, model context size, familiarity, conventional practice. These never appear.

### Materiality thresholds (global)

A difference between a pair of candidates on an objective is **material** iff at
least one of the following holds:

- **M1** it changes the admissibility of at least one legal proposition class;
- **M2** it changes the set of blind spots the system can detect at all
  (not merely how fast);
- **M3** it changes whether an invariant is mechanically checkable versus only
  reviewable;
- **M4** it changes the outcome (not the latency) of recovery after a fault
  enumerated in the failure model;
- **M5** it changes whether a wrong conclusion can be *explained and reopened*
  after the fact;
- **M6** it changes whether an authority boundary is enforced or merely
  conventional;
- **M7** (Tier 4 only) it changes whether a declared lag budget is achievable by
  more than one order of magnitude.

Differences failing all of M1–M7 are **immaterial** and may not be used to break a
tie, to justify a selection, or to defeat a dominance challenge.

---

## 5. ADMISSIBLE CONCLUSION FORM

Per C10, no selection in this phase claims optimality. Every selection is recorded
as:

> Non-dominated among the evaluated frontier candidates under the declared
> constraints and evidence, with residual uncertainty R.

Where a complete candidate domain is *claimed* to be exhaustive (only D09 and D24
approach this), the exhaustiveness argument is stated and is itself listed as a
defeater target.
