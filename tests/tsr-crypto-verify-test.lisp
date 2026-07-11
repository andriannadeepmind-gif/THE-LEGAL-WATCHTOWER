;;;; tests/tsr-crypto-verify-test.lisp
;;;; ============================================================================
;;;; P4 — ΠΛΗΡΗΣ κρυπτογραφική επαλήθευση RFC-3161 TSR (regression lock)
;;;; ============================================================================
;;;; Κλείδωμα της νέας συμπεριφοράς verify-tsr-cryptographically σε ΓΝΗΣΙΑ
;;;; receipts (owner TSAs, 2026-07-10) — ΔΥΟ ανεξάρτητοι αλγόριθμοι υπογραφής:
;;;;   • Sectigo   = RSASSA-PKCS1-v1_5 / SHA-384
;;;;   • FreeTSA   = ECDSA P-384 / SHA-512
;;;; Fixtures αυτοτελή στο tests/fixtures/tsr/ (αποσυνδεμένα από output/ churn).
;;;; Θετικά: και οι δύο επαληθεύονται πάνω στο ΙΔΙΟ message (root string).
;;;; Αρνητικά (fail-closed): λάθος μήνυμα, cross-binding, νοθευμένη υπογραφή,
;;;; ακρωτηριασμένο TSR — ΚΑΘΕ ένα ⇒ σφάλμα, ΠΟΤΕ σιωπηλό πράσινο.
;;;; ============================================================================

(in-package :orchestrator.timestamp-authority)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *fix*
  (merge-pathnames "fixtures/tsr/"
                   (make-pathname :directory (pathname-directory
                                              (or *load-truename* *load-pathname*)))))

(defun fx (name) (alexandria:read-file-into-byte-vector (merge-pathnames name *fix*)))
(defparameter *msg*
  (babel:string-to-octets
   (alexandria:read-file-into-string (merge-pathnames "message.txt" *fix*))
   :encoding :utf-8))

(defun verifies-p (tsr msg)
  "Boolean: το TSR επαληθεύεται κρυπτογραφικά πάνω στο msg;"
  (handler-case (progn (verify-tsr-cryptographically tsr msg) t)
    (error () nil)))

(format t "~%== [1] Θετικά: γνήσια receipts επαληθεύονται (RSA + ECDSA) ==~%")
(let ((rsa (fx "sectigo-rsa.tsr")) (ec (fx "freetsa-ecdsa.tsr")))
  (multiple-value-bind (tier plist) (verify-tsr-cryptographically rsa *msg*)
    ;; ΟΧΙ ταυτολογία (εύρημα κριτή F2): βεβαιώνεται η ΕΠΙΣΤΡΕΦΟΜΕΝΗ τιμή.
    (ck "Sectigo RSA ⇒ επαληθεύεται" (member tier '(:pinned :unpinned)))
    (ck "Sectigo tier = :unpinned (τίμια, χωρίς pinned CA)" (eq tier :unpinned))
    (ck "Sectigo digest = :sha384" (eq (getf plist :digest) :sha384))
    (ck "Sectigo genTime = GeneralizedTime Z"
        (let ((gt (getf plist :gen-time)))
          (and gt (char= #\Z (char gt (1- (length gt))))))))
  (multiple-value-bind (tier plist) (verify-tsr-cryptographically ec *msg*)
    (ck "FreeTSA ECDSA P-384 ⇒ επαληθεύεται" (member tier '(:pinned :unpinned)))
    (ck "FreeTSA tier = :unpinned" (eq tier :unpinned))
    (ck "FreeTSA digest = :sha512" (eq (getf plist :digest) :sha512))
    (ck "FreeTSA genTime = GeneralizedTime Z"
        (let ((gt (getf plist :gen-time)))
          (and gt (char= #\Z (char gt (1- (length gt)))))))))

(format t "~%== [2] Αρνητικά: λάθος μήνυμα ⇒ ΑΠΟΡΡΙΨΗ (imprint binding) ==~%")
(let ((wrong (babel:string-to-octets "sha256:0000000000000000000000000000000000000000000000000000000000000000"
                                     :encoding :utf-8)))
  (ck "Sectigo + λάθος message ⇒ FAIL" (not (verifies-p (fx "sectigo-rsa.tsr") wrong)))
  (ck "FreeTSA + λάθος message ⇒ FAIL" (not (verifies-p (fx "freetsa-ecdsa.tsr") wrong))))

(format t "~%== [3] Αρνητικά: νοθευμένη υπογραφή/δομή ⇒ ΑΠΟΡΡΙΨΗ (fail-closed) ==~%")
(let* ((rsa (fx "sectigo-rsa.tsr"))
       (mut (copy-seq rsa)))
  ;; flip ένα byte μέσα στην ουρά (signatureValue region) — καμία forgery δεν περνά
  (setf (aref mut (- (length mut) 8)) (logxor (aref mut (- (length mut) 8)) #x01))
  (ck "Sectigo με flipped signature byte ⇒ FAIL" (not (verifies-p mut *msg*))))
(let* ((ec (fx "freetsa-ecdsa.tsr"))
       (mut (copy-seq ec)))
  (setf (aref mut (- (length mut) 6)) (logxor (aref mut (- (length mut) 6)) #x80))
  (ck "FreeTSA με flipped signature byte ⇒ FAIL" (not (verifies-p mut *msg*))))

(format t "~%== [4] Αρνητικά: ακρωτηριασμένο TSR ⇒ ΑΠΟΡΡΙΨΗ (όχι crash) ==~%")
(let ((rsa (fx "sectigo-rsa.tsr")))
  (ck "μισό TSR ⇒ FAIL" (not (verifies-p (subseq rsa 0 (floor (length rsa) 2)) *msg*)))
  (ck "άδειο TSR ⇒ FAIL" (not (verifies-p (make-array 0 :element-type '(unsigned-byte 8)) *msg*))))

;; ── [5] :pinned tier — η ΑΓΚΥΡΑ (task title: «υπογραφή TSA κατά pinned CA») ──
;; Ο εκδότης CN του κάθε signer cert είναι ΕΝΣΩΜΑΤΩΜΕΝΟΣ στην αλυσίδα του TSR·
;; τον καρφιτσώνουμε ως pinned CA και απαιτούμε το signer cert να υπογράφεται
;; από αυτόν. ΔΥΟ αλγόριθμοι αγκύρωσης cert-signature ζωντανά:
;;   • Sectigo signer  ← intermediate CA  (RSA / SHA-384)
;;   • FreeTSA signer  ← Root CA          (ECDSA P-384 / SHA-512)  ← %cert-tbs-span EC κλάδος
(defun tier-with-ca (tsr-name ca-name)
  (multiple-value-bind (tier)
      (verify-tsr-cryptographically (fx tsr-name) *msg*
                                    :ca-pem-path (merge-pathnames ca-name *fix*))
    tier))
(format t "~%== [5] :pinned tier — signer cert αγκυρωμένο σε ΓΝΗΣΙΟ embedded issuer CA ==~%")
(ck "Sectigo signer ← intermediate CA (RSA) ⇒ :pinned"
    (eq :pinned (tier-with-ca "sectigo-rsa.tsr" "sectigo-issuer-ca.pem")))
(ck "FreeTSA signer ← Root CA (ECDSA anchor) ⇒ :pinned"
    (eq :pinned (tier-with-ca "freetsa-ecdsa.tsr" "freetsa-issuer-ca.pem")))
(format t "~%== [5.5] Αρνητικά κριτών C1/M3: αυστηρότητα ορίων ==~%")
(let* ((rsa (fx "sectigo-rsa.tsr"))
       (padded (concatenate '(vector (unsigned-byte 8)) rsa #(#x00))))
  (ck "trailing byte μετά το TimeStampResp ⇒ FAIL (M3)"
      (not (verifies-p padded *msg*))))

(format t "~%== [6] Αρνητικά: ΛΑΘΟΣ pinned CA ⇒ ΑΠΟΡΡΙΨΗ (ποτέ σιωπηλό :unpinned) ==~%")
(ck "Sectigo καρφιτσωμένο στην CA της FreeTSA ⇒ FAIL"
    (handler-case (progn (tier-with-ca "sectigo-rsa.tsr" "freetsa-issuer-ca.pem") nil)
      (error () t)))
(ck "FreeTSA καρφιτσωμένο στην CA της Sectigo ⇒ FAIL"
    (handler-case (progn (tier-with-ca "freetsa-ecdsa.tsr" "sectigo-issuer-ca.pem") nil)
      (error () t)))

(format t "~%========================================~%")
(format t "TSR crypto-verify tests: ~D passed, ~D failed~%" *p* *f*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *f*) 0 1))
