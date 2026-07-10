;;;; systems/orchestrator-ai-core/ingest-manifest.lisp
;;;; AI ingest manifest generation with maximum CL expressiveness

(in-package :orchestrator.ai-core)

;;; ============================================================================
;;; DETERMINISTIC TIME CONTROL
;;; ============================================================================

(defconstant +default-deterministic-timestamp+ 1700000000
  "Default fixed timestamp for deterministic builds (2023-11-14T22:13:20Z).
   Used when deterministic mode is enabled but no specific timestamp is provided.")

(defvar *build-timestamp-override* nil
  "Override for build timestamp for reproducibility.
   When NIL, uses (orchestrator.time:now :source :deterministic). When set, uses this value.")

(defun current-build-timestamp ()
  "Get current build timestamp with deterministic override support.
   This value is serialized into the AI ingest manifest, so it must be
   reproducible: it honors deterministic mode (SOURCE_DATE_EPOCH)."
  (or *build-timestamp-override* (orchestrator.time:now :source :deterministic)))

(defun deterministic-hash (data)
  "Compute deterministic hash of data using Blake2.
   Uses unified hash authority for cryptographic hashing."
  (let ((content (if (stringp data)
                    data
                    (babel:octets-to-string data :encoding :utf-8))))
    (orchestrator.hash-authority:compute-hash content :algorithm :blake2)))

;;; ============================================================================
;;; MANIFEST ENTRY GENERATION
;;; ============================================================================

(defgeneric generate-article-manifest-entry (article corpus)
  (:documentation "Generate AI ingest manifest entry for a single article.
   Returns a plist with all metadata needed for AI ingestion."))

(defmethod generate-article-manifest-entry ((article orchestrator.model:article)
                                            (corpus orchestrator.model:corpus))
  "Generate comprehensive manifest entry using CLOS method dispatch"
  (let* ((number (orchestrator.model:article-number article))
         (eli-uri (when (slot-boundp article 'orchestrator.model::eli-uri)
                   (orchestrator.model:article-eli-uri article)))
         (hash (orchestrator.model:article-hash article))
         (state (orchestrator.model:article-processing-state article))
         (blockchain-proof (orchestrator.model:article-blockchain-proof article))
         (has-rdf (and (slot-boundp article 'orchestrator.model::rdf-turtle)
                      (orchestrator.model:article-rdf-turtle article)))
         (has-json-ld (and (slot-boundp article 'orchestrator.model::json-ld)
                          (orchestrator.model:article-json-ld article)))
         (has-html (and (slot-boundp article 'orchestrator.model::html)
                       (orchestrator.model:article-html article))))
    
    ;; P1b [0049]: label-aware ταυτότητα — ποτέ ο συνθετικός αριθμός στο id
    `(:|id| ,(format nil "~A/article/~A"
                     (orchestrator.model:corpus-eli-prefix corpus)
                     (orchestrator.model:article-uri-id
                      number (orchestrator.model:article-label article)))
      :|canonical_source| ,eli-uri
      :|corpus| ,(orchestrator.model:corpus-short-name corpus)
      ;; article_number = η ΠΡΑΓΜΑΤΙΚΗ κανονική ταυτότητα (label-aware string,
      ;; «5Α»/«70») — ο εσωτερικός συνθετικός αριθμός δεν διαφεύγει σε καταναλωτές
      :|article_number| ,(orchestrator.model:article-uri-id
                          number (orchestrator.model:article-label article))
      :|title| ,(orchestrator.model:article-title article)
      :|language| ,(orchestrator.model:corpus-language corpus)
      :|content_hash| ,hash
      :|state| ,(string-downcase (symbol-name state))
      :|formats_available| ,(list
                            (when has-rdf "rdf-turtle")
                            (when has-json-ld "json-ld")
                            (when has-html "html-rdfa"))
      :|blockchain_anchored| ,(if blockchain-proof t :false)
      :|blockchain_proofs| ,(coerce blockchain-proof 'vector)
      :|authority| (:|name| "STAVROPOULOS LAW"
                    :|webid| ,(orchestrator.model:corpus-webid corpus)
                    :|orcid| ,(orchestrator.model:corpus-orcid corpus))
      :|citation_template| ,(format nil "~A, Article ~A (~A)"
                                   (orchestrator.model:corpus-name corpus)
                                   (orchestrator.model:article-uri-id
                                    number (orchestrator.model:article-label article))
                                   (orchestrator.model:corpus-publication-date corpus))
      :|last_updated| ,(current-build-timestamp)
      :|eli_uri| ,eli-uri)))

;;; ============================================================================
;;; JSON SERIALIZATION
;;; ============================================================================

(defun manifest-entry-to-json (entry)
  "Convert manifest entry (plist/alist) to compact JSON string.
   Uses jonathan for high-performance serialization."
  ;; P1b [0049]: τα entries είναι PLIST — το «:from :alist» τα σειριοποιούσε
  ;; ως JSON ARRAY εναλλασσόμενων keys/values (ίδια κλάση με το P1-D).
  (jonathan:to-json entry :from :plist))

;;; ============================================================================
;;; CORPUS-LEVEL MANIFEST GENERATION
;;; ============================================================================

(defgeneric write-ai-ingest-manifest (corpus &key output-path ensure-directory)
  (:documentation "Write complete AI ingest manifest for corpus in NDJSON format.
   Each line is a JSON object for one article.
   
   Args:
     corpus: Corpus object
     output-path: Destination path (default: outputs-final/ai/manifest.jsonl)
     ensure-directory: Create directory if missing (default: T)
   
   Returns:
     Pathname of written file"))

(defmethod write-ai-ingest-manifest ((corpus orchestrator.model:corpus)
                                      &key
                                      (output-path #p"outputs-final/ai/manifest.jsonl")
                                      (ensure-directory t))
  "Write AI ingest manifest with maximum expressiveness:
   - CLOS method dispatch for extensibility
   - Lazy sequence processing (don't realize all at once)
   - Proper error handling with restarts
   - Deterministic output ordering"
  
  (when ensure-directory
    (ensure-directories-exist output-path))
  
  (with-open-file (stream output-path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    
    (let ((articles (sort (orchestrator.model::get-corpus-articles corpus)
                         #'<
                         :key #'orchestrator.model:article-number)))
      
      (restart-case
          (loop for article in articles
                for entry = (generate-article-manifest-entry article corpus)
                for json-line = (manifest-entry-to-json entry)
                do (progn
                     (write-line json-line stream)
                     (force-output stream))
                finally (return (truename output-path)))
        
        (skip-article (article-num)
          :report "Skip this article and continue with next"
          :interactive (lambda ()
                         (format *query-io* "~&Article number to skip: ")
                         (finish-output *query-io*)
                         (list (read *query-io*)))
          (declare (ignore article-num))
          (format stream "~%"))
        
        (abort-manifest ()
          :report "Abort manifest generation entirely"
          (error "Manifest generation aborted by user")))))
  
  output-path)

;;; ============================================================================
;;; BATCH OPERATIONS
;;; ============================================================================

(defun write-all-corpus-manifests (corpora output-dir)
  "Write manifests for multiple corpora with parallel processing potential.
   
   Args:
     corpora: List of corpus objects
     output-dir: Base directory for outputs
   
   Returns:
     List of (corpus-name . manifest-path) pairs"
  (loop for corpus in corpora
        for short-name = (orchestrator.model:corpus-short-name corpus)
        for output-path = (merge-pathnames
                          (make-pathname :name "manifest"
                                        :type "jsonl"
                                        :directory `(:relative "ai" ,short-name))
                          output-dir)
        collect (cons short-name
                     (write-ai-ingest-manifest corpus
                                              :output-path output-path))))

;;; ============================================================================
;;; VALIDATION & STATS
;;; ============================================================================

(defun validate-manifest (manifest-path)
  "Validate NDJSON manifest file structure.
   Returns (values valid-p error-lines total-lines)"
  (with-open-file (stream manifest-path :direction :input)
    (loop for line = (read-line stream nil nil)
          for line-num from 1
          while line
          for parsed = (ignore-errors (jonathan:parse line))
          when (null parsed)
          collect line-num into errors
          finally (return (values (null errors)
                                 errors
                                 (1- line-num))))))

(defun manifest-stats (manifest-path)
  "Compute statistics for manifest file.
   Returns plist with :total, :anchored, :live, etc."
  (with-open-file (stream manifest-path :direction :input)
    (loop for line = (read-line stream nil nil)
          while line
          for entry = (jonathan:parse line :as :alist)
          count t into total
          count (equal (cdr (assoc :|blockchain_anchored| entry)) t) into anchored
          count (string= (cdr (assoc :|state| entry)) "live") into live
          finally (return `(:total ,total
                           :anchored ,anchored
                           :live ,live
                           :completion-percentage ,(if (zerop total)
                                                      0.0
                                                      (* 100.0 (/ live total))))))))

;;; ============================================================================
;;; INCREMENTAL UPDATES
;;; ============================================================================

(defun append-article-to-manifest (article corpus manifest-path)
  "Incrementally append single article to existing manifest.
   Useful for live updates without regenerating entire manifest."
  (let* ((entry (generate-article-manifest-entry article corpus))
         (json-line (manifest-entry-to-json entry)))
    (with-open-file (stream manifest-path
                           :direction :output
                           :if-exists :append
                           :if-does-not-exist :create)
      (write-line json-line stream)
      (force-output stream))
    manifest-path))
