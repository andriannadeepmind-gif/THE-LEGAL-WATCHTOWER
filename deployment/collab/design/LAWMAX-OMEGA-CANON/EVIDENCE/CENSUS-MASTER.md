# LAWMAX-Ω — CENSUS MASTER (Stage-B Assembly)

**Assembled from 15 area census reports · B0 baseline: `e621dbe1` (Area 11 notes live HEAD `803113c0`) · Assembly date 2026-08-27**

> **AX-legend notice (binding, honest-ignorance rule).** No area agent was given the AX-01..AX-22 catalog, and it was **not supplied to Stage-B either**. Every area returned `ax=[]` rather than guess. This master therefore maps leverage to **named thematic ceilings** (the recurring quality axes the census actually measured) and marks the numeric AX slot **`AX-##: unassigned`** throughout. Stage-E must overlay the real legend onto the named ceilings in §5. Nothing here is invented to fill that gap.

---

## 1. TOTALS

### 1a. Files covered per area

| # | Area | Scope | Files |
|---|------|-------|------:|
| 0 | source-a | `source/[a-c]*.lisp` | 38 |
| 1 | source-b | `source/[d-l]*.lisp` | 56 |
| 2 | source-c | `source/[m-z]*.lisp` | 39 |
| 3 | cli-1 | `systems/orchestrator-cli/` A–E | 24 |
| 4 | cli-2 | `systems/orchestrator-cli/` F–Z | 24 |
| 5 | engine-core-spec | spec + core + engine-sbcl | 41 |
| 6 | epistemic-meta | ai-core + epistemic + meta + model | 40 |
| 7 | omega-syntagma | omega-modules + gr-syntagma | 34 |
| 8 | tests-1 | `tests/` A–G | 76 |
| 9 | tests-2 | `tests/` H–Z + orchestrator-tests | 89 |
| 10 | authority-v2 | `authority-v2/` | 63 |
| 11 | determinism-ops | docker + scripts + configs + determinism | 95 |
| 12 | toplevel-contracts | root .asd/docs/workflows | 54 |
| 13 | deployment-misc | deployment/ + data + collab + input | 1680 (61 distinct + 1619 in verified homogeneous classes) |
| 14 | third-party | vendored libs | 58 |
| | **GRAND TOTAL** | | **2,411** |

Every file was read in full except Area 13's 1,619 homogeneous machine-generated files, which were verified **member-by-member by script** (schema homogeneity, prov-hash recomputation, mutant diffs) and reported as class records — see §6.

### 1b. Seats by kind — the four catalogued kinds (WRITER/GATE/STORE/PROOF)

| Kind | Count |
|------|------:|
| GATE | 69 |
| PROOF | 41 |
| WRITER | 36 |
| STORE | 23 |
| **Catalogued total** | **169** |

The remaining ~2,240 records are `lib`, `adapter`, `tool`, `config`, `contract`, `data`, `doc`, `build`, and `dead` seats (out of catalog scope per the §2 instruction), plus Area 14's 58 vendored libraries (which carry a `risk` field, not a guarantee level).

### 1c. Guarantee-level histogram — **exact, over the 169 catalogued seats**

| Guarantee | GATE | PROOF | WRITER | STORE | Total | % |
|-----------|-----:|------:|-------:|------:|------:|--:|
| VERIFIED | 42 | 23 | 2 | 7 | **74** | 43.8% |
| DETERMINISTIC_SEAT | 14 | 11 | 15 | 9 | **49** | 29.0% |
| GATED_PARTIAL | 9 | 6 | 16 | 7 | **38** | 22.5% |
| HEURISTIC_OR_LLM | 0 | 0 | 2 | 0 | **2** | 1.2% |
| ABSENT_OR_DEAD | 4 | 1 | 1 | 0 | **6** | 3.6% |

**Reading:** GATES and PROOFS are the mature strata (VERIFIED 61% and 56% respectively). WRITERS are the weakest catalogued kind — only 2/36 VERIFIED, 16/36 GATED_PARTIAL, both HEURISTIC seats, i.e. the emission/serialization layer is where the fabrication/nondeterminism/duplicate-seat debt concentrates. The 6 dead catalog seats are 4 determinism-archive no-op verifiers (`verify.lisp`/`verify.ps1` ×2 runs), `primary-anchor.lisp` (undefined functions), and `narrative-provenance.lisp` (fabricated evidence).

*All-files qualitative note (not exact — derived from area summaries):* the ~700 individually-recorded non-catalog files split the same way (a strong VERIFIED/DETERMINISTIC modern core around an older `DARPA/NSA-GRADE`-bannered stratum carrying the fail-open/fabrication/duplicate-seat defects); the ~1,619 Area-13 class files are overwhelmingly VERIFIED/DETERMINISTIC data with prov-hashes recomputed at 0 mismatches; Area 14's 58 libs are all pinned+bijective against `deps.lock`.

---

## 2. THE SEAT CATALOG

Every WRITER, GATE, STORE, PROOF seat, one row each (169 rows). Axes column is `—` (legend unavailable). Debt = highest severity on that seat.

| Path | System | Ax | Guarantee | Debt |
|------|--------|----|-----------|------|
| source/adoption-decision.lisp | self-governance | — | DETERMINISTIC | P1 wall-clock in signed ledger |
| source/ai-corpus-dump.lisp | corpus-serving | — | DETERMINISTIC | none |
| source/ai-ingest-manifest.lisp | ai-ingest | — | DETERMINISTIC | P1 cc-by-4.0 in dataset card |
| source/akoma-ntoso-emitter.lisp | corpus-serving | — | DETERMINISTIC | P2 dead ecase/otherwise |
| source/anomaly-detection.lisp | corpus-intelligence | — | DETERMINISTIC | P2 trampoline; unsourced thresholds |
| source/ast-gate.lisp | corpus-intelligence | — | DETERMINISTIC | P2 copy-pasted macrolet |
| source/authority-evidence-replay.lisp | authority-v2 | — | VERIFIED | P2 vg:: reach-through |
| source/authority-proof-bundle.lisp | authority-v2 | — | VERIFIED | P2 stringly group dispatch |
| source/capability-registry.lisp | capability | — | VERIFIED | none |
| source/components.lisp | self-model | — | DETERMINISTIC | none |
| source/consolidation-proof.lisp | consolidation | — | VERIFIED | P2 step hashes not compared |
| source/constitutional-gate.lisp | self-governance | — | GATED_PARTIAL | **P0 fail-open supreme gate** |
| source/contracts.lisp | self-model | — | DETERMINISTIC | none |
| source/corpus-fingerprint.lisp | corpus-proof | — | VERIFIED | none |
| source/corpus-intelligence.lisp | corpus-intelligence | — | DETERMINISTIC | P1 skip-blind aggregate |
| source/execution-trace.lisp | provenance | — | DETERMINISTIC | P2 no durable trace archive |
| source/guard-metaeval.lisp | inference/guards | — | VERIFIED | none |
| source/journal.lisp | persistence | — | VERIFIED | P2 append-line decomposition |
| source/knowledge-graph.lisp | self+world graph | — | GATED_PARTIAL | P1 one-sided write barrier |
| source/knowledge-packs.lisp | knowledge | — | VERIFIED | none |
| source/legal-audit-system.lisp | provenance/audit | — | GATED_PARTIAL | **P0 JWS verify wiring inoperative** |
| source/legal-authority-receipt.lisp | authority-v2 | — | VERIFIED | P2 vg:: internal access |
| source/legal-extraction-verify.lisp | ai-advisory-gate | — | GATED_PARTIAL | P2 marker tables not packs |
| source/memory.lisp | infrastructure | — | VERIFIED | P2 error-swallow in fire-intentions |
| source/narrative-provenance.lisp | infrastructure | — | ABSENT_OR_DEAD | **P0 fabricated evidence + false-green verify** |
| source/proof-carrying.lisp | infrastructure | — | VERIFIED | P1 silent signed→unsigned downgrade |
| source/proposals.lisp | infrastructure | — | GATED_PARTIAL | **P0 approve! swallows hook, journals approved** |
| source/provenance-link.lisp | infrastructure | — | DETERMINISTIC | none |
| source/review-queue.lisp | infrastructure | — | VERIFIED | P2 audit :around no-op w/o log4cl |
| source/self-history.lisp | infrastructure | — | GATED_PARTIAL | P1 non-injective '\|' hash |
| source/semantic-authority.lisp | infrastructure | — | HEURISTIC_OR_LLM | **P0 unconditional 'fully_verified' + empty⇒valid** |
| source/shacl-validator.lisp | infrastructure | — | DETERMINISTIC | P2 per-value scanner recompile |
| source/signed-embedding-manifest.lisp | infrastructure | — | HEURISTIC_OR_LLM | P1 unbounded alloc from untrusted header |
| source/static-site.lisp | infrastructure | — | GATED_PARTIAL | **P0 proofs silently omitted from published site** |
| source/timestamp-authority.lisp | infrastructure | — | VERIFIED | none |
| source/validate-ast.lisp | infrastructure | — | GATED_PARTIAL | P2 always-T sub-validators |
| source/validate-layout-graph.lisp | infrastructure | — | DETERMINISTIC | P2 severity/verdict mismatch |
| source/validate-logical-blocks.lisp | infrastructure | — | DETERMINISTIC | P2 article-sequence can't fail gate |
| source/validation-authority.lisp | infrastructure | — | GATED_PARTIAL | P1 &key/positional call crash |
| source/version-graph.lisp | infrastructure | — | VERIFIED | none |
| source/write-authority.lisp | infrastructure | — | GATED_PARTIAL | P1 ambient encoding + non-atomic emit |
| systems/orchestrator-cli/approval-policy.lisp | cli | — | DETERMINISTIC | P2 usage-string drift |
| systems/orchestrator-cli/architecture-gate.lisp | cli | — | VERIFIED | P2 lexer blind to \|…\|/#+ |
| systems/orchestrator-cli/autonomy-missions.lisp | cli | — | GATED_PARTIAL | **P0 silent loss of approved knowledge on replay** |
| systems/orchestrator-cli/capability-gate.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/component-gate.lisp | cli | — | VERIFIED | P2 private-symbol shadowing |
| systems/orchestrator-cli/constitutional-dispatch.lisp | cli | — | VERIFIED | P1 override audit can fail silently |
| systems/orchestrator-cli/content-validation.lisp | cli | — | VERIFIED | P2 duplicate normalization seat |
| systems/orchestrator-cli/contract-gate.lisp | cli | — | VERIFIED | P2 private-symbol shadowing |
| systems/orchestrator-cli/decisions.lisp | cli | — | GATED_PARTIAL | P1 silent-skip indexes + octet corruption + god-module |
| systems/orchestrator-cli/deontic-gate.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/dialogue-gate.lisp | cli | — | VERIFIED | P1 pollutes canonical episode/failure stores |
| systems/orchestrator-cli/event-gate.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/evolution-gate.lisp | cli | — | VERIFIED | P2 substring reason mapping |
| systems/orchestrator-cli/external-benchmark-gate.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/fluid-gate.lisp | cli | — | DETERMINISTIC | P2 shared PRNG special |
| systems/orchestrator-cli/gates-runner.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/generation-gate.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/golden-gate.lisp | cli | — | VERIFIED | P2 find-symbol stringly |
| systems/orchestrator-cli/inference-gate.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/iq-gate.lisp | cli | — | VERIFIED | P2 capability pkg misname |
| systems/orchestrator-cli/memory-commands.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/provenance-gate.lisp | cli | — | VERIFIED | P2 unexported internals |
| systems/orchestrator-cli/release-authority.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/release-gate.lisp | cli | — | VERIFIED | P2 stringly symbol resolution |
| systems/orchestrator-cli/subsumption-commands.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/understanding-learning.lisp | cli | — | VERIFIED | P2 regex-over-JSON read |
| systems/orchestrator-cli/verify-truth-gate.lisp | cli | — | VERIFIED | none |
| systems/orchestrator-cli/version-graph-import.lisp | cli | — | VERIFIED | P2 vg:: internal access |
| .../orchestrator-core/context.lisp | core | — | DETERMINISTIC | P2 silent initarg swallow |
| .../orchestrator-engine-sbcl/filesystem.lisp | engine-sbcl | — | DETERMINISTIC | P2 duplicate writer/temp seats |
| .../engine-sbcl/adapters/errata-boundary.lisp | engine-sbcl | — | GATED_PARTIAL | P1 silent no-errata on config fail |
| .../engine-sbcl/stages/source-normalize.lisp | engine-sbcl | — | DETERMINISTIC | P2 two source-resolution paths |
| .../engine-sbcl/stages/generate-rdf.lisp | engine-sbcl | — | DETERMINISTIC | P2 dead escaper/var |
| .../engine-sbcl/stages/consolidate.lisp | engine-sbcl | — | DETERMINISTIC | none |
| .../engine-sbcl/stages/test-escaping.lisp | engine-sbcl | — | GATED_PARTIAL | P1 sxhash sample + hardcoded id |
| .../engine-sbcl/stages/validate-shacl.lisp | engine-sbcl | — | VERIFIED | none |
| .../engine-sbcl/stages/hash-artifacts.lisp | engine-sbcl | — | DETERMINISTIC | P2 misdocumented algorithm |
| .../engine-sbcl/stages/anchor-blockchain.lisp | engine-sbcl | — | GATED_PARTIAL | P1 configured-chain fail warn-and-continue |
| .../engine-sbcl/stages/deploy.lisp | engine-sbcl | — | DETERMINISTIC | P1 error path errors (bad initarg) |
| .../engine-sbcl/stages/deploy-epistemic.lisp | engine-sbcl | — | GATED_PARTIAL | **P0 warn-only terminal validation (false-green)** |
| .../orchestrator-ai-core/ingest-manifest.lisp | ai-core | — | DETERMINISTIC | P1 mis-scoped restart truncates manifest |
| .../orchestrator-ai-core/provenance-model.lisp | ai-core | — | DETERMINISTIC | P1 synthesized uniform timestamps |
| .../orchestrator-epistemic/meta-ontology.lisp | epistemic | — | DETERMINISTIC | P2 hand format-string ontology |
| .../orchestrator-epistemic/lineage-authority.lisp | epistemic | — | DETERMINISTIC | P1 synthetic genesis + pending anchors |
| .../orchestrator-epistemic/negation-layer.lisp | epistemic | — | DETERMINISTIC | P2 misspelled canonical IRI |
| .../orchestrator-epistemic/stability-policy.lisp | epistemic | — | DETERMINISTIC | P2 hand version/date |
| .../orchestrator-epistemic/authority-boundary.lisp | epistemic | — | VERIFIED | P2 marker reuse no content check |
| .../orchestrator-epistemic/primary-anchor.lisp | epistemic | — | ABSENT_OR_DEAD | **P0 undefined hash fns in L1 anchor** |
| .../orchestrator-epistemic/release-manifest.lisp | epistemic | — | GATED_PARTIAL | **P0 fabricated stats + CC0 in canonical manifest** |
| .../orchestrator-epistemic/artifact-census.lisp | epistemic | — | VERIFIED | P2 ungated ~D fields |
| .../orchestrator-epistemic/transparency-log.lisp | epistemic | — | VERIFIED | P1 error-swallow in chain walker |
| .../orchestrator-epistemic/release-spine.lisp | epistemic | — | VERIFIED | none |
| .../orchestrator-epistemic/shacl-shapes.lisp | epistemic | — | GATED_PARTIAL | P1 shapes contradict shipped artifacts |
| .../orchestrator-epistemic/deploy-epistemic.lisp | epistemic | — | GATED_PARTIAL | **P0 silent signing-key path substitution** |
| .../orchestrator-meta/registry.lisp | meta | — | GATED_PARTIAL | **P0 empty duplicate pipeline registry serves false answers** |
| .../orchestrator-meta/reports.lisp | meta | — | GATED_PARTIAL | **P0 malformed JSON + undeclared core dep** |
| .../orchestrator-model/article.lisp | model | — | VERIFIED | P2 stale hash-name doc |
| .../orchestrator-model/normalized-input.lisp | model | — | GATED_PARTIAL | P1 silent lossy heuristics in sealed text |
| .../orchestrator-model/corpus.lisp | model | — | VERIFIED | P2 languages replace-not-union |
| .../orchestrator-model/artifact.lisp | model | — | GATED_PARTIAL | P1 hash API ignores requested algorithm |
| .../orchestrator-omega-modules/greek-law-types.lisp | omega | — | DETERMINISTIC | P2 runtime exports |
| .../omega-modules/article-root-generator-omega.lisp | omega | — | DETERMINISTIC | P1 unescaped literal in RDF |
| .../omega-modules/prov-activity-generator-omega.lisp | omega | — | DETERMINISTIC | P2 escaping bypass |
| .../omega-modules/work-generator-omega.lisp | omega | — | GATED_PARTIAL | P1 conditionally-invalid Turtle + dup escaper |
| .../omega-modules/expression-generator-omega.lisp | omega | — | GATED_PARTIAL | P1 divergent normalization in one artifact |
| .../omega-modules/manifestation-generator-omega.lisp | omega | — | GATED_PARTIAL | P1 conditionally-invalid Turtle |
| .../omega-modules/format-generator-omega.lisp | omega | — | GATED_PARTIAL | P1 conditionally-invalid Turtle |
| .../omega-modules/frbr-consistency-validator.lisp | omega | — | GATED_PARTIAL | P1 Constitution-hardcoded gate |
| .../omega-modules/unified-frbr-generator.lisp | omega | — | GATED_PARTIAL | **P0 wall-clock in canonical artifact + text-surgery** |
| .../omega-modules/corpus-root-generator.lisp | omega | — | GATED_PARTIAL | **P0 silently fabricated provenance attribution** |
| .../omega-modules/hybrid-generator-phase1.lisp | omega | — | GATED_PARTIAL | P1 wrong ODRL target non-syntagma |
| .../omega-modules/html-rdfa-generator.lisp | omega | — | GATED_PARTIAL | **P0 redefines production escape-html seat** |
| tests/architecture-multiplicity-test.lisp | arch-constitution | — | VERIFIED | P1 SKIP-on-missing-seat silent green |
| tests/dependency-contract-consistency-test.lisp | deps governance | — | VERIFIED | none |
| tests/hash-seat-registry-test.lisp | audit | — | VERIFIED | P2 SKIP-exit-0 on missing seat |
| tests/kernel-conformance-test.lisp | kernel↔merkle | — | VERIFIED | P2 brittle entrypoint-skip loader |
| tests/legal-identity-test.lisp | identity | — | VERIFIED | none |
| tests/level7-disarm-test.lisp | epistemic/cli | — | VERIFIED | P2 cwd/LAWMAX_REPO dependence |
| tests/merkle-single-truth-test.lisp | merkle+governance | — | VERIFIED | P2 two concerns + embedded JSON reader |
| tests/param-type-coercion-test.lisp | capability | — | VERIFIED | none |
| tests/param-type-roundtrip-test.lisp | capability-api | — | VERIFIED | P2 SKIP-exit-0 |
| tests/reader-census-test.lisp | reader governance | — | VERIFIED | P1 cwd-rooted scan → green on 0 files |
| tests/release-vector-conformance-test.lisp | epistemic+verify | — | GATED_PARTIAL | P2 env-conditional halves |
| tests/temporal-semantics-test.lisp | version-graph | — | VERIFIED | P2 monolith w/ cross-section state |
| tests/temporal-verifier-test.lisp | version-graph+verify | — | GATED_PARTIAL | P2 fixed /tmp vectors path |
| authority-v2/LEVEL7-COMPLETION-MATRIX.sexp | authority-v2 | — | GATED_PARTIAL | P2 snapshot staleness |
| authority-v2/proof-manifest.sexp | authority-v2 | — | GATED_PARTIAL | none (0/17 proved, honest) |
| authority-v2/proofs/verify-completion-matrix.py | authority-v2 | — | DETERMINISTIC | P2 duplicated sexp parser |
| authority-v2/proofs/verify-proof-manifest.py | authority-v2 | — | DETERMINISTIC | P2 duplicated sexp parser |
| authority-v2/run-proofs.sh | authority-v2 | — | DETERMINISTIC | P2 setup diagnostics discarded |
| authority-v2/proofs/capture-adversarial-test.py | authority-v2 | — | DETERMINISTIC | P2 unclosed test anchors |
| authority-v2/proofs/capture-mountpoint-test.sh | authority-v2 | — | DETERMINISTIC | none |
| authority-v2/proofs/capture-mutation-witness.py | authority-v2 | — | DETERMINISTIC | none |
| authority-v2/proofs/capture-seat-differential-test.sh | authority-v2 | — | DETERMINISTIC | none |
| authority-v2/proofs/delta23-evidence-bundle.sh | authority-v2 | — | DETERMINISTIC | P2 inner boundary not tallied |
| authority-v2/proofs/docker-e2e-test.sh | authority-v2 | — | GATED_PARTIAL | P1 load-bearing E2E unexecuted |
| authority-v2/proofs/gate-negative-fixtures.py | authority-v2 | — | DETERMINISTIC | P2 literal-string anchors |
| authority-v2/proofs/producer-os-boundary-test.sh | authority-v2 | — | DETERMINISTIC | none |
| authority-v2/proofs/producer-topology-test.py | authority-v2 | — | DETERMINISTIC | P2 dead corpora param |
| authority-v2/proofs/proof-census-adversarial-test.py | authority-v2 | — | DETERMINISTIC | none |
| authority-v2/proofs/verify-capability-closure.sh | authority-v2 | — | DETERMINISTIC | none |
| authority-v2/proofs/witness-quorum-test.py | authority-v2 | — | GATED_PARTIAL | P1 tests local model w/ duplicated constants |
| docker/run-standalone-suites.sh | proof-chain | — | VERIFIED | none |
| docker/verify-deps.lisp | supply-chain | — | VERIFIED | none |
| docker/verify-proof-manifest.py | proof-chain | — | VERIFIED | none |
| scripts/gen-merkle-truth.lisp | merkle-single-truth | — | VERIFIED | none |
| scripts/merkle-mutation-witness.sh | proof-chain | — | VERIFIED | none |
| scripts/verify-runtime-closure.sh | supply-chain | — | VERIFIED | P2 coexists w/ contradictory dead schema |
| determinism/run1/latest/verify/verify.lisp | release-archive | — | ABSENT_OR_DEAD | **P0 unconditional-pass verifier** |
| determinism/run1/latest/verify/verify.ps1 | release-archive | — | ABSENT_OR_DEAD | **P0 unconditional-pass verifier** |
| determinism/run2/latest/verify/verify.lisp | release-archive | — | ABSENT_OR_DEAD | **P0 unconditional-pass verifier** |
| determinism/run2/latest/verify/verify.ps1 | release-archive | — | ABSENT_OR_DEAD | **P0 unconditional-pass verifier** |
| .github/workflows/docker-orchestrator.yml | CI | — | VERIFIED | P1 unsigned auto-tags mint releases |
| deployment/verify/verify.py | verify-kit | — | VERIFIED | none |
| deployment/verify/verify.mjs | verify-kit | — | VERIFIED | P2 missing bad-exponent guard |
| deployment/verify/verify-merkle.py | merkle-single-truth | — | VERIFIED | none |
| deployment/verify/verify-merkle.mjs | merkle-single-truth | — | VERIFIED | none |
| deployment/verify/verify-release.py | release-spine | — | VERIFIED | none |
| deployment/verify/kernel-verify.lisp | release-spine | — | VERIFIED | P2 %pad duplicate (declared) |
| deployment/verify/verify-canonical.py | canonical-repr | — | VERIFIED | none |
| deployment/verify/verify-temporal.py | temporal-identity | — | VERIFIED | none |
| deployment/verify/verify-authority-bundle.py | apb | — | VERIFIED | P1 signatures/replay single-impl |
| deployment/verify/assess-gate-plenary.sh | cli/CI | — | VERIFIED | P2 GATE_PLENARY_EXPECT never bound |
| deployment/verify/assess-gate-manifest.lisp | cli/CI | — | VERIFIED | none |
| deployment/self/history.sexp | self-history | — | DETERMINISTIC | P2 seed-vs-runtime not stated in-file |
| state/fek-api.json | cli/fek | — | DETERMINISTIC | P2 split state seat |
| state/fek-listing.json | cli/fek | — | DETERMINISTIC | P2 split state seat |
| state/fek-last-seen.txt | cli/fek | — | DETERMINISTIC | P2 split state seat |

---

## 3. DEBT REGISTER (ranked, deduplicated)

### P0 — load-bearing defects (fix first)

Grouped where the same defect class recurs across files (deduplicated); each item gives **path(s) · defect · exact change**.

**P0-1 · False-green / fabricated-evidence emitters (single largest class).**
- `source/narrative-provenance.lisp` — emits fabricated reviews/tx-hash/IPFS-CID/QES serials as genuine RDF; `verify-provenance-chain` returns T on empty. **Change:** DELETE, or rewrite to emit only real journaled events.
- `source/semantic-authority.lisp` — `write-verification-chain` emits `overallStatus "fully_verified"` unconditionally; `verify-authority-chain` returns T on empty. **Change:** emit only verifiable fields (extend the [P1.5-A] cleanup) or delete in favor of corpus-provenance.
- `systems/orchestrator-epistemic/release-manifest.lisp` — `void:triples = N×50`, `void:properties = 25`, `totalArtifacts = N×4+10` fabricated; `dcterms:license` hardcoded CC0. **Change:** count real triples or emit honest nulls; license from a policy seat; deterministic default timestamp.
- `.github/workflows/provenance.yml` — release notes print "✅ canonical / signed / OpenTimestamps" over all-optional steps. **Change:** make notes reflect actual step outcomes; fix license line; reconcile with `release-authority` as the one release seat.
- `determinism/run{1,2}/latest/verify/verify.lisp` + `verify.ps1` (4 files) — every gate is a TODO; prints "✓ ALL VERIFICATIONS PASSED" and returns t. **Change:** DELETE; the modern `deployment/verify/*` are the real seats.
- `configs/huggingface-dataset.json`, `examples/benchmark-results.json`, `examples/citation-embeddings-report.json`, `source/ai-citation-strategy.lisp` — fabricated metrics/DOIs presented as measurements. **Change:** DELETE (retired/orphaned exporters).

**P0-2 · Fail-open handlers in trusted paths.**
- `source/constitutional-gate.lisp:44-45` — erroring constitutional rule ⇒ action allowed. **Change:** rewrite `evaluate` so a rule error is a named violation (fail-closed) or a visible `:indeterminate` routed to the creator.
- `source/proposals.lisp` `%transition` — `on-approve` hook error swallowed, status still journaled `approved`. **Change:** hook failure must abort or record `:approved-with-failed-hook`, never silent success.
- `systems/orchestrator-cli/autonomy-missions.lisp:49-51` — approved norm-classification that fails to register on replay vanishes silently. **Change:** counted/reported failures + exported `orchestrator.proposals:replay-approved!`; red on any loss.
- `systems/orchestrator-cli/graph-import.lisp` `%graph-import-citations` — per-corpus citation-edge import errors swallowed to nil. **Change:** counted, printed per-corpus failure the caller surfaces.
- `systems/orchestrator-cli/ingestion-commands.lisp` `%read-laws-json` — corrupt-but-present AMENDMENT_LAWS_JSON read → nil → store silently erased on rewrite. **Change:** fail loudly on unreadable-present file (missing⇒nil is fine).
- `systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp` — terminal `validate-epistemic-stage` failure is warn-only, stage returns success. **Change:** signal `validation-error` instead of warning.
- `systems/orchestrator-epistemic/deploy-epistemic.lisp` — env `PRIVATE_KEY_PATH`/`RELEASE_CERT_PATH` containing `..`/`~` silently replaced by defaults → trust-root substitution. **Change:** error (not silent default) on rejected key paths.
- `source/static-site.lisp` — `%emit-corpus-proofs` silently skips all proofs if `find-symbol` misses, though JSON-LD promises them. **Change:** missing proof functions must ERROR; replace find-symbol wiring with imports.
- `authority-v2/capture/capture.py` `_mount_id()` — swallows OSError/ValueError → None, and `reverify` passes None==None (silent degradation of one identity check). **Change:** refuse with `'mount-id-unavailable'`.
- `.gitignore` — `deployment/self/proposals.sexp.*  # comment` — inline comment makes the pattern literal and inert; runtime sidecar/lock state can be committed. **Change:** move the comment to its own line.

**P0-3 · Broken / inoperative trusted seats.**
- `source/legal-audit-system.lisp:549-551` — `verify-jws` called with wrong arity/keyword; `sign-entry` stores the plist not the `:jws` string → crypto verification can never succeed. **Change:** store `(getf (sign-jws …) :jws)`; call `(verify-jws sig content key-path)`; CSPRNG UUID; route time through `orchestrator.time`.
- `systems/orchestrator-epistemic/primary-anchor.lisp` — calls `compute-sha256-file`/`compute-sha256-string` defined nowhere; every L1-anchor construct/verify path is a runtime undefined-function error. **Change:** rewrite hash calls to `orchestrator.hash-authority`/`orchestrator.merkle`; add a regression test.
- `systems/orchestrator-engine-sbcl/adapters/html-parliament-adapter.lisp` — `#+cxml-stp` never on `*features*` → "primary" CXML parser permanently dead, regex fallback always silently used. **Change:** feature detection via `find-package`, or delete the dead path (keep the live crawler in a small file).
- `systems/orchestrator-meta/reports.lisp` — `jonathan:to-json … :from :alist` on plist data (malformed JSON array output) + reads `orchestrator.core` without an .asd dep. **Change:** `:from :plist`; declare the core dependency; deterministic timestamp.
- `systems/orchestrator-meta/registry.lisp` — meta pipeline-registry is a second, never-written seat that the CLI reads → false "no pipelines". **Change:** delete pipeline/backend registries, point listings at the spec seat.
- `text-canonicalizer.lisp` — `\x{0384}` inserted literally by cl-ppcre into leaf-hashed canonical text. **Change:** literal-char replacement; bound the section-header regexes; implement or rename the NFC step. *(Reported P0-class in the canonical text path.)*

**P0-4 · Determinism violated in the identity/artifact path.**
- `systems/orchestrator-omega-modules/unified-frbr-generator.lisp` — wall-clock activity timestamp serialized into canonical `.ttl` when deterministic mode is off, plus fragile string-surgery activity linkage. **Change:** pass activity URI into generators (dynamic var); require `:deterministic` time for the serialized timestamp.
- `determinism/run{1,2}` archive — release identity (merkleRoot, systemCommitHash) is built from live wall-clock; identical corpus 57s apart → different roots. **Change:** single injected `SOURCE_DATE_EPOCH` timestamp in the emitter; delete/regenerate the broken snapshots.

**P0-5 · Fabricated provenance attribution.**
- `systems/orchestrator-omega-modules/corpus-root-generator.lisp` — `prov:wasAttributedTo` silently defaults to hardcoded `…/agent/greek-parliament` on missing config. **Change:** `authority_uri` must be required-config (no silent default); escape titles.

**P0-6 · One-seat law violated by contradictory duplicate seats.**
- `source/reasoning-authority.lisp` vs `source/rdfs-inference.lisp` — two full RDFS engines with divergent triple representations, both loaded, in a legal-inference path. **Change:** port OWL-RL rules onto `rdfs-inference`'s KB; delete `reasoning-authority`.

**P0-7 · Operational / supply-chain (docker area).**
- `docker-compose.yml` — (a) tmpfs `/tmp:size=256m,mode=1777"` stray quote → orchestrator service cannot start; (b) healthcheck targets committed `/app/output/.healthy` on a `:ro` mount → permanently green. **Change:** drop the stray quote; point healthcheck at `/run/lawmax/.healthy` (tmpfs), matching the Dockerfile.
- `docker/sbom.json` — hand-written SBOM with false license (MIT/CC0 vs All-Rights-Reserved), pdfminer listed though Python removed, 19 of ~60 packages, wrong SBCL version — bound into the runtime image hash. **Change:** generate the SBOM from `deps.lock` + the closure artifact at build time.

**P0-8 · Contract seats asserting false grants.**
- `SEMANTIC-CONTRACT.md` — declares "CC BY 4.0" (LICENSE is All-Rights-Reserved) and points verification at scripts that do not exist. **Change:** reissue under All-Rights-Reserved; point every command at real seats; fix repo URLs.
- `PROVENANCE.yaml` — a second, fictional provenance seat (all placeholder fields, references nonexistent scripts, CC-BY). **Change:** delete or make it the config the real `--cut-release`/`--attest-release` seats read.

**P0-9 · Stale duplicate of a trusted corpus in the rule-book tree.**
- `deployment/data/syntagma_clean.zip` — unreferenced alternate `syntagma_clean.json` with divergent per-article `date` metadata (1986 vs 1975), inside read-only `deployment/`. **Change:** DELETE (creator approval) or move to an archive with a prov note.

**P0-10 · Hardcoded corpus clamp silently dropping data.**
- `source/citation-authority.lisp:224` — drops any cited article number > 120 (constitution-sized clamp); fixnum node typing excludes lettered articles (100Α) → silently wrong for Penal Code (536) and every larger corpus. **Change:** take corpus size from the document; accept string article identities; delete the dead pattern table.

**P0-11 · False-green archival "proof".**
- `source/archive-authority.lisp` — prints "✓ Archived" and records `:success` from the raw HTTP call without validating the Wayback response; binary responses become garbage `archived-url` recorded as 100-year proof. **Change:** parse Content-Location/timestamp from the SPN response, signal `submission-failed`, mark unverified results explicitly.

**P0-12 · Tracked open fail-open verifiers (documented, unfixed).**
- `docs/SECURITY-REDTEAM.md` O-2 (`timestamp-authority` accepts any ASN.1 blob; blockchain verify checks only HTTP 200) and O-4 (`fetch_cmd → sh -c` RCE-by-design). **Change:** owned by the named source authorities — verification theatre in the time/anchor stack must be made cryptographic.

*(Not P0 in this master: `orchestrator-core/parallel-executor.lisp` is fail-open **only if live** — it is dead code and covered under §4 A3/dead-code.)*

### P1 — high-value defects (by area, path · defect · change)

- `source/adoption-decision.lisp` — wall-clock in signed ledger → route through `orchestrator.time`.
- `source/ai-ingest-manifest.lisp` — cc-by-4.0 in dataset card → strip until license decision.
- `source/blockchain-authority.lisp` — tx "success" on confirmation timeout; ipfs errors→nil → return `:unconfirmed`; distinguish error vs unconfigured.
- `source/canonical-representation.lisp` — JCS non-conformance (float format + key order) → RFC 8785 number serialization + UTF-16 key order, or structurally forbid floats in signed payloads.
- `source/cognition.lisp` — vacuous default verification → default `execute-step` returns `:unverified`; log classifier errors.
- `source/corpus-diff.lisp` — deleted articles silently absent from diff → iterate both maps.
- `source/corpus-intelligence.lisp` — crashing check ⇒ "clean" → surface `:skipped` count as not-fully-verified.
- `source/corpus-provenance.lisp` — silent fabricated epoch timestamp → omit or fail-closed on malformed date.
- `source/corpus-service.lisp` — HTTP 200 with error body on `/diff /search /sparql` → return 400 for missing params.
- `source/deterministic-time.lisp` — silent wall-clock fallback in `:deterministic` + triple API → collapse legacy API; make `:deterministic` error.
- `source/embeddings-authority.lisp` — exported dead API + "authority" misnames trust → split live client, delete dead cluster.
- `source/greek-lemmatizer.lisp` — lossy guesser exported + silent collision → retire `lemmatize-greek`; detect collisions at registration.
- `source/greek-nlp-core.lisp` / `greek-tokenizer-advanced.lisp` — duplicate/triple NLP + tokenizer seats → unify behind one protocol.
- `source/injection.lisp` — dead DI container with load-time side effect → delete or declare test scaffolding.
- `source/knowledge-graph.lisp` — one-sided Self/World write barrier → enforce `layer-writable-p` on both endpoints.
- `source/legal-deontic.lisp` — 2-pass (not fixpoint) norm application under-derives deep chains → iterate to fixpoint or declare+gate the bound.
- `source/legal-knowledge.lisp` — greedy second join contradicts the engine's exhaustive join → implement `satisfy-patterns` over `match-patterns`.
- `source/json-emit.lisp` — declared JSON-escape unification unfinished (3 stray escapers) → finish migration.
- `source/lexicon-neurolingo.lisp` — fail-open validation (warn on checksum mismatch) → fail-closed or delete.
- `source/eu-interop-layer.lisp` — fail-open ELI validation + dead-on-use API under a production banner → delete or full rewrite behind a dormant flag.
- `source/government-source.lisp` — SSRF via `:redirect 5` auto-follow (guard only checks first URL) → disable auto-redirect, route through per-hop guarded fetch.
- `source/mcp-server.lisp` — wrong-package guard + hardcoded corpus-list fallback → fix spec/cli package mismatch.
- `source/paths.lisp` — traversal containment skipped for not-yet-existing targets → enforce containment on non-existent paths.
- `source/pdf-authority.lisp` — silent empty-page placeholder on layout failure → fail-closed or return declared per-page failures.
- `source/proof-carrying.lisp` — silent signed→unsigned downgrade when signing throws → error when a key is configured.
- `source/rdfs-inference.lisp` — duplicate RDFS seat + warn-then-incomplete closure → fold in reasoning-authority, delete twin.
- `source/review-service.lisp` — page-embedded token is the only mutation auth → CSPRNG token; direct package imports.
- `source/self-history.lisp` — non-injective `|` hash → move to `journal:canon-sexp`.
- `source/semantic-versioning-system.lisp` — silent no-op diff stubs + fixed-position version parsing → implement/delete; delegate identity/time to version-graph.
- `source/signed-embedding-manifest.lisp` — unbounded allocation from untrusted `.embedding` header → bound dim/sig-len on load.
- `source/trace-core.lisp` — `validate-trace-chain` always-T false-green → make it able to fail or rename; route time through the seat.
- `source/write-authority.lisp` — ambient encoding + non-atomic emit → explicit UTF-8 + atomic write via `journal:write-file-atomic`.
- `cli/constitutional-dispatch.lisp` — override biography record `ignore-errors`'d → verify with `require-durable!` or refuse the override.
- `cli/dialogue-gate.lisp` — pollutes canonical episode/failure stores each plenary → bind stores to scratch files for the M1 block.
- `cli/cognition-legal.lisp` — "Καταγράφηκε" asserted while `%lesson` write can silently fail → verified read-back discipline.
- `cli/config-loader.lisp` — dead duplicate YAML-config seat → DELETE (file + .asd entry + export).
- `engine-sbcl/adapters/errata-boundary.lisp` — `ignore-errors` on config → silent zero errata; report-only stale handling → drop `ignore-errors`; signal typed `erratum-not-applied`.
- `engine-sbcl/adapters/pdf-adapter.lisp` — advisory-only codification gate + global mutable parser state → thread state through the struct; make the gate fail-closed.
- `engine-sbcl/adapters/raw-text-adapter.lisp` / `stages/test-escaping.lisp` — wall-clock trace-id in IIR metadata; sxhash sampling + hardcoded pipeline id/version → deterministic trace-id/sample; read identity from context.
- `engine-sbcl/stages/deploy.lisp` — `validation-error` constructed with undefined `:details` initarg (errors on the error path) → add slot or drop.
- `engine-sbcl/stages/anchor-blockchain.lisp` — configured-chain failure warn-and-continue + wall-clock in article metadata → fail/declare-degraded; deterministic timestamp.
- `orchestrator-model/normalized-input.lisp` — silent lossy FEK-noise/dehyphenation inside the sealed-text seat → move to adapters or make removals reported+bounded.
- `orchestrator-model/artifact.lisp` — `artifact-hash` silently ignores requested algorithm; `/tmp`+wall-clock serializer → honor/reject via hash-authority; delete `/tmp` path.
- `orchestrator-ai-core/ingest-manifest.lisp` — mis-scoped restart writes blank NDJSON line, truncates manifest, reports success → per-iteration restart or delete.
- `orchestrator-ai-core/provenance-model.lisp` / `epistemic/lineage-authority.lisp` — "provenance/lineage" synthesizes uniform build-time timestamps + "pending" anchors as identity-bound facts → record real events or rename honestly.
- `epistemic/transparency-log.lisp` — chain walker swallows corrupt-census parse errors as chain-genesis → typed error for unreadable ancestor.
- `epistemic/shacl-shapes.lisp` — shapes require `ctProof`/integer `eli:number` that contradict shipped artifacts → regenerate from current truth + add a CI check.
- `epistemic/vocabularies.lisp` — vocabulary truth split across a dead table and a live format string → generate ontology from the tables.
- `meta/queries.lisp` — `describe-pipeline` structurally always NIL (reads the dead registry) → retarget to spec seat.
- `meta/tool-versions.lisp` / `meta/package.lisp` — duplicate `2.0.0` version constant; package co-owned by a foreign stub → version from `spec:+version+`; evict foreign symbols.
- `orchestrator-model/metaclasses.lisp` — latent mis-designed validation hook + large dead MOP surface → keep bare metaclass tags, delete/rebuild validator machinery per-slot.
- omega generators (`article-root/work/expression/manifestation/format/hybrid`, `frbr-consistency-validator`) — unescaped literals, ODRL-gated terminator → conditionally-invalid Turtle, divergent normalization, Constitution-hardcoded gate → unconditional terminators; all literals through `canonical-literal`; prefix/gate from the corpus under validation.
- `tests/architecture-multiplicity-test.lisp`, `tests/reader-census-test.lisp` — SKIP-on-missing-seat and cwd-rooted scan go silently green → hard-fail inside the gated build; anchor root via `*load-truename*`.
- `tests/authority-cross-language-test.lisp` — runs `python3` in the SBCL-only stage on an undeclared transitive dep → add `%which` guard + honest SKIP + hard re-run in verifier-conformance stage.
- `tests/comparison-test.lisp` — declared-excluded but no runner and no reference artifact exist (dead) → delete or rewrite as a committed-vector gate.
- `authority-v2/proofs/docker-e2e-test.sh`, `witness-quorum-test.py` — load-bearing E2E unexecuted; quorum test proves a local model with duplicated constants → read constants from `witness-policy.sexp`; declare the evaluator a model.
- `authority-v2/toolchain/perennial.Dockerfile` — unblock path incomplete past pin gate (no store Makefile, unused COQ_VERSION) → add scaffolding or mark placeholder.
- `authority-v2/tests/probe-attest-refusal.lisp`, `probe-producer-under-uid.lisp` — orphaned, stale, semantically inverted probes → DELETE + census lines.
- Dockerfile — `Dockerfile.test` non-hermetic Quicklisp network install; stage-3 "test" near-no-op; inline shell SBOM/manifest generator → vendor fiveam; gate/split stage-3; move manifest gen to a checked script.
- `configs/constitution.yaml`, `configs/poinikoskodikas.yaml` — article_count 120≠124 contradiction; aspirational dead blocks; zero amendment events for amended codes → fix count, strip dead blocks, record amendment events.
- Root `deps/closure-schema.json` — contradictory dead schema that rejects the artifact it governs → rewrite to the `verify-runtime-closure.sh` contract or delete.
- `docs/IMPLEMENTATION-COMPLETE.md`, `docs/ELI-IMPLEMENTATION-PHASES.md`, `MANUAL-STEPS-HERMETIC.md`, `CHANGELOG.md`, `README.md`, `DEPENDENCY-CONTRACT.md`, `DEPLOY-PRODUCTION.md`, `RUN-DOCKER.md` — dead file references, MIT footers, stale trees/counts, dead commands → move to `docs/history/`, fix license footers, machine-lock the tables.
- `orchestrator.asd` vs `orchestrator-core-runtime.asd` — duplicate umbrella seats + dead upstream URLs → merge into one.
- `orchestrator-infrastructure.asd` — 140-file `:serial t` monolith, order-by-comment → split into ~5 systems with `:depends-on`.
- `orchestrator-tests.asd` — `:perform` test-op clause outside the defsystem form (not attached) → move it inside.
- `orchestrator-omega.asd` — dangling `orchestrator-omega/tests` test-op + global optimize proclaim → delete/define; per-file declaims.
- `entrypoint.lisp` (root) — dead duplicate entrypoint with nonexistent paths, still COPY'd → DELETE.
- `deployment/verify/ontology-raw-live-dump.sexp` — orphan, stale second self-description (19 gates vs 24) → delete or regenerate under a generator+test.
- `deployment/verify/vectors/README.md` + `build-vectors.lisp` — false "committed test-key" determinism claim (keys are gitignored) → fix claim or force-add fixture keypair.
- `input/decisions/ap-2024-*.txt` (18 files) — convention-violating, unprocessed → rename to `areios-pagos/ap_2024_N.txt` and ingest (silent 2024 coverage gap).
- Third-party: dual-seat JSON (`jonathan` vs `yason`, migration stalled); `static-vectors` orphan; empty `deps.archives.lock`; hermeticity overstatement (libyaml/libssl/libpoppler C ABIs unpinned) → finish yason migration + retire jonathan's 5 legacy libs; delete/declare orphans; pin C-side or amend the claim.
- `authority-v2/kernel/admission-model.sexp`, `store/STORAGE-API.sexp` — load-bearing kernel/store are specs with no executable form (accepted ledgered blockers, F*/Coq) → progress the blocked toolchains.

### P2 — count-only summary (deduplicated, grouped by class)

P2 count is **assembled from the individual records** (exact per-file P2s were not all separately tallied by every area; the counts below are the assembler's grouped totals over the reported P2 debts, ≈ **185–205 items**). Grouped by recurring class:

| P2 class | Approx. count | Representative sites |
|----------|--------------:|----------------------|
| Duplicate/weaker escaping & JSON seats | ~14 | `ai-corpus-dump`, `corpus-diff`, `corpus-eu-links`, `corpus-search`, `legal-qa`, `gov-source`, omega `format-literal`, `mcp/proof-carrying/review-service/static-site %json-string`, three TTL-literal escapers |
| `find-symbol`/`::` stringly cross-package coupling | ~18 | golden/release/provenance gates, `legal-references`, `ingestion-daemon`, `static-site`, omega generators, version-graph-import |
| Stale docs/comments/headers vs current tree | ~20 | `docker/BUILD-ISSUES.md`, `IMPLEMENTATION-SUMMARY.md`, `SYSTEM-HIERARCHY.txt`, `docs/BRAIN.md`, `escape-sequences-test` header, `greek-lemmatizer` header, `reasoning-authority` "not loaded" |
| Copy-pasted test harness / macrolet (one-seat) | ~8 | ~60 `check` macro clones, `%`-accessor macrolet ×3, `suite.lisp` twin runners |
| Untyped bare-error where a typed condition is the ceiling | ~10 | `canonical-uris`, `hash-authority`, builders, model constructors, `write-authority` |
| Hand-written / divergent version seats | ~7 | `main.lisp` 1.2.0 vs .asd 0.9.0, `spec/version.lisp`, `tool-versions` 2.0.0, dataset-version 1.3.0, html footer v1.2 |
| SKIP-exit-0 / silent-green on missing seat | ~5 | `architecture-multiplicity`, `deps-hash`, `json-emit`, `safe-read`, `param-type-roundtrip` tests |
| Severity/verdict mismatches in validators | ~6 | `validate-ast`, `validate-layout-graph`, `validate-logical-blocks`, layout/logical gates |
| Split state / dead constants / dead params | ~10 | `state/*` vs `deployment/state`, `circuit-breaker` dead consts, `producer-topology` dead param |
| Determinism-archive Lisp-print-leak inclusion proofs & JSON keys | ~16 | `determinism/run{1,2}/temporal-proof/inclusion-proofs/*.json` |
| Misc (thresholds, monoliths, non-atomic writes, doc/enforcement gaps) | ~70 | remainder across all areas |

---

## 4. GATE-#1 CHECK RESULTS (consolidated)

### A1 — deployment/operational artifacts
- **PASS** for all source/tests/systems scopes (no Dockerfiles in those scopes).
- **VIOLATION** `docker-compose.yml:17` — tmpfs mode `1777"` (stray quote) makes the orchestrator service uncreatable. **(P0)**
- **VIOLATION** `docker-compose.yml` healthcheck — `/app/output/.healthy` on a `:ro` mount with committed backing file → permanently green health, contradicting the Dockerfile's own `/run/lawmax/.healthy` fix. **(P0)**
- **VIOLATION** `Dockerfile.test` — unpinned Quicklisp network install (non-hermetic) gating Phase-3. **(P1)**
- **NOTE** `docker-compose.architecture-tests.yml`/`.citation-tests.yml`/`.tokenizer-tests.yml` carry obsolete `version:` keys and keep three declared-nonsuite files alive off the signed proof chain. **(P2)**
- **PASS-with-note** `authority-v2/toolchain/everparse.Dockerfile` coherent; `perennial.Dockerfile` **VIOLATION** (store proof target has no Makefile; COQ_VERSION unused). **(P1)**

### A2 — cross-references resolve / docs≡reality
- **PASS** for the bulk of source/tests (all pipeline stage functions, gate registries, verifier-census paths, TSR fixtures, golden fingerprints resolve; verifiers execute green: merkle 134/134 ×2, canonical 8/8, release-vector 1+7 verdicts reproduced, 170 prov-hashes recomputed at 0 mismatch).
- **VIOLATION** `source/legal-audit-system.lisp` → `jws-authority:verify-jws` arity/keyword mismatch (every crypto verify errors). **(P0)**
- **VIOLATION** `source/eu-interop-layer.lisp` — drakma `:timeout` keyword doesn't exist; `jonathan:parse` read with `gethash` (dead-on-use). **(P0)**
- **VIOLATION** `epistemic/primary-anchor.lisp` header + call — `compute-sha256-*` defined nowhere. **(P0)**
- **VIOLATION** license three-way contradiction: LICENSE (All-Rights-Reserved) vs `SEMANTIC-CONTRACT.md`/`PROVENANCE.yaml`/`provenance.yml` (CC-BY) vs `DEPLOY-PRODUCTION.md`/`RUN-DOCKER.md` (MIT); manifests assert CC0; huggingface asserts cc-by-4.0; ARC corpus is Apache-2.0 (deferred-license class). **(P0)**
- **VIOLATION** dead script references: `scripts/verify-deps.sh`, `verify-deterministic-build.sh`, `provenance-stamp.sh`, `verify-provenance.sh`, `ipfs-pin-remote.sh`, `generate-deps-lock.sh` (real seats are `.lisp`). **(P1)**
- **VIOLATION** determinism archive: manifests list `verify/tsa-ca.pem` (absent) and a `stability-policy.md` leaf that no longer matches committed bytes (eol normalization mutated evidence). **(P0)**
- **VIOLATION** `deps/closure-schema.json` rejects the artifact it governs (contradicts `verify-runtime-closure.sh`). **(P1)**
- **VIOLATION** `epistemic/shacl-shapes.lisp` — shapes require `ctProof`/integer `eli:number` that every real manifest/article fails. **(P1)**
- **VIOLATION** repo-identity churn — URLs reference `ORCHESTRATORSUPER`/`STAVROPOULOSLAWCORPUS`/`orchestratorGREEKLAW`; actual repo is `THE-LEGAL-WATCHTOWER`.
- **VIOLATION** stale not-loaded headers (`reasoning-authority`, `greek-lemmatizer`); doc/default mismatches (`x509` 3650 vs 36500; `hash-artifacts` "Blake3" vs SHA-512).

### A3 — orphans / dead / duplicate seats
- **Orphans / dead (loaded-but-dead or unloadable):** `source/config.lisp` (unloadable), `source/ai-citation-strategy.lisp` (zero callers), `source/eu-interop-layer.lisp`, `source/injection.lisp`, `source/lexicon-neurolingo.lisp`, `orchestrator-core/{parallel-executor,artifact-cache,instrumentation}.lisp`, engine `backends/{mock,ethereum,arweave,ipfs}.lisp`, `templates/rendering.lisp`, `html-parliament-adapter` (~1000 lines), `orchestrator-meta/{meta-model,meta-graph}.lisp` + AI-core `{beacon-model,citation-strategy,feeds}.lisp`, `orchestrator-omega/frbr-pipeline-stage.lisp` + `omega-package.lisp` + gr-syntagma `{historical,structure,validation}.lisp`, `cli/{log,reporting,config-loader}.lisp`, `orchestrator-tooling.asd`, `orchestrator-tests-runtime.asd`, root `entrypoint.lisp`, `authority-v2/tests/{probe-attest-refusal,probe-producer-under-uid}.lisp`, `deployment/verify/ontology-raw-live-dump.sexp`, `configs/{huggingface-dataset.json,prometheus-citation.yml}`, `docker/cosign.pub`, `examples/*`, `deployment/data/syntagma_clean.zip`, `deps.archives.lock`, third-party `static-vectors`, four DARPA-era tests (`mathematical-proof`, `observer-verification`, `test-citation-authority`, `test-infrastructure`), `tests/architecture-verification.lisp`, `tests/comparison-test.lisp`.
- **Duplicate seats (one-seat law):** two RDFS engines (`reasoning-authority`+`rdfs-inference`, **P0**); two umbrella `.asd`; two protocol files; two pipeline-registries (spec live + meta empty, **P0**); dual JSON seats (jonathan/yason); three authority/provenance RDF writers; three Greek-folding + three tokenizer + three TTL-escaper seats; `escape-html` redefined by html-rdfa-generator over the spec seat (**P0**); hand-written SBOM duplicating deps.lock; ≥4 divergent version seats.
- **Duplicate version seats:** enumerated 6-way in the .asd fleet (0.9.0 ×6, 0.9.1 ×2, 1.0.0 ×4, 1.2.0 ×3, 1.3.0 ×1) plus `main.lisp` 1.2.0 vs .asd 0.9.0 and CI `v1.3.N` auto-tags — no single version seat.

### Fail-open handlers (all sites)
`constitutional-gate` (rule error⇒allow), `proposals` `%transition`, `autonomy-missions` replay, `graph-import` citation edges, `ingestion-commands` `%read-laws-json`, engine `deploy-epistemic` + epistemic `deploy-epistemic` (key-path substitution + warn-only), `errata-boundary`, `static-site`, `pdf-adapter` codification gate (advisory), `anchor-blockchain` (configured-chain warn), `eu-interop` ELI validate, `lexicon-neurolingo` checksum-warn, `gov-source` `make-feed-source`, `capture.py` `_mount_id`, `parallel-executor` (dead), `generate-keys.lisp` (exit 0 on load failure), `.gitignore` inert rule, determinism `verify.lisp/ps1`, `provenance.yml` notes, `run-vectors.sh`/`architecture-multiplicity`/`deps-hash`/`reader-census` SKIP-green.

### Wall-clock in trusted/artifact paths
`adoption-decision` (signed ledger), `canonical-representation` finalize, `archive-authority`, `blockchain-authority` (anchor results), `corpus-provenance` (%ts fabricated epoch), `raw-text-adapter` IIR trace-id, `anchor-blockchain` article metadata, `templates/rendering` dct:created, `unified-frbr-generator` canonical .ttl, `release-manifest` default, `meta/reports` + `tool-versions`, `artifact`/`normalized-input` defaults, ai-core beacon/feeds, and the **determinism release-identity path** (multiple clock reads per release, 1s intra-run skew witnessed). Correct discipline (`orchestrator.time`/`SOURCE_DATE_EPOCH`/`version-graph iso-now`) is followed by the modern authority/temporal core.

### Error-swallowing (visible-but-uncounted or silent)
`blockchain-authority` ipfs-add, `cognition` classifier, `corpus-intelligence` `:skipped`-as-clean, `memory` fire-due-intentions, `self-model` aspects, `graph-import`, `decisions` per-file skips, `case-workspace`, `self-extension` shadow (rejection vs crash conflated), `transparency-log` chain walker, `probe-emit-load-graph` load-system, `independent-audit.py` sidecar, fluid-gate `--arc-eval`.

### Hardcoded limits (silent-degradation class only)
`citation-authority` ≤120 clamp (**P0**), `ai-citation-strategy` `(dotimes 120)`, `frbr-pipeline-stage` `(integer 1 120)` (dead), `structure.lisp` 120, `constitution.yaml` article_count 120 vs 124, omega `get-eli-const-prefix` Constitution leakage in "corpus-generic" paths. *(Most other bounded limits are declared/printed and defensible — metaeval fuel, intern caps, DoS bounds, `+ebg-*+`, docx zip-bomb cap.)*

---

## 5. ROAD SUMMARY

### Counts by road verb (assembled over all records)

| Verb | Approx. count | Meaning |
|------|--------------:|---------|
| KEEP | ~330 | seat at or near ceiling (dominant among VERIFIED/DETERMINISTIC + all verified data classes) |
| REFACTOR | ~150 | fixable in place (encoding, typed conditions, seat consumption, deterministic time) |
| DELETE | ~55 | dead/orphan/duplicate/fabricated artifacts |
| DECLARE | ~25 | dormant/limit/seed status must be stated (blocked toolchains, license-deferred, seed files) |
| SPLIT | ~15 | god-modules / multi-concept suites (`decisions.lisp`, `main.lisp`, infra `.asd`, `temporal-semantics-test`, `corpus-identity-test`) |
| REWRITE | ~18 | seat must be rebuilt (false-green verifiers, YAML config, primary-anchor, contracts) |
| MOVE | ~12 | history docs → `docs/history/`, state seats → declared volume |

*(Counts are assembler estimates over the reported `road` fields; KEEP dominates because the modern gate/proof strata and the 1,619 verified data-class files are all KEEP.)*

### Ordered top-20 highest-leverage changes toward the 22 ceilings

Each mapped to a **named ceiling**; numeric AX slot unassigned (legend absent). Ranked by blast radius × severity.

| # | Change | Path(s) | Ceiling (AX-## unassigned) |
|---|--------|---------|-----------------------------|
| 1 | Make the two `deploy-epistemic` terminal validations + `proposals`/`autonomy-missions`/`graph-import`/`ingestion-commands` handlers fail-closed | 6 files | **C-FAILCLOSED** |
| 2 | Delete/rewrite the fabricated-evidence & false-green emitters | narrative-provenance, semantic-authority, release-manifest, determinism verify.lisp/ps1, provenance.yml | **C-NOFALSEGREEN + C-HONESTY** |
| 3 | Fix `constitutional-gate` fail-open (erroring rule ⇒ named violation) | constitutional-gate.lisp | **C-FAILCLOSED** |
| 4 | Repair `primary-anchor` undefined hash calls (L1 gazette anchor is unexecutable) | epistemic/primary-anchor.lisp | **C-STRUCTURAL** |
| 5 | Fix `legal-audit-system` JWS verify wiring (crypto audit path inoperative) | legal-audit-system.lisp | **C-STRUCTURAL** |
| 6 | Resolve the license contradiction fleet-wide to All-Rights-Reserved | SEMANTIC-CONTRACT, PROVENANCE.yaml, provenance.yml, DEPLOY/RUN-DOCKER, manifests, huggingface, sbom | **C-LICENSE + C-HONESTY** |
| 7 | Fix `docker-compose.yml` two P0s (stray-quote mount + always-green healthcheck) | docker-compose.yml | **C-FAILCLOSED (ops)** |
| 8 | Fix the inert `.gitignore` rule (runtime state can leak into commits) | .gitignore | **C-STRUCTURAL** |
| 9 | Kill the RDFS duplicate seat; merge OWL-RL into `rdfs-inference` | reasoning-authority.lisp | **C-ONESEAT** |
| 10 | Remove the empty duplicate pipeline registry + malformed report JSON | meta/registry.lisp, meta/reports.lisp | **C-ONESEAT + C-STRUCTURAL** |
| 11 | Remove wall-clock from the canonical artifact path; single injected timestamp | unified-frbr-generator.lisp, determinism emitter | **C-DETERMINISM** |
| 12 | Delete `html-rdfa-generator` `escape-html` redefinition; one escaping seat | html-rdfa-generator + 3 shadow escapers + json-emit stragglers | **C-ONESEAT** |
| 13 | Remove the ≤120 article clamp and lettered-id exclusion | citation-authority.lisp | **C-HONESTY (coverage)** |
| 14 | Make `static-site`/`proof-carrying`/`archive-authority` proof paths loud/verified | 3 files | **C-NOFALSEGREEN** |
| 15 | Close SSRF-via-redirect and unbounded-allocation edges | government-source.lisp, signed-embedding-manifest.lisp | **C-SECURITY** |
| 16 | Fix `capture.py` `_mount_id` silent degradation | authority-v2/capture/capture.py | **C-FAILCLOSED** |
| 17 | Generate SBOM/closure from `deps.lock`; finish yason migration + retire jonathan stack | docker/sbom.json, third-party | **C-ONESEAT + C-HONESTY (supply-chain)** |
| 18 | Split the god-modules and the 140-file `:serial t` infra system | decisions.lisp, main.lisp, orchestrator-infrastructure.asd | **C-STRUCTURAL** |
| 19 | Delete the dead/orphan stratum (config.lisp, backends, rendering, examples, syntagma_clean.zip, tooling.asd, entrypoint.lisp, orphan probes) | ~30 files | **C-DEADCODE** |
| 20 | Make silent-green gates hard-fail (cwd-rooted `reader-census`, SKIP-on-missing-seat, cross-language stage dep) | reader-census-test, architecture-multiplicity, authority-cross-language | **C-NOFALSEGREEN (gates)** |

> **Ceilings note for Stage-E:** the 10 named ceilings observed (C-FAILCLOSED, C-ONESEAT, C-DETERMINISM, C-HONESTY, C-NOFALSEGREEN, C-STRUCTURAL, C-LICENSE, C-DEADCODE, C-SECURITY, C-CURRENCY) do **not** claim to be the full AX-01..AX-22 set — they are the axes the census evidence forced. Stage-E must reconcile them against the real 22-ceiling legend and split/merge as the legend dictates.

---

## 6. HONEST COVERAGE STATEMENT

**Fully read in full (every line):** all 15 areas report reading their scoped files in full. Concretely — Areas 0–12 and 14 read **every individual file** (751 distinct files across those areas, incl. the 3 >1200-line adapters read in multiple passes). Area 13 read **61 heterogeneous files in full** and, for the 1,619 homogeneous machine-generated files, verified them **member-by-member by script** (not sampled): schema homogeneity, prov-hash recomputation (170 prov sidecars recomputed → 0 mismatches), and mutant diffs against base (release-vector bundles, golden fingerprints, corpus/decision pairs, dialogue catalog, ARC/input classes). Area 14's 58 vendored libraries were each read at the `.asd` level, cross-checked bijectively against `deps.lock` (58/58) and reverse-reachability computed from all 16 first-party `.asd` files.

**Read as class-level (verified as a class, not per-file prose):** Area 13's 1,619 files — covered by class records whose counts sum exactly to 1,619 (173 release-vector fixtures, 6 golden fingerprints, 6 corpus + 6 prov + 164 decision + 164 decision-prov, 113 dialogue entries, 801 ARC, 183 raw decisions, 6 source PDFs, etc.). Each class was mechanically validated, not eyeballed.

**Catalog-only (identity/metadata, not full-content prose in this master):** none — every catalogued seat carries a read-derived guarantee and debt from its area report.

**Counts.** Grand total 2,411 files. Fully-read-prose: **~812** (751 across areas 0–12/14 + 61 in area 13). Class-verified: **1,619**. Third-party at `.asd`/lock granularity: **58** (included in the 812 count as read). Catalogued WRITER/GATE/STORE/PROOF seats: **169**, guarantee histogram exact (§1c).

**Known limits of this assembly (declared, not hidden):**
1. **AX legend absent.** No AX-01..AX-22 mapping exists anywhere in the tree or was supplied to any agent or to Stage-B; all `ax` fields are `—` and §5 uses named ceilings. This is the single largest coverage gap and must be closed by Stage-E.
2. **P2 counts are grouped estimates** (~185–205), not a per-file enumeration — the areas reported P2 as per-record debt but did not all emit per-area P2 totals; the §3 P2 table is the assembler's grouped tally and should be treated as ±10%.
3. **Road-verb counts (§5) and the all-files histogram note (§1c) are derived estimates**; the §1c histogram over the **169 catalogued seats is exact**.
4. **B0 drift:** Areas were cut against `e621dbe1`; Area 11 observed live HEAD `803113c0`. Findings tied to determinism/CI artifacts should be re-confirmed against the intended B0 before Stage-E acts on them.
5. **Cross-area verification of "fixed" claims:** several history docs (GATE-0 audits) assert fixes whose current state must be confirmed in the owning area (e.g. `shacl-validator`, `hash-artifacts`, `write-authority` seats now exist — that they actually replaced the old placeholders in the stage wiring is asserted by docs, not re-proven here).

*This document is Stage-E-ready: every path is real and traceable to its area report; the P0/P1 registers carry the exact change per item; the seat catalog is complete over the four catalogued kinds.*

---

## ADDENDUM — GAP CLOSURE (75 αρχεία, πλήρης ανάγνωση) → COVERAGE_COMPLETE

Ο coverage adversary βρήκε 74(+1) αρχεία εκτός census (deployment top-level, cloudflare/, deps/, tools/). Όλα καταγράφηκαν με πλήρη ανάγνωση (_stageB_gap_census.md). Τελικό σύνολο: **2,486 records**. Νέα ευρήματα:
- **+3 P0 (P0-13):** deployment/provenance-narrative.ttl (κατασκευασμένο 'INSTITUTIONAL RHETORIC' αφήγημα), deployment/authority.ttl (πλαστά QES/blockchain attestations «legally binding»), deployment/ai-feedback.ttl (πλαστό citation log). Καμία κατανάλωση από το build — supreme closure: DELETE, οι γνήσιες έδρες υπάρχουν (PCL-1, release-authority, generated manifest/SHACL).
- **+P1:** templates/graph-delta.ttl + version-lineage.ttl με ΨΕΥΔΕΣ περιεχόμενο αναθεώρησης 2019 (Art.3/16/32) + invalid Turtle· deps/closure-schema.json dead-letter (229 παραβιάσεις από το ίδιο του το artifact, 0 enforcement — τα hashes ταυτίζονται με deps.lock)· CC-BY στη δημόσια serving διαδρομή (cloudflare) vs All-Rights-Reserved νόμος.
- **LAWMAX canon (30 specs):** ομοιόμορφα υψηλού επιπέδου, KEEP σχεδόν όλα· χρέη μόνο cosmetic drift.
- **Ρίζα του τυφλού σημείου:** τα maps του LAWMAX-ARCHITECTURE-CONSTITUTION δεν φτάνουν cloudflare/deps/tools/TTL-fleet — το δηλωμένο χρέος Π1· αυτό το census είναι το τεκμήριο εκτέλεσής του.
- **Quality-adversary διορθώσεις ενσωματωμένες:** P0 static-site = latent (μη-πυροδοτούμενο σήμερα) fail-open· JWS defect = fail-closed inoperative (όχι fail-open).
