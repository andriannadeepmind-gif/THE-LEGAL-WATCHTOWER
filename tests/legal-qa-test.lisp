;;;; tests/legal-qa-test.lisp
;;;; Deterministic legal reasoning over the citation graph.

(in-package :orchestrator.legal-qa)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mk (eid title text)
  (orchestrator.consolidation:make-provision :eid eid :kind :article :heading title :text text))

;; art 3 is cited by 1 and 2 (the central one); art 4 is isolated.
(defparameter *doc*
  (orchestrator.consolidation:make-legal-document
   :id "syn" :title "Synthetic"
   :provisions (list (mk "art_1" "Πρώτο" "ορίζεται κατά το άρθρο 3 και το άρθρο 2")
                     (mk "art_2" "Δεύτερο" "βλέπε άρθρο 3")
                     (mk "art_3" "Τρίτο" "αυτοτελές")
                     (mk "art_4" "Τέταρτο" "καμία παραπομπή"))))

(format t "~%== outgoing / incoming ==~%")
(check "references-from 1 = (3 2)" (equal '("3" "2") (getf (references-from *doc* "1") :references)))
(check "references-to 3 = (1 2)" (equal '("1" "2") (getf (references-to *doc* "3") :referenced-by)))
(check "references-to 3 count = 2" (= 2 (getf (references-to *doc* "3") :count)))

(format t "~%== centrality + isolated ==~%")
(let ((rank (getf (most-referenced *doc*) :ranking)))
  (check "most-referenced top is art 3" (equal "3" (car (first rank))))
  (check "art 3 in-degree = 2" (= 2 (cdr (first rank)))))
(check "isolated = (4)" (equal '("4") (getf (isolated-articles *doc*) :articles)))

(format t "~%== dispatcher + provability ==~%")
(check "answer :references-to dispatches" (equal '("1" "2") (getf (answer *doc* :references-to :id "3") :referenced-by)))
(check "every answer carries its question key" (eq :most-referenced (getf (answer *doc* :most-referenced) :question)))
(check "deterministic" (equal (references-to *doc* "3") (references-to *doc* "3")))

(format t "~%== AI-consumable graph JSON ==~%")
(let ((json (legal-graph-json *doc*)))
  (check "valid-looking JSON with articles" (and (search "\"articles\"" json) (search "\"id\":\"3\"" json)))
  (check "art 3 referenced_by includes 1 and 2"
         (let ((p (search "\"id\":\"3\"" json)))
           (and p (search "\"referenced_by\":[\"1\",\"2\"]" (subseq json p)))))
  (check "titles included" (search "\"title\":\"Τρίτο\"" json)))

(format t "~%========================================~%")
(format t "Legal QA tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
