;;;; orchestrator-ai-core.asd
;;;; ASDF System Definition for Orchestrator AI Core
;;;; AI authority & ingest layer (beacons, manifests, provenance)

(asdf:defsystem #:orchestrator-ai-core
  :description "AI authority & ingest layer for Greek Legal Corpus Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "0.9.1"
  :homepage "https://stavropouloslaw.com"
  
  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-infrastructure  ; Required for orchestrator.time package
               #:alexandria
               #:yason                  ; JSON serialization (replacing jonathan)
               #:ironclad               ; For provenance hashing
               #:babel                  ; For string/octets conversion
               #:cl-yaml                ; For YAML config parsing
               #:local-time
               #:uuid)
  
  :serial t
  :components
  ((:module "systems/orchestrator-ai-core"
    :components
    ((:file "package")
     (:file "beacon-model")
     (:file "ingest-manifest")
     (:file "citation-strategy")
     (:file "provenance-model")
     (:file "config")                   ; NEW: AI configuration
     (:file "feeds")))))
