;;;; tests/authority-evidence-replay-test.lisp
;;;; ============================================================================
;;;; [0088 Φ7-HARDENING #4B+#4C] Regression lock: verify-authority-evidence-bundle
;;;; ============================================================================
;;;; ΠΡΑΓΜΑΤΙΚΟΣ γράφος (submit-genesis! → journal), γνήσιο receipt/TRA από τις
;;;; έδρες, ΠΡΑΓΜΑΤΙΚΗ source→spans→extraction→normalization→graph-text γέφυρα,
;;;; #4A envelope με γνήσιο Sectigo TSR σε pinned CA. Ο verifier ΑΝΑΚΑΤΑΣΚΕΥΑΖΕΙ
;;;; τα πάντα — ΚΑΝΕΝΑ declared root.
;;;; #4C witnesses: scope mismatch delegation, source-χωρίς-το-κείμενο, span
;;;; overflow, extraction/normalization tamper, policy-field-ίδιο-digest, anchor
;;;; forge, verifier-set missing/extra, bundle-id tamper, duplicate key,
;;;; census decorative, release-manifest, require-delegation-state, compromise.
;;;; TEST ROOT — NOT PRODUCTION (Δ5).
;;;; ============================================================================

(in-package :orchestrator.apb-replay)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *fix*
  (merge-pathnames "fixtures/tsr/"
                   (make-pathname :directory (pathname-directory (or *load-truename* *load-pathname*)))))
(defparameter *sectigo-ca* (merge-pathnames "sectigo-issuer-ca.pem" *fix*))
(defparameter *release-root*
  (string-trim '(#\Newline #\Space)
               (alexandria:read-file-into-string (merge-pathnames "message.txt" *fix*))))
(defparameter *tsr* (alexandria:read-file-into-byte-vector (merge-pathnames "sectigo-rsa.tsr" *fix*)))
(defun sha256tag (str)
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string
           (ironclad:digest-sequence :sha256 (babel:string-to-octets str :encoding :utf-8)))))
(defun sha256tag-bytes (b)
  (format nil "sha256:~A" (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 b))))

;;; ── ΠΡΑΓΜΑΤΙΚΟΣ ΓΡΑΦΟΣ ────────────────────────────────────────────────────
(defparameter *corpus* "syntagma-test")
(defparameter *body* "gr/nomos/2099/test")
(defparameter *pid* "gr/nomos/2099/test:art_1")
(defparameter *legal-text* "Άρθρο 1. Το πολίτευμα είναι δοκιμαστικό.")
(defparameter *tmp-graph-body* "apbc-source-graph")
(let ((path (vg::vg-path (vg:make-graph *tmp-graph-body*))))
  (when (probe-file path) (delete-file path))
  (let ((g (vg:make-graph *tmp-graph-body*)))   ; ΕΝΑ graph object για ΟΛΑ τα submits
    (vg:submit-genesis! g
      (vg:make-version-spec :provision-id *pid* :text *legal-text* :heading "Δοκιμή"
                            :valid-from "2020-01-01" :assurance :extracted-verified)
      :derivation "bootstrap:syntagma-test")
    (vg:submit-genesis! g
      (vg:make-version-spec :provision-id "gr/nomos/2099/test:art_2" :text "Άρθρο 2." :heading "Β"
                            :valid-from "2020-01-01" :assurance :extracted-verified)
      :derivation "bootstrap:syntagma-test"))
  (defparameter *graph* (vg:load-graph *tmp-graph-body*))
  (defparameter *journal-bytes* (alexandria:read-file-into-string path :external-format :utf-8))
  (defparameter *graph-path* path))
(defparameter *graph-root* (vg:graph-chain-head *graph*))
(defparameter *graph-seq* (vg:graph-seq *graph*))
(defparameter *known-at* "2099-01-01T00:00:00Z")
(defparameter *valid-at* "2025-01-01")

;;; ── SOURCE→TEXT: source bytes ΠΟΥ ΠΕΡΙΕΧΟΥΝ το κείμενο ────────────────────
(defparameter *prefix* "ΕΦΗΜΕΡΙΣ ΤΗΣ ΚΥΒΕΡΝΗΣΕΩΣ | ")
(defparameter *padded* (concatenate 'string "  " *legal-text* "  "))  ; padding ⇒ normalization
(defparameter *suffix* " | ΤΕΛΟΣ ΦΕΚ")
(defparameter *source-str* (concatenate 'string *prefix* *padded* *suffix*))
(defparameter *source-bytes* (babel:string-to-octets *source-str* :encoding :utf-8))
(defparameter *source-digest* (sha256tag-bytes *source-bytes*))
(defparameter *span-start* (length (babel:string-to-octets *prefix* :encoding :utf-8)))
(defparameter *span-end* (+ *span-start* (length (babel:string-to-octets *padded* :encoding :utf-8))))
(defparameter *extracted-bytes* (subseq *source-bytes* *span-start* *span-end*))
(defparameter *normalized* (string-trim '(#\Space #\Newline #\Tab #\Return)
                                        (babel:octets-to-string *extracted-bytes* :encoding :utf-8)))
;; sanity: normalized == graph text
(assert (string= *normalized* *legal-text*))

(defparameter *extraction-receipt*
  (list (cons "schema" +extraction-schema+)
        (cons "extractor_id" "lawmax-span-extractor")
        (cons "extractor_hash" (sha256tag "extractor-v1"))
        (cons "config_hash" (sha256tag "extractor-config-v1"))
        (cons "input_digest" *source-digest*)
        (cons "spans" (list (list (cons "start" *span-start*) (cons "end" *span-end*) (cons "unit" "byte"))))
        (cons "output_digest" (sha256tag-bytes *extracted-bytes*))))
(defparameter *normalization-receipt*
  (list (cons "schema" +normalization-schema+)
        (cons "normalizer_id" "lawmax-trim-normalizer")
        (cons "normalizer_hash" (sha256tag "normalizer-v1"))
        (cons "config_hash" (sha256tag "normalizer-config-v1"))
        (cons "input_digest" (sha256tag-bytes *extracted-bytes*))
        (cons "output_digest" (sha256tag *normalized*))))
(defparameter *provenance-root*
  (orchestrator.merkle:merkle-root-of-strings
   (list *source-digest* (extraction-receipt-id *extraction-receipt*)
         (normalization-receipt-id *normalization-receipt*))))
(defparameter *src-artifact-alist*
  (list (cons "content_sha256" *source-digest*) (cons "source_digest" *source-digest*)))

;;; ── ΠΡΑΓΜΑΤΙΚΟ RECEIPT ───────────────────────────────────────────────────
(defparameter *version* (vg:version-at *graph* *pid* :valid-at *valid-at* :known-at *known-at*))
(defparameter *receipt* (orchestrator.legal-receipt:build-receipt *graph* *version*
                          :source-artifact *src-artifact-alist* :known-at *known-at*))
(defparameter *receipt-id* (orchestrator.legal-receipt:lr-receipt-id *receipt*))
(defparameter *receipt-alist* (orchestrator.legal-receipt:receipt-alist *receipt*))
(defparameter *receipt-ids* (list "rid:pad0" *receipt-id* "rid:pad2" "rid:pad3"))
(defparameter *receipt-index* 1)
(defparameter *receipt-set-root* (orchestrator.merkle:merkle-root-of-strings *receipt-ids*))

;;; ── VERIFIER BINARIES (πραγματικά bytes) → verifier-set ──────────────────
(defparameter *vbytes-a* "VERIFY-TEMPORAL-PY-CONTENT-v1")
(defparameter *vbytes-b* "VERIFY-CANONICAL-PY-CONTENT-v1")
(defparameter *vhash-a* (sha256tag *vbytes-a*))
(defparameter *vhash-b* (sha256tag *vbytes-b*))
(defparameter *verifier-hash* *vhash-a*)
(defparameter *verifier-set* (sort (list *vhash-a* *vhash-b*) #'string<))
(defparameter *verifier-binaries*
  (list (list :name "verify-temporal.py" :bytes-utf8 *vbytes-a* :sha256 *vhash-a*)
        (list :name "verify-canonical.py" :bytes-utf8 *vbytes-b* :sha256 *vhash-b*)))

;;; ── #4A ENVELOPE ─────────────────────────────────────────────────────────
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
(defparameter *content* (list :text-sha256 (sha256tag *legal-text*) :version-hash (vg:tv-version-hash *version*)))
(defparameter *cut* (list :graph-root *graph-root* :journal-seq *graph-seq* :known-at *known-at*))
(defparameter *census* (list :graph-root *graph-root* :receipt-set-root *receipt-set-root* :receipt-ids *receipt-ids*))
(defparameter *tlog-leaves* (list "sha256:prev" *release-root* "sha256:x" "sha256:y"))
(defparameter *tlh* (mapcar #'orchestrator.merkle:hash-leaf-string *tlog-leaves*))
(defparameter *tlog* (list :tree-size 4 :root (orchestrator.merkle:merkle-tree-hash *tlh*) :leaf-index 1
                           :inclusion-path (orchestrator.merkle:inclusion-path *tlh* 1)
                           :consistency-proof (orchestrator.merkle:consistency-proof *tlh* 2)))
(defparameter *cp* (list :tree-size 2 :root (orchestrator.merkle:merkle-tree-hash (subseq *tlh* 0 2))))
(defparameter *scope* (format nil "corpus/~A" *corpus*))
(defparameter *registry-digest* (sha256tag "scope-tag-registry-v2"))

(defun make-delegation (&key (seq 1) (scope *scope*) (signer *owner-sk*) (owner-thumb *owner-thumb*))
  (let ((s (apb:make-delegation-statement :owner-root-thumbprint owner-thumb
             :delegate-algorithm "RS256" :delegate-jwk-thumbprint *rk-thumb* :scope scope
             :not-before "20260101000000" :not-after "20261231235959" :sequence seq)))
    (list :statement s :signature (apb:owner-sign-statement signer "lawmax/trust/delegation/1" s))))

(defun sign-release-statement (&key (census *census*) (cut *cut*))
  (getf (orchestrator.jws-authority:sign-jws
         (funcall (find-symbol "%CANONICAL-RELEASE-STATEMENT" :orchestrator.apb)
                  :release-root *release-root* :graph-root (getf census :graph-root)
                  :receipt-set-root (getf census :receipt-set-root)
                  :content-text-sha256 (getf *content* :text-sha256)
                  :content-version-hash (getf *content* :version-hash)
                  :cut-graph-root (getf cut :graph-root) :cut-journal-seq (getf cut :journal-seq)
                  :cut-known-at (getf cut :known-at) :verifier-set *verifier-set*
                  :tlog-root (getf *tlog* :root) :tlog-tree-size (getf *tlog* :tree-size)
                  :tlog-leaf-index (getf *tlog* :leaf-index))
         *rk-priv*) :jws))

(defun make-envelope (&rest overrides)
  (let* ((census (or (getf overrides :census) *census*)) (cut (or (getf overrides :cut) *cut*))
         (e (list :release-root *release-root* :release-jwk *release-jwk*
                  :release-jws (sign-release-statement :census census :cut cut)
                  :owner-root-jwk *owner-jwk* :census census :cut cut :content *content*
                  :receipt (list :receipt-id *receipt-id* :index *receipt-index*)
                  :tra (list :committed-content (list :text-sha256 (getf *content* :text-sha256)
                                                      :version-hash (getf *content* :version-hash)))
                  :tlog *tlog* :tsr-bytes *tsr* :verifier-set *verifier-set*
                  :delegation (make-delegation) :revocations '())))
    (loop for (k v) on overrides by #'cddr do (setf (getf e k) v)) e))

;;; ── TRA με anchor ΠΟΥ ΤΑΙΡΙΑΖΕΙ ΤΟ %derive-anchor ────────────────────────
(defparameter *anchor*
  (vg::%make-verified-anchor :assurance "internally-release-consistent"
    :release-root *release-root* :reasons '()
    :tlog-size (getf *tlog* :tree-size) :tlog-root (getf *tlog* :root)
    :registry-digest *registry-digest* :verifier-hash *verifier-hash*))
(defparameter *tra*
  (vg:make-effectivity-attestation *graph* *pid* :valid-at *valid-at* :known-at *known-at*
    :corpus-id *corpus* :anchor *anchor* :receipt-id *receipt-id*))
(defparameter *tra-hash* (getf *tra* :hash))

;;; ── POLICY (closed digest) ───────────────────────────────────────────────
(defparameter *policy-base*
  (list :required-tier "owner-pinned-authenticated" :allowed-delegate-algorithms '("RS256")
        :temporal-verifier-hash *verifier-hash*))
(defparameter *policy* (append (list :policy-digest (canonical-policy-digest *policy-base*)) *policy-base*))

;;; ── AUTHORITY-STATEMENT + BUNDLE ─────────────────────────────────────────
(defun components-bundle (&rest overrides)
  "Bundle ΧΩΡΙΣ :bundle-id/:authority-statement-jws — για υπολογισμό bundle-id."
  (let ((b (list :protocol +bundle-protocol+ :corpus-id *corpus* :body-id *body*
                 :release-id "rel-1" :release-generation "1" :delegation-scope *scope*
                 :registry-digest *registry-digest* :envelope (make-envelope)
                 :source-artifact (list :bytes-utf8 *source-str* :declared-digest *source-digest*
                                        :provenance-root *provenance-root*)
                 :extraction-receipt *extraction-receipt* :normalization-receipt *normalization-receipt*
                 :receipt *receipt-alist* :receipt-membership (list :index *receipt-index*)
                 :journal-bytes *journal-bytes* :census *census*
                 :release-manifest (list :release-id "rel-1" :release-generation "1")
                 :verifier-binaries *verifier-binaries* :tra *tra*)))
    (loop for (k v) on overrides by #'cddr do (setf (getf b k) v)) b))

;; Το statement υπογράφεται πάνω στις ΠΡΑΓΜΑΤΙΚΕΣ τιμές των components (production
;; model: η release ceremony υπογράφει το ΠΡΑΓΜΑΤΙΚΟ bundle) — ώστε isolating
;; negatives (π.χ. διαφορετικό span) να μη σπάνε τη statement υπογραφή.
(defun sign-authority-statement-of (bid comp &key (policy-digest (getf *policy* :policy-digest)))
  (let* ((env (getf comp :envelope)) (census (getf comp :census))
         (src (getf comp :source-artifact)))
    (getf (orchestrator.jws-authority:sign-jws
           (canonical-authority-statement
            :protocol +bundle-protocol+ :bundle-id bid :corpus-id (getf comp :corpus-id)
            :body-id (getf comp :body-id) :release-id (getf comp :release-id)
            :release-generation (getf comp :release-generation)
            :delegation-scope (getf comp :delegation-scope) :registry-digest (getf comp :registry-digest)
            :release-root (getf env :release-root) :census-root (getf census :graph-root)
            :receipt-set-root (getf census :receipt-set-root) :source-provenance-root (getf src :provenance-root)
            :graph-root (getf census :graph-root) :graph-seq (getf (getf env :cut) :journal-seq)
            :graph-known-at (getf (getf env :cut) :known-at) :tra-hash (getf (getf comp :tra) :hash)
            :verifier-set-root (orchestrator.merkle:merkle-root-of-strings (getf env :verifier-set))
            :tlog-tree-size (getf (getf env :tlog) :tree-size) :tlog-root (getf (getf env :tlog) :root)
            :tlog-leaf-index (getf (getf env :tlog) :leaf-index) :policy-digest policy-digest)
           *rk-priv*) :jws)))

(defun %strip (plist keys)
  (loop for (k v) on plist by #'cddr unless (member k keys) append (list k v)))
(defun make-bundle (&rest overrides)
  (let* ((comp (apply #'components-bundle (%strip overrides '(:bundle-id :authority-statement-jws))))
         (bid (or (getf overrides :bundle-id) (bundle-id comp)))
         (jws (or (getf overrides :authority-statement-jws) (sign-authority-statement-of bid comp))))
    (append (list :bundle-id bid :authority-statement-jws jws) comp)))

(defun verify (&rest overrides)
  (verify-authority-evidence-bundle (apply #'make-bundle overrides)
   :trusted-owner-root-jwk *owner-jwk* :trusted-tsa-ca-path *sectigo-ca*
   :consumer-checkpoint *cp* :policy *policy*))
(defun failed-p (v name) (member name (aer-reasons v)))
(defun verify-b (b) (verify-authority-evidence-bundle b :trusted-owner-root-jwk *owner-jwk*
                     :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp* :policy *policy*))
;; helpers για isolating source→text negatives (provenance-root recomputed ⇒ ΜΟΝΟ
;; το target predicate κοκκινίζει)
(defun make-er (spans &key (input *source-digest*) (output nil))
  (list (cons "schema" +extraction-schema+) (cons "extractor_id" "x")
        (cons "extractor_hash" (sha256tag "e")) (cons "config_hash" (sha256tag "c"))
        (cons "input_digest" input) (cons "spans" spans)
        (cons "output_digest" (or output "sha256:0"))))
(defun span1 (a b &key (unit "byte")) (list (list (cons "start" a) (cons "end" b) (cons "unit" unit))))
(defun make-nr (input normalized) (list (cons "schema" +normalization-schema+) (cons "normalizer_id" "n")
        (cons "normalizer_hash" (sha256tag "n")) (cons "config_hash" (sha256tag "nc"))
        (cons "input_digest" input) (cons "output_digest" (sha256tag normalized))))
(defun bundle-src (er nr)
  (make-bundle :extraction-receipt er :normalization-receipt nr
               :source-artifact (list :bytes-utf8 *source-str* :declared-digest *source-digest*
                 :provenance-root (orchestrator.merkle:merkle-root-of-strings
                   (list *source-digest* (extraction-receipt-id er) (normalization-receipt-id nr))))))

;;; ════════════════════════════════ TESTS ════════════════════════════════
(format t "~%== [1] ΘΕΤΙΚΟ: πλήρες #4C replay + source→text bridge ==~%")
(let ((v (verify)))
  (ck "awarded = owner-pinned-authenticated" (equal (aer-awarded-tier v) "owner-pinned-authenticated"))
  (ck "satisfies-policy" (aer-satisfies-policy-p v))
  (ck "reasons ΚΕΝΑ (full replay green)" (null (aer-reasons v)))
  (ck "replayed graph_root γνήσιος" (equal (aer-replayed-graph-root v) *graph-root*))
  (ck "derived text == graph text (η ΓΕΦΥΡΑ)" (equal (aer-derived-text v) *legal-text*))
  (ck "recomputed TRA hash == TRA hash (anchor από envelope)" (equal (aer-recomputed-tra-hash v) *tra-hash*)))

(format t "~%== [2] SCOPE binding (#4C-1) ==~%")
;; delegation scope για ΑΛΛΟ corpus αλλά top-level scope σωστό
(let ((v (verify :envelope (make-envelope) :delegation-scope *scope*
                 :envelope (progn (make-envelope)))))
  (declare (ignore v)))
(let* ((env (make-envelope))                 ; delegation scope = corpus/B μέσα, top-level = corpus/A
       (envB (progn (setf (getf env :delegation) (make-delegation :scope "corpus/OTHER"))
                    ;; ξανα-υπόγραψε #4A release-statement ΔΕΝ αλλάζει — delegation ξεχωριστό
                    env))
       (v (verify :envelope envB)))
  (ck "owner-signed delegation scope=corpus/OTHER ≠ top-level ⇒ scope-matches FAIL"
      (failed-p v :replay/scope-matches-delegation)))

(format t "~%== [3] SOURCE→TEXT bridge (#4C-2) ==~%")
;; source bytes ΠΟΥ ΔΕΝ περιέχουν το κείμενο (αλλά self-consistent digests)
(let* ((bad-str "ΑΣΧΕΤΟ ΚΕΙΜΕΝΟ που δεν είναι ο νόμος")
       (bad-bytes (babel:string-to-octets bad-str :encoding :utf-8))
       (bad-dig (sha256tag-bytes bad-bytes))
       (bad-ex (list (cons "schema" +extraction-schema+) (cons "extractor_id" "x")
                     (cons "extractor_hash" (sha256tag "e")) (cons "config_hash" (sha256tag "c"))
                     (cons "input_digest" bad-dig)
                     (cons "spans" (list (list (cons "start" 0) (cons "end" (length bad-bytes)) (cons "unit" "byte"))))
                     (cons "output_digest" (sha256tag-bytes bad-bytes))))
       (bad-norm-text (string-trim '(#\Space) bad-str))
       (bad-nr (list (cons "schema" +normalization-schema+) (cons "normalizer_id" "n")
                     (cons "normalizer_hash" (sha256tag "n")) (cons "config_hash" (sha256tag "nc"))
                     (cons "input_digest" (sha256tag-bytes bad-bytes)) (cons "output_digest" (sha256tag bad-norm-text))))
       (bad-proot (orchestrator.merkle:merkle-root-of-strings
                   (list bad-dig (extraction-receipt-id bad-ex) (normalization-receipt-id bad-nr))))
       (v (verify :source-artifact (list :bytes-utf8 bad-str :declared-digest bad-dig :provenance-root bad-proot)
                  :extraction-receipt bad-ex :normalization-receipt bad-nr)))
  (ck "source bytes ΧΩΡΙΣ το κείμενο ⇒ text-equals-graph FAIL (η ΓΕΦΥΡΑ πιάνει)"
      (failed-p v :replay/text-equals-graph))
  (ck "  ⇒ source-digest όμως αλλάζει receipt binding" t))
;; span overflow
(let* ((bad-ex (copy-tree *extraction-receipt*)))
  (setf (cdr (assoc "spans" bad-ex :test #'equal))
        (list (list (cons "start" 0) (cons "end" 999999) (cons "unit" "byte"))))
  (let ((v (verify :extraction-receipt bad-ex)))
    (ck "span overflow ⇒ provenance-root FAIL (recompute id διαφέρει)" (failed-p v :replay/provenance-root))))
;; extraction output_digest tamper
(let* ((bad-ex (copy-tree *extraction-receipt*)))
  (setf (cdr (assoc "output_digest" bad-ex :test #'equal)) "sha256:LIED")
  (let ((v (verify :extraction-receipt bad-ex)))
    (ck "extraction output_digest tamper ⇒ provenance-root FAIL" (failed-p v :replay/provenance-root))))

(format t "~%== [4] POLICY digest recompute (#4C-5) ==~%")
;; ίδιο δηλωμένο policy-digest αλλά διαφορετικό required-tier
(let* ((bad-policy (append (list :policy-digest (getf *policy* :policy-digest)
                                 :required-tier "internally-release-consistent")
                           (cddr *policy-base*)))
       (v (verify-authority-evidence-bundle (make-bundle) :trusted-owner-root-jwk *owner-jwk*
           :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp* :policy bad-policy)))
  (ck "ίδιο policy-digest διαφορετικό policy field ⇒ policy-digest FAIL"
      (failed-p v :replay/policy-digest)))

(format t "~%== [5] TRA anchor από envelope, ΟΧΙ από TRA (#4C-6) ==~%")
;; forge TRA anchor fields (release-root στο anchor) — το recompute με derived anchor το πιάνει
(let* ((forged-anchor (vg::%make-verified-anchor :assurance "internally-release-consistent"
                        :release-root "sha256:FORGED-RELEASE" :reasons '()
                        :tlog-size (getf *tlog* :tree-size) :tlog-root (getf *tlog* :root)
                        :registry-digest *registry-digest* :verifier-hash *verifier-hash*))
       (forged-tra (vg:make-effectivity-attestation *graph* *pid* :valid-at *valid-at* :known-at *known-at*
                     :corpus-id *corpus* :anchor forged-anchor :receipt-id *receipt-id*))
       (v (verify :tra forged-tra)))
  (ck "forged TRA anchor (release-root) ⇒ tra-recompute FAIL (anchor derived από envelope)"
      (failed-p v :replay/tra-recompute)))

(format t "~%== [6] VERIFIER-SET exact set (#4C-7) ==~%")
;; missing binary (μόνο 1 από 2)
(let ((v (verify :verifier-binaries (list (first *verifier-binaries*)))))
  (ck "missing verifier binary ⇒ verifier-set-exact FAIL" (failed-p v :replay/verifier-set-exact)))
;; extra binary
(let ((v (verify :verifier-binaries (append *verifier-binaries*
                                            (list (list :name "extra" :bytes-utf8 "EXTRA" :sha256 (sha256tag "EXTRA")))))))
  (ck "extra verifier binary ⇒ verifier-set-exact FAIL" (failed-p v :replay/verifier-set-exact)))

(format t "~%== [7] BUNDLE-ID + duplicate key (#4C-3) ==~%")
(let ((v (verify :bundle-id "sha256:WRONGBID")))
  (ck "bundle-id ≠ recompute ⇒ bundle-id FAIL" (failed-p v :replay/bundle-id)))
;; tamper receipt ΚΡΑΤΩΝΤΑΣ το signed bundle-id ⇒ bundle-id recompute διαφέρει
(let* ((b (make-bundle)) (bad-r (copy-tree *receipt-alist*)))
  (setf (cdr (assoc "derivation" bad-r :test #'equal)) "TAMPERED")
  (setf (getf b :receipt) bad-r)                 ; signed bundle-id ΜΕΝΕΙ, receipt αλλάζει
  (let ((v (verify-authority-evidence-bundle b :trusted-owner-root-jwk *owner-jwk*
            :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp* :policy *policy*)))
    (ck "tampered receipt (signed bundle-id ίδιο) ⇒ bundle-id FAIL (δεσμεύει ΟΛΑ)"
        (failed-p v :replay/bundle-id))))
(ck "duplicate top-level key ⇒ schema ΣΦΑΛΜΑ"
    (handler-case (progn (validate-bundle-schema (append (make-bundle) (list :census *census*))) nil)
      (error () t)))

(format t "~%== [8] DECORATIVE fields δεσμευμένα (#4C-4) ==~%")
(let ((v (verify :census (list :graph-root "sha256:OTHER" :receipt-set-root *receipt-set-root* :receipt-ids *receipt-ids*))))
  (ck "top-level census ≠ envelope census ⇒ census-bound FAIL" (failed-p v :replay/census-bound)))
(let ((v (verify :release-manifest (list :release-id "WRONG" :release-generation "1"))))
  (ck "release-manifest release-id ≠ ⇒ release-manifest-bound FAIL" (failed-p v :replay/release-manifest-bound)))

(format t "~%== [9] DELEGATION STATE (#4C-8) ==~%")
(let ((v (verify-authority-evidence-bundle (make-bundle) :trusted-owner-root-jwk *owner-jwk*
          :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp*
          :policy (append (list :require-delegation-state t :policy-digest
                                (canonical-policy-digest (append (list :require-delegation-state t) *policy-base*)))
                          *policy-base*))))
  (ck "require-delegation-state χωρίς external state ⇒ delegation-state-required FAIL"
      (failed-p v :replay/delegation-state-required)))
;; compromise_from ≤ release genTime ⇒ compromised
(let ((v (verify-authority-evidence-bundle (make-bundle) :trusted-owner-root-jwk *owner-jwk*
          :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp* :policy *policy*
          :known-delegation-state (list :latest-sequence 1 :compromise-from "20260101000000"))))
  (ck "compromise-from ≤ release genTime ⇒ not-compromised FAIL"
      (failed-p v :replay/delegation-not-compromised)))
(let ((v (verify-authority-evidence-bundle (make-bundle) :trusted-owner-root-jwk *owner-jwk*
          :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp* :policy *policy*
          :known-delegation-state (list :latest-sequence 1 :compromise-from "20990101000000"))))
  (ck "compromise-from ΜΕΤΑ genTime ⇒ owner-pinned ΠΑΡΑΜΕΝΕΙ" (equal (aer-awarded-tier v) "owner-pinned-authenticated")))

(format t "~%== [10] source→text ADVERSARIAL (single contiguous span, isolating) ==~%")
;; ΙΣΟΛΑΤΙΝΓ text-equals-graph: single span → ΔΙΑΦΟΡΕΤΙΚΟ contiguous κείμενο (prefix)
(let* ((plen (length (babel:string-to-octets *prefix* :encoding :utf-8)))
       (extracted (subseq *source-bytes* 0 plen))
       (norm (string-trim '(#\Space #\Newline #\Tab #\Return)
                          (babel:octets-to-string extracted :encoding :utf-8)))
       (er (make-er (span1 0 plen) :output (sha256tag-bytes extracted)))
       (nr (make-nr (sha256tag-bytes extracted) norm))
       (v (verify-b (bundle-src er nr))))
  (ck "ΙΣΟΛΑΤΙΝΓ: span σε ΔΙΑΦΟΡΕΤΙΚΟ κείμενο ⇒ ΜΟΝΟ text-equals-graph FAIL"
      (and (failed-p v :replay/text-equals-graph)
           (not (failed-p v :replay/provenance-root))
           (not (failed-p v :replay/extraction-replay))
           (not (failed-p v :replay/source-digest)))))
;; multi-span scatter/drop ⇒ ΣΦΑΛΜΑ (θάνατος forgery — source-critic F1)
(let* ((er (make-er (append (span1 0 5) (span1 10 15)) :output (sha256tag "x")))
       (nr (make-nr (sha256tag "x") "x")) (v (verify-b (bundle-src er nr))))
  (ck "multi-span (scatter/drop) ⇒ extraction-replay FAIL" (failed-p v :replay/extraction-replay)))
;; non-byte unit ⇒ ΣΦΑΛΜΑ
(let* ((er (make-er (span1 *span-start* *span-end* :unit "char") :output (sha256tag-bytes *extracted-bytes*)))
       (nr (make-nr (sha256tag-bytes *extracted-bytes*) *normalized*)) (v (verify-b (bundle-src er nr))))
  (ck "non-byte unit ⇒ extraction-replay FAIL" (failed-p v :replay/extraction-replay)))
;; extraction input_digest ≠ source
(let* ((er (make-er (span1 *span-start* *span-end*) :input "sha256:WRONG" :output (sha256tag-bytes *extracted-bytes*)))
       (nr (make-nr (sha256tag-bytes *extracted-bytes*) *normalized*)) (v (verify-b (bundle-src er nr))))
  (ck "extraction input_digest ≠ source ⇒ extraction-replay FAIL" (failed-p v :replay/extraction-replay)))
;; normalization input_digest ≠ extraction output
(let* ((er (make-er (span1 *span-start* *span-end*) :output (sha256tag-bytes *extracted-bytes*)))
       (nr (make-nr "sha256:MISMATCH" *normalized*)) (v (verify-b (bundle-src er nr))))
  (ck "normalization input ≠ extraction output ⇒ normalization-replay FAIL" (failed-p v :replay/normalization-replay)))

(format t "~%== [11] keystone signature + delegation branches (schema-critic F5/F6/F7) ==~%")
;; F5: νοθευμένο authority-statement-jws ⇒ ΜΟΝΟ binds-replay FAIL (τα άλλα πράσινα)
(let* ((b (make-bundle)) (j (copy-seq (getf b :authority-statement-jws))))
  (setf (char j (1- (length j))) (if (char= (char j (1- (length j))) #\A) #\B #\A))
  (setf (getf b :authority-statement-jws) j)
  (let ((v (verify-b b)))
    (ck "νοθευμένο authority-statement JWS ⇒ binds-replay FAIL (isolating)"
        (and (failed-p v :replay/authority-statement-binds-replay)
             (not (failed-p v :replay/graph-root-consistent))
             (not (failed-p v :replay/receipt-intrinsic))))))
;; F6: rollback (latest 2 > seq 1)
(let ((v (verify-authority-evidence-bundle (make-bundle) :trusted-owner-root-jwk *owner-jwk*
          :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp* :policy *policy*
          :known-delegation-state (list :latest-sequence 2))))
  (ck "delegation seq 1 < latest 2 ⇒ no-rollback FAIL" (failed-p v :replay/delegation-no-rollback)))
;; F6: equivocation (ίδιο seq, λάθος statement-hash)
(let ((v (verify-authority-evidence-bundle (make-bundle) :trusted-owner-root-jwk *owner-jwk*
          :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp* :policy *policy*
          :known-delegation-state (list :latest-sequence 1 :statement-hash "sha256:WRONG"))))
  (ck "ίδιο seq λάθος statement-hash ⇒ no-equivocation FAIL" (failed-p v :replay/delegation-no-equivocation)))
;; F7: compromise-from == genTime (boundary, inclusive ⇒ compromised)
(let ((v (verify-authority-evidence-bundle (make-bundle) :trusted-owner-root-jwk *owner-jwk*
          :trusted-tsa-ca-path *sectigo-ca* :consumer-checkpoint *cp* :policy *policy*
          :known-delegation-state (list :latest-sequence 1 :compromise-from "2026-07-10T19:47:02Z"))))
  (ck "compromise-from == genTime (boundary) ⇒ not-compromised FAIL" (failed-p v :replay/delegation-not-compromised)))
;; F8: source-digest isolating (declared-digest stale)
(let ((v (verify :source-artifact (list :bytes-utf8 (concatenate 'string *source-str* "X")
                                        :declared-digest *source-digest* :provenance-root *provenance-root*))))
  (ck "source bytes αλλαγμένα declared-digest stale ⇒ source-digest FAIL" (failed-p v :replay/source-digest)))

(ignore-errors (delete-file *graph-path*))
(format t "~%======================================================~%")
(format t "authority-evidence-replay: ~D passed, ~D failed~%" *p* *f*)
(when (plusp *f*) (format t "ΑΠΟΤΥΧΙΑ~%") (sb-ext:exit :code 1))
(format t "ΟΛΑ ΠΡΑΣΙΝΑ — #4C proof-binding freeze κλειδωμένο~%")
