;;;; systems/orchestrator-engine-sbcl/filesystem.lisp
;;;; Filesystem operations for SBCL engine

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; DIRECTORY MANAGEMENT
;;; ============================================================================

(defun ensure-output-directory (path)
  "Ensure output directory exists, create if necessary
  
  Args:
    path: Directory path (string or pathname)
  
  Returns:
    Pathname of directory"
  (let ((dir (uiop:ensure-directory-pathname path)))
    (ensure-directories-exist dir)
    dir))

(defun get-output-directory (context)
  "Get output directory from context or use default
  
  Args:
    context: Pipeline context
  
  Returns:
    Pathname of output directory"
  (let ((output-dir (get-context-value context :output-dir)))
    (ensure-output-directory
     (or output-dir
         (merge-pathnames "outputs/" (orchestrator.paths:institution-root))))))

(defun get-temp-directory ()
  "Get temporary directory
  
  Returns:
    Pathname of temp directory"
  (ensure-output-directory "/tmp/orchestrator/"))

;;; ============================================================================
;;; FILE OPERATIONS
;;; ============================================================================

(defun %file-bytes-equal-p (path bytes)
  "T όταν το υπάρχον PATH περιέχει ΑΚΡΙΒΩΣ τα BYTES. Φθηνός πρώτος έλεγχος
   μήκους (stat)· πλήρης σύγκριση μόνο σε ίσο μήκος. Οποιοδήποτε IO σφάλμα
   ανάγνωσης ⇒ NIL (θα ξαναγραφτεί — ποτέ ψευδές «αμετάβλητο»)."
  (handler-case
      (with-open-file (in path :direction :input
                               :element-type '(unsigned-byte 8)
                               :if-does-not-exist nil)
        (and in
             (= (file-length in) (length bytes))
             (let ((existing (make-array (length bytes)
                                         :element-type '(unsigned-byte 8))))
               (= (read-sequence existing in) (length bytes))
               (equalp existing bytes))))
    (error () nil)))

(defun write-utf8-file (filepath content)
  "Write file with guaranteed UTF-8 encoding using babel.

  ΑΥΞΗΤΙΚΗ ΕΞΟΔΟΣ (write-if-changed): τα artifacts είναι ντετερμινιστικές
  συναρτήσεις των εισόδων τους — αν τα bytes στον δίσκο είναι ΗΔΗ ταυτόσημα,
  η εγγραφή ΠΑΡΑΛΕΙΠΕΤΑΙ (το mtime διατηρείται, το IO πεθαίνει). Καμία λογική
  invalidation/εκδόσεων: η ισοδυναμία κρίνεται στα ΠΡΑΓΜΑΤΙΚΑ bytes, άρα το
  αποτέλεσμα είναι ΕΚ ΚΑΤΑΣΚΕΥΗΣ byte-ταυτόσημο με πλήρη επανεγγραφή.

  Args:
    filepath: Target file path
    content: String content

  Returns:
    (values pathname status) — status ∈ {:written :unchanged}"
  (let ((path (uiop:ensure-pathname filepath))
        (bytes (babel:string-to-octets content :encoding :utf-8)))
    (ensure-directories-exist path)
    (if (%file-bytes-equal-p path bytes)
        (values path :unchanged)
        (progn
          (with-open-file (stream path
                                  :direction :output
                                  :if-exists :supersede
                                  :if-does-not-exist :create
                                  :element-type '(unsigned-byte 8))
            (write-sequence bytes stream))
          (values path :written)))))

(defun write-artifact-to-file (artifact filepath)
  "Write artifact content to file with UTF-8 encoding

  Args:
    artifact: Artifact object
    filepath: Target file path

  Returns:
    Pathname of written file"
  (let ((content (orchestrator.model:artifact-content artifact))
        (path (uiop:ensure-pathname filepath)))
    (ensure-directories-exist path)
    ;; DARPA GUARANTEE: UTF-8 encoding for Greek characters
    (write-utf8-file path
                     (if (stringp content)
                         content
                         (format nil "~A" content)))))

(defun read-artifact-from-file (filepath)
  "Read artifact content from file
  
  Args:
    filepath: Source file path
  
  Returns:
    File content as string"
  (uiop:read-file-string filepath))

(defun write-string-to-file (string filepath)
  "Write string to file
  
  Args:
    string: String content
    filepath: Target file path
  
  Returns:
    Pathname of written file"
  (let ((path (uiop:ensure-pathname filepath)))
    (ensure-directories-exist path)
    (alexandria:write-string-into-file 
     string path
     :if-exists :supersede
     :if-does-not-exist :create)
    path))

;;; ============================================================================
;;; ARTICLE FILE NAMING
;;; ============================================================================

(defun article-base-filename (article)
  "Generate base filename for article
  
  Args:
    article: Article object
  
  Returns:
    Base filename string (e.g., 'article-002')"
  (format nil "article-~A" (orchestrator.model:article-file-id article)))

(defun article-filepath (article extension &optional (directory nil))
  "Generate filepath for article with extension
  
  Args:
    article: Article object
    extension: File extension (e.g., 'ttl', 'jsonld')
    directory: Optional directory path
  
  Returns:
    Pathname"
  (let ((filename (format nil "~A.~A" 
                         (article-base-filename article)
                         extension)))
    (if directory
        (merge-pathnames filename (ensure-output-directory directory))
        (pathname filename))))

;;; ============================================================================
;;; BATCH OPERATIONS (SINGLE FILESYSTEM TRUTH)
;;; ============================================================================

;; NOTE: JSON-LD byte-identity validation removed.
;;
;; CANONICAL AUTHORITY: article-N.jsonld (standalone file)
;;   - The standalone .jsonld file is the ONLY canonical byte artifact
;;   - Generated once via generate-json-ld()
;;   - Stored in (article-json-ld article)
;;
;; EMBEDDED JSON-LD: <script type="application/ld+json"> in HTML
;;   - Derived from same source string during HTML generation
;;   - Considered a DERIVATION, not a separate canonical artifact
;;   - NO byte-identity guarantees between standalone and embedded
;;   - HTML encoding/formatting may differ from standalone file
;;
;; GUARANTEE: Both are generated from the SAME Lisp string in-memory,
;; but post-serialization byte comparison is unreliable and removed.

(defun write-article-formats (article output-dir &key (verbose t))
  "Write all formats for a single article

  Writes 5 formats per article:
    - article-N.ttl (RDF/Turtle)
    - article-N.jsonld (Standalone JSON-LD - CANONICAL)
    - article-N.html (HTML+RDFa+embedded JSON-LD - DERIVATION)
    - article-N.hash (SHA-256)
    - article-N.txt (plain readable text - the MCP serve view)

  CANONICAL AUTHORITY: article-N.jsonld is the canonical JSON-LD artifact.
  Embedded JSON-LD in HTML is a derivation from the same source string.

  Args:
    article: Article object
    output-dir: Output directory pathname
    verbose: Log each file write (default: T)

  Returns:
    (values artifact-paths written-count unchanged-count) — τα paths είναι το
    ΠΛΗΡΕΣ σύνολο artifacts του άρθρου (γραμμένα + αμετάβλητα: όλα υπαρκτά)·
    οι μετρητές τροφοδοτούν την τίμια αναφορά του write-corpus-files."
  (let ((artifact-files nil)
        (written 0) (unchanged 0)
        (num (orchestrator.model:article-number article)))

    (when verbose
      (log:info () "Deploying article ~D (5 formats)" num))

    (flet ((w (ext content label)
             (multiple-value-bind (path status)
                 (write-utf8-file (article-filepath article ext output-dir) content)
               (push path artifact-files)
               (if (eq status :written) (incf written) (incf unchanged))
               (when verbose
                 (log:info () "  ~:[≡~;✓~] ~A: ~A" (eq status :written)
                           label (namestring path))))))

      ;; Write Turtle
      (when (orchestrator.model:article-rdf-turtle article)
        (w "ttl" (orchestrator.model:article-rdf-turtle article) "RDF/Turtle"))

      ;; Write JSON-LD (STANDALONE - guaranteed identical to embedded)
      (when (orchestrator.model:article-json-ld article)
        (w "jsonld" (orchestrator.model:article-json-ld article) "JSON-LD"))

      ;; Write HTML+RDFa (contains embedded JSON-LD)
      (when (orchestrator.model:article-html article)
        (w "html" (orchestrator.model:article-html article) "HTML+RDFa"))

      ;; Write hash
      (when (orchestrator.model:article-hash article)
        (w "hash" (orchestrator.model:article-hash article) "Hash"))

      ;; Write plain text (the human-readable view the MCP serve layer returns as
      ;; :text). Without it an article's text is locked inside the .jsonld/.html only;
      ;; emitting article-N.txt means EVERY article carries its full file set.
      (let ((title (orchestrator.model:article-title article))
            (content (orchestrator.model:article-content article)))
        (when (or title content)
          (w "txt" (format nil "~@[~A~%~%~]~@[~A~%~]" title content) "Text"))))

    (values (nreverse artifact-files) written unchanged)))

(defun write-corpus-files (articles-or-corpus output-dir
                           &key manifest void-descriptor ai-manifest)
  "SINGLE FILESYSTEM TRUTH: Write all corpus artifacts

  Handles BOTH article sources:
    - Corpus object (hash table via corpus-articles)
    - List of article objects

  Writes PER-ARTICLE (5 formats each):
    - article-N.ttl, article-N.jsonld, article-N.html, article-N.hash, article-N.txt

  Writes DATASET-LEVEL (optional):
    - syntagma-manifest.ttl (if :manifest provided)
    - void.ttl (if :void-descriptor provided)
    - manifest.jsonl (if :ai-manifest provided)

  Args:
    articles-or-corpus: Either corpus object OR list of articles
    output-dir: Output directory path
    manifest: (optional) Corpus manifest RDF/Turtle string
    void-descriptor: (optional) VoID descriptor RDF/Turtle string
    ai-manifest: (optional) AI ingest manifest NDJSON string

  Returns:
    Plist with :article-files and :dataset-files"
  (let ((dir (ensure-output-directory output-dir))
        (article-files nil)
        (dataset-files nil))

    ;; Determine article source
    (let ((articles (cond
                      ;; Case 1: Corpus object
                      ((typep articles-or-corpus 'orchestrator.model:corpus)
                       (alexandria:hash-table-values
                        (orchestrator.model:corpus-articles articles-or-corpus)))
                      ;; Case 2: List of articles
                      ((listp articles-or-corpus)
                       articles-or-corpus)
                      ;; Invalid
                      (t (error 'orchestrator.spec:config-error
                               :message "write-corpus-files expects corpus object or list of articles"
                               :config-key :articles)))))

      (log:info () "Writing ~D articles (5 formats each, incremental write-if-changed)"
                (length articles))

      ;; Write all article formats — αυξητικά: ΟΛΑ παράγονται, γράφονται ΜΟΝΟ
      ;; όσα άλλαξαν bytes. Η αναφορά ΔΗΛΩΝΕΙ το skip (ποτέ σιωπηλό).
      (let ((written 0) (unchanged 0))
        (loop for article in articles
              do (multiple-value-bind (files w u)
                     (write-article-formats article dir :verbose nil)
                   (setf article-files (nconc article-files files))
                   (incf written w) (incf unchanged u)))
        (log:info () "Incremental emit: ~D αρχεία ΓΡΑΦΤΗΚΑΝ, ~D αμετάβλητα (ίδια bytes, ανέγγιχτα)"
                  written unchanged))

      ;; Write dataset-level files

      ;; 1. Corpus manifest
      (when manifest
        (let* ((short-name (or (orchestrator.spec:config-get "corpus.short_name") "corpus"))
               (path (merge-pathnames (format nil "~A-manifest.ttl" short-name) dir)))
          (write-utf8-file path manifest)
          (push path dataset-files)
          (log:info () "Deployed corpus manifest: ~A" path)))

      ;; 2. VoID descriptor
      (when void-descriptor
        (let ((path (merge-pathnames "void.ttl" dir)))
          (write-utf8-file path void-descriptor)
          (push path dataset-files)
          (log:info () "Deployed VoID descriptor: ~A" path)))

      ;; 3. AI ingest manifest
      (when ai-manifest
        (let ((path (merge-pathnames "manifest.jsonl" dir)))
          (write-utf8-file path ai-manifest)
          (push path dataset-files)
          (log:info () "Deployed AI manifest: ~A" path)))

      (log:info () "Deployment complete: ~D articles × 5 formats + ~D dataset files"
                (length articles)
                (length dataset-files))

      (list :article-files (nreverse article-files)
            :dataset-files (nreverse dataset-files)))))

;;; ============================================================================
;;; TEMP FILE MANAGEMENT
;;; ============================================================================

(defun make-temp-file (&optional (prefix "orch") (extension "tmp"))
  "Create temporary file
  
  Args:
    prefix: Filename prefix
    extension: File extension
  
  Returns:
    Pathname of temp file"
  (let* ((temp-dir (get-temp-directory))
         (filename (format nil "~A-~D.~A"
                          prefix
                          (orchestrator.time:now :source :system)
                          extension)))
    (merge-pathnames filename temp-dir)))

(defmacro with-temp-file ((var &optional (prefix "orch") (extension "tmp")) &body body)
  "Execute body with a temporary file
  
  Syntax:
    (with-temp-file (path \"prefix\" \"ext\")
      ... use path ...)
  
  File is automatically deleted after execution"
  `(let ((,var (make-temp-file ,prefix ,extension)))
     (unwind-protect
          (progn ,@body)
       (when (probe-file ,var)
         (delete-file ,var)))))
