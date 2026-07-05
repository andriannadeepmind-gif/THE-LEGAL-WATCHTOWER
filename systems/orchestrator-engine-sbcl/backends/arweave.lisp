;;;; systems/orchestrator-engine-sbcl/backends/arweave.lisp
;;;; ============================================================================
;;;; ARWEAVE BACKEND - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; Uses orchestrator.blockchain-authority for all Arweave operations.
;;;; No JavaScript, no arweave-js, no subprocess calls - pure Lisp.
;;;;
;;;; DARPA-GRADE: Self-contained, deterministic, auditable.
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; ARWEAVE BACKEND CLASS
;;; ============================================================================

(defclass arweave-backend ()
  ((gateway-url
    :accessor backend-gateway-url
    :initarg :gateway-url
    :initform nil
    :documentation "Arweave gateway URL (nil = use global config)")
   (wallet-path
    :accessor backend-wallet-path
    :initarg :wallet-path
    :initform nil
    :documentation "Path to JWK wallet file (nil = use global config)"))
  (:documentation "Arweave permanent storage backend using pure Lisp authority"))

;;; ============================================================================
;;; BACKEND PROTOCOL METHODS
;;; ============================================================================

(defmethod backend-upload ((backend arweave-backend) data &key content-type tags)
  "Upload data to Arweave permanent storage

   Uses orchestrator.blockchain-authority:arweave-upload

   Args:
     backend: Arweave backend instance
     data: Data to upload (string or byte vector)
     content-type: MIME type for data
     tags: Alist of name-value tag pairs

   Returns:
     Arweave transaction ID string, or nil if not configured"
  ;; Override global config if backend has specific settings
  (let ((orchestrator.blockchain-authority:*arweave-gateway-url*
          (or (backend-gateway-url backend)
              orchestrator.blockchain-authority:*arweave-gateway-url*))
        (orchestrator.blockchain-authority:*arweave-wallet-path*
          (or (backend-wallet-path backend)
              orchestrator.blockchain-authority:*arweave-wallet-path*)))

    ;; Call the authority function
    (let ((result (orchestrator.blockchain-authority:arweave-upload
                   data
                   :chain :arweave
                   :content-type content-type
                   :tags tags)))
      (when result
        ;; Return formatted transaction reference
        (format nil "ar://~A" (getf result :data-hash))))))

(defmethod backend-verify ((backend arweave-backend) tx-id)
  "Verify transaction exists on Arweave

   Args:
     backend: Arweave backend instance
     tx-id: Transaction ID to verify

   Returns:
     T if exists, NIL otherwise"
  (let ((orchestrator.blockchain-authority:*arweave-gateway-url*
          (or (backend-gateway-url backend)
              orchestrator.blockchain-authority:*arweave-gateway-url*)))
    (orchestrator.blockchain-authority:verify-anchor tx-id :chain :arweave)))

(defmethod backend-get-data ((backend arweave-backend) tx-id)
  "Retrieve data from Arweave by transaction ID

   Args:
     backend: Arweave backend instance
     tx-id: Transaction ID

   Returns:
     Data as byte vector, or nil if not found"
  (let ((orchestrator.blockchain-authority:*arweave-gateway-url*
          (or (backend-gateway-url backend)
              orchestrator.blockchain-authority:*arweave-gateway-url*)))
    (orchestrator.blockchain-authority:arweave-get-data tx-id)))

(defmethod backend-configured-p ((backend arweave-backend))
  "Check if Arweave backend is properly configured

   Returns:
     T if wallet path is available"
  (let ((wallet-path (or (backend-wallet-path backend)
                         orchestrator.blockchain-authority:*arweave-wallet-path*)))
    (and wallet-path (probe-file wallet-path))))

;;; ============================================================================
;;; FACTORY FUNCTION
;;; ============================================================================

(defun make-arweave-backend (&key gateway-url wallet-path)
  "Create Arweave backend instance

   Args:
     gateway-url: Arweave gateway URL (optional, uses env if nil)
     wallet-path: Path to JWK wallet (optional, uses env if nil)

   Returns:
     Configured arweave-backend instance"
  (make-instance 'arweave-backend
                 :gateway-url gateway-url
                 :wallet-path wallet-path))

;;; ============================================================================
;;; END OF ARWEAVE.LISP
;;; ============================================================================
