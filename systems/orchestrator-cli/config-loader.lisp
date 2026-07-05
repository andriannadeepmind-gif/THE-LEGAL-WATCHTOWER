;;;; systems/orchestrator-cli/config-loader.lisp
;;;; Configuration loading

(in-package :orchestrator.cli)

(defun load-config (path)
  "Load configuration from YAML file
  
  Args:
    path: Path to config file
  
  Returns:
    Config hash table"
  (cl-yaml:parse (uiop:read-file-string path)))
