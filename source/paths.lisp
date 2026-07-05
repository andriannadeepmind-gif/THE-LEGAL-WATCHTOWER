;;;; paths.lisp
;;;; Path abstraction layer - Zero hardcoded paths
;;;; All filesystem paths must go through this module

(defpackage #:orchestrator.paths
  (:use :cl)
  (:import-from :alexandria
                #:hash-table-keys)
  (:import-from :uiop
                #:getenv
                #:getcwd
                #:merge-pathnames*
                #:default-temporary-directory)
  (:export #:resolve-path
           #:register-path
           #:initialize-paths
           #:path-exists-p
           #:*path-registry*
           #:ensure-directory
           #:with-temp-file
           #:make-relative-path))

(in-package :orchestrator.paths)

;;;; ========================================================================
;;;; CONSTANTS
;;;; ========================================================================

(defparameter +default-base-path+ "/app"
  "Default base path for application")

(defparameter +max-path-components+ 20
  "Maximum number of path components to merge")

;;;; ========================================================================
;;;; PATH REGISTRY
;;;; ========================================================================

(defparameter *path-registry* (make-hash-table :test 'eq)
  "Central registry of all configured paths")

(defparameter *default-paths* nil
  "Default path configuration")

;;;; ========================================================================
;;;; PATH SECURITY (DARPA-GRADE)
;;;; ========================================================================

(define-condition path-traversal-error (error)
  ((attempted-path :initarg :attempted-path :reader attempted-path)
   (base-path :initarg :base-path :reader base-path))
  (:report (lambda (c s)
             (format s "Path traversal attack blocked: ~A escapes base ~A"
                     (attempted-path c) (base-path c)))))

(defun contains-traversal-p (path-string)
  "Check if path string contains directory traversal sequences"
  (or (search ".." (namestring path-string))
      (search "~" (namestring path-string))  ; Home directory expansion
      (and (> (length (namestring path-string)) 0)
           (char= (char (namestring path-string) 0) #\/))))  ; Absolute path

(defun path-within-base-p (resolved-path base-path)
  "Verify resolved path is within base directory (canonicalized check)"
  (let ((resolved-str (namestring (truename resolved-path)))
        (base-str (namestring (truename base-path))))
    ;; Resolved path must start with base path
    (and (>= (length resolved-str) (length base-str))
         (string= base-str (subseq resolved-str 0 (length base-str))))))

(defun validate-path-component (component base-path)
  "Validate a single path component against traversal attacks
   Signals path-traversal-error if attack detected"
  (let ((comp-str (etypecase component
                    (string component)
                    (pathname (namestring component)))))
    (when (contains-traversal-p comp-str)
      (error 'path-traversal-error
             :attempted-path comp-str
             :base-path base-path))))

;;;; ========================================================================
;;;; PATH RESOLUTION
;;;; ========================================================================

(defun resolve-path (key &rest components)
  "Resolve a path from registry and optional path components.

   DARPA-GRADE: Validates all components against path traversal attacks.
   Rejects: '..' sequences, '~' expansion, absolute paths in components.

   Example: (resolve-path :scripts \"pdf_parser.py\")
            => \"/app/scripts/pdf_parser.py\""
  (declare (type symbol key))
  (declare (type list components))
  (declare (optimize (speed 3) (safety 1)))
  (check-type key symbol)
  (let ((base-path (gethash key *path-registry*)))
    (unless base-path
      (error "Path key ~A not registered. Available keys: ~A"
             key
             (hash-table-keys *path-registry*)))
    (if components
        (progn
          ;; Validate each component against traversal attacks
          (dolist (comp components)
            (validate-path-component comp base-path))
          (let ((resolved (apply #'merge-pathnames*
                                 (reverse (cons base-path
                                               (mapcar #'pathname components))))))
            ;; Double-check: verify resolved path is within base
            ;; (handles edge cases where merge could escape)
            (when (probe-file resolved)
              (unless (path-within-base-p resolved base-path)
                (error 'path-traversal-error
                       :attempted-path resolved
                       :base-path base-path)))
            resolved))
        base-path)))

(defun register-path (key path)
  "Register a path in the global registry"
  (declare (type symbol key))
  (declare (type (or string pathname) path))
  (declare (optimize (speed 3) (safety 1)))
  (check-type key symbol)
  (setf (gethash key *path-registry*)
        (pathname path)))

(defun path-exists-p (key)
  "Check if a path key is registered"
  (declare (type symbol key))
  (declare (optimize (speed 3) (safety 1)))
  (nth-value 1 (gethash key *path-registry*)))

;;;; ========================================================================
;;;; INITIALIZATION
;;;; ========================================================================

(defun initialize-paths (&key (base-dir nil))
  "Initialize path registry with defaults or config-provided values"
  (declare (type (or null string pathname) base-dir))
  (declare (optimize (speed 3) (safety 1)))
  (let ((root (or base-dir
                  (getenv "ORCHESTRATOR_ROOT")
                  "/app"
                  (getcwd))))
    (setf *default-paths*
          `((:base    . ,(pathname root))
            (:config  . ,(merge-pathnames* "configs/" root))
            (:output  . ,(merge-pathnames* "output/" root))
            (:input   . ,(merge-pathnames* "input/" root))
            (:scripts . ,(merge-pathnames* "scripts/" root))
            (:shapes  . ,(merge-pathnames* "shapes/" root))
            (:temp    . ,(pathname (default-temporary-directory)))
            (:logs    . ,(merge-pathnames* "logs/" root))
            (:data    . ,(merge-pathnames* "data/" root))
            (:cache   . ,(merge-pathnames* "cache/" root))
            (:source  . ,(merge-pathnames* "source/" root))
            (:tests   . ,(merge-pathnames* "tests/" root))))
    
    ;; Register all default paths
    (loop for (key . path) in *default-paths*
          do (register-path key path))
    
    (values *path-registry*)))

;;;; ========================================================================
;;;; UTILITY FUNCTIONS
;;;; ========================================================================

(defun ensure-directory (key &rest components)
  "Ensure directory exists for given path key"
  (declare (type symbol key))
  (declare (type list components))
  (declare (optimize (speed 3) (safety 1)))
  (let ((dir (apply #'resolve-path key components)))
    (ensure-directories-exist dir)
    dir))

(defmacro with-temp-file ((var &key (directory :temp) (prefix "orch-") (suffix ".tmp")) 
                          &body body)
  "Execute body with a temporary file path bound to VAR"
  `(let ((,var (merge-pathnames* 
                (format nil "~A~A~A" 
                        ,prefix 
                        (orchestrator.time:get-unix-timestamp)
                        ,suffix)
                (resolve-path ,directory))))
     (unwind-protect
          (progn ,@body)
       (when (probe-file ,var)
         (delete-file ,var)))))

(defun make-relative-path (key relative-path)
  "Make a relative path from a base key

   DARPA-GRADE: Validates relative-path against path traversal attacks."
  (declare (type symbol key))
  (declare (type (or string pathname) relative-path))
  (declare (optimize (speed 3) (safety 1)))
  (let ((base-path (resolve-path key)))
    ;; Validate against traversal attacks
    (validate-path-component relative-path base-path)
    (merge-pathnames* relative-path base-path)))

;;;; ========================================================================
;;;; MIGRATION UTILITIES
;;;; ========================================================================

(defun migrate-hardcoded-path (old-path)
  "Convert a hardcoded path to path-resolved equivalent.
   For development/migration purposes only."
  (cond
    ((search "/scripts/" old-path) 
     (list :scripts (file-namestring old-path)))
    ((search "/shapes/" old-path)
     (list :shapes (file-namestring old-path)))
    ((search "/output/" old-path)
     (list :output (file-namestring old-path)))
    ((search "/config" old-path)
     (list :config (file-namestring old-path)))
    ((search "/input/" old-path)
     (list :input (file-namestring old-path)))
    (t 
     (warn "Cannot migrate path: ~A" old-path)
     nil)))

;;;; ========================================================================
;;;; INITIALIZE ON LOAD
;;;; ========================================================================

;; Initialize with defaults when loaded
(initialize-paths)
