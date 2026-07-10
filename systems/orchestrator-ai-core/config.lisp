;;;; systems/orchestrator-ai-core/config.lisp
;;;; AI export configuration with YAML/config hooks
;;;; Enables parameterization of AI export layer via standard configs

(in-package :orchestrator.ai-core)

;;; ============================================================================
;;; AI CONFIGURATION STRUCTURE
;;; ============================================================================

(defclass ai-export-config ()
  ((output-root
    :initarg :output-root
    :accessor config-output-root
    :initform #p"outputs-final/ai/"
    :type pathname
    :documentation "Base directory for AI export output")
   
   (dataset-name
    :initarg :dataset-name
    :accessor config-dataset-name
    :initform "greek-legal-corpus"
    :type string
    :documentation "Dataset identifier for AI systems")
   
   (dataset-version
    :initarg :dataset-version
    :accessor config-dataset-version
    :initform "1.0.0"
    :type string
    :documentation "Semantic version of dataset")
   
   (publisher
    :initarg :publisher
    :accessor config-publisher
    :initform "STAVROPOULOS LAW"
    :type string
    :documentation "Publishing organization name")
   
   (canonical-base-uri
    :initarg :canonical-base-uri
    :accessor config-canonical-base-uri
    :initform "https://stavropouloslaw.com/corpus/"
    :type string
    :documentation "Base URI for canonical artifact URLs")
   
   (manifest-filename
    :initarg :manifest-filename
    :accessor config-manifest-filename
    :initform "manifest.jsonl"
    :type string
    :documentation "Filename for NDJSON manifest")
   
   (provenance-subdir
    :initarg :provenance-subdir
    :accessor config-provenance-subdir
    :initform "provenance"
    :type string
    :documentation "Subdirectory for provenance files")
   
   (include-content-text
    :initarg :include-content-text
    :accessor config-include-content-text
    :initform t
    :type boolean
    :documentation "Whether to include full text in manifest")
   
   (include-html-snippet
    :initarg :include-html-snippet
    :accessor config-include-html-snippet
    :initform t
    :type boolean
    :documentation "Whether to include HTML snippet in manifest")
   
   (deterministic
    :initarg :deterministic
    :accessor config-deterministic
    :initform nil
    :type boolean
    :documentation "Use deterministic timestamps for reproducibility")
   
   (fixed-timestamp
    :initarg :fixed-timestamp
    :accessor config-fixed-timestamp
    :initform nil
    :documentation "Fixed timestamp to use when deterministic=t"))
  
  (:documentation "Configuration for AI export layer"))

(defmethod print-object ((config ai-export-config) stream)
  "Print AI config in readable format"
  (print-unreadable-object (config stream :type t)
    (format stream "~A v~A → ~A"
            (config-dataset-name config)
            (config-dataset-version config)
            (config-output-root config))))

;;; ============================================================================
;;; CONFIGURATION CONSTRUCTORS
;;; ============================================================================

(defun make-ai-export-config (&rest args)
  "Create AI export configuration with keyword arguments"
  (apply #'make-instance 'ai-export-config args))

(defun make-default-ai-export-config ()
  "Create default AI export configuration"
  (make-instance 'ai-export-config))

;;; ============================================================================
;;; YAML/PLIST PARSING
;;; ============================================================================

(defun parse-ai-config-from-plist (plist)
  "Parse AI config from plist (as from YAML parsing).
   Supports nested 'ai_export' section in larger config.
   
   Expected YAML structure:
   ai_export:
     output_root: /path/to/output
     dataset_name: my-dataset
     dataset_version: 1.0.0
     publisher: My Organization
     canonical_base_uri: https://example.com/
     deterministic: true
     fixed_timestamp: 1700000000"
  
  ;; Handle both direct config and nested 'ai_export' section
  (let ((ai-section (or (getf plist :ai-export)
                        (getf plist :ai_export)
                        (getf plist :ai-export)
                        (getf plist :ai-export)
                        plist)))
    
    (let ((config (make-instance 'ai-export-config)))
      
      ;; Parse each field if present
      (when-let ((v (or (getf ai-section :output-root)
                        (getf ai-section :output_root)
                        (getf ai-section :output-root))))
        (setf (config-output-root config) (pathname v)))
      
      (when-let ((v (or (getf ai-section :dataset-name)
                        (getf ai-section :dataset_name)
                        (getf ai-section :dataset-name))))
        (setf (config-dataset-name config) v))
      
      (when-let ((v (or (getf ai-section :dataset-version)
                        (getf ai-section :dataset_version)
                        (getf ai-section :dataset-version))))
        (setf (config-dataset-version config) v))
      
      (when-let ((v (or (getf ai-section :publisher)
                        (getf ai-section :publisher))))
        (setf (config-publisher config) v))
      
      (when-let ((v (or (getf ai-section :canonical-base-uri)
                        (getf ai-section :canonical_base_uri)
                        (getf ai-section :canonical-base-uri))))
        (setf (config-canonical-base-uri config) v))
      
      (when-let ((v (or (getf ai-section :manifest-filename)
                        (getf ai-section :manifest_filename)
                        (getf ai-section :manifest-filename))))
        (setf (config-manifest-filename config) v))
      
      (when-let ((v (or (getf ai-section :provenance-subdir)
                        (getf ai-section :provenance_subdir)
                        (getf ai-section :provenance-subdir))))
        (setf (config-provenance-subdir config) v))
      
      (when-let ((v (or (getf ai-section :include-content-text)
                        (getf ai-section :include_content_text)
                        (getf ai-section :include-content-text))))
        (setf (config-include-content-text config) v))
      
      (when-let ((v (or (getf ai-section :include-html-snippet)
                        (getf ai-section :include_html_snippet)
                        (getf ai-section :include-html-snippet))))
        (setf (config-include-html-snippet config) v))
      
      (when-let ((v (or (getf ai-section :deterministic)
                        (getf ai-section :deterministic))))
        (setf (config-deterministic config) v))
      
      (when-let ((v (or (getf ai-section :fixed-timestamp)
                        (getf ai-section :fixed_timestamp)
                        (getf ai-section :fixed-timestamp))))
        (setf (config-fixed-timestamp config) v))
      
      config)))

(defun load-ai-config-from-yaml (path)
  "Load AI export configuration from YAML file.
   Can be a dedicated AI config or extract ai_export section from larger config."
  (let* ((yaml-content (uiop:read-file-string path))
         (parsed (cl-yaml:parse yaml-content)))
    (parse-ai-config-from-plist parsed)))

;;; ============================================================================
;;; CONFIG-AWARE MANIFEST ENTRY GENERATION
;;; ============================================================================

(defvar *current-ai-config* nil
  "Dynamically bound AI configuration for use during export")

(defgeneric generate-article-manifest-entry-with-config (article corpus config)
  (:documentation "Generate manifest entry with explicit configuration"))

(defmethod generate-article-manifest-entry-with-config
    ((article orchestrator.model:article)
     (corpus orchestrator.model:corpus)
     (config ai-export-config))
  "P1b [0050]#3: ΜΙΑ έδρα πεδίων άρθρου. Όλη η αλήθεια επιπέδου άρθρου
   (ταυτότητα, τίτλος, hash, παραπομπή, μορφές) αντλείται από το
   GENERATE-ARTICLE-MANIFEST-ENTRY — εδώ προστίθενται/παρακάμπτονται ΜΟΝΟ τα
   config-driven πεδία (dataset, publisher, provenance_url, last_updated,
   id πάνω στο config base-uri). Η παλιά δεύτερη παραγωγή έγραφε τον
   ΣΥΝΘΕΤΙΚΟ αριθμό σε article_number/citation και provenance_url χωρίς
   επίθημα — η κλάση πεθαίνει με την εξάλειψη της δεύτερης έδρας."
  (let* ((base-entry (generate-article-manifest-entry article corpus))
         (short-name (orchestrator.model:corpus-short-name corpus))
         (art-id (getf base-entry :|article_number|)))
    `(:|id| ,(format nil "~A/~A/article/~A"
                     (config-canonical-base-uri config) short-name art-id)
      :|canonical_source| ,(getf base-entry :|canonical_source|)
      :|corpus| ,(getf base-entry :|corpus|)
      :|article_number| ,art-id
      :|title| ,(getf base-entry :|title|)
      :|language| ,(getf base-entry :|language|)
      :|content_hash| ,(getf base-entry :|content_hash|)
      :|state| ,(getf base-entry :|state|)
      :|formats_available| ,(remove nil (getf base-entry :|formats_available|))
      :|blockchain_anchored| ,(getf base-entry :|blockchain_anchored|)
      :|blockchain_proofs| ,(getf base-entry :|blockchain_proofs|)

      ;; Config-driven metadata
      :|dataset| (:|name| ,(config-dataset-name config)
                  :|version| ,(config-dataset-version config)
                  :|publisher| ,(config-publisher config))

      :|authority| (:|name| ,(config-publisher config)
                    :|webid| ,(orchestrator.model:corpus-webid corpus)
                    :|orcid| ,(orchestrator.model:corpus-orcid corpus))

      :|citation_template| ,(getf base-entry :|citation_template|)

      ;; Provenance URL: κανονικό padded όνομα ΜΕ επίθημα από τη μία έδρα
      ;; (article-file-id): article-005Α-provenance.json — ποτέ ~3,'0D του
      ;; συνθετικού αριθμού.
      :|provenance_url| ,(format nil "~A/~A/article-~A-provenance.json"
                                 (config-provenance-subdir config)
                                 short-name
                                 (orchestrator.model:article-file-id article))

      :|last_updated| ,(if (config-deterministic config)
                          (or (config-fixed-timestamp config) 1700000000)
                          (current-build-timestamp))

      :|eli_uri| ,(getf base-entry :|eli_uri|))))

;;; ============================================================================
;;; CONFIG-AWARE WRITE FUNCTIONS
;;; ============================================================================

(defgeneric write-ai-ingest-manifest-with-config (corpus config)
  (:documentation "Write manifest using explicit configuration"))

(defmethod write-ai-ingest-manifest-with-config 
    ((corpus orchestrator.model:corpus)
     (config ai-export-config))
  "Write manifest with configuration-driven output location and metadata"
  
  ;; Apply deterministic settings
  (when (config-deterministic config)
    (setf *build-timestamp-override* 
          (or (config-fixed-timestamp config) +default-deterministic-timestamp+)))
  
  (let ((output-path (merge-pathnames
                      (make-pathname :name (pathname-name 
                                           (config-manifest-filename config))
                                    :type (pathname-type 
                                          (config-manifest-filename config)))
                      (config-output-root config))))
    
    (ensure-directories-exist output-path)
    
    (with-open-file (stream output-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      
      (let ((articles (sort (orchestrator.model::get-corpus-articles corpus)
                           #'<
                           :key #'orchestrator.model:article-number)))
        
        (loop for article in articles
              for entry = (generate-article-manifest-entry-with-config 
                          article corpus config)
              for json-line = (manifest-entry-to-json entry)
              do (progn
                   (write-line json-line stream)
                   (force-output stream))
              finally (return (truename output-path)))))))

(defgeneric write-corpus-provenance-with-config (corpus config)
  (:documentation "Write provenance files using configuration"))

(defmethod write-corpus-provenance-with-config 
    ((corpus orchestrator.model:corpus)
     (config ai-export-config))
  "Write provenance with configuration-driven output location"
  
  ;; Apply deterministic settings
  (when (config-deterministic config)
    (setf *build-timestamp-override* 
          (or (config-fixed-timestamp config) +default-deterministic-timestamp+)))
  
  (let ((provenance-base-dir (merge-pathnames
                              (make-pathname 
                               :directory `(:relative ,(config-provenance-subdir config)))
                              (config-output-root config)))
        (articles (sort (orchestrator.model::get-corpus-articles corpus)
                       #'<
                       :key #'orchestrator.model:article-number)))
    
    (loop for article in articles
          for number = (orchestrator.model:article-number article)
          for output-path = (merge-pathnames
                            (make-pathname
                             :name (format nil "article-~3,'0D-provenance" number)
                             :type "json")
                            provenance-base-dir)
          collect (cons number
                       (write-article-provenance article corpus output-path
                                                :ensure-directory t)))))

;;; ============================================================================
;;; UTILITY MACRO
;;; ============================================================================

(defmacro with-ai-config ((config-form) &body body)
  "Execute body with AI config bound for implicit use"
  `(let ((*current-ai-config* ,config-form))
     ,@body))

