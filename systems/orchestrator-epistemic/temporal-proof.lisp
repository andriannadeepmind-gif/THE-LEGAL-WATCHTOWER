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
;;; RFC 3161: ΜΙΑ ΕΔΡΑ — orchestrator.timestamp-authority
;;;
;;; Το ASN.1/DER encoding του TimeStampReq, τα *tsa-endpoints* (HTTPS, MITM-
;;; σκληρυμένα) και το multi-TSA μονοπάτι ζουν ΜΟΝΟ στην orchestrator.timestamp-
;;; authority (που με τη σειρά της καταναλώνει την έδρα orchestrator.asn1 για το
;;; raw DER). Εδώ μένει ΜΟΝΟ η επιπλέον σημασιολογία του epistemic release
;;; (αντιγραφή του πρώτου TSR ως timestamp.tsr) + JWS υπογραφή (jws-authority).
;;; [0057]: αφαιρέθηκαν ο 2ος DER encoder, ο 2ος TimeStampReq builder, τα
;;; διπλά *tsa-endpoints* (που είχαν HTTP drift) και το request-rfc3161-timestamp.
;;; ============================================================================

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
            Certificate should be auto-generated in the institution keys dir"))

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
;;; MULTI-TSA TIMESTAMPING (100-YEAR PROOF) — delegates to the ONE seat
;;; ============================================================================

(defun request-multi-tsa-timestamps (root-hash-string output-dir)
  "Request RFC 3161 timestamps from ALL configured TSAs for 100-year proof.

   ΜΙΑ έδρα RFC-3161: καταναλώνει orchestrator.timestamp-authority:request-
   timestamps-from-all-tsas — ίδια *tsa-endpoints* (HTTPS, MITM-σκληρυμένα),
   ίδιος DER encoder μέσω orchestrator.asn1. Εδώ μένει ΜΟΝΟ η σημασιολογία του
   epistemic release: αντιγραφή του πρώτου επιτυχούς TSR ως temporal-proof/
   timestamp.tsr (το αρχείο που απαιτεί το SHACL/attestation gate).

   Args:
     root-hash-string: Merkle root hash to timestamp
     output-dir: Directory for TSR files

   Returns:
     List of successful timestamp results (η έδρα σφάλλει αν καμία TSA δεν απαντά)"
  (ensure-directories-exist output-dir)
  (let ((results (orchestrator.timestamp-authority:request-timestamps-from-all-tsas
                  root-hash-string :output-dir output-dir)))
    ;; Πρώτο επιτυχές TSR ⇒ timestamp.tsr (η έδρα attestation το απαιτεί).
    (when results
      (let ((first-tsr-path (getf (getf (first results) :result) :output-path)))
        (when (and first-tsr-path (probe-file first-tsr-path))
          (uiop:copy-file first-tsr-path
                          (merge-pathnames "timestamp.tsr" output-dir)))))
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
