;;;; systems/orchestrator-ai-core/package.lisp
;;;; Package for AI Authority Layer

(in-package :cl-user)

(defpackage #:orchestrator.ai-core
  (:use :cl)
  (:import-from :alexandria :when-let)
  (:export
   ;; === AI BEACONS ===
   #:ai-beacon
   #:ai-beacon-authority
   #:ai-beacon-weight
   
   ;; === INGEST MANIFEST ===
   #:write-ai-ingest-manifest
   #:generate-article-manifest-entry
   #:manifest-entry-to-json
   #:validate-manifest
   #:manifest-stats
   #:write-all-corpus-manifests
   #:append-article-to-manifest
   
   ;; === PROVENANCE MODEL ===
   #:provenance-record
   #:provenance-activity
   #:provenance-timestamp
   #:provenance-agent
   #:make-provenance-record
   #:provenance-chain
   #:chain-activities              ; Public accessor
   #:chain-master-hash             ; Public accessor
   #:chain-article-number          ; Public accessor
   #:chain-corpus-id               ; Public accessor
   #:add-provenance-activity
   #:export-provenance-json
   #:write-article-provenance
   #:write-corpus-provenance
   #:build-article-provenance-chain
   
   ;; === FEEDS ===
   #:generate-ai-feed
   
   ;; === CITATION STRATEGY ===
   #:compute-citation-weight
   #:authority-score
   
   ;; === DETERMINISTIC EXPORT ===
   #:*build-timestamp-override*
   #:current-build-timestamp
   #:deterministic-hash
   #:effective-deterministic-timestamp
   
   ;; === AI CONFIGURATION ===
   #:ai-export-config
   #:make-ai-export-config
   #:make-default-ai-export-config
   #:config-output-root
   #:config-dataset-name
   #:config-dataset-version
   #:config-publisher
   #:config-canonical-base-uri
   #:config-manifest-filename
   #:config-provenance-subdir
   #:config-include-content-text
   #:config-include-html-snippet
   #:config-deterministic
   #:config-fixed-timestamp
   #:parse-ai-config-from-plist
   #:load-ai-config-from-yaml
   #:write-ai-ingest-manifest-with-config
   #:write-corpus-provenance-with-config
   #:generate-article-manifest-entry-with-config
   #:with-ai-config
   #:*current-ai-config*))
