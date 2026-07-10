;;;; source/x509-authority.lisp
;;;; ============================================================================
;;;; X.509 CERTIFICATE AUTHORITY - Pure Common Lisp Implementation
;;;; ============================================================================
;;;;
;;;; Self-signed X.509 certificate generation using Ironclad.
;;;; NO OpenSSL, NO external subprocess calls - DARPA-GRADE.
;;;;
;;;; Implements:
;;;;   - X.509 v3 certificate structure (RFC 5280)
;;;;   - ASN.1 DER encoding
;;;;   - RSA-SHA256 signing
;;;;   - PEM encoding
;;;;
;;;; Usage:
;;;;   (generate-self-signed-certificate
;;;;     :private-key key
;;;;     :common-name "example.com"
;;;;     :organization "My Org"
;;;;     :days 365)
;;;;
;;;; ============================================================================

(defpackage :orchestrator.x509-authority
  (:use :cl)
  (:import-from :orchestrator.asn1
                #:asn1-error
                #:der-read-tlv
                #:pem->der
                #:der->pem
                #:encode-asn1-length
                #:encode-asn1-sequence
                #:encode-asn1-set
                #:encode-asn1-integer
                #:encode-asn1-bit-string
                #:encode-asn1-octet-string
                #:encode-asn1-null
                #:encode-asn1-oid
                #:encode-asn1-utf8-string
                #:encode-asn1-utc-time
                #:encode-asn1-generalized-time
                #:encode-asn1-boolean
                #:encode-asn1-context-specific)
  (:export
   ;; Certificate generation
   #:generate-self-signed-certificate
   #:save-certificate-pem
   ;; Structural validation (P1.4 [0054]#1: ασπίδα ψευδο-πιστοποιητικού)
   #:valid-x509-certificate-der-p
   #:assert-valid-x509-pem
   ;; Utility
   #:make-distinguished-name
   ;; Conditions
   #:x509-error))

(in-package :orchestrator.x509-authority)

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition x509-error (error)
  ((message :initarg :message :reader x509-error-message))
  (:report (lambda (c s)
             (format s "X.509 Error: ~A" (x509-error-message c)))))

;;; (Κωδικοποίηση/αποκωδικοποίηση ASN.1 DER: orchestrator.asn1 — Η έδρα.
;;; Εδώ μένει ΜΟΝΟ η σημασιολογία X.509: OIDs, DN, TBS, υπογραφή, επικύρωση.)

;;; ============================================================================
;;; X.509 OBJECT IDENTIFIERS
;;; ============================================================================

;; Attribute types (X.500)
(defparameter *oid-common-name* '(2 5 4 3))
(defparameter *oid-country* '(2 5 4 6))
(defparameter *oid-locality* '(2 5 4 7))
(defparameter *oid-state* '(2 5 4 8))
(defparameter *oid-organization* '(2 5 4 10))
(defparameter *oid-organizational-unit* '(2 5 4 11))

;; Signature algorithms
(defparameter *oid-sha256-with-rsa* '(1 2 840 113549 1 1 11))
(defparameter *oid-rsa-encryption* '(1 2 840 113549 1 1 1))

;; Extensions
(defparameter *oid-basic-constraints* '(2 5 29 19))
(defparameter *oid-key-usage* '(2 5 29 15))
(defparameter *oid-subject-key-identifier* '(2 5 29 14))
(defparameter *oid-authority-key-identifier* '(2 5 29 35))

;;; ============================================================================
;;; X.509 STRUCTURE ENCODING
;;; ============================================================================

(defun encode-algorithm-identifier (oid)
  "Encode AlgorithmIdentifier SEQUENCE"
  (encode-asn1-sequence
   (list (encode-asn1-oid oid)
         (encode-asn1-null))))

(defun encode-rdn (oid value)
  "Encode RelativeDistinguishedName as SET OF AttributeTypeAndValue"
  (encode-asn1-set
   (list (encode-asn1-sequence
          (list (encode-asn1-oid oid)
                (encode-asn1-utf8-string value))))))

(defun encode-distinguished-name (components)
  "Encode X.500 Distinguished Name as SEQUENCE of RDNs

   Components is a plist: (:common-name \"...\" :organization \"...\" ...)"
  (let ((rdns '()))
    ;; Build RDNs in order (C, ST, L, O, OU, CN)
    (when (getf components :country)
      (push (encode-rdn *oid-country* (getf components :country)) rdns))
    (when (getf components :state)
      (push (encode-rdn *oid-state* (getf components :state)) rdns))
    (when (getf components :locality)
      (push (encode-rdn *oid-locality* (getf components :locality)) rdns))
    (when (getf components :organization)
      (push (encode-rdn *oid-organization* (getf components :organization)) rdns))
    (when (getf components :organizational-unit)
      (push (encode-rdn *oid-organizational-unit* (getf components :organizational-unit)) rdns))
    (when (getf components :common-name)
      (push (encode-rdn *oid-common-name* (getf components :common-name)) rdns))
    (encode-asn1-sequence (nreverse rdns))))

(defun make-distinguished-name (&key common-name organization organizational-unit
                                     locality state country)
  "Create a distinguished name plist"
  (list :common-name common-name
        :organization organization
        :organizational-unit organizational-unit
        :locality locality
        :state state
        :country country))

(defun encode-time-rfc5280 (universal-time)
  "Encode time per RFC 5280: UTCTime for 1950-2049, GeneralizedTime for 2050+

   RFC 5280 Section 4.1.2.5:
   - UTCTime MUST be used for dates from 1950 through 2049
   - GeneralizedTime MUST be used for dates before 1950 or in 2050 or later

   Signals X509-ERROR for invalid dates."
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal-time 0)
    (declare (ignore sec min hour day month))
    (cond
      ;; RFC 5280: UTCTime is valid only for 1950-2049
      ((< year 1950)
       (error 'x509-error
              :message (format nil "Year ~D is before 1950, not valid for X.509 certificates" year)))
      ((< year 2050)
       ;; UTCTime for 1950-2049
       (encode-asn1-utc-time universal-time))
      (t
       ;; GeneralizedTime for 2050+
       (encode-asn1-generalized-time universal-time)))))

(defun encode-validity (not-before not-after)
  "Encode Validity SEQUENCE with notBefore and notAfter (RFC 5280 compliant)"
  (encode-asn1-sequence
   (list (encode-time-rfc5280 not-before)
         (encode-time-rfc5280 not-after))))

(defun encode-subject-public-key-info (public-key)
  "Encode SubjectPublicKeyInfo for RSA public key"
  (let* ((n (ironclad:rsa-key-modulus public-key))
         (e (ironclad:rsa-key-exponent public-key))
         ;; RSAPublicKey ::= SEQUENCE { modulus INTEGER, publicExponent INTEGER }
         (rsa-public-key (encode-asn1-sequence
                          (list (encode-asn1-integer n)
                                (encode-asn1-integer e)))))
    (encode-asn1-sequence
     (list (encode-algorithm-identifier *oid-rsa-encryption*)
           (encode-asn1-bit-string rsa-public-key)))))

(defun encode-basic-constraints-extension (&key (ca nil) path-length-constraint)
  "Encode Basic Constraints extension"
  (let* ((constraints-content
           (if path-length-constraint
               (encode-asn1-sequence
                (list (encode-asn1-boolean ca)
                      (encode-asn1-integer path-length-constraint)))
               (if ca
                   (encode-asn1-sequence (list (encode-asn1-boolean ca)))
                   (encode-asn1-sequence nil)))))
    (encode-asn1-sequence
     (list (encode-asn1-oid *oid-basic-constraints*)
           (encode-asn1-boolean t)  ; critical
           (encode-asn1-octet-string constraints-content)))))

(defun count-trailing-zero-bits (byte)
  "Count trailing zero bits in a byte (0-8)"
  (if (zerop byte)
      8
      (loop for i from 0 below 8
            while (zerop (logand byte (ash 1 i)))
            count 1)))

(defun encode-key-usage-extension (usages)
  "Encode Key Usage extension per RFC 5280 Section 4.2.1.3

   Usages is a list of keywords:
   :digital-signature :non-repudiation :key-encipherment :data-encipherment
   :key-agreement :key-cert-sign :crl-sign :encipher-only :decipher-only

   Key Usage bits (RFC 5280):
   Bit 0: digitalSignature
   Bit 1: nonRepudiation (contentCommitment)
   Bit 2: keyEncipherment
   Bit 3: dataEncipherment
   Bit 4: keyAgreement
   Bit 5: keyCertSign
   Bit 6: cRLSign
   Bit 7: encipherOnly
   Bit 8: decipherOnly (requires second byte)"
  (let ((byte1 0)
        (byte2 0)
        (need-byte2 nil))
    ;; First byte (bits 0-7)
    (when (member :digital-signature usages) (setf byte1 (logior byte1 #x80)))  ; bit 0
    (when (member :non-repudiation usages) (setf byte1 (logior byte1 #x40)))    ; bit 1
    (when (member :key-encipherment usages) (setf byte1 (logior byte1 #x20)))   ; bit 2
    (when (member :data-encipherment usages) (setf byte1 (logior byte1 #x10)))  ; bit 3
    (when (member :key-agreement usages) (setf byte1 (logior byte1 #x08)))      ; bit 4
    (when (member :key-cert-sign usages) (setf byte1 (logior byte1 #x04)))      ; bit 5
    (when (member :crl-sign usages) (setf byte1 (logior byte1 #x02)))           ; bit 6
    (when (member :encipher-only usages) (setf byte1 (logior byte1 #x01)))      ; bit 7
    ;; Second byte (bit 8)
    (when (member :decipher-only usages)
      (setf byte2 #x80)  ; bit 8 = MSB of second byte
      (setf need-byte2 t))
    ;; Calculate unused bits in last byte
    (let* ((last-byte (if need-byte2 byte2 byte1))
           (unused-bits (count-trailing-zero-bits last-byte))
           ;; Build BIT STRING content
           (bit-string-content (if need-byte2
                                   (vector unused-bits byte1 byte2)
                                   (vector unused-bits byte1)))
           ;; Encode as BIT STRING primitive
           (bit-string (concatenate '(vector (unsigned-byte 8))
                                    (vector #x03)  ; BIT STRING tag
                                    (vector (length bit-string-content))
                                    bit-string-content)))
      (encode-asn1-sequence
       (list (encode-asn1-oid *oid-key-usage*)
             (encode-asn1-boolean t)  ; critical
             (encode-asn1-octet-string bit-string))))))

(defun encode-subject-key-identifier-extension (public-key)
  "Encode Subject Key Identifier extension (SHA-256 hash of public key)

   DARPA-GRADE: SHA-256 replaces deprecated SHA-1.
   RFC 5280 doesn't mandate specific hash algorithm for SKI.
   Using full 32-byte SHA-256 hash for stronger key identification."
  (let* ((spki (encode-subject-public-key-info public-key))
         (hash (ironclad:digest-sequence :sha256 spki))
         (ski (encode-asn1-octet-string hash)))
    (encode-asn1-sequence
     (list (encode-asn1-oid *oid-subject-key-identifier*)
           (encode-asn1-octet-string ski)))))

(defun encode-extensions (extensions)
  "Encode X.509 v3 extensions as context-specific [3]"
  (when extensions
    (encode-asn1-context-specific
     3
     (encode-asn1-sequence extensions)
     :constructed t)))

;;; ============================================================================
;;; TBS CERTIFICATE ENCODING
;;; ============================================================================

(defun generate-serial-number ()
  "Generate random 20-byte serial number (positive, non-zero)

   DARPA-GRADE: Preserves full 159 bits of CSPRNG entropy.
   RFC 5280: Serial number must be positive integer, ≤20 octets.
   CAB Forum: Minimum 64 bits of entropy (we provide 159).

   Instead of modifying bad values (which biases distribution),
   we retry until we get a valid value (virtually always first try)."
  (loop
    (let* ((bytes (ironclad:random-data 20))
           ;; Clear MSB to ensure positive (ASN.1 INTEGER is signed 2's complement)
           ;; This is the only entropy reduction: 160 → 159 bits
           (first-byte (logand (aref bytes 0) #x7f)))
      (setf (aref bytes 0) first-byte)
      ;; Accept if non-zero (retry on all-zeros, probability 1/2^159 ≈ 0)
      (unless (every #'zerop bytes)
        (return (ironclad:octets-to-integer bytes))))))

(defun encode-tbs-certificate (&key serial-number
                                    issuer
                                    subject
                                    not-before
                                    not-after
                                    public-key
                                    extensions)
  "Encode TBSCertificate structure"
  (let ((elements (list
                   ;; version [0] EXPLICIT INTEGER (v3 = 2)
                   (encode-asn1-context-specific
                    0
                    (encode-asn1-integer 2)
                    :constructed t)
                   ;; serialNumber INTEGER
                   (encode-asn1-integer serial-number)
                   ;; signature AlgorithmIdentifier
                   (encode-algorithm-identifier *oid-sha256-with-rsa*)
                   ;; issuer Name
                   (encode-distinguished-name issuer)
                   ;; validity Validity
                   (encode-validity not-before not-after)
                   ;; subject Name
                   (encode-distinguished-name subject)
                   ;; subjectPublicKeyInfo
                   (encode-subject-public-key-info public-key))))
    ;; Add extensions if present
    (when extensions
      (setf elements (append elements (list (encode-extensions extensions)))))
    (encode-asn1-sequence elements)))

;;; ============================================================================
;;; RSA SIGNATURE
;;; ============================================================================

(defun sign-tbs-certificate (tbs-bytes private-key)
  "Sign TBSCertificate with sha256WithRSAEncryption.

   [0057]: ΜΙΑ έδρα υπογραφής — orchestrator.jws-authority:sign-rsa-sha256,
   που χτίζει το ΠΛΗΡΕΣ EMSA-PKCS1-v1_5 encoded message (0x00 0x01 PS 0x00
   DigestInfo) πριν την raw RSA πράξη (RFC 8017 §8.2.1). Η προηγούμενη τοπική
   υλοποίηση περνούσε ΓΥΜΝΟ το DigestInfo στο ironclad:sign-message (raw RSA,
   ΧΩΡΙΣ padding) ⇒ μη-συμμορφείς υπογραφές που κανένα εξωτερικό εργαλείο δεν
   επαλήθευε· ταυτόχρονα διπλασίαζε το DigestInfo/σταθερά SHA-256 του
   jws-authority. Και τα δύο κλείνουν εδώ, στη ΜΙΑ έδρα."
  (orchestrator.jws-authority:sign-rsa-sha256 tbs-bytes private-key))

;;; ============================================================================
;;; CERTIFICATE GENERATION
;;; ============================================================================

(defun generate-self-signed-certificate (&key private-key
                                              public-key
                                              common-name
                                              organization
                                              organizational-unit
                                              locality
                                              state
                                              country
                                              (days 36500)
                                              (ca nil)
                                              (key-usage '(:digital-signature :key-encipherment)))
  "Generate self-signed X.509 v3 certificate

   Args:
     private-key: RSA private key (Ironclad)
     public-key: RSA public key (Ironclad) - REQUIRED for correct e extraction
     common-name: CN (e.g., 'example.com')
     organization: O (e.g., 'My Organization')
     days: Validity period in days (default 3650 = 10 years)
     ca: If true, create CA certificate with key-cert-sign
     key-usage: List of key usage flags

   Returns:
     DER-encoded certificate bytes"
  (unless private-key
    (error 'x509-error :message "Private key required"))
  (unless public-key
    (error 'x509-error :message "Public key required (for correct public exponent e)"))
  (unless common-name
    (error 'x509-error :message "Common name required"))

  ;; Use provided public key to get correct public exponent (e)
  ;; NOTE: ironclad:rsa-key-exponent on private key returns d (private exponent)
  ;;       but on public key it returns e (public exponent) - what we need!
  (let* (;; Build distinguished name
         (dn (list :common-name common-name
                   :organization organization
                   :organizational-unit organizational-unit
                   :locality locality
                   :state state
                   :country country))
         ;; Time values
         (now (get-universal-time))
         (not-before now)
         (not-after (+ now (* days 24 60 60)))
         ;; Serial number
         (serial (generate-serial-number))
         ;; Extensions
         (extensions (list
                      (encode-basic-constraints-extension :ca ca)
                      (encode-key-usage-extension
                       (if ca
                           (append key-usage '(:key-cert-sign :crl-sign))
                           key-usage))
                      (encode-subject-key-identifier-extension public-key)))
         ;; Encode TBSCertificate
         (tbs (encode-tbs-certificate
               :serial-number serial
               :issuer dn
               :subject dn
               :not-before not-before
               :not-after not-after
               :public-key public-key
               :extensions extensions))
         ;; Sign TBSCertificate
         (signature (sign-tbs-certificate tbs private-key)))

    ;; Build final certificate: SEQUENCE { tbsCertificate, signatureAlgorithm, signatureValue }
    (encode-asn1-sequence
     (list tbs
           (encode-algorithm-identifier *oid-sha256-with-rsa*)
           (encode-asn1-bit-string signature)))))

;;; ============================================================================
;;; ASN.1 DER STRUCTURAL VALIDATION (P1.4 [0054]#1)
;;;
;;; Κάνει ΔΟΜΙΚΑ αδύνατο να διανεμηθεί μη-parseable «πιστοποιητικό» ως υλικό
;;; επαλήθευσης σε release. ΔΕΝ επαληθεύει υπογραφή/αλυσίδα (αυτό είναι P4:
;;; πλήρης RFC-3161 CA verification) — επιβεβαιώνει ότι τα bytes είναι ΟΝΤΩΣ
;;; μια καλοσχηματισμένη X.509 δομή, ώστε το verify kit να μη λέει ψέματα για
;;; το τι κρατά. Ο decoder είναι η έδρα orchestrator.asn1 (der-read-tlv) —
;;; εδώ ζει ΜΟΝΟ το X.509 κριτήριο δομής.
;;; ============================================================================

(defun valid-x509-certificate-der-p (der)
  "T αν τα DER bytes είναι καλοσχηματισμένη X.509 Certificate δομή:
   SEQUENCE { tbsCertificate SEQUENCE, signatureAlgorithm SEQUENCE,
   signatureValue BIT STRING }, με το εξωτερικό μήκος να ταιριάζει ΑΚΡΙΒΩΣ με
   το buffer (καμία ουρά). Επιπλέον δομικοί έλεγχοι (ώστε κούφιο shaped ψευδο-
   cert να ΜΗΝ περνά): tbsCertificate μη-κενό με πρώτο στοιχείο version[0]
   (0xA0) ή serialNumber INTEGER (0x02)· signatureAlgorithm ξεκινά με OID
   (0x06)· signatureValue BIT STRING μη-κενό. ΔΕΝ επαληθεύει υπογραφή/αλυσίδα
   εμπιστοσύνης — αυτό είναι δηλωμένη φάση P4. Επιστρέφει (values NIL reason)."
  (handler-case
      (multiple-value-bind (tag cstart clen next) (der-read-tlv der 0)
        (cond
          ((/= tag #x30) (values nil "εξωτερικό tag ≠ SEQUENCE"))
          ((/= next (length der)) (values nil "ουρά bytes μετά το certificate SEQUENCE"))
          (t
           ;; Τρία παιδιά: tbs SEQUENCE, sigAlg SEQUENCE, sig BIT STRING
           (multiple-value-bind (t1 c1 cl1 n1) (der-read-tlv der cstart)
             (multiple-value-bind (t2 c2 cl2 n2) (der-read-tlv der n1)
               (declare (ignore cl2))
               (multiple-value-bind (t3 c3 cl3 n3) (der-read-tlv der n2)
                 (cond
                   ((/= t1 #x30) (values nil "tbsCertificate ≠ SEQUENCE"))
                   ((/= t2 #x30) (values nil "signatureAlgorithm ≠ SEQUENCE"))
                   ((/= t3 #x03) (values nil "signatureValue ≠ BIT STRING"))
                   ((/= n3 (+ cstart clen)) (values nil "τα 3 πεδία δεν γεμίζουν το certificate SEQUENCE"))
                   ((zerop cl1) (values nil "tbsCertificate κενό"))
                   ((zerop cl3) (values nil "signatureValue (BIT STRING) κενό"))
                   (t
                    ;; tbs: πρώτο στοιχείο = version[0] (0xA0) ή serial INTEGER (0x02)
                    (let ((tbs-first (der-read-tlv der c1))
                          ;; sigAlg: πρώτο στοιχείο = OID (0x06)
                          (sigalg-first (der-read-tlv der c2)))
                      (cond
                        ((not (or (= tbs-first #xA0) (= tbs-first #x02)))
                         (values nil "tbsCertificate: πρώτο στοιχείο ≠ version[0]/serial INTEGER"))
                        ((/= sigalg-first #x06)
                         (values nil "signatureAlgorithm: δεν ξεκινά με OID"))
                        (t t)))))))))))
    (asn1-error (e) (values nil (orchestrator.asn1:asn1-error-message e)))
    (error (e) (values nil (format nil "~A" e)))))

(defun assert-valid-x509-pem (pem-string &optional (where "certificate"))
  "Επικυρώνει ότι το PEM-STRING είναι ΑΛΥΣΙΔΑ (≥1) έγκυρων X.509 δομών: ΚΑΘΕ
   CERTIFICATE block περνά το valid-x509-certificate-der-p ΚΑΙ δεν υπάρχουν
   non-whitespace bytes εκτός των blocks. Σφάλμα X509-ERROR αλλιώς (και για
   άκυρο PEM περίβλημα — ενιαίος τύπος συνθήκης της φραγής). Κλείνει την τρύπα
   «μόνο το πρώτο block»: bundle με καλή κεφαλή αλλά σκουπίδι ουρά ΑΠΟΡΡΙΠΤΕΤΑΙ."
  (let ((blocks (handler-case (orchestrator.asn1:pem->der-all-blocks pem-string "CERTIFICATE")
                  (asn1-error (e)
                    (error 'x509-error
                           :message (format nil "~A: ~A" where
                                            (orchestrator.asn1:asn1-error-message e)))))))
    (loop for der in blocks
          for i from 1
          do (multiple-value-bind (ok reason) (valid-x509-certificate-der-p der)
               (unless ok
                 (error 'x509-error
                        :message (format nil "~A: block #~D ΔΕΝ είναι έγκυρο X.509 πιστοποιητικό (~A) — άρνηση διανομής ψευδο-υλικού επαλήθευσης"
                                         where i reason)))))
    t))

(defun save-certificate-pem (certificate-der output-path)
  "Save DER certificate as PEM file"
  (let ((pem (der->pem certificate-der "CERTIFICATE")))
    (with-open-file (stream output-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-string pem stream))
    output-path))

;;; ============================================================================
;;; HIGH-LEVEL API
;;; ============================================================================

(defun generate-and-save-certificate (&key private-key-path
                                           public-key-path
                                           output-path
                                           common-name
                                           organization
                                           (days 3650))
  "Generate self-signed certificate and save to file

   Convenience function that loads keypair and saves certificate."
  (let* ((private-key (orchestrator.jws-authority:load-rsa-private-key private-key-path))
         (public-key (orchestrator.jws-authority:load-rsa-public-key public-key-path))
         (cert-der (generate-self-signed-certificate
                    :private-key private-key
                    :public-key public-key
                    :common-name common-name
                    :organization organization
                    :days days)))
    (save-certificate-pem cert-der output-path)
    (format t "✓ Certificate generated: ~A~%" output-path)
    output-path))

