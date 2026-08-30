# WATCHTOWER TARGET v0.7-R — REDUCED CONSTITUTION
**Status: PROOF-REFINED ADVERSARIAL REDUCTION EXPERIMENT.**
NOT a freeze candidate · NOT migration material · NOT production. The repository is untouched.
The VLT spine `A → S → L → B → N → C + E/P/G + D + AI-outside-truth` is **unchanged**: nothing
in fourteen breaks touched it. What changes is the architecture of the constitution itself.

## Why a kernel instead of more invariants
44 free-standing invariants generate 946 pairs that share an object, a time axis or an
authority. Two adversarial passes examined roughly 20 pairs and found 14 breaks — every one of
them in a **composition**, none in the spine. Adding a correct rule adds *n* new pairs, so the
patch method produces the problem faster than it solves it. The kernel exists to make the three
root classes structurally impossible rather than individually guarded.

---

## STRATUM A — MINIMAL SEMANTIC KERNEL

### Primitives (9 — one more than sealed; see the convergence report)
`TypedObject` · `AuthorityOperation` · `LinearizationDomain` · `EvaluationFrontier` ·
`ClosureClaim` · `ArtifactValidityEnvelope` · `RootCommit` · `CanonicalEncoding` ·
**`OperationEffect`** *(added — required to close B-8)*

### L1 — UNIFIED LINEARIZATION AND FRONTIER
**One order semantics, not one global log.** No global sequence across unrelated matters: that
would buy a scalability, availability, privacy and trust-centralisation problem for nothing.

- **L1.a** Operations that can change one another's validity **share a LinearizationDomain**.
  For a capability C, `GRANT · USE · REVOKE · EXPIRE · COMPROMISE` are one domain. A writer may
  not decide "was it authorised" from a local view of another domain.
- **L1.b** A `LinearizationPosition` carries **exactly one** authority-bearing operation. If the
  order of two operations matters, they occupy two positions. *(Discovered executably: with a
  shared position the order is undefined and no property about them is provable.)*
- **L1.c** Cross-domain references are **causal-backward only**; an `EvaluationFrontier` is a
  causally closed set of domain heads.
- **L1.d** Civil time never becomes canonical order. A civil-time query yields a frontier only
  through a **FrontierSelectionProof**, else `UNKNOWN{TEMPORAL_AMBIGUITY}`.
- **L1.e** No local view produces authority.
- **L1.f** *(added)* Trusted time bounds attached to an order must be **propagated to their
  tightest order-consistent form**; contradictory bounds are an inconsistency, not a selection.
  *(The exhaustive check failed without this: raw per-item bounds are unsound because the order
  already asserts monotone true times.)*
- **L1.g** *(added)* **Refusal is constrained.** `UNKNOWN` is permitted only when no unique sound
  answer exists. Without this clause every other L1 property is satisfied by a kernel that
  always refuses to answer.

**Authorisation profiles — the cost is a declared parameter, never an accident:**
`GRANT-BEFORE-REVOKE` (a use linearised before the revoke stays authorised) ·
`ONE-SHOT WINDOW` (one-shot authorisation with a bounded commit window, so a revoke also stops
already-granted work, at an explicit coordination/availability cost).

### L2 — FIRST-CLASS CLOSURE EVIDENCE
The system represents what exists superbly and what does **not** exist not at all. Every
absence becomes a typed object.
- **L2.a** No absence claim without `UniverseDefinition` **and** `ClosureBasis`. Provable:
  "no further admitted amendment exists in R_LEGAL at frontier F". Not provable from a Merkle
  tree: "no amendment exists anywhere in the legal world".
- **L2.b** Conservation: `CapturedInScope = Admitted + Pending + Quarantined +
  GovernedTerminalDisposition`. No fifth bucket — nothing forgotten, dropped or sampled away.
- **L2.c** A terminal disposition is a **durable, auditable record**. Anything that removes an
  item from completeness risk is authority-bearing as to completeness, even when it carries no
  legal authority.
- **L2.d** A completeness label exists only inside the declared `ProofSupportedQuerySubset`,
  addressed through a canonical `VerifiableQueryIR`. Otherwise: a correct proof of a wrong
  reading of the question.
- **L2.e** *(added)* Corroboration requires **evidenced independence per axis** (juridical,
  origin, administrative, transport, hosting, archive-time). Two URLs with one upstream are one
  source. Corroboration is never legal authority.
- **L2.f** *(added)* Attribution never exceeds `MaximumSupportedAttributionLevel`
  (`KEY < WORKLOAD < SERVICE < PRINCIPAL`). A compromised key proves the key signed, not that a
  person acted. *(Derivable as an instance of L2.a — an absence claim about stronger attribution
  — but counted separately so the kernel-growth number is not flattered.)*

### L3 — IMMUTABLE ARTIFACT, COMPUTED APPLICABILITY
Historical artifacts must survive, or forensic reproducibility dies. What must not survive is
**implicit current applicability**.
- **L3.a** An issued artifact is immutable forever; its current applicability is
  `ArtifactStatus(artifact, frontier)` — computed, never a stored flag.
  Statuses: `CURRENTLY_APPLICABLE · VALID_AT_ISSUANCE · SUPERSEDED · STALE · REVOKED ·
  CONTENT_ERASED · DEPENDENCY_INVALIDATED · EXPIRED`.
- **L3.b** A durable proof binds a **commitment** to private content, never the opening. After a
  governed erasure the certificate still verifies structurally and still proves that it was
  issued — and reveals nothing. *(No claim is made that an external recipient who already holds
  a plaintext can be made to forget it.)*
- **L3.c** A change to a `SemanticInfluenceArtifact` (projector, rulepack, Normative IR,
  classifier, policy table) is effective only with **AffectedScopeImpactClosure**: full replay of
  the affected scope or a machine-checkable locality argument. A golden corpus is a canary, not
  a completeness proof.

### OperationEffect and composition obligations *(the B-8 mechanism)*
A **declared** footprint cannot be a trust root: an author who forgets one authority input
causes the analysis to see no overlap and generate no test. Therefore an `OperationEffect` is
**derived** from independent sources (formal transition relation, schema graph, static
extraction, capability graph, runtime traces) and cross-checked against the declaration.
Mismatch **REJECTS**. Unknown access is **TOP** — conservative overlap with everything — never
bottom. Overlapping footprints **generate a composition obligation**.

---

## STRATUM B — DERIVED THEOREM MAP
These are **not** axioms. Each is a proof obligation discharged from Stratum A, with executed
evidence in `KNOWN-BREAK-REPLAY.txt`:
revoked authority cannot write (L1.a+e) · stale control authorisation impossible (L1.a) ·
wrong civil-time frontier rejected (L1.d+f+g) · quarantine suppression visible (L2.b+c) ·
silent answer omission detectable (L2.a+d) · corroboration limits explicit (L2.e) ·
over-attribution impossible (L2.f) · erasure-compatible answer proofs (L3.a+b) ·
semantic-artifact impact visible (L3.c) · composition footprints not self-declared (OperationEffect).

## STRATUM C — ORTHOGONAL BOUNDARY ASSURANCE CONTRACTS
**Explicitly NOT mathematical consequences of L1/L2/L3.** They remain first-class contracts with
their own evidence and their own assumptions: cryptography · key management · runtime
integrity · identity assurance · TCB · supply chain · trusted updates · trusted code safety ·
noninterference envelope · AI boundary · source authority policy · physical/hardware
assumptions. Pretending these follow from the semantic kernel would be a new laundering.
