;;;; systems/orchestrator-engine-sbcl/backends/ipfs.lisp
;;;; ============================================================================
;;;; IPFS BACKEND - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; Uses orchestrator.blockchain-authority for all IPFS operations.
;;;; No subprocess calls - pure Lisp HTTP API.
;;;;
;;;; DARPA-GRADE: Self-contained, deterministic, auditable.
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

;;; ============================================================================
;;; IPFS BACKEND CLASS
;;; ============================================================================

(defclass ipfs-backend ()
  ((api-url
    :accessor backend-api-url
    :initarg :api-url
    :initform nil
    :documentation "IPFS API URL (nil = use global config)"))
  (:documentation "IPFS storage backend using pure Lisp authority"))

;;; ============================================================================
;;; BACKEND PROTOCOL METHODS
;;; ============================================================================

(defmethod backend-upload ((backend ipfs-backend) data &key content-type tags)
  "Upload data to IPFS

   Uses orchestrator.blockchain-authority:ipfs-add

   Args:
     backend: IPFS backend instance
     data: Data to upload (string or byte vector)
     content-type: MIME type (unused for IPFS)
     tags: Metadata tags (unused for IPFS)

   Returns:
     IPFS CID string, or nil if not available"
  (declare (ignore content-type tags))
  ;; Override global config if backend has specific settings
  (let ((orchestrator.blockchain-authority:*ipfs-api-url*
          (or (backend-api-url backend)
              orchestrator.blockchain-authority:*ipfs-api-url*)))

    ;; Call the authority function
    (let ((result (orchestrator.blockchain-authority:ipfs-add
                   data
                   :chain :ipfs
                   :pin t)))
      (when result
        (getf result :cid)))))

(defmethod backend-verify ((backend ipfs-backend) cid)
  "Verify content exists on IPFS

   Args:
     backend: IPFS backend instance
     cid: Content ID to verify

   Returns:
     T if exists, NIL otherwise"
  (let ((orchestrator.blockchain-authority:*ipfs-api-url*
          (or (backend-api-url backend)
              orchestrator.blockchain-authority:*ipfs-api-url*)))
    (orchestrator.blockchain-authority:verify-anchor cid :chain :ipfs)))

(defmethod backend-configured-p ((backend ipfs-backend))
  "Check if IPFS backend is available

   Returns:
     T if IPFS API URL is set"
  (or (backend-api-url backend)
      orchestrator.blockchain-authority:*ipfs-api-url*))

;;; ============================================================================
;;; FACTORY FUNCTION
;;; ============================================================================

(defun make-ipfs-backend (&key api-url)
  "Create IPFS backend instance

   Args:
     api-url: IPFS HTTP API URL (optional, uses env if nil)

   Returns:
     Configured ipfs-backend instance"
  (make-instance 'ipfs-backend
                 :api-url api-url))

;;; ============================================================================
;;; END OF IPFS.LISP
;;; ============================================================================
