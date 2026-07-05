;;;; docker/run-standalone-test.lisp
;;;; Run ONE standalone test file inside the Docker build image.
;;;;
;;;; Standalone tests (tests/source-profile-test.lisp, review-queue-test.lisp, …)
;;;; are self-contained scripts: they (in-package …), run their checks, and
;;;; (sb-ext:exit) with 0/1. This loader configures the hermetic ASDF registry,
;;;; loads the full runtime (so every package exists), then loads the test file
;;;; named on the command line.
;;;;
;;;; Usage (inside the test/builder image, which has sbcl + /app sources):
;;;;   sbcl --script /app/docker/run-standalone-test.lisp /app/tests/<name>-test.lisp

(require :asdf)
(require :sb-posix)

(setf asdf:*central-registry*
      (list #p"/app/"
            #p"/app/systems/orchestrator-spec/"
            #p"/app/systems/orchestrator-model/"
            #p"/app/systems/orchestrator-core/"
            #p"/app/systems/orchestrator-engine-sbcl/"
            #p"/app/systems/orchestrator-cli/"
            #p"/app/systems/orchestrator-gr-syntagma/"
            #p"/app/systems/orchestrator-meta/"
            #p"/app/systems/orchestrator-ai-core/"
            #p"/app/systems/orchestrator-infrastructure/"
            #p"/app/systems/orchestrator-omega-modules/"
            #p"/app/systems/orchestrator-epistemic/"
            #p"/app/tests/"))

(locally
  (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (asdf:load-system :alexandria)
  (asdf:load-system :log4cl)
  (asdf:load-system :orchestrator-core-runtime)
  ;; A handful of legacy test files use the FiveAM framework instead of the
  ;; self-contained check/exit pattern. Make the package available so they load;
  ;; tolerant so the 60+ non-FiveAM tests are never affected if it is absent.
  (ignore-errors (asdf:load-system :fiveam)))

(let ((f (second sb-ext:*posix-argv*)))
  (unless f
    (format t "~%usage: sbcl --script run-standalone-test.lisp <test-file>~%")
    (sb-ext:exit :code 2))
  (handler-bind ((warning #'muffle-warning))
    (load f)))
