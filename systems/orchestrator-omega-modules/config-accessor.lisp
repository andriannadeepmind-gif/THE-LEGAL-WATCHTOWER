;;;; systems/orchestrator-omega-modules/config-accessor.lisp
;;;; LEVEL 300: Configuration Accessor
;;;;
;;;; Loads constitution.yaml and provides structured access to:
;;;;   - Rich identity metadata (person, organization)
;;;;   - ODRL policy configuration
;;;;   - HTML generation settings
;;;;
;;;; Philosophy: NO HARDCODED VALUES - All data flows from config

(in-package :orchestrator.spec)

;;; ============================================================
;;; GLOBAL CONFIG STATE
;;; ============================================================

(defvar *loaded-config* nil
  "Cached configuration hash table loaded from the active corpus config")

(defvar *config-path* (orchestrator.paths:institution-dir "configs/constitution.yaml")
  "Path to active corpus config file. Changed by select-corpus.")

;;; ============================================================
;;; CORPUS REGISTRY
;;; ============================================================

(defparameter *corpus-config-registry*
  '(("syntagma"     . "constitution.yaml")        ; Σύνταγμα της Ελλάδας
    ("poinikos"     . "poinikoskodikas.yaml")     ; Ποινικός Κώδικας
    ("kpoinikis"    . "kpoinikis.yaml")           ; Κώδικας Ποινικής Δικονομίας
    ("astikos"      . "astikos.yaml")             ; Αστικός Κώδικας
    ("kpolitikis"   . "kpolitikis.yaml")          ; Κώδικας Πολιτικής Δικονομίας
    ("kdioikitikis" . "kdioikitikis.yaml"))       ; Κώδικας Διοικητικής Δικονομίας
  "Maps corpus ID string → config filename under the institution configs dir. The six core Greek
   legal codes. Add an entry here when a new corpus YAML config is created.")

(defun select-corpus (&optional corpus-id)
  "Load configuration for the named corpus.

   corpus-id: String such as 'syntagma' or 'poinikos'.
              Defaults to ORCHESTRATOR_CORPUS env var, then 'syntagma'.

   Side effects:
     - Updates *config-path* to the corpus config file
     - Resets *loaded-config* so the new YAML is loaded on next access

   Errors:
     Signals an error if corpus-id is not in *corpus-config-registry*."
  (let* ((resolved (or corpus-id
                       (uiop:getenv "ORCHESTRATOR_CORPUS")
                       "syntagma"))
         (filename (or (cdr (assoc resolved *corpus-config-registry* :test #'string=))
                       (error "Unknown corpus '~A'. Known corpora: ~{~A~^, ~}"
                              resolved (mapcar #'car *corpus-config-registry*))))
         (path (orchestrator.paths:institution-dir (format nil "configs/~A" filename))))
    (setf *config-path* path)
    (setf *loaded-config* nil)    ; Force reload on next ensure-config-loaded call
    (load-constitution-config path)
    (format t "  Corpus config: ~A → ~A~%" resolved path)
    resolved))

;;; ============================================================
;;; CONFIG LOADER
;;; ============================================================

(defun load-constitution-config (&optional (path *config-path*))
  "Load constitution.yaml configuration file

   Arguments:
     path: Path to YAML config file (default: *config-path*)

   Returns:
     Hash table containing configuration

   Side Effects:
     Updates *loaded-config* with parsed YAML"

  (when (probe-file path)
    (setf *loaded-config* (cl-yaml:parse (uiop:read-file-string path)))
    *loaded-config*))

(defun ensure-config-loaded ()
  "Ensure configuration is loaded, load if necessary

   Returns:
     Hash table containing configuration"

  (unless *loaded-config*
    (load-constitution-config))
  *loaded-config*)

;;; ============================================================
;;; GENERIC HASH TABLE ACCESSOR
;;; ============================================================

(defun config-get (path &optional default)
  "Get value from config by dotted path (e.g., 'identity.person.name')

   Arguments:
     path:    Dotted path string or list of keys
     default: Value to return if path not found

   Returns:
     Value at path, or default if not found"

  (ensure-config-loaded)

  (let* ((keys (if (stringp path)
                   (cl-ppcre:split "\\." path)  ; Keep as strings, not symbols
                   path))
         (current *loaded-config*))

    (dolist (key keys default)
      (if (hash-table-p current)
          (setf current (gethash key current))  ; Use string keys
          (return-from config-get default)))

    ;; ΚΑΘΑΡΟ boundary (κανόνας Κριτή 0021): το config-get επιστρέφει RAW τιμή —
    ;; ΠΟΤΕ δεν «πειράζει» strings. URLs/URIs/format/prefixes μένουν άθικτα.
    ;; Η επίλυση filesystem paths γίνεται ΜΟΝΟ μέσω resolve-config-path, και
    ;; ΜΟΝΟ για δηλωμένα path-valued keys.
    current))

(defparameter +config-path-keys+
  '("source.json" "source.pdf" "source.docx")
  "Τα ΜΟΝΑ config keys που είναι filesystem paths — επιλύονται μέσω της ρίζας
   του Ιδρύματος. ΟΛΑ τα άλλα source.* (url, format, …) είναι web
   identifiers/metadata και ΔΕΝ αγγίζονται ποτέ από root resolver.")

(defun resolve-config-path (key &optional default)
  "Path-aware accessor για δηλωμένα filesystem-path keys ΜΟΝΟ (+config-path-keys+):
     • σχετική τιμή  ⇒ επίλυση μέσω institution-root (φορητότητα)
     • absolute path ⇒ ως έχει (ρητό external/user override)
     • μη-path key   ⇒ raw (ασφάλεια αν κληθεί λάθος· URL/format ΔΕΝ αγγίζεται)
   Η ΜΙΑ κανονική οδός επίλυσης — οι καταναλωτές path fields ΔΕΝ κάνουν δική
   τους root λογική (κανόνας Κριτή)."
  (let ((raw (config-get key default)))
    (if (and (stringp raw) (plusp (length raw))
             (member key +config-path-keys+ :test #'string=)
             (not (char= (char raw 0) #\/)))
        (orchestrator.paths:institution-dir raw)
        raw)))

(export 'resolve-config-path :orchestrator.spec)

;;; ============================================================
;;; REQUIRED CONFIG INFRASTRUCTURE
;;; ============================================================

(define-condition missing-required-config (error)
  ((key :initarg :key :reader missing-config-key)
   (path :initarg :path :reader missing-config-path))
  (:report (lambda (condition stream)
             (format stream "FATAL: Required configuration missing~%  Key: ~A~%  File: ~A~%  Action: Add this key to constitution.yaml"
                     (missing-config-key condition)
                     (missing-config-path condition)))))

(defmacro required-config (path)
  "Access REQUIRED config value. Signals error if missing.
   
   Arguments:
     path: Dotted path string to required configuration key
   
   Returns:
     Configuration value at path
   
   Signals:
     missing-required-config if key not found in constitution.yaml"
  `(or (config-get ,path)
       (error 'missing-required-config 
              :key ,path 
              :path *config-path*)))

(defun validate-required-config ()
  "Validate all required configuration keys are present.
   
   Call this at system startup to fail fast.
   
   Returns:
     T if all required keys present
   
   Signals:
     missing-required-config if any key missing"
  (let ((required-keys '(;; Corpus identity — required for all ELI URI generation
                         "corpus.name"
                         "corpus.short_name"
                         "corpus.eli_prefix"
                         "corpus.publication.date"
                         "corpus.document_type"
                         "corpus.dataset_uri"
                         ;; Person identity
                         "identity.person.webid"
                         "identity.person.name"
                         "identity.person.given_name"
                         "identity.person.family_name"
                         "identity.person.orcid"
                         "identity.person.bar_number"
                         "identity.person.job_title"
                         ;; Organization identity
                         "identity.organization.webid"
                         "identity.organization.name"
                         "identity.organization.legal_name"
                         "identity.organization.trademark"
                         "identity.organization.url"
                         "identity.organization.logo"
                         ;; Policy & HTML
                         "odrl_policy.policy_uri"
                         "html_generation.output_directory"
                         "html_generation.seo.canonical_base")))
    (dolist (key required-keys t)
      (unless (config-get key)
        (error 'missing-required-config :key key :path *config-path*)))))

;;; ============================================================
;;; IDENTITY ACCESSORS - PERSON
;;; ============================================================

(defun person-webid ()
  "Get person WebID URI.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String URI for person's WebID"
  (required-config "identity.person.webid"))

(defun person-name ()
  "Get person full name.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing person's full name"
  (required-config "identity.person.name"))

(defun person-given-name ()
  "Get person given name.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing person's given name"
  (required-config "identity.person.given_name"))

(defun person-family-name ()
  "Get person family name.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing person's family name"
  (required-config "identity.person.family_name"))

(defun person-orcid ()
  "Get person ORCID identifier.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing person's ORCID identifier"
  (required-config "identity.person.orcid"))

(defun person-bar-number ()
  "Get person bar association number.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing person's bar association number"
  (required-config "identity.person.bar_number"))

(defun person-job-title ()
  "Get person job title.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing person's job title"
  (required-config "identity.person.job_title"))

(defun person-email ()
  "Get person email (may be nil)"
  (config-get "identity.person.email"))

(defun person-telephone ()
  "Get person telephone (may be nil)"
  (config-get "identity.person.telephone"))

(defun person-linkedin ()
  "Get person LinkedIn URL (may be nil)"
  (config-get "identity.person.linkedin"))

(defun person-twitter ()
  "Get person Twitter URL (may be nil)"
  (config-get "identity.person.twitter"))

(defun person-university ()
  "Get person university (may be nil)"
  (config-get "identity.person.university"))

(defun person-degree ()
  "Get person degree (may be nil)"
  (config-get "identity.person.degree"))

(defun person-graduation-year ()
  "Get person graduation year (may be nil)"
  (config-get "identity.person.graduation_year"))

;;; ============================================================
;;; IDENTITY ACCESSORS - ORGANIZATION
;;; ============================================================

(defun org-webid ()
  "Get organization WebID URI.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String URI for organization's WebID"
  (required-config "identity.organization.webid"))

(defun org-name ()
  "Get organization name.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing organization's name"
  (required-config "identity.organization.name"))

(defun org-legal-name ()
  "Get organization legal name.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing organization's legal name"
  (required-config "identity.organization.legal_name"))

(defun org-trademark ()
  "Get organization trademark number.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String containing organization's trademark number"
  (required-config "identity.organization.trademark"))

(defun org-url ()
  "Get organization canonical URL.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String URL for organization"
  (required-config "identity.organization.url"))

(defun org-logo ()
  "Get organization logo URL.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String URL for organization's logo"
  (required-config "identity.organization.logo"))

(defun org-email ()
  "Get organization email (may be nil)"
  (config-get "identity.organization.email"))

(defun org-telephone ()
  "Get organization telephone (may be nil)"
  (config-get "identity.organization.telephone"))

(defun org-address-street ()
  "Get organization street address (may be nil)"
  (config-get "identity.organization.address.street_address"))

(defun org-address-city ()
  "Get organization city (may be nil)"
  (config-get "identity.organization.address.city"))

(defun org-address-postal-code ()
  "Get organization postal code (may be nil)"
  (config-get "identity.organization.address.postal_code"))

(defun org-address-region ()
  "Get organization region (may be nil)"
  (config-get "identity.organization.address.region"))

(defun org-address-country ()
  "Get organization country"
  (config-get "identity.organization.address.country" "Greece"))

(defun org-founded ()
  "Get organization founding year (may be nil)"
  (config-get "identity.organization.founded"))

(defun org-founding-location ()
  "Get organization founding location (may be nil)"
  (config-get "identity.organization.founding_location"))

(defun org-linkedin ()
  "Get organization LinkedIn URL (may be nil)"
  (config-get "identity.organization.linkedin"))

(defun org-twitter ()
  "Get organization Twitter URL (may be nil)"
  (config-get "identity.organization.twitter"))

;;; ============================================================
;;; ODRL POLICY ACCESSORS
;;; ============================================================

(defun odrl-enabled-p ()
  "Check if ODRL policy is enabled"
  (config-get "odrl_policy.enabled" t))

(defun odrl-policy-uri ()
  "Get ODRL policy URI.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String URI for ODRL policy"
  (required-config "odrl_policy.policy_uri"))

(defun odrl-attribution-text ()
  "Get ODRL attribution text"
  (let ((permissions (config-get "odrl_policy.permissions")))
    (when (and permissions (> (length permissions) 0))
      (let ((first-perm (elt permissions 0)))
        (when (hash-table-p first-perm)
          (let ((duties (gethash "duties" first-perm)))
            (when (and duties (> (length duties) 0))
              (let ((first-duty (elt duties 0)))
                (when (hash-table-p first-duty)
                  (gethash "attribution_text" first-duty
                          "Source: Stavropoulos Law® (https://stavropouloslaw.com)"))))))))))

(defun odrl-attribution-url ()
  "Get ODRL attribution URL"
  (let ((permissions (config-get "odrl_policy.permissions")))
    (when (and permissions (> (length permissions) 0))
      (let ((first-perm (elt permissions 0)))
        (when (hash-table-p first-perm)
          (let ((duties (gethash "duties" first-perm)))
            (when (and duties (> (length duties) 0))
              (let ((first-duty (elt duties 0)))
                (when (hash-table-p first-duty)
                  (gethash "attribution_url" first-duty
                          "https://stavropouloslaw.com"))))))))))

;;; ============================================================
;;; HTML GENERATION ACCESSORS
;;; ============================================================

(defun html-enabled-p ()
  "Check if HTML generation is enabled"
  (config-get "html_generation.enabled" t))

(defun html-output-directory ()
  "Get HTML output directory.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String path for HTML output directory"
  (required-config "html_generation.output_directory"))

(defun html-include-organization-p ()
  "Check if JSON-LD should include organization"
  (config-get "html_generation.jsonld.include_organization" t))

(defun html-include-ceo-p ()
  "Check if JSON-LD should include CEO"
  (config-get "html_generation.jsonld.include_ceo" t))

(defun html-include-founder-p ()
  "Check if JSON-LD should include founder"
  (config-get "html_generation.jsonld.include_founder" t))

(defun html-include-address-p ()
  "Check if JSON-LD should include address"
  (config-get "html_generation.jsonld.include_address" t))

(defun html-include-social-proof-p ()
  "Check if JSON-LD should include social proof"
  (config-get "html_generation.jsonld.include_social_proof" t))

(defun html-canonical-base ()
  "Get HTML canonical base URL.
   
   REQUIRED - Signals missing-required-config if not in constitution.yaml.
   
   Returns:
     String URL for HTML canonical base"
  (required-config "html_generation.seo.canonical_base"))

(defun html-robots ()
  "Get HTML robots meta tag"
  (config-get "html_generation.seo.robots" "index, follow"))

(defun canonical-base-uri ()
  "Get canonical base URI (domain only, for ELI URI construction).
   Reads from corpus config key 'canonical.base_uri'."
  (or (config-get "canonical.base_uri")
      "https://stavropouloslaw.com"))

;;; ============================================================
;;; TELEMETRY ACCESSORS
;;; ============================================================

(defun telemetry-enabled-p ()
  "Check if telemetry is enabled. PRIVACY BY DEFAULT: NIL unless a config
   explicitly sets telemetry.enabled — so no published page tracks its reader
   without an opt-in."
  (config-get "telemetry.enabled" nil))

(defun telemetry-endpoint ()
  "Get telemetry endpoint URL"
  (config-get "telemetry.endpoint" "https://telemetry.stavropouloslaw.com/beacon"))

(defun telemetry-include-referrer-p ()
  "Check if telemetry should include referrer"
  (config-get "telemetry.include_referrer" t))

(defun telemetry-track-ai-systems-p ()
  "Check if telemetry should track AI systems"
  (config-get "telemetry.track_ai_systems" t))

;;; ============================================================
;;; VOID DATASET DESCRIPTOR
;;; ============================================================

(defun generate-void-dataset-descriptor ()
  "Generate VoID Dataset descriptor — config-driven, no hardcoded corpus identifiers.

   All corpus-specific values (dataset URI, ELI prefix, title) are read from
   the active corpus config (e.g. constitution.yaml) so the same function
   works for any law type when the matching corpus config is loaded.

   Returns: Complete, standalone, W3C-valid Turtle RDF string.
   Includes canonical prefix declarations so the file is valid both
   as a standalone void.ttl and when prefix-stripped for embedding
   inside a unified file (via strip-leading-prefix-block)."

  (let* ((dataset-uri  (or (config-get "corpus.dataset_uri")
                           (error "corpus.dataset_uri not configured")))
         (eli-prefix   (or (config-get "corpus.eli_prefix")
                           (error "corpus.eli_prefix not configured")))
         (corpus-name  (or (config-get "corpus.name") "Greek Law Corpus"))
         (created-date (or (config-get "corpus.dataset_created") "2025-12-14")))

    (with-output-to-string (s)
      ;; Emit canonical prefix block — required for standalone validity.
      ;; unified-frbr-generator.lisp strips this block when embedding.
      (emit-canonical-prefixes s)
      (format s "<~A>~%" dataset-uri)
      (format s "    a void:Dataset, dcat:Dataset ;~%")
      (format s "~%")

      ;; Basic metadata
      (format s "    # Dataset Identity~%")
      (format s "    dct:title \"~A - Semantic Corpus\"@en ;~%" corpus-name)
      (format s "    dct:description \"W3C ELI-compliant semantic corpus: ~A. Includes FRBR hierarchy, PROV-O provenance, and ODRL policies.\"@en ;~%"
              corpus-name)
      (format s "~%")

      ;; Creator & Publisher
      (format s "    # Authorship~%")
      (format s "    dct:creator <~A> ;~%" (person-webid))
      (format s "    dct:publisher <~A> ;~%" (org-webid))
      (format s "    pav:curatedBy <~A> ;~%" (person-webid))
      (format s "~%")

      ;; Temporal — corpus creation dates, not legal document dates
      (format s "    # Temporal~%")
      (format s "    dct:created ~S^^xsd:date ;~%" created-date)
      (format s "    dct:modified ~S^^xsd:date ;~%" created-date)
      (format s "~%")

      ;; VoID Statistics — computed from corpus article count
      ;; FRBR stack: ArticleRoot + Work + Expression + Manifestation + 1 Format = 5 layers
      ;; Average ~12 triples per FRBR layer (type, URI, label, links, provenance)
      (let* ((article-count (or (ignore-errors
                                  (parse-integer
                                    (or (config-get "corpus.article_count") "0")
                                    :junk-allowed t))
                                0))
             (frbr-layers 5)
             (triples-per-layer 12)
             (computed-triples (* article-count frbr-layers triples-per-layer))
             (computed-entities (* article-count frbr-layers))
             (computed-subjects (round (* computed-entities 0.85))))
        (format s "    # VoID Statistics~%")
        (format s "    void:triples ~D ;~%" computed-triples)
        (format s "    void:entities ~D ;~%" computed-entities)
        (format s "    void:distinctSubjects ~D ;~%" computed-subjects)
        (format s "    void:properties 45 ;~%"))
      (format s "~%")

      ;; VoID Structure
      (format s "    # Dataset Structure~%")
      (format s "    void:exampleResource <~A/art/1> ;~%" eli-prefix)
      (format s "    void:vocabulary <http://data.europa.eu/eli/ontology#> ,~%")
      (format s "                    <http://www.w3.org/ns/prov#> ,~%")
      (format s "                    <https://schema.org/> ;~%")
      (format s "~%")

      ;; DCAT Distribution
      (format s "    # DCAT Distribution~%")
      (format s "    dcat:distribution [~%")
      (format s "        a dcat:Distribution ;~%")
      (format s "        dcat:downloadURL <~A/full-corpus.ttl> ;~%" dataset-uri)
      (format s "        dcat:mediaType \"text/turtle\" ;~%")
      (format s "        dct:format <http://publications.europa.eu/resource/authority/file-type/RDF_TURTLE> ;~%")
      (format s "        dct:license <~A>~%" (odrl-policy-uri))
      (format s "    ] ;~%")
      (format s "~%")

      ;; License & Rights
      (format s "    # Rights~%")
      (format s "    dct:license <~A> ;~%" (odrl-policy-uri))
      (format s "    dct:rights \"© 2025 ~A. CC BY 4.0\" ;~%" (org-name))
      (format s "~%")

      ;; Provenance
      (format s "    # Provenance~%")
      (format s "    prov:wasGeneratedBy [~%")
      (format s "        a prov:Activity ;~%")
      (format s "        rdfs:label \"Semantic Transformation & ELI Mapping\"@en ;~%")
      (format s "        prov:wasAssociatedWith <~A> ;~%" (person-webid))
      (format s "        prov:endedAtTime ~S^^xsd:dateTime~%"
              ;; Output-bound timestamp: must be reproducible across runs.
              (orchestrator.time:format-iso8601 (orchestrator.time:now :source :deterministic)))
      (format s "    ] .~%"))))

;;; ============================================================
;;; CRYPTOGRAPHIC UTILITIES
;;; ============================================================

(defun calculate-sha256-hash (text)
  "Calculate SHA-256 hash of text using ironclad.

   Arguments:
     text - String to hash

   Returns:
     Lowercase hex string of SHA-256 digest

   Example:
     (calculate-sha256-hash \"Hello World\")
     => \"a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e\""

  (orchestrator.hash-authority:compute-hash text :algorithm :sha256))

;;; ============================================================
;;; EXPORTS
;;; ============================================================

(export '(;; Config loading
          load-constitution-config
          ensure-config-loaded
          config-get
          
          ;; Required config infrastructure
          missing-required-config
          missing-config-key
          missing-config-path
          required-config
          validate-required-config

          ;; Person accessors
          person-webid
          person-name
          person-given-name
          person-family-name
          person-orcid
          person-bar-number
          person-job-title
          person-email
          person-telephone
          person-linkedin
          person-twitter
          person-university
          person-degree
          person-graduation-year

          ;; Organization accessors
          org-webid
          org-name
          org-legal-name
          org-trademark
          org-url
          org-logo
          org-email
          org-telephone
          org-address-street
          org-address-city
          org-address-postal-code
          org-address-region
          org-address-country
          org-founded
          org-founding-location
          org-linkedin
          org-twitter

          ;; ODRL accessors
          odrl-enabled-p
          odrl-policy-uri
          odrl-attribution-text
          odrl-attribution-url

          ;; HTML accessors
          html-enabled-p
          html-output-directory
          html-include-organization-p
          html-include-ceo-p
          html-include-founder-p
          html-include-address-p
          html-include-social-proof-p
          html-canonical-base
          html-robots
          canonical-base-uri

          ;; Telemetry accessors
          telemetry-enabled-p
          telemetry-endpoint
          telemetry-include-referrer-p
          telemetry-track-ai-systems-p

          ;; Corpus selection
          select-corpus
          *corpus-config-registry*

          ;; VoID Dataset
          generate-void-dataset-descriptor

          ;; Cryptographic utilities
          calculate-sha256-hash))
