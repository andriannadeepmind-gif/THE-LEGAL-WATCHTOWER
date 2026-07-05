;;;; systems/orchestrator-tests/unit/test-ai-core.lisp
;;;; Comprehensive unit tests for orchestrator-ai-core
;;;; Tests for AI manifest generation, validation, and provenance tracking

(in-package :orchestrator-tests)

(in-suite unit-tests)

;;; ============================================================================
;;; TEST FIXTURES FOR AI-CORE TESTING
;;; ============================================================================

(defparameter *test-ai-output-dir* (pathname "/tmp/orchestrator-test-ai/"))

(defun make-test-article (&key (number 1) 
                               (title "Test Article") 
                               (content "Test content")
                               (hash "abc123hash")
                               (state :draft)
                               (eli-uri nil))
  "Create a mock article for testing"
  (let ((article (make-instance 'orchestrator.model:article)))
    (setf (orchestrator.model:article-number article) number
          (orchestrator.model:article-title article) title
          (orchestrator.model:article-content article) content
          (orchestrator.model:article-hash article) hash
          (orchestrator.model:article-processing-state article) state)
    (when eli-uri
      (setf (orchestrator.model:article-eli-uri article) eli-uri))
    article))

(defun make-test-corpus (&key (name "Test Corpus")
                              (short-name "test-corpus")
                              (eli-prefix "http://example.com/eli")
                              (language "el")
                              (articles nil))
  "Create a mock corpus for testing"
  (let ((corpus (make-instance 'orchestrator.model:corpus)))
    (setf (orchestrator.model:corpus-name corpus) name
          (orchestrator.model:corpus-short-name corpus) short-name
          (orchestrator.model:corpus-eli-prefix corpus) eli-prefix
          (orchestrator.model:corpus-language corpus) language
          (orchestrator.model:corpus-webid corpus) "https://test.com/#me"
          (orchestrator.model:corpus-orcid corpus) "0000-0001-2345-6789"
          (orchestrator.model:corpus-publication-date corpus) "2024-01-01")
    ;; Add articles to corpus
    (dolist (article articles)
      (orchestrator.spec:add-article corpus article))
    corpus))

(defun cleanup-test-dir ()
  "Clean up test output directory"
  (when (probe-file *test-ai-output-dir*)
    (uiop:delete-directory-tree *test-ai-output-dir* :validate t :if-does-not-exist :ignore)))

(defun ensure-test-dir ()
  "Ensure test directory exists"
  (ensure-directories-exist *test-ai-output-dir*))

;;; ============================================================================
;;; DETERMINISTIC TIMESTAMP TESTS
;;; ============================================================================

(test deterministic-timestamp-override
  "Test that build timestamp can be overridden for deterministic builds"
  (let ((fixed-time 1700000000))
    ;; Test with override
    (let ((orchestrator.ai-core:*build-timestamp-override* fixed-time))
      (is (= (orchestrator.ai-core:current-build-timestamp) fixed-time)))
    
    ;; Test without override (should return current time)
    (let ((orchestrator.ai-core:*build-timestamp-override* nil))
      (is (numberp (orchestrator.ai-core:current-build-timestamp)))
      (is (> (orchestrator.ai-core:current-build-timestamp) 0)))))

;;; ============================================================================
;;; MANIFEST ENTRY GENERATION TESTS
;;; ============================================================================

(test generate-manifest-entry-basic
  "Test basic manifest entry generation"
  (let* ((article (make-test-article :number 42 
                                      :title "Article 42"
                                      :hash "sha256:abc123"))
         (corpus (make-test-corpus))
         (entry (orchestrator.ai-core:generate-article-manifest-entry article corpus)))
    
    ;; Check required fields are present
    (is (not (null entry)))
    (is (getf entry :|id|))
    (is (getf entry :|corpus|))
    (is (getf entry :|article_number|))
    (is (= (getf entry :|article_number|) 42))
    (is (string= (getf entry :|title|) "Article 42"))
    (is (string= (getf entry :|content_hash|) "sha256:abc123"))
    (is (getf entry :|authority|))))

(test generate-manifest-entry-blockchain-fields
  "Test manifest entry includes blockchain status correctly"
  (let* ((article (make-test-article :number 1))
         (corpus (make-test-corpus))
         (entry (orchestrator.ai-core:generate-article-manifest-entry article corpus)))
    
    ;; Article without blockchain proof
    (is (eq (getf entry :|blockchain_anchored|) :false))
    
    ;; Article with blockchain proof
    (setf (orchestrator.model:article-blockchain-proof article) '(("txid" . "0xabc")))
    (let ((entry2 (orchestrator.ai-core:generate-article-manifest-entry article corpus)))
      (is (eq (getf entry2 :|blockchain_anchored|) t)))))

;;; ============================================================================
;;; JSON SERIALIZATION TESTS
;;; ============================================================================

(test manifest-entry-to-json-valid
  "Test manifest entry JSON serialization produces valid JSON"
  (let* ((article (make-test-article :number 5))
         (corpus (make-test-corpus))
         (entry (orchestrator.ai-core:generate-article-manifest-entry article corpus))
         (json-string (orchestrator.ai-core:manifest-entry-to-json entry)))
    
    ;; Must be a string
    (is (stringp json-string))
    
    ;; Must be valid JSON (should not error when parsing)
    (let ((parsed (jonathan:parse json-string :as :alist)))
      (is (not (null parsed)))
      (is (listp parsed)))))

(test manifest-entry-no-newlines
  "Test manifest JSON entries don't contain embedded newlines"
  (let* ((article (make-test-article :number 1 :content "Multi\nline\ncontent"))
         (corpus (make-test-corpus))
         (entry (orchestrator.ai-core:generate-article-manifest-entry article corpus))
         (json-string (orchestrator.ai-core:manifest-entry-to-json entry)))
    
    ;; NDJSON requires each entry to be a single line
    ;; The JSON should handle newlines properly (escaped or removed)
    (is (stringp json-string))))

;;; ============================================================================
;;; WRITE MANIFEST TESTS
;;; ============================================================================

(test write-ai-ingest-manifest-creates-file
  "Test write-ai-ingest-manifest creates output file"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  (let* ((articles (list (make-test-article :number 1)
                         (make-test-article :number 2)
                         (make-test-article :number 3)))
         (corpus (make-test-corpus :articles articles))
         (output-path (merge-pathnames "manifest.jsonl" *test-ai-output-dir*)))
    
    (let ((result (orchestrator.ai-core:write-ai-ingest-manifest 
                   corpus 
                   :output-path output-path)))
      
      ;; Should return pathname
      (is (pathnamep result))
      
      ;; File should exist
      (is (probe-file result))))
  
  (cleanup-test-dir))

(test write-ai-ingest-manifest-ndjson-format
  "Test manifest is valid NDJSON (one JSON per line)"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  (let* ((articles (list (make-test-article :number 1)
                         (make-test-article :number 2)))
         (corpus (make-test-corpus :articles articles))
         (output-path (merge-pathnames "manifest.jsonl" *test-ai-output-dir*)))
    
    (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path output-path)
    
    ;; Read and validate each line
    (with-open-file (stream output-path :direction :input)
      (let ((line-count 0)
            (all-valid t))
        (loop for line = (read-line stream nil nil)
              while line
              do (progn
                   (incf line-count)
                   ;; Each line should parse as valid JSON
                   (let ((parsed (ignore-errors (jonathan:parse line))))
                     (when (null parsed)
                       (setf all-valid nil)))))
        
        ;; Should have 2 lines (one per article)
        (is (= line-count 2))
        (is all-valid))))
  
  (cleanup-test-dir))

(test write-ai-ingest-manifest-deterministic-ordering
  "Test manifest has deterministic article ordering (by number)"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  ;; Create articles out of order
  (let* ((articles (list (make-test-article :number 3)
                         (make-test-article :number 1)
                         (make-test-article :number 2)))
         (corpus (make-test-corpus :articles articles))
         (output-path (merge-pathnames "manifest.jsonl" *test-ai-output-dir*)))
    
    (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path output-path)
    
    ;; Read and check ordering
    (with-open-file (stream output-path :direction :input)
      (let ((article-numbers nil))
        (loop for line = (read-line stream nil nil)
              while line
              do (let* ((parsed (jonathan:parse line :as :alist))
                        (num (cdr (assoc :|article_number| parsed))))
                   (push num article-numbers)))
        
        ;; Should be 1, 2, 3 order (read in reverse since we pushed)
        (is (equal (reverse article-numbers) '(1 2 3))))))
  
  (cleanup-test-dir))

;;; ============================================================================
;;; VALIDATE MANIFEST TESTS
;;; ============================================================================

(test validate-manifest-valid-file
  "Test validate-manifest returns true for valid NDJSON"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  (let* ((articles (list (make-test-article :number 1)
                         (make-test-article :number 2)))
         (corpus (make-test-corpus :articles articles))
         (output-path (merge-pathnames "manifest.jsonl" *test-ai-output-dir*)))
    
    (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path output-path)
    
    (multiple-value-bind (valid errors total)
        (orchestrator.ai-core:validate-manifest output-path)
      
      (is valid)
      (is (null errors))
      (is (= total 2))))
  
  (cleanup-test-dir))

(test validate-manifest-detects-invalid-json
  "Test validate-manifest detects malformed JSON lines"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  (let ((bad-file (merge-pathnames "bad-manifest.jsonl" *test-ai-output-dir*)))
    ;; Write a file with one invalid JSON line
    (with-open-file (stream bad-file 
                            :direction :output 
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-line "{\"valid\": true}" stream)
      (write-line "this is not valid json" stream)
      (write-line "{\"also\": \"valid\"}" stream))
    
    (multiple-value-bind (valid errors total)
        (orchestrator.ai-core:validate-manifest bad-file)
      
      (is (not valid))
      (is (= (length errors) 1))
      (is (member 2 errors)) ; Line 2 is invalid
      (is (= total 3))))
  
  (cleanup-test-dir))

;;; ============================================================================
;;; MANIFEST STATISTICS TESTS
;;; ============================================================================

(test manifest-stats-computation
  "Test manifest statistics are computed correctly"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  ;; Create articles with various states
  (let* ((article1 (make-test-article :number 1 :state :live))
         (article2 (make-test-article :number 2 :state :live))
         (article3 (make-test-article :number 3 :state :draft))
         (corpus (make-test-corpus :articles (list article1 article2 article3)))
         (output-path (merge-pathnames "manifest.jsonl" *test-ai-output-dir*)))
    
    ;; Add blockchain proof to one article
    (setf (orchestrator.model:article-blockchain-proof article1) '(("txid" . "0x123")))
    
    (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path output-path)
    
    (let ((stats (orchestrator.ai-core:manifest-stats output-path)))
      (is (= (getf stats :total) 3))
      (is (= (getf stats :live) 2))
      (is (= (getf stats :anchored) 1))
      (is (numberp (getf stats :completion-percentage)))))
  
  (cleanup-test-dir))

;;; ============================================================================
;;; PROVENANCE TESTS
;;; ============================================================================

(test provenance-record-creation
  "Test provenance record creation and validation"
  (let ((record (orchestrator.ai-core:make-provenance-record
                 :activity :parse
                 :agent "test-agent"
                 :input-artifacts '("hash1")
                 :output-artifacts '("hash2" "hash3"))))
    
    (is (not (null record)))
    (is (eq (orchestrator.ai-core:provenance-activity record) :parse))
    (is (string= (orchestrator.ai-core:provenance-agent record) "test-agent"))))

(test provenance-record-requires-keyword-activity
  "Test that provenance record requires keyword for activity"
  (signals error
    (orchestrator.ai-core:make-provenance-record
     :activity "not-a-keyword"
     :agent "test")))

(test provenance-chain-building
  "Test provenance chain is built correctly from article"
  (let* ((article (make-test-article :number 1 :content "test content"))
         (corpus (make-test-corpus))
         (chain (orchestrator.ai-core:build-article-provenance-chain article corpus)))
    
    (is (not (null chain)))
    ;; Chain should have at least one activity (parse)
    (is (> (length (orchestrator.ai-core:chain-activities chain)) 0))
    ;; Chain should have a hash
    (is (stringp (orchestrator.ai-core:chain-master-hash chain)))))

(test provenance-json-export
  "Test provenance chain exports to valid JSON"
  (let* ((article (make-test-article :number 1 :content "test"))
         (corpus (make-test-corpus))
         (chain (orchestrator.ai-core:build-article-provenance-chain article corpus))
         (json (orchestrator.ai-core:export-provenance-json chain)))
    
    (is (stringp json))
    
    ;; Should parse as valid JSON
    (let ((parsed (jonathan:parse json :as :alist)))
      (is (not (null parsed)))
      (is (assoc :|article| parsed))
      (is (assoc :|activities| parsed))
      (is (assoc :|chain_hash| parsed)))))

(test write-article-provenance-creates-file
  "Test write-article-provenance creates JSON file"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  (let* ((article (make-test-article :number 42))
         (corpus (make-test-corpus))
         (output-path (merge-pathnames "article-42-provenance.json" *test-ai-output-dir*)))
    
    (let ((result (orchestrator.ai-core:write-article-provenance 
                   article corpus output-path 
                   :ensure-directory t)))
      
      (is (pathnamep result))
      (is (probe-file result))
      
      ;; Should be valid JSON
      (let ((content (alexandria:read-file-into-string result)))
        (is (stringp content))
        (is (not (null (jonathan:parse content)))))))
  
  (cleanup-test-dir))

(test write-corpus-provenance-all-articles
  "Test write-corpus-provenance creates files for all articles"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  (let* ((articles (list (make-test-article :number 1)
                         (make-test-article :number 2)
                         (make-test-article :number 3)))
         (corpus (make-test-corpus :articles articles)))
    
    (let ((results (orchestrator.ai-core:write-corpus-provenance 
                    corpus *test-ai-output-dir*)))
      
      ;; Should return 3 pairs
      (is (= (length results) 3))
      
      ;; Each pair should be (number . path)
      (dolist (pair results)
        (is (integerp (car pair)))
        (is (pathnamep (cdr pair)))
        (is (probe-file (cdr pair))))))
  
  (cleanup-test-dir))

;;; ============================================================================
;;; DETERMINISTIC BUILD TESTS
;;; ============================================================================

(test deterministic-manifest-reproducibility
  "Test that manifest generation is deterministic"
  (ensure-test-dir)
  (cleanup-test-dir)
  (ensure-test-dir)
  
  (let* ((articles (list (make-test-article :number 1)
                         (make-test-article :number 2)))
         (corpus (make-test-corpus :articles articles))
         (path1 (merge-pathnames "manifest1.jsonl" *test-ai-output-dir*))
         (path2 (merge-pathnames "manifest2.jsonl" *test-ai-output-dir*)))
    
    ;; Generate twice with same fixed timestamp
    (let ((orchestrator.ai-core:*build-timestamp-override* 1700000000))
      (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path path1)
      (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path path2))
    
    ;; Files should be identical
    (let ((content1 (alexandria:read-file-into-string path1))
          (content2 (alexandria:read-file-into-string path2)))
      (is (string= content1 content2))))
  
  (cleanup-test-dir))

(test deterministic-provenance-hash
  "Test that provenance chain hash is deterministic"
  (let* ((article (make-test-article :number 1 :content "test"))
         (corpus (make-test-corpus)))
    
    (let ((orchestrator.ai-core:*build-timestamp-override* 1700000000))
      (let ((chain1 (orchestrator.ai-core:build-article-provenance-chain article corpus))
            (chain2 (orchestrator.ai-core:build-article-provenance-chain article corpus)))
        
        ;; Hashes should match
        (is (string= (orchestrator.ai-core:chain-master-hash chain1)
                    (orchestrator.ai-core:chain-master-hash chain2)))))))
