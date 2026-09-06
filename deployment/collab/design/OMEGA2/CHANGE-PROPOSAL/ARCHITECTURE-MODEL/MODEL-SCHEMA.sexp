;;;; MODEL-SCHEMA.sexp — the model's own schema. Both verification paths READ this specification and enforce it
;;;; generically. Sharing a specification is permitted; sharing parser or invariant-evaluation code is not.
;;;;
;;;; Uniform fact form everywhere: (fact <type> <id> :key value ...), spanning any number of lines.
;;;; Permitted value kinds (L1): a quoted string, an integer, or a bare plain symbol matching [A-Za-z0-9_.+/-]+.
;;;; Nothing else — no keywords, no nested lists, no NIL. A bare symbol denotes its upper-case name, so the two
;;;; verification paths agree on every value without sharing code.
;;;;
;;;; CLOSED FIELD SET (Review-2 N-8). For every fact type the allowed field set is exactly
;;;;   :required  ∪  :optional
;;;; and nothing else. A key outside that set — an unknown field or a misspelled optional one — is a typed L1
;;;; violation naming the fact, the key and the permitted set. A parsed-but-ignored field is silent loss, so no
;;;; field may be parsed without being declared here.
;;;;
;;;; (define-id-space NAME :charset TOKEN|PATH [:prefix "..."] [:min N] [:max N])
;;;;     the shape every id of a fact type must satisfy, enforced on the CANONICAL RENDERING of the id.
;;;;     TOKEN = characters drawn from A-Z a-z 0-9 _ . + / - only.   PATH = any non-control character.
;;;; (define-enum NAME (VALUE ...))                     closed value domain; an out-of-domain value is L1.
;;;; (define-fact-type NAME :id-space SPACE
;;;;        :required (k ...)      keys that must be present
;;;;        :optional (k ...)      keys that may be present; required ∪ optional is the COMPLETE allowed set
;;;;        :types ((k STRING|INTEGER|SYMBOL) ...)   the permitted value kind of each declared key
;;;;        :enum  ((k ENUM-NAME) ...)               the key's value must lie in that enum domain
;;;;        :ref   ((k TARGET-TYPE ...) ...))        the key's value must be a declared id of ONE of the listed
;;;;                                                 target types — a closed reference universe
;;;; (define-conditional NAME :type T :when-key K :when-value V :require (k ...) :forbid (k ...))
;;;;     a state-dependent field rule, kept as DATA so both paths enforce one specification rather than two
;;;;     hand-written implementations: when fact type T has K = V, every key in :require must be present and
;;;;     every key in :forbid must be absent. This is what makes a DESIGN_TARGET structurally unable to carry a
;;;;     path, and a BUILT seat structurally unable to be a plan.
;;;; :canonical-encoding names the NORMATIVE fact/commitment encoding (see CANONICAL-ENCODING.md). It is
;;;;     declared here, inside the hash-pinned schema, so the encoding is bound to the schema that defines the
;;;;     fact types; every implementation refuses to issue a verdict against a version it does not implement.
;;;; (define-unique NAME :type T :field K)
;;;;     no two facts of type T may carry the same value of K. One canonical write authority per store is a
;;;;     uniqueness law, not a convention.
(define-model-schema architecture-model-schema :version "3" :canonical-encoding "AMC2"

  ;; ─────────────────────────────────────────────────────────────────── id spaces
  (define-id-space PATH-SPACE      :charset PATH  :min 1 :max 400)
  (define-id-space TOKEN-SPACE     :charset TOKEN :min 1 :max 200)
  (define-id-space SUBSYSTEM-SPACE :charset TOKEN :prefix "S" :min 2 :max 8)
  (define-id-space DIRRULE-SPACE   :charset TOKEN :prefix "DR-" :min 4 :max 16)
  (define-id-space SEAT-SPACE      :charset TOKEN :prefix "SEAT-" :min 6 :max 64)

  ;; ─────────────────────────────────────────────────────────────────── closed enums
  (define-enum classification (PUBLIC PRIVATE))
  ;; a `type` may act as a consumer ONLY when it explicitly declares a consumer-role; a type without
  ;; one is not silently treated as a consumer of unknown kind — it is a typed L5 violation.
  (define-enum consumer-role (PROPOSER))
  (define-enum migration-disposition (KEEP EXTEND DEFER_PRIVATE))
  (define-enum file-role (CANONICAL_MODEL_INPUT GENERATED_VIEW ARCHITECTURE_DECISION AUTHORED_NORMATIVE_PROSE
                          HISTORICAL_EVIDENCE DEFERRED_PRIVATE GOVERNANCE_MACHINERY GOVERNANCE_FIXTURE
                          VENDORED_DEPENDENCY PRODUCTION_CODE TEST_OR_FIXTURE OUT_OF_SCOPE_WITH_REASON
                          REVIEW_REQUIRED))
  (define-enum migration-status (IMPORTED DEFERRED_DATA_IMPORT OUT_OF_MIGRATION_SCOPE))
  (define-enum migration-batch (DDI-1 DDI-2 DDI-3 DDI-4))
  ;; Review-2 N-7. Which document is AUTHORITATIVE for the detail of a migration source class, right now.
  (define-enum fact-authority (CANONICAL_IN_MODEL AUTHORITATIVE_AT_SOURCE))
  ;; Review-2 N-10. A seat is never a fake path. Either it resolves to a tracked artifact, or its
  ;; non-existence is itself declared, with a rationale and the work packet that will build it.
  (define-enum seat-status (BUILT DOCUMENT_SEAT DESIGN_TARGET DEFERRED_PRIVATE INTERFACE_ONLY NO_WRITER))
  (define-enum artifact-kind (MODEL_MODULE GENERATED_VIEW DECISION_DOCUMENT))
  (define-enum law-id (L1 L2 L3 L4 L5 L6 L7))
  (define-enum fixture-expectation (PASS FAIL))
  (define-enum falsifier-mutation (APPEND REPLACE CHECK))
  (define-enum yes-no (YES NO))
  (define-enum tool-role (KERNEL_RUNTIME DIGEST_PROVIDER CHECKER_RUNTIME ASP_SOLVER CHECKER_DIGEST_PROVIDER))
  ;; which verification path is required to prove a tool's identity — never the tool's own self-report alone.
  (define-enum verifier (KERNEL_PATH CHECKER_PATH BOTH_PATHS))
  (define-enum promotion-scope (IMPORTED_CLASSES_ONLY GLOBAL))
  (define-enum promotion-state (PERMITTED FORBIDDEN_UNTIL_DDI_COMPLETE))

  ;; ─────────────────────────────────────────────────────────────────── inventory
  ;; ─────────────────────────────────────────────────────────────── the classification table (Review-3 §15 M2)
  ;; The rule that classifies every tracked path is DATA with one canonical seat, not a table inside the
  ;; generator. `match` is a disjunction of conjunctions over the atoms prefix:/suffix:/equals:/depth:/pattern:
  ;; (the grammar is stated in classification-rules.sexp); `order` makes first-match-wins a model property
  ;; rather than a file-order accident. A rule that matches no tracked path fails the build as dead or shadowed.
  (define-fact-type classification-rule :id-space TOKEN-SPACE
                    :required (order match role reason) :optional ()
                    :types ((order INTEGER) (match STRING) (role SYMBOL) (reason STRING))
                    :enum ((role file-role)))
  (define-fact-type file        :id-space PATH-SPACE
                    :required (role rule reason) :optional ()
                    :types ((role SYMBOL) (rule SYMBOL) (reason STRING))
                    :enum ((role file-role)))
  (define-fact-type dir-rule    :id-space DIRRULE-SPACE
                    :required (top role rule count reason) :optional ()
                    :types ((top STRING) (role SYMBOL) (rule SYMBOL) (count INTEGER) (reason STRING))
                    :enum ((role file-role)))
  (define-fact-type inventory-total :id-space TOKEN-SPACE
                    :required (tracked file-facts dir-rule-facts dir-rule-sum) :optional ()
                    :types ((tracked INTEGER) (file-facts INTEGER) (dir-rule-facts INTEGER)
                            (dir-rule-sum INTEGER)))

  ;; ─────────────────────────────────────────────────────────────── the acceptance TCB (Review-3 §15)
  ;; The MEASUREMENT is generated with the inventory, from the candidate's own bytes, by the one counting rule
  ;; in acceptance_runtime.py. The BUDGET is authored, and lives in a different module, so the program that
  ;; counts the lines is never the program that decides how many are permitted. Membership of `tcb-file` follows
  ;; from path kind and file bytes and not from any role name: re-classifying a file cannot remove it.
  ;; The id is a token, not the path: a path is already the id space of `file`, and one id may be owned by one
  ;; fact type only (law L2). The path is a field, and it is unique across the family.
  (define-fact-type tcb-file    :id-space TOKEN-SPACE
                    :required (path physical nbnc) :optional ()
                    :types ((path STRING) (physical INTEGER) (nbnc INTEGER)))
  (define-fact-type tcb-total   :id-space TOKEN-SPACE
                    :required (files physical nbnc) :optional ()
                    :types ((files INTEGER) (physical INTEGER) (nbnc INTEGER)))
  (define-fact-type tcb-budget  :id-space TOKEN-SPACE
                    :required (cap baseline baseline-files baseline-commit rule rationale) :optional ()
                    :types ((cap INTEGER) (baseline INTEGER) (baseline-files INTEGER)
                            (baseline-commit STRING) (rule STRING) (rationale STRING)))

  ;; ─────────────────────────────────────────────────────────────────── seats (N-10)
  ;; One typed seat per subsystem and per store authority. `path` is REQUIRED for BUILT and DOCUMENT_SEAT and
  ;; must be a tracked repository path; it is FORBIDDEN for the other statuses, which must instead carry the
  ;; rationale and the work packet that will produce them. This is what makes "one canonical seat" checkable.
  (define-fact-type seat        :id-space SEAT-SPACE
                    :required (status note) :optional (path rationale packet)
                    :types ((status SYMBOL) (note STRING) (path STRING) (rationale SYMBOL) (packet SYMBOL))
                    :enum ((status seat-status))
                    :ref ((rationale rationale) (packet wp)))

  ;; ─────────────────────────────────────────────────────────────────── subsystems / interfaces
  (define-fact-type subsystem   :id-space SUBSYSTEM-SPACE
                    :required (owner-seat classification migration mission) :optional ()
                    :types ((owner-seat SYMBOL) (classification SYMBOL) (migration SYMBOL) (mission SYMBOL))
                    :enum ((classification classification) (migration migration-disposition))
                    :ref ((owner-seat seat)))
  (define-fact-type component   :id-space TOKEN-SPACE
                    :required (owner-subsystem) :optional ()
                    :types ((owner-subsystem SYMBOL))
                    :ref ((owner-subsystem subsystem)))
  (define-fact-type type        :id-space TOKEN-SPACE
                    :required (owner-subsystem classification) :optional (consumer-role)
                    :types ((owner-subsystem SYMBOL) (classification SYMBOL) (consumer-role SYMBOL))
                    :ref ((owner-subsystem subsystem))
                    :enum ((classification classification) (consumer-role consumer-role)))
  ;; store: exactly one owner seat and exactly one writer seat, both typed references (N-10). A store with no
  ;; writer names the declared NO_WRITER seat explicitly — "none" as a bare word is not an answer.
  (define-fact-type store       :id-space TOKEN-SPACE
                    :required (owner writer) :optional ()
                    :types ((owner SYMBOL) (writer SYMBOL))
                    :ref ((owner seat) (writer seat)))
  (define-fact-type stage       :id-space TOKEN-SPACE :required () :optional () :types ())
  (define-fact-type stage-edge  :id-space TOKEN-SPACE
                    :required (from to) :optional ()
                    :types ((from SYMBOL) (to SYMBOL))
                    :ref ((from stage) (to stage)))
  ;; consumes: BOTH endpoints are closed. `consumer` resolves to a declared subsystem, component, or a type
  ;; that explicitly declares a consumer-role (the proposer class); `provides` resolves to a declared type. An
  ;; unknown endpoint such as S99 is a typed L3 violation — never "non-public by default".
  (define-fact-type consumes    :id-space TOKEN-SPACE
                    :required (consumer provides) :optional ()
                    :types ((consumer SYMBOL) (provides SYMBOL))
                    :ref ((consumer subsystem component type) (provides type)))

  ;; ─────────────────────────────────────────────────────────────────── traceability
  (define-fact-type requirement :id-space TOKEN-SPACE :required () :optional () :types ())
  (define-fact-type test        :id-space TOKEN-SPACE :required () :optional () :types ())
  (define-fact-type wp          :id-space TOKEN-SPACE :required () :optional () :types ())
  ;; req-map carries the SEAT (N-10): requirement -> seat -> test -> WP is only a closed chain when the seat
  ;; is part of the chain. Before this pass the claim named a link the mechanism did not contain.
  (define-fact-type req-map     :id-space TOKEN-SPACE
                    :required (subsystem seat requirement test wp) :optional ()
                    :types ((subsystem SYMBOL) (seat SYMBOL) (requirement SYMBOL) (test SYMBOL) (wp SYMBOL))
                    :ref ((subsystem subsystem) (seat seat) (requirement requirement) (test test) (wp wp)))
  (define-fact-type rationale   :id-space TOKEN-SPACE
                    :required (doc anchor) :optional ()
                    :types ((doc STRING) (anchor STRING)))

  ;; ─────────────────────────────────────────────────────────────────── migration scope + authority split (N-7)
  (define-fact-type source-class :id-space TOKEN-SPACE
                    :required (source-file fact-class source-count status authority) :optional (batch maps-to reason)
                    :types ((source-file STRING) (fact-class STRING) (source-count INTEGER) (status SYMBOL)
                            (authority SYMBOL) (batch SYMBOL) (maps-to STRING) (reason STRING))
                    :enum ((status migration-status) (batch migration-batch) (authority fact-authority)))
  ;; The single typed seat for "how far may this model be promoted". Mechanically forbids global
  ;; single-source-of-truth status while any class is still authoritative at its legacy source.
  (define-fact-type promotion   :id-space TOKEN-SPACE
                    :required (scope state reason) :optional ()
                    :types ((scope SYMBOL) (state SYMBOL) (reason STRING))
                    :enum ((scope promotion-scope) (state promotion-state)))

  ;; ─────────────────────────────────────────────────────────────────── generation universe (N-3)
  (define-fact-type gen-step    :id-space TOKEN-SPACE
                    :required (producer) :optional ()
                    :types ((producer STRING)))
  (define-fact-type gen-edge    :id-space TOKEN-SPACE
                    :required (from to) :optional ()
                    :types ((from SYMBOL) (to SYMBOL))
                    :ref ((from gen-step) (to gen-step)))
  ;; Every derived artifact is declared here individually. The generator derives its output list from these
  ;; facts, and the gate asserts exact set equality with what exists. A view that is deleted, added, renamed
  ;; or orphaned is a named failure, not a silently smaller universe.
  (define-fact-type gen-artifact :id-space TOKEN-SPACE
                    :required (step path kind) :optional ()
                    :types ((step SYMBOL) (path STRING) (kind SYMBOL))
                    :enum ((kind artifact-kind))
                    :ref ((step gen-step)))

  ;; ─────────────────────────────────────────────────────────────────── verification corpus (N-4, N-19)
  (define-fact-type fixture     :id-space TOKEN-SPACE
                    :required (path expect law reason) :optional ()
                    :types ((path STRING) (expect SYMBOL) (law SYMBOL) (reason STRING))
                    :enum ((expect fixture-expectation) (law law-id)))
  ;; A generated property family declares its law, the module it enumerates and its EXACT cardinality, so a
  ;; family that silently shrinks to zero is a failure rather than a smaller number in a log line.
  (define-fact-type property-family :id-space TOKEN-SPACE
                    :required (law source-module selector cardinality reason) :optional ()
                    :types ((law SYMBOL) (source-module STRING) (selector STRING) (cardinality INTEGER)
                            (reason STRING))
                    :enum ((law law-id)))
  ;; A harness is the ONE program that executes a class of falsifiers, declared here rather than hard-coded in
  ;; the gate, so that renaming or losing a runner is a closed-reference violation instead of a check that
  ;; quietly examines a file nobody writes any more.
  (define-fact-type harness     :id-space TOKEN-SPACE
                    :required (runner intent) :optional ()
                    :types ((runner STRING) (intent STRING)))
  ;; :harness says WHICH harness executes a falsifier, as a CLOSED REFERENCE (L3) rather than a loose enum:
  ;; COMPONENT falsifiers run inside the gate; COMPOSED_GATE falsifiers execute ARCHITECTURE-MODEL-GATE.sh
  ;; itself and are therefore run by the separate acceptance battery — a falsifier that ran the gate from
  ;; inside the gate would recurse forever (Review-2 N-2).
  ;; A falsifier whose defect is an ordinary model mutation is DATA: the module, the injected or replaced text
  ;; and the reason each path must name. The runner then carries one driver per shape instead of one function
  ;; per falsifier, so a new held-out defect costs a corpus row and no code (Review-3 §15, TCB).
  ;;   APPEND   append :form to :module; BOTH verification paths must reject, naming :kernel-reason/:checker-reason
  ;;   REPLACE  replace :replace-from with :replace-to in :module; same obligation
  ;;   CHECK    mutate :module in an exported seat and require `gate_checks.py :check` to name :reason
  ;; In :form and :replace-* the token {NL} expands to a newline and {BS} to a backslash — canonical string
  ;; values are control-character free, so a defect that IS a control character has to be written this way.
  (define-fact-type falsifier   :id-space TOKEN-SPACE
                    :required (intent harness)
                    :optional (mutation module form replace-from replace-to check reason kernel-reason
                               checker-reason rehash)
                    :types ((intent STRING) (harness SYMBOL) (mutation SYMBOL) (module STRING) (form STRING)
                            (replace-from STRING) (replace-to STRING) (check SYMBOL) (reason STRING)
                            (kernel-reason STRING) (checker-reason STRING) (rehash SYMBOL))
                    :enum ((mutation falsifier-mutation) (rehash yes-no))
                    :ref ((harness harness)))

  ;; ─────────────────────────────────────────────────────────────────── universe floors (Review-3 R3-7)
  ;; A COHERENT deletion — the fact AND its implementation removed together — used to read as a smaller success:
  ;; "4 property families totalling 75 generated cases" is a PASS line, and nothing said the universe had shrunk.
  ;; The floor is the constitutional minimum cardinality of a declared family. Going below it is a named failure;
  ;; lowering the floor itself is a model edit that must carry a universe-authorization recording who decided it,
  ;; against which model root, and why. The link to the previous root is a RECORDED ASSERTION, checked for shape
  ;; and distinctness — it is not, and is not presented as, proof that the previous root was that value.
  (define-fact-type universe-floor :id-space TOKEN-SPACE
                    :required (family minimum rationale) :optional ()
                    :types ((family SYMBOL) (minimum INTEGER) (rationale STRING)))
  (define-fact-type universe-authorization :id-space TOKEN-SPACE
                    :required (family previous-minimum minimum previous-model-root rationale approver) :optional ()
                    :types ((family SYMBOL) (previous-minimum INTEGER) (minimum INTEGER)
                            (previous-model-root STRING) (rationale STRING) (approver STRING)))

  ;; ─────────────────────────────────────────────────────────────────── toolchain identity (N-1, N-11, N-13)
  ;; Executable policy, not prose: every tool on either verification path is pinned on its semantic version
  ;; AND its exact executable digest, and each is verified by the OTHER path before any verdict is issued.
  (define-fact-type tool        :id-space TOKEN-SPACE
                    :required (role name semantic-version path sha256 verified-by note) :optional (variant)
                    :types ((role SYMBOL) (name STRING) (semantic-version STRING) (path STRING)
                            (sha256 STRING) (verified-by SYMBOL) (note STRING) (variant STRING))
                    :enum ((role tool-role) (verified-by verifier)))

  ;; ─────────────────────────────────────────────────────────────────── conditional field rules (N-10)
  ;; A seat that exists must say where; a seat that does not exist must say why and which packet will build it.
  ;; Declaring this as data is what stops the two verification paths from drifting into two different opinions.
  (define-conditional SEAT-BUILT           :type seat :when-key status :when-value BUILT
                      :require (path) :forbid (rationale packet))
  (define-conditional SEAT-DOCUMENT        :type seat :when-key status :when-value DOCUMENT_SEAT
                      :require (path) :forbid (rationale packet))
  (define-conditional SEAT-DESIGN-TARGET   :type seat :when-key status :when-value DESIGN_TARGET
                      :require (rationale packet) :forbid (path))
  (define-conditional SEAT-DEFERRED        :type seat :when-key status :when-value DEFERRED_PRIVATE
                      :require (rationale) :forbid (path packet))
  (define-conditional SEAT-INTERFACE-ONLY  :type seat :when-key status :when-value INTERFACE_ONLY
                      :require (rationale) :forbid (path packet))
  (define-conditional SEAT-NO-WRITER       :type seat :when-key status :when-value NO_WRITER
                      :require (rationale) :forbid (path packet))
  ;; Review-3 R3-12. A canonical seat path belongs to exactly ONE seat identity. Before this, two ids could claim
  ;; the same artifact and both be referenced as a writer — duplicate ownership that read as two seats. A
  ;; genuinely shared artifact must be declared as such, not arrived at by two seats quietly naming one file.
  (define-unique SEAT-PATH-UNIQUE :type seat :field path)
  ;; A deferred migration class stays authoritative at its source and must name the batch that will import it;
  ;; an imported class is canonical here and must name what it became. Neither state can be half-declared.
  (define-conditional CLASS-DEFERRED       :type source-class :when-key status :when-value DEFERRED_DATA_IMPORT
                      :require (batch authority reason) :forbid (maps-to))
  (define-conditional CLASS-IMPORTED       :type source-class :when-key status :when-value IMPORTED
                      :require (maps-to authority) :forbid (batch))
  (define-conditional CLASS-OUT-OF-SCOPE   :type source-class :when-key status :when-value OUT_OF_MIGRATION_SCOPE
                      :require (reason authority) :forbid (batch maps-to))

  ;; ─────────────────────────────────────────────────────────────────── uniqueness laws (N-10)
  (define-unique STORE-OWNER-IS-ONE-SEAT   :type store       :field owner)
  (define-unique ARTIFACT-PATH-IS-ONE-SEAT :type gen-artifact :field path)
  (define-unique FIXTURE-PATH-IS-ONE       :type fixture     :field path)
  (define-unique TCB-PATH-IS-ONE           :type tcb-file    :field path))
