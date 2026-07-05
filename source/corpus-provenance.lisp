;;;; source/corpus-provenance.lisp
;;;; ============================================================================
;;;; LEGAL PROVENANCE  ("how did each article come to read the way it does")
;;;; ============================================================================
;;;;
;;;; Wires the restored legal-audit PROV-O capability to the consolidation
;;;; engine. Every consolidated provision carries its real provenance — the
;;;; amending act that last touched it and the date that took effect. This
;;;; bridge turns that into a W3C PROV-O document (Turtle / JSON-LD / PROV-XML)
;;;; via orchestrator.audit, with NO randomness: entry ids and timestamps are
;;;; derived from the act + effective date, so the output is byte-identical
;;;; across runs. Exposed as /<corpus>/provenance[.ttl|.jsonld|.xml].
;;;; ============================================================================

(defpackage :orchestrator.corpus-provenance
  (:use :cl)
  (:import-from :local-time #:parse-timestring #:encode-timestamp)
  (:export #:corpus-provenance))

(in-package :orchestrator.corpus-provenance)

(defun %cons (name) (find-symbol name :orchestrator.consolidation))
(defun %audit (name) (find-symbol name :orchestrator.audit))
(defun %uris (name) (find-symbol name :orchestrator.uris))

(defun %ensure-uris (base-uri)
  "Guarantee orchestrator.uris has at least a base + ontology prefix so the
   PROV-O generators never error. Idempotent; never overrides existing config."
  (let ((cfg (symbol-value (%uris "*CANONICAL-CONFIG*"))))
    (unless (gethash "base_uri" cfg)
      (funcall (%uris "CONFIGURE-CANONICAL-URIS")
               :base-uri base-uri
               :ontology-prefix (format nil "~A/ontology" base-uri)))))

(defun %ts (date-string)
  "Parse an ISO date (YYYY-MM-DD…) to a local-time timestamp; fall back to a
   fixed deterministic epoch when absent/malformed."
  (or (and date-string (ignore-errors (parse-timestring date-string)))
      (encode-timestamp 0 0 0 0 1 1 2025 :timezone local-time:+utc-zone+)))

(defun %status->activity (status)
  "Map a consolidation status to a PROV/legal activity type."
  (case status
    (:amended  :amendment)
    (:repealed :repeal)
    (:inserted :insertion)
    (:restored :restoration)
    (:original :enactment)
    (t         :modification)))

(defun %provenance-provisions (document)
  "Top-level provisions that carry a real amending act (i.e. were touched by
   legislation after enactment), in document order."
  (remove-if-not (lambda (p) (funcall (%cons "PROVISION-SOURCE-ACT") p))
                 (funcall (%cons "LEGAL-DOCUMENT-PROVISIONS") document)))

(defun %latest-date (provisions)
  (let ((dates (remove nil (mapcar (lambda (p) (funcall (%cons "PROVISION-SOURCE-DATE") p))
                                   provisions))))
    (when dates (first (sort (copy-list dates) #'string>)))))

(defun corpus-provenance (document
                          &key (base-uri "https://stavropouloslaw.com/eli")
                               (format :turtle))
  "Build a deterministic PROV-O provenance document for the consolidated
   DOCUMENT from its real amendment provenance. FORMAT is :turtle :json-ld :xml."
  (%ensure-uris base-uri)
  (let* ((provs (%provenance-provisions document))
         (latest (%ts (%latest-date provs)))
         (actor (or (ignore-errors (funcall (%uris "GET-IDENTITY-URI")))
                    (format nil "~A/#me" base-uri)))
         (entries '()))
    ;; Build entries directly from real provenance. We PUSH while walking the
    ;; document in order, so ENTRIES ends up newest-first — exactly the
    ;; convention the audit trail and PROV generators expect (they reverse back
    ;; to document order on output).
    (dolist (p provs)
      (let* ((eid (funcall (%cons "PROVISION-EID") p))
             (act (funcall (%cons "PROVISION-SOURCE-ACT") p))
             (date (funcall (%cons "PROVISION-SOURCE-DATE") p))
             (status (funcall (%cons "PROVISION-STATUS") p)))
        (push (make-instance (%audit "AUDIT-ENTRY")
                             :entry-id (format nil "~A--~A" eid act)
                             :timestamp (%ts date)
                             :activity-type (%status->activity status)
                             :actor actor
                             :target eid
                             :action (string-downcase (symbol-name (or status :modification)))
                             :result t
                             :ip-address ""
                             :signature nil
                             :justification
                             (format nil "Article ~A ~(~A~) by ~A, effective ~A"
                                     eid (or status :modified) act (or date "n/a")))
              entries)))
    (let ((trail (make-instance (%audit "AUDIT-TRAIL")
                                :trail-id (format nil "~A-provenance"
                                                  (or (funcall (%cons "LEGAL-DOCUMENT-ID") document)
                                                      "corpus"))
                                :corpus document
                                :entries entries
                                :created-at latest
                                :last-updated latest)))
      (funcall (%audit "GENERATE-PROV-DOCUMENT") trail :format format))))
