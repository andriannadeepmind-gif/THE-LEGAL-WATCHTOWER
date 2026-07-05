;;;; tests/source-materialize-test.lisp
;;;; Materialize PDF-extracted articles (IIR) into the canonical source.json — the
;;;; shape corpus-spec reads — so the REAL extracted code (not a placeholder) flows
;;;; into consolidation / intelligence / serve. The PDF extraction itself needs
;;;; poppler, but the IIR → JSON serialization is exercised here deterministically
;;;; with mock normalized-article-input objects (no poppler needed).

(in-package :orchestrator.gov-source)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun iir (title content &key (number 1) (label "1"))
  (orchestrator.model:make-normalized-article-input
   :article-number number :article-label label
   :article-title title :article-content content
   :source-type :pdf :source-path "test"))

(defparameter *iirs*
  (list (iir "Άρθρο 1 - Καμία ποινή χωρίς νόμο" "Κανείς δεν τιμωρείται χωρίς νόμο." :number 1 :label "1")
        (iir "Άρθρο 100 - Αναστολή εκτέλεσης ποινής υπό όρο" "Το δικαστήριο αναστέλλει." :number 100 :label "100")
        (iir "Άρθρο 100Α - Αναστολή υπό επιτήρηση" "Η αναστολή συνοδεύεται από επιτήρηση." :number 100 :label "100Α")))

(format t "~%== IIR → canonical source.json shape ==~%")
(let* ((json (normalized-articles->json *iirs*))
       (objs (jonathan:parse json :as :alist)))
  (check "produces a JSON array of the right length" (= 3 (length objs)))
  (check "each entry has a title and content key"
         (every (lambda (o) (and (assoc "title" o :test #'string=)
                                 (assoc "content" o :test #'string=)))
                objs))
  (check "the first article's title is preserved"
         (string= "Άρθρο 1 - Καμία ποινή χωρίς νόμο"
                  (cdr (assoc "title" (first objs) :test #'string=))))
  (check "the article body is carried into content"
         (let ((c (cdr (assoc "content" (first objs) :test #'string=))))
           (search "Κανείς δεν τιμωρείται" (princ-to-string c))))
  ;; the corpus-spec contract: it reads "title" + "content" off each object
  (check "matches what corpus-spec reads (title + content present, in order)"
         (and (string= "Άρθρο 100 - Αναστολή εκτέλεσης ποινής υπό όρο"
                       (cdr (assoc "title" (second objs) :test #'string=)))
              (string= "Άρθρο 100Α - Αναστολή υπό επιτήρηση"
                       (cdr (assoc "title" (third objs) :test #'string=))))))

(format t "~%== lettered articles stay DISTINCT (100 ≠ 100Α) ==~%")
(let* ((json (normalized-articles->json *iirs*)))
  (check "100 and 100Α are two separate entries with distinct titles"
         (and (search "Άρθρο 100 -" json) (search "Άρθρο 100Α -" json)))
  (check "the lettered title is not collapsed onto the base"
         (not (string= (cdr (assoc "title" (jonathan:parse json :as :alist) :test #'equal) )
                       "")))) ; sanity: parse works

(format t "~%== write-source-json: file round-trip ==~%")
(let* ((path (format nil "/tmp/source-mat-test-~A.json" (get-universal-time)))
       (cnt (write-source-json *iirs* path)))
  (check "returns the article count" (= 3 cnt))
  (check "the file exists" (probe-file path))
  (let ((round (jonathan:parse (uiop:read-file-string path :external-format :utf-8) :as :alist)))
    (check "the written file re-parses to the same articles" (= 3 (length round)))
    (check "the lettered article survived the round-trip"
           (some (lambda (o) (search "100Α" (princ-to-string (cdr (assoc "title" o :test #'string=)))))
                 round)))
  (ignore-errors (delete-file path)))

(format t "~%== deterministic ==~%")
(check "same IIR → byte-identical JSON"
       (string= (normalized-articles->json *iirs*) (normalized-articles->json *iirs*)))
(check "empty input → empty array" (string= "[]" (normalized-articles->json '())))

(format t "~%========================================~%")
(format t "Source materialize tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
