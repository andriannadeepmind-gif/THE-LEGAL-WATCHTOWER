;;;; systems/orchestrator-cli/builtin-commands.lisp
;;;; ============================================================================
;;;; ΟΙ ΠΡΩΗΝ-BUILTIN ΕΝΤΟΛΕΣ ΤΟΥ MAIN ΩΣ ΚΑΝΟΝΙΚΕΣ ΕΓΓΡΑΦΕΣ ΜΗΤΡΩΟΥ
;;;; ============================================================================
;;;;
;;;; Φάση 1 της διάσπασης του main (εξωτερική επιθεώρηση 05-07-2026): το main
;;;; δεν γνωρίζει πλέον ΚΑΜΙΑ εντολή — είναι σκέτος αγωγός parse → σύνταγμα →
;;;; μητρώο. Κάθε εντολή εδώ περνά από την ΙΔΙΑ συνταγματική :around όπως όλες.
;;;; ΣΗΜΕΙΩΣΗ: τα --approve/--reject ανήκουν στο self-reflection (μητρώο) — οι
;;;; παλαιοί κλάδοι τους στο main ήταν νεκρός κώδικας και ΔΕΝ μεταφέρονται.

(in-package :orchestrator.cli)

(macrolet ((reg (name &body body)
             `(register-command ,name
                                (lambda (args) (declare (ignorable args)) ,@body))))
  (reg "--help"    (print-usage) 0)
  (reg "-h"        (print-usage) 0)
  (reg "--version" (format t "Orchestrator v~A~%" *version*) 0)
  (reg "-v"        (format t "Orchestrator v~A~%" *version*) 0)
  (reg "--run-pipeline"            (run-pipeline))
  (reg "--run-all-pipelines"       (run-all-pipelines))
  (reg "--review"                  (review-list))
  (reg "--review-approve"          (review-decide :approved args))
  (reg "--review-reject"           (review-decide :rejected args))
  (reg "--serve-review"            (serve-review) 0)
  (reg "--verify-corpus"           (verify-corpus))
  (reg "--verify-all"              (verify-all-corpora))
  (reg "--verify-intelligence"     (verify-intelligence))
  (reg "--verify-all-intelligence" (verify-all-intelligence))
  (reg "--emit-proofs"             (emit-proofs))
  (reg "--emit-references"         (emit-references))
  (reg "--verify-consolidation"    (verify-all-consolidation))
  (reg "--emit-hypergraph"         (emit-hypergraph))
  (reg "--reason"                  (run-reason (first args) (second args)))
  (reg "--verify-proof"            (verify-proof))
  (reg "--serve-mcp"               (install-live-mcp-resolvers)
                                   (orchestrator.mcp:serve-mcp) 0)
  (reg "--dump-pdf-text"           (dump-pdf-text))
  (reg "--process-pdf"             (process-pdf))
  (reg "--serve"                   (serve-corpus) 0)
  (reg "--fetch-sources"           (fetch-sources))
  (reg "--fetch-pdf"               (fetch-pdf-sources))
  (reg "--materialize-pdf"         (materialize-pdf-sources))
  (reg "--auto-update"             (auto-update))
  (reg "--emit-site"               (emit-site))
  (reg "--run-tests"               (run-tests))
  (reg "--list-corpora"
       (orchestrator.spec:select-corpus)
       (orchestrator.gr-syntagma:register-active-corpus)
       (format t "Corpora: ~{~A~^, ~}~%" (orchestrator.meta:list-corpora))
       0)
  (reg "--list-pipelines"
       (orchestrator.spec:select-corpus)
       (orchestrator.gr-syntagma:register-active-corpus)
       (orchestrator.gr-syntagma:greek-constitution-pipeline)
       (format t "Pipelines: ~{~A~^, ~}~%" (orchestrator.meta:list-pipelines))
       0))
