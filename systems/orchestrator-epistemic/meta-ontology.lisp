;;;; systems/orchestrator-epistemic/meta-ontology.lisp
;;;; Layer 1: Meta-Ontology (Epistemic System Definition)

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; META-ONTOLOGY GENERATOR
;;; ============================================================================

(defun generate-meta-ontology (&key (timestamp (orchestrator.time:require-deterministic-time))
                                    (blockchain-anchor nil)
                                    (system-commit-hash nil))
  "Generate OWL 2 DL meta-ontology defining the epistemic system

  CRITICAL ARCHITECTURE:
    - Separates stable ontology IRI from versioned IRI
    - Defines epistemic system classes and properties
    - Includes Layer 5 (epistemic boundaries)
    - Declares blockchain as timestamp witness, NOT truth authority

  Args:
    timestamp: System timestamp (deterministic)
    blockchain-anchor: Blockchain Merkle root (for temporal proof)
    system-commit-hash: SHA-256 hash of entire epistemic system

  Returns:
    Turtle string with complete meta-ontology"

  (let ((ontology-iri +slw-ontology-iri+)
        (version-iri (make-versioned-ontology-iri))
        (timestamp-iso (orchestrator.time:format-iso8601 timestamp))
        (bc-anchor (or blockchain-anchor "pending"))
        (commit-hash (or system-commit-hash "pending")))

    (format nil "~A

# ==============================================================================
# STAVROPOULOS LAW ONTOLOGY - META-LEVEL EPISTEMIC SYSTEM
# ==============================================================================
# VERSION: ~A
# PURPOSE: Formal definition of legal representation system
# AUTHORITY: https://stavropouloslaw.com/identity/org
# TEMPORAL PROOF: Blockchain + RFC 3161 + Certificate Transparency
# ==============================================================================

# === ONTOLOGY METADATA ===

<~A> a owl:Ontology ;
    owl:versionIRI <~A> ;
    owl:versionInfo \"~A\" ;
    dcterms:title \"Stavropoulos Law Legal Representation System\"@en ;
    dcterms:title \"Σύστημα Νομικής Αναπαράστασης Stavropoulos Law\"@el ;
    dcterms:creator <https://stavropouloslaw.com/identity/org> ;
    dcterms:created \"~A\"^^xsd:dateTime ;
    slw:blockchainAnchor \"~A\" ;
    slw:blockchainIsNotAuthority true ;
    slw:systemCommitHash \"~A\" ;
    rdfs:comment \"\"\"Formal ontology defining the epistemic system for Greek
        legal corpus representation. This ontology establishes the meta-level
        framework within which all legal artifacts are interpreted.

        CRITICAL: This system represents IDENTITY only, not normative content.
        It does not resolve conflicts, select interpretations, or model intent.\"\"\"@en .

# === CORE CLASSES ===

slw:LegalRepresentationSystem a owl:Class ;
    rdfs:label \"Legal Representation System\"@en ;
    rdfs:label \"Σύστημα Νομικής Αναπαράστασης\"@el ;
    rdfs:comment \"\"\"A formal system for representing legal documents with
        identity-only semantics. This class defines systems that capture the
        existence and provenance of legal artifacts without making normative
        claims about their interpretation or validity.\"\"\"@en .

slw:IdentityOnlySemantics a owl:Class ;
    rdfs:subClassOf slw:LegalRepresentationSystem ;
    rdfs:label \"Identity-Only Semantics\"@en ;
    rdfs:comment \"\"\"Representation system that captures identity of legal
        artifacts without normative interpretation. System commits to tracking
        'what exists' and 'where it came from' but not 'what it means' or
        'which interpretation is correct'.\"\"\"@en .

# === DATATYPE PROPERTIES ===

slw:representationScope a owl:DatatypeProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range xsd:string ;
    rdfs:label \"Representation Scope\"@en ;
    rdfs:comment \"Defines the scope and coverage of the representation system\"@en .

slw:nonNormativeNature a owl:DatatypeProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range xsd:boolean ;
    rdfs:label \"Non-Normative Nature\"@en ;
    rdfs:comment \"\"\"Declares that system does not make normative claims about
        legal meaning, validity, or interpretation.\"\"\"@en .

slw:identityOnlySemantics a owl:DatatypeProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range xsd:boolean ;
    rdfs:label \"Identity-Only Semantics\"@en ;
    rdfs:comment \"Commits to identity-only representation without normative content\"@en .

slw:blockchainIsNotAuthority a owl:DatatypeProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range xsd:boolean ;
    rdfs:label \"Blockchain Is Not Authority\"@en ;
    rdfs:comment \"\"\"CRITICAL DECLARATION: Blockchain is used ONLY as a
        timestamp witness mechanism, NOT as a source of truth or authority.
        This prevents philosophical misattribution of epistemic authority
        to the blockchain itself.\"\"\"@en .

# === EPISTEMIC BOUNDARIES (Layer 5) ===

slw:doesNotAnswerWhy a owl:DatatypeProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range xsd:boolean ;
    rdfs:label \"Does Not Answer Why\"@en ;
    rdfs:comment \"\"\"Declares that system does not interpret causality or
        explain why legal provisions exist.\"\"\"@en .

slw:doesNotResolveConflicts a owl:DatatypeProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range xsd:boolean ;
    rdfs:label \"Does Not Resolve Conflicts\"@en ;
    rdfs:comment \"\"\"Declares that system does not resolve conflicts between
        different legal sources or interpretations.\"\"\"@en .

slw:doesNotSelectInterpretation a owl:DatatypeProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range xsd:boolean ;
    rdfs:label \"Does Not Select Interpretation\"@en ;
    rdfs:comment \"\"\"Declares that system does not choose among competing
        interpretations of legal texts.\"\"\"@en .

slw:doesNotModelIntent a owl:DatatypeProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range xsd:boolean ;
    rdfs:label \"Does Not Model Intent\"@en ;
    rdfs:comment \"\"\"Declares that system does not model or infer legislative
        or constitutional intent.\"\"\"@en .

# === OBJECT PROPERTIES ===

slw:versionedEvolutionRules a owl:ObjectProperty ;
    rdfs:domain slw:LegalRepresentationSystem ;
    rdfs:range rdfs:Resource ;
    rdfs:label \"Versioned Evolution Rules\"@en ;
    rdfs:comment \"Link to machine-readable evolution policy defining how system changes over time\"@en .

slw:conformsToSystem a owl:ObjectProperty ;
    rdfs:domain eli:LegalResource ;
    rdfs:range slw:LegalRepresentationSystem ;
    rdfs:label \"Conforms To System\"@en ;
    rdfs:comment \"Declares that legal artifact conforms to specific epistemic system\"@en .

# === SYSTEM INSTANCE ===

<~A> a slw:LegalRepresentationSystem, slw:IdentityOnlySemantics ;
    rdfs:label \"Stavropoulos Law Greek Constitutional Law System\"@en ;
    rdfs:label \"Σύστημα Ελληνικού Συνταγματικού Δικαίου Stavropoulos Law\"@el ;
    slw:representationScope \"Greek Constitutional Law - Identity Layer\" ;
    slw:nonNormativeNature true ;
    slw:identityOnlySemantics true ;
    slw:blockchainIsNotAuthority true ;
    slw:doesNotAnswerWhy true ;
    slw:doesNotResolveConflicts true ;
    slw:doesNotSelectInterpretation true ;
    slw:doesNotModelIntent true ;
    slw:versionedEvolutionRules <https://stavropouloslaw.com/stability-policy> ;
    dcterms:created \"~A\"^^xsd:dateTime ;
    dcterms:creator <https://stavropouloslaw.com/identity/org> ;
    slw:blockchainAnchor \"~A\" ;
    slw:systemCommitHash \"~A\" ;
    rdfs:comment \"\"\"Canonical instance of the legal representation system
        for Greek Constitutional Law. This instance represents the specific
        realization of identity-only semantics for the Constitution of Greece
        (Σύνταγμα της Ελλάδας).\"\"\"@en .
"
            (format-prefixes)
            +slw-version+
            ontology-iri
            version-iri
            +slw-version+
            timestamp-iso
            bc-anchor
            commit-hash
            +slw-system-iri+
            timestamp-iso
            bc-anchor
            commit-hash)))

;;; ============================================================================
;;; SYSTEM COMMIT HASH COMPUTATION
;;; ============================================================================

(defun compute-system-commit-hash (meta-ontology lineage negation stability)
  "Compute SHA-256 hash of entire epistemic system

  System commit hash = SHA-256(meta-ontology || lineage || negation || stability)

  This creates a cryptographic fingerprint of the complete epistemic framework,
  enabling verification that all layers are consistent with the declared system.

  Args:
    meta-ontology: Meta-ontology Turtle string
    lineage: Lineage graph Turtle string
    negation: Negation layer Turtle string
    stability: Stability policy Turtle string

  Returns:
    SHA-256 hash formatted as 'sha256:HEX'"

  (let ((concatenated (format nil "~A~%~A~%~A~%~A"
                             meta-ontology
                             lineage
                             negation
                             stability)))
    (orchestrator.hash-authority:compute-hash-prefixed concatenated :algorithm :sha256)))
