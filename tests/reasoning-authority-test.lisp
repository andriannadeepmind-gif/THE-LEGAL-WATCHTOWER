;;;; tests/reasoning-authority-test.lisp
;;;; The reasoning-authority: a pure-Lisp forward-chaining reasoner that goes
;;;; BEYOND plain RDFS — RDFS entailment + OWL 2 RL + ontology consistency. This
;;;; was dead code (it never compiled: variable names with a colon, e.g.
;;;; *rdf:type*, are package-qualified symbols). With that fixed it is live; this
;;;; test exercises the entailments and the consistency check. Deterministic.

(in-package :orchestrator.reasoning-authority)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun has (triples s p o) (member (list s p o) triples :test #'equal))

(format t "~%== RDFS entailment: subClassOf is transitive ==~%")
(let ((out (reason (list (list "Cat" *rdfs-subClassOf* "Mammal")
                         (list "Mammal" *rdfs-subClassOf* "Animal"))
                   :profile :rdfs)))
  (check "Cat ⊑ Mammal ⊑ Animal  ⇒  Cat ⊑ Animal"
         (has out "Cat" *rdfs-subClassOf* "Animal"))
  (check "the asserted triples are preserved (monotonic)"
         (and (has out "Cat" *rdfs-subClassOf* "Mammal")
              (has out "Mammal" *rdfs-subClassOf* "Animal"))))

(format t "~%== RDFS entailment: rdf:type propagates up the class hierarchy ==~%")
(let ((out (reason (list (list "felix" *rdf-type* "Cat")
                         (list "Cat" *rdfs-subClassOf* "Animal"))
                   :profile :rdfs)))
  (check "felix : Cat  and  Cat ⊑ Animal  ⇒  felix : Animal"
         (has out "felix" *rdf-type* "Animal")))

(format t "~%== OWL 2 RL: a transitive property chains (beyond RDFS) ==~%")
(let ((out (reason (list (list "ancestor" *rdf-type* *owl-TransitiveProperty*)
                         (list "a" "ancestor" "b")
                         (list "b" "ancestor" "c"))
                   :profile :full)))
  (check "ancestor is transitive  ⇒  a ancestor c"
         (has out "a" "ancestor" "c")))

(format t "~%== OWL 2 RL: a symmetric property is mirrored ==~%")
(let ((out (reason (list (list "marriedTo" *rdf-type* *owl-SymmetricProperty*)
                         (list "x" "marriedTo" "y"))
                   :profile :full)))
  (check "marriedTo is symmetric  ⇒  y marriedTo x"
         (has out "y" "marriedTo" "x")))

(format t "~%== the triple store + indices ==~%")
(let ((store (make-triple-store)))
  (check "add-triple returns T for a new triple" (add-triple store "s" "p" "o"))
  (check "add-triple returns NIL for a duplicate" (not (add-triple store "s" "p" "o")))
  (check "triple-count reflects one triple" (= 1 (triple-store-triple-count store)))
  (check "query-triples by predicate finds it"
         (query-triples store :predicate "p"))
  (check "remove-triple takes it out"
         (progn (remove-triple store "s" "p" "o")
                (= 0 (triple-store-triple-count store)))))

(format t "~%== ontology consistency checking ==~%")
(let ((store (make-triple-store)))
  (add-triple store "Cat" *rdfs-subClassOf* "Animal")
  (add-triple store "felix" *rdf-type* "Cat")
  (multiple-value-bind (consistent-p issues) (check-consistency store)
    (declare (ignore issues))
    (check "a well-formed ontology is reported consistent" consistent-p)))

(format t "~%== determinism ==~%")
(let ((triples (list (list "A" *rdfs-subClassOf* "B") (list "B" *rdfs-subClassOf* "C"))))
  (check "same input ⇒ same set of entailed triples"
         (let ((a (reason triples :profile :rdfs))
               (b (reason triples :profile :rdfs)))
           (and (= (length a) (length b))
                (every (lambda (tr) (member tr b :test #'equal)) a)))))

(format t "~%========================================~%")
(format t "Reasoning authority tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
