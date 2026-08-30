# Formal-Methods Boundary Map for a Legal-AI System (2026)

**Team:** FORMAL-METHODS BOUNDARY
**Scope:** exclusive-internal legal-AI (Greek practice; EU/ECHR inside the Greek order)
**Purpose:** the precise, honest boundary between what formal methods *prove*, what verified
implementation *guarantees end-to-end*, what per-run certificates *witness*, and what remains
*empirical* — plus the irreducible formalization gap and a recommended assurance-level taxonomy
to stamp on every component and every claim.

**Claim-status tags used throughout:** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED /
EMPIRICAL / HYPOTHESIS / UNKNOWN. Two disciplines are enforced verbatim: *proof-checking is never
equated with correctness of a natural-language formalization*, and *model access is never equated
with idea inclusion*. Unresolved contradictions are marked **BLOCKING**.

---

## 0. The one-paragraph honest summary

Formal methods can make a specific *formal object* (a function, a state machine, a security
lattice, a date computation, a proof search) satisfy a *specified property* with machine-checked
certainty, and — with a verified compiler class — can extend that certainty to the *binary that
runs on a modeled processor*, minus an explicitly enumerable trusted base. Formal methods **cannot**
certify that the formal object *is* the law, that a legal conclusion is *correct*, or that the
system is *superior* to a human team. The correctness of the map from natural-language law to
formal object is a **validation** problem settled by human legal authority and empirical evidence,
never by **verification**. Every architectural guarantee below is therefore a guarantee about a
*specification*, and the value of the whole system is bounded by the fidelity of that specification
to the law — a quantity that is *auditable and narrowable but never provable to zero error*.

---

## 1. The four assurance strata (exact meanings and exact limits)

### 1(a). THEOREM — machine-checked property of the formal object

**What it is.** A statement `P` about a mathematical object, reduced by a proof assistant's kernel
to primitive inference steps and accepted only if every step type-checks. This is the *de Bruijn
criterion*: a small, independently re-runnable checker (Coq/Rocq kernel, Lean 4 kernel, HOL4/
Isabelle LCF core, F*'s typechecker) is the sole thing that must be trusted about the proof.

**What it guarantees.** `P(formal_object)` holds under the axioms of the logic — with certainty far
exceeding human review or testing. `[THEOREM]` for the object; e.g. "this parser is total", "this
lattice join is monotone", "this deadline function never returns a date before the trigger event",
"the publication predicate is false unless all N gate conditions hold".

**Exact limits — what a THEOREM does NOT give you:**
- **It is about the formal object, not the running program.** A Lean/Coq proof about function `f`
  says nothing, by itself, about the C/OCaml binary that code-generation emits from `f`. That bridge
  is §1(b), and it is *separate and usually weaker*.
- **The kernel is small but not infallible.** Soundness bugs have been found historically in Coq,
  Lean, Agda, and Isabelle tooling (typically in exotic universe/reduction/serialization corners).
  `[EMPIRICAL]` mitigation: independent re-checking by a *second, independently implemented* kernel
  (e.g. MetaCoq's verified checker; external Lean kernel re-checkers) drives residual kernel risk
  toward — but never to — zero.
- **Axioms are trusted, not proven.** Classical logic, choice, `Prop`-impredicativity,
  `Type`-in-`Type` mistakes, or an over-strong custom axiom can make `P` provable *and false about
  the intended object*. Axiom hygiene (`Print Assumptions`, axiom-free cores) is a discipline, not
  a theorem.
- **`P` is a formal statement.** "The theorem is the right theorem" — that `P` means what a lawyer
  or architect intended — is itself a formalization-gap question (§3). A proved theorem about the
  *wrong* property is worthless and looks identical to a valuable one.

### 1(b). VERIFIED IMPLEMENTATION — the extraction/compilation chain, end-to-end

The central 2026 honesty point: **most proof assistants do NOT verify the path from proof to
binary.** The four toolchain classes differ sharply here.

- **Coq/Rocq extraction (to OCaml/Haskell): UNVERIFIED.** The standard `Extraction` mechanism is a
  *trusted*, historically *bug-carrying* translation (soundness bugs in extraction have been found).
  A Coq theorem about `f` + standard extraction gives you an OCaml `f'` whose correspondence to `f`
  is *trusted, not proved*. `[IMPLEMENTED, not verified]`.
- **CertiCoq: verified Gallina→Clight**, then handed to CompCert. Narrows the gap to research-grade
  verified compilation of a functional core, but is not the default and does not cover all of Coq.
  `[DEMONSTRATED]`.
- **CompCert (verified C compiler).** `[THEOREM]` of *semantic preservation*: the assembly it emits
  refines the semantics of the C source, for a defined C subset. Landmark empirical corroboration:
  Csmith random testing found **zero** miscompilations in CompCert's *verified core*; the only bugs
  were in *unverified* front-end/spec parts — the sharpest existing evidence that the verified/
  unverified boundary is *real and load-bearing*. `[EMPIRICAL]`. Residual TCB: the C-source
  semantics formalization, the assembler + linker, the Coq kernel, and CompCert's *own extraction*
  (itself via unverified Coq extraction).
- **CakeML (verified ML compiler).** The strongest end-to-end story in the functional world:
  a HOL4 theorem relates *source semantics all the way to machine-code semantics* for a real ISA
  model, including a verified runtime/GC, and *proof-producing synthesis* turns HOL functions into
  CakeML with a certificate. `[THEOREM]` end-to-end, modulo TCB below.
- **F\* (extraction to OCaml/C via KaRaMeL/Low\*): largely TRUSTED, and Z3 is in the TCB.**
  Two honesty flags: (i) KaRaMeL extraction of Low\* to C is *mostly trusted* (verified-extraction
  work is ongoing, not universal); (ii) **F\* discharges proof obligations with Z3 and does not
  reconstruct those proofs** — so Z3's soundness is in the trusted base. HACL\*/EverCrypt are
  proved *at the F\* level*; the C they ship is trusted-compiled. `[IMPLEMENTED]`.
- **Lean 4: code generation to C is UNVERIFIED.** Lean's kernel is trusted-small for *proofs*, but
  the compiler (elaborator→IR→C), the C toolchain, and the runtime (incl. GMP bignums, reference
  counting) are *trusted*, not proved. A Lean proof about `f` is about the *mathematical* `f`; the
  executable is a separate, trusted artifact. `[IMPLEMENTED, not verified]`.

**The seL4 pattern — how a proof is actually pushed to the binary.** seL4 combines (i) an Isabelle
refinement proof from abstract spec → executable spec → C, and (ii) **binary-level translation
validation**: an SMT-backed graph-refinement check that the *compiled ARM binary* refines the C
semantics — deliberately *removing the C compiler from the TCB* rather than trusting or re-verifying
it. `[DEMONSTRATED]`. This is the template this project should imitate for its trusted core: prove
at the source level, then *validate the actual binary per build* (§1c).

**What a VERIFIED IMPLEMENTATION still does not give you — the irreducible TCB.** Even CakeML/seL4-
class results are conditional on, and *silent about*:
- the **ISA / hardware model** being faithful (hardware errata, microarchitectural side channels
  — Spectre/Meltdown-class, Rowhammer, fault injection, cosmic-ray bit flips — live *outside* the
  model);
- the **assembler, linker, loader, OS, and I/O boundary** (unless themselves verified);
- **timing, concurrency, and the external world** (clocks, filesystems, network) at the trust edge;
- the **specification** being the right one (§3).
Enumerate this TCB explicitly for every A4 component. A "verified" stamp that hides its TCB is a
**BLOCKING** dishonesty.

### 1(c). TRANSLATION VALIDATION — per-run certificates checked by a checker

Instead of proving a *tool* correct once, prove each *output* correct every time, with an
independently checkable certificate. This is the most deployable, most honest, and most
under-used stratum.

- **SAT (mature).** UNSAT results emit **DRAT/LRAT** proofs; **LRAT is checked by a verified
  checker** — e.g. `cake_lpr` (CakeML-verified LRAT checker) or GRAT (Isabelle-verified). Result:
  a *machine-checked certificate that this particular UNSAT/tautology claim is valid*, with the
  solver *removed from the TCB*. `[DEMONSTRATED]`. This is the gold standard for the pattern.
- **SMT (partial, theory-dependent).** Proof production is *incomplete in practice*: cvc5/veriT emit
  **Alethe**/LFSC proofs reconstructable in Coq/Isabelle (SMTCoq, Isabelle `smt`); **Z3's proofs
  are notoriously partial/hard to check**. Coverage varies by theory (good: EUF, LIA fragments,
  bit-vectors; weak/absent: heavy nonlinear arithmetic, quantifier instantiation heuristics,
  strings). **Honest rule: an SMT result is A2 only for the theories/queries where a certificate is
  actually produced and checked; elsewhere the SMT solver is trusted (A0/A1 for that step).**
  `[IMPLEMENTED, partial]`.
- **Compiler translation validation.** Per-build binary refinement (seL4-style graph refinement;
  Alive2-style bounded validation of LLVM peephole passes). Validates *this build's* output, not
  the compiler in general; Alive2-class checks are *bounded* (SMT over bounded programs), so they
  find bugs and certify instances but are not a total compiler theorem. `[DEMONSTRATED]`.

**Exact limit of the whole stratum.** A per-run certificate says **"this specific output satisfies
the checked relation"** — nothing about the next input, and nothing about whether the *checked
relation* is the property you care about. The certificate's value collapses to the checker's
soundness (make it verified, §1b) *and* to the relation being the right relation (§3). A checked
certificate over the *wrong specification* is a rigorously-proved irrelevance.

### 1(d). EMPIRICAL — tests, benchmarks, measured behavior

Contrastive test suites, differential testing (Csmith-class), fuzzing, benchmark scores, latency/
availability measurements, and legal worked-examples. `[EMPIRICAL]` / `[DEMONSTRATED]` for a fixed
harness. **Testing shows presence of behavior on sampled inputs, never absence of error on the
input space** (Dijkstra). For legal fidelity, tests are the *primary* evidence available (§3) and
must be treated as strong-but-defeasible, never as THEOREM. Real deadlines / latency / availability
(project condition 5) are *correctness requirements* established here empirically (plus design
redundancy), not by proof.

---

## 2. The stratum lattice — what each level buys, precisely

| Level | Claim shape | Removes from TCB | Still trusts | Legal-core applicability |
|---|---|---|---|---|
| **A0 Unverified** | none | — | everything | LLM outputs, corpus ingestion, heuristics |
| **A1 Tested** | behavior on samples | — | code + spec + inputs unseen | fidelity evidence, regression safety |
| **A2 Certified-run** | *this output* satisfies R (checked) | the *producer* (solver/pass) | checker, R, TCB | proof-search results, deadline checks, gate decisions |
| **A3 Theorem** | formal object has P | producer *and* test-completeness | kernel, axioms, that P=intent | statute engines, invariants, protocols |
| **A4 Verified-impl** | *binary* refines P on modeled HW | the compiler | kernel, ISA/HW model, OS/IO, that P=intent | the trusted execution core |

**Reading the lattice honestly:** moving up removes trusted components but **never removes the
specification** (that `P`/`R` is the intended property) and **never removes the hardware/axiom
floor**. §3 is orthogonal to this entire table and *dominates* it for legal claims.

---

## 3. The formalization gap — why proof never reaches "the law"

### 3.1 The gap, stated exactly

Verification answers *"does the artifact satisfy the specification?"* Validation answers *"is the
specification the right one?"* Proof assistants are **verification** engines. The legal question —
*"does this formal rule faithfully capture Article X of Law Y as it will be applied by the competent
Greek/EU court?"* — is a **validation** question about a relation between:

- a **formal object** (precise, closed, machine-checkable), and
- an **informal object**: natural-language statutory text *plus* its authoritative interpretation
  — case-law, administrative practice, teleological/systematic/CJEU-conforming interpretation,
  higher-norm supremacy (Constitution, EU primary/secondary law, ECHR), lex-posterior/specialis
  conflict resolution, and Hartian **open texture** (genuinely indeterminate penumbra).

No proof can bridge these because one side is *not a formal object*: its meaning is partly
**contested, evolving, and institutionally assigned by courts**, not fixed by the text. Therefore:

> **[THEOREM-about-the-limit, informal]** For any formalization `φ` of a natural-language norm `n`,
> "`φ ⊨ P` is machine-checked" carries **zero** entailment toward "`φ` faithfully represents `n`."
> The two are logically independent. This independence is *structural*, not a maturity gap that
> 2027 tooling closes.

**Two prohibited equivocations (enforced):**
1. *Proof-checking ≠ formalization correctness.* A green kernel check is silent on fidelity.
2. *Model access ≠ idea inclusion.* Having an LLM or an oracle *read* a statute does not mean its
   content, exceptions, or cross-references were *represented*; and a model "considering" an
   argument is not the argument being *in* the formal object.

### 3.2 Mechanisms that genuinely narrow the gap — and their honest ceilings

The gap is **auditable and narrowable**, never provable-to-zero. Each mechanism converts opaque
fidelity risk into *reviewable, accountable, testable* risk.

1. **Isomorphism discipline (Catala-style).** Structure the formal program to mirror the legal text
   *article-by-article, clause-by-clause*, so every formal fragment has a bidirectional trace link
   to a specific legal fragment, and default-logic (base rule + exceptions/derogations) mirrors how
   statutes are actually written. **Narrows** by shrinking each review unit to a lawyer-checkable
   local correspondence and making the *whole* correspondence enumerable/auditable.
   **Ceiling:** isomorphism is to the *text*, not to the *law-as-applied*. It cannot encode
   cross-statute conflict, CJEU/ECHR-conforming reinterpretation, case-law glosses, or penumbral
   choices; modeling decisions (which reading of an ambiguous term) are *made silently inside*
   "faithful" mirroring. Isomorphism makes disagreement *locatable*, not *absent*.
   `[DESIGN-ENTAILED narrowing; EMPIRICAL fidelity]`.

2. **Dual / independent back-translation.** Independently render `φ` *back* to natural language
   (ideally by a different person/tool than the forward encoder) and reconcile against `n`;
   divergences flag suspected mismatches. **Ceiling:** shared misconceptions survive (both
   directions can embed the same error); NL targets are ambiguous so "matches" is a *judgment*;
   *omissions* (a whole exception never encoded) are the hardest to surface because there is nothing
   to back-translate. `[EMPIRICAL]`.

3. **Contrastive / differential test suites.** Curate worked cases with *authoritative* answers —
   official administrative guidance, court/CJEU decisions, ministry circulars, tax-authority rulings
   — including **adversarial near-boundary and near-miss pairs** (cases that differ minimally but
   flip the legal outcome). The formalization must reproduce every answer. **Ceiling:** this is
   `[EMPIRICAL]` evidence of fidelity over a *sample*; the legal input space is effectively infinite
   and partly interpretive, so passing is *strong corroboration, never proof*. Authoritative answers
   can themselves be overruled. Guard against test-tautology (tests written from the same reading as
   the formalization prove only self-consistency).

4. **Expert sign-off protocols.** Qualified lawyers formally attest fidelity of each `φ` under a
   *recorded* procedure: named reviewers, versioned artifact hash, explicit coverage boundary,
   recorded dissents, and an *attestation that is an accountable authority/liability act, not a
   truth guarantee.* **Ceiling:** experts disagree; sign-off certifies *responsible human judgment
   at time T*, and law changes at T+1 (new statute, new CJEU ruling) silently invalidating it —
   hence every attestation carries a **temporal-validity + scope** stamp and a re-review trigger on
   legal change. `[EMPIRICAL / institutional]`.

5. **N-version independent formalization + cross-diff.** Commission ≥2 independent formalizations of
   the same norm; *disagreement* provably reveals a gap somewhere; *agreement* is weak evidence
   (correlated errors from shared sources/training). **Ceiling:** agreement is not fidelity.
   `[EMPIRICAL]`.

**Net:** the highest attainable fidelity claim for any legal rule is
`[EMPIRICAL, expert-attested, scoped, dated]` — call it **F3** below. It is categorically **not** a
THEOREM and must never be stamped as one. This bound is the load-bearing honesty of the whole
architecture.

---

## 4. What THIS project can actually attain, per component

Two orthogonal stamps per component: an **execution-assurance level A0–A4** (§1–2, about
artifact→binary) and a **fidelity level F0–F3** (§3, about spec→law/intent). A component's honest
strength is the *pair*, and for legal claims the **F-level dominates**.

### 4.1 Components where A3/A4 + high-F are genuinely attainable (the trusted spine)

These have *machine-checkable* specifications (their "law" is a math/security property, so the
fidelity gap is *small and itself formalizable*), so they can reach A4 with F near-maximal:

- **Publication Gateway as a fail-closed lattice.** `[DESIGN-ENTAILED → A4-attainable, THEOREM-able]`
  Model release as a predicate that is *false unless* all conditions hold (privilege review passed
  ∧ DLP/confidentiality clear ∧ redaction applied ∧ authority validated ∧ human approval ∧ receipt
  emitted). Prove: (i) no path emits output with the predicate false (fail-closed by construction,
  making the error *structurally impossible* — the CLAUDE.md "eliminate the error class" doctrine);
  (ii) monotonicity/no-bypass; (iii) every release ⇒ immutable receipt. This is the single
  highest-value formal target: a *security/information-flow* property, provable to A3, pushable to
  A4 via CakeML/seL4-pattern, with F≈F3 because the spec *is* the requirement.
- **Confidentiality / privilege separation / memory isolation.** Non-interference and access-control
  lattice theorems; "no client-matter data crosses into a publishable channel except through the
  Gateway." `[A3/A4-attainable THEOREM]`, F-high.
- **Immutability & integrity of audit trail, receipts, proof logs.** Append-only, hash-chained,
  tamper-evident structures with proved invariants. `[A3-attainable]`.
- **Deadline / procedural-time computation.** Date arithmetic, court-holiday calendars, service/
  notification rules, statutory-period computation as *total, certified* functions with per-run
  certificates (A2) and total-function theorems (A3). **Caveat:** the *arithmetic* is A3/A4 with
  F-high; **which** period/rule applies to a given procedural posture is a *legal* mapping at
  F≤F3 (§3). Stamp the two separately — never let the proved arithmetic launder the legal mapping.
- **Procedural state machines / workflow legality invariants.** "No filing action reachable after
  the deadline state", "no state emits an act without required authority" — refinement/reachability
  theorems. `[A3-attainable]`.
- **Proof-search / rule-engine results at A2.** Whenever the trusted core answers a legal-logic
  query via SAT/SMT-class search, emit an LRAT/checked certificate; keep the solver out of the TCB;
  fall back to *honest "unknown"* (never a guess — CLAUDE.md `Τίμια άγνοια`) where no certificate
  is producible. `[DESIGN-ENTAILED]`.

### 4.2 Components with an irreducible fidelity ceiling (F ≤ F3, never THEOREM)

- **Every substantive legal conclusion** (how a statute/case applies to a matter). Best attainable:
  `A2/A3 execution` (the *reasoning steps and rule application* can be certificate-checked and the
  *engine* proved sound w.r.t. its formal rules) **combined with** `F≤F3 fidelity` of those rules to
  the actual law. **The conclusion's legal correctness is at most `[EMPIRICAL, expert-attested]`.**
  This is the hard ceiling and must be stamped on every legal output.

### 4.3 Components that are irreducibly A0 — the untrusted zone

- **LLM reasoning / drafting / retrieval ranking.** `[A0, UNKNOWN per-output]`. Consistent with
  CLAUDE.md's *no LLM on the trusted path*: LLMs may *propose, draft, search, and explain* in the
  untrusted zone, but **no LLM output crosses a trust boundary except as an input to a verified
  gate** (Gateway, rule-engine with certificate, or human sign-off). *Model access ≠ idea inclusion*
  is enforced structurally: the LLM's "consideration" of an argument has no standing until the
  argument is represented in an F-tracked formal object or attested by a human.

### 4.4 The supremacy goal (project condition 7) — stated without circularity

`[HYPOTHESIS]`, never THEOREM. "Superiority" cannot be a proved property (no circular self-scoring).
The honest, non-circular form: *a bounded EMPIRICAL claim* — "under a defined resource envelope,
equal data, and equal procedural position, on a **pre-registered, authoritative-answer** contrastive
benchmark, the system's certified-correct outputs meet-or-exceed comparator outputs at rate R with
CI, while emitting *honest-unknown* rather than fabrication on the remainder." Superiority is then a
*measured*, dated, scoped claim — plus the *structural* advantages that **are** design-entailed
(fail-closed gate, certificate-backed reasoning, immutable audit, no-fabrication discipline). No
metric may define superiority in terms of the system's own judgments (anti-circularity is a
**BLOCKING** review gate).

---

## 5. Recommended assurance-level taxonomy (the stamp every component and claim carries)

Every component, artifact, and *individual claim* carries a **four-field stamp**:

```
⟦ A-level | F-level | Evidence | Scope&Validity ⟧
```

**Axis A — Execution assurance (artifact → running binary):**
- **A0 UNVERIFIED** — no formal guarantee (LLMs, ingestion, heuristics).
- **A1 TESTED** — empirical only; no proof. Record harness + coverage.
- **A2 CERTIFIED-RUN** — per-output certificate (LRAT/checked-SMT/binary-TV) validated by a
  verified/independently-audited checker; producer out of TCB. Scope = *this output*.
- **A3 THEOREM** — machine-checked property of the *formal object*; small trusted kernel; axioms
  and "P=intent" disclosed.
- **A4 VERIFIED-IMPL** — A3 pushed to the *binary on a modeled processor* via verified compilation
  (CakeML-class) or per-build binary translation validation (seL4-class), **with the residual TCB
  enumerated inline** (kernel, ISA/HW model, OS/IO, assembler/linker).

**Axis F — Formalization fidelity (spec → law/intent):**
- **F0 NONE** — no lawyer review of the formal-vs-legal correspondence.
- **F1 ISOMORPHIC-DRAFT** — Catala-style article-mirroring with bidirectional trace links; not
  attested.
- **F2 EXPERT-REVIEWED** — F1 + dual back-translation reconciled + contrastive suite passing +
  named qualified-lawyer sign-off under recorded protocol.
- **F3 ADJUDICATED-SCOPED** — F2 + corroboration against authoritative decisions/guidance for a
  *declared* coverage boundary, with an explicit **open-texture register** listing known
  indeterminacies and modeling choices. *(F3 is the ceiling; there is no "F4 = proven-correct".)*

**Field 3 — Evidence pointer:** the actual artifact (proof term hash, LRAT file, test-suite id +
result, attestation record id). No stamp without a resolvable evidence pointer.

**Field 4 — Scope & temporal validity:** input domain covered + legal-version/date the fidelity was
established at + re-review trigger (statutory amendment, new CJEU/ECHR/Areios Pagos ruling in scope).
Legal fidelity *expires*; the stamp makes expiry explicit.

**Composition rule (mandatory, anti-laundering):** a claim's overall strength is the *weakest*
relevant field, and **A-level never upgrades F-level**. A deadline delivered as
`⟦A4 | F1 | proof#… | Greek CCP arts …, valid @2026-08⟧` is a *proved computation over an unattested
legal mapping* — it must **not** be reported as "verified deadline". Proved-arithmetic may never
launder unattested legal fidelity. Enforcing this is a **BLOCKING** review gate.

---

## 6. Contradictions that stay BLOCKING until the architecture resolves them

1. **"0 error / ΤΙΠΟΤΑ ΜΕΤΡΙΟ" (CLAUDE.md) vs. the irreducible §3 gap.** *Resolution to adopt
   explicitly:* "0 error" is attainable and demandable for **A3/A4 machine-checked properties and
   fail-closed security invariants**; it is **categorically unattainable** for legal-conclusion
   correctness, which tops out at F3 EMPIRICAL. The supreme law is honored *maximally* by making the
   *error class structurally impossible where it can be* (fail-closed Gateway, no-bypass lattices,
   certificate-or-honest-unknown) and by *never overstamping* the rest. Any claim of proved legal
   correctness is a violation of both the honesty discipline and the creator's own
   `Τίμια άγνοια` law. **BLOCKING** until the architecture writes this stratification into its claim
   policy.
2. **Trusted-path purity vs. LLM utility.** Resolved by §4.3 (LLMs untrusted-zone only; cross a
   boundary solely as gate input). **BLOCKING** if any design routes unverified LLM output into a
   trusted decision without a verified gate.
3. **SMT convenience vs. TCB honesty.** Any trusted-core use of SMT without a produced+checked
   certificate silently puts Z3/cvc5 in the TCB. **BLOCKING** unless either a certificate is checked
   (A2) or the SMT step is explicitly quarantined to the untrusted zone.
4. **Supremacy claim circularity.** **BLOCKING** unless benchmarks use *external authoritative*
   answers and never self-scored metrics (§4.4).

---

## 7. Bottom line for the architecture

- Build a **small, formally verified trusted spine** (Publication Gateway fail-closed lattice,
  confidentiality/isolation, immutable audit, deadline/procedure engines, certificate-checked
  proof-search) targeting **A3, pushed to A4** via a CakeML-class compiler and/or seL4-style
  per-build binary translation validation, **TCB enumerated**. `[DESIGN-ENTAILED, attainable]`.
- Encode substantive law with **Catala-style isomorphism (F1) → expert-attested (F2) → adjudicated-
  scoped (F3)**, knowing F3 is the ceiling and legal correctness stays **EMPIRICAL**. `[attainable
  to F3, never THEOREM]`.
- Keep **LLMs strictly A0/untrusted**, gated. `[DESIGN-ENTAILED]`.
- **Stamp everything** with `⟦A | F | Evidence | Scope&Validity⟧`; enforce the composition rule so
  proved execution never launders unattested legal fidelity, and forbid any THEOREM tag on a
  legal-conclusion claim.
- Treat the §3 gap and §6 contradictions as *permanent architectural features to be managed and
  disclosed*, not defects to be closed — because they are, provably, not closable.
