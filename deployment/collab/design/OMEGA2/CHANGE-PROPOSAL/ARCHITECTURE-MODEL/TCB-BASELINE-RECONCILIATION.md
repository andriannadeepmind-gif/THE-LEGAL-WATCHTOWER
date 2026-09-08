# TCB-BASELINE-RECONCILIATION — what the acceptance trusted computing base at `af0eb3c9` actually was

**Scope.** One bounded question, decided once, recorded here: *which files formed the acceptance execution
closure of the candidate `af0eb3c9`, how many lines were they, and why did independent review #3 report
`16 executable files, 5,544 physical, 4,440 non-blank/non-comment` while the seat's own accounting reported a
different pair?* This document reconciles two measurements of the same commit. It is **not** a security proof,
not a semantic or legal proof, and it does not qualify or freeze anything.

The reconciliation was performed on a **clean disposable checkout of `af0eb3c9`** (`git archive af0eb3c9 <seat>`
extracted into a private workspace outside the repository), not on the working tree and not on the summary.

---

## 1. The one counting rule

Both the baseline and every later measurement use **exactly one** rule, implemented in exactly one place
(`gate_checks.py tcb`, which is executed by the top-level acceptance command and which emits the file set and
the counts as evidence):

* **Physical lines** — the file's bytes decoded as UTF-8 and split on `\n`; a single trailing empty element
  produced by a final newline is dropped. This is `wc -l` for a file that ends with a newline.
* **NBNC lines** — of those physical lines, the ones whose whitespace-stripped form is non-empty and does not
  begin with the file's line-comment marker: `;` for `.lisp`, `#` for `.py` and `.sh`.
* **No other exclusion.** Docstrings, blank-but-for-a-string lines, shebangs, `else:` and closing brackets all
  count. Nothing is excluded for being "boilerplate", and no line may be packed to lower the number.

Checked on the disposable checkout: no file carries a BOM, no file uses CRLF, and no file lacks a final
newline — so no counting variant that depends on those artefacts can change the totals.

---

## 2. The acceptance execution closure at `af0eb3c9`, path by path

The **top-level acceptance command** at `af0eb3c9` is `ARCHITECTURE-MODEL-GATE.sh`. Its check
`doc-03-governance-closure-declared-and-historic-free` (`gate_checks.py dependency-closure`) takes **every**
path the model classifies `GOVERNANCE_MACHINERY`, parses its source, computes the transitive seat-local closure,
and fails the gate if any member of that closure is undeclared or is classified `HISTORICAL_EVIDENCE`. Membership
of this set is therefore not a naming convention: a file in it is read by the acceptance command and can, by its
own bytes, turn the verdict from PASS to FAIL.

Counting rule for every row: §1. `phys` = physical, `nbnc` = non-blank/non-comment.

| path | in the acceptance execution closure because | phys | nbnc | rule | started by the top-level command? | can change candidate / evidence / verdict? |
|---|---|---:|---:|---|---|---|
| `ARCHITECTURE-MODEL-GATE.sh` | it **is** the top-level acceptance command | 147 | 94 | §1 | it is the command | yes — it issues the verdict |
| `gate_checks.py` | started by the gate for 12 named checks | 977 | 853 | §1 | yes | yes — every check verdict |
| `SEXP-READER.py` | the one reader seat; loaded by the gate checks, every producer and the checker | 288 | 235 | §1 | yes (loaded) | yes — every fact read |
| `CHECKER/independent_check.py` | the ASP verification path; started for `ver-01` and `hsh-01` | 602 | 525 | §1 | yes | yes — one of the two path verdicts |
| `KERNEL/model-law-kernel.lisp` | the Lisp verification path; started via `sbcl --script` | 361 | 333 | §1 | yes | yes — one of the two path verdicts |
| `KERNEL/hash-provider.lisp` | loaded by the kernel; the Lisp path's only digest seat | 109 | 67 | §1 | yes (loaded) | yes — every Lisp-path digest |
| `build_inventory.py` | regenerated and byte-compared by `inv-01`; also imported by the falsifier battery | 329 | 280 | §1 | yes | yes — the classified universe |
| `build_root.py` | regenerated and byte-compared by `gen-02`; re-pins every module | 99 | 78 | §1 | yes | yes — the model root digest |
| `build_deferred.py` | started by the gate as `--verify` for `led-01` | 258 | 218 | §1 | yes | yes — the ledger verdict |
| `generate_views.py` | regenerated and byte-compared by `gen-02` | 215 | 185 | §1 | yes | yes — eight generated artifacts |
| `build_decision_packet.py` | regenerated and byte-compared by `gen-02`; reconciled by `doc-02` | 237 | 180 | §1 | yes | yes — the operator packet |
| `run_fixtures.py` | started by the gate for `fix-01` | 276 | 228 | §1 | yes | yes — the fixture verdict |
| `run_falsifiers.py` | started by the gate for `fls-01`; its own bytes are compared to the candidate blob by `fls-00` | 928 | 741 | §1 | yes | yes — the component-falsifier verdict |
| `run_gate_falsifiers.py` | the composed battery: it *executes the gate*, so the gate cannot execute it (recursion); the model declares it as a harness and `cor-01` asserts its declared falsifiers exist | 334 | 273 | §1 | no — it runs the gate | yes — `cor-01`, and it is an acceptance battery in its own right |
| `regenerate.py` | never called by the gate (it is the apply command), but it is a declared `GOVERNANCE_MACHINERY` entrypoint: `doc-03` parses it and asserts its closure | 97 | 81 | §1 | no | yes — `doc-03` fails on its content |
| `SETUP-TOOLCHAIN.sh` | provisioning, never called by the gate; classified `GOVERNANCE_MACHINERY` by name in `R-003`, so it enters `doc-03`'s computed closure and `inv-01`'s universe | 115 | 70 | §1 | no | yes — `doc-03`, `inv-01` |
| `build_model.py` | **the 17th file.** The one-time migration that emitted the model. Never started by the gate and nothing imports it — but at `af0eb3c9` `R-003` classifies it `GOVERNANCE_MACHINERY`, so `doc-03` takes it as an entrypoint, parses it and asserts its transitive closure; a change to its imports fails the gate with `CLOSURE-UNDECLARED` | 172 | 136 | §1 | no | **yes — `doc-03` reads its source and can fail on it** |
| **TOTAL — 17 files** | | **5,544** | **4,577** | §1 | | |

**Nothing is excluded.** No row was dropped for being called a migration, a helper, a fixture or a generator.
The exclusion test authorised by the creator — *"a real one-time migration tool that is never executed and never
affects acceptance, candidate, evidence or verdict"* — has two conjuncts, and `build_model.py` satisfies only the
first: it is never started, but `doc-03` reads its bytes and can fail the gate on them. It therefore stays in the
count. (Re-classifying it would not change this: as `HISTORICAL_EVIDENCE` it is still read by `doc-03`, which
then fails if it is *reachable*. Either way its bytes reach a verdict.)

---

## 3. The three questions, answered exactly

**(a) Which is the 17th file?** `build_model.py` — 172 physical, 136 NBNC.

**(b) Why do the physical totals appear identical?** Because they *are* the same measurement: **5,544 physical is
the 17-file total**, exactly, and no 16-file subset can reach it (every file has a positive line count, so any
16-file subtotal is strictly below the 17-file total). Independent review #3 reported `16 executable files` beside
a physical figure computed over 17. The identity of the physical numbers is therefore not a coincidence and not a
different rule — the review's physical total is the full closure, and only its *file count* and its *NBNC* total
were taken over a reduced set.

**(c) Where do the 137 NBNC lines come from?** They decompose exactly, with no residue:

```
4,577   full 17-file closure at af0eb3c9 (rule §1)
 -136   build_model.py, absent from the review's NBNC set
-------
4,441   16-file total (rule §1) — reproduced on the disposable checkout
   -1   review §13 quotes the Lisp path as "399-400 SLOC" and totals it at its LOWER bound;
        the executed value is 400 (the gate's own ver-02 prints "400/400")
-------
4,440   the figure reported by independent review #3
```

The review's own §13 breakdown confirms the decomposition. Measured against the same files:

| review §13 term | review | measured | agrees |
|---|---:|---:|---|
| gate | 94 | 94 | yes |
| `gate_checks` | 853 | 853 | yes |
| `SEXP-READER` | 235 | 235 | yes |
| runners (3) | 1,242 | 1,242 | yes |
| setup | 70 | 70 | yes |
| checker path | 525 | 525 | yes |
| Lisp path | "399-400" | 400 | lower bound taken |
| producers | 823 | 1,022 | **no — short by 199** |

`94 + 853 + 235 + 1,242 + 1,022 + 70 + 525 + 400 = 4,441`, and the same sum with the Lisp path at 399 is
**4,440** — the review's headline figure, reproduced to the line. The review's `producers 823` term is the one
internally inconsistent number: it understates the six producers by 199, which is why its own `≈3.317` subtotal
does not reconcile with its own headline. The headline does.

An exhaustive search settles that no other reading works: of all 17 single-file exclusions, only removing
`build_model.py` lands near 4,440 (at 4,441); the only subset of any size summing to exactly 4,440 excludes
`KERNEL/hash-provider.lisp` **and** `SETUP-TOOLCHAIN.sh`, which the review's own breakdown counts explicitly
(`setup 70`, Lisp path `399-400` = kernel + provider). And no counting-rule variant reproduces 4,440 over 17
files: minus shebangs 4,577; minus every docstring 4,176; minus module docstrings only 4,335; non-blank with no
comment rule 4,874.

---

## 4. The corrected baseline and the corrected cap

The full real acceptance execution closure at `af0eb3c9` was **17 files, 5,544 physical, 4,577 NBNC**.

Under the creator's TCB baseline reconciliation instruction (*"if the full real baseline at `af0eb3c9` proves to be 4,577 NBNC,
the hard non-growth cap is corrected, documented, to ≤ 4,577"*), the cap is therefore:

> **Hard non-growth cap: the active acceptance TCB must not exceed 4,577 NBNC lines**, measured by rule §1 over
> the same full execution closure, before and after.

This is **not** a relaxation of the 4,440 figure and it is not a third, convenient number. It is the same
measurement the review made, taken over the same set on both sides instead of over 17 files on one side and 16 on
the other. The reviewer's finding is unaffected and stands: **the verifier is larger than the model it verifies,
and `400/400` is the Lisp path's budget, not the total TCB.** Nothing in this document may be used to present
`400/400` as a total.

**What may not be done to satisfy the cap**, recorded so that a later pass cannot quietly do it: no file may leave
the count by being re-classified, re-named, moved to a "fixture", "helper", "generator" or "migration" bucket, or
declared out of scope; no line may be packed; and no independent mechanism — the second reader in the checker,
the third reference encoding implementation, or the closure-indeterminacy analyser — may be removed or weakened to
buy lines. The counter enforces this structurally rather than by convention: it derives its file set from the
**candidate tree by kind**, not from any role name the model assigns, so a re-classification cannot shrink the
measured TCB at all.

---

## 5. The measured after-state, and what it costs

Measured by rule §1 over the same full execution closure, at the end of the Review-3 correction pass:

| | files | physical | NBNC |
|---|---:|---:|---:|
| baseline `af0eb3c9` | 17 | 5,544 | **4,577** |
| after the Review-3 correction | 16 | 6,072 | **5,019** |
| difference | −1 | +528 | **+442** |

Per file, the whole of the difference:

| path | af0eb3c9 | now | Δ | what the change is |
|---|---:|---:|---:|---|
| `run_fixtures.py` + `run_falsifiers.py` + `run_gate_falsifiers.py` | 1,242 | — | −1,242 | three runners, three copies of one scaffolding |
| `run_corpus.py` | — | 1,111 | +1,111 | the ONE runner that replaced them (net **−131**) |
| `gate_checks.py` | 853 | 1,196 | **+343** | R3-2 provenance, R3-7 universe floors, R3-1/R3-13 encoding agreement, §15 the TCB counter, R3-3 executed-identity, R3-5 closure indeterminacy, R3-6 generation workspace, R3-9 content-state and candidate resolution, R3-11 extension-blind artifacts, and the dead-rule finding this pass added |
| `acceptance_runtime.py` | — | 123 | **+123** | R3-8 workspace lifecycle and hostile-TMPDIR refusal, R3-9 content-sensitive state, R3-10 bounded execution, R3-14 the common object store, §15 the one counting rule |
| `SEXP-READER.py` | 235 | 335 | **+100** | R3-1 the AMC2 reference implementation, R3-6 the containment seat, the one canonical model read, the one pinned-tool lookup (R3-3) |
| `ARCHITECTURE-MODEL-GATE.sh` (the session's transient `ACCEPT.sh` was never tracked) | 94 | 151 | **+57** | R3-15 one command with two phases, R3-3 pinned-interpreter resolution, and the exit-code check that stopped a vacuous battery reporting PASS |
| `CHECKER/independent_check.py` | 525 | 547 | +22 | R3-1 its own independent AMC2 implementation |
| producers (`build_inventory` −36, `build_decision_packet` −25, `generate_views` −11) | 1,022 | 950 | **−72** | §15 M2 the classification table moved to model data; §15 M3 the packet's mechanical skeleton moved to a template and its authored prose out of the generator |
| everything else (kernel, hash provider, setup, `build_deferred`, `build_model`, `build_root`, `regenerate`) | 683 | 683 | 0 | unchanged |
| **total** | **4,577** | **5,019** | **+442** | |

Read plainly: **the entire overrun is the price of closing R3-1…R3-15.** The consolidations went the other way
and gave back 203 lines (−131 on the runner, −72 on the producers), and there is no remaining duplication of
comparable size: the three-runner duplication the previous pass carried is already gone, and what is left in
`gate_checks.py` and `run_corpus.py` is one seat per check and one case per defect class.

## 6. What was NOT done to close the gap, and why

Each of these would have closed the arithmetic. None of them was taken.

* **Nothing was re-classified out of the measurement.** The counter derives its file set from the candidate by
  KIND, so a role change cannot shrink it even in principle.
* **No line was packed.** Every reduction above is a deletion of duplicated logic, not a reformatting.
* **No independent mechanism was removed or weakened** — not the checker's own reader, not the third reference
  AMC2 implementation, not the closure-indeterminacy analyser.
* **The counting rule was not changed to produce a passing number.** It is the same rule, over the same closure,
  on both sides.
* **One authorised consolidation was evaluated and declined**: a shared data-driven renderer for the eight
  generated views. It would move roughly 30 lines of straight-line rendering into an interpreter plus a
  view-specification mini-language inside the model. That does not make any error class structurally
  impossible, it puts a second language in the canonical model, and 30 lines cannot change a 440-line residual.
  It is recorded here as declined-with-reason rather than done, so the creator can overrule it.

## 7. The creator's adjudication, and the cap that now holds

The decision was taken by the creator: **`R3-CLOSURE-JUSTIFIED-EXCEPTION`, granted explicitly, up to 5,020
NBNC**, on the finding that the additional lines close named and independently reproduced defects. The final
measured closure is **5,019 NBNC**, one line under the granted ceiling. Its exact
terms, recorded here because the exception is meaningless without them:

* The historic baseline stands at **4,577 NBNC / 17 files / 5,544 physical at `af0eb3c9`** and is **NOT
  retroactively corrected**. This document's §1–§4 are the record of it.
* **5,020 NBNC is the new non-growth ceiling** for this governance TCB. One line over it stops the pass.
* **The exception is not evidence of quality.** Every line above the baseline must correspond to a specific
  `R3-*` finding, an invariant, a falsifier, or necessary shared infrastructure. §5's table above is that
  correspondence, line for line.
* Nothing was removed or weakened to reach the number: not `build_model.py`, not the checker's independent
  reader, not the third AMC2 implementation, not the closure-indeterminacy analyser. No line packing, no change
  to the counting rule, no artificial exclusion of a file, and no relocation of executable code to an unmeasured
  place.

`tcb-budget ACCEPTANCE-TCB` in `verification-corpus.sexp` therefore reads `:cap 5020 :baseline 4577`, with the
exception and its conditions written into its `:rationale`, and `tcb-01` enforces the ceiling against a
measurement it re-derives from the candidate by file KIND on every run.

The reviewer's finding is untouched by any of this and still stands: **the verifier is larger than the model it
verifies, and `400/400` is the Lisp path's budget, not the total trusted computing base.**

## 8. One authorised consolidation, declined with reason

A shared data-driven renderer for the eight generated views was authorised and was **not** implemented. It would
move roughly 30 lines of straight-line rendering into an interpreter plus a view-specification mini-language
inside the canonical model. That makes no error class structurally impossible, it puts a second language in the
model, and it cannot change a 442-line figure. Recorded here as declined-with-reason so the creator can overrule
it, not silently skipped.

## 9. Two findings the final batteries produced, after the exception was granted

Both are recorded here because they changed the final number and because neither came from review.

* **The composed battery was judging the wrong tree.** The full acceptance phase exports `AML_REPO` and
  `AML_CANDIDATE_TREE` so the exported verifier knows which repository it is judging. Those variables were
  inherited by the inner gate each composed falsifier starts inside its own disposable repository, so eight
  falsifiers injected a defect into one tree and then made the gate judge a different, unmutated one — all eight
  reported NOT REJECTED against a defect that was never put in front of a check. `run_gate` now strips `AML_*`
  from the inner environment; verified by re-running a composed falsifier with exactly those variables exported.
  Cost: one line, paid for by deleting two single-use local aliases of the reader's own header vocabulary.
* **A real weakening mutation was run through the whole acceptance command** on a disposable clone: `check_tcb`
  was neutered to report nothing and enforce no cap. `tcb-01` then reports PASS, as the mutation intends — and
  the three held-out falsifiers for that check (`X54`, `X55`, `X56`) report NOT REJECTED, `fls-01` FAILS, and
  the acceptance subset fails by name. A weakened check does not pass acceptance quietly; the falsifiers that
  exercise it are what makes that true.

---

## 10. Review-4: the numeric ceiling is withdrawn; the gate becomes an accountability gate

The creator's Review-4 order supersedes §7's ceiling **as a pass/fail condition only**. There is no numeric TCB
cap any more. What `tcb-01` now holds, on every run, is:

* the **exact TCB file universe**, derived from the candidate by file kind and never by role name — nothing
  executable hidden, undeclared, phantom or duplicated;
* the **real measurement** of every file, physical and NBNC, matched against what the model records;
* the **per-file and total delta** against the verified baseline `af0eb3c9 = 17 files / 5,544 physical /
  4,577 NBNC`, whose per-file rows are now authored `tcb-baseline` facts (independent review #4 reproduced
  every one of them with its own counter);
* the rule that **every growth is attributed** (`tcb-attribution`) to a specific reproduced finding from the
  closed `finding-id` set — an unattributed growth, an unknown finding id, an attribution for a file that does
  not exist, or baseline rows that do not sum to the recorded baseline are each a named failure.

The total is printed as a **measured fact and a complexity signal**. It is not the sole reason for a verdict:
a budget raised to meet a measurement would be a tautology, and a protection removed to meet a number would be
exactly the defect this gate exists to expose. §5–§7 remain as the record of how the 4,577 baseline and the
5,020 exception were established; §8's declined consolidation stands. After independent review #5, if it
passes, the measured size becomes the next observed baseline and this verifier infrastructure is locked; growth
after that is permitted only for a new reproduced counterexample or a new explicitly approved architecture law.
The `400` for the Lisp path remains a design target and a measurement, never a reason to pack a line or drop a
protection.

Measured at the end of the Review-4 correction, by `tcb-01` on the candidate: **16 files / 6,550 physical /
5,420 NBNC** — `+843` NBNC over `af0eb3c9`, `+401` over `cc52a27d`. The Review-4 growth, file by file:
`gate_checks.py` +178 (history-bound base, base-anchored authorization, schema-version policy, accountability
`tcb-01`, typed toolchain refusal), `run_corpus.py` +149 (data-driven `GATE`/`CHECK`/`APPEND`/`REPLACE`
falsifiers with synthetic bases and PASS controls, the spawn-time and concurrent-signal falsifiers),
`acceptance_runtime.py` +57 (typed spawn failures, forced `GIT_OPTIONAL_LOCKS=0`, live child registry with
signal forwarding), `build_decision_packet.py` +14 (schema-declared versus instantiated fact types, and the
sentence that names the counted checks as Option-2 acceptance checks), `ARCHITECTURE-MODEL-GATE.sh` +3 (`--base`,
own process groups, the check-count label). Every row above the baseline carries a `tcb-attribution`, and
`tcb-01` names any that does not.

---

## 11. Review-5: the decision recorded where it binds; the measurement after the correction

The creator's Review-5 order records the TCB decision verbatim in the canonical model — the `:rationale` of
`tcb-budget ACCEPTANCE-TCB` in `verification-corpus.sexp` — so that the policy lives beside the numbers it
governs and `tcb-01` reads both from the same fact: *numeric TCB ceilings are withdrawn as pass/fail criteria;
exact TCB file-universe discovery, exact physical/NBNC measurement, historical comparison and honest per-file
attribution remain mandatory; no protection, independent implementation, coverage mechanism or falsifier may be
removed, weakened, packed or obscured merely to satisfy a line-count target.* `TCB-DECISION.md` §7 points there.

Attribution is **per file**, and is described as such everywhere: a file that grew over the baseline names the
findings that required its growth. There is no per-line mapping and none is claimed.

Measured at the end of the Review-5 correction, by `tcb-01` on the candidate: **16 files / 7,079 physical /
5,866 NBNC** — `+1,289` NBNC over `af0eb3c9`, `+446` over `4ee2b58a`. The Review-5 growth, file by file:
`run_corpus.py` +239 (synthetic candidate commits over coherent synthetic bases, relocation and form-module
operations, the derived inner-gate base, whole-model integrity, the nine candidate/base process cases and the
two-commit reproducer), `SEXP-READER.py` +118 (one model read over any source with historical verification, the
one root-digest formula, the canonical version rule, whole-model discovery of floors and authorizations),
`gate_checks.py` +97 (the derived candidate/base seat, the verified historical load, the rewritten universe
check with its separated report, the real candidate in provenance), `ARCHITECTURE-MODEL-GATE.sh` +1 (the
candidate identity carried to every phase), `build_root.py` −9 (its own copies of the digest formula and the
version rule replaced by the reader's). Every grown file carries a `tcb-attribution` naming its Review-5
findings; `build_inventory.py`, whose two raw git calls now go through the execution seat, stays at −36 against
the baseline.

---

## 12. Review-6: the two residuals, and what they cost

The Review-6 re-verification passed with two P3 residuals, both outside the verifier lock boundary. Closing them
is a bounded change at two seats, and its cost is recorded here per file, as every growth since `af0eb3c9` is:

* `SEXP-READER.py` — `authorization_state`, the derived lifecycle of an authorization: four states read from a
  record's own immutable fields and the floors of the model carrying it, so nothing about a record's standing is
  ever written by a candidate (R6-1).
* `gate_checks.py` — one seat for the base's parent model, the lifecycle applied in `uni-01`, the two rules that
  keep the spent state from becoming a hole (`AUTHORIZATION-SPENT-WITHOUT-HISTORY`,
  `AUTHORIZATION-SPENT-FAMILY-REVIVED`), and the `UNIVERSE-AUTHORIZATIONS-TERMINALLY-SPENT` evidence line (R6-1).
* `run_corpus.py` — the fourteen held-out cases and the edge-chain harness they need, plus `--count`, the
  model-derived number the command's informational note now prints (R6-1, R6-2).
* `ARCHITECTURE-MODEL-GATE.sh` — one line: the note's count comes from the model instead of from a `grep` over a
  named module (R6-2). The file's measurement does not change.

There is still no numeric ceiling: the total is a measured fact and a complexity signal. The creator's binding
decision remains recorded verbatim in the `:rationale` of `tcb-budget ACCEPTANCE-TCB`, and nothing was removed,
compressed, packed or weakened to change a number. The measurement of the corrected tree is produced by the
canonical acceptance run on the declared toolchain, and is recorded there rather than asserted here.
