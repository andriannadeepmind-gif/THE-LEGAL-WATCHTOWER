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
;;; JWS SIGNATURE (Reuses jws-authority - Pure Lisp)
;;; ============================================================================

(defun %public-pem-sibling (private-key-path)
  "Το αδερφό public.pem δίπλα στο private-key-path (private.pem → public.pem)."
  (let* ((name (pathname-name private-key-path)))
    (merge-pathnames (make-pathname :name (if (and name (search "private" name))
                                              (with-output-to-string (o)
                                                (loop with n = (search "private" name)
                                                      for i from 0 below (length name)
                                                      do (if (= i n) (progn (write-string "public" o)
                                                                            (incf i (1- (length "private"))))
                                                             (write-char (char name i) o))))
                                              "public")
                                    :type (pathname-type private-key-path))
                     private-key-path)))

(defun sign-manifest-jws (root-hash-string signature-output-path
                         &key (private-key-path "private.pem")
                              (public-key-jwk-path "verify/public.jwk")
                              (public-key-path nil))
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
  (let* ((private-key (orchestrator.jws-authority:load-rsa-private-key
                       private-key-path))
         (pub-path (or public-key-path (%public-pem-sibling private-key-path)))
         (public-key (orchestrator.jws-authority:load-rsa-public-key pub-path))
         ;; ΤΙΜΙΟ kid (εύρημα κριτή): RFC 7638 JWK thumbprint — παράγεται ΑΠΟ
         ;; το κλειδί που ΠΡΑΓΜΑΤΙ υπογράφει, όχι αυθαίρετο brand string που
         ;; θα έντυνε και dev-genesis κλειδιά. x5u ΜΟΝΟ αν το δηλώσει ο
         ;; χειριστής (env LAWMAX_X5U) — καμία επινοημένη προέλευση.
         (kid (orchestrator.jws-authority:jwk-thumbprint public-key))
         (x5u (let ((v (uiop:getenv "LAWMAX_X5U")))
                (and v (plusp (length v)) v))))

    ;; Create JWS using pure Lisp
    ;; sign-jws signature: (payload private-key &key ...)
    (let* ((result (orchestrator.jws-authority:sign-jws
                    root-hash-string    ; payload (data to sign)
                    private-key         ; private-key (RSA key object)
                    :algorithm :rs256
                    :kid kid
                    :detached t
                    :extra-headers (when x5u (list :|x5u| x5u))))
           (jws (getf result :jws)))

      ;; Write JWS
      (alexandria:write-string-into-file jws
                                         (namestring signature-output-path)
                                         :if-exists :supersede)

      (log:info () "✓ JWS signature: ~A" signature-output-path)

      ;; Export public key as JWK — ΑΠΟ ΤΟ ΔΗΜΟΣΙΟ ΚΛΕΙΔΙ (fail-closed: ποτέ d
      ;; ως e· βλ. jws-authority:export-jwk). kid = RFC 7638 thumbprint (ίδιο
      ;; με το JWS header — ένας επαληθευτής ταιριάζει kid↔κλειδί δομικά).
      (let* ((jwk-json (orchestrator.jws-authority:export-jwk
                        public-key :kid kid)))
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
