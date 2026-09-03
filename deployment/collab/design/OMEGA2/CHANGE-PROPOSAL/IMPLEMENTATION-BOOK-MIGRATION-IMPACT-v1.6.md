# IMPLEMENTATION-BOOK MIGRATION IMPACT — v1.6 (REPORT ONLY · Book NOT changed)

**This is a REPORT.** It records how a FUTURE Implementation-Book revision would absorb v1.6, but it does
**not** change the Implementation Book (v1.0 / v1.1 stay bound to frozen `88129099`). No file is moved now;
no WP is started; no production code changes. Parent `112379cc`. Classification: `INFORMATIVE`.

## 1. Scope of impact
v1.6 is a **specification-layer** delta. It touches the Implementation Book only as a **future migration map**:
- No new Work-Packet is created; the existing WP-00..WP-14 keep their identity and rollback gates.
- v1.6 **extends** the responsibilities of existing WPs; it does not add a WP or split the DAG.

## 2. Per-WP impact (future revision — NOT applied here)
| WP | v1.6 impact | disposition |
|---|---|---|
| WP-00 | add `SafetyState/1` + `SafetyMode :SYMBOLIC_ONLY` bootstrap as the default-safe entry | EXTEND |
| WP-01 | census keeps `census_coverage_state` (v1.5 D2/F3); no change to totality function | KEEP |
| WP-02 | acquisition emits `PerceptionEnvelope/1`; SemanticProposer plane replaces the "neural" framing; ONNX becomes an **optional** `ONNXProposerAdapter` (removed from mandatory toolchain) | EXTEND |
| WP-03 | MLTP `TrustBundle/1` + crypto agility unchanged; adapters pinned by capability manifest | EXTEND |
| WP-04 | bitemporal twin unchanged; `MemoryEvent/1` reuses `valid_time × known_time` | KEEP |
| WP-05 | dual compilers unchanged | KEEP |
| WP-06 | **Language Cognition Layer** added inside the existing engine; `legal-casegrammar` SPLIT (general→public, client-fact→private); no second engine/implementation | EXTEND |
| WP-07 | hypergraph / jurisprudence unchanged | KEEP |
| WP-08 | proof-carrying query unchanged | KEEP |
| WP-09 | ontology governance unchanged | KEEP |
| WP-10 | public→private boundary gains `DeclassificationReceipt/1` typing | EXTEND |
| WP-11 | **Memory Kernel** taxonomy (13 `MemoryType`, 5 `MemoryScope`) extended in `memory.lisp` (ONE seat) | EXTEND |
| WP-12 | cockpit gains `Plan/1`/`ActionIntent/1`/`Approval/1`/`ExecutionReceipt/1` typing (reuse L12) | EXTEND |
| WP-13 | website/observatory unchanged | KEEP |
| WP-14 | SDK/API adapters gain `CapabilityManifest/1` + shadow/canary/rollback | EXTEND |

## 3. Deferred-private (never public dependencies)
`PrivateMatterProfile/1`, `RealTimeAssistance/1`, `EmbodimentInterfaces/1` are **DEFERRED_PRIVATE** extension
contracts. They map to **no** public WP and MUST NOT become a public-build dependency. A future private
revision would add its own WPs, consuming only signed public releases / proof-carrying interfaces.

## 4. legal-casegrammar SPLIT (file-level future migration)
`legal-casegrammar.lisp`: was `DEFER_PRIVATE` → **SPLIT**. General Greek morphology / case frames / ambiguity
detection → S04 Language Cognition Layer (shared/public). Client-fact schemas + matter-solving → S22
PrivateMatterProfile (DEFER_PRIVATE). **No second implementation**; the private layer consumes the public one.
**Not executed now** — this is a future migration instruction only.

## 5. What is explicitly NOT done here
No Implementation-Book file is edited; no WP-00 start; no file moved; no production code; no refactor; no
freeze/re-freeze; no qualification claim. The Book revision above happens only under a future explicit
creator order, after v1.6 passes independent adversarial review and (separately) a re-freeze decision.
