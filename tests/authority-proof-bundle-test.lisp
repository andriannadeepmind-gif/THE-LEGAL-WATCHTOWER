;;;; tests/authority-proof-bundle-test.lisp
;;;; ============================================================================
;;;; [0088 Φ7-HARDENING #4] Regression lock: verify-authority-proof-bundle
;;;; ============================================================================
;;;; Ο ανεξάρτητος, hermetic, fail-closed επαληθευτής αλυσίδας εξουσίας.
;;;; ΘΕΤΙΚΟ: πλήρες bundle με ΓΝΗΣΙΑ κρυπτογραφία — Ed25519 owner root, RSA
;;;;   release key υπογράφει ΚΑΝΟΝΙΚΟ release-statement (δένει census/receipt-set/
;;;;   content/cut/verifier-set στον anchored root), ΓΝΗΣΙΟ RFC-3161 TSR Sectigo
;;;;   chained σε PINNED CA, RFC-6962 receipt-set + tlog ⇒ owner-pinned, :active.
;;;; ΑΡΝΗΤΙΚΑ (fail-closed μάρτυρες, ΜΕΤΑ από 2 αντιπαλικούς κριτές):
;;;;   • provenance C1/C2: swap census υπό fixed γνήσιο JWS ⇒ release-jws FAIL·
;;;;   • crypto C1: unpinned/wrong-CA TSR ⇒ tsr FAIL (ο genTime δεν αυθεντικοποιείται)·
;;;;   • crypto S1: known-revocation του καταναλωτή ⇒ not-revoked FAIL (θάνατος
;;;;     suppression-by-omission)· crypto S2: ISO-format bounds· crypto M3:
;;;;     ανάκληση άλλου delegate ΔΕΝ επηρεάζει· provenance S4: gentime-floor·
;;;;     provenance M2: require-checkpoint.
;;;; ΤΕST ROOT — NOT PRODUCTION (Δ5): όλα τα κλειδιά είναι εφήμερα δοκιμαστικά.
;;;; ============================================================================

(in-package :orchestrator.apb)

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
(defparameter *sectigo-ca* (merge-pathnames "sectigo-issuer-ca.pem" *fix*))
(defparameter *freetsa-ca* (merge-pathnames "freetsa-issuer-ca.pem" *fix*))

(defparameter *release-root*
  (string-trim '(#\Newline #\Space)
               (alexandria:read-file-into-string (merge-pathnames "message.txt" *fix*))))
(defparameter *tsr* (fx "sectigo-rsa.tsr"))

(multiple-value-bind (osk opk) (ironclad:generate-key-pair :ed25519)
  (defparameter *owner-sk* osk) (defparameter *owner-pk* opk))
(defparameter *owner-jwk* (ed25519-public-to-jwk *owner-pk*))
(defparameter *owner-thumb* (ed25519-jwk-thumbprint *owner-pk*))

(multiple-value-bind (fsk fpk) (ironclad:generate-key-pair :ed25519)
  (defparameter *foreign-sk* fsk) (defparameter *foreign-jwk* (ed25519-public-to-jwk fpk)))

(defparameter *rsa* (orchestrator.jws-authority:generate-rsa-keypair :bits 2048))
(defparameter *rk-pub* (getf *rsa* :public-key))
(defparameter *rk-priv* (getf *rsa* :private-key))
(defun %b64uint (n) (orchestrator.jws-authority:base64url-encode (ironclad:integer-to-octets n)))
(defparameter *release-jwk*
  (list (cons "kty" "RSA")
        (cons "n" (%b64uint (ironclad:rsa-key-modulus *rk-pub*)))
        (cons "e" (%b64uint (ironclad:rsa-key-exponent *rk-pub*)))))
(defparameter *rk-thumb* (orchestrator.jws-authority:jwk-thumbprint *rk-pub*))

(defparameter *receipt-ids* (list "rid:alpha" "rid:beta" "rid:release-target" "rid:delta"))
(defparameter *receipt-index* 2)
(defparameter *receipt-set-root* (orchestrator.merkle:merkle-root-of-strings *receipt-ids*))
(defparameter *graph-root* "sha256:graphrootDEADBEEF")
(defparameter *content* (list :text-sha256 "sha256:text-1" :version-hash "sha256:ver-1"))
(defparameter *verifier-hash* "sha256:temporal-verifier-abc")
(defparameter *verifier-set* (list *verifier-hash* "sha256:other-verifier"))
(defparameter *cut* (list :graph-root *graph-root* :journal-seq 42 :known-at "2026-07-10T00:00:00Z"))

;; transparency log (RFC-6962) — το release-root leaf στο index 1, μέγεθος 4
(defparameter *tlog-leaves*
  (list "sha256:prev-root-0" *release-root* "sha256:root-2" "sha256:root-3"))
(defparameter *tlog-index* 1)
(defparameter *tlog-leaf-hashes* (mapcar #'orchestrator.merkle:hash-leaf-string *tlog-leaves*))
(defparameter *tlog-root* (orchestrator.merkle:merkle-tree-hash *tlog-leaf-hashes*))
(defparameter *tlog-size* 4)
(defparameter *cp-size* 2)
(defparameter *cp-root* (orchestrator.merkle:merkle-tree-hash (subseq *tlog-leaf-hashes* 0 2)))
(defparameter *consistency-proof* (orchestrator.merkle:consistency-proof *tlog-leaf-hashes* *cp-size*))

;; Ο RELEASE-STATEMENT (δεσμεύει census/receipt-set/content/cut/verifier-set/tlog)
(defun sign-release-statement (&key (release-root *release-root*) (graph-root *graph-root*)
                                    (receipt-set-root *receipt-set-root*) (content *content*)
                                    (cut *cut*) (verifier-set *verifier-set*)
                                    (tlog-root *tlog-root*) (tlog-tree-size *tlog-size*)
                                    (tlog-leaf-index *tlog-index*))
  (getf (orchestrator.jws-authority:sign-jws
         (%canonical-release-statement
          :release-root release-root :graph-root graph-root
          :receipt-set-root receipt-set-root
          :content-text-sha256 (getf content :text-sha256)
          :content-version-hash (getf content :version-hash)
          :cut-graph-root (getf cut :graph-root) :cut-journal-seq (getf cut :journal-seq)
          :cut-known-at (getf cut :known-at) :verifier-set verifier-set
          :tlog-root tlog-root :tlog-tree-size tlog-tree-size :tlog-leaf-index tlog-leaf-index)
         *rk-priv*)
        :jws))

(defun base-delegation (&key (seq 1) (not-before "20260101000000") (not-after "20261231235959")
                             (delegate-thumb *rk-thumb*) (algorithm "RS256")
                             (owner-thumb *owner-thumb*) (signer *owner-sk*))
  (let ((stmt (make-delegation-statement
               :owner-root-thumbprint owner-thumb :delegate-algorithm algorithm
               :delegate-jwk-thumbprint delegate-thumb :scope "corpus/syntagma"
               :not-before not-before :not-after not-after :sequence seq)))
    (list :statement stmt :signature (owner-sign-statement signer +delegation-tag+ stmt))))

(defun revocation (&key (revokes-seq 1) (revoked-at "20260101000000") (signer *owner-sk*)
                        (delegate-thumb *rk-thumb*) (owner-thumb *owner-thumb*))
  (let ((stmt (make-revocation-statement
               :owner-root-thumbprint owner-thumb :revokes-sequence revokes-seq
               :revokes-delegate-thumbprint delegate-thumb :revoked-at revoked-at :reason "test")))
    (list :statement stmt :signature (owner-sign-statement signer +revocation-tag+ stmt))))

(defun base-bundle (&rest overrides)
  "Χτίζει bundle· το release-jws ΞΑΝΑΫΠΟΛΟΓΙΖΕΤΑΙ πάνω στα ΤΕΛΙΚΑ statement-bound
   πεδία (census/cut/content/verifier-set) ⇒ isolation μετάλλαξη ⇒ ΕΝΑ κατηγόρημα.
   Εξαίρεση: αν δοθεί ρητά :release-jws στα overrides, μένει ως έχει (JWS-tamper/C1)."
  (let* ((census (or (getf overrides :census)
                     (list :graph-root *graph-root* :receipt-set-root *receipt-set-root*
                           :receipt-ids *receipt-ids*)))
         (cut (or (getf overrides :cut) *cut*))
         (content (or (getf overrides :content) *content*))
         (vset (if (member :verifier-set overrides) (getf overrides :verifier-set) *verifier-set*))
         (tlog (or (getf overrides :tlog)
                   (list :tree-size *tlog-size* :root *tlog-root* :leaf-index *tlog-index*
                         :inclusion-path (orchestrator.merkle:inclusion-path
                                          *tlog-leaf-hashes* *tlog-index*)
                         :consistency-proof *consistency-proof*)))
         (jws (or (getf overrides :release-jws)
                  (sign-release-statement :graph-root (getf census :graph-root)
                                          :receipt-set-root (getf census :receipt-set-root)
                                          :content content :cut cut :verifier-set vset
                                          :tlog-root (getf tlog :root)
                                          :tlog-tree-size (getf tlog :tree-size)
                                          :tlog-leaf-index (getf tlog :leaf-index))))
         (b (list :release-root *release-root* :release-jwk *release-jwk* :release-jws jws
                  :owner-root-jwk *owner-jwk* :census census :cut cut :content content
                  :receipt (list :receipt-id (nth *receipt-index* *receipt-ids*)
                                 :index *receipt-index*)
                  :tra (list :committed-content
                             (list :text-sha256 (getf content :text-sha256)
                                   :version-hash (getf content :version-hash)))
                  :tlog tlog
                  :tsr-bytes *tsr* :verifier-set vset :delegation (base-delegation)
                  :revocations '())))
    (loop for (k v) on overrides by #'cddr do (setf (getf b k) v))
    b))

(defparameter *policy*
  (list :required-tier "owner-pinned-authenticated"
        :allowed-delegate-algorithms '("RS256") :temporal-verifier-hash *verifier-hash*))

(defun verdict (&rest bundle-overrides)
  (verify-authority-proof-bundle
   (apply #'base-bundle bundle-overrides)
   :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
   :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*))

(defun failed-p (v name) (member name (apb-reasons v)))

;;; ── [1] ΘΕΤΙΚΟ ──
(format t "~%== [1] ΘΕΤΙΚΟ: πλήρης αλυσίδα ⇒ owner-pinned-authenticated ==~%")
(let ((v (verdict)))
  (ck "awarded = owner-pinned-authenticated" (equal (apb-awarded-tier v) "owner-pinned-authenticated"))
  (ck "satisfies-policy" (apb-satisfies-policy-p v))
  (ck "reasons ΚΕΝΑ (whole-chain green baseline)" (null (apb-reasons v)))
  (ck "delegation-state = :active" (eq (apb-delegation-state v) :active))
  (ck "genTime από PINNED TSR" (stringp (apb-gen-time v))))

;;; ── [2] Hermetic pin ──
(format t "~%== [2] Hermetic pin — trusted root ΕΞΩΘΕΝ ==~%")
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-thumbprint "WRONGTHUMB" :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (ck "λάθος pin ⇒ cap internally-release-consistent"
      (equal (apb-awarded-tier v) "internally-release-consistent"))
  (ck "λάθος pin ⇒ pin κατηγόρημα απέτυχε" (failed-p v :own/pin-authenticates-owner-key))
  (ck "λάθος pin ⇒ ΔΕΝ ικανοποιεί owner policy" (not (apb-satisfies-policy-p v))))
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-thumbprint *owner-thumb* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (ck "thumbprint-only pin ⇒ owner-pinned (RFC-7638 bootstrap)"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))
(let ((v (verify-authority-proof-bundle
          (base-bundle :owner-root-jwk *foreign-jwk*) :trusted-owner-thumbprint *owner-thumb*
          :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (ck "ξένο owner JWK vs pinned thumbprint ⇒ ΟΧΙ owner"
      (failed-p v :own/pin-authenticates-owner-key)))

;;; ── [3] Owner-tier αρνητικοί μάρτυρες ──
(format t "~%== [3] Owner-tier αρνητικοί μάρτυρες ==~%")
(let* ((d (base-delegation))
       (badsig (let ((s (copy-seq (getf d :signature))))
                 (setf (char s 3) (if (char= (char s 3) #\A) #\B #\A)) s))
       (v (verdict :delegation (list :statement (getf d :statement) :signature badsig))))
  (ck "νοθευμένη υπογραφή delegation ⇒ owner-signs FAIL" (failed-p v :own/owner-signs-delegation))
  (ck "  ⇒ cap internally-release-consistent" (equal (apb-awarded-tier v) "internally-release-consistent")))
(let ((v (verdict :delegation (base-delegation :not-after "20260101000000"))))
  (ck "ληγμένη delegation ⇒ validity FAIL" (failed-p v :own/delegation-valid-at-gentime))
  (ck "  ⇒ state = :expired" (eq (apb-delegation-state v) :expired)))
(let ((v (verdict :delegation (base-delegation :not-before "20270101000000"))))
  (ck "μελλοντική delegation ⇒ validity FAIL" (failed-p v :own/delegation-valid-at-gentime))
  (ck "  ⇒ state = :not-yet" (eq (apb-delegation-state v) :not-yet)))
;; [crypto-critic S2] ISO-format bounds ΚΑΝΟΝΙΚΟΠΟΙΟΥΝΤΑΙ (dual-format)
(let ((v (verdict :delegation (base-delegation :not-before "2026-01-01T00:00:00Z"
                                               :not-after "2026-12-31T23:59:59Z"))))
  (ck "ISO-format bounds ⇒ ΣΩΣΤΑ :active (dual-format normalization)"
      (and (eq (apb-delegation-state v) :active)
           (equal (apb-awarded-tier v) "owner-pinned-authenticated"))))
(let ((v (verdict :revocations (list (revocation :revokes-seq 1 :revoked-at "20260101000000")))))
  (ck "ανάκληση ίδιας seq ⇒ not-revoked FAIL" (failed-p v :own/not-revoked))
  (ck "  ⇒ state = :revoked" (eq (apb-delegation-state v) :revoked)))
(let ((v (verdict :revocations (list (revocation :revokes-seq 2 :revoked-at "20260101000000")))))
  (ck "νεότερη ανάκληση (seq 2 ≥ 1) ⇒ not-revoked FAIL" (failed-p v :own/not-revoked)))
(let ((v (verdict :revocations (list (revocation :revokes-seq 1 :revoked-at "20991231000000")))))
  (ck "ανάκληση ΜΕΤΑ το genTime ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))
(let ((v (verdict :revocations (list (revocation :revokes-seq 1 :revoked-at "20260101000000"
                                                 :signer *foreign-sk*)))))
  (ck "ανάκληση με ξένη υπογραφή ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))
;; [crypto-critic M3] ανάκληση ΑΛΛΟΥ delegate (seq≥) ΔΕΝ over-revoke
(let ((v (verdict :revocations (list (revocation :revokes-seq 5
                                                 :delegate-thumb "OTHER-DELEGATE"
                                                 :revoked-at "20260101000000")))))
  (ck "ανάκληση ΑΛΛΟΥ delegate ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ (M3)"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))
;; [crypto-critic S1] known-revocation του καταναλωτή, ΑΠΟΝ από το bundle
(let ((v (verify-authority-proof-bundle
          (base-bundle)                  ; bundle ΧΩΡΙΣ revocation
          :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :known-revocations (list (revocation :revokes-seq 1 :revoked-at "20260101000000"))
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (ck "known-revocation (suppression-by-omission) ⇒ not-revoked FAIL (S1)"
      (failed-p v :own/not-revoked)))
(let ((v (verdict :delegation (base-delegation :delegate-thumb "WRONGDELEGATE"))))
  (ck "delegate thumbprint mismatch ⇒ delegate-binds FAIL" (failed-p v :own/delegate-binds-release-key)))
(let ((v (verdict :delegation (base-delegation :algorithm "ES256"))))
  (ck "algorithm ES256 εκτός policy ⇒ delegate-binds FAIL" (failed-p v :own/delegate-binds-release-key)))
(let ((v (verdict :delegation (base-delegation :owner-thumb "OTHEROWNER"))))
  (ck "delegation δηλώνει ΑΛΛΟΝ owner ⇒ owner-matches-pin FAIL"
      (failed-p v :own/delegation-owner-matches-pin)))

;;; ── [4] Release-consistency + COMMITMENT-EDGE μάρτυρες ──
(format t "~%== [4] Release-consistency + commitment-edge ==~%")
;; 4.0 [provenance C1/C2] SWAP census υπό fixed γνήσιο JWS ⇒ release-jws FAIL
(let* ((b (base-bundle))
       (_ (setf (getf b :census)
                (list :graph-root "sha256:FORGED-GRAPH"
                      :receipt-set-root (orchestrator.merkle:merkle-root-of-strings
                                         (list "rid:forged-authority"))
                      :receipt-ids (list "rid:forged-authority"))))
       (v (verify-authority-proof-bundle
           b :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
           :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (declare (ignore _))
  (ck "swap census υπό fixed JWS ⇒ release-jws FAIL (commitment edge, C1)"
      (failed-p v :rc/release-jws))
  (ck "  ⇒ provisional-unanchored" (equal (apb-awarded-tier v) "provisional-unanchored")))
;; 4.0β [provenance S2] SWAP verifier-set υπό fixed JWS ⇒ release-jws FAIL
(let* ((b (base-bundle)) (_ (setf (getf b :verifier-set) (list *verifier-hash* "sha256:INJECTED")))
       (v (verify-authority-proof-bundle
           b :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
           :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (declare (ignore _))
  (ck "swap verifier-set υπό fixed JWS ⇒ release-jws FAIL (S2 bound)" (failed-p v :rc/release-jws)))
;; 4.1 νοθευμένο release JWS
(let* ((j (copy-seq (sign-release-statement)))
       (_ (setf (char j 5) (if (char= (char j 5) #\A) #\B #\A)))
       (v (verdict :release-jws j)))
  (declare (ignore _))
  (ck "νοθευμένο release JWS ⇒ release-jws FAIL" (failed-p v :rc/release-jws))
  (ck "  ⇒ provisional-unanchored" (equal (apb-awarded-tier v) "provisional-unanchored")))
;; 4.2 census graph_root ≠ cut (JWS ΞΑΝΑΫΠΟΛΟΓΙΖΕΤΑΙ ⇒ isolation)
(let ((v (verdict :cut (list :graph-root "sha256:DIFFERENT" :journal-seq 42
                             :known-at "2026-07-10T00:00:00Z"))))
  (ck "census graph_root ≠ cut ⇒ census-binds-cut FAIL" (failed-p v :rc/census-binds-cut)))
;; 4.3 receipt-set root ≠ MTH(ids) (isolation)
(let ((v (verdict :census (list :graph-root *graph-root* :receipt-set-root "sha256:FORGEDSETROOT"
                                :receipt-ids *receipt-ids*))))
  (ck "receipt-set-root ≠ MTH(ids) ⇒ receipt-set-root FAIL" (failed-p v :rc/receipt-set-root)))
;; 4.4 receipt membership λάθος index
(let ((v (verdict :receipt (list :receipt-id (nth *receipt-index* *receipt-ids*) :index 0))))
  (ck "receipt λάθος index ⇒ receipt-membership FAIL" (failed-p v :rc/receipt-membership)))
;; 4.5 content ↔ TRA απόκλιση (isolation: content bound σε JWS, TRA χαλασμένο)
(let* ((b (base-bundle))
       (_ (setf (getf b :tra) (list :committed-content
                                    (list :text-sha256 "sha256:TAMPERED" :version-hash "sha256:ver-1"))))
       (v (verify-authority-proof-bundle
           b :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
           :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (declare (ignore _))
  (ck "TRA content ≠ release content ⇒ content-commitment FAIL" (failed-p v :rc/content-commitment)))
;; 4.6 tlog inclusion νοθευμένο root
(let ((v (verdict :tlog (list :tree-size *tlog-size* :root "forged-tlog-root"
                              :inclusion-path (orchestrator.merkle:inclusion-path
                                               *tlog-leaf-hashes* *tlog-index*)
                              :consistency-proof *consistency-proof*))))
  (ck "tlog root νοθευμένο ⇒ tlog-inclusion FAIL" (failed-p v :rc/tlog-inclusion)))
;; 4.7/4.8 TSR: pinned CA discipline (crypto C1)
(let ((v (verdict :tsr-bytes (subseq *tsr* 0 (floor (length *tsr*) 2)))))
  (ck "ακρωτηριασμένο TSR ⇒ tsr FAIL" (failed-p v :rc/tsr)))
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk*  ; ΧΩΡΙΣ trusted-tsa-ca-path
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (ck "ΑΠΩΝ trusted-tsa-ca-path ⇒ tsr FAIL (unpinned genTime ΔΕΝ αυθεντικοποιείται)"
      (failed-p v :rc/tsr)))
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *freetsa-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*) :policy *policy*)))
  (ck "ΛΑΘΟΣ TSA CA (freetsa για sectigo TSR) ⇒ tsr FAIL (όχι :pinned)"
      (failed-p v :rc/tsr)))
;; 4.9 verifier-set membership: ο απαιτούμενος ΑΠΩΝ (isolation)
(let ((v (verdict :verifier-set (list "sha256:only-other"))))
  (ck "temporal verifier ΑΠΩΝ από verifier-set ⇒ verifier-set FAIL" (failed-p v :rc/verifier-set)))

;;; ── [5] Consistency (fork) + require-checkpoint ──
(format t "~%== [5] Transparency consistency + require-checkpoint ==~%")
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root "forged-old-root") :policy *policy*)))
  (ck "λάθος consumer old-root ⇒ consistency FAIL" (failed-p v :cons/tlog-consistency))
  (ck "  ⇒ cap provisional" (equal (apb-awarded-tier v) "provisional-unanchored")))
;; [provenance M2] require-checkpoint χωρίς checkpoint ⇒ ονομαστική αποτυχία
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :policy (list* :require-checkpoint t *policy*))))
  (ck "require-checkpoint χωρίς checkpoint ⇒ checkpoint-required FAIL (M2)"
      (failed-p v :cons/checkpoint-required)))

;;; ── [6] gentime-floor (provenance S4: temporal rollback) ──
(format t "~%== [6] gentime-floor — θάνατος temporal rollback ==~%")
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy (list* :gentime-floor "20270101000000" *policy*))))
  (ck "genTime < floor ⇒ validity FAIL (rollback)" (failed-p v :own/delegation-valid-at-gentime))
  (ck "  ⇒ state = :stale" (eq (apb-delegation-state v) :stale)))
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy (list* :gentime-floor "20260101000000" *policy*))))
  (ck "genTime ≥ floor ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))

;;; ── [7] independently-witnessed ΠΟΤΕ χωρίς μάρτυρα ──
(format t "~%== [7] independently-witnessed ΠΟΤΕ χωρίς μάρτυρα ==~%")
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy (list* :require-witness t *policy*))))
  (ck "require-witness χωρίς γνήσιο ⇒ ΟΧΙ independently-witnessed"
      (not (equal (apb-awarded-tier v) "independently-witnessed")))
  (ck "  ⇒ witness κατηγόρημα απέτυχε" (failed-p v :wit/third-party-checkpoint)))

;;; ── [8] tier ordering + canonical injectivity (crypto M1) ──
(format t "~%== [8] tier ordering + canonical injectivity ==~%")
(ck "owner ≥ internally" (tier>= "owner-pinned-authenticated" "internally-release-consistent"))
(ck "internally ≥ provisional" (tier>= "internally-release-consistent" "provisional-unanchored"))
(ck "provisional ⊁ owner" (not (tier>= "provisional-unanchored" "owner-pinned-authenticated")))
;; [crypto-critic M1] separator control byte σε value ⇒ ΣΦΑΛΜΑ (δομική ενριξιμότητα)
(ck "value με #x1f separator ⇒ ΣΦΑΛΜΑ (injectivity δομική)"
    (handler-case
        (progn (owner-sign-statement *owner-sk* +delegation-tag+
                                     (list (cons "k" (format nil "a~Cb" (code-char #x1f)))))
               nil)
      (error () t)))
;; [crypto-critic-2 F1] ΓΝΗΣΙΑ non-canonical x (low-bit variant του τελευταίου
;; sextet — ΔΙΑΦΟΡΕΤΙΚΟ string, ΙΔΙΑ 32 bytes) ⇒ ΙΔΙΟΣ thumbprint. Αν η
;; recanonicalization αφαιρεθεί, οι δύο thumbprints ΔΙΑΦΕΡΟΥΝ ⇒ το test κοκκινίζει.
(ck "thumbprint ανεξάρτητος non-canonical x (M2 recanonicalization, ΜΗ-vacuous)"
    (let* ((raw (ironclad:ed25519-key-y *owner-pk*))
           (canon (orchestrator.jws-authority:base64url-encode raw))
           (alpha "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
           (lastc (char canon (1- (length canon))))
           (variant (concatenate 'string (subseq canon 0 (1- (length canon)))
                                 (string (char alpha (mod (1+ (position lastc alpha)) 64))))))
      (and (not (string= canon variant))       ; ΟΝΤΩΣ διαφορετική κωδικοποίηση
           (equalp raw (orchestrator.jws-authority:base64url-decode variant)) ; ΙΔΙΑ bytes
           (equal (ed25519-jwk-thumbprint *owner-pk*)
                  (ed25519-jwk-thumbprint (list (cons "kty" "OKP") (cons "crv" "Ed25519")
                                                (cons "x" variant)))))))
;; [crypto-critic-2 F3] verifier-set token με comma ⇒ ΕΝΡΙΞΙΜΟ (length-prefixed):
;; {"a,b"} και {"a","b"} ΔΕΝ συμπίπτουν πλέον στην υπογραφή
(ck "verifier-set {\"a,b\"} ≠ {\"a\",\"b\"} στο signed statement (F3 injectivity)"
    (not (string= (%canonical-release-statement :verifier-set (list "a,b"))
                  (%canonical-release-statement :verifier-set (list "a" "b")))))

;;; ── [9] COMMITMENT-EDGE per-field witnesses (crypto-critic-2 F2 + C1) ──
;;; Κάθε statement-bound πεδίο μεταλλάσσεται ΜΟΝΟ του υπό fixed γνήσιο JWS ⇒
;;; rc/release-jws FAIL. Αποδεικνύει ότι ΚΑΘΕ πεδίο είναι ΟΝΤΩΣ στην υπογραφή.
(format t "~%== [9] commitment-edge per-field witnesses ==~%")
(macrolet ((fixed-jws-mutation (label setter)
             `(let* ((b (base-bundle)) (_ ,setter)
                     (v (verify-authority-proof-bundle
                         b :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
                         :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
                         :policy *policy*)))
                (declare (ignore _))
                (ck ,label (and (failed-p v :rc/release-jws)
                                (equal (apb-awarded-tier v) "provisional-unanchored"))))))
  (fixed-jws-mutation "swap content_text_sha256 υπό fixed JWS ⇒ release-jws FAIL"
                      (setf (getf b :content) (list :text-sha256 "sha256:FORGED" :version-hash "sha256:ver-1")))
  (fixed-jws-mutation "swap content_version_hash υπό fixed JWS ⇒ release-jws FAIL"
                      (setf (getf b :content) (list :text-sha256 "sha256:text-1" :version-hash "sha256:FORGED")))
  (fixed-jws-mutation "swap cut_journal_seq υπό fixed JWS ⇒ release-jws FAIL"
                      (setf (getf b :cut) (list :graph-root *graph-root* :journal-seq 99
                                                :known-at "2026-07-10T00:00:00Z")))
  (fixed-jws-mutation "swap cut_known_at υπό fixed JWS ⇒ release-jws FAIL"
                      (setf (getf b :cut) (list :graph-root *graph-root* :journal-seq 42
                                                :known-at "2099-01-01T00:00:00Z")))
  (fixed-jws-mutation "[C1] swap tlog_root υπό fixed JWS ⇒ release-jws FAIL (tlog δεσμευμένο)"
                      (setf (getf b :tlog) (list :tree-size *tlog-size* :root "sha256:FORGED-TLOG"
                                                 :leaf-index *tlog-index*
                                                 :inclusion-path (getf (getf b :tlog) :inclusion-path)
                                                 :consistency-proof *consistency-proof*)))
  (fixed-jws-mutation "[C1] swap tlog_leaf_index υπό fixed JWS ⇒ release-jws FAIL"
                      (setf (getf b :tlog) (list :tree-size *tlog-size* :root *tlog-root* :leaf-index 3
                                                 :inclusion-path (getf (getf b :tlog) :inclusion-path)
                                                 :consistency-proof *consistency-proof*))))

;;; ── [10] anti-rollback freshness + F4/F5/F6 fail-closed ──
(format t "~%== [10] anti-rollback + fail-closed normalization ==~%")
;; [S1] min-tlog-leaf-index: signed leaf-index (1) < floor (3) ⇒ freshness FAIL
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy (list* :min-tlog-leaf-index 3 *policy*))))
  (ck "leaf-index 1 < floor 3 ⇒ freshness FAIL (anti-rollback S1)" (failed-p v :cons/tlog-freshness)))
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy (list* :min-tlog-leaf-index 1 *policy*))))
  (ck "leaf-index 1 ≥ floor 1 ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ"
      (equal (apb-awarded-tier v) "owner-pinned-authenticated")))
;; [F4] κακοσχηματισμένο :gentime-floor ⇒ ΔΕΝ παρακάμπτεται σιωπηλά
(let ((v (verify-authority-proof-bundle
          (base-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint (list :tree-size *cp-size* :root *cp-root*)
          :policy (list* :gentime-floor "garbage" *policy*))))
  (ck "κακοσχηματισμένο gentime-floor ⇒ validity FAIL (F4, ΟΧΙ σιωπηλή παράκαμψη)"
      (and (failed-p v :own/delegation-valid-at-gentime)
           (eq (apb-delegation-state v) :floor-unparseable))))
;; [F5] owner-signed ΤΑΙΡΙΑΣΤΗ ανάκληση με κακοσχηματισμένο revoked_at ⇒ ΑΝΑΚΛΗΣΗ
(let ((v (verdict :revocations (list (revocation :revokes-seq 1 :revoked-at "garbage")))))
  (ck "ανάκληση με κακοσχηματισμένο revoked_at ⇒ not-revoked FAIL (F5 fail-closed)"
      (failed-p v :own/not-revoked)))
;; [F6] offset-bearing not_before ⇒ ΑΠΟΡΡΙΨΗ normalization ⇒ validity FAIL
(let ((v (verdict :delegation (base-delegation :not-before "2026-01-01T00:00:00+02:00"))))
  (ck "offset-bearing not_before ⇒ validity FAIL (F6 offset rejection)"
      (failed-p v :own/delegation-valid-at-gentime)))

(format t "~%======================================================~%")
(format t "authority-proof-bundle: ~D passed, ~D failed~%" *p* *f*)
(when (plusp *f*)
  (format t "ΑΠΟΤΥΧΙΑ — fail-closed παραβιάστηκε~%") (sb-ext:exit :code 1))
(format t "ΟΛΑ ΠΡΑΣΙΝΑ — hermetic fail-closed επαληθευτής κλειδωμένος (μετά 2 κριτών)~%")
