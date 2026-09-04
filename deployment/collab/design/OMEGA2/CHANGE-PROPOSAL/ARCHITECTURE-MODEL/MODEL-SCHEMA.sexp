;;;; MODEL-SCHEMA.sexp — the model's own schema: fact types, their id-space, required keys and typed references.
;;;; The kernel reads this to check well-formedness (L1) and closed typed references (L3) generically — no
;;;; hard-coded fact knowledge, no regex. Uniform fact form everywhere: (fact <type> <id> :key value ...).
(define-model-schema architecture-model-schema :version "1"
  ;; (define-fact-type NAME :id-space SPACE :required (k...) :ref ((key . TARGET-TYPE) ...))
  (define-fact-type file        :id-space FILE      :required (role))
  (define-fact-type dir-rule    :id-space DIRRULE   :required (role count))
  (define-fact-type subsystem   :id-space SUBSYSTEM :required (owner-seat classification))
  (define-fact-type component   :id-space COMPONENT :required (owner-subsystem) :ref ((owner-subsystem . subsystem)))
  (define-fact-type type        :id-space TYPE      :required (owner-subsystem classification) :ref ((owner-subsystem . subsystem)))
  (define-fact-type store       :id-space STORE     :required (owner writer))
  (define-fact-type stage       :id-space STAGE     :required ())
  (define-fact-type stage-edge  :id-space EDGE      :required (from to) :ref ((from . stage) (to . stage)))
  (define-fact-type consumes    :id-space CONSUMES  :required (consumer provides) :ref ((provides . type)))
  (define-fact-type requirement :id-space REQUIREMENT :required ())
  (define-fact-type test        :id-space TEST      :required ())
  (define-fact-type wp          :id-space WP        :required ())
  (define-fact-type req-map     :id-space REQMAP    :required (subsystem requirement test wp)
                    :ref ((subsystem . subsystem) (requirement . requirement) (test . test) (wp . wp)))
  (define-fact-type rationale   :id-space RATIONALE :required (doc anchor))
  ;; migration-scope ledger: every v1.6-v1.8 source fact class, IMPORTED | DEFERRED_DATA_IMPORT | OUT_OF_MIGRATION_SCOPE
  (define-fact-type source-class :id-space SRCCLASS :required (source-file fact-class source-count status)))
