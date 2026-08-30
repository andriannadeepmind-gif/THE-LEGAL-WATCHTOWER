# PHASE-2 CANDIDATE ARCHITECTURES

Phase: 2 — BLIND FRONTIER ARCHITECTURE
Date: 2026-08-26
Depends on: PHASE-2-CREATOR-AXIOMS.md, PHASE-2-REQUIREMENTS-AND-INVARIANTS.md

CANDIDATE_IDS: A1 A2 A3 A4 A5 A6 A7 A8
ORIGINAL_SYNTHESES: A6 A7

*(The two lines above are written in a fixed key form because the sealing script
parses them; per second-round audit finding HF-023, a count reported in the seal
must be extractable from the artifact it describes rather than typed into the
sealing script. A6 is the selected original synthesis; A7 was constructed during
dominance challenge and rejected; A1–A5 are reconstructions of existing approaches
and A8 was added by the hostile self-audit, so neither is original to this phase.)*

The system-level architectures considered are exactly those named on the
`CANDIDATE_IDS` line above, which is the canonical source for the count (count in PHASE-2-SEAL.json, derived at sealing time):

- **A1–A5** — complete architectures reconstructed from the strongest
  available public practice and literature (§§1–5);
- **A6 (CDAI)** — the original synthesis, selected (§6);
- **A7 (CCF)** — a second original synthesis, constructed during dominance
  challenge and rejected (§8). It is recorded because a rejected original is
  evidence and a hidden rejected original is not;
- **A8** — the editorial institution, added by the hostile self-audit as an
  omitted contender and evaluated at §9.2.

This exceeds the required "at least three materially distinct complete
architectures plus at least one original synthesis"; the arithmetic is left to the
seal rather than restated here.

Each candidate is reconstructed **at its strongest** — with the best available
answers to the hard problems, not a strawman. Where a candidate's own literature
supplies a fix for an obvious weakness, that fix is included in the reconstruction
before evaluation.

Evaluation uses the gates (G1, G2) and the tiered objective vector O1–O12 declared
in PHASE-2-CREATOR-AXIOMS.md §4, with the materiality thresholds M1–M7.

Scoring notation per objective: `++` strong, `+` adequate, `~` marginal,
`−` materially deficient, `✗` disqualifying.

---

## 1. CANDIDATE A1 — BITEMPORAL LEGAL KNOWLEDGE GRAPH PIPELINE (BLKG)

*The strongest reconstruction of contemporary legal-informatics practice.*

### 1.1 Shape

Source adapters → fetch/normalise → structured legal XML (Akoma Ntoso, per OASIS
Standard 29 Aug 2018 [RL-001]) → identity assignment via ELI URIs [RL-003] and
ECLI for case law [RL-004] → load into a bitemporal store (SQL:2011
system-versioned + application-time period tables [RL-019], or an RDF quadstore
using the FRBR-derived Common Data Model as EUR-Lex Cellar does [RL-006]) →
point-in-time reconstruction service in the manner of legislation.gov.uk [RL-020]
→ SPARQL/API + retrieval-augmented answering → operational dashboards and data
quality metrics.

### 1.2 Strongest form

- Full WEMI modelling (IFLA LRM [RL-029]) so that work/expression/manifestation
  are distinguished rather than collapsed.
- Akoma Ntoso `<mod>`/`<textualMod>` amendment modelling, so amendments are data,
  not diffs.
- System-time versioning gives full "what did we believe when".
- Provenance recorded as W3C PROV-O [RL-007].
- Point-in-time reconstruction validated against official consolidated texts.

### 1.3 Where it genuinely leads

O2 temporal (partially), O10 explanation (citations are native), O12 liveness
(proven at national scale), interoperability (proven).

### 1.4 Where it fails, precisely

- **G1 ✗.** The pipeline collapses `OBSERVATION`, `ACQUISITION`, `EVIDENCE` and
  `AUTHORITY` into "a record loaded from a trusted source". The adapter's
  successful parse *is* the authority claim. This is exactly what C3/A1 forbid.
  Bitemporality records *when we stored it*, never *why we were entitled to
  believe it*.
- **G2 ✗ (contingently).** The store is the authority: delete it and you cannot
  rebuild it, because the transformations are not recorded as a replayable
  derivation. It fails the A8 deletability test.
- **O1 −.** The signed Gazette container (L4) is consumed and discarded at parse
  time. The best evidence the system will ever hold is destroyed in step 2.
- **O3 −.** Bitemporal SQL and RDF have no defeasibility. Conflicting provisions
  are either both present (and the store is inconsistent) or one is deleted (and
  the conflict is lost). Neither is acceptable.
- **O4 ✗.** Metacognition is metrics and dashboards: exactly the form C4 rules
  inadmissible.
- **O5 −.** Replay is not available: the ETL is effectful and not versioned.
- **O7 −.** Blind-spot detection reduces to "job failed" and freshness alarms;
  unknown-unknowns are unreachable (A7 unsatisfiable).
- **O11 −.** In its RAG form, the model is on the answer path with propositional
  authority. Measured hallucination rates of 17–33% for exactly this class of tool
  [RL-030] make this a wrapper around an unresolved capability.

### 1.5 Verdict

**Disqualified at the gates.** Retained as a *component-level* source of proven
technique: WEMI identity, Akoma Ntoso vocabulary, ELI/ECLI identifiers,
point-in-time semantics, PROV vocabulary for export. These are adopted inside the
synthesis as *representations*, never as *authorities*.

---

## 2. CANDIDATE A2 — DETERMINISTIC INSTITUTIONAL STATE MACHINE (DISM)

*The strongest reconstruction of the event-sourced, formally-specified,
deterministically-replayable systems tradition.*

### 2.1 Shape

One totally ordered, hash-chained, append-only log is the system of record. All
state is a pure fold over the log. Replication by Viewstamped Replication
[RL-012]. Recovery is replay from checkpoint (ARIES-style checkpoint/redo
discipline [RL-031]). Log integrity via a Merkle tree with inclusion and
consistency proofs, in the manner of Certificate Transparency [RL-011]. The whole
system is specified in TLA+ and model-checked [RL-016]; correctness is exercised
by deterministic simulation with injected faults, in the manner of FoundationDB
[RL-017]. Ordering by hybrid logical clocks [RL-018].

### 2.2 Strongest form

- The fold function is versioned and content-addressed; conclusions carry the
  version.
- Snapshots are consistent cuts; recovery is analysis/redo.
- Simulation is the *production* scheduler, so replay is exact.
- Anti-entropy over artifact digests, Merkle-compared, in the manner of
  Dynamo-style replica reconciliation.

### 2.3 Where it genuinely leads

O5 determinism `++`, O6 recovery `++`, O9 verifiability `++`, and it satisfies A3
and A8 essentially by construction. It is the strongest available answer to
"durable state, recovery, replay".

### 2.4 Where it fails, precisely

- **O3 ✗.** A fold is monotone in the log but the *state* it computes has no
  defeasibility machinery. Legal conflict, defeat, preference and reopening are
  not expressible; you get "latest write wins", which is legally wrong (a later
  general provision does not automatically defeat an earlier special one).
- **O1 −.** Evidence is "whatever the event payload says". There is no evidentiary
  algebra, no signature preservation obligation, no laundering prohibition.
- **G1 ~.** Event *types* can encode the eight kinds, but nothing enforces
  non-coercion: any handler may synthesise an `AUTHORITY` event from an
  `OBSERVATION` event. Separation is convention.
- **O4 −.** There is no self-model at all; metacognition would have to be bolted
  on and would default to metrics.
- **O7 −.** Gap detection is not addressed; the log knows what entered it, not
  what failed to.
- **O8 −.** Fold-function evolution is the tradition's known open wound: changing
  the fold silently rewrites history on replay. DISM has no principled answer.
- **O10 ~.** Explanations are event traces, not legal arguments.

### 2.5 Verdict

**Not disqualified, but materially deficient on Tier 1 (O1, O3) and Tier 2 (O4,
O7).** Its mechanisms — pure fold, hash-chained log, HLC, VR, Merkle proofs,
deterministic simulation, ARIES-style checkpoint/redo — are adopted wholesale in
the synthesis as the *substrate*. Its failure is that a substrate is not an
institution.

---

## 3. CANDIDATE A3 — NORMATIVE INSTITUTION WITH ARGUMENTATIVE TRUTH MAINTENANCE (NIATM)

*The strongest reconstruction of the normative-multi-agent-systems and AI-and-law
tradition.*

### 3.1 Shape

The system is modelled as a norm-governed institution. Offices are agents holding
**institutionalised power** in the Jones–Sergot sense: designated agents are
empowered to create normative states of affairs by performing specified act types,
and the *counts-as* relation classifies a brute act as an institutional act in a
context [RL-010]. Regulative and constitutive norms are separated. Legal content
is represented in LegalRuleML, which supplies deontic operators, defeasibility,
rule superiority, temporal management of rules and the constitutive/prescriptive
distinction [RL-002]. Reasoning is structured argumentation in the ASPIC+ style:
strict and defeasible rules, three attack forms (premise, undercut, rebut),
preferences, with the rationality postulates of closure and consistency [RL-008].
Belief bookkeeping is a truth maintenance system: justification-based [RL-032] or
assumption-based with environments, labels and minimal no-goods [RL-009]. Norm
change over time uses temporalised defeasible logic, distinguishing abrogation
from annulment and handling retroactivity [RL-013].

### 3.2 Strongest form

- Powers are typed and exclusive; acts without power are void (not merely
  invalid) — the correct reading of institutionalised power.
- The preference relation encodes legal meta-norms as defeasible, attackable
  rules, not hard-coded priorities.
- ATMS environments give "under which assumptions does this hold", which is the
  natural substrate for blind-spot reasoning.

### 3.3 Where it genuinely leads

O3 defeasibility `++`, O1 evidentiary *modelling* `+` (the vocabulary exists),
G1 `++` (kind separation is native — counts-as is precisely a controlled kind
coercion), O10 explanation `++` (arguments are the explanation).

### 3.4 Where it fails, precisely

- **O5 ✗.** Nothing in the tradition addresses determinism or replay. Argumentation
  engines are typically effectful, order-sensitive, and not reproducible across
  versions.
- **O6 −.** Durability and recovery are unaddressed; the tradition assumes a
  knowledge base that exists.
- **O7 −.** Observation, scheduling, coverage and lag are outside its scope
  entirely; it has no theory of *acquiring* the premises.
- **O12 −.** ATMS label computation is worst-case exponential; without an explicit
  bound and a declared-incompleteness status this becomes silent degradation,
  which C7 forbids.
- **O4 ~.** Institutional self-description exists (the institution knows its norms)
  but there is no operational self-model of *epistemic adequacy* — no coverage,
  no lag, no blind spots.
- **O9 ~.** Formal properties are proved *about the logics*, not about *this
  system*.

### 3.5 Verdict

**Not disqualified, but materially deficient on Tier 2 (O5, O6, O7) and Tier 4.**
Its mechanisms — institutionalised power, counts-as, void-without-power,
strict/defeasible rules, three attack forms, preference-based defeat, ATMS
environments and no-goods, abrogation/annulment temporal treatment — are adopted
in the synthesis as the *institutional and epistemic semantics*. Its failure is
that a semantics is not a running institution.

---

## 4. CANDIDATE A4 — CUSTODIAL FEDERATION OF LINKED LEGAL DATA (CFLLD)

*The strongest reconstruction of "do not centralise truth at all".*

### 4.1 Shape

The Watchtower holds no corpus. Each legal source remains the authority over its
own data; the Watchtower holds only (i) a registry of sources and their authority
relations, (ii) resolvable identifiers (ELI/ECLI), (iii) cached provenance
records, and (iv) a federated query planner that resolves questions live against
authoritative endpoints (e.g. the Cellar SPARQL endpoint [RL-006], national
portals). Answers cite live sources. Provenance is by reference, not by copy.

### 4.2 Strongest form

- Aggressive caching with revalidation, so that answers are fast but always
  traceable to a live authoritative fetch.
- A conflict-free replicated cache [RL-033] so that multiple Watchtower nodes
  converge without coordination.
- Full ELI/ECLI resolution so that identity is the source's own identity.

### 4.3 Where it genuinely leads

- **G2 `++` in one specific sense**: it cannot create duplicate *truth*, because
  it holds none. This is a real and under-appreciated strength.
- O1 `+`: it never launders evidence because it never transforms it.
- O8 `++`: nothing to migrate.

### 4.4 Where it fails, precisely

- **O2 ✗.** Point-in-time legal reconstruction is impossible when the source only
  serves "current". The Greek sources do not offer historical point-in-time
  service for most material; a federation over them cannot answer "what was the
  text in force on 2019-11-04".
- **O6 ✗.** Durability is zero: if a source withdraws or silently mutates a
  document (L5), the Watchtower's past answers become unexplainable. It cannot
  retain superseded text (I-13) because it retains nothing.
- **O5 ✗.** Not replayable: an answer cannot be reproduced once the source changes.
- **O7 ✗.** Blind-spot detection is impossible: you cannot detect a gap in a corpus
  you do not hold, and you cannot compare a digest you never stored.
- **O4 ✗.** No epistemic state to model.

### 4.5 Verdict

**Disqualified on Tier 1 and Tier 2.** But it produces one decisive insight that
is carried into the synthesis: *holding a copy is what creates the duplicate-truth
risk*. The synthesis therefore holds copies only as **artifacts with digests and
custody records** (which are evidence *about* the source, not a substitute
authority) and never as a "normalised current view" that could compete with the
source. A4's failure clarifies exactly what a copy is allowed to be.

---

## 5. CANDIDATE A5 — REFLECTIVE AGENTIC ENSEMBLE (RAE)

*The strongest reconstruction of the contemporary LLM-agent approach.*

### 5.1 Shape

A supervisor agent decomposes legal questions; retrieval agents fetch from portals
and a vector index; extraction agents parse instruments; a critic agent attacks
conclusions; a memory agent maintains episodic and semantic memory; a
meta-controller monitors reasoning traces and re-plans on impasse, in the manner
of a metacognitive dual-cycle architecture with a ground level, an object level
and a meta-level for introspective monitoring and metacognitive control [RL-034],
[RL-035]. Tool use is mediated; all outputs carry citations.

### 5.2 Strongest form

- The meta-level is a genuine metareasoning layer with declarative traces of
  cognitive activity, not prompt self-reflection.
- The critic is adversarial by mandate and its objections are retained.
- Citations are verified by a deterministic resolver before emission.

### 5.3 Where it genuinely leads

O10 surface explanation `+`, adaptability `++`, coverage of unstructured material
(doctrine, commentary) `++`. It is the only candidate with a credible answer to
*reading messy Greek legal prose at scale*.

### 5.4 Where it fails, precisely

- **G1 ✗.** Agents freely coerce kinds: a retrieval agent's output becomes a
  premise. There is no structural barrier.
- **G2 ✗.** Memory is a second truth. Semantic memory competes with the corpus and
  neither is authoritative.
- **O1 ✗.** No evidentiary algebra; text passed between agents loses its container
  and its signature at the first hop.
- **O5 ✗.** Non-deterministic by construction; replay impossible; the same query
  can yield different answers with no recorded reason.
- **O11 ✗.** The model *is* the authority. Directly contradicted by measurement:
  leading commercial legal RAG tools produce incorrect or misgrounded output on
  17–33% of queries against vendor claims of hallucination-freedom [RL-030].
- **O4 ~.** The meta-level monitors *reasoning*, not *epistemic adequacy about the
  world*: it can detect "I am stuck" but not "I am missing ΦΕΚ Α′ issue 212 of
  2024". This is the crucial distinction between metareasoning and institutional
  metacognition, and it is why A5's meta-level does not satisfy A6.

### 5.5 Verdict

**Disqualified at the gates.** Two things are carried into the synthesis:
(i) the dual-cycle insight that the meta-level must have *declarative traces of
cognitive activity* as first-class data [RL-034] — the synthesis makes those
traces record entries; (ii) LLMs are retained, confined by A9 to proposal
generation and surface rendering, because the alternative (no statistical
component at all) would materially reduce reachable coverage of unstructured
Greek legal prose, and that reduction is material under M2.

---

## 6. ORIGINAL SYNTHESIS — CHARTERED DETERMINISTIC ADJUDICATIVE INSTITUTION (CDAI)

*Selected. Fully specified in PHASE-2-FRONTIER-ARCHITECTURE.md.*

### 6.1 What the synthesis has to resolve

A2 and A3 are the strong candidates and they are in genuine tension. The
synthesis is not "A2 + A3"; it is the resolution of four specific contradictions
between them. Naming them precisely is the substance of the synthesis:

**Contradiction 1 — monotone log vs non-monotone law.**
A2 requires an append-only monotone record; A3 requires retraction and defeat.
*Resolution:* separate the **record** (monotone, append-only, the system of
record) from the **conclusion state** (non-monotone, fully derived). Retraction is
expressed as *appending a defeat*. Non-monotonicity lives entirely inside the pure
derivation function; the record never shrinks. This is A2 (Axioms).

**Contradiction 2 — deterministic replay vs live evolution.**
A2's fold must be fixed for replay to mean anything; A3's legal ontology and
interpretive rules must evolve.
*Resolution:* **versioned interpretation**. `state = K_v(R, A|_R)` is parameterised
by kernel version `v`. Changing `v` does not rewrite history; it produces a second
interpretation of the same record. The *difference between interpretations* is a
first-class object (a `DIVERGENCE`) that must itself be adjudicated. Promotion of
`v'` requires discharging the regression obligation I-32. This is the synthesis's
answer to "evolution without semantic regression", and neither parent has it.

**Contradiction 3 — single writer vs separation of powers.**
A2 wants one append point (for order); A3 wants many independent powers.
*Resolution:* **one physical order, many constitutional authorities.** There is a
single logical order over the record, but admissibility is gated by the Charter:
an entry is admissible only if its issuing office holds the power to issue an
entry of that kind, evidenced by a warrant checked at admission. Powers are
*exclusive* per fact class (I-09, PO-009). One truth, many powers, no duplicate
authority.

**Contradiction 4 — where does metacognition live?**
A2 has none; A3 has institutional self-description but no epistemic self-model;
A5 has metareasoning without world-adequacy.
*Resolution:* the self-model is **propositions in the same epistemic store**,
derived by the same kernel, defeasible by the same mechanics — plus the A6 triple:
truth condition, executable falsifier, institutional consequence. Causation is
structural: the observation plan is a *derived function of self-model propositions*
(I-22), and the Inspectorate's finding of procedural invalidity *suspends* the
publication power (I-23). Metacognition that can neither be falsified nor change
what the institution does is, by A6, inadmissible.

### 6.2 Shape in one paragraph

A chartered institution of offices holding exclusive typed powers, writing warranted
entries of eight distinct kinds into a single append-only, hash-chained,
HLC-stamped record; artifacts held immutably by content address with their source
signatures preserved; all state — legal, epistemic, and self-model — derived by a
pure, versioned, ACL2-admissible kernel that computes assumption-labelled,
argumentation-adjudicated beliefs; decisions taken in dockets with mandatory
contradiction and executable reopening predicates; observation planned as a
derived consequence of the self-model; blind spots detected by enumeration
closure, reference closure and cadence analysis with independent source-vitality
probes to separate source silence from self-blindness; publication gated by
support strength, coverage status, and the Inspectorate's suspension power; the
whole running on a deterministic logical scheduler that is the same in production
and in simulation.

### 6.3 Scoring

| | G1 | G2 | O1 | O2 | O3 | O4 | O5 | O6 | O7 | O8 | O9 | O10 | O11 | O12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A1 BLKG | ✗ | ✗ | − | + | − | ✗ | − | + | − | ~ | ~ | + | − | ++ |
| A2 DISM | ~ | ++ | − | ~ | ✗ | − | ++ | ++ | − | − | ++ | ~ | n/a | ++ |
| A3 NIATM | ++ | ~ | + | ++ | ++ | ~ | ✗ | − | − | ~ | ~ | ++ | n/a | − |
| A4 CFLLD | + | ++ | + | ✗ | ~ | ✗ | ✗ | ✗ | ✗ | ++ | ~ | + | + | + |
| A5 RAE | ✗ | ✗ | ✗ | − | ~ | ~ | ✗ | − | ~ | + | − | + | ✗ | + |
| **A6 CDAI** | **++** | **++** | **++** | **++** | **++** | **++** | **++** | **++** | **++** | **+** | **+** | **++** | **++** | **~** |

CDAI's honest weaknesses are recorded, not hidden:

- **O12 `~`** — the derived-state model with adjudicated temporal facts and
  assumption labelling is materially more expensive than a bitemporal table
  lookup. Accepted because (a) C8 excludes cost and effort from the objective
  vector, and (b) under M7 the difference is not an order-of-magnitude threat at
  the declared corpus scale (OA-4), which is itself a falsifiable operating
  assumption (DF-021).
- **O8 `+` not `++`** — the regression obligation is only as strong as the
  designated regression corpus. A change that is correct on the corpus and wrong
  off it is not caught. Bounded, not eliminated (DF-019).
- **O9 `+` not `++`** — the proof boundary is real but partial; the properties
  that are explicitly unproved are enumerated canonically in Requirements Part X
  and are neither re-listed nor re-counted here.

### 6.4 Verdict

**Non-dominated among the evaluated frontier candidates under the declared
constraints and evidence.** See PHASE-2-NON-DOMINANCE.md for the formal
non-dominance argument and the enumeration of what would defeat it.

---

## 7. WHY THE SYNTHESIS IS NOT A RELABELLING

The acceptance contract disqualifies "a conventional pipeline with renamed
components". The structural properties below have no counterpart in any of
A1–A5 and cannot be obtained by renaming:

1. **Voidness as the enforcement primitive.** An unwarranted act does not fail, it
   has *no institutional effect*. Implemented by a method combination in which the
   `:warrant` qualifier group must unanimously succeed before any primary method
   runs, so unwarranted acts cannot execute at all (D02, Lisp design §3).
2. **Deletability as the test of non-authority (A8).** A scheduled experiment that
   deletes a derived store and rebuilds it. No candidate has a *test* for
   duplicate truth; they have intentions.
3. **Decisions that carry their own falsifiers (I-26).** A decision is inadmissible
   unless it names a decidable predicate whose truth reopens it. This converts
   "institutional memory" from storage into a control mechanism.
4. **Silence/blindness separability (A7, I-24).** A named epistemic status for
   "cannot distinguish", plus content-independent vitality probes to resolve it.
   No candidate distinguishes these; all of them silently report coverage.
5. **Monotone evidentiary degradation as a theorem (A4, PO-004).** Not a review
   rule: an ACL2 theorem over a closed transformation algebra.

Each is mechanically checkable, which is what makes them structural rather than
rhetorical.

---

## 8. REJECTED ORIGINAL SYNTHESIS — CHARTERED CUSTODIAL FEDERATION (CCF)

Constructed during the dominance challenge on the durable-state decision (D10),
as an attempt to dominate CDAI by combining CDAI's charter with A4's refusal to
hold a corpus.

**Shape.** Charter, offices, powers, dockets and self-model exactly as CDAI, but
the Watchtower holds no artifacts: it holds only observation records, digests,
signatures and custody *attestations by third parties*, resolving content on
demand from the source or from an external preservation service.

**Claim.** Strictly better on G2 (cannot possibly hold a competing truth) and on
storage cost, no worse elsewhere.

**Why it fails.** It is *not* no-worse elsewhere. Three material losses:

- **O1 (M1).** Under L5, sources lawfully replace published text. Without custody
  of the superseded bytes, I-13 is unsatisfiable and past answers become
  unexplainable — a change in the admissibility of propositions about *what was
  published*, which is material under M1.
- **O7 (M2).** Digest-based anti-entropy requires holding the artifact to detect a
  silent substitution against a *retained* copy; an attestation by the source that
  the source has not changed is not independent evidence. This removes a whole
  class of detectable blind spot: material under M2.
- **O5 (M4/M5).** Replay of a derivation requires the input bytes. Without custody,
  `state = K_v(R, A|_R)` is false: there is no `A` to restrict, so the record
  would not determine the state.
  A3 (Axioms) fails outright.

**Disposition.** Rejected. The challenge did, however, sharpen CDAI: it forced the
explicit statement that a held artifact is **evidence about the source, never a
substitute authority for it** (Frontier Architecture §4.4), and it produced the
custody-attestation mechanism which CDAI adopts as an *additional* integrity
control rather than a replacement for custody.

**Recorded as:** dominance-challenge iteration DC-10-2, failed.

---

## 9. CANDIDATE-DOMAIN COMPLETENESS

The system-level candidate domain is **not** claimed exhaustive. The six evaluated
architectures were chosen to span four orthogonal axes, and the axes are stated so
that an omitted contender can be identified as a gap:

| Axis | Poles | Covered by |
|---|---|---|
| Truth location | centralised corpus ↔ no corpus | A1/A2/A3/A5 ↔ A4 |
| Reasoning discipline | monotone computation ↔ defeasible adjudication | A1/A2 ↔ A3 |
| Determinism | deterministic ↔ stochastic | A2 ↔ A5 |
| Authority structure | flat/implicit ↔ chartered/exclusive | A1/A2/A5 ↔ A3/A6 |

A contender occupying a cell none of these covers would be a genuine omission. The
hostile self-audit searched for omissions and found two worth naming.

### 9.1 HF-004 — The human-institution-first architecture

An architecture in which a human jurist office holds final interpretive authority
and the machine is purely an evidentiary instrument. This is **not a rival** to
CDAI; it is a *constraint CDAI must satisfy*. It forced two changes: the adoption
of axiom A1 (jurisdictional limit of the whole institution, not merely of adapters)
and the creation of the Rapporteur office with mandatory review of declared
high-consequence classes and standing power to reopen any docket (D19, iteration
DC-19-2).

### 9.2 HF-005 — The editorial institution (added by the hostile self-audit)

**The candidate.** The strongest *existing* answer to point-in-time legislation is
not a system at all: it is an editorial institution — trained legal editors
applying amendments to a revised corpus, with software as a work tool and an
editorial backlog as the accepted cost. The UK service is the visible instance: it
maintains as-enacted, revised and point-in-time versions with per-provision
timelines, and its coverage carries a documented start date and an editorial lag
[RL-020].

**Why the first pass missed it.** Candidate A1 reconstructed the *software* of that
model and scored it as a pipeline, which silently assumed away the editors. That is
a real defect in the first pass: it evaluated the artifact and not the institution.

**Evaluation.** Against the declared objectives, the editorial institution is:

- materially **better** on O10 (explanation quality — a competent editor's
  consolidation is more useful than any current automated reconstruction) and on
  legal correctness of individual reconstructions;
- materially **worse** on O5 (M4) — editorial judgements are not replayable and
  the reasons are usually not recorded in machine-checkable form;
- materially **worse** on O7 (M2) — an editorial backlog is a known-unknown, but
  an editor cannot detect a gazette issue that never reached the desk; there is no
  enumeration-closure mechanism;
- materially **worse** on O4 (M6) — the institution's self-knowledge is the
  editors' knowledge, which is neither queryable nor falsifiable by the system;
- materially **worse** on O2 at scale (M1) — per-provision commencement across a
  full national corpus is precisely what exceeds editorial throughput, which is why
  coverage start dates and backlogs exist.

It does not dominate CDAI. But the honest conclusion is stronger than that:
**CDAI does not eliminate editorial labour and does not claim to.** The Rapporteur
office *is* the editorial function, given a constitutional position, a bounded
mandate, and a machine that (i) tells it where to look, (ii) records why it decided
what it decided, and (iii) reopens its decisions when their basis changes. The
correct description of CDAI is not "an autonomous replacement for legal editors"
but "an institution in which editorial judgement is scarce, located, recorded and
falsifiable."

Recorded as hostile-audit finding HF-005; closed by this evaluation plus the
scope correction in PHASE-2-REPORT.md §5.
