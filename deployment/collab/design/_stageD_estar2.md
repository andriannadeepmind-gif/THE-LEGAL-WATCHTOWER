All inputs read (ceilings v2, freeze v2, Stage-C report §3/§7, corrected verdicts, K-SUP + donor steelmen, census master, B0 map, CEILING-BAR). The dossier follows.

---

# E★★ v2 — THE CEILING-VECTOR ARCHITECTURE
## Stage C Round 2 synthesis dossier — ONE machine, generated basis-free from the 22-ceiling vector

**Derivation charter.** E★★ v2 is generated from the 22 frozen guarantee ceilings (`_ssp_ceilings_v2.json`) under the CEILING-BAR rule: `ACCEPT(E★★) ⇔ ∀a ∈ AX-01..22: attains(ceiling_a) ∨ proven_impossible(ceiling_a ∧ rest)`. The tournament record (`_stageC_verdicts_r2corrected.json`, 198 cells) is used only as a **falsifier and a constructability-witness index** — never as a synthesis source; "the K-SUP join" as generative base is struck per the round-2 corrections. Class mechanisms are cited below solely as per-axis proofs that a mechanism class is buildable today.

**Registered evidence regime (binding on every claim in this dossier).** Three types only:
- `EXECUTING_WITNESS(path)` — a census-verified seat runs today (Stage-B master, 2,411 files / 169 catalogued seats).
- `DESIGN_ENTAILMENT` — permitted to rank **only** on axes whose frozen evidence rider allows design-stage ranking (AX-05, 06, 07, 09, 11, 17-old-clause, 18, 20, 21, 22; AX-01/02 from re-verifiable artifacts).
- `CONDITIONAL_ON_NAMED_BUILD(BO-xx)` ≡ UNKNOWN with a design floor, discharged only by the named artifact entering the evidence set. On executed-evidence-rider axes (AX-03 R4+, AX-04 R3+, AX-08 R3+, AX-10 all rungs, AX-13, AX-14 R4+, AX-15 R4+, AX-19 R3+) an unbuilt/unreplayed mechanism is **always** this type, never AT.

No VERIFIED claim appears anywhere in this dossier. No aggregate, count-of-wins, or ranking object appears anywhere in this dossier.

---

## 1. THE ARCHITECTURE

### 1.0 The identity theorem (obligation (d), frozen as a construction constraint)

E★★ v2 has exactly **one gate = one witnessed head = one root acceptance relation**:

> The kernel admission predicate `K(state, transition, certificate)`, the single logical serialization point, the domain-separated Merkle commitment head, and trusted-trace emission are **one artifact**: acceptance evaluates K, and appends {transition, trace event, Merkle leaf, seq' = seq+1} in the **same all-or-nothing commit**, whose head is what the external witness quorum cosigns. Every non-acceptance — including an error inside K's own predicates — is a recorded, signed, committed refusal with zero state change (fail-closed totality).

Consequences by construction: AX-19 divergence between decision and explanation is structurally impossible (same event); AX-06 lineage, AX-11 commit, AX-12 evaluation, AX-08 monotone sequencing, AX-07 memory admission are conjuncts of the same commit; per-axis-consistent global equivocation (the K-NSV×K-TLOG attack) has no seam to live in. This closes round-1 obligation (d) explicitly rather than implicitly.

### 1.1 Pinned operating mode: **MODE A — physical single writer + external cosigning witness quorum** (default, binding)

**The B0 continuity argument (why Mode A, stated as attainment logic, not cost).**
1. **No frozen rung requires Mode B.** Every equivocation-relevant frozen ceiling (AX-07(c), AX-08(b), AX-12 equivocation clause) states its cap as *fork consistency, liftable by an external witness quorum to split-view resistance* — a detection/attribution-class guarantee. Mode A + enrolled witness quorum sits exactly **at** those frozen caps. Prevention-class non-equivocation is a Mode-B property **above** the frozen ceilings; the supreme law does not demand exceeding a frozen ceiling, and its adoption would be an S2 escalation for the freeze authority, not a synthesis decision.
2. **Continuity of the only executing evidence in the field.** Every EXECUTING_WITNESS seat in the census is Mode-A-shaped: the OS-DAC uid-pinned single writer with executional proof (`authority-v2/capability/identities.sh` + `verify-capability-closure.sh` — kernel EACCES real today), the RFC-6962 Merkle seat, the hash-chained memory chain, the release spine with 3-implementation offline verification, the bitemporal receipts with exact journal-prefix replay (the field's **only** executing partial AX-08 past-time witness), and the mutation-kill AX-10 seed. Mode B forfeits all of it and restarts every executing witness at zero; Mode A inherits it and inherits the (h) continuity path through B0's ratchet (creator decision, §8).
3. **Latency/cost class.** Mode A holds the fsync-commit AX-17 latency class; Mode B is one declared class below (consensus commit). Under the frozen AX-17/AX-18 instruments this is a typed class difference recorded in the complexity_class fields, not prose.

**Mode B (BFT-replicated total order) — declared alternative, documented, not chosen.** The full design is the K-BFT steelman (Quorum Custodian): n = 3f+1 institutionally independent custodians, admission at consensus commit, f+1 serve-time recomputation, omission accountability, consensus-governed code identity. Its rungs that Mode A structurally cannot hold are recorded with impossibility-under-model notes in §7(b) — theorems of the declared model, never cost statements.

**Mode-A witness algebra (resolving the two-trust-algebra incoherence, obligation (b)).** ONE algebra: cosigning witnesses only. Witnesses are non-adjudicating countersigners of checkpoint heads (C2SP/Ed25519 wire format already specified in `authority-v2/log/witness-policy.sexp`, today `disabled`); client-side k-of-n witness policies verify **against those cosignatures** — there is no second adjudication layer, no voting, no quorum-certificate stack for witnesses to disagree with. Every commit additionally bracketed by k-of-n external time authorities (Roughtime-class + eIDAS TSA, strict-DER seat `source/asn1-der.lisp`) per the frozen AX-17 clause (c).

### 1.2 Layers (concrete, each buildable today)

**L0 — TCB and substrate.** Enumerated, hash-committed TCB: {small proof-checker kernel (Lean 4, offline-vendored), the pinned SBCL binary + 3 diverse verifier implementations (`deployment/verify/verify.py`, `verify.mjs`, `kernel-verify.lisp`) as the diverse-execution mitigation for the unverified-compiler link, OS loader, hardware class}. The trusted path is LLM-free (honored in all 8 census areas today — cross-cutting invariant preserved). One injected logical clock; wall-clock removed from every canonical artifact (census P0-4). The **CakeML-class verified-kernel retargeting** is recorded as the superior transport the frozen AX-21 ceiling names — a creator decision (BO-24, §8), not silently dropped.

**L1 — The gate (§1.0).** K realized as a pure SBCL function over `authority-v2/kernel/admission-model.sexp` conjuncts and `transition-certificate.cddl` certificates; capability/delegation recomputation from the genesis anchor (`genesis-policy.sexp`); the constitutional gate flipped fail-closed (today `constitutional-gate.lisp:44-45` fails open — P0-2, BO-02); every acceptance AND refusal appended to the signed read-back-durable ledger. K's authority-model theorems T1–T9 machine-checked (BO-02).

**L2 — Storage, durability, recovery.** ONE atomic writer seat: tmp-in-same-dir → finish-output → fsync(fd) → atomic rename → fsync(dir) → read-back SHA-256 recompute-and-compare, generalized from the executing `require-durable!` pattern (`source/adoption-decision.lisp`, `source/journal.lisp`) to `emit-graph`/`deploy.lisp` (today's sharpest census hole). Multi-file transitions: the six-item STORAGE-API transaction as an S-expression WAL with SHA-256-chained commit records; recovery replays to last valid commit record, Θ(uncommitted tail), checkpoint-capped. Crash-refinement proof in Lean (FSCQ technique, BO-13). **Absorbed from K-DMERGE (mode-compatible):** the append store is content-addressed so a torn append fails its hash check and equals "never durable" — collapsing the injected-crash surface toward a single crash class per store.

**L3 — Capture and grounding (AX-04, per the three-mechanism positive ceiling).** Publisher signature verification where the gazette signs (typed as capture-time hypothesis, never rank-grounding); else k-of-n independent capture witnesses (enrollment = BO-09; the wire format exists); else DECO/TLSNotary-class attested-channel arm. Dual digest with deterministic extraction E and third-party byte-equality replay (`primary-anchor.lisp` with its P0-3 undefined-hash fix + `authority-evidence-replay.lisp`, executing). Selection by exact committed identifier only; glob fallback deleted; Merkle inclusion O(log n) (`source/merkle-authority.lisp`, executing). Multi-span excerpts with committed gap-manifest.

**L4 — The ROOT ACCEPTANCE RELATION (the rationality-postulate seam, handled at its seat).** ONE acceptance relation **A** over ONE committed finite defeasible base B (strict rules ∪ defeasible rules ∪ committed priority order), with the Caminada–Amgoud closure/consistency postulates held **as theorems** via transposition-closure of the strict-rule stratum (the K-ARG seam absorption; proofs in BO-03). Cells enter A as certificate oracles — **never as parallel engines**:
- **Statute cell (total-by-construction):** Catala-class δ-calc scopes, statute-isomorphic, compiled by a verified/validated step into prioritized defaults of B. Conflict-between-exceptions and missing-definition are typed fail-closed errors.
- **Decidable-theory atoms:** dates/deadlines/linear arithmetic via proof-producing SMT (cvc5/Alethe, Carcara-checked), admitted as strict-rule instances.
- **Case-law cell (PCK, absorbed whole — §2 #1):** Horty sceptical-forcing over signed factor ascriptions; FORCED_π/FORCED_δ verdicts enter A as certificate-carrying premises with precedent provenance; **cross-cell defeat has its seat inside A**: precedent-vs-statute attack is resolved by committed priority rules (lex superior/posterior/specialis as committed rules — `source/legal-conflict-resolution.lisp` seat), never by a router.
- **Escalation cell (coNP):** where grounded labelling of A leaves the query target undefined AND a P-time even-cycle analysis certifies the cycle, the query escalates to certified ideal/sceptical-preferred acceptance (proof-logging exhaustive-extension enumeration, checker-verified) under the committed AX-17 budget; breach = typed refusal.
- **Router soundness (obligation (c)) closed structurally:** cell membership is not a hardcoded partition function — it is a **derived, certificate-carrying conclusion of A itself** (the grounded-undefined result + the cycle certificate ARE the escalation ticket; the compiled-scope provenance IS the statute-cell ticket). There is no unranked trusted router because there is no router.
- **Formalization admission (DIM-16):** n-version independent formalization + structural diff + round-trip verbalization invariant + accountable human sign-off as a committed transition; interpretively contested text is typed UNKNOWN at admission (H1/H2).

**L5 — Plans (AX-02, K-NSV absorption §2 #2).** Plans are Lean proof-term skeletons: goal = target theorem, nodes = typed lemma obligations, edges = proof-term composition; `sorry` = typed blocking obligation; a defective plan **cannot come into existence** (fail-closed macroexpansion). Execution: Calvin-class deterministic conflict-ordered tiers, scratch-then-merge, atomic tier commit at the gate; tier failure restores pre-tier state exactly. DEFPIPELINE produces/consumes contracts gated at definition time (today computed but not gated — census).

**L6 — Verdict algebra (AX-09).** Four classes, total: PASS+certificate; FAIL/CONTRADICTION+counter-certificate; **KNOWN-STABLE-over-UNKNOWNs** with certified invariance over ALL completions (extremal-completion shortcut on monotone lattices per PCK; exhaustive enumeration/Kleene elsewhere); typed UNKNOWN with cause from a **closed committed sum type** consumed only through exhaustive etypecase. Coverage = the un-gameable positive census (`verify-proof-manifest.py`/`run-proofs.sh` — executing; a crash yields no manifest, never false green). Flagged anomaly = blocking non-servable state.

**L7 — Bitemporal state (AX-08).** ONE total seat `View(t_legal, t_knowledge)` over committed snapshots + typed amendment events under the declared event calculus; t_knowledge = admission sequence of the Merkle-committed corpus; genTime-floor anti-rollback; typed UNKNOWN off coverage. Extends the executing bitemporal receipts (`source/legal-authority-receipt.lisp`).

**L8 — Citations (AX-05).** Grammar-total, coverage-gated FSM recognizer generated from the committed profile grammar (replacing the regex layer; the `citation-authority.lisp:224` ≤120 clamp deleted — census P0-10); every in-L(G) string resolves through the executing verifier chain (`authority-proof-bundle.lisp` owner-pin/delegation/revocation) to a bitemporal receipt with a per-citation certificate; out-of-L(G) → typed UNKNOWN-CITATION, never upgraded. Formal-object support = derivation provenance (AX-01×AX-04 composition); NL-vs-NL support never claimed.

**L9 — Partitioned cost regime (AX-17 both readings; committed cell boundary).**
- **Under the FROZEN clause:** exact offline-recomputable abstract cost certificates for every run (deterministic meter at the single seats); fail-closed committed budget gates; k-of-n external-time-authority wall-clock bracketing. This is the OLD-clause R5 shape, design-stage per the frozen rider.
- **Under the RAISED clause (PENDING_CREATOR_APPROVAL — §8):** for every **total-by-construction cell** (δ-calc statute cell, grounded labeller, PCK forcing O(|CB|·|F|), citation FSM, Merkle/verifier paths) a machine-checked **∀-input worst-case cost theorem** per compiled unit (BO-15b); for **Turing-complete/coNP cells** (escalation enumeration) the **budget gate is the ceiling**, backed by the §7(a) impossibility draft: a useful (polynomially bounded) ∀-input envelope on the coNP cell is impossible unless coNP ⊆ P.
- **The cell boundary is a committed, machine-enforced artifact:** the escalation certificate (grounded-undefined + even-cycle witness) is the boundary-crossing record; the boundary census is hashed into the release identity. Pre-adoption obligation carried verbatim: reconcile the raised clause with the frozen ladder's AX-17 R5 "certified-worst-case-envelope" wording (S2 act of the freeze authority).

**L10 — Falsification institution (AX-10, seeded by the field's only executing evidence).** Two-regime adequacy: (1) proof-carrying exclusion on the (currently empty, growing-by-BO-03) verified perimeter; (2) hash-committed repo-wide mutation-operator/counter-design registry with a 100%-kill matrix as an offline-recomputable release artifact, seeded from the executing `capture-mutation-witness.py` harness; fresh-context critics with **machine-checkable independence** (committed prompt-closure hashes + distinct producer-ids — the K-NSV method absorption); every finding → recorded terminal disposition; a surviving mutant = typed UNKNOWN that blocks release and escalates to the creator as a certificate-carrying transition. The `use-default*` value-fabricating restarts and all P0-1 false-green emitters are deleted (census register, verbatim).

**L11 — Evolution (AX-20) + B0 continuity.** Floor-vector ratchet: each release recomputes (never trusts) Floors(S_n) from the previous release's hash-chained census (`prev_release_root` chain, executing), proves pointwise non-regression AND re-checks preservation proofs for every committed spec'd class; the certified set only grows; refusal fail-closed. The monotone-registry AX-10×AX-20 composition (refuted as exceedance, valid as composition) is absorbed here: every new finding class ratchets into the committed registry. **E★★ v2's own admission path runs through B0's ratchet chain as a ratchet-certified evolution sequence — flagged as a creator decision (§8), not adjudicated here.**

**L12 — Generality (AX-22).** Every trusted mechanism is one function of a hash-committed legal-order PROFILE (article ranges, publisher identity/keys, script normalization, calendar, citation grammar, deontic lexicon); noninterference obligation: no trusted decision depends on jurisdiction facts except through the profile; a jurisdiction literal in any trusted seat outside the single profile-loader fails the build gate; missing/ill-formed profile → typed UNKNOWN. Greece profile extracted from the enumerated constants (`greek-law-types.lisp`, `structure.lisp` `*constitution-articles*`, FEK tables, `/exp/ell`, calendar).

**L13 — The deliverable (K-TLOG shape + ZKREC strengthener).** ONE portable countersigned receipt rooted in the one witnessed head: {checkpoint head + witness cosignatures + Merkle inclusion proofs + the answer's derivation object + external time brackets} — offline-checkable with zero producer trust. **Dual-mode verification (ZKREC absorption):** every receipt remains recomputable (the assurance floor is pinned at the recompute arm); the Z2 succinct transition-receipt arm (zk-light-client profile over the admission spine) only lowers verifier cost, with its Fiat-Shamir/FRI assumption *instance* and prover-implementation trust entered as **typed assumptions in the certificate algebra**, never folded into "same hash family."

### 1.3 Per-cell trust positions (obligation (g))

| Cell | Trust position | Interpretive trust surface |
|---|---|---|
| Publisher-authoritative formal law (DGFiP-class, where the order promulgates executable law) | **Enroll the promulgated calculus text directly** — formalization-correctness residual zero *by identity*; occupancy is a per-order trust-position rule, never a transferable rank (the a2-struck evidence stays struck) | none (identity) |
| Privately authored codification (statute cell) | n-version formalization + structural δ-term diff + round-trip verbalization + human sign-off transition | authored rulebase, human-gated |
| Case-law cell | signed per-span factor ascriptions only; CONTESTED ascription → UNKNOWN → stability analysis | one auditable per-span act per factor |
| Escalation cell | same base as statute/general cell; budget-gated semantics upgrade only | none additional |
| All cells | LLMs strictly untrusted proposers; admission only as checked bytes through K | — |

### 1.4 What the architecture eliminates structurally (supreme-law rule 2)

Untraced trusted acts (L1 identity); torn canonical artifacts (L2 single crash class); corpus-size-dependent grounding (L3 committed-identifier selection); router-as-unranked-trusted-component (L4 derived cell membership); defective plans (L5 non-existence by macroexpansion); silent UNKNOWN upgrade (L6 closed sum type); jurisdiction leakage (L12 build gate); explanation/decision divergence (L1/L13 same object).

---

## 2. ABSORPTION LEDGER (all §3A mandatory + §3B strengtheners; donor mechanism named at its integration seat)

| # | Donor → E★★ v2 seat | Mechanism | Status (per corrected verdicts) |
|---|---|---|---|
| A1 | K-CBR → L4 case-law cell | Horty sceptical-forcing whole: dominance traces, counter-decision witnesses, exhaustive broken-dominance scans, certified OPEN, extremal-completion stability lemma, ascription-admission gate | **CONDITIONAL** — forcing-certificate independent checker = BO-06 (cell property, not an axis rank, per a3/a4) |
| A2 | K-NSV → L5 plans | Plans as Lean proof-term skeletons; defective plans cannot exist | **CONDITIONAL** — Lean-4 admission machinery = BO-07 |
| A3 | K-BFT → §7(b) notes + L1 mode record | Protocol-exclusion-proof discipline; since Mode A is pinned, the mandated form is the **single-writer exclusion proof actually written** (the §3A#3 mode-conditional branch) | **CONDITIONAL** — BO-08 (a literature replay never enters the evidence set unreplayed, per a2) |
| A4 | K-B0-TARGET → L10 | The only executing AX-10 evidence anywhere: mutation-kill witnesses, capture/Merkle areas, census-verified + the AX-10×AX-20 registry ratchet | **STANDS** — EXECUTING_WITNESS (`authority-v2/proofs/capture-mutation-witness.py`, `run-proofs.sh`); axis rank still moves only by BO-01 execution |
| A5 | K-CAT (+K-CBR, K-RULES) → L9 raised reading | Totality-by-construction cost substrate: static ∀-input worst-case cost theorems per total compiled unit | **CONDITIONAL + PENDING** — BO-15b, gated on creator adoption of the raised clause (§8) |
| B1 | K-TLOG → L3 | Publication-transparency enrollment of gazette logs (clause-(b) corroboration direction; stealth key-compromise issuance → attributable) | absorbed; enrollment inside BO-09 |
| B2 | K-ARG → L6 | Witness-carrying UNKNOWN (even-cycle subgraph, interpretive fork, cost certificate as offline-refutable payloads) | absorbed into the closed-cause sum type |
| B3 | K-CBR → L6 | Flip-set frontier wherever a monotone lattice exists, budget-gated | absorbed |
| B4 | K-B0-TARGET → L6 | The un-gameable proof census (crash ⇒ no manifest) | EXECUTING_WITNESS, kept as the coverage seat |
| B5 | K-B0-TARGET → L7 | The field's only executing partial past-time bitemporal replay witness | EXECUTING_WITNESS (partial); completion = BO-10 |
| B6 | K-NSV → L4/L13 | Assumption-tiered certificates T0/T1/T2 (T2 never serves) + verified external checkers (cake_lpr LRAT, Carcara Alethe) — the certificate-format bottleneck route (obligation (f)): escalation-cell certificates route through the certified reduction until a native mechanized checker exists | absorbed; encoder-soundness = BO-04 (the single load-bearing artifact) |
| B7 | K-NSV → L10 | Machine-checkable critic independence (prompt-closure hashes, producer-ids) | absorbed |
| B8 | K-ARG → L4 | Seam theorem: single acceptance relation carrying Caminada–Amgoud closure/consistency as theorems | absorbed; proofs in BO-03 |
| B9 | K-TLOG → L13 | The single portable countersigned receipt rooted in one witnessed head | absorbed as the deliverable shape |
| B10 | K-B0-TARGET → §6 | The 2,411-file census + per-seat debt register as the measured completion distance | absorbed as the grounding substrate |
| B11 | K-BFT (Mode-B properties) | Serve-time f+1 recomputation, omission accountability, production-time divergence detection | **NOT absorbed** — mode-conditional on the unchosen mode; recorded in §7(b); Mode-A substitutes: countersigned pre-action receipts, CI dual-run byte-compare |

---

## 3. K-DMERGE / K-ZKREC DISPOSITION (requirement 7)

**K-DMERGE (Mode C — anchored deterministic-merge admission fabric).**
- **Absorbed (mode-compatible mechanisms):** (i) the anchor **subset-condition conjunct** — E★★ v2's checkpoint admission includes the machine-checked condition committed-set(head_{n−1}) ⊆ committed-set(head_n), making gapless monotone history a K-conjunct theorem rather than a convention; (ii) the **content-addressed append store / single-crash-class** insight (L2); (iii) refusals-as-derived-facts strengthens the refusal ledger reading (every evaluator of the committed set recomputes the refusal).
- **Refuted in part:** its AX-15/AX-13 rungs are typed WOULD_NEED_BUILD by its own honesty ledger; zero EXECUTING_WITNESS cells; its exceed claims rest on a substrate-proof-uniformity ruling not yet issued.
- **Recorded incomparability + synthesis obligation SO-DM:** Mode C's threshold-free admission integrity (no seat to seize) is a property Mode A structurally lacks, and Mode A's fsync-immediacy finality + executing-evidence continuity are properties Mode C lacks (anchor-cadence finality; detection-class non-equivocation between anchors). Per the freeze registry-integrity clause, Mode C **cannot be removed by prose**: it enters the generation-class registry as an adjudicable class (a future full 22-axis row), and its AX-03 claim — that the frozen relativity note's single-writer/replicated-order **binary** is incomplete — is remitted to the freeze authority as a relativity-note amendment, PENDING. The §7(b) mode notes below therefore cover Mode C's rungs as well as Mode B's.

**K-ZKREC — MANDATORY ABSORPTION, no 10th row (adopting its own §3 disposition verbatim).**
- **Z1** (now): Lean-verified O(log n) Merkle inclusion/consistency checker, differentially byte-tested against `source/merkle-authority.lisp` → the missing AX-18 machine-checked-scaling-bound artifact type = **BO-16**. Caveat carried: grounding via an existing substrate-class mechanization is conditional on the round-2 substrate-proof-uniformity ruling (same standard as K-BFT's AX-03 — not yet issued; see §8).
- **Z2** (months): transparent-STARK succinct transition receipts for the admission spine (MerkleAppend + decidable admission per leaf), chained from genesis; makes the L13 receipt **self-verifying** (H8 verifier class widens from "SBCL toolchain + full corpus" to "~100ms verifier binary") = **BO-17**. **Dual-mode acceptance is mandatory** — the recompute arm remains available and pins the assurance floor; the FS/ROM+FRI assumption instance and prover-implementation trust are typed assumptions in the certificate algebra.
- **Z3**: whole-pipeline arithmetization recorded as **RESOURCE_BOUNDED frontier, never mechanism**, with the arithmetization census verbatim: the 2,411-file SBCL trusted path has no SBCL→zkVM route; the provable perimeter is the admission/commit spine (= Z2); parsing/extraction/NLP stay in recompute mode behind the AX-04 dual-digest byte-equality boundary. Claiming more would be the vendor-grade overclaim the freeze bans.
- AX-06 assurance unchanged (tie by the MODE-EQUIV theorem); AX-04/AX-01/H4/H2 untouched — no organizing-principle claim survives.

---

## 4. 22-AXIS SELF-PROFILE (strict evidence typing; per-axis descriptive, no aggregate)

Legend: EW = EXECUTING_WITNESS(census path) · DE = DESIGN_ENTAILMENT · C(BO-xx) = CONDITIONAL_ON_NAMED_BUILD ≡ UNKNOWN with the stated design floor.

| Axis | Ceiling top | E★★ v2 mechanism (seat) | Evidence today | Honest claim TODAY | Discharge |
|---|---|---|---|---|---|
| AX-01 | R5 certified-unique-status-defeater-closed | L4 root relation: grounded labelling + typed defeaters; escalation via certified enumeration; case-law forcing cell | DE (R4) + EW partial (`inference-gate.lisp` proof-carrying on frozen suites) | **R4**; R5 = C(BO-04, BO-05); case-law-cell R5 property = C(BO-06), prose cell property, not an axis rank | BO-04/05/06 |
| AX-02 | R5 certified-plan-calculus | L5 Lean proof-term plans; gated DEFPIPELINE contracts | DE (R4) + EW partial (`pipeline-dsl.lisp`, `dependency-graph.lisp`) | **R4**; R5 = C(BO-07) | BO-07 |
| AX-03 | R5 certified-coordination | L1 gate arbitration + Calvin-class tier commit | EW floor (`verify-capability-closure.sh` — executional OS-DAC proof) | **R3**; R4/R5 = C(BO-08) (exclusion proof itself must be re-checkable) | BO-08 |
| AX-04 | R5 certified-grounding | L3 three-arm attested capture + dual digest + Merkle selection | EW partial (`primary-anchor.lisp`+`authority-evidence-replay.lisp` dual-digest replay) | **C(BO-09): R5** — rider demands demonstrated structural enforcement; no unconditional rank at R3+ | BO-09 |
| AX-05 | R5 certificate-carrying-citation | L8 grammar-total recognizer + receipt chain | DE (rider permits design-stage); EW for the chain (`authority-proof-bundle.lisp`) | **R5 by DE** (recognizer is NEW-BUILD for grounding: BO-20) | BO-20 (grounding) |
| AX-06 | R5 recompute-and-compare | L2/L13 per-step recompute DAG under signed release identity | EW (`merkle-authority.lisp`, `authority-evidence-replay.lisp`); consolidation still aggregate-only | **R5 by DE**; the executing head reaches it via BO-21 (per-step ledger + census-totality gate — two-history lemma) | BO-21 |
| AX-07 | R5 reflective-certified-memory | L2 salted-leaf hash-chained episode log + erasure certificates + reflective episodes through K | EW (`source/memory.lisp` [RATCHET-3]) | **R5 by DE**; grounding completion BO-25 | BO-25 |
| AX-08 | R5 certified-bitemporal | L7 View(t,τ) + typed amendment events + prefix-consistency | EW partial — the field's ONLY executing partial past-time witness (`legal-authority-receipt.lisp`) | **C(BO-10): R5** — rider demands re-runnable past-time evidence | BO-10 |
| AX-09 | R5 certified-frontier | L6 four-verdict algebra + stability certificates + positive census | EW (`verify-proof-manifest.py` un-gameable census) + DE | **R5 by DE** (rider structural); grounding completion BO-22 | BO-22 |
| AX-10 | R5 escalation-complete | L10 two-regime falsification institution | EW **R3 on covered areas only** (capture/Merkle mutation-kill); axis-level rank UNKNOWN | **UNKNOWN** — operational axis; only execution moves it; no design entailment permitted at any rung | BO-01 |
| AX-11 | R5 certified-transactional-orchestration | L2 atomic seat + intent/outcome journal for external effects | DE + EW partial (`require-durable!`) | **R5 by DE**; grounding via BO-13 writer-seat work | BO-13 |
| AX-12 | R5 certified-governance | L1 gate + genesis-anchored delegation recomputation + fail-closed totality | DE (R4) + EW (`constitutional-dispatch.lisp` :around barrier; OS-DAC closure) | **R4**; R5 = C(BO-02) — verified authority model exists nowhere in the field | BO-02 |
| AX-13 | R5 zero-trust-offline-replay | L13 receipt + full-closure replay; dual-mode (recompute / Z2 proof) | EW partial (release spine + 3 diverse verifiers) | **C(BO-11): R5** — rider demands a replay demo covering every trusted decision class | BO-11 (+BO-17 cost arm) |
| AX-14 | R5 certified-purity | L0 committed closure; logical clock; deterministic merge order | EW partial (journal-prefix replay; canonical ordering seats) | **C(BO-12): R4**; R5 = C(BO-24 + machine-verified purity) | BO-12, BO-24 |
| AX-15 | R5 bounded-certified-recovery | L2 single atomic seat + WAL + verified recovery | EW partial (governance ledgers only; artifact path today ABSENT — census sharpest hole) | **C(BO-13): R4**; R5-path = BO-13 proof + declared bound | BO-13 |
| AX-16 | R5 certified-accountable-stall | L0/L5 budgeted typed termination, no unbounded-wait primitive; variant functions | DE (R3) + EW partial (`autonomy.lisp` bounded errors, fail-closed exits) | **R3**; R4/R5 = C(BO-14) | BO-14 |
| AX-17 | OLD: R5 certified-worst-case-envelope · RAISED: pending | L9 partitioned regime: exact cost certificates + budget gates + external-time bracketing; ∀-input theorems on total cells | DE (old clause, design-stage per rider); B0 seat effectively ABSENT (meter/ledger/gate = new code) | **OLD clause: R5 by DE**, dual-reported; **RAISED: PENDING_CREATOR_APPROVAL — no rank until adoption**; total cells then C(BO-15b), coNP cell = budget gate per §7(a) | BO-15 |
| AX-18 | R5 certified-envelope-accountable-saturation | L9/L10 work-span declared classes; batched Merkle amortization; memoization; Z1/Z2 schedule | DE (R3); EW partial (lparallel tier, artifact-cache, 3000-event chain demo) | **R3**; cost-leg R4 = C(BO-16, Z1); R5-candidate = C(BO-17, Z2) | BO-16/17 |
| AX-19 | R5 certified-explanation | L1 identity: explanation IS the proof object; same-event trace emission | EW partial (MOP visible-thought invariant, `provenance-gate.lisp`) | **C(BO-18): R5** — rider demands independent trace-vs-explanation comparison | BO-18 |
| AX-20 | R5 certified-evolution | L11 floor-vector ratchet + preservation-proof re-checks | EW (`capability-gate.lisp` ratchet, architecture-gate) + DE | **R4 by DE**; R5 = C(BO-19) — the preservation-proof corpus exists nowhere | BO-19 |
| AX-21 | R5 end-to-end-transport | L0 TCB + BO-03 spec-proof program + diverse re-verification links | EW narrow (FSM coverage gate, architecture-gate); 0/17 proofs today | **R2** — the deepest field-wide gap, stated plainly; R3 = C(BO-03); R4/R5 = C(BO-24 + refinement links) | BO-03, BO-24 |
| AX-22 | R5 certified-generality | L12 profile parametricity + build gate | DE (R3); constants enumerable in census | **R3 by DE**; R4 = C(BO-23 two-order); R5 = C(BO-23 noninterference lemma) | BO-23 |

---

## 5. BUILD-OBLIGATIONS REGISTER (every decisive-cell UNKNOWN and every conditional rank; no UNKNOWN closed by prose)

| BO | Axis | Named artifact | Acceptance test |
|---|---|---|---|
| **BO-01** | AX-10 (decisive) | Executed adversarial campaign: repo-wide hash-committed mutation-operator/counter-design registry + offline-recomputable 100%-kill matrix + blocking gate **in operation** (seed: `capture-mutation-witness.py`) | Third party recomputes the kill matrix from registry + release bytes; a seeded surviving mutant demonstrably blocks release and emits the typed escalation transition |
| **BO-02** | AX-12 (decisive) | Lean 4 discharge of `admission-model.sexp` T1–T9 + fail-closed rewrite of `constitutional-gate.lisp:44-45` | Proof objects replay under the vendored Lean kernel offline; injected predicate error yields a recorded typed refusal, never allow |
| **BO-03** | AX-21 (decisive) | Spec-level proof program: K totality/determinism, seq-monotone (T5), RFC-6962 prefix (T3), plan wf, labelling T1–T6, PCK forcing soundness, seam postulates (Caminada–Amgoud closure/consistency) | R3 per ladder: machine-proven spec properties replay offline; verified perimeter enumerated so the one-rank-lower cap is computed |
| **BO-04** | AX-01 (decisive, K-NSV-inherited) | Lean encoder-soundness proof for the defeasible→SAT reduction (escalation-cell certificate route) | Proof replays; differential test vs reference semantics over a committed graph corpus, 0 divergences |
| **BO-05** | AX-01 | Certified exhaustive-extension enumeration certifier (proof-logging SAT/ASP; LRAT checked by cake_lpr), incl. certified OPEN | Even-cycle witness graph: certificate re-checks offline; grounded ⊊ ideal gap exhibited |
| **BO-06** | AX-01 case-law cell | Independent producer-free Horty forcing-certificate checker + machine-checked extremal-completion stability lemma | FORCED/NOT-FORCED certificates re-verify against committed Merkle leaves |
| **BO-07** | AX-02 | Lean-4 plan-admission machinery (proof-term skeletons; sorries = typed obligations) | Defective plan (cycle/mismatch/orphan) fails macroexpansion; plan certificate re-derived by third party |
| **BO-08** | AX-03 | Written + mechanized single-writer exclusion proof (deadlock/lost-update/unarbitrated-conflict) for the Mode-A tier-commit executor, shipped offline-recheckable | Proof replays; adversarial interleaving harness shows atomic tier abort restores pre-tier state exactly |
| **BO-09** | AX-04 | Structural bypass-impossibility demonstration (glob fallback deleted; enumerated bypass attempts blocked) + witness-quorum enrollment (`witness-policy.sexp` enabled) + attested-channel arm + gazette transparency-log enrollment | Bypass census: every path EACCES/type-error; k-of-n cosignatures verify against pinned keys |
| **BO-10** | AX-08 | Total `View(t_legal, t_knowledge)` seat + recorded re-runnable past-time evaluation witness (extends `legal-authority-receipt.lisp`) | Third party replays a past (t,τ) query to byte-equality from committed snapshots |
| **BO-11** | AX-13 | All-class replay demonstration (≥1 decision from every trusted decision class) + closure-totality fix (wall-clock out of release identity, census P0-4) | Replay bundle recomputes bit-equal offline, zero producer trust; decision-class census total |
| **BO-12** | AX-14 | Divergence-free perturbed-environment replay demo + deterministic intra-tier ordering fix | N perturbed re-executions byte-identical |
| **BO-13** | AX-15/AX-11 | Atomic writer seat generalized to `emit-graph`/`deploy.lisp`; six-item WAL transaction; Lean crash-refinement proof (FSCQ technique); injected-crash campaign | kill -9 at every declared crash point recovers exactly σ_pre or σ_post; proof replays; recovery within declared bound |
| **BO-14** | AX-16 | Liveness proof corpus: variant function + budget obligation per wait point, machine-checked | Progress proofs replay; injected stall yields a typed, certificate-carrying accountable stall |
| **BO-15** | AX-17 | (a) deterministic cost meter + persisted hash-chained cost ledger + fail-closed budget gate + external-time bracketing arm (all new code per census); (b) ∀-input worst-case cost theorems per total compiled unit (raised clause, pending §8) | Cost certificate recomputes to bit-equality; budget breach blocks fail-closed; per-unit theorems replay |
| **BO-16** | AX-18 (Z1) | Lean-verified O(log n) Merkle inclusion/consistency checker, differentially byte-tested vs `merkle-authority.lisp` | Machine-checked scaling bound replays; differential test 0 mismatches; grounding conditional on the substrate-proof-uniformity ruling (§8) |
| **BO-17** | AX-18/AX-13 (Z2) | Succinct transition receipts for the admission spine (transparent STARK, dual-mode), typed assumption instances entered in the certificate algebra | ~100ms verifier validates genesis→head; recompute arm byte-agrees on every receipt |
| **BO-18** | AX-19 | Independent trace-vs-explanation comparison harness | Explanation re-derived from the replay trace byte-compares with the served proof object across every decision class |
| **BO-19** | AX-20 | Preservation-proof corpus per committed spec'd class; floor vector serialized into the census chain | Synthetic floor-lowering candidate refused fail-closed; proofs replay at admission |
| **BO-20** | AX-05 (grounding) | Grammar-total FSM recognizer from committed grammar (≤120 clamp deleted); per-citation certificates; RFC-3161 discharge via `asn1-der.lisp` | Load-time coverage gate proves totality over L(G); out-of-G → UNKNOWN-CITATION; certificates re-verify |
| **BO-21** | AX-06 (grounding) | Per-step hash ledger in `consolidation-proof.lisp` (aggregate→per-step) + census-totality blocking gate | Two-history counterexample no longer constructible; orphan artifact blocks release |
| **BO-22** | AX-09 (grounding) | Stability-certificate engine; closed UNKNOWN-cause sum type (from `meta-ontology.lisp` prose); blocking anomaly queue; P0-1 false-green register closed | Stability certificate quantifies over all completions, re-checks offline; injected anomaly renders state non-servable |
| **BO-23** | AX-22 | Profile schema + Greece profile extraction + parametricity build gate; second structurally distinct order instantiated with zero mechanism change; noninterference lemma | Independent verification of the zero-change claim (R4); lemma replay (R5) |
| **BO-24** | AX-21/AX-14/AX-16 substrate | Kernel-substrate decision artifact: CakeML-class verified kernel (refinement proofs — unwritten) vs declared-SBCL diverse-verification optimum — **creator decision** | Either the refinement proofs replay, or the declared-scope record is committed with the superior transport named |
| **BO-25** | AX-07 (grounding) | Salted per-leaf commitment migration + typed erasure certificates + signed memory checkpoint bound into release spine | Erasure destroys body/salt while chain + inclusion proofs verify; rollback past a held checkpoint detected |
| **BO-26** | §7(a) | Lean formalization of the coNP-cell impossibility theorem (the CEILING-BAR `proven_impossible` artifact) | Machine-checked reduction replays (see §7(a)) |

---

## 6. B0-GROUNDING TABLE (feeds the Stage-E transition map)

| E★★ v2 component | B0 seat (census path) or NEW-BUILD |
|---|---|
| Gate serialization seat (physical single writer) | EW: `authority-v2/capability/identities.sh` + `authority-v2/proofs/verify-capability-closure.sh` (kernel EACCES, executional proof) |
| Kernel predicate K | Spec: `authority-v2/kernel/admission-model.sexp` + `schema/transition-certificate.cddl`; proofs NEW-BUILD(BO-02) |
| Constitutional barrier | EW: `systems/orchestrator-cli/constitutional-dispatch.lisp` + `source/constitutional-gate.lisp`; fail-closed flip NEW-BUILD(BO-02) |
| Genesis anchor | EW: `authority-v2/genesis/genesis-policy.sexp` |
| Merkle head | EW: `source/merkle-authority.lisp` (RFC-6962 profile, domain separation) |
| Witness quorum | Spec: `authority-v2/log/witness-policy.sexp` (disabled); enrollment NEW-BUILD(BO-09) |
| Atomic writer seat | EW pattern: `require-durable!` (`source/adoption-decision.lisp`, `source/journal.lisp`); generalization to `source/write-authority.lisp` `emit-graph` / deploy = NEW-BUILD(BO-13) |
| Recovery + WAL | Spec: `authority-v2/store/STORAGE-API.sexp` (absent-by-design today); NEW-BUILD(BO-13) |
| Capture + dual digest | EW: `systems/orchestrator-epistemic/primary-anchor.lisp` (P0-3 hash fix) + `source/authority-evidence-replay.lisp`; attested arms NEW-BUILD(BO-09) |
| Root acceptance relation (grounded core) | EW: `systems/orchestrator-cli/inference-gate.lisp` (JTMS on frozen suites); whole-base certified labelling NEW-BUILD(BO-04/05) |
| Priority/conflict rules | EW: `source/legal-conflict-resolution.lisp`, `source/legal-counterfactual.lisp` |
| Statute δ-calc cell | NEW-BUILD (Catala-class toolchain; admission via L4 ceremony); deontic heuristic (~91.5%) retired from trusted path |
| Case-law PCK cell | NEW-BUILD(BO-06); no B0 precursor |
| Escalation certifier | NEW-BUILD(BO-05) + checker route (cake_lpr/Carcara, existing external verified artifacts, admission via BO-04) |
| Plans | EW: `systems/orchestrator-spec/pipeline-dsl.lisp`, `systems/orchestrator-core/dependency-graph.lisp`; Lean skeletons NEW-BUILD(BO-07); executor fix NEW-BUILD(BO-08/12) — note `parallel-executor.lisp` fail-open is dead code per census §4 |
| Verdict algebra + census | EW: `authority-v2/proofs/verify-proof-manifest.py`, `run-proofs.sh`; stability engine + sum type NEW-BUILD(BO-22) |
| Bitemporal seat | EW partial: `source/legal-authority-receipt.lisp`, `systems/orchestrator-epistemic/transparency-log.lisp`, `source/version-graph.lisp`; total View NEW-BUILD(BO-10) |
| Citations | EW chain: `source/authority-proof-bundle.lisp`, `source/asn1-der.lisp`; recognizer NEW-BUILD(BO-20); `source/citation-authority.lisp:224` clamp deleted (P0-10) |
| Memory/episodes | EW: `source/memory.lisp` [RATCHET-3]; salted-leaf migration NEW-BUILD(BO-25) |
| Release/replay spine | EW: `systems/orchestrator-epistemic/release-spine.lisp`, `artifact-census.lisp` prev_release_root, `deployment/verify/{verify.py,verify.mjs,kernel-verify.lisp}`; per-step ledger NEW-BUILD(BO-21); all-class replay NEW-BUILD(BO-11) |
| Falsification institution | EW: `authority-v2/proofs/capture-mutation-witness.py` + honesty gate; repo-wide registry + campaign NEW-BUILD(BO-01); `use-default*` restarts (`frbr-conditions.lisp`) deleted |
| Evolution ratchet | EW: `systems/orchestrator-cli/capability-gate.lisp`, `architecture-gate.lisp`, tombstones, drift gates; preservation corpus NEW-BUILD(BO-19) |
| Cost regime | effectively ABSENT in B0 (only `instrumentation.lisp` advisory metrics — census honest note); meter/ledger/gate/bracketing NEW-BUILD(BO-15) |
| Profiles | constants enumerated (`greek-law-types.lisp`, `structure.lisp`, FEK tables, `/exp/ell`, calendar, adapter range); schema + gate NEW-BUILD(BO-23); universal-source-contract = unapproved frozen proposal (creator gate) |
| Trace/introspection | EW: `source/deliberation.lisp` MOP invariant, `provenance-gate.lisp` + `provenance-link.lisp`; comparison harness NEW-BUILD(BO-18) |
| Time authorities | EW parser: `source/asn1-der.lisp`, `source/timestamp-authority.lisp` (with SECURITY-REDTEAM O-2 fix); bracketing arm NEW-BUILD(BO-15) |
| ZKREC Z1/Z2 | NEW-BUILD(BO-16/17); no B0 precursor |
| P0 register closure (false-green emitters, fail-open handlers, JWS wiring, determinism-archive, SBOM, license contradictions) | census §3 P0-1..P0-12, verbatim changes listed there — precondition to every EXECUTING_WITNESS claim surviving independent replay |

---

## 7. IMPOSSIBILITY THEOREM DRAFTS (frozen-standard: theorem or construction, never cost)

### (a) AX-01-coNP-cell × AX-17-raised joint attainment — impossibility draft (with constructive complement)

**Setting.** The raised AX-17 clause (pending adoption) demands, for a cell, a machine-checked ∀-input worst-case cost theorem ∀x. C(f,x) ≤ B(f,|x|) that dominates the committed institutional budget ("we prove we never have to give up"). The AX-01 R5 escalation cell computes sceptical acceptance under preferred semantics / certified ideal acceptance over finite defeasible bases.

**Theorem (draft).** Let β be any committed budget polynomial in the base size n. There is no sound and complete decision procedure f for sceptical-preferred (resp. ideal) acceptance over arbitrary finite bases together with a sound cost theorem B with B(n) ≤ β(n) for all n — unless coNP ⊆ P.
*Proof sketch.* Sceptical acceptance under preferred semantics is Π₂ᵖ-complete for general AFs and coNP-hard already for the certificate-verification fragment the frozen ceiling names (verification of exhaustive-extension certificates is the recorded "co-NP verification cost" of the frozen AX-01 derivation); ideal-acceptance decision is coNP-hard (Dunne). A total procedure f with a machine-checked polynomial ∀-input bound is a polynomial-time decision procedure for a coNP-hard problem; hence coNP ⊆ P. ∎
**Corollary (the partitioned regime as theorem, not choice).** Any sound ∀-input envelope B on the escalation cell is super-polynomial (under the assumption above); for every committed budget β there exist inputs with B(|x|) > β(|x|); therefore the **fail-closed budget gate is not eliminable on this cell** — "we tell you when we give up" is the ceiling there. Joint attainment of {AX-01 R5 on the escalation cell} × {budget-dominating AX-17-raised envelope on that same cell} is impossible; the raised envelope and the R5 semantics are jointly attainable only under the committed cell partition.
**Constructive complement (refutation-by-construction for the total cells).** On the δ-calc statute cell (strong normalization, structural recursion), the grounded labelling cell (alternating fixpoint, ≤ |N| rounds — the frozen AX-01 lean obligation T1), and the PCK forcing cell (O(|CB|·|F|)), polynomial ∀-input envelopes are attainable by construction — the A5 absorption. **Mechanization = BO-26.** This draft is the `proven_impossible` leg CEILING-BAR requires for the one axis-pair where E★★ v2 does not target joint attainment of both maxima on one cell.

### (b) Unchosen-mode rung notes (impossibility-under-declared-model; Mode B and Mode C)

Under E★★ v2's pinned declared model (single node, POSIX, honored write barriers, external witness + time-authority quorums as the only external resources):

1. **Real-time equivocation prevention (Mode B rung).** Fork-consistency is the ceiling for any log-bytes-only verifier of a single producer (Mazières–Shasha; frozen AX-07(c)/AX-08(b)); the witness quorum lifts it to split-view **resistance** (detection/attribution), and no single-writer construction can reach quorum-intersection **prevention** — prevention requires ≥2f+1 intersecting admission quorums, structurally absent from a single-node model. Model theorem, not cost. The frozen ceilings themselves cap at the witness-lifted rung, so no frozen rung is forfeited.
2. **Omission accountability (Mode B rung).** A single writer can drop a request before any record exists; a guarantee of eventual inclusion requires a replicated inclusion rule. Mode-A attainable form: countersigned pre-action receipts (client-held submission evidence) — detection, absorbed at L1.
3. **Replicated durability-at-ack (Mode B rung).** Excluded by the declared single-node model; the frozen AX-15 ceiling itself classifies replication as an outside-model resource, not an impossibility — recorded as the declared-scope fact.
4. **Production-time nondeterminism detection by cross-replica divergence (Mode B rung).** No second replica exists in-model; Mode-A substitute is the CI dual-run byte-compare gate (pre-production, strictly weaker — stated, not hidden).
5. **Threshold-free admission integrity (Mode C rung).** A physical seat can be seized; Mode A's bound: a seized seat cannot rewrite history past the witness-cosigned head (attributable fork evidence) and cannot forge offline-replayable derivations (H8) — it can halt or fork detectably. The residual gap to Mode C's no-seat property is real and is carried in synthesis obligation SO-DM (§3), which per registry integrity must be discharged by adjudication or a frozen theorem, not by this note.

### (c) AX-13/AX-07 erasure-composition — the adjudicated reading, drafted as the frozen ceiling annotation

Proposed AX-13 letter (for the freeze authority, S2 version-stamped): *"Auditability terminates at the commitment boundary — including under lawful erasure: for any derivation whose input body/salt was destroyed by a typed erasure certificate, commitment-level replay (hash-chain and inclusion-proof verification) remains total, and content-level re-verification is re-verdicted as STABLE-over-erasure where a certified invariance proof exists, else typed UNKNOWN-REDACTED; neither outcome is a silent pass, and the erasure certificate is itself part of the committed closure."* This freezes the round-1 adjudication so the seam cannot be re-litigated; no rung text changes.

---

## 8. CREATOR-DECISION FLAGS (only the creator approves; nothing here self-activates)

1. **AX-17 raised clause adoption** (ESCALATION_FILED — PENDING_CREATOR_APPROVAL), with the pre-adoption reconciliation of the raised wording against the frozen ladder's R5 "certified-worst-case-envelope" text.
2. **B0 continuity ruling (obligation (h))**: whether E★★ v2 admission must pass through the existing B0 ratchet chain as a ratchet-certified evolution sequence — this dossier is architected to make that path available (L11), not to presume it.
3. **Kernel substrate (BO-24)**: CakeML-class verified transport vs declared-SBCL scope — the superior transport is named per the supreme law; adoption is the creator's.
4. **Substrate-proof-uniformity ruling** (completeness-critique item iii): whether existing offline-re-checkable substrate-class mechanizations ground rungs pre-replay — decides BO-16's grounding and, symmetrically, K-BFT's AX-03 and K-DMERGE's AX-15 story.
5. **Mode-C registry row (SO-DM)** and the AX-03 relativity-note ternary amendment — freeze-authority items.
6. **Deferred license policy** interactions (census P0-8 license contradictions) — closed only per the standing CLAUDE.md rule.

---

## 9. HONEST BOTTOM LINE (per-axis; no counts, no ranking, no VERIFIED claims anywhere)

**AT ceiling today by DESIGN_ENTAILMENT (riders permit design-stage ranking):** AX-05, AX-06, AX-07, AX-09, AX-11 at R5; AX-17 at R5 **under the OLD clause only** (RAISED pending); AX-20 at R4 (ceiling rung R5 conditional); AX-22 at R3 (ceiling rungs R4/R5 conditional).

**KNOWN below-ceiling ranks held today with the gap named:** AX-01 R4 (semantics gap → BO-04/05/06); AX-02 R4 (→ BO-07); AX-03 R3 (→ BO-08); AX-12 R4 (→ BO-02); AX-16 R3 (→ BO-14); AX-18 R3 (→ BO-16/17); AX-21 **R2 — the deepest gap in the field and in this design**, movable only by BO-03/BO-24.

**CONDITIONAL (≡ UNKNOWN with a design floor; only the named artifact moves them):** AX-04 (BO-09), AX-08 (BO-10 — E★★ holds the field's only executing *partial* witness), AX-13 (BO-11), AX-14 (BO-12), AX-15 (BO-13), AX-19 (BO-18).

**UNKNOWN, evidence-blocked, no design entailment possible:** AX-10 — executing R3 on covered areas only (capture/Merkle); axis rank moves only by BO-01 execution.

**Deviation-by-theorem (the CEILING-BAR second leg):** exactly one, scoped — the escalation-cell AX-17-raised envelope, covered by the §7(a) impossibility draft (mechanization BO-26); everywhere else E★★ v2 targets attainment, not exemption.

**Honesty invariant.** Every AT-by-entailment claim above rests on a rider the frozen instrument permits design entailment to satisfy; every other claim is typed CONDITIONAL_ON_NAMED_BUILD or UNKNOWN with its discharging artifact and acceptance test in §5. VERIFIED is issuable only by machine check plus independent reproduction, and none is issued here.

---
*Inputs: `_ssp_ceilings_v2.json` · `_ssp_freeze_v2.json` · `_stageC_report.md` §3/§7 · `_stageC_verdicts_r2corrected.json` · `_stageC_steelmen.json` (K-SUP; donors K-CBR/K-NSV/K-CAT/K-BFT/K-B0-TARGET) · `_stageB_master.md` · `_b0_map.md` · `CEILING-BAR-RULE.md` · K-DMERGE/K-ZKREC round-2 filings. All scratchpad paths under `/tmp/claude-0/-home-user-THE-LEGAL-WATCHTOWER/8a568901-aaa2-51c4-86b4-eb7bbdff4e90/scratchpad/`.*
---

## RECORD-COMPLETION RIDER (μέρος του κλεισίματος του Round 2 — απαίτηση του τελικού completeness αντιπάλου· κανένα round 3)

(a) **Remit lines (§7-mandate item 5, remit branch):** τα δύο ανοιχτά S1 pairwise ερωτήματα (K-SUP AX-18 operative-floor· K-CBR interpretive-economy) και η σημείωση **απουσίας άξονα εμπιστευτικότητας/επαγγελματικού απορρήτου** παραπέμπονται ρητά στην αρχή παγώματος/δημιουργό ως taxonomy notes — δεν αδικάστηκαν εδώ.
(b) **AX-07 / K-DMERGE συμπλήρωση:** ladder-top R5 έναντι μηδενικού EXECUTING_WITNESS δότη — κανένα rung και κανένα exceed δεν κατασκευάζεται· η γραμμή κλείνει ως immaterial.
(c) **Σημαίες #7–#8 προστίθενται στο §8:** (#7) substrate-proof-uniformity ruling ως αυτοτελής απόφαση· (#8) τα remits του (a) ως ρητές γραμμές δημιουργού.
(d) **Οι deflations τυποποίησης τεκμηρίων της αδίκασης (D1/D3/D4/D6/D7/D8) ισχύουν verbatim** — ειδικά: το `primary-anchor.lisp` ΔΕΝ ταξιδεύει ως EXECUTING_WITNESS όσο το P0-3 μένει άλυτο· και το §7(a) διαβάζεται «deviation-by-DRAFT» (όχι by-theorem) μέχρι BO-26 mechanization + S2 υιοθέτηση.

Τυπογραφική συμφιλίωση (τελικός honesty, P2): η αναφορά RFC-6962 εναρμονίζεται με το RFC-9162 profile wording του παγωμένου AX-06 lean obligation στα BO-03/BO-21.
