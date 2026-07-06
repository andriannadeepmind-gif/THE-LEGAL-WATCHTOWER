;;;; source/canonical-uris.lisp
;;;; CANONICAL URI CONFIGURATION
;;;;
;;;; Phase C: Canonical URI Sovereignty (DRY = LAW)
;;;;
;;;; This module provides the SINGLE source of truth for ALL URIs in the system.
;;;; NO hardcoded URIs are allowed anywhere else in the codebase.
;;;; All modules MUST read URIs from this configuration.
;;;;
;;;; Guarantee: The system has ONE identity.

(defpackage :orchestrator.uris
  (:use :cl)
  (:import-from :uiop
                #:getenv)
  (:export
   ;; Configuration
   #:*canonical-config*
   #:configure-canonical-uris
   #:load-canonical-uris-from-config

   ;; Main API - Use these instead of hardcoded URIs
   #:get-base-uri
   #:get-eli-prefix
   #:get-eli-const-prefix
   #:get-eli-law-prefix
   #:get-corpus-prefix
   #:get-identity-prefix
   #:get-policy-prefix
   #:get-ontology-prefix

   ;; URI Builders
   #:build-ontology-uri
   #:build-audit-uri
   #:build-activity-uri
   #:build-citation-uri
   #:build-anchor-uri
   #:build-article-uri
   #:build-corpus-version-uri
   #:get-identity-uri
   #:get-org-uri

   ;; URI validation
   #:validate-uri
   #:assert-canonical-uri))

(in-package :orchestrator.uris)

;;; ============================================================
;;; CONFIGURATION
;;; ============================================================

(defparameter *canonical-config* (make-hash-table :test 'equal)
  "Canonical URI configuration loaded from config file.
   This is the ONLY source of truth for URIs.")

;;; ============================================================
;;; NO DEFAULT CONFIGURATION - YAML is single source of truth
;;; ============================================================
;;;
;;; Google-Standard: NO fallback defaults. Configuration MUST be loaded
;;; from configs/constitution.yaml at startup via load-canonical-uris-from-config.
;;; If configuration is missing, the system MUST fail hard.

;;; ============================================================
;;; CONFIGURATION API
;;; ============================================================

(defun configure-canonical-uris (&key base-uri eli-prefix eli-const-prefix 
                                      corpus-prefix identity-prefix 
                                      policy-prefix ontology-prefix)
  "Configure canonical URIs programmatically.
   
   Arguments:
     :base-uri - Base URI for all resources
     :eli-prefix - ELI prefix for European Legislation Identifier
     :eli-const-prefix - Full ELI prefix for constitution
     :corpus-prefix - Corpus resource prefix
     :identity-prefix - Identity resource prefix
     :policy-prefix - Policy resource prefix
     :ontology-prefix - Ontology prefix
   
   Example:
     (configure-canonical-uris 
       :base-uri \"https://stavropouloslaw.com\"
       :eli-prefix \"https://stavropouloslaw.com/eli/gr\")"
  (when base-uri
    (setf (gethash "base_uri" *canonical-config*) base-uri))
  (when eli-prefix
    (setf (gethash "eli_prefix" *canonical-config*) eli-prefix))
  (when eli-const-prefix
    (setf (gethash "eli_const_prefix" *canonical-config*) eli-const-prefix))
  (when corpus-prefix
    (setf (gethash "corpus_prefix" *canonical-config*) corpus-prefix))
  (when identity-prefix
    (setf (gethash "identity_prefix" *canonical-config*) identity-prefix))
  (when policy-prefix
    (setf (gethash "policy_prefix" *canonical-config*) policy-prefix))
  (when ontology-prefix
    (setf (gethash "ontology_prefix" *canonical-config*) ontology-prefix)))

(defun load-canonical-uris-from-config (config-hash)
  "Load canonical URIs from a configuration hash table.
   
   Expected keys in config-hash under 'canonical':
     - base_uri
     - eli_prefix
     - eli_const_prefix
     - corpus_prefix
     - identity_prefix
     - policy_prefix
     - ontology_prefix"
  (let ((canonical (gethash "canonical" config-hash)))
    (when canonical
      (maphash (lambda (key value)
                 (setf (gethash (string key) *canonical-config*) value))
               canonical))))

;;; ============================================================
;;; MAIN API - Always use these instead of hardcoded URIs
;;; ============================================================

(defun get-base-uri ()
  "Get the canonical base URI.
   Returns: https://stavropouloslaw.com"
  (or (gethash "base_uri" *canonical-config*)
      (error "Canonical base URI not configured! Call configure-canonical-uris or load-canonical-uris-from-config first.")))

(defun get-eli-prefix ()
  "Get the ELI prefix.
   Returns: https://stavropouloslaw.com/eli/gr"
  (or (gethash "eli_prefix" *canonical-config*)
      (error "ELI prefix not configured!")))

(defun get-eli-const-prefix ()
  "Get the full ELI constitution prefix.
   Returns: https://stavropouloslaw.com/eli/gr/const/1975"
  (or (gethash "eli_const_prefix" *canonical-config*)
      (error "ELI constitution prefix not configured!")))

(defun get-corpus-prefix ()
  "Get the corpus prefix.
   Returns: https://stavropouloslaw.com/corpus/constitution"
  (or (gethash "corpus_prefix" *canonical-config*)
      (error "Corpus prefix not configured!")))

(defun get-identity-prefix ()
  "Get the identity prefix.
   Returns: https://stavropouloslaw.com/identity"
  (or (gethash "identity_prefix" *canonical-config*)
      (error "Identity prefix not configured!")))

(defun get-policy-prefix ()
  "Get the policy prefix.
   Returns: https://stavropouloslaw.com/policy"
  (or (gethash "policy_prefix" *canonical-config*)
      (error "Policy prefix not configured!")))

(defun get-ontology-prefix ()
  "Get the ontology prefix.
   Returns: https://stavropouloslaw.com/ontology"
  (or (gethash "ontology_prefix" *canonical-config*)
      (error "Ontology prefix not configured!")))

;;; ============================================================
;;; GENERIC ELI LAW PREFIX - Supports all Greek law types
;;; ============================================================

(defun get-eli-law-prefix (type-code year)
  "Build the ELI prefix for any Greek law type.

   This is the authoritative URI constructor for all Greek legal acts,
   implementing ELI v1.4 as Greece should apply it per Council Conclusions
   2012/C 325/02.

   type-code: ELI type code string (\"const\", \"l\", \"pd\", \"md\", \"jmd\",
              \"cma\", \"cc\", \"pc\", \"ccp\", \"cciv\", \"ld\", \"rpd\")
   year:      String or integer (e.g. \"1975\", 2024)

   Returns: ELI prefix string, e.g.:
     \"https://stavropouloslaw.com/eli/gr/const/1975\"
     \"https://stavropouloslaw.com/eli/gr/l/2024\"
     \"https://stavropouloslaw.com/eli/gr/pd/2017\"

   For Constitution, prefer get-eli-const-prefix (reads from YAML config).
   For all other law types, use this function."
  (format nil "~A/~A/~A" (get-eli-prefix) type-code year))

;;; ============================================================
;;; URI BUILDERS - Common patterns for constructing URIs
;;; ============================================================

(defun build-ontology-uri (fragment)
  "Build an ontology URI.
   Example: (build-ontology-uri \"legal#\") => \"https://stavropouloslaw.com/ontology/legal#\""
  (format nil "~A/~A" (get-ontology-prefix) fragment))

(defun build-audit-uri (id)
  "Build an audit trail URI."
  (format nil "~A/audit/~A" (get-base-uri) id))

(defun build-activity-uri (id)
  "Build an activity URI."
  (format nil "~A/activity/~A" (get-base-uri) id))

(defun build-citation-uri (id)
  "Build a citation URI."
  (format nil "~A/citation/~A" (get-base-uri) id))

(defun build-anchor-uri (id)
  "Build an anchor URI."
  (format nil "~A/anchor/~A" (get-base-uri) id))

(defun build-article-uri (article-number &optional version)
  "Build an article URI with optional version. ARTICLE-NUMBER is the CANONICAL
   article identity — integer or suffixed label (e.g. \"100Α\"): suffixes are
   part of the identity and must never collapse (contract:
   article-identity-management)."
  (if version
      (format nil "~A/article/~A/v~A" (get-base-uri) article-number version)
      (format nil "~A/article/~A" (get-base-uri) article-number)))

(defun build-corpus-version-uri (version-string)
  "Build a corpus version URI."
  (format nil "~A/corpus/version/~A" (get-base-uri) version-string))

(defun get-identity-uri ()
  "Get the canonical identity URI (#me)."
  (format nil "~A/#me" (get-base-uri)))

(defun get-org-uri ()
  "Get the organization URI (#org)."
  (format nil "~A/#org" (get-base-uri)))

;;; ============================================================
;;; URI VALIDATION
;;; ============================================================

(defun validate-uri (uri)
  "Validate that a URI is under the canonical base.
   
   Returns T if valid, NIL otherwise.
   A valid URI must start with the canonical base URI."
  (let ((base (get-base-uri)))
    (and (stringp uri)
         (>= (length uri) (length base))
         (string= base uri :end2 (length base)))))

(defun assert-canonical-uri (uri &optional (error-message "URI is not under canonical base"))
  "Assert that a URI is under the canonical base.
   
   Raises an error if the URI is not canonical.
   This is used for build-time validation."
  (unless (validate-uri uri)
    (error "~A: ~A (expected to start with ~A)" 
           error-message uri (get-base-uri))))

;;; ============================================================
;;; INITIALIZATION
;;; ============================================================
;;;
;;; Google-Standard: NO automatic defaults.
;;; Configuration MUST be loaded explicitly from configs/constitution.yaml
;;; at system startup. See entrypoint.lisp or orchestrator-main.lisp.
;;;
;;; If you see "Canonical base URI not configured!" errors,
;;; ensure load-canonical-uris-from-config is called during initialization.
