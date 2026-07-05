;;;; source/deterministic-time.lisp
;;;; DETERMINISTIC TIMESTAMP ABSTRACTION
;;;;
;;;; Phase B: Deterministic Build
;;;;
;;;; This module provides a single source of truth for timestamps.
;;;; When deterministic mode is enabled, all timestamps are fixed.
;;;; When disabled, it falls back to system time.
;;;;
;;;; Guarantee: Same input → Same output → Same hash

(defpackage :orchestrator.time
  (:use :cl)
  (:import-from :local-time
                #:timestamp
                #:now
                #:parse-timestring
                #:format-timestring
                #:format-rfc3339-timestring
                #:timestamp<=)
  (:export
   ;; Configuration
   #:*deterministic-mode*
   #:*fixed-timestamp*
   #:configure-deterministic-time

   ;; Main API - Use these instead of direct local-time calls
   #:get-current-timestamp
   #:get-unix-timestamp
   #:get-iso8601-timestamp
   #:get-rfc3339-timestamp

   ;; GATE-1: Unified API with explicit source control
   #:now
   #:format-iso8601
   #:parse-iso8601
   #:*mock-time*

   ;; Pass-through from local-time for convenience
   #:parse-timestring
   #:format-timestring
   #:format-rfc3339-timestring
   #:timestamp<=))

(in-package :orchestrator.time)

;;; ============================================================
;;; CONFIGURATION
;;; ============================================================

(defparameter *deterministic-mode* nil
  "When T, use fixed timestamp. When NIL, use system time.")

(defparameter *fixed-timestamp* nil
  "Fixed timestamp used in deterministic mode.
   Set via configure-deterministic-time or from config.")

;;; ============================================================
;;; CONFIGURATION API
;;; ============================================================

(defun configure-deterministic-time (&key (enabled nil) (fixed-time "2025-01-01T00:00:00Z"))
  "Configure deterministic time mode.
   
   Arguments:
     :enabled - T to enable deterministic mode, NIL to use system time
     :fixed-time - ISO8601 string for fixed timestamp (default 2025-01-01T00:00:00Z)
   
   Example:
     (configure-deterministic-time :enabled t :fixed-time \"2025-01-01T00:00:00Z\")"
  (setf *deterministic-mode* enabled)
  (when enabled
    (setf *fixed-timestamp* 
          (if (stringp fixed-time)
              (parse-timestring fixed-time)
              fixed-time)))
  (values *deterministic-mode* *fixed-timestamp*))

;;; ============================================================
;;; MAIN API - Always use these instead of local-time:now
;;; ============================================================

(defun get-current-timestamp ()
  "Get current timestamp - fixed in deterministic mode, system time otherwise.

   This is the ONLY function that should be used instead of (local-time:now).
   Returns a local-time:timestamp object."
  (if *deterministic-mode*
      *fixed-timestamp*
      (local-time:now)))

(defun get-unix-timestamp ()
  "Get current Unix timestamp (seconds since epoch) as integer.

   This is the function to use instead of (get-universal-time).
   Uses fixed time in deterministic mode.
   Returns integer (Unix timestamp)."
  (if *deterministic-mode*
      (local-time:timestamp-to-unix *fixed-timestamp*)
      (get-universal-time)))

(defun get-iso8601-timestamp ()
  "Get current timestamp formatted as ISO8601 string.
   
   Returns string like \"2025-01-01T00:00:00.000000Z\"
   Uses fixed time in deterministic mode."
  (format-timestring nil (get-current-timestamp)
                     :format '((:year 4) #\- (:month 2) #\- (:day 2)
                              #\T
                              (:hour 2) #\: (:min 2) #\: (:sec 2)
                              #\. (:usec 6) #\Z)))

(defun get-rfc3339-timestamp ()
  "Get current timestamp formatted as RFC3339 string.
   
   Returns string like \"2025-01-01T00:00:00Z\"
   Uses fixed time in deterministic mode."
  (format-rfc3339-timestring nil (get-current-timestamp)))

;;; ============================================================
;;; GATE-1: UNIFIED API WITH EXPLICIT SOURCE CONTROL
;;; ============================================================

(defparameter *mock-time* nil
  "Mock timestamp for deterministic testing. NIL means no mock set.
   Use with (now :source :mock).")

(defun now (&key source)
  "Return current universal time with explicit source control.

   SOURCE is REQUIRED and must be :system, :deterministic or :mock.
     :system        → get-universal-time (actual system time). Use for
                      operational/internal timestamps (logs, caches, health)
                      that are NOT serialized into reproducible artifacts.
     :deterministic → fixed reproducible universal-time when deterministic mode
                      is enabled (via SOURCE_DATE_EPOCH or
                      configure-deterministic-time); otherwise falls back to
                      system time. Use for ANY timestamp that is serialized into
                      output artifacts (RDF/TTL, JSON-LD, manifests, release
                      directory names) so that two runs produce byte-identical
                      output.
     :mock          → *mock-time* (errors if nil)

   This is the canonical time API for GATE-1.
   Fail-fast guarantees:
     - Errors if SOURCE not provided (prevents accidental omission)
     - Errors if :mock used but *mock-time* is nil (prevents accidental production use)

   Returns: universal-time (integer)"
  (unless source
    (error "SOURCE parameter is required. Use :source :system, :source :deterministic or :source :mock"))
  (ecase source
    (:system (get-universal-time))
    (:deterministic
     (if (and *deterministic-mode* *fixed-timestamp*)
         (local-time:timestamp-to-universal *fixed-timestamp*)
         (get-universal-time)))
    (:mock
     (unless *mock-time*
       (error "Mock time requested but *mock-time* is nil. Set it before calling (now :source :mock)."))
     *mock-time*)))

(defun format-iso8601 (universal-time)
  "Format universal-time as ISO8601 string (UTC).

   Args: universal-time (integer)
   Returns: string like \"2025-01-01T00:00:00Z\""
  (let ((timestamp (local-time:universal-to-timestamp universal-time)))
    (format-timestring nil timestamp
                       :format '((:year 4) #\- (:month 2) #\- (:day 2) #\T
                                (:hour 2) #\: (:min 2) #\: (:sec 2) #\Z)
                       :timezone local-time:+utc-zone+)))

(defun parse-iso8601 (string)
  "Parse ISO8601 string to universal-time.

   Args: string (ISO8601 format)
   Returns: universal-time (integer)"
  (local-time:timestamp-to-universal
   (parse-timestring string)))

;;; ============================================================
;;; INITIALIZATION
;;; ============================================================

;; Try to load deterministic config from environment or config file
(defun initialize-from-environment ()
  "Initialize deterministic time from SOURCE_DATE_EPOCH environment variable.
   
   SOURCE_DATE_EPOCH is a Unix timestamp used for reproducible builds."
  (let ((epoch (uiop:getenv "SOURCE_DATE_EPOCH")))
    (when epoch
      (let ((unix-time (parse-integer epoch :junk-allowed t)))
        (when unix-time
          ;; Convert Unix timestamp to local-time timestamp
          (let ((base-time (parse-timestring "1970-01-01T00:00:00Z")))
            (setf *deterministic-mode* t)
            (setf *fixed-timestamp* 
                  (local-time:timestamp+ base-time unix-time :sec))
            (format t "~&; Deterministic mode enabled from SOURCE_DATE_EPOCH: ~A~%"
                    (get-iso8601-timestamp))))))))

;; Initialize on load if SOURCE_DATE_EPOCH is set
(eval-when (:load-toplevel :execute)
  (initialize-from-environment))
