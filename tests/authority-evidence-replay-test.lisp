;;;; tests/authority-evidence-replay-test.lisp
;;;; ============================================================================
;;;; [0088 Φ7-HARDENING #4B] Regression lock: verify-authority-evidence-bundle
;;;; ============================================================================
;;;; Ο ΠΛΗΡΗΣ authority evidence replay verifier. ΠΡΑΓΜΑΤΙΚΟΣ γράφος χτίζεται
;;;; (submit-genesis! → journal), το receipt/TRA παράγονται από τις έδρες, το
;;;; bundle συναρμολογείται με ΓΝΗΣΙΑ κρυπτογραφία (#4A envelope: Ed25519 owner,
;;;; RSA release key, γνήσιο Sectigo TSR σε pinned CA) + signed authority-statement
;;;; που δεσμεύει το REPLAYED graph_root. Ο verifier ΑΝΑΚΑΤΑΣΚΕΥΑΖΕΙ τον γράφο
;;;; από τα journal bytes και ΞΑΝΑΤΡΕΧΕΙ verify-receipt-intrinsic + TRA recompute
;;;; — ΚΑΝΕΝΑ declared root.
;;;; ΑΡΝΗΤΙΚΟΙ ΜΑΡΤΥΡΕΣ (εντολή δημιουργού): journal byte tamper, prefix under/
;;;; overshoot, receipt-id mismatch, ξένο receipt περιεχόμενο, source byte tamper,
;;;; span εκτός artifact, extraction receipt substitution, TRA σωστό committed
;;;; αλλά λάθος outcome, scope mismatch, delegation rollback/equivocation,
;;;; unknown/missing schema key.  TEST ROOT — NOT PRODUCTION (Δ5).
;;;; ============================================================================

(in-package :orchestrator.apb-replay)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *fix*
  (merge-pathnames "fixtures/tsr/"
                   (make-pathname :directory (pathname-directory
                                              (or *load-truename* *load-pathname*)))))
(defparameter *sectigo-ca* (merge-pathnames "sectigo-issuer-ca.pem" *fix*))
(defparameter *release-root*
  (string-trim '(#\Newline #\Space)
               (alexandria:read-file-into-string (merge-pathnames "message.txt" *fix*))))
(defparameter *tsr* (alexandria:read-file-into-byte-vector
                     (merge-pathnames "sectigo-rsa.tsr" *fix*)))

;;; ── ΠΡΑΓΜΑΤΙΚΟΣ ΓΡΑΦΟΣ ────────────────────────────────────────────────────
(defparameter *corpus* "syntagma-test")
(defparameter *body* "gr/nomos/2099/test")
(defparameter *pid* "gr/nomos/2099/test:art_1")
(defparameter *tmp-graph-body* "apbtest-source-graph")

(defun build-real-graph ()
  "Χτίζει ΓΝΗΣΙΟ journal graph (2 genesis versions) σε temp body· επιστρέφει
   (values graph journal-bytes graph-path)."
  (let* ((g (vg:make-graph *tmp-graph-body*))
         (path (vg::vg-path g)))
    (when (probe-file path) (delete-file path))
    (setf g (vg:make-graph *tmp-graph-body*))
    (vg:submit-genesis! g (vg:make-version-spec :provision-id *pid*
                            :text "Άρθρο 1. Το πολίτευμα είναι δοκιμαστικό."
                            :heading "Δοκιμή" :valid-from "2020-01-01"
                            :assurance :extracted-verified)
                        :derivation "bootstrap:syntagma-test")
    (vg:submit-genesis! g (vg:make-version-spec :provision-id "gr/nomos/2099/test:art_2"
                            :text "Άρθρο 2. Δεύτερη διάταξη." :heading "Δεύτερο"
                            :valid-from "2020-01-01" :assurance :extracted-verified)
                        :derivation "bootstrap:syntagma-test")
    (values (vg:load-graph *tmp-graph-body*)
            (alexandria:read-file-into-string path :external-format :utf-8)
            path)))

(multiple-value-bind (g jbytes gpath) (build-real-graph)
  (defparameter *graph* g)
  (defparameter *journal-bytes* jbytes)
  (defparameter *graph-path* gpath))
(defparameter *graph-root* (vg:graph-chain-head *graph*))
(defparameter *graph-seq* (vg:graph-seq *graph*))
(defparameter *known-at* "2099-01-01T00:00:00Z")
(defparameter *valid-at* "2025-01-01")

;;; ── SOURCE ARTIFACT (ΠΡΑΓΜΑΤΙΚΑ bytes + digest) ──────────────────────────
(defparameter *source-str* "ΕΦΗΜΕΡΙΣ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ — Άρθρο 1 — official source bytes")
(defun sha256tag (str)
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string
           (ironclad:digest-sequence :sha256 (babel:string-to-octets str :encoding :utf-8)))))
(defparameter *source-digest* (sha256tag *source-str*))
(defparameter *extraction-digest* (sha256tag "extraction-receipt-v1"))
(defparameter *normalization-digest* (sha256tag "normalization-receipt-v1"))
(defparameter *provenance-root*
  (orchestrator.merkle:merkle-root-of-strings
   (list *source-digest* *extraction-digest* *normalization-digest*)))
(defparameter *src-artifact-alist*
  (list (cons "content_sha256" *source-digest*) (cons "source_digest" *source-digest*)))

;;; ── ΠΡΑΓΜΑΤΙΚΟ RECEIPT (από την έδρα) ────────────────────────────────────
(defparameter *version*
  (vg:version-at *graph* *pid* :valid-at *valid-at* :known-at *known-at*))
(defparameter *receipt*
  (orchestrator.legal-receipt:build-receipt *graph* *version*
    :source-artifact *src-artifact-alist* :known-at *known-at*))
(defparameter *receipt-id* (orchestrator.legal-receipt:lr-receipt-id *receipt*))
(defparameter *receipt-alist* (orchestrator.legal-receipt:receipt-alist *receipt*))
(defparameter *receipt-ids* (list "rid:pad0" *receipt-id* "rid:pad2" "rid:pad3"))
(defparameter *receipt-index* 1)
(defparameter *receipt-set-root* (orchestrator.merkle:merkle-root-of-strings *receipt-ids*))

;;; ── ΠΡΑΓΜΑΤΙΚΟ TRA (make-effectivity-attestation) ────────────────────────
(defparameter *anchor* (vg:make-provisional-anchor :verifier-hash "sha256:vh"))
(defparameter *tra*
  (vg:make-effectivity-attestation *graph* *pid* :valid-at *valid-at* :known-at *known-at*
    :corpus-id *corpus* :anchor *anchor* :receipt-id *receipt-id*))
(defparameter *tra-hash* (getf *tra* :hash))

;;; ── #4A ENVELOPE (ΓΝΗΣΙΑ κρυπτο) ─────────────────────────────────────────
(multiple-value-bind (osk opk) (ironclad:generate-key-pair :ed25519)
  (defparameter *owner-sk* osk) (defparameter *owner-jwk* (apb:ed25519-public-to-jwk opk))
  (defparameter *owner-thumb* (apb:ed25519-jwk-thumbprint opk)))
(defparameter *rsa* (orchestrator.jws-authority:generate-rsa-keypair :bits 2048))
(defparameter *rk-pub* (getf *rsa* :public-key)) (defparameter *rk-priv* (getf *rsa* :private-key))
(defun b64u (n) (orchestrator.jws-authority:base64url-encode (ironclad:integer-to-octets n)))
(defparameter *release-jwk*
  (list (cons "kty" "RSA") (cons "n" (b64u (ironclad:rsa-key-modulus *rk-pub*)))
        (cons "e" (b64u (ironclad:rsa-key-exponent *rk-pub*)))))
(defparameter *rk-thumb* (orchestrator.jws-authority:jwk-thumbprint *rk-pub*))
(defparameter *verifier-bytes* "TEMPORAL-VERIFIER-BINARY-CONTENT-v1 (test)")
(defparameter *verifier-hash* (sha256tag *verifier-bytes*))
(defparameter *verifier-set* (list *verifier-hash* "sha256:other"))
(defparameter *content* (list :text-sha256 (sha256tag (vg:tv-text *version*))
                              :version-hash (vg:tv-version-hash *version*)))
(defparameter *cut* (list :graph-root *graph-root* :journal-seq *graph-seq* :known-at *known-at*))
(defparameter *census* (list :graph-root *graph-root* :receipt-set-root *receipt-set-root*
                             :receipt-ids *receipt-ids*))
;; tlog: release-root leaf
(defparameter *tlog-leaves* (list "sha256:prev" *release-root* "sha256:x" "sha256:y"))
(defparameter *tlh* (mapcar #'orchestrator.merkle:hash-leaf-string *tlog-leaves*))
(defparameter *tlog*
  (list :tree-size 4 :root (orchestrator.merkle:merkle-tree-hash *tlh*) :leaf-index 1
        :inclusion-path (orchestrator.merkle:inclusion-path *tlh* 1)
        :consistency-proof (orchestrator.merkle:consistency-proof *tlh* 2)))
(defparameter *cp* (list :tree-size 2 :root (orchestrator.merkle:merkle-tree-hash (subseq *tlh* 0 2))))
(defparameter *scope* (format nil "corpus/~A" *corpus*))

(defun make-delegation (&key (seq 1) (scope *scope*) (signer *owner-sk*) (owner-thumb *owner-thumb*))
  (let ((s (apb:make-delegation-statement :owner-root-thumbprint owner-thumb
             :delegate-algorithm "RS256" :delegate-jwk-thumbprint *rk-thumb* :scope scope
             :not-before "20260101000000" :not-after "20261231235959" :sequence seq)))
    (list :statement s :signature (apb:owner-sign-statement signer "lawmax/trust/delegation/1" s))))

(defun sign-release-statement (&key (census *census*) (content *content*) (cut *cut*)
                                    (verifier-set *verifier-set*) (tlog *tlog*))
  (getf (orchestrator.jws-authority:sign-jws
         (funcall (find-symbol "%CANONICAL-RELEASE-STATEMENT" :orchestrator.apb)
                  :release-root *release-root* :graph-root (getf census :graph-root)
                  :receipt-set-root (getf census :receipt-set-root)
                  :content-text-sha256 (getf content :text-sha256)
                  :content-version-hash (getf content :version-hash)
                  :cut-graph-root (getf cut :graph-root) :cut-journal-seq (getf cut :journal-seq)
                  :cut-known-at (getf cut :known-at) :verifier-set verifier-set
                  :tlog-root (getf tlog :root) :tlog-tree-size (getf tlog :tree-size)
                  :tlog-leaf-index (getf tlog :leaf-index))
         *rk-priv*) :jws))

(defun make-envelope (&rest overrides)
  (let* ((census (or (getf overrides :census) *census*))
         (cut (or (getf overrides :cut) *cut*))
         (e (list :release-root *release-root* :release-jwk *release-jwk*
                  :release-jws (sign-release-statement :census census :cut cut)
                  :owner-root-jwk *owner-jwk* :census census :cut cut :content *content*
                  :receipt (list :receipt-id *receipt-id* :index *receipt-index*)
                  :tra (list :committed-content
                             (list :text-sha256 (getf *content* :text-sha256)
                                   :version-hash (getf *content* :version-hash)))
                  :tlog *tlog* :tsr-bytes *tsr* :verifier-set *verifier-set*
                  :delegation (make-delegation) :revocations '())))
    (loop for (k v) on overrides by #'cddr do (setf (getf e k) v))
    e))

(defun sign-authority-statement (&key (graph-root *graph-root*) (graph-seq *graph-seq*)
                                      (scope *scope*) (tra-hash *tra-hash*))
  (getf (orchestrator.jws-authority:sign-jws
         (canonical-authority-statement
          :protocol +bundle-protocol+ :corpus-id *corpus* :body-id *body*
          :release-id "rel-1" :release-generation "1" :delegation-scope scope
          :release-root *release-root* :census-root *graph-root*
          :receipt-set-root *receipt-set-root* :source-provenance-root *provenance-root*
          :graph-root graph-root :graph-seq graph-seq :graph-known-at *known-at*
          :tra-hash tra-hash :verifier-set-root (orchestrator.merkle:merkle-root-of-strings *verifier-set*)
          :tlog-tree-size 4 :tlog-root (getf *tlog* :root) :tlog-leaf-index 1
          :policy-digest "sha256:pol")
         *rk-priv*) :jws))

(defun make-bundle (&rest overrides)
  (let ((b (list :protocol +bundle-protocol+ :corpus-id *corpus* :body-id *body*
                 :release-id "rel-1" :release-generation "1" :delegation-scope *scope*
                 :envelope (make-envelope) :source-artifact
                 (list :bytes-utf8 *source-str* :declared-digest *source-digest*
                       :provenance-root *provenance-root*
                       :spans (list (list :start 0 :end 10 :unit :byte)))
                 :extraction-receipt (list :digest *extraction-digest*)
                 :normalization-receipt (list :digest *normalization-digest*)
                 :receipt *receipt-alist*
                 :receipt-membership (list :index *receipt-index*)
                 :journal-bytes *journal-bytes*
                 :census *census* :release-manifest (list :release-id "rel-1")
                 :verifier-binaries (list (list :name "verify-temporal.py"
                                                :bytes-utf8 *verifier-bytes* :sha256 *verifier-hash*))
                 :tra *tra* :authority-statement-jws (sign-authority-statement))))
    (loop for (k v) on overrides by #'cddr do (setf (getf b k) v))
    b))

(defparameter *policy*
  (list :required-tier "owner-pinned-authenticated"
        :allowed-delegate-algorithms '("RS256") :temporal-verifier-hash *verifier-hash*
        :policy-digest "sha256:pol"))

(defun verify (&rest bundle-overrides)
  (verify-authority-evidence-bundle
   (apply #'make-bundle bundle-overrides)
   :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
   :consumer-checkpoint *cp* :policy *policy*))

(defun failed-p (v name) (member name (aer-reasons v)))

;;; ════════════════════════════════ TESTS ════════════════════════════════
(format t "~%== [1] ΘΕΤΙΚΟ: πλήρες evidence replay ⇒ owner-pinned, continuity ==~%")
(let ((v (verify)))
  (ck "awarded = owner-pinned-authenticated" (equal (aer-awarded-tier v) "owner-pinned-authenticated"))
  (ck "satisfies-policy" (aer-satisfies-policy-p v))
  (ck "reasons ΚΕΝΑ (full replay green)" (null (aer-reasons v)))
  (ck "replayed graph_root = γνήσιος" (equal (aer-replayed-graph-root v) *graph-root*))
  (ck "recomputed TRA hash = TRA hash" (equal (aer-recomputed-tra-hash v) *tra-hash*))
  (ck "authentication-mode = :continuity-verified" (eq (aer-authentication-mode v) :continuity-verified)))

(format t "~%== [2] SCHEMA κλειστό ==~%")
(ck "unknown key ⇒ ΣΦΑΛΜΑ"
    (handler-case (progn (validate-bundle-schema (append (make-bundle) (list :smuggled 1))) nil)
      (error () t)))
(ck "missing key ⇒ ΣΦΑΛΜΑ"
    (handler-case (let ((b (copy-list (make-bundle)))) (remf b :receipt)
                    (validate-bundle-schema b) nil)
      (error () t)))
(ck "bundle-id ντετερμινιστικό" (equal (bundle-id (make-bundle)) (bundle-id (make-bundle))))

(format t "~%== [3] JOURNAL REPLAY (byte tamper / prefix / graph_root) ==~%")
;; journal byte tamper ⇒ load-graph journal-corruption ⇒ replay FAIL
(let ((v (verify :journal-bytes (let ((s (copy-seq *journal-bytes*)))
                                  (setf (char s (floor (length s) 2))
                                        (if (char= (char s (floor (length s) 2)) #\a) #\b #\a))
                                  s))))
  (ck "journal byte tamper ⇒ journal-integrity FAIL" (failed-p v :replay/journal-integrity)))
;; graph_root δηλωμένο στο authority-statement αλλά ΔΕΝ παράγεται από replay
(let ((v (verify :authority-statement-jws (sign-authority-statement :graph-root "sha256:FORGED"))))
  (ck "authority-statement graph_root ≠ replayed ⇒ statement-binds-replay FAIL"
      (failed-p v :replay/authority-statement-binds-replay)))
;; envelope census/cut root ≠ replayed (self-consistent #4A αλλά διαφορετικός
;; από τον ΑΝΑΚΑΤΑΣΚΕΥΑΣΜΕΝΟ) ⇒ ο δεσμός replay↔declared σπάει
(let ((v (verify :envelope (make-envelope
                            :census (list :graph-root "sha256:FAKE"
                                          :receipt-set-root *receipt-set-root* :receipt-ids *receipt-ids*)
                            :cut (list :graph-root "sha256:FAKE" :journal-seq *graph-seq* :known-at *known-at*)))))
  (ck "envelope census/cut root ≠ replayed ⇒ graph-root-consistent FAIL"
      (failed-p v :replay/graph-root-consistent)))
;; ξένο journal (άλλο body) ⇒ receipt cut δεν βρίσκεται
(let* ((g2b "apbtest-other-graph")
       (g2 (vg:make-graph g2b)) (p2 (vg::vg-path g2)))
  (when (probe-file p2) (delete-file p2))
  (vg:submit-genesis! (vg:make-graph g2b)
                      (vg:make-version-spec :provision-id "x:art_9" :text "ξένο" :valid-from "2020-01-01"
                                            :assurance :extracted-verified)
                      :derivation "bootstrap:x")
  (let* ((jb (alexandria:read-file-into-string (vg::vg-path (vg:make-graph g2b)) :external-format :utf-8))
         (v (verify :journal-bytes jb)))
    (ck "ξένο journal (receipt cut απών) ⇒ receipt-intrinsic FAIL" (failed-p v :replay/receipt-intrinsic))
    (ignore-errors (delete-file (vg::vg-path (vg:make-graph g2b))))))

(format t "~%== [4] RECEIPT (id mismatch / ξένο περιεχόμενο / membership) ==~%")
;; receipt-id mismatch: αλλάζω το receipt_id στο alist
(let* ((bad (copy-tree *receipt-alist*))
       (_ (setf (cdr (assoc "receipt_id" bad :test #'equal)) "sha256:FORGEDID"))
       (v (verify :receipt bad)))
  (declare (ignore _))
  (ck "receipt_id mismatch ⇒ receipt-intrinsic FAIL" (failed-p v :replay/receipt-intrinsic)))
;; receipt μέλος του set (id) αλλά ξένο περιεχόμενο (content_hash πειραγμένο)
(let* ((bad (copy-tree *receipt-alist*))
       (_ (setf (cdr (assoc "content_hash" bad :test #'equal)) "sha256:ALIEN"))
       (v (verify :receipt bad)))
  (declare (ignore _))
  (ck "receipt id μέλος αλλά ξένο content ⇒ receipt-intrinsic FAIL" (failed-p v :replay/receipt-intrinsic)))
;; membership λάθος index
(let ((v (verify :receipt-membership (list :index 0))))
  (ck "receipt membership λάθος index ⇒ membership FAIL" (failed-p v :replay/receipt-membership)))

(format t "~%== [5] SOURCE ARTIFACT (byte tamper / span / extraction subst) ==~%")
(let ((v (verify :source-artifact (list :bytes-utf8 (concatenate 'string *source-str* "X")
                                        :declared-digest *source-digest* :provenance-root *provenance-root*
                                        :spans (list (list :start 0 :end 10 :unit :byte))))))
  (ck "source byte tamper ⇒ source-digest FAIL" (failed-p v :replay/source-digest)))
(let ((v (verify :source-artifact (list :bytes-utf8 *source-str* :declared-digest *source-digest*
                                        :provenance-root *provenance-root*
                                        :spans (list (list :start 0 :end 99999 :unit :byte))))))
  (ck "source span εκτός artifact ⇒ source-spans FAIL" (failed-p v :replay/source-spans-within)))
(let ((v (verify :extraction-receipt (list :digest (sha256tag "SUBSTITUTED-extraction")))))
  (ck "extraction receipt substitution ⇒ provenance-chain FAIL" (failed-p v :replay/provenance-chain)))

(format t "~%== [6] TRA recompute (σωστό committed αλλά λάθος outcome/hash) ==~%")
;; TRA με λάθος hash (committed-content ίδιο, hash πειραγμένο)
(let* ((bad (copy-list *tra*)) (_ (setf (getf bad :hash) "sha256:WRONGTRA"))
       (v (verify :tra bad)))
  (declare (ignore _))
  (ck "TRA hash ≠ recompute ⇒ tra-recompute FAIL" (failed-p v :replay/tra-recompute)))
;; TRA με λάθος outcome (recompute από τον γράφο το πιάνει)
(let* ((bad (copy-list *tra*)) (_ (setf (getf bad :outcome) (list "resolved" "version-hash" "sha256:FAKE" "text-sha256" "sha256:FAKE")))
       (v (verify :tra bad)))
  (declare (ignore _))
  (ck "TRA outcome ≠ recompute-from-graph ⇒ tra-recompute FAIL" (failed-p v :replay/tra-recompute)))

(format t "~%== [7] SCOPE + DELEGATION STATE (rollback / equivocation) ==~%")
;; scope mismatch: delegation scope για ΑΛΛΟ corpus
(let ((v (verify :envelope (make-envelope) :delegation-scope "corpus/OTHER"
                 :authority-statement-jws (sign-authority-statement :scope "corpus/OTHER"))))
  (ck "delegation scope ΑΛΛΟ corpus ⇒ scope-covers FAIL" (failed-p v :replay/scope-covers-corpus)))
;; rollback: known latest sequence 5 > bundle sequence 1
(let ((v (verify-authority-evidence-bundle
          (make-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint *cp* :policy *policy*
          :known-delegation-state (list :latest-sequence 5))))
  (ck "delegation sequence 1 < known latest 5 ⇒ no-rollback FAIL" (failed-p v :replay/delegation-no-rollback)))
;; equivocation: ίδιο sequence, ΔΙΑΦΟΡΕΤΙΚΟ statement hash
(let ((v (verify-authority-evidence-bundle
          (make-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint *cp* :policy *policy*
          :known-delegation-state (list :latest-sequence 1 :statement-hash "sha256:DIFFERENT"))))
  (ck "ίδιο sequence διαφορετικό statement hash ⇒ no-equivocation FAIL"
      (failed-p v :replay/delegation-no-equivocation)))
;; συνεπές delegation state ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ
(let ((v (verify-authority-evidence-bundle
          (make-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint *cp* :policy *policy*
          :known-delegation-state (list :latest-sequence 1))))
  (ck "συνεπές delegation state ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ"
      (equal (aer-awarded-tier v) "owner-pinned-authenticated")))

(format t "~%== [8] POLICY substitution + verifier-binaries binding ==~%")
;; policy digest substitution ⇒ authority-statement recompute ≠ signed
(let ((v (verify-authority-evidence-bundle
          (make-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :consumer-checkpoint *cp*
          :policy (list* :policy-digest "sha256:SUBSTITUTED" (cddr *policy*)))))
  (ck "policy digest substitution ⇒ statement-binds-replay FAIL"
      (failed-p v :replay/authority-statement-binds-replay)))
;; verifier binary bytes ΠΟΥ ΔΕΝ κατακερματίζονται στον required verifier hash
;; (recompute sha256(bytes) ≠ required) ⇒ verifier-binaries FAIL (F2 real bytes)
(let ((v (verify :verifier-binaries
                 (list (list :name "verify-temporal.py" :bytes-utf8 "WRONG-BINARY-CONTENT"
                             :sha256 (sha256tag "WRONG-BINARY-CONTENT"))))))
  (ck "verifier bytes ≠ required hash (recompute) ⇒ verifier-binaries FAIL"
      (failed-p v :replay/verifier-binaries-bind)))
;; declared :sha256 ≠ recompute(bytes) ⇒ FAIL (ο declared ΔΕΝ γίνεται δεκτός)
(let ((v (verify :verifier-binaries
                 (list (list :name "verify-temporal.py" :bytes-utf8 *verifier-bytes*
                             :sha256 "sha256:LIED")))))
  (ck "declared verifier sha256 ≠ recompute ⇒ verifier-binaries FAIL"
      (failed-p v :replay/verifier-binaries-bind)))

(format t "~%== [9] first-seen vs continuity (ΟΥΣΙΑΣΤΙΚΗ διάκριση) ==~%")
(let ((v (verify-authority-evidence-bundle
          (make-bundle) :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
          :policy *policy*)))                       ; ΧΩΡΙΣ checkpoint
  (ck "χωρίς checkpoint ⇒ authentication-mode = :first-seen"
      (eq (aer-authentication-mode v) :first-seen))
  (ck "first-seen ⇒ cap σε internally-release-consistent (ΟΧΙ owner-pinned)"
      (equal (aer-awarded-tier v) "internally-release-consistent"))
  (ck "first-seen ⇒ ΔΕΝ ικανοποιεί owner-pinned policy" (not (aer-satisfies-policy-p v))))

;; cleanup
(ignore-errors (delete-file *graph-path*))

(format t "~%======================================================~%")
(format t "authority-evidence-replay: ~D passed, ~D failed~%" *p* *f*)
(when (plusp *f*) (format t "ΑΠΟΤΥΧΙΑ~%") (sb-ext:exit :code 1))
(format t "ΟΛΑ ΠΡΑΣΙΝΑ — #4B authority evidence replay κλειδωμένο~%")
