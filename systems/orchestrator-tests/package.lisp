;;;; systems/orchestrator-tests/package.lisp
;;;; Package for test suite

(in-package :cl-user)

(defpackage #:orchestrator-tests
  (:use :cl :fiveam)
  ;; FiveAM already exports a symbol RUN-ALL-TESTS from its (locked) package; we
  ;; provide our OWN canonical entry point of the same name, so shadow it to own
  ;; the symbol instead of inheriting (and trying to redefine) fiveam's.
  (:shadow #:run-all-tests)
  (:export #:run-all-tests
           #:orchestrator-test-suite))


