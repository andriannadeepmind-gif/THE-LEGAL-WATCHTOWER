;;;; generation-order.sexp — the ONE declared, acyclic order in which every derived artifact of the
;;;; architecture-governance seat is produced. The gate does not carry its own private order: it topologically
;;;; sorts these facts and executes exactly the producers declared here, so the executed order and the modelled
;;;; order cannot drift apart. Acyclicity is enforced by model law L4 (every declared from/to relation over one
;;;; node type is checked), so a future edge that introduced a cycle would be a typed violation, not a hang.
;;;;
;;;; Why this order: the deferred ledger and the file inventory are *.sexp modules that ROOT.sexp hashes, so both
;;;; must be final before ROOT is computed; the generated views embed the canonical model-root digest, so they
;;;; must be produced after ROOT; the decision packet reconciles totals from the model and the views, so it is
;;;; last. Every tracked generated view — GENERATED/DEFERRED-DATA-IMPORT-VIEW.md included — is therefore produced
;;;; and present before the inventory, root and packet are read back and compared by the gate.
(fact gen-step DEFERRED-LEDGER :producer "build_deferred.py" :produces "ARCHITECTURE-MODEL/deferred-imports.sexp")
(fact gen-step INVENTORY :producer "build_inventory.py" :produces "ARCHITECTURE-MODEL/files-and-roles.sexp")
(fact gen-step ROOT :producer "build_root.py" :produces "ARCHITECTURE-MODEL/ROOT.sexp")
(fact gen-step VIEWS :producer "generate_views.py" :produces "ARCHITECTURE-MODEL/GENERATED/")
(fact gen-step PACKET :producer "build_decision_packet.py" :produces "ARCHITECTURE-MODEL/ROOT-OPERATOR-DECISION-PACKET.md")

(fact gen-edge DEFERRED-LEDGER__INVENTORY :from DEFERRED-LEDGER :to INVENTORY)
(fact gen-edge INVENTORY__ROOT :from INVENTORY :to ROOT)
(fact gen-edge ROOT__VIEWS :from ROOT :to VIEWS)
(fact gen-edge VIEWS__PACKET :from VIEWS :to PACKET)
