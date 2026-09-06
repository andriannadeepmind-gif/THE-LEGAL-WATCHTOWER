# REVIEW-4 CORRECTION ADJUDICATION — finding by finding, at the seat of each error class

**Governing evidence.** The external report *INDEPENDENT REVIEW #4 — TARGETED VERIFICATION OF THE REVIEW-3
CORRECTION @ `cc52a27d`*, verdict `OPTION-2 INDEPENDENT REVIEW #4 FAILED — CORRECTION REQUIRED — DDI-1 BLOCKED`
(candidate `cc52a27d…`, parent `a87bb6b7…`, tree `aacec2f0…`). One verifier-blocking P2, one non-blocking P2,
five P3. The reviewer confirmed the Review-3 P1 dead, reproduced every headline number with independent code,
and corrected an undercount in their own review #3; the record here is about what they found still open.

**Method.** R4-1 and R4-2 were reproduced on disposable exports before anything changed (the coherent shrink
passed `universe` and `corpus` with 5 families and 75 cases; the absent pinned tool produced a `FileNotFoundError`
traceback). Every closure is a change at the SEAT of the error class and is re-verified by execution.

**What this document is not.** Not a semantic, legal, security, behavioural, operational or qualification proof;
nothing here freezes or qualifies anything; no verifier, kernel or model is perfect, sound, complete or
freeze-ready.

---

## The seven findings

| id | pri | the class, as the reviewer stated it | the seat it was closed at | state |
|---|---|---|---|---|
| **R4-1** | **P2 blocking** | R3-7 not closed: a coherent shrink — the floor and the family member deleted together — passes `uni-01` and `cor-01`, 83 cases become 75, every check reports success. The floor that guards the universe is itself unguarded | the reference frame is now **history the candidate cannot edit**. `uni-01` reads the floors, the authorizations and the schema of the BASE COMMIT from the repository's objects and requires every base family to keep a floor ≥ the base's; a floor lowered, deleted or renamed away is `UNIVERSE-FLOOR-REDUCED`. The base is canonical, with no fallback: a commit candidate's unique first parent, or an explicit `--base <full SHA>` for a working-tree or export candidate; zero or several parents, a contradicting explicit base, or an absent base object are typed failures (`UNIVERSE-BASE-AMBIGUOUS`, `-MISMATCH`, `-UNSPECIFIED`, `-UNAVAILABLE` with the exact object a bounded fetch needs). `cor-01` reconciles the implemented counts against the floors (`CORPUS-BELOW-FLOOR`). Candidate and base commit/tree/model-root are printed | **closed** |
| **R4-1 §3** | — | no candidate self-authorization | a reduction stands only on a **base-anchored prospective authorization**: committed in the base, naming the family, recording the base's floor as its previous minimum, naming the model root the approver reviewed (the base's parent's root — a base's own root cannot contain a fact that states it), carried unchanged into the candidate, granting exactly its stated minimum. It is spent once the floor has moved (replay fails on the previous minimum). One that appears only in the candidate is `AUTHORIZATION-CANDIDATE-INJECTED`; one altered or dropped is `AUTHORIZATION-TAMPERED`. No external approval mechanism exists in this repository and none was invented | **closed** |
| **R4-2** | P2 | a missing pinned tool is a Python traceback, not the promised typed refusal | the **common execution seat** turns every spawn failure into a typed `ToolUnavailable` with a closed reason — `TOOLCHAIN-MISSING` (ENOENT, broken symlink, vanished between pre-check and spawn), `TOOLCHAIN-UNEXECUTABLE` (EACCES, EPERM, ENOEXEC, EISDIR, not a regular file), `TOOLCHAIN-SPAWN-FAILED` (anything else); `tool_defect` pre-checks existence, regular file, readability and execute permission; the toolchain check fails on any defect BEFORE any probe runs; every seat program prints the typed line and exits non-zero. The falsifier harness now rejects any case whose output carries a traceback, whatever the exit code | **closed** |
| **R4-3** | P3 | three workspaces survive a SIGTERM to the acceptance command | the runtime seat keeps an exact registry of the children IT started and terminates them as process groups on SIGINT/SIGTERM/SIGHUP before removing its own workspace; the command launches every child phase as a job in its own process group and, on a signal, forwards it to exactly the group it is waiting on. No glob over a scratch root, no other run's directories. Nothing is claimed for SIGKILL | **closed** |
| **R4-4** | P3 | `.git/index.lock` is still taken, against "every git invocation" | one seat forces `GIT_OPTIONAL_LOCKS=0` on **every** git subprocess started through the execution seat — overriding whatever was inherited — and the command exports it for the whole process tree; the four direct `subprocess.run` git calls that bypassed the seat were routed through it. Verified under a hostile inherited `GIT_OPTIONAL_LOCKS=1` with strace: zero `.git/index.lock` creations | **closed** |
| **R4-5** | P3 | schema version "3" at both `af0eb3c9` (AMC1, 26 types) and `cc52a27d` (AMC2, 32 types); "bound by construction" overstated | the schema is now version **4**; `uni-01` requires that whenever `MODEL-SCHEMA.sexp` differs byte-wise from the base's, the version is an integer strictly greater than the base's (`SCHEMA-VERSION-STALE` otherwise); `CANONICAL-ENCODING.md` §2.1 now states the truth: the model root binds the schema's bytes, the version is an enforced policy discriminator, and no claim is made that the number alone is a cryptographic identity | **closed** |
| **R4-6** | P3 | three record statements do not match the repository | corrected in this seat's living documents: the transient `ACCEPT.sh` was never tracked and was not "deleted from a commit"; the Review-3 additions were 8 in the seat plus 1 dialogue record outside it; the delta was +442, not 443. The append-only dialogue entry and index row stay as written and are corrected explicitly in dialogue 0164. "Fact types" is now two numbers, both generated into the packet: schema-declared and instantiated, with the declared-but-uninstantiated types named | **closed** |
| **R4-7** | P3 | `ro-02` can never fire in the real path | removed. `ro-01`'s measure is the working-tree candidate tree plus a hash of every untracked file's bytes; `ro-02` compared that same tree before and after — a strict subset that could not fail alone and killed no mutation `ro-01` does not kill (G01 targets `ro-01`). The counted checks are **21 OPTION-2 ACCEPTANCE CHECKS — NOT THE ORIGINAL 20 OPTION-A FULL-BUILD GATES**, which remain a mandatory future stage after DDI-1…DDI-4. (The order anticipated 20: it assumed `ro-02` had been counted in the canonical path. It had not — that was the finding — so removing it leaves the 21 the reviewer counted, and the command prints the live number rather than a literal) | **closed** |

## The numeric TCB ceiling, withdrawn

By the creator's order the numeric ceiling is no longer a pass/fail condition. `tcb-01` is an accountability
gate: exact file universe by kind, real measurement, per-file delta against the verified baseline (its rows are
authored `tcb-baseline` facts), and every growth attributed to a reproduced finding (`tcb-attribution`,
validated against the closed `finding-id` enum). The total is a measured fact and a complexity signal. Nothing
was removed, compressed or weakened to change a number. See `TCB-BASELINE-RECONCILIATION.md` §10.

## The fact-type reconciliation (R4-6)

| | `af0eb3c9` | `cc52a27d` | this correction |
|---|---:|---:|---:|
| schema-declared fact types | 26 | 32 | 34 |
| instantiated fact types | 26 | 31 | 33 |
| enums | 15 | 17 | 18 |
| modules | 13 | 14 | 14 |

The one type declared but never instantiated is `universe-authorization`, in every state that declares it: the
mechanism exists so that a reduction CAN be authorised, and no reduction has been authorised. The reviewer's
"33 fact types" for `cc52a27d` (R4-5) disagreed with their own "32" (§2); 32 is the declared count, 31 the
instantiated one. The decision packet now prints both, generated from the model.

## Falsifiers added for this pass (all data, except the two that need a process)

`X54` growth unattributed · `X61`–`X70` the coherent-shrink and authorization cases (lowered with member,
deleted with family, renamed away, wrong previous root, other family, replay, candidate-injected, valid
base-anchored **positive control**, floor-set weakened, corpus below effective floor) · `X71`–`X73` missing,
non-executable and vanished-before-spawn tools · `X74`–`X76` schema changed with the version same, lower, and
raised (**positive control**) · `X77`–`X78` unknown finding id, inconsistent baseline rows · `G09`–`G10` the two
critical shrinks through the REAL top-level command · `G11` SIGTERM to one of two concurrent runs. The falsifier
floor rises from 59 to 80.
