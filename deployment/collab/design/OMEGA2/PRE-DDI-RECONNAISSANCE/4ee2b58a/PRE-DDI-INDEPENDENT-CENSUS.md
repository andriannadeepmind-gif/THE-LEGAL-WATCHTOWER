# PRE-DDI-INDEPENDENT-CENSUS

**Read-only reconnaissance artifact — NOT a repository file. Produced outside the repository by an independent reader (`census.py`, tokenizer + explicit-stack parser, sharing no code with `SEXP-READER.py`). The committed ledger and generated views were NOT used as an oracle; they were compared AFTER the reconstruction.**

## A. Git facts of the read-only target

| fact | value |
|---|---|
| repository | `andriannadeepmind-gif/THE-LEGAL-WATCHTOWER` |
| branch | `claude/lawmax-omega-arch-review-vgi9zl` (fresh clone into scratchpad; the session's working repository was never touched) |
| pinned candidate commit | `4ee2b58a8df0941845ab786bd0ff859844b94dde` |
| tree | `ad71185a26b3beb39da6d50c09f567cff0475def` |
| first parent | `cc52a27d79e3d60c2a85ed8f85ba0516830406e4` (cc52a27d, "correct the recorded TCB figures…") |
| migration baseline (ROOT.sexp :parent-architecture-commit) | `4787b342282f8d5f2ec4b9e64b11e32b7a64813a` |
| commits since baseline | a2f45f6d [0160] → 818b7dd9 → f04bf7e6 [0161] → af0eb3c9 [0162] → a87bb6b7 [0163] → cc52a27d → 4ee2b58a [0164] |
| origin/main relation | origin/main (`e621dbe1`) is an ancestor of the candidate; 42 commits ahead |
| clone working tree | clean (0 changed, 0 untracked; 0 commits authored in this session) |
| remote tip of the target branch AT THE END of this session | `720452abe72cf986d5431d629b8d7385fd68acd7` — the branch MOVED on the remote while this read-only reconnaissance ran. It was not moved by this session (no commit, no push; the clone still points at the pinned commit). Every statement in these five artifacts is pinned to `4ee2b58a` / tree `ad71185a` as ordered, and must be re-validated against `720452ab` before any builder acts on it. |
| model root digest (ROOT.sexp) | `0902776d4672fe77b491e9d6b55fc4865a7362d22efe0382554d132fe847db92` (schema version 4, 14 modules) |

## B. Migration-source universe (six registries, SHA-256 of raw bytes)

The source universe is derived exactly as the model derives it: every tracked path whose `files-and-roles.sexp` role is `CANONICAL_MODEL_INPUT` and that lies outside `ARCHITECTURE-MODEL/` (21 such file facts exist; 15 are the model's own modules, 6 are the registries below).

| registry | bytes | lines | top-level forms | SHA-256 |
|---|---|---|---|---|
| `INTERFACE-AND-SCHEMA-REGISTRY.sexp` | 18074 | 181 | 62 | `bb40f8a048ee07ee6f55f183f438a7aee1cd90e013ffc034c6694782f2fc377b` |
| `SUBSYSTEM-REGISTRY.sexp` | 14914 | 146 | 46 | `6d4fea2816699a66257d2e3b741a42ede6ccf94198f2280f62084a6d5b16ca17` |
| `V1.5-SCHEMAS.sexp` | 47939 | 646 | 77 | `220c51439f08ba14aa4ad90733ddc70f18f09d6e42e3ef0107fafb362249975e` |
| `V1.6-SCHEMAS.sexp` | 30133 | 356 | 66 | `4e8eaf6bc1c6a2b7b10e4bee39472c5ee2a06d6638658a09817639ee3f60fd08` |
| `V1.7-SCHEMAS.sexp` | 37803 | 404 | 88 | `ab682b2c7076d0a587c86be3299d2f408cb4f03fb3d367c768ec7a199bc02e5b` |
| `V1.8-SCHEMAS.sexp` | 44265 | 465 | 96 | `be5607a8596545486db8557cc85d31d658a3075ce9aa8809470149cb40eb23f7` |
| **total** | | | **435** | |

Reader grammar warnings (atoms containing `| ' \` ,`, `#`-dispatch other than `#| |#`): **0**. Complete consumption: every file read to end of input; no unbalanced or surplus parenthesis; no unterminated string or block comment.

## C. Independently reconstructed counts vs the claimed ledger

| quantity | claimed (ledger / packet / [0160]) | reconstructed | verdict |
|---|---|---|---|
| source fact classes (file, top-level head) | 66 | 66 | CONFIRMED |
| IMPORTED classes | 4 | 4 | CONFIRMED |
| DEFERRED_DATA_IMPORT classes | 56 | 56 | CONFIRMED |
| OUT_OF_MIGRATION_SCOPE classes | 6 | 6 | CONFIRMED |
| deferred source forms | 332 | 332 | CONFIRMED |
| imported source forms | 97 | 97 | CONFIRMED |
| out-of-scope forms | 6 | 6 | CONFIRMED |
| total top-level forms | (not claimed) | 435 | RECONSTRUCTED |
| DDI-1 classes / forms | (ledger rows) | 12 / 40 | CONFIRMED against ledger rows |
| DDI-2 classes / forms | (ledger rows) | 18 / 156 | CONFIRMED against ledger rows |
| DDI-3 classes / forms | (ledger rows) | 10 / 12 | CONFIRMED against ledger rows |
| DDI-4 classes / forms | (ledger rows) | 16 / 124 | CONFIRMED against ledger rows |
| unclassified forms (catch-all check) | 0 | 0 | CONFIRMED — every head has exactly one declared disposition |
| ledger rows | 66 | 66 | CONFIRMED |
| duplicate ledger rows (multiset) | 0 | 0 | CONFIRMED |
| missing / phantom / count / status / batch discrepancies | 0 | 0 | CONFIRMED (counts); the authority wording is over-broad at field level — see §D2 / BLK-C4 |

Batch sums: 12+18+10+16 = 56 classes; 40+156+12+124 = 332 forms.

## D. Instance-level verification of the four IMPORTED classes (the ledger only proves class-level; this proves each form)

| source class | source instances | model facts | missing in model | extra in model |
|---|---|---|---|---|
| INTERFACE-AND-SCHEMA-REGISTRY define-interface → `type` | 60 | 60 | none | none |
| define-interface `:consumers` → `consumes` pairs | 102 | 102 | none | none |
| SUBSYSTEM-REGISTRY define-subsystem → `subsystem` | 26 | 26 | none | none |
| V1.8 define-write-authority → `store` | 10 | 10 | none (all 10 store ids present) | none |
| V1.8 define-pipeline → `stage` + `stage-edge` | 1 form (8 nodes, 8 edges) | 8 stages, 8 edges | none | none |

Observation (not a discrepancy, but a fact the builder needs): the model's `store` facts translate the source's free-text `:owner "WP-03 journal.lisp"` / `:write-authority "write-authority.lisp"` into typed seats (`SEAT-JOURNAL` / `SEAT-WRITE-AUTHORITY`), i.e. the IMPORTED class was NOT imported verbatim but re-seated through `seats.sexp`. The V1.7 `define-write-authority` class (10 forms, DDI-1) is byte-for-byte identical in content to the V1.8 one (same=true, 0 differing rows): its import is a pure superseded-duplicate case.

### D2. Field-level coverage of the four IMPORTED classes (measured with my reader; `imported-field-coverage.json`)

The ledger and the promotion fact state that the four IMPORTED classes are "fully represented as canonical model facts" (`deferred-imports.sexp` PROMOTION-IMPORTED) and that their detail is `CANONICAL_IN_MODEL`. At the level of INSTANCES that is true (§D). At the level of FIELDS it is not:

| source class | source keys (forms carrying them) | keys represented in the model | keys NOT in the model (silently dropped by `build_model.py`) |
|---|---|---|---|
| `define-interface` (60) | owner 60, classification 60, seat 60, signature-owner 60, version 60, consumers 60, new 42 / reuse 16, future-wp 19, migration 19, rollback 19, status 7, public-dependency 6, kind 1 | `type :owner-subsystem :classification (:consumer-role)`, `component`, `consumes :consumer :provides` | **seat, signature-owner, version, new/reuse, future-wp, migration, rollback, status, public-dependency, kind** |
| `define-subsystem` (26) | name, owner, mission, migration, requirement, interface, test, future-wp, rollback (26 each), wp-note 8 | `subsystem :owner-seat :classification :migration :mission`, `req-map :requirement :test :wp :seat` | **name, interface, rollback, wp-note** (classification is DERIVED from migration = DEFER_PRIVATE, not a source field) |
| `define-write-authority` (10) | store, owner, write-authority, writers (10 each), read-only 3 | `store :owner :writer` (writer "none" → `SEAT-NO-WRITER`) | **writers (count), read-only** (represented only implicitly by `SEAT-NO-WRITER`) |
| `define-pipeline` (1) | entry, exit, nodes, edges, mandatory-nodes, symbolic-only-nodes, proposer-optional-nodes, proposer-mandatory-nodes, mutation-count, mutations | `stage` (8), `stage-edge :from :to` (8) | **entry, exit, mandatory-nodes, symbolic-only-nodes, proposer-optional-nodes, proposer-mandatory-nodes, mutation-count, mutations** — i.e. the whole SYMBOLIC-ONLY guarantee (`V8I-SYM-exact`) is not in the model |

**Consequence for the authority split.** For these four classes the model is canonical for identity and topology only; the dropped fields have no canonical seat at all (the source registry is declared superseded for them, the model does not hold them). This is not a count discrepancy — the 66/4/56/6/332 numbers stand — but it is an over-claim in the `promotion` fact's wording and in `:authority CANONICAL_IN_MODEL`, and it is a DDI input: the dropped fields are source facts without a future gate unless a batch re-imports them (the interface dossier classifies 44 of the 60 IMPORTED interface forms as NEEDS_SCHEMA_EXTENSION and 16 as NEEDS_ARCHITECTURAL_DECISION for exactly this reason). Named as **BLK-C4** in §I.

## E. Duplicate-assignment and lineage analysis

- Every one of the 435 forms is assigned to exactly one (file, class) and every class to exactly one status/batch: **no duplicate assignment**.
- Same head + same name defined in more than one registry (version chains that the identity/version rule must resolve): **22 groups** (7 capability seats V1.7↔V1.8, 10 write-authorities V1.7↔V1.8, pipeline V1.7↔V1.8, record ClarifiedInterpretation/1 V1.7↔V1.8, references CognitionResult/1 V1.7↔V1.8, DeclassificationReceipt/1 V1.6↔V1.8, LegalIR/1 V1.6↔V1.8, TrustBundle/1 V1.6↔V1.8).
- Same name under ANY head in more than one registry: **80 names** (see `version-chains.md` in the work set; e.g. a V1.6 `define-record` later re-declared as a V1.8 `define-reference`). These are the "conflict / duplicate-seat risk" inputs of the execution matrix.
- Diff facts: V1.7 vs V1.8 `define-capability-seat`: all 7 differ (V1.8 adds `:kind :CODE|:DOCUMENT`, full paths, `:section`; `JURIS_ANONYMIZE` renamed `JURIS_RATIO`; `orchestrator.corpus/ai-corpus-dump` → `orchestrator.ai-dump/emit-corpus-jsonl`; subsystem `RA-S25` → `S25`). V1.7 vs V1.8 `define-pipeline`: V1.8 adds `:mandatory-nodes`, drops `:node-types`, replaces the 5-mutation invariant with exactly 4 mutations. `ClarifiedInterpretation/1`: V1.8 adds `merged_result_ref`, `input_provenance_refs`, typed `MergeSemanticsV8`. `define-ra-closure-roots`: V1.8 changes public roots (CitationSupremacyMetric/1→CitationMetricV8/1, RootAuthorityQualification/1→RootAuthorityStatus/1, drops LanguageCognitionLayer/1), adds two private-forbidden types, and changes edge-kinds (13) → edge-families (8).

## F. Per-class table (66 rows; status/batch = declared disposition under test, reconstructed per head)

| # | file | class (top-level head) | forms | status | authority | batch |
|---|---|---|---|---|---|---|
| 1 | INTERFACE-AND-SCHEMA-REGISTRY.sexp | `registry-version` | 1 | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — |
| 2 | INTERFACE-AND-SCHEMA-REGISTRY.sexp | `define-interface` | 60 | IMPORTED | CANONICAL_IN_MODEL | — |
| 3 | INTERFACE-AND-SCHEMA-REGISTRY.sexp | `define-invariant` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 4 | SUBSYSTEM-REGISTRY.sexp | `registry-version` | 1 | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — |
| 5 | SUBSYSTEM-REGISTRY.sexp | `define-wp-purpose` | 16 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 6 | SUBSYSTEM-REGISTRY.sexp | `define-subsystem` | 26 | IMPORTED | CANONICAL_IN_MODEL | — |
| 7 | SUBSYSTEM-REGISTRY.sexp | `define-file-disposition` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 8 | SUBSYSTEM-REGISTRY.sexp | `define-invariant` | 2 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 9 | V1.5-SCHEMAS.sexp | `spec-version` | 1 | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — |
| 10 | V1.5-SCHEMAS.sexp | `define-closed-enum` | 16 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 11 | V1.5-SCHEMAS.sexp | `define-record` | 18 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 12 | V1.5-SCHEMAS.sexp | `define-cardinality-matrix` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 13 | V1.5-SCHEMAS.sexp | `define-invariant` | 22 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 14 | V1.5-SCHEMAS.sexp | `define-rule` | 7 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 15 | V1.5-SCHEMAS.sexp | `define-gate` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 16 | V1.5-SCHEMAS.sexp | `define-frozen-enum-reference` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 17 | V1.5-SCHEMAS.sexp | `define-required-refs` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 18 | V1.5-SCHEMAS.sexp | `define-decision-function` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 19 | V1.5-SCHEMAS.sexp | `define-algorithm` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 20 | V1.5-SCHEMAS.sexp | `define-quorum-predicate` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 21 | V1.5-SCHEMAS.sexp | `define-projection` | 3 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 22 | V1.5-SCHEMAS.sexp | `define-ref-classification` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 23 | V1.5-SCHEMAS.sexp | `define-construction-order` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 24 | V1.5-SCHEMAS.sexp | `define-constitution-reference` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 25 | V1.6-SCHEMAS.sexp | `spec-version` | 1 | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — |
| 26 | V1.6-SCHEMAS.sexp | `define-invariant` | 21 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 27 | V1.6-SCHEMAS.sexp | `define-closed-enum` | 8 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 28 | V1.6-SCHEMAS.sexp | `define-protocol` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 29 | V1.6-SCHEMAS.sexp | `define-adapter-contract` | 2 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 30 | V1.6-SCHEMAS.sexp | `define-record` | 22 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 31 | V1.6-SCHEMAS.sexp | `define-reference` | 6 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 32 | V1.6-SCHEMAS.sexp | `define-construction-order` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 33 | V1.6-SCHEMAS.sexp | `define-mapping` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 34 | V1.6-SCHEMAS.sexp | `define-rule` | 2 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 35 | V1.6-SCHEMAS.sexp | `define-ref-classification-v6` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 36 | V1.7-SCHEMAS.sexp | `spec-version` | 1 | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — |
| 37 | V1.7-SCHEMAS.sexp | `define-invariant` | 23 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 38 | V1.7-SCHEMAS.sexp | `define-reference` | 8 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 39 | V1.7-SCHEMAS.sexp | `define-closed-enum` | 8 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 40 | V1.7-SCHEMAS.sexp | `define-record` | 25 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 41 | V1.7-SCHEMAS.sexp | `define-construction-order` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 42 | V1.7-SCHEMAS.sexp | `define-decision-function` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 43 | V1.7-SCHEMAS.sexp | `define-ra-closure-roots` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 44 | V1.7-SCHEMAS.sexp | `define-pipeline` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 45 | V1.7-SCHEMAS.sexp | `define-write-authority` | 10 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 46 | V1.7-SCHEMAS.sexp | `define-capability-seat` | 7 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 47 | V1.7-SCHEMAS.sexp | `define-source-type-coverage` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 48 | V1.7-SCHEMAS.sexp | `define-wp-reconciliation` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 49 | V1.8-SCHEMAS.sexp | `spec-version` | 1 | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — |
| 50 | V1.8-SCHEMAS.sexp | `define-invariant` | 23 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 51 | V1.8-SCHEMAS.sexp | `define-closed-enum` | 9 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 52 | V1.8-SCHEMAS.sexp | `define-record` | 19 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 53 | V1.8-SCHEMAS.sexp | `define-cognition-graph` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 54 | V1.8-SCHEMAS.sexp | `define-dimension-policy` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 55 | V1.8-SCHEMAS.sexp | `define-reference` | 9 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 56 | V1.8-SCHEMAS.sexp | `define-capability-seat` | 7 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 57 | V1.8-SCHEMAS.sexp | `define-ra-closure-roots` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 58 | V1.8-SCHEMAS.sexp | `define-write-authority` | 10 | IMPORTED | CANONICAL_IN_MODEL | — |
| 59 | V1.8-SCHEMAS.sexp | `define-wp-reconciliation` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 60 | V1.8-SCHEMAS.sexp | `define-pipeline` | 1 | IMPORTED | CANONICAL_IN_MODEL | — |
| 61 | V1.8-SCHEMAS.sexp | `define-cognition-node-types` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 62 | V1.8-SCHEMAS.sexp | `define-cardinality-table` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 |
| 63 | V1.8-SCHEMAS.sexp | `define-fixtures` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 |
| 64 | V1.8-SCHEMAS.sexp | `define-reliance-aggregation` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 |
| 65 | V1.8-SCHEMAS.sexp | `define-canonical-identity` | 8 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |
| 66 | V1.8-SCHEMAS.sexp | `define-ra-delta-seats` | 1 | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 |

## G. Per-form table (435 rows) — file, line, ordinal, class, name, status, authority, batch, structural locator

The locator `sha16` is the first 16 hex digits of SHA-256 over the canonical re-rendering of the form (whitespace-normalised, comments stripped); it is stable under reformatting and identifies the form independently of its line number.

| file | line | ord | class | name | status | authority | batch | sha16 |
|---|---|---|---|---|---|---|---|---|
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 7 | 0 | `registry-version` | `"interface-and-schema-registry-v1.6"` | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — | `af4706ab86becf2b` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 11 | 1 | `define-interface` | `PerceptionEnvelope/1` | IMPORTED | CANONICAL_IN_MODEL | — | `9b1cd46360e72b93` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 13 | 2 | `define-interface` | `CandidateInterpretation/1` | IMPORTED | CANONICAL_IN_MODEL | — | `7b6f12749160dc94` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 15 | 3 | `define-interface` | `LegalIR/1` | IMPORTED | CANONICAL_IN_MODEL | — | `2449dbad63694b52` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 17 | 4 | `define-interface` | `MemoryEvent/1` | IMPORTED | CANONICAL_IN_MODEL | — | `a9ba3c40dad0392b` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 19 | 5 | `define-interface` | `CapabilityManifest/1` | IMPORTED | CANONICAL_IN_MODEL | — | `06ed235cdd18d273` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 21 | 6 | `define-interface` | `ToolInvocation/1` | IMPORTED | CANONICAL_IN_MODEL | — | `9641ee5b1ecebda7` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 23 | 7 | `define-interface` | `Plan/1` | IMPORTED | CANONICAL_IN_MODEL | — | `6e494932c8b1e039` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 25 | 8 | `define-interface` | `ActionIntent/1` | IMPORTED | CANONICAL_IN_MODEL | — | `fe8dbca036a9058b` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 27 | 9 | `define-interface` | `Approval/1` | IMPORTED | CANONICAL_IN_MODEL | — | `4d2f9802bbfc8ce0` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 29 | 10 | `define-interface` | `ExecutionReceipt/1` | IMPORTED | CANONICAL_IN_MODEL | — | `94d20ff16d9fd3a3` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 31 | 11 | `define-interface` | `SafetyState/1` | IMPORTED | CANONICAL_IN_MODEL | — | `9184c6396936bcdd` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 33 | 12 | `define-interface` | `TrustBundle/1` | IMPORTED | CANONICAL_IN_MODEL | — | `31dfc981086f8e0a` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 35 | 13 | `define-interface` | `DeclassificationReceipt/1` | IMPORTED | CANONICAL_IN_MODEL | — | `49daccbe4b1cc23d` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 39 | 14 | `define-interface` | `SemanticProposer` | IMPORTED | CANONICAL_IN_MODEL | — | `bc4b76f815960653` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 41 | 15 | `define-interface` | `LanguageCognitionLayer/1` | IMPORTED | CANONICAL_IN_MODEL | — | `2f4bcb93397dca58` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 43 | 16 | `define-interface` | `CognitionResult/1` | IMPORTED | CANONICAL_IN_MODEL | — | `fd22b31a07b58725` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 45 | 17 | `define-interface` | `MemoryProjection/1` | IMPORTED | CANONICAL_IN_MODEL | — | `7773ab5c9f8e9478` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 47 | 18 | `define-interface` | `MemoryPolicy/1` | IMPORTED | CANONICAL_IN_MODEL | — | `969fecdc346efe60` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 51 | 19 | `define-interface` | `PrivateMatterProfile/1` | IMPORTED | CANONICAL_IN_MODEL | — | `e039435e4e7d3429` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 53 | 20 | `define-interface` | `RealTimeAssistance/1` | IMPORTED | CANONICAL_IN_MODEL | — | `c751b7883f67eb67` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 55 | 21 | `define-interface` | `EmbodimentInterfaces/1` | IMPORTED | CANONICAL_IN_MODEL | — | `188bf9dc8af250f1` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 59 | 22 | `define-interface` | `SemanticAdmissionEvidence/1` | IMPORTED | CANONICAL_IN_MODEL | — | `f520e73628cb2318` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 61 | 23 | `define-interface` | `CensusSpaceClassification/1` | IMPORTED | CANONICAL_IN_MODEL | — | `fe9303678c68489f` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 63 | 24 | `define-interface` | `IndependencePolicy/1` | IMPORTED | CANONICAL_IN_MODEL | — | `787f3c0628016901` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 65 | 25 | `define-interface` | `InterpretiveProfile/1` | IMPORTED | CANONICAL_IN_MODEL | — | `6398326cf21f9774` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 69 | 26 | `define-interface` | `legal-timeline/1` | IMPORTED | CANONICAL_IN_MODEL | — | `a1bbdfa61c845715` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 71 | 27 | `define-interface` | `audit-timeline/1` | IMPORTED | CANONICAL_IN_MODEL | — | `643ae6e03e4319d3` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 73 | 28 | `define-interface` | `citation/1` | IMPORTED | CANONICAL_IN_MODEL | — | `419588fb0eca9038` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 77 | 29 | `define-interface` | `ResolverQuery/1` | IMPORTED | CANONICAL_IN_MODEL | — | `a4c89c72ab559c29` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 79 | 30 | `define-interface` | `ResolverResult/1` | IMPORTED | CANONICAL_IN_MODEL | — | `25dcea3fe0bf5a9a` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 81 | 31 | `define-interface` | `AmbiguityResult/1` | IMPORTED | CANONICAL_IN_MODEL | — | `2e82636727aab36f` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 83 | 32 | `define-interface` | `ResolverReceipt/1` | IMPORTED | CANONICAL_IN_MODEL | — | `fc9238b0601c72d8` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 85 | 33 | `define-interface` | `CanonicalRetrievalView/1` | IMPORTED | CANONICAL_IN_MODEL | — | `5589949c7ee93459` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 87 | 34 | `define-interface` | `RightsMatrix/1` | IMPORTED | CANONICAL_IN_MODEL | — | `baa1f69063173462` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 89 | 35 | `define-interface` | `LicensePolicy/1` | IMPORTED | CANONICAL_IN_MODEL | — | `e11f8090019161f0` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 91 | 36 | `define-interface` | `CitationSupremacyMetric/1` | IMPORTED | CANONICAL_IN_MODEL | — | `eff0fb4bb067308f` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 93 | 37 | `define-interface` | `DatasetSnapshot/1` | IMPORTED | CANONICAL_IN_MODEL | — | `84a3931a15941902` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 95 | 38 | `define-interface` | `AnonymizationReceipt/1` | IMPORTED | CANONICAL_IN_MODEL | — | `548edb40fb69fc42` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 97 | 39 | `define-interface` | `NonAuthoritativeTranslation/1` | IMPORTED | CANONICAL_IN_MODEL | — | `eb3c59d763911241` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 99 | 40 | `define-interface` | `TenantProfile/1` | IMPORTED | CANONICAL_IN_MODEL | — | `f26d2bea30fae11f` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 101 | 41 | `define-interface` | `RootAuthorityQualification/1` | IMPORTED | CANONICAL_IN_MODEL | — | `047e05826ae6e1c6` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 110 | 42 | `define-interface` | `RootAuthorityStatus/1` | IMPORTED | CANONICAL_IN_MODEL | — | `d49d3610ff465f61` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 113 | 43 | `define-interface` | `RelianceProjection/1` | IMPORTED | CANONICAL_IN_MODEL | — | `5c4cfa881e7379ef` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 117 | 44 | `define-interface` | `ClarifiedInterpretation/1` | IMPORTED | CANONICAL_IN_MODEL | — | `9214c63f579c0376` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 120 | 45 | `define-interface` | `ClarificationRequest/1` | IMPORTED | CANONICAL_IN_MODEL | — | `0c546285b961a05f` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 123 | 46 | `define-interface` | `ClarificationResponse/1` | IMPORTED | CANONICAL_IN_MODEL | — | `c006409d107fddb6` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 127 | 47 | `define-interface` | `CanonicalCitationURI/1` | IMPORTED | CANONICAL_IN_MODEL | — | `82ba3501dca5881e` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 130 | 48 | `define-interface` | `MultiCommitment/1` | IMPORTED | CANONICAL_IN_MODEL | — | `873b51d10c21e435` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 133 | 49 | `define-interface` | `ReAnchoringManifest/1` | IMPORTED | CANONICAL_IN_MODEL | — | `db8ac5db58f78f7f` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 136 | 50 | `define-interface` | `ResolutionRecord/1` | IMPORTED | CANONICAL_IN_MODEL | — | `05bdb25d3a40546d` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 140 | 51 | `define-interface` | `ContinuityPolicy/1` | IMPORTED | CANONICAL_IN_MODEL | — | `0baec372c2c62b24` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 143 | 52 | `define-interface` | `EmergencyFreeze/1` | IMPORTED | CANONICAL_IN_MODEL | — | `18f931c34b17f935` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 147 | 53 | `define-interface` | `PublicCorrectionEvent/1` | IMPORTED | CANONICAL_IN_MODEL | — | `4361ea1d54f2b827` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 150 | 54 | `define-interface` | `RestrictedForensicRecord/1` | IMPORTED | CANONICAL_IN_MODEL | — | `f746e98b017dd7f0` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 154 | 55 | `define-interface` | `CitationMetricV8/1` | IMPORTED | CANONICAL_IN_MODEL | — | `d12cee4c9f4ff506` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 158 | 56 | `define-interface` | `SidecarSourceProfile/1` | IMPORTED | CANONICAL_IN_MODEL | — | `e389819a99b46341` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 162 | 57 | `define-interface` | `LawmaxStatusVsMark/1` | IMPORTED | CANONICAL_IN_MODEL | — | `184af59b7177ee02` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 166 | 58 | `define-interface` | `CryptoSuiteRegistry/1` | IMPORTED | CANONICAL_IN_MODEL | — | `6a38d83568c24a90` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 169 | 59 | `define-interface` | `RecoveryEpoch/1` | IMPORTED | CANONICAL_IN_MODEL | — | `1904c6cb6a2c8576` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 173 | 60 | `define-interface` | `JurisdictionNamespace/1` | IMPORTED | CANONICAL_IN_MODEL | — | `3f0a69913a38814c` |
| INTERFACE-AND-SCHEMA-REGISTRY.sexp | 177 | 61 | `define-invariant` | `:ISR-V6-closure` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `dbf1a566ab46649e` |
| SUBSYSTEM-REGISTRY.sexp | 8 | 0 | `registry-version` | `"subsystem-registry-v1.6"` | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — | `e87f844e84a2ff5a` |
| SUBSYSTEM-REGISTRY.sexp | 15 | 1 | `define-wp-purpose` | `WP-00` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `eb218434677c55fe` |
| SUBSYSTEM-REGISTRY.sexp | 16 | 2 | `define-wp-purpose` | `WP-01` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `5065e11e66c162dc` |
| SUBSYSTEM-REGISTRY.sexp | 17 | 3 | `define-wp-purpose` | `WP-02` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `a880c58b4d9541ba` |
| SUBSYSTEM-REGISTRY.sexp | 18 | 4 | `define-wp-purpose` | `WP-03` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `0f613bd3214041cd` |
| SUBSYSTEM-REGISTRY.sexp | 19 | 5 | `define-wp-purpose` | `WP-04` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `5dadac926e47d353` |
| SUBSYSTEM-REGISTRY.sexp | 20 | 6 | `define-wp-purpose` | `WP-05` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `01130836597f2782` |
| SUBSYSTEM-REGISTRY.sexp | 21 | 7 | `define-wp-purpose` | `WP-06` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c2d52bc4b60320b0` |
| SUBSYSTEM-REGISTRY.sexp | 22 | 8 | `define-wp-purpose` | `WP-07` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `99e6ae6bb0f351bc` |
| SUBSYSTEM-REGISTRY.sexp | 23 | 9 | `define-wp-purpose` | `WP-08` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `1bc9a29d9d9995b5` |
| SUBSYSTEM-REGISTRY.sexp | 24 | 10 | `define-wp-purpose` | `WP-09` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `cce56cd3f4dddcaa` |
| SUBSYSTEM-REGISTRY.sexp | 25 | 11 | `define-wp-purpose` | `WP-10` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `71a18eba12cfea96` |
| SUBSYSTEM-REGISTRY.sexp | 26 | 12 | `define-wp-purpose` | `WP-11` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `1501a2fc412e0337` |
| SUBSYSTEM-REGISTRY.sexp | 27 | 13 | `define-wp-purpose` | `WP-12` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `b5539ce022277683` |
| SUBSYSTEM-REGISTRY.sexp | 28 | 14 | `define-wp-purpose` | `WP-13` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `13f66e65771dd6ff` |
| SUBSYSTEM-REGISTRY.sexp | 29 | 15 | `define-wp-purpose` | `WP-14` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `2b2d7412d0dac9e6` |
| SUBSYSTEM-REGISTRY.sexp | 30 | 16 | `define-wp-purpose` | `FUTURE_BOOK_REVISION` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `9e5a579c41684dce` |
| SUBSYSTEM-REGISTRY.sexp | 35 | 17 | `define-subsystem` | `S01` | IMPORTED | CANONICAL_IN_MODEL | — | `8c654c153c69e5c1` |
| SUBSYSTEM-REGISTRY.sexp | 38 | 18 | `define-subsystem` | `S02` | IMPORTED | CANONICAL_IN_MODEL | — | `aea3f9ceb9a0f6fc` |
| SUBSYSTEM-REGISTRY.sexp | 41 | 19 | `define-subsystem` | `S03` | IMPORTED | CANONICAL_IN_MODEL | — | `c1d8f5d53ee5a874` |
| SUBSYSTEM-REGISTRY.sexp | 45 | 20 | `define-subsystem` | `S04` | IMPORTED | CANONICAL_IN_MODEL | — | `456391de12853570` |
| SUBSYSTEM-REGISTRY.sexp | 49 | 21 | `define-subsystem` | `S05` | IMPORTED | CANONICAL_IN_MODEL | — | `67da616c2a23467f` |
| SUBSYSTEM-REGISTRY.sexp | 52 | 22 | `define-subsystem` | `S06` | IMPORTED | CANONICAL_IN_MODEL | — | `56aa911817e31b02` |
| SUBSYSTEM-REGISTRY.sexp | 55 | 23 | `define-subsystem` | `S07` | IMPORTED | CANONICAL_IN_MODEL | — | `e37e9bdc2c20fa0a` |
| SUBSYSTEM-REGISTRY.sexp | 58 | 24 | `define-subsystem` | `S08` | IMPORTED | CANONICAL_IN_MODEL | — | `2724e0ef993bd5bf` |
| SUBSYSTEM-REGISTRY.sexp | 62 | 25 | `define-subsystem` | `S09` | IMPORTED | CANONICAL_IN_MODEL | — | `d3c3b42ed16c1e34` |
| SUBSYSTEM-REGISTRY.sexp | 65 | 26 | `define-subsystem` | `S10` | IMPORTED | CANONICAL_IN_MODEL | — | `8e59c3f07dde2cce` |
| SUBSYSTEM-REGISTRY.sexp | 68 | 27 | `define-subsystem` | `S11` | IMPORTED | CANONICAL_IN_MODEL | — | `83cd768cdf68fed3` |
| SUBSYSTEM-REGISTRY.sexp | 71 | 28 | `define-subsystem` | `S12` | IMPORTED | CANONICAL_IN_MODEL | — | `a210320d663bbe34` |
| SUBSYSTEM-REGISTRY.sexp | 75 | 29 | `define-subsystem` | `S13` | IMPORTED | CANONICAL_IN_MODEL | — | `01fbaf1a0d9931a6` |
| SUBSYSTEM-REGISTRY.sexp | 78 | 30 | `define-subsystem` | `S14` | IMPORTED | CANONICAL_IN_MODEL | — | `17127c117b427669` |
| SUBSYSTEM-REGISTRY.sexp | 81 | 31 | `define-subsystem` | `S15` | IMPORTED | CANONICAL_IN_MODEL | — | `84cd870d1929bb49` |
| SUBSYSTEM-REGISTRY.sexp | 85 | 32 | `define-subsystem` | `S16` | IMPORTED | CANONICAL_IN_MODEL | — | `cc5f495930d4e5fb` |
| SUBSYSTEM-REGISTRY.sexp | 88 | 33 | `define-subsystem` | `S17` | IMPORTED | CANONICAL_IN_MODEL | — | `507bd6fb40043993` |
| SUBSYSTEM-REGISTRY.sexp | 91 | 34 | `define-subsystem` | `S18` | IMPORTED | CANONICAL_IN_MODEL | — | `09691d46ba82fb94` |
| SUBSYSTEM-REGISTRY.sexp | 96 | 35 | `define-subsystem` | `S19` | IMPORTED | CANONICAL_IN_MODEL | — | `35109619f6d3d9a3` |
| SUBSYSTEM-REGISTRY.sexp | 100 | 36 | `define-subsystem` | `S20` | IMPORTED | CANONICAL_IN_MODEL | — | `8eff45015d3622c3` |
| SUBSYSTEM-REGISTRY.sexp | 104 | 37 | `define-subsystem` | `S21` | IMPORTED | CANONICAL_IN_MODEL | — | `28d2d5008f9c90f3` |
| SUBSYSTEM-REGISTRY.sexp | 108 | 38 | `define-subsystem` | `S22` | IMPORTED | CANONICAL_IN_MODEL | — | `42127f3c5cd3c409` |
| SUBSYSTEM-REGISTRY.sexp | 111 | 39 | `define-subsystem` | `S23` | IMPORTED | CANONICAL_IN_MODEL | — | `ff12a8cc3181b4cb` |
| SUBSYSTEM-REGISTRY.sexp | 114 | 40 | `define-subsystem` | `S24` | IMPORTED | CANONICAL_IN_MODEL | — | `41559440748c2134` |
| SUBSYSTEM-REGISTRY.sexp | 119 | 41 | `define-subsystem` | `S25` | IMPORTED | CANONICAL_IN_MODEL | — | `53cd595244474407` |
| SUBSYSTEM-REGISTRY.sexp | 124 | 42 | `define-subsystem` | `S26` | IMPORTED | CANONICAL_IN_MODEL | — | `704f41c0b9afbd82` |
| SUBSYSTEM-REGISTRY.sexp | 130 | 43 | `define-file-disposition` | `"legal-casegrammar.lisp"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `8482bb1f8585e90a` |
| SUBSYSTEM-REGISTRY.sexp | 136 | 44 | `define-invariant` | `:SR-V6-one-seat` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `9d1e26c9190fc024` |
| SUBSYSTEM-REGISTRY.sexp | 141 | 45 | `define-invariant` | `:SR-V6-wp-honesty` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `56f977329acaa948` |
| V1.5-SCHEMAS.sexp | 6 | 0 | `spec-version` | `"v1.5-narrow-delta-candidate-type-closed"` | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — | `f2c004572fd573ea` |
| V1.5-SCHEMAS.sexp | 13 | 1 | `define-closed-enum` | `SemanticAdmissionAssuranceProfile` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c66bd6a31f646671` |
| V1.5-SCHEMAS.sexp | 20 | 2 | `define-closed-enum` | `StateEventKind` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `08834400ec9741f6` |
| V1.5-SCHEMAS.sexp | 33 | 3 | `define-record` | `SemanticAdmissionEvidence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `3275833fb415b5ad` |
| V1.5-SCHEMAS.sexp | 45 | 4 | `define-cardinality-matrix` | `SemanticAdmissionEvidence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `e5fed8880274d882` |
| V1.5-SCHEMAS.sexp | 70 | 5 | `define-invariant` | `:V5I-D1-both` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `01ae3ec927c7d6c3` |
| V1.5-SCHEMAS.sexp | 76 | 6 | `define-record` | `DerivationIndependenceEvidence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d97439c3f54fe68b` |
| V1.5-SCHEMAS.sexp | 87 | 7 | `define-rule` | `derivation-independence-trust-root` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `28a55bdb300467c3` |
| V1.5-SCHEMAS.sexp | 100 | 8 | `define-invariant` | `:V5I-D1-indep` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c41390a9625d59a9` |
| V1.5-SCHEMAS.sexp | 105 | 9 | `define-invariant` | `:V5I-F7-derivation-trust` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c9c4fe3f17cb564a` |
| V1.5-SCHEMAS.sexp | 111 | 10 | `define-closed-enum` | `DivergenceState` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `7d4189ac96f57434` |
| V1.5-SCHEMAS.sexp | 115 | 11 | `define-invariant` | `:V5I-01` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `301cd8ca623af46a` |
| V1.5-SCHEMAS.sexp | 123 | 12 | `define-gate` | `SA-2-canonical-admission` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `5dd9666348f770b4` |
| V1.5-SCHEMAS.sexp | 140 | 13 | `define-rule` | `candidate-id-discipline` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `54adbdb9456f4026` |
| V1.5-SCHEMAS.sexp | 148 | 14 | `define-rule` | `unregistered-state-event` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `117c9eeffb1b4864` |
| V1.5-SCHEMAS.sexp | 152 | 15 | `define-invariant` | `:V5I-D1-unregistered-event` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `6d42cd663eb48e64` |
| V1.5-SCHEMAS.sexp | 155 | 16 | `define-invariant` | `:V5I-D1-no-assumption-canonical` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `7ab81ff1aba5192e` |
| V1.5-SCHEMAS.sexp | 161 | 17 | `define-invariant` | `:V5I-02` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `1d067824a81e06bc` |
| V1.5-SCHEMAS.sexp | 169 | 18 | `define-closed-enum` | `enumerability_class` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d15dbd97a0fc7eae` |
| V1.5-SCHEMAS.sexp | 172 | 19 | `define-closed-enum` | `availability_class` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `25f1399fcd19820f` |
| V1.5-SCHEMAS.sexp | 182 | 20 | `define-frozen-enum-reference` | `census_coverage_state` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `95ec693477ff35f0` |
| V1.5-SCHEMAS.sexp | 186 | 21 | `define-closed-enum` | `observation_state` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `e993bbc9850e5512` |
| V1.5-SCHEMAS.sexp | 188 | 22 | `define-closed-enum` | `availability_state` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `166e07a3d712f856` |
| V1.5-SCHEMAS.sexp | 192 | 23 | `define-record` | `NegativeEvidence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `4878d66bda60406b` |
| V1.5-SCHEMAS.sexp | 198 | 24 | `define-record` | `CensusSpaceClassification/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `464914001ae1cf09` |
| V1.5-SCHEMAS.sexp | 209 | 25 | `define-required-refs` | `CensusSpaceClassification/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `966349e4d7d0da4f` |
| V1.5-SCHEMAS.sexp | 217 | 26 | `define-closed-enum` | `acquisition_state` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `0131aa1d3b0f70d1` |
| V1.5-SCHEMAS.sexp | 219 | 27 | `define-closed-enum` | `validation_state` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `f2545002cd744950` |
| V1.5-SCHEMAS.sexp | 221 | 28 | `define-closed-enum` | `admission_obligation_state` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `225c415dd01c3ff2` |
| V1.5-SCHEMAS.sexp | 223 | 29 | `define-closed-enum` | `negative_evidence_validity` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c06093d1a32a126c` |
| V1.5-SCHEMAS.sexp | 229 | 30 | `define-decision-function` | `census-coverage-decision` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `e9f9deb73208f847` |
| V1.5-SCHEMAS.sexp | 246 | 31 | `define-invariant` | `:V5I-04` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `08645eb3dc01a6a0` |
| V1.5-SCHEMAS.sexp | 254 | 32 | `define-invariant` | `:V5I-05` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `e1675a1f2334b856` |
| V1.5-SCHEMAS.sexp | 266 | 33 | `define-closed-enum` | `IndependenceAssuranceProfile` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `408cce4f0dd259dc` |
| V1.5-SCHEMAS.sexp | 271 | 34 | `define-closed-enum` | `IndependenceDimension` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c5efbe6cf53b10bf` |
| V1.5-SCHEMAS.sexp | 276 | 35 | `define-record` | `ActorIndependenceEvidence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `66c80ca2ff28b7eb` |
| V1.5-SCHEMAS.sexp | 287 | 36 | `define-invariant` | `:V5I-D3-bind` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `6675bfc387d0bd29` |
| V1.5-SCHEMAS.sexp | 293 | 37 | `define-invariant` | `:V5I-D3-issuer-signing` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c73b38ce96e8d6f6` |
| V1.5-SCHEMAS.sexp | 304 | 38 | `define-record` | `DomainAssertion/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c3595ec7efaf13ee` |
| V1.5-SCHEMAS.sexp | 315 | 39 | `define-record` | `DomainNamespaceAuthorization/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `df75e4d2799e7779` |
| V1.5-SCHEMAS.sexp | 324 | 40 | `define-record` | `NamespaceEquivalence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `18682d8432eb3e99` |
| V1.5-SCHEMAS.sexp | 333 | 41 | `define-rule` | `domain-namespace-comparison` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `59d1db3cbc381d29` |
| V1.5-SCHEMAS.sexp | 346 | 42 | `define-invariant` | `:V5I-D3-domainassertion` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c2b84c82f150cd3f` |
| V1.5-SCHEMAS.sexp | 355 | 43 | `define-record` | `TrustedIssuerRegistry/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `83b9601526c7991a` |
| V1.5-SCHEMAS.sexp | 362 | 44 | `define-record` | `IssuerEntry/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `935c33d22cf0f796` |
| V1.5-SCHEMAS.sexp | 367 | 45 | `define-rule` | `trusted-issuer-registry-pinning` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `3f1402c7423e3e09` |
| V1.5-SCHEMAS.sexp | 378 | 46 | `define-rule` | `revocation-semantics` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `791ea876f90e0034` |
| V1.5-SCHEMAS.sexp | 387 | 47 | `define-algorithm` | `control-domain-partition` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `457dd57134cad4bf` |
| V1.5-SCHEMAS.sexp | 403 | 48 | `define-closed-enum` | `unknown_handling` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `735a64eeee1f847c` |
| V1.5-SCHEMAS.sexp | 406 | 49 | `define-invariant` | `:V5I-D3-unknown` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `3b9c03ab68356ba0` |
| V1.5-SCHEMAS.sexp | 411 | 50 | `define-record` | `IndependencePolicy/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `5280ea41994ffdd8` |
| V1.5-SCHEMAS.sexp | 421 | 51 | `define-quorum-predicate` | `mesh-independence-quorum` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `022c125dcd47ca8d` |
| V1.5-SCHEMAS.sexp | 433 | 52 | `define-invariant` | `:V5I-06` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `b67c326fb48c3b5b` |
| V1.5-SCHEMAS.sexp | 437 | 53 | `define-invariant` | `:V5I-07` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `b5a47b599ee234d2` |
| V1.5-SCHEMAS.sexp | 448 | 54 | `define-closed-enum` | `ArgumentScheme` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `45aa3bda3e3ef8b4` |
| V1.5-SCHEMAS.sexp | 454 | 55 | `define-closed-enum` | `StatementTargetKind` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c0b1d196ccc29613` |
| V1.5-SCHEMAS.sexp | 461 | 56 | `define-record` | `CanonRule/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `deeb4ef72fa50dc4` |
| V1.5-SCHEMAS.sexp | 468 | 57 | `define-record` | `CanonPolicy/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `2a3aacc9caed0447` |
| V1.5-SCHEMAS.sexp | 476 | 58 | `define-record` | `InterpretiveProfile/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `18da27465dc20ca6` |
| V1.5-SCHEMAS.sexp | 484 | 59 | `define-projection` | `InterpretiveProfileCanons` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `a8ad4dba6fa79927` |
| V1.5-SCHEMAS.sexp | 487 | 60 | `define-invariant` | `:V5I-C1-canon` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `abb2addc0f5dca2b` |
| V1.5-SCHEMAS.sexp | 496 | 61 | `define-record` | `ClaimRecord/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `89c8ab881acd598b` |
| V1.5-SCHEMAS.sexp | 502 | 62 | `define-record` | `ArgumentRecord/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `4d0f30b31f1e2bae` |
| V1.5-SCHEMAS.sexp | 515 | 63 | `define-record` | `ArgumentRelation/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d0cfa7bbbaecdd46` |
| V1.5-SCHEMAS.sexp | 522 | 64 | `define-invariant` | `:V5I-C1-relation-detached` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `cc3f78cda4d37329` |
| V1.5-SCHEMAS.sexp | 530 | 65 | `define-record` | `LifecycleRecord/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `9e76da3faa10cd8b` |
| V1.5-SCHEMAS.sexp | 540 | 66 | `define-projection` | `SubjectCurrentStatus` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `5670a3305f19e378` |
| V1.5-SCHEMAS.sexp | 544 | 67 | `define-rule` | `lifecycle-overlay` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `5da09ce461d21aa5` |
| V1.5-SCHEMAS.sexp | 554 | 68 | `define-invariant` | `:V5I-A2-immutable-id` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ebfe29f7a2f9c6aa` |
| V1.5-SCHEMAS.sexp | 561 | 69 | `define-projection` | `ClaimArgumentIndex` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `54cccaf54351f752` |
| V1.5-SCHEMAS.sexp | 569 | 70 | `define-ref-classification` | `(CanonRule/1.authority_basis :hash-bearing (AuthorityBasis))` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `164f6ca1997e4b21` |
| V1.5-SCHEMAS.sexp | 597 | 71 | `define-construction-order` | `legal-ir-interpretive` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `790d5e89e13610fb` |
| V1.5-SCHEMAS.sexp | 610 | 72 | `define-invariant` | `:V5I-C1-acyclic` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ac594ee68a6194e8` |
| V1.5-SCHEMAS.sexp | 618 | 73 | `define-invariant` | `:V5I-08` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `8078131d6a312bca` |
| V1.5-SCHEMAS.sexp | 622 | 74 | `define-invariant` | `:V5I-09` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `e80f437bf4b9e2b3` |
| V1.5-SCHEMAS.sexp | 630 | 75 | `define-constitution-reference` | `v1.5-interpretive-binding` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `202e856f97dfb0a3` |
| V1.5-SCHEMAS.sexp | 641 | 76 | `define-invariant` | `:V5I-10` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `5710d0d7cc25a7c2` |
| V1.6-SCHEMAS.sexp | 8 | 0 | `spec-version` | `"v1.6-future-extensibility-public-cognition"` | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — | `78e78760e5b5ae34` |
| V1.6-SCHEMAS.sexp | 15 | 1 | `define-invariant` | `:V6I-01-lock-meanings-not-tools` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `886fe84e091a9a22` |
| V1.6-SCHEMAS.sexp | 17 | 2 | `define-invariant` | `:V6I-02-no-mandatory-model` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `58404ec00c17fd0f` |
| V1.6-SCHEMAS.sexp | 20 | 3 | `define-closed-enum` | `SafetyMode` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `f2de0430b4f48766` |
| V1.6-SCHEMAS.sexp | 25 | 4 | `define-invariant` | `:V6I-03-symbolic-only-complete` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `707ef235be866264` |
| V1.6-SCHEMAS.sexp | 29 | 5 | `define-invariant` | `:V6I-04-adapter-no-canonical-authority` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `37ed00daea0866c6` |
| V1.6-SCHEMAS.sexp | 32 | 6 | `define-invariant` | `:V6I-05-memory-owned-by-lawmax` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c749a209e249b8e5` |
| V1.6-SCHEMAS.sexp | 35 | 7 | `define-invariant` | `:V6I-06-critical-result-carries` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c94df04355dbc0e4` |
| V1.6-SCHEMAS.sexp | 38 | 8 | `define-invariant` | `:V6I-07-public-independent-of-private` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `47268e9a5ea670c5` |
| V1.6-SCHEMAS.sexp | 41 | 9 | `define-invariant` | `:V6I-08-self-improvement-gated` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `8d25b6a3e674337b` |
| V1.6-SCHEMAS.sexp | 43 | 10 | `define-invariant` | `:V6I-09-future-tech-is-adapter` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `a769154098391042` |
| V1.6-SCHEMAS.sexp | 51 | 11 | `define-closed-enum` | `ProposerKind` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `de073b79bbd459a4` |
| V1.6-SCHEMAS.sexp | 57 | 12 | `define-protocol` | `SemanticProposer` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `608c3ce36e66e26d` |
| V1.6-SCHEMAS.sexp | 67 | 13 | `define-adapter-contract` | `ONNXProposerAdapter` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `35197ad7e34f71fb` |
| V1.6-SCHEMAS.sexp | 71 | 14 | `define-adapter-contract` | `OCRPerceptionAdapter` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `b998bc4e834da73f` |
| V1.6-SCHEMAS.sexp | 75 | 15 | `define-invariant` | `:V6I-10-proposer-never-authority` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `78b3b4fa429e7032` |
| V1.6-SCHEMAS.sexp | 85 | 16 | `define-record` | `PerceptionEnvelope/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `45236b0a10e416bc` |
| V1.6-SCHEMAS.sexp | 92 | 17 | `define-reference` | `CandidateInterpretation/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `dbab024931378a6b` |
| V1.6-SCHEMAS.sexp | 96 | 18 | `define-reference` | `LegalIR/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `7ff3107628071d41` |
| V1.6-SCHEMAS.sexp | 100 | 19 | `define-record` | `MemoryEvent/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `dff03926fe9d1552` |
| V1.6-SCHEMAS.sexp | 108 | 20 | `define-record` | `CapabilityManifest/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d63728c84c3d93b3` |
| V1.6-SCHEMAS.sexp | 115 | 21 | `define-record` | `ToolInvocation/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `b317333d8349b968` |
| V1.6-SCHEMAS.sexp | 122 | 22 | `define-record` | `Plan/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `8b960fc1baeb5dfd` |
| V1.6-SCHEMAS.sexp | 127 | 23 | `define-reference` | `ActionIntent/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `a3d4c332d18b6149` |
| V1.6-SCHEMAS.sexp | 131 | 24 | `define-reference` | `Approval/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `fd50298c13b17025` |
| V1.6-SCHEMAS.sexp | 135 | 25 | `define-record` | `ExecutionReceipt/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `19b69d53d40e2c2b` |
| V1.6-SCHEMAS.sexp | 139 | 26 | `define-record` | `SafetyState/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `4202ce69a270fbb6` |
| V1.6-SCHEMAS.sexp | 143 | 27 | `define-reference` | `TrustBundle/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `625c55482fd1d530` |
| V1.6-SCHEMAS.sexp | 147 | 28 | `define-reference` | `DeclassificationReceipt/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `ab262b94a5ccd16f` |
| V1.6-SCHEMAS.sexp | 151 | 29 | `define-invariant` | `:V6I-11-contracts-closed-noncircular` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `96e38414a0f48734` |
| V1.6-SCHEMAS.sexp | 155 | 30 | `define-invariant` | `:V6I-12-no-vendor-in-core` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `edcfd6c8a71bdc80` |
| V1.6-SCHEMAS.sexp | 158 | 31 | `define-invariant` | `:V6I-REF-single-source-of-truth` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `7668243474147c25` |
| V1.6-SCHEMAS.sexp | 168 | 32 | `define-closed-enum` | `CognitionCapability` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `a45b5d9e0ec11005` |
| V1.6-SCHEMAS.sexp | 177 | 33 | `define-closed-enum` | `CognitionError` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `136db7ad2972ed5b` |
| V1.6-SCHEMAS.sexp | 183 | 34 | `define-record` | `MorphLattice/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `a958805e82f96532` |
| V1.6-SCHEMAS.sexp | 186 | 35 | `define-record` | `PackedParseForest/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `b4c610ffedaa0b71` |
| V1.6-SCHEMAS.sexp | 189 | 36 | `define-record` | `CoreferenceRecord/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c92023c32cb04def` |
| V1.6-SCHEMAS.sexp | 192 | 37 | `define-record` | `DiscourseState/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `6458c0780dc95291` |
| V1.6-SCHEMAS.sexp | 195 | 38 | `define-record` | `LegalSemanticAlternative/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `9d34ac7e72f687f4` |
| V1.6-SCHEMAS.sexp | 198 | 39 | `define-record` | `ClarificationState/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `eae1014a146fc944` |
| V1.6-SCHEMAS.sexp | 201 | 40 | `define-record` | `PromotionEvidence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `7a16dc1c18cebe57` |
| V1.6-SCHEMAS.sexp | 204 | 41 | `define-record` | `CognitionResult/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `fe4b4d51bc346cc1` |
| V1.6-SCHEMAS.sexp | 209 | 42 | `define-record` | `LanguageCognitionLayer/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `b420bf0be9454daf` |
| V1.6-SCHEMAS.sexp | 217 | 43 | `define-construction-order` | `cognition-stage-dag` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `7ccec82074bc8392` |
| V1.6-SCHEMAS.sexp | 231 | 44 | `define-mapping` | `cognition->existing-lisp-seat` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `0e941294436c348c` |
| V1.6-SCHEMAS.sexp | 247 | 45 | `define-rule` | `casegrammar-split` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `d4f85455718c33f2` |
| V1.6-SCHEMAS.sexp | 251 | 46 | `define-rule` | `common-lisp-cognition-usage` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `db61c3ef045cedc6` |
| V1.6-SCHEMAS.sexp | 261 | 47 | `define-invariant` | `:V6I-13-cognition-one-seat` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ffd66767dfbfb513` |
| V1.6-SCHEMAS.sexp | 265 | 48 | `define-invariant` | `:V6I-COG-symbolic-only` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `da2948086f58e2f0` |
| V1.6-SCHEMAS.sexp | 270 | 49 | `define-invariant` | `:V6I-COG-one-to-one` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `390e02de2553af02` |
| V1.6-SCHEMAS.sexp | 278 | 50 | `define-closed-enum` | `PublicMemoryType` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d5a95cdb6f4a4d25` |
| V1.6-SCHEMAS.sexp | 282 | 51 | `define-closed-enum` | `PublicMemoryScope` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `04051e3c55a07b8a` |
| V1.6-SCHEMAS.sexp | 284 | 52 | `define-closed-enum` | `MemoryType` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d85e02df672c06fb` |
| V1.6-SCHEMAS.sexp | 288 | 53 | `define-closed-enum` | `MemoryScope` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `a818d2b17c9ffb13` |
| V1.6-SCHEMAS.sexp | 289 | 54 | `define-record` | `MemoryPolicy/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `9f5b480c7a271141` |
| V1.6-SCHEMAS.sexp | 294 | 55 | `define-record` | `MemoryProjection/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d0d563a600d769fb` |
| V1.6-SCHEMAS.sexp | 297 | 56 | `define-invariant` | `:V6I-14-memory-model-boundary` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `f87b89618bd59cc0` |
| V1.6-SCHEMAS.sexp | 301 | 57 | `define-invariant` | `:V6I-15-memory-scope-isolation` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `d8ad8efad8c39e1a` |
| V1.6-SCHEMAS.sexp | 305 | 58 | `define-invariant` | `:V6I-MEM-public-base-clean` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `157a3e2338955274` |
| V1.6-SCHEMAS.sexp | 312 | 59 | `define-record` | `PrivateMemoryEvent/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `9d14a22da96869ab` |
| V1.6-SCHEMAS.sexp | 317 | 60 | `define-record` | `PrivateMatterProfile/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `e3091afa73493015` |
| V1.6-SCHEMAS.sexp | 323 | 61 | `define-record` | `RealTimeAssistance/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `16b46aff54334302` |
| V1.6-SCHEMAS.sexp | 328 | 62 | `define-record` | `EmbodimentInterfaces/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `ff006e79e24497d6` |
| V1.6-SCHEMAS.sexp | 334 | 63 | `define-invariant` | `:V6I-16-extension-isolation` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `768be6f79fc81eb4` |
| V1.6-SCHEMAS.sexp | 344 | 64 | `define-ref-classification-v6` | `(public-build :hash-bearing (LegalIR/1 MemoryEvent/1 TrustBundle/1 LanguageCognitionLayer/1 CognitionResult/1))` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `419c0424a4357a33` |
| V1.6-SCHEMAS.sexp | 348 | 65 | `define-invariant` | `:V6I-17-one-source-of-truth` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ac905a44a7ff1319` |
| V1.7-SCHEMAS.sexp | 7 | 0 | `spec-version` | `"v1.7-no-loss-root-authority-public-cognition"` | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — | `4d6ce18c501925b0` |
| V1.7-SCHEMAS.sexp | 14 | 1 | `define-invariant` | `:RA-I-1-root-authority-certifies-not-replaces` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `4cfab2a432da0802` |
| V1.7-SCHEMAS.sexp | 17 | 2 | `define-invariant` | `:RA-I-2-citation-primacy-no-false-certainty` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `7e899f83c7d7bbf9` |
| V1.7-SCHEMAS.sexp | 20 | 3 | `define-invariant` | `:RA-I-3-no-mandatory-model` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c08af45b5707f607` |
| V1.7-SCHEMAS.sexp | 23 | 4 | `define-invariant` | `:RA-I-4-public-independent-of-private` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `925967fe53817903` |
| V1.7-SCHEMAS.sexp | 26 | 5 | `define-invariant` | `:RA-I-5-one-seat-per-concept` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `f9c01833ec152f94` |
| V1.7-SCHEMAS.sexp | 34 | 6 | `define-reference` | `PerceptionEnvelope/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `6fbc92ac4cbdd688` |
| V1.7-SCHEMAS.sexp | 35 | 7 | `define-reference` | `MorphLattice/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `7fb367acbe9e5114` |
| V1.7-SCHEMAS.sexp | 36 | 8 | `define-reference` | `PackedParseForest/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `9cc44374e4ae5931` |
| V1.7-SCHEMAS.sexp | 37 | 9 | `define-reference` | `DiscourseState/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `1518f2b21ba58af2` |
| V1.7-SCHEMAS.sexp | 38 | 10 | `define-reference` | `PromotionEvidence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `bba94e53316e4a3d` |
| V1.7-SCHEMAS.sexp | 39 | 11 | `define-reference` | `CognitionResult/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d04f120dfadb82d4` |
| V1.7-SCHEMAS.sexp | 40 | 12 | `define-closed-enum` | `CognitionErrorV7` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `a894015def0dbc5a` |
| V1.7-SCHEMAS.sexp | 45 | 13 | `define-record` | `NormalizedDocument/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `53d1c035e54df271` |
| V1.7-SCHEMAS.sexp | 48 | 14 | `define-record` | `SegmentSequence/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `5c340b38b5dbe85c` |
| V1.7-SCHEMAS.sexp | 51 | 15 | `define-record` | `TokenStream/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `eef26abb85469a5a` |
| V1.7-SCHEMAS.sexp | 54 | 16 | `define-record` | `ReferenceGraph/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `6a6081a5638b56fa` |
| V1.7-SCHEMAS.sexp | 58 | 17 | `define-record` | `LegalEntityGraph/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `7a6fe67070fde33a` |
| V1.7-SCHEMAS.sexp | 62 | 18 | `define-record` | `LegalSemanticAlternativeSet/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `fe36dc2931cf1356` |
| V1.7-SCHEMAS.sexp | 66 | 19 | `define-record` | `InterpretiveProfileEvaluation/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `2d6ef45eb8eb7913` |
| V1.7-SCHEMAS.sexp | 70 | 20 | `define-record` | `ClarificationDecision/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `917313b79dc4fe1c` |
| V1.7-SCHEMAS.sexp | 75 | 21 | `define-record` | `ClarifiedInterpretation/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `5dcd35b01276208f` |
| V1.7-SCHEMAS.sexp | 80 | 22 | `define-construction-order` | `cognition-stage-dag-v7` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `1c84e3a43b7b7395` |
| V1.7-SCHEMAS.sexp | 95 | 23 | `define-invariant` | `:V7I-COG-info-preserving` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ce4450ae21d34782` |
| V1.7-SCHEMAS.sexp | 105 | 24 | `define-closed-enum` | `MemoryScopeV7` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `e07875ed400dd01e` |
| V1.7-SCHEMAS.sexp | 106 | 25 | `define-record` | `MemoryScopePolicy/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `cf36597b43489f5b` |
| V1.7-SCHEMAS.sexp | 111 | 26 | `define-invariant` | `:V7I-MEM-user-private-no-auto-public` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c2fc0526f5d29469` |
| V1.7-SCHEMAS.sexp | 115 | 27 | `define-invariant` | `:V7I-MEM-one-owner` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `f0ce26077f0ab148` |
| V1.7-SCHEMAS.sexp | 121 | 28 | `define-closed-enum` | `ArtifactRightsClass` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `a5206bf6f9112716` |
| V1.7-SCHEMAS.sexp | 124 | 29 | `define-closed-enum` | `RightsDisposition` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `f4ee69b71c58de34` |
| V1.7-SCHEMAS.sexp | 125 | 30 | `define-closed-enum` | `LegalReviewState` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `7180d34d169c2ce7` |
| V1.7-SCHEMAS.sexp | 126 | 31 | `define-record` | `RightsMatrix/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `19b6c2ce5e368c43` |
| V1.7-SCHEMAS.sexp | 135 | 32 | `define-record` | `LicensePolicy/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `6105268b5fd5fb35` |
| V1.7-SCHEMAS.sexp | 139 | 33 | `define-invariant` | `:V7I-RA-L-no-unlicensed` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `c3eb5dfc53357b9b` |
| V1.7-SCHEMAS.sexp | 147 | 34 | `define-closed-enum` | `ResolverInputKind` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `16e87a267e851a1e` |
| V1.7-SCHEMAS.sexp | 150 | 35 | `define-record` | `ResolverQuery/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `e0d07ab93e3ca2df` |
| V1.7-SCHEMAS.sexp | 153 | 36 | `define-record` | `AmbiguityResult/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `0772c200e04c6431` |
| V1.7-SCHEMAS.sexp | 155 | 37 | `define-record` | `ResolverResult/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `6c03d4ba169d040f` |
| V1.7-SCHEMAS.sexp | 163 | 38 | `define-record` | `ResolverReceipt/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `5972f6ab35e1f6a2` |
| V1.7-SCHEMAS.sexp | 166 | 39 | `define-invariant` | `:V7I-RA-I-deterministic` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `fc56e9d7150a6c88` |
| V1.7-SCHEMAS.sexp | 172 | 40 | `define-closed-enum` | `RetrievalFormat` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `25d1d4c1e7ad82da` |
| V1.7-SCHEMAS.sexp | 173 | 41 | `define-record` | `CanonicalRetrievalView/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `abe84e25194005a5` |
| V1.7-SCHEMAS.sexp | 180 | 42 | `define-invariant` | `:V7I-RA-R-proof-carrying-pages` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `662208f86f501067` |
| V1.7-SCHEMAS.sexp | 188 | 43 | `define-record` | `CitationPanel/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `2d4fc993ccb51d00` |
| V1.7-SCHEMAS.sexp | 191 | 44 | `define-record` | `CitationSupremacyMetric/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `54601bda9d262b35` |
| V1.7-SCHEMAS.sexp | 199 | 45 | `define-invariant` | `:V7I-RA-K-metrics-not-truth` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `6c204345f94cfa0b` |
| V1.7-SCHEMAS.sexp | 205 | 46 | `define-record` | `DatasetSnapshot/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `11f101b79edf5ef5` |
| V1.7-SCHEMAS.sexp | 209 | 47 | `define-record` | `DatasetDelta/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `41573efed064cc5d` |
| V1.7-SCHEMAS.sexp | 212 | 48 | `define-invariant` | `:V7I-RA-T-lawmax-canonical-home` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `17d54070a6bce334` |
| V1.7-SCHEMAS.sexp | 218 | 49 | `define-record` | `AnonymizationReceipt/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `27c7152d6141de60` |
| V1.7-SCHEMAS.sexp | 222 | 50 | `define-record` | `NonAuthoritativeTranslation/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `19beb942f65207de` |
| V1.7-SCHEMAS.sexp | 227 | 51 | `define-record` | `TenantProfile/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c96b903a3abb1590` |
| V1.7-SCHEMAS.sexp | 234 | 52 | `define-invariant` | `:V7I-RA-INST-no-authority` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `76e07bca2b00a93f` |
| V1.7-SCHEMAS.sexp | 241 | 53 | `define-closed-enum` | `RootAuthorityState` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `81586043cdc1d6d6` |
| V1.7-SCHEMAS.sexp | 242 | 54 | `define-record` | `RootAuthorityQualification/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `49ca27b2fa9cb9af` |
| V1.7-SCHEMAS.sexp | 249 | 55 | `define-invariant` | `:V7I-RA-qual-revocable` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `2137764be668295a` |
| V1.7-SCHEMAS.sexp | 257 | 56 | `define-reference` | `availability_state` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `9b6bf259151d4101` |
| V1.7-SCHEMAS.sexp | 258 | 57 | `define-reference` | `census_coverage_state` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `d650dbb0336e8680` |
| V1.7-SCHEMAS.sexp | 259 | 58 | `define-decision-function` | `census-coverage-decision-v7` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `5551087f2165da4c` |
| V1.7-SCHEMAS.sexp | 280 | 59 | `define-invariant` | `:V7I-COV-availability-live` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `2048769c119b8ba8` |
| V1.7-SCHEMAS.sexp | 290 | 60 | `define-ra-closure-roots` | `(public-roots (LegalIR/1 MemoryEvent/1 TrustBundle/1 LanguageCognitionLayer/1 CognitionResult/1 CanonicalRetrievalView/1 ResolverResult/1 CitationSupremacyMetric/1 DatasetSnapshot/1 RightsMatrix/1 RootAuthorityQualification/1))` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `7b8d34d922d003cf` |
| V1.7-SCHEMAS.sexp | 297 | 61 | `define-invariant` | `:V7I-PUBPRIV-acyclic` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `b5f19b23d9e1c22b` |
| V1.7-SCHEMAS.sexp | 301 | 62 | `define-invariant` | `:V7I-no-mandatory-model-v7` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `bcb4b395e9cd7436` |
| V1.7-SCHEMAS.sexp | 308 | 63 | `define-pipeline` | `symbolic-only-path` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `513dd6151f3d5ecc` |
| V1.7-SCHEMAS.sexp | 318 | 64 | `define-invariant` | `:V7I-SYM-reachable` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `97b6ec00b719e946` |
| V1.7-SCHEMAS.sexp | 327 | 65 | `define-write-authority` | `:store="journal"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `a90c5d5feea775ef` |
| V1.7-SCHEMAS.sexp | 328 | 66 | `define-write-authority` | `:store="memory"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `27a53bfaf93b06e1` |
| V1.7-SCHEMAS.sexp | 329 | 67 | `define-write-authority` | `:store="legal-ir"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `e1692201f4cbb245` |
| V1.7-SCHEMAS.sexp | 330 | 68 | `define-write-authority` | `:store="trust-bundle"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `7e884b76ee8c5461` |
| V1.7-SCHEMAS.sexp | 331 | 69 | `define-write-authority` | `:store="coverage-ledger"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `15651aad3807d97a` |
| V1.7-SCHEMAS.sexp | 332 | 70 | `define-write-authority` | `:store="citation-observatory"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `ae424324b2a67eba` |
| V1.7-SCHEMAS.sexp | 333 | 71 | `define-write-authority` | `:store="dataset-distribution"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `c4c265d263fff02b` |
| V1.7-SCHEMAS.sexp | 334 | 72 | `define-write-authority` | `:store="static-site"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `b2727aa85e46637a` |
| V1.7-SCHEMAS.sexp | 335 | 73 | `define-write-authority` | `:store="resolver-dataset"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `10e15cd332515a6e` |
| V1.7-SCHEMAS.sexp | 336 | 74 | `define-write-authority` | `:store="tenant-profile"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `8a4ddcb94b3a109f` |
| V1.7-SCHEMAS.sexp | 337 | 75 | `define-invariant` | `:V7I-OWN-single-writer` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `b5eecef332133977` |
| V1.7-SCHEMAS.sexp | 346 | 76 | `define-capability-seat` | `:capability=:RESOLVE_IDENTIFIER` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `a3f6edae98a89467` |
| V1.7-SCHEMAS.sexp | 347 | 77 | `define-capability-seat` | `:capability=:PUBLIC_RETRIEVAL` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `bd26bf5f1a1a7621` |
| V1.7-SCHEMAS.sexp | 348 | 78 | `define-capability-seat` | `:capability=:CITATION_MEASURE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `6bffbdb57f03c16e` |
| V1.7-SCHEMAS.sexp | 349 | 79 | `define-capability-seat` | `:capability=:DATASET_DISTRIBUTE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `60682d84cf634343` |
| V1.7-SCHEMAS.sexp | 350 | 80 | `define-capability-seat` | `:capability=:JURIS_ANONYMIZE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `7ab27ab8bc6af295` |
| V1.7-SCHEMAS.sexp | 351 | 81 | `define-capability-seat` | `:capability=:EXPRESSION_TRANSLATE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `ed27a7c4c2ebdfb1` |
| V1.7-SCHEMAS.sexp | 352 | 82 | `define-capability-seat` | `:capability=:RIGHTS_LICENSE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `dc8375fb2683ec43` |
| V1.7-SCHEMAS.sexp | 353 | 83 | `define-invariant` | `:V7I-CAP-seat-closure` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `dbbdfaea66262809` |
| V1.7-SCHEMAS.sexp | 361 | 84 | `define-source-type-coverage` | `:registry="LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md"` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `1927074952d0beba` |
| V1.7-SCHEMAS.sexp | 372 | 85 | `define-invariant` | `:V7I-SRC-open-fail-closed` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `6a21ebdea85a4b3a` |
| V1.7-SCHEMAS.sexp | 379 | 86 | `define-wp-reconciliation` | `(:concept COGNITION_DAG :wp WP-08 :evidence "WP-08.md:19 Public Legal Discernment core")` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `d5e94cfa5e26055a` |
| V1.7-SCHEMAS.sexp | 400 | 87 | `define-invariant` | `:V7I-WP-honest` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `f89a256a19c4e7bf` |
| V1.8-SCHEMAS.sexp | 7 | 0 | `spec-version` | `"v1.8-final-pre-freeze-integration"` | OUT_OF_MIGRATION_SCOPE | AUTHORITATIVE_AT_SOURCE | — | `8f3e316a87476d51` |
| V1.8-SCHEMAS.sexp | 14 | 1 | `define-invariant` | `:V8I-01-certifies-not-replaces` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `aa3e7c03b7d8e73f` |
| V1.8-SCHEMAS.sexp | 17 | 2 | `define-invariant` | `:V8I-02-no-mandatory-model` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `3a8dedd47a4fe98c` |
| V1.8-SCHEMAS.sexp | 20 | 3 | `define-invariant` | `:V8I-03-one-seat` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ce0c53b4c56fdf3a` |
| V1.8-SCHEMAS.sexp | 28 | 4 | `define-closed-enum` | `ClarificationLifecycleState` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `e42b407441408f13` |
| V1.8-SCHEMAS.sexp | 31 | 5 | `define-closed-enum` | `MergeSemanticsV8` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `0715d4ce29e4f984` |
| V1.8-SCHEMAS.sexp | 32 | 6 | `define-record` | `ClarificationRequest/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `1f0344ab75354724` |
| V1.8-SCHEMAS.sexp | 36 | 7 | `define-record` | `ClarificationResponse/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `4b0b2caaf5372d17` |
| V1.8-SCHEMAS.sexp | 40 | 8 | `define-record` | `ClarifiedInterpretation/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `ecf44277925c137e` |
| V1.8-SCHEMAS.sexp | 47 | 9 | `define-invariant` | `:V8I-CLARIFY-cardinality` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `dba0f816daa79248` |
| V1.8-SCHEMAS.sexp | 53 | 10 | `define-cognition-graph` | `cognition-graph-v8` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `e10c0e89f27f0f1a` |
| V1.8-SCHEMAS.sexp | 66 | 11 | `define-invariant` | `:V8I-COGGRAPH-acyclic-except-resume` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `48855a783534adb1` |
| V1.8-SCHEMAS.sexp | 75 | 12 | `define-closed-enum` | `DimensionState` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `334cddef9e69b993` |
| V1.8-SCHEMAS.sexp | 76 | 13 | `define-record` | `RootAuthorityStatus/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `809ee3443b46f2fc` |
| V1.8-SCHEMAS.sexp | 83 | 14 | `define-closed-enum` | `RelianceClass` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `161f98f3cd0d41b0` |
| V1.8-SCHEMAS.sexp | 84 | 15 | `define-record` | `RelianceProjection/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `8bd8eb17ccf1aa11` |
| V1.8-SCHEMAS.sexp | 88 | 16 | `define-dimension-policy` | `root-authority-dimensions` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `9dfbac8b2307366c` |
| V1.8-SCHEMAS.sexp | 97 | 17 | `define-invariant` | `:V8I-RASTATUS-product` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `affef9a944cd46d4` |
| V1.8-SCHEMAS.sexp | 107 | 18 | `define-reference` | `USC-expression` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `103d8bc58e119565` |
| V1.8-SCHEMAS.sexp | 109 | 19 | `define-closed-enum` | `CitationTemporalResolution` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `bf7f32d45f2fd901` |
| V1.8-SCHEMAS.sexp | 110 | 20 | `define-record` | `CanonicalCitationURI/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `713ad3555fad3c99` |
| V1.8-SCHEMAS.sexp | 116 | 21 | `define-record` | `ResolutionRecord/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `4f846f515bf69841` |
| V1.8-SCHEMAS.sexp | 119 | 22 | `define-record` | `MultiCommitment/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `40f51cf0eee1f5c8` |
| V1.8-SCHEMAS.sexp | 124 | 23 | `define-record` | `ReAnchoringManifest/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `40d8b83fc5b82926` |
| V1.8-SCHEMAS.sexp | 128 | 24 | `define-invariant` | `:V8I-EPOCH-one-expression` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `8b9ef85ed1980d7c` |
| V1.8-SCHEMAS.sexp | 139 | 25 | `define-closed-enum` | `ContinuityRole` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `66e403a32193c7c5` |
| V1.8-SCHEMAS.sexp | 140 | 26 | `define-record` | `ContinuityPolicy/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `60a1123c748d00fc` |
| V1.8-SCHEMAS.sexp | 145 | 27 | `define-record` | `EmergencyFreeze/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `27f89449d9bf85de` |
| V1.8-SCHEMAS.sexp | 149 | 28 | `define-invariant` | `:V8I-CONT-separated` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `05e3e522537189e2` |
| V1.8-SCHEMAS.sexp | 160 | 29 | `define-record` | `PublicCorrectionEvent/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `f95ea27a3dcaa967` |
| V1.8-SCHEMAS.sexp | 165 | 30 | `define-record` | `RestrictedForensicRecord/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `e145018456a3be9f` |
| V1.8-SCHEMAS.sexp | 168 | 31 | `define-invariant` | `:V8I-CORR-privacy` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `0f133b2167b2a20f` |
| V1.8-SCHEMAS.sexp | 177 | 32 | `define-closed-enum` | `MetricAssuranceClass` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `082460fb01fd1f6c` |
| V1.8-SCHEMAS.sexp | 178 | 33 | `define-closed-enum` | `ReproTier` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `612e7b6d283a6d49` |
| V1.8-SCHEMAS.sexp | 179 | 34 | `define-record` | `CitationMetricV8/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `6a3090b0a51cb3ca` |
| V1.8-SCHEMAS.sexp | 184 | 35 | `define-invariant` | `:V8I-RA-K-tiered` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ed059e89fc71457b` |
| V1.8-SCHEMAS.sexp | 193 | 36 | `define-record` | `SidecarSourceProfile/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `11c577d370d5adb2` |
| V1.8-SCHEMAS.sexp | 200 | 37 | `define-invariant` | `:V8I-SIDE-gdpr-honest` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `7e6048e367de6026` |
| V1.8-SCHEMAS.sexp | 207 | 38 | `define-record` | `LawmaxStatusVsMark/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `a53ee4a1345b00a7` |
| V1.8-SCHEMAS.sexp | 212 | 39 | `define-invariant` | `:V8I-MARK-separated` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `81f2e0dd8f25469e` |
| V1.8-SCHEMAS.sexp | 219 | 40 | `define-closed-enum` | `CryptoMaturity` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `6a3f80ead26ef58e` |
| V1.8-SCHEMAS.sexp | 220 | 41 | `define-record` | `CryptoSuiteRegistry/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `39844155785aa635` |
| V1.8-SCHEMAS.sexp | 226 | 42 | `define-record` | `RecoveryEpoch/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `b966a38a93efeca8` |
| V1.8-SCHEMAS.sexp | 231 | 43 | `define-invariant` | `:V8I-FROST-precise` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ab965078f976510a` |
| V1.8-SCHEMAS.sexp | 243 | 44 | `define-capability-seat` | `:capability=:RESOLVE_IDENTIFIER` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `5daae96bc00d5c17` |
| V1.8-SCHEMAS.sexp | 244 | 45 | `define-capability-seat` | `:capability=:PUBLIC_RETRIEVAL` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `174b2ca9d4d446e1` |
| V1.8-SCHEMAS.sexp | 245 | 46 | `define-capability-seat` | `:capability=:CITATION_MEASURE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `8e7f5dcb2f8dc4b8` |
| V1.8-SCHEMAS.sexp | 246 | 47 | `define-capability-seat` | `:capability=:DATASET_DISTRIBUTE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `c2ea2482b5498784` |
| V1.8-SCHEMAS.sexp | 247 | 48 | `define-capability-seat` | `:capability=:JURIS_RATIO` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `fb3a9efd4cc841fa` |
| V1.8-SCHEMAS.sexp | 248 | 49 | `define-capability-seat` | `:capability=:RIGHTS_LICENSE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `a1b72ae08b2fde29` |
| V1.8-SCHEMAS.sexp | 249 | 50 | `define-capability-seat` | `:capability=:EXPRESSION_TRANSLATE` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `c0a9282f4c8beaf8` |
| V1.8-SCHEMAS.sexp | 250 | 51 | `define-invariant` | `:V8I-CAP-real` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `763534c8d8c9dc79` |
| V1.8-SCHEMAS.sexp | 259 | 52 | `define-ra-closure-roots` | `(public-roots (LegalIR/1 MemoryEvent/1 TrustBundle/1 CognitionResult/1 CanonicalRetrievalView/1 ResolverResult/1 CitationMetricV8/1 DatasetSnapshot/1 RightsMatrix/1 RootAuthorityStatus/1))` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `67363bac46c081c4` |
| V1.8-SCHEMAS.sexp | 277 | 53 | `define-invariant` | `:V8I-PUBPRIV-all-families` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `407a8df54db4e90b` |
| V1.8-SCHEMAS.sexp | 286 | 54 | `define-write-authority` | `:store="journal"` | IMPORTED | CANONICAL_IN_MODEL | — | `a90c5d5feea775ef` |
| V1.8-SCHEMAS.sexp | 287 | 55 | `define-write-authority` | `:store="memory"` | IMPORTED | CANONICAL_IN_MODEL | — | `27a53bfaf93b06e1` |
| V1.8-SCHEMAS.sexp | 288 | 56 | `define-write-authority` | `:store="legal-ir"` | IMPORTED | CANONICAL_IN_MODEL | — | `e1692201f4cbb245` |
| V1.8-SCHEMAS.sexp | 289 | 57 | `define-write-authority` | `:store="trust-bundle"` | IMPORTED | CANONICAL_IN_MODEL | — | `7e884b76ee8c5461` |
| V1.8-SCHEMAS.sexp | 290 | 58 | `define-write-authority` | `:store="coverage-ledger"` | IMPORTED | CANONICAL_IN_MODEL | — | `15651aad3807d97a` |
| V1.8-SCHEMAS.sexp | 291 | 59 | `define-write-authority` | `:store="citation-observatory"` | IMPORTED | CANONICAL_IN_MODEL | — | `ae424324b2a67eba` |
| V1.8-SCHEMAS.sexp | 292 | 60 | `define-write-authority` | `:store="dataset-distribution"` | IMPORTED | CANONICAL_IN_MODEL | — | `c4c265d263fff02b` |
| V1.8-SCHEMAS.sexp | 293 | 61 | `define-write-authority` | `:store="static-site"` | IMPORTED | CANONICAL_IN_MODEL | — | `b2727aa85e46637a` |
| V1.8-SCHEMAS.sexp | 294 | 62 | `define-write-authority` | `:store="resolver-dataset"` | IMPORTED | CANONICAL_IN_MODEL | — | `10e15cd332515a6e` |
| V1.8-SCHEMAS.sexp | 295 | 63 | `define-write-authority` | `:store="tenant-profile"` | IMPORTED | CANONICAL_IN_MODEL | — | `8a4ddcb94b3a109f` |
| V1.8-SCHEMAS.sexp | 296 | 64 | `define-invariant` | `:V8I-OWN-universal` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `266efa1f30e9cc20` |
| V1.8-SCHEMAS.sexp | 303 | 65 | `define-wp-reconciliation` | `(:concept COGNITION_DAG :wp WP-08 :file "WP-08.md" :evidence "Public Legal Discernment")` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `26fc7e9bec3f2e72` |
| V1.8-SCHEMAS.sexp | 320 | 66 | `define-invariant` | `:V8I-WP-real` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `ecd1b36c6b864e0f` |
| V1.8-SCHEMAS.sexp | 326 | 67 | `define-pipeline` | `symbolic-only-path` | IMPORTED | CANONICAL_IN_MODEL | — | `a9d700ce9ebcdd13` |
| V1.8-SCHEMAS.sexp | 336 | 68 | `define-invariant` | `:V8I-SYM-exact` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `481f7627596db21f` |
| V1.8-SCHEMAS.sexp | 345 | 69 | `define-reference` | `LegalIR/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c30e7536fa5f8782` |
| V1.8-SCHEMAS.sexp | 346 | 70 | `define-reference` | `TrustBundle/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `e617e7d18b7b3269` |
| V1.8-SCHEMAS.sexp | 347 | 71 | `define-reference` | `MemoryEvent/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `c9ed4029fde4211a` |
| V1.8-SCHEMAS.sexp | 348 | 72 | `define-reference` | `CognitionResult/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `051d9a78fa7a5d61` |
| V1.8-SCHEMAS.sexp | 349 | 73 | `define-reference` | `DeclassificationReceipt/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `ccd6ef97f0c05fb2` |
| V1.8-SCHEMAS.sexp | 350 | 74 | `define-reference` | `ResolverResult/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `3be48105d64fdac1` |
| V1.8-SCHEMAS.sexp | 351 | 75 | `define-reference` | `DatasetSnapshot/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `6ddaa1d027cdd75a` |
| V1.8-SCHEMAS.sexp | 352 | 76 | `define-reference` | `RightsMatrix/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `b2a2aa8759363817` |
| V1.8-SCHEMAS.sexp | 353 | 77 | `define-invariant` | `:V8I-XREF-real` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `91b5846adca7fc5b` |
| V1.8-SCHEMAS.sexp | 363 | 78 | `define-cognition-node-types` | `cognition-graph-v8-types` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `fb29edbf7f0538ec` |
| V1.8-SCHEMAS.sexp | 386 | 79 | `define-invariant` | `:V8I-COG-typed-edges` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `300a63df8a936099` |
| V1.8-SCHEMAS.sexp | 394 | 80 | `define-cardinality-table` | `clarified-interpretation-cardinality` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `8f69eed47da08ee1` |
| V1.8-SCHEMAS.sexp | 398 | 81 | `define-fixtures` | `clarified-interpretation-fixtures` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `2fe8caba1d5d86b1` |
| V1.8-SCHEMAS.sexp | 411 | 82 | `define-reliance-aggregation` | `reliance-of` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-3 | `946b0e12430f511d` |
| V1.8-SCHEMAS.sexp | 425 | 83 | `define-canonical-identity` | `LegalIR/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `52be402bf0c497ef` |
| V1.8-SCHEMAS.sexp | 426 | 84 | `define-canonical-identity` | `TrustBundle/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `8cda5dc4f7494e97` |
| V1.8-SCHEMAS.sexp | 427 | 85 | `define-canonical-identity` | `DeclassificationReceipt/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `f5ba0def888ccc30` |
| V1.8-SCHEMAS.sexp | 428 | 86 | `define-canonical-identity` | `CognitionResult/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `fe4abfae8a4675e6` |
| V1.8-SCHEMAS.sexp | 429 | 87 | `define-canonical-identity` | `MemoryEvent/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `9b1b9861e048d3b0` |
| V1.8-SCHEMAS.sexp | 430 | 88 | `define-canonical-identity` | `ResolverResult/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `ed69c7fafb572c8b` |
| V1.8-SCHEMAS.sexp | 431 | 89 | `define-canonical-identity` | `DatasetSnapshot/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `50de133130ffab04` |
| V1.8-SCHEMAS.sexp | 432 | 90 | `define-canonical-identity` | `RightsMatrix/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `52a3c916f50b45f0` |
| V1.8-SCHEMAS.sexp | 433 | 91 | `define-invariant` | `:V8I-XREF-identity` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `11a82e28a0be0bf4` |
| V1.8-SCHEMAS.sexp | 444 | 92 | `define-ra-delta-seats` | `(:delta RA-EPOCH :seat CanonicalCitationURI/1 :owner S25 :requirement RA8-EPOCH :test T8-EPOCH)` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-1 | `52a9ccf34a7e9fa9` |
| V1.8-SCHEMAS.sexp | 452 | 93 | `define-record` | `JurisdictionNamespace/1` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-2 | `2df203498672d407` |
| V1.8-SCHEMAS.sexp | 455 | 94 | `define-invariant` | `:V8I-RA-DELTA-seats` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `aad63e39c1b456da` |
| V1.8-SCHEMAS.sexp | 459 | 95 | `define-invariant` | `:V8I-SYM-structural` | DEFERRED_DATA_IMPORT | AUTHORITATIVE_AT_SOURCE | DDI-4 | `9267530969beb559` |

## H. Discrepancies with the existing ledger

**None.** Every (file, class) on disk has exactly one ledger row with the same count, status and batch; no phantom rows; no duplicate rows. The ledger's claims 66 / 4 / 56 / 6 / 332 are independently CONFIRMED.

Non-count observations recorded for the builder (not ledger errors):
1. `build_deferred.py` classifies by HEAD ONLY; a source form whose head is misspelled (e.g. `define-recrod`) would be a fail-closed FATAL (no batch) — good — but a form with a KNOWN head and a wrong/ambiguous body (e.g. a `define-record` with no fields) is still counted as a migratable instance. Instance-level validity is not part of the ledger and must be part of each DDI batch's entry criteria.
2. The V1.7 `define-write-authority` and V1.8 `define-write-authority` are content-identical (10/10 rows), yet one is IMPORTED and the other DEFERRED (DDI-1). The ledger is right to count both; the matrix must give the V1.7 class a SUPERSEDED-IDENTICAL rule rather than a second import.
3. The model's `wp` facts (14 ids) were derived from `define-subsystem :future-wp` tokens, not from `define-wp-purpose` (16 forms, DDI-4). `WP-00`, `WP-05`, `WP-10` exist in the source but not in the model; `DEFERRED` exists in the model but is not a `define-wp-purpose`. This is a pre-existing partial overlap between an IMPORTED derivation and a DEFERRED class — a named seat question for DDI-4 (see execution matrix).
4. `define-invariant` forms (92 total across **six** registries — INTERFACE 1, SUBSYSTEM 2, V1.5 22, V1.6 21, V1.7 23, V1.8 23; DDI-4) are keyword-named docstring-only forms; they carry no machine-checkable structure and their "import" is a representation decision (rationale-anchor facts vs. prose seat), not a data copy.

## I. Blockers named by this census (items that are NOT classifiable as pure data)

- **BLK-C1** Nested-list forms (every `define-record` field list, every `define-closed-enum` value list, cognition graph edge lists, `define-ra-closure-roots`, `define-cardinality-table`, `define-fixtures`, `define-wp-reconciliation`, `define-ra-delta-seats`, `define-dimension-policy`, `define-cognition-node-types`, `define-construction-order`, `define-pipeline`(V1.7)) cannot be represented under MODEL-SCHEMA.sexp L1 (values must be string | integer | plain symbol). Each needs a declared flattening rule or a schema extension BEFORE its batch starts. This is a schema-extension decision, not a data fact.
- **BLK-C2** Keyword symbols (`:V8I-01-…`, `:CODE`, `:MANDATORY`, `:OK`) are not admissible model values; a rendering rule (strip colon / upper-case) must be declared once (one seat) — it already exists for the checker (`canonical_value`) but not for imported keyword data.
- **BLK-C4** The four IMPORTED classes dropped 10 + 4 + 2 + 8 source keys on import (§D2); `PROMOTION-IMPORTED :state PERMITTED` and `:authority CANONICAL_IN_MODEL` are over-broad at field level. Whether those fields are re-imported (which batch?), retired with proof, or left authoritative at source must be decided before DDI-1 — the pipeline's symbolic-only guarantee is the most consequential of them.
- **BLK-C3** The `define-invariant`/`define-rule`/`define-gate`/`define-protocol`/`define-constitution-reference` classes (DDI-4, 128 of the 332 forms) are prose-bearing; the model has no prose seat except `rationale` anchors. Whether DDI-4 imports the TEXT or only ANCHORS is an architectural decision the creator must take (the model's stated principle is "prose lives in AUTHORED_NORMATIVE_PROSE, not duplicated").

## I-bis. Corrections applied to this document after adversarial review

1. §H(4) said the 92 `define-invariant` forms span "five files"; the per-file counts in §F sum over **six** registries. Corrected above. Found by the DDI-4 Common Lisp-native agent re-deriving the count with its own grep, not by the ledger.
2. §D2 (field-level coverage of the IMPORTED classes) and blocker **BLK-C4** were added after the interface dossier showed 44 of 60 `define-interface` forms need a schema extension and 16 an architectural decision — evidence that `CANONICAL_IN_MODEL` is over-broad at field level even though the class-level counts are exact.

## J. Reproduction

```
python3 census.py  <clone>/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL  <outdir>   # census.json
python3 census2.py <clone>/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL  <outdir>   # forms.tsv, forms.json, imported-instance-check.json
python3 dag.py     <clone>/deployment/collab/design/OMEGA2/CHANGE-PROPOSAL  <outdir>   # dag.json
```
Scripts live only in the session scratchpad; nothing was written into the repository.
