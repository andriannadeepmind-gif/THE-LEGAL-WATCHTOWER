;;;; systems/orchestrator-tests/reproducibility/hash-stability-test.lisp
;;;; Reproducibility test for hash stability

(in-package :orchestrator-tests)

(in-suite reproducibility-tests)

(test hash-reproducibility
  "Test that same input produces same hash"
  (let ((content "Test content for hashing"))
    (let ((hash1 (orchestrator.hash-authority:compute-hash content :algorithm :sha256))
          (hash2 (orchestrator.hash-authority:compute-hash content :algorithm :sha256)))
      (is (string= hash1 hash2)))))
