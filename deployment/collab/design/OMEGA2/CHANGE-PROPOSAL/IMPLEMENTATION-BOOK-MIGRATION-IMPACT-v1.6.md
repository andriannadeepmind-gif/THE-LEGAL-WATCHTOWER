# IMPLEMENTATION-BOOK MIGRATION IMPACT — v1.6 (REPORT ONLY · Book NOT changed)

**This is a REPORT.** It records how a FUTURE Implementation-Book revision would absorb v1.6, but it does
**not** change the Implementation Book (v1.0 / v1.1 stay bound to frozen `88129099`). No file is moved now;
no WP is started; no production code changes. Parent `112379cc`. Classification: `INFORMATIVE`.

## 1. Scope of impact
v1.6 is a **specification-layer** delta. It touches the Implementation Book only as a **future migration map**:
- The existing WP-00..WP-14 keep their identity and rollback gates.
- v1.6 mostly **extends** the responsibilities of existing WPs — BUT it is honest where no existing WP owns a
  v1.6 concept: the complete **Memory taxonomy has NO owning WP** (`FUTURE BOOK REVISION REQUIRED`, §2a), and
  **WP-07's toolchain-freeze must be modified** so no model/runtime is mandatory (§2b). Each row below is
  grounded in the actual WP purpose/requirements at `IMPLEMENTATION-BOOK/WORK-PACKETS/WP-NN.md:5-6`.

## 2. Per-WP impact (future revision — NOT applied here; each WP purpose is quoted from WP-NN.md:1/5/6)
| WP | actual purpose (evidence WP-NN.md) | v1.6 impact | disposition |
|---|---|---|---|
| WP-00 | clean reproducible base + genuinely green CI (R-1..R-6, R-85..R-88, R-99/R-100) | **no v1.6 concept lands here.** `SafetyMode :SYMBOLIC_ONLY` is a *property* enforced by WP-07 (external non-authoritative neural) + WP-08 (epistemic wall), not a WP-00 bootstrap artifact | KEEP |
| WP-01 | national source/court census + coverage ledger (R-01..R-13, R-132) | census keeps `census_coverage_state` (v1.5 D2/F3); no change to totality function | KEEP |
| WP-02 | acquisition, provenance, authenticity + **Secure Semantic Ingress sandbox** (R-14..R-23, R-133) | acquisition emits `PerceptionEnvelope/1`; the **non-evaluating ingress decoder stays here** (every `SemanticProposer` feeds candidates through it); the neural runtime / model-independence itself is **WP-07**, not here | EXTEND |
| WP-03 | **typed Legal IR + bitemporal event store** (R-31..R-38) | `MemoryEvent/1` reuses `valid_time × known_time` from THIS store; WP-03 is the **only existing substrate overlapping memory** (temporal / provenance / episodic continuity). The full 13-type memory taxonomy is **NOT** owned here (see §2a) | EXTEND (substrate overlap only) |
| WP-04 | first deterministic Legal Compiler (CL, domain A) (R-40, R-43) | unchanged | KEEP |
| WP-05 | second independent compiler (Rust, domain B) + differential (R-39/R-41/R-42) | unchanged | KEEP |
| WP-06 | **MLTP v3, Trust Mesh + crypto agility** (R-57..R-70, R-130, R-134) | owns `TrustBundle/1` (WP-06.md:20 `IssuedClaim`/`TrustBundle`/`VerificationReceipt`); crypto agility + nation-state (R-134) unchanged. **NOT cognition** | EXTEND |
| WP-07 | **multimodal acquisition + external neural runtime + ontology alignment** (R-24..R-30, R-131) | **model-agnostic `SemanticProposer` replaces the "neural" framing; ONNX becomes an OPTIONAL `ONNXProposerAdapter`. The toolchain-freeze "neural = Python + ONNX Runtime" (WP-07.md:25) MUST be revised so no model/runtime is mandatory (`V6I-02`); OCR = `OCRPerceptionAdapter`.** See §2b | EXTEND (Book revision required at WP-07.md:25) |
| WP-08 | **neuro-symbolic reasoning + epistemic wall (Public Legal Discernment core)** (R-129) | **Language Cognition Layer (`LanguageCognitionLayer/1`) added INSIDE this engine (WP-08.md:19 "Deliverable 6 … composition of S3+S4+S6+S7+S9, no second engine"); `legal-casegrammar` SPLIT (general→public, client-fact→private).** Symbolic-only completeness (candidate→IR only via symbolic validation) is enforced here. **NOT proof-carrying query, NOT WP-06** | EXTEND |
| WP-09 | full jurisprudence-evolution plane (R-51..R-56) | unchanged | KEEP |
| WP-10 | National Legal Digital Twin + impact engine (R-48..R-50) | digital twin unchanged; the public→private `DeclassificationReceipt/1` is **WP-12** (R-111), not here | KEEP |
| WP-11 | **proof-carrying query API / MCP / thin SDKs + Citation-Bound** (R-44..R-47, R-71..R-73, R-101..R-110, R-119..R-124) | thin SDK / MCP adapters gain a `CapabilityManifest/1` *facet* (versioned iface, conformance). **memory is NOT owned here** (WP-11.md:16 owns `proof-carrying-answer/1`, OpenAPI, SDKs — no memory seat); see §2a | EXTEND (adapter facet only) |
| WP-12 | website, cockpit, publication + **public→private enforcement** (R-74..R-81, R-111) | cockpit gains `Plan/1`/`ActionIntent/1`/`Approval/1`/`ExecutionReceipt/1` typing (reuse L12); **public→private boundary gains `DeclassificationReceipt/1` typing (R-111 §1.3/§1.4)** | EXTEND |
| WP-13 | citation + security/operational observatory (R-82..R-84, R-93/R-95..R-98) | unchanged | KEEP |
| WP-14 | **mission-scale qualification + provider adoption** (R-112..R-118) | provider adoption / registry gains an adapter conformance/qualification facet of `CapabilityManifest/1` (shadow/canary/rollback, adoption attestations) | EXTEND (adoption facet only) |

### 2a. Memory taxonomy — `FUTURE BOOK REVISION REQUIRED` (honest: no WP fits)
The complete Memory Architecture (13 `MemoryType` × 5 `MemoryScope`, `MemoryEvent/1` + `MemoryProjection/1` +
`MemoryPolicy/1`) has **NO owning Work-Packet.** WP-11 (its former, WRONG assignment) is the proof-carrying
query API / SDK packet and owns no memory. The **only** existing substrate that overlaps is WP-03's bitemporal
event store (`valid × known`), which covers TEMPORAL / SOURCE_PROVENANCE / EPISODIC continuity **only** — not
working-context, semantic, procedural, prospective-goal, user-preference, skill or meta memory. Therefore a
future Implementation-Book revision MUST declare a memory owner (a new memory WP, or an explicit typed
extension of WP-03) before any memory construction. This pass does **not** invent that WP.

### 2b. Model independence — required WP-07 Book modification (recorded, NOT applied)
WP-07.md:25 currently freezes **"neural = Python + ONNX Runtime"** and WP-07.md:17 lists **"Python/PyTorch/ONNX"**
as the neural runtime. Under `V6I-02` (no mandatory model/runtime) these become an **optional, replaceable
`ONNXProposerAdapter`** (`:mandatory nil :canonical-write-authority nil`). The precise future edits are recorded
in §6 below; the frozen Book is **not** edited in this pass.

## 3. Deferred-private (never public dependencies)
`PrivateMatterProfile/1`, `RealTimeAssistance/1`, `EmbodimentInterfaces/1` are **DEFERRED_PRIVATE** extension
contracts. They map to **no** public WP and MUST NOT become a public-build dependency. A future private
revision would add its own WPs, consuming only signed public releases / proof-carrying interfaces.

## 4. legal-casegrammar SPLIT (file-level future migration)
`legal-casegrammar.lisp`: was `DEFER_PRIVATE` → **SPLIT**. General Greek morphology / case frames / ambiguity
detection → S04 Language Cognition Layer (shared/public). Client-fact schemas + matter-solving → S22
PrivateMatterProfile (DEFER_PRIVATE). **No second implementation**; the private layer consumes the public one.
**Not executed now** — this is a future migration instruction only.

## 6. Model-independence — the precise FUTURE modifications (RECORDED, not applied; make every proposer an optional adapter)
Every ACTIVE mandatory/pinned neural-runtime reference and the exact future edit that demotes it to an optional
replaceable adapter under `V6I-02` (verbatim current text on the left; the Book/crosswalk/matrix are **not**
edited in this pass — these are the instructions a future revision would apply under explicit creator order):

| # | location (file:line) | current text (verbatim) | FUTURE modification |
|---|---|---|---|
| 1 | `IMPLEMENTATION-BOOK/WORK-PACKETS/WP-07.md:25` | "**Toolchain freeze:** neural = **Python + ONNX Runtime** (out-of-process, PLANE-3)…" | "neural = **OPTIONAL** `SemanticProposer` adapter(s); reference adapter `ONNXProposerAdapter` (`:mandatory nil`); when absent ⇒ `SafetyMode :SYMBOLIC_ONLY` (default-safe). `WP-07-b runtime_manifest_sha256` stays an adapter **conformance** pin, not a mandatory dependency." |
| 2 | `IMPLEMENTATION-BOOK/WORK-PACKETS/WP-07.md:17` | "\| neural runtime \| **NEW** `neural-runtime/` (external, out-of-process) \| Python/PyTorch/ONNX \| NEW \|…" | "\| neural runtime \| **OPTIONAL adapter** (`ONNXProposerAdapter`/`OCRPerceptionAdapter`) \| any/none — replaceable, non-authoritative, disableable (fail-closed) \|" |
| 3 | `IMPLEMENTATION-BOOK/…-IMPLEMENTATION-BOOK-v1.1.md:118` | "\| WP-07 \| Python + ONNX Runtime (external, PLANE-3), cxml/SHACL \|…" | "\| WP-07 \| **OPTIONAL** external adapter runtime (any `SemanticProposer`; ONNX one reference impl), non-mandatory; cxml/SHACL \|" |
| 4 | `PUBLIC-OBSERVATORY-CROSSWALK.md:388` (CAP-40) | "\| CAP-40 \| εξωτερικό νευρωνικό runtime (Python/PyTorch/ONNX) \| HAS_SEAT \|…" | "\| CAP-40 \| **OPTIONAL** `SemanticProposer` adapter capability (ONNX one optional impl) \| HAS_SEAT via `ONNXProposerAdapter` (`:mandatory nil`) \|" — the crosswalk **§v1.6 note (:575)** already demotes ONNX; this makes CAP-40's own row consistent. |
| 5 | `TRACEABILITY-MATRIX.md:65` (R-32) | "\| R-32 \| … νευρωνικό runtime εξωτερικό (Python/PyTorch/ONNX ή ανώτερο) \|…" | "\| R-32 \| … **OPTIONAL** model-agnostic `SemanticProposer` (any/none); no mandatory model/runtime (`V6I-02`) \|" — falsifier `V6KW-01` already requires that removing ONNX + all proposers keep the symbolic system working. |

Rows 4 and 5 live in the **v1.4-count-bearing** blocks (`R-\d`/`CAP-` rows); they are **NOT** edited here (that
would perturb the frozen v1.4 regression). They are recorded as future modifications only. No location above is
mandatory-to-run today — every one is already framed `external / εκτός trusted path / non-authoritative /
disableable`; this pass records the exact wording that makes that OPTIONAL status categorical.

## 7. What is explicitly NOT done here
No Implementation-Book file is edited; no WP-00 start; no file moved; no production code; no refactor; no
freeze/re-freeze; no qualification claim; no v1.4-count-bearing row (`R-\d`, `CAP-`, `KW-`, `Q\d\d`) is touched.
The Book / crosswalk / matrix revisions above happen only under a future explicit creator order, after v1.6
passes independent adversarial review and (separately) a re-freeze decision.
