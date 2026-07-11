;;;; orchestrator-epistemic.asd
;;;; Epistemic Authority System - Six Layers
;;;;
;;;; PURPOSE: Global epistemic authority for Greek legal corpus
;;;; LAYERS:
;;;;   1. Meta-ontology (epistemic system definition)
;;;;   2. Release proof pack (temporal priority)
;;;;   3. Identity lineage (PROV-O continuity)
;;;;   4. Canonical negation (defensive moat)
;;;;   5. Epistemic boundaries (credibility)
;;;;   6. Stability commitment (long-term anchor)

(defsystem "orchestrator-epistemic"
  :description "Epistemic authority system for Greek legal corpus"
  :version "1.0.0"
  :author "Stavropoulos Law"
  :license "All Rights Reserved"

  :depends-on (#:orchestrator-spec
               #:orchestrator-model
               #:orchestrator-infrastructure  ; Provides orchestrator.time + hash-authority
               #:drakma
               #:ironclad
               #:jonathan
               #:cl-base64
               #:babel
               #:alexandria
               #:log4cl
               #:cl-ppcre)

  :pathname "systems/orchestrator-epistemic/"

  :components
  ((:file "package")
   (:file "vocabularies" :depends-on ("package"))
   (:file "meta-ontology" :depends-on ("vocabularies"))
   (:file "lineage-authority" :depends-on ("vocabularies"))
   (:file "negation-layer" :depends-on ("vocabularies"))
   (:file "stability-policy" :depends-on ("vocabularies"))
   (:file "merkle-tree" :depends-on ("package"))
   ;; Level-1: provenance anchor to the primary ΦΕΚ (reuses compute-sha256-*)
   (:file "primary-anchor" :depends-on ("package" "merkle-tree"))
   (:file "temporal-proof" :depends-on ("package" "merkle-tree"))
   (:file "release-manifest" :depends-on ("vocabularies" "merkle-tree"))
   ;; [P1.5-B] Artifact Census: το 9ο canonical αρχείο (census-1)
   (:file "artifact-census" :depends-on ("package" "release-manifest"))
   (:file "release-spine" :depends-on ("package" "artifact-census" "deploy-epistemic"))
   (:file "shacl-shapes" :depends-on ("vocabularies"))
   (:file "deploy-epistemic" :depends-on ("meta-ontology"
                                          "lineage-authority"
                                          "negation-layer"
                                          "stability-policy"
                                          "release-manifest"
                                          "artifact-census"
                                          "temporal-proof"
                                          "shacl-shapes"))))
