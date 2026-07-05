;;;; tests/source-detect-test.lisp
;;;; A corpus declares source.pdf + source.json; when the PDF is absent the JSON
;;;; must be used. docker-compose passes ORCHESTRATOR_JSON_PATH as an EMPTY string
;;;; (`${VAR:-}`), which previously shadowed the real source.json and made the
;;;; loader read "/app" (a directory) → crash. The fix: an empty env var is "not
;;;; set". This test locks that, plus a real override still wins.

(in-package :orchestrator.core)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun setenv (k v) (sb-posix:setenv k v 1))
(defun unsetenv (k) (ignore-errors (sb-posix:unsetenv k)))

;; a real JSON source file + a real override file
(defparameter *json* (format nil "/tmp/sd-src-~A.json" (get-universal-time)))
(defparameter *override* (format nil "/tmp/sd-ovr-~A.json" (get-universal-time)))
(with-open-file (s *json* :direction :output :if-exists :supersede :if-does-not-exist :create)
  (write-string "[]" s))
(with-open-file (s *override* :direction :output :if-exists :supersede :if-does-not-exist :create)
  (write-string "[]" s))

(format t "~%== %non-blank: empty/blank → NIL ==~%")
(check "empty string is blank"      (null (%non-blank "")))
(check "whitespace is blank"        (null (%non-blank "   ")))
(check "nil is blank"               (null (%non-blank nil)))
(check "a real value passes"        (string= "x" (%non-blank "x")))

(format t "~%== an EMPTY ORCHESTRATOR_JSON_PATH must NOT shadow source.json ==~%")
(unsetenv "ORCHESTRATOR_PDF_PATH") (unsetenv "ORCHESTRATOR_PDF_INPUT_DIR")
(setenv "ORCHESTRATOR_JSON_PATH" "")          ; the docker-compose `${VAR:-}` case
(let ((cfg (detect-source-config :json-path *json*)))
  (check "the configured source.json is used (not shadowed by the empty env)"
         (and cfg (eq :json (getf cfg :type))))
  (check "and it resolves to the REAL file, not /app"
         (and cfg (string= *json* (getf cfg :path)))))

(format t "~%== a NON-empty ORCHESTRATOR_JSON_PATH override still wins ==~%")
(setenv "ORCHESTRATOR_JSON_PATH" *override*)
(let ((cfg (detect-source-config :json-path *json*)))
  (check "the real env override is honoured" (string= *override* (getf cfg :path))))
(unsetenv "ORCHESTRATOR_JSON_PATH")

(format t "~%== unset env + configured source.json still works ==~%")
(let ((cfg (detect-source-config :json-path *json*)))
  (check "configured source.json used when env is unset"
         (and cfg (string= *json* (getf cfg :path)))))

(format t "~%== genuinely source-less corpus → NIL (clean), not a /app crash ==~%")
(setenv "ORCHESTRATOR_JSON_PATH" "")
(check "no pdf + no json → NIL (caller errors cleanly, no directory read)"
       (null (detect-source-config :json-path "/tmp/does-not-exist-xyz.json")))
(unsetenv "ORCHESTRATOR_JSON_PATH")

(ignore-errors (delete-file *json*)) (ignore-errors (delete-file *override*))

(format t "~%========================================~%")
(format t "Source detect tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
