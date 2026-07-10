;;;; source/timestamp-authority.lisp
;;;; ============================================================================
;;;; TIMESTAMP AUTHORITY - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; RFC 3161 Timestamp Protocol implementation.
;;;; Uses Drakma for HTTP, Ironclad for hashing.
;;;;
;;;; AUTHORITY PATTERN:
;;;; - Pure Lisp ASN.1 encoding for TimeStampReq
;;;; - HTTP submission to TSA via Drakma
;;;; - Deterministic request creation
;;;;
;;;; DARPA-GRADE: No OpenSSL subprocess, no curl, pure Lisp.
;;;; ============================================================================

(defpackage :orchestrator.timestamp-authority
  (:use :cl)
  (:import-from :orchestrator.asn1
                #:encode-asn1-sequence
                #:encode-asn1-integer
                #:encode-asn1-octet-string
                #:encode-asn1-boolean
                #:encode-asn1-null
                #:encode-asn1-oid)
  (:export
   ;; Core timestamping
   #:request-timestamp
   #:verify-timestamp
   ;; Multi-TSA (100-year proof)
   #:request-timestamps-from-all-tsas
   #:get-available-tsa-count
   ;; TSA configuration
   #:*default-tsa-url*
   #:*tsa-timeout*
   #:*tsa-endpoints*
   ;; Conditions
   #:timestamp-error
   #:tsa-unavailable
   #:invalid-response))

(in-package :orchestrator.timestamp-authority)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defparameter *default-tsa-url* "https://freetsa.org/tsr"
  "Default RFC 3161 TSA endpoint")

(defparameter *tsa-timeout* 30
  "TSA request timeout in seconds")

(defparameter *tsa-endpoints*
  '(("FreeTSA" "https://freetsa.org/tsr")
    ("DigiCert" "https://timestamp.digicert.com")
    ("Sectigo" "https://timestamp.sectigo.com"))
  "List of available TSA endpoints for redundancy - HTTPS required for MITM protection")

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition timestamp-error (error)
  ((message :initarg :message :reader timestamp-error-message))
  (:report (lambda (c s)
             (format s "Timestamp Error: ~A" (timestamp-error-message c)))))

(define-condition tsa-unavailable (timestamp-error) ())
(define-condition invalid-response (timestamp-error) ())

;;; ============================================================================
;;; RFC 3161 TIMESTAMP REQUEST
;;; ============================================================================

(defun request-timestamp (data &key
                                 (tsa-url *default-tsa-url*)
                                 (hash-algorithm :sha256)
                                 (include-cert t)
                                 (nonce t)
                                 output-path)
  "Request RFC 3161 timestamp for data

   AUTHORITY PATTERN:
   - Creates TimeStampReq per RFC 3161
   - Submits via HTTP POST using Drakma
   - Returns TimeStampResp (TSR) bytes

   Args:
     data: Data to timestamp (string or bytes)
     tsa-url: TSA endpoint URL
     hash-algorithm: :sha256 (default), :sha384, :sha512
     include-cert: Request certificate in response
     nonce: Include random nonce (T) or specific value
     output-path: If provided, write TSR to file

   Returns:
     Plist with :tsr-bytes, :tsa-url, :hash, :nonce, :timestamp"

  ;; Compute hash of data
  (let* ((data-bytes (etypecase data
                       (string (babel:string-to-octets data :encoding :utf-8))
                       (vector data)))
         (hash-bytes (ironclad:digest-sequence hash-algorithm data-bytes))
         ;; DARPA-GRADE: Use CSPRNG for nonce to prevent replay attacks
         (nonce-value (cond
                        ((eq nonce t)
                         (let ((nonce-bytes (ironclad:random-data 8)))  ; 64 bits CSPRNG
                           (ironclad:octets-to-integer nonce-bytes)))
                        ((integerp nonce) nonce)
                        (t nil)))

         ;; Create TimeStampReq
         (tsq (encode-timestamp-request hash-bytes
                                        :algorithm hash-algorithm
                                        :nonce nonce-value
                                        :cert-req include-cert))

         ;; Submit to TSA
         (tsr (submit-to-tsa tsq tsa-url)))

    ;; Optionally write to file
    (when output-path
      (ensure-directories-exist output-path)
      (with-open-file (out output-path
                           :direction :output
                           :element-type '(unsigned-byte 8)
                           :if-exists :supersede)
        (write-sequence tsr out)))

    ;; Return result
    (list :tsr-bytes tsr
          :tsa-url tsa-url
          :hash (ironclad:byte-array-to-hex-string hash-bytes)
          :hash-algorithm hash-algorithm
          :nonce nonce-value
          :output-path output-path
          :timestamp (get-universal-time))))

(defun submit-to-tsa (tsq-bytes tsa-url)
  "Submit TimeStampReq to TSA

   Args:
     tsq-bytes: Encoded TimeStampReq
     tsa-url: TSA endpoint

   Returns:
     TimeStampResp bytes"
  (handler-case
      (multiple-value-bind (body status headers uri stream must-close reason)
          (drakma:http-request tsa-url
                               :method :post
                               :content tsq-bytes
                               :content-type "application/timestamp-query"
                               :accept "application/timestamp-reply"
                               :connection-timeout *tsa-timeout*
                               :force-binary t)
        (declare (ignore headers uri stream must-close))

        (unless (= status 200)
          (error 'tsa-unavailable
                 :message (format nil "TSA returned HTTP ~A: ~A" status reason)))

        (unless (and body (> (length body) 0))
          (error 'invalid-response
                 :message "TSA returned empty response"))

        ;; Verify it's a valid TimeStampResp (starts with SEQUENCE tag)
        (unless (= (aref body 0) #x30)
          (error 'invalid-response
                 :message "TSA response is not valid ASN.1 SEQUENCE"))

        body)

    (drakma:drakma-error (e)
      (error 'tsa-unavailable
             :message (format nil "HTTP error: ~A" e)))

    (usocket:socket-error (e)
      (error 'tsa-unavailable
             :message (format nil "Network error: ~A" e)))))

;;; ============================================================================
;;; RFC 3161 TimeStampReq ENCODING
;;; ============================================================================
;;;;
;;;; TimeStampReq ::= SEQUENCE {
;;;;    version        INTEGER { v1(1) },
;;;;    messageImprint MessageImprint,
;;;;    reqPolicy      TSAPolicyId    OPTIONAL,
;;;;    nonce          INTEGER        OPTIONAL,
;;;;    certReq        BOOLEAN        DEFAULT FALSE,
;;;;    extensions     [0] IMPLICIT Extensions OPTIONAL
;;;; }
;;;;
;;;; MessageImprint ::= SEQUENCE {
;;;;    hashAlgorithm  AlgorithmIdentifier,
;;;;    hashedMessage  OCTET STRING
;;;; }

(defun encode-timestamp-request (hash-bytes &key
                                              (algorithm :sha256)
                                              nonce
                                              cert-req)
  "Encode RFC 3161 TimeStampReq

   Args:
     hash-bytes: Hash of data to timestamp
     algorithm: Hash algorithm used
     nonce: Random nonce (optional)
     cert-req: Request certificate in response

   Returns:
     DER-encoded TimeStampReq bytes"

  (let* (;; MessageImprint
         (message-imprint (encode-message-imprint hash-bytes algorithm))
         ;; Build sequence elements
         (elements (list (encode-asn1-integer 1)  ; version = 1
                         message-imprint)))

    ;; Add optional nonce
    (when nonce
      (setf elements (append elements (list (encode-asn1-integer nonce)))))

    ;; Add certReq if true
    (when cert-req
      (setf elements (append elements (list (encode-asn1-boolean t)))))

    ;; Wrap in SEQUENCE
    (encode-asn1-sequence elements)))

(defun encode-message-imprint (hash-bytes algorithm)
  "Encode MessageImprint SEQUENCE"
  (encode-asn1-sequence
   (list (encode-hash-algorithm-identifier algorithm)
         (encode-asn1-octet-string hash-bytes))))

(defun encode-hash-algorithm-identifier (algorithm)
  "Encode AlgorithmIdentifier for hash algorithm"
  (let ((oid (case algorithm
               (:sha256 '(2 16 840 1 101 3 4 2 1))   ; id-sha256
               (:sha384 '(2 16 840 1 101 3 4 2 2))   ; id-sha384
               (:sha512 '(2 16 840 1 101 3 4 2 3))   ; id-sha512
               (:sha1   '(1 3 14 3 2 26))            ; id-sha1 (legacy)
               (t (error 'timestamp-error
                         :message (format nil "Unsupported algorithm: ~A" algorithm))))))
    (encode-asn1-sequence
     (list (encode-asn1-oid oid)
           (encode-asn1-null)))))

;;; (Κωδικοποίηση ASN.1 DER: orchestrator.asn1 — Η έδρα. Εδώ μένει ΜΟΝΟ η
;;; RFC-3161 σημασιολογία: TimeStampReq/MessageImprint/AlgorithmIdentifier.)

;;; ============================================================================
;;; TIMESTAMP VERIFICATION
;;; ============================================================================

(defun verify-timestamp (tsr-bytes original-data &key (hash-algorithm :sha256))
  "Verify TimeStampResp contains correct hash

   Basic verification - checks that response contains our hash.
   Full X.509 chain verification requires more complex implementation.

   Args:
     tsr-bytes: TimeStampResp bytes
     original-data: Original data that was timestamped
     hash-algorithm: Algorithm used

   Returns:
     T if hash matches, signals error otherwise"

  ;; Compute expected hash
  (let* ((data-bytes (etypecase original-data
                       (string (babel:string-to-octets original-data :encoding :utf-8))
                       (vector original-data)))
         (expected-hash (ironclad:digest-sequence hash-algorithm data-bytes))
         (expected-hex (ironclad:byte-array-to-hex-string expected-hash)))

    ;; Parse TSR and extract hash
    (let ((found-hash (extract-hash-from-tsr tsr-bytes)))
      (if (string-equal expected-hex found-hash)
          t
          (error 'invalid-response
                 :message (format nil "Hash mismatch: expected ~A, found ~A"
                                  expected-hex found-hash))))))

(defun extract-hash-from-tsr (tsr-bytes)
  "Extract hashed message from TimeStampResp

   Simplified extraction - looks for hash in MessageImprint.
   TSR structure is complex (SignedData wrapping TSTInfo)."

  ;; Look for typical SHA-256 hash (32 bytes) in OCTET STRING
  ;; This is a simplified approach - full parsing would require
  ;; complete CMS/PKCS#7 implementation
  (let ((hash-len 32)  ; SHA-256
        (octet-string-tag #x04))
    (loop for i from 0 below (- (length tsr-bytes) hash-len 2)
          when (and (= (aref tsr-bytes i) octet-string-tag)
                    (= (aref tsr-bytes (1+ i)) hash-len))
            do (let ((hash-bytes (subseq tsr-bytes (+ i 2) (+ i 2 hash-len))))
                 ;; Verify it looks like a hash (not all zeros/ones)
                 (when (and (not (every #'zerop hash-bytes))
                            (not (every (lambda (b) (= b #xff)) hash-bytes)))
                   (return (ironclad:byte-array-to-hex-string hash-bytes)))))
    ;; Not found
    nil))

;;; ============================================================================
;;; MULTI-TSA REDUNDANCY
;;; ============================================================================

(defun request-timestamp-redundant (data &key
                                          (tsa-list *tsa-endpoints*)
                                          (min-success 1)
                                          output-dir)
  "Request timestamp from multiple TSAs for redundancy

   Args:
     data: Data to timestamp
     tsa-list: List of (name url) pairs
     min-success: Minimum successful responses required
     output-dir: Directory for TSR files

   Returns:
     List of successful timestamp results"

  (let ((results nil)
        (errors nil))

    (dolist (tsa-entry tsa-list)
      (destructuring-bind (name url) tsa-entry
        (handler-case
            (let* ((output-path (when output-dir
                                  (merge-pathnames
                                   (format nil "timestamp-~A.tsr"
                                           (string-downcase
                                            (substitute #\- #\Space name)))
                                   output-dir)))
                   (result (request-timestamp data
                                              :tsa-url url
                                              :output-path output-path)))
              (push (cons name result) results))
          (timestamp-error (e)
            (push (cons name (timestamp-error-message e)) errors)))))

    ;; Check minimum success requirement
    (when (< (length results) min-success)
      (error 'tsa-unavailable
             :message (format nil "Only ~A/~A TSAs responded. Errors: ~{~A~^, ~}"
                              (length results) (length tsa-list)
                              (mapcar #'cdr errors))))

    (nreverse results)))

;;; ============================================================================
;;; CONVENIENCE FUNCTIONS
;;; ============================================================================

(defun timestamp-file (file-path &key
                                   (tsa-url *default-tsa-url*)
                                   output-path)
  "Timestamp a file

   Args:
     file-path: Path to file
     tsa-url: TSA endpoint
     output-path: Where to write TSR (default: file.tsr)

   Returns:
     Timestamp result plist"

  (unless (probe-file file-path)
    (error 'timestamp-error
           :message (format nil "File not found: ~A" file-path)))

  (let* ((data (alexandria:read-file-into-byte-vector file-path))
         (out-path (or output-path
                       (make-pathname :defaults file-path
                                      :type "tsr"))))
    (request-timestamp data
                       :tsa-url tsa-url
                       :output-path out-path)))

(defun timestamp-string (string &key
                                  (tsa-url *default-tsa-url*)
                                  output-path)
  "Timestamp a string (typically a hash)

   Args:
     string: String to timestamp
     tsa-url: TSA endpoint
     output-path: Where to write TSR

   Returns:
     Timestamp result plist"

  (request-timestamp string
                     :tsa-url tsa-url
                     :output-path output-path))

;;; ============================================================================
;;; MULTI-TSA TIMESTAMPING (100-YEAR PROOF)
;;; ============================================================================

(defun request-timestamps-from-all-tsas (data &key output-dir)
  "Request timestamps from ALL configured TSAs for 100-year proof

   DARPA-GRADE: Multiple independent timestamps ensure temporal
   precedence even if individual TSAs cease to exist.

   Args:
     data: Data to timestamp (string or bytes)
     output-dir: Directory for TSR files

   Returns:
     List of successful timestamp results"

  (let ((results nil)
        (successes 0)
        (failures 0))

    (format t "~%═══════════════════════════════════════════════════════════════~%")
    (format t "  100-YEAR TEMPORAL PROOF: Multi-TSA Timestamping~%")
    (format t "═══════════════════════════════════════════════════════════════~%~%")

    (dolist (tsa-entry *tsa-endpoints*)
      (let ((tsa-name (first tsa-entry))
            (tsa-url (second tsa-entry)))
        (format t "[TSA] ~A (~A)...~%" tsa-name tsa-url)
        (handler-case
            (let* ((output-path (when output-dir
                                  (merge-pathnames
                                   (format nil "timestamp-~A.tsr"
                                           (string-downcase (substitute #\- #\Space tsa-name)))
                                   output-dir)))
                   (result (request-timestamp data
                                             :tsa-url tsa-url
                                             :output-path output-path)))
              (format t "      ✓ Success (~A bytes)~%"
                      (length (getf result :tsr-bytes)))
              (push (list :tsa-name tsa-name
                         :tsa-url tsa-url
                         :result result)
                    results)
              (incf successes))
          (error (e)
            (format t "      ✗ Failed: ~A~%" e)
            (incf failures)))))

    (format t "~%Multi-TSA Summary: ~D/~D successful~%"
            successes (+ successes failures))

    (when (zerop successes)
      (error 'tsa-unavailable
             :message "All TSA endpoints failed - no timestamps obtained"))

    (nreverse results)))

(defun get-available-tsa-count ()
  "Return number of configured TSA endpoints"
  (length *tsa-endpoints*))

;;; ============================================================================
;;; END OF TIMESTAMP-AUTHORITY.LISP
;;; ============================================================================
