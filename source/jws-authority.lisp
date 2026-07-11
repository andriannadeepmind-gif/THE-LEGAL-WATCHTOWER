;;;; source/jws-authority.lisp
;;;; ============================================================================
;;;; JWS AUTHORITY - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; JSON Web Signature (RFC 7515) implementation using Ironclad.
;;;; NO external subprocess calls - pure Lisp cryptography.
;;;;
;;;; AUTHORITY PATTERN:
;;;; - Explicit key loading from PEM files
;;;; - Deterministic signing (same input → same signature with same key)
;;;; - Full audit trail via return values
;;;;
;;;; DARPA-GRADE: Self-contained, no subprocess, auditable.
;;;; ============================================================================

(defpackage :orchestrator.jws-authority
  (:use :cl)
  (:import-from :orchestrator.asn1
                #:pem->der
                #:der->pem
                #:der-sequence-elements
                #:der-integer-value
                #:encode-asn1-sequence
                #:encode-asn1-integer
                #:encode-asn1-bit-string
                #:encode-asn1-oid
                #:encode-asn1-null)
  (:export
   ;; Core signing
   #:sign-jws
   #:verify-jws
   ;; Key management
   #:load-rsa-private-key
   #:load-rsa-public-key
   #:export-jwk
   #:export-jwk-to-file
   #:generate-rsa-keypair
   #:save-rsa-keypair
   ;; JWS utilities
   #:base64url-encode
   #:base64url-decode
   ;; RSASSA-PKCS1-v1_5 / SHA-256 — Η ΜΙΑ έδρα υπογραφής (RFC 8017 §8.2)·
   ;; την καταναλώνει και το x509-authority (αντί για raw-RSA χωρίς padding).
   #:sign-rsa-sha256
   #:verify-rsa-sha256
   ;; Conditions
   #:jws-error
   #:key-not-found
   #:invalid-signature))

(in-package :orchestrator.jws-authority)

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition jws-error (error)
  ((message :initarg :message :reader jws-error-message))
  (:report (lambda (c s)
             (format s "JWS Error: ~A" (jws-error-message c)))))

(define-condition key-not-found (jws-error) ())
(define-condition invalid-signature (jws-error) ())

;;; ============================================================================
;;; BASE64URL ENCODING (RFC 4648 Section 5)
;;; ============================================================================

(defun base64url-encode (data)
  "Encode bytes or string as Base64url (no padding)

   Args:
     data: String or byte vector

   Returns:
     Base64url encoded string (no padding)"
  (let* ((bytes (etypecase data
                  (string (babel:string-to-octets data :encoding :utf-8))
                  (vector data)))
         ;; Use cl-base64 with URI mode (alphabet uses - and _, like base64url)
         (b64 (cl-base64:usb8-array-to-base64-string bytes :uri t)))
    ;; cl-base64's URI mode pads with #\. (NOT #\=); strip both so the result is
    ;; canonical, unpadded base64url. Leaving #\. in place corrupts JWS compact
    ;; serialization, which splits on #\. (header.payload.signature).
    (string-right-trim "=." b64)))

(defun base64url-decode (string)
  "Decode Base64url string to bytes

   Args:
     string: Base64url encoded string

   Returns:
     Byte vector"
  ;; Add padding if needed
  (let* ((len (length string))
         (pad-len (mod (- 4 (mod len 4)) 4))
         (padded (if (zerop pad-len)
                     string
                     (concatenate 'string string (make-string pad-len :initial-element #\=)))))
    ;; Convert from URL-safe to standard base64
    (let ((standard (substitute #\+ #\- (substitute #\/ #\_ padded))))
      (cl-base64:base64-string-to-usb8-array standard))))

;;; ============================================================================
;;; PEM KEY LOADING
;;; ============================================================================

(defun load-rsa-private-key (pem-path)
  "Load RSA private key from PEM file

   Supports:
     - PKCS#1 format (-----BEGIN RSA PRIVATE KEY-----)
     - PKCS#8 format (-----BEGIN PRIVATE KEY-----)

   Args:
     pem-path: Path to PEM file

   Returns:
     Ironclad RSA private key object"
  (unless (probe-file pem-path)
    (error 'key-not-found
           :message (format nil "Private key not found: ~A" pem-path)))

  (let* ((pem-content (alexandria:read-file-into-string pem-path))
         ;; PKCS#1 ή PKCS#8 label — η έδρα PEM (orchestrator.asn1) απαιτεί
         ;; ζεύγος φρουρών με ρητό label, όχι σιωπηλή αφαίρεση γραμμών.
         (der-bytes (pem->der pem-content '("RSA PRIVATE KEY" "PRIVATE KEY"))))
    (parse-rsa-private-key der-bytes)))

(defun load-rsa-public-key (pem-path)
  "Load RSA public key from PEM file

   Args:
     pem-path: Path to PEM file

   Returns:
     Ironclad RSA public key object"
  (unless (probe-file pem-path)
    (error 'key-not-found
           :message (format nil "Public key not found: ~A" pem-path)))

  (let* ((pem-content (alexandria:read-file-into-string pem-path))
         (der-bytes (pem->der pem-content "PUBLIC KEY")))
    (parse-rsa-public-key der-bytes)))

(defun parse-rsa-private-key (der-bytes)
  "Parse DER-encoded RSA private key

   Handles both PKCS#1 and PKCS#8 formats.

   PKCS#1 RSAPrivateKey:
     SEQUENCE {
       version INTEGER,
       modulus INTEGER,
       publicExponent INTEGER,
       privateExponent INTEGER,
       prime1 INTEGER,
       prime2 INTEGER,
       exponent1 INTEGER,
       exponent2 INTEGER,
       coefficient INTEGER
     }

   PKCS#8 PrivateKeyInfo:
     SEQUENCE {
       version INTEGER,
       algorithmIdentifier SEQUENCE { OID, NULL },
       privateKey OCTET STRING (contains PKCS#1)
     }

   Args:
     der-bytes: DER encoded bytes

   Returns:
     Ironclad RSA private key"
  (let* ((parsed (der-sequence-elements der-bytes))
         ;; PKCS#8 detection: has 3 elements, second is a list (nested SEQUENCE = AlgorithmIdentifier)
         ;; PKCS#1 has 9 elements (version + 8 key components), all vectors
         (is-pkcs8 (and (= (length parsed) 3)
                        (listp (second parsed))))  ; AlgorithmIdentifier is parsed as list
         ;; Extract RSA key data
         (key-data (if is-pkcs8
                       ;; PKCS#8: third element is OCTET STRING containing PKCS#1
                       (let ((inner (third parsed)))
                         (der-sequence-elements (if (vectorp inner) inner
                                                    (coerce inner '(vector (unsigned-byte 8))))))
                       ;; PKCS#1: direct
                       parsed)))
    ;; Extract components (skip version at index 0)
    (let ((n (der-integer-value (nth 1 key-data)))       ; modulus
          (e (der-integer-value (nth 2 key-data)))       ; public exponent
          (d (der-integer-value (nth 3 key-data)))       ; private exponent
          (p (der-integer-value (nth 4 key-data)))       ; prime1
          (q (der-integer-value (nth 5 key-data))))      ; prime2
      (ironclad:make-private-key :rsa :n n :e e :d d :p p :q q))))

(defun parse-rsa-public-key (der-bytes)
  "Parse DER-encoded RSA public key

   Args:
     der-bytes: DER encoded bytes

   Returns:
     Ironclad RSA public key"
  (let* ((parsed (der-sequence-elements der-bytes))
         ;; SubjectPublicKeyInfo wraps the key
         (key-bytes (if (= (length parsed) 2)
                        ;; Unwrap BIT STRING
                        (let ((bit-string (second parsed)))
                          (if (and (vectorp bit-string) (> (length bit-string) 1))
                              (subseq bit-string 1)  ; Skip unused bits byte
                              bit-string))
                        der-bytes))
         (key-data (der-sequence-elements key-bytes)))
    (let ((n (der-integer-value (nth 0 key-data)))
          (e (der-integer-value (nth 1 key-data))))
      (ironclad:make-public-key :rsa :n n :e e))))

;;; ============================================================================
;;; JWS SIGNING (RFC 7515)
;;; ============================================================================

(defun sign-jws (payload private-key &key
                                       (algorithm :rs256)
                                       (kid "orchestrator-key")
                                       (detached t)
                                       (extra-headers nil))
  "Create JWS signature

   AUTHORITY PATTERN:
   - Uses Ironclad for all cryptographic operations
   - Returns complete JWS with audit metadata

   Args:
     payload: Data to sign (string or bytes)
     private-key: Ironclad RSA private key or path to PEM file
     algorithm: :rs256 (only RS256 supported currently)
     kid: Key ID for JWS header
     detached: If T, omit payload from JWS (RFC 7797)
     extra-headers: Additional header fields

   Returns:
     Plist with :jws, :header, :payload-hash, :algorithm"
  (unless (eq algorithm :rs256)
    (error 'jws-error :message "Only RS256 algorithm is supported"))

  ;; Load key if path provided
  (let ((key (etypecase private-key
               (pathname (load-rsa-private-key private-key))
               (string (load-rsa-private-key private-key))
               (t private-key))))  ; Already a key object

    ;; Create header
    (let* ((header (append `(:|alg| "RS256"
                             :|typ| "JWS"
                             :|kid| ,kid)
                           extra-headers))
           (header-json (jonathan:to-json header))
           (header-b64 (base64url-encode header-json))

           ;; Encode payload
           (payload-bytes (etypecase payload
                            (string (babel:string-to-octets payload :encoding :utf-8))
                            (vector payload)))
           (payload-b64 (base64url-encode payload-bytes))

           ;; Create signing input: BASE64URL(header).BASE64URL(payload)
           (signing-input (format nil "~A.~A" header-b64 payload-b64))
           (signing-bytes (babel:string-to-octets signing-input :encoding :utf-8))

           ;; Sign with RSA-SHA256
           (signature (sign-rsa-sha256 signing-bytes key))
           (signature-b64 (base64url-encode signature))

           ;; Create JWS
           (jws (if detached
                    ;; Detached: header..signature (empty payload)
                    (format nil "~A..~A" header-b64 signature-b64)
                    ;; Full: header.payload.signature
                    (format nil "~A.~A.~A" header-b64 payload-b64 signature-b64))))

      (list :jws jws
            :header header
            :payload-hash (ironclad:byte-array-to-hex-string
                           (ironclad:digest-sequence :sha256 payload-bytes))
            :algorithm "RS256"
            :detached detached))))

;; SHA-256 DigestInfo DER prefix per RFC 3447 (PKCS#1 v2.1)
;; SEQUENCE { SEQUENCE { OID sha256, NULL }, OCTET STRING (32 bytes) }
(defparameter +sha256-digest-info-prefix+
  #(#x30 #x31                           ; SEQUENCE, 49 bytes
    #x30 #x0d                           ; SEQUENCE, 13 bytes (AlgorithmIdentifier)
    #x06 #x09                           ; OID, 9 bytes
    #x60 #x86 #x48 #x01 #x65 #x03 #x04 #x02 #x01  ; 2.16.840.1.101.3.4.2.1 (SHA-256)
    #x05 #x00                           ; NULL
    #x04 #x20)                          ; OCTET STRING, 32 bytes (digest follows)
  "DER-encoded DigestInfo prefix for SHA-256 (RFC 3447 Section 9.2)")

(defun %rsa-modulus-bytes (key)
  "Byte length k of the RSA modulus — the size of a conforming signature/EM."
  (ceiling (integer-length (ironclad:rsa-key-modulus key)) 8))

(defun %emsa-pkcs1-v15-sha256 (message k)
  "Build the encoded message EM per RFC 8017 §9.2 (EMSA-PKCS1-v1_5):
     EM = 0x00 || 0x01 || PS || 0x00 || T,
   where T = DigestInfo(SHA-256, H(message)) and PS is 0xFF padding (>= 8 bytes)
   filling EM to exactly K bytes. ironclad:sign-message/verify-signature are the
   RAW RSA primitive (no padding), so we MUST construct the full EM ourselves —
   otherwise the output is non-standard and no JOSE library can verify it."
  (let* ((digest (ironclad:digest-sequence :sha256 message))
         (tt (concatenate '(vector (unsigned-byte 8)) +sha256-digest-info-prefix+ digest))
         (ps-len (- k 3 (length tt))))
    (when (< ps-len 8)
      (error 'jws-error :message "RSA modulus too small for RSASSA-PKCS1-v1_5/SHA-256"))
    (concatenate '(vector (unsigned-byte 8))
                 #(#x00 #x01)
                 (make-array ps-len :element-type '(unsigned-byte 8) :initial-element #xFF)
                 #(#x00)
                 tt)))

(defun sign-rsa-sha256 (message private-key)
  "Sign MESSAGE with RSASSA-PKCS1-v1_5 / SHA-256 (RFC 8017 §8.2.1), producing a
   STANDARD signature any JOSE library verifies. Returns signature bytes."
  (let ((em (%emsa-pkcs1-v15-sha256 message (%rsa-modulus-bytes private-key))))
    (ironclad:sign-message private-key em)))

(defun verify-jws (jws payload public-key)
  "Verify JWS signature

   Args:
     jws: JWS string (compact serialization)
     payload: Original payload (for detached JWS)
     public-key: Ironclad RSA public key or path to PEM file

   Returns:
     T if valid, signals INVALID-SIGNATURE if not"
  ;; Load key if path provided
  (let ((key (etypecase public-key
               (pathname (load-rsa-public-key public-key))
               (string (load-rsa-public-key public-key))
               (t public-key))))

    ;; Parse JWS
    (let* ((parts (uiop:split-string jws :separator '(#\.)))
           (header-b64 (first parts))
           ;; Pin the algorithm to RS256: decode the protected header and reject any
           ;; other "alg" (defends against alg-confusion / "alg":"none" if dispatch
           ;; is ever added). The header is also bound into the signing input below.
           (header (handler-case
                       (jonathan:parse
                        (babel:octets-to-string (base64url-decode header-b64) :encoding :utf-8)
                        :as :alist)
                     (error () nil)))
           (alg (and header (cdr (assoc "alg" header :test #'string=))))
           ;; Detached JWS: the payload was base64url(UTF-8 octets) at signing time,
           ;; so re-encode it the SAME way here (encoding a STRING directly would not
           ;; match what SIGN-JWS produced and verification would always fail).
           (payload-b64 (or (and (> (length (second parts)) 0) (second parts))
                            (base64url-encode (if (stringp payload)
                                                  (babel:string-to-octets payload :encoding :utf-8)
                                                  payload))))
           (signature-b64 (third parts))

           ;; Reconstruct signing input
           (signing-input (format nil "~A.~A" header-b64 payload-b64))
           (signing-bytes (babel:string-to-octets signing-input :encoding :utf-8))

           ;; Decode signature
           (signature (base64url-decode signature-b64)))

      ;; Strict: the protected header must parse AND pin alg=RS256. An absent or
      ;; unparseable header, or any other alg, is a hard failure.
      (unless (and header (equal alg "RS256"))
        (error 'invalid-signature
               :message (format nil "JWS header invalid or alg not RS256 (got ~S)" alg)))
      ;; Verify with RSA-SHA256
      (verify-rsa-sha256 signing-bytes signature key))))

(defun verify-rsa-sha256 (message signature public-key)
  "Verify a STANDARD RSASSA-PKCS1-v1_5 / SHA-256 signature (RFC 8017 §8.2.2):
   rebuild the encoded message EM (the SAME full PKCS#1 v1.5 padding used when
   signing) and check it against the raw RSA recovery. Returns T, or signals
   INVALID-SIGNATURE on mismatch / malformed input."
  (let ((em (%emsa-pkcs1-v15-sha256 message (%rsa-modulus-bytes public-key))))
    (handler-case
        ;; ironclad:verify-signature returns NIL for a bad-but-well-formed
        ;; signature (it does NOT signal); only malformed input errors. Honor the
        ;; boolean — returning T unconditionally would accept ANY signature.
        (if (ironclad:verify-signature public-key em signature)
            t
            (error 'invalid-signature
                   :message "Signature verification failed: signature does not match"))
      (invalid-signature (e) (error e))
      (error (e)
        (error 'invalid-signature
               :message (format nil "Signature verification failed: ~A" e))))))

;;; ============================================================================
;;; JWK EXPORT (RFC 7517)
;;; ============================================================================

(defun %rsa-private-key-p (k)
  "T αν το K είναι ironclad RSA ΙΔΙΩΤΙΚΟ κλειδί (έχει πρώτο p). Τα δημόσια
   κλειδιά δεν έχουν — σφάλμα/NIL."
  (and (ignore-errors (ironclad:rsa-key-prime-p k)) t))

(defun export-jwk (key &key (kid "orchestrator-key") (use "sig") public-key)
  "Export RSA ΔΗΜΟΣΙΟ κλειδί ως JWK (RS256).

   ΚΡΙΣΙΜΟ (fail-closed): το «e» ΠΟΤΕ δεν εξάγεται από ΙΔΙΩΤΙΚΟ κλειδί —
   ironclad:rsa-key-exponent σε ιδιωτικό κλειδί επιστρέφει το d (ΙΔΙΩΤΙΚΟ
   εκθέτη), που (α) θα ΔΙΕΡΡΕΕ το ιδιωτικό κλειδί μέσα στο δημόσιο JWK
   (n + d ⇒ ανακατασκευή) και (β) θα έκανε την επαλήθευση αδύνατη. Αν δοθεί
   ιδιωτικό κλειδί, ΑΠΑΙΤΕΙΤΑΙ το αντίστοιχο δημόσιο (:public-key ή public PEM
   path)· αλλιώς ΣΦΑΛΜΑ.

   Args:
     key: Ironclad RSA κλειδί (δημόσιο ή ιδιωτικό) ή PEM path.
     public-key: το ΔΗΜΟΣΙΟ κλειδί/PEM path — υποχρεωτικό όταν KEY είναι ιδιωτικό.
     kid, use: JWK πεδία."
  (flet ((as-key (x public-p)
           (etypecase x
             (pathname (if public-p (load-rsa-public-key x) (load-rsa-private-key x)))
             (string   (if public-p (load-rsa-public-key x) (load-rsa-private-key x)))
             (t x))))
    ;; Η ΠΗΓΗ του δημόσιου εκθέτη: αποκλειστικά δημόσιο κλειδί.
    (let* ((pub (cond
                  (public-key (as-key public-key t))
                  ;; PEM path για το KEY: δοκίμασε δημόσιο πρώτα (σωστό e)· αν
                  ;; είναι ιδιωτικό PEM χωρίς :public-key ⇒ σφάλμα παρακάτω.
                  ((or (pathnamep key) (stringp key))
                   (handler-case (as-key key t)
                     (error () (error 'jws-error
                                      :message "export-jwk: ιδιωτικό PEM απαιτεί :public-key (ΠΟΤΕ d ως e)"))))
                  ((%rsa-private-key-p key)
                   (error 'jws-error
                          :message "export-jwk: ιδιωτικό κλειδί απαιτεί :public-key — ironclad:rsa-key-exponent σε ιδιωτικό επιστρέφει d (διαρροή + άκυρο e)"))
                  (t key)))              ; ήδη δημόσιο κλειδί
           (n (ironclad:rsa-key-modulus pub))
           ;; Ο δημόσιος εκθέτης ΑΠΟ ΤΟ ΔΗΜΟΣΙΟ κλειδί. ΣΗΜ: το ironclad
           ;; generate-key-pair παράγει ΜΕΓΑΛΟ e (όχι 65537), οπότε ΔΕΝ υπάρχει
           ;; φραγή μεγέθους — η προστασία διαρροής είναι ΔΟΜΙΚΗ (ποτέ από
           ;; ιδιωτικό κλειδί, όπου rsa-key-exponent = d).
           (e (ironclad:rsa-key-exponent pub)))
      `(:|kty| "RSA"
        :|use| ,use
        :|kid| ,kid
        :|alg| "RS256"
        :|n| ,(base64url-encode (ironclad:integer-to-octets n))
        :|e| ,(base64url-encode (ironclad:integer-to-octets e))))))

(defun export-jwk-to-file (key output-path &key (kid "orchestrator-key") public-key)
  "Export ΔΗΜΟΣΙΟ key as JWK to file. Αν το KEY είναι ιδιωτικό, δώσε :public-key
   (fail-closed — βλ. export-jwk· ποτέ d ως e)."
  (let ((jwk (export-jwk key :kid kid :public-key public-key)))
    (ensure-directories-exist output-path)
    (alexandria:write-string-into-file
     (jonathan:to-json jwk)
     output-path
     :if-exists :supersede)
    output-path))

;;; ============================================================================
;;; KEY GENERATION
;;; ============================================================================

(defun generate-rsa-keypair (&key (bits 4096))
  "Generate RSA keypair

   Args:
     bits: Key size in bits (default 4096)

   Returns:
     Plist with :private-key, :public-key"
  ;; ironclad:generate-key-pair returns multiple values: private-key, public-key
  (multiple-value-bind (private-key public-key)
      (ironclad:generate-key-pair :rsa :num-bits bits)
    (list :private-key private-key
          :public-key public-key)))

(defun save-rsa-keypair (keypair private-path public-path)
  "Save RSA keypair to PEM files

   Args:
     keypair: Result from generate-rsa-keypair
     private-path: Output path for private key
     public-path: Output path for public key

   Returns:
     Plist with :private-path, :public-path"
  (let ((private-key (getf keypair :private-key))
        (public-key (getf keypair :public-key)))

    ;; Ensure directories exist
    (ensure-directories-exist private-path)
    (ensure-directories-exist public-path)

    ;; Write private key PEM (need public-key to get public exponent for PKCS#1)
    (let ((private-pem (rsa-key-to-pem private-key :private :public-key public-key)))
      (alexandria:write-string-into-file private-pem private-path
                                         :if-exists :supersede))

    ;; Write public key PEM
    (let ((public-pem (rsa-key-to-pem public-key :public)))
      (alexandria:write-string-into-file public-pem public-path
                                         :if-exists :supersede))

    (list :private-path private-path
          :public-path public-path)))

(defun rsa-key-to-pem (key type &key public-key)
  "Convert RSA key to PEM format

   Args:
     key: Ironclad RSA key
     type: :private or :public
     public-key: For private keys, the corresponding public key (to get e)

   Returns:
     PEM string"
  ;; [0057]: ΜΙΑ έδρα PEM-encode — orchestrator.asn1:der->pem (RFC 7468,
  ;; γραμμές 64 χαρ.). Το προηγούμενο χειροποίητο base64+φρουροί ήταν 3ο
  ;; αντίγραφο του der->pem.
  (der->pem (rsa-key-to-der key type :public-key public-key)
            (if (eq type :private) "RSA PRIVATE KEY" "PUBLIC KEY")))

(defun rsa-key-to-der (key type &key public-key)
  "Convert RSA key to DER format

   Args:
     key: Ironclad RSA key
     type: :private or :public
     public-key: For private keys, the corresponding public key (to get e)

   Returns:
     DER bytes"
  (if (eq type :private)
      (encode-rsa-private-key key :public-key public-key)
      (encode-rsa-public-key key)))

(defun encode-rsa-private-key (key &key public-key)
  "Encode RSA private key as PKCS#1 DER

   PKCS#1 RSAPrivateKey structure:
   RSAPrivateKey ::= SEQUENCE {
     version           Version,
     modulus           INTEGER,  -- n
     publicExponent    INTEGER,  -- e
     privateExponent   INTEGER,  -- d
     prime1            INTEGER,  -- p
     prime2            INTEGER,  -- q
     exponent1         INTEGER,  -- d mod (p-1)
     exponent2         INTEGER,  -- d mod (q-1)
     coefficient       INTEGER   -- (inverse of q) mod p
   }

   Args:
     key: Ironclad RSA private key
     public-key: Corresponding RSA public key (required for public exponent)

   Returns:
     DER bytes"
  (unless public-key
    (error 'jws-error
           :message "Public key required for private key encoding (need public exponent)"))
  (let* ((n (ironclad:rsa-key-modulus key))
         (d (ironclad:rsa-key-exponent key))
         (p (ironclad:rsa-key-prime-p key))
         (q (ironclad:rsa-key-prime-q key))
         (e (ironclad:rsa-key-exponent public-key))
         ;; Compute CRT components
         (dp (mod d (1- p)))           ; d mod (p-1)
         (dq (mod d (1- q)))           ; d mod (q-1)
         (qinv (mod-inverse q p)))     ; q^(-1) mod p
    ;; Build RSAPrivateKey SEQUENCE
    (encode-asn1-sequence
     (list (encode-asn1-integer 0)     ; version = 0 (two-prime)
           (encode-asn1-integer n)     ; modulus
           (encode-asn1-integer e)     ; publicExponent
           (encode-asn1-integer d)     ; privateExponent
           (encode-asn1-integer p)     ; prime1
           (encode-asn1-integer q)     ; prime2
           (encode-asn1-integer dp)    ; exponent1
           (encode-asn1-integer dq)    ; exponent2
           (encode-asn1-integer qinv)))))  ; coefficient

(declaim (ftype (function (integer integer) integer) mod-inverse))
(defun mod-inverse (a n)
  "Compute modular multiplicative inverse using extended Euclidean algorithm.
   Returns x such that (a * x) mod n = 1"
  (declare (type integer a n)
           (optimize (speed 3) (safety 1)))
  (multiple-value-bind (gcd x y)
      (extended-gcd a n)
    (declare (type integer gcd x)
             (ignore y))
    (unless (= gcd 1)
      (error 'jws-error :message "Modular inverse does not exist"))
    (the integer (mod x n))))

(declaim (ftype (function (integer integer) (values integer integer integer)) extended-gcd))
(defun extended-gcd (a b)
  "Extended Euclidean algorithm.
   Returns (gcd, x, y) such that a*x + b*y = gcd"
  (declare (type integer a b)
           (optimize (speed 3) (safety 1)))
  (if (zerop b)
      (values a 1 0)
      (multiple-value-bind (g x y)
          (extended-gcd b (mod a b))
        (declare (type integer g x y))
        (values g y (the integer (- x (the integer (* (floor a b) y))))))))

(defun encode-rsa-public-key (key)
  "Encode RSA public key as SubjectPublicKeyInfo DER"
  (let ((n (ironclad:rsa-key-modulus key))
        (e (ironclad:rsa-key-exponent key)))
    ;; RSAPublicKey SEQUENCE
    (let ((rsa-key-seq (encode-asn1-sequence
                        (list (encode-asn1-integer n)
                              (encode-asn1-integer e)))))
      ;; Wrap in SubjectPublicKeyInfo
      (encode-asn1-sequence
       (list ;; AlgorithmIdentifier
             (encode-asn1-sequence
              (list (encode-asn1-oid '(1 2 840 113549 1 1 1))  ; rsaEncryption
                    (encode-asn1-null)))
             ;; BIT STRING containing RSAPublicKey
             (encode-asn1-bit-string rsa-key-seq))))))

;;; ============================================================================
;;; END OF JWS-AUTHORITY.LISP
;;; (Κωδικοποίηση/αποκωδικοποίηση ASN.1 DER: orchestrator.asn1 — Η έδρα.)
;;; ============================================================================
