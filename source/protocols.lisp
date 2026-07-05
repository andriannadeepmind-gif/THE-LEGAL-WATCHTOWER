;;;; protocols.lisp
;;;; Protocol definitions for all orchestrator modules
;;;; Complete interface definitions for pluggable architecture

(defpackage #:orchestrator.protocols
  (:use :cl)
  (:export #:generate-rdf
           #:validate-rdf
           #:anchor-to-blockchain
           #:verify-blockchain-anchor
           #:get-anchor-status
           #:validate-data
           #:call-service
           #:check-service-health
           #:circuit-breaker-state
           #:close-session
           #:component-status
           #:compute-hash
           #:create-session
           #:delete-corpus
           #:export-audit-trail
           #:get-config-value
           #:get-service-metrics
           #:get-session
           #:get-validation-report
           #:handle-error
           #:initialize-component
           #:list-active-sessions
           #:list-corpora
           #:log-audit-event
           #:path-exists-p
           #:query-audit-log
           #:register-path
           #:reload-config
           #:resolve-path
           #:restart-component
           #:retrieve-corpus
           #:retry-operation
           #:set-config-value
           #:start-component
           #:stop-component
           #:store-corpus
           #:supported-hash-types
           #:update-corpus
           #:update-session
           #:validate-config
           #:verify-hash))

(in-package :orchestrator.protocols)

;;;; ========================================================================
;;;; CORE PROTOCOLS
;;;; ========================================================================

;;; RDF Generator Protocol
(defgeneric generate-rdf (object &key format)
  (:documentation "Generate RDF representation of an object"))

(defgeneric validate-rdf (rdf-string &key format)
  (:documentation "Validate RDF syntax and structure"))

;;; Blockchain Anchor Protocol
(defgeneric anchor-to-blockchain (data blockchain-type &key options)
  (:documentation "Anchor data to a blockchain"))

(defgeneric verify-blockchain-anchor (anchor-id blockchain-type)
  (:documentation "Verify a blockchain anchor"))

(defgeneric get-anchor-status (anchor-id blockchain-type)
  (:documentation "Get status of a blockchain anchor"))

;;; Validator Protocol
(defgeneric validate-data (data validator-type &key options)
  (:documentation "Validate data using specified validator"))

(defgeneric get-validation-report (validation-result)
  (:documentation "Get detailed validation report"))

;;; Corpus Repository Protocol
(defgeneric store-corpus (corpus repository &key options)
  (:documentation "Store corpus in repository"))

(defgeneric retrieve-corpus (corpus-id repository)
  (:documentation "Retrieve corpus from repository"))

(defgeneric list-corpora (repository &key filters)
  (:documentation "List available corpora in repository"))

(defgeneric update-corpus (corpus repository &key options)
  (:documentation "Update existing corpus in repository"))

(defgeneric delete-corpus (corpus-id repository)
  (:documentation "Delete corpus from repository"))

;;; Audit Logger Protocol
(defgeneric log-audit-event (event logger &key severity)
  (:documentation "Log an audit event"))

(defgeneric query-audit-log (logger &key filters)
  (:documentation "Query audit log with filters"))

(defgeneric export-audit-trail (logger format &key options)
  (:documentation "Export audit trail in specified format"))

;;; Session Manager Protocol
(defgeneric create-session (manager &key options)
  (:documentation "Create new session"))

(defgeneric get-session (session-id manager)
  (:documentation "Get existing session"))

(defgeneric update-session (session manager)
  (:documentation "Update session state"))

(defgeneric close-session (session-id manager)
  (:documentation "Close and cleanup session"))

(defgeneric list-active-sessions (manager)
  (:documentation "List all active sessions"))

;;; Config Provider Protocol
(defgeneric get-config-value (key provider &key default)
  (:documentation "Get configuration value"))

(defgeneric set-config-value (key value provider)
  (:documentation "Set configuration value"))

(defgeneric reload-config (provider)
  (:documentation "Reload configuration from source"))

(defgeneric validate-config (provider)
  (:documentation "Validate configuration completeness"))

;;; Path Resolver Protocol
(defgeneric resolve-path (path-key resolver &rest components)
  (:documentation "Resolve path from key and optional components"))

(defgeneric register-path (path-key path resolver)
  (:documentation "Register a path mapping"))

(defgeneric path-exists-p (path-key resolver)
  (:documentation "Check if path exists"))

;;; Hash Provider Protocol
(defgeneric compute-hash (data hash-type &key options)
  (:documentation "Compute hash of data"))

(defgeneric verify-hash (data hash-value hash-type)
  (:documentation "Verify hash matches data"))

(defgeneric supported-hash-types (provider)
  (:documentation "List supported hash types"))

;;; External Service Protocol
(defgeneric call-service (service method &key params)
  (:documentation "Call external service"))

(defgeneric check-service-health (service)
  (:documentation "Check external service health"))

(defgeneric get-service-metrics (service)
  (:documentation "Get service performance metrics"))

;;;; ========================================================================
;;;; LIFECYCLE PROTOCOLS
;;;; ========================================================================

(defgeneric initialize-component (component &key options)
  (:documentation "Initialize component"))

(defgeneric start-component (component)
  (:documentation "Start component"))

(defgeneric stop-component (component)
  (:documentation "Stop component"))

(defgeneric restart-component (component)
  (:documentation "Restart component"))

(defgeneric component-status (component)
  (:documentation "Get component status"))

;;;; ========================================================================
;;;; ERROR HANDLING PROTOCOLS
;;;; ========================================================================

(defgeneric handle-error (error handler &key context)
  (:documentation "Handle error with specified handler"))

(defgeneric retry-operation (operation &key max-retries backoff)
  (:documentation "Retry operation with backoff"))

(defgeneric circuit-breaker-state (breaker)
  (:documentation "Get circuit breaker state"))

;;;; ========================================================================
;;;; EXPORTS
;;;; ========================================================================

(export '(;; RDF Generator
          generate-rdf
          validate-rdf
          
          ;; Blockchain Anchor
          anchor-to-blockchain
          verify-blockchain-anchor
          get-anchor-status
          
          ;; Validator
          validate-data
          get-validation-report
          
          ;; Corpus Repository
          store-corpus
          retrieve-corpus
          list-corpora
          update-corpus
          delete-corpus
          
          ;; Audit Logger
          log-audit-event
          query-audit-log
          export-audit-trail
          
          ;; Session Manager
          create-session
          get-session
          update-session
          close-session
          list-active-sessions
          
          ;; Config Provider
          get-config-value
          set-config-value
          reload-config
          validate-config
          
          ;; Path Resolver
          resolve-path
          register-path
          path-exists-p
          
          ;; Hash Provider
          compute-hash
          verify-hash
          supported-hash-types
          
          ;; External Service
          call-service
          check-service-health
          get-service-metrics
          
          ;; Lifecycle
          initialize-component
          start-component
          stop-component
          restart-component
          component-status
          
          ;; Error Handling
          handle-error
          retry-operation
          circuit-breaker-state))
