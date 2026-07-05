;;;; systems/orchestrator-omega-modules/html-rdfa-generator.lisp
;;;; PHASE 2: HTML + RDFa Generator for SEO & Google Panels
;;;;
;;;; Generates SEO-ready HTML pages with:
;;;;   - RDFa embedded markup (for crawlers)
;;;;   - JSON-LD structured data (for Google)
;;;;   - Schema.org LegalService + Person
;;;;   - Placeholder fields for contact info (address, phone, email)
;;;;
;;;; Architecture: Turtle RDF → HTML with RDFa → Google-crawlable

(in-package :orchestrator.spec)

;;; ============================================================
;;; ARTICLE IDENTIFIER (preserves lettered articles, e.g. 100Α)
;;; ============================================================
;;;
;;; ARTICLE-NUM is the article's display identifier as a STRING — "100" for a
;;; plain article, "100Α" for a lettered one. Rendering it with ~A (not ~D)
;;; keeps the letter suffix in every title / eId / URI, so article 100 and
;;; article 100Α never collapse onto the same resource.

(defun %article-heading (article-num title)
  "'Άρθρο N - Title', or just 'Άρθρο N' when the article has no distinct title
   (a transitional/repealing provision) — so it never reads 'Άρθρο N - Άρθρο N'."
  (if (and title (plusp (length (string-trim " " (princ-to-string title)))))
      (format nil "Άρθρο ~A - ~A" article-num title)
      (format nil "Άρθρο ~A" article-num)))

(defun %display-title (article-num title)
  "The article's bare title, or 'Άρθρο N' when it has none — so a no-title
   provision never serializes an empty name."
  (if (and title (plusp (length (string-trim " " (princ-to-string title)))))
      title
      (format nil "Άρθρο ~A" article-num)))

(defun %pad-article-id (id)
  "Zero-pad the numeric prefix of an article id to 3 digits, preserving any
   letter suffix: 1 -> \"001\", \"100Α\" -> \"100Α\". Used for the stable
   legislationIdentifier, matching the on-disk article-file-id. Delegates to the
   single source of truth ORCHESTRATOR.MODEL:PAD-ARTICLE-ID (no reimplementation)."
  (let* ((s (princ-to-string id))
         (end (or (position-if-not #'digit-char-p s) (length s)))
         (digits (subseq s 0 end))
         (suffix (subseq s end)))
    (if (plusp (length digits))
        (orchestrator.model:pad-article-id (parse-integer digits) suffix)
        s)))

;;; ============================================================
;;; CONFIGURATION - LEVEL 300: Reads from constitution.yaml
;;; ============================================================

;; NOTE: All identity metadata now flows from config-accessor.lisp
;; which loads constitution.yaml
;;
;; Available accessors:
;;   - person-name, person-given-name, person-family-name, etc.
;;   - org-name, org-legal-name, org-url, org-logo, etc.
;;   - org-address-street, org-address-city, etc. (may be nil)
;;
;; NO MORE HARDCODED VALUES - This is the SYSTEM way!

;;; ============================================================
;;; HTML HEADER - SEO Meta Tags
;;; ============================================================

(defun generate-html-head (article-num title)
  "Generate HTML <head> with SEO meta tags"
  (with-output-to-string (s)
    (format s "<!DOCTYPE html>~%")
    (format s "<html lang=\"el\" prefix=\"~
               eli: http://data.europa.eu/eli/ontology# ~
               dct: http://purl.org/dc/terms/ ~
               schema: https://schema.org/ ~
               prov: http://www.w3.org/ns/prov#\">~%")
    (format s "<head>~%")
    (format s "  <meta charset=\"UTF-8\">~%")
    (format s "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">~%")
    (format s "~%")
    (format s "  <!-- SEO Meta Tags -->~%")
    (format s "  <title>~A | Stavropoulos Law®</title>~%" (escape-html (%article-heading article-num title)))
    (format s "  <meta name=\"description\" content=\"~A, ~A. Defense-grade semantic corpus by Stavropoulos Law®.\">~%"
            (escape-html (or (config-get "corpus.name") "Νομικό Κείμενο"))
            (escape-html (%article-heading article-num title)))
    (format s "  <meta name=\"keywords\" content=\"~A, Ελλάδα, Άρθρο ~A, νομική, ELI, RDF\">~%"
            (escape-html (or (config-get "corpus.name") "Νόμος")) article-num)
    (format s "  <meta name=\"author\" content=\"Spyridon Stavropoulos\">~%")
    (format s "  <meta name=\"robots\" content=\"index, follow\">~%")
    (format s "  <link rel=\"canonical\" href=\"~A/art/~A\">~%"
            (config-get "corpus.eli_prefix") article-num)
    (format s "~%")
    (format s "  <!-- Open Graph (Facebook, LinkedIn) -->~%")
    (format s "  <meta property=\"og:title\" content=\"~A\">~%" (escape-html (%article-heading article-num title)))
    (format s "  <meta property=\"og:description\" content=\"~A - Defense-grade semantic corpus\">~%"
            (escape-html (or (config-get "corpus.name") "Legal Corpus")))
    (format s "  <meta property=\"og:type\" content=\"article\">~%")
    (format s "  <meta property=\"og:url\" content=\"~A/art/~A\">~%"
            (config-get "corpus.eli_prefix") article-num)
    (format s "~%")
    (format s "  <!-- Twitter Card -->~%")
    (format s "  <meta name=\"twitter:card\" content=\"summary\">~%")
    (format s "  <meta name=\"twitter:title\" content=\"~A\">~%" (escape-html (%article-heading article-num title)))
    (format s "~%")

    ;; CSS Styles (from Jinja2 template)
    (format s "  <!-- Styles -->~%")
    (format s "  <style>~%")
    (format s "    body {~%")
    (format s "      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;~%")
    (format s "      line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; color: #333;~%")
    (format s "    }~%")
    (format s "    article { background: white; padding: 30px; border-radius: 8px;~%")
    (format s "              box-shadow: 0 2px 10px rgba(0,0,0,0.1); }~%")
    (format s "    h1, h2 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }~%")
    (format s "    .metadata { background: #f8f9fa; padding: 15px; border-left: 4px solid #3498db;~%")
    (format s "                margin: 20px 0; font-size: 0.9em; }~%")
    (format s "    .article-content { text-align: justify; line-height: 1.8; }~%")
    (format s "    .blockchain-proof { background: #f0f8ff; padding: 15px; border-radius: 4px;~%")
    (format s "                        font-family: monospace; font-size: 0.85em; margin-top: 20px; }~%")
    (format s "    .blockchain-proof code { word-break: break-all; }~%")
    (format s "    footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #dee2e6;~%")
    (format s "             font-size: 0.9em; color: #6c757d; }~%")
    (format s "    @media print { body { max-width: none; } article { box-shadow: none; } }~%")
    (format s "  </style>~%")
    (format s "~%")

    ;; Telemetry Beacon — PRIVACY BY DEFAULT. Emitted ONLY when telemetry is
    ;; explicitly enabled (telemetry.enabled), which now defaults to NIL. A reader
    ;; of a published legal article is never tracked (userAgent/referrer) without an
    ;; explicit opt-in — matching the static-site generator, which carries no beacon.
    (when (telemetry-enabled-p)
      (format s "  <!-- Telemetry Beacon for AI Citation Tracking -->~%")
      (format s "  <script>~%")
      (format s "  (function() {~%")
      (format s "    var telemetryData = {~%")
      (format s "      article: '~A',~%" article-num)
      (format s "      corpus: '~A',~%" (or (config-get "corpus.short_name") "corpus"))
      (format s "      timestamp: Date.now(),~%")
      (format s "      referrer: document.referrer,~%")
      (format s "      userAgent: navigator.userAgent,~%")
      (format s "      eli_uri: '~A/art/~A',~%" (orchestrator.uris:get-eli-const-prefix) article-num)
      (format s "      event: 'page_view'~%")
      (format s "    };~%")
      (format s "    if (navigator.sendBeacon) {~%")
      (format s "      navigator.sendBeacon('~A', JSON.stringify(telemetryData));~%" (telemetry-endpoint))
      (format s "    }~%")
      (format s "  })();~%")
      (format s "  </script>~%"))
    (format s "~%")
    (format s "</head>~%")))

;;; ============================================================
;;; JSON-LD STRUCTURED DATA - Schema.org
;;; ============================================================

(defun generate-jsonld-organization ()
  "Generate RICH JSON-LD for organization (Knowledge Panel Ready)

   LEVEL 300: All data flows from constitution.yaml via config accessors
   TIER 2: Enhanced with contactPoint for Google Business Profile"

  (with-output-to-string (s)
    (format s "{~%")
    (format s "  \"@context\": \"https://schema.org\",~%")
    (format s "  \"@type\": [\"LegalService\", \"Organization\"],~%")
    (format s "  \"@id\": ~S,~%" (org-webid))
    (format s "  \"name\": ~S,~%" (org-name))
    (format s "  \"legalName\": ~S,~%" (org-legal-name))
    (format s "  \"url\": ~S,~%" (org-url))
    (format s "  \"logo\": ~S,~%" (org-logo))
    (format s "  \"identifier\": ~S,~%" (org-trademark))

    ;; Founded year (if available)
    (when (org-founded)
      (format s "  \"foundingDate\": ~S,~%" (org-founded)))

    (format s "~%")

    ;; FOUNDER
    (format s "  \"founder\": {~%")
    (format s "    \"@type\": \"Person\",~%")
    (format s "    \"@id\": ~S,~%" (person-webid))
    (format s "    \"name\": ~S,~%" (person-name))
    (format s "    \"givenName\": ~S,~%" (person-given-name))
    (format s "    \"familyName\": ~S,~%" (person-family-name))
    (format s "    \"jobTitle\": ~S,~%" (person-job-title))
    (format s "    \"identifier\": ~S,~%" (person-orcid))

    ;; Social proof (sameAs)
    (format s "    \"sameAs\": [~%")
    (format s "      \"https://orcid.org/~A\"" (person-orcid))
    (when (person-linkedin)
      (format s ",~%      ~S" (person-linkedin)))
    (when (person-twitter)
      (format s ",~%      ~S" (person-twitter)))
    (when (person-email)
      (format s ",~%      \"mailto:~A\"" (person-email)))
    (format s "~%    ]")

    ;; Academic credentials (if available)
    (when (person-university)
      (format s ",~%    \"alumniOf\": ~S" (person-university)))

    (format s "~%  },~%")
    (format s "~%")

    ;; CEO (reference to same person)
    (format s "  \"ceo\": {~%")
    (format s "    \"@id\": ~S~%" (person-webid))
    (format s "  },~%")
    (format s "~%")

    ;; Organization contact info
    (when (org-telephone)
      (format s "  \"telephone\": ~S,~%" (org-telephone)))
    (when (org-email)
      (format s "  \"email\": ~S,~%" (org-email)))

    ;; ContactPoint - TIER 2 Enhancement for Google Business Profile
    (when (or (org-telephone) (org-email))
      (format s "  \"contactPoint\": {~%")
      (format s "    \"@type\": \"ContactPoint\",~%")
      (when (org-telephone)
        (format s "    \"telephone\": ~S,~%" (org-telephone)))
      (when (org-email)
        (format s "    \"email\": ~S,~%" (org-email)))
      (format s "    \"contactType\": \"Legal Services\",~%")
      (format s "    \"availableLanguage\": [\"Greek\", \"English\"]~%")
      (format s "  },~%"))

    ;; Address
    (format s "  \"address\": {~%")
    (format s "    \"@type\": \"PostalAddress\",~%")
    (when (org-address-street)
      (format s "    \"streetAddress\": ~S,~%" (org-address-street)))
    (when (org-address-city)
      (format s "    \"addressLocality\": ~S,~%" (org-address-city)))
    (when (org-address-postal-code)
      (format s "    \"postalCode\": ~S,~%" (org-address-postal-code)))
    (when (org-address-region)
      (format s "    \"addressRegion\": ~S,~%" (org-address-region)))
    (format s "    \"addressCountry\": ~S~%" (org-address-country))
    (format s "  },~%")

    ;; Organization sameAs - TIER 2: External authority links
    (format s "  \"sameAs\": [~%")
    (format s "    ~S" (org-url))
    (when (org-linkedin)
      (format s ",~%    ~S" (org-linkedin)))
    (when (org-twitter)
      (format s ",~%    ~S" (org-twitter)))
    (format s "~%  ]~%")

    (format s "}~%")))

(defun generate-jsonld-breadcrumb (article-num title)
  "Generate Schema.org BreadcrumbList for Google rich results

   TIER 2: Enables breadcrumb display in Google Search results

   Structure: Home → Σύνταγμα → Άρθρο N"

  (with-output-to-string (s)
    (format s "{~%")
    (format s "  \"@context\": \"https://schema.org\",~%")
    (format s "  \"@type\": \"BreadcrumbList\",~%")
    (format s "  \"itemListElement\": [~%")

    ;; Level 1: Home
    (format s "    {~%")
    (format s "      \"@type\": \"ListItem\",~%")
    (format s "      \"position\": 1,~%")
    (format s "      \"name\": \"Αρχική\",~%")
    (format s "      \"item\": \"https://stavropouloslaw.com\"~%")
    (format s "    },~%")

    ;; Level 2: Corpus
    (format s "    {~%")
    (format s "      \"@type\": \"ListItem\",~%")
    (format s "      \"position\": 2,~%")
    (format s "      \"name\": ~S,~%" (or (config-get "corpus.name") (config-get "corpus.english_name") "Legal Corpus"))
    (format s "      \"item\": ~S~%" (orchestrator.uris:get-eli-const-prefix))
    (format s "    },~%")

    ;; Level 3: Current Article
    (format s "    {~%")
    (format s "      \"@type\": \"ListItem\",~%")
    (format s "      \"position\": 3,~%")
    (format s "      \"name\": \"~A\",~%" (escape-json-string (%article-heading article-num title)))
    (format s "      \"item\": \"~A/art/~A\"~%" (orchestrator.uris:get-eli-const-prefix) article-num)
    (format s "    }~%")

    (format s "  ]~%")
    (format s "}~%")))

(defun generate-jsonld-faq (article-num title paragraphs)
  "Generate Schema.org FAQPage for Google featured snippets

   TIER 2: Enables FAQ rich results and featured snippets

   Generates Q&A pairs based on article content"

  (with-output-to-string (s)
    (format s "{~%")
    (format s "  \"@context\": \"https://schema.org\",~%")
    (format s "  \"@type\": \"FAQPage\",~%")
    (format s "  \"mainEntity\": [~%")

    ;; Question 1: What does this article define?
    (format s "    {~%")
    (format s "      \"@type\": \"Question\",~%")
    (format s "      \"name\": \"~A\",~%"
            (escape-json-string
             (format nil "Τι ορίζει το Άρθρο ~A (~A);"
                     article-num (or (config-get "corpus.name") "νόμου"))))
    (format s "      \"acceptedAnswer\": {~%")
    (format s "        \"@type\": \"Answer\",~%")
    (let ((first-para-text (when paragraphs
                             (getf (first paragraphs) :text)))
          ;; only show "(title)" when the article actually has a title
          (ttl (let ((tt (string-trim " " (princ-to-string (or title "")))))
                 (and (plusp (length tt)) tt))))
      (format s "        \"text\": \"~A\"~%"
              (escape-json-string
               (if first-para-text
                   (format nil "Το Άρθρο ~A~@[ (~A)~] ορίζει: ~A"
                           article-num ttl first-para-text)
                   (format nil "Το Άρθρο ~A αφορά: ~A"
                           article-num (%display-title article-num title))))))
    (format s "      }~%")
    (format s "    }~%")

    ;; Question 2: How many paragraphs?
    (when paragraphs
      (format s "    ,{~%")
      (format s "      \"@type\": \"Question\",~%")
      (format s "      \"name\": \"~A\",~%" (escape-json-string (format nil "Πόσες παραγράφους έχει το Άρθρο ~A;" article-num)))
      (format s "      \"acceptedAnswer\": {~%")
      (format s "        \"@type\": \"Answer\",~%")
      (format s "        \"text\": \"~A\"~%"
              (escape-json-string
               (format nil "Το Άρθρο ~A περιλαμβάνει ~D ~A που διέπουν το θέμα: ~A"
                       article-num (length paragraphs)
                       (if (= (length paragraphs) 1) "παράγραφο" "παραγράφους")
                       (%display-title article-num title))))
      (format s "      }~%")
      (format s "    }~%"))

    (format s "  ]~%")
    (format s "}~%")))

(defun generate-jsonld-article (article-num title content-hash
                                &key eli-prefix document-type issued-date)
  "Generate JSON-LD for legal article.

   Keyword params override config when generating for a specific law type;
   omit them to use constitution.yaml defaults (Constitution corpus default path)."
  (let* ((resolved-eli-prefix (or eli-prefix
                                  (config-get "corpus.eli_prefix")
                                  (error "corpus.eli_prefix not configured")))
         (resolved-doc-type   (or document-type
                                  (config-get "corpus.document_type")
                                  "const"))
         (resolved-issued     (or issued-date
                                  (config-get "corpus.publication.date")
                                  (error "corpus.publication.date not configured")))
         (resolved-year       (subseq resolved-issued 0 4))
         (legislation-type    (orchestrator.model:law-type-schema-legislation-type
                                resolved-doc-type)))
    (with-output-to-string (s)
      (format s "{~%")
      (format s "  \"@context\": \"https://schema.org\",~%")
      (format s "  \"@type\": \"Legislation\",~%")
      (format s "  \"@id\": \"~A/art/~A\",~%" resolved-eli-prefix article-num)
      (format s "  \"name\": \"~A\",~%" (escape-json-string (%display-title article-num title)))
      (format s "  \"legislationIdentifier\": \"gr-~A-~A-art-~A\",~%"
              resolved-doc-type resolved-year (%pad-article-id article-num))
      (format s "  \"legislationJurisdiction\": \"Greece\",~%")
      (format s "  \"legislationType\": \"~A\",~%" legislation-type)
      (format s "  \"publisher\": {~%")
      (format s "    \"@type\": \"LegalService\",~%")
      (format s "    \"@id\": ~S,~%" (org-webid))
      (format s "    \"name\": ~S~%" (org-name))
      (format s "  },~%")
      (format s "  \"author\": {~%")
      (format s "    \"@type\": \"Organization\",~%")
      (format s "    \"name\": \"Greek Parliament\"~%")
      (format s "  },~%")
      (format s "  \"datePublished\": \"~A\",~%" resolved-issued)
      ;; dateModified intentionally omitted — requires per-article amendment tracking
      (format s "  \"inLanguage\": \"el\",~%")
      (format s "  \"sha256\": ~S~%" content-hash)
      (format s "}~%"))))

;;; ============================================================
;;; ARTICLE HTML BODY - RDFa Embedded
;;; ============================================================

(defun generate-article-body (article-num title paragraphs content-hash &key blockchain-proof)
  "Generate HTML article body content with RDFa attributes (without <body> tags)

   Arguments:
     article-num:     Article number
     title:           Article title
     paragraphs:      List of paragraph plists
     content-hash:    SHA-256 hash of content
     blockchain-proof: Optional plist with :ethereum, :arweave, :ipfs keys"
  (with-output-to-string (s)
    (format s "  <!-- Header -->~%")
    (format s "  <header>~%")
    (format s "    <h1>~A</h1>~%" (escape-html (or (config-get "corpus.name") "Legal Corpus")))
    (format s "    <p>Canonical Legal Corpus | <strong>Stavropoulos Law®</strong></p>~%")
    (format s "  </header>~%")
    (format s "~%")
    (format s "  <!-- Article Content with RDFa -->~%")
    (format s "  <article typeof=\"eli:LegalResource\" resource=\"~A/art/~A\">~%" (orchestrator.uris:get-eli-const-prefix) article-num)
    (format s "~%")
    (format s "    <!-- Title -->~%")
    (format s "    <h2 property=\"dct:title\" lang=\"el\">~A</h2>~%" (escape-html (%article-heading article-num title)))
    (format s "~%")
    (format s "    <!-- Metadata -->~%")
    ;; eli:number is the base integer (xsd:integer); the letter suffix lives in
    ;; the URI / title / legislationIdentifier.
    (format s "    <meta property=\"eli:number\" content=\"~D\">~%"
            (or (parse-integer (princ-to-string article-num) :junk-allowed t) 0))
    (format s "    <meta property=\"dct:language\" content=\"el\">~%")
    (format s "    <meta property=\"digest:sha256\" content=\"~A\">~%" content-hash)
    (format s "~%")
    (format s "    <!-- Authority and Provenance -->~%")
    (format s "    <div rel=\"dct:publisher\" resource=\"~A\">~%" (org-webid))
    (format s "      <span property=\"schema:name\">~A</span>~%" (escape-html (org-name)))
    (format s "    </div>~%")
    (let ((auth-uri (orchestrator.spec:config-get "provenance.authority_uri"
                                                   "http://data.stavropouloslaw.com/agent/greek-parliament"))
          (auth-label (orchestrator.spec:config-get "provenance.authority_label"
                                                     "Ελληνική Βουλή")))
      (format s "    <div rel=\"prov:wasAttributedTo\" resource=\"~A\">~%" auth-uri)
      (format s "      <span property=\"schema:name\">~A</span>~%" (escape-html auth-label))
      (format s "    </div>~%"))
    (format s "~%")
    (format s "    <!-- Paragraphs -->~%")
    (format s "    <div class=\"article-content\">~%")
    (loop for para in paragraphs
          for para-num = (getf para :number)
          for para-text = (getf para :text)
          do (format s "      <p typeof=\"eli:LegalResourceSubdivision\" resource=\"~A/art/~A/par/~D\">~%"
                    (orchestrator.uris:get-eli-const-prefix) article-num para-num)
             (format s "        <meta property=\"eli:number\" content=\"~D\">~%" para-num)
             (format s "        <span property=\"schema:text\" lang=\"el\">~D. ~A</span>~%"
                    para-num (escape-html para-text))
             (format s "      </p>~%"))
    (format s "    </div>~%")
    (format s "~%")

    ;; Blockchain Proof Display (from Jinja2 template)
    (when blockchain-proof
      (format s "    <!-- Blockchain Verification -->~%")
      (format s "    <div class=\"blockchain-proof\">~%")
      (format s "      <strong>🔗 Blockchain Verification:</strong><br>~%")
      (when (getf blockchain-proof :ethereum)
        (format s "      Ethereum: <code>~A</code><br>~%" (getf blockchain-proof :ethereum)))
      (when (getf blockchain-proof :arweave)
        (format s "      Arweave: <code>~A</code><br>~%" (getf blockchain-proof :arweave)))
      (when (getf blockchain-proof :ipfs)
        (format s "      IPFS: <code>~A</code>~%" (getf blockchain-proof :ipfs)))
      (format s "    </div>~%")
      (format s "~%"))

    (format s "  </article>~%")
    (format s "~%")
    (format s "  <!-- Footer -->~%")
    (format s "  <footer>~%")
    (format s "    <p>&copy; 2025 ~A</p>~%" (escape-html (org-name)))
    (when (org-email)
      (format s "    <p>Email: <a href=\"mailto:~A\">~A</a></p>~%" (escape-html (org-email)) (escape-html (org-email))))
    (when (org-telephone)
      (format s "    <p>Tel: ~A</p>~%" (escape-html (org-telephone))))
    (format s "    <p><small>Generated by ORCHESTRATOR v1.2 | ")
    (format s "<a href=\"~A/art/~A.ttl\">RDF/Turtle</a> | " (orchestrator.uris:get-eli-const-prefix) article-num)
    (format s "<a href=\"~A/art/~A.jsonld\">JSON-LD</a></small></p>~%" (orchestrator.uris:get-eli-const-prefix) article-num)
    (format s "  </footer>~%")
    (format s "~%")))

;;; ============================================================
;;; HTML ESCAPING - Security
;;; ============================================================

(defun escape-html (text)
  "Escape HTML special characters to prevent XSS"
  (let ((escaped text))
    (setf escaped (cl-ppcre:regex-replace-all "&" escaped "&amp;"))
    (setf escaped (cl-ppcre:regex-replace-all "<" escaped "&lt;"))
    (setf escaped (cl-ppcre:regex-replace-all ">" escaped "&gt;"))
    (setf escaped (cl-ppcre:regex-replace-all "\"" escaped "&quot;"))
    (setf escaped (cl-ppcre:regex-replace-all "'" escaped "&#39;"))
    escaped))

;; NOTE: JSON escaping now handled by orchestrator.spec:escape-json-string

;;; ============================================================
;;; UNIFIED HTML GENERATOR
;;; ============================================================

(defun generate-html-with-rdfa (article-num title content paragraphs content-hash)
  "Generate complete SEO-ready HTML page with RDFa and JSON-LD

   Arguments:
     article-num:   Article number
     title:         Article title
     content:       Full article text (for metadata)
     paragraphs:    List of paragraph plists
     content-hash:  SHA-256 hash of content

   Returns:
     String containing complete HTML page

   TIER 2 Enhancements:
     - BreadcrumbList for Google rich results
     - FAQPage for featured snippets
     - Enhanced Organization profile"
  (declare (ignore content)) ;; Used for hash only

  (with-output-to-string (stream)
    ;; HTML Head with SEO
    (write-string (generate-html-head article-num title) stream)

    ;; Open body with RDFa vocabulary
    (format stream "<body vocab=\"http://data.europa.eu/eli/ontology#\">~%")
    (format stream "~%")

    ;; JSON-LD Scripts - TIER 2: Now includes Breadcrumb + FAQ
    (format stream "  <!-- JSON-LD Structured Data -->~%")

    ;; 1. Organization (Knowledge Panel)
    (format stream "  <script type=\"application/ld+json\">~%")
    (write-string (generate-jsonld-organization) stream)
    (format stream "  </script>~%")
    (format stream "~%")

    ;; 2. Article (Legislation)
    (format stream "  <script type=\"application/ld+json\">~%")
    (write-string (generate-jsonld-article article-num title content-hash) stream)
    (format stream "  </script>~%")
    (format stream "~%")

    ;; 3. Breadcrumb (Rich Results) - TIER 2
    (format stream "  <script type=\"application/ld+json\">~%")
    (write-string (generate-jsonld-breadcrumb article-num title) stream)
    (format stream "  </script>~%")
    (format stream "~%")

    ;; 4. FAQ (Featured Snippets) - TIER 2
    (format stream "  <script type=\"application/ld+json\">~%")
    (write-string (generate-jsonld-faq article-num title paragraphs) stream)
    (format stream "  </script>~%")
    (format stream "~%")

    ;; Article Body with RDFa
    (write-string (generate-article-body article-num title paragraphs content-hash) stream)

    ;; Close body and html
    (format stream "</body>~%")
    (format stream "</html>~%")))

;;; ============================================================
;;; EXPORT
;;; ============================================================

(export '(generate-html-with-rdfa
          *organization-info*
          *person-info*))
