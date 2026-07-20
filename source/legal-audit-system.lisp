;;;; LEGAL-AUDIT-SYSTEM.LISP
;;;; Complete audit trail and provenance tracking for legal corpus
;;;; Implements W3C PROV-O with legal extensions
;;;; STAVROPOULOS LAW - Production Ready

(defpackage :orchestrator.audit
  (:use :cl :local-time)
  (:export #:audit-entry
           #:audit-trail
           #:create-audit-entry
           #:log-activity
           #:verify-audit-trail
           #:generate-prov-document
           #:legal-activity
           #:sign-audit-entry
           #:export-audit-report
           #:generate-audit-report
           #:initialize-audit-trail
           #:seal-audit-trail
           #:trail-entries
           #:corpus-name))

(in-package :orchestrator.audit)

;; Special variables defined (with defparameter) further down; declare them
;; special up-front so the functions above their definition compile cleanly.
(declaim (special *signing-enabled* *signing-private-key-path* *signing-public-key-path*
                  *current-actor* *client-ip* *user-agent* *global-audit-trail*))

;;; ============================================================================
;;; AUDIT ENTRY MODEL
;;; ============================================================================

(defclass audit-entry ()
  ((entry-id :initarg :entry-id 
             :accessor entry-id
             :initform (generate-uuid)
             :documentation "Unique identifier for audit entry")
   
   (timestamp :initarg :timestamp
              :accessor entry-timestamp
              :initform (local-time:now)
              :documentation "When the activity occurred")
   
   (activity-type :initarg :activity-type 
                  :accessor activity-type
                  :type symbol
                  :documentation "Type of activity (parse, generate, validate, etc.)")
   
   (actor :initarg :actor 
          :accessor entry-actor
          :documentation "Who performed the activity (WebID)")
   
   (target :initarg :target 
           :accessor entry-target
           :documentation "What was acted upon (article, corpus, etc.)")
   
   (action :initarg :action 
           :accessor entry-action
           :documentation "Specific action performed")
   
   (result :initarg :result 
           :accessor entry-result
           :documentation "Outcome of the action")
   
   (duration :initarg :duration 
             :accessor entry-duration
             :type (or null number)
             :documentation "Time taken in seconds")
   
   (ip-address :initarg :ip-address 
               :accessor entry-ip-address
               :documentation "IP address of actor")
   
   (user-agent :initarg :user-agent 
               :accessor entry-user-agent
               :documentation "Software/browser used")
   
   (justification :initarg :justification 
                  :accessor entry-justification
                  :documentation "Legal justification for action")
   
   (metadata :initarg :metadata 
             :accessor entry-metadata
             :initform (make-hash-table :test 'equal)
             :documentation "Additional metadata")
   
   (signature :initarg :signature 
              :accessor entry-signature
              :documentation "Digital signature of entry")
   
   (hash :initarg :hash 
         :accessor entry-hash
         :documentation "Blake3 hash of entry content")
   
   (previous-hash :initarg :previous-hash 
                  :accessor entry-previous-hash
                  :documentation "Hash of previous entry (blockchain style)")
   
   (prov-data :initarg :prov-data 
              :accessor entry-prov-data
              :documentation "PROV-O structured data")))

(defmethod print-object ((entry audit-entry) stream)
  (print-unreadable-object (entry stream :type t)
    (format stream "~A [~A] ~A->~A" 
            (entry-id entry)
            (format-timestring nil (entry-timestamp entry) 
                              :format '(:year "-" :month "-" :day " " :hour ":" :min))
            (activity-type entry)
            (entry-target entry))))

(defun corpus-name (corpus)
  "Best-effort human-readable name for the corpus object backing a trail.
   Accepts a plain string, a consolidation LEGAL-DOCUMENT, or any object."
  (cond
    ((null corpus) "corpus")
    ((stringp corpus) corpus)
    ((and (find-package :orchestrator.consolidation)
          (ignore-errors
            (funcall (find-symbol "LEGAL-DOCUMENT-P" :orchestrator.consolidation) corpus)))
     (or (funcall (find-symbol "LEGAL-DOCUMENT-TITLE" :orchestrator.consolidation) corpus)
         (funcall (find-symbol "LEGAL-DOCUMENT-ID" :orchestrator.consolidation) corpus)
         "corpus"))
    (t (princ-to-string corpus))))

;;; ============================================================================
;;; LEGAL ACTIVITY MODEL (PROV-O Activity with Legal Extensions)
;;; ============================================================================

(defclass legal-activity ()
  ((activity-id :initarg :id 
                :accessor activity-id
                :initform (generate-activity-id)
                :documentation "Activity URI")
   
   (activity-type :initarg :type 
                  :accessor activity-type
                  :documentation "Type of legal activity")
   
   (started-at :initarg :started-at
               :accessor activity-started-at
               :initform (local-time:now)
               :documentation "Activity start time")
   
   (ended-at :initarg :ended-at 
             :accessor activity-ended-at
             :documentation "Activity end time")
   
   (associated-with :initarg :associated-with 
                    :accessor activity-associated-with
                    :documentation "Agent performing activity (WebID)")
   
   (used-entities :initarg :used 
                  :accessor activity-used-entities
                  :initform nil
                  :documentation "Entities used by activity")
   
   (generated-entities :initarg :generated 
                       :accessor activity-generated-entities
                       :initform nil
                       :documentation "Entities generated by activity")
   
   (informed-by :initarg :informed-by 
                :accessor activity-informed-by
                :documentation "Previous activities that informed this one")
   
   (legal-basis :initarg :legal-basis 
                :accessor activity-legal-basis
                :documentation "Legal authority for activity")
   
   (compliance :initarg :compliance 
               :accessor activity-compliance
               :initform '(:gdpr t :eidas t :eli t)
               :documentation "Compliance attestations")))

;;; ============================================================================
;;; AUDIT TRAIL CONTAINER
;;; ============================================================================

(defclass audit-trail ()
  ((trail-id :initarg :trail-id 
             :accessor trail-id
             :initform (generate-uuid)
             :documentation "Unique trail identifier")
   
   (corpus :initarg :corpus 
           :accessor trail-corpus
           :documentation "Associated corpus")
   
   (entries :initarg :entries 
            :accessor trail-entries
            :initform nil
            :documentation "List of audit entries (newest first)")
   
   (entry-index :initarg :entry-index 
                :accessor trail-entry-index
                :initform (make-hash-table :test 'equal)
                :documentation "Hash table for quick entry lookup")
   
   (merkle-root :initarg :merkle-root 
                :accessor trail-merkle-root
                :documentation "Merkle root of all entries")
   
   (blockchain-anchors :initarg :blockchain-anchors 
                       :accessor trail-blockchain-anchors
                       :initform nil
                       :documentation "Blockchain anchor points")
   
   (sealed :initarg :sealed 
           :accessor trail-sealed-p
           :initform nil
           :documentation "Whether trail is sealed (immutable)")
   
   (created-at :initarg :created-at
               :accessor trail-created-at
               :initform (local-time:now))

   (last-updated :initarg :last-updated
                 :accessor trail-last-updated
                 :initform (local-time:now))))

;;; ============================================================================
;;; AUDIT LOGGING FUNCTIONS
;;; ============================================================================

(defmethod log-activity ((trail audit-trail) activity-type 
                        &key actor target action result duration 
                             justification metadata)
  "Log an activity to the audit trail"
  
  (unless (trail-sealed-p trail)
    (let* ((previous-entry (first (trail-entries trail)))
           (previous-hash (when previous-entry 
                           (entry-hash previous-entry)))
           
           (entry (make-instance 'audit-entry
                                :activity-type activity-type
                                :actor (or actor (get-current-actor))
                                :target target
                                :action action
                                :result result
                                :duration duration
                                :justification justification
                                :metadata (or metadata (make-hash-table :test 'equal))
                                :ip-address (get-client-ip)
                                :user-agent (get-user-agent)
                                :previous-hash previous-hash)))
      
      ;; Compute hash
      (setf (entry-hash entry) (compute-entry-hash entry))
      
      ;; Sign entry
      (when *signing-enabled*
        (setf (entry-signature entry) (sign-entry entry)))
      
      ;; Add to trail
      (push entry (trail-entries trail))
      (setf (gethash (entry-id entry) (trail-entry-index trail)) entry)
      (setf (trail-last-updated trail) (local-time:now))
      
      ;; Log to system
      (log:info () "AUDIT: ~A [~A] ~A → ~A" 
               activity-type 
               (entry-actor entry)
               action
               (if result "SUCCESS" "FAILURE"))
      
      entry)))

(defun compute-entry-hash (entry)
  "Compute SHA-512 hash of audit entry"
  (let ((content (format nil "~A|~A|~A|~A|~A|~A|~A|~A"
                        (entry-id entry)
                        (format-rfc3339-timestring nil (entry-timestamp entry))
                        (activity-type entry)
                        (entry-actor entry)
                        (entry-target entry)
                        (entry-action entry)
                        (entry-result entry)
                        (or (entry-previous-hash entry) "GENESIS"))))

    (orchestrator.hash-authority:compute-hash content :algorithm :sha512)))

;;; ============================================================================
;;; CRYPTOGRAPHIC SIGNING (DARPA-GRADE)
;;; ============================================================================

(defvar *signing-private-key-path* nil
  "Path to RSA private key for cryptographic signing. If nil, uses legacy format.")

(defvar *signing-public-key-path* nil
  "Path to RSA public key for signature verification.")

(defun sign-entry (entry)
  "Sign audit entry with a cryptographic signature, or the legacy format ONLY
   when no signing key is configured.

   [Blocker#1] FAIL-CLOSED. When *signing-private-key-path* is set (the operator
   explicitly requested genuine signatures), a signing failure SIGNALS — it does
   NOT silently downgrade to the forgeable legacy \"SIGNED:\" pseudo-signature.
   That downgrade was a fail-OPEN hole: content = (compute-entry-hash entry) is
   derived purely from public entry fields, so anyone can recompute SIGNED:actor:
   content, and verify-signature would then bless it. An attacker able to induce
   a signing error (remove/corrupt the key, resource exhaustion, library fault)
   could thus write keyless, verifier-passing audit entries. A missing entry is
   safer than a forgeable one — so we signal and let the caller fail loudly."
  (let ((content (compute-entry-hash entry)))
    (if *signing-private-key-path*
        (orchestrator.jws-authority:sign-jws
         content
         *signing-private-key-path*
         :algorithm :rs256)
        ;; Pure-legacy mode (no key configured): backwards-compatible format,
        ;; which verify-signature treats as unverified-legacy, not crypto-strength.
        (format nil "SIGNED:~A:~A"
                (entry-actor entry)
                content))))

;;; ============================================================================
;;; LEGAL COMPLIANCE TRACKING
;;; ============================================================================

(defmethod track-legal-compliance ((trail audit-trail) regulation 
                                   &key status evidence)
  "Track compliance with specific regulation"
  (log-activity trail :compliance-check
               :target regulation
               :action "verify-compliance"
               :result status
               :metadata (alexandria:alist-hash-table
                         `((:regulation . ,regulation)
                           (:status . ,status)
                           (:evidence . ,evidence)
                           (:timestamp . ,(orchestrator.time:get-rfc3339-timestamp))))))

(defmethod verify-gdpr-compliance ((trail audit-trail))
  "Verify GDPR compliance of audit trail"
  (let ((personal-data-entries 
         (remove-if-not (lambda (e)
                         (member (activity-type e) 
                                '(:personal-data-access 
                                  :personal-data-modification
                                  :personal-data-deletion)))
                       (trail-entries trail))))
    
    (dolist (entry personal-data-entries)
      (unless (entry-justification entry)
        (warn "GDPR violation: No justification for personal data access in ~A" 
              (entry-id entry))))
    
    (track-legal-compliance trail :gdpr 
                          :status (if personal-data-entries :review-required :compliant))))

;;; ============================================================================
;;; PROVENANCE GENERATION (PROV-O)
;;; ============================================================================

(defmethod generate-prov-document ((trail audit-trail) &key format)
  "Generate PROV-O document from audit trail"
  (let ((format (or format :turtle)))
    (case format
      (:turtle (generate-prov-turtle trail))
      (:json-ld (generate-prov-jsonld trail))
      (:xml (generate-prov-xml trail))
      (t (error "Unsupported PROV format: ~A" format)))))

(defun generate-prov-turtle (trail)
  "Generate PROV-O in Turtle format"
  (with-output-to-string (stream)
    (format stream "
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix dct: <http://purl.org/dc/terms/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix legal: <~A> .

# Audit Trail Bundle
<~A> a prov:Bundle ;
    dct:title \"Audit Trail for ~A\" ;
    dct:created \"~A\"^^xsd:dateTime ;
    dct:modified \"~A\"^^xsd:dateTime ;
    prov:wasAttributedTo <~A> .

"
            (or (ignore-errors (orchestrator.uris:get-ontology-prefix)) "https://stavropouloslaw.com/ontology")
            (orchestrator.uris:build-audit-uri (trail-id trail))
            (corpus-name (trail-corpus trail))
            (format-rfc3339-timestring nil (trail-created-at trail))
            (format-rfc3339-timestring nil (trail-last-updated trail))
            (orchestrator.uris:get-identity-uri))
    
    ;; Add each audit entry as activity
    (dolist (entry (reverse (trail-entries trail)))
      (format stream "
# Activity: ~A
<~A> a prov:Activity, legal:~A ;
    prov:startedAtTime \"~A\"^^xsd:dateTime ;
    prov:wasAssociatedWith <~A> ;
    legal:hasJustification \"~A\" ;
    legal:hasResult \"~A\" ;
    legal:hasIPAddress \"~A\" ;
    legal:hasSignature \"~A\" .
"
              (entry-id entry)
              (orchestrator.uris:build-activity-uri (entry-id entry))
              (activity-type entry)
              (format-rfc3339-timestring nil (entry-timestamp entry))
              (entry-actor entry)
              (or (entry-justification entry) "")
              (entry-result entry)
              (entry-ip-address entry)
              (or (entry-signature entry) "")))))

(defun generate-prov-jsonld (trail)
  "Generate PROV-O in JSON-LD format"
  (jonathan:to-json
   `(:|@context| (:|prov| "http://www.w3.org/ns/prov#"
                  :|dct| "http://purl.org/dc/terms/"
                  :|legal| ,(or (ignore-errors (orchestrator.uris:get-ontology-prefix)) "https://stavropouloslaw.com/ontology"))
     :|@type| "prov:Bundle"
     :|@id| ,(orchestrator.uris:build-audit-uri (trail-id trail))
     :|dct:title| ,(format nil "Audit Trail for ~A"
                          (corpus-name (trail-corpus trail)))
     :|prov:wasAttributedTo| (:|@id| ,(orchestrator.uris:get-identity-uri))
     :|prov:activity| ,(mapcar (lambda (entry)
                                 `(:|@type| "prov:Activity"
                                   :|@id| ,(orchestrator.uris:build-activity-uri (entry-id entry))
                                   :|prov:startedAtTime| ,(format-rfc3339-timestring
                                                          nil (entry-timestamp entry))
                                   :|prov:wasAssociatedWith| ,(entry-actor entry)
                                   :|legal:hasJustification| ,(entry-justification entry)
                                   :|legal:hasResult| ,(entry-result entry)))
                               (trail-entries trail)))))

(defun %xml-escape (s)
  "Escape a string for inclusion in XML character data / attributes."
  (with-output-to-string (out)
    (loop for ch across (princ-to-string (or s ""))
          do (case ch
               (#\& (write-string "&amp;" out))
               (#\< (write-string "&lt;" out))
               (#\> (write-string "&gt;" out))
               (#\" (write-string "&quot;" out))
               (#\' (write-string "&apos;" out))
               (t (write-char ch out))))))

(defun generate-prov-xml (trail)
  "Generate PROV-O in the W3C PROV-XML serialization."
  (with-output-to-string (stream)
    (format stream "<?xml version=\"1.0\" encoding=\"UTF-8\"?>~%")
    (format stream "<prov:document xmlns:prov=\"http://www.w3.org/ns/prov#\"~%~
                    ~Axmlns:dct=\"http://purl.org/dc/terms/\"~%~
                    ~Axmlns:legal=\"~A\">~%"
            "               " "               "
            (%xml-escape (or (ignore-errors (orchestrator.uris:get-ontology-prefix))
                             "https://stavropouloslaw.com/ontology")))
    (format stream "  <prov:bundle prov:id=\"~A\">~%"
            (%xml-escape (orchestrator.uris:build-audit-uri (trail-id trail))))
    (format stream "    <dct:title>Audit Trail for ~A</dct:title>~%"
            (%xml-escape (corpus-name (trail-corpus trail))))
    (format stream "    <dct:created>~A</dct:created>~%"
            (%xml-escape (format-rfc3339-timestring nil (trail-created-at trail))))
    ;; Activities oldest-first for stable reading order
    (dolist (entry (reverse (trail-entries trail)))
      (format stream "    <prov:activity prov:id=\"~A\">~%"
              (%xml-escape (orchestrator.uris:build-activity-uri (entry-id entry))))
      (format stream "      <prov:type>~A</prov:type>~%"
              (%xml-escape (activity-type entry)))
      (format stream "      <prov:startTime>~A</prov:startTime>~%"
              (%xml-escape (format-rfc3339-timestring nil (entry-timestamp entry))))
      (format stream "      <prov:wasAssociatedWith prov:agent=\"~A\"/>~%"
              (%xml-escape (entry-actor entry)))
      (format stream "      <legal:hasJustification>~A</legal:hasJustification>~%"
              (%xml-escape (or (entry-justification entry) "")))
      (format stream "      <legal:hasResult>~A</legal:hasResult>~%"
              (%xml-escape (entry-result entry)))
      (format stream "    </prov:activity>~%"))
    (format stream "  </prov:bundle>~%")
    (format stream "</prov:document>~%")))

;;; ============================================================================
;;; AUDIT VERIFICATION
;;; ============================================================================

(defmethod verify-audit-trail ((trail audit-trail))
  "Verify integrity of audit trail"
  (log:info () "Verifying audit trail integrity...")
  
  (let ((errors nil)
        (previous-hash "GENESIS"))
    
    ;; Verify hash chain
    (dolist (entry (reverse (trail-entries trail)))
      ;; Check previous hash link
      (unless (equal (entry-previous-hash entry) previous-hash)
        (push (format nil "Hash chain broken at entry ~A" (entry-id entry)) errors))
      
      ;; Verify entry hash
      (let ((computed-hash (compute-entry-hash entry)))
        (unless (equal (entry-hash entry) computed-hash)
          (push (format nil "Hash mismatch for entry ~A" (entry-id entry)) errors)))
      
      ;; Verify signature if present
      (when (entry-signature entry)
        (unless (verify-signature entry)
          (push (format nil "Invalid signature for entry ~A" (entry-id entry)) errors)))
      
      (setf previous-hash (entry-hash entry)))
    
    ;; Verify Merkle root if sealed
    (when (trail-sealed-p trail)
      (let ((computed-merkle (compute-merkle-root trail)))
        (unless (equal (trail-merkle-root trail) computed-merkle)
          (push "Merkle root verification failed" errors))))
    
    (if errors
        (progn
          (log:error () "Audit trail verification FAILED:")
          (dolist (error errors)
            (log:error () "  - ~A" error))
          nil)
        (progn
          (log:info () "✓ Audit trail verification PASSED")
          t))))

(defun verify-signature (entry)
  "Verify digital signature of entry.

   DARPA-GRADE: Supports both cryptographic (JWS) and legacy (SIGNED:) formats.
   - JWS signatures: Verified cryptographically with public key
   - Legacy signatures: Verified by format check (backwards compatible)

   Returns T if signature valid, NIL otherwise."
  (let ((signature (entry-signature entry)))
    (unless signature
      (return-from verify-signature nil))

    (cond
      ;; JWS format detection: contains two dots (header.payload.signature)
      ((and (> (length signature) 10)
            (= (count #\. signature) 2)
            (not (search "SIGNED:" signature)))
       ;; Cryptographic JWS verification
       (if *signing-public-key-path*
           (handler-case
               (let ((content (compute-entry-hash entry)))
                 (orchestrator.jws-authority:verify-jws
                  signature
                  *signing-public-key-path*
                  :expected-payload content))
             (error (e)
               (log:warn () "JWS verification error: ~A" e)
               nil))
           ;; No public key configured - cannot verify JWS
           (progn
             (log:warn () "JWS signature present but no public key configured")
             nil)))

      ;; Legacy SIGNED: format — accepted ONLY in pure-legacy mode (no public key
      ;; configured). [Blocker#1] When a crypto public key IS configured, genuine
      ;; JWS signatures are expected; a legacy "SIGNED:" string is unverifiable and
      ;; trivially forgeable (content derives from public entry fields), so it is
      ;; REJECTED, never blessed as valid. This closes the verify side of the
      ;; fail-open forgery (the sign side is fixed in sign-entry).
      ((search "SIGNED:" signature)
       (if *signing-public-key-path*
           (progn
             (log:warn () "Legacy SIGNED: signature REJECTED — crypto public key configured (entry ~A)"
                       (entry-id entry))
             nil)
           (let* ((content (compute-entry-hash entry))
                  (expected-legacy (format nil "SIGNED:~A:~A"
                                           (entry-actor entry)
                                           content)))
             ;; Constant-time comparison to prevent timing attacks
             (orchestrator.jws-authority:constant-time-string= signature expected-legacy))))

      ;; Unknown format
      (t
       (log:warn () "Unknown signature format for entry ~A" (entry-id entry))
       nil))))

(defun compute-merkle-root (trail)
  "Merkle root της αλυσίδας audit entries μέσω της ΜΙΑΣ έδρας orchestrator.merkle
   (RFC 6962: domain-separated φύλλα/κόμβοι + unbalanced split). [P1.5-A] Το
   προηγούμενο SHA-512 string-concat δέντρο (compute-merkle-tree-root + hash-pair,
   με odd-node malleability) αντικαταστάθηκε. Κενή αλυσίδα -> NIL (format-compat).
   Επιστρέφει bare hex (η μορφή του audit trail)."
  (let ((hashes (mapcar #'entry-hash (trail-entries trail))))
    (if (null hashes)
        nil
        (subseq (orchestrator.merkle:merkle-root-of-strings hashes) 7))))

;;; ============================================================================
;;; AUDIT REPORTS
;;; ============================================================================

(defmethod generate-audit-report ((trail audit-trail) &key (format :text) 
                                  start-date end-date)
  "Generate audit report for specified period"
  (let ((entries (if (or start-date end-date)
                    (filter-entries-by-date trail start-date end-date)
                    (trail-entries trail))))
    
    (case format
      (:text (generate-text-report trail entries))
      (:html (generate-html-report trail entries))
      (:csv (generate-csv-report trail entries))
      (:json (generate-json-report trail entries))
      (t (error "Unsupported report format: ~A" format)))))

(defun generate-text-report (trail entries)
  "Generate plain text audit report"
  (with-output-to-string (stream)
    (format stream "
================================================================================
AUDIT REPORT - ~A
================================================================================
Trail ID: ~A
Corpus: ~A
Period: ~A to ~A
Total Entries: ~D
Status: ~A
================================================================================

"
            (format-timestring nil (local-time:now) :format '(:year "-" :month "-" :day))
            (trail-id trail)
            (corpus-name (trail-corpus trail))
            (format-timestring nil (trail-created-at trail))
            (format-timestring nil (trail-last-updated trail))
            (length entries)
            (if (trail-sealed-p trail) "SEALED" "ACTIVE"))
    
    ;; Summary by activity type
    (format stream "ACTIVITY SUMMARY:~%")
    (let ((activity-counts (make-hash-table)))
      (dolist (entry entries)
        (incf (gethash (activity-type entry) activity-counts 0)))
      
      (maphash (lambda (type count)
                (format stream "  ~A: ~D~%" type count))
              activity-counts))
    
    (format stream "~%DETAILED LOG:~%")
    (format stream "~100@{-~}~%")
    
    ;; Detailed entries
    (dolist (entry entries)
      (format stream "~A | ~A | ~A | ~A → ~A | ~A~%"
              (format-timestring nil (entry-timestamp entry) 
                               :format '(:year "-" :month "-" :day " " :hour ":" :min ":" :sec))
              (activity-type entry)
              (entry-actor entry)
              (entry-action entry)
              (entry-target entry)
              (if (entry-result entry) "SUCCESS" "FAILURE")))))

(defun generate-html-report (trail entries)
  "Generate HTML audit report"
  (with-output-to-string (stream)
    (format stream "<!DOCTYPE html>
<html>
<head>
    <title>Audit Report - ~A</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .success { color: green; }
        .failure { color: red; }
    </style>
</head>
<body>
    <h1>Audit Report</h1>
    <p><strong>Corpus:</strong> ~A</p>
    <p><strong>Generated:</strong> ~A</p>
    <p><strong>Total Entries:</strong> ~D</p>
    
    <table>
        <thead>
            <tr>
                <th>Timestamp</th>
                <th>Activity</th>
                <th>Actor</th>
                <th>Action</th>
                <th>Target</th>
                <th>Result</th>
            </tr>
        </thead>
        <tbody>"
            (corpus-name (trail-corpus trail))
            (corpus-name (trail-corpus trail))
            (format-timestring nil (local-time:now))
            (length entries))
    
    (dolist (entry entries)
      (format stream "
            <tr>
                <td>~A</td>
                <td>~A</td>
                <td>~A</td>
                <td>~A</td>
                <td>~A</td>
                <td class=\"~A\">~A</td>
            </tr>"
              (format-timestring nil (entry-timestamp entry))
              (activity-type entry)
              (entry-actor entry)
              (entry-action entry)
              (entry-target entry)
              (if (entry-result entry) "success" "failure")
              (if (entry-result entry) "✓" "✗")))
    
    (format stream "
        </tbody>
    </table>
</body>
</html>")))

(defun %csv-field (s)
  "Quote a CSV field per RFC 4180 (always quoted; embedded quotes doubled)."
  (with-output-to-string (out)
    (write-char #\" out)
    (loop for ch across (princ-to-string (or s ""))
          do (if (char= ch #\") (write-string "\"\"" out) (write-char ch out)))
    (write-char #\" out)))

(defun generate-csv-report (trail entries)
  "Generate an RFC 4180 CSV audit report."
  (declare (ignore trail))
  (with-output-to-string (stream)
    (format stream "timestamp,activity_type,actor,action,target,result,entry_id,hash~A"
            #\Newline)
    (dolist (entry entries)
      (format stream "~A,~A,~A,~A,~A,~A,~A,~A~A"
              (%csv-field (format-rfc3339-timestring nil (entry-timestamp entry)))
              (%csv-field (activity-type entry))
              (%csv-field (entry-actor entry))
              (%csv-field (entry-action entry))
              (%csv-field (entry-target entry))
              (%csv-field (if (entry-result entry) "SUCCESS" "FAILURE"))
              (%csv-field (entry-id entry))
              (%csv-field (entry-hash entry))
              #\Newline))))

(defun generate-json-report (trail entries)
  "Generate a JSON audit report (trail metadata + entries)."
  (jonathan:to-json
   `(:|trail_id| ,(trail-id trail)
     :|corpus| ,(corpus-name (trail-corpus trail))
     :|created_at| ,(format-rfc3339-timestring nil (trail-created-at trail))
     :|last_updated| ,(format-rfc3339-timestring nil (trail-last-updated trail))
     :|sealed| ,(trail-sealed-p trail)
     :|merkle_root| ,(and (slot-boundp trail 'merkle-root) (trail-merkle-root trail))
     :|total_entries| ,(length entries)
     :|entries|
     ,(mapcar (lambda (entry)
                `(:|entry_id| ,(entry-id entry)
                  :|timestamp| ,(format-rfc3339-timestring nil (entry-timestamp entry))
                  :|activity_type| ,(princ-to-string (activity-type entry))
                  :|actor| ,(princ-to-string (entry-actor entry))
                  :|action| ,(princ-to-string (entry-action entry))
                  :|target| ,(princ-to-string (entry-target entry))
                  :|result| ,(if (entry-result entry) "SUCCESS" "FAILURE")
                  :|hash| ,(entry-hash entry)
                  :|previous_hash| ,(and (slot-boundp entry 'previous-hash)
                                         (entry-previous-hash entry))
                  :|signature| ,(and (slot-boundp entry 'signature) (entry-signature entry))))
              entries))))

;;; ============================================================================
;;; UTILITY FUNCTIONS
;;; ============================================================================

(defun generate-uuid ()
  "Generate UUID v4"
  (format nil "~8,'0X-~4,'0X-~4,'0X-~4,'0X-~12,'0X"
          (random (expt 2 32))
          (random (expt 2 16))
          (logior #x4000 (random (expt 2 16)))
          (logior #x8000 (random (expt 2 16)))
          (random (expt 2 48))))

(defun generate-activity-id ()
  "Generate unique activity ID"
  (format nil "activity-~A-~A"
          (format-timestring nil (local-time:now) :format '(:year :month :day))
          (random (expt 2 32))))

(defun get-current-actor ()
  "Get current actor WebID"
  (or *current-actor* (orchestrator.uris:get-identity-uri)))

(defun get-client-ip ()
  "Get client IP address"
  (or *client-ip* "127.0.0.1"))

(defun get-user-agent ()
  "Get user agent string"
  (or *user-agent* "ORCHESTRATOR/1.1"))

(defun filter-entries-by-date (trail start-date end-date)
  "Filter audit entries by date range"
  (remove-if-not (lambda (entry)
                  (let ((timestamp (entry-timestamp entry)))
                    (and (or (null start-date)
                            (timestamp>= timestamp start-date))
                         (or (null end-date)
                            (timestamp<= timestamp end-date)))))
                (trail-entries trail)))

;;; ============================================================================
;;; GLOBAL AUDIT MANAGEMENT
;;; ============================================================================

(defparameter *global-audit-trail* nil
  "Global audit trail instance")

(defparameter *signing-enabled* nil
  "Whether to sign audit entries")

(defparameter *current-actor* nil
  "Current actor WebID")

(defparameter *client-ip* nil
  "Current client IP")

(defparameter *user-agent* nil
  "Current user agent")

(defun initialize-audit-trail (corpus)
  "Initialize global audit trail for corpus"
  (setf *global-audit-trail*
        (make-instance 'audit-trail
                      :corpus corpus))
  
  (log-activity *global-audit-trail* :initialization
               :target (corpus-name corpus)
               :action "initialize-audit-trail"
               :result t
               :justification "System initialization")
  
  *global-audit-trail*)

(defun seal-audit-trail ()
  "Seal audit trail (make immutable)"
  (when *global-audit-trail*
    (setf (trail-merkle-root *global-audit-trail*)
          (compute-merkle-root *global-audit-trail*))
    (setf (trail-sealed-p *global-audit-trail*) t)
    
    (log:info () "Audit trail sealed with Merkle root: ~A" 
             (trail-merkle-root *global-audit-trail*))
    
    *global-audit-trail*))

(defun export-audit-trail (filename &key (format :turtle) authority)
  "Export audit trail to file"
  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :provenance"))
  (when *global-audit-trail*
    (let ((content (generate-prov-document *global-audit-trail* :format format)))
      (orchestrator.write-authority:emit-graph content filename :authority authority)
      (log:info () "Audit trail exported to ~A" filename))))

;;; ============================================================================
;;; END OF LEGAL-AUDIT-SYSTEM.LISP
;;; ============================================================================
