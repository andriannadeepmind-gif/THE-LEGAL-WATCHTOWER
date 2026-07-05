;;;; source/embeddings-authority.lisp
;;;; ============================================================================
;;;; EMBEDDINGS AUTHORITY - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; Text embeddings with multiple backends:
;;;; - OpenAI text-embedding-3-large (CEILING - best quality)
;;;; - GloVe/Word2Vec (fallback - no external dependency)
;;;;
;;;; STRATEGY:
;;;; - Generate embeddings ONCE via OpenAI API
;;;; - Store as .vec files
;;;; - Load and compare at runtime (no API needed)
;;;;
;;;; DARPA-GRADE: Best available quality, deterministic storage.
;;;; ============================================================================

(defpackage :orchestrator.embeddings-authority
  (:use :cl)
  (:export
   ;; Core operations
   #:embed-text
   #:embed-texts
   #:similarity
   #:find-similar
   ;; OpenAI API (CEILING)
   #:embed-via-openai
   #:embed-batch-openai
   #:*openai-api-key*
   #:*openai-model*
   ;; Vector operations
   #:cosine-similarity
   #:euclidean-distance
   #:normalize-vector
   ;; Storage
   #:save-embedding
   #:load-embedding
   #:generate-corpus-embeddings
   ;; Model management
   #:load-word-vectors
   #:*word-vectors*
   #:*embedding-dimension*
   ;; Conditions
   #:embeddings-error
   #:model-not-loaded
   #:api-error))

(in-package :orchestrator.embeddings-authority)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *word-vectors* nil
  "Hash table mapping words to vectors (loaded from GloVe/Word2Vec)")

(defvar *embedding-dimension* 3072
  "Dimension of embeddings (3072 for text-embedding-3-large)")

(defvar *default-model-path* nil
  "Default path to word vectors file")

;;; ============================================================================
;;; OPENAI API CONFIGURATION (CEILING QUALITY)
;;; ============================================================================

(defvar *openai-api-key* nil
  "OpenAI API key - set via environment or directly")

(defvar *openai-model* "text-embedding-3-large"
  "OpenAI embedding model (text-embedding-3-large = best quality)")

(defvar *openai-endpoint* "https://api.openai.com/v1/embeddings"
  "OpenAI embeddings API endpoint")

(defun get-openai-api-key ()
  "Get OpenAI API key from variable or environment.

   DARPA-GRADE: Validates that key is non-empty string."
  (let ((key (or *openai-api-key*
                 (uiop:getenv "OPENAI_API_KEY"))))
    (unless key
      (error 'api-error
             :message "OpenAI API key not set. Set *openai-api-key* or OPENAI_API_KEY env var."))
    (unless (and (stringp key) (> (length (string-trim '(#\Space #\Tab) key)) 0))
      (error 'api-error
             :message "OpenAI API key is empty or whitespace-only."))
    key))

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition embeddings-error (error)
  ((message :initarg :message :reader embeddings-error-message))
  (:report (lambda (c s)
             (format s "Embeddings Error: ~A" (embeddings-error-message c)))))

(define-condition api-error (embeddings-error) ())

;;; ============================================================================
;;; OPENAI EMBEDDINGS API (CEILING - BEST QUALITY ON PLANET)
;;; ============================================================================

(defun embed-via-openai (text &key (model *openai-model*))
  "Generate embedding via OpenAI API

   Uses text-embedding-3-large (3072 dimensions) - best quality available.

   Args:
     text: Text string to embed
     model: OpenAI model (default: text-embedding-3-large)

   Returns:
     Float vector of dimension 3072"

  (let* ((api-key (get-openai-api-key))
         (payload (jonathan:to-json
                   `(:|model| ,model
                     :|input| ,text
                     :|encoding_format| "float"))))

    (handler-case
        (multiple-value-bind (body status headers)
            (drakma:http-request *openai-endpoint*
                                 :method :post
                                 :content-type "application/json"
                                 :additional-headers
                                   `(("Authorization" . ,(format nil "Bearer ~A" api-key)))
                                 :content payload
                                 :want-stream nil)
          (declare (ignore headers))

          (unless (= status 200)
            (error 'api-error
                   :message (format nil "OpenAI API error ~A: ~A" status body)))

          ;; Parse response and extract embedding
          (let* ((response (jonathan:parse body :as :alist))
                 (data (cdr (assoc :|data| response)))
                 (embedding-data (first data))
                 (embedding-list (cdr (assoc :|embedding| embedding-data))))

            ;; Convert to float vector
            (let ((vec (make-array (length embedding-list)
                                   :element-type 'single-float)))
              (loop for i from 0
                    for val in embedding-list
                    do (setf (aref vec i) (coerce val 'single-float)))
              vec)))

      (error (e)
        (error 'api-error
               :message (format nil "OpenAI request failed: ~A" e))))))

(defun embed-batch-openai (texts &key (model *openai-model*))
  "Generate embeddings for multiple texts in one API call

   More efficient than calling embed-via-openai multiple times.

   Args:
     texts: List of text strings
     model: OpenAI model

   Returns:
     List of float vectors"

  (let* ((api-key (get-openai-api-key))
         (payload (jonathan:to-json
                   `(:|model| ,model
                     :|input| ,texts
                     :|encoding_format| "float"))))

    (handler-case
        (multiple-value-bind (body status)
            (drakma:http-request *openai-endpoint*
                                 :method :post
                                 :content-type "application/json"
                                 :additional-headers
                                   `(("Authorization" . ,(format nil "Bearer ~A" api-key)))
                                 :content payload)

          (unless (= status 200)
            (error 'api-error
                   :message (format nil "OpenAI API error ~A: ~A" status body)))

          ;; Parse response
          (let* ((response (jonathan:parse body :as :alist))
                 (data (cdr (assoc :|data| response))))

            ;; Sort by index and extract embeddings
            (let ((sorted-data (sort (copy-list data) #'<
                                     :key (lambda (d) (cdr (assoc :|index| d))))))
              (mapcar (lambda (item)
                        (let* ((embedding-list (cdr (assoc :|embedding| item)))
                               (vec (make-array (length embedding-list)
                                                :element-type 'single-float)))
                          (loop for i from 0
                                for val in embedding-list
                                do (setf (aref vec i) (coerce val 'single-float)))
                          vec))
                      sorted-data))))

      (error (e)
        (error 'api-error
               :message (format nil "OpenAI batch request failed: ~A" e))))))

;;; ============================================================================
;;; CORPUS EMBEDDING GENERATION (ONE-TIME)
;;; ============================================================================

(defun generate-corpus-embeddings (articles output-dir &key (model *openai-model*))
  "Generate embeddings for all articles in corpus (ONE-TIME operation)

   Calls OpenAI API once per article and saves to .vec files.
   These files are then used at runtime without API calls.

   Args:
     articles: List of article objects or (number . text) pairs
     output-dir: Directory to save .vec files
     model: OpenAI model

   Returns:
     Number of embeddings generated"

  (ensure-directories-exist (merge-pathnames "dummy.txt" output-dir))

  (let ((count 0)
        (total (length articles)))

    (format t "~&; Generating embeddings for ~D articles...~%" total)

    (dolist (article articles)
      (let* ((number (if (consp article) (car article)
                         (funcall (find-symbol "ARTICLE-NUMBER" :orchestrator.model) article)))
             (text (if (consp article) (cdr article)
                       (funcall (find-symbol "ARTICLE-CONTENT" :orchestrator.model) article)))
             (output-path (merge-pathnames
                           (format nil "article-~3,'0D.vec" number)
                           output-dir)))

        ;; Skip if already exists
        (if (probe-file output-path)
            (format t ";   Article ~3,'0D: already exists, skipping~%" number)
            (progn
              (format t ";   Article ~3,'0D: generating...~%" number)

              ;; Generate embedding
              (let ((embedding (embed-via-openai text :model model)))

                ;; Save to file
                (save-embedding embedding output-path)

                (incf count)
                (format t ";   Article ~3,'0D: saved (~D dimensions)~%"
                        number (length embedding)))))))

    (format t "~&; Generated ~D new embeddings (total: ~D)~%" count total)
    count))

(defun save-embedding (vector output-path)
  "Save embedding vector to file

   Format: Binary float32 array for efficiency

   Args:
     vector: Float vector
     output-path: Output file path"

  (ensure-directories-exist output-path)

  (with-open-file (out output-path
                       :direction :output
                       :element-type '(unsigned-byte 8)
                       :if-exists :supersede)
    ;; Write dimension as 4-byte integer
    (let ((dim (length vector)))
      (write-byte (ldb (byte 8 0) dim) out)
      (write-byte (ldb (byte 8 8) dim) out)
      (write-byte (ldb (byte 8 16) dim) out)
      (write-byte (ldb (byte 8 24) dim) out))

    ;; Write floats as IEEE 754 binary32
    (loop for val across vector
          for bits = (ieee-floats:encode-float32 val)
          do (write-byte (ldb (byte 8 0) bits) out)
             (write-byte (ldb (byte 8 8) bits) out)
             (write-byte (ldb (byte 8 16) bits) out)
             (write-byte (ldb (byte 8 24) bits) out))))

(defun load-embedding (input-path)
  "Load embedding vector from file

   Args:
     input-path: Path to .vec file

   Returns:
     Float vector"

  (unless (probe-file input-path)
    (error 'embeddings-error
           :message (format nil "Embedding file not found: ~A" input-path)))

  (with-open-file (in input-path
                      :direction :input
                      :element-type '(unsigned-byte 8))
    ;; Read dimension
    (let* ((dim (+ (read-byte in)
                   (ash (read-byte in) 8)
                   (ash (read-byte in) 16)
                   (ash (read-byte in) 24)))
           (vector (make-array dim :element-type 'single-float)))

      ;; Read floats
      (loop for i from 0 below dim
            for bits = (+ (read-byte in)
                          (ash (read-byte in) 8)
                          (ash (read-byte in) 16)
                          (ash (read-byte in) 24))
            do (setf (aref vector i) (ieee-floats:decode-float32 bits)))

      vector)))

(defun load-corpus-embeddings (embeddings-dir)
  "Load all pre-computed embeddings from directory

   Args:
     embeddings-dir: Directory containing .vec files

   Returns:
     Hash table mapping article numbers to vectors"

  (let ((embeddings (make-hash-table)))
    (dolist (path (directory (merge-pathnames "article-*.vec" embeddings-dir)))
      (let* ((filename (pathname-name path))
             (number (parse-integer (subseq filename 8) :junk-allowed t)))
        (when number
          (setf (gethash number embeddings) (load-embedding path)))))

    (format t "~&; Loaded ~D pre-computed embeddings~%" (hash-table-count embeddings))
    embeddings))

;;; ============================================================================
;;; HYBRID EMBED-TEXT (Uses pre-computed if available)
;;; ============================================================================

(defvar *corpus-embeddings* nil
  "Pre-loaded corpus embeddings hash table")

(defun embed-text-hybrid (text &key article-number embeddings-dir)
  "Embed text using pre-computed embeddings if available, else GloVe fallback

   Args:
     text: Text to embed
     article-number: If provided, try to load pre-computed embedding
     embeddings-dir: Directory with .vec files

   Returns:
     Float vector"

  ;; Try pre-computed embedding first
  (when (and article-number *corpus-embeddings*)
    (let ((cached (gethash article-number *corpus-embeddings*)))
      (when cached
        (return-from embed-text-hybrid cached))))

  ;; Try loading from file
  (when (and article-number embeddings-dir)
    (let ((path (merge-pathnames
                 (format nil "article-~3,'0D.vec" article-number)
                 embeddings-dir)))
      (when (probe-file path)
        (return-from embed-text-hybrid (load-embedding path)))))

  ;; Fallback to GloVe
  (embed-text text))

(define-condition model-not-loaded (embeddings-error) ())

;;; ============================================================================
;;; WORD VECTOR LOADING (GloVe Format)
;;; ============================================================================
;;;;
;;;; GloVe format: word float1 float2 ... floatN
;;;; One word per line, space-separated

(defun load-word-vectors (path &key (max-words nil) (dimension 300))
  "Load pre-trained word vectors from GloVe/Word2Vec format file

   Args:
     path: Path to vectors file (e.g., glove.6B.300d.txt)
     max-words: Maximum words to load (nil = all)
     dimension: Expected vector dimension

   Returns:
     Number of words loaded

   Side effect:
     Sets *word-vectors* hash table"

  (unless (probe-file path)
    (error 'embeddings-error
           :message (format nil "Word vectors file not found: ~A" path)))

  (setf *embedding-dimension* dimension)
  (setf *word-vectors* (make-hash-table :test 'equal :size (or max-words 400000)))

  (let ((count 0))
    (with-open-file (stream path :direction :input)
      (loop for line = (read-line stream nil nil)
            while (and line (or (null max-words) (< count max-words)))
            do (handler-case
                   (let* ((parts (uiop:split-string line :separator '(#\Space)))
                          (word (first parts))
                          (vector (make-array dimension
                                              :element-type 'single-float
                                              :initial-element 0.0)))
                     ;; Parse floats
                     (loop for i from 0 below dimension
                           for str in (rest parts)
                           do (setf (aref vector i)
                                    (coerce (parse-float str) 'single-float)))
                     ;; Store normalized vector
                     (setf (gethash word *word-vectors*)
                           (normalize-vector vector))
                     (incf count))
                 (error ()
                   ;; Skip malformed lines
                   nil))))

    (format t "~&; Loaded ~D word vectors (dimension: ~D)~%" count dimension)
    count))

(defun parse-float (string)
  "Parse float from STRING, handling scientific notation.

   *READ-EVAL* is bound to NIL: word-vector model files are an untrusted
   supply-chain artifact, and a token like `#.(form)` would otherwise execute
   arbitrary code at load time via the reader. Disabling read-eval makes the
   `#.` macro signal instead of running — no code execution from a model file."
  (let ((*read-default-float-format* 'single-float)
        (*read-eval* nil))
    (read-from-string string)))

;;; ============================================================================
;;; TEXT EMBEDDING
;;; ============================================================================

(defun embed-text (text &key (normalize t))
  "Create embedding vector for text

   Uses average of word vectors (simple but effective baseline).

   Args:
     text: Text string to embed
     normalize: If T, return unit vector

   Returns:
     Float vector of dimension *embedding-dimension*"

  (ensure-model-loaded)

  (let* ((words (tokenize text))
         (vectors (remove nil (mapcar #'get-word-vector words)))
         (result (make-array *embedding-dimension*
                             :element-type 'single-float
                             :initial-element 0.0)))

    (if (null vectors)
        ;; No known words - return zero vector
        result
        (progn
          ;; Average all word vectors
          (dolist (vec vectors)
            (loop for i from 0 below *embedding-dimension*
                  do (incf (aref result i) (aref vec i))))
          (let ((n (length vectors)))
            (loop for i from 0 below *embedding-dimension*
                  do (setf (aref result i) (/ (aref result i) n))))
          ;; Normalize if requested
          (if normalize
              (normalize-vector result)
              result)))))

(defun embed-texts (texts &key (normalize t))
  "Create embeddings for multiple texts

   Args:
     texts: List of text strings
     normalize: If T, return unit vectors

   Returns:
     List of float vectors"
  (mapcar (lambda (text) (embed-text text :normalize normalize)) texts))

(defun get-word-vector (word)
  "Get vector for a single word

   Returns nil if word not in vocabulary"
  (gethash (string-downcase word) *word-vectors*))

(defun tokenize (text)
  "Simple tokenization - split on whitespace and punctuation

   Returns list of lowercased words"
  (let ((cleaned (cl-ppcre:regex-replace-all "[^a-zA-Zα-ωά-ώΑ-ΩΆ-Ώ0-9\\s]"
                                             text " ")))
    (remove-if (lambda (s) (zerop (length s)))
               (mapcar #'string-downcase
                       (uiop:split-string cleaned :separator '(#\Space #\Tab #\Newline))))))

;;; ============================================================================
;;; VECTOR OPERATIONS
;;; ============================================================================

(defun cosine-similarity (vec1 vec2)
  "Compute cosine similarity between two vectors

   Args:
     vec1, vec2: Float vectors of same dimension

   Returns:
     Similarity score in [-1, 1]"
  (let ((dot 0.0)
        (norm1 0.0)
        (norm2 0.0))
    (loop for i from 0 below (length vec1)
          for a = (aref vec1 i)
          for b = (aref vec2 i)
          do (incf dot (* a b))
             (incf norm1 (* a a))
             (incf norm2 (* b b)))
    (let ((denom (* (sqrt norm1) (sqrt norm2))))
      (if (zerop denom)
          0.0
          (/ dot denom)))))

(defun euclidean-distance (vec1 vec2)
  "Compute Euclidean distance between two vectors

   Args:
     vec1, vec2: Float vectors of same dimension

   Returns:
     Distance (non-negative)"
  (sqrt (loop for i from 0 below (length vec1)
              for diff = (- (aref vec1 i) (aref vec2 i))
              sum (* diff diff))))

(defun normalize-vector (vec)
  "Normalize vector to unit length

   Args:
     vec: Float vector

   Returns:
     New normalized vector"
  (let* ((norm (sqrt (loop for x across vec sum (* x x))))
         (result (make-array (length vec)
                             :element-type 'single-float)))
    (if (zerop norm)
        (loop for i from 0 below (length vec)
              do (setf (aref result i) 0.0))
        (loop for i from 0 below (length vec)
              do (setf (aref result i) (/ (aref vec i) norm))))
    result))

(defun dot-product (vec1 vec2)
  "Compute dot product of two vectors"
  (loop for i from 0 below (length vec1)
        sum (* (aref vec1 i) (aref vec2 i))))

;;; ============================================================================
;;; SIMILARITY SEARCH
;;; ============================================================================

(defun similarity (text1 text2)
  "Compute semantic similarity between two texts

   Args:
     text1, text2: Text strings

   Returns:
     Similarity score in [-1, 1]"
  (let ((vec1 (embed-text text1))
        (vec2 (embed-text text2)))
    (cosine-similarity vec1 vec2)))

(defun find-similar (query texts &key (top-k 5))
  "Find most similar texts to query

   Args:
     query: Query text string
     texts: List of candidate texts
     top-k: Number of results to return

   Returns:
     List of (text . similarity-score) pairs, sorted by similarity"
  (let* ((query-vec (embed-text query))
         (scored (mapcar (lambda (text)
                           (cons text (cosine-similarity query-vec (embed-text text))))
                         texts))
         (sorted (sort scored #'> :key #'cdr)))
    (subseq sorted 0 (min top-k (length sorted)))))

;;; ============================================================================
;;; BATCH OPERATIONS
;;; ============================================================================

(defun compute-similarity-matrix (texts)
  "Compute pairwise similarity matrix

   Args:
     texts: List of texts

   Returns:
     2D array of similarity scores"
  (let* ((n (length texts))
         (embeddings (embed-texts texts))
         (matrix (make-array (list n n) :element-type 'single-float)))
    (loop for i from 0 below n
          for vec-i = (nth i embeddings)
          do (loop for j from i below n
                   for vec-j = (nth j embeddings)
                   for sim = (cosine-similarity vec-i vec-j)
                   do (setf (aref matrix i j) sim)
                      (setf (aref matrix j i) sim)))
    matrix))

(defun cluster-by-similarity (texts &key (threshold 0.7))
  "Group texts by semantic similarity

   Args:
     texts: List of texts
     threshold: Minimum similarity for same cluster

   Returns:
     List of text clusters (lists of texts)"
  (let* ((embeddings (embed-texts texts))
         (n (length texts))
         (assigned (make-array n :initial-element nil))
         (clusters nil))

    (loop for i from 0 below n
          unless (aref assigned i)
          do (let ((cluster (list (nth i texts))))
               (setf (aref assigned i) t)
               (loop for j from (1+ i) below n
                     unless (aref assigned j)
                     when (>= (cosine-similarity (nth i embeddings)
                                                 (nth j embeddings))
                              threshold)
                     do (push (nth j texts) cluster)
                        (setf (aref assigned j) t))
               (push (nreverse cluster) clusters)))

    (nreverse clusters)))

;;; ============================================================================
;;; PERSISTENCE
;;; ============================================================================

(defun save-embeddings (texts output-path)
  "Save embeddings to file

   Format: text<TAB>vec[0] vec[1] ... vec[n]

   Args:
     texts: List of texts
     output-path: Output file path

   Returns:
     Number of embeddings saved"
  (ensure-model-loaded)
  (ensure-directories-exist output-path)

  (with-open-file (out output-path :direction :output
                                   :if-exists :supersede)
    (loop for text in texts
          for vec = (embed-text text)
          do (format out "~A~C~{~F~^ ~}~%"
                     text #\Tab (coerce vec 'list))
          count t)))

(defun load-embeddings (input-path)
  "Load pre-computed embeddings from file

   Args:
     input-path: Path to embeddings file

   Returns:
     Hash table mapping texts to vectors"
  (let ((embeddings (make-hash-table :test 'equal)))
    (with-open-file (stream input-path :direction :input)
      (loop for line = (read-line stream nil nil)
            while line
            do (let* ((tab-pos (position #\Tab line))
                      (text (subseq line 0 tab-pos))
                      (vec-str (subseq line (1+ tab-pos)))
                      (vec-parts (uiop:split-string vec-str :separator '(#\Space)))
                      (vec (make-array (length vec-parts)
                                       :element-type 'single-float)))
                 (loop for i from 0
                       for s in vec-parts
                       do (setf (aref vec i) (parse-float s)))
                 (setf (gethash text embeddings) vec))))
    embeddings))

;;; ============================================================================
;;; UTILITY
;;; ============================================================================

(defun ensure-model-loaded ()
  "Ensure word vectors are loaded"
  (unless *word-vectors*
    (error 'model-not-loaded
           :message "Word vectors not loaded. Call (load-word-vectors path) first.")))

(defun vocabulary-size ()
  "Return number of words in vocabulary"
  (if *word-vectors*
      (hash-table-count *word-vectors*)
      0))

(defun word-in-vocabulary-p (word)
  "Check if word is in vocabulary"
  (and *word-vectors*
       (gethash (string-downcase word) *word-vectors*)))

(defun oov-words (text)
  "Get list of out-of-vocabulary words in text"
  (remove-if #'word-in-vocabulary-p (tokenize text)))

(defun vocabulary-coverage (text)
  "Calculate percentage of words in vocabulary"
  (let* ((words (tokenize text))
         (known (count-if #'word-in-vocabulary-p words)))
    (if (zerop (length words))
        1.0
        (/ known (length words)))))

;;; ============================================================================
;;; END OF EMBEDDINGS-AUTHORITY.LISP
;;; ============================================================================
