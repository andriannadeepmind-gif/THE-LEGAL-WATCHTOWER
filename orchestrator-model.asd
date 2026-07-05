;;;; orchestrator-model.asd
;;;; ASDF System Definition for Orchestrator Data Model
;;;; CLOS + MOP data model with custom metaclasses

(asdf:defsystem #:orchestrator-model
  :description "CLOS + MOP data model with custom metaclasses for Greek Legal Corpus Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association) <ORCID: 0009-0005-2832-2153>"
  :license "All Rights Reserved"
  :version "0.9.0"
  :homepage "https://stavropouloslaw.com"
  
  :depends-on (#:orchestrator-spec
               #:orchestrator-infrastructure  ; Required for orchestrator.time package
               #:alexandria
               #:closer-mop
               #:local-time
               #:babel
               #:ironclad
               #:cl-ppcre)            ; Required by normalized-input.lisp
  
  :serial t
  :components
  ((:module "systems/orchestrator-model"
    :components
    ((:file "package")
     (:file "metaclasses")
     (:file "article")
     (:file "normalized-input")     ; IIR - Intermediate Internal Representation
     (:file "corpus")
     (:file "artifact")
     (:file "builders")
     (:file "schema")))))
