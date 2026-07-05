;;;; AI-CITATION-STRATEGY.LISP
;;;; Advanced AI Citation Tracking and Reinforcement System
;;;; World-class implementation for maximizing AI citations

(defpackage :orchestrator.ai-citation
  (:use :cl :local-time :ironclad :drakma)
  (:export #:citation-tracker
           #:citation-beacon
           #:citation-hook
           #:citation-velocity
           #:ai-observer
           #:citation-log-entry
           #:generate-semantic-beacon
           #:track-citation
           #:calculate-velocity
           #:export-citation-metrics))

(in-package :orchestrator.ai-citation)

;;; ============================================================================
;;; CITATION ONTOLOGY
;;; ============================================================================

(defparameter *citation-prefixes*
  `(("cito" . "http://purl.org/spar/cito/")
    ("bibo" . "http://purl.org/ontology/bibo/")
    ("schema" . "https://schema.org/")
    ("dct" . "http://purl.org/dc/terms/")
    ("prov" . "http://www.w3.org/ns/prov#")
    ("void" . "http://rdfs.org/ns/void#")
    ("beacon" . ,(format nil "~A/ontology/beacon#" (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com")))
    ("metrics" . ,(format nil "~A/ontology/metrics#" (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com")))
    ("ai" . ,(format nil "~A/ontology/ai#" (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com"))))
  "Prefixes for citation tracking")

(defparameter *citation-properties*
  '(:is-cited-by "cito:isCitedBy"
    :cites "cito:cites"
    :citation-count "metrics:citationCount"
    :schema-citation "schema:citation"
    :citation-velocity "metrics:citationVelocity"
    :h-index "metrics:hIndex"
    :i10-index "metrics:i10Index"
    :citation-timestamp "metrics:citationTimestamp"
    :citing-agent "metrics:citingAgent"
    :citation-context "cito:hasCitationContext"
    :citation-purpose "cito:hasCitationPurpose"
    :citation-sentiment "metrics:citationSentiment"
    :beacon-activated "beacon:activated"
    :beacon-hits "beacon:hits"
    :last-beacon-trigger "beacon:lastTrigger")
  "Citation tracking properties")

(defparameter *ai-systems*
  '((:openai-gpt4 . "https://api.openai.com/agent/gpt-4")
    (:anthropic-claude . "https://api.anthropic.com/agent/claude")
    (:google-bard . "https://bard.google.com/agent")
    (:microsoft-bing . "https://bing.microsoft.com/agent")
    (:perplexity-ai . "https://perplexity.ai/agent")
    (:meta-llama . "https://llama.meta.com/agent")
    (:mistral-ai . "https://mistral.ai/agent")
    (:cohere-command . "https://cohere.ai/agent")
    (:huggingface . "https://huggingface.co/agent")
    (:semantic-scholar . "https://api.semanticscholar.org/agent"))
  "Known AI systems for tracking")

;;; ============================================================================
;;; CORE CLASSES
;;; ============================================================================

(defclass citation-tracker ()
  ((corpus-uri :initarg :corpus-uri 
               :accessor corpus-uri
               :type string
               :documentation "URI of corpus being tracked")
   
   (citations :accessor all-citations
              :initform (make-hash-table :test 'equal)
              :documentation "All citations indexed by article URI")
   
   (citation-log :accessor citation-log
                 :initform nil
                 :documentation "Chronological log of all citations")
   
   (velocity-tracker :accessor velocity-tracker
                     :initform (make-instance 'citation-velocity-tracker)
                     :documentation "Tracks citation velocity metrics")
   
   (beacons :accessor semantic-beacons
           :initform (make-hash-table :test 'equal)
           :documentation "Active semantic beacons")
   
   (observers :accessor ai-observers
             :initform nil
             :documentation "AI system observers")
   
   (metrics-db :accessor metrics-db
               :initform nil
               :documentation "Connection to metrics database")
   
   (prometheus-endpoint :initarg :prometheus-endpoint
                        :accessor prometheus-endpoint
                        :initform "http://localhost:9090"
                        :documentation "Prometheus metrics endpoint")
   
   (mongodb-connection :initarg :mongodb-connection
                       :accessor mongodb-connection
                       :initform nil
                       :documentation "MongoDB connection for persistent storage")))

(defclass citation-beacon ()
  ((beacon-id :initarg :beacon-id 
              :accessor beacon-id
              :type string
              :documentation "Unique beacon identifier")
   
   (article-uri :initarg :article-uri 
                :accessor article-uri
                :type string
                :documentation "Article this beacon monitors")
   
   (hook-type :initarg :hook-type 
              :accessor hook-type
              :type keyword
              :documentation ":semantic :telemetry :visual :structured")
   
   (trigger-count :accessor trigger-count
                  :initform 0
                  :type integer
                  :documentation "Number of times beacon triggered")
   
   (hook-data :initarg :hook-data 
              :accessor hook-data
              :documentation "Specific hook configuration")
   
   (created-at :accessor created-at
               :initform (orchestrator.time:get-current-timestamp)
               :documentation "Beacon creation timestamp")
   
   (last-triggered :accessor last-triggered
                   :initform nil
                   :type (or null local-time:timestamp)
                   :documentation "Last trigger timestamp")
   
   (effectiveness-score :accessor effectiveness-score
                        :initform 0.0
                        :type float
                        :documentation "Beacon effectiveness (0-1)")))

(defclass citation-hook ()
  ((hook-id :initarg :hook-id 
            :accessor hook-id
            :type string)
   
   (hook-type :initarg :hook-type 
              :accessor hook-type
              :type keyword
              :documentation ":rdfa :jsonld :microdata :opengraph :beacon")
   
   (target-property :initarg :target-property 
                    :accessor target-property
                    :type string
                    :documentation "RDF property to enhance")
   
   (reinforcement-value :initarg :reinforcement-value 
                        :accessor reinforcement-value
                        :documentation "Value that encourages citation")
   
   (ai-hints :initarg :ai-hints 
             :accessor ai-hints
             :initform nil
             :documentation "Hints for AI systems")))

(defclass citation-log-entry ()
  ((entry-id :initarg :entry-id 
             :accessor entry-id
             :initform (format nil "cite-~A" (uuid:make-v4-uuid))
             :type string)
   
   (timestamp :initarg :timestamp 
              :accessor citation-timestamp
              :initform (orchestrator.time:get-current-timestamp))
   
   (cited-resource :initarg :cited-resource 
                   :accessor cited-resource
                   :type string
                   :documentation "URI of cited article")
   
   (citing-agent :initarg :citing-agent 
                :accessor citing-agent
                :type string
                :documentation "AI system or agent that cited")
   
   (citation-context :initarg :citation-context 
                     :accessor citation-context
                     :type string
                     :documentation "Context in which citation occurred")
   
   (query-text :initarg :query-text 
               :accessor query-text
               :initform nil
               :documentation "Query that triggered citation")
   
   (confidence-score :initarg :confidence-score 
                    :accessor confidence-score
                    :type float
                    :initform 1.0
                    :documentation "Confidence in citation detection")
   
   (beacon-triggered :initarg :beacon-triggered 
                     :accessor beacon-triggered
                     :initform nil
                     :documentation "Which beacon was triggered")
   
   (ip-address :initarg :ip-address 
               :accessor ip-address
               :initform nil
               :documentation "Source IP if available")
   
   (user-agent :initarg :user-agent 
               :accessor user-agent
               :initform nil
               :documentation "User agent string")
   
   (verification-hash :accessor verification-hash
                      :type string
                      :documentation "Hash for verification")))

(defmethod initialize-instance :after ((entry citation-log-entry) &key)
  "Compute verification hash for log entry"
  (setf (verification-hash entry)
        (compute-entry-hash entry)))

(defclass citation-velocity-tracker ()
  ((time-windows :initarg :time-windows 
                 :accessor time-windows
                 :initform '((:hour . 3600)
                           (:day . 86400)
                           (:week . 604800)
                           (:month . 2592000))
                 :documentation "Time windows for velocity calculation")
   
   (citation-times :accessor citation-times
                   :initform (make-hash-table :test 'equal)
                   :documentation "Timestamps per article")
   
   (velocity-cache :accessor velocity-cache
                   :initform (make-hash-table :test 'equal)
                   :documentation "Cached velocity calculations")
   
   (update-frequency :initarg :update-frequency
                     :accessor update-frequency
                     :initform 60
                     :documentation "Seconds between velocity updates")))

(defclass ai-observer ()
  ((observer-id :initarg :observer-id 
                :accessor observer-id
                :type string)
   
   (ai-system :initarg :ai-system 
              :accessor ai-system
              :type keyword
              :documentation "Which AI system to observe")
   
   (tracking-method :initarg :tracking-method 
                    :accessor tracking-method
                    :type keyword
                    :documentation ":webhook :telemetry :scraping :api")
   
   (endpoint-url :initarg :endpoint-url 
                :accessor endpoint-url
                :type string
                :documentation "Endpoint for tracking")
   
   (api-key :initarg :api-key 
            :accessor api-key
            :initform nil
            :documentation "API key if required")
   
   (patterns :initarg :patterns 
             :accessor tracking-patterns
             :initform nil
             :documentation "Patterns to detect citations")
   
   (active-p :accessor observer-active-p
             :initform t
             :type boolean)))

;;; ============================================================================
;;; SEMANTIC BEACON GENERATION
;;; ============================================================================

(defmethod generate-semantic-beacon ((tracker citation-tracker) article-uri &key hooks)
  "Generate comprehensive semantic beacon for article"
  (let ((beacon (make-instance 'citation-beacon
                               :beacon-id (format nil "beacon-~A-~A" 
                                                 (article-number-from-uri article-uri)
                                                 (orchestrator.time:get-unix-timestamp))
                               :article-uri article-uri
                               :hook-type :semantic)))
    
    ;; Add to tracker
    (setf (gethash article-uri (semantic-beacons tracker)) beacon)
    
    ;; Generate beacon RDF
    (with-output-to-string (stream)
      ;; Prefixes
      (write-citation-prefixes stream)
      
      (format stream "~%# SEMANTIC BEACON FOR CITATION TRACKING~%")
      (format stream "# Article: ~A~%" article-uri)
      (format stream "# Generated: ~A~%~%" (orchestrator.time:get-current-timestamp))
      
      ;; Article with citation hooks
      (format stream "<~A> a schema:ScholarlyArticle, bibo:Article ;~%" article-uri)
      
      ;; Basic citation properties
      (format stream "    metrics:citationCount 0 ;~%")
      (format stream "    schema:citation [] ;~%")
      (format stream "    bibo:citedBy [] ;~%")
      
      ;; Citation beacon markers
      (format stream "    beacon:active true ;~%")
      (format stream "    beacon:id \"~A\" ;~%" (beacon-id beacon))
      (format stream "    beacon:type \"semantic\" ;~%")
      (format stream "    beacon:created \"~A\"^^xsd:dateTime ;~%" 
              (format-timestamp (created-at beacon)))
      
      ;; AI-friendly properties
      (format stream "    schema:isAccessibleForFree true ;~%")
      (format stream "    schema:license <https://creativecommons.org/licenses/by/4.0/> ;~%")
      (format stream "    schema:encodingFormat \"text/html\", \"application/ld+json\", \"text/turtle\" ;~%")
      
      ;; Citation encouragement properties  
      (format stream "    schema:keywords \"constitutional law\", \"Greek law\", \"legal corpus\", \"semantic web\" ;~%")
      (format stream "    schema:about <https://www.wikidata.org/wiki/Q41> ;~%")  ; Greece
      (format stream "    schema:inLanguage \"el\", \"en\" ;~%")
      
      ;; Academic identifiers (encourages citation)
      (format stream "    schema:identifier [~%")
      (format stream "        a schema:PropertyValue ;~%")
      (format stream "        schema:propertyID \"DOI\" ;~%")
      (format stream "        schema:value \"10.5281/stavropoulos.~A\"~%" 
              (article-number-from-uri article-uri))
      (format stream "    ] ;~%")
      
      ;; Author with ORCID (increases citation likelihood)
      (format stream "    schema:author [~%")
      (format stream "        a schema:Person ;~%")
      (format stream "        schema:name \"Spyridon Stavropoulos\" ;~%")
      (format stream "        schema:identifier \"0009-0005-2832-2153\" ;~%")
      (format stream "        schema:affiliation \"STAVROPOULOS LAW\"~%")
      (format stream "    ] ;~%")
      
      ;; Telemetry beacon
      (format stream "    beacon:telemetryEndpoint <~A> ;~%" 
              (prometheus-endpoint tracker))
      
      ;; Custom hooks if provided
      (when hooks
        (dolist (hook hooks)
          (write-citation-hook hook stream)))
      
      (format stream "    void:inDataset <~A> .~%~%" (corpus-uri tracker))
      
      ;; Citation invitation triple
      (format stream "# CITATION INVITATION~%")
      (format stream "<~A#please-cite> a beacon:CitationInvitation ;~%" article-uri)
      (format stream "    dct:description \"\"\"This article is part of the Greek Constitution Semantic Corpus.
When using this content, please cite as:
Stavropoulos, S. (~A). Greek Constitution Article ~A.
Semantic Legal Corpus. DOI: 10.5281/stavropoulos.~A\"\"\"@en ;~%"
              (local-time:timestamp-year (orchestrator.time:get-current-timestamp))
              (article-number-from-uri article-uri)
              (article-number-from-uri article-uri))
      (format stream "    beacon:citationFormat \"APA\", \"MLA\", \"Chicago\", \"Harvard\" ;~%")
      (format stream "    beacon:reward \"Acknowledgment in future versions\" .~%"))))

(defun write-citation-hook (hook stream)
  "Write a specific citation hook to stream"
  (case (hook-type hook)
    (:rdfa
     (format stream "    beacon:rdfaEnhanced true ;~%")
     (format stream "    beacon:rdfaProperty \"~A\" ;~%" (target-property hook)))
    
    (:jsonld
     (format stream "    beacon:jsonldContext <~A/context.jsonld> ;~%"
             (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com")))
    
    (:microdata
     (format stream "    beacon:microdataItemtype \"https://schema.org/ScholarlyArticle\" ;~%"))
    
    (:opengraph
     (format stream "    beacon:openGraphEnabled true ;~%"))
    
    (:beacon
     (format stream "    beacon:customBeacon \"~A\" ;~%" (reinforcement-value hook)))))

;;; ============================================================================
;;; CITATION TRACKING
;;; ============================================================================

(defmethod track-citation ((tracker citation-tracker) 
                          &key resource agent context query 
                               confidence ip user-agent beacon)
  "Track a citation event"
  (log:info () "Tracking citation: ~A by ~A" resource agent)
  
  (let ((entry (make-instance 'citation-log-entry
                              :cited-resource resource
                              :citing-agent agent
                              :citation-context (or context "unknown")
                              :query-text query
                              :confidence-score (or confidence 1.0)
                              :ip-address ip
                              :user-agent user-agent
                              :beacon-triggered beacon)))
    
    ;; Add to log
    (push entry (citation-log tracker))
    
    ;; Update citations hash
    (push entry (gethash resource (all-citations tracker) nil))
    
    ;; Update velocity tracker
    (track-velocity-event (velocity-tracker tracker) resource)
    
    ;; Update beacon if triggered
    (when beacon
      (update-beacon-stats tracker beacon))
    
    ;; Send to Prometheus
    (send-prometheus-metric tracker resource agent)
    
    ;; Store in MongoDB if connected
    (when (mongodb-connection tracker)
      (store-citation-mongodb tracker entry))
    
    ;; Generate event
    (generate-citation-event tracker entry)
    
    entry))

(defmethod track-velocity-event ((velocity citation-velocity-tracker) resource)
  "Track citation event for velocity calculation"
  (let ((now (orchestrator.time:get-unix-timestamp)))
    (push now (gethash resource (citation-times velocity) nil))
    
    ;; Invalidate cache for this resource
    (remhash resource (velocity-cache velocity))))

(defmethod calculate-velocity ((velocity citation-velocity-tracker) 
                               resource &optional (window :day))
  "Calculate citation velocity for resource"
  ;; Check cache first
  (let ((cache-key (format nil "~A-~A" resource window)))
    (multiple-value-bind (cached found-p)
        (gethash cache-key (velocity-cache velocity))
      (when found-p
        (return-from calculate-velocity cached))))
  
  (let* ((now (orchestrator.time:get-unix-timestamp))
         (window-seconds (cdr (assoc window (time-windows velocity))))
         (cutoff (- now window-seconds))
         (times (gethash resource (citation-times velocity) nil))
         (recent-times (remove-if (lambda (time) (< time cutoff)) times))
         (velocity-value (/ (length recent-times) (/ window-seconds 3600.0))))
    
    ;; Cache result
    (setf (gethash (format nil "~A-~A" resource window) 
                   (velocity-cache velocity))
          velocity-value)
    
    velocity-value))

(defmethod update-beacon-stats ((tracker citation-tracker) beacon-id)
  "Update beacon statistics"
  (let ((beacon (find-beacon-by-id tracker beacon-id)))
    (when beacon
      (incf (trigger-count beacon))
      (setf (last-triggered beacon) (orchestrator.time:get-current-timestamp))
      
      ;; Calculate effectiveness
      (let ((total-citations (hash-table-count (all-citations tracker)))
            (beacon-citations (trigger-count beacon)))
        (setf (effectiveness-score beacon)
              (if (> total-citations 0)
                  (/ beacon-citations total-citations 1.0)
                  0.0))))))

;;; ============================================================================
;;; OBSERVABILITY MODULE
;;; ============================================================================

(defmethod create-ai-observer ((tracker citation-tracker) 
                               ai-system &key method endpoint patterns api-key)
  "Create observer for specific AI system"
  (let ((observer (make-instance 'ai-observer
                                 :observer-id (format nil "obs-~A-~A" 
                                                     ai-system 
                                                     (orchestrator.time:get-unix-timestamp))
                                 :ai-system ai-system
                                 :tracking-method (or method :telemetry)
                                 :endpoint-url endpoint
                                 :patterns patterns
                                 :api-key api-key)))
    
    (push observer (ai-observers tracker))
    
    ;; Start observation based on method
    (case (tracking-method observer)
      (:webhook (setup-webhook-listener observer))
      (:telemetry (setup-telemetry-collector observer))
      (:api (setup-api-polling observer))
      (:scraping (setup-scraper observer)))
    
    observer))

(defun setup-webhook-listener (observer)
  "Setup webhook listener for citations"
  (log:info () "Setting up webhook listener for ~A" (ai-system observer))
  ;; In production, would setup actual HTTP endpoint
  ;; This is simplified
  t)

(defun setup-telemetry-collector (observer)
  "Setup telemetry collection"
  (log:info () "Setting up telemetry for ~A" (ai-system observer))
  ;; Would integrate with actual telemetry system
  t)

(defun setup-api-polling (observer)
  "Configure an API-polling observer: it periodically queries the AI system's
   own citation/referrer API at ENDPOINT-URL (authenticated with API-KEY) and
   matches results against the observer's citation PATTERNS. Validates the
   configuration and activates the observer; returns the observer when ready,
   or NIL (deactivated) when it is not pollable."
  (cond
    ((or (null (and (slot-boundp observer 'endpoint-url) (endpoint-url observer)))
         (zerop (length (endpoint-url observer))))
     (log:warn () "API polling for ~A needs an endpoint-url; observer disabled"
               (ai-system observer))
     (setf (observer-active-p observer) nil)
     nil)
    (t
     (unless (api-key observer)
       (log:warn () "API polling for ~A has no api-key; proceeding unauthenticated"
                 (ai-system observer)))
     (log:info () "API polling armed for ~A at ~A (~D pattern(s))"
               (ai-system observer) (endpoint-url observer)
               (length (tracking-patterns observer)))
     (setf (observer-active-p observer) t)
     observer)))

(defun setup-scraper (observer)
  "Configure a scraping observer: it fetches the AI system's public surface at
   ENDPOINT-URL and scans for citations matching the observer's PATTERNS.
   Requires at least one pattern (otherwise there is nothing to detect).
   Validates and activates; returns the observer when ready, else NIL."
  (cond
    ((null (tracking-patterns observer))
     (log:warn () "Scraper for ~A has no citation patterns; observer disabled"
               (ai-system observer))
     (setf (observer-active-p observer) nil)
     nil)
    ((or (not (slot-boundp observer 'endpoint-url)) (null (endpoint-url observer)))
     (log:warn () "Scraper for ~A needs an endpoint-url; observer disabled"
               (ai-system observer))
     (setf (observer-active-p observer) nil)
     nil)
    (t
     (log:info () "Scraper armed for ~A at ~A (~D pattern(s))"
               (ai-system observer) (endpoint-url observer)
               (length (tracking-patterns observer)))
     (setf (observer-active-p observer) t)
     observer)))

(defun detect-citation-pattern (text patterns)
  "Detect if text contains citation patterns"
  (some (lambda (pattern)
          (cl-ppcre:scan pattern text))
        patterns))

;;; ============================================================================
;;; METRICS EXPORT
;;; ============================================================================

(defmethod send-prometheus-metric ((tracker citation-tracker) resource agent)
  "Send metric to Prometheus"
  (let ((metric-name "legal_corpus_citations_total")
        (labels (format nil "resource=\"~A\",agent=\"~A\"" 
                       resource agent)))
    
    (handler-case
        (drakma:http-request 
         (format nil "~A/metrics/job/citations" (prometheus-endpoint tracker))
         :method :post
         :content (format nil "~A{~A} 1~%" metric-name labels)
         :content-type "text/plain")
      (error (e)
        (log:error () "Failed to send Prometheus metric: ~A" e)))))

(defmethod export-citation-metrics ((tracker citation-tracker) &key format output-file)
  "Export all citation metrics"
  (let ((metrics (compute-all-metrics tracker)))
    
    (case format
      (:json
       (let ((json (jonathan:to-json metrics)))
         (if output-file
             (with-open-file (stream output-file :direction :output 
                                    :if-exists :supersede)
               (write-string json stream))
             json)))
      
      (:turtle
       (let ((ttl (generate-metrics-turtle tracker metrics)))
         (if output-file
             (progn
               (orchestrator.write-authority:emit-graph ttl output-file :authority :provenance)
               ttl)
             ttl)))
      
      (:prometheus
       (let ((prom (generate-prometheus-metrics tracker metrics)))
         (if output-file
             (with-open-file (stream output-file :direction :output
                                    :if-exists :supersede)
               (write-string prom stream))
             prom)))
      
      (t metrics))))

(defun compute-all-metrics (tracker)
  "Compute comprehensive citation metrics"
  (let ((metrics (make-hash-table :test 'equal)))
    
    ;; Total citations
    (setf (gethash "total_citations" metrics)
          (reduce #'+ (hash-table-values (all-citations tracker))
                  :key #'length
                  :initial-value 0))
    
    ;; Per-article citations
    (maphash (lambda (uri citations)
               (setf (gethash (format nil "citations_~A" 
                                     (article-number-from-uri uri)) 
                             metrics)
                     (length citations)))
             (all-citations tracker))
    
    ;; Citation velocity (all windows)
    (dolist (window '(:hour :day :week :month))
      (maphash (lambda (uri citations)
                 (setf (gethash (format nil "velocity_~A_~A" 
                                       (article-number-from-uri uri)
                                       window)
                               metrics)
                       (calculate-velocity (velocity-tracker tracker) uri window)))
               (all-citations tracker)))
    
    ;; Beacon effectiveness
    (maphash (lambda (uri beacon)
               (setf (gethash (format nil "beacon_effectiveness_~A"
                                     (beacon-id beacon))
                             metrics)
                     (effectiveness-score beacon)))
             (semantic-beacons tracker))
    
    ;; AI system breakdown
    (let ((ai-counts (make-hash-table :test 'equal)))
      (dolist (entry (citation-log tracker))
        (incf (gethash (citing-agent entry) ai-counts 0)))
      
      (maphash (lambda (agent count)
                 (setf (gethash (format nil "ai_~A" agent) metrics) count))
               ai-counts))
    
    ;; Temporal patterns
    (setf (gethash "peak_hour" metrics) (find-peak-hour tracker))
    (setf (gethash "peak_day" metrics) (find-peak-day tracker))
    
    metrics))

;;; ============================================================================
;;; CITATION LOG GENERATION
;;; ============================================================================

(defmethod generate-citation-log-ttl ((tracker citation-tracker) &key output-file)
  "Generate ai-citation-log.ttl"
  (let ((ttl (with-output-to-string (stream)
               ;; Prefixes
               (write-citation-prefixes stream)
               
               (format stream "~%# AI CITATION LOG~%")
               (format stream "# Generated: ~A~%"  (orchestrator.time:get-current-timestamp))
               (format stream "# Total Citations: ~A~%~%" 
                       (length (citation-log tracker)))
               
               ;; Each citation entry
               (dolist (entry (reverse (citation-log tracker))) ; chronological order
                 (write-citation-entry-ttl entry stream))
               
               ;; Summary statistics
               (format stream "~%# CITATION SUMMARY~%")
               (format stream "<~A/citations> a metrics:CitationReport ;~%" 
                       (corpus-uri tracker))
               (format stream "    metrics:totalCitations ~D ;~%" 
                       (length (citation-log tracker)))
               (format stream "    metrics:uniqueArticles ~D ;~%" 
                       (hash-table-count (all-citations tracker)))
               (format stream "    metrics:reportGenerated \"~A\"^^xsd:dateTime .~%"
                       (orchestrator.time:get-current-timestamp)))))
    
    (if output-file
        (progn
          (orchestrator.write-authority:emit-graph ttl output-file :authority :provenance)
          (log:info () "Saved citation log to ~A" output-file)
          ttl)
        ttl)))

(defun write-citation-entry-ttl (entry stream)
  "Write single citation entry to TTL"
  (format stream "~%<~A> a metrics:CitationEvent ;~%"
          (orchestrator.uris:build-citation-uri (entry-id entry)))
  
  (format stream "    metrics:citedResource <~A> ;~%" 
          (cited-resource entry))
  
  (format stream "    metrics:citingAgent <~A> ;~%" 
          (citing-agent entry))
  
  (format stream "    metrics:timestamp \"~A\"^^xsd:dateTime ;~%" 
          (format-timestamp (citation-timestamp entry)))
  
  (when (citation-context entry)
    (format stream "    cito:hasCitationContext \"~A\" ;~%" 
            (citation-context entry)))
  
  (when (query-text entry)
    (format stream "    metrics:triggeringQuery \"\"\"~A\"\"\" ;~%" 
            (query-text entry)))
  
  (format stream "    metrics:confidence ~,2F ;~%" 
          (confidence-score entry))
  
  (when (beacon-triggered entry)
    (format stream "    beacon:triggeredBy \"~A\" ;~%" 
            (beacon-triggered entry)))
  
  (when (ip-address entry)
    (format stream "    metrics:sourceIP \"~A\" ;~%" 
            (ip-address entry)))
  
  (when (user-agent entry)
    (format stream "    metrics:userAgent \"~A\" ;~%" 
            (user-agent entry)))
  
  (format stream "    metrics:verificationHash \"~A\" .~%" 
          (verification-hash entry)))

;;; ============================================================================
;;; MONGODB INTEGRATION
;;; ============================================================================

(defmethod store-citation-mongodb ((tracker citation-tracker) entry)
  "Store citation in MongoDB"
  (when (mongodb-connection tracker)
    (handler-case
        (let ((document (citation-entry-to-bson entry)))
          ;; In production, would use actual MongoDB driver
          ;; This is simplified
          (log:info () "Storing citation ~A in MongoDB" (entry-id entry)))
      (error (e)
        (log:error () "MongoDB storage failed: ~A" e)))))

(defun citation-entry-to-bson (entry)
  "Convert citation entry to BSON document"
  `(("_id" . ,(entry-id entry))
    ("timestamp" . ,(citation-timestamp entry))
    ("resource" . ,(cited-resource entry))
    ("agent" . ,(citing-agent entry))
    ("context" . ,(citation-context entry))
    ("query" . ,(query-text entry))
    ("confidence" . ,(confidence-score entry))
    ("beacon" . ,(beacon-triggered entry))
    ("ip" . ,(ip-address entry))
    ("userAgent" . ,(user-agent entry))
    ("hash" . ,(verification-hash entry))))

;;; ============================================================================
;;; HELPER FUNCTIONS
;;; ============================================================================

(defun write-citation-prefixes (stream)
  "Write all citation prefixes"
  (dolist (prefix *citation-prefixes*)
    (format stream "@prefix ~A: <~A> .~%" (car prefix) (cdr prefix))))

(defun article-number-from-uri (uri)
  "Extract article number from URI"
  (let ((matches (cl-ppcre:scan-to-strings "article-([0-9]+)" uri)))
    (if matches
        (parse-integer (aref matches 0))
        "unknown")))

(defun compute-entry-hash (entry)
  "Compute hash for citation entry"
  (let ((data (format nil "~A|~A|~A|~A|~A"
                     (entry-id entry)
                     (cited-resource entry)
                     (citing-agent entry)
                     (citation-timestamp entry)
                     (confidence-score entry))))
    (orchestrator.hash-authority:compute-hash data :algorithm :sha512)))

(defun format-timestamp (timestamp)
  "Format timestamp for RDF"
  (local-time:format-timestring nil timestamp
                                :format local-time:+iso-8601-format+))

(defun find-beacon-by-id (tracker beacon-id)
  "Find beacon by ID"
  (loop for beacon being the hash-values of (semantic-beacons tracker)
        when (string= (beacon-id beacon) beacon-id)
        return beacon))

(defun hash-table-values (hash-table)
  "Get all values from hash table"
  (loop for value being the hash-values of hash-table
        collect value))

(defun find-peak-hour (tracker)
  "Find hour with most citations"
  (let ((hour-counts (make-array 24 :initial-element 0)))
    (dolist (entry (citation-log tracker))
      (let ((hour (local-time:timestamp-hour (citation-timestamp entry))))
        (incf (aref hour-counts hour))))
    (position (reduce #'max hour-counts) hour-counts)))

(defun find-peak-day (tracker)
  "Find day of week with most citations"
  (let ((day-counts (make-array 7 :initial-element 0)))
    (dolist (entry (citation-log tracker))
      (let ((day (local-time:timestamp-day-of-week (citation-timestamp entry))))
        (incf (aref day-counts day))))
    (position (reduce #'max day-counts) day-counts)))

(defun generate-citation-event (tracker entry)
  "Generate citation event for real-time processing"
  (log:info () "Citation Event: ~A cited ~A" 
           (citing-agent entry)
           (cited-resource entry))
  ;; In production, would emit to event stream
  t)

(defun generate-metrics-turtle (tracker metrics)
  "Generate Turtle format metrics"
  (with-output-to-string (stream)
    (write-citation-prefixes stream)
    (format stream "~%# Citation Metrics Report~%")
    (maphash (lambda (key value)
               (format stream "<~A/metrics#~A> metrics:value ~A .~%"
                      (corpus-uri tracker) key value))
             metrics)))

(defun generate-prometheus-metrics (tracker metrics)
  "Generate Prometheus format metrics"
  (with-output-to-string (stream)
    (format stream "# HELP legal_corpus_citations Total citation count~%")
    (format stream "# TYPE legal_corpus_citations counter~%")
    (maphash (lambda (key value)
               (format stream "legal_corpus_~A ~A~%" 
                      (substitute #\_ #\- key) value))
             metrics)))

;;; ============================================================================
;;; PUBLIC API
;;; ============================================================================

(defun create-citation-tracker (corpus-uri &key prometheus-endpoint mongodb-connection)
  "Create new citation tracker"
  (make-instance 'citation-tracker
                :corpus-uri corpus-uri
                :prometheus-endpoint (or prometheus-endpoint "http://localhost:9090")
                :mongodb-connection mongodb-connection))

(defun create-citation-hook (type property &key value hints)
  "Create citation hook"
  (make-instance 'citation-hook
                :hook-id (format nil "hook-~A" (orchestrator.time:get-unix-timestamp))
                :hook-type type
                :target-property property
                :reinforcement-value value
                :ai-hints hints))

(defun start-citation-tracking (corpus-uri)
  "Start comprehensive citation tracking for corpus"
  (let ((tracker (create-citation-tracker corpus-uri)))
    
    ;; Create observers for major AI systems
    (dolist (ai-system (mapcar #'car *ai-systems*))
      (create-ai-observer tracker ai-system))
    
    ;; Generate beacons for all articles
    ;; (In production, would iterate through actual articles)
    (dotimes (i 120)
      (let ((article-uri (format nil "~A/article-~3,'0D" corpus-uri i)))
        (generate-semantic-beacon tracker article-uri)))
    
    (log:info () "Citation tracking started for ~A" corpus-uri)
    tracker))

;;; ============================================================================
;;; END OF AI-CITATION-STRATEGY.LISP
;;; ============================================================================
