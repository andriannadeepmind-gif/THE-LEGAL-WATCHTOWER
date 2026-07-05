;;;; systems/orchestrator-tests/unit/dsl-test.lisp
;;;; Unit tests for pipeline DSL

(in-package :orchestrator-tests)

(in-suite unit-tests)

(test pipeline-definition
  "Test DEFPIPELINE macro"
  (let ((pipeline (orchestrator.spec:defpipeline test-pipeline
                   (:corpus :test)
                   (:config '(:test t))
                   (:stages
                     (stage-a :function #'identity :produces (:output-a))
                     (stage-b :function #'identity 
                             :depends-on (stage-a)
                             :produces (:output-b))))))
    (is (not (null pipeline)))
    (is (= 2 (length (orchestrator.spec:pipeline-stages pipeline))))
    (is (eql 'test-pipeline (orchestrator.spec:pipeline-name pipeline)))))
