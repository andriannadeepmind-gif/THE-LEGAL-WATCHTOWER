;;;; AI-INGEST-MANIFEST.LISP
;;;; Advanced AI Ingestion Manifest System for LLM Optimization
;;;; World-class implementation for maximum AI digestibility

(defpackage :orchestrator.ai-ingest
  (:use :cl :local-time :ironclad)
  (:export #:ingest-manifest
           #:article-saturation
           #:uri-density-analyzer
           #:huggingface-formatter
           #:llm-optimizer
           #:generate-ai-manifest
           #:calculate-saturation
           #:export-huggingface-dataset
           #:build-corpus-manifest
           #:manifest->huggingface-formatter
           #:export-corpus-dataset
           #:manifest->json-string
           #:dataset-jsonl-string
           #:serialize-manifest-rdf
           #:manifest-articles-ordered
           #:create-ai-manifest))

(in-package :orchestrator.ai-ingest)

;;; ============================================================================
;;; AI INGEST ONTOLOGY
;;; ============================================================================

(defparameter *ingest-prefixes*
  `(("llm" . ,(format nil "~A/ontology/llm#" (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com")))
    ("hf" . "https://huggingface.co/ontology#")
    ("ingest" . ,(format nil "~A/ontology/ingest#" (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com")))
    ("metrics" . ,(format nil "~A/ontology/metrics#" (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com")))
    ("schema" . "https://schema.org/")
    ("dcat" . "http://www.w3.org/ns/dcat#")
    ("dct" . "http://purl.org/dc/terms/")
    ("xsd" . "http://www.w3.org/2001/XMLSchema#")
    ("void" . "http://rdfs.org/ns/void#")
    ("prov" . "http://www.w3.org/ns/prov#")
    ("eli" . "http://data.europa.eu/eli/ontology#")
    ("rdfs" . "http://www.w3.org/2000/01/rdf-schema#"))
  "Prefixes for AI ingestion")

(defparameter *saturation-factors*
  '((:rdfa . 0.20)           ; RDFa annotations present
    (:structured-citation . 0.15)  ; Structured citations
    (:backlinks . 0.15)      ; Backlinks from other articles
    (:json-ld . 0.15)        ; JSON-LD embedded
    (:microdata . 0.10)     ; Microdata markup
    (:opengraph . 0.10)     ; Open Graph tags
    (:schema-org . 0.10)    ; Schema.org markup
    (:telemetry . 0.05))    ; Telemetry beacon
  "Weights for saturation level calculation")

(defparameter *llm-optimization-params*
  '((:max-context-length . 128000)  ; GPT-4 Turbo context
    (:optimal-chunk-size . 4096)    ; Optimal chunk for embeddings
    (:overlap-ratio . 0.1)          ; 10% overlap between chunks
    (:min-uri-density . 0.05)       ; Minimum 5% URIs
    (:max-uri-density . 0.25)       ; Maximum 25% URIs
    (:target-saturation . 0.85))    ; Target 85% saturation
  "LLM optimization parameters")

;;; ============================================================================
;;; CORE CLASSES
;;; ============================================================================

(defclass ingest-manifest ()
  ((manifest-id :initarg :manifest-id
                :accessor manifest-id
                :initform (format nil "manifest-~A" (orchestrator.time:now :source :deterministic))
                :type string
                :documentation "Unique manifest identifier")
   
   (corpus-uri :initarg :corpus-uri 
               :accessor corpus-uri
               :type string
               :documentation "URI of corpus")
   
   (generated-at :accessor generated-at
                 :initform (orchestrator.time:get-current-timestamp)
                 :documentation "Manifest generation timestamp")
   
   (total-articles :accessor total-articles
                   :type integer
                   :documentation "Total number of articles")
   
   (total-tokens :accessor total-tokens
                 :type integer
                 :initform 0
                 :documentation "Total token count")
   
   (total-uris :accessor total-uris
               :type integer
               :initform 0
               :documentation "Total URI count")
   
   (avg-uri-density :accessor avg-uri-density
                    :type float
                    :initform 0.0
                    :documentation "Average URI density")
   
   (avg-saturation :accessor avg-saturation
                   :type float
                   :initform 0.0
                   :documentation "Average saturation level")
   
   (article-metadata :accessor article-metadata
                     :initform (make-hash-table :test 'equal)
                     :documentation "Per-article metadata")
   
   (huggingface-config :accessor huggingface-config
                       :initform nil
                       :documentation "HuggingFace dataset config")
   
   (llm-hints :accessor llm-hints
              :initform nil
              :documentation "Hints for LLM processing")
   
   (ingestion-stats :accessor ingestion-stats
                    :initform nil
                    :documentation "Ingestion statistics")))

(defclass article-saturation ()
  ((article-uri :initarg :article-uri 
                :accessor article-uri
                :type string)
   
   (article-number :initarg :article-number 
                   :accessor article-number
                   :type integer)
   
   (token-count :initarg :token-count 
                :accessor token-count
                :type integer
                :initform 0
                :documentation "Number of tokens in article")
   
   (uri-count :initarg :uri-count 
              :accessor uri-count
              :type integer
              :initform 0
              :documentation "Number of URIs in article")
   
   (uri-density :accessor uri-density
                :type float
                :initform 0.0
                :documentation "URI:token ratio")
   
   (saturation-components :accessor saturation-components
                          :initform (make-hash-table :test 'eq)
                          :documentation "Individual saturation factors")
   
   (total-saturation :accessor total-saturation
                     :type float
                     :initform 0.0
                     :documentation "Overall saturation level (0-1)")
   
   (rdfa-present :accessor rdfa-present
                 :type boolean
                 :initform nil)
   
   (structured-citations :accessor structured-citations
                        :type integer
                        :initform 0)
   
   (backlink-count :accessor backlink-count
                   :type integer
                   :initform 0)
   
   (json-ld-present :accessor json-ld-present
                    :type boolean
                    :initform nil)
   
   (embeddings :accessor article-embeddings
               :initform nil
               :documentation "Pre-computed embeddings")

   (chunk-boundaries :accessor chunk-boundaries
                     :initform nil
                     :documentation "Optimal chunk boundaries for LLM")

   (eid :initarg :eid :accessor article-eid :initform ""
        :type string :documentation "Akoma Ntoso eId of the article")

   (title :initarg :title :accessor article-title :initform ""
          :type string :documentation "Article heading/title")

   (content :initarg :content :accessor article-content :initform ""
            :type string :documentation "Full in-force article text")

   (status :initarg :status :accessor article-status :initform :original
           :documentation "Consolidation status (:original/:amended/:repealed/…)")

   (ingestion-ready :accessor ingestion-ready
                    :type boolean
                    :initform nil
                    :documentation "Ready for LLM ingestion")))

(defclass uri-density-analyzer ()
  ((corpus-analyzer :initarg :corpus-analyzer 
                   :accessor corpus-analyzer
                   :documentation "Analyzes entire corpus")
   
   (uri-patterns :accessor uri-patterns
                 :initform nil
                 :documentation "Common URI patterns")
   
   (token-counter :accessor token-counter
                  :initform (make-hash-table :test 'equal)
                  :documentation "Token counts per article")
   
   (uri-counter :accessor uri-counter
                :initform (make-hash-table :test 'equal)
                :documentation "URI counts per article")
   
   (density-distribution :accessor density-distribution
                         :initform nil
                         :documentation "Distribution of URI densities")
   
   (optimal-density :accessor optimal-density
                    :type float
                    :initform 0.15
                    :documentation "Optimal URI density for LLMs")))

(defclass huggingface-formatter ()
  ((dataset-name :initarg :dataset-name 
                 :accessor dataset-name
                 :type string
                 :initform "stavropoulos/greek-constitution-semantic"
                 :documentation "HuggingFace dataset name")
   
   (dataset-config :accessor dataset-config
                   :documentation "Dataset configuration")
   
   (features-schema :accessor features-schema
                    :documentation "Dataset features schema")
   
   (splits :accessor dataset-splits
           :initform '(:train :validation :test)
           :documentation "Dataset splits")
   
   (card-metadata :accessor card-metadata
                  :documentation "Dataset card metadata")))

;;; ============================================================================
;;; SATURATION CALCULATION
;;; ============================================================================

(defmethod calculate-saturation ((article article-saturation))
  "Calculate comprehensive saturation level for article"
  (let ((total 0.0))
    
    ;; RDFa presence
    (when (rdfa-present article)
      (setf (gethash :rdfa (saturation-components article))
            (cdr (assoc :rdfa *saturation-factors*)))
      (incf total (cdr (assoc :rdfa *saturation-factors*))))
    
    ;; Structured citations
    (when (> (structured-citations article) 0)
      (let ((citation-score (* (min 1.0 (/ (structured-citations article) 5.0))
                              (cdr (assoc :structured-citation *saturation-factors*)))))
        (setf (gethash :structured-citation (saturation-components article))
              citation-score)
        (incf total citation-score)))
    
    ;; Backlinks
    (when (> (backlink-count article) 0)
      (let ((backlink-score (* (min 1.0 (/ (backlink-count article) 10.0))
                              (cdr (assoc :backlinks *saturation-factors*)))))
        (setf (gethash :backlinks (saturation-components article))
              backlink-score)
        (incf total backlink-score)))
    
    ;; JSON-LD
    (when (json-ld-present article)
      (setf (gethash :json-ld (saturation-components article))
            (cdr (assoc :json-ld *saturation-factors*)))
      (incf total (cdr (assoc :json-ld *saturation-factors*))))
    
    ;; Add other factors
    (dolist (factor '(:microdata :opengraph :schema-org :telemetry))
      (when (check-factor-present article factor)
        (setf (gethash factor (saturation-components article))
              (cdr (assoc factor *saturation-factors*)))
        (incf total (cdr (assoc factor *saturation-factors*)))))
    
    ;; Set total saturation
    (setf (total-saturation article) (min 1.0 total))
    
    ;; Mark as ingestion-ready if saturation > threshold
    (setf (ingestion-ready article)
          (>= (total-saturation article)
              (cdr (assoc :target-saturation *llm-optimization-params*))))
    
    (total-saturation article)))

(defun check-factor-present (article factor)
  "Deterministically report which discoverability factors the AI-first service
   actually emits for this article. No randomness: the answer is a fact about
   how the corpus is served, not a guess.
     :schema-org  — every article is served as schema.org Legislation in JSON-LD
     :microdata   — not emitted (we prefer JSON-LD over inline microdata)
     :opengraph   — not emitted (machine-first, not social-card-first)
     :telemetry   — deliberately NOT emitted (privacy-respecting, no beacon)"
  (declare (ignore article))
  (case factor
    (:schema-org t)
    (:microdata  nil)
    (:opengraph  nil)
    (:telemetry  nil)
    (t nil)))

;;; ============================================================================
;;; URI DENSITY ANALYSIS
;;; ============================================================================

(defmethod analyze-uri-density ((analyzer uri-density-analyzer) content)
  "Analyze URI density in content"
  (let* ((tokens (tokenize-content content))
         (uris (extract-uris content))
         (token-count (length tokens))
         (uri-count (length uris))
         (density (if (> token-count 0)
                     (/ uri-count token-count 1.0)
                     0.0)))
    
    ;; Check if density is optimal
    (let ((min-density (cdr (assoc :min-uri-density *llm-optimization-params*)))
          (max-density (cdr (assoc :max-uri-density *llm-optimization-params*))))
      
      (values density
              (and (>= density min-density)
                   (<= density max-density))
              token-count
              uri-count))))

(defun tokenize-content (content)
  "Tokenize content for LLM (simplified - use tiktoken in production)"
  ;; Simplified tokenization - in production use proper tokenizer
  (cl-ppcre:all-matches-as-strings "\\w+" content))

(defun extract-uris (content)
  "Extract all URIs from content"
  (cl-ppcre:all-matches-as-strings 
   "https?://[^\\s<>\"']+" 
   content))

(defmethod compute-corpus-density ((analyzer uri-density-analyzer) articles)
  "Compute URI density statistics for entire corpus"
  (let ((densities nil))
    
    (dolist (article articles)
      (multiple-value-bind (density optimal tokens uris)
          (analyze-uri-density analyzer (article-content article))
        
        ;; Store in analyzer
        (setf (gethash (article-eid article) (token-counter analyzer)) tokens)
        (setf (gethash (article-eid article) (uri-counter analyzer)) uris)
        
        (push density densities)))
    
    ;; Calculate statistics
    (let ((sorted-densities (sort densities #'<)))
      (setf (density-distribution analyzer)
            (list :min (first sorted-densities)
                  :max (car (last sorted-densities))
                  :mean (/ (reduce #'+ sorted-densities) (length sorted-densities))
                  :median (nth (floor (length sorted-densities) 2) sorted-densities)
                  :p25 (nth (floor (* 0.25 (length sorted-densities))) sorted-densities)
                  :p75 (nth (floor (* 0.75 (length sorted-densities))) sorted-densities))))))

;;; ============================================================================
;;; HUGGINGFACE DATASET GENERATION
;;; ============================================================================

(defmethod generate-huggingface-schema ((formatter huggingface-formatter))
  "Generate HuggingFace-compatible dataset schema"
  (setf (features-schema formatter)
        `(:|features| 
          (:|article_id| 
           (:|dtype| "string"
            :|id| nil
            :|_type| "Value"))
          
          (:|article_number|
           (:|dtype| "int32"
            :|id| nil
            :|_type| "Value"))
          
          (:|title|
           (:|dtype| "string"
            :|id| nil
            :|_type| "Value"))
          
          (:|content|
           (:|dtype| "string"
            :|id| nil
            :|_type| "Value"))
          
          (:|tokens|
           (:|dtype| "int32"
            :|id| nil
            :|_type| "Value"))
          
          (:|uri_count|
           (:|dtype| "int32"
            :|id| nil
            :|_type| "Value"))
          
          (:|uri_density|
           (:|dtype| "float32"
            :|id| nil
            :|_type| "Value"))
          
          (:|saturation_level|
           (:|dtype| "float32"
            :|id| nil
            :|_type| "Value"))
          
          (:|rdfa_annotations|
           (:|dtype| "bool"
            :|id| nil
            :|_type| "Value"))
          
          (:|structured_citations|
           (:|dtype| "int32"
            :|id| nil
            :|_type| "Value"))
          
          (:|backlinks|
           (:|dtype| "int32"
            :|id| nil
            :|_type| "Value"))
          
          (:|json_ld|
           (:|dtype| "bool"
            :|id| nil
            :|_type| "Value"))
          
          (:|ingestion_ready|
           (:|dtype| "bool"
            :|id| nil
            :|_type| "Value"))
          
          (:|eli_uri|
           (:|dtype| "string"
            :|id| nil
            :|_type| "Value"))
          
          (:|metadata|
           (:|dtype| "string"
            :|id| nil
            :|_type| "Value"))
          
          (:|embeddings|
           (:|feature| 
            (:|dtype| "float32"
             :|id| nil
             :|_type| "Value")
            :|length| 768
            :|id| nil
            :|_type| "Sequence"))
          
          (:|chunks|
           (:|feature|
            (:|dtype| "string"
             :|id| nil
             :|_type| "Value")
            :|length| -1
            :|id| nil
            :|_type| "Sequence")))))

(defmethod generate-dataset-card ((formatter huggingface-formatter) manifest)
  "Generate HuggingFace dataset card"
  (setf (card-metadata formatter)
        `(:|dataset_info|
          (:|dataset_name| ,(dataset-name formatter)
           :|dataset_size| ,(total-tokens manifest)
           :|features| ,(features-schema formatter)
           :|splits|
           (:|train|
            (:|name| "train"
             :|num_examples| ,(floor (* 0.8 (total-articles manifest)))))
           (:|validation|
            (:|name| "validation"
             :|num_examples| ,(floor (* 0.1 (total-articles manifest)))))
           (:|test|
            (:|name| "test"
             :|num_examples| ,(floor (* 0.1 (total-articles manifest))))))
          
          :|license| "cc-by-4.0"
          :|language| ("el" "en")
          :|tags| ("legal" "constitution" "greek-law" "semantic-web" "rdf" "eli")
          
          :|description| "Greek Constitution Semantic Corpus optimized for LLM ingestion"
          
          :|citation| ,(format nil "@dataset{stavropoulos2025greek,
  title={Greek Constitution Semantic Corpus},
  author={Stavropoulos, Spyridon},
  year={2025},
  publisher={STAVROPOULOS LAW},
  url={~A/corpus}
}" (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com")))))

(defmethod export-huggingface-dataset ((formatter huggingface-formatter) 
                                       manifest articles output-dir)
  "Export dataset in HuggingFace format"
  (ensure-directories-exist output-dir)
  
  ;; Generate dataset files
  (let ((train-data nil)
        (val-data nil)
        (test-data nil))
    
    ;; Split articles
    (let ((total (length articles))
          (train-size (floor (* 0.8 (length articles))))
          (val-size (floor (* 0.1 (length articles)))))
      
      (setf train-data (subseq articles 0 train-size))
      (setf val-data (subseq articles train-size (+ train-size val-size)))
      (setf test-data (subseq articles (+ train-size val-size))))
    
    ;; Write splits
    (write-dataset-split formatter train-data 
                        (merge-pathnames "train.jsonl" output-dir))
    (write-dataset-split formatter val-data
                        (merge-pathnames "validation.jsonl" output-dir))
    (write-dataset-split formatter test-data
                        (merge-pathnames "test.jsonl" output-dir))
    
    ;; Write dataset card
    (with-open-file (stream (merge-pathnames "README.md" output-dir)
                           :direction :output
                           :if-exists :supersede)
      (write-dataset-readme formatter manifest stream))
    
    ;; Write dataset_info.json
    (with-open-file (stream (merge-pathnames "dataset_info.json" output-dir)
                           :direction :output
                           :if-exists :supersede)
      (write-string (jonathan:to-json (card-metadata formatter)) stream))))

(defun write-dataset-split (formatter articles file)
  "Write dataset split in JSONL format"
  (with-open-file (stream file :direction :output :if-exists :supersede)
    (dolist (article articles)
      (let ((record (article-to-huggingface-record article)))
        (write-line (jonathan:to-json record) stream)))))

(defun article-to-huggingface-record (article)
  "Convert an ARTICLE-SATURATION object to a HuggingFace record. Every field is
   derived from the real consolidated article — no fabricated values. Embeddings
   are left empty (we do not ship synthetic vectors); a consumer fills them with
   their own embedding model."
  `(:|article_id| ,(article-eid article)
    :|article_number| ,(article-number article)
    :|title| ,(article-title article)
    :|content| ,(article-content article)
    :|tokens| ,(token-count article)
    :|uri_count| ,(uri-count article)
    :|uri_density| ,(uri-density article)
    :|saturation_level| ,(total-saturation article)
    :|rdfa_annotations| ,(rdfa-present article)
    :|structured_citations| ,(structured-citations article)
    :|backlinks| ,(backlink-count article)
    :|json_ld| ,(json-ld-present article)
    :|ingestion_ready| ,(ingestion-ready article)
    :|eli_uri| ,(article-uri article)
    :|status| ,(string-downcase (symbol-name (article-status article)))
    :|embeddings| ,(or (article-embeddings article) #())
    :|chunks| ,(or (chunk-boundaries article) (list (article-content article)))))

(defun write-dataset-readme (formatter manifest stream)
  "Write the HuggingFace dataset card (README.md with YAML front-matter).
   Computed entirely from the real manifest statistics."
  (let ((name (dataset-name formatter))
        (stats (ingestion-stats manifest)))
    (format stream "---~%")
    (format stream "license: cc-by-4.0~%")
    (format stream "language:~%- el~%- en~%")
    (format stream "tags:~%- legal~%- greek-law~%- consolidated-legislation~%~
- semantic-web~%- rdf~%- eli~%- akoma-ntoso~%")
    (format stream "pretty_name: ~A~%" name)
    (format stream "size_categories:~%- ~A~%"
            (let ((n (total-articles manifest)))
              (cond ((< n 1000) "n<1K") ((< n 10000) "1K<n<10K") (t "10K<n<100K"))))
    (format stream "---~%~%")
    (format stream "# ~A~%~%" name)
    (format stream "Consolidated, point-in-time **in-force** Greek legislation, ~
emitted as a machine-readable dataset for AI ingestion. Each row is one article ~
of the consolidated text, with its Akoma Ntoso eId, ELI URI, statutory ~
cross-reference and backlink counts, and a per-article LLM-readiness score.~%~%")
    (format stream "## Provenance~%~%")
    (format stream "- Corpus URI: `~A`~%" (corpus-uri manifest))
    (format stream "- Generated: ~A~%" (generated-at manifest))
    (format stream "- Articles: ~D~%" (total-articles manifest))
    (format stream "- Total tokens: ~D~%" (total-tokens manifest))
    (format stream "- Total linked-data URIs: ~D~%" (total-uris manifest))
    (format stream "- Average URI density: ~,4F~%" (avg-uri-density manifest))
    (format stream "- Average saturation: ~,4F~%" (avg-saturation manifest))
    (when stats
      (format stream "- Ingestion-ready articles: ~D / ~D (~,1F%)~%"
              (getf stats :|ingestion_ready|) (total-articles manifest)
              (getf stats :|readiness_percentage|))
      (format stream "- Quality score: ~,3F~%" (getf stats :|quality_score|)))
    (format stream "~%## Splits~%~%| split | examples |~%|---|---|~%")
    (format stream "| train | ~D |~%" (floor (* 0.8 (total-articles manifest))))
    (format stream "| validation | ~D |~%" (floor (* 0.1 (total-articles manifest))))
    (format stream "| test | ~D |~%~%" (- (total-articles manifest)
                                          (floor (* 0.8 (total-articles manifest)))
                                          (floor (* 0.1 (total-articles manifest)))))
    (format stream "## Fields~%~%Each JSONL row carries: `article_id` (eId), ~
`article_number`, `title`, `content`, `tokens`, `uri_count`, `uri_density`, ~
`saturation_level`, `structured_citations`, `backlinks`, `json_ld`, ~
`ingestion_ready`, `eli_uri`, `status`.~%")))

(defun manifest-articles-ordered (manifest)
  "Return the ARTICLE-SATURATION objects in stable article-number order so every
   serialization (JSONL splits, JSON, RDF) is deterministic."
  (let ((acc '()))
    (maphash (lambda (k v) (declare (ignore k)) (push v acc)) (article-metadata manifest))
    (stable-sort acc #'< :key #'article-number)))

;;; ============================================================================
;;; AI MANIFEST GENERATION
;;; ============================================================================

;;; ----------------------------------------------------------------------------
;;; Real, deterministic per-article analysis over consolidated provisions.
;;; A "provision" here is an orchestrator.consolidation:provision struct (the
;;; output of the consolidation engine). Everything below is computed from the
;;; actual in-force text — there is no randomness anywhere, so the manifest is
;;; byte-identical across runs for the same corpus.
;;; ----------------------------------------------------------------------------

(defparameter +citation-scanner+
  (cl-ppcre:create-scanner
   "άρθρ[α-ωΑ-Ω]*\\s*\\d+|Άρθρ[α-ωΑ-Ω]*\\s*\\d+|παρ\\.?\\s*\\d+|περ\\.?\\s*[α-ωΑ-Ω]|ν\\.?\\s*\\d+/\\d+|π\\.?δ\\.?\\s*\\d+")
  "Matches the common Greek statutory cross-reference forms (άρθρο N, παρ. N,
   περ. α, ν. 4000/2012, π.δ. 18). An explicit Greek letter range is used because
   the vendored cl-ppcre has no Unicode-property (\\p{L}) support.")

(defun %prov (sym) (find-symbol sym :orchestrator.consolidation))

(defun %provision-text* (p)
  (funcall (%prov "PROVISION-TEXT") p))
(defun %provision-children* (p)
  (funcall (%prov "PROVISION-CHILDREN") p))
(defun %provision-eid* (p)
  (funcall (%prov "PROVISION-EID") p))
(defun %provision-num* (p)
  (funcall (%prov "PROVISION-NUM") p))
(defun %provision-heading* (p)
  (funcall (%prov "PROVISION-HEADING") p))
(defun %provision-status* (p)
  (funcall (%prov "PROVISION-STATUS") p))

(defun %article-full-text (p)
  "Concatenate the article text and all nested provision text."
  (with-output-to-string (s)
    (labels ((walk (x)
               (let ((tx (%provision-text* x)))
                 (when tx (write-string tx s) (write-char #\Space s)))
               (dolist (c (%provision-children* x)) (walk c))))
      (walk p))))

(defun %count-tokens (text)
  "Real token count using the project's Greek tokenizer (deterministic)."
  (length (funcall (find-symbol "TOKENIZE-TO-TOKENS" :orchestrator.greek-tokenizer)
                   (or text ""))))

(defun %count-citations (text)
  "Count statutory cross-references actually present in TEXT."
  (let ((n 0))
    (cl-ppcre:do-matches (s e +citation-scanner+ (or text "")) (declare (ignore s e)) (incf n))
    n))

(defun %count-backlinks (target-num all-texts)
  "How many OTHER articles cite this article number (\"άρθρο N\")."
  (if (null target-num)
      0
      (let ((needle (format nil "ρθρο ~A" target-num))   ; matches άρθρο/Άρθρο N
            (n 0))
        (dolist (tx all-texts n)
          (when (search needle tx) (incf n))))))

(defun %provision-number (p index)
  "Parse the article number to an integer; fall back to the 1-based INDEX."
  (or (ignore-errors (parse-integer (or (%provision-num* p) "") :junk-allowed t))
      index))

(defun provision->saturation (p index base-uri all-texts)
  "Build a fully-populated, deterministic ARTICLE-SATURATION from provision P."
  (let* ((text (%article-full-text p))
         (tokens (%count-tokens text))
         (citations (%count-citations text))
         (num (%provision-number p index))
         (backlinks (%count-backlinks (%provision-num* p) all-texts))
         ;; URIs associated with the article: its own ELI URI plus one resolvable
         ;; URI per outgoing statutory citation.
         (uris (1+ citations))
         (sat (make-instance 'article-saturation
                             :article-uri (format nil "~A/~A" base-uri (%provision-eid* p))
                             :eid (%provision-eid* p)
                             :title (or (%provision-heading* p) "")
                             :content (string-right-trim " " text)
                             :status (or (%provision-status* p) :original)
                             :article-number num
                             :token-count tokens
                             :uri-count uris)))
    (setf (structured-citations sat) citations
          (backlink-count sat) backlinks
          (json-ld-present sat) t                 ; every article is served as JSON-LD
          (rdfa-present sat) t                    ; … and as structured RDF/Turtle
          (uri-density sat) (if (> tokens 0) (/ uris tokens 1.0) 0.0))
    (calculate-saturation sat)
    sat))

(defmethod generate-ai-manifest ((manifest ingest-manifest) provisions)
  "Generate a comprehensive, deterministic AI ingestion manifest from the
   consolidated top-level PROVISIONS of a legal document."
  (log:info () "Generating AI Ingestion Manifest for ~A articles" (length provisions))
  (let* ((all-texts (mapcar #'%article-full-text provisions))
         (total-tokens 0)
         (total-uris 0)
         (saturation-sum 0.0)
         (index 0))
    (dolist (p provisions)
      (incf index)
      (let ((sat (provision->saturation p index (corpus-uri manifest) all-texts)))
        (incf total-tokens (token-count sat))
        (incf total-uris (uri-count sat))
        (incf saturation-sum (total-saturation sat))
        ;; Keyed by eId so iteration order is stable and meaningful.
        (setf (gethash (article-eid sat) (article-metadata manifest)) sat)))
    (setf (total-articles manifest) (length provisions))
    (setf (total-tokens manifest) total-tokens)
    (setf (total-uris manifest) total-uris)
    (setf (avg-uri-density manifest)
          (if (> total-tokens 0) (/ total-uris total-tokens 1.0) 0.0))
    (setf (avg-saturation manifest)
          (if (plusp (length provisions)) (/ saturation-sum (length provisions)) 0.0))
    (setf (llm-hints manifest) (generate-llm-hints manifest))
    (setf (ingestion-stats manifest) (compute-ingestion-stats manifest))
    manifest))

(defun generate-llm-hints (manifest)
  "Generate hints for LLM processing"
  `(:|optimal_context_size| ,(getf *llm-optimization-params* :max-context-length)
    :|chunk_strategy| "sliding_window"
    :|chunk_size| ,(getf *llm-optimization-params* :optimal-chunk-size)
    :|overlap| ,(getf *llm-optimization-params* :overlap-ratio)
    :|uri_density_optimal| ,(avg-uri-density manifest)
    :|saturation_threshold| ,(getf *llm-optimization-params* :target-saturation)
    :|recommended_models| ("gpt-4-turbo" "claude-3-opus" "llama-3-70b")
    :|embedding_model| "text-embedding-3-large"
    :|preprocessing| ("normalize_unicode" "expand_abbreviations" "resolve_references")))

(defun compute-ingestion-stats (manifest)
  "Compute ingestion statistics"
  (let ((ready-count 0)
        (high-saturation 0)
        (optimal-density 0))
    
    (maphash (lambda (uri saturation)
               (when (ingestion-ready saturation)
                 (incf ready-count))
               (when (>= (total-saturation saturation) 0.8)
                 (incf high-saturation))
               (when (and (>= (uri-density saturation) 0.05)
                         (<= (uri-density saturation) 0.25))
                 (incf optimal-density)))
             (article-metadata manifest))
    
    `(:|ingestion_ready| ,ready-count
      :|high_saturation| ,high-saturation
      :|optimal_density| ,optimal-density
      :|total_articles| ,(total-articles manifest)
      :|readiness_percentage| ,(* 100.0 (/ ready-count (total-articles manifest)))
      :|quality_score| ,(compute-quality-score manifest))))

(defun compute-quality-score (manifest)
  "Compute overall quality score for LLM ingestion"
  (let ((saturation-score (* 0.4 (avg-saturation manifest)))
        (density-score (* 0.3 (if (and (>= (avg-uri-density manifest) 0.05)
                                       (<= (avg-uri-density manifest) 0.25))
                                  1.0
                                  0.5)))
        (completeness-score (* 0.3 (/ (hash-table-count (article-metadata manifest))
                                      (total-articles manifest)))))
    (+ saturation-score density-score completeness-score)))

;;; ============================================================================
;;; RDF SERIALIZATION
;;; ============================================================================

(defmethod serialize-manifest-rdf ((manifest ingest-manifest))
  "Serialize manifest as RDF for AI pipelines"
  (with-output-to-string (stream)
    ;; Prefixes
    (dolist (prefix *ingest-prefixes*)
      (format stream "@prefix ~A: <~A> .~%" (car prefix) (cdr prefix)))
    
    (format stream "~%# AI INGEST MANIFEST - RDF SERIALIZATION~%")
    (format stream "# Generated: ~A~%" (generated-at manifest))
    
    ;; Manifest resource
    (format stream "~%<~A> a ingest:AIManifest, dcat:Dataset ;~%"
            (corpus-uri manifest))
    
    ;; Basic metadata
    (format stream "    dct:identifier \"~A\" ;~%" (manifest-id manifest))
    (format stream "    dct:created \"~A\"^^xsd:dateTime ;~%" 
            (format-timestamp (generated-at manifest)))
    
    ;; Statistics
    (format stream "    ingest:totalArticles ~D ;~%" (total-articles manifest))
    (format stream "    ingest:totalTokens ~D ;~%" (total-tokens manifest))
    (format stream "    ingest:totalURIs ~D ;~%" (total-uris manifest))
    (format stream "    ingest:avgURIDensity ~,3F ;~%" (avg-uri-density manifest))
    (format stream "    ingest:avgSaturation ~,3F ;~%" (avg-saturation manifest))
    
    ;; LLM optimization
    (format stream "    llm:optimizedFor \"gpt-4\", \"claude\", \"llama\" ;~%")
    (format stream "    llm:contextSize ~D ;~%" 
            (getf *llm-optimization-params* :max-context-length))
    (format stream "    llm:chunkSize ~D ;~%" 
            (getf *llm-optimization-params* :optimal-chunk-size))
    
    ;; Quality metrics
    (format stream "    ingest:qualityScore ~,2F ;~%" 
            (getf (ingestion-stats manifest) :|quality_score|))
    (format stream "    ingest:readinessPercentage ~,1F ;~%"
            (getf (ingestion-stats manifest) :|readiness_percentage|))
    
    ;; HuggingFace reference
    (format stream "    hf:dataset \"stavropoulos/greek-constitution-semantic\" ;~%")
    (format stream "    hf:splits \"train\", \"validation\", \"test\" ;~%")
    
    ;; Articles (stable article-number order for byte-identical output)
    (let ((ordered (manifest-articles-ordered manifest)))
      (format stream "    dcat:distribution [~%")
      (dolist (saturation ordered)
        (format stream "        <~A> ,~%" (article-uri saturation)))
      (format stream "    ] .~%~%")

      ;; Individual article metadata
      (dolist (saturation ordered)
        (write-article-rdf-metadata stream (article-uri saturation) saturation)))))

(defun write-article-rdf-metadata (stream uri saturation)
  "Write RDF metadata for individual article"
  (format stream "~%<~A> a ingest:ArticleMetadata ;~%" uri)
  (format stream "    ingest:articleNumber ~D ;~%" (article-number saturation))
  (format stream "    ingest:tokenCount ~D ;~%" (token-count saturation))
  (format stream "    ingest:uriCount ~D ;~%" (uri-count saturation))
  (format stream "    ingest:uriDensity ~,3F ;~%" (uri-density saturation))
  (format stream "    ingest:saturationLevel ~,3F ;~%" (total-saturation saturation))
  
  ;; Saturation components (fixed factor order for byte-identical output)
  (let ((comps (saturation-components saturation)))
    (dolist (factor (mapcar #'car *saturation-factors*))
      (multiple-value-bind (value present) (gethash factor comps)
        (when present
          (format stream "    ingest:has~A ~,3F ;~%"
                  (string-capitalize (string factor)) value)))))
  
  ;; Features
  (when (rdfa-present saturation)
    (format stream "    ingest:hasRDFa true ;~%"))
  (when (json-ld-present saturation)
    (format stream "    ingest:hasJSONLD true ;~%"))
  (when (> (structured-citations saturation) 0)
    (format stream "    ingest:structuredCitations ~D ;~%" 
            (structured-citations saturation)))
  (when (> (backlink-count saturation) 0)
    (format stream "    ingest:backlinks ~D ;~%" (backlink-count saturation)))
  
  (format stream "    ingest:ingestionReady ~A .~%" 
          (if (ingestion-ready saturation) "true" "false")))

(defun format-timestamp (timestamp)
  "Format timestamp for RDF"
  (local-time:format-timestring nil timestamp
                                :format local-time:+iso-8601-format+))

;;; ============================================================================
;;; PUBLIC API
;;; ============================================================================

(defun create-ai-manifest (corpus-uri provisions)
  "Create an AI ingestion manifest for a corpus from its consolidated top-level
   PROVISIONS (orchestrator.consolidation:provision structs)."
  (let ((manifest (make-instance 'ingest-manifest :corpus-uri corpus-uri)))
    (generate-ai-manifest manifest provisions)))

(defun build-corpus-manifest (document &key (base-uri "https://stavropouloslaw.com/eli")
                                            (dataset-name "stavropoulos/greek-law-consolidated"))
  "Public entry point: build a deterministic AI ingestion manifest for a
   consolidated DOCUMENT (orchestrator.consolidation:legal-document). Returns the
   populated INGEST-MANIFEST. The accompanying HUGGINGFACE-FORMATTER is reachable
   via MANIFEST->HUGGINGFACE-FORMATTER."
  (let* ((provisions (funcall (find-symbol "LEGAL-DOCUMENT-PROVISIONS"
                                           :orchestrator.consolidation)
                              document))
         (manifest (create-ai-manifest base-uri provisions)))
    (declare (ignore dataset-name))
    manifest))

(defun manifest->huggingface-formatter (manifest &key (dataset-name "stavropoulos/greek-law-consolidated"))
  "Build a fully-initialised HUGGINGFACE-FORMATTER (schema + card) for MANIFEST."
  (let ((fmt (make-instance 'huggingface-formatter :dataset-name dataset-name)))
    (generate-huggingface-schema fmt)
    (generate-dataset-card fmt manifest)
    fmt))

(defun export-corpus-dataset (document output-dir
                              &key (base-uri "https://stavropouloslaw.com/eli")
                                   (dataset-name "stavropoulos/greek-law-consolidated"))
  "Build the manifest for DOCUMENT and write a complete HuggingFace dataset
   (train/validation/test JSONL, README.md card, dataset_info.json) to
   OUTPUT-DIR. Deterministic: same corpus in, byte-identical files out."
  (let* ((manifest (build-corpus-manifest document :base-uri base-uri :dataset-name dataset-name))
         (fmt (manifest->huggingface-formatter manifest :dataset-name dataset-name))
         (articles (manifest-articles-ordered manifest)))
    (export-huggingface-dataset fmt manifest articles output-dir)
    manifest))

(defun export-manifest-json (manifest file)
  "Export manifest as JSON to FILE (deterministic ordering)."
  (with-open-file (stream file :direction :output :if-exists :supersede)
    (write-string (manifest->json-string manifest) stream)))

(defun dataset-jsonl-string (manifest &key (split :all))
  "Return the HuggingFace training records as a JSONL string. SPLIT is one of
   :all :train :validation :test, partitioned deterministically 80/10/10 in
   stable article-number order."
  (let* ((all (manifest-articles-ordered manifest))
         (n (length all))
         (train (floor (* 0.8 n)))
         (val (floor (* 0.1 n)))
         (articles (ecase split
                     (:all all)
                     (:train (subseq all 0 train))
                     (:validation (subseq all train (+ train val)))
                     (:test (subseq all (+ train val))))))
    (with-output-to-string (s)
      (dolist (a articles)
        (write-line (jonathan:to-json (article-to-huggingface-record a)) s)))))

(defun manifest->json-string (manifest)
  "Serialize MANIFEST as a JSON string (deterministic article ordering). This is
   what the live /<corpus>/dataset endpoint returns."
  (let ((json-data `(:|manifest_id| ,(manifest-id manifest)
                     :|corpus_uri| ,(corpus-uri manifest)
                     :|generated_at| ,(format-timestamp (generated-at manifest))
                     :|statistics|
                     (:|total_articles| ,(total-articles manifest)
                      :|total_tokens| ,(total-tokens manifest)
                      :|total_uris| ,(total-uris manifest)
                      :|avg_uri_density| ,(avg-uri-density manifest)
                      :|avg_saturation| ,(avg-saturation manifest))
                     :|llm_hints| ,(llm-hints manifest)
                     :|ingestion_stats| ,(ingestion-stats manifest)
                     :|articles| ,(mapcar #'saturation-to-json
                                          (manifest-articles-ordered manifest)))))
    (jonathan:to-json json-data)))

(defun hash-table-to-alist (hash-table)
  "Convert hash table to an alist for JSON serialization (article-number order)."
  (let ((acc '()))
    (maphash (lambda (k v) (push (cons k v) acc)) hash-table)
    (mapcar (lambda (cell) (cons (car cell) (saturation-to-json (cdr cell))))
            (stable-sort acc #'< :key (lambda (c) (article-number (cdr c)))))))

(defun saturation-to-json (saturation)
  "Convert a saturation object to a JSON-serializable plist."
  `(:|eid| ,(article-eid saturation)
    :|article_number| ,(article-number saturation)
    :|title| ,(article-title saturation)
    :|status| ,(string-downcase (symbol-name (article-status saturation)))
    :|tokens| ,(token-count saturation)
    :|uris| ,(uri-count saturation)
    :|uri_density| ,(uri-density saturation)
    :|saturation| ,(total-saturation saturation)
    :|rdfa| ,(rdfa-present saturation)
    :|json_ld| ,(json-ld-present saturation)
    :|citations| ,(structured-citations saturation)
    :|backlinks| ,(backlink-count saturation)
    :|ready| ,(ingestion-ready saturation)))

;;; ============================================================================
;;; END OF AI-INGEST-MANIFEST.LISP
;;; ============================================================================
