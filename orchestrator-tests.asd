;;;; orchestrator-tests.asd
;;;; ASDF System Definition for Orchestrator Test Suite
;;;; Comprehensive test suite using FiveAM only

(asdf:defsystem #:orchestrator-tests
  :description "Comprehensive test suite for Greek Legal Corpus Orchestrator (FiveAM only)"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "0.9.1"
  :homepage "https://stavropouloslaw.com"
  
  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-core
               #:orchestrator-engine-sbcl
               #:orchestrator-gr-syntagma
               #:orchestrator-ai-core       ; NEW: For AI layer tests
               #:orchestrator-meta          ; NEW: For registry access in integration tests
               #:orchestrator-cli           ; NEW: For CLI command tests
               #:fiveam
               #:jonathan                   ; NEW: For JSON parsing in tests
               #:alexandria)                ; NEW: For file utilities in tests
  
  :serial nil
  :components
  ((:module "systems/orchestrator-tests"
    :components
    ((:file "package")
     (:file "suite" :depends-on ("package"))
     (:module "fixtures"
      :depends-on ("package")
      :components
      ((:file "test-articles")
       (:file "mock-data")))
     (:module "unit"
      :depends-on ("package" "suite" "fixtures")
      :components
      ((:file "utilities-test")
       (:file "artifact-test")
       (:file "dependency-graph-test")
       (:file "dsl-test")
       (:file "test-ai-core")))           ; NEW: AI core unit tests
     (:module "integration"
      :depends-on ("package" "suite" "fixtures")
      :components
      ((:file "mini-corpus-test")
       (:file "pipeline-test")
       (:file "ai-export-integration-test"))) ; [0115] AI export integration (live ai-core seats)
     (:module "reproducibility"
      :depends-on ("package" "suite" "fixtures")
      :components
      ((:file "hash-stability-test"))))))
  
  :perform (test-op (o c)
             (symbol-call :orchestrator-tests :run-all-tests)))
