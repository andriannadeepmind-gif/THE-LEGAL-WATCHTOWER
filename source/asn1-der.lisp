;;;; source/asn1-der.lisp
;;;; ============================================================================
;;;; ASN.1 DER (X.690) — Η ΜΙΑ ΕΔΡΑ ΤΟΥ ΙΔΡΥΜΑΤΟΣ
;;;; ============================================================================
;;;;
;;;; Κάθε κωδικοποίηση/αποκωδικοποίηση ASN.1 DER του συστήματος περνά από εδώ:
;;;;   - jws-authority: PEM→DER κλειδιών, RSAPrivateKey/SubjectPublicKeyInfo
;;;;   - timestamp-authority: RFC 3161 TimeStampReq
;;;;   - x509-authority: X.509 δομές + δομική επικύρωση πιστοποιητικών
;;;;   ([P1.5] το verify-authority πέθανε — καταναλωτής πλέον ανύπαρκτος)
;;;;
;;;; ΝΟΜΟΣ: μία έδρα ανά έννοια. Δεύτερος DER encoder/decoder ΔΕΝ γράφεται
;;;; πουθενά — επεκτείνεται ΑΥΤΟΣ.
;;;;
;;;; Ο decoder είναι ΑΥΣΤΗΡΟΣ (ο σπόρος του L6 kernel): απορρίπτει multi-byte
;;;; tags, αόριστο μήκος (BER, όχι DER), υπερμεγέθη πεδία μήκους και κάθε
;;;; υπέρβαση buffer — με σφάλμα, όχι σιωπηλή παρερμηνεία.
;;;; ============================================================================

(defpackage :orchestrator.asn1
  (:use :cl)
  (:export
   ;; Condition
   #:asn1-error
   #:asn1-error-message
   ;; Αυστηρή αποκωδικοποίηση DER
   #:der-read-tlv
   #:der-sequence-elements
   #:der-integer-value
   ;; Κωδικοποίηση DER
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
   #:encode-asn1-context-specific
   ;; PEM ↔ DER (RFC 7468)
   #:pem->der
   #:pem->der-all-blocks
   #:der->pem))

(in-package :orchestrator.asn1)

;;; ============================================================================
;;; CONDITION
;;; ============================================================================

(define-condition asn1-error (error)
  ((message :initarg :message :reader asn1-error-message))
  (:report (lambda (c s)
             (format s "ASN.1 Error: ~A" (asn1-error-message c)))))

;;; ============================================================================
;;; ΑΥΣΤΗΡΗ ΑΠΟΚΩΔΙΚΟΠΟΙΗΣΗ DER
;;; ============================================================================

(defparameter +der-max-depth+ 64
  "Ανώτατο βάθος εμφώλευσης SEQUENCE που αποκωδικοποιεί η έδρα. Κάθε γνήσια
   δομή του συστήματος (X.509 ~8, RSA κλειδιά ~3, RFC-3161 ~5) είναι πολύ κάτω
   από αυτό· το όριο υπάρχει ώστε κακόβουλη βαθιά εμφώλευση να εγείρει ASN1-ERROR
   ΠΡΙΝ εξαντληθεί η στοίβα ελέγχου (θανατηφόρα, μη-ανακτήσιμη κατάρρευση
   διεργασίας). Εξάλειψη της κλάσης σφάλματος, όχι φρουρός γύρω της.")

(defun der-read-tlv (bytes offset)
  "Διάβασε ΕΝΑ ASN.1 TLV στο OFFSET. Επιστρέφει (values tag content-start
   content-len next-offset). Σφάλμα ASN1-ERROR σε κακοσχηματισμένο tag/μήκος,
   αόριστο μήκος (BER), ΜΗ-ΕΛΑΧΙΣΤΟ μήκος (X.690 §10.1: leading zero octet ή
   long-form για <128 — μη-DER), πεδίο μήκους >4 bytes ή υπέρβαση buffer."
  (let ((len (length bytes)))
    (when (>= offset len)
      (error 'asn1-error :message "DER: πρόωρο τέλος (tag)"))
    (let* ((tag (aref bytes offset))
           (p (1+ offset)))
      (when (= (logand tag #x1f) #x1f)
        (error 'asn1-error :message "DER: multi-byte tags δεν υποστηρίζονται"))
      (when (>= p len)
        (error 'asn1-error :message "DER: πρόωρο τέλος (length)"))
      (let ((len-byte (aref bytes p)))
        (incf p)
        (let ((content-len
                (if (< len-byte #x80)
                    len-byte
                    (let ((num (logand len-byte #x7f)))
                      (when (zerop num)
                        (error 'asn1-error :message "DER: αόριστο μήκος (BER, όχι DER)"))
                      (when (> num 4)
                        (error 'asn1-error :message "DER: υπερμέγεθες πεδίο μήκους"))
                      (when (> (+ p num) len)
                        (error 'asn1-error :message "DER: πρόωρο τέλος (long length)"))
                      ;; X.690 §10.1: ελάχιστη κωδικοποίηση μήκους — κανένα
                      ;; προπορευόμενο μηδενικό octet.
                      (when (zerop (aref bytes p))
                        (error 'asn1-error :message "DER: μη-ελάχιστο μήκος (leading zero octet)"))
                      (let ((acc 0))
                        (dotimes (i num) (setf acc (logior (ash acc 8) (aref bytes (+ p i)))))
                        (incf p num)
                        ;; X.690 §10.1: long-form επιτρέπεται ΜΟΝΟ για μήκος ≥ 128.
                        (when (< acc 128)
                          (error 'asn1-error :message "DER: μη-ελάχιστο μήκος (long-form για <128)"))
                        acc)))))
          (when (> (+ p content-len) len)
            (error 'asn1-error :message "DER: το μήκος περιεχομένου υπερβαίνει το buffer"))
          (values tag p content-len (+ p content-len)))))))

(defun der-sequence-elements (bytes &optional (offset 0) (depth 0))
  "Αποκωδικοποίησε ένα SEQUENCE στο OFFSET σε λίστα στοιχείων:
     NULL ⇒ NIL · εμφωλευμένο SEQUENCE ⇒ λίστα (αναδρομικά) ·
     κάθε άλλο tag (INTEGER/BIT STRING/OCTET STRING/OID/…) ⇒ τα content bytes.
   Σφάλμα ASN1-ERROR αν το OFFSET δεν δείχνει SEQUENCE, αν παιδί υπερβαίνει το
   όριο του SEQUENCE (αυστηρό DER — καμία σιωπηλή αποκοπή), ή αν το βάθος
   εμφώλευσης ξεπεράσει το +DER-MAX-DEPTH+ (προστασία στοίβας)."
  (when (> depth +der-max-depth+)
    (error 'asn1-error
           :message (format nil "DER: βάθος εμφώλευσης > ~D — άρνηση (προστασία στοίβας)"
                            +der-max-depth+)))
  (multiple-value-bind (tag content-start content-len)
      (der-read-tlv bytes offset)
    (unless (= tag #x30)
      (error 'asn1-error
             :message (format nil "DER: αναμενόταν SEQUENCE (0x30), βρέθηκε 0x~2,'0X" tag)))
    (let ((end (+ content-start content-len))
          (elements nil)
          (pos content-start))
      (loop while (< pos end)
            do (multiple-value-bind (ctag cstart clen cnext)
                   (der-read-tlv bytes pos)
                 (when (> cnext end)
                   (error 'asn1-error :message "DER: στοιχείο υπερβαίνει το όριο του SEQUENCE"))
                 (push (cond ((= ctag #x05) nil)                      ; NULL
                             ((= ctag #x30)                           ; nested SEQUENCE
                              (der-sequence-elements bytes pos (1+ depth)))
                             (t (subseq bytes cstart (+ cstart clen))))
                       elements)
                 (setf pos cnext)))
      (nreverse elements))))

(defun der-integer-value (content)
  "Τιμή ASN.1 INTEGER από τα content bytes του, ως ΜΗ-ΑΡΝΗΤΙΚΟΣ ακέραιος
   (big-endian· τυχόν προπορευόμενο μηδενικό byte θετικότητας δεν επηρεάζει).
   Τα INTEGER που αποκωδικοποιεί το σύστημα (RSA συνιστώσες, PKIStatus) είναι
   εξ ορισμού μη-αρνητικά — αρνητικές τιμές είναι εκτός πεδίου αυτής της έδρας."
  (let ((acc 0))
    (loop for b across content do (setf acc (logior (ash acc 8) b)))
    acc))

;;; ============================================================================
;;; ΚΩΔΙΚΟΠΟΙΗΣΗ DER
;;; ============================================================================

(defun encode-asn1-length (length)
  "Encode ASN.1 length field"
  (cond
    ((< length 128)
     (vector length))
    ((< length 256)
     (vector #x81 length))
    ((< length 65536)
     (vector #x82 (ash length -8) (logand length #xff)))
    (t
     (let* ((bytes (ironclad:integer-to-octets length))
            (len (length bytes)))
       (concatenate '(vector (unsigned-byte 8))
                    (vector (logior #x80 len))
                    bytes)))))

(defun encode-asn1-sequence (elements)
  "Encode list of DER elements as SEQUENCE"
  (let ((content (apply #'concatenate '(vector (unsigned-byte 8)) elements)))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x30)  ; SEQUENCE tag
                 (encode-asn1-length (length content))
                 content)))

(defun encode-asn1-set (elements)
  "Encode list of DER elements as SET"
  (let ((content (apply #'concatenate '(vector (unsigned-byte 8)) elements)))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x31)  ; SET tag
                 (encode-asn1-length (length content))
                 content)))

(defun encode-asn1-integer (value)
  "Encode integer as ASN.1 INTEGER"
  (let* ((bytes (if (zerop value)
                    (vector 0)
                    (ironclad:integer-to-octets value)))
         ;; Add leading zero if high bit set (to keep positive)
         (padded (if (and (> (length bytes) 0)
                          (>= (aref bytes 0) 128))
                     (concatenate '(vector (unsigned-byte 8)) (vector 0) bytes)
                     bytes)))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x02)  ; INTEGER tag
                 (encode-asn1-length (length padded))
                 padded)))

(defun encode-asn1-bit-string (content)
  "Encode bytes as ASN.1 BIT STRING"
  (let ((with-unused (concatenate '(vector (unsigned-byte 8))
                                  (vector 0)  ; 0 unused bits
                                  content)))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x03)  ; BIT STRING tag
                 (encode-asn1-length (length with-unused))
                 with-unused)))

(defun encode-asn1-octet-string (content)
  "Encode bytes as ASN.1 OCTET STRING"
  (concatenate '(vector (unsigned-byte 8))
               (vector #x04)  ; OCTET STRING tag
               (encode-asn1-length (length content))
               content))

(defun encode-asn1-null ()
  "Encode ASN.1 NULL"
  (vector #x05 #x00))

(defun encode-asn1-oid (components)
  "Encode OID as ASN.1 OBJECT IDENTIFIER"
  (let ((encoded (make-array 0 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0)))
    ;; First two components combined: 40*first + second
    (vector-push-extend (+ (* 40 (first components)) (second components)) encoded)
    ;; Remaining components use base-128 encoding
    (dolist (c (cddr components))
      (let ((bytes nil))
        (if (zerop c)
            (push 0 bytes)
            (loop while (> c 0)
                  do (push (logior (if bytes #x80 0) (logand c #x7f)) bytes)
                     (setf c (ash c -7))))
        (dolist (b bytes)
          (vector-push-extend b encoded))))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x06)  ; OID tag
                 (encode-asn1-length (length encoded))
                 encoded)))

(defun encode-asn1-utf8-string (string)
  "Encode string as ASN.1 UTF8String"
  (let ((bytes (babel:string-to-octets string :encoding :utf-8)))
    (concatenate '(vector (unsigned-byte 8))
                 (vector #x0c)  ; UTF8String tag
                 (encode-asn1-length (length bytes))
                 bytes)))

(defun encode-asn1-utc-time (universal-time)
  "Encode time as ASN.1 UTCTime (YYMMDDhhmmssZ)"
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal-time 0)
    (let* ((time-string (format nil "~2,'0D~2,'0D~2,'0D~2,'0D~2,'0D~2,'0DZ"
                                (mod year 100) month day hour min sec))
           (bytes (babel:string-to-octets time-string :encoding :ascii)))
      (concatenate '(vector (unsigned-byte 8))
                   (vector #x17)  ; UTCTime tag
                   (encode-asn1-length (length bytes))
                   bytes))))

(defun encode-asn1-generalized-time (universal-time)
  "Encode time as ASN.1 GeneralizedTime (YYYYMMDDhhmmssZ)"
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal-time 0)
    (let* ((time-string (format nil "~4,'0D~2,'0D~2,'0D~2,'0D~2,'0D~2,'0DZ"
                                year month day hour min sec))
           (bytes (babel:string-to-octets time-string :encoding :ascii)))
      (concatenate '(vector (unsigned-byte 8))
                   (vector #x18)  ; GeneralizedTime tag
                   (encode-asn1-length (length bytes))
                   bytes))))

(defun encode-asn1-boolean (value)
  "Encode ASN.1 BOOLEAN"
  (vector #x01 #x01 (if value #xff #x00)))

(defun encode-asn1-context-specific (tag-number content &key (constructed nil))
  "Encode context-specific tagged value [n]"
  (let ((tag (logior #xa0  ; Context-specific class
                     (if constructed #x20 #x00)
                     tag-number)))
    (concatenate '(vector (unsigned-byte 8))
                 (vector tag)
                 (encode-asn1-length (length content))
                 content)))

;;; ============================================================================
;;; PEM ↔ DER (RFC 7468)
;;; ============================================================================

(defun pem->der (pem-string label-or-labels)
  "Αποκωδικοποίηση PEM μπλοκ «-----BEGIN <LABEL>-----…-----END <LABEL>-----»
   σε DER bytes. LABEL-OR-LABELS: string ή λίστα αποδεκτών labels (π.χ.
   '(\"RSA PRIVATE KEY\" \"PRIVATE KEY\") για PKCS#1/PKCS#8) — δοκιμάζονται με
   τη σειρά. Σφάλμα ASN1-ERROR αν κανένα label δεν βρεθεί με ζεύγος φρουρών ή
   αν το base64 είναι άκυρο. ΔΕΝ δέχεται μπλοκ χωρίς label — καμία σιωπηλή
   αφαίρεση «όποιας γραμμής μοιάζει με φρουρό»."
  (let ((labels (if (listp label-or-labels) label-or-labels (list label-or-labels))))
    (dolist (label labels
             (error 'asn1-error
                    :message (format nil "PEM: λείπουν οι φρουροί για ~{~A~^ / ~}" labels)))
      (let* ((begin (format nil "-----BEGIN ~A-----" label))
             (end   (format nil "-----END ~A-----" label))
             (b (search begin pem-string))
             (e (search end pem-string)))
        (when (and b e (< b e))
          (let* ((body (subseq pem-string (+ b (length begin)) e))
                 (b64 (remove-if (lambda (c) (member c '(#\Newline #\Return #\Space #\Tab)))
                                 body)))
            (return
              (handler-case (cl-base64:base64-string-to-usb8-array b64)
                (error (ex)
                  (error 'asn1-error
                         :message (format nil "PEM ~A: άκυρο base64 (~A)" label ex)))))))))))

(defun %pem-whitespace-p (c)
  (member c '(#\Newline #\Return #\Space #\Tab #\Page)))

(defun pem->der-all-blocks (pem-string label)
  "ΟΛΑ τα DER blocks με το δοσμένο LABEL, με τη σειρά εμφάνισης, ως λίστα από
   (vector (unsigned-byte 8)). Σφάλμα ASN1-ERROR αν: κανένα block δεν βρεθεί,
   ένα base64 είναι άκυρο, ένα BEGIN δεν έχει αντίστοιχο END, ή υπάρχουν
   non-whitespace bytes ΕΚΤΟΣ των blocks (καμία λαθραία κεφαλή/ουρά/ενδιάμεσο).
   Αυτή είναι η ΜΙΑ έδρα ανάγνωσης αλυσίδας PEM — κλείνει την τρύπα «μόνο το
   πρώτο block» του pem->der, ώστε ένα CA bundle να επικυρώνεται ΟΛΟΚΛΗΡΟ."
  (let ((begin (format nil "-----BEGIN ~A-----" label))
        (end   (format nil "-----END ~A-----" label))
        (blocks nil)
        (cursor 0))
    (loop
      (let ((b (search begin pem-string :start2 cursor)))
        (cond
          ((null b)
           (when (find-if-not #'%pem-whitespace-p pem-string :start cursor)
             (error 'asn1-error
                    :message (format nil "PEM ~A: non-whitespace bytes εκτός block (ουρά)" label)))
           (return))
          (t
           (when (find-if-not #'%pem-whitespace-p pem-string :start cursor :end b)
             (error 'asn1-error
                    :message (format nil "PEM ~A: non-whitespace bytes εκτός block (πριν BEGIN)" label)))
           (let ((e (search end pem-string :start2 (+ b (length begin)))))
             (unless e
               (error 'asn1-error :message (format nil "PEM ~A: BEGIN χωρίς END" label)))
             (let* ((body (subseq pem-string (+ b (length begin)) e))
                    (b64 (remove-if #'%pem-whitespace-p body)))
               (push (handler-case (cl-base64:base64-string-to-usb8-array b64)
                       (error (ex)
                         (error 'asn1-error
                                :message (format nil "PEM ~A: άκυρο base64 (~A)" label ex))))
                     blocks))
             (setf cursor (+ e (length end))))))))
    (when (null blocks)
      (error 'asn1-error :message (format nil "PEM: λείπουν οι φρουροί ~A" label)))
    (nreverse blocks)))

(defun der->pem (der-bytes label)
  "Κωδικοποίηση DER bytes σε PEM μπλοκ με το δοσμένο LABEL (γραμμές 64 χαρ.)."
  (let* ((base64 (cl-base64:usb8-array-to-base64-string der-bytes))
         (lines (loop for i from 0 below (length base64) by 64
                      collect (subseq base64 i (min (+ i 64) (length base64))))))
    (format nil "-----BEGIN ~A-----~%~{~A~%~}-----END ~A-----~%"
            label lines label)))
