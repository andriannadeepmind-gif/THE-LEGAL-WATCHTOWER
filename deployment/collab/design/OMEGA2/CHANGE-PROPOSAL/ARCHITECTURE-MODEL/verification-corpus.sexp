;;;; verification-corpus.sexp — the EXACT universe of everything that tests this model (Review-2 N-4, N-5, N-19).
;;;;
;;;; Before this pass the gate checked only the runners' exit codes, and the universes lived inside the runners.
;;;; The independent review showed what that permits: deleting a golden fixture reported `golden fixtures=7` and
;;;; still passed; forcing the runner to execute nothing reported `0/0 failures=0` and still passed; a committed
;;;; deletion of one held-out falsifier reported `31 … not-rejected=0` with the complete gate at `pass=20 fail=0`;
;;;; and a semantically neutral multi-line reformat silently dropped the entire public/private-leak property
;;;; family from six tests to zero while both verification paths certified an unchanged 1,439-fact commitment.
;;;;
;;;; The universe is therefore declared here, as facts, with EXACT CARDINALITIES, and the runners derive their
;;;; work from it. `gate_checks.py corpus` asserts set equality in both directions between what is declared and
;;;; what is implemented or present on disk, so a missing, extra, duplicate or renamed member is a named
;;;; failure and a shrunk universe cannot be reported as a smaller success.
;;;;
;;;; A `property-family` enumerates its cases from the MODEL, through the classified reader, never from physical
;;;; lines: `:source-module` and `:selector` say what to enumerate and `:cardinality` says exactly how many cases
;;;; that must yield. A reformat that changes the line structure of a module cannot change any of these numbers,
;;;; and a selector that silently matches nothing fails instead of reporting a smaller family.
;;;;
;;;; Every fixture and every property case is run through BOTH verification paths, and both the expected LAW and
;;;; the expected REASON are enforced on both — a rejection for the wrong law is a failure, not a pass.

;; ── golden fixtures ───────────────────────────────────────────────────────────────────────────────────────
(fact fixture FX-PASS-BASELINE :path "FIXTURES/PASS/baseline.sexp" :expect PASS :law L1
      :reason "ARCHITECTURE MODEL LAWS: PASS")
(fact fixture FX-L1-UNDECLARED-TYPE :path "FIXTURES/FAIL/l1-undeclared-type.sexp" :expect FAIL :law L1
      :reason "undeclared fact type BOGUS")
(fact fixture FX-L2-DUPLICATE-STORE :path "FIXTURES/FAIL/l2-duplicate-store.sexp" :expect FAIL :law L2
      :reason "duplicate seat STORE journal")
(fact fixture FX-L3-DANGLING-WP :path "FIXTURES/FAIL/l3-dangling-wp.sexp" :expect FAIL :law L3
      :reason "resolves to no declared wp")
(fact fixture FX-L4-PIPELINE-CYCLE :path "FIXTURES/FAIL/l4-pipeline-cycle.sexp" :expect FAIL :law L4
      :reason "cycle in the stage-edge graph over stage")
(fact fixture FX-L5-PUBLIC-PRIVATE-LEAK :path "FIXTURES/FAIL/l5-public-private-leak.sexp" :expect FAIL :law L5
      :reason "public/private leak")
(fact fixture FX-L6-SUBSYSTEM-NO-MAP :path "FIXTURES/FAIL/l6-subsystem-no-map.sexp" :expect FAIL :law L6
      :reason "has no requirement->seat->test->WP mapping")
(fact fixture FX-L7-MODULE-HASH-DRIFT :path "FIXTURES/FAIL/l7-module-hash-drift.sexp" :expect FAIL :law L7
      :reason "SHA drift")

;; ── generated property families: enumerated from the model, exact cardinality, no caps ─────────────────────
(fact property-family PF-L6-UNMAPPED-SUBSYSTEM :law L6 :cardinality 26
      :source-module "subsystems.sexp" :selector "subsystem"
      :reason "has no requirement->seat->test->WP mapping")
(fact property-family PF-L5-PRIVATE-TYPE-LEAK :law L5 :cardinality 6
      :source-module "interfaces-and-types.sexp" :selector "type:classification=PRIVATE"
      :reason "public/private leak")
(fact property-family PF-L2-DUPLICATE-STORE :law L2 :cardinality 10
      :source-module "stores-and-authorities.sexp" :selector "store"
      :reason "duplicate seat STORE")
(fact property-family PF-L3-DANGLING-SEAT :law L3 :cardinality 33
      :source-module "seats.sexp" :selector "seat"
      :reason "resolves to no declared seat")
(fact property-family PF-L4-STAGE-CYCLE :law L4 :cardinality 8
      :source-module "dependencies-and-boundaries.sexp" :selector "stage-edge"
      :reason "cycle in the stage-edge graph over stage")

;; ── universe floors: the constitutional minimum cardinality of every declared family (Review-3 R3-7) ────────
;; Coherent deletion — removing a fact and its implementation together — passed silently before these existed.
(fact universe-floor UF-FIXTURE :family fixture :minimum 8
      :rationale "one golden fixture per model law plus the passing baseline")
(fact universe-floor UF-PROPERTY-FAMILY :family property-family :minimum 5
      :rationale "one enumerated family per law that has a generable counterexample shape")
(fact universe-floor UF-FALSIFIER :family falsifier :minimum 120
      :rationale "one held-out falsifier per closed defect class across both harnesses")
(fact universe-floor UF-GEN-ARTIFACT :family gen-artifact :minimum 12
      :rationale "every derived artifact the model declares")
(fact universe-floor UF-SEAT :family seat :minimum 33
      :rationale "every seat the subsystems, stores and requirement maps refer to")
(fact universe-floor UF-TOOL :family tool :minimum 5
      :rationale "every tool on either verification path")
(fact universe-floor UF-UNIVERSE-FLOOR :family universe-floor :minimum 7
      :rationale "the constitutional self-floor: the floor set floors itself, so it cannot be deleted together with the floors it protects (Review-5 R5-1)")

;; ── the acceptance TCB: baseline AUTHORED here, measurement GENERATED in files-and-roles.sexp (Review-3 §15, Review-4 §1)
;; There is NO numeric ceiling. tcb-01 holds the exact file universe by kind, the real measurement, the per-file delta
;; against the verified baseline af0eb3c9 (17 files / 5,544 physical / 4,577 NBNC — reconciled path by path in
;; TCB-BASELINE-RECONCILIATION.md and reproduced by independent review #4 with its own counter), and the rule that every
;; growth is attributed to a reproduced finding. The total is a measured fact and a complexity signal, never the sole
;; reason for a verdict; a budget raised to meet a measurement would be a tautology, a protection removed to meet a number
;; would be the defect this gate exists to expose. After independent review #5, if it passes, the measured size becomes
;; the next observed baseline and this verifier infrastructure is locked.
(fact tcb-budget ACCEPTANCE-TCB :baseline 4577 :baseline-files 17 :baseline-physical 5544
      :baseline-commit "af0eb3c9452cdbcefa25fd457f16dd727706e7d6"
      :rule "physical = UTF-8 lines with one trailing empty element dropped; nbnc = those whose stripped form is non-empty and does not start with the kind's comment marker (; for .lisp, % for .lp, # otherwise); no other exclusion, and line packing is a defect"
      :rationale "Binding creator decision (Review-5 §6): Numeric TCB ceilings are withdrawn as pass/fail criteria. Exact TCB file-universe discovery, exact physical/NBNC measurement, historical comparison and honest per-file attribution remain mandatory. No protection, independent implementation, coverage mechanism or falsifier may be removed, weakened, packed or obscured merely to satisfy a line-count target. The baseline is the verified measurement the machinery is compared against; growth is permitted only for a reproduced counterexample or an explicitly approved architecture law, and every grown file names, per file, the finding that required it; 400 remains the design target of the Lisp path alone, never a verdict gate")
(fact tcb-baseline TB-01 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/ARCHITECTURE-MODEL-GATE.sh" :physical 147 :nbnc 94)
(fact tcb-baseline TB-02 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/CHECKER/independent_check.py" :physical 602 :nbnc 525)
(fact tcb-baseline TB-03 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/KERNEL/hash-provider.lisp" :physical 109 :nbnc 67)
(fact tcb-baseline TB-04 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp" :physical 361 :nbnc 333)
(fact tcb-baseline TB-05 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/SETUP-TOOLCHAIN.sh" :physical 115 :nbnc 70)
(fact tcb-baseline TB-06 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/SEXP-READER.py" :physical 288 :nbnc 235)
(fact tcb-baseline TB-07 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/build_decision_packet.py" :physical 237 :nbnc 180)
(fact tcb-baseline TB-08 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/build_deferred.py" :physical 258 :nbnc 218)
(fact tcb-baseline TB-09 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/build_inventory.py" :physical 329 :nbnc 280)
(fact tcb-baseline TB-10 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/build_model.py" :physical 172 :nbnc 136)
(fact tcb-baseline TB-11 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/build_root.py" :physical 99 :nbnc 78)
(fact tcb-baseline TB-12 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/gate_checks.py" :physical 977 :nbnc 853)
(fact tcb-baseline TB-13 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/generate_views.py" :physical 215 :nbnc 185)
(fact tcb-baseline TB-14 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/regenerate.py" :physical 97 :nbnc 81)
(fact tcb-baseline TB-15 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/run_falsifiers.py" :physical 928 :nbnc 741)
(fact tcb-baseline TB-16 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/run_fixtures.py" :physical 276 :nbnc 228)
(fact tcb-baseline TB-17 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/run_gate_falsifiers.py" :physical 334 :nbnc 273)
(fact tcb-attribution TA-01 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/ARCHITECTURE-MODEL-GATE.sh"
      :findings "R3-15 R3-3 R4-1 R4-3 R4-4 R4-7 R5-2 R5-P3-5 R6-2"
      :rationale "the candidate identity carried to every phase and check, the base only confirmed (R5-2); the summary names the real candidate (R5-P3-5); one command with two phases (R3-15); the pinned interpreter lifted with awk (R3-3); --base threaded to every history-bound check (R4-1); job-control signal forwarding to its own children (R4-3); GIT_OPTIONAL_LOCKS exported (R4-4); ro-02 removed as a strict subset of ro-01 (R4-7)")
(fact tcb-attribution TA-02 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/CHECKER/independent_check.py"
      :findings "R3-1"
      :rationale "its own independent AMC2 implementation")
(fact tcb-attribution TA-03 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/SEXP-READER.py"
      :findings "R3-1 R3-6 R3-3 S15-M1 R5-1 R5-P3-2 R6-1"
      :rationale "the one model read over any source, verified for history, with whole-model discovery of floors and authorizations and the one root-digest formula (R5-1); the canonical schema-version rule (R5-P3-2); the AMC2 reference implementation (R3-1), the containment seat (R3-6), the pinned-tool lookup (R3-3), the one canonical model read that replaced four copies (S15-M1)")
(fact tcb-attribution TA-04 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/acceptance_runtime.py"
      :findings "R3-8 R3-9 R3-10 R3-14 S15-TCB R4-2 R4-3 R4-4"
      :rationale "workspace lifecycle and hostile-TMPDIR refusal (R3-8), content-sensitive state (R3-9), bounded execution (R3-10), the common object store (R3-14), the one counting rule (S15-TCB), typed tool failure (R4-2), own-child registry and termination (R4-3), the one git lock policy (R4-4)")
(fact tcb-attribution TA-05 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/gate_checks.py"
      :findings "R3-2 R3-3 R3-5 R3-6 R3-7 R3-9 R3-11 R3-13 S15-TCB S15-M2 R4-1 R4-2 R4-5 R5-1 R5-2 R5-P3-1 R5-P3-2 R5-P3-5 R6-1"
      :rationale "the derived candidate/base seat and the verified whole-model historical load (R5-1, R5-2), the separated floor report (R5-P3-1), the version rule (R5-P3-2), the real candidate in provenance (R5-P3-5); provenance (R3-2), executed-identity and bootstrap declaration (R3-3), closure indeterminacy (R3-5), generation workspace (R3-6), floors (R3-7), content-state and candidate (R3-9), extension-blind artifacts (R3-11), encoding agreement (R3-13), the accountability gate (S15-TCB), dead-rule detection (S15-M2), history-bound base, authorizations and schema version (R4-1, R4-5), typed tool failure (R4-2)")
(fact tcb-attribution TA-06 :path "deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/run_corpus.py"
      :findings "S15-M1 R3-7 R3-14 R4-1 R4-2 R4-3 R5-1 R5-2 R5-P3-4 R6-1 R6-2"
      :rationale "synthetic candidate commits over coherent synthetic bases, relocation ops, the derived inner-gate base and the nine candidate/base process cases plus the two-commit reproducer (R5-1, R5-2), the permanent candidate_tree falsifier (R5-P3-4); the one runner that replaced three (S15-M1, net negative), universe integrity (R3-7), worktree-safe object store (R3-14), --base threading and base-anchored falsifier harness (R4-1), spawn-time typed falsifiers (R4-2), the concurrent-signal falsifier (R4-3)")

;; ── the two harnesses: one program each, declared so a rename cannot orphan a class of falsifiers ─────────
(fact harness COMPONENT :runner "run_corpus.py"
      :intent "each injects one defect into a disposable copy and requires the specific machinery under test to reject it for its intended named reason; run inside the gate")
(fact harness COMPOSED_GATE :runner "run_corpus.py"
      :intent "each injects one defect into a disposable copy of the whole repository and requires ARCHITECTURE-MODEL-GATE.sh itself to fail; run by the separate acceptance battery, never from inside the gate, which would recurse")

;; ── held-out falsifiers: each must be REJECTED for its intended named reason ───────────────────────────────
;; K/X entries are the corpus carried forward from the previous pass. G entries are new and, unlike every
;; falsifier before them, execute the COMPOSED `ARCHITECTURE-MODEL-GATE.sh` rather than an isolated helper —
;; the gap Review-2 N-2 identified when it showed that the falsifier written for "inventory drift erased
;; instead of compared" could not detect inventory drift being erased instead of compared.
(fact falsifier K01-GENERATED-VIEW-MISSING :harness COMPONENT :intent "a tracked generated view absent from the inventory")
(fact falsifier K02-NEW-FILE-NO-RULE :harness COMPONENT :intent "a new tracked file matching no classification rule")
(fact falsifier K03-MISSING-INVENTORY-PATH :harness COMPONENT :intent "a tracked path missing from the inventory")
(fact falsifier K04-EXTRA-INVENTORY-PATH :harness COMPONENT :intent "an inventory key that is not tracked"
      :mutation CHECK :check INVENTORY :module "files-and-roles.sexp"
      :replace-from "{NL}(fact dir-rule DR-0001" :replace-to "{NL}(fact file {Q}no/such/tracked/path.md{Q} :role AUTHORED_NORMATIVE_PROSE :rule R-027 :reason {Q}invented{Q}){NL}(fact dir-rule DR-0001" :reason "EXTRA-INVENTORY-PATH")
(fact falsifier K05-DUPLICATE-INVENTORY-KEY :harness COMPONENT :intent "the same path classified twice")
(fact falsifier K06-C-QUOTED-PATH :harness COMPONENT :intent "a non-ASCII path written as C-quoted text")
(fact falsifier K07-GREEK-FILE-OUT-OF-SCOPE :harness COMPONENT :intent "a normative Greek document classified out of scope"
      :mutation CHECK :check INVENTORY :module "files-and-roles.sexp"
      :replace-from ":role AUTHORED_NORMATIVE_PROSE :rule R-053" :replace-to ":role OUT_OF_SCOPE_WITH_REASON :rule R-053" :reason "INVENTORY-CLASSIFICATION-DRIFT")
(fact falsifier K08-MULTILINE-FACT-KEPT :harness COMPONENT :intent "a benign multi-line fact silently omitted")
(fact falsifier K09-MULTILINE-PRIVATE-LEAK :harness COMPONENT :intent "a public/private leak written across lines")
(fact falsifier K10-NEW-PINNED-MODULE :harness COMPONENT :intent "a newly pinned module ignored by one path")
(fact falsifier K11-FACT-COUNT-MISMATCH :harness COMPONENT :intent "the two paths consuming different fact counts")
(fact falsifier K12-FAMILY-DIGEST-MISMATCH :harness COMPONENT :intent "equal counts but a different per-family digest")
(fact falsifier K13-PRIVATE-TYPO :harness COMPONENT :intent "a mistyped classification value (PRIVAT)"
      :mutation REPLACE :module "interfaces-and-types.sexp"
      :replace-from ":classification PRIVATE" :replace-to ":classification PRIVAT"
      :kernel-reason "outside enum classification domain" :checker-reason "L1")
(fact falsifier K14-UNKNOWN-CONSUMER :harness COMPONENT :intent "an undeclared consumer (S99)"
      :mutation APPEND :module "dependencies-and-boundaries.sexp" :form "(fact consumes S99__HELDOUT :consumer S99 :provides ActionIntent/1)"
      :kernel-reason "resolves to no declared subsystem" :checker-reason "L3")
(fact falsifier K15-WRONG-TYPE-PROVIDES :harness COMPONENT :intent "a provides endpoint of the wrong kind"
      :mutation APPEND :module "dependencies-and-boundaries.sexp" :form "(fact consumes S01__WRONGKIND :consumer S01 :provides S02)"
      :kernel-reason ":provides = S02 resolves to no declared type" :checker-reason "L3")
(fact falsifier K16-ROOT-DIGEST-ALONE :harness COMPONENT :intent "the root digest changed without changing any pin")
(fact falsifier K17-DUPLICATE-LEDGER-ROW :harness COMPONENT :intent "a duplicated deferred-ledger row")
(fact falsifier K18-MISSING-SOURCE-FILE :harness COMPONENT :intent "an absent migration source file")
(fact falsifier K20-PACKET-UNDERCOUNT :harness COMPONENT :intent "a decision-packet total the model does not support")
(fact falsifier K21-SELF-CERTIFIED-PASS :harness COMPONENT :intent "a verdict issued without the other path present")
(fact falsifier K22-UNCONSUMED-SYNTAX :harness COMPONENT :intent "canonical-model syntax no reader consumes"
      :mutation APPEND :module "rationale-references.sexp" :form "(define-something-else extra)"
      :kernel-reason "unexpected top-level form" :checker-reason "UNCONSUMED-CANONICAL-SYNTAX")
(fact falsifier K23-READER-INJECTION :harness COMPONENT :intent "a read-time evaluation attempt in a module"
      :mutation APPEND :module "rationale-references.sexp" :form "(fact rationale INJECTED :doc #.(sb-ext:run-program {Q}/bin/true{Q} nil) :anchor {Q}x{Q})"
      :kernel-reason "unreadable model file" :checker-reason "MODEL-UNREADABLE")
(fact falsifier K24-CRLF-TEXT-HASHING :harness COMPONENT :intent "pins computed with text-decoded hashing")
(fact falsifier K25-PROVIDER-UNAVAILABLE :harness COMPONENT :intent "the vetted hash provider unavailable")
(fact falsifier X26-DEAD-RULE :harness COMPONENT :intent "a classification rule that can never fire")
(fact falsifier X27-ILLEGAL-VALUE-KIND :harness COMPONENT :intent "a value of a kind the grammar forbids"
      :mutation APPEND :module "rationale-references.sexp" :form "(fact rationale KEYWORDVALUE :doc :A-KEYWORD :anchor {Q}x{Q})"
      :kernel-reason "illegal value kind" :checker-reason "MALFORMED-FACT")
(fact falsifier X28-CONSUMER-WITHOUT-ROLE :harness COMPONENT :intent "a type consuming without a declared consumer-role"
      :mutation REPLACE :module "interfaces-and-types.sexp"
      :replace-from " :consumer-role PROPOSER" :replace-to ""
      :kernel-reason "declares no :consumer-role" :checker-reason "TYPE-CONSUMER-WITHOUT-CONSUMER-ROLE")
(fact falsifier X29-GENERATION-ORDER-CYCLE :harness COMPONENT :intent "a cycle in the declared generation order"
      :mutation APPEND :module "generation-order.sexp" :form "(fact gen-edge PACKET__DEFERRED-LEDGER :from PACKET :to DEFERRED-LEDGER)"
      :kernel-reason "cycle in the gen-edge graph over gen-step" :checker-reason "L4")
(fact falsifier X30-UNRECORDED-NORMALIZATION :harness COMPONENT :intent "a migration normalization with no ledger row")
(fact falsifier X31-HISTORICAL-ON-LIVE-PATH :harness COMPONENT :intent "historical code made a live dependency")
(fact falsifier X32-MODULE-COUNT-MISMATCH :harness COMPONENT :intent "a module count ROOT does not actually pin")
;; ── new: schema closure, seats, authority (Review-2 N-8, N-9, N-10, N-7) ───────────────────────────────────
(fact falsifier X33-UNKNOWN-FACT-FIELD :harness COMPONENT :intent "a field no fact type declares")
(fact falsifier X34-MISSPELLED-OPTIONAL-FIELD :harness COMPONENT :intent "a misspelled optional field with no downstream law")
(fact falsifier X35-WRONG-VALUE-TYPE :harness COMPONENT :intent "a declared field carrying the wrong value kind")
(fact falsifier X36-ID-SPACE-VIOLATION :harness COMPONENT :intent "an id outside its declared id-space"
      :mutation APPEND :module "subsystems.sexp" :form "(fact subsystem BADID :owner-seat SEAT-MEMORY :classification PUBLIC :migration KEEP :mission MIS-1)"
      :kernel-reason "does not start with the SUBSYSTEM-SPACE prefix" :checker-reason "ID-SPACE")
(fact falsifier X37-ROOT-EXTRA-FORM :harness COMPONENT :intent "a surplus top-level form in ROOT.sexp"
      :mutation APPEND :module "ROOT.sexp" :form "(fact seat SEAT-SMUGGLED :status BUILT :path {Q}x{Q} :note {Q}y{Q})"
      :kernel-reason "exactly one define-model-root form and nothing else" :checker-reason "ROOT-MALFORMED" :rehash NO)
(fact falsifier X38-ROOT-DUPLICATE-KEY :harness COMPONENT :intent "a duplicated plist key in ROOT.sexp"
      :mutation REPLACE :module "ROOT.sexp"
      :replace-from "  :module-count" :replace-to "  :module-count 99{NL}  :module-count"
      :kernel-reason "declares :module-count more than once" :checker-reason "ROOT-MALFORMED" :rehash NO)
(fact falsifier X39-ROOT-SCHEMA-VERSION :harness COMPONENT :intent "a schema version ROOT does not actually bind"
      :mutation REPLACE :module "ROOT.sexp"
      :replace-from ":schema-version {Q}6{Q}" :replace-to ":schema-version {Q}99{Q}"
      :kernel-reason "binds :schema-version" :checker-reason "schema-version" :rehash NO)
(fact falsifier X40-GHOST-SEAT :harness COMPONENT :intent "a seat reference resolving to no declared seat"
      :mutation REPLACE :module "subsystems.sexp"
      :replace-from ":owner-seat SEAT-MEMORY" :replace-to ":owner-seat SEAT-GHOST-DOES-NOT-EXIST"
      :kernel-reason "resolves to no declared seat" :checker-reason "L3")
(fact falsifier X41-DESIGN-TARGET-WITH-PATH :harness COMPONENT :intent "a design target dressed as a built artifact"
      :mutation REPLACE :module "seats.sexp"
      :replace-from "(fact seat SEAT-SECURITY-CELLS :status DESIGN_TARGET" :replace-to "(fact seat SEAT-SECURITY-CELLS :path {Q}CLAUDE.md{Q} :status DESIGN_TARGET"
      :kernel-reason "forbids :path" :checker-reason "CONDITIONAL-FORBIDS")
(fact falsifier X42-BUILT-SEAT-PATH-UNTRACKED :harness COMPONENT :intent "a built seat whose path is not in the candidate tree"
      :mutation CHECK :check SEATS :module "seats.sexp"
      :replace-from ":path {Q}source/memory.lisp{Q}" :replace-to ":path {Q}source/this-file-does-not-exist.lisp{Q}" :reason "SEAT-PATH-NOT-TRACKED")
(fact falsifier X43-RIVAL-STORE-WRITER :harness COMPONENT :intent "two stores claiming the same owner seat"
      :mutation APPEND :module "stores-and-authorities.sexp" :form "(fact store probe-rival :owner SEAT-JOURNAL :writer SEAT-NO-WRITER)"
      :kernel-reason "STORE-OWNER-IS-ONE-SEAT" :checker-reason "ALSO-CLAIMED-BY")
(fact falsifier X44-GLOBAL-PROMOTION-OVERCLAIM :harness COMPONENT :intent "global source-of-truth claimed while classes remain deferred")
(fact falsifier X45-CONTROL-CHARACTER-IN-STRING :harness COMPONENT :intent "a control character inside a canonical string value"
      :mutation APPEND :module "rationale-references.sexp" :form "(fact rationale CONTROLCHAR :doc {Q}line one{NL}line two{Q} :anchor {Q}x{Q})"
      :kernel-reason "illegal value kind" :checker-reason "control character")
;; ── new: composed-gate falsifiers — these run ARCHITECTURE-MODEL-GATE.sh itself ────────────────────────────
(fact falsifier G01-GATE-WRITES-TO-TREE :harness COMPOSED_GATE :intent "the validation gate modifying the tree it audits")
(fact falsifier G02-PRE-EXISTING-DRIFT-ERASED :harness COMPOSED_GATE :intent "pre-existing drift regenerated away before comparison")
(fact falsifier G03-ARTIFACT-DELETED :harness COMPOSED_GATE :intent "a declared generated artifact deleted from generator and tree")
(fact falsifier G04-ARTIFACT-UNDECLARED :harness COMPOSED_GATE :intent "an undeclared artifact produced into the seat")
(fact falsifier G05-CORPUS-SHRUNK :harness COMPOSED_GATE :intent "a fixture, property family or falsifier silently removed")
(fact falsifier G06-TOOLCHAIN-IDENTITY :harness COMPOSED_GATE :intent "a tool whose executable identity is not the pinned one")
(fact falsifier G07-UNADJUDICATED-SOURCE :harness COMPOSED_GATE :intent "a qualifying migration source absent from the ledger")
(fact falsifier G08-TMP-COLLISION :harness COMPOSED_GATE :intent "a hostile pre-existing path at a gate scratch location")

;; ── Review-3 §15: the machinery added in this pass is held out too ──────────────────────────────────────────
;; Every row below is DATA. A new defect class costs a corpus row and no code, which is the property that makes
;; "one held-out falsifier per closed defect class" affordable rather than aspirational.
(fact falsifier X54-TCB-GROWTH-UNATTRIBUTED :harness COMPONENT
      :intent "acceptance machinery grown over the baseline with no finding attributed"
      :mutation CHECK :check tcb :module "verification-corpus.sexp"
      :drop "tcb-attribution TA-05"
      :reason "TCB-GROWTH-UNATTRIBUTED")
(fact falsifier X55-TCB-FILE-UNRECORDED :harness COMPONENT
      :intent "an acceptance-machinery file with no recorded measurement"
      :mutation CHECK :check tcb :module "files-and-roles.sexp"
      :replace-from "(fact tcb-file TCB-0002 " :replace-to ";;(fact tcb-file TCB-0002 "
      :reason "TCB-UNRECORDED")
(fact falsifier X56-TCB-FILE-PHANTOM :harness COMPONENT
      :intent "a recorded measurement for a file that is not acceptance machinery"
      :mutation CHECK :check tcb :module "files-and-roles.sexp"
      :form "(fact tcb-file TCB-9999 :path {Q}deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL/no-such-machinery.py{Q} :physical 1 :nbnc 1)"
      :reason "TCB-PHANTOM")
(fact falsifier X57-DUPLICATE-CLASSIFICATION-RULE :harness COMPONENT
      :intent "the same classification-rule id declared twice"
      :mutation APPEND :module "classification-rules.sexp"
      :form "(fact classification-rule R-001 :order 900 :role GENERATED_VIEW :match {Q}prefix:zz-held-out/{Q} :reason {Q}held-out duplicate{Q})"
      :kernel-reason "DUPLICATE" :checker-reason "DUPLICATE")
(fact falsifier X58-DEAD-CLASSIFICATION-RULE :harness COMPONENT
      :intent "a classification rule in the model that can never fire"
      :mutation CHECK :check inventory :module "classification-rules.sexp"
      :form "(fact classification-rule R-900 :order 900 :role OUT_OF_SCOPE_WITH_REASON :match {Q}prefix:zz-held-out-never-tracked/{Q} :reason {Q}held-out dead rule{Q})"
      :reason "DEAD RULE")
(fact falsifier X59-PACKET-BLOCK-MISSING :harness COMPONENT
      :intent "an authored adjudication block the packet template still asks for"
      :mutation CHECK :check generation :module "PACKET-ADJUDICATION.md"
      :replace-from "<!-- BLOCK: decision -->" :replace-to "<!-- BLOCK: decision-renamed -->"
      :reason "UNKNOWN-PACKET-BLOCK")
(fact falsifier X60-PACKET-VALUE-DROPPED :harness COMPONENT
      :intent "a recomputed packet total silently dropped from the template"
      :mutation CHECK :check generation :module "PACKET-TEMPLATE.md"
      :replace-from "{{commitment-digest}}" :replace-to "(not shown)"
      :reason "UNUSED-PACKET-VALUE")

;; ── Review-4 R4-1: the universe is bound to history, and nothing in the candidate can authorise its own shrink
;; Every row is DATA. Rows with :base-* fields build a SYNTHETIC BASE — the candidate tree with those edits,
;; committed on top of the real base — so a base-anchored authorization can be exercised; {BASE-ROOT} expands to
;; the model root of the real base, which is what a valid authorization must name. Rows with :expect PASS are
;; positive controls: the guard must ACCEPT the legitimate case, or every FAIL above it would be vacuous.
(fact falsifier X61-FLOOR-LOWERED-WITH-MEMBER :harness COMPONENT
      :intent "a floor lowered and a family member removed together, with no authorization"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :drop "property-family PF-L4-STAGE-CYCLE"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X62-FLOOR-DELETED-WITH-FAMILY :harness COMPONENT
      :intent "a floor deleted together with the family it protected"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :drop "universe-floor UF-PROPERTY-FAMILY; property-family PF-L4-STAGE-CYCLE"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X63-FLOOR-RENAMED-OLD-FAMILY-GONE :harness COMPONENT
      :intent "a floor renamed to another declared family so that the base family disappears"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family harness :minimum 2"
      :drop "property-family PF-L4-STAGE-CYCLE"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X64-AUTHORIZATION-WRONG-PREVIOUS-ROOT :harness COMPONENT
      :intent "a base-anchored authorization naming the wrong previous model root"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}0000000000000000000000000000000000000000000000000000000000000000{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}0000000000000000000000000000000000000000000000000000000000000000{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X65-AUTHORIZATION-OTHER-FAMILY :harness COMPONENT
      :intent "a valid authorization for a different family used to lower this one"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-form "(fact universe-authorization UA-HELD-OUT :family fixture :previous-minimum 8 :minimum 7 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :form "(fact universe-authorization UA-HELD-OUT :family fixture :previous-minimum 8 :minimum 7 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X66-AUTHORIZATION-REPLAY :harness COMPONENT
      :intent "an authorization already spent by the base, replayed for a further reduction"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :base-replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :base-replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 3"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X67-AUTHORIZATION-CANDIDATE-INJECTED :harness COMPONENT
      :intent "an authorization written by the candidate for itself"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :reason "AUTHORIZATION-CANDIDATE-INJECTED")
(fact falsifier X68-AUTHORIZATION-VALID-CONTROL :harness COMPONENT
      :intent "a base-anchored, exactly scoped authorization honoured once (positive control)"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :expect PASS
      :reason "GATECHECK universe: PASS")
(fact falsifier X69-FLOOR-SET-WEAKENED :harness COMPONENT
      :intent "a floor removed from the floor set the base declares"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :drop "universe-floor UF-FALSIFIER"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X70-CORPUS-BELOW-EFFECTIVE-FLOOR :harness COMPONENT
      :intent "a corpus whose declarations and implementation agree, below the floor"
      :mutation CHECK :check corpus :module "verification-corpus.sexp"
      :drop "property-family PF-L4-STAGE-CYCLE"
      :reason "CORPUS-BELOW-FLOOR")

;; ── Review-4 R4-2: a tool that cannot be executed is a typed refusal, never a traceback
(fact falsifier X71-PINNED-TOOL-MISSING :harness COMPONENT
      :intent "a pinned tool absent from the host"
      :mutation CHECK :check toolchain :module "TOOLCHAIN.sexp"
      :replace-from ":path {Q}/usr/local/bin/python3{Q}" :replace-to ":path {Q}/nonexistent/host/python3{Q}"
      :reason "TOOLCHAIN-MISSING")
(fact falsifier X72-PINNED-TOOL-UNEXECUTABLE :harness COMPONENT
      :intent "a pinned tool that is a regular, non-executable file"
      :mutation CHECK :check toolchain :module "TOOLCHAIN.sexp"
      :replace-from ":path {Q}/usr/local/bin/python3{Q}" :replace-to ":path {Q}{SEAT}/ROOT.sexp{Q}"
      :reason "TOOLCHAIN-UNEXECUTABLE")
(fact falsifier X73-TOOL-VANISHES-BEFORE-SPAWN :harness COMPONENT
      :intent "a tool that passes the pre-check and vanishes before the spawn; a non-executable spawn")

;; ── Review-4 R4-5: a changed schema carries a strictly greater integer version
(fact falsifier X74-SCHEMA-CHANGED-VERSION-SAME :harness COMPONENT
      :intent "schema bytes changed against a base of the same version, version unchanged"
      :mutation CHECK :check universe :module "MODEL-SCHEMA.sexp"
      :base-form ";; the base's schema at the same version"
      :form ";; held-out schema change at the same version"
      :reason "SCHEMA-VERSION-STALE")
(fact falsifier X75-SCHEMA-CHANGED-VERSION-LOWER :harness COMPONENT
      :intent "schema bytes changed, version lowered"
      :mutation CHECK :check universe :module "MODEL-SCHEMA.sexp"
      :replace-from ":version {Q}6{Q}" :replace-to ":version {Q}5{Q}"
      :reason "SCHEMA-VERSION-STALE")
(fact falsifier X76-SCHEMA-CHANGED-VERSION-RAISED :harness COMPONENT
      :intent "schema bytes changed, version raised (positive control)"
      :mutation CHECK :check universe :module "MODEL-SCHEMA.sexp"
      :replace-from ":version {Q}6{Q}" :replace-to ":version {Q}7{Q}"
      :expect PASS
      :reason "GATECHECK universe: PASS")

;; ── Review-4 §1: the accountability gate's own data
(fact falsifier X77-ATTRIBUTION-UNKNOWN-FINDING :harness COMPONENT
      :intent "a growth attributed to a finding id the closed set does not declare"
      :mutation CHECK :check tcb :module "verification-corpus.sexp"
      :replace-from ":findings {Q}R3-1{Q}" :replace-to ":findings {Q}R9-9{Q}"
      :reason "TCB-ATTRIBUTION-UNKNOWN-FINDING")
(fact falsifier X78-BASELINE-ROWS-INCONSISTENT :harness COMPONENT
      :intent "authored baseline rows that do not sum to the recorded baseline"
      :mutation CHECK :check tcb :module "verification-corpus.sexp"
      :replace-from ":baseline 4577 :baseline-files 17" :replace-to ":baseline 4576 :baseline-files 17"
      :reason "TCB-BASELINE-INCONSISTENT")

;; ── the critical shrink cases through the REAL top-level acceptance command, and the signal falsifier
;; ── Review-5 R5-1 / R5-2 (data). Floors and authorizations discovered across the whole model, exactly one floor
;; per family, the self-floor, honest authorization attributes, the canonical schema-version rule.
(fact falsifier X79-CANDIDATE-TREE-NOT-COMMIT-ID :harness COMPONENT
      :intent "a commit-ish candidate resolves to its tree, never to the commit id (permanent, Review-5 §5.4)")
(fact falsifier X80-WORKTREE-ARBITRARY-BASE :harness COMPONENT
      :intent "an arbitrary --base for a WORKTREE candidate is refused by name")
(fact falsifier X81-COMMIT-BASE-NOT-PARENT :harness COMPONENT
      :intent "a committed candidate with a --base other than its unique parent is refused by name")
(fact falsifier X82-MERGE-CANDIDATE :harness COMPONENT
      :intent "a merge commit as candidate is refused, with and without an explicit base")
(fact falsifier X83-ORPHAN-CANDIDATE :harness COMPONENT
      :intent "a zero-parent commit as candidate is refused")
(fact falsifier X84-WORKTREE-DIFFERS-BASE-IS-HEAD :harness COMPONENT
      :intent "a working tree differing from HEAD is the candidate and HEAD is its base")
(fact falsifier X85-WORKTREE-EQUALS-HEAD-BASE-IS-PARENT :harness COMPONENT
      :intent "a working tree equal to HEAD's tree is HEAD, judged against HEAD's unique parent")
(fact falsifier X86-SHALLOW-BASE-MISSING-THEN-FETCHED :harness COMPONENT
      :intent "a depth-1 clone: a typed refusal naming the exact base object, then PASS after fetching exactly it")
(fact falsifier X87-FLOORS-REPORTED-SEPARATELY :harness COMPONENT
      :intent "base floors and candidate floors reported as distinct lines that differ when one was raised")
(fact falsifier X88-FLOORS-RELOCATED-CONTROL :harness COMPONENT
      :intent "every floor moved unchanged to another canonical module (positive control)"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :drop "universe-floor UF-FIXTURE; universe-floor UF-PROPERTY-FAMILY; universe-floor UF-FALSIFIER; universe-floor UF-GEN-ARTIFACT; universe-floor UF-SEAT; universe-floor UF-TOOL; universe-floor UF-UNIVERSE-FLOOR"
      :relocate-to "seats.sexp"
      :expect PASS
      :reason "GATECHECK universe: PASS")
(fact falsifier X89-BASE-FLOORS-RELOCATED-THEN-LOWERED :harness COMPONENT
      :intent "the base keeps its floors in another module; the candidate lowers one — discovered where the base put them"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-drop "universe-floor UF-FIXTURE; universe-floor UF-PROPERTY-FAMILY; universe-floor UF-FALSIFIER; universe-floor UF-GEN-ARTIFACT; universe-floor UF-SEAT; universe-floor UF-TOOL; universe-floor UF-UNIVERSE-FLOOR"
      :base-relocate-to "seats.sexp"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X90-SELF-FLOOR-DELETED :harness COMPONENT
      :intent "the floor that floors the floor set itself deleted"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :drop "universe-floor UF-UNIVERSE-FLOOR"
      :reason "UNIVERSE-SELF-FLOOR-MISSING")
(fact falsifier X91-DUPLICATE-FLOOR-SAME-FAMILY :harness COMPONENT
      :intent "a second floor for a family that already has one"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :form "(fact universe-floor UF-FIXTURE-AGAIN :family fixture :minimum 8 :rationale {Q}held-out duplicate{Q})"
      :reason "UNIVERSE-FLOOR-DUPLICATE")
(fact falsifier X92-AUTHORIZATION-RELOCATED-CONTROL :harness COMPONENT
      :intent "a base-anchored authorization living in another module, carried there and consumed validly (positive control)"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-module "seats.sexp"
      :base-form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :form-module "seats.sexp"
      :form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :expect PASS
      :reason "GATECHECK universe: PASS")
(fact falsifier X93-AUTHORIZATION-WRONG-PREVIOUS-MINIMUM :harness COMPONENT
      :intent "a base-anchored authorization recording a previous minimum that is not the base's floor"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 4 :minimum 3 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 4 :minimum 3 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}held-out{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 3"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier X94-AUTHORIZATION-EMPTY-APPROVER :harness COMPONENT
      :intent "a base-anchored authorization with an empty approver"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}{Q})"
      :form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}held-out{Q} :approver {Q}{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :reason "AUTHORIZATION-UNATTRIBUTED")
(fact falsifier X95-AUTHORIZATION-EMPTY-RATIONALE :harness COMPONENT
      :intent "a base-anchored authorization with an empty rationale"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}{Q} :approver {Q}held-out{Q})"
      :form "(fact universe-authorization UA-HELD-OUT :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}{Q} :approver {Q}held-out{Q})"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :reason "AUTHORIZATION-UNATTRIBUTED")
(fact falsifier X96-SCHEMA-VERSION-UNQUOTED :harness COMPONENT
      :intent "a schema version written as an unquoted integer"
      :mutation CHECK :check universe :module "MODEL-SCHEMA.sexp"
      :replace-from ":version {Q}6{Q}" :replace-to ":version 7"
      :reason "SCHEMA-VERSION-MALFORMED")
(fact falsifier X97-SCHEMA-VERSION-LEADING-ZERO :harness COMPONENT
      :intent "a schema version with a leading zero"
      :mutation CHECK :check universe :module "MODEL-SCHEMA.sexp"
      :replace-from ":version {Q}6{Q}" :replace-to ":version {Q}07{Q}"
      :reason "SCHEMA-VERSION-MALFORMED")
(fact falsifier X98-SCHEMA-VERSION-NON-ASCII-DIGIT :harness COMPONENT
      :intent "a schema version written with an Arabic-Indic digit"
      :mutation CHECK :check universe :module "MODEL-SCHEMA.sexp"
      :replace-from ":version {Q}6{Q}" :replace-to ":version {Q}٧{Q}"
      :reason "SCHEMA-VERSION-MALFORMED")
(fact falsifier X99-FLOOR-FAMILY-UNDEFINED :harness COMPONENT
      :intent "a floor for a family the schema declares nowhere"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :form "(fact universe-floor UF-GHOST :family ghost-family :minimum 1 :rationale {Q}held-out{Q})"
      :reason "UNIVERSE-FLOOR-FAMILY-UNDEFINED")
(fact falsifier X100-PROSPECTIVE-AUTHORIZATION-CONTROL :harness COMPONENT
      :intent "a well-formed prospective authorization introduced for the next edge, reducing nothing here (positive control)"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :form "(fact universe-authorization UA-NEXT-EDGE :family property-family :previous-minimum 5 :minimum 4 :previous-model-root {Q}{BASE-ROOT}{Q} :rationale {Q}for the next edge{Q} :approver {Q}held-out{Q})"
      :expect PASS
      :reason "GATECHECK universe: PASS")
(fact falsifier X101-SELF-FLOOR-LOWERED :harness COMPONENT
      :intent "the self-floor of the floor set lowered against a base that carries it"
      :mutation CHECK :check universe :module "verification-corpus.sexp"
      :base-form ";; the base carries the self-floor at 7"
      :replace-from "UF-UNIVERSE-FLOOR :family universe-floor :minimum 7" :replace-to "UF-UNIVERSE-FLOOR :family universe-floor :minimum 6"
      :reason "UNIVERSE-FLOOR-REDUCED")

(fact falsifier G09-COHERENT-SHRINK-FLOOR-LOWERED :harness COMPOSED_GATE
      :intent "the whole gate on a candidate whose floor was lowered with its family member removed"
      :mutation GATE :check uni-01-no-declared-family-below-its-floor :module "verification-corpus.sexp"
      :replace-from "UF-PROPERTY-FAMILY :family property-family :minimum 5" :replace-to "UF-PROPERTY-FAMILY :family property-family :minimum 4"
      :drop "property-family PF-L4-STAGE-CYCLE"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier G10-COHERENT-SHRINK-FLOOR-DELETED :harness COMPOSED_GATE
      :intent "the whole gate on a candidate whose floor and family were deleted together"
      :mutation GATE :check uni-01-no-declared-family-below-its-floor :module "verification-corpus.sexp"
      :drop "universe-floor UF-PROPERTY-FAMILY; property-family PF-L4-STAGE-CYCLE"
      :reason "UNIVERSE-FLOOR-REDUCED")
(fact falsifier G11-SIGNAL-CLEANS-ONLY-ITS-OWN-RESOURCES :harness COMPOSED_GATE
      :intent "SIGTERM to one of two concurrent acceptance runs: it leaves no workspace or orphan of its own, the other is unaffected, the repository is byte-identical")
(fact falsifier G12-RELOCATE-THEN-SHRINK-TWO-COMMITS :harness COMPOSED_GATE
      :intent "C1 relocates every floor to another canonical module and passes; C2 deletes five floors and shrinks the corpus coherently; judged edge by edge against C1 through the real command, C2 fails through uni-01")

;; ── Review-6 R6-1: the derived authorization lifecycle, judged edge by edge ─────────────────────────────────
;; These are CODED, not data: each one commits a real chain of edges in a throwaway object store, and no corpus
;; row can express a history. Four are positive controls: without them every refusal below would be vacuous.
(fact falsifier X116-PROSPECTIVE-REMOVAL-CONTROL :harness COMPONENT
      :intent "a prospective authorization for a full removal, reducing nothing on the edge that introduces it (positive control)")
(fact falsifier X117-AUTHORISED-REMOVAL-CONTROL :harness COMPONENT
      :intent "the next edge removing the floor and consuming the record exactly (positive control)")
(fact falsifier X118-SPENT-NOOP-EDGE-CONTROL :harness COMPONENT
      :intent "a no-op edge after an authorised removal: a terminally spent record is evidence, not a permanent refusal (positive control)")
(fact falsifier X119-SPENT-SECOND-NOOP-CONTROL :harness COMPONENT
      :intent "a second no-op edge, so the spent state is a state and not a one-off exemption (positive control)")
(fact falsifier X120-SPENT-RECORD-REMOVED :harness COMPONENT
      :intent "the spent record dropped by a later candidate")
(fact falsifier X121-SPENT-RECORD-ALTERED :harness COMPONENT
      :intent "the spent record edited by a later candidate")
(fact falsifier X122-SPENT-RECORD-REPLAYED :harness COMPONENT
      :intent "a spent record replayed for a further reduction")
(fact falsifier X123-CANDIDATE-INJECTED-SPENT-RECORD :harness COMPONENT
      :intent "a candidate writing itself a record that merely looks terminally spent")
(fact falsifier X124-NONZERO-AUTHORIZATION-UNDEFINED-FAMILY :harness COMPONENT
      :intent "a record that authorised no removal used to excuse one")
(fact falsifier X125-SPENT-FAMILY-REVIVED :harness COMPONENT
      :intent "the removed family floored again while its spent record still names it")
(fact falsifier X126-SIBLING-NO-EXTRA-AUTHORITY :harness COMPONENT
      :intent "two siblings of one authorised base gaining no authority beyond the grant itself")
(fact falsifier X127-UNAUTHORISED-REMOVAL-NOT-CURED :harness COMPONENT
      :intent "an unauthorised removal cured after the fact by a record claiming to have authorised it")

;; ── Review-6 R6-2: the informational count is model-derived, never a filename lookup ────────────────────────
(fact falsifier X128-COMPOSED-COUNT-RELOCATED :harness COMPONENT
      :intent "the informational composed count with every COMPOSED_GATE fact moved to another canonical module")
(fact falsifier X129-COMPOSED-COUNT-SPLIT :harness COMPONENT
      :intent "the informational composed count with those facts split across two canonical modules")
(fact falsifier X130-COUNT-UNREADABLE-MODEL-TYPED :harness COMPONENT
      :intent "the informational count over a malformed canonical module: the model's own typed outcome, never a traceback")
(fact falsifier X131-KIND-MODEL-READS-TYPED :harness COMPONENT
      :intent "every --kind entry point over a malformed and over an absent canonical module: typed outcome, non-zero, no traceback")
