# POST-DDI-FULL-BUILD-READINESS

**Read-only reconnaissance artifact — NOT a repository file. No ceiling adjudication is made here; the canonical model remains incomplete until DDI-1…DDI-4 are imported and Option A is actually executed.** Target: commit `4ee2b58a8df0941845ab786bd0ff859844b94dde`, tree `ad71185a26b3beb39da6d50c09f567cff0475def`.

## 1. No-loss map: DDI class → canonical module → requirement → test → Option-A gate (candidate) → future packet (readiness agent)

## READINESS MAP — the no-loss map for the 56 deferred source classes
#### DDI class → canonical module → requirement → test → Option-A gate (CANDIDATE) → future implementation packet

**Read-only reconnaissance. No gate, battery or generator was executed. Nothing in `RO` or in the working
tree was modified.** Target: commit `4ee2b58a8df0941845ab786bd0ff859844b94dde`, tree
`ad71185a26b3beb39da6d50c09f567cff0475def`. Every number below is either recomputed by this agent from the
clone (scripts kept beside this file) or carried from a named upstream artifact with its own citation.
No institutional or architectural decision is taken here; disagreements are filed as ADJUDICATION ITEMS.

### 0. What I recomputed myself (so the map is not a restatement of the matrices)

| # | recomputation | script | result | agrees with |
|---|---|---|---|---|
| M1 | s-expression re-scan of the six registries: top-level forms per (file, head) class | `scan_nesting.py` | **66 classes / 435 forms** | orchestrator census (66/435) — exact |
| M2 | per class: how many forms contain a nested list (depth ≥ 2), max depth, plist-headed forms | `scan_nesting.py` → `nesting.json` | **39 of 66 classes** carry ≥1 nested-list form; 29 of the 56 deferred ones do | new measurement (N4 stated the problem, never the count) |
| M3 | per deferred class: does ANY of its form names occur in the 13 non-ledger hash-pinned modules? | `scan_consumers.py` → `model-consumers.json` | **26 CONFIRMED-ABSENT · 13 PRESENT · 17 NOT-NAME-TESTABLE** (= 56) | matrix `consumers` cells for the 18 that state it in prose — no contradiction |
| M4 | proposed target modules vs `ROOT.sexp` `:composition` and vs every `*.sexp` tracked in the repo | `build_map.py` | **25 classes propose 10 modules that do not exist**: `invariants.sexp`(9) `decision-functions.sexp`(7) `cognition-graph.sexp`(2) `file-dispositions.sexp`(2) `rules.sexp` `adapters.sexp` `enums.sexp` `capability-seats.sexp` `record-fields.sexp` `source-type-coverage.sexp` | new measurement |
| M5 | model requirement/test/wp/req-map universe re-parsed from `requirements-tests-workpackets.sexp` | `build_map.py` | 24 requirement · 21 test · 14 wp · 28 req-map · 26 subsystems | orchestrator N7/N8 |
| M6 | `type :classification` vs `subsystem :classification` for all 60 types | inline (§6) | **exactly 1 crossing**: `RestrictedForensicRecord/1` PRIVATE owned by PUBLIC `S18` | new finding |
| M7 | negative-witness presence for each of the 21 model `test` facts | inline (§5) | 19 have one; **`RA-Q-RESOLVE` and `RA-Q-TENANT` have none anywhere in the repo** | orchestrator N7 (direction), sharpened to an exact pair |
| M8 | `TRACEABILITY-MATRIX.md` requirement rows with no test token | inline (§5) | 134 distinct `R-nnn`; **6 rows carry no test at all** | orchestrator N8 (134) |

### 1. The five columns — what each one is, and what it is NOT

* **DDI class** — a `(file, head)` pair, the unit the deferred ledger enumerates
  (`ARCHITECTURE-MODEL/deferred-imports.sexp`; batch map `build_deferred.py:90-105`).
* **canonical module** — the *proposed* seat from the execution matrices (`WORK/agents/matrix-DDI-*/matrix.json`,
  field `proposed_canonical_target_module`), trimmed to its leading clause. A module name outside `ROOT.sexp`'s
  14-module `:composition` is flagged `NEW-MODULE-PROPOSED(L7)`.
* **requirement / test** — the matrix row's OWN leading verdict token (`EXISTING`/`PARTIAL`/`NEW`/`NONE_OR_UNKNOWN`),
  followed by the ids that are actual model `requirement`/`test` facts. Ids that are *named* but are not facts are
  reported as gaps `L6-REQ-OUTSIDE-MODEL` / `L6-TEST-OUTSIDE-MODEL`, never silently promoted.
* **Option-A gate (CANDIDATE)** — the gate concepts G01…G21 of `ARCHITECTURE-MODEL-GATE.sh @ a2f45f6d`, as
  identified by `WORK/agents/gates-matrix/survival-matrix.md`. **This identification is a CANDIDATE, not a proof**:
  the phrase "Full build, all 20 gates" exists in no tracked file of any ref, and the gates-skeptic finding S-1
  (`WORK/agents/gates-skeptic/findings.md:28-33`) shows the evidence supports a *concept* identity at a *different
  scope* (the same G1…G21 demanded over the complete 66-class model), not a set identity with the 20 `ck` calls.
  Assignment is by the documented rules in §3 — never by guessing which gate "feels" related.
* **future packet** — a `WP-nn` derived **only** from primary sources: the owner subsystem's `:future-wp`
  (`SUBSYSTEM-REGISTRY.sexp`, 26 forms at :35-124) and/or `define-wp-reconciliation`'s concept row
  (`V1.8-SCHEMAS.sexp:303-319`, `V1.7-SCHEMAS.sexp:379-399`). Where neither names the class,
  the value is `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED` — the token the registries themselves use
  (V1.8-SCHEMAS.sexp:315-319) for "no WP owns this; do not invent a mapping".
  *Caveat, stated so the cell is not read as more than it is:* for the three classes that ARE the packet
  vocabulary — `SUBSYSTEM-REGISTRY__define-wp-purpose` and the two `define-wp-reconciliation` classes — the
  derived cell shows only what their **owner subsystems** say (e.g. `S02 → WP-02`, `S26 → DEFERRED`). Their own
  content names 11 WPs plus `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED` five times (`V1.8:304-319`). Whether a
  packet-defining class can itself be owned by a packet is RP-05 / §4, not a value I fill in.

### 2. The map
##### DDI-1 — 12 classes

| # | DDI class (`file__head`) | forms | proposed canonical module | requirement | test | Option-A gate (CANDIDATE) | future packet | gaps |
|---|---|---|---|---|---|---|---|---|
| 1 | `V1.5-SCHEMAS__define-construction-order` (V1.5-SCHEMAS.sexp:597) | 1 | dependencies-and-boundaries.sexp | NEW | NEW | G02 G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-08 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED; L6-TEST-OUTSIDE-MODEL(V5Q-F1) |
| 2 | `V1.5-SCHEMAS__define-required-refs` (V1.5-SCHEMAS.sexp:209) | 1 | interfaces-and-types.sexp | NEW | NEW | G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-01 | NO-REQUIREMENT-FACT; NO-TEST-FACT; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED; L6-TEST-OUTSIDE-MODEL(V5Q-D2-06) |
| 3 | `V1.6-SCHEMAS__define-construction-order` (V1.6-SCHEMAS.sexp:217) | 1 | dependencies-and-boundaries.sexp | EXISTING R-129 | EXISTING Q08 | G02 G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-07, WP-08, WP-09, WP-11 | NO-MODEL-CONSUMER; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED |
| 4 | `V1.7-SCHEMAS__define-capability-seat` (V1.7-SCHEMAS.sexp:346) | 7 | NEW:capabilities — reason: no existing module holds a capability→seat binding | NEW | EXISTING RA-Q-RESOLVE | G02 G03 G09a G10-12 G13 G14 G15 G19 G21 | FUTURE_BOOK_REVISION, WP-01, WP-08, WP-09, WP-11, WP-12, WP-13 | NO-REQUIREMENT-FACT; ID-SYNTHESIS-REQUIRED; NEW-FACT-TYPE-REQUIRED; L6-REQ-OUTSIDE-MODEL(RA-E,RA-I,RA-J,RA-K) |
| 5 | `V1.7-SCHEMAS__define-construction-order` (V1.7-SCHEMAS.sexp:80) | 1 | Same as the V1.6 row: dependencies-and-boundaries.sexp | NEW | NEW | G02 G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-07, WP-08, WP-09 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED; L6-TEST-OUTSIDE-MODEL(RA-Q-COGDAG,T8-COGLIFE) |
| 6 | `V1.7-SCHEMAS__define-pipeline` (V1.7-SCHEMAS.sexp:308) | 1 | dependencies-and-boundaries.sexp | EXISTING R-V6-SAFE | EXISTING V6Q-01 | G02 G03 G04 G10-12 G19 G21 | WP-07+WP-08 | L1-NESTED-VALUE(1/1 forms) |
| 7 | `V1.7-SCHEMAS__define-ra-closure-roots` (V1.7-SCHEMAS.sexp:290) | 1 | dependencies-and-boundaries.sexp | EXISTING R-111 | EXISTING Q20 | G02 G03 G04 G09a G10-12 G13 G15 G19 G21 | WP-12 | ID-SYNTHESIS-REQUIRED; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED |
| 8 | `V1.7-SCHEMAS__define-write-authority` (V1.7-SCHEMAS.sexp:327) | 10 | stores-and-authorities.sexp | NEW | NONE_OR_UNKNOWN | G02 G03 G10-12 G14 G19 G21 | DEFERRED, FUTURE_BOOK_REVISION, WP-01, WP-06, WP-08, WP-12, WP-13 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; L6-TEST-OUTSIDE-MODEL(RA-Q-OWN,T8-OWN) |
| 9 | `V1.8-SCHEMAS__define-canonical-identity` (V1.8-SCHEMAS.sexp:425) | 8 | interfaces-and-types.sexp | NEW | NEW | G10-12 G14 G19 G21 | FUTURE_BOOK_REVISION, WP-06, WP-08, WP-11, WP-12 | NO-REQUIREMENT-FACT; NO-TEST-FACT; L6-TEST-OUTSIDE-MODEL(T8-XREF) |
| 10 | `V1.8-SCHEMAS__define-capability-seat` (V1.8-SCHEMAS.sexp:243) | 7 | NEW:capabilities | NEW | EXISTING RA-Q-RESOLVE | G02 G03 G09a G10-12 G13 G14 G15 G19 G21 | FUTURE_BOOK_REVISION, WP-01, WP-08, WP-09, WP-11, WP-12, WP-13 | NO-REQUIREMENT-FACT; ID-SYNTHESIS-REQUIRED; NEW-FACT-TYPE-REQUIRED; L6-REQ-OUTSIDE-MODEL(RA-E,RA-I,RA-J,RA-K) |
| 11 | `V1.8-SCHEMAS__define-ra-closure-roots` (V1.8-SCHEMAS.sexp:259) | 1 | dependencies-and-boundaries.sexp | EXISTING R-111 | EXISTING Q20 | G02 G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-12 | ID-SYNTHESIS-REQUIRED; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED |
| 12 | `V1.8-SCHEMAS__define-ra-delta-seats` (V1.8-SCHEMAS.sexp:444) | 1 | requirements-tests-workpackets.sexp | NEW | NEW | G02 G03 G04 G10-12 G14 G19 G21 | DEFERRED, FUTURE_BOOK_REVISION, WP-06, WP-12, WP-13 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; L1-NESTED-VALUE(1/1 forms); L6-REQ-OUTSIDE-MODEL(RA8-CONT,RA8-CORR,RA8-EPOCH,RA8-JURNS); L6-TEST-OUTSIDE-MODEL(T8-EPOCH) |

##### DDI-2 — 18 classes

| # | DDI class (`file__head`) | forms | proposed canonical module | requirement | test | Option-A gate (CANDIDATE) | future packet | gaps |
|---|---|---|---|---|---|---|---|---|
| 1 | `V1.5-SCHEMAS__define-cardinality-matrix` (V1.5-SCHEMAS.sexp:45) | 1 | interfaces-and-types.sexp | EXISTING R-25 | EXISTING Q22 | G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-07 | L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED |
| 2 | `V1.5-SCHEMAS__define-closed-enum` (V1.5-SCHEMAS.sexp:13) | 16 | interfaces-and-types.sexp | EXISTING R-129 R-130 R-132 R-25 | NONE_OR_UNKNOWN | G02 G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-01, WP-06, WP-07, WP-08, WP-09 | NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(16/16 forms); NEW-FACT-TYPE-REQUIRED; L6-TEST-OUTSIDE-MODEL(V5Q-D1-08,V5Q-D2-08,V5Q-D3-07) |
| 3 | `V1.5-SCHEMAS__define-frozen-enum-reference` (V1.5-SCHEMAS.sexp:182) | 1 | interfaces-and-types.sexp | EXISTING R-132 | EXISTING Q01 Q29 | G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-01 | NO-MODEL-CONSUMER; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED |
| 4 | `V1.5-SCHEMAS__define-record` (V1.5-SCHEMAS.sexp:33) | 18 | interfaces-and-types.sexp | EXISTING R-129 R-130 R-132 R-25 | EXISTING Q01 Q08 Q22 Q28 | G02 G03 G04 G10-12 G14 G19 G21 | WP-01, WP-03, WP-06, WP-07, WP-08, WP-09 | L1-NESTED-VALUE(18/18 forms) |
| 5 | `V1.5-SCHEMAS__define-ref-classification` (V1.5-SCHEMAS.sexp:569) | 1 | interfaces-and-types.sexp | EXISTING R-129 | EXISTING Q08 | G02 G03 G04 G10-12 G14 G19 G21 | WP-08 | ID-SYNTHESIS-REQUIRED; L1-NESTED-VALUE(1/1 forms) |
| 6 | `V1.6-SCHEMAS__define-adapter-contract` (V1.6-SCHEMAS.sexp:67) | 2 | interfaces-and-types.sexp | EXISTING R-25 R-V6-ADP | EXISTING V6Q-17 | G05 G09a G10-12 G13 G15 G19 G21 | WP-07, WP-07+WP-11+WP-14 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):adapters.sexp |
| 7 | `V1.6-SCHEMAS__define-closed-enum` (V1.6-SCHEMAS.sexp:20) | 8 | UNDECIDED — interfaces-and-types.sexp | PARTIAL R-V6-MEM R-V6-SAFE | EXISTING V6Q-01 V6Q-02 | G02 G03 G04 G05 G09a G10-12 G13 G15 G19 G21 | FUTURE_BOOK_REVISION, WP-07, WP-07+WP-08, WP-08 | NO-MODEL-CONSUMER; L1-NESTED-VALUE(8/8 forms); NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):enums.sexp |
| 8 | `V1.6-SCHEMAS__define-mapping` (V1.6-SCHEMAS.sexp:231) | 1 | SAME module as the DDI-1 capability-seat class | NONE_OR_UNKNOWN | NEW | G03 G04 G05 G10-12 G19 G21 | WP-07, WP-08, WP-09, WP-11 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(1/1 forms); NEW-MODULE-PROPOSED(L7):capability-seats.sexp |
| 9 | `V1.6-SCHEMAS__define-record` (V1.6-SCHEMAS.sexp:85) | 22 | SPLIT, and the split is the decision: type IDENTITY already lives in interfaces-and-types.sexp | PARTIAL R-129 R-V6-ADP R-V6-MEM | EXISTING Q08 V6Q-01 V6Q-02 V6Q-09 V6Q-13 V6Q-17 | G02 G03 G04 G05 G10-12 G19 G21 | DEFERRED, FUTURE_BOOK_REVISION, WP-02, WP-07, WP-07+WP-08, WP-07+WP-11+WP-14, WP-08, WP-12 | L1-NESTED-VALUE(22/22 forms); NEW-MODULE-PROPOSED(L7):record-fields.sexp |
| 10 | `V1.6-SCHEMAS__define-ref-classification-v6` (V1.6-SCHEMAS.sexp:344) | 1 | dependencies-and-boundaries.sexp | NONE_OR_UNKNOWN | NONE_OR_UNKNOWN | G02 G03 G04 G10-12 G19 G21 | WP-12 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; L1-NESTED-VALUE(1/1 forms) |
| 11 | `V1.6-SCHEMAS__define-reference` (V1.6-SCHEMAS.sexp:92) | 6 | interfaces-and-types.sexp | PARTIAL R-111 R-118 R-129 R-130 R-25 | NEW | G02 G10-12 G19 G21 | WP-06, WP-07, WP-08, WP-12 | NO-TEST-FACT |
| 12 | `V1.7-SCHEMAS__define-closed-enum` (V1.7-SCHEMAS.sexp:40) | 8 | UNDECIDED, and it MUST be the same module as the V1.5/V1.6/V1.8 enums — the V1.7 dossier proposes a NEW module 'enums' while the V1.5/V1.6 dossiers pr | NONE_OR_UNKNOWN | EXISTING RA-Q-RESOLVE | G02 G03 G04 G10-12 G14 G19 G21 | FUTURE_BOOK_REVISION, WP-08, WP-11, WP-12 | NO-REQUIREMENT-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(8/8 forms); L6-REQ-OUTSIDE-MODEL(RA-I,RA-K,RA-L,RA-Q) |
| 13 | `V1.7-SCHEMAS__define-record` (V1.7-SCHEMAS.sexp:45) | 25 | SPLIT as for every record class: identity is already in interfaces-and-types.sexp for 14 of the 25 | PARTIAL R-102 R-124 R-129 R-132 R-51 R-V6-RESOLVE R-V6-TENANT | EXISTING Q06 Q08 Q16 Q27 Q29 Q42 RA-Q-RESOLVE RA-Q-TENANT | G02 G03 G04 G10-12 G14 G19 G21 | DEFERRED, FUTURE_BOOK_REVISION, WP-01, WP-08, WP-09, WP-11, WP-12, WP-13 | L1-NESTED-VALUE(25/25 forms); L6-REQ-OUTSIDE-MODEL(RA-E,RA-I,RA-J,RA-K) |
| 14 | `V1.7-SCHEMAS__define-reference` (V1.7-SCHEMAS.sexp:34) | 8 | The SAME module and the SAME family as V1.6 define-reference, V1.8 define-reference and the DDI-1 V1.8 define-canonical-identity | PARTIAL R-129 R-132 R-16 | NEW | G02 G10-12 G19 G21 | WP-01, WP-02, WP-08 | NO-TEST-FACT |
| 15 | `V1.8-SCHEMAS__define-cardinality-table` (V1.8-SCHEMAS.sexp:394) | 1 | The SAME module as the `field` family | EXISTING R-129 | NEW | G03 G04 G09a G10-12 G13 G14 G15 G19 G21 | WP-08 | NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED |
| 16 | `V1.8-SCHEMAS__define-closed-enum` (V1.8-SCHEMAS.sexp:28) | 9 | UNDECIDED and shared: the same single module as the other three DDI-2 enum classes | NONE_OR_UNKNOWN | NONE_OR_UNKNOWN | G02 G03 G04 G10-12 G14 G19 G21 | FUTURE_BOOK_REVISION, WP-06, WP-08, WP-11, WP-13 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(9/9 forms); L6-REQ-OUTSIDE-MODEL(RA8-EPOCH) |
| 17 | `V1.8-SCHEMAS__define-record` (V1.8-SCHEMAS.sexp:32) | 19 | SPLIT: identity is ALREADY complete in interfaces-and-types.sexp — all 19 are `type` facts | PARTIAL R-102 R-111 R-124 R-129 R-130 R-134 R-V6-RESOLVE R-V6-TENANT | EXISTING Q08 Q20 Q27 Q28 Q42 RA-Q-RESOLVE RA-Q-TENANT | G02 G03 G04 G10-12 G14 G19 G21 | DEFERRED, FUTURE_BOOK_REVISION, WP-06, WP-08, WP-11, WP-12, WP-13 | L1-NESTED-VALUE(19/19 forms); L6-REQ-OUTSIDE-MODEL(RA-Q,RA8-CONT,RA8-CORR,RA8-EPOCH) |
| 18 | `V1.8-SCHEMAS__define-reference` (V1.8-SCHEMAS.sexp:107) | 9 | The module and family chosen in DDI-1 for V1.8 define-canonical-identity | PARTIAL R-102 R-111 R-129 R-130 R-V6-MEM R-V6-RESOLVE | NEW | G02 G10-12 G14 G19 G21 | FUTURE_BOOK_REVISION, WP-01, WP-06, WP-08, WP-11, WP-12 | NO-TEST-FACT; L6-REQ-OUTSIDE-MODEL(RA-Q) |

##### DDI-3 — 10 classes

| # | DDI class (`file__head`) | forms | proposed canonical module | requirement | test | Option-A gate (CANDIDATE) | future packet | gaps |
|---|---|---|---|---|---|---|---|---|
| 1 | `V1.5-SCHEMAS__define-algorithm` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.5-SCHEMAS.sexp:None) | 1 | NEW:decision-functions.sexp | EXISTING R-130 R-134 | EXISTING Q28 | G05 G09a G10-12 G13 G14 G15 G19 G21 | WP-06 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):decision-functions.sexp |
| 2 | `V1.5-SCHEMAS__define-decision-function` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.5-SCHEMAS.sexp:None) | 1 | NEW:decision-functions.sexp — no existing module can hold it without a second concept per module: dependencies-and-boundaries.sexp is the pipeline/con | EXISTING R-132 | EXISTING Q01 | G02 G05 G09a G10-12 G13 G14 G15 G19 G21 | WP-01 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):decision-functions.sexp |
| 3 | `V1.5-SCHEMAS__define-projection` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.5-SCHEMAS.sexp:None) | 3 | NEW:decision-functions.sexp | EXISTING R-129 | EXISTING Q08 | G05 G09a G10-12 G13 G14 G15 G19 G21 | WP-08 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):decision-functions.sexp |
| 4 | `V1.5-SCHEMAS__define-quorum-predicate` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.5-SCHEMAS.sexp:None) | 1 | NEW:decision-functions.sexp — same reason as the decision family | EXISTING R-130 | EXISTING Q28 | G05 G09a G10-12 G13 G14 G15 G19 G21 | WP-06 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):decision-functions.sexp |
| 5 | `V1.7-SCHEMAS__define-decision-function` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-SCHEMAS.sexp:None) | 1 | NEW:decision-functions.sexp — same module as the V1.5 decision | EXISTING R-132 | EXISTING Q01 | G02 G05 G10-12 G14 G19 G21 | WP-01 | NO-MODEL-CONSUMER; NEW-MODULE-PROPOSED(L7):decision-functions.sexp |
| 6 | `V1.7-SCHEMAS__define-source-type-coverage` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.7-SCHEMAS.sexp:None) | 1 | subsystems.sexp / seats.sexp already hold the seat and subsystem | EXISTING R-132 | EXISTING Q29 | G02 G03 G05 G09a G10-12 G13 G15 G19 G21 | WP-01 | ID-SYNTHESIS-REQUIRED; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):source-type-coverage.sexp |
| 7 | `V1.8-SCHEMAS__define-cognition-graph` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp:None) | 1 | NEW:cognition-graph.sexp — dependencies-and-boundaries.sexp cannot hold it without a second concept: its `stage` universe is the 8-node symbolic-only- | EXISTING R-129 | EXISTING Q08 | G05 G09a G10-12 G13 G14 G15 G19 G21 | WP-02, WP-08 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):cognition-graph.sexp |
| 8 | `V1.8-SCHEMAS__define-cognition-node-types` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp:None) | 1 | NEW:cognition-graph.sexp — together with row 7 | EXISTING R-129 | EXISTING Q08 | G05 G09a G10-12 G13 G14 G15 G19 G21 | WP-02, WP-08 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):cognition-graph.sexp |
| 9 | `V1.8-SCHEMAS__define-dimension-policy` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp:None) | 1 | NEW:decision-functions.sexp | EXISTING R-102 | EXISTING Q27 | G05 G09a G10-12 G13 G14 G15 G19 G21 | FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED, WP-11 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):decision-functions.sexp; WP-SOURCES-DISAGREE(owner=WP-11 vs wp-reconciliation ROOT_AUTHORITY_FLYWHEEL=FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED) |
| 10 | `V1.8-SCHEMAS__define-reliance-aggregation` (deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.8-SCHEMAS.sexp:None) | 1 | NEW:decision-functions.sexp — next to its parameter table | EXISTING R-102 | EXISTING Q27 | G05 G09a G10-12 G13 G14 G15 G19 G21 | FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED, WP-11 | NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):decision-functions.sexp; WP-SOURCES-DISAGREE(owner=WP-11 vs wp-reconciliation ROOT_AUTHORITY_FLYWHEEL=FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED) |

##### DDI-4 — 16 classes

| # | DDI class (`file__head`) | forms | proposed canonical module | requirement | test | Option-A gate (CANDIDATE) | future packet | gaps |
|---|---|---|---|---|---|---|---|---|
| 1 | `INTERFACE-AND-SCHEMA-REGISTRY__define-invariant` (INTERFACE-AND-SCHEMA-REGISTRY.sexp:177) | 1 | NEW:invariants.sexp — one-seat reason: the 92 define-invariant forms of the six registries | NONE_OR_UNKNOWN | NEW | G02 G03 G05 G09a G13 G14 G15 G16 G19 G20 G21 | FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):invariants.sexp; L6-TEST-OUTSIDE-MODEL(QT-DDI4-ISR-CLOSURE); NO-FUTURE-PACKET |
| 2 | `SUBSYSTEM-REGISTRY__define-file-disposition` (SUBSYSTEM-REGISTRY.sexp:130) | 1 | NEW:file-dispositions.sexp — one-seat reason: the only existing module that speaks about files is files-and-roles.sexp, and it is a GENERATED artefact | NONE_OR_UNKNOWN | NEW | G05 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | DEFERRED, WP-08 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):file-dispositions.sexp; L6-TEST-OUTSIDE-MODEL(QT-DDI4-SPLIT-NO-COPY) |
| 3 | `SUBSYSTEM-REGISTRY__define-invariant` (SUBSYSTEM-REGISTRY.sexp:136) | 2 | NEW:invariants.sexp for the TEXT | NONE_OR_UNKNOWN | NEW | G02 G03 G05 G14 G16 G19 G20 G21 | FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; NEW-MODULE-PROPOSED(L7):invariants.sexp; L6-TEST-OUTSIDE-MODEL(QT-DDI4-RATIONALE-RESOLVES); NO-FUTURE-PACKET |
| 4 | `SUBSYSTEM-REGISTRY__define-wp-purpose` (SUBSYSTEM-REGISTRY.sexp:15) | 16 | requirements-tests-workpackets.sexp | UNKNOWN | NEW | G14 G16 G19 G20 G21 | FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED | NO-REQUIREMENT-FACT; NO-TEST-FACT; L6-REQ-OUTSIDE-MODEL(R-universe); L6-TEST-OUTSIDE-MODEL(QT-DDI4-WP-OWNS); NO-FUTURE-PACKET |
| 5 | `V1.5-SCHEMAS__define-constitution-reference` (V1.5-SCHEMAS.sexp:630) | 1 | rationale-references.sexp | NEW | NEW | G05 G10-12 G14 G16 G19 G20 G21 | WP-08 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; NEW-MODULE-PROPOSED(L7):invariants.sexp; L6-TEST-OUTSIDE-MODEL(QT-DDI4-CONSTITUTION-BINDING-NO-GROWTH,QT-DDI4-RATIONALE-RESOLVES) |
| 6 | `V1.5-SCHEMAS__define-gate` (V1.5-SCHEMAS.sexp:123) | 1 | NEW:invariants.sexp | NEW | NEW | G03 G04 G05 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | WP-06, WP-07, WP-12 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):invariants.sexp; L6-TEST-OUTSIDE-MODEL(QT-DDI4-GATE-NO-ASSUMPTION-PATH) |
| 7 | `V1.5-SCHEMAS__define-invariant` (V1.5-SCHEMAS.sexp:70) | 22 | NEW:invariants.sexp — same seat as classes 1/4/9/12/14 | NEW | NEW | G02 G03 G05 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | WP-01, WP-06, WP-07, WP-08 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):invariants.sexp; L6-REQ-OUTSIDE-MODEL(R-space); L6-TEST-OUTSIDE-MODEL(QT-DDI4-INV-V15-COUNT,QT-DDI4-INV-VOCAB) |
| 8 | `V1.5-SCHEMAS__define-rule` (V1.5-SCHEMAS.sexp:87) | 7 | NEW:invariants.sexp | NEW | NEW | G02 G03 G04 G05 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | WP-03, WP-06, WP-07, WP-08 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(7/7 forms); NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):invariants.sexp,rules.sexp; L6-TEST-OUTSIDE-MODEL(QT-DDI4-RULE-CLAUSE-CLOSURE) |
| 9 | `V1.6-SCHEMAS__define-invariant` (V1.6-SCHEMAS.sexp:15) | 21 | NEW:invariants.sexp — shared seat with classes 1/4/5/12/14 | NEW | NEW | G02 G03 G05 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | DEFERRED, FUTURE_BOOK_REVISION, WP-07, WP-07+WP-08, WP-07+WP-11+WP-14, WP-08, WP-12 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):invariants.sexp; L6-REQ-OUTSIDE-MODEL(R-V6-); L6-TEST-OUTSIDE-MODEL(QT-DDI4-INV-CONTRADICTION,QT-DDI4-INV-V16-COUNT) |
| 10 | `V1.6-SCHEMAS__define-protocol` (V1.6-SCHEMAS.sexp:57) | 1 | interfaces-and-types.sexp | EXISTING R-25 R-V6-ADP | NEW | G03 G04 G10-12 G14 G16 G19 G20 G21 | WP-07 | NO-TEST-FACT; L1-NESTED-VALUE(1/1 forms); L6-TEST-OUTSIDE-MODEL(QT-DDI4-PROTOCOL-NO-WRITE) |
| 11 | `V1.6-SCHEMAS__define-rule` (V1.6-SCHEMAS.sexp:247) | 2 | For casegrammar-split: whichever module class 3 resolves to | NONE_OR_UNKNOWN | NEW | G02 G03 G04 G05 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | DEFERRED, WP-07, WP-07+WP-11+WP-14, WP-08 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(2/2 forms); NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):file-dispositions.sexp; L6-TEST-OUTSIDE-MODEL(QT-DDI4-MECHANISM-ADMISSION,QT-DDI4-RULE-NO-DUPLICATE-CONCEPT) |
| 12 | `V1.7-SCHEMAS__define-invariant` (V1.7-SCHEMAS.sexp:14) | 23 | NEW:invariants.sexp — shared seat with classes 1/4/5/9/14. rationale-references.sexp is the pointer alternative and would carry :doc "V1.7-SCHEMAS.sex | NONE_OR_UNKNOWN | NEW | G02 G03 G05 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | DEFERRED, FUTURE_BOOK_REVISION, WP-07+WP-08, WP-08, WP-11, WP-13 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):invariants.sexp; L6-REQ-OUTSIDE-MODEL(RA-E,RA-I,RA-J,RA-K); L6-TEST-OUTSIDE-MODEL(QT-DDI4-INV-SUCCESSION) |
| 13 | `V1.7-SCHEMAS__define-wp-reconciliation` (V1.7-SCHEMAS.sexp:379) | 1 | requirements-tests-workpackets.sexp | NONE_OR_UNKNOWN | NEW | G02 G03 G04 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | DEFERRED, WP-02 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED; L6-TEST-OUTSIDE-MODEL(QT-DDI4-WP-EVIDENCE-RESOLVES) |
| 14 | `V1.8-SCHEMAS__define-fixtures` (V1.8-SCHEMAS.sexp:398) | 1 | verification-corpus.sexp | NEW | NEW | G03 G04 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | WP-08 | NO-REQUIREMENT-FACT; NO-TEST-FACT; NO-MODEL-CONSUMER; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED; L6-TEST-OUTSIDE-MODEL(QT-DDI4-CLARIFY-FIXTURES-EXECUTED) |
| 15 | `V1.8-SCHEMAS__define-invariant` (V1.8-SCHEMAS.sexp:14) | 23 | NEW:invariants.sexp — shared seat with classes 1/4/5/9/12. rationale-references.sexp is the pointer alternative | NONE_OR_UNKNOWN | NEW | G02 G03 G05 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | DEFERRED, FUTURE_BOOK_REVISION, WP-06, WP-08, WP-11, WP-12, WP-13 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; NEW-FACT-TYPE-REQUIRED; NEW-MODULE-PROPOSED(L7):invariants.sexp; L6-REQ-OUTSIDE-MODEL(RA8-CONT,RA8-CORR,RA8-EPOCH,RA8-FROST); L6-TEST-OUTSIDE-MODEL(QT-DDI4-INV-NO-INTERNAL-CONTRADICTION) |
| 16 | `V1.8-SCHEMAS__define-wp-reconciliation` (V1.8-SCHEMAS.sexp:303) | 1 | requirements-tests-workpackets.sexp | NONE_OR_UNKNOWN | NEW | G02 G03 G04 G09a G10-12 G13 G14 G15 G16 G19 G20 G21 | DEFERRED, WP-02 | NO-REQUIREMENT-FACT; NO-TEST-FACT; ID-SYNTHESIS-REQUIRED; L1-NESTED-VALUE(1/1 forms); NEW-FACT-TYPE-REQUIRED; L6-TEST-OUTSIDE-MODEL(QT-DDI4-WP-EVIDENCE-DISCRIMINATES,QT-DDI4-WP-EVIDENCE-RESOLVES) |

### 3. The gate-assignment rules (stated once, applied mechanically, auditable)

Every gate cell above is produced by these rules only. `batches` quoted from
`WORK/agents/gates-matrix/survival.json` field `ddi_dependency`.

| rule | gate | condition | why (evidence) |
|---|---|---|---|
| R1 | **G19**, **G21** | every one of the 56 | `build_deferred.py` writes one ledger row per class and `led-01` verifies the multiset; survival.json G19/G21 `batches = [DDI-1..4]`; at DDI-4 completion G19's meaning inverts (`deferred = 0`) and G20's second conjunct becomes false by design |
| R2 | **G04** | class has ≥1 nested-list form (M2) | L1 admits only string · integer · plain symbol (`MODEL-SCHEMA.sexp:5-6`); the kernel cannot even read the form until it is flattened or L1 grows |
| R3 | **G02** | id must be synthesised (M3 `NOT-NAME-TESTABLE`) **or** the head is defined in more than one registry | L2 = one id, owned by one fact type (`MODEL-SCHEMA.sexp:106-107`); a synthesised id and a second version of the same head are the two ways to collide |
| R4 | **G03** | same trigger as R2 or R3 | a flattening or an id synthesis is a *migration normalization*, and `doc-01` requires every normalization to appear in `MODEL-MIGRATION-CONFLICT-LEDGER.md` with a **closed** row kind (`gate_checks.py:873-902`) |
| R5 | **G05** | the proposed module is not in `ROOT.sexp` `:composition` (M4) | L7 is an exact module/hash universe; `ROOT.sexp:12` `:module-count 14` |
| R6 | **G13**, **G15**, **G09a** | the matrix proposes a NEW fact type | both verification paths must implement the new type independently, and the Lisp path is at 400/400 of its budget (`ARCHITECTURE-MODEL-GATE.sh:178-179`) |
| R7 | **G14** | the class names a requirement/test id that is not a model fact | L6 closure is `requirement → seat → test → wp` over declared ids only (`MODEL-SCHEMA.sexp:178-182`); survival.json G14 `batches = [DDI-1]` under-states this — 46 of 56 classes trip it |
| R8 | **G10-12** | the class has an owner subsystem or cites a model requirement/test | the property families carry **exact** cardinalities (`verification-corpus.sexp:42-56`: L6 26, L5 6, L2 10, L3 33, L4 8) and the universe floors are minima (`:60-70`); any added subsystem/type/seat/store re-authors `cor-01`/`fix-01` |
| R9 | **G16**, **G20** | batch = DDI-4 | survival.json G16/G20 `batches = [DDI-4]`; GLOBAL promotion is `FORBIDDEN_UNTIL_DDI_COMPLETE` (`gate_checks.py:1096-1104`) |

Resulting load per gate (out of 56 classes): **G19 56 · G21 56 · G10-12 53 · G14 46 · G03 39 · G02 36 ·
G09a/G13/G15 35 each · G04 29 · G05 25 · G16 16 · G20 16.**
Seven gates are touched by **no** DDI class at all: **G01, G06, G07, G08, G09b, G17, G18** — their properties
(inventory totality, generation determinism, no-drift, tamper detection, kernel lexical discipline,
single-operator assurance, legacy non-authority) are independent of what the model contains.

### 4. Orphan DDI classes — 42 of 56

An **orphan** is a class with no requirement fact, **or** no consumer in the canonical model, **or** no future
packet. Counted as stated in the task (union, not intersection).

| orphan kind | count | meaning |
|---|---|---|
| `NO-REQUIREMENT-FACT` | 27 | the matrix's own verdict is `NEW` / `UNKNOWN` / `NONE` and no model `requirement` fact covers it |
| `NO-MODEL-CONSUMER` | 26 | **M3, recomputed**: not one of the class's form names occurs anywhere in the 13 non-ledger hash-pinned modules — the class's only trace in the model is its own ledger row |
| `NO-FUTURE-PACKET` | 3 | `INTERFACE-AND-SCHEMA-REGISTRY__define-invariant`, `SUBSYSTEM-REGISTRY__define-invariant`, `SUBSYSTEM-REGISTRY__define-wp-purpose` — no owner subsystem and no `define-wp-reconciliation` concept names them |
| **union** | **42** | 14 of 56 classes are free of all three |

The three hardest orphans are the same three classes: the two registry-level `define-invariant` classes are
*constitutional* statements owned by no subsystem, and `define-wp-purpose` is the packet universe itself — it
cannot be owned by a packet without circularity. This is a seat question, not an omission (§8, RP-05).

Additional structural orphanhood, not counted above but recorded:
* `NO-TEST-FACT` **30 of 56** — the largest single gap in the map.
* `ID-SYNTHESIS-REQUIRED` **17 of 56** — 7 anonymous singletons whose second element is a nested list
  (`V1.5:569`, `V1.6:344`, `V1.7:290`, `V1.7:379`, `V1.8:259`, `V1.8:303`, `V1.8:444` — orchestrator N11),
  4 plist-headed classes with no name at all (`define-capability-seat` ×2, V1.7 `define-write-authority`,
  V1.7 `define-source-type-coverage`), and 6 keyword-named `define-invariant` classes (92 forms; N12).
* `NEW-FACT-TYPE-REQUIRED` **35 of 56** — the existing 34 fact types cover fewer than half of the corpus.

**The 14 classes that are not orphans** (a requirement fact, a model consumer *and* a packet):
`V1.5__define-cardinality-matrix` · `V1.5__define-record` · `V1.5__define-ref-classification` ·
`V1.6__define-protocol` · `V1.6__define-record` · `V1.6__define-reference` · `V1.7__define-pipeline` ·
`V1.7__define-ra-closure-roots` · `V1.7__define-record` · `V1.7__define-reference` ·
`V1.7__define-source-type-coverage` · `V1.8__define-ra-closure-roots` · `V1.8__define-record` ·
`V1.8__define-reference`. Eleven of the fourteen are the record/reference families — the classes whose ids the
model already carries as `type` facts. Everything the model does **not** already name is an orphan.

**A packet token that is not a packet.** Two `:future-wp` values are compound: `S20 → WP-07+WP-11+WP-14`
(`SUBSYSTEM-REGISTRY.sexp:102`) and `S21 → WP-07+WP-08` (`:106`). The model already resolves them by
*multiplying rows* (`req-map S20__WP-07`, `S20__WP-11`, `S20__WP-14`; `S21__WP-07`, `S21__WP-08` —
`requirements-tests-workpackets.sexp:86-90`), so one requirement is closed by three packets. A fourth token,
`DEFERRED`, is a **disposition**, and it is a `wp` fact (`:52`). Both are precedents that RP-05 must settle.

### 5. Requirements without tests · tests without a falsifiable failure

#### 5.1 Three requirement universes, and they do not agree

| universe | size | source | test binding |
|---|---|---|---|
| model `requirement` facts | **24** | `requirements-tests-workpackets.sexp:5-28` | **all 24** appear in a `req-map` row with a `test` (`:67-95`) — L6 closure is complete *inside the model* |
| registry `:requirement` values | **38** | six registries | 24 as above + **14 RA-\*/RA8-\*** ids (`RA-E RA-I RA-J RA-K RA-L RA-R RA-T` at `V1.8:243-249`; `RA8-CONT/CORR/EPOCH/JURNS/K/MARK/SIDE` at `V1.8:445-451`) that are **not model facts** and whose paired tests are also not model facts |
| `TRACEABILITY-MATRIX.md` | **134** distinct `R-nnn` | the requirement register of record | **6 rows carry no test token at all**: `TM:133` R-70, `TM:205` R-112, `TM:206` R-113, `TM:209` R-116, `TM:210` R-117, `TM:211` R-118 |

**`reqs_without_tests` is reported as 6** (the requirement ids with no test anywhere). Two further layers are
recorded rather than folded into that number: 14 requirement ids whose requirement→test pair exists but is
invisible to L6, and one live contradiction —

> **ADJ-RM-01.** `TRACEABILITY-MATRIX.md:211` states for **R-118**: *"— (δεν εκτελείται)"* (no test, not
> executed). The model asserts `(fact req-map S12__WP-12 :requirement R-118 :seat SEAT-APPROVAL-POLICY
> :subsystem S12 :test Q19 :wp WP-12)` (`requirements-tests-workpackets.sexp:78`). Either the register or the
> model is wrong about whether R-118 has a test. Both sides cited; not decided here.

#### 5.2 Tests without a falsifiable failure — 15

`test` is declared `:required () :optional () :types ()` (`MODEL-SCHEMA.sexp:173`) — **a model `test` fact
structurally cannot carry a failure condition**, and `falsifier` (`:246-256`) has no `:ref` to `test`. So no
test in this model is bound to its own falsifier; the failure condition, where it exists, lives in prose.

| test id | model fact? | failure condition found | evidence |
|---|---|---|---|
| `Q01 Q06 Q08 Q16 Q19 Q20 Q22 Q27 Q28 Q29 Q40 Q41 Q42 Q43` | yes (14) | **yes** — each `### Qnn` section carries an *Αρνητικός μάρτυρας* (negative witness) | `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:84,148,173,281,315,326,358,442,456,468,618,633,657,697` |
| `V6Q-01 V6Q-02 V6Q-09 V6Q-13 V6Q-17` | yes (5) | **yes** — declared 1-1 with kill-witnesses `V6KW-01..18` | `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:1150-1151` |
| **`RA-Q-RESOLVE`**, **`RA-Q-TENANT`** | **yes (2)** | **NO — nothing, anywhere** | `git grep` over the whole clone returns only registrations: `TRACEABILITY-MATRIX.md:350,355`, `SUBSYSTEM-REGISTRY.sexp:121,126`, `V1.7:346`, `V1.8:243`, the model fact, and the generated view. 0 hits in `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md` |
| `RA-Q-CITE DATASET JURIS LICENSE RETRIEVE TRANSLATE` | no (6) | **no per-test statement** — only the class-level audit mutation `:V8I-CAP-real` "bogus-symbol mutation" (`V1.8:250-254`) | `TRACEABILITY-MATRIX.md:349-355`, `V1.8:243-249` |
| `T8-CONT CORR EPOCH JURNS K MARK SIDE` | no (7) | **no per-test statement** — only the class-level `:V8I-RA-DELTA-seats` "zero or multiple seats ⇒ failure" (`V1.8:455-458`) and one shared mutation `drop-to-six` in a NON_AUTHORITATIVE file (`V1.8-VERIFY.py:1703`) | `TRACEABILITY-MATRIX.md:391-397` |

`tests_without_falsifier = 15`. The sharp two are `RA-Q-RESOLVE` and `RA-Q-TENANT`: they are **inside the
model's own L6 chain** (`req-map` :94, :95) and therefore already count as "requirement → seat → test → WP
closed" while naming a test that no document defines.

### 6. Option-A gates without source facts · source facts without any future gate

#### 6.1 Six candidate Option-A gates whose acceptance criterion has NO fact seat — `gates_without_facts = 6`

"Without source facts" here means: the thing the gate compares against is a literal, a document's prose, or a
vocabulary that exists in no `*.sexp` module — so it is outside the hash-rooted fact universe that L7 pins and
that both verification paths read.

| gate | what it compares against | where that lives | fact seat |
|---|---|---|---|
| **G03** `03-conflicts-recorded` | migration conflict rows | `MODEL-MIGRATION-CONFLICT-LEDGER.md` (Markdown), parsed by `gate_checks.py` | **none** — `grep -n conflict MODEL-SCHEMA.sexp` = 0 hits; only the *file* is a fact (`files-and-roles.sexp:326`, `:role ARCHITECTURE_DECISION`) |
| **G09a** `09a-kernel-sloc-budget` | the number **400** | `ARCHITECTURE-MODEL-GATE.sh:178-179` — `KSLOC=$(grep -vE ...)` then `[ "$KSLOC" -le 400 ]` | **none** — `400` appears in the modules only as `PATH-SPACE :max` (`MODEL-SCHEMA.sexp:40`). The model states the opposite principle for the *other* budget: "the program that counts the lines is never the program that decides how many are permitted" (`MODEL-SCHEMA.sexp:102-104`, the `tcb-budget` rationale) |
| **G09b** `09b-kernel-no-regex` | a blacklist of forbidden constructs | the a2f45f6d script; gone at HEAD | **none**, and never had one |
| **G16** `16-decision-packet` | the packet's totals and authority split | `ROOT-OPERATOR-DECISION-PACKET.md` | only the *file* is a fact (`files-and-roles.sexp:333`); the numbers inside are recomputed by `build_decision_packet.py`, not declared |
| **G17** `17-no-exhaustive-human-review` | a sentence | a Markdown document | **none** |
| **G18** `18-legacy-nonauthoritative` | the token `NON_AUTHORITATIVE_GATE` | asserted by `LEGACY-AUDIT-DISPOSITION.md:6` and `build_model.py:9` | **none** — 0 occurrences in `files-and-roles.sexp` and **the value is not in the `file-role` enum** (`MODEL-SCHEMA.sexp:52-55`). Independently re-verified here; matches orchestrator N14 |

A second, disjoint reading is recorded rather than merged: **seven gates are fed by no DDI source class at all**
(G01, G06, G07, G08, G09b, G17, G18 — §3). The intersection of the two readings is {G09b, G17, G18}: three gates
that neither rest on a fact nor gain anything from the full build. Two of them (G09b, G17) are the two the
survival matrix classes `MISSING` and the orchestrator's own table classes `DEMOTED (informational)` —

> **ADJ-RM-02.** `WORK/agents/gates-matrix/survival.json` counts `missing = 2` (G09b, G17);
> `WORK/my-gate-mapping.md` rows 10 and 16 call the same two "DEMOTED (informational)". The equation is
> 2 + 16 + 2 = 20 either way, but "missing without proof = 0" holds only under the second reading. Both cited;
> not decided here. (The gates-skeptic states the same in S-7's caveat, `findings.md:51-52`.)

#### 6.2 Eight kinds of source fact with no future gate — `facts_without_gate = 8`

| # | fact / content with no gate | evidence |
|---|---|---|
| F1 | **`rationale :doc`/`:anchor` never resolved.** `rationale-references.sexp:7` `RAT-PUBPRIV :doc "deployment/LAWMAX-THREAT-MODEL.md" :anchor "public/private one-way boundary"` — the anchor occurs **0 times** in that file (also 0 for `one-way`). L3 only checks that a `:rationale` value names a `rationale` id; no check opens the doc. It is the stated justification of the four private seats (`seats.sexp:91,93,95,97`) | re-verified here; orchestrator N17 |
| F2 | **`test` id → a real test.** No check confirms a `test` fact names a defined test (§5.2 shows two that name nothing) | `MODEL-SCHEMA.sexp:174`; `gate_checks.py` has no test resolver |
| F3 | **`requirement` id → a real requirement.** Same shape; the register (`TRACEABILITY-MATRIX.md`, 134 ids) is never opened by a counted check | `MODEL-SCHEMA.sexp:173` |
| F4 | **`wp` id → a real `WP-NN.md`.** `define-wp-reconciliation`'s own invariant demands exactly this ("V8-WP **OPENS** each named WP-NN.md and confirms the `:evidence` string occurs in it", `V1.8:320-323`) — but that audit lives in `V1.8-VERIFY.py`, classified `HISTORICAL_EVIDENCE … NON_AUTHORITATIVE` (`files-and-roles.sexp:453`) | — |
| F5 | **Fields dropped at import from the 4 IMPORTED classes.** `define-interface` keeps 2 of 20 source keys (drops `:seat :signature-owner :version :new/:reuse :future-wp :migration :rollback :status :public-dependency :kind :protocol`); `define-subsystem` drops `:name :interface :rollback :wp-note`; `define-write-authority` drops `:writers :read-only`; `define-pipeline` keeps `:from/:to` only, dropping `:entry :exit :mandatory-nodes :symbolic-only-nodes :proposer-optional-nodes :proposer-mandatory-nodes :mutation-count :mutations` | `WORK/imported-field-coverage.json`; orchestrator N15. **Consequence:** the symbolic-only guarantee `:V8I-SYM-exact` (`V1.8:336-341`) and `:V8I-02` have *no canonical seat in the model at all* — no gate can detect that `proposer-mandatory-nodes` became non-empty |
| F6 | **`type :classification` vs `subsystem :classification`.** Nothing checks that a PRIVATE type is owned by a PRIVATE subsystem; §7 shows the one live crossing | `MODEL-SCHEMA.sexp` has no such conditional |
| F7 | **7 of the 8 declared public/private edge families.** L5 as implemented walks `consumes` only (`MODEL-SCHEMA.sexp:164-170`); `V1.8:264-266` declares `field-type ref-target interface-io subsystem-dep store-owner-writer api-mcp-schema publication declassification` | — |
| F8 | **`git` as an executed tool.** `tch-01` enforces exactly the 5 `tool` facts (`TOOLCHAIN.sexp`, `UF-TOOL :minimum 5` at `verification-corpus.sexp:70`); git is executed by `build_inventory.py:83-84`, `gate_checks.py:87,113,127,138,160,189,202,220`, `acceptance_runtime.py:187,193`, `run_corpus.py:177,247-260` and is pinned by nothing | §8 AM-01 |

### 7. Private concepts leaking into the public core — `private_leaks = 8`

**Baseline (verified here, and it is clean): 0 of the 102 `consumes` edges provides one of the six PRIVATE
types** (`dependencies-and-boundaries.sexp`; per-type grep = 0 for all six). The only edge touching a private
subsystem is `S22 → DeclassificationReceipt/1` (`:110`) — private consuming public, the permitted direction.
The leaks below are therefore **not** violations of the check that exists; they are places where the check that
exists cannot see, or where an import will make the model's own numbers false.

| # | leak | status | evidence |
|---|---|---|---|
| PL-1 | **`RestrictedForensicRecord/1` is `:classification PRIVATE` and `:owner-subsystem S18`, and `S18` is `:classification PUBLIC`** — the single type/owner classification crossing among all 60 types | **LIVE at HEAD**, invisible to every counted check | `interfaces-and-types.sexp:51` vs `subsystems.sexp:22`; source: `INTERFACE-AND-SCHEMA-REGISTRY.sexp:150` `:owner S18 :status :DEFERRED_PRIVATE`, `V1.8-SCHEMAS.sexp:165` `:public-dependency nil`, listed private-forbidden at `V1.8:263` |
| PL-2 | **L5 is one edge family; the constitution declares eight.** Importing `define-ra-closure-roots` (DDI-1) declares the eight families as data but does not make the closure true | LIVE (scope) + import-time | `MODEL-SCHEMA.sexp:164-170` vs `V1.8-SCHEMAS.sexp:264-266`, `:277-283` |
| PL-3 | **`RAT-PUBPRIV`'s anchor does not exist.** The public/private boundary's stated justification points at absent text, for all four private/interface-only seats | LIVE | `rationale-references.sexp:7`; 0 hits in `deployment/LAWMAX-THREAT-MODEL.md` |
| PL-4 | **`PrivateMemoryEvent/1`** is named in both private-forbidden lists (`V1.7:296`, `V1.8:263`) but is **not a model `type`**. DDI-2 must seat it — and `PF-L5-PRIVATE-TYPE-LEAK :cardinality 6` (`verification-corpus.sexp:45-47`) is an **exact** number that becomes wrong the moment a 7th private type exists | import-time (DDI-2) | `V1.6-SCHEMAS.sexp:312` `:status :DEFERRED_PRIVATE :public-dependency nil`; owner (S19 private extension vs S22) is undetermined — orchestrator N9 |
| PL-5 | **`MemoryPolicy/1` is a public record whose `:scope_isolation` ranges over `MemoryScope`**, which includes `:client` and `:matter`; the public base is supposed to use `PublicMemoryScope` (`:public :user :ephemeral`) | import-time (DDI-2) | `V1.6-SCHEMAS.sexp:282,288,289-293`; independently confirmed by cl-freedom-hunter FH-12 |
| PL-6 | **`MemoryType` carries `:PRIVATE_CLIENT_MATTER`** while `PublicMemoryType` excludes it — importing the enum family seats a private-bearing enum next to its public twin under one enum vocabulary | import-time (DDI-2) | `V1.6-SCHEMAS.sexp:278-288` |
| PL-7 | **`legal-casegrammar.lisp` is ONE tracked file with a PUBLIC general part and a PRIVATE client-fact part (`SPLIT`)**, while a `file` fact carries exactly one `:role` from a closed enum | import-time (DDI-4) | `SUBSYSTEM-REGISTRY.sexp:130-134`; `MODEL-SCHEMA.sexp:52-55` |
| PL-8 | **Two of the eight closure families are derived from replaceable projections with no floor**: `api-mcp-schema ⇐ source/mcp-server.lisp`, `publication ⇐ source/static-site.lisp` (`V1.8:267-274`), while `source/capability-registry.lisp:142-143` calls HTTP/MCP/CLI *projections* of the one capability definition. No `universe-floor` covers any closure family (`verification-corpus.sexp:60-70` covers only fixture, property-family, falsifier, gen-artifact, seat, tool) — retire the MCP surface and the family silently empties and still passes | LIVE (design) | cl-freedom-hunter FH-06, re-checked against the cited lines |

> **ADJ-RM-03.** PL-1: is `RestrictedForensicRecord/1` correctly owned by the PUBLIC boundary subsystem S18
> (because the boundary is where declassification happens), or must a PRIVATE type be owned by a PRIVATE
> subsystem? Both readings are sourced (`ISR:150` says S18; `V1.8:263` says private-forbidden). A `define-conditional`
> that makes the crossing structurally impossible is the higher implementation if the answer is "must be PRIVATE".

### 8. Vendor / model / tool dependencies that became accidentally mandatory — `accidental_mandatory = 6`

The rule under attack is `:V8I-02-no-mandatory-model` — *"No model/ONNX/**Python**/runtime/cloud/provider is
mandatory anywhere in **the public build**"* (`V1.8-SCHEMAS.sexp:17-19`, carrying `V6I-02`).

| # | dependency | why it is (or may be) mandatory | the honest tension |
|---|---|---|---|
| **AM-01** | **`git`** | The *whole model universe* is defined by it: `build_inventory.py:83-84` (`git ls-tree` / `git ls-files`), and every check reaches the candidate through `git cat-file` / `git archive` (`gate_checks.py:127,138`, `run_corpus.py:177`). `acceptance_runtime.py:79-80` even special-cases `git` in its process runner | It is **not a `tool` fact**. `TOOLCHAIN.sexp` declares exactly 5 tools (SBCL, sha256sum, CPython, clingo, hashlib/OpenSSL) and `UF-TOOL :minimum 5` freezes that count. TOOLCHAIN's own opening argument is *"Pins that nothing reads are documentation"* (`:6`) — git is the inverse: **a tool that everything reads and nothing pins.** Not a decision for me; reported |
| **AM-02** | **CPython 3.11.15 · clingo 5.8.2 · SBCL 2.2.9.debian · coreutils 9.4 · OpenSSL 3.0.13, by SHA-256, on ONE host** | `TOOLCHAIN.sexp:28-76`; the declared supported base is *"Ubuntu 24.04 LTS x86-64 … On any other host the gate stops with a typed TOOLCHAIN-IDENTITY-MISMATCH"* (`:15-20`) | The governance path is `GOVERNANCE_MACHINERY`, not `PRODUCTION_CODE` — **whether it is part of "the public build" is exactly the question V8I-02 does not answer, and I do not answer it either.** Reported as the tension it is (orchestrator N6). Illustration, not argument: `sbcl` and `clingo` are absent from this session's container, so the kernel cannot run here at all |
| **AM-03** | **`ironclad` + `sb-ext` on the production identity path** | `source/journal.lisp:88-92` — `sha256-hex` = `ironclad:byte-array-to-hex-string(ironclad:digest-sequence :sha256 (sb-ext:string-to-octets …))`, *"η ΜΙΑ ταυτότητα περιεχομένου"*. **24 of the 133 files under `source/` reference ironclad** | `TOOLCHAIN.sexp:46` announces that the kernel *"stopped using the vendored ironclad closure"* — true for the **governance** TCB, and it says nothing about the **product**, where a specific library and a specific Lisp implementation compute the content address of every public record. `:V6I-12-no-vendor-in-core` (`V1.6:155-157`) forbids vendor identifiers only *inside canonical data*. Confirms cl-freedom-hunter FH-10 |
| **AM-04** | **`V1.8-VERIFY.py` (Python) as the only executor of two declared properties** | `RelianceProjection` total aggregation over the 65 536-cell product is executed only at `V1.8-VERIFY.py:1190-1258`; two Common-Lisp map cells name that same file as their **fallback** | The file is `:role HISTORICAL_EVIDENCE … NON_AUTHORITATIVE (frozen at 4787b342)` (`files-and-roles.sexp:453`). A fallback that names a frozen non-authoritative artifact re-mandates a Python runtime the same invariant forbids by name. Confirms FH-05 / FH-09 |
| **AM-05** | **`source/mcp-server.lisp` and `source/static-site.lisp` as derivation sources of a constitutional law** | `V1.8:267-274` binds two of the eight L5 edge families to those two files, and `:V8I-PUBPRIV-all-families` says the closure is built **ONLY** from those real sources | The same corpus calls MCP/HTTP/CLI *projections* (`source/capability-registry.lisp:142-143`) and DDI-1's own map says MCP must *"never be a mandatory node (V8I-02)"*. A declared-replaceable surface is a mandatory input to a law. See PL-8 |
| **AM-06** | **`source/greek-nlp-core.lisp` inside the sealed memory identity** | a hot-swappable, language-specific analyzer whose output sits inside content-addressed memory; its registry is a string-keyed `equal` hash with a bare `setf gethash` and no collision detection (`source/greek-nlp-core.lisp:397,400-402`), unlike `source/capability-registry.lisp:63-82` (`*capabilities*` :63, `*capability-owners*` :69-70, `capability-seat-collision` :72, raised :131) which has a `capability-seat-collision` condition | The hot-swap freedom and the identity contract collide. Confirms cl-freedom-hunter FH-04/FH-07 and cl-python-hunter PH-02 |

**Negative control (reported so the section is not one-sided).** ONNX is *not* an accidental mandatory
dependency **in the registries**: `(define-adapter-contract ONNXProposerAdapter … :mandatory nil :replaceable t
:canonical-write-authority nil)` and the same for `OCRPerceptionAdapter` (`V1.6-SCHEMAS.sexp:67-73`), and
`define-wp-purpose WP-07` itself records that the Implementation Book's toolchain freeze *"pins Python+ONNX and
MUST become optional adapter"* (`SUBSYSTEM-REGISTRY.sexp:22`). The registries are clean on this axis; the
mandatory runtimes are the governance ones (AM-02) and the product-identity ones (AM-03).

### 9. Points that would force a FOUNDATIONAL refactoring — `refactor_points = 12`

"Foundational" = it changes the schema, the id space, the module universe or the seat of a concept, so it cannot
be done *after* a batch without re-doing that batch. Ordered by how many of the 56 classes it binds.

| id | foundational point | binds | evidence |
|---|---|---|---|
| **RP-01** | **The L1 value grammar.** Permitted values are *"a quoted string, an integer, or a bare plain symbol … Nothing else — no keywords, no nested lists, no NIL"*. Recomputed here: **29 of the 56 deferred classes** (and 39 of all 66) contain at least one nested-list form; max depth 5 (`V1.5`/`V1.7 define-decision-function`). Either a flattening rule is fixed once, or the schema grows a value kind. **This decision fixes the fact vocabulary every later batch uses** | 29 | `MODEL-SCHEMA.sexp:5-6`; `nesting.json` (M2); orchestrator N4 |
| **RP-02** | **The id space.** 17 of 56 classes have no importable id: 7 anonymous singletons (second element is a nested list), 4 plist-headed classes (`:capability`/`:store`/`:registry`), 6 keyword-named `define-invariant` classes (92 forms). A synthesis convention is a *schema-level* decision because L2 says one id is owned by one fact type. Plus exactly one atom outside the TOKEN charset: `cognition->existing-lisp-seat` | 17 | `MODEL-SCHEMA.sexp:106-107`, `:16-17` (TOKEN charset); `V1.6-SCHEMAS.sexp:231`; orchestrator N11/N12; M3 |
| **RP-03** | **The single `define-model-root` / 14-module universe.** 25 classes propose **10 modules that do not exist** (`invariants.sexp` ×9, `decision-functions.sexp` ×7, `cognition-graph.sexp` ×2, `file-dispositions.sexp` ×2, + 6 singletons). L7 is an *exact* universe and `:module-count` is itself a pinned integer, so the composition, the root digest and `generation-order.sexp` all move together | 25 | `ROOT.sexp:7-12`; M4 |
| **RP-04** | **`requirement`, `test` and `wp` are bare ids: `:required () :optional () :types ()`.** A requirement carries no text, a test carries no failure condition, a WP carries no packet. L6 closure is therefore symbol-level only — §5.2 shows two tests inside the closed chain that name nothing at all. `falsifier` has no `:ref` to `test`, so a test can never be bound to its own falsifier | all 56 | `MODEL-SCHEMA.sexp:173-175`, `:246-256` |
| **RP-05** | **`wp` gets a second origin.** Today `wp` is *derived* from `define-subsystem :future-wp` (14 facts, incl. `DEFERRED` — a disposition, not a packet). DDI-4 imports `define-wp-purpose` (16 forms, the packet universe of record, adding WP-00/05/10). Two seats for one concept unless the derivation is retired in the same transaction | 1 (+ every req-map) | `requirements-tests-workpackets.sexp:52-65` vs `SUBSYSTEM-REGISTRY.sexp:15-30`; orchestrator N2 |
| **RP-06** | **Requirement ownership is a prose range.** `(define-wp-purpose WP-01 … :owns "R-01..R-13 R-132")` — a STRING. Under L1 the string imports fine and under L3 **nothing inside it is a reference**, so "which WP owns R-57" is not a machine-answerable question even after DDI-4 | 1 (+ the 134-id register) | `SUBSYSTEM-REGISTRY.sexp:16`; §5.1 |
| **RP-07** | **The migration conflict record has no fact type.** `doc-01` parses Markdown with a closed row-kind vocabulary living in Python. Every DDI flattening/rename/id-synthesis is a normalization that must be recorded — 39 of 56 classes trip rule R4 — into a structure that is not part of the hash-rooted fact universe | 39 | `grep conflict MODEL-SCHEMA.sexp` = 0; `gate_checks.py:873-902`; `files-and-roles.sexp:326` |
| **RP-08** | **L5 is structurally narrower than its own statement.** One edge family (`consumes`) implements a law the constitution defines over eight. Adding the other seven is a schema change (new fact types for field-type/ref-target/store-owner/publication/declassification edges), not a check change — and `PF-L5-PRIVATE-TYPE-LEAK :cardinality 6` is an exact number that DDI-2 falsifies | 12 (DAG §6) | `MODEL-SCHEMA.sexp:164-170` vs `V1.8:264-266`; `verification-corpus.sexp:45-47` |
| **RP-09** | **The IMPORTED four are not field-complete.** `define-interface` keeps 2 of 20 keys, `define-pipeline` keeps 2 of 10. `PROMOTION-IMPORTED` + `:authority CANONICAL_IN_MODEL` claim full representation at class level. Correcting this re-opens classes already declared done — the definition of foundational | 4 imported | `WORK/imported-field-coverage.json`; orchestrator N15 (BLK-C4) |
| **RP-10** | **The kernel's 400-line ceiling is a shell literal.** The model articulates the separation of measurement from budget for the acceptance TCB and then violates it for its own kernel: the path is at **400/400** today, so any new law needed by RP-01/RP-02/RP-08 trips G09a on arrival | all | `ARCHITECTURE-MODEL-GATE.sh:178-181`; `MODEL-SCHEMA.sexp:102-104` |
| **RP-11** | **One true co-definition cannot be ordered.** `define-cognition-graph` ↔ `define-cognition-node-types` is node-set equality (`V1.8:53-65` vs `:363-383`) — importable only as one atomic transaction, never by ordering. The declared batch order is not the dependency order at all: DDI-2 enums/records occupy topological ranks 0-11 while nine DDI-1 classes sit at ranks 15-51 | 2 (+ the batch order) | `WORK/agents/dag/DAG.md` §1 CYC-1, §2 |
| **RP-12** | **`git` is the unpinned root of the universe.** Making it a `tool` fact moves `UF-TOOL :minimum 5`, which is a universe-floor change requiring a `universe-authorization` — i.e. a governance act, not an edit | all | §6.2 F8, §8 AM-01; `verification-corpus.sexp:70` |

### 10. Adjudication items raised here (not decided)

* **ADJ-RM-01** — R-118: `TRACEABILITY-MATRIX.md:211` says no test ("δεν εκτελείται"); `requirements-tests-workpackets.sexp:78` binds it to Q19. §5.1.
* **ADJ-RM-02** — G09b/G17: `MISSING` (survival.json `missing = 2`) vs `DEMOTED (informational)` (`WORK/my-gate-mapping.md` rows 10, 16). §6.1.
* **ADJ-RM-03** — `RestrictedForensicRecord/1`: PRIVATE type owned by PUBLIC S18 — correct-by-design or a crossing that a `define-conditional` should make impossible? §7 PL-1.
* **ADJ-RM-04** — Root-authority future packet: three sources disagree. `SUBSYSTEM-REGISTRY.sexp:78` gives S14 `:future-wp WP-11`; `TRACEABILITY-MATRIX.md:390` (DFT-10) gives **WP-14**; `V1.8-SCHEMAS.sexp:319` gives the concept `ROOT_AUTHORITY_FLYWHEEL` → **FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED** ("NEW_GAP"). Affects `V1.8-SCHEMAS__define-dimension-policy` and `V1.8-SCHEMAS__define-reliance-aggregation`.
* **ADJ-RM-05** — Seat of the requirement/test universe: is it the `define-subsystem` projection (24 requirement facts) or the RA layer + `TRACEABILITY-MATRIX.md` (38 / 134)? Until this is fixed, DDI-1 cannot import capability seats or RA delta seats as L3-closed facts. Carries orchestrator N1.
* **ADJ-RM-06** — Is the governance/acceptance path part of "the public build" for the purposes of `:V8I-02`? §8 AM-02. **Reported, not decided** — the whole toolchain-pin question turns on it.
* **ADJ-RM-07** — May a declared-replaceable projection (MCP surface, static-site emitter) be a mandatory derivation source of a constitutional law, and must every closure family carry a cardinality floor so an emptied family fails instead of passing? §7 PL-8 / §8 AM-05.
* **ADJ-RM-08** — Owner of `PrivateMemoryEvent/1` on DDI-2 import: the private memory extension of S19 or the private matter profile S22? Not determinable from the registries. §7 PL-4 (orchestrator N9).
* **ADJ-RM-09** — Scope of the Option-A identification: set identity with the 20 `ck` calls of a2f45f6d, or the same concepts G1…G21 demanded over the complete 66-class model? The gate column of this map is only as strong as this answer. `WORK/agents/gates-skeptic/findings.md:28-33` (S-1), `:53-56` (S-8).

### 11. UNKNOWNS (honest ignorance — no guess substituted)

1. **The Option-A list itself is not in the repository.** "Full build, all 20 gates" occurs in no tracked file of
   any ref. Every value in the `option_a_gate` column is a CANDIDATE derived from `a2f45f6d`'s 20 `ck` calls by
   the rules in §3. If Option A's "20" were order items rather than `ck` calls, the universe changes (21 G-numbers).
2. **Whether the governance path is "the public build"** (ADJ-RM-06). Not decidable from the artifacts.
3. **Which batches add modules** — survival.json records `UNKNOWN` for G05's DDI dependency; §M4 gives the
   *proposed* modules from the matrices, which is a proposal, not a decision.
4. **Consumer status of the 17 NOT-NAME-TESTABLE classes.** Their identity is a `(file, head)` pair, so the
   name-occurrence test in M3 is not applicable to them; they are neither counted as orphans nor cleared.
5. **Whether flattening a nested form loses meaning** for any specific class. I measured *that* nesting exists
   and how deep; I did not adjudicate any individual flattening.
6. **The failure conditions of `RA-Q-RESOLVE` and `RA-Q-TENANT`** are not merely unfound — they are absent from
   the clone. I cannot say whether they were ever written.
7. **Nothing was executed.** No kernel, checker, gate or corpus ran; `sbcl` and `clingo` are not installed in
   this container. Every "would fail / would trip" statement is a reading of the declared machinery, not a run.




## Orchestrator's independent findings folded in

- **N1** RA-layer requirement/test ids referenced by DDI-1 classes are not model facts (see DDI-DEPENDENCY-AND-ORDER §3).
- **N2** `wp` ids have two origins once `define-wp-purpose` is imported.
- **N4** Every nested-list source form (records' field lists, enums' value lists, graph edge lists, tables, fixtures) is inadmissible under L1 as a model value; a flattening rule or schema extension is a prerequisite decision, and it is a FOUNDATIONAL one because it fixes the fact vocabulary every later batch uses.
- **N5** V1.7 `define-write-authority` is content-identical to the IMPORTED V1.8 class; V1.7 `define-capability-seat` differs from V1.8 in all 7 rows (paths, `:kind`, one renamed capability `JURIS_ANONYMIZE`→`JURIS_RATIO`, subsystem `RA-S25`→`S25`).
- **N6** The acceptance path is pinned to CPython 3.11.15, clingo 5.8.2, SBCL 2.2.9 (Ubuntu build), coreutils 9.4 on one host; `V8I-02` forbids a mandatory Python/runtime in the PUBLIC BUILD. The governance path is classified `GOVERNANCE_MACHINERY`; whether it is part of "the public build" is a tension for the creator, recorded here, not decided. In this session's container `sbcl` and `clingo` are absent, so the kernel cannot be executed here at all — an illustration of the single-host pin.
- **Boundary check (model, independent):** none of the six PRIVATE types (`EmbodimentInterfaces/1 PrivateMatterProfile/1 RealTimeAssistance/1 RestrictedForensicRecord/1 SidecarSourceProfile/1 TenantProfile/1`) appears in any `consumes` edge; the only private consumer edge is `S22 → DeclassificationReceipt/1` (private consuming public, the permitted direction). `PrivateMemoryEvent/1`, named in V1.8 `define-ra-closure-roots :private-forbidden`, is a V1.6 `define-record` (V1.6-SCHEMAS.sexp:312, `:status :DEFERRED_PRIVATE :public-dependency nil`, batch DDI-2) that is NOT a model `type` today; on import it must be classified PRIVATE and given an owner — the private memory extension of S19 or the private matter profile S22 is not determinable from the registries alone (adjudication item).

## 2. Common Lisp-native impact map (Part 4; full per-class 12-dimension rows are in DDI-1-4-EXECUTION-MATRIX.sexp `:cl-native`)

### DDI-1

#### cl-DDI-1 — Common-Lisp-native usage map for the 12 DDI-1 classes (Part 4)

READ-ONLY reconnaissance against RO HEAD 4ee2b58a (tree ad71185a). No production code written. Normative contract: `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md` (L5-8: eight-field discipline reason→seat→requirement→invariant→test→fallback→migration→rollback; L23/L40-41: MOP forbidden without a named invariant). Companion data: `cl-map.json` (one object per class: class_id + 12 dimensions + python_in_cl_risk + future_freedom + evidence). Every dimension value is either `NOT-APPLICABLE` (reason in `evidence.na_reasons`) or `<mechanism> | invariant: <…> | fallback: <…>`.

##### 0. Batch DDI-1 = 12 classes / 40 forms (WORK/classes.md rows 17,23,32,41,43,44,45,46,56,57,65,66; build_deferred.py:86-90)

| # | class_id | forms | source lines | ledger | dossier import_kind |
|---|---|---|---|---|---|
| 1 | `V1.5-SCHEMAS__define-required-refs` | 1 | CensusSpaceClassification/1 (V1.5-SCHEMAS.sexp:209-214) | deferred-imports.sexp:27 (DDI-1) | NEEDS_SCHEMA_EXTENSION |
| 2 | `V1.5-SCHEMAS__define-construction-order` | 1 | legal-ir-interpretive (V1.5-SCHEMAS.sexp:597-609) | deferred-imports.sexp:18 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 3 | `V1.6-SCHEMAS__define-construction-order` | 1 | cognition-stage-dag (V1.6-SCHEMAS.sexp:217-229) | deferred-imports.sexp:32 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 4 | `V1.7-SCHEMAS__define-construction-order` | 1 | cognition-stage-dag-v7 (V1.7-SCHEMAS.sexp:80-94) | deferred-imports.sexp:43 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 5 | `V1.7-SCHEMAS__define-ra-closure-roots` | 1 | (public-roots …) anonymous singleton (V1.7-SCHEMAS.sexp:290-296) | deferred-imports.sexp:47 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 6 | `V1.8-SCHEMAS__define-ra-closure-roots` | 1 | (public-roots …) anonymous singleton (V1.8-SCHEMAS.sexp:259-265; derivation comments :266-276) | deferred-imports.sexp:64 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 7 | `V1.7-SCHEMAS__define-pipeline` | 1 | symbolic-only-path (V1.7-SCHEMAS.sexp:308-317) | deferred-imports.sexp:46 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 8 | `V1.7-SCHEMAS__define-write-authority` | 10 | :store=journal … tenant-profile, 10 rows (V1.7-SCHEMAS.sexp:327-336) | deferred-imports.sexp:52 (DDI-1) | PURE_DATA |
| 9 | `V1.7-SCHEMAS__define-capability-seat` | 7 | :RESOLVE_IDENTIFIER … :RIGHTS_LICENSE, 7 rows (V1.7-SCHEMAS.sexp:346-352) | deferred-imports.sexp:41 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 10 | `V1.8-SCHEMAS__define-capability-seat` | 7 | :RESOLVE_IDENTIFIER … :EXPRESSION_TRANSLATE, 7 rows (V1.8-SCHEMAS.sexp:243-249; :V8I-CAP-real :250-254) | deferred-imports.sexp:55 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 11 | `V1.8-SCHEMAS__define-canonical-identity` | 8 | LegalIR/1 … RightsMatrix/1, 8 rows (V1.8-SCHEMAS.sexp:425-432; doctrine :416-424; invariant :433-441) | deferred-imports.sexp:54 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |
| 12 | `V1.8-SCHEMAS__define-ra-delta-seats` | 1 | (:delta RA-EPOCH …) anonymous singleton, 7 rows (V1.8-SCHEMAS.sexp:444-451; invariant :455-458) | deferred-imports.sexp:65 (DDI-1) | NEEDS_ARCHITECTURAL_DECISION |

Total forms: 40 (matches BRIEF: DDI-1 = 12 classes / 40 forms).

##### 1. Real CL seats used as anchors (all verified by grep in RO/source this session)

- **generic functions** — source/cognition.lisp:107 `defgeneric triage`; :92 `plan`; :96 `execute-step (step frame cog)`; :101 `synthesize`; :113 `critique`
- **CLOS classes** — source/cognition.lisp:35 `defclass frame`, :42 `defclass working-memory` (contract L20 cites `:46` — 4-line drift), :58 `defstruct cognition`; source/legal-ast.lisp:291 `defclass ast-node` (+16 subclasses), :1170 `defgeneric ast-to-form`; source/knowledge-graph.lisp:116 `defclass knowledge-graph`; source/legal-decisions.lisp:71 `defclass legal-decision`
- **JTMS** — source/legal-inference-engine.lisp:227 `defclass jtms`; :238 `make-jtms`; :347 `recompute-beliefs` (well-founded, deterministic); :395 `tms-retract-premise`; :78 `unify`; :491 `defmacro defrule`
- **canonical serialization** — source/journal.lisp:61-68 `canon-sexp` ('ONE canonical serialization … anything else ⇒ ERROR (fail-closed)'); ARCHITECTURE-MODEL/CANONICAL-ENCODING.md:1-3 AMC2; MODEL-SCHEMA.sexp:37 `:canonical-encoding "AMC2"`
- **persistent hash chain** — source/journal.lisp:507-515 `chained-append` (:identity :hash, :back-link :prev, RATCHET-2); :495 `stale-chain-link`; :252 `non-monotonic-transaction-time`; source/memory.lisp:79 `record-episode` (:prev, :hv 2 hash via canon-sexp :102-109)
- **condition/restart** — source/safe-read.lisp:68 `define-condition safe-read-error`; source/capability-registry.lisp:72 `capability-seat-collision`, :83 `capability-error`; source/legal-ast.lisp:1604-1615 `restart-case` (use-empty-node / skip-node / provide-node — ':interactive (eval (read)) REMOVED'); source/trace-core.lisp:264-277; source/greek-tokenizer-advanced.lisp:434. These are the ONLY three `restart-case` seats in source/. source/legal-dialectic.lisp has NO condition/restart (only `defpackage` :14).
- **macros / DSLs** — source/capability-registry.lisp:140-147 `defmacro define-capability` ('the ONE declarative definition; HTTP/MCP/CLI are projections'); source/mcp-server.lisp:80 `defmacro define-mcp-tool` (uses :133,:138,:151,:173); source/greek-legislation-ontology.lisp:57 `defmacro defconcept`; source/legal-event-calculus.lisp:43,52,61 `defrule ec-*`; source/write-authority.lisp:53-73 `defmacro with-write-authority`; source/safe-read.lisp:152-160 `%with-data-env` (*read-eval* nil)
- **write authority** — source/write-authority.lisp:4 `defpackage :orchestrator.write-authority`; :16-51 `emit-graph` ('the ONLY authorized write function' :29); :32-41 UNTYPED `(error "…")` checks; :35 allowed set = {:canonical :provenance} (2 values, not 10 stores)
- **package / ASDF** — 16 root `orchestrator*.asd` systems (ls RO/); deployment/collab/dialogue/0146-claude.md:18 'ASDF graph 16 systems, 53 edges, cycle NONE'; 128 files with `defpackage`; packages named by capability rows: canonical-uris.lisp:12 `:orchestrator.uris`, static-site.lisp:26, ai-citation-strategy.lisp:5, ai-corpus-dump.lisp:21 `:orchestrator.ai-dump`, journal.lisp:22, memory.lisp:27, legal-ast.lisp:57
- **kernel-law time (the CL reader of the model)** — ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:2 ('*read-eval* nil … NO project reader macros; no eval'); :16 `defpackage :aml-kernel`; :56 reader binding; :119-166 L1/L2 checks incl. :163-166 define-conditional 'requires/forbids (rule ~a)'; TOOLCHAIN.sexp:29-33 KERNEL_RUNTIME = SBCL 2.2.9
- **runtime rule seat** — source/constitutional-gate.lisp:16 `:orchestrator.constitution`; :22-47 runtime plist rules; 0 `eval-when`, 0 `defmacro`; :45 rule error ⇒ FAIL-OPEN ('σφάλμα κανόνα ⇒ ΜΗΝ μπλοκάρεις')
- **temporal** — source/version-graph.lisp:7 bitemporal [valid-from,valid-until)×[recorded-from,recorded-until); :221 `defstruct text-version`; :184 `temporal-uncertainty`; source/legal-temporal.lisp exists
- **model schema as data** — MODEL-SCHEMA.sexp:26-30 `define-conditional` (state-dependent field rule kept as DATA); :34-36 `define-unique`; :24-25 closed `:ref` universe; :44 SEAT-SPACE; :56 migration-status enum (no SUPERSEDED value); :71 yes-no enum; :132-136 `seat`; :155-158 `store`; :159 `stage` (no fields); :178-181 `req-map`; :217-220 `fixture :expect`; :308 SEAT-PATH-UNIQUE; :319 STORE-OWNER-IS-ONE-SEAT

##### 2. Matrix (● = mechanism named with invariant+fallback; — = NOT-APPLICABLE, reason in cl-map.json)

| class | immut | clos | gf | cond/restart | macro | proto | pkg/asdf | event | jtms | temporal | compile-t | runtime | py-risk | freedom |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `V1.5-SCHEMAS__define-required-refs` | ● | — | — | ● | — | — | ● | — | — | — | ● | ● | MEDIUM | NO |
| `V1.5-SCHEMAS__define-construction-order` | ● | — | — | ● | — | — | ● | ● | ● | ● | ● | ● | HIGH | NO |
| `V1.6-SCHEMAS__define-construction-order` | ● | — | ● | ● | — | ● | ● | — | — | — | ● | ● | HIGH | CONSTRAINS |
| `V1.7-SCHEMAS__define-construction-order` | ● | — | ● | ● | — | ● | ● | — | ● | — | ● | ● | HIGH | CONSTRAINS |
| `V1.7-SCHEMAS__define-ra-closure-roots` | — | — | — | ● | — | — | ● | — | — | — | ● | ● | HIGH | CONDITIONAL |
| `V1.8-SCHEMAS__define-ra-closure-roots` | — | — | — | ● | — | — | ● | — | — | — | ● | ● | HIGH | CONDITIONAL |
| `V1.7-SCHEMAS__define-pipeline` | — | — | ● | ● | — | ● | ● | — | — | — | ● | ● | MEDIUM | CONDITIONAL (protects S20; constrains S04 via :node-types) |
| `V1.7-SCHEMAS__define-write-authority` | ● | — | ● | ● | ● | ● | ● | ● | — | ● | ● | ● | LOW | NO |
| `V1.7-SCHEMAS__define-capability-seat` | ● | — | — | ● | ● | ● | ● | — | — | — | ● | ● | HIGH | CONDITIONAL |
| `V1.8-SCHEMAS__define-capability-seat` | ● | — | — | ● | ● | ● | ● | — | — | — | ● | ● | HIGH | CONDITIONAL |
| `V1.8-SCHEMAS__define-canonical-identity` | ● | — | — | ● | — | — | ● | ● | — | ● | ● | ● | HIGH | CONDITIONAL |
| `V1.8-SCHEMAS__define-ra-delta-seats` | — | — | — | ● | — | — | ● | ● | ● | ● | ● | — | MEDIUM | CONDITIONAL |

Counts: classes 12 · mechanisms named 79 (of 144 cells) · NOT-APPLICABLE 65 · MOP requested 0 · python-in-CL risk non-LOW 11 (LOW: V1.7 define-write-authority, whose data is already canonical) · future-freedom constraints (CONSTRAINS or CONDITIONAL) 9 (NO CONSTRAINT: define-required-refs, V1.5 define-construction-order, V1.7 define-write-authority).

##### 3. Per-class future CL-native usage (condensed; full 12-dimension text in cl-map.json)

###### V1.5-SCHEMAS__define-required-refs

- **immutable_record** — The rule table is constant data (one flat `required-ref` fact per (record, enum-value, field) triple, 6 facts + 2 explicitly-empty rows) — a read-only datum of the type schema, never a mutable registry; instances of CensusSpaceClassification/1 (V1.5:198-208, fields valid_from/valid_to) are the mutable-in-time objects, the rule is not
  - invariant: :V5I-04 (V1.5:246-253) 'census-coverage-decision is TOTAL, deterministic and SINGLE-VALUED over the finite input product' — a rule that could change at runtime would break totality
  - fallback: literal constant list (defparameter) read from the model module
- **condition_restart** — typed condition `missing-required-ref` carrying (record-id, enum-value, field) signalled at census admission; NO restart that supplies a default ref — the decision degrades to UNKNOWN (pattern: safe-read.lisp:68 safe-read-error with :why reader)
  - invariant: :V5I-04 'A serial gap alone is NEVER EXPLICITLY-ABSENT … Every remaining combination ⇒ UNKNOWN' (V1.5:251-252); contract L24 'typed errors, never a guess'
  - fallback: return typed error value (fail-closed, decision = UNKNOWN)
- **package_asdf_boundary** — No CL package today: owner S01 (interfaces-and-types.sexp:13 type CensusSpaceClassification/1 :owner-subsystem S01) whose seat SEAT-COVERAGE-LEDGER is DESIGN_TARGET (seats.sexp:77-78, packet WP-01, no coverage-ledger.lisp tracked); the rule therefore lives ONLY as model data beside the `type` fact until WP-01 builds the package that checks it
  - invariant: seats.sexp:15-17 'a design target can never be dressed as a real file'; contract L31 'package boundary = capability boundary'
  - fallback: monolith package
- **compile_time_validation** — Totality of the table at kernel-law time: every value of the closed enum enumerability_class (V1.5:169-171: 5 values) has exactly one row (a row with zero fields is a row, not an absence); each :field is a declared field of the record (V1.5:200-208) — the same DATA shape as define-conditional (MODEL-SCHEMA.sexp:26-30) enforced today by model-law-kernel.lisp:163-166 'requires :~a (rule ~a)'
  - invariant: :V5I-04 totality; L1 closed enums + L3 closed refs (MODEL-SCHEMA.sexp:18,24-25)
  - fallback: runtime check at admission
- **runtime_validation** — Data-driven conditional-field check of a CensusSpaceClassification/1 instance against the required-ref facts (one generic checker over the table, zero per-value code) — identical in shape to the kernel's define-conditional evaluator (model-law-kernel.lisp:160-166)
  - invariant: :V5I-04; V5S-D2c audit intent (V1.5:208 comment 'machine-checkable')
  - fallback: reject instance (fail-closed) — decision UNKNOWN
- NOT-APPLICABLE: clos_class, generic_function, macro_dsl, protocol, persistent_event, truth_maintenance_dependency, temporal_index_projection (reasons: evidence.na_reasons)
- **python_in_cl_risk** — MEDIUM. Naive import yields a dict {enum_value: [field,...]} plus an imperative validator `if cls == SERIAL_SPACE: require(a,b,c)`. Source shape is nested row lists (V1.5:210-214) which L1 forbids as values (MODEL-SCHEMA.sexp:5-6; orchestrator-notes.md N4). CL-native alternative: flatten to typed facts `required-ref` (:record -> type, :enum-value -> enum-value fact [DDI-2], :field -> field fact [DDI-2]) so the table is inspectable data and the checker is the ONE generic conditional-field evaluator already specified by define-conditional (MODEL-SCHEMA.sexp:26-30). Two structural traps: (a) the two empty rows (OPEN_WORLD, UNKNOWN; V1.5:213-214) must be representable as explicit zero-field rows — absence is not a declaration (seats.sexp:19 'none as a bare word is not an answer'); (b) the id CensusSpaceClassification/1 is already owned by `type` (interfaces-and-types.sexp:13) — L2 (MODEL-SCHEMA.sexp:124-126 'id declared under both') forbids reusing it, so the fact ids must be synthesised (dossier V5-A9).
- **future_freedom** — NO CONSTRAINT on S04 language cognition, S19 memory, the JTMS, or S20 adapters: the rule binds only the S01 census record and is consumed by census-coverage-decision (V1.5:229, DDI-3). It keeps future freedom BECAUSE it is data: adding a field/value is a fact, not a method. Batch-order coupling (not a freedom constraint): every target is DDI-2 detail (enum values V1.5:170-171, fields V1.5:201-203) — dag-fragment.md:20 / dossier V5-A10 — so the facts cannot be L3-closed in DDI-1 order.
- adjudication refs: V5-A9, V5-A10, V5-A15

###### V1.5-SCHEMAS__define-construction-order

- **immutable_record** — The 9 ordered record kinds are hash-bearing immutable bodies (V1.5:598 'immutable; refs only AuthorityBasis/anchors'; :V5I-A2-immutable-id V1.5:554); a construction order over content-addressed records IS the dependency order of their identities — an object can only be hashed after everything it references exists (journal.lisp:507 chained-append :identity :hash; canon-sexp journal.lisp:61)
  - invariant: :V5I-C1-acyclic (V1.5:610-616) 'the content-addressing dependency graph over ALL hash-bearing ref fields … is ACYCLIC'; contract L27 'identity = content-address; lifecycle detached'
  - fallback: copy-on-write; keep prior version
- **condition_restart** — typed condition `construction-order-violation` (from-kind, to-kind, ref-field) when a hash-bearing ref would target an unbuilt identity; no restart that fabricates the dependency
  - invariant: :V5I-C1-acyclic 'Any cycle … ⇒ kill (V5KW-C1-9)'; contract L24
  - fallback: typed error value (fail-closed)
- **package_asdf_boundary** — Owner S04 (V1.6:97 declares the canonical seat of 'v1.5 C1 records' as legal-ast.lisp + LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md; seats.sexp:32 SEAT-LEGAL-AST; package :orchestrator.legal-ast legal-ast.lisp:57). The order is Legal-IR SEMANTICS and therefore must remain language-independent data that compiler B (Rust, WP-05) can read — no CL mechanism (class precedence, load order, ASDF :serial) may become the seat of the order
  - invariant: contract §1 (L10-15) 'no CL mechanism may leak into the IR contract such that a non-Lisp compiler cannot conform'; §3 (L42-44)
  - fallback: monolith package
- **persistent_event** — Step 9 LifecycleRecord/1 (V1.5:606 'detached overlay keyed to any immutable subject') is an EVENT over an identity, journal-shaped: appended, hash-chained, never mutating the subject (journal.lisp:507 chained-append; memory.lisp:79 record-episode :prev)
  - invariant: contract L27 'lifecycle detached (v1.5 R2)'; V1.5 define-rule lifecycle-overlay (V1.5:544, DDI-4)
  - fallback: full replay
- **truth_maintenance_dependency** — Steps 10-12 are DERIVED projections over (7),(3),(9) (V1.5:607-609): dependency-directed recomputation targets — a projection is a JTMS-style consequent of its base records so that a new ArgumentRecord/CanonPolicy/LifecycleRecord recomputes exactly the dependent projection (legal-inference-engine.lisp:227 jtms, :347 recompute-beliefs; corpus-diff.lisp:66 corpus-diff for deltas)
  - invariant: contract L29 'recomputation is deterministic + replayable'; L28 'belief revision is monotone-audited'
  - fallback: full recompute of the three projections
- **temporal_index_projection** — Step 12 SubjectCurrentStatus (V1.5:609, define-projection V1.5:540 DDI-3) is a current-time projection over the LifecycleRecord/1 overlay — the same shape as version-graph's bitemporal text-version (version-graph.lisp:7, :221) where valid-time is a PROJECTION (version-graph.lisp:334)
  - invariant: valid-time vs recorded-time separation (version-graph.lisp:7); :V5I-C1-relation-detached (V1.5:522)
  - fallback: full scan of the overlay
- **compile_time_validation** — Kernel-law time: (i) every step target is a declared id (L3, MODEL-SCHEMA.sexp:24-25) — steps 2 ConflictPolicyBundle and 5 statement are UNDECLARED today (dossier V5-A7: CHANGE-PROPOSAL-v1.4.md:871 prose / LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md:55) so L3 cannot close; (ii) the order is CONSISTENT with the typed ref graph (define-ref-classification V1.5:569, DDI-2) — i.e. derived by topological sort and compared, never authored twice
  - invariant: L3 + L4 (acyclicity of every from/to relation); V1.8:266 VR-01 'edges are DERIVED FROM REAL SOURCES, never from manual restatement'
  - fallback: runtime check at build
- **runtime_validation** — At record construction: a hash-bearing ref to an identity not yet in the store signals the typed condition above; the store is the journal/legal-ir store (stores-and-authorities.sexp:9 store legal-ir :owner SEAT-LEGAL-AST :writer SEAT-WRITE-AUTHORITY)
  - invariant: :V5I-C1-acyclic; V7I-OWN-single-writer (V1.7:337-340)
  - fallback: fail-closed
- NOT-APPLICABLE: clos_class, generic_function, macro_dsl, protocol (reasons: evidence.na_reasons)
- **python_in_cl_risk** — HIGH. Naive import yields an ordered Python list [(1,'CanonRule/1'),…,(12,'SubjectCurrentStatus')] and a build script that iterates it (the build_*.py shape) — an authored SECOND seat of a truth already carried by the records' hash-bearing ref fields, which V6I-REF (V1.6:158-162) and V8I-03 (V1.8:20-22) reject as duplicate source of truth. CL-native alternative: the order is DERIVED (topological sort of `ref-classification`/field-type facts, DDI-2) and the authored 12-step list becomes an EXPECTATION — a `fixture :expect PASS :law L4` (MODEL-SCHEMA.sexp:217-220) or `construction-step`/`construction-edge` facts whose agreement with the derived order is a kernel-law property. Source shape is nested (n Name) pairs (V1.5:598-609) — L1 forbids nested values, so flattening is mandatory in any case (N4).
- **future_freedom** — NO CONSTRAINT on S19/S20/LLM. S04: the order fixes Legal-IR construction semantics (Claim before Argument, V1.5:614-615) — legitimate because it is IR contract semantics (LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md §12 per dossier) that both compilers must share; it would become a constraint only if imported as a CL-specific mechanism (contract §1). JTMS: steps 10-12 should be JTMS consequents rather than a hand-ordered rebuild, otherwise future incremental reasoning (contract L28-29) is pre-empted by a full-rebuild order. Grammar clash with V1.6/V1.7 same-head forms (dossier V5-A10) must not be 'solved' by a union type that carries both shapes.
- adjudication refs: V5-A7, V5-A10, V5-A15, CL-DDI1-A6

###### V1.6-SCHEMAS__define-construction-order

- **immutable_record** — Stage :in/:out records (PerceptionEnvelope/1 … CognitionResult/1, V1.6:85-204, DDI-2) are typed immutable values handed between stages; the stage table itself is constant data (12 stage facts + 11 edge facts), not a mutable pipeline object
  - invariant: :V6I-COG-symbolic-only (V1.6:265-269); :V6I-COG-one-to-one (V1.6:270)
  - fallback: copy-on-write records
- **generic_function** — One stage = one method of an `execute-step`-shaped generic (cognition.lisp:96 defgeneric execute-step (step frame cog)) specialised on the stage designator (eql COG-n), with the stage's :in record as typed argument and :out record as typed result; stage designators are data (facts), methods are the built seats — REUSING the existing generics (cognition.lisp:92-107 plan/execute-step/synthesize/triage), never a forked pipeline
  - invariant: contract L21 'dispatch is total or errors typed'; :V6I-13-cognition-one-seat (V1.6:261-264) 'reuses the existing Lisp seats and never forks a second implementation'
  - fallback: single dispatch function over a stage table
- **condition_restart** — The CLARIFY stage's seat string literally names 'condition/restart' (V1.6:227 COG-10-CLARIFY; V1.7:91 COG7-11-CLARIFY): clarification = a typed condition `clarification-required` with restarts (passthrough | provide-clarification), invoked PROGRAMMATICALLY only (pattern legal-ast.lisp:1604-1615 / trace-core.lisp:264-277 ':interactive (eval (read)) REMOVED'); no restart may pick a winner. legal-dialectic.lisp has NO condition/restart today (only defpackage :14) → [design-target]
  - invariant: no silent forced winner (V1.7:99 (e) :no-forced-winner); contract L24 'controlled ambiguity/recovery, no silent failure' seat 'cognition clarification (COG7-11)'
  - fallback: return typed error value (ClarificationState / ClarificationDecision record)
- **protocol** — The stage protocol is the existing generic-function protocol (triage/plan/execute-step/synthesize, cognition.lisp:92-107) with typed in/out; the SemanticProposer PROPOSER protocol (interfaces-and-types.sexp:57 :consumer-role PROPOSER; V1.6 define-protocol V1.6:57, DDI-4) is a SEPARATE optional protocol stages may consult, never require
  - invariant: :V6I-10-proposer-never-authority (V1.6:75); :V6I-COG-symbolic-only
  - fallback: explicit function table
- **package_asdf_boundary** — Stage seats span packages of several subsystems: :orchestrator.legal-ast (legal-ast.lisp:57, S04 seats.sexp:32), legal-event-calculus (S07 seats.sexp:38), legal-extraction-verify (S03 seats.sexp:30), :orchestrator.dialectic (legal-dialectic.lisp:14), plus 8 files with NO seat fact (greek-nlp-core, greek-tokenizer-advanced, greek-lemmatizer, legal-casegrammar, greek-legislation-ontology, legal-deontic, legal-dialectic, legal-qa — dossier ADJ-V17-CO-2). ':symbolic-only t' is a PACKAGE property: no ASDF system implementing a stage may :depends-on a proposer/adapter system (V1.6:67-73 adapters :mandatory nil) — the leak becomes a build failure, not an audit; legal-casegrammar.lisp[general] SPLIT (SUBSYSTEM-REGISTRY.sexp:130-134 :no-copy) is exactly a package split public/private
  - invariant: :V6I-COG-symbolic-only (V1.6:265-269); contract L31 'package boundary = capability boundary; declared forbidden dependencies' ([0146]:18 16 systems/53 edges acyclic)
  - fallback: monolith package + runtime SafetyMode check
- **compile_time_validation** — Typed connectivity at kernel-law time once stages are flat facts: stage_i :out = stage_{i+1} :in over closed `type` refs (L3); every :seat is a SEAT-SPACE id (MODEL-SCHEMA.sexp:44,132-136) not a string; :symbolic-only rendered as yes-no enum (MODEL-SCHEMA.sexp:71)
  - invariant: :V7I-COG-info-preserving (a) 'each stage :out type equals the next stage :in type (typed, connected)' (V1.7:96); L3
  - fallback: runtime check-type at method boundaries
- **runtime_validation** — check-type of the :in record at method entry and of the :out record at exit, signalling a typed condition on mismatch — no coercion, no proposer-derived default
  - invariant: contract L21 'dispatch is total or errors typed'; :V6I-COG-symbolic-only
  - fallback: fail-closed → SafetyMode :DEGRADED ⇒ SYMBOLIC_ONLY semantics (V1.6:23)
- NOT-APPLICABLE: clos_class, macro_dsl, persistent_event, truth_maintenance_dependency, temporal_index_projection (reasons: evidence.na_reasons)
- **python_in_cl_risk** — HIGH. Naive import yields a list of dicts [{'stage':'COG-1-SEGMENT','in':…,'out':…,'seat':'greek-nlp-core.lisp','symbolic_only':True}] and a for-loop runner; seat strings stay strings ('greek-nlp-core.lisp (EXTEND)', 'legal-casegrammar.lisp[general]', 'InterpretiveProfile/1 (v1.5 C1)' — a TYPE used as a seat; 'legal-qa.lisp + citation/1' — two seats in one string), and `t` becomes a Python bool. Every one of these is an L1 violation (nested plists, boolean, MODEL-SCHEMA.sexp:5-6) or an L3 violation (seat not in SEAT-SPACE). CL-native alternative: flat `cog-node` facts (:in/:out -> type, :seat -> seat, :symbolic-only yes-no) + `cog-edge` facts under L4, stages as methods of the existing generics, symbolic-only as an ASDF forbidden-dependency property. 'An arbitrary string is not a seat' (V1.7:354).
- **future_freedom** — CONSTRAINS S04 (language cognition) if imported as canonical: (i) it is the FIRST of three divergent cognition DAG seats (V1.6:217 12 stages → V1.7:80 14 stages → V1.8:53/363 typed graph, DDI-3) and V1.8:24-27 declares the linear list with :branch annotation REPLACED (DFT-07) — importing V1.6 as facts would freeze a superseded shape into the model (ADJ-V17-CO-1; V1.6 dossier A8); (ii) binding each stage to a file name freezes today's file layout (8 unseated files) into the canonical model, so a future re-partition of greek-nlp-core.lisp becomes a model change. No S19/S20/LLM constraint: all stages :symbolic-only t, proposers optional (V6I-02). Recommended reading: lineage-only / zero facts unless adjudicated.
- adjudication refs: V1.6-A8, V1.6-A13, ADJ-V17-CO-1, ADJ-V17-CO-2, CL-DDI1-A2

###### V1.7-SCHEMAS__define-construction-order

- **immutable_record** — 14 typed :in/:out records (V1.7:45-79 new intermediate records, DDI-2) passed as immutable values; COG7-13 ':binds-exact-candidate t' (V1.7:93) binds the promoted candidate by exact content identity — a content-address, not a mutable pointer (journal.lisp:61 canon-sexp; :507 chained-append :identity :hash)
  - invariant: :V7I-COG-info-preserving (b) 'every stage preserves source anchors + provenance' (V1.7:97); contract L27
  - fallback: copy-on-write
- **generic_function** — One stage = one method of an `execute-step`-shaped generic (cognition.lisp:96 defgeneric execute-step (step frame cog)) specialised on the stage designator (eql COG-n), with the stage's :in record as typed argument and :out record as typed result; stage designators are data (facts), methods are the built seats — REUSING the existing generics (cognition.lisp:92-107 plan/execute-step/synthesize/triage), never a forked pipeline
  - invariant: contract L21 'dispatch is total or errors typed'; :V6I-13-cognition-one-seat (V1.6:261-264) 'reuses the existing Lisp seats and never forks a second implementation'
  - fallback: single dispatch function over a stage table
- **condition_restart** — The CLARIFY stage's seat string literally names 'condition/restart' (V1.6:227 COG-10-CLARIFY; V1.7:91 COG7-11-CLARIFY): clarification = a typed condition `clarification-required` with restarts (passthrough | provide-clarification), invoked PROGRAMMATICALLY only (pattern legal-ast.lisp:1604-1615 / trace-core.lisp:264-277 ':interactive (eval (read)) REMOVED'); no restart may pick a winner. legal-dialectic.lisp has NO condition/restart today (only defpackage :14) → [design-target]
  - invariant: no silent forced winner (V1.7:99 (e) :no-forced-winner); contract L24 'controlled ambiguity/recovery, no silent failure' seat 'cognition clarification (COG7-11)'
  - fallback: return typed error value (ClarificationState / ClarificationDecision record)
- **protocol** — As V1.6 (existing generic protocol cognition.lisp:92-107) plus an explicit BRANCH on COG7-11 (V1.7:91 :branch (:NO_CLARIFICATION_PASSTHROUGH :CLARIFICATION_REQUIRED)) — in V1.8 this is a typed graph edge kind (V1.8:24-27, DDI-3), in CL a condition/restart outcome, never a second pipeline
  - invariant: :V7I-COG-info-preserving (d) 'COG7-11 is an EXPLICIT branch' (V1.7:98)
  - fallback: explicit function table
- **package_asdf_boundary** — Stage seats span packages of several subsystems: :orchestrator.legal-ast (legal-ast.lisp:57, S04 seats.sexp:32), legal-event-calculus (S07 seats.sexp:38), legal-extraction-verify (S03 seats.sexp:30), :orchestrator.dialectic (legal-dialectic.lisp:14), plus 8 files with NO seat fact (greek-nlp-core, greek-tokenizer-advanced, greek-lemmatizer, legal-casegrammar, greek-legislation-ontology, legal-deontic, legal-dialectic, legal-qa — dossier ADJ-V17-CO-2). ':symbolic-only t' is a PACKAGE property: no ASDF system implementing a stage may :depends-on a proposer/adapter system (V1.6:67-73 adapters :mandatory nil) — the leak becomes a build failure, not an audit; legal-casegrammar.lisp[general] SPLIT (SUBSYSTEM-REGISTRY.sexp:130-134 :no-copy) is exactly a package split public/private
  - invariant: :V6I-COG-symbolic-only (V1.6:265-269); contract L31 'package boundary = capability boundary; declared forbidden dependencies' ([0146]:18 16 systems/53 edges acyclic)
  - fallback: monolith package + runtime SafetyMode check
- **truth_maintenance_dependency** — :preserves (anchors provenance alternatives uncertainty) on COG7-09..12 (V1.7:89-92) is exactly the input to a JTMS: each alternative of LegalSemanticAlternativeSet/1 is a node whose belief a ClarificationDecision/1 may retract WITHOUT deleting it (legal-inference-engine.lisp:238 make-jtms; :395 tms-retract-premise; :347 recompute-beliefs, well-founded, deterministic)
  - invariant: :V7I-COG-info-preserving (c) 'alternative identity and uncertainty are preserved from COG7-09 through COG7-12 and never silently dropped' (V1.7:97-98); contract L28 'belief revision is monotone-audited'
  - fallback: full recompute of the alternative set
- **compile_time_validation** — Typed connectivity at kernel-law time once stages are flat facts: stage_i :out = stage_{i+1} :in over closed `type` refs (L3); every :seat is a SEAT-SPACE id (MODEL-SCHEMA.sexp:44,132-136) not a string; :symbolic-only rendered as yes-no enum (MODEL-SCHEMA.sexp:71); additionally each :preserves property is a flat `cog-preserves` fact (stage, property) so that (b)/(c) are checkable as data rather than trusted comments
  - invariant: :V7I-COG-info-preserving (a)-(e) (V1.7:95-99); L3
  - fallback: runtime check-type at method boundaries
- **runtime_validation** — check-type of the :in record at method entry and of the :out record at exit, signalling a typed condition on mismatch — no coercion, no proposer-derived default
  - invariant: contract L21 'dispatch is total or errors typed'; :V6I-COG-symbolic-only
  - fallback: fail-closed → SafetyMode :DEGRADED ⇒ SYMBOLIC_ONLY semantics (V1.6:23)
- NOT-APPLICABLE: clos_class, macro_dsl, persistent_event, temporal_index_projection (reasons: evidence.na_reasons)
- **python_in_cl_risk** — HIGH — as V1.6 plus deeper nesting: each of 14 plists carries nested :preserves lists and one nested :branch list (V1.7:81-94), all L1-forbidden as values; :no-forced-winner t / :binds-exact-candidate t booleans. Naive import = list-of-dicts + runner + comments-as-truth. CL-native alternative: `cog-node` / `cog-edge` / `cog-preserves` flat facts (yes-no enums for the flags), stages as eql methods of the existing generics, alternatives held in a JTMS (contract L28), CLARIFY as condition/restart. Same seat-string problem as V1.6 (8 unseated files; 'InterpretiveProfile/1 (v1.5 C1)' and 'citation/1' are types used as seats — ADJ-V17-CO-2).
- **future_freedom** — CONSTRAINS S04 if imported as canonical: V1.8 (DFT-07, V1.8:24-27; CHANGE-PROPOSAL-v1.8.md:33-37 per dossier) explicitly replaces this linear-list-with-:branch shape by a typed graph (cognition-graph-v8 V1.8:53 + node types :363, DDI-3) — importing V1.7 in DDI-1 before the DDI-3 graph would seat the superseded topology first (batch order conflict ADJ-V17-CO-1; dag-fragment.md:44-49 order violations). It PROTECTS future reasoning if :preserves becomes JTMS data (alternatives retractable, never dropped). No S19/S20/LLM constraint (all stages :symbolic-only t; V7I-no-mandatory-model-v7 V1.7:301).
- adjudication refs: ADJ-V17-CO-1, ADJ-V17-CO-2, ADJ-V18-COG-1, ADJ-V18-NT-4, CL-DDI1-A2

###### V1.7-SCHEMAS__define-ra-closure-roots

- **condition_restart** — typed condition `private-type-leak` (family, source-file, locator, from-type, to-type) raised at kernel-law time; NO restart — the leak must be 'structurally absent' (V1.7:300)
  - invariant: L5 (MODEL-SCHEMA.sexp:47-50 'a typed L5 violation'); :V7I-PUBPRIV-acyclic (V1.7:297-300); :V8I-PUBPRIV-all-families (V1.8:277-283)
  - fallback: typed error value
- **package_asdf_boundary** — THE native seat of the boundary: the public build is a set of ASDF systems with NO :depends-on edge to any private system; private families (S22-S24 DEFERRED_PRIVATE, S26 INTERFACE_ONLY — seats.sexp:91-98, :path FORBIDDEN MODEL-SCHEMA.sexp:299-302) have no public package to depend on, so a public→private reference is a LOAD FAILURE (undefined package/symbol), not an audit finding — the error class is eliminated structurally (CLAUDE.md law 2) instead of enumerated by roots/forbidden lists
  - invariant: :RA-I-4-public-independent-of-private (V1.7:23); :V6I-07 (V1.6:38); contract L31 'declared forbidden dependencies; ASDF graph cycle check (exit 0)' ([0146]:18)
  - fallback: monolith + runtime closure check over derived edges
- **compile_time_validation** — Closure computed at kernel-law time over DERIVED edges: today L5 runs over `consumes` + `type :classification` only (MODEL-SCHEMA.sexp:148-152,164-170; PF-L5-PRIVATE-TYPE-LEAK per dossier verification-corpus.sexp:45-47); V1.8 demands 8 families (V1.8:264-265) of which api-mcp-schema and publication are derived from CL SOURCE (mcp-server.lisp:80,133-173 define-mcp-tool; static-site.lisp:308 emit-corpus-site) — a source-derived edge needs a NON-EVALUATING reader (safe-read.lisp:152-165; model-law-kernel.lisp:2,56 *read-eval* nil), never `load`
  - invariant: :V8I-PUBPRIV-all-families 'edges DERIVED FROM REAL machine-readable sources … Manual define-public-edge restatements are FORBIDDEN as proof (VR-01)' (V1.8:278-283); contract L35 'no read/eval/macro over external input'
  - fallback: consumes-only L5 (today)
- **runtime_validation** — ASDF load-time: a forbidden :depends-on edge (public system → private system) fails the build
  - invariant: contract L31 test 'ASDF graph cycle check (exit 0)'; :V7I-PUBPRIV-acyclic
  - fallback: runtime closure check
- NOT-APPLICABLE: immutable_record, clos_class, generic_function, macro_dsl, protocol, persistent_event, truth_maintenance_dependency, temporal_index_projection (reasons: evidence.na_reasons)
- **python_in_cl_risk** — HIGH. Naive import yields three Python lists (11 roots / 14 edge-kinds / 5 forbidden, V1.7:291-296) and a BFS over a dict graph whose edges are MANUALLY restated — precisely what V1.8:283 forbids as proof (VR-01). The form is an anonymous singleton (no atomic id; orchestrator-notes.md N11) with nested lists (L1). CL-native alternative: ZERO authored root/forbidden facts — roots = every `type :classification PUBLIC`, forbidden = every `type :classification PRIVATE` (interfaces-and-types.sexp:5-64; the enum MODEL-SCHEMA.sexp:47) — and the edge families as derived relations over typed facts; the boundary enforced by package/ASDF dependency, the closure by the kernel over derived edges. Two blockers for verbatim import: PrivateMemoryEvent/1 (V1.7:296) is NOT a model type (N9 → L3 impossible); a PUBLIC form naming PRIVATE types would itself be a public→private reference unless typed as a negative list (dossier visibility note).
- **future_freedom** — CONDITIONAL. S19 memory: private-forbidden names PrivateMemoryEvent/1 (V1.6:312) — the private EXTENSION of the public memory base; the closure must stay one-way so that :V6I-MEM-public-base-clean (V1.6:305) holds without forbidding the private side from consuming the public base (V1.6 SR:134 'private consumes the public general mechanisms'). S20 adapters: edge kind api-schema (V1.7:295) makes the MCP surface a closure SOURCE — fine as derivation, but MCP/HTTP must remain projections (capability-registry.lisp:142-143), never a mandatory node (V8I-02). No S04/JTMS/LLM constraint. Divergent from V1.8:259-265 in all three lists (11/14/5 vs 10/8/7) — ADJ-V17-ROOTS-1 / ADJ-V18-ROOTS-1.
- adjudication refs: ADJ-V17-ROOTS-1, ADJ-V17-ROOTS-2, ADJ-V18-ROOTS-1, ADJ-V18-ROOTS-3, N9, N11, CL-DDI1-A9

###### V1.8-SCHEMAS__define-ra-closure-roots

- **condition_restart** — typed condition `private-type-leak` (family, source-file, locator, from-type, to-type) raised at kernel-law time; NO restart — the leak must be 'structurally absent' (V1.7:300)
  - invariant: L5 (MODEL-SCHEMA.sexp:47-50 'a typed L5 violation'); :V7I-PUBPRIV-acyclic (V1.7:297-300); :V8I-PUBPRIV-all-families (V1.8:277-283)
  - fallback: typed error value
- **package_asdf_boundary** — THE native seat of the boundary: the public build is a set of ASDF systems with NO :depends-on edge to any private system; private families (S22-S24 DEFERRED_PRIVATE, S26 INTERFACE_ONLY — seats.sexp:91-98, :path FORBIDDEN MODEL-SCHEMA.sexp:299-302) have no public package to depend on, so a public→private reference is a LOAD FAILURE (undefined package/symbol), not an audit finding — the error class is eliminated structurally (CLAUDE.md law 2) instead of enumerated by roots/forbidden lists
  - invariant: :RA-I-4-public-independent-of-private (V1.7:23); :V6I-07 (V1.6:38); contract L31 'declared forbidden dependencies; ASDF graph cycle check (exit 0)' ([0146]:18)
  - fallback: monolith + runtime closure check over derived edges
- **compile_time_validation** — Closure computed at kernel-law time over DERIVED edges: today L5 runs over `consumes` + `type :classification` only (MODEL-SCHEMA.sexp:148-152,164-170; PF-L5-PRIVATE-TYPE-LEAK per dossier verification-corpus.sexp:45-47); V1.8 demands 8 families (V1.8:264-265) of which api-mcp-schema and publication are derived from CL SOURCE (mcp-server.lisp:80,133-173 define-mcp-tool; static-site.lisp:308 emit-corpus-site) — a source-derived edge needs a NON-EVALUATING reader (safe-read.lisp:152-165; model-law-kernel.lisp:2,56 *read-eval* nil), never `load`
  - invariant: :V8I-PUBPRIV-all-families 'edges DERIVED FROM REAL machine-readable sources … Manual define-public-edge restatements are FORBIDDEN as proof (VR-01)' (V1.8:278-283); contract L35 'no read/eval/macro over external input'
  - fallback: consumes-only L5 (today)
- **runtime_validation** — ASDF load-time: a forbidden :depends-on edge (public system → private system) fails the build
  - invariant: contract L31 test 'ASDF graph cycle check (exit 0)'; :V7I-PUBPRIV-acyclic
  - fallback: runtime closure check
- NOT-APPLICABLE: immutable_record, clos_class, generic_function, macro_dsl, protocol, persistent_event, truth_maintenance_dependency, temporal_index_projection (reasons: evidence.na_reasons)
- **python_in_cl_risk** — HIGH — as V1.7, with one important difference in the source itself: V1.8:266-276 ALREADY states the CL-native doctrine ('edges are DERIVED FROM REAL SOURCES … Manual define-public-edge restatements are FORBIDDEN as proof'), so the only importable content is the FAMILY LIST (8 symbols, V1.8:264-265) plus each family's derivation source (V1.8:267-274) — e.g. `edge-family api-mcp-schema :source "source/mcp-server.lisp"`; roots and forbidden sets are derivable from `type :classification` and should import as ZERO facts (10 roots are all PUBLIC model types; 6 of 7 forbidden are PRIVATE model types; PrivateMemoryEvent/1 is not a type — N9). Importing the three lists as authored facts would recreate the 'manual restatement' the form forbids. Anonymous singleton id must be synthesised (N11).
- **future_freedom** — CONDITIONAL — as V1.7. Additionally the family store-owner-writer (V1.8:271) binds the closure to the write-authority table (C8) and publication (V1.8:273) to static-site.lisp emit-* — both are BUILT symbolic seats (seats.sexp:48,60), so no LLM/adapter becomes mandatory. The families api-mcp-schema/publication being derived from CL source means compiler B (Rust) cannot mirror those derivations at the code level — permitted by contract §3 (L42-44) only if the derived EDGES (not the reader) are the shared artefact.
- adjudication refs: ADJ-V18-ROOTS-1, ADJ-V18-ROOTS-2, ADJ-V18-ROOTS-3, N9, N11, N17, CL-DDI1-A9

###### V1.7-SCHEMAS__define-pipeline

- **generic_function** — One generic per stage boundary (execute-step-shaped, cognition.lisp:96); the three :proposer-optional-nodes ADMIT/IR/REASON (V1.7:313) are the stages whose generic admits an ADDITIONAL method contributed by an adapter system and removable with no path loss — the symbolic method is the primary method; the proposer method may enrich but never be an :around that decides (method-combination row)
  - invariant: :V7I-SYM-reachable (V1.7:318-322) 'removing every proposer … leaves entry→exit connected'; :V8I-02 (V1.8:17-19); contract L21 rollback 'remove method' / L22 'no :around that hides a forced winner'
  - fallback: single dispatch function; symbolic path only
- **condition_restart** — Unknown node type / broken edge fails CLOSED (V1.7:321) → typed condition at kernel-law time; at runtime an unavailable adapter signals a typed condition whose ONLY restart is `use-symbolic-only` (SafetyMode :DEGRADED 'fail-closed to SYMBOLIC_ONLY semantics', V1.6:23) — never a silent fallback
  - invariant: :V6I-03-symbolic-only-complete (V1.6:25-28); :V6I-02 'absence NEVER degrades correctness or safety' (V1.6:18-19)
  - fallback: typed error value
- **protocol** — Mode ownership: SafetyState / SYMBOLIC_ONLY controller = S21 SEAT-WRITE-AUTHORITY (seats.sexp:60-61); the PUBLISH exit writes only inside `with-write-authority` (write-authority.lisp:53) — the pipeline does not define a new protocol, it binds to the existing dynamic-scope write protocol
  - invariant: :V7I-OWN-single-writer (V1.7:337-340); contract L33 'canonical writes only via write-authority.lisp'
  - fallback: explicit authority parameter
- **package_asdf_boundary** — All 8 nodes :symbolic-only (V1.7:312) ⇒ the ASDF systems implementing ACQUIRE…PUBLISH have no :depends-on edge to any proposer/adapter system (ONNXProposerAdapter/OCRPerceptionAdapter V1.6:67-73 :mandatory nil :replaceable t); the 'mandatory-model-node' mutation (V1.8:339-340) is then a BUILD failure
  - invariant: :V8I-02-no-mandatory-model (V1.8:17-19); contract L31
  - fallback: monolith + runtime SafetyMode check
- **compile_time_validation** — Graph already canonical (stage/stage-edge facts dependencies-and-boundaries.sexp:5-21 from V1.8:326, L4 acyclic; reachability entry→exit as a property over stage-edge). V1.7-unique :node-types (V1.7:315-317) would be `stage :type` L3 refs — but COMPILE→legal_state_root and PROOF→proof_bundle are NOT defined types in any registry (dossier: git grep; only prose) so L3 cannot close for 2 of 8 rows; :symbolic-only-nodes / :proposer-optional-nodes are not model facts at all (stage fact has no fields, MODEL-SCHEMA.sexp:159; N15 field loss)
  - invariant: :V7I-SYM-reachable; :V8I-SYM-structural (V1.8:459-462); L3/L4
  - fallback: runtime check
- **runtime_validation** — SafetyMode transitions (SYMBOLIC_ONLY/ENRICHED/DEGRADED/OFFLINE, V1.6:20-24) evaluated at stage entry; absence of an adapter changes the mode, never the correctness of the symbolic result
  - invariant: :V6I-02; :V6I-03
  - fallback: fail-closed to SYMBOLIC_ONLY
- NOT-APPLICABLE: immutable_record, clos_class, macro_dsl, persistent_event, truth_maintenance_dependency, temporal_index_projection (reasons: evidence.na_reasons)
- **python_in_cl_risk** — MEDIUM. The topology is already canonical (imported from V1.8) — the risk is that the 8 non-topological keys (entry/exit/symbolic-only-nodes/proposer-optional/mandatory/node-types; N15) are imported as a side dict or as booleans attached to stage rows. CL-native alternative: `stage` gains an optional :type L3 ref and yes-no fields (or separate `stage-property` facts) rendered in the closed enum yes-no (MODEL-SCHEMA.sexp:71); node-type strings 'legal_state_root'/'proof_bundle' must NOT be imported as strings — either they get a `type` seat or the rows stay unimported (ADJ-V17-PIPE-1). The V1.7 form itself is byte-divergent from V1.8 only by :node-types (dropped in V1.8) and by V1.8's added :mandatory-nodes/:mutations.
- **future_freedom** — CONDITIONAL (protects S20; constrains S04 via :node-types). Protects S20/V8I-02 by construction (proposer-optional = replaceable adapter methods). Constrains S04 if :node-types is imported: REASON→CognitionResult/1 and COMPILE→legal_state_root freeze the v1.7 output vocabulary of cognition into the pipeline; V1.8 deliberately dropped :node-types (V1.8:326-335 per dossier) — importing the V1.7 table would re-freeze what V1.8 released. No S19/JTMS/LLM constraint. The 'no mandatory node' guarantee needs the non-evaluating ingress decoder the contract names (L35 ingress-decoder.lisp) — NOT FOUND in source/ (only deployment/LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md).
- adjudication refs: ADJ-V17-PIPE-1, ADJ-V17-PIPE-2, ADJ-V18-PIPE-1, ADJ-V18-PIPE-3, N15, CL-DDI1-A5

###### V1.7-SCHEMAS__define-write-authority

- **immutable_record** — The written stores journal / memory / legal-ir are append-only hash chains: journal.lisp:507 chained-append (:identity :hash, :back-link :prev, RATCHET-2 compare-and-append :512-515), memory.lisp:79 record-episode (:prev, :hv 2 hash over canon-sexp :102-109)
  - invariant: :V7I-OWN-single-writer (V1.7:337-340); journal.lisp:495 stale-chain-link ('STALE-CHAIN-LINK BEFORE anything is written')
  - fallback: copy-on-write
- **generic_function** — A `write-store`-shaped generic dispatched on the STORE designator with exactly one method per writable store (7 writable rows :writers 1; 3 read-only rows :writers 0 V1.7:334-336 → no method, i.e. the declared SEAT-NO-WRITER seats.sexp:99) — a second writer becomes a method redefinition, detectable like capability-seat-collision (capability-registry.lisp:72-81)
  - invariant: :V7I-OWN-single-writer 'exactly ONE write authority per store' (V1.7:338); define-unique STORE-OWNER-IS-ONE-SEAT (MODEL-SCHEMA.sexp:319)
  - fallback: single dispatch function — today's emit-graph (write-authority.lisp:16)
- **condition_restart** — Typed conditions replacing the untyped string errors at write-authority.lisp:33,36,40 (authority-missing / authority-not-allowed / authority-scope-violation) and journal's typed chain conditions (journal.lisp:215 sync-failure, :252 non-monotonic-transaction-time, :324 unserializable-record, :334 not-durable, :495 stale-chain-link); NO restart that performs the write
  - invariant: contract L24 'every error is a typed condition'; :V7I-OWN-single-writer
  - fallback: typed error value
- **macro_dsl** — `with-write-authority` (write-authority.lisp:53-73): a dynamic-scope macro binding *current-write-authority* (:12), nesting forbidden (:68-70) — admissible: expands at compile time only, never over external bytes
  - invariant: one write seat per dynamic extent; contract L25 'macros expand at compile time only'
  - fallback: explicit (let ((*current-write-authority* …)) …)
- **protocol** — The canonical write protocol = with-write-authority + emit-graph ('This is the ONLY authorized write function', write-authority.lisp:29-30) in package :orchestrator.write-authority (:4) — the seat SEAT-WRITE-AUTHORITY (seats.sexp:60-61) that the model already names as :writer of journal/legal-ir/memory (stores-and-authorities.sexp:8-10)
  - invariant: contract L33 'canonical writes only via write-authority.lisp'; :V7I-OWN-single-writer (V1.7:339 'the ONE canonical write seat is write-authority.lisp for the journal/memory/IR')
  - fallback: n/a (removing the seat removes canonical writes)
- **package_asdf_boundary** — :orchestrator.write-authority (write-authority.lisp:4) is the only package exporting a canonical write; owner packages :orchestrator.journal (journal.lisp:22), :orchestrator.memory (memory.lisp:27), :orchestrator.legal-ast (legal-ast.lisp:57) — an owner package acquiring a second write path is a forbidden package edge
  - invariant: :V7I-OWN-single-writer; contract L31
  - fallback: monolith
- **persistent_event** — journal store = chained-append (journal.lisp:507, atomic under thread+flock lock :508); memory store = record-episode (memory.lisp:79) — every canonical write is an appended, hash-linked event
  - invariant: RATCHET-2 (journal.lisp:512-515); RATCHET-3 (memory.lisp:102-104 'hash from the ONE canonical serialization seat')
  - fallback: full replay of the chain
- **temporal_index_projection** — The journal is the transaction-time axis of the bitemporal version graph (version-graph.lisp:7 [recorded-from,recorded-until)); journal.lisp:252 define-condition non-monotonic-transaction-time enforces monotone recorded time
  - invariant: monotone transaction time (journal.lisp:252); bitemporal separation (version-graph.lisp:7)
  - fallback: n/a
- **compile_time_validation** — store :owner/:writer are L3 refs to `seat` (MODEL-SCHEMA.sexp:155-158) + STORE-OWNER-IS-ONE-SEAT (:319) — already enforced for the byte-identical V1.8 rows (stores-and-authorities.sexp:5-14; N5 '10/10 identical'); the V1.7 class therefore imports ZERO facts; its DISPOSITION needs a ledger value that does not exist (migration-status = IMPORTED | DEFERRED_DATA_IMPORT | OUT_OF_MIGRATION_SCOPE, MODEL-SCHEMA.sexp:56 — no SUPERSEDED)
  - invariant: L2/L3; :V8I-03-one-seat (V1.8:20-22)
  - fallback: n/a
- **runtime_validation** — authority-scope check on every write (write-authority.lisp:32-41: required, in allowed set, equal to the dynamic scope)
  - invariant: :V7I-OWN-single-writer
  - fallback: fail-closed
- NOT-APPLICABLE: clos_class, truth_maintenance_dependency (reasons: evidence.na_reasons)
- **python_in_cl_risk** — LOW for the data (already canonical as 10 `store` facts with typed seats; V1.7 rows byte-identical to V1.8:286-295). The RISK is in the BUILT seat, not the import: the model knows 10 stores × typed owner/writer seats, but the CL write seat knows only two authorities {:canonical :provenance} (write-authority.lisp:35) with string errors (:33,:36,:40) — i.e. today's write-authority.lisp is shaped like an imperative validator ('if authority not in allowed: error'), not like a store-dispatched typed protocol. CL-native alternative: dispatch on the store id read from the model's store facts, one method per writer seat, typed conditions; :writers/:read-only fields (dropped on import, N15/ADJ-V18-WA-2) are then structurally encoded by method presence/absence.
- **future_freedom** — NO CONSTRAINT. S19: memory store's writer is write-authority (V1.7:328) — consistent with :V6I-05-memory-owned-by-lawmax (V1.6:32) and :V6I-14-memory-model-boundary (V1.6:297): no model can be a writer. S20: adapters have 'NO canonical write authority' (V1.6:29-31) — enforced by the single writer seat. No S04/JTMS/LLM constraint. Alias 'RA-S25'/'RA-S26' in :owner strings (V1.7:335-336) lies outside SUBSYSTEM-SPACE (MODEL-SCHEMA.sexp:42) — irrelevant after zero-fact import, but recorded (ADJ-V17-CAP-3).
- adjudication refs: ADJ-V17-WA-1, ADJ-V18-WA-2, ADJ-V18-WA-5, ADJ-V17-CAP-3, N5, N15, CL-DDI1-A1

###### V1.7-SCHEMAS__define-capability-seat

- **immutable_record** — A capability registration is an immutable struct after registration (capability-registry.lisp:40-48 defstruct capability, every slot :read-only t, :copier nil)
  - invariant: capability-seat-collision (capability-registry.lisp:72-81) 'one capability has ONE seat; no silent replacement of trust/fn/schema'; :V8I-03-one-seat
  - fallback: plain struct
- **condition_restart** — capability-seat-collision on a second registration of the same capability name (capability-registry.lisp:72-81); capability-error on invocation (:83-88); unknown param type ⇒ rejection at registration, fail-closed (:54-59) — no restart
  - invariant: :V7I-CAP-seat-closure (V1.7:353-356); :V8I-CAP-real (V1.8:250-254)
  - fallback: typed error value
- **macro_dsl** — `define-capability` (capability-registry.lisp:140-147) is 'the ONE declarative definition; HTTP/MCP/CLI are projections of it — never a separate hand-written definition per surface' (:142-143); `define-mcp-tool` (mcp-server.lisp:80) is such a projection surface — an RA capability is registered ONCE there, with :fn bound to the real symbol
  - invariant: one seat per capability (:142-143; :V8I-03); contract L25 seat 'capability-registry:define-capability'
  - fallback: hand-written register-capability call
- **protocol** — The capability invocation protocol (invoke-capability; trust classes :trusted | :advisor, capability-registry.lisp:46,158-159): RA capabilities are :trusted SYMBOLIC seats; any proposer-backed capability is :advisor and can never be a trusted seat
  - invariant: :V6I-10-proposer-never-authority (V1.6:75); :V6I-04 (V1.6:29-31)
  - fallback: direct function call
- **package_asdf_boundary** — :package must be a REAL defpackage and :symbol a real exported function: canonical-uris.lisp:12 defpackage :orchestrator.uris / :169 defun get-eli-law-prefix ✔; static-site.lisp:26 / :308 emit-corpus-site ✔; ai-citation-strategy.lisp:5 / :604 defmethod export-citation-metrics ✔; legal-decisions.lisp:569 defun decision-ratio ✔; V1.7:349 'orchestrator.corpus' / 'ai-corpus-dump' — NOT FOUND (the file's package is :orchestrator.ai-dump ai-corpus-dump.lisp:21; the function is emit-corpus-jsonl :92); V1.7:351-352 pseudo-packages 'usc.expression' / 'ra.license' for Markdown seats — NOT packages. Binding the seat as a function object at load ((fdefinition (find-symbol …))) makes every one of these errors a LOAD FAILURE instead of a string that survived until V1.8 corrected it
  - invariant: :V7I-CAP-seat-closure 'An arbitrary string is not a seat' (V1.7:354); contract L31
  - fallback: audit grep of source (today's V7S-CAP/V8-CAP)
- **compile_time_validation** — (package, symbol) resolvable at load (fboundp) — structurally rejects V1.7:349; :subsystem must be SUBSYSTEM-SPACE (V1.7:346,352 'RA-S25' violates the S-prefix rule MODEL-SCHEMA.sexp:42); :requirement/:test must be L3 refs to requirement/test facts — RA-I/RA-R/RA-K/RA-T/RA-J/RA-E/RA-L and RA-Q-* (except RA-Q-RESOLVE) are NOT model facts (requirements-tests-workpackets.sexp:5-50; orchestrator-notes.md N1)
  - invariant: :V7I-CAP-seat-closure; L3; L6
  - fallback: runtime grep
- **runtime_validation** — registration-time validation of params against the frozen +param-types+ (capability-registry.lisp:54-59: 'unknown type ⇒ REJECTION at registration (fail-closed), never silent acceptance')
  - invariant: fail-closed registration; :V8I-CAP-real
  - fallback: n/a
- NOT-APPLICABLE: clos_class, generic_function, persistent_event, truth_maintenance_dependency, temporal_index_projection (reasons: evidence.na_reasons)
- **python_in_cl_risk** — HIGH. Naive import yields a table of strings {capability: {file, package, symbol, subsystem, requirement, test}} verified by grep — which is literally today's audit (V8-CAP 'greps the real files', V1.8:254). Strings that name nothing survive (V1.7:349 is FALSE against the tree). CL-native alternative: a model `capability` fact with L3 refs (seat → `seat`, subsystem, requirement, test) as the DESIGN seat + a `define-capability` registration whose :fn IS the function object as the BUILT seat; the gate proves the two coincide. The V1.7 rows are superseded in all 7 by V1.8:243-249 (N5) and one is false — import ZERO facts from V1.7, adjudicate the class as superseded (no ledger value exists: ADJ-V17-WA-1 pattern).
- **future_freedom** — CONDITIONAL, mild. S20: capability-registry.lisp IS S20's seat (seats.sexp:58) and its :trusted/:advisor split keeps any proposer as advisor (V6I-10) — consistent with V8I-02. Constraint: binding a capability to a specific defun/defmethod name pins the symbol as public identity (a rename is a capability change); mitigated by pinning through the `seat` fact + exported symbol rather than a raw string. No S04/S19/JTMS/LLM constraint. Divergence: :JURIS_ANONYMIZE (V1.7:350) renamed :JURIS_RATIO (V1.8:247) with the same symbol decision-ratio while requirement RA-J text says 'typed anonymization receipt' (TRACEABILITY-MATRIX.md:351) — ADJ-V18-CAP-3.
- adjudication refs: ADJ-V17-CAP-1, ADJ-V17-CAP-2, ADJ-V17-CAP-3, ADJ-V17-CAP-4, ADJ-V18-CAP-3, N1, N5, CL-DDI1-A7

###### V1.8-SCHEMAS__define-capability-seat

- **immutable_record** — A capability registration is an immutable struct after registration (capability-registry.lisp:40-48 defstruct capability, every slot :read-only t, :copier nil)
  - invariant: capability-seat-collision (capability-registry.lisp:72-81) 'one capability has ONE seat; no silent replacement of trust/fn/schema'; :V8I-03-one-seat
  - fallback: plain struct
- **condition_restart** — capability-seat-collision on a second registration of the same capability name (capability-registry.lisp:72-81); capability-error on invocation (:83-88); unknown param type ⇒ rejection at registration, fail-closed (:54-59) — no restart
  - invariant: :V7I-CAP-seat-closure (V1.7:353-356); :V8I-CAP-real (V1.8:250-254)
  - fallback: typed error value
- **macro_dsl** — `define-capability` (capability-registry.lisp:140-147) is 'the ONE declarative definition; HTTP/MCP/CLI are projections of it — never a separate hand-written definition per surface' (:142-143); `define-mcp-tool` (mcp-server.lisp:80) is such a projection surface — an RA capability is registered ONCE there, with :fn bound to the real symbol
  - invariant: one seat per capability (:142-143; :V8I-03); contract L25 seat 'capability-registry:define-capability'
  - fallback: hand-written register-capability call
- **protocol** — The capability invocation protocol (invoke-capability; trust classes :trusted | :advisor, capability-registry.lisp:46,158-159): RA capabilities are :trusted SYMBOLIC seats; any proposer-backed capability is :advisor and can never be a trusted seat
  - invariant: :V6I-10-proposer-never-authority (V1.6:75); :V6I-04 (V1.6:29-31)
  - fallback: direct function call
- **package_asdf_boundary** — :CODE rows (V1.8:243-247) name real defpackage + symbol (all 5 verified: canonical-uris.lisp:12/169; static-site.lisp:26/308; ai-citation-strategy.lisp:5/604; ai-corpus-dump.lisp:21/92; legal-decisions.lisp:569) — bind as function objects at load; :DOCUMENT rows (V1.8:248-249 LAWMAX-LICENSE-POLICY.md §RightsMatrix/1; deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md §lawmax/expression/1) are not packages: they are `seat :status DOCUMENT_SEAT` facts (MODEL-SCHEMA.sexp:295-296) with a section anchor the gate must open+grep (cf. the unresolved RAT-PUBPRIV anchor, N17). Only 3 of 7 files coincide with an existing `seat` (SEAT-CANONICAL-URIS :62, SEAT-STATIC-SITE :48, SEAT-AI-CORPUS-DUMP :64); ai-citation-strategy.lisp / legal-decisions.lisp / the two documents would be SECOND seats of S15/S07/S25/S16 (ADJ-V18-CAP-2; SEAT-PATH-UNIQUE MODEL-SCHEMA.sexp:308)
  - invariant: :V8I-CAP-real (V1.8:250-254) 'NO pseudo-package is used for a Markdown/document seat'; contract L31
  - fallback: audit grep (today's V8-CAP)
- **compile_time_validation** — Load-time symbol resolution for :CODE rows; file+section existence for :DOCUMENT rows (gate opens the file); :requirement/:test as L3 refs — 6 of 7 requirement ids and 6 of 7 test ids are NOT model facts (N1; only RA-Q-RESOLVE requirements-tests-workpackets.sexp:44); L6 also needs a WP per capability (TRACEABILITY-MATRIX.md:347-353 supplies FUTURE_BOOK/WP-12/WP-09/WP-13/WP-11/WP-03 — FUTURE_BOOK is not a wp fact)
  - invariant: :V8I-CAP-real; L3; L6
  - fallback: runtime grep
- **runtime_validation** — registration-time validation of params against the frozen +param-types+ (capability-registry.lisp:54-59: 'unknown type ⇒ REJECTION at registration (fail-closed), never silent acceptance')
  - invariant: fail-closed registration; :V8I-CAP-real
  - fallback: n/a
- NOT-APPLICABLE: clos_class, generic_function, persistent_event, truth_maintenance_dependency, temporal_index_projection (reasons: evidence.na_reasons)
- **python_in_cl_risk** — HIGH — as V1.7, but V1.8 is the row set worth importing (every file/package/symbol/section verified against the tree by the dossier). Naive import: string table + grep audit (= V8-CAP). CL-native alternative: `capability` fact type (:seat L3→seat, :subsystem, :requirement, :test, :symbol STRING or :section STRING) + `define-capability` registration binding :fn for :CODE rows; :DOCUMENT rows cannot be functions and remain DOCUMENT_SEAT facts with an anchor-resolution check (one check shared with `rationale` anchors, N17). Prerequisites that are not CL questions: new `seat` facts (4) and the requirement/test universe (N1).
- **future_freedom** — CONDITIONAL, mild — as V1.7 (symbol pinning). Additionally: S20's registry (capability-registry.lisp) carries :name/:params/:result/:trust/:proof/:fn but NO :subsystem/:requirement/:test (:40-48) while the model has NO capability fact type — two half-seats; the CL-native resolution keeps the model fact as design seat and the registration as built seat (one concept, two roles proven equal by the gate), never a third table. No S04/S19/JTMS/LLM constraint; :trusted RA capabilities are symbolic (V8I-02).
- adjudication refs: ADJ-V18-CAP-1, ADJ-V18-CAP-2, ADJ-V18-CAP-3, N1, N17, CL-DDI1-A7

###### V1.8-SCHEMAS__define-canonical-identity

- **immutable_record** — The 8 identity strings (lawmax/legal-ir/1 … lawmax/rights-matrix/1, V1.8:425-432) name HASH-BEARING immutable types (V1.6:344-345 public-build :hash-bearing; V1.8 public roots :260-261); the identity of an INSTANCE is its content-address computed over ONE canonical serialization (journal.lisp:61-68 canon-sexp 'function of the VALUE, never of the representation'; AMC2 CANONICAL-ENCODING.md:1-3 for model facts), the identity of the TYPE is a plain string datum carried once on the `type` fact
  - invariant: contract L27 'identity = content-address; lifecycle detached (v1.5 R2)'; :V5I-A2-immutable-id (V1.5:554); :V8I-XREF-identity (V1.8:433-441)
  - fallback: keep prior version (additive fields, re-hash new version)
- **condition_restart** — The five failure kinds enumerated in :V8I-XREF-identity (wrong-file, wrong-identity, wrong-version, locator-absent-from-canonical-file, wrong-reference-target, V1.8:440-441) are typed conditions raised by the gate; a type without identity is HARD_PRE_FREEZE_BLOCKER (V1.8:439) — no restart, 'never a fabricated identity and never a silent pass'
  - invariant: :V8I-XREF-identity (V1.8:433-441)
  - fallback: typed error value
- **package_asdf_boundary** — Identity strings are plain data shared with compiler B (Rust) — NEVER CL symbols, packages or class names (a CL symbol as identity would leak the CL mechanism into the IR contract); the structural anchors point at 3 kinds of seat: documents (V1.8:345-346), CL source (V1.8:347 source/memory.lisp locator 'record-episode' = memory.lisp:79) and 5 migration-source .sexp files (V1.8:348-352 → V1.6/V1.7-SCHEMAS.sexp) whose role is CANONICAL_MODEL_INPUT (files-and-roles per dossier) — after DDI those anchors must move to the model or go stale (ADJ-V18-CI-3)
  - invariant: contract §1 language-independence (L10-15); :V6I-REF-single-source-of-truth (V1.6:158-162)
  - fallback: n/a
- **persistent_event** — MemoryEvent/1's identity is anchored at memory.lisp record-episode (V1.8:347 locator; memory.lisp:79) whose records are hash-chained events (:prev, :hv 2 over canon-sexp :102-109) — identity and event chain share the ONE serialization seat
  - invariant: RATCHET-3 (memory.lisp:102-104); contract L34 'one canonical serialization boundary'
  - fallback: full replay
- **temporal_index_projection** — :version "1" (V1.8:425-432) is a type-schema version, not valid time: a new version is a new identity string (lawmax/x/2) with the prior kept — versions are additive, never in-place (contract L27 migration 'additive fields, re-hash new version'; rollback 'keep prior version')
  - invariant: :V5I-A2-immutable-id (V1.5:554); :V6I-REF (V1.6:158-162)
  - fallback: keep prior version
- **compile_time_validation** — The two-part resolution (part A identity+version inside the named define-reference block; part B open :canonical-file and grep :locator, V1.8:434-437) is a GATE CHECK that computes the verdict — the same anchor-resolution the model lacks for `rationale` facts (N17: RAT-PUBPRIV :anchor occurs 0 times in deployment/LAWMAX-THREAT-MODEL.md) → ONE anchor-resolution check for define-reference, rationale and DOCUMENT capability seats; the verdict is never stored (verification-corpus doctrine: MODEL-SCHEMA.sexp:217-220 stores :expect, not results)
  - invariant: :V8I-XREF-identity; :V8I-XREF-real (V1.8:353)
  - fallback: runtime check
- **runtime_validation** — Canonical serialization of an instance is total over the permitted value domain and fails closed otherwise (journal.lisp:65-66 'Anything else ⇒ ERROR (fail-closed)'); dual-compiler root equality is the test (contract L34)
  - invariant: contract L34 'byte-identical roots'
  - fallback: explicit encoder
- NOT-APPLICABLE: clos_class, generic_function, macro_dsl, protocol, truth_maintenance_dependency (reasons: evidence.na_reasons)
- **python_in_cl_risk** — HIGH. Naive import yields a dict {type: {identity, version, status:'VERIFIED', verify_file, type_locator}} — carrying (a) a SELF-REPORTED VERDICT as data (:status VERIFIED, V1.8:425-432) which the model's doctrine forbids (verdicts are computed by two independent paths, never stored; MODEL-SCHEMA.sexp:217-220 fixture :expect), (b) a SELF-REFERENTIAL pointer (:verify-file = V1.8-SCHEMAS.sexp itself), and (c) a DUPLICATE of :identity/:version already inside the define-reference block it names (V1.8:345-352; V1.8:421-422 'the reference is the identity seat'). CL-native alternative: `type` gains optional :identity STRING / :version STRING (one seat, L2), the verdict is a gate check, :verify-file/:type-locator/:status are dropped — the class imports ZERO facts of its own if define-reference (DDI-2) becomes the identity seat (ADJ-V18-CI-1). Instance identity = hash over canon-sexp; type identity = string.
- **future_freedom** — CONDITIONAL. S19: MemoryEvent/1's anchor is a CL function name (memory.lisp:79 record-episode) — acceptable as EVIDENCE (BUILT seat) but the identity string must remain the contract so compiler B and any future memory implementation can conform without that symbol; if the locator became the identity, S19 would be frozen to one Lisp function. S04: LegalIR/1 → LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md 'Counterproof' (V1.8:345) is a document anchor — language-independent, no constraint. Identity universe: only 8 of 60 types carry an identity; public roots CanonicalRetrievalView/1, CitationMetricV8/1, RootAuthorityStatus/1 and all 19 new V1.8 records have none while V1.8:422-424 calls that a HARD_PRE_FREEZE_BLOCKER (ADJ-V18-CI-4) — future types must obtain identities through the one seat, never through a second table. No JTMS/S20/LLM constraint. MOP explicitly NOT requested: a metaclass carrying identity would be MOP without a named invariant (contract L23, §3).
- adjudication refs: ADJ-V18-CI-1, ADJ-V18-CI-2, ADJ-V18-CI-3, ADJ-V18-CI-4, V1.6-A1 (record-vs-reference doctrine), N17, CL-DDI1-A10

###### V1.8-SCHEMAS__define-ra-delta-seats

- **condition_restart** — L6 closure failure (a requirement with zero or multiple seats / no test / no WP) is a kernel-law violation → typed; no restart
  - invariant: L6 requirement→seat→test→WP (MODEL-SCHEMA.sexp:176-181); :V8I-RA-DELTA-seats 'Zero or multiple seats for any delta ⇒ failure' (V1.8:455-458)
  - fallback: typed error value
- **package_asdf_boundary** — A delta's home is the PACKAGE/SEAT of its owner subsystem, not a type: RA-EPOCH/RA-JUR-NS/RA-MARK → S25 SEAT-CANONICAL-URIS (seats.sexp:62; :orchestrator.uris canonical-uris.lisp:12); RA-K → S15 SEAT-CITATION-AUTHORITY (seats.sexp:52); RA-CORR → S18 SEAT-BOUNDARY-SHAPES DOCUMENT_SEAT (seats.sexp:73); RA-CONT → S11 SEAT-SECURITY-CELLS DESIGN_TARGET (seats.sexp:79, no path allowed MODEL-SCHEMA.sexp:297-298); RA-SIDE → S26 SEAT-TENANT-PROFILE INTERFACE_ONLY (seats.sexp:97) — i.e. RA-SIDE has NO public package by construction (its seat type SidecarSourceProfile/1 is PRIVATE interfaces-and-types.sexp:58)
  - invariant: L5 (public/private isolation); :V8I-PUBPRIV-all-families; seats.sexp:15-19 (design targets/interface-only never dressed as files)
  - fallback: monolith
- **persistent_event** — RA-CORR's seat PublicCorrectionEvent/1 (V1.8:447) is an EVENT record: appended and hash-chained (journal.lisp:507 chained-append), carrying no re-published content (deployment/LAWMAX-THREAT-MODEL.md:101-102 'no re-published content and no PII')
  - invariant: :V8I-CORR-privacy (V1.8:168)
  - fallback: full replay
- **truth_maintenance_dependency** — RA-CORR: a public correction RETRACTS a previously published belief and every conclusion that depended on it — JTMS retraction (legal-inference-engine.lisp:395 tms-retract-premise; :347 recompute-beliefs, well-founded) rather than an ad-hoc republish
  - invariant: contract L28 'belief revision is monotone-audited'; :V8I-CORR-privacy
  - fallback: full recompute
- **temporal_index_projection** — RA-EPOCH (CanonicalCitationURI/1 + MultiCommitment/1 + ReAnchoringManifest/1, V1.8:445; TRACEABILITY-MATRIX.md:391) is an EPOCH-indexed identity: any cached derivation over a citation names its epoch and is invalidated on re-anchoring (contract L30 'a cache entry names its validation epoch; epoch change invalidates') — the contract's epoch seat (shacl-validator.lisp / mltp3:ontology-bundle) is NOT FOUND by grep ('epoch' 0 hits in shacl-validator.lisp; 'ontology-bundle' 0 hits in source/)
  - invariant: :V8I-EPOCH-one-expression (V1.8:128)
  - fallback: no cache
- **compile_time_validation** — L6 closure at kernel-law time requires facts that do not exist: 7 `requirement` (RA8-*) + 7 `test` (T8-*) — none in requirements-tests-workpackets.sexp:5-50 (N1) — and a `wp` per row, absent from the form (V1.8:445-451 has no :wp; TRACEABILITY-MATRIX.md:391-397 supplies FUTURE_BOOK×3 / WP-06 / WP-12 / WP-13 / DEFERRED, and FUTURE_BOOK is not a `wp` fact: only FUTURE_BOOK_REVISION requirements-tests-workpackets.sexp:53); also :seat is a TYPE while req-map :seat is a `seat` (MODEL-SCHEMA.sexp:178-181) — a type-seat notion or a mapping to the owner seat is a schema decision (ADJ-V18-DELTA-2)
  - invariant: L6; :V8I-RA-DELTA-seats
  - fallback: n/a — cannot close today
- NOT-APPLICABLE: immutable_record, clos_class, generic_function, macro_dsl, protocol, runtime_validation (reasons: evidence.na_reasons)
- **python_in_cl_risk** — MEDIUM. Naive import yields 7 dict rows from an anonymous nested form (N11: id must be synthesised) with :seat kept as a string because it is a type, not an artifact seat. CL-native alternative: pure traceability facts — either req-map rows (:seat = owner subsystem's `seat`, plus a new optional :type L3 ref) or a `delta` fact type (:seat-type→type :owner→subsystem :requirement :test :wp) — nothing imperative; the only 'code' is the kernel's L6 closure. The tempting shortcut (a string :seat 'CanonicalCitationURI/1') is exactly the 'arbitrary string is not a seat' error (V1.7:354).
- **future_freedom** — CONDITIONAL. RA-SIDE is seated in a PRIVATE type owned by PRIVATE S26 with TRACEABILITY wp 'DEFERRED' (V1.8:451; TRACEABILITY-MATRIX.md:396) — a root-authority delta of the PUBLIC candidate whose one canonical seat lies outside the public build (ADJ-V18-DELTA-5); in package terms it has no public package, so the public build cannot even name it without a declassification edge. RA-CORR/RA-EPOCH pull in JTMS retraction and epoch invalidation — these are freedoms the contract already reserves (L28, L30), not constraints. Seven-vs-eight (RA8-FROST, TRACEABILITY-MATRIX.md:398 vs :V8I-RA-DELTA-seats) and RA-JUR-NS own-seat vs 'typed dimension of CanonicalCitationURI/1' (ADJ-V18-DELTA-3/4) are adjudications, not CL questions. No S04/S19/S20/LLM constraint.
- adjudication refs: ADJ-V18-DELTA-1, ADJ-V18-DELTA-2, ADJ-V18-DELTA-3, ADJ-V18-DELTA-4, ADJ-V18-DELTA-5, ADJ-V18-DELTA-6, ADJ-V18-INV-4, N1, N11, CL-DDI1-A4

##### 4. Cross-cutting findings (the contract's own seat citations vs the tree)

- F1 — Contract row 'condition/restart' (L24) seats 'cognition clarification (COG7-11)'; the registries seat it in 'legal-dialectic.lisp + condition/restart' (V1.6:227; V1.7:91). `source/legal-dialectic.lisp` contains no `define-condition`/`restart-case`/`handler-*` (grep; only `defpackage :orchestrator.dialectic` :14). The pattern exists elsewhere (legal-ast.lisp:1604-1615; trace-core.lisp:264-277; greek-tokenizer-advanced.lisp:434). ⇒ a [design-target] under contract L8, not a built seat.
- F2 — Contract row 'compile-time validation' (L32) seats 'constitutional-gate.lisp + compile-time schema'. `source/constitutional-gate.lisp` has 0 `eval-when` and 0 `defmacro`; it is a RUNTIME plist-rule evaluator (:22-47) whose rule errors FAIL OPEN (:45). The real 'fail at build' seat for model facts is `ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp` (L1/L2 at :119-166, read with *read-eval* nil :56). For DDI-1 data 'compile-time' therefore means kernel-law time (build gate), and the fail-open at constitutional-gate.lisp:45 is a doctrinal tension with 'fail-closed' (V1.7:321; safe-read.lisp:66) — reported, not resolved.
- F3 — Contract row 'memoization with epoch invalidation' (L30) seats 'shacl-validator.lisp + mltp3:ontology-bundle': `epoch` occurs 0 times in source/shacl-validator.lisp and `ontology-bundle` 0 times in source/ (grep). RA-EPOCH (define-ra-delta-seats V1.8:445) needs a real epoch seat — NOT FOUND today.
- F4 — Contract row 'no read/eval over external input' (L35) seats 'ingress-decoder.lisp (non-evaluating)': no such file in source/ (find; only deployment/LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md). The proposer-optional nodes of define-pipeline (V1.7:313) and V6I-04 (V1.6:31) depend on it. `source/safe-read.lisp` is the built non-evaluating reader (:152-165, :169 %data-only-p).
- F5 — Contract L20 cites `cognition.lisp:46 working-memory`; the class is at cognition.lisp:42 (4-line drift; the contract's commit pin is unknown). Other cited seats verified exactly: cognition.lisp:107 triage; legal-inference-engine.lisp:238 make-jtms; knowledge-graph.lisp:116; legal-decisions.lisp:71; greek-legislation-ontology.lisp:57 defconcept; journal.lisp canon-sexp :61 / chained-append :507.
- F6 — write-authority seat vs model: the model has 10 `store` facts with typed owner/writer seats (stores-and-authorities.sexp:5-14) while `write-authority.lisp:35` knows exactly two authorities {:canonical :provenance} and raises untyped string errors (:33,:36,:40). The built seat is shaped like an imperative validator, not a store-dispatched typed protocol (contract L21/L24). Data import risk LOW; seat-alignment gap HIGH.
- F7 — The single class-level SCC of the six registries (dag-fragment.md:92-112) closes through define-canonical-identity ↔ define-reference; in CL-native terms the identity string must live ONCE on the `type` fact (V1.8:421-422 already names define-reference the identity seat) — importing define-canonical-identity as facts would import a stored verdict (:status VERIFIED) and a self-reference (:verify-file = V1.8-SCHEMAS.sexp), both inadmissible (MODEL-SCHEMA.sexp:217-220 stores :expect only).
- F8 — Public/private boundary: contract L31 ('package boundary = capability boundary') is the STRUCTURAL form of L5; roots/forbidden lists (V1.7:290-296; V1.8:259-265) are derivable from `type :classification` (MODEL-SCHEMA.sexp:47; interfaces-and-types.sexp:5-64) and V1.8:266-283 itself forbids manual restatement as proof (VR-01). PrivateMemoryEvent/1 (V1.6:312) is not a model type (N9) — L3 closure impossible for a verbatim import. The boundary's own rationale anchor is unresolved (N17: RAT-PUBPRIV anchor 0 hits in deployment/LAWMAX-THREAT-MODEL.md).
- F9 — Capability seats: the built seat `capability-registry.lisp` (S20, seats.sexp:58) has :name/:params/:result/:trust/:proof/:fn (:40-48) but no :subsystem/:requirement/:test; the model has no `capability` fact type; requirement ids RA-*/RA8-* and tests RA-Q-*/T8-* are not model facts (N1; requirements-tests-workpackets.sexp:5-50). A CL-native binding (function object at load) would have rejected V1.7:349 (`orchestrator.corpus`/`ai-corpus-dump` do not exist; ai-corpus-dump.lisp:21 `:orchestrator.ai-dump`, :92 `emit-corpus-jsonl`) at load time — evidence that string seats are the error class to eliminate.
- F10 — Three cognition DAG seats (V1.6:217, V1.7:80, V1.8:53/363) in two batches (DDI-1 vs DDI-3); V1.8:24-27 says the linear list is REPLACED. Importing V1.6/V1.7 construction orders as canonical facts in DDI-1 freezes superseded S04 topology before the DDI-3 typed graph exists.

##### 5. Adjudication items

New (raised by this map; each cites both sides):

- CL-DDI1-A1 — Store→writer table seat: model `store` facts (10, typed seats; stores-and-authorities.sexp:5-14; STORE-OWNER-IS-ONE-SEAT MODEL-SCHEMA.sexp:319) vs the built write seat write-authority.lisp:35 (two authorities, string errors :33,36,40). Which is the seat of the writer table, and is a store-dispatched generic with typed conditions the mandated shape (contract L21/L24, V7I-OWN-single-writer V1.7:337-340)?
- CL-DDI1-A2 — Clarification condition/restart seat: registries name 'legal-dialectic.lisp + condition/restart' (V1.6:227; V1.7:91); contract L24 names 'cognition clarification (COG7-11)'; legal-dialectic.lisp has none (grep). Declare [design-target] (contract L8) with packet, or re-seat to legal-ast.lisp:1604 pattern?
- CL-DDI1-A3 — 'Compile-time validation' seat: contract L32 names constitutional-gate.lisp (runtime, fail-open :45) vs the kernel-law reader model-law-kernel.lisp:119-166 (build gate, fail-closed). Which seat owns 'fail at build' for imported DDI facts, and is constitutional-gate.lisp:45 fail-open admissible under the fail-closed doctrine (V1.7:321; safe-read.lisp:66)?
- CL-DDI1-A4 — Epoch seat: contract L30 names shacl-validator.lisp + mltp3:ontology-bundle (NOT FOUND by grep); RA-EPOCH (V1.8:445; V8I-EPOCH-one-expression V1.8:128) requires one. Where is the epoch seat?
- CL-DDI1-A5 — Ingress decoder seat: contract L35 + V1.6:31 name ingress-decoder.lisp (NOT FOUND in source/; only deployment/LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md); safe-read.lisp:152-169 is the built non-evaluating reader. Is safe-read.lisp the seat, or is the decoder a [design-target]?
- CL-DDI1-A6 — define-construction-order (V1.5:597): import an AUTHORED order (second seat of the ref graph; V6I-REF V1.6:158-162 / V8I-03 V1.8:20-22 reject duplicates) or DERIVE the order from typed ref facts (define-ref-classification V1.5:569, DDI-2) with the list as a `fixture :expect` (MODEL-SCHEMA.sexp:217-220; VR-01 doctrine V1.8:266)? Extends V5-A10 (grammar clash with V1.6/V1.7 same-head forms).
- CL-DDI1-A7 — Capability seats: design seat = new model `capability` fact (L3 refs) vs built seat = `define-capability` registration with :fn bound (capability-registry.lisp:140-147, :40-48 lacks subsystem/requirement/test). One concept, two roles proven equal by the gate — or one of them only? Extends ADJ-V18-CAP-1/2, N1.
- CL-DDI1-A8 — Contract citation drift: cognition.lisp:46 (contract L20) vs :42 (tree). Is the contract pinned to an earlier commit (parent f05f5514 per contract L3), and must its seat citations be re-verified before DDI-1?
- CL-DDI1-A9 — ra-closure-roots (V1.7:290; V1.8:259): import zero authored root/forbidden facts (derive from `type :classification`) + enforce the boundary as ASDF forbidden dependencies (contract L31; [0146]:18) vs import the lists as facts (which V1.8:283 forbids as proof). Extends ADJ-V17-ROOTS-1, ADJ-V18-ROOTS-3, N9.
- CL-DDI1-A10 — canonical-identity: `type` gains :identity/:version (one seat; define-reference V1.8:345-352 as source) with the VERIFIED verdict COMPUTED by one anchor-resolution check shared with `rationale` anchors (N17) — vs importing the 8 rows with :status/:verify-file. Extends ADJ-V18-CI-1/2/3.

Existing items relied upon (dossiers / orchestrator-notes): V5-A7, V5-A9, V5-A10, V5-A15; V1.6 A1, A8, A13; ADJ-V17-CO-1, CO-2, ROOTS-1, ROOTS-2, PIPE-1, PIPE-2, WA-1, CAP-1, CAP-2, CAP-3, CAP-4; ADJ-V18-CAP-1, CAP-2, CAP-3, ROOTS-1, ROOTS-2, ROOTS-3, PIPE-1, PIPE-3, WA-2, WA-5, CI-1, CI-2, CI-3, CI-4, DELTA-1..6, INV-4, COG-1, NT-4; orchestrator-notes N1, N4, N5, N9, N11, N15, N17.

##### 6. UNKNOWN / NOT FOUND

- Whether the future kernel-law seat for imported DDI facts is the existing CL kernel (KERNEL/model-law-kernel.lisp) or a new CL-native schema module — not decided in the repository.
- Whether the V1.6 / V1.7 construction orders import at all (lineage-only) or only cognition-graph-v8 (DDI-3) — pending ADJ-V17-CO-1 / ADJ-V18-COG-1.
- Type seats for `legal_state_root` and `proof_bundle` (V1.7:316) — NOT FOUND in any .sexp registry (dossier grep).
- Owner of PrivateMemoryEvent/1 (V1.6:312; not a model type) — N9.
- `ingress-decoder.lisp` — NOT FOUND in source/ (F4). `shacl-validator.lisp` epoch / `mltp3:ontology-bundle` — NOT FOUND (F3).
- The commit the contract's seat citations were taken from (cognition.lisp:46 vs :42) — UNKNOWN.
- Canonical seat of the RA-*/RA8-*/T8-* requirement/test universe (only TRACEABILITY-MATRIX.md, AUTHORED_NORMATIVE_PROSE) — N1.
- Whether any of the 16 ASDF systems today declares a FORBIDDEN dependency (the contract L31 mechanism) — I verified the system count (ls) and the [0146]:18 claim only; the 53-edge graph itself was not re-derived here — UNKNOWN.
- Whether `restart-case` at greek-tokenizer-advanced.lisp:434 is on the cognition path (COG-2/COG7-03 seat) or a legacy tokenizer path — not examined.


### DDI-2

#### cl-DDI-2 — Common-Lisp-native usage map for batch DDI-2 (18 classes / 156 forms)

Read-only reconnaissance. RO = clone at HEAD 4ee2b58a (tree ad71185a). No production code was written; no RO file was touched.
Machine-readable twin: `cl-map.json` (JSON array, one object per class, keys `class_id` + 12 dimensions + `python_in_cl_risk` + `future_freedom` + `mop_requested` + `evidence`). Counts: `counts.json`.

Normative contract used: `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md` (v1.7 CANDIDATE, added in 04cca6ed [0153]; role AUTHORED_NORMATIVE_PROSE, `ARCHITECTURE-MODEL/files-and-roles.sexp:403`). Its §2 rows (contract:20-35) supply the `reason/seat/requirement/invariant/test/fallback/migration/rollback` tuple; every dimension value below names only the mechanism, the invariant that requires it and the fallback — the remaining five fields are the contract row's own unless stated. MOP: forbidden without a named invariant (contract:23, :40-41) — **no DDI-2 class requests MOP** (`mop_requested` = 0/18).

Batch membership (AM/build_deferred.py:91-95; ledger AM/deferred-imports.sexp rows 15,16,20,25,26,30,31,34,36,37,38,42,48,49,56,57,66,67): 16+18+1+1+1+8+2+22+6+1+1+8+8+25+9+19+9+1 = 156 forms — matches WORK/classes.md and the census.

##### Method
Every DDI-2 form was read in RO (V1.5:13-594, V1.6:20-347, V1.7:34-258, V1.8:28-454); each named CL seat was grepped/read in `RO/source` (`defgeneric`/`defclass`/`defstruct`/`define-condition`/`deftype`/`defmacro`/`restart-case`/`sb-mop`/`closer-mop` sweeps + targeted reads); the model side was read in `AM/MODEL-SCHEMA.sexp`, `AM/KERNEL/model-law-kernel.lisp`, `AM/seats.sexp`, `AM/stores-and-authorities.sexp`, `AM/verification-corpus.sexp`, `AM/CANONICAL-ENCODING.md`; the six dossiers' DDI-2 class blocks and adjudication items were read (WORK/agents/dossier-*/dossier.json) and are cross-referenced, never re-decided.

Two layers are distinguished throughout: (M) the **model layer** — every DDI-2 form first lands as flat `(fact ...)` data read by the CL kernel with `*read-eval*` nil (`AM/interfaces-and-types.sexp:3`; `model-law-kernel.lisp:1-3, :56-60`), so macros/CLOS never touch the registry forms; (P) the **production layer** — `source/*.lisp` seats that will consume the same declarations (deftype member types, immutable structs/classes, typed decoders, JTMS, bitemporal graph, journal chain).

##### The 18 classes — condensed (full text in cl-map.json)

| # | class_id (ledger row) | forms | dominant CL-native mechanisms (seat) | risk | freedom |
|---|---|---|---|---|---|
| 1 | V1.5-SCHEMAS__define-closed-enum (:16) | 16 | deftype member type per enum (`version-graph.lisp:148-149`) + closed constant list checked by `ecase` (`capability-registry.lisp:59,:169`); per-value attributes as flat facts; out-of-domain ⇒ typed condition (fail-closed V1.5:148-154) | HIGH | NO |
| 2 | V1.5-SCHEMAS__define-record (:25) | 18 | content-address via `journal.lisp:61 canon-sexp` (as `memory.lisp:96-110`); immutable struct/CLOS; typed decoder pattern `legal-ast.lisp:1704-1717`; C1 records = JTMS justifications/defeaters (`legal-inference-engine.lisp:199-204, :238, :385`); LifecycleRecord chain via `journal.lisp:507 chained-append`; validity intervals via `legal-temporal.lisp:22` / `version-graph.lisp:1030` | HIGH | NO (conditional: no second reasoning seat) |
| 3 | V1.5-SCHEMAS__define-cardinality-matrix (:15) | 1 | DATA only: one fact per cell, one generic conditional evaluator (`MODEL-SCHEMA.sexp:26-30 define-conditional`; kernel `*conds*`) | HIGH | NO |
| 4 | V1.5-SCHEMAS__define-frozen-enum-reference (:20) | 1 | enum fact frozen=YES + (doc, anchor) with a resolver (today anchors are unresolved: N17) | LOW | NO |
| 5 | V1.5-SCHEMAS__define-ref-classification (:26) | 1 | typed edge facts (record.field → kind → target) feeding canon-sexp hash membership + kernel L3/L4 acyclicity | MEDIUM | NO |
| 6 | V1.6-SCHEMAS__define-closed-enum (:31) | 8 | deftypes in OWNER packages; private-bearing MemoryType/MemoryScope as UNION extension types in the private package (V6I-16/V6I-MEM-clean); CognitionError = condition-class names | MEDIUM | **YES** (S19/S04 duplicate taxonomies) |
| 7 | V1.6-SCHEMAS__define-adapter-contract (:30) | 2 | capability struct with `:trust :advisor` (`capability-registry.lisp:40-47, :140`), collision-guarded (:72); methods on SemanticProposer generics; out-of-process, no ASDF edge; ingress decoder NOT BUILT | MEDIUM | **YES** (technology names as canonical ids; make `:mandatory YES` structurally impossible) |
| 8 | V1.6-SCHEMAS__define-record (:36) | 22 | cognition records as classes specialising stage generics (`cognition.lisp:92-113`, `greek-nlp-core.lisp:394`); MemoryEvent/1 as typed VIEW over the journal plist (`memory.lisp:53-61`), not a second object; private records in a system no public system depends on | HIGH | **YES** (S04/S19 duplicates; write-authority gap CL2-A11) |
| 9 | V1.6-SCHEMAS__define-reference (:38) | 6 | canonical-identity fact with L3 `seat` ref (one family with V1.8 define-canonical-identity); code seats resolved by find-symbol, not grep | MEDIUM | NO |
| 10 | V1.6-SCHEMAS__define-mapping (:34) | 1 | capability → `seat` ref (+ disposition enum) = V1.8 capability-seat shape; runtime binding via analyzer registry (`greek-nlp-core.lisp:397-407`) | HIGH | **YES** (binds meanings to file names, V6I-01) |
| 11 | V1.6-SCHEMAS__define-ref-classification-v6 (:37) | 1 | closure-root facts (shared with DDI-1 ra-closure-roots) or retire; the 3 families = the ASDF partition twin of L5 | MEDIUM | NO (if superseded) |
| 12 | V1.7-SCHEMAS__define-reference (:49) | 8 | one canonical-identity fact per type; section-string pointers into migration sources retired | MEDIUM | NO |
| 13 | V1.7-SCHEMAS__define-closed-enum (:42) | 8 | deftypes; CognitionErrorV7 as conditions; RetrievalFormat keys the representation protocol (`corpus-service.lisp:44-70`) | LOW | **YES** (duplicates with V1.6 for S04/S19) |
| 14 | V1.7-SCHEMAS__define-record (:48) | 25 | cognition intermediates as stage-generic specialisers; resolver records EXTEND `canonical-uris.lisp`; no-forced-winner = JTMS `:undefined`; temporal fields on the ONE bitemporal seat; singleton `(member :false)` fields = constants, not flags | HIGH | **YES** (ClarifiedInterpretation double seat; 11 ownerless records; second memory-policy seat) |
| 15 | V1.8-SCHEMAS__define-closed-enum (:57) | 9 | deftypes; ClarificationLifecycleState backs a PERSISTED state machine (restarts are dynamic-extent) | LOW | NO |
| 16 | V1.8-SCHEMAS__define-record (:66) | 19 | RelianceProjection as dependency-directed derivation (never stored scalar); CanonicalCitationURI temporal resolution = `version-at` discipline; tombstones bound by `%payload-hash` chaining (`version-graph.lisp:498-506`); MultiCommitment needs a ≥2-family commitment seat (UNKNOWN) | HIGH | **YES** (double seat; private-in-public package split; persisted clarification store absent) |
| 17 | V1.8-SCHEMAS__define-reference (:67) | 9 | :CODE locator = package-qualified exported symbol (`memory.lisp:24-27 record-episode`) verified structurally; document locators = DOCUMENT_SEAT anchors | MEDIUM | NO |
| 18 | V1.8-SCHEMAS__define-cardinality-table (:56) | 1 | DATA only (field-rule facts, typed column→field refs); ONE generic conditional evaluator; the imperative twin already exists in `V1.8-VERIFY.py:1050-1075` and must not be ported | HIGH | NO |

Totals: 216 dimension values = 111 mechanisms + 105 NOT-APPLICABLE; python_in_cl_risks (HIGH+MEDIUM) = 15/18; future-freedom flags = 7/18; MOP requested = 0/18.

##### Cross-cutting findings (evidence-based, not decided here)

**F1 — Field-type vocabulary must be decomposed, never stringified.** Every record class carries `(list X)`, `(or X null)`, `(member ...)` type expressions. The model's L1 forbids nested lists and keywords (`MODEL-SCHEMA.sexp:4-7`); storing the expression as a STRING and re-parsing it is the regex anti-pattern the kernel forbids (`model-law-kernel.lisp:9`) and that the legacy audit already practises (`V1.6-CONTRADICTION-OMISSION-AUDIT.sh:151-152`). CL-native: typed closed fields `:domain <type|enum id> :cardinality ONE|LIST :nullable YES|NO`; inline member sets → named enums (precedent: V1.8:31 MergeSemanticsV8 promotes V1.7:78).

**F2 — canon-sexp bounds the primitives.** `journal.lisp:61-66` admits NIL/keyword/string/integer/list only; every hash-bearing DDI-2 body must render into that domain. The 17 primitive tokens (id, usc-id, ref, sha256, sig, kid, pubkey, scope, instant, duration, semver, text, anchor, keyword, quorum-spec, uncertainty, requirement — V5-A8/ADJ-V17-REC-5/A20) need a CL type binding each; `instant` binds naturally to `version-graph.lisp:149 legal-instant`; `duration`, `uncertainty` (`lawmax/uncertainty/1`), `quorum-spec` have 0 occurrences in `source/*.lisp` (grep) — UNKNOWN seats.

**F3 — Restarts are dynamic-extent; clarification is not.** V1.6:227/V1.7:91 seat the clarification branch at "legal-dialectic.lisp + condition/restart"; `legal-dialectic.lisp` has no condition/restart (restart-case exists only at `greek-tokenizer-advanced.lisp:434`, `legal-ast.lisp:1604`, `trace-core.lisp:264`), and V1.8's SUSPEND→RESUME with `:expiry` (V1.8:28-39, :60-61) crosses invocations. The CL-native shape is: typed conditions + restarts inside one invocation, PERSISTED ClarificationRequest/Response events across invocations — and no `store` fact exists for that state (`AM/stores-and-authorities.sexp:5-14`).

**F4 — Cardinality rules are data, in both dialects.** `MODEL-SCHEMA.sexp:26-30` states the principle ("kept as DATA so both paths enforce one specification rather than two hand-written implementations"); the kernel already evaluates such rules generically (`*conds*`). Neither V1.5's matrix nor V1.8's table should become a macro or an imperative validator.

**F5 — Enum = deftype + closed list + ecase, in the owner's package.** The repo idiom is `deftype` (`version-graph.lisp:148-149`) and closed constant lists with structural `ecase` (`capability-registry.lisp:59, :169`; `legal-deontic.lisp:61 +modalities+`; `version-graph.lisp:239 +supported-ops+`); only one `(member ...)` slot type exists (`circuit-breaker.lisp:49`). Private-bearing enums (V1.6:284-288) must be union EXTENSIONS in the private package, never members of the public type (V6I-16, V6I-MEM-public-base-clean).

**F6 — Records that are events go through ONE writer.** `journal.lisp:507 chained-append` is the atomic seat; `memory.lisp:96` and `version-graph.lisp:546` use it. But `write-authority.lisp:4-8` exports only `emit-graph`/`with-write-authority` (RDF graphs, `:16-49`), while the model names SEAT-WRITE-AUTHORITY as writer of the memory/journal/legal-ir stores (`AM/stores-and-authorities.sexp:8-10`) and V6I-05/V6I-14 require canonical memory writes ONLY by the write authority — see CL2-A11.

**F7 — Contract seat drift (minor, but the contract is normative).** `cognition.lisp:46 working-memory` is at `cognition.lisp:42` at HEAD; `shacl-validator.lisp` contains no "epoch" (0 hits) and `mltp3:ontology-bundle` is not in `source/` (only MLTP §2.11 prose: `ARCHITECTURE-CLOSURE-MATRIX.md:31`, `CHANGE-PROPOSAL-v1.4.md:916`) — the memoization row's seat is design-only; `ingress-decoder.lisp` (contract:35) is NOT FOUND (`LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md:12` "NEW, MISSING"). `knowledge-graph.lisp:116`, `legal-decisions.lisp:71`, `legal-inference-engine.lisp:238`, `greek-legislation-ontology.lisp:57`, `safe-read.lisp:68`, `journal.lisp:61` verified exact.

**F8 — MOP.** Contract:23 says MOP is "NOT USED in the trusted path — (none)". Source at HEAD uses `sb-mop`/`closer-mop` in 10 files, including `legal-inference-engine.lisp:504-509 all-legal-rules` (rule discovery of the reasoning engine — trusted path) and `knowledge-graph.lisp:69-84 assertion-class` (a metaclass that enforces the named invariant "no assertion without source+justification"). DDI-2 adds nothing to this; the discrepancy is CL2-A3.

##### Adjudication items raised by this map (both sides cited; nothing decided)

- **CL2-A1 — Single seat of a record's field list.** Model `field` facts (canonical, flat, kernel-checked; `MODEL-SCHEMA.sexp:9-13`) vs hand-written Lisp `defstruct`/`defclass` in `source/` (contract:20). Options: (i) Lisp declarations GENERATED from the model as `gen-artifact` facts — but `artifact-kind` has no PRODUCTION_CODE value (`MODEL-SCHEMA.sexp:63`, `:207-214`); (ii) hand-written Lisp + build-time set-equality conformance (the corpus discipline `AM/verification-corpus.sexp:11-14`); (iii) Lisp reads the facts at build time. V6I-REF (V1.6:158-162) rejects a type defined twice. Which is the ONE seat?
- **CL2-A2 — canonical(BODY) for content-addressed records.** V1.5:141-142/:456-458 and V1.6:86 leave `canonical(BODY)` undefined. Candidates: `journal.lisp:61 canon-sexp` (contract:34 "one canonical serialization boundary"; used by `memory.lisp:110`); `version-graph.lisp:471 %canon-sexp` — a byte-identical re-implementation although `journal.lisp:67` claims version-graph "delegates" (duplicate seat, constitution `:no-duplicate` `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:26`); AMC2 (`AM/CANONICAL-ENCODING.md:1-5`) for model facts. Which encoding hashes DDI-2 bodies, and is `%canon-sexp` retired?
- **CL2-A3 — MOP row vs source.** Contract:23/:40 "(none)" vs `sb-mop`/`closer-mop` in `corpus-intelligence.lisp:45-52`, `corpus-service.lisp:44-53`, `deliberation.lisp:40-44`, `greek-legislation-ontology.lisp:88-`, `knowledge-graph.lisp:69-76`, `legal-hypergraph.lisp`, `legal-inference-engine.lisp:504-509`, `review-queue.lisp`, `self-model.lisp`, `source-profile.lisp`. Correct the contract row (admit each with reason/seat/requirement/invariant/test) or change the seats? DDI-2 is neutral (0 MOP requests).
- **CL2-A4 (cross-ref V1.6 dossier A21) — Non-evaluating ingress decoder is unbuilt.** Adapter outputs (class 7) and PerceptionEnvelope/1 (class 8) have no runtime validation seat: `ingress-decoder.lisp` NOT FOUND; `safe-read.lisp:28-30` is internal-only by constitutional order. Until built, `runtime_validation` for adapter-fed records is UNKNOWN.
- **CL2-A5 (cross-ref V1.6 dossier A13) — define-mapping binds capabilities to file names.** V6I-01 (V1.6:15-16 "lock meanings, NEVER tools") vs V1.7:344-345 (this map is the only capability closure). CL-native re-expression through `seat` refs (`MODEL-SCHEMA.sexp:129-136`) or the analyzer registry name (`greek-nlp-core.lisp:397`) — which family, and are the two field-seats and one invariant-seat (V1.6:244-246) DECLARED-EXTENSION rows?
- **CL2-A6 — Technology names as canonical ids + structural V8I-02.** ONNXProposerAdapter/OCRPerceptionAdapter (V1.6:67-74) and ProposerKind (V1.6:51-56): import as adapter-instance facts (never `type`)? Should the schema carry a `define-conditional` forbidding `:mandatory YES` for kinds LOCAL_MODEL/EXTERNAL_MODEL/OCR_PERCEPTION, making V8I-02 (V1.8:17-19) a kernel law rather than prose (CLAUDE.md: make the error structurally impossible)? Also `:canonical-write-authority nil` cannot be a model value (`MODEL-SCHEMA.sexp:6`; dossier A18).
- **CL2-A7 — Persisted clarification state has no store.** Suspend/resume/expiry (V1.8:28-39, :60-61, :378-385) cannot be CL restarts across invocations; ClarificationRequest/Response must be journaled, but no `store` fact covers cognition state (`AM/stores-and-authorities.sexp:5-14`, 10 stores) and `legal-dialectic.lisp` has no condition/restart today. Which store/writer owns it (memory store under SEAT-MEMORY? a new store — L2 single owner)?
- **CL2-A8 — Contract seat drift.** `cognition.lisp:46`→`:42`; memoization seat (`shacl-validator.lisp` epoch / `mltp3:ontology-bundle`) absent from source; `ingress-decoder.lisp` absent. Record corrections in the normative contract or annotate as `[design-target]` per its own convention (contract:8).
- **CL2-A9 (cross-ref V5-A8 / ADJ-V17-REC-5 / A20) — Primitive → CL type binding.** The primitive vocabulary seat must bind each token to a CL type seat: `instant`→`version-graph.lisp:149 legal-instant`, `id`/`sha256`/`sig` → strings under canon-sexp; `duration` (only `legal-temporal.lisp:28 date-plus-days` exists), `uncertainty` (`lawmax/uncertainty/1`), `quorum-spec` have no seat (0 hits in `source/*.lisp`).
- **CL2-A10 (cross-ref V1.6 dossier A10 / ADJ-V17-ENUM-2) — Private-bearing enum in a PUBLIC record.** MemoryPolicy/1 `(list MemoryScope)` (V1.6:293) vs V6I-MEM-public-base-clean (V1.6:305-308). CL-native repair = union extension type in the private package; alternative = re-type to MemoryScopeV7 (V1.7:105). Decide before any S19 deftype is written.
- **CL2-A11 — Memory/journal write authority: model vs source.** `AM/stores-and-authorities.sexp:8-10` names SEAT-WRITE-AUTHORITY (`write-authority.lisp`) as writer of journal/legal-ir/memory and V6I-05/V6I-14 (V1.6:32-34, :297-300) require it; `write-authority.lisp:4-8,:16-49` handles only RDF `emit-graph` with `:canonical`/`:provenance`, while `memory.lisp:96`, `self-history.lisp:48`, `version-graph.lisp:546` call `journal:chained-append` directly. Is the journal chain (`journal.lisp:507`) the write authority for these stores (then the seat fact is misnamed), or must `write-authority.lisp` grow the journal API (then MemoryEvent/1's `write_authority_id` V1.6:107 has a real seat)?

##### Unknowns (honest)
- Owner subsystem / package for: StateEventKind and the six V1.5 decision-input enums (V5-A5); 14 unregistered V1.5 records (V5-A1); MorphLattice/1, PackedParseForest/1, DiscourseState/1, PromotionEvidence/1 and 11 V1.7 cognition intermediates (ADJ-V17-REF-1/REC-1); ProposerKind/CognitionCapability/CognitionError (A19). Without an owner no `type` fact and no package placement is possible (`MODEL-SCHEMA.sexp:148-152`).
- CL type seats for `duration`, `uncertainty`, `quorum-spec` (0 hits in `source/*.lisp`).
- The ≥2-hash-family multi-commitment seat for MultiCommitment/1 (V1.8:119-123): `orchestrator.merkle` is domain-separated (`proof-carrying.lisp:26-33`) but single-family; no seat found.
- Which harness executes imported EXEC-MODEL data (cardinality table/matrix) — ADJ-V18-EXEC-1; the model's harness universe runs L1-L7 only (`AM/verification-corpus.sexp:24-39`).
- Whether the CL contract (v1.7 CANDIDATE, [0153]) has an explicit creator approval — no "εγκρίνω" found for it in `deployment/collab/dialogue/0153-claude.md`; `AI-DIALOGUE.md` does not name the file.
- `systems/orchestrator-omega.asd` is a symlink to `../orchestrator-omega.asd` (so 16 real systems, consistent with [0146]:18) — verified; no duplicate system.
- Nothing was executed (no SBCL, no gates, per BRIEF); all mechanism claims are read-only structural readings.


### DDI-3

#### cl-DDI-3 — Common-Lisp-native map for batch DDI-3 (10 classes / 12 forms)

Read-only reconnaissance against RO HEAD 4ee2b58a. Normative contract: `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md` (each mechanism only with reason/seat/requirement/invariant/test/fallback/migration/rollback; MOP forbidden without a named invariant — contract:23,40-41). No production code was written. Every claim cites file:line in RO; UNKNOWN is stated where the repository is silent.

##### Batch scope (WORK/classes.md rows 18-21, 42, 47, 53, 54, 61, 64; ledger deferred-imports.sexp:14,19,23,24,44,50,58,59,60,68)

| # | class_id | form(s) | source lines | owner (as evidenced) |
|---|---|---|---|---|
| 1 | `V1.5-SCHEMAS__define-decision-function` | census-coverage-decision | V1.5:226-245 | S01 (SR:36; seat DESIGN_TARGET seats.sexp:77) |
| 2 | `V1.7-SCHEMAS__define-decision-function` | census-coverage-decision-v7 | V1.7:254-279 | S01 by content; -v7 in no registry row |
| 3 | `V1.5-SCHEMAS__define-algorithm` | control-domain-partition | V1.5:385-400 | S10 inferred; code seat UNKNOWN |
| 4 | `V1.5-SCHEMAS__define-quorum-predicate` | mesh-independence-quorum | V1.5:420-432 | S10 inferred; code seat UNKNOWN |
| 5 | `V1.5-SCHEMAS__define-projection` | InterpretiveProfileCanons; SubjectCurrentStatus; ClaimArgumentIndex | V1.5:483-486, 540-543, 560-564 | S04 inferred (seats.sexp:32-33) |
| 6 | `V1.7-SCHEMAS__define-source-type-coverage` | (anonymous) :registry=LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md | V1.7:358-371 | S16 (SR:85-87; DOCUMENT_SEAT seats.sexp:70-72) |
| 7 | `V1.8-SCHEMAS__define-cognition-graph` | cognition-graph-v8 | V1.8:52-65 | S04 by TRACEABILITY:387; UNKNOWN as a fact |
| 8 | `V1.8-SCHEMAS__define-cognition-node-types` | cognition-graph-v8-types | V1.8:362-383 | S04 by TRACEABILITY:387; UNKNOWN as a fact |
| 9 | `V1.8-SCHEMAS__define-dimension-policy` | root-authority-dimensions | V1.8:88-96 | S14 by ISR:110 / TRACEABILITY:390 |
| 10 | `V1.8-SCHEMAS__define-reliance-aggregation` | reliance-of | V1.8:407-414 | S14 by ISR:110-115 / TRACEABILITY:390 |

##### Real CL seats used as evidence (all in ONE ASDF system: orchestrator-infrastructure.asd:5)

- generic functions: `source/cognition.lisp:101-118` (defgeneric synthesize/triage/critique; plan, execute-step exported :28); hard-coded 5-stage `%run-stages` :123-135.
- JTMS: `source/legal-inference-engine.lisp:227-238` (defclass jtms, make-jtms); rules as data `:491 defrule`; unify `:78`.
- canonical serialization / chained journal: `source/journal.lisp:61-68 canon-sexp`, `:507 chained-append`, `:252-262 non-monotonic-transaction-time`.
- safe data reading: `source/safe-read.lisp:6-30` (one seat, *read-eval* nil, +data-readtable+), `:68-70 safe-read-error`, `:275 read-data-file`.
- restarts invoked programmatically: `source/trace-core.lisp:264-277`, `source/legal-ast.lisp:1600-1612`.
- immutable contracts: `source/capability-registry.lisp:40-48` (:read-only, :copier nil), frozen type set `:54-59`.
- bitemporal / as-of: `source/version-graph.lisp:7, 461-465`; calendar arithmetic `source/legal-temporal.lisp:28-53`; typed temporal conditions `source/corpus-service.lisp:223-240`.
- ontology DSL: `source/greek-legislation-ontology.lisp:57 defconcept` (33 forms); rule consumer `source/legal-conflict-resolution.lisp:22-49,78-90`.
- write authority: `source/write-authority.lisp:16-30`. Compile-time seat named by contract:32 (`constitutional-gate.lisp`) is a RUNTIME rule registry with fail-open on rule error (`:22-47`, `:45`).
- MOP is LIVE in source despite contract:23 'NOT USED in the trusted path': `deliberation.lisp:40-44` (thought-class metaclass), `legal-inference-engine.lisp:17-18,514-520` (sb-mop:class-direct-subclasses rule discovery), `review-queue.lisp:54-63`, `corpus-service.lisp:44-53`, `source-profile.lisp:137`. This map REQUESTS MOP NOWHERE (mop_requested = 0).

##### Per-class map (12 dimensions + two checks)

###### V1.5-SCHEMAS__define-decision-function

Source: deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.5-SCHEMAS.sexp:226-245 (define-decision-function census-coverage-decision; :inputs 8, :output census_coverage_state, :ordered-clauses 6, :precedence)  
Ledger: ARCHITECTURE-MODEL/deferred-imports.sexp:19 (DDI-3, AUTHORITATIVE_AT_SOURCE) · Dossier: agents/dossier-V1.5-SCHEMAS.sexp/dossier.json class define-decision-function (import_kind NEEDS_ARCHITECTURAL_DECISION) · Owner: S01 (SUBSYSTEM-REGISTRY.sexp:35-37; subsystems.sexp:5; seat DESIGN_TARGET seats.sexp:77)

| dimension | value |
|---|---|
| immutable_record | flattened typed facts `decision` (id, output-enum) + `decision-input` (decision, input-name, enum-ref) + `decision-clause` (decision, ordinal, output) + `decision-condition` (clause, input, value | member-set) — read-only after load, as the model reads every module with *read-eval* nil (dependencies-and-boundaries.sexp:3) and as the :read-only/:copier nil idiom of capability-registry.lisp:40-48 ('αμετάβλητο μετά την εγγραφή') | invariant: :V5I-04 TOTAL/deterministic/SINGLE-VALUED over the finite input product (V1.5-SCHEMAS.sexp:246-253) — determinism is structural only if the clause table cannot be mutated after load | fallback: one plain data list read by safe-read read-data-file (source/safe-read.lisp:275) with no struct |
| clos_class | **NOT-APPLICABLE** — no inheritance benefit (contract:20 admits CLOS for 'typed domain objects with inheritance'); a decision table is a value |
| generic_function | **NOT-APPLICABLE** — dispatch is closed — 'ONE total, deterministic, single-valued decision function' (V1.5:226); pluggable variants would create a second seat |
| condition_restart | an input value outside its closed enum (V1.5:186-189, 217-224) signals a typed condition of the S01 package (pattern source/safe-read.lisp:68-70 safe-read-error; source/corpus-service.lisp:223-235 as-known-unknown) — distinct from the enum MEMBER :UNKNOWN, which is a legitimate input VALUE; the `(:otherwise :UNKNOWN)` clause (V1.5:243) is the total fail-closed OUTPUT, never a condition | invariant: contract:24 'typed errors, never a guess' + L1 closed enums (MODEL-SCHEMA.sexp:18) | fallback: return a typed error value (contract:24 fallback) |
| macro_dsl | the registry form is DATA, never macroexpanded: the table is read (safe-read.lisp:275 read-data-file, *read-eval* nil) and folded by ONE first-match interpreter in the S01 seat; a `define-decision-function` macro is admissible ONLY as a compile-time golden-expansion over the in-repo model module (contract:25 'macros expand at compile time only; NEVER over external bytes'), never over registry bytes at runtime | invariant: contract:25 + contract:35 (no read/eval/macro over external input) + contract:26 'rules are data, not opaque code' | fallback: hand-written forms (contract:25 fallback) |
| protocol | **NOT-APPLICABLE** — closed signature (8 enum inputs -> 1 frozen enum); no open implementers; the signature is carried by `decision-input` facts |
| package_asdf_boundary | decision lives in the S01 package (owner SUBSYSTEM-REGISTRY.sexp:36 S01 :interface '... + census-coverage-decision'; model owner-seat SEAT-COVERAGE-LEDGER DESIGN_TARGET, packet WP-01, seats.sexp:77-78 — no coverage-ledger.lisp is tracked); consumers (S16 SR:86 names census_coverage_state) import only the frozen output enum (V1.5:182-185), never the clause table | invariant: contract:31 'package boundary = capability boundary' + L5 (S01 PUBLIC, subsystems.sexp:5) | fallback: monolith package — today every cited seat is a component of ONE ASDF system orchestrator-infrastructure.asd:5 |
| persistent_event | the decision TABLE is a hash-pinned model module (L7); the decision OUTPUT per object is journaled into the coverage-ledger store (writer SEAT-COVERAGE-OWNER, seats.sexp:83) through the one journal idiom — source/journal.lisp:507 chained-append with :prev back-link, hashed by canon-sexp (journal.lisp:61-68) | invariant: identity = content-address (contract:27); non-monotonic transaction time rejected fail-closed (journal.lisp:252-262 non-monotonic-transaction-time) | fallback: copy-on-write / full re-derivation from inputs |
| truth_maintenance_dependency | **NOT-APPLICABLE** — pure function; recomputation = re-evaluation over a finite product; JTMS (legal-inference-engine.lisp:227-238) is for legal conclusions, not census states |
| temporal_index_projection | the coverage state is an AS-OF projection: inputs negative_evidence (:FRESH_QUALIFYING/:EXPIRED V1.5:223-224) and availability are time-indexed, so every evaluation names its transaction-time snapshot (source/version-graph.lisp:461-465 graph-latest-at: 'ντετερμινιστική συνάρτηση του journal, ΟΧΙ ρολόι build'); temporal uncertainty surfaces as the typed conditions of corpus-service.lisp:223-240 (as-known-uncertain / as-of-unavailable) | invariant: :V7I-COV-availability-live — availability is a LIVE input (V1.7-SCHEMAS.sexp:280-282); a coverage state without its as-of is not reproducible | fallback: full recompute at query time |
| compile_time_validation | exhaustive enumeration of the finite input product at model-build time (audit V5G 'zero uncovered, zero multi-output, exactly one frozen state per combination' V1.5:252-253) declared as a `property-family` with EXACT cardinality (MODEL-SCHEMA.sexp:221-223) so both verification paths enforce it generically (MODEL-SCHEMA.sexp:1-2); every clause value checked against its closed enum (L1) and every input bound to its enum by a typed `decision-input` ref (L3) instead of the present naming convention (V5-A2) | invariant: :V5I-04 total + single-valued; L1/L3 | fallback: runtime check on first evaluation |
| runtime_validation | each of the 8 inputs checked against its closed enum at the S01 boundary — the frozen-set idiom of capability-registry.lisp:54-59 (+param-types+: 'Άγνωστος τύπος ⇒ ΑΠΟΡΡΙΨΗ ... fail-closed, ποτέ σιωπηλή αποδοχή'); check-type at entry (idiom source/legal-identity.lisp:191) | invariant: L1 closed enums; contract:24 typed errors | fallback: reject the input fail-closed |

**python_in_cl_risk:** HIGH. Naive import = the source plist with nested clause lists (V1.5:229-245) copied as a blob — forbidden by L1 (MODEL-SCHEMA.sexp:5-6: no keywords, no nested lists, no NIL) — or a hand-transliterated `cond` chain / Python loop (the legacy pattern: V1.8-VERIFY.py re-implements the sibling reliance rule in Python at :1222-1232; for this class audit V5G never ran — PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:1119 'Καμία εκτέλεση'). CL-native alternative: 1 `decision` + 8 `decision-input` + 6 `decision-clause` + 13 `decision-condition` typed facts (dossier candidate family) folded by ONE first-match interpreter whose :otherwise row makes totality structural; the same facts are the fixture of the exhaustive product check — rules as inspectable data (contract:26), exactly as legal-event-calculus.lisp:43-61 defrule ec-* keeps rules as data.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04 cognition: NONE (S01 census domain, no cognition node). S19 memory: NONE. JTMS/legal-inference-engine: NONE (pure total function of 8 enum inputs; no belief revision). S20 / V8I-02: NONE — no model, vendor or runtime named (V1.8:17-19). Only constraint: importing BOTH V1.5:229 and its declared successor V1.7:259 (:supersedes, V1.7:260; SUPERSEDED-REGISTER.md:257-258) freezes two seats for one decision, violating :V8I-03-one-seat (V1.8:20-22) — adjudication V5-A2 / ADJ-V17-DF-1 must precede the import.

Eight-field discipline (for the admitted mechanisms): reason — typed, inspectable decision table shared by both verification paths · seat — S01 package / SEAT-COVERAGE-LEDGER (DESIGN_TARGET, WP-01) · requirement — R-132 (SR:36); V5R-B1 (TRACEABILITY-MATRIX.md:284) — NOT a model requirement fact (V5-A15) · test — V5Q-B1 (QUALIFICATION-TESTS:1110) unexecuted; future: property-family exhaustive product · migration — flatten to facts under a new module (dossier: decisions-and-projections.sexp); rendering of keywords per orchestrator note N12 · rollback — drop the module; the registry form remains AUTHORITATIVE_AT_SOURCE

Adjudication: V5-A2, V5-A3, V5-A15, ADJ-V17-DF-1, CL-DDI3-A6, CL-DDI3-A7, CL-DDI3-A9 · Unknown: whether audit V5G (finite product) ever executed under any gate (QUALIFICATION-TESTS.md:1119 says no execution)

###### V1.7-SCHEMAS__define-decision-function

Source: V1.7-SCHEMAS.sexp:254-279 (define-decision-function census-coverage-decision-v7; :supersedes string L260; :clauses 7 incl. availability guard L269; :total t :single-valued t L279)  
Ledger: deferred-imports.sexp:44 (DDI-3) · Dossier: agents/dossier-V1.7-SCHEMAS.sexp/dossier.json class define-decision-function (NEEDS_ARCHITECTURAL_DECISION) · Owner: S01 by SR:35-37 naming the v1.5 name only; -v7 in no registry row (UNKNOWN as a fact)

| dimension | value |
|---|---|
| immutable_record | same typed family as V1.5 (`decision` + `decision-input` + `decision-clause` (7 rows) + `decision-condition`) plus the flags :total/:single-valued rendered as yes-no enum values (MODEL-SCHEMA.sexp:71) and :supersedes as a typed ref to the superseded `decision` id (L3) instead of a string (V1.7:260) | invariant: :V7I-COV-availability-live TOTAL and SINGLE-VALUED (V1.7:280-282); supersession is a typed relation, not prose | fallback: plain data list (safe-read.lisp:275) |
| clos_class | **NOT-APPLICABLE** — as V1.5 |
| generic_function | **NOT-APPLICABLE** — as V1.5 (one seat) |
| condition_restart | as V1.5: out-of-enum input ⇒ typed condition (safe-read.lisp:68-70 pattern); NOTE the guard clause 4 (V1.7:269, availability non-public ⇒ :UNKNOWN) is a table ROW producing a VALUE, not an error path | invariant: contract:24 + L1 | fallback: typed error value |
| macro_dsl | data, never macroexpanded (contract:25/35); one first-match interpreter — identical mechanism to the V1.5 form so that ONE evaluator serves whichever version is canonical | invariant: contract:26 rules are data; :V8I-03-one-seat (V1.8:20-22) | fallback: hand-written forms |
| protocol | **NOT-APPLICABLE** — as V1.5 (closed signature) |
| package_asdf_boundary | S01 package as V1.5 — but the -v7 name appears in NO registry row (SR:36 still names the v1.5 name; dossier owner 'UNKNOWN as a fact'); the package that exports the decision must export exactly one symbol for it | invariant: contract:31 + one seat | fallback: monolith package (orchestrator-infrastructure.asd:5) |
| persistent_event | as V1.5: table hash-pinned (L7); outputs journaled via journal.lisp:507 chained-append / canon-sexp :61 | invariant: content-addressed identity (contract:27); journal.lisp:252 monotone transaction time | fallback: full re-derivation |
| truth_maintenance_dependency | **NOT-APPLICABLE** — as V1.5 (pure function) |
| temporal_index_projection | availability is a LIVE, time-indexed input (V1.7:255-256, 268-272): evaluation is as-of a journal snapshot (version-graph.lisp:461-465); typed temporal uncertainty (corpus-service.lisp:223-240) | invariant: :V7I-COV-availability-live (V1.7:280-282) | fallback: full recompute at query time |
| compile_time_validation | exhaustive product enumeration as `property-family` EXACT cardinality (MODEL-SCHEMA.sexp:221-223) + L1 closed-enum check of every clause value — which FAILS TODAY on clause 6: :VALID_AUTHORITATIVE_FRESH (V1.7:274) is not a member of negative_evidence_validity (V1.5:223-224) — the build-time law makes V5-A3 / ADJ-V17-DF-2 structurally visible instead of prose-only | invariant: L1 closed enums; :V7I-COV-availability-live total + single-valued | fallback: runtime check |
| runtime_validation | closed-enum check of the 8 inputs at the S01 boundary (capability-registry.lisp:54-59 idiom; check-type) | invariant: L1; contract:24 | fallback: reject fail-closed |

**python_in_cl_risk:** HIGH (as V1.5). Additional naive-import hazard specific to this form: :total t :single-valued t are boolean flags a naive importer would store and trust ('t' compared as a string — exactly V1.8-VERIFY.py:1203-1211's `!= 't'` pattern) instead of PROVING totality/single-valuedness from the clause table. CL-native alternative: the flags are not stored as claims at all — they are the RESULT of the build-time exhaustive product over the typed `decision-*` facts; a flag the table cannot prove is an L1 failure, not a stored boolean.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04/S19/JTMS/S20: NONE (see V1.5 row). Constraint: same one-seat adjudication (ADJ-V17-DF-1); plus the undeclared enum value (ADJ-V17-DF-2) blocks L1 import until the enum is extended or the clause corrected — a decision that changes the semantics of EXPLICITLY-ABSENT (V1.7:273-275), i.e. a legal-coverage semantics decision, not a rendering detail.

Eight-field discipline (for the admitted mechanisms): reason — one evaluator for one canonical decision · seat — S01 package (DESIGN_TARGET) · requirement — R-132; :V7I-COV-availability-live (V1.7:280) · test — V1.7-CONTRADICTION-OMISSION-AUDIT.sh (HISTORICAL_EVIDENCE files-and-roles.sexp:444); future property-family · migration — import only the canonical version; :supersedes as typed ref · rollback — drop module

Adjudication: ADJ-V17-DF-1, ADJ-V17-DF-2, V5-A2, V5-A3, CL-DDI3-A9 · Unknown: whether :VALID_AUTHORITATIVE_FRESH is a rename of :FRESH_QUALIFYING or a new member (no registry says)

###### V1.5-SCHEMAS__define-algorithm

Source: V1.5-SCHEMAS.sexp:385-400 (define-algorithm control-domain-partition; :input 4 names; :steps 6 prose; :output string)  
Ledger: deferred-imports.sexp:14 (DDI-3) · Dossier: agents/dossier-V1.5-SCHEMAS.sexp/dossier.json class define-algorithm (NEEDS_SCHEMA_EXTENSION) · Owner: S10 inferred (dossier); seat SEAT-KERNEL-VERIFY seats.sexp:44-45

| dimension | value |
|---|---|
| immutable_record | `algorithm` fact (id, output text) + 6 `algorithm-step` facts (ordinal, text) as DOCUMENTATION facts (the steps are prose, V1.5:389-399); the algorithm's RESULT — the partition — is an immutable value (vector of component ids) computed once per (inputs, as-of) | invariant: V1.5:398 'deterministic, order-independent' — order-independence is only checkable over an immutable input set and an immutable result | fallback: plain list of strings |
| clos_class | **NOT-APPLICABLE** — union-find over actor ids; the typed inputs (DomainAssertion/1, NamespaceEquivalence/1, TrustedIssuerRegistry/1) are DDI-2 records, not classes of this form |
| generic_function | **NOT-APPLICABLE** — closed disjunction (V1.5:392-394), no open dispatch |
| condition_restart | **NOT-APPLICABLE** — deliberate: UNKNOWN membership is a closed VALUE (edge added, V1.5:395-397), never a signalled condition; a condition is reserved for structurally malformed records (L1) |
| macro_dsl | **NOT-APPLICABLE** — steps are prose; a DSL without a grammar would be a string parser (contract:35 forbids read/eval over text) |
| protocol | **NOT-APPLICABLE** — closed signature (actors, domain-assertions, registry, policy) -> partition; only consumer is mesh-independence-quorum (V1.5:425) |
| package_asdf_boundary | S10 package (dossier inference: MLTP trust layer, ISR sibling IndependencePolicy/1 :owner S10 interfaces-and-types.sexp:27); model owner-seat SEAT-KERNEL-VERIFY = deployment/verify/kernel-verify.lisp (seats.sexp:44-45), which is a dependency-free release verifier ('ΜΟΝΟ ironclad + babel + cl-base64 + yason — ΚΑΜΙΑ εξάρτηση από το σύστημα παραγωγής', kernel-verify.lisp:3-5) and contains no partition/quorum code (grep quorum|union-find|control-domain in source/*.lisp and kernel-verify.lisp = 0) — the CL seat of this algorithm is therefore UNKNOWN (CL-DDI3-A4) | invariant: contract:31 package boundary = capability boundary; kernel-verify's independence from the production system is itself an invariant (kernel-verify.lisp:3-9) | fallback: monolith package |
| persistent_event | **NOT-APPLICABLE** — derived result; the persistent objects are its content-addressed inputs (TrustedIssuerRegistry/1 pinned by LocalTrustState, V1.5:414) |
| truth_maintenance_dependency | **NOT-APPLICABLE** — full recompute is cheap (union-find) and is the contract:29 fallback; no named invariant asks for incremental recomputation |
| temporal_index_projection | 'fresh, non-revoked' membership (V1.5:391) is evaluated as-of an explicit instant against IndependencePolicy/1.evidence_freshness (:duration, V1.5:415) using the ONE calendar arithmetic source/legal-temporal.lisp:28-46 (date-plus-days, date<=) — never a wall clock inside the algorithm | invariant: determinism: same (inputs, as-of) ⇒ same partition (V1.5:398); revocation fail-closed (LAWMAX-THREAT-MODEL.md:47 Θ19 'revocation_ref fail-closed') | fallback: recompute at query time |
| compile_time_validation | **NOT-APPLICABLE** — open actor sets — nothing finite to enumerate; the only build-time check is L3 binding of the 4 input names to record types, which today exist only by prose (dossier unknown) |
| runtime_validation | every DomainAssertion/1 is admitted only if fresh AND non-revoked AND issuer-scope-authorized (V1.5:390-391); any missing / unauthorized-namespace / cross-namespace-without-equivalence / contradictory / :unknown membership is a VALUE that adds an edge (V1.5:395-397) — a closed 3-valued result type, not an exception path | invariant: fail-closed step 4 (V1.5:395-397) + :V5I-D3-unknown (V1.5:406-409) | fallback: treat every pair as shared (one component) — the maximal fail-closed answer |

**python_in_cl_risk:** MEDIUM. Naive import = six prose strings as a list plus, later, an imperative loop with a mutable 'unknown' boolean and try/except around namespace lookups (the Python idiom), so 'unknown ⇒ edge' becomes a caught exception instead of a value. CL-native alternative: the SHARED(a,b,d) predicate as a closed 3-valued `(member :shared :not-shared :unknown)` result over typed records, union-find over an immutable vector, the disjunction of V1.5:392-394 expressed as inspectable data (pattern legal-inference-engine.lisp:491 defrule :when/:unless — rules are data, contract:26); the six steps imported only as documentation facts, never as code.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04/S19: NONE. JTMS: NONE — but note the semantic kinship: 'unknown ⇒ edge' is the same fail-closed reading the engine gives its well-founded :undefined set (legal-inference-engine.lisp:233-236), so no second notion of 'unknown' is needed. S20 / V8I-02: NONE (no model). Constraint: the CL seat is undecided (CL-DDI3-A4) — a first implementation placed inside kernel-verify.lisp would break that file's dependency-free invariant.

Eight-field discipline (for the admitted mechanisms): reason — deterministic, fail-closed independence partition · seat — UNKNOWN (S10; kernel-verify.lisp is not it) · requirement — V5R-D3-11 (TRACEABILITY:261) — not a model fact (V5-A15) · test — V5Q-D3-11 (QUALIFICATION-TESTS:1097) unexecuted; audit V1.5-CONTRADICTION-OMISSION-AUDIT.sh:205 · migration — algorithm + algorithm-step facts; code in a future S10 file under WP-06 · rollback — drop facts

Adjudication: V5-A15, CL-DDI3-A4 · Unknown: the 4 :input names are bound to record types only by prose; whether kernel-verify.lisp is intended to host MLTP §10 logic

###### V1.5-SCHEMAS__define-quorum-predicate

Source: V1.5-SCHEMAS.sexp:420-432 (define-quorum-predicate mesh-independence-quorum; :was, :now multi-line string, :result-when-insufficient :INDEPENDENCE_UNKNOWN)  
Ledger: deferred-imports.sexp:24 (DDI-3) · Dossier: agents/dossier-V1.5-SCHEMAS.sexp/dossier.json class define-quorum-predicate (NEEDS_SCHEMA_EXTENSION) · Owner: S10 inferred; section header V1.5:263 'One quorum seat'

| dimension | value |
|---|---|
| immutable_record | `predicate` fact (id, was, result-when-insufficient) — the :now body (V1.5:423-431) cannot be a model value except as an opaque string (dossier); the CL-native form is the FOUR conjuncts (|INDEP| >= n, covers, no-prohibited-shared-dimension, FAIL_CLOSED exclusion) as four `predicate-conjunct` facts referencing the IndependencePolicy/1 fields they read (V1.5:412-418) | invariant: 'ONE seat' (V1.5:420; MACHINE-LEGAL-TRUST-PROTOCOL.md:1477 'Μία quorum έδρα') — today two textual seats (V5-A16); a structured record makes the second prose copy derivable rather than authored | fallback: opaque string value + rationale pointer |
| clos_class | **NOT-APPLICABLE** — a predicate over sets, no domain objects of its own |
| generic_function | **NOT-APPLICABLE** — one predicate, closed; 'replaces distinct-valid-kids' (V1.5:420) — a second dispatchable variant would resurrect the replaced seat |
| condition_restart | **NOT-APPLICABLE** — deliberate: insufficient evidence yields the declared result VALUE (V1.5:432), never a condition; only a malformed policy record is a typed error (L1) |
| macro_dsl | the τετρα-συζευκτική predicate (MLTP.md:1542) as an inspectable data conjunction evaluated by ONE evaluator — the pattern of legal-inference-engine.lisp:491 defrule (:when support list, :unless defeaters) where the rule is data, NOT a runtime parse of the :now string and NOT cl:read/eval of it (contract:35; safe-read.lisp:6-8 'Κανένα bare read') | invariant: contract:26 'rules are data, not opaque code'; one quorum seat | fallback: procedural `and` of four plain functions |
| protocol | **NOT-APPLICABLE** — consumer is the MLTP consumer-local verifier (V5I-07); closed signature |
| package_asdf_boundary | S10 package — same UNKNOWN code seat as control-domain-partition (SEAT-KERNEL-VERIFY seats.sexp:44-45 holds no quorum code; grep = 0; CL-DDI3-A4); the helper predicates independence-evidence-valid / distinct-components / covers / no-prohibited-shared-dimension are 'defined nowhere' (dossier) and must be exported from that one package | invariant: contract:31; one seat | fallback: monolith package |
| persistent_event | **NOT-APPLICABLE** — derived verdict; persistent objects are its inputs (LocalTrustState pins, V1.5:414) |
| truth_maintenance_dependency | **NOT-APPLICABLE** — full recompute is the contract:29 fallback and sufficient; no incremental invariant named |
| temporal_index_projection | VALID := fresh AND non-revoked ... (V1.5:423-424) is as-of an explicit instant against evidence_freshness (V1.5:415) via legal-temporal.lisp:28-46; the verdict carries its as-of | invariant: determinism of the quorum verdict per (members, evidence, policy, as-of); revocation fail-closed (THREAT-MODEL.md:47) | fallback: recompute at query time |
| compile_time_validation | L1 closed-enum membership of :result-when-insufficient at model build (MODEL-SCHEMA.sexp:18 'an out-of-domain value is L1') — FAILS TODAY: :INDEPENDENCE_UNKNOWN (V1.5:432) is in no closed enum (V5-A17); plus L3 refs of the four conjuncts into the IndependencePolicy/1 fields (quorum, required_distinct_dimensions, prohibited_shared_dimensions, unknown_handling V1.5:412-418) | invariant: L1/L3; the build makes V5-A17 structurally visible | fallback: runtime check |
| runtime_validation | unknown_handling dispatch inside the one evaluator over the closed enum (:FAIL_CLOSED | :DEGRADE, V1.5:403-405): under :FAIL_CLOSED no UNKNOWN member is counted in INDEP (V1.5:430-431); insufficient evidence ⇒ the declared result VALUE, never a pass | invariant: :V5I-06 (V1.5:433-436) + :V5I-D3-unknown (V1.5:406-409) | fallback: always FAIL_CLOSED |

**python_in_cl_risk:** HIGH. The :now field is pseudo-code in a string (V1.5:423-431); a naive import stores it and someone later 'parses' it or writes a boolean function beside it — which is already the state of play: MACHINE-LEGAL-TRUST-PROTOCOL.md:1540-1545 restates the predicate as a second authored text (V5-A16). CL-native alternative: four `predicate-conjunct` facts + one evaluator; the :now string survives only as a `rationale` (doc, anchor) pointer (MODEL-SCHEMA.sexp:182-184), and MLTP §15 becomes a rendering of the facts, not a second seat.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04/S19/JTMS: NONE. S20 / V8I-02: NONE (trust layer, no model). Freedom-reducing by OMISSION: the four helper predicates are undefined anywhere, so whoever implements first fixes MLTP §10 semantics without a registry seat; and the result token :INDEPENDENCE_UNKNOWN is undeclared (V5-A17) — importing the string as-is would freeze an undeclared vocabulary into the model.

Eight-field discipline (for the admitted mechanisms): reason — inspectable quorum predicate with one seat · seat — UNKNOWN (S10) · requirement — V5R-D3-12, V5R-R8 (TRACEABILITY:262,289) — not model facts · test — V5Q-D3-12 (:1098) unexecuted; audit V5S11 V1.5-CONTRADICTION-OMISSION-AUDIT.sh:208-209 · migration — predicate + predicate-conjunct facts; declare an independence-result enum (V5-A17) · rollback — drop facts; MLTP prose remains

Adjudication: V5-A16, V5-A17, V5-A15, CL-DDI3-A4 · Unknown: which text governs if V1.5:423-431 and MLTP.md:1541-1545 diverge; definitions of the four helper predicates

###### V1.5-SCHEMAS__define-projection

Source: V1.5-SCHEMAS.sexp:483-486 (InterpretiveProfileCanons), :540-543 (SubjectCurrentStatus), :560-564 (ClaimArgumentIndex); flat plists :derivation string :identity :none :hash-bearing nil :derived t  
Ledger: deferred-imports.sexp:23 (DDI-3, 3 forms) · Dossier: agents/dossier-V1.5-SCHEMAS.sexp/dossier.json class define-projection (NEEDS_SCHEMA_EXTENSION) · Owner: S04 inferred (seats.sexp:32-33 SEAT-LEGAL-AST; ISR:65 InterpretiveProfile/1 :owner S04)

| dimension | value |
|---|---|
| immutable_record | 3 `projection` facts (id, derivation text, derived=YES, identity=NONE, hash-bearing=NO — the keyword/nil flags of V1.5:486,543,564 rendered through the yes-no enum MODEL-SCHEMA.sexp:71 because L1 forbids keywords and NIL, MODEL-SCHEMA.sexp:5-6) + `projection-over` typed refs to the records each derives from (from define-ref-classification :derived rows V1.5:593-594) | invariant: a projection is NEVER identity-bearing (:V5I-C1-canon V1.5:487; contract:27 'identity = content-address; lifecycle detached (v1.5 R2)') — the hash-bearing/detached/derived trichotomy (V1.5:566) is what keeps derived views out of the content-address | fallback: copy-on-write (contract:27 fallback) |
| clos_class | **NOT-APPLICABLE** — a projection is a function over immutable records; making it an AST node class (legal-ast.lisp:1548 defastnode) would give it identity, which V1.5:486 forbids |
| generic_function | **NOT-APPLICABLE** — three closed derivations; open dispatch would be a CL mechanism leaking into the language-independent IR contract (contract §1) |
| condition_restart | **NOT-APPLICABLE** — deliberate: absent policy ⇒ UNKNOWN and incompatible ⇒ CONFLICTING are VALUES (Legal-IR:187-188); only a corrupt chain is a typed error |
| macro_dsl | **NOT-APPLICABLE** — derivations are prose; a CL DSL would leak into the IR contract (contract §1) |
| protocol | the Legal-IR conformance protocol: the three derivations are specified in the language-independent Legal-IR contract (deployment/LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md:187 'Convenience list = derived projection InterpretiveProfileCanons'; :207 'Το τρέχον status = reproducible projection SubjectCurrentStatus') and both compilers (CL WP-04, Rust WP-05) must produce identical projection results over the conformance corpus (contract:11-15 'share no evaluator code'; contract:34 dual-compiler root equality) | invariant: contract §1 language-independence — no CL mechanism may leak into the IR contract | fallback: single compiler (no cross-check) |
| package_asdf_boundary | InterpretiveProfileCanons and SubjectCurrentStatus in the S04 package (owner-seat SEAT-LEGAL-AST source/legal-ast.lisp seats.sexp:32-33; V1.6:97 declares 'legal-ast.lisp + LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md' the seat of v1.5 C1 records — dossier); ClaimArgumentIndex is 'over the existing L5/L6 proof-dependency graph' (V1.5:562) whose code seat is NOT FOUND (grep 'proof-dependency' in source = 0; ArgumentRecord/1 in source = 0) — S04 by dossier inference, S09 SEAT-PROOF-CARRYING (seats.sexp:42-43) the only other candidate | invariant: contract:31; the projection package may depend on the record packages, never the reverse (derived over stored) | fallback: monolith package |
| persistent_event | SubjectCurrentStatus = fold over the ordered LifecycleRecord/1 chain (V1.5:541-542; Legal-IR:205-207 'κλειδωμένο στο αμετάβλητο subject_id') — the chain is the append-only event log, the status is never stored; the chain idiom is journal.lisp:507 chained-append (:prev back-link, :hash identity) with chain verification as in memory.lisp:34 verify-episode-chain | invariant: status is a reproducible projection (Legal-IR:207); subject_id immutable (V1.5:558 'CANNOT change the subject's *_id'); non-monotonic transaction time rejected (journal.lisp:252-262) | fallback: full replay of the chain |
| truth_maintenance_dependency | **NOT-APPLICABLE** — no named invariant requires incremental maintenance; full recompute is the contract:28 fallback — recorded as fallback, not ceiling (see future_freedom) |
| temporal_index_projection | SubjectCurrentStatus is BITEMPORAL: LifecycleRecord/1 carries legal_time + audit_time (Legal-IR:205-206), so 'current' = as-of (valid-time, transaction-time); the seat idiom is source/version-graph.lisp:7 ('πλήρες bitemporal [valid-from,valid-until) × [recorded-from,recorded-until)') and :461-465 graph-latest-at (transaction-time snapshot as a deterministic function of the journal); half-open interval arithmetic legal-temporal.lisp:48-53 | invariant: reproducibility: status is a deterministic function of (chain, as-of) — never of the build clock (version-graph.lisp:463-464) | fallback: full replay |
| compile_time_validation | the status vocabulary {none|proposed|adopted|withdrawn|corrected|revoked|superseded} lives only inside the :derivation string (V1.5:542) and the transition alphabet (:propose|:adopt|:withdraw|:correct|:revoke|:supersede Legal-IR:205) is finite — declare both as closed enums (L1) and check the fold's transition table exhaustively at model build as a `property-family` of EXACT cardinality (MODEL-SCHEMA.sexp:221-223); for InterpretiveProfileCanons, L3 closure of the ref chain canon_policy_ref -> CanonPolicy/1.canon_id_refs -> CanonRule/1 (V1.5:485) | invariant: totality of the lifecycle fold over every transition; L1/L3 | fallback: runtime check |
| runtime_validation | unresolvable canon_policy_ref ⇒ UNKNOWN, incompatible canons ⇒ CONFLICTING as VALUES of the projection (Legal-IR:187-188 'καμία επινοημένη προτεραιότητα'); the fold over a lifecycle chain with a broken :prev link signals a typed condition (journal.lisp:495 stale-chain-link pattern) | invariant: :V5I-C1-canon (V1.5:487); honest ignorance (CLAUDE.md) | fallback: fail-closed UNKNOWN |

**python_in_cl_risk:** MEDIUM. Naive import = `{identity: None, hash_bearing: False, derived: True, derivation: '<docstring>'}` (L1 forbids two of those three values, MODEL-SCHEMA.sexp:5-6) followed, in code, by a `current_status` FIELD cached on the subject — the exact anti-pattern the form exists to forbid (never identity-bearing). CL-native alternative: pure functions in the S04 seat with no slot for their result; `projection` + `projection-over` facts give the model the typed 'derived over X' relation so the ref-classification trichotomy (V1.5:566) is checkable; the derivation prose becomes a `rationale` pointer.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04: the projections are Legal-IR semantics — the CL implementation must not leak into the IR contract (contract:10-15), which constrains compiler B equally; this is the intended constraint. S19 memory: the survival ledger groups 'V1.6:MemoryProjection/1 + V1.5:define-projection' (dossier lineage; V1.7-ARCHITECTURE-IDEA-SURVIVAL-LEDGER.md:16) while MemoryProjection/1 is a define-record (V1.6:294) — importing V1.5 define-projection as THE projection family pre-decides whether S19's memory projection is derived-only or a stored record; adjudication needed before S19 memory design is bound. JTMS: ClaimArgumentIndex sits over the proof-dependency graph — the import must record full recompute as FALLBACK (contract:28-29), not as the ceiling, so future incremental maintenance of the index remains admissible. S20 / V8I-02: NONE.

Eight-field discipline (for the admitted mechanisms): reason — derived views kept out of the content-address · seat — S04 legal-ast.lisp (ClaimArgumentIndex seat UNKNOWN) · requirement — Legal-IR §12 R6.4/R8.3; V5R rows (TRACEABILITY:241-293) — not model facts (V5-A15) · test — dual-compiler equality over the conformance corpus (contract:34); V5Q unexecuted · migration — projection + projection-over facts; enums for status/transition vocabularies · rollback — drop facts

Adjudication: V5-A15, CL-DDI3-A10 · Unknown: code seat of the L5/L6 proof-dependency graph for ClaimArgumentIndex (NOT FOUND in source); whether MemoryProjection/1 (V1.6:294) is to be classified derived-only

###### V1.7-SCHEMAS__define-source-type-coverage

Source: V1.7-SCHEMAS.sexp:358-371 (define-source-type-coverage; :registry doc; :required-families 36 keywords; :unknown-fail-closed t :versioned t :open-extension t; :relations-not-title-labels prose)  
Ledger: deferred-imports.sexp:50 (DDI-3) · Dossier: agents/dossier-V1.7-SCHEMAS.sexp/dossier.json class define-source-type-coverage (NEEDS_SCHEMA_EXTENSION) · Owner: S16 (SR:85-87; subsystems.sexp:20; seats.sexp:70-72 DOCUMENT_SEAT; files-and-roles.sexp:38 AUTHORED_NORMATIVE_PROSE)

| dimension | value |
|---|---|
| immutable_record | 36 `source-type-family` facts (registry-seat ref SEAT-SOURCE-TYPE-AUTHORITY-REGISTRY seats.sexp:70-72, family token) + one `registry-policy` fact (unknown-fail-closed=YES, versioned=YES, open-extension=YES via yes-no MODEL-SCHEMA.sexp:71) — facts, NOT a define-enum: the set is declared OPEN (:open-extension t V1.7:370) and a model enum is closed by definition (MODEL-SCHEMA.sexp:18) | invariant: :V7I-SRC-open-fail-closed (V1.7:372-374) versioned + open to extension; :V8I-03-one-seat (the registry document is the ONE seat, V1.7:359-360) | fallback: plain symbol list |
| clos_class | **NOT-APPLICABLE** — the coverage declaration is a closed list of tokens; inheritance among source types is already carried by defconcept supers (greek-legislation-ontology.lisp:120-136) — no new classes |
| generic_function | **NOT-APPLICABLE** — no open dispatch; classification is fact-driven |
| condition_restart | **NOT-APPLICABLE** — deliberate: unknown source type is the ST-UNKNOWN VALUE (fail-closed), not a condition |
| macro_dsl | the admitted DSL seat for the source-type taxonomy already exists: source/greek-legislation-ontology.lisp:57 defconcept (supers + :rank; 33 defconcept forms, e.g. :126 formal-law, :130 presidential-decree, :132 ministerial-decision) named by the contract:25 row; the 36 required families become a COVERAGE ASSERTION over that ontology (each family token resolves to one concept), never a second taxonomy — mapping today UNVERIFIED: family tokens are :FORMAL_LAW (V1.7:363), concepts are formal-law / URI strings 'FormalLaw' (legal-conflict-resolution.lisp:25-26), registry rows are ST-nn (ADJ-V17-STC-1) — three namings, no declared mapping (CL-DDI3-A5) | invariant: one seat for the taxonomy (V1.7:359-360; contract:20 ':no-duplicate'); macros expand at compile time only (contract:25) | fallback: hand-written list |
| protocol | source type enters reasoning ONLY as adapter-emitted `(:source-type CODE ART SOURCE-URI)` facts plus ontology-derived `(:outranks SUPERIOR INFERIOR)` facts (source/legal-conflict-resolution.lisp:22-31, 44-49 'Reflects the ontology automatically: a new DEFCONCEPT source with a rank is included here with no code change'); lex superior/specialis/posterior are DERIVED relations `(:prevails ... :by lex-superior)` (:30) — exactly the registry's rule that relations are 'never immutable title labels' (V1.7:371) | invariant: V1.7:371 relations-not-title-labels; :V7I-SRC 'classifies from authority evidence (never from act title)' (V1.7:373-374) | fallback: explicit rank table |
| package_asdf_boundary | S16 owner-seat is a DOCUMENT (seats.sexp:70-72 DOCUMENT_SEAT; SR:85-87 :owner the .md); the code consumers are S04 packages orchestrator.legal-ontology (greek-legislation-ontology.lisp) and orchestrator.conflict (legal-conflict-resolution.lisp:33-34, (:use :orchestrator.inference)) — one-way: document authority -> ontology -> rules; no code writes the registry | invariant: contract:31; DOCUMENT_SEAT conditional requires a tracked path (MODEL-SCHEMA.sexp:295) | fallback: monolith package |
| persistent_event | **NOT-APPLICABLE** — the registry is a versioned document, not an event log; version = document version (SR:87) |
| truth_maintenance_dependency | a registry version change (rank or relation) flows as fact retraction/assertion through the JTMS: the consumer already lives on orchestrator.inference (legal-conflict-resolution.lisp:34) and derives (:outranks) facts from ranks (:44-49), so conclusions (:prevails / :invalid-override :30-31) are recomputed dependency-directed by legal-inference-engine.lisp:227-238 (jtms, make-jtms) — the one admitted JTMS seat (contract:28) | invariant: contract:28 'belief revision is monotone-audited'; V1.7:371 relations are scoped, evidence-backed | fallback: full recompute (contract:28-29 fallback) |
| temporal_index_projection | classification is as-of a registry VERSION (:versioned t V1.7:370; SR:87 rollback 'registry version rollback') and as-of legal time for lex posterior (V1.7:371 'scoped'): the registry version is the epoch key of contract:30 ('a cache entry names its validation epoch; epoch change invalidates') | invariant: a classification without its registry version is not reproducible (:versioned t) | fallback: no cache — recompute |
| compile_time_validation | coverage check at model build: every `source-type-family` fact resolves (L3) to a registry row AND to an ontology concept — blocked today because the ST-01..ST-28(+ST-UNKNOWN) rows are prose inside a DOCUMENT_SEAT, not facts, and the family->row mapping is unverified (ADJ-V17-STC-1); the check exists only once the rows become facts (schema extension) or the mapping is declared | invariant: :V7I-SRC-open-fail-closed 'covers every required family' | fallback: runtime check |
| runtime_validation | an unknown source type resolves to the registry's ST-UNKNOWN row as a fail-closed VALUE and 'enters only via versioned' extension (V1.7:360, :370 :unknown-fail-closed t, :374); closed membership test over the versioned family set | invariant: :V7I-SRC-open-fail-closed (V1.7:372-374) | fallback: reject / ST-UNKNOWN |

**python_in_cl_risk:** MEDIUM. Naive import = 36 strings + 3 booleans + the 'relations-not-title-labels' sentence as a comment; the next step in that idiom is a classifier doing `title.startswith('ΝΟΜΟΣ')` — precisely what V1.7:373-374 forbids ('never from act title'). CL-native alternative: facts consumed by defrule patterns `(:source-type ?ca ?a ?sa)` (legal-conflict-resolution.lisp:78-90) with authority evidence, ranks from defconcept, relations derived in the JTMS — the source type is a fact with provenance, not a label.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04: NONE beyond the existing ontology seat. S19: NONE. JTMS: consistent with the existing consumer (legal-conflict-resolution.lisp:34). S20 / V8I-02: NONE. The one real constraint is on the IMPORT itself: rendering the 36 families as a closed model enum would foreclose the declared open extension (V1.7:370) — they must be facts (CL-DDI3-A5).

Eight-field discipline (for the admitted mechanisms): reason — coverage assertion over the one taxonomy seat · seat — S16 document + S04 ontology/rule packages · requirement — R-132 / Q29 / WP-01 (requirements-tests-workpackets.sexp:82 per dossier) · test — :V7I-SRC-open-fail-closed audit (V1.7-CONTRADICTION-OMISSION-AUDIT.sh HISTORICAL_EVIDENCE files-and-roles.sexp:444) · migration — 36 family facts + registry-policy fact; mapping table before L3 · rollback — drop facts; document remains the seat

Adjudication: ADJ-V17-STC-1, CL-DDI3-A5 · Unknown: mapping of the 36 family tokens to ST-nn rows and to the 33 defconcept concepts (not established by any registry)

###### V1.8-SCHEMAS__define-cognition-graph

Source: V1.8-SCHEMAS.sexp:52-65 (define-cognition-graph cognition-graph-v8: 20 :nodes, 13 :flow-edges, 2 :branch-edges, 2 :resume-edges, 4 :terminal-edges, 5 :terminals, :entry PERCEIVE)  
Ledger: deferred-imports.sexp:58 (DDI-3) · Dossier: agents/dossier-V1.8-SCHEMAS.sexp/dossier.json class define-cognition-graph (NEEDS_ARCHITECTURAL_DECISION) · Owner: UNKNOWN as a fact; S04 by TRACEABILITY-MATRIX.md:387 (DFT-07, seat legal-dialectic.lisp, T8-COGLIFE, WP-08)

| dimension | value |
|---|---|
| immutable_record | `cog-node` facts (graph, node, kind ENTRY/INTERIOR/TERMINAL) + `cog-edge` facts (graph, from, to, family FLOW/BRANCH/RESUME/TERMINAL) in a NEW module, not in the `stage`/`stage-edge` universe of the 8-node symbolic pipeline (dependencies-and-boundaries.sexp:5-21) — the graph is a value the traversal interpreter reads, never a structure it mutates; the edge (CLARIFY-DECIDE RESOLVE) listed in two families (V1.8:59-60) needs family in the id or it is an L2 collision (ADJ-V18-COG-2) | invariant: :V8I-COGGRAPH-acyclic-except-resume (V1.8:66-71) — acyclicity is a property of an immutable edge set | fallback: adjacency list |
| clos_class | **NOT-APPLICABLE** — nodes are stages, not domain objects; the existing CLOS in the seat (cognition.lisp:35 frame subclasses per intent, :42 working-memory) types VALUES flowing through the graph, not the graph |
| generic_function | one generic function per node kind with eql-specialized methods on the node designator — the admitted seat pattern source/cognition.lisp:101-118 (defgeneric synthesize / triage / critique; plan, execute-step exported :28) named by contract:21 ('open dispatch for analyzers/stages/adapters; dispatch is total or errors typed') — with the traversal ORDER driven by `cog-edge` facts instead of the hard-coded 5-stage sequence of cognition.lisp:123-135 (%run-stages 'Στάδια 2→5 (με 4.5)') which is a DIFFERENT, older pipeline than the 20-node v8 graph (CL-DDI3-A2) | invariant: contract:21 dispatch total or typed error; :V8I-COG-typed-edges (every node has exactly its declared in/out) | fallback: single dispatch function (contract:21 fallback) |
| condition_restart | CLARIFY-SUSPEND / CLARIFY-RESUME (V1.8:56,60-61) is the condition/restart the registries themselves name (V1.6:227 ':seat legal-dialectic.lisp + condition/restart'; V1.7:91 same; contract:24 'cognition clarification (COG7-11)'): CLARIFY-DECIDE signals a typed condition carrying ClarificationRequest/1; RESUME is a restart taking a ClarificationResponse/1 whose resume_binding_ref (V1.8:38, 384-385) must bind the exact suspended instance — restarts invoked PROGRAMMATICALLY with a typed argument as in source/trace-core.lisp:264-277 (provide-trace: 'καμία read-then-eval οδός') and source/legal-ast.lisp:1600-1612 (use-empty-node / skip-node / provide-node); LIMIT: a restart lives in the dynamic extent of its restart-case, so a clarification answered in a later session cannot be a live restart — it must re-enter RESOLVE from a persisted request (see persistent_event; CL-DDI3-A3) | invariant: contract:24 'every error is a typed condition; no silent failure'; V1.8:67-69 resume binds the exact suspended instance; TERM-UNDERDETERMINED is the typed no-answer value (V1.8:62) | fallback: return a typed error value / terminal (contract:24 fallback) |
| macro_dsl | **NOT-APPLICABLE** — the graph is data read with *read-eval* nil (dependencies-and-boundaries.sexp:3 idiom); no macro |
| protocol | the typed node protocol in-type -> out-type per node (define-cognition-node-types V1.8:363-383) with the mandatory path SYMBOLIC ONLY: every v1.7 stage is :symbolic-only t (V1.7:81-94) and the v8 node set has NO proposer node (V1.8:54-56) — proposers (S03, consumer-role PROPOSER MODEL-SCHEMA.sexp:48-50) can attach only as optional adapters (V1.6 adapter contracts :mandatory nil :replaceable t, orchestrator note N13) | invariant: :V8I-02-no-mandatory-model (V1.8:17-19) 'Removing every proposer leaves a semantically-equivalent SYMBOLIC_ONLY mandatory path' | fallback: symbolic-only path |
| package_asdf_boundary | node->package binding as facts — the :seat column of V1.7:81-94 (greek-nlp-core, greek-tokenizer-advanced, greek-lemmatizer, legal-casegrammar[general], greek-legislation-ontology, legal-deontic + legal-event-calculus, legal-dialectic, legal-extraction-verify + legal-ast, legal-qa) that V1.8 DROPPED (ADJ-V18-NT-4) — so that the edge set is also the allowed inter-package dependency set; existing packages: orchestrator.cognition (cognition.lisp:23), orchestrator.dialectic (legal-dialectic.lisp:14), orchestrator.deliberation (deliberation.lisp:27, used by cognition.lisp:126); none of cognition.lisp / deliberation.lisp / legal-dialectic.lisp is a model seat (seats.sexp: NOT FOUND); all are components of ONE ASDF system orchestrator-infrastructure.asd:5 (CL-DDI3-A6) | invariant: contract:31 'package boundary = capability boundary'; ASDF graph acyclic | fallback: monolith package (the present state) |
| persistent_event | ClarificationRequest/1 and ClarificationResponse/1 as journaled events through the one journal idiom (source/journal.lisp:507 chained-append; canon-sexp :61-68 for the content hash) so RESUME can bind the exact instance after the suspending process has ended — resume_binding_ref = content-address of the persisted request; MemoryEvent/1 is a VERIFIED canonical identity (V1.8:429) | invariant: exact-instance binding (V1.8:67-69, 384-388); monotone transaction time (journal.lisp:252-262); canonical writes only via write-authority (contract:33; source/write-authority.lisp:16-30 emit-graph 'ONLY authorized write function') | fallback: in-process restart only (no cross-session resume) |
| truth_maintenance_dependency | **NOT-APPLICABLE** — static topology; alternatives with no forced winner (V1.7:90,92) are values, not beliefs under revision |
| temporal_index_projection | **NOT-APPLICABLE** — the graph is atemporal; instance lifecycle is ClarificationLifecycleState (V1.8:30, DDI-2) |
| compile_time_validation | model-build laws over the new facts, enforced generically by BOTH verification paths (MODEL-SCHEMA.sexp:1-2): acyclic over flow+branch+terminal families; the resume family declared EXEMPT as data rather than hard-coded in the checker (the legacy guard hard-codes it: V1.8-VERIFY.py:1629-1645); every terminal reachable with no outgoing flow edge; out(src)=in(tgt) per edge (with `cog-node-type`); L2 uniqueness catching the double-listed edge (V1.8:59-60) — the same fixture discipline as FX-L4-PIPELINE-CYCLE (verification-corpus.sexp:32-33) but over a SEPARATE relation, since the L4 fixture is defined over stage-edge | invariant: :V8I-COGGRAPH-acyclic-except-resume (V1.8:66-71); :V8I-COG-typed-edges (V1.8:386-391) | fallback: runtime check on graph load |
| runtime_validation | at each node entry the value is checked against the node's declared :in type (check-type; frozen-set idiom capability-registry.lisp:54-59 fail-closed); a mismatch is a typed condition routed to TERM-ERROR (V1.8:63) | invariant: :V8I-COG-typed-edges | fallback: reject to TERM-ERROR |

**python_in_cl_risk:** HIGH. The naive import is a dict {nodes:[...], flow_edges:[[a,b],...]} plus a DFS validator with `if node == 'CLARIFY-RESUME': skip` — which is literally V1.8-VERIFY.py:897-902 cog_model and :1629-1645 (resume exemption hard-coded in the checker); in CL the equivalent is a hard-coded stage sequence, which cognition.lisp:123-135 already is. CL-native alternative: graph as facts; traversal = generic dispatch per node (cognition.lisp:107 pattern) reading `cog-edge`; suspension = typed condition + restart + journaled event; acyclicity/reachability/typing = generic build-time laws over a declared relation with the resume exemption as data.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04 cognition: HIGH STAKES. (a) Three graph versions are simultaneously authoritative at source (V1.6:217 12 stages with seats; V1.7:80 13 stages with seats, :preserves, :no-forced-winner, :binds-exact-candidate; V1.8:53 20 nodes without seats — ADJ-V18-COG-1); importing V1.8 alone loses the seat binding and the information-preservation flags (:V7I-COG-info-preserving V1.7:95), reducing what the future can verify. (b) The existing cognition.lisp is a 5-stage design with an `*advisor*` hook (cognition.lisp:25-30) and is not a model seat — the v8 graph must not be bent to its stage order (CL-DDI3-A2). (c) Proposer attachment: no PROPOSE node exists — where S03 SemanticProposer plugs in is UNKNOWN. S19 memory: the graph has no memory node; cognition.lisp:42 working-memory vs SEAT-MEMORY source/memory.lisp (seats.sexp:56) is unbound by this import — UNKNOWN, not constrained. JTMS: RESOLVE/PROMOTE feed legal inference; the graph does not constrain it. S20 / V8I-02: preserved — the graph is symbolic-only and adapter-free (V1.7:81-94 :symbolic-only t on every stage).

Eight-field discipline (for the admitted mechanisms): reason — cognition stages as data-driven typed dispatch with explicit suspension · seat — S04 — file UNKNOWN (legal-dialectic.lisp by TRACEABILITY:387; cognition.lisp by content; neither is a model seat) · requirement — DFT-07 (TRACEABILITY:387) — not a model requirement fact (orchestrator note N8) · test — T8-COGLIFE (registration only, note N7); audit V8-COGLIFE 7 witnesses (V1.8:389-391) executed only by HISTORICAL_EVIDENCE code · migration — cog-node/cog-edge facts in a new module + node->seat facts recovered from V1.7:81-94 · rollback — drop module; stage universe untouched

Adjudication: ADJ-V18-COG-1, ADJ-V18-COG-2, ADJ-V18-NT-4, ADJ-V18-EXEC-1, CL-DDI3-A2, CL-DDI3-A3, CL-DDI3-A6 · Unknown: where S03 proposers attach to the v8 graph; binding of working-memory (cognition.lisp:42) to SEAT-MEMORY; which of the three graph versions is canonical

###### V1.8-SCHEMAS__define-cognition-node-types

Source: V1.8-SCHEMAS.sexp:362-383 (define-cognition-node-types cognition-graph-v8-types: 20 (:node :in :out) rows) + :384-391 resume rule and :V8I-COG-typed-edges  
Ledger: deferred-imports.sexp:59 (DDI-3) · Dossier: agents/dossier-V1.8-SCHEMAS.sexp/dossier.json class define-cognition-node-types (NEEDS_ARCHITECTURAL_DECISION) · Owner: UNKNOWN as a fact; S04 by TRACEABILITY-MATRIX.md:387

| dimension | value |
|---|---|
| immutable_record | 20 `cog-node-type` facts (graph, node, in TYPE-ref, out TYPE-ref | TERMINAL) — TERMINAL is a sentinel, not a type (V1.8:380-383); L1 forbids NIL so 'no output' needs one declared token (ADJ-V18-NT-2); plus one `resume-binding` fact (from-type ClarificationRequest/1, to-type ClarificationResponse/1, via resume_binding_ref) making the resume exemption typed (dossier candidate) | invariant: :V8I-COG-typed-edges (V1.8:386-391) | fallback: alist of (node in out) |
| clos_class | **NOT-APPLICABLE** — a typing table; the types themselves are DDI-2 records |
| generic_function | the (node, in, out) rows ARE the method-signature table of the per-node generic function of the graph: :in is the specializer of the node's method, :out its declared result type — standard CLOS eql/class specializers (cognition.lisp:101-118 pattern), no MOP; method existence per node checked at build with standard `find-method` | invariant: contract:21 'dispatch is total or errors typed' — a node without a method is a build failure, not a runtime surprise | fallback: single dispatch function |
| condition_restart | the resume edge is type-INCOMPATIBLE by construction (CLARIFY-SUSPEND :out ClarificationRequest/1 V1.8:378 vs CLARIFY-RESUME :in ClarificationResponse/1 :379) and legal only by prose (V1.8:384-388; ADJ-V18-NT-3) — in CL that discontinuity IS the restart boundary: SUSPEND's :out is the slot type of the signalled condition, RESUME's :in is the argument type of the restart (trace-core.lisp:272-277 provide-trace takes a typed argument), so the 'exemption' is structural instead of a hard-coded skip (V1.8-VERIFY.py:1639) | invariant: V1.8:384-388 resume rule; contract:24 | fallback: typed error value |
| macro_dsl | **NOT-APPLICABLE** — data |
| protocol | the 20 rows are the node protocol of the graph; a `resume-binding` fact types the SUSPEND->RESUME binding; only 5 of the 17 endpoint types are model `type` facts today (PerceptionEnvelope/1 :39, ClarificationRequest/1 :16, ClarificationResponse/1 :17, ClarifiedInterpretation/1 :18, CognitionResult/1 :19 in interfaces-and-types.sexp) — the remaining 12 have no ISR entry, no model type and no stated owner (ADJ-V18-NT-1) | invariant: :V8I-COG-typed-edges; L3 closed refs (MODEL-SCHEMA.sexp:24-25) | fallback: prose rule (the present state) |
| package_asdf_boundary | each :in/:out must resolve (L3) to a `type` fact carrying owner-subsystem (MODEL-SCHEMA.sexp:148-152) — blocked for 12/17 until DDI-2 seats the intermediate cognition records (NormalizedDocument/1 ... PromotionEvidence/1, V1.7:45-62 records); the V1.7:81-94 :seat column is the only existing node->file binding (ADJ-V18-NT-4) | invariant: L3 closed references; contract:31 | fallback: type names as strings (loses L3) |
| persistent_event | **NOT-APPLICABLE** — intermediate records are transient unless promoted (PromotionEvidence/1) |
| truth_maintenance_dependency | **NOT-APPLICABLE** — static |
| temporal_index_projection | **NOT-APPLICABLE** — static |
| compile_time_validation | build-time laws: L3 of every :in/:out into `type`; out(src)=in(tgt) over `cog-edge` x `cog-node-type` for flow/branch/terminal families; the resume edge checked against the `resume-binding` fact instead of exempted by name; method existence per node (standard find-method) — read-verified by the dossier: all 13 flow, 2 branch, 4 terminal edges compatible, resume edge incompatible by construction | invariant: :V8I-COG-typed-edges | fallback: runtime check |
| runtime_validation | check-type of the incoming value against the node's :in at entry (capability-registry.lisp:54-59 fail-closed idiom); TERMINAL nodes accept and emit nothing | invariant: :V8I-COG-typed-edges | fallback: reject to TERM-ERROR |

**python_in_cl_risk:** HIGH. Naive import = list of dicts {node,in,out} with 'TERMINAL' as a magic string and the resume exemption as an `if node == ...` branch (V1.8-VERIFY.py:1632,1639 mutations name the rows textually). CL-native alternative: the table becomes method specializers + a typed restart argument; TERMINAL is a declared enum token; the resume binding is a fact — every 'special case' becomes a type, so no imperative validator exists to drift.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04 cognition: importing the 12 unowned intermediate type NAMES (NormalizedDocument/1, SegmentSequence/1, TokenStream/1, MorphLattice/1, PackedParseForest/1, ReferenceGraph/1, DiscourseState/1, LegalEntityGraph/1, LegalSemanticAlternativeSet/1, InterpretiveProfileEvaluation/1, ClarificationDecision/1, PromotionEvidence/1) as canonical `type` facts would fix S04's intermediate representations before the language-cognition design is decided; importing them as strings preserves freedom but loses L3 — adjudication ADJ-V18-NT-1 decides which. S19/JTMS/S20: NONE.

Eight-field discipline (for the admitted mechanisms): reason — edge type-compatibility as a structural property of dispatch · seat — S04 (file UNKNOWN) · requirement — DFT-07 (TRACEABILITY:387) · test — T8-COGLIFE / V8-COGLIFE 7 witnesses (V1.8:389-391) — HISTORICAL_EVIDENCE only · migration — cog-node-type + resume-binding facts; blocked on DDI-2 for 12 types · rollback — drop facts

Adjudication: ADJ-V18-NT-1, ADJ-V18-NT-2, ADJ-V18-NT-3, ADJ-V18-NT-4, ADJ-V18-COG-1 · Unknown: owner of the 12 intermediate cognition record types

###### V1.8-SCHEMAS__define-dimension-policy

Source: V1.8-SCHEMAS.sexp:88-96 (define-dimension-policy root-authority-dimensions: 8 rows dimension/class/failure/recovery-evidence/authority)  
Ledger: deferred-imports.sexp:60 (DDI-3) · Dossier: agents/dossier-V1.8-SCHEMAS.sexp/dossier.json class define-dimension-policy (NEEDS_ARCHITECTURAL_DECISION) · Owner: UNKNOWN as a fact; S14 by ISR:110 and TRACEABILITY:390

| dimension | value |
|---|---|
| immutable_record | 8 `dimension-policy` facts (dimension, class MANDATORY|ADVISORY, failure RelianceClass-value, recovery-evidence STRING, authority -> typed ref or EXTERNAL_PARTY token) — a policy TABLE versioned by policy_epoch (RootAuthorityStatus/1.policy_epoch :semver V1.8:82), immutable per epoch | invariant: :V8I-RASTATUS-product (V1.8:97-103): exactly 8 typed dimensions, proof_integrity SEPARATE from security, 'never turns recovery of one dimension into silent recovery of another' | fallback: alist |
| clos_class | **NOT-APPLICABLE** — a policy table |
| generic_function | **NOT-APPLICABLE** — closed table, one consumer (reliance-of) |
| condition_restart | **NOT-APPLICABLE** — deliberate: dimension failures are VALUES (DimensionState V1.8:75) and recovery is a journaled lifecycle, not a restart |
| macro_dsl | **NOT-APPLICABLE** — data |
| protocol | WHO may certify recovery: :authority as a typed reference into `seat` — 'MLTP root' ~ SEAT-KERNEL-VERIFY (seats.sexp:44), 'coverage owner' ~ SEAT-COVERAGE-OWNER (:83), 'observatory' ~ SEAT-OBSERVATORY-COLLECTOR (:81), 'security cell' ~ SEAT-SECURITY-CELLS (:79) — or an explicit EXTERNAL_PARTY token for 'legal counsel' / 'independent auditor'; no registry states the mapping (ADJ-V18-DIM-1) | invariant: L3 closed refs + 'forbids self-qualification' (V1.8:102) — self-qualification is structurally impossible only when the certifying authority is a typed seat distinct from the subject | fallback: free-text string (the present state) |
| package_asdf_boundary | S14 package (ISR:110 owner of RootAuthorityStatus/1; subsystems.sexp:18 owner-seat SEAT-CAPABILITY-API source/capability-api.lisp seats.sexp:50; TRACEABILITY:390 names 'provider_registry' which is NOT FOUND in source — CL-DDI3-A8); producers of dimension states (S10 proof_integrity, S01 coverage, S11 security) write DimensionState values one-way and never read the policy | invariant: contract:31; one-way producer->aggregator dependency | fallback: monolith package |
| persistent_event | the policy table is hash-pinned (L7 module hash) and every stored RootAuthorityStatus/1 names its policy_epoch + measured_at + signature (V1.8:82); per-dimension recovery is JOURNALED (V1.8:101-102) through journal.lisp:507 chained-append | invariant: a status without its policy epoch is not interpretable; monotone transaction time (journal.lisp:252) | fallback: embed a policy copy in each status |
| truth_maintenance_dependency | **NOT-APPLICABLE** — 8 static rows |
| temporal_index_projection | evaluation is keyed by (measured_at, policy_epoch) (V1.8:82): the policy epoch is the invalidation key of contract:30 ('a cache entry names its validation epoch; epoch change invalidates') | invariant: policy change invalidates every derived projection | fallback: no cache |
| compile_time_validation | build-time: exactly 8 rows = the 8 DimensionState fields of RootAuthorityStatus/1 (V1.8:78-80) as a `property-family` of EXACT cardinality (MODEL-SCHEMA.sexp:221-223); every :failure in RelianceClass (V1.8:83) and every :class in {MANDATORY, ADVISORY} by L1 closed enums; the row<->field correspondence needs DDI-2 record-field facts for L3 | invariant: :V8I-RASTATUS-product | fallback: runtime check |
| runtime_validation | a RootAuthorityStatus/1 whose policy_epoch names an unknown policy version, or carries a dimension absent from the table, raises a typed condition (pattern capability-api.lisp:35 coercion-error under a typed hierarchy) — never reinterpreted under another epoch | invariant: no silent reinterpretation (V8I-RASTATUS 'never ... silent recovery') | fallback: reject |

**python_in_cl_risk:** MEDIUM. Naive import = 8 dicts with free-text authority and keyword failure values as strings; downstream, the aggregation loop of V1.8-VERIFY.py:1222-1232 reads them as (dn, cl, fl) tuples. CL-native alternative: 8 typed facts with :authority as a closed reference or an explicit external-party token, consumed by ONE fold (reliance-of) whose inputs are the facts themselves — so the policy is inspectable by both verification paths and by the runtime from one seat.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04/S19/JTMS: NONE. S20 / V8I-02: NONE. Constraints on the import: (a) :authority strings naming humans ('legal counsel', 'independent auditor') cannot become seats — an EXTERNAL_PARTY token must be admitted; (b) the prose carrier claimed by CHANGE-PROPOSAL-v1.8.md:51-52 does not carry the table (ADJ-V18-DIM-2), so the model module would become the ONLY seat — acceptable but must be decided, not assumed.

Eight-field discipline (for the admitted mechanisms): reason — typed policy read by one aggregator · seat — S14 (capability-api.lisp per model; provider_registry per TRACEABILITY — NOT FOUND) · requirement — DFT-10 (TRACEABILITY:390) · test — T8-RASTATUS / audit V8-RASTATUS (V1.8-VERIFY.py:1120) — HISTORICAL_EVIDENCE · migration — 8 dimension-policy facts; authority mapping decided once · rollback — drop facts

Adjudication: ADJ-V18-DIM-1, ADJ-V18-DIM-2, CL-DDI3-A8 · Unknown: mapping of :authority strings to seats / external parties

###### V1.8-SCHEMAS__define-reliance-aggregation

Source: V1.8-SCHEMAS.sexp:407-414 (define-reliance-aggregation reliance-of: :order 4 symbols, :rule string, :preserve-causes t :advisory-never-blocks t :self-qualification :rejected :total t :deterministic t)  
Ledger: deferred-imports.sexp:68 (DDI-3) · Dossier: agents/dossier-V1.8-SCHEMAS.sexp/dossier.json class define-reliance-aggregation · Owner: S14 (ISR:110-115; TRACEABILITY:390); UNKNOWN as a fact

| dimension | value |
|---|---|
| immutable_record | `aggregation` fact (output-enum RelianceClass, total=YES, deterministic=YES, preserve-causes=YES, advisory-never-blocks=YES, self-qualification=REJECTED) + 4 `aggregation-order` facts (enum value, ordinal) + a STRUCTURED rule (rule-kind MIN-OVER-MANDATORY-FAILING, policy -> root-authority-dimensions, failing-states {FAILED DEGRADED UNKNOWN} as typed refs into DimensionState V1.8:75) instead of the formula STRING (V1.8:413; ADJ-V18-AGG-1) — the :order bare symbols vs RelianceClass keywords (ADJ-V18-AGG-3) unify under L1 rendering (note N12) | invariant: :V8I-RASTATUS-product 'DERIVED, total, deterministic, preserves ALL simultaneous causes' (V1.8:100-101) — a min over a declared total order of a closed enum is total by construction | fallback: string + external executor (the present state: V1.8-VERIFY.py) |
| clos_class | **NOT-APPLICABLE** — a fold over 8 enum values |
| generic_function | **NOT-APPLICABLE** — closed dimension set; no open methods — and method combination (contract:22) is explicitly not requested: explicit fold is the fallback AND the ceiling |
| condition_restart | self-issued qualification evidence (issuer = subject) is rejected at evidence intake by a typed condition under a typed hierarchy — pattern source/jws-authority.lisp:62-68 (jws-error > key-not-found / invalid-signature) — never silently downgraded; UNKNOWN on a mandatory dimension is NOT an error: it maps to that dimension's failure class as a VALUE (V1.8:409) | invariant: :self-qualification :rejected (V1.8:414); V8I-RASTATUS 'forbids self-qualification' (V1.8:102) | fallback: typed error value |
| macro_dsl | **NOT-APPLICABLE** — the rule must be neither a runtime-parsed string nor a macro over the registry; it is a structured fact + one fold |
| protocol | RootAuthorityStatus/1 -> RelianceProjection/1 with :derived a CONSTANT true (V1.8:87 '(member :true)') — the projection is never stored truth; both types are model facts owned by S14 (interfaces-and-types.sexp:46,54); consumers read RelianceProjection only and the causes are preserved in blocking_dimensions/advisory_dimensions (V1.8:86-87) | invariant: RelianceProjection DERIVED, not stored (V1.8:84); preserve-causes | fallback: n/a (signature fixed by the two model types) |
| package_asdf_boundary | S14 package as define-dimension-policy (subsystems.sexp:18 SEAT-CAPABILITY-API; TRACEABILITY:390 'provider_registry' NOT FOUND — CL-DDI3-A8); the fold and the policy live in ONE package so there is exactly one reader of the policy | invariant: contract:31; one seat | fallback: monolith package |
| persistent_event | the projection is never journaled as truth; the stored status (with policy_epoch, measured_at, signature V1.8:82) and the per-dimension recovery events are (V1.8:101-102, journal.lisp:507); every projection carries as_of (V1.8:87) | invariant: :derived constant true (V1.8:87) | fallback: n/a |
| truth_maintenance_dependency | **NOT-APPLICABLE** — 8 inputs; the 'support set' V8I-RASTATUS asks for (all causes) is exactly the blocking/advisory lists computed directly (V1.8:86-87) |
| temporal_index_projection | as_of (V1.8:87) + measured_at + policy_epoch (V1.8:82) key every projection; policy epoch = invalidation epoch (contract:30) | invariant: deterministic per (status, policy epoch, as_of) | fallback: no cache |
| compile_time_validation | the full 4^8 = 65,536 product (SUPERSEDED-REGISTER.md:286-287; V1.8-VERIFY.py:1233-1240) enumerated at model build as a `property-family` of EXACT cardinality 65536 (MODEL-SCHEMA.sexp:221-223) executed generically by BOTH verification paths — replacing the Python-only executor (V1.8-VERIFY.py:1222-1240, HISTORICAL_EVIDENCE files-and-roles.sexp:453; ADJ-V18-EXEC-1); the flags total/deterministic/preserve-causes are PROVED by the enumeration, not stored booleans compared as strings (V1.8-VERIFY.py:1203-1213 `!= 't'`) | invariant: :V8I-RASTATUS-product; V1.8:414 flags | fallback: runtime check |
| runtime_validation | every DimensionState value in its closed enum (V1.8:75) and the status's policy_epoch matching the loaded policy, else a typed condition (capability-api.lisp:35 pattern) | invariant: L1; no silent reinterpretation | fallback: reject |

**python_in_cl_risk:** HIGHEST in the batch. The executable semantics ALREADY live in Python: V1.8-VERIFY.py:1222-1232 `project()` re-implements the rule, pinned to a byte-exact string (EXPECTED_AGG_RULE :548-549; :1200-1202). A naive CL import copies the string into a fact and re-implements the loop beside it — two seats plus a 'parsed-but-ignored' value (MODEL-SCHEMA.sexp:11-13 forbids that). CL-native alternative: structured `aggregation` + `aggregation-order` facts + ONE explicit fold in S14 (min over the declared ordinals across MANDATORY dimensions whose state is in the declared failing set, else FULL_RELIANCE); the formula string survives only as a `rationale` pointer; the exhaustive product is a generic property family, not a bespoke executor.

**future_freedom (S04 / S19 / JTMS / S20-V8I-02):** S04/S19/JTMS: NONE. S20 / V8I-02: NONE. Constraint: this is the third 'decision' dialect at source (ADJ-V18-AGG-2) — first-match ordered clauses (V1.5/V1.7) vs min-over-order; a single `decision` family cannot express both without a :kind discriminator, so the import must decide one family with kinds or two families (CL-DDI3-A9); method combination (contract:22) is NOT requested — an explicit fold is the ceiling here because the dimension set is closed (8), so there is no open method set to combine.

Eight-field discipline (for the admitted mechanisms): reason — one inspectable aggregation with proved totality · seat — S14 (file UNKNOWN: capability-api.lisp per model, provider_registry per TRACEABILITY) · requirement — DFT-10 (TRACEABILITY:390); :V8I-RASTATUS-product · test — T8-RASTATUS; 4^8 product currently executed only by HISTORICAL_EVIDENCE code (ADJ-V18-EXEC-1) · migration — aggregation + aggregation-order + structured rule facts; property-family 65536 · rollback — drop facts; string remains at source

Adjudication: ADJ-V18-AGG-1, ADJ-V18-AGG-2, ADJ-V18-AGG-3, ADJ-V18-EXEC-1, CL-DDI3-A8, CL-DDI3-A9

##### New adjudication items raised by this map (CL-DDI3-A*) — both sides cited, not resolved here

- **CL-DDI3-A1** — MOP in the trusted path: contract:23,40-41 says MOP is 'NOT USED in the trusted path / deliberately absent'; source uses it in the reasoning engine's rule discovery (legal-inference-engine.lisp:17-18,514-520 sb-mop:class-direct-subclasses), in deliberation.lisp:40-44 (thought-class metaclass, called from cognition.lisp:126), review-queue.lisp:54-63, corpus-service.lisp:44-53, source-profile.lisp:137. Either the contract's claim is wrong or those files are outside 'the trusted path'. DDI-3 rule tables (decision, quorum, aggregation) must not depend on MOP discovery; no named invariant requires it.
- **CL-DDI3-A2** — Cognition seat mismatch: TRACEABILITY-MATRIX.md:387 names legal-dialectic.lisp (68 lines; a dialectic-report function :20-27) as the DFT-07 seat; the file that implements cognition stages is cognition.lisp (5 stages, %run-stages :123-135, *advisor* :25) — neither is a model seat (seats.sexp: NOT FOUND); the model's S04 owner-seat is legal-ast.lisp (seats.sexp:32-33). Which file is the future seat of cognition-graph-v8?
- **CL-DDI3-A3** — Restart dynamic extent vs cross-session clarification: V1.6:227 / V1.7:91 / contract:24 name CLARIFY as 'condition/restart', but a human clarification outlives the process; the resume must be a persisted ClarificationRequest/1 + re-entry at RESOLVE (journal.lisp:507; V1.8:384-385 resume_binding_ref). The registries do not say whether in-process restart, persisted re-entry, or both are normative.
- **CL-DDI3-A4** — S10 code seat for control-domain-partition / mesh-independence-quorum: model owner-seat SEAT-KERNEL-VERIFY = deployment/verify/kernel-verify.lisp (seats.sexp:44-45) is a dependency-free release verifier (kernel-verify.lisp:3-5) with no quorum/partition code (grep = 0 in source/*.lisp and kernel-verify.lisp); MLTP §10/§15 is prose (files-and-roles.sexp:406). A new S10 file needs a new seat (WP-06); reusing kernel-verify breaks its minimalism.
- **CL-DDI3-A5** — Source-type families must be facts, not a closed enum: :open-extension t (V1.7:370) vs define-enum closed (MODEL-SCHEMA.sexp:18). Also three namings with no declared mapping: family tokens :FORMAL_LAW (V1.7:363), defconcept names formal-law / URI 'FormalLaw' (greek-legislation-ontology.lisp:126; legal-conflict-resolution.lisp:25-26), registry rows ST-nn (extends ADJ-V17-STC-1).
- **CL-DDI3-A6** — Package vs system boundary: every seat cited for DDI-3 (cognition, legal-inference-engine, legal-dialectic, journal, safe-read, memory, capability-registry/api, legal-ast, constitutional-gate, write-authority, proof-carrying, version-graph, deliberation) is a component of ONE ASDF system orchestrator-infrastructure.asd:5; contract:31 says 'package boundary = capability boundary; 16 ASDF systems / 53 edges'. For S04/S10/S14 the boundary is at defpackage level only. Is that sufficient for L5 in the future build?
- **CL-DDI3-A7** — Compile-time validation seat: contract:32 names constitutional-gate.lisp + compile-time schema; constitutional-gate.lisp:22-47 is a runtime rule registry evaluated per command, and :45 is fail-OPEN on rule error ('σφάλμα κανόνα ⇒ ΜΗΝ μπλοκάρεις') — contrary to fail-closed everywhere else. For DDI-3 the build-time seat is the model gate's generic laws (MODEL-SCHEMA.sexp:1-2, 221-223), not constitutional-gate.lisp. Decide the seat.
- **CL-DDI3-A8** — S14 seat: TRACEABILITY-MATRIX.md:390 names 'provider_registry' (NOT FOUND in source: no provider_registry.lisp / provider-registry.lisp); the model's S14 owner-seat is SEAT-CAPABILITY-API source/capability-api.lisp (subsystems.sexp:18; seats.sexp:50). Which is the seat of dimension-policy / reliance-of?
- **CL-DDI3-A9** — Decision dialects: a typed `decision` family of first-match ordered clauses covers V1.5:229 and V1.7:259 but not reliance-of (min over a total order, V1.8:412-413). One family with a :kind discriminator, or two families? (extends ADJ-V18-AGG-2)
- **CL-DDI3-A10** — Projection family vs S19: V1.7-ARCHITECTURE-IDEA-SURVIVAL-LEDGER.md:16 groups 'V1.6:MemoryProjection/1 + V1.5:define-projection' while MemoryProjection/1 is a define-record (V1.6:294). Importing V1.5 define-projection as THE projection family pre-decides whether S19's memory projection is derived-only; the import must not bind S19 before its memory design (SEAT-MEMORY memory.lisp) is decided.

##### Counts

- classes: 10 (12 forms)
- mop_requested: 0 (MOP proposed for no class; existing MOP uses in source recorded as CL-DDI3-A1)
- python_in_cl_risks: 10 (HIGH: V1.5 decision, V1.7 decision, quorum, cognition-graph, node-types, reliance; MEDIUM: algorithm, projection, source-type-coverage, dimension-policy)
- future_constraints: 4 (cognition-graph, cognition-node-types, projection, source-type-coverage) — the other six constrain S04/S19/JTMS/S20 NOT AT ALL; their only constraints are one-seat / enum adjudications

##### Unknowns (repository silent)

- whether audit V5G (finite product of census-coverage-decision) or any V5Q/V5KW ever executed (PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:1119 'Καμία εκτέλεση')
- whether :VALID_AUTHORITATIVE_FRESH (V1.7:274) is a rename or a new enum member
- the 4 :input names of control-domain-partition bound to record types only by prose
- whether kernel-verify.lisp is intended to host MLTP §10 quorum logic
- definitions of the four quorum helper predicates (independence-evidence-valid, distinct-components, covers, no-prohibited-shared-dimension) — defined nowhere
- code seat of the 'L5/L6 proof-dependency graph' for ClaimArgumentIndex (grep 'proof-dependency' and 'ArgumentRecord' in source = 0)
- mapping of the 36 source-type family tokens to ST-nn rows and to the 33 defconcept concepts
- where S03 proposers attach to cognition-graph-v8 (no PROPOSE node in V1.8:54-56)
- binding of working-memory (cognition.lisp:42) to SEAT-MEMORY (memory.lisp) relative to the v8 graph
- owner of the 12 intermediate cognition record types (ADJ-V18-NT-1)
- mapping of dimension-policy :authority strings to seats / external parties
- the contract's '16 ASDF systems / 53 edges' claim (contract:31) — 16 root .asd files confirmed; the 53 edges were not verified here


### DDI-4

#### cl-DDI-4 — Common-Lisp-native map of the 16 DDI-4 classes (124 forms)

Read-only reconnaissance against RO HEAD 4ee2b58a (tree ad71185a). Normative contract: `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md` (§2 rows :18-35; §1 language-independence :10-15; MOP forbidden without a named invariant :23,:40-41). Model target: `(fact <type> <id> :key value ...)`, values string|integer|plain symbol only, read with `*read-eval*` nil (MODEL-SCHEMA.sexp:4-7; deferred-imports.sexp:4; KERNEL/model-law-kernel.lisp:56). Every mechanism below cites a real seat (`file:line`) or says NOT FOUND/UNKNOWN. No production code was written. **No class requests MOP** (mop_requested = 0); two EXISTING MOP uses in source intersect DDI-4 and are raised as ADJ-CL4-01.

Dimension value grammar: `NOT-APPLICABLE` or `<mechanism> | invariant: <the invariant that requires it> | fallback: <fallback>`.

##### Counts

- classes: 16
- forms: 124
- mop_requested: 0
- python_in_cl_risks: 16
- python_in_cl_risks_yes: 15
- python_in_cl_risks_moderate: 1
- future_constraints: 10
- future_constraints_schedule_only: 3
- future_constraints_none: 3
- dimensions_applicable: 80
- dimensions_not_applicable: 112
- existing_mop_uses_in_source_intersecting_ddi4: 2

##### Reading key (seats cited most often)

- Model CL verification path: `ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp` (package aml-kernel :16; `v!` violation record :25; `*read-eval*` nil :56; add-fact L1/L2 :116-168; law2-unique :190; law3-closed-refs :200; edge-relations/law4-acyclic :211-228; law5-isolation :243). Data-declared laws: MODEL-SCHEMA.sexp define-conditional :26-30,293-316; define-unique :34-36,308,319-322.
- Contract seats verified in source/: cognition.lisp:35 frame, :42 working-memory, :57-63 *advisor*/advise, :78 build-frame-from-advice, :92-113 defgeneric plan/execute-step/synthesize/triage/critique; legal-inference-engine.lisp:78 unify, :199-204 justification, :206-238 tms-node/jtms/make-jtms, :347 recompute-beliefs, :456-465 legal-rule, :473-489 static rule legality, :491-506 defrule, :514-520 all-legal-rules (sb-mop); legal-event-calculus.lisp:43-64 defrule ec-*; journal.lisp:61-86 canon-sexp, :88 sha256-hex, :369 %check-monotonic-at!, :507-542 chained-append, :544 read-lines; safe-read.lisp:68-70 safe-read-error, :152-165 %with-data-env/%read-one; write-authority.lisp:16-51 emit-graph, :53 with-write-authority; memory.lisp:79-111 record-episode, :167-197 verify-episode-chain; capability-registry.lisp:40-48 capability struct, :54-61 +param-types+, :72-81 capability-seat-collision, :140-147 define-capability; greek-nlp-core.lisp:163-189 lexicon protocol, :387-394 analyzer; legal-ast.lisp:1548 defastnode, :1597-1627 with-ast-restarts; version-graph.lisp:7 bitemporal, :172-210 typed conditions, :1030 version-at; legal-temporal.lisp:41-53; constitutional-gate.lisp:22-47; mcp-server.lisp:80-91 define-mcp-tool; greek-legislation-ontology.lisp:57 defconcept; legal-dialectic.lisp:6-11,20; legal-extraction-verify.lisp:30-31,340; adoption-decision.lisp:23,85; deliberation.lisp:40-44 (metaclass).
- NOT FOUND: ingress-decoder.lisp; an SA-2/ADOPTED→CANONICAL state seat; condition/restart in legal-dialectic.lisp; an epoch in shacl-validator.lisp; any WP-file grep in gate_checks.py.

##### Per-class map

###### C1. `INTERFACE-AND-SCHEMA-REGISTRY__define-invariant`

**Source:** INTERFACE-AND-SCHEMA-REGISTRY.sexp:177-180 (:ISR-V6-closure, 1 form); ledger deferred-imports.sexp:7 DDI-4

| dimension | value |
|---|---|
| immutable_record | hash-pinned model fact in a module under ROOT.sexp composition (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:170-184 root-composition/load-facts; L7) ¦ invariant: L7 exact module/hash universe (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:64 law-id L7) ¦ fallback: existing `rationale` pointer fact (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:182-184; pattern rationale-references.sexp:3-7) — no text copy |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | NOT-APPLICABLE (a gate failure is a kernel violation record `v!` ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:25, not a signalled condition) |
| macro_dsl | NOT-APPLICABLE (registry forms are DATA read under *read-eval* nil (deferred-imports.sexp:4; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:56; safe-read.lisp:152-165) — never a macro expanded over the registry file) |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | NOT-APPLICABLE |
| truth_maintenance_dependency | NOT-APPLICABLE |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | kernel laws already evaluated at gate time over the ISR-derived type/component/consumes facts (deferred-imports.sexp:6 maps-to): L2 duplicate seat / id under two types (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:124,126; law2-unique :190 over define-unique data ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:34-36) + L3 closed refs (law3-closed-refs :200) ¦ invariant: :ISR-V6-closure clauses 'DEFINED here exactly once with an owner' and 'Referenced-but-undefined ⇒ FAIL' (ISR:178-180) ¦ fallback: none needed for those clauses (already mechanized — dossier A11/A12); the 'no adapter-specific (vendor) type is canonical' clause has NO mechanism: `type` has fields owner-subsystem/classification/consumer-role only (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:148-152) — UNKNOWN whether an origin enum is wanted |
| runtime_validation | NOT-APPLICABLE |

**python_in_cl_risk:** YES — a naive import writes `(fact invariant ISR-V6-closure :text "...")`: a string blob that duplicates two laws already mechanized (L2/L3) and invites a Python regex 'check' of the prose. CL-native alternative: no text fact at all — a `rationale` pointer (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:182-184; rationale-references.sexp:4 RAT-ONE-SEAT pattern) and, for the one unmechanized clause (vendor type), a NEW closed enum field on `type` (e.g. :origin CANONICAL|ADAPTER declared with define-enum ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:18) that the generic kernel enum path (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:152-155) validates — never a per-invariant checker.

**future_freedom (NONE):** NONE — restates L2/L3 over the interface universe. The vendor clause PROTECTS S20/V8I-02 (adapters stay replaceable, V1.8:17-19) provided it is mechanized as an origin enum, not as a closed list of vendor names (which would freeze the adapter roster). No S04/S19/JTMS constraint.

**evidence:** INTERFACE-AND-SCHEMA-REGISTRY.sexp:177-180; deferred-imports.sexp:6-7; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:34-36,64,148-152,182-184; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:25,56,124,126,170-184,190,200; rationale-references.sexp:3-7; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:18-35

###### C2. `SUBSYSTEM-REGISTRY__define-wp-purpose`

**Source:** SUBSYSTEM-REGISTRY.sexp:15-30 (WP-00..WP-14 + FUTURE_BOOK_REVISION, 16 forms; :purpose STRING + :owns requirement ranges); ledger deferred-imports.sexp:12 DDI-4

| dimension | value |
|---|---|
| immutable_record | hash-pinned `wp` fact extended with :purpose STRING (schema extension — `wp` has no fields, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:175) + NEW `wp-owns` facts (:wp ref wp, :requirement ref requirement), one fact per owned requirement ¦ invariant: L7 hash pin + L3 closed refs (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:24-25) ¦ fallback: keep :purpose in WP-NN.md (AUTHORED_NORMATIVE_PROSE files-and-roles.sexp:386) and import only wp-owns edges |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | NOT-APPLICABLE |
| macro_dsl | NOT-APPLICABLE (the range syntax 'R-1..R-6' at SR:15 is data the generator expands into one fact per requirement — not a reader macro; the model reader admits only string/integer/plain symbol, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:5) |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | NOT-APPLICABLE |
| truth_maintenance_dependency | NOT-APPLICABLE |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | L3 closed refs (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:200 law3-closed-refs) over wp-owns → requirement and L6 requirement→seat→test→WP closure (req-map ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:176-181; verification-corpus.sexp:42-44 PF-L6) at gate time ¦ invariant: :SR-V6-one-seat 'every :future-wp token resolves to a define-wp-purpose WP id' (SR:139-140) + :SR-V6-wp-honesty 'grounded in WP-NN.md, not asserted' (SR:142-145) ¦ fallback: today's 14 bare `wp` facts (requirements-tests-workpackets.sexp:52-65) with no ownership check |
| runtime_validation | NOT-APPLICABLE |

**python_in_cl_risk:** YES — naive import keeps :owns as an opaque STRING ('R-1..R-6 R-85..R-88 R-99 R-100' SR:15): a JSON-shaped range list nobody resolves, with two id formats in one file (R-1 at SR:15 vs R-01 at SR:16; dossier A17-SR-R-ID-FORMAT) and an ad-hoc range parser hidden in build_model.py. CL-native alternative: expand every range into typed `wp-owns` facts whose :requirement is an L3 closed ref into a FULL `requirement` universe (today only 24 requirement facts exist, requirements-tests-workpackets.sexp:5-28; R-1..R-134 has no model seat — it lives in prose: TRACEABILITY-MATRIX.md, IMPLEMENTATION-BOOK WP-NN.md:5), and declare the range grammar as DATA (as classification-rules.sexp declares its match grammar, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:80-83) so the generic kernel ref check validates it.

**future_freedom (SCHEDULE):** SCHEDULE ONLY — binds concept→WP ownership, not mechanisms. S19 memory = FUTURE_BOOK_REVISION (SR:30; SR:98-99 'FUTURE BOOK REVISION REQUIRED before construction') is a construction block, not a design constraint; WP-07 :purpose pins 'Python+ONNX … MUST become optional adapter' (SR:22), which is freedom-preserving w.r.t. V8I-02. Importing WP-00/WP-05/WP-10 (absent from model `wp` facts) widens the wp universe (L3/L6 effects). No JTMS/S04/S20 mechanism constraint.

**evidence:** SUBSYSTEM-REGISTRY.sexp:11-30,98-99,118,139-145; deferred-imports.sexp:12; requirements-tests-workpackets.sexp:5-28,52-65,85; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:5,24-25,80-83,175-181; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:200; files-and-roles.sexp:386; IMPLEMENTATION-BOOK/WORK-PACKETS/WP-08.md:5

###### C3. `SUBSYSTEM-REGISTRY__define-file-disposition`

**Source:** SUBSYSTEM-REGISTRY.sexp:130-134 ("legal-casegrammar.lisp" :was DEFER_PRIVATE :now SPLIT :public→S04 :private→S22 :no-copy, 1 form); ledger deferred-imports.sexp:9 DDI-4; duplicate seat V1.6-SCHEMAS.sexp:247-250 define-rule casegrammar-split

| dimension | value |
|---|---|
| immutable_record | NEW `file-disposition` fact (:file PATH, :was/:now closed enum incl. SPLIT, :public-subsystem/:private-subsystem refs subsystem, :no-copy yes-no) hash-pinned, define-unique on :file ¦ invariant: L1 closed enums (SPLIT is absent from migration-disposition = KEEP EXTEND DEFER_PRIVATE, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:51) + L2 one disposition per path ¦ fallback: two `component` facts under S04/S22 (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:144-147) |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | NOT-APPLICABLE |
| macro_dsl | NOT-APPLICABLE |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | the FUTURE execution of SPLIT is a package/ASDF split: the general mechanisms stay in :orchestrator.casegrammar (legal-casegrammar.lisp:29-37, exports parse-narrative/parse-definition/parse-provision) inside the public system; client-fact schemas + matter-solving move to a private package in a system that no public system :depends-on (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:31 'package boundary = capability boundary'; [0146]-claude.md:18 '16 systems, 53 edges, cycle NONE') ¦ invariant: :no-copy 'no second implementation; private consumes the public general mechanisms' (SR:134) + V6I-16 acyclic public→private boundary (V1.6:334-338) + model L5 (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:243 law5-isolation) ¦ fallback: one package with export discipline and a documented private section — which is today's state: every cognition seat lives in ONE serial system (orchestrator-infrastructure.asd:44 :serial t; :105 legal-casegrammar, :113 constitutional-gate, :114 cognition, :115 memory) — no ASDF-level seat for the split exists |
| persistent_event | NOT-APPLICABLE |
| truth_maintenance_dependency | NOT-APPLICABLE |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | ASDF dependency-graph cycle check (contract test 'ASDF graph cycle check (exit 0)', LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:31) + kernel L5 over consumes once the private package's types are PRIVATE `type` facts (verification-corpus.sexp:45-47 PF-L5) ¦ invariant: public system never depends on the private system (V6I-07 V1.6:38-40) ¦ fallback: runtime package-export check |
| runtime_validation | NOT-APPLICABLE |

**python_in_cl_risk:** YES — SPLIT rendered as a free string (or dropped because it is not in the enum), and :public/:private carried as prose blobs ('general Greek morphology … -> S04 …') instead of typed subsystem refs. CL-native alternative: L3 refs to S04/S22, yes-no enum for :no-copy (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:71), and the SPLIT member added to a disposition enum AS DATA in MODEL-SCHEMA.sexp — never a Python special case in the generator.

**future_freedom (MECHANISM):** CONSTRAINS S04 (cognition) file/package layout: the morphology/case-frame layer must be a public package consumed by the private layer (COG-3/COG-4 seats 'legal-casegrammar.lisp[general]' V1.6:220-221; V1.7:85). This PRESERVES the public/private one-way boundary and S22's deferral. No S19/JTMS/S20 constraint. Precondition: the duplicate seat (SR:130-134 vs V1.6:247-250) must be adjudicated to ONE (dossier A11-SR-CASEGRAMMAR-SPLIT-SEAT).

**evidence:** SUBSYSTEM-REGISTRY.sexp:129-134; V1.6-SCHEMAS.sexp:167,220-221,247-250,334-338; V1.7-SCHEMAS.sexp:85; source/legal-casegrammar.lisp:29-37; orchestrator-infrastructure.asd:44,105,113-115; files-and-roles.sexp:1077 (DR-0060 source/ PRODUCTION_CODE); ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:51,71,144-147; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:243; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:31; deployment/collab/dialogue/0146-claude.md:18

###### C4. `SUBSYSTEM-REGISTRY__define-invariant`

**Source:** SUBSYSTEM-REGISTRY.sexp:136-145 (:SR-V6-one-seat, :SR-V6-wp-honesty, 2 forms); ledger deferred-imports.sexp:10 DDI-4; AM anchors rationale-references.sexp:4-5 (RAT-ONE-SEAT, RAT-WP-HONESTY) consumed by seats.sexp:77-88,99

| dimension | value |
|---|---|
| immutable_record | the EXISTING `rationale` pointer facts (rationale-references.sexp:4-5) are already the seat; the prose stays in SR (V6I-17: prose not duplicated, rationale-references.sexp:1-2) ¦ invariant: one seat per concept (the invariant's own first clause, SR:137) + constitution :no-duplicate (LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:26) ¦ fallback: a NEW invariant fact carrying :text — which would be a second seat for the same prose |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | NOT-APPLICABLE |
| macro_dsl | NOT-APPLICABLE (registry forms are DATA read under *read-eval* nil (deferred-imports.sexp:4; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:56; safe-read.lisp:152-165) — never a macro expanded over the registry file) |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | NOT-APPLICABLE |
| truth_maintenance_dependency | NOT-APPLICABLE |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | one-seat: kernel L2 (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:124 duplicate seat; :190 law2-unique reading define-unique data ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:308 SEAT-PATH-UNIQUE, :319 STORE-OWNER-IS-ONE-SEAT) — ALREADY enforced; wp-honesty: a NEW data-declared closure rule 'every req-map.wp owns req-map.requirement via wp-owns' (needs C2 facts) evaluated by the generic kernel ¦ invariant: SR:139-140 'the architecture gate rejects a dangling or invented WP'; SR:142-145 'grounded, not asserted' ¦ fallback: audit V6S11 in V1.6-CONTRADICTION-OMISSION-AUDIT.sh — HISTORICAL_EVIDENCE, NON_AUTHORITATIVE (files-and-roles.sexp:440) |
| runtime_validation | NOT-APPLICABLE |

**python_in_cl_risk:** YES if the two docstrings become :text blobs beside the pointers (duplicate seat) or if wp-honesty is 'checked' by a hand-written Python loop over strings. CL-native alternative: keep the pointer facts; mechanize wp-honesty as a declared rule in MODEL-SCHEMA.sexp data (define-unique/define-conditional style, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:26-36) that both verification paths evaluate generically (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:1-2 forbids shared evaluator code, permits shared specification).

**future_freedom (NONE):** NONE — the invariant FIXES the one-seat identity of S19 memory (memory.lisp EXTEND, SR:138 = SEAT-MEMORY seats.sexp:56) and S04 cognition ('existing engine EXTEND' = SEAT-LEGAL-AST seats.sexp:32); that is the intended guard against a second engine/memory (contract JTMS row LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:28). No S20/V8I-02 constraint.

**evidence:** SUBSYSTEM-REGISTRY.sexp:136-145; deferred-imports.sexp:10; rationale-references.sexp:1-5; seats.sexp:32,56,77-88,99; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:1-2,26-36,308,319; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:124,190; files-and-roles.sexp:440; deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:26

###### C5. `V1.5-SCHEMAS__define-invariant`

**Source:** V1.5-SCHEMAS.sexp: 22 forms — D1 :V5I-D1-both 70, :V5I-D1-indep 100, :V5I-F7-derivation-trust 105, :V5I-01 115, :V5I-D1-unregistered-event 152, :V5I-D1-no-assumption-canonical 155, :V5I-02 161; D2 :V5I-04 246, :V5I-05 254; D3 :V5I-D3-bind 287, :V5I-D3-issuer-signing 293, :V5I-D3-domainassertion 346, :V5I-D3-unknown 406, :V5I-06 433, :V5I-07 437; C1 :V5I-C1-canon 487, :V5I-C1-relation-detached 522, :V5I-A2-immutable-id 554, :V5I-C1-acyclic 610, :V5I-08 618, :V5I-09 622; GLOBAL :V5I-10 641; ledger deferred-imports.sexp:22 DDI-4

| dimension | value |
|---|---|
| immutable_record | hash-pinned invariant/anchor facts (ids rendered without the colon — TOKEN charset ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:17 has no ':'); for the C1 subset the invariant is ABOUT immutability: V5I-A2/V5I-C1-* ⇒ compiler-A-private mechanism = read-only structs (pattern capability-registry.lisp:40-48 `:read-only t`) whose *_id = sha256(canon-sexp(BODY)) via journal.lisp:61-86 canon-sexp + :88 sha256-hex (contract LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:27 'identity = content-address; lifecycle detached (v1.5 R2)') ¦ invariant: :V5I-A2-immutable-id (V1.5:554-558) + :V5I-C1-acyclic (610-616) + candidate-id-discipline formula (V1.5:141-142) ¦ fallback: copy-on-write plain lists; the content-address must stay language-independent so compiler B reaches the same root (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:10-15 §1; :34 dual-compiler root equality) |
| clos_class | NOT-APPLICABLE (no V1.5 invariant requires a class; ClaimRecord/ArgumentRecord are DDI-2 records — a CLOS class would need the contract's CLOS row invariant 'one class per concept', not requested here) |
| generic_function | NOT-APPLICABLE |
| condition_restart | the fail-closed outcomes these invariants mandate are VALUES of closed enums (QUARANTINED, INDEPENDENCE_UNKNOWN, INDEPENDENCE_INSUFFICIENT — DivergenceState V1.5:111-113, unknown_handling 403-405), i.e. the contract's 'return typed error value' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:24) as the PRIMARY form; a typed condition class is needed only where an SA-2 admission must UNWIND a write in progress ('semantic-admission-obligation-unmet' V1.5:72) — pattern: typed conditions version-graph.lisp:184-205 (temporal-uncertainty, scope-uncertain with typed slots :197-205) ¦ invariant: :V5I-D1-both 'Missing either ⇒ … QUARANTINED' (V1.5:71-72); :V5I-D3-unknown 'explicit downgrade, never a silent pass' (406-409) ¦ fallback: typed error value |
| macro_dsl | NOT-APPLICABLE (registry forms are DATA read under *read-eval* nil (deferred-imports.sexp:4; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:56; safe-read.lisp:152-165) — never a macro expanded over the registry file) |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | V5I-09 + V5I-A2: adoption/withdrawal is a NEW LifecycleRecord appended in the existing InstitutionalAct + L2 event-ledger seat (V1.5:527-529); CL seat = journal.lisp:507-542 chained-append (compare-and-append; stale-chain-link :534-541) through the ONE write seat write-authority.lisp:16-51 (mandatory :authority) — adoption records already exist: adoption-decision.lisp:85 record-adoption! ¦ invariant: :V5I-A2 'Flipping adoption/withdrawal emits a NEW LifecycleRecord and CANNOT change the subject's *_id' (V1.5:557-558) ¦ fallback: full replay of the record list (journal.lisp:544 read-lines) |
| truth_maintenance_dependency | V5I-02/V5I-08/V5I-C1-relation-detached: support/attack relations live in the L5/L6 proof-dependency graph = the EXISTING JTMS (legal-inference-engine.lisp:199-204 justification in-list/out-list; :227 jtms; :238 make-jtms; :347 recompute-beliefs; Dung-grounded reading legal-dialectic.lisp:6-11): ArgumentRelation :supports → in-list, :attacks → out-list; INTERPRETIVE_DISAGREEMENT stays :undefined (WFS undefined set legal-inference-engine.lisp:233-236), never majority vote ¦ invariant: :V5I-02 'never resolved by majority vote' (V1.5:161-164); :V5I-08 'no forced winner' (618-621) ¦ fallback: full recompute (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:28) |
| temporal_index_projection | SubjectCurrentStatus = fold of the LifecycleRecord chain over legal_time × audit_time (V1.5:536,540-543) = a bitemporal projection on the existing seat version-graph.lisp:7 ('[valid-from,valid-until) × [recorded-from,recorded-until)'), :1030 version-at (valid-at/known-at) ¦ invariant: :V5I-09 adoption changes status, NOT objective truth (V1.5:622-625); :V5I-A2 no retroactive identity change ¦ fallback: linear scan of the chain |
| compile_time_validation | the STRUCTURAL subset at gate time: :V5I-C1-acyclic ⇒ kernel law4-acyclic (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:219; edge-relations :211 treat every from/to relation as an acyclicity duty) over hash-bearing ref edges once DDI-2 imports define-ref-classification (V1.5:569-594) as edge facts; :V5I-A2 ⇒ define-conditional :forbid (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:26-30) forbidding status/adoption fields on identity-bearing records; :V5I-D1-no-assumption-canonical ⇒ the gate fact (C7) whose :requires structurally excludes residual_independence_assumption ¦ invariant: the three 'STRUCTURAL' / 'kill' clauses (V1.5:156, 611, 616) ¦ fallback: V1.5-CONTRADICTION-OMISSION-AUDIT.sh — HISTORICAL_EVIDENCE, rule R-012, NON_AUTHORITATIVE (files-and-roles.sexp:436), so no authoritative executor exists today |
| runtime_validation | the D3 subset (:V5I-D3-bind/issuer-signing/domainassertion/unknown, :V5I-06/07) and :V5I-F7 are production-time signature / pinned-registry / freshness / revocation checks in the MLTP verifier seat (SEAT-KERNEL-VERIFY deployment/verify/kernel-verify.lisp, seats.sexp:44; SR:66 'TrustBundle/1 + LocalTrustState + suite registry') — fail-closed to INDEPENDENCE_UNKNOWN ¦ invariant: :V5I-06 'Distinct kid does NOT prove independence … Insufficient evidence ⇒ INDEPENDENCE_UNKNOWN' (V1.5:433-436) ¦ fallback: reject / never count (V1.5:407-409) |

**python_in_cl_risk:** YES — 22 docstrings as :text STRING blobs whose kill ids (V5KW-*) and audit ids (V5G, V5S-D1a) dangle (no such `test` facts: requirements-tests-workpackets.sexp:30-50), followed by ad-hoc Python re-implementations of the 'STRUCTURAL' clauses in gate_checks.py. CL-native alternative: split each invariant into (a) a pointer/anchor fact and (b) its mechanization as DATA the generic kernel already evaluates — define-unique / define-conditional / from-to edge relations (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:26-36; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:211-228) — so :V5I-C1-acyclic is an L4 relation over ref-edge facts and :V5I-A2 a forbid rule, never a string.

**future_freedom (MECHANISM):** CONSTRAINS the reasoning seat in the intended direction: :V5I-08/02 forbid a forced winner and majority vote — exactly what the JTMS/WFS engine provides (:undefined). :V5I-C1-canon forbids an invented universal Greek canon priority (V1.5:491) — binds S04 interpretation to adopted ConflictPolicyBundle (also WP-08.md:18). :V5I-10 fixes the de-jure boundary. No mandatory-model, S19 or S20 constraint. RISK: :V5I-04/05 are tied to census-coverage-decision, superseded by V1.7:259-279 census-coverage-decision-v7 (dossier V5-A2) — importing both as live invariants would bind the census seat twice.

**evidence:** V1.5-SCHEMAS.sexp:70-72,100-109,111-120,141-142,152-164,246-260,287-298,346-351,403-409,433-440,487-493,522-525,527-529,536,540-543,554-558,569-594,610-625,641-645; deferred-imports.sexp:22; source/legal-inference-engine.lisp:199-204,227-238,233-236,347; source/legal-dialectic.lisp:6-11; source/journal.lisp:61-90,507-544; source/write-authority.lisp:16-51; source/adoption-decision.lisp:85; source/version-graph.lisp:7,184-205,1030; source/capability-registry.lisp:40-48; seats.sexp:44; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:17,26-36; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:211-228; requirements-tests-workpackets.sexp:30-50; files-and-roles.sexp:440,444,453; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:10-15,24,27,28,34

###### C6. `V1.5-SCHEMAS__define-rule`

**Source:** V1.5-SCHEMAS.sexp: derivation-independence-trust-root 87-99 (5 clauses), candidate-id-discipline 140-145 (2), unregistered-state-event 148-151 (1), domain-namespace-comparison 333-345 (6), trusted-issuer-registry-pinning 367-375 (4), revocation-semantics 378-383 (3), lifecycle-overlay 544-553 (6); ledger deferred-imports.sexp:28 DDI-4

| dimension | value |
|---|---|
| immutable_record | NEW `rule` (id, owner-subsystem) + `rule-clause` (rule, key SYMBOL, text STRING) facts, hash-pinned; candidate-id-discipline's identity formula hex(sha256(id_domain‖0x1F‖canonical(BODY))) (V1.5:141-142) IS the content-address rule whose CL seat is journal.lisp:61-86 canon-sexp + :88 sha256-hex (the ONE canonical serialization boundary, LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:34) ¦ invariant: candidate-id-discipline :target 'no ambient/implicit candidate' (V1.5:143-145) + :V5I-A2 ¦ fallback: explicit encoder per record (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:34 fallback) |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | the :fail-closed clauses yield typed outcome VALUES (INDEPENDENCE_UNKNOWN, 'evidence does NOT count'); a condition only if a bundle verification must abort mid-way — pattern safe-read.lisp:68-70 safe-read-error caught into (values nil :unreadable) at :214 ¦ invariant: revocation-semantics :fail-closed 'treated as UNKNOWN (never silently counted)' (V1.5:382-383); derivation-independence-trust-root :fail-closed (98-99) ¦ fallback: typed error value (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:24) |
| macro_dsl | ONLY IF these rules are to be EXECUTED by the engine (not merely anchored): the admitted DSL is `defrule` (legal-inference-engine.lisp:491-506 → a legal-rule class :456-465 with STATIC legality at instantiation :473-489; exemplar legal-event-calculus.lisp:43-64 ec-initiation/ec-clipping/ec-holds) — 'rules as inspectable data' expanded at compile/load time, never over registry bytes ¦ invariant: 'rules are data, not opaque code' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:26) + 'macros expand at compile time only; NEVER over external bytes' (:25) ¦ fallback: procedural branch (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:26) — NOTE: defrule rule DISCOVERY uses sb-mop:class-direct-subclasses (legal-inference-engine.lisp:514-520) while the contract's MOP row says 'NOT USED in the trusted path — (none)' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:23) → ADJ-CL4-01 |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | lifecycle-overlay (V1.5:544-553): each transition (:propose/:adopt/:withdraw/:correct/:revoke/:supersede) is an appended LifecycleRecord whose :supersedes is the back-link — journal.lisp:507 chained-append (:back-link/:identity keys :507, stale-chain-link :534-541); trusted-issuer-registry-pinning :update 'monotonic: new registry_id with supersedes = the pinned one' (V1.5:371-372) is the same idiom ¦ invariant: lifecycle-overlay :revocation 'historical records survive; no retroactive identity change' (V1.5:550-551) ¦ fallback: full replay (journal.lisp:544 read-lines) |
| truth_maintenance_dependency | NOT-APPLICABLE (validity predicates and state overlays, not belief revision) |
| temporal_index_projection | lifecycle-overlay 'withdrawn-by-revocation from audit_time forward' (V1.5:550) and the validity windows [valid_from, valid_to] + freshness in derivation-independence-trust-root :validity (V1.5:95-97) are as-of predicates over the bitemporal seat (version-graph.lisp:1030 version-at; legal-temporal.lisp:48-53 date-in-interval-p, half-open) ¦ invariant: :validity 'now in [valid_from, valid_to] AND fresh … AND not revoked' (V1.5:95-97) ¦ fallback: linear scan |
| compile_time_validation | the clause-key set of each rule becomes a CLOSED field set (L1: per-rule fact type or a closed enum of clause keys) so a missing/misspelled clause is a typed L1 violation (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:137,157) ¦ invariant: L1 'a parsed-but-ignored field is silent loss' (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:12) ¦ fallback: free text |
| runtime_validation | derivation-independence-trust-root :validity/:issuer-scope/:self-issued, trusted-issuer-registry-pinning, revocation-semantics :verify, domain-namespace-comparison are production verifier predicates in the MLTP seat (SEAT-KERNEL-VERIFY seats.sexp:44); their consumer control-domain-partition (V1.5:387-400) is DDI-3 — fail-closed ¦ invariant: :fail-closed clauses (V1.5:98-99, 338-340, 382-383) ¦ fallback: reject |

**python_in_cl_risk:** YES — 27 clauses as a JSON dict {clause-key: text} per rule, then the 'VALID :=' formula (V1.5:95-97) re-typed as an imperative Python validator in the V1.x-VERIFY lineage (HISTORICAL_EVIDENCE files-and-roles.sexp:453). CL-native alternative: clause facts with closed keys (L1) and, where a rule is executable, `defrule`-style declarative patterns whose :where guards are typed :bool at load time (legal-inference-engine.lisp:477-479) and recorded in the proof (:495-496) — the rule is inspectable data, its evaluation is the ONE engine.

**future_freedom (MECHANISM):** CONSTRAINS S10 (trust): two rules bind to LocalTrustState / MLTP qualification registry (V1.5:88-89, 368) which no registry declares (dossier V5-A7). lifecycle-overlay binds InstitutionalAct + event-ledger (existing seats). candidate-id-discipline fixes the content-address formula that compiler B must mirror semantically (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:10-15) — a permanent cross-language constraint by design. No S04/S19/S20 mechanism constraint; no mandatory model.

**evidence:** V1.5-SCHEMAS.sexp:87-99,140-151,333-345,367-383,387-400,544-553; deferred-imports.sexp:28; source/legal-inference-engine.lisp:456-465,473-489,491-506,514-520; source/legal-event-calculus.lisp:37-64; source/journal.lisp:61-90,507-544; source/safe-read.lisp:68-70,214; source/version-graph.lisp:1030; source/legal-temporal.lisp:48-53; seats.sexp:44; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:137,157; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:12; files-and-roles.sexp:453; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:10-15,23-26,34

###### C7. `V1.5-SCHEMAS__define-gate`

**Source:** V1.5-SCHEMAS.sexp:123-137 (SA-2-canonical-admission :from :ADOPTED :to :CANONICAL; :requires 5 items incl. nested (divergence_state :is :AGREED); :verify prose; :forbids-alternative; :assumption-disposition nested; :note; 1 form); ledger deferred-imports.sexp:21 DDI-4

| dimension | value |
|---|---|
| immutable_record | NEW `gate` fact (:from/:to symbols of a lifecycle-state enum, :verify-rule ref to the C6 rule fact, :forbids-alternative field SYMBOL) + `gate-requires` facts (:gate, :field, optional :value from DivergenceState) + `gate-disposition` facts — hash-pinned; the gate's subject is content-addressed (candidate-id-discipline V1.5:140-145) so it binds an immutable candidate ¦ invariant: :V5I-01 (V1.5:115-120) + :V5I-D1-no-assumption-canonical (155-160) ¦ fallback: prose in the D1 contract (LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md, named V1.5:11) |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE (no invariant requires dispatch on assurance profile; the per-profile decision is a data table — the cardinality matrix V1.5:45-62, DDI-2) |
| condition_restart | gate failure ⇒ QUARANTINED VALUE (:V5I-01 'a schema-valid but wrong SA-2 event is QUARANTINED' V1.5:119-120); NO restart is admissible — a restart offering 'use the assumption' would be the structural error the gate exists to exclude (:forbids-alternative V1.5:133) ¦ invariant: :V5I-D1-no-assumption-canonical 'contains NO assumption alternative' (V1.5:155-160) ¦ fallback: typed error value |
| macro_dsl | NOT-APPLICABLE (the gate is a data table evaluated by a generic evaluator; no invariant requires a `define-gate` macro in the image; registry forms are DATA read under *read-eval* nil (deferred-imports.sexp:4; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:56; safe-read.lisp:152-165) — never a macro expanded over the registry file) |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | the ADOPTED→CANONICAL transition is itself a journaled adoption event (adoption_act_ref REQUIRED, V1.5:129) through the ONE write seat (write-authority.lisp:53 with-write-authority; adoption-decision.lisp:85 record-adoption!) ¦ invariant: V6I-08 'journaled adoption + rollback' (V1.6:41-42) + :V5I-09 ¦ fallback: replay |
| truth_maintenance_dependency | NOT-APPLICABLE |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | gate-time: every gate-requires :field must be a declared field of SemanticAdmissionEvidence/1 (V1.5:33-41) with SA-2 cardinality :R or :C in the matrix (V1.5:45-62, DDI-2) — an L3 closed ref to a record-field fact; :forbids-alternative must NOT occur among gate-requires (define-conditional :forbid, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:26-30) ¦ invariant: :V5I-D1-no-assumption-canonical 'STRUCTURAL' (V1.5:156) ¦ fallback: prose review |
| runtime_validation | :verify (V1.5:130-132): resolve derivation_independence_evidence_ref and VERIFY signature / issuer in qualification registry / scope / freshness / revocation / candidate binding — a production verifier in the MLTP seat (SEAT-KERNEL-VERIFY seats.sexp:44); presence of the reference is NOT sufficient (R7.6) ¦ invariant: :V5I-F7 'the gate VERIFIES the evidence, not merely the presence of a reference' (V1.5:108) ¦ fallback: reject (fail-closed) — a source seat for the ADOPTED/CANONICAL/CANDIDATE/QUARANTINED states: NOT FOUND (adoption-decision.lisp exposes can-adopt :23 / record-adoption! :85 only; grep 'SA-2¦:ADOPTED' over source/ and systems/ = no hit) |

**python_in_cl_risk:** YES — the nested :requires item (divergence_state :is :AGREED) and :assumption-disposition (:candidate-only (...)) are flattened into strings or silently dropped (L1 forbids nested lists, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:6), and the :verify prose becomes an imperative Python function. CL-native alternative: one `gate-requires` fact per requirement (:field ref + optional :value validated against the DivergenceState enum), the disposition as a closed enum, and the verifier obligation as an L3 ref to the C6 rule fact derivation-independence-trust-root — all validated by the kernel's generic ref/enum paths.

**future_freedom (MECHANISM):** CONSTRAINS the ADMIT stage (dependencies-and-boundaries.sexp:7 stage ADMIT; edges :15 ACQUIRE→ADMIT and :16 ADMIT→IR) to evidence-only promotion — no S04/S19/JTMS mechanism constraint; it STRENGTHENS V8I-02 (no proposer can promote). Precondition: the lifecycle states ADOPTED/CANONICAL/CANDIDATE/UNKNOWN/QUARANTINED are declared in no registry (dossier V5-A6) — importing the gate forces that enum to be seated first (ADJ-CL4-11).

**evidence:** V1.5-SCHEMAS.sexp:11,33-41,45-62,108,115-120,122-137,140-145,155-160; V1.6-SCHEMAS.sexp:41-42; deferred-imports.sexp:21; source/adoption-decision.lisp:23,85; source/write-authority.lisp:53; seats.sexp:44; dependencies-and-boundaries.sexp:7,15-16; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:6,26-30

###### C8. `V1.5-SCHEMAS__define-constitution-reference`

**Source:** V1.5-SCHEMAS.sexp:630-638 (v1.5-interpretive-binding, flat, 8 keys; 1 form); duplicate seat deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:358-368 (14 keys incl. :status/:not-frozen/:frozen-baseline, :second-seat nil, :machine-readable, :spec); ledger deferred-imports.sexp:17 DDI-4

| dimension | value |
|---|---|
| immutable_record | pointer fact: existing `rationale` (:doc "deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp" :anchor "v1.5-interpretive-binding") — PURE_DATA under ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:182-184 ¦ invariant: V6I-17 prose not duplicated (rationale-references.sexp:1-2) + constitution :no-duplicate (LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:26) ¦ fallback: NEW `constitution-binding` fact carrying the three record refs (L3 → type) and the three flags as yes-no (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:71) |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | NOT-APPLICABLE |
| macro_dsl | NOT-APPLICABLE |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | NOT-APPLICABLE |
| truth_maintenance_dependency | the binding's :invariant says L6 Adversarial Parliament consumes ArgumentRecords 'as typed arguments with proof/counterproof' and :adds-engine nil (V1.5:635-638): the CL consumer is the EXISTING jtms (legal-inference-engine.lisp:227-238) read dialectically (legal-dialectic.lisp:6-11 'Dung grounded semantics = the well-founded fixpoint the engine already runs') — ArgumentRecord → tms-node datum, ArgumentRelation → justification in/out lists ¦ invariant: :adds-engine nil / :adds-gate nil (V1.5:635) + :SR-V6-one-seat 'S04 cognition has ONE seat (existing engine EXTEND)' (SR:138) ¦ fallback: full recompute |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | gate-time: :by-record/:claims-record/:profile-record resolve to declared `type` facts (L3) and the three flags are NO (yes-no enum); :represents-primitive resolves to a member of the Constitution :primitives list (LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:14) if that list is imported as a define-enum ¦ invariant: :adds-primitive/:adds-engine/:adds-gate nil (V1.5:635) ¦ fallback: prose review — the two seats disagree in key set (8 vs 12 keys); adjudicate V5-A11 first (ADJ-CL4-10) |
| runtime_validation | NOT-APPLICABLE |

**python_in_cl_risk:** MODERATE — the nil flags become NIL (forbidden, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:6) or Python False, and :represents-primitive :argument (a keyword) is stringified. CL-native alternative: yes-no enum values and a plain symbol ARGUMENT validated against a closed enum of Constitution primitives (LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:14) — or, simpler and one-seat, only the rationale pointer.

**future_freedom (NONE):** NONE (preserving) — it forbids a second reasoning engine and a new gate (V1.5:635), binding interpretation to the existing JTMS/L5-L6 seat; no S19/S20/V8I-02 constraint.

**evidence:** V1.5-SCHEMAS.sexp:627-638; deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:14,26,353-368; deferred-imports.sexp:17; rationale-references.sexp:1-2; SUBSYSTEM-REGISTRY.sexp:138; source/legal-inference-engine.lisp:227-238; source/legal-dialectic.lisp:6-11; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:6,71,182-184

###### C9. `V1.6-SCHEMAS__define-invariant`

**Source:** V1.6-SCHEMAS.sexp: 21 forms — :V6I-01 15, :V6I-02 17, :V6I-03 25, :V6I-04 29, :V6I-05 32, :V6I-06 35, :V6I-07 38, :V6I-08 41, :V6I-09 43, :V6I-10 75, :V6I-11 151, :V6I-12 155, :V6I-REF 158, :V6I-13 261, :V6I-COG-symbolic-only 265, :V6I-COG-one-to-one 270, :V6I-14 297, :V6I-15 301, :V6I-MEM-public-base-clean 305, :V6I-16 334, :V6I-17 348; ledger deferred-imports.sexp:33 DDI-4

| dimension | value |
|---|---|
| immutable_record | hash-pinned anchor facts; :V6I-11 'identity = content-address of the immutable BODY … lifecycle detached' (V1.6:151-154) ⇒ compiler-A-private read-only structs + journal.lisp:61-90 canon-sexp/sha256-hex; :V6I-05/14 memory ⇒ the existing chained episode stream memory.lisp:95-111 (chained-append, :hv 2 canon-sexp hash inside the sealed body :102-106) ¦ invariant: :V6I-11 (V1.6:151-154) + :V6I-14 'byte-verifiable memory continuity' (297-300) ¦ fallback: copy-on-write; full-chain verification memory.lisp:167-197 verify-episode-chain |
| clos_class | NOT-APPLICABLE (:V6I-09 'adapter, capability or profile' is realised by the CLOS protocol of C10, not by these invariants) |
| generic_function | NOT-APPLICABLE |
| condition_restart | :V6I-06 'yields UNKNOWN / CONFLICTING / QUARANTINED / a clarification question — never a guess' (V1.6:35-37) and the CognitionError taxonomy (V1.6:177-181, DDI-2) are typed VALUES; a typed condition + restart is admitted only at the clarification unwind COG-10-CLARIFY 'legal-dialectic.lisp + condition/restart' (V1.6:227, :242) — pattern legal-ast.lisp:1597-1627 with-ast-restarts (restart-case; the :interactive restart reads DATA-ONLY via safe-read :1619-1626) ¦ invariant: :V6I-06 ¦ fallback: typed error value — NOTE legal-dialectic.lisp (4648 B) defines only dialectic-report (:20) and NO condition/restart; restart-case occurs only in greek-tokenizer-advanced.lisp, legal-ast.lisp, trace-core.lisp → the named seat is a DESIGN TARGET (ADJ-CL4-03) |
| macro_dsl | the NEGATIVE rule: :V6I-04/:V6I-10 'passes EXCLUSIVELY through the non-evaluating ingress decoder (no cl:read/eval/macro/compile)' (V1.6:31,64) — seat safe-read.lisp:152-165 (*read-eval* nil, data readtable, the ONE cl:read :163-165); ingress-decoder.lisp named by LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:35 is NOT FOUND in source/ (only deployment/LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md exists) ¦ invariant: 'no cl:read/eval/reader-macro/compile/macroexpand on external bytes' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:35) ¦ fallback: reject input (fail-closed) |
| protocol | NOT-APPLICABLE (see C10 define-protocol) |
| package_asdf_boundary | :V6I-07/:V6I-15/:V6I-16/:V6I-MEM-public-base-clean/:V6I-12: the public build must not depend on private/embodiment/vendor — ASDF system boundary + package exports (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:31; [0146]-claude.md:18) and the model's L5 (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:243 law5-isolation; verification-corpus.sexp:45-47 PF-L5-PRIVATE-TYPE-LEAK) ¦ invariant: :V6I-16 'the boundary is ACYCLIC' (V1.6:334-338) ¦ fallback: single package with export discipline — today's state: cognition/memory/casegrammar/inference all load in ONE serial system (orchestrator-infrastructure.asd:44,88,105,114,115) |
| persistent_event | :V6I-05/:V6I-08/:V6I-14: canonical memory writes ONLY by the write authority; self-improvement 'journaled adoption + rollback' — seats write-authority.lisp:16-51 (mandatory :authority, closed set :35-38) + :53 with-write-authority; memory.lisp:79-111 record-episode via journal chained-append; adoption-decision.lisp:85 record-adoption! ¦ invariant: :V6I-14 'canonical MemoryEvent/1 writes are made ONLY by the authorized write authority' (V1.6:297-300) ¦ fallback: replay (journal.lisp:544 read-lines) |
| truth_maintenance_dependency | :V6I-06 proof/counterproof + :V6I-10 'the epistemic wall judges symbolically' — a candidate enters belief only after legal-extraction-verify (verdict struct legal-extraction-verify.lisp:340; exports :30-31 verify-proposal/verdict-accepted-p) and then as a JTMS node (legal-inference-engine.lisp:206-238) ¦ invariant: :V6I-10 'A malicious proposer produces ZERO canonical writes' (V1.6:75-78) ¦ fallback: full recompute |
| temporal_index_projection | :V6I-14/:V6I-15 MemoryEvent/1 valid_time × known_time (V1.6:105 'bitemporal (reuse L2)') and MemoryProjection :as_of (V1.6:295) = a bitemporal projection over the memory stream; pattern version-graph.lisp:1030 version-at (valid-at/known-at) ¦ invariant: :V6I-14 'Replacing any model MUST preserve byte-verifiable memory continuity' ¦ fallback: linear fold over episodes (memory.lisp:113 episodes :fold) |
| compile_time_validation | mechanizable subset at gate time: :V6I-REF 'defined as BOTH a record and a reference, or twice ⇒ REJECTED' (V1.6:158-162) → L2 id-owned-by-one-type (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:126) once DDI-2 imports records/references as facts; :V6I-COG-one-to-one → define-unique over the DDI-2 define-mapping facts; :V6I-17 orphans/dual seats/undocumented deps → L2/L3/L6 (already model laws) ¦ invariant: those three clauses ¦ fallback: audits V6S12-V6S17 in V1.6-CONTRADICTION-OMISSION-AUDIT.sh — HISTORICAL_EVIDENCE (files-and-roles.sexp:440) |
| runtime_validation | :V6I-02/:V6I-03/:V6I-COG-symbolic-only: removing every proposer leaves SYMBOLIC_ONLY functional — runtime seat cognition.lisp:57-61 (*advisor* nil = 'purely symbolic operation (no dependency)') + decompose :70-77 (symbolic classifiers first, advisor last and verified); :V6I-04 adapters hold no keys/write authority — write-authority.lisp:16-51 refuses any write without :authority ¦ invariant: :V6I-02 (V1.6:17-19) ¦ fallback: fail-closed to :SYMBOLIC_ONLY (SR:44 S03 rollback; SR:106 S21 rollback) |

**python_in_cl_risk:** YES — 21 :text blobs; the mechanizable ones (:V6I-REF, :V6I-COG-one-to-one) re-coded as Python duplicate detection instead of L2/define-unique data; V6S12-V6S17 audit ids and V6KW kill ids dangle (V6KW-* are 'Predeclared tests (design-only, UNEXECUTED)' per the V1.6 dossier; no `test` facts). CL-native alternative: pointer facts + data rules for the mechanized clauses; the negative-eval rule stays in safe-read.lisp (one seat) rather than becoming a lint regex.

**future_freedom (MECHANISM):** CONSTRAINS by seat binding, otherwise these ARE the freedom guarantees (:V6I-01/02/09 lock meanings not tools; no mandatory model; future tech only as adapter). :V6I-10 verbatim binds seats by filename (legal-extraction-verify.lisp, write-authority.lisp — V1.6:76-78), which seats.sexp:30,60 already fix; :V6I-13 fixes S04 = WP-08 one seat; :V6I-14 forbids any model from owning S19 memory — both intended. DOCTRINE CONFLICT (V1.6 dossier A16/A17, NEEDS_ARCHITECTURAL_DECISION): :V6I-REF rejects 'record AND reference for one type' while V1.8:416-424 makes the define-reference the identity seat and the define-record the structure seat of the SAME type; :V6I-17 says human tables are generated FROM the registries while the model generates its views from the model (files-and-roles.sexp:321 GENERATED_VIEW 'from the canonical model') — the source of truth moved.

**evidence:** V1.6-SCHEMAS.sexp:15-46,75-78,105,151-162,177-181,227,242,261-272,295,297-308,334-338,348-355; V1.8-SCHEMAS.sexp:416-424; deferred-imports.sexp:33; source/safe-read.lisp:152-165; source/legal-ast.lisp:1597-1627; source/legal-dialectic.lisp:20; source/memory.lisp:79-111,113,167-197; source/journal.lisp:61-90,544; source/write-authority.lisp:16-51,53; source/adoption-decision.lisp:85; source/legal-extraction-verify.lisp:30-31,340; source/legal-inference-engine.lisp:206-238; source/cognition.lisp:57-77; source/version-graph.lisp:1030; orchestrator-infrastructure.asd:44,88,105,114,115; seats.sexp:30,60; files-and-roles.sexp:321,440; verification-corpus.sexp:45-47; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:126,243; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:31,35; deployment/collab/dialogue/0146-claude.md:18; SUBSYSTEM-REGISTRY.sexp:44,106

###### C10. `V1.6-SCHEMAS__define-protocol`

**Source:** V1.6-SCHEMAS.sexp:57-66 (SemanticProposer :generic-functions (propose-candidates negotiate-capability declare-limitations) 'CLOS generic fns'; :input PerceptionEnvelope/1; :output list CandidateInterpretation/1; 5 :constraints; :absent-behavior SYMBOLIC_ONLY; 1 form); ledger deferred-imports.sexp:35 DDI-4; model identity already `type SemanticProposer :consumer-role PROPOSER :owner-subsystem S03` (interfaces-and-types.sexp:57; consumes dependencies-and-boundaries.sexp:30,122)

| dimension | value |
|---|---|
| immutable_record | protocol identity = the EXISTING `type` fact (interfaces-and-types.sexp:57) + NEW `protocol-function` facts (:protocol ref type, :name SYMBOL, :in ref type, :out ref type) and `protocol-constraint` facts (closed enum of obligations) — hash-pinned; the protocol's OUTPUT records are hash-bearing (CandidateInterpretation/1 = lawmax/neural-candidate/1, V1.6:92-95) ¦ invariant: L2 — the id SemanticProposer is owned by `type`; a second `protocol` id for the same concept is forbidden (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:34-36; V1.6 dossier A6/A21) ¦ fallback: a NEW `protocol` family with a DISTINCT id (second seat — needs adjudication) |
| clos_class | abstract protocol class `semantic-proposer` with concrete adapter subclasses (ONNXProposerAdapter / OCRPerceptionAdapter — V1.6:67-74, DDI-2) — pattern greek-nlp-core.lisp:163-168 (abstract `lexicon`) → hash-table-lexicon :195 / file-lexicon :229 / composite-lexicon :306; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:20 'one class per concept' ¦ invariant: :V6I-04 adapter has NO canonical write authority / NO keys / NO self-certification (V1.6:29-31) + :V6I-10 ¦ fallback: plain structs (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:20) |
| generic_function | defgeneric propose-candidates (proposer envelope) → list of CandidateInterpretation/1; negotiate-capability; declare-limitations — the three NAMES are fixed by V1.6:58; dispatch on the adapter class; an ABSENT proposer is 'no applicable method → symbolic path', never a blocking error (V1.6:66) — pattern cognition.lisp:78-80 build-frame-from-advice with a default method returning nil, and cognition.lisp:92-113 stage generics; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:21 'dispatch is total or errors typed' ¦ invariant: :V6I-10 'A proposer produces PerceptionEnvelope-derived CandidateInterpretation only' (V1.6:75-78) + :absent-behavior (V1.6:66) ¦ fallback: single dispatch function (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:21) |
| condition_restart | adapter failure ⇒ a TYPED condition caught at the wall, degrading SafetyMode to :DEGRADED/:SYMBOLIC_ONLY (V1.6:23 'fail-closed to SYMBOLIC_ONLY semantics'); today cognition.lisp:62-63 `advise` wraps the advisor in ignore-errors — the future form must be a typed condition per LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:24 'every error is a typed condition' ¦ invariant: :V6I-03 'Removing every proposer yields SafetyMode :SYMBOLIC_ONLY, never a broken state' (V1.6:25-28) ¦ fallback: return typed error value |
| macro_dsl | NOT a macro — the constraint 'passes EXCLUSIVELY through the non-evaluating ingress decoder (no cl:read/eval/macro/compile)' (V1.6:64): safe-read.lisp:152-165; the `ingress-decoder.lisp` named by LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:35 is NOT FOUND in source/ ¦ invariant: SIK §14 no read/eval over external bytes (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:35) ¦ fallback: reject input |
| protocol | THE class of this form: a CLOS protocol = abstract class + 3 defgenerics + documented contract (the 5 constraints as `protocol-constraint` facts); exemplars greek-nlp-core.lisp:170-189 ('Generic functions - THE PROTOCOL'), :387-394 analyzer/analyze, protocols.lisp:51-60 ¦ invariant: :V6I-10 + :V6I-04 ¦ fallback: a single function-typed slot registered through the capability registry (capability-registry.lisp:48 :fn; :46 trust :trusted¦:advisor; define-capability :140-147) with :trust :advisor |
| package_asdf_boundary | the protocol package lives in the public system; each adapter in its OWN ASDF system that :depends-on the protocol package, never the reverse; no trusted-path system :depends-on an adapter system ¦ invariant: 'removable with NO loss of memory or canonical data' (V1.6:65) + :V8I-02 (V1.8:17-19) ¦ fallback: adapter registered at runtime through the capability registry (SEAT-CAPABILITY-REGISTRY seats.sexp:58; capability-seat-collision capability-registry.lisp:72-81 keeps one owner per capability) |
| persistent_event | NOT-APPLICABLE (the proposer 'writes NO journal/canonical state' V1.6:62 — the ABSENCE is the invariant, enforced by write-authority.lisp:16-51) |
| truth_maintenance_dependency | NOT-APPLICABLE (candidates are not beliefs until symbolically promoted — :V6I-10; that is C9/C5's JTMS concern) |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | gate-time: protocol-function names are plain symbols (L1 TOKEN); :in/:out are L3 refs to declared `type` facts (PerceptionEnvelope/1, CandidateInterpretation/1 are imported types per deferred-imports.sexp:6); every DDI-2 adapter-contract :implements resolves to this protocol (L3) with :mandatory NO (yes-no) ¦ invariant: :V7I-no-mandatory-model-v7 'No define-adapter-contract … is :mandatory t' (V1.7:301-303) ¦ fallback: prose |
| runtime_validation | 'score is NEVER converted to legal truth' (V1.6:63) is enforced at the wall: verify-proposal / verdict (legal-extraction-verify.lisp:30-31,340) is the ONLY path from candidate to IR ¦ invariant: :V6I-10 (V1.6:75-78) ¦ fallback: reject candidate |

**python_in_cl_risk:** YES — :generic-functions as a JSON list of strings and :constraints as 5 free strings; the naive import loses that these are CLOS generic-function NAMES with typed signatures. CL-native alternative: `protocol-function` facts (name SYMBOL, :in ref type, :out ref type) so the future defgeneric lambda-lists are DERIVABLE from data, and the constraints as a closed enum of obligations (e.g. NO_KEYS, NO_CANONICAL_WRITE, NO_SELF_CERT, INGRESS_ONLY, REMOVABLE) checkable per adapter-contract fact.

**future_freedom (MECHANISM):** CONSTRAINS S20 adapter API to three generic-function names (V1.6:58) — a stable contract that PRESERVES V8I-02 (absent ⇒ SYMBOLIC_ONLY, V1.6:66); S04 consumes only typed candidates; S19 untouched ('removable with NO loss of memory', V1.6:65). No JTMS constraint. Batch-order note: DDI-2 adapter contracts reference this DDI-4 protocol (dossier: dag.json order violation). UNKNOWN: the ingress-decoder seat named by the contract does not exist in source/.

**evidence:** V1.6-SCHEMAS.sexp:23,25-31,51-78,92-95; V1.7-SCHEMAS.sexp:301-303; V1.8-SCHEMAS.sexp:17-19; deferred-imports.sexp:6,35; interfaces-and-types.sexp:57; dependencies-and-boundaries.sexp:30,122; source/greek-nlp-core.lisp:163-189,195,229,306,387-394; source/protocols.lisp:51-60; source/cognition.lisp:57-63,78-80,92-113; source/capability-registry.lisp:46-48,72-81,140-147; source/legal-extraction-verify.lisp:30-31,340; source/safe-read.lisp:152-165; source/write-authority.lisp:16-51; seats.sexp:58; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:34-36; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:20-21,24,35

###### C11. `V1.6-SCHEMAS__define-rule`

**Source:** V1.6-SCHEMAS.sexp:247-250 (casegrammar-split, 3 clauses) and :251-260 (common-lisp-cognition-usage, 9 clauses: :clos :conditions :macros :compile-time :packages :immutable :hot-swap :no-external-eval :no-python-in-lisp); ledger deferred-imports.sexp:39 DDI-4

| dimension | value |
|---|---|
| immutable_record | casegrammar-split: the SAME fact as C3 (one seat — adjudicate A11-SR-CASEGRAMMAR-SPLIT-SEAT); common-lisp-cognition-usage: its 9 clauses are the mechanism admissions of LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:18-35 (AUTHORED_NORMATIVE_PROSE files-and-roles.sexp:403) — a `rationale` pointer to the contract, not a text copy ¦ invariant: :V6I-17 one source of truth (V1.6:348-355) ¦ fallback: `rule-clause` facts (rule, key, text) |
| clos_class | meta-rule :clos 'CLOS protocols + generic functions for adapters/analyzers' (V1.6:252) = contract rows LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:20-21 — seats cognition.lisp:35 frame / :42 working-memory; greek-nlp-core.lisp:163 lexicon / :387 analyzer ¦ invariant: 'one class per concept' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:20) ¦ fallback: plain structs |
| generic_function | :clos clause → cognition.lisp:92-113 defgeneric plan / execute-step / synthesize / triage / critique; greek-nlp-core.lisp:394 analyze ¦ invariant: 'dispatch is total or errors typed' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:21) ¦ fallback: single dispatch function |
| condition_restart | :conditions 'condition/restart system for controlled ambiguity and recovery' (V1.6:253) → LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:24: safe-read.lisp:68 safe-read-error; legal-ast.lisp:1597 with-ast-restarts; version-graph.lisp:184-205 typed uncertainty conditions ¦ invariant: 'every error is a typed condition' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:24) ¦ fallback: typed error value |
| macro_dsl | :macros 'macros/DSLs for grammar, morphology, Legal IR and rules' (V1.6:254) + :no-external-eval (:259) → LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:25,35: greek-legislation-ontology.lisp:57 defconcept; legal-inference-engine.lisp:491 defrule; legal-ast.lisp:1548 defastnode; capability-registry.lisp:140 define-capability; mcp-server.lisp:80 define-mcp-tool; safe-read.lisp:156 *read-eval* nil ¦ invariant: 'macros expand at compile time only; NEVER over external bytes' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:25) ¦ fallback: hand-written forms |
| protocol | :hot-swap 'incremental/hot-swappable analyzers via capability registry' (V1.6:258) → capability-registry.lisp:140-147 define-capability + :72-81 capability-seat-collision (one owner per capability, 'structurally impossible' silent replacement :66-70); greek-nlp-core.lisp:387-394 analyzer protocol ¦ invariant: capability-seat-collision — one seat per capability (capability-registry.lisp:66-70) ¦ fallback: static analyzer list |
| package_asdf_boundary | :packages 'package boundaries + declared forbidden dependencies' (V1.6:256) → LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:31; [0146]-claude.md:18 (16 systems / 53 edges / cycle NONE) ¦ invariant: 'declared forbidden dependencies' — the dossier notes this clause has no located counterpart in the registries ¦ fallback: monolith package (today: orchestrator-infrastructure.asd:44 :serial t) |
| persistent_event | NOT-APPLICABLE (:immutable 'immutable/versioned internal objects' V1.6:257 is the immutable_record dimension, cf. :V6I-11) |
| truth_maintenance_dependency | NOT-APPLICABLE (the rule does not name the JTMS; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:28 does) |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | :compile-time 'compile-time schema/invariant generation' (V1.6:255) → LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:32 names constitutional-gate.lisp — but that seat is a RUNTIME rule registry (register-rule :25 / evaluate :38 at command time) whose evaluator is FAIL-OPEN on a rule error (constitutional-gate.lisp:44-45 'σφάλμα κανόνα ⇒ ΜΗΝ μπλοκάρεις (fail-open)'); the actual load-time validation seats are legal-inference-engine.lisp:473-489 (rule legality at instantiation — 'the rule never exists wrong') and capability-registry.lisp:54-61 (frozen +param-types+, fail-closed at registration) ¦ invariant: 'fail at build, not runtime' (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:32) ¦ fallback: runtime check — ADJ-CL4-02: the contract's named compile-time seat is a fail-open runtime evaluator |
| runtime_validation | NOT-APPLICABLE (meta-rule) |

**python_in_cl_risk:** YES, and self-referential: importing the 9 clauses as strings turns :no-python-in-lisp into a string. CL-native alternative: no text copy — a rationale pointer to the contract (one seat) and, for each admitted mechanism, the contract's 8-field admission row as FACTS (mechanism, reason, seat ref, requirement ref, invariant ref, test ref, fallback, migration, rollback) so 'admitted mechanism' is a closed-ref fact type and the contract's MOP row 'none' becomes checkable against source (sb-mop use at legal-inference-engine.lisp:517 and deliberation.lisp:40-44).

**future_freedom (MECHANISM):** CONSTRAINS S04 cognition construction to the listed CL mechanisms — acceptable for compiler A only: LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:10-15 (§1) forbids leaking any of them into the Legal-IR contract that compiler B (Rust, WP-05) must conform to. :hot-swap binds S20's registry as the analyzer-swap seat (freedom-preserving). :immutable aligns with :V6I-11. RISK: as an executable lint the rule would forbid mechanisms it omits but the contract admits (method combination, LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:22; JTMS :28; memoization :30) — it must stay a pointer, not a whitelist (ADJ-CL4-09).

**evidence:** V1.6-SCHEMAS.sexp:247-260,348-355; deferred-imports.sexp:39; files-and-roles.sexp:403; source/cognition.lisp:35,42,92-113; source/greek-nlp-core.lisp:163,387-394; source/safe-read.lisp:68,156; source/legal-ast.lisp:1548,1597; source/version-graph.lisp:184-205; source/greek-legislation-ontology.lisp:57; source/legal-inference-engine.lisp:473-489,491,517; source/capability-registry.lisp:54-61,66-81,140-147; source/mcp-server.lisp:80; source/constitutional-gate.lisp:22-47; source/deliberation.lisp:40-44; orchestrator-infrastructure.asd:44; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:10-15,18-35; deployment/collab/dialogue/0146-claude.md:18

###### C12. `V1.7-SCHEMAS__define-invariant`

**Source:** V1.7-SCHEMAS.sexp: 23 forms — :RA-I-1 14, :RA-I-2 17, :RA-I-3 20, :RA-I-4 23, :RA-I-5 26, :V7I-COG-info-preserving 95, :V7I-MEM-user-private-no-auto-public 111, :V7I-MEM-one-owner 115, :V7I-RA-L 139, :V7I-RA-I-deterministic 166, :V7I-RA-R 180, :V7I-RA-K 199, :V7I-RA-T 212, :V7I-RA-INST 234, :V7I-RA-qual-revocable 249, :V7I-COV-availability-live 280, :V7I-PUBPRIV-acyclic 297, :V7I-no-mandatory-model-v7 301, :V7I-SYM-reachable 318, :V7I-OWN-single-writer 337, :V7I-CAP-seat-closure 353, :V7I-SRC-open-fail-closed 372, :V7I-WP-honest 400; ledger deferred-imports.sexp:45 DDI-4; 13 of 23 have a V1.6 predecessor / V1.8 successor (dossier ADJ-V17-INV-1)

| dimension | value |
|---|---|
| immutable_record | hash-pinned anchor facts with a supersession chain (:supersedes / :superseded-by as L3 refs invariant→invariant, L4-acyclic) so the one-seat question (ADJ-V17-INV-1) is DATA; :V7I-RA-T 'snapshots/deltas are signed, content-addressed' (V1.7:214) → canon-sexp/sha256 seat journal.lisp:61-90 ¦ invariant: :RA-I-5 one seat per concept (V1.7:26-28) ¦ fallback: latest-only import (V1.8 ids live) with V1.7 as rationale pointers |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | :V7I-RA-I-deterministic: non-unique input ⇒ typed AmbiguityResult/1 VALUE (V1.7:166-169), never a guess; :V7I-COG-info-preserving (d): COG7-11 is an EXPLICIT branch whose seat is 'legal-dialectic.lisp + condition/restart' (V1.7:91) — the only mandated restart; CognitionErrorV7 values otherwise (V1.7:40-43) ¦ invariant: :V7I-COG-info-preserving (e) 'no silent forced winner' (V1.7:95-101) ¦ fallback: typed error value (see ADJ-CL4-03: the named restart seat is not built) |
| macro_dsl | NOT-APPLICABLE (registry forms are DATA read under *read-eval* nil (deferred-imports.sexp:4; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:56; safe-read.lisp:152-165) — never a macro expanded over the registry file) |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | :RA-I-4 / :V7I-PUBPRIV-acyclic / :V7I-RA-INST: the public closure contains zero INTERFACE_ONLY/DEFERRED_PRIVATE record — model L5 over consumes (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:243) + ASDF/package boundary for TenantProfile (SEAT-TENANT-PROFILE INTERFACE_ONLY seats.sexp:97) ¦ invariant: :V7I-PUBPRIV-acyclic 'public → private/real-time/embodiment edges are FORBIDDEN and structurally absent' (V1.7:297-300) ¦ fallback: L5 over the consumes family only (today's single family — cf. ADJ-V18-INV-5) |
| persistent_event | :V7I-OWN-single-writer: ONE canonical write seat write-authority.lisp for journal/memory/IR (V1.7:337-340; the define-write-authority rows :327-336 are DDI-1 in V1.7 / IMPORTED from V1.8) — seat write-authority.lisp:16-51,53; :V7I-RA-qual-revocable: expiring/downgrading state transitions are journaled ¦ invariant: :V7I-OWN-single-writer ¦ fallback: replay |
| truth_maintenance_dependency | :V7I-COG-info-preserving (c)(e): alternatives + uncertainty preserved, no forced winner — the alternative SET (LegalSemanticAlternativeSet/1 V1.7:62-65) maps to competing JTMS nodes left :undefined under WFS (legal-inference-engine.lisp:233-236) rather than to a selected winner; :V7I-RA-K 'metrics are NEVER evidence of legal correctness' (V1.7:199-202) keeps metrics OUT of the belief graph ¦ invariant: :V7I-COG-info-preserving ¦ fallback: full recompute |
| temporal_index_projection | :V7I-COV-availability-live: availability is a LIVE input of the census decision (V1.7:280-284) = an as-of projection over coverage state; :V7I-MEM-user-private scopes with retention/deletion (V1.7:106-110) = scope × time policy ¦ invariant: :V7I-COV-availability-live 'mutation removing the guard flips' (V1.7:284) ¦ fallback: recompute the decision table (define-decision-function is DDI-3) |
| compile_time_validation | mechanizable subset at gate time: :V7I-OWN-single-writer → L2 define-unique STORE-OWNER-IS-ONE-SEAT (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:319) + PF-L2-DUPLICATE-STORE (verification-corpus.sexp:48-50) — ALREADY enforced; :V7I-SYM-reachable → L4 + reachability over stage/stage-edge (dependencies-and-boundaries.sexp:5-21); :V7I-CAP-seat-closure → L3 refs from DDI-1 capability-seat facts to real file/package/symbol — the kernel reads only model modules (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:170-184), so a 'real symbol' check is a gate_checks.py-class check with git access (pattern gate_checks.py:786 check_seats) declared as a check fact; :V7I-WP-honest → C13 ¦ invariant: each clause's 'Audit … with N mutations' sentence ¦ fallback: V1.7-CONTRADICTION-OMISSION-AUDIT.sh — HISTORICAL_EVIDENCE (files-and-roles.sexp:444); the V7S-* ids exist nowhere else (dossier ADJ-V17-INV-3) |
| runtime_validation | :V7I-RA-I-deterministic (resolver, SEAT-CANONICAL-URIS seats.sexp:62), :V7I-RA-L (RIGHTS_UNKNOWN ⇒ no redistribution), :V7I-SRC-open-fail-closed (unknown source type fails closed), :V7I-RA-INST (a tenant never gains write authority — write-authority.lisp:35-38 closed authority set) ¦ invariant: the fail-closed clauses (V1.7:140-142, 167-169, 235-238, 373-375) ¦ fallback: reject |

**python_in_cl_risk:** YES — 23 blobs with dangling audit ids (V7S-*), 13 duplicates of V1.6/V1.8 ids imported as separate 'facts' (violating :RA-I-5 by the act of import), and :V7I-SYM-reachable's '5 mutations' (V1.7:321) frozen next to :V8I-SYM-exact's 'EXACTLY 4' (V1.8:339-341) as two live strings. CL-native alternative: supersession-chain facts (L3 refs invariant→invariant, L4 acyclic) with only the LATEST id live; mechanized clauses as data laws (define-unique / edge relations); audit ids as `test` facts ONLY if a tracked, authoritative harness exists (none: files-and-roles.sexp:444 is HISTORICAL_EVIDENCE).

**future_freedom (MECHANISM):** CONSTRAINS: :V7I-MEM-one-owner fixes S19 = memory.lisp EXTEND with owner FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED (V1.7:115-118) — a schedule block on S19 construction, not a mechanism constraint; :V7I-COG-info-preserving fixes the 14-stage DAG and :no-forced-winner for S04 (carried by DDI-1/DDI-3 classes) — compatible with JTMS :undefined; :V7I-RA-K binds S15 to citation-authority.lisp (seats.sexp:52). PROTECTS: :RA-I-3/:V7I-no-mandatory-model-v7 (V8I-02). CONTRADICTION with V1.8 (5 vs 4 mutations; :V8I-SYM-structural retracts 'semantic') constrains the future test corpus — must be adjudicated before either is a live fact (ADJ-CL4-05).

**evidence:** V1.7-SCHEMAS.sexp:14-28,40-43,62-65,91,95-101,106-118,139-142,166-169,180-185,199-202,212-215,234-238,249-252,280-284,297-303,318-322,327-340,353-356,372-375,400-403; V1.8-SCHEMAS.sexp:336-341,459-464; deferred-imports.sexp:45; source/legal-inference-engine.lisp:233-236; source/write-authority.lisp:16-51,53,35-38; source/journal.lisp:61-90; seats.sexp:52,62,97; dependencies-and-boundaries.sexp:5-21; verification-corpus.sexp:48-50; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:319; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:170-184,243; gate_checks.py:786; files-and-roles.sexp:444

###### C13. `V1.7-SCHEMAS__define-wp-reconciliation`

**Source:** V1.7-SCHEMAS.sexp:379-399 (anonymous form, 20 concept→WP rows, line-referenced :evidence; 6 rows FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED; 1 form); ledger deferred-imports.sexp:51 DDI-4; superseded row set at V1.8:303-319 (16 rows)

| dimension | value |
|---|---|
| immutable_record | NEW `concept-wp` facts (:concept SYMBOL, :wp ref wp, :evidence STRING) hash-pinned — but this row set differs from V1.8 (20 vs 16 rows; BITEMPORAL_TWIN, RESOLVER_URIS, PUBLIC_RETRIEVAL_SITE, CONTENT_NEGOTIATION_SITEMAPS dropped without note — dossier ADJ-V18-WP-2) ¦ invariant: :V7I-WP-honest (V1.7:400-403) ¦ fallback: import V1.8 rows only (C15) and keep V1.7 as a rationale pointer |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | NOT-APPLICABLE |
| macro_dsl | NOT-APPLICABLE |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | NOT-APPLICABLE |
| truth_maintenance_dependency | NOT-APPLICABLE |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | L3: :wp must resolve to a declared `wp` fact — FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED is NOT one (model wp facts: DEFERRED, FUTURE_BOOK_REVISION, requirements-tests-workpackets.sexp:52-53; SR:118 equates the tokens only in a comment); the V1.7 :evidence strings are line-referenced but 9 of 14 are not literal in the WP files (dossier ADJ-V17-WP-1) — they cannot be a grep obligation ¦ invariant: :V7I-WP-honest 'a concept mapping to a WP whose evidence does not name it … flips the check' (V1.7:402-403) ¦ fallback: none honest — the V1.7 rows are unverifiable as written |
| runtime_validation | NOT-APPLICABLE |

**python_in_cl_risk:** YES — 20 rows as a JSON array of dicts, 'WP-08.md:19'-style locators parsed by regex, and a Python grep over WP-NN.md at build time (no such check exists today: grep 'WP-' over gate_checks.py finds none). CL-native alternative: `concept-wp` facts with L3 refs and the evidence obligation declared as a harness-bound check fact (pattern verification-corpus.sexp:122-137: harness + falsifier with :reason) executed by the ONE runner — never an inline loop in the generator.

**future_freedom (SCHEDULE):** SCHEDULE ONLY — MEMORY_KERNEL (V1.7:394), UNIFIED_RESOLVER, LICENSE_RIGHTS_MATRIX, CONTENT_NEGOTIATION_SITEMAPS, TENANT_PROFILES, ROOT_AUTHORITY_FLYWHEEL → FUTURE packet; COGNITION_DAG → WP-08 agrees with SR:47 and req-map S04__WP-08 (requirements-tests-workpackets.sexp:70). LEGAL_IR → WP-03 (V1.7:383) vs LegalIR/1 owner S04 → WP-08 (req-map :70) is the keyed-by-concept vs keyed-by-subsystem disagreement (ADJ-V18-WP-3). No mechanism constraint on S04/S19/JTMS/S20.

**evidence:** V1.7-SCHEMAS.sexp:377-403; V1.8-SCHEMAS.sexp:301-323; deferred-imports.sexp:51; SUBSYSTEM-REGISTRY.sexp:47,118; requirements-tests-workpackets.sexp:52-53,70; verification-corpus.sexp:122-137; gate_checks.py (grep 'WP-': no evidence check); IMPLEMENTATION-BOOK/WORK-PACKETS/WP-08.md:1,6,19

###### C14. `V1.8-SCHEMAS__define-invariant`

**Source:** V1.8-SCHEMAS.sexp: 23 forms — :V8I-01 14, :V8I-02 17, :V8I-03 20, :V8I-CLARIFY-cardinality 47, :V8I-COGGRAPH-acyclic-except-resume 66, :V8I-RASTATUS-product 97, :V8I-EPOCH-one-expression 128, :V8I-CONT-separated 149, :V8I-CORR-privacy 168, :V8I-RA-K-tiered 184, :V8I-SIDE-gdpr-honest 200, :V8I-MARK-separated 212, :V8I-FROST-precise 231, :V8I-CAP-real 250, :V8I-PUBPRIV-all-families 277, :V8I-OWN-universal 296, :V8I-WP-real 320, :V8I-SYM-exact 336, :V8I-XREF-real 353, :V8I-COG-typed-edges 386, :V8I-XREF-identity 433, :V8I-RA-DELTA-seats 455, :V8I-SYM-structural 459; ledger deferred-imports.sexp:62 DDI-4

| dimension | value |
|---|---|
| immutable_record | hash-pinned anchor facts with a supersession chain; :V8I-EPOCH: every MultiCommitment carries ≥2 DISTINCT hash families with domain separation from FIRST publication (V1.8:132-133) — canon-sexp is the ONE serialization (journal.lisp:61-68) but sha256-hex (:88) is a SINGLE family, so a second family + domain separation is a NEW seat (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:34 'pin encoder'); :V8I-CORR: the chain verifies with 'content unavailable/withdrawn' without retaining withdrawn content (V1.8:173-174) — the hash stays, the body goes ¦ invariant: :V8I-EPOCH 'the same versioned citation URI NEVER resolves to a different Expression' (V1.8:134-135) ¦ fallback: keep prior version (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:27) |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | :V8I-COGGRAPH / :V8I-COG-typed-edges: SUSPEND→RESUME binds the EXACT suspended instance (resume_binding_ref V1.8:38, 384-385) — the CL-native form of a suspended cognition is a restart established at CLARIFY-DECIDE whose resume restart takes the ClarificationResponse (pattern legal-ast.lisp:1604-1613 restart-case with named restarts); the ClarificationLifecycleState values (V1.8:28-30) are enum VALUES ¦ invariant: :V8I-COG-typed-edges 'the resume edge SUSPEND→RESUME is legal only because ClarificationResponse/1 carries resume_binding_ref binding the exact suspended instance' (V1.8:386-391) ¦ fallback: typed error value + explicit state records (ClarificationRequest/Response facts, V1.8:32-39) |
| macro_dsl | NOT-APPLICABLE (registry forms are DATA read under *read-eval* nil (deferred-imports.sexp:4; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:56; safe-read.lisp:152-165) — never a macro expanded over the registry file) |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | :V8I-PUBPRIV-all-families: 8 edge families DERIVED from real sources incl. source/mcp-server.lisp define-mcp-tool (:80-91) and static-site.lisp emit-* (V1.8:264-274) — the api-mcp-schema and publication families are PACKAGE-level facts (which exported symbols publish what); the model's L5 today covers only the consumes family (dossier ADJ-V18-INV-5) ¦ invariant: :V8I-PUBPRIV-all-families 'no universal-closure claim is made for a family whose real source is not parsed' (V1.8:281-283) ¦ fallback: consumes-only L5 with the honest one-family statement |
| persistent_event | :V8I-CORR (PublicCorrectionEvent tombstone stays citation-resolvable), :V8I-EPOCH (RecoveryEpoch = NEW monotonic epoch N+1, never revert, V1.8:235-238), :V8I-CONT (EmergencyFreeze time-limited, journaled) → chained-append with a monotonic check (journal.lisp:369 %check-monotonic-at!; :507 chained-append) ¦ invariant: :V8I-FROST 'The verifier NEVER silently reverts to an older epoch' (V1.8:238) ¦ fallback: replay |
| truth_maintenance_dependency | :V8I-RASTATUS-product: RelianceProjection is DERIVED, total, deterministic, preserves ALL simultaneous causes, and recovery of one dimension never silently recovers another (V1.8:100-102) — dependency-directed derivation (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:29) over 8 typed dimensions; cause_refs play the role of justification in-lists; not a JTMS belief (no defeaters) but the same 'derived + replayable' discipline ¦ invariant: :V8I-RASTATUS-product (V1.8:97-103) ¦ fallback: full recompute (reliance-of is declared :total t :deterministic t, V1.8:411-414, DDI-3) |
| temporal_index_projection | :V8I-EPOCH-one-expression: temporal_resolution must be :EXPRESSION_VERSION or :FULLY_DETERMINED_TEMPORAL_SLICE with timezone/calendar; 'A bare calendar as-of date is INSUFFICIENT when more than one change can occur the same day' (V1.8:129-132) — the existing temporal seat is DAY-granular: legal-temporal.lisp:41-46 (date<= = string<= over YYYY-MM-DD), version-graph.lisp:7 (bitemporal intervals) / :1030 version-at (valid-at/known-at) ⇒ the invariant requires a finer temporal index (expression-version ordering) than the seat provides today ¦ invariant: :V8I-EPOCH (V1.8:128-136) ¦ fallback: :CURRENT_VIEW_QUERY is never a canonical citation (V1.8:131-132) — i.e. refuse, do not approximate |
| compile_time_validation | gate-time subset: :V8I-OWN-universal → L2 (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:319) ALREADY; :V8I-XREF-real/:V8I-XREF-identity → a check that OPENS :canonical-file and greps :locator (V1.8:354-356, 434-441) — the kernel reads only model modules (ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:170-184), so this is a git-access check (gate_checks.py:786 pattern) declared as a check/falsifier fact; :V8I-CAP-real → same (opens source/*.lisp for defpackage + symbol, V1.8:251-254); :V8I-COGGRAPH → L4 over flow+branch+terminal edges with resume edges in their OWN relation (the kernel treats every from/to relation as an acyclicity duty, ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:211-228 — resume edges must not share the flow relation); :V8I-RA-DELTA-seats 'exactly SEVEN' → an exact-cardinality fact (property-family pattern verification-corpus.sexp:42-56) ¦ invariant: each 'Audit … mutation' clause ¦ fallback: V1.8-VERIFY.py — HISTORICAL_EVIDENCE (files-and-roles.sexp:453) |
| runtime_validation | :V8I-02/:V8I-03 SYMBOLIC_ONLY path + one seat; :V8I-CONT (one person may invoke only a time-limited freeze; thaw requires quorum) and :V8I-FROST (no silent single-algorithm fallback) are production-time governance/crypto checks in the MLTP seats (SEAT-KERNEL-VERIFY seats.sexp:44; SEAT-MLTP-THRESHOLD-CUSTODY DESIGN_TARGET :87) ¦ invariant: :V8I-FROST-precise (V1.8:231-238) ¦ fallback: reject / hold |

**python_in_cl_risk:** YES — 23 blobs including two INTERNAL contradictions (:V8I-SYM-exact 'SEMANTICALLY EQUIVALENT' V1.8:338 vs :V8I-SYM-structural 'does NOT claim behavioral SEMANTIC equivalence' :462; V8-COGLIFE 3 witnesses :71 vs 7 :390) and 'exactly SEVEN' (:456) vs TRACEABILITY's eight (dossier ADJ-V18-INV-4) — as strings they coexist silently; the file-opening audits (XREF/CAP/WP) become Python grep loops. CL-native alternative: retraction as DATA (:retracts V8I-SYM-exact on V8I-SYM-structural, L4-acyclic), witness/mutation counts as exact-cardinality facts (universe-floor pattern verification-corpus.sexp:60-71) so 3-vs-7 is an L1/corpus violation, and file-opening obligations as declared checks in the harness universe.

**future_freedom (MECHANISM):** CONSTRAINS: (1) :V8I-EPOCH forces sub-day temporal identity on S05/version-graph and the resolver — the day-granular date arithmetic (legal-temporal.lisp:41-46) cannot express it (ADJ-CL4-04); (2) :V8I-COGGRAPH/:V8I-COG-typed-edges fix S04's graph (19 nodes, resume semantics — DDI-3 classes); (3) :V8I-CLARIFY-cardinality constrains the ClarifiedInterpretation record (DDI-2) and the C16 fixtures; (4) :V8I-PUBPRIV-all-families makes mcp-server.lisp define-mcp-tool the derivation source of the api-mcp-schema family (V1.8:272) — binds S14's MCP surface as a public-edge source; (5) :V8I-SYM-structural explicitly DEFERS behavioral equivalence to a future WP (V1.8:462-463). PROTECTS: :V8I-02 (no mandatory model), :V8I-03 (no duplicate store — S19 stays one seat).

**evidence:** V1.8-SCHEMAS.sexp:14-22,28-51,66-71,97-103,128-136,149-157,168-174,184-190,200-204,212-216,231-238,250-254,264-283,296-299,320-323,336-341,353-356,386-391,411-414,433-441,455-464; deferred-imports.sexp:62; source/journal.lisp:61-68,88,369,507; source/legal-ast.lisp:1604-1613; source/legal-temporal.lisp:41-46; source/version-graph.lisp:7,1030; source/mcp-server.lisp:80-91; seats.sexp:44,87; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:319; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:170-184,211-228; gate_checks.py:786; verification-corpus.sexp:42-56,60-71; files-and-roles.sexp:453; LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:27,29,34

###### C15. `V1.8-SCHEMAS__define-wp-reconciliation`

**Source:** V1.8-SCHEMAS.sexp:303-319 (anonymous form, 16 concept→WP rows with :file + literal :evidence; 5 rows FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED with :file "none"; 1 form); ledger deferred-imports.sexp:69 DDI-4; competing seats SR:15-30 define-wp-purpose (declared cross-check source of truth SR:12) and req-map (requirements-tests-workpackets.sexp:67-95)

| dimension | value |
|---|---|
| immutable_record | NEW `concept-wp` facts (:concept SYMBOL, :wp ref wp, :file STRING, :evidence STRING) hash-pinned — supersedes C13 (all 11 :file names tracked and all 11 :evidence strings literal per the V1.8 dossier grep) ¦ invariant: :V8I-WP-real (V1.8:320-323) ¦ fallback: retire in favour of req-map + wp-purpose (dossier ADJ-V18-WP-3) |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | NOT-APPLICABLE |
| macro_dsl | NOT-APPLICABLE |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | NOT-APPLICABLE |
| truth_maintenance_dependency | NOT-APPLICABLE |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | (a) L3: :wp → declared `wp` — requires ONE future token (FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED vs FUTURE_BOOK_REVISION vs DEFERRED — dossier ADJ-V18-WP-1; TENANT_PROFILES is FUTURE at V1.8:318 but DEFERRED at SR:126 / req-map S26__DEFERRED :95); (b) the evidence obligation OPENS :file under IMPLEMENTATION-BOOK/WORK-PACKETS/ (AUTHORED_NORMATIVE_PROSE files-and-roles.sexp:386) and confirms :evidence occurs — a git-access check (gate_checks.py class; none exists today) declared as a harness-bound check fact; (c) :file "none" for FUTURE rows must be excluded STRUCTURALLY by a define-conditional (when :wp = the future token, forbid :file/:evidence; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:26-30) rather than the bare string 'none' (cf. seats.sexp:19 '"none" as a bare word is not an answer') ¦ invariant: :V8I-WP-real 'V8-WP OPENS each named WP-NN.md and confirms the :evidence string occurs in it' (V1.8:321-323) ¦ fallback: SR define-wp-purpose :owns (C2) |
| runtime_validation | NOT-APPLICABLE |

**python_in_cl_risk:** YES — 16 dict rows plus a Python grep in the generator; generic evidence strings ('public' → WP-12.md, 'provider' → WP-14.md, 'Legal IR' → WP-03.md title only; dossier ADJ-V18-WP-4) pass a naive grep while proving nothing. CL-native alternative: `concept-wp` facts with L3 refs; the evidence check declared as data with a minimum discriminating standard (e.g. :evidence-kind HEADING|REQUIREMENT-LINE|SYMBOL as a closed enum); 'none' replaced by a conditional rule — never a truthy-string test.

**future_freedom (SCHEDULE):** SCHEDULE ONLY — same FUTURE blocks as C13 (MEMORY_KERNEL, UNIFIED_RESOLVER, LICENSE_RIGHTS_MATRIX, TENANT_PROFILES, ROOT_AUTHORITY_FLYWHEEL, V1.8:315-319); binds PROOF_CARRYING_QUERY → WP-11 and CITATION_MEASUREMENT → WP-13. Three competing WP-assignment seats (concept→WP here; WP→:owns SR:15-30; subsystem→WP req-map) must reduce to ONE before any is a live constraint (ADJ-CL4-06). No mechanism constraint on S04/S19/JTMS/S20.

**evidence:** V1.8-SCHEMAS.sexp:301-323; SUBSYSTEM-REGISTRY.sexp:11-30,118,126; requirements-tests-workpackets.sexp:52-53,67-95; seats.sexp:19; files-and-roles.sexp:386; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:26-30; deferred-imports.sexp:69; IMPLEMENTATION-BOOK/WORK-PACKETS/WP-08.md:1,6,19

###### C16. `V1.8-SCHEMAS__define-fixtures`

**Source:** V1.8-SCHEMAS.sexp:398-405 (clarified-interpretation-fixtures: 3 :valid + 4 :invalid rows over the DDI-2 cardinality table :394-397; modes as bare symbols, :provenance-preserved t/nil; 1 form); ledger deferred-imports.sexp:61 DDI-4 (batched as prose although executable data — dossier ADJ-V18-FIX-2)

| dimension | value |
|---|---|
| immutable_record | NEW `record-fixture` facts (:rule ref cardinality-table id, :expect PASS¦FAIL from fixture-expectation ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:65, :mode SYMBOL constrained to MergeSemanticsV8 (V1.8:31) as a define-enum, :selected INTEGER, :merged INTEGER, :provenance-preserved YES¦NO from yes-no :71) — 7 facts, hash-pinned ¦ invariant: L1 (no NIL, closed enums, ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:5-7) + :V8I-CLARIFY-cardinality (V1.8:47-51) ¦ fallback: leave in V1.8 as AUTHORITATIVE_AT_SOURCE — but NOT as an inert model fact (ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:12 forbids parsed-but-ignored data) |
| clos_class | NOT-APPLICABLE |
| generic_function | NOT-APPLICABLE |
| condition_restart | NOT-APPLICABLE |
| macro_dsl | NOT-APPLICABLE |
| protocol | NOT-APPLICABLE |
| package_asdf_boundary | NOT-APPLICABLE |
| persistent_event | NOT-APPLICABLE |
| truth_maintenance_dependency | NOT-APPLICABLE |
| temporal_index_projection | NOT-APPLICABLE |
| compile_time_validation | executed at gate time by a DECLARED harness (harness facts verification-corpus.sexp:122-125; run_corpus.py is the ONE runner per S15-M1 :118) with EXACT cardinality 7 and a universe-floor (UF-FIXTURE pattern :60-61) so a dropped row is a named failure; the executor evaluates the DDI-2 cardinality table AS DATA (as law2-unique evaluates define-unique data, ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:190) — each :invalid row must FAIL for the cell its comment names (V1.8:402-405) ¦ invariant: :V8I-CLARIFY-cardinality 'Audit V8-CLARIFY with a mutation that makes ABSTAIN carry a selection' (V1.8:51) = the :invalid ABSTAIN row (V1.8:402) ¦ fallback: NONE that is honest — an unexecuted fixture is silent loss; either executed or not imported (ADJ-CL4-08) |
| runtime_validation | the SAME table is the production-time validator of ClarifiedInterpretation/1 instances at the RESOLVE node (V1.8:375; record V1.8:40-46): a data-driven cardinality check (selected/merged null¦one, provenance all-preserved per :merge_semantics); the fixtures are its regression vectors (WP-08.md:23 'sbcl inference fiveam suite') ¦ invariant: :V8I-CLARIFY-cardinality ¦ fallback: reject the record (fail-closed) |

**python_in_cl_risk:** YES — the sharpest in DDI-4: t/nil → NIL (an L1 violation) or Python True/False; :valid/:invalid → strings; bare ABSTAIN vs :ABSTAIN in the table (V1.8:395 vs :399) reconciled by stripping colons in Python (the legacy guard V1.8-VERIFY.py:1049 per the dossier); the executor written as one imperative Python function per fixture. CL-native alternative: yes-no + fixture-expectation enums, mode symbols validated against the MergeSemanticsV8 define-enum, and ONE data-driven evaluator of the cardinality table implemented independently by each verification path (kernel and checker share the specification, never evaluator code — ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:1-2) and reused as the production validator's specification (one seat for the rule, two independent evaluations).

**future_freedom (MECHANISM):** CONSTRAINS S04's RESOLVE output (ClarifiedInterpretation/1) to the three merge semantics — intended (no hidden winner). Batch order: these DDI-4 fixtures depend on the DDI-2 table (V1.8:394-397; dossier ADJ-V18-FIX-2) — importing them before DDI-2 is impossible. No S19/JTMS/S20 constraint.

**evidence:** V1.8-SCHEMAS.sexp:31,40-51,375,393-405; deferred-imports.sexp:61; ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:1-2,5-7,12,65,71,217-220; verification-corpus.sexp:24-39,60-61,118,122-125; ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp:190; IMPLEMENTATION-BOOK/WORK-PACKETS/WP-08.md:23; files-and-roles.sexp:453

##### Adjudication items (named; both sides cited; not resolved here)

- ADJ-CL4-01 MOP: LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:23 declares MOP 'NOT USED in the trusted path — (none)'; source/legal-inference-engine.lisp:491-506 (defrule ⇒ defclass) and :514-520 (all-legal-rules via sb-mop:class-direct-subclasses) discover the rule universe through the MOP in the WP-08 reasoning core (WP-08.md:12 lists legal-inference-engine.lisp), and source/deliberation.lisp:40-44 defines a metaclass; grep finds standard-class/sb-mop in 10 source files. Either the contract admits MOP with a named invariant (e.g. 'the rule universe is the leaf set of the legal-rule class graph, never a hand-listed registry') plus test/fallback/rollback, or rule discovery moves to an explicit registry (capability-registry pattern). Not resolved here; no DDI-4 class REQUESTS MOP.
- ADJ-CL4-02 compile-time validation seat: the contract's row (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:32) names constitutional-gate.lisp; that file is a RUNTIME rule registry (register-rule :25, evaluate :38) with FAIL-OPEN on a rule error (constitutional-gate.lisp:44-45) — the opposite of the fail-closed doctrine in :V5I-D3-unknown (V1.5:406-409) and :V7I-SRC-open-fail-closed (V1.7:372-375). The load-time seats that actually fail early are legal-inference-engine.lisp:473-489 and capability-registry.lisp:54-61. Which seat is 'compile-time validation' for V1.6:255 :compile-time?
- ADJ-CL4-03 clarification condition/restart seat: V1.6:227/:242 and V1.7:91 name 'legal-dialectic.lisp + condition/restart' (EXTEND) as the COG-10/COG7-11 seat; source/legal-dialectic.lisp (4648 B) contains one function dialectic-report (:20) and no define-condition/restart-case; restart-case exists only in greek-tokenizer-advanced.lisp, legal-ast.lisp (:1597 with-ast-restarts), trace-core.lisp. Seat status is DESIGN_TARGET, not REUSE/EXTEND — affects :V6I-06, :V7I-COG-info-preserving (d), :V8I-COG-typed-edges (resume).
- ADJ-CL4-04 :V8I-EPOCH-one-expression (V1.8:128-136) requires sub-day temporal resolution (EXPRESSION_VERSION / FULLY_DETERMINED_TEMPORAL_SLICE with timezone/calendar) while the temporal seat is day-granular: legal-temporal.lisp:41-46 (date<= = string<= over YYYY-MM-DD) and version-graph.lisp:7,1030 (valid-at/known-at intervals). Importing the invariant as live binds S05/version-graph and the resolver to a finer index than exists.
- ADJ-CL4-05 prose-invariant one-seat policy (carries ADJ-V17-INV-1 / ADJ-V18-INV-1): 92 define-invariant forms across SIX registries (independently grep-counted: ISR 1, SR 2, V1.5 22, V1.6 21, V1.7 23, V1.8 23) with ≥13 supersession chains and three INTERNAL V1.8 contradictions (:V8I-SYM-exact V1.8:336-341 vs :V8I-SYM-structural :459-464; COGLIFE 3 witnesses :71 vs 7 :390; 'exactly SEVEN' :456 vs TRACEABILITY eight) and one V1.7/V1.8 contradiction (5 mutations V1.7:321 vs 4 V1.8:339). Latest-only vs history-chain vs pointer-only decides whether an `invariant` fact type exists at all; contradictions must be retraction DATA before any text is live.
- ADJ-CL4-06 WP assignment (carries ADJ-V18-WP-1/-3, A2/A17-SR): three seats (concept→WP V1.8:303-319 & V1.7:379-399; WP→:owns SR:15-30 'cross-check source of truth' SR:12; subsystem→WP req-map requirements-tests-workpackets.sexp:67-95), four future tokens (FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED / FUTURE_BOOK_REVISION / DEFERRED / 'FUTURE_BOOK'), and no model seat for the R-1..R-134 requirement universe (24 requirement facts :5-28; ids R-1 vs R-01 at SR:15-16). One seat and one token must win before :owns/concept-wp facts can be L3-closed.
- ADJ-CL4-07 casegrammar SPLIT: two seats (SR:130-134 define-file-disposition vs V1.6:247-250 define-rule casegrammar-split), SPLIT absent from migration-disposition (MODEL-SCHEMA.sexp:51), and no ASDF-level seat — every cognition file loads in one serial system (orchestrator-infrastructure.asd:44,105,113-115). Which seat, which enum, and is the package split a DESIGN_TARGET packet?
- ADJ-CL4-08 define-fixtures executor (carries ADJ-V18-FIX-1/-2/-3): no model law L1-L7 (MODEL-SCHEMA.sexp:64) evaluates a domain-record cardinality; the only executor is V1.8-VERIFY.py (HISTORICAL_EVIDENCE files-and-roles.sexp:453). Either the harness universe (verification-corpus.sexp:122-125) grows a declared executor with a floor, or the class is not imported (inert import forbidden by MODEL-SCHEMA.sexp:12). Also: fixtures (DDI-4) depend on the DDI-2 table (V1.8:394-397), and modes are :ABSTAIN in the table but ABSTAIN in the fixtures (V1.8:395 vs :399).
- ADJ-CL4-09 common-lisp-cognition-usage (V1.6:251-260) vs the CL contract §2 table (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:18-35): duplicate seat for 'admitted mechanisms'; the rule omits method combination (:22), JTMS (:28), memoization (:30) which the contract admits, and contract §1 (:10-15) forbids leaking any of them into the language-independent Legal-IR contract. Retire to a rationale pointer, or import as rule-clause facts?
- ADJ-CL4-10 define-constitution-reference two seats with different key sets (V1.5:630-638, 8 keys vs LAWMAX-ARCHITECTURE-CONSTITUTION.sexp:358-368, 14 keys incl. :status / :not-frozen / :frozen-baseline / :second-seat nil / :machine-readable / :spec) — carries V5-A11; the CL-native import is a `rationale` pointer to ONE of them.
- ADJ-CL4-11 SA-2-canonical-admission (V1.5:123-137) presupposes lifecycle states ADOPTED/CANONICAL/CANDIDATE/UNKNOWN/QUARANTINED declared in no registry (V5-A6) and has no source seat (adoption-decision.lisp exposes can-adopt :23 / record-adoption! :85; grep 'SA-2|:ADOPTED' over source/ and systems/ = no hit). The state enum must be seated (DDI-2) before the gate facts can be L1/L3-closed.
- ADJ-CL4-12 :V8I-PUBPRIV-all-families (V1.8:264-283) demands 8 derived edge families incl. api-mcp-schema (from source/mcp-server.lisp:80-91 define-mcp-tool) and publication (static-site.lisp emit-*) while the model's L5 covers the consumes family only (MODEL-SCHEMA.sexp:164-170; KERNEL/model-law-kernel.lisp:243) — carries ADJ-V18-INV-5; a package-level derivation seat is needed or the invariant's claim must be narrowed to the parsed family.
- ADJ-CL4-13 the CL contract's own seat citations have drifted from source: LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:20 cites `cognition.lisp:46 working-memory` but source/cognition.lisp:42 is (defclass working-memory ...) and :46 is (defun remember ...); :21 cites `cognition.lisp:107 defgeneric triage / plan / execute-step / synthesize` but only triage is at :107 (plan :92, execute-step :96, synthesize :101). The contract is the normative admission table this map is written against and it claims to be 'grounded in real seats' (:17), so the drift must be corrected at its seat or the citations made symbol-only (file:symbol, as the column header says) — not resolved here.

##### Unknowns

- ingress-decoder.lisp: named by LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:35 and V1.6:64; find over the tree returns only deployment/LAWMAX-SECURE-SEMANTIC-INGRESS-CONTRACT.md — no Lisp seat (NOT FOUND); safe-read.lisp:152-165 is the only non-evaluating reader.
- ASDF system count: [0146]-claude.md:18 says '16 systems, 53 edges, cycle NONE'; find lists 17 .asd files outside third-party (orchestrator.asd carries two defsystems :9,:34; systems/orchestrator-omega.asd duplicates the root orchestrator-omega.asd name) — which 16 the record counts is UNKNOWN.
- Memoization/epoch seat: the contract row (LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:30) names 'shacl-validator.lisp + mltp3:ontology-bundle'; grep -i epoch over source/shacl-validator.lisp and grep ontology-bundle over source/*.lisp return nothing — the epoch-invalidation seat is NOT FOUND in source/ (relevant to :V8I-EPOCH/RecoveryEpoch only by name; not a DDI-4 blocker).
- Whether deliberation.lisp (metaclass, :40-44) is on the public trusted path is UNKNOWN; it is loaded by orchestrator-infrastructure.asd (not checked line-by-line here).
- Whether the R-1..R-134 requirement universe is intended to become model `requirement` facts (today 24: requirements-tests-workpackets.sexp:5-28) or stay prose in TRACEABILITY-MATRIX.md / IMPLEMENTATION-BOOK is UNKNOWN — it decides whether define-wp-purpose :owns can be L3-closed.
- The two V1.6 invariants the V1.6 dossier marks NEEDS_ARCHITECTURAL_DECISION are :V6I-REF (V1.6:158) and :V6I-17 (:348) (A16/A17); the tension with V1.8:416-424 (reference = identity seat, record = structure seat) and files-and-roles.sexp:321 (views generated from the model) is my reading, not the dossier's wording.
- Whether the future SemanticProposer generic functions will dispatch on an adapter CLASS (CLOS) or be registered through capability-registry :fn slots is a design choice the registries leave open (V1.6:58 says 'CLOS generic fns'; SR:101 says owner 'capability registry') — both are recorded as mechanism and fallback, not decided.

##### Cross-cutting findings

- Independent grep of the six registries confirms the batch: 16 classes / 124 forms, of which `define-invariant` is 92 forms across SIX files (ISR 1, SR 2, V1.5 22, V1.6 21, V1.7 23, V1.8 23) — not five; the ledger rows are deferred-imports.sexp:7,9,10,12,17,21,22,28,33,35,39,45,51,61,62,69.
- The registry `define-*` heads are DATA, never macros in the model path: every DDI-4 form must be read under `*read-eval*` nil (kernel :56; safe-read.lisp:156) and flattened into typed facts; a `define-invariant`/`define-rule`/`define-gate` macro in the image is admissible only under the contract's macro row (:25) with a named invariant — none of the 16 classes names one.
- Where an invariant is already MECHANIZED by a model law (L2 one-seat: :SR-V6-one-seat, :ISR-V6-closure, :V7I-OWN-single-writer, :V8I-OWN-universal; L3/L6: wp resolution), the CL-native import is a `rationale` pointer plus the existing data law — a second `:text` fact would be a duplicate seat (rationale-references.sexp:1-2; V6I-17).
- Where an invariant demands a NEW structural check (acyclicity over hash-bearing refs :V5I-C1-acyclic; field-absence :V5I-A2; cardinality :V8I-RA-DELTA 'exactly seven'; resume-edge exclusion :V8I-COGGRAPH), the CL-native form is a data-declared law (define-conditional / define-unique / edge relation / exact-cardinality fact) evaluated by the generic kernel — not a per-invariant function.
- Where an invariant demands opening files outside the model (:V8I-XREF-*, :V8I-CAP-real, :V8I-WP-real), the kernel cannot do it (it reads model modules only, :170-184); the seat is a declared check in the harness universe executed by gate_checks.py-class code with git access (:786 check_seats pattern) — still declared as data (harness/falsifier facts), never an inline loop in a generator.
- Production-time mechanisms (JTMS, chained-append, write-authority, typed conditions, CLOS protocol) are named ONLY where the invariant text requires them, and every one has the contract's fallback; the language-independence ceiling (§1) confines struct/CLOS/condition choices to compiler A's private implementation — content-address formulas and cardinality tables stay in the shared data contract.


### Adversarial pass over all four maps — axis (a): Python-in-Common-Lisp hunter

#### cl-python-hunter — fresh-context adversary over the four Common-Lisp-native maps

Scope: `WORK/agents/cl-DDI-{1,2,3,4}/cl-map.json` (+ their `cl-map.md`) at RO HEAD
`4ee2b58a8df0941845ab786bd0ff859844b94dde`. Contract:
`deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md`
(44 lines, read in full). Every claim below was re-verified by reading RO source, not the maps.
READ-ONLY: nothing outside this directory was written; no git mutation; no gate/battery run.

##### Measurement base (my own reader over the four JSONs)
- 56 classes = 12 + 18 + 10 + 16 (matches the census batch counts).
- 341 cells propose a mechanism (DDI-1 79 / DDI-2 111 / DDI-3 71 / DDI-4 80); the remainder are
  `NOT-APPLICABLE`.
- **341/341 (100%) of those cells contain the literal tokens `invariant:` and `fallback:`.**
  Format compliance is total — which is exactly why it had to be attacked on substance.
- 95/341 (28%) name no invariant **id**; 38/341 carry **no locator of any kind**.
- MOP requested: 0 in all four maps (verified by reading every cell, not by trusting the summary).

##### CONFIRMED DEFECTS

###### PH-01 (P1) — DDI-2 recommends a MOP metaclass as the pattern while declaring `mop_requested = NO`, on a factually false justification
`cl-DDI-2/cl-map.json` `V1.5-SCHEMAS__define-record.clos_class` proposes the C1 records as CLOS classes
"(pattern `source/knowledge-graph.lisp:69-84 assertion-class metaclass` + `initialize-instance :after`
(no assertion without source+justification))", while the same object's `mop_requested` says
"NO — no DDI-2 class needs the metaobject protocol; no named invariant requires it (contract:23,40-41)",
and `cl-DDI-2/cl-map.md:56` calls `assertion-class` "**a metaclass that enforces the named invariant**".

Ground truth in RO:
- `source/knowledge-graph.lisp:69-70` — `(defclass assertion-class (standard-class) () (:documentation …))`
  — **zero slots**.
- `source/knowledge-graph.lisp:71` — its only method is `sb-mop:validate-superclass … t`.
- `source/knowledge-graph.lisp:80-85` — the invariant ("ισχυρισμός ΧΩΡΙΣ ΠΗΓΗ — αδύνατο") is enforced by
  `initialize-instance :after ((a assertion) &key)`, which is **standard CLOS and requires no metaclass**.
- Uses: `:78`, `:106`, `:113` (three `:metaclass assertion-class`) — nothing reads the metaclass.

So the metaclass enforces nothing; deleting `(:metaclass assertion-class)` is behaviour-preserving.
DDI-2 therefore (a) cites gratuitous mechanism as the exemplar to copy into the DDI-2 record seats —
the *opposite* failure the contract forbids ("Macro / MOP / metaprogramming without a demonstrated
benefit is forbidden", contract:6-8), and (b) states a false enforcement claim which, if believed,
would license MOP past contract:23 without the named invariant that line demands.
The same shape recurs in `source/deliberation.lisp:40-44` (`thought-class`, zero slots, only
`validate-superclass`; the real work is `initialize-instance :after` at `:74`). By contrast
`review-queue.lisp:54-57`, `corpus-service.lisp:44-46`, `source-profile.lisp:72-77`,
`corpus-intelligence.lisp:45-47` carry class-allocated slots — those are real MOP.

**Required correction.** Strike "assertion-class metaclass" from the `clos_class` pattern (cite only
`knowledge-graph.lisp:80-85 initialize-instance :after`); correct `cl-map.md:56`; and add to CL2-A3 the
sub-item that `assertion-class` and `thought-class` are **empty metaclasses whose removal is
behaviour-preserving** (gratuitous mechanism), distinct from the four slot-bearing metaclasses.

###### PH-02 (P1) — DDI-2 seats the capability→implementation mapping on a string-keyed hash table that structurally cannot hold the invariant it is admitted under
`cl-DDI-2/cl-map.json` `V1.6-SCHEMAS__define-mapping.protocol`:
"capability -> analyzer binding through the analyzer protocol registry keyed by capability name
(`source/greek-nlp-core.lisp:387-407` … `*analyzer-registry*`/`register-analyzer`/`get-analyzer`) —
**the CL-native mapping is a registry entry** | invariant: V6I-COG-one-to-one; hot-swappable analyzers
(V1.6:258 :hot-swap)". (`V1.6-SCHEMAS__define-record.protocol` cites the same registry.)

Ground truth in RO:
- `source/greek-nlp-core.lisp:396` — `(defvar *analyzer-registry* (make-hash-table :test 'equal))`:
  an **`equal`-test hash table keyed by strings**.
- `:399-401` — `(defun register-analyzer (name analyzer) (setf (gethash name *analyzer-registry*) analyzer))`
  — a **bare `setf gethash`: silent overwrite, no collision detection**.
- `:581-583` (`define-analyzer`) registers under `(string-downcase (string name))` — a downcased string key.
- The invariant cited, `V1.6-SCHEMAS.sexp:270-272` `:V6I-COG-one-to-one`, says an unmapped or
  multiply-mapped capability "is REJECTED **by the architecture gate**" — a *build-time* property.
  A runtime `setf gethash` cannot reject a second registration; it silently wins.
- The other citation, `V1.6-SCHEMAS.sexp:258` `:hot-swap`, reads "incremental/hot-swappable analyzers
  **via capability registry**" — i.e. `source/capability-registry.lisp`, a *different* seat:
  `:63` `(make-hash-table :test 'eq)` keyed by **keywords**, `:69` `*capability-owners*`,
  `:72-81` `capability-seat-collision` ("ΜΙΑ δυνατότητα, ΕΝΑΣ ιδιοκτήτης … ΔΟΜΙΚΑ αδύνατη").

So the map names the invariant of registry A and the mechanism of registry B, and B is precisely the
"hash-table-of-strings, stringly-typed lookup" shape the hunt targets. Adopting it would create a
second capability→implementation registry (CLAUDE.md "μία έδρα ανά έννοια"; contract:20 `:no-duplicate`)
with a silent-overwrite failure mode. Note the map is not uniformly wrong: its own
`compile_time_validation` cell correctly places `V6I-COG-one-to-one` as build-time set equality
(`MODEL-SCHEMA.sexp:34-36` define-unique shape) and its `python_in_cl_risk` cell gives the right
CL-native answer (typed rows with `seat` refs). The `protocol` cell contradicts both.

**Required correction.** Replace the `protocol` mechanism with `capability-registry.lisp:140-147
define-capability` + `:72-81 capability-seat-collision` (eq/keyword, structural single owner), or
state explicitly that `*analyzer-registry*` must first gain a seat-collision condition and a closed
key domain before it may carry `V6I-COG-one-to-one`; cite `greek-nlp-core.lisp:396,399-401` as the
reason.

###### PH-03 (P2) — the eight-field admission discipline is satisfied by token, not by substance, in ~28% of cells
Contract:5-8 admits a mechanism only with `reason → seat → requirement → invariant → test → fallback →
migration → rollback`. All 341 mechanism cells print `invariant:`; 95 name no invariant id and 38 carry
no locator. The clearest self-referential class is `package_asdf_boundary`, whose entire invariant is a
verbatim copy of the contract's own invariant column:
- DDI-2 (7 of 18 classes): "package boundary = capability boundary (…CONSTRUCTION-CONTRACT.md:31)" —
  `define-closed-enum` V1.5, V1.7 and V1.8; `define-record` V1.5; `define-frozen-enum-reference` V1.5;
  `define-mapping` V1.6; plus `define-reference` V1.7 whose whole invariant is the bare phrase
  "one seat per concept".
- DDI-3 (7 of 10 classes): "contract:31; one seat", "contract:31 + one seat", "contract:31; ASDF graph
  acyclic", etc. (`define-decision-function` V1.7, `define-quorum-predicate`, `define-projection`,
  `define-cognition-graph`, `define-cognition-node-types`, `define-dimension-policy`,
  `define-reliance-aggregation`).
- Likewise DDI-2's `macro_dsl` for the four `define-closed-enum` classes: the only invariant is
  "compile-time expansion only (contract:25)".
`cl-DDI-2/cl-map.md:6` declares the shortcut openly ("the remaining five fields are the contract row's
own unless stated"), so this is a *declared* weakening, not a concealed one — but a contract row's
generic column is not a **named invariant of this class**, which is what contract:23/40-41 demands
before a mechanism is admitted.
**Required correction.** For each such cell either name a registry/model invariant id (the maps prove
this is possible: 246/341 cells do it) or mark the cell `INHERITED-CONTRACT-ROW-ONLY` so the
adjudicator can see which admissions rest on nothing class-specific.

###### PH-04 (P2) — `python_in_cl_risk` is not one scale; DDI-4's value is near-constant
DDI-1/2/3 use HIGH / MEDIUM / LOW (DDI-3 also "HIGHEST in the batch"); **DDI-4 uses YES (15 of 16) /
MODERATE (1 of 16)**. Cross-batch ranking of the 56 classes is therefore impossible, and DDI-4's field
carries almost no discriminating information — every class but
`V1.5-SCHEMAS__define-constitution-reference` is "YES". Distribution check (my reader): DDI-1 HIGH 8 /
MEDIUM 3 / LOW 1; DDI-2 HIGH 8 / MEDIUM 7 / LOW 3; DDI-3 HIGH 5 / MEDIUM 4 / HIGHEST 1; DDI-4 YES 15 /
MODERATE 1.
**Required correction.** One declared ordinal scale across the four maps before any aggregation, and a
re-scoring of DDI-4 on it — otherwise "risk" cannot order the DDI import work.

###### PH-05 (P2) — the four JSONs are not one schema
Key counts per object: DDI-1 16, DDI-2 17, DDI-3 16, DDI-4 18.
- `mop_requested` exists **only in DDI-2's JSON** (18/18 objects, one byte-identical string in all 18 —
  informationless per class). DDI-1, DDI-3 and DDI-4 answer the MOP question in **markdown prose only**
  (`cl-DDI-1/cl-map.md:57`, `cl-DDI-3/cl-map.md:331`, `cl-DDI-4/cl-map.md:11`).
- `source` and `future_constraint_level` exist only in DDI-4.
A machine consumer of the four JSONs (the intended use of a "machine-readable twin") gets the MOP
answer for 18 of 56 classes and a per-class source locator for 16 of 56.
**Required correction.** One declared key set; back-fill `mop_requested` and `source` into DDI-1/2/3
from their markdown, or drop the field from DDI-2 and keep the answer in one place.

###### PH-06 (P2) — the contract's MOP row is not merely stale: MOP is load-bearing, and two of the six metaclasses are gratuitous. No map states either half.
Contract:23 and :40 say MOP is "NOT USED in the trusted path — (none)" / "deliberately absent".
All four maps flag the discrepancy (DDI-2 `cl-map.md:56,62` CL2-A3 — 10 files; DDI-3 `cl-map.md:31`,
CL-DDI3-A1; DDI-4 ADJ-CL4-01 — 2 intersecting sites; DDI-1 `cl-map.md:354` declines MOP). Credit given.
But two verified facts appear in **none** of them:
1. **MOP is structural, not incidental**: `source/legal-inference-engine.lisp:514-520 all-legal-rules`
   ("discovered from the MOP class graph", `sb-mop:class-direct-subclasses` at `:517`) is the **default
   value** of `run-inference`'s `:rules` argument (`:604`), and is called from
   `source/legal-knowledge.lisp:35` and `source/self-model.lisp:285`; `:17-18` states it as a design
   claim; `docs/BRAIN.md:157` documents it as the way a rule enters the system. The rule universe **is**
   the MOP class graph — so contract:23's fallback "standard CLOS" is not a drop-in: removing MOP
   requires an explicit rule registry, which is a design change, not a rollback.
2. **Two of the six metaclasses are gratuitous** (see PH-01): `assertion-class`
   (`knowledge-graph.lisp:69-71`) and `thought-class` (`deliberation.lisp:40-44`) have zero slots and
   only `validate-superclass`; removal is behaviour-preserving. The other four
   (`review-queue.lisp:54-57`, `corpus-service.lisp:44-46`, `source-profile.lisp:72-77`,
   `corpus-intelligence.lisp:45-47`) carry class-allocated slots. `(:metaclass …)` occurs 17 times in
   `source/`; `sb-mop`/`closer-mop` in 10 files.
**Required correction.** Split the adjudication into two: (i) admit the rule-discovery MOP with the
named invariant it actually earns ("the rule universe is the leaf set of the `legal-rule` class graph,
never a hand-listed registry") plus test/fallback/rollback — DDI-4's ADJ-CL4-01 already proposes this
wording; (ii) retire the two empty metaclasses as gratuitous mechanism under contract:6-8.

###### PH-07 (P2) — DDI-2 mis-cites the MOP seat by 10 lines, twice
`cl-DDI-2/cl-map.md:56` and `:62` cite "`legal-inference-engine.lisp:504-509 all-legal-rules`".
In RO, `:502-506` is the tail of the `defrule` macro body, `:508-512` a comment block, and
`all-legal-rules` is at **`:514-520`** (`sb-mop:class-direct-subclasses` at `:517`).
DDI-3 (`cl-map.md:31`, CL-DDI3-A1) and DDI-4 (`cl-map.json` `V1.5-SCHEMAS__define-rule.macro_dsl`,
ADJ-CL4-01) both cite 514-520 correctly, so the two are directly contradictory in the deliverable set.
**Required correction.** `504-509` → `514-520` in both places in `cl-DDI-2/cl-map.md`.

###### PH-08 (P3) — bare, uncited invariant assertions
~10 invariant clauses carry neither an id nor a locator, against the brief's file:line rule:
DDI-2 `define-mapping.condition_restart` "EVERY capability mapped EXACTLY once";
DDI-2 `define-adapter-contract.temporal_index_projection` "CapabilityManifest fail-closed on
downgrade/expiry"; DDI-2 `V1.7 define-record.compile_time_validation` "closed field set; typed edges";
DDI-2 `V1.7 define-reference.package_asdf_boundary` "one seat per concept";
DDI-2 `V1.7 define-closed-enum.runtime_validation` "absent proof => RIGHTS_UNKNOWN, no redistribution";
DDI-3 `define-dimension-policy.temporal_index_projection` "policy change invalidates every derived
projection"; DDI-3 `define-reliance-aggregation.temporal_index_projection` "deterministic per (status,
policy epoch, as_of)"; DDI-4 `V1.6 define-invariant.compile_time_validation` "those three clauses";
DDI-4 `V1.7/V1.8 define-invariant.compile_time_validation` "each clause's 'Audit … with N mutations'
sentence" / "each 'Audit … mutation' clause".
(The first is recoverable — `V1.6-SCHEMAS.sexp:270-272` — and the map cites it in a neighbouring cell;
the others need a locator or an UNKNOWN.)

##### ATTACKS THAT FAILED (recorded so the maps get the credit they earn)

- **R1 — "the maps propose hash-table-of-strings blobs / stringly-typed validators / JSON round-trips
  as the CL-native target": REFUTED except PH-02.** I read all 56 `python_in_cl_risk` cells: every
  CL-native alternative is flat typed facts + L3-closed refs + **one** generic evaluator, repeatedly
  pointing at the same real seats (`MODEL-SCHEMA.sexp:26-30` define-conditional, `:34-36` define-unique,
  `journal.lisp:61 canon-sexp`, `KERNEL/model-law-kernel.lisp` generic enum/ref paths). Zero JSON
  round-trips are proposed; the maps explicitly name the Python artifacts to *not* re-import
  (`V1.8-VERIFY.py:1050-1075`, `:1222-1232`, `V1.6-CONTRADICTION-OMISSION-AUDIT.sh:151-152`) and cite
  `model-law-kernel.lisp:9` "No regex, no grep, no substring is structural proof".
- **R2 — "method combination admitted with no named invariant": REFUTED.** It is requested nowhere.
  DDI-3 declines it explicitly (`define-reliance-aggregation.future_freedom`: "method combination
  (contract:22) is NOT requested — an explicit fold is the ceiling here because the dimension set is
  closed (8)"), and DDI-1 invokes contract:22 negatively (`V1.7 define-pipeline.generic_function`:
  "the proposer method may enrich but never be an `:around` that decides").
- **R3 — "imperative loop where a generic function / data-driven rule is CL-native": REFUTED as a map
  defect.** Every occurrence of an imperative loop in the maps is in the *rejected naive import*
  (e.g. DDI-3 `define-algorithm.python_in_cl_risk` "an imperative loop with a mutable 'unknown' boolean
  and try/except"; DDI-4 `V1.7 define-wp-reconciliation` "a Python grep in the generator … never an
  inline loop in the generator"), not in the proposal.
- **R4 — "DDI-3's quorum `defrule` is gratuitous mechanism over a 4-term conjunction": REFUTED.**
  `V1.5-SCHEMAS.sexp:432` `:result-when-insufficient :INDEPENDENCE_UNKNOWN` needs to know *which*
  conjunct failed, so the inspectable-data conjunction has a demonstrated benefit over the stated
  fallback ("procedural `and` of four plain functions").
- **R5 — "a `define-closed-enum` macro where a plain `deftype` + constant suffices": WEAKENED, not
  refuted.** DDI-2 proposes the macro for four classes with no benefit stated against its own fallback
  ("hand-written deftype + defparameter list", the repo's current practice at
  `version-graph.lisp:148-149` and `capability-registry.lisp:59`). The benefit exists — 41
  `define-closed-enum` forms across the four registries (V1.5 16, V1.6 8, V1.7 8, V1.8 9) — but the map
  never states it, and contract:6-8 requires a *demonstrated* benefit. One sentence fixes it.

##### Verification method
Every source line quoted above was read in `RO` with `sed -n`; every count was produced by my own
reader over the four JSONs (no map summary was trusted as an oracle). Seats spot-verified exact:
`capability-registry.lisp:40-48,59,63,66-81,140-147`; `greek-nlp-core.lisp:127,163-170,195,229,306,
387-395,396-407,549,573,581-583`; `write-authority.lisp:12,16,29-30,53-73`;
`knowledge-graph.lisp:69-71,78,80-85,106,113`; `deliberation.lisp:40-44,53-63,74`;
`legal-inference-engine.lisp:15-18,502-520,552,604`; `legal-knowledge.lisp:35`; `self-model.lisp:285`;
`review-queue.lisp:54-63`; `corpus-service.lisp:44-53`; `source-profile.lisp:72-82,135-142`;
`corpus-intelligence.lisp:45-52`; `V1.6-SCHEMAS.sexp:230-246,256-260,268-272`;
`V1.5-SCHEMAS.sexp:415-435`.


### Adversarial pass over all four maps — axis (b): future-freedom hunter

#### cl-freedom-hunter — adversarial pass over the four Common-Lisp-native maps

Fresh context. Targets: `WORK/agents/cl-DDI-{1,2,3,4}/cl-map.json` (12+56 entries: 12/18/10/16).
Axis: any mapping that CONSTRAINS the future — S04 language cognition, S19 memory kernel, reasoning
(JTMS / legal-inference-engine / proof-carrying), replaceable adapters (S20, V8I-02), and the
two-compiler independence of the Legal IR; plus implicit vendor/tool mandates and fake fallbacks.

Method: extracted every `future_freedom` (56 rows) and every `| fallback:` clause (341 applicable
dimension cells; 0 cells missing a fallback field) into `_ff.txt` / `_fallbacks.txt`, then verified
each suspicious claim against the read-only clone. Every claim below carries file:line from RO.

---

##### FH-01 (P1) — Two canonical-serialization seats; DDI-2 mandates one of them as "the ONE" and never names the other

DDI-2 asserts, for all four `define-record` classes, that the content-address of every hash-bearing
record goes through `source/journal.lisp:61 canon-sexp`; the V1.5 row is explicit:

> "canonical(BODY) **MUST** be the ONE serialization seat source/journal.lisp:61 canon-sexp"
> (`cl-DDI-2/cl-map.json`, `V1.5-SCHEMAS__define-record`.immutable_record)

But the ARCHITECTURE-MODEL declares a *different* normative encoding for facts/commitments:
`ARCHITECTURE-MODEL/MODEL-SCHEMA.sexp:37` `:canonical-encoding "AMC2"`, specified in
`ARCHITECTURE-MODEL/CANONICAL-ENCODING.md:1-30` (length-prefixed `enc(s) := decimal(|utf8(s)|) ":" utf8(s)`,
explicitly injective, explicitly designed to kill the ambiguity class that retired AMC1).

`LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:34` admits "deterministic serialization" with the
invariant **"one canonical serialization boundary"** and seat `journal.lisp:canon-sexp`. At HEAD there are
two boundaries with two different algorithms. Map coverage: `AMC2` appears **5×in DDI-1, 0× in DDI-2, DDI-3, DDI-4**.
DDI-1 names both in a single clause (`V1.8-SCHEMAS__define-canonical-identity`.immutable_record;
`cl-map.md:29`) without recording it as a one-seat collision.

Consequence for the future: `contract:34`'s test is "dual-compiler root equality" — over *which* encoding is
undetermined, and DDI-2 would import the CL runtime seat as canonical for records the model already
commits under AMC2. One concept, two seats (CLAUDE.md "μία έδρα ανά έννοια"; `:V8I-03-one-seat`
V1.8-SCHEMAS.sexp:20-22).

**Required:** raise a named ADJUDICATION (which encoding is canonical for hash-bearing record bodies;
is `contract:34`'s single-boundary invariant true at HEAD) before any DDI-2 record row is imported.

---

##### FH-02 (P1) — A CL value domain is being written into a cross-language identity contract, and DDI-2 never applies the §1 test

`journal.lisp:61-83` `canon-sexp`: admissible domain is **NIL, keyword, string, integer, list of those**;
anything else ⇒ error. Keywords are emitted as `:` + `symbol-name` (Lisp upcasing); `NIL` and the empty
list are the same token by construction; dotted pairs print as `" . "`. `journal.lisp:88-92 sha256-hex`
digests via `ironclad` over `sb-ext:string-to-octets` (SBCL-specific).

The registries themselves keep the identity rule abstract and language-neutral:
`V1.5-SCHEMAS.sexp:456-458` and `V1.6-SCHEMAS.sexp:86` say only `hex(sha256(id_domain ‖ 0x1F ‖ canonical(BODY)))`.
DDI-2 narrows `canonical(BODY)` to canon-sexp and then states the consequence itself: it
"bounds every field value to canon-sexp's domain (keyword/string/integer/list)"
(`cl-DDI-2`, `V1.5-SCHEMAS__define-record`.immutable_record).

`LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:10-15` (§1): "no CL mechanism may leak into the IR
contract such that a non-Lisp compiler cannot conform"; `:42-44` (§3): a mechanism a Rust conformer cannot
mirror **semantically** is confined to the CL compiler's private implementation, never the shared contract.

Measured coverage: the DDI-2 map contains **0 occurrences of "compiler B", 0 of "dual-compiler"** across
all 18 entries — the batch that maps every record/type/enum is the one batch that never applies §1.
(DDI-1: 4/1; DDI-3: 1/2; DDI-4: 3/1.)

Honest limit on this attack: no registry field is today outside canon-sexp's domain — the 4 registries use
`ref/id/semver/instant/sig/uncertainty/sha256/(member …)` only (no float/rational/boolean type appears), and
`lawmax/uncertainty/1` is a 13-**kind** registry, not a number (`deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md:553-560`).
So this is not a live L1 violation; it is a permanent forward constraint: content addresses can never be
recomputed, so the value domain chosen at import binds every future version of every public contract.

**Required:** decide explicitly (adjudication) whether the shared identity encoding is AMC2 (language-neutral)
or canon-sexp (Lisp-value-typed), and record the NIL/() conflation and keyword-case rule as part of the
cross-language contract if canon-sexp is chosen.

---

##### FH-03 (P1) — The S19 substrate does not implement the identity rule the maps say it "already does"

DDI-2: canon-sexp "(as `source/memory.lisp:96-110 record-episode` … already does)".
DDI-1: "identity and event chain **share the ONE serialization seat** | invariant: … contract L34"
(`V1.8-SCHEMAS__define-canonical-identity`.persistent_event).

Both are false as stated:

* `source/memory.lisp:101` — `(eid (or id (subseq (%sha256 (format nil "~A|~A|~A|~A" kind text at prev)) 0 16)))`.
  The episode **id** is a 16-hex (64-bit) truncation of a SHA-256 over a `format ~A` printed string: no
  `id_domain`, no `0x1F` separator, not canon-sexp. Only `:hash` (`memory.lisp:110`) uses canon-sexp.
* `source/memory.lisp:158-165` — `%episode-hash` keeps a **second live serialization**: `:hv 2` ⇒ canon-sexp,
  otherwise `(format nil "~S" payload)` for pre-RATCHET lines, and `verify-episode-chain` (`:167-197`) runs it.
  `journal.lisp:68` claims "ΜΙΑ έδρα — καμία δεύτερη παραλλαγή"; `contract:34` claims "one canonical
  serialization boundary". Both are contradicted inside the S19 seat.

Map coverage of the divergence across all four maps: `truncat` 0, `16 hex` 0, `subseq` 0, `eid` 0 hits.

MemoryEvent/1 is the PUBLIC BASE contract (`V1.6-SCHEMAS.sexp:100`) declared as "projection over the
memory.lisp substrate" (`:101`) with `:memory_event_id :type id` (`:102`). Importing it on the maps' stated
mapping either freezes the non-conforming substrate id rule as the public contract, or breaks continuity
with every sealed episode. Neither is surfaced.

**Required:** a named adjudication for S19 identity (substrate eid vs universal `id_domain‖0x1F‖canonical(BODY)`),
and correction of the DDI-1 persistent_event / DDI-2 immutable_record cells.

---

##### FH-04 (P1) — A hot-swappable Greek analyzer's output sits inside the sealed memory body; the hot-swap freedom and the memory identity contract collide

`source/memory.lisp:106-110`: the sealed body is
`(:at :session :id :kind :text :topic :status :props :lemmas :prev :hv)`, hashed with canon-sexp.
`:lemmas` comes from `%lemma-set` (`memory.lisp:72-77`) → `orchestrator.citation-authority:tokenize-greek`
+ `known-lemma`.

Declared freedoms it collides with:
* `V1.6-SCHEMAS.sexp:212` and `:258` — "incremental/hot-swappable analyzers via capability registry";
  `:V6I-09-future-tech-is-adapter` (`V1.6:43-46`) — new technique never forces a change to memory.
* `:V6I-14-memory-model-boundary` (`V1.6:297-300`) — "Replacing any model MUST preserve **byte-verifiable
  memory continuity**".

Swapping the lemmatizer/tokenizer changes the body, hence the content-address, of every *subsequently*
recorded memory event; two conforming implementations (or compiler B) recording the same episode reach
different identities. Already-sealed lines still verify (recomputation reads stored fields), so this is a
forward-identity divergence, not a verification break.

Map coverage: `lemma` — **0 hits in all four maps**. No S19 or S20 row records the collision.

**Required:** decide whether analyzer output may be inside a hash-bearing public body; if yes, the analyzer
is no longer replaceable without a memory-identity epoch, and that must be stated in the S20 replaceability row.

---

##### FH-05 (P1) — DDI-3's escape route from the Python executor is not expressible in the model; the Python tool therefore stays mandatory for that property

Five DDI-3 rows propose `property-family` as a general "exact cardinality proved at model build" device:
`V1.5/V1.7 define-decision-function` (input product), `define-projection` (lifecycle transition table),
`define-dimension-policy` (8 rows = 8 DimensionState fields), and `define-reliance-aggregation`
("EXACT cardinality **65536** … executed generically by BOTH verification paths — replacing the
Python-only executor (V1.8-VERIFY.py:1222-1240)"). All five cite `MODEL-SCHEMA.sexp:221-223`.

The schema does not support that use:
* `MODEL-SCHEMA.sexp:222-227` — `property-family :required (law source-module selector cardinality reason)`,
  `:enum ((law law-id))`, and `law-id` is `(L1 L2 L3 L4 L5 L6 L7)` (`MODEL-SCHEMA.sexp:64`). There is no
  law-id for "totality of an aggregation" or "exhaustive enum product".
* All five existing instances (`verification-corpus.sexp:41-56`) enumerate **facts of one model module**
  (`:source-module "subsystems.sexp" :selector "subsystem"`, etc.). A 4^8 cartesian product of enum values
  is not a fact family of a module; neither is a cross-family field-count equality.

Consequence: the row's own declared fallback stands instead — "string + external executor (**the present
state: V1.8-VERIFY.py**)" (`cl-DDI-3`, `V1.8-SCHEMAS__define-reliance-aggregation`.immutable_record) —
and `V1.8-VERIFY.py` is `:role HISTORICAL_EVIDENCE … NON_AUTHORITATIVE` (`ARCHITECTURE-MODEL/files-and-roles.sexp:453`).
`:V8I-02-no-mandatory-model` (`V1.8-SCHEMAS.sexp:17-19`) names **Python** explicitly among what may not be
mandatory. (Cf. WORK/orchestrator-notes.md N6 for the governance-path tension; this finding is the new part:
the map's stated remedy does not exist.)

**Required:** either extend the schema (new law-id + a family kind whose selector ranges over enum products)
as an explicit decision, or record honestly that the reliance-aggregation totality property has **no
authoritative executor** today.

---

##### FH-06 (P1) — MCP and the static-site emitter are mandatory inputs to the constitutional public/private closure, and no floor protects the families

`V1.8-SCHEMAS.sexp:264-265` declares 8 `edge-families`; `:267-274` fixes their derivation sources, including
`api-mcp-schema ⇐ source/mcp-server.lisp (define-mcp-tool + returned type)` and
`publication ⇐ source/static-site.lisp (emit-*)`. `:V8I-PUBPRIV-all-families` (`V1.8:277-283`): the public
dependency closure is built **ONLY** from edges derived from those real sources.

Against this:
* `source/capability-registry.lisp:142-143` — "HTTP/MCP/CLI είναι **προβολές** του" (projections of the one
  declarative capability definition), i.e. replaceable surfaces.
* DDI-1 itself asserts, in `V1.7-SCHEMAS__define-ra-closure-roots`.future_freedom: "MCP/HTTP must remain
  projections …, **never a mandatory node** (V8I-02)"; and in `V1.8-SCHEMAS__define-ra-closure-roots`.future_freedom
  it accepts that the same families "being derived from CL source means compiler B (Rust) cannot mirror those
  derivations at the code level". The two rows of the same map disagree about whether MCP is mandatory.
* No `universe-floor` covers the 8 closure families: floors exist only for `fixture, property-family,
  falsifier, gen-artifact, seat, tool` (`verification-corpus.sexp:60-70`). Retire the MCP surface — a declared
  freedom — and `api-mcp-schema` silently becomes an empty family; the boundary check then examines nothing
  and still passes.

**Required:** an adjudication (a) whether a replaceable projection may be a mandatory derivation source of a
constitutional law, and (b) a cardinality floor per edge family so an emptied family fails instead of passing.

---

##### FH-07 (P2) — LanguageCognitionLayer/1's analyzer plug-point is bound to a Greek-language file with no one-owner guard; DDI-2 and DDI-4 bind it to different seats

`V1.6-SCHEMAS.sexp:209-215` `LanguageCognitionLayer/1` has `:analyzer_registry_ref` with the source comment
"incremental/hot-swappable analyzers **via capability registry**" (`:212`).

DDI-2 quotes that comment and then binds it elsewhere:
> "`LanguageCognitionLayer/1 :analyzer_registry_ref` (V1.6:212 'incremental/hot-swappable analyzers via
> capability registry') binds to the analyzer protocol registry (`source/greek-nlp-core.lisp:387-407`
> `*analyzer-registry*/register-analyzer/get-analyzer`)"  (`cl-DDI-2`, `V1.6-SCHEMAS__define-record`.protocol)

DDI-4 binds the same clause (`V1.6:258 :hot-swap`) to `capability-registry.lisp:140-147` + `:72-81`
capability-seat-collision (`cl-DDI-4`, `V1.6-SCHEMAS__define-rule`.protocol).

Verified difference in kind:
* `source/greek-nlp-core.lisp:397-402` — `(defvar *analyzer-registry* (make-hash-table …))` and
  `register-analyzer` = bare `(setf (gethash name *analyzer-registry*) analyzer)`: last write wins,
  **no owner, no collision condition**.
* `source/capability-registry.lisp:62-81` — `*capabilities*` "Η ΜΙΑ έδρα … Κανένα δεύτερο μητρώο" plus
  `*capability-owners*` and `capability-seat-collision`, making silent replacement structurally impossible.
* `grep analyzer source/capability-registry.lisp` → **0 hits**; the two registries are disjoint.

Adopting DDI-2's binding creates a second capability seat (`:V8I-03-one-seat`, V1.8:20-22), downgrades the
structural one-owner guarantee to last-write-wins, and freezes a Greek-language file as the plug-point of the
general cognition layer — whose own record carries `:controlling_text_declaration` for multilingual work
(`V1.6:213`).

**Required:** one seat, decided; DDI-2's protocol cell corrected or marked ADJUDICATION with both sides.

---

##### FH-08 (P2) — "single compiler (no cross-check)" is declared as a fallback; it deletes a verification rather than degrading a mechanism

`cl-DDI-3`, `V1.5-SCHEMAS__define-projection`.protocol maps the dual-compiler conformance protocol
(contract:11-15, `:34`) and gives `fallback: single compiler (no cross-check)`.

`LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:38-39` (§3) defines what a fallback must be: "remove the
mechanism and the system still works (**more slowly / more verbosely**), never breaks". `:42-44` makes the two
compilers' independence "the **ceiling** on CL-nativeness", and `:34` makes "dual-compiler root equality" the
**test** of the one-serialization invariant. A fallback that removes the cross-check leaves a system that
still runs but whose named invariant is no longer verified — the fallback silently retires a guarantee.

This is the only fallback in 341 cells that removes a verification. (The other suspicious ones — 6× `n/a`,
`none honest — the V1.7 rows are unverifiable as written` — are explicit honesty markers, not disguised losses,
and I treat them as correct.)

**Required:** restate as "degraded: single compiler, invariant unverified — dual-compiler equality is a
mandatory future stage", not as an equal fallback.

---

##### FH-09 (P2) — Two fallbacks point at a frozen NON_AUTHORITATIVE Python artifact

* `cl-DDI-4`, `V1.8-SCHEMAS__define-invariant`.compile_time_validation — `fallback: V1.8-VERIFY.py — HISTORICAL_EVIDENCE (files-and-roles.sexp:453)`
* `cl-DDI-3`, `V1.8-SCHEMAS__define-reliance-aggregation`.immutable_record — `fallback: string + external executor (the present state: V1.8-VERIFY.py)`

`files-and-roles.sexp:453` classifies that file `:role HISTORICAL_EVIDENCE … NON_AUTHORITATIVE (frozen at 4787b342)`.
A fallback naming a frozen non-authoritative artifact is not "a system that still works" under contract §3;
it is an authority regression, and it re-mandates a Python runtime that `:V8I-02` (V1.8:17-19) forbids.
Both cells label the artifact honestly — the defect is using it as the *fallback slot*, which is the slot the
contract reads as "what remains when the mechanism is removed".

**Required:** name a real fallback (or declare `none honest`, as DDI-4 correctly does for
`V1.7-SCHEMAS__define-wp-reconciliation`.compile_time_validation).

---

##### FH-10 (P2) — No map applies a "vendor / implementation mandatory" test to the identity path

The identity function the maps mandate (`journal.lisp:88-92 sha256-hex`) is
`ironclad:digest-sequence` over `sb-ext:string-to-octets` — an SBCL-only call and a specific library, in the
path that computes the content-address of every public contract record.

Measured map coverage: `sb-ext` 0 hits in all four maps; `SBCL` 1 hit (DDI-2, unrelated — the type system);
`ironclad` 1 hit (DDI-3, quoting kernel-verify's *declared* dependency set). `:V6I-12-no-vendor-in-core`
(`V1.6:155-157`) only forbids vendor identifiers **inside canonical data**, so this axis is not covered by any
existing invariant either, while `:V8I-02` (V1.8:17-19) forbids a mandatory "runtime" in general terms.

**Required:** state explicitly whether the CL implementation and hash library are permitted mandatory
dependencies of the identity path, or whether the identity must be specified so any implementation reproduces it
(the AMC2 style — see FH-01).

---

##### FH-11 (P2) — Independent confirmation: `store memory` has a declared writer the code never uses

`ARCHITECTURE-MODEL/stores-and-authorities.sexp:10` — `(fact store memory :owner SEAT-MEMORY :writer SEAT-WRITE-AUTHORITY)`.
`source/memory.lisp` contains **0 references to write-authority**; it writes via
`orchestrator.journal:chained-append` (`memory.lisp:96`). `source/write-authority.lisp:4-8` exports only
`emit-graph / with-write-authority / *current-write-authority*` — no memory or journal API.

DDI-2 already raises this (CL2-A11). I confirm it independently so the merge cannot lose it: it bears
directly on `:V6I-05` / `:V6I-14` ("canonical MemoryEvent/1 writes are made ONLY by the authorized write
authority", V1.6:32-34, :297-300), which is the guarantee that keeps any model out of S19.

---

##### FH-12 (P2) — Independent confirmation: MemoryPolicy/1 carries private-bearing scopes in a public record

`V1.6-SCHEMAS.sexp:289-293` — `MemoryPolicy/1 … (:scope_isolation :type (list MemoryScope))`, and
`MemoryScope` (`:288`) = `(:public)(:user)(:client)(:matter)(:ephemeral)`. `MemoryPolicy/1` carries no
`:status :DEFERRED_PRIVATE`. DDI-2 flags it (A10); confirmed against source. It matters for
`:V6I-MEM-public-base-clean` (`V1.6:305-308`) once DDI-2 imports the record set.

---

##### FH-13 (P3) — Map schema is not uniform across the four batches; one adjudication is narrower in one map than in another

Keys per map: DDI-1 and DDI-3 = 12 dimensions + `python_in_cl_risk` + `future_freedom` + `evidence`;
DDI-2 adds `mop_requested`; DDI-4 adds `source` and `future_constraint_level`. A merged deliverable must
decide the union.

Concretely on MOP: DDI-4's `ADJ-CL4-01` names `legal-inference-engine.lisp:514-520` and `deliberation.lisp:40-44`.
The true universe at HEAD is **22 `sb-mop`/`closer-mop` call sites in 10 files** (corpus-intelligence,
corpus-service, deliberation, greek-legislation-ontology, knowledge-graph, legal-hypergraph,
legal-inference-engine, review-queue, self-model, source-profile) against
`LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:23` "MOP — NOT USED in the trusted path — (none)".
**My attempt to score this against DDI-2 is REFUTED**: DDI-2's `CL2-A3` (`cl-map.md:62`) already lists all ten
files. The risk is merge-level only: adopting DDI-4's narrower item would drop 8 files.

---

##### FH-14 (P1) — The V8I-02 verdict for `cognition-graph-v8` is carried by evidence from the graph V1.8 replaced

`cl-DDI-3`, `V1.8-SCHEMAS__define-cognition-graph`.future_freedom concludes:

> "S20 / V8I-02: **preserved** — the graph is symbolic-only and adapter-free (V1.7:81-94 `:symbolic-only t`
> on every stage)."

The cited evidence is the V1.7 construction-order, which the same row's point (a) says V1.8 supersedes
(`V1.8:24-27`, DFT-07). On the V1.8 artefact:
* `V1.8-SCHEMAS.sexp:53-65` `define-cognition-graph cognition-graph-v8` — 20 nodes, 4 edge families,
  `:terminals`, `:entry`. **No `:symbolic-only`, no `:proposer-optional`, no `:seat` on any node.**
* `grep symbolic-only V1.8-SCHEMAS.sexp` → exactly 2 hits, both on `define-pipeline symbolic-only-path`
  (`:326` and `:331`), the separate 8-node ACQUIRE→PUBLISH pipeline.
* `:V8I-SYM-exact` (`V1.8:336-345`) proves proposer-removal equivalence over **that pipeline**
  (`:proposer-mandatory-nodes ()`, mutation `mandatory-model-node`), not over the cognition graph.
* The same DDI-3 row concedes: "Proposer attachment: no PROPOSE node exists — where S03 SemanticProposer
  plugs in is **UNKNOWN**."

So for cognition-graph-v8 the structural V8I-02 guarantee is **absent**, and the plug-point at which a model
could later become mandatory is undetermined. The claim is not refuted (the graph indeed contains no proposer
node) but its support does not hold: it is inherited from a superseded artefact. This is exactly the seam the
mandate asks to guard — importing the V1.8 graph as canonical seats a 20-node cognition topology carrying no
symbolic-only property at all.

**Required:** either the import carries a per-node `symbolic-only` fact (restoring what V1.7 declared and
V1.8 dropped) with its own mutation witness, or the row's V8I-02 verdict is downgraded to UNKNOWN.

---

##### What I checked and did NOT find a defect in

* **Fallback completeness.** 341 applicable dimension cells across the four maps; every one carries a
  `| fallback:` clause (0 missing). The 6 bare `n/a` cells are all structurally correct
  (`define-write-authority`.protocol "removing the seat removes canonical writes"; signature-fixed protocols).
* **JTMS / reasoning lock-in.** All 15 `truth_maintenance_dependency` cells fall back to
  `full recompute` / `reject (fail-closed)` (`contract:28-29`). No map makes incremental TMS mandatory,
  and none proposes a second reasoning engine — consistent with `V1.6:164-166` and
  `V1.5 :define-constitution-reference` ("no second reasoning engine", V1.5:635).
* **Method combination.** Requested by no map; `define-method-combination` appears 0× in `source/`.
  `contract:22` (candidate seat `proof-carrying.lisp`, which exists) is correctly left unexercised.
* **S20 adapter replaceability.** `V1.6:67-74` both adapter contracts are `:mandatory nil :replaceable t
  :canonical-write-authority nil`; DDI-2's `package_asdf_boundary` fallback correctly refuses the contract's
  generic "monolith package" and names the invariant's own fallback (`SafetyMode :DEGRADED` ⇒ SYMBOLIC_ONLY semantics, V1.6:20-23) —
  the one place in 341 cells where an agent overrode a contract fallback for a better one, and it is right.
* **DDI-4's `define-gate` lifecycle-state claim.** Verified: `:ADOPTED`/`SA-2` do not occur in `source/` or
  `systems/` (one unrelated `:adopted 0` props key in `systems/orchestrator-cli/understanding-learning.lisp:566`);
  `adoption-decision.lisp:23,85` exposes only `can-adopt` / `record-adoption!`. Claim stands.

##### Scope limits (honest)

* I read the four `cl-map.json` files in full and verified 24 distinct claims against RO. I did not
  re-derive the maps' 8-field discipline rows for all 56 entries.
* No gate, battery or Lisp/Python program was executed (BRIEF rule); `sbcl` and `clingo` are absent here.
* Whether the ARCHITECTURE-MODEL governance path counts as "the public build" for `:V8I-02` is an
  institutional question I do not resolve — it is the pivot of FH-05, FH-09 and FH-10 and is already
  registered as WORK/orchestrator-notes.md N6.


## 3. Future-review inputs (Part 7 — no ceiling adjudication)

## FUTURE-REVIEW-INPUTS — Part 7 (label `future-review`)

**Scope discipline, stated first.** This document is INPUTS ONLY. It performs **no ceiling adjudication**. Nothing
here is called ανώτατο, complete, sufficient, or freeze-ready, and nothing here declares any artifact ready to be
frozen or merged. Where two artifacts of this reconnaissance disagree, the disagreement is recorded with both sides
cited (§E), never resolved. "UNKNOWN" appears where the evidence stops.

RO = read-only clone at HEAD `4ee2b58a8df0941845ab786bd0ff859844b94dde` (tree `ad71185a`). Nothing outside
`WORK/agents/future-review/` was created, modified or deleted; no git mutation; no gate, corpus, battery,
`run_corpus.py`, `build_*.py` or Lisp/Python model program was executed. `sbcl`/`clingo` are absent in this
container (orchestrator-notes N6), so no claim below rests on a run.

Path abbreviations: `AM` = `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL`,
`CP` = `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL`, `GATE` = `AM/ARCHITECTURE-MODEL-GATE.sh`,
`MS` = `AM/MODEL-SCHEMA.sexp`, `VC` = `AM/verification-corpus.sexp`, `KRN` = `AM/KERNEL/model-law-kernel.lisp`,
`W` = the reconnaissance work directory.

---

### 0. Input inventory — what I actually read, and what was NOT THERE

**Read in full or in the cited part (all present):**

| input | note |
|---|---|
| `W/agents/dossier-{INTERFACE-AND-SCHEMA-REGISTRY,SUBSYSTEM-REGISTRY,V1.5,V1.6,V1.7,V1.8}-SCHEMAS.sexp/dossier.json` | 6 dossiers; 12/18/17/21/29/65 adjudication items, 9/7/13/8/7/12 unknowns; 3/5/16/11/13/18 classes |
| `W/agents/matrix-DDI-{1,2,3,4}/matrix.json` | 12/18/10/16 rows, 23 keys each, key set identical across all four |
| `W/agents/dag/DAG.md`, `W/agents/dag/order.json` | 60 nodes, 464 kinded edge rows, 161 blocking, 33 conflicts / 83 blocking refs, 8 bounded adjudications ADJ-DAG-01…08 |
| `W/agents/gates-archaeology/report.md` | verdict PARTIALLY-EVIDENCED; A-1…A-6; 5 unknowns; 4 external artifacts demanded |
| `W/agents/gates-matrix/survival-matrix.md` | 20 cards; equation 2 + 16 + 2; new_checks = 16; A-1…A-8; U-1…U-5 |
| `W/agents/gates-skeptic/findings.md` | S-1…S-9 (2 P1, 4 P2, 3 P3; 3 REFUTED attacks recorded) |
| `W/agents/cl-DDI-{1,2,3,4}/cl-map.json` | 12/18/10/16 rows; key counts 16/17/16/18 (uniform within a file, not across) |
| `W/agents/cl-python-hunter/findings.md`, `W/agents/cl-freedom-hunter/findings.md` | PH-01…PH-08, FH-01…FH-14 |
| `W/agents/dag-attack/findings.md`, `W/agents/dag-mediocrity/findings.md` | DA-01…DA-09 (+6 refuted attacks), F1…F12 — arrived 06:28–06:29 while I wrote (see below) |
| `W/agents/matrix-attack-A/findings.md`, `matrix-mediocrity-A/findings.md`, `matrix-attack-B/findings.md`, `matrix-mediocrity-B/findings.md` | MA-01…MA-10 (+MA-R1…R5 refuted), M1…M12, B-01…B-08, 10 findings — arrived 06:32–06:39 |
| `W/orchestrator-notes.md`, `W/my-gate-mapping.md`, `W/imported-instance-check.json`, `W/imported-field-coverage.json`, `W/dag-crosscheck-fragment.md`, `W/adjudications.json` | N1…N23; the 20→21 mapping; instance- and field-level import coverage |
| the model itself: `MS`, `AM/CANONICAL-ENCODING.md`, `AM/ROOT.sexp`, `VC`, `KRN`, `GATE`, `AM/deferred-imports.sexp`, `AM/build_deferred.py`, `AM/stores-and-authorities.sexp`, `AM/seats.sexp`, `CP/V1.8-SCHEMAS.sexp` | read directly, not through an agent |

**Named in my task but ABSENT on disk at my first inventory (06:25–06:30 UTC 2026-09-07) — and the correction:**

At 06:25–06:30 the only skeptic findings on disk were `gates-skeptic`, `cl-python-hunter` and `cl-freedom-hunter`;
`dag-attack/` held data with no verdict, and `dag-mediocrity/`, `matrix-mediocrity-A/`, `matrix-mediocrity-B/`,
`matrix-mediocrity-DDI-1/` were empty directories. **Between 06:28 and 06:39 UTC, while I was writing, five more
`findings.md` appeared** and I re-read all of them before finishing:
`dag-mediocrity` (06:28, F1…F12), `dag-attack` (06:29, DA-01…DA-09 + 6 refuted attacks),
`matrix-mediocrity-A` (06:32, M1…M12), `matrix-attack-A` (06:34, MA-01…MA-10 + MA-R1…MA-R5 refuted),
`matrix-mediocrity-B` (06:39, 10 findings), `matrix-attack-B` (06:39, B-01…B-08 + refuted classes).
**All eight consolidated adversarial passes have therefore delivered.** The path names in my task
(`matrix-attack-DDI-2/3/4`, `matrix-mediocrity-DDI-1..4`, `cl-DDI-N` hunters) do not exist as such; the same
coverage arrived under the consolidated labels of orchestrator N18 (`-A` = DDI-1+2, `-B` = DDI-3+4,
`cl-python-hunter` / `cl-freedom-hunter` over all four CL maps). No adversarial axis is missing; what changed is
the *shape* of the coverage (8 agents over 12 named slots), which BS-08 records.

Because the work directory is live (`W/adjudications.json` grew from 683 items at 06:21 to 784 at 06:29:35 while I
read it), every count I quote from `W/` is timestamped, and a later count is not evidence that mine was wrong.

---

### A. PROBABLE ARCHITECTURE-CEILING BLIND SPOTS

Each row: what is probably not being seen · the evidence that makes it a blind spot · the check that would expose it.
"Blind spot" here means *the review's own instruments cannot currently see the thing*, not that the thing is broken.

#### BS-01 — AMC2 injectivity is asserted in prose and falsified by nothing

- **Evidence.** `AM/CANONICAL-ENCODING.md:82-87` declares three artifacts as the falsification of the encoding:
  `X46-COMMITMENT-DELIMITER-COLLISION`, `X47-ENCODING-VERSION-BINDING`, and "the property family
  `PF-ENC-INJECTIVITY`". In `VC` at 4ee2b58a: `X46` = 0 occurrences, `X47` = 0 occurrences, and the five
  `property-family` facts are `PF-L6-UNMAPPED-SUBSYSTEM`, `PF-L5-PRIVATE-TYPE-LEAK`, `PF-L2-DUPLICATE-STORE`,
  `PF-L3-DANGLING-SEAT`, `PF-L4-STAGE-CYCLE` (`VC:42,45,48,51,54`) — none is an encoding family. The falsifier ids
  jump `X45-CONTROL-CHARACTER-IN-STRING` (`VC:218`) → `X54-TCB-GROWTH-UNATTRIBUTED`: **X46…X53 do not exist**.
  A repo-wide grep finds `X46-COMMITMENT-DELIMITER-COLLISION` in exactly one place — the sentence that claims it.
  The one counted check on the encoding, `enc-01-three-implementations-one-encoding` (`GATE:190`), requires three
  implementations to agree; three implementations of the same wrong rendering agree perfectly.
- **Why it is a blind spot.** The commitment "claims to be the identity of the fact universe"
  (`CANONICAL-ENCODING.md:16`); its stated defence is a corpus that is not there. AMC1 was retired for exactly this
  class of defect (`:8-19`), and the successor's own guard was never built.
- **Check that exposes it.** (i) A *documentation-closure* check: every id of the form `X\d+-…`, `K\d+-…`,
  `PF-…`, `G\d+-…`, `FX-…` appearing in any `AM/*.md` must resolve to a fact of the matching family in `VC` —
  fails today on three ids. (ii) A real `PF-ENC-INJECTIVITY` family generated over the model's own strings
  (delimiters, `=`, `|`, backslash, empty value, adjacent keys, non-BMP UTF-8, decimal-looking prefixes) asserting
  pairwise render inequality. (iii) The SMT lemma FP-08 below.

#### BS-02 — L5 is a one-edge test; the constitution names an eight-family closure

- **Evidence.** `KRN:243-254` (`law5-isolation`) iterates `CONSUMES` facts and, for each, compares the classification
  of the direct consumer with the classification of the directly provided type. There is no transitive step
  anywhere in the function. `MS:164-166` documents `consumes` as the only closed-endpoint edge. Against that,
  `CP/V1.8-SCHEMAS.sexp:264-265` declares **eight** edge families (`field-type ref-target interface-io subsystem-dep
  store-owner-writer api-mcp-schema publication declassification`) and `:277-283` (`:V8I-PUBPRIV-all-families`)
  requires the public dependency closure to be built from all of them. `PF-L5-PRIVATE-TYPE-LEAK :cardinality 6`
  (`VC:45-47`) enumerates the 6 PRIVATE `type` facts, i.e. it too is per-node, not per-path.
  DAG.md:434-437 states the same conclusion independently.
- **Why it is a blind spot.** A PUBLIC subsystem that consumes a PUBLIC type whose *fields* are typed by a PRIVATE
  record is invisible to L5 today, and seven of the eight declared families have no representation in the model at
  all. The law's name ("isolation") and the check's reach differ by a closure.
- **Check that exposes it.** A held-out fixture with a two-hop path `PUBLIC-consumer → PUBLIC type → PRIVATE type`
  that the current kernel accepts and the intended law must reject; plus a per-family non-emptiness assertion
  (see FH-06, `cl-freedom-hunter/findings.md:158-177`) so that a family with zero derived edges fails instead of
  passing vacuously.

#### BS-03 — the pipeline's symbolic-only guarantee has no representable seat

- **Evidence.** `MS:159` declares `(define-fact-type stage :id-space TOKEN-SPACE :required () :optional () :types ())`
  — a `stage` fact can carry **no field at all**. `W/imported-field-coverage.json` measures the consequence for the
  one imported pipeline: source keys `:nodes :entry :exit :mandatory-nodes :symbolic-only-nodes
  :proposer-optional-nodes :proposer-mandatory-nodes :mutation-count :mutations :edges` (10) → model keys
  `:from :to` (8 `stage-edge` facts) plus 8 field-less `stage` facts. `:V8I-SYM-exact`
  (`CP/V1.8-SCHEMAS.sexp:336-345`) proves proposer-removal equivalence over that pipeline, and the property it
  proves is exactly the one the import dropped. Orchestrator N15/BLK-C4 records the same for
  `define-interface` (10 keys dropped), `define-subsystem` (4) and `define-write-authority` (2).
- **Why it is a blind spot.** `deferred-imports.sexp:6` carries `:status IMPORTED :authority CANONICAL_IN_MODEL` and
  `promotion PROMOTION-IMPORTED` (`:75`) says the 4 imported classes are "fully represented as canonical model
  facts". At field level they are not, and no counted check compares source keys with model keys.
- **Check that exposes it.** A per-class **key-coverage** check: for every `source-class :status IMPORTED`, enumerate
  the source form's keys and the model fact's keys and require every dropped key to appear in a declared
  loss list; an undeclared drop is a failure. Fails today on all four imported classes.

#### BS-04 — the review contradicts itself about L4 and the cognition resume edges, and one branch of the contradiction is testable in seconds

- **Evidence.** `W/agents/dag/DAG.md:533` states as a DDI-3 *exit criterion* that "the v1.8 graph is acyclic EXCEPT the
  two declared resume edges …, which the current L4 has no exemption for", and `DAG.md:867-869` records the
  admissibility of those edges as **UNKNOWN**. (Both DAG.md sentences cite the resume edges as `V1.8:63`; the
  `:resume-edges` key is at `CP/V1.8-SCHEMAS.sexp:61` and `:63` is the tail of `:terminal-edges` — a citation slip
  that does not change the substance of either side.) `W/agents/matrix-DDI-3/matrix.md:238` states the opposite with a
  derivation: `KRN:211-218` derives an acyclicity duty for every fact type whose `:from`/`:to` refs target one node
  type, "so `cog-edge` over `cog-node` is checked acyclic INCLUDING resume edges — the listed graph passes
  (SUSPEND→RESUME→RESOLVE never returns to CLARIFY-DECIDE)". My own independent topological sort over the 20 nodes
  and 21 edge entries exactly as written at `CP/V1.8-SCHEMAS.sexp:53-65` (13 flow + 2 branch + 2 resume + 4 terminal;
  **20 distinct edges**, one duplicate) finds **no cycle**, and no terminal with an outgoing edge.
- **Why it is a blind spot.** An UNKNOWN was carried into the batch-order artifact for a question that another
  artifact of the same reconnaissance had already answered mechanically. Nothing in the assembly cross-checks two
  agents' verdicts on one question, so a resolved item and an open item coexist. (The reverse risk is equally real:
  if the DAG is right and the matrix wrong, the DDI-3 exit criterion is understated.)
- **Check that exposes it.** A cross-artifact consistency pass: for every UNKNOWN recorded in any artifact, grep the
  other artifacts for a claim on the same subject; report the pairs. This is ADJ-FR-01 in §E.

#### BS-05 — the reconnaissance's own adjudication ledger cannot see its adversaries

- **Evidence.** `W/collect_adjudications.py:8-40` collects from six dossiers, four matrices, `order.json`,
  `orchestrator-notes.md` (N-headings) and two gates documents — and from nowhere else. Measured on
  `W/adjudications.json` at 06:29:35 UTC: **784 items**, sources exactly those; occurrences of `FH-0` = 0,
  `PH-0` = 0, `S-`-prefixed items = 0. Every finding of `cl-freedom-hunter` (FH-01…FH-14, five of them P1),
  `cl-python-hunter` (PH-01…PH-08, two P1) and `gates-skeptic` (S-1…S-9) is outside the ledger the creator would read.
  The same file measured **683 items at 06:21** and 784 at 06:29 — it is regenerated during the session, so any
  count quoted from it is a timestamped observation, not a fixed number.
- **Second half of the same blind spot.** The de-duplication key is `re.sub(r'\W+',' ',text.lower())[:120]`
  (`collect_adjudications.py:41-46`) — the **first 120 normalised characters**. Re-running the same collection myself
  over dossiers + matrices + `order.json` yields 793 raw items of which **47 are dropped by that key**, collapsing 14
  distinct keys; the largest collapse merges **15** items into one (all beginning "DECISION: closed field set — `wp`
  has :required () :optional () (MODEL-SCHEMA.sexp:175) so …"). Distinct decisions with a shared opening sentence
  are silently merged.
- **Check that exposes it.** (i) A source-coverage assertion: every directory under `W/agents/` must contribute at
  least one ledger row or be listed as deliberately excluded. (ii) Identity by an **id assigned at birth**, not by a
  text prefix; a collision on full text is a duplicate, a collision on a prefix is a warning that names both.

#### BS-06 — there is no id space for adjudication items, so they cannot be counted, closed or re-tested

- **Evidence.** Across the artifacts the same object is named in at least seven grammars: `A1`, `A1-SR-EMITS-CLAIM`,
  `V5-A1` (dossiers); `ADJ-V17-INV-1`, `ADJ-V18-COG-2` (dossiers); `ADJ-DDI2-ENUM-SEAT`, `ADJ-MX1-CO7-1`, bare `A10`
  (matrices); `ADJ-DAG-01…08` (DAG); `A-1…A-8` (gates matrix); `N1…N23` (orchestrator); `FH-01…14`, `PH-01…08`,
  `S-1…S-9` (skeptics). Parsing the leading token of the 334 `adjudication_items` mentions in the four matrices
  yields **218 distinct leading tokens**, many of them prose fragments (`A1 (V1.6 dossier): record-vs-reference d`).
  The model itself has an id-space discipline for every fact family (`MS:38-42`) — the review of the model does not.
- **Why it is a blind spot.** "Closed at its seat, refuted with proof, or declared a residue with a death phase"
  (CLAUDE.md) is not machine-checkable over items that have no stable identity. Nothing can prove that item *X* was
  answered, and a second review cannot diff its item set against this one's.
- **Check that exposes it.** One regex-checkable grammar (e.g. `ADJ-<ARTIFACT>-<NNN>`), uniqueness across all
  artifacts, and a closure check that every id referenced by another artifact resolves.

#### BS-07 — "the source form's own text" is two different extents in two agents, and one blocking edge lives in the gap

- **Evidence.** `DAG.md:14-17` defines a form's extent as "its start line up to the line before the next top-level
  form" — which includes the trailing comment block. `W/agents/dag-attack/verify.py` recomputes extents by
  parenthesis depth, i.e. start line → the line of the closing paren. Running the attacker's own checker over the
  DAG's 464 edge rows (`W/agents/dag-attack/edgecheck.json`) yields 273 rows with at least one problem, of which
  **33 are blocking**; 32 of those 33 are `matrix-adjudicated` rows that carry a single citation by construction,
  and exactly **one** fails the token test: `V1.8-SCHEMAS__define-ra-closure-roots → V1.6-SCHEMAS__define-reference`,
  token `DeclassificationReceipt/1` "absent from src form text". I verified this directly: the form at
  `CP/V1.8-SCHEMAS.sexp:259-265` contains no such token; the token appears at `CP/V1.8-SCHEMAS.sexp:274` — inside a
  `;;` VR-01 provenance **comment** that follows the form. The edge is exactly the one DAG.md ADJ-DAG-02 cites as
  its `names-symbol` example. **Independently confirmed** by the DAG's own attacker after I wrote this:
  `dag-attack/findings.md` DA-07 (P3) reaches the identical conclusion — "the ONLY blocking edge in this class
  (1 of 161), but it is a comment, not the form's data" — and DA-06 adds the larger measurement: under DAG.md's own
  extent rule **234 of 464 edges fail evidence (2)** (all 234 non-blocking; all 161 blocking edges pass).
  `dag-mediocrity/findings.md` F10 states the same overclaim from the mediocrity axis.
- **Why it is a blind spot.** A comment can satisfy the "two independent evidences" rule. Comments are not facts;
  an import prerequisite justified only by a comment is prose promoted to structure — the class the creator's law
  forbids ("guard around the wrong shape < eliminate the error class").
- **Check that exposes it.** Recompute every blocking edge with the parenthesised extent only and label
  comment-only evidence as a third kind (`comment-evidence`), never as `blocking`.

#### BS-08 — the adversarial protocol was reshaped under budget, and the reshaping is invisible in the deliverables

- **Evidence.** Orchestrator N18 records the cause honestly: two usage-limit resets killed the whole DAG stage and
  all 18 planned skeptics, and the 18 were consolidated into **8** (two axes over DDI-1+2, two over DDI-3+4, two
  over the DAG, two over all four CL maps). All eight delivered (§0). What is not recorded anywhere in the
  deliverables is the *mapping*: which of the 18 planned coverages each of the 8 actually performed, and which
  planned coverage no agent performed. Concretely: `cl-freedom-hunter` states its own scope limit — "I did not
  re-derive the maps' 8-field discipline rows for all 56 entries" (`cl-freedom-hunter/findings.md:351-353`) — and
  no other agent did either; `matrix-mediocrity-A/B` cover the four matrices but no agent attacked the six
  **dossiers** on either axis.
- **Why it is a blind spot.** A deliverable assembled from 8 passes looks identical to one assembled from 18. The
  reader cannot tell which artifact was attacked on which axis, so "the adversary found nothing here" and "no
  adversary looked here" are the same silence. The dossiers (162 adjudication items, the substrate of every matrix)
  are currently in the second category.
- **Check that exposes it.** A coverage matrix as data: rows = primary artifacts (6 dossiers, 4 matrices, 4 CL maps,
  DAG, 3 gates artifacts), columns = the two mandated axes, cells = the agent that performed it or `NOT PERFORMED`.
  A cell that is empty must be an explicit `NOT PERFORMED`, never a blank.

#### BS-09 — the requirement/test universe is a projection of one source class, so L6 cannot detect a missing requirement

- **Evidence.** `MS` declares `requirement`, `test` and `wp` as **field-less** fact types
  (`:required () :optional ()`), i.e. bare id existence. Counts at HEAD: `requirement` 24, `test` 21, `wp` 14,
  `req-map` 29 — all derived from `define-subsystem` (`deferred-imports.sexp:11` `:maps-to "subsystem
  (+requirement/test/wp/req-map derived)"`). Orchestrator N8: `TRACEABILITY-MATRIX.md` carries **134** distinct
  `R-nnn` ids. Orchestrator N1: DDI-1's `define-capability-seat` and `define-ra-delta-seats` cite 14 `RA-*/RA8-*`
  requirement ids and 14 `RA-Q-*/T8-*` test ids, of which the model has one (`RA-Q-RESOLVE`).
  `law6-reqmap` (`KRN:255-266`) checks that every subsystem has a mapping and that the seat matches — it cannot
  check that a requirement is missing, because the universe is defined by what was cited.
- **Why it is a blind spot.** L6 is stated as "requirement → seat → test → WP closure"; it is closure over a
  self-generated set. A requirement that nobody cited does not exist and therefore cannot be unmapped.
- **Check that exposes it.** Declare a requirement/test **registry seat** with its own id universe and assert
  set equality (or a declared, enumerated difference) against the model's `requirement`/`test` families —
  the same shape as `led-01` for the source universe.

#### BS-10 — no check opens a rationale document and looks for its anchor

- **Evidence.** Orchestrator N17 (verified by the orchestrator against the clone): `AM/rationale-references.sexp:7`
  `(fact rationale RAT-PUBPRIV :doc "deployment/LAWMAX-THREAT-MODEL.md" :anchor "public/private one-way boundary")`
  and the anchor string occurs **0 times** in that file. L3 checks only that a `:rationale` key names a declared
  `rationale` id (`KRN:208`); `gate_checks.py` has no anchor resolver. `RAT-PUBPRIV` is the stated justification of
  the four private/interface-only seats.
- **Why it is a blind spot.** The public/private boundary — the constitution's load-bearing wall — is justified by a
  pointer into absent text, and the pointer type-checks.
- **Check that exposes it.** An anchor-resolution check (`:doc` exists ∧ `:anchor` occurs ≥ 1 time in it), the exact
  discipline `:V8I-XREF-real` already applies to `define-reference` at source level.

#### BS-11 — dead machinery inside the measured acceptance base, and a retired mutation with no successor

- **Evidence.** `gates-matrix` A-4 and orchestrator N14: `AM/run_corpus.py:811` defines
  `f19_restore_instead_of_compare` — its only occurrence in the file; it is absent from `CODED_COMPONENT`
  (`:1343`) and `COMPOSED` (`:1370`), and `K19` is absent from `VC` (0 occurrences). `cor-01` reads the two
  registration tables by AST (`gate_checks.py:617-631`), so an unregistered function is invisible to it, while
  `tcb-01` counts its lines. Separately (A-3 / N14): `MISSING-FROM-LEDGER` occurs only in
  `build_deferred.py:218`; no corpus row drops one existing ledger row, so original gate 21's exact mutation has
  **no held-out successor**.
- **Why it is a blind spot.** The acceptance TCB is measured by line count and by table membership; a function that
  is in neither table is simultaneously counted as trusted base and never executed.
- **Check that exposes it.** An AST check: every `def f\d+_…` in a runner must appear in exactly one registration
  table, and every registered name must resolve — plus one corpus row whose mutation is "delete one existing
  `source-class` row".

#### BS-12 — a property demoted to a note is a property with no owner

- **Evidence.** `GATE:89` — `note()` increments `info` only and can never fail. Two of the twenty candidate
  Option-A properties live there: `krn-lexical-scan` (`GATE:224-225`, whose own text says "a lexical scan cannot
  prove absence") and `packet-single-operator-assurance` (`:226`). `gates-matrix` §3 files both as MISSING under its
  own rule, and A-2 records the alternative reading.
- **Why it is a blind spot.** The summary line reports `pass/fail/informational` (`GATE:229`); a reader sees 21
  passing checks and 3 informational lines, not "two constitutional properties are currently unprotected".
- **Check that exposes it.** An explicit `unprotected-property` inventory in the model (one fact per property with
  no counted check), so that the number of unprotected properties is itself a measured quantity.

#### BS-13 — the batch map is data with no law over it

- **Evidence.** `AM/build_deferred.py:87-107` is a literal `head → batch` dictionary; nothing constrains it to
  respect dependency order. The four matrices mark **34 of 56** deferred classes as disagreeing with their declared
  batch (DDI-1 11/12, DDI-2 14/18, DDI-3 3/10, DDI-4 6/16). The DAG's topological order puts DDI-2 enums/records at
  ranks 0-11 while nine DDI-1 classes sit at ranks 15-51 (`DAG.md:110-194`), and reports 33 conflicts over 83
  verified blocking references (`DAG.md:553-556`), every one deferred→deferred. The DAG's own attacker raises
  both numbers: DA-01 (P1) finds a **missing** blocking edge `V1.8 define-ra-delta-seats → V1.8 define-record`
  (7 refs, `CP/V1.8-SCHEMAS.sexp:444-451` binding 7 `:seat` types that are all V1.8 records), so the total is a
  34th DDI-1→DDI-2 conflict; DA-03 (P1) finds a second missing edge `define-subsystem → define-wp-purpose`
  (26 of 26 subsystems carry `:future-wp`, 3 tokens — `DEFERRED`, `WP-07+WP-08`, `WP-07+WP-11+WP-14` — resolving
  to no `define-wp-purpose` id), which is the largest L6 dependency in the migration and is currently absent.
  DA-09 and dag-mediocrity F6 independently correct "26 of the 33 conflicts have a DDI-1 source" to 27
  (28 of 34 after DA-01).
- **Why it is a blind spot.** `gen-01-declared-order-is-total-and-acyclic` (`GATE:168`) enforces exactly this
  property for the *generation* order; the *migration* order has no equivalent, so the plan can be wrong without
  any check noticing.
- **Check that exposes it.** `bat-01`: the declared batch sequence must be a linear extension of the blocking
  edge relation over source classes; fails today with the 33 conflicts named.

#### BS-14 — every floored family sits exactly on its floor, and DDI must move all of them

- **Evidence (counted by me over `AM/*.sexp`).** `fixture` 8 = `UF-FIXTURE` 8; `property-family` 5 = 5;
  `falsifier` 80 = 80; `gen-artifact` 12 = 12; `seat` 33 = 33; `tool` 5 = 5 (`VC:60-70`). Zero headroom anywhere.
  `ROOT.sexp:12` pins `:module-count 14` with a per-module SHA-256 and a recomputed root digest (`:11`);
  the four matrices propose "NEW module" **17** times; the Lisp path is at 400/400 lines
  (`files-and-roles.sexp:1090-1091` per `gates-matrix` A-7(v)) against `ver-02`'s budget (`GATE:179`).
- **Why it is a blind spot.** Each batch must re-declare six floors, re-pin `ROOT.sexp`, and stay inside a kernel
  budget that has no remaining line. None of these is expressed as a *forecast*; they are discovered at run time.
- **Check that exposes it.** A per-batch **dry-run budget forecast** artifact: predicted new facts per family,
  predicted new modules, predicted kernel line delta — asserted against the batch's actual result afterwards.

#### BS-15 — floors protect the corpus families; the constitutional families are unfloored

- **Evidence.** The six `universe-floor` facts cover `fixture, property-family, falsifier, gen-artifact, seat, tool`
  (`VC:60-70`). There is no floor on `type` (60), `subsystem` (26), `consumes` (102), `store` (10), `stage` (8),
  `req-map` (29), `rationale` (5), and none on the eight public/private edge families of
  `CP/V1.8-SCHEMAS.sexp:264-265` (which are not model families at all). FH-06 makes the same point for
  `api-mcp-schema`/`publication`: retire the surface and the family becomes empty while the boundary check passes.
- **Check that exposes it.** Extend the floor family to every fact type the constitution names, or replace floors
  with exact declared cardinalities per family (the `property-family` pattern) for the constitutional set.

#### BS-16 — "one canonical write authority per store" is enforced in one direction only

- **Evidence.** `MS:319` `(define-unique STORE-OWNER-IS-ONE-SEAT :type store :field owner)` — uniqueness on
  `owner`, none on `writer`. `stores-and-authorities.sexp:5-14`: `SEAT-WRITE-AUTHORITY` is the writer of
  `journal`, `legal-ir` and `memory`; `SEAT-NO-WRITER` of `resolver-dataset`, `static-site`, `tenant-profile`.
  The held-out falsifier `X43-RIVAL-STORE-WRITER` (`VC:214-216`) appends a second store claiming
  `:owner SEAT-JOURNAL` — it tests the owner direction only. FH-11 independently reports that `store memory` has a
  declared writer the code never uses.
- **Why it is a blind spot.** The prose (`MS:153-154`) says "exactly one owner seat and exactly one writer seat";
  the mechanism says "one store per owner seat, any number per writer seat". Whether that is intended is a
  decision — that nothing states it is the blind spot.
- **Check that exposes it.** FP-05 below (Alloy), or a `define-unique` on `writer` with the three shared writers
  declared as explicit exemptions.

#### BS-17 — "one canonical serialization boundary" while two exist, and the three "independent" implementations are two languages in one repository

- **Evidence.** FH-01 (`cl-freedom-hunter/findings.md:14-38`): `MS:37` `:canonical-encoding "AMC2"` +
  `AM/CANONICAL-ENCODING.md:1-30` versus `source/journal.lisp:61 canon-sexp`, which DDI-2 would import as *the ONE*
  serialization seat for every hash-bearing record body; `LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:34`
  claims a single boundary. `AMC2` appears 5× in the DDI-1 map and 0× in DDI-2/3/4.
  `AM/CANONICAL-ENCODING.md:70-74`: the three implementations are `KERNEL/model-law-kernel.lisp`,
  `CHECKER/independent_check.py` and `SEXP-READER.py` — **two of the three are Python in the same tree**, and
  FH-02 shows `canon-sexp`'s value domain (NIL/keyword/string/integer/list, `NIL` ≡ `()`, Lisp upcasing) is a
  CL-typed domain being written into a cross-language identity contract.
- **Check that exposes it.** A one-seat check over serialization: exactly one function in the tracked tree may be
  cited as canonical for a hash-bearing body, and its citation must be a model fact.

#### BS-18 — the target of the future full-build stage is not in the repository

- **Evidence.** `gates-archaeology` §5: the phrase "Full build, all 20 gates" occurs in no tracked file, commit
  message, dialogue record, packet or script over 517 commits and 7 refs; the only in-repo list of exactly 20 gates
  is the stale plenary figure (`deployment/LAWMAX-REPO-ONTOLOGY-MAP.sexp:14 :gates 20`,
  `LAWMAX-CONSOLIDATION-PLAN.md:9`) which is not that list, while `deployment/verify/gate-registry.sexp` declares
  itself the one source of truth with 25. `GATE:230-231` names the original 20 as "a mandatory future stage".
  `gates-matrix` U-3 and `W/my-gate-mapping.md` ("Caveat (decisive)") both record that every survival status is a
  status **over the CORE model** (4 imported classes) and acquires a DDI dependency over the full model.
- **Why it is a blind spot.** Any future statement of the form "the ceiling is reached" would be measured against a
  target that exists only outside the repository. `gates-skeptic` S-8 supplies the verbatim question to the creator.
- **Check that exposes it.** Commit the Option-A definition as a model artifact (a `gate-lineage` fact family is
  proposed by `gates-matrix` A-8) so that "which gates, over which model" becomes a closed reference.

#### BS-19 — the schema extensions DDI needs are being designed per-row, and two rows of one batch already contradict each other

- **Evidence.** `matrix-attack-A/findings.md` MA-01 (P1): DDI-2 declares a NEW fact type `field-rule` **twice**
  with incompatible field sets — `V1.5 define-cardinality-matrix` gives `:required (field when-enum when-value
  cardinality)` with `field-cardinality` = 7 members, `V1.8 define-cardinality-table` gives
  `:required (record when-field when-value field cardinality)` with `field-cardinality` = 4 members — while the
  first row calls it "ONE family shared". Under `MS:9-13` (allowed field set = `:required ∪ :optional`, nothing
  else) each declaration makes the other's facts a typed L1 violation, and the V1.5 data (`CP/V1.5-SCHEMAS.sexp:47-62`,
  48 rows using members `R`/`F`/`C`) is out-of-domain under the V1.8 declaration. MA-02 (P1): `enum`/`enum-value`
  is declared with **three** different field sets across the four DDI-2 enum classes, and two of the four assert
  "the same NEW family" while repeating a flattening sentence a third declaration forbids. Independently:
  `ADJ-DDI3-MOD-1` records that the module NAME for the DDI-3 layer is stated three ways by three dossiers, and
  the four matrices say "NEW module" 17 times.
- **Why it is a blind spot.** The model has one seat per concept for *facts*; the *schema extension* that DDI
  requires has no seat at all. It is currently an emergent property of 56 independently-written matrix rows, and
  `MS:9-13` guarantees that a divergence is not a style difference but a fatal L1 violation at import time.
- **Check that exposes it.** A single `proposed-schema` artifact in which every new fact type, enum and module is
  declared exactly once, plus a check that every row citing a new family cites that one declaration by id — the
  same discipline `define-fact-type` already imposes on the model itself.

#### BS-20 — nothing decides whether a PROPOSED falsifier can discriminate

- **Evidence.** The model's falsifier family is fully specified (`MS:245-260`: `:harness` as a closed reference,
  mutation kinds `APPEND REPLACE CHECK GATE`, `:kernel-reason`/`:checker-reason` that each path must name) and
  floored at 80 (`VC:64`). The batch plans propose new falsifiers in prose, and the adversaries found the whole
  spectrum of ways a proposed one fails to discriminate: already covered by an existing row and undisclosed
  (MA-03 P2; `matrix-mediocrity-A` M8, M9); a `REPLACE` target the mutation engine will not hit (MA-04 P2);
  a `:reason` token no check emits (`matrix-attack-B` B-01 P2); a rejection mechanism the same cell does not
  declare (B-03 P2); **two admissible outcomes, so it cannot fail** (B-04 P2); a key its own fact family does not
  declare (B-06 P3); unrejectable (M11); and "DDI-4's whole falsifier column is prose, not corpus rows"
  (`matrix-mediocrity-B` §3).
- **Why it is a blind spot.** `fls-01` (`GATE:199-202`) verifies that the corpus's falsifiers are all rejected; it
  cannot ask whether a falsifier *would have passed* on a healthy model. A falsifier rejected for the wrong reason,
  or one whose defect is already covered, raises the count and adds nothing — and the count is what the floor
  protects.
- **Check that exposes it.** Two-sided discrimination per falsifier: rejected on the mutated model **and** NOT
  rejected on the unmutated one, with the emitted reason string required to equal the declared
  `:kernel-reason`/`:checker-reason` — plus a duplicate-coverage check against the existing 80.

#### BS-21 — rollback is a template, and in three places it is not executable

- **Evidence.** `matrix-mediocrity-A` M1 (P1): the DDI-2 rollback "cannot restore ROOT for any row that proposes a
  NEW module"; M2: "the DDI-2 rollback's ledger step is not executable and contradicts DDI-1's"; M7: the DDI-1
  `writer` field is one 229-character template repeated verbatim in 10 of 12 rows. `matrix-mediocrity-B` §2 (P2):
  **9 of 10 DDI-3 rollbacks prescribe hand-editing a GENERATED file** — `deferred-imports.sexp` is generated by
  `build_deferred.py` and pinned by `ROOT.sexp`, so a hand-edit is exactly the defect `gen-02`
  (`GATE:169`) and `ro-01` (`GATE:221`) exist to catch.
- **Why it is a blind spot.** Rollback is the one column of the migration plan that is never exercised: it is
  written per row, read by no checker, and its failure mode only appears after a batch has already been imported.
  The Common-Lisp-native contract admits a mechanism only with a rollback
  (`CP/LAWMAX-COMMON-LISP-NATIVE-CONSTRUCTION-CONTRACT.md:20-35`) — 56 such rollbacks now exist and none has run.
- **Check that exposes it.** A rollback dry run per batch in a scratch worktree: after import-then-rollback, the
  `canonical-model-root-digest` must equal the pre-batch value, `gen-02`, `ro-01` and `led-01` must pass, and no
  generated module may have been hand-edited (its regeneration must be byte-identical).

---

### B. WHAT MUST BE CHECKED AFTER THE FULL BUILD (post-DDI-4) — concrete and machine-checkable

Every item is stated as a check with a decidable verdict. "Fails today" means the check would fail on the model at
4ee2b58a and is therefore already runnable as a red test. Nothing here proposes a decision; each item is the
*measurement* of whatever the creator decides.

| id | check (machine-checkable statement) | anchor at HEAD |
|---|---|---|
| **PB-01** | `led-01` reports `DEFERRED-IMPORT LEDGER: PASS` with **0** `source-class` facts of `:status DEFERRED_DATA_IMPORT`, 60 IMPORTED and 6 OUT_OF_MIGRATION_SCOPE, total still **66 / 435 forms** (multiset equality with the scanned sources) | `GATE:205-208`; `build_deferred.py:38-44`; `deferred-imports.sexp` |
| **PB-02** | Every imported row satisfies `CLASS-IMPORTED` (`:maps-to` present, `:batch` absent) and the `IMPORTED` dict in `build_deferred.py:75-80` has exactly 60 entries — i.e. the hard-coded dict was grown, not bypassed | `MS:313-314`; `build_deferred.py:75-80` |
| **PB-03** | `promotion PROMOTION-GLOBAL` is `:state PERMITTED` **and** `X44-GLOBAL-PROMOTION-OVERCLAIM` still rejects a model in which any class is deferred — i.e. the falsifier was re-authored, not left vacuous | `deferred-imports.sexp:75-76`; `VC:217` |
| **PB-04** | Ledger-shaped falsifiers are non-vacuous after the flip: `K17-DUPLICATE-LEDGER-ROW`, `K18-MISSING-SOURCE-FILE`, `G07-UNADJUDICATED-SOURCE` each still have a reachable defect, and a NEW row exists whose mutation deletes exactly one existing `source-class` row (the missing successor of gate 21) | `VC:159-160,228`; `build_deferred.py:218`; `gates-matrix` A-3 |
| **PB-05** | Field-level coverage: for each of the 60 imported classes, the set of source-form keys minus the set of keys represented in the model is either **empty** or fully enumerated in a declared-loss artifact; no undeclared drop | `W/imported-field-coverage.json` (4 classes, 26 dropped keys today) |
| **PB-06** | `sea-01` passes and `UF-SEAT` equals the new `seat` count, with `PF-L3-DANGLING-SEAT :cardinality` equal to it in the same commit; likewise `UF-FIXTURE`, `UF-FALSIFIER`, `UF-PROPERTY-FAMILY`, `UF-GEN-ARTIFACT`, `UF-TOOL` re-declared upward (never downward without a base-anchored `universe-authorization`) | `GATE:174,189`; `VC:51-53,60-70`; `MS:258-282` |
| **PB-07** | `ROOT.sexp` `:module-count` equals the number of pinned modules **and** every new DDI module is classified by an existing rule in `classification-rules.sexp` with no `UNCLASSIFIED` and no catch-all | `ROOT.sexp:12-28`; `KRN:294-313`; `GATE:172` |
| **PB-08** | `ver-02` passes: kernel + hash-provider non-blank non-comment lines ≤ 400 after whatever kernel work the new fact families required (today exactly 400) | `GATE:178-181` |
| **PB-09** | `tcb-01` passes with every line of acceptance-machinery growth attributed to a `finding-id` in the closed enum; no attribution to an unknown finding (`X77`) | `GATE:182`; `MS:74-76`; `VC` X77 |
| **PB-10** | L4 holds over **every** edge relation the import created — i.e. `edge-relations` (`KRN:211-218`) enumerates more than `stage-edge`/`gen-edge`, and each new relation has its own `property-family` with an exact cardinality (`PF-L4-STAGE-CYCLE :cardinality 8` is not silently reused) | `KRN:219-229`; `VC:54-56` |
| **PB-11** | The cognition graph is imported as one seat: exactly one canonical cognition-DAG fact set exists (not V1.6 12-stage **and** V1.7 14-stage **and** V1.8 20-node), and every node of the canonical set is typed | `CP/V1.6:217-229`, `V1.7:80-94`, `V1.8:53-65,363-383`; ADJ-DAG-08 |
| **PB-12** | Edge identity carries its family: the duplicated pair `(CLARIFY-DECIDE RESOLVE)` — listed in both `:flow-edges` and `:branch-edges` — yields two distinct ids or one declared merge, never an L2 collision | `CP/V1.8-SCHEMAS.sexp:59,60`; ADJ-V18-COG-2 |
| **PB-13** | L5 after import: the number of PRIVATE `type` facts equals `PF-L5-PRIVATE-TYPE-LEAK :cardinality`, `PrivateMemoryEvent/1` has a decided classification, and **each** of the eight declared edge families is either a model relation with a non-zero cardinality or explicitly declared out of the closure | `CP/V1.6:312`; `interfaces-and-types.sexp:24,41,44,51,58,59`; `VC:45-47`; `CP/V1.8:264-283` |
| **PB-14** | L6 after import: every `RA-*`/`RA8-*` requirement and every `RA-Q-*`/`T8-*` test cited by an imported capability seat resolves to a `requirement`/`test` fact, and the requirement universe has a declared seat (not a derivation) | orchestrator N1/N8; `KRN:255-266` |
| **PB-15** | `wp` has exactly one origin: either the `define-subsystem :future-wp` derivation or `define-wp-purpose` (16 rows incl. WP-00/WP-05/WP-10), never both; `DEFERRED` is not a `wp` id | orchestrator N2; `requirements-tests-workpackets.sexp` |
| **PB-16** | Every anonymous singleton form has a synthesised id produced by **one declared rule**, and the rule is a model artifact; the 7 forms of orchestrator N11 all resolve; `cognition->existing-lisp-seat` (`CP/V1.6:231`) is renamed into TOKEN charset with the rename recorded | `MS:38-40` (TOKEN charset); N11/N12 |
| **PB-17** | Flattening is total and declared: no source form with a nested list was imported as an opaque string. Check: no imported fact carries a value that contains `(` or `)`, and every nested structure has a corresponding fact family | `MS:5-6` (L1 value kinds); N4 |
| **PB-18** | Batch order was a linear extension: replaying the declared batch sequence against the blocking-edge relation yields 0 violations, or every remaining violation names the adjudication that authorised it | `DAG.md:553-556` (33 conflicts today) |
| **PB-19** | Every ADJ-* item raised by this reconnaissance has a recorded disposition (`CLOSED_AT_SEAT` / `REFUTED_WITH_PROOF` / `RESIDUE_WITH_DEATH_PHASE`), and the count of items with no disposition is **0** | CLAUDE.md protocol; `W/adjudications.json` (784 rows at 06:29:35, 0 dispositions) |
| **PB-20** | Documentation closure: every `X\d+`, `K\d+`, `PF-*`, `G\d+`, `FX-*`, `UF-*` id mentioned in any `AM/*.md` resolves to a fact in `VC`; fails today on `X46`, `X47`, `PF-ENC-INJECTIVITY` | `AM/CANONICAL-ENCODING.md:82-87` |
| **PB-21** | Rationale anchors resolve: for every `rationale` fact, `:doc` exists and `:anchor` occurs at least once in it; fails today on `RAT-PUBPRIV` | `rationale-references.sexp:7`; N17 |
| **PB-22** | Registration closure in the runners: every `def f\d+_…` in `run_corpus.py` appears in exactly one registration table and every registered name resolves; fails today on `f19_restore_instead_of_compare` | `run_corpus.py:811,1343,1370`; `gates-matrix` A-4 |
| **PB-23** | Informational is not a hiding place: the set of properties with no counted check is enumerated as facts and its cardinality is reported next to `pass/fail/informational` | `GATE:89,224-227,229` |
| **PB-24** | Re-run of the original 20 candidate gates **over the full model**, with each result labelled `over-full-model`; the two structurally-inverted ones (G20 requires a DEFERRED row to exist; G21 drops an IMPORTED row) must be re-authored before they can be run at all | `gates-skeptic` S-1; `a2f45f6d:GATE:94,96` |
| **PB-25** | Every new fact type, enum and module introduced by any batch is declared **exactly once**; no two rows declare one family with different field sets (fails today on `field-rule`/`field-cardinality` and on `enum`/`enum-value`), and `MODEL-SCHEMA.sexp`'s `:version` strictly increases in the commit that adds any of them | `MS:9-13`; MA-01, MA-02; `AM/CANONICAL-ENCODING.md:48-51` |
| **PB-26** | Every falsifier added by a batch **discriminates**: rejected on the mutated model, NOT rejected on the unmutated one, its emitted reason equal to its declared `:kernel-reason`/`:checker-reason`, and no duplicate of an existing row's defect class | `MS:245-260`; `GATE:199-202`; MA-03, MA-04, B-01, B-03, B-04, M8, M9, M11 |
| **PB-27** | Rollback dry run per batch: import, roll back, and require `canonical-model-root-digest` equal to the pre-batch value with `gen-02`, `ro-01`, `led-01` all passing and every generated module byte-identical after regeneration (no hand-edit) | `GATE:169,208,221`; `matrix-mediocrity-A` M1/M2; `matrix-mediocrity-B` §2 |
| **PB-28** | The two blocking edges the DAG's attacker found missing are present in whatever order artifact drives the build: `V1.8 define-ra-delta-seats → V1.8 define-record` and `define-subsystem → define-wp-purpose`; and the three `:future-wp` tokens that resolve to no `define-wp-purpose` id (`DEFERRED`, `WP-07+WP-08`, `WP-07+WP-11+WP-14`) are either resolved or declared | DA-01, DA-03 |

**Machine-checkable, non-negotiable arithmetic to re-assert after the build** (each a single equality):
`source-class` = 66; imported = 60; deferred = 0; forms = 435; DDI-1 12 classes / 40 forms, DDI-2 18 / 156,
DDI-3 10 / 12, DDI-4 16 / 124 (`W/census.json`, BRIEF §census). Any batch that changes these numbers changed the
source universe, which `led-01` must then reject.

---

### C. CANDIDATE FORMAL PROPERTIES (Alloy / TLA+ / SMT / Lean)

Each property is stated over the model's own fact types, then a tool with the reason it is the right one.
None of these has been written; they are candidates for the future review to commission.

**FP-01 — L2 one seat (Alloy).**
`sig Fact { type: one FactType, id: one Id }` with
`all disj f1, f2: Fact | f1.id = f2.id implies f1.type = f2.type` (an id is owned by one fact type) and, per
`define-unique U(:type T, :field K)`, `all disj f1, f2: Fact | f1.type = T and f2.type = T implies f1.K != f2.K`.
Instantiate the four declared uniques (`STORE-OWNER-IS-ONE-SEAT`, `ARTIFACT-PATH-IS-ONE-SEAT`,
`FIXTURE-PATH-IS-ONE`, `TCB-PATH-IS-ONE`, plus `SEAT-PATH-UNIQUE`) — `MS:308,319-322`.
*Why Alloy:* L2 is a pure finite relational constraint; Alloy's value is the counterexample instance it prints when
a new DDI family reuses an id space, which is exactly the DDI-2 risk (`ADJ-DAG-05`: `CensusSpaceClassification/1`
is already owned by `type`).

**FP-02 — L4 acyclicity of every derived edge relation (Alloy).**
For each fact type `E` whose `:ref` maps both `from` and `to` to the same single target type `N`
(`KRN:211-218` computes this set): `sig N {}` , `sig E { from: one N, to: one N }`,
`no n: N | n in n.^(from.~to)` — i.e. `acyclic[to.~from, N]`. Today `E ∈ {stage-edge, gen-edge}`; after DDI-3 it
must include the cognition edge family.
*Why Alloy:* transitive closure (`^`) is primitive, the relation is small (8 stages, ~20 cognition nodes), and the
interesting question is not "is this instance acyclic" (checkable by DFS) but "can any legal instance of the schema
be cyclic while every other law holds" — a scope-bounded model-finding question.

**FP-03 — cognition-graph-v8 acyclic-except-resume (Alloy, with an explicit resume predicate).**
`sig CogNode {}`, `sig CogEdge { from, to: one CogNode, family: one Family }`,
`Family = FLOW + BRANCH + RESUME + TERMINAL`. Two properties, stated separately because the review currently
disagrees about which is true (§E ADJ-FR-01):
(i) `acyclic[(from.~to) restricted to FLOW+BRANCH+TERMINAL]`;
(ii) `acyclic[(from.~to) over all four families]` — my own topological computation over
`CP/V1.8-SCHEMAS.sexp:53-65` says (ii) holds for the graph as written, `matrix-DDI-3/matrix.md:238` says the same,
and `DAG.md:533,867` presupposes it does not.
Plus: `all t: Terminal | no t.~from` (no terminal has an outgoing edge — holds today) and
`all n: CogNode | n in entry.*(from.~to)` (reachability from `:entry PERCEIVE`).
*Why Alloy:* it can prove (ii) for the fixed instance **and** search for the smallest future edge that breaks it
(the answer "a resume edge back into CLARIFY-DECIDE" is the design constraint worth writing down).

**FP-04 — L3 closed typed references (Alloy).**
For every `(k, T₁…Tₙ)` in a fact type's `:ref` declaration: `all f: Fact | f.k in (T₁ + … + Tₙ).id`.
The interesting corollary to check is *non-vacuity*: `some f: Fact | f.k != none` for each declared ref key — a
reference universe that is empty type-checks trivially.
*Why Alloy:* L3 is a containment property over a heterogeneous relation set; Alloy expresses "closed universe"
directly and finds the instance where a new DDI family points at a family that does not exist yet.

**FP-05 — store: one owner, one writer, and the direction question (Alloy).**
`sig Store { owner: one Seat, writer: one Seat }`; the declared law is
`all disj s1, s2: Store | s1.owner != s2.owner` (`MS:319`). The candidate property to *decide* is the dual,
`all disj s1, s2: Store | s1.writer != s2.writer`, which is **false** at HEAD (`SEAT-WRITE-AUTHORITY` writes
3 stores, `SEAT-NO-WRITER` 3 — `stores-and-authorities.sexp:5-14`). State both, mark which is intended, and
generate the counterexample for the other.
*Why Alloy:* the whole question is a cardinality of a relation; Alloy answers it in one `check` and prints the
three-store witness.

**FP-06 — L5 public/private isolation as a REACHABILITY property (Alloy first, SMT if it must scale).**
`sig Node { class: one Classification }` ranging over `subsystem + component + type`;
`sig Edge { src, dst: one Node, family: one EdgeFamily }` with
`EdgeFamily = FieldType + RefTarget + InterfaceIO + SubsystemDep + StoreOwnerWriter + ApiMcpSchema + Publication + Declassification`
(`CP/V1.8-SCHEMAS.sexp:264-265`). Property:
`no p: Node | p.class = PUBLIC and some q: Node | q.class = PRIVATE and q in p.^(src.~dst)`
— **transitive**, over all eight families, with `Declassification` as the single declared exception edge
(`:V8I-PUBPRIV-all-families`, `:277-283`). Compare with what the kernel does today: one step, one family
(`KRN:243-254`). Also state the fail-closed clause as a property: an edge whose endpoint kind is undecidable must
make the model *unsatisfiable*, not merely unclassified (`MS:49`, `KRN:248`).
*Why Alloy:* `^` gives the closure for free and the counterexample is a path, which is the artifact a reviewer needs.
*Why SMT as an alternative:* if the closure must run over the full imported graph (102 `consumes` today, far more
after DDI-2), reachability encodes naturally as a Horn/Datalog query for Z3's fixedpoint engine, which scales past
Alloy's scope bound and can produce the same path witness.

**FP-07 — L6 requirement → seat → test → WP closure (Alloy).**
`all s: Subsystem | some m: ReqMap | m.subsystem = s and m.seat = s.ownerSeat and one m.requirement and one m.test and one m.wp`
plus the universe clause that is the actual blind spot (BS-09):
`Requirement = ran(ReqMap.requirement)` is what the model enforces today; the property worth stating is
`DeclaredRequirementRegistry = Requirement` for a registry that does not yet exist.
*Why Alloy:* the chain is a composition of four relations; Alloy states composition closure in one line and shows
the subsystem with no map (which is exactly `PF-L6-UNMAPPED-SUBSYSTEM`, 26 cases, `VC:42-44`).

**FP-08 — AMC2 `enc` injectivity, and the injectivity of the fact render (SMT, then Lean).**
Let `enc(s) = decimal(|utf8(s)|) ‖ ":" ‖ utf8(s)` (`AM/CANONICAL-ENCODING.md:25`). Three lemmas:
(i) `∀ s, t. enc(s) = enc(t) → s = t`;
(ii) `∀ a b c d. enc(a) ‖ enc(b) = enc(c) ‖ enc(d) → a = c ∧ b = d` (unique parseability of concatenations);
(iii) the fact-level statement — for facts `F₁ ≠ F₂` (different type, id, key set, or any value),
`render(F₁) ≠ render(F₂)`, where `render` is `enc("AMC2") ‖ enc(ver) ‖ enc(TYPE) ‖ enc(ID) ‖ enc(decimal(n)) ‖ pair₁ … pairₙ`
with pairs sorted as **encoded strings** (`:37-40`).
*Why SMT (Z3/CVC5 strings):* (i) and (ii) are exactly the sequence/length theory these solvers decide, and the
delimiter-collision witness that killed AMC1 (`:12-15`) is the kind of counterexample they produce automatically.
*Why Lean for (iii):* (iii) quantifies over arbitrary fact sets and a sort order; a bounded solver can only refute
it, while the claim in the document is universal. A ~50-line Lean proof (injectivity of length-prefix ‖ injectivity
of sorted-multiset encoding) converts the strongest prose claim in the model into a checked theorem.
*Note (not a decision):* lemma (iii) has a stated precondition worth making explicit — sorting the **encoded pair
strings** rather than the keys means two different key sets could interleave; that is precisely what the missing
`PF-ENC-INJECTIVITY` (BS-01) was supposed to probe.

**FP-09 — universe-floor monotonicity across commits (TLA+).**
State `⟨floors, authorizations, modelRoot, baseCommit⟩` per commit; `Next` = one commit.
`Safety ≜ ∀ fam ∈ Families : floors'[fam] ≥ floors[fam] ∨ ∃ a ∈ authorizations_base :
   a.family = fam ∧ a.previous_minimum = floors[fam] ∧ a.minimum = floors'[fam] ∧
   a.previous_model_root = modelRoot(parent(base)) ∧ a ∈ candidate` — i.e. floors never fall except by a
base-anchored, prospective, single-use authorization (`MS:258-282`).
Two liveness/safety corollaries worth model-checking: **spend-once** (`a` cannot authorise a second reduction once
the floor has moved — replay must fail on `previous_minimum`) and **no self-authorisation** (an authorization that
appears only in the candidate is a finding, never a permission).
*Why TLA+:* this is a property of a *history of commits*, not of one model; the base/candidate/parent relation and
the "spent once" behaviour are temporal, and TLC will find the replay trace. Alloy cannot express "across commits"
without hand-rolling a time signature; SMT cannot express the trace at all.

**FP-10 — promotion monotonicity and the ledger flip (TLA+, same specification).**
`PROMOTION-GLOBAL.state` may move `FORBIDDEN_UNTIL_DDI_COMPLETE → PERMITTED` **only** in a step where the count of
`source-class :status DEFERRED_DATA_IMPORT` reaches 0, and never back (`deferred-imports.sexp:75-76`).
Add: `∀ c ∈ SourceClasses : status(c) ∈ {DEFERRED, IMPORTED, OUT_OF_SCOPE}` and status transitions are
`DEFERRED → IMPORTED` only — a class never returns to deferred, and `OUT_OF_MIGRATION_SCOPE` is terminal.
*Why TLA+:* the whole point is the ordering of two state changes over commits and the impossibility of a rollback.

**FP-11 — L7 exact module/hash universe (TLA+ for the history part, Lean/none for the crypto part).**
Checkable part: `moduleSet' = declared(ROOT')`, `|declared(ROOT')| = ROOT'.module_count`, `schema_version` strictly
increases whenever `MODEL-SCHEMA.sexp` bytes change (`AM/CANONICAL-ENCODING.md:48-51`; falsifiers X74/X75/X76).
Not provable: that the digest binds. State honestly that L7's strength is SHA-256's and nothing more
(`AM/CANONICAL-ENCODING.md:89-92` already says this).
*Why TLA+:* "strictly greater than the base's version whenever the bytes differ" is a two-commit invariant.

**FP-12 — the deferred ledger is a bijection onto the source universe (Alloy or SMT).**
`source-class` facts ↔ (source file, top-level form head) pairs discovered by the scanner:
`∀ p ∈ Scanned : ∃! c ∈ SourceClass : (c.source_file, c.fact_class) = p` and
`∀ c ∈ SourceClass : (c.source_file, c.fact_class) ∈ Scanned` and `Σ c.source_count = 435`.
*Why SMT:* it is a counting/bijection statement over finite sets with an arithmetic side condition — trivial for a
solver, and it is the property `led-01` implements in Python today with no independent statement.

**FP-13 — the batch order is a linear extension of the blocking relation (SMT).**
Given `blocking ⊆ Class × Class` (161 edges, `W/agents/dag/order.json`) and `batch : Class → {1,2,3,4}`:
`∀ (u,v) ∈ blocking : batch(u) ≥ batch(v)` — with the atomic groups AG-01…AG-10 as equality constraints
(`batch(u) = batch(v)`) and the two cycles as declared co-import units.
Ask the solver two questions: (a) is the *declared* map a model? (no — 33 conflicts); (b) is there **any** total
assignment into 4 batches satisfying all constraints, and is it unique up to renaming?
*Why SMT:* this is a finite-domain constraint problem with an optimisation flavour ("minimum number of classes that
must move"), which Z3's `Optimize` answers directly and Alloy answers only by enumeration.

**FP-14 — the closed field set and the value grammar (Lean, or SMT for the decidable half).**
`∀ f : Fact. keys(f) ⊆ required(type(f)) ∪ optional(type(f)) ∧ required(type(f)) ⊆ keys(f)` (`MS:9-13`), and
`∀ v ∈ values(f). v ∈ String ∪ Int ∪ Symbol[A-Za-z0-9_.+/-]` with **no** keyword, nested list, or NIL (`MS:5-6`).
The DDI-relevant theorem is the **flattening round-trip**: for a chosen flattening `Φ` from source forms with
nested lists to sets of facts, `Φ` is injective and `Φ⁻¹ ∘ Φ = id` on the six registries — i.e. no source form's
information is lost or aliased by the flattening.
*Why Lean:* the round-trip is a universally-quantified statement about a translation function, exactly what a proof
assistant is for; a solver can only test it on the 435 forms present, which is useful but is not the theorem.
*Why SMT for the half:* the value-grammar membership and the id-charset/`min`/`max` constraints (`MS:38-42`) are
regular-language questions the string solvers decide, including the DDI-2 rename of
`cognition->existing-lisp-seat` (N12) and the 92 keyword-named invariants that become TOKEN ids after stripping `:`.

**FP-15 — the acceptance gate's own counting rule (Alloy, small but load-bearing).**
`pass + fail = countedChecks`, `note ⇒ ¬countable`, and the property the gate states about itself at `GATE:26-28`:
"a check that cannot fail is not a check". Model a check as `sig Check { canFail: one Bool, counted: one Bool }`
with `all c: Check | c.counted implies c.canFail`. The interesting instance is the historical defect F-10
("ck01 structurally unable to fail") — a counted check with `canFail = False`.
*Why Alloy:* it makes "structurally unable to fail" a stateable predicate rather than a review opinion; the model
is what forces the gate to declare, per check, the defect class it can name.

---

### D. ISSUES FOR THE FINAL RED TEAM

Three surfaces, as commissioned: the acceptance machinery, the migration itself, and the public/private boundary.
Each item is an attack to attempt, with the exact place to attack and what a success would look like.

#### D.1 Attack surface: the acceptance machinery

- **RT-01 — Judge the judge.** The gate exports the candidate's own machinery and runs the checks from that export
  (`GATE:120-132`, `prv-01`). Attack: craft a candidate whose exported `gate_checks.py` is subtly weaker (e.g. a
  check that returns 0 on an exception) and see whether `prv-01` — which proves *identity* with the candidate, not
  *fitness* — still yields a PASS. Success = a self-weakened candidate certifying itself. Related: `K21-SELF-CERTIFIED-PASS`
  (`VC:162`) covers the missing-path case, not the weakened-path case.
- **RT-02 — Vacuous subsets.** `sub()` (`GATE:90-98`) was hardened after a battery that ran zero cases printed
  `not-rejected=0` and passed. Attack the same class one level down: a *component* falsifier run whose corpus filter
  matches nothing, or a `property-family` whose generator yields its exact declared cardinality of trivially-true
  cases. Success = `fls-01`/`fix-01` PASS with no real case executed.
- **RT-03 — The unregistered function.** `f19_restore_instead_of_compare` (`run_corpus.py:811`) is in the TCB line
  count and in no registration table (`gates-matrix` A-4). Attack: add a second such function that *is* imported by
  a registered one, and check whether `cor-01`'s AST reading of the two tables (`gate_checks.py:617-631`) still
  believes the corpus universe is exact.
- **RT-04 — Notes as a hiding place.** `note()` cannot fail (`GATE:89`). Attack: move a property that currently
  fails into a note and observe the summary line still reading `fail=0`. Success = a demotion that is
  indistinguishable from a fix in the gate's own output.
- **RT-05 — Floors at exactly the floor.** Every floored family sits exactly on its minimum (BS-14). Attack the
  authorization path: `X66-AUTHORIZATION-REPLAY`, `X67-AUTHORIZATION-CANDIDATE-INJECTED`,
  `X64-AUTHORIZATION-WRONG-PREVIOUS-ROOT` exist; try the combination they do not cover — a *coherent* addition then
  removal across two commits (raise the floor with the family, then lower both, each step individually legal).
- **RT-06 — Documentation as a second seat.** `AM/CANONICAL-ENCODING.md:82-87` names three artifacts that do not
  exist (BS-01) and `LEGACY-AUDIT-DISPOSITION.md:6` names a `NON_AUTHORITATIVE_GATE` role that is not in the enum
  (`gates-matrix` A-6, N14). Attack: how many *other* normative `.md` claims name machinery that is absent? Each one
  is a place where a reader believes a check exists.
- **RT-07 — The gate's own writes.** `ro-01` compares a `content-state` before and after (`GATE:103,219-221`) and
  `G01-GATE-WRITES-TO-TREE`/`G08-TMP-COLLISION` cover the obvious cases. Attack the measurement itself: a write that
  occurs *inside* `gate_checks.py content-state`'s own execution, or a path class the content-state does not
  enumerate.
- **RT-08 — The toolchain on one host.** `tch-01` pins tools by digest (`GATE:165`, `TOOLCHAIN.sexp`, 5 tools = the
  floor). Orchestrator N6: the pins are Ubuntu-24.04-specific and `sbcl`/`clingo` are absent in this container.
  Attack: what does the gate do on a host where a pinned digest cannot exist — refuse (correct) or degrade?
  `X71/X72/X73` cover missing/unexecutable/vanishing; the *unreproducible-host* case is the one to try.
- **RT-09 — Three implementations, two languages, one tree.** `enc-01` requires the Lisp kernel, the Python checker
  and the Python reference to agree (`AM/CANONICAL-ENCODING.md:70-74`). Attack: a defect that all three share
  because two are Python written from the same reading of the same document. Success = a rendering both Python
  implementations produce identically and a from-scratch third-party implementation does not.

#### D.2 Attack surface: the migration itself

- **RT-10 — The batch map as an unguarded literal.** `build_deferred.py:87-107` is a dictionary; nothing checks it
  against dependency order (BS-13), and 34/56 rows disagree with it. Attack: swap two entries and see which counted
  check notices. Expected answer today: none.
- **RT-11 — Strings that look like references.** `ADJ-DAG-01`'s explicitly NOT-PROPOSED option is "import the
  references as strings" — L1 accepts a string, L3 never checks it. Attack the general form: after DDI-2, how many
  imported values are strings that *name* a fact but are not typed refs? A single grep-shaped check
  (`value matches an existing fact id but the key has no :ref declaration`) should be part of the build.
- **RT-12 — Comment-sourced evidence.** BS-07: one blocking edge's textual evidence is a `;;` comment
  (`CP/V1.8-SCHEMAS.sexp:274`). Attack: how many of the 161 blocking edges survive if comments are excluded from the
  form extent, and does any *adjudication* rest on a comment?
- **RT-13 — Anonymous ids and the rename.** 7 forms have no atomic name (N11) and one atom is outside the TOKEN
  charset (N12). Attack the synthesis rule: construct two distinct anonymous forms that the proposed rule maps to
  the same id (e.g. `<head>__<file-stem>` collides for two anonymous forms of the same head in the same file —
  V1.7 and V1.8 each have exactly one `define-ra-closure-roots`, but `define-wp-reconciliation` appears in both).
- **RT-14 — Vacuous falsifiers after the flip.** PB-03/PB-04: `X44`, `K17`, `K18`, `G07` all describe defects that
  presuppose deferred rows. Attack: after a simulated DDI-4 completion, which held-out falsifiers can no longer fail
  for any input? Every one of them is a silent reduction of the corpus that no floor detects (the *count* stays 80).
- **RT-15 — Two seats for one concept, arriving one batch apart.** 17 classes carry same-name / competing-seat
  annotations (`DAG.md:388-414`). Attack: import order that lands `V1.6 define-record PerceptionEnvelope/1` and
  `V1.7 define-reference PerceptionEnvelope/1` in different batches and check whether anything but L2 (same id,
  different type) notices that one concept acquired two seats in two *different* families.
- **RT-16 — The identity encoding decision, made by default.** FH-01/FH-02: if DDI-2 imports record bodies with
  `canon-sexp` as canonical, the value domain of every future public contract is fixed to a CL type domain
  (NIL ≡ `()`, keyword upcasing) and content addresses can never be recomputed. Attack: find the first field whose
  value would render differently under AMC2 and under `canon-sexp` — FH-02 states honestly that none exists in the
  four registries today, which makes this a *forward* attack: construct the field that a future version would add.

#### D.3 Attack surface: the public/private boundary

- **RT-17 — Two hops.** BS-02/FP-06: L5 is one edge. Attack: a PUBLIC subsystem consuming a PUBLIC type that is
  structurally composed of a PRIVATE record (after DDI-2 gives records their fields). Success = a leak that passes.
- **RT-18 — The seven missing families.** Seven of the eight declared edge families have no model representation
  (`CP/V1.8-SCHEMAS.sexp:264-265`). Attack the two that are derived from replaceable surfaces: retire
  `source/mcp-server.lisp` or `source/static-site.lisp` and observe `api-mcp-schema` / `publication` become empty
  families that the boundary check reads as clean (FH-06).
- **RT-19 — The undecidable consumer.** `MS:49` and `KRN:248` say a consumer of unknown kind fails closed. Attack:
  after DDI-2 adds `consumer-role`-bearing types, find a consumer whose kind is decided by a *field the import
  dropped* — then the fail-closed branch never fires because the kind resolves, wrongly, to PUBLIC.
- **RT-20 — `PrivateMemoryEvent/1`.** `:status :DEFERRED_PRIVATE :public-dependency nil`
  (`CP/V1.6-SCHEMAS.sexp:312`), named in the V1.7/V1.8 private-forbidden lists
  (`CP/V1.8-SCHEMAS.sexp:262-263`), and **not** one of the 6 PRIVATE `type` facts
  (`interfaces-and-types.sexp:24,41,44,51,58,59`). Attack: import DDI-1's closure roots (which name it) before
  DDI-2 creates it, and check whether L3 catches the dangling reference or whether the root list is imported as a
  string (RT-11).
- **RT-21 — The split file.** `SUBSYSTEM-REGISTRY.sexp:130-134` declares `legal-casegrammar.lisp` as one tracked
  file with a PUBLIC general part and a PRIVATE client-fact part. Attack: the classification table
  (`classification-rules.sexp`) assigns one role per path; a file that is half private has no representable
  classification. Success = a PRIVATE fragment inside a PUBLIC-classified path.
- **RT-22 — The rationale that is not there.** BS-10/N17: the boundary's stated justification `RAT-PUBPRIV` points
  at an anchor that occurs 0 times in the document it names. Attack: are the other four anchors *semantically* what
  the seats claim, or merely present? (Presence is what a future check would test; the four resolve today.)
- **RT-23 — Governance path vs public build.** N6/FH-05/FH-09/FH-10: the acceptance path mandates CPython 3.11.15,
  clingo 5.8.2, SBCL 2.2.9 on one host, while `:V8I-02` (`CP/V1.8-SCHEMAS.sexp:17-19`) forbids a mandatory model or
  Python on the public path; the governance machinery is classified `GOVERNANCE_MACHINERY`, not `PRODUCTION_CODE`.
  Attack: identify one artifact that is produced by the governance path and consumed by the public build — if one
  exists, the classification boundary is not a boundary. (FH-05 supplies a candidate: the reliance-aggregation
  totality property whose only executor is `V1.8-VERIFY.py`, classified `HISTORICAL_EVIDENCE / NON_AUTHORITATIVE`,
  `files-and-roles.sexp:453`.)
- **RT-24 — V8I-02 for the cognition graph.** FH-14: the symbolic-only verdict for `cognition-graph-v8` is carried
  by evidence from the V1.7 graph it supersedes; the V1.8 form carries no `:symbolic-only`, no
  `:proposer-optional`, no `:seat` on any node, and the proposer plug-point is UNKNOWN. Attack: after DDI-3, is
  there any fact in the model that would *fail* if a mandatory proposer node were added to the cognition graph?
  If not, the guarantee is prose.

#### D.4 Attack surface: the plan's own artifacts (added after the eight adversarial passes delivered)

- **RT-25 — Execute two contradictory schema declarations.** BS-19: take the two DDI-2 rows that both declare
  `field-rule` and emit both fact sets into one candidate. Expected: a typed L1 unknown-field violation on
  whichever declaration is not in `MODEL-SCHEMA.sexp`. Success for the attacker = neither declaration was written
  into the schema and the facts were imported as strings instead (RT-11's shape).
- **RT-26 — A falsifier that cannot fail.** BS-20: submit a proposed falsifier with two admissible outcomes
  (B-04's shape) and one whose `:reason` no check emits (B-01's shape) and see whether anything but a human reading
  rejects them. Then submit a falsifier that IS rejected — but for a defect other than the injected one — and check
  whether `fls-01` can tell the difference. It cannot today: it counts rejections, not reasons.
- **RT-27 — Roll a batch back.** BS-21: import one batch in a scratch worktree, execute the batch's own written
  rollback verbatim, then run `gen-02` and `led-01`. A rollback that hand-edits `deferred-imports.sexp` will pass
  `led-01` (the row is gone) and fail `gen-02` on the next regeneration — a state in which the ledger and the
  generator disagree and only one of them is checked at a time.
- **RT-28 — The dossiers were never attacked.** BS-08: the six dossiers carry 162 adjudication items and are the
  substrate of every matrix row, and no adversarial pass took either axis over them. Run both axes over one dossier
  (V1.8, the largest at 65 items / 18 classes) and measure how much of what is found also applies to the other five.

---

### E. ADJUDICATION ITEMS RAISED BY THIS PASS (both sides cited; not resolved here)

- **ADJ-FR-01 — L4 and the cognition resume edges: two artifacts of this reconnaissance disagree.**
  Side A: `W/agents/dag/DAG.md:533` (DDI-3 exit criterion: "acyclic EXCEPT the two declared resume edges, which the
  current L4 has no exemption for") and `DAG.md:867-869` (recorded UNKNOWN).
  Side B: `W/agents/matrix-DDI-3/matrix.md:238` (with derivation from `KRN:211-218`: the graph "is checked acyclic
  INCLUDING resume edges — the listed graph passes … no exemption"), and dossier item `ADJ-V18-COG-2`.
  Third evidence: my own topological sort over the 20 nodes / 21 edge entries at `CP/V1.8-SCHEMAS.sexp:53-65` finds
  no cycle and no terminal with an outgoing edge. **Not resolved here** — the DDI-3 exit criterion depends on it.
- **ADJ-FR-02 — What the adjudication ledger is for.** Side A: `W/collect_adjudications.py` treats the ledger as a
  pool of items harvested from primary artifacts only (784 rows at 06:29:35, 0 from any adversary).
  Side B: CLAUDE.md's protocol requires every adversarial finding to be closed at its seat, refuted with proof, or
  declared a residue with a death phase — which presupposes the adversaries' findings are *in* the ledger
  (FH-01…14, PH-01…08, S-1…S-9 are not). Whether the ledger is a work list or the record of closure is the decision.
- **ADJ-FR-03 — Identity of an adjudication item.** Side A: identity by normalised 120-character prefix
  (`collect_adjudications.py:41-46`) — measured effect: 47 of 793 items dropped, one key merging 15 distinct
  decisions. Side B: identity by an id assigned at birth (BS-06), which requires an id grammar that does not exist.
- **ADJ-FR-04 — Whether a comment may be import evidence.** Side A: `DAG.md:14-17` (form extent runs to the line
  before the next top-level form, so trailing `;;` comments count as the form's own text). Side B:
  `W/agents/dag-attack/verify.py` (extent = the parenthesised form), under which one blocking edge loses its
  evidence entirely (`CP/V1.8-SCHEMAS.sexp:259-266` vs the token at `:274`).
- **ADJ-FR-05 — Store writer cardinality.** Side A: `MS:153-154` prose ("exactly one owner seat and exactly one
  writer seat") + `define-unique` on `owner` only (`MS:319`). Side B: the data — `SEAT-WRITE-AUTHORITY` writes three
  stores, `SEAT-NO-WRITER` three (`stores-and-authorities.sexp:5-14`). Whether many-stores-per-writer is intended
  is undecided in the repository.
- **ADJ-FR-06 — Whether 8 consolidated adversarial passes discharge a protocol written for 18.**
  Side A: orchestrator N18 — the consolidation is declared, the axes are preserved two-per-artifact-class, all
  eight delivered (§0), and several attacks are recorded as REFUTED, which is the evidence a real adversary
  leaves. Side B: CLAUDE.md requires the adversary per phase on at least two axes over the artifact under
  review; the six dossiers received neither axis, and no artifact records which of the 18 planned coverages went
  unperformed (BS-08). This is a process decision for the creator, not a technical one.
- **ADJ-FR-07 — the blocking-edge set: the DAG and its own attacker disagree.**
  Side A: `W/agents/dag/order.json` / `DAG.md:553-556` — 161 blocking edges, 33 conflicts, "26 of the 33 have a
  DDI-1 source" (`DAG.md:495ff`).
  Side B: `W/agents/dag-attack/findings.md` DA-01 (a missing blocking edge `V1.8 define-ra-delta-seats →
  V1.8 define-record`, 7 refs, `CP/V1.8-SCHEMAS.sexp:444-451`), DA-03 (a missing blocking edge
  `define-subsystem → define-wp-purpose`, 26 of 26 subsystems carrying `:future-wp`), DA-09 + `dag-mediocrity` F6
  (the count is 27, not 26). Under side B the totals become 34 conflicts and 28 with a DDI-1 source, and
  `importable_without_any_deferred_prerequisite` loses at least one member (DA-02).
  The DAG agent has not answered; the finding is unrebutted, not adjudicated. **The batch plan's headline numbers
  depend on which side is right.**

---

### F. UNKNOWNS (honest)

- **U-FR-1** SUPERSEDED DURING THIS PASS. At 06:25–06:30 five adversarial verdicts were missing; by 06:39 all
  eight had delivered and I read them (§0). What remains unknown is what the **other ten** planned passes of the
  original 18 would have found, and specifically what an adversarial pass over the six **dossiers** would find —
  no agent took either axis over them (BS-08, RT-28).
- **U-FR-2** Whether `X46`, `X47` and `PF-ENC-INJECTIVITY` ever existed: `git log -S` was not run over all refs for
  these ids in this pass (the archaeology agent's search covered the "20 gates" phrase, not these). NOT CHECKED.
- **U-FR-3** Whether the `enc` sort-by-encoded-pair-string rule (`AM/CANONICAL-ENCODING.md:37`) is injective for all
  key sets: stated as a candidate lemma (FP-08 iii), not proven, not refuted here.
- **U-FR-4** Which of the two readings of L4-over-cognition is right (ADJ-FR-01): my computation supports side B for
  the graph *as written today*, but says nothing about the fact families the import will actually create.
- **U-FR-5** What the original 20 Option-A gates are, and whether "Full build" additionally required them over the
  66-class model (`gates-matrix` U-1…U-3, `gates-skeptic` S-8). Without it, no post-build check in §B can be called
  complete against Option A — only complete against itself.
- **U-FR-6** Whether the ARCHITECTURE-MODEL governance path counts as "the public build" for `:V8I-02` (N6, FH-05,
  FH-09, FH-10) — an institutional question this pass does not touch.
- **U-FR-7** Nothing in §B, §C or §D was executed: no gate, no corpus, no kernel, no solver. Every "fails today"
  is derived from reading the source at 4ee2b58a, not from a run.


## 4. Adversarial verification record

### 4.1 Readiness skeptic

### readiness-skeptic — adversarial pass over READINESS-MAP.md and FUTURE-REVIEW-INPUTS.md

Read-only. Nothing under `RO` or `/home/user/THE-LEGAL-WATCHTOWER` was created, modified or deleted; no git
mutation; no gate, corpus, battery or generator executed. Scratch scripts kept here: `nest.py` (independent
s-expression re-scan of the six registries), `recount.py` (arithmetic over the map's own tables), `modcheck.py`,
`cmp.py`, `nest.json`.

Targets:
- `W/agents/readiness-map/READINESS-MAP.md` (+ its `build_map.py`, `nesting.json`, `model-consumers.json`)
- `W/agents/future-review/FUTURE-REVIEW-INPUTS.md`

Verdict key: REFUTED = the claim is false as written; WEAKENED = materially overstated; CONFIRMED_DEFECT = the
claim survives verification and names a real defect; UNRESOLVED = evidence insufficient.

#### Summary
18 findings. 3 P1, 9 P2, 6 P3. The heaviest is a silent join failure in `build_map.py` that voids the entire
L1/G04 analysis for batch DDI-3 (RS-01), refuted by the map's OWN `nesting.json`. Two headline metrics are
refuted outright (`reqs_without_tests = 6`, RS-02; `29 of 56 nested`, RS-01) and one ceiling adjudication is
smuggled into a document that opens by declaring it performs none (RS-11).

---

##### RS-01 (P1, REFUTED) — the map's nesting/G04 analysis is void for all 10 DDI-3 classes; 37, not 29
**Claim attacked.** `READINESS-MAP.md:15` (M2): "**39 of 66 classes** carry ≥1 nested-list form; **29 of the 56
deferred ones do**"; `:317` (RP-01): "Recomputed here: **29 of the 56 deferred classes** … contain at least one
nested-list form; max depth 5 (`V1.5`/`V1.7 define-decision-function`)"; §3 rule R2 (`:135`) "G04 | class has ≥1
nested-list form"; gate load "G04 29" (`:144-145`).

**Evidence.**
- My independent scan (`nest.py`, string/comment-aware, parenthesis-depth) reproduces 66 classes / 435 forms and
  39-of-66 exactly, but finds **37 of the 56 deferred classes** carry ≥1 nested-list form, not 29.
- The eight missed classes are all of DDI-3 that nest: `V1.5__define-algorithm` (1/1, depth 3),
  `V1.5__define-decision-function` (1/1, depth **5**), `V1.7__define-decision-function` (1/1, depth **5**),
  `V1.7__define-source-type-coverage` (1/1, depth 2), `V1.8__define-cognition-graph` (1/1, depth 3),
  `V1.8__define-cognition-node-types` (1/1, depth 2), `V1.8__define-dimension-policy` (1/1, depth 2),
  `V1.8__define-reliance-aggregation` (1/1, depth 2). None carries `L1-NESTED-VALUE`; none carries **G04**
  (`READINESS-MAP.md:95-104`).
- **The map's own data file refutes its table**: `readiness-map/nesting.json` records
  `V1.5-SCHEMAS.sexp|define-decision-function {"forms":1,"nested":1,"maxdepth":5,"first_line":229}` and
  `V1.8-SCHEMAS.sexp|define-cognition-graph {"nested":1,"maxdepth":3,"first_line":53}`. Restricted to the 56
  deferred classes that file yields **37**, not 29.
- **Mechanism.** `build_map.py:112` joins with `nk = '%s|%s' % (r['source_file'], head)`. `matrix-DDI-3/matrix.json`
  stores `source_file` as a full path (`deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.5-SCHEMAS.sexp`) while
  `nesting.json` is keyed by basename; the other three matrices store basenames. So every DDI-3 row gets
  `nes = {}` → no `first_line`, no `L1-NESTED-VALUE`, no G04 (`build_map.py:135,152,168`).
- The symptom is printed in the published table and was not noticed: every DDI-3 row cites
  `(…/V1.5-SCHEMAS.sexp:**None**)` (`READINESS-MAP.md:95-104`) — a `file:None` citation in a document whose
  §0 preamble says "Every number below is either recomputed by this agent from the clone".
- Self-refutation: RP-01 cites `V1.5`/`V1.7 define-decision-function` as the **max-depth-5** exemplars while its
  own count excludes both.

**Required correction.** Re-run the join on basenames; restate M2 as **37 of 56**, RP-01 `binds` as 37, G04's load
as 37 and G03's as 47 (rule R4 fires on the same trigger); restore a real `first_line` to the 10 DDI-3 rows; state
that DDI-3 — the cognition/decision layer, which carries the two deepest forms in the corpus — was previously
reported as containing no nested value at all.

---

##### RS-02 (P1, REFUTED) — `reqs_without_tests = 6` is wrong under every reading of the register
**Claim attacked.** `READINESS-MAP.md:21` (M8) "134 distinct `R-nnn`; **6 rows carry no test at all**";
`:196` "**6 rows carry no test token at all**: `TM:133` R-70, `TM:205` R-112, `TM:206` R-113, `TM:209` R-116,
`TM:210` R-117, `TM:211` R-118"; `:198` "**`reqs_without_tests` is reported as 6**".

**Evidence.** `TRACEABILITY-MATRIX.md:17` declares the column order; column 9 is `Test`. Parsing all 134 `R-nnn`
rows by column:
- Rows whose **Test cell is `—`**: exactly **one** — `TRACEABILITY-MATRIX.md:211` (R-118).
- The other five named rows carry a test: `:133` R-70 → `validation pass 2`; `:205` R-112 and `:206` R-113 →
  `contradiction audit`; `:209` R-116 → `validation pass 2`; `:210` R-117 → `contradiction audit`.
- Rows with **no `Qnn`/`V6Q-nn` id** in the Test cell: **twelve**, not six — the six named plus
  `:227` R-129 (`VS-09, VS-10`), `:228` R-130 (`VS-12`), `:229` R-131 (`VS-11`), `:230` R-132 (`VS-13`),
  `:231` R-133 (`VS-06`), `:232` R-134 (`VS-12`).
- `134 distinct R-nnn` is confirmed.

**Consequence beyond the number.** Four of the six newly-found rows — R-129, R-130, R-132, R-134 — **are** model
`requirement` facts bound to tests by `req-map` (`requirements-tests-workpackets.sexp:70,76,67,77` → Q08, Q28, Q01,
Q28). The map raised exactly one instance of that register/model contradiction as **ADJ-RM-01** (R-118). There are
five, and the map's own metric hid the other four.

**Required correction.** Replace `reqs_without_tests = 6` with the two measured quantities (1 empty Test cell; 12
rows with no Q-family id) and extend ADJ-RM-01 to R-129/R-130/R-132/R-134. Also register the `VS-nn` test
vocabulary: `build_map.py:88` `compact_test`'s regex matches only `Q\d\d|V6Q-\d\d|RA-Q-*|T8-*|V5Q-*|QT-DDI4-*`, so
every `VS-nn`/`KW-nn` test id in the register is invisible to the map's EXISTING/NEW verdicts and to
`L6-TEST-OUTSIDE-MODEL`.

---

##### RS-03 (P1, REFUTED) — `SUBSYSTEM-REGISTRY__define-invariant` is neither name-untestable nor an orphan: it is already seated
**Claim attacked.** `READINESS-MAP.md:16` (M3) classes `NOT-NAME-TESTABLE` = 17; `:159` "`NO-FUTURE-PACKET` | 3 |
… `SUBSYSTEM-REGISTRY__define-invariant` …"; `:162-164` "The three hardest orphans are the same three classes: the
two registry-level `define-invariant` classes are *constitutional* statements owned by no subsystem";
`:350-351` (UNKNOWN 4) "**Consumer status of the 17 NOT-NAME-TESTABLE classes.** Their identity is a `(file, head)`
pair, so the name-occurrence test in M3 is not applicable to them"; DDI-4 row 3 gap `ID-SYNTHESIS-REQUIRED`
(`:112`).

**Evidence.** The class has two atomic ids, `:SR-V6-one-seat` (`SUBSYSTEM-REGISTRY.sexp:136`) and
`:SR-V6-wp-honesty` (`SUBSYSTEM-REGISTRY.sexp:141`), and the map's own `model-consumers.json` records
`"model_hits": {"rationale-references.sexp": [":SR-V6-one-seat", ":SR-V6-wp-honesty"]}` for it. Verified in the
model: `rationale-references.sexp:4` `(fact rationale RAT-ONE-SEAT :doc "SUBSYSTEM-REGISTRY.sexp" :anchor
":SR-V6-one-seat")` and `:5` `(fact rationale RAT-WP-HONESTY … :anchor ":SR-V6-wp-honesty")`. So the class
(a) has atomic names, (b) has a model consumer, and (c) already has a candidate seat in an **existing** pinned
module (`rationale`), not the proposed `NEW:invariants.sexp`.

Sixteen further `NOT-NAME-TESTABLE` classes do have names and score **zero** model hits — i.e. they are
`CONFIRMED-ABSENT` under the map's own M3 test (e.g. `V1.5__define-invariant`, 22 names, 0 hits;
`V1.7__define-capability-seat`, 7 names, 0 hits). Only genuinely nameless classes deserve the label; the map's own
data shows 17 rows where the label is asserted and the test in fact ran.

**Required correction.** Recompute `_consumer_status` from `model_hits ∪ names`; move the 16 to
`CONFIRMED-ABSENT` (raising `NO-MODEL-CONSUMER` from 26 toward 42 and shrinking the "14 non-orphans" list);
remove `SUBSYSTEM-REGISTRY__define-invariant` from the "hardest orphans" and record that
`rationale-references.sexp:4-5` is an existing seat precedent for registry-level invariants — which is decision
evidence RP-05/§4 currently lacks.

---

##### RS-04 (P2, REFUTED) — two classes propose a module outside the 14 and are given neither the L7 flag nor G05
**Claim attacked.** `READINESS-MAP.md:28-29` "A module name outside `ROOT.sexp`'s 14-module `:composition` is
flagged `NEW-MODULE-PROPOSED(L7)`"; `:138` rule R5 "**G05** | the proposed module is not in `ROOT.sexp`
`:composition`"; `:17` (M4) "**25 classes propose 10 modules that do not exist**"; gate load "G05 25" (`:145`).

**Evidence.** DDI-1 rows 4 and 10 (`READINESS-MAP.md:58,64`) give the proposed module as
`NEW:capabilities` — plainly outside `ROOT.sexp:13-27`'s 14 modules — yet their gaps carry **no**
`NEW-MODULE-PROPOSED(L7)` and their gate cells carry **no G05**
(row 4: `G02 G03 G09a G10-12 G13 G14 G15 G19 G21`). Mechanism: `build_map.py:63-69`,
`target_modules()` only matches tokens ending in `.sexp`, and `proposes_new_module()` additionally exempts any
basename appearing in `git ls-files '*.sexp'` **anywhere in the repository** — which is not the L7 test
(`ROOT.sexp:12` `:module-count 14`, an exact universe). A proposal targeting an existing-but-unpinned `.sexp`
(e.g. `deployment/verify/gate-registry.sexp`) would likewise pass unflagged although it is an L7 change.

Second, the same two rows expose an undeclared naming split: DDI-1 calls the capability module `capabilities`
while DDI-2 row 8's gap calls it `capability-seats.sexp` (`READINESS-MAP.md:79`) — the map records no adjudication
for the one-seat/one-name question it itself raises.

**Required correction.** Make the flag test `module ∉ ROOT.sexp :composition` (not `∉ repo`), accept non-`.sexp`
module names, restate M4 as ≥27 classes / ≥11 module names, correct the G05 load, and file the
`capabilities` vs `capability-seats.sexp` name collision as an adjudication item.

---

##### RS-05 (P2, CONFIRMED_DEFECT) — the "proposed canonical module" column contradicts the gaps column in 7 of 56 rows
**Claim attacked.** `READINESS-MAP.md:27-29` — the column is "the *proposed* seat … trimmed to its leading clause"
and a module outside the 14 "is flagged".

**Evidence** (`modcheck.py`). Seven rows name an **existing** module in the column while the gaps flag a **new**
one and G05 fires: DDI-2 #6 `interfaces-and-types.sexp` vs `NEW-MODULE-PROPOSED(L7):adapters.sexp` (`:77`);
DDI-2 #7 `UNDECIDED — interfaces-and-types.sexp` vs `enums.sexp` (`:78`); DDI-2 #8 "SAME module as the DDI-1
capability-seat class" vs `capability-seats.sexp` (`:79`); DDI-2 #9 "SPLIT … lives in i" vs `record-fields.sexp`
(`:80`); DDI-3 #6 "subsystems.sexp / seats.sexp already hold the seat and subsystem" vs `source-type-coverage.sexp`
(`:100`); DDI-4 #5 `rationale-references.sexp` vs `invariants.sexp` (`:114`); DDI-4 #11 "whichever module class 3
resolves to" vs `file-dispositions.sexp` (`:120` — while class 3 resolves to `invariants.sexp`, `:112`).
Cause: `first_clause()` (`build_map.py:71-75`) truncates the module cell at the first `(` or `;` and at 190
characters, while the flag is computed over the untruncated field.

**Required correction.** Emit the module cell from the same value the flag is computed from, or print the flagged
module name inside the cell.

---

##### RS-06 (P2, REFUTED) — `M3`'s 26/13/17 classification is not reproducible from any kept script
**Claim attacked.** `READINESS-MAP.md:6-7` "Every number below is either recomputed by this agent from the clone
(**scripts kept beside this file**)"; `:16` M3 "**26 CONFIRMED-ABSENT · 13 PRESENT · 17 NOT-NAME-TESTABLE**",
script cited as `scan_consumers.py`.

**Evidence.** `scan_consumers.py` writes only `file, head, batch, forms, names, model_hits, n_names_seated`
(its `out[cid]=` dict). `model-consumers.json` additionally contains `_kind` and `_consumer_status` — the two
fields `build_map.py:136,137,150,151` actually branches on. `grep -rn '_consumer_status\|_kind'` over the agent's
kept `*.py` returns hits only in `build_map.py` (as *readers*). The classification that drives
`NO-MODEL-CONSUMER` (26), `ID-SYNTHESIS-REQUIRED` (17), G02 and G03 was injected by a step that was not kept, and
17 of its 56 verdicts disagree with the recomputable `names`/`model_hits` (see RS-03).

**Required correction.** Publish the classifier, or derive `_consumer_status` inside `scan_consumers.py`.

---

##### RS-07 (P2, REFUTED) — the future-packet column is driven by an undisclosed hand-authored mapping
**Claim attacked.** `READINESS-MAP.md:39-43`: the packet "is derived **only** from primary sources — the owner
subsystem's `:future-wp` … and/or `define-wp-reconciliation`'s concept row. Where neither names the class, the
value is `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED` — the token the registries themselves use … for 'no WP owns
this; **do not invent a mapping**'."

**Evidence.** `build_map.py:96-106` defines `CONCEPT_BY_HEAD`, a seven-entry literal table
(`define-cognition-graph`, `define-cognition-node-types`, `define-construction-order` → `COGNITION_DAG`;
`define-adapter-contract` → `NEURAL_PROPOSER`; `define-ra-closure-roots` → `PUBLIC_PRIVATE_BOUNDARY`;
`define-dimension-policy`, `define-reliance-aggregation` → `ROOT_AUTHORITY_FLYWHEEL`), commented "only where the
concept's own words name the class (evidence in the MD)". No such evidence appears in `READINESS-MAP.md`, which
never mentions the table. The registry rows themselves name no head: `V1.8-SCHEMAS.sexp:304` is
`(:concept COGNITION_DAG :wp WP-08 :file "WP-08.md" :evidence "Public Legal Discernment")`; nothing in it names
`define-construction-order`. The table therefore *is* the invented mapping the same section forbids, and it
supplies packet values for 7 of 56 rows and 2 of the 3 `WP-SOURCES-DISAGREE` gaps.

**Required correction.** Publish `CONCEPT_BY_HEAD` in the document as an adjudication item with per-entry
evidence, or drop it and let those rows fall to `FUTURE_IMPLEMENTATION_BOOK_PACKET_REQUIRED`.

---

##### RS-08 (P2, REFUTED) — `M5`'s `req-map` count is wrong, and FUTURE-REVIEW has the right number
**Claim attacked.** `READINESS-MAP.md:18` (M5) "24 requirement · 21 test · 14 wp · **28 req-map** · 26 subsystems",
"agrees with orchestrator N7/N8".

**Evidence.** `requirements-tests-workpackets.sexp:67-95` contains **29** `(fact req-map …)` forms
(`grep -c '^(fact req-map '` = 29; the file is 95 lines and the family is contiguous). The other four counts are
exact (requirement 24 at `:5-28`, test 21 at `:30-50`, wp 14 at `:52-65`). `FUTURE-REVIEW-INPUTS.md:215`
(BS-09) independently states `req-map 29`, so the two artifacts of this reconnaissance disagree and the
readiness-map is the wrong side.

**Required correction.** M5 → 29; the two agents' counts must be reconciled before either is quoted.

---

##### RS-09 (P2, WEAKENED) — `tests_without_falsifier = 15` is not a count over any single universe
**Claim attacked.** `READINESS-MAP.md:207-223`, §5.2 heading "Tests without a falsifiable failure — 15";
`:221` "`tests_without_falsifier = 15`"; M7 (`:20`) "19 [of 21] have one".

**Evidence.** The model declares exactly 21 `test` facts (`requirements-tests-workpackets.sexp:30-50`). Of the 15
counted, **13 are not `test` facts at all** — `RA-Q-CITE/DATASET/JURIS/LICENSE/RETRIEVE/TRANSLATE` (6) and
`T8-CONT/CORR/EPOCH/JURNS/K/MARK/SIDE` (7) appear nowhere in that file. Only 2 of the 15 (`RA-Q-RESOLVE`,
`RA-Q-TENANT`) are model tests. The section's own opening argument points the other way: "a model `test` fact
structurally cannot carry a failure condition … **So no test in this model is bound to its own falsifier**"
(`:209-211`) — which yields 21, not 15. A metric that is 2 over the model, 15 over model∪registry and 21 under the
section's own structural argument cannot be quoted as one number.

Additionally, the five `V6Q` tests are credited "failure condition found: **yes**" on a 1-1 id correspondence
(`:216`), while the cited source says of exactly those ids: "**Predeclared tests (design-only· UNEXECUTED)** …
κάθε test θα εκτελεστεί **μετά** την υλοποίηση με fixture + expected outcome" and "Design-only· κανένα
`V6Q`/`V6KW` δεν εκτελείται" (`PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:1150-1151,1160`).

**Required correction.** Report three separate numbers with their universes named, and mark the five `V6Q` rows
`DECLARED-UNEXECUTED`.

---

##### RS-10 (P2, WEAKENED) — `private_leaks = 8` and `facts_without_gate = 8` are inflated by definition drift
**Claim attacked.** `READINESS-MAP.md:265` "## 7. Private concepts leaking into the public core —
`private_leaks = 8`"; `:252` "### 6.2 Eight kinds of **source fact** with no future gate — `facts_without_gate = 8`".

**Evidence.**
- §7's own baseline, which I re-verified, is clean: `dependencies-and-boundaries.sexp` holds **102** `consumes`
  facts and **zero** provide any of the six PRIVATE types (`interfaces-and-types.sexp:24,41,44,51,58,59`); the only
  edge touching a private subsystem is `:110` `S22 → DeclassificationReceipt/1`, the permitted direction. The
  section then writes: "The leaks below are therefore **not** violations of the check that exists" (`:270-271`).
  Of the 8, `PL-3` is a missing documentation anchor and `PL-8` is a missing cardinality floor — neither is a
  private concept in the public core. At most PL-1/4/5/6/7 are classification items, and only PL-1 is live at HEAD.
- §6.2 is headed "source fact" but F1 (`rationale :doc/:anchor`), F2 (`test` id), F3 (`requirement` id) and F6
  (`type :classification`) are **model** facts, and F8 ("`git` as an executed tool") is the *absence* of a fact —
  I confirmed `TOOLCHAIN.sexp` declares exactly 5 `tool` facts (`:28,38,48,58,68`) and contains the string `git`
  zero times.

**Required correction.** Rename the metrics to what they count (`classification_crossings_live = 1`,
`import_time_classification_risks = 4`, `unfloored_or_undocumented = 3`) and retitle §6.2 "facts and non-facts
with no counted check".

---

##### RS-11 (P1, REFUTED) — a ceiling adjudication is smuggled into the scope statement of "INPUTS ONLY"
**Claim attacked.** `FUTURE-REVIEW-INPUTS.md:3-5`: "This document is INPUTS ONLY. It performs **no ceiling
adjudication**. Nothing here is called ανώτατο, complete, sufficient, or freeze-ready … Where two artifacts of
this reconnaissance disagree, the disagreement is recorded with both sides cited (§E), never resolved."

**Evidence.** `FUTURE-REVIEW-INPUTS.md:48` "**All eight consolidated adversarial passes have therefore
delivered.**" and `:51-52` "**No adversarial axis is missing**; what changed is the *shape* of the coverage
(8 agents over **12** named slots)". That is a sufficiency verdict on the CLAUDE.md adversarial protocol — the
exact question the same document files as **undecided** at `:761-767` (ADJ-FR-06, "Whether 8 consolidated
adversarial passes discharge a protocol written for **18** … This is a process decision for the creator").
It is also contradicted by the document's own BS-08 at `:199-201`: "`matrix-mediocrity-A/B` cover the four
matrices but **no agent attacked the six dossiers on either axis**" and `:204-206` "'the adversary found nothing
here' and 'no adversary looked here' are the same silence. The dossiers (162 adjudication items, the substrate of
every matrix) are currently in the second category." A missing axis over the largest substrate is precisely an
adversarial axis that is missing. The slot count is also inconsistent inside the document: "12 named slots"
(`:52`) vs "the 18 were consolidated into 8" (`:196-197`) and "a protocol written for 18" (`:761`).

**Required correction.** Delete "No adversarial axis is missing" and the completeness reading of "have therefore
delivered"; state instead "eight of eight *spawned* passes returned findings; coverage of the six dossiers on both
axes was NOT PERFORMED (BS-08); sufficiency is ADJ-FR-06, undecided." Reconcile 12 vs 18.

---

##### RS-12 (P2, WEAKENED) — BS-05's de-duplication harm is overstated by an order of magnitude
**Claim attacked.** `FUTURE-REVIEW-INPUTS.md:250-256` (BS-05, second half): "Re-running the same collection myself
… yields 793 raw items of which **47 are dropped by that key**, collapsing 14 distinct keys; the largest collapse
merges **15** items into one … **Distinct decisions with a shared opening sentence are silently merged.**"

**Evidence.** I re-ran `collect_adjudications.py:9-30`'s collection verbatim (dossiers + matrices + `order.json`)
and reproduce 793 raw / 47 dropped / 14 collapsing keys / largest group 15 — the arithmetic is exact. But grouping
by the key and counting **distinct full texts**: of the 47 dropped items, **43 are byte-identical duplicates**
(correctly removed) and only **4** are genuinely distinct texts lost. The 15-item group contains just **3**
distinct texts, so it merges 3 decisions, not 15.

The first half of BS-05 is fully CONFIRMED and I re-verified it: `adjudications.json` holds 784 items whose
sources are only dossiers, matrices, `order.json`, `orchestrator-notes.md`, `gates-matrix` and
`gates-archaeology`; occurrences of `FH-0`, `PH-0`, `"S-1`, `cl-freedom-hunter`, `cl-python-hunter`,
`gates-skeptic`, `dag-attack`, `matrix-attack`, `mediocrity` = **0**.

**Required correction.** State "47 drops, of which 4 lose a distinct decision"; the defect (prefix identity) is
real and the fix (id at birth) still stands, but the quoted magnitude must not survive.

---

##### RS-13 (P2, WEAKENED) — §C's opening claim that every formal property is over the model's own fact types
**Claim attacked.** `FUTURE-REVIEW-INPUTS.md:463` "Each property is stated over the model's own fact types, then a
tool with the reason it is the right one."

**Evidence.** `MODEL-SCHEMA.sexp` declares 34 fact types; there is no `cognition`, `cog-node`, `cog-edge`,
`check`, or `edge` type, and no fact type for a module or a batch.
- **FP-03** (`:494-506`) is stated over `sig CogNode`, `sig CogEdge`, `Family = FLOW+BRANCH+RESUME+TERMINAL` —
  none is a model fact type; the subject is a source form (`V1.8-SCHEMAS.sexp:53-65`).
- **FP-13** (`:588-597`) is stated over `blocking ⊆ Class × Class` taken from `W/agents/dag/order.json` and
  `batch : Class → {1..4}` from `build_deferred.py:86-104` — a reconnaissance artifact and a Python literal.
- **FP-15** (`:611-620`) is stated over `sig Check { canFail, counted }` — the gate is a shell script; no `check`
  fact exists.
- **FP-06** (`:507`) ranges `Edge` over eight families of which seven are not model relations (the document says so
  itself); **FP-07** (`:531-534`) needs a `DeclaredRequirementRegistry` "that does not yet exist"; **FP-11**
  (`:567`) is over `ROOT.sexp`'s module set, which is `define-model-root`, not a `fact`; **FP-12** (`:580-584`)
  half-quantifies over `Scanned`, an external scanner's output.
Correctly over model fact types: FP-01, FP-02, FP-04, FP-05 (verified: `MODEL-SCHEMA.sexp:155-158`
`store :required (owner writer) :ref ((owner seat) (writer seat))`, and the uniques at `:308,319-322`),
FP-09, FP-10, FP-14.

**Required correction.** Split §C into "properties of the model at HEAD" (8) and "properties of a model the
migration has not yet created / of the process" (7), and mark the latter as requiring the fact family first.

---

##### RS-14 (P3, WEAKENED) — ADJ-RM-01 quotes the wrong column of the register
**Claim attacked.** `READINESS-MAP.md:202-205` (ADJ-RM-01): "`TRACEABILITY-MATRIX.md:211` states for **R-118**:
*'— (δεν εκτελείται)'* (no test, not executed)."

**Evidence.** By the header at `TRACEABILITY-MATRIX.md:17` (`| R | Mission | CAP | Requirement | Seat | Interface |
Invariant | Negative witness | Test | Evidence | Qual |`), the quoted string `— (δεν εκτελείται)` sits in column 8,
**Negative witness**; the `Test` cell (column 9) of `:211` is a bare `—`. The adjudication's conclusion survives,
its quotation does not.

**Required correction.** Quote the `Test` cell and cite the Negative-witness cell separately.

---

##### RS-15 (P3, CONFIRMED_DEFECT) — three gap labels silently truncate their evidence
**Claim attacked.** the gap column's completeness, `READINESS-MAP.md:30-32`.

**Evidence.** `build_map.py:155` `'L6-REQ-OUTSIDE-MODEL(%s)' % ','.join(reqother[:4])`, `:156`
`tstother[:4]`, `:154` `sorted(set(newmods))[:3]` — all truncate with no ellipsis, so a row with more than four
outside-model requirement ids reads as if it had exactly four (e.g. `:84`, `:116`, `:121`). Separately, `:139`
and `:153` test `NEW_RE.search((r['canonical_type_or_fact_family'] or '')[:60])` — only the first 60 characters —
which is an undisclosed heuristic driving `NEW-FACT-TYPE-REQUIRED` and the G13/G15/G09a triple. Searching the full
field changes exactly one row (`SUBSYSTEM-REGISTRY__define-wp-purpose`), so the material effect today is 1, but
the rule is not the rule §3 R6 states.

**Required correction.** Append `…(+n)` on truncation; search the whole field or document the 60-character window.

---

##### RS-16 (P3, CONFIRMED_DEFECT) — the batch-map citation is wrong in three artifacts
**Claim attacked.** `FUTURE-REVIEW-INPUTS.md:281` "`AM/build_deferred.py:87-107` is a literal `head → batch`
dictionary"; `READINESS-MAP.md:26` and `BRIEF.md` "`build_deferred.py:90-105`".

**Evidence.** `grep -n` gives `BATCH={` at `build_deferred.py:86` and its closing `}` at `:104`;
`BATCH_TITLE=` begins at `:105`. Neither cited span is the dictionary. (`IMPORTED={` at `:75`–`:80` — cited
correctly by `FUTURE-REVIEW-INPUTS.md` PB-02, and PB-02's arithmetic 4 + 56 = 60 checks out.)

**Required correction.** Cite `build_deferred.py:86-104`.

---

##### RS-17 (P3, CONFIRMED_DEFECT) — claims I attacked and could not break (recorded so silence is not evidence)
Re-verified against `RO` and standing:
- `M1` 66 classes / 435 forms; `39 of 66` classes nested; max depth **5** at `V1.5`/`V1.7 define-decision-function`
  (my `nest.py`, independent reader).
- `M6` exactly one `type`/`subsystem` classification crossing: `interfaces-and-types.sexp:51`
  `RestrictedForensicRecord/1 :classification PRIVATE :owner-subsystem S18` vs `subsystems.sexp:22`
  `S18 :classification PUBLIC`; the other five PRIVATE types are owned by PRIVATE subsystems.
- `M7` / §5.2: `RA-Q-RESOLVE` and `RA-Q-TENANT` have **0** occurrences in
  `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`; every other occurrence is a registration
  (`V1.7-SCHEMAS.sexp:346`, `V1.8-SCHEMAS.sexp:243`, `SUBSYSTEM-REGISTRY.sexp:121`,
  `TRACEABILITY-MATRIX.md:350`, `requirements-tests-workpackets.sexp:44,94`).
- §6.2 F1 / BS-10 / RT-22: of the five `rationale` facts, four anchors resolve
  (`:V6I-17`, `:SR-V6-one-seat`, `:SR-V6-wp-honesty`, `define-pipeline symbolic-only-path` — each 1 hit in its
  `:doc`); `RAT-PUBPRIV`'s anchor "public/private one-way boundary" has **0** hits in
  `deployment/LAWMAX-THREAT-MODEL.md` (also 0 for `one-way`).
- RP-10 / BS-14: the Lisp path is at exactly **400/400** — `grep -vE '^[[:space:]]*;|^[[:space:]]*$'` over
  `KERNEL/model-law-kernel.lisp` + `KERNEL/hash-provider.lisp` = 400, budget at
  `ARCHITECTURE-MODEL-GATE.sh:178-179`; consistent with `files-and-roles.sexp:1090-1091` (`:nbnc 67` + `:nbnc 333`).
- BS-14 floors: `fixture` 8/8, `property-family` 5/5, `falsifier` 80/80, `gen-artifact` 12/12, `seat` 33/33,
  `tool` 5/5 against `verification-corpus.sexp:60-70`. Zero headroom, exactly as claimed.
- BS-01: `X46-COMMITMENT-DELIMITER-COLLISION` and `X47-ENCODING-VERSION-BINDING` occur only at
  `CANONICAL-ENCODING.md:82,84`; `PF-ENC-INJECTIVITY` only at `:86`; the falsifier ids jump
  `X45` (`verification-corpus.sexp:218`) → `X54` (`:234`).
- BS-02 / FP-02: `KERNEL/model-law-kernel.lisp:243-254` `law5-isolation` walks `CONSUMES` one hop with no
  transitive step; `:211-218` `edge-relations` derives the acyclicity duty exactly as FP-02 states.
- BS-03: `MODEL-SCHEMA.sexp:159` `(define-fact-type stage :id-space TOKEN-SPACE :required () :optional ()
  :types ())` — field-less, verbatim.
- BS-04 / FP-03: my own topological sort over `V1.8-SCHEMAS.sexp:53-65` (13 flow + 2 branch + 2 resume + 4
  terminal = 21 entries, 20 distinct, `(CLARIFY-DECIDE RESOLVE)` duplicated) finds **no cycle** and no terminal
  with an outgoing edge — side B of ADJ-FR-01. Their citation correction (`:resume-edges` is `:61`, `:63` is the
  tail of `:terminal-edges`) is also right.
- BS-12: `ARCHITECTURE-MODEL-GATE.sh:89` `note(){ … info=$((info+1)); }`; `:225-226` the two demoted properties;
  `:229` the summary line; `:26` "A check that cannot fail is not a check"; `:230-231` names the original 20 as a
  mandatory future stage.
- BS-11: `run_corpus.py:811 def f19_restore_instead_of_compare():`, single occurrence; `CODED_COMPONENT` at
  `:1343`, `COMPOSED` at `:1370`.
- BS-16 / FP-05 / ADJ-FR-05: `MODEL-SCHEMA.sexp:153-154` prose vs `:319` `define-unique` on `owner` only;
  `stores-and-authorities.sexp:8,9,10` show `SEAT-WRITE-AUTHORITY` writing three stores and `:11,12,13`
  `SEAT-NO-WRITER` writing three.
- BS-05 first half, §8 AM-01 (`git` absent from `TOOLCHAIN.sexp`), AM-03 (`source/journal.lisp:88-92`;
  24 of 133 files under `source/` reference `ironclad`), §7 baseline (102 `consumes`, 0 private provides),
  RP-07 (`grep -ci conflict MODEL-SCHEMA.sexp` = 0), §0 inventory of the eight adversarial passes
  (MA-01…10, B-01…08, DA-01…09, F1…F12, M1…M12, S-1…S-9, FH-01…14, PH-01…08 all present).

---

##### RS-18 (P2, UNRESOLVED) — the map's headline gate loads are internally consistent but rest on the defects above
`recount.py` re-derives every published aggregate directly from the map's own 56 table rows and they all match:
forms 40/156/12/124 = 332; gate loads G19 56, G21 56, G10-12 53, G14 46, G03 39, G02 36, G09a/G13/G15 35, G04 29,
G05 25, G16 16, G20 16; gap tallies `NEW-FACT-TYPE-REQUIRED` 35, `NO-TEST-FACT` 30, `L1-NESTED-VALUE` 29,
`NO-REQUIREMENT-FACT` 27, `NO-MODEL-CONSUMER` 26, `NEW-MODULE-PROPOSED` 25, `ID-SYNTHESIS-REQUIRED` 17,
`NO-FUTURE-PACKET` 3; orphan union 42 of 56; the seven untouched gates G01/G06/G07/G08/G09b/G17/G18. So the
document is arithmetically sound **and** wrong: every one of these numbers inherits RS-01 (G04, G03,
`L1-NESTED-VALUE`), RS-03/RS-06 (`NO-MODEL-CONSUMER`, `ID-SYNTHESIS-REQUIRED`, G02, G03, the orphan union and the
"14 non-orphans" list) and RS-04 (G05, `NEW-MODULE-PROPOSED`). I cannot state the corrected values without
re-deriving the inputs, which requires the unpublished classifier of RS-06. **UNKNOWN** until then; what is
certain is that the currently published set is not the corrected set.

---

#### UNKNOWNS (honest ignorance)
1. The corrected values of `NO-MODEL-CONSUMER`, `ID-SYNTHESIS-REQUIRED`, G02, G03 and the orphan union —
   blocked on the unpublished `_consumer_status` classifier (RS-06).
2. Whether `_kind`/`_consumer_status` were computed or hand-assigned. NOT DETERMINABLE from the kept artifacts.
3. Whether the `VS-nn` ids in `TRACEABILITY-MATRIX.md:227-232` denote executable tests or design records —
   the register does not say, and no `VS-nn` appears in `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`.
4. Nothing was executed. No gate, kernel, checker or corpus ran; `sbcl` and `clingo` are absent from this
   container. Every "would fire / would fail" above is a reading of the declared machinery.
5. I did not re-derive the four matrices or the six dossiers; where I quote them I quote them as artifacts.


### 4.2 Completeness critic (all parts)

### COMPLETENESS CRITIC — what is missing, thin, unverified or contradictory, part by part

Label `critic`. Read-only; every claim below is a path + line/row of an artifact under
`WORK/` or `WORK/agents/`, or a `file:line` of the read-only clone `RO`
(HEAD `4ee2b58a8df0941845ab786bd0ff859844b94dde`, tree `ad71185a`). Nothing here is decided:
where two artifacts disagree, both sides are cited. "UNKNOWN" is used where the evidence stops.
My own ledger of every adjudication item is `WORK/agents/critic/adjudications.json`
(979 de-duplicated entries, 196 of them carrying a canonical id).

#### 0. The one structural fact that shapes every finding below

**Every consolidated adversarial pass ran AFTER its primary artifact was frozen, and no primary
artifact was regenerated afterwards.** Measured mtimes:

| primary artifact | written | its adversaries | written |
|---|---|---|---|
| `matrix-DDI-1/matrix.json` 01:33, `-2` 06:21, `-3` 01:35, `-4` 06:26 | ≤06:26 | `matrix-mediocrity-A` 06:32, `matrix-attack-A` 06:34, `matrix-mediocrity-B` 06:39, `matrix-attack-B` 06:39 | ≥06:32 |
| `dag/order.json` 06:14, `dag/DAG.md` 06:17 | ≤06:17 | `dag-mediocrity` 06:28, `dag-attack` 06:29 | ≥06:28 |
| `cl-DDI-{1,2,3}` 01:31–01:34, `cl-DDI-4` 06:04 | ≤06:04 | `cl-python-hunter` 06:06, `cl-freedom-hunter` 06:13 | ≥06:06 |
| `readiness-map/READINESS-MAP.md` 06:50 | 06:50 | `readiness-skeptic` 07:08 | 07:08 |
| `gates-matrix/survival.json` 20:19 (06-09) | 20:19 | `gates-skeptic` 20:32 | 20:32 |

Only the **gates** stream closed its loop: `deliverables/OPTION-A-ORIGINAL-20-GATE-SURVIVAL-MATRIX.md`
(20:35) folds the skeptic in as §10 and applies S-1/S-3/S-5 corrections in §0.3, §4.7, §6, §7.2.
The other four streams' confirmed defects live only in `orchestrator-notes.md` (N20, N24–N27) and in
`agents/future-review/FUTURE-REVIEW-INPUTS.md`. **No corrected `matrix.json`, `cl-map.json` or
`order.json` exists**, so the CLAUDE.md protocol step "κλείσιμο ευρημάτων ΣΤΗΝ ΕΔΡΑ" is unmet for
Parts 2, 3, 4, 6. This is the single largest completeness gap of the run.

---

#### PART 1 — independent census (orchestrator: `census.json`, `classes.md`, `imported-instance-check.json`)

**Verified by me (recount from `census.json`):** 66 classes = 4 IMPORTED + 56 DEFERRED + 6 OUT_OF_SCOPE;
435 forms = 97 + 332 + 6; batches 12/40, 18/156, 10/12, 16/124; `unclassified_classes: 0`,
`unclassified_forms: 0`. `imported-instance-check.json` carries all five instance blocks
(`define-interface`, `consumes`, `define-subsystem`, `define-write-authority`, `define-pipeline`)
plus `v17_vs_v18_write_authority`. Deliverable `PRE-DDI-INDEPENDENT-CENSUS.md` (633 lines) has §A–§J
including the §I-bis self-correction (N19). **This part is the most complete of the nine.**

- **G1-01 (thin).** The census is class/form-level plus a field-level appendix (§D2,
  `imported-field-coverage.json`), but N15/BLK-C4 (field loss on all four IMPORTED classes) is
  recorded as a blocker and **never re-checked against a schema decision**; §D still lets
  `deferred-imports.sexp:75` `PROMOTION-IMPORTED` stand as "fully represented" without contradiction
  language inside the deliverable body (§D2 states the drops; §D header does not).
- **G1-02 (unverified).** `imported-instance-check.json` proves the 4 IMPORTED classes are IN the
  model. Nothing in Part 1 proves the converse — that the model holds **no** fact whose origin is a
  DEFERRED class. There is no "no-early-import" check anywhere in the nine parts.

---

#### PART 2 — execution matrix, 19 fields per class

**Coverage: complete.** All 56 DEFERRED classes have exactly one matrix row (set equality both
directions against `census.json`; 0 missing, 0 extra, 0 duplicate `class_id`). Every row carries the
same 23 keys; `class_id` + the 18 fields `source_file … rollback` = the 19 ordered fields, plus 4
additions (`batch_reason`, `decision_kind`, `decision_question`, `adjudication_items`).

- **G2-01 (P1, CONTRADICTORY — matrix vs DAG, 3 classes).** Three rows assert their batch placement
  "AGREES" with the dependency evidence while `agents/dag/order.json.conflicts` records a **blocking
  out-of-order conflict from that very class**:
  - `V1.7-SCHEMAS__define-write-authority` (DDI-1) — matrix `batch_reason`: *"AGREES: nothing precedes
    it"*; DAG conflict DDI-1 → `SUBSYSTEM-REGISTRY__define-wp-purpose` (DDI-4), **7 refs**
    (`ADJ-DAG-03`).
  - `V1.5-SCHEMAS__define-algorithm` (DDI-3) — matrix: *"AGREES mechanically"*; DAG conflict
    DDI-3 → `V1.5-SCHEMAS__define-rule` (DDI-4), 1 ref.
  - `V1.5-SCHEMAS__define-cardinality-matrix` (DDI-2) — matrix: *"Dependency evidence AGREES with
    DDI-2 placement"*; DAG conflict DDI-2 → `V1.5-SCHEMAS__define-gate` (DDI-4), 1 ref.
  No artifact reconciles these three. (Symmetrically: 20 rows say DISAGREES where the DAG lists no
  conflict from that class — the two artifacts are using two different notions of "disagrees" and
  neither says so.)
- **G2-02 (P1, MISSING FIELD VALUE).** `decision_question` is **empty in 5 of 56 rows**:
  `V1.5-SCHEMAS__define-required-refs`, `V1.7-SCHEMAS__define-write-authority` (DDI-1),
  `V1.5-SCHEMAS__define-cardinality-matrix` (DDI-2), `V1.5-SCHEMAS__define-algorithm`,
  `V1.5-SCHEMAS__define-projection` (DDI-3). Raised as `M5` (3 rows, matrix-mediocrity-A) and
  `MB-1` (2 rows, matrix-mediocrity-B); the union is exactly these 5 and **none was filled**.
  Note the overlap with G2-01: 3 of the 5 empty rows are the 3 rows the DAG contradicts.
- **G2-03 (P1, unanswered at the seat).** `MA-01` (`field-rule`/`field-cardinality` declared twice with
  incompatible field sets and domains) and `MA-02` (`enum`/`enum-value` with three field sets) are
  CONFIRMED by the orchestrator (N26) and named in FUTURE-REVIEW, but `matrix-DDI-2/matrix.json` still
  carries both declarations unchanged, and the rendered deliverable carries them into
  `DDI-1-4-EXECUTION-MATRIX.sexp`.
- **G2-04 (P2, unanswered anywhere).** `MA-05`, `MA-06`, `MA-07` appear in **no** artifact other than
  `matrix-attack-A/findings.md` — not in orchestrator-notes, not in FUTURE-REVIEW, not in a deliverable.
  Same for `B-02` (only in N27) partially, and for `PH-06`, `PH-07`.
- **G2-05 (P2, deliverable defect).** `render_matrix.py:66` writes the header *"nineteen execution
  fields"* while `render_matrix.py:57` emits **22** named fields per class. The rendered header and the
  rendered body disagree about the artifact's own field count.
- **G2-06 (P2, deliverable defect — duplicate plist key).** Every `(ddi-class …)` form in
  `deliverables/DDI-1-4-EXECUTION-MATRIX.sexp` carries `:source-file` **twice** (once at
  `render_matrix.py:88` in the census header line, once at `:57` as a field) and both
  `:source-count` and `:source-forms` for one concept. For a data-only s-expression read with
  `*read-eval* nil`, a repeated key is a well-formedness defect (a `getf` reader silently takes the
  first) and a "two seats for one concept" violation inside the artifact that preaches one seat.
- **G2-07 (P2, DATA LOSS in the deliverable).** `render_matrix.py:44` `CL_FIELDS` lists 14 CL keys;
  the CL maps carry 16/17/16/18 keys. `mop_requested` (18 DDI-2 rows) and `future_constraint_level`
  (16 DDI-4 rows) are **dropped** — `grep -c ":mop-requested"` and `":future-constraint-level"` in the
  deliverable = 0/0. Part 4 data does not survive into Part 8.

---

#### PART 3 — dependency DAG, real order, entry/exit criteria, conflicts

**Coverage: present but unfinished.** `agents/dag/order.json` has 60 nodes (56 deferred + the 4
IMPORTED), 56-long `topological_order`, 54 `topological_components`, 10 `atomic_groups`, 3 `cycles`,
33 `conflicts` each with `adjudication_item` + `bounded_adjudication` + `both_sides` (0 conflicts lack
a bounded adjudication), and `entry_exit_criteria` for `PRE-ALL, DDI-1, DDI-2, DDI-3, DDI-4`.

- **G3-01 (MISSING DELIVERABLE).** `deliverables/DDI-DEPENDENCY-AND-ORDER.md` **does not exist**.
  `WORK/skeleton-order.md` still holds unresolved placeholders `{{VERDICT}} {{SEMANTIC_DAG}} {{ORDER}}
  {{ENTRY_EXIT}} {{CONFLICTS}} {{VERIFICATION}}` and `WORK/assemble_order.py` was never run.
- **G3-02 (P1, uncorrected).** `DA-01` (missing blocking edge `V1.8 define-ra-delta-seats` (DDI-1) →
  `V1.8 define-record` (DDI-2), 7 `:seat` bindings, verified by the orchestrator at N25) and `DA-03`
  (missing `SUBSYSTEM-REGISTRY define-subsystem` → `define-wp-purpose`, 26 resolvable + 3 unresolvable
  of 29 `:future-wp` refs) are CONFIRMED. `order.json` still shows **33** conflicts, not 34, and still
  lists `V1.8-SCHEMAS__define-ra-delta-seats` in `importable_without_any_deferred_prerequisite`.
- **G3-03 (P1, uncorrected).** `DA-02` / `F1`: `importable_without_any_deferred_prerequisite` (16
  classes) contradicts `atomic_groups` — a member of an atomic group is not independently importable.
  Both artifacts still ship the contradiction.
- **G3-04 (P2, uncorrected, verified by me).** `F8`: `ADJ-DAG-08` is declared in `DAG.md` and appears in
  `order.json.entry_exit_criteria` **only under `DDI-3.entry`** ("it binds DDI-1, so it cannot be taken
  here") while `DDI-1.entry` names only `ADJ-DAG-01…06`. The batch that is blocked does not list its
  blocker. `ADJ-DAG-08` is also the one ADJ-DAG id with **no conflict row** (`order.json.conflicts`
  contains `ADJ-DAG-01…07` only) — so it is invisible to any consumer that reads conflicts.
- **G3-05 (P1, unanswered anywhere).** `F2` (§5 "requires a prior canonical identity" under-applies its
  own criterion; the three worst cases collide with facts already in the model) is referenced **only**
  in FUTURE-REVIEW's input-inventory table, never substantively, and nowhere else. Treated here as
  unanswered.
- **G3-06 (unverified, method-level).** `ADJ-FR-07` (FUTURE-REVIEW §E) records that the DAG and its own
  attacker disagree about the blocking-edge set (`DA-06`: 234 of 464 edges labelled
  "dossier+source-text" satisfy only the dossier evidence; `F10`: 32 blocking edges have one evidence,
  one rests on a comment). The published edge labels were not re-derived under the stricter rule.
- **G3-07 (thin).** `F7`: five entry criteria under the heading "machine-checkable" name no check, law,
  floor or fact family. Uncorrected in `order.json.entry_exit_criteria`.

---

#### PART 4 — CL-native impact map, 12 dimensions per class

**Coverage: complete on the 12 dimensions.** All 56 classes have a CL row; all 12 dimensions
(`immutable_record clos_class generic_function condition_restart macro_dsl protocol
package_asdf_boundary persistent_event truth_maintenance_dependency temporal_index_projection
compile_time_validation runtime_validation`) are non-empty in every one of the 56 rows.

- **G4-01 (P2, CONTRADICTORY SCHEMA — `PH-05`, confirmed by orchestrator N20).** The four
  `cl-map.json` files are **not one schema**: DDI-1 16 keys, DDI-2 17 (`+mop_requested`), DDI-3 16,
  DDI-4 18 (`+future_constraint_level`, `+source`). Not fixed; and see G2-07 — the deliverable
  resolves the divergence by silently dropping the two extra columns.
- **G4-02 (P2, `PH-04`).** `python_in_cl_risk` uses HIGH/MEDIUM/LOW (+one "HIGHEST") in DDI-1…3 and
  YES/MODERATE in DDI-4. One column, two scales, no declared mapping. Uncorrected.
- **G4-03 (P1, uncorrected).** `PH-01` (the DDI-2 map cites `source/knowledge-graph.lisp:69-71`
  `assertion-class` as "a metaclass that enforces the invariant"; it is an empty metaclass, the
  invariant is enforced by `initialize-instance :after` at `:80-85`) and `PH-02` (the capability→
  implementation seat is cited on the string-keyed `*analyzer-registry*` at
  `source/greek-nlp-core.lisp:396-401` rather than the collision-detecting
  `source/capability-registry.lisp:63-82`) are CONFIRMED by the orchestrator (N20). The DDI-2 cl-map
  still carries both citations.
- **G4-04 (P1, unanswered anywhere — the largest single hole).** `FH-03` ("the S19 substrate does not
  implement the identity rule the maps say it already does") appears in **zero** artifacts other than
  `cl-freedom-hunter/findings.md`: 0 hits in orchestrator-notes, 0 in FUTURE-REVIEW, 0 in
  READINESS-MAP, 0 in any deliverable.
- **G4-05 (P1, id-only coverage).** `FH-04` (hot-swappable Greek analyzer output inside sealed memory)
  is covered **by content** as READINESS-MAP §8 `AM-06` but never under its id, so a reader tracking
  finding ids sees it as open. `FH-07` likewise (READINESS-MAP §8 only). `FH-02`, `FH-05`, `FH-06`,
  `FH-14` are named in FUTURE-REVIEW; `FH-01` in N20. **None is closed at its seat (the cl-maps).**
- **G4-06 (thin).** Part 4 has no artifact of its own in `deliverables/`: the 12-dimension rows exist
  only inside `DDI-1-4-EXECUTION-MATRIX.sexp` `:cl-native` (minus the two dropped keys) and, per
  `assemble_readiness.py:15-21`, were to be folded into the missing
  `POST-DDI-FULL-BUILD-READINESS.md`.

---

#### PART 5 — the original 20 Option-A gates, 12 attributes each, survival equation

**Coverage: complete and the only stream that closed its adversarial loop.** `survival.json` holds
exactly 20 gates (`G01 G02 G03 G04 G05 G06 G07 G08 G09a G09b G10-12 G13 G14 G15 G16 G17 G18 G19 G20
G21`), 16 keys each; the deliverable renders 20 cards and **all 20 carry all 12 attributes**
(`W S P I O DDI NOW ST AC F L SET` — checked mechanically, 0 cards missing any attribute). Equation
`20 = PRESERVED 2 + GENERALIZED 16 + MISSING 2`, with the skeptic's alternative reading `2+18+0`
recorded, `double_counting: none`, 8 adjudication items, 5 unknowns.

- **G5-01 (STALE).** The deliverable was written 2026-09-06 20:35, i.e. **before** orchestrator notes
  N17, N24 and the READINESS-MAP §6. It therefore does **not** contain the two candidate Option-A
  gates those found: `grep RAT-PUBPRIV` = **0 hits**. Missing from Part 5:
  - N17 — `rationale-references.sexp:7` `RAT-PUBPRIV :anchor "public/private one-way boundary"`
    occurs 0 times in `deployment/LAWMAX-THREAT-MODEL.md`; candidate gate "every rationale anchor
    resolves".
  - N24.1 — `rationale-references.sexp:3` `RAT-V6I-17` passes a naive grep by pointing at a **comment**
    in the wrong file; the anchor gate must resolve to a *definition*.
  - READINESS-MAP §6.2 `F1…F8` (eight kinds of source fact with no future gate).
- **G5-02 (P1, open by design).** `S-8` — who enumerated the options, and the external artefact that
  settles the list, is UNRESOLVED. Recorded as `ARCH-A-1` / `GM-A-1` and §9 of the deliverable; it
  is an honest UNKNOWN, not a defect, but it means **Part 5's identification of "the 20" remains a
  CANDIDATE** and every downstream `option_a_gate` value in Part 6 inherits that status.
- **G5-03 (arithmetic, unreconciled).** `survival.json` `missing = 2` (G09b, G17) vs
  `WORK/my-gate-mapping.md` rows 10/16 "DEMOTED (informational)" — recorded as `ADJ-RM-02`, not
  decided. Two gates carry `superseding_check` empty; that is the only empty attribute value in the
  20 cards, and it is correct (they have none).
- **G5-04 (ID-NAMESPACE COLLISION across artifacts).** `A-1…A-8` is used by `gates-matrix` and
  `A-1…A-6` by `gates-archaeology` for **different** items (my ledger disambiguates them as `GM-A-n`
  / `ARCH-A-n`; the deliverable merges them in §7 with a withdrawal note for archaeology `A-6`, but
  the raw artifacts do not).

---

#### PART 6 — no-loss readiness map with 8 hunts

**Coverage: complete.** `READINESS-MAP.md` has all 56 classes (set equality with the census), the five
columns (§1–§2), and eight hunts: §4 orphans (42/56), §5.1 requirement universes, §5.2 tests without a
falsifiable failure (15), §6.1 gates without facts (6), §6.2 facts without gate (8), §7 private leaks
(8), §8 accidental mandatory (6), §9 refactor points (12), plus §10 nine `ADJ-RM-*` and §11 seven
unknowns. Gate vocabulary agrees exactly with Part 5 (0 labels outside the 20 ids).

- **G6-01 (P2, CONFIRMED and uncorrected — `RS-05`).** "the proposed canonical module column
  contradicts the gaps column in 7 of 56 rows". `RS-05` appears in **no** artifact other than
  `readiness-skeptic/findings.md` (0 hits in notes, FUTURE-REVIEW, deliverables). Same for the other
  confirmed readiness-skeptic defects `RS-15`, `RS-16`, and the unresolved `RS-18` (the headline gate
  loads rest on the defects above). The readiness stream's adversarial pass is **entirely unanswered**.
- **G6-02 (INDEPENDENCE — thin).** `readiness-map/build_map.py:16-20` loads the four `matrix.json`
  files and `:75` decides status "by the matrix row's OWN leading verdict token". The `module` column
  is therefore a **restatement of Part 2**, not an independent check: my token comparison found 0
  substantive disagreements over 56 rows (the 8 apparent ones are prose truncation). §0 of the map
  claims "what I recomputed myself"; the recomputation is real for nesting/consumers/req-map but not
  for module/owner. Nothing in the nine parts cross-checks the module assignment against a second
  source.
- **G6-03 (counting, unreconciled inside the artifact).** §6.1 says `gates_without_facts = 6` while
  §3's disjoint reading gives **7** gates fed by no DDI source class (`G01 G06 G07 G08 G09b G17 G18`).
  My own count over `map.json.option_a_gate` confirms 7 gate ids are never assigned to any class. The
  map records both readings and their intersection {G09b, G17, G18} — honest, but the headline number
  6 is the one that propagates.
- **G6-04 (ID-NAMESPACE COLLISION).** READINESS-MAP §6.2 uses `F1…F8` and §0 uses `M1…M6`; the same
  tokens are `dag-mediocrity` findings `F1…F12` and `matrix-mediocrity-A` findings `M1…M12`. Any
  automated roll-up of finding ids across artifacts (including my own first pass) mis-joins them.

---

#### PART 7 — future-review inputs (no ceiling adjudication)

**Coverage: complete and the most self-aware artifact of the run.** `FUTURE-REVIEW-INPUTS.md`
(75.6 KB) has §0 input inventory (including the honest record that five `findings.md` appeared while
it was being written, and that the named agent paths did not exist), §A `BS-01…BS-21`, §B `PB-01…PB-28`,
§C `FP-01…FP-15`, §D `RT-01…RT-28`, §E `ADJ-FR-01…07`, §F unknowns. The no-ceiling discipline is
stated first and `RS-11`'s attack on it was **REFUTED**.

- **G7-01 (thin, self-declared).** §0 records that `matrix-mediocrity-B` (06:39) and `matrix-attack-B`
  (06:39) landed at the moment of writing; the ids `MB-1…MB-10` and `B-06…B-08` are consequently
  listed but not analysed. `MA-05/06/07` are absent entirely.
- **G7-02 (open, by design).** `ADJ-FR-06` asks whether 8 consolidated adversarial passes discharge a
  protocol written for 18 (orchestrator N18). This is the run's own scope question and **no artifact
  answers it** — correctly, since it is the creator's to decide.
- **G7-03 (MISSING).** Part 7's content has no home in `deliverables/`: it was to be §3 of
  `POST-DDI-FULL-BUILD-READINESS.md` (`assemble_readiness.py:24`), which does not exist.

---

#### PART 8 — five deliverables outside the repository

**Only 3 of 5 exist** in `scratchpad/deliverables/`:

| # | deliverable | status |
|---|---|---|
| 1 | `PRE-DDI-INDEPENDENT-CENSUS.md` (90.7 KB, 633 lines) | PRESENT |
| 2 | `DDI-1-4-EXECUTION-MATRIX.sexp` (1.12 MB; 56 `ddi-class`, 56 `:cl-native`, 334 `adjudication`, `matrix-footer` `:matrix-rows-missing () :cl-rows-missing () :dag-order-present T`) | PRESENT (defects G2-05/06/07) |
| 3 | `OPTION-A-ORIGINAL-20-GATE-SURVIVAL-MATRIX.md` (101.6 KB, 20 cards × 12 attributes) | PRESENT (stale, G5-01) |
| 4 | `DDI-DEPENDENCY-AND-ORDER.md` | **MISSING** |
| 5 | `POST-DDI-FULL-BUILD-READINESS.md` | **MISSING** |

- **G8-01 (BLOCKER).** Deliverables 4 and 5 are unassembled. `assemble_order.py` and
  `assemble_readiness.py` exist and their skeletons (`skeleton-order.md`, `skeleton-readiness.md`)
  still contain live `{{…}}` placeholders.
- **G8-02 (BUG that will silently empty Part 4 from deliverable 5).**
  `assemble_readiness.py:19-20` reads `agents/cl-python-hunter-<batch>/findings.md` and
  `agents/cl-freedom-hunter-<batch>/findings.md`. Those directories **do not exist** — the consolidated
  agents are `agents/cl-python-hunter/` and `agents/cl-freedom-hunter/` (orchestrator N18). As written,
  all **8** hunter slots render `_not produced_`, i.e. `PH-01…PH-08` and `FH-01…FH-14` would vanish
  from the only deliverable meant to carry them.
- **G8-03 (deliverable 2 emits only part of the adjudication universe).** 334 `(adjudication …)` forms
  = matrix-row items only. My de-duplicated ledger over all artifacts is **979** items. Dossier
  `unknowns` (68 across the six dossiers + gates + cl-DDI-4) are emitted nowhere.
- **G8-04 (no deliverable for Part 1's blockers, Part 4's hunts, Part 6's hunts as such).** The three
  present deliverables cover Parts 1, 2 (+4 partially), 5. Parts 3, 6, 7 have **no** delivered artifact.

---

#### PART 9 — final return A–J

- **G9-01 (NOT STARTED).** No artifact anywhere under `WORK/` drafts an A–J return; `grep` for
  "final return" finds only `orchestrator-notes.md:82` (N18, "recorded for the final return"). The
  structure of A–J is not written down in any file I can read, so I cannot verify its completeness —
  **UNKNOWN**.
- **G9-02.** `WORK/adjudications.json` (784 items) is the orchestrator's roll-up and is **incomplete**
  as a Part-9 input. `collect_adjudications.py` reads only the six dossiers, the four matrices,
  `*/order.json` conflicts, `orchestrator-notes.md` N-headings, and two gate `.md` files. It never
  reads: `readiness-map` (§10 `ADJ-RM-01…09` and 56 `_adjudications` arrays), `future-review`
  (`ADJ-FR-01…07`, `BS-*`, `FP-*`, `PB-*`, `RT-*`), `gates-matrix/survival.json` `adjudication_items`
  (only the `.md` is regexed), `cl-DDI-4/return.json`, **any** of the ten skeptic `findings.md`, and
  any `unknowns` array. My replacement ledger is `agents/critic/adjudications.json` (979 items).
- **G9-03 (method defect in the ledger, = `ADJ-FR-03`).** `collect_adjudications.py:44` de-duplicates
  on a normalised **120-character prefix**. Two distinct items that share an opening clause collapse
  into one; the same item phrased differently by two agents stays double. Identity of an adjudication
  item is itself undecided (`ADJ-FR-03`, both sides cited).
- **G9-04 (session interruptions).** N18 records two usage-limit deaths and the 18→8 skeptic
  consolidation. That is honestly recorded, but it is the direct cause of G0 (no primary artifact was
  regenerated after its adversary ran) and of G8-01. It must appear in the final return, not only in
  the notes.

---

#### Cross-artifact contradiction register (the short list a creator must adjudicate)

| # | artifact A | artifact B | the disagreement |
|---|---|---|---|
| X1 | `matrix-DDI-1/2/3.batch_reason` = AGREES for 3 classes | `dag/order.json.conflicts` | 3 classes: write-authority→wp-purpose (7 refs), algorithm→rule, cardinality-matrix→gate |
| X2 | `matrix-*.batch_reason` = DISAGREES (34 classes) | `order.json.conflicts` (17 source classes) | 20 classes DISAGREE with no DAG conflict — two undeclared definitions of "disagrees" |
| X3 | `order.json.conflicts` = 33 | `dag-attack` DA-01 (verified N25) | 34th conflict (ra-delta-seats → V1.8 define-record) |
| X4 | `order.json.importable_without_any_deferred_prerequisite` (16) | `order.json.atomic_groups` (10) | DA-02/F1: group members are not independently importable |
| X5 | `order.json.entry_exit_criteria.DDI-1` | `…DDI-3.entry` + `DAG.md` AG-03 | ADJ-DAG-08 binds DDI-1 but is listed only under DDI-3 |
| X6 | `cl-DDI-1/3` (16 keys) | `cl-DDI-2` (17) / `cl-DDI-4` (18) | one map, four schemas (PH-05) |
| X7 | `cl-DDI-1..3` HIGH/MEDIUM/LOW | `cl-DDI-4` YES/MODERATE | `python_in_cl_risk` is not one scale (PH-04) |
| X8 | `survival.json` `missing = 2` | `my-gate-mapping.md` rows 10,16 "DEMOTED" | ADJ-RM-02 |
| X9 | READINESS-MAP §6.1 `gates_without_facts = 6` | READINESS-MAP §3 (7 gates unfed) + my count (7) | two readings, one headline |
| X10 | `WORK/dossier-graph.json` 123 edges | `agents/dag` 361/464 edges | N21/N22: 103 agree, 258 only theirs, 20 only mine |
| X11 | `render_matrix.py:66` "nineteen fields" | `render_matrix.py:57` 22 fields emitted | deliverable header vs body |
| X12 | `deliverables/…MATRIX.sexp` `:cl-native` (14 keys) | `cl-map.json` (16–18 keys) | `mop_requested`, `future_constraint_level` dropped |
| X13 | READINESS-MAP `F1…F8`, `M1…M6` | `dag-mediocrity F1…F12`, `matrix-mediocrity-A M1…M12` | id namespace collision across artifacts |
| X14 | `gates-matrix A-1…A-8` | `gates-archaeology A-1…A-6` | id namespace collision |

---

#### P1 findings and whether any artifact answers them

Nothing in the corpus is labelled P0; P1 is the top severity used. **24** P1 findings were raised
(`S-1 S-8 | MA-01 MA-02 | M5 | MB-1 | DA-01 DA-02 DA-03 | F1 F2 | PH-01 PH-02 | FH-01…FH-06 FH-14 |
RS-01 RS-02 RS-03 RS-11`); 4 of them (`RS-01 RS-02 RS-03 RS-11`) were REFUTED by their own author,
leaving **20 live P1s**. (Note a labelling discrepancy: FUTURE-REVIEW §A calls
`matrix-mediocrity-A` **M1** a P1; that file marks only **M5** as P1.)

| answered where | ids |
|---|---|
| Closed in a deliverable (gates stream only) (2) | `S-1`, `S-8` (as an open adjudication with the external artefact named) |
| Recorded in `orchestrator-notes` and/or FUTURE-REVIEW, **not closed at the seat** (12) | `MA-01 MA-02 DA-01 DA-02 DA-03 PH-01 PH-02 FH-01 FH-02 FH-05 FH-06 FH-14` |
| Covered by content under a different id only (1) | `FH-04` (= READINESS-MAP §8 `AM-06`) |
| **Answered by no artifact at all** (5) | `FH-03`, `F1` (bare inventory mention only), `F2`, `M5`, `MB-1` |

`p0p1_unanswered = 5` under the strict reading (no artifact records or refutes them), and
`= 18` under the strict-closure reading (every live P1 except `S-1`/`S-8`, whose seat was corrected).

---

#### What I could NOT determine (honest ignorance)

1. The creator's exact wording of the "19 fields", "12 dimensions", "12 attributes" and "8 hunts"
   lists is not in any file I can read; I verified the counts against the artifacts' own declared
   vocabularies (`render_matrix.py:57`, `CL_FIELDS`, the gate card legend, READINESS-MAP §§4–9).
   Whether those vocabularies are the ordered ones is UNKNOWN.
2. The A–J structure of the Part-9 return is not written anywhere under `WORK/` — I cannot audit it.
3. Whether the 20 empty-conflict "DISAGREES" rows (X2) are a defect or two legitimate definitions
   cannot be settled from the artifacts; both sides are cited.
4. Whether `RS-05`'s "7 of 56 rows" reproduces is unverified — I did not re-derive the gaps column.
5. `sbcl`/`clingo` are absent in this container (N6); no claim here rests on a run, and no gate,
   corpus or battery was executed.

---

#### Adjudication ledger index (`WORK/agents/critic/adjudications.json`, 979 de-duplicated items)

**196 items carry a canonical id**, grouped by the artifact that raised them:

| raising artifact | ids |
|---|---|
| `future-review/FUTURE-REVIEW-INPUTS.md` | `ADJ-FR-01…07`, `BS-01…BS-21` (28) |
| `dag/order.json` | `ADJ-DAG-01…07` (7, one per conflict class) |
| `dag/DAG.md` | `ADJ-DAG-08` — declared but **absent from `order.json.conflicts`** (1) |
| `readiness-map/READINESS-MAP.md` | `ADJ-RM-01…09` (9) |
| `gates-matrix/survival.json` | `A-1…A-8` (8; disambiguated `GM-A-n`) |
| `gates-archaeology/report.md` | `A-1…A-6` (6; disambiguated `ARCH-A-n`) |
| `orchestrator-notes.md` | `N1…N27` (27) |
| `gates-skeptic` | `S-1…S-9` (9) |
| `matrix-attack-A` | `MA-01…MA-10` (10) |
| `matrix-attack-B` | `B-01…B-08` (8) |
| `matrix-mediocrity-A` | `M1…M12` (12) |
| `matrix-mediocrity-B` | 10 unnumbered findings (indexed `MB-1…MB-10`) |
| `dag-attack` | `DA-01…DA-09` (9) |
| `dag-mediocrity` | `F1…F12` (12) |
| `cl-python-hunter` | `PH-01…PH-08` (8) |
| `cl-freedom-hunter` | `FH-01…FH-14` (14) |
| `readiness-skeptic` | `RS-01…RS-18` (18) |

**783 further items are prose-only (no canonical id)** — every one is a distinct `adjudication_items`
entry or `decision_question` from: `dossier-V1.8` 124, `matrix-DDI-2` 120, `matrix-DDI-4` 100,
`dossier-V1.7` 75, `dossier-SUBSYSTEM-REGISTRY` 68, `matrix-DDI-1` 66, `matrix-DDI-3` 66,
`dossier-V1.6` 62, `dossier-V1.5` 48, `dossier-INTERFACE-AND-SCHEMA-REGISTRY` 41,
`cl-DDI-4/return.json` 13. That 783 have no id is itself the reason `ADJ-FR-03` (identity of an
adjudication item) is open, and the reason the orchestrator's 120-character-prefix de-duplication
(`collect_adjudications.py:44`) cannot be audited.


---

## 5. Orchestrator-verified defects and cross-checks (computed or re-verified by me against the clone, independent of the agents)

Every item below was re-derived by the orchestrator with its own tooling or `git`/`grep` on the read-only clone. Items raised by an agent are marked as such; the verification is mine.

### N17. Live-model defect (verified): dangling rationale anchor, invisible to every counted check

rationale-references.sexp:7 `(fact rationale RAT-PUBPRIV :doc "deployment/LAWMAX-THREAT-MODEL.md" :anchor "public/private one-way boundary")` — the anchor string occurs 0 times
in that file (also 0 for "one-way", "μονόδρομ", "public/private"). The other four rationale anchors (:V6I-17, :SR-V6-one-seat, :SR-V6-wp-honesty, "define-pipeline symbolic-only-path") resolve.
L3 only checks that `:rationale` refs name a `rationale` fact id; no check (gate_checks.py has no rationale resolver) opens :doc and greps :anchor. RAT-PUBPRIV is the rationale of the
four private/interface-only seats (SEAT-PRIVATE-MATTER-PROFILE, SEAT-REALTIME-ASSISTANCE, SEAT-EMBODIMENT-INTERFACES, SEAT-TENANT-PROFILE) — the public/private boundary's stated
justification points at text that does not exist. Candidate Option-A/full-build gate: "every rationale anchor resolves" (cf. V8I-XREF-real, which does exactly this for define-reference at source level).

### N18. Session-limit interruptions (recorded for the final return; no evidence was fabricated to cover them)

The account hit its usage limit twice during the reconnaissance (resets 00:50 and 05:50 UTC on 2026-09-07). Casualties and recovery:
- 1st limit: dossier V1.8 agent died → re-run from cache-resume, completed (374 KB, class-for-class equal to my census).
- 2nd limit: matrix DDI-2 + DDI-4, cl DDI-4, the whole DAG stage and ALL 18 planned skeptics died. matrix DDI-3 and cl DDI-1/2/3 had already written their files before their agents failed (files validated: DDI-3 = 10/10 classes, all 23 keys).
- Recovery: four fill-in workflows re-run the missing primary artifacts; the 18 planned skeptics are consolidated into 8 (two independent axes per artifact class: matrix attack/mediocrity over DDI-1+2 and DDI-3+4; DAG attack/mediocrity; CL python-hunter/freedom-hunter over all four maps) to fit the remaining budget while keeping adversarial coverage of every artifact.

### N19. Self-correction (found by an agent, verified by me)

My census §H(4) wrote "92 define-invariant forms across five files"; my own per-file counts span SIX registries (ISR 1, SR 2, V1.5 22, V1.6 21, V1.7 23, V1.8 23 = 92). The TOTAL was right, the file count was wrong. Corrected in the deliverable (§I-bis records the correction rather than hiding it).

### N20. Adversarially-found defects in the CL maps that I verified MYSELF against the clone (all CONFIRMED)

- PH-01: source/knowledge-graph.lisp:69-71 `assertion-class` is an EMPTY metaclass `(defclass assertion-class (standard-class) () ...)` whose only method is validate-superclass; the invariant "no assertion without a source" is enforced at :80-85 by `initialize-instance :after` — standard CLOS, no MOP needed. Same shape at deliberation.lisp:40-44 (`thought-class`). CONTROL: review-queue.lisp:54-57 and corpus-service.lisp:44-46 ARE slot-bearing metaclasses. So the DDI-2 map's citation of assertion-class as "a metaclass that enforces the invariant" is wrong, and the two empty metaclasses are themselves gratuitous mechanism under contract:6-8.
- PH-02: source/greek-nlp-core.lisp:396 `*analyzer-registry*` is an `equal` hash keyed by STRINGS with a bare `setf gethash` at :399-401 (silent overwrite, no collision detection), whereas source/capability-registry.lisp:63-82 has `*capabilities*` (eq/keyword) + `*capability-owners*` + a `capability-seat-collision` condition. The map cited the weaker of the two registries for a one-seat invariant.
- PH-05 / my own count: the four cl-map.json files have DIFFERENT key sets per object (16 / 17 / 16 / 18 keys); `mop_requested` exists only in DDI-2's JSON.
- PH-04 / my own count: python_in_cl_risk uses HIGH/MEDIUM/LOW in DDI-1..3 (with one "HIGHEST") but YES/MODERATE in DDI-4 — not one comparable scale.
- PH-03 / my own count: 402 mechanism cells, 61 of them carry no "invariant:" token (the agent counted 341/95 with a different cell definition; direction identical).
- FH-01: TWO canonical serialization seats at HEAD — journal.lisp:61 `canon-sexp` (the CL runtime seat the contract names) and AMC2 (MODEL-SCHEMA.sexp:37 + CANONICAL-ENCODING.md), while the contract claims "one canonical serialization boundary". A real one-seat collision for the adjudicator.

### N21. DAG cross-check (my dossier graph vs the agent's semantic graph)

123 of my edges vs 361 distinct agent edges; 103 agreed (84% of mine); 258 only theirs (richer kinds: lineage, same-name-seat, competing-seat); 20 only mine — almost all pointing at a `define-invariant` target, i.e. docstring citations the agent's edge vocabulary deliberately excludes. Recorded as a modelling decision with consequences (27 violations vs 33 conflicts, 11 overlapping), not silently reconciled.

### N22. Why the agent's DAG dropped 20 of my edges — method, not omission (recorded after reading its stated method)

The DAG agent required TWO independent evidences per edge: (1) a dossier `references` entry of an admitted kind resolving into one of the six registries, AND (2) the source form's own TEXT containing the target's id token (form extent = start line to the line before the next top-level form). It then applied four documented filters: self-name vacuity (186 hits — a form containing its own id), direction-heterogeneous `consumer` refs (ISR `:consumers (...)` is outbound while a V1.6 note "consumed by ..." is inbound), enum-leaf out-edges (a closed-enum body is keyword members only), and matrix-labelled LINEAGE/reverse entries. My dossier graph used ONE evidence (the locator) and no direction filter, so its 123 edges are an upper bound and the 20 it does not share are explained by that stricter rule — not by an omission. The dag-attack skeptic was instructed to re-check 10 dropped mechanical edges precisely to test this.

### N23. DAG headline results (agent, to be checked by its two skeptics)

- The topological order is NOT DDI-1→2→3→4: DDI-2 enums/records occupy ranks 0-11 while nine DDI-1 classes sit at ranks 15-51; 54 topological components over 56 classes; 16 classes have no deferred prerequisite at all.
- Exactly 2 real cycles: CYC-1 `define-cognition-graph` ↔ `define-cognition-node-types` is a TRUE co-definition (node-set equality V1.8:53-65 vs :363-383) resolvable only by atomic co-import, never by ordering; CYC-2 V1.5 gate ↔ rule is a class-granularity artefact — acyclic at FORM level (rule@:87 → gate@:123 → rule@:140).
- The mechanical 5-class SCC I reported in §2 is adjudicated NOT a real import cycle, with three evidenced reasons: 2 of its 5 members are already IMPORTED; between the two deferred members the reference is one-way and textual; V1.6 define-protocol has no out-edge and is pulled in only by ISR/SR naming SemanticProposer.
- 33 conflicts over 83 verified blocking references, every one deferred→deferred, each with a two-option bounded adjudication citing both sides; nothing re-batched.
- Entry/exit criteria per batch name REAL machinery: gate checks led-01, sea-01, cor-01, uni-01, ver-01, enc-01, fls-01, tcb-01, doc-01..03, ro-01, gen-02, art-01; laws L1-L7; floors UF-SEAT 33 / UF-FALSIFIER 80 / UF-FIXTURE 8 / UF-PROPERTY-FAMILY 5 / UF-GEN-ARTIFACT 12; property families PF-L5 6 / PF-L3 33 / PF-L6 26 / PF-L4 8.

### N24. Two more live-model defects verified by me against the clone (raised by the DDI-4 matrix agent)

1. **A second dangling rationale anchor, subtler than N17.** `rationale-references.sexp:3` = `(fact rationale RAT-V6I-17 :doc "SUBSYSTEM-REGISTRY.sexp" :anchor ":V6I-17")`. In that file `:V6I-17` occurs exactly once — at LINE 3, inside the header COMMENT ";;;; NOT a second hand-maintained truth (v1.6 :V6I-17)". The invariant is actually defined at `V1.6-SCHEMAS.sexp:348` as `(define-invariant :V6I-17-one-source-of-truth`. So: RAT-PUBPRIV (N17) fails even a naive grep; RAT-V6I-17 PASSES a naive grep while pointing at a comment mention in the wrong file. Any future "anchor resolves" gate must therefore resolve to a DEFINITION, not to a text occurrence — otherwise it certifies this row.
2. **SemanticProposer is mechanically un-importable as a protocol.** `interfaces-and-types.sexp:57` already owns the id as `(fact type SemanticProposer ...)`; `V1.6-SCHEMAS.sexp:57` defines `(define-protocol SemanticProposer`. Under L2 (an id is owned by exactly one fact type) no `protocol` fact can be written under that id in ANY batch. This is not a scheduling problem; it is a naming/seat decision that must precede DDI-4.
3. Context check for the wp claim: the model holds 14 `wp` facts and 29 `req-map` facts, i.e. the ids the DDI-4 class `define-wp-purpose` would import are already live and consumed — supporting the agent's "belongs at the FRONT, not in DDI-4" disagreement (N2 records the double-origin consequence).

### N25. The DAG's two missing blocking edges — found by the attacker, present in MY graph, verified by me at source

- **DA-01** `V1.8 define-ra-delta-seats` (DDI-1) → `V1.8 define-record` (DDI-2): V1.8-SCHEMAS.sexp:444-451 binds seven `:seat` values and ALL SEVEN are define-record forms — CanonicalCitationURI/1 :110, ContinuityPolicy/1 :140, PublicCorrectionEvent/1 :160, CitationMetricV8/1 :179, SidecarSourceProfile/1 :193, LawmaxStatusVsMark/1 :207, JurisdictionNamespace/1 :452. My mechanical graph carried this edge with 7 refs; `order.json` had no edge to define-record from that class and listed it as importable with no deferred prerequisite. → a 34th DDI-1→DDI-2 conflict.
- **DA-03** `SUBSYSTEM-REGISTRY define-subsystem` (IMPORTED) → `define-wp-purpose` (DDI-4): 29 `:future-wp` occurrences against 16 `define-wp-purpose` ids; my mechanical graph carried it with 29 refs; `order.json` had only the reverse non-blocking annotation. Three tokens resolve to NO define-wp-purpose id — `DEFERRED` (×4), `WP-07+WP-11+WP-14`, `WP-07+WP-08` — so the honest count is 26 resolvable + 3 unresolvable, and those 3 must be recorded as an L3/L6 UNKNOWN instead of disappearing with the edge.
- Method note: both were caught because the orchestrator's mechanical graph and dossier graph are kept as an independent upper bound against which the agent's stricter semantic graph is diffed. The other confirmed attacker findings (DA-02 atomic-group members wrongly listed as independently importable; DA-04 the self-name filter firing on an ANONYMOUS form that has no name; DA-05 atomic groups split across non-contiguous ranks; DA-06 234 of 464 edges labelled "dossier+source-text" that satisfy only the dossier evidence — all non-blocking, so the topological order stands) are recorded in the deliverable with the agent's required corrections.

### N26. Matrix DDI-1/DDI-2 adversarial pass — what I verified myself

- **MA-03 CONFIRMED (with one fairness correction).** The DDI-1 `define-write-authority` falsifier appends exactly `(fact store journal :owner SEAT-JOURNAL :writer SEAT-WRITE-AUTHORITY)` — byte-identical to `FIXTURES/FAIL/l2-duplicate-store.sexp` — and the `define-pipeline` falsifier appends exactly `(fact stage-edge PUBLISH__ACQUIRE :from PUBLISH :to ACQUIRE)` — byte-identical to `FIXTURES/FAIL/l4-pipeline-cycle.sexp`. Both are additionally generated for every store/stage by `PF-L2-DUPLICATE-STORE` (cardinality 10) and the L4 family. So as HELD-OUT falsifiers they add zero discrimination. **Fairness correction to the attacker:** the matrix rows do NOT hide this — each row cites the fixture id inline ("= FX-L2-DUPLIC…", "= FX-L4-PIPELINE-CYCLE"). The defect is that a duplicate was offered in the `falsifier` field at all, not that it was concealed.
- The attacker also REFUTED five of its own planned vectors with evidence (no PRIVATE form mis-routed; no unraised second seat; no owner/writer contradicting seats.sexp; no nested-list class called PURE_DATA without a flattening rule; no sustained tautological test) — recorded because a review that only reports hits is grading its own homework.
- Confirmed P1s to carry into the deliverable: **MA-01** the NEW fact type `field-rule` and enum `field-cardinality` are declared TWICE with incompatible field sets and domains (V1.5 cardinality-matrix vs V1.8 cardinality-table) while one row asserts "ONE family shared" — under MODEL-SCHEMA.sexp:9-13 each declaration makes the other's facts L1 violations; **MA-02** `enum`/`enum-value` carry three different field sets across the DDI-2 enum rows while V1.7/V1.8 claim "the shared family".

### N27. Matrix DDI-3/DDI-4 adversarial pass — verified by me at source

- **B-01 CONFIRMED.** `gate_checks.py:758` emits `UNIVERSE-FLOOR-REDUCED` when a FLOOR moves and `:763` emits `UNIVERSE-BELOW-FLOOR` when a family drops below it. The DDI-3 row's falsifier declares `:reason "UNIVERSE-FLOOR"`, and `run_corpus.py:320` matches with a plain substring test (`if needle not in out`) — "UNIVERSE-FLOOR" IS a substring of "UNIVERSE-FLOOR-REDUCED" but the case at issue emits "UNIVERSE-BELOW-FLOOR", which does NOT contain it. All 9 existing CHECK falsifiers of this family use the exact token `UNIVERSE-FLOOR-REDUCED`. Correction: use `UNIVERSE-BELOW-FLOOR`.
- **B-02 CONFIRMED.** `SEXP-READER.py` imports only `hashlib, os` and contains ZERO occurrences of `__main__` / `argparse` / `sys.argv` — it is a library, not a CLI, so `python3 SEXP-READER.py --model .` cannot run; and `jq` appears 0 times in `TOOLCHAIN.sexp`, whose five pinned roles are KERNEL_RUNTIME, DIGEST_PROVIDER, CHECKER_RUNTIME, ASP_SOLVER, CHECKER_DIGEST_PROVIDER. The test must be restated as a `property-family` over the classified reader.
- **B-05 CONFIRMED against my own census.** V1.8 `define-pipeline` is IMPORTED (`deferred-imports.sexp:63`, census status IMPORTED, batch None); only the V1.7 twin is DDI-1. One DDI-4 row called it a DDI-1 dependency while another row of the same matrix stated it correctly — a self-contradiction, not a source ambiguity.
- **B-03 / B-04** (a `gate-disposition :state` left enum-free so its falsifier can never fire; a falsifier written to admit BOTH acceptance and rejection, i.e. unfalsifiable by construction under `run_corpus.py:519-520` `both_reject`) are carried into the deliverable as required corrections.

## 6. Consolidated adjudication ledger

De-duplicated across all agent artifacts and the orchestrator notes: **784 items**. Sources:

| source artifact | items |
|---|---|
| `agents/matrix-DDI-2/matrix.json` | 120 |
| `agents/matrix-DDI-4/matrix.json` | 100 |
| `agents/matrix-DDI-1/matrix.json` | 69 |
| `agents/matrix-DDI-3/matrix.json` | 66 |
| `agents/dossier-V1.8-SCHEMAS.sexp/dossier.json` | 65 |
| `dossier-V1.8-SCHEMAS.sexp` | 58 |
| `dossier-V1.7-SCHEMAS.sexp` | 46 |
| `agents/dag/order.json` | 33 |
| `dossier-SUBSYSTEM-REGISTRY.sexp` | 32 |
| `dossier-V1.6-SCHEMAS.sexp` | 29 |
| `agents/dossier-V1.7-SCHEMAS.sexp/dossier.json` | 29 |
| `orchestrator-notes.md` | 24 |
| `agents/dossier-V1.6-SCHEMAS.sexp/dossier.json` | 21 |
| `agents/dossier-SUBSYSTEM-REGISTRY.sexp/dossier.json` | 18 |
| `dossier-INTERFACE-AND-SCHEMA-REGISTRY.sexp` | 17 |
| `agents/dossier-V1.5-SCHEMAS.sexp/dossier.json` | 17 |
| `dossier-V1.5-SCHEMAS.sexp` | 14 |
| `agents/dossier-INTERFACE-AND-SCHEMA-REGISTRY.sexp/dossier.json` | 12 |
| `gates-matrix/survival-matrix.md` | 8 |
| `gates-archaeology/report.md` | 6 |

The full ledger with the text of every item is `adjudications.json` in the work set. **No item in it was decided by this reconnaissance**; each names both sides and the evidence.

## 7. What this reconnaissance did NOT do

- No repository file was created, modified or deleted; no commit, branch, push, stash or checkout; no gate, battery, generator or DDI import was executed (`sbcl` and `clingo` are absent from this container, so the kernel could not have been run even by accident).
- No architectural or institutional decision was taken. Where two sources disagree the disagreement is an adjudication item with both sides cited.
- No ceiling adjudication: nothing here says the architecture is "ανώτατη" or freeze-ready. The canonical model remains incomplete until DDI-1…DDI-4 are imported and Option A is actually executed.
- The 21 current Option-2 acceptance checks are never treated as the original 20 Option-A gates.

