;;;; systems/orchestrator-omega-modules/frbr-package.lisp
;;;; Package definition for orchestrator.frbr

(in-package :cl-user)

(defpackage :orchestrator.frbr
  (:use :cl :alexandria :serapeum)
  (:export
   ;; Pipeline
   ;; NOTE: Per-layer writers (write-{work,expression,manifestation,format}-layer)
   ;; and batch generators (generate-all-{work,expression}-layers) were removed.
   ;; The canonical write path is the unified single-emission generator
   ;; (orchestrator.spec:write-unified-article-file); per-layer RDF is produced
   ;; via the generate-rdf protocol method, not standalone writers.
   #:frbr-generation-stage
   #:execute-stage
   #:run-frbr-generation-stage))
