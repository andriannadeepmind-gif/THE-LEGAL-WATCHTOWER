;;;; orchestrator-gr-syntagma.asd
;;;; ASDF System Definition for Greek Constitution Domain
;;;; Greek Constitution domain specialization

(asdf:defsystem #:orchestrator-gr-syntagma
  :description "Greek Constitution domain specialization for Greek Legal Corpus Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "0.9.0"
  :homepage "https://stavropouloslaw.com"
  
  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-core
               #:orchestrator-meta
               #:alexandria
               #:local-time)
  
  :serial t
  :components
  ((:module "systems/orchestrator-gr-syntagma"
    :components
    ((:file "package")
     (:file "corpus")
     (:file "metadata")
     (:file "structure")
     (:file "parsing")
     (:file "validation")
     (:file "pipeline")
     (:file "historical")))))
