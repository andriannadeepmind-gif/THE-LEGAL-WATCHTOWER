;;;; source/authority-evidence-replay.lisp
;;;; ============================================================================
;;;; [0088 Φ7-HARDENING #4B+#4C] AUTHORITY EVIDENCE REPLAY + PROOF-BINDING FREEZE
;;;; ============================================================================
;;;; Ο ΠΛΗΡΗΣ δεύτερης βαθμίδας verifier: ΔΕΝ εμπιστεύεται bundle-declared roots —
;;;; τα ΞΑΝΑΠΑΡΑΓΕΙ. #4C κλείνει τα proof-binding κενά (εντολή δημιουργού):
;;;;  1. top-level scope ΔΕΝΕΤΑΙ με το scope της owner-signed delegation·
;;;;  2. ΠΡΑΓΜΑΤΙΚΗ source→spans→extraction→normalization→graph-text (byte-equiv)·
;;;;  3. mandatory bundle_id (recompute ΟΛΩΝ των components) + duplicate-key reject·
;;;;  4. census/release-manifest δεσμευμένα (κανένα decorative evidence)·
;;;;  5. policy_digest = recompute closed policy schema (όχι caller assertion)·
;;;;  6. TRA anchor ΠΑΡΑΓΕΤΑΙ από το verified envelope, ΟΧΙ από το ίδιο το TRA·
;;;;  7. verifier-set = ΑΚΡΙΒΗΣ ισότητα sorted-unique sha256(actual bytes)·
;;;;  8. :require-delegation-state cap + compromise_from.
;;;; ΚΑΝΕΝΑ declared root· ΟΛΟ το replay hermetic· κάθε βήμα recompute-and-compare.

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
   #:+authority-statement-tag+ #:+bundle-protocol+
   #:canonical-authority-statement #:canonical-policy-digest
   #:extraction-receipt-id #:normalization-receipt-id
   #:bundle-id #:validate-bundle-schema
   #:reconstruct-graph-from-journal-bytes
   #:aer-verdict #:aer-verdict-p
   #:aer-awarded-tier #:aer-satisfies-policy-p #:aer-reasons #:aer-predicates
   #:aer-replayed-graph-root #:aer-replayed-graph-seq #:aer-recomputed-tra-hash
   #:aer-derived-text #:aer-authentication-mode
   #:verify-authority-evidence-bundle))

(in-package :orchestrator.authority-evidence-replay)

;;; ============================================================================
;;; ΚΛΕΙΣΤΟ SCHEMA authority-proof-bundle/1
;;; ============================================================================

(defparameter +bundle-protocol+ "lawmax/authority-proof-bundle/1")

(defparameter +bundle-required-keys+
  '(:protocol :bundle-id :corpus-id :body-id :release-id :release-generation
    :delegation-scope :registry-digest :envelope :source-artifact
    :extraction-receipt :normalization-receipt :receipt :receipt-membership
    :journal-bytes :census :release-manifest :verifier-binaries :tra
    :authority-statement-jws)
  "Το ΑΚΡΙΒΕΣ σύνολο top-level κλειδιών — ούτε λιγότερα (missing evidence) ούτε
   περισσότερα (unknown ⇒ πιθανό smuggling). bundle-id ΥΠΟΧΡΕΩΤΙΚΟ (#4C).")

(defun %g (obj key)
  (cond ((null obj) nil)
        ((hash-table-p obj) (gethash key obj))
        ((and (consp obj) (keywordp (car obj))) (getf obj key))
        ((consp obj) (cdr (assoc key obj :test #'equal)))
        (t nil)))

(defun %plist-keys (pl)
  (loop for (k) on pl by #'cddr collect k))

(defun validate-bundle-schema (bundle)
  "Fail-closed κλειστό schema: ΑΚΡΙΒΩΣ +bundle-required-keys+ ΧΩΡΙΣ διπλότυπα
   (#4C: duplicate top-level key ⇒ ΣΦΑΛΜΑ — cross-language parsing ambiguity)."
  (unless (and (consp bundle) (keywordp (car bundle)))
    (error "authority-proof-bundle/1: το bundle πρέπει να είναι plist"))
  (unless (equal (%g bundle :protocol) +bundle-protocol+)
    (error "authority-proof-bundle: πρωτόκολλο ~S ≠ ~S" (%g bundle :protocol) +bundle-protocol+))
  (let* ((present (%plist-keys bundle))
         (dups (loop for k in present when (> (count k present) 1) collect k))
         (missing (set-difference +bundle-required-keys+ present))
         (unknown (set-difference present +bundle-required-keys+)))
    (when dups (error "authority-proof-bundle: ΔΙΠΛΟΤΥΠΑ κλειδιά ~S" (remove-duplicates dups)))
    (when missing (error "authority-proof-bundle: ΛΕΙΠΟΥΝ κλειδιά ~S" missing))
    (when unknown (error "authority-proof-bundle: ΑΓΝΩΣΤΑ κλειδιά ~S (schema κλειστό)" unknown))
    t))

;;; ============================================================================
;;; HELPERS: hashing
;;; ============================================================================

(defun %sha256-hex-of-string (s)
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string
           (ironclad:digest-sequence :sha256 (babel:string-to-octets s :encoding :utf-8)))))
(defun %sha256-hex-of-bytes (bytes)
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 bytes))))

;;; ============================================================================
;;; BUNDLE-ID — δεσμεύει ΟΛΑ τα components (#4C-3)
;;; ============================================================================

(defun %canon-print (obj)
  "STRUCTURE-PRESERVING ντετερμινιστική τυπωμένη μορφή ΟΠΟΙΟΥΔΗΠΟΤΕ component
   (plist | alist | dotted cons | list | string | integer | keyword | octet
   vector | nil). ΙΔΙΑ δομή ⇒ ΙΔΙΟ string. Δεν ταξινομεί (η δομή των components
   είναι code-deterministic) — χειρίζεται σωστά dotted pairs & octet vectors."
  (cond
    ((null obj) "N")
    ((stringp obj) (format nil "S~D:~A" (length obj) obj))
    ((integerp obj) (format nil "I:~D" obj))
    ((symbolp obj) (format nil "K:~A" (string-downcase (symbol-name obj))))
    ((typep obj '(vector (unsigned-byte 8))) (format nil "B:~A" (%sha256-hex-of-bytes obj)))
    ((consp obj) (%canon-list obj))     ; proper Ή improper list Ή dotted pair
    ;; [schema-critic-2 F2] μη-δεσμεύσιμος τύπος ⇒ ΣΦΑΛΜΑ (ΟΧΙ non-deterministic
    ;; ~A address) — η bundle-id δεν κρύβει τύπο που δεν σειριοποιεί ντετερμινιστικά.
    (t (error "%canon-print: μη-δεσμεύσιμος τύπος ~S (~S)" (type-of obj) obj))))

(defun %canon-list (obj)
  "[schema-critic-2 F1] ΕΝΡΙΞΙΜΗ σειριοποίηση list ΚΑΙ για improper lists — το
   mapcar θα έριχνε σιωπηλά το dotted tail (('a 'b . 'c) ≡ ('a 'b)). Εδώ το
   terminal atom κωδικοποιείται ΡΗΤΑ ⇒ καμία σύγκρουση."
  (with-output-to-string (s)
    (write-char #\( s)
    (loop for rest = obj then (cdr rest)
          for first = t then nil
          while (consp rest)
          do (unless first (write-char #\Space s))
             (write-string (%canon-print (car rest)) s)
          finally (unless (null rest)
                    (write-string " . " s) (write-string (%canon-print rest) s)))
    (write-char #\) s)))

(defun %component-digest (obj)
  "Ντετερμινιστικό digest ενός component για το bundle-id."
  (%sha256-hex-of-string (%canon-print obj)))

(defun bundle-id (bundle)
  "Ντετερμινιστική ταυτότητα ΟΛΟΚΛΗΡΟΥ του evidence — canonical hash των digests
   ΚΑΘΕ component (#4C-3: πλέον δεσμεύει receipt/tra/source/spans/extraction/
   normalization/verifier-binaries/manifest/envelope/census, όχι μόνο 6 πεδία)."
  (canon:canonical-hash
   (list (cons "protocol" (%g bundle :protocol))
         (cons "corpus_id" (%g bundle :corpus-id))
         (cons "body_id" (%g bundle :body-id))
         (cons "release_id" (%g bundle :release-id))
         (cons "release_generation" (princ-to-string (%g bundle :release-generation)))
         (cons "delegation_scope" (%g bundle :delegation-scope))
         (cons "registry_digest" (%g bundle :registry-digest))
         (cons "journal_sha256" (%sha256-hex-of-string (%g bundle :journal-bytes)))
         (cons "envelope" (%component-digest (%g bundle :envelope)))
         (cons "source_artifact" (%component-digest (%g bundle :source-artifact)))
         (cons "extraction_receipt" (%component-digest (%g bundle :extraction-receipt)))
         (cons "normalization_receipt" (%component-digest (%g bundle :normalization-receipt)))
         (cons "receipt" (%component-digest (%g bundle :receipt)))
         (cons "receipt_membership" (%component-digest (%g bundle :receipt-membership)))
         (cons "census" (%component-digest (%g bundle :census)))
         (cons "release_manifest" (%component-digest (%g bundle :release-manifest)))
         (cons "verifier_binaries" (%component-digest (%g bundle :verifier-binaries)))
         (cons "tra" (%component-digest (%g bundle :tra))))))
;; ΣΗΜ: το authority_statement_jws ΔΕΝ μπαίνει στο bundle-id (θα ήταν κυκλικό:
;; το statement υπογράφει το bundle_id). Το jws δένεται μεταβατικά — το signed
;; statement δεσμεύει το bundle_id που δεσμεύει ΟΛΑ τα components.

;;; ============================================================================
;;; CLOSED POLICY SCHEMA + digest (#4C-5)
;;; ============================================================================

(defparameter +policy-digest-tag+ "lawmax/verification-policy/1")

(defun canonical-policy-digest (policy)
  "policy_digest = canonical hash του ΚΛΕΙΣΤΟΥ policy schema — ΟΧΙ caller
   assertion. Αλλαγή ΟΠΟΙΟΥΔΗΠΟΤΕ policy field ⇒ διαφορετικό digest (#4C-5)."
  (flet ((s (x) (if (null x) "" (princ-to-string x))))
    (%sha256-hex-of-string
     (apb:canonical-statement-string
      +policy-digest-tag+
      (list (cons "required_tier" (s (%g policy :required-tier)))
            (cons "allowed_delegate_algorithms"
                  (format nil "~{~A~^,~}"
                          (sort (copy-list (or (%g policy :allowed-delegate-algorithms) '()))
                                #'string<)))
            (cons "temporal_verifier_hash" (s (%g policy :temporal-verifier-hash)))
            (cons "gentime_floor" (s (%g policy :gentime-floor)))
            (cons "min_tlog_leaf_index" (s (%g policy :min-tlog-leaf-index)))
            (cons "require_checkpoint" (s (and (%g policy :require-checkpoint) t)))
            (cons "require_witness" (s (and (%g policy :require-witness) t)))
            (cons "require_delegation_state" (s (and (%g policy :require-delegation-state) t))))))))

;;; ============================================================================
;;; SIGNED AUTHORITY-STATEMENT (point 7) — δεσμεύει ΟΛΕΣ τις ρίζες
;;; ============================================================================

(defparameter +authority-statement-tag+ "lawmax/authority-statement/1")

(defun canonical-authority-statement (&key protocol bundle-id corpus-id body-id
                                           release-id release-generation delegation-scope
                                           registry-digest release-root census-root
                                           receipt-set-root source-provenance-root
                                           graph-root graph-seq graph-known-at tra-hash
                                           verifier-set-root tlog-tree-size tlog-root
                                           tlog-leaf-index policy-digest)
  "Ο ΚΑΝΟΝΙΚΟΣ authority-statement που ΥΠΟΓΡΑΦΕΙ το delegated release key. Δεσμεύει
   ΟΛΑ τα σημεία (schema/bundle-id/corpus/body/release/scope/registry/όλες οι ρίζες/
   graph cut/TRA hash/verifier-set root/tlog/policy digest). #4C: + bundle_id,
   registry_digest. Reuse της ΜΙΑΣ έδρας canonical δήλωσης (apb)."
  (flet ((s (x) (if (null x) "" (princ-to-string x))))
    (apb:canonical-statement-string
     +authority-statement-tag+
     (list (cons "protocol" (s protocol))
           (cons "bundle_id" (s bundle-id))
           (cons "corpus_id" (s corpus-id))
           (cons "body_id" (s body-id))
           (cons "release_id" (s release-id))
           (cons "release_generation" (s release-generation))
           (cons "delegation_scope" (s delegation-scope))
           (cons "registry_digest" (s registry-digest))
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
;;; SOURCE-TO-TEXT PROVENANCE (#4C-2) — closed extraction/normalization schemas
;;; ============================================================================

(defparameter +extraction-schema+ "lawmax/extraction-receipt/1")
(defparameter +normalization-schema+ "lawmax/normalization-receipt/1")
(defparameter +extraction-keys+
  '("schema" "extractor_id" "extractor_hash" "config_hash" "input_digest" "spans" "output_digest"))
(defparameter +normalization-keys+
  '("schema" "normalizer_id" "normalizer_hash" "config_hash" "input_digest" "output_digest"))

(defun %validate-closed-alist (alist keys label schema-value)
  (unless (equal (%g alist "schema") schema-value)
    (error "~A: schema ≠ ~S" label schema-value))
  (let* ((present (mapcar #'car alist))
         (dups (loop for k in present when (> (count k present :test #'equal) 1) collect k)))
    (when dups (error "~A: ΔΙΠΛΟΤΥΠΑ κλειδιά ~S" label dups))
    (when (set-difference keys present :test #'equal)
      (error "~A: ΛΕΙΠΟΥΝ κλειδιά ~S" label (set-difference keys present :test #'equal)))
    (when (set-difference present keys :test #'equal)
      (error "~A: ΑΓΝΩΣΤΑ κλειδιά ~S" label (set-difference present keys :test #'equal))))
  t)

(defun extraction-receipt-id (er) (canon:canonical-hash er))
(defun normalization-receipt-id (nr) (canon:canonical-hash nr))

(defun %apply-spans (bytes spans)
  "Εφαρμόζει το byte-span στα ΠΡΑΓΜΑΤΙΚΑ source bytes → extracted octet vector.
   [source-critic-1 F1 — θάνατος scatter/drop forgery] ΑΚΡΙΒΩΣ ΕΝΑ ΣΥΝΕΧΟΜΕΝΟ
   span: το εξαγόμενο κείμενο ΠΡΕΠΕΙ να εμφανίζεται ΑΥΤΟΥΣΙΟ & ΣΥΝΕΧΟΜΕΝΟ στο
   source. Πολλαπλά spans θα επέτρεπαν (α) αναδιάταξη/επανάληψη χαρακτήρων ή
   (β) παράλειψη ενδιάμεσων bytes (π.χ. διαγραφή «ΔΕΝ» ⇒ αντιστροφή νοήματος
   ενώ το source λέει το αντίθετο). ΜΟΝΟ :byte unit· 0 ≤ start < end ≤ len·
   κάθε παράβαση ⇒ ΣΦΑΛΜΑ. (Δηλωμένο ΑΝΩΤΕΡΟ/μελλοντικό: multi-span excerpting
   ΜΟΝΟ με ρητό justified gap-manifest — δεν υλοποιείται εδώ κατά scope.)"
  (unless (and (consp spans) (= 1 (length spans)))
    (error "spans: απαιτείται ΑΚΡΙΒΩΣ ΕΝΑ συνεχόμενο span (θάνατος scatter/drop forgery)"))
  (let* ((sp (first spans)) (len (length bytes))
         (a (%g sp "start")) (b (%g sp "end")) (u (%g sp "unit")))
    (unless (and (member u '("byte" :byte) :test #'equal)
                 (integerp a) (integerp b) (<= 0 a) (< a b) (<= b len))
      (error "span μη-έγκυρο (κενό/εκτός/μη-byte): ~S" sp))
    (subseq bytes a b)))

(defun %normalize-legal-text (text)
  "Ντετερμινιστική normalization κειμένου: trim leading/trailing whitespace.
   (Η μία έδρα normalization· επεκτάσιμη — config_hash δεσμεύει την ταυτότητά της.)"
  (string-trim '(#\Space #\Newline #\Tab #\Return) text))

;;; ============================================================================
;;; HELPERS: keys / bytes / scope / anchor / verifier-set
;;; ============================================================================

(defun %rsa-key-from-jwk (jwk)
  (ironclad:make-public-key
   :rsa
   :n (ironclad:octets-to-integer (jws:base64url-decode (%g jwk "n")))
   :e (ironclad:octets-to-integer (jws:base64url-decode (%g jwk "e")))))

(defun %source-bytes (src)
  (let ((b (%g src :bytes)) (s (%g src :bytes-utf8)))
    (cond ((typep b '(vector (unsigned-byte 8))) b)
          ((stringp s) (babel:string-to-octets s :encoding :utf-8))
          (t (error "source-artifact: απόντα bytes")))))

(defun %binary-bytes (b)
  (let ((raw (%g b :bytes)) (s (%g b :bytes-utf8)))
    (cond ((typep raw '(vector (unsigned-byte 8))) raw)
          ((stringp s) (babel:string-to-octets s :encoding :utf-8))
          (t (error "verifier-binary: απόντα bytes")))))

(defun %scope-covers-p (scope corpus-id body-id)
  "Το delegation scope ΚΑΛΥΠΤΕΙ ΡΗΤΑ corpus+body. [schema-critic-2 F3] Ο corpus
   ΠΑΝΤΑ pinned — το bare «body/<id>» καταργήθηκε (θα εξουσιοδοτούσε το body σε
   ΟΠΟΙΟΝΔΗΠΟΤΕ corpus). Μορφές: «*» | «corpus/<id>» | «corpus/<id>/body/<id>»."
  (and (stringp scope)
       (or (string= scope "*")
           (equal scope (format nil "corpus/~A" corpus-id))
           (equal scope (format nil "corpus/~A/body/~A" corpus-id body-id)))))

(defun %delegation-scope (envelope)
  (cdr (assoc "scope" (%g (%g envelope :delegation) :statement) :test #'equal)))
(defun %delegation-sequence (envelope)
  (cdr (assoc "sequence" (%g (%g envelope :delegation) :statement) :test #'equal)))
(defun %delegation-statement-hash (envelope)
  (%sha256-hex-of-string
   (apb:canonical-statement-string "lawmax/trust/delegation/1"
                                   (%g (%g envelope :delegation) :statement))))

(defun %derive-anchor (envelope registry-digest verifier-hash)
  "[#4C-6] Το anchor ΠΑΡΑΓΕΤΑΙ από το VERIFIED envelope (release-root, tlog) +
   τον signed registry-digest + τον policy verifier-hash — ΠΟΤΕ από το ίδιο το
   TRA (θάνατος κυκλικότητας). assurance = 'internally-release-consistent' (το
   ΑΝΩΤΑΤΟ που παράγει η πρώτη βαθμίδα release-anchor-for)."
  (let ((tlog (%g envelope :tlog)))
    (vg::%make-verified-anchor
     :assurance "internally-release-consistent"
     :release-root (%g envelope :release-root)
     :reasons '()
     :tlog-size (or (%g tlog :tree-size) 0)
     :tlog-root (or (%g tlog :root) "")
     :registry-digest (or registry-digest "")
     :verifier-hash (or verifier-hash ""))))

(defun %verifier-set-recompute (binaries)
  "sorted-unique sha256(ΠΡΑΓΜΑΤΙΚΩΝ bytes) ΚΑΘΕ binary (#4C-7)."
  (sort (remove-duplicates
         (mapcar (lambda (b) (%sha256-hex-of-bytes (%binary-bytes b))) binaries)
         :test #'equal)
        #'string<))

;;; ============================================================================
;;; HERMETIC GRAPH RECONSTRUCTION
;;; ============================================================================

(defvar *replay-counter* 0)
(defvar *replay-rs* (make-random-state t))

(defun reconstruct-graph-from-journal-bytes (journal-bytes)
  "HERMETIC replay σε ΜΟΝΑΔΙΚΟ (nonce) ephemeral body· ΣΕ ΑΠΟΤΥΧΙΑ διαγράφει ΕΔΩ
   (0 leak, καμία concurrency collision). Επιστρέφει (values graph path)."
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
  "Ανακατασκευή του legal-authority-receipt struct ΑΠΟ τη canonical alist μορφή."
  (let* ((cut (%g alist "cut")) (comm (%g alist "commencement"))
         (kw (lambda (s) (intern (string-upcase s) :keyword))))
    (lr::make-legal-authority-receipt
     :receipt-id (%g alist "receipt_id") :provision-id (%g alist "provision_id")
     :commencement (list (funcall kw (%g comm "type")) (%g comm "value"))
     :source-artifact (%g alist "source_artifact") :derivation (%g alist "derivation")
     :valid-until (let ((v (%g alist "valid_until"))) (if (equal v "open") :open v))
     :recorded-from (%g alist "recorded_from")
     :recorded-until (let ((v (%g alist "recorded_until"))) (if (equal v "current") :current v))
     :genealogy (%g alist "genealogy") :content-hash (%g alist "content_hash")
     :previous-version-hash (%g alist "previous_version_hash")
     :release-generation (let ((v (%g alist "release_generation")))
                           (if (equal v "unreleased") :unreleased v))
     :assurance (funcall kw (%g alist "assurance"))
     :trust-status (funcall kw (%g alist "trust_status"))
     :cut-graph-root (%g cut "graph_root") :cut-journal-seq (%g cut "journal_seq")
     :cut-known-at (%g cut "known_at") :effectivity (%g alist "effectivity"))))

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
  (derived-text nil :read-only t)
  (authentication-mode nil :read-only t))

(defun %merkle-of (strings) (if (and strings (consp strings)) (merkle:merkle-root-of-strings strings) ""))

;;; ============================================================================
;;; Η ΜΙΑ ΕΙΣΟΔΟΣ
;;; ============================================================================

(defun verify-authority-evidence-bundle (bundle &key trusted-owner-root-jwk
                                                     trusted-owner-thumbprint
                                                     trusted-tsa-ca-path known-revocations
                                                     known-delegation-state
                                                     consumer-checkpoint policy)
  "Ο ΠΛΗΡΗΣ authority evidence replay verifier (#4B + #4C). KNOWN-DELEGATION-STATE
   = plist :latest-sequence :statement-hash :compromise-from (external anti-
   rollback/equivocation/compromise). Επιστρέφει aer-verdict."
  (validate-bundle-schema bundle)
  (let ((preds '()) (reasons '()) (graph-root nil) (graph-seq nil)
        (tra-hash nil) (derived-text nil) (auth-mode :first-seen)
        (release-gentime nil) (tmp-path nil))
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
               (corpus-id (%g bundle :corpus-id)) (body-id (%g bundle :body-id))
               (registry-digest (%g bundle :registry-digest))
               (top-census (%g bundle :census))
               (env-census (%g envelope :census))
               (cut (%g envelope :cut)) (tlog (%g envelope :tlog))
               (src (%g bundle :source-artifact)) (tra (%g bundle :tra))
               (er (%g bundle :extraction-receipt)) (nr (%g bundle :normalization-receipt))
               (req-verifier (%g policy :temporal-verifier-hash))
               (rgraph
                 (handler-case
                     (multiple-value-bind (g p)
                         (reconstruct-graph-from-journal-bytes (%g bundle :journal-bytes))
                       (setf tmp-path p) g)
                   (error (e) (pred :replay/journal-integrity nil (princ-to-string e)) nil))))

          ;; E0: envelope (#4A) — capture verdict (genTime για compromise check)
          (safe :evidence/envelope
                (lambda ()
                  (let ((v (apb:verify-authority-proof-bundle
                            envelope :trusted-owner-root-jwk trusted-owner-root-jwk
                            :trusted-owner-thumbprint trusted-owner-thumbprint
                            :trusted-tsa-ca-path trusted-tsa-ca-path
                            :known-revocations known-revocations
                            :consumer-checkpoint consumer-checkpoint :policy policy)))
                    (setf release-gentime (apb:apb-gen-time v))
                    (and (apb:apb-satisfies-policy-p v)
                         (apb:tier>= (apb:apb-awarded-tier v) "owner-pinned-authenticated")))))

          (when rgraph
            (pred :replay/journal-integrity t)
            (setf graph-root (vg:graph-chain-head rgraph) graph-seq (vg:graph-seq rgraph)))

          ;; [#4C-3] bundle_id recompute ΟΛΩΝ των components
          (safe :replay/bundle-id
                (lambda () (equal (%g bundle :bundle-id) (bundle-id bundle))))

          ;; [#4C-5] policy_digest recompute closed schema
          (safe :replay/policy-digest
                (lambda () (equal (%g policy :policy-digest) (canonical-policy-digest policy))))

          ;; SIGNED authority-statement δεσμεύει ΟΛΕΣ τις ρίζες + REPLAYED graph_root
          (safe :replay/authority-statement-binds-replay
                (lambda ()
                  (and graph-root release-jwk stmt-jws
                       (let ((astmt (canonical-authority-statement
                                     :protocol +bundle-protocol+ :bundle-id (%g bundle :bundle-id)
                                     :corpus-id corpus-id :body-id body-id
                                     :release-id (%g bundle :release-id)
                                     :release-generation (%g bundle :release-generation)
                                     :delegation-scope scope :registry-digest registry-digest
                                     :release-root (%g envelope :release-root)
                                     :census-root (%g env-census :graph-root)
                                     :receipt-set-root (%g env-census :receipt-set-root)
                                     :source-provenance-root (%g src :provenance-root)
                                     :graph-root graph-root :graph-seq graph-seq
                                     :graph-known-at (%g cut :known-at) :tra-hash (%g tra :hash)
                                     :verifier-set-root (%merkle-of (%g envelope :verifier-set))
                                     :tlog-tree-size (%g tlog :tree-size) :tlog-root (%g tlog :root)
                                     :tlog-leaf-index (%g tlog :leaf-index)
                                     :policy-digest (%g policy :policy-digest))))
                         (jws:verify-jws stmt-jws astmt (%rsa-key-from-jwk release-jwk))))))

          ;; ΔΕΣΜΟΣ REPLAY↔DECLARED
          (safe :replay/graph-root-consistent
                (lambda ()
                  (and graph-root graph-seq
                       (equal graph-root (%g env-census :graph-root))
                       (equal graph-root (%g cut :graph-root))
                       (equal graph-seq (%g cut :journal-seq))
                       (equal graph-root (%g (%g (%g bundle :receipt) "cut") "graph_root"))
                       (equal graph-seq (%g (%g (%g bundle :receipt) "cut") "journal_seq")))))

          ;; [#4C-4] top-level census == envelope census (κανένα decorative census)
          (safe :replay/census-bound (lambda () (equal top-census env-census)))
          ;; [#4C-4] release-manifest δεσμεύει release-id/generation
          (safe :replay/release-manifest-bound
                (lambda ()
                  (let ((m (%g bundle :release-manifest)))
                    (and (equal (%g m :release-id) (%g bundle :release-id))
                         (equal (%g m :release-generation) (%g bundle :release-generation))))))

          ;; [#4C-1] scope ΔΕΝΕΤΑΙ με το scope της owner-signed delegation + covers
          (safe :replay/scope-matches-delegation
                (lambda ()
                  (and (stringp scope) (equal scope (%delegation-scope envelope))
                       (%scope-covers-p scope corpus-id body-id))))

          ;; ── [#4C-2] ΠΡΑΓΜΑΤΙΚΗ source→text provenance ──
          (safe :replay/source-digest
                (lambda ()
                  (let ((dig (%sha256-hex-of-bytes (%source-bytes src))))
                    (and (equal dig (%g src :declared-digest))
                         (equal dig (%g (%g (%g bundle :receipt) "source_artifact") "content_sha256"))))))
          (safe :replay/provenance-root
                (lambda ()
                  (%validate-closed-alist er +extraction-keys+ "extraction-receipt" +extraction-schema+)
                  (%validate-closed-alist nr +normalization-keys+ "normalization-receipt" +normalization-schema+)
                  (equal (%g src :provenance-root)
                         (merkle:merkle-root-of-strings
                          (list (%sha256-hex-of-bytes (%source-bytes src))
                                (extraction-receipt-id er) (normalization-receipt-id nr))))))
          (safe :replay/extraction-replay
                (lambda ()
                  (let* ((sbytes (%source-bytes src))
                         (extracted (%apply-spans sbytes (%g er "spans"))))
                    (and (equal (%g er "input_digest") (%sha256-hex-of-bytes sbytes))
                         (equal (%g er "output_digest") (%sha256-hex-of-bytes extracted))))))
          (safe :replay/normalization-replay
                (lambda ()
                  (let* ((sbytes (%source-bytes src))
                         (extracted (%apply-spans sbytes (%g er "spans")))
                         (etext (babel:octets-to-string extracted :encoding :utf-8))
                         (normalized (%normalize-legal-text etext)))
                    (setf derived-text normalized)
                    (and (equal (%g nr "input_digest") (%g er "output_digest"))
                         (equal (%g nr "output_digest") (%sha256-hex-of-string normalized))))))
          ;; Η ΓΕΦΥΡΑ: το normalized κείμενο == graph text-version (byte-equiv)
          (safe :replay/text-equals-graph
                (lambda ()
                  (and rgraph derived-text
                       (let ((v (vg:version-at rgraph (%g tra :provision)
                                               :valid-at (%g tra :valid-at) :known-at (%g tra :known-at))))
                         (and v (equal derived-text (vg:tv-text v)))))))

          ;; RECEIPT: verify-receipt-intrinsic ΣΤΟΝ reconstructed graph
          (safe :replay/receipt-intrinsic
                (lambda ()
                  (and rgraph (multiple-value-bind (ok why)
                                  (lr:verify-receipt-intrinsic rgraph (%rebuild-receipt (%g bundle :receipt)))
                                (declare (ignore why)) ok))))
          (safe :replay/receipt-membership
                (lambda ()
                  (let* ((ids (%g env-census :receipt-ids))
                         (idx (%g (%g bundle :receipt-membership) :index))
                         (rid (%g (%g bundle :receipt) "receipt_id")))
                    (and (integerp idx) (< -1 idx (length ids)) (equal (nth idx ids) rid)
                         (equal (%g env-census :receipt-set-root) (merkle:merkle-root-of-strings ids))
                         (merkle:verify-inclusion (merkle:hash-leaf-string rid)
                          (merkle:inclusion-path (mapcar #'merkle:hash-leaf-string ids) idx)
                          (%g env-census :receipt-set-root))))))

          ;; [#4C-6] TRA recompute με anchor ΠΑΡΑΓΟΜΕΝΟ από το envelope (μη-κυκλικό)
          (safe :replay/tra-recompute
                (lambda ()
                  (and rgraph
                       (let* ((anchor (%derive-anchor envelope registry-digest req-verifier))
                              (recomputed (vg:make-effectivity-attestation
                                           rgraph (%g tra :provision) :valid-at (%g tra :valid-at)
                                           :known-at (%g tra :known-at) :corpus-id (%g tra :corpus-id)
                                           :anchor anchor :receipt-id (%g tra :receipt-id))))
                         (setf tra-hash (getf recomputed :hash))
                         (equal tra-hash (%g tra :hash))))))

          ;; [#4C-7] verifier-set = ΑΚΡΙΒΗΣ ισότητα sorted-unique sha256(bytes)
          (safe :replay/verifier-set-exact
                (lambda ()
                  (let ((recomputed (%verifier-set-recompute (%g bundle :verifier-binaries)))
                        (signed (sort (copy-list (or (%g envelope :verifier-set) '())) #'string<)))
                    (and (equal recomputed signed)
                         (stringp req-verifier) (member req-verifier recomputed :test #'equal) t))))

          ;; [#4C-8] EXTERNAL DELEGATION STATE (rollback/equivocation/compromise)
          (cond
            (known-delegation-state
             (safe :replay/delegation-no-rollback
                   (lambda ()
                     (let ((seq (%delegation-sequence envelope))
                           (latest (%g known-delegation-state :latest-sequence)))
                       (and (integerp seq) (integerp latest) (>= seq latest)))))
             (safe :replay/delegation-no-equivocation
                   (lambda ()
                     (let ((seq (%delegation-sequence envelope))
                           (latest (%g known-delegation-state :latest-sequence))
                           (khash (%g known-delegation-state :statement-hash)))
                       (or (not (eql seq latest)) (null khash)
                           (equal khash (%delegation-statement-hash envelope))))))
             (safe :replay/delegation-not-compromised
                   (lambda ()
                     (let ((cfrom (%g known-delegation-state :compromise-from))
                           (g (and release-gentime (apb::%normalize-gentime release-gentime))))
                       (or (null cfrom)
                           (and g (string< g (apb::%normalize-gentime cfrom))))))))
            ((%g policy :require-delegation-state)
             (pred :replay/delegation-state-required nil
                   "policy :require-delegation-state αλλά δεν δόθηκε known-delegation-state")))

          (setf auth-mode (if consumer-checkpoint :continuity-verified :first-seen))

          ;; ── ΑΠΟΝΟΜΗ ──
          (let* ((all-ok (every #'cadr preds))
                 (required (%g policy :required-tier))
                 (tier (cond ((and all-ok (eq auth-mode :continuity-verified)) "owner-pinned-authenticated")
                             (all-ok "internally-release-consistent")
                             (t "provisional-unanchored"))))
            (%make-aer-verdict
             :awarded-tier tier
             :satisfies-policy-p (or (null required) (apb:tier>= tier required))
             :reasons (nreverse reasons) :predicates (nreverse preds)
             :replayed-graph-root graph-root :replayed-graph-seq graph-seq
             :recomputed-tra-hash tra-hash :derived-text derived-text
             :authentication-mode auth-mode)))
        (when (and tmp-path (probe-file tmp-path)) (ignore-errors (delete-file tmp-path)))))))
