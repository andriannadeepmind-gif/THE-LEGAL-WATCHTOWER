;;;; tests/legal-references-test.lisp
;;;; Legal cross-reference graph + integrity over a deterministic synthetic corpus.

(in-package :orchestrator.references)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mk (eid text) (orchestrator.consolidation:make-provision :eid eid :kind :article :text text))

(format t "~%== citation extraction ==~%")
(check "single 'άρθρο 299'" (equal '("299") (extract-article-refs "τιμωρείται κατά το άρθρο 299 του κώδικα")))
(check "comma list 'άρθρα 216, 217, 218'"
       (equal '("216" "217" "218") (extract-article-refs "στα άρθρα 216, 217, 218 προβλέπεται")))
(check "range endpoints 'άρθρων 235 - 263Α'"
       (equal '("235" "263Α") (extract-article-refs "για τα εγκλήματα των άρθρων 235 - 263Α")))
(check "lettered citation normalised (263α → 263Α)"
       (equal '("263Α") (extract-article-refs "κατά το άρθρο 263α")))
(check "paragraph ref not swallowed ('άρθρο 94 παράγραφος 1' → 94)"
       (equal '("94") (extract-article-refs "εφαρμόζεται το άρθρο 94 παράγραφος 1")))
(check "no citation → none" (null (extract-article-refs "καμία παραπομπή εδώ")))
(check "distinct, in order" (equal '("5" "7") (extract-article-refs "άρθρο 5 και άρθρο 7 και πάλι άρθρο 5")))

(format t "~%== graph + reverse edges ==~%")
(let* ((doc (orchestrator.consolidation:make-legal-document
             :id "syn" :title "Synthetic"
             :provisions (list (mk "art_1" "ορίζει κατά το άρθρο 3 και το άρθρο 2")
                               (mk "art_2" "βλέπε άρθρο 3")
                               (mk "art_3" "τελικό άρθρο")
                               (mk "art_4" "παραπέμπει στο άρθρο 999 και στο άρθρο 2"))))
       (g (reference-graph doc)))
  (check "edges of art 1 = (3 2) resolved" (equal '("3" "2") (graph-edges g "1")))
  (check "art 4 edge to 999 dropped (does not exist), 2 kept" (equal '("2") (graph-edges g "4")))
  (check "reverse: who references art 3? (1,2)" (equal '("1" "2") (graph-referenced-by g "3")))
  (check "reverse: who references art 2? (1,4)" (equal '("1" "4") (graph-referenced-by g "2"))))

(format t "~%== integrity ==~%")
(let* ((ok-doc (orchestrator.consolidation:make-legal-document
                :id "ok" :provisions (list (mk "art_1" "άρθρο 2") (mk "art_2" "τέλος"))))
       (bad-doc (orchestrator.consolidation:make-legal-document
                 :id "bad" :provisions (list (mk "art_1" "άρθρο 2 και άρθρο 5")
                                             (mk "art_2" "ok")))))
  (check "all internal refs resolve" (verify-references ok-doc))
  (multiple-value-bind (ok unresolved) (verify-references bad-doc)
    (check "dangling ref detected" (and (not ok) (member '("1" . "5") unresolved :test #'equal)))
    (check "report names the exact edge"
           (search "άρθρο 1 → άρθρο 5" (format-reference-report unresolved)))))

(format t "~%========================================~%")
(format t "Legal references tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
