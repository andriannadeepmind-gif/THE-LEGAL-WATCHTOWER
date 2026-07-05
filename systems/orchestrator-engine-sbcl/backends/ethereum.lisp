;;;; systems/orchestrator-engine-sbcl/backends/ethereum.lisp
;;;; ============================================================================
;;;; ETHEREUM BACKEND - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; Uses orchestrator.blockchain-authority for all Ethereum operations.
;;;; No Python, no web3.py, no subprocess calls - pure Lisp.
;;;;
;;;; DARPA-GRADE: Self-contained, deterministic, auditable.
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; ETHEREUM BACKEND CLASS
;;; ============================================================================

(defclass ethereum-backend ()
  ((rpc-url
    :accessor backend-rpc-url
    :initarg :rpc-url
    :initform nil
    :documentation "Ethereum RPC URL (nil = use global config)")
   (private-key
    :accessor backend-private-key
    :initarg :private-key
    :initform nil
    :documentation "Private key hex (nil = use global config)")
   (chain-id
    :accessor backend-chain-id
    :initarg :chain-id
    :initform 1
    :documentation "Chain ID (1=mainnet, 5=goerli, 11155111=sepolia)"))
  (:documentation "Ethereum blockchain backend using pure Lisp authority"))

;;; ============================================================================
;;; BACKEND PROTOCOL METHODS
;;; ============================================================================

(defmethod backend-anchor ((backend ethereum-backend) hash)
  "Anchor hash to Ethereum blockchain

   Uses orchestrator.blockchain-authority:ethereum-anchor

   Args:
     backend: Ethereum backend instance
     hash: Content hash (string or byte vector)

   Returns:
     Transaction hash string, or nil if not configured"
  ;; Override global config if backend has specific settings
  (let ((orchestrator.blockchain-authority:*ethereum-rpc-url*
          (or (backend-rpc-url backend)
              orchestrator.blockchain-authority:*ethereum-rpc-url*))
        (orchestrator.blockchain-authority:*ethereum-private-key*
          (or (backend-private-key backend)
              orchestrator.blockchain-authority:*ethereum-private-key*))
        (orchestrator.blockchain-authority:*ethereum-chain-id*
          (backend-chain-id backend)))

    ;; Call the authority function
    (let ((result (orchestrator.blockchain-authority:ethereum-anchor
                   hash
                   :chain :ethereum
                   :wait-confirmation t)))
      (when result
        (getf result :tx-hash)))))

(defmethod backend-verify ((backend ethereum-backend) tx-hash)
  "Verify transaction exists and is confirmed

   Args:
     backend: Ethereum backend instance
     tx-hash: Transaction hash to verify

   Returns:
     T if confirmed, NIL otherwise"
  (let ((orchestrator.blockchain-authority:*ethereum-rpc-url*
          (or (backend-rpc-url backend)
              orchestrator.blockchain-authority:*ethereum-rpc-url*)))
    (orchestrator.blockchain-authority:verify-anchor tx-hash :chain :ethereum)))

(defmethod backend-get-balance ((backend ethereum-backend) address)
  "Get balance for address in Wei

   Args:
     backend: Ethereum backend instance
     address: Ethereum address (0x prefixed)

   Returns:
     Balance in Wei as integer"
  (let ((orchestrator.blockchain-authority:*ethereum-rpc-url*
          (or (backend-rpc-url backend)
              orchestrator.blockchain-authority:*ethereum-rpc-url*)))
    (orchestrator.blockchain-authority:ethereum-get-balance address)))

(defmethod backend-configured-p ((backend ethereum-backend))
  "Check if Ethereum backend is properly configured

   Returns:
     T if both RPC URL and private key are available"
  (and (or (backend-rpc-url backend)
           orchestrator.blockchain-authority:*ethereum-rpc-url*)
       (or (backend-private-key backend)
           orchestrator.blockchain-authority:*ethereum-private-key*)))

;;; ============================================================================
;;; FACTORY FUNCTION
;;; ============================================================================

(defun make-ethereum-backend (&key rpc-url private-key (chain-id 1))
  "Create Ethereum backend instance

   Args:
     rpc-url: Ethereum RPC endpoint (optional, uses env if nil)
     private-key: Private key hex (optional, uses env if nil)
     chain-id: Chain ID (default 1 = mainnet)

   Returns:
     Configured ethereum-backend instance"
  (make-instance 'ethereum-backend
                 :rpc-url rpc-url
                 :private-key private-key
                 :chain-id chain-id))

;;; ============================================================================
;;; END OF ETHEREUM.LISP
;;; ============================================================================
