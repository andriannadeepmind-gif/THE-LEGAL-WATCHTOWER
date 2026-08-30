# RESOLVE-R3 — Correlated-model false-consensus on a population-shared blind spot

**Team:** RESOLUTION R-3. **Date:** 2026-08-28. **Target:** CANON-OMEGA2 §9 R-3 (Tournament B-3, RANK 3,
epistemic ceiling), grounded in §5.6, `agent-systems` §8, `formal-boundaries` §3.
**Binding:** internal single-firm Greek super-system; only the strongest **containment** is sought.
**Forbidden and NOT claimed:** ELIMINATION; circular resolution ("solved by redefining"); relabel-and-move.
**Claim-status discipline:** every substantive claim tagged. Proof-checking ≠ formalization correctness;
model access ≠ idea inclusion.

---

## 0. The contradiction, stated exactly (so it cannot be wordsmithed)

R-3 is the population-level form of sycophancy. `[DESIGN-ENTAILED framing]`

> A blind spot shared by the **entire available frontier-model population** (common pretraining
> distribution, shared published-case/statute corpora, shared weak points — GreekBarBench: *all* models
> fail most on statutory-article identification) produces N models that are **confidently wrong in the
> same way**. Any defender *drawn from that population* — a larger ensemble, a distinct-vendor sibling,
> an independently-founded self-adversary — shares the blind spot and therefore cannot see it. Naive
> ensembling reads the resulting agreement as *confidence*. And whether enough genuinely-independent
> model foundations even exist to break the correlation is **UNKNOWN** (`agent-systems` §8.1–8.2;
> `autopsy` weakness 1).

This is the exact reason **generator-superset ≠ idea-superset** (§5.6; `autopsy` Claim 6). It is a real
ceiling, not a conflation. **It will not be dissolved.** The only honest program is to (i) make the
correlated wrong *proposal* unable to be **laundered into a trusted output** wherever a non-model check
can fire, (ii) route what no formal check can reach to the one oracle **outside** the population, (iii)
**measure** the correlation so the blind spot is visible even when it is not caught, and (iv) name the
exact residue that survives all three and prove it equals the human ceiling — no smaller.

**The load-bearing move up front (defeats the UNKNOWN):** the containment is deliberately built so it does
**NOT depend on independent model foundations existing.** Its two catching organs are a **deterministic
non-model recompute** and a **human**, both independent of the model population *by construction*, not by
the unproven hope that decorrelated foundations exist. The UNKNOWN about model independence therefore
stops gating the defense; it only caps the model population's own contribution. `[DESIGN-ENTAILED]`

---

## 1. Decompose the wrong-consensus by the KIND of error it produces

The seam (`agent-systems` §0) already makes every model output an **untrusted proposal** crossing a
fail-closed admission boundary. R-3 bites only if a *correlated-wrong* proposal can become an
authority-bearing artifact. So the question is entirely: **which kinds of correlated-wrong proposal can
the trusted region catch with a checker that is NOT itself a model?** Partition the blind-spot error space:

| Error kind the shared blit produces | Canonical example | Non-model checker that fires | Verdict on the **admission** of this sub-class |
|---|---|---|---|
| **Fabricated / non-existent authority** | all models cite a hallucinated article | K-src byte-identical source resolution (§3.2) | **un-admittable** — REJECT even at N=all |
| **Real-but-repealed / not-yet-in-force** | all cite a version out of its interval | K-src in-force-interval check (I-SRC) | **un-admittable** |
| **Byte-non-identical quotation** | all mis-quote the same way | K-src canonical-TTL validate-before-emit | **un-admittable** |
| **Deadline / day-count arithmetic** | all miscompute a CCP term | K-typ + checked proof over the date calculus | **un-admittable as "verified"** (A-level) |
| **Formal-logical inconsistency** | all assert a set that contradicts | K-prf checked certificate | **un-admittable** |
| **Sound-dominance-violating draft** | all keep a strictly-worse candidate | tournament sound-dominance edge (§2.3) | eliminated by objective test |
| **Wrong *applicability* of a real, in-force, correctly-quoted authority** | all pick art. 914 (exists, in force, byte-identical) where 919 governs *these* facts | **NONE** — this is open-texture (formalization gap, `formal-boundaries` §3.1 THEOREM) | **passes every formal check** → §2 |
| **Wrong open-texture *judgment*** | all read a balancing test the same wrong way | **NONE** | **passes every formal check** → §2 |

**Reading of the table.** The KIND-diversity of the trusted spine (it is non-LLM: recompute, proof-check,
type-stamp — `agent-systems` §8.3, "the symbolic member's errors are structurally uncorrelated with the
LLM's") **structurally strips the fact/citation/deadline/arithmetic/consistency sub-classes out of the
admissible set — and does so at N = the entire population, because agreement is never an admission
predicate.** The very canonical R-3 example — GreekBarBench's *statutory-article-identification* blind
spot — splits: its **non-existence / wrong-text / stale** face is **un-admittable** (K-src recompute); its
**wrong-applicability** face survives (a real article, correctly cited, wrongly *chosen*). `[DESIGN-ENTAILED
that the recompute fires on the resolvable faces; EMPIRICAL what fraction of real blind-spot errors have a
resolvable face — measured in §5(a)]`

**What this catches, precisely:** facts, citations, quotations, in-force status, deadline arithmetic,
internal logical consistency, sound-dominance. **What it structurally CANNOT catch:** whether a valid
authority is the *legally applicable* one, and how it *applies to open-textured facts* — because one side
of that relation is not a formal object (`formal-boundaries` §3.1 THEOREM: `φ ⊨ P` machine-checked carries
**zero** entailment toward "`φ` faithfully represents `n`"). That is the whole judgment axis, and it is
handed to §2. **No elimination is claimed:** a sub-class is made un-admittable; R-3 as a whole is not.

---

## 2. The judgment axis — the one oracle OUTSIDE the model population

On the residual (real, in-force, byte-identical authority, wrongly *applied*), **every model-drawn
defender is blind by R-3's own definition, and every formal checker is blind by the formalization-gap
THEOREM.** Exactly one class of defender remains whose errors are **not** drawn from the frontier-model
distribution: the **human Greek-law expert**. `[DESIGN-ENTAILED as the structural defense on the judgment
axis]`

- **Why it is structural, not decorative.** The human is the single member of the review population whose
  training distribution is *not* the shared pretraining corpus. Their errors decorrelate from the model
  blind spot **on the axes where they are genuinely expert** — which is precisely open-texture Greek-law
  application, the axis no formal check reaches. This is the only available source of *kind*-independence
  on the judgment axis (§8.3's "different modality" taken to its limit: a non-model reasoner).
- **The routing trigger is a mode-tag, never a confidence score.** K-typ (§3.4) stamps each conclusion
  `{PROVED|REFUTED|UNKNOWN|STABLE} × ⟦A|F|Ev|Scope⟧`. Any conclusion whose fidelity rests on
  **normative-judgment / open-texture** (F-axis, not A-axis) is routed to the human oracle **before
  emission** for irreversible / publication-gated stakes. Routing is driven by the *kind of claim*, not by
  how much the models agreed — so a high-agreement wrong judgment gets *more* scrutiny, not less.
- **THE ANTI-CORRELATION REQUIREMENT (the subtle attack on this very defense).** If the model consensus
  ("9 of 10 agree") is shown to the human, the human **anchors** and defers — the oracle correlates
  *into* the population and I-ORACLE degrades to a rubber stamp. R-3 would re-enter through the back door
  of my own containment. **Mitigation, mandatory:** the human judges **blind to the model consensus** —
  presented the *proposal and the sources*, never the vote count — reusing the §5.6 identity-blinding
  already applied to the socket layer, and coupling to R-8's discipline ("agreement is not evidence"). The
  human's signed judgment is produced *from source*, and only then may the model-set output be admitted.
  `[DESIGN-ENTAILED; the blinding effect is EMPIRICAL — measured in §5(b)]`

This is a **REDUCED-TO-HUMAN-LIMIT** move, not an elimination: the human oracle catches the
population-shared judgment blind spot **iff the human does not also hold it.** When the human shares it,
nothing in the system fires — that is §4.

---

## 3. Making the blind spot VISIBLE even when it is not caught (the metric)

Containment must not silently pretend the ceiling is gone. The **effective-independent-members** instrument
(`agent-systems` §8.4) is the honesty gauge, with a sharp statement of *what it can and cannot* surface:

- **What it makes visible.** On a held-out, matter-disjoint probe **with known ground truth (K-src-
  verifiable)**, uniform-*wrong* agreement drives measured pairwise disagreement → 0 → effective-count → 1,
  which **raises the `non-admissible-as-confidence` flag.** The population blind spot is thus made *visible
  and measured* on the ground-truthable axis: the certificate reports **effective-independent-members, not
  N**, and stamps N-model agreement as *not confidence* whenever the effective count collapses. A route
  paying N× compute for ~1× coverage is flagged, not trusted. `[DESIGN-ENTAILED]`
- **What it CANNOT make visible (stated, not hidden).** On an **open-texture** probe with **no ground
  truth**, uniform agreement is *indistinguishable* from correct consensus — the metric sees low
  disagreement but cannot score it wrong. So the instrument surfaces the blind spot exactly where §1's
  recompute already could have caught it, and is **blind exactly where §2's human is the only defense.**
  The metric therefore **measures the risk and caps the confidence claim; it does not catch the
  open-texture core.** Honestly: it converts an *invisible* ceiling into a *measured* one — which is the
  most the population can do to audit itself, and no more (`convergence-audit`: a regime cannot detect a
  blind spot it shares). `[DESIGN-ENTAILED the visibility on ground-truthed probes; THEOREM-adjacent that
  it is blind on no-ground-truth probes]`

---

## 4. The irreducible residue — and the proof it equals the human ceiling

**Definition (the exact surviving core).** A legal proposition on which **all three** hold:

1. **every model in the available population is wrong the same way** (population blind spot); AND
2. the error is an **open-texture application / judgment** error yielding a **real, in-force,
   byte-identical-resolving** authority — so **no** K-src recompute, K-prf certificate, K-typ arithmetic,
   tournament dominance, or effective-members metric can fire (it passes every formal check); AND
3. the firm's **own Greek-law expert(s), judging blind from source, hold the same reading.**

**Claim: this residue equals the shared-blind-spot limit of a top human legal team — no larger, no
smaller.** `[DESIGN-ENTAILED that it is ≤ the human limit; THEOREM-adjacent that it is ≥]`
- **≤ human limit:** every error *kind* a top human team would *also* catch (bad cite, stale law,
  miscount, contradiction) is stripped by §1 *before* the human is even consulted, and the model
  population's search breadth is strictly ⊇ any single opponent's on the *formalizable, model-reachable*
  fragment (generator-superset, weak — §5.6). So on everything a checker or a breadth-of-search can reach,
  the system is not worse than the human team.
- **≥ human limit (why it cannot be pushed below):** condition (3) *is* the definition of a
  prevailing-doctrine / school-of-thought blind spot — a settled misreading the **whole competent
  community** holds until a court moves the law (Hartian open texture, `formal-boundaries` §3.1;
  penumbral indeterminacy). A top human legal team faces exactly this and has exactly one non-solution:
  a **second expert of a different school** may dissent — which is why the system keeps the human oracle
  *plural and cross-school* where stakes warrant, estimating (never closing) the residual. There is no
  defender left that is both *outside the model population* and *outside the human community* — so the
  residue cannot be driven below what a human team faces. `[DESIGN-ENTAILED]`

**This is REDUCED-TO-HUMAN-LIMIT, and its magnitude is UNKNOWN** — estimable only by a second
independent-school expert panel, never provable to zero. It couples to R-1 (a novel-at-speed node gives no
time to convene the cross-school panel) and inherits R-5 (a mode-mislabel by K-typ that routes an
open-texture item as computational would skip the oracle entirely — the mode-laundering failure).

**Anti-circularity check (the specific sin R-3 hunts).** No step redefined the problem. R-3 stays a real
ceiling; §1 does *actual* non-model work (verifiable by the GreekBarBench replay §5a); §2 hands the
unverifiable core to a defender genuinely *outside* the population; §3 admits precisely where it goes
blind; §4 locates the residue at the human limit **and** flags the anchoring channel by which the
containment could have secretly re-correlated the human back *into* the population (armed with blinding).
The contradiction is **not moved elsewhere** — its formal-checkable share is *removed from admissibility*,
its judgment share is *lowered to the human ceiling and measured*, and the honest remainder is *named*.

---

## 5. Mechanism 5-tuple — the population-blind-spot containment rail

**Component:** compose three seats (no new TCB) into one rail: the **KIND-different non-model verifier
layer** + the **outside-population blinded human oracle** + the **effective-independent-members visibility
gauge**.

- **Seat.** (1) K-src recompute-from-source (`source/write-authority.lisp:emit-graph` guarded by
  `source/validation-authority.lisp` + `source/merkle-authority.lisp`) plus the deterministic checker
  family K-prf/K-typ (`source/proof-carrying.lisp`, gate-registry) — the non-LLM verifier of *different
  kind*; (2) the **human Greek-law expert oracle** as a first-class review seat on
  `source/review-queue.lisp`, **identity-/consensus-blinded** via the §5.6 blinding, triggered by the
  K-typ open-texture (F-axis) tag ∧ irreversible/publication-gated stakes; (3) the
  **effective-independent-members** instrument in the coverage certificate (`agent-systems` §8.4).
- **Interface.** `contain_consensus(proposal-set, matter) →` on the **verifiable subset**: recompute every
  authority/quotation/in-force-interval/deadline/consistency claim against authenticated source —
  *agreement is discarded as input*; a byte-non-identical, out-of-interval, or arithmetically-wrong claim
  **REJECTS even when produced by the whole population**. On the **open-texture subset** (K-typ tag ∈
  {UNKNOWN, normative-judgment, F-fidelity-bearing}): route to the **blinded** human oracle; require the
  expert's **signed judgment from source** (never the vote count) before emission; where stakes warrant,
  require a **cross-school second expert**. Attach `effective-independent-members(probe)` to the
  certificate and stamp agreement `non-admissible-as-confidence` whenever the effective count → 1.
- **Invariant.**
  **(I-KIND)** No admitted record's authority/quotation/deadline/consistency content is trusted *because
  models agreed*; it is trusted only because a **non-model deterministic recompute PASSED** — N-model
  agreement is never itself an admission predicate. `[DESIGN-ENTAILED; targeted THEOREM at the admission
  bus]`
  **(I-ORACLE)** No open-texture-tagged conclusion crosses to output without a **human-expert sign-off
  produced blind to the model consensus.**
  **(I-VIS)** No coverage certificate reports N as coverage; it reports **effective-independent-members**,
  and flags agreement at effective-count ≈ 1 as non-admissible-as-confidence.
- **Failure mode.** **The irreducible core (§4):** a proposal uniform across the whole population that
  PASSES every deterministic recompute (open-texture *applicability/judgment*, not a fact/cite/arith
  error) **and** is *also* held by the blinded human expert (shared prevailing-doctrine reading) — no
  organ fires: kind-diversity is blind to open texture, and the one outside-population oracle shares the
  error. **Secondary:** human **anchoring** — if consensus leaks un-blinded, the oracle correlates into the
  population (I-ORACLE → rubber stamp). **Tertiary:** K-typ **mode-mislabel** routes an open-texture item
  as computational, skipping the oracle (R-5 / `design-C` item-10 inheritance). **Quaternary:** at a
  novel-at-speed node (R-1) there is no time to convene the cross-school panel.
- **Verification.** (a) **GreekBarBench statutory-article-ID replay** — feed the known population-shared
  wrong-article items; assert the *resolvable* faces (non-existent/stale/mis-quoted) are **100%
  REJECT-or-corrected** by K-src and **none admitted**, and *measure* the fraction whose face is
  wrong-applicability only (the part that survives to §2). (b) **Anchoring A/B** — same expert, model
  consensus **shown vs blinded**; measure deference/flip rate; blinding must restore independent-judgment
  baseline. (c) **Metric on ground-truthed probe** — uniform-*wrong* agreement must drive
  effective-count → 1 and raise the non-admissible flag (blind spot made VISIBLE on the ground-truthable
  axis). (d) **Residue probe (no ground truth)** — seed items where models *and* one expert panel agree; a
  **second independent-school panel** adjudicates; the residual disagreement rate **estimates, never
  closes,** the human-shared blind-spot floor.

---

## 6. Honest status label + the exact irreducible residue

**ELIMINATION: REFUSED** (forbidden; and false — a population-shared open-texture blind spot cannot be made
structurally impossible). Decomposition across the binding taxonomy:

**⟨ (sub-class) ELIMINATED-AS-ADMISSION · CONTAINED-AND-MEASURED · REDUCED-TO-HUMAN-LIMIT · STILL-UNKNOWN ⟩**

1. **ELIMINATED as an *admission* risk (a sub-class only, NOT R-3):** the
   fact / citation / quotation / in-force / deadline-arithmetic / logical-consistency face of the shared
   blind spot — incl. the resolvable face of the canonical GreekBarBench statutory-article failure — is
   **structurally un-admittable**, because a non-model recompute (not agreement) is the admission
   predicate. `[DESIGN-ENTAILED; targeted THEOREM at the bus]`
2. **CONTAINED-AND-MEASURED:** the population-shared open-texture blind spot is made **visible** by
   effective-independent-members on ground-truthed probes and its confidence claim is capped; the metric
   is honestly declared **blind** on no-ground-truth probes.
3. **REDUCED-TO-HUMAN-LIMIT:** the open-texture judgment axis is defended by the **one oracle outside the
   model population** — the blinded, where-warranted cross-school human Greek-law expert.
4. **STILL-UNKNOWN, but de-gated:** whether enough genuinely-independent *model foundations* exist stays
   UNKNOWN — but the containment was built **not to depend on it** (its catchers are a deterministic
   recompute and a human, independent by construction). The UNKNOWN caps the model population's own
   contribution; it no longer gates the defense.

**Overall:** R-3 downgrades from **BLOCKING (unmeasured epistemic ceiling)** to **CONTAINED-AND-MEASURED on
the verifiable axis (fact/citation sub-class made un-admittable) + REDUCED-TO-HUMAN-LIMIT on the judgment
axis** — **not ELIMINATED, not DISSOLVED** (it was never a conflation; it is a real ceiling, honestly
lowered to the human ceiling and made visible, not removed). It does **not** upgrade generator-superset to
idea-superset (§8.5-ii); it only prevents a whole-population wrong idea from being *laundered* into a
trusted output on the checkable axis, and routes it to the one non-population judge on the rest.

**EXACT IRREDUCIBLE RESIDUE (one sentence):** a legal proposition on which (1) every model in the available
population is wrong the same way, (2) the error is an open-texture *application/judgment* error that yields
a real, in-force, byte-identical-resolving authority — so no recompute, proof-check, arithmetic, dominance
test, or effective-members metric can fire — and (3) the firm's own Greek-law expert(s), judging blind from
source, hold the same prevailing-doctrine reading; **this equals the schools-of-thought / prevailing-doctrine
blind spot every top human legal team also carries until a court overturns it — REDUCED-TO-HUMAN-LIMIT, of
UNKNOWN magnitude, estimable only by a second independent-school expert panel and never closable**, coupling
to R-1 at the novel-at-speed node and inheriting R-5 at the mode-mislabel edge.

**One-line for §9:** R-3 → **CONTAINED-AND-MEASURED + REDUCED-TO-HUMAN-LIMIT** — the correlated-wrong
proposal is un-admittable wherever a non-model recompute fires (the GreekBarBench article sub-class
included), measured wherever ground truth exists, and otherwise handed to the one oracle outside the model
population; the surviving core is exactly a top human team's shared-doctrine blind spot, no smaller.
