;;;; source/hash-authority.lisp
;;;; GATE-3: HASH AUTHORITY UNIFICATION

(defpackage #:orchestrator.hash-authority
  (:use :cl)
  (:export #:compute-hash
           #:compute-hash-prefixed
           #:merkle-root))

(in-package :orchestrator.hash-authority)

(defun compute-hash (content &key algorithm)
  "Compute cryptographic hash with mandatory algorithm.

   Arguments:
     content: String or byte-vector to hash
     algorithm: REQUIRED - :sha256, :sha512, :blake2, or :blake3

   Fail-fast guarantees:
     - Errors if ALGORITHM not provided (prevents accidental omission)
     - Errors if algorithm not in allowed set

   This is the ONLY authorized hash function for cryptographic hashing.
   All hash operations must use this function with explicit algorithm.

   Returns:
     Hex string (lowercase, without algorithm prefix)"

  (unless algorithm
    (error "ALGORITHM parameter is required. Use :algorithm :sha256/:sha512/:blake2/:blake3"))

  (unless (member algorithm '(:sha256 :sha512 :blake2 :blake3))
    (error "ALGORITHM must be :sha256, :sha512, :blake2, or :blake3, got: ~A" algorithm))

  (let ((bytes (etypecase content
                 (string (babel:string-to-octets content))
                 ((simple-array (unsigned-byte 8) (*)) content)
                 (vector content))))
    (ironclad:byte-array-to-hex-string
     (ironclad:digest-sequence algorithm bytes))))

(defun compute-hash-prefixed (content &key algorithm)
  "Compute cryptographic hash with algorithm prefix.

   Arguments:
     content: String content to hash
     algorithm: REQUIRED - :sha256, :sha512, :blake2, or :blake3

   Returns:
     Prefixed hex string (e.g., 'blake3:abcd1234...')"

  (let ((hex (compute-hash content :algorithm algorithm)))
    (format nil "~(~A~):~A" algorithm hex)))

(defun merkle-root (hashes)
  "Placeholder for Merkle root computation.
   Real implementation is in orchestrator-epistemic/merkle-tree.lisp"
  (error "Use orchestrator.epistemic:build-merkle-tree instead"))
