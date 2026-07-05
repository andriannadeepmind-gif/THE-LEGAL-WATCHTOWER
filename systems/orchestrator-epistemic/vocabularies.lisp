;;;; systems/orchestrator-epistemic/vocabularies.lisp
;;;; Stavropoulos Law Ontology Vocabulary Definitions

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; NAMESPACE CONSTANTS
;;; ============================================================================
;;; Using DEFPARAMETER instead of DEFCONSTANT to avoid SBCL DEFCONSTANT-UNEQL
;;; errors when file is loaded multiple times (build.lisp + ASDF).

(defparameter +slw-namespace+ "https://stavropouloslaw.com/ontology/legal#"
  "Stavropoulos Law ontology namespace IRI")

(defparameter +slw-version+ "1.0.0"
  "Current version of SLW ontology")

(defparameter +slw-ontology-iri+ "https://stavropouloslaw.com/ontology/legal"
  "Stable ontology IRI (version-independent)")

(defparameter +slw-system-iri+ "https://stavropouloslaw.com/system/legal-representation/2025"
  "System instance IRI")

;;; ============================================================================
;;; PREFIX DEFINITIONS
;;; ============================================================================

(defparameter *common-prefixes*
  '(("@prefix owl: <http://www.w3.org/2002/07/owl#> .")
    ("@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .")
    ("@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .")
    ("@prefix dcterms: <http://purl.org/dc/terms/> .")
    ("@prefix prov: <http://www.w3.org/ns/prov#> .")
    ("@prefix dcat: <http://www.w3.org/ns/dcat#> .")
    ("@prefix void: <http://rdfs.org/ns/void#> .")
    ("@prefix eli: <http://data.europa.eu/eli/ontology#> .")
    ("@prefix sh: <http://www.w3.org/ns/shacl#> .")
    ("@prefix odrl: <http://www.w3.org/ns/odrl/2/> .")
    ("@prefix slw: <https://stavropouloslaw.com/ontology/legal#> ."))
  "Standard RDF prefixes for all epistemic files")

;;; ============================================================================
;;; CLASS DEFINITIONS
;;; ============================================================================

(defparameter *slw-classes*
  '((LegalRepresentationSystem
     "Formal system for representing legal documents with identity-only semantics")

    (IdentityOnlySemantics
     "Representation system capturing artifact identity without normative interpretation")

    (LegalArticleIdentity
     "Legal article identity tracked through time")

    (OriginAssertion
     "Genesis generation event with blockchain-backed timestamp")

    (MutationEvent
     "Content mutation with hash continuity proof")

    (Release
     "Immutable timestamped release of corpus artifacts")

    (UnversionedText
     "Textual reproductions without version control or provenance")

    (ScrapedCopy
     "Web-scraped derivatives without canonical authority")

    (InferredReconstruction
     "Algorithmically reconstructed content without source proof")

    (NonProvencancedReproduction
     "Reproductions without documented origin chain"))
  "SLW ontology classes with descriptions")

;;; ============================================================================
;;; PROPERTY DEFINITIONS
;;; ============================================================================

(defparameter *slw-datatype-properties*
  '((representationScope rdfs:Literal
     "Scope of representation system")

    (nonNormativeNature xsd:boolean
     "Declares that system does not make normative claims")

    (identityOnlySemantics xsd:boolean
     "Commits to identity-only representation")

    (doesNotAnswerWhy xsd:boolean
     "Declares system does not interpret causality")

    (doesNotResolveConflicts xsd:boolean
     "Declares system does not resolve legal conflicts")

    (doesNotSelectInterpretation xsd:boolean
     "Declares system does not choose among interpretations")

    (doesNotModelIntent xsd:boolean
     "Declares system does not model legislative intent")

    (identityHash xsd:string
     "SHA-256 hash of canonical identity")

    (genesisProof xsd:string
     "Blockchain anchor of genesis timestamp")

    (blockchainAnchor xsd:string
     "Blockchain transaction hash or Merkle root")

    (blockchainIsNotAuthority xsd:boolean
     "CRITICAL: Declares blockchain is timestamp witness, not truth authority")

    (mutationType xsd:string
     "Type of mutation: correction|amendment|revision")

    (hashBefore xsd:string
     "Hash before mutation")

    (hashAfter xsd:string
     "Hash after mutation")

    (releaseTimestamp xsd:dateTime
     "Timestamp of immutable release")

    (merkleRoot xsd:string
     "SHA-256 Merkle root of all release artifacts")

    (systemCommitHash xsd:string
     "SHA-256 hash of entire epistemic system (ontology+lineage+negation)")

    (sha256Hash xsd:string
     "SHA-256 hash of individual artifact")

    (pipelineVersion xsd:string
     "Version of orchestrator pipeline")

    (totalArticles xsd:integer
     "Total number of articles in release")

    (totalArtifacts xsd:integer
     "Total number of artifacts in release")

    (timestampAuthority xsd:anyURI
     "RFC 3161 Timestamp Authority used")

    (ctLogId xsd:string
     "Certificate Transparency log identifier")

    (ctTimestamp xsd:dateTime
     "Certificate Transparency timestamp")

    (ctPolicy xsd:string
     "Multi-log redundancy policy (e.g., 'multi-log-capable')")

    (canonicalIDsNeverChange xsd:boolean
     "Guarantee that canonical IDs remain stable")

    (changesViaLineageOnly xsd:boolean
     "All changes tracked via lineage graph")

    (backwardResolutionGuaranteed xsd:boolean
     "Historical URIs resolve permanently via archived snapshots")

    (epistemicRole xsd:string
     "Role in epistemic system (e.g., 'identity-source-only')")

    (normative xsd:boolean
     "Whether artifact makes normative claims"))
  "SLW datatype properties (predicate, range, description)")

(defparameter *slw-object-properties*
  '((versionedEvolutionRules rdfs:Resource
     "Link to machine-readable evolution policy")

    (notEquivalentTo owl:Class
     "Declares non-equivalence with inferior source types")

    (conformsToSystem owl:Thing
     "Article conforms to declared epistemic system")

    (signatureJWS rdfs:Resource
     "Link to JWS detached signature file")

    (signaturePGP rdfs:Resource
     "Link to PGP signature file")

    (timestampReceipt rdfs:Resource
     "Link to RFC 3161 timestamp receipt")

    (ctProof rdfs:Resource
     "Link to Certificate Transparency SCT proof")

    (stabilityPolicyURI rdfs:Resource
     "Link to stability policy document"))
  "SLW object properties (predicate, range, description)")

;;; ============================================================================
;;; UTILITY FUNCTIONS
;;; ============================================================================

(defun format-prefixes ()
  "Return formatted prefix declarations for Turtle files"
  (format nil "~{~A~%~}~%" *common-prefixes*))

(defun make-slw-iri (local-name)
  "Construct full IRI for SLW term"
  (format nil "~A~A" +slw-namespace+ local-name))

(defun make-versioned-ontology-iri ()
  "Construct versioned ontology IRI"
  (format nil "~A/~A" +slw-ontology-iri+ +slw-version+))
