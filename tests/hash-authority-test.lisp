;;;; tests/hash-authority-test.lisp
;;;; GATE-3 Hash Authority Tests

(in-package :cl-user)

(defpackage #:orchestrator.hash-authority-test
  (:use :cl :fiveam)
  (:import-from :orchestrator.hash-authority
                #:compute-hash))

(in-package :orchestrator.hash-authority-test)

(def-suite hash-authority-tests
  :description "GATE-3 Hash Authority fail-fast guarantees")

(in-suite hash-authority-tests)

;;; ============================================================
;;; FAIL-FAST TESTS - MANDATORY ALGORITHM
;;; ============================================================

(test compute-hash-without-algorithm-fails
  "Test compute-hash fails when :algorithm parameter is not provided"
  (signals error
    (compute-hash "test content")))

(test compute-hash-with-invalid-algorithm-fails
  "Test compute-hash fails when :algorithm is not in allowed set"
  (signals error
    (compute-hash "test content" :algorithm :md5)))

(test compute-hash-with-blake3-fails
  "Test compute-hash fails with :blake3 (not supported by ironclad)"
  (signals error
    (compute-hash "test content" :algorithm :blake3)))

;;; ============================================================
;;; SUCCESS TESTS - SHA256
;;; ============================================================

(test compute-hash-sha256-succeeds
  "Test compute-hash succeeds with :algorithm :sha256"
  (finishes
    (compute-hash "test content" :algorithm :sha256)))

(test compute-hash-sha256-returns-hex-string
  "Test compute-hash returns hex string for SHA-256"
  (let ((hash (compute-hash "test content" :algorithm :sha256)))
    (is (stringp hash))
    (is (= 64 (length hash)))))

;;; ============================================================
;;; SUCCESS TESTS - SHA512
;;; ============================================================

(test compute-hash-sha512-succeeds
  "Test compute-hash succeeds with :algorithm :sha512"
  (finishes
    (compute-hash "test content" :algorithm :sha512)))

(test compute-hash-sha512-returns-hex-string
  "Test compute-hash returns hex string for SHA-512"
  (let ((hash (compute-hash "test content" :algorithm :sha512)))
    (is (stringp hash))
    (is (= 128 (length hash)))))

;;; ============================================================
;;; SUCCESS TESTS - BLAKE2
;;; ============================================================

(test compute-hash-blake2-succeeds
  "Test compute-hash succeeds with :algorithm :blake2"
  (finishes
    (compute-hash "test content" :algorithm :blake2)))

(test compute-hash-blake2-returns-hex-string
  "Test compute-hash returns hex string for BLAKE2"
  (let ((hash (compute-hash "test content" :algorithm :blake2)))
    (is (stringp hash))
    (is (> (length hash) 0))))

;;; ============================================================
;;; DETERMINISM TESTS
;;; ============================================================

(test compute-hash-is-deterministic
  "Test same input produces same hash"
  (let ((hash1 (compute-hash "deterministic test" :algorithm :sha512))
        (hash2 (compute-hash "deterministic test" :algorithm :sha512)))
    (is (string= hash1 hash2))))

(test compute-hash-different-inputs-different-hashes
  "Test different inputs produce different hashes"
  (let ((hash1 (compute-hash "content A" :algorithm :sha512))
        (hash2 (compute-hash "content B" :algorithm :sha512)))
    (is (not (string= hash1 hash2)))))

(test compute-hash-different-algorithms-different-hashes
  "Test same input with different algorithms produces different hashes"
  (let ((hash-sha256 (compute-hash "test" :algorithm :sha256))
        (hash-sha512 (compute-hash "test" :algorithm :sha512)))
    (is (not (string= hash-sha256 hash-sha512)))))

;;; ============================================================
;;; CANONICAL CONTENT TESTS
;;; ============================================================

(test compute-hash-empty-string
  "Test compute-hash handles empty string"
  (finishes
    (compute-hash "" :algorithm :sha512)))

(test compute-hash-unicode-content
  "Test compute-hash handles Unicode content"
  (finishes
    (compute-hash "Ελληνικό κείμενο με Unicode χαρακτήρες" :algorithm :sha512)))

(test compute-hash-large-content
  "Test compute-hash handles large content"
  (let ((large-content (make-string 100000 :initial-element #\A)))
    (finishes
      (compute-hash large-content :algorithm :sha512))))

;;; ============================================================
;;; RUN TESTS
;;; ============================================================

(defun run-hash-authority-tests ()
  "Run all GATE-3 hash authority tests"
  (format t "~%Running GATE-3 Hash Authority Tests...~%")
  (let ((results (run 'hash-authority-tests)))
    (format t "~%GATE-3 Hash Authority Test Results: ~A~%" results)
    results))

(export 'run-hash-authority-tests)

;;; ---------------------------------------------------------------------------
;;; Standalone gate: actually RUN the suite and exit non-zero on any failure, so
;;; this file is a real gate under docker/run-standalone-test.lisp (previously it
;;; only DEFINED the runner and was never invoked → silent green).
(sb-ext:exit :code (if (fiveam:run! 'hash-authority-tests) 0 1))
