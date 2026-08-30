# FINAL HONESTY ADVERSARY — VERDICT

**Verdict: SUBSTANTIALLY CLEAN on the three original critiques, with FOUR residual phrasing overshoots to tighten (all disclosed in the dossier's own residuals — none concealed, none a pseudo-green gate).**

I take the repo/status/path facts as given (the dossier states they check out) and audit only for honesty violations in the dossier's own framing.

---

## Clean on the three original critiques

- **(a) spec-only/:blocked-toolchain stated as delivered — NOT FOUND.** K is stated as `:specification-only`, F* target (not CL), "executes NOWHERE and MUST NOT be stated as delivered," no certificate emitter, all T1–T9 `:blocked-toolchain`. All 27 kernel-dependent cells carry `CONDITIONAL_ON_KERNEL_AND_TOOLCHAIN` and are written in the conditional ("Would add…", "0 machine-checked"). The TCB (Section 3) explicitly excludes K and the extracted binary. Clean.
- **(b) T6/VERIFIED/ceiling implied achieved — NOT FOUND.** Explicit: "0 VERIFIED," "T6 (deterministic-replay) is NOT discharged," terminal `FINAL_OPTIMALITY_BLOCKED`, "does NOT, and must not, claim a discharged VERIFIED today." AX-14/17/18 determinism/latency/throughput correctly sit at `NEEDS_EXECUTABLE_BENCHMARK`. Clean.
- **(c) floor laundered as advantage — NOT FOUND (correctly downgraded).** AX-22 is `FLOOR_RESTATED_MUST_FIX` ("six Greek codes = one legal order = corpus breadth, which is exactly the commercial floor"); AX-17 flagged a "category error"; AX-18 "audit-cost, NOT throughput"; AX-07 residual drops the "13-kinds/8-stores" counts as "quantity, not tier"; `NEEDS_BLACK_BOX_PRODUCT_RUN = 0` as primary status refuses any "structurally lacks" claim. Clean.
- Arithmetic consistent: 27+27+9+3 = 66; 9+9+3+1 = 22 axes; per-cell JSON statuses match the summary table.

---

## (d) ARCH_CLASS_PROVABLE_NOW cells leaning on blocked/unbuilt pieces — FOUR RESIDUAL OVERSHOOTS

Each is grounded in a genuinely executing seat (so the token is defensible under its own definition, "a logical/structural property provable now"), but a present-tense verb reaches past the executing part into a not-yet-built or benchmark/blocked part. The dossier's residuals concede each — so this is **tightening, not a caught lie** — but under strict fail-closed honesty the hedge belongs *inside* the claim verb, not deferred.

**1. AX-19 — "sound + complete" overshoots on completeness.**
Quoted (`e_star_mechanism_short`): *"…with an honest-ignorance gate forbidding a chainless conclusion; sound + complete, re-verifiable offline."*
Its own residual concedes: *"the 'coverage 1.0 by construction' completeness leans on the AX-09 honest-ignorance gate, which is not yet a computed standing invariant"* and *"replace no-op reporting stubs; add effect-typed lineage so an untraced trusted act cannot compile"* (C9, unbuilt; report stubs are no-ops).
**Honest correction:** "**sound** now (the proof object emits and re-verifies offline); **completeness is ASSERTED by-construction, NOT established** — it depends on AX-09's honesty counters becoming standing computed invariants (CONDITIONAL) and on C9 effect-typed lineage, which is unbuilt (report emitters are no-op stubs)." Sound = PROVABLE_NOW; complete = CONDITIONAL. The single green token papers over this split.

**2. AX-08 — "deterministic-replay … beats it TODAY" overshoots on 'deterministic.'**
Quoted (`floor_beaten`): *"E_star beats it TODAY with bitemporal deterministic-replay reconstruction…"*
Its own residuals concede: *"the bytewise 'reproduction error = 0' sub-claim needs the determinism run (NEEDS_EXECUTABLE_BENCHMARK)"* and *"Discharge the kernel monotonicity conjunct (blocked-toolchain) to lift replay to a machine-checked theorem."*
**Honest correction:** drop "deterministic" from the TODAY claim → "beats it TODAY with **replay-verified** bitemporal reconstruction (valid-time × known-at, fail-closed); the **determinism itself is unmeasured — the 0-bit number is NEEDS_EXECUTABLE_BENCHMARK and T6 is blocked**." The replay function executes; "deterministic" is exactly the unproven part.

**3. AX-06 — "byte-exact replay" via per-step chain is the C12 target, not current.**
Quoted (`e_star_mechanism_short`): *"SHA-256 before/after each amendment op enabling byte-exact replay…"*
Its own `b0_today`/residual concede: *"consolidation ledger verifies aggregate base/result hash + step-count, NOT a per-step hash chain"* → *"Upgrade … to a per-step before/after hash chain so byte-exact replay is a hard gate."*
**Honest correction:** the provable-now grounding is `authority-evidence-replay.lisp` (recompute-and-compare, real) — keep that. But "per-step before/after → byte-exact replay" is **C12, not built**; state it as the target, not a present property. (The `floor_beaten` already scopes correctly to recompute-and-compare; only the mechanism line overshoots.)

**4. AX-04 / AX-05 / AX-13 — "portable / offline third-party-verifiable" presumes a signed root that does not exist.**
Quoted (AX-04 `floor_beaten`): *"a third-party-verifiable Merkle inclusion path"*; (AX-05) *"a portable bundle any party recomputes byte-for-byte"*; (AX-13) *"a third party verifies offline."*
Own residuals concede: *"sign the corpus root for real (PROVENANCE.yaml is an unfilled template)"*, *"JWS proves consistency not authenticity today; bind the tier into a really-signed release"*, *"full RFC-3161 TSA-chain crypto verification is undischarged."*
**Honest correction:** the recompute-and-compare *derivation* executes and is the real lift — but **"third-party-verifiable / offline-verifiable" requires the signed root/really-signed release, which is pending**; today an offline party can re-derive bytes but cannot cryptographically anchor them to an authenticated origin. Say "recompute-and-compare re-derivation runs today; third-party *cryptographic* verification lands once the root is really signed."

---

## Bottom line

No pseudo-green gate, no laundered floor, no claimed VERIFIED/T6, no spec-only-as-delivered survives concealed. The dossier's honesty architecture holds. The four items above are the seams where a present-tense verb in `e_star_mechanism_short`/`floor_beaten` reaches into the part its own `residual_obligation` marks as unbuilt/benchmark/blocked — most sharply **AX-19's "complete"** (leans on CONDITIONAL AX-09 + unbuilt C9) and **AX-08's "deterministic"** (T6-blocked benchmark). Recommend moving those hedges inline so no cell reads greener than its own residual. Absent that, honest-ignorance still requires flagging that **AX-19's completeness and AX-08's determinism are not PROVABLE_NOW even though their cells are green** — the structural halves are; the named sub-properties are not.