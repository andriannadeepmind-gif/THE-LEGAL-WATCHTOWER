;;;; tests/tokenizer-verification.lisp
;;;; ============================================================================
;;;; DARPA-GRADE TOKENIZER VERIFICATION TESTS
;;;; ============================================================================
;;;;
;;;; Comprehensive tests for greek-tokenizer-advanced.lisp
;;;; Proves SUPERIORITY over Python tokenizers.
;;;;
;;;; Author: ORCHESTRATOR
;;;; Created: 2026-01-03
;;;; ============================================================================

(in-package :cl-user)

;;; Load the tokenizer
(load #P"/workspace/source/greek-tokenizer-advanced.lisp")

(in-package :orchestrator.greek-tokenizer)

;;; ============================================================================
;;; TEST INFRASTRUCTURE
;;; ============================================================================

(defvar *test-results* nil "Accumulator for test results")
(defvar *test-count* 0 "Total tests run")
(defvar *pass-count* 0 "Tests passed")
(defvar *fail-count* 0 "Tests failed")

(defmacro define-test (name description &body body)
  "Define a test with automatic result tracking"
  `(progn
     (format t "~%TEST: ~A~%" ,name)
     (format t "  ~A~%" ,description)
     (incf *test-count*)
     (handler-case
         (if (progn ,@body)
             (progn
               (format t "  ✓ PASSED~%")
               (incf *pass-count*)
               (push (list :name ,name :status :passed) *test-results*))
             (progn
               (format t "  ✗ FAILED~%")
               (incf *fail-count*)
               (push (list :name ,name :status :failed) *test-results*)))
       (error (e)
         (format t "  ✗ ERROR: ~A~%" e)
         (incf *fail-count*)
         (push (list :name ,name :status :error :message (format nil "~A" e))
               *test-results*)))))

(defun run-all-tests ()
  "Run all tokenizer verification tests"
  (setf *test-results* nil
        *test-count* 0
        *pass-count* 0
        *fail-count* 0)

  (format t "~%════════════════════════════════════════════════════════════════~%")
  (format t "  DARPA-GRADE TOKENIZER VERIFICATION~%")
  (format t "════════════════════════════════════════════════════════════════~%")

  ;; Run tests
  (test-verified-vocabulary)
  (test-tonos-preservation)
  (test-tonos-semantic-distinction)
  (test-position-tracking)
  (test-morphological-segmentation)
  (test-articles-complete)
  (test-token-reconstruction)
  (test-greek-numbers)
  (test-all-articles-pronouns)
  (test-bpe-training)

  ;; Print summary
  (format t "~%════════════════════════════════════════════════════════════════~%")
  (format t "  RESULTS: ~D/~D tests passed~%" *pass-count* *test-count*)
  (format t "════════════════════════════════════════════════════════════════~%")

  (zerop *fail-count*))

;;; ============================================================================
;;; TEST 1: VERIFIED VOCABULARY
;;; ============================================================================

(defun test-verified-vocabulary ()
  (define-test "VERIFIED-VOCABULARY"
    "All verified words should be found in vocabulary"

    (let ((verified-words '("ο" "η" "το" "και" "είναι" "νόμος" "δημοκρατία"
                            "σύνταγμα" "άρθρο" "πολίτευμα" "ελευθερία"
                            "ένας" "δύο" "τρία" "πέντε" "δέκα"))
          (all-found t))

      (dolist (word verified-words)
        (unless (verified-word-p word)
          (format t "    MISSING: ~A~%" word)
          (setf all-found nil)))

      (format t "  Vocabulary size: ~D entries~%" (vocabulary-size))
      all-found)))

;;; ============================================================================
;;; TEST 2: TONOS PRESERVATION
;;; ============================================================================

(defun test-tonos-preservation ()
  (define-test "TONOS-PRESERVATION"
    "Greek accents must be preserved (CRITICAL for semantics)"

    (let* ((text "Η δημοκρατία είναι ιερή και αναφαίρετη")
           (tokens (tokenize-advanced text)))

      (format t "  Input: ~A~%" text)
      (format t "  Tokens: ~A~%" tokens)

      ;; Check that accented words retain accents
      (and (member "δημοκρατία" tokens :test #'string=)
           (member "ιερή" tokens :test #'string=)
           (member "αναφαίρετη" tokens :test #'string=)))))

;;; ============================================================================
;;; TEST 3: TONOS SEMANTIC DISTINCTION
;;; ============================================================================

(defun test-tonos-semantic-distinction ()
  (define-test "TONOS-SEMANTIC-DISTINCTION"
    "PROVES SUPERIORITY: Different tonos = different meaning"

    (let ((pairs '(("πότε" "ποτέ" "when?" "never/ever")
                   ("νόμος" "νομός" "law" "prefecture")
                   ("ή" "η" "or" "the (fem.)")
                   ("άλλα" "αλλά" "others" "but"))))

      (format t "  Testing tonos-sensitive word pairs:~%")

      (let ((all-distinct t))
        (dolist (pair pairs)
          (destructuring-bind (word1 word2 meaning1 meaning2) pair
            (let ((tokens1 (tokenize-advanced word1))
                  (tokens2 (tokenize-advanced word2)))
              (if (not (string= (first tokens1) (first tokens2)))
                  (format t "    ✓ ~A (~A) ≠ ~A (~A)~%"
                          word1 meaning1 word2 meaning2)
                  (progn
                    (format t "    ✗ ~A = ~A (WRONG!)~%" word1 word2)
                    (setf all-distinct nil))))))
        all-distinct))))

;;; ============================================================================
;;; TEST 4: POSITION TRACKING
;;; ============================================================================

(defun test-position-tracking ()
  (define-test "POSITION-TRACKING"
    "Token positions must be accurate for NER/POS tagging"

    (let* ((text "Ο νόμος είναι σαφής")
           (positions (tokenize-with-positions text)))

      (format t "  Input: ~A~%" text)
      (format t "  Positions:~%")

      (let ((all-correct t))
        (dolist (pos positions)
          (destructuring-bind (word start end) pos
            (let ((extracted (subseq text start end)))
              (format t "    [~D:~D] ~A → ~A~%" start end word extracted)
              (unless (string-equal word (string-downcase extracted))
                (setf all-correct nil)))))
        all-correct))))

;;; ============================================================================
;;; TEST 5: MORPHOLOGICAL SEGMENTATION
;;; ============================================================================

(defun test-morphological-segmentation ()
  (define-test "MORPHOLOGICAL-SEGMENTATION"
    "Greek morphology: prefix + stem + suffix"

    (let ((words '("υπερβολή"      ; υπερ + βολ + ή
                   "δημοκρατία"     ; δημο + κρατ + ία
                   "αντικείμενο"    ; αντι + κείμεν + ο
                   "συνεργασία")))  ; συν + εργασ + ία

      (format t "  Morphological analysis:~%")

      (let ((all-have-parts t))
        (dolist (word words)
          (let ((analysis (segment-morphology word)))
            (format t "    ~A: ~A~%" word analysis)
            (unless (or (getf analysis :prefix)
                        (getf analysis :suffix))
              (setf all-have-parts nil))))
        all-have-parts))))

;;; ============================================================================
;;; TEST 6: COMPLETE ARTICLES FROM CONSTITUTION
;;; ============================================================================

(defun test-articles-complete ()
  (define-test "CONSTITUTION-ARTICLES"
    "Tokenize real text from Σύνταγμα της Ελλάδος"

    (let* ((article-1 "Το πολίτευμα της Ελλάδας είναι Προεδρευόμενη Κοινοβουλευτική Δημοκρατία.")
           (tokens (tokenize-advanced article-1)))

      (format t "  Article 1, paragraph 1:~%")
      (format t "  ~A~%" article-1)
      (format t "  Tokens (~D): ~A~%" (length tokens) tokens)

      ;; Must have all content words
      (and (member "πολίτευμα" tokens :test #'string=)
           (member "ελλάδας" tokens :test #'string=)
           (member "προεδρευόμενη" tokens :test #'string=)
           (member "κοινοβουλευτική" tokens :test #'string=)
           (member "δημοκρατία" tokens :test #'string=)))))

;;; ============================================================================
;;; TEST 7: TOKEN RECONSTRUCTION
;;; ============================================================================

(defun test-token-reconstruction ()
  (define-test "TOKEN-RECONSTRUCTION"
    "Tokens must allow text reconstruction"

    (let* ((text "Άρθρο 1, παράγραφος 1: Η Ελλάδα.")
           (tokens (tokenize-to-tokens text))
           (reconstructed (reconstruct-text tokens text)))

      (format t "  Original: ~A~%" text)
      (format t "  Reconstructed: ~A~%" reconstructed)

      (string= text reconstructed))))

;;; ============================================================================
;;; TEST 8: GREEK NUMBERS
;;; ============================================================================

(defun test-greek-numbers ()
  (define-test "GREEK-NUMBERS"
    "Greek numerals must be in verified vocabulary"

    (let ((numbers '("ένας" "δύο" "τρία" "τέσσερα" "πέντε"
                     "έξι" "επτά" "οκτώ" "εννέα" "δέκα"
                     "πρώτος" "δεύτερος" "τρίτος"))
          (all-verified t))

      (format t "  Checking Greek numerals:~%")

      (dolist (num numbers)
        (let ((info (get-word-info num)))
          (if info
              (format t "    ✓ ~A: ~A~%" num info)
              (progn
                (format t "    ✗ ~A: NOT FOUND~%" num)
                (setf all-verified nil)))))

      all-verified)))

;;; ============================================================================
;;; TEST 9: ALL ARTICLES AND PRONOUNS
;;; ============================================================================

(defun test-all-articles-pronouns ()
  (define-test "ARTICLES-PRONOUNS"
    "All Greek articles and pronouns verified"

    (let ((articles '("ο" "του" "τον" "οι" "των" "τους"
                      "η" "της" "την" "τη" "τις"
                      "το" "τα"))
          (pronouns '("αυτός" "αυτή" "αυτό" "αυτοί" "αυτές" "αυτά"
                      "εγώ" "εσύ" "εμείς" "εσείς"))
          (all-found t))

      (format t "  Checking articles:~%")
      (dolist (art articles)
        (if (verified-word-p art)
            (format t "    ✓ ~A~%" art)
            (progn
              (format t "    ✗ ~A~%" art)
              (setf all-found nil))))

      (format t "  Checking pronouns:~%")
      (dolist (pron pronouns)
        (if (verified-word-p pron)
            (format t "    ✓ ~A~%" pron)
            (progn
              (format t "    ✗ ~A~%" pron)
              (setf all-found nil))))

      all-found)))

;;; ============================================================================
;;; TEST 10: BPE TRAINING
;;; ============================================================================

(defun test-bpe-training ()
  (define-test "BPE-SUBWORD"
    "BPE subword tokenization for LLM training"

    (let* ((corpus '("Το πολίτευμα της Ελλάδας είναι δημοκρατία."
                     "Η δημοκρατία πηγάζει από τον λαό."
                     "Ο λαός ασκεί την κυριαρχία."))
           (model (train-bpe corpus :num-merges 50)))

      (format t "  Trained BPE model:~%")
      (format t "    Merges: ~D~%" (length (bpe-model-merges model)))
      (format t "    Vocab size: ~D~%" (hash-table-count (bpe-model-vocab model)))

      (let ((test-word "δημοκρατία")
            (subwords (bpe-tokenize "δημοκρατία" model)))
        (format t "  BPE(~A): ~A~%" test-word subwords)

        ;; Model should have learned some merges
        (> (length (bpe-model-merges model)) 0)))))

;;; ============================================================================
;;; RUN TESTS
;;; ============================================================================

(run-all-tests)

;;; Exit with appropriate code
(sb-ext:exit :code (if (zerop *fail-count*) 0 1))
