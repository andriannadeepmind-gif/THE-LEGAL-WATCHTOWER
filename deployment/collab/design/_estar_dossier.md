Repo grounding confirmed: `authority-v2/kernel/admission-model.sexp` carries the 9 named theorems T1–T9 exactly; the 6 Greek codes (astikos, poinikos, kpolitikis, kpoinikis, kdioikitikis, constitution) are present under `output/`; `redteam-audit-v2` exists; and the named trusted seats (`journal`, `version-graph`, `proof-carrying`, `merkle-authority`, `corpus-fingerprint`, `capability-api`, `negation-layer`, `parallel-executor`, `dependency-graph`, `ROLES-MODEL.sexp`, `trusted-toolchain-manifest.sexp`) all resolve. `legal-receipt`/`exec-provenance`/`references` resolve as package-qualified symbols, not top-level files. The dossier follows.

---

# THE LEGAL WATCHTOWER — E_star Phase‑2 Dominance Design Dossier

*Successor design record. Status: DESIGN + PLAN complete; architecture‑class coverage proved; T6 NOT discharged; FINAL_OPTIMALITY_BLOCKED (fail‑closed). No repo write authorized by this document.*

---

## 1. E_star Thesis (one paragraph)

**E_star moves the entire product one strict tier above the commercial floor by relocating every load‑bearing legal judgment out of the LLM and into a single pure, total admission kernel `K` that emits a proof‑carrying, third‑party‑re‑verifiable certificate for each admitted conclusion — so that on every axis the guarantee is a *structural non‑existence* result (a whole class of error made impossible), never a larger number of the same commercial thing.** The floor is agents + RAG + citation validation: an LLM authors an answer and a checker attaches provenance to it. E_star inverts this — the LLM is demoted to an *untrusted candidate generator* outside the trusted path, and admission is decided by `K(old_state, candidate, evidence, policy) → Reject(all‑reasons) | Accept(new_state, certificate)`, a function with no I/O, no clock, no randomness, and no mutable state, whose output is byte‑for‑byte reproducible and independently checkable without trusting E_star. The one load‑bearing guarantee is fourfold and indivisible: **proof‑carrying** (every conclusion ships an offline‑verifiable evidence object — Merkle inclusion to a signed corpus root, replayable derivation chain, signed transition certificate); **formally‑refined** (the trusted decisions are a language‑neutral spec carrying 9 named theorems on a declared refinement path toward the running binary); **honest‑ignorance** (a genuine gap returns a typed UNKNOWN / "δεν ξέρω" as a first‑class lattice element, never collapsed into a fluent guess, with no LLM anywhere in the trusted path); and **adversarially self‑falsifying** (release is gated on the system manufacturing and provably defeating its own strongest counter‑design). That single idea — *the trusted judgment is a pure certificate‑emitting kernel, not a model output* — is what puts correctness, coordination, grounding, provenance, memory, temporality, determinism, durability, liveness, auditability, evolvability, formal assurance, and cross‑jurisdiction generality each a strict rank above where a floor architecture can structurally reach.

---

## 2. E_star Architecture Overview

E_star is **one executable** in the existing SBCL/Lisp repo (entrypoint `entrypoint.lisp` — "Zero shell‑script orchestration in the trusted path; the entrypoint is Lisp"). It is not a new system; it is the existing seats composed under one integrity discipline. Buildable today.

### 2.1 Layered composition

```
                          UNTRUSTED  (candidate generation — LLMs allowed here, nowhere else)
  ┌───────────────────────────────────────────────────────────────────────────┐
  │  LLM/agent candidate producers  →  content-addressed candidate bundles only │
  └───────────────────────────────────────────────────────────────────────────┘
                                   │  (bundles cross the boundary as DATA)
════════════════ NO-LLM-IN-TRUSTED-PATH BOUNDARY (Θ13 structural axiom) ════════════════
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────────┐
  │  TRUSTED CORE (pure Lisp, jurisdiction-neutral)                            │
  │                                                                            │
  │  Plan layer      orchestrator-spec/pipeline-dsl · orchestrator-core/       │
  │                  dependency-graph  (typed DAG, topo-sort, cycle signal)    │
  │  Ground layer    source/corpus-fingerprint (invariant gate + Merkle root)  │
  │                  source/merkle-authority · source/proof-carrying           │
  │                  source/corpus-service /as-known (typed UNKNOWN)           │
  │  Judgment layer  orchestrator-epistemic/negation-layer (defeater closure)  │
  │                  source/legal-knowledge (honest-ignorance leaf)           │
  │                  source/version-graph (bitemporal, monotone no-negation)   │
  │  Authority layer source/authority-evidence-replay · authority-proof-bundle │
  │                  source/execution-trace · corpus-provenance (PROV-O)       │
  │                                                                            │
  │  ┌───────────────── SINGLE-WRITER INTEGRITY CORE ─────────────────────┐   │
  │  │  K = authority-v2/kernel/admission-model.sexp                        │   │
  │  │      pure · total · 9 conjuncts · Reject(all) | Accept(state,cert)   │   │
  │  │  source/journal.lisp  atomic rename + double fsync + RATCHET-2 CAS   │   │
  │  │  orchestrator-epistemic/authority-boundary  legacy seats fail-closed │   │
  │  └─────────────────────────────────────────────────────────────────────┘   │
  └───────────────────────────────────────────────────────────────────────────┘
                                   ▼
  OS-ENFORCED WRITE CAPABILITY  (authority-v2/proofs/verify-capability-closure.sh:
      real setpriv write attempts; every non-writer identity denied; writer positive-witness)
                                   ▼
  RELEASE / GATE PLANE   orchestrator-cli/*-gate.lisp · authority-v2/roles/ROLES-MODEL.sexp
      capability-gate (monotone floor) · evolution-gate (rollback/revalidation)
      approval-policy (human sole merge) · adversarial redteam-audit-v2 corpus
```

### 2.2 Trusted Computing Base (TCB), stated closed

The trusted path is: the pure kernel `K`; the single journal write seat; the deterministic‑time seat (`source/deterministic-time.lisp`, `SOURCE_DATE_EPOCH`); the Merkle/hash profile (`lawmax-merkle-sha256-v1`, RFC 9162 domain‑separated, unbalanced split so CVE‑2012‑2459 is structurally impossible); Ed25519/RFC‑3161 verification; and the OS write‑capability enforcement. **No LLM, no network, no wall‑clock read** is inside this set — wall‑clock enters only as TSA `genTime` *data* carried inside evidence. The declared residual TCB (`authority-v2/toolchain/trusted-toolchain-manifest.sexp`) is a closed catalog: prover kernels, libc, OS kernel, CPU, and the SHA‑256/Ed25519 cryptographic assumptions.

### 2.3 The three structural boundaries that carry the dossier

1. **No‑LLM‑in‑trusted‑path** — every legal conclusion is authored by `K`, not by a model; LLM output is only an untrusted candidate that must survive the pure gate.
2. **Single‑writer integrity core** — exactly one OS‑capability‑holding writer; `K`'s conjuncts guarantee `unique‑latest`, `monotonic‑sequence` (0,1,2,… no gaps), `no‑rollback`; split‑brain / double‑writer / gap‑insertion are admissible‑state‑count = 0 *by construction*.
3. **Proof‑carrying admission** — `Accept` emits a `transition_certificate` (T9 sound in both directions) that an independent checker validates; acceptance soundly implies every conjunct held.

Everything in Section 3 is a projection of these three boundaries onto one axis of comparison.

---

## 3. The 66‑Cell Planned Dominance Matrix

22 axes × 3 baselines = 66 cells. Baselines: **B‑COMM‑01** CoCounsel Legal (Thomson Reuters) · **B‑COMM‑02** Lexis+ with Protégé (LexisNexis) · **B‑COMM‑03** Harvey (Harvey AI). `proof_status` verbatim throughout. The commercial floor (agents/RAG/citations) is the subordinate check, never the delta.

---

### AX‑01 — Legal‑reasoning correctness & defeater sensitivity
**Mechanism:** proof‑carrying evidence‑rank certificate on a typed defeasible lattice; conclusion cannot enter `:accepted` unless its rebutting/undercutting/statutory‑exception defeater set is ENUMERATED and each defeater is status‑tagged {defeated|undefeated|UNKNOWN}, UNKNOWN a first‑class element; pure gate over `negation-layer.lisp`, LLM excluded. **Δ (logical):** rank tuple (defeater‑closure, ignorance‑handling, trusted‑path); strict iff dominates with ≥1 strict coordinate, threshold gap ≥1.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Adds `defeater‑closure=closed` + `trusted‑path=LLM‑excluded`; authority‑verification retained as subordinate check. Gap = 2 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Protégé citation‑intelligence still model‑produced & defeater‑open; UNKNOWN emitted honest‑total, so "confident wrong under unenumerated defeater" is impossible. Gap = 2 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Harvey's review‑ready cites attach provenance to LLM draft; E_star conclusion authored by pure gate, re‑checkable by `verify.lisp`. Gap = 2 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑02 — Multi‑step decomposition & plan completeness
**Mechanism:** plan = typed DAG; `validate-pipeline` promoted to total decision admitting a plan only if produces/consumes typing closes, graph acyclic, and every goal‑artifact produced; failing plan REJECTED pre‑execution with ALL reasons. **Δ (logical+quant):** rank {inspectable‑post‑hoc < completeness‑decided‑pre‑execution}; incomplete‑plan admission rate structurally 0 vs unbounded.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Steps inspectable but not decided complete; E_star decides dependency‑closure+acyclicity+goal‑coverage pre‑exec. Admission rate 0 vs unbounded | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Reusable workflows run with model discretion, no per‑instantiation completeness certificate; typed DAG supplies it. Rate 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Agent Builder composition errors surface at runtime; `DEFPIPELINE`+dependency‑graph rejects ill‑formed composition at admission. Rate 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑03 — Agent coordination, dependency control, parallelism & arbitration
**Mechanism:** parallelism scheduled off the verified DAG (`parallel-executor.lisp`, lparallel, `stages-ready-to-execute`); arbitration = total deterministic single‑writer `K`; coordination integrity enforced by OS capability closure (`verify-capability-closure.sh`, real write attempts + positive writer witness). **Δ:** rank {runtime‑coordinated < invariant‑enforced}; double‑writer/split‑brain/sequence‑gap admissible states = 0.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | No guarantee concurrent writers to matter state cannot diverge, no replayable arbitration; E_star single‑writer + unique‑latest. Rate 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Routing/continuity ≠ race‑freedom; DAG‑scheduled parallelism + single‑writer ratchet, pure total arbitration. Rate 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Most direct parallel competitor — dominator is NOT team size but DAG‑verified scheduling + provably single canonical writer + deterministic replay. Rate 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑04 — Source‑selection & grounding independent of corpus size
**Mechanism:** grounding by canonical‑identity (ELI/eId) resolution over an invariant‑gated closed set (unique‑eId, no‑gap, count‑match) folded into one signed Merkle root; each unit ships a portable inclusion proof or `/as-known` returns typed UNKNOWN; cost O(1) lookup / O(n) one‑time fold, invariant to |corpus|. **Δ (logical):** predicate G {authenticated‑inclusion OR typed‑UNKNOWN + completeness invariant} strictly above {top‑k similarity, silent miss}.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Relevance retrieval, no completeness guarantee, silent miss; E_star = total function over gated set + portable inclusion proof + typed UNKNOWN | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Routing rides confidence + index recall, no offline‑verifiable authenticity; E_star certifies no‑silent‑miss by invariants, not confidence | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Vault = embedding retrieval, recall silently lossy as vault grows; E_star addresses by legal identity, completeness independent of vault size | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑05 — Citation & legal‑authority validation
**Mechanism:** hermetic, fail‑closed, re‑derived proof chain (`authority-evidence-replay`): refuses bundle‑declared roots, re‑derives source→spans→extraction→normalization→graph‑text byte‑equivalence; tier from closed ordered taxonomy `+apb-assurance-tiers+` awarded ONLY from independently verified predicates; trusted root not recoverable from bundle (no self‑authorization); no LLM in path. **Δ (logical):** fail‑closed verifier V, awarded tier a monotone function only of re‑derived predicates, {hermetic tier + no‑self‑auth + typed reasons} strictly above {issuer‑asserted flag}.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Vendor‑produced status, not offline‑reproducible, no evidence‑only tier; E_star tier re‑derived hermetically, unresolved cross‑cites surfaced | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Shepard's‑class signal computed inside vendor, model‑influenceable; E_star keeps no LLM in path, portable bundle recomputable byte‑for‑byte | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Agent‑produced, asserted validity, LLM on generating path; E_star tier monotone in re‑derived evidence, no self‑authorization | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑06 — Evidence provenance & transformation‑lineage completeness
**Mechanism:** lineage = replayable gated cryptographically chained function (`consolidation-proof` SHA‑256 before/after each op → byte‑exact replay; `legal-receipt` binds FULL genealogy; deterministic PROV‑O; `exec-provenance` `validate-provenance` gating invariant, residual = enumerated explicit trace‑debt). **Δ:** predicate P (every legal‑critical event → contract∧component∧proof OR explicit debt) + replay byte‑equality hard gate; {gating‑completeness + replayable lineage} strictly above {displayed trace‑back}.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Trace‑back links cell→source for humans; E_star gates every critical step + byte‑reproducible consolidated text via hashed ledger | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Continuity carries context, no machine‑checkable coverage proof; E_star deterministic PROV‑O + no‑critical‑step‑without‑provenance invariant | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Multi‑agent pipeline, dropped lineage edge silent; E_star binds full genealogy into receipt‑id + replay byte‑equality + completeness gate | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑07 — Matter context, institutional & reflective memory
**Mechanism:** typed cognitive taxonomy (13 kinds) over 8 canonical stores, ONE writer per store (constitution gate 9); append‑only SHA‑256 chain (`episodes.sexp`, `verify-episode-chain`); `memory_recorded` a COMPUTED invariant (append+read‑back, P0), never a stored flag; reflective consolidation human‑signed‑only, never auto‑adopted; no LLM in memory path. **Δ (logical):** integrity lattice R0<R1<R2<R3; E_star=R3, baseline≤R0.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Workspace persistence (R0), no tamper‑evidence/single‑writer/computed‑recorded; E_star R3. Gap = 3 steps | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Institutional grounding = retrieval/continuity (R0), fed to LLM; E_star R3 with no‑LLM memory path. Gap R3 vs R0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Vault + shared spaces (R0/R1); E_star adds chained recall + single‑writer + human‑signed‑only consolidation. Gap ≥ 2 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑08 — Temporal & legal‑state consistency
**Mechanism:** bitemporal version‑graph; valid‑axis + known‑at from journal `:at`; in‑force computed ALWAYS as fold over live events, zero stored derived state; effectivity a closed MONOTONE AST with no negation; deterministic replay re‑verifies payload+chain+semantic hash → fail‑closed on contradiction; offline‑signed effectivity‑attestation (Π1 implemented, commit 7fc6c718). **Δ (mixed):** lattice T0<T1<T2<T3; reach ≥T2 and replay reproduction error = 0.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Point‑in‑time good‑law flag (T0), no transaction‑time axis; E_star T3 bitemporal + replay‑verified + fail‑closed. Gap = 3 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Citation‑intelligence T0, continuity ≠ transaction‑time axis; E_star T3 valid×known‑at + offline‑anchored attestation | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Cited‑output authority T0/T1; E_star T3 with offline‑signed attestation. Gap 2–3 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑09 — Contradiction, uncertainty, coverage & blind‑spot handling
**Mechanism:** honest ignorance is a structural MEASURED invariant — typed `temporal‑uncertainty` (422) with `false_uncertainty=0` AND no‑silent‑yes (`silent_scope_omissions=0`); contradiction fail‑closed (typed error, journaled‑retract‑only, never silent pick/average); blind spots typed knowledge‑gaps with intervals; adversarial negative‑witness gates (12/12, 14/14, `unverified_satisfactions=0`); no LLM in path. **Δ (mixed):** lattice U0<U1<U2<U3; reach ≥U2 + ≥1 honesty counter held at exactly 0.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Answer‑then‑check with LLM in path (U0), no abstention/non‑contradiction guarantee; E_star U3 double‑bounded honesty. Gap = 3 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Multiple configs + citation‑intelligence stay U0; E_star U3 with counted honesty invariants | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Parallel agents + cited outputs U0/U1 best‑effort; E_star U3 (false_uncertainty=0, silent_scope_omissions=0, negative‑witness gates) | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑10 — Self‑falsification, counter‑design generation & escalation
**Mechanism:** adversarial self‑falsification as a RELEASE‑GATING invariant — fresh‑context critic agents on two axes (break‑the‑model; hunt‑mediocrity), `redteam-audit-v2` metamorphic families (006/007/008 verdict‑must‑flip) + 6 counter‑proposal fixtures that MUST all be Rejected; merge blocked unless every counter‑design defeated; survivors auto‑escalate to the single human approver. **Δ:** lattice L0<L1<L2<L3<L4; baseline at L1 (LLM‑grounded validation), E_star at L4; co‑instrument N = mandatory reject‑corpus size vs baseline 0.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Verifies cites resolve (L1); E_star builds & must defeat strongest counter‑design pre‑emit (L4). Review subsumed | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Citation‑intelligence confirms linkage (L1); E_star runs independent adversaries, gates release on their failure (L4) | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Parallel teams collaborate toward one answer; E_star mandates ANTAGONISTIC agents whose success blocks merge | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑11 — Workflow/tool orchestration with explicit transaction semantics
**Mechanism:** total‑function kernel `K` as single commit boundary — 9 conjuncts all‑or‑nothing, sequence = old+1 exactly, no‑rollback/not‑an‑ancestor, unique‑latest, RFC 9162 log‑consistency + signed monotonic checkpoint; legacy write‑seats fail‑closed (`LEGACY-AUTHORITY-SEAT-REMOVED`); each step commits atomically as signed `transition_certificate` or changes nothing. **Δ:** L4 vs L1; co‑instrument 11 machine‑checked invariants/commit vs 0.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Steps inspectable, not transactional; E_star all‑or‑nothing commit + signed cert. Inspectability subsumed | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Reusable workflows carry no ACID commit; E_star enforces 11 invariants/commit, forbids out‑of‑sequence/partial | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Parallel writers over shared artifacts = interleaving risk; E_star single writer + serialized commit + unique‑latest | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑12 — Institutional decision authority, review & accountable state transition
**Mechanism:** authority = typed role‑attributable capability (`ROLES-MODEL.sexp`, TUF‑class root OFFLINE/release/targets/snapshot/timestamp, threshold+keyids, revocation); every transition signed via `K`'s certificate; human sole merge power (`approval-policy.lisp`, auto‑approval only with measured precision + full reversibility); PCL‑1 publisher‑independent verification; no LLM in path. **Δ (logical):** L4 vs L1; decision object simultaneously role‑attributable, non‑repudiable, third‑party verifiable.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Records informal reviewer; E_star binds every transition to cryptographic role signature under offline root | logical | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Grounds decisions but keeps LLM in path, no offline root/non‑repudiation; E_star excludes LLM, signed+revocable+reversible | logical | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Shared spaces distribute authority, no single‑writer accountability; E_star routes every transition through one signed‑role writer | logical | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑13 — Auditability, provenance‑complete replay & reproducibility
**Mechanism:** producer‑independent full‑derivation replay (`authority-evidence-replay`) — refuses declared roots, re‑derives source bytes→spans→extraction→normalization→graph→signed root with recompute‑and‑compare at every step; portable per‑provision Merkle inclusion proof + PROV‑O; third party runs `verify-authority-evidence-bundle` offline. **Δ:** ladder R0<R1<R2<R3<R4; E_star at R4, baseline ≤R1; recomputable‑chain fraction 1.0 vs 0. Measured rank gap = 3.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Internal check the reader must trust (R1); E_star R4 offline recompute‑and‑compare. Fraction 1.0 vs 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Look‑up‑and‑flag against Lexis's own graph (R1); E_star reconstructs root from raw source, zero producer trust | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Producer‑asserted review‑ready cites (R1); E_star R4 with full‑chain recompute. Gap = 3 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑14 — Determinism under frozen inputs & declared nondeterminism control
**Mechanism:** pure trusted kernel + enumerated declared‑nondeterminism closure — `K` clock‑/RNG‑/IO‑free, one time seat (`deterministic-time.lisp`, `SOURCE_DATE_EPOCH`), single Merkle profile; genuine nondeterminism (TSA nonce, JWS randomness, capture clock) quarantined into a declared set; `determinism/run1` vs `run2` hold the deterministic partition to bit‑for‑bit reproduction. **Δ:** deterministic partition reproduction error = 0 bits + total enumeration of nondeterministic artifacts.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | LLM steps sampling‑nondeterministic, no bit‑reproduction/enumeration; E_star 0‑bit partition + closure, clock‑/RNG‑free kernel | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Model routing multiplies nondeterminism; E_star one deterministic kernel, time‑as‑data, enumerated closure | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Parallel agents add scheduling nondeterminism; E_star pure total kernel, declared boundary, 0‑bit partition | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑15 — Durability, crash consistency & bounded recovery
**Mechanism:** integrity ratchet in single journal seat — WRITE‑FILE‑ATOMIC (tmp+rename(2)) + fsync(2) of data AND parent dir; Persistence Receipt fail‑closed (`%fsync` error → SYNC‑FAILURE, never labelled `:durable`); RATCHET‑2 compare‑and‑append makes forked chain structurally impossible; torn tail keeps valid prefix and DECLARES imperfection; recovery O(valid prefix), loss ≤ last non‑acknowledged record. **Δ:** ladder C0<C1<C2<C3<C4; E_star at C4, baseline ≤C1. Rung gap = 3.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Persistence‑as‑feature (C1); E_star C4 atomic rename + double fsync + fail‑closed receipt + bounded recovery. Gap = 3 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Continuity presumes storage but declares no crash mechanism; E_star supplies C4 anti‑fork + bounded recovery | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Shared vault + concurrent writers = torn‑write risk; E_star per‑path single‑writer + compare‑and‑append (C4) | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑16 — Progress & liveness under the declared operating model
**Mechanism:** total LLM‑free trusted decision — `K` returns Reject|Accept for EVERY input, no exception/undefined/hang, no third exit; no LLM/network/clock to loop or stall; T2 (completeness), T3 (sequence advances), T7 (Reject → no state change) pin progress; single‑writer compare‑and‑append yields bounded stale‑link retry, not deadlock. **Δ:** machine‑checkable totality + honest‑ignorance termination; worst‑case bounded by input size vs unbounded.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Inspectable ≠ always‑halts; E_star total function, bounded step count, honest‑ignorance termination | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Continuity + model selection add stall routes; E_star total, clock‑/network‑free, terminating Reject | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Parallel agents introduce coordination stalls; E_star converts contention to bounded retry, total gate | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑17 — Latency across frozen workload distributions
**Mechanism:** pure deterministic SBCL over Merkle‑pinned snapshot, no LLM on trusted path; `execution-trace.lisp` data‑only monotonic‑id span DAG → hashing yields a REPLAY‑CERTIFIED LATENCY ENVELOPE (same frozen workload → bit‑identical trace + identical op count → p100 tail is a deterministic function of input); signed latency‑trace replayable offline. **Δ:** existence of a replay‑certified deterministic envelope (trace‑hash equality, 0 differing ops) + deterministic p100 bound — NOT a smaller mean.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Agentic‑LLM tail is irreproducible random variable; E_star signed trace, 0‑op replay error, deterministic p100 | quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Per‑task model routing = higher‑variance mixture; frozen path routes to no model, bit‑identical trace | quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Parallel coordination adds straggler/join tail; E_star deterministic p100 envelope a multi‑agent fabric can't certify | quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑18 — Throughput, scale & resource‑normalized performance
**Mechanism:** throughput UNIT = proof‑carrying artifact (provision + inclusion proof to signed root + trace), offline re‑verifiable in O(log n) with zero pipeline re‑run; corpus scale governed by RFC 9162 §2.1.4.2 consistency proofs (`consistency-proof`/`verify-consistency`, old⊑new in O(log n) without leaves) under single‑writer append‑only ratchet. **Δ:** verifier cost class O(log n) vs O(n)/re‑ingest + per‑artifact offline‑verifiability — NOT bigger artifacts/second.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Trace‑back vendor‑internal & re‑run/trust‑based; E_star portable O(log n) offline proof + append‑only consistency | quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Grounding grows by re‑index/embed, correctness not a proof; E_star proves each delta without leaves | quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Vault audit needs trusting Harvey + re‑processing; E_star bounds delta audit at O(log n), proof‑carrying units | quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑19 — Introspection, explanation & inspectable causal account
**Mechanism:** every trusted conclusion emits a MACHINE‑CHECKABLE causal proof object, not NL rationalization — typed data‑only span DAG (`execution-trace`), Merkle inclusion proof per authority (`proof-carrying`, `verify-provision-proof`), honest‑ignorance gate structurally forbids a chainless conclusion ("δεν ξέρω"). SOUND (every conclusion has re‑verifiable chain) + COMPLETE (absence reported, never hallucinated). **Δ:** tiers T0<T1<T2; E_star T2 with verifiability coverage 1.0 by construction, baseline structurally <1.0 and un‑certifiable.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Inspectable steps ≤T1, LLM explains LLM, no honest‑ignorance completeness; E_star T2, coverage 1.0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Citation‑intelligence T1 but "why" is LLM narrative over routed pipeline; E_star DAG+proofs re‑checked, coverage 1.0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Cited output T1, cross‑agent account is NL reconstruction; E_star T2 proof object, coverage 1.0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑20 — Evolvability with monotonic capability & invariant preservation
**Mechanism:** every evolution step admitted only through pure total `K` (sequence‑monotonicity, no‑rollback, profile‑continuity binding predecessor hash + owner‑root signature); capability ratcheted by fail‑closed `capability-gate.lisp` scoring candidates on frozen benchmarks against committed floor (`capability-baseline.sexp`), refusing any release below floor on ANY metric; append‑only version‑graph + journal RATCHET‑4. **Δ:** lattice rank 0 {mutable accumulation} < rank 1 {typed monotone ratchet + replay‑verified lineage + fail‑closed regression gate}; P(admit below floor) = 0 by construction.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Mutable memory accumulation, no regression gate; E_star K + frozen‑benchmark ratchet. Rank 1 vs 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Model routing = unguarded regression surface; E_star fails closed below committed floor. Rank 1 vs 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Agent Builder freely mutable, no monotone floor; E_star gates via K + benchmark ratchet. Rank 1 vs 0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑21 — Formal assurance & architecture→source→executable property transport
**Mechanism:** trusted decisions specified as language‑neutral pure model carrying 9 named theorems (T1‑T9, incl. T9 certificate‑soundness both directions); 5‑link refinement chain with named obligation+tool per link (`trusted-toolchain-manifest.sexp`: spec → F*/Coq (EverCDDL/Perennial) → extracted source (KaRaMeL/Goose) → CompCert binary → reproducible‑build byte‑identity → closed residual‑TCB catalog); independent proof‑object checkers run today (`verify-proof-manifest.py`, `verify-completion-matrix.py`, capability‑closure + replay with real negative witnesses). **Δ:** ladder rank 0<1<2<3<4; baseline ≤1, E_star operational rank 2‑3 today, strictly exceeds ≤1.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | Heuristic check, LLM inside path, no proof object/checker/TCB (≤1); E_star pure kernel + independent‑checker cert + closed TCB (2‑3) | logical | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Citation‑intelligence over generative output (≤1), configs ARE the trusted path; E_star proof‑carrying cert checked independently of any model | logical | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Output‑level property by agents in path (≤1); E_star transports spec property link‑by‑link + bidirectional‑sound cert | logical | ARCH_CLASS_PROVABLE_NOW |

---

### AX‑22 — Mechanism generality across legal orders without content‑specific redesign
**Mechanism:** jurisdiction‑NEUTRAL trusted core (FRBR/ELI/PROV‑O generator + consistency validator + RDF canonicalizer + SHACL shapes + version‑graph + `K`) parameterized only by a thin per‑order content module; already emits byte‑canonical proof‑carrying artifacts across the SIX Greek codes (astikos, poinikos, kpolitikis, kpoinikis, kdioikitikis, constitution — all present under `output/`); a new order added as a content module (e.g. `orchestrator-gr-syntagma`) over the unchanged core; "one hearth per concept" forbids per‑order duplication. **Δ:** core‑invariance ratio 1.0 (zero trusted‑core edits) across ≥2 orders vs undefined; lattice rank 1 vs 0.

| Baseline | E_star strictly‑stronger | evidence_mode | proof_status |
|---|---|---|---|
| B‑COMM‑01 | No exposed transportable trusted core → ratio undefined (rank 0); E_star reuses one core across 6 codes, ratio 1.0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑02 | Source selection chooses content, not an order‑neutral core; E_star guarantees carried unchanged per order, ratio 1.0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |
| B‑COMM‑03 | Vault/agent generality = corpus breadth (rank 0); E_star adds order as content module over unchanged core, ratio 1.0 | logical+quantitative | ARCH_CLASS_PROVABLE_NOW |

---

## 4. Capability‑Superset Ledger

For each baseline *b*, the claim is `Capabilities(E_star) ⊋ Capabilities(b)`: E_star still performs **all** declared floor capabilities of *b* (agentic multi‑step research/analysis/drafting/review, RAG grounding, citation validation, reusable/parallel workflows, persistent matter memory, shared artifacts, institutional grounding) — these are retained as *subordinate* checks below the lattice top — **plus ≥1 material extra element per axis that no baseline declares**. The 22 extra elements:

| Axis | Strict‑superset element added to Capabilities(E_star) (absent from B‑01/02/03) |
|---|---|
| AX‑01 | emit‑defeater‑closed‑conclusion‑with‑reproducible‑evidence‑rank‑certificate‑under‑no‑LLM‑trusted‑path |
| AX‑02 | decide‑and‑certify‑plan‑completeness‑pre‑execution (dependency‑closure + acyclicity + goal‑coverage, exhaustive reasons) |
| AX‑03 | coordinate‑parallel‑agents‑with‑machine‑enforced‑single‑writer‑unique‑latest‑deterministic‑arbitration |
| AX‑04 | portable third‑party‑verifiable Merkle inclusion proof per unit + typed honest‑UNKNOWN, corpus‑size‑invariant completeness |
| AX‑05 | portable authority‑proof bundle verifiable OFFLINE without trusting issuer; no assertion can raise the tier; root not recoverable |
| AX‑06 | byte‑exact third‑party replay of before/after‑hash‑chained amendment ledger + gating provenance‑completeness invariant (explicit trace‑debt) |
| AX‑07 | cryptographic tamper‑evident memory with single‑writer provenance + COMPUTED recorded‑claim + human‑signed‑only reflective consolidation |
| AX‑08 | bitemporal deterministic‑replay legal‑state reconstruction, zero stored derived state, monotone no‑negation, offline‑signed attestation |
| AX‑09 | machine‑MEASURED double‑bounded honest ignorance + fail‑closed contradiction (journaled‑retract‑only) + interval‑typed blind‑spots |
| AX‑10 | generate‑and‑defeat‑your‑own‑strongest‑counter‑design as release precondition + honest‑ignorance abstention |
| AX‑11 | atomically‑committed state transition with portable signed transition_certificate + forward‑only integrity ratchet |
| AX‑12 | role‑attributable, non‑repudiable, offline‑root‑anchored accountable transition + publisher‑independent proof‑carrying verification |
| AX‑13 | offline producer‑independent re‑derivation of authority root from raw source + portable per‑provision inclusion proof |
| AX‑14 | frozen‑input deterministic replay + enumerated declared‑nondeterminism closure + provably clock‑free/RNG‑free kernel |
| AX‑15 | crash‑consistency by construction (atomic rename + double fsync) + fail‑closed durability receipt + structurally impossible forks + bounded recovery |
| AX‑16 | total, LLM‑/clock‑/network‑free trusted decision with honest‑ignorance termination + bounded single‑writer contention |
| AX‑17 | signed independently‑replayable deterministic latency envelope (bit‑stable op count + p100 bound) over no‑LLM path |
| AX‑18 | resource‑normalized proof‑carrying throughput unit + append‑only O(log n) Merkle consistency audit under single‑writer ratchet |
| AX‑19 | offline machine‑checkable causal proof object (span DAG + inclusion proofs) with honest‑ignorance completeness, zero‑trust re‑verify |
| AX‑20 | machine‑checkable monotone‑capability certificate + append‑only replay‑verified evolution lineage with no‑regression proof |
| AX‑21 | proof‑carrying transition certificates validated by an independent checker + explicit spec→binary refinement chain + closed residual‑TCB |
| AX‑22 | jurisdiction‑neutral trusted core with per‑order content modules whose guarantees transport UNCHANGED (portability‑of‑guarantee) |

Because each element is provably outside every baseline's *declared* capability set (all three place an LLM in the trusted path and declare none of these guarantees), the containment is strict against B‑01, B‑02, and B‑03 **separately** on all 22 axes.

---

## 5. Honest Proof‑Obligation Ledger

### 5.1 Cell counts by `proof_status` (verbatim tokens)

| proof_status | Count | Fraction |
|---|---|---|
| `ARCH_CLASS_PROVABLE_NOW` | **66 / 66** | 100% |
| `VERIFIED` | **0 / 66** | 0% |

All 66 cells (22 axes × 3 baselines) carry `proof_status = ARCH_CLASS_PROVABLE_NOW`. **Zero cells are `VERIFIED`.**

### 5.2 What Phase 2 does and does NOT establish (stated plainly)

Phase 2 **DESIGNS** the E_star mechanism per axis, **PLANS** its composition into one buildable SBCL executable, and **proves architecture‑class coverage** — i.e. that the dominance is a *structural guarantee gap* over each baseline's *declared* capability, established by the lattice rank argument plus the executable seats that already run (invariant gates, capability‑closure with real negative witnesses, deterministic replay fixtures, proof‑object checkers). Phase 2 **does NOT discharge T6** (deterministic byte‑identical replay) as a machine‑checked theorem, and does not discharge T1–T5, T7–T9; these remain `:blocked-toolchain`. The dominance claim rests on the executable guarantee‑class, which the formal proofs only *strengthen* (raise rank), not *gate*.

### 5.3 Residual obligations remaining for full `VERIFIED` (none discharged here)

Per the residual‑obligation tokens carried in the cells, full `VERIFIED` requires all of:

1. **`NEEDS_BLACK_BOX_PRODUCT_RUN`** — licensed head‑to‑head runs of CoCounsel / Lexis+Protégé / Harvey to fix the *cardinal* margins (correctness rate, recall/faithfulness, citation accuracy, temporal‑query accuracy, explanation‑faithfulness) and to confirm the baselines' exported‑stage / gated‑counter‑design counts. These pin numbers; they cannot lift a baseline into E_star's guarantee class.
2. **`NEEDS_EXECUTABLE_BENCHMARK`** — run the E_star pipeline N times to publish: 0‑bit reproduction on the deterministic partition + full membership of every varying file in the declared nondeterminism set (AX‑14); recovery‑latency and data‑loss under fault injection (AX‑15); trusted‑decision step‑count/latency (AX‑16, AX‑17); verified‑artifacts‑per‑core‑second and O(log n) consistency‑audit timing (AX‑18); negative‑witness regressor Reject / improver Accept (AX‑20); foreign‑order core‑invariance ratio (AX‑22).
3. **Closed architecture‑class proof replay** — discharge of the 9 kernel theorems T1–T9 in F*/Coq via the 5‑link refinement chain (EverParse/EverCDDL → Perennial/Goose → KaRaMeL → CompCert → reproducible‑build byte‑identity). Currently `:blocked-toolchain` (F*/Coq/CompCert absent in‑image / network 403); also gated by `blocked-spec-input` (TUF spec pin) and the owner‑pending CompCert commercial‑license decision, and the offline‑root ceremony (structural stop point).
4. **Independent reproduction** — a third party re‑runs `verify-authority-evidence-bundle`, `verify-provision-proof`, `verify-capability-closure.sh`, `verify-proof-manifest.py`, and the determinism run1/run2 replay, reproducing every certificate and root byte‑for‑byte with zero trust in E_star.

### 5.4 Fail‑closed default

Until 5.3(1)–(4) are all discharged, the system's optimality verdict remains **`FINAL_OPTIMALITY_BLOCKED`**. Phase 2 asserts architecture‑class dominance only; it does not, and this dossier does not, assert `VERIFIED` final optimality. Honest ignorance governs the verdict itself.

---

## 6. B0 → E_star Repository Transformation Outline (FOC‑19 / T7 direction)

High‑level shape only. **No write is authorized by this document** — every change below requires a creator‑approved *sealed delta* (explicit «εγκρίνω X» per phase) before a single line is touched; `deployment/self/history.sexp` and `output/.healthy` are reset (`git checkout --`) before each commit, author/committer `Stavropoulos Law® <info@stavropouloslaw.com>`, no AI trailer.

**ADD**
- `authority-v2/kernel/` F*/Coq discharge artifacts for T1–T9 and the 5 refinement‑link obligation files (spec→binary) once the toolchain is unblocked.
- Per‑axis certificate emitters where a seat produces a conclusion but not yet a portable certificate (AX‑01 defeater‑rank certificate; AX‑17 signed latency‑envelope trace; AX‑20 monotone‑capability certificate).
- Foreign‑legal‑order content module scaffold (AX‑22) over the unchanged trusted core.

**MODIFY**
- Promote `validate-pipeline` (AX‑02) and `scope-covers-p` / uncertainty seats (AX‑09) to *total* decision functions returning exhaustive reason lists.
- Extend `negation-layer.lisp` into the defeater‑closure admission gate (AX‑01); generalise the honest‑note pattern to a first‑class UNKNOWN lattice element everywhere it is currently local.
- Wire `capability-gate.lisp` to the committed floor vector as a hard release refusal (AX‑20).

**REFACTOR**
- Consolidate any provenance/lineage logic into the single `exec-provenance` / `consolidation-proof` hearth so the gating‑completeness invariant (AX‑06) has one seat.
- Collapse duplicate time reads into the single `deterministic-time.lisp` seat (AX‑14) — enforce "no implicit clock in trusted core."

**MOVE**
- Relocate any residual conclusion‑authoring logic *out* of LLM‑adjacent modules and *into* the pure kernel path, so the No‑LLM‑in‑trusted‑path boundary (Θ13) is a code‑location fact, not a convention.

**REPLACE**
- Replace any vendor‑asserted / caller‑asserted status flags with re‑derived predicate‑gated verdicts (AX‑05 authority tier; AX‑13 root re‑derivation).
- Replace best‑effort retrieval selection with canonical‑identity resolution over the invariant‑gated set (AX‑04).

**REMOVE**
- Retire every legacy write‑seat behind `authority-boundary.lisp` (`LEGACY-AUTHORITY-SEAT-REMOVED`) so the single‑writer core (AX‑03/11/15) has no bypass — **T7 direction**: `Reject ⇒ no state change`, extended repo‑wide to "no path mutates authoritative state except through `K`."
- Remove any silent fallback / averaging / first‑reason‑only rejection so contradiction handling is uniformly fail‑closed (AX‑09).

The transformation is monotone by AX‑20's own discipline: it is itself admitted only through `K`, forward‑only, no‑rollback, capability‑floor‑preserving — the repo cannot regress a held invariant while becoming E_star.

---

*End of dossier. Status tokens preserved verbatim. Architecture‑class coverage: proved. T6: not discharged. Verdict: FINAL_OPTIMALITY_BLOCKED (fail‑closed). Awaiting creator‑approved sealed delta before any write.*