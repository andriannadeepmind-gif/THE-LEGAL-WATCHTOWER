;;;; orchestrator-tests-runtime.asd
;;;; TEST-ONLY System Definition
;;;; NOT loaded in production builds

(asdf:defsystem #:orchestrator-tests-runtime
  :description "Test suite for Orchestrator - NOT loaded in production"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "1.0.0"
  :homepage "https://stavropouloslaw.com"
  
  ;; ══════════════════════════════════════════════════════════
  ;; TEST-ONLY DEPENDENCIES
  ;; Include test frameworks and development dependencies
  ;; ══════════════════════════════════════════════════════════
  :depends-on (#:orchestrator-core-runtime
               #:orchestrator-tests    ; Existing test suite
               #:fiveam                ; Test framework
               #:alexandria)
  
  :serial nil
  :components ()
  
  :perform (test-op (o c)
             (symbol-call :orchestrator-tests :run-all-tests)))
