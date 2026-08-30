# PHASE-1 REPORT — CURRENT-SYSTEM ARCHAEOLOGY AND EVIDENCE CLOSURE

**THE LEGAL WATCHTOWER · architecture study · Phase 1 of 1 authorised**

| | |
|---|---|
| **Source commit** | `e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03` |
| **Source tree** | `23b7a6f4450f50d151d38e13020bee9872e73bcd` |
| **Working directory** | `C:\THE-LEGAL-WATCHTOWER-NO-HOOKS` |
| **Historical baseline** | `57c0cd868c80f87df8e298c9aa75b8ccf2503391` — DeepSeek Phase-1 target, admitted |
| **Corroboration** | `2b910271f11fc462eee1378fb9a77623c791fcbf` — Claude Phase-1A, read as git objects only |
| **Generated** | 2026-08-26T00:36:43Z |
| **Worktree at start and at finish** | **clean** — `git status --porcelain` empty both times |
| **Repository mutations by this phase** | **none** |
| **Instruments built** | **none** |
| **Self SHA-256** | `9518468a02a487755ac7afff4045c77aff86001eae6535de4634c4146ef52a54` |
| **Self-hash convention** | SHA-256 of this file with the 64 hex characters on the line above replaced by 64 zeros. |

---

## 1. Preconditions

| Check | Result |
|---|---|
| `claude --version` | 2.1.246 (Claude Code) |
| Model | Claude Opus 5 (1M context), id `claude-opus-5[1m]` |
| Canonical working directory | `C:\THE-LEGAL-WATCHTOWER-NO-HOOKS` — matches |
| `git rev-parse HEAD` | `e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03` — matches |
| `git status --porcelain` | empty — clean, matches |
| `git remote -v` | `origin` → `andriannadeepmind-gif/THE-LEGAL-WATCHTOWER`; `old-origin` → `David33law/THE-LEGAL-WATCHTOWER` |

No identity differed. No branch was switched, merged, reset, pulled, committed, pushed or modified.

---

## 2. Admission of the historical baseline

**Verdict: `HISTORICAL-DEEPSEEK-PHASE1-ADMITTED`.**

All eleven required identities verified byte-exactly before any new repository reading.

| Identity | Required | Observed | |
|---|---|---|---|
| Study id | `lawmax-omega-max-deepseek-v4-v2-full` | same | ✔ |
| Real-provider Phase-1 seal | `cbcc70ee…0dc9f3` | same | ✔ |
| Historical final seal | `bba20ec1…66b9c4` | same | ✔ |
| Historical turnstore root | `c7449b0f…7eece11` | same | ✔ |
| Corpus root | `d62ab7bd…7e2e5c8` | same | ✔ |
| Historical target commit | `57c0cd86…03391` | same | ✔ |
| `CURRENT-SYSTEM-MAP.md` | `11a2e06a…dbcb54` | same | ✔ |
| `CURRENT-SYSTEM-EVIDENCE.json` | `689dc8c3…0be38c90` | same | ✔ |
| `CAPABILITY-INVENTORY.json` | `8517dbb5…7e288e9068` | same | ✔ |
| `TRUST-AND-WRITER-SEATS.json` | `141aa0d1…08f30aaf4` | same | ✔ |
| `WORKING-MEMORY.md` | `4437358a…6383e67dc871` | same | ✔ |

Coverage identities confirmed against the seal: complete enumeration (35,564 files, 0 uncovered),
reading complete, chunks complete (1202/1202), 1,000 required reads all satisfied, 536 citations
checked, 5,372 evidence-ledger lines whose SHA-256 equals the seal's `evidence_ledger_sha256`,
5,378 tool receipts.

`grounded-comprehension-v3` is `NOT_CLAIMED`: the token appears nowhere in the historical study's
state or output trees. The claim is not broadened here.

Historical Phases 2–4 are `ARCHIVAL_ONLY_NOT_ADMITTED`. Their existence was observed while listing
the workspace; no number, claim or conclusion from them entered any deliverable.

**One resolution was required and is recorded as part of the admission.** The instruction cites the
artifacts as `blind/phase-1/*`. In the workspace that subtree exists under four run directories.
Only `full/` reproduces the five required hashes; the three pilot runs produce five different
hashes each. `full/output/blind/phase-1/` is therefore the admitted subtree, and the discrimination
was made by hash, not by name.

### 2.1 A finding about the baseline itself

The admitted `CURRENT-SYSTEM-EVIDENCE.json` holds 513 records, **every one** of kind
`durable-read-coverage` with status `UNKNOWN` and a boilerplate proposition. It carries read
coverage, not substantive propositions. Meanwhile the baseline's narrative cites evidence
identifiers — `EV-1-02836`, `EV-1-02837`, `EV-1-082` — that do not occur in it; the first two
resolve only in the separately-sealed phase-1 ledger, and the third resolves nowhere
`[EV-P-005, EV-P-006]`.

Consequence for this phase: the baseline's headline pathology figures were **not** taken on trust.
The queries recorded in the sealed ledger were re-executed at the historical commit, which is what
makes them admissible here — and which is how the file-count error was found (§5).

---

## 3. Tracked-path counts by class

**35,640 tracked paths. 35,640 classified. 0 unclassified.**

| Class | Count | % |
|---|---:|---:|
| `generated_state_data` | 31,065 | 87.16 |
| `vendored_dependency` | 3,307 | 9.28 |
| `test_proof` | 390 | 1.09 |
| `first_party_source` | 346 | 0.97 |
| `documentation` | 262 | 0.74 |
| `binary_enumeration_only` | 196 | 0.55 |
| `configuration_contract` | 74 | 0.21 |
| **Total** | **35,640** | **100.00** |

By object mode: 35,559 regular files, 75 executables, 6 symlinks. The six symlinks are exactly the
per-corpus `releases/latest` pointers.

Classification was rule-based over the complete tree listing; six paths that no rule matched were
opened individually and assigned by content, so the zero is a fact and not a default.

---

## 4. First-party content coverage

| | |
|---|---|
| First-party source files at the target | **346** |
| Read line by line in this phase | **26** |
| — of which, files the delta touched | 23 (every one) |
| — of which, unchanged files re-read for cause | 3 |
| Carried on the admitted baseline's sealed complete-reading coverage | 320 |

Delta reading is **complete**: 100 of 100 changed or new paths read at the target commit —
23 first-party, 39 proofs and fixtures, 19 configuration and contract files, 11 documents,
6 generated artefacts, and 2 binary paths admitted by digest and content dump.

Ten unchanged files were re-read, each for a stated reason — three first-party
(`release-manifest.lisp` to verify the canonical-file constant independently of the runtime test;
`pdf-authority.lisp` and `blockchain-authority.lisp` to adjudicate imported claims) and seven of
other classes (`README.md`, `Dockerfile`, `Dockerfile.test`, the CI workflow,
`DEPENDENCY-CONTRACT.md`/`PROVENANCE.yaml`/`SYSTEM-HIERARCHY.txt` group, and the merkle vectors).
No file was re-read merely to claim activity.

---

## 5. The four evidence counts, separately

| | Count | What it is |
|---|---:|---|
| **1 · Admitted DeepSeek evidence** | **5,372** | Sealed phase-1 ledger lines, admitted whole by hash equality with the seal's `evidence_ledger_sha256`. Of the derived records, 513 are carried in the admitted evidence artifact, all of them read-coverage records (§2.1). |
| **2 · Claude Phase-1A corroboration** | **2,755** | `file:line` citations extracted from 25 dossiers and mechanically resolved against `e621dbe1`. **2,752 accepted**, 3 rejected. Of the 30 candidate defects in the contracts cluster, **12 were independently confirmed here** and **2 confirmed with correction**. |
| **3 · Delta-read evidence** | **84** | Evidence rows first established in this phase, each grounded in a citation to the admitted commit. |
| **4 · Rejected or corrected historical claims** | **7** | 2 evidence-level (`EV-I-006` systems/ count; `EV-P-001` bypass file count) plus 5 architectural claims invalidated by the delta, enumerated in `DEEPSEEK-PHASE1-LINEAGE.json :: invalidated_claims`. |

The evidence ledger totals **104 rows**: 73 mechanically-proved, 2 empirically-reproduced,
23 source-grounded inferences, 6 unresolved.

**Two reproductions worth naming.** The DeepSeek write-authority figure of 41 matches was
reproduced *exactly* at the historical target — and its companion file count of 18 was shown to be
wrong; the correct figure is 20, which is also the number of paths the sealed ledger record itself
enumerates. The hash-authority figure of 29 across 17 files reproduced exactly with no correction.
At the current target the same queries give 40/19 and 28/16.

**The single rejected import** is `source/capability-registry.lisp:40-207`, repeated across three
dossier revisions; the file has 206 lines. Admitted in corrected form as 40-206.

---

## 6. What Phase 1 establishes

**The system has no authority path in either direction.** Every legacy authority seat is disarmed
and fails closed — `tlog-append-root!`, `release-attested-p`, `promote-latest!` — and
`run-attest-release` is deleted rather than disabled. The admission kernel that was to replace them
is declared `:implementation-status :specification-only` and exists in no language. The store behind
it is `:absent-by-design` with its production writer `:disabled`. The service holding the private
key has, as its entire command, an error message saying so, followed by `exit 3`.

The system's own scoreboard is accurate: 0 of 13 requirements proved, 0 of 17 theorems proved, gate
`:not-passed`. Both summaries were recounted against their own rows and are arithmetically correct.

**The engineering in the delta is serious.** A capture protocol that treats the producer as an
active adversary and separates copying from measuring so strictly that "hash from hostile bytes" is
not expressible. Two structurally different Merkle implementations compared on every call. A pinned
profile digest that is live and correct. An OS boundary proof that removes every permission-based
explanation and demands `EROFS` rather than `EACCES`. A mutation witness that re-injects every past
finding and declares its three non-observable mutants with a falsifiable justification. And a
retraction: "Merkle divergence is structurally impossible" was withdrawn when a mutation erring only
at n = 18 passed all twenty-two checks.

**What Phase 1 adds beyond the system's self-assessment** is a small set of places where the
system's account of itself is not merely incomplete but wrong:

- The completion matrix records `producer-topology 24/0`. The checker emits exactly 17 assertions on
  a zero-failure run — 1 + 5 + 2 + 9, both terms fixed by the tree. **24/0 is arithmetically
  impossible**, and the collaboration record independently states 17/0 for the same run.
- Row 12 of the same matrix records suite counts that belong to the previous commit (`level7-disarm
  9/0`, `transparency-log 23/0`) while the committed suites contain 20 and 21 assertions. Row 5
  states 20/0 and 21/0. The matrix contradicts itself, and its honesty gate cannot see it: for a
  non-proved row it requires only that the result string exist and not contain `NOT-EXECUTED`.
- The `output-root` consolidation — a genuine and correct improvement — misstates its own size in
  two documents, in two different wrong ways. The idiom occurred **17** times and 17 call sites were
  added; `paths.lisp:145` says five and `dialogue/0125-claude.md` says thirteen.
- Two proof probes have no caller anywhere in the tree and call a symbol the same delta deleted. The
  census counts both as classified, because its `helper` mode exists precisely to allow that.
- The genesis certificate binds a commit eight behind its own tree, and nothing reads the field back.
- The compose file carries a malformed tmpfs option on the service the documentation tells operators
  to run, and the ingestion service lost the command that makes it ingest. The topology proof catches
  neither, because it validates roles and mounts and never looks at commands.
- Hermetic construction is asserted in three contracts and refuted by four `apt-get update` calls in
  the Dockerfile, one of them in the final runtime stage.
- A declared gate — GATE-4, "no subprocess" — exists only as a table row, while the file that denies
  launching subprocesses launches five and the runtime image installs the binaries it calls.

**The pattern.** Every false green found here came from a verifier that chose its own scope: the
topology proof looked at one service, the census looked at one glob, the classification looks at
three file extensions, the matrix gate looks for one literal string. The delta explicitly fixed the
first two — and reintroduced the third. That is the structural obligation the design phase inherits.

---

## 7. Unresolved obligations

**29 obligations** are recorded in `DEFECT-AND-GAP-OBLIGATIONS.json`, each bound to a defect and each
carrying a dominance test the successor architecture must satisfy. The load-bearing ones:

| | Obligation |
|---|---|
| OBL-01 | Supply a working, verifiable authority path. A specification no code realises does not discharge what the disarmament created. |
| OBL-02 | Discharge the blocked proofs or replace the claim with one dischargeable using tools that exist. "Blocked on an absent toolchain" may not be a load-bearing requirement's terminal state. |
| OBL-03 | Make the build match its hermeticity contract, or withdraw the contract. |
| OBL-04 | Bind recorded results to the code they describe, and let the honesty gate reject a result whose tree identity does not match. |
| OBL-09 | Every declared gate must have an implementation or be withdrawn. |
| OBL-13 | Audit GATE-1, GATE-2, GATE-3 and GATE-5 as GATE-4 was audited. Only GATE-4 was checked exhaustively. |
| OBL-22 | Make the capability register cover the authority architecture. A plenary that cannot fail on an authority defect is not a plenary. |
| OBL-23 | Decide what the 24 published releases are — evidence, or law. They satisfy nothing and are served as though they satisfied everything. |
| OBL-25 | Obtain one independent execution before any recorded number is treated as evidence. |
| OBL-26 | Repair the baseline's evidence discipline: every substantive claim must resolve inside the artifact set that carries it. |

**Six unresolved evidence items** (`EV-U-001` … `EV-U-006`): whether any recorded proof execution
happened as recorded; whether `docker build` succeeds today; whether the capture implementation
withstands its adversarial suite; whether the published corpus is correct as Greek law; the
baseline's eleven inherited static-analysis limitations; and the unreconciled os-exec seat count
(seven observed against nineteen declared).

**Residual set** — stated exactly, not estimated: 3,307 vendored files by manifest and hash;
31,065 generated files by enumeration and digest with the load-bearing ones read in full;
196 binary files by digest; 320 unchanged first-party files on the sealed baseline coverage;
four unaudited README gates; the substantive claims of 22 corroboration dossiers whose citations
were resolved but whose assertions were not adjudicated; and all runtime behaviour.

**Full comprehension is not claimed.** Enumeration is complete and delta reading is complete.
Content comprehension is not, and the residual above is the exact boundary.

---

## 8. The nine deliverables

Directory: `C:\THE-LEGAL-WATCHTOWER-STUDY-OUTPUT\phase-1`

| # | File | Bytes | SHA-256 |
|---|---|---:|---|
| 1 | `DEEPSEEK-PHASE1-LINEAGE.json` | 20,069 | `a66630cfc800992a9707d62b2f339abce29641b915ba50068379d9d7e8276720` |
| 2 | `TRACKED-PATH-INVENTORY.json` | 7,698,098 | `40aa49aec12221ed9aaac4e38ea7cf9c3ad171ee51443dd42366921841ee5f1a` |
| 3 | `CURRENT-SYSTEM-MAP.md` | 21,712 | `3bfa07860c04846231606391d1ce9bacd3cd6bd22d195f8e68982e77042e8bcd` |
| 4 | `CAPABILITY-REGISTER.json` | 19,237 | `bd3eee2e24d0d7298f6a7f34b307e57af27cd38933f2dfda9e421619e9179514` |
| 5 | `TRUST-AND-AUTHORITY-MAP.md` | 17,463 | `5880ea6b98a1099cf4765c09bc20010b46fd368bd118f98eb4df62c2f58e81a5` |
| 6 | `DEFECT-AND-GAP-OBLIGATIONS.json` | 24,461 | `258469b0d829d8fd46f8fd7c1241694a941467bbf67ed8c03cfbdf822bf7ef43` |
| 7 | `EVIDENCE-LEDGER.tsv` | 43,737 | `6e14a2d5137696db2371abd0ca668efd40de7bff62ad85e6cc96ac045ec7e197` |
| 8 | `PHASE-1-COVERAGE.json` | 8,784 | `8ad598878ffff4f65690497b378e19a3b4abfbe1b8976ac2e3b1eebb42c06e30` |
| 9 | `PHASE-1-REPORT.md` | this file | see the header |

Each deliverable carries its source commit, generation time, coverage counts, evidence classes,
unresolved items and its own SHA-256 under a stated, reproducible convention: hash the file with the
64 hex characters of the self-hash field replaced by 64 zeros. The substitution is
length-preserving, so verification is a one-line operation. All eight self-hashes were recomputed
and reproduce.

---

## 9. Cross-checks performed between deliverables

| Check | Result |
|---|---|
| Inventory class counts = report §3 = coverage file | agree |
| Inventory total = 35,640 = `git ls-tree` entry count | agree |
| Ledger row count = coverage `evidence_ledger.rows` = 104 | agree |
| Ledger class histogram = every deliverable header | agree |
| Every `EV-` identifier cited in the three Markdown files exists in the ledger | verified |
| Every defect's `evidence` list resolves to ledger rows | verified |
| Every defect's `obligation` resolves to an obligation id, and every obligation's `from_defect` resolves back | verified |
| Delta path count in lineage = coverage = 100 = `git diff --name-status` | agree |
| Capability count 36 = register = declaration-site enumeration | agree |
| Gate bijection 25 ↔ 25 stated identically in register and map | agree |
| All eight self-hashes recompute under the stated convention | verified |

---

## 10. Termination

The nine deliverables are complete and internally cross-checked.

The repository worktree is **clean**. `git status --porcelain` is empty. No tracked or untracked file
inside `C:\THE-LEGAL-WATCHTOWER-NO-HOOKS` was created, modified or deleted by this phase. All study
artifacts were written under `C:\THE-LEGAL-WATCHTOWER-STUDY-OUTPUT\phase-1`. The Claude Phase-1A
branch was never checked out; its dossiers were read as git objects, and neither its
`.claude/settings.json` nor any of its hooks was read or executed. Nothing was executed at all: no
proof, no gate, no test, no build, no canary. Instrument-building budget spent: zero — the only
scripts written were a path classifier, a citation resolver and the deliverable generators, all of
which analyse git objects and none of which is a component of anything.

No replacement architecture is proposed here. That is the design phase's work, and it must dominate
the 29 obligations recorded in `DEFECT-AND-GAP-OBLIGATIONS.json`.

**Phase 2 has not been started.** No design agent was spawned, no canary was run, no code was
modified. Awaiting a separate creator instruction.
