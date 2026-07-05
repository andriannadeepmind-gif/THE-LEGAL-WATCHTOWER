;;;; systems/orchestrator-ai-core/provenance-model.lisp
;;;; Narrative provenance model with activity chain tracking

(in-package :orchestrator.ai-core)

;;; ============================================================================
;;; PROVENANCE RECORD CLASS
;;; ============================================================================

(defclass provenance-record ()
  ((activity
    :initarg :activity
    :accessor provenance-activity
    :type keyword
    :documentation "Activity type (:parse, :generate, :validate, :anchor, etc.)")
   
   (timestamp
    :initform (current-build-timestamp)
    :initarg :timestamp
    :accessor provenance-timestamp
    :type integer
    :documentation "Unix timestamp of activity")
   
   (agent
    :initarg :agent
    :accessor provenance-agent
    :type string
    :documentation "Agent performing activity (system/user ID)")
   
   (input-artifacts
    :initarg :input-artifacts
    :initform nil
    :accessor provenance-input-artifacts
    :documentation "List of input artifact hashes")
   
   (output-artifacts
    :initarg :output-artifacts
    :initform nil
    :accessor provenance-output-artifacts
    :documentation "List of output artifact hashes")
   
   (metadata
    :initarg :metadata
    :initform nil
    :accessor provenance-metadata
    :type list
    :documentation "Additional metadata as plist"))
  
  (:documentation "Single provenance record in activity chain"))

(defmethod print-object ((record provenance-record) stream)
  "Print provenance record in readable format"
  (print-unreadable-object (record stream :type t :identity nil)
    (format stream "~A by ~A at ~A"
            (provenance-activity record)
            (provenance-agent record)
            (provenance-timestamp record))))

;;; ============================================================================
;;; PROVENANCE CHAIN CLASS
;;; ============================================================================

(defclass provenance-chain ()
  ((article-number
    :initarg :article-number
    :accessor chain-article-number
    :type integer
    :documentation "Article this chain belongs to")
   
   (corpus-id
    :initarg :corpus-id
    :accessor chain-corpus-id
    :type string
    :documentation "Corpus identifier")
   
   (activities
    :initform nil
    :accessor chain-activities
    :type list
    :documentation "Ordered list of provenance records (newest first)")
   
   (master-hash
    :initform nil
    :accessor chain-master-hash
    :documentation "Blake3 hash of complete activity chain"))
  
  (:documentation "Complete provenance chain for an article"))

(defmethod print-object ((chain provenance-chain) stream)
  "Print provenance chain in readable format"
  (print-unreadable-object (chain stream :type t :identity nil)
    (format stream "Article ~D, ~D activities"
            (chain-article-number chain)
            (length (chain-activities chain)))))

;;; ============================================================================
;;; CONSTRUCTOR FUNCTIONS
;;; ============================================================================

(defun make-provenance-record (&key activity agent input-artifacts output-artifacts metadata)
  "Create provenance record with validation"
  (assert (keywordp activity) (activity) "Activity must be a keyword")
  (assert (stringp agent) (agent) "Agent must be a string")
  
  (make-instance 'provenance-record
                 :activity activity
                 :agent agent
                 :input-artifacts input-artifacts
                 :output-artifacts output-artifacts
                 :metadata metadata))

(defun make-provenance-chain (article-number corpus-id)
  "Create empty provenance chain for article"
  (make-instance 'provenance-chain
                 :article-number article-number
                 :corpus-id corpus-id))

;;; ============================================================================
;;; CHAIN MANIPULATION
;;; ============================================================================

(defgeneric add-provenance-activity (chain record)
  (:documentation "Add provenance record to chain"))

(defmethod add-provenance-activity ((chain provenance-chain)
                                    (record provenance-record))
  "Add record to front of activity list (newest first)"
  (push record (chain-activities chain))
  ;; Invalidate master hash when chain is modified
  (setf (chain-master-hash chain) nil)
  chain)

(defmethod add-provenance-activity ((chain provenance-chain)
                                    (activity-spec list))
  "Add activity from plist spec"
  (let ((record (apply #'make-provenance-record activity-spec)))
    (add-provenance-activity chain record)))

;;; ============================================================================
;;; CHAIN HASHING
;;; ============================================================================

(defun compute-chain-hash (chain)
  "Compute deterministic Blake3 hash of entire provenance chain.
   Uses Ironclad for cryptographic hashing."
  (let* ((activities (reverse (chain-activities chain))) ; oldest first for canonical order
         (canonical-repr
          (with-output-to-string (s)
            (format s "CHAIN:~A:~A~%"
                   (chain-corpus-id chain)
                   (chain-article-number chain))
            (loop for record in activities
                  do (format s "~A|~A|~A|~{~A~^,~}|~{~A~^,~}~%"
                            (provenance-activity record)
                            (provenance-agent record)
                            (provenance-timestamp record)
                            (provenance-input-artifacts record)
                            (provenance-output-artifacts record))))))
    
    (orchestrator.hash-authority:compute-hash canonical-repr :algorithm :blake2)))

(defmethod update-chain-hash ((chain provenance-chain))
  "Update and cache the master hash"
  (setf (chain-master-hash chain) (compute-chain-hash chain))
  (chain-master-hash chain))

;;; ============================================================================
;;; JSON EXPORT
;;; ============================================================================

(defun provenance-record-to-alist (record)
  "Convert provenance record to alist for JSON serialization"
  `((:|activity| . ,(string-downcase (symbol-name (provenance-activity record))))
    (:|timestamp| . ,(provenance-timestamp record))
    (:|agent| . ,(provenance-agent record))
    (:|inputs| . ,(coerce (provenance-input-artifacts record) 'vector))
    (:|outputs| . ,(coerce (provenance-output-artifacts record) 'vector))
    (:|metadata| . ,(provenance-metadata record))))

(defun provenance-chain-to-alist (chain)
  "Convert provenance chain to alist for JSON serialization"
  `((:|article| . ,(chain-article-number chain))
    (:|corpus| . ,(chain-corpus-id chain))
    (:|activities| . ,(coerce
                       (mapcar #'provenance-record-to-alist
                              (reverse (chain-activities chain)))
                       'vector))
    (:|chain_hash| . ,(or (chain-master-hash chain)
                         (update-chain-hash chain)))
    (:|activity_count| . ,(length (chain-activities chain)))
    (:|first_activity| . ,(when (chain-activities chain)
                            (provenance-timestamp
                             (car (last (chain-activities chain))))))
    (:|last_activity| . ,(when (chain-activities chain)
                           (provenance-timestamp
                            (car (chain-activities chain)))))))

(defun export-provenance-json (chain)
  "Export provenance chain as compact JSON string"
  (jonathan:to-json (provenance-chain-to-alist chain) :from :alist))

;;; ============================================================================
;;; ARTICLE-LEVEL PROVENANCE
;;; ============================================================================

(defgeneric build-article-provenance-chain (article corpus)
  (:documentation "Build provenance chain from article processing history"))

(defmethod build-article-provenance-chain ((article orchestrator.model:article)
                                           (corpus orchestrator.model:corpus))
  "Construct provenance chain from article's processing state"
  (let ((chain (make-provenance-chain
               (orchestrator.model:article-number article)
               (orchestrator.model:corpus-short-name corpus)))
        (agent (format nil "~A/~A"
                      (orchestrator.model:corpus-webid corpus)
                      (orchestrator.model:corpus-orcid corpus))))
    
    ;; Add activities based on article state and artifacts
    (when (orchestrator.model:article-content article)
      (add-provenance-activity chain
        (make-provenance-record
         :activity :parse
         :agent agent
         :output-artifacts (list (orchestrator.model:article-hash article)))))
    
    (when (orchestrator.model:article-rdf-turtle article)
      (add-provenance-activity chain
        (make-provenance-record
         :activity :generate-rdf
         :agent agent
         :input-artifacts (list (orchestrator.model:article-hash article))
         :output-artifacts (list "rdf-turtle"))))
    
    (when (orchestrator.model:article-json-ld article)
      (add-provenance-activity chain
        (make-provenance-record
         :activity :generate-jsonld
         :agent agent
         :input-artifacts (list (orchestrator.model:article-hash article))
         :output-artifacts (list "json-ld"))))
    
    (when (orchestrator.model:article-blockchain-proof article)
      (add-provenance-activity chain
        (make-provenance-record
         :activity :anchor-blockchain
         :agent agent
         :input-artifacts (list (orchestrator.model:article-hash article))
         :output-artifacts (orchestrator.model:article-blockchain-proof article))))
    
    ;; Update final hash
    (update-chain-hash chain)
    chain))

;;; ============================================================================
;;; FILE EXPORT
;;; ============================================================================

(defun write-article-provenance (article corpus output-path &key ensure-directory)
  "Write article provenance to JSON file.
   
   Args:
     article: Article object
     corpus: Corpus object
     output-path: Destination path
     ensure-directory: Create directory if missing (default: T)
   
   Returns:
     Pathname of written file"
  (when ensure-directory
    (ensure-directories-exist output-path))
  
  (let* ((chain (build-article-provenance-chain article corpus))
         (json (export-provenance-json chain)))
    (alexandria:write-string-into-file json output-path
                                       :if-exists :supersede)
    output-path))

(defun write-corpus-provenance (corpus output-dir)
  "Write provenance files for all articles in corpus.
   Creates one JSON file per article.
   
   Args:
     corpus: Corpus object
     output-dir: Base directory for outputs
   
   Returns:
     List of (article-number . provenance-path) pairs"
  (let ((articles (sort (orchestrator.model::get-corpus-articles corpus)
                       #'<
                       :key #'orchestrator.model:article-number)))
    (loop for article in articles
          for number = (orchestrator.model:article-number article)
          for output-path = (merge-pathnames
                            (make-pathname
                             :name (format nil "article-~3,'0D-provenance" number)
                             :type "json"
                             :directory '(:relative "ai" "provenance"))
                            output-dir)
          collect (cons number
                       (write-article-provenance article corpus output-path
                                                :ensure-directory t)))))
