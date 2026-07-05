;;;; systems/orchestrator-engine-sbcl/backends/mock.lisp
;;;; Mock blockchain backend for testing

(in-package :orchestrator.engine.sbcl)

(defclass mock-backend ()
  ((anchored-hashes
    :accessor backend-anchored-hashes
    :initform (make-hash-table :test 'equal)
    :documentation "Hash table of anchored content hashes"))
  (:documentation "Mock blockchain backend"))

(defmethod backend-anchor ((backend mock-backend) hash)
  "Anchor hash to mock backend
  
  Args:
    backend: Mock backend instance
    hash: Content hash to anchor
  
  Returns:
    Mock transaction ID"
  (let ((tx-id (format nil "mock-tx-~8,'0X" (random (expt 2 32)))))
    (setf (gethash hash (backend-anchored-hashes backend))
          (list :tx-id tx-id
                :timestamp (orchestrator.time:now :source :system)))
    tx-id))

(defmethod backend-retrieve ((backend mock-backend) hash)
  "Retrieve anchoring info from mock backend
  
  Args:
    backend: Mock backend instance
    hash: Content hash
  
  Returns:
    Anchoring info or NIL"
  (gethash hash (backend-anchored-hashes backend)))
