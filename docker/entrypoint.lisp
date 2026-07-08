#!/usr/bin/env -S sbcl --script
;;;; docker/entrypoint.lisp
;;;; ============================================================================
;;;; PURE LISP DOCKER ENTRYPOINT (Vanilla SBCL)
;;;; ============================================================================
;;;;
;;;; Replaces: docker/entrypoint.sh
;;;; DARPA-GRADE: No bash, no shell scripts, Pure Common Lisp
;;;;
;;;; Production-grade entrypoint with:
;;;;   - Artifact detection (ELF executable, SBCL core, script)
;;;;   - Environment validation
;;;;   - Health file management
;;;;
;;;; Usage (from Dockerfile):
;;;;   ENTRYPOINT ["sbcl", "--script", "/app/entrypoint.lisp"]
;;;; ============================================================================

;;; Load sb-posix for getuid (standard SBCL contrib)
(require :sb-posix)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defparameter *artifact-path* "/app/orchestrator.core")

;;; ============================================================================
;;; UTILITIES (Vanilla SBCL - no ASDF/UIOP)
;;; ============================================================================

(defun getenv (name &optional default)
  "Get environment variable (SBCL-native)"
  (or (sb-ext:posix-getenv name) default))

(defun read-file-bytes (path n)
  "Read first N bytes of file"
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array n :element-type '(unsigned-byte 8))))
      (read-sequence bytes stream)
      bytes)))

(defun detect-artifact-type (path)
  "Detect artifact type by examining file contents"
  (let ((bytes (read-file-bytes path 4)))
    (cond
      ;; ELF magic: 0x7f 'E' 'L' 'F'
      ((and (= (aref bytes 0) #x7f)
            (= (aref bytes 1) #x45)  ; E
            (= (aref bytes 2) #x4c)  ; L
            (= (aref bytes 3) #x46)) ; F
       :elf-executable)
      ;; Script shebang: '#' '!'
      ((and (= (aref bytes 0) #x23)  ; #
            (= (aref bytes 1) #x21)) ; !
       :script)
      ;; Otherwise assume SBCL core
      (t :sbcl-core))))

(defun get-user-info ()
  "Get current user information"
  (let ((uid (sb-posix:getuid)))
    (if (zerop uid)
        (values "root" uid)
        (values (getenv "USER" "nonroot") uid))))

(defun run-subprocess (program args)
  "Run external program and return exit code (SBCL-native). Forwards stdin (:input
   t) so stdio protocols like MCP/JSON-RPC over --serve-mcp actually receive their
   input; stdout/stderr are inherited so the child's protocol stream stays clean."
  (let ((process (sb-ext:run-program program args
                                      :search t
                                      :input t
                                      :output t
                                      :error :output
                                      :wait t)))
    (sb-ext:process-exit-code process)))

;;; ============================================================================
;;; ENVIRONMENT VALIDATION
;;; ============================================================================

(defun print-environment ()
  "Print environment information"
  (format t "=== Orchestrator Startup (Pure Lisp) ===~%")
  (format t "Environment:~%")
  (format t "  ORCHESTRATOR_OUTPUT_DIR=~A~%" (getenv "ORCHESTRATOR_OUTPUT_DIR" "/app/output"))
  (format t "  ORCHESTRATOR_LOG_DIR=~A~%" (getenv "ORCHESTRATOR_LOG_DIR" "/app/logs"))
  (format t "  ORCHESTRATOR_CONFIG_DIR=~A~%" (getenv "ORCHESTRATOR_CONFIG_DIR" "/app/configs"))
  (format t "  ORCHESTRATOR_LOG_LEVEL=~A~%" (getenv "ORCHESTRATOR_LOG_LEVEL" "info"))
  (format t "  ORCHESTRATOR_WORKERS=~A~%" (getenv "ORCHESTRATOR_WORKERS" "4"))
  (format t "~%"))

(defun validate-directories ()
  "Validate required directories exist"
  (let ((dirs (list (getenv "ORCHESTRATOR_OUTPUT_DIR" "/app/output")
                    (getenv "ORCHESTRATOR_LOG_DIR" "/app/logs")
                    (getenv "ORCHESTRATOR_CONFIG_DIR" "/app/configs"))))
    (dolist (dir dirs)
      (unless (probe-file dir)
        (format t "ERROR: Required directory does not exist: ~A~%" dir)
        (sb-ext:exit :code 1)))))

(defun print-user-warning ()
  "Print warning if running as root"
  (multiple-value-bind (user uid) (get-user-info)
    (if (zerop uid)
        (format t "WARNING: Running as root user (not recommended for production)~%")
        (format t "Running as user: ~A (UID: ~D)~%" user uid))))

;;; ============================================================================
;;; ARTIFACT EXECUTION
;;; ============================================================================

(defun execute-artifact (args)
  "Execute the orchestrator artifact with given arguments"
  ;; Check artifact exists
  (unless (probe-file *artifact-path*)
    (format t "FATAL ERROR: Artifact not found: ~A~%" *artifact-path*)
    (format t "Build may have failed or artifact was not copied to runtime stage.~%")
    (sb-ext:exit :code 127))

  ;; Detect artifact type
  (format t "Detecting artifact type...~%")
  (let ((artifact-type (detect-artifact-type *artifact-path*)))
    (format t "  Detected type: ~A~%" artifact-type)
    (format t "~%")
    (format t "Starting orchestrator.core...~%")
    (format t "===========================~%")

    (let ((exit-code
            (case artifact-type
              (:elf-executable
               (format t "Execution mode: Native ELF executable~%")
               (run-subprocess *artifact-path* args))

              (:script
               (format t "Execution mode: Script wrapper~%")
               (run-subprocess *artifact-path* args))

              (:sbcl-core
               (format t "Execution mode: SBCL core image~%")
               (run-subprocess "sbcl" (append (list "--core" *artifact-path*
                                                     "--noinform" "--disable-debugger"
                                                     "--end-toplevel-options")
                                               args)))

              (t
               (format t "WARNING: Unknown artifact type, attempting SBCL core load~%")
               (run-subprocess "sbcl" (append (list "--core" *artifact-path*
                                                     "--noinform" "--disable-debugger"
                                                     "--end-toplevel-options")
                                               args))))))
      (sb-ext:exit :code exit-code))))

;;; ============================================================================
;;; MAIN ENTRY POINT
;;; ============================================================================

(defun main ()
  "Main entrypoint function"
  ;; ΚΑΜΙΑ εγγραφή health από τον wrapper: η υγεία σημαίνει ΣΗΜΑΣΙΟΛΟΓΙΚΗ
  ;; ετοιμότητα και τη γράφει ΜΟΝΟ ο orchestrator (/app/output/.healthy,
  ;; write-health-file) στο τέλος επιτυχούς δουλειάς — εύρημα audit 0012.
  ;; Get command line arguments (skip sbcl and script args)
  (let ((args (cdr sb-ext:*posix-argv*)))
    (when (and args (string= (first args) "--script"))
      (setf args (cddr args)))
    ;; MCP / stdio mode (--serve-mcp): the child process OWNS stdout for the
    ;; JSON-RPC protocol, so ALL entrypoint chatter must go to stderr — otherwise
    ;; the startup banner corrupts the very first protocol frame. run-subprocess
    ;; inherits the real fd 1/0, so the child's stdout and stdin stay clean.
    (let* ((mcp (and (member "--serve-mcp" args :test #'string=) t))
           (*standard-output* (if mcp *error-output* *standard-output*)))
      (print-environment)
      (validate-directories)
      (print-user-warning)
      (format t "~%")
      (execute-artifact args))))

;; Run main
(main)
