;;;; systems/orchestrator-tests/unit/dependency-graph-test.lisp
;;;; Unit tests for dependency graph

(in-package :orchestrator-tests)

(in-suite unit-tests)

(test topological-sort
  "Test topological sorting"
  (let ((graph '((a . (b c))
                (b . (c))
                (c . nil))))
    (let ((sorted (orchestrator.core:topological-sort graph)))
      (is (member 'c sorted))
      (is (< (position 'c sorted) (position 'b sorted)))
      (is (< (position 'b sorted) (position 'a sorted))))))

(test circular-dependency-detection
  "Test circular dependency detection"
  (let ((graph '((a . (b))
                (b . (c))
                (c . (a)))))
    (signals orchestrator.spec:dependency-error
      (orchestrator.core:topological-sort graph))))
