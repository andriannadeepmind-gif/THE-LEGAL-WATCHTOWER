;;;; orchestrator-spec.asd
;;;; ASDF System Definition for Orchestrator Specification Layer
;;;; Kernel protocols, DSL macros, conditions, types

(asdf:defsystem #:orchestrator-spec
  :description "Kernel protocols, DSL macros, conditions, and types for Greek Legal Corpus Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "0.9.0"
  :homepage "https://stavropouloslaw.com"
  
  :depends-on (#:alexandria
               #:closer-mop
               #:cl-ppcre)               ; For escape-html regex
  
  :serial t
  :components
  ((:module "systems/orchestrator-spec"
    :components
    ((:file "package")
     (:file "version")
     (:file "escaping")          ; Centralized escape functions (PHASE 1)
     (:file "protocols")
     (:file "conditions")
     (:file "types")
     (:file "pipeline-dsl")
     (:file "introspection")))))
