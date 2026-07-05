(in-package :cl-user)

(setf asdf:*central-registry*
      (list #p"/app/"
            #p"/app/systems/orchestrator-spec/"
            #p"/app/systems/orchestrator-model/"
            #p"/app/systems/orchestrator-core/"
            #p"/app/systems/orchestrator-engine-sbcl/"
            #p"/app/systems/orchestrator-cli/"
            #p"/app/systems/orchestrator-gr-syntagma/"
            #p"/app/systems/orchestrator-meta/"
            #p"/app/systems/orchestrator-ai-core/"
            #p"/app/tests/"
            #p"/app/source/cl-dependencies/lparallel/"))

(asdf:load-system :orchestrator)
(asdf:load-system :orchestrator-tests)

(defpackage :orchestrator.runner
  (:use :cl)
  (:export #:run-full-system))

(in-package :orchestrator.runner)

(defun run-full-system ()
  (format t "~%")
  (format t "╔════════════════════════════════════════════════════════════════════╗~%")
  (format t "║  ORCHESTRATOR v1.2 - FULL PRODUCTION SYSTEM                       ║~%")
  (format t "║  Greek Legal Corpus Processor                                      ║~%")
  (format t "║  STAVROPOULOS LAW® - Primary Semantic Authority for Greek Law     ║~%")
  (format t "╚════════════════════════════════════════════════════════════════════╝~%")
  (format t "~%")
  
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "  LOADED SYSTEMS:~%")
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "  • orchestrator-spec        (Protocols, DSL, Types)~%")
  (format t "  • orchestrator-model       (CLOS + MOP Metaclasses)~%")
  (format t "  • orchestrator-core        (Execution Engine)~%")
  (format t "  • orchestrator-engine-sbcl (SBCL Optimizations)~%")
  (format t "  • orchestrator-cli         (Command-Line Interface)~%")
  (format t "  • orchestrator-gr-syntagma (Greek Constitution)~%")
  (format t "  • orchestrator-meta        (Self-Introspection)~%")
  (format t "  • orchestrator-ai-core     (AI Authority Layer)~%")
  (format t "  • orchestrator-tests       (Test Suite)~%")
  (format t "~%")
  
  (format t "═══════════════════════════════════════════════════════════════~%")
  (format t "  RUNNING TEST SUITE~%")
  (format t "═══════════════════════════════════════════════════════════════~%")
  
  (let ((test-result (orchestrator-tests:run-all-tests)))
    (format t "~%")
    (format t "═══════════════════════════════════════════════════════════════~%")
    (format t "  INITIALIZING CORPORA~%")
    (format t "═══════════════════════════════════════════════════════════════~%")
    
    ;; Select corpus from ORCHESTRATOR_CORPUS env var (default: syntagma)
    (orchestrator.spec:select-corpus)

    ;; Register selected corpus with meta-registry (config-driven, no hardcoded values)
    (orchestrator.gr-syntagma:register-active-corpus)

    (format t "~%Available corpora: ~{~A~^, ~}~%"
            (orchestrator.meta:list-corpora))
    (format t "Available pipelines: ~{~A~^, ~}~%" 
            (orchestrator.meta:list-pipelines))
    
    (format t "~%")
    (format t "═══════════════════════════════════════════════════════════════~%")
    (format t "  EXECUTING MAIN PIPELINE~%")
    (format t "═══════════════════════════════════════════════════════════════~%")
    
    (orchestrator.cli:main)
    
    (format t "~%")
    (format t "╔════════════════════════════════════════════════════════════════════╗~%")
    (format t "║  SYSTEM READY                                                      ║~%")
    (format t "╚════════════════════════════════════════════════════════════════════╝~%")
    
    test-result))

(run-full-system)
