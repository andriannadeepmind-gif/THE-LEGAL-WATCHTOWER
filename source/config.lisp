;;;; config.lisp
;;;; Configuration Management for Orchestrator v1.2

(in-package :orchestrator.config)

;;;; Global configuration
(defparameter *config* (make-hash-table :test 'equal)
  "Global configuration hash table")

(defun get-config (key &optional default)
  "Get configuration value"
  (gethash key *config* default))

(defun set-config (key value)
  "Set configuration value"
  (setf (gethash key *config*) value))

(defun config-value (key &optional default)
  "Alias for get-config"
  (get-config key default))

(defun load-config (path)
  "Load configuration from YAML file"
  (when (probe-file path)
    (handler-case
        (let ((yaml-data (cl-yaml:parse path)))
          (loop for (key . value) in yaml-data
               do (set-config (string key) value))
          t)
      (error (e)
        (warn "Failed to load config from ~A: ~A" path e)
        nil))))

(defun load-default-config ()
  "Load configuration from YAML (Google-Standard: YAML is single source of truth).
   NO hardcoded URIs - all URIs must come from configs/constitution.yaml."
  (set-config "version" "1.2.0")
  (set-config "parallel-workers" 4)
  (set-config "max-retries" 3)
  (set-config "publisher" "STAVROPOULOS LAW")
  (set-config "log-level" :info)

  ;; Load from YAML - this is MANDATORY
  (unless (load-config "configs/constitution.yaml")
    (error "Failed to load configs/constitution.yaml - this is REQUIRED for Google-Standard compliance"))

  ;; Initialize canonical URIs from config (Phase C: Canonical URI Sovereignty)
  (when (find-package :orchestrator.uris)
    (funcall (intern "LOAD-CANONICAL-URIS-FROM-CONFIG" :orchestrator.uris) *config*)))

(defun setup-logging ()
  "Setup logging system"
  (handler-case
      (when (find-package :orchestrator.logging)
        (funcall (intern "INITIALIZE-LOGGING" :orchestrator.logging)
                 :level (get-config "log-level" :info))
        t)
    (error (e)
      (warn "Failed to setup logging: ~A" e)
      nil)))
