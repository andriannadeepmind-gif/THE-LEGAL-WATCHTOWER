# ARCHITECTURE-CLOSURE-MATRIX — CPEI PUBLIC OBSERVATORY PROFILE v1.4
# LAWMAX OMEGA — THE LEGAL WATCHTOWER OF GREECE

**ΚΑΤΑΣΤΑΣΗ: `DESIGN-ONLY · ARCHITECTURE CLOSURE`.** Καμία γραμμή κώδικα, κανένα freeze,
καμία υλοποίηση. Η **μία** μακροαρχιτεκτονική (v1.4)· καμία παράλληλη/νέα. Χαρτογραφεί
κάθε: **mission → subsystem → trust boundary → data type → contract → repository seat →
test → kill test → evidence → implementation-book work package (WP)**. Οι WP είναι
**ονόματα** work packages· το περιεχόμενό τους γράφεται **μόνο μετά** το ρητό
`ΕΓΚΡΙΝΩ SPEC FREEZE` (Implementation Book, εντολή §7). Design-only.

## 1. ΠΙΝΑΚΑΣ ΚΛΕΙΣΙΜΑΤΟΣ (μία γραμμή ανά subsystem/boundary — καμία ορφανή)

| # | mission | subsystem | trust boundary | data type | contract (έδρα) | repository seat | test | kill test | evidence state | Impl-Book WP |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | MIS-2 | National Legal Census / Radar (M1·L9) | source authenticity (S1–S3) | census position (`state ∈ INGESTED/EXPLICITLY-ABSENT/QUARANTINED/UNKNOWN`) | v1.4 §4.1 + `LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md` | `ingestion-daemon.lisp`, `legislation-ingestion.lisp` (EXTEND) | Q01/Q29 | KW-48, KW-109 | UNKNOWN_WITH_OWNER (CAP-157) | WP-01 census + coverage ledger |
| 2 | MIS-1 | Multimodal acquisition (M2·L1/L3) | **Secure Semantic Ingress** (external bytes ≠ Lisp forms) | `source-authenticity` + `ingress-envelope/1`/`parser-result/1` | v1.4 §4.2 + `SECURE-SEMANTIC-INGRESS-CONTRACT.md` | `pdf-authority.lisp` + **non-evaluating JSON/CBOR decoder (NEW, ΟΧΙ safe-read)**· `safe-read.lisp` = internal-only | Q03/Q30 | KW-108 (SIK-1..9 UNEXECUTED) | MISSING (CAP-158) | WP-02 acquisition + ingress sandbox + schema decoder |
| 3 | MIS-1 | Neuro-symbolic bridge (§4.3/§4.4) | epistemic wall (PLANE-3 ≠ trusted) | `neural-candidate/1` (closed) | v1.4 §4.3/§4.4 | `legal-extraction-verify.lisp` (EXTEND) | Q09/Q31 | KW-7, KW-49, KW-50 | missing (CAP-135 EXCLUDED core) | WP-03 neural runtime + closed protocol |
| 4 | MIS-1 | Symbolic Common Lisp core | Legal IR non-executability | typed Legal IR (Fact/Norm/Claim/Proof) | `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` (REQUIREMENTS) | `legal-ast.lisp`, `legal-inference-engine.lisp` | Q07 | KW-105 | UNKNOWN_WITH_OWNER (CAP-156) | WP-04 Legal IR grammar+WFS+conflict evaluator+corpus |
| 5 | MIS-3 | Bitemporal Legal Digital Twin (M3·L2) | valid-time vs audit-time separation | event (closed catalog) + `legal-timeline/1` / `audit-timeline/1` | v1.4 §4.5 + MLTP §2.0 | `version-graph.lisp`, `legal-temporal.lisp` (EXTEND) | Q05/Q06/Q41 | KW-51 | partial (CAP L2) | WP-05 event store + bitemporal projection |
| 6 | MIS-4 | Unified legal hypergraph | relation authenticity (`rel1:` explicit-citation) | USC §6.3 relations | `LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md` §6 | `legal-hypergraph.lisp` (EXTEND) | Q08 | KW-55 | partial | WP-06 hypergraph + impact engine |
| 7 | MIS-4 | Jurisprudence evolution plane (M4·§4.9) | four-class separation | `judgment-identity-and-text` / `jurisprudential-analysis` | MLTP §2.5/§2.6, v1.4 §4.9 | `legal-decisions.lisp`, `citation-authority.lisp` (EXTEND) | Q07/Q25/Q37 | KW-36, KW-55 | MISSING (Μ1) | WP-07 jurisprudence plane + line-of-authority |
| 8 | MIS-5 | Dual independent compilation (M5·§4.6) | compiler independence (no shared evaluator) | `compiler-attestation` | MLTP §13.4, `LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md` §10 | `consolidation-engine.lisp` + Rust compiler (MISSING) | Q11/Q34 | KW-52, KW-105 | UNKNOWN_WITH_OWNER (CAP-156) | WP-08 second compiler + differential harness |
| 9 | MIS-5 | Proof-carrying query engine (M6·§4.7) | proof-carrying-or-UNKNOWN | `proof-carrying-answer/1` (11 §3.F πεδία) | v1.4 §4.7 | `legal-qa.lisp`, `proof-carrying.lisp` (EXTEND) | Q14/Q27/Q35 | KW-53 | missing (answer type) | WP-09 proof-carrying answer type |
| 10 | MIS-1 | MLTP trust layer (§4.10) + crypto agility | pinned root · profile pinning · crypto agility | `IssuedClaim`/`TrustBundle`/`VerificationReceipt`, `crypto-policy-epoch`, `PQRootSet` | MLTP v3 (executable ref §13, +§14 agility) | `deployment/verify/mltp3/` (PASSED) + §14 (MISSING) | Q21/Q22/Q43 | KW-64..106 | executed (πυρήνας) / MISSING (§14) | WP-10 PCL-2 + trust mesh + ML-DSA |
| 11 | MIS-9 | Nation-state security cells (§4.14/§4.22) | single-zone ≠ canonical authority | threshold+n-of-m root, journal, witnesses | v1.4 §4.22 + MLTP §10.2/§14.4 (D-07..09,14) | `authority-v2/` (EXTEND) | Q17/Q18/Q19 | KW-107 | UNKNOWN_WITH_OWNER (CAP-159) | WP-11 HSM/threshold/PQ custody + recovery |
| 12 | MIS-6 | Cockpit (§4.12) | signed intent → M5 (ποτέ direct-publish) | `cockpit_intent` (closed, RBAC/MFA) | v1.4 §4.12 §1.4 | `cockpit.lisp` (`/api/publish` REPLACE) | Q15/Q39 | KW-39, KW-57 | missing (RBAC/MFA) | WP-12 cockpit shell + intent queue |
| 13 | MIS-6 | Public search + website (§4.12) | ιστότοπος = προβολή, ποτέ δεύτερη πηγή | canonical URL `/lawmax/...` (ένα ανά Legal Object) | v1.4 §4.12 (URL topology) | `static-site.lisp` (REUSE) | Q15 | KW-57 (site cell isolation) | missing (app shell) | WP-13 site + search + isolation |
| 14 | MIS-5 | OpenAPI / MCP / SDKs / feeds (§4.15) | citation-bound (§4.16) | `CertifiedResult` + `citation/1` | v1.4 §4.15/§4.16, MLTP §2.10 | `mcp-server.lisp` (EXTEND), OpenAPI (MISSING) | Q26/Q28/Q42 | KW-62, KW-63 | HAS_SEAT partial | WP-14 OpenAPI+SDK+conformance |
| 15 | MIS-9 | Observatories: citation/security/coverage (§4.13/§4.14) | metrics ≠ legal correctness | L9 metrics (typed UNKNOWN if stub) | v1.4 §4.13/§4.14 | `ai-citation-strategy.lisp` (EXTEND) | Q16/Q40 | KW-58, KW-59 | missing (collectors) | WP-15 observatories + SLO/DR |
| 16 | MIS-2 | Source-type authority registry (§4.20) | source-registry completeness | `ST-01..28` + `SourceTypeSchema/1`/`SourceTypeEntry` + `UNKNOWN_SOURCE_TYPE` + encoding profiles | `LAWMAX-PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY.md` | source-profile seats (EXTEND) | I1a/I1b (audit) | KW-109 | UNKNOWN_WITH_OWNER (CAP-157) | WP-16 per-ST collectors/profiles/compilers |
| 17 | MIS-8 | Ontology & validation governance (§4.19) | ontology version binding | `ontology-bundle` + `shacl-validation-receipt` | MLTP §2.11 | `shacl-validator.lisp` (EXTEND) | (audit H) | KW-106 | UNKNOWN_WITH_OWNER (CAP-155) | WP-17 ontology bundle lifecycle |
| 18 | MIS-10 | Public→private boundary (§1.3/§1.4) | 9 απόντες ιδιωτικοί τύποι (structural) | κλειστά σχήματα | v1.4 §1.3/§1.4 | InstitutionalAct public profile | Q20 | KW-39 | HAS_SEAT (type-level) | WP-18 schema enforcement (compile-time) |

## 2. ΕΓΓΥΗΣΕΙΣ ΚΛΕΙΣΙΜΑΤΟΣ — καμία από τις απαγορευμένες καταστάσεις (document/reference επιβολή)

**ΤΙΜΙΑ ΤΑΞΙΝΟΜΗΣΗ ΤΕΚΜΗΡΙΟΥ (micro-pass defect 3):** ο `V1.4-CONTRADICTION-OMISSION-AUDIT.sh`
είναι **DOCUMENT/REFERENCE CONSISTENCY PASS** — deterministic έλεγχοι σε κείμενο/δομή/
αναφορές. **ΔΕΝ** αποδεικνύει semantic/legal/security correctness ούτε source-universe
completeness. Πέντε **διακριτές** κατηγορίες τεκμηρίου: **[1]** deterministic document/
reference checks (αυτός ο audit)· **[2]** executable protocol tests (`run.sh`/mltp3 — μόνο
ο πυρήνας MLTP)· **[3]** legal-content review (MISSION legal gate — τα ST entries είναι
`PENDING_LEGAL_VALIDATION`)· **[4]** security implementation tests (Impl-Book + SIK-1..9,
**UNEXECUTED**)· **[5]** specification qualification (§8 `SPEC QUALIFIED`). Οι παρακάτω
έλεγχοι αποδεικνύουν **δομή**, όχι ουσία:

| απαγόρευση (εντολή §5) | μηχανικός έλεγχος |
|---|---|
| orphan IDs | audit P5g (kwref⊆def), P5r (capref⊆def), P5s (rref⊆def), P5n (dref⊆def) |
| undefined contexts | audit **H2a/H2b/H2c** (context-registry closure, κάθε άπαξ) |
| cyclic object construction | audit **H1a/H1b** (κανένα `*_id` πάνω σε ολόκληρο record· BODY-based) |
| duplicate ownership | audit **H4a/H4b/H4c** (μοναδική έδρα ανά concept) + superseded register (μία έδρα ανά profile) |
| type χωρίς schema | audit **H3** (κάθε extension record ορισμένο) |
| requirement χωρίς test | audit **P5d** (κάθε R-row seat+test+evidence) |
| error χωρίς emission seat | audit C9 (§4.3 35/35) + §14.9/§2.11/ingress §6 (κάθε όνομα με βήμα) |
| source category χωρίς collector/profile/compiler | audit **I1a-I1i** (SourceTypeSchema/1 + 28 SourceTypeEntry + UNKNOWN_SOURCE_TYPE· όλα PENDING_LEGAL_VALIDATION· collector·profile·compiler+coverage) |
| public claim χωρίς evidence state | crosswalk 159/159 caps με κατάσταση· traceability 134/134 με evidence |
| αρχείο χωρίς classification | superseded register (CURRENT/ACTIVE FOUNDATION/EVIDENCE/HISTORICAL/FALSIFIED/SUPERSEDED) |
| untrusted → Lisp code | audit **I3a/I3b/I3c** (Legal IR non-executability) |
| ασαφές algorithm-policy | audit **I4a/I4b** (independent n-of-m ML-DSA, ΟΧΙ «threshold/multisig») |
| public/internal time σύγχυση | audit **I5a/I5b** (legal-timeline ≠ audit-timeline) |

## 3. ΤΑΞΙΝΟΜΗΣΗ ΥΠΟΛΟΙΠΩΝ — κανένα εσωτερικό architecture `UNKNOWN`

Κάθε ανοιχτό στοιχείο ταξινομείται **αποκλειστικά** σε μία από τέσσερις κατηγορίες
(εντολή §6)· **κανένα δεν παραμένει «εσωτερικό architecture UNKNOWN»**:

| κατηγορία | στοιχεία |
|---|---|
| **IMPLEMENTATION-BOOK** | WP-01..WP-18 (τα μηχανοποιημένα artifacts: grammar/WFS/corpus, ML-DSA/hybrid, ontology schemas, per-ST profiles, ingress sandbox, second compiler) — γράφονται **μετά** το freeze |
| **IMPLEMENTATION** | production code κάθε WP (μετά το approved Implementation Book) |
| **QUALIFICATION** | `SPEC QUALIFIED` §8 (KW-1..KW-109 + δομικοί audits + ανεξάρτητοι adjudicators)· Q01–Q43· 15 φέτες· MISSION GREECE-1 |
| **EXTERNAL / OPERATIONAL** | U-2 (registries ταυτότητα)· U-3 (αδειοδότηση doctrine/full-text)· U-4 (benchmark verification)· U-7 (νομιμότητα δημοσίευσης δικαστικών/ΟΤΑ)· θεσμικές συμφωνίες custody |

**Αρχιτεκτονικά UNKNOWN: 0.** Ό,τι απομένει είναι IMPLEMENTATION-BOOK, IMPLEMENTATION,
QUALIFICATION ή EXTERNAL/OPERATIONAL — καμία ανοιχτή αρχιτεκτονική απόφαση.

## 4. Τι ΔΕΝ κάνει

Δεν υλοποιεί WP· δεν γράφει το Implementation Book (μόνο μετά το ρητό `ΕΓΚΡΙΝΩ SPEC
FREEZE`)· δεν κάνει freeze/qualification/merge/refactoring· δεν εισάγει παράλληλη
αρχιτεκτονική. Απόλυτο όριο: de jure αυθεντία πάντα στο Κράτος/ΦΕΚ/ΕΕ/δικαστήρια (MIS-8).
