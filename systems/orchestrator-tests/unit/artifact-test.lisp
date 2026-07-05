;;;; systems/orchestrator-tests/unit/artifact-test.lisp
;;;; Unit tests for artifacts

(in-package :orchestrator-tests)

(in-suite unit-tests)

(test artifact-creation
  "Test artifact creation"
  (let ((artifact (orchestrator.model:make-artifact
                   :name :test-artifact
                   :type :rdf-turtle
                   :content "test content")))
    (is (eql :test-artifact (orchestrator.model:artifact-name artifact)))
    (is (eql :rdf-turtle (orchestrator.model:artifact-output-type artifact)))
    (is (string= "test content" (orchestrator.model:artifact-content artifact)))))
