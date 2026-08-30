# DELIVERABLE 6 — PATH-LEVEL TRANSFORMATION of the real repository

**Repo:** `/home/user/THE-LEGAL-WATCHTOWER` — working tree = frozen baseline `e621dbe1` **+**
the one sanctioned extra dir `deployment/collab/fresh-phase-2-launch/` (HEAD `803113c0`).
**Target seats:** CANON-Ω2 §3–§6 (`K-adm`, `K-src`, `K-prf`, `K-typ`, `K-write`, `K-precl`,
`G-pub`, `G-inf`, `G-sev`, `epistemic-store`, `premise-ledger`, `deadline-kernel`, `isolation`,
`compliance-seat`, `socket-bay`, `SEV`/`G-sev`, `victory-organs`).
**Binding envelope:** internal single-firm Greek legal super-system (EU/ECHR inside the Greek
order); only final outputs go public via a separate fail-closed Publication Gateway;
cost/time/compute/staffing are NOT constraints; deadlines/latency/availability/reliability ARE
correctness requirements; corpus volume out of scope; no fabrication.

**Method / honesty discipline.** Every `existing_path` in the table below was verified VERBATIM on
disk this session (`ls`/`find`/`grep`/`Read`); a path is either quoted exactly or marked **NEW**
(does not exist — must be created). No path is invented. `output/` and `output_run1/` are treated by
path/dependency-position only (contents NOT read, per brief). Claim-status is tagged per row and per
finding: `DEMONSTRATED` (I ran the check), `EMPIRICAL` (read from the file's own banner), `DESIGN-
ENTAILED`, `THEOREM`, `HYPOTHESIS`, `UNKNOWN`. **Discharge tests are machine-checkable** — a script,
a fuzz harness, a determinism replay, a byte-compare — never "review confirms." `proof-checking ≠
formalization correctness`; `model access ≠ idea inclusion`; unresolved contradictions stay BLOCKING.

**GOVERNANCE PRECONDITION (CLAUDE.md, non-negotiable).** This document is a *mapping and a proposed
build order*, not an authorization to mutate the tree. **No file below is created, moved, refactored,
retired or deleted without an explicit per-phase creator «εγκρίνω X».** Nothing opens itself. Author/
committer identity on any resulting commit is `Stavropoulos Law® <info@stavropouloslaw.com>`, no AI
trailer; `deployment/self/history.sexp` and `output/.healthy` are `git checkout --`-restored before
each commit.

---

## 0. On-disk baseline the mapping stands on (`DEMONSTRATED` this session)

| fact | verified value |
|---|---|
| `source/` seat count | **133** `.lisp` files (flat) |
| `systems/` engine subsystems | **11** dirs: `orchestrator-{ai-core, cli, core, engine-sbcl, epistemic, gr-syntagma, meta, model, omega-modules, spec, tests}` |
| root ASDF definitions | **16** `orchestrator*.asd` at repo root; **17** `.asd` tree-wide excl. `third-party/` (+`systems/orchestrator-omega.asd`) — *see DRIFT §D.a: prior canon's "23" is unverified* |
| `systems/orchestrator-cli/*-gate.lisp` | **17** gate files (`architecture, capability, component, contract, deontic, dialogue, event, evolution, external-benchmark, fluid, generation, golden, inference, iq, provenance, release, verify-truth`) |
| `source/constitutional-gate.lisp` | **fail-OPEN at lines 43–47** confirmed by direct Read (`(error () (values t nil))` = crashing predicate ⇒ ALLOW). **R-4 BLOCKER.** |
| `admission-model.sexp` | exists at `authority-v2/kernel/admission-model.sexp` (single file) |
| `emit-graph` | `(defun emit-graph …)` at `source/write-authority.lisp:16` — a **function seat, NOT a file** |
| `meta-ontology.lisp` | ONLY at `systems/orchestrator-epistemic/meta-ontology.lisp` (**no `source/meta-ontology.lisp`**) |
| `inference-gate.lisp` | ONLY at `systems/orchestrator-cli/inference-gate.lisp` (**no `source/` copy**) |
| `legal-authority-replay` | **MISSING** — zero hits, any extension, any dir (prior-canon ghost) |
| deadline / publication / DLP / matter-isolation / socket seats in `source/` | **NONE** — `deadline-kernel`, `G-pub`, `isolation`, `socket-bay` are all **NEW** |
| `source/legal-conflict-resolution.lisp` | exists — **norm-conflict** resolution (authority lattice), NOT firm-wide matter-conflict |

---

## 1. THE MAPPING TABLE — one row per real seat

Columns: **existing_path** → **disposition** (KEEP / REFACTOR / RETIRE / DELETE / NEW) →
**target_seat** → **dependency (what must land first)** → **discharge_test (machine-checkable)**.

### A. Admission core → K-adm (the genuinely tiny kernel + the fail-closed barrier)

| existing_path | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| `authority-v2/kernel/admission-model.sexp` | **REFACTOR** | **K-adm** | proof-CI up (Phase 0); N-version decider harness | `bypass-fuzz`: over ≥10⁶ random proposals, count ledger COMMITs lacking a checker PASS + premise-manifest + K-typ stamp ⇒ MUST be 0. `determinism-replay`: bit-identical decision from `(proposal, policy-version, clock)` across 2 independent builds. |
| `source/constitutional-gate.lisp` (lines 43–47 fail-open) | **REFACTOR → fail-CLOSED** | **K-adm** barrier predicate | **R-4 — FIRST change in the whole build**; no dependency, it *is* the root dependency | `fail-closed-fuzz`: inject a predicate that unconditionally `(error)`; assert `evaluate` returns `(values nil …)` (REJECT) for the covered command, never `(values t …)`. Property test: ∀ rule r applying to command c, `(error)` in `r.predicate` ⇒ decision ≠ ALLOW. CI gate blocks merge if any admit-path can reach ALLOW via the `error` branch. |
| `systems/orchestrator-cli/constitutional-dispatch.lisp` (CLOS `around` mediation) | **REFACTOR** | **K-adm** dispatch/mediation | refactored `constitutional-gate` (fail-closed) | `mediation-completeness`: every privileged command name is covered by a registered rule OR routes to explicit REJECT; fuzz an unregistered command ⇒ default-deny, not silent pass. |
| `source/ast-gate.lisp` | **KEEP** | **K-adm** structural checker (bus member) | K-adm interface frozen | `structural-checker-negative`: malformed AST ⇒ REJECT; well-formed ⇒ PASS; no third outcome reachable. |
| `systems/orchestrator-cli/approval-policy.lisp`, `self-reflection.lisp` (constitution consumers) | **REFACTOR** | **K-adm** (rule registrants) | fail-closed `constitutional-gate` | `consumer-conformance`: each `register-rule` call's predicate is total on its declared domain (fuzz inputs; no unhandled `error` escapes to the gate). |

### B. Source-authority recompute + physical writer → K-src / K-write

| existing_path | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| `source/write-authority.lisp` (`emit-graph` defun) | **REFACTOR** (guard the single writer) | **K-src** emit + **K-write** commit | `validation-authority` guard wired *before* emit; K-write journal seat | `emit-guard`: assert every `emit-graph` call-site (≈9, in `ai-citation-strategy`, `legal-audit-system`, `semantic-versioning-system`, `consolidate.lisp`, FRBR generators) passes through `validation-authority` FIRST; a fuzz TTL that fails canonical-validate ⇒ 0 bytes emitted. |
| `source/validation-authority.lisp` | **KEEP** | **K-src** (canonical-TTL validate-before-emit) | — | `validate-before-emit`: property — no output artifact exists without a preceding PASS record; inject non-canonical TTL ⇒ REJECT. |
| `source/merkle-authority.lisp` (RFC 6962, 13 defuns) | **KEEP** | **K-write** integrity / **K-src** | K-write journal seat | `merkle-mutation-witness.sh` (exists) + `deployment/verify/verify-merkle.py`: mutate any leaf ⇒ root mismatch + alert; inclusion proof re-checks. |
| `source/journal.lisp` (append-only SHA-256 chain, 21 defuns) | **KEEP** | **K-write** (the ONE physical writer) | — | `tamper-test`: rewrite a past line ⇒ all subsequent `:HASH`/`:PREV` links + external anchor fail. `orphan-effect`: 0 privileged effects without a ledger entry (fuzz effect-emitters). |
| `source/self-history.lisp` + `deployment/self/history.sexp` | **KEEP** | **K-write** record / **G-sev** biography | K-write | `chain-verify`: SHA-256 `:PREV`/`:HASH` continuity from genesis; break one line ⇒ verifier fails. |
| `source/legal-authority-receipt.lisp` | **KEEP** | **K-write** / **G-pub** receipt-mint | G-pub pipeline (for publication receipts) | `receipt-binding`: every minted receipt binds artifact-hash + full conjunction result; forge a receipt without a passing gateway record ⇒ verifier rejects. |
| `source/timestamp-authority.lisp`, `jws-authority.lisp`, `blockchain-authority.lisp`, `archive-authority.lisp`, `signed-embedding-manifest.lisp`, `json-emit.lisp`, `semantic-authority.lisp` | **KEEP** | **K-write** external-anchor / emit adjuncts | K-write journal seat | `external-anchor`: multi-TSA anchor present for each committed root; drop one anchor ⇒ "not all TSAs collude" assumption re-checked, verifier flags under-anchored root. |

### C. Proof / certificate checkers → K-prf (one checker per proof system, NOT one blob)

| existing_path | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| `source/proof-carrying.lisp` | **REFACTOR** (split per proof-system) | **K-prf** | K-adm bus; per-system checker registry | `checker-split`: Lean/LRAT/Horty each have an independent checker binary; solver removed from TCB (LRAT re-checked by `cake_lpr`-class checker). Inject an invalid certificate per system ⇒ INVALID; valid ⇒ VALID; no cross-system trust. |
| `source/authority-proof-bundle.lisp` | **REFACTOR** | **K-prf** bundle verifier | `proof-carrying` split; `premise-ledger` (NEW) | `bundle-completeness`: no bundle VALID without its formalization-fidelity artifact (§5.2) attached; strip the artifact ⇒ bundle rejected. |
| `source/consolidation-proof.lisp` (9 defuns, replayable amendment proof) | **KEEP** | **K-prf** (consolidation) | K-write; replay harness | `replay-consolidation`: re-run the amendment proof from source ⇒ bit-identical consolidated result; perturb one input ⇒ proof fails, not silently re-derives. |
| `source/authority-evidence-replay.lisp` (29 defuns) | **KEEP** | **K-prf** / **K-src** replay | K-src recompute path | `replay-determinism`: replay authority evidence ⇒ identical AuthorityRef@interval; forged/amended/repealed source ⇒ REJECT (not a trusted ref). |
| `source/corpus-provenance.lisp`, `provenance-link.lisp`, `narrative-provenance.lisp` | **KEEP** | **premise-ledger** feed / **K-prf** | `premise-ledger` (NEW) | `provenance-resolvable`: every trusted emission's manifest resolves to byte-identical source; dangling provenance pointer ⇒ emission blocked. |
| `source/legal-extraction-verify.lisp` | **KEEP** | **K-prf** (extraction check) | — | `extraction-negative`: seed known-wrong extraction ⇒ verify fails. |
| `systems/orchestrator-epistemic/temporal-proof.lisp`, `systems/orchestrator-ai-core/provenance-model.lisp` | **KEEP** | **K-prf** temporal / provenance | epistemic-store bitemporal typing | `temporal-proof`: "law as of act-date" vs "law now" both derivable; `deployment/verify/verify-temporal.py` passes; contradictory temporal claim ⇒ surfaced UNKNOWN. |

### D. Epistemic multi-world store → epistemic-store (DELETE single-world)

| existing_path | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| `source/version-graph.lisp` (bitemporal, **114 defuns — largest seat**) | **REFACTOR** (extend to labelled multi-world) | **epistemic-store** | `multi-world` typing (NEW) over norms/facts/procedure | `no-silent-collapse`: type system forbids collapsing to a single world/stance without a recorded R0 decision; attempt an unrecorded collapse ⇒ compile/runtime type error. `consistency-audit`: inject contradictory authorities ⇒ surfaced as conflict edges, never absorbed. |
| `authority-v2/` store (`store/`, `log/`, `capability/`, `genesis/`, `fixtures/`, `schema/`, `roles/`) | **REFACTOR** | **epistemic-store** + **isolation** substrate | version-graph multi-world extension | `equal-rank-splits`: represent "N means X per forum f₁ vs ¬X per f₂" as first-class edges; a store that can only hold one meaning ⇒ test fails. |
| `source/legal-conflict-resolution.lisp` (norm-conflict) | **REFACTOR** | **epistemic-store** (A-lattice defeasible priority: lex superior/specialis/posterior) | multi-world typing | `meta-norm-enumeration`: emit the *set* of resolutions each meta-norm ordering yields + UNDECIDED where meta-norms themselves conflict; a single forced resolution ⇒ fails. |
| `source/memory.lisp` (29 defuns, episode stream) | **REFACTOR** (partition per-matter) | **isolation** (episodic memory partitioned at store level) | `isolation` compartments (NEW) | `cross-matter-read`: from a `C_m` session, read `C_n` across every API ⇒ DENY on all, 0 bytes; no shared vector index (each index decrypts under exactly one DEK). |
| `systems/orchestrator-epistemic/meta-ontology.lisp` (Layer-1 epistemic def) | **KEEP** | **epistemic-store** typing / **K-typ** feed | — | `ontology-live-dump`: `deployment/verify/ontology-raw-live-dump.sexp` reproducible; four-valued `{PROVED,REFUTED,UNKNOWN,STABLE}` typing derivable. |
| `source/semantic-versioning-system.lisp`, `consolidation-engine.lisp`, `trace-core.lisp` | **KEEP** | **epistemic-store** versioning core | version-graph refactor | `bitemporal-replay`: valid-time + record-time both queryable; retroactive rule version resolves correctly. |

### E. Gateways → G-inf / G-pub / G-sev (must NOT live in any kernel)

| existing_path | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| `systems/orchestrator-cli/inference-gate.lisp` | **REFACTOR** (per-data-class posture) | **G-inf** | routing table signed; data-class taxonomy | `payload-capture`: on the external wire, 0 PRIVILEGED/WORK-PRODUCT/CLIENT-CONFIDENTIAL bytes, matter labels stripped. `route-audit`: privileged classes have NO external route in the table (structural absence, not a filter). |
| **NEW** `systems/publication-gateway/` (separate R1 pipeline over write-once staging, distinct code paths) | **NEW** | **G-pub** | G-inf; `legal-authority-receipt`; DLP/stego detector (NEW); K-write | `may_publish` monotone conjunction: seed sensitive canaries pre-publication ⇒ BLOCK; red-team stego/paraphrastic exfil, measure miss-rate; ABSTAIN≡FAIL; redaction verified by independent **re-detection of the exact release bytes**, not asserted by redactor; 2 distinct non-self human approvals required or no R4 write-capability minted. |
| **NEW** `systems/self-evolution-ceremony/` (isolated worktree ceremony) | **NEW** | **G-sev** | `deployment/self/history.sexp`; SEV harness; two-R0-token binding | `no-self-merge`: production-TCB write handle is structurally absent from the ceremony process (capability test, not policy); attempt autonomous merge ⇒ impossible, not merely denied. `two-token`: production write requires 2 distinct R0 «εγκρίνω» bound to artifact-hash. |

### F. The 17 `*-gate.lisp` runtime checks → K-precl / K-typ / admission-bus members

| existing_path | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| `systems/orchestrator-cli/inference-gate.lisp` | (→ **G-inf**, row E) | — | — | — |
| `systems/orchestrator-cli/provenance-gate.lisp`, `contract-gate.lisp`, `component-gate.lisp`, `architecture-gate.lisp`, `capability-gate.lisp`, `deontic-gate.lisp`, `event-gate.lisp` | **REFACTOR** (re-seat as typed bus checkers under K-adm) | **K-adm** bus members / **K-typ** stamp inputs | K-adm interface; fail-closed barrier | `gate-fail-closed`: each gate, on internal error/timeout/ambiguity ⇒ REJECT (never ALLOW). Discharge = 0 of 17 gates reachable-ALLOW-on-error (currently the fail-open makes this **0/17 discharged**, see §D.d). |
| `systems/orchestrator-cli/release-gate.lisp`, `evolution-gate.lisp` | **REFACTOR** | **G-sev** admission checks | G-sev ceremony (NEW) | `release-negative`: `authority-v2/proofs/gate-negative-fixtures.py` — every negative fixture ⇒ REJECT. |
| `systems/orchestrator-cli/dialogue-gate.lisp`, `generation-gate.lisp`, `fluid-gate.lisp`, `iq-gate.lisp`, `golden-gate.lisp`, `external-benchmark-gate.lisp`, `verify-truth-gate.lisp` | **REFACTOR or RETIRE** (audit each against "one door per concept"; retire any that duplicate a K-typ/K-prf concept) | **K-typ** / **K-prf** / RETIRE | registry census (`deployment/verify/hash-seat-registry.sexp`) | `seat-uniqueness`: `git log -S` + hash-seat-registry ⇒ no two gates own the same concept; a duplicate ⇒ one is retired with a death-phase record. |
| **NEW** K-precl seat (adjacent to `*-gate.lisp`) | **NEW** | **K-precl** | epistemic-store; safety-game fixpoint producer | `preclusion-cert`: PASS only with (i) frozen rule-set version + world assumptions, (ii) GCC-281 abuse-of-right self-attack, (iii) future-law sensitivity flag, (iv) client-non-self-binding proof; inject tolling/waiver/amendment ⇒ certificate re-opens (not "born won"). |
| **NEW** K-typ seat (co-located `deployment/verify/gate-registry.sexp`) | **NEW** | **K-typ** | `formal-boundaries` stamp; four-valued taxonomy | `no-unstamped-output`: no conclusion crosses to R0/output without `{PROVED\|REFUTED\|UNKNOWN\|STABLE}` × coverage-stamp × `⟦A\|F\|Ev\|Scope⟧`; **A-level never upgrades F-level** (proved deadline arithmetic over unattested legal mapping stays `⟦A4\|F1\|…⟧`). Mode-laundering probe: open-texture question phrased as computational ⇒ mis-tag rate measured. |

### G. Verify / proof-CI harness → the discharge infrastructure (KEEP, wire first)

| existing_path | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| `deployment/verify/` (211 files: `assess-gate-plenary.sh`, `assess-gate-manifest.lisp`, `gate-registry.sexp`, `verify-merkle.py`, `kernel-verify.lisp`, `verify-canonical.py`, `verify-temporal.py`, `verify-release.py`, …) | **KEEP** | **proof-CI** (discharge harness for every row) | — (this is Phase-0 infrastructure) | `ci-comes-up`: `assess-gate-plenary.sh` runs green in owner Docker BEFORE any seat refactor; a red harness blocks all subsequent phases. |
| `authority-v2/proofs/` (`verify-completion-matrix.py`, `verify-proof-manifest.py`, `gate-negative-fixtures.py`, `witness-quorum-test.py`, …) + `authority-v2/run-proofs.sh` | **KEEP** | **proof-CI** / **K-prf** manifest | `deployment/verify/` up | `completion-matrix`: proof-manifest completeness = 100% of *declared* theorems checked; a missing certificate ⇒ matrix red. |
| `scripts/` (`verify-runtime-closure.sh`, `capture-runtime-closure.lisp`, `gen-merkle-truth.lisp`, `merkle-mutation-witness.sh`, `verify-gate-5-validation.lisp`, …) | **KEEP** | **proof-CI** closure | `deployment/verify/` up | `runtime-closure`: `verify-runtime-closure.sh` + `.closure.json` — the runtime dependency set is closed; a leaked dependency ⇒ fail. |
| `scripts/verify-provenance.sh` (referenced by `.github/workflows/provenance.yml:270`) | **NEW** (missing but CI-referenced) | **proof-CI** / **K-src** | provenance verify semantics defined | `provenance-script-exists`: `provenance.yml` tag-path resolves; create the script OR remove the dead reference — CI lints for referenced-but-absent scripts ⇒ 0. |
| `tests/` (`level7-disarm-test.lisp`, `release-authority-test.lisp`, `transparency-log-test.lisp`, …) | **KEEP** | **proof-CI** regression | seats refactored | `regression-suite`: full test tree green in owner Docker per phase. |

### H. New cross-cutting seats (NONE exist on disk → all NEW)

| existing_path | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| **NEW** `source/premise-trust-ledger.lisp` (hash-chained into `journal.lisp`) | **NEW** | **premise-ledger** | `journal.lisp` (K-write) | `manifest-required`: no trusted emission without a resolvable premise-trust manifest {who-confirmed, fidelity artifacts + status, coverage stamp, enumerated unchecked deps}; strip the manifest ⇒ emission blocked. Seed known-wrong formalization ⇒ ratifier catch-rate measured (never "0 wrong claims"). |
| **NEW** `source/formalization-fidelity.lisp` (artifact ships WITH every proof AND the calculus) | **NEW** | **premise-ledger** / **K-prf** §5.2 | premise-ledger; K-prf | `fidelity-artifact`: F0→F3, F3 ceiling; A-level never upgrades F-level; artifact expires on statutory amendment / new CJEU-ECHR-ΑΠ ruling in scope; dual independent back-translation reconciled; N-version formalization cross-diff (disagreement provably reveals a gap). |
| **NEW** `systems/deadline-kernel/` (dual-computed, LLM-off-path, HA independent of reasoning plane) | **NEW** | **deadline-kernel** | independent calendar store; 2 independent implementations | `dual-engine-agree`: two independent implementations MUST agree or BLOCKING incident (earliest date operative pending resolution). `fault-injection`: kill the authority-retrieval path ⇒ deadline alarm STILL fires from the independent calendar. Models ΚΠολΔ 147§7 August suspension, 144§2 holiday rollover, residence-dependent terms, retroactive rule versions. Fail-**loud**: satisfied only by acknowledgement/filing-receipt, never silence. |
| **NEW** `systems/matter-isolation/` (per-matter `DEK_m` compartments, grant broker, PDP/PEP) | **NEW** | **isolation** | crypto compartment substrate; `memory.lisp` partition | `grant-non-transitive`: I-GRANT-NT — grant n→m and m→k do NOT compose to n→k (confused-deputy leak not expressible); constant-time DENY hides object existence; ethical wall = un-minted capability (structurally inexpressible for walled principal). |
| **NEW** `systems/compliance-seat/` (neutral, run by Ethics/Conflicts role, gates the position ledger) | **NEW** | **compliance-seat** (BLOCK-1 resolution) | isolation; position ledger (NEW) | `wall-crossing-redteam`: consistency check over **de-identified commitments** (identifiers + forum/panel exposure, never matter substance); assert no walled content surfaces to a walled principal. `self-estoppel-bait`: alternative/arguendo + fact-distinguished positions NOT falsely flagged as contradiction. Positional conflicts = advisory-BLOCKING (partner decision), never auto-resolved. |
| **NEW** `systems/socket-bay/` + `route-registry.sexp` (R3, identity-blinded from trusted path) | **NEW** | **socket-bay** | seam typing (typed/signed Proposal objects) | `effective-independence`: measure realized pairwise disagreement on a held-out matter-disjoint probe; report **effective-independent-members, not N**; require distinct *foundation families*; an ensemble with effective-count ≈ 1 ⇒ its agreement flagged **non-admissible as confidence** (correlated-failure test, R-3). Privileged work: socket population = on-prem Tier-A only. |
| **NEW** `systems/victory-organs/` (R3 proposer faculties, never on trusted path) | **NEW** | **victory-organs** | seam; procedural-state machine; deadline-kernel | `one-shot-detect`: seed ασφαλιστικά μέτρα / προσωρινή διαταγή / διαταγή πληρωμής scenarios ⇒ detection + escalation, never silent queue-for-next-round. `time-to-relief`: assert time-to-relief scored on EVERY matter plan. `prior-guard`: bench priors may order search / shape presentation, **never prune/decide** (judge-conditioned decision policy = un-absorbable, rejected). Settlement/BATNA: every recommendation surfaces the assumption frontier, never a hidden pick. |
| **NEW** `systems/calibration-spine/` (conformal forecast-verification, orthogonal to deductive Λ) | **NEW** (HYPOTHESIS-status) | second spine (§7) | epistemic-store; held-out outcome set | `coverage-backtest`: reliability diagrams / Brier / log-score over held-out realized outcomes; conformal set coverage ≥ 1−α; thin reference class ⇒ honest UNKNOWN, not a gerrymandered set. **Output NEVER enters deductive labeling Λ.** STATUS: THEOREM for coverage under exchangeability; EMPIRICAL whether legal data is exchangeable; HYPOTHESIS spine is superior. |

### I. Bulk classification of the remaining `source/` (133) + `systems/` (11)

| existing_path group | disp | target_seat | dependency | discharge_test |
|---|---|---|---|---|
| Ingestion/corpus seats (`source/ingestion-daemon.lisp`, `ai-ingest-manifest.lisp`, `ai-corpus-dump.lisp`, `corpus-fingerprint.lisp`, `government-source.lisp`, `source-profile.lisp`, `legal-audit-system.lisp`, `ai-citation-strategy.lisp`) | **KEEP/REFACTOR** | **K-src** ingest + **premise-ledger** feed | K-src recompute path | `ingest-redteam`: forged/amended/repealed sources + edge-case amendment chains ⇒ any that becomes a trusted ref falsifies I-SRC (must be 0). |
| `source/http-server.lisp`, `review-queue.lisp`, `guard-metaeval.lisp` | **KEEP** (R3-side / human-in-loop) | **socket-bay** / R0 review surface | seam typing | `seam-typed`: no raw model string crosses the seam — only typed/signed/provenance-complete Proposal objects; inject a raw string ⇒ rejected at the seam. |
| Remaining `source/*.lisp` not individually named above | **AUDIT → KEEP / REFACTOR / RETIRE** case-by-case against "μία έδρα ανά έννοια" | mapped per concept | registry census | `no-duplicate-seat`: `git log -S<symbol>` + `deployment/verify/hash-seat-registry.sexp` ⇒ each concept has exactly one seat; a second ⇒ RETIRE the weaker with a death-phase record (CLAUDE.md workaround-A/B/C/D discipline). |
| `systems/orchestrator-engine-sbcl/stages/deploy.lisp` ("SINGLE FILESYSTEM TRUTH") + engine stages | **KEEP** | **K-write** deploy / proof-CI | K-write | `deploy-idempotent`: deploy stage is deterministic + idempotent; `output/.healthy` marker present post-deploy (existence only — contents NOT read). |
| `systems/orchestrator-{core,model,spec,meta,gr-syntagma,ai-core,omega-modules,tests}/` | **KEEP** (mostly), audit `omega-modules` for concept overlap | respective target seats | census | `system-load`: all 11 subsystems load clean under the 16 root `*.asd`; a load failure ⇒ blocks phase. |
| `output/`, `output_run1/` | **KEEP** (emit sink) | dependency sink only | K-write, deploy | `sink-position`: paths + dependency-position only; contents deliberately NOT read (brief). |

---

## 2. DRIFT-CORRECTION — fixing the prior canon precisely

### (a) Literal-path vs normalized-record mismatches
1. **`emit-graph` is a `defun`, not a file.** Prior canon lists `emit-graph` as an anchor path. On
   disk it is `source/write-authority.lisp:16 (defun emit-graph …)`, exported by
   `orchestrator.write-authority`, ~9 call-sites. **Correction:** the seat is `write-authority.lisp`;
   `emit-graph` is its exported entry. Any target that resolves `emit-graph` as a path is wrong.
   `[DEMONSTRATED]`
2. **`meta-ontology.lisp` and `inference-gate.lisp` are NOT in `source/`.** They live at
   `systems/orchestrator-epistemic/meta-ontology.lisp` and `systems/orchestrator-cli/inference-gate.lisp`
   respectively. **Correction:** any consumer assuming a `source/` seat is normalized wrong. `[DEMONSTRATED]`
3. **ASDF count.** Prior canon / repo-paths §1 says "23 `orchestrator*.asd`." On-disk this session:
   **16** at root, **17** tree-wide excl. `third-party/`. The "23" is unverified — the mapping uses the
   **11 engine subsystems under `systems/` + 16 root `.asd`** as the load surface. **Correction:** cite
   16/17/11, not 23. `[DEMONSTRATED]`
4. **`legal-authority-receipt.lisp` vs `legal-conflict-resolution.lisp`.** Both exist; the first is a
   receipt-mint seat (→ K-write/G-pub), the second is *norm*-conflict resolution (→ epistemic-store),
   NOT firm-wide matter-conflict. The firm matter-conflicts graph is **NEW** (compliance-seat/isolation).
   `[DEMONSTRATED]`

### (b) Stale / non-existent anchors from the prior canon
1. **`legal-authority-replay` — MISSING.** Zero occurrences anywhere (any extension, any dir). It is a
   plan-level ghost. **Correction:** the real replay seats are `source/authority-evidence-replay.lisp`
   (→ K-prf/K-src) and `source/consolidation-proof.lisp` (→ K-prf). Do NOT create a `legal-authority-
   replay` file; wire the replay target to the two real seats. `[DEMONSTRATED MISSING]`
2. **`scripts/verify-provenance.sh` — MISSING but CI-referenced** (`provenance.yml:270`). **Correction:**
   either create the script with defined provenance-verify semantics (→ proof-CI/K-src, marked NEW in
   the table) or delete the dead workflow reference; add a CI lint for referenced-but-absent scripts.
   Whether this step is on an exercised path in the standard run is `UNKNOWN` (tag-triggered). `[DEMONSTRATED]`
3. **The god-Kernel `K`.** Prior monolithic-Kernel framing embeds ≥15 heterogeneous responsibilities over
   6 trust foundations, and its calculus is an unvalidated construal (`reject-A` #1). **Correction:** there
   is no single `K` seat to KEEP; `K` is **decomposed** into K-adm/K-src/K-prf/K-typ/K-write/K-precl
   behind one typed admission bus + one write seat. A bug in the Horty checker must not fail-open the
   deadline decider. `[DESIGN-ENTAILED]`

### (c) Phase-dependency inversions the prior canon ordered wrong
1. **Gateways before kernel-split — WRONG.** G-pub/G-inf/G-sev cannot be trusted while the admission
   barrier is fail-OPEN; a gateway sitting behind a gate that admits-on-error inherits the bypass.
   **Correction:** R-4 (fail-closed `constitutional-gate`) precedes every gateway. Egress hardening is
   worthless before the admission barrier is closed.
2. **Multi-world epistemic-store before proof-CI — WRONG.** Refactoring the 114-defun `version-graph.lisp`
   to multi-world with no green discharge harness means no test can prove the refactor correct.
   **Correction:** proof-CI (`deployment/verify/` green in owner Docker) comes up BEFORE any seat is
   touched. No transformation is "correct" without a machine-checkable discharge test that can run.
3. **premise-ledger / fidelity-artifact ordering.** K-prf bundle verification depends on the premise-
   ledger + fidelity artifact existing. **Correction:** `premise-trust-ledger.lisp` + `formalization-
   fidelity.lisp` land before `authority-proof-bundle.lisp` is refactored to require them.
4. **isolation before compliance-seat.** The BLOCK-1 compliance-seat reads de-identified commitments
   *across* matters; it is only safe once matter isolation (un-minted-capability walls) exists.
   **Correction:** isolation precedes compliance-seat.

### (d) Proof-workflow bootstrap — the 0/17 theorems + fail-open + CI-first
- **State on disk (`DEMONSTRATED`):** the 17 `systems/orchestrator-cli/*-gate.lisp` are **runtime
  predicates, not certificate-backed theorems** — **0 of the 17 carry a checked proof certificate**, and
  they sit *under* a constitutional barrier that is **fail-OPEN** (`constitutional-gate.lisp:43–47`: a
  crashing predicate ⇒ ALLOW). So the admission story is: 17 gates, 0 discharged as theorems, on a
  barrier that silently admits on any predicate error. This is the R-4 BLOCKER and it **poisons every
  downstream guarantee** — nothing above it can claim "cannot admit a wrong authority."
- **Why CI must come up first.** A "transformation is correct" claim is only meaningful if a
  machine-checkable discharge test can *run and go green*. The `deployment/verify/` harness
  (`assess-gate-plenary.sh`, `verify-*.py`, `kernel-verify.lisp`) + `authority-v2/run-proofs.sh` +
  `authority-v2/proofs/verify-completion-matrix.py` are the discharge substrate. **Bootstrap order:**
  (1) stand up proof-CI green on the *frozen* tree (baseline measurement, expected to show fail-open +
  0/17), (2) close the fail-open (R-4) and prove it with `fail-closed-fuzz`, (3) only then begin
  discharging gates into typed bus-checkers with per-gate `gate-fail-closed` tests. **proof-checking ≠
  formalization correctness:** a green gate proves the *predicate is total and fail-closed*, never that
  the underlying legal formalization is right (that stays F≤F3 EMPIRICAL, R-5).

---

## 3. PHASE-ORDERED BUILD SEQUENCE (each phase gated by a discharge test)

> **NO REPO CHANGE HAPPENS WITHOUT EXPLICIT CREATOR APPROVAL.** Each phase below is a *proposal*
> requiring a per-phase «εγκρίνω X» before a single file is touched. The sequence is a dependency
> order, not a license. Plan → creator «εγκρίνω» → implement → internal adversarial review → full
> proof (gates/tests/audits with numbers) → owner Docker proof → explicit creator merge command.

**Phase 0 — Proof-CI up on the frozen tree (measurement, no seat change).**
Stand up `deployment/verify/assess-gate-plenary.sh` + `authority-v2/run-proofs.sh` green in owner
Docker against the frozen baseline. *Discharge:* `ci-comes-up` green; baseline record shows fail-open
present + 0/17 gates theorem-backed. Gate to Phase 1.

**Phase 1 — Close the fail-open (R-4). THE FIRST CHANGE.**
REFACTOR `source/constitutional-gate.lisp:43–47` so a predicate `error`/timeout/ambiguity ⇒ REJECT.
Re-seat `constitutional-dispatch.lisp` + consumers (`approval-policy.lisp`, `self-reflection.lisp`)
to the fail-closed barrier. *Discharge:* `fail-closed-fuzz` (inject unconditional-`error` predicate ⇒
never ALLOW) + `consumer-conformance`. Nothing downstream proceeds until this is green. Closes R-4 at
the program level.

**Phase 2 — K-adm tiny kernel + typed admission bus.**
REFACTOR `authority-v2/kernel/admission-model.sexp` to `admit → COMMIT|REJECT|UNKNOWN` (total,
decidable, deterministic, fail-closed) dispatching to specialized checkers. *Discharge:* `bypass-fuzz`
(0 orphan COMMITs) + `determinism-replay` (bit-identical across 2 builds) + N-version decider diff.

**Phase 3 — K-write commit seat + K-src recompute + integrity.**
KEEP/guard `journal.lisp`, `self-history.lisp`, `merkle-authority.lisp`; REFACTOR `write-authority.lisp`
(`emit-graph`) behind `validation-authority.lisp`. *Discharge:* `tamper-test` + `orphan-effect` +
`emit-guard` + `merkle-mutation-witness.sh`.

**Phase 4 — premise-ledger + formalization-fidelity, then K-prf split.**
NEW `premise-trust-ledger.lisp`, `formalization-fidelity.lisp`; REFACTOR `proof-carrying.lisp` (split
per proof-system), `authority-proof-bundle.lisp` (require the fidelity artifact). *Discharge:*
`manifest-required` + `fidelity-artifact` + `checker-split` + `completion-matrix`.

**Phase 5 — K-typ coverage-stamp + four-valued enforcer; re-seat the 17 gates.**
NEW K-typ seat co-located with `gate-registry.sexp`; REFACTOR the 17 `*-gate.lisp` into typed bus
checkers, RETIRE any duplicating a concept. *Discharge:* `no-unstamped-output` + per-gate
`gate-fail-closed` (target: 17/17 fail-closed, previously 0/17) + `seat-uniqueness`.

**Phase 6 — epistemic-store multi-world.**
REFACTOR `version-graph.lisp` + `authority-v2/` store + `legal-conflict-resolution.lisp`; add
`multi-world` typing. *Discharge:* `no-silent-collapse` + `consistency-audit` + `meta-norm-enumeration`.

**Phase 7 — isolation, then compliance-seat (BLOCK-1).**
NEW `matter-isolation/` (per-matter DEK, monotone non-transitive grants); REFACTOR `memory.lisp`
partitioned; then NEW `compliance-seat/`. *Discharge:* `cross-matter-read` (0 bytes) +
`grant-non-transitive` + `wall-crossing-redteam` + `self-estoppel-bait`.

**Phase 8 — K-precl + deadline-kernel + victory-organs.**
NEW K-precl seat; NEW dual-computed `deadline-kernel/` (HA, LLM-off-path); NEW `victory-organs/` (R3).
*Discharge:* `preclusion-cert` + `dual-engine-agree` + `fault-injection` (alarm fires with retrieval
killed) + `one-shot-detect` + `time-to-relief`.

**Phase 9 — Gateways: G-inf, then G-pub, then G-sev.**
REFACTOR `inference-gate.lisp` (per-data-class); NEW `publication-gateway/` (separate code paths);
NEW `self-evolution-ceremony/`. Fix `scripts/verify-provenance.sh` (create-or-delete-reference).
*Discharge:* `payload-capture` + `route-audit` + `may_publish` monotone-conjunction canary/stego
red-team + `no-self-merge` (capability test) + `two-token`.

**Phase 10 — socket-bay + calibration spine (HYPOTHESIS-status, quarantined from Λ).**
NEW `socket-bay/` + `route-registry.sexp`; NEW `calibration-spine/`. *Discharge:*
`effective-independence` (effective-count, correlated-failure test) + `coverage-backtest`. Calibration
output must not enter deductive labeling.

**Residual BLOCKING carried the whole way (never wordsmithed away):** R-1 novel-at-speed (un-absorbable),
R-2 honesty-tax/advocacy-register (EMPIRICAL/UNKNOWN), R-3 shared-population blind spot, R-5
verifier-calculus F≤F3 (contained by K-prf split + calculus-fidelity, **not closed**), R-6
e-filing-only deadline hole (narrowed), R-7 AI-Act Art.12 vs GDPR vs privilege (retention-policy level),
R-8 "convergence ≠ evidence," R-9 DLP-classifier-in-TCB. R-4 is the only BLOCKING residual this build
*closes*; the rest are contained-and-disclosed or structurally open.
