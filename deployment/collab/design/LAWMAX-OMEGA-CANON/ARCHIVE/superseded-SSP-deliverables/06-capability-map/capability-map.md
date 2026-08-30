# E★★ CAPABILITY MAP — LAWMAX-Ω

*Synthesized from the 8-area capability census + the honesty adversary's adjudication (52 claims audited: 50 CONFIRMED_EXECUTING, 1 demoted, 2 material caveats). Every demotion the adversary found is applied below — nothing the adversary broke is still shown as running.*

**Tier legend**
- **✔ EXECUTING TODAY** — running, VERIFIED/DETERMINISTIC in the census, inspected in the repo
- **◐ DESIGN-ENTAILED** — forced by the committed architecture (closed sum types, identity theorem, single relation A); executing precursor present, formal grounding is a named BO
- **◇ CONDITIONAL ON BUILD** — designed with an executing partial, gated behind a specific Build Obligation (BO-nn)
- **○ BUILD OBLIGATION** — designed, no executing precursor yet

**Floor:** ▲ = above the CoCounsel / Protégé / Harvey floor · = = at the commercial floor

---

## 1. What this system is

LAWMAX-Ω is not a legal-research assistant that answers in natural language and hopes you trust it. It is a **deterministic admission machine for legal conclusions**: an LLM is allowed to *propose*, but no language model sits anywhere on the trusted path — every guarantee (soundness, grounding, provenance, authority, durability) is checked by re-runnable, LLM-free code and pinned at **one kernel admission gate**. The single thing that separates its capabilities from CoCounsel, Protégé, and Harvey is a **trust inversion**: those products place intelligence *inside* the trusted path and bolt guardrails around it; LAWMAX treats all intelligence — including its own agentic parts — as untrusted, forces every claim through a single admission predicate, and ships each answer with a **receipt anyone can re-verify offline, byte-for-byte, with zero trust in the producer**. When it cannot soundly decide, it returns a typed "I don't know" rather than a confident guess — honesty is a first-class output, not a disclaimer.

---

## 2. Capabilities by domain

### 2.1 Legal reasoning & adjudication (AX-01, AX-02, AX-09, AX-10)

| Capability | What a lawyer gets | Tier | Floor |
|---|---|---|---|
| Defeasible reasoning w/ automatic retraction (JTMS) | Conclusions withdraw themselves the moment a supporting rule is repealed or defeated; no infinite loops on circular argument | ✔ `orchestrator-cli/inference-gate.lisp` | ▲ |
| Cross-authority conflict resolution by committed lex rules | Constitution-vs-statute, newer-vs-older, specific-vs-general clashes resolved by fixed lex superior/posterior/specialis — same inputs, same result | ✔ `source/legal-conflict-resolution.lisp` + `legal-counterfactual.lisp` | ▲ |
| Deterministic single-entry pipeline composition | Multi-step workflows run in one fixed, reproducible order — no agent wandering | ✔ `orchestrator-spec/pipeline-dsl.lisp` + `orchestrator-core/dependency-graph.lisp` | ▲ |
| Honest "I don't know" (honest-ceiling judges) | Typed refusal at the competence boundary instead of a plausible-sounding unverified answer | ✔ `deontic-gate.lisp` + `inference-gate.lisp` + `meta-ontology.lisp` | ▲ |
| Un-gameable positive proof census | "All checks passed" exists only if the checks actually ran; a crash yields no green | ✔ `authority-v2/proofs/verify-proof-manifest.py` + `run-proofs.sh` | ▲ |
| Mutation-kill adversarial self-testing (covered areas) | Faults injected into safeguards, each proven caught, as an offline-recomputable kill matrix | ✔ `authority-v2/proofs/capture-mutation-witness.py` *(capture/Merkle areas only; axis rank UNKNOWN)* | ▲ |
| Counterfactual ablation self-falsification | Remove a fact/rule, re-check whether the conclusion still holds — which conclusions are load-bearing | ✔ `source/legal-counterfactual.lisp` + `source/introspection.lisp` | ▲ |
| Frozen adversarial regression suites | Hard normative-conflict cases the engine must keep passing every release | ✔ `deontic-gate.lisp` + `inference-gate.lisp` *(the ~91.5% deontic classifier they exercise is being retired from the trusted path)* | ▲ |
| Single consistent acceptance relation over one committed rulebook | Every conclusion from ONE engine over ONE rulebook, provably never self-contradictory | ◐ AX-01 R4 rider → BO-03 | ▲ |
| Four-class total verdict algebra | Every answer is exactly PROVEN / REFUTED / STABLE-over-unknowns / typed-UNKNOWN — no fifth "confident guess" | ◐ AX-09 R5 rider → BO-22 | ▲ |
| Statute-as-code total evaluation | Apply a codified statute; conflicting exceptions & missing definitions surface as typed errors, never smoothed over | ◇ new L4 statute δ-calc cell, admission via DIM-16 | ▲ |
| Precedential forcing from case law (FORCED vs OPEN + certificate) | Whether precedents force a result or leave it genuinely open, with a checkable dominance trace | ◇ BO-06 | ▲ |
| Escalation to stronger argumentation semantics | On undecided cycles, escalate under budget with a re-checkable certificate — or honest OPEN/refusal | ◇ BO-05 + BO-04 | ▲ |
| Certified unique-status defeater closure (R5) | Proven — not just tested — that in/out/undecided is the unique correct labelling for arbitrary rule graphs | ◇ BO-04 + BO-05 (+ BO-06) | ▲ |
| Plans that cannot be defective | A plan with a missing step / cycle / type-mismatch cannot be built or run — an incomplete plan is a visible typed hole | ◇ BO-07 | ▲ |
| Atomic tier-commit plan execution w/ exact rollback | A tier of steps commits whole or not at all; failure restores exact pre-step state | ◇ BO-08 + BO-12 *(today's parallel-executor is fail-open dead code, slated for deletion)* | ▲ |
| Stability certification over all open questions | Proof the answer is identical under every way the gaps could resolve | ◇ BO-22 | ▲ |
| Machine-enforced closed cause set for UNKNOWN | "Unknown" drawn from a fixed enumerated list; a blind spot can never be silently promoted to "yes" | ◇ BO-22 | ▲ |
| Repo-wide adversarial campaign + provably-independent critics | Any silently-breakable safeguard blocks the whole release; reviewers proven independent of the builder | ◇ BO-01 | ▲ |

### 2.2 Grounding & citation (AX-04 source grounding; AX-05 citation/authority validation)

| Capability | What a lawyer gets | Tier | Floor |
|---|---|---|---|
| Reproducible source-quote verification | Re-run extraction from original bytes; the quote is proven byte-identical, not paraphrased or hallucinated | ✔ `source/authority-evidence-replay.lisp` | ▲ |
| Corpus-size-independent membership proof | Proving a cited doc is in the committed corpus costs O(log n), not a full re-scan | ✔ `source/merkle-authority.lisp` (RFC-6962, CVE-2012-2459-safe) | ▲ |
| Cryptographic authority-chain verification | Right issuer signed it, delegation valid at the time, not revoked | ✔ `source/authority-proof-bundle.lisp` (Ed25519) | ▲ |
| Time-anchored authority receipt (bitemporal) | Citation resolves to a receipt pinned to legal-time and knowledge-time; anti-rollback | ✔ `source/legal-authority-receipt.lisp` | ▲ |
| Strict DER / ASN.1 parsing | Timestamp/cert tokens parsed under strict rules; malformed encodings rejected, not guessed | ✔ `source/asn1-der.lisp` | ▲ |
| No LLM anywhere in the grounding/citation trust path | Every trust decision is deterministic re-runnable code; a fabricated cite cannot pass | ✔ `authority-proof-bundle.lisp` + `authority-evidence-replay.lisp` | ▲ |
| Citation extraction from free text (heuristic) | Best-effort scan of cites in a document | ✔ `source/citation-authority.lisp:224` — **lossy: `(<= num 120)` clamp silently drops articles >120 and lettered articles (P0-10); correct only for the ≤120-article Constitution, wrong for the Penal Code. Being retired.** | = |
| Fail-closed citation typing (UNKNOWN-CITATION) | An unverifiable cite is typed UNKNOWN and can never be silently upgraded to "valid" | ◐ AX-05 rider (closed sum type) | ▲ |
| Honest support boundary | Validates the authority is genuine/in-force — does **not** claim its text supports the NL point (a distinction commercial cite-checkers blur) | ◐ AX-05 L8 boundary | ▲ |
| Exact-identifier source selection | Fetch by exact committed identifier, no corpus-scanning guess | ◇ BO-09 *(glob fallback still reachable today)* | ▲ |
| Fail-closed grounding (unattested → typed refusal) | An unattestable source refuses, never proceeds on unverified bytes | ◇ BO-09 *(origin fetch un-attested today; capture.py P0-16 silent-degradation)* | ▲ |
| Publisher-signature verification at capture | Where the gazette signs, verify the signature at capture | ◇ BO-09 | ▲ |
| Independent capture witnesses / attested channel | Where the publisher does not sign, anchor via k-of-n witnesses or attested TLS | ◇ BO-09 *(witnesses NIL today)* | ▲ |
| Gazette transparency-log enrollment | Stealth issuance with a compromised key becomes detectable/attributable | ◇ BO-09 | ▲ |
| Multi-span excerpting w/ committed gap-manifest | Quote several passages with an explicit record of what was skipped | ◇ BO-09 *(single contiguous span only today)* | ▲ |
| Grammar-total citation recognizer | Proven-complete coverage; every citation-shaped string resolves or is flagged unrecognized — no clamp | ◇ BO-20 *(deletes the `:224` regex+clamp)* | ▲ |
| Per-citation certificate binding each cite to a receipt | Each cite independently checkable against its verified time-anchored receipt | ◇ BO-20 (chain executes today) | ▲ |
| Full RFC-3161 TSA-chain verification | Full timestamp-authority chain, not just token-parses | ◇ BO-20 *(strict-DER parser executes today)* | ▲ |

### 2.3 Provenance, audit & reproducibility (AX-06, AX-13, AX-14, AX-19)

| Capability | What a lawyer gets | Tier | Floor |
|---|---|---|---|
| Tamper-evident inclusion & append-only proof | Prove a doc is in the corpus and the corpus only grew — by redoing the hash arithmetic yourself | ✔ `source/merkle-authority.lisp` | ▲ |
| Recompute-and-compare evidence lineage | System re-derives each result from source bytes and distrusts even its own recorded hashes | ✔ `source/authority-evidence-replay.lisp` | ▲ |
| Hash-committed artifact inventory (census) | Hash-sealed inventory + release chain; any missing/extra artifact is mechanically detectable | ✔ `orchestrator-epistemic/artifact-census.lisp` | ▲ |
| Human-readable source-provenance on each answer | Which exact PDF/gazette and which stage produced each element | ✔ `source/provenance-link.lisp` + `source-detection.lisp` | = |
| Independent offline re-verification by 3 diverse implementations | Re-check a whole release offline with Python + JS + Lisp verifiers that must all agree | ✔ `deployment/verify/verify.py` + `verify.mjs` + `kernel-verify.lisp` | ▲ |
| Fail-closed un-gameable proof manifest | "Passed" only if the proofs ran to completion; a crash yields no manifest | ✔ `verify-proof-manifest.py` + `run-proofs.sh` | ▲ |
| Release-spine re-verification staged inside release identity | The verifier is part of the signed release; re-run offline with no producer cooperation | ✔ `orchestrator-epistemic/release-spine.lisp` | ▲ |
| Exact deterministic replay of a decision receipt | Replay a receipt to the exact journal state/sequence — the field's only running past-time replay witness | ✔ `source/legal-authority-receipt.lisp` | ▲ |
| Canonical deterministically-ordered serialization | Same logical content always serializes in the same order | ✔ `omega-modules/rdf-canonicalization.lisp` + `model/article.lisp` | ▲ |
| Cannot-think-invisibly: every reasoning step is a recorded trace | No hidden deliberation; traces bound to contract/proof, and the path is LLM-free so the trace *is* the computation | ✔ `source/deliberation.lisp` + `provenance-gate.lisp` *(universality rests on provenance-gate registration, not the MOP alone)* | ▲ |
| All provenance folded into one signed release identity | One signature covers the whole lineage record | ◐ AX-06 rider → BO-21 | ▲ |
| Per-step transformation ledger (before→after hash) | Catch a silent alteration mid-pipeline, not just start-to-end mismatch | ◇ BO-21 *(today step hashes computed but not compared)* | ▲ |
| Portable zero-trust receipt over every decision class | Every trusted decision, not just releases, ships a re-derivable receipt | ◇ BO-11 | ▲ |
| ~100ms self-verifying succinct receipt | Prove a derivation in ~100ms without re-running the system | ◇ BO-17 (transparent-STARK; recompute arm stays the floor) | ▲ |
| Byte-identical reproducible rebuild across environments | Two auditors in different environments get byte-identical files | ◇ BO-12 *(residual wall-clock leaks P0-4 today)* | ▲ |
| Machine-verified purity / injected logical clock | Proof — not a passing test — that no clock/randomness/env leak can change a trusted output | ◇ BO-24 + BO-12 | ▲ |
| Decision and its explanation are the same committed object | The explanation *is* the proof object decided from — it cannot drift from the decision | ◇ BO-18 | ▲ |
| Independent trace-vs-explanation cross-check | Harness re-derives the explanation from the replay trace and byte-compares to what was served | ◇ BO-18 | ▲ |

### 2.4 Memory & temporal reasoning (AX-07 institutional memory; AX-08 bitemporal legal state)

| Capability | What a lawyer gets | Tier | Floor |
|---|---|---|---|
| Tamper-evident institutional memory log | Every decision/episode/note in a chain that fails its own integrity check if a past entry is altered | ✔ `source/memory.lisp` | ▲ |
| Downgrade-proof memory records | A high-assurance record cannot be swapped for a weaker version undetected | ✔ `source/memory.lisp` ([RATCHET-3]) | ▲ |
| Read-back-verified decision ledger | Re-read and re-hash what was written before treating a decision as recorded | ✔ `source/adoption-decision.lisp` | ▲ |
| Matter-memory recall interface | Query prior episodes, decisions, and context for the matter | ✔ `orchestrator-cli/memory-commands.lisp` | = |
| Re-runnable past-time replay of legal-authority state | Reconstruct and replay past authority state to exact equality — the field's only such running mechanism | ✔ `source/legal-authority-receipt.lisp` *(receipt path only)* | ▲ |
| Point-in-time version history of legal provisions | Target the text as it stood on a given legal date (as-enacted/amended/repealed) | ✔ `source/version-graph.lisp` + `temporal-semantics-test.lisp` | = |
| Cryptographic append-only proof of the knowledge timeline | Verify what was known over time grew append-only, never silently rewritten | ✔ `orchestrator-epistemic/transparency-log.lisp` *(proves internal consistency only; wholesale replacement not caught by this seat; P1 error-swallow)* | ▲ |
| Hash-chained knowledge-time spine across releases | Monotone verifiable "what was known as of when" | ✔ `orchestrator-epistemic/artifact-census.lisp` | ▲ |
| Anti-rollback floor on cited authorities | A cited authority can't be rolled back below a time floor undetected | ✔ `source/authority-proof-bundle.lisp` *(floor consumer-supplied today)* | ▲ |
| Automatic invalidation of conclusions when the law changes | Repeal/amend a provision → dependent conclusions auto-withdrawn | ✔ `orchestrator-cli/inference-gate.lisp` | ▲ |
| Every memory write is an accountable fail-closed transition | Nothing enters memory except as a signed act through the kernel commit | ◐ AX-07 rider → BO-25 | ▲ |
| Full two-clock bitemporal query (law-as-of × knowledge-as-of) | "What did the law say on D1, per what we knew on D2" for any query; off-coverage → typed UNKNOWN | ◇ BO-10 *(today only the receipt path replays)* | ▲ |
| Typed amendment events w/ transitional-effect semantics | Amendments as structured typed events, not just successive text snapshots | ◇ BO-10 *(amended codes carry zero recorded amendment events today)* | ▲ |
| Lawful erasure of memory that keeps the audit chain intact | Cryptographically destroy client content (right-to-erasure) while tamper-evidence still verifies | ○ BO-25 | ▲ |
| Signed memory checkpoint bound to release identity | System can't be silently rewound below a held memory checkpoint | ○ BO-25 | ▲ |

### 2.5 Authority, orchestration & durability (AX-03, AX-11, AX-12, AX-15, AX-16)

| Capability | What a lawyer gets | Tier | Floor |
|---|---|---|---|
| Kernel-enforced sole writer to the legal record | Only one OS identity can write the record; every other process gets a real kernel EACCES | ✔ `verify-capability-closure.sh` + `capability/identities.sh` | ▲ |
| One and only one code path writes the corpus | A single auditable write seat; a regression gate fails the build if a second writer appears | ✔ `source/write-authority.lisp` + `architecture-multiplicity-test.lisp` *(emit itself non-atomic, P1)* | ▲ |
| Read-back-verified durable commit of institutional decisions | Write → read back → re-hash before a governance decision is final | ✔ `source/journal.lisp` + `adoption-decision.lisp` | ▲ |
| Signed, append-only accountable decision ledger | Who decided what, when — tamper-evident, not silently rewritable | ✔ `source/adoption-decision.lisp` *(P1 wall-clock debt)* | ▲ |
| Capability closure — only trusted capabilities invocable | Closed permission model; anything not enrolled trusted is refused | ✔ `source/capability-registry.lisp` | = |
| Fail-closed verification harness | A crash/missing check yields no success manifest, never a false green | ✔ `authority-v2/run-proofs.sh` + `verify-proof-manifest.py` | ▲ |
| Bounded autonomous error handling w/ checkpoint resume | Stops after bounded consecutive errors; resumes from a saved agenda checkpoint | ✔ `source/autonomy.lisp` | = |
| Circuit breaker on external dependencies | Repeated failures trip a breaker; stays responsive under partial outage | ✔ `source/circuit-breaker.lisp` *(`:system` time debt)* | = |
| Append-only release/transparency log w/ re-provable consistency | Sequence of official states can't be rewritten without detection | ✔ `orchestrator-epistemic/transparency-log.lisp` | ▲ |
| No operation waits forever (bounded execution by construction) | No primitive can block indefinitely; every wait is budgeted | ◐ AX-16 R3 rider (floor: `autonomy.lisp` + `run-proofs.sh`) | ▲ |
| **Unbypassable constitutional gate on every command** | The `:around` dispatch barrier is genuinely unbypassable — **but the gate it enforces fails OPEN today**: a rule that throws returns `(values t nil)` = *allowed* (P0-2). The "must clear a constitutional check" guarantee is **NOT executing.** | **◇ DEMOTED → BO-02** `constitutional-gate.lisp:44-45` | ▲ |
| Fail-closed constitutional evaluation | Rewrite so a rule error becomes a violation/refusal, never an allow | ◇ BO-02 *(closes P0-2 above)* | ▲ |
| Machine-checked institutional authority model | Who-may-authorize-what recomputed from genesis anchor, machine-proven | ◇ BO-02 *(admission-model.sexp spec-only, 0/17 proved)* | ▲ |
| Atomic, crash-consistent legal-artifact writer | A power loss mid-write can never leave a torn official document | ◇ BO-13 *(ABSENT today — census "sharpest hole", weakest axis)* | ▲ |
| Bounded, machine-verified crash recovery | Provable recovery to the last committed state within bounded work | ◇ BO-13 *(Perennial/Coq toolchain blocked)* | ▲ |
| Atomic multi-file / external-effect transaction | Cross-file changes + side effects commit as one, with an intent/outcome journal | ◇ BO-13 *(STORAGE-API spec present, no executable form)* | ▲ |
| Deterministic conflict-ordered parallel exec w/ atomic tier commit | Conflicting steps ordered deterministically; tier failure rolls back exactly | ◇ BO-08 *(today's parallel-executor is fail-open dead code)* | ▲ |
| External witness quorum cosigning of checkpoint heads | Even a seized single writer can't rewrite history past a cosigned point without detectable forks | ◇ BO-09 *(`witness-policy.sexp` disabled today)* | ▲ |
| Certificate-carrying accountable stall | A machine-checked progress proof per wait point; any stall emits a signed accounting certificate | ◇ BO-14 | ▲ |

### 2.6 Evolution, assurance, generality & trust model (AX-18, AX-20, AX-21, AX-22, cross-cutting)

*Several rows here are the trust-model lens on seats already tabled above; only the evolution/generality-specific ones are re-stated.*

| Capability | What a lawyer gets | Tier | Floor |
|---|---|---|---|
| Regression-proof upgrades (capability ratchet) | A guaranteed capability can't silently disappear in a later version; a downgrade is refused | ✔ `capability-gate.lisp` + `artifact-census.lisp` | ▲ |
| Architecture-map equals running code | Every declared capability must exist in code; no undocumented trusted component; drift fails the build | ✔ `architecture-gate.lisp` + `dependency-contract-consistency-test.lisp` | ▲ |
| Retired features stay retired (tombstones) | A removed entry point can't be quietly resurrected | ✔ `conditions.lisp` tombstones + `architecture-multiplicity-test.lisp` *(guarding test carries a P1 skip-on-missing-seat)* | ▲ |
| No language model in the trusted path | No AI ever decides a legal answer; a draft must pass deterministic checks as plain data | ✔ cross-cutting (all 8 census areas); `cognition.lisp` stage-1 advisory + `inference-gate.lisp` | ▲ |
| Untrusted-generator (agentic) admission gate | Any autonomous component can only submit proposals; the OS physically bars it from the store | ✔ **OS layer only** — `capability/identities.sh` + `verify-capability-closure.sh` *(the single admission predicate K is spec-only, BO-02; the referenced constitutional gate fails open, P0-2)* | ▲ |
| Offline-re-verifiable answer receipt (proof-carrying) | Result ships a portable receipt a third party re-checks offline without trusting the producer | ✔ `release-spine.lisp` + `merkle-authority.lisp` + `authority-evidence-replay.lisp` *(release/artifact class today)* | ▲ |
| Content-neutral cryptographic & receipt layer | Merkle/signature/timestamp/certificate machinery carries no jurisdiction assumptions | ✔ `transition-certificate.cddl` + `merkle-authority.lisp` + `authority-proof-bundle.lisp` | ▲ |
| Preservation-proof-gated evolution | Every previously-guaranteed property re-proven before any release ships | ◇ BO-19 | ▲ |
| Machine-checked spec-to-code proof transport | Proofs the kernel matches its spec (total, deterministic, sound) and they survive into the running code | ◇ BO-03 *(**deepest gap** — authority-v2 is 0/17 proved, toolchains blocked)* | ▲ |
| Zero-trust replay across every decision class | Every trusted decision, not just releases, recomputes bit-for-bit offline | ◇ BO-11 | ▲ |
| Assumption-tiered certificates | Every answer carries an explicit assumption tier; an unproven (T2) certificate can't serve | ◇ BO-04 | ▲ |
| Dual-mode succinct verification | Receipts stay fully recomputable (the floor); optional ~100ms mode with assumptions written down | ◇ BO-17 | ▲ |
| Provably-independent adversarial critics | Reviewers proven independent via committed prompt-closure hashes + distinct producer-ids | ◇ BO-01 | ▲ |
| Jurisdiction supplied as data, leakage build-gated | Add a legal order by supplying a data profile; any hard-coded jurisdiction assumption fails the build | ◇ BO-23 *(Greece-coupled today; "works across jurisdictions" is already commercial — only the certified no-leakage guarantee is novel)* | = |
| Verified-compiler end-to-end transport | A verified kernel so a proven property holds in the actual binary | ○ BO-24 | ▲ |

---

## 3. The headline differentiators

The claims that are **above the commercial floor** and **either executing today or design-entailed** — the real "supreme" claims. No CoCounsel / Protégé / Harvey feature does any of these, because all three keep the LLM on the trusted path.

1. **No LLM anywhere on the trusted path (executing, cross-cutting).** The whole industry's guardrails wrap an LLM that still decides. Here the model only *proposes*; every trusted decision is deterministic, re-runnable code. A hallucination structurally cannot become a trusted output. This is the trust inversion the other four sections rest on.

2. **Reproducible, recompute-and-compare grounding (executing — `authority-evidence-replay.lisp` + `merkle-authority.lisp`).** A cited quote is re-derived from the original source bytes and byte-compared; membership in the committed corpus is an O(log n) proof. The system distrusts even its own stored hashes. Commercial tools assert a citation is real; this one lets *you* recompute that it is — and the cost is corpus-size-independent.

3. **Bitemporal time-anchored receipt with exact past-time replay (executing — `legal-authority-receipt.lisp`).** Replay a past query and get the exact same authority state, to sequence equality, with anti-rollback. This is the field's *only running* past-time replay witness — no commercial product can reproduce the answer it would have given on a past date.

4. **Automatic retraction of conclusions when the law changes (executing — JTMS `inference-gate.lisp`).** Repeal or amend a provision and every dependent conclusion withdraws itself, with guaranteed termination on circular argument. Commercial engines re-run and hope; none track justification well enough to auto-retract.

5. **Un-gameable positive proof census + fail-closed manifest (executing — `verify-proof-manifest.py` + `run-proofs.sh`).** "All checks passed" is a positive artifact that exists only if the checks ran to completion; a crash produces no green. The self-check cannot lie by omission — and it honestly reports 0/17 kernel proofs done rather than faking them.

6. **Independent triple offline re-verification (executing — Python + JS + Lisp).** Three independently written verifiers must agree, so a bug or planted backdoor in any single tool cannot pass a bad release. This is the mitigation for the unverified-compiler trust link, and it runs today.

7. **Four-class total verdict algebra — no fifth "confident guess" (design-entailed, executing honest ceilings).** Every answer is PROVEN, REFUTED, STABLE-over-unknowns, or a typed I-DON'T-KNOW with a cause drawn from a closed sum type. Honesty is structural, not advisory.

8. **Decision and explanation are the same committed object (design-entailed → BO-18; executing "cannot-think-invisibly" trace).** The explanation *is* the proof object the system decided from, so it can never drift into a post-hoc rationalization — and because the trusted path is LLM-free, the trace reflects the actual computation.

---

## 4. What it cannot do / not yet

**Honest — this is a designed system with a large executing core and a real proof debt. It is not yet VERIFIED.**

**Genuine limits, today:**
- **No confidentiality axis yet.** There is no privilege/confidentiality guarantee in the trusted set; lawful erasure of client content while keeping the chain intact is unbuilt (**BO-25**).
- **Knowledge coverage is thin.** The knowledge packs cover only a few Greek norms per the census; amended codes currently carry **zero recorded amendment events**, and the citation extractor's `≤120` clamp (**P0-10**) is silently lossy beyond the Constitution.
- **The generative / agentic zone is unbuilt on the trusted side.** The untrusted-generator admission gate executes only as OS single-writer separation; the single admission predicate **K** is spec-only (**BO-02**).
- **Greece-coupled.** Multi-jurisdiction is data-driven *by design* but not running (**BO-23**); "works across jurisdictions" is something commercial LLM tools already offer — only the certified no-leakage guarantee is novel.

**Pointed defects the adversary confirmed (executing claims that are not what their title implies):**
- **The supreme constitutional gate fails OPEN today (P0-2).** The `:around` dispatch barrier is genuinely unbypassable, but `constitutional-gate.lisp:44-45` treats a rule-evaluation error as *allowed* — so an unconstitutional action whose rule throws is silently permitted. The "unbypassable constitutional gate" is **demoted to BUILD_OBLIGATION (BO-02)**; only the wrapper, not the guarantee, executes.
- **No atomic crash-consistent writer (BO-13, census "sharpest hole").** `emit-graph`/`deploy.lisp` writes are non-atomic; a mid-write crash can tear an official document. AX-15 is the weakest axis overall.
- **The deontic classifier is a ~91.5% linguistic heuristic** being retired from the trusted path; the guarantee is carried by the gate/suite machinery, not the classifier.

**Designed-but-unbuilt (the Build Obligations):** the full formal layer is essentially empty today — authority-v2 is **0/17 proved, 0/13 Level-7**, proving toolchains blocked. The deepest gap is machine-checked spec-to-code proof transport (**BO-03**). Other named obligations include the total bitemporal View (**BO-10**), atomic/crash-consistent storage (**BO-13**), plan admission (**BO-07**), certified argumentation escalation (**BO-04/05/06**), the stability + closed-UNKNOWN engine (**BO-22**), the repo-wide falsification campaign (**BO-01**), all-decision-class replay (**BO-11**), and per-step provenance (**BO-21**).

**What "VERIFIED" requires:** all **26 Build Obligations discharged, plus independent third-party reproduction.** Until then this is a system whose *executing* guarantees are the deterministic crypto/replay/JTMS core, whose *design* is entailed above the commercial floor, and whose *formal proofs and agentic trusted path remain owed.*

---

*Status: EXECUTING core is real and largely above the commercial floor (deterministic grounding, bitemporal replay, JTMS retraction, triple offline re-verification, fail-closed census) — but the supreme constitutional gate fails open today (P0-2/BO-02), the formal layer is 0/17 proved, and full VERIFIED status is gated on 26 Build Obligations plus independent reproduction; nothing here is offered as more than it is.*