# PHASE-2 AUTHORITY AND STATE MODEL

Phase: 2 — BLIND FRONTIER ARCHITECTURE
Date: 2026-08-26
Depends on: PHASE-2-FRONTIER-ARCHITECTURE.md,
PHASE-2-REQUIREMENTS-AND-INVARIANTS.md

This document states, exactly: who owns what; every legal and epistemic state and
its transitions; which transitions are **invalid** and what invalidity means;
temporal semantics; recovery semantics; and the single-authority constraints with
their enforcement points.

Notation:

- `⊥` — **void**: the act has no institutional effect. The only state change is
  the appended record that a void act was attempted. Void is not "error" and not
  "rejected": a rejected act might be retried and succeed; a void act could never
  have succeeded because the actor lacked the power.
- `⊘` — **inadmissible**: structurally malformed; refused at admission; no state
  change other than the refusal record.
- `⊑` — evidentiary order (no stronger than).
- `E!` — enforcement point: `TYPE` | `ADMISSION` | `KERNEL` | `RUNTIME-AUDIT` |
  `PROOF`.

---

## PART A — OWNERSHIP

### A.1 The two authorities, one scratch area, and nothing else

| Store | Status | Owns | Mutability | Enforcement |
|---|---|---|---|---|
| **The Record** `R` | **authority** | every institutional act, in one total order | append-only | `ADMISSION` (evaluated in `V_w`, §J) + Merkle commitment + witness co-signature |
| **The Artifact Store** `A` | **authority** | immutable bytes, addressed by content digest, **and nothing the record does not name** (I-43) | write-once; never modified; never deleted except under §G.4 | `TYPE` (no update operation exists) + scheduled R-boundedness sweep |
| **The Proposal Spool** `P` | **scratch** | machine-learned and heuristic output | freely writable, freely deletable | outside the kernel's signature (I-45) |

Everything else is **derived**: legal state, epistemic state, self-model, plan,
quarantine status, indices, caches, the running image.

### A.1.1 The exact derivation identity

*(Restated by second-round audit finding HF-020. The first version asserted claim
**WC-8**: the kernel must read artifact bytes to derive anything about a text, and
that dependency was elided from the central axiom of the architecture.)*

```
state = K_v(R, A|_R)
```

`A|_R` is the artifact store restricted to digests named in `R`. This is a function
of `R` alone in every operative sense, because:

1. **`A` is content-addressed and write-once.** For a given digest there is exactly
   one possible byte sequence, so `A|_R` is uniquely determined by `R` whenever the
   named digests resolve.
2. **`A` is R-bounded** (I-43). Nothing in `A` is unnamed by `R`. Without this,
   `A` would be an unaccounted second authority and the deletability test would
   prove nothing, because a rebuild could silently draw on bytes the record never
   mentioned.
3. **`K_v` is total under unresolvability** (I-44). A digest that `R` names and `A`
   cannot resolve yields `UNSUPPORTED-BY-UNRESOLVED-ARTIFACT` on the affected
   beliefs and a global `DERIVATION-INCOMPLETE(D)` marker naming the exact
   unresolved set — never a skip, a substitution or a guess.

**Why `A` is an authority and not derived.** Its bytes came from the world. They
cannot be recomputed, only re-observed, and re-observation may lawfully yield
different bytes (L5). `A` is therefore exempt from rebuild-and-compare — but it is
not thereby unchecked: it is **verifiable** (the digest *is* the address, so
corruption is self-announcing on read) and **bounded** (I-43). Verifiability plus
boundedness is what makes its authority accountable.

**Why `P` is neither.** The proposal spool is not an authority and not derived; it
is scratch. Its check is the opposite of the deletability test: deleting `P` must
change `state` by **nothing at all**. Since `P` is not an argument of `K_v`, that
holds by construction.

### A.1.2 Staging and atomic promotion — how bytes enter `A` without ever violating I-43

*(Added in the third audit round, finding HF-029. I-43 requires that `A` contain
nothing `R` does not name. Bytes necessarily arrive **before** the `ACQUISITION`
entry that names them can be appended, so the invariant had a crash window that the
design named as a risk (DF-044) but never resolved. A crash window that an
invariant does not cover is an unspecified transition, which the acceptance
contract treats as a defect.)*

There is a fourth area, and it is deliberately **not** one of the three above:

```
S — the staging area.  Not R. Not A. Not P.
    Pre-institutional: bytes that have been fetched but not yet admitted.
    Content-addressed, like A, so staging is idempotent.
    Never read by K_v. Never read by V_w. Invisible to derivation.
```

**The admission protocol, in order:**

```
1.  Observatory fetches bytes; they land in S under their computed digest d.
2.  fsync(S/d), then fsync(dir S).                       ← durable in staging
3.  Archive appends the ACQUISITION entry naming d.       ← d becomes named by R
4.  Atomically promote: rename(S/d → A/d), same volume.   ← single atomic op
5.  fsync(dir A).
```

**Why entry-first and not promote-first.** This is the whole decision, and it is
forced:

| Order | Crash window leaves | Governed by |
|---|---|---|
| promote → append | `A` holds bytes **unnamed** by `R` | **nothing** — this is a direct I-43 violation, an unaccounted second authority |
| **append → promote** | `R` names a digest `A` cannot resolve | **I-44**, which already makes this total and explicit: `UNSUPPORTED-BY-UNRESOLVED-ARTIFACT` plus `DERIVATION-INCOMPLETE({d})` |

The design chooses the window that an invariant **already covers**. That is the
general principle: where a crash window is unavoidable, place it where an existing
invariant governs the resulting state, rather than where a new exception is needed.

**Step 4 is atomic by construction.** A same-volume rename is atomic on the target
filesystems: the name `A/d` either resolves to the complete object or does not
exist. There is no torn intermediate. Cross-volume staging is therefore
**prohibited** — a copy is not a rename, and a copy has a torn window.

**Crash reconciliation at recovery**, exhaustive over the three windows:

| Crash between | State found | Reconciliation |
|---|---|---|
| 1 and 2 | partial bytes in `S` | digest of the partial object does not match its name; discard; recorded as `STAGING-TORN`. Nothing was named, nothing was promoted, no invariant touched. |
| 2 and 3 | complete object in `S`, unnamed by `R` | **staging orphan.** Not in `A`, so I-43 holds. Recovery re-offers it to the pending acquisition plan (idempotent — the digest is the name). If it is still unnamed after the declared retention window, it is garbage-collected **and the collection is recorded**, so a silently discarded fetch is impossible. |
| 3 and 4 | `R` names `d`; `A` lacks it; `S` has it | **resumable promotion.** Recovery scans the digests named by `R`, finds those unresolvable in `A`, and promotes any that are present in `S`. Promotion is idempotent. Until it completes, I-44 governs and the state carries `DERIVATION-INCOMPLETE({d})`. |
| during 4 | rename either happened or did not | atomic; no reconciliation needed |
| 3 and 4, `S` also lost | `R` names `d`; nowhere resolvable | I-44 governs permanently until re-acquisition. This is the same state as F3 corruption and is handled identically. |

**What this changes about `A`'s invariants.** I-43 is now maintained *by
construction on the write path*: nothing is ever placed in `A` except by promotion,
and promotion happens only after the naming entry is committed. The scheduled
R-boundedness sweep (PO-043) becomes a check against *corruption and tampering*
rather than against a routine race — a genuine strengthening, because a sweep that
routinely finds orphans teaches operators to ignore it.

**Staging is not a fourth authority.** It holds only pre-institutional bytes; it is
invisible to both kernels; every staged object terminates in exactly one of
{promoted, discarded-as-torn, garbage-collected-with-record}; and deleting `S`
entirely can lose at most in-flight fetches, which are re-derivable from the plan.
That is the same status as an in-flight HTTP response, which is what it is.

### A.2 The single-authority constraints

| ID | Constraint | E! | Violation |
|---|---|---|---|
| **SA-1** | For each fact class F, exactly one office holds `issue(F)` | `ADMISSION` (Charter table) + `PROOF` (Alloy PO-009) | act ⊥ |
| **SA-2** | No office holds both `determine-evidence` and `determine-legal-effect` | `PROOF` (Alloy) | Charter fails to compile |
| **SA-3** | No office holds both `publish` and `adjudicate` | `PROOF` (Alloy) | Charter fails to compile |
| **SA-4** | The Inspectorate holds no `issue` power for a positive proposition kind | `PROOF` (Alloy) | Charter fails to compile |
| **SA-5** | The Registry holds no `issue(AUTHORITY)` | `PROOF` (Alloy) | Charter fails to compile |
| **SA-6** | Every power is reachable from the Charter by exactly one delegation path | `PROOF` (Alloy) | Charter fails to compile |
| **SA-7** | Every store except `R`, `A` and the scratch spool `P` is deletable and exactly rebuildable from `K_v(R, A|_R)` | `RUNTIME-AUDIT` (scheduled experiment) | configuration unconstitutional ⇒ publication SUSPENDED |
| **SA-8** | No derived store is written by anything except `K_v` | `TYPE` (kernel package exports the only intended writer; the guarantee is ACL2 admissibility, not the import list — see Lisp design §1.2) + `RUNTIME-AUDIT` | as SA-7 |
| **SA-9** | An adapter or model principal holds only `issue(OBSERVATION)` | `ADMISSION` | act ⊥ |
| **SA-10** | Entrenched axioms cannot be removed by any internal act | `ADMISSION` + `PROOF` (Alloy PO-034) | act ⊥, Inspectorate review triggered |
| **SA-11** | `A` contains nothing that `R` does not name (I-43) | `ADMISSION` on the write path + scheduled sweep (PO-043) | unnamed artifacts quarantined, never deleted; sweep result is a self-model proposition |
| **SA-12** | Admission is a pure function of (Charter, entry) evaluated in `V_w`, which imports no office package; it does not trust any caller-supplied warrant (I-46) | `ADMISSION` + `PROOF` (ACL2 PO-046) | act ⊥ regardless of call path |
| **SA-13** | `K_v` and `V_w` share no code beyond ANSI CL and the frozen decoder library (I-42) | build-time import-closure audit (PO-042) | the build fails |
| **SA-14** | The Inspectorate's verdicts are computed by `V_w`, never by `K_v` (I-41) | `TYPE` (package imports) + `RUNTIME-AUDIT` | a verdict traceable to `K_v` is itself `PROCEDURE-INVALID` |

**SA-7 is the operative test.** It is executed, not asserted: a sandbox region
deletes a derived store, rebuilds it from the record, and compares. A store that
survives deletion with information the record does not contain *is* a second
authority, whatever it is called.

### A.2.1 Genesis: where the Charter's own authority comes from

*(Added by hostile-audit finding HF-006: the design specified how authority is
exercised but not how it originates, which left an unlocated authority at
bootstrap — precisely the hidden-authority defect C7 forbids.)*

The Charter cannot be enacted by an office, because offices exist only by virtue of
the Charter. Genesis is therefore **explicitly external and explicitly recorded**:

```
e₀  GENESIS entry
      · the Charter text, verbatim
      · its content digest
      · the entrenchment declaration
      · the identity of the external principal(s) who enacted it
      · their signatures
      · a qualified electronic time stamp over the genesis digest
      · prev-commit = the well-known genesis constant
```

Properties:

1. **The genesis principal is external and named.** It is not an office. It holds
   no continuing power: after `e₀` it can act only through offices, and the
   Charter grants it none. Its authority is exhausted by the act of founding.
2. **Genesis is a single entry.** There is no second founding. An entry purporting
   to be a `GENESIS` at any position other than `e₀` is void (`⊥`).
3. **Amendment is the only continuation.** Non-entrenched provisions change by
   Amendment Council act (§18.3 of the Frontier Architecture); entrenched axioms
   never change (I-34).
4. **The bootstrap is auditable.** Any party holding `e₀` and the witnessed head
   can verify that the currently running Charter is the enacted one, or is its
   lawful amendment chain, because the amendment chain is itself in the record.

**Honest statement of what this does and does not achieve.** It *locates* the
founding authority rather than leaving it implicit, and it makes the founding
inspectable and its subsequent limits checkable. It does **not** make the founding
legitimate — nothing in an architecture can. A Charter that entrenches a bad axiom
is entrenched exactly as effectively as one that entrenches a good one. This is the
same class of limit as DF-007 (entrenchment binds acts, not operators), and it is
stated for the same reason.

### A.3 Ownership of each fact class

| Fact class | Sole issuer | Notes |
|---|---|---|
| source registration | Registry | |
| norm identity assignment / confirmation | Registry | never confers authority (SA-5) |
| external identifier binding (ELI/ECLI) | Registry | recorded as *defeasible external assertion* |
| observation record | Observatory | includes vitality probes |
| custody admission | Archive | includes container retention (I-06) |
| custody attestation | Archive | third-party attestations *cited*, not issued |
| evidentiary status | Authentication | includes signature and time-anchor verification |
| authority relation | Tribunal | |
| interpretation | Tribunal | |
| non-trivial inference admission | Tribunal | trivial strict-rule inference is kernel-derived |
| cessation classification | Tribunal | |
| conflict resolution | Tribunal | under declared preferences |
| doctrinal position | Doctrine Office | status `DOCTRINAL`, incomparable |
| procedural validity finding | Inspectorate | negative only |
| publication suspension / restoration | Inspectorate (suspend) / Amendment Council + Inspectorate (restore) | |
| reopening requirement | Chronicler | mechanical, from predicate evaluation |
| coverage obligation / observation plan | Coverage Ephorate | derived, not decided |
| publication | Publications | |
| high-consequence review | Rapporteur | human |
| charter amendment (non-entrenched) | Amendment Council | dual countersignature |

---

## PART B — ENTRY LIFECYCLE

An entry has exactly three states. There is no "update" and no "delete".

```
        ┌──────────┐   admissible?   ┌───────────┐
        │ PROPOSED │ ───────────────►│ COMMITTED │
        └──────────┘                 └───────────┘
              │  not admissible            │
              ▼                            │ (never leaves COMMITTED)
        ┌──────────┐                       │
        │  VOID /  │◄──────────────────────┘  only as a *separate* entry
        │INADMISS. │      recording that an act was void
        └──────────┘
```

**Invalid transitions** (all `⊘`, enforced at `TYPE`):
`COMMITTED → PROPOSED`; `COMMITTED → VOID`; `COMMITTED → COMMITTED′` (mutation);
deletion of any state.

Admissibility check at `ADMISSION`, in this order (first failure decides):

1. structural well-formedness (schema) → else `⊘`
2. `prev-commit` matches current head → else `⊘` (concurrent append; retry)
3. HLC monotonic w.r.t. the region's last entry → else `⊘`
4. issuing office holds `issue(kind, fact-class)` → else `⊥`
5. warrant verifies against the Charter power table → else `⊥`
6. kind-specific admission predicate (below) → else `⊘`
7. if kind ∈ {DECISION}: reopening predicate present and in the closed language →
   else `⊘`
8. if publication power suspended and kind = PUBLICATION → `⊥`

---

## PART C — LEGAL STATE MACHINES

### C.1 Instrument existence state

The legal existence of a Greek statutory instrument. Grounded in Const. Art. 42 §1
(promulgation and publication by the President) [RL-021] and ΕισΝΑΚ Art. 103 (the
ten-day default) [RL-023].

```
  UNKNOWN
     │ observed evidence of adoption
     ▼
  ADOPTED ─────────────► PROMULGATED ─────────────► PUBLISHED
     │  (t_enact)     (t_promulgate)             (t_publish)
     │                                                │
     │                                                │  t_force reached
     │                                                ▼
     │                                          IN-FORCE ◄────┐
     │                                                │       │ suspension lifted
     │                                                │       │
     │                                   suspension   ▼       │
     │                                          SUSPENDED ────┘
     │                                                │
     │                                                ▼
     └──────────────────────────────────────►  CEASED
                                              (ABROGATED | ANNULLED)
```

**States**

| State | Meaning |
|---|---|
| `UNKNOWN` | no admitted evidence of the instrument |
| `ADOPTED` | voted/adopted; not yet legally operative |
| `PROMULGATED` | promulgated; not yet published |
| `PUBLISHED` | published in the Gazette; **formally in existence** (L1) |
| `IN-FORCE` | `t_force` reached for **this provision** |
| `SUSPENDED` | effect suspended by a competent act |
| `CEASED` | with sub-kind `ABROGATED` (ex nunc) or `ANNULLED` (ex tunc) |

**Transitions and their warrants**

| From → To | Requires | Issuer |
|---|---|---|
| `UNKNOWN → ADOPTED` | evidence of adoption, ⊒ `SECONDARY` | Tribunal |
| `ADOPTED → PROMULGATED` | evidence of promulgation | Tribunal |
| `PROMULGATED → PUBLISHED` | evidence of Gazette publication, ⊒ `AUTHENTIC-UNSIGNED`, and `AUTHENTIC-SIGNED` required for `ESTABLISHED` strength | Tribunal |
| `PUBLISHED → IN-FORCE` | a `t_force` proposition (express provision or `RULE-EISNAK-103`) | Tribunal |
| `IN-FORCE ↔ SUSPENDED` | a competent suspending/restoring act | Tribunal |
| `* → CEASED` | a cessation instrument **and** a cessation-kind classification | Tribunal |

**Invalid transitions** (`⊥` if attempted by act; `⊘` if the kernel would derive
them):

| Invalid | Why |
|---|---|
| `UNKNOWN → PUBLISHED` | skips the constitutive chain; publication must be *evidenced*, not assumed |
| `ADOPTED → IN-FORCE` | an unpublished statute cannot be in force (L1) |
| `PROMULGATED → IN-FORCE` | same |
| `CEASED → IN-FORCE` | resurrection requires a *new* instrument, which is a new norm identity |
| `* → CEASED` without a cessation kind | leaves `CESSATION-KIND-UNDETERMINED`, which is a **state**, not a transition (see C.2) |
| any transition asserted by an adapter | SA-9 |
| any transition whose sole support is `DOCTRINAL` | I-20 |

### C.2 Cessation-kind determination

```
  CESSATION-OBSERVED
        │
        ├── evidence identifies an abrogating instrument ──► ABROGATED  (ex nunc)
        │
        ├── evidence identifies an annulling decision ─────► ANNULLED   (ex tunc,
        │                                                     within declared scope)
        │
        └── neither ───────────────────────────────────────► CESSATION-KIND-
                                                              UNDETERMINED
```

`CESSATION-KIND-UNDETERMINED` **suppresses** every point-in-time answer whose
interval spans the cessation (I-12). This is a refusal, not a default.

**Retroactive consequence of `ANNULLED`.** Every admitted decision whose evidence
window intersects the annulment scope has its reopening predicate satisfied and
is reopened by the Chronicler. This is mechanical, not discretionary.

### C.2.1 Composition of cessation and correction events

*(Added by hostile-audit finding HF-003: the trichotomy was specified singly but
its compositions were not, and Greek practice produces all of them.)*

Cessation kinds and corrections compose. The composition rules are stated
explicitly because a system that resolves them ad hoc will resolve them
inconsistently.

| Composition | Rule | Rationale |
|---|---|---|
| **Correction of a text later abrogated** | The correction applies to the interval in which the norm was in force; the abrogation closes `t_end`. Both stand; neither defeats the other. | They operate on different axes: correction on content, abrogation on `t_end`. |
| **Correction of a text later annulled** | The annulment's *ex tunc* effect governs within its declared scope; the correction remains evidence of what was published and is retained, but no reconstruction within the annulled scope uses either text as operative. | Annulment removes the claimed effect; it does not remove the publication history. |
| **Abrogation later annulled** | The *abrogating instrument* is annulled *ex tunc* within scope, so within that scope the abrogation is treated as never having had effect and the earlier norm's `t_end` reverts to `OPEN` **for that scope only**. Every decision in the interval reopens. | This is the case most often got wrong: annulling an abrogation revives, within scope, rather than compounding cessation. |
| **Annulment later itself annulled** | Recursive: apply the same rule at the next level. The reconstruction depth is bounded by the chain length, which is finite and recorded. | No special case is needed; the rule is uniform. |
| **Correction issued after annulment of the correcting instrument** | The correction has no effect; the pre-correction text stands within the annulled scope. | Follows from *ex tunc*. |
| **Two cessations of different kinds asserted for the same norm and interval** | `CESSATION-KIND-CONFLICT` — a first-class state that suppresses point-in-time answers over the interval and opens a docket. **Never** resolved by precedence of kind. | Two competent authorities disagreeing is a legal conflict, not a data conflict. |

**Invalid compositions** (`⊘`): treating an annulment as an abrogation because the
annulment's scope is unclear (the correct state is
`CESSATION-KIND-UNDETERMINED`); applying a correction inside an annulled scope as
though it were operative; collapsing `CESSATION-KIND-CONFLICT` by choosing the
later instrument.

**Obligation.** These compositions are among the cases PO-040 (amendment-chain
confluence) must cover: the reconstruction of a provision at `t` must be identical
regardless of the order in which the composing events are applied, given their
admitted temporal ordering.

### C.3 Text correction

Grounded in Law 3469/2006 Art. 16 §§4–5, the formal correction procedure operated
by the National Printing House [RL-026].

```
  TEXT-CURRENT(x)
        │ SOURCE-MUTATION detected (digest change on unchanged identity)
        ▼
  MUTATION-QUARANTINED
        │
        ├── matched to a published correction instrument ──► CORRECTED(x → x′)
        │        · x retained (I-13)
        │        · norm treated as always having been x′ within correction scope
        │        · prior answers grounded in x linked to the correction
        │
        ├── no correction instrument found ────────────────► UNANNOUNCED-REVISION
        │        · both retained; channel evidentiary status degraded
        │        · prior answers flagged; dockets reopened
        │
        ├── content is a different instrument ─────────────► SUBSTITUTION
        │        · channel status degraded to SECONDARY or below
        │
        └── re-observation returns the original digest ────► TRANSIENT-ERROR
```

**Invalid transitions**: `MUTATION-QUARANTINED → TEXT-CURRENT` without
adjudication (`⊥`); discarding `x` on correction (`⊘`, violates I-13);
auto-selecting `x′` as authoritative without a Tribunal act (`⊥`).

### C.4 Consolidation class

The consolidation classes never merge (I-14):

```
OFFICIAL-CODIFICATION                  (Law 4622/2019 Arts. 65–66 organs) [RL-027]
OFFICIAL-CONSOLIDATED-REPUBLICATION    (a further official publication)
WATCHTOWER-RECONSTRUCTION              (derived by the kernel from amendments)
```

**Invalid**: emitting a `WATCHTOWER-RECONSTRUCTION` in answer to a request for an
official codified text (`⊥` at the publication boundary); any transition between
classes (they are different kinds of object, not stages).

---

## PART D — EVIDENTIARY STATE MACHINE

```
                      ┌──────────────────────────────┐
                      │  AUTHENTIC-SIGNED-ANCHORED   │
                      └──────────────┬───────────────┘
                                     │ anchor lost / expired (▼ only)
                      ┌──────────────▼───────────────┐
                      │      AUTHENTIC-SIGNED        │
                      └──────────────┬───────────────┘
                                     │ signature no longer verifies
                      ┌──────────────▼───────────────┐
                      │     AUTHENTIC-UNSIGNED       │
                      └──────────────┬───────────────┘
                                     │ provenance to source not establishable
                      ┌──────────────▼───────────────┐
                      │         SECONDARY            │        DOCTRINAL
                      └──────────────┬───────────────┘      (incomparable;
                                     │                        no transition into
                      ┌──────────────▼───────────────┐        or out of the chain)
                      │        UNVERIFIED            │
                      └──────────────┬───────────────┘
                                     │ repudiation evidence
                      ┌──────────────▼───────────────┐
                      │        REPUDIATED (⊥)        │  absorbing
                      └──────────────────────────────┘
```

### D.1 Rules

- **Downward transitions** may be issued by Authentication on new evidence.
- **Upward transitions** require a *new* `ACQUISITION` plus an Authentication act
  citing new material (I-05). There is no upward path from derivation.
- **`REPUDIATED` is absorbing**: no transition out. Rehabilitation requires a new
  artifact with a new digest, i.e. a different subject.
- **`DISPUTED`** is the meet of two incomparable non-⊥ statuses; it is a computed
  status, not an issued one.

### D.2 The degradation theorem

For every transformation `T` in the closed algebra: `rank(T(x)) ⊑ rank(x)`
(PO-004, ACL2). There exists no rank-raising constructor. Consequence: strength
laundering — the accumulation of apparent authority through successive clean
representations — is *impossible*, not *discouraged*.

### D.3 Invalid evidentiary transitions

| Invalid | Why |
|---|---|
| `SECONDARY → AUTHENTIC-SIGNED` by re-parsing | I-05: no new evidence |
| `DOCTRINAL → SECONDARY` | incomparable branch; doctrine is not weak authority |
| `REPUDIATED → anything` | absorbing |
| any status change issued by the Archive or the Tribunal | SA-1: Authentication holds this power exclusively |
| status raised because two `SECONDARY` sources agree | agreement is corroboration, recorded as an additional argument; it does not change the *artifact's* status |

---

## PART E — EPISTEMIC STATE MACHINE

### E.1 Belief status

```
        ┌───────────────┐
        │  UNSUPPORTED  │◄──── all environments defeated
        └───────┬───────┘
                │ an environment becomes viable
        ┌───────▼───────┐
        │   SUPPORTED   │──── conflict arises ────►┌───────────┐
        └───────┬───────┘                          │ CONTESTED │
                │ strict derivation from           └─────┬─────┘
                │ AUTHENTIC-SIGNED(-ANCHORED)            │ preference resolves
        ┌───────▼───────┐                                │
        │  ESTABLISHED  │                                ▼
        └───────────────┘                          ┌───────────┐
                                                   │ UNDECIDED │
                                                   └───────────┘

        ┌────────────────────┐   bound exhausted    (orthogonal marker,
        │  LABEL-INCOMPLETE  │◄──────────────────    applies to any status)
        └────────────────────┘
```

### E.2 Transition rules

| From → To | Trigger | E! |
|---|---|---|
| `UNSUPPORTED → SUPPORTED` | a new argument with a viable environment | `KERNEL` |
| `SUPPORTED → ESTABLISHED` | derivation uses only strict rules and all leaves ⊒ `AUTHENTIC-SIGNED` | `KERNEL` |
| `SUPPORTED → CONTESTED` | a defeater argument is constructed | `KERNEL` |
| `CONTESTED → SUPPORTED` | preference ordering defeats the attacker | `KERNEL` |
| `CONTESTED → UNDECIDED` | preference ordering is silent | `KERNEL` |
| `* → UNSUPPORTED` | every supporting environment contains a defeated assumption or is a superset of a no-good | `KERNEL` (label propagation) |
| `* → LABEL-INCOMPLETE` | `B_label` exhausted | `KERNEL` returns status; shell signals a condition |

### E.3 Invalid epistemic transitions

| Invalid | Why |
|---|---|
| `UNDECIDED → SUPPORTED` by recency or any tie-break | I-19: no arbitrary resolution |
| `LABEL-INCOMPLETE → ESTABLISHED` | incomplete labels cannot license the strongest status |
| `* → ESTABLISHED` with any `DOCTRINAL` leaf | I-20 |
| belief surviving the defeat of all its environments | I-16: unsound label |
| belief labelled with a superset of a no-good | I-17 |
| any status change not computed by `K_v` | SA-8 |

### E.4 Assumption defeat propagation

When assumption `a` is defeated at record position `n`:

1. every environment containing `a` is marked non-viable;
2. every belief whose environments are all non-viable becomes `UNSUPPORTED`;
3. every `DECISION` whose support includes such a belief has its reopening
   predicate evaluated; those satisfied reopen;
4. every `PUBLICATION` whose support includes such a belief is added to the
   **correction obligation** set.

Steps 1–3 are inside `K_v`, hence deterministic and replayable. Step 4 produces an
obligation, not an automatic retraction: withdrawing a published answer is an act
of the Publications office with its own warrant.

### E.5 Published-answer state machine

*(Added by hostile-audit finding HF-018: the correction-obligation set was named
but the transitions out of it were not specified, leaving the most externally
visible behaviour of the institution — what happens to an answer it has already
given — under-defined.)*

```
   EMITTED
      │ a supporting belief changes status, or a supporting artifact is
      │ repudiated, corrected, or erased
      ▼
   CORRECTION-OBLIGED ──────────────────────────────────────────┐
      │                                                          │
      ├── re-derivation yields the same proposition ────────────►│ AFFIRMED
      │      · the answer stands; the basis changed but not      │ (re-emitted
      │        the conclusion; the new basis is recorded         │  with new basis)
      │                                                          │
      ├── re-derivation yields a different proposition ─────────►│ SUPERSEDED
      │      · a corrected answer is emitted, linked to the      │
      │        original; the original remains retrievable        │
      │                                                          │
      ├── re-derivation yields insufficient support ────────────►│ WITHDRAWN
      │      · a structured withdrawal is emitted naming what    │
      │        changed and what is now missing (I-36 shape)      │
      │                                                          │
      └── the supporting content was erased under F13 ──────────►│ WITHDRAWN-
             · withdrawal states erasure as the cause, without   │ BY-ERASURE
               disclosing the erased content                     │
```

**Rules.**

1. `EMITTED → *` is triggered by the kernel (the obligation is derived); the
   *transition out* of `CORRECTION-OBLIGED` is a warranted Publications act.
2. An emitted answer is **never** silently deleted or edited in place. All four
   outcomes are new publications linked to the original, and the original remains
   retrievable with its original basis — otherwise the institution could not
   explain what it once said, which is the point of I-13.
3. `CORRECTION-OBLIGED` is a **published** status: a consumer querying a
   previously issued answer sees that it is under correction, before the outcome is
   determined. Concealing the obligation until resolution would be a silent
   degradation.
4. `WITHDRAWN-BY-ERASURE` states the *fact* of erasure and its legal basis but not
   the erased content, so that the withdrawal does not defeat the erasure.
5. Reopening-predicate firing is **idempotent**: a predicate that fires while its
   docket is already reopened produces no second reopening, only an additional
   citation on the existing docket.

**Invalid transitions** (`⊥`): editing an emitted answer in place; withdrawing
without a stated cause; leaving `CORRECTION-OBLIGED` without one of the four
outcomes; emitting `AFFIRMED` without actually re-deriving.

---

## PART F — SELF-MODEL STATE

### F.1 Coverage state per (source × series × window)

```
   INDETERMINATE-COVERAGE ◄──────────── vitality probe inconclusive
            │                                       ▲
            │ enumeration model available           │ probe fails / channel dead
            ▼                                       │
    ┌───────────────┐  gap found   ┌────────────────┴───┐
    │    COVERED    │─────────────►│   GAP-CONFIRMED    │
    └───────┬───────┘              └────────┬───────────┘
            │ no emissions in window         │ missing item acquired
            ▼                                │
    ┌───────────────┐                        │
    │ SOURCE-SILENT │◄───────────────────────┘
    │ (vitality OK) │
    └───────────────┘
```

**The decisive rule (I-24)**: `SOURCE-SILENT` may be entered **only** with a
successful content-independent vitality probe. Without it the state is
`INDETERMINATE-COVERAGE`, and every completeness claim over the window is
suppressed. Absence of evidence is not entered as evidence of absence.

### F.2 Procedural validity state

```
   PROCEDURE-VALID ──── falsifier fires ────► PROCEDURE-INVALID(x)
          ▲                                          │
          │                                          │ if x is publication-critical
          │                                          ▼
          │                                   PUBLICATION-SUSPENDED
          │                                          │
          └──── warranted restoration act ───────────┘
```

- Suspension is entered by the Inspectorate alone.
- Restoration requires a warranted act *and* re-execution of the falsifier
  returning valid. An office cannot restore its own suspension by assertion.
- The Inspectorate can never issue a positive legal proposition (SA-4), so this
  power cannot be leveraged into adjudication.

### F.3 The A6 admissibility gate

Every self-model proposition is `⊘` unless it carries `⟨truth-condition,
falsifier, consequence⟩` (I-21). A self-model proposition with an empty consequence
set is decoration and does not enter the store.

---

## PART G — TEMPORAL SEMANTICS

### G.1 The nine axes and what they are *for*

| Axis | Kind | Owner of the proposition | Defeasible? |
|---|---|---|---|
| `t_enact` | legal | Tribunal | yes |
| `t_promulgate` | legal | Tribunal | yes |
| `t_publish` | legal, **constitutive** | Tribunal | yes |
| `t_force` | legal, **per provision** | Tribunal | yes |
| `t_apply_from` / `t_apply_to` | legal, may be retroactive | Tribunal | yes |
| `t_end` | legal, with cessation kind | Tribunal | yes |
| `t_observe` | system | Observatory | no (a record fact) |
| `t_record` | system (HLC) | admission | no |
| `t_believe` | system | Tribunal admission | no |

The three system axes are **record facts** and are not defeasible; the six legal
axes are **adjudicated propositions** and are (A5).

### G.2 Interval endpoints

```
endpoint := CLOSED(d) | OPEN(d) | UNKNOWN | CONDITIONAL(c)
```

`CONDITIONAL(c)` is essential and common: "in force on publication of the
ministerial decision provided for in §4". A date column cannot represent it; the
system would have to guess or drop the provision. With it, the honest answer is
expressible.

### G.3 Point-in-time query semantics

`text-in-force(P, t)` is defined only when, for every axis relevant to `P` over the
neighbourhood of `t`:

- the axis proposition is `SUPPORTED` or `ESTABLISHED`, **and**
- no cessation in the interval is `CESSATION-KIND-UNDETERMINED`, **and**
- no source whose coverage window intersects the evidence window is
  `INDETERMINATE-COVERAGE` *when a completeness claim is being made*.

Otherwise the answer is a **structured refusal** naming which condition failed
(I-36). The refusal is precise: *"cannot determine text in force on 2019-11-04:
commencement of §3 is CONDITIONAL on an unobserved ministerial decision"*.

### G.4 The bounded exception to append-only

A legally mandated erasure (for example, data-protection erasure of personal data
appearing in a judgment) conflicts with A2. The architecture does not deny the
conflict. Resolution — **sealed-void semantics**:

1. The artifact's bytes are destroyed in `A`.
2. A `SEALED-VOID` entry is appended to `R` recording: the digest, the legal basis
   for erasure, the issuing authority, and the scope.
3. The digest and all lineage remain, so every derivation that used it remains
   explainable *as to structure*; only the content is gone.
4. Every belief whose support requires the destroyed content transitions to
   `UNSUPPORTED-BY-ERASURE`, a distinct status from `UNSUPPORTED`, so the record
   shows *why*.
5. Replay from before the erasure reproduces the structure but not the content and
   is marked `REPLAY-INCOMPLETE-BY-ERASURE`.

This is the only mechanism that removes content, it is warranted, it is recorded,
and its consequences are typed. It is stated as a bounded exception, not concealed
as an impossibility.

---

## PART H — RECOVERY SEMANTICS

### H.1 The recovery identity

```
State_v = K_v(R, A|_R)
```

Recovery is therefore **recomputation**, not repair. There is no undo pass.

```
1. Verify record integrity:
     · hash chain contiguous from genesis (or last verified checkpoint)
     · Merkle consistency proof from last witnessed head to current head [RL-011]
     · witness co-signatures verify; qualified time anchor verifies [RL-028]
2. Verify artifact store:
     · every digest named in R resolves, or is recorded in the unresolved set D
     · every artifact in A is named by R (I-43); unnamed artifacts are quarantined
3. Locate last valid checkpoint C (a derived-state snapshot + record position)
4. Redo: State ← K_v(R[C.position .. head], A|_R)
     · if D is non-empty the state carries DERIVATION-INCOMPLETE(D) (I-44)
5. Re-evaluate all live reopening predicates
6. Re-run the deletability experiment on one derived store (SA-7), and the
   null-effect check on the proposal spool (I-31)
7. Inspectorate re-executes publication-critical falsifiers **in V_w** (SA-14),
   and the K_v/V_w differential audit runs over the regression corpus
8. Publication power remains SUSPENDED until step 7 passes with agreement
```

Step 7 is where the second-round remedy bites on recovery specifically: a restart
is exactly the moment at which a corrupted derived state would otherwise be
recomputed by a possibly-defective kernel and then audited by the same kernel. The
differential audit is run before the institution is permitted to speak again.

Step 7 matters: an institution that resumes speaking before it has re-validated
its own procedures is asserting on the authority of a state it has not checked.

### H.2 Checkpoint status

A checkpoint is a **cache** (A12), never an authority. It may be a serialised
derived state or an SBCL core image [RL-046]. Because core images are explicitly
not compatible across runtimes, a runtime upgrade invalidates every image
checkpoint and forces a full rebuild from `R`. This is stated as a known cost
(Frontier §21.3), not hidden.

### H.3 Partial-write and torn-entry handling (fault F2)

An entry is committed only when its full bytes and its commitment are durable. A
torn tail is truncated at the last fully verifiable entry; truncation is itself
recorded on restart. Because nothing derives from an uncommitted entry, truncation
cannot lose institutional state — only in-flight work, which is re-derived from
the plan.

### H.4 Divergence between replicas (fault F8)

Under the optional Viewstamped Replication topology [RL-012], a view change may
reveal divergent tails. Resolution: the protocol's own reconciliation determines
the committed prefix; entries beyond it were never committed and therefore never
had institutional effect. Any derived state computed from an uncommitted suffix is
discarded and recomputed — which is safe precisely because derived state is
disposable (SA-7).

---

## PART I — CROSS-CUTTING INVALID-TRANSITION SUMMARY

The complete set of transitions that are **void** (`⊥`) rather than merely
erroneous:

1. Any act by an office lacking the power (SA-1).
2. Any adapter or model act outside `{OBSERVATION, PROPOSAL}` (SA-9).
3. Any authority assertion justified by a channel (I-02).
4. Any evidentiary elevation without new acquisition (I-05).
5. Any transformation claiming a rank increase (I-04).
6. Any legal-state transition skipping the constitutive chain (C.1).
7. Any cessation without a kind classification, treated as `ABROGATED` by default.
8. Any belief admission without a contradiction record (I-25).
9. Any decision without a reopening predicate (I-26).
10. Any publication while suspended (I-23), or above its support (I-35), or over an
    `INDETERMINATE-COVERAGE` window with a completeness claim (I-24), or of a
    reconstruction presented as an official codification (I-14).
11. Any amendment touching an entrenched axiom (I-34).
12. Any class redefinition without a migration warrant (I-33).
13. Any write to a derived store by anything but `K_v` (SA-8).
14. Any deletion from `A` except under sealed-void semantics (G.4).
15. Any restart selection made without a warrant (D24).
16. Any entry whose (office, kind, fact-class) is outside the Charter power table,
    **regardless of the call path by which it reached the append point** (I-46,
    SA-12).
17. Any Inspectorate verdict computed by `K_v` rather than `V_w` (I-41, SA-14).
18. Any artifact admitted to `A` that no entry of `R` names (I-43, SA-11).
19. Any entry whose payload embeds proposal *content* rather than a proposal
    *digest* (I-45).

Each of these is enforced at a named point, and each has an assigned proof
obligation or runtime audit. None of them is a review guideline.

---

## PART J — THE VERIFICATION KERNEL

*(Added by the creator's ruling that HF-001 is a defect. The first version merely
disclosed condition **WC-7** and bounded its consequence. It is now replaced by a
structural remedy.)*

### J.1 Two kernels

```
        R, A|_R
        ┌──┴───┐
        │      │
        ▼      ▼
   ┌────────┐  ┌────────┐
   │  K_v   │  │  V_w   │      independently authored, independently ACL2-admitted,
   │derive  │  │verify  │      no shared code (I-42) beyond ANSI CL + frozen decoders
   └───┬────┘  └───┬────┘
       │           │
       ▼           ▼
   full state   admission decisions
   (all offices) publication-critical invariant verdicts
                 self-model falsifier outcomes
                       │
                       ▼
                 Inspectorate  ── may SUSPEND, may never create
```

`V_w` reads the record and the artifact store **directly**. It never reads `K_v`'s
output. That is the whole point: an auditor that consumes the audited party's
conclusions inherits the audited party's errors.

### J.2 What `V_w` computes, and what it deliberately does not

**Does:** the admission predicate (I-46); the publication-critical invariant subset;
every self-model falsifier — and, for coverage falsifiers specifically, it
recomputes coverage from the **raw observation entries including vitality-probe
results**, not from `K_v`'s coverage propositions.

**Does not:** the full institutional state. An independent re-implementation of the
entire kernel would double the specification surface without doubling the
assurance, and would make the two implementations diverge constantly on questions
that do not bear on whether the institution may speak. Scope is bounded to exactly
what gates publication.

### J.3 Disagreement is a fault, and it is the point

`K_v ≠ V_w` on any publication-critical invariant or any falsifier outcome is
**fault F15**. It admits `PROCEDURE-INVALID`, which suspends the publication power.

The institution continues to observe, acquire, authenticate and adjudicate while
suspended. It simply cannot *speak*. That asymmetry is deliberate: agreement is not
required for the institution to run; it is required for the institution to assert.

Resolution of F15 is not automatic and has no majority rule — with two
implementations there is no majority. It requires an act: the Rapporteur and the
Amendment Council determine which kernel is wrong, the defective one is corrected,
and promotion of the correction carries the regression obligation (I-32). Until
then, suspension stands.

### J.4 What this closes, and what it does not

**Closes.** A defect in `K_v` alone can no longer corrupt both the world model and
the audit of the world model. It produces disagreement, which is detected, which
stops publication. The institution can still be wrong; it can no longer be wrong
*and confident* through a single point of failure.

**Does not close.** Both kernels implement the same written specification, run on
the same SBCL, are checked by the same ACL2, and share the frozen decoder library
that I-42 permits as the one deliberate intersection — because two kernels that
disagree about what the bytes of an entry *mean* are not verifying the same thing.
A defect in the specification, the substrate, the prover, or the decoders defeats
both.

That residual is materially smaller than what it replaces and is different in
kind — a **specification** risk rather than a **circularity**. It is carried as
DF-043 and it is not claimed to be closed.
