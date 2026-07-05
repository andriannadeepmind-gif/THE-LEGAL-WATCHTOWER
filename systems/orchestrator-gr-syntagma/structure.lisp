;;;; systems/orchestrator-gr-syntagma/structure.lisp
;;;; Greek Constitution structure (120 articles)

(in-package :orchestrator.gr-syntagma)

(defparameter *constitution-articles* 120
  "Total number of articles in Greek Constitution")

(defun valid-article-number-p (number)
  "Check if article number is valid
  
  Args:
    number: Article number
  
  Returns:
    T if valid, NIL otherwise"
  (and (integerp number)
       (>= number 1)
       (<= number *constitution-articles*)))
