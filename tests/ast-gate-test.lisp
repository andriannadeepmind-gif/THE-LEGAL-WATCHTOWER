;;;; tests/ast-gate-test.lisp
;;;; The AST structural gate: the served corpus is lifted into the CLOS legal-AST
;;;; and the (previously dead, raw-text-only) Layer-4 validators run over it. This
;;;; proves the gate accepts a well-formed corpus, flags structural defects
;;;; (missing article number, empty document), and carries lettered ids (100Α)
;;;; into the AST distinctly. Deterministic; no PDF/poppler needed.

(in-package :orchestrator.ast-gate)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== a well-formed corpus passes the structural gate ==~%")
(let ((ast (articles->document-ast
            (list (list :number "5" :title "Δικαίωμα" :paragraphs (list "Πρώτη παράγραφος." "Δεύτερη."))
                  (list :number "6" :paragraphs (list "Κείμενο άρθρου 6."))))))
  (multiple-value-bind (valid-p result) (validate-document-ast ast)
    (check "valid-p is true for a well-formed document" valid-p)
    (check "structure-clean-p agrees" (structure-clean-p result))
    (check "no issues reported" (null (orchestrator.validate-ast:result-issues result)))
    (check "the AST actually has nodes" (plusp (orchestrator.validate-ast:result-node-count result)))
    (check "report renders the success line"
           (search "δομή άρθρων έγκυρη" (format-structure-report result nil)))))

(format t "~%== lettered article id is carried into the AST as a distinct string ==~%")
(let* ((ast (articles->document-ast
             (list (list :number "100"  :paragraphs (list "Αναστολή εκτέλεσης ποινής υπό όρο."))
                   (list :number "100Α" :paragraphs (list "Αναστολή υπό επιτήρηση.")))))
       (arts (orchestrator.legal-ast:document-articles ast))
       (nums (mapcar #'orchestrator.legal-ast:article-number arts)))
  (check "both article numbers present" (= 2 (length nums)))
  (check "100 kept" (member "100" nums :test #'equal))
  (check "100Α kept (distinct from 100)" (member "100Α" nums :test #'equal))
  (check "100 and 100Α are NOT the same AST node id"
         (not (equal (first nums) (second nums))))
  (multiple-value-bind (valid-p result) (validate-document-ast ast)
    (declare (ignore result))
    (check "a lettered corpus still validates" valid-p)))

(format t "~%== the gate FLAGS a missing article number ==~%")
(let ((ast (articles->document-ast
            (list (list :number nil :paragraphs (list "Άρθρο χωρίς αριθμό."))))))
  (multiple-value-bind (valid-p result) (validate-document-ast ast)
    (check "not valid when an article has no number" (not valid-p))
    (check "an issue is recorded" (plusp (length (orchestrator.validate-ast:result-issues result))))
    (check "the report shows a structural problem"
           (search "δομικό" (format-structure-report result nil)))))

(format t "~%== the gate FLAGS an empty document ==~%")
(let ((ast (articles->document-ast '())))
  (multiple-value-bind (valid-p result) (validate-document-ast ast)
    (check "not valid when the document has no articles" (not valid-p))
    (check "an issue is recorded for the empty document"
           (plusp (length (orchestrator.validate-ast:result-issues result))))))

(format t "~%== determinism: same input, same verdict ==~%")
(let ((specs (list (list :number "1" :paragraphs (list "Α."))
                   (list :number "2" :paragraphs (list "Β.")))))
  (check "two runs agree on validity"
         (eql (validate-document-ast (articles->document-ast specs))
              (validate-document-ast (articles->document-ast specs)))))

(format t "~%========================================~%")
(format t "AST gate tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
