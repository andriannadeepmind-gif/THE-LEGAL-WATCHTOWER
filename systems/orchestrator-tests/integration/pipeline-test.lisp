;;;; systems/orchestrator-tests/integration/pipeline-test.lisp
;;;; Integration test for pipeline execution

(in-package :orchestrator-tests)

(in-suite integration-tests)

(test simple-pipeline-execution
  "Test simple pipeline execution"
  (let* ((pipeline (orchestrator.spec:find-pipeline 'test-pipeline))
         (context (orchestrator.core:make-pipeline-context
                   :pipeline pipeline
                   :config *mock-config*)))
    (is (not (null context)))
    (is (zerop (hash-table-count (orchestrator.core:context-artifacts context))))))
