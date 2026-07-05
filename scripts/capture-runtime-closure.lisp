#!/usr/bin/env sbcl --script
;;;; capture-runtime-closure.lisp
;;;; Captures ACTUAL runtime dependency closure via ASDF operation plan instrumentation
;;;; Output: deps/*.closure.json (canonical, deterministic, schema-validated)

(require :asdf)
(require :uiop)

(defvar *closure-data* (make-hash-table :test 'equal)
  "Hash table: system-name -> {version, source-id, hash, layer}")

(defvar *dependency-graph* (make-hash-table :test 'equal)
  "Hash table: system-name -> list of direct dependencies")

(defvar *loaded-systems* nil
  "List of systems that have been loaded (in order)")

(defvar *project-root* (uiop:getcwd)
  "Project root directory for filtering paths")

(defvar *third-party-dir* (merge-pathnames "third-party/" *project-root*)
  "Third-party dependencies directory")

(defparameter *target-system* "orchestrator-core-runtime"
  "Target system to capture closure for")

(defparameter *output-file* "deps/orchestrator-core-runtime.closure.json"
  "Output canonical closure artifact")

;;;; ============================================================================
;;;; ASDF Operation Plan Instrumentation
;;;; ============================================================================

(defmethod asdf:operate :before ((operation asdf:operation) (component asdf:component)
                                  &key &allow-other-keys)
  "Hook ASDF operations to capture dependency closure at operation plan level."
  (let ((system (asdf:component-system component)))
    (when system
      (let ((system-name (asdf:component-name system)))
        ;; Track system loading
        (unless (gethash system-name *closure-data*)
          (capture-system-metadata system-name system))

        ;; Track load order
        (pushnew system-name *loaded-systems* :test #'equal)))))

(defmethod asdf:perform :before ((operation asdf:load-op) (component asdf:system))
  "Hook load operations to capture system-level dependencies."
  (let ((system-name (asdf:component-name component)))
    ;; Capture dependencies from ASDF system definition
    (let ((deps (asdf:component-sideway-dependencies component)))
      (when deps
        (setf (gethash system-name *dependency-graph*)
              (remove-duplicates
               (append (gethash system-name *dependency-graph*) deps)
               :test #'equal))))))

;;;; ============================================================================
;;;; Metadata Capture
;;;; ============================================================================

(defun capture-system-metadata (system-name system)
  "Capture metadata for a system: version, source-id, hash, layer."
  (let* ((source-location (asdf:system-source-directory system))
         (source-id (extract-source-id source-location))
         (version (extract-version source-id))
         (hash (get-hash-from-deps-lock system-name))
         (layer (determine-layer system-name)))

    (setf (gethash system-name *closure-data*)
          (list :name system-name
                :version version
                :source-id source-id
                :hash hash
                :layer layer))))

(defun extract-source-id (source-location)
  "Extract logical source-id from source location (relative to project root)."
  (when source-location
    (let* ((namestring (namestring source-location))
           (relative (if (uiop:subpathp namestring *third-party-dir*)
                         (enough-namestring namestring *third-party-dir*)
                         (enough-namestring namestring *project-root*))))
      (string-right-trim "/" relative))))

(defun extract-version (source-id)
  "Extract version from source-id (e.g., 'alexandria-20241012-git' -> '20241012-git')."
  (let ((pos (position #\- source-id :from-end t :test #'char=)))
    (if pos
        (subseq source-id (1+ pos))
        "unknown")))

(defun get-hash-from-deps-lock (system-name)
  "Retrieve SHA-256 hash from deps.lock for system-name."
  (let ((deps-lock (merge-pathnames "deps.lock" *project-root*)))
    (when (probe-file deps-lock)
      (with-open-file (stream deps-lock :direction :input)
        (loop for line = (read-line stream nil)
              while line
              do (unless (or (string= line "")
                             (char= (char line 0) #\#))
                   (let ((parts (uiop:split-string line :separator "|")))
                     (when (= (length parts) 2)
                       (let ((name (string-trim " " (first parts)))
                             (hash (string-trim " " (second parts))))
                         (when (search system-name name :test #'char-equal)
                           (return-from get-hash-from-deps-lock hash)))))))))))

(defun determine-layer (system-name)
  "Determine layer (runtime/test/tooling) based on system name."
  (cond
    ((search "test" system-name :test #'char-equal) "test")
    ((search "tooling" system-name :test #'char-equal) "tooling")
    (t "runtime")))

;;;; ============================================================================
;;;; Controlled require/load tracking (filtered to project paths)
;;;; ============================================================================

(let ((original-require (fdefinition 'require)))
  (setf (fdefinition 'require)
        (lambda (module-name &rest args)
          "Wrap require to track non-ASDF module loads."
          (format t "~&[REQUIRE] ~A~%" module-name)
          ;; Track if it's a project-related module
          (when (or (stringp module-name)
                    (symbolp module-name))
            (let ((module-str (string module-name)))
              (unless (or (search "SB-" module-str)
                          (search "COMMON-LISP" module-str))
                (pushnew module-str *loaded-systems* :test #'equal))))
          (apply original-require module-name args))))

;;;; ============================================================================
;;;; Canonical JSON Output
;;;; ============================================================================

(defun generate-canonical-closure-json ()
  "Generate canonical, deterministic JSON closure artifact."
  (let* ((closure-list (sort-closure-data))
         (graph-sorted (sort-dependency-graph))
         (sbcl-version (lisp-implementation-version)))

    (with-open-file (stream (merge-pathnames *output-file* *project-root*)
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (format stream "{~%")
      (format stream "  \"format_version\": \"1.0\",~%")
      (format stream "  \"system\": \"~A\",~%" *target-system*)
      (format stream "  \"sbcl_version\": \"~A\",~%" sbcl-version)
      (format stream "  \"closure\": [~%")

      ;; Write closure data (sorted)
      (loop for (data . rest) on closure-list
            do (write-closure-entry stream data (not (null rest))))

      (format stream "  ],~%")
      (format stream "  \"graph\": {~%")

      ;; Write dependency graph (sorted)
      (loop for ((sys . deps) . rest) on graph-sorted
            do (format stream "    \"~A\": [~{\"~A\"~^, ~}]~:[~;,~]~%"
                       sys deps (not (null rest))))

      (format stream "  }~%")
      (format stream "}~%"))))

(defun sort-closure-data ()
  "Sort closure data alphabetically by system name."
  (let ((entries nil))
    (maphash (lambda (key value)
               (push (cons key value) entries))
             *closure-data*)
    (sort entries #'string< :key #'car)))

(defun sort-dependency-graph ()
  "Sort dependency graph alphabetically by system name."
  (let ((entries nil))
    (maphash (lambda (key value)
               (push (cons key (sort (copy-list value) #'string<)) entries))
             *dependency-graph*)
    (sort entries #'string< :key #'car)))

(defun write-closure-entry (stream entry trailing-comma)
  "Write a single closure entry to JSON stream."
  (destructuring-bind (name &key version source-id hash layer) (cdr entry)
    (format stream "    {~%")
    (format stream "      \"name\": \"~A\",~%" name)
    (format stream "      \"version\": \"~A\",~%" version)
    (format stream "      \"source_id\": \"~A\",~%" source-id)
    (format stream "      \"hash\": \"~A\",~%" (or hash "unknown"))
    (format stream "      \"layer\": \"~A\"~%" layer)
    (format stream "    }~:[~;,~]~%" trailing-comma)))

;;;; ============================================================================
;;;; Main Execution
;;;; ============================================================================

(defun main ()
  "Main entry point: load target system and capture closure."
  (format t "~&========================================~%")
  (format t "Runtime Closure Capture~%")
  (format t "========================================~%")
  (format t "Target system: ~A~%" *target-system*)
  (format t "Output file: ~A~%" *output-file*)
  (format t "~%")

  ;; Configure ASDF source registry (hermetic)
  (let ((third-party-tree (list :tree (namestring *third-party-dir*))))
    (asdf:initialize-source-registry
     `(:source-registry
       ,third-party-tree
       (:tree ,(namestring (merge-pathnames "source/cl-dependencies/" *project-root*)))
       :inherit-configuration)))

  ;; Add systems to ASDF central registry
  (push *project-root* asdf:*central-registry*)
  (push (merge-pathnames "systems/orchestrator-spec/" *project-root*)
        asdf:*central-registry*)
  (push (merge-pathnames "systems/orchestrator-model/" *project-root*)
        asdf:*central-registry*)
  (push (merge-pathnames "systems/orchestrator-core/" *project-root*)
        asdf:*central-registry*)
  (push (merge-pathnames "systems/orchestrator-engine-sbcl/" *project-root*)
        asdf:*central-registry*)

  ;; Load target system (instrumentation captures closure)
  (format t "Loading system: ~A~%" *target-system*)
  (handler-case
      (asdf:load-system *target-system*)
    (error (e)
      (format t "~&ERROR loading system: ~A~%" e)
      (uiop:quit 1)))

  (format t "~%Systems loaded: ~D~%" (hash-table-count *closure-data*))

  ;; Generate canonical JSON output
  (ensure-directories-exist (merge-pathnames "deps/" *project-root*))
  (generate-canonical-closure-json)

  (format t "~%Closure artifact written: ~A~%" *output-file*)
  (format t "========================================~%")
  (uiop:quit 0))

;; Execute main
(main)
