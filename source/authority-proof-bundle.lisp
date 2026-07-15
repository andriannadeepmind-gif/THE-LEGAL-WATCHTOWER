;;;; source/authority-proof-bundle.lisp
;;;; ============================================================================
;;;; [0088 Φ7-HARDENING #4] Ο ΑΝΕΞΑΡΤΗΤΟΣ, HERMETIC, FAIL-CLOSED ΕΠΑΛΗΘΕΥΤΗΣ
;;;; ΑΛΥΣΙΔΑΣ ΕΞΟΥΣΙΑΣ — verify-authority-proof-bundle.
;;;; ============================================================================
;;;; Η ΜΙΑ έδρα δεύτερης βαθμίδας: δέχεται ΧΩΡΙΣΤΕΣ εισόδους
;;;;   (α) proof bundle (όλα τα τεκμήρια)·
;;;;   (β) trusted owner-root (Ed25519 JWK) Ή trusted RFC-7638 thumbprint·
;;;;   (γ) προηγούμενο consumer transparency checkpoint (όταν υπάρχει)·
;;;;   (δ) verification policy.
;;;; Η ΕΜΠΙΣΤΗ ΡΙΖΑ/ΤΟ PIN ΔΕΝ ΑΝΑΚΑΛΥΠΤΕΤΑΙ ΠΟΤΕ ΑΠΟ ΤΟ ΙΔΙΟ ΤΟ BUNDLE
;;;; (hermetic): το bundle ΔΕΝ μπορεί να αυτο-εξουσιοδοτηθεί.
;;;;
;;;; ΤΙΜΙΟΤΗΤΑ ΒΑΘΜΙΔΑΣ (Δ1–Δ5): κάθε assurance tier απονέμεται ΜΟΝΟ από
;;;; ΕΠΑΛΗΘΕΥΜΕΝΑ κατηγορήματα τεκμηρίων — ΠΟΤΕ από string/caller assertion.
;;;;   "internally-release-consistent" — τοπική συνέπεια release (JWS+census+
;;;;                                     receipt-set+tlog inclusion+TSR+verifier-set)·
;;;;   "owner-pinned-authenticated"    — + owner-root pin ταιριάζει + owner
;;;;                                     υπογράφει delegation + delegation έγκυρη
;;;;                                     ΣΤΟ genTime του TSR + όχι ανακληθείσα·
;;;;   "independently-witnessed"       — + επαληθευμένος 3ος μάρτυρας (Δ4:
;;;;                                     προαιρετικός· ΠΟΤΕ σε TEST/χωρίς μάρτυρα).
;;;;
;;;; Fail-closed: κάθε κατηγόρημα ανεξάρτητο· ΚΑΘΕ αποτυχία = ονομαστικός λόγος·
;;;; η απονεμόμενη βαθμίδα = η ΑΝΩΤΑΤΗ της οποίας ΟΛΟ το σύνολο κατηγορημάτων
;;;; πέρασε. Καμία σιωπηλή υποβάθμιση, κανένα LLM στο trusted path.

(defpackage :orchestrator.authority-proof-bundle
  (:use :cl)
  (:nicknames :orchestrator.apb)
  (:local-nicknames (:jws :orchestrator.jws-authority)
                    (:tsa :orchestrator.timestamp-authority)
                    (:merkle :orchestrator.merkle)
                    (:journal :orchestrator.journal))
  (:export
   ;; ── Ed25519 owner-root ταυτότητα (RFC 8037 OKP + RFC 7638 thumbprint) ──
   #:ed25519-public-from-jwk
   #:ed25519-public-to-jwk
   #:ed25519-jwk-thumbprint
   #:owner-sign-statement
   #:owner-verify-statement
   #:make-delegation-statement
   #:make-revocation-statement
   ;; ── typed verdict ──
   #:apb-verdict #:apb-verdict-p
   #:apb-awarded-tier #:apb-required-tier #:apb-satisfies-policy-p
   #:apb-reasons #:apb-predicates #:apb-gen-time #:apb-delegation-state
   ;; ── η ΜΙΑ είσοδος ──
   #:verify-authority-proof-bundle
   ;; ── κλειστή taxonomy βαθμίδων ──
   #:+apb-assurance-tiers+ #:tier>=))

(in-package :orchestrator.authority-proof-bundle)

;;; ============================================================================
;;; ΚΛΕΙΣΤΗ TAXONOMY ΒΑΘΜΙΔΩΝ — ΔΙΑΤΕΤΑΓΜΕΝΗ (χαμηλή → υψηλή)
;;; ============================================================================

(defparameter +apb-assurance-tiers+
  '("provisional-unanchored"
    "internally-release-consistent"
    "owner-pinned-authenticated"
    "independently-witnessed")
  "Η κλειστή, ΔΙΑΤΕΤΑΓΜΕΝΗ λίστα βαθμίδων — ΙΔΙΑ έδρα με version-graph
   +anchor-assurance-taxonomy+ (η σειρά εδώ κωδικοποιεί την ισχύ).")

(defun tier-rank (tier)
  (or (position tier +apb-assurance-tiers+ :test #'equal)
      (error "apb: άγνωστη βαθμίδα ~S εκτός taxonomy" tier)))

(defun tier>= (a b)
  "T ανν η βαθμίδα A είναι τουλάχιστον τόσο ισχυρή όσο η B."
  (>= (tier-rank a) (tier-rank b)))

;;; ============================================================================
;;; ΚΑΝΟΝΙΚΗ ΣΕΙΡΙΟΠΟΙΗΣΗ ΥΠΟΓΡΑΦΟΜΕΝΩΝ ΔΗΛΩΣΕΩΝ (domain-separated)
;;; ============================================================================
;;; Ντετερμινιστική, χωρίς JSON-escaping αμφισημία: tag \x1e + για κάθε key σε
;;; ΛΕΞΙΚΟΓΡΑΦΙΚΗ σειρά:  key \x1f value \x1e. Τα control bytes ΔΕΝ εμφανίζονται
;;; σε base64url/ISO/scope tokens ⇒ καμία σύγκρουση/ambiguity. ΕΝΑ tag ανά τύπο
;;; δήλωσης ⇒ cross-type replay (delegation ↔ revocation) δομικά αδύνατο.

(defun %no-separators-p (str)
  "T ανν το STR δεν περιέχει τα control separators #x1e/#x1f — εγγυάται
   ΔΟΜΙΚΑ την ενριξιμότητα (injectivity) της σειριοποίησης (crypto-critic M1:
   εξάλειψη της κλάσης σφάλματος, όχι φρουρός γύρω της)."
  (notany (lambda (c) (or (char= c (code-char #x1e)) (char= c (code-char #x1f))))
          str))

(defun %canonical-statement-string (tag alist)
  "Ντετερμινιστική κανονική σειριοποίηση: TAG \\x1e, μετά σε ΛΕΞΙΚΟΓΡΑΦΙΚΗ
   σειρά key \\x1f value \\x1e. FAIL-CLOSED (M1): κάθε key/value που περιέχει
   τα separators #x1e/#x1f ⇒ ΣΦΑΛΜΑ — η μη-σύγκρουση γίνεται δομική ιδιότητα,
   όχι ανεξέλεγκτη υπόθεση."
  (unless (%no-separators-p tag)
    (error "canonical-statement: tag περιέχει separator control byte"))
  (let ((sorted (sort (copy-seq alist) #'string< :key #'car)))
    (with-output-to-string (s)
      (write-string tag s) (write-char (code-char #x1e) s)
      (dolist (kv sorted)
        (let ((k (car kv)) (v (princ-to-string (cdr kv))))
          (unless (and (%no-separators-p k) (%no-separators-p v))
            (error "canonical-statement: πεδίο ~S περιέχει separator control byte" k))
          (write-string k s) (write-char (code-char #x1f) s)
          (write-string v s) (write-char (code-char #x1e) s))))))

(defun %canonical-statement-octets (tag alist)
  (babel:string-to-octets (%canonical-statement-string tag alist) :encoding :utf-8))

(defparameter +delegation-tag+ "lawmax/trust/delegation/1")
(defparameter +revocation-tag+ "lawmax/trust/revocation/1")
(defparameter +release-statement-tag+ "lawmax/trust/release-statement/1")

(defun %canonical-verifier-set (verifier-set)
  "Ντετερμινιστική, ΕΝΡΙΞΙΜΗ σειριοποίηση του verifier-set: length-prefixed
   ταξινομημένα tokens (crypto-critic-2 F3 — το comma-join ΔΕΝ ήταν injective:
   {\"a,b\"} και {\"a\",\"b\"} συνέπιπταν). Length-prefix ⇒ καμία σύγκρουση
   ανεξαρτήτως περιεχομένου· κάθε token ελέγχεται και για separators."
  (with-output-to-string (s)
    (dolist (tok (sort (copy-list (or verifier-set '())) #'string<))
      (let ((v (princ-to-string tok)))
        (unless (%no-separators-p v)
          (error "verifier-set token περιέχει separator control byte"))
        (format s "~D:~A;" (length v) v)))))

(defun %canonical-release-statement (&key release-root graph-root receipt-set-root
                                          content-text-sha256 content-version-hash
                                          cut-graph-root cut-journal-seq cut-known-at
                                          verifier-set tlog-root tlog-tree-size
                                          tlog-leaf-index)
  "Η ΚΑΝΟΝΙΚΗ δήλωση release που ΥΠΟΓΡΑΦΕΙ το delegated release key (RC1). ΔΕΝΕΙ
   τον anchored release-root ΜΑΖΙ ΜΕ census/receipt-set/content/cut/verifier-set
   ΚΑΙ την ταυτότητα του transparency log (tlog root/tree_size/leaf_index —
   provenance-critic-2 C1: χωρίς αυτό ο tlog root ήταν αδέσμευτος ⇒ RC6 vacuous
   χωρίς checkpoint). Κανένα πεδίο ελεύθερα αντικαταστάσιμο (το commitment edge).
   [crypto-critic-2 S4] ΟΛΕΣ οι τιμές σειριοποιούνται ΡΗΤΑ ως strings (format
   ~A) — καμία type-collision int/string/symbol στη δεσμευμένη μορφή."
  (flet ((s (x) (if (null x) "" (princ-to-string x))))
    (%canonical-statement-string
     +release-statement-tag+
     (list (cons "content_text_sha256" (s content-text-sha256))
           (cons "content_version_hash" (s content-version-hash))
           (cons "cut_graph_root" (s cut-graph-root))
           (cons "cut_journal_seq" (s cut-journal-seq))
           (cons "cut_known_at" (s cut-known-at))
           (cons "graph_root" (s graph-root))
           (cons "receipt_set_root" (s receipt-set-root))
           (cons "release_root" (s release-root))
           (cons "tlog_leaf_index" (s tlog-leaf-index))
           (cons "tlog_root" (s tlog-root))
           (cons "tlog_tree_size" (s tlog-tree-size))
           (cons "verifier_set" (%canonical-verifier-set verifier-set))))))

;;; ============================================================================
;;; Ed25519 OKP JWK (RFC 8037) + RFC 7638 THUMBPRINT
;;; ============================================================================
;;; Ο δημόσιος thumbprint είναι η ΤΑΥΤΟΤΗΤΑ της owner root — παράγεται ΑΠΟ το
;;; κλειδί (τίμια προέλευση), ΠΟΤΕ δηλωμένος ως αυθαίρετο brand string.

(defun %jwk-field (jwk key)
  (cond ((hash-table-p jwk) (gethash key jwk))
        ((consp jwk) (or (cdr (assoc key jwk :test #'equal))
                         (getf jwk (intern (string-upcase key) :keyword))))))

(defun ed25519-public-from-jwk (jwk)
  "OKP/Ed25519 JWK → ironclad Ed25519 ΔΗΜΟΣΙΟ κλειδί. Fail-closed: λάθος
   kty/crv/μήκος x ⇒ ΣΦΑΛΜΑ (ποτέ σιωπηλά ανεκτό)."
  (let ((kty (%jwk-field jwk "kty")) (crv (%jwk-field jwk "crv"))
        (x (%jwk-field jwk "x")))
    (unless (equal kty "OKP")
      (error "ed25519 jwk: kty=~S ≠ OKP" kty))
    (unless (equal crv "Ed25519")
      (error "ed25519 jwk: crv=~S ≠ Ed25519" crv))
    (unless (stringp x)
      (error "ed25519 jwk: απόν/μη-string x"))
    (let ((y (jws:base64url-decode x)))
      (unless (= 32 (length y))
        (error "ed25519 jwk: x = ~D bytes ≠ 32" (length y)))
      (ironclad:make-public-key :ed25519 :y y))))

(defun ed25519-public-to-jwk (public-key)
  "ironclad Ed25519 ΔΗΜΟΣΙΟ κλειδί → κανονικό OKP JWK alist."
  (list (cons "crv" "Ed25519")
        (cons "kty" "OKP")
        (cons "x" (jws:base64url-encode (ironclad:ed25519-key-y public-key)))))

(defun ed25519-jwk-thumbprint (public-key-or-jwk)
  "RFC 7638 JWK thumbprint OKP: base64url(SHA-256({\"crv\":\"Ed25519\",
   \"kty\":\"OKP\",\"x\":…})) — ΑΚΡΙΒΩΣ τα required members σε λεξικογραφική
   σειρά, χωρίς κενά (RFC 8037 §2). Δέχεται είτε ironclad key είτε JWK."
  (let* ((x-in (etypecase public-key-or-jwk
                 (cons (or (%jwk-field public-key-or-jwk "x")
                           (error "ed25519 thumbprint: JWK χωρίς x")))
                 (hash-table (%jwk-field public-key-or-jwk "x"))
                 (t (jws:base64url-encode
                     (ironclad:ed25519-key-y public-key-or-jwk)))))
         ;; επικύρωση μήκους ΚΑΙ στη διαδρομή JWK — 32 bytes ή ΣΦΑΛΜΑ
         (raw (jws:base64url-decode x-in))
         ;; [crypto-critic M2] ΕΠΑΝΑΚΑΝΟΝΙΚΟΠΟΙΗΣΗ του x: η ταυτότητα είναι
         ;; ανεξάρτητη της κωδικοποίησης εισόδου (padding/non-canonical bits) —
         ;; δύο κωδικοποιήσεις του ΙΔΙΟΥ κλειδιού ⇒ ΙΔΙΟΣ thumbprint.
         (x (jws:base64url-encode raw)))
    (unless (= 32 (length raw))
      (error "ed25519 thumbprint: x = ~D bytes ≠ 32" (length raw)))
    (let ((canonical (format nil "{\"crv\":\"Ed25519\",\"kty\":\"OKP\",\"x\":\"~A\"}" x)))
      (jws:base64url-encode
       (ironclad:digest-sequence :sha256
                                 (babel:string-to-octets canonical :encoding :utf-8))))))

;;; ── owner υπογραφή/επαλήθευση δήλωσης ──

(defun owner-sign-statement (secret-key tag alist)
  "Ed25519 υπογραφή της κανονικής δήλωσης (TAG,ALIST) → base64url signature."
  (jws:base64url-encode
   (ironclad:sign-message secret-key (%canonical-statement-octets tag alist))))

(defun owner-verify-statement (public-key tag alist signature-b64)
  "T ανν το SIGNATURE-B64 είναι έγκυρη Ed25519 υπογραφή του PUBLIC-KEY πάνω
   στην κανονική (TAG,ALIST). Fail-closed σε κακοσχηματισμένη υπογραφή."
  (handler-case
      (let ((sig (jws:base64url-decode signature-b64)))
        (and (= 64 (length sig))
             (ironclad:verify-signature
              public-key (%canonical-statement-octets tag alist) sig)))
    (error () nil)))

;;; ── κατασκευαστές δηλώσεων (χρησιμοποιούνται από ceremony/fixtures) ──

(defun make-delegation-statement (&key owner-root-thumbprint delegate-algorithm
                                       delegate-jwk-thumbprint scope
                                       not-before not-after sequence)
  "Κανονική delegation δήλωση (alist string→value). SEQUENCE = μονότονος
   ακέραιος (Δ3). Τα πεδία ΔΕΣΜΕΥΟΝΤΑΙ ΟΛΑ στην υπογραφή."
  (list (cons "delegate_algorithm" delegate-algorithm)
        (cons "delegate_jwk_thumbprint" delegate-jwk-thumbprint)
        (cons "not_after" not-after)
        (cons "not_before" not-before)
        (cons "owner_root_thumbprint" owner-root-thumbprint)
        (cons "scope" scope)
        (cons "sequence" sequence)))

(defun make-revocation-statement (&key owner-root-thumbprint revokes-sequence
                                       revokes-delegate-thumbprint revoked-at reason)
  "Κανονική revocation δήλωση. Ανακαλεί delegation με REVOKES-SEQUENCE (και,
   ρητά, το REVOKES-DELEGATE-THUMBPRINT) από το REVOKED-AT και μετά."
  (list (cons "owner_root_thumbprint" owner-root-thumbprint)
        (cons "reason" (or reason ""))
        (cons "revoked_at" revoked-at)
        (cons "revokes_delegate_thumbprint" revokes-delegate-thumbprint)
        (cons "revokes_sequence" revokes-sequence)))

;;; ============================================================================
;;; TYPED VERDICT
;;; ============================================================================

(defstruct (apb-verdict (:conc-name apb-) (:copier nil)
                        (:constructor %make-apb-verdict))
  (awarded-tier "provisional-unanchored" :type string :read-only t)
  (required-tier nil :read-only t)
  (satisfies-policy-p nil :read-only t)
  (reasons '() :type list :read-only t)
  (predicates '() :type list :read-only t)   ; (name ok . detail)
  (gen-time nil :read-only t)                 ; genTime από επαληθευμένο TSR
  (delegation-state nil :read-only t))        ; :active|:revoked|:expired|:not-yet|:absent

;;; ============================================================================
;;; ΕΙΣΟΔΟΙ (bundle/policy/checkpoint) — accessors ανεκτικοί σε plist/alist/hash
;;; ============================================================================

(defun %get (obj key)
  (cond ((null obj) nil)
        ((hash-table-p obj) (gethash key obj))
        ((and (consp obj) (keywordp (car obj))) (getf obj key))  ; plist με keyword
        ((consp obj) (cdr (assoc key obj :test #'equal)))
        (t nil)))

;;; ============================================================================
;;; Η ΜΙΑ ΕΙΣΟΔΟΣ
;;; ============================================================================

(defun verify-authority-proof-bundle (bundle &key trusted-owner-root-jwk
                                                  trusted-owner-thumbprint
                                                  trusted-tsa-ca-path
                                                  known-revocations
                                                  consumer-checkpoint
                                                  policy)
  "Επαληθεύει ΟΛΗ την αλυσίδα εξουσίας του BUNDLE, hermetically. Επιστρέφει
   apb-verdict. ΟΛΑ τα σημεία εμπιστοσύνης ΔΙΝΟΝΤΑΙ ΕΞΩΘΕΝ — ΠΟΤΕ από το bundle:
     trusted-owner-root-jwk | trusted-owner-thumbprint — Ed25519 owner pin·
     trusted-tsa-ca-path — pinned RFC-3161 TSA CA (ΑΠΑΙΤΕΙΤΑΙ :pinned· χωρίς
       αυτό ο genTime ΔΕΝ αυθεντικοποιείται και RC7 αποτυγχάνει — crypto-critic C1)·
     known-revocations — authoritative ανακλήσεις που ΓΝΩΡΙΖΕΙ ήδη ο καταναλωτής
       (αποτρέπουν suppression-by-omission από το bundle — crypto-critic S1).
   POLICY: plist :required-tier :allowed-delegate-algorithms
     :temporal-verifier-hash :require-witness :require-checkpoint :gentime-floor
     :min-tlog-leaf-index :policy-digest.

   ΒΑΘΜΙΔΕΣ ΑΠΟΝΕΜΟΝΤΑΙ ΜΟΝΟ από επαληθευμένα κατηγορήματα:
     RC*   → internally-release-consistent (ο υπογεγραμμένος release-statement
             ΔΕΝΕΙ census/receipt-set/content/cut/verifier-set στον anchored root)
     RC*+CONS*+OWN* → owner-pinned-authenticated
     RC*+CONS*+OWN*+WIT* → independently-witnessed.
   ΟΡΙΑ (τίμια δηλωμένα):
   • ο verifier αυτός (#4A — cryptographic release-envelope) ΔΕΝ έχει journal:
     ο graph_root δεσμεύεται στον υπογεγραμμένο release-statement, ΟΧΙ σε replay.
     Η δέσμευση graph_root↔ζωντανή αλυσίδα + το πλήρες authority-evidence replay
     (journal bytes → reconstructed graph → verify-receipt-intrinsic → TRA
     recompute) ανήκουν στο #4B (verify-authority-evidence-bundle).
   • [provenance-critic-2 S3] Η βαθμίδα «internally-release-consistent» μοιράζεται
     ΟΝΟΜΑ με την πρώτη βαθμίδα (release-anchor-for) αλλά ΔΙΑΦΟΡΕΤΙΚΑ τεκμήρια:
     εκεί = graph_root ≡ live chain-head· εδώ = υπογεγραμμένος release-statement.
     ΣΥΜΠΛΗΡΩΜΑΤΙΚΕΣ, όχι εναλλάξιμες — ο καταναλωτής χρειάζεται ΚΑΙ τις δύο για
     πλήρη διαβεβαίωση (γι' αυτό υπάρχει το #4B).
   • [provenance-critic-2 S1] Anti-rollback: χωρίς policy :min-tlog-leaf-index (ή
     :gentime-floor) ένα παλιό γνήσιο release μπορεί να επαναπαρουσιαστεί εντός
     της ισχύος της delegation — ο καταναλωτής δηλώνει ρητά το freshness floor."
  (let ((preds '()) (reasons '()) (gen-time nil) (deleg-state :absent))
    (labels ((pred (name ok &optional detail)
               (push (list* name (and ok t) detail) preds)
               (unless ok (push name reasons))
               (and ok t))
             (safe (name thunk)
               ;; κάθε κατηγόρημα fail-closed: εξαίρεση = αποτυχία, ποτέ crash
               (handler-case (pred name (funcall thunk))
                 (error (e) (pred name nil (princ-to-string e))))))

      ;; ── ΟΜΑΔΑ RC: τοπική συνέπεια release ────────────────────────────────
      (let* ((release-root (%get bundle :release-root))
             (release-jwk (%get bundle :release-jwk))
             (census (%get bundle :census))
             (cut (%get bundle :cut))
             (receipt (%get bundle :receipt))
             (content (%get bundle :content))
             (tlog (%get bundle :tlog))
             (verifier-set (%get bundle :verifier-set))
             (req-verifier (%get policy :temporal-verifier-hash)))

        ;; RC1: το release JWS επαληθεύεται πάνω στον ΚΑΝΟΝΙΚΟ release-statement
        ;; που ΔΕΝΕΙ release-root ⋈ census ⋈ receipt-set ⋈ content ⋈ cut ⋈
        ;; verifier-set (provenance-critic C1/C2/S1-S3: το commitment edge — κανένα
        ;; downstream artifact δεν είναι πλέον ελεύθερα αντικαταστάσιμο, αφού το
        ;; delegated release key τα υπογράφει ΟΛΑ μαζί με τον anchored root).
        (safe :rc/release-jws
              (lambda ()
                (let ((key (ironclad:make-public-key
                            :rsa
                            :n (ironclad:octets-to-integer
                                (jws:base64url-decode (%jwk-field release-jwk "n")))
                            :e (ironclad:octets-to-integer
                                (jws:base64url-decode (%jwk-field release-jwk "e")))))
                      (stmt (%canonical-release-statement
                             :release-root release-root
                             :graph-root (%get census :graph-root)
                             :receipt-set-root (%get census :receipt-set-root)
                             :content-text-sha256 (%get content :text-sha256)
                             :content-version-hash (%get content :version-hash)
                             :cut-graph-root (%get cut :graph-root)
                             :cut-journal-seq (%get cut :journal-seq)
                             :cut-known-at (%get cut :known-at)
                             :verifier-set verifier-set
                             ;; [C1] η ταυτότητα του tlog ΜΕΣΑ στην υπογραφή ⇒
                             ;; RC6 δεν είναι πλέον vacuous χωρίς checkpoint
                             :tlog-root (%get tlog :root)
                             :tlog-tree-size (%get tlog :tree-size)
                             :tlog-leaf-index (%get tlog :leaf-index))))
                  (and (stringp release-root)
                       (jws:verify-jws (%get bundle :release-jws) stmt key)))))

        ;; RC2: census.graph_root ≡ cut.graph_root (semantic έλεγχος — αμφότερα
        ;; δεσμεύονται ΗΔΗ στον υπογεγραμμένο release-statement μέσω RC1)
        (safe :rc/census-binds-cut
              (lambda ()
                (and (stringp (%get census :graph-root))
                     (equal (%get census :graph-root) (%get cut :graph-root)))))

        ;; RC3: receipt-set root ≡ MTH(receipt-ids) — ο census δεσμεύει το ΣΥΝΟΛΟ
        (safe :rc/receipt-set-root
              (lambda ()
                (let ((ids (%get census :receipt-ids)))
                  (and (consp ids)
                       (equal (%get census :receipt-set-root)
                              (merkle:merkle-root-of-strings ids))))))

        ;; RC4: το συγκεκριμένο receipt ∈ receipt-set (inclusion path στη ρίζα)
        (safe :rc/receipt-membership
              (lambda ()
                (let* ((ids (%get census :receipt-ids))
                       (idx (%get receipt :index))
                       (rid (%get receipt :receipt-id)))
                  (and (integerp idx) (< -1 idx (length ids))
                       (equal (nth idx ids) rid)
                       (merkle:verify-inclusion
                        (merkle:hash-leaf-string rid)
                        (merkle:inclusion-path
                         (mapcar #'merkle:hash-leaf-string ids) idx)
                        (%get census :receipt-set-root))))))

        ;; RC5: content ↔ TRA συνέπεια. Το content ΔΕΣΜΕΥΕΤΑΙ στον υπογεγραμμένο
        ;; release-statement (RC1)· εδώ ελέγχεται επιπλέον ότι το TRA δεσμεύει
        ;; ΤΟ ΙΔΙΟ content (καμία απόκλιση attestation↔release).
        (safe :rc/content-commitment
              (lambda ()
                (let ((tra-out (%get (%get bundle :tra) :committed-content)))
                  (and (stringp (%get content :text-sha256))
                       (stringp (%get content :version-hash))
                       tra-out
                       (equal (%get content :text-sha256)
                              (%get tra-out :text-sha256))
                       (equal (%get content :version-hash)
                              (%get tra-out :version-hash))))))

        ;; RC6: tlog inclusion του release-root leaf (RFC 6962)
        (safe :rc/tlog-inclusion
              (lambda ()
                (and (stringp release-root)
                     (merkle:verify-inclusion
                      (merkle:hash-leaf-string release-root)
                      (%get tlog :inclusion-path)
                      (%get tlog :root)))))

        ;; RC7: TSR κρυπτογραφικά έγκυρο ΚΑΙ chained σε PINNED TSA CA (crypto-
        ;; critic C1: το :unpinned ΔΕΝ αυθεντικοποιεί ΠΟΙΟΣ υπέγραψε ⇒ ο genTime
        ;; θα ήταν attacker-forgeable, καταρρίπτοντας OWN5/OWN6). Απαιτείται
        ;; ΕΞΩΤΕΡΙΚΟ trusted-tsa-ca-path και tier = :pinned. Ο genTime ΤΙΘΕΤΑΙ
        ;; ΜΟΝΟ στην επιτυχία (provenance-critic M1) — ποτέ από μη-επαληθευμένο TSR.
        (safe :rc/tsr
              (lambda ()
                (unless trusted-tsa-ca-path
                  (error "RC7: απόν trusted-tsa-ca-path — ο genTime ΔΕΝ αυθεντικοποιείται (fail-closed)"))
                (multiple-value-bind (tier plist)
                    (tsa:verify-tsr-cryptographically
                     (%get bundle :tsr-bytes)
                     (babel:string-to-octets release-root :encoding :utf-8)
                     :ca-pem-path trusted-tsa-ca-path)
                  (let ((g (getf plist :gen-time)))
                    (when (and (eq tier :pinned) g)
                      (setf gen-time g)      ; ΜΟΝΟ σε επιτυχία
                      t)))))

        ;; RC8: verifier-set membership — ο ΑΠΑΙΤΟΥΜΕΝΟΣ (policy) temporal
        ;; verifier ∈ verifier-set ΤΟΥ release (ο verifier απαιτείται εξ policy,
        ;; ΟΧΙ ανακαλύπτεται από το bundle)
        (safe :rc/verifier-set
              (lambda ()
                (and (stringp req-verifier)
                     (consp verifier-set)
                     (member req-verifier verifier-set :test #'equal)
                     t)))

        ;; ── ΟΜΑΔΑ CONS: consistency vs consumer checkpoint (append-only) ──
        ;; [provenance-critic M2] Η ανίχνευση fork ΕΞΑΡΤΑΤΑΙ από checkpoint· η
        ;; απουσία του ΔΕΝ είναι σιωπηλή — αν η policy απαιτεί :require-checkpoint
        ;; και δεν δόθηκε, ΑΠΟΤΥΓΧΑΝΕΙ ονομαστικά.
        (cond
          (consumer-checkpoint
           (safe :cons/tlog-consistency
                 (lambda ()
                   (merkle:verify-consistency
                    (%get consumer-checkpoint :tree-size)
                    (%get tlog :tree-size)
                    (%get consumer-checkpoint :root)
                    (%get tlog :root)
                    (%get tlog :consistency-proof)))))
          ((%get policy :require-checkpoint)
           (pred :cons/checkpoint-required nil
                 "policy απαιτεί consumer-checkpoint αλλά δεν δόθηκε — fork undetectable")))

        ;; [provenance-critic-2 S1] ANTI-ROLLBACK freshness: αν η policy δηλώσει
        ;; :min-tlog-leaf-index (η ΤΕΛΕΥΤΑΙΑ θέση log που ο καταναλωτής αποδέχτηκε
        ;; — μονότονος δείκτης), το ΥΠΟΓΕΓΡΑΜΜΕΝΟ (RC1) tlog leaf-index ΠΡΕΠΕΙ να
        ;; είναι ≥ αυτού· παλιό γνήσιο release (μικρότερος index) ⇒ rollback ⇒ FAIL.
        (let ((floor-idx (%get policy :min-tlog-leaf-index)))
          (when floor-idx
            (safe :cons/tlog-freshness
                  (lambda ()
                    (let ((idx (%get tlog :leaf-index)))
                      (and (integerp idx) (integerp floor-idx)
                           (>= idx floor-idx))))))))

      ;; ── ΟΜΑΔΑ OWN: owner-pinned authentication (hermetic pin) ────────────
      (let* ((deleg (%get bundle :delegation))
             (deleg-stmt (%get deleg :statement))
             (deleg-sig (%get deleg :signature))
             (bundle-owner-jwk (%get bundle :owner-root-jwk))
             (release-jwk (%get bundle :release-jwk))
             ;; Το ΕΜΠΙΣΤΟ owner public key ΠΟΤΕ από το bundle αυθαίρετα:
             ;;  • αν δόθηκε trusted JWK → αυτό·
             ;;  • αλλιώς αν δόθηκε trusted thumbprint → το bundle owner JWK
             ;;    ΓΙΝΕΤΑΙ ΔΕΚΤΟ ΜΟΝΟ αν ο thumbprint του ταιριάζει (το pin
             ;;    αυθεντικοποιεί το πλήρες κλειδί — RFC 7638)·
             ;;  • αλλιώς → κανένα pin ⇒ owner tier αδύνατη.
             (trusted-thumb
               (cond (trusted-owner-root-jwk
                      (ignore-errors (ed25519-jwk-thumbprint trusted-owner-root-jwk)))
                     ((stringp trusted-owner-thumbprint) trusted-owner-thumbprint)
                     (t nil)))
             (owner-key nil))

        ;; OWN1: pin resolution + το bundle owner JWK δεσμεύεται στο pin
        (safe :own/pin-authenticates-owner-key
              (lambda ()
                (cond
                  ((null trusted-thumb) nil)   ; κανένα pin → όχι owner tier
                  (trusted-owner-root-jwk
                   (setf owner-key (ed25519-public-from-jwk trusted-owner-root-jwk))
                   ;; αν το bundle φέρει owner jwk, ΠΡΕΠΕΙ να ταυτίζεται
                   (or (null bundle-owner-jwk)
                       (equal (ed25519-jwk-thumbprint bundle-owner-jwk) trusted-thumb)))
                  (t   ; μόνο thumbprint pinned → αυθεντικοποίησε το bundle key
                   (and bundle-owner-jwk
                        (equal (ed25519-jwk-thumbprint bundle-owner-jwk) trusted-thumb)
                        (progn (setf owner-key
                                     (ed25519-public-from-jwk bundle-owner-jwk))
                               t))))))

        ;; OWN2: η delegation δηλώνει τον ΙΔΙΟ owner thumbprint με το pin
        (safe :own/delegation-owner-matches-pin
              (lambda ()
                (and trusted-thumb deleg-stmt
                     (equal (cdr (assoc "owner_root_thumbprint" deleg-stmt :test #'equal))
                            trusted-thumb))))

        ;; OWN3: ο owner ΥΠΟΓΡΑΦΕΙ την delegation (Ed25519 πάνω στην κανονική)
        (safe :own/owner-signs-delegation
              (lambda ()
                (and owner-key deleg-stmt deleg-sig
                     (owner-verify-statement owner-key +delegation-tag+
                                             deleg-stmt deleg-sig))))

        ;; OWN4: το delegate δεσμεύει ΤΟ release key (RSA thumbprint) + algorithm
        (safe :own/delegate-binds-release-key
              (lambda ()
                (let* ((rk (ironclad:make-public-key
                            :rsa
                            :n (ironclad:octets-to-integer
                                (jws:base64url-decode (%jwk-field release-jwk "n")))
                            :e (ironclad:octets-to-integer
                                (jws:base64url-decode (%jwk-field release-jwk "e")))))
                       (rk-thumb (jws:jwk-thumbprint rk))
                       (allowed (or (%get policy :allowed-delegate-algorithms)
                                    '("RS256"))))
                  (and deleg-stmt
                       (equal (cdr (assoc "delegate_jwk_thumbprint" deleg-stmt :test #'equal))
                              rk-thumb)
                       (member (cdr (assoc "delegate_algorithm" deleg-stmt :test #'equal))
                               allowed :test #'equal)
                       t))))

        ;; OWN5: η delegation ΙΣΧΥΕΙ ΣΤΟ genTime του TSR (όχι σε caller clock).
        ;; [crypto-critic S2] ΑΜΦΟΤΕΡΑ nb/na ΚΑΝΟΝΙΚΟΠΟΙΟΥΝΤΑΙ (dual-format
        ;; ISO/GeneralizedTime) — ασύμμετρη σύγκριση = λάθος έκβαση.
        ;; [provenance-critic S4] freshness floor: αν η policy δώσει
        ;; :gentime-floor, ο genTime ΠΡΕΠΕΙ να είναι ≥ αυτού (θάνατος temporal
        ;; rollback — παλιό γνήσιο TSR δεν ξανα-εξουσιοδοτεί νεότερη έκδοση).
        (safe :own/delegation-valid-at-gentime
              (lambda ()
                (let* ((nb (%normalize-gentime
                            (cdr (assoc "not_before" deleg-stmt :test #'equal))))
                       (na (%normalize-gentime
                            (cdr (assoc "not_after" deleg-stmt :test #'equal))))
                       (floor-raw (%get policy :gentime-floor))
                       (floor (and floor-raw (%normalize-gentime floor-raw)))
                       (g (and gen-time (%normalize-gentime gen-time))))
                  (cond
                    ;; [crypto-critic-2 F4] κακοσχηματισμένο :gentime-floor ΔΕΝ
                    ;; παρακάμπτει σιωπηλά τον anti-rollback έλεγχο — fail-closed.
                    ((and floor-raw (null floor)) (setf deleg-state :floor-unparseable) nil)
                    ((not (and g nb na)) (setf deleg-state :absent) nil)
                    ((and floor (string< g floor)) (setf deleg-state :stale) nil)
                    ((string< g nb) (setf deleg-state :not-yet) nil)
                    ((string> g na) (setf deleg-state :expired) nil)
                    (t (setf deleg-state :active) t)))))

        ;; OWN6: ΚΑΜΙΑ ενεργή (owner-signed) ανάκληση δεν καλύπτει την delegation
        ;; στο genTime. [crypto-critic M3] η ανάκληση πρέπει να ΣΤΟΧΕΥΕΙ ΤΟΝ ΙΔΙΟ
        ;; delegate (revokes_delegate_thumbprint) ΚΑΙ seq ≥ (supersession).
        ;; [crypto-critic S1] αξιολογούνται ΚΑΙ οι bundle revocations ΚΑΙ οι
        ;; ΕΞΩΤΕΡΙΚΕΣ known-revocations του καταναλωτή — suppression-by-omission
        ;; από το bundle δεν κρύβει ανάκληση που ο καταναλωτής ήδη γνωρίζει.
        (safe :own/not-revoked
              (lambda ()
                (let* ((seq (cdr (assoc "sequence" deleg-stmt :test #'equal)))
                       (dthumb (cdr (assoc "delegate_jwk_thumbprint" deleg-stmt :test #'equal)))
                       (g (and gen-time (%normalize-gentime gen-time))))
                  (if (not (and (integerp seq) (>= seq 1) owner-key g dthumb))
                      nil                       ; προϋποθέσεις απούσες ⇒ fail-closed
                      (block scan
                        (dolist (rv (append (%get bundle :revocations)
                                            known-revocations)
                                    t)
                          (let* ((st (%get rv :statement)) (sg (%get rv :signature))
                                 (rvseq (cdr (assoc "revokes_sequence" st :test #'equal)))
                                 (rdt (cdr (assoc "revokes_delegate_thumbprint" st :test #'equal)))
                                 (rat (%normalize-gentime
                                       (cdr (assoc "revoked_at" st :test #'equal)))))
                            ;; owner-signed ανάκληση που ΣΤΟΧΕΥΕΙ ΤΟΝ ΙΔΙΟ delegate
                            ;; με seq ≥ (supersession):
                            (when (and (owner-verify-statement owner-key +revocation-tag+ st sg)
                                       (integerp rvseq) (>= rvseq seq) (equal rdt dthumb))
                              ;; [crypto-critic-2 F5] revoked_at μη-αναγνώσιμο σε
                              ;; ΤΑΙΡΙΑΣΤΗ owner-signed ανάκληση ⇒ ΑΝΑΚΛΗΣΗ (fail-
                              ;; closed), ΠΟΤΕ σιωπηλή παράβλεψη· αλλιώς ισχύει από
                              ;; revoked_at ≤ genTime.
                              (when (or (null rat) (string>= g rat))
                                (setf deleg-state :revoked)
                                (return-from scan nil)))))))))))

      ;; ── ΟΜΑΔΑ WIT: independently-witnessed (Δ4) ──────────────────────────
      ;; Απονέμεται ΜΟΝΟ με επαληθευμένο 3ο μάρτυρα ΚΑΙ policy require-witness.
      ;; Χωρίς γνήσιο μάρτυρα (TEST/παραγωγή σήμερα) ΠΟΤΕ δεν περνά (τίμιο όριο).
      (when (%get policy :require-witness)
        (safe :wit/third-party-checkpoint
              (lambda ()
                (let ((w (%get bundle :witness)))
                  (and w (%get w :verified-independently) nil)))))  ; δομικά NIL σήμερα

      ;; ── ΑΠΟΝΟΜΗ ΒΑΘΜΙΔΑΣ: η ΑΝΩΤΑΤΗ με ΟΛΟ το σύνολο περασμένο ────────────
      (let* ((by-name (lambda (prefix)
                        (remove-if-not
                         (lambda (p) (let ((n (string (car p))))
                                       (and (>= (length n) (length prefix))
                                            (string= prefix (subseq n 0 (length prefix))))))
                         preds)))
             (all-ok (lambda (ps) (and ps (every #'cadr ps))))
             (rc-ok (funcall all-ok (funcall by-name "RC/")))
             (cons-ok (let ((cp (funcall by-name "CONS/")))
                        (or (null cp) (funcall all-ok cp))))
             (own-ok (funcall all-ok (funcall by-name "OWN/")))
             (wit-ok (let ((wp (funcall by-name "WIT/")))
                       (and wp (funcall all-ok wp))))
             (tier (cond ((and rc-ok cons-ok own-ok wit-ok) "independently-witnessed")
                         ((and rc-ok cons-ok own-ok) "owner-pinned-authenticated")
                         ((and rc-ok cons-ok) "internally-release-consistent")
                         (t "provisional-unanchored")))
             (required (%get policy :required-tier)))
        (%make-apb-verdict
         :awarded-tier tier
         :required-tier required
         :satisfies-policy-p (or (null required) (tier>= tier required))
         :reasons (nreverse reasons)
         :predicates (nreverse preds)
         :gen-time gen-time
         :delegation-state deleg-state)))))

;;; ── βοηθητικά ──

(defun %normalize-gentime (gt)
  "GeneralizedTime «YYYYMMDDHHMMSS[.fff]Z» ή ISO «YYYY-MM-DDTHH:MM:SS[.fff]Z» →
   συγκρίσιμο «YYYYMMDDHHMMSS» (14 UTC ψηφία). NIL σε κακοσχηματισμένο (fail-
   closed). [crypto-critic-2 F6] ΑΠΟΡΡΙΠΤΟΝΤΑΙ offset-bearing χρόνοι (+HH:MM ή
   -HH:MM μετά το T) — δεν μετατρέπονται σιωπηλά σε UTC· ο genTime RFC-3161
   είναι πάντα Z, τα bounds προέρχονται από trusted signers/policy, οπότε ένας
   offset = κακοσχηματισμένη είσοδος ⇒ fail-closed αντί για λάθος σύγκριση."
  (when (stringp gt)
    (let* ((tpos (position #\T gt))
           ;; offset ανιχνεύεται ΜΟΝΟ στο time-τμήμα (μετά το T ή, σε καθαρό
           ;; GeneralizedTime χωρίς T, οπουδήποτε): «+» πάντα, «-» μετά το T.
           (offset-p (or (find #\+ gt)
                         (and tpos (find #\- gt :start (1+ tpos)))
                         (and (null tpos) (find #\- gt)))))
      (unless offset-p
        (let ((digits (remove-if-not #'digit-char-p gt)))
          (when (>= (length digits) 14) (subseq digits 0 14)))))))
