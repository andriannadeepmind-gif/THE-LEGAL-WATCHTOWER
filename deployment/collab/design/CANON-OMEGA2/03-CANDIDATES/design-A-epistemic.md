# Design A — Epistemic First-Principles Architecture

**Team:** Architecture Team A (first principles)
**Entry point:** EPISTEMICS — "what IS legal knowledge and a legal conclusion, formally?"
**Scope:** Internal, single-firm, private legal-reasoning system (Greek order; EU/ECHR apply inside it).
**Claim-status discipline:** every substantive claim tagged THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN. Nothing here is IMPLEMENTED or DEMONSTRATED — this is a design; the strongest tags available to a design document are THEOREM (formally provable given stated definitions), DESIGN-ENTAILED (follows from the architecture if built as specified), HYPOTHESIS, and UNKNOWN.

---

## 0. Method note

I do not start from "what should the system do" (features) but from "what is the object the system manipulates" (the representation). If the representation is honest about how legal knowledge actually behaves, the architecture is largely forced by it; if the representation is dishonest (a single truth-world, facts asserted rather than proven, one interpretation privileged silently), no amount of engineering recovers correctness. This is the load-bearing commitment of Design A.

---

## 1. What legal knowledge and a legal conclusion ARE (formal core)

### 1.1 The negative theses (what a legal conclusion is NOT)

- **N1.** A legal conclusion is **not** a truth-value about the world. *(THEOREM, given the definitions of validity vs. truth in legal theory: norms are valid/invalid, not true/false; conclusions are their consequences.)*
- **N2.** A legal conclusion is **not** monotone: adding a premise (a new fact, a new authority, a later argument) can retract a previously supported conclusion. *(THEOREM — defeasibility is definitional of legal reasoning; classical monotone logic cannot model it without contradiction.)*
- **N3.** There is **not** one factual world. Facts are outputs of a procedure operating on evidence under burdens and standards of proof; multiple coherent factual constructions can be simultaneously admissible. *(THEOREM given the definition of proof-standards; a "found fact" is a procedural artifact, not an observation.)*
- **N4.** There is **not** a total order on authorities. `lex superior / specialis / posterior` are themselves defeasible meta-norms that can conflict (superior-general vs. inferior-special), and EU primacy + ECHR conformity impose cross-order constraints. *(THEOREM within the standard model of Greek/EU sources.)*
- **N5.** Discretion and open texture are **not** hidden gaps to be filled by guessing. They are irreducible choice points. *(THEOREM — Hart's open texture; any system that resolves them silently is fabricating.)*

### 1.2 The positive formal object

Define the atomic derivation object as a **Legal Argument**:

```
Arg ::= ⟨ id,
         claim        : NormativeProposition,      -- what is asserted to hold
         premises      : Set[Premise],              -- ordinary + assumption premises
         warrant       : InferenceRule,             -- the interpretive/legal step used
         authorities   : Set[AuthorityRef@interval],-- versioned sources relied on
         interpStance  : InterpretiveStance,        -- literal/systematic/teleological/
                                                    --   EU-conform/ECHR-conform/historical
         factualWorld  : WorldId,                   -- which construction of facts
         posture       : ProceduralState,           -- where in the state machine
         defeaters     : Set[Defeater],             -- rebutting / undercutting / undermining
         discretionRefs: Set[DiscretionNode] ⟩      -- explicitly marked irreducible choices
```

A **Legal Position** on a question `Q` is then not an answer but a structure:

```
Position(Q) = ⟨ AF, W, A, Λ ⟩
  AF : an argumentation framework (ASPIC+-style: strict + defeasible rules,
        preference ordering, attack relation derived from rebut/undercut/undermine)
  W  : a set of admissible factual worlds, each with an evidentiary support label
  A  : the authority lattice slice (partial order + defeasible priority meta-norms)
  Λ  : a labeling function  (Arg × Semantics × Stance × World × Posture)
         → { IN, OUT, UNDECIDED }
```

**Definition (Legal Conclusion, formal).** A legal conclusion for `Q` is a *labeling* `Λ` of `AF` relative to a fixed tuple `(order O, time t, interpretive stance s, factual world w, procedural posture p)`, together with the maximal set of *defeaters that would flip it*. The conclusion is **honest** iff every discretion node and open-texture penumbra reachable from an IN-labeled argument is surfaced as an explicit `UNKNOWN`/`CHOICE` rather than resolved. *(DESIGN-ENTAILED: this is the contract the kernel enforces.)*

**Corollary (why "one truth world" is wrong).** Since `Λ` is a function *of* `(w, s, ...)`, collapsing to a single world/stance is not a simplification but an unrecorded *decision* — it hides N3/N4/N5. *(THEOREM given the definition above.)*

### 1.3 What "superiority" can and cannot mean here (anti-circularity)

- Superiority is **defined operationally, not self-referentially**: for a fixed `(O,t,s,w,p)` and a fixed corpus, System X dominates System Y iff (a) every admissible argument Y produces, X also produces (recall of the argument space), and (b) X's produced arguments each pass the symbolic checker (soundness against the calculus), and (c) X correctly marks as UNKNOWN every point Y silently resolved. *(DESIGN-ENTAILED as a *measurable* relation; NOT a claim that this system achieves it — that would be EMPIRICAL and is untested.)*
- This is a *partial* order and explicitly refuses a global "best." Where discretion is irreducible, no system can be "more correct," only more *complete in surfacing the choice*. *(THEOREM.)*
- **No circular supremacy claim is made anywhere in this document.** The design's target is *maximal honest argument-space coverage under a checker*, which is falsifiable (§16).

---

## 2. Architectural consequence: the Propose/Check split (the master trust boundary)

The single most important structural decision, forced by §1:

> **The system separates UNTRUSTED generation of legal arguments from TRUSTED validation of them.** LLMs and agents *propose* arguments, interpretations, factual constructions, and defeaters. A small symbolic **Epistemic Kernel** *checks* each proposed derivation against the argument calculus and the versioned authority store, and computes labelings. No LLM output ever enters a conclusion without passing the checker.

*(DESIGN-ENTAILED; also mandated by CLAUDE.md: "κανένα LLM στο trusted path", "τίμια άγνοια".)*

Why this makes the TCB small: the kernel does not need to *know law*; it needs to (i) verify that a proposed argument's warrant is an instance of an admitted inference rule, (ii) verify every `AuthorityRef@interval` resolves to a byte-identical versioned source, (iii) compute attack relations and labelings by a fixed algorithm, (iv) refuse to output a conclusion over any argument touching an unresolved discretion node without an explicit human/authority decision record. All four are decidable, testable, and free of natural-language understanding. *(THEOREM for (iii) given finite AF; DESIGN-ENTAILED for (i),(ii),(iv).)*

**The load-bearing honesty caveat (never hidden as an engineering detail):** proof-checking an argument's *form* is **not** proof of the *correctness of the natural-language formalization* that produced its premises. The kernel guarantees "this conclusion follows from these formalized premises under this calculus"; it does **not** guarantee "these premises faithfully render the statute/【evidence】." That gap is real, irreducible, and is handled by §7.3 (dual-formalization + human ratification), never claimed away. *(THEOREM — this is the Achilles heel of all "verified" legal AI and must stay visible.)*

---

## 3. Trust boundaries

Boundaries ordered from most-trusted (inside) to least:

1. **B0 — Epistemic Kernel & Authority Store integrity** (the TCB, §4). Deterministic, symbolic, no network, no LLM.
2. **B1 — Control Plane / Policy Enforcement Point.** Mediates every cross-boundary call; enforces matter isolation, ethical walls, egress. Trusted for *mediation*, not for reasoning.
3. **B2 — Human Authority Points.** Lawyers/partners who ratify formalizations, exercise discretion, approve publication. Trusted as *authority*, audited as *actors* (insider-threat model, §11).
4. **B3 — Agent Orchestration Layer.** Untrusted-for-truth, trusted-for-scheduling; runs the multi-agent topology.
5. **B4 — Model/LLM Proposers.** Fully untrusted for truth. Sandboxed, no direct store write, no egress.
6. **B5 — Retrieval / Corpus ingestion.** Untrusted; every retrieved item is provenance-stamped and treated as a *proposal of an authority*, checked before it can be an `AuthorityRef`.
7. **B6 — Vendors / external models / external data.** Adversarial by assumption (§11 vendor risk).
8. **B7 — Publication Gateway boundary** (§14). The *only* egress path to any public artifact; fail-closed.

Rule: **a boundary crossing is only legal through the Control Plane (B1), which attaches a signed capability token scoping the call to one matter, one purpose, one data class.** *(DESIGN-ENTAILED.)* There is exactly one enforcement seat per concept (CLAUDE.md "μία έδρα ανά έννοια"): one egress enforcer, one isolation enforcer, one publication gate.

---

## 4. TCB — what is trusted and why it stays small

**In the TCB:**

- **T1. Epistemic Kernel:** argument well-formedness checker, attack-relation computer, labeling engine (grounded + preferred + a legally-tuned semantics), discretion/open-texture gate. Pure function of its inputs; no I/O beyond reading the sealed store. *(Target size: small; the reason it *can* be small is §2 — it does not understand law, it checks form.)*
- **T2. Versioned Authority Store (integrity layer only):** content-addressed, append-only, Merkle-rooted store of norms/cases/facts with validity intervals. Trusted for *integrity and temporal resolution*, not for *interpretation*. *(DESIGN-ENTAILED.)*
- **T3. Reference Monitor / Capability verifier** inside B1: checks every capability token's signature and scope. Classic reference-monitor properties (complete mediation, tamper-evident, small enough to verify). *(DESIGN-ENTAILED; property target, not a proof.)*
- **T4. Publication Gateway decision core** (the fail-closed predicate, §14) — but *not* the review agents feeding it.
- **T5. Audit/Provenance ledger writer:** append-only, hash-chained.

**Explicitly NOT in the TCB:** any LLM, any agent, any retrieval component, any natural-language-to-formal translator, any ranking/heuristic, the corpus itself, vendor infrastructure, the UI.

**Why small-is-possible (the argument, not a slogan):** every component that requires "understanding" is pushed to the untrusted side and reduced to *proposals that the TCB checks by form or by cryptographic identity*. The TCB's obligations are all decidable and independently testable. *(DESIGN-ENTAILED. The claim "the TCB is actually small when built" is HYPOTHESIS until measured, §16.)*

**Honest limit:** T2's *temporal/authority model* (which norm was in force when, how repeal/amendment chains resolve) is genuinely complex and is the largest honest risk to "small TCB." It is in scope and flagged (§16-W3).

---

## 5. Dataflow

```
                          ┌──────────────── B7 Publication Gateway (fail-closed) ─────────────┐
                          │   privilege→DLP→redaction→authority-validate→human→receipt        │
                          └───────────────────────────▲──────────────────────────────────────┘
                                                       │ (only path out)
   Corpus/Evidence ──► [B5 Ingest] ──► provenance-stamped PROPOSAL
        (B6 external)        │                         │
                             ▼                         │
                    [B1 Control Plane / PEP]  ◄────────┼──────── capability tokens ────────┐
                       │  complete mediation           │                                   │
        ┌──────────────┼───────────────────────────────┼──────────────────┐               │
        ▼              ▼                                ▼                  ▼               │
  [B4 Proposer LLMs] [B3 Agents] ──proposals──► [B0 EPISTEMIC KERNEL] ──► Positions       │
   (argue, interpret,  (orchestrate)   (args,      check form+authority+    (AF,W,A,Λ)     │
    find defeaters)                     worlds)     labeling; gate          + defeaters    │
        │                                           discretion                │            │
        └── no store write, no egress ──┐                                     ▼            │
                                        ▼                              [B2 Human Authority]─┘
                              [T2 Versioned Authority Store] ◄── ratified formalizations,
                              [T5 Audit/Provenance ledger]        discretion decisions
```

Invariants on the dataflow:
- **D1.** Nothing reaches T2 (store) as an `AuthorityRef` or a ratified formalization except through the Kernel's checker AND a B2 human ratification event. *(DESIGN-ENTAILED.)*
- **D2.** No data leaves the trust perimeter except through B7. *(DESIGN-ENTAILED; enforced at B1 egress seat.)*
- **D3.** Every arrow is logged to T5 with matter-id, purpose, capability-token-id, content hash. *(DESIGN-ENTAILED.)*

---

## 6. Control plane & agent topology

### 6.1 Control plane (B1)

- **Capability-based, not ambient-authority.** Every agent/model action requires an unforgeable, signed, scoped capability (matter, purpose, data-class, TTL, egress=false by default). *(DESIGN-ENTAILED.)*
- **Complete mediation:** no side channel; agents cannot open sockets, read the store, or call each other except through B1. Enforced by sandbox (network-namespace deny-all + brokered IPC). *(DESIGN-ENTAILED; property target.)*
- **Deterministic replay hooks:** the control plane records the exact inputs (model version, prompt, seed where available, retrieved doc hashes) so a run is replayable (§8). *(DESIGN-ENTAILED; note LLM nondeterminism caveat in §8/§16-W5.)*

### 6.2 Agent topology (all of B3/B4 are UNTRUSTED proposers)

Adversarial-by-construction, per CLAUDE.md's internal-adversary protocol:

- **Proposer swarm** (per interpretive stance): one agent-cluster per stance (literal, systematic, teleological, EU-conform, ECHR-conform, historical). Each independently builds arguments for/against `Q`. Diversity is structural, not stylistic. *(DESIGN-ENTAILED.)*
- **Fact-world constructors:** agents build *distinct* coherent factual worlds from the same evidence under different burden/standard allocations. Output = labeled `W`. *(DESIGN-ENTAILED.)*
- **Adversary/Breaker agents (mandatory, fresh context, no access to the proposer's reasoning):** two axes required by CLAUDE.md [0047]-style protocol — (α) attack the legal model/security (find a defeater, a missed authority, a preclusion); (β) hunt mediocrity (patches, wrappers, duplicated seats, silent fallbacks, test-tautologies). Every finding must be closed at its seat, refuted with proof, or recorded as a residue with a death-phase. *(DESIGN-ENTAILED; this is a control on the *design process itself*, not only runtime.)*
- **Synthesis/Marshalling agent:** does NOT decide truth; it only assembles proposals into a candidate `AF` for the Kernel and drafts the human-facing brief. *(DESIGN-ENTAILED.)*
- **Kernel (B0):** the only component that assigns labels.

Topology principle: **generation is many, diverse, and adversarial; adjudication is one, symbolic, and small.** *(DESIGN-ENTAILED.)*

---

## 7. Epistemic representation (the heart)

### 7.1 Norms

`Norm = ⟨id, antecedent, deonticConsequent, validityInterval, jurisdiction, rank, provenance⟩`, rank in the source hierarchy (Constitution > EU primary/《primacy》 > ECHR-as-incorporated > statute > regulation > soft-law), with amendment/repeal as explicit edges producing new versions rather than mutation. *(DESIGN-ENTAILED.)* Computational-law norms (deterministic conditions — deadlines, thresholds, arithmetic) are compiled to *strict rules*; open-textured norms to *defeasible rules with an attached penumbra marker*. *(DESIGN-ENTAILED.)*

### 7.2 Conflicting authorities

Represented as a **partial order + defeasible priority meta-norms** (`lex superior/specialis/posterior`), themselves defeasible and able to conflict. Conflict resolution is *not* pre-computed into a single winner; the Kernel emits the *set* of resolutions each meta-norm ordering yields, and where the meta-norms themselves conflict it emits `UNDECIDED` + the competing orderings. EU primacy and the duty of conforming interpretation are cross-order attack/support edges. *(DESIGN-ENTAILED. THEOREM: total-ordering here would violate N4.)*

### 7.3 Competing interpretations & the formalization-gap control

Each interpretation is a first-class argument with an explicit `InferenceRule` warrant and a stance tag. **No stance is privileged by default.** The dominant literal/systematic/teleological readings are all carried; the system's job is to present the competition, not to pick unless a human/authority does.

**The formalization gap (never hidden):** turning statute/evidence text into `premises` is an untrusted NL→formal step. Controls:
- **Dual independent formalization:** two disjoint proposer clusters formalize the same source; a diff is computed; disagreement is surfaced, never silently merged. *(DESIGN-ENTAILED.)*
- **Human ratification (B2):** a formalization becomes an `AuthorityRef` premise only after a lawyer ratifies it; the ratification is content-hashed into T2 with the ratifier's identity. *(DESIGN-ENTAILED.)*
- **Back-translation check:** the Kernel can render a formal premise back to controlled natural language for the ratifier; mismatch is a blocking finding. *(HYPOTHESIS on fidelity of back-translation — flagged §16-W2.)*

### 7.4 Alternative factual worlds under evidence uncertainty

`World = ⟨id, factSet, evidenceSupport, burdenAllocation, standardOfProof, presumptions⟩`. Multiple worlds coexist; each argument is indexed by the world it lives in. Evidentiary support is represented as a *structured record of admissible evidence and its weight-under-standard*, **not** a single scalar probability — because standards of proof (πιθανολόγηση / πλήρης απόδειξη) are qualitative thresholds, not calibrated probabilities. Where a probabilistic model is used at all, it is a *proposer heuristic* for ranking worlds, never a truth-claim, and never enters the trusted labeling. *(DESIGN-ENTAILED. Marking this scalar-refusal is important: pretending burdens are Bayesian would be a dishonest formalization.)*

### 7.5 Procedure as state machine

`Matter` carries a `ProceduralState` in an explicit automaton (deadlines, admissible actions, preclusions, appeal windows). Preclusion edges *remove* argument availability (a right not timely exercised is `OUT` by posture, regardless of merits). Deadlines are strict-rule computations with jurisdiction-specific calendar rules; they generate hard alerts (§ correctness requirement 5). *(DESIGN-ENTAILED.)*

### 7.6 Discretion as irreducible

`DiscretionNode` is a typed choice point (judicial discretion, proportionality balancing, equitable adjustment). The Kernel **refuses to collapse it**: any conclusion whose derivation passes through an unresolved discretion node is emitted as `CHOICE-DEPENDENT`, enumerating the options and the reasons on each side, and requires a B2 human decision (recorded) before it can be treated as settled *for that matter*. Proportionality is represented as a structured multi-factor argument (suitability/necessity/stricto-sensu) whose *balancing weight* is the discretion node — the *structure* is computed, the *weighting* is human. *(DESIGN-ENTAILED; THEOREM that it cannot be fully computed given N5.)*

---

## 8. Reasoning modes & memory/versioning

### 8.1 Four reasoning modes, each with its own trusted treatment

- **Computational law** (deadlines, thresholds, tax/interest arithmetic): strict rules, fully decidable, Kernel-checked, exact. *(DESIGN-ENTAILED; correctness here is THEOREM-grade given correct formalization.)*
- **Open texture:** defeasible rules + penumbra markers; Kernel never resolves the penumbra, surfaces it. *(DESIGN-ENTAILED.)*
- **Precedent:** case-based reasoning as argument-from-analogy with explicit factor/dimension model (HYPO/CATO-style) — similarity is an *argument with a warrant and distinguishing defeaters*, not a metric lookup. Retrieval proposes candidate cases; the analogy argument is checked for form and its distinguishers surfaced. *(DESIGN-ENTAILED.)*
- **Evidence:** world-construction under burdens/standards (§7.4); reasoning about admissibility and sufficiency, not about "what really happened." *(DESIGN-ENTAILED.)*

### 8.2 Memory / versioning — the twin requirement

Two distinct operations, both first-class:

- **Same-version replay (auditability):** given a matter-output, reproduce the *exact* Position by pinning: authority-store Merkle root, model versions, prompts, retrieved-doc hashes, kernel version, and all human decision records. The Kernel is deterministic, so *given identical proposals* the labeling is bit-reproducible. *(DESIGN-ENTAILED for the Kernel; the *proposals* are only reproducible up to LLM determinism — see caveat below.)*
- **Current-version re-evaluation (law changed / better argument found):** re-run the same `Q` against the *current* authority-store root and current models; produce a **diff of Positions** (what flipped, which new defeater/authority caused it, which deadlines this newly implicates). This is how the firm learns that a past matter's conclusion is now stale. *(DESIGN-ENTAILED.)*

Everything is content-addressed and append-only (T2, T5): law-as-of-time is a *view* over versioned norms, never a mutated record. *(DESIGN-ENTAILED.)*

**Caveat (not hidden):** LLM proposer nondeterminism means same-version replay reproduces the *checked conclusion and its full derivation* exactly (because the derivation is stored and re-checkable), but does **not** guarantee an LLM re-run yields the identical *search* over arguments. We therefore replay from **stored proposals**, not by re-sampling models. Re-sampling is a separate "did we miss arguments" audit. *(DESIGN-ENTAILED; the distinction is essential and is flagged §16-W5.)*

---

## 9. Security model

- **Matter isolation:** each matter is a cryptographic compartment; capability tokens are matter-scoped; cross-matter reads require an explicit, logged, human-authorized bridge (for conflicts-checking there is a *separate* minimal-disclosure conflicts service that sees only conflict-relevant identifiers, not matter contents). *(DESIGN-ENTAILED.)*
- **Ethical walls / Chinese walls:** enforced at B1 as deny-by-default ACLs over matter compartments; wall breaches are structurally impossible (no capability minted) rather than merely policy-forbidden — per CLAUDE.md "εξάλειψη της κλάσης σφάλματος", make the error structurally impossible, not prohibited. *(DESIGN-ENTAILED.)*
- **Insider threat:** every human authority action (ratification, discretion, publication approval, cross-matter bridge) is hash-chained in T5 with identity, is two-person for high-stakes acts (publication, wall bridges), and is subject to anomaly review. No single insider can exfiltrate or publish alone. *(DESIGN-ENTAILED. Note: this *reduces*, does not *eliminate*, insider risk — see §16-W6.)*
- **Egress control:** one egress seat (B1). Default egress=false on all tokens. The *only* capability that can produce an external artifact is minted by B7. Proposer LLMs run air-gapped from the network (local weights preferred; if a vendor model is used it is behind a brokered, content-inspected, matter-scoped proxy with no raw-data egress). *(DESIGN-ENTAILED.)*
- **Vendor / model risk:** external models are B6-adversarial. Mitigations: prefer self-hosted weights; if external, never send privileged raw content — send *derived, minimized, matter-agnostic* queries where possible, through the DLP inspector; treat all model output as untrusted proposals checked by the Kernel; pin and hash model versions; assume the vendor is a potential exfiltration and poisoning channel and design so that a fully-malicious model *cannot* cause a wrong *conclusion* (only a wrong *proposal*, which the Kernel rejects) nor an *egress* (no token). *(DESIGN-ENTAILED. Residual: a malicious model can *omit* a valid argument — a completeness attack, not a soundness attack — flagged §16-W4.)*
- **Data poisoning of corpus:** ingested authorities are provenance-stamped and must be validated against authenticated official sources before becoming `AuthorityRef`s; a poisoned document can at worst become a *rejected proposal*. *(DESIGN-ENTAILED, contingent on authenticated-source validation being real — §16-W3.)*

---

## 10. Failure containment

- **Fail-closed everywhere at trust boundaries:** if the Kernel cannot check, it emits `UNKNOWN`/BLOCKING, never a guessed conclusion (CLAUDE.md "τίμια άγνοια", "0 λάθος"). If B1 cannot verify a capability, it denies. If B7 cannot complete privilege/DLP checks, it does not publish. *(DESIGN-ENTAILED.)*
- **Blast radius = one matter:** compartmentalization confines any single failure/compromise to a matter. *(DESIGN-ENTAILED; contingent on isolation being sound.)*
- **No silent fallback:** a degraded mode is a *declared* mode with a visible banner and restricted capabilities, never a quiet substitution — CLAUDE.md forbids silent fallbacks and patches. *(DESIGN-ENTAILED.)*
- **Deadline safety:** the procedural state machine's deadline computations are on the strict/decidable path and are redundantly computed; a missed-deadline risk raises a hard, non-suppressible alert to named humans. *(DESIGN-ENTAILED; correctness requirement 5.)*
- **Contradiction handling:** an unresolved contradiction (e.g., two meta-norm orderings, a formalization diff) stays BLOCKING and visible; it is never averaged away. *(DESIGN-ENTAILED, per brief.)*

---

## 11. Human authority points (where humans are load-bearing, by design)

Humans are not "in the loop" decoratively; specific decisions are *reserved to humans* because they are irreducible (N5) or high-stakes:

1. **Formalization ratification** (§7.3) — a premise is not trusted until a lawyer signs it.
2. **Discretion exercise** (§7.6) — CHOICE-DEPENDENT conclusions require a recorded human choice, per matter.
3. **Cross-matter / wall bridges** — two-person authorization.
4. **Publication approval** (§14) — two-person, at the gateway.
5. **Phase merges / system self-change** (§13) — only the creator/partner merges; nothing self-merges (CLAUDE.md).

Each is captured as a signed, hash-chained decision record in T5, making authority auditable and non-repudiable. *(DESIGN-ENTAILED.)*

---

## 12. Publication boundary (fail-closed Publication Gateway, B7)

The **only** path from private to public. A publication candidate (e.g., a codified statute/case-law text intended for release) passes an ordered, fail-closed pipeline; any stage's failure or timeout aborts with no release:

1. **Privilege review** — automated classifier *proposes*, human confirms no privileged/work-product content. *(Human is authority; classifier is untrusted proposer.)*
2. **Confidentiality / DLP** — deterministic scan for client identifiers, matter fingerprints, strategy traces, model traces, internal reasoning. Deny on any hit. *(DESIGN-ENTAILED.)*
3. **Redaction** — applied and re-scanned; redaction is *additive-only* (cannot un-redact).
4. **Authority validation** — every legal proposition in the candidate must resolve to a checked `AuthorityRef@interval` in T2 (no unsourced legal claim may be published). *(DESIGN-ENTAILED — enforces "no fabrication" on public output.)*
5. **Human approval** — two named partners.
6. **Immutable release receipt** — hash of the exact released bytes + the authority-store root + approver identities, appended to T5 and to a public-facing tamper-evident log.

Properties: **fail-closed** (default: do not publish), **complete-mediation** (no other egress), **immutable receipt** (non-repudiation, reproducibility of "what was released and on what legal basis"). *(DESIGN-ENTAILED.)* Only *final outputs* traverse it; all matters/strategies/traces/memories are structurally barred (they never obtain an egress capability). *(DESIGN-ENTAILED, per conditions 2–3.)*

---

## 13. Self-improvement WITHOUT self-merge

The system may improve *its own* rules, formalizations, prompts, kernel semantics, and proposer models — but it can never *merge* its own change.

- **Proposal:** an improvement (new inference rule, corrected formalization, better analogy model, kernel semantic refinement) is produced as a **candidate versioned artifact** in an isolated branch/worktree, never touching the live TCB. *(DESIGN-ENTAILED.)*
- **Adversarial gauntlet:** the internal Breaker agents (fresh context, no access to the proposer's rationale) attack it on both axes (soundness/security; mediocrity/patch/wrapper/duplicate-seat). Findings closed-at-seat or recorded as residue-with-death-phase. *(DESIGN-ENTAILED; CLAUDE.md [0047].)*
- **Differential proof obligations:** the candidate must (a) not change any previously-checked conclusion without an explicit, human-reviewed *regression diff* of Positions across a fixed benchmark of matters; (b) preserve all TCB invariants (fail-closed, complete mediation, discretion-gate); (c) come with the numbers (gates/tests/audits). *(DESIGN-ENTAILED.)*
- **Human merge only:** a partner issues an explicit "εγκρίνω X" per phase; the merge is a two-person, hash-chained authority event; `deployment/self` history is the record. Nothing opens itself. *(DESIGN-ENTAILED; CLAUDE.md "μόνο ο δημιουργός συγχωνεύει".)*
- **Kernel-change caution:** changes to the TCB (T1/T3/T4 predicate) get the strictest treatment — they must be accompanied by a re-proof of the boundary invariants and are the only changes that can require re-baselining replay. *(DESIGN-ENTAILED.)*

The self-improvement loop is thus **generate-and-check applied to the system itself**: the system proposes; humans + adversaries + the differential harness check; only humans merge. *(DESIGN-ENTAILED.)*

---

## 14. What this architecture buys, stated honestly (no self-grading)

- It makes a class of errors **structurally impossible** rather than forbidden: unsourced conclusions (Kernel refuses), silent single-world/single-stance collapse (representation forbids), ethical-wall breach (no capability minted), un-reviewed publication (no egress token), self-merge (no self-authority). *(DESIGN-ENTAILED.)*
- It **cannot** guarantee the formalizations are faithful, the argument search is complete, or that discretion was exercised wisely. Those are HYPOTHESIS/UNKNOWN and handled by human authority + adversarial completeness audits, not by the machine's say-so.
- **No supremacy claim is asserted.** The design targets *maximal honest coverage of the admissible argument space under a sound checker, with all irreducible choices surfaced*. Whether an instantiation achieves dominance over a given human team or AI (§1.3) is EMPIRICAL and untested here.

---

## 15. Open BLOCKING contradictions carried forward (not resolved by fiat)

- **C1.** "0 λάθος / no fabrication" (CLAUDE.md) vs. the formalization gap (§2, §7.3): the machine cannot *guarantee* zero formalization error; it can only *contain* it behind human ratification. This tension is real and remains BLOCKING for any claim of machine-guaranteed correctness. Resolution stance: the guarantee is *conditional* ("sound given ratified premises"), stated as such, never absolute. *(THEOREM that an unconditional guarantee is impossible here.)*
- **C2.** Completeness of argument search is undecidable in general; "maximal coverage" is a goal, not a proven property. Stays open. *(THEOREM.)*
- **C3.** Determinism/replay vs. LLM proposers (§8 caveat) — resolved by replaying stored proposals, but this weakens "re-derive from scratch" to "re-check what was derived." Open as a limitation.

---

## 16. FALSIFIABLE WEAKNESSES (where Design A can fail, and how an evaluator detects it)

- **W1 — The Kernel is only as sound as its calculus.** If the ASPIC+/labeling semantics chosen mis-models Greek legal defeat (e.g., wrong handling of conforming interpretation as attack vs. support), the Kernel will confidently mislabel.
  *Detection:* curated benchmark of decided cases with known argument-defeat structure; measure labeling disagreement vs. expert annotation. A mismatch rate > 0 on *strict* items falsifies "sound." *(EMPIRICAL test; untested here.)*
- **W2 — Formalization-gap / back-translation infidelity (§2, §7.3).** The whole "trusted conclusion" rests on premises a human ratified; if back-translation is misleading or ratifiers rubber-stamp, garbage premises pass.
  *Detection:* seed known-wrong formalizations; measure ratifier catch-rate; measure back-translation semantic drift via independent expert re-formalization. Low catch-rate falsifies the ratification control. *(EMPIRICAL.)*
- **W3 — Authority/temporal model complexity threatens "small TCB" and poisoning-resistance (§4, §9).** If "which norm in force when" and "authenticated official source validation" are not actually watertight, poisoned/stale authorities enter as trusted refs.
  *Detection:* red-team the ingest with forged/amended/repealed sources and edge-case amendment chains; any that become a trusted `AuthorityRef` falsifies the integrity claim. *(EMPIRICAL.)*
- **W4 — Completeness attack (malicious or merely weak proposers *omit* a decisive argument).** The Kernel checks soundness of what it's given; it cannot conjure a missing winning argument. A vendor model could silently omit; an honest one could just miss.
  *Detection:* differential-coverage audit — run independent, differently-built proposer stacks and human experts on the same `Q`; any admissible argument found by one but absent from the delivered Position is a coverage miss. Nonzero, high-severity misses falsify "maximal coverage." *(EMPIRICAL; this is the design's most serious residual, per §1.3(a).)*
- **W5 — Replay is over stored proposals, not re-derivation (§8).** An evaluator who expected "re-run reproduces the reasoning" finds only "re-check reproduces the labeling." If a bug lived in the (untrusted) proposer, replay won't resurface it.
  *Detection:* independent re-derivation runs compared against stored proposals; divergence in the *argument set* (not just labels) exposes proposer nondeterminism/bugs the replay hides. *(EMPIRICAL.)*
- **W6 — Insider threat is reduced, not eliminated (§9).** Two-person controls and audit deter but do not stop collusion of two authorized partners.
  *Detection:* audit-log analysis + segregation-of-duties red team; a successful two-party exfiltration/publication in a drill falsifies "cannot publish alone" at n=2. *(EMPIRICAL.)*
- **W7 — Discretion-gate can be gamed into a rubber stamp.** If humans routinely approve CHOICE-DEPENDENT nodes without real deliberation, the honesty guarantee is cosmetic.
  *Detection:* measure time-to-approve and reasons-recorded quality on discretion nodes; near-instant, empty-reason approvals falsify "discretion honestly surfaced." *(EMPIRICAL.)*
- **W8 — Kernel-in-TCB single-point epistemic risk.** A subtle bug in the labeling engine mislabels *everything* uniformly and invisibly (unlike a proposer bug, which is local).
  *Detection:* N-version the labeling engine (independent implementations of the semantics) and diff outputs on the full benchmark; any divergence localizes a kernel bug. Absence of N-version diffing is itself a detectable design gap. *(EMPIRICAL / DESIGN gap if omitted.)*
- **W9 — Performance/latency vs. deadline correctness.** The adversarial many-agent generation is expensive; if a Position for a deadline-critical `Q` cannot be produced in time, fail-closed means "no answer," which can itself cause a missed deadline.
  *Detection:* load/latency tests against real procedural clocks; a class of deadlines the pipeline cannot meet falsifies "reliability is a correctness property is satisfied." *(EMPIRICAL; correctness requirement 5.)*
- **W10 — The design assumes the argument-representation is expressive enough for Greek/EU/ECHR reasoning.** If real doctrines (e.g., proportionality, conforming interpretation, EU primacy interplay, constitutional review) don't fit the AF+worlds model, the honesty is illusory.
  *Detection:* attempt full formalization of a battery of hard, doctrine-heavy decided cases; representational failures (things that can only be shoe-horned or dropped) falsify expressiveness. *(EMPIRICAL; this is the deepest falsifier — the representation itself.)*

---

## 17. One-line self-location

Design A's bet: **honesty of representation (defeasible arguments over labeled worlds, discretion irreducible) + a small symbolic checker + generate/check separation** produces a system whose *errors are structurally contained and whose ignorance is declared*, at the cost of leaving faithful formalization, argument completeness, and wise discretion to audited humans — and it says so, in the tags, rather than claiming to have solved them.
