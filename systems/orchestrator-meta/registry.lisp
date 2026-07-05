;;;; systems/orchestrator-meta/registry.lisp
;;;; Global registries for pipelines, corpora, backends

(in-package :orchestrator.meta)

;;; ============================================================================
;;; GLOBAL REGISTRIES
;;; ============================================================================

(defvar *pipeline-registry* (make-hash-table :test 'eq)
  "Global registry of pipelines")

(defvar *corpus-registry* (make-hash-table :test 'eq)
  "Global registry of corpora")

(defvar *backend-registry* (make-hash-table :test 'eq)
  "Global registry of blockchain/storage backends")

;;; ============================================================================
;;; REGISTRATION FUNCTIONS
;;; ============================================================================

(defun register-pipeline (name pipeline)
  "Register a pipeline
  
  Args:
    name: Pipeline name (symbol)
    pipeline: Pipeline object
  
  Returns:
    Pipeline"
  (setf (gethash name *pipeline-registry*) pipeline))

(defun register-corpus (name corpus)
  "Register a corpus
  
  Args:
    name: Corpus name (symbol)
    corpus: Corpus object
  
  Returns:
    Corpus"
  (setf (gethash name *corpus-registry*) corpus))

(defun register-backend (name backend)
  "Register a backend
  
  Args:
    name: Backend name (symbol)
    backend: Backend object
  
  Returns:
    Backend"
  (setf (gethash name *backend-registry*) backend))

;;; ============================================================================
;;; RETRIEVAL FUNCTIONS
;;; ============================================================================

(defun get-pipeline (name)
  "Get pipeline by name
  
  Args:
    name: Pipeline name (symbol)
  
  Returns:
    Pipeline object or NIL"
  (gethash name *pipeline-registry*))

(defun get-corpus (name)
  "Get corpus by name
  
  Args:
    name: Corpus name (symbol)
  
  Returns:
    Corpus object or NIL"
  (gethash name *corpus-registry*))

(defun get-backend (name)
  "Get backend by name
  
  Args:
    name: Backend name (symbol)
  
  Returns:
    Backend object or NIL"
  (gethash name *backend-registry*))

;;; ============================================================================
;;; LISTING FUNCTIONS
;;; ============================================================================

(defun list-pipelines ()
  "List all registered pipeline names
  
  Returns:
    List of pipeline names"
  (alexandria:hash-table-keys *pipeline-registry*))

(defun list-corpora ()
  "List all registered corpus names
  
  Returns:
    List of corpus names"
  (alexandria:hash-table-keys *corpus-registry*))

(defun list-backends ()
  "List all registered backend names
  
  Returns:
    List of backend names"
  (alexandria:hash-table-keys *backend-registry*))
