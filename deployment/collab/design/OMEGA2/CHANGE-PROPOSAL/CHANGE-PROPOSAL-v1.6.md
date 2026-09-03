# CHANGE-PROPOSAL v1.6 — FUTURE-EXTENSIBILITY & PUBLIC COGNITION CLOSURE (CANDIDATE · NOT FROZEN)

**ΚΑΤΑΣΤΑΣΗ:** `SPEC v1.6 CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`.
**Parent** `112379cc` · **frozen v1.4 baseline** `88129099` (αμετάβλητο ιστορικό) · **successor** του ίδιου
**CPEI Public Observatory Profile v1.4**. Design/specification only· καμία production αλλαγή, κανένα WP-00,
κανένα freeze/re-freeze, καμία τροποποίηση Implementation Book, καμία δεύτερη/τρίτη αρχιτεκτονική.
Machine-readable πηγή αλήθειας: `V1.6-SCHEMAS.sexp`, `SUBSYSTEM-REGISTRY.sexp`,
`INTERFACE-AND-SCHEMA-REGISTRY.sexp`. Οι ανθρώπινοι πίνακες **παράγονται** από αυτά (`:V6I-17`).

## 0. Αποστολή (μία bounded ενοποίηση)
1. v1.4 = αμετάβλητο frozen baseline. 2. Ενσωμάτωση **όλων** των έγκυρων v1.5 repairs (D1/D2/D3/C1 + F1–F5
+ R1–R8/A-1..D-1/F7) χωρίς regression. 3. Common Lisp **Public Legal Language Cognition Layer** μέσα στον
υπάρχοντα Public Legal Discernment Engine. 4. Πλήρης **conversational memory architecture** (μία έδρα).
5. Εξάλειψη κάθε **υποχρεωτικής** εξάρτησης από ONNX/μοντέλο/cloud/runtime/provider. 6. Κλείδωμα
**extension contracts** για Private Matter Profile / real-time / embodiment. 7. Ενοποίηση διάσπαρτων
αρχείων μέσω **μοναδικών registries**. 8. Μία ενιαία `v1.6 CURRENT CANDIDATE`, έτοιμη για ανεξάρτητο
adversarial review.

## 1. Μη διαπραγματεύσιμες αρχές (κανονιστικά — `V6I-01..V6I-17`)
Κλειδώνουμε **νομικές σημασίες, invariants, interfaces — όχι εργαλεία**. Κανένα μοντέλο/ONNX/Python/cloud/
provider δεν είναι υποχρεωτικό. Πλήρες ασφαλές `SYMBOLIC_ONLY` mode. Κάθε εξωτερικό εργαλείο = replaceable
adapter χωρίς canonical write authority. Η μνήμη ανήκει στο LAWMAX. Κάθε κρίσιμο αποτέλεσμα φέρει πηγή/χρόνο/
uncertainty/proof-counterproof. Ασάφεια/άγνοια ⇒ `UNKNOWN`/`CONFLICTING`/`QUARANTINED`/ερώτηση. Public ποτέ
δεν εξαρτάται από Private/embodied· Private καταναλώνει signed public releases ή proof-carrying interfaces,
ποτέ public-store internals. Καμία αυτοβελτίωση canonical χωρίς test+authorization+journaled adoption+
rollback. Νέα τεχνολογία = adapter/capability/profile — **ποτέ** αλλαγή legal identity/Legal IR/memory/
temporality/proofs/trust boundaries. Η εγγύηση αφορά **σταθερά contracts + migration + isolation**, ΟΧΙ
γνώση του μέλλοντος (καμία αξίωση πρόβλεψης 2040).

## 2. Ενσωμάτωση v1.5 (χωρίς regression)
Όλες οι v1.5 έδρες παραμένουν κανονικές και δεσμευτικές: D1 admission (`SemanticAdmissionEvidence/1`, SA-0/1/2,
gate `SA-2-canonical-admission` με **έγκυρο** `DerivationIndependenceEvidence/1`), D2 census (frozen
`census_coverage_state {INGESTED, EXPLICITLY-ABSENT, QUARANTINED, UNKNOWN}` + total `census-coverage-decision`),
D3 independence (namespace-aware `DomainAssertion/1` + pinned `TrustedIssuerRegistry/1` + component quorum),
C1 interpretive (immutable records + detached `LifecycleRecord/1` + single `CanonPolicy/1`). Ο v1.6 audit
τρέχει τον v1.5 audit ως regression (πρέπει να μένει πράσινος).

## 3. ONNX / Model independence (κανονιστικά· `V6I-02/03/10`)
Το ONNX **αφαιρείται από κάθε mandatory architecture dependency και toolchain assumption**. Η ανώτερη μορφή:
**mandatory Common Lisp trusted language/semantic kernel** + model-agnostic **`SemanticProposer`** protocol +
**προαιρετικοί** τοπικοί/εξωτερικοί proposers + **προαιρετικό** ONNX adapter (`ONNXProposerAdapter`, μόνο αν
χρήσιμο) + **καμία επίπτωση** στην ασφαλή λειτουργία όταν όλοι οι proposers απουσιάζουν (⇒ `SafetyMode
:SYMBOLIC_ONLY`). Κάθε proposer: παράγει μόνο typed/anchored `CandidateInterpretation/1`· δεν κατέχει κλειδιά·
δεν γράφει journal/canonical state· δεν αυτοπιστοποιείται· score **ποτέ** νομική αλήθεια· περνά **αποκλειστικά**
από τον non-evaluating ingress decoder· αφαιρείται χωρίς απώλεια μνήμης/canonical data. OCR/perception επίσης
adapter-based (`OCRPerceptionAdapter`)· καμία OCR engine/runtime δεν είναι source of truth (ίδια bytes ⇒ ίδια
manifestation identity).

## 4. Public Legal Language Cognition Layer (`V6I-13` · seat **WP-08**, όχι WP-06)
**Καμία δεύτερη reasoning engine.** Προστίθεται `LanguageCognitionLayer/1` **μέσα** στον υπάρχοντα Public Legal
Discernment Engine (**WP-08 core** — WP-08.md:19 «Deliverable 6 … composition S3+S4+S6+S7+S9, no second engine»),
ως **construction contract**: ordered stage DAG (`cognition-stage-dag`, COG-1..COG-12, κάθε στάδιο `:symbolic-only t`)
πάνω σε typed I/O records (`MorphLattice/1`, `PackedParseForest/1`, `CoreferenceRecord/1`, `DiscourseState/1`,
`LegalSemanticAlternative/1`, `ClarificationState/1`, `PromotionEvidence/1`, `CognitionResult/1`, error taxonomy
`CognitionError`), κάθε `CognitionCapability` mapped **ακριβώς μία φορά** σε existing seat ή declared extension
(`V6I-COG-one-to-one`)· symbolic-only execution path πλήρες (`V6I-COG-symbolic-only`). Composition + language
front-end, επαναχρησιμοποιώντας `greek-nlp-core.lisp`,
`greek-tokenizer-advanced.lisp`, `greek-lemmatizer.lisp`, `legal-casegrammar.lisp[general]`,
`greek-legislation-ontology.lisp`, `legal-ast.lisp`, `legal-inference-engine.lisp`, `legal-deontic.lisp`,
`legal-event-calculus.lisp`, `legal-dialectic.lisp`, `legal-qa.lisp`, `legal-reasoning-bridge.lisp`, `memory.lisp`.
**`legal-casegrammar` SPLIT:** οι **γενικοί** μηχανισμοί ελληνικής μορφολογίας/case-frames/ambiguity ⇒
shared/public language layer· τα **client-fact schemas + matter-solving** ⇒ private/deferred. **Καμία
αντιγραφή δεύτερης υλοποίησης** — το private καταναλώνει το public. Οι 15 κανονιστικές δυνατότητες
(`CognitionCapability`): Unicode normalization+segmentation· reversible tokenization με spans· morphological
lattice· constraint syntax + packed forest· coreference/anaphora/discourse· inter-sentence/document linking·
legal entities/citations/terms-of-art· temporal/deontic/conditional/exception/scope semantics· multiple
`InterpretiveProfile`· `CandidateInterpretation → LegalIR` promotion· explicit ambiguity + clarification·
controlled NLG με citation/proof· multilingual extension point + controlling-text declaration· δηλωμένη
coverage + `UNKNOWN` εκτός κάλυψης· **καμία** αξίωση «τέλειας κατανόησης» χωρίς measurable corpus evidence.
**Common Lisp αξιοποίηση:** CLOS protocols/generic functions για adapters/analyzers· condition/restart για
ελεγχόμενη ασάφεια/recovery· macros/DSLs για grammar/morphology/Legal-IR/rules· compile-time schema/invariant
generation· package boundaries + forbidden dependencies· immutable/versioned internal objects·
incremental/hot-swappable analyzers μέσω capability registry· **κανένα** `cl:read`/`eval`/`macroexpand`/
`compile` πάνω σε external bytes· **καμία** «Python-σε-Lisp» υλοποίηση.

## 5. Πλήρης Memory Architecture (`V6I-05/14/15` · **PUBLIC base / PRIVATE extension split**)
**Μία μόνο έδρα μνήμης:** ο υπάρχων Memory Kernel / `memory.lisp` — **EXTEND**, καμία δεύτερη. **Public base
(defect 4):** `MemoryEvent/1` φέρει **μόνο** `PublicMemoryType × PublicMemoryScope` — 12 public types
(working/context, episodic, semantic, procedural, prospective goals, source/provenance, temporal,
argument/counterargument, uncertainty/contradiction, user-preference, skill/capability, meta-memory) × 3 public
scopes (`public | user | ephemeral`). **Κανένας private τύπος/scope (client/matter/`PRIVATE_CLIENT_MATTER`) στο
public hash-bearing contract** — verified ως transitive type-closure (`V6S12`, `V6I-MEM-public-base-clean`). Ο
private τύπος ζει στο `PrivateMemoryEvent/1` (§5 extension, `:public-dependency nil`), που **καταναλώνει** το
public base by ref, ποτέ αντίστροφα. `MemoryPolicy/1`: retention, forgetting, consolidation, explainable recall,
correction/supersession, scope isolation. **Κανένα μοντέλο** δεν κατέχει/τροποποιεί μνήμη — λαμβάνει
`MemoryProjection/1` (scoped) και επιστρέφει `CandidateInterpretation/1`· canonical `MemoryEvent/1` γράφεται
**μόνο** από την authorized write authority. Αντικατάσταση μοντέλου ⇒ **byte-verifiable memory continuity**.
Πλήρης κάλυψη (EXISTING/PARTIAL/MISSING, με file:line:symbol) στο `V1.6-CANDIDATE-MANIFEST.md §5`: PROSPECTIVE_GOALS/
EPISODIC **EXISTING** (memory.lisp record-goal/arm-intention/record-episode)· knowledge/ontology είναι **ξεχωριστή
έδρα**, όχι semantic memory. **Η 13-type taxonomy δεν έχει owning WP** ⇒ `FUTURE BOOK REVISION REQUIRED` (μόνη
substrate-επικάλυψη = WP-03 bitemporal store)· **όχι** WP-11.

## 6. Σταθερά καθολικά contracts (§6 · `V6I-11/12/REF`)
13 versioned contracts, type-closed & non-circular (`V1.6-SCHEMAS.sexp §2`). **Μία πηγή αλήθειας (defect 7):**
οι υπάρχοντες canonical τύποι **REFERENCED** by identity/version (`define-reference`) — **ΔΕΝ** ξαναορίζονται σε
απλοποιημένη v1.6 μορφή: `CandidateInterpretation/1` → `neural-candidate/1`, `LegalIR/1` → legal-ast/LEGAL-IR-
SEMANTIC-CONTRACT, `ActionIntent/1` → `cockpit_intent`, `Approval/1` → approval-policy (L12), `TrustBundle/1` →
MLTP LocalTrustState, `DeclassificationReceipt/1` → declassification gateway. **Genuinely-new records**
(`define-record`): `PerceptionEnvelope/1`, `MemoryEvent/1` (public base πάνω στη memory.lisp substrate),
`CapabilityManifest/1`, `ExecutionReceipt/1`, `SafetyState/1`. **Reference-derived** (`:extends` canonical seat,
προσθέτει μόνο v1.6 fields): `ToolInvocation/1` (`neural-task/1`), `Plan/1` (`cockpit_intent`). Ένας τύπος
ορισμένος **και** ως record **και** ως reference (ή δύο φορές) = duplicate source of truth ⇒ **REJECT** (`V6S13`).
**Κανένας vendor type** στον πυρήνα Legal IR/memory — adapter-specific δεδομένα ζουν μόνο σε
`CapabilityManifest`/`PerceptionEnvelope` και normalize πριν κάθε canonical write.

## 7. Μελλοντικό Private / Real-time / Embodiment boundary (`V6I-07/16`)
**Interfaces ONLY** — δεν υλοποιείται ιδιωτικό σύστημα/ακουστικό/ρομπότ. `PrivateMatterProfile/1`,
`RealTimeAssistance/1`, `EmbodimentInterfaces/1` (`V1.6-SCHEMAS.sexp §5`) είναι extension contracts,
`:status :DEFERRED_PRIVATE`, `:public-dependency nil`. Public → private/embodiment ακμές **ΑΠΑΓΟΡΕΥΟΝΤΑΙ**·
το boundary είναι **ακυκλικό**. High-risk νομική/φυσική ενέργεια απαιτεί προηγούμενο `Approval/1`·
independent emergency stop + sim/HIL gate πριν από embodiment action· human final authority.

## 8. Αντικαταστασιμότητα όλων των εργαλείων (`V6I-04` · §8)
Κάθε replaceable adapter φέρει `CapabilityManifest/1`: versioned interface, capability manifest, declared
limitations, runtime/build digest, provenance, conformance suite, golden corpus, quality/SLO, security
profile, shadow mode, differential comparison, canary promotion, migration, rollback, expiration/deprecation,
**fail-closed** behaviour. Καλύπτει OCR, language proposers, search/index, graph/database, object storage,
queue, cryptographic backend, timestamp provider, API transport, UI, μελλοντικές συσκευές. **Vendor-specific
identifiers/formats ΔΕΝ εισέρχονται** στο canonical Legal IR ή στη μνήμη.

## 9. Repository order — μία πηγή αλήθειας (`V6I-17`)
Καθιερώνονται: `CURRENT-ARCHITECTURE-MANIFEST` (= `V1.6-CANDIDATE-MANIFEST.md`), `SUBSYSTEM-REGISTRY.sexp`,
`INTERFACE-AND-SCHEMA-REGISTRY.sexp`, `DATA-OWNERSHIP-MATRIX` (owners στο SUBSYSTEM-REGISTRY),
canonical `DEPENDENCY-GRAPH` + `SECURITY-BOUNDARY-MAP` (v1.6 §6 acyclic + v1.4 §4.14/§4.22),
`REQUIREMENT-TRACEABILITY` (TRACEABILITY-MATRIX §v1.6), architecture-decision registry (§11 rationale εδώ),
`QUALIFICATION-PLAN` (PUBLIC-OBSERVATORY-QUALIFICATION-TESTS §v1.6), `MIGRATION-AND-ROLLBACK`
(SUBSYSTEM-REGISTRY dispositions + migration map), classification `NORMATIVE|GENERATED|INFORMATIVE|
HISTORICAL|EVIDENCE`. Ο architecture gate απορρίπτει: orphan files/symbols, dual seats, undocumented deps,
multiple write owners, public→private deps, adapter-specific canonical types, referenced-but-undefined
contracts, duplicated normative statements. **Δεν μετακινούνται αρχεία τώρα** — παραδίδεται ακριβές future
migration map (`KEEP|EXTEND|SPLIT|MOVE|DEFER_PRIVATE|REMOVE`) στο `SUBSYSTEM-REGISTRY.sexp` +
`IMPLEMENTATION-BOOK-MIGRATION-IMPACT-v1.6.md`.

## 10. Προδηλωμένα tests / falsifiers (UNEXECUTED — απαιτούν κώδικα)
`V6Q-01..V6Q-18` + kill witnesses `V6KW-01..V6KW-18` (PUBLIC-OBSERVATORY-QUALIFICATION-TESTS §v1.6):
①ONNX+proposers removed ⇒ symbolic public works· ②model change ⇒ no memory loss/change· ③OCR change ⇒ same
manifestation identity for same bytes, typed divergence for different extraction· ④DB/store change ⇒ full
export/import με ισοδύναμες ρίζες· ⑤malicious proposer ⇒ no canonical write· ⑥two proposers disagree ⇒
alternatives/UNKNOWN/quarantine· ⑦cloud outage ⇒ safe offline/degraded· ⑧schema migration ⇒ forward/backward
+ rollback· ⑨public-only build ⇒ zero private/embodiment dep· ⑩private read of public law ⇒ only via signed
release/proof-carrying· ⑪private datum in public flow ⇒ blocked χωρίς valid declassification receipt·
⑫model replacement ⇒ capability negotiation χωρίς core edit· ⑬new sensor/robot adapter ⇒ no Legal-IR/memory/
trust change· ⑭language ambiguity/negation/exceptions/anaphora/long sentences/historical Greek/EU-Greek cross-
refs· ⑮memory correction/forgetting/supersession/scope-leakage/hostile retrieval· ⑯external bytes reader/eval/
compile ⇒ structural rejection· ⑰adapter downgrade + expired manifest ⇒ rejection· ⑱self-improvement self-
authorization ⇒ rejection. **Τα consistency audits δηλώνονται έντιμα ως structural/document checks — ΟΧΙ
semantic/legal/security/qualification proof.**

## 11. Architecture Decision rationale (registry)
- **AD-V6-1:** «lock meanings not tools» ⇒ όλα τα εργαλεία adapters· η ανθεκτικότητα στο μέλλον = σταθερά
  contracts + migration + isolation, όχι πρόβλεψη τεχνολογίας.
- **AD-V6-2:** ONNX/model demoted σε optional adapter· ο πυρήνας είναι το Common Lisp symbolic kernel· η
  ασφάλεια δεν εξαρτάται από κανέναν proposer (SYMBOLIC_ONLY complete path).
- **AD-V6-3:** μία memory έδρα (memory.lisp EXTEND)· model boundary = projection-in / candidate-out.
- **AD-V6-4:** μία cognition έδρα μέσα στον υπάρχοντα engine· casegrammar SPLIT γενικό/ιδιωτικό, καμία διπλή
  υλοποίηση.
- **AD-V6-5:** extension contracts (private/real-time/embodiment) = interfaces only, ποτέ public deps·
  ακυκλικό boundary· human final authority + emergency stop + sim/HIL.
- **AD-V6-6:** registries = μία πηγή αλήθειας· ανθρώπινοι πίνακες generated· architecture gate rejects
  orphans/dual-seats/public→private/vendor-canonical/undefined-refs/dup-normative.

## 12. STATUS
`SPEC v1.6 CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`. No freeze/re-freeze, no
Implementation Book update, no WP-00, no implementation, no qualification claim, χωρίς νέα ρητή εντολή
δημιουργού. Η προηγούμενη ετυμηγορία «READY FOR INDEPENDENT ADVERSARIAL REVIEW» είναι **ΑΝΑΣΤΑΛΜΕΝΗ**·
εκτελέστηκε μία bounded corrective integration micro-pass ([0152]) που έκλεισε 9 defects (§13).
`V1.6 INTEGRATION CORRECTED — READY FOR BOUNDED ADVERSARIAL REVIEW` (υπό τα predeclared, UNEXECUTED tests
και τα finite unknowns του manifest· τα consistency audits είναι structural/document checks, όχι semantic/
legal/security/qualification proof).

## 13. Corrective integration micro-pass [0152] — 9 defects closed (design-only)
1. **WP reconciliation:** actual-purpose→impact πίνακας WP-00..WP-14 (migration §2, `define-wp-purpose` στο
   SUBSYSTEM-REGISTRY)· διόρθωση cognition→**WP-08**, TrustBundle→**WP-06**, neural/model→**WP-07**,
   DeclassificationReceipt→**WP-12**· memory taxonomy = `FUTURE_BOOK_REVISION` (καμία WP)· parse-check `WPX`.
2. **ONNX/model independence:** ακριβείς FUTURE Book modifications (migration §6: WP-07.md:25/17, v1.1:118,
   CAP-40, R-32) ώστε κάθε proposer = optional replaceable adapter· ο frozen Book **δεν** αλλάζει· `V6S15`.
3. **Memory disposition:** manifest §5 ξαναχτισμένο από πραγματικό κώδικα (file:line:symbol)· knowledge/ontology
   ≠ semantic memory· PROSPECTIVE_GOALS/EPISODIC **EXISTING**.
4. **Private types out of public memory:** `MemoryEvent/1` public base = `PublicMemoryType × PublicMemoryScope`·
   private → `PrivateMemoryEvent/1` (`:public-dependency nil`)· `V6I-MEM-public-base-clean`.
5. **Transitive closure:** το manual public-build set αντικαταστάθηκε από real transitive type-closure (`V6S12`
   + injected-mutation self-test `V6S12M`).
6. **LanguageCognitionLayer construction contract:** stage DAG COG-1..12 (`:symbolic-only t`), typed I/O records,
   error taxonomy, clarification state machine, promotion evidence, one-to-one capability→seat (`V6S14`).
7. **No duplicate sources of truth:** existing canonical types → `define-reference` (identity/version)· `V6S13`.
8. **Traceability:** §v1.6 επεκτάθηκε από 6 umbrella σε 23 λεπτομερείς `R-V6-*` γραμμές (owner/test/future-WP).
9. **Audit strengthened to PARSE:** `V6S11-V6S17` + `WPX`, καθεμία non-vacuous με injected-mutation self-test
   (`…M`). Audit = **56/56 exit 0**· v1.5 **75/75**· v1.4 **158/158** regressions πράσινα.
