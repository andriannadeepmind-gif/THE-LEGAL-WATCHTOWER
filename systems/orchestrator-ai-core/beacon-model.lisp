;;;; systems/orchestrator-ai-core/beacon-model.lisp
;;;; AI beacon model for authority signals

(in-package :orchestrator.ai-core)

(defclass ai-beacon ()
  ((article-uri :initarg :article-uri :accessor beacon-article-uri)
   (authority-score :initarg :authority-score :accessor beacon-authority-score :initform 1.0)
   (timestamp :initform (orchestrator.time:now :source :system) :accessor beacon-timestamp))
  (:documentation "AI telemetry beacon for authority tracking"))
