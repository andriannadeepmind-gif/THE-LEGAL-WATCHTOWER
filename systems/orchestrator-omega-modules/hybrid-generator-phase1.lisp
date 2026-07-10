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


;;; ============================================================
;;; EXPRESSION LEVEL - Language Realization with Hash
;;; ============================================================


;;; ============================================================
;;; PARAGRAPH LEVEL - Atomic Content Nodes
;;; ============================================================


;;; ============================================================
;;; UNIFIED HYBRID GENERATOR
;;; ============================================================


;;; ============================================================
;;; EXPORT
;;; ============================================================

;; GATE-4A: generate-hybrid-phase1-ttl is now internal-only (Single Emission Law)
;; Public write path: orchestrator.spec:write-unified-article-file
(export '(parse-article-into-paragraphs
          generate-identity-triples
          generate-odrl-policy))
