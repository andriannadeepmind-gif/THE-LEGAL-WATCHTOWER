# BASE AUDIT — LAYER 3: ADMISSION / GATE / CONSTITUTIONAL SPINE
**Stance:** adversarial, uncharitable. Existing seats are NOT credited for existing.
**Method:** read the real code (Read/Grep/Bash over the live tree). `output/`, `output_run1/` paths only.
**Claim tags:** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN.
**Files read in full:** `source/constitutional-gate.lisp`, `systems/orchestrator-cli/constitutional-dispatch.lisp`,
`authority-v2/kernel/admission-model.sexp`, `source/ast-gate.lisp`, `systems/orchestrator-cli/approval-policy.lisp`,
`systems/orchestrator-cli/self-reflection.lisp`, `systems/orchestrator-cli/gates-runner.lisp`, plus the 17 `*-gate.lisp`
(headers + bodies of architecture/capability/iq sampled deep; all 17 registration + structure enumerated).

---

## 0. THE CENTRAL REFRAME (read this first) — two different things are both called "gate"

The brief treats "the 17 gates" as the constitutional/admission spine. **They are not.** Adversarial reading of the code
splits the word "gate" into two disjoint concepts that the vocabulary silently conflates:

1. **The runtime ADMISSION spine** (authorizes a privileged action *before it happens*):
   `constitutional-gate.lisp` (registry+`evaluate`+`overridden-p`) → `constitutional-dispatch.lisp` (CLOS `:around`) →
   (aspirationally) `admission-model.sexp` (kernel K). This is the only thing that *mediates acting*. `DEMONSTRATED`.

2. **The self-VERIFICATION plenary** (`--gates`, `gates-runner.lisp`): the 17 `*-gate.lisp` are **CLI regression/CI
   suites**. Each is a `register-command "--X-gate"` returning exit 0/1; `run-all-gates` enumerates every command whose
   name ends `-gate` and runs it (`gates-runner.lisp:20-26`). They gate **release** (CI must be green), *not* runtime
   privileged effects. None of them sits on the path of any privileged action. `DEMONSTRATED`.

Consequence: the question "are the 17 gates complete-mediation of privileged actions?" is a **category error the code
invites** — they were never on that path. Complete-mediation is decided entirely by spine #1, and spine #1 is thin,
fail-open, and its kernel is unbuilt (§1–§3). This conflation is itself a first-order finding: the impressive breadth of
"17 gates" is *test coverage*, and it is being read as *authorization coverage*. Those are not the same guarantee.

---

## 1. `source/constitutional-gate.lisp` — VERDICT: **REPLACE**

**(a) Defects (quoted).**
- **FAIL-OPEN (lines 43–47), confirmed:**
  ```lisp
  (handler-case (funcall (getf r :predicate))
    (error () (values t nil)))   ; σφάλμα κανόνα ⇒ ΜΗΝ μπλοκάρεις (fail-open, τίμια)
  ```
  A predicate that SIGNALS → treated as ALLOW. For a privilege/admission boundary this is a class of bypass, not an
  edge case: any bug/type-error/resource error inside a rule silently opens the gate. `DEMONSTRATED`.
- **The entire constitution contains EXACTLY ONE rule.** `grep register-rule` over the whole tree returns a single
  call site: `self-reflection.lisp:142` `:understanding-before-load`, `:applies-to '("--fetch-decision" "--fetch-year"
  "--watch-decisions")`. Therefore `evaluate` returns `(values t nil nil nil)` — ALLOW — for **every other command in
  the system**, vacuously. The "supreme constitutional barrier on every act" is, empirically, one understanding-scan
  predicate over three fetch commands. `DEMONSTRATED`.
- **`evaluate` receives only the command NAME** (`dispatch:56` → `(evaluate name)`), never the args/payload. Rules are
  nullary closures over ambient global state (`%understanding-scan`). The gate structurally *cannot* make a
  data-dependent decision about the action it is admitting — it can only consult ambient scan state. `DEMONSTRATED`.
- **Fail-open × the one live rule = a concrete exploit.** `:understanding-before-load` calls `%understanding-scan`; if
  that scan errors (corpus not loaded — and `main.lisp:2523` explicitly tolerates "running WITHOUT declarative
  knowledge"), the `error()` branch returns ALLOW, so new decisions load *without* the understanding precondition the
  rule exists to enforce. The one rule that exists is nullified precisely in the degraded state where it matters.
  `DESIGN-ENTAILED`.

**(b) Needs-it-to-WORK vs needs-it-to-be-TOP.** Fail-open is a **needs-it-just-to-WORK / actively-unsafe** defect: it
contradicts CLAUDE.md's "0 λάθος / εξάλειψη της κλάσης σφάλματος" and the Ω2 architecture's stated **fail-CLOSED**
premise (CANON-Ω2 §2 "Inherited BLOCKING dependency"). The one-rule emptiness is a **needs-it-to-be-TOP** gap that is
so large it reads as WORK-level: a barrier that admits everything is decorative.

**(c) Required restructuring.** Replace the fail-open with **fail-CLOSED**: predicate error/timeout/UNKNOWN ⇒ REFUSE
(`(values nil article "rule-error" id)`), with the error surfaced, never swallowed. The "honest" comment is honest about
*being* a bypass — that is the bug, not a mitigation. `evaluate` must take the **full action descriptor** (name + args +
effect class), so rules can decide on payload. The rule *registry* must not be near-empty: the privileged-effect classes
(file writes to canonical stores, `emit-graph`, journal appends, adoption install, network fetch) each need a
constitutional rule or an explicit, recorded "unrestricted by design" declaration. Error-class elimination (CLAUDE.md
ΥΠΕΡΤΑΤΟΣ ΝΟΜΟΣ #2) means the ALLOW value should be **unrepresentable** on the error path, not merely discouraged.

---

## 2. `systems/orchestrator-cli/constitutional-dispatch.lisp` — VERDICT: **RESTRUCTURE**

**(a) Defect.** The CLOS `:around` on `execute-command` is genuine method-combination mediation — a real strength: every
CLI command routes through it (`main.lisp:2537` is the sole dispatch; the "30 builtins outside the gate" finding was
closed here). BUT it mediates **command-name dispatch only**. It calls `(evaluate name)` (line 56), so:
- privileged **effects invoked from inside a command body** (a handler that writes a store, calls `emit-graph`, appends
  a journal line, runs git, fetches the net) are **not re-mediated** — the constitution sees the command name, not the
  effects it will perform. Complete-mediation over *privileged effects* is **FALSE**; complete-mediation over *CLI
  command entry* is true. `DEMONSTRATED`.
- The refusal path (`%constitutional-refusal`) prints and returns exit 1 — correct. The override path
  (`overridden-p args name`) requires scope (`--force`/`LAWMAX_OVERRIDE` naming the command) **AND** a non-empty
  `LAWMAX_OVERRIDE_REASON`, recorded to the biography (lines 41–47). This is well-built (`approval-policy.lisp:258-282`
  locks it with negative tests) — the universal `LAWMAX_OVERRIDE=1` flag is correctly dead. `DEMONSTRATED`. This is the
  **one part of the spine that is at TOP level.**

**(b) WORK vs TOP.** Effect-level mediation is a **needs-it-to-be-TOP** gap for a "trusted spine a super-system is built
on": the Ω2 trust-boundary map (CANON-Ω2 §2) demands "one door per concept" and default-deny egress; a command-name
barrier cannot enforce that, because the privileged effects live *below* the command boundary.

**(c) Required restructuring.** The mediated unit must become the **privileged effect**, not the command name — i.e. the
reference monitor sits on the effect seats (write-authority/`emit-graph`, journal append, store writers, egress) with a
typed capability check, and the CLI `:around` becomes one *caller* of that monitor rather than the monitor itself. Until
then the program-level claim "no privileged action escapes the constitution" is **HYPOTHESIS**, not DESIGN-ENTAILED.

---

## 3. `authority-v2/kernel/admission-model.sexp` — VERDICT: **RESTRUCTURE (build the decider or withdraw the claim)**

**(a) Defect — it is DEAD SPECIFICATION, not a decider.**
- `:implementation-status :specification-only`, `:assurance-status :under-construction`,
  `:implementation-language-target "F* (verified) — ΟΧΙ Common Lisp"` (lines 20–22). All **9 theorems** T1–T9 carry
  `:status :blocked-toolchain` (lines 78–111) — **0/9 discharged**. `DEMONSTRATED`.
- **It is never loaded or executed.** `grep admission-model` over the tree: the only references are documentary —
  `authority-v2/proof-manifest.sexp:29` and `authority-v2/LEVEL7-COMPLETION-MATRIX.sexp:62`, both citing it as a source.
  No parser, no evaluator, no caller. The "pure total decidable decider K" that CANON-Ω2 §3.1 names as the tiny trusted
  kernel the whole split-verifier family rests on **exists only as prose in an s-expression**. `DEMONSTRATED`.
- Therefore: "K is total/decidable/fail-closed" is `DESIGN-ENTAILED` *of a specification*, and `UNKNOWN` as an
  artifact. There is no executable admission kernel anywhere in the trusted path. The runtime admission mechanism is
  §1's fail-open one-rule predicate — the opposite of this spec's stated totality and fail-closedness.

**(b) WORK vs TOP.** This is the **needs-it-just-to-WORK** foundation of the entire program: every downstream guarantee
("cannot admit a wrong authority", "cannot emit an unjustified trusted claim") is a theorem *about K*. With K unbuilt and
0/9 proved, those guarantees are undischarged at the artifact level. The spec's own `:out-of-scope` (lines 114–118) is
honest and good, but honesty about scope does not substitute for the missing decider.

**(c) Required restructuring.** The spec is a *good spec* — keep it as the single source of the conjuncts/theorems. But
the claim it underwrites must be made real: either (i) implement the decider in a verified toolchain and discharge
T1–T9 (the stated intent), or (ii) implement a deterministic total CL decider **and** cross-check it against an
independent implementation (N-version), explicitly marked as the interim trusted decider pending F*. Until one of these,
the correct status line everywhere downstream is "admission kernel: SPEC-ONLY, 0/9 theorems, no executable decider" —
and CANON-Ω2's §3.1 "the genuinely tiny kernel" must be tagged HYPOTHESIS, not DESIGN-ENTAILED.

---

## 4. `source/ast-gate.lisp` — VERDICT: **KEEP-AS-IS (with a naming caveat)**

**(a)** Honest, well-scoped advisory: lifts the served corpus into the existing legal-AST and runs the Layer-4
validators that were dead on the ΦΕΚ path. Preserves the lettered-article distinctness (`"100Α"` kept as string,
lines 74–77, 92). Docstrings label it **"Advisory"** (line 108). Pure CLOS, deterministic. `DEMONSTRATED`.
**(b)** Not a defect: it is advisory, so it does not *block*. If the mission needs structural validity to be a hard
admission condition on ingest, that is a **needs-it-to-be-TOP** upgrade (wire `structure-clean-p` into an admission
rule), but as an advisory intelligence layer it is correct as written.
**(c)** Caveat: the file is named `*-gate*` but is **not** a `--*-gate` plenary member and does not mediate — the "gate"
name overloads concept #1/#2 again. Rename to `ast-structure-advisor` or promote it to a real gate; do not leave a
"gate" that neither blocks nor joins the plenary.

---

## 5. `systems/orchestrator-cli/approval-policy.lisp` — VERDICT: **UPGRADE-IN-PLACE**

**(a) Defects.** Class-level auto-approval of norm classifications, gated on **measured precision over a LOCKED suite**
(`*deontic-suite*`, `+dream-precision-suite+`). Two adversarial problems:
- **Precision-only, no recall.** `measured-modality-precision` (lines 49–60) counts, among sentences the classifier
  *labels* as MODALITY, how many are truly MODALITY. A classifier that labels almost nothing can score 100% precision
  while missing most true instances. Auto-approving a *legal-critical* class on precision alone can silently admit a
  systematically under-firing classifier. `DEMONSTRATED` (metric definition).
- **Suite-authored-by-the-same-hand risk.** The "measured accuracy" is over a suite the project itself froze. Passing
  it proves "matches our own expectations," not "correct on unseen Greek legal text" — a regression scaffold read as a
  competence certificate. The `--policy-gate` self-test (lines 200-288) even asserts `= c tot` (100% on the green
  suite) as a *law* (line 219) — a suite the author both writes and grades. This is close to the brief's "test that
  asserts what the code already does." `EMPIRICAL/HYPOTHESIS`.
**(b) WORK vs TOP.** The escalation problem it solves (3016 classifications waiting one-by-one) is real; the mechanism
(versioned, revocable, append-only, recorded) is well-built and fail-closed on "no measurement ⇒ no policy" (line 163).
The gap is **needs-it-to-be-TOP**: auto-approving legal-norm modality on a locked, author-graded, precision-only metric
is a governance leap for a legal system whose creator law is "0 λάθος."
**(c) Upgrade.** Add **recall + F1** and a **held-out / adversarially-sourced** slice the author did not curate before
any class becomes auto-approvable; require the suite's provenance stamp (like capability-gate's `judge-dataset-stamp`)
so a re-baseline is a conscious, recorded act. Keep the human in the loop for any class below a stated recall floor.

---

## 6. `systems/orchestrator-cli/self-reflection.lisp` — VERDICT: **KEEP-AS-IS (structurally sound; note the load-bearing single rule)**

**(a)** Clean open/closed domain layer: registers proposal kinds (`:adopt` re-runs the shadow gate on approve — approval
does *not* bypass proof, lines 26–32), observers, institution/roles, contracts, and `--mirror-gate`. The `--mirror-gate`
(lines 589-648) is a genuine self-model consistency check (no orphan gates, closed dependency graph, honest gap-report).
`DEMONSTRATED`.
**(b)** The one adversarial note: **this file physically contains the entire constitution's rule set** — the single
`register-rule` (§1). The constitution's substance is one line in a reflection module. That is not a code defect but a
governance smell: the supreme barrier's content should not be a lone incidental registration inside self-reflection.
**(c)** No change to the mechanism; move/grow the rule set as part of §1's REPLACE so the constitution is not "one rule
hidden in the mirror."

---

## 7. THE 17 `*-gate.lisp` — distinctness, theatricality, retire list

All 17 are `--*-gate` CLI regression suites in the `--gates` plenary (self-verification, not admission — §0). Assessed
on: (i) is the concept distinct (one-seat-per-concept), (ii) is the verification a genuine independent oracle or a
hand-authored tautology.

**Verification-strength tiers (DEMONSTRATED by reading bodies):**
- **Genuine differential / independent oracle (strong):** `iq-gate` (believed-set vs an *independent naive stratified
  fixpoint*, `%naive-match`/`%naive-join`, lines 29-49), `fluid-gate` (hidden LCG-drawn DSL programs as oracle),
  `capability-gate` (independent legal-eval gold + leave-one-out judge, ratchet vs committed baseline + dataset-stamp),
  `golden-gate` (committed fingerprints), `release-gate` (recomputed RFC-6962 roots), `event-gate` (independently
  verified date certificates). These are NOT tautological.
- **Internal consistency checks (real, but prove coherence, not correctness):** `architecture-gate` (bidirectional
  live-registry ↔ declared constitution closure — the strongest structural gate), `component-gate`, `contract-gate`,
  `provenance-gate`, `verify-truth-gate` (docs≡CI), plus `--mirror-gate`.
- **Hand-authored expectation suites (weakest — regression scaffolds, closest to the brief's "tautology"):**
  `deontic-gate`, `generation-gate`, `dialogue-gate`. `dialogue-gate` **self-admits** it: line 169 — "η σουίτα είναι
  χειροποίητες προσδοκίες (σκαλωσιά μη-παλινδρόμησης) — ΔΕΝ συνιστά απόδειξη μάθησης." Honest, but a passing suite here
  proves "unchanged," never "correct/top." Must not be read as competence.
- No gate has a purely theatrical always-true predicate — I grepped for `(chk "…" t)` constants and found none. The one
  genuinely dangerous always-ALLOW in the codebase is §1's fail-open, not a plenary gate.

**One-seat-per-concept VIOLATIONS (name to RETIRE/MERGE):**
- **Cluster A — "self-model ≡ live image" fragmented across 4 seats:** `architecture-gate`, `component-gate`,
  `contract-gate`, `--mirror-gate`. `architecture-gate` ⑤⑥ already re-validates capabilities↔constitution and
  gates↔primitives bidirectionally — it is a **superset** of the concept the other three each check on one registry.
  The validation *logic* lives in library seats (`self-model:validate-*`, `component-scan:validate-*`,
  `contracts:validate-*`), so this is duplication at the **gate layer**, not the implementation layer. **Recommend:**
  fold into ONE `--self-model-gate` that runs all registry validators; demote mirror/contract/component gate-wrappers.
- **Cluster B — reasoning-engine correctness:** `inference-gate` (unify/JTMS/WFS/graph-BFS), `iq-gate` (stratified
  soundness, independent oracle), `event-gate` (temporal scenarios). `event-gate` is the thinnest (13 markers, a handful
  of scenarios) and exercises the **same** `make-inference-engine`/`run-inference` — temporal validity is a property of
  that one engine. **Recommend RETIRE `event-gate` as a standalone**, merge its scenarios into `inference-gate` as a
  temporal family. Keep `inference-gate` + `iq-gate` distinct (different verification methods).
- The regression-ratchet trio (`golden`/`capability`/`release`) and the language trio (`deontic`/`generation`/
  `dialogue`) are over **distinct objects** — legitimately separate, not duplicates.

**Per-gate verdicts:** architecture **KEEP** (make it the single self-model seat) · component **RESTRUCTURE** (fold into
self-model-gate) · contract **RESTRUCTURE** (fold) · mirror **RESTRUCTURE** (fold) · inference **KEEP** · iq **KEEP** ·
event **RETIRE→merge into inference** · fluid **KEEP** · deontic **KEEP** (weak — held-out slice needed) · generation
**KEEP** (weak) · dialogue **KEEP-AS-SCAFFOLD** (self-labeled, never cite as proof) · golden **KEEP** · capability
**KEEP** (add recall) · release **KEEP** · provenance **KEEP** · external-benchmark **KEEP** (dry-run stub, honestly
`:not-run` only) · verify-truth **KEEP**.

---

## 8. MOST SERIOUS FOUNDATIONAL DEFECT

**The runtime admission spine is a fiction at the trusted-path level, and the impressive "17 gates" mask it by being
test coverage read as authorization coverage.** Concretely: (a) the single total/decidable admission kernel K
(`admission-model.sexp`) is **specification-only, never loaded, 0/9 theorems discharged**; (b) the *only* executable
admission mechanism (`constitutional-gate`) is **fail-OPEN** (a crashing rule ⇒ ALLOW) and carries **exactly one rule**
over three fetch commands, so it admits essentially everything; (c) its dispatch mediates **command names, not
privileged effects**. Therefore the program-level guarantees the whole Ω2 architecture is "built on" — "cannot admit a
wrong authority," "cannot emit an unjustified trusted claim," fail-closed publication — are **HYPOTHESIS/UNKNOWN at the
artifact level**, not DESIGN-ENTAILED. The 17 plenary gates verify that the *rest* of the system does not regress; none
of them is on the admission path, so their green does not touch this hole. Fixing it is prerequisite to any "top legal
observatory / trusted spine" claim: build (or interim-implement + N-version) K, make the constitutional gate
fail-CLOSED with a non-trivial rule set, and move mediation onto privileged effects rather than command names.
