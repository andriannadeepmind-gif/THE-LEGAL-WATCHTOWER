;;;; systems/orchestrator-tests/fixtures/mock-data.lisp
;;;; Mock data for testing

(in-package :orchestrator-tests)

(defparameter *mock-config*
  '(:parallel nil
    :max-retries 1
    :output-dir "/tmp/orchestrator-test/"))
