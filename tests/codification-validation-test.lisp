;;;; tests/codification-validation-test.lisp
;;;; The correctness gate: detect duplicates, numeric collisions (lettered vs
;;;; base), and sequence gaps before any parse is published as authoritative.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mk (number numeric &optional suffix)
  (make-instance 'fek-article :id (intern (format nil "A-~A" number))
                 :number number :numeric numeric :suffix suffix :confidence 1.0))

(format t "~%== Clean parse passes ==~%")
(multiple-value-bind (ok rep)
    (validate-codification (list (mk "1" 1) (mk "2" 2) (mk "3" 3)) :expected-count 3)
  (check "ok when contiguous, no dups, count matches" ok)
  (check "unique = 3" (= 3 (getf rep :unique)))
  (check "no duplicates/gaps/collisions"
         (and (null (getf rep :duplicates)) (null (getf rep :gaps))
              (null (getf rep :numeric-collisions)))))

(format t "~%== Duplicate article number flagged ==~%")
(multiple-value-bind (ok rep)
    (validate-codification (list (mk "1" 1) (mk "458" 458) (mk "458" 458) (mk "459" 459)))
  (check "not ok with a duplicate" (not ok))
  (check "duplicate 458 reported" (member "458" (getf rep :duplicates) :test #'string=)))

(format t "~%== Lettered family (70/70Α) is OK, reported, not a duplicate ==~%")
(multiple-value-bind (ok rep)
    (validate-codification (list (mk "187" 187) (mk "187Α" 187 "Α") (mk "188" 188)))
  (check "OK — lettered family is legitimate (preserved via file-id)" ok)
  (check "family on 187 reported (187 + 187Α)"
         (let ((c (assoc 187 (getf rep :numeric-collisions))))
           (and c (member "187" (cdr c) :test #'string=)
                (member "187Α" (cdr c) :test #'string=))))
  (check "187Α listed as lettered" (member "187Α" (getf rep :lettered) :test #'string=))
  (check "no duplicate (distinct labels)" (null (getf rep :duplicates))))

(format t "~%== Sequence gap flagged ==~%")
(multiple-value-bind (ok rep)
    (validate-codification (list (mk "1" 1) (mk "2" 2) (mk "10" 10)))
  (check "not ok with a gap" (not ok))
  (check "gap 2->10 reported" (member '(2 . 10) (getf rep :gaps) :test #'equal)))

(format t "~%== Count mismatch flagged ==~%")
(multiple-value-bind (ok rep)
    (validate-codification (list (mk "1" 1) (mk "2" 2)) :expected-count 466)
  (declare (ignore rep))
  (check "not ok when count != expected" (not ok)))

(format t "~%== article-file-id preserves letters (the data-loss fix) ==~%")
(let ((a (make-instance 'orchestrator.model:article :number 70 :label "70Α"))
      (b (make-instance 'orchestrator.model:article :number 70 :label nil))
      (c (make-instance 'orchestrator.model:article :number 5 :label "5"))
      (d (make-instance 'orchestrator.model:article :number 110 :label "110Β")))
  (check "70Α -> 070Α (no collision with 70)" (string= (orchestrator.model:article-file-id a) "070Α"))
  (check "70 (no label) -> 070" (string= (orchestrator.model:article-file-id b) "070"))
  (check "5 numeric label -> 005" (string= (orchestrator.model:article-file-id c) "005"))
  (check "110Β -> 110Β" (string= (orchestrator.model:article-file-id d) "110Β"))
  (check "70 and 70Α now get DISTINCT file ids (no overwrite)"
         (not (string= (orchestrator.model:article-file-id a)
                       (orchestrator.model:article-file-id b)))))

(format t "~%========================================~%")
(format t "Codification validation tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
