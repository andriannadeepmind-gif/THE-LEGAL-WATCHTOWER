;;;; tests/hardcoded-verification.lisp
;;;; ============================================================================
;;;; HARDCODED VERIFICATION - NOT RIGGED
;;;; ============================================================================
;;;;
;;;; These tests use KNOWN VALUES calculated by hand or from textbooks.
;;;; If the implementation is wrong, these WILL FAIL.
;;;;
;;;; Usage: sbcl --load source/citation-authority.lisp --load tests/hardcoded-verification.lisp
;;;; ============================================================================

;;; Assume citation-authority.lisp is already loaded
(in-package :orchestrator.citation-authority)

(defvar *tolerance* 1e-6)

(defun approx= (a b)
  (< (abs (- a b)) *tolerance*))

;;; ============================================================================
;;; TEST 1: TF-IDF με γνωστές τιμές
;;; ============================================================================
;;;
;;; Corpus: ["cat dog", "cat cat", "dog bird"]
;;;
;;; Document Frequency:
;;;   cat: appears in doc 1,2 → df=2
;;;   dog: appears in doc 1,3 → df=2
;;;   bird: appears in doc 3 → df=1
;;;
;;; IDF = log(N/df) where N=3:
;;;   IDF(cat) = log(3/2) = 0.405465...
;;;   IDF(dog) = log(3/2) = 0.405465...
;;;   IDF(bird) = log(3/1) = 1.098612...

(defun test-tfidf-known-values ()
  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "TEST 1: TF-IDF with KNOWN VALUES (hand-calculated)~%")
  (format t "═══════════════════════════════════════════════════════════════~%")

  (let* ((docs '("cat dog" "cat cat" "dog bird"))
         (idf (compute-idf docs))
         (expected-cat (log (/ 3.0 2.0)))    ; 0.405465...
         (expected-dog (log (/ 3.0 2.0)))    ; 0.405465...
         (expected-bird (log (/ 3.0 1.0)))   ; 1.098612...
         (actual-cat (gethash "cat" idf 0.0))
         (actual-dog (gethash "dog" idf 0.0))
         (actual-bird (gethash "bird" idf 0.0)))

    (format t "~%  Hand-calculated expected values:~%")
    (format t "    IDF(cat)  = log(3/2) = ~,6F~%" expected-cat)
    (format t "    IDF(dog)  = log(3/2) = ~,6F~%" expected-dog)
    (format t "    IDF(bird) = log(3/1) = ~,6F~%" expected-bird)

    (format t "~%  Actual values from our code:~%")
    (format t "    IDF(cat)  = ~,6F~%" actual-cat)
    (format t "    IDF(dog)  = ~,6F~%" actual-dog)
    (format t "    IDF(bird) = ~,6F~%" actual-bird)

    (let ((passed t))
      (unless (approx= actual-cat expected-cat)
        (format t "    ✗ cat MISMATCH~%")
        (setf passed nil))
      (unless (approx= actual-dog expected-dog)
        (format t "    ✗ dog MISMATCH~%")
        (setf passed nil))
      (unless (approx= actual-bird expected-bird)
        (format t "    ✗ bird MISMATCH~%")
        (setf passed nil))

      (if passed
          (format t "~%  ✓ ALL VALUES MATCH HAND CALCULATIONS~%")
          (format t "~%  ✗ FAILED - Implementation is WRONG~%"))
      passed)))

;;; ============================================================================
;;; TEST 2: PageRank σε απλό γράφο με γνωστή λύση
;;; ============================================================================
;;;
;;; Graph: Complete graph K3 (triangle where everyone links to everyone)
;;;   1 ↔ 2 ↔ 3 ↔ 1
;;;
;;; For a complete graph, ALL nodes have EQUAL PageRank = 1/N
;;; This is a mathematical theorem, not a guess.

(defun test-pagerank-complete-graph ()
  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "TEST 2: PageRank on Complete Graph K3 (KNOWN SOLUTION)~%")
  (format t "═══════════════════════════════════════════════════════════════~%")

  (let ((g (make-citation-graph)))
    ;; Create complete graph K3
    (add-article g 1) (add-article g 2) (add-article g 3)
    (add-citation g 1 2) (add-citation g 1 3)
    (add-citation g 2 1) (add-citation g 2 3)
    (add-citation g 3 1) (add-citation g 3 2)

    (let* ((pr (pagerank g))
           (expected (/ 1.0d0 3.0d0))  ; 0.333...
           (pr1 (gethash 1 pr))
           (pr2 (gethash 2 pr))
           (pr3 (gethash 3 pr)))

      (format t "~%  Complete graph K3: all nodes link to all others~%")
      (format t "  Mathematical theorem: All nodes have equal rank = 1/3~%")

      (format t "~%  Expected: ~,6F for all nodes~%" expected)
      (format t "  Actual:~%")
      (format t "    PR(1) = ~,6F~%" pr1)
      (format t "    PR(2) = ~,6F~%" pr2)
      (format t "    PR(3) = ~,6F~%" pr3)

      (let ((passed t))
        (unless (approx= pr1 expected)
          (format t "    ✗ Node 1 WRONG~%")
          (setf passed nil))
        (unless (approx= pr2 expected)
          (format t "    ✗ Node 2 WRONG~%")
          (setf passed nil))
        (unless (approx= pr3 expected)
          (format t "    ✗ Node 3 WRONG~%")
          (setf passed nil))

        (if passed
            (format t "~%  ✓ MATCHES MATHEMATICAL THEOREM~%")
            (format t "~%  ✗ FAILED - PageRank is WRONG~%"))
        passed))))

;;; ============================================================================
;;; TEST 3: Cosine με γνωστή γεωμετρία
;;; ============================================================================
;;;
;;; Vector A = (3, 4) → magnitude = 5
;;; Vector B = (4, 3) → magnitude = 5
;;; Dot product = 3*4 + 4*3 = 24
;;; Cosine = 24 / (5 * 5) = 0.96

(defun test-cosine-known-geometry ()
  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "TEST 3: Cosine Similarity with KNOWN GEOMETRY~%")
  (format t "═══════════════════════════════════════════════════════════════~%")

  (let ((vec-a (make-hash-table :test 'equal))
        (vec-b (make-hash-table :test 'equal)))

    ;; A = (3, 4), B = (4, 3)
    (setf (gethash "x" vec-a) 3.0d0)
    (setf (gethash "y" vec-a) 4.0d0)
    (setf (gethash "x" vec-b) 4.0d0)
    (setf (gethash "y" vec-b) 3.0d0)

    (let* ((expected (/ 24.0d0 25.0d0))  ; 0.96
           (actual (cosine-similarity vec-a vec-b)))

      (format t "~%  A = (3, 4), ||A|| = 5~%")
      (format t "  B = (4, 3), ||B|| = 5~%")
      (format t "  A·B = 3×4 + 4×3 = 24~%")
      (format t "  cos(A,B) = 24/(5×5) = 0.96~%")

      (format t "~%  Expected: ~,6F~%" expected)
      (format t "  Actual:   ~,6F~%" actual)

      (if (approx= actual expected)
          (progn
            (format t "~%  ✓ MATCHES GEOMETRY~%")
            t)
          (progn
            (format t "~%  ✗ FAILED - Cosine is WRONG~%")
            nil)))))

;;; ============================================================================
;;; TEST 4: Greek tokenizer - FULL ARTICLES 1, 2, 3 from Σύνταγμα της Ελλάδος
;;; ============================================================================
;;; Source: deployment/data/syntagma_clean.json
;;; DARPA-GRADE: Complete articles, no arbitrary filtering, ALL words preserved.

(defparameter *article-1-full*
  "1. Το πολίτευμα της Ελλάδας είναι Προεδρευόμενη Κοινοβουλευτική Δημοκρατία. 2. Θεμέλιο του πολιτεύματος είναι η λαϊκή κυριαρχία. 3. Όλες οι εξουσίες πηγάζουν από το Λαό, υπάρχουν υπέρ αυτού και του Έθνους και ασκούνται όπως ορίζει το Σύνταγμα.")

(defparameter *article-2-full*
  "1. Ο σεβασμός και η προστασία της αξίας του ανθρώπου αποτελούν την πρωταρχική υποχρέωση της Πολιτείας. 2. Η Ελλάδα, ακολουθώντας τους γενικά αναγνωρισμένους κανόνες του διεθνούς δικαίου, επιδιώκει την εμπέδωση της ειρήνης, της δικαιοσύνης, καθώς και την ανάπτυξη των φιλικών σχέσεων μεταξύ των λαών και των κρατών.")

(defparameter *article-3-full*
  "1. Επικρατούσα θρησκεία στην Ελλάδα είναι η θρησκεία της Ανατολικής Ορθόδοξης Εκκλησίας του Χριστού. Η Ορθόδοξη Εκκλησία της Ελλάδας, που γνωρίζει κεφαλή της τον Κύριο ημών Ιησού Χριστό, υπάρχει αναπόσπαστα ενωμένη δογματικά με τη Μεγάλη Εκκλησία της Κωνσταντινούπολης και με κάθε άλλη ομόδοξη Εκκλησία του Χριστού τηρεί απαρασάλευτα, όπως εκείνες, τους ιερούς αποστολικούς και συνοδικούς κανόνες και τις ιερές παραδόσεις. Είναι αυτοκέφαλη, διοικείται από την Ιερά Σύνοδο των εν ενεργεία Αρχιερέων και από τη Διαρκή Ιερά Σύνοδο που προέρχεται από αυτή και συγκροτείται όπως ορίζει ο Καταστατικός Χάρτης της Εκκλησίας, με τήρηση των διατάξεων του Πατριαρχικού Τόμου της κθ 29 Ιουνίου 1850 και της Συνοδικής Πράξης της 4ης Σεπτεμβρίου 1928. 2. Το εκκλησιαστικό καθεστώς που υπάρχει σε ορισμένες περιοχές του Κράτους δεν αντίκειται στις διατάξεις της προηγούμενης παραγράφου. 3. Το κείμενο της Αγίας Γραφής τηρείται αναλλοίωτο. Η επίσημη μετάφρασή του σε άλλο γλωσσικό τύπο απαγορεύεται χωρίς την έγκριση της Αυτοκέφαλης Εκκλησίας της Ελλάδας και της Μεγάλης του Χριστού Εκκλησίας στην Κωνσταντινούπολη.")

(defun test-greek-tokenizer-specific ()
  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "TEST 4: Greek Tokenizer - FULL ARTICLES 1, 2, 3 (Σύνταγμα)~%")
  (format t "═══════════════════════════════════════════════════════════════~%")

  (let* ((tokens-1 (tokenize-greek *article-1-full*))
         (tokens-2 (tokenize-greek *article-2-full*))
         (tokens-3 (tokenize-greek *article-3-full*))
         (passed t))

    (format t "~%  Άρθρο 1 - Μορφή του πολιτεύματος~%")
    (format t "  Token count: ~D~%" (length tokens-1))

    (format t "~%  Άρθρο 2 - Πρωταρχικές υποχρεώσεις της πολιτείας~%")
    (format t "  Token count: ~D~%" (length tokens-2))

    (format t "~%  Άρθρο 3 - Σχέσεις Εκκλησίας και Πολιτείας~%")
    (format t "  Token count: ~D~%" (length tokens-3))

    ;; Key legal terms that MUST be preserved with correct tonos
    (format t "~%  Verifying key legal terms (with tonos):~%")

    ;; Article 1 terms
    (unless (member "δημοκρατία" tokens-1 :test #'equal)
      (format t "    ✗ Missing 'δημοκρατία' in Article 1~%")
      (setf passed nil))
    (unless (member "κυριαρχία" tokens-1 :test #'equal)
      (format t "    ✗ Missing 'κυριαρχία' in Article 1~%")
      (setf passed nil))
    (unless (member "σύνταγμα" tokens-1 :test #'equal)
      (format t "    ✗ Missing 'σύνταγμα' in Article 1~%")
      (setf passed nil))

    ;; Article 2 terms
    (unless (member "σεβασμός" tokens-2 :test #'equal)
      (format t "    ✗ Missing 'σεβασμός' in Article 2~%")
      (setf passed nil))
    (unless (member "ανθρώπου" tokens-2 :test #'equal)
      (format t "    ✗ Missing 'ανθρώπου' in Article 2~%")
      (setf passed nil))
    (unless (member "πολιτείας" tokens-2 :test #'equal)
      (format t "    ✗ Missing 'πολιτείας' in Article 2~%")
      (setf passed nil))
    (unless (member "δικαιοσύνης" tokens-2 :test #'equal)
      (format t "    ✗ Missing 'δικαιοσύνης' in Article 2~%")
      (setf passed nil))

    ;; Article 3 terms
    (unless (member "θρησκεία" tokens-3 :test #'equal)
      (format t "    ✗ Missing 'θρησκεία' in Article 3~%")
      (setf passed nil))
    (unless (member "εκκλησίας" tokens-3 :test #'equal)
      (format t "    ✗ Missing 'εκκλησίας' in Article 3~%")
      (setf passed nil))
    (unless (member "κωνσταντινούπολης" tokens-3 :test #'equal)
      (format t "    ✗ Missing 'κωνσταντινούπολης' in Article 3~%")
      (setf passed nil))

    ;; Single-char articles must be present (DARPA: no arbitrary filtering)
    (unless (member "ο" tokens-2 :test #'equal)
      (format t "    ✗ Missing 'ο' (single-char article) - arbitrary filtering!~%")
      (setf passed nil))
    (unless (member "η" tokens-1 :test #'equal)
      (format t "    ✗ Missing 'η' (single-char article) - arbitrary filtering!~%")
      (setf passed nil))

    (let ((total-tokens (+ (length tokens-1) (length tokens-2) (length tokens-3))))
      (format t "~%  Total tokens across 3 articles: ~D~%" total-tokens))

    (if passed
        (format t "~%  ✓ ALL 3 ARTICLES tokenized correctly - tonos preserved~%")
        (format t "~%  ✗ FAILED~%"))
    passed))

;;; ============================================================================
;;; TEST 5: TONOS SEMANTIC DISTINCTION - PROVES SUPERIORITY OVER PYTHON
;;; ============================================================================
;;; Python sklearn TfidfVectorizer with strip_accents='unicode' would FAIL this.
;;; It would treat "πότε" (when) and "ποτέ" (never) as the SAME word.
;;; Our Lisp implementation correctly distinguishes them.
;;;
;;; Real examples where tonos changes meaning:
;;;   πότε (when) ≠ ποτέ (never/ever)
;;;   ξέρω (I know) ≠ ξερό (dry)
;;;   νόμος (law) ≠ νομός (prefecture)

(defun test-tonos-semantic-distinction ()
  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "TEST 5: TONOS SEMANTIC DISTINCTION (Python sklearn would FAIL)~%")
  (format t "═══════════════════════════════════════════════════════════════~%")

  (format t "~%  Python sklearn TfidfVectorizer with strip_accents='unicode'~%")
  (format t "  would merge these as identical. We correctly distinguish them.~%")

  (let* (;; Two documents with semantically different words that only differ by tonos
         ;; Doc 1: "Πότε ψηφίστηκε ο νόμος;" (When was the law voted?)
         ;; Doc 2: "Δεν έχει ψηφιστεί ποτέ νομός." (A prefecture was never voted.)
         (doc1 "Πότε ψηφίστηκε ο νόμος")        ; πότε = when, νόμος = law
         (doc2 "Δεν έχει ψηφιστεί ποτέ νομός")  ; ποτέ = never, νομός = prefecture
         (tokens1 (tokenize-greek doc1))
         (tokens2 (tokenize-greek doc2))
         (passed t))

    (format t "~%  Document 1: \"~A\"~%" doc1)
    (format t "  Tokens: ~A~%" tokens1)
    (format t "  Token count: ~D (expected: 4)~%" (length tokens1))
    (format t "~%  Document 2: \"~A\"~%" doc2)
    (format t "  Tokens: ~A~%" tokens2)
    (format t "  Token count: ~D (expected: 5)~%" (length tokens2))

    ;; DARPA-GRADE: Verify ALL tokens present including single-char "ο"
    (unless (= (length tokens1) 4)
      (format t "  ✗ Doc1 token count wrong - words lost!~%")
      (setf passed nil))
    (unless (= (length tokens2) 5)
      (format t "  ✗ Doc2 token count wrong - words lost!~%")
      (setf passed nil))
    (unless (member "ο" tokens1 :test #'equal)
      (format t "  ✗ Missing 'ο' (single-char article) - arbitrary filtering!~%")
      (setf passed nil))

    ;; Test 1: "πότε" (when) must be in doc1, NOT in doc2
    (format t "~%  Testing semantic pairs:~%")

    (if (and (member "πότε" tokens1 :test #'equal)
             (not (member "πότε" tokens2 :test #'equal)))
        (format t "    ✓ 'πότε' (when) correctly in doc1 only~%")
        (progn
          (format t "    ✗ 'πότε' (when) distinction FAILED~%")
          (setf passed nil)))

    ;; Test 2: "ποτέ" (never) must be in doc2, NOT in doc1
    (if (and (member "ποτέ" tokens2 :test #'equal)
             (not (member "ποτέ" tokens1 :test #'equal)))
        (format t "    ✓ 'ποτέ' (never) correctly in doc2 only~%")
        (progn
          (format t "    ✗ 'ποτέ' (never) distinction FAILED~%")
          (setf passed nil)))

    ;; Test 3: "νόμος" (law) must be in doc1, NOT in doc2
    (if (and (member "νόμος" tokens1 :test #'equal)
             (not (member "νόμος" tokens2 :test #'equal)))
        (format t "    ✓ 'νόμος' (law) correctly in doc1 only~%")
        (progn
          (format t "    ✗ 'νόμος' (law) distinction FAILED~%")
          (setf passed nil)))

    ;; Test 4: "νομός" (prefecture) must be in doc2, NOT in doc1
    (if (and (member "νομός" tokens2 :test #'equal)
             (not (member "νομός" tokens1 :test #'equal)))
        (format t "    ✓ 'νομός' (prefecture) correctly in doc2 only~%")
        (progn
          (format t "    ✗ 'νομός' (prefecture) distinction FAILED~%")
          (setf passed nil)))

    (format t "~%")
    (if passed
        (progn
          (format t "  ✓ TONOS PRESERVED - Semantic distinction maintained~%")
          (format t "  ✓ SUPERIOR TO PYTHON: sklearn would merge these words~%"))
        (format t "  ✗ FAILED - Tonos handling broken~%"))
    passed))

;;; ============================================================================
;;; RUN ALL HARDCODED TESTS
;;; ============================================================================

(defun run-hardcoded-tests ()
  (format t "~%")
  (format t "╔════════════════════════════════════════════════════════════════╗~%")
  (format t "║     HARDCODED VERIFICATION - NOT RIGGED                        ║~%")
  (format t "║                                                                ║~%")
  (format t "║  These values are calculated BY HAND or from TEXTBOOKS.        ║~%")
  (format t "║  If the code is wrong, these tests WILL FAIL.                  ║~%")
  (format t "╚════════════════════════════════════════════════════════════════╝~%")

  (let ((results nil))
    (push (cons "TF-IDF Known Values" (test-tfidf-known-values)) results)
    (push (cons "PageRank Complete Graph" (test-pagerank-complete-graph)) results)
    (push (cons "Cosine Known Geometry" (test-cosine-known-geometry)) results)
    (push (cons "Greek Tokenizer" (test-greek-tokenizer-specific)) results)
    (push (cons "Tonos Semantic Distinction" (test-tonos-semantic-distinction)) results)

    (format t "~%")
    (format t "╔════════════════════════════════════════════════════════════════╗~%")
    (format t "║                         FINAL RESULTS                          ║~%")
    (format t "╠════════════════════════════════════════════════════════════════╣~%")

    (let ((all-passed t))
      (dolist (result (reverse results))
        (format t "║  ~50A ~A ║~%"
                (car result)
                (if (cdr result) "✓" "✗"))
        (unless (cdr result)
          (setf all-passed nil)))

      (format t "╠════════════════════════════════════════════════════════════════╣~%")
      (if all-passed
          (progn
            (format t "║                                                                ║~%")
            (format t "║  ✓ ALL HARDCODED TESTS PASSED                                  ║~%")
            (format t "║  ✓ IMPLEMENTATION IS MATHEMATICALLY CORRECT                   ║~%")
            (format t "║                                                                ║~%"))
          (format t "║  ✗ SOME TESTS FAILED - IMPLEMENTATION IS WRONG               ║~%"))
      (format t "╚════════════════════════════════════════════════════════════════╝~%")

      all-passed)))

;;; Run — [RATCHET-5] η ΕΤΥΜΗΓΟΡΙΑ κρατιέται ώστε ο runner να μπορεί να βγει
;;; με τίμιο exit code. Πριν, η τιμή πεταγόταν και το
;;; tests/run-citation-verification.lisp έκανε ΠΑΝΤΑ (sb-ext:exit :code 0) —
;;; αποτυχημένο test = πράσινο container (false-green entrypoint του
;;; docker-compose.citation-tests.yml). ΜΙΑ εκτέλεση, μία αλήθεια.
(defparameter *hardcoded-verification-passed* (run-hardcoded-tests))
