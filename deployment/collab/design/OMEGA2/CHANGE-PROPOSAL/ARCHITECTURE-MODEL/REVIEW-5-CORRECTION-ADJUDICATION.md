# REVIEW-5 CORRECTION ADJUDICATION — finding by finding, at the seat of each error class

**Governing evidence.** The creator's *FINAL R5 SYSTEMIC CLOSURE ORDER* over candidate `4ee2b58a…` (unique
parent `cc52a27d…`, tree `ad71185a…`), issued on the independent review #5 whose verdict was
`OPTION-2 INDEPENDENT REVIEW #5 FAILED — CORRECTION REQUIRED — DDI-1 BLOCKED`. The order names the report
`REVIEW5.md`; that file was not among the session's uploads (the uploads directory holds the first review,
REVIEW2, REVIEW3 and REVIEW4 only), so the order's own enumeration of the findings — R5-1 with its two
reproducers C1/C2, R5-2, the duplicate floor, the wrong `candidate_commit`, and the seven P3 items of its §5 —
is the text this correction was judged against. The P3 items are identified here as `R5-P3-1` … `R5-P3-7` in
the order the closure order lists them. If the report is later attached, this record is to be reconciled
against it, not rewritten.

**Method.** Every before-state was reproduced on disposable copies BEFORE anything changed, and recorded:
a two-commit clone in which C1 (every `universe-floor` moved to `seats.sexp`, values unchanged) passed
`universe` and `corpus`, and C2 on top of it (five floors deleted, a property family and a falsifier removed
coherently) ALSO passed both — `1 floored families … (tool>=5)`, `4 property families totalling 75 generated
cases, and 79 falsifiers`; a WORKTREE candidate accepted `--base af0eb3c9…` (two commits back) as its base;
a duplicate `universe-floor` for `fixture` whose last row silently became the effective floor; `provenance`
printing `candidate_commit 4ee2b58a…` (HEAD) for the candidate `cc52a27d…`. Each closure is a change at the
SEAT of its error class and is re-verified by execution.

**What this document is not.** Not a semantic, legal, security, behavioural, operational or qualification
proof; nothing here freezes or qualifies anything; no verifier, kernel or model is perfect, sound, complete or
freeze-ready; no independent human approval is proven by any PASS below.

---

## The findings

| id | pri | the class, as the order states it | the seat it was closed at | state |
|---|---|---|---|---|
| **R5-1** | blocking | history was read by FILENAME: `base_facts(…, "verification-corpus.sexp", …)`, so a floor relocated to another canonical module vanished from the base's view and C2 deleted five floors after C1 had moved them — every check green | ONE historical load, `read_model_at(commit)` (`gate_checks.py`), built on the ONE reader core `SEXP-READER.read_model_from(load, source, verify)`: it reads the commit's `ROOT.sexp`, takes the exact module universe from it, verifies module set, SHA-256 pins, root digest (one formula, `SR.root_digest`, shared with `build_root.py` and the corpus rehash), the root's schema version against the schema's, refuses duplicate modules, duplicate facts and undeclared fact types, and yields every fact of every module by type. `SR.universe_floors` / `SR.universe_authorizations` discover the universe facts across the whole model — of the base and of the candidate alike — never by module name. Exactly one active floor per family (`UNIVERSE-FLOOR-DUPLICATE`, never last-write-wins), the family must be a schema-declared type (`UNIVERSE-FLOOR-FAMILY-UNDEFINED`), and `UF-UNIVERSE-FLOOR` floors the floor set itself (`UNIVERSE-SELF-FLOOR-MISSING` when absent). The corpus runner's own integrity pre-check discovers floors, authorizations, fixtures, families and falsifiers from the model, not from one file | **closed** — C1 passes, C2 fails through `uni-01` (`G12`, through the real command) |
| **R5-2** | blocking | `--base` was a free chooser of history for a WORKTREE candidate | `resolve()` in `gate_checks.py` derives candidate and base from what was named and the repository alone: a commit has exactly one parent, which is the base (`UNIVERSE-BASE-ORPHAN`, `UNIVERSE-BASE-AMBIGUOUS` otherwise, and no `--base` can choose); WORKTREE whose tree differs from HEAD's is the candidate with HEAD as base; WORKTREE equal to HEAD's tree IS HEAD with HEAD's unique parent as base; a bare tree is `CANDIDATE-NOT-COMMIT`; `--base` is a confirmation, `UNIVERSE-BASE-MISMATCH` when it differs, whatever it names; `--tree` is a verified hint (`CANDIDATE-TREE-MISMATCH`). The base object is checked for presence (`UNIVERSE-BASE-OBJECT-MISSING`, naming the exact bounded fetch; no network access, no other base), type (`UNIVERSE-BASE-NOT-COMMIT`) and seat (`UNIVERSE-BASE-SEAT-MISSING`). Every check invocation re-derives it (≈0.05 s); the command passes the candidate identity, never a tree, to its phases; the corpus runner presents synthetic candidates as commits over their bases; the inner gate of a composed case derives its own base | **closed** |
| **R5-1 dup** | — | duplicate `universe-floor` for one family silently last-write-wins | `UNIVERSE-FLOOR-DUPLICATE` in the one discovery seat, for base and candidate alike (`X91`) | **closed** |
| **R5-P3-1** | P3 | `uni-01 PASS` hid what it compared | the check prints `UNIVERSE-BASE-FLOORS`, `UNIVERSE-CANDIDATE-FLOORS`, `UNIVERSE-REDUCTIONS`, `UNIVERSE-AUTHORIZATIONS-CONSUMED` and `UNIVERSE-AUTHORIZATIONS-PROSPECTIVE` as separate lines before its verdict (`X87`) | **closed** |
| **R5-P3-2** | P3 | schema version accepted whatever Python's `isdigit`/`int` accepted; a dead `SCHEMA-VERSION-UNMOTIVATED` branch | one rule in the reader seat, `SR.schema_version_of`: a quoted ASCII decimal string matching `[1-9][0-9]*`; an unquoted integer, a leading zero and a non-ASCII digit are `SCHEMA-VERSION-MALFORMED` (`X96`–`X98`), in the gate and in `build_root.py` alike. The dead branch is deleted: a byte-identical schema carries an identical version by construction | **closed** |
| **R5-P3-3** | P3 | the Review-4 bookkeeping reported 22 paths in the seat | 23 paths inside `ARCHITECTURE-MODEL/`, 3 outside (`AI-DIALOGUE.md`, `STATE-OF-PLAY.md`, `dialogue/0164-claude.md`), 26 in total; recorded here and in dialogue 0165 — the append-only 0164 record stands as written | **closed** |
| **R5-P3-4** | P3 | no permanent falsifier for `candidate_tree()` | `X79`: a synthetic commit over the candidate tree resolves to that tree and to that commit, never to the commit id as tree | **closed** |
| **R5-P3-5** | P3 | `provenance` printed HEAD whatever the candidate was | `PROVENANCE candidate_commit` prints `WORKTREE` (and the computed tree, labelled so) when the working tree is judged, the named commit when one was named, and `<sha> (HEAD)` only when the candidate IS HEAD | **closed** |
| **R5-P3-6** | P3 | two raw `subprocess.run` git calls in `build_inventory.py` | both routed through `acceptance_runtime.bounded_run`; `subprocess` is no longer imported there | **closed** |
| **R5-P3-7** | P3 | "every line attributed" overstated a per-file mechanism | every wording now says per-file attribution: a grown FILE names the findings that required its growth; there is no per-line mapping and none is claimed | **closed** |

## Authorization semantics, stated honestly (§4)

An authorization is honoured only when it is BASE-ANCHORED: present in the base's model (wherever it lives),
naming this family, recording the base's floor as `previous-minimum`, a smaller `minimum`, the model root the
approver reviewed (`previous-model-root` = the root of the base's parent), a non-empty `approver` and
`rationale`, and carried into the candidate with its content unchanged (its module may differ — discovery is
by type). It grants exactly `minimum`. It is consumed on THIS EDGE: once the floor it names has moved, it no
longer applies (`X66` replay fails). That consumption is per-lineage, per-edge, not global: two sibling
candidates of the same base can each cite the same authorization mechanically, and only the Root Authority
decides which sibling acquires canonical standing — the gate makes no such choice and proves no independent
human approval; `approver`/`rationale` attribute a decision, they are not a cryptographic or externally
validated approval. An authorization that exists only in the candidate authorises nothing on this edge
(`AUTHORIZATION-CANDIDATE-INJECTED` when the same candidate reduces that family) but may be INTRODUCED,
well-formed and prospective, to authorise the next edge (`X100`, positive control; a malformed one is
`AUTHORIZATION-MALFORMED-PROSPECTIVE`). No external approval mechanism exists in this repository and none was
invented.

## Candidate/base semantics (§2, §3)

| named | candidate | base |
|---|---|---|
| a commit with one parent | that commit's tree | its unique parent (`--base` must equal it) |
| a commit with 0 / ≥2 parents | — | `UNIVERSE-BASE-ORPHAN` / `UNIVERSE-BASE-AMBIGUOUS`, with or without `--base` |
| WORKTREE, tree ≠ HEAD's | the working tree (computed through a throwaway index) | HEAD |
| WORKTREE, tree = HEAD's | HEAD | HEAD's unique parent |
| a bare tree object | `CANDIDATE-NOT-COMMIT` | — |
| base object absent / not a commit / without `ROOT.sexp` | — | `UNIVERSE-BASE-OBJECT-MISSING` (exact `git fetch --depth=1 <remote> <sha>` named; no network access, no other base) / `-NOT-COMMIT` / `-SEAT-MISSING` |

A sequence of commits is judged EDGE BY EDGE — every commit against its own unique parent, none skipped; the
last independently reviewed commit is the procedural anchor of the next judgement. Because a WORKTREE candidate
is re-derived by every check, a working tree edited DURING a run is a typed refusal (`CANDIDATE-TREE-MISMATCH`)
rather than a silent judgement of a stale tree.

## The TCB decision (§6)

The creator's binding decision is recorded verbatim in the canonical model, in the `:rationale` of
`tcb-budget ACCEPTANCE-TCB` (`verification-corpus.sexp`), and `TCB-DECISION.md` §7 points to it. Measured at
the end of this correction by `tcb-01`: **16 files / 7,079 physical / 5,866 NBNC — +446 NBNC over `4ee2b58a`, +1,289 over the verified baseline `af0eb3c9` (run_corpus +239, SEXP-READER +118, gate_checks +97, the command +1, build_root −9; every other file unchanged). Per-file attribution: `TCB-BASELINE-RECONCILIATION.md` §11**. Every grown file carries a `tcb-attribution` naming the
Review-5 findings that required it.

## Falsifiers added (all data except the ten that need a process or a history)

Data: `X88` floors relocated (PASS control) · `X89` base floors relocated, one lowered · `X90` self-floor
deleted · `X91` duplicate floor · `X92` authorization relocated and consumed (PASS control) · `X93` wrong
previous minimum · `X94`/`X95` empty approver / rationale · `X96`–`X98` unquoted, leading-zero, non-ASCII
version · `X99` undefined family · `X100` prospective authorization introduced (PASS control) · `X101`
self-floor lowered against a base carrying it. `X63` now renames to a DECLARED family (the undeclared rename is
`X99`). Coded: `X79` tree-not-commit-id · `X80` arbitrary WORKTREE base · `X81` base not the parent · `X82`
merge · `X83` orphan · `X84` WORKTREE ≠ HEAD ⇒ base HEAD · `X85` WORKTREE = HEAD ⇒ HEAD, base parent · `X86`
depth-1 clone: typed refusal then PASS after fetching exactly the named object · `X87` floors reported
separately · `G12` the two-commit C1→C2 reproducer through the real command. The falsifier floor rises from 80
to 104. Results: **pre-flight before-states reproduced and recorded; the Review-5 cases with the Review-4 universe / authorization / schema cases, 36 in all, REJECTED as intended after two case corrections (`X63` renamed to a declared family because the undeclared rename now fails earlier as `UNIVERSE-FLOOR-FAMILY-UNDEFINED`; `X101` anchored to a synthetic base that carries the self-floor, since this edge's real base predates it) and one redesign (`X87` first raised a tight floor and was rightly refused with `UNIVERSE-BELOW-FLOOR`; it now adds a floor); the full COMPONENT battery **92/92** in 4 min 33 s; the affected COMPOSED cases — control HOLDS, `G01` (its gate marker moved), `G09`, `G10`, `G12` — **4/4** in 35 min; one full canonical acceptance on the exact committed tree, base derived as `4ee2b58a`: **PASS — 4/4 subsets, 21 checks / 0 FAIL, 92/92 COMPONENT + 12/12 COMPOSED_GATE, control HOLDS**. One observation worth recording: cases run while the working tree was being edited were refused with `CANDIDATE-TREE-MISMATCH` — the per-check re-derivation refusing to judge a tree that had moved under it, which is the intended behaviour, not a defect**.
