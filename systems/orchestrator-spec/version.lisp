;;;; systems/orchestrator-spec/version.lisp
;;;; System Version Definition (Canonical Source)

(in-package :orchestrator.spec)

;;; ============================================================================
;;; SYSTEM VERSION
;;; ============================================================================
;;; Canonical source for system-wide version.
;;; All other subsystems consume this value.
;;;
;;; Using DEFPARAMETER (not DEFCONSTANT) to avoid SBCL DEFCONSTANT-UNEQL
;;; errors when file is loaded multiple times.

(defparameter +system-version+ "1.2.0"
  "Current version of the Orchestrator system (canonical source)")

(defparameter +pipeline-version+ "1.2.0"
  "Pipeline version (alias for +system-version+ for backward compatibility)")

;;; Backward compatibility alias
(defparameter +version+ +system-version+
  "Backward compatibility alias for +system-version+")
