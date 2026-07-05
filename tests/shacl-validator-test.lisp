;;;; tests/shacl-validator-test.lisp
;;;; Real SHACL Core validation: conforming + violating data across components.

(in-package :orchestrator.shacl)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *shapes* "
@prefix sh: <http://www.w3.org/ns/shacl#> .
@prefix ex: <http://example.org/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

ex:PersonShape a sh:NodeShape ;
    sh:targetClass ex:Person ;
    sh:property [ sh:path ex:name ; sh:minCount 1 ; sh:maxCount 1 ; sh:datatype xsd:string ] ;
    sh:property [ sh:path ex:age ; sh:datatype xsd:integer ; sh:maxCount 1 ] ;
    sh:property [ sh:path ex:email ; sh:nodeKind sh:IRI ] ;
    sh:property [ sh:path ex:status ; sh:in ( \"active\" \"inactive\" ) ] ;
    sh:property [ sh:path ex:code ; sh:pattern \"^[A-Z]{3}$\" ] ;
    sh:property [ sh:path ex:account ; sh:class ex:Account ] .
")

(defparameter *conforming* "
@prefix ex: <http://example.org/> .
ex:alice a ex:Person ;
    ex:name \"Alice\" ;
    ex:age 30 ;
    ex:email <mailto:alice@example.org> ;
    ex:status \"active\" ;
    ex:code \"ABC\" ;
    ex:account ex:acc1 .
ex:acc1 a ex:Account .
")

(defparameter *violating* "
@prefix ex: <http://example.org/> .
ex:bob a ex:Person ;
    ex:name \"Bob\", \"Bobby\" ;
    ex:age \"old\" ;
    ex:email \"not-an-iri\" ;
    ex:status \"pending\" ;
    ex:code \"abcd\" ;
    ex:account ex:acc2 .
ex:acc2 a ex:NotAnAccount .
ex:carol a ex:Person ;
    ex:age 5 .
")

(defun has-component (report comp)
  (some (lambda (r) (string= (validation-result-component r) comp))
        (validation-report-results report)))

(let ((ok (validate-turtle *conforming* *shapes*))
      (bad (validate-turtle *violating* *shapes*)))

  (format t "~%== Conforming data ==~%")
  (check "conforming data conforms" (conforms-p ok))
  (check "conforming data has zero results" (null (validation-report-results ok)))

  (format t "~%== Violating data ==~%")
  (check "violating data does NOT conform" (not (conforms-p bad)))
  (check "maxCount violation detected (name x2)" (has-component bad "MaxCountConstraintComponent"))
  (check "minCount violation detected (carol missing name)"
         (has-component bad "MinCountConstraintComponent"))
  (check "datatype violation detected (age=\"old\")" (has-component bad "DatatypeConstraintComponent"))
  (check "nodeKind violation detected (email literal)" (has-component bad "NodeKindConstraintComponent"))
  (check "pattern violation detected (code=abcd)" (has-component bad "PatternConstraintComponent"))
  (check "in violation detected (status=pending)" (has-component bad "InConstraintComponent"))
  (check "class violation detected (account not ex:Account)" (has-component bad "ClassConstraintComponent"))

  (format t "~%== Targeting & focus nodes ==~%")
  (check "two focus nodes targeted (bob, carol)"
         (= 2 (length (focus-nodes (graph-from-turtle *violating*)
                                   (first (parse-shapes (graph-from-turtle *shapes*)))))))

  (format t "~%== Report serialization ==~%")
  (let ((ttl (report->ttl bad)))
    (check "report is a sh:ValidationReport" (search "sh:ValidationReport" ttl))
    (check "report sh:conforms false" (search "sh:conforms false" ttl))
    (check "report has sh:ValidationResult" (search "sh:ValidationResult" ttl))
    (check "report serialization parses back as Turtle"
           (handler-case (progn (orchestrator.turtle:parse-turtle ttl) t) (error () nil))))

  (format t "~%== Determinism ==~%")
  (check "report TTL identical across runs"
         (string= (report->ttl (validate-turtle *violating* *shapes*))
                  (report->ttl (validate-turtle *violating* *shapes*)))))

(format t "~%== sh:targetSubjectsOf ==~%")
(let* ((shapes "
@prefix sh: <http://www.w3.org/ns/shacl#> .
@prefix ex: <http://example.org/> .
ex:ParentShape a sh:NodeShape ;
    sh:targetSubjectsOf ex:hasChild ;
    sh:property [ sh:path ex:name ; sh:minCount 1 ] .")
       (data "
@prefix ex: <http://example.org/> .
ex:p1 ex:hasChild ex:c1 ; ex:name \"Parent One\" .
ex:p2 ex:hasChild ex:c2 .
ex:unrelated ex:name \"x\" .")
       (rep (validate-turtle data shapes))
       (foci (focus-nodes (graph-from-turtle data)
                          (first (parse-shapes (graph-from-turtle shapes))))))
  (check "targetSubjectsOf selects only subjects of ex:hasChild (2)" (= 2 (length foci)))
  (check "targetSubjectsOf: p2 (missing name) violates" (not (conforms-p rep)))
  (check "targetSubjectsOf: exactly one violation (p2)"
         (= 1 (length (validation-report-results rep)))))

(format t "~%========================================~%")
(format t "SHACL validator tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
