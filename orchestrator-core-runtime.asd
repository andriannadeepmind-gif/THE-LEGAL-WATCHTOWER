;;;; orchestrator-core-runtime.asd
;;;; RUNTIME-ONLY System Definition
;;;; NO tests, NO tooling - Pure production runtime

(asdf:defsystem #:orchestrator-core-runtime
  :description "Core runtime for Greek Legal Corpus Orchestrator - NO tests, NO tooling"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "1.0.0"
  :homepage "https://stavropouloslaw.com"
  
  ;; ══════════════════════════════════════════════════════════
  ;; RUNTIME DEPENDENCIES ONLY
  ;; NO test frameworks (fiveam)
  ;; NO dev tools (log4cl for dev logging, unless needed in prod)
  ;; ══════════════════════════════════════════════════════════
  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-core
               #:orchestrator-engine-sbcl
               #:orchestrator-omega
               #:orchestrator-meta
               #:orchestrator-cli
               #:orchestrator-gr-syntagma
               #:orchestrator-ai-core
               #:orchestrator-infrastructure)
  
  :serial nil
  :components ()
  
  :in-order-to ((test-op (test-op "orchestrator-tests-runtime"))))
