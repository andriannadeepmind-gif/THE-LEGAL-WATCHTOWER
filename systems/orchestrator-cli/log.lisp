;;;; systems/orchestrator-cli/log.lisp
;;;; Simple logging facility for CLI

(in-package :orchestrator.cli)

(defmacro log-info (control-string &rest args)
  "Log an info message"
  `(format t ,(concatenate 'string "~&[INFO] " control-string "~%") ,@args))

(defmacro log-warn (control-string &rest args)
  "Log a warning message"
  `(format t ,(concatenate 'string "~&[WARN] " control-string "~%") ,@args))

(defmacro log-error (control-string &rest args)
  "Log an error message"
  `(format t ,(concatenate 'string "~&[ERROR] " control-string "~%") ,@args))
