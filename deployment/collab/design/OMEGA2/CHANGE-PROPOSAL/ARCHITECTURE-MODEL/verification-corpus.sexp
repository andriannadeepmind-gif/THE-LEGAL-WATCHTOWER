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

;; ── the two harnesses: one program each, declared so a rename cannot orphan a class of falsifiers ─────────
(fact harness COMPONENT :runner "run_falsifiers.py"
      :intent "each injects one defect into a disposable copy and requires the specific machinery under test to reject it for its intended named reason; run inside the gate")
(fact harness COMPOSED_GATE :runner "run_gate_falsifiers.py"
      :intent "each injects one defect into a disposable copy of the whole repository and requires ARCHITECTURE-MODEL-GATE.sh itself to fail; run by the separate acceptance battery, never from inside the gate, which would recurse")

;; ── held-out falsifiers: each must be REJECTED for its intended named reason ───────────────────────────────
;; K/X entries are the corpus carried forward from the previous pass. G entries are new and, unlike every
;; falsifier before them, execute the COMPOSED `ARCHITECTURE-MODEL-GATE.sh` rather than an isolated helper —
;; the gap Review-2 N-2 identified when it showed that the falsifier written for "inventory drift erased
;; instead of compared" could not detect inventory drift being erased instead of compared.
(fact falsifier K01-GENERATED-VIEW-MISSING :harness COMPONENT :intent "a tracked generated view absent from the inventory")
(fact falsifier K02-NEW-FILE-NO-RULE :harness COMPONENT :intent "a new tracked file matching no classification rule")
(fact falsifier K03-MISSING-INVENTORY-PATH :harness COMPONENT :intent "a tracked path missing from the inventory")
(fact falsifier K04-EXTRA-INVENTORY-PATH :harness COMPONENT :intent "an inventory key that is not tracked")
(fact falsifier K05-DUPLICATE-INVENTORY-KEY :harness COMPONENT :intent "the same path classified twice")
(fact falsifier K06-C-QUOTED-PATH :harness COMPONENT :intent "a non-ASCII path written as C-quoted text")
(fact falsifier K07-GREEK-FILE-OUT-OF-SCOPE :harness COMPONENT :intent "a normative Greek document classified out of scope")
(fact falsifier K08-MULTILINE-FACT-KEPT :harness COMPONENT :intent "a benign multi-line fact silently omitted")
(fact falsifier K09-MULTILINE-PRIVATE-LEAK :harness COMPONENT :intent "a public/private leak written across lines")
(fact falsifier K10-NEW-PINNED-MODULE :harness COMPONENT :intent "a newly pinned module ignored by one path")
(fact falsifier K11-FACT-COUNT-MISMATCH :harness COMPONENT :intent "the two paths consuming different fact counts")
(fact falsifier K12-FAMILY-DIGEST-MISMATCH :harness COMPONENT :intent "equal counts but a different per-family digest")
(fact falsifier K13-PRIVATE-TYPO :harness COMPONENT :intent "a mistyped classification value (PRIVAT)")
(fact falsifier K14-UNKNOWN-CONSUMER :harness COMPONENT :intent "an undeclared consumer (S99)")
(fact falsifier K15-WRONG-TYPE-PROVIDES :harness COMPONENT :intent "a provides endpoint of the wrong kind")
(fact falsifier K16-ROOT-DIGEST-ALONE :harness COMPONENT :intent "the root digest changed without changing any pin")
(fact falsifier K17-DUPLICATE-LEDGER-ROW :harness COMPONENT :intent "a duplicated deferred-ledger row")
(fact falsifier K18-MISSING-SOURCE-FILE :harness COMPONENT :intent "an absent migration source file")
(fact falsifier K20-PACKET-UNDERCOUNT :harness COMPONENT :intent "a decision-packet total the model does not support")
(fact falsifier K21-SELF-CERTIFIED-PASS :harness COMPONENT :intent "a verdict issued without the other path present")
(fact falsifier K22-UNCONSUMED-SYNTAX :harness COMPONENT :intent "canonical-model syntax no reader consumes")
(fact falsifier K23-READER-INJECTION :harness COMPONENT :intent "a read-time evaluation attempt in a module")
(fact falsifier K24-CRLF-TEXT-HASHING :harness COMPONENT :intent "pins computed with text-decoded hashing")
(fact falsifier K25-PROVIDER-UNAVAILABLE :harness COMPONENT :intent "the vetted hash provider unavailable")
(fact falsifier X26-DEAD-RULE :harness COMPONENT :intent "a classification rule that can never fire")
(fact falsifier X27-ILLEGAL-VALUE-KIND :harness COMPONENT :intent "a value of a kind the grammar forbids")
(fact falsifier X28-CONSUMER-WITHOUT-ROLE :harness COMPONENT :intent "a type consuming without a declared consumer-role")
(fact falsifier X29-GENERATION-ORDER-CYCLE :harness COMPONENT :intent "a cycle in the declared generation order")
(fact falsifier X30-UNRECORDED-NORMALIZATION :harness COMPONENT :intent "a migration normalization with no ledger row")
(fact falsifier X31-HISTORICAL-ON-LIVE-PATH :harness COMPONENT :intent "historical code made a live dependency")
(fact falsifier X32-MODULE-COUNT-MISMATCH :harness COMPONENT :intent "a module count ROOT does not actually pin")
;; ── new: schema closure, seats, authority (Review-2 N-8, N-9, N-10, N-7) ───────────────────────────────────
(fact falsifier X33-UNKNOWN-FACT-FIELD :harness COMPONENT :intent "a field no fact type declares")
(fact falsifier X34-MISSPELLED-OPTIONAL-FIELD :harness COMPONENT :intent "a misspelled optional field with no downstream law")
(fact falsifier X35-WRONG-VALUE-TYPE :harness COMPONENT :intent "a declared field carrying the wrong value kind")
(fact falsifier X36-ID-SPACE-VIOLATION :harness COMPONENT :intent "an id outside its declared id-space")
(fact falsifier X37-ROOT-EXTRA-FORM :harness COMPONENT :intent "a surplus top-level form in ROOT.sexp")
(fact falsifier X38-ROOT-DUPLICATE-KEY :harness COMPONENT :intent "a duplicated plist key in ROOT.sexp")
(fact falsifier X39-ROOT-SCHEMA-VERSION :harness COMPONENT :intent "a schema version ROOT does not actually bind")
(fact falsifier X40-GHOST-SEAT :harness COMPONENT :intent "a seat reference resolving to no declared seat")
(fact falsifier X41-DESIGN-TARGET-WITH-PATH :harness COMPONENT :intent "a design target dressed as a built artifact")
(fact falsifier X42-BUILT-SEAT-PATH-UNTRACKED :harness COMPONENT :intent "a built seat whose path is not in the candidate tree")
(fact falsifier X43-RIVAL-STORE-WRITER :harness COMPONENT :intent "two stores claiming the same owner seat")
(fact falsifier X44-GLOBAL-PROMOTION-OVERCLAIM :harness COMPONENT :intent "global source-of-truth claimed while classes remain deferred")
(fact falsifier X45-CONTROL-CHARACTER-IN-STRING :harness COMPONENT :intent "a control character inside a canonical string value")
;; ── new: composed-gate falsifiers — these run ARCHITECTURE-MODEL-GATE.sh itself ────────────────────────────
(fact falsifier G01-GATE-WRITES-TO-TREE :harness COMPOSED_GATE :intent "the validation gate modifying the tree it audits")
(fact falsifier G02-PRE-EXISTING-DRIFT-ERASED :harness COMPOSED_GATE :intent "pre-existing drift regenerated away before comparison")
(fact falsifier G03-ARTIFACT-DELETED :harness COMPOSED_GATE :intent "a declared generated artifact deleted from generator and tree")
(fact falsifier G04-ARTIFACT-UNDECLARED :harness COMPOSED_GATE :intent "an undeclared artifact produced into the seat")
(fact falsifier G05-CORPUS-SHRUNK :harness COMPOSED_GATE :intent "a fixture, property family or falsifier silently removed")
(fact falsifier G06-TOOLCHAIN-IDENTITY :harness COMPOSED_GATE :intent "a tool whose executable identity is not the pinned one")
(fact falsifier G07-UNADJUDICATED-SOURCE :harness COMPOSED_GATE :intent "a qualifying migration source absent from the ledger")
(fact falsifier G08-TMP-COLLISION :harness COMPOSED_GATE :intent "a hostile pre-existing path at a gate scratch location")
