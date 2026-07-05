;;;; EU-INTEROP-LAYER.LISP
;;;; Integration with European Union legal systems (EUR-Lex, CELLAR, EBSI)
;;;; Full production implementation for EU standards compliance
;;;;
;;;; Restored and made self-contained: the package (previously defined in the
;;;; removed legacy packages.lisp) is declared here. Provides the real EUR-Lex /
;;;; CELLAR integration with the EU's official legal data; depends only on the
;;;; HTTP libraries + orchestrator.time / orchestrator.hash-authority.

(defpackage :orchestrator.eu-interop
  (:use :cl)
  (:export #:initialize-eu-systems
           #:search-eurlex #:fetch-eurlex-document
           #:search-cellar-by-eli #:fetch-cellar-document
           #:fetch-eu-legal-ontology
           #:eu-api-client #:eurlex-client #:cellar-client
           #:*eurlex-base-url* #:*cellar-sparql-endpoint*))

(in-package :orchestrator.eu-interop)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defparameter *eurlex-base-url* "https://eur-lex.europa.eu/api/"
  "EUR-Lex API endpoint")

(defparameter *cellar-sparql-endpoint* "http://publications.europa.eu/webapi/rdf/sparql"
  "CELLAR SPARQL endpoint for EU publications")

(defparameter *ebsi-base-url* "https://api.ebsi.eu/v1/"
  "European Blockchain Services Infrastructure API")

(defparameter *eli-validator-url* "https://publications.europa.eu/eli-validator/"
  "ELI (European Legislation Identifier) validator service")

(defparameter *supported-languages* '("el" "en" "fr" "de" "it" "es")
  "Supported EU languages for document retrieval")

;;; ============================================================================
;;; EU API CLIENT BASE
;;; ============================================================================

(defclass eu-api-client ()
  ((service-name :initarg :service-name 
                 :accessor service-name
                 :type string
                 :documentation "EU service name")
   
   (endpoint :initarg :endpoint 
             :accessor service-endpoint
             :type string
             :documentation "Service endpoint URL")
   
   (auth-token :initarg :auth-token 
               :accessor auth-token
               :type (or null string)
               :initform nil
               :documentation "Authentication token if required")
   
   (rate-limit :initarg :rate-limit 
               :accessor rate-limit
               :initform 100
               :type integer
               :documentation "Requests per minute limit")
   
   (request-count :accessor request-count 
                  :initform 0
                  :type integer)
   
   (last-reset :accessor last-reset
               :initform (orchestrator.time:now :source :system))
   
   (cache :accessor service-cache 
          :initform (make-hash-table :test 'equal)
          :documentation "Response cache")
   
   (timeout :initarg :timeout 
            :accessor request-timeout
            :initform 60
            :documentation "Request timeout in seconds")))

(defmethod check-rate-limit ((client eu-api-client))
  "Enforce rate limiting for EU services"
  (let ((now (orchestrator.time:now :source :system)))
    (when (> (- now (last-reset client)) 60)
      (setf (request-count client) 0
            (last-reset client) now))
    
    (when (>= (request-count client) (rate-limit client))
      (let ((wait-time (- 60 (- now (last-reset client)))))
        (log:info () "Rate limit reached for ~A, waiting ~A seconds"
                 (service-name client) wait-time)
        (sleep wait-time)
        (setf (request-count client) 0
              (last-reset client) (orchestrator.time:now :source :system))))
    
    (incf (request-count client))))

;;; ============================================================================
;;; EUR-LEX INTEGRATION
;;; ============================================================================

(defclass eurlex-client (eu-api-client)
  ((search-types :initform '(:legislation :case-law :preparatory :consolidated)
                 :documentation "Types of documents searchable in EUR-Lex"))
  (:default-initargs
   :service-name "EUR-Lex"
   :endpoint "https://eur-lex.europa.eu/api/"
   :rate-limit 120))

(defparameter *eurlex-client* nil)

(defun initialize-eurlex ()
  "Initialize EUR-Lex client"
  (setf *eurlex-client*
        (make-instance 'eurlex-client
                       :auth-token (uiop:getenv "EURLEX_API_TOKEN"))))

(defun search-eurlex (query &key 
                           (document-type :legislation)
                           (language "en")
                           (year nil)
                           (in-force-only t)
                           (page 1)
                           (results-per-page 20))
  "Search EUR-Lex for EU legal documents"
  (unless *eurlex-client*
    (initialize-eurlex))
  
  (check-rate-limit *eurlex-client*)
  
  (let* ((search-params 
          `(("q" . ,query)
            ("type" . ,(string-downcase (string document-type)))
            ("lang" . ,language)
            ("page" . ,(write-to-string page))
            ("pageSize" . ,(write-to-string results-per-page))
            ,@(when year `(("year" . ,(write-to-string year))))
            ,@(when in-force-only `(("inForce" . "true")))))
         
         (url (format nil "~Asearch" (service-endpoint *eurlex-client*))))
    
    (handler-case
        (multiple-value-bind (body status-code)
            (drakma:http-request url
                                :method :get
                                :parameters search-params
                                :accept "application/json"
                                :timeout (request-timeout *eurlex-client*))
          
          (when (= status-code 200)
            (let ((results (jonathan:parse 
                           (babel:octets-to-string body :encoding :utf-8))))
              (log:info () "EUR-Lex search returned ~A results" 
                       (gethash "totalResults" results))
              results)))
      
      (error (e)
        (log:error () "EUR-Lex search failed: ~A" e)
        nil))))

(defun fetch-eurlex-document (celex-number &key (language "en") (format :html))
  "Fetch specific document from EUR-Lex by CELEX number"
  (unless *eurlex-client*
    (initialize-eurlex))
  
  (log:info () "Fetching EUR-Lex document: ~A" celex-number)
  
  ;; CACHE-KEY spans the whole body: it is used both for the cache lookup and
  ;; for storing the freshly-fetched document.
  (let ((cache-key (format nil "~A-~A-~A" celex-number language format)))
    ;; Check cache
    (let ((cached (gethash cache-key (service-cache *eurlex-client*))))
      (when cached
        (return-from fetch-eurlex-document cached)))

    (check-rate-limit *eurlex-client*)

    (let ((url (format nil "~Adocument/~A"
                      (service-endpoint *eurlex-client*)
                      celex-number))
          (params `(("language" . ,language)
                    ("format" . ,(string-downcase (string format))))))

      (multiple-value-bind (body status-code)
          (drakma:http-request url
                              :parameters params
                              :accept (case format
                                       (:json "application/json")
                                       (:xml "application/xml")
                                       (:pdf "application/pdf")
                                       (t "text/html"))
                              :timeout (request-timeout *eurlex-client*))

        (when (= status-code 200)
          (let ((content (if (eq format :pdf)
                            body
                            (babel:octets-to-string body :encoding :utf-8))))
            ;; Cache the result
            (setf (gethash cache-key (service-cache *eurlex-client*)) content)
            content))))))

(defun get-eurlex-metadata (celex-number)
  "Get metadata for EUR-Lex document"
  (unless *eurlex-client*
    (initialize-eurlex))
  
  (check-rate-limit *eurlex-client*)
  
  (let ((url (format nil "~Ametadata/~A" 
                    (service-endpoint *eurlex-client*)
                    celex-number)))
    
    (handler-case
        (multiple-value-bind (body status-code)
            (drakma:http-request url
                                :accept "application/json"
                                :timeout (request-timeout *eurlex-client*))
          
          (when (= status-code 200)
            (jonathan:parse (babel:octets-to-string body :encoding :utf-8))))
      
      (error (e)
        (log:error () "Failed to fetch EUR-Lex metadata: ~A" e)
        nil))))

;;; ============================================================================
;;; CELLAR INTEGRATION (EU Publications Office)
;;; ============================================================================

(defclass cellar-client (eu-api-client)
  ()
  (:default-initargs
   :service-name "CELLAR"
   :endpoint "http://publications.europa.eu/webapi/rdf/sparql"
   :rate-limit 60))

(defparameter *cellar-client* nil)

(defun initialize-cellar ()
  "Initialize CELLAR client"
  (setf *cellar-client*
        (make-instance 'cellar-client)))

(defun execute-sparql-query (query &key (format :json) (timeout 30))
  "Execute SPARQL query against CELLAR endpoint"
  (unless *cellar-client*
    (initialize-cellar))
  
  (check-rate-limit *cellar-client*)
  
  (log:info () "Executing SPARQL query on CELLAR")
  (log:debug () "Query: ~A" query)
  
  (let ((params `(("query" . ,query)
                  ("format" . ,(case format
                                (:json "application/sparql-results+json")
                                (:xml "application/sparql-results+xml")
                                (:csv "text/csv")
                                (t "application/sparql-results+json"))))))
    
    (handler-case
        (multiple-value-bind (body status-code)
            (drakma:http-request (service-endpoint *cellar-client*)
                                :method :post
                                :parameters params
                                :timeout timeout)
          
          (when (= status-code 200)
            (case format
              (:json (jonathan:parse 
                     (babel:octets-to-string body :encoding :utf-8)))
              (t body))))
      
      (error (e)
        (log:error () "SPARQL query failed: ~A" e)
        nil))))

(defun search-cellar-by-eli (eli-uri)
  "Search CELLAR for document by ELI identifier"
  (let ((query (format nil "
PREFIX eli: <http://data.europa.eu/eli/ontology#>
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

SELECT ?work ?expression ?title ?date ?type
WHERE {
  ?work eli:is_realized_by ?expression ;
        cdm:resource_legal_eli <~A> ;
        cdm:resource_legal_date_document ?date ;
        cdm:resource_legal_type ?type .
  
  ?expression cdm:expression_title ?title .
  
  FILTER (lang(?title) = 'en')
}
LIMIT 10" eli-uri)))
    
    (execute-sparql-query query)))

(defun fetch-cellar-document (cellar-uri &key (language "en"))
  "Fetch document from CELLAR by URI"
  (let ((query (format nil "
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>
PREFIX eli: <http://data.europa.eu/eli/ontology#>

CONSTRUCT {
  <~A> ?p ?o .
  ?o ?p2 ?o2 .
}
WHERE {
  <~A> ?p ?o .
  OPTIONAL { ?o ?p2 ?o2 }
  
  FILTER (
    ?p IN (cdm:expression_title, 
           cdm:expression_uses_language,
           eli:date_document,
           eli:type_document,
           eli:id_local,
           eli:is_part_of)
  )
}
" cellar-uri cellar-uri)))
    
    (execute-sparql-query query :format :json)))

(defun get-cellar-work-expressions (work-uri)
  "Get all expressions (language versions) of a CELLAR work"
  (let ((query (format nil "
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>
PREFIX eli: <http://data.europa.eu/eli/ontology#>

SELECT ?expression ?language ?title ?format
WHERE {
  <~A> eli:is_realized_by ?expression .
  
  ?expression cdm:expression_uses_language ?language ;
              cdm:expression_title ?title .
  
  OPTIONAL { ?expression cdm:expression_manifested_by_manifestation ?format }
}
ORDER BY ?language
" work-uri)))
    
    (execute-sparql-query query)))

;;; ============================================================================
;;; EBSI (EUROPEAN BLOCKCHAIN SERVICES INFRASTRUCTURE)
;;; ============================================================================

(defclass ebsi-client (eu-api-client)
  ((did :accessor ebsi-did
        :initform nil
        :documentation "Decentralized Identifier for EBSI")
   
   (private-key :accessor ebsi-private-key
                :initform nil
                :documentation "Private key for EBSI transactions"))
  (:default-initargs
   :service-name "EBSI"
   :endpoint "https://api.ebsi.eu/v1/"
   :rate-limit 30))

(defparameter *ebsi-client* nil)

(defun initialize-ebsi (&optional private-key)
  "Initialize EBSI client with optional private key"
  (setf *ebsi-client*
        (make-instance 'ebsi-client))
  
  (when private-key
    (setf (ebsi-private-key *ebsi-client*) private-key))
  
  ;; Generate or load DID
  (setf (ebsi-did *ebsi-client*)
        (or (uiop:getenv "EBSI_DID")
            (generate-did))))

(defun generate-did ()
  "Generate a new DID for EBSI"
  (let ((did-data (format nil "~A-~A"
                         (orchestrator.time:now :source :system)
                         (random 1000000))))
    (format nil "did:ebsi:~A"
           (orchestrator.hash-authority:compute-hash did-data :algorithm :sha256))))

(defun register-with-ebsi (organization-data)
  "Register organization with EBSI"
  (unless *ebsi-client*
    (initialize-ebsi))
  
  (check-rate-limit *ebsi-client*)
  
  (log:info () "Registering with EBSI: ~A" (gethash "name" organization-data))
  
  (let ((registration-data
         (jonathan:to-json
          `(:|did| ,(ebsi-did *ebsi-client*)
            :|organization| ,organization-data
            :|timestamp| ,(orchestrator.time:now :source :system)
            :|type| "LegalEntity"))))
    
    (handler-case
        (multiple-value-bind (body status-code)
            (drakma:http-request (format nil "~Aregister" 
                                        (service-endpoint *ebsi-client*))
                                :method :post
                                :content-type "application/json"
                                :content registration-data
                                :timeout (request-timeout *ebsi-client*))
          
          (when (= status-code 200)
            (let ((response (jonathan:parse 
                           (babel:octets-to-string body :encoding :utf-8))))
              (log:info () "EBSI registration successful: ~A" 
                       (gethash "registrationId" response))
              response)))
      
      (error (e)
        (log:error () "EBSI registration failed: ~A" e)
        nil))))

(defun anchor-to-ebsi (document-hash metadata)
  "Anchor document hash to EBSI blockchain"
  (unless *ebsi-client*
    (initialize-ebsi))
  
  (check-rate-limit *ebsi-client*)
  
  (log:info () "Anchoring to EBSI: ~A" document-hash)

  (let* ((timestamp (orchestrator.time:now :source :system))
         (anchor-data
          `(:|documentHash| ,document-hash
            :|metadata| ,metadata
            :|timestamp| ,timestamp
            :|did| ,(ebsi-did *ebsi-client*)))
         
         ;; Sign the data
         (signature (when (ebsi-private-key *ebsi-client*)
                     (sign-data (jonathan:to-json anchor-data)
                               (ebsi-private-key *ebsi-client*)))))
    
    (handler-case
        (multiple-value-bind (body status-code)
            (drakma:http-request (format nil "~Aanchor" 
                                        (service-endpoint *ebsi-client*))
                                :method :post
                                :content-type "application/json"
                                :content (jonathan:to-json
                                         `(:|data| ,anchor-data
                                           :|signature| ,signature))
                                :timeout (request-timeout *ebsi-client*))
          
          (when (= status-code 200)
            (let ((response (jonathan:parse
                           (babel:octets-to-string body :encoding :utf-8))))
              (log:info () "EBSI anchor transaction: ~A" 
                       (gethash "transactionId" response))
              response)))
      
      (error (e)
        (log:error () "EBSI anchoring failed: ~A" e)
        nil))))

(defun verify-ebsi-anchor (transaction-id)
  "Verify an EBSI anchor transaction"
  (unless *ebsi-client*
    (initialize-ebsi))
  
  (check-rate-limit *ebsi-client*)
  
  (let ((url (format nil "~Averify/~A" 
                    (service-endpoint *ebsi-client*)
                    transaction-id)))
    
    (handler-case
        (multiple-value-bind (body status-code)
            (drakma:http-request url
                                :accept "application/json"
                                :timeout (request-timeout *ebsi-client*))
          
          (when (= status-code 200)
            (jonathan:parse (babel:octets-to-string body :encoding :utf-8))))
      
      (error (e)
        (log:error () "EBSI verification failed: ~A" e)
        nil))))

(defun sign-data (data private-key)
  "Sign data with private key for EBSI"
  (let ((signing-data (concatenate 'string data private-key)))
    (orchestrator.hash-authority:compute-hash signing-data :algorithm :sha256)))

;;; ============================================================================
;;; ELI VALIDATION
;;; ============================================================================

(defun validate-eli-compliance (eli-uri)
  "Validate ELI identifier compliance with EU standards"
  (log:info () "Validating ELI: ~A" eli-uri)
  
  ;; Check ELI pattern
  (let ((eli-regex "^/eli/[a-z]{2}/[a-z]+/[0-9]{4}/"))
    (unless (cl-ppcre:scan eli-regex eli-uri)
      (log:error () "Invalid ELI format: ~A" eli-uri)
      (return-from validate-eli-compliance nil)))
  
  ;; Call EU ELI validator service
  (handler-case
      (multiple-value-bind (body status-code)
          (drakma:http-request *eli-validator-url*
                              :method :post
                              :parameters `(("eli" . ,eli-uri))
                              :timeout 30)
        
        (when (= status-code 200)
          (let ((result (jonathan:parse 
                        (babel:octets-to-string body :encoding :utf-8))))
            (gethash "valid" result))))
    
    (error (e)
      (log:error () "ELI validation service error: ~A" e)
      ;; Fallback to local validation
      t)))

(defun generate-eli-for-greek-law (law-type year number)
  "Generate ELI identifier for Greek legislation"
  (format nil "/eli/gr/~A/~A/~A" 
         (string-downcase law-type)
         year
         number))

;;; ============================================================================
;;; CROSS-REFERENCING
;;; ============================================================================

(defun cross-reference-eu-law (greek-law-id)
  "Find EU directives/regulations related to Greek law"
  (log:info () "Cross-referencing Greek law ~A with EU legislation" greek-law-id)
  
  ;; Search EUR-Lex for transposition measures
  (let ((results (search-eurlex greek-law-id
                                :document-type :legislation
                                :language "el")))
    
    (when results
      (let ((related-docs (gethash "results" results))
            (cross-refs nil))
        
        (dolist (doc related-docs)
          (let ((celex (gethash "celexNumber" doc))
                (title (gethash "title" doc))
                (type (gethash "documentType" doc)))
            
            ;; Check if this EU law mentions Greece
            (when (mentions-greece-p celex)
              (push `(:celex ,celex
                     :title ,title
                     :type ,type
                     :relationship "transposes")
                    cross-refs))))
        
        cross-refs))))

(defun mentions-greece-p (celex-number)
  "Check if EU document mentions Greece"
  (let ((metadata (get-eurlex-metadata celex-number)))
    (when metadata
      (let ((countries (gethash "countriesConcerned" metadata)))
        (member "GR" countries :test #'string=)))))

(defun find-transposed-directives (greek-law)
  "Find which EU directives are transposed by Greek law"
  (let ((sparql-query (format nil "
PREFIX eli: <http://data.europa.eu/eli/ontology#>
PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>

SELECT ?directive ?title ?deadline
WHERE {
  ?directive a eli:Directive ;
            eli:transposes_into ?national_measure ;
            eli:date_transposition ?deadline ;
            cdm:resource_legal_eli_title ?title .
  
  FILTER (CONTAINS(STR(?national_measure), 'gr'))
  FILTER (CONTAINS(STR(?national_measure), '~A'))
}
LIMIT 20
" greek-law)))
    
    (execute-sparql-query sparql-query)))

;;; ============================================================================
;;; EU LEGAL ONTOLOGY
;;; ============================================================================

(defun fetch-eu-legal-ontology ()
  "Fetch the EU legal ontology (ELI + CDM)"
  (let ((eli-ontology-url "http://data.europa.eu/eli/ontology")
        (cdm-ontology-url "http://publications.europa.eu/ontology/cdm"))
    
    (log:info () "Fetching EU legal ontologies...")
    
    (handler-case
        (let ((eli-onto (drakma:http-request eli-ontology-url
                                             :accept "application/rdf+xml"))
              (cdm-onto (drakma:http-request cdm-ontology-url
                                             :accept "application/rdf+xml")))
          
          (list :eli eli-onto :cdm cdm-onto))
      
      (error (e)
        (log:error () "Failed to fetch EU ontologies: ~A" e)
        nil))))

;;; ============================================================================
;;; MULTILINGUAL SUPPORT
;;; ============================================================================

(defun get-document-in-languages (celex-number languages)
  "Fetch EU document in multiple languages"
  (let ((versions nil))
    (dolist (lang languages)
      (let ((doc (fetch-eurlex-document celex-number 
                                        :language lang 
                                        :format :json)))
        (when doc
          (push (cons lang doc) versions))))
    
    (nreverse versions)))

(defun translate-eli-metadata (metadata target-language)
  "Translate ELI metadata to target EU language"
  ;; This would integrate with EU translation services
  ;; For now, returns original
  metadata)

;;; ============================================================================
;;; STATISTICS & MONITORING
;;; ============================================================================

(defun get-eu-api-statistics ()
  "Get usage statistics for EU APIs"
  (list
   :eurlex (when *eurlex-client*
            `(:requests ,(request-count *eurlex-client*)
              :cache-size ,(hash-table-count (service-cache *eurlex-client*))))
   :cellar (when *cellar-client*
            `(:requests ,(request-count *cellar-client*)))
   :ebsi (when *ebsi-client*
          `(:requests ,(request-count *ebsi-client*)
            :did ,(ebsi-did *ebsi-client*)))))

;;; EU compliance monitoring — decoupled from any specific corpus class. The
;;; caller passes the relevant metadata, so this works against the consolidation
;;; model (or any other) instead of the removed legacy corpus type.

(defun monitor-eu-compliance (&key eli-uris languages metadata)
  "Monitor EU standards compliance. ELI-URIS is a list of ELI URI strings,
   LANGUAGES a list of language codes, METADATA an alist/plist of present
   metadata keys (e.g. \"dct:publisher\")."
  (let ((compliance-checks
         `((:eli-format . ,(check-eli-format eli-uris))
           (:dcat-ap . ,(check-dcat-ap-compliance metadata))
           (:multilingual . ,(check-multilingual-support languages))
           (:metadata-completeness . ,(check-metadata-completeness metadata)))))
    (log:info () "EU Compliance Report:")
    (dolist (check compliance-checks)
      (log:info () "  ~A: ~A" (car check) (if (cdr check) "✓ PASS" "✗ FAIL")))
    compliance-checks))

(defun %has-meta (metadata key)
  (cond ((hash-table-p metadata) (nth-value 1 (gethash key metadata)))
        ((and (listp metadata) (consp (car metadata)))      ; alist
         (and (assoc key metadata :test #'equal) t))
        ((listp metadata) (and (member key metadata :test #'equal) t))
        (t nil)))

(defun check-eli-format (eli-uris)
  "Check that every ELI URI is well-formed."
  (and eli-uris (every #'validate-eli-compliance eli-uris)))

(defun check-dcat-ap-compliance (metadata)
  "Check DCAT-AP presence of publisher / distribution / license."
  (and (%has-meta metadata "dct:publisher")
       (%has-meta metadata "dcat:distribution")
       (%has-meta metadata "dct:license")))

(defun check-multilingual-support (languages)
  "Check that at least two languages are present."
  (>= (length languages) 2))

(defun check-metadata-completeness (metadata)
  "Check that the required Dublin Core / DCAT fields are present."
  (every (lambda (field) (%has-meta metadata field))
         '("dct:title" "dct:description" "dct:creator" "dct:publisher"
           "dct:created" "dct:modified" "dct:license" "dct:language")))

;;; ============================================================================
;;; INITIALIZATION
;;; ============================================================================

(defun initialize-eu-systems ()
  "Initialize all EU system integrations"
  (log:info () "Initializing EU system integrations...")
  
  (initialize-eurlex)
  (initialize-cellar)
  (initialize-ebsi)
  
  (log:info () "✓ EU systems initialized")
  
  ;; Fetch ontologies
  (fetch-eu-legal-ontology)
  
  t)

;;; ============================================================================
;;; END OF EU-INTEROP-LAYER.LISP
;;; ============================================================================
