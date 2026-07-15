;;;; tests/authority-proof-bundle-test.lisp
;;;; ============================================================================
;;;; [0088 Φ7-HARDENING #4] Regression lock: verify-authority-proof-bundle
;;;; ============================================================================
;;;; Ο ανεξάρτητος, hermetic, fail-closed επαληθευτής αλυσίδας εξουσίας.
;;;; ΘΕΤΙΚΟ: πλήρες bundle με ΓΝΗΣΙΑ κρυπτογραφία (Ed25519 owner root, RSA
;;;;   release key, ΓΝΗΣΙΟ RFC-3161 TSR fixture Sectigo, RFC-6962 receipt-set +
;;;;   tlog) ⇒ owner-pinned-authenticated, delegation :active.
;;;; ΑΡΝΗΤΙΚΑ (fail-closed μάρτυρες): κάθε νόθευση κρίκου ⇒ ονομαστική
;;;;   υποβάθμιση/απόρριψη — ΠΟΤΕ σιωπηλό πράσινο. Το trusted root/pin δίνεται
;;;;   ΕΞΩΘΕΝ (hermetic): το bundle ΔΕΝ αυτο-εξουσιοδοτείται.
;;;; ΤΕST ROOT — NOT PRODUCTION (Δ5): όλα τα κλειδιά είναι εφήμερα δοκιμαστικά.
;;;; ============================================================================

(in-package :orchestrator.apb)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;;; ── ΓΝΗΣΙΑ κρυπτογραφικά συστατικά (TEST ROOT — NOT PRODUCTION) ──

(defparameter *fix*
  (merge-pathnames "fixtures/tsr/"
                   (make-pathname :directory (pathname-directory
                                              (or *load-truename* *load-pathname*)))))
(defun fx (name) (alexandria:read-file-into-byte-vector (merge-pathnames name *fix*)))

(defparameter *release-root*
  ;; ΑΚΡΙΒΩΣ το μήνυμα που χρονοσφράγισε το ΓΝΗΣΙΟ Sectigo TSR ⇒ RC7 γνήσιο
  (string-trim '(#\Newline #\Space)
               (alexandria:read-file-into-string (merge-pathnames "message.txt" *fix*))))
(defparameter *root-hex* (subseq *release-root* 7))
(defparameter *tsr* (fx "sectigo-rsa.tsr"))

(multiple-value-bind (osk opk) (ironclad:generate-key-pair :ed25519)
  (defparameter *owner-sk* osk)
  (defparameter *owner-pk* opk))
(defparameter *owner-jwk* (ed25519-public-to-jwk *owner-pk*))
(defparameter *owner-thumb* (ed25519-jwk-thumbprint *owner-pk*))

;; δεύτερος owner (foreign) για αρνητικά pin
(multiple-value-bind (fsk fpk) (ironclad:generate-key-pair :ed25519)
  (defparameter *foreign-sk* fsk)
  (defparameter *foreign-pk* fpk))
(defparameter *foreign-jwk* (ed25519-public-to-jwk *foreign-pk*))

(defparameter *rsa* (orchestrator.jws-authority:generate-rsa-keypair :bits 2048))
(defparameter *rk-pub* (getf *rsa* :public-key))
(defparameter *rk-priv* (getf *rsa* :private-key))
(defun %b64uint (n) (orchestrator.jws-authority:base64url-encode (ironclad:integer-to-octets n)))
(defparameter *release-jwk*
  (list (cons "kty" "RSA")
        (cons "n" (%b64uint (ironclad:rsa-key-modulus *rk-pub*)))
        (cons "e" (%b64uint (ironclad:rsa-key-exponent *rk-pub*)))))
(defparameter *rk-thumb* (orchestrator.jws-authority:jwk-thumbprint *rk-pub*))
(defparameter *release-jws*
  (getf (orchestrator.jws-authority:sign-jws *root-hex* *rk-priv*) :jws))

;; receipt-set (RFC-6962) — το release receipt στο index 2
(defparameter *receipt-ids* (list "rid:alpha" "rid:beta" "rid:release-target" "rid:delta"))
(defparameter *receipt-index* 2)
(defparameter *receipt-set-root* (orchestrator.merkle:merkle-root-of-strings *receipt-ids*))
(defparameter *graph-root* "sha256:graphrootDEADBEEF")

;; transparency log (RFC-6962) — το release-root leaf στο index 1, μέγεθος 4
(defparameter *tlog-leaves*
  (list "sha256:prev-root-0" *release-root* "sha256:root-2" "sha256:root-3"))
(defparameter *tlog-index* 1)
(defparameter *tlog-leaf-hashes*
  (mapcar #'orchestrator.merkle:hash-leaf-string *tlog-leaves*))
(defparameter *tlog-root* (orchestrator.merkle:merkle-tree-hash *tlog-leaf-hashes*))
(defparameter *tlog-size* 4)
;; consumer checkpoint: παλιό μέγεθος 2
(defparameter *cp-size* 2)
(defparameter *cp-root*
  (orchestrator.merkle:merkle-tree-hash (subseq *tlog-leaf-hashes* 0 2)))
(defparameter *consistency-proof*
  (orchestrator.merkle:consistency-proof *tlog-leaf-hashes* *cp-size*))

(defparameter *verifier-hash* "sha256:temporal-verifier-abc")

(defun base-delegation (&key (seq 1) (not-before "20260101000000")
                             (not-after "20261231235959")
                             (delegate-thumb *rk-thumb*) (algorithm "RS256")
                             (owner-thumb *owner-thumb*) (signer *owner-sk*))
  (let ((stmt (make-delegation-statement
               :owner-root-thumbprint owner-thumb :delegate-algorithm algorithm
               :delegate-jwk-thumbprint delegate-thumb :scope "corpus/syntagma"
               :not-before not-before :not-after not-after :sequence seq)))
    (list :statement stmt
          :signature (owner-sign-statement signer +delegation-tag+ stmt))))

(defun revocation (&key (revokes-seq 1) (revoked-at "20260101000000")
                        (signer *owner-sk*) (owner-thumb *owner-thumb*))
  (let ((stmt (make-revocation-statement
               :owner-root-thumbprint owner-thumb :revokes-sequence revokes-seq
               :revokes-delegate-thumbprint *rk-thumb* :revoked-at revoked-at
               :reason "test")))
    (list :statement stmt
          :signature (owner-sign-statement signer +revocation-tag+ stmt))))

(defun base-bundle (&rest overrides)
  (let ((b (list
            :release-root *release-root*
            :release-jwk *release-jwk*
            :release-jws *release-jws*
            :owner-root-jwk *owner-jwk*
            :census (list :graph-root *graph-root*
                          :receipt-set-root *receipt-set-root*
                          :receipt-ids *receipt-ids*)
            :cut (list :graph-root *graph-root* :journal-seq 42 :known-at "2026-07-10T00:00:00Z")
            :receipt (list :receipt-id (nth *receipt-index* *receipt-ids*)
                           :index *receipt-index*)
            :content (list :text-sha256 "sha256:text-1" :version-hash "sha256:ver-1")
            :tra (list :committed-content
                       (list :text-sha256 "sha256:text-1" :version-hash "sha256:ver-1"))
            :tlog (list :tree-size *tlog-size* :root *tlog-root*
                        :inclusion-path (orchestrator.merkle:inclusion-path
                                         *tlog-leaf-hashes* *tlog-index*)
                        :consistency-proof *consistency-proof*)
            :tsr-bytes *tsr*
            :verifier-set (list *verifier-hash* "sha256:other-verifier")
            :delegation (base-delegation)
            :revocations '())))
    ;; overrides: εναλλαγή top-level plist κλειδιών
    (loop for (k v) on overrides by #'cddr do (setf (getf b k) v))
    b))

(defparameter *policy*
  (list :required-tier "owner-pinned-authenticated"
        :allowed-delegate-algorithms '("RS256")
        :temporal-verifier-hash *verifier-hash*))

(defun verdict (&rest bundle-overrides)
  (verify-authority-proof-bundle
   (apply #'base-bundle bundle-overrides)
   :trusted-owner-root-jwk *owner-jwk*
   :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
   :policy *policy*))

(defun failed-p (v name) (member name (apb-reasons v)))

;;; ============================================================================
;;; [1] ΘΕΤΙΚΟ: πλήρες γνήσιο bundle ⇒ owner-pinned-authenticated
;;; ============================================================================
(format t "~%== [1] ΘΕΤΙΚΟ: πλήρης αλυσίδα ⇒ owner-pinned-authenticated ==~%")
(let ((v (verdict)))
  (ck "awarded = owner-pinned-authenticated"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated"))
  (ck "satisfies-policy" (apb-satisfies-policy-p v))
  (ck "reasons ΚΕΝΑ" (null (apb-reasons v)))
  (ck "delegation-state = :active" (eq (apb-delegation-state v) :active))
  (ck "genTime εξήχθη από γνήσιο TSR" (stringp (apb-gen-time v)))
  ;; ΟΧΙ ταυτολογία: κάθε ομάδα κατηγορημάτων ΟΝΤΩΣ αποτιμήθηκε
  (ck "RC κατηγορήματα παρόντα"
      (some (lambda (p) (search "RC/" (string (car p)))) (apb-predicates v)))
  (ck "OWN κατηγορήματα παρόντα"
      (some (lambda (p) (search "OWN/" (string (car p)))) (apb-predicates v))))

;;; ============================================================================
;;; [2] HERMETIC PIN: το bundle ΔΕΝ αυτο-εξουσιοδοτείται
;;; ============================================================================
(format t "~%== [2] Hermetic pin — trusted root ΕΞΩΘΕΝ ==~%")
;; (α) λάθος thumbprint pin ⇒ όχι owner tier (αλλά RC ισχύει)
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-thumbprint "WRONGTHUMB"
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy *policy*)))
  (ck "λάθος pin ⇒ ΟΧΙ owner (cap σε internally-release-consistent)"
      (equal (apb-awarded-tier v) "internally-release-consistent"))
  (ck "λάθος pin ⇒ pin κατηγόρημα απέτυχε"
      (failed-p v :own/pin-authenticates-owner-key))
  (ck "λάθος pin ⇒ ΔΕΝ ικανοποιεί owner-pinned policy"
      (not (apb-satisfies-policy-p v))))
;; (β) κανένα pin ⇒ όχι owner tier
(let ((v (verify-authority-proof-bundle
          (base-bundle)
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy *policy*)))
  (ck "χωρίς pin ⇒ cap σε internally-release-consistent"
      (equal (apb-awarded-tier v) "internally-release-consistent")))
;; (γ) thumbprint-only pin ΑΥΘΕΝΤΙΚΟΠΟΙΕΙ το bundle owner JWK (RFC 7638)
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-thumbprint *owner-thumb*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy *policy*)))
  (ck "thumbprint-only pin ⇒ owner-pinned (bootstrap μέσω thumbprint)"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))
;; (δ) thumbprint pin σε bundle με ΞΕΝΟ owner JWK ⇒ απόρριψη
(let ((v (verify-authority-proof-bundle
          (base-bundle :owner-root-jwk *foreign-jwk*)
          :trusted-owner-thumbprint *owner-thumb*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy *policy*)))
  (ck "ξένο owner JWK vs pinned thumbprint ⇒ ΟΧΙ owner"
      (failed-p v :own/pin-authenticates-owner-key)))

;;; ============================================================================
;;; [3] ΑΡΝΗΤΙΚΟΙ ΜΑΡΤΥΡΕΣ owner-tier (delegation/revocation)
;;; ============================================================================
(format t "~%== [3] Owner-tier αρνητικοί μάρτυρες ==~%")
;; 3.1 νοθευμένη υπογραφή delegation
(let* ((d (base-delegation))
       (badsig (let ((s (copy-seq (getf d :signature))))
                 (setf (char s 3) (if (char= (char s 3) #\A) #\B #\A)) s))
       (v (verdict :delegation (list :statement (getf d :statement) :signature badsig))))
  (ck "νοθευμένη υπογραφή delegation ⇒ owner-signs FAIL"
      (failed-p v :own/owner-signs-delegation))
  (ck "  ⇒ cap σε internally-release-consistent"
      (equal (apb-awarded-tier v) "internally-release-consistent")))
;; 3.2 delegation ΛΗΓΜΕΝΗ στο genTime
(let ((v (verdict :delegation (base-delegation :not-after "20260101000000"))))
  (ck "ληγμένη delegation ⇒ validity FAIL" (failed-p v :own/delegation-valid-at-gentime))
  (ck "  ⇒ state = :expired" (eq (apb-delegation-state v) :expired)))
;; 3.3 delegation ΟΧΙ-ΑΚΟΜΗ έγκυρη
(let ((v (verdict :delegation (base-delegation :not-before "20270101000000"))))
  (ck "μελλοντική delegation ⇒ validity FAIL" (failed-p v :own/delegation-valid-at-gentime))
  (ck "  ⇒ state = :not-yet" (eq (apb-delegation-state v) :not-yet)))
;; 3.4 ΑΝΑΚΛΗΘΕΙΣΑ (ίδια seq) πριν το genTime
(let ((v (verdict :revocations (list (revocation :revokes-seq 1
                                                 :revoked-at "20260101000000")))))
  (ck "ανάκληση ίδιας seq ⇒ not-revoked FAIL" (failed-p v :own/not-revoked))
  (ck "  ⇒ state = :revoked" (eq (apb-delegation-state v) :revoked)))
;; 3.5 ΝΕΟΤΕΡΗ ανάκληση (supersession, seq>seq) ⇒ ανακαλεί
(let ((v (verdict :revocations (list (revocation :revokes-seq 2
                                                 :revoked-at "20260101000000")))))
  (ck "νεότερη ανάκληση (seq 2 ≥ 1) ⇒ not-revoked FAIL" (failed-p v :own/not-revoked)))
;; 3.6 ανάκληση ΜΕΤΑ το genTime ⇒ ΔΕΝ επηρεάζει (χρονικά ορθό)
(let ((v (verdict :revocations (list (revocation :revokes-seq 1
                                                 :revoked-at "20991231000000")))))
  (ck "ανάκληση ΜΕΤΑ το genTime ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))
;; 3.7 ανάκληση με ΞΕΝΗ υπογραφή ⇒ ΑΓΝΟΕΙΤΑΙ (μόνο owner ανακαλεί)
(let ((v (verdict :revocations (list (revocation :revokes-seq 1
                                                 :revoked-at "20260101000000"
                                                 :signer *foreign-sk*)))))
  (ck "ανάκληση με ξένη υπογραφή ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ (μη έγκυρη ανάκληση)"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))
;; 3.8 delegate thumbprint ΔΕΝ δένει το release key
(let ((v (verdict :delegation (base-delegation :delegate-thumb "WRONGDELEGATE"))))
  (ck "delegate thumbprint mismatch ⇒ delegate-binds FAIL"
      (failed-p v :own/delegate-binds-release-key)))
;; 3.9 algorithm εκτός policy
(let ((v (verdict :delegation (base-delegation :algorithm "ES256"))))
  (ck "algorithm ES256 εκτός policy ⇒ delegate-binds FAIL"
      (failed-p v :own/delegate-binds-release-key)))
;; 3.10 delegation owner_thumbprint ≠ pinned owner
(let ((v (verdict :delegation (base-delegation :owner-thumb "OTHEROWNER"))))
  (ck "delegation δηλώνει ΑΛΛΟΝ owner ⇒ owner-matches-pin FAIL"
      (failed-p v :own/delegation-owner-matches-pin)))

;;; ============================================================================
;;; [4] ΑΡΝΗΤΙΚΟΙ ΜΑΡΤΥΡΕΣ release-consistency (RC)
;;; ============================================================================
(format t "~%== [4] Release-consistency αρνητικοί μάρτυρες ==~%")
;; 4.1 νοθευμένο release JWS
(let* ((j (copy-seq *release-jws*))
       (_ (setf (char j 5) (if (char= (char j 5) #\A) #\B #\A)))
       (v (verdict :release-jws j)))
  (declare (ignore _))
  (ck "νοθευμένο release JWS ⇒ release-jws FAIL" (failed-p v :rc/release-jws))
  (ck "  ⇒ provisional-unanchored" (equal (apb-awarded-tier v) "provisional-unanchored")))
;; 4.2 census graph_root ≠ cut
(let ((v (verdict :cut (list :graph-root "sha256:DIFFERENT" :journal-seq 42
                             :known-at "2026-07-10T00:00:00Z"))))
  (ck "census graph_root ≠ cut ⇒ census-binds-cut FAIL"
      (failed-p v :rc/census-binds-cut)))
;; 4.3 receipt-set root νοθευμένο
(let ((v (verdict :census (list :graph-root *graph-root*
                                :receipt-set-root "sha256:FORGEDSETROOT"
                                :receipt-ids *receipt-ids*))))
  (ck "receipt-set-root ≠ MTH(ids) ⇒ receipt-set-root FAIL"
      (failed-p v :rc/receipt-set-root)))
;; 4.4 receipt membership: λάθος index
(let ((v (verdict :receipt (list :receipt-id (nth *receipt-index* *receipt-ids*)
                                 :index 0))))
  (ck "receipt λάθος index ⇒ receipt-membership FAIL"
      (failed-p v :rc/receipt-membership)))
;; 4.5 content commitment mismatch
(let ((v (verdict :content (list :text-sha256 "sha256:TAMPERED" :version-hash "sha256:ver-1"))))
  (ck "content text-sha256 ≠ TRA ⇒ content-commitment FAIL"
      (failed-p v :rc/content-commitment)))
;; 4.6 tlog inclusion νοθευμένο root
(let ((v (verdict :tlog (list :tree-size *tlog-size* :root "forged-tlog-root"
                              :inclusion-path (orchestrator.merkle:inclusion-path
                                               *tlog-leaf-hashes* *tlog-index*)
                              :consistency-proof *consistency-proof*))))
  (ck "tlog root νοθευμένο ⇒ tlog-inclusion FAIL" (failed-p v :rc/tlog-inclusion)))
;; 4.7 TSR ακρωτηριασμένο
(let ((v (verdict :tsr-bytes (subseq *tsr* 0 (floor (length *tsr*) 2)))))
  (ck "ακρωτηριασμένο TSR ⇒ tsr FAIL" (failed-p v :rc/tsr)))
;; 4.8 TSR νοθευμένη υπογραφή
(let* ((t2 (copy-seq *tsr*))
       (_ (setf (aref t2 (- (length t2) 8)) (logxor (aref t2 (- (length t2) 8)) 1)))
       (v (verdict :tsr-bytes t2)))
  (declare (ignore _))
  (ck "TSR flipped signature byte ⇒ tsr FAIL" (failed-p v :rc/tsr)))
;; 4.9 verifier-set membership: ο απαιτούμενος verifier ΑΠΩΝ
(let ((v (verdict :verifier-set (list "sha256:only-other"))))
  (ck "temporal verifier ΑΠΩΝ από verifier-set ⇒ verifier-set FAIL"
      (failed-p v :rc/verifier-set)))

;;; ============================================================================
;;; [5] ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ consistency (fork detection)
;;; ============================================================================
(format t "~%== [5] Transparency consistency (fork) ==~%")
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk*
          :consumer-checkpoint (list :tree-size *cp-size* :root "forged-old-root")
          :policy *policy*)))
  (ck "λάθος consumer old-root ⇒ consistency FAIL"
      (failed-p v :cons/tlog-consistency))
  (ck "  ⇒ cap σε provisional (RC ομάδα ολοκληρωμένη αλλά CONS απέτυχε)"
      (equal (apb-awarded-tier v) "provisional-unanchored")))

;;; ============================================================================
;;; [6] ΒΑΘΜΙΔΑ independently-witnessed: ΠΟΤΕ χωρίς γνήσιο μάρτυρα (Δ4)
;;; ============================================================================
(format t "~%== [6] independently-witnessed ΠΟΤΕ χωρίς μάρτυρα ==~%")
(let ((v (verify-authority-proof-bundle
          (base-bundle)
          :trusted-owner-root-jwk *owner-jwk*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy (list :required-tier "owner-pinned-authenticated"
                        :allowed-delegate-algorithms '("RS256")
                        :temporal-verifier-hash *verifier-hash*
                        :require-witness t))))
  (ck "require-witness αλλά κανένας γνήσιος ⇒ ΟΧΙ independently-witnessed"
      (not (equal (apb-awarded-tier v) "independently-witnessed")))
  (ck "  ⇒ witness κατηγόρημα απέτυχε" (failed-p v :wit/third-party-checkpoint)))

;;; ============================================================================
;;; [7] tier>= μονοτονία (κλειστή taxonomy)
;;; ============================================================================
(format t "~%== [7] tier ordering ==~%")
(ck "owner ≥ internally" (tier>= "owner-pinned-authenticated" "internally-release-consistent"))
(ck "internally ≥ provisional" (tier>= "internally-release-consistent" "provisional-unanchored"))
(ck "provisional ⊁ owner" (not (tier>= "provisional-unanchored" "owner-pinned-authenticated")))

;;; ── ΣΥΝΟΨΗ ──
(format t "~%======================================================~%")
(format t "authority-proof-bundle: ~D passed, ~D failed~%" *p* *f*)
(when (plusp *f*)
  (format t "ΑΠΟΤΥΧΙΑ — fail-closed παραβιάστηκε~%")
  (sb-ext:exit :code 1))
(format t "ΟΛΑ ΠΡΑΣΙΝΑ — hermetic fail-closed επαληθευτής κλειδωμένος~%")
