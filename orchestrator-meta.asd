;;;; orchestrator-meta.asd
;;;; ASDF System Definition for Orchestrator Meta-Introspection
;;;; Self-introspection system (registry, meta-model, queries)

(asdf:defsystem #:orchestrator-meta
  :description "Self-introspection system for Greek Legal Corpus Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "0.9.0"
  :homepage "https://stavropouloslaw.com"
  
  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-infrastructure  ; Required for orchestrator.time package
               #:alexandria
               #:jonathan
               #:uiop)
  
  :serial t
  :components
  ((:module "systems/orchestrator-meta"
    :components
    ((:file "package")
     (:file "registry")
     (:file "meta-model")
     (:file "meta-graph")
     (:file "queries")
     (:file "reports")
     (:file "tool-versions")))))
