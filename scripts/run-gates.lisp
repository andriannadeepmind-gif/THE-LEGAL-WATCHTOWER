#!/usr/bin/env -S sbcl --script
;;;; scripts/run-gates.lisp
;;;; ============================================================================
;;;; UNIFIED GATE RUNNER - Pure Common Lisp
;;;; ============================================================================
;;;;
;;;; Replaces ALL shell-based gate guards with Pure Lisp.
;;;;
;;;; Usage:
;;;;   sbcl --script scripts/run-gates.lisp
;;;;   sbcl --script scripts/run-gates.lisp --gate 3
;;;;   sbcl --script scripts/run-gates.lisp --verify
;;;;   sbcl --script scripts/run-gates.lisp --all
;;;;
;;;; Exit codes:
;;;;   0 = All checks passed
;;;;   1 = Violations found
;;;;
;;;; DARPA-GRADE: No bash, no grep, no external tools.
;;;; ============================================================================

(require :asdf)

;;; Configure ASDF paths
(push (truename ".") asdf:*central-registry*)
(push (truename "source/") asdf:*central-registry*)
(push (truename "systems/") asdf:*central-registry*)

;;; Load gate-guards
(load "source/gate-guards.lisp")

;;; Parse command line arguments
(defun get-arg (name args)
  "Get argument value from command line"
  (let ((pos (position name args :test #'string=)))
    (when (and pos (< (1+ pos) (length args)))
      (nth (1+ pos) args))))

(defun has-arg (name args)
  "Check if argument present"
  (member name args :test #'string=))

;;; Main entry point
(let* ((args (uiop:command-line-arguments))
       (gate-num (get-arg "--gate" args))
       (verify-only (has-arg "--verify" args))
       (run-all (or (has-arg "--all" args) (null args))))

  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "  ORCHESTRATOR GATE GUARDS - Pure Common Lisp~%")
  (format t "  \"η DARPA δεν δουλεύει με bash scripts\"~%")
  (format t "═══════════════════════════════════════════════════════════════~%~%")

  (handler-case
      (cond
        ;; Run specific gate
        (gate-num
         (let ((n (parse-integer gate-num)))
           (case n
             (1 (orchestrator.gate-guards:run-gate-1-time-guard))
             (2 (orchestrator.gate-guards:run-gate-2-write-guard))
             (3 (orchestrator.gate-guards:run-gate-3-hash-guard))
             (4 (orchestrator.gate-guards:run-gate-4-pipeline-guard))
             (5 (orchestrator.gate-guards:run-gate-5-validation-guard))
             (t (format t "Unknown gate: ~A~%" n)
                (sb-ext:exit :code 1)))))

        ;; Run verifications only
        (verify-only
         (orchestrator.gate-guards:run-all-verifications))

        ;; Run all gates and verifications
        (run-all
         (orchestrator.gate-guards:run-all-gates)
         (orchestrator.gate-guards:run-all-verifications)))

    (orchestrator.gate-guards:gate-violation (e)
      (format t "~%~%GATE VIOLATION: ~A~%" e)
      (sb-ext:exit :code 1))

    (orchestrator.gate-guards:verification-failure (e)
      (format t "~%~%VERIFICATION FAILURE: ~A~%" e)
      (sb-ext:exit :code 1))

    (error (e)
      (format t "~%~%UNEXPECTED ERROR: ~A~%" e)
      (sb-ext:exit :code 1)))

  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "  ALL CHECKS PASSED ✓~%")
  (format t "═══════════════════════════════════════════════════════════════~%~%")

  (sb-ext:exit :code 0))
