# CHANGE-PROPOSAL v1.8 — FINAL PRE-FREEZE INTEGRATION (CANDIDATE · NOT FROZEN)

**ΚΑΤΑΣΤΑΣΗ: `SPEC v1.8 CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`.**
Parent `04cca6ed`. successor of `CHANGE-PROPOSAL-v1.7.md` on the SAME CPEI Public Observatory Profile v1.4;
frozen v1.4 baseline `88129099` (tree `a2617649`) unchanged. This is the one final pre-freeze integration before
independent verification and a new SPEC FREEZE. Design/spec only — no production code, no refactor, no
Work-Packet, no Implementation-Book change, no second Book, no second architecture/store/IR/engine/memory, no
freeze, no qualification. It references the canonical seats; it does not copy them.

## 0. Αποστολή
LAWMAX OMEGA is built as the privately-governed **Machine Legal Trust Root, citation root and default
verification layer** for humans, machines, AI providers and (future) institutional users. State and judicial
bodies remain the issuers of primary acts; LAWMAX becomes the superior computational, proof-carrying, codifying
and referencing authority through **measurable superiority, not self-declaration** (`:V8I-01`).

## 1. Τα 10 v1.7 defects διορθωμένα (DFT-01..10) — audits που ΑΝΟΙΓΟΥΝ πραγματικά αρχεία
- **DFT-01** `V8-PUBPRIV` crosses every declared edge family (field-type, ref-target, interface-io,
  subsystem-dep, store-owner-writer, api-mcp-schema, publication, declassification), reading schema/ISR/SUB, with
  an **independent mutation witness per family** (`V8-PUBPRIV-FAMW` = families). No universal-closure claim for an
  unchecked family.
- **DFT-02** `V8-WP` **opens the real `WP-00..WP-14.md`** and confirms each declared evidence string; unowned →
  `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED`.
- **DFT-03** `V8-XREF` **opens the declared canonical file** and confirms the type/symbol locator + identity +
  version exist; nonexistent file/locator fails.
- **DFT-04** `V8-OWN` universal store uniqueness (one id, one owner, ≤1 writer, read-only 0), agreeing with
  registries; a duplicate store with a different owner fails.
- **DFT-05** `V8-CAP` **opens the real code/document seat**: `:CODE` ⇒ real `source/*.lisp` + real `defpackage` +
  real symbol; `:DOCUMENT` ⇒ real `.md`/`.sexp` + section, **no pseudo-package**. Prior Markdown pseudo-packages
  (`ra.license`, `usc.expression`) are corrected to `:DOCUMENT` seats.
- **DFT-06** `ClarifiedInterpretation/1` has **conditional cardinality**: `ABSTAIN`⇒null (no hidden winner),
  `EXPLICIT_SELECTION`⇒exactly one selected, `EXPLICIT_MERGE`⇒required merged-result ref preserving ALL input
  provenance (`V8I-CLARIFY-cardinality`).
- **DFT-07** a real clarification lifecycle (`ClarificationRequest/1`, `ClarificationResponse/1`, suspend/resume/
  expiry/cancel/repeat, terminal `UNDERDETERMINED`/`CONFLICTING`/`ABSTAINED`/error) and a **typed cognition
  graph** (`cognition-graph-v8`) with real branch/resume/terminal edges — NOT a linear list with a `:branch`
  annotation. `V8-COGLIFE` accepts branch/resume/terminal and rejects an injected cycle, an orphan terminal and a
  dangling resume (3 witnesses).
- **DFT-08** `V8-SYM` proves mandatory-stage reachability, node-type compatibility, empty proposer-mandatory set,
  and **semantic equivalence of the mandatory path after removing all proposers**, with **exactly 4** real
  mutation tests (the prior 5/3/2 ambiguity retired).
- **DFT-09** `V8-REQ`/`V8-REQM` uses a **real negative mutation** (blanking a test cell makes the traceability
  check fail) — the tautological `V7S-RANSM` is replaced.
- **DFT-10** Root Authority is an **orthogonal product state** with a **deterministic derived projection** — no
  scalar stored truth (`RootAuthorityStatus/1` + `RelianceProjection/1`).

## 2. `RootAuthorityStatus/1` — orthogonal dimensions
`security`, **`proof_integrity` (mandatory, SEPARATE from security — authenticity/provenance/tlog/witness/MLTP
failures map here)**, `freshness`, `rights`, `coverage`, `availability_ops`, `juris_access`, `qualification`,
`cause_refs[]`, measurement time, policy epoch, signature. `RelianceProjection/1` is derived, total,
deterministic, preserves all simultaneous causes, separates mandatory/advisory, never converts one dimension's
recovery into another's, has journaled per-dimension recovery, and forbids self-qualification. The Acceptance
Matrix carries `dimension | mandatory/advisory | failure value | recovery evidence | authority`.

## 3. Τα 7 RA deltas (μία canonical έδρα έκαστο)
- **RA-EPOCH** `CanonicalCitationURI/1` is an **address over USC W→E→M→I**, not a second identity; every citation
  fixes jurisdiction/source-type/work/subdivision/expression-version-or-fully-determined-temporal-slice/temporal-
  semantics+tz+calendar and resolves to **exactly one Expression** (a bare as-of date is insufficient when >1
  change/day). A URI without version/temporal segment is a current-view query, never a canonical citation.
  `MultiCommitment/1` carries ≥2 distinct hash families with domain separation from first publication;
  `ReAnchoringManifest/1` requires pre-existing pre-transition commitments/timestamps/witnesses/archival bytes (a
  root signature alone is insufficient); the same versioned URI never resolves to a different Expression.
  Jurisdiction is a dimension (GR-first, EU/federation later) with no grammar change.
- **RA-CONT** separates institutional / approval / key-share-custody / technical-signing authority; custodians
  gain none of the first two. Versioned `ContinuityPolicy/1` (configurable council/threshold, separation of
  duties, no single succession authority, incapacity/death evidence, time-locked succession, witnesses,
  collusion/capture controls, recovery drills, policy epoch) — no arbitrary `3/2-of-3/30-day` constants. One
  person may invoke only a temporary time-limited `EmergencyFreeze` (PUBLISH_FREEZE); extension/thaw needs quorum
  (no permanent single-custodian DoS). Real people/numbers/instruments are external governance gates.
- **RA-CORR** `PublicCorrectionEvent/1` (no re-published content, no PII in tombstone, points to replacement/
  withdrawal, citation-resolvable) + `RestrictedForensicRecord/1` (own access/retention/legal-hold/deletion).
  Crypto-shredding/salted commitments are `PENDING_LEGAL_VALIDATION`, not automatic compliance; digests may
  themselves be sensitive; the chain verifies with `content unavailable/withdrawn` without retaining withdrawn
  content in the public journal.
- **RA-K** tiered reproducibility (T1 public / T2 delayed-public retired / T3 sealed restricted) with a typed
  `MetricAssuranceClass` (`PUBLICLY_REPRODUCIBLE` only when data can be published+reproduced publicly, else
  `INDEPENDENTLY_AUDITED_RESTRICTED`/`AGGREGATE_ONLY`/`UNQUALIFIED` from independent audit). Hidden holdouts are
  not revealed before retirement; redistribution-forbidden is explicit; metrics are never legal correctness.
- **RA-SIDE** `SidecarSourceProfile/1` is specification-only + creator-gated; lawful basis is per source/
  controller/purpose and `PENDING_LEGAL_VALIDATION`; Article 6(1)(f)/89 are not locked as universal basis; no
  source, not even ΦΕΚ, is "zero GDPR weight".
- **RA-MARK** separates cryptographic status / trademark / certification mark / attribution text / CC BY
  attribution / enterprise contractual; technical validity is independent of any visual logo; trademark/
  certification is an external legal gate; no extra restriction inside the open licence.
- **RA-JUR-NS** jurisdiction/namespace is a typed dimension carried by `CanonicalCitationURI/1` (GR-first,
  EU/federation later) — reuses the resolver namespace discipline (v1.7 RA-I), no new identifier grammar.

## 4. FROST / PQ — μόνο ακριβείς ισχυρισμοί
FROZEN: versioned suite registry, ceremony roles, policy epochs, separation of duties, witness/delay, downgrade
resistance, recovery procedure. NOT frozen (explicit): FROST key-generation/DKG is **outside RFC 9591**;
independent n-of-m ML-DSA signatures are **not** threshold ML-DSA; DKG/share-refresh/HSM maturity is
`PENDING_IMPLEMENTATION_REVIEW`; no homemade cryptography. An emergency transition is **not** an "epoch
demotion" — it creates a new monotonically-increasing `RECOVERY_EPOCH N+1` (reasoned retirement, pre-committed
recovery policy, governance quorum, surviving independent signatures, public delay, tlog/witness). The verifier
never silently reverts to an older epoch nor accepts a silent single-algorithm fallback.

## 5. Audits (τίμια tiered)
`V1.8-CONTRADICTION-OMISSION-AUDIT.sh` declares, per check, what it proves and at which tier — `[DOC]`
document/reference, `[STR]` structural/type, `[XFILE]` opens a real file and greps a symbol/section. It is **NOT**
executable-protocol / legal-content / security-qualification / operational proof, and does **not** use agent
count, grep presence or a passing regression as proof of semantic correctness. Every defect-guard carries a real
negative mutation that fails for the stated reason. It runs v1.7/v1.6/v1.5/v1.4 as regressions and re-checks the
frozen tree + pinned `.out`. **The phrase "SEMANTICALLY CLOSED" is deliberately not used.**

## 6. STATUS & ΕΤΥΜΗΓΟΡΙΑ
`SPEC v1.8 CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`. No freeze/re-freeze, no
Implementation-Book update/regeneration, no second Book, no WP-00, no implementation/qualification, without a new
explicit creator order.
**`V1.8 FINAL PRE-FREEZE INTEGRATION COMPLETE — READY FOR ONE BOUNDED INDEPENDENT VERIFICATION — NOT FROZEN —
NOT QUALIFIED — IMPLEMENTATION BLOCKED`.** Στάση.
