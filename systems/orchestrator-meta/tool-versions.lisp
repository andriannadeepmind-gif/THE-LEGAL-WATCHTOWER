;;;; systems/orchestrator-meta/tool-versions.lisp
;;;; Environment and tool version capture

(in-package :orchestrator.meta)

(defun capture-tool-versions ()
  "Capture versions of all tools in environment
  
  Returns:
    Plist of tool versions"
  (list :lisp-implementation (lisp-implementation-type)
        :lisp-version (lisp-implementation-version)
        #+sbcl :sbcl-version #+sbcl (lisp-implementation-version)
        :asdf-version (asdf:asdf-version)
        :orchestrator-version "2.0.0"
        :timestamp (orchestrator.time:now :source :system)))

(defun get-tool-version (tool-name)
  "Get version of specific tool
  
  Args:
    tool-name: Tool name (keyword)
  
  Returns:
    Version string or NIL"
  (getf (capture-tool-versions) tool-name))
