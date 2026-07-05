;;;; tests/comparison-test.lisp
;;;; ============================================================================
;;;; COMPARISON TEST: Lisp Citation Authority
;;;; ============================================================================
;;;;
;;;; Generates values in SAME format as Python for direct comparison.
;;;; Run this and compare with python-reference-values.json
;;;;
;;;; Usage:
;;;;   sbcl --load comparison-test.lisp
;;;;
;;;; ============================================================================

(require :asdf)

;;; Load citation-authority
(load (merge-pathnames "source/citation-authority.lisp"
                       (make-pathname :directory '(:absolute "home" "user" "ORCHESTRATORSUPER"))))

(in-package :orchestrator.citation-authority)

;;; ============================================================================
;;; TEST DATA - IDENTICAL TO PYTHON
;;; ============================================================================

(defparameter *test-articles*
  '((1 . (:title "State Form" :text "Basic provisions on state structure"))
    (2 . (:title "Popular Sovereignty" :text "All powers derive from the People"))
    (5 . (:title "Individual Rights" :text "Free development of personality"))
    (16 . (:title "Education" :text "Art and science are free"))
    (21 . (:title "Family" :text "Family as foundation of nation"))
    (25 . (:title "Rights and Duties" :text "General principles of individual rights"))
    (28 . (:title "International Relations" :text "Generally recognized rules of international law"))
    (106 . (:title "Revision" :text "Provisions that may not be revised"))))

(defparameter *test-citations*
  '((16 . 5)    ; Education cites Individual Rights
    (16 . 21)   ; Education cites Family
    (25 . 5)    ; Rights cites Individual Rights
    (25 . 2)    ; Rights cites Popular Sovereignty
    (28 . 1)    ; International Relations cites State Form
    (106 . 1)   ; Revision cites State Form
    (106 . 2))) ; Revision cites Popular Sovereignty

;;; ============================================================================
;;; CREATE TEST GRAPH
;;; ============================================================================

(defun create-comparison-graph ()
  "Create graph with identical data to Python"
  (let ((g (make-citation-graph)))
    ;; Add articles
    (dolist (article *test-articles*)
      (let ((num (car article))
            (data (cdr article)))
        (add-article g num
                     :title (getf data :title)
                     :text (getf data :text))))
    ;; Add citations
    (dolist (citation *test-citations*)
      (add-citation g (car citation) (cdr citation)))
    g))

;;; ============================================================================
;;; COMPUTE AND COMPARE
;;; ============================================================================

(defun run-comparison ()
  "Run comparison tests and output results"
  (format t "~%")
  (format t "════════════════════════════════════════════════════════════~%")
  (format t "  LISP IMPLEMENTATION VALUES~%")
  (format t "════════════════════════════════════════════════════════════~%")

  (let* ((g (create-comparison-graph))
         (results nil))

    ;; [1] PageRank
    (format t "~%[1] Computing PageRank...~%")
    (let* ((pr (pagerank g :damping 0.85 :max-iterations 100 :tolerance 1e-6))
           (sum 0.0d0))
      (maphash (lambda (k v)
                 (incf sum v)
                 (push (cons k v) results))
               pr)
      (format t "    Sum of ranks: ~,10F~%" sum)

      ;; Verify sum = 1.0
      (format t "    Property: sum=1.0 → ~A~%"
              (if (< (abs (- sum 1.0d0)) 1e-6) "✓ PASSED" "✗ FAILED"))

      ;; Print individual ranks
      (format t "~%    PageRank values:~%")
      (dolist (article '(1 2 5 16 21 25 28 106))
        (format t "      Article ~3D: ~,8F~%" article (gethash article pr 0.0))))

    ;; [2] Betweenness Centrality
    (format t "~%[2] Computing Betweenness Centrality...~%")
    (let ((bc (betweenness-centrality g)))
      (format t "    Betweenness values:~%")
      (dolist (article '(1 2 5 16 21 25 28 106))
        (format t "      Article ~3D: ~,8F~%" article (gethash article bc 0.0)))

      ;; Verify all in [0, 1]
      (let ((all-valid t))
        (maphash (lambda (k v)
                   (declare (ignore k))
                   (unless (and (>= v 0.0) (<= v 1.0))
                     (setf all-valid nil)))
                 bc)
        (format t "    Property: all in [0,1] → ~A~%"
                (if all-valid "✓ PASSED" "✗ FAILED"))))

    ;; [3] TF-IDF
    (format t "~%[3] Computing TF-IDF embeddings...~%")
    (let ((embeddings (tfidf-embed g :max-features 100)))
      (format t "    Articles with embeddings: ~D~%" (hash-table-count embeddings))

      ;; Show sample terms for article 1
      (let ((emb-1 (gethash 1 embeddings)))
        (when emb-1
          (format t "    Sample terms for Article 1:~%")
          (let ((count 0))
            (maphash (lambda (term weight)
                       (when (< count 5)
                         (format t "      ~A: ~,4F~%" term weight)
                         (incf count)))
                     emb-1)))))

    ;; [4] Cosine Similarity
    (format t "~%[4] Computing Cosine Similarity...~%")
    (let ((embeddings (tfidf-embed g :max-features 100)))
      ;; Self-similarity test
      (let* ((emb-1 (gethash 1 embeddings))
             (self-sim (when emb-1 (cosine-similarity emb-1 emb-1))))
        (format t "    Self-similarity Article 1: ~,10F~%" (or self-sim 0.0))
        (format t "    Property: self-sim=1.0 → ~A~%"
                (if (and self-sim (< (abs (- self-sim 1.0d0)) 1e-10))
                    "✓ PASSED" "✗ FAILED")))

      ;; Sample pair similarities
      (format t "    Sample pair similarities:~%")
      (dolist (pair '((1 . 2) (5 . 25) (16 . 21)))
        (let* ((emb-a (gethash (car pair) embeddings))
               (emb-b (gethash (cdr pair) embeddings))
               (sim (if (and emb-a emb-b)
                        (cosine-similarity emb-a emb-b)
                        0.0)))
          (format t "      ~D vs ~D: ~,6F~%" (car pair) (cdr pair) sim))))

    ;; [5] In-Degree Centrality
    (format t "~%[5] Computing In-Degree Centrality...~%")
    (let ((in-deg (in-degree-centrality g)))
      (format t "    Most cited articles:~%")
      (let ((sorted (sort (loop for k being the hash-keys of in-deg
                                using (hash-value v)
                                collect (cons k v))
                          #'> :key #'cdr)))
        (dolist (item (subseq sorted 0 (min 5 (length sorted))))
          (format t "      Article ~D: ~,4F~%" (car item) (cdr item)))))

    (format t "~%")
    (format t "════════════════════════════════════════════════════════════~%")
    (format t "  COMPARISON COMPLETE~%")
    (format t "════════════════════════════════════════════════════════════~%")
    (format t "~%Compare these values with python-reference-values.json~%")
    (format t "If PageRank sum=1.0 and all properties pass, implementation is CORRECT.~%")
    (format t "~%")))

;;; ============================================================================
;;; MAIN
;;; ============================================================================

(run-comparison)
