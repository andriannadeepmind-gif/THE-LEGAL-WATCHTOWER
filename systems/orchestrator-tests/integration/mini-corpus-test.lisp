;;;; systems/orchestrator-tests/integration/mini-corpus-test.lisp
;;;; Integration test with mini corpus

(in-package :orchestrator-tests)

(in-suite integration-tests)

(test mini-corpus-processing
  "Test processing a mini corpus"
  (let ((corpus *test-corpus*))
    (orchestrator.spec:add-article corpus *test-article-1*)
    (orchestrator.spec:add-article corpus *test-article-2*)
    (is (= 2 (orchestrator.spec:corpus-article-count corpus)))
    (is (not (null (orchestrator.spec:get-article corpus 1))))
    (is (not (null (orchestrator.spec:get-article corpus 2))))))
