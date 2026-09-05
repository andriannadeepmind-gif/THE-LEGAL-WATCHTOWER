;;;; generation-order.sexp — the ONE declared, acyclic order in which derived artifacts are produced, AND the
;;;; EXACT universe of what is produced (Review-2 N-3).
;;;;
;;;; Before this pass this file declared only the producers and, for the views, a DIRECTORY:
;;;;   (fact gen-step VIEWS :producer "generate_views.py" :produces "ARCHITECTURE-MODEL/GENERATED/")
;;;; The six views themselves existed nowhere but as six literal `w("...")` calls inside the generator, and no
;;;; counted check enumerated the members of GENERATED/. The independent review showed the consequences: a view
;;;; deleted from the generator and the tree passed with `pass=20 fail=0`; an undeclared extra output was
;;;; accepted; and a generator-only rename orphaned a tracked view permanently, leaving a file still stamped
;;;; "GENERATED — DO NOT EDIT" that could be hand-edited with fabricated content and committed.
;;;;
;;;; Every derived artifact is therefore declared here individually, as a `gen-artifact` fact bound to the step
;;;; that produces it. `generate_views.py` derives its output list from these facts instead of carrying its own,
;;;; and `gate_checks.py artifacts` asserts EXACT SET EQUALITY between the declared universe and what exists in
;;;; the candidate tree. Missing, extra, renamed and orphaned artifacts are each a named failure.
;;;;
;;;; Why this order: the inventory is produced first because the deferred ledger now DERIVES its migration-source
;;;; universe from the inventory's own CANONICAL_MODEL_INPUT role assignment (Review-2 N-6) rather than from a
;;;; hand-written list; both are *.sexp modules that ROOT.sexp hashes, so both must be final before ROOT; the generated views embed the canonical model-root digest, so they
;;;; must be produced after ROOT; the decision packet reconciles totals from the model and both verification
;;;; commitments, so it is last. Acyclicity is enforced by model law L4 over every declared from/to relation, so
;;;; a future edge that introduced a cycle would be a typed violation rather than a hang.
;;;;
;;;; `:path` is relative to the ARCHITECTURE-MODEL seat directory.

(fact gen-step DEFERRED-LEDGER :producer "build_deferred.py")
(fact gen-step INVENTORY       :producer "build_inventory.py")
(fact gen-step ROOT            :producer "build_root.py")
(fact gen-step VIEWS           :producer "generate_views.py")
(fact gen-step PACKET          :producer "build_decision_packet.py")

(fact gen-edge INVENTORY__DEFERRED-LEDGER :from INVENTORY       :to DEFERRED-LEDGER)
(fact gen-edge DEFERRED-LEDGER__ROOT      :from DEFERRED-LEDGER :to ROOT)
(fact gen-edge ROOT__VIEWS                :from ROOT            :to VIEWS)
(fact gen-edge VIEWS__PACKET              :from VIEWS           :to PACKET)

;; ── the exact generated-artifact universe ─────────────────────────────────────────────────────────────────
(fact gen-artifact ART-DEFERRED-LEDGER :step DEFERRED-LEDGER :kind MODEL_MODULE
      :path "deferred-imports.sexp")
(fact gen-artifact ART-INVENTORY :step INVENTORY :kind MODEL_MODULE
      :path "files-and-roles.sexp")
(fact gen-artifact ART-ROOT :step ROOT :kind MODEL_MODULE
      :path "ROOT.sexp")
(fact gen-artifact ART-VIEW-SUBSYSTEM-REGISTRY :step VIEWS :kind GENERATED_VIEW
      :path "GENERATED/SUBSYSTEM-REGISTRY-VIEW.md")
(fact gen-artifact ART-VIEW-OWNERSHIP-MATRIX :step VIEWS :kind GENERATED_VIEW
      :path "GENERATED/OWNERSHIP-MATRIX.md")
(fact gen-artifact ART-VIEW-DEPENDENCY :step VIEWS :kind GENERATED_VIEW
      :path "GENERATED/DEPENDENCY-VIEW.md")
(fact gen-artifact ART-VIEW-REQUIREMENT-TRACEABILITY :step VIEWS :kind GENERATED_VIEW
      :path "GENERATED/REQUIREMENT-TRACEABILITY-VIEW.md")
(fact gen-artifact ART-VIEW-ARCHITECTURE-CLOSURE :step VIEWS :kind GENERATED_VIEW
      :path "GENERATED/ARCHITECTURE-CLOSURE-SUMMARY.md")
(fact gen-artifact ART-VIEW-DEFERRED-DATA-IMPORT :step VIEWS :kind GENERATED_VIEW
      :path "GENERATED/DEFERRED-DATA-IMPORT-VIEW.md")
(fact gen-artifact ART-VIEW-SEAT-REGISTRY :step VIEWS :kind GENERATED_VIEW
      :path "GENERATED/SEAT-REGISTRY-VIEW.md")
(fact gen-artifact ART-VIEW-TOOLCHAIN :step VIEWS :kind GENERATED_VIEW
      :path "GENERATED/TOOLCHAIN-IDENTITY-VIEW.md")
(fact gen-artifact ART-PACKET :step PACKET :kind DECISION_DOCUMENT
      :path "ROOT-OPERATOR-DECISION-PACKET.md")
