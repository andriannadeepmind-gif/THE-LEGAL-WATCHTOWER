# STAGE C — ROUND 1 REPORT (SYNTHESIS-OBLIGATIONS COLLECTOR)

Inputs: 9 steelman profiles, 4 per-axis verdict bands (22 axes × 9 classes = 198 adjudicated cells), CEILING-BAR rule (ACCEPT(E★★) ⇔ ∀a: attains(ceiling_a) ∨ proven_impossible; tournament = falsifier of attainment, not source of synthesis; the E★★ is generated from the 22-ceiling vector).

---

## 1. THE SCOREBOARD (non-compensatory — no totals ranking; counts only)

Classification: an adjudicated rank equal to the axis's ceiling maximum rung = AT_CEILING; a definite lower rank = BELOW; adjudicated UNKNOWN = UNKNOWN. EXCEED_REFUTED/EXCEED_VALID verdicts are classified by their adjudicated_rank.

| Class | AT_CEILING | BELOW | UNKNOWN | AT_CEILING axes |
|---|---|---|---|---|
| K-SUP | 12 | 9 | 1 | 04,05,06,07,08,09,11,13,14,16,17,19 |
| K-NSV | 12 | 8 | 2 | 02,05,06,07,08,09,11,13,14,16,17,19 |
| K-CBR | 11 | 10 | 1 | 01(cell-relative),04,05,06,07,08,09,11,13,17,19 |
| K-CAT | 9 | 8 | 5 | 04,05,06,08,11,13,14,17(EXCEED_VALID),19 |
| K-BFT | 9 | 9 | 4 | 03(unique),04,05,06,07,08,11,13,19 |
| K-ARG | 6 | 11 | 5 | 06,07,08,09,13,19 |
| K-B0-TARGET | 6 | 11 | 5 | 04,06,08,09,13,19 |
| K-TLOG | 5 | 9 | 8 | 04,06,07,11,13 |
| K-RULES | 1 | 19 | 2 | 17 |

**Closest to the ceiling vector.** K-SUP and K-NSV tie at 12 AT-CEILING axes and are **pointwise incomparable**: K-SUP strictly better on AX-01 (KNOWN R4 vs UNKNOWN) and AX-04 (R5 vs R4); K-NSV strictly better on AX-02 (R5 vs R4, the only AX-02 ceiling attainment in the field); equal or tied everywhere else. K-CBR is the only class holding AX-01 at ceiling (cell-relative, case-law cell). Under the non-compensatory order, no class dominates any other of the top three; no class attains the full vector.

**Field-wide ceiling gaps (no class AT on 7 axes)** — these are the E★★ frontier, unclaimed by anyone:
- AX-10: field max KNOWN = R3 (K-B0-TARGET only; 8 classes UNKNOWN) — operational axis, design cannot entail it.
- AX-12: field max KNOWN = R4 (verified authority model exists nowhere).
- AX-15: field max = R4 (no verified recovery procedure exists in any class).
- AX-18: field max = R3 (no machine-checked scaling bound artifact exists).
- AX-20: field max = R4 (no preservation-proof corpus exists).
- AX-21: field max = R2 across all nine classes — the single deepest field-wide gap; every spec-level proof program is unwritten (K-CAT nearest to R3 via the existing F* calculus artifact, perimeter-capped).
- AX-22: field max = R3 (no two-order instantiation of any candidate's full mechanism set).

## 2. CEILING ESCALATIONS (EXCEED_VALID — these amend the bar per the supreme law)

Exactly **one** exceed claim survived out of 24 filed:

**AX-17 (from K-CAT).** Clause (a) of the frozen ceiling is falsified as a least upper bound. For totality-by-construction substrates (non-Turing-complete calculi, structurally bounded iteration), a machine-checked **distribution-independent ∀-input worst-case cost theorem** ∀x. C(f,x) ≤ B(f,|x|) — derived from the artifact alone, before any workload exists — is feasible with precedented technique and strictly stronger than frozen-workload quantile certificates plus a runtime budget gate ("we prove we never have to give up" vs "we tell you when we give up").

**NEW CEILING**: clauses (a)–(c) as frozen PLUS, for totality-by-construction substrates, a certified ∀-input worst-case cost envelope per compiled unit; frozen-workload quantile certificates remain the supremum only for Turing-complete substrates.

**Re-freeze consequence (binding on round 2)**: all AX-17 AT_CEILING verdicts issued against the old statement (K-SUP, K-CBR, K-NSV, K-RULES, K-CAT) must be re-adjudicated against the raised clause wherever the candidate's substrate is total. K-CAT, K-CBR, K-RULES plausibly attain the raised rung (their bounds are already ∀-input in form); budget-gate-only envelopes on Turing-complete cells do not.

All other 23 exceed claims: REFUTED (recorded in the verdict bands; several were demoted to "within-clause operational strengtheners" — see §3B).

## 3. E★★ ABSORPTION LIST

### 3A. MANDATORY (a challenger holds a KNOWN rung the K-SUP join's adjudicated profile lacks)

| # | Axis | Donor | Rung gap | Mechanism to absorb |
|---|---|---|---|---|
| 1 | AX-01 | K-CBR | join R4/UNKNOWN vs R5 (case-law cell) | Horty sceptical-forcing engine: direct polynomial certificates (dominance traces, counter-decision witnesses, exhaustive broken-dominance scans) with a trivially-entailed independent checker — **no reduction-mediated unbuilt soundness theorem**, which is exactly why it is the only KNOWN AX-01 R5 in the field. Absorb whole as the case-law cell, including certified OPEN and the extremal-completion stability lemma. |
| 2 | AX-02 | K-NSV | join R4 vs R5 | Plans as Lean proof-term skeletons: goal entailment, gap-freedom (sorries = typed blocking obligations), step soundness kernel-checked per plan; defective plans cannot come into existence (fail-closed macroexpansion). The verified plan calculus is Lean's own type theory — built, not promised. |
| 3 | AX-03 | K-BFT | join R3 vs R5 | Existing, independently re-checkable protocol-exclusion proofs (Velisarios/ACL2/TLA+-Apalache) for the consensus substrate class — the only AX-03 R5 evidence in the field. Absorption is mode-conditional (see obligation (b) in §4); if Mode A is chosen instead, the small single-writer exclusion proof must actually be written before AX-03 rises above R3. |
| 4 | AX-10 | K-B0-TARGET | join UNKNOWN vs R3 (executing) | The only KNOWN AX-10 evidence anywhere: executing mutation-kill witnesses (capture/Merkle areas, deterministic, census-verified) with tracked findings. Absorb as the seed of the E★★ falsification institution, together with the (refuted-as-exceedance but valid-as-composition) monotone-registry ratchet AX-10×AX-20. |
| 5 | AX-17 (raised) | K-CAT (with K-CBR, K-RULES) | join meets old bar only | Totality-by-construction cost substrate: static ∀-input worst-case cost theorems per compiled unit for every total cell of the pipeline. Under the §2 escalation this is now a ceiling requirement, not an option; the coNP escalation cell is handled under obligation (a) in §4. |

### 3B. SUPREME-LAW STRENGTHENERS (no rung gap, but strictly superior conceptions — «αν υπάρχει ανώτερη, η τρέχουσα δεν κάνει» makes them obligatory absent a frozen counter-argument)

- **AX-04 (K-TLOG)**: publication-transparency enrollment of gazette logs — within clause (b)'s no-maximum corroboration direction; converts stealth key-compromise issuance from undetectable to attributable.
- **AX-09 (K-ARG)**: witness-carrying UNKNOWN (even-cycle subgraph, interpretive fork, cost certificate as offline-refutable payloads) — adjudicated the strongest realization of the frozen supremum.
- **AX-09/AX-01 (K-CBR)**: flip-set frontier (minimal ascription sets that flip a verdict) wherever a monotone lattice exists.
- **AX-09 (K-B0-TARGET)**: the un-gameable proof census (crash yields no manifest, never false green) — executing realization of the positive-census clause.
- **AX-08 (K-B0-TARGET)**: the field's only executing past-time bitemporal replay witness — satisfies the AX-08 delta rule's evidence rider that converts DE credit into tournament rank.
- **AX-21 transport (K-NSV)**: assumption-tiered certificates (T0/T1/T2, T2 never serves) + verified external checkers (cake_lpr, Carcara) — the only transport mode with existing verified artifacts.
- **AX-10 method (K-NSV)**: machine-checkable critic independence (committed prompt-closure hashes prove context excluded implementer rationale; producer-ids prove distinct model family).
- **Seam theorem (K-ARG)**: single acceptance relation carrying Caminada–Amgoud closure/consistency as theorems — the only known answer to the inter-substrate joint-consistency defect (§4d).
- **If Mode B (K-BFT)**: serve-time f+1 independent recomputation, collusion-resistant ratchet, omission accountability, production-time nondeterminism detection — emergent properties with no per-axis seat.
- **Deliverable shape (K-TLOG)**: the single portable countersigned receipt rooted in one witnessed head — the institutional output object.
- **Evidence substrate (K-B0-TARGET)**: the 2,411-file census + per-seat debt register — the only measured completion distance in the tournament.

## 4. INCOMPARABLE / SYNTHESIS OBLIGATIONS (each needs a constructed join or a frozen joint-attainment impossibility theorem — cost/effort reasons inadmissible per CEILING-BAR)

**(a) AX-01-R5 × AX-17-raised × AX-21 — the totality/expressiveness incomparability (K-CAT's attack, sharpened by the §2 escalation).** The ∀-input envelope is purchasable only on total substrates; the ideal/sceptical-preferred escalation cell is coNP. Obligation: EITHER a partitioned cost regime frozen as architecture (total cells carry ∀-input theorems; the escalation cell carries budget-gated frozen-workload certificates, with the cell boundary a committed machine-enforced artifact) with a frozen impossibility theorem that ∀-input polynomial envelopes cannot hold on the coNP cell, OR a construction refuting the impossibility. This is the sharpest genuine incomparability in the record.

**(b) Mode A × Mode B — one physical commit event, two definitions of "committed" (K-BFT's, K-NSV's, K-RULES's, K-TLOG's convergent attack; conceded by K-SUP itself).** Single-writer fsync (AX-15/AX-17 latency class, frozen model of those ceilings) vs consensus commit (prevention-class nonforking, replicated durability-at-ack, omission exclusion, collusion-resistant ratchet). No deployment holds both; AX-03 was already deflated partly for the unpinned mode. Obligation: pin ONE mode; re-derive every coupled rung (AX-03, 07, 08, 11, 12, 15, 16, 17) under it; and resolve the two-trust-algebra incoherence (witness policy layered on quorum certificates has no disagreement semantics — either one algebra with witnesses as non-voting learners, or Mode A with cosigning only). The rungs of the unchosen mode require a frozen impossibility-under-chosen-model note.

**(c) Router soundness — the partition function is an unranked trusted component (K-ARG + K-RULES).** Which cell answers a query is itself a defeasible legal conclusion; cross-cell defeat (case-law rebuttal vs calculus conclusion) needs a seat; inter-substrate joint consistency has no axis coordinate. Obligation: adopt the root-substrate shape (one acceptance relation with global rationality postulates; calculi and PCK admitted as strict-rule/certificate oracles into it) or freeze a soundness argument for hardcoded routing. Connects to (i).

**(d) One gate = one head (K-NSV prong 3 × K-TLOG prong 1).** The structural-impossibility rungs (AX-19 divergence, AX-06 pre-action receipts, AX-11 commit, AX-12 evaluation) hold only if effect-execution, trace-emission, admission, and commitment-root are the SAME event at one seat under one commitment topology; per-axis-consistent global equivocation is otherwise constructible. Obligation: E★★'s serialization point, kernel predicate, and witnessed head are one artifact by construction — a constraint on the join, already implicitly honored by the adjudicated K-SUP R5s, now to be frozen explicitly.

**(e) AX-07 erasure × AX-13 total replay.** Resolved by adjudication (the declared STABLE-over-erasure / UNKNOWN-REDACTED composition rule was accepted as inside the commitment-boundary clause, and the rung held). Obligation reduced to: freeze the adjudicated reading as the official AX-13 letter so the seam cannot be re-litigated.

**(f) Certificate-format bottleneck (K-NSV's AX-01×AX-21 coupling).** The only verified checkers existing today are clausal (cake_lpr LRAT, Carcara Alethe); native argumentation/bespoke-calculus checkers are unbuilt — confirmed by the uniform AX-21 R2 deflations. Obligation: the escalation cell's certificates route through the certified reduction (encoder + clausal proofs) until a mechanized native checker exists; the encoder-soundness proof is the single load-bearing unbuilt artifact deciding the AX-01 dominance conjecture.

**(g) The publisher-authoritative trust position is relational, not mechanical (K-CAT).** Zero-formalization-gap on the DGFiP-class cell does not survive substrate swap. Obligation: per-cell trust-position rule — E★★ enrolls promulgated formal law directly where the order provides it (the strictly stronger DIM-16 cell) while carrying the root substrate elsewhere; the exceed claims built on this cell stay refuted (secondary-evidence premise), but the cell occupancy itself is a real asset requiring a join rule.

**(h) Evolution continuity (K-B0-TARGET).** Under H7 and the creator's governance frame, E★★ either forfeits the committed hash-chained institutional history or is admitted as a ratchet-certified evolution sequence over the existing chain. Obligation: define E★★'s admission path through B0's ratchet — with the explicit flag that this is a **creator decision** (only the creator approves phases), not adjudicable here.

**(i) Case-law cell coverage (K-CBR).** PCK is the sole holder of the cell; the envelope composes with it rather than dominating it. Obligation: absorb PCK whole (§3A#1) including its ascription-admission gate, and give cross-cell defeat (precedent-vs-statute) its seat at the root substrate per (c). The interpretive-economy property (trusted interpretive surface per certificate) remains unmeasured — record as taxonomy note for the freeze authority, not a rung.

## 5. UNKNOWN LEDGER (33 fully-UNKNOWN cells blocking verdicts, plus rank-residuals)

**Grouped by resolving evidence:**

| Axis | UNKNOWN classes | What resolves it |
|---|---|---|
| AX-10 | K-SUP, K-ARG, K-CAT, K-CBR, K-NSV, K-RULES, K-TLOG, K-BFT (8 of 9) | **Only execution**: a run adversarial campaign against a hash-committed registry with an offline-recomputable kill matrix and a blocking gate in operation. No design can entail this axis; the cells are evidence-blocked, not argument-open. K-B0's R3 is the only seed. |
| AX-03 | K-ARG, K-CAT, K-RULES, K-TLOG, K-B0 (+ R4/R5 residuals: K-SUP, K-CBR, K-NSV) | The mechanized protocol-exclusion proof for the class's own seat, shipped as an offline re-checkable artifact (small single-writer lemma; K-BFT already holds it for the consensus class). |
| AX-12 | K-CAT, K-TLOG, K-BFT, K-B0 | Machine-checked verification of the authority model itself (the R5 differentiator; T1–T9-class theorems). Field-wide: nobody has it. |
| AX-01 | K-NSV, K-TLOG, K-BFT, K-B0 | K-NSV: the encoder-soundness Lean proof (decides the dominance conjecture). K-TLOG/K-BFT: certified proof-object checker layer + rulebase. K-B0: whole-base certified labelling + deontic-classifier retirement + ideal module. |
| AX-05 | K-ARG, K-TLOG, K-B0 | Built grammar-total recognizer + per-order authority-state data (K-B0 additionally: retire the regex/PageRank heuristic and the ≤120 clamp). |
| AX-09 | K-CAT, K-TLOG, K-BFT | The stability-certificate generator (K-CAT's self-named "genuinely new component"), census machinery, closed cause enumeration — built and demonstrated. |
| AX-07 | K-CAT | Verified-store integration (self-conceded build). |
| AX-11 | K-ARG, K-B0 | External-effect intent/outcome journal built; K-B0: atomic writer seat (fsync/temp-rename on emit-graph) closing the census P1. |
| AX-08 | K-TLOG | The total View(t_legal, t_knowledge) amendment-calculus build. |
| AX-19 | K-TLOG | Inherits the AX-01 core build (proof-object substrate must exist before the receipt-binding shape can rank). |

**Decisive-cell flag:** the AX-10 column (whole field), K-NSV's AX-01 (dominance conjecture), and the AX-12 column gate any final ACCEPT(E★★) under the CEILING-BAR rule — they are ceiling axes no argument can close.

## 6. ENVELOPE VERDICT — do the envelope_attacks reveal a real defect of the join approach?

**Aggregate verdict: the join survives as a generation method but is refuted as "max() by fiat."** The attacks collectively establish that a coherent E★★ is a single constructed architecture — one gate, one commitment head, one root acceptance relation, one pinned operating model — whose per-axis maxima are re-derived, not inherited. Per attack:

- **K-SUP (self-attack), 4 prongs.** (1) Mode equivocation: CONFIRMED — already cost the join its AX-03 rank; obligation (b). (2) Erasure vs replay: DEFUSED by adjudication (rung held); reduces to freezing the reading, obligation (e). (3) Budget-coupled AX-01 crown: REAL but priced — attainment is workload-relative; the freeze should annotate "R5 under declared budget" as distribution-relative; not a rung-defeater since breach is a typed refusal priced on AX-17. (4) unknown_rule as killer: DIRECTIONALLY CONFIRMED (AX-10 UNKNOWN, several R5 deflations) but OVERSTATED — 12 axes survived as design entailments; the join did not decay to UNKNOWN-almost-everywhere.
- **K-ARG.** (1) Defeasible partition function: REAL DEFECT — no axis measures the router; obligation (c). (2) Joint inconsistency across cells has no axis coordinate: REAL — resolved only by the single-acceptance-relation absorption (§3B). (3) Joint proofs decay to UNKNOWN: PARTIALLY REAL — composite-specific coupling obligations are real; wholesale decay did not occur.
- **K-CAT.** Cascade-from-one-commitment: VALIDATED in part — the AX-17 escalation (only total substrates reach the raised rung) and the AX-21 field-wide R2 confirm that the join cannot claim K-ARG-strength AX-01 and K-CAT-strength proof profile by fiat; obligation (a). Trust-position non-transferability: REAL, obligation (g). Single-artifact coherence: real but unmeasured; carried as per-cell identity requirement.
- **K-CBR.** (1) Stability-mechanism non-transferability: REAL — the rung label survives the join only where the monotone lattice exists; the generic generator is the unbuilt hard part. (3) Certified OPEN: PARTIALLY REFUTED (rulebase analog exists per the AX-01 judge) but (4) cell coverage stands: the envelope federates with PCK, it does not dominate it — obligation (i).
- **K-NSV.** (1) Certificate-format bottleneck: CONFIRMED by the uniform AX-21 deflations — obligation (f). (2) Model-relativity of AX-16/17 proofs: real, folded into (b). (3) "K-NSV is a retract of every coherent envelope": CONFIRMED as a constraint, not a defect — the adjudicated join's surviving R5s (AX-19, AX-06, AX-11) hold precisely because it already has the single verify-out-gate shape.
- **K-RULES.** (1) Router: same as K-ARG, real. (2) Cost-class contamination: REAL and now sharpened by the escalation — one ∀-input envelope over the shared stream is impossible with a coNP cell; forces the partitioned regime of (a). (3) Stratification invariant not join-preserved: real; the collapse theorem is retained cell-locally only, to be frozen as such. (4) Evidence decay: overstated (see scoreboard).
- **K-TLOG.** (1) One-witnessed-head binding invariant has no axis seat: REAL — obligation (d); the envelope escapes only by becoming a K-TLOG instance at the spine, which is hereby accepted as a construction constraint. (3) Verifier-complexity union: REAL and unmeasured — E★★ must keep one verification regime; record as taxonomy note. (4) The portable receipt as emergent deliverable: real; absorbed with the spine.
- **K-BFT.** Commit-point coupling across ≥7 axes: REAL — the strongest form of (b). The two-trust-algebra incoherence in K-SUP's own text (client witness policies atop quorum certificates): REAL DEFECT as written; fixed only by choosing one algebra. Emergent non-axis properties: real absorption candidates conditional on mode choice.
- **K-B0-TARGET.** (1) H4 one-seat fusion: PARTIALLY REAL — fusion is required; that it must be B0's specific seat is a continuity/governance claim, not structural. (2) No admissible evolution path for a chimera: REAL under the creator's governance frame — obligation (h), flagged for creator decision. (3) Dangling cross-axis preconditions: CONFIRMED by the actual deflations (e.g., AX-12 R5 riding unbuilt AX-21). (4) Wrapper-federation inadmissibility: governance-real — the supreme law's one-seat-per-concept rule independently forbids a stapled envelope, converging with (c)/(d) from the technical side.

## 7. ROUND-2 NEED — YES, round 2 is required by the termination rule

All three triggers fire:

1. **Surviving exceed-claim**: the AX-17 EXCEED_VALID amends the bar; the escalation text itself mandates re-adjudication of every old-bar AX-17 AT_CEILING verdict (K-SUP, K-CBR, K-NSV, K-RULES, K-CAT) against the raised clause.
2. **Unabsorbed wins**: the 5 mandatory absorptions (§3A) are not yet in any single architecture; the adjudicated K-SUP profile lacks KNOWN rungs on AX-01, AX-02, AX-03, AX-10, AX-17-raised that challengers hold.
3. **Open UNKNOWNs on decisive cells**: AX-10 (field-wide), AX-12 (field-wide), K-NSV AX-01 — these are ceiling axes and, under CEILING-BAR, ACCEPT(E★★) cannot issue while they stand unaddressed.

**Round 2 must contain, precisely:**

1. **AX-17 re-adjudication** of all 9 classes against the escalated ceiling, with partitioned verdicts for mixed-substrate candidates (total cells vs Turing-complete cells).
2. **E★★ v2 as one constructed architecture** (not a profile): the K-SUP join amended with the 5 mandatory absorptions and the §3B strengtheners, restructured under the frozen envelope constraints — one gate = one witnessed head = one root acceptance relation carrying the rationality-postulate seam theorem; one pinned operating mode with all coupled rungs re-derived under it; per-cell trust positions (publisher-authoritative cell enrolled directly); partitioned cost regime with committed cell boundary. Adjudicated as a fresh single candidate.
3. **Frozen theorems for the incomparabilities**, per CEILING-BAR's proven_impossible standard (theorem or construction, never cost): (a) AX-01-coNP-cell × AX-17-raised joint-attainment impossibility (or its refutation by construction); (b) chosen-mode declaration with impossibility-under-model notes for the unchosen mode's rungs; (e) the adjudicated AX-13/AX-07 reading frozen into the ceiling text.
4. **UNKNOWN ledger disposition**: decisive-cell UNKNOWNs (AX-10, AX-12, K-NSV AX-01, AX-21 field-wide R2) typed as evidence-blocked build obligations with named artifacts — round 2 records them as obligations of E★★ v2; it must NOT re-argue them closed, since only execution/proof artifacts can move them.
5. **Open S1 pairwise questions** under incomparable_rule: K-SUP's AX-18 operative-floor argument (filed, not adjudicated); K-CBR's interpretive-economy property; K-TLOG's verifier-complexity — adjudicate or remit to the freeze authority as taxonomy notes.
6. **Creator-decision flags** (per the permanent law, only the creator approves): the (h) continuity ruling — whether E★★ admission must pass through the existing B0 ratchet chain — and the mode choice in (b) insofar as it re-scopes declared operating models of frozen ceilings.

**Round-3 trigger**: only if round 2's re-adjudication produces a new EXCEED_VALID, a new incomparability, or an E★★ v2 cell adjudicated BELOW a ceiling without a frozen impossibility theorem.