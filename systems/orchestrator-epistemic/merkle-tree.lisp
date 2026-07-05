;;;; systems/orchestrator-epistemic/merkle-tree.lisp
;;;; Merkle Tree Construction for Release Integrity

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; MERKLE TREE DATA STRUCTURE
;;; ============================================================================

(defstruct merkle-node
  "Node in Merkle tree"
  (hash nil :type (or null string))
  (left nil :type (or null merkle-node))
  (right nil :type (or null merkle-node))
  (data nil :type (or null string)))

;;; ============================================================================
;;; SHA-256 HASH COMPUTATION (NIST Standard, RFC 3161 Compatible)
;;; ============================================================================

(defun compute-sha256-file (filepath)
  "Compute SHA-256 hash of file with deterministic UTF-8 encoding

  Args:
    filepath: Path to file

  Returns:
    SHA-256 hash formatted as 'sha256:HEX'"

  (let ((content (alexandria:read-file-into-byte-vector filepath)))
    (format nil "sha256:~(~{~2,'0x~}~)"
            (coerce (ironclad:digest-sequence :sha256 content) 'list))))

(defun compute-sha256-string (string)
  "Compute SHA-256 hash of string with UTF-8 encoding

  Args:
    string: String content

  Returns:
    SHA-256 hash formatted as 'sha256:HEX'"

  (let ((bytes (babel:string-to-octets string :encoding :utf-8)))
    (format nil "sha256:~(~{~2,'0x~}~)"
            (coerce (ironclad:digest-sequence :sha256 bytes) 'list))))

(defun compute-sha256-concat (hash1 hash2)
  "Compute SHA-256 hash of concatenated hashes (for internal nodes)

  DARPA-GRADE: Hash raw bytes, not UTF-8 encoding of hex characters.
  Standard Merkle trees concatenate raw hash bytes: H(H1 || H2)
  NOT the ASCII encoding of the hex strings.

  Args:
    hash1: First hash (with 'sha256:' prefix)
    hash2: Second hash (with 'sha256:' prefix)

  Returns:
    SHA-256 hash of (bytes1 || bytes2)"

  (let* ((hex1 (subseq hash1 7))  ; Remove 'sha256:' prefix
         (hex2 (subseq hash2 7))
         ;; Convert hex strings to raw bytes (not UTF-8 of hex chars!)
         (bytes1 (ironclad:hex-string-to-byte-array hex1))
         (bytes2 (ironclad:hex-string-to-byte-array hex2))
         (concatenated (concatenate '(vector (unsigned-byte 8)) bytes1 bytes2)))
    (format nil "sha256:~(~{~2,'0x~}~)"
            (coerce (ironclad:digest-sequence :sha256 concatenated) 'list))))

;;; ============================================================================
;;; MERKLE TREE CONSTRUCTION
;;; ============================================================================

(defun build-merkle-tree (filepaths)
  "Build Merkle tree from list of file paths

  Algorithm:
    1. Compute SHA-256 hash for each file (leaf nodes)
    2. Pair hashes and compute parent hashes recursively
    3. Handle odd number of nodes by duplicating last node

  Args:
    filepaths: List of file paths

  Returns:
    Merkle tree root node"

  (unless filepaths
    (error "Cannot build Merkle tree from empty file list"))

  (let ((leaf-nodes (mapcar (lambda (filepath)
                             (make-merkle-node
                              :hash (compute-sha256-file filepath)
                              :data (namestring filepath)))
                           filepaths)))
    (build-tree-from-nodes leaf-nodes)))

(defun build-tree-from-nodes (nodes)
  "Recursively build Merkle tree from list of nodes

  Args:
    nodes: List of merkle-node structs

  Returns:
    Root merkle-node"

  (cond
    ;; Single node = root
    ((= (length nodes) 1)
     (first nodes))

    ;; Multiple nodes - build next level
    (t
     (let ((parent-nodes nil))
       ;; Pair nodes and create parents
       (loop for (left right) on nodes by #'cddr
             do (let ((parent-hash (if right
                                      (compute-sha256-concat
                                       (merkle-node-hash left)
                                       (merkle-node-hash right))
                                      ;; Odd number - duplicate last
                                      (compute-sha256-concat
                                       (merkle-node-hash left)
                                       (merkle-node-hash left)))))
                  (push (make-merkle-node
                         :hash parent-hash
                         :left left
                         :right (or right left))
                        parent-nodes)))
       ;; Recurse
       (build-tree-from-nodes (nreverse parent-nodes))))))

;;; ============================================================================
;;; MERKLE ROOT EXTRACTION
;;; ============================================================================

(defun merkle-tree-root (tree)
  "Extract Merkle root hash from tree

  Args:
    tree: Merkle tree root node

  Returns:
    SHA-256 hash string"

  (merkle-node-hash tree))

;;; ============================================================================
;;; INCLUSION PROOF GENERATION
;;; ============================================================================

(defun generate-inclusion-proof (tree target-filepath)
  "Generate Merkle inclusion proof for specific file

  Inclusion proof = list of sibling hashes along path from leaf to root

  Args:
    tree: Merkle tree root node
    target-filepath: File to generate proof for

  Returns:
    List of proof objects (:direction :left/:right :hash \"sha256:...\")"

  (let ((proof nil))
    (labels ((search-tree (node path)
               (cond
                 ;; Found target at leaf
                 ((and (null (merkle-node-left node))
                       (null (merkle-node-right node))
                       (merkle-node-data node)  ; data must be non-NIL
                       (string= (merkle-node-data node) (namestring target-filepath)))
                  (nreverse proof))

                 ;; Not a leaf - search children
                 ((merkle-node-left node)
                  (let ((left-result
                         (progn
                           (when (merkle-node-right node)
                             (push (list :direction :right
                                        :hash (merkle-node-hash (merkle-node-right node)))
                                   proof))
                           (search-tree (merkle-node-left node) (cons :left path)))))
                    (if left-result
                        left-result
                        (progn
                          (when (merkle-node-right node)
                            (pop proof))  ; Remove sibling we pushed
                          (when (merkle-node-right node)
                            (push (list :direction :left
                                       :hash (merkle-node-hash (merkle-node-left node)))
                                  proof)
                            (search-tree (merkle-node-right node) (cons :right path)))))))

                 ;; Not found
                 (t nil))))
      (or (search-tree tree nil)
          (error "File not found in Merkle tree: ~A" target-filepath)))))

(defun generate-all-inclusion-proofs (tree filepaths)
  "Generate inclusion proofs for all files

  Args:
    tree: Merkle tree root node
    filepaths: List of all file paths

  Returns:
    Association list of (filepath . inclusion-proof) pairs"

  (loop for filepath in filepaths
        collect (cons filepath
                      (generate-inclusion-proof tree filepath))))

;;; ============================================================================
;;; MERKLE PROOF VERIFICATION
;;; ============================================================================

(defun verify-inclusion-proof (leaf-hash proof merkle-root)
  "Verify Merkle inclusion proof

  Recomputes root hash from leaf + proof path and compares to expected root.

  Args:
    leaf-hash: SHA-256 hash of file
    proof: List of (direction . sibling-hash) pairs
    merkle-root: Expected Merkle root

  Returns:
    T if proof valid, NIL otherwise"

  (let ((current-hash leaf-hash))
    (loop for (direction . sibling-hash) in proof
          do (setf current-hash
                  (if (eq direction :left)
                      (compute-sha256-concat sibling-hash current-hash)
                      (compute-sha256-concat current-hash sibling-hash))))
    (string= current-hash merkle-root)))
