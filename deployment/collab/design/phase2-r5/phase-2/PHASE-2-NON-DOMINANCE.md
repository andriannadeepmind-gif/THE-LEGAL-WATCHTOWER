# PHASE-2 NON-DOMINANCE

Phase: 2 — BLIND FRONTIER ARCHITECTURE
Date: 2026-08-26

This document states the exact claim made about the selected architecture, proves
it in the only sense in which it is provable here, and enumerates precisely what
would defeat it.

---

## 1. THE CLAIM, STATED EXACTLY

> **CDAI is non-dominated among the evaluated frontier candidates under the
> declared constraints and evidence.**

This is **not** a claim that CDAI is optimal. Per creator axiom C10, optimality
would require a complete formal candidate domain and a mechanically checked proof.
Neither exists at the system level, and neither is claimed.

### 1.1 Definitions

Let `C` be the evaluated candidate set, `G = {G1, G2}` the gates, `O = {O1…O12}`
the objectives, `T(o)` the tier of objective `o`, and `M` the materiality
predicate (M1–M7).

**Candidate `x` dominates candidate `y`** iff:

1. `x` passes every gate that `y` passes, and
2. for every objective `o ∈ O`, `x` is not materially worse than `y` on `o`, and
3. there exists an objective `o*` on which `x` is materially better than `y`, and
4. no material loss suffered by `y` relative to `x` sits in a strictly higher tier
   than the gain `o*` — i.e. tier ordering is respected.

**`x` is non-dominated in `C`** iff no `y ∈ C` dominates `x`.

Condition (4) is what makes the tiering operative: a Tier 4 gain never compensates
a Tier 1 loss, so a faster architecture that cannot represent per-provision
commencement does not dominate a slower one that can.

### 1.1.1 Gate G2 is decided by axiom A8, and A8 is a *test*, not a judgement

*(Added in the third audit round, finding HF-030. G2 — "single authority" — was
applied in §3 as a qualitative reading of each candidate. Axiom A8 exists precisely
because "no duplicate truth" is otherwise unfalsifiable, and it was not being used
in the comparison that most needed it.)*

**A8 (deletability).** A store is non-authoritative **iff** it can be deleted in
full and rebuilt exactly from `K_v(R, A|_R)`. Any store failing this test *is* an
authority.

G2 is therefore evaluated by a decision procedure, applied identically to every
candidate:

```
for each store S in the candidate:
    classify S as {declared authority | derived | scratch}
    if derived:   is S rebuildable from the candidate's own record + artifacts?
    if authority: is it (a) enumerated, (b) verifiable, (c) bounded?
    if scratch:   does deleting S change answers?
G2 PASSES iff every store lands in exactly one class and satisfies its obligation.
```

Three consequences for the comparison, all of which change §3:

- **A8 is applicable to candidates that never heard of it.** Nothing about the test
  presupposes CDAI's design; it asks only whether a store's contents are a function
  of that candidate's own inputs. So it can be run against A1–A5 and A7 fairly.
- **A8 discriminates where prose does not.** "The knowledge graph is the system of
  record" and "the knowledge graph is a derived index" are the same sentence until
  someone tries the delete.
- **Passing A8 is not free.** A candidate that passes trivially because it holds
  nothing (A4, A7) buys G2 at Tier-1 cost elsewhere, and the tier rule (condition 4)
  then decides — which is exactly what §3.4 and §3.6 turn on.

A8 verdicts are recorded per candidate in §2 and carried into each pairwise
argument in §3.

### 1.2 Scope of the claim

Non-dominance is relative to three things, all declared in advance and all open to
attack:

- **the evaluated set** `C` (enumerated in §2; count in the seal);
- **the objective vector and its ordering** (Axioms §4);
- **the evidence** (PHASE-2-RESEARCH-LEDGER.jsonl; source count in the seal).

Change any of the three and the claim must be re-established. It is stated this way
so that Phase-3 adversarial judging attacks a defined target rather than a mood.

---

## 2. THE EVALUATED SET

| ID | Architecture | **A8 verdict (decides G2)** | Disposition |
|---|---|---|---|
| A1 | Bitemporal Legal Knowledge Graph Pipeline | **FAILS.** The store is the only copy of the normalised legal state; the transformations that produced it are effectful and unversioned, so deleting it is unrecoverable. It is an authority that is not declared as one. | disqualified at G1 and G2 |
| A2 | Deterministic Institutional State Machine | **PASSES** for derived state (pure fold over a log). Silent on artifacts: the tradition has no notion of an artifact store, so byte custody is undeclared and therefore unclassified. | admissible; materially deficient Tier 1 & 2 |
| A3 | Normative Institution with Argumentative Truth Maintenance | **NOT DECIDABLE.** The tradition specifies a knowledge base, not a derivation from inputs, so there is nothing to rebuild *from*. G2 cannot be established either way. | admissible; materially deficient Tier 2 & 4 |
| A4 | Custodial Federation of Linked Legal Data | **PASSES TRIVIALLY** — holds no corpus, so there is nothing that could be a second authority. Bought at Tier-1 cost (§3.4). | disqualified at Tier 1 & 2 |
| A5 | Reflective Agentic Ensemble | **FAILS.** Agent memory is not a function of any recorded input and cannot be rebuilt; it is a second truth competing with the corpus. | disqualified at G1, G2, O11 |
| A6 | **CDAI (original synthesis)** | **PASSES, and the test is scheduled.** Two declared authorities (`R`; `A`, which is verifiable by content address and bounded by I-43/I-47), one scratch area (`P`, whose deletion must change nothing), everything else rebuildable from `K_v(R, A\|_R)` and periodically *actually deleted and rebuilt* (I-31). | selected |
| A7 | Chartered Custodial Federation (second original synthesis) | **PASSES TRIVIALLY**, as A4 — and for the same reason fails A3 (Axioms) outright, since replay needs the bytes (§3.6). | constructed during dominance challenge; rejected |
| A8 | The editorial institution | **NOT APPLICABLE.** The authoritative store is the editors' judgement, which is not a store. Coverage and revision state are not reconstructible from any recorded input, so G2 is not assessable and O4 is unreachable (Candidates §9.2). | added by hostile self-audit; does not dominate |

**Note on the identifier collision.** `A8` names both an evaluated architecture
(the editorial institution) and an axiom (non-authority by deletability). They are
disambiguated by context throughout: an architecture row in a table, an axiom in
running prose. The collision is recorded rather than renamed because both
identifiers are used across the sealed package and renaming either would break
references in artifacts that are already hashed.

---

## 3. PAIRWISE NON-DOMINANCE ARGUMENT

For CDAI to be dominated, some candidate must be **no materially worse on every
objective** and **materially better on at least one**, with tier ordering
respected. Each pair is disposed of by naming a specific objective on which the
challenger is materially worse.

### 3.1 A1 (BLKG) does not dominate CDAI

A1 is materially better on **O12** (liveness — proven national-scale performance)
and arguably on integration effort, which is excluded by C8.

A1 is materially worse on:

- **G1** — the adapter's successful parse *is* the authority claim; there is no
  barrier between `OBSERVATION` and `AUTHORITY`. Gate failure ends the analysis.
- **G2, by the A8 test** — delete the store and it cannot be rebuilt, because the
  transformations that produced it are effectful and unversioned. It is an
  undeclared authority. This is not a reading of A1's intentions; it is the
  outcome of running the decision procedure of §1.1.1 against it.
- **O1** (M1) — the signed Gazette container is consumed and discarded at parse
  time (L4, [RL-024]).
- **O3** (M1) — bitemporal stores and RDF have no defeasibility; a conflict is
  either an inconsistency or a deletion.
- **O4** (M6) — metacognition is metrics and dashboards, which C4 rules
  inadmissible.
- **O7** (M2) — unknown-unknowns are unreachable.

O12 is Tier 4; the losses are Tier 1 and Tier 2. Condition (4) fails. **Not
dominating.**

### 3.2 A2 (DISM) does not dominate CDAI

A2 is not materially better than CDAI on any objective. CDAI *adopts* A2's
substrate wholesale — pure fold, hash-chained log, HLC, Merkle proofs, VR,
ARIES-style checkpoint/redo, deterministic simulation — so A2's strengths (O5, O6,
O9) are matched, not exceeded.

A2 is materially worse on:

- **O3** (M1) — a fold has no defeat, no preference, no reopening; "latest write
  wins" is legally wrong.
- **O1** (M1) — no evidentiary algebra, no signature-preservation obligation, no
  laundering prohibition.
- **O4** (M6) — no self-model at all.
- **O7** (M2) — the log knows what entered it, not what failed to.
- **O8** (M5) — changing the fold silently rewrites history on replay; the
  tradition has no principled answer, and versioned interpretation (CDAI §18.1) is
  precisely the answer A2 lacks.
- **G2 is only half-established.** A2 passes the A8 test for *derived state* — a
  pure fold is rebuildable by construction — but has no notion of an artifact
  store at all, so byte custody is undeclared and unclassified. CDAI's `A` is a
  declared authority with a verifiability property (content address) and a
  boundedness property (I-43, maintained by the staged-promotion protocol I-47).
  A2 does not so much fail this as never reach it.

**Not dominating** — and it is the closest case, because A2's substrate is
excellent. The distance is entirely in the institutional and epistemic layers.

### 3.3 A3 (NIATM) does not dominate CDAI

A3 is not materially better on any objective. CDAI adopts its semantics —
institutionalised power, counts-as, void-without-power, strict/defeasible rules,
three attack forms, ATMS environments and no-goods, abrogation/annulment temporal
treatment — so A3's strengths (G1, O3, O10) are matched.

A3 is materially worse on:

- **O5** (M4) — no determinism, no replay; argumentation engines are typically
  order-sensitive.
- **O6** (M4) — durability and recovery unaddressed.
- **O7** (M2) — no theory of *acquiring* premises: no observation, scheduling,
  coverage or lag.
- **O12** (M7) — unbounded label computation without a declared-incompleteness
  status is silent degradation, which C7 forbids.
- **G2 is not decidable for it.** The A8 test asks whether a store is a function
  of recorded inputs; A3 specifies a knowledge base, not a derivation, so there is
  nothing to rebuild *from*. This is the sharpest way to state A3's gap: it has a
  semantics of belief and no semantics of provenance-to-belief.

**Not dominating.**

### 3.4 A4 (CFLLD) does not dominate CDAI

A4 is materially better on **O8** (nothing to migrate) and holds a genuine G2
advantage in one specific sense: a system holding no corpus cannot hold a competing
truth.

A4 is materially worse on:

- **O2** (M1) — point-in-time reconstruction is impossible when sources serve only
  "current".
- **O6** (M4) — no durability; withdrawn or mutated source material makes past
  answers unexplainable (I-13 unsatisfiable).
- **O5** (M4) — answers cannot be reproduced once the source changes.
- **O7** (M2) — you cannot detect a gap in a corpus you do not hold, or compare a
  digest you never stored.

**A8 verdict.** A4 passes trivially — holding no corpus, it cannot hold a second
authority. This is a *real* G2 advantage over CDAI, which passes by scheduled
experiment rather than by vacuity. But the tier rule decides: the losses above are
Tier 1 and Tier 2, the gain is Tier 3 plus a vacuous-pass on a gate CDAI also
passes. Condition (4) fails.

O8 is Tier 3; the losses are Tier 1 and Tier 2. **Not dominating.**

### 3.5 A5 (RAE) does not dominate CDAI

A5 is materially better on **coverage of unstructured prose** — a real advantage,
which CDAI *retains* under A9 confinement by using models as proposal generators.

A5 is materially worse on:

- **G1, G2** — agents coerce kinds freely; memory is a second truth. Gate failure.
- **O5** (M4) — non-deterministic; the same query can yield different answers with
  no recorded reason.
- **O11** (M1) — the model is the authority, against measured error rates of
  17–33% for exactly this tool class [RL-030].
- **O1** (M1) — no evidentiary algebra; containers lost at the first hop.
- **G2, by the A8 test** — agent memory is not a function of any recorded input
  and cannot be rebuilt from one. It is a second truth competing with the corpus,
  and the test says so mechanically rather than by argument.

**Not dominating.**

### 3.6 A7 (CCF) does not dominate CDAI

This is the important case, because A7 was constructed *specifically* as a
dominance challenge and is CDAI's nearest neighbour: identical charter, offices,
dockets and self-model, differing only in refusing custody of artifacts.

A7 claims to be strictly better on G2 and on storage. Storage is excluded by C8.
On G2 the claim is real but small: CDAI already passes G2 by the deletability test,
so the improvement is from "passes with a test" to "passes trivially".

A7 is materially worse on:

- **O1** (M1) — under L5 sources lawfully replace text [RL-026]; without custody of
  superseded bytes I-13 is unsatisfiable and past answers become unexplainable.
- **O7** (M2) — digest anti-entropy requires a retained copy; a source's attestation
  that it has not changed is not independent evidence. An entire class of
  detectable blind spot disappears.
- **O5** (M4/M5) — replay requires the input bytes; without custody
  `state = K_v(R, A|_R)` is false, and axiom A3 fails outright.

**Not dominating.** Recorded as dominance-challenge iteration DC-10-2, failed.

### 3.7 A8 (the editorial institution) does not dominate CDAI

*(Added in the third audit round: A8 was evaluated in Candidates §9.2 but was never
carried into this document, so the formal comparison omitted a candidate the
package claimed to have compared.)*

A8 is materially better on **O10** — a competent legal editor's consolidation is
more useful and more reliably correct than any current automated reconstruction —
and on the legal correctness of individual reconstructions.

A8 is materially worse on:

- **O5** (M4) — editorial judgements are not replayable, and the reasons are
  usually not recorded in machine-checkable form.
- **O7** (M2) — an editorial backlog is a *known* unknown; an editor cannot detect
  a Gazette issue that never reached the desk. There is no enumeration-closure
  mechanism, so the whole class of unknown-unknowns is unreachable.
- **O4** (M6) — the institution's self-knowledge *is* the editors' knowledge:
  neither queryable, nor falsifiable by the system, nor capable of suspending
  publication automatically.
- **O2** (M1) at national scale — per-provision commencement across a full corpus
  is exactly what exceeds editorial throughput, which is why coverage start dates
  and backlogs exist in practice [RL-020].
- **G2, by the A8 test** — **not assessable.** The authoritative store is human
  judgement, which is not a store, so the deletability procedure has nothing to run
  against. This is not a technicality: it is the same fact as O4's failure, seen
  from the gate side.

O10 is Tier 3; the losses are Tier 1 and Tier 2. Condition (4) fails. **Not
dominating.**

**But the honest conclusion is stronger than "not dominating".** CDAI does not
eliminate editorial labour and does not claim to. The Rapporteur office *is* the
editorial function, given a constitutional position, a bounded mandate, and a
machine that tells it where to look, records why it decided, and reopens its
decisions when their basis changes. A8's real contribution to this comparison was
to force that scope correction (HF-005), not to contest the selection.

---

## 4. WHAT THE CHALLENGES ACTUALLY CHANGED

Non-dominance would be worthless if the process were ceremonial. Counts of challenges by outcome are derived at sealing time and recorded in PHASE-2-SEAL.json rather than restated here (second-round finding HF-023). What matters is which selections actually changed:

| Decision | Provisional | Replaced by | Why |
|---|---|---|---|
| D02 | runtime assertions at entry points | custom method combination | check becomes a property of the generic function, not of a body |
| D05 | bitemporal | nine-axis adjudicated | per-provision commencement and ex tunc/ex nunc are inexpressible in two axes |
| D06 | PROV as the internal model | native typed lineage | degradation is not expressible in PROV |
| D08 | ATMS alone | ATMS + ASPIC+ + declared incompleteness | labels say *under what assumptions*, never *which reading wins and why* |
| D10 | prevalence (image is truth) | record + artifacts + derived state | prevalence fails A12 and makes A8 inapplicable |
| D11 | hash chain | Merkle + witnesses + qualified time anchor | changes fault F12 from undetectable to detectable |
| D15 | triadic detection | + vitality probes | silence and blindness were otherwise indistinguishable |
| D18 | self-model read by planner | + falsifiers + suspension power | a self-model that cannot be falsified and cannot act is a dashboard |
| D19 | docket with contradiction | + executable reopening predicates | memory becomes a control mechanism rather than an archive |
| D20 | TLA+ only | ACL2 + Alloy + TLA+ + simulation | a single TLA+ model says nothing about kernel functional correctness |
| D25 | free redefinition | warranted redefinition + regression | free redefinition changes admitted meanings with no record |

The remaining twelve successful challenges *amended* a selection rather than
replacing it — for example adding parallel read-only derivation to D13,
third-party custody attestations to D06, recorded environment traces to D14,
portable threading primitives to D21, explicit `UNKNOWN`/`CONDITIONAL` interval
endpoints to D05, and cross-channel corroboration to D15.

Every failed challenge records a specific reason tied to a named
materiality threshold. Those reasons — not the counts — are the falsifiable
content, and a hostile reviewer should attack them.

The strongest failed challenge is **DC-08-5**: substituting sceptical Defeasible
Logic for the ASPIC+ adjudication layer, which would have made the epistemic
kernel linear-time, trivially total, ACL2-admissible without a bound, and would
have eliminated both the `SEMANTICS-INCOMPLETE` and `LABEL-INCOMPLETE` statuses.
Those gains are real and material. It fails only because a proof tag is not an
argument: R-10 requires every answer to carry the defeaters considered and their
disposition, and the three attack forms collapse into rule-level superiority, so
the institution could report that a reading lost but not on which ground. This
challenge was raised by the hostile self-audit (HF-017), not by the first pass,
which is itself a finding about the first pass.

---

## 5. WHAT WOULD DEFEAT NON-DOMINANCE

Non-dominance falls if any of the following is established.

### 5.1 A dominating candidate

A candidate that passes G1 and G2, is no materially worse on O1–O12, and is
materially better on at least one with tier ordering respected. The most credible
direction is **DF-033**: a materially simpler design that still satisfies the gates
and Tier 1. Nothing in this phase establishes that the full apparatus is *necessary*
rather than merely *sufficient*; necessity would require showing, for each office
and each invariant, a concrete question that becomes unanswerable without it. That
demonstration was not made, and its absence is the single strongest attack
available.

### 5.2 Confirmation of an open defeater

The OPEN defeaters (enumerated in the seal) are the live attack surface. DF-026 is
BOUNDED — condition WC-7 was structurally remedied — and **DF-043 is the deepest
OPEN technical residual**. Confirming any of these materially degrades a Tier 1–3
objective and could reverse a selection:

| Defeater | Objective degraded | Effect if confirmed |
|---|---|---|
| DF-007 operator tampering defeats entrenchment | O1 | integrity reduces to trusting the operator |
| DF-011 ACL2↔SBCL correspondence fails | O9 | CDAI drops to A2/D20-d level on verifiability; D20, D21 re-open |
| DF-016 meta-norm ordering is legally wrong | O3 | systematic conflict-resolution error |
| DF-018 assumption vocabulary incomplete | O3, O7 | defeat fails to propagate to some beliefs |
| DF-021 corpus scale exceeds budget | O12 → O2, O5 | D05 and D10 re-open |
| DF-023 no signal for jurisprudence sources | O7 | permanent indeterminate coverage for case law |
| DF-043 common-mode failure across the two kernels (shared specification, substrate, prover, decoders) | O4, O9 | the two-kernel remedy bounds implementation error but not specification error; the specification itself would need an independent check |
| DF-033 apparatus disproportionate | all | dominated; replace |
| DF-042 genesis cannot legitimate; entrenchment makes founding error irreversible | O4, O8 | the entrenchment set itself becomes a decision to attack, not a given |

### 5.3 A different objective ordering

The tiering is a normative choice. If evidentiary fidelity, temporal adequacy and
defeasibility were *not* Tier 1 — for example if the institution's real mandate
were rapid current-awareness rather than reconstruction — then A1 would likely
dominate CDAI. The ordering is therefore declared in advance (Axioms §4) and is
itself an attack surface. This is the honest statement: **non-dominance is
conditional on the objective ordering, and the ordering is a judgement.**

### 5.4 A falsified operating assumption

OA-1 through OA-5 are declared and falsifiable. OA-4 (corpus scale) is the one
carrying live architectural weight and is unmeasured (DF-021).

---

## 6. WHAT IS *NOT* CLAIMED

1. **Not optimal.** No complete candidate domain, no mechanically checked
   optimality proof (C10).
2. **Not exhaustive.** The candidate domain is spanned along four stated axes, not
   enumerated. Two decision-level domains (D09 conflict-resolution policy, D24
   error-propagation discipline) are argued *near*-exhaustive with the argument
   given; even there the conclusion is non-dominance.
3. **Not proved correct.** The proof obligations are assigned across the tool set
   named in Requirements Part IX; the properties that remain unprovable are enumerated canonically as
   UP-1…UP-10 in Requirements Part X and are not re-counted here.
4. **Not free of regression risk.** The regression obligation bounds semantic
   regression to the designated corpus, no further (DF-019).
5. **Not the final architecture.** This is a blind frontier candidate for
   subsequent adversarial judging, produced without access to the existing
   implementation or to any prior study artifact.

---

## 7. SUMMARY

| Question | Answer |
|---|---|
| Is CDAI dominated by any evaluated candidate? | No — §3 gives, for each, a specific objective on which it is materially worse, with the materiality threshold named. |
| Is CDAI optimal? | Unknown and not claimed. |
| Is the candidate set exhaustive? | No, and the spanning axes are stated so gaps are identifiable. |
| Was the process ceremonial? | No. Eleven challenges replaced a selection outright; the strongest failed challenge (DC-08-5) was raised by the hostile self-audit rather than the first pass; and the second audit round REVERSED a sealed decision (D02 via DC-02-4, moving DF-002 from BOUNDED to ELIMINATED). A process that cannot overturn its own sealed conclusions is ceremonial; this one did. |
| What is the strongest attack? | DF-033 — that the apparatus is disproportionate — followed by DF-043 (deepest technical residual) and DF-011. |
| Under what conditions does the claim fail? | §5: a dominating candidate, confirmation of any open defeater, a different objective ordering, or falsification of OA-4. |
