# CURRENT-SYSTEM-MAP — THE LEGAL WATCHTOWER at `e621dbe1`

| | |
|---|---|
| **Source commit** | `e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03` |
| **Source tree** | `23b7a6f4450f50d151d38e13020bee9872e73bcd` |
| **Historical baseline** | `57c0cd868c80f87df8e298c9aa75b8ccf2503391` (DeepSeek Phase-1 target) |
| **Corroboration commit** | `2b910271f11fc462eee1378fb9a77623c791fcbf` (Claude Phase-1A, read as git objects only) |
| **Generated** | 2026-08-26T00:36:43Z |
| **Worktree** | clean at read and at generation |
| **Tracked paths** | 35,640 — 100 % enumerated, 100 % classified, 0 unclassified |
| **Evidence classes** | mechanically-proved 73 · empirically-reproduced 2 · source-grounded 23 · unresolved 6 |
| **Self SHA-256** | `3bfa07860c04846231606391d1ce9bacd3cd6bd22d195f8e68982e77042e8bcd` |
| **Self-hash convention** | SHA-256 of this file with the 64 hex characters on the line above replaced by 64 zeros. |

Every material claim below carries an evidence identifier resolving into `EVIDENCE-LEDGER.tsv`,
which gives the path, line range, blob hash, class and method for each.

---

## 1. What the system is

LAWMAX / THE LEGAL WATCHTOWER is a Common Lisp system that ingests the six principal Greek
legal codes from primary sources, consolidates them, and emits a content-addressed, cryptographically
committed publication of each — RDF/Turtle, JSON-LD, HTML, plain text, Akoma Ntoso — together with
Merkle inclusion proofs, RFC-3161 timestamps, JWS signatures and a transparency log.

At this commit it does not publish. The delta under study demotes the entire Lisp system to an
untrusted producer of *candidates* and moves publication authority to a subsystem that has been
specified but not built. What follows describes both halves as they actually are.

---

## 2. Repository shape

All 35,640 tracked paths are classified; none is left over `[EV-I-002, EV-I-003]`.

| Class | Count | What it is |
|---|---:|---|
| `generated_state_data` | 31,065 | Published output (29,204), a historical run (706), ingested corpora (990), deployment data, determinism runs, runtime state |
| `vendored_dependency` | 3,307 | `third-party/` in full — 30 vendored Lisp libraries |
| `test_proof` | 390 | `tests/` (152), authority-v2 proofs and probes, verification vectors, independent verifiers |
| `first_party_source` | 346 | `source/` (133), `systems/` (175, of which 171 `.lisp`), build and entry points, authority-v2 executables, scripts, tools, edge workers, hand-authored RDF vocabularies |
| `documentation` | 262 | Markdown, the collaboration dialogue record (117 files), READMEs inside generated trees |
| `binary_enumeration_only` | 196 | PDFs, images, `.tsr` receipts, certificates, keys, detached signatures |
| `configuration_contract` | 74 | 17 ASDF systems, container and CI definitions, lockfiles, pipeline YAML, CDDL schemas, s-expression policy files |

The ratio is the first architectural fact: **87 % of the repository is output**. The system under
study is 346 first-party files; it carries 31,065 files of what it has produced.

---

## 3. Build and load structure

Seventeen ASDF `defsystem` forms across sixteen real `.asd` files `[EV-I-007]`.
`systems/orchestrator-omega.asd` is a symlink to the root file; `orchestrator.asd` declares two
systems (`orchestrator` and `orchestrator/tests`).

```
orchestrator (meta, 1.2.0)
├── orchestrator-spec              contracts, config, protocols
├── orchestrator-model             domain model
├── orchestrator-core              pipeline machinery
├── orchestrator-infrastructure    ← the source monolith: all 133 source/*.lisp
├── orchestrator-engine-sbcl       pipeline stages (SBCL-specific)
├── orchestrator-epistemic         releases, Merkle, census, transparency log, authority boundary
├── orchestrator-omega             25 FRBR generator modules — implemented, not spec-only [EV-I-008]
├── orchestrator-gr-syntagma       the Greek constitutional pipeline
├── orchestrator-ai-core           inference
├── orchestrator-meta              self-model
└── orchestrator-cli               130 registered commands, 25 gates, 36 capability declarations
```

Two aggregators (`orchestrator-core-runtime`, `orchestrator-tests-runtime`) and one dev system
(`orchestrator-tooling`) declare `:components ()`. `orchestrator-tooling` is loaded by nothing:
no `.asd` depends on it, no build, workflow or compose file references it; the only references are
four lines of prose `[EV-C-013]`.

The system is SBCL-locked: `sb-posix`, `sb-thread`, `sb-ext`, `sb-unix`, `sb-alien`. The delta
deepens this (`sb-unix:unix-getpid`, `sb-posix:getpid`).

**Entry points — three declarations, one truth.** `SYSTEM-HIERARCHY.txt:5-8` names
`unified-frbr-generator.lisp` as the single entry point; `build.lisp:44` produces a core whose
toplevel is `orchestrator.cli:main`; `Dockerfile:452` runs `/app/entrypoint.lisp`, which is
`docker/entrypoint.lisp`, not the root `entrypoint.lisp` (that file is copied into the builder
stage and never executed). Three "one entry point" statements, one of which is right.

---

## 4. The pipeline, end to end

```
input/*.pdf  ─┐
              ├─▶ pdf-authority ──▶ consolidation ──▶ omega FRBR generation
configs/*.yaml┘        │                                        │
                       │ (5 subprocesses: pdftoppm, tesseract)  ▼
                       │                          per-article emitters
                       │                     .ttl .jsonld .html .txt .hash
                       ▼                                        │
              source.fetch_cmd ──▶ /bin/sh -c ──▶ node/Playwright
                                                                ▼
                                    deploy-epistemic ──▶ 10 canonical artefacts
                                                                │
                                            Merkle root over the canonical set
                                                                ▼
                                          ┌──────────────────────────────┐
                                          │  candidates/sha256-<root>/   │ ◀── the delta moved this
                                          └──────────────────────────────┘
                                                                │
                                    ══════ CAPTURE BOUNDARY ══════
                                          quarantine snapshot, recomputed
                                                                │
                                                   admission kernel K
                                                   ✖ NOT IMPLEMENTED
                                                                │
                                          ┌──────────────────────────────┐
                                          │  authority store · latest    │  never reached
                                          └──────────────────────────────┘
```

The canonical set that defines release identity is ten files, and the **order is part of the
commitment**: `census.json`, `lineage-graph.ttl`, `meta-ontology.ttl`, `negation.ttl`,
`shapes/article-shape.ttl`, `shapes/lineage-shape.ttl`, `shapes/manifest-shape.ttl`,
`stability-policy.md`, `stability-policy.ttl`, `verify/verify.lisp`. The Merkle profile is
`lawmax-merkle-sha256-v1`: leaf = `SHA-256(0x00 ‖ raw bytes)`, node = `SHA-256(0x01 ‖ L ‖ R)`,
RFC 9162 §2.1.1 unbalanced split, never duplicate-last `[EV-V-003]`.

**Six corpora, twenty-four legacy releases.** `astikos`, `constitution`, `kdioikitikis`,
`kpoinikis`, `kpolitikis`, `poinikos` — each with three content-addressed releases and one
timestamp-named one, plus a `latest` symlink and a `latest.json` pointer. Eighteen content-addressed
plus six timestamp-named is the 24 the genesis inventory records; `output_run1/` holds seven further
historical releases `[EV-V-008]`. Those seven carry `U+F03A` — a private-use codepoint — where a
colon belongs, an artefact of a Windows filesystem that the snapshot records rather than normalises
`[EV-V-012]`.

---

## 5. What the delta did

Thirteen commits, 100 paths, +8,265/−414 `[EV-D-001]`. It is one architectural act with several
corrections layered on top, and it is best read as a demotion.

**Before**: the Lisp system cut a release, attested it with an RFC-3161 receipt, appended the root
to a transparency log, and promoted `latest`. It was the authority.

**After**: the Lisp system writes a candidate bundle into `candidates/<release-id>/` and can do
nothing else. Three seats now fail closed at their definition —

- `tlog-append-root!` → `%seat-removed` `[EV-T-002]`
- `release-attested-p` → `%seat-removed` `[EV-T-003]`
- `promote-latest!` → `%seat-removed` `[EV-T-003]`

— and `run-attest-release` was not disabled but **deleted**, its name entered in a retired-seat
registry that answers honestly and refuses re-registration `[EV-T-005, EV-T-006]`. The legacy
transparency-log writers `%tlog-write` and `%tlog-write-1` are likewise gone from the tree, their
historical text frozen in a fixture that no `.asd` declares `[EV-T-004]`.

The refusal is unconditional. It is a plain `(error ...)` with no restart and no fallback, signalled
for every input including the fully legitimate legacy path that previously succeeded `[EV-T-001]`.

Two seats that were missing were added: `output-root`, the producer's writable workspace, and
`runtime-state-dir`, ephemeral process state — because `output/` had been carrying three different
meanings at once (authority evidence, work area, health file) and making it read-only broke the
pipeline `[EV-T-010]`. A related defect was caught in passing: the health-file path had been a
`defparameter`, baked into the saved core at load time, so a container's `LAWMAX_RUNTIME_DIR` could
never have taken effect `[EV-T-011]`.

The delta touched no published output at all: zero paths under `output/`, `output_run1/` or
`releases/` changed `[EV-D-004]`.

---

## 6. The replacement, and what is actually there

`authority-v2/` is 63 files. Read by kind rather than by directory, it is:

| Kind | Files | State |
|---|---:|---|
| Specification (`.sexp`, `.cddl`) | 11 | Written, closed, internally consistent |
| Proofs and probes | 26 | Written, adversarial, of high quality |
| Reference implementation (`capture.py`) | 1 | 1,017 lines, Linux-only, working by inspection |
| Genesis tooling and outputs | 6 | Ran once, outputs committed |
| Ceremony tooling and fixtures | 10 | Complete and rehearsable with test keys |
| Hermetic build definitions | 2 | Deliberately failing on placeholder pins |
| Runners and census | 4 | Working |
| **The admission kernel** | **0** | **Does not exist** |

The kernel `K(old_state, candidate, evidence, policy) → Reject | Accept` is declared
`:implementation-status :specification-only`, with `:implementation-language-target "F* (verified) —
not Common Lisp"` `[EV-K-001]`. The store behind it is `:implementation-status :absent-by-design`,
`:production-writer :disabled` `[EV-K-002]`. The service that would hold the private key and the
authority store has, as its entire command, an error message saying the kernel is unimplemented,
followed by `exit 3` `[EV-K-003]`.

This is stated plainly by the system in all three places. It is not concealed.

**The scoreboard the system keeps on itself**: 13 Level-7 requirements — 0 proved, 3
implemented-not-proved, 7 externally blocked, 3 not started, gate `:not-passed` `[EV-K-004]`.
17 theorems — 0 proved, 17 blocked on toolchains that are absent `[EV-K-005]`. Both summaries were
recounted against their own rows and are arithmetically correct.

**What the delta genuinely achieved**, and it is not small:

- A candidate-capture protocol that treats the producer as an active adversary, refuses symlinks,
  hardlinks, traversal, non-regular files and non-UTF-8 names, copies to a private quarantine before
  judging anything, and recomputes every byte from the copy in a strictly separate phase
  `[EV-V-002, EV-V-005]`.
- Two structurally different Merkle implementations compared on every call, plus committed golden
  vectors across the whole differential range n = 0..64 `[EV-V-004]`.
- A pinned canonical-profile digest that is live and correct at this commit `[EV-V-002]`.
- A mutation witness that re-injects every finding as a deliberate defect and requires each to be
  killed, declaring three as non-observable with a falsifiable justification.
- An OS-level boundary proof that removes every permission-based explanation and demands `EROFS(30)`
  rather than `EACCES(13)`, so the refusal is attributable to the mount and not to file modes.
- A retraction: "Merkle divergence is structurally impossible" was withdrawn when a mutation that
  errs only at n = 18 passed all twenty-two checks. What is claimed now is detection `[EV-V-006]`.

---

## 7. Deployment topology

Six compose services. Three UIDs, pinned in `identities.sh` and referenced verbatim:

| Service | UID | Role | Sees private key | Writes |
|---|---:|---|---|---|
| `orchestrator` | 11002 | producer | no | `candidates/`, `logs/`, tmpfs |
| `ingestion` | 11002 | producer | no | `candidates/`, `logs/`, tmpfs |
| `corpus-service` | 11003 | reader | no | evidence sub-volumes only |
| `producer` | 11002 | producer | no | `candidates/` |
| `authority-signer` | 11001 | authority | **yes** | authority store — but refuses to run |
| `authority-v2-proofs` | root | proof-runner | n/a | **the entire repository** |

`output/` is read-only everywhere. `deployment/` is read-only everywhere, with writable evidence
sub-volumes mounted over it from a separate host directory. `/run/lawmax` is tmpfs. `read_only`
rootfs, `cap_drop: ALL` and `no-new-privileges` on every runtime service.

Two defects sit in this file. The main service carries a malformed tmpfs option — a stray double
quote absent from the other four blocks — on the service the documentation tells operators to run
`[EV-N-001]`. The ingestion service lost its `command:` entirely, so it would run the image default
rather than ingesting `[EV-N-002]`. The topology proof catches neither: it validates roles, mounts
and privileges, and never looks at commands or tmpfs option syntax `[EV-N-003]`.

The proof-runner is the exception to everything: privileged, whole repository read-write, unpinned
base image, `apt-get install` at run time — and exempt from the topology proof by name, because it
does not use the runtime image `[EV-N-011]`.

---

## 8. Verification and gates

**Command registry**: 130 registered commands, 25 ending in `-gate`, exactly one retired
(`--attest-release`) `[EV-V-018]`.

**Capability declarations**: 36, all of them in `systems/orchestrator-cli/`. They name 25 distinct
gates; all 25 are registered commands, and all 25 registered `-gate` commands are claimed by at
least one capability — an exact bijection in both directions `[EV-V-018]`. Four capabilities declare
no gate. The bijection binds names, not behaviour.

`authority-v2` declares no capability at all. The subsystem that now carries the whole authority
story is absent from the system's own account of what it can do.

**A second, disconnected gate scheme** lives in `README.md:300-305` as GATE-1..GATE-5. It is not
the same set as the 25. GATE-4, "Pipeline integrity (no subprocess)", has no implementation anywhere
in the tree `[EV-C-004]` — while `source/pdf-authority.lisp:28` declares "No Python, no subprocess"
and the same file launches five subprocesses at lines 1389–1419 `[EV-C-006]`, and the final runtime
stage installs the binaries it calls `[EV-C-007]`.

**Proof census**: mechanically consistent at this commit. All 15 files under `authority-v2/proofs/`
are registered, no entry is dead, every `.py`/`.sh`/`.lisp` outside `proofs/` is declared as tool or
helper, and there is no symlink under `authority-v2/` `[EV-V-001]`. The classification is by
extension allowlist, which the census's own text says it is not — a residual that is benign at this
commit and untested by the adversary `[EV-N-007, EV-N-008]`.

**CI**: a new `authority-v2-boundary` job runs the single proof-runner seat with
`AUTHORITY_V2_REQUIRE_ALL=1`, then the three Lisp suites, then the two honesty gates; `tag-release`
depends on it. The completion matrix records that it has never run: zero Actions runs, zero status
contexts `[EV-V-017]`.

---

## 9. Duplications and divergences

| Concept | Seats |
|---|---|
| Container entry point | `entrypoint.lisp` (orphan, copied but never run) · `docker/entrypoint.lisp` (real) |
| Aggregate system definition | `orchestrator.asd:19-28` · `orchestrator-core-runtime.asd:17-26` — same ten subsystems |
| Which system runs the pipeline | `build.lisp:34` → core-runtime · `entrypoint.lisp:16` → orchestrator · `README.md:227` → omega |
| Dependency verifier name | `scripts/verify-deps.sh` (absent) · `docker/verify-deps.sh` (absent) · `docker/verify-deps.lisp` (real) |
| `verify-proof-manifest.py` | `docker/` (295 lines, build gate) · `authority-v2/proofs/` (95 lines) — different files |
| Edge negotiation | `cloudflare/src/worker.ts` · `cloudflare/functions/_middleware.ts` |
| "ONE ENTRY POINT" | three incompatible declarations (§3) |
| Declared version | `v1.3` in `SYSTEM-HIERARCHY.txt:2` · `1.2.0` in `orchestrator.asd` and `Dockerfile:338` `[EV-C-015]` |
| `deploy-epistemic.lisp` | `systems/orchestrator-epistemic/` (implementation) · `systems/orchestrator-engine-sbcl/stages/` (stage wrapper) |

---

## 10. What changed in the inherited pathology counts

The DeepSeek baseline's two headline figures were not taken on trust; the queries recorded in its
sealed ledger were re-executed.

| Measure | At `57c0cd86` | At `e621dbe1` |
|---|---|---|
| Direct output-file writes outside the write-authority seat | **41 matches / 20 files** (baseline said 18 files — corrected) `[EV-P-001]` | 40 / 19 `[EV-P-002]` |
| Direct `ironclad:digest-sequence` calls | **29 / 17** — reproduced exactly `[EV-P-003]` | 28 / 16 `[EV-P-004]` |

The delta removed the write site in `transparency-log.lisp` and the one in `deploy-epistemic.lisp`,
added one in `authority-boundary.lisp`, and removed one direct digest call. The structural pathology
— roughly two dozen files writing output and sixteen computing hashes, in a system whose architecture
declares one seat for each — is essentially untouched.

---

## 11. Failure semantics

The system's default is to refuse, and this is consistent enough to be called a design property.
Retired seats signal a named condition. Blocked proofs exit 2 and are never counted as passes;
the aggregate runner exits 3 for "incomplete" rather than 0. Capture translates every `OSError`
into a named refusal and purges partial quarantine, making cleanup failure visible rather than
swallowed. Ceremony stops at `exit 3` before any production root key. The hermetic builds fail
deliberately while their pins are placeholders. `open_anchor` refuses a vault that is
group-writable. `register-command` refuses to resurrect a retired name.

The exceptions are worth naming. `write-health-file` catches all errors and warns. The gate-plenary
baseline carries one declared exception (`advisor-gate`). And the largest exception is structural:
the whole authority path is now fail-closed with nothing behind it.

---

## 12. Extension mechanisms

Commands are registered by name into a single registry that enforces one seat per name and refuses
anonymous runtime re-registration. Capabilities are declared alongside contracts that state inputs,
outputs, pre- and post-conditions, side effects, policy level, audit method, rollback and tests.
Corpora are added by YAML under `configs/`, which is where `source.fetch_cmd` lives — a string
handed to `/bin/sh -c`, configured live for the constitution corpus, in a directory copied into the
runtime image. Proofs are added by dropping a file into `authority-v2/proofs/` and registering it
in the census, which the runner then enforces in both directions.

---

## 13. Honest summary

The delta is a serious, well-executed piece of engineering that makes the old authority impossible
and does not pretend the new one exists. Its self-assessment is unusually accurate: it says 0/13
and 0/17, it retracts its own strongest claim, and its most privileged service refuses to run rather
than simulate a signature.

What Phase 1 finds beyond that self-assessment is a small number of places where the system's
account of itself is wrong rather than incomplete: a recorded proof result the code cannot produce
`[EV-N-019]`, two suites whose recorded counts belong to a different commit `[EV-N-004]`, a
consolidation that misstates its own size in two documents and neither figure is right
`[EV-N-018]`, two dead probes that the census counts as classified `[EV-N-009, EV-N-017]`, a genesis
certificate bound to a commit eight behind its own tree `[EV-N-016]`, and a compose file with two
defects that its own topology proof is structurally unable to see `[EV-N-001, EV-N-002, EV-N-003]`.

None of these is hidden by intent. All of them are places where a mechanism exists, is trusted, and
does not check what it is believed to check. That is the pattern the design phase has to dominate.
