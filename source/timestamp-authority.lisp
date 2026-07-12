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
                #:encode-asn1-oid
                #:der-read-tlv
                #:der-sequence-elements
                #:der-integer-value
                #:pem->der-all-blocks
                #:asn1-error)
  (:export
   ;; Core timestamping
   #:request-timestamp
   ;; P4: ΠΛΗΡΗΣ κρυπτογραφική επαλήθευση TSR (CMS SignedData + TSA υπογραφή)
   ;; — Η ΜΙΑ έδρα επαλήθευσης TSR (η παλιά verify-timestamp/byte-scan πέθανε)
   #:verify-tsr-cryptographically
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

;;; Η παλιά verify-timestamp/extract-hash-from-tsr (byte-scan «containment»,
;;; μόνο SHA-256, ΚΑΜΙΑ υπογραφή) ΠΕΘΑΝΕ — δεύτερη, ασθενέστερη έδρα για την
;;; ίδια έννοια δίπλα στην πλήρη verify-tsr-cryptographically (εύρημα κριτή F1).

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

;;; ============================================================================
;;; P4: ΠΛΗΡΗΣ ΚΡΥΠΤΟΓΡΑΦΙΚΗ ΕΠΑΛΗΘΕΥΣΗ TSR (RFC 3161 / CMS RFC 5652)
;;; ============================================================================
;;;
;;; Μέχρι το P4, το σύστημα έλεγχε ΥΠΑΡΞΗ + imprint-containment του receipt —
;;; δηλωμένο τίμια ως υπόλοιπο. Εδώ κλείνει: πλήρες parse του TimeStampResp
;;; πάνω στην ΑΥΣΤΗΡΗ έδρα DER (orchestrator.asn1) + επαλήθευση:
;;;   [1] PKIStatus = granted/grantedWithMods
;;;   [2] TSTInfo.messageImprint ≡ sha256(message) — ΘΕΣΙΑΚΑ, όχι containment
;;;   [3] signedAttrs: messageDigest ≡ sha256(eContent) + contentType ≡ TSTInfo
;;;   [4] Υπογραφή SignerInfo πάνω στο DER(signedAttrs ως SET) — μέσω της ΜΙΑΣ
;;;       έδρας verify-rsa-pkcs1 (sha256/384/512)
;;;   [5] Ο signer επιλέγεται ΑΠΟ ΤΗΝ ΥΠΟΓΡΑΦΗ (ποιο embedded cert επαληθεύει)
;;;   [6] ΑΓΚΥΡΑ: αν δοθεί pinned CA (tsa-ca.pem), το signer cert πρέπει να
;;;       είναι υπογεγραμμένο από την CA (ή να ΕΙΝΑΙ η pinned) ⇒ :pinned.
;;;       Χωρίς CA ⇒ :unpinned (η υπογραφή ισχύει, η αλυσίδα ΔΕΝ αγκυρώνεται —
;;;       ΤΙΜΙΑ διαβάθμιση, ποτέ σιωπηλό πράσινο επιπέδου που δεν κρατά).
;;; ============================================================================

(defparameter +oid-signed-data+   #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x07 #x02))
(defparameter +oid-tst-info+      #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x09 #x10 #x01 #x04))
(defparameter +oid-message-digest+ #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x09 #x04))
(defparameter +oid-content-type+  #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x09 #x03))
(defparameter +oid-sha256+        #(#x60 #x86 #x48 #x01 #x65 #x03 #x04 #x02 #x01))
(defparameter +oid-sha384+        #(#x60 #x86 #x48 #x01 #x65 #x03 #x04 #x02 #x02))
(defparameter +oid-sha512+        #(#x60 #x86 #x48 #x01 #x65 #x03 #x04 #x02 #x03))

(defun %tlv-children (bytes start end)
  "Λίστα (tag content-start content-len next) των ΑΜΕΣΩΝ παιδιών του [START,END)."
  (let ((out '()) (pos start))
    (loop while (< pos end)
          do (multiple-value-bind (tag cstart clen next) (der-read-tlv bytes pos)
               (when (> next end)
                 (error 'invalid-response :message "TSR: στοιχείο υπερβαίνει το γονικό όριο"))
               (push (list tag cstart clen next pos) out)
               (setf pos next)))
    (nreverse out)))

(defun %constructed-children (bytes offset expect-tag what)
  "Παιδιά ενός constructed TLV στο OFFSET· απαιτεί tag = EXPECT-TAG."
  (multiple-value-bind (tag cstart clen) (der-read-tlv bytes offset)
    (unless (= tag expect-tag)
      (error 'invalid-response
             :message (format nil "TSR: ~A — αναμενόταν tag 0x~2,'0X, βρέθηκε 0x~2,'0X"
                              what expect-tag tag)))
    (values (%tlv-children bytes cstart (+ cstart clen)) cstart clen)))

(defun %digest-alg-from-oid (oid-bytes what)
  (cond ((equalp oid-bytes +oid-sha256+) :sha256)
        ((equalp oid-bytes +oid-sha384+) :sha384)
        ((equalp oid-bytes +oid-sha512+) :sha512)
        (t (error 'invalid-response
                  :message (format nil "TSR: μη υποστηριζόμενος digest στο ~A" what)))))

(defun %content-bytes (bytes child)
  (destructuring-bind (tag cstart clen next pos) child
    (declare (ignore tag next pos))
    (subseq bytes cstart (+ cstart clen))))

(defparameter +oid-ec-public-key+ #(#x2a #x86 #x48 #xce #x3d #x02 #x01))
(defparameter +oid-secp256r1+   #(#x2a #x86 #x48 #xce #x3d #x03 #x01 #x07))
(defparameter +oid-secp384r1+   #(#x2b #x81 #x04 #x00 #x22))
(defparameter +oid-secp521r1+   #(#x2b #x81 #x04 #x00 #x23))
;; X.509 extensions + ESS (κλείσιμο ευρημάτων C2/C3 αντιπαλικού κριτή)
(defparameter +oid-ext-eku+               #(#x55 #x1d #x25))              ; 2.5.29.37
(defparameter +oid-ext-basic-constraints+ #(#x55 #x1d #x13))              ; 2.5.29.19
(defparameter +oid-kp-timestamping+ #(#x2b #x06 #x01 #x05 #x05 #x07 #x03 #x08)) ; 1.3.6.1.5.5.7.3.8
(defparameter +oid-signing-certificate+    ; RFC 2634 (certHash = SHA-1)
  #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x09 #x10 #x02 #x0c))
(defparameter +oid-signing-certificate-v2+ ; RFC 5035 (default SHA-256)
  #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x09 #x10 #x02 #x2f))
(defparameter +oid-sha1+ #(#x2b #x0e #x03 #x02 #x1a)) ; ΜΟΝΟ για ESS certHash (v1)

(defun %cert-tbs-fields (cert-bytes cert-start)
  "Πεδία του TBSCertificate ΜΕΤΑ το προαιρετικό [0] version — μία έδρα για τη
   δομική αποσύνθεση TBS (SPKI/Validity/Extensions τη καταναλώνουν)."
  (multiple-value-bind (kids) (%constructed-children cert-bytes cert-start #x30 "certificate")
    (destructuring-bind (tbs &rest rest) kids
      (declare (ignore rest))
      (destructuring-bind (tbs-tag tbs-start tbs-len tbs-next tbs-pos) tbs
        (declare (ignore tbs-tag tbs-next tbs-pos))
        (let ((fields (%tlv-children cert-bytes tbs-start (+ tbs-start tbs-len))))
          (if (= (first (first fields)) #xa0) (rest fields) fields))))))

(defun %x509-time->generalized (bytes child)
  "UTCTime (0x17) ή GeneralizedTime (0x18) → κανονικοποιημένο GeneralizedTime
   string (RFC 5280: UTCTime YY≥50 ⇒ 19YY, αλλιώς 20YY)."
  (destructuring-bind (tag cs cl next pos) child
    (declare (ignore next pos))
    (let ((s (babel:octets-to-string (subseq bytes cs (+ cs cl)) :encoding :ascii)))
      (ecase tag
        (#x18 s)
        (#x17 (concatenate 'string
                           (if (>= (parse-integer s :end 2) 50) "19" "20") s))))))

(defun %cert-validity (cert-bytes cert-start)
  "(values notBefore notAfter) του cert ως GeneralizedTime strings."
  (let ((validity (nth 3 (%cert-tbs-fields cert-bytes cert-start))))
    (unless (and validity (= (first validity) #x30))
      (error 'invalid-response :message "TSR: cert χωρίς Validity"))
    (let ((vk (%tlv-children cert-bytes (second validity)
                             (+ (second validity) (third validity)))))
      (values (%x509-time->generalized cert-bytes (first vk))
              (%x509-time->generalized cert-bytes (second vk))))))

(defun %cert-extension (cert-bytes cert-start ext-oid)
  "Περιεχόμενο (bytes) του extnValue OCTET STRING της επέκτασης EXT-OID, ή NIL."
  (let ((exts (find #xa3 (%cert-tbs-fields cert-bytes cert-start) :key #'first)))
    (when exts
      (let ((seq (first (%tlv-children cert-bytes (second exts)
                                       (+ (second exts) (third exts))))))
        (dolist (ext (%tlv-children cert-bytes (second seq)
                                    (+ (second seq) (third seq))))
          (let* ((ek (%tlv-children cert-bytes (second ext)
                                    (+ (second ext) (third ext))))
                 (oid (%content-bytes cert-bytes (first ek)))
                 (val (find #x04 ek :key #'first))) ; extnValue (μετά τυχόν critical)
            (when (and val (equalp oid ext-oid))
              (return (%content-bytes cert-bytes val)))))))))

(defun %cert-timestamping-eku-p (cert-bytes cert-start)
  "T αν το cert έχει ExtendedKeyUsage με id-kp-timeStamping (RFC 3161 §2.3)."
  (let ((v (%cert-extension cert-bytes cert-start +oid-ext-eku+)))
    (and v
         (multiple-value-bind (tag cs cl) (der-read-tlv v 0)
           (and (= tag #x30)
                (loop for k in (%tlv-children v cs (+ cs cl))
                        thereis (equalp (%content-bytes v k) +oid-kp-timestamping+)))))))

(defun %cert-ca-p (cert-bytes cert-start)
  "T αν basicConstraints δηλώνει CA:TRUE."
  (let ((v (%cert-extension cert-bytes cert-start +oid-ext-basic-constraints+)))
    (and v
         (multiple-value-bind (tag cs cl) (der-read-tlv v 0)
           (and (= tag #x30)
                (let ((b (find #x01 (%tlv-children v cs (+ cs cl)) :key #'first)))
                  (and b (plusp (third b)) (= #xff (aref v (second b))))))))))

(defun %ess-digest-alg (oid-bytes)
  "Digest για ESS certHash — εδώ (ΜΟΝΟ εδώ) επιτρέπεται και SHA-1 (RFC 2634 v1)·
   δεν αγγίζει την υπογραφή, μόνο το identity binding του cert."
  (if (equalp oid-bytes +oid-sha1+) :sha1 (%digest-alg-from-oid oid-bytes "ESSCertID")))

(defun %ess-binds-cert-p (attr-bytes cert-der default-digest)
  "T αν κάποιο ESSCertID(v2) certHash ≡ digest(CERT-DER). ATTR-BYTES = το DER
   value του SigningCertificate(V2) attribute."
  (multiple-value-bind (tag cs cl) (der-read-tlv attr-bytes 0)
    (unless (= tag #x30)
      (error 'invalid-response :message "TSR: SigningCertificate — μη έγκυρη δομή"))
    (let ((certs-seq (first (%tlv-children attr-bytes cs (+ cs cl)))))
      (loop for essid in (%tlv-children attr-bytes (second certs-seq)
                                        (+ (second certs-seq) (third certs-seq)))
              thereis
              (let* ((ek (%tlv-children attr-bytes (second essid)
                                        (+ (second essid) (third essid))))
                     (alg (if (= (first (first ek)) #x30) ; explicit AlgorithmIdentifier
                              (let ((ak (%tlv-children attr-bytes (second (first ek))
                                                       (+ (second (first ek))
                                                          (third (first ek))))))
                                (%ess-digest-alg (%content-bytes attr-bytes (first ak))))
                              default-digest))
                     (h (find #x04 ek :key #'first)))
                (and h (equalp (%content-bytes attr-bytes h)
                               (ironclad:digest-sequence alg cert-der))))))))

(defun %cert-spki-public-key (cert-bytes cert-start cert-len)
  "Δημόσιο κλειδί από το SubjectPublicKeyInfo ενός X.509 cert (raw span).
   Επιστρέφει (values key kind) όπου KIND ∈ {:rsa, :secp256r1, :secp384r1,
   :secp521r1} — καλύπτει RSA ΚΑΙ ECDSA (οι TSAs χρησιμοποιούν και τα δύο:
   Sectigo RSA, FreeTSA ECDSA P-384)."
  (declare (ignore cert-len))
  (let* ((fields (%cert-tbs-fields cert-bytes cert-start))
         (spki (nth 5 fields)))
    (progn
          (unless (and spki (= (first spki) #x30))
            (error 'invalid-response :message "TSR: cert χωρίς SubjectPublicKeyInfo"))
          (destructuring-bind (spki-tag spki-start spki-len spki-next spki-pos) spki
            (declare (ignore spki-tag spki-next spki-pos))
            (let* ((spki-kids (%tlv-children cert-bytes spki-start (+ spki-start spki-len)))
                   (alg (first spki-kids))
                   (bitstr (second spki-kids)))
              (unless (and bitstr (= (first bitstr) #x03))
                (error 'invalid-response :message "TSR: SPKI χωρίς BIT STRING"))
              (let* ((alg-kids (%tlv-children cert-bytes (second alg)
                                              (+ (second alg) (third alg))))
                     (alg-oid (%content-bytes cert-bytes (first alg-kids)))
                     (bs (%content-bytes cert-bytes bitstr))
                     (point (subseq bs 1)))       ; drop unused-bits byte
                (cond
                  ;; RSA: BIT STRING περιέχει SEQUENCE{n,e}
                  ((not (equalp alg-oid +oid-ec-public-key+))
                   (let ((ints (der-sequence-elements point)))
                     (values (ironclad:make-public-key
                              :rsa :n (der-integer-value (first ints))
                                   :e (der-integer-value (second ints)))
                             :rsa)))
                  ;; ECDSA: namedCurve OID + uncompressed point (0x04||X||Y)
                  (t (let* ((curve-oid (%content-bytes cert-bytes (second alg-kids)))
                            (kind (cond ((equalp curve-oid +oid-secp256r1+) :secp256r1)
                                        ((equalp curve-oid +oid-secp384r1+) :secp384r1)
                                        ((equalp curve-oid +oid-secp521r1+) :secp521r1)
                                        (t (error 'invalid-response
                                                  :message "TSR: μη υποστηριζόμενη EC καμπύλη")))))
                       (values (ironclad:make-public-key kind :y point) kind))))))))))

(defun %ecdsa-sig-der->raw (der-sig field-bytes)
  "ECDSA υπογραφή CMS = DER SEQUENCE{r INTEGER, s INTEGER} → raw r‖s, κάθε
   σκέλος zero-padded/trimmed σε FIELD-BYTES (ό,τι θέλει το ironclad)."
  (let* ((ints (der-sequence-elements der-sig))
         (r (der-integer-value (first ints)))
         (s (der-integer-value (second ints))))
    ;; Έλεγχοι εύρους ΣΤΗΝ ΕΔΡΑ (εύρημα κριτή M1): r,s ∈ [1, 2^(8·field)-1] —
    ;; ποτέ σιωπηλή περικοπή oversize τιμής· το r,s < n το επιβάλλει το ironclad.
    (let ((cap (ash 1 (* 8 field-bytes))))
      (unless (and (< 0 r cap) (< 0 s cap))
        (error 'invalid-response
               :message "TSR: ECDSA r/s εκτός εύρους (0 ή υπερμεγέθης τιμή)")))
    (flet ((fixed (x)
             (let ((v (make-array field-bytes :element-type '(unsigned-byte 8)
                                              :initial-element 0)))
               (loop for i from (1- field-bytes) downto 0
                     for sh from 0 by 8
                     do (setf (aref v i) (ldb (byte 8 sh) x)))
               v)))
      (concatenate '(vector (unsigned-byte 8)) (fixed r) (fixed s)))))

(defun %verify-signer (input signature key kind digest)
  "Επαλήθευση υπογραφής SignerInfo/cert: RSA (PKCS#1 μέσω της έδρας) ή ECDSA
   (ironclad secp*, message = digest, sig = raw r‖s· για P-521 το SHA-512 hash
   των 512 bits < 521 bits της τάξης ⇒ e = ολόκληρο το hash, ορθό κατά FIPS
   186-4 §6.4). ΣΤΕΝΟΣ handler (εύρημα κριτή F3): ΜΟΝΟ οι αναμενόμενες
   δομικές/κρυπτο συνθήκες γίνονται «όχι» — εσωτερικά ελαττώματα ΔΙΑΔΙΔΟΝΤΑΙ."
  (handler-case
      (ecase kind
        (:rsa (orchestrator.jws-authority:verify-rsa-pkcs1 input signature key :digest digest))
        ((:secp256r1 :secp384r1 :secp521r1)
         (let* ((field (ecase kind (:secp256r1 32) (:secp384r1 48) (:secp521r1 66)))
                (h (ironclad:digest-sequence digest input))
                (raw (%ecdsa-sig-der->raw signature field)))
           (ironclad:verify-signature key h raw))))
    (asn1-error () nil)
    (invalid-response () nil)
    (ironclad:ironclad-error () nil)))

(defun %cert-tbs-span (bytes cert-child)
  "(values tbs-full-start tbs-full-end sig-alg-digest signature-bytes) του cert —
   το TBS ΟΛΟΚΛΗΡΟ TLV (με tag+len) είναι το υπογεγραμμένο μήνυμα."
  (destructuring-bind (tag cstart clen next pos) cert-child
    (declare (ignore tag next pos))
    (let ((kids (%tlv-children bytes cstart (+ cstart clen))))
      (destructuring-bind (tbs sig-alg sig-bits) (subseq kids 0 3)
        (destructuring-bind (tbs-tag tbs-cs tbs-cl tbs-next tbs-pos) tbs
          (declare (ignore tbs-tag tbs-cs tbs-cl))
          (let* ((alg-kids (%tlv-children bytes (second sig-alg)
                                          (+ (second sig-alg) (third sig-alg))))
                 (alg-oid (%content-bytes bytes (first alg-kids)))
                 ;; sha256/384/512WithRSAEncryption: 1.2.840.113549.1.1.{11,12,13}
                 (digest (cond ((equalp alg-oid #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x01 #x0b)) :sha256)
                               ((equalp alg-oid #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x01 #x0c)) :sha384)
                               ((equalp alg-oid #(#x2a #x86 #x48 #x86 #xf7 #x0d #x01 #x01 #x0d)) :sha512)
                               ;; ecdsa-with-SHA256/384/512: 1.2.840.10045.4.3.{2,3,4}
                               ((equalp alg-oid #(#x2a #x86 #x48 #xce #x3d #x04 #x03 #x02)) :sha256)
                               ((equalp alg-oid #(#x2a #x86 #x48 #xce #x3d #x04 #x03 #x03)) :sha384)
                               ((equalp alg-oid #(#x2a #x86 #x48 #xce #x3d #x04 #x03 #x04)) :sha512)
                               (t nil)))
                 (sig (let ((raw (%content-bytes bytes sig-bits)))
                        (subseq raw 1))))     ; BIT STRING unused-bits byte
            (values tbs-pos tbs-next digest sig)))))))

(defun verify-tsr-cryptographically (tsr-bytes message-bytes &key ca-pem-path)
  "ΠΛΗΡΗΣ επαλήθευση RFC-3161 TSR πάνω στο MESSAGE-BYTES.
   Επιστρέφει (values tier plist) όπου TIER ∈ {:pinned, :unpinned} — ή σφάλμα
   INVALID-RESPONSE σε ΟΠΟΙΑΔΗΠΟΤΕ κρυπτογραφική αποτυχία (fail-closed).
   PLIST: :gen-time (string GeneralizedTime) :digest (:sha256|:sha384|:sha512).

   ΤΙΜΙΑ ΔΙΑΒΑΘΜΙΣΗ ΕΜΠΙΣΤΟΣΥΝΗΣ (εύρημα κριτή C1 — διάβασέ το ΠΡΙΝ βασιστείς
   στο αποτέλεσμα): το :UNPINNED ΔΕΝ ΑΥΘΕΝΤΙΚΟΠΟΙΕΙ ΤΙΠΟΤΑ ως προς το ΠΟΙΟΣ
   υπέγραψε — επιτιθέμενος με δικό του κλειδί + δικό του embedded cert φτιάχνει
   TSR που περνά ΟΛΟΥΣ τους ελέγχους αυτού του tier. Το :unpinned πιστοποιεί
   ΜΟΝΟ εσωτερική συνέπεια (imprint↔μήνυμα, signedAttrs↔TSTInfo, υπογραφή↔
   embedded cert με timestamping EKU + ESS binding). ΕΜΠΙΣΤΟΣΥΝΗ ⇒ ΜΟΝΟ
   :pinned (signer cert ταυτίζεται με ή υπογράφεται από pinned CA:TRUE αρχή,
   με genTime εντός ισχύος). Χρήση :unpinned μόνο ως διαγνωστικό."
  ;; Αυστηρότητα ορίων (εύρημα κριτή M3): κανένα trailing byte μετά το
  ;; εξωτερικό TimeStampResp TLV — ό,τι δεν καλύπτει η δομή απορρίπτεται.
  (multiple-value-bind (tag cstart clen next) (der-read-tlv tsr-bytes 0)
    (declare (ignore tag cstart clen))
    (unless (= next (length tsr-bytes))
      (error 'invalid-response :message "TSR: trailing bytes μετά το TimeStampResp")))
  (let* ((top (%constructed-children tsr-bytes 0 #x30 "TimeStampResp")))
    ;; [1] PKIStatusInfo.status ∈ {0,1}
    (let* ((status-seq (first top)))
      (unless (= (first status-seq) #x30)
        (error 'invalid-response :message "TSR: PKIStatusInfo απόν"))
      (let* ((st-kids (%tlv-children tsr-bytes (second status-seq)
                                     (+ (second status-seq) (third status-seq))))
             (status (der-integer-value (%content-bytes tsr-bytes (first st-kids)))))
        (unless (member status '(0 1))
          (error 'invalid-response
                 :message (format nil "TSR: PKIStatus=~D (όχι granted)" status)))))
    (let ((token (second top)))
      (unless (and token (= (first token) #x30))
        (error 'invalid-response :message "TSR: timeStampToken απόν"))
      ;; ContentInfo: OID signedData + [A0]{SignedData}
      (let* ((ci-kids (%tlv-children tsr-bytes (second token)
                                     (+ (second token) (third token)))))
        (unless (equalp (%content-bytes tsr-bytes (first ci-kids)) +oid-signed-data+)
          (error 'invalid-response :message "TSR: ContentInfo δεν είναι signedData"))
        (let* ((a0 (second ci-kids))
               (sd (first (%tlv-children tsr-bytes (second a0) (+ (second a0) (third a0)))))
               (sd-kids (%tlv-children tsr-bytes (second sd) (+ (second sd) (third sd))))
               ;; SignedData: version, digestAlgs SET, encapContentInfo, [A0]certs, ... signerInfos SET
               (encap (third sd-kids))
               (certs-child (find #xa0 (cddr sd-kids) :key #'first))
               (signer-set (find #x31 (reverse sd-kids) :key #'first)))
          ;; [2] encapContentInfo: OID TSTInfo + [A0]{OCTET STRING eContent}
          (let* ((e-kids (%tlv-children tsr-bytes (second encap)
                                        (+ (second encap) (third encap)))))
            (unless (equalp (%content-bytes tsr-bytes (first e-kids)) +oid-tst-info+)
              (error 'invalid-response :message "TSR: eContentType δεν είναι TSTInfo"))
            (let* ((ea0 (second e-kids))
                   (eoct (first (%tlv-children tsr-bytes (second ea0)
                                               (+ (second ea0) (third ea0)))))
                   (tst (%content-bytes tsr-bytes eoct))
                   (tst-kids (progn
                               ;; M3: ούτε trailing bytes μετά το TSTInfo TLV
                               (multiple-value-bind (tg cs cl nx) (der-read-tlv tst 0)
                                 (declare (ignore tg cs cl))
                                 (unless (= nx (length tst))
                                   (error 'invalid-response
                                          :message "TSR: trailing bytes μετά το TSTInfo")))
                               (%constructed-children tst 0 #x30 "TSTInfo")))
                   ;; TSTInfo: version, policy OID, messageImprint SEQ, serial, genTime
                   (imprint (third tst-kids))
                   (imp-kids (%tlv-children tst (second imprint)
                                            (+ (second imprint) (third imprint))))
                   (alg-kids (%tlv-children tst (second (first imp-kids))
                                            (+ (second (first imp-kids))
                                               (third (first imp-kids)))))
                   (imp-alg (%digest-alg-from-oid (%content-bytes tst (first alg-kids))
                                                  "messageImprint"))
                   (imp-hash (%content-bytes tst (second imp-kids)))
                   (gen-time (let ((gt (find #x18 tst-kids :key #'first)))
                               (and gt (babel:octets-to-string
                                        (%content-bytes tst gt) :encoding :ascii)))))
              ;; [2] imprint ≡ digest(message) — ΘΕΣΙΑΚΑ
              (unless (equalp imp-hash (ironclad:digest-sequence imp-alg message-bytes))
                (error 'invalid-response
                       :message "TSR: messageImprint ≠ digest(message) — το receipt ΔΕΝ δένει αυτό το μήνυμα"))
              ;; [3]+[4] SignerInfo
              (unless signer-set
                (error 'invalid-response :message "TSR: signerInfos απόντα"))
              (let* ((si (first (%tlv-children tsr-bytes (second signer-set)
                                               (+ (second signer-set) (third signer-set)))))
                     (si-kids (%tlv-children tsr-bytes (second si)
                                             (+ (second si) (third si))))
                     (sattrs (find #xa0 si-kids :key #'first))
                     (digest-alg
                       (let* ((da (third si-kids))
                              (da-kids (%tlv-children tsr-bytes (second da)
                                                      (+ (second da) (third da)))))
                         (%digest-alg-from-oid (%content-bytes tsr-bytes (first da-kids))
                                               "SignerInfo.digestAlgorithm")))
                     (sig-oct (find #x04 (reverse si-kids) :key #'first))
                     (signature (%content-bytes tsr-bytes sig-oct)))
                (unless sattrs
                  (error 'invalid-response :message "TSR: signedAttrs απόντα (απαιτούνται για TSTInfo)"))
                ;; [3] signedAttrs: messageDigest ≡ digest(eContent), contentType ≡ TSTInfo
                ;; + σύλληψη SigningCertificate(V2)/ESSCertID (εύρημα κριτή C3)
                (let ((md nil) (ct nil) (ess nil) (ess-default nil))
                  (dolist (attr (%tlv-children tsr-bytes (second sattrs)
                                               (+ (second sattrs) (third sattrs))))
                    (let* ((ak (%tlv-children tsr-bytes (second attr)
                                              (+ (second attr) (third attr))))
                           (aoid (%content-bytes tsr-bytes (first ak)))
                           (aset (second ak))
                           (aval (first (%tlv-children tsr-bytes (second aset)
                                                       (+ (second aset) (third aset))))))
                      (cond ((equalp aoid +oid-message-digest+)
                             (setf md (%content-bytes tsr-bytes aval)))
                            ((equalp aoid +oid-content-type+)
                             (setf ct (%content-bytes tsr-bytes aval)))
                            ((equalp aoid +oid-signing-certificate-v2+)
                             (setf ess (subseq tsr-bytes (fifth aval) (fourth aval))
                                   ess-default :sha256))
                            ((and (equalp aoid +oid-signing-certificate+) (null ess))
                             (setf ess (subseq tsr-bytes (fifth aval) (fourth aval))
                                   ess-default :sha1)))))
                  (unless (and md (equalp md (ironclad:digest-sequence digest-alg tst)))
                    (error 'invalid-response
                           :message "TSR: signedAttrs.messageDigest ≠ digest(TSTInfo)"))
                  (unless (and ct (equalp ct +oid-tst-info+))
                    (error 'invalid-response
                           :message "TSR: signedAttrs.contentType ≠ TSTInfo"))
                  (unless ess
                    (error 'invalid-response
                           :message "TSR: SigningCertificate(V2) απόν — το RFC 3161 §2.4.2 το ΑΠΑΙΤΕΙ"))
                ;; [4]+[5] υπογραφή πάνω στο DER(SET signedAttrs): retag A0→31
                (let* ((sa-full (subseq tsr-bytes (fifth sattrs) (fourth sattrs)))
                       (si-input (let ((v (copy-seq sa-full)))
                                   (setf (aref v 0) #x31) v))
                       (cert-children
                         (when certs-child
                           (%tlv-children tsr-bytes (second certs-child)
                                          (+ (second certs-child) (third certs-child)))))
                       (signer-cert
                         (loop for c in cert-children
                               do (multiple-value-bind (pub kind)
                                      (handler-case ; ΣΤΕΝΟΣ handler (F3)
                                          (%cert-spki-public-key tsr-bytes (fifth c)
                                                                 (- (fourth c) (fifth c)))
                                        (asn1-error () nil)
                                        (invalid-response () nil))
                                    (when (and pub
                                               (%verify-signer si-input signature pub kind
                                                               digest-alg))
                                      (return c))))))
                  (unless signer-cert
                    (error 'invalid-response
                           :message "TSR: ΚΑΝΕΝΑ embedded cert δεν επαληθεύει την υπογραφή του SignerInfo"))
                  (let ((signer-der (subseq tsr-bytes (fifth signer-cert) (fourth signer-cert))))
                    ;; [5β] ESSCertID (C3): το υπογεγραμμένο SigningCertificate(V2)
                    ;; πρέπει να δένει ΑΚΡΙΒΩΣ το cert που επαλήθευσε την υπογραφή —
                    ;; τέλος στα cert-injection παιχνίδια της επιλογής signer.
                    (unless (%ess-binds-cert-p ess signer-der ess-default)
                      (error 'invalid-response
                             :message "TSR: ESSCertID ≠ hash(signer cert) — το receipt ΔΕΝ ονομάζει αυτόν τον υπογράφοντα"))
                    ;; [5γ] EKU (C2): ο signer πρέπει να ΔΗΛΩΝΕΙ id-kp-timeStamping.
                    (unless (%cert-timestamping-eku-p tsr-bytes (fifth signer-cert))
                      (error 'invalid-response
                             :message "TSR: signer cert χωρίς ExtendedKeyUsage id-kp-timeStamping (RFC 3161 §2.3)"))
                    ;; [5δ] genTime εντός ισχύος του signer cert (C2).
                    (multiple-value-bind (nb na) (%cert-validity tsr-bytes (fifth signer-cert))
                      (unless (and gen-time (string<= nb gen-time) (string<= gen-time na))
                        (error 'invalid-response
                               :message (format nil "TSR: genTime ~A εκτός ισχύος signer cert [~A, ~A]"
                                                gen-time nb na))))
                    ;; [6] άγκυρα: pinned CA (αν δόθηκε) — είτε το signer cert ΕΙΝΑΙ
                    ;; pinned (ταυτότητα DER), είτε υπογράφεται από pinned cert που
                    ;; δηλώνει basicConstraints CA:TRUE (C2).
                    (let ((tier :unpinned))
                      (when (and ca-pem-path (probe-file ca-pem-path))
                        (let* ((pem (alexandria:read-file-into-string ca-pem-path))
                               (ca-ders (pem->der-all-blocks pem "CERTIFICATE")))
                          (unless ca-ders
                            (error 'invalid-response
                                   :message "TSR: pinned CA PEM χωρίς CERTIFICATE block"))
                          (unless
                              (or ;; (α) ταυτότητα: signer cert ≡ pinned cert (L1)
                                  (member signer-der ca-ders :test #'equalp)
                                  ;; (β) pinned CA:TRUE υπογράφει το signer TBS
                                  (multiple-value-bind (tbs-start tbs-end cert-digest cert-sig)
                                      (%cert-tbs-span tsr-bytes signer-cert)
                                    (unless cert-digest
                                      (error 'invalid-response
                                             :message "TSR: signer cert με μη υποστηριζόμενο αλγόριθμο υπογραφής"))
                                    (let ((tbs (subseq tsr-bytes tbs-start tbs-end)))
                                      (loop for der in ca-ders
                                              thereis
                                              (multiple-value-bind (k kind)
                                                  (handler-case
                                                      (%cert-spki-public-key der 0 (length der))
                                                    (asn1-error () nil)
                                                    (invalid-response () nil))
                                                (and k
                                                     (%cert-ca-p der 0) ; CA:TRUE (C2)
                                                     (%verify-signer tbs cert-sig k kind
                                                                     cert-digest)))))))
                            (error 'invalid-response
                                   :message "TSR: το signer cert ΟΥΤΕ ταυτίζεται με ΟΥΤΕ υπογράφεται από pinned CA:TRUE αρχή"))
                          (setf tier :pinned)))
                      (values tier (list :gen-time gen-time :digest digest-alg))))))))))))))
