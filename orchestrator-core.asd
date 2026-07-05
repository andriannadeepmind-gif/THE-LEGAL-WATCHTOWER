;;;; orchestrator-core.asd
;;;; ASDF System Definition for Orchestrator Core Execution Engine
;;;; Dependency-driven execution engine

(asdf:defsystem #:orchestrator-core
  :description "Dependency-driven execution engine for Greek Legal Corpus Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "0.9.0"
  :homepage "https://stavropouloslaw.com"

  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-infrastructure  ; Required for orchestrator.time package
               #:alexandria
               #:bordeaux-threads
               #:lparallel           ; Parallel execution (used in parallel-executor.lisp)
               #:log4cl)             ; Logging (used in executor.lisp via :log package)

  :serial t
  :components
  ((:module "systems/orchestrator-core"
    :components
    ((:file "package")
     (:file "context")
     (:file "dependency-graph")
     (:file "executor")
     (:file "parallel-executor")
     (:file "artifact-cache")
     (:file "instrumentation")
     (:file "source-detection")))))

