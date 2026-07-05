;;;; systems/orchestrator-spec/types.lisp
;;;; Type definitions for Orchestrator

(in-package :orchestrator.spec)

;;; Article States
(deftype article-state ()
  "Valid states for an article in the processing pipeline"
  '(member :queued :parsing :generating :validating :reviewing
           :hashing :anchoring :deploying :live :failed :rejected))

;;; Pipeline States
(deftype pipeline-state ()
  "Valid states for a pipeline execution"
  '(member :initialized :running :paused :completed :failed :aborted))

;;; Backend Types
(deftype backend-type ()
  "Supported blockchain/storage backends"
  '(member :ethereum :arweave :ipfs :mock :filecoin :storj))

;;; Artifact Types
(deftype artifact-type ()
  "Types of artifacts produced by the pipeline"
  '(member :rdf-turtle :json-ld :html-rdfa :pdf :xml :hash :blockchain-proof
           :manifest :identity :publisher :shacl-report))

;;; Stage Names (extensible via symbols)
(deftype stage-name ()
  "Stage identifier - any symbol"
  'symbol)

;;; ELI URI Type
(deftype eli-uri ()
  "European Legislation Identifier - must be a string starting with http(s)://"
  '(and string (satisfies valid-eli-uri-p)))

(defun valid-eli-uri-p (uri)
  "Validate ELI URI format"
  (and (stringp uri)
       (or (alexandria:starts-with-subseq "http://" uri)
           (alexandria:starts-with-subseq "https://" uri))
       (search "eli" uri)))

;;; Hash Type
(deftype content-hash ()
  "Content hash (Blake3, SHA256, etc.) - hexadecimal string"
  '(and string (satisfies valid-hash-p)))

(defun valid-hash-p (hash)
  "Validate hash format (hexadecimal string)"
  (and (stringp hash)
       (> (length hash) 0)
       (every (lambda (c) (find c "0123456789abcdefABCDEF")) hash)))

;;; Timestamp Type
(deftype iso8601-timestamp ()
  "ISO 8601 timestamp string"
  'string)

;;; Language Code Type
(deftype language-code ()
  "ISO 639-1 two-letter language code"
  '(and string (satisfies valid-language-code-p)))

(defun valid-language-code-p (code)
  "Validate language code (two letters)"
  (and (stringp code)
       (= (length code) 2)
       (every #'alpha-char-p code)))
