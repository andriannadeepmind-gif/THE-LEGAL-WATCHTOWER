# DESIGN C — THE INSTITUTION

**Architecture Team C — First Principles from the Question: "What makes an elite law firm elite as an ORGANIZATION?"**

Entry point: derive the target system as the *ideal digital legal institution*, then specify its technical architecture, governance, and failure culture. This document designs from first principles only; it opens no prior project design work.

---

## CLAIM-STATUS LEGEND (mandatory discipline)

Every substantive claim below carries exactly one tag:

- **THEOREM** — provable in a stated formal model (and I state the model's gap to reality).
- **DESIGN-ENTAILED** — follows necessarily *if* the system is built as specified; not yet built.
- **IMPLEMENTED** — code exists in this project. (Almost nothing here is; this is a design.)
- **DEMONSTRATED** — shown working end-to-end. (Nothing here is.)
- **EMPIRICAL** — supported by measurement. (Nothing here is.)
- **HYPOTHESIS** — plausible, motivated, but untested.
- **UNKNOWN** — openly unresolved.

Two prohibitions I hold throughout: **proof-checking a formal object is NOT correctness of the natural-language formalization it claims to encode** (the formalization gap is always named). **Model access is NOT idea inclusion** (that a model *can read* an authority does not mean the reasoning *used* it).

---

## PART 0 — THE DERIVATION: FROM INSTITUTION TO ARCHITECTURE

An elite law firm is not elite because its individual lawyers are individually the smartest. It is elite because of **organizational properties that survive the turnover, error, and bounded rationality of every individual member**. The following ten mechanisms are, on inspection, what "institutional excellence" decomposes into. Each maps to an architectural obligation, and — this is the first-principles payoff — for each I ask the CLAUDE.md question: *is there a strictly superior conception where the error class is made structurally impossible rather than merely guarded against?*

| # | Institutional mechanism | What it actually buys | Architectural obligation | Structural upgrade available? |
|---|---|---|---|---|
| 1 | **Division of expertise** (practice groups) | Specialization beats generalism per-domain | Typed specialist agents with declared competence boundaries | Partial — competence can be *declared and checked*, not merely trusted |
| 2 | **Review chains** (associate→senior→partner) | Error caught before it leaves | Mandatory multi-stage verification with independent context | Yes — reviewer independence can be *enforced by construction*, not by norm |
| 3 | **Institutional memory** (know-how, matter files) | The firm knows more than any lawyer | Versioned, queryable, provenance-carrying memory | Yes — perfect recall + citation-of-source is mechanizable |
| 4 | **Quality control** (before it goes out) | Reputation and malpractice protection | Fail-closed output gate | Yes — a gate can be *fail-closed by construction* |
| 5 | **Ethical walls** (conflicts, info barriers) | Legal/ethical duty; client trust | Matter isolation as a hard boundary | Yes — isolation can be a *capability property*, not a policy |
| 6 | **Partner judgment** (the signature) | An accountable human bears the risk | Named human authority points; no autonomous merge/release | **No** — this is irreducible; the design must *preserve* it, not replace it |
| 7 | **Apprenticeship / learning loops** | The firm improves across matters | Self-improvement mechanism | Partial — improvement without self-merge |
| 8 | **Confidentiality / privilege** | The sacred boundary | Default-private everything; egress control | Yes — private-by-default is the ground state |
| 9 | **Conflict checking** (before intake) | Duty; avoids disqualification | Pre-matter conflict scan against memory | Yes — mechanizable and auditable |
| 10 | **Failure culture** (post-mortems) | The firm gets safer over time | Blameless incident capture + phase-death of error classes | Yes — near-miss capture can be mandatory and structural |

**The central design thesis (DESIGN-ENTAILED):** The digital institution's superiority, where it exists at all, comes from converting *norms enforced by human diligence* (mechanisms 2, 3, 4, 5, 9, 10) into *properties enforced by construction*. Where a mechanism is irreducibly human (mechanism 6), the design must **make that human authority load-bearing and un-bypassable**, not automate it away. A design that automates away the partner's signature has not built a superior institution; it has built an unaccountable one. This is a trade-off, stated openly, not hidden as an engineering detail.

**Non-goal disclaimer (UNKNOWN→HYPOTHESIS):** "Superiority over any AI system or human legal team given equal data and procedural position" is a *goal*, not a claim. I make no supremacy assertion. The design gives structural reasons to expect advantage on specific, enumerable axes (recall, review independence, isolation guarantees, auditability). It gives *no* structural reason to expect advantage on the axis that most decides real cases — **judgment under genuine open texture** — and I mark that as a permanent frontier, not a solved problem.

---

## PART 1 — TRUST BOUNDARIES

The institution is drawn as a set of nested trust rings. A subject in an outer ring cannot cause an effect in an inner ring except through a **single named mediator** with a checkable contract. This is the "one door per concept" principle applied to trust.

```
┌────────────────────────────────────────────────────────────────────────┐
│ RING 4 — THE WORLD (untrusted): public statutes, case-law feeds,         │
│          opposing filings, third-party data, vendor model weights,       │
│          the internet. EVERYTHING here is adversarial input.             │
│   ┌──────────────────────────────────────────────────────────────────┐  │
│   │ RING 3 — INGESTION & REASONING PLANE (untrusted-by-default):      │  │
│   │   all LLM agents, retrieval, drafting, analysis. Powerful but     │  │
│   │   NEVER trusted. Treated as brilliant, unvetted lateral hires     │  │
│   │   who may be wrong, captured, or adversarial.                     │  │
│   │   ┌────────────────────────────────────────────────────────────┐ │  │
│   │   │ RING 2 — THE RECORD (trusted for integrity, not judgment):  │ │  │
│   │   │   append-only matter ledger, authority store, provenance    │ │  │
│   │   │   graph, memory versions. Trusted to be TAMPER-EVIDENT and  │ │  │
│   │   │   COMPLETE, not to be RIGHT.                                 │ │  │
│   │   │   ┌──────────────────────────────────────────────────────┐  │ │  │
│   │   │   │ RING 1 — THE TCB (small, trusted): policy kernel,     │  │ │  │
│   │   │   │   capability broker, isolation monitor, gate          │  │ │  │
│   │   │   │   evaluators, human-authority verifier, crypto root.  │  │ │  │
│   │   │   │   ┌────────────────────────────────────────────────┐  │  │ │  │
│   │   │   │   │ RING 0 — NAMED HUMANS (the partners): the only │  │  │ │  │
│   │   │   │   │   source of merge/release/authorization         │  │  │ │  │
│   │   │   │   │   consent. Root of accountability.              │  │  │ │  │
│   │   │   │   └────────────────────────────────────────────────┘  │  │ │  │
│   │   │   └──────────────────────────────────────────────────────┘  │ │  │
│   │   └────────────────────────────────────────────────────────────┘ │  │
│   └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

**Key inversion from a naive design (DESIGN-ENTAILED):** the reasoning plane (Ring 3), where all the "intelligence" lives, is *outside* the trust boundary of the record and the policy kernel. The smartest components are the least trusted. This is exactly how an elite firm treats a brilliant new lateral: enormous capability, zero unsupervised authority until the work is on the record and reviewed. A model's fluency is never evidence of its trustworthiness.

**Trust-boundary invariants:**

- **INV-1 (DESIGN-ENTAILED):** No Ring 3 component holds a capability to write Ring 2 directly. It emits *proposed records* to the capability broker (Ring 1), which validates provenance/format and commits. Rationale: a captured or hallucinating agent cannot corrupt the record, only propose to it.
- **INV-2 (DESIGN-ENTAILED):** No Ring 3 or Ring 2 component can cause egress to Ring 4. Only the Publication Gateway (Ring 1) can, and only after Ring 0 consent. Confidentiality is the ground state; egress is the rare, gated exception.
- **INV-3 (THEOREM, in the capability model of Part 3; formalization gap named there):** Cross-matter information flow requires a capability neither the source nor the destination agent possesses; therefore no agent action can breach an ethical wall. The theorem holds in the model; whether the *deployed* isolation monitor faithfully implements the model is DESIGN-ENTAILED at best and must be tested (see Falsifiable Weaknesses).

---

## PART 2 — THE TCB (TRUSTED COMPUTING BASE): WHAT IS TRUSTED AND WHY IT IS SMALL

The TCB is the set of components whose failure can silently violate a security or correctness invariant. The design's central security bet is: **the TCB must be small, must contain no LLM, and must be independently reviewable by a single competent human in a bounded time.**

**What is IN the TCB (Ring 1 + the integrity guarantees of Ring 2):**

1. **Policy Kernel** — a deterministic, non-LLM decision engine. Given (subject, action, object, context) it returns permit/deny against explicit, versioned policy. It is the *only* authority on capabilities. (DESIGN-ENTAILED: deterministic ⇒ replayable ⇒ auditable.)
2. **Capability Broker** — mediates every write to the record and every cross-boundary request. Holds no policy of its own; asks the kernel.
3. **Isolation Monitor** — enforces matter/ethical-wall partitioning of memory, compute, and message routing.
4. **Gate Evaluators** — the fail-closed checkers (privilege, DLP/confidentiality, authority validation, redaction verification) used by the Publication Gateway and internal quality gates. Deterministic checks over declared predicates; where a check is inherently probabilistic (e.g., PII detection), the gate treats "uncertain" as "deny" (fail-closed).
5. **Human-Authority Verifier** — validates that a merge/release/authorization carries a cryptographically valid, non-replayable consent token from a Ring 0 human bound to *this specific artifact and version*.
6. **Cryptographic root & append-only log substrate** — hash-chained, tamper-evident record integrity.

**What is DELIBERATELY OUT of the TCB:**

- **All LLMs / all agents.** (Rationale, THEOREM-adjacent: a component you cannot formally verify and whose outputs are non-deterministic cannot be *trusted*; it can only be *checked*. So it is architected as untrusted and every consequential output passes a TCB gate. "Honest ignorance over guessing" is enforced here: an agent that cannot cite a Ring-2 authority for a claim is structurally unable to get that claim past the provenance gate.)
- **Retrieval, drafting, analysis, self-improvement engines.** All propose; none commit.
- **The corpus itself.** Content is data, never trusted code/policy.

**Why the TCB can be small (DESIGN-ENTAILED, with a named residual):** Intelligence does not need to be trusted if it is *checkable*. The heavy, unverifiable machinery (models) is pushed out; what remains inside is deterministic policy + integrity + gating + human-consent verification. The residual that keeps the TCB from being *tiny*: the Gate Evaluators must include at least one inherently-imperfect classifier (confidentiality/PII detection over free text). **This is the honest crack in the "small TCB" story** — a fail-closed classifier is still a classifier, and its false-negatives are a TCB-level confidentiality risk. Marked in Falsifiable Weaknesses.

**TCB size claim status:** "The TCB is small" is **HYPOTHESIS** until (a) the components are implemented and (b) their combined reviewable surface is measured. I do not assert it as achieved.

---

## PART 3 — SECURITY MODEL

### 3.1 Matter isolation & ethical walls (the capability model)

Every unit of work belongs to exactly one **matter**. Every agent instance is spawned bound to exactly one matter and receives a **capability set** minted by the broker: keys/handles to *only* that matter's memory partition, retrieval scope, and message bus topic.

- **Ethical wall = absence of capability.** If lawyer/agent context is walled off from Matter B, no capability referencing Matter B is ever minted into its set. (THEOREM in the capability-machine model: unreachable object ⇒ no information flow via *authorized* channels. **Formalization gap, explicit:** the theorem covers authorized channels only. Covert/side channels — timing, shared caches, model-weight memorization across fine-tunes — are OUTSIDE the model and are handled operationally, not proven. See 3.3 and Weaknesses.)
- **Conflict check (mechanism 9):** at intake, a deterministic scan runs the proposed parties/adverse parties against the provenance graph *through a privacy-preserving index* (the check learns "conflict / no conflict / needs-human", never leaking the contents of walled matters). "Needs-human" is a fail-closed default routed to Ring 0.

### 3.2 Insider threat

The institution assumes its own members (human and agent) may be compromised or malicious.

- **Two-person integrity for consequential acts (DESIGN-ENTAILED):** release, cross-matter linkage, policy change, and model promotion each require *two distinct* Ring 0 consents (separation of duties). No single insider can release client data or promote a captured model.
- **Least authority everywhere:** capability sets are minimal and time-boxed; expired handles are inert.
- **Every act is attributable:** the append-only log binds each record to the authoring agent identity, its capability set, and (for consequential acts) the consenting humans. (DESIGN-ENTAILED: non-repudiation for internal acts.)
- **Break-glass is loud, not silent:** emergency overrides exist (real deadlines demand them) but emit an un-suppressible high-priority incident to a second Ring 0 human and are auto-reviewed post hoc.

### 3.3 Egress & vendor/model risk

- **Default deny egress (INV-2).** The only path to Ring 4 is the Publication Gateway (Part 9).
- **Model risk containment:** models are Ring 3, untrusted. A poisoned or backdoored model can produce *wrong or malicious proposals* but (a) cannot write the record, (b) cannot cause egress, (c) cannot cross matters. Its blast radius is bounded to "bad proposal that must survive independent review + gates." (DESIGN-ENTAILED, conditional on INV-1/2/3 holding.)
- **Vendor/weights risk:** because no trust is placed in model internals, weight provenance is a *quality* input, not a *security* dependency. **Residual (HYPOTHESIS):** a sufficiently capable adversarial model could craft proposals engineered to pass the deterministic gates and fool independent reviewers simultaneously. The design's only defense is reviewer independence + gate diversity; there is no proof this suffices. Marked in Weaknesses.
- **Model exfiltration via output:** an adversarial model could try to encode client data steganographically into a "public" draft. The Publication Gateway's DLP/redaction is the sole barrier; this is a genuine, only-partially-mitigated risk (Weaknesses).

---

## PART 4 — DATAFLOW

A matter's life, as data:

```
INTAKE ─▶ CONFLICT SCAN (fail-closed) ─▶ MATTER PARTITION CREATED
                                              │  (capabilities minted)
   ┌──────────────────────────────────────────┘
   ▼
RING 4 INPUTS (statutes, filings, evidence)
   │  ingested as UNTRUSTED, hash-stamped, provenance-tagged
   ▼
RING 3 REASONING (specialist agents; see Part 6)
   │  produce PROPOSED RECORDS: analyses, drafts, claims-with-citations,
   │  factual-world hypotheses, each carrying provenance + confidence + dissent
   ▼
CAPABILITY BROKER (Ring 1)
   │  validates: format, provenance-completeness, matter-scope, gate predicates
   │  fail-closed: no citation ⇒ no commit; wrong matter ⇒ reject
   ▼
RING 2 RECORD (append-only, versioned)
   │
   ▼
INTERNAL REVIEW CHAIN (independent reviewer agents + human authority points)
   │
   ▼  [if artifact is destined to leave the firm]
PUBLICATION GATEWAY (Ring 1, fail-closed) ─▶ Ring 0 human consent ─▶ RING 4 (world)
                                            └─ immutable release receipt
```

**Load-bearing dataflow properties:**
- Every arrow into Ring 2 passes the broker. (INV-1.)
- The only arrow from any inner ring to Ring 4 passes the Gateway + Ring 0. (INV-2.)
- Provenance travels *with* the data, not beside it: a claim without a resolvable Ring-2 authority handle cannot be committed. (DESIGN-ENTAILED; this is the technical form of "honest ignorance" and "no fabrication.")

---

## PART 5 — CONTROL PLANE

The control plane is **separate from the data/reasoning plane** and is itself minimal and deterministic.

- **Orchestration Kernel (Ring 1):** schedules matters, spawns agents with minted capabilities, enforces deadlines (Part 11), and routes messages *only* along matter-scoped topics. It executes no legal reasoning and contains no LLM. (DESIGN-ENTAILED: keeping orchestration LLM-free means the *controller* cannot be prompt-injected by adversarial corpus content.)
- **Policy as versioned data:** all policy (capabilities, gates, review requirements, deadline rules) lives in Ring 2 as versioned records the kernel reads. Changing policy is a two-person Ring 0 act (3.2), logged and replayable.
- **No dynamic privilege escalation:** an agent cannot request "more capability" mid-task; it must return to the broker with a justified proposal that the kernel evaluates against static policy. (Prevents the classic "confused deputy" and prompt-injection-driven escalation.)
- **Control/measurement split:** the plane that *observes* (telemetry, audit, incident capture) is read-only with respect to the plane that *acts*, so a compromised observer cannot act and a compromised actor cannot rewrite history.

---

## PART 6 — AGENT TOPOLOGY (THE DIGITAL FIRM'S ORG CHART)

Modeled directly on the firm's org structure, because the org structure *is* the error-control structure.

**Roles (all Ring 3, all untrusted, all matter-bound):**

1. **Intake & Framing agents** — turn a raw matter into a structured question set, identify governing regimes (Greek order; EU law; ECHR), flag procedural posture and deadlines. Output: a *framing*, not an answer.
2. **Specialist reasoners (practice groups)** — typed by domain (e.g., civil procedure, administrative, criminal, EU/ECHR, tax). Each declares a **competence boundary**; the broker will not commit a specialist's claim outside its declared domain without cross-specialist corroboration. (Mechanism 1, upgraded: competence is *declared and checked*.)
3. **Adversarial reasoners (the internal opponent)** — per CLAUDE.md's internal-adversary protocol, for every consequential analysis an *independent* agent with fresh context and no access to the author's private reasoning is spawned to (a) attack the legal position and (b) hunt mediocrity/patches/ungrounded claims. (Mechanism 2, upgraded: reviewer independence is enforced by construction — the reviewer literally cannot see the author's chain-of-thought, only the committed record.)
4. **Evidence & fact-world agents** — build and maintain *alternative factual worlds* (Part 7), never a single stipulated truth.
5. **Reviewer/synthesis agents (the "senior associates")** — reconcile specialist + adversary outputs into a reviewed work product with an explicit *dissent ledger*.
6. **Memory/provenance agents** — maintain the record's citation graph and version links.
7. **Improvement agents (Part 10)** — propose, never merge.

**Topology invariants:**
- **Author ≠ reviewer, by construction (DESIGN-ENTAILED):** the orchestration kernel guarantees the reviewer instance shares no state with the author instance. This makes "rubber-stamp review" structurally harder than social review chains, where a junior's deference to a partner is a known failure mode.
- **Independence is verifiable:** the log records the context isolation, so an auditor can confirm reviewer independence rather than trust it.
- **No agent is a "wrapper" of another** (CLAUDE.md: no wrappers): each role is a single seat with a single entry point; duplicated capability is a defect the registry rejects.

**Honest limit (HYPOTHESIS→UNKNOWN):** independent adversarial review reduces *correlated* error but not error that is *common to the whole model population* (a shared blind spot in the training distribution about, say, a subtle point of Greek administrative practice). Multiple independent agents drawn from correlated models are not truly independent. This is a real ceiling; see Weaknesses.

---

## PART 7 — EPISTEMIC REPRESENTATION (NO SINGLE "ONE TRUTH")

A single-world knowledge base is presumptively wrong for law, because law is a domain of *contested authority, open texture, and unresolved fact*. The record therefore represents disagreement as a first-class object.

### 7.1 Authorities and their conflicts
- Each legal authority (statute article, regulation, decision of Άρειος Πάγος / ΣτΕ / ΔΕΕ / ΕΔΔΑ) is a node with: text, temporal validity interval, jurisdictional scope, and hierarchical rank.
- **Conflicts are edges, not deletions.** When authorities conflict, the graph records *both* plus a **conflict-resolution rule node** (lex superior / lex posterior / lex specialis, EU primacy, ECHR conformity via Art. 28 §1 Greek Constitution) and its *conditions of application*. The system computes candidate resolutions; it does not silently pick one. (DESIGN-ENTAILED.)
- **Temporal worlds:** the same question at time T1 and T2 may have different governing law. The store is bitemporal (valid-time and record-time), so "what was the law when the act occurred" and "what is the law now" are both answerable. (Ties to Part 8 replay.)

### 7.2 Competing interpretations
- An interpretation is an explicit object: {authority set, interpretive method (textual/teleological/systematic/historical), resulting rule, supporting reasoning, known counter-arguments, holder}. Multiple live interpretations coexist with weights that are *arguments*, not scalar "confidence" pretending to be probability.

### 7.3 Alternative factual worlds
- Facts are represented as a set of **mutually exclusive or partially-ordered factual hypotheses**, each with its evidentiary support, burden/standard of proof it must meet, and the procedural consequence if adopted. The system reasons *per world* and reports how the legal outcome varies across worlds — exactly the "if the court finds X vs. Y" analysis a good lawyer performs. (DESIGN-ENTAILED.)

### 7.4 Procedural uncertainty
- Deadlines, admissibility, standing, competence of forum are represented with their own uncertainty (e.g., contested limitation start date ⇒ two deadline worlds, and the system plans to the *earliest* under fail-closed logic). (Ties to Part 11.)

**Why this beats a "one-truth" KB (DESIGN-ENTAILED):** the record can never be "caught out" by having deleted the losing interpretation, and every downstream draft can be traced to *which* world/interpretation it assumed. **Cost, stated openly:** this representation is far more expensive to build and keep consistent, and consistency of the disagreement-graph itself is a new failure surface (Weaknesses).

---

## PART 8 — REASONING MODES

The system does not have one reasoning engine; it routes to the mode appropriate to the legal question type, and records which mode produced each conclusion.

1. **Computational-law mode (rules-as-code):** for genuinely algorithmic law (deadlines, thresholds, fee/interest computation, procedural checklists), reasoning is *deterministic code over structured facts*, not LLM inference. (DESIGN-ENTAILED: where law is a function, compute the function; do not ask a model to guess it. **Formalization gap, named:** the code is a *formalization* of the statute; proving the code correct is NOT proving the formalization faithful to the enacted text. Faithfulness requires human authority sign-off on the formalization, versioned and re-reviewed when the statute changes.)
2. **Open-texture mode:** for evaluative standards (good faith, proportionality, "reasonable time"), the system does NOT pretend to compute an answer. It *maps the argument space*: the competing constructions, the authorities each side would marshal, the factual sensitivities, and the range of defensible outcomes. It outputs *structured advocacy and risk*, explicitly flagged as judgment territory reserved to the human. (This is the honest boundary: open texture is where human partner judgment is irreplaceable, mechanism 6.)
3. **Precedent mode:** case-based reasoning over the authority graph — analogize/distinguish on stated factors, surface the strongest adverse precedent (the adversarial agent's job), track precedent's temporal validity and any overruling.
4. **Evidence mode:** reasoning over the factual-worlds structure (7.3) against burden/standard of proof, chain-of-custody/provenance of each evidentiary item, and admissibility.

**Cross-mode rule (DESIGN-ENTAILED):** no conclusion may launder its mode. A computational result and an open-texture judgment are tagged distinctly in the record; a draft that presents an open-texture *opinion* as if it were a computed *fact* is rejected by the review gate. This structurally prevents the most dangerous legal-AI failure: confident presentation of contestable judgment as settled law.

---

## PART 9 — PUBLICATION BOUNDARY (FAIL-CLOSED GATEWAY)

Per the binding conditions: the system is internal/private; only *final outputs* may become public, only through a separate fail-closed gateway. The Gateway is Ring 1, deterministic, and the *only* egress path.

**Gateway pipeline (every stage fail-closed — "uncertain" ⇒ "block"):**
1. **Scope check:** is this artifact *marked releasable* by policy at all? Default no.
2. **Privilege review:** does it contain privileged/work-product content? Classifier + policy; uncertain ⇒ block.
3. **Confidentiality/DLP:** client identifiers, matter data, model-trace leakage, steganographic-exfiltration heuristics. Uncertain ⇒ block.
4. **Redaction verification:** if redaction was applied, verify it is *irreversible in the output artifact* (not just visually masked). Fail ⇒ block.
5. **Authority validation:** for codified-law/case-law publications, every cited authority resolves to a valid Ring-2 node with correct temporal/jurisdictional scope. Any dangling/expired citation ⇒ block.
6. **Human approval (Ring 0):** two-person consent bound to *this artifact hash and version*.
7. **Immutable release receipt:** hash of released artifact + policy version + gate results + consenting identities, written to the append-only log. (Non-repudiation of what was released and on whose authority.)

**Fail-closed theorem (THEOREM in the gateway's state model):** if any stage returns anything other than an explicit PASS, the artifact does not egress. **Formalization gap:** this is only as strong as the *completeness* of the checks; a leak the checks don't model passes silently. The theorem is about the *control structure*, not about the *sufficiency of the detectors*. Stated plainly, not hidden.

---

## PART 10 — SELF-IMPROVEMENT WITHOUT SELF-MERGE

The firm improves via apprenticeship and post-mortems (mechanisms 7, 10). The digital institution improves analogously — but **no component may promote its own improvement.**

**Mechanism:**
- **Improvement proposals are Ring-3 outputs** like any other: a proposed change to a formalization, a prompt/strategy, a policy, a model version. They carry evidence: which past matters they would have changed, replayed outcomes, adversarial-review results.
- **Evaluation is on the RECORD, not the proposer's say-so:** proposals are tested by replay (Part 12) on a corpus of past matters, with the *same-version* baseline compared to the *proposed-version* outcome. Independent adversarial agents attack the proposal.
- **Promotion requires two-person Ring 0 consent** (separation of duties) plus a passing internal gate. **No autonomous merge exists in the system** — there is no code path by which an agent's proposal becomes active policy/model without a Ring 0 token. (DESIGN-ENTAILED; this is the technical enactment of CLAUDE.md's "only the creator merges/approves phases.")
- **Learning without weight-trust:** because models are never trusted, "self-improvement" is primarily improvement of *formalizations, argument maps, gates, and process*, not opaque weight updates. A promoted model is treated as a *new untrusted component* that must still pass every gate.

**Anti-Goodhart guard (HYPOTHESIS):** improvement is measured against *multiple* independent metrics plus adversarial review, precisely because optimizing one metric invites gaming. There is no guarantee this defeats a sufficiently clever proposer; marked in Weaknesses.

---

## PART 11 — DEADLINES, LATENCY, AVAILABILITY (AS CORRECTNESS)

Real procedural deadlines are correctness, not economics.

- **Deadlines are first-class record objects** with source (the procedural rule + authority), computed date, and *uncertainty* (7.4). The computational-law engine (mode 1) computes them deterministically; a human authority point confirms any deadline whose computation depends on a contested fact.
- **Fail-closed on time:** where a deadline's start is uncertain, the system plans to the *earliest* defensible date. Missing-a-deadline is treated as a *safety violation*, not a quality miss.
- **Availability as correctness (DESIGN-ENTAILED):** the deadline/alerting path and the record's integrity substrate are designed for high availability independent of the (heavier, flakier) reasoning plane — the firm must never miss a filing because a model was down. The reasoning plane may degrade; the *deadline watchtower* may not. (This is why the name-space of this project — a "watchtower" — is apt: the deterministic guardian outlives the clever tenant.)
- **Latency budgets** are per-matter-posture correctness constraints surfaced to the orchestration kernel; the kernel prioritizes deadline-critical work over background improvement work.

---

## PART 12 — MEMORY & VERSIONING (REPLAY AND RE-EVALUATION)

Two distinct, both-required capabilities:

1. **Same-version replay (audit/defense):** given a past decision, reconstruct *exactly* what the system knew and concluded then — same corpus version, same policy version, same model version, same authority-graph state (bitemporal record-time). (DESIGN-ENTAILED: deterministic control plane + versioned everything ⇒ replayable. **Named gap:** LLM outputs are non-deterministic; true bit-replay of a model requires captured outputs, so replay reconstructs *the recorded proposals and the deterministic decisions over them*, not a re-execution of the model. The record, not the model, is the replayable object.)
2. **Current-version re-evaluation (learning/consistency):** re-run today's system against a past matter to detect where current understanding diverges — surfacing both improvements and regressions. This is how the institution notices "we would decide this differently now" and feeds Part 10.

Memory is **provenance-first**: every stored conclusion links to its authorities, its factual world, its reasoning mode, and its version context. Retrieval returns provenance, so a downstream agent inherits *why*, not just *what*. (DESIGN-ENTAILED; the technical form of institutional memory that is superior to a human firm's — perfect, cited recall — while explicitly NOT superior in judgment.)

---

## PART 13 — FAILURE CONTAINMENT & FAILURE CULTURE

**Containment (DESIGN-ENTAILED, conditional on invariants):**
- A failing/compromised agent is bounded by its capability set (matter-scoped) and cannot write the record or egress. Blast radius = "bad proposals within one matter, caught by review + gates."
- A failing gate defaults closed. A failing reasoning plane degrades to the deterministic watchtower (deadlines/integrity survive).
- A failing TCB component is the catastrophic case; hence the TCB is kept small, LLM-free, and (aspirationally) independently verified. The design does not claim the TCB cannot fail — it claims failures elsewhere are contained *to* the TCB's guarantees.

**Failure culture (governance, mechanism 10):**
- **Blameless, mandatory near-miss capture:** any gate-block, break-glass, review-caught error, or replay-detected regression is an incident record, automatically. Suppressing an incident is itself a violation.
- **Phase-death of error classes:** per CLAUDE.md, a fix is not a patch around a bad shape; the standard is *eliminate the error class structurally* and retire (φάση θανάτου) the guard once the class is impossible. Incidents that recur are escalated from "guard" to "redesign."
- **The internal adversary is permanent, not decorative:** every phase runs independent attack agents (security break + mediocrity hunt) before any proof, per CLAUDE.md [0047]. Findings are closed at their seat, refuted with proof, or declared residual with a death-phase. Unresolved contradictions remain **BLOCKING**.

---

## PART 14 — HUMAN AUTHORITY POINTS (WHERE RING 0 IS LOAD-BEARING)

The following acts have **no autonomous path** and require named-human consent (two-person where noted):

| Act | Consent | Rationale |
|---|---|---|
| Take a matter past a conflict "needs-human" | 1 human | Ethical duty; mechanism 9 |
| Sign off a formalization of a statute (mode 1) | 1 human | Formalization-faithfulness gap (Part 8) |
| Resolve an open-texture judgment for a real matter | 1 human (the responsible lawyer) | Mechanism 6 — irreducible judgment |
| Release anything to Ring 4 (publication) | 2 humans | Confidentiality + accountability |
| Promote a model/policy/improvement | 2 humans | Insider threat + Goodhart |
| Change TCB policy | 2 humans | Root-of-trust change |
| Break-glass override | 1 human, loud + auto-review | Real deadlines vs. safety |

**Design commitment (stated as a trade-off, not hidden):** these human points are deliberate *throughput bottlenecks*. The design chooses accountability and safety over autonomy. A system that removed them would be faster and would be, by this design's definition, *not an institution* — it would be an unaccountable oracle. That choice is contestable; I mark it as a chosen value, not a theorem.

---

## PART 15 — FALSIFIABLE WEAKNESSES (where THIS design fails, and how an evaluator detects it)

I do not self-grade. The following are concrete failure modes with detection procedures. An evaluator should attack these first.

1. **Correlated-model blind spot (UNKNOWN).** "Independent" adversarial reviewers drawn from correlated models share blind spots; independence is partly illusory. *Detection:* seed matters with errors known to be in a shared training blind spot (e.g., a subtle, rarely-litigated point of Greek procedure); measure whether *any* independent agent catches it. If catch-rate ≈ single-agent rate, the review-chain's claimed advantage is largely false. **BLOCKING until measured.**

2. **Gate detector insufficiency (HYPOTHESIS).** Fail-closed control is only as strong as the checks' completeness (Parts 2, 9). A confidentiality leak the DLP doesn't model egresses silently. *Detection:* red-team the Publication Gateway with steganographic and paraphrastic exfiltration; measure leakage past the gate. Non-zero leakage falsifies "confidentiality is structural." The residual PII/privilege classifier inside the TCB is the specific crack.

3. **Formalization-faithfulness gap (THEOREM-adjacent, permanent).** Proving rules-as-code correct never proves it faithful to the statute (Part 8). *Detection:* independent human re-formalization of a sample of statutes; measure divergence from the deployed formalization. Divergences are latent wrong-law bugs that all downstream proofs inherit. This gap cannot be closed by more compute — only by human review, which reintroduces human error.

4. **Disagreement-graph inconsistency (HYPOTHESIS).** The multi-world epistemic store (Part 7) is itself a large consistency-maintenance problem; an inconsistent conflict-graph could yield incoherent cross-world reasoning. *Detection:* consistency audits over the authority/interpretation graph; injected contradictory authorities should be surfaced, not silently absorbed.

5. **Replay is record-replay, not model-replay (named gap, Part 12).** An evaluator expecting to *re-derive* a past conclusion from the model will find only the recorded proposals. *Detection:* attempt independent re-derivation; the gap is real and by-design, but a stakeholder who misunderstands it will overtrust "reproducibility."

6. **Covert channels defeat the isolation THEOREM (Part 3.1).** The ethical-wall theorem covers authorized channels only. *Detection:* timing/cache side-channel probes across matter partitions; cross-fine-tune memorization tests (does a model trained on Matter A leak into Matter B outputs?). Any leak falsifies "ethical walls are structural" in the deployed system even though the model-level theorem stands.

7. **TCB-size claim unproven (HYPOTHESIS, Part 2).** "The TCB is small and reviewable" is asserted, not measured. *Detection:* measure the reviewable surface (LOC, policy size, dependency closure) of Ring 1; if it is large or depends on unverifiable libraries, the core security bet is weaker than stated.

8. **Human bottleneck as availability risk (DESIGN-ENTAILED trade-off).** Mandatory Ring 0 consent points can block time-critical release under real deadlines. *Detection:* simulate deadline-critical publications requiring two-person consent with humans unavailable; measure missed-deadline rate. Break-glass mitigates but reintroduces insider risk.

9. **Adversarial proposal engineered to pass gates + fool reviewers simultaneously (HYPOTHESIS, Part 3.3).** No proof this is prevented. *Detection:* commission a red-team model explicitly optimizing for "pass all deterministic gates AND survive independent review"; measure success rate. Non-trivial success falsifies the containment story for model risk.

10. **Open-texture over-confidence leak (HYPOTHESIS, Part 8).** The mode-tagging rule that keeps judgment from masquerading as fact depends on correct mode classification, itself fallible. *Detection:* seed open-texture questions phrased to look computational; measure how often the system mis-tags judgment as computed fact and gets it past review.

**Standing instruction to any evaluator:** treat items 1, 2, 3, 6 as the load-bearing ones. If any of them fails empirically, the corresponding superiority axis (independent review / structural confidentiality / correct-law / ethical walls) is falsified regardless of how elegant the rest of the design reads.

---

## PART 16 — WHAT THIS DESIGN DOES *NOT* CLAIM

- It does not claim supremacy over any human team or AI system. It gives structural reasons to expect advantage on **recall, review independence, isolation, auditability, deadline safety** — each falsifiable above — and *no* structural reason to expect advantage on **judgment under open texture**, which it explicitly reserves to humans.
- It does not equate proof-checking with correctness (formalization gaps are named throughout).
- It does not equate model access with idea inclusion (a claim is "included" only when it survives to the record with provenance and review, not merely because a model could read the source).
- It leaves BLOCKING: item 1 (correlated-model independence) and item 2 (gate sufficiency) until measured. These are not engineering details; they decide whether the institution's central advantages are real.
