;;;; systems/orchestrator-epistemic/lineage-authority.lisp
;;;; Layer 3: Identity Lineage (PROV-O Continuity)

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; PROV-O LINEAGE GRAPH GENERATION
;;; ============================================================================

(defun generate-lineage-graph (articles &key (blockchain-anchors nil))
  "Generate PROV-O compliant lineage graph for all articles

  Creates dataset-level lineage file with:
    - Genesis events (origin assertions) for each article
    - Mutation events (if any version changes exist)
    - Blockchain anchors as temporal witnesses

  ARCHITECTURE:
    - Dataset-level graph (not embedded in articles)
    - Articles contain pointers to lineage entries
    - Enables temporal proof without bloating canonical artifacts

  Args:
    articles: List of article objects
    blockchain-anchors: Hash map of article-number -> blockchain-tx-hash

  Returns:
    Turtle string with complete lineage graph"

  ;; P1R [0046]: output-bound timestamp (σειριοποιείται στο canonical
  ;; lineage-graph.ttl ⇒ συμμετέχει στην content-addressed ταυτότητα) —
  ;; ΠΡΕΠΕΙ :deterministic κατά τον νόμο GATE-1, αλλιώς δύο πανομοιότυπα
  ;; cuts θα έπαιρναν διαφορετική ταυτότητα από θόρυβο ρολογιού.
  (let ((genesis-timestamp (orchestrator.time:now :source :deterministic))
        (bc-map (or blockchain-anchors (make-hash-table :test 'eql))))

    (with-output-to-string (out)
      ;; Prefixes
      (format out "~A~%" (format-prefixes))

      ;; Graph metadata
      (format out "# ==============================================================================~%")
      (format out "# STAVROPOULOS LAW - IDENTITY LINEAGE GRAPH~%")
      (format out "# ==============================================================================~%")
      (format out "# PURPOSE: PROV-O compliant identity continuity tracking~%")
      (format out "# STANDARD: W3C PROV-O (https://www.w3.org/TR/prov-o/)~%")
      (format out "# TEMPORAL PROOF: Blockchain + RFC 3161~%")
      (format out "# ==============================================================================~%~%")

      (format out "<https://stavropouloslaw.com/lineage/2025> a prov:Collection ;~%")
      (format out "    dcterms:title \"Greek Constitution Identity Lineage Graph\"@en ;~%")
      (format out "    dcterms:created \"~A\"^^xsd:dateTime ;~%"
              (orchestrator.time:format-iso8601 genesis-timestamp))
      (format out "    dcterms:creator <https://stavropouloslaw.com/identity/org> ;~%")
      (format out "    slw:totalArticles ~D ;~%" (length articles))
      (format out "    rdfs:comment \"\"\"PROV-O lineage graph tracking identity
        continuity of all articles. Each article has genesis event with
        blockchain-backed timestamp.\"\"\"@en .~%~%")

      ;; Generate lineage entries for each article
      (loop for article in articles
            for num = (orchestrator.model:article-number article)
            for eli-uri = (orchestrator.model:article-eli-uri article)
            for hash = (orchestrator.model:article-hash article)
            for bc-anchor = (gethash num bc-map "pending")
            do (format out "~A~%"
                      (generate-origin-assertion article
                                                genesis-timestamp
                                                bc-anchor))))))

;;; ============================================================================
;;; ORIGIN ASSERTION (Genesis Event)
;;; ============================================================================

(defun generate-origin-assertion (article genesis-timestamp blockchain-anchor)
  "Generate PROV-O origin assertion for article genesis

  Creates:
    - prov:Entity (article identity)
    - prov:Activity (genesis generation activity)
    - prov:wasGeneratedBy relationship
    - Blockchain anchor as temporal witness

  Args:
    article: Article object
    genesis-timestamp: Timestamp of genesis event
    blockchain-anchor: Blockchain transaction hash

  Returns:
    Turtle string with genesis assertion"

  (let* ((eli-uri (orchestrator.model:article-eli-uri article))
         ;; P1b [0050]#2: η ΚΑΝΟΝΙΚΗ ταυτότητα («5Α», όχι ο συνθετικός 5001)
         ;; από τη ΜΙΑ έδρα — τα labels/σχόλια του lineage φέρουν την αληθινή
         ;; ταυτότητα, όπως ήδη τα URIs (article-eli-uri).
         (art-id (orchestrator.model:article-uri-id
                  (orchestrator.model:article-number article)
                  (orchestrator.model:article-label article)))
         (hash (orchestrator.model:article-hash article))
         (genesis-iri (format nil "~A/genesis" eli-uri))
         (timestamp-iso (orchestrator.time:format-iso8601 genesis-timestamp)))

    (format nil "# === Article ~A Genesis ===

<~A> a prov:Entity, slw:LegalArticleIdentity ;
    rdfs:label \"Article ~A Identity\"@en ;
    prov:wasGeneratedBy <~A> ;
    slw:identityHash \"~A\" ;
    slw:genesisProof \"~A\" ;
    dcterms:identifier <~A> .

<~A> a prov:Activity, slw:OriginAssertion ;
    rdfs:label \"Article ~A Genesis Event\"@en ;
    prov:startedAtTime \"~A\"^^xsd:dateTime ;
    prov:endedAtTime \"~A\"^^xsd:dateTime ;
    slw:blockchainAnchor \"~A\" ;
    slw:blockchainIsNotAuthority true ;
    prov:wasAssociatedWith <https://stavropouloslaw.com/identity/org> ;
    rdfs:comment \"\"\"Genesis event for Article ~A. Blockchain anchor serves
        as timestamp witness, NOT as truth authority.\"\"\"@en .
"
            art-id
            eli-uri
            art-id
            genesis-iri
            hash
            blockchain-anchor
            eli-uri
            genesis-iri
            art-id
            timestamp-iso
            timestamp-iso
            blockchain-anchor
            art-id)))

;;; ============================================================================
;;; MUTATION EVENT (Version Change)
;;; ============================================================================

(defun generate-mutation-event (article previous-hash current-hash
                               change-type timestamp blockchain-anchor)
  "Generate PROV-O mutation event for version change

  Creates:
    - prov:wasDerivedFrom relationship (continuity proof)
    - Hash before/after for cryptographic verification
    - Mutation type classification
    - Blockchain anchor for timestamp

  Args:
    article: Article object
    previous-hash: SHA-256 hash before mutation
    current-hash: SHA-256 hash after mutation
    change-type: :correction | :amendment | :revision
    timestamp: Mutation timestamp
    blockchain-anchor: Blockchain tx hash

  Returns:
    Turtle string with mutation event"

  (let* ((eli-uri (orchestrator.model:article-eli-uri article))
         ;; P1b [0050]#2: κανονική ταυτότητα από τη ΜΙΑ έδρα — ποτέ συνθετικός.
         (art-id (orchestrator.model:article-uri-id
                  (orchestrator.model:article-number article)
                  (orchestrator.model:article-label article)))
         (current-iri (format nil "~A#version-~A" eli-uri current-hash))
         (previous-iri (format nil "~A#version-~A" eli-uri previous-hash))
         (mutation-iri (format nil "~A/mutation/~A"
                              eli-uri
                              (orchestrator.time:format-iso8601 timestamp)))
         (timestamp-iso (orchestrator.time:format-iso8601 timestamp))
         (change-str (string-downcase (symbol-name change-type))))

    (format nil "# === Article ~A Mutation ===

<~A> a prov:Entity, slw:LegalArticleIdentity ;
    rdfs:label \"Article ~A (Version ~A)\"@en ;
    prov:wasDerivedFrom <~A> ;
    prov:wasGeneratedBy <~A> ;
    slw:identityHash \"~A\" .

<~A> a prov:Activity, slw:MutationEvent ;
    rdfs:label \"Article ~A Mutation (~A)\"@en ;
    slw:mutationType \"~A\" ;
    slw:hashBefore \"~A\" ;
    slw:hashAfter \"~A\" ;
    prov:used <~A> ;
    prov:generated <~A> ;
    prov:startedAtTime \"~A\"^^xsd:dateTime ;
    prov:endedAtTime \"~A\"^^xsd:dateTime ;
    slw:blockchainAnchor \"~A\" ;
    slw:blockchainIsNotAuthority true ;
    prov:wasAssociatedWith <https://stavropouloslaw.com/identity/org> .
"
            art-id
            current-iri
            art-id
            (subseq current-hash 0 (min 8 (length current-hash)))
            previous-iri
            mutation-iri
            current-hash
            mutation-iri
            art-id
            change-str
            change-str
            previous-hash
            current-hash
            previous-iri
            current-iri
            timestamp-iso
            timestamp-iso
            blockchain-anchor)))

;;; ============================================================================
;;; LINEAGE POINTER (For Article Files)
;;; ============================================================================

(defun generate-lineage-pointer (article)
  "Generate minimal lineage pointer for embedding in article TTL

  Creates single triple pointing to genesis event in lineage graph.
  Keeps article files lightweight.

  Args:
    article: Article object

  Returns:
    Turtle triple with lineage pointer"

  (let ((eli-uri (orchestrator.model:article-eli-uri article)))
    (format nil "    prov:wasGeneratedBy <~A/genesis> ;~%"
            eli-uri)))
