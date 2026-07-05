;;;; orchestrator-tooling.asd
;;;; DEV-ONLY System Definition
;;;; Development tooling - NOT loaded in production

(asdf:defsystem #:orchestrator-tooling
  :description "Development tooling for Orchestrator - NOT loaded in production"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "1.0.0"
  :homepage "https://stavropouloslaw.com"
  
  ;; ══════════════════════════════════════════════════════════
  ;; DEV-ONLY DEPENDENCIES
  ;; Include development and debugging tools
  ;; ══════════════════════════════════════════════════════════
  :depends-on (#:orchestrator-core-runtime
               #:alexandria)
  
  :serial nil
  :components ())
