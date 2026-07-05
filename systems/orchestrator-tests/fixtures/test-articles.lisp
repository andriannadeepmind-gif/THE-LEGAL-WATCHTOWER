;;;; systems/orchestrator-tests/fixtures/test-articles.lisp
;;;; Test article fixtures

(in-package :orchestrator-tests)

(defparameter *test-article-1*
  (orchestrator.model:make-article
   :number 1
   :title "Άρθρο 1 - Πολίτευμα"
   :content "Το πολίτευμα της Ελλάδας είναι Προεδρευόμενη Κοινοβουλευτική Δημοκρατία."))

(defparameter *test-article-2*
  (orchestrator.model:make-article
   :number 2
   :title "Άρθρο 2 - Θρησκεία"
   :content "Επικρατούσα θρησκεία στην Ελλάδα είναι η θρησκεία της Ανατολικής Ορθόδοξης Εκκλησίας του Χριστού."))

(defparameter *test-corpus*
  (orchestrator.model:make-corpus
   :name "Test Corpus"
   :short-name "test"
   :eli-prefix "http://test.example.com/eli"))
