;;;; systems/orchestrator-epistemic/shacl-shapes.lisp
;;;; SHACL Validation Shapes for Self-Validating Corpus

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; ARTICLE SHAPE (Canonical Article Validation)
;;; ============================================================================

(defun generate-article-shape ()
  "Generate SHACL shape for validating article artifacts

  Validates:
    - Canonical ELI URI structure
    - SHA-256 hash presence and format
    - conformsToSystem declaration
    - Genesis pointer (prov:wasGeneratedBy)
    - Required metadata (title, creator, date)
    - Language tags (Greek + English)

  Returns:
    Turtle string with article SHACL shape"

  (format nil "~A

# ==============================================================================
# ARTICLE VALIDATION SHAPE
# ==============================================================================
# PURPOSE: Validates canonical article artifacts
# STANDARD: W3C SHACL (https://www.w3.org/TR/shacl/)
# ==============================================================================

slw:ArticleShape a sh:NodeShape ;
    sh:targetClass eli:LegalResource ;
    rdfs:label \"Legal Article Validation Shape\"@en ;
    rdfs:comment \"\"\"Validates canonical article structure, including ELI URI,
        SHA-256 hash, epistemic system conformance, and PROV-O genesis pointer.\"\"\"@en ;

    # === CANONICAL URI VALIDATION ===
    sh:property [
        sh:path dcterms:identifier ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:pattern \"^https://stavropouloslaw\\\\.com/eli/gr/constitution/\" ;
        sh:message \"Article must have canonical ELI URI with stavropouloslaw.com authority\"@en ;
    ] ;

    # === SHA-256 HASH VALIDATION ===
    sh:property [
        sh:path slw:sha256Hash ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:pattern \"^sha256:[0-9a-f]{64}$\" ;
        sh:message \"Article must have SHA-256 hash in format 'sha256:HEX'\"@en ;
    ] ;

    # === EPISTEMIC SYSTEM CONFORMANCE ===
    sh:property [
        sh:path slw:conformsToSystem ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:hasValue <~A> ;
        sh:message \"Article must conform to declared epistemic system\"@en ;
    ] ;

    # === PROV-O GENESIS POINTER ===
    sh:property [
        sh:path prov:wasGeneratedBy ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:pattern \"/genesis$\" ;
        sh:message \"Article must have genesis event pointer\"@en ;
    ] ;

    # === TITLE (BILINGUAL) ===
    sh:property [
        sh:path dcterms:title ;
        sh:minCount 2 ;
        sh:uniqueLang true ;
        sh:languageIn ( \"el\" \"en\" ) ;
        sh:message \"Article must have titles in both Greek and English\"@en ;
    ] ;

    # === CREATOR ===
    sh:property [
        sh:path dcterms:creator ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:hasValue <https://stavropouloslaw.com/identity/org> ;
        sh:message \"Article must declare stavropouloslaw.com as creator\"@en ;
    ] ;

    # === CREATION DATE ===
    sh:property [
        sh:path dcterms:created ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:dateTime ;
        sh:message \"Article must have ISO 8601 creation timestamp\"@en ;
    ] ;

    # === ARTICLE NUMBER ===
    sh:property [
        sh:path eli:number ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:integer ;
        sh:minInclusive 1 ;
        sh:message \"Article must have positive integer number\"@en ;
    ] ;

    # === NON-NORMATIVE DECLARATION ===
    sh:property [
        sh:path slw:normative ;
        sh:maxCount 1 ;
        sh:hasValue false ;
        sh:message \"Article must declare non-normative nature (normative=false)\"@en ;
    ] .

"
          (format-prefixes)
          +slw-system-iri+))

;;; ============================================================================
;;; MANIFEST SHAPE (Release Manifest Validation)
;;; ============================================================================

(defun generate-manifest-shape ()
  "Generate SHACL shape for validating release manifests

  Validates:
    - Release timestamp (ISO 8601)
    - Merkle root (SHA-256 format)
    - Temporal proof references (RFC 3161, CT, JWS)
    - System commit hash
    - Total artifact counts
    - DCAT compliance

  Returns:
    Turtle string with manifest SHACL shape"

  (format nil "~A

# ==============================================================================
# RELEASE MANIFEST VALIDATION SHAPE
# ==============================================================================
# PURPOSE: Validates release manifest structure and temporal proofs
# STANDARD: W3C SHACL + DCAT 2.0
# ==============================================================================

slw:ManifestShape a sh:NodeShape ;
    sh:targetClass dcat:Catalog ;
    rdfs:label \"Release Manifest Validation Shape\"@en ;
    rdfs:comment \"\"\"Validates release manifest including temporal proof pack,
        Merkle root, system commit hash, and DCAT catalog structure.\"\"\"@en ;

    # === RELEASE TIMESTAMP ===
    sh:property [
        sh:path slw:releaseTimestamp ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:dateTime ;
        sh:message \"Manifest must have release timestamp in ISO 8601 format\"@en ;
    ] ;

    # === MERKLE ROOT ===
    sh:property [
        sh:path slw:merkleRoot ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:pattern \"^sha256:[0-9a-f]{64}$\" ;
        sh:message \"Manifest must have SHA-256 Merkle root\"@en ;
    ] ;

    # === SYSTEM COMMIT HASH ===
    sh:property [
        sh:path slw:systemCommitHash ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:pattern \"^sha256:[0-9a-f]{64}$\" ;
        sh:message \"Manifest must have system commit hash (epistemic framework fingerprint)\"@en ;
    ] ;

    # === TIMESTAMP RECEIPT (RFC 3161) ===
    sh:property [
        sh:path slw:timestampReceipt ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:pattern \"\\\\.tsr$\" ;
        sh:message \"Manifest must reference RFC 3161 timestamp receipt (.tsr file)\"@en ;
    ] ;

    # === JWS SIGNATURE ===
    sh:property [
        sh:path slw:signatureJWS ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:pattern \"\\\\.jws$\" ;
        sh:message \"Manifest must reference JWS signature file\"@en ;
    ] ;

    # === CT PROOFS (Multi-log) ===
    sh:property [
        sh:path slw:ctProof ;
        sh:minCount 1 ;
        sh:nodeKind sh:IRI ;
        sh:pattern \"ct-proof-.*\\\\.json$\" ;
        sh:message \"Manifest must reference at least one Certificate Transparency proof\"@en ;
    ] ;

    # === TOTAL ARTICLES ===
    sh:property [
        sh:path slw:totalArticles ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:integer ;
        sh:minInclusive 1 ;
        sh:message \"Manifest must declare total article count\"@en ;
    ] ;

    # === TOTAL ARTIFACTS ===
    sh:property [
        sh:path slw:totalArtifacts ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:integer ;
        sh:minInclusive 1 ;
        sh:message \"Manifest must declare total artifact count\"@en ;
    ] ;

    # === BLOCKCHAIN IS NOT AUTHORITY ===
    sh:property [
        sh:path slw:blockchainIsNotAuthority ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:hasValue true ;
        sh:message \"Manifest must declare blockchain as timestamp witness only\"@en ;
    ] ;

    # === DCAT DATASET REFERENCE ===
    sh:property [
        sh:path dcat:dataset ;
        sh:minCount 1 ;
        sh:class void:Dataset ;
        sh:message \"Manifest must reference VoID dataset\"@en ;
    ] ;

    # === PUBLISHER ===
    sh:property [
        sh:path dcterms:publisher ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:hasValue <https://stavropouloslaw.com/identity/org> ;
        sh:message \"Manifest must declare stavropouloslaw.com as publisher\"@en ;
    ] .

"
          (format-prefixes)))

;;; ============================================================================
;;; LINEAGE SHAPE (PROV-O Lineage Graph Validation)
;;; ============================================================================

(defun generate-lineage-shape ()
  "Generate SHACL shape for validating PROV-O lineage graph

  Validates:
    - Genesis events (prov:Activity)
    - Entity-Activity relationships (prov:wasGeneratedBy)
    - Blockchain anchors as timestamp witnesses
    - Mutation events (if present)
    - Continuity proofs (prov:wasDerivedFrom)

  Returns:
    Turtle string with lineage SHACL shape"

  (format nil "~A

# ==============================================================================
# LINEAGE GRAPH VALIDATION SHAPE
# ==============================================================================
# PURPOSE: Validates PROV-O lineage graph structure
# STANDARD: W3C SHACL + W3C PROV-O
# ==============================================================================

slw:GenesisEventShape a sh:NodeShape ;
    sh:targetClass slw:OriginAssertion ;
    rdfs:label \"Genesis Event Validation Shape\"@en ;
    rdfs:comment \"\"\"Validates PROV-O genesis events including blockchain
        anchors as timestamp witnesses.\"\"\"@en ;

    # === START TIME ===
    sh:property [
        sh:path prov:startedAtTime ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:dateTime ;
        sh:message \"Genesis event must have start time\"@en ;
    ] ;

    # === END TIME ===
    sh:property [
        sh:path prov:endedAtTime ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:dateTime ;
        sh:message \"Genesis event must have end time\"@en ;
    ] ;

    # === BLOCKCHAIN ANCHOR ===
    sh:property [
        sh:path slw:blockchainAnchor ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:message \"Genesis event must have blockchain anchor (timestamp witness)\"@en ;
    ] ;

    # === BLOCKCHAIN IS NOT AUTHORITY ===
    sh:property [
        sh:path slw:blockchainIsNotAuthority ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:hasValue true ;
        sh:message \"Genesis event must declare blockchain as witness only\"@en ;
    ] ;

    # === ASSOCIATED AGENT ===
    sh:property [
        sh:path prov:wasAssociatedWith ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:hasValue <https://stavropouloslaw.com/identity/org> ;
        sh:message \"Genesis event must be associated with stavropouloslaw.com\"@en ;
    ] .

slw:ArticleIdentityShape a sh:NodeShape ;
    sh:targetClass slw:LegalArticleIdentity ;
    rdfs:label \"Article Identity Validation Shape\"@en ;
    rdfs:comment \"Validates article identity entities in lineage graph\"@en ;

    # === GENERATED BY (Genesis or Mutation) ===
    sh:property [
        sh:path prov:wasGeneratedBy ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:or (
            [ sh:class slw:OriginAssertion ]
            [ sh:class slw:MutationEvent ]
        ) ;
        sh:message \"Article identity must be generated by genesis or mutation event\"@en ;
    ] ;

    # === IDENTITY HASH ===
    sh:property [
        sh:path slw:identityHash ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:pattern \"^sha256:[0-9a-f]{64}$\" ;
        sh:message \"Article identity must have SHA-256 hash\"@en ;
    ] ;

    # === GENESIS PROOF ===
    sh:property [
        sh:path slw:genesisProof ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:message \"Article identity must have genesis proof (blockchain anchor)\"@en ;
    ] .

slw:MutationEventShape a sh:NodeShape ;
    sh:targetClass slw:MutationEvent ;
    rdfs:label \"Mutation Event Validation Shape\"@en ;
    rdfs:comment \"Validates content mutation events with continuity proofs\"@en ;

    # === MUTATION TYPE ===
    sh:property [
        sh:path slw:mutationType ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:in ( \"correction\" \"amendment\" \"revision\" ) ;
        sh:message \"Mutation type must be correction, amendment, or revision\"@en ;
    ] ;

    # === HASH BEFORE ===
    sh:property [
        sh:path slw:hashBefore ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:pattern \"^sha256:[0-9a-f]{64}$\" ;
        sh:message \"Mutation must have hash before change\"@en ;
    ] ;

    # === HASH AFTER ===
    sh:property [
        sh:path slw:hashAfter ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:datatype xsd:string ;
        sh:pattern \"^sha256:[0-9a-f]{64}$\" ;
        sh:message \"Mutation must have hash after change\"@en ;
    ] ;

    # === USED (Previous version) ===
    sh:property [
        sh:path prov:used ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:class slw:LegalArticleIdentity ;
        sh:message \"Mutation must reference previous version\"@en ;
    ] ;

    # === GENERATED (New version) ===
    sh:property [
        sh:path prov:generated ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:class slw:LegalArticleIdentity ;
        sh:message \"Mutation must generate new version\"@en ;
    ] .

"
          (format-prefixes)))

;;; ============================================================================
;;; COMBINED SHAPES OUTPUT
;;; ============================================================================

(defun generate-all-shapes ()
  "Generate combined SHACL shapes file with all validation shapes

  Returns:
    Turtle string with article, manifest, and lineage shapes"

  (format nil "~A~%~A~%~A"
          (generate-article-shape)
          (generate-manifest-shape)
          (generate-lineage-shape)))
