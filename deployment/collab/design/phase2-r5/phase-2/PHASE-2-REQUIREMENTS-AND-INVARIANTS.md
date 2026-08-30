# PHASE-2 REQUIREMENTS AND INVARIANTS

Phase: 2 — BLIND FRONTIER ARCHITECTURE
Date: 2026-08-26
Depends on: PHASE-2-CREATOR-AXIOMS.md

This document states the hard requirements, the formal invariants, the failure and
operating model under which the invariants must hold, and the executable proof
obligations that discharge them. It is written so that a hostile reviewer can
attempt to violate each invariant by construction.

Conventions:

- **R-n** requirement (what must be possible or impossible).
- **I-n** invariant (a predicate over system state or history that must always
  hold). Each invariant states its **quantification**, its **enforcement point**,
  its **violation semantics**, and its **discharge** (how it is checked).
- **PO-n** proof obligation, with the tool that discharges it.
- Enforcement points are one of: `KERNEL` (checked inside the pure derivation
  function; violation makes the entry inadmissible), `ADMISSION` (checked at
  append time by the constitutional gate), `TYPE` (structurally impossible to
  express), `RUNTIME-AUDIT` (checked periodically by the inspection office),
  `PROOF` (established statically, not checked at runtime).

A violation semantics of **VOID** means the offending act has no institutional
effect and the only state change is the record of its voidness. **SUSPEND** means
a named power is disabled institution-wide until a warranted act restores it.

---

## PART I — THE EIGHT KINDS AND THEIR SEPARATION

### R-01 Kind separation
The system shall represent, as eight mutually exclusive kinds with distinct
identity spaces, distinct owning offices and distinct entry types:

| Kind | Content | Owner (sole power) |
|---|---|---|
| `OBSERVATION` | "channel C returned response R at logical time τ" | Observatory |
| `ACQUISITION` | "artifact with digest D is in durable custody" | Archive |
| `EVIDENCE` | "artifact D has evidentiary status S w.r.t. claim class K" | Authentication |
| `AUTHORITY` | "instrument I holds authority A in legal order O at time t" | Registry (identity) + Tribunal (authority relation) |
| `INTERPRETATION` | "provision P bears meaning M under reading R" | Tribunal |
| `INFERENCE` | "proposition Q follows from premises Π under rules Σ" | Kernel, admitted by Tribunal |
| `PUBLICATION` | "answer A was emitted to audience X at time τ" | Publications |
| `DECISION` | "docket Δ was resolved as Z for reasons W with reopening predicate Π" | Tribunal / Amendment Council |

### I-01 — No kind coercion (C2, G1)
∀ entry e, e's kind is fixed at construction and immutable. There exists no
operation mapping an entry of one kind to an entry of another kind other than a
**warranted elevation act**, which itself appends a new entry of the target kind
citing the source entry.
- Enforcement: `TYPE` (distinct CLOS classes with no shared mutable slots; no
  `change-class` method defined between kind classes) + `KERNEL`.
- Violation: VOID.
- Discharge: PO-001 (Alloy 6 structural model shows no path between kind sorts
  except via `Elevation`), plus a compile-time check that no `change-class`
  specialisation exists across kind classes.

### I-02 — Authority is never a property of a channel (L3, A1)
∀ authority assertion a, the justification of a mentions no observation channel,
endpoint, adapter, transport, or retrieval method.
- Enforcement: `KERNEL` — the authority derivation function's domain type does not
  include channel identifiers.
- Violation: VOID.
- Discharge: PO-002 (ACL2: the type signature of `authority-of` excludes channel;
  proved by construction of the datatype).

### I-03 — Adapters and models confer nothing (C3, A9)
∀ entry e produced by an adapter or by a machine-learned component,
kind(e) = `OBSERVATION`.

*(Revised, second audit round, finding HF-021.)* The first version admitted a
second kind, `PROPOSAL`, and thereby created a ninth entry kind inside a design
that claims exactly eight. Proposals no longer enter the record at all: they live
in the **proposal spool**, which is outside the kernel's domain entirely (I-45).
A machine-learned component therefore has exactly one record-affecting power, and
"a proposal can never be a premise" is no longer a rule about the support relation
but a consequence of the kernel being unable to see proposals.
- Enforcement: `ADMISSION` — the warrant of an adapter/model principal grants only
  `issue(OBSERVATION)`.
- Violation: VOID.
- Discharge: PO-003 (Alloy 6: no principal of class `Adapter` or `Model` holds any
  power whose product kind is other than `OBSERVATION`).

---

## PART II — EVIDENCE AND PROVENANCE

### R-02 Evidentiary lattice
The system shall represent evidentiary status as a finite partially ordered set
`E` with a bottom element, and shall never represent it as a number.

The lattice (⊑ reads "no stronger than"):

```
                 REPUDIATED (⊥ absorbing)
                      ⊑
      UNVERIFIED ⊑ SECONDARY ⊑ AUTHENTIC-UNSIGNED ⊑ AUTHENTIC-SIGNED
                                   ⊑
                            AUTHENTIC-SIGNED-ANCHORED
      DOCTRINAL  (incomparable to the authentic chain; never ⊒ SECONDARY)
      DISPUTED   (meet of any two incomparable non-⊥ statuses)
```

- `AUTHENTIC-SIGNED` requires a verified signature by a registered signing
  authority of the source (L4).
- `AUTHENTIC-SIGNED-ANCHORED` additionally requires an independent time anchor
  (qualified electronic time stamp under Regulation (EU) 910/2014, or inclusion
  proof in a witnessed append-only log). [ledger: RL-028, RL-011]
- `DOCTRINAL` is deliberately *incomparable* rather than low: doctrine is not weak
  authority, it is a different kind (L8).

### I-04 — Monotone degradation (A4)
∀ transformation T, ∀ artifact x: `rank(T(x)) ⊑ rank(x)`.
- Enforcement: `KERNEL` — transformations are represented as a closed algebra
  whose result status is computed, never supplied.
- Violation: VOID.
- Discharge: **PO-004** (ACL2 theorem `evidence-rank-monotone`: for the closed set
  of transformation constructors, `(<= (rank (apply-transform tr x)) (rank x))`).

### I-05 — Strength can rise only by acquisition + authentication
∀ artifact x, if `rank_t2(x) ⊐ rank_t1(x)` for t2 > t1, then there exists an
`ACQUISITION` entry and an `EVIDENCE` entry between t1 and t2 issued by the
Authentication office citing new material.
- Enforcement: `KERNEL`.
- Violation: VOID.
- Discharge: PO-005 (ACL2: `rank-increase-requires-new-evidence`).

### I-06 — Container preservation (L4)
∀ acquired artifact x that arrives inside a signed container, the container bytes
are retained in the artifact store unmodified, and every derived representation
records the container digest as an ancestor.
- Enforcement: `ADMISSION` — an `ACQUISITION` entry for a signed container whose
  container digest is absent is inadmissible.
- Violation: VOID.
- Discharge: PO-006 (runtime audit: for every artifact with derived children,
  ancestor-closure reaches a retained container digest or an explicit
  `NO-CONTAINER` attestation).

### I-07 — Lineage totality and reproducibility (A3)
∀ derived artifact y, there exists exactly one `DERIVATION` record naming
(inputs, transformation identity, kernel version hash) such that re-executing that
transformation at that version on those inputs yields a byte-identical y.
- Enforcement: `KERNEL` + `RUNTIME-AUDIT` (sampled re-execution).
- Violation: the derived artifact is marked `NON-REPRODUCIBLE`, which is ⊑
  `UNVERIFIED`, and any proposition depending on it is suspended.
- Discharge: PO-007 (deterministic simulation: sampled re-derivation equality).

**Note on honesty.** Some transformations (OCR with a nondeterministic engine,
model-based segmentation) are not byte-reproducible. The architecture does not
pretend otherwise: such transformations are *required* to be executed once and
their output *recorded as an artifact*, so the recorded output is reproducible even
though the process is not. The distinction "reproducible process" vs "recorded
result" is explicit in the derivation record (`process-deterministic: true|false`).

---

## PART III — LEGAL IDENTITY, AUTHORITY, AND TIME

### R-03 Four-level identity
The system shall distinguish, with separate identifier spaces:

1. **Norm identity** `N` — the institutional identity of a normative unit
   (e.g. "Article 66 of Law 4622/2019"), assigned only by the Registry.
2. **Expression identity** `X` — a textual version of a work at a language and a
   point on the amendment timeline; ELI/Akoma-Ntoso aligned. [RL-001, RL-003]
3. **Manifestation identity** `M` — a specific published rendering (a Gazette
   issue PDF, an HTML page). Aligned to IFLA LRM WEMI. [RL-029]
4. **Digest identity** `D` — the content hash of retrieved bytes.

### I-08 — Digest never confers norm identity (C3, A1)
There is no function from `D` to `N`. The mapping `D → M → X → N` exists only as a
chain of *warranted assertions*, each defeasible.
- Enforcement: `TYPE` (no accessor from digest to norm identity exists) +
  `KERNEL`.
- Violation: VOID.
- Discharge: PO-008 (Alloy 6: no relation `Digest → Norm` in the model).

### I-09 — Registry cannot create authority (A1, separation)
The Registry holds `assign-identity` and `confirm-identity`; it does not hold
`determine-authority`. An `AUTHORITY` entry warranted by the Registry is ⊥.
- Enforcement: `ADMISSION`.
- Violation: VOID.
- Discharge: PO-009 (Alloy 6 power-exclusivity check).

### I-10 — Identity assignments are themselves adjudicable
∀ identity assignment i, i carries a reopening predicate and may be defeated by a
Tribunal decision. There is no "final" identity that is immune to revision.
- Enforcement: `KERNEL`.
- Violation: the assignment is inadmissible at creation (missing reopening
  predicate).
- Discharge: PO-010 (schema obligation: `reopening-predicate` non-null).

### R-04 Temporal axes
The system shall represent, per **provision** (not per document), the following
independent axes, each as an adjudicated proposition (A5):

| Axis | Meaning | Legal ground |
|---|---|---|
| `t_enact` | vote / adoption of the instrument | domestic procedure |
| `t_promulgate` | promulgation by the President | Const. Art. 42 §1 (L1) |
| `t_publish` | publication in the Gazette | Const. Art. 42 §1 (L1) |
| `t_force` | entry into force of *this provision* | ΕισΝΑΚ Art. 103 default +10d, or express (L2) |
| `t_apply_from` / `t_apply_to` | applicability to facts (may precede `t_force`: retroactivity) | express provision |
| `t_end` | cessation | abrogation vs annulment (below) |
| `t_observe` | when the Watchtower observed the evidencing artifact | system |
| `t_record` | when the entry was appended (HLC) | system |
| `t_believe` | when the proposition was admitted | system |

### I-11 — Nine-axis independence
No axis may be derived by defaulting from another *silently*. Where a default is
applied (e.g. `t_force = t_publish + 10 days` under ΕισΝΑΚ Art. 103), the default
is recorded as a **defeasible inference with a named rule**, and the rule is
attackable.
- Enforcement: `KERNEL`.
- Violation: VOID.
- Discharge: PO-011 (ACL2: every `t_force` value in derived state has a non-empty
  justification set naming either an express provision or the default rule).

### R-05 Cessation trichotomy
The system shall distinguish three legally distinct ways a norm ceases, because
they have different effects on past applications:

- **Abrogation (κατάργηση)** — ceases *ex nunc*; past applications stand.
- **Annulment / invalidity (ακύρωση, ανίσχυρο)** — treated as never having had the
  effect claimed, *ex tunc*, within the scope declared by the annulling authority.
- **Correction (διόρθωση σφάλματος)** — the published text is replaced by a
  corrected text; the *norm* is treated as having always been the corrected text
  in the scope of the correction, but the superseded text remains evidence of what
  was published. Statutory basis: Law 3469/2006 Art. 16 §§4–5 (L5). [RL-026]

The distinction between abrogation and annulment and their differing temporal
treatment is established in the legal-informatics literature on temporalised
defeasible logic. [RL-013]

### I-12 — Cessation kind is never defaulted
∀ cessation record c, `kind(c) ∈ {ABROGATION, ANNULMENT, CORRECTION}` is asserted
by a Tribunal decision citing the cessating instrument. A cessation of unknown kind
is recorded as `CESSATION-KIND-UNDETERMINED` and **suppresses** any point-in-time
answer whose interval spans the cessation.
- Enforcement: `KERNEL`.
- Violation: VOID; answers depending on it are refused, not guessed.
- Discharge: PO-012 (Alloy 6 temporal: no reachable state emits a point-in-time
  answer over an interval containing an undetermined cessation).

### I-13 — Retained superseded text
∀ correction c replacing text `x` by `x'`, both `x` and `x'` remain retrievable,
and any prior published answer grounded in `x` is linked to c.
- Enforcement: `KERNEL` (A2: correction is an append) + `RUNTIME-AUDIT`.
- Violation: SUSPEND publication power (an institution that loses its superseded
  evidence cannot honestly explain its past answers).
- Discharge: PO-013.

### I-39 — Interval algebra soundness
*(Added by hostile-audit finding HF-009: the temporal model carried adequacy claims
with no obligation covering the algebra itself.)*

The interval algebra over endpoints `{CLOSED, OPEN, UNKNOWN, CONDITIONAL}` is
sound: intersection, containment and adjacency are total; `UNKNOWN` and
`CONDITIONAL` endpoints propagate to the result rather than being coerced to a
date; and `contains?(I, t)` returns one of `{true, false, indeterminate}` — never
`false` where the truth is unknown.
- Enforcement: `KERNEL`.
- Violation: VOID; the derived temporal proposition is inadmissible.
- Discharge: **PO-039** (ACL2: totality of the algebra; and
  `no-unknown-collapses-to-false`, i.e. for every interval containing an `UNKNOWN`
  or unsatisfied `CONDITIONAL` endpoint straddling `t`, `contains?` yields
  `indeterminate`).

**Why this matters.** Without it, "in force from an unknown date" silently becomes
"not in force", which is the most dangerous possible default in a legal system: it
converts ignorance into a negative assertion.

### I-40 — Amendment-chain confluence
*(Added by hostile-audit finding HF-009.)*

Reconstructing the text of a provision at time `t` from a set of modification
instruments is **order-independent given the temporal ordering**: for any two
application orders consistent with the admitted `t_force` propositions of the
modifying instruments, the reconstructed text is identical. Where two modifications
have overlapping scope and no admitted ordering between them, the reconstruction
yields `RECONSTRUCTION-AMBIGUOUS` rather than an arbitrary result.
- Enforcement: `KERNEL`.
- Violation: VOID.
- Discharge: **PO-040** (ACL2: confluence over the modification-application
  relation restricted to temporally ordered pairs; and the ambiguity witness for
  unordered overlapping pairs).

**Why this matters.** Watchtower reconstruction (I-14, third class) is the answer
most often requested and the one with no official text to check against. An
order-dependent reconstruction would be wrong in a way nothing else in the design
would detect.

### I-14 — The consolidation classes never merge (L6)
`OFFICIAL-CODIFICATION`, `OFFICIAL-CONSOLIDATED-REPUBLICATION` and
`WATCHTOWER-RECONSTRUCTION` are distinct classes; a reconstruction may never be
returned in answer to a request for an official codified text, and the
distinction is present in every emitted citation.
- Enforcement: `TYPE` + `ADMISSION` at the publication boundary.
- Violation: VOID.
- Discharge: PO-014.

---

## PART IV — EPISTEMIC STATE

### R-06 Belief representation
Every belief is the conclusion of at least one **argument**: a tree of strict
and defeasible rule applications over premises, where every leaf premise is either
an `EVIDENCE`-backed proposition or a declared **assumption**.

### R-07 Assumption discipline
The assumption vocabulary is closed and finite by class:
`A-AUTHENTICITY`, `A-COMPLETENESS`, `A-IDENTITY`, `A-READING`,
`A-TEMPORAL-DEFAULT`, `A-SOURCE-FIDELITY`, `A-TRANSLATION`. Every assumption
instance names its class, the entity it concerns, and its falsifier.

### I-15 — No unsupported belief
∀ belief b in the epistemic store, `support(b) ≠ ∅` and every element of
`support(b)` is an argument whose leaves are `EVIDENCE`-backed or declared
assumptions.
- Enforcement: `KERNEL`.
- Violation: VOID.
- Discharge: PO-015 (ACL2: `label-soundness`).

### I-16 — Defeat propagates without recomputation of unrelated beliefs
When an assumption `a` is defeated, every belief whose every supporting
environment contains `a` becomes `UNSUPPORTED` in the same derivation step.
- Enforcement: `KERNEL` (assumption-based label propagation, de Kleer ATMS
  semantics). [RL-009]
- Violation: VOID (a belief surviving the defeat of all its supports is an
  unsound label).
- Discharge: PO-016 (ACL2: `defeat-propagation-complete`).

### I-17 — No-good soundness
∀ recorded no-good `η` (a minimal inconsistent environment), no belief is labelled
with a superset of `η`.
- Enforcement: `KERNEL`.
- Discharge: PO-017 (ACL2: `nogood-superset-exclusion`).

### I-18 — Declared incompleteness, never silent truncation (C7)
If label computation exceeds the declared bound `B_label`, the affected belief is
marked `LABEL-INCOMPLETE`; a condition is signalled; the belief may not support a
publication; and the docket is queued for bounded re-adjudication.
- Enforcement: `KERNEL` returns an explicit status; the shell signals.
- Violation: this is the *anti-silent-degradation* invariant; a build in which
  truncation can occur without the status is rejected.
- Discharge: PO-018 (deterministic simulation with adversarial assumption graphs
  designed to exceed `B_label`, asserting the status is always produced).

### I-19 — Conflict resolution is by declared meta-norms, never by tie-break
Conflicts between arguments are resolved by a declared, inspectable preference
relation over rules. The Watchtower's default ordering encodes the classical legal
meta-norms as **defeasible** rules — *lex superior*, then *lex specialis*, then
*lex posterior* — each of which is itself attackable by a Tribunal decision.
Unresolved conflict yields `UNDECIDED`, not an arbitrary winner.
- Enforcement: `KERNEL`.
- Violation: VOID.
- Discharge: PO-019 (ACL2: preference relation is a strict partial order;
  `no-arbitrary-resolution`: the resolver is a function of the declared ordering
  only).

### I-20 — Doctrine cannot ground authority (L8)
∀ argument A concluding an `AUTHORITY` proposition, no leaf of A has evidentiary
status `DOCTRINAL`.
- Enforcement: `KERNEL`.
- Violation: VOID.
- Discharge: PO-020 (ACL2: `authority-arguments-doctrine-free`).

---

## PART V — SELF-MODEL AND METACOGNITION

### R-08 Self-model content (C5)

**Two distinct bodies, deliberately separated** (revision arising from hostile-audit
finding HF-002).

**(a) Constitutional facts** — identity, mandate, offices, powers, jurisdiction,
authority boundaries. These are *record facts* derived from the Charter. They are
required by C5 and are queryable as part of the institution's explicit self-model,
but they are **not** subject to A6, because a constitutional fact has no falsifier
distinct from the record itself: "the Registry holds the identity power" is true
because the Charter says so, and is changed by amendment, not by refutation.
Applying A6 to them would either force fabricated falsifiers or force their
exclusion from C5's required self-knowledge. Both are wrong; the separation is the
correct resolution.

**(b) Self-model propositions** — claims about the institution's own *epistemic and
operational adequacy*. These live in the same epistemic store as world propositions,
are subject to the same defeat mechanics, and **are** subject to A6 (I-21):

- coverage propositions per (source × series × period);
- lag propositions per source;
- uncertainty propositions per proposition class;
- conflict-inventory propositions;
- intention propositions (current observation plan and its justification);
- decision-history propositions;
- **procedural-validity propositions** — "the institution's own procedures remain
  valid", i.e. the runtime status of each invariant in this document.

### I-21 — A6 triple (anti-decoration)
∀ proposition s of body R-08(b): s declares a truth condition over the record, an
executable falsifier, and at least one institutional consequence. Constitutional
facts (R-08(a)) are outside the scope of this invariant and are outside the
epistemic store's defeat mechanics; a proposition asserted as R-08(a) that is not
derivable from the Charter is inadmissible.
- Enforcement: `ADMISSION` (schema) + `RUNTIME-AUDIT` (the Inspectorate executes
  falsifiers on a schedule).
- Violation: the proposition is inadmissible.
- Discharge: PO-021 (schema check + an enumeration audit that reports any
  R-08(b) proposition class whose consequence set is empty, **and** any proposition
  classified R-08(a) that is not Charter-derivable — the latter closes the evasion
  in which a weak self-model claim is reclassified as constitutional to escape A6).

### I-22 — Self-model causation is structural, not advisory
The observation plan is a *derived object*: `plan = Π(self-model propositions)`.
No scheduling decision may be taken that is not a consequence of self-model
propositions plus the Charter.
- Enforcement: `KERNEL` (the planner is part of the pure kernel; the shell only
  executes the plan).
- Violation: VOID.
- Discharge: PO-022 (ACL2: `plan-is-function-of-selfmodel`).

### I-23 — Suspension power (C4 with causal effect)
If the Inspectorate admits `PROCEDURE-INVALID(x)` for any invariant x classified
as *publication-critical*, the publication power is SUSPENDED institution-wide
until a warranted restoration act. Suspension is not a warning.
- Enforcement: `ADMISSION` at the publication boundary.
- Violation: VOID publication.
- Discharge: PO-023 (Alloy 6 temporal: no trace contains a `PUBLISH` event after
  `PROCEDURE-INVALID` and before `RESTORE`).

### I-24 — Silence/blindness separability (A7)
∀ (source, window) pair, the coverage proposition is one of
`COVERED`, `GAP-CONFIRMED` (source published, we lack it),
`SOURCE-SILENT` (source live, published nothing),
`INDETERMINATE-COVERAGE` (cannot distinguish).
No completeness claim may be published over a window containing
`INDETERMINATE-COVERAGE`.
- Enforcement: `KERNEL` + publication `ADMISSION`.
- Violation: VOID.
- Discharge: PO-024 (simulation: for a source with no structural signal, the
  system must reach `INDETERMINATE-COVERAGE` and must not reach `COVERED`).

### I-41 — Self-model falsifiers are evaluated by an independent verification kernel
*(Added, second audit round, closing finding HF-001, which the creator ruled a
defect rather than an inherent limit.)*

There are **two** kernels, not one:

| | `K_v` — derivation kernel | `V_w` — verification kernel |
|---|---|---|
| computes | the full institutional state | only: admission decisions (I-46), publication-critical invariant checks, and self-model falsifier outcomes |
| authored | independently | independently, from the same written specification, by a different author, using a different algorithmic approach |
| admitted | in ACL2 | in ACL2, separately |
| used by | every office | **the Inspectorate only** |
| shares code with the other | — | **nothing** (I-42) |

Requirements:

1. ∀ publication-critical invariant `x` and ∀ self-model falsifier `f`, the
   Inspectorate's verdict is computed by `V_w`, never by `K_v`.
2. `V_w` reads `R` and `A|_R` directly. It does **not** read `K_v`'s output, so it
   cannot inherit `K_v`'s errors.
3. Coverage falsifiers are recomputed by `V_w` from the **raw observation entries**
   — including the vitality-probe results — and not from `K_v`'s coverage
   propositions.
4. Disagreement between `K_v` and `V_w` on any publication-critical invariant or
   any falsifier outcome is fault **F15**: it admits `PROCEDURE-INVALID` and
   suspends the publication power (I-23). Agreement is not required for the
   institution to run; it is required for the institution to **speak**.

- Enforcement: `TYPE` (the Inspectorate package imports `V_w` and does not import
  `K_v`) + `ADMISSION` + `RUNTIME-AUDIT`.
- Violation: VOID; and an Inspectorate verdict traceable to `K_v` is itself a
  `PROCEDURE-INVALID` condition.
- Discharge: **PO-041** (ACL2, on `V_w`: the same theorems as the corresponding
  `K_v` obligations for the publication-critical subset, proved over the
  independent implementation; plus a runtime differential audit that `K_v` and
  `V_w` agree on the regression corpus).

**What this buys, stated precisely.** The first version's defect was that a defect
in `K_v` would corrupt both the world model and the audit of the world model, so
the institution could be confidently wrong about being right. That is now false for
the publication-critical subset: a defect in `K_v` alone produces **disagreement**,
which is detected and which stops publication. The institution can still be wrong —
but it can no longer be wrong *and confident* through a single point of failure.

**What it does not buy.** Common-mode failure remains: both kernels implement the
same written specification, so a defective *specification* corrupts both, and both
run on the same SBCL and are checked by the same ACL2. This is a materially smaller
and materially different residual — a specification risk rather than a
self-reference risk — and it is carried as DF-043. Scope is also bounded: `V_w`
covers the publication-critical subset, not the whole state, because an independent
re-implementation of the entire kernel would double the specification surface
without doubling the assurance.

### I-42 — Kernel code disjointness
*(Added, second audit round; makes I-41 checkable rather than aspirational.)*

`K_v` and `V_w` share **no code**. Formally: the transitive closure of the packages
and systems reachable from `V_w` intersects the transitive closure reachable from
`K_v` only in (i) the ANSI Common Lisp package and (ii) a shared, frozen,
separately verified *datum* library containing the record and artifact **decoders**
and nothing else.

The decoder exception is stated rather than hidden: both kernels must agree on what
the bytes of an entry mean, or they are not verifying the same thing. The decoders
are therefore the one deliberate shared dependency, they are frozen, they are
separately ACL2-verified, and a decoder defect is an acknowledged common-mode path
(DF-043).

- Enforcement: build-time import-closure audit.
- Violation: the build fails.
- Discharge: **PO-042** (mechanical: compute both closures, assert the intersection
  equals the permitted set exactly).

---

## PART VI — DELIBERATION AND DECISION

### R-09 Docket
Every admission of an `INTERPRETATION`, `AUTHORITY`, or non-trivial `INFERENCE`
proposition occurs in a **docket** with: a question; an evidence set; constructed
arguments; a recorded contradiction attempt; an admission determination; reasons;
and a **reopening predicate**.

### I-25 — Mandatory contradiction (A11)
∀ docket δ admitting a defeasible conclusion, δ contains either at least one
constructed counter-argument, or a record `CONTRADICTION-NOT-CONSTRUCTIBLE` with
its reason and a syntactic witness that the derivation used no defeasible rule.
- Enforcement: `KERNEL`.
- Violation: VOID admission.
- Discharge: PO-025 (ACL2: `docket-admissibility` requires the disjunct; the
  syntactic witness is checkable because "uses no defeasible rule" is decidable on
  the argument tree).

### I-26 — Every decision carries its own falsifier
∀ decision d, `reopening-predicate(d)` is a total, decidable predicate over record
prefixes. When it becomes true, the docket reopens automatically.
- Enforcement: `KERNEL` (evaluation of reopening predicates is part of the fold).
- Violation: inadmissible decision.
- Discharge: PO-026 (ACL2: reopening predicates are drawn from a closed,
  total, decidable predicate language).

### I-48 — Cleanup completion is not claimed without an aggregate protocol
*(Added, fifth audit round, R5 finding 10.)*

ANSI `UNWIND-PROTECT` guarantees **entry** into the cleanup forms on normal or
non-local exit from the protected form. It gives a cleanup form no further
protection: if one `:record` method signals or throws, later `:record` methods do
not run. Therefore the institution may **partially record** an act.

The architecture does **not** currently claim otherwise, and does not yet specify
the remedy. Two admissible resolutions, neither yet built:

1. an **aggregate-cleanup protocol** — each required record action wrapped in its
   own nested `UNWIND-PROTECT`, failures collected, the original condition
   re-signalled after all attempts; or
2. the narrower claim, which is what the package asserts today: *entry into
   cleanup is guaranteed; completion is not*.

- Enforcement: none available today; this is a stated residual, not a mechanism.
- Discharge: **PO-048** (specify the aggregate protocol, then verify the actual
  macroexpansion in a pinned SBCL: every required record action attempted, the
  original failure preserved). **NOT DISCHARGED — no Common Lisp implementation is
  available in this environment, so the macroexpansion has not been inspected.**
- Residual defeater: **DF-050** (OPEN).

### I-27 — Reproducibility of admission
Re-running the kernel at the recorded version on the recorded environment yields
the same admission outcome.
- Enforcement: `RUNTIME-AUDIT` (sampled) + replay.
- Violation: the decision is marked `NON-REPRODUCIBLE`; publication power for
  dependent answers is SUSPENDED.
- Discharge: PO-027.

---

## PART VII — RECORD, STATE, AND EVOLUTION

### I-28 — Append-only, hash-chained, ordered (A2)
The record is a sequence of entries; entry *n* commits to entry *n−1* by hash;
each entry carries a hybrid logical clock stamp preserving causality with bounded
divergence from physical time. [RL-018]
- Enforcement: `ADMISSION`.
- Discharge: PO-028 (TLA+: append safety under crash; Merkle consistency proof
  verification per RFC 9162 §2 semantics). [RL-011]

### I-29 — Kernel purity and the exact derivation identity (A3)
*(Restated, second audit round, finding HF-020. The first version asserted claim
**WC-8**: the kernel must read artifact bytes to derive anything about a text, and
the elided dependency on the artifact store was a genuine hole in the central axiom
of the architecture.)*

The derivation identity is:

```
state = K_v(R, A|_R)
```

where `A|_R` is the artifact store **restricted to the digests named in R**.

The following make this a function of `R` alone in every sense that matters:

1. **Content addressing.** `A` is keyed by digest and is write-once, so for a given
   digest there is exactly one possible byte sequence. `A|_R` is therefore uniquely
   determined by `R` whenever every named digest is resolvable.
2. **R-boundedness** (I-43). `A` may contain nothing that `R` does not name, so `A`
   cannot carry hidden state that influences derivation.
3. **Totality under unresolvability** (I-44). Where a named digest is *not*
   resolvable, `K_v` is still total and returns a state carrying explicit
   unresolved-artifact status rather than diverging or guessing.

Everything else stands: no ambient effect; time, randomness, network and filesystem
enter only as entries.
- Enforcement: `PROOF` — **ACL2 admissibility is the guarantee**: ACL2's logic has
  no notion of a side effect, so a function that calls `OPEN` cannot be admitted at
  all. Supported by `TYPE`: the artifact store is passed as an explicit argument
  and never reached through a global, which is what makes admissibility achievable.
  *(Corrected, third audit round, HF-026: the previous enforcement clause asserted
  claim **WC-3**, which does not establish purity — `OPEN`, `READ`, `RANDOM`,
  `GET-UNIVERSAL-TIME` and `DELETE-FILE` are all symbols in the `COMMON-LISP`
  package, so a kernel importing only `COMMON-LISP` can still perform I/O. A
  denylist over `COMMON-LISP` itself is retained as a fast-fail check, not as the
  guarantee.)*
- Discharge: PO-029 (ACL2 admissibility of the kernel — an ACL2-admitted function
  is applicative by construction; plus the `COMMON-LISP` effectful-symbol denylist
  as a fast-fail pre-check; plus a signature audit that `K_v` takes `A|_R` as a
  parameter and performs no I/O to obtain it).

### I-43 — The artifact store is R-bounded
*(Added, second audit round, finding HF-020.)*

∀ artifact `a ∈ A`, some entry of `R` names `digest(a)`. An artifact present in `A`
and named nowhere in `R` is **not evidence**: it is unaccounted bytes, and its
presence would mean `A` holds state outside the record's account of the
institution's history.

- Enforcement: `ADMISSION` (an `ACQUISITION` entry is what admits bytes to `A`, so
  the invariant holds by construction on the write path) + `RUNTIME-AUDIT` (a
  scheduled sweep reports any unnamed artifact).
- Violation: unnamed artifacts are quarantined, not deleted — deletion would
  destroy possible evidence of a fault — and the sweep result is a self-model
  proposition subject to A6.
- Discharge: **PO-043** (runtime audit: `∀a ∈ A. ∃e ∈ R. digest(a) ∈ names(e)`).

**Why this matters.** Without R-boundedness, `A` is a second, unaccounted authority
and the deletability test (A8/I-31) proves nothing, because a rebuild could silently
draw on bytes the record never mentioned.

### I-47 — Staged admission with atomic promotion
*(Added, third audit round, finding HF-029; closes the crash window in I-43.)*

Bytes enter `A` **only** by atomic promotion from a staging area `S`, and only
after the `ACQUISITION` entry naming their digest is committed:

```
fetch → S/d  →  fsync  →  append ACQUISITION(d) to R  →  rename(S/d → A/d)
```

Requirements:

1. `S` is not `R`, not `A`, not `P`, and is **not an argument of either kernel**.
2. Promotion is a same-volume rename and is therefore atomic; cross-volume staging
   is prohibited, because a copy has a torn window and a rename does not.
3. Promotion is **idempotent and resumable**: recovery promotes any `R`-named
   digest that is absent from `A` and present in `S`.
4. Every staged object terminates in exactly one of *promoted*,
   *discarded-as-torn*, or *garbage-collected*, and the latter two are **recorded**.
   A silently discarded fetch is impossible.
5. The ordering is entry-first, not promote-first, so the unavoidable crash window
   leaves `R` naming a digest `A` lacks — a state **I-44 already governs** — rather
   than `A` holding bytes `R` does not name, which would be a bare I-43 violation.

- Enforcement: `TYPE` (kernel signatures exclude `S`) + `ADMISSION` + recovery
  reconciliation.
- Violation: an artifact appearing in `A` by any path other than promotion is an
  I-43 violation and is quarantined.
- Discharge: **PO-047** (TLA+: model the five-step protocol with a crash action at
  every point; assert that no reachable state has an object in `A` unnamed by `R`,
  and that every staged object reaches a terminal disposition).

**Why this is an invariant and not an implementation note.** The ordering is the
only thing standing between the architecture and an unaccounted second authority.
Reversing steps 3 and 4 — which is the more obvious order, since it puts the bytes
in place before announcing them — silently breaks G2.

### I-44 — Kernel totality under unresolved artifacts
*(Added, second audit round, finding HF-020.)*

If `R` names a digest that `A` cannot resolve — because of corruption (F3), mandated
erasure (F13), or an incomplete replica — then:

1. `K_v` returns normally (it is total);
2. every belief whose support requires the unresolved bytes takes status
   `UNSUPPORTED-BY-UNRESOLVED-ARTIFACT`, distinct from `UNSUPPORTED` and from
   `UNSUPPORTED-BY-ERASURE`, so the record shows *why*;
3. the derived state carries a global `DERIVATION-INCOMPLETE(D)` marker naming the
   exact set `D` of unresolved digests;
4. no publication may draw on a `DERIVATION-INCOMPLETE` state without naming `D`.

- Enforcement: `KERNEL`.
- Violation: VOID (a kernel that silently substitutes, skips or guesses for an
  unresolved artifact is the archetypal silent degradation C7 forbids).
- Discharge: **PO-044** (ACL2: totality of `K_v` over partial `A`, and
  `unresolved-propagates`: no belief is `SUPPORTED` if its support closure contains
  an unresolved digest).

### I-45 — Proposals are outside the kernel's domain
*(Added, second audit round, finding HF-021.)*

Machine-learned and heuristic output is written to a **proposal spool** `P`, which:

- is **not** part of `R` and **not** part of `A`;
- is **not** an argument of `K_v` — the kernel's signature does not mention it, so
  a proposal is not merely excluded from the support relation, it is *invisible to
  the derivation*;
- is fully **deletable** at any time with no effect on `state` (A8), and is
  routinely deleted;
- may be referenced from a real entry only by *digest*, as a provenance annotation
  recording that a proposal existed and what it hashed to — never by content.

- Enforcement: `TYPE` (the kernel's parameter list) + `ADMISSION` (an entry whose
  payload embeds proposal content rather than a proposal digest is inadmissible).
- Violation: VOID.
- Discharge: **PO-045** (signature audit on `K_v`; plus a schema check that
  proposal references are digests).

**Why the spool rather than a ninth entry kind.** Three reasons, in order of
weight. (i) It makes the eight-kind claim true without qualification. (ii) It makes
non-premisehood structural rather than relational: the kernel cannot read a
proposal, so no rule change and no coding error can turn one into a premise.
(iii) It keeps unbounded model output out of the record, whose length drives
rebuild cost (DF-009) — putting proposals in `R` would have made the institution's
memory grow with its guessing rather than with its knowledge.

### I-46 — Admission is call-path independent
*(Added, second audit round, finding HF-022; closes DF-002.)*

Whether an entry is admitted is a **pure function of the Charter and the entry**,
evaluated at the append point by the verification kernel `V_w` (I-41). It does not
depend on, and does not trust, any warrant object constructed by the caller:

```
admit?(charter, entry) : boolean          -- total, decidable, ACL2-admitted
```

The gate independently reconstructs, from the Charter's power table, whether
`office(entry)` holds `issue(kind(entry), fact-class(entry))`, and verifies that the
entry's warrant is a Charter-derived capability bound to the entry's content digest.
A forged, absent, stale, or scope-mismatched warrant fails regardless of how the
call arrived.

- Enforcement: `ADMISSION`, evaluated in `V_w`, which imports no office package.
- Violation: VOID.
- Discharge: **PO-046** (ACL2: `no-entry-committed-outside-charter` — for all
  entries, `committed(e) ⇒ charter-permits(office(e), kind(e), fact-class(e))`,
  proved over the admission function without reference to any call path).

**What this replaces.** The first version enforced warrants through a custom method
combination at the *call* site (D02). That mechanism polices generic-function calls
only, so an ordinary in-office function call bypassed it — recorded as DF-002 and
wrongly accepted as merely *bounded*. Enforcement now sits at the append point,
where every entry must pass regardless of provenance; the method combination is
retained as **defence in depth** (it fails fast and produces a good diagnostic) but
is no longer the guarantee.

### I-30 — Version-stamped conclusions
∀ derived proposition p, p carries the content hash of the kernel version that
produced it.
- Enforcement: `KERNEL`.
- Discharge: PO-030.

### I-31 — Non-authority by deletability (A8, G2)
∀ store `S ∉ {R, A, P}`: deleting `S` and re-running `K_v(R, A|_R)` reproduces `S`
exactly.

*(Restated, second audit round, finding HF-020/HF-023.)* Three corrections to the
first version. (i) The rebuild input is `(R, A|_R)`, not `R` alone. (ii) The
proposal spool `P` is exempt **in the opposite direction**: it is not an authority
either, it is *pure scratch* — deleting it must change nothing at all, which is a
stronger and separately checked property (`delete P ⇒ state unchanged`), and is the
operational meaning of I-45. (iii) `A` is exempt from *rebuildability* because its
bytes come from the world and cannot be recomputed — but it is not thereby
unchecked: it is **verifiable** (the digest is the address) and **bounded** (I-43),
which together are what make its authority accountable.

So the three exemptions have three different justifications, and none of them is
"it is convenient":

| Store | Status | Why exempt from rebuild-and-compare |
|---|---|---|
| `R` | authority | it *is* the input; nothing to rebuild it from |
| `A` | authority | not recomputable (bytes came from the world), but digest-verifiable and R-bounded |
| `P` | scratch | not an authority and not derived; the check is that deleting it changes nothing |

- Enforcement: `RUNTIME-AUDIT` — executed as a scheduled *experiment*, not an
  assertion.
- Violation: `S` is an authority ⇒ the configuration is unconstitutional ⇒ SUSPEND
  publication.
- Discharge: PO-031 (scheduled rebuild-and-compare in a sandbox region, plus the
  `delete P` null-effect check).

### I-32 — Regression obligation on kernel change (O8)
A new kernel version `v'` may be promoted only if, for the designated regression
corpus `C` of previously admitted decisions, every decision either reproduces
under `v'`, or has an admitted `DIVERGENCE` record explaining and justifying the
change. Unexplained divergence blocks promotion.
- Enforcement: `ADMISSION` of the promotion act.
- Violation: VOID promotion.
- Discharge: PO-032 (executable: replay `C` under `v` and `v'`, diff, require an
  admitted divergence for each difference).

### I-33 — Class evolution under warrant (C11, MOP)
∀ redefinition of a persistent class, there exists a migration warrant naming the
old and new class layout hashes and a total migration function; instance update
occurs through the standard CLOS redefinition protocol and is recorded.

*(Revised, second audit round, finding HF-024. The first version's MOP enforcement
was both incompletely specified and hooked in the wrong place.)*

**Corrections.**

1. **Redefinition hook.** The guard belongs on `ensure-class-using-class`, which is
   the metaobject protocol's redefinition entry point invoked by `defclass`
   expansion — not on `reinitialize-instance` on the class, which the first version
   named and which is not the protocol's defined interception point for
   redefinition.
2. **Slot-access coverage.** Guarding `(setf slot-value-using-class)` alone is
   insufficient. `slot-makunbound-using-class` must also be specialised, or a slot
   can be unbound without a warrant; and `shared-initialize` / `initialize-instance`
   must be handled explicitly, because construction legitimately writes slots before
   any act warrant exists and therefore requires a distinct *construction warrant*
   binding rather than an exemption.
3. **Scope of the guarantee.** The AMOP slot-access protocol is honoured for
   instances of a custom metaclass, which institutional classes have; it is not a
   portable guarantee for `standard-class`, where implementations may optimise
   access. A build-time audit therefore asserts that no institutional class is
   reached through low-level instance access (`standard-instance-access` and
   equivalents). This is an implementation-dependent guarantee pinned to SBCL, and
   it is recorded as such (DF-046).
4. **Status relative to enforcement.** Following I-46, the MOP guard is **defence
   in depth**, not the guarantee. The guarantee that nothing enters the
   institution's state without a warrant lives at the append point in `V_w`, which
   is call-path independent and provable. The MOP guard catches unwarranted
   *in-memory* mutation early and with a good diagnostic; it does not have to be
   airtight for the invariant to hold, because unwarranted in-memory mutation of a
   derived store is corrected by the next rebuild-and-compare (I-31).

- Enforcement: `ADMISSION` (authoritative) + metaclass (defence in depth).
- Violation: VOID redefinition.
- Discharge: PO-033 (schema and warrant check) + the build-time low-level-access
  audit.

### I-34 — Entrenchment (A10)
An entry purporting to amend an entrenched axiom is ⊥ and is recorded as an
attempted constitutional violation, which itself triggers Inspectorate review.
- Enforcement: `ADMISSION`.
- Discharge: PO-034 (Alloy 6: no reachable state has an entrenched axiom absent).

---

## PART VIII — PUBLICATION BOUNDARY

### R-10 Answer shape
Every emitted answer carries: the proposition; every temporal axis relevant to it;
the evidentiary basis with statuses; the argument structure; the defeaters
considered and their disposition; the coverage status of every source the answer
depends on; the kernel version; and an explicit statement of what is *not* known.

### I-35 — No answer above its support
An answer's asserted strength is the meet (⊓) of the strengths of its supporting
leaves. It cannot exceed any leaf.
- Enforcement: `KERNEL`.
- Discharge: PO-035 (ACL2: `answer-strength-is-meet`).

### I-36 — Refusal is a first-class outcome
When support is insufficient, the system emits a **structured refusal** naming the
missing evidence and the acquisition action that would resolve it. It never
substitutes a lower-confidence answer silently.
- Enforcement: publication `ADMISSION`.
- Discharge: PO-036 (simulation: withhold a required gazette issue; assert the
  system refuses and names the missing issue).

### I-37 — No model-authored propositional content (A9)
∀ emitted answer, the propositional content is a rendering of admitted
propositions; a language model may alter surface form only. A rendering that
changes the entailment set is rejected by a deterministic round-trip check.
- Enforcement: publication `ADMISSION` (round-trip: parse the rendered answer's
  claim slots back to proposition identifiers and compare sets).
- Violation: VOID.
- Discharge: PO-037.

---

## PART IX — FAILURE AND OPERATING MODEL

The invariants above must hold under the following declared operating model. An
invariant that holds only under fault-free operation is not an invariant.

### Operating assumptions (declared, falsifiable)
- **OA-1** The Watchtower runs as one institution with one logical record; the
  record may be replicated for availability but has a single logical order.
- **OA-2** Sources are untrusted, non-transactional, rate-limited, occasionally
  mutating published bytes without notice (L5), and occasionally unreachable.
- **OA-3** Clocks are synchronised only to NTP-grade accuracy; causality must not
  depend on wall-clock ordering. [RL-018]
- **OA-4** The Greek legal corpus is bounded: the structured legal state is small
  enough to hold in memory on a single commodity machine; the artifact corpus is
  large but immutable and content-addressed. (Falsifier: measured corpus size
  exceeding the declared budget — see DF-021.)
- **OA-5** Operators are trusted for availability but **not** trusted for
  integrity: the design must make operator tampering *detectable*, not impossible.

### Declared fault classes
F1 process crash; F2 partial write / torn record entry; F3 storage corruption
(silent bit rot); F4 source unreachable; F5 source silently mutated; F6 source
serves wrong content (substitution); F7 clock jump (forward/backward); F8 network
partition between replicas; F9 kernel bug producing wrong derivation; F10
resource exhaustion during label computation; F11 model component producing
plausible-but-false proposals; F12 operator tampering with the record; F13 legally
mandated erasure conflicting with A2; F14 charter amendment error; **F15
verification-kernel divergence** — `K_v` and `V_w` disagree on a
publication-critical invariant or a self-model falsifier outcome (added with I-41;
this fault class exists *because* the remedy exists, and its firing is the signal
that the remedy is working).

Each fault's semantics, detection, and recovery are specified in
PHASE-2-FAILURE-AND-RECOVERY-MODEL.md. The requirement here is:

### I-38 — Invariant preservation under fault
For each fault F1–F15, the failure model states, for every non-meta invariant
(I-01…I-37 and I-39…I-47 — forty-six in total; I-38 itself is the meta-invariant
and is excluded), whether it is *preserved*, *temporarily suspended with a named
status*, or *violated with a named recovery*. No invariant may be left unaddressed
for any fault.
- Discharge: PO-038 (coverage matrix: one cell per non-meta invariant per fault
  class, no empty cell; totality is achieved by an explicit default rule plus
  enumerated exceptions. Dimensions and cell count are derived into the seal, not
  restated here).

---

## PART X — PROOF OBLIGATION SUMMARY

| Tool | Obligations | Rationale |
|---|---|---|
| **ACL2** (executable logic of applicative Common Lisp) [RL-014] | PO-002, PO-004, PO-005, PO-011, PO-015, PO-016, PO-017, PO-019, PO-020, PO-022, PO-025, PO-026, PO-029, PO-035, PO-039, PO-040, **PO-041** (on `V_w`), **PO-044**, **PO-046** | The kernel *is* Common Lisp: no extraction step and no re-implementation, so the **translation** gap is eliminated. The logic-to-execution gap is **narrowed to three named seams** (guard verification, ACL2 surface syntax, host conformance), not closed — see PHASE-2-LISP-NATIVE-DESIGN.md §1.0, DF-011, DF-048. |
| **Mechanical build-time audit** | **PO-042** (kernel import-closure disjointness), **PO-045** (kernel signature excludes the proposal spool), the effectful-symbol denylist over `COMMON-LISP` supporting I-29, low-level-instance-access audit for I-33 | Properties of the program's structure, decidable without proof search. |
| **Scheduled runtime sweep** | **PO-043** (artifact store is R-bounded) | A property of stored state, checkable only against the live store. |
| **Alloy 6** (relational + LTL) [RL-015] | PO-001, PO-003, PO-008, PO-009, PO-012, PO-023, PO-034 | Structural power exclusivity and finite-scope temporal lifecycle properties. |
| **TLA+ / Apalache / TLAPS** [RL-016] | PO-028, **PO-047** (staged admission with a crash action at every step), and the concurrency/liveness obligations of the failure model | Protocol-level safety and liveness under crash and partition. |
| **Deterministic simulation** (FoundationDB-style, same scheduler in production and test) [RL-017] | PO-007, PO-018, PO-024, PO-027, PO-031, PO-032, PO-036, PO-037, PO-038 | Whole-system properties not reducible to a kernel theorem. |
| **Schema / compile-time checks** | PO-006, PO-010, PO-013, PO-014, PO-021, PO-030, PO-033 | Structural admissibility. |

### Explicitly *not* proved — CANONICAL ENUMERATION

*(Codified in the fourth audit round, finding HF-032. This list previously appeared
in several artifacts at several different lengths, one of which stated a length
smaller than the list it introduced. It is now the single source: every other artifact refers to
`UP-n` and none restates the list or its length. The sealing script extracts the
codes from this section, so a divergence is a build failure rather than a reading
error.)*

- **UP-1 — ACL2 ⟷ host semantic conformance.** ACL2 verifies an applicative subset
  under its own logic and guard discipline; execution on the host relies on the
  correspondence between that logic and the implementation, and holds for
  guard-verified functions on guard-satisfying inputs. *Argued, not proved.*
  → DF-011 (**OPEN**).
- **UP-2 — The ACL2 surface-syntax compatibility shim is unverified.** `xargs`
  declarations, `mbe`, `defthm` are not ANSI CL; a frozen shim makes them inert
  under plain CL and sits in the trusted computing base. → DF-048.
- **UP-3 — TLA+ model-to-shell refinement.** The specification is a model of the
  shell; the correspondence is argued, not compiled. → DF-012.
- **UP-4 — Alloy scope adequacy.** Properties verified within a finite scope are
  not proved for all sizes. → DF-013.
- **UP-5 — Legal correctness of the meta-norm ordering.** That *lex superior > lex
  specialis > lex posterior* is the right default for the Greek order is a
  normative-legal claim, not a formal one. The architecture makes it inspectable
  and attackable, which is the strongest available treatment. → DF-016 (**OPEN**).
- **UP-6 — Completeness of the assumption vocabulary (R-07).** Argued as closed by
  construction over the eight kinds; a new class would be a charter amendment.
  → DF-018 (**OPEN**).
- **UP-7 — Common-mode failure across the two kernels (I-41).** `K_v` and `V_w` are
  independently implemented but from a *shared written specification*, on a shared
  substrate, checked by a shared prover, over the shared frozen decoder library
  that I-42 permits as the single deliberate intersection. A defect in any of those
  defeats both, they agree, and no fault fires. Materially smaller than, and
  different in kind from, the condition it replaced — a specification risk, not a
  circularity — but not eliminated. **This is the deepest OPEN technical residual
  in the design.** → DF-043 (**OPEN**).
- **UP-8 — Faithfulness of the kernel load-time closure computation.** I-42 is
  decided on the package graph; that the graph captures every reachable dependency
  rests on kernel admissibility rather than on the graph itself. → DF-049.
- **UP-9 — Fidelity of text extraction from scanned Gazette material.** Bounded by
  evidentiary status, not eliminated.
- **UP-10 — Source behaviour.** No proof constrains what a Greek portal will do.
