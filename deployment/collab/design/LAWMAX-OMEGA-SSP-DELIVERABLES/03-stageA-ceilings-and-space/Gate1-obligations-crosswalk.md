All four inputs are now fully extracted, including the term-level searches that settle the DF-043 question (zero occurrences of "common-mode", "two-kernel", "HF-001", "I-41", "I-42", or "entrench" anywhere in the v2 corpus). Here is the crosswalk.

---

# INHERITED-OBLIGATIONS CROSSWALK — Gate #1, SSP-Omega

**Inputs:** `_gate1_obligations.json` (29 OBLs), `_gate1_defeaters.json` (51 defeaters, 10 OPEN), `_ssp_ceilings_v2.json` (AX-01..AX-22, frozen guarantee profiles), `_ssp_closure_v2.json` (DIM-01..DIM-16, 17 canonical classes, FOC-04 checklist).

**Coverage standard applied (honesty rule):** COVERED means a design *attaining* the cited frozen guarantee necessarily passes the obligation's dominance test — an entailment argument, not thematic similarity. Where the entailment runs through the instrument's corpus-wide evidence conventions (witness-appendix convention, evidence-status tags) rather than an axis, that is stated explicitly. PARTIAL names exactly what is missing. Only frozen guarantee statements and closure decisions are cited as covering instruments; attainment-witness appendices are quoted only as evidence of *non*-coverage (they are non-frozen and carry no rank).

---

## Part A — The 29 obligations

**OBL-01 — Supply a working, verifiable authority path.**
→ **AX-12** + **DIM-05** (single-writer-kernel-arbitration). AX-12: "every trusted state transition is admitted by one total, pure, decidable kernel predicate K(state, transition, certificate) … EVERY other outcome — including an error inside the gate's own predicates — is a recorded, signed refusal with zero state change (fail-closed totality)." DIM-05: "every acceptance AND refusal a signed, durable derivation." The "spec-that-no-code-realises does not discharge" half is carried by the witness-appendix convention: attainment is "UNKNOWN pending independently re-checkable verification artifacts (replay artifacts and discharged proof obligations)" — a specification cannot attain. **COVERED.**

**OBL-02 — Discharge the blocked proofs or replace the claim with one dischargeable with tools that exist.**
→ **AX-21** + the per-axis `lean_obligation` apparatus. Every ceiling carries a lean_obligation naming the exact proof artifact and asserting Lean-4 formalizability ("All over finite decidable structures, Lean 4 formalizable"); DIM-06 names the environment ("offline-vendored Lean 4 toolchain"). AX-21 additionally forbids the terminal-blocked state: for an unverified-compiler commitment "link-type (b) [recompute-and-compare / diverse re-verification] is the optimum FOR THAT COMMITMENT" — i.e., every load-bearing link has a named, presently-producible discharge route (proof or conformance). **COVERED** (jointly by AX-21 and the instrument's lean_obligation discipline).

**OBL-03 — Make the build match its hermeticity contract, or withdraw the contract.**
→ **AX-13**: "an independent third party holding only the certificate and the committed closure can, fully offline and with zero producer trust, verify that the output is the unique derivation result." Offline recomputation from the committed closure (which includes "source bytes, code identity, pinned toolchain identity, configuration") is impossible if the derivation reaches outside the closure at build time — attaining AX-13 entails the network-free rebuild. The "or withdraw" disjunct is the corpus evidence discipline (unverifiable claims are typed HYPOTHESIS, never asserted). **COVERED.** (Note: the words "hermetic"/"network" appear nowhere; coverage is by entailment from offline verifiability, not by an explicit hermeticity clause.)

**OBL-04 — Bind recorded results to the code they describe.**
→ **AX-13** (primary), **AX-06**. AX-13: certificate "binding it, via collision-resistant hash commitments, to the COMPLETE closure of its derivation (source bytes, code identity, …)"; AX-06 commits each step as "(input-hash, deterministic-transformation-id, output-hash)". A result whose identity mismatches the committed tree fails recompute-and-compare, and AX-12/H3 make failed verification a refusing state. **COVERED.**

**OBL-05 — Validate deployment definitions, not only their security shape.**
→ **AX-09 clause (c)** covers half: "coverage is a positively-proven census (absence of a check is itself a detectable, blocking state — no silent gap)" — a missing deployment-validation check cannot be silent. But the census permits "enumerated-unchecked"; no frozen clause entails an actual *semantic validator* for deployment artifacts (malformed mount option, missing command). AX-02's decidable defect class governs plan DAGs, not operational definitions. **PARTIAL** — missing: an instrument clause extending the AX-09 declared decidable check class (or AX-02's admission class) to mandatory semantic well-formedness validation of operational/deployment artifacts in the release closure.

**OBL-06 — Restore ingestion's entry point and network configuration, or delete the service.**
→ **AX-02** covers the structural analogue: "orphan stage feeding no goal" and "goal artifact unreachable from admitted inputs" are "made structurally inadmissible at plan-derivation time (fail-closed)." A service modeled as a plan stage that cannot reach its declared goal is inadmissible. But the operational half — a service *definition* (entry point, network wiring) unable to perform its declared purpose — is the same uninstrumented deployment-artifact layer as OBL-05. **PARTIAL** — same missing instrument as OBL-05.

**OBL-07 — Constrain the proof runner, or make its exemption explicit and bounded.**
→ **AX-21**: the refinement chain terminates "in an explicitly enumerated, minimized, hash-committed Trusted Computing Base (proof checker, compiler+runtime image, OS loader, hardware)." The proof checker's exemption is exactly "explicit and bounded": enumerated, minimized, hash-committed. AX-19 rung 1 adds "absence of out-of-model effects enforced by the OS capability model." **COVERED.**

**OBL-08 — Verify anchored content, not transport status, or downgrade the guarantee.**
→ **AX-04**: the ABSOLUTE negative half — "a digest commits to WHAT was received, never to WHO published it" — plus derivation binding "E(captured-bytes) = t" byte-equality, with everything below the three positive mechanisms "admissible only as typed UNKNOWN/provisional." Attaining AX-04 makes a transport-status-only "guarantee" structurally impossible. The naming-the-code half ("every use of GUARANTEE must name the code") is carried by the witness convention plus AX-13's binding of outputs to code identity. **COVERED.**

**OBL-09 — Every declared gate must have an implementation or be withdrawn.**
→ **AX-09(c)** + **AX-12**. AX-09(c): absence of a check is "a detectable, blocking state — no silent gap"; a gate-table row with no executable can produce no certificate and therefore reads as an absent check, which blocks. AX-12's fail-closed totality requires recorded, signed refusals — producible only by an executing gate. **COVERED.**

**OBL-10 — Classify by content and mode, not by extension.**
→ **AX-06** fail-closed totality: verification is "TOTAL OVER THE RELEASE CLOSURE … Any artifact lacking a complete chain, or any step failing verification, blocks the release." The census is content-addressed (hash commitments), so an extensionless planted executable is an artifact in the closure with neither grounded-root status nor a lineage chain — it blocks. Entailment holds provided the release closure is defined as the exhaustive byte inventory, which the totality clause states. **COVERED.**

**OBL-11 — Delete or repair the dead probe.**
→ **AX-09(c)**: census entries are "checked-with-certificate or enumerated-unchecked", a missing entry "unrepresentable in the manifest type" (lean obligation T4), and the positive-proof pattern means "a crash yields no manifest, never a false green." A file counted as covered while unreachable by any runner is structurally impossible: the covering certificate cannot exist without an execution. The honest alternative (enumerated-unchecked) makes the dead probe visible, forcing repair or deletion. **COVERED.**

**OBL-12 — Make the two specifications agree on the path.**
→ **AX-09(a)/(b)** gives the shape: contradiction detection "provably complete WITHIN a declared decidable class over the committed inputs," with the class boundary "a committed, certificate-carrying, machine-enforced artifact (not prose)." Inter-contract cross-reference resolution is decidable and could sit in that class — but no frozen clause *entails* that the declared class includes it; that is an instantiation choice. **PARTIAL** — missing: a committed well-formedness rule (in the AX-09 declared class or as an AX-13 closure condition) that all cross-references between committed spec artifacts resolve.

**OBL-13 — Audit GATE-1, GATE-2, GATE-3, GATE-5 as GATE-4 was audited.**
→ **AX-09(c)** + **AX-10(3)**. The coverage census makes the unaudited-gate state explicit and blocking, and AX-10: "every hypothesis, mutant, or counter-design outside both regimes … is a typed UNKNOWN that fail-closed blocks release … and escalates to the accountable human authority." Attaining these makes "clean bill by silence" impossible — the other four gates are forced to be either audited or a typed, blocking, recorded residual, which is exactly what the dominance test demands. **COVERED.**

**OBL-14 — Regenerate or remove the stale repository graph.**
→ **AX-13/AX-06** recompute mode: the output must be "the unique derivation result" of the committed closure. A published graph pinning a commit outside the release's lineage cannot equal the byte-identical recomputation from the committed tree; verification fails and AX-06 blocks the release. **COVERED.**

**OBL-15 — Restore the ratchet rule's written statement.**
→ **AX-20**: the ratchet is a committed object, not folklore — the certificate "recomputes (never trusts) the committed capability-floor vector Floors(S_n) from the previous release's hash-chained census" and proves conditions (1)–(4). Attaining AX-20 entails the rule exists as committed, reviewable, machine-checked artifacts. **COVERED.**

**OBL-16 — Pin the SBOM tooling by digest.**
→ **AX-13** ("pinned toolchain identity" inside the committed closure of every trusted output) + **DIM-06** tcb-minimized-root ("enumerated, hash-committed TCB with full-source bootstrap … reproducible builds … binary transparency"). Scoping note: the entailment holds because supply-chain evidence (SBOM) is itself a trusted output, so its producing workflow is inside the closure discipline. **COVERED.**

**OBL-17 — Remove the Quicklisp path or withdraw the claim.**
→ **AX-21/AX-13**: a Quicklisp-style unpinned network dependency channel cannot coexist with a chain whose every link is "a machine-checked proof replayable offline" or "recompute-and-compare conformance" over a "hash-committed" TCB, nor with AX-13's fully-offline verification. Attaining either kills the fourth-file violation structurally; the prose-consistency half is the evidence discipline. **COVERED.** (The word "Quicklisp" appears nowhere in the instrument; coverage is via the pinning/offline entailment.)

**OBL-18 — Make the documented quickstart work as written.**
→ **GAP.** No ceiling or dimension entails documentation-behavior conformance ("README"/"quickstart" have zero presence in the v2 corpus, and no frozen clause makes doc examples executable checks). AX-09's census would carry such a check only if declared — not entailed. **Instrument amendment needed:** add executable-documentation conformance (every documented command is a committed, census-covered check run on a clean clone) to the AX-09 declared check family or as a release-gate condition adjacent to AX-13.

**OBL-19 — Delete the orphan system or give it components.**
→ **PARTIAL.** AX-02 makes "orphan stage feeding no goal" inadmissible *within an admitted plan*, and AX-06's census is backward-lineage (every artifact has a chain); neither entails forward reachability of committed *source roots* — an `.asd` that nothing loads is a root with no consumer, which no frozen clause forbids. **Missing:** a reachability census over source roots (every committed source artifact reachable from some admitted plan/goal), i.e., a forward-totality strengthening of the AX-06 census.

**OBL-20 — Populate or delete deps.archives.lock.**
→ **AX-13** closure completeness: if archive dependencies exist, offline recomputation from the committed closure fails unless their bytes/digests are committed — an empty lockfile alongside real dependencies makes the closure incomplete and verification impossible (blocking); if no dependencies exist, the empty lock asserts nothing false. The looks-like-a-control pathology is thereby structurally impossible for attaining designs. **COVERED.**

**OBL-21 — One version seat.**
→ **PARTIAL.** AX-06 ("lineage root bound inside the signed release identity") and AX-08(a) (sequence-monotonic history) give exactly one *canonical* version identity per release. But no frozen clause forbids residual duplicate hand-written version declarations coexisting with it — "say its own version once" needs the one-seat-per-concept rule, which lives in the creator's laws (CLAUDE.md), not in the instrument. **Missing:** an instrument clause (natural seat: AX-14/AX-20) that version identity is *derived* from the signed release identity and every other occurrence is generated, never authored.

**OBL-22 — Make the capability register cover the authority architecture.**
→ **AX-12**: "authorization validity is offline-decidable by any third party recomputing the capability/delegation chain from a committed genesis trust anchor," with every non-acceptance a recorded refusal — an authority defect is a decidable, blocking failure. **DIM-07** verifiable-authority-directory makes the register itself a transparency-logged artifact ("which key/role may sign which class of act"). A plenary gate over that register necessarily can fail on an authority defect. **COVERED.**

**OBL-23 — Decide what the 24 legacy releases are: evidence, or law.**
→ **AX-12**: authority exists exactly as far as the recomputable chain from genesis reaches ("signatures transfer trust, they cannot create it"), and every grant of authority is a certificate-carrying admission transition. Attaining AX-12 yields the classification for free: a legacy artifact carries authority iff a recorded admission act binds it into the chain; otherwise it is evidence only — and "by what act" is the recorded transition. **COVERED.**

**OBL-24 — Make the boundary testable where it is developed, or declare the platform.**
→ The **kind-taxonomy discipline** plus **AX-11/AX-15**: "Resource facts (toolchain availability, witness enrollment, …) live in appendices or RESOURCE_BOUNDED clauses, never inside ABSOLUTE labels"; AX-15: "On the declared operating model (single node, POSIX filesystem, commodity SSD with honored write barriers)…"; AX-11(i) is explicitly "relative to the declared storage platform." Every platform-scoped guarantee in the v2 instrument carries its platform declaration in the frozen statement — the "declare the platform" disjunct is satisfied structurally. **COVERED.**

**OBL-25 — One independent green execution before any number is treated as evidence.**
→ **Witness-appendix convention** (instrument-level) + **AX-13**/H8. Convention: every attainment claim is "HYPOTHESIS … UNKNOWN pending independently re-checkable verification artifacts (replay artifacts and discharged proof obligations). An assessor's unverifiable claim of a rank is not a rank." AX-09's derivation states the same bound: "a declared all-clear can never exceed what an independent recomputation over committed inputs establishes." A count produced only on the author's machine is exactly an unverifiable claim — typed UNKNOWN, not evidence. **COVERED** (note: by frozen convention + AX-13, not by a dedicated axis).

**OBL-26 — Repair the baseline's own evidence discipline in the successor study.**
→ **Corpus-wide evidence discipline** (frozen conventions): evidence-status tags on every empirical premise, "VERIFIED_FROM_SECONDARY … never grounds a rank — at most a KNOWN_UPPER_BOUND cap," the honest_independence_statement retracting the v1 false claim, and the closure's rule that eliminations cite committed grounds with retained representatives. Every substantive claim in the v2 corpus is typed against its evidence record; the EV-P-005/006 pathology (headline figure with no resolvable record) is inadmissible under these conventions. **COVERED** (convention-level covering, stated as such).

**OBL-27 — A checker's conjunct must test something.**
→ **AX-10 regime (2)** + **AX-09**. AX-10: "adversarial adequacy certified as 100 percent mutation-kill over a DECLARED, hash-committed, finite class M … with the kill matrix an offline-recomputable release artifact" — a constant conjunct kills no mutants, so the tautology surfaces as surviving mutants, which are "typed UNKNOWN that fail-closed blocks release." AX-09's census separates "checked-with-certificate" from "enumerated-unchecked," which is precisely "reported as untested" rather than mislabeled. **COVERED.**

**OBL-28 — Bind genesis evidence to the tree it ships in, and check the binding.**
→ **AX-13** (certificate bound to the complete closure including source bytes — a different commit is a different closure, hence a different certificate) + **AX-15(d)** ("FAIL-CLOSED READ-BACK — a transition counts committed only after recompute-and-compare of the persisted bytes") for the read-the-field-back half. **COVERED.**

**OBL-29 — Let the code count itself.**
→ **AX-13/AX-14** + **AX-18**. AX-14: every trusted derivation is "a total mathematical function of its committed input closure" — a hand-written count is not a derivation; AX-13's unique-derivation-result verification rejects any figure that recomputation does not reproduce; AX-18 states the norm expressly: "all bounds derived from committed corpus configuration, never constants." The DIM-08 elimination of aggregate-only ledgers (two-history counterexample) closes the adjacent evasion. **COVERED.**

---

## Part B — The 10 OPEN R5 defeaters

**DF-007 (axiom) — A10 entrenchment; D11 record integrity.**
Record-integrity half: **addressed** — AX-07(a)/(b) (tamper-evidence by full recomputation over episode commitments, typed erasure certificates), AX-08(b) (append-only verifiability), DIM-09 witnessing. Entrenchment half: the word "entrench" occurs **zero times** in the v2 corpus. Oblique instruments exist — AX-20(3) ("the certified set itself only grows"), AX-12's genesis-anchor clause, DIM-14's absorbed "TUF/gittuf threshold delegable rotatable root over the system's own code and policy refs," DIM-09 forensic attribution — but no clause states what protects the amendment rule itself from the root holder. **PARTIAL** — missing: an explicit entrenchment treatment (threshold/rotation semantics for the root, and which floors are constitutionally unamendable) in AX-12 or AX-20.

**DF-011 (claim) — D20/D21: ACL2-verified kernel executed under SBCL.**
**Addressed by AX-21**, which meets the defeater head-on both ways: (i) it types the current arrangement honestly — for "a Common Lisp commitment, for which no verified compiler exists, link-type (b) [recompute-and-compare / diverse re-verification] is the optimum FOR THAT COMMITMENT"; (ii) it names the superior conception that retires the gap — "a strictly smaller trust residue is reachable TODAY by retargeting the trusted kernel to a verified-compilation substrate — CakeML … or Brack," recorded as "a declared scope choice of the creator, not a limit." The verified-in-ACL2/executed-in-SBCL gap is no longer a hidden assumption but a typed RESOURCE_BOUNDED residue with a named exit. **COVERED** (as honest bounding + recorded superior alternative; see DF-043 for the residue this leaves).

**DF-016 (claim) — D09/I-19: lex superior > lex specialis > lex posterior as the default ordering.**
**Addressed by AX-01's MODEL_RELATIVE relativization** ("Correctness claims are meaningful only against the committed formal semantics of the admitted rulebase, never against 'the law' as natural-language text") with the priorities demoted from architecture constants to committed rulebase content (AX-01 appendix: "lex-superior/posterior/specialis priorities as explicit committed rules"; DIM-05 absorbs "semantic-conflict isolation ordered by the lex superior/posterior/specialis authority lattice"). AX-12's process-not-substance clause assigns the substantive rightness of the ordering to the accountable human authority. The defeater's target claim (the ordering as a system-asserted truth) is withdrawn by construction. **COVERED**, with the recorded residue that choosing the default remains a human normative act, as AX-12 requires.

**DF-018 (claim) — R-07: closed assumption vocabulary.**
**Addressed by AX-09(a)/(b)**: typed UNKNOWN comes "from a CLOSED, committed enumeration of unknowability causes," and — decisively against this defeater — "the boundary of that class is itself a committed, certificate-carrying, machine-enforced artifact (not prose)," with the honest impossibility stated ("No feasible system can additionally certify the absence of unknown-unknowns outside its committed input set"). Vocabulary growth is an AX-20 evolution step (certified set only grows). DIM-12's closed-sum-type/etypecase mechanism is the closure decision. **COVERED.**

**DF-021 (assumption) — OA-4: the Greek legal corpus is small enough for in-memory derived state.**
Partially addressed by *containment*, not remedy: **AX-17(b)** ("a fail-closed cost-budget gate blocking any run whose certified cost exceeds a committed budget"), **AX-16** (typed bounded refusal, never a hang), and **AX-18** ("all bounds derived from committed corpus configuration, never constants") jointly convert a falsified capacity assumption into a typed, blocking, visible state rather than silent degradation. **AX-04(iii)** makes *grounding* corpus-size-independent. But no dimension enumerates an out-of-core/externalized-state family, and nothing retires the in-memory dependence itself. **PARTIAL** — missing: either a closure family for externalized derived state or a committed capacity model tied to the AX-17 budget gate.

**DF-023 (decision) — D15/D16: coverage for sources without structural signal; sampling latency.**
Coverage half **addressed by honest claim-narrowing**: AX-09's derivation states "blind spots over inputs never received are undetectable in principle; the ceiling … is 'no SILENT blind spots over the committed universe'," and AX-08(c) types every (t, tau) outside committed evidence as UNKNOWN ("No feasible system can … anticipate unpublished amendments"). The stale-law failure mode becomes typed, never wrong-but-confident. Sampling-latency half: **uninstrumented** — AX-17 governs compute latency over a frozen workload, not capture recency; no axis bounds how quickly the committed universe tracks the world, which for a watchtower is a first-class quality. **PARTIAL** — missing: a capture-freshness axis or clause (e.g., certified maximum age of the committed universe per source class, gated like an AX-17 budget).

**DF-033 (architectural) — the architecture as a whole.**
**Addressed as a framework, unresolved as a verdict — by design.** The closure's FOC-04 checklist supplies the structural answer: U_T nonempty with nine members whose membership is "PURELY H-invariant-defined"; D_T a seventeen-class quotient in which every non-admissible class (K-COM, K-AGT, K-TEE, K-CRDT, K-HUM, K-COM+, K-GRAPH, K-B0-SHIPPED) "is dominated (if at all) by adjudication, never by pruning"; all former per-dimension eliminations demoted to pre-registered DOMINANCE_CONJECTURES "adjudicated ONLY by full 22-axis verdict sets"; K-COM+ added "so the 17-class quotient covers this cell BEFORE a vendor occupies it." The corpus itself insists the conjectures are "CONJECTURED, not established," and K-SUP/K-B0-TARGET "cannot be crowned" under unknown_rule. **PARTIAL** — the defeater stays open until the tournament produces the verdict sets; the v2 corpus has built the apparatus that makes it decidable, which is Gate-conformant but not yet a discharge.

**DF-042 (architectural) — A.2.1 genesis; A10 entrenchment.**
Genesis half **addressed by AX-12's ABSOLUTE clause**: the "committed genesis trust anchor, which no system can eliminate (signatures transfer trust, they cannot create it)" — the defeater's demand for an unanchored bootstrap is met with a proved irreducibility, and AX-07 classifies TEE anchors as "the same category of irreducible anchor as a genesis key," while DIM-09 witnessing makes genesis-key misuse "producer-attributable cryptographic evidence." Entrenchment half: same finding as DF-007 — zero direct treatment. **PARTIAL** — missing the same entrenchment instrument as DF-007 (protection and amendment semantics of the root/amendment rule itself).

**DF-043 (architectural) — I-41/I-42: the two-kernel remedy for HF-001 (common-mode failure across two kernels).**
**GAP — the v2 corpus does not address common-mode failure.** Verified by exhaustive term search: "common-mode"/"common mode", "two-kernel", "HF-001", "I-41", "I-42" each occur **zero times** in both `_ssp_ceilings_v2.json` and `_ssp_closure_v2.json`. What the corpus *does* contain, and why none of it answers the defeater:
- **AX-21 (frozen)** lists Thompson-mitigation options — "a verified compiler, diverse double-compilation, or independent re-execution" — but supplies **no independence or fault-class-disjointness model** for any diverse pair; diversity is asserted as a mitigation category, never argued.
- **AX-21 attainment appendix (non-frozen)** actively *relies* on the attacked assumption: "kernel-diversity independent re-verification (release-spine + staged L6 verifier) as the diverse-execution mitigation for the unverified compiler link" — the two-kernel pattern reappears with no common-mode analysis, i.e., the exact structure DF-043 attacks is still load-bearing in the witness story, undefended.
- **DIM-13/DIM-16 n-version-formalization** is a genuine diversity mechanism (independent formalizations SAT-diffed, disagreement a typed blocking object) — but it covers *formalization artifacts*, not the kernel pair, and its soundness likewise rests on an unmodeled independence assumption.
- The one structural exit the corpus records is **AX-21's superior conception**: CakeML/Brack retargeting "removes the diverse-double-execution mitigation from the compiler link entirely" — which retires the two-kernel remedy by *eliminating the error class* rather than defending the diversity argument (the supreme-law-preferred shape). It is recorded as awaiting explicit creator approval, so today it is a named alternative, not a covering.
**Instrument amendment needed (Gate #1 deliverable):** either (a) adopt the verified-compilation retargeting, retiring the two-kernel remedy and DF-043 with it, or (b) amend AX-21 link-type (b) so that wherever diverse re-verification is load-bearing, a committed common-cause model (shared toolchain, shared spec, shared author, shared input-parsing code — each argued disjoint or typed as residual trust) is a required, certificate-carrying artifact.

**DF-050 (claim) — I-27 / institutional method combination: cleanup completion.**
**Addressed by structural elimination, not by defense of the claim.** The v2 corpus never mentions method combination or cleanup, but **AX-11(i)** makes cleanup completion non-load-bearing for integrity: "after a crash at ANY instant the recovered state is exactly sigma_pre or exactly sigma_post, never a hybrid" — a design attaining single-commit-point atomicity has no state whose consistency depends on in-image cleanup code running; **AX-12** adds that an error inside the gate itself is "a recorded, signed refusal with zero state change," and **AX-16** excludes silent hangs. The I-27 mechanism must be re-seated on the commit-point discipline (its cleanup demoted to non-trusted tidying). **COVERED** (the defect class is made structurally impossible rather than the completion claim being proved).

---

## Part C — Summary

```json
{
  "obl_covered": 23,
  "obl_partial": ["OBL-05", "OBL-06", "OBL-12", "OBL-19", "OBL-21"],
  "obl_gaps": ["OBL-18"],
  "defeaters_covered": 4,
  "defeater_partial": ["DF-007", "DF-021", "DF-023", "DF-033", "DF-042"],
  "defeater_gaps": ["DF-043"]
}
```

Counting rule used: `obl_covered`/`defeaters_covered` count only full COVERED verdicts; PARTIAL entries are listed separately and are **not** counted as covered (DF-011, DF-016, DF-018, DF-050 are the four covered defeaters).

**Consolidated instrument amendments implied by the gaps and partials (five distinct instruments):**
1. **Deployment-artifact validation** (OBL-05, OBL-06): mandatory semantic well-formedness checks for operational/deployment definitions in the AX-09 declared check class.
2. **Cross-reference and doc-executability well-formedness** (OBL-12, OBL-18): committed resolvability of inter-contract references and census-covered executable documentation.
3. **Forward-reachability census + single version seat** (OBL-19, OBL-21): source-root reachability totality, and version identity derived from the signed release identity with all other occurrences generated.
4. **Entrenchment treatment** (DF-007, DF-042): explicit amendment-rule protection and root threshold/rotation semantics in AX-12/AX-20.
5. **Common-mode/diversity model or verified-substrate adoption** (DF-043): the one hard architectural gap — plus, from the partials, a capture-freshness clause (DF-023) and a capacity model or out-of-core family (DF-021).

Per the honesty rules these gaps are Gate #1 deliverables: each names the exact instrument amendment, none was forced into coverage, and every COVERED verdict above rests on a quoted frozen clause with an entailment argument, with convention-level coverings (OBL-25, OBL-26) flagged as such.