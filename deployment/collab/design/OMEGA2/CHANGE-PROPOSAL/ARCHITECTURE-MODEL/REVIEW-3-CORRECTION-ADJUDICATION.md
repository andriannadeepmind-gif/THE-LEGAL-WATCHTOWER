# REVIEW-3 CORRECTION ADJUDICATION — finding by finding, at the seat of each error class

**Governing evidence.** The external report *INDEPENDENT CANONICAL-MODEL CORE REVIEW #3 — OPTION-2 CORE @
`af0eb3c9`*, verdict `OPTION-2 CANONICAL CORE INDEPENDENT REVIEW #3 FAILED — CORRECTION REQUIRED`
(candidate `af0eb3c9…`, parent `f04bf7e6…`, tree `38b9d7c9…`). One P1, five P2, nine P3.

**Method.** Every finding was first REPRODUCED independently on a disposable copy of `af0eb3c9` and its real
before-state recorded, before anything was changed. Every closure is then a change at the SEAT of the error
class — never a guard around the reported example — and is re-verified by execution. Where a closure is
partial or absent, this document says so by name.

**What this document is not.** Not a semantic, legal, security, behavioural, operational or qualification
proof. Nothing here freezes or qualifies anything, and no verifier, kernel or model is claimed to be perfect,
sound, complete or freeze-ready.

---

## The fifteen findings

| id | pri | the class, as the reviewer stated it | the seat it was closed at | state |
|---|---|---|---|---|
| **R3-1** | P2 | the canonical commitment is injectable — a `\|` inside a value recreates "two fact sets, identical bytes" | the commitment is no longer delimiter-joined: **AMC2**, a length-prefixed canonical encoding (`enc(s) = byte-length ":" s`), specified once in `CANONICAL-ENCODING.md` and implemented independently in all three readers; `enc-01` requires the three to agree | **closed** |
| **R3-2** | **P1** | in tree-ish mode the immutable candidate is judged by the WORKING TREE's code | the acceptance command binds the machinery first — every file the model classifies `GOVERNANCE_MACHINERY` must be byte-identical in the candidate, in the executing copy and in the working tree — and then executes the whole battery from an EXPORT of that candidate. Provenance failure stops the command before any verdict | **closed** |
| **R3-3** | P2 | "pinned tools are the tools executed" measures a file and executes whatever PATH/loader supplies; the bootstrap boundary is implied, not stated | no interpreter is resolved by NAME anywhere: the command lifts the pinned absolute path out of `TOOLCHAIN.sexp` with `awk` and executes that; the toolchain check additionally verifies the RUNNING interpreter's realpath and the ACTUALLY IMPORTED solver extension against the pins; the bootstrap root is printed as an explicit external assumption | **closed** |
| **R3-4** | P2 | N-17 recurrence: a dotted plist `(fact … . BAD)` gives an unhandled `TYPE-ERROR` in the kernel | `fget` is total over improper lists, and `form-defect` names the shape ("improper (dotted) list") as a typed L1 reason on both paths | **closed** |
| **R3-5** | P2 | N-13 partially: a load whose argument is not a constant is invisible to the "real transitive closure", and the docstring promises a wildcard that does not exist | a call site the analyser cannot resolve statically is a FINDING, not an absence: `CLOSURE-BOUND: <fact-type>.<field>` and `CLOSURE-DELEGATED` are the only two ways to discharge one, each checked against the model or against the enclosing function's own parameters | **closed** |
| **R3-6** | P2 | model-controlled `:path` becomes a write to an arbitrary absolute path | one containment seat in the reader (`contained_path`) refuses absolute, `..`, empty, padded, backslash and symlink-escaping paths BEFORE any filesystem call; generation stages into a private directory and moves nothing into place until the whole generation succeeded; duplicate destinations are refused | **closed** |
| **R3-7** | P3 | coherent deletion is silent: removing a whole family — fact and implementation together — still reports a smaller success | `universe-floor` facts declare the constitutional minimum cardinality of every family; `uni-01` fails below the floor; lowering a floor requires a typed `universe-authorization` recording who decided it and against which model root | **closed** |
| **R3-8** | P3 | litter by default: 73 `aml-*` directories left in `/tmp`, three left INSIDE the audited repository under a hostile TMPDIR | one workspace seat: created 0700, removed on success, failure, signal and timeout alike; keeping it is an explicit request; a scratch root inside the repository under audit is refused before any work is done | **closed** |
| **R3-9** | P3 | the read-only metric is a proxy — blind to a CONTENT change in an untracked file — and the gate touches `.git/index.lock` | the measurement is content-sensitive: the tree the current state would commit to, plus a SHA-256 of every untracked file's bytes; every git invocation runs with `GIT_OPTIONAL_LOCKS=0` | **closed** |
| **R3-10** | P3 | no timeout on any acceptance subprocess: a hung producer is a gate that never reaches a verdict | one bounded-execution seat: every subprocess runs in its own process group with a deadline and is killed as a GROUP on expiry, raising a typed `Timeout` | **closed** |
| **R3-11** | P3 | the artifact universe sees only `.md`/`.sexp`, so `GENERATED/evil.py` is invisible to the check that promises "no extra" | the artifact check is extension-BLIND over the declared generated roots and resolves every path through the containment seat | **closed** |
| **R3-12** | P3 | a second seat with the SAME `:path` passes: "duplicate seat" only ever meant duplicate ids | `(define-unique SEAT-PATH-UNIQUE :type seat :field path)` — a schema-level uniqueness law both paths enforce | **closed** |
| **R3-13** | P3 | the kernel's accepted language is strictly wider than the spec: `#x10` reads as INTEGER 16 where the Python readers refuse it | the kernel's readtable disables the reader macros `#`, `'`, `` ` `` and `,`; all three readers now refuse `#x10` — kernel: *reader macro # is outside the canonical grammar*; checker: *symbol '#x10' is outside the canonical grammar*; reference reader: the same, with position | **closed** |
| **R3-14** | P3 | `tree_with` assumes a `.git/objects` layout and breaks under `git worktree` | the real git directory is resolved once, through `rev-parse --absolute-git-dir`, in the one runtime seat every harness uses | **closed** |
| **R3-15** | P3 | acceptance is TWO commands bound by a printed note; an operator who runs only the gate sees `pass=18` and a sentence | ONE command with two phases. Without an argument it IS acceptance: bind, export, re-run ITSELF with `--checks` from that export, then the composed-gate battery, then evidence validation, then one verdict. `--checks` is the model-check phase the composed falsifiers execute. The separate `ACCEPT.sh` was deleted, not kept as a wrapper | **closed** |

## §15 — the trusted computing base

The measurement, the exact file set and the cap are handled in `TCB-BASELINE-RECONCILIATION.md`. In summary:
the baseline at `af0eb3c9` was reconciled to **17 files / 5,544 physical / 4,577 NBNC**, the counter now has one
definition, the measurement is generated evidence in the model, and `tcb-01` re-derives it from the candidate by
FILE KIND — never by role name — and holds it under an authored cap. The measured closure is **16 files / 6,072
physical / 5,019 NBNC**, `+442` over the reviewed baseline, and every one of those 443 lines is attributed to a
named `R3-*` closure or to the shared infrastructure those closures require. The creator granted an explicit
`R3-CLOSURE-JUSTIFIED-EXCEPTION` up to 5,020 on that attribution, and the final measurement is 5,019; the historic baseline of 4,577 stands and is
not rewritten, 5,020 is now the non-growth ceiling, and the exception is expressly not evidence of quality.

## Defects this pass found in its own new machinery, and closed

* An acceptance subset reported PASS while announcing `BATTERY-VACUOUS`: the subset check matched a marker and
  never looked at the exit code. A subset now passes only when it EXITED zero, produced evidence, and its
  verdict line appears exactly once. Found by the wrapper battery, not by review.
* A classification rule that can never fire was visible only to the generator's own exit code. The gate now
  names it (`DEAD RULE`) from the classifications the committed inventory actually cites.
* The falsifier harness exported the seat alone while the gate exports the whole change-proposal subtree, so a
  generation falsifier failed for a missing source file instead of for the defect it injected — a harness
  artefact masquerading as a rejection. The harness export is now the gate's export.
* The synthetic index repository could not read the objects it indexed, which would have forced the generator to
  tolerate an unreadable tracked path — the one tolerance that lets real machinery drop out of the measured
  base unseen. It now carries an alternate to the real object store.
* The composed-gate battery inherited `AML_REPO` and `AML_CANDIDATE_TREE` from the full acceptance phase, so
  every composed falsifier injected its defect into a disposable repository and then made the inner gate judge
  the outer, unmutated tree instead. Eight falsifiers reported NOT REJECTED for defects that were never placed
  in front of a check. The inner gate now runs with `AML_*` stripped.
