(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :orchestrator.meta)
    (defpackage :orchestrator.meta (:use :cl))))

;;;; orchestrator.asd
;;;; ASDF System Definition for Greek Legal Corpus Orchestrator
;;;; Production-Grade Modular Architecture - v1.2

(asdf:defsystem #:orchestrator
  :description "Greek Legal Corpus Orchestrator - Research-Grade Modular Architecture"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "1.2.0"
  :homepage "https://stavropouloslaw.com"
  :bug-tracker "https://github.com/David33law/orchestratorGREEKLAW/issues"
  :source-control (:git "https://github.com/David33law/orchestratorGREEKLAW.git")
  
  ;; Modular architecture - core systems + infrastructure
  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-core
               #:orchestrator-engine-sbcl
               #:orchestrator-meta
               #:orchestrator-infrastructure
               #:orchestrator-ai-core
               #:orchestrator-gr-syntagma
               #:orchestrator-cli
               #:orchestrator-omega))

;;;; ========================================================================
;;;; ORCHESTRATOR/TESTS - Test Suite System (Local Development Only)
;;;; ========================================================================

(asdf:defsystem #:orchestrator/tests
  :description "Test suite for local REPL development"
  :author "Spyridon Stavropoulos (Athens Bar Association)"
  :license "All Rights Reserved"
  :version "1.2.0"
  :depends-on (#:orchestrator-tests)
  
  :perform (test-op (o c)
             (symbol-call :orchestrator-tests :run-orchestrator-tests)))
