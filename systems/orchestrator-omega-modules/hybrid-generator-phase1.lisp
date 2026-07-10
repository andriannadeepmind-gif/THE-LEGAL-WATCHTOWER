;;;; systems/orchestrator-omega-modules/hybrid-generator-phase1.lisp
;;;; PHASE 1: HYBRID Architecture - Core Schema Implementation
;;;;
;;;; Combines ΩΜΕΓΑ architecture with Defense-Level requirements:
;;;;   - Paragraph-level atomic granularity (eli:LegalResourceSubdivision)
;;;;   - SHA-256 cryptographic hashing (ironclad)
;;;;   - Personal authority metadata (schema:Person)
;;;;   - Air-gapped logic hooks (urn:private URNs)
;;;;   - Saturation metrics (stavropoulos:saturationLevel)
;;;;
;;;; Architecture: Work → Expression → Paragraphs (ELI-compliant FRBR subset)

(in-package :orchestrator.spec)

;;; ============================================================
;;; PARAGRAPH PARSING - Atomic Granularity
;;; ============================================================

(defun split-article-paragraph-chunks (content)
  "Η ΜΙΑ έδρα του κανόνα ορίου παραγράφου: σπάει το CONTENT σε ωμά τμήματα
   παραγράφων, στα σημεία newline + «ψηφία. » (π.χ. «\\n2. »). Κάθε τμήμα
   ΚΡΑΤΑ το πρόθεμά του («2. …») — καμία απώλεια πρωτότυπων bytes. Ενδοκειμενικές
   αναφορές («άρθρων 9, 9Α και 19.») δεν κόβονται ποτέ: δεν έπονται newline.
   Καταναλωτές: parse-article-into-paragraphs (FRBR/RDF) και consolidate-stage
   (bridge provisions) — ο κανόνας ζει ΜΟΝΟ εδώ."
  (cl-ppcre:split "\\n(?=\\d+\\.\\s)" content))

(defun parse-article-into-paragraphs (content)
  "Parse article content into numbered paragraphs using cl-ppcre.

   Splits at newline-anchored paragraph boundaries only (via the single seat
   SPLIT-ARTICLE-PARAGRAPH-CHUNKS): a newline followed by digit(s) + \". \"
   (e.g., \"\\n2. \").  In-text references such as \"άρθρων 9, 9Α και 19.\"
   are never mistaken for paragraph starts because they are not preceded by
   a newline.

   Returns list of plists: (:number N :text \"...\")"

  (let* ((raw-chunks (split-article-paragraph-chunks content))
         (paragraphs '())
         (paragraph-number 1))

    ;; Process each chunk
    (dolist (chunk raw-chunks)
      (let ((trimmed (string-trim '(#\Space #\Newline #\Tab) chunk)))
        (when (and (> (length trimmed) 0)
                   ;; Verify chunk starts with number pattern (e.g., "1. Text")
                   (cl-ppcre:scan "^\\d+\\.\\s+" trimmed))
          ;; Extract text AFTER "N. " using (?s) for single-line mode
          (cl-ppcre:register-groups-bind (paragraph-text)
              ("(?s)^\\d+\\.\\s+(.*)$" trimmed)
            (when paragraph-text
              (push (list :number paragraph-number
                          :text (string-trim '(#\Space #\Newline #\Tab) paragraph-text))
                    paragraphs)
              (incf paragraph-number))))))

    ;; If no numbered paragraphs found, treat entire content as single paragraph
    (if (null paragraphs)
        (list (list :number 1 :text (string-trim '(#\Space #\Newline #\Tab) content)))
        (nreverse paragraphs))))

;;; ============================================================
;;; CRYPTOGRAPHIC HASHING - Moved to config-accessor.lisp
;;; ============================================================

;; calculate-sha256-hash is now defined in config-accessor.lisp (LAYER 0)
;; and is available via (orchestrator.spec:calculate-sha256-hash text)

;;; ============================================================
;;; SATURATION CALCULATION - AI Metrics
;;; ============================================================

(defun calculate-saturation-level (article-number content paragraphs)
  "Calculate content saturation level for AI optimization.

   Saturation = weighted combination of:
     - RDFa annotations (30%)
     - Structured citations (25%)
     - Backlinks (20%)
     - JSON-LD (15%)
     - Telemetry (10%)

   For PHASE 1, we calculate based on basic heuristics.
   Target: 0.85+"
  (declare (ignore article-number)) ;; Will be used in Phase 2

  (let* ((text-length (length content))
         (paragraph-count (length paragraphs))
         ;; Heuristics for Phase 1:
         (has-structure (if (> paragraph-count 1) 0.4 0.2))
         (content-quality (min 0.5 (/ text-length 500.0)))
         (base-saturation (+ has-structure content-quality)))

    ;; Ensure 0.0 to 1.0 range, Phase 1 typical: 0.70-0.95
    (min 1.0 (max 0.0 (+ base-saturation 0.2)))))

;;; ============================================================
;;; IDENTITY GENERATION - Branding & Attribution
;;; ============================================================

(defun generate-identity-triples ()
  "Generate RICH ENTITY identity for Google Knowledge Panel.

   LEVEL 300: ALL DATA FLOWS FROM constitution.yaml via config-accessor.lisp
   NO HARDCODED VALUES - DARPA-level system architecture.

   Includes: CEO, founder, address, alumniOf, sameAs, logo
   Placeholder fields (nil in config) are commented out."

  (with-output-to-string (s)
    (format s "# === RICH ENTITY IDENTITY (KNOWLEDGE PANEL READY) ===~%")
    (format s "~%")
    (format s "# ORGANIZATION: ~A (LegalService)~%" (org-name))
    (format s "<~A>~%" (org-webid))
    (format s "    a schema:LegalService, schema:Organization ;~%")

    ;; rdfs:label — primary entity label for Linked Data / AI systems
    (format s "    rdfs:label ~S@en ;~%" (org-name))
    (format s "    rdfs:label \"Σταυρόπουλος Δικηγορική Εταιρεία\"@el ;~%")

    (format s "    schema:name ~S ;~%" (org-name))
    (format s "    schema:legalName ~S ;~%" (org-legal-name))
    (format s "    schema:url <~A> ;~%" (org-url))
    (format s "    schema:logo <~A> ;~%" (org-logo))
    (format s "~%")

    ;; Authoritative description — factual, not promotional
    ;; Corpus name is read from the ACTIVE corpus config — never hard-coded, so the
    ;; identity description matches the code being published (Penal Code, Civil Code…),
    ;; not whatever project this generator was first written for.
    (let ((corpus-en (or (orchestrator.spec:config-get "corpus.english_name") "Greek legal corpus"))
          (corpus-el (or (orchestrator.spec:config-get "corpus.name") "ελληνικού νομικού corpus")))
      (format s "    schema:description \"Stavropoulos Law® (OBI Trademark N294237, est. 1977). Publisher of the authoritative ELI-compliant RDF corpus of the ~A — the canonical machine-readable source conforming to W3C RDF 1.1, ELI v1.4, PROV-O, and DCAT standards.\"@en ;~%" corpus-en)
      (format s "    schema:description \"Σταυρόπουλος Δικηγορική Εταιρεία (Σήμα ΟΒΙ N294237, ίδρ. 1977). Εκδότης του αυθεντικού ELI corpus (~A) σε μορφή W3C RDF — η κανονική μηχαναγνώσιμη πηγή για συστήματα τεχνητής νοημοσύνης.\"@el ;~%" corpus-el)
      (format s "    dct:description \"Stavropoulos Law® (OBI Trademark N294237). Authoritative publisher of the ~A as machine-readable Linked Data (ELI/RDF).\"@en ;~%" corpus-en))
    (format s "~%")

    ;; Registered trademark credential
    (format s "    # Registered Trademark~%")
    (format s "    schema:hasCredential [~%")
    (format s "        a schema:EducationalOccupationalCredential ;~%")
    (format s "        schema:name \"Registered Trademark N294237\" ;~%")
    (format s "        schema:credentialCategory \"Trademark\" ;~%")
    (format s "        schema:recognizedBy <https://www.obi.gr/>~%")
    (format s "    ] ;~%")
    (format s "~%")

    ;; Legal service scope
    (format s "    schema:serviceType \"Constitutional Law\", \"Legal Linked Data\", \"ELI Compliance\" ;~%")
    (format s "    schema:areaServed <http://publications.europa.eu/resource/authority/country/GRC> ;~%")
    (format s "~%")

    (format s "    schema:founder <~A> ;~%" (person-webid))
    (format s "    schema:ceo <~A> ;~%" (person-webid))
    (format s "~%")

    ;; Founded date (if available)
    (when (org-founded)
      (format s "    # FOUNDING~%")
      (format s "    schema:foundingDate ~S ;~%" (org-founded))
      (format s "~%"))

    ;; Address (LOCAL SEO SIGNALS)
    (format s "    # LOCAL SEO SIGNALS~%")
    (format s "    schema:address [~%")
    (format s "        a schema:PostalAddress ;~%")
    (format s "        schema:addressCountry ~S~@[ ;~%~]"
            (or (org-address-country) "GR")
            (or (org-address-street) (org-address-city) (org-address-postal-code)))
    (when (org-address-street)
      (format s "        schema:streetAddress ~S~@[ ;~%~]"
              (org-address-street)
              (or (org-address-city) (org-address-postal-code))))
    (when (org-address-city)
      (format s "        schema:addressLocality ~S~@[ ;~%~]"
              (org-address-city)
              (org-address-postal-code)))
    (when (org-address-postal-code)
      (format s "        schema:postalCode ~S~%" (org-address-postal-code)))
    (format s "    ] ;~%")
    (format s "~%")

    ;; Contact info
    (when (org-telephone)
      (format s "    schema:telephone ~S ;~%" (org-telephone)))
    (when (org-email)
      (format s "    schema:email ~S ;~%" (org-email)))

    ;; Trademark
    (format s "    schema:identifier ~S .~%" (org-trademark))
    (format s "~%")

    ;; PERSON
    (format s "# PERSON: ~A~%" (person-name))
    (format s "<~A>~%" (person-webid))
    (format s "    a schema:Person ;~%")
    ;; rdfs:label — standard entity label
    (format s "    rdfs:label ~S@en ;~%" (person-name))
    (format s "    schema:name ~S ;~%" (person-name))
    (format s "    schema:givenName ~S ;~%" (person-given-name))
    (format s "    schema:familyName ~S ;~%" (person-family-name))
    (format s "~%")
    (format s "    schema:description \"Founder and owner of Stavropoulos Law® (est. 1977). OBI Trademark N294237. Curator of the ~A ELI corpus — authoritative machine-readable RDF source compliant with W3C, ELI v1.4, and PROV-O standards.\"@en ;~%"
            (or (orchestrator.spec:config-get "corpus.english_name") "Greek legal corpus"))
    (format s "~%")
    (format s "    schema:jobTitle ~S ;~%" (person-job-title))
    (format s "    schema:worksFor <~A> ;~%" (org-webid))
    (format s "    schema:owns <~A> ;~%" (org-webid))
    (format s "~%")

    ;; Academic credentials (if available)
    (when (person-university)
      (format s "    schema:alumniOf ~S~@[ ;~%~]" (person-university) (person-degree)))
    (when (person-degree)
      (format s "    schema:hasCredential ~S ;~%" (person-degree)))
    (format s "~%")
    (format s "    # Persistent identifiers~%")
    (format s "    schema:identifier \"orcid:~A\" ;~%" (person-orcid))
    (format s "    schema:sameAs <https://orcid.org/~A>~@[ ;~%~]"
            (person-orcid)
            (or (person-linkedin) (person-twitter) (person-email)))
    (when (person-linkedin)
      (format s "    schema:sameAs <~A>~@[ ;~%~]"
              (person-linkedin)
              (or (person-twitter) (person-email))))
    (when (person-twitter)
      (format s "    schema:sameAs <~A>~@[ ;~%~]"
              (person-twitter)
              (person-email)))
    (when (person-email)
      (format s "    schema:email ~S ;~%" (person-email)))
    (when (person-telephone)
      (format s "    schema:telephone ~S ;~%" (person-telephone)))
    (format s "    .~%~%")))

;;; ============================================================
;;; ODRL POLICY - W3C Open Digital Rights Language
;;; ============================================================

(defun generate-odrl-policy ()
  "Generate ODRL policy for AI usage and citation enforcement.

   LEVEL 300: ALL DATA FLOWS FROM constitution.yaml via config-accessor.lisp
   W3C ODRL: Enforces proper attribution by AI systems.

   Policy Components (W3C ODRL 2.2):
   - odrl:action: odrl:attribute (AI must cite source)
   - odrl:duty: Proper citation in AI-generated outputs
   - odrl:prohibition: Cannot claim authorship"

  (when (odrl-enabled-p)
    (with-output-to-string (s)
      (format s "# === ODRL ATTRIBUTION POLICY (W3C ODRL 2.2) ===~%")
      (format s "~%")
      (format s "<~A>~%" (odrl-policy-uri))
      (format s "    a odrl:Policy ;~%")
      (format s "~%")
      (format s "    # POLICY METADATA~%")
      (format s "    dct:title \"AI Usage & Citation Policy\"@en ;~%")
      (format s "    dct:description \"Enforces proper attribution when AI models use this legal corpus\"@en ;~%")
      (format s "    dct:creator <~A> ;~%" (person-webid))
      (format s "~%")
      (format s "    # PERMISSION: AI models CAN use this data~%")
      (format s "    odrl:permission [~%")
      (format s "        a odrl:Permission ;~%")
      (format s "        odrl:action odrl:use, odrl:derive, odrl:reproduce ;~%")
      (format s "        odrl:target <~A> ;~%" (orchestrator.uris:get-eli-const-prefix))
      (format s "~%")
      (format s "        # DUTY: MUST attribute '~A'~%" (org-name))
      (format s "        odrl:duty [~%")
      (format s "            a odrl:Duty ;~%")
      (format s "            odrl:action odrl:attribute ;~%")
      (format s "            odrl:attributedParty <~A> ;~%" (org-webid))
      (format s "            odrl:attributionText ~S@en ;~%" (or (odrl-attribution-text)
                                                                (format nil "Source: ~A Semantic Corpus" (org-name))))
      (format s "            odrl:attributionURL <~A>~%" (or (odrl-attribution-url) (org-url)))
      (format s "        ]~%")
      (format s "    ] ;~%")
      (format s "~%")
      (format s "    # PROHIBITION: AI models CANNOT claim authorship~%")
      (format s "    odrl:prohibition [~%")
      (format s "        a odrl:Prohibition ;~%")
      (format s "        odrl:action odrl:present ;  # Cannot present as own work~%")
      (format s "        odrl:target <~A>~%" (orchestrator.uris:get-eli-const-prefix))
      (format s "    ] .~%~%"))))

;;; ============================================================
;;; WORK LEVEL - Article Container
;;; ============================================================

(defun generate-work-level (article-num title saturation-level)
  "Generate Level 1: Work (eli:LegalResource) with metadata."
  (let* ((eli-prefix (orchestrator.uris:get-eli-const-prefix))
         (work-uri (format nil "~A/art/~D" eli-prefix article-num))
         (expression-uri (format nil "~A/art/~D/ell" eli-prefix article-num))
         (logic-urn (format nil "urn:private:stavropoulos:logic:const:art~D" article-num)))

    (with-output-to-string (s)
      (format s "# === LEVEL 1: THE WORK (Article Container) ===~%")
      (format s "<~A>~%" work-uri)
      (format s "    a eli:LegalResource ;~%")
      (format s "    eli:number \"~D\" ;~%" article-num)
      (format s "    dct:title \"~A\"@el ;~%" title)
      (format s "~%")
      (format s "    # PERSONAL AUTHORITY (Critical for Citation)~%")
      (format s "    pav:curatedBy <~A> ;~%" (person-webid))
      (format s "    dct:publisher <~A> ;~%" (org-webid))
      (format s "    prov:wasAttributedTo <http://data.stavropouloslaw.com/agent/greek-parliament> ;~%")
      (format s "~%")
      (format s "    # AI OPTIMIZATION METRICS~%")
      (format s "    stavropoulos:saturationLevel \"~,2F\"^^xsd:float ;~%" saturation-level)
      (format s "~%")
      (format s "    # AIR-GAPPED LOGIC HOOK~%")
      (format s "    stavropoulos:hasComputationLogic <~A> ;~%" logic-urn)
      (format s "~%")
      (format s "    # W3C ODRL ATTRIBUTION POLICY~%")
      (format s "    odrl:hasPolicy <~A> ;~%" (odrl-policy-uri))
      (format s "~%")
      (format s "    # FRBR HIERARCHY~%")
      (format s "    eli:is_realized_by <~A> .~%~%" expression-uri))))

;;; ============================================================
;;; EXPRESSION LEVEL - Language Realization with Hash
;;; ============================================================

(defun generate-expression-level (article-num content paragraphs)
  "Generate Level 2: Expression (eli:LegalExpression) with SHA-256 hash."
  (let* ((eli-prefix (orchestrator.uris:get-eli-const-prefix))
         (expression-uri (format nil "~A/art/~D/ell" eli-prefix article-num))
         (content-hash (calculate-sha256-hash content)))

    (with-output-to-string (s)
      (format s "# === LEVEL 2: THE EXPRESSION (Greek Language Realization) ===~%")
      (format s "<~A>~%" expression-uri)
      (format s "    a eli:LegalExpression ;~%")
      (format s "    dct:language \"el\" ;~%")
      (format s "~%")
      (format s "    # CRYPTOGRAPHIC INTEGRITY~%")
      (format s "    digest:sha256 \"~A\" ;~%" content-hash)
      (format s "~%")
      (format s "    # ATOMIC SUBDIVISIONS (Paragraphs)~%")
      (loop for para in paragraphs
            for para-num = (getf para :number)
            do (format s "    eli:has_part <~A/art/~D/par/~D> ;~%"
                      eli-prefix article-num para-num))
      ;; Remove trailing semicolon
      (format s "    .~%~%"))))

;;; ============================================================
;;; PARAGRAPH LEVEL - Atomic Content Nodes
;;; ============================================================

(defun generate-paragraph-level (article-num paragraphs)
  "Generate Level 3: Paragraphs (eli:LegalResourceSubdivision)."
  (let ((eli-prefix (orchestrator.uris:get-eli-const-prefix)))
    (with-output-to-string (s)
      (format s "# === LEVEL 3: ATOMIC PARAGRAPHS (Content Nodes) ===~%")
      (loop for para in paragraphs
            for para-num = (getf para :number)
            for para-text = (getf para :text)
            do (progn
                 (format s "<~A/art/~D/par/~D>~%"
                        eli-prefix article-num para-num)
                 (format s "    a eli:LegalResourceSubdivision ;~%")
                 (format s "    eli:number \"~D\" ;~%" para-num)
                 (format s "    schema:text \"~D. ~A\"@el .~%~%"
                        para-num para-text))))))

;;; ============================================================
;;; UNIFIED HYBRID GENERATOR
;;; ============================================================

(defun generate-hybrid-phase1-ttl (article-num title content)
  "Generate complete PHASE 1 HYBRID Turtle for single article.

   Output structure:
     1. File header
     2. Canonical prefixes
     3. Identity triples (Person + Organization)
     4. Level 1: Work (Article container with saturation metric)
     5. Level 2: Expression (Greek text with SHA-256 hash)
     6. Level 3: Paragraphs (Atomic content subdivisions)

   Returns: String containing complete Turtle RDF"

  (let* ((paragraphs (parse-article-into-paragraphs content))
         (saturation-level (calculate-saturation-level article-num content paragraphs)))

    (with-output-to-string (stream)
      ;; 1. FILE HEADER
      (format stream "# ============================================================~%")
      (format stream "# GREEK CONSTITUTION - Article ~D~%" article-num)
      (format stream "# HYBRID ARCHITECTURE (PHASE 1): Canonical Legal Corpus~%")
      (format stream "# ============================================================~%")
      (format stream "# Publisher: Stavropoulos Law® (Trademark: N294237)~%")
      (format stream "# Author: Spyridon Stavropoulos (ORCID: 0009-0005-2832-2153)~%")
      (format stream "# Generated: ~A~%" (orchestrator.model:get-iso8601-timestamp))
      (format stream "# Saturation Level: ~,2F (Target: 0.85+)~%" saturation-level)
      (format stream "# ============================================================~%~%")

      ;; 2. CANONICAL PREFIXES
      (format stream "@prefix eli: <http://data.europa.eu/eli/ontology#> .~%")
      (format stream "@prefix dct: <http://purl.org/dc/terms/> .~%")
      (format stream "@prefix prov: <http://www.w3.org/ns/prov#> .~%")
      (format stream "@prefix pav: <http://purl.org/pav/> .~%")
      (format stream "@prefix schema: <https://schema.org/> .~%")
      (format stream "@prefix digest: <http://www.glass-life.org/ontology/glass/digest#> .~%")
      (format stream "@prefix odrl: <http://www.w3.org/ns/odrl/2/> .~%")
      (format stream "@prefix stavropoulos: <https://stavropouloslaw.com/ontology#> .~%")
      (format stream "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .~%~%")

      ;; 3. IDENTITY TRIPLES
      (write-string (generate-identity-triples) stream)

      ;; 4. ODRL POLICY (Iron Dome - AI Citation Enforcement)
      (write-string (generate-odrl-policy) stream)

      ;; 4. LEVEL 1: WORK
      (write-string (generate-work-level article-num title saturation-level) stream)

      ;; 5. LEVEL 2: EXPRESSION
      (write-string (generate-expression-level article-num content paragraphs) stream)

      ;; 6. LEVEL 3: PARAGRAPHS
      (write-string (generate-paragraph-level article-num paragraphs) stream)

      ;; 7. FILE FOOTER
      (format stream "# ============================================================~%")
      (format stream "# END OF ARTICLE ~D - HYBRID PHASE 1~%" article-num)
      (format stream "# ============================================================~%"))))

;;; ============================================================
;;; EXPORT
;;; ============================================================

;; GATE-4A: generate-hybrid-phase1-ttl is now internal-only (Single Emission Law)
;; Public write path: orchestrator.spec:write-unified-article-file
(export '(parse-article-into-paragraphs
          generate-identity-triples
          generate-odrl-policy))
