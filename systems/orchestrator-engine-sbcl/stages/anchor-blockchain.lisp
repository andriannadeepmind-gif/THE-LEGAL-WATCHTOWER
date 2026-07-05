;;;; systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp
;;;; ============================================================================
;;;; BLOCKCHAIN ANCHORING STAGE - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; Anchors article hashes to blockchain(s) for immutable timestamping.
;;;;
;;;; AUTHORITY PATTERN:
;;;; - Uses orchestrator.blockchain-authority for all blockchain operations
;;;; - CONDITIONAL: Skips chains that are not configured
;;;; - STRICT: Fails if configured chain returns error
;;;; - Full PROV-O audit trail via anchor-result metadata
;;;;
;;;; DARPA-GRADE: No external scripts, pure Lisp, deterministic.
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defparameter *anchor-chains* '(:ethereum :arweave :ipfs)
  "List of chains to anchor to (will skip unconfigured ones)")

(defparameter *anchor-require-at-least-one* nil
  "If T, fail if no chain anchored successfully")

;;; ============================================================================
;;; ANCHOR STAGE
;;; ============================================================================

(defun anchor-blockchain-stage (context)
  "Anchor all articles to blockchain

   AUTHORITY PATTERN:
   - Computes Merkle root of all article hashes
   - Anchors to configured chains (CONDITIONAL for each chain)
   - Stores anchor results in context metadata

   Args:
     context: Pipeline execution context with :articles

   Returns:
     Updated context with :anchor-results"
  (let ((articles (orchestrator.core:get-context-value context :articles)))
    (unless articles
      (error 'orchestrator.spec:config-error
             :message "No articles in context"
             :config-key :articles))

    ;; Compute Merkle root of all article hashes
    (let* ((article-hashes (mapcar #'get-article-content-hash articles))
           (merkle-root (compute-merkle-root article-hashes))
           (anchor-results nil)
           (anchor-count 0))

      (log:info () "Anchoring ~D articles to blockchain" (length articles))
      (log:info () "  Merkle root: ~A" merkle-root)

      ;; Anchor to each configured chain
      (dolist (chain *anchor-chains*)
        (handler-case
            (let ((result (anchor-to-chain merkle-root chain)))
              (when result
                (push (cons chain result) anchor-results)
                (incf anchor-count)
                (log:info () "  ~A: ANCHORED (~A)"
                         chain (anchor-result-reference result))))
          (orchestrator.blockchain-authority:chain-not-configured (e)
            (declare (ignore e))
            (log:info () "  ~A: SKIPPED (not configured)" chain))
          (error (e)
            (log:warn () "  ~A: FAILED (~A)" chain e)
            ;; STRICT: If chain is configured but fails, we should know
            (when (chain-is-configured-p chain)
              (push (cons chain (list :error (format nil "~A" e))) anchor-results)))))

      ;; Check requirement
      (when (and *anchor-require-at-least-one* (zerop anchor-count))
        (error 'orchestrator.spec:config-error
               :message "No blockchain anchored successfully"
               :config-key :anchor-chains))

      ;; Update articles with anchor metadata
      (dolist (article articles)
        (setf (orchestrator.model:article-metadata article)
              (append (orchestrator.model:article-metadata article)
                      `((:merkle-root . ,merkle-root)
                        (:anchor-results . ,anchor-results)
                        (:anchor-timestamp . ,(get-universal-time))))))

      ;; Transition articles
      (dolist (article articles)
        (orchestrator.spec:transition article :deploying))

      ;; Store results in context
      (orchestrator.core:set-context-value context :merkle-root merkle-root)
      (orchestrator.core:set-context-value context :anchor-results anchor-results)
      (orchestrator.core:set-context-value context :articles articles)

      (log:info () "Blockchain anchoring complete: ~D/~D chains succeeded"
               anchor-count (length *anchor-chains*))

      context)))

;;; ============================================================================
;;; DATA STRUCTURES
;;; ============================================================================

(defstruct anchor-result
  "Result of anchoring to a blockchain"
  chain            ; :ethereum, :arweave, :ipfs
  reference        ; tx-hash, ar:// URI, or CID
  timestamp        ; Universal time
  metadata)        ; Additional chain-specific metadata

;;; ============================================================================
;;; HELPER FUNCTIONS
;;; ============================================================================

(defun get-article-content-hash (article)
  "Get or compute content hash for article

   Returns:
     SHA-256 hash as hex string"
  (or (getf (orchestrator.model:article-metadata article) :content-hash)
      (let* ((content (orchestrator.model:article-content article))
             (content-bytes (babel:string-to-octets content :encoding :utf-8))
             (hash (ironclad:digest-sequence :sha256 content-bytes)))
        (ironclad:byte-array-to-hex-string hash))))

(defun compute-merkle-root (hashes)
  "Compute Merkle root from list of hash strings

   Uses SHA-256 for internal nodes.

   Args:
     hashes: List of hex hash strings

   Returns:
     Merkle root as hex string"
  (if (null hashes)
      ;; Empty tree = hash of empty string
      (ironclad:byte-array-to-hex-string
       (ironclad:digest-sequence :sha256 #()))
      (loop with current = (mapcar #'ironclad:hex-string-to-byte-array hashes)
            while (> (length current) 1)
            do (setf current
                    (loop for (left right) on current by #'cddr
                          collect (let ((right (or right left))) ; Duplicate if odd
                                    (ironclad:digest-sequence
                                     :sha256
                                     (concatenate '(vector (unsigned-byte 8)) left right)))))
            finally (return (ironclad:byte-array-to-hex-string (first current))))))

(defun anchor-to-chain (merkle-root chain)
  "Anchor Merkle root to specific chain

   Args:
     merkle-root: Hash to anchor (hex string)
     chain: Blockchain keyword

   Returns:
     anchor-result struct, or nil if skipped"
  (case chain
    (:ethereum
     (let ((result (orchestrator.blockchain-authority:ethereum-anchor
                    merkle-root :chain :ethereum)))
       (when result
         (make-anchor-result
          :chain :ethereum
          :reference (getf result :tx-hash)
          :timestamp (getf result :timestamp)
          :metadata result))))

    (:arweave
     (let ((result (orchestrator.blockchain-authority:arweave-upload
                    merkle-root :chain :arweave
                    :tags `(("Content-Type" . "text/plain")
                           ("App-Name" . "ORCHESTRATOR")
                           ("Type" . "merkle-root")))))
       (when result
         (make-anchor-result
          :chain :arweave
          :reference (format nil "ar://~A" (getf result :data-hash))
          :timestamp (getf result :timestamp)
          :metadata result))))

    (:ipfs
     (let ((result (orchestrator.blockchain-authority:ipfs-add
                    merkle-root :chain :ipfs :pin t)))
       (when result
         (make-anchor-result
          :chain :ipfs
          :reference (format nil "ipfs://~A" (getf result :cid))
          :timestamp (getf result :timestamp)
          :metadata result))))

    (t nil)))

(defun chain-is-configured-p (chain)
  "Check if chain is configured (has credentials set)

   Args:
     chain: Blockchain keyword

   Returns:
     T if configured, NIL otherwise"
  (case chain
    (:ethereum
     (and orchestrator.blockchain-authority:*ethereum-rpc-url*
          orchestrator.blockchain-authority:*ethereum-private-key*))
    (:arweave
     (and orchestrator.blockchain-authority:*arweave-wallet-path*
          (probe-file orchestrator.blockchain-authority:*arweave-wallet-path*)))
    (:ipfs
     ;; IPFS is considered configured if API URL is set (local or remote)
     orchestrator.blockchain-authority:*ipfs-api-url*)
    (t nil)))

;;; ============================================================================
;;; VERIFICATION FUNCTIONS
;;; ============================================================================

(defun verify-anchor (anchor-result)
  "Verify that an anchor exists on its blockchain

   Args:
     anchor-result: anchor-result struct

   Returns:
     T if verified, NIL otherwise"
  (orchestrator.blockchain-authority:verify-anchor
   (anchor-result-reference anchor-result)
   :chain (anchor-result-chain anchor-result)))

(defun verify-all-anchors (context)
  "Verify all anchors in context

   Args:
     context: Pipeline context with :anchor-results

   Returns:
     Plist of chain -> verification-result"
  (let ((anchor-results (orchestrator.core:get-context-value context :anchor-results)))
    (loop for (chain . result) in anchor-results
          when (anchor-result-p result)
            collect (cons chain (verify-anchor result)))))

;;; ============================================================================
;;; END OF ANCHOR-BLOCKCHAIN.LISP
;;; ============================================================================
