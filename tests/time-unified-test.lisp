;;;; tests/time-unified-test.lisp
;;;; GATE-1: TIME UNIFICATION TESTS
;;;; Tests for orchestrator.time unified API with mock injection

(defpackage :orchestrator.time-tests
  (:use :cl :fiveam :orchestrator.time)
  (:export #:run-time-tests))

(in-package :orchestrator.time-tests)

;;; ============================================================================
;;; TEST SUITE DEFINITION
;;; ============================================================================

(def-suite time-unified-suite
  :description "GATE-1: TIME unification tests with mock injection")

(in-suite time-unified-suite)

;;; ============================================================================
;;; FIXTURES
;;; ============================================================================

(defparameter *test-timestamp* 3944678400
  "Fixed universal-time for deterministic testing: 2025-01-01T00:00:00Z
   (universal-time 3944678400; the previous value 3904752000 was 2023-09-26 and
   was inconsistent with every 2025-01-01 assertion below).")

;;; ============================================================================
;;; API TESTS
;;; ============================================================================

(test now-requires-source
  "Test (now) fails when :source parameter is not provided (fail-fast guarantee)"
  (signals error
    (now)))

(test now-system-mode
  "Test (now :source :system) returns current universal-time"
  (let ((t1 (now :source :system))
        (t2 (get-universal-time)))
    (is (integerp t1))
    (is (<= (abs (- t1 t2)) 1))))  ; Allow 1 second tolerance

(test now-mock-mode-with-value
  "Test (now :source :mock) returns *mock-time* when set"
  (let ((*mock-time* *test-timestamp*))
    (is (= (now :source :mock) *test-timestamp*))))

(test now-mock-mode-fail-fast
  "Test (now :source :mock) fails when *mock-time* is nil"
  (let ((*mock-time* nil))
    (signals error
      (now :source :mock))))

(test now-determinism
  "Test that (now :source :mock) returns same value on repeated calls"
  (let ((*mock-time* *test-timestamp*))
    (let ((t1 (now :source :mock))
          (t2 (now :source :mock))
          (t3 (now :source :mock)))
      (is (= t1 t2 t3 *test-timestamp*)))))

;;; ============================================================================
;;; FORMAT TESTS
;;; ============================================================================

(test format-iso8601-basic
  "Test format-iso8601 produces correct ISO8601 string"
  (let ((result (format-iso8601 *test-timestamp*)))
    (is (stringp result))
    (is (search "2025-01-01" result))
    (is (search "T" result))
    (is (search "Z" result))))

(test format-iso8601-determinism
  "Test format-iso8601 is deterministic (same input → same output)"
  (let ((r1 (format-iso8601 *test-timestamp*))
        (r2 (format-iso8601 *test-timestamp*)))
    (is (string= r1 r2))))

;;; ============================================================================
;;; PARSE TESTS
;;; ============================================================================

(test parse-iso8601-basic
  "Test parse-iso8601 correctly parses ISO8601 string"
  (let ((timestamp (parse-iso8601 "2025-01-01T00:00:00Z")))
    (is (integerp timestamp))
    (is (= timestamp *test-timestamp*))))

(test parse-iso8601-round-trip
  "Test format → parse round-trip preserves timestamp"
  (let* ((formatted (format-iso8601 *test-timestamp*))
         (parsed (parse-iso8601 formatted)))
    (is (= parsed *test-timestamp*))))

;;; ============================================================================
;;; INTEGRATION TESTS
;;; ============================================================================

(test mock-injection-isolation
  "Test that mock time doesn't leak between test contexts"
  (let ((*mock-time* 1000))
    (is (= (now :source :mock) 1000)))

  ;; In new context, *mock-time* should be nil
  (signals error
    (now :source :mock)))

(test system-vs-mock-independence
  "Test that :system and :mock modes are independent"
  (let ((*mock-time* *test-timestamp*))
    (let ((mock-val (now :source :mock))
          (sys-val (now :source :system)))
      (is (= mock-val *test-timestamp*))
      (is (not (= sys-val *test-timestamp*))))))

;;; ============================================================================
;;; GOLDEN FIXTURE TEST
;;; ============================================================================

(test golden-fixture-determinism
  "Test that same mock time produces same formatted output (golden fixture)"
  (let ((*mock-time* *test-timestamp*))
    (let ((output1 (format-iso8601 (now :source :mock)))
          (output2 (format-iso8601 (now :source :mock))))
      (is (string= output1 output2))
      (is (string= output1 "2025-01-01T00:00:00Z")))))

;;; ============================================================================
;;; TEST RUNNER
;;; ============================================================================

(defun run-time-tests ()
  "Run all GATE-1 time unification tests"
  (run! 'time-unified-suite))

;;; Standalone gate: run the suite, exit non-zero on any failure (was never invoked).
(sb-ext:exit :code (if (fiveam:run! 'time-unified-suite) 0 1))
