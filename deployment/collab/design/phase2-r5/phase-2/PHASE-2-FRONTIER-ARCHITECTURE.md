# PHASE-2 FRONTIER ARCHITECTURE
## The Legal Watchtower as a Chartered Deterministic Adjudicative Institution (CDAI)

Phase: 2 — BLIND FRONTIER ARCHITECTURE
Date: 2026-08-26
Status: **Blind frontier candidate for subsequent adversarial judging. Not the
final architecture of the six-phase study.**

Depends on: PHASE-2-CREATOR-AXIOMS.md, PHASE-2-REQUIREMENTS-AND-INVARIANTS.md,
PHASE-2-CANDIDATE-ARCHITECTURES.md, PHASE-2-DECISION-MATRIX.jsonl.
Companion detail: PHASE-2-AUTHORITY-AND-STATE-MODEL.md,
PHASE-2-LISP-NATIVE-DESIGN.md, PHASE-2-FAILURE-AND-RECOVERY-MODEL.md.

---

## 0. THE ONE-SENTENCE ARCHITECTURE

The Legal Watchtower is a chartered institution whose offices hold exclusive typed
powers to append warranted entries of eight distinct kinds to a single
append-only, Merkle-committed, hybrid-logical-clock-stamped record; whose entire
legal, epistemic and self-referential state is a pure, versioned, deterministically
replayable function of that record; whose beliefs are argumentation-adjudicated
over assumption-labelled evidence in dockets that require a contradiction attempt
and carry executable reopening predicates; whose observation is planned as a
derived consequence of its own falsifiable self-model; and which is
architecturally incapable of asserting a legal proposition on the authority of any
adapter, model, or store.

The rest of this document says exactly what each clause means, what state it owns,
what transitions it permits, what transitions are void, what invariant it
preserves under which faults, and what would falsify it.

---

## 1. THE SPINE: EIGHT KINDS, ONE ORDER, ONE DERIVATION

### 1.1 The eight kinds

Everything the institution knows is one of exactly eight kinds. This is not a
taxonomy for documentation; it is the type discipline that makes G1 checkable.

```
OBSERVATION   channel C returned response R at logical time τ
ACQUISITION   artifact with digest D entered durable custody
EVIDENCE      artifact D has evidentiary status S for claim class K
AUTHORITY     instrument I holds authority A in legal order O over interval T
INTERPRETATION provision P bears meaning M under reading R
INFERENCE     proposition Q follows from premises Π under rules Σ
DECISION      docket Δ resolved as Z for reasons W, reopening predicate Ξ
PUBLICATION   answer A emitted to audience X at τ
```

Eight. Not eight plus a special case.

*(Second-round audit finding HF-021.)* The first version added a ninth entry type,
`PROPOSAL`, described as a "non-kind" and said to be excluded from the support
relation. That was a contradiction dressed as a distinction: an entry in the record
that the kernel can read is a kind, whatever it is called, and "excluded from the
support relation" is a rule that a rule change could undo.

Machine-learned and heuristic output now lives in the **proposal spool** `P`, which
is not the record, not the artifact store, and **not an argument of the kernel**
(I-45). The kernel's signature does not mention it. A proposal therefore cannot be
a premise not because a rule forbids it but because the derivation cannot see it.

An office that acts on a proposal must derive the content itself from evidence and
issue a real entry; the entry may carry the proposal's **digest** as a provenance
annotation, so the audit trail survives without giving proposals record status.
`P` is freely deletable, and deleting it must change `state` by nothing at all.

### 1.2 One order

There is exactly one logical record `R = ⟨e₀, e₁, …⟩`. Every entry carries:

```
entry := { seq          : ℕ                     -- position, gapless
         , prev-commit  : digest                -- hash chain
         , hlc          : ⟨physical, counter⟩   -- causality, bounded skew
         , kind         : one of the eight
         , office       : office-identity        -- who acted
         , warrant      : warrant                -- why they were entitled to
         , payload      : kind-specific
         , cites        : list of seq            -- explicit dependency
         , kernel-ver   : digest or ⊥            -- ⊥ for observation entries
         }
```

`seq` is gapless and totally ordered; `hlc` preserves causality while remaining
within bounded divergence of physical time [RL-018], so that legal deadlines
expressed in wall-clock time ("ten days after publication") remain evaluable while
causal ordering never depends on clock correctness.

The record is committed as a Merkle tree; log heads are periodically co-signed by
independent witnesses and anchored with a qualified electronic time stamp, which
under Regulation (EU) 910/2014 enjoys a presumption of the accuracy of the date
and time and of the integrity of the bound data [RL-028]. Consistency proofs
demonstrate that a later head is a superset of an earlier one [RL-011].

### 1.3 One derivation — and one independent verification

```
State_v = K_v(R, A|_R)
```

*(Restated by second-round audit finding HF-020.)* The first version asserted claim
**WC-8**, eliding the artifact store. The kernel must read bytes to derive anything
about a text, and the elision sat in the central axiom of the architecture. `A|_R` is the artifact store restricted to digests named
in `R`. It is a function of `R` alone because `A` is content-addressed and
write-once, because `A` is **R-bounded** (I-43: nothing in `A` is unnamed by `R`,
so `A` cannot carry hidden state), and because `K_v` is **total under
unresolvability** (I-44: a named digest that does not resolve yields
`UNSUPPORTED-BY-UNRESOLVED-ARTIFACT` and a global `DERIVATION-INCOMPLETE(D)` marker
naming the exact unresolved set — never a skip or a substitution).

`K_v` is pure, total and deterministic (A3, I-29). It is written in the applicative
subset of ANSI Common Lisp that ACL2 admits, so there is no extraction step and no
re-implementation step — with the three residual seams named in
PHASE-2-LISP-NATIVE-DESIGN.md §1.0 (guard verification, ACL2 surface syntax, host
conformance; DF-011, DF-048). The translation seam is removed; the
logic-to-execution seam is narrowed, not closed [RL-014]. Claims WC-1 and WC-2 are
withdrawn. Every proposition it produces carries `v` (I-30).

**And there is a second kernel.** `V_w` — independently authored, independently
ACL2-admitted, sharing no code with `K_v` (I-42) — computes the admission predicate,
the publication-critical invariant verdicts, and every self-model falsifier outcome,
reading `R` and `A|_R` directly and never reading `K_v`'s output. The Inspectorate
uses `V_w` and only `V_w`. Disagreement between the two is fault F15 and suspends
publication. See §15.5 and PHASE-2-AUTHORITY-AND-STATE-MODEL.md Part J.

`State_v` contains, as one homogeneous body of adjudicated propositions:

- the reconstructed legal state (what the law is/was),
- the epistemic state (what is believed, on what support, with what defeaters),
- **the self-model** (coverage, lag, uncertainty, intentions, procedural
  validity),
- the derived quarantine status,
- the derived plan.

That the self-model is in the *same* store, produced by the *same* function, and
defeasible by the *same* mechanics is the architectural content of "metacognition
is semantics, not presentation" (C4).

### 1.4 What is authoritative and what is not

| Thing | Status | Its check |
|---|---|---|
| The record `R` | **Authority** (institutional acts) | it *is* the input; integrity by hash chain, Merkle consistency, witnesses, time anchor |
| The artifact store `A` | **Authority** (byte custody) | **not rebuildable** — the bytes came from the world — but **digest-verifiable** and **R-bounded** (I-43) |
| The proposal spool `P` | **Scratch** | deleting it must change `state` by nothing at all |
| Everything else — legal state, beliefs, indices, self-model, plan, caches, the running image | **Derived** | the deletability test A8/I-31 |

The three exemptions from rebuild-and-compare have three different justifications,
and none of them is convenience. `R` is the input. `A` cannot be recomputed, only
re-observed — and re-observation may lawfully return different bytes (L5) — so its
accountability comes from verifiability plus boundedness instead. `P` is not an
authority *or* derived; it is scratch, and its check is the mirror image.

The deletability test is a **scheduled experiment**, not an assertion: a sandbox
region periodically deletes a derived store and rebuilds it from `K_v(R, A|_R)`. If
the rebuild differs, the store was holding information not in the record — i.e. it
was a second authority — and the configuration is unconstitutional, which suspends
the publication power.

This single test is the strongest available operational answer to "no duplicate
truth" (C7). It is what the phrase *single authority* means here.

---

## 2. INSTITUTIONAL IDENTITY AND CONSTITUTIONAL AXIOMS

### 2.1 Identity

The Watchtower's identity is a set of entrenched constitutional propositions in
`State_v`, derived from the Charter, and therefore inspectable, queryable and
subject to the same defeat mechanics as everything else — except that entrenched
axioms cannot be defeated by internal act (A10, I-34).

```
IDENTITY:
  mandate       : continuous observation and defeasible reconstruction of the
                  Greek legal order and of legally relevant European and
                  international authority
  jurisdiction  : evidence about law; NOT law itself (A1)
  competence    : may assert what the evidence shows; may never assert what the
                  law is on its own authority
  temporal-scope: continuous, with durable memory across restarts and versions
  organs        : the offices of §3
```

### 2.2 The constitutional axioms (Charter)

The Charter is a compile-time artifact (D23) that expands into: office
definitions, power tables, warrant types, entrenchment declarations, and
compile-time proof-obligation stubs. Declaring two offices with the same power over
one fact class is a **compile error**, not a runtime discovery.

Entrenched (unamendable by internal act):

- **CA-1 Jurisdictional limit.** No organ of the Watchtower confers legal
  authority. (A1)
- **CA-2 Monotone record.** The record is append-only; retraction is an append.
  (A2)
- **CA-3 Derivation purity.** All state is `K_v(R, A|_R)`, with `A` R-bounded and
  the kernel total under unresolvability. (A3, I-29, I-43, I-44)
- **CA-4 Metacognitive adequacy.** Every self-model proposition declares a truth
  condition, a falsifier and a consequence. (A6)
- **CA-5 Non-authority by deletability.** Every store but the two authorities is
  deletable and rebuildable. (A8)
- **CA-6 Machine-learned containment.** Models propose and render; they never
  assert. (A9)
- **CA-7 Inspection is negative.** The Inspectorate may suspend; it may never
  create a positive legal proposition.

Amendable (by the Amendment Council under the procedure of §18.3, and **by no
other office**): office composition; source registry policy; **the
organ-to-instrument-type-to-authority mapping**; the preference ordering of legal
meta-norms; the strict/defeasible classification of rules; observation policy;
publication policy; evidentiary lattice extensions; reopening-predicate language
extensions; the high-consequence class definition that triggers Rapporteur review;
the regression-corpus composition policy.

*Revision arising from hostile-audit finding HF-007.* The organ-to-authority
mapping and the rule classification were previously described only as "inspectable,
attackable data" without naming who may change them. Unassigned mutability is
hidden authority: if the Tribunal could amend the mapping it applies, it would hold
legislative power over its own competence. Assigning every one of these to the
Amendment Council — which cannot itself adjudicate — closes that.

**Genesis.** The Charter's own enactment is not an office act, because offices
exist only by virtue of the Charter. Genesis is an explicitly external, named,
signed and time-anchored first entry `e₀`, after which the founding principal holds
no continuing power. Full specification: PHASE-2-AUTHORITY-AND-STATE-MODEL.md
§A.2.1.

### 2.3 Why entrenchment, precisely

Without it, the amendment power is a hidden universal authority: any invariant is
removable by first amending the rule that protects it, so the Amendment Council
silently holds every power in the institution — a direct violation of C7. With
entrenchment, the amendment power is bounded and the bound is checkable (PO-034:
no reachable state lacks an entrenched axiom).

**Honest limit.** Entrenchment binds *acts*, not *operators*. An operator with
filesystem write access defeats it. The architecture converts that from prevention
into detection: witness co-signature plus qualified time anchoring make silent
rewriting detectable by a third party (§1.2, D11). This limit is stated, not
concealed (DF-007).

---

## 3. OFFICES, JURISDICTION, SEPARATION OF POWERS, DELIBERATION

### 3.1 The offices and their exclusive powers

Powers are **exclusive per fact class**: for each fact class, exactly one office
may issue. An act by an unempowered office is **void** — it has no institutional
effect and the only state change is the record of its voidness (D02). This is
institutionalised power in the Jones–Sergot sense: designated agents are empowered
to create normative states of affairs by performing specified act types, and the
counts-as relation classifies a brute act as an institutional act in context
[RL-010].

| Office | Exclusive power over | May NOT |
|---|---|---|
| **Registry** (Μητρώο) | source registration; assignment and confirmation of norm identity; binding of external identifiers (ELI/ECLI) as defeasible assertions | determine authority, evidence, or meaning |
| **Observatory** (Παρατηρητήριο) | conduct observation; emit `OBSERVATION`; run vitality probes | assign identity, custody, evidence, or authority |
| **Archive** (Αρχειοφυλακείο) | admit bytes into durable custody; emit `ACQUISITION`; attest custody continuity | modify or delete an artifact; determine evidence |
| **Authentication** (Επικυρωτήριο) | determine evidentiary status; verify source signatures and time anchors; emit `EVIDENCE` | determine legal effect or meaning |
| **Tribunal** (Κριτήριο) | admit `AUTHORITY`, `INTERPRETATION`, non-trivial `INFERENCE`; issue `DECISION`; classify cessations; resolve conflicts | observe, acquire, authenticate, or publish |
| **Doctrine Office** (Θεωρητήριο) | record doctrinal positions; supply interpretive arguments to the Tribunal marked `DOCTRINAL` | ground any authority proposition (I-20) |
| **Inspectorate** (Ελεγκτήριο) | execute falsifiers **in `V_w`**; audit invariants; admit `PROCEDURE-INVALID`; **suspend** the publication power | create any positive legal proposition (CA-7); use `K_v` for any verdict (SA-14) |
| **Chronicler** (Χρονικό) | maintain decision history projections; evaluate reopening predicates; require reopening | decide anything |
| **Coverage Ephorate** (Εφορεία Κάλυψης) | derive the observation plan from self-model propositions; declare coverage obligations | decide truth; observe directly |
| **Publications** (Εκδοτήριο) | emit `PUBLICATION` | publish anything not admitted, or while suspended |
| **Rapporteur** (Εισηγητήριο) | **human office**: mandatory review of declared high-consequence proposition classes; standing power to reopen any docket | be bypassed for its declared classes |
| **Amendment Council** | amend non-entrenched Charter provisions under §18.3 | touch entrenched axioms (I-34) |

### 3.2 The separation invariants

These are the checkable content of "separation of powers":

- **SP-1** ∀ fact class F: `|{o : holds-power(o, issue, F)}| = 1`.
- **SP-2** No office holds both `determine-evidence` and `determine-legal-effect`.
- **SP-3** No office holds both `publish` and `adjudicate`.
- **SP-4** The Inspectorate's power set contains no `issue` power for a positive
  proposition kind.
- **SP-5** The Registry's power set excludes `AUTHORITY` issuance (I-09).
- **SP-6** Every power is reachable from the Charter by exactly one delegation
  path (no authority cycles, no orphan powers).

All six are discharged by PO-001/PO-003/PO-009 in Alloy 6, where power exclusivity
and reachability are natural relational properties [RL-015].

### 3.3 Why this is a separation of powers and not an agent council

An agent council aggregates opinions; authority is emergent and therefore
unlocatable. Here, authority is **exclusive, typed, checked at admission, and
voiding**. Two offices cannot both be right about the same fact class because only
one of them can act on it at all. The Doctrine Office is the sharpest illustration:
it exists precisely to be *powerless* over authority, which is how "doctrine is not
binding authority" (L8) becomes structural rather than editorial.

### 3.4 Deliberation

Deliberation happens in **dockets** (§16), not in message-passing among agents.
A docket is a first-class object with a lifecycle, an evidence set, argument
trees, a mandatory contradiction record, an admission determination, and a
reopening predicate.

---

## 4. SOURCE REGISTRY AND SOURCE-AUTHORITY SEMANTICS

### 4.1 What a source is

A **source** is not a URL. It is a registered model of a publication process:

```
source := { id
          , organ             : the legal organ whose acts it publishes
          , instrument-types  : which instrument kinds appear here
          , order             : which legal order (Hellenic, EU, ECHR, …)
          , constitutive?     : does publication here constitute legal effect?
          , channels          : list of observation channels (transport-level)
          , enumeration-model : how the source numbers its own emissions
          , cadence-model     : calibrated distribution of inter-emission time
          , signature-model   : what signatures/attestations it applies
          , vitality-probe    : a content-independent liveness test
          , correction-model  : how this source publishes corrections
          }
```

Registered instances include: the Government Gazette via the National Printing
House (constitutive for statutes under Const. Art. 42 §1 [RL-021], series-and-issue
enumeration, digital signature by an authorised officer under Law 3469/2006
[RL-024], formal correction procedure under Art. 16 §§4–5 [RL-026]); Diavgeia
(administrative transparency under Law 3861/2010, ΑΔΑ enumeration, **not**
constitutive [RL-051]); Areios Pagos decision search (no reliable enumeration
signal [RL-052]); EUR-Lex/Cellar (ELI/CDM, SPARQL access [RL-006]).

### 4.2 The critical distinction: channel vs source vs authority

```
channel   — a transport-level way of reaching bytes (HTTP endpoint, API, mirror)
source    — a modelled publication process of a legal organ
authority — a relation between an instrument and a legal order over an interval
```

**Invariant I-02**: the justification of an authority assertion mentions no
channel. The type of the authority derivation function does not accept a channel
argument, so this is enforced by construction, not by review.

Consequence: acquiring the *same bytes* from a mirror, a commercial database, and
the National Printing House produces three different evidentiary states and the
*same* authority conclusion only if the Authentication office can verify the
gazette signature on at least one of them. The channel is irrelevant to authority
and decisive for evidence — which is exactly backwards from how a pipeline treats
it.

### 4.3 What a source adapter may do

An adapter is shell code. Its entire institutional capability is:

```
emit OBSERVATION: "channel C, request Q, response bytes B, headers H,
                   at HLC τ, by observer principal π"

-- and nothing else. A candidate interpretation ("these bytes may be gazette
-- issue A′ 133/2019") is written to the proposal spool P, which is not the
-- record and is not an argument of the kernel (I-45). It is not an entry.
```

It may not emit `ACQUISITION`, `EVIDENCE`, `AUTHORITY`, or anything else (I-03).
Its warrant grants exactly one entry type, so an attempt is void at admission —
and void at the *append point*, by a predicate that reconstructs the power from the
Charter rather than trusting the warrant the adapter presents (I-46).
This is C3 made structural — and, per A1, generalised so that moving the same
behaviour into a "normalizer" or "loader" does not evade it.

### 4.4 What a held copy is

A held artifact is **evidence about the source, never a substitute authority for
it**. This sentence is the residue of the rejected Chartered Custodial Federation
synthesis (Candidates §8): that challenge established that not holding a copy is
fatal (replay, correction history, anti-entropy all require it), and in doing so
made explicit what holding one is *for*.

---

## 5. OBSERVATION AND ACQUISITION

### 5.1 Observation

Observation is effectful shell work performed by stateless workers. Every effect —
DNS, TCP, TLS, HTTP, clock read, randomness, filesystem, model call — is obtained
from an injected **environment object**, never from ambient globals (D14). In
production the environment is real; in replay it is the recorded trace; in
simulation it is synthetic and seeded. The scheduler is the same object in all
three [RL-017, RL-057].

An observation produces exactly one `OBSERVATION` entry containing the full
response (status, headers, body digest, TLS chain, timing) and the body bytes
placed in a staging area. Nothing is interpreted.

### 5.2 Acquisition

The Archive decides whether staged bytes enter durable custody. Acquisition:

1. computes the digest,
2. checks whether the digest is already held (deduplication is by content, so
   re-observation of unchanged material is cheap and *informative*: it is the
   anti-entropy signal of §12),
3. if the bytes arrive inside a signed container, **retains the container
   unmodified** (I-06) — the signed PDF is preserved, not just the extracted text,
4. emits `ACQUISITION` binding digest → custody, with a custody-start attestation.

**Why container retention is non-negotiable.** Under L4 the electronic Gazette
issue bears a digital signature from an authorised officer of the National
Printing House [RL-024]. That signature is the strongest evidentiary primitive the
Watchtower will ever hold about Greek legislation. A pipeline that extracts text
and discards the container destroys it in step two and can never recover it. The
architecture forbids this structurally: an `ACQUISITION` entry for a signed
container whose container digest is absent is inadmissible.

*Scope of the claim (revision arising from hostile-audit finding HF-015).* No
survey evidence was gathered in this phase about how widespread container
discarding is in practice, so no frequency claim is made. What is established is
narrower and sufficient: (i) L4 makes the signature legally significant [RL-024];
(ii) the reconstruction of candidate A1 exhibits the discard at its normalisation
step; (iii) once discarded it is unrecoverable, so the defect is irreversible
rather than merely undesirable. That is the whole basis for the requirement.

### 5.3 Transformation

Transformations (decompression, text extraction, OCR, segmentation, structural
parsing to Akoma Ntoso [RL-001]) are a **closed algebra**. Each transformation
constructor declares:

```
transform := { id, inputs, kernel-ver, process-deterministic?, rank-effect }
```

`rank-effect` is constrained: `rank(T(x)) ⊑ rank(x)` always (A4, I-04, PO-004).
There is no constructor with a rank-raising effect. Strength can rise only via a
new `ACQUISITION` plus an Authentication act (I-05).

For non-deterministic processes (OCR, model-based segmentation) the architecture
does not pretend to reproducibility: the process is executed once and its
**output is recorded as an artifact**, so the *result* is reproducible even though
the *process* is not. The derivation record carries `process-deterministic: false`
so that this is visible in every explanation that depends on it.

---

## 6. EVIDENCE, PROVENANCE, ATTESTATION, LINEAGE

### 6.1 The evidentiary lattice

```
                    AUTHENTIC-SIGNED-ANCHORED
                              │
                       AUTHENTIC-SIGNED
                              │
                      AUTHENTIC-UNSIGNED
                              │
                          SECONDARY          DOCTRINAL (incomparable)
                              │                   │
                          UNVERIFIED ─────────────┘
                              │
                          REPUDIATED  (absorbing ⊥)

DISPUTED := meet of two incomparable non-⊥ statuses
```

- `AUTHENTIC-SIGNED` — a signature by a registered signing authority of the source
  verified against its registered key material (L4).
- `AUTHENTIC-SIGNED-ANCHORED` — additionally bound to an independent time anchor:
  a qualified electronic time stamp, which under Regulation (EU) 910/2014 carries
  a presumption of accuracy of date and time and of integrity of the bound data
  [RL-028], or inclusion in a witnessed append-only log [RL-011].
- `DOCTRINAL` is **incomparable**, not weak. Doctrine is a different kind of thing,
  and placing it in the authentic chain would let a large quantity of commentary
  substitute for a small quantity of authority.

### 6.2 Lineage

Every derived artifact carries exactly one derivation record naming inputs,
transformation identity and kernel version (I-07). Lineage is a typed internal
graph; it is **exported** to W3C PROV [RL-007, RL-059] and to in-toto/DSSE
attestations [RL-047, RL-048], but the export is not the authority. The reason the
internal model is native rather than PROV-shaped: PROV's derivation relation is
untyped with respect to fidelity — it can say *y was derived from x* but not that
the derivation *weakened evidentiary strength* — so the monotone-degradation
theorem is not expressible in it (D06).

### 6.3 Attestation

The attestation classes are distinguished because they have different evidential
force:

1. **Source attestations** — signatures the source applied (Gazette officer
   signature, submitting body's advanced electronic signature). Strongest;
   independent of the Watchtower.
2. **Third-party attestations** — witness co-signatures on record heads, qualified
   electronic time stamps, independent custody attestations. Independent of the
   Watchtower, weaker as to content but decisive as to time and integrity.
3. **Self-attestations** — the Watchtower's own signatures over its derivations.
   Useful for detecting internal inconsistency; **worthless as independent
   evidence about itself**, and typed so that no argument can treat them
   otherwise.

---

## 7. TEMPORAL LEGAL VALIDITY AND PUBLICATION TIME

### 7.1 Nine axes, per provision, all adjudicated

Legal time in the Greek order cannot be represented by two axes. The architecture
carries nine (R-04), each an adjudicated defeasible proposition rather than a
stored scalar (A5):

```
t_enact        vote/adoption
t_promulgate   promulgation by the President          (Const. Art. 42 §1)
t_publish      publication in the Gazette              (Const. Art. 42 §1)
t_force        entry into force OF THIS PROVISION      (ΕισΝΑΚ Art. 103 default
                                                        +10 days, or express)
t_apply_from   applicability to facts (may precede t_force: retroactivity)
t_apply_to     end of applicability
t_end          cessation
t_observe      when the Watchtower saw the evidencing artifact
t_record       when the entry was appended (HLC)
t_believe      when the proposition was admitted
```

Two structural consequences:

- **Per-provision granularity.** Greek statutes routinely commence
  article-by-article. A document-level "effective date" is not an approximation of
  this; it is a different and wrong claim.
- **Defaults are named defeasible rules, never values.** The ten-day rule
  [RL-023] is applied as `RULE-EISNAK-103`, recorded in the justification, and
  attackable. A stored date cannot be attacked; a rule application can.

### 7.2 Intervals with explicit unknown endpoints

Endpoints are `⟨kind, value⟩` where kind ∈ {`CLOSED`, `OPEN`, `UNKNOWN`,
`CONDITIONAL`}. `CONDITIONAL` carries the condition (e.g. "on publication of the
ministerial decision provided for in §4"), which is extremely common and which a
date column cannot express. This admits the answer *"in force from a date not yet
determinable, conditional on X, which has not been observed"* — precisely the
honest answer, which R-10 requires and which a scalar model must fake.

### 7.3 The cessation trichotomy

| Kind | Effect | Treatment |
|---|---|---|
| **Abrogation** (κατάργηση) | *ex nunc* | `t_end` closes; past applications stand; prior answers remain correct as of their time |
| **Annulment** (ακύρωση/ανίσχυρο) | *ex tunc*, within the declared scope | the norm is treated as never having had the claimed effect within scope; **all prior answers within scope are reopened** |
| **Correction** (διόρθωση σφάλματος) | text replaced; norm treated as always having been the corrected text within the correction's scope | superseded text **retained** as evidence of what was published; prior answers grounded in it are linked to the correction (I-13) |

The abrogation/annulment distinction and its two-timeline treatment are established
in temporalised defeasible logic for legal change [RL-013]. The correction limb is
grounded in Greek positive law: correction of Gazette errors is a formal
procedure under Law 3469/2006 Art. 16 §§4–5, operated by the National Printing
House and producing a further published instrument [RL-026].

**Undetermined cessation kind is a first-class state.** `CESSATION-KIND-UNDETERMINED`
suppresses every point-in-time answer whose interval spans the cessation (I-12).
The system refuses rather than guesses.

### 7.4 The consolidation classes

`OFFICIAL-CODIFICATION` (under Law 4622/2019 Arts. 65–66 and its organs [RL-027]),
`OFFICIAL-CONSOLIDATED-REPUBLICATION`, and `WATCHTOWER-RECONSTRUCTION` are distinct
classes that never merge (I-14). A reconstruction is never returned in answer to a
request for an official codified text, and the class appears in every emitted
citation. This is the difference between a research aid and a misrepresentation.

---

## 8. LEGAL PROPOSITIONS, INTERPRETATION, CONFLICT, DEFEATERS

### 8.1 Arguments, not records

A legal proposition is held only as the conclusion of one or more **arguments**:
trees of strict and defeasible rule applications over premises, where each leaf is
either `EVIDENCE`-backed or a declared assumption (R-06, R-07). Attack takes the
three ASPIC+ forms — on premises, undercutting a defeasible inference, and
rebutting a defeasible conclusion — with preferences resolving defeat, under the
rationality postulates of closure and consistency [RL-008, RL-056].

**Strict rules** are constitutional/definitional and not attackable as inferences:
e.g. *published in the Gazette ⇒ formally in existence as a statute* (L1).
**Defeasible rules** are everything interpretive: commencement defaults, *lex
specialis*, scope readings, classification of an instrument type.

### 8.2 Conflict resolution

Conflicts are resolved by a **declared preference relation over rules**, encoding
the classical legal meta-norms — *lex superior*, then *lex specialis*, then *lex
posterior* — as themselves-defeasible, inspectable, attackable meta-rules (I-19).
Where the ordering is silent, the outcome is `UNDECIDED`, which is publishable as a
structured refusal (I-36). There is no arbitrary tie-break and no recency default.

**Honest statement of what this is.** That this ordering is the correct default for
the Greek legal order is a *normative-legal* claim, not a formal one. The
architecture's contribution is not to settle it but to make it (a) explicit,
(b) inspectable, (c) attackable in a docket, and (d) versioned, so that changing it
is a recorded institutional act with a regression obligation. See DF-016.

### 8.3 Defeaters as first-class objects

A defeater is an entry, not a condition. Classes:

```
EVIDENTIARY   the supporting artifact's status fell (repudiated signature,
              detected substitution)
IDENTITY      the norm identity binding was defeated
TEMPORAL      a commencement/cessation proposition was defeated
INTERPRETIVE  a competing reading was preferred
NORMATIVE     a superior/special/later norm defeats the conclusion
PROCEDURAL    the admitting docket was defective (I-25 violated)
SELF-MODEL    a coverage or procedural-validity claim underpinning the answer
              was falsified
```

The `SELF-MODEL` class is what makes metacognition load-bearing on legal output:
an answer can be defeated because the institution discovered it was blind, not
because the law changed.

---

## 9. EPISTEMIC STATE, UNCERTAINTY, BLIND SPOTS, CONFIDENCE

### 9.1 The two-layer belief mechanism

- **Substrate: assumption-based labels.** Each belief carries a label — a set of
  minimal environments (assumption sets) under which it holds — with minimal
  inconsistent environments recorded as no-goods [RL-009, RL-062]. Defeating an
  assumption invalidates every belief all of whose environments contain it, in one
  derivation step, without touching unrelated beliefs (I-16).
- **Adjudication: structured argumentation.** Which of two conflicting conclusions
  prevails, and *why*, is decided by ASPIC+-style defeat under the declared
  preferences [RL-008].

Neither subsumes the other: labels answer *"under what assumptions, and what
breaks if this fails"*; arguments answer *"which reading wins, and for what
reason"*. The first is what makes blind-spot reasoning possible; the second is what
makes explanation possible.

### 9.2 The closed assumption vocabulary

```
A-AUTHENTICITY     this artifact is what it purports to be
A-COMPLETENESS     we hold everything the source published in window W
A-IDENTITY         this text is that norm
A-READING          this provision bears this reading
A-TEMPORAL-DEFAULT the ΕισΝΑΚ default applies here
A-SOURCE-FIDELITY  the source reproduced the instrument faithfully
A-TRANSLATION      this translation preserves normative content
```

Closed by construction over the eight kinds; adding a class is a Charter amendment.
Every instance names its class, its subject, and its **falsifier** — so
"uncertainty" is never a mood, it is an enumerated set of things that could be
wrong and a stated way to check each one.

### 9.3 Confidence is a status, never a number

Emitted qualification is drawn from a small ordered vocabulary tied to *structure*,
not to a score:

```
ESTABLISHED       strict-rule derivation from AUTHENTIC-SIGNED(-ANCHORED) evidence
SUPPORTED         defeasible derivation, no surviving defeater, complete labels
CONTESTED         surviving defeater recorded, preference resolves
UNDECIDED         conflict unresolved by the declared ordering
LABEL-INCOMPLETE  bound exhausted; may not support publication (I-18)
UNSUPPORTED       all environments defeated
```

Under I-35 an answer's strength is the **meet** of its supporting leaves; it can
never exceed any leaf. A numeric score was rejected precisely because a number
invites arithmetic and arithmetic on evidence is laundering (D07).

### 9.4 Bounded computation, declared incompleteness

Label computation is worst-case exponential [RL-009]. The architecture does not
hide this. When the bound `B_label` is exhausted, the belief is marked
`LABEL-INCOMPLETE`, a condition is signalled, the belief may not support a
publication, and the docket is queued for bounded re-adjudication (I-18). The
frequency of bound exhaustion is itself a self-model proposition subject to A6.

This is the concrete refusal of "silent degradation" (C7).

---

## 10. SCHEDULING, LIVENESS, RETRIES, RECOVERY, DETERMINISTIC REPLAY

### 10.1 The scheduler

A single deterministic logical scheduler drives all regions. All nondeterminism is
injected through the environment object. The production scheduler *is* the
simulation scheduler [RL-017, RL-057] — not a test double, because a test-only
simulator verifies a different program.

Consequences:

- **Replay** of any past interval is exact: re-run `K_v` over the record prefix
  with the recorded environment trace.
- **Fault injection** is first-class: partitions, clock jumps, truncated
  responses, mutated sources, and rate limits are environment behaviours.
- **Liveness** properties are stated in TLA+ and checked with Apalache/TLC
  [RL-016]; safety of record append under crash is PO-028.

### 10.2 Retries

A retry is not a control-flow construct; it is a *policy chosen by a handler*
through the condition system (D24). The Observatory signals
`observation-failed`; the Coverage Ephorate's handler selects among named restarts
(`retry-with-backoff`, `switch-channel`, `defer-to-window`,
`declare-source-unreachable`). Restart selection is a warranted, recorded act, so
the institution can later explain *why* it waited rather than switched.

### 10.3 Recovery

Recovery is recomputation, in the ARIES sense adapted to an append-only record
[RL-031]: locate the last valid checkpoint, verify the Merkle consistency proof
from checkpoint head to current head, then redo by re-deriving `K_v` over the
suffix. There is no undo pass, because there is nothing to undo: the record never
contained uncommitted state.

Checkpoints may include an SBCL core image for fast start [RL-046], but an image
is a **cache** (A12): core images are explicitly not compatible across runtimes,
so an image can never be an archival format. Full detail in
PHASE-2-FAILURE-AND-RECOVERY-MODEL.md.

---

## 11. GAP AND DELAYED-PUBLICATION DETECTION

This is where the architecture attempts something most systems do not: knowing
about things it has **never seen**.

### 11.1 Three structural detectors

1. **Enumeration closure.** Exploit the source's own numbering. The Government
   Gazette numbers issues sequentially within series and year; Diavgeia assigns
   ΑΔΑ. A missing number in an otherwise continuous sequence is positive evidence
   of an unseen emission — the system knows *that* it is missing something and
   *which* thing, without ever having seen it.
2. **Reference closure.** Every citation in an acquired instrument to an
   instrument not held creates an **acquisition obligation**. Citation closure is
   a coverage metric that grows as the corpus grows and that surfaces material the
   enumeration cannot (e.g. an older instrument amended by a new one).
3. **Cadence anomaly.** Each source carries a calibrated model of its
   inter-emission time distribution. Silence longer than the model's tail is
   evidence — but of *what* is ambiguous, which is the point of §11.2.

### 11.2 The decisive move: separating silence from blindness

A source that has produced nothing might have published nothing, or the Watchtower
might have gone blind. These are different facts with different consequences, and
nothing in the observation itself distinguishes them.

*Scope of the claim (revision arising from hostile-audit finding HF-016).* No
survey was conducted of how other systems handle this, so no claim is made about
prevalence. What is established is structural: an architecture whose only signal is
"no new items were retrieved" has no term in which to express the difference, and
must therefore either report completeness it cannot justify or report a failure it
has not observed. Candidates A1, A2 and A5 each have this property by construction;
that is the evidence relied on, and it is about those reconstructions, not about
the field.

The architecture resolves this with a **content-independent vitality probe**: an
observation, on a different code path from content acquisition, that verifies
(a) the source responds, and (b) a *known, previously acquired* item is still
retrievable with the expected digest. The probe must not share the content
channel's failure modes, otherwise it tests the thing whose failure it is meant to
detect.

Resulting coverage states (I-24):

```
COVERED                 enumeration closed, references discharged, cadence normal
GAP-CONFIRMED           source published; we lack it — a specific missing item
SOURCE-SILENT           vitality confirmed; nothing published
INDETERMINATE-COVERAGE  cannot distinguish — completeness claims SUPPRESSED
```

`INDETERMINATE-COVERAGE` is not a failure state; it is an honest state, and its
existence is what lets the institution answer *"I do not know whether I am
complete, and here is why"*.

### 11.3 Declared limit

Some sources expose no structural signal at all. Greek court publication practice
is a real instance: the Supreme Court's decision search offers no enumeration
invariant comparable to Gazette issue numbering [RL-052]. For such sources,
coverage is **permanently** `INDETERMINATE` and completeness claims are suppressed
forever. This is a limit of the world, not of the design, and the architecture's
contribution is to make it visible rather than to paper over it (A7 falsifier;
DF-023).

---

## 12. BACKFILL AND ANTI-ENTROPY RECONCILIATION

### 12.1 Backfill is an append

Historical material enters as `OBSERVATION` entries with an earlier `t_observe`
and a later `t_record`. Because the nine-axis model separates these, **no log
rewriting is ever needed** — ordering by legal time is a query concern, not a
storage concern. The kernel re-derives; the difference in derived state is
observable and, where it changes an admitted decision, produces a `DIVERGENCE` for
adjudication.

Backfill is therefore *sound by construction*: it cannot corrupt, because it
cannot mutate.

### 12.2 Anti-entropy against silent source mutation

Retained artifact digests are compared against re-observation on a schedule.
Sampling is **stratified by legal salience and citation recency**, with *full*
verification of every artifact currently supporting a published answer (D16).

A digest change on an identity the source presents as unchanged raises
`SOURCE-MUTATION`, which is quarantined and adjudicated into one of:

```
LAWFUL-CORRECTION      matched to a published correction instrument
                       (Law 3469/2006 Art. 16 §§4–5) → correction semantics §7.3
UNANNOUNCED-REVISION   content changed with no correction instrument
                       → both versions retained; prior answers flagged
SUBSTITUTION           the source served a different instrument
                       → evidentiary status of the channel degraded
TRANSIENT-ERROR        re-observation resolves to the original digest
```

This is a capability a federation cannot have: detecting a silent substitution
requires a retained copy to compare against. It is one of the three reasons the
Chartered Custodial Federation synthesis was rejected (Candidates §8).

---

## 13. ANOMALY QUARANTINE AND CORRECTION

Quarantine is a **derived status**, not a separate store (D17 iteration 3) — this
preserves G2 and the deletability test while keeping the non-support property
structural: the support relation's domain is *computed* to exclude quarantined
entries, so a query that "forgets to filter" cannot exist.

Quarantine state machine:

```
DETECTED ──► QUARANTINED ──► UNDER-ADJUDICATION ──► RELEASED (with reopening pred.)
                  │                    │
                  │                    └──► REPUDIATED (absorbing)
                  └──► SUPERSEDED (a later observation resolves it)
```

Invalid transitions (void): `DETECTED → RELEASED` (no adjudication);
`REPUDIATED → *` (absorbing); any transition without an Authentication act plus a
Tribunal decision; automatic correction of content (which would manufacture
evidence, violating A4/I-05).

Nothing in quarantine can support a publication, at any strength.

---

## 14. REFLECTIVE MEMORY AND DECISION HISTORY

### 14.1 Decisions carry their own falsifiers

Every `DECISION` names an **executable reopening predicate** Ξ over record
prefixes, drawn from a closed, total, decidable predicate language (I-26). The
Chronicler evaluates all live predicates as part of the fold; when one becomes
true, the docket reopens automatically.

Examples:

```
Ξ₁: an EVIDENCE entry lowers the status of any artifact in this decision's
    support below AUTHENTIC-UNSIGNED
Ξ₂: an AUTHORITY entry admits an instrument that cites this provision with a
    modification relation
Ξ₃: coverage for source S over window W transitions to GAP-CONFIRMED where W
    intersects this decision's evidence window
Ξ₄: the preference ordering used in this decision is amended
Ξ₅: the kernel version is promoted and this decision is in the regression corpus
```

This converts institutional memory from an archive into a **control mechanism**.
It is the single most important difference between "the system remembers its
decisions" and "the system's decisions remain answerable".

### 14.2 What the memory contains

Not just outcomes: the question, the evidence set as of decision time, every
argument constructed (including the losing ones), the contradiction attempt and
its result, the preference applications, the admission determination, the reasons,
the kernel version, and Ξ. A decision whose losing arguments were discarded cannot
be re-examined honestly, so they are retained.

---

## 15. SELF-MODEL VALIDATION AND METACOGNITIVE CONTROL

### 15.1 The A6 triple

A self-model proposition is admissible only if it declares:

1. a **truth condition** expressible over the record,
2. an **executable falsifier**,
3. at least one **institutional consequence** that follows causally from it.

A self-model proposition with no consequence is inadmissible — it is decoration
(I-21). This is the mechanical anti-decoration test the acceptance contract
demands: enumerate the self-model propositions and check the triple.

Worked example:

```
proposition:  COVERAGE(Gazette series A′, 2026-08, ratio 0.997, GAP-CONFIRMED:{212})
truth cond.:  enumeration closure over observed issues in the window
falsifier:    vitality probe returns issue 212 successfully on re-observation
consequence:  Coverage Ephorate raises the acquisition obligation for issue 212
              to priority 0; Publications attaches an incompleteness qualifier to
              any answer whose evidence window intersects 2026-08 series A′
```

### 15.2 Causation is structural

The observation plan is a **derived object**: `plan = Π(self-model propositions,
Charter)` computed inside the kernel (I-22). The shell only *executes* the plan.
No scheduling decision exists that is not a consequence of self-model propositions
plus the Charter. This is the difference between a self-model that is *read* and
one that is *causal*.

Contrast with the metareasoning tradition: a meta-level that monitors traces of
cognitive activity [RL-034] can detect *"I am stuck"* but not *"Gazette series A′
issue 212 of 2026 is missing"*. The extension here — self-model propositions
grounded in *evidence about the world*, with falsifiers executed by an adversarial
office — is what makes the meta-level institutional rather than merely cognitive.

### 15.3 The suspension power

The Inspectorate executes falsifiers on a schedule and may admit
`PROCEDURE-INVALID(x)` for any invariant classified publication-critical. That
admission **suspends the publication power institution-wide** until a warranted
restoration act (I-23). It is not a warning; it is not a dashboard colour; it stops
the institution from speaking.

The Inspectorate holds **no** power to create positive legal propositions (CA-7),
so it cannot be captured into becoming a second Tribunal — which would destroy
G2 by creating a competing authority.

### 15.4 Procedural self-validation

"Whether its own reasoning and institutional procedures remain valid" (C5) is
implemented as continuous runtime checking of the structural invariants that Alloy
established over the Charter model (SP-1…SP-6, I-34), plus the deletability
experiment (I-31), plus sampled admission re-execution (I-27). Each produces a
`PROCEDURE-VALID` / `PROCEDURE-INVALID` proposition with the full A6 triple.

### 15.5 The self-reference defect, and its remedy

**The defect.** In the first version of this architecture, self-model propositions
were produced by the same kernel that produced world propositions. A kernel defect
would corrupt both together, so the institution could be confidently wrong about
being right — and its own audit would confirm the error. The first version
disclosed this and bounded it. **The creator ruled that disclosure is not a
remedy**, and that ruling is correct: an audit performed with the audited party's
own machinery is not an audit, and calling the circularity "inherent" made a design
choice look like a law of nature.

**The remedy: two kernels.**

```
                    R, A|_R
                   ┌───┴────┐
                   ▼        ▼
              ┌────────┐ ┌────────┐
              │  K_v   │ │  V_w   │
              │ derive │ │ verify │
              └───┬────┘ └───┬────┘
                  │          │
             full state   admission decisions (I-46)
            (all offices) publication-critical verdicts
                          self-model falsifier outcomes
                             │
                             ▼
                       Inspectorate
                    (may suspend; may never create)
```

- `V_w` is **independently authored** from the same written specification, by a
  different author, using a different algorithmic approach, and **independently
  ACL2-admitted**.
- `V_w` shares **no code** with `K_v` (I-42), enforced by a build-time
  import-closure audit — with exactly one deliberate, frozen, separately verified
  exception: the record and artifact **decoders**, because two kernels that
  disagree about what an entry's bytes *mean* are not verifying the same thing.
- `V_w` reads `R` and `A|_R` **directly** and never reads `K_v`'s output. Coverage
  falsifiers in particular are recomputed from the **raw observation entries,
  including vitality-probe results**, not from `K_v`'s coverage propositions.
- The Inspectorate uses `V_w` and only `V_w` (SA-14). A verdict traceable to `K_v`
  is itself a procedural-invalidity condition.
- Disagreement is **fault F15**: it admits `PROCEDURE-INVALID` and suspends the
  publication power. The institution keeps observing, acquiring, authenticating and
  adjudicating while suspended. It simply cannot **speak**. Agreement is not
  required to run; it is required to assert.
- There is no majority rule, because with two implementations there is no majority.
  F15 is resolved by an act: the Rapporteur and the Amendment Council determine
  which kernel is wrong, and the correction carries the regression obligation.

**Scope, stated rather than assumed.** `V_w` covers the publication-critical subset
— admission, the invariants that gate speech, and the falsifiers — not the whole
state. An independent re-implementation of the entire kernel would double the
specification surface without doubling the assurance, and would generate constant
divergence on questions that do not bear on whether the institution may speak.

**What is closed.** A defect in `K_v` alone can no longer corrupt both the world
model and the audit of the world model. It produces disagreement, which is detected,
which stops publication.

**What remains, and it is a different thing.** Both kernels implement the same
written specification, run on the same SBCL, are checked by the same ACL2, and share
the frozen decoders. A defect in the **specification**, the substrate, the prover or
the decoders defeats both. That is a *common-mode* residual, carried as **DF-043**.
It is materially smaller than the defect it replaces and it is different in kind —
a specification risk, not a circularity — and it is not claimed to be closed.

---

## 16. INTERNAL ADVERSARIAL REASONING AND INSTITUTIONAL APPROVAL

### 16.1 The docket

```
docket := { id, question, opened-by, opened-at
          , evidence-set          : entries as of opening
          , positions             : maximal-consistent readings from ATMS
                                    environments
          , arguments             : per position, constructed argument trees
          , contradiction-record  : MANDATORY
          , preference-applications
          , admission-determination
          , reasons
          , reopening-predicate   : MANDATORY
          }
```

### 16.2 Mandatory contradiction

A docket admitting a defeasible conclusion must contain **either** at least one
constructed counter-argument, **or** a record `CONTRADICTION-NOT-CONSTRUCTIBLE`
with its reason and a *syntactic witness* that the derivation used no defeasible
rule (I-25). The witness is checkable because "uses no defeasible rule" is a
decidable property of the argument tree.

This is what makes adversarial deliberation **structural**: its absence is an
admissibility defect that voids the admission, not a process someone might skip.

A machine-learned critic may *propose* objections, but a proposal is not a
defeater: it must be reified as an argument with premises bound to the epistemic
store before it counts (A9, D19).

### 16.3 Admission conditions

All must hold:

1. every premise meets the strength threshold declared for the claim class;
2. the preference ordering resolves all conflicts (else `UNDECIDED`);
3. no supporting environment is a superset of a no-good (I-17);
4. labels are complete (else `LABEL-INCOMPLETE`, which cannot be admitted for
   publication);
5. the contradiction record is present (I-25);
6. a reopening predicate is present (I-26);
7. for declared high-consequence classes, Rapporteur review is recorded.

### 16.4 The human office

The Rapporteur exists because the strongest justifiable architecture does not
pretend a machine can hold final interpretive authority. Under A1 the Watchtower's
jurisdiction is *evidence about law*, never *law*; the Rapporteur is where that
boundary is operationalised: mandatory review for declared high-consequence
proposition classes, and standing power to reopen any docket at any time. This
answers hostile-audit finding HF-004.

---

## 17. QUERY, EXPLANATION, CITATION AND PUBLICATION BOUNDARIES

### 17.1 What an answer is

An answer is a **warranted extract of admitted propositions**, carrying:

```
proposition | all nine temporal axes with endpoint kinds | evidentiary basis with
statuses | argument structure | defeaters considered and disposition | coverage
status of every source relied on | consolidation class (I-14) | kernel version |
explicit statement of what is not known
```

### 17.2 Publication gates

Publication is void unless: nothing in the support is quarantined; no support is
`LABEL-INCOMPLETE`; strength equals the meet of supporting leaves (I-35); no
completeness claim spans an `INDETERMINATE-COVERAGE` window (I-24); the publication
power is not suspended (I-23).

### 17.3 Refusal is a first-class output

When support is insufficient the system emits a **structured refusal** naming the
missing evidence and the acquisition action that would resolve it (I-36). A refusal
that says *"Gazette series A′ issue 212 of 2026 is missing; acquiring it would
resolve this"* is strictly more useful than a hedged assertion — and it is the only
honest output.

### 17.4 Where language models are allowed

Exactly two places (A9):

- **Proposal generation** — candidate parses, candidate identity matches,
  candidate anomalies, candidate objections. Output goes to the **proposal spool**
  `P`, which is not the record and is **not an argument of the kernel** (I-45), so
  a proposal cannot be a premise because the derivation cannot see it. An office
  acting on a proposal must derive the content itself from evidence and issue a
  real entry, which may cite the proposal's *digest* as provenance but never its
  content.
- **Surface rendering** — prose rendering of already-admitted propositions,
  verified by a deterministic **round-trip check**: the rendered text's claim slots
  are parsed back to proposition identifiers and compared as a set. A rendering
  that changes the entailment set is rejected (I-37).

The evidential basis for this containment is direct: a preregistered evaluation of
leading commercial retrieval-augmented legal research tools found incorrect or
misgrounded output on 17–33% of 202 hand-scored queries, against vendor claims of
hallucination-freedom [RL-030]. Retrieval grounding alone does not license
propositional authority. The architecture therefore uses models where their error
mode is *recoverable* (a bad proposal is discarded) and excludes them where it is
not (a bad assertion is believed).

**Honest residual.** The round-trip check verifies the claim-slot set, not
rhetorical implicature; a rendering can be faithful and still misleading in
emphasis. Bounded by restricting high-consequence classes to templated renderings
(DF-031).

---

## 18. EVOLUTION WITHOUT DUPLICATE AUTHORITY OR SEMANTIC REGRESSION

### 18.1 Versioned interpretation

`state = K_v(R, A|_R)`. Changing `v` does **not** rewrite history; it produces a
second interpretation of the same record. The difference between interpretations is
a first-class `DIVERGENCE` object that must itself be adjudicated.

This resolves the event-sourcing tradition's known open wound (Candidates §2.4):
changing the fold silently rewrites the past. Here the past is the record, which
never changes; only readings of it change, and readings are versioned and
comparable.

### 18.2 The regression obligation

A kernel version `v′` may be promoted only if, for the designated regression corpus
`C` of previously admitted decisions, every decision either reproduces under `v′`
or carries an **admitted `DIVERGENCE`** explaining and justifying the change.
Unexplained divergence blocks promotion (I-32). The corpus is curated
(high-consequence decisions) **plus** randomly sampled, because sampling alone
under-weights the rare decisions a regression must not break (D25).

**Honest limit.** The obligation is only as strong as the corpus: a change correct
on `C` and wrong off `C` is not caught. Bounded, not eliminated (DF-019).

### 18.3 Charter amendment

Non-entrenched provisions are amended by the Amendment Council under: a proposal
docket with mandatory contradiction; discharge of the structural proof obligations
(Alloy re-check of SP-1…SP-6); dual-office countersignature (the one place where
exclusivity is deliberately not claimed, per D01 iteration 2); and a regression
obligation over decisions that relied on the amended provision. Entrenched axioms
cannot be amended; an entry purporting to do so is void and triggers Inspectorate
review (I-34).

### 18.4 Class evolution

Persistent class redefinition is refused by the metaclass unless a **migration
warrant** is present naming old and new layout hashes and a total migration
function; instance update proceeds through the standard CLOS redefinition protocol
and is recorded (I-33). Free redefinition was rejected because it changes the
meaning of already-admitted conclusions with no record that the meaning changed
(D25).

---

## 19. FORMAL INVARIANTS AND EXECUTABLE PROOF OBLIGATIONS

Full statement: PHASE-2-REQUIREMENTS-AND-INVARIANTS.md; counts are derived into
the seal rather than restated here. Assignment of obligations to tools:

- **ACL2** — kernel functional properties, because ACL2's logic is a subset of
  ANSI Common Lisp, so there is no extraction step and no re-implementation step
  [RL-014]. *(R4, HF-025: this bullet previously asserted claim WC-2. Withdrawn —
  the translation seam is removed, the logic-to-execution seam is narrowed to
  UP-1 and UP-2, not closed.)* Includes monotone evidentiary degradation (PO-004),
  label soundness (PO-015…017), plan-is-a-function-of-the-self-model (PO-022),
  docket admissibility (PO-025), kernel totality under unresolved artifacts
  (PO-044) and call-path-independent admission (PO-046).
- **Alloy 6** — Charter structure and finite-scope lifecycle, because power
  exclusivity and reachability are relational and Alloy 6 adds linear temporal
  operators [RL-015]. Scope adequacy is UP-4.
- **TLA+ / Apalache** — protocol safety and liveness under crash and partition
  [RL-016].
- **Deterministic simulation** — whole-system properties not reducible to a kernel
  theorem, including declared-incompleteness behaviour (PO-018),
  silence/blindness separability (PO-024) and the deletability experiment
  (PO-031) [RL-017, RL-057].

---

## 20. COMMON LISP REALISATION

Full statement: PHASE-2-LISP-NATIVE-DESIGN.md. The summary claim, stated so it can
be attacked:

Common Lisp is load-bearing here for **six** specific reasons, and explicitly *not*
for the concurrency topology (§13 of the Lisp document lists what is **not**
claimed):

1. **ACL2**: the kernel is verified and executed without an extraction or
   re-implementation step, so the *translation* gap is eliminated and the
   logic-to-execution gap is narrowed to three named seams (guard verification,
   ACL2 surface syntax, host conformance) rather than closed — DF-011 and DF-048.
   No other mainstream language narrows it this far [RL-014]. See Lisp design §1.0
   for what is and is not claimed.
2. **Custom method combination**: warrant checking becomes a property of the
   generic function, computed during effective-method construction, rather than a
   line someone might omit [RL-042]. *(Second-round audit finding HF-022: this is
   now **defence in depth**, not the guarantee. A method combination polices
   generic-function calls only, so an in-office ordinary call bypassed it. The
   guarantee moved to the append point, where admission is a pure, call-path
   independent, ACL2-proved function of (Charter, entry) evaluated in `V_w` —
   I-46, PO-046. The method combination is retained because failing fast at the
   call site with a good diagnostic is worth having, not because the invariant
   depends on it.)*
3. **Multi-method dispatch**: the counts-as relation is genuinely three-argument
   (act × context × institution); single-dispatch languages must hand-roll a
   registry, which C11 forbids.
4. **Conditions and restarts**: detection is separated from remedy without
   unwinding the context in which the remedy must be applied [RL-041]; the restart
   set is the institution's remedy catalogue.
5. **MOP**: persistence, access control and warranted class evolution are
   *intercepted* by a metaclass rather than left to discipline [RL-040, RL-045] —
   defence in depth, not the guarantee (Lisp design §5.1).
6. **Packages + locks + ASDF**: hygiene for office boundaries, and — load-bearing —
   the package-graph property that makes kernel disjointness I-42 mechanically
   checkable [RL-038, RL-043]. Package locks do **not** enforce authority: an
   unexported symbol is reachable with two colons and any code may unlock a
   package. Authority is enforced at the append point (I-46).

---

## 21. EXACT LIMITS AND UNRESOLVED OBLIGATIONS

Stated here rather than buried, because the acceptance contract treats
claim-inflation as a defect.

### 21.1 What is proved and what is not

The properties that are **not proved** are enumerated canonically in
PHASE-2-REQUIREMENTS-AND-INVARIANTS.md Part X and are neither re-listed nor
re-counted here. The deepest of them is common-mode failure across the two kernels
— shared specification, substrate, prover and decoders — carried as **DF-043**.

### 21.2 Capabilities the architecture does not have

- It cannot detect gaps in sources with no structural signal; coverage there is
  permanently `INDETERMINATE` (§11.3).
- It cannot compute preferred/stable argumentation semantics without bound;
  bounded search with `SEMANTICS-INCOMPLETE` is the honest substitute (D08).
- It cannot prevent operator tampering; it can make it detectable (§2.3).
- It cannot detect a defect present in **both** kernels — a specification error, a
  substrate error, a prover error, or a decoder error (§15.5, DF-043).
- It cannot resolve a `K_v`/`V_w` disagreement by itself: with two implementations
  there is no majority, so F15 requires a human act and publication stays suspended
  until it is taken (§15.5).
- It cannot guarantee absence of semantic regression outside the regression corpus
  (§18.2).
- It cannot hold final interpretive authority, by constitutional design (A1).
- It offers no guarantee about rhetorical implicature in rendered prose (§17.4).

### 21.3 Known cost

Adjudicated temporal facts, assumption labelling and derived-only state are
materially more expensive than bitemporal table lookup. Accepted because C8
excludes cost from the objective vector and because the difference is not an
order-of-magnitude threat at the declared corpus scale — which is itself a
falsifiable operating assumption (OA-4, DF-021). If OA-4 is falsified, D10 and D05
must be re-opened; the architecture states this rather than assuming its way past
it.

### 21.4 Status of this document

A blind frontier candidate produced without access to the existing implementation
or any prior study artifact, offered for adversarial judging. Its claim is:

> **Non-dominated among the evaluated frontier candidates under the declared
> constraints and evidence.**

Not optimal. Not final. Falsifiable at every point enumerated in
PHASE-2-DEFEATER-REGISTER.jsonl; the register is the canonical source and the
tallies by status are derived into PHASE-2-SEAL.json.

The **open** defeaters are the honest attack surface, and Phase-3 adversarial
judging should start there: DF-007 (operator tampering defeats entrenchment),
DF-011 (ACL2↔SBCL correspondence unproved), DF-016 (the meta-norm ordering is a
contested legal claim), DF-018 (assumption vocabulary completeness is argued, not
proved), DF-021 (the corpus-scale operating assumption is unmeasured), DF-023
(jurisprudence coverage is structurally indeterminate), DF-033 (the whole
institutional apparatus may be disproportionate to the mandate), DF-042 (genesis
locates but cannot legitimate the founding authority, and entrenchment makes a
founding error irreversible), and **DF-043 — the deepest OPEN technical residual:
common-mode failure across the two kernels**.

DF-026 is **BOUNDED**, not open: condition WC-7 was remedied structurally by the
two-kernel design (I-41, I-42). No part of this architecture audits itself with the
kernel it audits.
