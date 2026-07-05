;;;; orchestrator-tests/suite.lisp
;;;;
;;;; Test suite definition and runner for Orchestrator

(in-package #:orchestrator-tests)

;;; ═══════════════════════════════════════════════════════════════════════════
;;;  Test Suite Definition
;;; ═══════════════════════════════════════════════════════════════════════════

(fiveam:def-suite orchestrator-test-suite
    :description "Master test suite for Greek Legal Corpus Orchestrator")

(fiveam:def-suite unit-tests
    :description "Unit tests for individual components"
    :in orchestrator-test-suite)

(fiveam:def-suite integration-tests
    :description "Integration tests for multi-component interactions"
    :in orchestrator-test-suite)

(fiveam:def-suite reproducibility-tests
    :description "Reproducibility and determinism tests"
    :in orchestrator-test-suite)

(fiveam:in-suite orchestrator-test-suite)

;;; ═══════════════════════════════════════════════════════════════════════════
;;;  Test Runner - Production-Grade with Proper Error Handling
;;; ═══════════════════════════════════════════════════════════════════════════

(defun run-orchestrator-tests ()
  "Run all orchestrator tests using FiveAM's documented API
  
  Returns:
    T if all tests pass, NIL otherwise
    
  Notes:
    - Uses run! which returns detailed results
    - Handles results using explain! for formatted output
    - Returns boolean success indicator"
  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "  ORCHESTRATOR TEST SUITE v1.2~%")
  (format t "═══════════════════════════════════════════════════════════════~%~%")
  
  ;; Run tests and capture results
  (let ((results (fiveam:run! 'orchestrator-test-suite)))
    
    ;; FiveAM's results are complex objects
    ;; The safest way is to check explain!'s output or results-status
    ;; Since results-status returns NIL on success, we use that
    (format t "~%═══════════════════════════════════════════════════════════════~%")
    
    (let ((status (fiveam:results-status results)))
      (if (null status)
          (progn
            (format t "  ✓ ALL TESTS PASSED~%")
            (format t "═══════════════════════════════════════════════════════════════~%~%")
            t)
          (progn
            (format t "  ✗ TESTS FAILED~%")
            (format t "═══════════════════════════════════════════════════════════════~%~%")
            nil)))))

;;; ═══════════════════════════════════════════════════════════════════════════
;;;  Public API
;;; ═══════════════════════════════════════════════════════════════════════════

(defun run-all-tests ()
  "Run all orchestrator tests using FiveAM.

   This is the canonical public entry point called by:
     - orchestrator-tests.asd  perform test-op
     - orchestrator-tests-runtime.asd  perform test-op
     - entrypoint.lisp at startup

   Runs the master suite which includes all sub-suites:
     unit-tests, integration-tests, reproducibility-tests.

   Returns: T if all tests pass, NIL otherwise."
  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "  ORCHESTRATOR TEST SUITE v1.2~%")
  (format t "═══════════════════════════════════════════════════════════════~%~%")

  (let ((results (fiveam:run! 'orchestrator-test-suite)))

    (format t "~%═══════════════════════════════════════════════════════════════~%")

    (let ((status (fiveam:results-status results)))
      (if (null status)
          (progn
            (format t "  ✓ ALL TESTS PASSED~%")
            (format t "═══════════════════════════════════════════════════════════════~%~%")
            t)
          (progn
            (format t "  ✗ TESTS FAILED~%")
            (format t "═══════════════════════════════════════════════════════════════~%~%")
            nil)))))

(export '(run-orchestrator-tests run-all-tests))

;;; End of suite.lisp
