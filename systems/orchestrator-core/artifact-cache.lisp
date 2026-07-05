;;;; systems/orchestrator-core/artifact-cache.lisp
;;;; Content-addressable artifact cache

(in-package :orchestrator.core)

;;; ============================================================================
;;; ARTIFACT CACHE CLASS
;;; ============================================================================

(defclass artifact-cache ()
  ((store
    :accessor cache-store
    :initform (make-hash-table :test 'equal)
    :documentation "Hash table storing artifacts by content hash")
   (metadata
    :accessor cache-metadata
    :initform (make-hash-table :test 'equal)
    :documentation "Hash table storing artifact metadata")
   (max-size
    :accessor cache-max-size
    :initarg :max-size
    :initform nil
    :documentation "Maximum cache size (nil for unlimited)"))
  (:documentation "Content-addressable artifact cache"))

(defmethod print-object ((cache artifact-cache) stream)
  "Print cache in readable format"
  (print-unreadable-object (cache stream :type t :identity t)
    (format stream "~D artifacts" (hash-table-count (cache-store cache)))))

;;; ============================================================================
;;; CACHE CONSTRUCTION
;;; ============================================================================

(defun make-artifact-cache (&key max-size)
  "Create a new artifact cache
  
  Args:
    max-size: Maximum number of artifacts to cache (nil for unlimited)
  
  Returns:
    Artifact cache instance"
  (make-instance 'artifact-cache :max-size max-size))

;;; ============================================================================
;;; CACHE OPERATIONS
;;; ============================================================================

(defun cache-artifact (cache artifact)
  "Add artifact to cache
  
  Args:
    cache: Artifact cache
    artifact: Artifact to cache
  
  Returns:
    Content hash of cached artifact"
  (let ((hash (orchestrator.spec:artifact-hash artifact)))
    (unless hash
      (error "Cannot cache artifact without hash"))
    
    ;; Check size limit
    (when (and (cache-max-size cache)
              (>= (hash-table-count (cache-store cache))
                  (cache-max-size cache)))
      (evict-lru-artifact cache))
    
    ;; Store artifact
    (setf (gethash hash (cache-store cache)) artifact)
    
    ;; Store metadata
    (setf (gethash hash (cache-metadata cache))
          (list :cached-at (orchestrator.time:now :source :system)
                :access-count 0
                :last-access (orchestrator.time:now :source :system)))
    
    hash))

(defun lookup-artifact (cache hash)
  "Retrieve artifact from cache by hash
  
  Args:
    cache: Artifact cache
    hash: Content hash
  
  Returns:
    Artifact or NIL if not found"
  (let ((artifact (gethash hash (cache-store cache))))
    (when artifact
      ;; Update access metadata
      (let ((metadata (gethash hash (cache-metadata cache))))
        (when metadata
          (incf (getf metadata :access-count))
          (setf (getf metadata :last-access) (orchestrator.time:now :source :system)))))
    artifact))

(defun cache-has-artifact-p (cache hash)
  "Check if cache has artifact with given hash
  
  Args:
    cache: Artifact cache
    hash: Content hash
  
  Returns:
    T if artifact exists in cache, NIL otherwise"
  (nth-value 1 (gethash hash (cache-store cache))))

(defun cache-clear (cache)
  "Clear all artifacts from cache
  
  Args:
    cache: Artifact cache
  
  Returns:
    NIL"
  (clrhash (cache-store cache))
  (clrhash (cache-metadata cache))
  nil)

(defun cache-size (cache)
  "Get current cache size
  
  Args:
    cache: Artifact cache
  
  Returns:
    Number of cached artifacts"
  (hash-table-count (cache-store cache)))

;;; ============================================================================
;;; EVICTION POLICIES
;;; ============================================================================

(defun evict-lru-artifact (cache)
  "Evict least recently used artifact from cache
  
  Args:
    cache: Artifact cache
  
  Returns:
    Hash of evicted artifact or NIL"
  (let ((lru-hash nil)
        (lru-time most-positive-fixnum))
    
    ;; Find least recently used
    (maphash (lambda (hash metadata)
              (let ((last-access (getf metadata :last-access)))
                (when (< last-access lru-time)
                  (setf lru-time last-access
                        lru-hash hash))))
            (cache-metadata cache))
    
    ;; Evict if found
    (when lru-hash
      (remhash lru-hash (cache-store cache))
      (remhash lru-hash (cache-metadata cache)))
    
    lru-hash))

(defun evict-oldest-artifact (cache)
  "Evict oldest artifact from cache
  
  Args:
    cache: Artifact cache
  
  Returns:
    Hash of evicted artifact or NIL"
  (let ((oldest-hash nil)
        (oldest-time most-positive-fixnum))
    
    ;; Find oldest
    (maphash (lambda (hash metadata)
              (let ((cached-at (getf metadata :cached-at)))
                (when (< cached-at oldest-time)
                  (setf oldest-time cached-at
                        oldest-hash hash))))
            (cache-metadata cache))
    
    ;; Evict if found
    (when oldest-hash
      (remhash oldest-hash (cache-store cache))
      (remhash oldest-hash (cache-metadata cache)))
    
    oldest-hash))

;;; ============================================================================
;;; CACHE STATISTICS
;;; ============================================================================

(defun cache-statistics (cache)
  "Get cache statistics
  
  Args:
    cache: Artifact cache
  
  Returns:
    Plist with cache statistics"
  (let ((total-artifacts 0)
        (total-accesses 0)
        (oldest-time most-positive-fixnum)
        (newest-time 0))
    
    (maphash (lambda (hash metadata)
              (declare (ignore hash))
              (incf total-artifacts)
              (incf total-accesses (getf metadata :access-count))
              (let ((cached-at (getf metadata :cached-at)))
                (when (< cached-at oldest-time)
                  (setf oldest-time cached-at))
                (when (> cached-at newest-time)
                  (setf newest-time cached-at))))
            (cache-metadata cache))
    
    (list :artifact-count total-artifacts
          :total-accesses total-accesses
          :average-accesses (if (zerop total-artifacts)
                               0.0
                               (/ total-accesses total-artifacts))
          :oldest-artifact (if (= oldest-time most-positive-fixnum)
                              nil
                              oldest-time)
          :newest-artifact (if (zerop newest-time)
                              nil
                              newest-time))))
