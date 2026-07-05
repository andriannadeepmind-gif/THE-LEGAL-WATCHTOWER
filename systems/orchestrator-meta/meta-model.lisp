;;;; systems/orchestrator-meta/meta-model.lisp
;;;; Meta-model classes for introspection

(in-package :orchestrator.meta)

;;; ============================================================================
;;; META-PIPELINE
;;; ============================================================================

(defclass meta-pipeline ()
  ((name :initarg :name :accessor meta-pipeline-name)
   (stage-count :initarg :stage-count :accessor meta-pipeline-stage-count)
   (corpus :initarg :corpus :accessor meta-pipeline-corpus)
   (created-at :initform (orchestrator.time:now :source :system) :accessor meta-pipeline-created-at))
  (:documentation "Meta-information about a pipeline"))

;;; ============================================================================
;;; META-STAGE
;;; ============================================================================

(defclass meta-stage ()
  ((name :initarg :name :accessor meta-stage-name)
   (dependencies :initarg :dependencies :accessor meta-stage-dependencies)
   (produces :initarg :produces :accessor meta-stage-produces))
  (:documentation "Meta-information about a stage"))

;;; ============================================================================
;;; META-ARTIFACT-TYPE
;;; ============================================================================

(defclass meta-artifact-type ()
  ((type-name :initarg :type-name :accessor meta-artifact-type-name)
   (description :initarg :description :accessor meta-artifact-type-description)
   (producers :initform nil :accessor meta-artifact-type-producers))
  (:documentation "Meta-information about artifact type"))
