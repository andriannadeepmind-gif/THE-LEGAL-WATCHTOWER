<!-- COORDINATOR ROADMAP — Phases 2..6. External coordinator material; lives OUTSIDE the Andrianna repo. -->

> ## Αντιπαλική επιθεώρηση — ΚΛΕΙΣΤΑ ΕΥΡΗΜΑΤΑ (authoritative corrections, υπερισχύουν κάθε αντικρουόμενου κατωτέρω)
>
> Ανεξάρτητοι αντίπαλοι κριτές (LAWMAX) επιθεώρησαν το roadmap. Δύο πραγματικά ευρήματα κλείνουν εδώ· ο honesty-lens κριτής βρήκε **NONE** (καμία υπερβεβαίωση· το `FINAL_OPTIMALITY_BLOCKED` παραμένει η προεπιλογή).
>
> **[C1 — role-separation / result-blind leak]** Ο **P3 dominance-judge ΔΕΝ συντάσσει** το `FOC-15` pre-Phase-3 freeze που μετά κρίνει υπό αυτό. Το `FOC-15` (πάγωμα domain grammar/envelope, objective order/bins, material-equivalence, hard-invariant registry, evaluator inputs, TCB, named-product versions, 22-axis lattices, result-blind calibration) **παγώνεται & hash-άρεται από ξεχωριστό ρόλο (coordinator/independent) ΠΡΙΝ** αρχίσει οποιαδήποτε P3 κατασκευή/κρίση υποψηφίου. Ο judge εφαρμόζει μόνο το ήδη-παγωμένο.
>
> **[C2 — FOC-04 / T2 domain non-vacuity, «winner-only hole»]** Πριν από κάθε greatest-element ισχυρισμό (FOC-08→T2) απαιτείται ρητά: **μη-κενό ανεξάρτητο U_T**, ακριβής quotient-image **D_T**, αμφίδρομη διατήρηση feasibility/objectives/traces, και dated open-world frontier certificate. **Απαγορεύονται** `D_T={winner}`, winner-only U_T και post-hoc U_T (negative controls NC-14/NC-24). Αυτό είναι προϋπόθεση, όχι βήμα του P5.
>
> ---

# COORDINATOR EXECUTION ROADMAP — THE LEGAL WATCHTOWER
### Running Phases 2 → 6 in separate fresh sessions to the final ceiling
*Process/gate roadmap only. No legal-tech architecture answer is asserted anywhere below; the architecture is produced blind in P2 and proved in P5/P6. Every positive claim is CONDITIONAL on its proof object verifying, and is fail-closed by default.*

---

## 0. Κατάσταση & ο ένας κανόνας που κυβερνά τα πάντα (Honest status + governing rule)

**CURRENT STATUS — one line:** `FINAL_OPTIMALITY_BLOCKED` — nothing is discharged; all 19 formal obligations (FOC-01..FOC-19) and all 7 theorems (T1..T7) are in state `BLOCKED`; derived from P1=`ACCEPTED`, P2=`FRESH_RERUN_PREPARED_NOT_LAUNCHED`, P3=`UNAUTHORIZED`, FINAL_PROOF=`NOT_YET_PRODUCED`, COMMERCIAL_SUPERIORITY=`NOT_YET_PROVED`, B0_TRANSFORMATION=`NOT_YET_PLANNED`.

**THE ONE FAIL-CLOSED RULE (FOC-16 termination_policy):** `UNIVERSAL_PROOF_ONLY`. Success is declared **only** by a mechanically checked *greatest-element* proof over the sealed present-day domain plus every downstream theorem — **never** by the strongest candidate found. No number of rounds, candidates, reviewers, tokens, time, compute, or failed attack attempts authorizes success. Any of `{missing, extra, null, unknown, warning, skip, timeout, unexecuted obligation, verifier disagreement}` forces `BLOCKED`. `UNKNOWN` never becomes equality or dominance. This rule outranks every convenience below it.

**Fixed identities (do not drift):**
- **B0** = `github.com/andriannadeepmind-gif/THE-LEGAL-WATCHTOWER.git`, branch `main`, commit `e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03`, tree `23b7a6f4450f50d151d38e13020bee9872e73bcd`, leaf_count 35640. This is the mandatory lower bound of comparison (not RAG, not replaceable by a Phase-1 summary or abstract comparator).
- **P1 binding** = `PHASE-1-DELIVERABLES.zip` (byte_length 1170654, sha256 `3E927EBA2E90410C47FC955C0B6F704F054630DE141F275CF89A4AB31EAB3E93`, tracked_path_count 35640), state `ACCEPTED` — holds **only** while this hash verifies AND its internal source_commit/source_tree equal B0.
- **Contract** v2.3.0-R3-PRE-PHASE-2-FROZEN-CANDIDATE is `authoritative=false` / CANDIDATE ONLY. It may not be declared final and is not phase authority.

---

## 1. Ο σκελετός των φάσεων (Phase spine — distinct fresh sessions, R8/R9)

**Session law (R8/R9):** producer, reviewer, judge, synthesizer, red team and each replicator run in **distinct sessions**. A fork, resume, branch, or inherited subagent is **not** an independent role and must fail role separation (NC-02). No actor accepts its own artifact (R9). The coordinator (R1) may provision environments, route sealed artifacts, and approve immutable hashes — but may **never** supply an architecture answer to the producer, nor rewrite frozen gates after output.

| Phase | Role (session) | Governing freeze/gate slotted at its boundary |
|---|---|---|
| **P2** | `FRESH_PHASE_2_PRODUCER` (R2) + `PHASE_2_INDEPENDENT_REVIEWER` (R3) | — designs the FOC-18/T6 66-cell plan; proves nothing |
| P2→P3 | coordinator reveals B0 after producer stops + submission hash fixed | **FOC-15** freeze at P3 entry |
| **P3** | `PHASE_3_DOMINANCE_JUDGE` (R4) | **FOC-15** complete → **FOC-16** `UNIVERSAL_PROOF_ONLY` activated |
| **P4** | `PHASE_4_SYNTHESIZER` (R5) | **FOC-19** post-B0-reveal delta plan (creator-approved before any write) |
| **P5** | `PHASE_5_RED_TEAM` (R6) | **FOC-16** escalation loop; **FOC-18/T6** discharge attempt |
| **P6** | `PHASE_6_REPLICATOR_A` and `PHASE_6_REPLICATOR_B` (R7, two operators) | **T1–T7 + FOC-12** independent replay; **T5** terminal ceiling |
| deployed | continual | **FOC-17** ratchet (reopens the ceiling) |

---

## 2. Ανά φάση (Per-phase execution) — P2 → P3 → P4 → P5 → P6

### P2 — Fresh blind producer + independent reviewer
- **ROLE:** `FRESH_PHASE_2_PRODUCER` (R2) in a *genuinely fresh* session; then, after termination, a **separate** `PHASE_2_INDEPENDENT_REVIEWER` (R3) session. No fork/resume/inherited subagent (NC-02).
- **INPUTS:** exactly the sealed `PHASE-2-BLIND-PRODUCER-INPUT.zip` (its `START-FRESH-PHASE-2.md`) + permitted public primary sources + producer-created output files. **Forbidden inputs** (NC-01/03/04, IP4): B0 and any mirror/checkout/git object; Phase-1 artifacts; all prior Phase-2 outputs/reviews/checkers; the reviewer capsule or any hidden reviewer implementation; prior memory/session summaries/connected stores/code-search; any architecture answer from creator or another model.
- **ENVIRONMENT / ISOLATION:** a baseline-connected project is **ineligible** (`eligible_to_run_blind_phase_2=false`; conversation freshness ≠ input isolation). Provision via **Route 1** NEW_UPLOAD_ONLY_CLOUD_WORKSPACE (preferred), else **Route 2** NEW_STERILE_STUDY_REPOSITORY (new root commit, no fork/mirror/import/submodule/remote to baseline), else **Route 3** LOCAL_BARE_ISOLATED_SANDBOX (fresh `CLAUDE_CONFIG_DIR`, bare mode, no host hooks/plugins/memory/CLAUDE.md). **Preflight (LP6)** must pass before spend; **first-action gate (IP7)** writes `PHASE-2-ENVIRONMENT-ATTESTATION.json` + `PHASE-2-ACCESS-LEDGER.jsonl` before any research. Immediate stop → `PRELAUNCH_ISOLATION_BLOCKED` (reprovision once).
- **WORK:** blindly produce the strongest frontier architecture + an answer-neutral architecture-family grammar seed, open assumptions, defeaters; independently inventory the three named commercial baselines; design the complete **66-cell** (3×22) all-axis challenge plan and the mechanism-only evaluation plan; emit the 23 required output artifacts incl. `PHASE-2-IMPLEMENTATION-ABSTRACTION-MAP.json` (post-reveal B0 mapping **seed** — no B0 path/symbol may be invented). Deliver **one sealed submission ZIP** (single top-level dir `phase-2-fresh-epoch-1/`, transport-only). **P2 proves nothing** — it may not mark FOC-18/T6 proved and may not begin Phase 3.
- **ACCEPTANCE vs BLOCKER:**
  - Producer may emit **only** `PHASE_2_CANDIDATE_READY_FOR_INDEPENDENT_REVIEW` **or** `PHASE_2_BLOCKED`. Forbidden producer statuses: `PHASE_2_COMPLETE`, `PHASE_2_ACCEPTED`, `FRONTIER_VERIFIED`, `GLOBAL_OPTIMUM_PROVED`, `PHASE_3_AUTHORIZED` (NC-05).
  - Commercial status permitted in P2 is **only** `COMMERCIAL_SUPERIORITY_NOT_YET_PROVED`; forbidden: `STRICT_ALL_AXIS_COMMERCIAL_SUPERIORITY_VERIFIED`, `FOC_18_DISCHARGED`, `T6_PROVED`.
  - Reviewer first-review verdict is **only** `PHASE_2_CANDIDATE_ACCEPTED_FOR_PROOF_PIPELINE` (runbook/acceptance-spec token) — issued equivalently as `PHASE_2_ACCEPTED_FRESH_BLIND_EPOCH` in ROLE-SEPARATION.json; **both tokens appear verbatim across the frozen files and are preserved as-is** — **or** `PHASE_2_BLOCKED` (with exact failed gates). Reviewer must confirm: all 3 products present separately, every observable capability mapped, matrix is **exactly 66 cells**, and no content-quantity/average/weight/compensation/equality/UNKNOWN used as superiority (RB4).
  - **Blindness label** (`BLINDNESS_VERIFIED` / `BLINDNESS_FAILED` / `BLINDNESS_UNVERIFIED`) is reported **separately** and can neither establish nor refute the final theorem; a logging gap never forces a Phase-2 rerun.
- **CREATOR-APPROVAL gate to leave P2:** Phase-2 acceptance is **not** a ceiling proof. Leaving P2 for P3 requires **independent contract review AND explicit creator approval** (P3=`UNAUTHORIZED` until then). Separately, before P2 even launched, the creator signs the hash-bound receipt over the immutable outer/blind/reviewer hashes (see §8).

### P3 — Domain freeze + adversarial judging
- **ROLE:** `PHASE_3_DOMINANCE_JUDGE` (R4), distinct session. May compare and generate challengers under the frozen order; **may not** change FOC-15/FOC-16 policy or certify the final ceiling.
- **INPUTS:** the accepted blind Phase-2 candidate, the **revealed B0** and Phase 1, and the FOC-15 freeze objects.
- **ENVIRONMENT / ISOLATION:** B0 becomes visible **only after** the producer has stopped and its submission archive hash is fixed. Any deviation changes the blindness label, not the theorem.
- **WORK:** execute **FOC-15** first (see §3), then run adversarial dominance judging under the frozen objective order (`ge_T`: top-tier-where-vectors-differ; mixed ⇒ `INCOMPARABLE`; equal vectors ⇒ trace-refinement). Record `UNKNOWN` honestly.
- **ACCEPTANCE vs BLOCKER:** acceptance = FOC-15 freeze instantiated **and hashed** before any candidate comparison, then judging under frozen order. **BLOCKER:** any Phase-3 candidate construction/evaluation before authorization, or any comparison before the freeze/hash is complete (NC-23; FOC-15 negative control). No positive final token is emitted in P3.
- **CREATOR-APPROVAL gate:** entry to P3 is the creator-approval point (from P2). No further creator approval is consumed to move P3→P4, but FOC-19's write gate is armed the moment B0 is revealed.

### P4 — B0 census + exact repository crosswalk + approved transformation plan
- **ROLE:** `PHASE_4_SYNTHESIZER` (R5), distinct session. Constructs the strongest incumbent as an **approved transformation of the Andrianna repository**; reopens affected obligations; **may not** prune without a certificate or declare finality.
- **INPUTS:** Phase-3 evidence and admitted contenders; the revealed B0; `B0-TRANSFORMATION-AND-REPOSITORY-DELTA-SPEC.json`.
- **ENVIRONMENT / ISOLATION:** study runs **outside** the repository until approval; implementation later occurs in a **dedicated Andrianna branch/worktree**; **no study ZIP or supervisory report is ever committed**; `baseline_repository_writes = 0` until the gate opens.
- **WORK (FOC-19, see §5):** exhaustive 10-surface semantic census; total bidirectional architecture-to-path/package/symbol/store/gate crosswalk; the exact `ADD/MODIFY/REFACTOR/MOVE/REPLACE/REMOVE` changeset (16 mandatory fields per record); capability-preservation matrix; migration DAG; verification matrix; removal proofs; final implementation manifest — the 9 post-reveal artifacts. Every increment is a **verified vertical increment of the final architecture** (no deliberately inferior interim).
- **ACCEPTANCE vs BLOCKER:** acceptance = complete immutable plan produced, hashed, and **independently reviewed**, with total (orphan-free) bidirectional crosswalk and exactly one census identity+disposition per surface. **BLOCKER:** one unexplained B0 surface; any `UNKNOWN` disposition authorizing a change; a disconnected greenfield / parallel authority / second source of truth; any repository write before the approved plan (NC-44, `B0_TRANSFORMATION_BLOCKED`).
- **CREATOR-APPROVAL gate to leave P4 into implementation:** `repository_writes_before_creator_approval = 0` — **creator must approve the immutable, hashed, independently-reviewed delta plan** before a single write to the Andrianna repo. Realization must later match the approved manifest.

### P5 — Counterexample-guided universal escalation
- **ROLE:** `PHASE_5_RED_TEAM` (R6), distinct session. Escalates across every canonical class and attack operator; **may not** stop successfully on a fixed cap, upgrade `UNKNOWN`, or ignore an incomparable challenger.
- **INPUTS:** the frozen domain and all incumbents; FOC-16 `UNIVERSAL-ESCALATION-PROTOCOL.json`.
- **ENVIRONMENT / ISOLATION:** **no round/time/compute/token/candidate/consensus cap may authorize success** (unbounded search until the proofs close). Repeated canonical states prove only a cycled branch, never success.
- **WORK:** run the counterexample loop applying all 17 mandatory attack operators across every uncovered grammar class; admit each valid challenger into the canonical class registry; reopen every affected obligation; close each unbounded family only via a mechanically checked parametric upper-bound proof; discharge domain closure by complete finite enumeration **or** exhaustive symbolic partition with proved per-class upper bounds. Discharge **FOC-18/T6** here (§4).
- **ACCEPTANCE vs BLOCKER:** acceptance = class coverage **and** per-class upper-bound proofs jointly close, all hard invariants proved, greatest-element + uniqueness established, zero live material defeaters. **BLOCKER:** any grammar class uncovered, an incomparable maximum (T3 fails), a symbolic family bound unproved, or inability to close ⇒ `FINAL_OPTIMALITY_BLOCKED`; any commercial cell not `STRICTLY_BETTER` ⇒ `COMMERCIAL_SUPERIORITY_BLOCKED`.
- **CREATOR-APPROVAL gate:** none newly consumed; P5 operates under the P4-approved plan and the FOC-15 freeze.

### P6 — Independent reconstruction + mechanical verification (terminal)
- **ROLE:** `PHASE_6_REPLICATOR_A` and `PHASE_6_REPLICATOR_B` (R7) — **two distinct operators** in **two distinct attested clean-room environments**; must not share working state before both commit results (FOC-12; NC-20).
- **INPUTS:** the sealed proof inputs required for clean-room reproduction; the hashed TCB and actual build.
- **ENVIRONMENT / ISOLATION:** two independent clean-room reproductions in distinct, non-shared attested environments; a single-environment repeat labeled replication must fail (NC-20).
- **WORK:** independently reconstruct, replay and mechanically verify **domain/quotient closure, all hard invariants, universal B0 refinement (T1), greatest-element (T2), uniqueness up to material equivalence (T3), architecture→source→executable refinement (T4), strict all-axis commercial superiority (T6), the exact B0→E_star transformation (T7)**, hash-bound actual-build + TCB instantiation (FOC-14), and zero live defeaters — then the terminal **T5** conditional ceiling.
- **ACCEPTANCE vs BLOCKER:** acceptance = all 13 success-gate conditions hold simultaneously and both reproductions agree ⇒ emit `FINAL_B0_SUCCESSOR_GREATEST_ELEMENT_AND_STRICT_ALL_AXIS_COMMERCIAL_SUPERIORITY_VERIFIED_UNDER_HASHED_TCB`. **BLOCKER:** any single condition unmet, an incomparable maximum, executable refinement failure, or reproduction disagreement ⇒ `FINAL_OPTIMALITY_BLOCKED` (preserve the strongest valid design).
- **CREATOR-APPROVAL gate:** the permitted final status is available only after FOC-01..FOC-19 and T1..T7 are actually discharged **and independently reproduced** — discharge alone is insufficient.

---

## 3. Πού κουμπώνουν FOC-15..FOC-19 (Where the freeze/escalation objects slot)

- **FOC-15 (Pre-Phase-3 freeze) — slots at the P2→P3 boundary, at the *start* of P3, strictly before any candidate construction/evaluation.** Freeze **and hash**: domain grammar/envelope (the U_T/D_T definition), objective order + bins, material-equivalence rule, hard-invariant registry, evaluator inputs, TCB, exact named-product versions, observable capability census, the 22-axis evidence lattices, and the result-blind calibration procedure. Scope note: policy/field schemas were frozen before P2; these concrete objects are *instantiated and hash-frozen after* accepted blind P2 but *before* any P3 comparison — populating predeclared fields is not a policy change. **Negative control:** any candidate compared before the freeze hash exists must fail (NC-23).
- **FOC-16 (Universal escalation) — activated immediately after FOC-15, governs P5.** Sets `RED_TEAM_TERMINATION = UNIVERSAL_PROOF_ONLY`. Success-termination is allowed **only after** domain closure + greatest-element + uniqueness + executable-refinement obligations close; every fixed search cap is forbidden from authorizing success (NC-13, NC-21).
- **FOC-18 / T6 (Commercial superiority) — designed in P2, judged across P3–P5, discharged+reproduced in P5–P6.** See §4.
- **FOC-19 / T7 (B0 transformation) — slots into P4 (plan) and P6 (T7 replay), gated by creator approval before any write.** See §5.
- **FOC-17 (Continual evolution) — slots *after* the certified ceiling, at deployment, and runs indefinitely.** See §6.
- Dependency spine to the ceiling: **T5** (terminal) requires hashed TCB + actual build + **T1..T4 + T6 + T7** + independent replay (**FOC-12**) + provenance (**FOC-14**). Reaching the final ceiling status **= discharging T5**, and only conditionally.

---

## 4. Το εμπορικό κατώφλι (Commercial-superiority gate, FOC-18 / T6)

**The matrix:** exactly **3 mandatory named baselines × 22 binding axes = 66 cells**, each of which must reach verdict **`STRICTLY_BETTER`** — `all_66_cells_must_pass = true`, `only_passing_cell_verdict = STRICTLY_BETTER`, `every_product_every_axis = true`.

**The three baselines (sealed set `COMMERCIAL-FRONTIER-BASELINES.json`), each compared SEPARATELY — never as a composite:**
1. `B-COMM-01-THOMSON-REUTERS-COCOUNSEL-LEGAL` — **CoCounsel Legal** (incl. Westlaw / Practical Law grounding)
2. `B-COMM-02-LEXISNEXIS-LEXIS-PLUS-WITH-PROTEGE` — **Lexis+ with Protégé**
3. `B-COMM-03-HARVEY` — **Harvey**

**The 22 binding axes (`ALL-AXIS-DOMINANCE-SPEC.json`, AX-01..AX-22):** legal-reasoning correctness & defeater sensitivity; multi-step decomposition & plan completeness; agent coordination/parallelism/arbitration; source-selection & grounding independent of corpus size; citation & authority validation; evidence provenance & transformation-lineage; matter/institutional & reflective memory; temporal & legal-state consistency; contradiction/uncertainty/blind-spot handling; self-falsification/counter-design/escalation; workflow & tool orchestration w/ transaction semantics; institutional decision authority & accountable state transition; auditability/provenance-complete replay; determinism under frozen inputs; durability/crash consistency/bounded recovery; progress & liveness; latency; throughput/scale/resource-normalized perf; introspection/inspectable causal account; evolvability w/ monotonic preservation; formal assurance & architecture→source→executable transport; mechanism generality across legal orders without content-specific redesign. Fixed evidence modes: AX-12 & AX-21 logical-only; AX-17 & AX-18 quantitative-only; all others logical+quantitative.

**Additional binding requirement — proper capability superset:** for each baseline `b`, `Capabilities(b)` is a **proper subset** of `Capabilities(E_star)`, under universal trace/capability refinement, each mapped capability materially improved (not merely copied), plus ≥1 additional material capability. Grounding/validation mechanisms count; content quantity does not (NC-36).

**Three required evidence tracks (all mandatory; marketing/benchmarks alone cannot prove T6):** `MECHANISM_NORMALIZED`, `ACTUAL_PRODUCT_BLACK_BOX`, `ARCHITECTURE_CLASS_PROOF`.

**FORBIDDEN superiority substitutes — each blocks the cell and the theorem:**
- **Equality** on any axis / overlapping uncertainty interval (NC-30);
- **Averaging** (unweighted, geometric, composite) (NC-28);
- **Weighting** / scalar / overall / LLM score (NC-28);
- **Compensation / trade-off** — a loss on one axis offset by a gain on another (NC-31);
- **Better-on-one/some axes** with equality on the rest (NC-29);
- **Content advantage** — proprietary corpus size/exclusivity, jurisdiction count, brand, adoption, price counted as mechanism superiority (NC-34, `content_quantity_excluded`);
- **UNKNOWN / inaccessible / unlicensed / non-comparable / unmapped / content-confounded** evidence upgraded to pass (NC-32, `unknown_as_pass_forbidden`);
- **Absolute-ceiling equality renamed superiority** — if any baseline already occupies a proved absolute ceiling on a binding axis, strict improvement is impossible and the claim stays `COMMERCIAL_SUPERIORITY_BLOCKED`.

Success token: `STRICT_ALL_AXIS_COMMERCIAL_SUPERIORITY_VERIFIED` (equivalently T6 discharged). Failure token: `COMMERCIAL_SUPERIORITY_BLOCKED`. Any unmapped material commercial mechanism property ⇒ `AXIS_DOMAIN_OPEN`, forcing a new axis epoch and full replay.

---

## 5. Το κατώφλι μετασχηματισμού B0 (B0 transformation gate, FOC-19 / T7)

**The obligation:** E_star must be the **verified evolutionary successor implemented inside the Andrianna B0 repository** via a finite, **creator-approved**, exact change sequence `Delta_B0` with `Apply(B0, Delta_B0) = E_star`, every increment preserving all still-binding B0 capabilities/invariants, and the final source/build/executable instantiating the proved `A_star`/`E_star`.

**Why a greenfield / parallel system fails (structurally, not by preference):** the target rule forbids a disconnected greenfield, adjacent replacement, facade, wrapper-only substitute, second authority, or duplicate subsystem (NC-39). Anti-duplication rules (all forbidden): parallel authority, second source of truth, hidden fallback, wrapper-only substitution, unbounded compatibility shim, abandoned old path (NC-42). A separate implementation cannot map back to B0's surface, so it leaves unexplained B0 surface and duplicate authority — both hard blockers — and it cannot satisfy the bidirectional crosswalk totality below.

**Post-reveal repository-delta obligations (9 mandatory artifacts):** `B0-SEMANTIC-REPOSITORY-CENSUS.jsonl`, `B0-TO-E-STAR-CAPABILITY-PRESERVATION-MATRIX.json`, `B0-TO-E-STAR-ARCHITECTURE-CROSSWALK.jsonl`, `B0-TO-E-STAR-CHANGESET-PLAN.jsonl`, `B0-TO-E-STAR-REFACTOR-PLAN.md`, `B0-TO-E-STAR-MIGRATION-DAG.json`, `B0-TO-E-STAR-VERIFICATION-MATRIX.json`, `B0-TO-E-STAR-REMOVAL-PROOFS.jsonl`, `B0-TO-E-STAR-FINAL-IMPLEMENTATION-MANIFEST.json`.

- **Census closure (10 surfaces):** tracked files & generated boundaries; ASDF systems/components/load order; packages & exported/internal protocols; definitions/callers/writers/readers; authority & state-transition points; durable stores/schemas/migrations/recovery; concurrency ownership & scheduling; deployment/operational/integration paths; tests/proof gates/fixtures/toolchain assumptions; existing capabilities/invariants/theorem debts. **Rule:** each in-scope surface has exactly **one** stable census identity+disposition; one unexplained surface blocks FOC-19; `UNKNOWN` never authorizes a change or a preservation claim.
- **Crosswalk totality:** every Phase-2 mechanism maps to ≥1 exact B0 change **or** a proof B0 already implements a strictly sufficient form; every planned change maps back to a frozen architecture/preservation/commercial-axis/proof obligation. Orphans in **either** direction block (NC-40).
- **16 mandatory changeset fields** per record; **6 change_kinds** each with its proof burden: `ADD` (no orphan/speculative subsystem), `MODIFY` (complete caller/consumer impact + preservation evidence), `REFACTOR` (differential/bisimulation evidence over the complete affected surface), `MOVE` (no dual authority/split state), `REPLACE` (universal capability/trace refinement + migration closure before superseding), `REMOVE` (exhaustive caller/consumer/store/deployment proof of redundancy/completed migration/stronger replacement) (NC-41, NC-43).
- **Preservation rule:** every reachable B0 capability, invariant, trace, public protocol, durable-state meaning, recovery property, deployment path and verification gate is preserved **or** migrated to a strictly stronger verified form; no loss may be excused as refactoring.
- **Migration DAG:** acyclic, dependency-complete, verified vertical increments only — each declaring pre-state, post-state, preserved properties, recovery behavior, evidence; a deliberately inferior interim architecture is forbidden.

**Write gate & tokens:** `repository_writes_before_creator_approval = 0`. Implementation proceeds only in a dedicated Andrianna branch/worktree after **creator approval of the immutable plan** (NC-44). Success token `B0_TRANSFORMATION_TO_E_STAR_VERIFIED` (T7 discharged) requires source+build+executable to be the **exact proved E_star** with no parallel authority or unlisted change; otherwise `B0_TRANSFORMATION_BLOCKED`.

---

## 6. Ο κρίκος συνεχούς εξέλιξης (FOC-17 continual-evolution ratchet)

After a certified ceiling, the claim is **not timeless**. The epoch invariant holds at every certified epoch t: for all x in F_t, `Omega_t >=_t x`. What **re-opens the ceiling into `CEILING_REVALIDATION_REQUIRED`** (any one validated trigger):
- any newly constructible architecture class or mechanism;
- any validated challenger claiming material superiority;
- **any validated update to CoCounsel Legal, Lexis+ with Protégé, or Harvey** (reopens FOC-18/T6);
- a changed primary-source frontier fact, a new reachable baseline capability or workload;
- a changed objective / invariant / equivalence rule / evaluator input / TCB assumption;
- a counterexample to any active proof or abstraction relation.

**Monotonic ratchet:** a successor `Omega_(t+1)` is admissible **only if** it preserves every still-binding invariant and reachable capability of `Omega_t` and is no worse on every binding objective. A regressive successor must fail (NC-26). **Restoration** to current-ceiling (`CERTIFIED_CEILING_AT_EPOCH_t_plus_1`) occurs **only after** greatest-element + uniqueness + executable-refinement obligations replay **and** independent reproduction pass for the new epoch. A stale certificate left current after a validated trigger must fail (NC-25, `stale_certificate_forbidden`); otherwise preserve the strongest valid executable and report `CEILING_REVALIDATION_REQUIRED` / `FINAL_OPTIMALITY_BLOCKED` — never retain a stale supremacy claim. No epoch quantifies over unknown future technology; the guarantee is renewed per closed, timestamped present-day epoch (cutoff 2026-08-27).

---

## 7. Τι σημαίνει «DONE» (DONE means)

**DONE = exactly one permitted positive token:**

> `FINAL_B0_SUCCESSOR_GREATEST_ELEMENT_AND_STRICT_ALL_AXIS_COMMERCIAL_SUPERIORITY_VERIFIED_UNDER_HASHED_TCB`

It is emitted **only** when the terminal theorem **T5** is discharged — i.e. hashed jointly-satisfiable TCB + actual build + **T1..T4 + T6 + T7** + zero live defeaters + **two independent clean-room reproductions (FOC-12)** + provenance (FOC-14), all 13 success-gate conditions holding simultaneously. Reaching it is **CONDITIONAL on every proof object verifying and being independently reproduced** — it is **never assumed, defaulted, or inferred from effort**.

**Otherwise (fail-closed, always):** `FINAL_OPTIMALITY_BLOCKED` — with `COMMERCIAL_SUPERIORITY_BLOCKED` and `B0_TRANSFORMATION_BLOCKED` as the component fail-closed statuses, and non-final evidence statuses `ARCHITECTURE_ONLY_EVIDENCE` / `SCOPED_NONDOMINANCE_EVIDENCED` where applicable. **Forbidden verdicts** (must never be emitted): "best effort", "state of the art without theorem", "likely optimal", "no better solution found", "all agents agreed", "better overall/on average/on some axes", "equal but acceptable", "trade-off accepted". Today's honest verdict remains `FINAL_OPTIMALITY_BLOCKED`.

---

## 8. Τι κάνει φυσικά ο συντονιστής ανάμεσα στις sessions (Coordinator between-sessions checklist)

Performed by `CREATOR_COORDINATOR` (R1) — may provision, route, and approve hashes; may **never** supply an answer or rewrite frozen gates after output.

1. **Verify the freeze before launch.** Verify the outer freeze bundle and **both** inner capsule hashes; run `verify_freeze.py` and `verify_freeze.mjs` inside the reviewer capsule — **both must exit 0 and print `FREEZE_STRUCTURE_VALID`** (they check structure only; they are *not* proof verifiers). Disagreement ⇒ `BLOCKED`.
2. **Obtain the hash-bound creator approval receipt** (trust root, state `PENDING_CREATOR_APPROVAL`, external to the freeze — approval changes **no** package byte). Five required fields: `freeze_bundle_sha256`, `blind_capsule_sha256`, `reviewer_capsule_sha256`, `approval_text`, `timestamp_utc`.
3. **Provision a clean, eligible environment** (Route 1 → 2 → 3), run the LP6 preflight; a baseline-connected project is ineligible. **Upload only** `PHASE-2-BLIND-PRODUCER-INPUT.zip`.
4. **Quarantine the reviewer capsule.** Never upload, mention, hash-expose, or let the producer see the reviewer capsule, B0 identity, Phase 1, or prior Phase-2 work — producer sees only the reviewer-capsule *commitment* (cryptographic capsule separation; NC-04).
5. **On producer termination, record submission bytes first.** Record the producer ZIP's **byte length and SHA-256 before opening it**; preserve the complete Code session and tool transcript; **do not resume the producer** for remediation.
6. **Open a distinct reviewer session** with the immutable reviewer capsule, the frozen producer ZIP, and the retained transcript; apply only the **pre-frozen** answer-neutral gates + negative controls (checker-epoch rule: editing a checker after seeing output opens a new preserved epoch and cannot retroactively certify; NC-12).
7. **Reveal B0 only after** the producer has stopped and its submission archive hash is fixed — this is the P2→P3 boundary that arms FOC-15 and FOC-19.
8. **Route each phase to its own distinct session** (judge, synthesizer, red team, two replicators) — never a fork/resume/inherited subagent; no actor accepts its own artifact.
9. **Gate every creator-approval point:** (a) immutable freeze hashes before P2 launch; (b) explicit creator approval + independent contract review before P3; (c) creator approval of the immutable B0→E_star delta plan before **any** repository write (`repository_writes_before_creator_approval = 0`); (d) require independent reproduction in addition to discharge before the final token.
10. **Keep the whole pipeline fail-closed.** Treat any `{missing, extra, null, unknown, warning, skip, timeout, unexecuted, verifier-disagreement}` as `BLOCKED`; never pre-count a frozen-but-unexecuted control as a pass; never upgrade `UNKNOWN`. Until T5 verifies and reproduces, the status stays `FINAL_OPTIMALITY_BLOCKED`.