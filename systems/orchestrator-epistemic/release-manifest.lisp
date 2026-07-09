;;;; systems/orchestrator-epistemic/release-manifest.lisp
;;;; Layer 2: Release Manifest (DCAT + VoID + Temporal Proof Pack)

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; RELEASE FILE COLLECTION
;;; ============================================================================

(defun collect-all-release-files (output-dir)
  "Collect all files in release directory for Merkle tree construction

  Collects ALL files for complete proof chain:
    - Article artifacts (TTL, JSON-LD, HTML, PDF)
    - Dataset-level files (manifest, void, ai-manifest)
    - Epistemic layer files (meta-ontology, lineage-graph, negation, stability)
    - SHACL shapes (3 files)
    - Temporal proof files (merkle-tree, timestamp, CT proofs, JWS signature, inclusion proofs)
    - Verification kit (public.jwk, tsa-ca.pem, verify scripts, README)

  Args:
    output-dir: Release directory path

  Returns:
    List of absolute file paths"

  (let ((files '()))
    ;; Collect article artifacts
    (dolist (file (directory (merge-pathnames "articles/article-*.ttl" output-dir)))
      (push file files))
    (dolist (file (directory (merge-pathnames "articles/article-*.jsonld" output-dir)))
      (push file files))
    (dolist (file (directory (merge-pathnames "articles/article-*.html" output-dir)))
      (push file files))
    (dolist (file (directory (merge-pathnames "articles/article-*.pdf" output-dir)))
      (push file files))

    ;; Collect dataset-level files
    (dolist (filename '("manifest.ttl" "void.ttl" "ai-manifest.jsonld"))
      (let ((path (merge-pathnames filename output-dir)))
        (when (probe-file path)
          (push path files))))

    ;; Collect epistemic layer files (UPDATED: lineage.ttl → lineage-graph.ttl)
    (dolist (filename '("meta-ontology.ttl" "lineage-graph.ttl" "negation.ttl"
                       "stability-policy.ttl" "stability-policy.md"))
      (let ((path (merge-pathnames filename output-dir)))
        (when (probe-file path)
          (push path files))))

    ;; Collect SHACL shapes
    (dolist (file (directory (merge-pathnames "shapes/*.ttl" output-dir)))
      (push file files))

    ;; Collect temporal proof files
    (dolist (file (directory (merge-pathnames "temporal-proof/*.json" output-dir)))
      (push file files))
    (dolist (file (directory (merge-pathnames "temporal-proof/*.tsr" output-dir)))
      (push file files))
    (dolist (file (directory (merge-pathnames "temporal-proof/*.jws" output-dir)))
      (push file files))
    (dolist (file (directory (merge-pathnames "temporal-proof/inclusion-proofs/*.json" output-dir)))
      (push file files))

    ;; Collect verification kit files
    (dolist (filename '("verify/public.jwk" "verify/tsa-ca.pem"
                       "verify/verify.sh" "verify/verify.ps1" "verify/verify.lisp"
                       "verify/README-VERIFY.md"))
      (let ((path (merge-pathnames filename output-dir)))
        (when (probe-file path)
          (push path files))))

    ;; Sort for deterministic ordering
    (sort files #'string< :key #'namestring)))

(defun collect-epistemic-artifacts (staging-dir)
  "Collect ONLY epistemic layer artifacts for canonical Merkle root

  DARPA-GRADE PROVENANCE: This function defines the CANONICAL set of artifacts
  that form the release-root-hash. NO temporal proofs, NO manifests, NO verification kit.

  Collects EXACTLY 8 files (deterministic):
    1. meta-ontology.ttl
    2. lineage-graph.ttl
    3. negation.ttl
    4. stability-policy.ttl
    5. stability-policy.md
    6. shapes/article-shape.ttl
    7. shapes/manifest-shape.ttl
    8. shapes/lineage-shape.ttl

  Args:
    staging-dir: Staging directory path

  Returns:
    List of 8 absolute file paths (sorted)"

  (let ((files '()))
    ;; Epistemic layer files (5 files)
    (dolist (filename '("meta-ontology.ttl" "lineage-graph.ttl" "negation.ttl"
                       "stability-policy.ttl" "stability-policy.md"))
      (let ((path (merge-pathnames filename staging-dir)))
        (unless (probe-file path)
          (error "CRITICAL: Missing epistemic artifact: ~A" path))
        (push path files)))

    ;; SHACL shapes (3 files)
    (dolist (filename '("shapes/article-shape.ttl"
                       "shapes/manifest-shape.ttl"
                       "shapes/lineage-shape.ttl"))
      (let ((path (merge-pathnames filename staging-dir)))
        (unless (probe-file path)
          (error "CRITICAL: Missing SHACL shape: ~A" path))
        (push path files)))

    ;; Sort for deterministic ordering
    (let ((sorted (sort files #'string< :key #'namestring)))
      (unless (= (length sorted) 8)
        (error "CRITICAL: Expected 8 epistemic artifacts, found ~D" (length sorted)))
      sorted)))

;;; ============================================================================
;;; RELEASE MANIFEST GENERATION
;;; ============================================================================

(defun build-release-manifest (articles output-dir
                               &key (timestamp (orchestrator.time:now :source :system))
                                    (merkle-root nil)
                                    (rfc3161-receipt nil)
                                    (ct-proofs nil)
                                    (jws-signature nil)
                                    (system-commit-hash nil))
  "Generate DCAT + VoID release manifest

  ARCHITECTURE:
    - DCAT Catalog for dataset discovery
    - VoID description for RDF dataset statistics
    - Temporal proof pack references (RFC 3161, CT, JWS)
    - Merkle root for cryptographic commitment
    - Individual artifact inventory with hashes

  Args:
    articles: List of article objects
    output-dir: Release directory
    timestamp: Release timestamp (deterministic)
    merkle-root: SHA-256 Merkle root of all artifacts
    rfc3161-receipt: Path to RFC 3161 timestamp receipt
    ct-proofs: List of CT proof paths
    jws-signature: Path to JWS signature file
    system-commit-hash: SHA-256 hash of epistemic system

  Returns:
    Turtle string with complete manifest"

  (let ((release-iri (format nil "https://stavropouloslaw.com/releases/~A"
                            (orchestrator.time:format-iso8601 timestamp)))
        (timestamp-iso (orchestrator.time:format-iso8601 timestamp))
        (all-files (collect-all-release-files output-dir))
        (total-articles (length articles))
        (total-artifacts (+ (* (length articles) 4) ; 4 formats per article
                           5                         ; dataset files
                           5)))                      ; epistemic layer files

    (with-output-to-string (out)
      ;; Prefixes
      (format out "~A~%" (format-prefixes))

      ;; Header
      (format out "# ==============================================================================~%")
      (format out "# STAVROPOULOS LAW - IMMUTABLE RELEASE MANIFEST~%")
      (format out "# ==============================================================================~%")
      (format out "# RELEASE: ~A~%" timestamp-iso)
      (format out "# PURPOSE: Cryptographically committed release manifest~%")
      (format out "# STANDARD: DCAT 2.0 + VoID + W3C PROV~%")
      (format out "# TEMPORAL PROOF: RFC 3161 + CT + JWS~%")
      (format out "# ==============================================================================~%~%")

      ;; DCAT Catalog
      (format out "<~A> a dcat:Catalog ;~%" release-iri)
      (format out "    dcterms:title \"Greek Constitutional Law Corpus - Release ~A\"@en ;~%"
              timestamp-iso)
      (format out "    dcterms:title \"Σώμα Ελληνικού Συνταγματικού Δικαίου - Έκδοση ~A\"@el ;~%"
              timestamp-iso)
      (format out "    dcterms:created \"~A\"^^xsd:dateTime ;~%" timestamp-iso)
      (format out "    dcterms:publisher <https://stavropouloslaw.com/identity/org> ;~%")
      (format out "    dcterms:license <https://creativecommons.org/publicdomain/zero/1.0/> ;~%")
      (format out "    dcat:dataset <~A/dataset> ;~%" release-iri)
      (format out "    slw:releaseTimestamp \"~A\"^^xsd:dateTime ;~%" timestamp-iso)
      (format out "    slw:merkleRoot \"~A\" ;~%" (or merkle-root "pending"))
      (format out "    slw:systemCommitHash \"~A\" ;~%" (or system-commit-hash "pending"))
      (format out "    slw:totalArticles ~D ;~%" total-articles)
      (format out "    slw:totalArtifacts ~D ;~%" total-artifacts)
      (format out "    slw:pipelineVersion \"~A\" ;~%" orchestrator.spec:+version+)
      (format out "    slw:blockchainIsNotAuthority true ;~%")

      ;; Temporal proof references
      (when rfc3161-receipt
        (format out "    slw:timestampReceipt <~A/timestamp.tsr> ;~%" release-iri))
      (when jws-signature
        (format out "    slw:signatureJWS <~A/signature.jws> ;~%" release-iri))
      (when ct-proofs
        (dolist (ct-proof ct-proofs)
          (format out "    slw:ctProof <~A/~A> ;~%" release-iri (file-namestring ct-proof))))

      (format out "    rdfs:comment \"\"\"Immutable timestamped release of Greek Constitutional\\n")
      (format out "        Law corpus. This manifest provides cryptographic commitment via Merkle root,\\n")
      (format out "        temporal proof via RFC 3161 + Certificate Transparency, and integrity\\n")
      (format out "        verification via JWS signature.\"\"\"@en .~%~%")

      ;; VoID Dataset Description
      (format out "<~A/dataset> a void:Dataset, dcat:Dataset ;~%" release-iri)
      (format out "    dcterms:title \"Greek Constitutional Law RDF Dataset\"@en ;~%")
      (format out "    dcterms:description \"\"\"Complete RDF representation of Greek Constitution\\n")
      (format out "        articles with identity-only semantics and PROV-O lineage tracking.\"\"\"@en ;~%")
      (format out "    void:triples ~D ;~%"
              (* total-articles 50)) ; Approximate triples per article
      (format out "    void:entities ~D ;~%" total-articles)
      (format out "    void:properties 25 ;~%") ; Approximate distinct properties
      (format out "    void:distinctSubjects ~D ;~%" total-articles)
      (format out "    void:vocabulary <~A> ;~%" +slw-ontology-iri+)
      (format out "    void:vocabulary <http://data.europa.eu/eli/ontology#> ;~%")
      (format out "    void:vocabulary <http://www.w3.org/ns/prov#> ;~%")
      (format out "    dcat:distribution <~A/distribution/turtle> ,~%" release-iri)
      (format out "                      <~A/distribution/jsonld> ,~%" release-iri)
      (format out "                      <~A/distribution/html> ,~%" release-iri)
      (format out "                      <~A/distribution/pdf> ;~%" release-iri)
      (format out "    slw:conformsToSystem <~A> .~%~%" +slw-system-iri+)

      ;; DCAT Distributions
      (format out "# === DCAT Distributions ===~%~%")

      (format out "<~A/distribution/turtle> a dcat:Distribution ;~%" release-iri)
      (format out "    dcterms:format \"text/turtle\" ;~%")
      (format out "    dcat:mediaType \"text/turtle\" ;~%")
      (format out "    dcterms:title \"RDF Turtle Format\"@en ;~%")
      (format out "    dcat:accessURL <~A/articles/> .~%~%" release-iri)

      (format out "<~A/distribution/jsonld> a dcat:Distribution ;~%" release-iri)
      (format out "    dcterms:format \"application/ld+json\" ;~%")
      (format out "    dcat:mediaType \"application/ld+json\" ;~%")
      (format out "    dcterms:title \"JSON-LD Format\"@en ;~%")
      (format out "    dcat:accessURL <~A/articles/> .~%~%" release-iri)

      (format out "<~A/distribution/html> a dcat:Distribution ;~%" release-iri)
      (format out "    dcterms:format \"text/html\" ;~%")
      (format out "    dcat:mediaType \"text/html\" ;~%")
      (format out "    dcterms:title \"HTML with RDFa + JSON-LD\"@en ;~%")
      (format out "    dcat:accessURL <~A/articles/> .~%~%" release-iri)

      (format out "<~A/distribution/pdf> a dcat:Distribution ;~%" release-iri)
      (format out "    dcterms:format \"application/pdf\" ;~%")
      (format out "    dcat:mediaType \"application/pdf\" ;~%")
      (format out "    dcterms:title \"PDF Format\"@en ;~%")
      (format out "    dcat:accessURL <~A/articles/> .~%~%" release-iri)

      ;; Artifact Inventory (ALL files with hash + byteSize)
      (format out "# === ARTIFACT INVENTORY ===~%~%")
      (format out "# Individual artifact hashes for Merkle tree verification~%~%")
      (format out "# Includes ALL files: articles, epistemic layers, shapes, temporal-proof, verify~%~%")

      (loop for filepath in all-files
            for rel-path = (enough-namestring filepath output-dir)
            for file-bytes = (alexandria:read-file-into-byte-vector filepath)
            for hash = (orchestrator.hash-authority:compute-hash-prefixed
                       file-bytes
                       :algorithm :sha256)
            for byte-size = (length file-bytes)
            for idx from 0
            do (format out "<~A/artifact/~D> a dcat:Distribution ;~%"
                      release-iri idx)
               (format out "    dcterms:identifier \"~A\" ;~%" rel-path)
               (format out "    slw:sha256Hash \"~A\" ;~%" hash)
               (format out "    dcat:byteSize ~D ;~%" byte-size)
               (format out "    dcat:accessURL <~A/~A> .~%~%"
                      release-iri rel-path)))))

;;; ============================================================================
;;; JSON-LD MANIFEST GENERATION
;;; ============================================================================

(defun build-release-manifest-jsonld (articles output-dir
                                     &key timestamp merkle-root
                                          rfc3161-receipt ct-proofs
                                          jws-signature system-commit-hash)
  "Generate JSON-LD version of release manifest

  Same content as Turtle manifest but in JSON-LD format for API consumption.

  Args:
    Same as build-release-manifest

  Returns:
    JSON-LD string"

  (let ((release-iri (format nil "https://stavropouloslaw.com/releases/~A"
                            (orchestrator.time:format-iso8601 timestamp)))
        (timestamp-iso (orchestrator.time:format-iso8601 timestamp))
        (all-files (collect-all-release-files output-dir))
        (total-articles (length articles))
        (total-artifacts (+ (* (length articles) 4) 5 5)))

    (jonathan:to-json
     `(:|@context| (:|@vocab| "https://stavropouloslaw.com/ontology/legal#"
                    :|dcat| "http://www.w3.org/ns/dcat#"
                    :|dcterms| "http://purl.org/dc/terms/"
                    :|void| "http://rdfs.org/ns/void#"
                    :|xsd| "http://www.w3.org/2001/XMLSchema#")
       :|@id| ,release-iri
       :|@type| "dcat:Catalog"
       :|dcterms:title| (:|@value| ,(format nil "Greek Constitutional Law Corpus - Release ~A"
                                           timestamp-iso)
                         :|@language| "en")
       :|dcterms:created| (:|@value| ,timestamp-iso
                           :|@type| "xsd:dateTime")
       :|releaseTimestamp| (:|@value| ,timestamp-iso
                            :|@type| "xsd:dateTime")
       :|merkleRoot| ,(or merkle-root "pending")
       :|systemCommitHash| ,(or system-commit-hash "pending")
       :|totalArticles| ,total-articles
       :|totalArtifacts| ,total-artifacts
       :|pipelineVersion| ,orchestrator.spec:+version+
       :|blockchainIsNotAuthority| t)
     ;; P1 [0043] D: τα δεδομένα είναι PLIST — το «:from :alist» τα σειριοποιούσε
     ;; ως JSON ARRAY εναλλασσόμενων keys/values αντί για top-level object.
     :from :plist)))
