# [0152] — V1.6 CORRECTIVE INTEGRATION MICRO-PASS (design-only· CANDIDATE· 9 defects closed)
**2026-09-03 · parent `3d906c2d` · frozen v1.4 baseline `88129099` (tree `a2617649`) αμετάβλητο · CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED**

Εντολή: «V1.6 CORRECTIVE INTEGRATION MICRO-PASS — NO NEW ARCHITECTURE». Η στρατηγική v1.6 κατεύθυνση γίνεται
δεκτή· η ετυμηγορία «READY FOR INDEPENDENT ADVERSARIAL REVIEW» **ΑΝΑΣΤΕΛΛΕΤΑΙ**· μία bounded, design-only
διορθωτική πάσα που κλείνει **ακριβώς 9** ελαττώματα ενοποίησης. Απαγορευμένα (τηρήθηκαν): production code,
Implementation Book update, swarm/destruction, freeze/re-freeze, WP-00, νέα αρχιτεκτονική. Δεν αγγίχθηκαν
`source/ systems/ .github/ deployment/verify/mltp3/ IMPLEMENTATION-BOOK/`· `RAW-JOURNAL`/`history.sexp`/
`output/.healthy` ανέγγιχτα· pinned v1.4 `.out` (`4873e610`) αμετάβλητο· κανένα amend/rebase/squash. Όλη η
τεκμηρίωση **grounded σε πραγματικά WP-αρχεία + κώδικα + references**, όχι σε προηγούμενες υποθέσεις.

## Τα 9 defects — before → after (evidence-grounded)
1. **WP reconciliation.** Παραγωγή actual-purpose→impact πίνακα WP-00..WP-14 (migration §2, από `WP-NN.md:5/6`)
   + `define-wp-purpose` block στο SUBSYSTEM-REGISTRY (audit source of truth). Διόρθωση κάθε λανθασμένης
   ανάθεσης: cognition **WP-06→WP-08** (Public Legal Discernment core, WP-08.md:19), TrustBundle **WP-03→WP-06**
   (WP-06.md:20), neural/proposer/model-independence **WP-02→WP-07** (WP-07.md:25 toolchain-freeze),
   DeclassificationReceipt **WP-10→WP-12** (WP-12.md:5, R-111)· επίσης S05/S06/S07/S09/S14/S17 διορθωμένα στο
   WP που κατέχει την απαίτησή τους. **Memory taxonomy → `FUTURE BOOK REVISION REQUIRED`** (καμία WP δεν την
   κατέχει· μόνη substrate-επικάλυψη = WP-03 bitemporal store) αντί ψευδο-χαρτογράφησης WP-11.
2. **ONNX/model independence.** Καταγραφή **ακριβών** FUTURE Book modifications (migration §6, πίνακας): WP-07.md:25
   toolchain-freeze «neural = Python + ONNX Runtime», WP-07.md:17, IB v1.1:118, CAP-40 (crosswalk:388),
   R-32 (matrix:65) → κάθε ένα OPTIONAL replaceable adapter (`ONNXProposerAdapter :mandatory nil`). Ο frozen
   Book/crosswalk/matrix **ΔΕΝ** τροποποιείται (rows CAP-/R-\d είναι v1.4-count-bearing). Καμία active mandatory
   αναφορά· `V6S15` (+ mutation `V6S15M`).
3. **Memory disposition rebuilt από κώδικα.** manifest §5 ξαναχτισμένο με file:line:symbol. Knowledge/ontology =
   **ξεχωριστή έδρα** (`:orchestrator.knowledge/.legal-ontology/.graph`), ΟΧΙ semantic memory. Διορθώσεις:
   PROSPECTIVE_GOALS **MISSING→EXISTING** (memory.lisp:203 `record-goal`/:226 `open-goals`/:247 `arm-intention`),
   EPISODIC **→EXISTING** (:79 `record-episode`), SEMANTIC **→PARTIAL** (:72 `%lemma-set`), META_MEMORY
   **MISSING→PARTIAL** (:167 `verify-episode-chain`), TEMPORAL **→PARTIAL** (bitemporal μόνο στο version-graph),
   USER_PREFERENCE **MISSING** (κανένα symbol).
4. **Private types out of public memory.** `MemoryEvent/1` public base = `PublicMemoryType (12) × PublicMemoryScope
   (public|user|ephemeral)` — **κανένα** `:client/:matter/:PRIVATE_CLIENT_MATTER`. Ο private τύπος → νέο
   `PrivateMemoryEvent/1` (§5 extension, `:public-dependency nil`) που καταναλώνει το public base by ref.
   `V6I-MEM-public-base-clean`.
5. **Real transitive closure.** Το manually-asserted public-build set αντικαταστάθηκε από **πραγματικό transitive
   type-closure** (`V6S12`): parse κάθε record, build `:type` graph, closure από τις public roots, assert κανένα
   `:DEFERRED_PRIVATE` record / private-bearing enum. Non-vacuity: `V6S12M` εγχέει `:type MemoryScope` (private)
   στο public root ⇒ ανιχνεύεται.
6. **LanguageCognitionLayer construction contract.** ordered stage DAG `cognition-stage-dag` (COG-1..COG-12, κάθε
   `:symbolic-only t`) + typed I/O records (`MorphLattice/1`, `PackedParseForest/1`, `CoreferenceRecord/1`,
   `DiscourseState/1`, `LegalSemanticAlternative/1`, `ClarificationState/1`, `PromotionEvidence/1`,
   `CognitionResult/1`) + `CognitionError` taxonomy + provenance + symbolic-only path (`V6I-COG-symbolic-only`).
   Κάθε `CognitionCapability` mapped **ακριβώς μία φορά** (διορθώθηκε το διπλό `CANDIDATE_TO_LEGALIR_PROMOTION`
   + χαρτογραφήθηκαν τα 4 unmapped)· `V6S14` (+ `V6S14M`).
7. **No duplicate sources of truth.** Οι υπάρχοντες canonical τύποι έγιναν `define-reference` (identity/version/seat,
   ΟΧΙ ξαναορισμός): `CandidateInterpretation/1`→neural-candidate/1, `LegalIR/1`, `ActionIntent/1`→cockpit_intent,
   `Approval/1`, `TrustBundle/1`, `DeclassificationReceipt/1`· reference-derived (`:extends`): `ToolInvocation/1`,
   `Plan/1`· genuinely-new records: PerceptionEnvelope/MemoryEvent(base)/CapabilityManifest/ExecutionReceipt/
   SafetyState. `V6S13` (record+reference ή διπλός ορισμός = REJECT).
8. **Traceability expanded.** §v1.6 από 6 umbrella σε **23 λεπτομερείς `R-V6-*` γραμμές** (6 memory + 3 adapters +
   3 safety/model + 8 cognition + 1 private + 1 real-time + 1 embodiment), κάθε μία ONE owner seat / test-falsifier /
   future-WP (διορθωμένο). Καμία v1.4 `R-\d`/`KW-`/`Q\d\d` μέτρηση δεν μεταβλήθηκε (141/69/122 αμετάβλητα).
9. **Audit strengthened to PARSE.** `V6S11` WP-assignment, `V6S12` transitive private leakage, `V6S13` duplicate
   type-def, `V6S14` cognition one-to-one, `V6S15` no mandatory model, `V6S16` orphan public root, `V6S17`
   symbolic-only reachability, `WPX` migration concept↔WP — **καθεμία non-vacuous** με inline injected-mutation
   self-test (`…M`) που ΠΡΕΠΕΙ να αναστραφεί.

## Παραδοτέα (μόνο 8 v1.6 CHANGE-PROPOSAL artifacts τροποποιημένα)
`V1.6-SCHEMAS.sexp` (references + memory split + cognition construction contract), `SUBSYSTEM-REGISTRY.sexp`
(`define-wp-purpose` + διορθωμένα `:future-wp`), `INTERFACE-AND-SCHEMA-REGISTRY.sexp` (+`CognitionResult/1`),
`IMPLEMENTATION-BOOK-MIGRATION-IMPACT-v1.6.md` (§2 evidence-grounded πίνακας + §2a memory FUTURE_BOOK + §2b/§6
ONNX future edits), `V1.6-CANDIDATE-MANIFEST.md` (§5 code-grounded memory + §6 transitive proof + §7 counts +
re-pinned hashes), `CHANGE-PROPOSAL-v1.6.md` (§4/5/6 consistency + §13 corrective summary + verdict),
`TRACEABILITY-MATRIX.md` (§v1.6 23 detailed rows), `V1.6-CONTRADICTION-OMISSION-AUDIT.sh` (V6S11-V6S17 + WPX + …M).

## Audit (τίμια ταξινομημένο)
`V1.6-CONTRADICTION-OMISSION-AUDIT.sh` = **56/56 exit 0**: A-E document/reference, F = **V6S1-V6S17 + WPX PARSE**
(paren balance, 13 contracts once as record|reference, reference closure, no dual seat, single owner,
referenced-but-undefined=0, no vendor type, transitive private-leak=0, WP-assignment resolves, duplicate-def=0,
cognition one-to-one, no mandatory model, orphan public root=0, symbolic-only complete, migration concept↔WP) —
**κάθε defect-guard με injected-mutation self-test (…M) που αναστρέφεται**· G = **v1.5 75/75 + v1.4 158/158
regressions + frozen tree `a2617649` + pinned `.out` `4873e610`**· H = migration honesty (no file move, Book not
changed). Ρητά **structural/document/duplicate-seat μόνο** — ΟΧΙ semantic/legal/security/qualification proof·
κανένα `V6Q`/`V6KW` εκτελεσμένο.

## Remaining unknowns (ρητό, πεπερασμένο)
U-1..U-8 (v1.4 §12)· όλα τα `V6Q`/`V6KW` **UNEXECUTED** (απαιτούν κώδικα)· memory taxonomy owner = **FUTURE BOOK
REVISION** (όχι υπάρχουσα WP)· WP-07 toolchain-freeze modification = future Book edit (recorded, όχι applied)·
πραγματικοί proposers/OCR/hardware external-operational· legal content `PENDING_LEGAL_VALIDATION`· measurable-corpus
cognition evidence = future qualification· private/real-time/embodiment = interfaces only.

**ΕΤΥΜΗΓΟΡΙΑ: `V1.6 INTEGRATION CORRECTED — READY FOR BOUNDED ADVERSARIAL REVIEW`.** Καμία freeze/re-freeze/
book-update/WP-00/implementation/qualification χωρίς νέα ρητή εντολή δημιουργού. Στάση.
