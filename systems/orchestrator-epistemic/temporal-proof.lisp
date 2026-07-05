;;;; systems/orchestrator-epistemic/temporal-proof.lisp
;;;; ============================================================================
;;;; TEMPORAL PROOF SYSTEM - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; RFC 3161 Timestamps + Certificate Transparency + JWS Signatures
;;;;
;;;; DARPA-GRADE: Zero subprocess calls. Pure Lisp cryptography.
;;;;   - ASN.1/DER encoding for RFC 3161 TimeStampReq
;;;;   - Drakma HTTP client for TSA/CT submissions
;;;;   - Ironclad for cryptographic operations
;;;;   - Reuses jws-authority for JWS signing
;;;;
;;;; NO: curl, openssl, external binaries
;;;; YES: Pure functional, auditable, deterministic
;;;; ============================================================================

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; ASN.1/DER ENCODING FOR RFC 3161
;;; ============================================================================

(defun encode-der-sequence (elements)
  "Encode list of DER elements as SEQUENCE (tag 0x30)"
  (let ((content (apply #'concatenate '(vector (unsigned-byte 8))
                        (remove nil elements))))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x30)
                 (encode-der-length (length content))
                 content)))

(defun encode-der-integer (value)
  "Encode integer as DER INTEGER (tag 0x02)"
  (let* ((bytes (if (zerop value)
                    (vector 0)
                    (integer-to-octets-be value)))
         (padded (if (and (> (length bytes) 0)
                          (>= (aref bytes 0) 128))
                     (concatenate '(vector (unsigned-byte 8)) (vector 0) bytes)
                     bytes)))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x02)
                 (encode-der-length (length padded))
                 padded)))

(defun encode-der-octet-string (bytes)
  "Encode bytes as DER OCTET STRING (tag 0x04)"
  (concatenate '(vector (unsigned-byte 8))
               (vector #x04)
               (encode-der-length (length bytes))
               bytes))

(defun encode-der-boolean (value)
  "Encode boolean as DER BOOLEAN (tag 0x01)"
  (vector #x01 #x01 (if value #xff #x00)))

(defun encode-der-oid (components)
  "Encode OID as DER OBJECT IDENTIFIER (tag 0x06)"
  (let ((encoded (make-array 0 :element-type '(unsigned-byte 8)
                             :adjustable t :fill-pointer 0)))
    ;; First two components combined
    (vector-push-extend (+ (* 40 (first components)) (second components)) encoded)
    ;; Remaining components in base-128
    (dolist (c (cddr components))
      (let ((bytes nil))
        (if (zerop c)
            (push 0 bytes)
            (loop while (plusp c)
                  do (push (logand c #x7f) bytes)
                     (setf c (ash c -7))))
        ;; Set high bit on all but last byte
        (loop for tail on bytes
              while (cdr tail)
              do (setf (car tail) (logior (car tail) #x80)))
        (dolist (b bytes)
          (vector-push-extend b encoded))))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x06)
                 (encode-der-length (length encoded))
                 encoded)))

(defun encode-der-length (length)
  "Encode ASN.1 length field"
  (cond
    ((< length 128)
     (vector length))
    ((< length 256)
     (vector #x81 length))
    ((< length 65536)
     (vector #x82 (ash length -8) (logand length #xff)))
    (t
     (let ((bytes (integer-to-octets-be length)))
       (concatenate '(vector (unsigned-byte 8))
                    (vector (logior #x80 (length bytes)))
                    bytes)))))

(defun integer-to-octets-be (n)
  "Convert integer to big-endian octet vector"
  (if (zerop n)
      (vector 0)
      (let ((bytes nil))
        (loop while (plusp n)
              do (push (logand n #xff) bytes)
                 (setf n (ash n -8)))
        (coerce bytes '(vector (unsigned-byte 8))))))

;;; OID constants for RFC 3161
(defparameter *oid-sha256* '(2 16 840 1 101 3 4 2 1)
  "OID for SHA-256: 2.16.840.1.101.3.4.2.1")

(defparameter *oid-tsa-policy* '(1 3 6 1 4 1 13762 3)
  "Default TSA policy OID (optional)")

;;; ============================================================================
;;; RFC 3161 TIMESTAMP REQUEST CREATION (Pure Lisp)
;;; ============================================================================

(defun create-timestamp-request (hash-bytes &key (cert-req t) nonce)
  "Create RFC 3161 TimeStampReq as DER-encoded bytes

   TimeStampReq ::= SEQUENCE {
     version        INTEGER { v1(1) },
     messageImprint MessageImprint,
     reqPolicy      TSAPolicyId OPTIONAL,
     nonce          INTEGER OPTIONAL,
     certReq        BOOLEAN DEFAULT FALSE,
     extensions     [0] IMPLICIT Extensions OPTIONAL
   }

   MessageImprint ::= SEQUENCE {
     hashAlgorithm  AlgorithmIdentifier,
     hashedMessage  OCTET STRING
   }

   Args:
     hash-bytes: SHA-256 hash as octet vector (32 bytes)
     cert-req: Request certificate in response (default T)
     nonce: Optional nonce for replay protection

   Returns:
     DER-encoded TimeStampReq as octet vector"
  (declare (type (vector (unsigned-byte 8)) hash-bytes))

  ;; AlgorithmIdentifier for SHA-256
  (let ((algorithm-id (encode-der-sequence
                       (list (encode-der-oid *oid-sha256*)
                             (vector #x05 #x00)))))  ; NULL parameters

    ;; MessageImprint
    (let ((message-imprint (encode-der-sequence
                            (list algorithm-id
                                  (encode-der-octet-string hash-bytes)))))

      ;; TimeStampReq
      (encode-der-sequence
       (list (encode-der-integer 1)          ; version = 1
             message-imprint                  ; messageImprint
             nil                              ; reqPolicy (omitted)
             (when nonce                      ; nonce (optional)
               (encode-der-integer nonce))
             (when cert-req                   ; certReq
               (encode-der-boolean t)))))))

;;; ============================================================================
;;; HTTP CLIENT (Drakma - Pure Lisp)
;;; ============================================================================

(defun http-post-binary (url content-type body)
  "POST binary data using Drakma (pure Lisp HTTP client)

   Args:
     url: Target URL
     content-type: MIME type
     body: Octet vector to POST

   Returns:
     (values response-body status-code headers)"
  (multiple-value-bind (body status headers uri stream must-close reason)
      (drakma:http-request url
                           :method :post
                           :content-type content-type
                           :content body
                           :force-binary t
                           :connection-timeout 30)
    ;; NOTE: :read-timeout removed - not supported by usocket SBCL backend
    ;; Connection timeout (30s) provides sufficient protection
    (declare (ignore uri stream must-close reason))
    (values body status headers)))

;;; ============================================================================
;;; RFC 3161 TIMESTAMP AUTHORITY (Pure Lisp)
;;; ============================================================================

(defun request-rfc3161-timestamp (root-hash-string output-path
                                  &key (tsa-url "https://freetsa.org/tsr"))
  "Request RFC 3161 timestamp using pure Lisp

   DARPA-GRADE: No subprocess calls. Pure Lisp implementation:
     1. Hash the root-hash-string with SHA-256
     2. Create TimeStampReq using ASN.1/DER encoding
     3. Submit via Drakma HTTP POST
     4. Save TimeStampResp to file

   Args:
     root-hash-string: Merkle root hash (e.g., \"sha256:4b83456...\")
     output-path: Where to write timestamp.tsr
     tsa-url: RFC 3161 TSA endpoint

   Returns:
     Plist with :receipt-path, :tsa-authority, :root-hash"

  (ensure-directories-exist
   (make-pathname :directory (pathname-directory output-path)
                  :name nil :type nil))

  (log:info () "Creating RFC 3161 timestamp request (pure Lisp)...")

  ;; Step 1: Hash the root-hash-string
  (let* ((hash-input (babel:string-to-octets root-hash-string :encoding :utf-8))
         (hash-bytes (ironclad:digest-sequence :sha256 hash-input))
         ;; Use cryptographically secure random nonce (Ironclad CSPRNG)
         (nonce-bytes (ironclad:random-data 8))  ; 64 bits
         (nonce (ironclad:octets-to-integer nonce-bytes)))

    ;; Step 2: Create TimeStampReq
    (let ((tsq-bytes (create-timestamp-request hash-bytes
                                                :cert-req t
                                                :nonce nonce)))

      (log:info () "✓ TimeStampReq created (~A bytes, nonce: ~A)"
                (length tsq-bytes) nonce)

      ;; Step 3: Submit to TSA via Drakma
      (log:info () "Submitting to TSA: ~A" tsa-url)

      (handler-case
          (multiple-value-bind (response-body status headers)
              (http-post-binary tsa-url
                               "application/timestamp-query"
                               tsq-bytes)

            (unless (= status 200)
              (error "TSA returned HTTP ~A" status))

            ;; Verify response content-type
            (let ((ct (cdr (assoc :content-type headers))))
              (unless (and ct (search "timestamp-reply" ct))
                (log:warn () "Unexpected content-type: ~A" ct)))

            ;; Step 4: Save response
            (with-open-file (out output-path
                                 :direction :output
                                 :element-type '(unsigned-byte 8)
                                 :if-exists :supersede)
              (write-sequence response-body out))

            (log:info () "✓ RFC 3161 timestamp received (~A bytes)"
                      (length response-body))

            ;; Return metadata
            (list :receipt-path output-path
                  :tsa-authority tsa-url
                  :root-hash root-hash-string
                  :nonce nonce))

        (error (e)
          (error "TSA request failed: ~A" e))))))

;;; ============================================================================
;;; CERTIFICATE TRANSPARENCY (Pure Lisp)
;;; ============================================================================

(defun submit-to-ct-log (root-hash-string output-path
                         &key (ct-log-url "https://ct.googleapis.com/logs/argon2023/ct/v1/add-chain")
                              (certificate-path nil))
  "Submit to Certificate Transparency log using pure Lisp

   DARPA-GRADE: Uses Drakma HTTP client, no curl subprocess.

   Args:
     root-hash-string: Merkle root hash (for reference)
     output-path: Where to write ct-proof.json
     ct-log-url: CT log endpoint
     certificate-path: Path to X.509 certificate (PEM format)

   Returns:
     Plist with :sct, :proof-path, :log-url, :root-hash"

  ;; Certificate is required for CT logs (auto-generated on first run)
  (unless certificate-path
    (error "CT log submission requires X.509 certificate.~%~
            Certificate should be auto-generated at /app/keys/certificate.pem"))

  (unless (probe-file certificate-path)
    (error "Certificate not found: ~A" certificate-path))

  (ensure-directories-exist
   (make-pathname :directory (pathname-directory output-path)
                  :name nil :type nil))

  (log:info () "Submitting to CT log (pure Lisp): ~A" ct-log-url)

  ;; Read and prepare certificate
  (let* ((cert-pem (alexandria:read-file-into-string certificate-path))
         (cert-lines (remove-if (lambda (line)
                                  (or (search "-----BEGIN" line)
                                      (search "-----END" line)
                                      (string= line "")))
                                (uiop:split-string cert-pem :separator '(#\Newline))))
         (cert-b64 (apply #'concatenate 'string cert-lines))
         (payload (jonathan:to-json `(:|chain| (,cert-b64)))))

    ;; Submit via Drakma
    (handler-case
        (multiple-value-bind (response-body status headers)
            (drakma:http-request ct-log-url
                                 :method :post
                                 :content-type "application/json"
                                 :content payload
                                 :force-binary nil
                                 :connection-timeout 30)
          (declare (ignore headers))

          (unless (= status 200)
            (error "CT log returned HTTP ~A: ~A" status response-body))

          ;; Save response
          (let ((response-str (if (stringp response-body)
                                  response-body
                                  (babel:octets-to-string response-body))))
            (alexandria:write-string-into-file response-str
                                               (namestring output-path)
                                               :if-exists :supersede)

            (log:info () "✓ SCT received: ~A" output-path)

            (list :sct (jonathan:parse response-str :as :alist)
                  :proof-path output-path
                  :log-url ct-log-url
                  :root-hash root-hash-string)))

      (error (e)
        (error "CT log submission failed: ~A" e)))))

;;; ============================================================================
;;; JWS SIGNATURE (Reuses jws-authority - Pure Lisp)
;;; ============================================================================

(defun sign-manifest-jws (root-hash-string signature-output-path
                         &key (private-key-path "private.pem")
                              (public-key-jwk-path "verify/public.jwk"))
  "Sign manifest using pure Lisp JWS (reuses jws-authority module)

   DARPA-GRADE: Uses Ironclad for RSA signing, no OpenSSL subprocess.

   Args:
     root-hash-string: Merkle root hash to sign
     signature-output-path: Where to write signature.jws
     private-key-path: Path to RSA private key (PEM)
     public-key-jwk-path: Where to write public.jwk

   Returns:
     Plist with :signature-path, :public-key-jwk-path, :root-hash"

  (unless (probe-file private-key-path)
    (error "Private key not found: ~A" private-key-path))

  ;; Ensure directories exist
  (ensure-directories-exist
   (make-pathname :directory (pathname-directory signature-output-path)
                  :name nil :type nil))
  (ensure-directories-exist
   (make-pathname :directory (pathname-directory public-key-jwk-path)
                  :name nil :type nil))

  (log:info () "Creating JWS signature (pure Lisp)...")

  ;; Load private key using our pure Lisp loader
  (let ((private-key (orchestrator.jws-authority:load-rsa-private-key
                      private-key-path)))

    ;; Create JWS using pure Lisp
    ;; sign-jws signature: (payload private-key &key ...)
    (let* ((result (orchestrator.jws-authority:sign-jws
                    root-hash-string    ; payload (data to sign)
                    private-key         ; private-key (RSA key object)
                    :algorithm :rs256
                    :kid "stavropouloslaw-2025"
                    :detached t
                    :extra-headers '(:|x5u| "https://stavropouloslaw.com/keys/2025.pem")))
           (jws (getf result :jws)))

      ;; Write JWS
      (alexandria:write-string-into-file jws
                                         (namestring signature-output-path)
                                         :if-exists :supersede)

      (log:info () "✓ JWS signature: ~A" signature-output-path)

      ;; Export public key as JWK
      (let ((jwk-json (orchestrator.jws-authority:export-jwk
                       private-key
                       :kid "stavropouloslaw-2025")))
        (alexandria:write-string-into-file
         (jonathan:to-json jwk-json)
         (namestring public-key-jwk-path)
         :if-exists :supersede)

        (log:info () "✓ Public JWK: ~A" public-key-jwk-path))

      ;; Return metadata
      (list :signature-path signature-output-path
            :public-key-jwk-path public-key-jwk-path
            :root-hash root-hash-string))))

;;; ============================================================================
;;; MULTI-TSA TIMESTAMPING (100-YEAR PROOF)
;;; ============================================================================

(defparameter *tsa-endpoints*
  '(("FreeTSA" "https://freetsa.org/tsr")
    ("DigiCert" "http://timestamp.digicert.com")
    ("Sectigo" "http://timestamp.sectigo.com"))
  "Multiple TSA endpoints for 100-year temporal proof redundancy")

(defun request-multi-tsa-timestamps (root-hash-string output-dir)
  "Request RFC 3161 timestamps from multiple TSAs for 100-year proof

   DARPA-GRADE: Multiple independent timestamps ensure temporal
   precedence even if individual TSAs cease to exist.

   Args:
     root-hash-string: Merkle root hash to timestamp
     output-dir: Directory for TSR files

   Returns:
     List of successful timestamp results"

  (format t "~%═══════════════════════════════════════════════════════════════~%")
  (format t "  100-YEAR TEMPORAL PROOF: Multi-TSA Timestamping~%")
  (format t "═══════════════════════════════════════════════════════════════~%~%")

  (ensure-directories-exist output-dir)

  (let ((results nil)
        (successes 0)
        (failures 0))

    (dolist (tsa-entry *tsa-endpoints*)
      (let ((tsa-name (first tsa-entry))
            (tsa-url (second tsa-entry)))
        (format t "[TSA] ~A (~A)...~%" tsa-name tsa-url)
        (let ((output-path (merge-pathnames
                           (format nil "timestamp-~A.tsr"
                                  (string-downcase
                                   (cl-ppcre:regex-replace-all " " tsa-name "-")))
                           output-dir)))
          (handler-case
              (let ((result (request-rfc3161-timestamp root-hash-string output-path
                                                       :tsa-url tsa-url)))
                (format t "      ✓ Success~%")
                (push (list :tsa-name tsa-name
                           :tsa-url tsa-url
                           :output-path output-path
                           :result result)
                      results)
                (incf successes))
            (error (e)
              (format t "      ✗ Failed: ~A~%" e)
              (incf failures))))))

    (format t "~%Multi-TSA Summary: ~D/~D successful~%~%" successes (+ successes failures))

    (when (zerop successes)
      (error "All TSA endpoints failed - no timestamps obtained"))

    ;; Reverse results to chronological order
    (setf results (nreverse results))

    ;; Also write the first successful timestamp as timestamp.tsr for SHACL validation
    (when results
      (let ((first-result (first results)))
        (when first-result
          (let ((first-tsr-path (getf first-result :output-path)))
            (when (and first-tsr-path (probe-file first-tsr-path))
              (let ((primary-tsr-path (merge-pathnames "timestamp.tsr" output-dir)))
                (uiop:copy-file first-tsr-path primary-tsr-path)))))))

    results))

;;; ============================================================================
;;; END OF TEMPORAL-PROOF.LISP - Pure Lisp Implementation
;;; ============================================================================
;;;
;;; NOTE: CT Log submission removed (2026-01-07)
;;; Public CT logs (Google, Cloudflare) require CA-issued certificates.
;;; Self-signed certificates are rejected by all public CT logs.
;;; DARPA-GRADE: No external WebPKI dependencies.
;;; Temporal proof: Multi-TSA RFC 3161 + JWS + Merkle trees.
;;; ============================================================================
