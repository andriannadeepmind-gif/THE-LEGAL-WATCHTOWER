# [0151] — SPEC v1.6 FUTURE-EXTENSIBILITY & PUBLIC COGNITION CLOSURE (design-only· CANDIDATE)
**2026-09-03 · parent `112379cc` · frozen v1.4 baseline `88129099` αμετάβλητο · CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED**

Εντολή: «FINAL v1.6 FUTURE-EXTENSIBILITY & PUBLIC COGNITION CLOSURE — ONE BOUNDED DESIGN-ONLY INTEGRATION
PASS». **Μία** bounded αρχιτεκτονική ενοποίηση· successor του **ίδιου** CPEI Public Observatory Profile
(καμία δεύτερη/τρίτη αρχιτεκτονική). Design/specification only· καμία production αλλαγή, κανένα WP-00, κανένα
freeze/re-freeze, καμία τροποποίηση Implementation Book, κανένα file move, κανένα destruction/swarm, καμία
qualification claim. Frozen v1.4 `88129099` (tree `a2617649`) immutable· `RAW-JOURNAL`/`history.sexp`/
`output/.healthy` ανέγγιχτα· pinned `.out` (`4873e610`) αμετάβλητο· κανένα amend/rebase/squash.

## Τι παραδόθηκε (ελάχιστο σύνολο· μία πηγή αλήθειας)
**Νέα:** `CHANGE-PROPOSAL-v1.6.md` (ενοποιημένο candidate delta), `V1.6-SCHEMAS.sexp` (19 records + 9 enums,
type-closed, 0 unresolved refs), `SUBSYSTEM-REGISTRY.sexp` (24 subsystems: 18 reused CPEI + 6 v1.6, ONE owner
έκαστο), `INTERFACE-AND-SCHEMA-REGISTRY.sexp` (24 interfaces, ONE owner+seat έκαστο),
`V1.6-CANDIDATE-MANIFEST.md`, `V1.6-CONTRADICTION-OMISSION-AUDIT.sh`, `IMPLEMENTATION-BOOK-MIGRATION-IMPACT-
v1.6.md` (report only — Book NOT changed). **Επεκτάσεις (additive, μία έδρα):** TRACEABILITY §v1.6 (6
`R-V6-*`), QUALIFICATION-TESTS §11 (V6Q/V6KW-01..18), THREAT Θ20, CROSSWALK/SUPERSEDED/Secure-Ingress/CPEI
v1.6 notes.

## Κύριες αρχιτεκτονικές κινήσεις
- **ONNX/model independence:** το «neural plane» framing → model-agnostic **`SemanticProposer`** protocol·
  ONNX = προαιρετικός `ONNXProposerAdapter` (`:mandatory nil :canonical-write-authority nil`)· OCR =
  `OCRPerceptionAdapter`· κάθε proposer παράγει μόνο typed anchored `CandidateInterpretation/1` (= ο υπάρχων
  `neural-candidate/1`) μέσω **non-evaluating** ingress· χωρίς keys/write/self-cert· score ποτέ νομική
  αλήθεια· αφαιρείται χωρίς απώλεια μνήμης/δεδομένων ⇒ **`SafetyMode :SYMBOLIC_ONLY`** (πλήρες path,
  `V6I-02/03/10`).
- **Public Language Cognition Layer (μία έδρα):** `LanguageCognitionLayer/1` **μέσα** στον υπάρχοντα Public
  Legal Discernment Engine (15 `CognitionCapability`· CLOS/condition-restart/macros/compile-time-schemas/
  package-boundaries/immutable-versioned/hot-swap· κανένα `cl:read`/eval/compile σε external bytes· καμία
  «Python-σε-Lisp»)· `legal-casegrammar.lisp` **SPLIT** general→public / client-fact→private, **καμία**
  δεύτερη υλοποίηση (`V6I-13`).
- **Πλήρης Memory Architecture (μία έδρα):** `memory.lisp` EXTEND· 13 `MemoryType` × 5 `MemoryScope`·
  projection-in/candidate-out· canonical write μόνο από write-authority· byte-verifiable continuity·
  scope isolation + `DeclassificationReceipt/1` (`V6I-05/14/15`). Coverage EXISTING/PARTIAL/MISSING στο
  manifest §5.
- **13 σταθερά καθολικά contracts** (type-closed, non-circular· reuse>new): PerceptionEnvelope/1 (new),
  CandidateInterpretation/1 (reuse neural-candidate/1), LegalIR/1 (reuse), MemoryEvent/1 (reuse+extend),
  CapabilityManifest/1 (new), ToolInvocation/1 (reuse neural-task/1), Plan/1, ActionIntent/1, Approval/1
  (reuse L12), ExecutionReceipt/1 (new), SafetyState/1 (new), TrustBundle/1 (reuse), DeclassificationReceipt/1
  (reuse). Κανένας vendor type στον πυρήνα (`V6I-11/12`).
- **Extension contracts (interfaces only):** `PrivateMatterProfile/1`, `RealTimeAssistance/1`,
  `EmbodimentInterfaces/1` — `:public-dependency nil`· public→private/embodiment ακμές ΑΠΑΓΟΡΕΥΟΝΤΑΙ·
  boundary ACYCLIC· human final authority + independent emergency stop + sim/HIL gate (`V6I-07/16`).
- **Adapter replaceability (§8):** κάθε εργαλείο φέρει `CapabilityManifest/1` (versioned iface, manifest,
  limitations, digest, provenance, conformance, golden corpus, SLO, security profile, shadow/differential/
  canary/migration/rollback/expiration, **fail-closed**)· vendor identifiers δεν εισέρχονται σε Legal IR/
  memory (`V6I-04`).
- **Μία πηγή αλήθειας:** οι δύο registries είναι source of truth· οι ανθρώπινοι πίνακες generated· ο
  architecture gate απορρίπτει orphans/dual-seats/undocumented-deps/multiple-write-owners/public→private/
  vendor-canonical/undefined-refs (`V6I-17`). Δεν μετακινείται αρχείο· ακριβές future migration map
  (`KEEP|EXTEND|SPLIT|DEFER_PRIVATE|REMOVE`) στο SUBSYSTEM-REGISTRY + migration-impact report.

## Audit (τίμια ταξινομημένο)
`V1.6-CONTRADICTION-OMISSION-AUDIT.sh` = **40/40 exit 0**: artifacts+status, ONNX/model independence,
cognition one-seat + casegrammar split, memory one-seat + boundary, extension acyclicity, structural parse
(V6S1-10: paren balance, 13 contracts defined, reference closure, no dual subsystem/interface seat, single
write owner, referenced-but-undefined=0, no vendor canonical type, no public→private leak), **v1.5 regression
(75/75) + v1.4 regression (158/158) + frozen immutability**, migration honesty (no file move, Book not
changed). Ρητά **structural/document/duplicate-seat μόνο** — **ΟΧΙ** semantic/legal/security/qualification
proof· κανένα `V6Q`/`V6KW` εκτελεσμένο.

## Δεν αγγίχτηκαν
`source/ systems/ .github/ deployment/verify/mltp3/ IMPLEMENTATION-BOOK/ (v1.0+v1.1) RAW-JOURNAL history.sexp
output/.healthy`· pinned v1.4 `.out` (4873e610)· frozen `CHANGE-PROPOSAL-v1.4.md`. Καμία production/source
αλλαγή.

## Finite unknown ledger
U-1..U-8 (v1.4 §12)· όλα τα `V6Q`/`V6KW` **UNEXECUTED**· memory types PARTIAL/MISSING (typed, μελλοντικό
WP-11)· πραγματικοί proposers/OCR/hardware/namespace authorities external-operational· legal content
`PENDING_LEGAL_VALIDATION`· measurable-corpus cognition evidence = future qualification· private/real-time/
embodiment = interfaces only.

## Regressions
v1.4 **158/158** (working tree)· v1.5 **75/75**· v1.6 **40/40** (incl. v1.4/v1.5 regressions + frozen tree
`a2617649` + pinned `.out` `4873e610`), exit 0.

**ΕΤΥΜΗΓΟΡΙΑ: `V1.6 CANDIDATE INTEGRATED — READY FOR INDEPENDENT ADVERSARIAL REVIEW`.** Καμία freeze/re-freeze/
book-update/WP-00/implementation/qualification χωρίς νέα ρητή εντολή δημιουργού. Στάση.
