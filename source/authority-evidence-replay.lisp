;;;; source/authority-evidence-replay.lisp
;;;; ============================================================================
;;;; [0088 Φ7-HARDENING #4B] AUTHORITY EVIDENCE REPLAY — ο ΠΛΗΡΗΣ δεύτερης
;;;; βαθμίδας verifier: ΔΕΝ εμπιστεύεται bundle-declared graph_root/journal_seq/
;;;; content hashes — τα ΞΑΝΑΠΑΡΑΓΕΙ από τα πραγματικά τεκμήρια.
;;;; ============================================================================
;;;; Το #4A (verify-authority-proof-bundle) είναι cryptographic release-envelope
;;;; verifier — δηλώνει ρητά ότι ΔΕΝ έχει journal. Το #4B κλείνει αυτό το κενό:
;;;; ανακατασκευάζει τον γράφο ΑΠΟ ΤΑ ΑΚΡΙΒΗ journal bytes, ξανατρέχει
;;;; verify-receipt-intrinsic ΠΑΝΩ στον reconstructed graph, επανυπολογίζει το
;;;; TRA canonical payload/hash ΚΑΙ την temporal έκβαση από τον γράφο, και
;;;; επανυπολογίζει το source artifact digest από τα ίδια τα bytes.
;;;;
;;;; ΚΛΕΙΣΤΟ VERSIONED SCHEMA: authority-proof-bundle/1 — άγνωστο/απόν πεδίο ⇒
;;;; ΣΦΑΛΜΑ (καμία σιωπηλή ανοχή). bundle_id = canonical hash ΟΛΟΚΛΗΡΟΥ του
;;;; evidence (πλην του ίδιου).
;;;;
;;;; ΤΙΜΙΟΤΗΤΑ (supreme law): κάθε βήμα recompute-and-compare· ΚΑΝΕΝΑ trusted
;;;; declared root· ΟΛΟ το replay hermetic (bundle-supplied bytes σε temp body,
;;;; load-graph με πλήρη payload/chain/semantic verification — byte tamper ⇒
;;;; journal-corruption). Ο signed authority-statement δεσμεύει ΟΛΕΣ τις ρίζες.

(defpackage :orchestrator.authority-evidence-replay
  (:use :cl)
  (:nicknames :orchestrator.apb-replay)
  (:local-nicknames (:apb :orchestrator.authority-proof-bundle)
                    (:vg :orchestrator.version-graph)
                    (:lr :orchestrator.legal-receipt)
                    (:canon :orchestrator.canonical-representation)
                    (:merkle :orchestrator.merkle)
                    (:jws :orchestrator.jws-authority)
                    (:paths :orchestrator.paths))
  (:export
   #:+authority-statement-tag+
   #:canonical-authority-statement
   #:bundle-id
   #:validate-bundle-schema
   #:reconstruct-graph-from-journal-bytes
   #:aer-verdict #:aer-verdict-p
   #:aer-awarded-tier #:aer-satisfies-policy-p #:aer-reasons #:aer-predicates
   #:aer-replayed-graph-root #:aer-replayed-graph-seq #:aer-recomputed-tra-hash
   #:verify-authority-evidence-bundle))

(in-package :orchestrator.authority-evidence-replay)

;;; ============================================================================
;;; ΚΛΕΙΣΤΟ SCHEMA authority-proof-bundle/1
;;; ============================================================================

(defparameter +bundle-protocol+ "lawmax/authority-proof-bundle/1")

(defparameter +bundle-required-keys+
  '(:protocol :corpus-id :body-id :release-id :release-generation :delegation-scope
    :envelope :source-artifact :extraction-receipt :normalization-receipt
    :receipt :receipt-membership :journal-bytes :census :release-manifest
    :verifier-binaries :tra :authority-statement-jws)
  "Το ΑΚΡΙΒΕΣ σύνολο top-level κλειδιών του authority-proof-bundle/1 — ούτε
   λιγότερα (missing evidence) ούτε περισσότερα (unknown ⇒ πιθανό smuggling).")

(defun %g (obj key)
  (cond ((null obj) nil)
        ((hash-table-p obj) (gethash key obj))
        ((and (consp obj) (keywordp (car obj))) (getf obj key))
        ((consp obj) (cdr (assoc key obj :test #'equal)))
        (t nil)))

(defun %bundle-keys (bundle)
  (cond ((and (consp bundle) (keywordp (car bundle)))
         (loop for (k) on bundle by #'cddr collect k))
        (t (error "authority-proof-bundle/1: το bundle πρέπει να είναι plist"))))

(defun validate-bundle-schema (bundle)
  "Fail-closed κλειστό schema: ΑΚΡΙΒΩΣ +bundle-required-keys+, καμία απουσία,
   κανένα άγνωστο. Επιστρέφει T ή σηματοδοτεί error με ονομαστικό λόγο."
  (unless (equal (%g bundle :protocol) +bundle-protocol+)
    (error "authority-proof-bundle: πρωτόκολλο ~S ≠ ~S" (%g bundle :protocol) +bundle-protocol+))
  (let* ((present (%bundle-keys bundle))
         (missing (set-difference +bundle-required-keys+ present))
         (unknown (set-difference present +bundle-required-keys+)))
    (when missing (error "authority-proof-bundle: ΛΕΙΠΟΥΝ κλειδιά ~S" missing))
    (when unknown (error "authority-proof-bundle: ΑΓΝΩΣΤΑ κλειδιά ~S (schema κλειστό)" unknown))
    t))

(defun bundle-id (bundle)
  "Ντετερμινιστική ταυτότητα ΟΛΟΚΛΗΡΟΥ του evidence (πλην journal-bytes/envelope
   opaque blobs, που δεσμεύονται μέσω των hashes τους) — canonical hash."
  (canon:canonical-hash
   (list (cons "protocol" (%g bundle :protocol))
         (cons "corpus_id" (%g bundle :corpus-id))
         (cons "body_id" (%g bundle :body-id))
         (cons "release_id" (%g bundle :release-id))
         (cons "journal_sha256" (%sha256-hex-of-string (%g bundle :journal-bytes)))
         (cons "authority_statement_jws" (%g bundle :authority-statement-jws)))))

;;; ============================================================================
;;; SIGNED AUTHORITY-STATEMENT (point 7) — δεσμεύει ΟΛΕΣ τις ρίζες
;;; ============================================================================

(defparameter +authority-statement-tag+ "lawmax/authority-statement/1")

(defun canonical-authority-statement (&key protocol corpus-id body-id release-id
                                           release-generation delegation-scope
                                           release-root census-root receipt-set-root
                                           source-provenance-root graph-root graph-seq
                                           graph-known-at tra-hash verifier-set-root
                                           tlog-tree-size tlog-root tlog-leaf-index
                                           policy-digest)
  "Ο ΚΑΝΟΝΙΚΟΣ authority-statement που ΥΠΟΓΡΑΦΕΙ το delegated release key. Δεσμεύει
   ΟΛΑ τα σημεία της αλυσίδας (schema/corpus/body/release/scope/όλες οι ρίζες/
   graph cut/TRA hash/verifier-set root/tlog ταυτότητα/policy digest). Reuse της
   ΜΙΑΣ έδρας canonical δήλωσης του #4A (apb:canonical-statement-string)."
  (flet ((s (x) (if (null x) "" (princ-to-string x))))
    (apb:canonical-statement-string
     +authority-statement-tag+
     (list (cons "protocol" (s protocol))
           (cons "corpus_id" (s corpus-id))
           (cons "body_id" (s body-id))
           (cons "release_id" (s release-id))
           (cons "release_generation" (s release-generation))
           (cons "delegation_scope" (s delegation-scope))
           (cons "release_root" (s release-root))
           (cons "census_root" (s census-root))
           (cons "receipt_set_root" (s receipt-set-root))
           (cons "source_provenance_root" (s source-provenance-root))
           (cons "graph_root" (s graph-root))
           (cons "graph_seq" (s graph-seq))
           (cons "graph_known_at" (s graph-known-at))
           (cons "tra_hash" (s tra-hash))
           (cons "verifier_set_root" (s verifier-set-root))
           (cons "tlog_tree_size" (s tlog-tree-size))
           (cons "tlog_root" (s tlog-root))
           (cons "tlog_leaf_index" (s tlog-leaf-index))
           (cons "policy_digest" (s policy-digest))))))

;;; ============================================================================
;;; HELPERS
;;; ============================================================================

(defun %sha256-hex-of-string (s)
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string
           (ironclad:digest-sequence :sha256 (babel:string-to-octets s :encoding :utf-8)))))

(defun %sha256-hex-of-bytes (bytes)
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 bytes))))

(defun %rsa-key-from-jwk (jwk)
  (ironclad:make-public-key
   :rsa
   :n (ironclad:octets-to-integer (jws:base64url-decode (%g jwk "n")))
   :e (ironclad:octets-to-integer (jws:base64url-decode (%g jwk "e")))))

(defvar *replay-counter* 0
  "Μονότονος μετρητής ανά process — μαζί με fresh random state δίνει ΜΟΝΑΔΙΚΟ
   nonce ανά κλήση (θάνατος concurrency collision).")
(defvar *replay-rs* (make-random-state t)
  "Fresh random state (entropy-seeded) — cross-process nonce uniqueness παρά το
   deterministic SOURCE_DATE_EPOCH.")

(defun reconstruct-graph-from-journal-bytes (journal-bytes)
  "HERMETIC replay: γράφει τα bundle-supplied journal bytes σε ΜΟΝΑΔΙΚΟ (nonce)
   ephemeral body και τα φορτώνει με load-graph (ΠΛΗΡΗΣ payload/chain/semantic
   verification ανά γραμμή — byte tamper ⇒ journal-corruption). [provenance-critic-2
   F3] nonce ανά κλήση ⇒ καμία concurrency collision με άλλες επαληθεύσεις ή με
   πραγματικά corpus bodies· ΣΕ ΑΠΟΤΥΧΙΑ load-graph το αρχείο ΔΙΑΓΡΑΦΕΤΑΙ ΕΔΩ
   (θάνατος leak στο tamper path). Επιστρέφει (values graph path)· ο caller
   διαγράφει το path στο unwind-protect μετά το πέρας του replay."
  (let* ((nonce (format nil "apbreplay-~A-~A-~A"
                        (incf *replay-counter*) (random (expt 2 48) *replay-rs*)
                        (ironclad:byte-array-to-hex-string
                         (ironclad:digest-sequence
                          :sha256 (babel:string-to-octets journal-bytes :encoding :utf-8)))))
         (path (vg::vg-path (vg:make-graph nonce))))
    (ensure-directories-exist path)
    (with-open-file (s path :direction :output :if-exists :supersede
                            :if-does-not-exist :create :external-format :utf-8)
      (write-string journal-bytes s))
    (handler-case (values (vg:load-graph nonce) path)
      (error (e) (ignore-errors (delete-file path)) (error e)))))

(defun %rebuild-receipt (alist)
  "Ανακατασκευή του legal-authority-receipt struct ΑΠΟ την canonical alist μορφή
   του bundle. Το verify-receipt-intrinsic θα ΞΑΝΑΫΠΟΛΟΓΙΣΕΙ το receipt-id από
   αυτόν — άρα λάθος rebuild ⇒ receipt-id mismatch (fail-closed)."
  (let* ((cut (%g alist "cut"))
         (comm (%g alist "commencement"))
         (kw (lambda (s) (intern (string-upcase s) :keyword))))
    (lr::make-legal-authority-receipt
     :receipt-id (%g alist "receipt_id")
     :provision-id (%g alist "provision_id")
     :commencement (list (funcall kw (%g comm "type")) (%g comm "value"))
     :source-artifact (%g alist "source_artifact")
     :derivation (%g alist "derivation")
     :valid-until (let ((v (%g alist "valid_until"))) (if (equal v "open") :open v))
     :recorded-from (%g alist "recorded_from")
     :recorded-until (let ((v (%g alist "recorded_until"))) (if (equal v "current") :current v))
     :genealogy (%g alist "genealogy")
     :content-hash (%g alist "content_hash")
     :previous-version-hash (%g alist "previous_version_hash")
     :release-generation (let ((v (%g alist "release_generation")))
                           (if (equal v "unreleased") :unreleased v))
     :assurance (funcall kw (%g alist "assurance"))
     :trust-status (funcall kw (%g alist "trust_status"))
     :cut-graph-root (%g cut "graph_root")
     :cut-journal-seq (%g cut "journal_seq")
     :cut-known-at (%g cut "known_at")
     :effectivity (%g alist "effectivity"))))

(defun %reconstruct-anchor (tra)
  "Ανακατασκευή του opaque release-anchor ΑΠΟ τα anchor πεδία του TRA, ώστε το
   make-effectivity-attestation να ξαναπαραχθεί ΑΚΡΙΒΩΣ (recompute TRA)."
  (if (equal (%g tra :anchor-kind) "verified")
      (vg::%make-verified-anchor
       :assurance (%g tra :assurance) :release-root (%g tra :release-root)
       :reasons (%g tra :anchor-reasons)
       :tlog-size (%g tra :tlog-size) :tlog-root (%g tra :tlog-root)
       :registry-digest (%g tra :registry-digest) :verifier-hash (%g tra :verifier-hash))
      (vg:make-provisional-anchor :reasons (%g tra :anchor-reasons)
                                  :verifier-hash (%g tra :verifier-hash))))

;;; ============================================================================
;;; TYPED VERDICT
;;; ============================================================================

(defstruct (aer-verdict (:conc-name aer-) (:copier nil) (:constructor %make-aer-verdict))
  (awarded-tier "provisional-unanchored" :type string :read-only t)
  (satisfies-policy-p nil :read-only t)
  (reasons '() :type list :read-only t)
  (predicates '() :type list :read-only t)
  (replayed-graph-root nil :read-only t)
  (replayed-graph-seq nil :read-only t)
  (recomputed-tra-hash nil :read-only t)
  (authentication-mode nil :read-only t))   ; :first-seen | :continuity-verified

;;; ============================================================================
;;; Η ΜΙΑ ΕΙΣΟΔΟΣ
;;; ============================================================================

(defun verify-authority-evidence-bundle (bundle &key trusted-owner-root-jwk
                                                     trusted-owner-thumbprint
                                                     trusted-tsa-ca-path
                                                     known-revocations
                                                     known-delegation-state
                                                     consumer-checkpoint policy)
  "Ο ΠΛΗΡΗΣ authority evidence replay verifier. Επαληθεύει (α) το cryptographic
   envelope μέσω #4A (apb:verify-authority-proof-bundle στο :envelope) ΚΑΙ (β)
   την ΠΡΑΓΜΑΤΙΚΗ provenance/journal/receipt/TRA με ΑΝΑΚΑΤΑΣΚΕΥΗ — ΚΑΝΕΝΑ
   declared root δεν γίνεται δεκτό. Το trusted root/pin/TSA δίνονται ΕΞΩΘΕΝ.
   KNOWN-DELEGATION-STATE (plist :latest-sequence :statement-hash :compromise-from)
   = external anti-rollback/equivocation. Επιστρέφει aer-verdict."
  (validate-bundle-schema bundle)
  (let ((preds '()) (reasons '()) (graph-root nil) (graph-seq nil)
        (tra-hash nil) (auth-mode :first-seen) (tmp-path nil))
    (labels ((pred (name ok &optional detail)
               (push (list* name (and ok t) detail) preds)
               (unless ok (push name reasons)) (and ok t))
             (safe (name thunk)
               (handler-case (pred name (funcall thunk))
                 (error (e) (pred name nil (princ-to-string e))))))
      (unwind-protect
        (let* ((stmt-jws (%g bundle :authority-statement-jws))
               (envelope (%g bundle :envelope))
               (release-jwk (%g envelope :release-jwk))
               (scope (%g bundle :delegation-scope))
               (corpus-id (%g bundle :corpus-id))
               (body-id (%g bundle :body-id))
               (census (%g envelope :census))
               (cut (%g envelope :cut))
               (tlog (%g envelope :tlog))
               (src (%g bundle :source-artifact))
               (tra (%g bundle :tra))
               ;; ── ΑΝΑΚΑΤΑΣΚΕΥΗ ΓΡΑΦΟΥ ΑΠΟ ΤΑ ΑΚΡΙΒΗ JOURNAL BYTES ──
               (rgraph
                 (handler-case
                     (multiple-value-bind (g p)
                         (reconstruct-graph-from-journal-bytes (%g bundle :journal-bytes))
                       (setf tmp-path p) g)
                   (error (e) (pred :replay/journal-integrity nil (princ-to-string e)) nil))))

          ;; E0: envelope (#4A) — cryptographic release-envelope
          (safe :evidence/envelope
                (lambda ()
                  (let ((v (apb:verify-authority-proof-bundle
                            envelope
                            :trusted-owner-root-jwk trusted-owner-root-jwk
                            :trusted-owner-thumbprint trusted-owner-thumbprint
                            :trusted-tsa-ca-path trusted-tsa-ca-path
                            :known-revocations known-revocations
                            :consumer-checkpoint consumer-checkpoint
                            :policy policy)))
                    (and (apb:apb-satisfies-policy-p v)
                         (apb:tier>= (apb:apb-awarded-tier v) "owner-pinned-authenticated")))))

          (when rgraph
            (pred :replay/journal-integrity t)
            (setf graph-root (vg:graph-chain-head rgraph)
                  graph-seq (vg:graph-seq rgraph)))

          ;; ── SIGNED AUTHORITY-STATEMENT: δεσμεύει ΟΛΕΣ τις ρίζες + το REPLAYED
          ;;    graph_root (ΟΧΙ το declared) ──
          (safe :replay/authority-statement-binds-replay
                (lambda ()
                  (and graph-root release-jwk stmt-jws
                       (let ((astmt (canonical-authority-statement
                                     :protocol +bundle-protocol+
                                     :corpus-id corpus-id :body-id body-id
                                     :release-id (%g bundle :release-id)
                                     :release-generation (%g bundle :release-generation)
                                     :delegation-scope scope
                                     :release-root (%g envelope :release-root)
                                     :census-root (%g census :graph-root)
                                     :receipt-set-root (%g census :receipt-set-root)
                                     :source-provenance-root (%g src :provenance-root)
                                     ;; ΤΟ REPLAYED graph_root/seq — όχι το declared
                                     :graph-root graph-root :graph-seq graph-seq
                                     :graph-known-at (%g cut :known-at)
                                     :tra-hash (%g tra :hash)
                                     :verifier-set-root (%merkle-of (%g envelope :verifier-set))
                                     :tlog-tree-size (%g tlog :tree-size)
                                     :tlog-root (%g tlog :root)
                                     :tlog-leaf-index (%g tlog :leaf-index)
                                     :policy-digest (%g policy :policy-digest))))
                         (jws:verify-jws stmt-jws astmt (%rsa-key-from-jwk release-jwk))))))

          ;; ── ΔΕΣΜΟΣ REPLAY↔DECLARED: ο replayed graph_root ΠΡΕΠΕΙ να ταυτίζεται
          ;;    με census/cut/receipt cut graph_root ΚΑΙ ο replayed seq με το cut seq.
          ;;    Χωρίς αυτό, forged-but-self-consistent envelope census root θα ξέφευγε
          ;;    (το #4A δεν έχει journal — εδώ δένεται στην ΑΝΑΚΑΤΑΣΚΕΥΗ).
          (safe :replay/graph-root-consistent
                (lambda ()
                  (and graph-root graph-seq
                       (equal graph-root (%g census :graph-root))
                       (equal graph-root (%g cut :graph-root))
                       (equal graph-seq (%g cut :journal-seq))
                       (equal graph-root (%g (%g (%g bundle :receipt) "cut") "graph_root"))
                       (equal graph-seq (%g (%g (%g bundle :receipt) "cut") "journal_seq")))))

          ;; ── SOURCE ARTIFACT: recompute digest ΑΠΟ ΤΑ BYTES + spans εντός ──
          (safe :replay/source-digest
                (lambda ()
                  (let* ((bytes (%source-bytes src))
                         (dig (%sha256-hex-of-bytes bytes)))
                    (and (equal dig (%g src :declared-digest))
                         ;; δέσιμο στο receipt: το receipt source_artifact content_sha256
                         (equal dig (%g (%g (%g bundle :receipt) "source_artifact")
                                        "content_sha256"))))))
          (safe :replay/source-spans-within
                (lambda ()
                  (let ((len (length (%source-bytes src))))
                    (every (lambda (span)
                             (let ((a (%g span :start)) (b (%g span :end)))
                               (and (integerp a) (integerp b) (<= 0 a b len))))
                           (%g src :spans)))))
          ;; extraction/normalization receipts δεσμεύονται στο source provenance root
          (safe :replay/provenance-chain
                (lambda ()
                  (let ((proot (%g src :provenance-root)))
                    (and (stringp proot)
                         (equal proot
                                (%merkle-of
                                 (list (%sha256-hex-of-bytes (%source-bytes src))
                                       (%g (%g bundle :extraction-receipt) :digest)
                                       (%g (%g bundle :normalization-receipt) :digest))))))))

          ;; ── RECEIPT: rebuild + verify-receipt-intrinsic ΣΤΟΝ RECONSTRUCTED GRAPH ──
          (safe :replay/receipt-intrinsic
                (lambda ()
                  (and rgraph
                       (let ((rc (%rebuild-receipt (%g bundle :receipt))))
                         (multiple-value-bind (ok why) (lr:verify-receipt-intrinsic rgraph rc)
                           (declare (ignore why))
                           ok)))))
          ;; receipt membership στο SIGNED receipt-set-root (όχι declared)
          (safe :replay/receipt-membership
                (lambda ()
                  (let* ((ids (%g census :receipt-ids))
                         (idx (%g (%g bundle :receipt-membership) :index))
                         (rid (%g (%g bundle :receipt) "receipt_id")))
                    (and (integerp idx) (< -1 idx (length ids)) (equal (nth idx ids) rid)
                         (equal (%g census :receipt-set-root) (merkle:merkle-root-of-strings ids))
                         (merkle:verify-inclusion
                          (merkle:hash-leaf-string rid)
                          (merkle:inclusion-path (mapcar #'merkle:hash-leaf-string ids) idx)
                          (%g census :receipt-set-root))))))

          ;; ── TRA: recompute canonical payload/hash + OUTCOME από τον γράφο ──
          (safe :replay/tra-recompute
                (lambda ()
                  (and rgraph
                       (let* ((anchor (%reconstruct-anchor tra))
                              (recomputed
                                (vg:make-effectivity-attestation
                                 rgraph (%g tra :provision)
                                 :valid-at (%g tra :valid-at) :known-at (%g tra :known-at)
                                 :corpus-id (%g tra :corpus-id) :anchor anchor
                                 :receipt-id (%g tra :receipt-id))))
                         (setf tra-hash (getf recomputed :hash))
                         ;; ΤΟ HASH ΞΑΝΑΒΓΑΙΝΕΙ από τον reconstructed graph — η απλή
                         ;; ισότητα committed-content ΔΕΝ αρκεί (recompute outcome)
                         (and (equal tra-hash (%g tra :hash))
                              (equal (getf recomputed :outcome) (%g tra :outcome)))))))

          ;; ── VERIFIER BINARIES: το verifier-set string ΔΕΝΕΤΑΙ στα ΠΡΑΓΜΑΤΙΚΑ
          ;;    verifier bytes — sha256(bytes) ΞΑΝΑΫΠΟΛΟΓΙΖΕΤΑΙ ΕΔΩ (provenance-
          ;;    critic-2 F2: ο declared :sha256 ΔΕΝ γίνεται δεκτός· recompute ==
          ;;    declared == required verifier hash της policy). ΚΑΘΕ binary bytes
          ;;    ⇒ digest· κανένα binary χωρίς bytes ⇒ ΣΦΑΛΜΑ.
          (safe :replay/verifier-binaries-bind
                (lambda ()
                  (let ((req (%g policy :temporal-verifier-hash))
                        (bins (%g bundle :verifier-binaries)))
                    (and (stringp req) (consp bins)
                         (some (lambda (b)
                                 (let ((declared (%g b :sha256))
                                       (recomputed (%sha256-hex-of-bytes (%binary-bytes b))))
                                   (and (equal declared recomputed) (equal req recomputed))))
                               bins)))))

          ;; ── SCOPE: το delegation scope ΚΑΛΥΠΤΕΙ το corpus/release ──
          (safe :replay/scope-covers-corpus
                (lambda () (%scope-covers-p scope corpus-id body-id)))

          ;; ── EXTERNAL DELEGATION STATE: rollback/equivocation rejection ──
          (when known-delegation-state
            (safe :replay/delegation-no-rollback
                  (lambda ()
                    (let ((seq (%delegation-sequence envelope))
                          (latest (%g known-delegation-state :latest-sequence)))
                      (and (integerp seq) (integerp latest) (>= seq latest)))))
            (safe :replay/delegation-no-equivocation
                  (lambda ()
                    ;; ίδιο sequence με ΔΙΑΦΟΡΕΤΙΚΟ statement hash ⇒ equivocation
                    (let ((seq (%delegation-sequence envelope))
                          (latest (%g known-delegation-state :latest-sequence))
                          (khash (%g known-delegation-state :statement-hash)))
                      (or (not (eql seq latest)) (null khash)
                          (equal khash (%delegation-statement-hash envelope)))))))

          ;; ── TRANSPARENCY: first-seen vs continuity-verified ──
          (setf auth-mode (if consumer-checkpoint :continuity-verified :first-seen))

          ;; ── ΑΠΟΝΟΜΗ ──
          (let* ((all-ok (every #'cadr preds))
                 (required (%g policy :required-tier))
                 ;; [provenance-critic-2 F4] first-seen vs continuity ΟΥΣΙΑΣΤΙΚΗ,
                 ;; όχι διακοσμητική: το ΑΝΩΤΑΤΟ owner-pinned-authenticated απαιτεί
                 ;; ΚΑΙ ΟΛΟ το replay ΚΑΙ continuity (consumer checkpoint — ο
                 ;; καταναλωτής έχει επαληθεύσει append-only συνέχεια). Χωρίς
                 ;; checkpoint (first-seen) το bundle μπορεί να είναι fork που ο
                 ;; καταναλωτής δεν έχει δει — cap σε internally-release-consistent.
                 (tier (cond ((and all-ok (eq auth-mode :continuity-verified))
                              "owner-pinned-authenticated")
                             (all-ok "internally-release-consistent")   ; first-seen
                             (t "provisional-unanchored"))))
            (%make-aer-verdict
             :awarded-tier tier
             :satisfies-policy-p (or (null required) (apb:tier>= tier required))
             :reasons (nreverse reasons) :predicates (nreverse preds)
             :replayed-graph-root graph-root :replayed-graph-seq graph-seq
             :recomputed-tra-hash tra-hash :authentication-mode auth-mode)))
        ;; cleanup temp journal
        (when (and tmp-path (probe-file tmp-path)) (ignore-errors (delete-file tmp-path)))))))

;;; ── βοηθητικά ──

(defun %merkle-of (strings)
  (if (and strings (consp strings)) (merkle:merkle-root-of-strings strings) ""))

(defun %binary-bytes (b)
  "Τα ΩΜΑ bytes ενός verifier binary — :bytes (octet vector) ή :bytes-utf8 (string).
   Απόν ⇒ ΣΦΑΛΜΑ (fail-closed — κανένα digest χωρίς bytes)."
  (let ((raw (%g b :bytes)) (s (%g b :bytes-utf8)))
    (cond ((typep raw '(vector (unsigned-byte 8))) raw)
          ((stringp s) (babel:string-to-octets s :encoding :utf-8))
          (t (error "verifier-binary: απόντα bytes")))))

(defun %source-bytes (src)
  "Τα ΩΜΑ bytes του source artifact — είτε :bytes (octet vector) είτε
   :bytes-utf8 (string). Απόν ⇒ ΣΦΑΛΜΑ (fail-closed)."
  (let ((b (%g src :bytes)) (s (%g src :bytes-utf8)))
    (cond ((typep b '(vector (unsigned-byte 8))) b)
          ((stringp s) (babel:string-to-octets s :encoding :utf-8))
          (t (error "source-artifact: απόντα bytes")))))

(defun %scope-covers-p (scope corpus-id body-id)
  "Το delegation scope ΚΑΛΥΠΤΕΙ ΡΗΤΑ το corpus/body. Μορφές: «*» (όλα),
   «corpus/<id>», «body/<id>», ή ακριβές corpus-id. Scope mismatch ⇒ NIL."
  (and (stringp scope)
       (or (string= scope "*")
           (equal scope corpus-id)
           (equal scope (format nil "corpus/~A" corpus-id))
           (equal scope (format nil "body/~A" body-id)))))

(defun %delegation-sequence (envelope)
  (let ((st (%g (%g envelope :delegation) :statement)))
    (cdr (assoc "sequence" st :test #'equal))))

(defun %delegation-statement-hash (envelope)
  (let ((st (%g (%g envelope :delegation) :statement)))
    (%sha256-hex-of-string
     (apb:canonical-statement-string "lawmax/trust/delegation/1" st))))
