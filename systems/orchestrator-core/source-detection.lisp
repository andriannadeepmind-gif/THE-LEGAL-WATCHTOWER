;;;; systems/orchestrator-core/source-detection.lisp
;;;; Source Detection - Generic runtime source type detection
;;;;
;;;; ARCHITECTURE (Production-grade):
;;;;   - Generic functions that take paths as parameters
;;;;   - NO hardcoded paths (domain packages provide them)
;;;;   - Environment variables provide runtime override
;;;;   - Full logging and validation
;;;;   - Type declarations for performance
;;;;
;;;; Environment Variables:
;;;;   ORCHESTRATOR_PDF_INPUT_DIR - Override PDF input directory
;;;;   ORCHESTRATOR_JSON_PATH - Override JSON fallback path

(in-package :orchestrator.core)

;;; ============================================================================
;;; TYPE DECLARATIONS
;;; ============================================================================

(declaim (ftype (function ((or pathname string null)) (or pathname null)) find-pdf-in-dir))
(declaim (ftype (function (&key (:pdf-dir t) (:pdf-path t) (:json-path t)) (or list null)) detect-source-config))
(declaim (ftype (function (&key (:pdf-dir t) (:pdf-path t) (:json-path t)) list) get-runtime-source-config))

;;; ============================================================================
;;; ENVIRONMENT VARIABLE ACCESS
;;; ============================================================================

(defun get-env (name &optional default)
  "Get environment variable value with optional default.

   Args:
     name: Environment variable name (string)
     default: Default value if not set

   Returns:
     Environment variable value or default"
  (declare (type string name))
  (or (uiop:getenv name) default))

(defun %non-blank (s)
  "Return S only when it is a non-blank string, else NIL. An env var set to the
   empty string (e.g. docker-compose's `VAR: ${VAR:-}`) must NOT shadow a real
   configured path — it is treated as 'not set'."
  (and s (stringp s)
       (plusp (length (string-trim '(#\Space #\Tab #\Newline #\Return) s)))
       s))

;;; ============================================================================
;;; VALIDATION FUNCTIONS
;;; ============================================================================

(defun validate-directory-path (path operation)
  "Validate that path is a directory (not a file).

   Args:
     path: Pathname to validate
     operation: Description for error message

   Returns:
     T if valid directory, NIL if not a directory or doesn't exist"
  (when path
    (let ((pathname (pathname path)))
      (and (probe-file pathname)
           (uiop:directory-pathname-p pathname)))))

(defun validate-file-path (path operation)
  "Validate that path is a file (not a directory).

   Args:
     path: Pathname to validate
     operation: Description for error message

   Returns:
     T if valid file, NIL if not a file or doesn't exist"
  (when path
    (let ((pathname (pathname path)))
      (and (probe-file pathname)
           (not (uiop:directory-pathname-p pathname))))))

;;; ============================================================================
;;; CORE DETECTION FUNCTIONS
;;; ============================================================================

(defun find-pdf-in-dir (dir)
  "Find first PDF file in directory.

   Args:
     dir: Directory pathname or string to search

   Returns:
     Pathname of first PDF found, or NIL if none found

   Note:
     - Returns NIL if dir is NIL
     - Returns NIL if dir doesn't exist
     - Returns NIL if dir is a file (not directory)
     - Searches for *.pdf pattern"
  (when dir
    (let ((dir-pathname (pathname dir)))
      (when (probe-file dir-pathname)
        (let ((pdfs (directory (merge-pathnames "*.pdf" dir-pathname))))
          (first pdfs))))))

(defun detect-source-config (&key pdf-dir pdf-path json-path)
  "Auto-detect source configuration based on available files.

   PDF-PATH (or ORCHESTRATOR_PDF_PATH) names the EXACT source document for the
   active corpus and takes priority: when given, only that file is considered
   and the input directory is NEVER globbed. This is what keeps two corpora
   whose PDFs share an input directory (e.g. the Constitution and the Penal
   Code) from being mixed. PDF-DIR globbing remains only as a legacy fallback
   for configs that declare no specific source.pdf.

   Args:
     pdf-dir: Directory to search for PDF files (pathname or string)
     json-path: Path to JSON fallback file (pathname or string)

   Environment Variable Overrides:
     ORCHESTRATOR_PDF_INPUT_DIR - Overrides pdf-dir parameter
     ORCHESTRATOR_JSON_PATH - Overrides json-path parameter

   Returns:
     Plist with :type and :path keys, or NIL if nothing found
       (:type :pdf :path <pathname-string>) - PDF found
       (:type :json :path <pathname-string>) - JSON fallback used
       NIL - No source found

   Priority:
     1. Environment variable ORCHESTRATOR_PDF_INPUT_DIR
     2. pdf-dir parameter
     3. Environment variable ORCHESTRATOR_JSON_PATH
     4. json-path parameter

   Logging:
     - Logs detection result via format t (visible in Docker build)
     - Logs via log4cl for runtime tracing"

  ;; Resolve effective paths (environment variables override parameters)
  (let* ((env-pdf-path (%non-blank (get-env "ORCHESTRATOR_PDF_PATH")))
         (env-pdf-dir (%non-blank (get-env "ORCHESTRATOR_PDF_INPUT_DIR")))
         (env-json-path (%non-blank (get-env "ORCHESTRATOR_JSON_PATH")))
         (effective-pdf-path (%non-blank (or env-pdf-path
                                             (when pdf-path (namestring pdf-path)))))
         (effective-pdf-dir (%non-blank (or env-pdf-dir
                                            (when pdf-dir (namestring pdf-dir)))))
         (effective-json-path (%non-blank (or env-json-path
                                              (when json-path (namestring json-path))))))

    ;; Log effective configuration
    (when env-pdf-dir
      (format t "~&[SOURCE-DETECT] Using env ORCHESTRATOR_PDF_INPUT_DIR=~A~%" env-pdf-dir)
      (log:info () "[SOURCE-DETECT] Environment override: ORCHESTRATOR_PDF_INPUT_DIR=~A" env-pdf-dir))
    (when env-json-path
      (format t "~&[SOURCE-DETECT] Using env ORCHESTRATOR_JSON_PATH=~A~%" env-json-path)
      (log:info () "[SOURCE-DETECT] Environment override: ORCHESTRATOR_JSON_PATH=~A" env-json-path))

    (when effective-pdf-path
      (format t "~&[SOURCE-DETECT] Corpus-specific PDF configured: ~A~%" effective-pdf-path)
      (log:info () "[SOURCE-DETECT] Corpus-specific PDF: ~A" effective-pdf-path))

    ;; Attempt detection with priority order.
    ;; A corpus-specific PDF path wins and is used ONLY if it exists; the input
    ;; directory is globbed only when no specific path was configured.
    (let ((pdf-file
            (cond
              (effective-pdf-path
               (when (validate-file-path effective-pdf-path "source PDF")
                 (pathname effective-pdf-path)))
              (effective-pdf-dir
               (find-pdf-in-dir (pathname effective-pdf-dir)))
              (t nil))))
      (cond
        ;; PRIORITY 1: PDF file found in directory
        (pdf-file
         (let ((result (list :type :pdf :path (namestring pdf-file))))
           (format t "~&[SOURCE-DETECT] Found PDF: ~A~%" pdf-file)
           (log:info () "[SOURCE-DETECT] Found PDF: ~A" pdf-file)
           result))

        ;; PRIORITY 2: JSON fallback file exists
        ((and effective-json-path (probe-file effective-json-path))
         (let ((result (list :type :json :path effective-json-path)))
           (format t "~&[SOURCE-DETECT] Using JSON fallback: ~A~%" effective-json-path)
           (log:info () "[SOURCE-DETECT] Using JSON fallback: ~A" effective-json-path)
           result))

        ;; NO SOURCE FOUND
        (t
         (format t "~&[SOURCE-DETECT] No source found at detection time~%")
         (format t "~&[SOURCE-DETECT]   pdf-dir: ~A~%" effective-pdf-dir)
         (format t "~&[SOURCE-DETECT]   json-path: ~A~%" effective-json-path)
         (format t "~&[SOURCE-DETECT]   Will detect at runtime if :deferred~%")
         (log:debug () "[SOURCE-DETECT] No source found (pdf-dir=~A, json-path=~A)"
                    effective-pdf-dir effective-json-path)
         nil)))))

(defun get-runtime-source-config (&key pdf-dir pdf-path json-path)
  "Get source configuration at runtime. Signals error if nothing found.

   This function is called by source-normalize-stage when the pipeline
   configuration has :type :deferred.

   Args:
     pdf-dir: Directory to search for PDF files
     json-path: Path to JSON fallback file

   Returns:
     Plist with :type and :path keys (guaranteed non-NIL)

   Signals:
     orchestrator.spec:config-error if no source found

   Usage:
     Called from source-normalize-stage when :type = :deferred"
  (let ((config (detect-source-config :pdf-dir pdf-dir :pdf-path pdf-path :json-path json-path)))
    (if config
        config
        (error 'orchestrator.spec:config-error
               :message (format nil "No source found at runtime.~%~
                                     Checked:~%~
                                       PDF directory: ~A~%~
                                       JSON path: ~A~%~
                                     Environment overrides:~%~
                                       ORCHESTRATOR_PDF_INPUT_DIR=~A~%~
                                       ORCHESTRATOR_JSON_PATH=~A~%~
                                     Solutions:~%~
                                       1. Place PDF file in the input directory~%~
                                       2. Ensure JSON file exists at fallback path~%~
                                       3. Set environment variables to override paths"
                                pdf-dir
                                json-path
                                (get-env "ORCHESTRATOR_PDF_INPUT_DIR" "<not set>")
                                (get-env "ORCHESTRATOR_JSON_PATH" "<not set>"))
               :config-key :source-config))))

;;; ============================================================================
;;; OUTPUT FILES PRODUCED BY PIPELINE
;;; ============================================================================
;;;
;;; When the pipeline runs successfully, it produces the following artifacts:
;;;
;;; PER-ARTICLE OUTPUT (in /app/output/articles/):
;;;   article-{N}.ttl     - RDF Turtle format
;;;   article-{N}.jsonld  - JSON-LD format (byte-identical standalone/embedded)
;;;   article-{N}.html    - Canonical HTML rendering
;;;   article-{N}.hash    - Blake3 hash for integrity verification
;;;
;;; DATASET-LEVEL OUTPUT (in /app/output/):
;;;   manifest.ttl        - DCAT dataset manifest
;;;   void.ttl            - VoID dataset description
;;;   manifest.jsonl      - AI ingest manifest (JSON Lines)
;;;
;;; EPISTEMIC OUTPUT (in /app/output/releases/YYYY-MM-DDTHH:MM:SSZ/):
;;;   meta-ontology.ttl   - Layer 1: OWL 2 DL system definition
;;;   release.ttl         - Layer 2: DCAT + temporal proof pack
;;;   lineage.ttl         - Layer 3: PROV-O continuity graph
;;;   negation.ttl        - Layer 4: Defensive moat (what we DON'T claim)
;;;   boundaries.ttl      - Layer 5: Epistemic scope limits
;;;   stability.ttl       - Layer 6: Long-term guarantees
;;;   merkle-tree.json    - Blake3 Merkle tree with inclusion proofs
;;;   latest -> symlink   - Atomic publish pointer to current release
;;;
;;; ============================================================================
