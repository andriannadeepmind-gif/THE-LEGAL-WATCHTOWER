;;;; MODEL-SCHEMA.sexp — the model's own schema: enum domains, fact types, their id-space, required keys and
;;;; typed references. The kernel and the independent checker both READ this specification (sharing a
;;;; specification is permitted; sharing parser or invariant-evaluation code is not) and enforce it generically —
;;;; no hard-coded fact knowledge, no regex.
;;;;
;;;; Uniform fact form everywhere: (fact <type> <id> :key value ...), any number of lines.
;;;; Permitted value kinds (L1): a quoted string, an integer, or a bare plain symbol matching [A-Za-z0-9_.+/-]+.
;;;; Nothing else — no keywords, no nested lists, no NIL. A bare symbol denotes its upper-case name, so the two
;;;; verification paths agree on every value without sharing code.
;;;;
;;;; (define-enum NAME (VALUE ...))                        closed value domain; an out-of-domain value is L1
;;;; (define-fact-type NAME :id-space SPACE :required (k...)
;;;;                        :enum ((key ENUM-NAME) ...)  the key's value must lie in that enum domain
;;;;                        :ref  ((key TARGET-TYPE ...))  the key's value must be a declared id of ONE of the
;;;;                                                       listed target types — a closed reference universe
(define-model-schema architecture-model-schema :version "2"

  (define-enum classification (PUBLIC PRIVATE))
  ;; a `type` may act as a consumer ONLY when it explicitly declares a consumer-role; a type without
  ;; one is not silently treated as a consumer of unknown kind — it is a typed L5 violation.
  (define-enum consumer-role (PROPOSER))
  (define-enum file-role (CANONICAL_MODEL_INPUT GENERATED_VIEW ARCHITECTURE_DECISION AUTHORED_NORMATIVE_PROSE
                          HISTORICAL_EVIDENCE DEFERRED_PRIVATE GOVERNANCE_MACHINERY GOVERNANCE_FIXTURE
                          PRODUCTION_CODE TEST_OR_FIXTURE OUT_OF_SCOPE_WITH_REASON))
  (define-enum migration-status (IMPORTED DEFERRED_DATA_IMPORT OUT_OF_MIGRATION_SCOPE))
  (define-enum migration-batch (DDI-1 DDI-2 DDI-3 DDI-4))

  (define-fact-type file        :id-space FILE      :required (role rule reason) :enum ((role file-role)))
  (define-fact-type dir-rule    :id-space DIRRULE   :required (top role rule count reason) :enum ((role file-role)))
  (define-fact-type inventory-total :id-space INVTOTAL :required (tracked file-facts dir-rule-facts dir-rule-sum))
  (define-fact-type subsystem   :id-space SUBSYSTEM :required (owner-seat classification)
                    :enum ((classification classification)))
  (define-fact-type component   :id-space COMPONENT :required (owner-subsystem) :ref ((owner-subsystem subsystem)))
  (define-fact-type type        :id-space TYPE      :required (owner-subsystem classification)
                    :ref ((owner-subsystem subsystem))
                    :enum ((classification classification) (consumer-role consumer-role)))
  (define-fact-type store       :id-space STORE     :required (owner writer))
  (define-fact-type stage       :id-space STAGE     :required ())
  (define-fact-type stage-edge  :id-space EDGE      :required (from to) :ref ((from stage) (to stage)))
  ;; consumes: BOTH endpoints are closed. `consumer` resolves to a declared subsystem, component, or a type
  ;; that explicitly declares a consumer-role (the proposer class); `provides` resolves to a declared type. An
  ;; unknown endpoint such as S99 is a typed L3 violation — never "non-public by default".
  (define-fact-type consumes    :id-space CONSUMES  :required (consumer provides)
                    :ref ((consumer subsystem component type) (provides type)))
  (define-fact-type requirement :id-space REQUIREMENT :required ())
  (define-fact-type test        :id-space TEST      :required ())
  (define-fact-type wp          :id-space WP        :required ())
  (define-fact-type req-map     :id-space REQMAP    :required (subsystem requirement test wp)
                    :ref ((subsystem subsystem) (requirement requirement) (test test) (wp wp)))
  (define-fact-type rationale   :id-space RATIONALE :required (doc anchor))
  ;; migration-scope ledger: every v1.6-v1.8 source fact class, IMPORTED | DEFERRED_DATA_IMPORT | OUT_OF_MIGRATION_SCOPE
  (define-fact-type source-class :id-space SRCCLASS :required (source-file fact-class source-count status)
                    :enum ((status migration-status) (batch migration-batch)))
  ;; declared acyclic order in which derived artifacts are produced (gen-edge: PRODUCER must run before CONSUMER)
  (define-fact-type gen-step    :id-space GENSTEP   :required (producer produces))
  (define-fact-type gen-edge    :id-space GENEDGE   :required (from to) :ref ((from gen-step) (to gen-step))))
