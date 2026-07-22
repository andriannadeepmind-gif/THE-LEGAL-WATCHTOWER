;;;; systems/orchestrator-tests/integration/ai-export-integration-test.lisp
;;;; [0115] Integration tests για τη ΖΩΝΤΑΝΗ λειτουργικότητα AI export
;;;; (orchestrator.ai-core: manifest, provenance, determinism, validation,
;;;; statistics, performance). ΔΕΝ αφορά τους αποσυρμένους wrappers του
;;;; commands.lisp — το παλιό όνομα/σχόλια το υπονοούσαν ψευδώς.

(in-package :orchestrator-tests)

(in-suite integration-tests)

;;; ============================================================================
;;; INTEGRATION TEST FIXTURES
;;; ============================================================================

(defparameter *integration-test-dir* (pathname "/tmp/orchestrator-integration-test/"))
(defparameter *integration-output-dir* (merge-pathnames "outputs-final/" *integration-test-dir*))

(defun create-mini-test-corpus ()
  "Create a minimal test corpus with 3 articles for integration testing"
  (let* ((articles (list 
                    ;; Article 1 - Complete with blockchain proof
                    (let ((a (make-instance 'orchestrator.model:article)))
                      (setf (orchestrator.model:article-number a) 1
                            (orchestrator.model:article-title a) "Test Article One"
                            (orchestrator.model:article-content a) "Content of article one."
                            (orchestrator.model:article-hash a) "blake3:article1hash"
                            (orchestrator.model:article-processing-state a) :live
                            (orchestrator.model:article-rdf-turtle a) "@prefix eli: <...> ."
                            (orchestrator.model:article-json-ld a) "{\"@type\": \"Article\"}"
                            (orchestrator.model:article-html a) "<article>One</article>"
                            (orchestrator.model:article-blockchain-proof a) 
                            '((:|network| . "ethereum")
                              (:|txid| . "0xabc123")))
                      a)
                    
                    ;; Article 2 - Partial (no blockchain)
                    (let ((a (make-instance 'orchestrator.model:article)))
                      (setf (orchestrator.model:article-number a) 2
                            (orchestrator.model:article-title a) "Test Article Two"
                            (orchestrator.model:article-content a) "Content of article two."
                            (orchestrator.model:article-hash a) "blake3:article2hash"
                            (orchestrator.model:article-processing-state a) :live
                            (orchestrator.model:article-rdf-turtle a) "@prefix eli: <...> .")
                      a)
                    
                    ;; Article 3 - Draft state
                    (let ((a (make-instance 'orchestrator.model:article)))
                      (setf (orchestrator.model:article-number a) 3
                            (orchestrator.model:article-title a) "Test Article Three"
                            (orchestrator.model:article-content a) "Content of article three."
                            (orchestrator.model:article-hash a) "blake3:article3hash"
                            (orchestrator.model:article-processing-state a) :draft)
                      a)))
         
         (corpus (make-instance 'orchestrator.model:corpus)))
    
    ;; Configure corpus
    (setf (orchestrator.model:corpus-name corpus) "Integration Test Corpus"
          (orchestrator.model:corpus-short-name corpus) "test-integration"
          (orchestrator.model:corpus-eli-prefix corpus) "http://test.example.com/eli"
          (orchestrator.model:corpus-language corpus) "el"
          (orchestrator.model:corpus-webid corpus) "https://test.example.com/#me"
          (orchestrator.model:corpus-orcid corpus) "0000-0001-2345-6789"
          (orchestrator.model:corpus-publication-date corpus) "2024-01-01")
    
    ;; Add articles
    (dolist (article articles)
      (orchestrator.spec:add-article corpus article))
    
    corpus))

(defun cleanup-integration-test-dir ()
  "Clean up integration test directory"
  (when (probe-file *integration-test-dir*)
    (uiop:delete-directory-tree *integration-test-dir* :validate t :if-does-not-exist :ignore)))

(defun ensure-integration-test-dir ()
  "Ensure integration test directory exists"
  (ensure-directories-exist *integration-output-dir*))

(defun register-test-corpus-for-integration (corpus)
  "Register test corpus in meta registry for CLI access"
  ;; Store in meta registry ώστε τα integration tests να βρίσκουν το corpus
  (setf (gethash :test-integration orchestrator.meta::*corpus-registry*) corpus))

;;; ============================================================================
;;; DIRECT AI EXPORT INTEGRATION TESTS
;;; ============================================================================

(test integration-manifest-generation
  "Integration test: Generate manifest for mini corpus"
  (cleanup-integration-test-dir)
  (ensure-integration-test-dir)
  
  (let* ((corpus (create-mini-test-corpus))
         (manifest-path (merge-pathnames "ai/manifest.jsonl" *integration-output-dir*)))
    
    ;; Generate manifest
    (let ((result (orchestrator.ai-core:write-ai-ingest-manifest
                   corpus
                   :output-path manifest-path)))
      
      ;; File should exist
      (is (probe-file result))
      
      ;; Should have 3 lines (one per article)
      (with-open-file (stream result :direction :input)
        (let ((line-count (loop for line = (read-line stream nil nil)
                                while line
                                count 1)))
          (is (= line-count 3))))
      
      ;; Should be valid
      (multiple-value-bind (valid errors total)
          (orchestrator.ai-core:validate-manifest result)
        (is valid)
        (is (null errors))
        (is (= total 3)))))
  
  (cleanup-integration-test-dir))

(test integration-provenance-generation
  "Integration test: Generate provenance for mini corpus"
  (cleanup-integration-test-dir)
  (ensure-integration-test-dir)
  
  (let* ((corpus (create-mini-test-corpus))
         (provenance-dir (merge-pathnames "ai/provenance/" *integration-output-dir*)))
    
    ;; Generate provenance files
    (let ((results (orchestrator.ai-core:write-corpus-provenance
                    corpus
                    *integration-output-dir*)))
      
      ;; Should have 3 results
      (is (= (length results) 3))
      
      ;; Each file should exist and be valid JSON
      (dolist (result results)
        (let ((path (cdr result)))
          (is (probe-file path))
          
          ;; Validate JSON structure
          (let* ((content (alexandria:read-file-into-string path))
                 (parsed (jonathan:parse content :as :alist)))
            (is (not (null parsed)))
            (is (assoc :|article| parsed))
            (is (assoc :|corpus| parsed))
            (is (assoc :|chain_hash| parsed)))))))
  
  (cleanup-integration-test-dir))

(test integration-manifest-provenance-consistency
  "Integration test: Manifest entries point to existing provenance files"
  (cleanup-integration-test-dir)
  (ensure-integration-test-dir)
  
  (let* ((corpus (create-mini-test-corpus))
         (manifest-path (merge-pathnames "ai/manifest.jsonl" *integration-output-dir*)))
    
    ;; Generate both manifest and provenance
    (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path manifest-path)
    (orchestrator.ai-core:write-corpus-provenance corpus *integration-output-dir*)
    
    ;; Check each manifest entry
    (with-open-file (stream manifest-path :direction :input)
      (loop for line = (read-line stream nil nil)
            for line-num from 1
            while line
            do (let* ((entry (jonathan:parse line :as :alist))
                      (article-num (cdr (assoc :|article_number| entry))))
                 
                 ;; Corresponding provenance file should exist — όνομα από τις
                 ;; έδρες ταυτότητας (το article_number είναι πλέον κανονικό
                 ;; label-aware string, π.χ. «5Α»).
                 (let ((provenance-path
                        (merge-pathnames
                         (make-pathname
                          :name (format nil "article-~A-provenance"
                                        (orchestrator.model:pad-article-id
                                         (orchestrator.model:article-base-number
                                          nil (string article-num))
                                         (string article-num)))
                          :type "json"
                          :directory '(:relative "ai" "provenance"))
                         *integration-output-dir*)))
                   (is (probe-file provenance-path)
                       "Provenance file for article ~A should exist" article-num))))))
  
  (cleanup-integration-test-dir))

(test integration-deterministic-build
  "Integration test: Full AI export is deterministic"
  (cleanup-integration-test-dir)
  (ensure-integration-test-dir)
  
  (let* ((corpus (create-mini-test-corpus))
         (manifest-path-1 (merge-pathnames "ai/run1/manifest.jsonl" *integration-output-dir*))
         (manifest-path-2 (merge-pathnames "ai/run2/manifest.jsonl" *integration-output-dir*)))
    
    ;; Set deterministic timestamp
    (let ((orchestrator.ai-core:*build-timestamp-override* 1700000000))
      
      ;; First run
      (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path manifest-path-1)
      
      ;; Second run
      (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path manifest-path-2))
    
    ;; Files should be identical
    (let ((content1 (alexandria:read-file-into-string manifest-path-1))
          (content2 (alexandria:read-file-into-string manifest-path-2)))
      (is (string= content1 content2))))
  
  (cleanup-integration-test-dir))

;;; ============================================================================
;;; STATISTICS INTEGRATION TESTS
;;; ============================================================================

(test integration-stats-accuracy
  "Integration test: Statistics accurately reflect corpus state"
  (cleanup-integration-test-dir)
  (ensure-integration-test-dir)
  
  (let* ((corpus (create-mini-test-corpus))
         (manifest-path (merge-pathnames "ai/manifest.jsonl" *integration-output-dir*)))
    
    (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path manifest-path)
    
    (let ((stats (orchestrator.ai-core:manifest-stats manifest-path)))
      ;; Total: 3 articles
      (is (= (getf stats :total) 3))
      
      ;; Live: 2 articles (1 and 2)
      (is (= (getf stats :live) 2))
      
      ;; Anchored: 1 article (only article 1 has blockchain proof)
      (is (= (getf stats :anchored) 1))
      
      ;; Completion: 2/3 ≈ 66.67%
      (is (> (getf stats :completion-percentage) 60))
      (is (< (getf stats :completion-percentage) 70))))
  
  (cleanup-integration-test-dir))

;;; ============================================================================
;;; ERROR HANDLING INTEGRATION TESTS
;;; ============================================================================

(test integration-handles-empty-corpus
  "Integration test: Gracefully handles empty corpus"
  (cleanup-integration-test-dir)
  (ensure-integration-test-dir)
  
  (let* ((empty-corpus (make-instance 'orchestrator.model:corpus))
         (manifest-path (merge-pathnames "ai/empty-manifest.jsonl" *integration-output-dir*)))
    
    ;; Configure empty corpus
    (setf (orchestrator.model:corpus-name empty-corpus) "Empty Corpus"
          (orchestrator.model:corpus-short-name empty-corpus) "empty"
          (orchestrator.model:corpus-eli-prefix empty-corpus) "http://empty.test"
          (orchestrator.model:corpus-language empty-corpus) "el"
          (orchestrator.model:corpus-webid empty-corpus) "https://test.com/#me"
          (orchestrator.model:corpus-orcid empty-corpus) "0000-0000-0000-0000"
          (orchestrator.model:corpus-publication-date empty-corpus) "2024-01-01")
    
    ;; Should not error
    (let ((result (orchestrator.ai-core:write-ai-ingest-manifest 
                   empty-corpus 
                   :output-path manifest-path)))
      
      (is (probe-file result))
      
      ;; File should be empty (or just newlines)
      (let ((content (alexandria:read-file-into-string result)))
        (is (or (zerop (length content))
               (every (lambda (c) (member c '(#\Newline #\Return))) content))))))
  
  (cleanup-integration-test-dir))

;;; ============================================================================
;;; LARGE CORPUS SIMULATION TESTS
;;; ============================================================================

(test integration-handles-larger-corpus
  "Integration test: Handles corpus with 50 articles efficiently"
  (cleanup-integration-test-dir)
  (ensure-integration-test-dir)
  
  (let* ((corpus (make-instance 'orchestrator.model:corpus))
         (manifest-path (merge-pathnames "ai/large-manifest.jsonl" *integration-output-dir*)))
    
    ;; Configure corpus
    (setf (orchestrator.model:corpus-name corpus) "Large Test Corpus"
          (orchestrator.model:corpus-short-name corpus) "large-test"
          (orchestrator.model:corpus-eli-prefix corpus) "http://large.test/eli"
          (orchestrator.model:corpus-language corpus) "el"
          (orchestrator.model:corpus-webid corpus) "https://test.com/#me"
          (orchestrator.model:corpus-orcid corpus) "0000-0000-0000-0000"
          (orchestrator.model:corpus-publication-date corpus) "2024-01-01")
    
    ;; Add 50 articles
    (loop for i from 1 to 50
          for article = (make-instance 'orchestrator.model:article)
          do (progn
               (setf (orchestrator.model:article-number article) i
                     (orchestrator.model:article-title article) (format nil "Article ~D" i)
                     (orchestrator.model:article-content article) (format nil "Content ~D" i)
                     (orchestrator.model:article-hash article) (format nil "hash~D" i)
                     (orchestrator.model:article-processing-state article) :live)
               (orchestrator.spec:add-article corpus article)))
    
    ;; Generate manifest (should complete reasonably fast)
    (let ((start-time (get-internal-real-time)))
      (orchestrator.ai-core:write-ai-ingest-manifest corpus :output-path manifest-path)
      (let ((elapsed-ms (/ (* 1000 (- (get-internal-real-time) start-time))
                          internal-time-units-per-second)))
        
        ;; Should complete in under 5 seconds
        (is (< elapsed-ms 5000))))
    
    ;; Validate result
    (multiple-value-bind (valid errors total)
        (orchestrator.ai-core:validate-manifest manifest-path)
      (is valid)
      (is (= total 50))))
  
  (cleanup-integration-test-dir))
