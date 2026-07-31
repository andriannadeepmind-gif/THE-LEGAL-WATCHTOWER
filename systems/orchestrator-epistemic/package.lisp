;;;; systems/orchestrator-epistemic/package.lisp

;;; ============================================================================
;;; RDF NAMESPACE PACKAGES
;;; ============================================================================
;;; These packages correspond to RDF/OWL namespace prefixes.
;;; They are used as Lisp symbols in vocabulary definitions.
;;;
;;; ONTOLOGY-FIRST DESIGN: Symbols are exported to match RDF vocabulary terms.

(defpackage #:rdf
  (:use)
  (:export)
  (:documentation "RDF namespace package"))

(defpackage #:rdfs
  (:use)
  (:export #:literal
           #:resource
           #:label
           #:comment
           #:domain
           #:range
           #:subClassOf
           #:subPropertyOf)
  (:documentation "RDFS (RDF Schema) namespace package"))

(defpackage #:owl
  (:use)
  (:export #:Ontology
           #:Class
           #:Thing
           #:DatatypeProperty
           #:ObjectProperty
           #:AllDifferent
           #:AllDisjointClasses
           #:versionIRI
           #:versionInfo
           #:imports
           #:members
           #:equivalentClass
           #:disjointWith)
  (:documentation "OWL (Web Ontology Language) namespace package"))

(defpackage #:xsd
  (:use)
  (:export #:string
           #:boolean
           #:integer
           #:dateTime
           #:anyURI
           #:decimal
           #:float
           #:double
           #:date
           #:time)
  (:documentation "XML Schema datatypes namespace package"))

(defpackage #:dcterms
  (:use)
  (:export #:title
           #:description
           #:creator
           #:created
           #:modified
           #:issued
           #:publisher
           #:license
           #:rights
           #:format
           #:identifier)
  (:documentation "Dublin Core Terms namespace package"))

(defpackage #:prov
  (:use)
  (:export #:Entity
           #:Activity
           #:Collection
           #:Agent
           #:wasGeneratedBy
           #:wasDerivedFrom
           #:wasAttributedTo
           #:wasAssociatedWith
           #:generated
           #:used
           #:startedAtTime
           #:endedAtTime)
  (:documentation "PROV-O namespace package"))

(defpackage #:dcat
  (:use)
  (:export #:Catalog
           #:Dataset
           #:Distribution
           #:dataset
           #:distribution
           #:downloadURL
           #:accessURL
           #:mediaType
           #:byteSize
           #:keyword
           #:theme)
  (:documentation "DCAT (Data Catalog Vocabulary) namespace package"))

(defpackage #:void
  (:use)
  (:export #:Dataset
           #:dataset
           #:dataDump
           #:vocabulary
           #:triples
           #:entities
           #:properties
           #:distinctSubjects)
  (:documentation "VoID (Vocabulary of Interlinked Datasets) namespace package"))

(defpackage #:eli
  (:use)
  (:export #:LegalResource
           #:legalResource
           #:legalExpression
           #:format
           #:jurisdiction
           #:dateDocument
           #:idLocal
           #:number)
  (:documentation "ELI (European Legislation Identifier) namespace package"))

(defpackage #:sh
  (:use)
  (:export #:NodeShape
           #:IRI
           #:nodeShape
           #:targetClass
           #:property
           #:path
           #:minCount
           #:maxCount
           #:datatype
           #:nodeKind
           #:class
           #:hasValue
           #:in
           #:languageIn
           #:message
           #:minInclusive
           #:or
           #:pattern
           #:uniqueLang)
  (:documentation "SHACL (Shapes Constraint Language) namespace package"))

(defpackage #:odrl
  (:use)
  (:export #:Policy
           #:Permission
           #:Duty
           #:Constraint
           #:policy
           #:permission
           #:prohibition
           #:duty
           #:action
           #:constraint
           #:target
           #:assigner
           #:assignee
           #:attribute
           #:derive
           #:index
           #:isAnyOf
           #:leftOperand
           #:operator
           #:purpose
           #:read
           #:rightOperand
           #:uid)
  (:documentation "ODRL (Open Digital Rights Language) namespace package"))

;;; ============================================================================
;;; ORCHESTRATOR EPISTEMIC PACKAGE
;;; ============================================================================

(defpackage #:orchestrator.epistemic
  (:use #:cl)
  (:import-from #:orchestrator.spec
                #:validation-error
                #:config-error)
  (:import-from #:orchestrator.model
                #:article
                #:article-number
                #:article-eli-uri
                #:article-hash
                #:article-rdf-turtle
                #:article-json-ld
                #:article-html
                #:corpus
                #:corpus-articles)
  (:import-from #:orchestrator.time
                #:now
                #:format-iso8601)
  (:import-from #:orchestrator.hash-authority
                #:compute-hash)
  (:export
   ;; Vocabularies
   #:+slw-namespace+
   #:+slw-version+

   ;; Meta-ontology (Layer 1)
   #:generate-meta-ontology

   ;; Lineage (Layer 3)
   #:generate-lineage-graph
   #:generate-origin-assertion
   #:generate-mutation-event

   ;; Negation (Layer 4)
   #:generate-negation-layer

   ;; Stability (Layer 6)
   #:generate-stability-policy-ttl
   #:generate-stability-policy-md

   ;; Release manifest (Layer 2)
   #:build-release-manifest
   #:build-release-manifest-jsonld
   #:collect-all-release-files

   ;; Merkle tree
   #:build-merkle-tree
   #:merkle-tree-root
   #:generate-inclusion-proof
   #:generate-all-inclusion-proofs
   #:verify-inclusion-proof

   ;; Level-1 primary-source (ΦΕΚ) anchor
   #:primary-anchor
   #:immutable-class
   #:make-primary-anchor
   #:anchor-fek-ref
   #:anchor-fek-citation
   #:anchor-fek-series
   #:anchor-fek-number
   #:anchor-fek-year
   #:anchor-source-uri
   #:anchor-source-digest
   #:anchor-extraction-digest
   #:anchor-extraction-method
   #:compute-extraction-digest
   #:anchor-algorithm
   #:anchor-locator
   #:anchor-retrieved-at
   #:anchor-verified-p
   #:anchor-assert
   #:anchor->plist
   #:primary-anchor-error
   #:anchor-digest-mismatch
   #:immutable-slot-error

   ;; Temporal proof
   ;; [0057]: request-rfc3161-timestamp αφαιρέθηκε (ΜΙΑ έδρα RFC-3161 =
   ;; orchestrator.timestamp-authority)· submit-to-multiple-ct-logs ήταν
   ;; orphan export (καμία υλοποίηση).
   #:sign-manifest-jws

   ;; SHACL shapes
   #:generate-article-shape
   #:generate-manifest-shape
   #:generate-lineage-shape
   #:generate-all-shapes

   ;; Main deploy
   #:deploy-epistemic-stage
   #:validate-epistemic-stage

   ;; [P1.5-D] Release spine verification (release-gate v2)
   #:verify-release-spine
   #:frozen-legacy-release-id-p

   ;; [L7-B] Transparency log των release roots (RFC 6962 §2.1.2)
   #:tlog-append-root!
   #:tlog-verify

   ;; [Level-7 VCCT-RSM] Οι ΠΑΛΙΕΣ έδρες authority ΚΑΤΑΡΓΗΘΗΚΑΝ. Το legacy
   ;; σύστημα είναι πλέον ΜΟΝΟ μη-έμπιστος παραγωγός candidate bundles.
   #:legacy-authority-seat-removed
   #:legacy-authority-seat-removed-seat
   #:emit-candidate-bundle!))
