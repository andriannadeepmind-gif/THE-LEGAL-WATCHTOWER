# BASE AUDIT — LAYER 5: PROOF/VERIFY HARNESS + BUILD ARCHITECTURE

**Stance:** adversarial, uncharitable. Existing seats read for real (Glob/Grep/Read), not trusted because they exist.
**Method:** every verifier read line-by-line; every "proof" traced to what it actually machine-checks; every "test" checked for tautology (asserts-what-code-does) vs. real falsifier.
**Claim-status tags per statement:** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN.
**Load-bearing distinction enforced throughout:** *exists-and-runs* ≠ *correct* ≠ *top*. proof-checking ≠ formalization correctness.

---

## 0. ONE-PARAGRAPH VERDICT

The harness is **two disjoint machines wearing one name**. Machine A (the cryptographic/serialization plumbing verifiers: Merkle, canonical serialization, temporal date-arithmetic, release-census integrity, CI false-green killers) is **genuinely real, N-version, mutation-adequate machine-checkable verification** — the strongest engineering in the repo and legitimately above the commercial floor. Machine B (everything that carries the *mission's* trust claims: the admission kernel, the 9 authorization theorems, all 17 formal theorems, the witness-quorum policy) is **0/17 discharged, specification-only prose, blocked on toolchains that are not present, and in one case a pure tautology** — while the *only live runtime admission path* (`source/constitutional-gate.lisp`) **fails OPEN**. The green CI certifies Machine A's conformance plus **the ledger's own honesty about Machine B being unproven** — which a casual reader misreads as "system verified." The verification is real; it points almost entirely away from where legal correctness is decided. The system is **commendably honest** that this is so (the manifest literally says "0/17 PROVED, ΤΟ ΣΥΣΤΗΜΑ ΔΕΝ ΕΙΝΑΙ LEVEL-7"); the defect is not dishonesty, it is that the trusted spine's root seat **does not exist as code**.

---

## 1. IS THE PROOF HARNESS REAL VERIFICATION OR THEATRE? — split verdict

### 1A. REAL machine-checkable verification (KEEP — trustworthy) `DEMONSTRATED`

These are **independent N-version reimplementations checked against shared golden vectors**, with **mutation witnesses** proving the checks are not tautologies. They verify a *specific property* by *independent agreement*, not by "run code, check exit 0."

| seat | what it actually checks | why trustworthy |
|---|---|---|
| `deployment/verify/verify-merkle.py` + `verify-merkle.mjs` + `kernel-verify.lisp` (mth/hash-node) | RFC 9162/6962 Merkle: empty root, every leaf (hex inputs), roots n=0..8,15,16,17, inclusion paths, consistency proofs — **and independently *generates* PATH and PROOF element-for-element** (`path_gen`, `proof_gen`), not merely folds to a root | 3 independent implementations (Lisp/Python/Node), shared **data only** (`gen-merkle-truth.lisp` explicitly refuses to generate code); split-at-largest-power-of-two, **no duplicate-last** (CVE-2012-2459 avoided); mutation-witnessed (§1C) |
| `deployment/verify/verify-temporal.py` | Temporal semantics reimplemented from spec: `date+` per ΑΚ 241-243 (leap/month-end), condition-AST canonicalization (flatten/dedupe/sort/collapse), denotational `sat`, domain-separated hashes, attestation canonical+hash | pure-stdlib Python vs. Lisp-produced vectors — genuine N-version agreement; every disagreement → exit 1 with named site |
| `deployment/verify/verify-canonical.py` | RFC-8785-style canonical serialization (escapes, `\u%04x` lowercase, boolean-in-hash-record forbidden) → `sha256(utf8)` | second-language reimplementation vs. golden vectors, fail-closed |
| `deployment/verify/verify-release.py` ⇄ `kernel-verify.lisp` | Release census: root ≡ dir-name (MTH of 10 canonical files, **verifier inside its own identity**), per-article sha512 ≡ bytes, `pcl_text_root` ≡ MTH(text leaves), detached JWS RS256 with **full EMSA-PKCS1-v1_5** (attached-payload token rejected; missing sig = FAIL, no unsigned downgrade) | verdict-for-verdict twins in two languages; **honestly discloses its own limit** (see §2) |

**Verdict: KEEP-AS-IS.** These are the trustworthy core. Defect class here is not correctness but *coverage* (they verify plumbing, not the mission surface — §3).

### 1B. Anti-false-green CI judges (KEEP — real, born from real incidents) `DEMONSTRATED`

- `assess-gate-plenary.sh` — refuses CI false-green: requires a **line-anchored** footer `════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (N) ════` where N == printed verdict count == ≥floor, takes the **real** `${PIPESTATUS[0]}` docker exit (not `tee`'s 0), treats non-{0,1} exit (137 OOM / 139 segv / 125 docker) as crash not verdict, exact-name gate-exception matching. Born from a real bug (CI judged plenary with `docker … | tee` and no pipefail). **KEEP-AS-IS.**
- `assess-gate-manifest.lisp` — the strictly superior form: parses the canonical `:gate-plenary/1` manifest with a data-only readtable (`*read-eval* nil`, `#`/`` ` `` denied), enforces **exact set-equality** with `gate-registry.sexp`, no duplicates, exactly one verdict per gate, `:completed t` positive proof. **KEEP-AS-IS.**
- `verify-runtime-closure.sh` — born from a real false-green (CI called a nonexistent script → all downstream `needs:` never ran; committed artifact was `"closure":[]` so inline jq passed trivially). Now checks the closure artifact is non-empty, layer separation, pin↔deps.lock hashes. **KEEP-AS-IS.**

### 1C. Mutation-adequacy backbone (KEEP — this is what makes 1A non-tautological) `DEMONSTRATED`

- `scripts/merkle-mutation-witness.sh` — **actually applies** mutations to *copies* of each Merkle impl, runs against committed golden vectors, requires non-zero; a surviving mutant = the gate cannot tell right from wrong = FAIL. Witness registry read from the profile (`:mutation-witnesses`), set-equality enforced so the field can't rot decoratively.
- `authority-v2/proofs/gate-negative-fixtures.py` — mutates the *real* manifest files (gate flipped to `:passed`, `:proved` without artifact, invented status, hand-edited summary) and requires each verifier to **reject**, with positive-witness that the unmutated files pass.

**These two are the reason Machine A is not theatre.** Without them the N-version verifiers could share a bug or assert-what-they-do. **KEEP-AS-IS** and treat as load-bearing.

### 1D. Bookkeeping gates mislabeled as "proofs" (UPGRADE — real at their job, misleading as presented) `DEMONSTRATED`

- `authority-v2/proofs/verify-completion-matrix.py` and `verify-proof-manifest.py` **do not verify any theorem.** They verify that the *ledger* (`LEVEL7-COMPLETION-MATRIX.sexp`, `proof-manifest.sexp`) is internally consistent: status ∈ allowed set, `:proved` requires an executed `:actual-result` + a `:proof-artifact` + a present prover, the gate is `:not-passed` while any load-bearing row ≠ `:proved`, and the declared summary equals the computed counts. This is an **honesty-ledger enforcer** — it structurally prevents *lying in the bookkeeping*. It is genuinely useful and genuinely fail-closed. But it is **not a proof checker**, and the CI step that runs it prints green. **A reader who sees this green concludes "proofs pass"; what actually passed is "the ledger honestly admits 0/17 are proved."**
- **Verdict: UPGRADE-IN-PLACE.** (a) Defect: the word "proofs" over `authority-v2/proofs/` and the green CI checkmark conflate *ledger-consistency* with *theorem-discharge*; this is a semantic false-green at the meta level. (b) Needs it to be TOP (not merely to work). (c) Upgrade: rename the directory/step to what it is (`ledger-integrity` / `honesty-gates`), and make the CI surface print the manifest's own `:gate :not-passed` prominently so green never reads as "verified."

### 1E. Tautology / theatre (REPLACE) `DEMONSTRATED`

- `authority-v2/proofs/witness-quorum-test.py` — **the clearest tautology in the harness.** It *defines the policy it tests inside the test file* (`evaluate_quorum`, lines 52-78) — a toy re-implementation — then asserts that toy behaves as the test expects. There is **no production witness-quorum seat** anywhere in the trusted path that this exercises; `external_quorum_status=disabled` is the current real state, so the gate is inert. The test proves only that a function written 30 lines above returns what the assertions 30 lines below expect. Zero coupling to any deployed code. **Verdict: REPLACE.** (a) Defect: test-restates-the-code, and the code it restates is not the system's code. (b) Needs it to WORK honestly (a passing tautology is worse than no test — it manufactures assurance). (c) Replace with a test against the *actual* quorum seat once one exists; until then delete it and mark witness-quorum `:not-implemented` in the ledger rather than "tested."

---

## 2. ARE THE "PROOFS" ACTUAL PROOFS, OR TESTS-THAT-RESTATE-THE-CODE? — the 0/17

**CONFIRMED: 0/17 theorems discharged.** `authority-v2/proof-manifest.sexp` `:summary (:total 17 :proved 0 :failed 0 :blocked-toolchain 17)`; every one of T1–T9 (admission), P1–P2 (parser), S1–S2 (store), C1 (checker), R1–R3 (refinement) is `:status :blocked-toolchain` awaiting **F\*, Coq/Perennial, CompCert — none of which are present** (`:present nil`; CompCert additionally blocked on a commercial licence). `DEMONSTRATED`.

**The 9 admission "theorems" are prose, not machine-checked.** `authority-v2/kernel/admission-model.sexp` is `:implementation-status :specification-only`, `:implementation-language-target "F* (verified) — ΟΧΙ Common Lisp"`. Each theorem is a natural-language ∀-statement (e.g. T1: "∀ inputs. K(...) = Accept ⇒ candidate bears a valid signature against an active role"). There is **no executable model, no F\* source, no proof object.** `DEMONSTRATED`. Under the mandatory distinction (proof-checking ≠ formalization correctness), even if F\* later discharges these, the F\*-model-⇔-Greek-law fidelity is a separate, un-owned obligation. Today the status is: **THEOREM-shaped prose at HYPOTHESIS/DESIGN-ENTAILED level.**

**What `authority-v2/run-proofs.sh` actually runs** (from `authority-v2/PROOF-CENSUS.txt`, 15 proof-mode entries): OS-boundary/capture-isolation behavioral tests, producer-topology tests, capture mutation-witness, proof-census adversarial test, `gate-negative-fixtures.py`, `witness-quorum-test.py`, `verify-completion-matrix.py`, `verify-proof-manifest.py`, ceremony rehearsal. **Not one of these discharges a theorem.** They are behavioral tests + ledger checks. The directory name "proofs" is a misnomer; it is a test-and-ledger suite. `run-proofs.sh`'s own census discipline is *excellent* (recursive scan, closed schema, no glob, symlinks banned, "baptism" of a proof as a tool rejected, BLOCKED-is-never-PASS with `AUTHORITY_V2_REQUIRE_ALL=1` in CI) — but it is a **harness for tests, judged by exit codes**, not a proof runner. **Verdict on run-proofs.sh: UPGRADE-IN-PLACE** — keep the census machinery verbatim (it is top-tier anti-glob discipline), relabel "proofs" → "adversarial suites", and stop letting its green stand next to the word "proofs."

**The CI false-green at the meta level (the real trap):** `docker-orchestrator.yml` runs the authority-v2 suite under `AUTHORITY_V2_REQUIRE_ALL=1` and the two honesty gates, and goes **green** — while 0/17 theorems are proved and the live admission gate is fail-open. Green here means "plumbing conforms AND the ledger is honest about being unproven," which is *not* what "all proofs pass" connotes. `DEMONSTRATED` / the misreading risk is `HYPOTHESIS` but structural.

---

## 3. THE SINGLE MOST SERIOUS FOUNDATIONAL DEFECT

> **The harness's entire real verification power is concentrated on the cryptographic/serialization *plumbing*, while the load-bearing *authority/admission/legal-correctness* surface — the whole reason the system claims to be a trusted spine — has ZERO discharged proof, no implemented kernel, and a live runtime admission path that fails OPEN.**

Concretely:
- **The trusted spine's root seat does not exist as code.** CANON-Ω2 §3.1 designates `authority-v2/kernel/admission-model.sexp` (K-adm) as "the genuinely tiny kernel… the *only* member that must reach CakeML/Lean-class minimality." On disk it is `:specification-only` prose, 0/9 theorems discharged, no F\*. `IMPLEMENTED=false`.
- **The only *live* admission path fails open.** `source/constitutional-gate.lisp:43-47` — a rule predicate that *signals* → `(values t nil)` = **ALLOW** (self-labelled "fail-open, τίμια"). So the deployed boundary is fail-OPEN while the fail-CLOSED kernel that the architecture assumes is unbuilt (inherited R-4, `repo-paths.md` §2a — independently confirmed here). `DEMONSTRATED`.
- **The mission's correctness surface has no machine-checkable coverage at all.** Deadlines/prescription arithmetic, authority-admission ("cannot admit a wrong authority"), statute-code ⇔ statute-text fidelity — the things that decide matters and that the brief calls correctness — are verified by **nothing** in this harness. Merkle trees and canonical JSON are verified to the hilt; προθεσμία computation and admission are verified by prose.

**Why this is the top defect and not merely R-4 restated:** R-4 is one fail-open seat. This is the *shape of the entire assurance investment* — it has been spent almost entirely on the layer that is easy to make machine-checkable (crypto data structures) and almost not at all on the layer where the system can lose a client (authority + legal mapping). A green build is therefore a **category error waiting to be quoted**: "verified" plumbing under an unbuilt, fail-open trust core. `DESIGN-ENTAILED`. The system's honesty ledger *discloses* this (great); the architecture has not *closed* it (the point).

---

## 4. IS THE OVERALL STRUCTURE COHERENT, OR ACCRETED (needs RESTRUCTURING)?

**Finding: accreted; the "authority/admission" concept is smeared across THREE live locations — the exact "μία έδρα ανά έννοια" violation, masked by a `-v2` label.** `DEMONSTRATED`.

1. `source/` — **19 `*-authority.lisp` seats** (archive, blockchain, citation, embeddings, hash, jws, legal-authority-receipt, merkle, pdf, reasoning, semantic, timestamp, validation, write, x509 …) **+ `constitutional-gate.lisp` (v1 admission, fail-open) + `self-constitution.lisp`.**
2. `authority-v2/kernel/admission-model.sexp` — **v2 admission kernel (spec-only).** The literal name `authority-v2` is an accretion signal: a v2 living beside a v1 with no retirement of v1. Two admission stories coexist (live fail-open gate vs. aspirational fail-closed kernel).
3. `systems/orchestrator-cli/*-gate.lisp` — **17 gates**; plus `source/ast-gate.lisp` + `source/constitutional-gate.lisp`. **The "gate" concept is itself split across `source/` and `systems/`.**

Other structural findings:
- **`source/` is 133 FLAT files, no sub-package directories** (`find source -type d` = empty). At 133 seats a flat namespace is an accreted layout that will not scale to "the observatory of Greek law"; concepts (authority writers, gates, memory, ingestion, proof/replay) are co-located only by filename convention. **RESTRUCTURE** before growth.
- **Merkle is clean, contrary to first appearance.** `systems/orchestrator-epistemic/merkle-tree.lisp` is an **adapter** that delegates entirely to `orchestrator.merkle` (`source/merkle-authority.lisp`) — not a second implementation. It is a mild *wrapper-smell* (CLAUDE.md bans wrappers) but adds a domain plist shape; the N-version copies in `kernel-verify.lisp`/`verify-merkle.{py,mjs}` are *intentional verifier diversity*, not production duplication. **KEEP** (note the wrapper-smell). Journal has a single seat (`source/journal.lisp`). So the duplication problem is **specifically the admission/gate concept**, not crypto.
- **CI drift (confirmed):** `provenance.yml:270` calls `./scripts/verify-provenance.sh $TAG`, which **does not exist** in `scripts/`. Broken reference on the tag path. **Fix/REPLACE.**

**Verdict on architecture: RESTRUCTURE.** The composition CANON-Ω2 proposes (split-verifier family behind one admission bus) is the right target; the *current* tree is a v1-authority-layer + a v2-spec-kernel + a 17-gate CLI + a 133-flat source, with admission living in ≥3 places. Growth on this base compounds the "which door is *the* door?" problem.

---

## 5. PER-SEAT VERDICT TABLE

| seat | verdict | defect / limit (quote) | WORK vs TOP | required change |
|---|---|---|---|---|
| `verify-merkle.py`/`.mjs` | **KEEP-AS-IS** | none material; finite vector set (n≤17) but PATH/PROOF gen'd independently | TOP-grade | none |
| `kernel-verify.lisp` / `verify-release.py` | **KEEP-AS-IS (note)** | own docstring: "JWK read from inside the release ⇒ proves CONSISTENCY; AUTHENTICITY rests on pinned root + TSR" | TOP, *iff* CI passes `[pinned-root-hex]` | make pinned-root out-of-band mandatory in CI; without it a forger regenerates a self-consistent signed release |
| `verify-temporal.py` | **KEEP-AS-IS** | N-version vs Lisp vectors; legal-mapping fidelity out of scope (honest) | TOP for the semantics | none (fidelity is a separate seat) |
| `verify-canonical.py` | **KEEP-AS-IS** | — | TOP | none |
| `assess-gate-plenary.sh` | **KEEP-AS-IS** | — | TOP anti-false-green | none |
| `assess-gate-manifest.lisp` | **KEEP-AS-IS** | strictly supersedes the `.sh` grep form | TOP | prefer it over `.sh` in CI |
| `gate-registry.sexp` | **KEEP-AS-IS (note)** | header concedes set was "static enumeration… first owner Docker run validates against runtime" — DEMONSTRATED-only after that run | WORK | ensure the runtime-vs-registry reconciliation actually runs |
| `verify-runtime-closure.sh` | **KEEP-AS-IS** | — | TOP | none |
| `merkle-mutation-witness.sh` | **KEEP-AS-IS** | the anti-tautology backbone | TOP | none |
| `gate-negative-fixtures.py` | **KEEP-AS-IS** | mutation adequacy for the ledger gates | TOP | none |
| `verify-completion-matrix.py` / `verify-proof-manifest.py` | **UPGRADE-IN-PLACE** | verify the *ledger*, not theorems; green reads as "proofs pass" | TOP-honesty, misleading surface | relabel; surface `:gate :not-passed` in CI |
| `run-proofs.sh` | **UPGRADE-IN-PLACE** | superb census discipline, but runs *tests* under the name "proofs" | WORK→TOP | rename "proofs" → "adversarial suites" |
| `witness-quorum-test.py` | **REPLACE** | defines `evaluate_quorum` *inside the test* and tests it — tautology, no production seat | fails to WORK honestly | delete; test the real seat when it exists |
| `authority-v2/kernel/admission-model.sexp` (K-adm) | **RESTRUCTURE/REPLACE (impl)** | `:specification-only`, 0/9 discharged, no code | not even WORK (unbuilt) | implement as the tiny fail-closed kernel; discharge or downgrade the 9 |
| `proof-manifest.sexp` (17 theorems) | **KEEP ledger / defect is content** | `0/17 PROVED … blocked-toolchain` | honest, but the proofs are absent | stand up ≥1 toolchain (F\*) or reclassify debt with dates |
| `source/constitutional-gate.lisp` (live admission) | **REPLACE (on-seat)** | `l.44-47` predicate error → `(values t nil)` = ALLOW = **fail-OPEN** | breaks the whole trust story | make fail-CLOSED; eliminate the error class structurally |
| overall `source/`(133 flat) + `authority-v2` + 17 gates | **RESTRUCTURE** | admission concept in ≥3 seats; flat namespace | scaling defect | one admission door; sub-package the flat tree |
| `provenance.yml:270 verify-provenance.sh` | **REPLACE** | referenced script does not exist | broken | write it or remove the step |

---

## 6. WHICH PARTS ARE TRUSTWORTHY vs MUST BE REPLACED

- **Trust (use as the foundation to build on):** the N-version + golden-vector + mutation-witness discipline (Merkle, temporal, canonical, release), the anti-false-green CI judges (`assess-gate-*`, `verify-runtime-closure`), and the census/ledger-honesty machinery (`run-proofs.sh` census, `gate-negative-fixtures`, the two manifest verifiers *as honesty gates*). This is real, and it is the correct *template* to extend to the mission surface.
- **Replace/relabel:** `witness-quorum-test.py` (tautology); the "proofs" label wherever it sits over test suites and ledger gates (semantic false-green); the fail-open `constitutional-gate`; the missing `verify-provenance.sh`.
- **Build (does not exist):** a real, implemented, fail-closed **K-adm** kernel and *any* machine-checkable coverage of deadlines, admission, and statute-code↔text fidelity. Until then, the harness verifies the safe, and is silent on the load-bearing.

**Bottom line for the base transformation:** do NOT read the green CI as "foundation is sound." The foundation is *sound where it is cryptographic* and *unbuilt-and-fail-open where it is legal*. The prior "KEEP most seats" assumption is FALSIFIED precisely at the trusted spine.
