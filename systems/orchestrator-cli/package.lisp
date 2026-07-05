;;;; systems/orchestrator-cli/package.lisp
;;;; Package for CLI

(in-package :cl-user)

(defpackage #:orchestrator.cli
  (:use :cl)
  (:local-nicknames (#:log #:orchestrator.logging))
  (:export
   #:main
   #:run-full-build
   #:run-full-build-ai
   #:run-ai-export-only
   #:validate-pipeline
   #:generate-report
   #:load-config))
