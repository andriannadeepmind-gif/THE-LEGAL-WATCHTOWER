# 06 — TRANSITION PROGRAM: B0 → the Canon system

The build-obligation register (BO-01..BO-41). BO-01..26 are re-derived from the prior
study (full prose detail preserved in
`ARCHIVE/superseded-SSP-deliverables/05-stageCD-tournament-and-E-star-2/E-star-2-MAIN-DOSSIER.md`);
BO-27..33 derive from the native clauses added to the pillars. Every BO is stated with its
INV derivation, B0 anchor, and discharge artifact. Execution is phased P1..P7; **no phase
starts without the creator's explicit «εγκρίνω P<n>»**; every phase ends with the
adversarial review + proof protocol of `07-VERIFICATION.md`.

## Build-obligation register

| BO | Derives from | Obligation (discharge artifact) | B0 anchor |
|---|---|---|---|
| BO-01 | P4 | Executed adversarial campaign: repo-wide hash-committed mutation-operator/counter-design registry, offline-recomputable | release gates |
| BO-02 | P1/INV | Lean discharge of `admission-model.sexp` T1–T9 (authority totality) + **fail-closed rewrite of `constitutional-gate.lisp:44-45`** | constitutional gate |
| BO-03 | P3 | Spec-level proof program: K totality/determinism, seq-monotonicity (T5), RFC-6962 prefix consistency (T3), plan well-formedness, labelling T1–T6, proof-carrying-kernel obligations | `admission-model.sexp` |
| BO-04 | P2 | Lean encoder-soundness proof for the defeasible→SAT reduction (escalation-cell certificate route) | inference layer |
| BO-05 | P2/P4 | Certified exhaustive-extension enumeration (proof-logging SAT/ASP; LRAT checked by cake_lpr-class checker) | new |
| BO-06 | P2 | Independent producer-free Horty forcing-certificate checker + machine-checked extremal-completion stability lemma | case-law cell |
| BO-07 | P4 | Lean-4 plan-admission machinery (proof-term skeletons; sorries = typed obligations, zero at discharge) | new |
| BO-08 | P1 | Written + mechanized single-writer exclusion proof (deadlock/lost-update/unarbitrated-conflict freedom) for the Mode-A tier | `merkle-authority.lisp` |
| BO-09 | P2 | Structural bypass-impossibility (glob fallback deleted; enumerated bypass attempts blocked) + witness-quorum cosigning | ingest path |
| BO-10 | P2 | Total `View(t_legal, t_knowledge)` seat + recorded re-runnable past-time evaluation witness | `version-graph.lisp`, authority replay |
| BO-11 | P5 | All-class replay demonstration (≥1 decision from every trusted decision class) + closure-totality fix (wall-clock out of trusted path) | `journal.lisp` |
| BO-12 | P1 | Divergence-free perturbed-environment replay demo + deterministic intra-tier ordering fix | scheduler |
| BO-13 | P1/P5 | Atomic writer seat generalized to `emit-graph`/`deploy.lisp`; six-item WAL transaction; Lean crash-refinement proof | writers |
| BO-14 | P1 | Liveness proof corpus: variant function + budget obligation per wait point, machine-checked | wait points |
| BO-15 | P1 | Deterministic cost meter + persisted hash-chained cost ledger + fail-closed budget gate + external-time bracketing | new |
| BO-16 | P5 | Lean-verified O(log n) Merkle inclusion/consistency checker, differentially byte-tested vs `merkle-authority.lisp` | `merkle-authority.lisp` |
| BO-17 | P3/P5 | Succinct transition receipts for the admission spine (transparent STARK, dual-mode), typed assumption instances | new |
| BO-18 | P3 | Independent trace-vs-explanation comparison harness (introspection honesty) | new |
| BO-19 | P1 | Preservation-proof corpus per committed spec'd class; floor vector serialized into the census chain | evolvability |
| BO-20 | P2 | Grammar-total FSM citation recognizer from committed grammar (≤120-char clamp deleted); per-citation certificates; RFC-3161 timestamping | citation validator |
| BO-21 | P5 | Per-step hash ledger in `consolidation-proof.lisp` (aggregate→per-step) + census-totality blocking gate | `consolidation-proof.lisp` |
| BO-22 | P2 | Stability-certificate engine; closed UNKNOWN-cause sum type (replacing `meta-ontology.lisp` prose); blocking anomaly queue | `meta-ontology.lisp` |
| BO-23 | P2 | Jurisdiction profile schema + Greece profile extraction + parametricity build gate; second structurally distinct legal order instantiated | new |
| BO-24 | P1/P3 | Kernel-substrate decision artifact: CakeML-class verified kernel vs declared-SBCL divergence budget (decision + proofs) | runtime |
| BO-25 | P5 | Salted per-leaf commitments + typed erasure certificates + signed memory checkpoint bound into release spine | `memory.lisp` |
| BO-26 | P3 | Lean formalization of the coNP-cell impossibility theorem (the CEILING-BAR `proven_impossible` artifact) | new |
| **BO-27** | P4 preclusion | Preclusion engine: controllable-predecessor safety-game fixpoint over P2 irreversibility doctrines; preclusion certificates + mandatory non-self-binding proof | new |
| **BO-28** | P4/P2 construals | Qualification-lattice search: untrusted construal generator; authority-anchored admissibility; canon-priority pruning; **declared-coverage certificate type + kernel refusal of unstamped completeness** | new |
| **BO-29** | P5 loop | Pre-registration ledger: mechanically-applicable reference-class predicates; outcome closure; calibration arithmetic (prevail rate, Brier, n); anti-gerrymandering guard (thin class → UNKNOWN) | `journal.lisp` extension |
| **BO-30** | P3 output | Tribunal-adoption compiler: deterministic certified-conclusion → Greek issuing schema (facts → ELI-cited law → node-wise subsumption → operative part); structural open-texture flags; no LLM post-certification | new |
| **BO-31** | P1 multi-model | Organ socket bay: N frontier-model sockets per generative organ, competing proposals, model identity excluded from trusted path and artifacts | new |
| **BO-32** | Mission preventive | Instrument compiler: contract/act draft → P4 exhaustion over its future-dispute space → rewrite loop until preclusion-certified "born won" | application of BO-27/28 |
| **BO-33** | Method/A4 | **Self-evolution pipeline (SEV) — the autopoietic seat.** The system maintains and regenerates ITSELF. A **standing self-adversary program** runs continuously against the system's own body — its proofs, its organs, its coverage boundaries, its security posture, its performance — system-level self-falsification, strictly distinct from case-level opponent simulation. Its findings, plus red proofs, mutation-adversary hits, calibration drift (BO-29), model deprecations/releases, and novel opponent moves, are the SEV triggers. Untrusted multi-model builders design and implement the candidate upgrade; it runs in an **isolated sandbox** (no production access): full proof CI (zero sorry), all gates, mutation adversary, and **bit-for-bit replay regression over the entire P5 corpus** (every past decision re-derives identically, or the difference is declared as an intended semantic change). Output: an **upgrade certificate** {diff hash, sandbox evidence, BO-19 preservation proofs, replay-regression results, declared semantic deltas}. Admission: valid certificate **+ creator «εγκρίνω»** — self-merge is structurally impossible (single writer + human approval), and PROVABLY the superior form (axis A4: silent self-modification re-admits the silent-drift failure class). The heavy lifting is fully autonomous; the authority is fully the creator's. Formula: **autopoietic in labor, heteronomous in authority** — the system produces, tests, and regenerates its own components (a broken proof re-derives, a deprecated model socket re-fills, stale coverage re-tightens, health invariants self-restore within proven bounds); the seal is always the creator's, because self-sealed change re-admits the silent-drift class (A4). | CLAUDE.md protocol, formalized + sandbox infra (new) |
| **BO-34** | §5 threat model | Adversarial-input hardening + confidentiality architecture: no-egress organ sandboxes (typed proposal channel only); standing injection test-suite in CI (hostile filings ⇒ decided output unchanged); the **inference-boundary gateway** as the single egress to model vendors with per-data-class posture (on-prem / redact-then-external / never-external — creator decision artifact); HSM-class key custody + rotation for writer & witness quorum; encrypted-at-rest private partitions | new |
| **BO-35** | P2 (first order) | **EU/ECHR layer of the Verified World**: EU regulations/directives, CJEU and ECtHR case law admitted as mandatory sources OF THE GREEK ORDER, with supremacy/direct-effect/consistent-interpretation meta-rules encoded as P2 objects (distinct from BO-23's second order) | L2 pipeline |
| **BO-36** | P5/P4 | **Cross-matter consistency guard**: firm-wide position registry over P5; deterministic contradiction scan (same predicate asserted/denied across live matters; same tribunal/judge exposure); blocking flag at strategy/drafting time | P5 index |
| **BO-37** | §6 modes | Operating-mode ladder as typed states (FULL/DEGRADED/MANUAL) named in every certificate + continuity: offsite replication of the authoritative chain via witness cosigning (RPO 0), documented RTO, repeatable disaster-recovery drill as proof artifact | `merkle-authority.lisp`, quorum |
| **BO-38** | INV honesty | **Incident protocol**: on discovery of a defective certified output — deterministic full scan of affected matters via P5 replay, recall/notification records, root cause enters SEV as a mandatory trigger, incident log append-only | P5 |
| **BO-39** | Mission/office | **Client desk**: mandate/POA registry; client communications rendered in the same four-valued honest-certainty language; GDPR records of processing + consent for AI-assisted processing; EU AI Act posture memo; professional-liability documentation | new |
| **BO-40** | §7 real-time | **Second chair (live)**: streaming transcription (local models); live contradiction flags (testimony vs confirmed facts); prepared-counter lookup over the pre-certified exhaustion tree at speech latency; honest NOVEL flag + recess queue; venue-typed audio posture (NO-AUDIO mode runs identically on typed cues); client-meeting mode with logged consent, live four-valued answers, post-meeting structured intake | new; consumes P4/P5 outputs |
| **BO-41** | §8 fabric | **Experimentation fabric**: frozen proposal-protocol & K interfaces; typed versioned configuration in P5 (postures, sockets, flags); clone-on-write shadow workspaces + SHADOW RUNS parallel to live matters (outputs diffed, never delivered); promotion only via SEV certificate; rollback as a config/version step | sandbox infra shared with BO-33 |

## Phases (order is load-bearing; each phase's exit is machine-checkable)

### P1 — Unblock the proof toolchain
Run `TOOLING/lean-proofs.yml` on GitHub Actions (runners have open network; the dev
sandbox does not). Fail-closed: any `sorry` or undeclared axiom fails the build.
**Exit:** green CI on a seeded theorem; BO-26 skeleton compiles. Everything downstream
depends on this.

### P2 — The kernel K (the heart)
BO-02 (incl. the fail-closed rewrite — first blood of the transformation), BO-03, BO-08,
BO-24, BO-33. **Exit:** K implemented; totality/determinism/fail-closed machine-checked;
no trusted decision path bypasses K; builder protocol operative.

### P3 — Substrate integrity
BO-13, BO-11, BO-12, BO-14, BO-15, BO-21, BO-25, BO-37 (modes + continuity/DR), BO-41
(experimentation fabric — shared substrate with the SEV sandbox). **Exit:**
crash-refinement proof green; all-class bit-for-bit replay demo recorded; wall-clock and
non-determinism out of the trusted path; DR drill passed.

### P4 — The untrusted zone (L1 + L3 + organs)
BO-31 (sockets), BO-34 (hardening + inference boundary), BO-01, BO-18, BO-27, BO-28
(generator + coverage certificates), BO-29 (ledger), scouts (O1 watchers), multimodal
ingestion (O3), opponent simulator (O9).
**Exit:** end-to-end demo — scout finds a real ΦΕΚ change → gate admits it → world
updates → dependent conclusion auto-retracts; one matter run with competing sockets.

### P5 — The verified legal world at scale
BO-10, BO-20, BO-22, BO-09, BO-16, BO-17, BO-04, BO-05, BO-06, BO-07, BO-30, BO-35
(EU/ECHR layer), BO-36 (cross-matter guard); the ELI codification pipeline; Greek
coverage expansion (content work rides on the now-proven pipeline). **Exit:** a full matter runs: ingest → facts → subsumption-with-proof →
exhaustion → tribunal-schema output, all certified.

### P6 — Generality + preventive deployment + the client
BO-23 (second legal order proves non-Greece-lock), BO-19, BO-32 (instrument compiler),
BO-39 (client desk & consent posture), BO-40 (second chair live — hearings & meetings).
**Exit:** parametricity gate green; one real instrument compiled to "born won" with
preclusion certificates.

### P7 — The VERIFIED regime
Backtesting protocol + independent reproduction + BO-38 (incident protocol, standing from
P2 onward) + final BO sweep (see `07-VERIFICATION.md`). **Exit:** the permitted claim upgrades from "strongest design"
to "empirically dominant, independently reproduced" — only then.

## Standing rules for every phase

- Fix at the seat, never guard around it; delete the defect class.
- One seat per concept — check the register + `git log -S` before writing anything.
- Every push validated locally first (lint/tests/proof stubs); one validated push beats
  three speculative ones.
- Repo writes only on the designated branch, only after «εγκρίνω», with the commit
  identity and hygiene rules of `START-HERE.md`.
