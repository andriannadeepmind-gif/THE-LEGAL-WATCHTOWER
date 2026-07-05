;;;; systems/orchestrator-tests/unit/utilities-test.lisp
;;;; Unit tests for utilities

(in-package :orchestrator-tests)

(in-suite unit-tests)

(test type-validators
  "Test type validators"
  (is (typep "el" 'orchestrator.spec:language-code))
  (is (not (typep "english" 'orchestrator.spec:language-code)))
  (is (typep "http://example.com/eli/test" 'orchestrator.spec:eli-uri))
  (is (not (typep "not-a-uri" 'orchestrator.spec:eli-uri))))
