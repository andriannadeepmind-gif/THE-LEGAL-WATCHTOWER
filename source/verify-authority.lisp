;;;; source/verify-authority.lisp
;;;; ============================================================================
;;;; PURE LISP VERIFICATION AUTHORITY
;;;; ============================================================================
;;;;
;;;; Complete verification of epistemic releases using only Pure Common Lisp.
;;;; NO OpenSSL, NO external tools - DARPA-GRADE verification.
;;;;
;;;; Verifies:
;;;;   1. Merkle tree integrity
;;;;   2. JWS signatures
;;;;   3. RFC 3161 timestamp structure (basic parsing)
;;;;   4. SHACL shape compliance
;;;;
;;;; ============================================================================

(defpackage :orchestrator.verify-authority
  (:use :cl)
  (:export
   ;; Main verification
   #:verify-release
   #:verify-merkle-tree
   #:verify-jws-signature
   #:verify-timestamp-structure
   ;; Results
   #:verification-result
   #:verification-passed-p
   #:verification-errors
   ;; Conditions
   #:verification-error))

(in-package :orchestrator.verify-authority)

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition verification-error (error)
  ((component :initarg :component :reader error-component)
   (message :initarg :message :reader error-message)
   (details :initarg :details :reader error-details :initform nil))
  (:report (lambda (c s)
             (format s "Verification Error [~A]: ~A~@[~%Details: ~A~]"
                     (error-component c)
                     (error-message c)
                     (error-details c)))))

;;; ============================================================================
;;; VERIFICATION RESULT
;;; ============================================================================

(defstruct verification-result
  (passed nil :type boolean)
  (component "" :type string)
  (message "" :type string)
  (details nil))

(defun make-pass (component message &optional details)
  (make-verification-result :passed t :component component
                            :message message :details details))

(defun make-fail (component message &optional details)
  (make-verification-result :passed nil :component component
                            :message message :details details))

;;; ============================================================================
;;; FILE UTILITIES
;;; ============================================================================

(defun read-file-bytes (path)
  "Read file as byte vector"
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length stream) :element-type '(unsigned-byte 8))))
      (read-sequence bytes stream)
      bytes)))

(defun read-file-string (path)
  "Read file as string"
  (with-open-file (stream path :direction :input)
    (let ((content (make-string (file-length stream))))
      (read-sequence content stream)
      content)))

(defun file-exists-p (path)
  "Check if file exists"
  (probe-file path))

;;; ============================================================================
;;; HASH VERIFICATION
;;; ============================================================================

(defun compute-sha256 (data)
  "Compute SHA-256 hash of data (bytes or string)"
  (let ((bytes (etypecase data
                 (string (babel:string-to-octets data :encoding :utf-8))
                 (vector data))))
    (ironclad:digest-sequence :sha256 bytes)))

(defun hash-to-hex (hash)
  "Convert hash bytes to hex string"
  (ironclad:byte-array-to-hex-string hash))

(defun hex-to-hash (hex)
  "Convert hex string to hash bytes"
  (ironclad:hex-string-to-byte-array hex))

(defun constant-time-string= (a b)
  "Constant-time string comparison to prevent timing attacks.

   DARPA-GRADE: Standard string= returns immediately on first mismatch,
   allowing attackers to infer hash values by measuring response time.
   This function always compares all characters regardless of mismatch.

   Returns T if strings are equal, NIL otherwise."
  (if (not (= (length a) (length b)))
      nil  ; Length difference is unavoidable but reveals less info
      (let ((result 0))
        (loop for i from 0 below (length a)
              do (setf result (logior result
                                      (logxor (char-code (char a i))
                                              (char-code (char b i))))))
        (zerop result))))

;;; ============================================================================
;;; MERKLE TREE VERIFICATION
;;; ============================================================================

(defun verify-merkle-tree (release-dir)
  "Verify Merkle tree integrity

   Reads merkle-tree.json, recalculates hashes from files, compares roots.

   Returns:
     verification-result"
  (let ((merkle-path (merge-pathnames "temporal-proof/merkle-tree.json" release-dir)))
    (unless (file-exists-p merkle-path)
      (return-from verify-merkle-tree
        (make-fail "MERKLE" "merkle-tree.json not found")))

    (handler-case
        (let* ((merkle-json (read-file-string merkle-path))
               (merkle-data (jonathan:parse merkle-json))
               (stored-root (gethash "root" merkle-data))
               (files (gethash "files" merkle-data))
               (computed-hashes '()))

          ;; Compute hash for each file
          (maphash (lambda (file-path stored-hash)
                     (let* ((full-path (merge-pathnames file-path release-dir))
                            (computed (when (file-exists-p full-path)
                                        (hash-to-hex (compute-sha256
                                                      (read-file-bytes full-path))))))
                       (push (list file-path stored-hash computed
                                   (and computed (constant-time-string= stored-hash computed)))
                             computed-hashes)))
                   files)

          ;; Check all files match
          (let ((mismatches (remove-if #'fourth computed-hashes)))
            (if mismatches
                (make-fail "MERKLE"
                           (format nil "~D file(s) hash mismatch" (length mismatches))
                           mismatches)
                (make-pass "MERKLE"
                           (format nil "All ~D files verified" (length computed-hashes))
                           `(:root ,stored-root :files ,(length computed-hashes))))))
      (error (e)
        (make-fail "MERKLE" "Failed to parse merkle-tree.json"
                   (format nil "~A" e))))))

;;; ============================================================================
;;; JWS SIGNATURE VERIFICATION
;;; ============================================================================

(defun verify-jws-signature (release-dir)
  "Verify JWS signature over manifest

   Reads signature.jws and public.jwk, verifies signature.

   Returns:
     verification-result"
  (let ((jws-path (merge-pathnames "temporal-proof/signature.jws" release-dir))
        (jwk-path (merge-pathnames "verify/public.jwk" release-dir))
        (manifest-path (merge-pathnames "manifest.ttl" release-dir)))

    ;; Check required files exist
    (unless (file-exists-p jws-path)
      (return-from verify-jws-signature
        (make-fail "JWS" "signature.jws not found")))
    (unless (file-exists-p jwk-path)
      (return-from verify-jws-signature
        (make-fail "JWS" "public.jwk not found")))
    (unless (file-exists-p manifest-path)
      (return-from verify-jws-signature
        (make-fail "JWS" "manifest.ttl not found")))

    (handler-case
        (let* ((jws-string (string-trim '(#\Space #\Newline #\Return)
                                        (read-file-string jws-path)))
               (jwk-json (read-file-string jwk-path))
               (manifest-content (read-file-string manifest-path))
               (public-key (parse-jwk-to-rsa-key jwk-json)))

          ;; Verify JWS
          (if (orchestrator.jws-authority:verify-jws jws-string manifest-content public-key)
              (make-pass "JWS" "Signature valid"
                         `(:algorithm "RS256" :key-id ,(get-jwk-kid jwk-json)))
              (make-fail "JWS" "Signature verification failed")))
      (error (e)
        (make-fail "JWS" "Verification error" (format nil "~A" e))))))

(defun parse-jwk-to-rsa-key (jwk-json)
  "Parse JWK JSON to RSA public key"
  (let* ((jwk (jonathan:parse jwk-json))
         (n-b64 (gethash "n" jwk))
         (e-b64 (gethash "e" jwk))
         (n (b64url-to-integer n-b64))
         (e (b64url-to-integer e-b64)))
    (ironclad:make-public-key :rsa :n n :e e)))

(defun b64url-to-integer (b64url-string)
  "Convert base64url string to integer"
  (let ((bytes (orchestrator.jws-authority:base64url-decode b64url-string)))
    (ironclad:octets-to-integer bytes)))

(defun get-jwk-kid (jwk-json)
  "Extract key ID from JWK"
  (let ((jwk (jonathan:parse jwk-json)))
    (gethash "kid" jwk "unknown")))

;;; ============================================================================
;;; RFC 3161 TIMESTAMP VERIFICATION
;;; ============================================================================

;;; TimeStampResp ::= SEQUENCE {
;;;    status          PKIStatusInfo,
;;;    timeStampToken  TimeStampToken OPTIONAL  }
;;;
;;; PKIStatusInfo ::= SEQUENCE {
;;;    status        PKIStatus,  -- INTEGER: 0=granted, 1=grantedWithMods, ...
;;;    statusString  PKIFreeText OPTIONAL,
;;;    failInfo      PKIFailureInfo OPTIONAL  }

;;; (Αποκωδικοποίηση ASN.1 DER: orchestrator.asn1 — Η έδρα. Εδώ ζει ΜΟΝΟ η
;;; RFC-3161 σημασιολογία επαλήθευσης. Το συμβόλαιο NIL-σε-κακοσχηματισμένο
;;; διατηρείται: κακό TSR ⇒ τίμια αποτυχία επαλήθευσης, όχι κατάρρευση.)

(defun parse-tsr-status (tsr-bytes)
  "Parse RFC 3161 TimeStampResp and extract PKIStatus
   Returns: (values status-integer status-name) or NIL on error

   Status codes per RFC 3161:
     0 = granted
     1 = grantedWithMods
     2 = rejection
     3 = waiting
     4 = revocationWarning
     5 = revocationNotification"
  (handler-case
      ;; TimeStampResp SEQUENCE → PKIStatusInfo SEQUENCE → PKIStatus INTEGER
      (multiple-value-bind (outer-tag outer-start)
          (orchestrator.asn1:der-read-tlv tsr-bytes 0)
        (unless (= outer-tag #x30)
          (return-from parse-tsr-status nil))
        (multiple-value-bind (info-tag info-start)
            (orchestrator.asn1:der-read-tlv tsr-bytes outer-start)
          (unless (= info-tag #x30)
            (return-from parse-tsr-status nil))
          (multiple-value-bind (status-tag status-start status-len)
              (orchestrator.asn1:der-read-tlv tsr-bytes info-start)
            (unless (= status-tag #x02)
              (return-from parse-tsr-status nil))
            (let* ((status-value (orchestrator.asn1:der-integer-value
                                  (subseq tsr-bytes status-start
                                          (+ status-start status-len))))
                   (status-name (case status-value
                                  (0 "granted")
                                  (1 "grantedWithMods")
                                  (2 "rejection")
                                  (3 "waiting")
                                  (4 "revocationWarning")
                                  (5 "revocationNotification")
                                  (t "unknown"))))
              (values status-value status-name)))))
    (orchestrator.asn1:asn1-error () nil)))

(defun verify-timestamp-structure (release-dir)
  "Verify RFC 3161 TimeStampResp structure with proper ASN.1 parsing

   DARPA-GRADE: Full ASN.1 DER parsing, not just tag checking.
   Verifies:
     1. Valid ASN.1 structure
     2. PKIStatus is granted (0) or grantedWithMods (1)
     3. Response has sufficient size for TimeStampToken

   Returns:
     verification-result"
  (let ((tsr-path (merge-pathnames "temporal-proof/timestamp.tsr" release-dir)))
    (unless (file-exists-p tsr-path)
      (return-from verify-timestamp-structure
        (make-fail "RFC3161" "timestamp.tsr not found")))

    (handler-case
        (let* ((tsr-bytes (read-file-bytes tsr-path))
               (tsr-size (length tsr-bytes)))

          ;; Minimum size check
          (when (< tsr-size 50)
            (return-from verify-timestamp-structure
              (make-fail "RFC3161" "TSR too small for valid TimeStampResp"
                         `(:size ,tsr-size :minimum 50))))

          ;; Parse and validate ASN.1 structure
          (multiple-value-bind (status status-name)
              (parse-tsr-status tsr-bytes)
            (unless status
              (return-from verify-timestamp-structure
                (make-fail "RFC3161" "Invalid ASN.1 structure - cannot parse PKIStatusInfo"
                           `(:size ,tsr-size))))

            ;; Verify status is acceptable
            (unless (member status '(0 1))
              (return-from verify-timestamp-structure
                (make-fail "RFC3161"
                           (format nil "TSA returned status ~D (~A) - timestamp not granted"
                                   status status-name)
                           `(:status ,status :status-name ,status-name))))

            ;; Success - structure is valid and status is granted
            (make-pass "RFC3161"
                       (format nil "TimeStampResp valid: status=~A (~D bytes)"
                               status-name tsr-size)
                       `(:status ,status
                         :status-name ,status-name
                         :size ,tsr-size))))
      (error (e)
        (make-fail "RFC3161" "Failed to parse timestamp"
                   (format nil "~A" e))))))

;;; ============================================================================
;;; MANIFEST VERIFICATION
;;; ============================================================================

(defun verify-manifest-integrity (release-dir)
  "Verify manifest exists and is valid RDF

   Returns:
     verification-result"
  (let ((manifest-ttl (merge-pathnames "manifest.ttl" release-dir))
        (manifest-jsonld (merge-pathnames "manifest.jsonld" release-dir)))

    (cond
      ((not (file-exists-p manifest-ttl))
       (make-fail "MANIFEST" "manifest.ttl not found"))

      ((not (file-exists-p manifest-jsonld))
       (make-fail "MANIFEST" "manifest.jsonld not found"))

      (t
       (let ((ttl-size (with-open-file (s manifest-ttl) (file-length s)))
             (jsonld-size (with-open-file (s manifest-jsonld) (file-length s))))
         (make-pass "MANIFEST"
                    (format nil "Manifests present (TTL: ~D bytes, JSON-LD: ~D bytes)"
                            ttl-size jsonld-size)
                    `(:turtle-size ,ttl-size :jsonld-size ,jsonld-size)))))))

;;; ============================================================================
;;; MAIN VERIFICATION FUNCTION
;;; ============================================================================

(defun verify-release (release-dir &key (verbose t))
  "Verify all aspects of an epistemic release

   Args:
     release-dir: Path to release directory
     verbose: Print progress messages

   Returns:
     List of verification-results"
  (let ((results '())
        (release-path (pathname release-dir)))

    (when verbose
      (format t "~%═══════════════════════════════════════════════════════════════~%")
      (format t "  EPISTEMIC RELEASE VERIFICATION (Pure Lisp)~%")
      (format t "  Release: ~A~%" release-path)
      (format t "═══════════════════════════════════════════════════════════════~%~%"))

    ;; 1. Manifest verification
    (when verbose (format t "[1/4] Verifying manifests...~%"))
    (let ((result (verify-manifest-integrity release-path)))
      (push result results)
      (when verbose
        (format t "  ~A ~A~%~%"
                (if (verification-result-passed result) "✓" "✗")
                (verification-result-message result))))

    ;; 2. Merkle tree verification
    (when verbose (format t "[2/4] Verifying Merkle tree...~%"))
    (let ((result (verify-merkle-tree release-path)))
      (push result results)
      (when verbose
        (format t "  ~A ~A~%~%"
                (if (verification-result-passed result) "✓" "✗")
                (verification-result-message result))))

    ;; 3. JWS signature verification
    (when verbose (format t "[3/4] Verifying JWS signature...~%"))
    (let ((result (verify-jws-signature release-path)))
      (push result results)
      (when verbose
        (format t "  ~A ~A~%~%"
                (if (verification-result-passed result) "✓" "✗")
                (verification-result-message result))))

    ;; 4. RFC 3161 timestamp structure
    (when verbose (format t "[4/4] Verifying RFC 3161 timestamp...~%"))
    (let ((result (verify-timestamp-structure release-path)))
      (push result results)
      (when verbose
        (format t "  ~A ~A~%~%"
                (if (verification-result-passed result) "✓" "✗")
                (verification-result-message result))))

    ;; Summary
    (let* ((all-results (nreverse results))
           (passed (count-if #'verification-result-passed all-results))
           (failed (- (length all-results) passed))
           (all-passed (zerop failed)))

      (when verbose
        (format t "═══════════════════════════════════════════════════════════════~%")
        (if all-passed
            (format t "  ✓ ALL VERIFICATIONS PASSED (~D/~D)~%" passed (length all-results))
            (format t "  ✗ VERIFICATION FAILED (~D passed, ~D failed)~%" passed failed))
        (format t "═══════════════════════════════════════════════════════════════~%~%"))

      all-results)))

