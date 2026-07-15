;;;; tests/write-authority-test.lisp
;;;; GATE-2 Write Authority Tests

(in-package :cl-user)

(defpackage #:orchestrator.write-authority-test
  (:use :cl :fiveam)
  (:import-from :orchestrator.write-authority
                #:emit-graph
                #:with-write-authority
                #:*current-write-authority*))

(in-package :orchestrator.write-authority-test)

(def-suite write-authority-tests
  :description "GATE-2 Write Authority fail-fast guarantees")

(in-suite write-authority-tests)

;;; ============================================================
;;; FAIL-FAST TESTS - MANDATORY AUTHORITY
;;; ============================================================

(test emit-without-authority-fails
  "Test emit-graph fails when :authority parameter is not provided (fail-fast guarantee)"
  (signals error
    (emit-graph "test content" "/tmp/test.ttl")))

(test emit-with-invalid-authority-fails
  "Test emit-graph fails when :authority is not :canonical or :provenance"
  (signals error
    (emit-graph "test content" "/tmp/test.ttl" :authority :invalid)))

(test emit-with-wrong-scope-authority-fails
  "Test emit-graph fails when :authority doesn't match scope"
  (signals error
    (with-write-authority :canonical
      (emit-graph "test content" "/tmp/test.ttl" :authority :provenance))))

(test nested-with-write-authority-fails
  "Test nested WITH-WRITE-AUTHORITY is not allowed"
  (signals error
    (with-write-authority :canonical
      (with-write-authority :provenance
        nil))))

;;; ============================================================
;;; SUCCESS TESTS - CANONICAL AUTHORITY
;;; ============================================================

(test emit-canonical-succeeds
  "Test emit-graph succeeds with :authority :canonical"
  (let ((test-file "/tmp/gate2-test-canonical.ttl"))
    (finishes
      (emit-graph "@prefix ex: &lt;http://example.org/&gt; ."
                  test-file
                  :authority :canonical))
    (is (probe-file test-file))
    (delete-file test-file)))

(test emit-canonical-in-scope-succeeds
  "Test emit-graph with :canonical in canonical scope"
  (let ((test-file "/tmp/gate2-test-canonical-scope.ttl"))
    (finishes
      (with-write-authority :canonical
        (emit-graph "@prefix ex: &lt;http://example.org/&gt; ."
                    test-file
                    :authority :canonical)))
    (is (probe-file test-file))
    (delete-file test-file)))

;;; ============================================================
;;; SUCCESS TESTS - PROVENANCE AUTHORITY
;;; ============================================================

(test emit-provenance-succeeds
  "Test emit-graph succeeds with :authority :provenance"
  (let ((test-file "/tmp/gate2-test-provenance.ttl"))
    (finishes
      (emit-graph "@prefix prov: &lt;http://www.w3.org/ns/prov#&gt; ."
                  test-file
                  :authority :provenance))
    (is (probe-file test-file))
    (delete-file test-file)))

(test emit-provenance-in-scope-succeeds
  "Test emit-graph with :provenance in provenance scope"
  (let ((test-file "/tmp/gate2-test-provenance-scope.ttl"))
    (finishes
      (with-write-authority :provenance
        (emit-graph "@prefix prov: &lt;http://www.w3.org/ns/prov#&gt; ."
                    test-file
                    :authority :provenance)))
    (is (probe-file test-file))
    (delete-file test-file)))

;;; ============================================================
;;; CONTENT VERIFICATION
;;; ============================================================

(test emit-writes-correct-content
  "Test emit-graph writes exact content to file"
  (let ((test-file "/tmp/gate2-test-content.ttl")
        (test-content "@prefix ex: &lt;http://example.org/&gt; .
ex:subject ex:predicate ex:object ."))
    (emit-graph test-content test-file :authority :canonical)
    (let ((written-content (uiop:read-file-string test-file)))
      (is (string= test-content written-content)))
    (delete-file test-file)))

;;; ============================================================
;;; SCOPE TRACKING
;;; ============================================================

(test current-write-authority-nil-by-default
  "Test *current-write-authority* is nil outside scope"
  (is (null *current-write-authority*)))

(test current-write-authority-set-in-scope
  "Test *current-write-authority* is set inside scope"
  (with-write-authority :canonical
    (is (eq *current-write-authority* :canonical)))
  (with-write-authority :provenance
    (is (eq *current-write-authority* :provenance))))

;;; ============================================================
;;; RUN TESTS
;;; ============================================================

(defun run-write-authority-tests ()
  "Run all GATE-2 write authority tests"
  (format t "~%Running GATE-2 Write Authority Tests...~%")
  (let ((results (run 'write-authority-tests)))
    (format t "~%GATE-2 Write Authority Test Results: ~A~%" results)
    results))

(export 'run-write-authority-tests)

;;; Standalone gate: run the suite, exit non-zero on any failure (was never invoked).
(let* ((results (fiveam:run 'write-authority-tests))
       (failed (count-if-not (lambda (r) (typep r 'fiveam::test-passed)) results)))
  (fiveam:explain! results)
  ;; Canonical parseable proof line (manifest gate) — uniform «N passed, M failed»
  (format t "~%WRITE-AUTHORITY: ~D passed, ~D failed~%" (- (length results) failed) failed)
  (sb-ext:exit :code (if (zerop failed) 0 1)))
