;;;; orchestrator-engine-sbcl.asd

(asdf:defsystem #:orchestrator-engine-sbcl
  :description "SBCL implementations for Orchestrator"
  :author "Spyridon Stavropoulos (Athens Bar Association)"
  :license "All Rights Reserved"
  :version "1.2.0"
  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-core
               #:orchestrator-omega    ; HYBRID PHASE 1 generators
               #:orchestrator-ai-core  ; AI ingest manifest generation
               #:orchestrator-epistemic ; Epistemic authority system (6 layers)
               #:orchestrator-infrastructure  ; Required for orchestrator.time package
               #:closer-mop          ; MOP introspection for FSM validation
               #:named-readtables    ; Named readtable for #§ legal article dispatch
               #:log4cl              ; [RATCHET-5] ΑΔΗΛΩΤΗ εξάρτηση: 17 αρχεία χρησιμοποιούν
                                     ; το πακέτο LOG — αυτάρκεια ΔΗΛΩΜΕΝΗ, όχι τυχαία
               #:alexandria
               #:cl-ppcre
               #:jonathan
               #:yason
               #:local-time
               #:ironclad
               #:babel
               #:drakma
               #:cxml
               #:cxml-stp           ; Full DOM parser for Parliament HTML (via yacc → xpath → cxml-stp)
               #:chipz              ; DEFLATE inflate for the .docx (ZIP) authoritative-source adapter
               #:uiop)
  :components
  ((:module "systems/orchestrator-engine-sbcl"
    :components
    ((:file "package")
     (:file "filesystem" :depends-on ("package"))
     
     (:module "adapters"
      :depends-on ("package" "filesystem")
      :components
      ((:file "json-adapter")
       ;; [Π7-U.1 Φ1γ] Η ΜΙΑ έδρα errata στο όριο εξαγωγής — πριν από pdf/docx
       (:file "errata-boundary")
       (:file "pdf-adapter" :depends-on ("errata-boundary"))
       (:file "raw-text-adapter")
       (:file "html-parliament-adapter")
       ;; .docx (Office Open XML) → text → raw-text FSM; needs raw-text->iir-articles
       (:file "docx-adapter" :depends-on ("raw-text-adapter" "errata-boundary"))))
     
     (:module "stages"
      :depends-on ("package" "filesystem" "adapters")
      :components
      ((:file "source-normalize")
       (:file "load-json-source")
       (:file "parse-pdf")
       (:file "parse-raw-text")
       (:file "generate-rdf")
       (:file "consolidate")    ; Codification: in-force consolidated text + provenance
       (:file "test-escaping")  ; PIPELINE-EMBEDDED TESTS
       (:file "validate-shacl")
       (:file "hash-artifacts")
       (:file "anchor-blockchain")
       (:file "deploy")
       (:file "deploy-epistemic")))
     
     (:module "backends"
      :depends-on ("package")
      :components
      ((:file "mock")
       (:file "ethereum")
       (:file "arweave")
       (:file "ipfs")))
     
     (:module "templates"
      :depends-on ("package")
      :components
      ((:file "rendering")))

     ;; NOTE: the former "emission" module (orchestrator.emission: emission-core +
     ;; emission-stages) was a flat eli:LegalResource emitter, fully SUPERSEDED by
     ;; the richer live FRBR emission path (unified-frbr-generator +
     ;; html-rdfa-generator + ai-corpus-dump). It had zero callers; retired from
     ;; the build to consolidate on the superior path (no capability removed —
     ;; the FRBR path emits a strict superset: Work/Expression/Manifestation/
     ;; Format + PROV-O + suffix-safe ids).
     ))))
