# REVIEW-2 CORRECTION ADJUDICATION — N-1 … N-20 and the residual F-1 … F-13

**Governing document.** The independent red-team report *INDEPENDENT CANONICAL-MODEL CORE REVIEW #2 — OPTION-2
CORE @ `f04bf7e6`*, verdict `OPTION-2 CANONICAL CORE INDEPENDENT REVIEW #2 FAILED — CORRECTION REQUIRED`
(7 × P1 N-1…N-7, 10 × P2 N-8…N-17, 3 × P3 N-18…N-20; plus a residual assessment of F-1…F-13 from review #1:
7 CLOSED, 5 PARTIALLY CLOSED, 1 RECURRENT).

**What this document is.** The adjudication of that register: for each finding, the **class of error** it belongs
to and the **structural change** that removes the class — not a guard placed around the reported example. Where
something is left open, it is named here as a residual with the phase that retires it, never left implied.

**What this document is not.** Not a claim of soundness, completeness, freeze-readiness or independent
verification. The next verdict on this work belongs to a fresh independent review. DDI-1…DDI-4, Option-1 /
full-build closure, SPEC freeze, qualification, MISSION, WP-00, Implementation-Book regeneration and production
implementation all remain blocked and untouched.

---

## 1. The P1 findings

### N-1 — the trusted kernel compiled an unpinned third-party closure that could forge its verdict
*Class:* the verifier's own instrument was unpinned, and pinning it was impossible from inside itself.
*Closure:* the vendored SHA-256 closure is retired. The Common Lisp path acquires its digest engine from the
schema-validated `tool` fact whose `:role` is `DIGEST_PROVIDER` — one external program, pinned on path, exact
executable digest and semantic version, invoked with the bytes on standard input (no shell, no temp file, no
path interpolation), and measured by the *other* path's engine. The full dominance comparison, including what
this costs, is `TCB-DECISION.md`. *Seat:* `TOOLCHAIN.sexp`, `KERNEL/hash-provider.lisp` (67 lines).
*Mechanised by:* `gate_checks.py toolchain`, `gate_checks.py hash-engines`.
*Falsified by:* `K25-PROVIDER-UNAVAILABLE`, `K24-CRLF-TEXT-HASHING`, `G06-TOOLCHAIN-IDENTITY`.

### N-2 — the gate erased pre-existing drift before comparing, and its falsifier was a tautology
*Class:* the judge rewrote the evidence, so no check downstream could be honest.
*Closure:* applying and judging are now different commands. `regenerate.py` is the only thing that writes derived
artifacts into the tree; `ARCHITECTURE-MODEL-GATE.sh` resolves one **immutable candidate tree**, exports it into
a private `mktemp -d` workspace, regenerates *there*, and byte-compares against the candidate's own blobs. The
gate proves its own read-only property at the end: the working tree must be byte-identical and, when it judges
the working-tree candidate, the recomputed candidate tree must be the same object.
*Mechanised by:* `gate_checks.py candidate`, `generation`, and the gate's `ro-01`/`ro-02`.
*Falsified by:* `G01-GATE-WRITES-TO-TREE`, `G02-PRE-EXISTING-DRIFT-ERASED` — and these run the **composed gate**,
which is the specific gap the review identified: the previous falsifier for this class could not detect its own
defect because it never ran the gate.

### N-3 — the generated-artifact universe was a hand-written list inside the generator
*Class:* a universe that lived in code, so deletion and renaming were invisible.
*Closure:* every derived artifact is a `gen-artifact` fact bound to the `gen-step` that produces it.
`generate_views.py` derives its output list from those facts and refuses to run if declared and renderable
differ **in either direction**. *Mechanised by:* `gate_checks.py artifacts` (exact set equality against the
candidate tree), `generation-order`. *Falsified by:* `K01`, `G03-ARTIFACT-DELETED`, `G04-ARTIFACT-UNDECLARED`.

### N-4 — the fixture / property / falsifier universes were unpinned and shrank silently
*Class:* the test corpus certified itself; `0/0 failures=0` was accepted as success.
*Closure:* `verification-corpus.sexp` declares the exact universe as facts — every fixture with its expected law
and reason, every property family with its **exact cardinality**, every falsifier with the harness that runs it.
The runners derive their work from it and fail on an empty universe. *Mechanised by:* `gate_checks.py corpus`
(set equality in both directions, per harness). *Falsified by:* `G05-CORPUS-SHRUNK`.

### N-5 — `run_fixtures.py` was a regex / physical-line reader on the acceptance path
*Class:* a second, weaker reader seat, so a reformat changed what was tested while every commitment stayed equal.
*Closure:* the runner parses through the one classified reader, mutates **structurally** (`remove_fact`,
`remove-facts-where`) and re-emits; property families enumerate from the model by declared selector, never from
lines. Both the expected law and the expected reason are enforced on **both** verification paths.
*Mechanised by:* the declared cardinalities in `corpus`. *Falsified by:* `K08`, `K09`, `G05`.

### N-6 — the migration-source universe was a hand-written list
*Class:* a qualifying new source was invisible while the ledger still reported `exact-universe`.
*Closure:* `build_deferred.py` derives the source universe from the inventory's own `CANONICAL_MODEL_INPUT` role
assignment outside the model seat. A file that qualifies by the classification rule and is not adjudicated is a
named failure. *Falsified by:* `K18`, `X30`, `G07-UNADJUDICATED-SOURCE`.

### N-7 — the decision packet offered global promotion with no typed authority split
*Class:* an unconditional `APPROVE` that a Root Operator would sign, over a model where 56 classes / 332 source
forms are still authoritative only at their legacy source.
*Closure:* `source-class` facts carry a typed `:authority` (`CANONICAL_IN_MODEL` vs `AUTHORITATIVE_AT_SOURCE`),
and two `promotion` facts state the scope and state explicitly — `IMPORTED_CLASSES_ONLY` = `PERMITTED`,
`GLOBAL` = `FORBIDDEN_UNTIL_DDI_COMPLETE`. The packet's §10 offers **APPROVE (bounded)** only, and §2b-i prints
the authority split with the instance counts beside the class counts.
*Mechanised by:* `gate_checks.py packet`, which recomputes the deferred volume and refuses a `GLOBAL` promotion
state other than `FORBIDDEN_UNTIL_DDI_COMPLETE` while any class remains authoritative at source.
*Falsified by:* `X44-GLOBAL-PROMOTION-OVERCLAIM`, `K20-PACKET-UNDERCOUNT`.

---

## 2. The P2 findings

| # | class | structural closure | falsifier |
|---|---|---|---|
| **N-8** | open field-name space: `:unexpected-key` and a misspelled optional field both passed | `:required ∪ :optional` is the **complete** permitted vocabulary of every fact type; any other key is a typed L1 violation naming the fact, the key and the permitted set | `X33`, `X34` |
| **N-9** | `ROOT.sexp` unconstrained beyond its first form; the two paths read it differently | the module-level complete-consumption rule now applies to the root: exactly one `define-model-root` and nothing else, duplicate plist keys rejected, `:schema-version` validated against `MODEL-SCHEMA.sexp` | `X37`, `X38`, `X39` |
| **N-10** | seat and write authority were opaque strings; 21 of 26 `owner-seat` values resolved to nothing | `seats.sexp` declares 33 typed seats; `define-conditional` makes a `BUILT` seat structurally unable to be a plan and a `DESIGN_TARGET` structurally unable to carry a path; `owner-seat`, `store.owner`, `store.writer` and `req-map.seat` are closed references; `define-unique` gives one canonical write authority per store | `X40`, `X41`, `X42`, `X43` |
| **N-11** | toolchain pins were documentation: nothing read `:execution-digest` | `tool` facts, enforced before either verifier runs, on path + exact executable digest + semantic version, each measured by the **other** path (`:verified-by`); no tool can certify itself because the `verifier` enum has no such value | `G06` |
| **N-12** | fixed `/tmp` paths, no cleanup trap, observed cross-run contamination and a destroyed victim file | one `mktemp -d` mode-0700 workspace per execution with a cleanup trap on `EXIT INT TERM HUP`; no fixed scratch path remains anywhere in the gate | `G08-TMP-COLLISION` |
| **N-13** | the live-path AST check was evaded by 5 of 7 reintroduction forms | the check computes the **real transitive execution closure** of every governance entrypoint, resolving constant parts and treating a non-constant part as a wildcard, so concatenation, f-strings and joins fail closed | `X31` (which now performs an actual reintroduction, not a basename string) |
| **N-14** | check names misdescribed their mechanism; a presence check sat inside the counted set | every counted check is named for what it measures; presence-only evidence is reported as `INFORMATIONAL_PRESENCE_CHECK` and excluded; drift is measured against the candidate tree object, never a porcelain column | `G01`, `G02` |
| **N-15** | the "independent" re-derivation shared the classifier | the claim is now what it is: *deterministic reapplication of the one classifier seat*. In exchange the coverage is strictly larger — every named row's role, rule and reason is re-derived, not only the directory-rule counts | `K07` (a named row silently re-roled) |
| **N-16** | `build_root.read_schema_version` was an undeclared substring reader | the version is read structurally through the one classified reader seat | `X39` |
| **N-17** | uncaught traceback on a missing pinned module | `MISSING-MODEL-FILE` / `UNREADABLE-MODEL-FILE` are typed results on every path; the independent checker additionally renders every value where the fact enters the universe, so no unrenderable value can surface as a traceback from a later stage | `X27`, `X45` |

---

## 3. The P3 findings

* **N-18 — prefix rules auto-admitted inside governed subtrees.** The model seat no longer blesses by prefix:
  `R-009Q` quarantines any file inside it whose kind no rule declares, and `REVIEW_REQUIRED` joins `UNCLASSIFIED`
  as a quarantine role that fails the build. The design-round extension set was narrowed, and `R-038` classifies
  the vendored tree as `VENDORED_DEPENDENCY` rather than absorbing it as evidence. *Falsified by:* `K02`, `X26`.
* **N-19 — `run_fixtures.py` hygiene.** The expected **law** and the expected **reason** are now enforced on
  both paths; the undeclared `[:6]` / `[:4]` caps are gone, replaced by the corpus's declared cardinalities; a
  family that enumerates nothing fails instead of reporting a smaller number.
* **N-20 — `SETUP-TOOLCHAIN.sh` prerequisites.** The script states its supported base environment, separates
  `--verify` (read-only, unprivileged, offline) from `--provision` (declares that it changes the machine and
  requires root and network), emits typed `READY` / `MISSING_PREREQUISITE` / `UNPROVISIONABLE` lines, and issues
  no identity verdict at all — identity belongs to `gate_checks.py toolchain`, which compares digests.

---

## 4. The residual from review #1

| # | prior verdict | where the residue is closed now |
|---|---|---|
| F-1 | CLOSED | unchanged, and strengthened: the comparison is against an immutable tree object rather than the index |
| F-2 | PARTIALLY CLOSED (prefix residue) | closed by N-18 above |
| F-3 | CLOSED | unchanged; `C-QUOTED-INVENTORY-KEY` remains a named failure |
| F-4 | **RECURRENT in the test oracle** | closed by N-5: the second reader seat is gone; the runner parses and re-emits structurally |
| F-5 | CLOSED | unchanged; extended by the closed field set (N-8) and the id spaces (N-10) |
| F-6 | CLOSED | unchanged; extended by full ROOT discipline (N-9) |
| F-7 | PARTIALLY CLOSED (5 of 7 evasions) | closed by N-13: a real transitive closure replaces the basename tripwire |
| F-8 | CLOSED | unchanged |
| F-9 | CLOSED for the ledger path | closed everywhere by N-17 |
| F-10 | PARTIALLY CLOSED (`led-02`, `inv-04`) | closed by N-14: both are gone; what remains counted can fail on a defect it names |
| F-11 | CLOSED as to the primitive; provider unverified | closed by N-1 and N-11 |
| F-12 | CLOSED as documentation; NOT enforced | closed by N-11: the pins are now read and enforced before any verdict |
| F-13 | CLOSED | unchanged; this pass appends and never rewrites the earlier record |

---

## 5. What the internal adversarial pass found in this correction itself

Recorded because a correction that only reports the reviewer's findings is grading its own homework. Each of
these was found while building the machinery above, and each is closed at its seat rather than worked around.

1. **The composed-gate battery was reconstructing an incomplete repository.** It built its disposable copy with
   `git init` + `git add -A`. `git add` obeys `.gitignore`, so every ignored-but-tracked path was dropped — the
   whole 29,204-file `output/` subtree among them — and it applies `.gitattributes` text normalisation, so CRLF
   blobs changed. The copy held 7,421 of 36,631 paths, its gate failed for that reason alone, and two
   falsifiers that merely require the gate to fail were therefore **passing vacuously**.
   *Closure:* the candidate tree object is installed directly (index read from the tree, working tree written
   from the index, commit made over that exact tree), the path count is asserted against the tree before any
   falsifier runs, and a mandatory **control** now runs first: the gate must PASS on an unmutated copy, or the
   battery aborts as `BATTERY-VACUOUS` instead of reporting eight successes.

2. **The gate regenerated into the seat its later checks read.** `generation` ran the producers inside the
   shared exported candidate, so `inventory`, `corpus`, `packet` and the ledger verification afterwards were
   inspecting bytes an earlier check had just produced — the N-2 class reappearing inside the gate's own
   workspace. It was caught by falsifier `G07`, which failed to reproduce because the ledger it was supposed to
   catch had been regenerated in between.
   *Closure:* the one check that must run producers gets its own private copy; the shared export is never
   written.

3. **The independent checker crashed instead of judging.** A value with no canonical rendering passed the
   read stage and raised an uncaught `ReadError` from deep inside commitment construction — a traceback where a
   named verdict belongs (the N-17 class, in a second place).
   *Closure:* every value is rendered where its fact enters the universe, so an unrenderable value is a typed
   `MALFORMED-FACT` at the point of reading.

4. **A control character inside a string value was legal.** The commitment joins rendered fact lines with a
   newline, so a string able to contain one would let two different fact sets render to identical bytes — and
   the ASP program built from such a value ended in a solver lexer error rather than a verdict.
   *Closure:* control characters are removed from the value grammar itself on all three readers; the ambiguity
   cannot arise. Falsifier `X45` holds it.

## 6. What is still open, named rather than implied

1. **DDI-1 … DDI-4 have not started.** 56 source classes (332 source forms) remain `AUTHORITATIVE_AT_SOURCE`.
   Global single-source-of-truth is `FORBIDDEN_UNTIL_DDI_COMPLETE` in the model itself, and the gate fails if
   that ever stops being true while classes remain deferred.
2. **Six seats are `DESIGN_TARGET`, three `DEFERRED_PRIVATE`, one `INTERFACE_ONLY`, one `NO_WRITER`.** Each
   declares a rationale and, where it will be built, the work packet that builds it. None is a fake path, and
   none is presented as existing.
3. **The supported base environment is one host.** On any other, the gate stops with a typed
   `TOOLCHAIN-IDENTITY-MISMATCH`; re-pinning is an explicit edit, never an automatic accommodation.
4. **The lexical scan of the kernel sources cannot prove absence** and is reported as informational, not counted.
5. **No semantic, legal, security, behavioural, operational or qualification property is established here.**
   Everything above is structural evidence about a model of an architecture.
