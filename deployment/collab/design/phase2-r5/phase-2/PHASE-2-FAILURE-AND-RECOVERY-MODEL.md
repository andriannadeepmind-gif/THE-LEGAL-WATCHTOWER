# PHASE-2 FAILURE AND RECOVERY MODEL

Phase: 2 — BLIND FRONTIER ARCHITECTURE
Date: 2026-08-26
Depends on: PHASE-2-REQUIREMENTS-AND-INVARIANTS.md (I-01…I-38),
PHASE-2-AUTHORITY-AND-STATE-MODEL.md (Part H)

An invariant that holds only under fault-free operation is not an invariant. This
document specifies the declared fault classes F1…Fn and, for each, the semantics,
the detection mechanism, the recovery, and the disposition of every invariant.

Disposition vocabulary:

- **PRESERVED** — the invariant continues to hold throughout the fault.
- **SUSPENDED(status)** — the invariant is temporarily unenforceable; the system
  enters a *named* status that suppresses the affected claims. Never silent.
- **VIOLATED(recovery)** — the invariant can be broken; the named recovery
  restores it, and the breach is recorded.

**Default rule (used to make the matrix total).** For every fault, every
invariant not listed explicitly in that fault's disposition table is **PRESERVED**.
The default is stated here once so that no cell of the matrix is empty (I-38,
PO-038); §16 gives the machine-checkable summary. The non-meta invariants are
I-01…I-37 and I-39…I-47 (I-38 is the meta-invariant and is excluded); the count is
derived into the seal. I-39 and I-40 were added by first-round finding HF-009; I-41…I-46 by the
second round; I-47 by the third round (HF-029, staged admission).

---

## 1. THE STRUCTURAL REASON RECOVERY IS SIMPLE

```
State_v = K_v(R, A|_R)
```

The record `R` and the artifact store `A` are the only authorities; everything else
is derived and disposable (SA-7). Therefore:

- **there is no undo pass** — nothing partially-committed ever entered state;
- **recovery is recomputation**, not repair;
- **any corrupted derived store is deleted and rebuilt**, which is the same
  operation as the constitutional deletability experiment;
- **the hard cases are exactly two**: damage to `R`, and damage to `A`.

Everything below is organised around that.

---

## 2. F1 — PROCESS CRASH

**Semantics.** The institution image terminates without warning; in-flight
observation, derivation and adjudication are lost.

**Detection.** Restart.

**Recovery.**

```
1. Verify hash chain contiguity from last verified checkpoint to head.
2. Verify Merkle consistency proof from last witnessed head to current head.
3. Truncate any torn tail entry (→ F2).
4. State ← K_v(R[checkpoint .. head], A|_R).
5. Reconcile staging: promote any R-named digest absent from A and present in S
   (I-47); discard torn staged objects; record both.
6. Re-evaluate all live reopening predicates.
7. Publication power remains SUSPENDED until step 8.
8. Inspectorate re-executes all publication-critical falsifiers in V_w, and the
   K_v/V_w differential audit runs over the regression corpus.
```

**Dispositions.** All PRESERVED except:

| Invariant | Disposition |
|---|---|
| I-23 (suspension) | SUSPENDED(`PUBLICATION-SUSPENDED-PENDING-REVALIDATION`) — deliberately: an institution that resumes speaking before re-validating its own procedures is asserting on the authority of an unchecked state. |
| I-27 (admission reproducibility) | SUSPENDED(`REPRODUCIBILITY-UNCHECKED`) until sampled re-execution resumes. |
| I-47 (staged admission) | SUSPENDED until staging reconciliation completes at step 5 of recovery: a crash between the `ACQUISITION` append and the promotion leaves `R` naming a digest `A` lacks, which I-44 governs in the interim. Promotion is idempotent and resumable, so reconciliation is a replay, not a repair. |

**Note.** In-flight *work* is lost; in-flight *institutional state* cannot be,
because it never existed outside the record.

---

## 3. F2 — PARTIAL WRITE / TORN ENTRY

**Semantics.** The tail of `R` contains a partially written entry.

**Detection.** Entry framing plus `prev-commit` verification fails on the tail.

**Recovery.** Truncate at the last fully verifiable entry; append a
`TAIL-TRUNCATED` record naming the discarded byte range and its digest. Because
nothing derives from an uncommitted entry, no institutional state is lost.

**Dispositions.** All PRESERVED except I-47, which is SUSPENDED(`STAGING-TORN`)
for any staged object whose bytes did not survive: its digest will not match its
name, it is discarded, and the discard is recorded (I-47 clause 4). I-28 is
PRESERVED *by construction*: an entry is committed only when its bytes and its
commitment are durable, so a torn tail was never part of the record. **I-43 is
PRESERVED even here**, because a torn staged object was never in `A`.

**Adversarial note.** Truncation is the one operation that shortens the byte file
while preserving the record. It is recorded, and the discarded range's digest is
retained, so a truncation used to hide a committed entry is detectable against the
last witnessed head.

---

## 4. F3 — STORAGE CORRUPTION (SILENT BIT ROT)

**Semantics.** Bytes in `R` or `A` change without a write.

**Detection.**
- `R`: hash-chain verification and Merkle consistency proof against the last
  witnessed head [RL-011].
- `A`: content-address verification — the digest *is* the address, so corruption
  is self-announcing on read; plus scheduled scrubbing.

**Recovery.**
- `R` corrupt: restore from a replica whose head matches a witnessed
  co-signature; if no replica has it, the record is truncated to the last
  verifiable position and the institution enters `RECORD-INCOMPLETE` — a permanent,
  published status, never a silent repair.
- `A` corrupt: re-acquire from the source. **If re-acquisition yields a different
  digest, this is not corruption recovery — it is a `SOURCE-MUTATION` event (F5)
  and must be adjudicated**, because under L5 the source may lawfully have changed
  the text. Conflating the two would silently rewrite legal history.

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-06 (container preservation) | VIOLATED(re-acquire; if unavailable, dependent evidence → `UNVERIFIED`) |
| I-07 (lineage reproducibility) | SUSPENDED(`NON-REPRODUCIBLE`) for affected artifacts |
| I-13 (retained superseded text) | VIOLATED(if the superseded artifact is unrecoverable, publication power SUSPENDED per I-13's violation semantics) |
| I-28 | VIOLATED(restore from replica, else `RECORD-INCOMPLETE`) |

---

## 5. F4 — SOURCE UNREACHABLE

**Semantics.** An observation channel fails.

**Detection.** Observation failure plus **vitality probe** on an independent code
path (§11 of the Frontier Architecture).

**Recovery.** The Observatory signals `observation-failed`; the Coverage Ephorate's
handler selects a restart (`retry-with-backoff`, `switch-channel`,
`defer-to-window`, `declare-source-unreachable`). Restart selection is a warranted,
recorded act, so the institution can later explain why it waited rather than
switched.

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-24 (silence/blindness) | PRESERVED — and *this is the fault it exists for*: if the vitality probe also fails, coverage enters `INDETERMINATE-COVERAGE`, not `SOURCE-SILENT`. |

**Critical rule.** A failed content fetch plus a *successful* vitality probe is
evidence about the *content channel*, not about the source. A failed content fetch
plus a *failed* vitality probe is evidence about the Watchtower's own blindness.
Reporting either as "no new material" is the failure mode the architecture exists
to prevent.

---

## 6. F5 — SOURCE SILENTLY MUTATED

**Semantics.** The source replaces the bytes at an identity it presents as
unchanged. Under Greek law this is *expected*: correction of Gazette errors is a
formal procedure under Law 3469/2006 Art. 16 §§4–5 [RL-026].

**Detection.** Scheduled digest anti-entropy against retained artifacts, stratified
by legal salience and citation recency, with **full** verification of every
artifact currently supporting a published answer (D16).

**Recovery.** `SOURCE-MUTATION` raised → quarantine → Tribunal adjudication into
`LAWFUL-CORRECTION` | `UNANNOUNCED-REVISION` | `SUBSTITUTION` | `TRANSIENT-ERROR`
(Authority model C.3). Both versions retained; dependent dockets reopened via their
reopening predicates.

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-13 | PRESERVED — this is the fault it exists for. |
| I-15/I-16 | PRESERVED — defeat propagates through the `A-AUTHENTICITY` assumption. |
| I-35 | SUSPENDED for dependent answers until adjudication completes; affected published answers enter the correction-obligation set. |

**What is not claimed.** Sampling means some mutations are detected late. The
detection-latency distribution is itself a self-model proposition subject to A6 and
is published with coverage answers.

---

## 7. F6 — SOURCE SERVES WRONG CONTENT (SUBSTITUTION)

**Semantics.** The channel returns a different instrument than requested, or an
error page with a 200 status, or a stale cached object.

**Detection.** Structural validation against the source's declared model
(enumeration, series, issue number), signature verification against the source's
registered key material, and cross-channel corroboration where a second channel
exists [RL-051].

**Recovery.** The *channel's* evidentiary contribution is degraded, not the
instrument's status. Acquisition proceeds only if identity is confirmable
independently.

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-02 | PRESERVED — degrading the channel does not touch authority, by construction. |
| I-08 | PRESERVED — digest never confers norm identity, which is exactly why a substitution cannot silently become an instrument. |

---

## 8. F7 — CLOCK JUMP

**Semantics.** Wall-clock time moves backwards, or forwards beyond the HLC
divergence bound ε [RL-018].

**Detection.** HLC monotonicity violation at append, or physical–logical divergence
exceeding ε.

**Recovery.** Causal ordering is unaffected (that is the point of HLC). Entries
appended during the anomaly are marked `CLOCK-ANOMALOUS`. Any *legal* deadline
computed from a `CLOCK-ANOMALOUS` stamp is re-derived once an anchored time is
available; a qualified electronic time stamp on the record head [RL-028] provides
the anchor.

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-28 | PRESERVED (causality) / SUSPENDED(`CLOCK-ANOMALOUS`) for the physical component. |
| I-11 | SUSPENDED for temporal propositions derived from anomalous stamps; they are recomputed after anchoring. |

---

## 9. F13 — LEGALLY MANDATED ERASURE (taken out of order: it is the hard case)

**Semantics.** A competent authority requires destruction of content held in `A`
(for example, personal data in a published judgment). This directly conflicts with
A2 (monotone record).

**The architecture does not deny the conflict.** Resolution — **sealed-void
semantics** (Authority model G.4):

```
1. The artifact's bytes are destroyed in A.
2. A SEALED-VOID entry is appended to R recording the digest, the legal basis,
   the issuing authority, and the scope.
3. Digest and lineage remain: every derivation that used it stays explainable
   AS TO STRUCTURE; only content is gone.
4. Beliefs requiring the destroyed content transition to UNSUPPORTED-BY-ERASURE,
   a status distinct from UNSUPPORTED, so the record shows WHY.
5. Replay across the erasure reproduces structure but not content and is marked
   REPLAY-INCOMPLETE-BY-ERASURE.
```

**Dispositions.**

| Invariant | Disposition |
|---|---|
| A2 / I-28 | Bounded exception — the *record* remains append-only; only `A` loses content. |
| I-06, I-07, I-13 | VIOLATED(sealed-void; consequences typed and recorded) |
| I-27 | SUSPENDED(`REPLAY-INCOMPLETE-BY-ERASURE`) for affected intervals |

This is the **only** mechanism that removes content. It is warranted, recorded, and
its consequences are typed. Stating it as a bounded exception is more honest than
claiming append-only absolutism that a legal order can override.

---

## 10. F8 — NETWORK PARTITION BETWEEN REPLICAS

**Semantics.** Under the optional Viewstamped Replication topology [RL-012],
replicas diverge.

**Detection.** View change.

**Recovery.** The protocol determines the committed prefix; entries beyond it were
never committed and therefore never had institutional effect. Derived state
computed from an uncommitted suffix is discarded and recomputed — safe precisely
because derived state is disposable (SA-7).

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-28 | PRESERVED (single logical order is a protocol guarantee; PO-028) |
| I-23 | SUSPENDED(`PUBLICATION-SUSPENDED-PENDING-VIEW-STABILITY`) during view change |

---

## 11. F9 — KERNEL DEFECT PRODUCING A WRONG DERIVATION

**Semantics.** `K_v` computes a wrong conclusion from a correct record. This is the
most dangerous fault, because the record is correct and the wrongness is
systematic and confident.

**Detection.** Five independent mechanisms, deliberately not sharing a failure
mode:

1. **ACL2 obligations** — the kernel theorems catch defects in the properties they
   cover [RL-014].
2. **`K_v` / `V_w` differential** — the independently authored verification kernel
   recomputes every publication-critical verdict and every self-model falsifier
   from `R` and `A|_R`; disagreement is **F15**. *(Added in the second audit round.
   This is the mechanism whose absence made the first version's self-audit
   circular.)*
3. **Differential execution across evaluators** — kernel functions run under the
   ACL2 evaluator and under SBCL on the regression corpus; divergence is a fault
   (this also probes DF-011).
4. **Sampled admission re-execution** (I-27).
5. **Rapporteur review** for high-consequence classes, and the human office's
   standing power to reopen any docket.

**Recovery.** Version-stamped conclusions (I-30) make the blast radius computable:
every proposition carrying the defective `v` is identified exactly. Promotion of
`v′` requires discharging the regression obligation (I-32); each behavioural
difference must be an admitted `DIVERGENCE`. Published answers grounded in
defective conclusions enter the correction-obligation set.

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-15…I-20, I-25…I-27 | potentially VIOLATED(detect → version-scoped reopening → regression-gated promotion) |
| I-39, I-40 | potentially VIOLATED(same recovery) — a defect in the interval algebra or in reconstruction confluence is exactly the class PO-039 and PO-040 exist to catch, and is the reason those obligations were added |
| I-30 | PRESERVED — and it is what makes the blast radius bounded rather than unknown. |

**Honest note.** A defect in a property no obligation covers, that also does not
diverge between evaluators and is not sampled, can persist. This is the residual
that DF-043 names — common mode across the two kernels. It is not condition WC-7,
which the two-kernel design remedied; DF-026 is BOUNDED.

---

## 12. F10 — RESOURCE EXHAUSTION DURING LABEL COMPUTATION

**Semantics.** ATMS label size grows exponentially [RL-009] and exhausts the
declared bound `B_label`.

**Detection.** The kernel returns an explicit status; the shell signals
`label-bound-exhausted`.

**Recovery.** The belief is marked `LABEL-INCOMPLETE`; it may not support a
publication; the docket is queued for bounded re-adjudication with a reduced
assumption scope. Bound-exhaustion frequency is a self-model proposition (A6).

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-18 | PRESERVED — this is the fault it exists for. |
| I-16, I-17 | SUSPENDED(`LABEL-INCOMPLETE`) for affected beliefs — soundness of the *computed* label is preserved; completeness is not claimed. |
| I-35 | PRESERVED — `LABEL-INCOMPLETE` cannot support publication, so nothing is published above its support. |

**This is the concrete refusal of silent degradation.** A system that truncated
labels quietly would answer confidently and wrongly; this one refuses and says why.

---

## 13. F11 — MODEL COMPONENT PRODUCING PLAUSIBLE-BUT-FALSE PROPOSALS

**Semantics.** A language model proposes a wrong parse, a wrong identity match, a
fabricated citation, or a fluent but unfaithful rendering. This is not
hypothetical: leading commercial retrieval-augmented legal research tools produced
incorrect or misgrounded output on 17–33% of 202 hand-scored queries against
vendor claims of hallucination-freedom [RL-030].

**Detection.** By construction rather than by monitoring. *(Strengthened in the
second audit round, finding HF-021.)* Model output goes to the **proposal spool**
`P`, which is not the record, not the artifact store, and **not an argument of the
kernel** (I-45). A proposal therefore cannot be a premise not because a rule
excludes it but because `K_v` cannot see it. Every proposal must pass a
deterministic verifier before any office may act on it, and acting means deriving
the content from evidence and issuing a real entry that may cite the proposal's
*digest* but never its content. Renderings pass the round-trip claim-slot check
(I-37).

**Recovery.** Delete the proposal. Nothing to unwind, because nothing entered the
record, the artifact store, or the derived state — and deleting the whole spool must
change `state` by nothing at all (I-31).

**Dispositions.** All PRESERVED. This fault is *designed to be harmless*, which is
the entire point of the containment: a component with a 17–33% error rate is used
only where its errors are discarded, never where they are believed.

---

## 14. F12 — OPERATOR TAMPERING WITH THE RECORD

**Semantics.** Someone with filesystem access rewrites, reorders or deletes
entries. Under OA-5 operators are trusted for availability but **not** for
integrity.

**Detection.** Not prevention — detection:

- hash-chain break;
- Merkle consistency proof failure against the last **witnessed** head [RL-011];
- witness co-signature mismatch;
- qualified electronic time stamp on a head that no longer verifies, where the
  presumption of accuracy of date and integrity of bound data attaches under
  Regulation (EU) 910/2014 [RL-028];
- deletability experiment divergence (SA-7), which detects tampering with derived
  state.

**Recovery.** Restore from a replica whose head matches a witnessed co-signature.
If none exists, the record is truncated to the last verifiable position and the
institution enters `RECORD-INCOMPLETE` — a permanent, published status.

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-28, I-34 | VIOLATED(detected; restore or `RECORD-INCOMPLETE`) |
| everything derived | PRESERVED after rebuild from the restored record |

**Stated limit.** Entrenchment (A10) binds *acts*, not *operators*. The
architecture converts prevention into detection and says so (DF-007). Claiming
otherwise would be a claim exceeding its evidence.

---

## 15. F14 — CHARTER AMENDMENT ERROR

**Semantics.** An amendment introduces a power conflict, an authority cycle, an
orphan power, or removes a needed obligation.

**Detection.** Alloy re-check of SP-1…SP-6 is a *precondition* of the amendment
act, so most such errors are caught before commitment; the `DEFCHARTER` macro
catches exclusivity conflicts at compile time (Lisp design §7.1). Runtime
structural audit by the Inspectorate catches the rest.

**Recovery.** An amendment failing its proof obligations is inadmissible (`⊘`). An
amendment touching an entrenched axiom is void (`⊥`) and triggers Inspectorate
review (I-34). A committed amendment later found defective is corrected by a
further amendment; because conclusions are version-stamped, the affected set is
computable, and the regression obligation applies.

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-34 | PRESERVED (entrenchment is checked at admission) |
| I-32 | PRESERVED (amendment carries a regression obligation over decisions that relied on the amended provision) |
| SP-1…SP-6 | VIOLATED only if the audit is itself defective → detected by the Inspectorate's independent structural check |

---

## 15A. F15 — VERIFICATION-KERNEL DIVERGENCE

*(Added with I-41, the remedy for the defect the creator identified in HF-001. This
fault class exists **because** the remedy exists: its firing is the signal that the
remedy is working.)*

**Semantics.** `K_v` and `V_w` disagree on a publication-critical invariant verdict,
on an admission decision, or on a self-model falsifier outcome. Exactly one of them
is wrong, and from inside the institution it is not determinable which.

**Detection.** By construction. The Inspectorate's verdicts come from `V_w`
(SA-14); the differential audit compares the two over the regression corpus on a
schedule and at every restart (Authority model §H.1 step 7).

**Recovery.**

```
1. Admit PROCEDURE-INVALID; SUSPEND the publication power (I-23).
2. The institution CONTINUES to observe, acquire, authenticate and adjudicate.
   It simply cannot speak. Agreement is not required to run; it is required
   to assert.
3. No automatic resolution. With two implementations there is no majority, and a
   tie-break rule would silently reintroduce a single point of authority — the
   very defect being remedied.
4. The Rapporteur (human) and the Amendment Council determine which kernel is
   wrong, citing the disagreeing inputs, which are recorded.
5. The defective kernel is corrected; promotion carries the regression obligation
   I-32 and the divergence itself joins the regression corpus.
6. Suspension is lifted only after the differential audit passes.
```

**Dispositions.**

| Invariant | Disposition |
|---|---|
| I-23 | SUSPENDED(`PUBLICATION-SUSPENDED-KERNEL-DIVERGENCE`) — deliberately, and this is the whole mechanism |
| I-41 | PRESERVED — this is the fault it exists to surface |
| I-46 | SUSPENDED for the disputed entry class only; entries on which the kernels agree continue to be admitted normally |
| everything else | PRESERVED |

**The honest limit.** F15 detects disagreement, not error. If both kernels are wrong
in the same way — a defective shared specification, a defective substrate, a
defective prover, a defective decoder — they agree, no fault fires, and the
institution speaks with confidence. That is DF-043, and it is the residual that
replaces HF-001 rather than the elimination of it.

---

## 16. THE COVERAGE MATRIX (I-38 / PO-038)

One cell per non-meta invariant per fault class. Every cell is assigned by the
default rule of the preamble plus the explicit dispositions below. Dimensions and
total are derived into PHASE-2-SEAL.json rather than restated here — this table
restated them twice before and drifted twice.

| Fault | Explicitly non-PRESERVED invariants | Count | Cells PRESERVED by default |
|---|---|---|---|
| F1 crash | I-23, I-27, I-47, I-48 | 4 | 43 |
| F2 torn entry | I-47 | 1 | 46 |
| F3 corruption | I-06, I-07, I-13, I-28, I-44 | 5 | 42 |
| F4 source unreachable | — | 0 | 47 |
| F5 silent mutation | I-35 | 1 | 46 |
| F6 substitution | — | 0 | 47 |
| F7 clock jump | I-11, I-28 | 2 | 45 |
| F8 partition | I-23 | 1 | 46 |
| F9 kernel defect | I-15, I-16, I-17, I-18, I-19, I-20, I-25, I-26, I-27, I-39, I-40, I-48 | 12 | 35 |
| F10 label exhaustion | I-16, I-17 | 2 | 45 |
| F11 model falsehood | — | 0 | 47 |
| F12 tampering | I-28, I-34, I-43 | 3 | 44 |
| F13 mandated erasure | I-06, I-07, I-13, I-27, I-28, I-44 | 6 | 41 |
| F14 amendment error | — (SP-invariants are Charter-level, not I-numbered) | 0 | 47 |
| **F15 kernel divergence** | I-23, I-46 | 2 | 45 |

**No empty cells.**

Three observations that are design results rather than luck:

- **F9 (kernel defect) still has the widest blast radius** — but its character has
  changed. In the first version a `K_v` defect was undetectable from inside because
  the audit ran on the same kernel. It is now detected as **F15** for everything
  that gates publication, which is why F9 carries five detection mechanisms rather
  than four (the fifth being the `K_v`/`V_w` differential).
- **F3 and F13 now touch I-44**, because an unresolvable artifact digest is exactly
  the condition I-44 was added to make total and explicit rather than silent.
- **F2, F4, F6, F11 and F14 preserve every invariant.** Those are precisely the
  faults the architecture is *shaped* to absorb: a torn tail was never committed,
  an unreachable source is a coverage state rather than a loss, a substitution
  degrades a channel rather than an instrument, a false proposal is invisible to the
  kernel (I-45), and a defective amendment fails its proof obligations before it
  commits.

---

## 17. LIVENESS OBLIGATIONS

Safety is the bulk of this document; liveness is stated separately because
conflating them hides failures.

| Property | Statement | Tool |
|---|---|---|
| **L-1 Record progress** | if an admissible entry is offered infinitely often and a quorum is live, it is eventually committed | TLA+/Apalache [RL-016] |
| **L-2 Docket progress** | every opened docket eventually reaches admission, `UNDECIDED`, or `LABEL-INCOMPLETE`; none stalls forever | TLA+ + measure argument on the bounded search |
| **L-3 Obligation discharge** | every acquisition obligation is eventually attempted or explicitly deferred with a recorded reason | Alloy 6 temporal [RL-015] |
| **L-4 Reopening liveness** | every satisfied reopening predicate eventually reopens its docket | TLA+ |
| **L-5 Suspension recovery** | publication suspension is eventually lifted or escalated to the Rapporteur; it cannot silently persist | Alloy 6 temporal |
| **L-6 Coverage convergence** | for a source with a structural signal, coverage eventually leaves `INDETERMINATE` | **not provable** — depends on source behaviour; stated as an operating expectation, not a guarantee (DF-020) |

L-6 is listed precisely because it *cannot* be proved. A liveness claim that
depends on an uncontrolled external party is an assumption, and the honest thing is
to label it one.

---

## 18. WHAT THIS MODEL DOES NOT COVER

1. **Byzantine faults among replicas.** Viewstamped Replication tolerates crash
   faults, not Byzantine ones [RL-012]. A malicious replica is out of scope;
   detection falls back to witness co-signature over the record head.
2. **Compromise of the signing keys** of the National Printing House or of a
   qualified trust service provider. This would defeat the top of the evidentiary
   lattice. Mitigation is limited to key-material revocation propagating as
   evidentiary defeat (`A-AUTHENTICITY` defeated for all artifacts signed under the
   revoked key), which is expressible but which cannot restore the lost evidence.
3. **Legal-classification error** by the Tribunal. No mechanism detects a wrong
   legal judgement; only a later adjudication does. This is why every decision
   carries a reopening predicate and why the Rapporteur holds standing reopening
   power.
4. **Systematic OCR or extraction bias** correlated across the corpus. Bounded by
   evidentiary status (a derived text never rises above `SECONDARY` on its own),
   not detected.
5. **Simultaneous failure of the record and every replica and every witness.**
   Recovery is impossible; the institution's memory is lost; the honest outcome is
   `RECORD-INCOMPLETE` from the last anchored head, published as such.
