;;;; run-tests-docker.lisp
;;;; Phase 3: Escape sequence test execution (Docker-compatible paths)

;; Configure ASDF source registry (use /workspace which Docker mounts)
(require "asdf")
(asdf:initialize-source-registry
 '(:source-registry
   (:tree "/workspace/")
   :inherit-configuration))

;; Load orchestrator systems (escape functions are in orchestrator-spec)
(format t "~%Loading orchestrator-spec system...~%")
(asdf:load-system :orchestrator-spec)

(format t "Loading orchestrator-engine-sbcl system...~%")
(asdf:load-system :orchestrator-engine-sbcl)

;; Load FiveAM test framework
(format t "Loading FiveAM test framework...~%")
(asdf:load-system :fiveam)

;; Load test file
(format t "Loading test file...~%")
(load "/workspace/tests/test-escape-sequences.lisp")

;; Execute tests
(format t "~%=================================================================~%")
(format t "PHASE 3: ESCAPE SEQUENCE TEST EXECUTION~%")
(format t "=================================================================~%~%")

(let ((results (orchestrator.tests.escape:run-escape-tests)))
  (if results
      (progn
        (format t "~%✓✓✓ PHASE 3: PASS ✓✓✓~%")
        (sb-ext:exit :code 0))
      (progn
        (format t "~%✗✗✗ PHASE 3: FAIL ✗✗✗~%")
        (sb-ext:exit :code 1))))
