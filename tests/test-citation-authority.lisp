;;;; tests/test-citation-authority.lisp
;;;; ============================================================================
;;;; CITATION AUTHORITY VERIFICATION TESTS
;;;; ============================================================================
;;;;
;;;; Mathematical property tests that verify correctness WITHOUT needing Python.
;;;; These tests verify that our algorithms satisfy known mathematical properties.
;;;;
;;;; VERIFICATION STRATEGY:
;;;;   1. PageRank: sum of all ranks = 1.0 (probability distribution)
;;;;   2. PageRank: all ranks in (0, 1)
;;;;   3. PageRank: convergence (same result on repeated runs)
;;;;   4. Betweenness: all values in [0, 1] after normalization
;;;;   5. TF-IDF: IDF(rare term) > IDF(common term)
;;;;   6. Cosine: similarity(A,A) = 1.0
;;;;   7. Cosine: similarity in [-1, 1]
;;;;
;;;; Author: ORCHESTRATOR
;;;; Created: 2026-01-03
;;;; ============================================================================

(defpackage :orchestrator.tests.citation-authority
  (:use :cl :orchestrator.citation-authority)
  (:export #:run-all-tests
           #:test-pagerank-properties
           #:test-betweenness-properties
           #:test-tfidf-properties
           #:test-cosine-properties
           #:test-graph-operations))

(in-package :orchestrator.tests.citation-authority)

;;; ============================================================================
;;; TEST UTILITIES
;;; ============================================================================

(defvar *test-count* 0)
(defvar *pass-count* 0)
(defvar *fail-count* 0)

(defmacro deftest (name &body body)
  "Define a test case"
  `(defun ,name ()
     (format t "~%[TEST] ~A~%" ',name)
     (incf *test-count*)
     (handler-case
         (progn ,@body
                (incf *pass-count*)
                (format t "  ✓ PASSED~%")
                t)
       (error (e)
         (incf *fail-count*)
         (format t "  ✗ FAILED: ~A~%" e)
         nil))))

(defun assert-true (condition &optional message)
  "Assert that condition is true"
  (unless condition
    (error "Assertion failed: ~A" (or message "condition is false"))))

(defun assert-equal (expected actual &optional message)
  "Assert that expected equals actual"
  (unless (equal expected actual)
    (error "Assertion failed: ~A~%  Expected: ~A~%  Actual: ~A"
           (or message "values not equal") expected actual)))

(defun assert-approximately-equal (expected actual tolerance &optional message)
  "Assert that expected ≈ actual within tolerance"
  (unless (< (abs (- expected actual)) tolerance)
    (error "Assertion failed: ~A~%  Expected: ~A~%  Actual: ~A~%  Tolerance: ~A"
           (or message "values not approximately equal") expected actual tolerance)))

(defun assert-in-range (value min max &optional message)
  "Assert that min <= value <= max"
  (unless (and (>= value min) (<= value max))
    (error "Assertion failed: ~A~%  Value ~A not in range [~A, ~A]"
           (or message "value out of range") value min max)))

;;; ============================================================================
;;; TEST GRAPH CREATION
;;; ============================================================================

(defun create-test-graph-simple ()
  "Create simple test graph: A → B → C"
  (let ((g (make-citation-graph)))
    (add-article g 1 :title "Article A" :text "Reference to άρθρο 2")
    (add-article g 2 :title "Article B" :text "Reference to άρθρο 3")
    (add-article g 3 :title "Article C" :text "No references")
    (add-citation g 1 2)
    (add-citation g 2 3)
    g))

(defun create-test-graph-complex ()
  "Create more complex test graph for thorough testing"
  (let ((g (make-citation-graph)))
    ;; Add 8 articles (similar to Python mock data)
    (add-article g 1 :title "State Form" :text "Basic provisions on state structure")
    (add-article g 2 :title "Popular Sovereignty" :text "All powers derive from the People")
    (add-article g 5 :title "Individual Rights" :text "Free development of personality")
    (add-article g 16 :title "Education" :text "Art and science are free άρθρο 5")
    (add-article g 21 :title "Family" :text "Family as foundation of nation")
    (add-article g 25 :title "Rights and Duties" :text "General principles άρθρο 5 άρθρο 2")
    (add-article g 28 :title "International Relations" :text "Generally recognized rules άρθρο 1")
    (add-article g 106 :title "Revision" :text "Provisions that may not be revised άρθρο 1 άρθρο 2")

    ;; Add citations (same as Python mock)
    (add-citation g 16 5)   ; Education cites Individual Rights
    (add-citation g 16 21)  ; Education cites Family
    (add-citation g 25 5)   ; Rights cites Individual Rights
    (add-citation g 25 2)   ; Rights cites Popular Sovereignty
    (add-citation g 28 1)   ; International Relations cites State Form
    (add-citation g 106 1)  ; Revision cites State Form
    (add-citation g 106 2)  ; Revision cites Popular Sovereignty
    g))

;;; ============================================================================
;;; GRAPH OPERATION TESTS
;;; ============================================================================

(deftest test-graph-creation
  "Test basic graph creation and article/citation addition"
  (let ((g (make-citation-graph)))
    (assert-equal 0 (article-count g) "Empty graph should have 0 articles")
    (assert-equal 0 (citation-count g) "Empty graph should have 0 citations")

    (add-article g 1 :title "Test")
    (assert-equal 1 (article-count g) "Should have 1 article after add")

    (add-article g 2 :title "Test 2")
    (add-citation g 1 2)
    (assert-equal 1 (citation-count g) "Should have 1 citation")

    ;; Test duplicate prevention
    (add-citation g 1 2)
    (assert-equal 1 (citation-count g) "Duplicate citation should not be added")))

(deftest test-graph-adjacency
  "Test that adjacency lists are correctly maintained"
  (let ((g (create-test-graph-simple)))
    ;; Article 1 cites Article 2
    (assert-true (member 2 (gethash 1 (citation-graph-outgoing g)))
                 "Article 1 should have 2 in outgoing")
    ;; Article 2 is cited by Article 1
    (assert-true (member 1 (gethash 2 (citation-graph-incoming g)))
                 "Article 2 should have 1 in incoming")))

;;; ============================================================================
;;; PAGERANK PROPERTY TESTS
;;; ============================================================================

(deftest test-pagerank-sum-equals-one
  "PageRank is a probability distribution: sum of all ranks must equal 1.0"
  (let* ((g (create-test-graph-complex))
         (pr (pagerank g))
         (sum 0.0d0))
    (maphash (lambda (k v)
               (declare (ignore k))
               (incf sum v))
             pr)
    (assert-approximately-equal 1.0d0 sum 1e-6
                                "Sum of PageRank values must equal 1.0")))

(deftest test-pagerank-values-in-range
  "All PageRank values must be in (0, 1)"
  (let* ((g (create-test-graph-complex))
         (pr (pagerank g)))
    (maphash (lambda (k v)
               (declare (ignore k))
               (assert-in-range v 0.0 1.0 "PageRank value must be in [0, 1]"))
             pr)))

(deftest test-pagerank-convergence
  "PageRank must give same result on repeated runs"
  (let* ((g (create-test-graph-complex))
         (pr1 (pagerank g))
         (pr2 (pagerank g)))
    (maphash (lambda (k v1)
               (let ((v2 (gethash k pr2)))
                 (assert-approximately-equal v1 v2 1e-10
                                             (format nil "PageRank for article ~A should be deterministic" k))))
             pr1)))

(deftest test-pagerank-highly-cited-article
  "More cited articles should have higher PageRank"
  (let* ((g (create-test-graph-complex))
         (pr (pagerank g)))
    ;; Articles 1, 2, and 5 are most cited
    ;; They should have higher PageRank than articles with no incoming citations
    (let ((rank-1 (gethash 1 pr))
          (rank-16 (gethash 16 pr)))  ; Article 16 cites but is not cited
      (assert-true (> rank-1 rank-16)
                   "More cited article should have higher PageRank"))))

;;; ============================================================================
;;; BETWEENNESS CENTRALITY TESTS
;;; ============================================================================

(deftest test-betweenness-in-range
  "Betweenness centrality values must be in [0, 1] after normalization"
  (let* ((g (create-test-graph-complex))
         (bc (betweenness-centrality g)))
    (maphash (lambda (k v)
               (declare (ignore k))
               (assert-in-range v 0.0 1.0 "Betweenness must be in [0, 1]"))
             bc)))

(deftest test-betweenness-leaf-nodes
  "Leaf nodes (no outgoing edges to bridge) should have low betweenness"
  (let* ((g (create-test-graph-simple))
         (bc (betweenness-centrality g)))
    ;; Article 3 is a leaf - nothing goes through it
    (let ((bc-3 (gethash 3 bc)))
      (assert-approximately-equal 0.0 bc-3 1e-10
                                  "Leaf node should have 0 betweenness"))))

;;; ============================================================================
;;; TF-IDF TESTS
;;; ============================================================================

(deftest test-tfidf-rare-term-higher
  "Rare terms should have higher IDF than common terms"
  (let* ((docs '("the cat sat on the mat"
                 "the dog sat on the log"
                 "the bird flew over the tree"
                 "unique word here only"))
         (idf (compute-idf docs)))
    ;; "the" appears in all documents - lowest IDF
    ;; "unique" appears in only one - highest IDF
    (let ((idf-the (gethash "the" idf 0.0))
          (idf-unique (gethash "unique" idf 0.0)))
      (assert-true (> idf-unique idf-the)
                   "Rare term 'unique' should have higher IDF than common 'the'"))))

(deftest test-tfidf-embeddings-generated
  "TF-IDF should generate embeddings for all articles"
  (let* ((g (create-test-graph-complex))
         (embeddings (tfidf-embed g :max-features 100)))
    (assert-equal 8 (hash-table-count embeddings)
                  "Should have embeddings for all 8 articles")))

;;; ============================================================================
;;; COSINE SIMILARITY TESTS
;;; ============================================================================

(deftest test-cosine-self-similarity
  "Cosine similarity of a vector with itself must be 1.0"
  (let ((vec (make-hash-table :test 'equal)))
    (setf (gethash "term1" vec) 0.5)
    (setf (gethash "term2" vec) 0.3)
    (setf (gethash "term3" vec) 0.8)
    (assert-approximately-equal 1.0d0 (cosine-similarity vec vec) 1e-10
                                "Self-similarity must be 1.0")))

(deftest test-cosine-in-range
  "Cosine similarity must be in [-1, 1]"
  (let ((vec1 (make-hash-table :test 'equal))
        (vec2 (make-hash-table :test 'equal)))
    (setf (gethash "a" vec1) 0.5)
    (setf (gethash "b" vec1) 0.5)
    (setf (gethash "a" vec2) 0.3)
    (setf (gethash "c" vec2) 0.7)
    (let ((sim (cosine-similarity vec1 vec2)))
      (assert-in-range sim -1.0d0 1.0d0 "Cosine similarity must be in [-1, 1]"))))

(deftest test-cosine-orthogonal-vectors
  "Orthogonal vectors (no common terms) should have similarity 0"
  (let ((vec1 (make-hash-table :test 'equal))
        (vec2 (make-hash-table :test 'equal)))
    (setf (gethash "only-in-1" vec1) 1.0)
    (setf (gethash "only-in-2" vec2) 1.0)
    (assert-approximately-equal 0.0d0 (cosine-similarity vec1 vec2) 1e-10
                                "Orthogonal vectors should have 0 similarity")))

;;; ============================================================================
;;; GREEK CITATION EXTRACTION TESTS
;;; ============================================================================

(deftest test-greek-citation-extraction
  "Should correctly extract Greek article citations"
  (let ((text "Σύμφωνα με το άρθρο 5 και το άρθρον 16 του Συντάγματος..."))
    (let ((citations (extract-greek-citations text)))
      (assert-true (member 5 citations) "Should find άρθρο 5")
      (assert-true (member 16 citations) "Should find άρθρον 16"))))

(deftest test-greek-tokenizer
  "Greek tokenizer should handle accented characters"
  (let ((tokens (tokenize-greek "Η δημοκρατία είναι η βάση")))
    (assert-true (member "δημοκρατία" tokens :test #'equal)
                 "Should preserve accented δημοκρατία")))

;;; ============================================================================
;;; RUN ALL TESTS
;;; ============================================================================

(defun run-all-tests ()
  "Run all verification tests"
  (setf *test-count* 0)
  (setf *pass-count* 0)
  (setf *fail-count* 0)

  (format t "~%")
  (format t "════════════════════════════════════════════════════════════~%")
  (format t "  CITATION AUTHORITY VERIFICATION TESTS~%")
  (format t "════════════════════════════════════════════════════════════~%")

  ;; Graph operations
  (test-graph-creation)
  (test-graph-adjacency)

  ;; PageRank properties
  (test-pagerank-sum-equals-one)
  (test-pagerank-values-in-range)
  (test-pagerank-convergence)
  (test-pagerank-highly-cited-article)

  ;; Betweenness centrality
  (test-betweenness-in-range)
  (test-betweenness-leaf-nodes)

  ;; TF-IDF
  (test-tfidf-rare-term-higher)
  (test-tfidf-embeddings-generated)

  ;; Cosine similarity
  (test-cosine-self-similarity)
  (test-cosine-in-range)
  (test-cosine-orthogonal-vectors)

  ;; Greek extraction
  (test-greek-citation-extraction)
  (test-greek-tokenizer)

  (format t "~%")
  (format t "════════════════════════════════════════════════════════════~%")
  (format t "  RESULTS: ~D tests, ~D passed, ~D failed~%"
          *test-count* *pass-count* *fail-count*)
  (format t "════════════════════════════════════════════════════════════~%")

  (if (zerop *fail-count*)
      (format t "  ✓ ALL TESTS PASSED - VERIFIED CORRECT~%")
      (format t "  ✗ SOME TESTS FAILED - NEEDS FIX~%"))

  (format t "════════════════════════════════════════════════════════════~%")

  (zerop *fail-count*))

;;; ============================================================================
;;; END OF TEST FILE
;;; ============================================================================
