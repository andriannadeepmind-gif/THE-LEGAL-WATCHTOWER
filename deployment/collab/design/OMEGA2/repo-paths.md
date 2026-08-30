# OMEGA-2 — REPO PATH-VERIFICATION INVENTORY
**Target:** `/home/user/THE-LEGAL-WATCHTOWER`
**Method:** direct filesystem enumeration (Glob/Grep/Read/`find`) against the live working tree. Every path below is either quoted VERBATIM as it exists on disk, or reported MISSING. No path is inferred.
**Claim-status of this document:** IMPLEMENTED-facts about the on-disk tree (what exists) are `DEMONSTRATED` (I ran `find`/`ls`/`grep` and reproduce the output). Statements about a file's *purpose* are `EMPIRICAL` (read from the file's own header banner), never a claim that the file is correct.

---

## 0. Baseline / freeze verification (`DEMONSTRATED`)

- Git `HEAD` = **`803113c0`** — `[FRESH-PHASE-2-LAUNCH] Συντονιστικό dossier εκκίνησης blind Φάσης 2`.
- Claimed baseline **`e621dbe1`** (`[L7-RUN-ALL] Μία εντολή για ΟΛΕΣ τις αποδείξεις`) **IS an ancestor** of HEAD (`git merge-base --is-ancestor` → true).
- `git diff --name-status e621dbe1 HEAD` returns **exactly 3 added files, all under one new directory**:
  - `deployment/collab/fresh-phase-2-launch/COORDINATOR-PLAYBOOK.md`  **[EXTRA-NOT-BASELINE]**
  - `deployment/collab/fresh-phase-2-launch/EXTERNAL-PACKAGE-POINTER.md`  **[EXTRA-NOT-BASELINE]**
  - `deployment/collab/fresh-phase-2-launch/FREEZE-VERIFICATION-RECORD.json`  **[EXTRA-NOT-BASELINE]**
- `git status --short` = **clean** (no unstaged/untracked drift beyond the committed extra dir).
- **Conclusion:** working tree == frozen baseline `e621dbe1` **+** the single extra directory `deployment/collab/fresh-phase-2-launch/`, exactly as the brief asserts. No other divergence. `VERIFIED`.

---

## 1. Top-level structure & file counts (`DEMONSTRATED`)

Recursive regular-file counts per top-level directory (`.git` excluded; `output/` and `output_run1/` counted by path only — contents NOT read, per brief):

| files | directory | notes |
|------:|-----------|-------|
| 29198 | `output/` | build/emit artifacts — **contents NOT read (in scope only as a dependency sink)** |
| 3307 | `third-party/` | vendored deps (SBCL/quicklisp libs, cffi, etc.) |
| 990 | `input/` | corpus/input staging |
| 742 | `deployment/` | verify harness, data, collab dialogue, self-history |
| 706 | `output_run1/` | second emit run — **contents NOT read** |
| 175 | `systems/` | the 11 orchestrator ASDF systems (main engine) |
| 152 | `tests/` | Lisp/py test suites |
| 133 | `source/` | **primary seat library (flat), 133 files** |
| 63 | `authority-v2/` | v2 authority kernel (admission model, proofs, capture) |
| 52 | `determinism/` | determinism harness |
| 18 | `docs/` · 16 `docker/` · 9 `configs/` · 8 `scripts/` · 5 `cloudflare/` · 3 `state/` · 3 `keys/` · 3 `examples/` · 3 `evidence/` · 2 `deps/` · 1 `tools/` · 1 `releases/` · 1 `candidates/` | supporting |

Root also holds **23 `orchestrator*.asd` system definitions**, `Dockerfile` (24 KB) + `Dockerfile.test`, `docker-compose.yml` (+3 scoped compose files), `build.lisp`, `entrypoint.lisp`, and the governance docs (`CLAUDE.md`, `SEMANTIC-CONTRACT.md`, `DEPENDENCY-CONTRACT.md`, `PROVENANCE.yaml`, `SYSTEM-HIERARCHY.txt`).

Total `.lisp`/`.sexp`/`.asd` files tree-wide: **1796** (includes vendored `third-party/`).

### `systems/` subtree (main engine, by file count)
| files | system |
|------:|--------|
| 48 | `systems/orchestrator-cli/` (**gate + dispatch seat**) |
| 25 | `systems/orchestrator-omega-modules/` |
| 25 | `systems/orchestrator-engine-sbcl/` (stages: deploy, consolidate…) |
| 18 | `systems/orchestrator-epistemic/` (meta-ontology) |
| 13 | `systems/orchestrator-tests/` |
| 8 | `orchestrator-spec/` · 8 `orchestrator-model/` · 8 `orchestrator-core/` |
| 7 | `orchestrator-meta/` · 7 `orchestrator-gr-syntagma/` · 7 `orchestrator-ai-core/` |

### `deployment/` subtree
`deployment/data/` (344) · `deployment/verify/` (211, the gate/proof harness) · `deployment/collab/` (120) · `deployment/knowledge/` (7) · `deployment/templates/` (5) · `deployment/self/` (1 = `history.sexp`) · `deployment/state/` (1).

### `authority-v2/` subtree
`proofs/` (15) · `tests/` (12) · `fixtures/` (10) · `genesis/` (7) · `toolchain/` (3) · `capture/` (3) · `schema/` (2) · `roles/` (2) · and single-file seats: `store/`, `log/`, **`kernel/` (= `admission-model.sexp`)**, `capability/`.

---

## 2. Claimed-anchor verification (`DEMONSTRATED` existence; `EMPIRICAL` role)

| # | claimed anchor | exists? | exact path (verbatim) | plausible role (from file header) |
|---|----------------|---------|-----------------------|-----------------------------------|
| 1 | `constitutional-gate.lisp` | ✅ | `source/constitutional-gate.lisp` | Constitutional barrier as a *property of acting*: rule registry + `evaluate` + creator-override detection. **See fail-open note §2a.** |
| 2 | `admission-model.sexp` | ✅ | `authority-v2/kernel/admission-model.sexp` | "PURE STATE-TRANSITION MODEL + THE 9 THEOREMS" — v2 admission kernel. |
| 3 | `merkle-authority.lisp` | ✅ | `source/merkle-authority.lisp` | "MERKLE (RFC 6962) — THE ONE SEAT of the foundation's Merkle trees" (13 defuns). |
| 4 | `journal.lisp` | ✅ | `source/journal.lisp` | "THE ONE journal idiom — append-only sexp-lines, single impl" (21 defuns). |
| 5 | `memory.lisp` | ✅ | `source/memory.lisp` | "MEMORY SUBSTRATE — one episode stream, five capabilities" (29 defuns). (Also a *vendored* homonym `third-party/cffi-.../tests/memory.lisp` — unrelated.) |
| 6 | `version-graph.lisp` | ✅ | `source/version-graph.lisp` | "BITEMPORAL VERSION GRAPH — [0088] Temporal/Identity Φ2" (**114 defuns/methods — largest seat**). |
| 7 | `inference-gate.lisp` | ✅ (⚠ path) | `systems/orchestrator-cli/inference-gate.lisp` | "INFERENCE GATE — the engine (L1/JTMS) and graph reasoner, checked". **NOT in `source/`** — see §5 drift (path ambiguity). |
| 8 | `authority-evidence-replay.lisp` | ✅ | `source/authority-evidence-replay.lisp` | "[0088 Φ7-HARDENING #4B+#4C] AUTHORITY EVIDENCE REPLAY + PROOF-BINDING FREEZE" (29 defuns). |
| 9 | `consolidation-proof.lisp` | ✅ | `source/consolidation-proof.lisp` | "LEVEL 2 — REPLAYABLE AMENDMENT PROOF (provably-correct consolidation)" (9 defuns). |
| 10 | `meta-ontology.lisp` | ✅ | `systems/orchestrator-epistemic/meta-ontology.lisp` | "Layer 1: Meta-Ontology (Epistemic System Definition)". |
| 11 | `emit-graph` | ✅ **as FUNCTION, not file** | `source/write-authority.lisp:16` `(defun emit-graph …)`, exported from pkg `orchestrator.write-authority` | The single authority-scoped TTL/graph writer; ~9 call-sites across `ai-citation-strategy`, `legal-audit-system`, `semantic-versioning-system`, `consolidate.lisp`, FRBR generators. **No file named `emit-graph*` exists** — it is the write seat's exported entry. |
| 12 | `deploy.lisp` | ✅ | `systems/orchestrator-engine-sbcl/stages/deploy.lisp` | "Deploy stage — SINGLE FILESYSTEM TRUTH". |
| 13 | `legal-authority-replay(.lisp?)` | ❌ **MISSING** | — (zero hits anywhere, any extension) | Claimed anchor does not exist. Closest real seats: `source/authority-evidence-replay.lisp` and `source/legal-authority-receipt.lisp`. **Likely a stale/renamed name — see §5.** |
| 14 | `constitutional-dispatch.lisp` | ✅ | `systems/orchestrator-cli/constitutional-dispatch.lisp` | "CONSTITUTIONAL ROUTING — the barrier as a property, via CLOS `around`" (the mediation layer that wraps §2.1's pure registry). |
| 15 | `deployment/self/history.sexp` | ✅ | `deployment/self/history.sexp` | Append-only hash-chained self-biography (genesis→birth→inheritance…), each line `:PREV`/`:HASH` linked (SHA-256 chain). 1633 B. |
| 16 | `output/.healthy` | ✅ | `output/.healthy` | 11-byte health marker in the emit sink (existence checked; content not read per brief). |

### 2a. FAIL-OPEN pattern in `constitutional-gate.lisp` (`DEMONSTRATED` — read directly) — **BLOCKING**

Lines 43–47 of `source/constitutional-gate.lisp`:

```lisp
(multiple-value-bind (ok reason)
    (handler-case (funcall (getf r :predicate))
      (error () (values t nil)))    ; σφάλμα κανόνα ⇒ ΜΗΝ μπλοκάρεις (fail-open, τίμια)
  (unless ok
    (return (values nil (getf r :article) reason (getf r :id)))))
```

**Confirmed:** if a constitutional rule's predicate SIGNALS AN ERROR, the gate treats it as `(values t nil)` = **ALLOW** (`fail-OPEN`). The in-source comment explicitly names it "fail-open, τίμια" (honest fail-open). This is exactly the pattern the brief flagged at ~44–45.
- **Status: BLOCKING contradiction with the creator law "0 λάθος / εξάλειψη της κλάσης σφάλματος" and the fail-closed posture demanded for a privilege/DLP boundary.** A crashing predicate = silent admission, not refusal. `DESIGN-ENTAILED` risk: any exception in rule evaluation (bug, resource, type error) becomes a constitutional bypass. This is a design choice made explicit in code, not an accident — but it directly opposes "fail-closed Publication Gateway" (real-condition #3) and "structurally-impossible error" (CLAUDE.md §ΥΠΕΡΤΑΤΟΣ ΝΟΜΟΣ). Must be resolved on its seat, not patched around.

---

## 3. The real seats — 40 most load-bearing `.lisp` files by role (`DEMONSTRATED` paths / `EMPIRICAL` roles)

**A. Gates (structural admission checks) — `systems/orchestrator-cli/*-gate.lisp` (17) + 2 in `source/`:**
`architecture-gate` · `capability-gate` · `component-gate` · `contract-gate` · `deontic-gate` · `dialogue-gate` · `event-gate` · `evolution-gate` · `external-benchmark-gate` · `fluid-gate` · `generation-gate` · `golden-gate` · `inference-gate` · `iq-gate` · `provenance-gate` · `release-gate` · `verify-truth-gate` (all under `systems/orchestrator-cli/`); plus `source/ast-gate.lisp`, `source/constitutional-gate.lisp`. Dispatch wrapper: `systems/orchestrator-cli/constitutional-dispatch.lisp`.

**B. Writers / authority-emit seats (`source/`):**
`write-authority.lisp` (**`emit-graph` seat**) · `validation-authority.lisp` (canonical-TTL validate *before* emit) · `merkle-authority.lisp` · `semantic-authority.lisp` · `timestamp-authority.lisp` · `jws-authority.lisp` · `blockchain-authority.lisp` · `archive-authority.lisp` · `legal-authority-receipt.lisp` · `signed-embedding-manifest.lisp` · `json-emit.lisp`.

**C. Proof / replay / verify runners:**
`source/authority-evidence-replay.lisp` · `source/consolidation-proof.lisp` · `source/proof-carrying.lisp` · `source/authority-proof-bundle.lisp` · `source/corpus-provenance.lisp` · `source/provenance-link.lisp` · `source/narrative-provenance.lisp` · `systems/orchestrator-epistemic/temporal-proof.lisp` · `systems/orchestrator-ai-core/provenance-model.lisp` · `source/legal-extraction-verify.lisp`.

**D. Memory / journal / history / versioning core:**
`source/memory.lisp` · `source/journal.lisp` · `source/self-history.lisp` · `source/version-graph.lisp` (114 defuns) · `source/semantic-versioning-system.lisp` · `source/consolidation-engine.lisp` · `source/trace-core.lisp`.

**E. Ingestion / corpus / source authority:**
`source/ingestion-daemon.lisp` · `source/ai-ingest-manifest.lisp` · `source/ai-corpus-dump.lisp` · `source/corpus-fingerprint.lisp` · `source/government-source.lisp` · `source/source-profile.lisp` · `source/legal-audit-system.lisp` · `source/ai-citation-strategy.lisp` · `source/http-server.lisp` · `source/review-queue.lisp` · `source/guard-metaeval.lisp` · `source/meta-ontology.lisp`(epistemic).

---

## 4. CI / workflow path references (`DEMONSTRATED`)

Three workflows: `.github/workflows/deploy-corpus.yml`, `.github/workflows/docker-orchestrator.yml`, `.github/workflows/provenance.yml`.

Concrete repo paths referenced and their on-disk status:

| referenced path | exists? |
|-----------------|---------|
| `deployment/verify/assess-gate-plenary.sh` | ✅ |
| `deployment/verify/assess-gate-plenary-test.sh` | ✅ |
| `deployment/verify/assess-gate-manifest.lisp` | ✅ |
| `deployment/verify/gate-registry.sexp` | ✅ |
| `deployment/verify/verify-merkle.py` | ✅ |
| `scripts/verify-runtime-closure.sh` | ✅ |
| `scripts/verify-runtime-closure-test.sh` | ✅ |
| `scripts/capture-runtime-closure.lisp` | ✅ |
| `scripts/gen-merkle-truth.lisp` | ✅ |
| `scripts/merkle-mutation-witness.sh` | ✅ |
| `authority-v2/proofs/verify-completion-matrix.py` | ✅ |
| `authority-v2/proofs/verify-proof-manifest.py` | ✅ |
| `authority-v2/run-proofs.sh` | ✅ |
| `authority-v2/tests/build-authority-core.lisp` | ✅ |
| `docker/run-standalone-suites-test.sh` | ✅ |
| `docker/run-standalone-test.lisp` | ✅ |
| `docker/verify-proof-manifest-test.py` | ✅ |
| `tests/level7-disarm-test.lisp` | ✅ |
| `tests/release-authority-test.lisp` | ✅ |
| `tests/transparency-log-test.lisp` | ✅ |
| `deps/orchestrator-core-runtime.closure.json` | ✅ |
| `orchestrator.asd`, `Dockerfile` | ✅ |
| **`scripts/verify-provenance.sh`** (called `provenance.yml:270` → `./scripts/verify-provenance.sh $TAG`) | ❌ **MISSING** |

`scripts/` actually contains: `capture-runtime-closure.lisp`, `gen-deps-lock.lisp`, `gen-merkle-truth.lisp`, `generate-keys.lisp`, `merkle-mutation-witness.sh`, `verify-gate-5-validation.lisp`, `verify-runtime-closure-test.sh`, `verify-runtime-closure.sh` — **no `verify-provenance.sh`**.

**Finding (CI drift):** `provenance.yml` invokes a script that does not exist in the frozen tree. `EMPIRICAL`: this step would fail at runtime *if reached* (it is on a tag-triggered path; whether that path is exercised in the standard proof run is UNKNOWN from paths alone). Reported as broken reference, not a runtime demonstration.

---

## 5. DRIFT LIST — claimed-but-missing / ambiguous anchors (`DEMONSTRATED`)

| anchor as claimed | status | reality on disk | severity |
|-------------------|--------|-----------------|----------|
| `legal-authority-replay(.lisp?)` | **MISSING** | Zero occurrences anywhere (any extension, any dir). Nearest real seats: `source/authority-evidence-replay.lisp`, `source/legal-authority-receipt.lisp`. | Anchor name is stale/renamed. Consumers referencing it would break — but no `.lisp`/CI reference to this name was found, so likely a doc/plan-level ghost. **HYPOTHESIS**: renamed → `authority-evidence-replay`. |
| `emit-graph` (as a **file**) | **NOT A FILE** | It is `(defun emit-graph …)` in `source/write-authority.lisp:16`, exported by `orchestrator.write-authority`. Real and load-bearing, but a *function seat*, not a path. | Resolved: claim of "model access ≠ file"; the anchor is a function. Report distinguishes function vs file (brief asked). |
| `inference-gate.lisp` | **EXISTS, PATH-AMBIGUOUS** | Only at `systems/orchestrator-cli/inference-gate.lisp`. **No `source/inference-gate.lisp`.** | Low: the file exists; any consumer assuming a `source/` seat is wrong. |
| `constitutional-gate.lisp` lines 44–45 | **PRESENT & FAIL-OPEN** | Rule-predicate error → ALLOW (`(values t nil)`), self-labelled "fail-open". | **BLOCKING** — see §2a. Contradicts fail-closed / 0-λάθος creator law. Stays BLOCKING until closed on-seat. |
| `scripts/verify-provenance.sh` | **MISSING (CI-referenced)** | Called by `provenance.yml:270`; not present in `scripts/`. | Medium: broken CI reference on the provenance/tag path. |
| baseline `e621dbe1` vs HEAD `803113c0` | **RESOLVED / consistent** | HEAD = baseline + exactly the one extra dir `deployment/collab/fresh-phase-2-launch/` (3 files). | None — matches brief; the working tree is NOT at the bare `e621dbe1` SHA but is that commit + the sanctioned extra dir. Flagged so no one mistakes HEAD for the raw baseline SHA. |

All other 12 named anchors: **PRESENT at a single verbatim path** (table §2).

---

## 6. Residual UNKNOWNs (honest ignorance)
- Whether `provenance.yml`'s missing-script step is on an exercised path in the standard proof run — `UNKNOWN` from paths alone (needs workflow-trigger analysis).
- Contents/consistency of `output/`, `output_run1/`, `output/.healthy` — **out of scope by brief** (paths + dependency position confirmed; contents deliberately unread).
- Whether the `legal-authority-replay` ghost is referenced by any non-`.lisp`, non-CI doc (governance markdown) — not exhaustively swept beyond code + workflows.
