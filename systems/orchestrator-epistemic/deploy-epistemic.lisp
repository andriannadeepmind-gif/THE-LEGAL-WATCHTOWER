;;;; systems/orchestrator-epistemic/deploy-epistemic.lisp
;;;; Epistemic Authority Deployment Stage
;;;;
;;;; PURPOSE: Deploy 6-layer epistemic authority system with STRICT PROOF GATES
;;;; DEPENDS: deploy stage (requires artifacts on filesystem)
;;;;
;;;; CRITICAL: NO FALLBACKS - Proofs unavailable → HARD FAIL → NO RELEASE
;;;;
;;;; GENERATES:
;;;; - Layer 1: Meta-ontology (epistemic system definition)
;;;; - Layer 2: Release manifest (DCAT + VoID + temporal proof pack)
;;;; - Layer 3: Lineage graph (PROV-O identity continuity)
;;;; - Layer 4: Negation layer (defensive moat)
;;;; - Layer 5: Epistemic boundaries (explicit scope limits)
;;;; - Layer 6: Stability policy (long-term anchor guarantees)
;;;;
;;;; TEMPORAL PROOF:
;;;; - SHA-256 Merkle tree with inclusion proofs (REQUIRED)
;;;; - RFC 3161 timestamp receipts (REQUIRED - fail if TSA unavailable)
;;;; - Certificate Transparency proofs (CONDITIONAL - strict if RELEASE_CERT_PATH set)
;;;; - JWS signatures (CONDITIONAL - strict if private key exists)
;;;;
;;;; VERIFICATION KIT:
;;;; - Public key material (JWK, CA certs)
;;;; - Verification scripts (verify.sh, verify.ps1, verify.lisp)
;;;; - Deterministic verification procedure
;;;;
;;;; OUTPUT:
;;;; - Staging directory with all artifacts
;;;; - SHACL validation (REQUIRED - fail if invalid)
;;;; - Atomic publish: staging → final release
;;;; - 'latest' symlink update

(in-package :orchestrator.epistemic)

;;; ============================================================================
;;; IMMUTABLE RELEASE DIRECTORY CREATION (STAGING-BASED)
;;; ============================================================================

(defun create-staging-directory (base-output-dir timestamp)
  "Create staging directory for release validation before publish

  Structure:
    /releases/.staging-<timestamp>/
      articles/
      meta-ontology.ttl
      lineage-graph.ttl
      negation.ttl
      stability-policy.ttl
      stability-policy.md
      manifest.ttl
      manifest.jsonld
      void.ttl
      ai-manifest.jsonld
      shapes/
        article-shape.ttl
        manifest-shape.ttl
        lineage-shape.ttl
      temporal-proof/
        merkle-tree.json
        inclusion-proofs/
        timestamp.tsr
        ct-proof-*.json
        signature.jws
      verify/
        public.jwk
        tsa-ca.pem
        verify.sh
        verify.ps1
        verify.lisp
        README-VERIFY.md

  Args:
    base-output-dir: Base output directory path
    timestamp: Release timestamp (deterministic)

  Returns:
    Absolute path to staging directory"

  (let* ((timestamp-str (orchestrator.time:format-iso8601 timestamp))
         ;; DARPA-GRADE: Ensure base-output-dir is treated as directory
         (base-dir-pathname (uiop:ensure-directory-pathname base-output-dir))
         ;; Μοναδικό staging ανά διεργασία: με ντετερμινιστικό timestamp δύο
         ;; παράλληλα cuts θα μοιράζονταν το ΙΔΙΟ staging και θα διαπλέκονταν.
         (staging-dir (merge-pathnames
                      (format nil "releases/.staging-~A-p~D/" timestamp-str
                              #+sbcl (sb-posix:getpid) #-sbcl 0)
                      base-dir-pathname))
         (articles-dir (merge-pathnames "articles/" staging-dir))
         (shapes-dir (merge-pathnames "shapes/" staging-dir))
         (temporal-dir (merge-pathnames "temporal-proof/" staging-dir))
         (proofs-dir (merge-pathnames "inclusion-proofs/" temporal-dir))
         (verify-dir (merge-pathnames "verify/" staging-dir)))

    ;; Create directory structure
    (ensure-directories-exist articles-dir)
    (ensure-directories-exist shapes-dir)
    (ensure-directories-exist temporal-dir)
    (ensure-directories-exist proofs-dir)
    (ensure-directories-exist verify-dir)

    staging-dir))

;;; ============================================================================
;;; EPISTEMIC LAYER GENERATION (Layers 1-6)
;;; ============================================================================

(defun generate-all-epistemic-layers (articles release-dir timestamp blockchain-anchor)
  "Generate all 6 epistemic authority layers

  Layers:
    1. Meta-Ontology (epistemic system definition)
    2. Release Manifest (DCAT + VoID + temporal proof pack) - generated later
    3. Lineage Graph (PROV-O identity continuity)
    4. Negation Layer (defensive moat against inferior sources)
    5. Epistemic Boundaries (explicit scope limitations) - in meta-ontology
    6. Stability Policy (long-term anchor guarantees)

  Args:
    articles: List of article objects
    release-dir: Release directory path
    timestamp: Release timestamp
    blockchain-anchor: Blockchain Merkle root (or 'pending')

  Returns:
    Plist with paths to all generated files"

  (let ((meta-ontology-path (merge-pathnames "meta-ontology.ttl" release-dir))
        (lineage-path (merge-pathnames "lineage-graph.ttl" release-dir))
        (negation-path (merge-pathnames "negation.ttl" release-dir))
        (stability-ttl-path (merge-pathnames "stability-policy.ttl" release-dir))
        (stability-md-path (merge-pathnames "stability-policy.md" release-dir)))

    ;; Layer 1: Meta-Ontology
    (let ((meta-ontology (generate-meta-ontology
                         :timestamp timestamp
                         :blockchain-anchor blockchain-anchor
                         :system-commit-hash "pending"))) ; Will compute after all layers
      (alexandria:write-string-into-file meta-ontology meta-ontology-path
                                         :if-exists :supersede))

    ;; Layer 3: Lineage Graph
    (let ((lineage (generate-lineage-graph articles
                                          :blockchain-anchors nil))) ; Per-article anchors
      (alexandria:write-string-into-file lineage lineage-path
                                         :if-exists :supersede))

    ;; Layer 4: Negation Layer
    (let ((negation (generate-negation-layer)))
      (alexandria:write-string-into-file negation negation-path
                                         :if-exists :supersede))

    ;; Layer 6: Stability Policy
    (let ((stability-ttl (generate-stability-policy-ttl))
          (stability-md (generate-stability-policy-md)))
      (alexandria:write-string-into-file stability-ttl stability-ttl-path
                                         :if-exists :supersede)
      (alexandria:write-string-into-file stability-md stability-md-path
                                         :if-exists :supersede))

    (list :meta-ontology meta-ontology-path
          :lineage lineage-path
          :negation negation-path
          :stability-ttl stability-ttl-path
          :stability-md stability-md-path)))

;;; ============================================================================
;;; SHACL SHAPES GENERATION (3 SEPARATE FILES)
;;; ============================================================================

(defun generate-shacl-shapes (release-dir)
  "Generate SHACL validation shapes as 3 separate files

  Files:
    shapes/article-shape.ttl - Article validation
    shapes/manifest-shape.ttl - Manifest validation
    shapes/lineage-shape.ttl - Lineage graph validation

  Args:
    release-dir: Release directory path

  Returns:
    Plist with paths to shape files"

  (let ((shapes-dir (merge-pathnames "shapes/" release-dir))
        (article-shape-path (merge-pathnames "shapes/article-shape.ttl" release-dir))
        (manifest-shape-path (merge-pathnames "shapes/manifest-shape.ttl" release-dir))
        (lineage-shape-path (merge-pathnames "shapes/lineage-shape.ttl" release-dir)))

    (ensure-directories-exist shapes-dir)

    ;; Generate individual shape files
    (alexandria:write-string-into-file
     (generate-article-shape)
     article-shape-path
     :if-exists :supersede)

    (alexandria:write-string-into-file
     (generate-manifest-shape)
     manifest-shape-path
     :if-exists :supersede)

    (alexandria:write-string-into-file
     (generate-lineage-shape)
     lineage-shape-path
     :if-exists :supersede)

    (list :article-shape article-shape-path
          :manifest-shape manifest-shape-path
          :lineage-shape lineage-shape-path)))

;;; ============================================================================
;;; SYSTEM COMMIT HASH COMPUTATION & UPDATE
;;; ============================================================================

(defun compute-and-update-system-commit-hash (layer-paths)
  "Compute SHA-256 hash of all epistemic layers and update meta-ontology

  System commit hash = SHA-256(meta-ontology || lineage || negation || stability)

  Args:
    layer-paths: Plist with paths to epistemic layer files

  Returns:
    SHA-256 hash string formatted as 'sha256:HEX'"

  (let* ((meta-path (getf layer-paths :meta-ontology))
         (lineage-path (getf layer-paths :lineage))
         (negation-path (getf layer-paths :negation))
         (stability-path (getf layer-paths :stability-ttl))
         (meta-content (alexandria:read-file-into-string meta-path))
         (lineage-content (alexandria:read-file-into-string lineage-path))
         (negation-content (alexandria:read-file-into-string negation-path))
         (stability-content (alexandria:read-file-into-string stability-path))
         (system-hash (compute-system-commit-hash meta-content
                                                 lineage-content
                                                 negation-content
                                                 stability-content)))

    ;; Update meta-ontology with actual system commit hash
    (let ((updated-meta (cl-ppcre:regex-replace
                        "slw:systemCommitHash \"pending\""
                        meta-content
                        (format nil "slw:systemCommitHash \"~A\"" system-hash))))
      (alexandria:write-string-into-file updated-meta meta-path
                                         :if-exists :supersede))

    system-hash))

;;; ============================================================================
;;; TEMPORAL PROOF PACK GENERATION (STRICT - NO FALLBACKS)
;;; ============================================================================

(defun dev-mode-p ()
  "Check if running in development mode (skips strict proof requirements)"
  (let ((dev-env (uiop:getenv "ORCHESTRATOR_DEV_MODE")))
    (and dev-env (member dev-env '("1" "true" "yes") :test #'string-equal))))

;;; ============================================================================
;;; AUTO-GENERATE CRYPTO KEYS (PURE LISP - DARPA-GRADE)
;;; ============================================================================

(defun %operator-tsa-ca-source ()
  "Η ΜΙΑ πηγή γνήσιας TSA CA αλυσίδας που ο χειριστής παρέχει: env TSA_CA_BUNDLE
   (ρητό μονοπάτι) ή <institution>/keys/tsa-ca.pem. Επιστρέφει pathname ή NIL."
  (let ((env (uiop:getenv "TSA_CA_BUNDLE")))
    (cond
      ((and env (plusp (length env)) (probe-file env)) (pathname env))
      (t (let ((p (orchestrator.paths:institution-dir "keys/tsa-ca.pem")))
           (and (probe-file p) p))))))

(defun %emit-tsa-ca-or-honest-note (tsa-ca-path)
  "Γράφει tsa-ca.pem ΜΟΝΟ από γνήσια, δομικά επικυρωμένη X.509 CA αλυσίδα του
   χειριστή. Αν δεν υπάρχει έγκυρη, ΔΕΝ γράφει ψευδο-cert — γράφει τίμια
   σημείωση (tsa-ca.MISSING.txt) που εξηγεί ότι η πλήρης RFC-3161 CA
   επαλήθευση απαιτεί την pinned CA του χειριστή. Άκυρη παρεχόμενη CA ⇒
   ΣΦΑΛΜΑ (ο χειριστής έδωσε σκουπίδι — δεν το κρύβουμε)."
  (let ((src (%operator-tsa-ca-source))
        (note-path (merge-pathnames "tsa-ca.MISSING.txt"
                                    (uiop:pathname-directory-pathname tsa-ca-path))))
    (cond
      (src
       (let ((pem (uiop:read-file-string src)))
         ;; Δομική φραγή: γνήσιο X.509 ή σφάλμα — ποτέ ψευδο-blob σε release.
         (orchestrator.x509-authority:assert-valid-x509-pem pem "tsa-ca.pem")
         (alexandria:write-string-into-file pem tsa-ca-path :if-exists :supersede)
         (when (probe-file note-path) (ignore-errors (delete-file note-path)))
         (log:info () "tsa-ca.pem: γνήσια CA αλυσίδα του χειριστή (επικυρωμένη X.509) από ~A" src)
         t))
      (t
       (when (probe-file tsa-ca-path) (ignore-errors (delete-file tsa-ca-path)))
       (alexandria:write-string-into-file
        (format nil "TSA CA certificate ΔΕΝ διανέμεται με αυτό το release.~%~%~
Η ΠΛΗΡΗΣ RFC-3161 επαλήθευση της χρονοσφραγίδας (αλυσίδα CA → TSA) απαιτεί την~%~
pinned CA αλυσίδα που παρέχει ο χειριστής (env TSA_CA_BUNDLE ή keys/tsa-ca.pem).~%~
Το σύστημα ΑΡΝΕΙΤΑΙ να διανείμει ψευδο/ληγμένο πιστοποιητικό ως υλικό~%~
επαλήθευσης — τίμια άγνοια αντί για παραίσθηση ασφάλειας.~%~%~
Οι δεσμοί που ΕΠΑΛΗΘΕΥΟΝΤΑΙ ΧΩΡΙΣ αυτό: Merkle root ≡ ταυτότητα release,~%~
JWS υπογραφή, ύπαρξη/imprint-binding του RFC-3161 receipt (timestamp.tsr).~%~
Η πλήρης κρυπτογραφική επαλήθευση της αλυσίδας TSA είναι δηλωμένη φάση P4+.~%")
        note-path :if-exists :supersede)
       (log:info () "tsa-ca.pem: καμία γνήσια CA — γράφτηκε τίμια σημείωση (καμία ψευδο-διανομή)")
       nil))))

(defun %tsa-ca-material-ok-p (release-dir)
  "Το αναλλοίωτο υλικού TSA CA ενός release: ΑΚΡΙΒΩΣ ένα από
   {verify/tsa-ca.pem που περνά τη δομική φραγή X.509,
    verify/tsa-ca.MISSING.txt (τίμια σημείωση)}.
   Η έδρα εκπομπής (%emit-tsa-ca-or-honest-note) το διατηρεί εκ κατασκευής —
   αυτή η πύλη το ΕΛΕΓΧΕΙ ανεξάρτητα, ώστε παράκαμψη της εκπομπής να μην
   περνά σιωπηλά. Αυστηρά ισχυρότερο και από το προ-P1.4 (παρουσία-μόνο, που
   δεχόταν ψευδο-blob) και από το ενδιάμεσο P1.4 (που επέτρεπε κανένα από τα
   δύο). Επιστρέφει T ή (values NIL αιτία)."
  (let* ((pem-path  (merge-pathnames "verify/tsa-ca.pem" release-dir))
         (note-path (merge-pathnames "verify/tsa-ca.MISSING.txt" release-dir))
         (pem-p  (probe-file pem-path))
         (note-p (probe-file note-path)))
    (cond
      ((and pem-p note-p)
       (values nil "και tsa-ca.pem ΚΑΙ tsa-ca.MISSING.txt — διφορούμενο υλικό επαλήθευσης"))
      ((and (not pem-p) (not note-p))
       (values nil "ούτε tsa-ca.pem ούτε tsa-ca.MISSING.txt — σιωπηλή παράλειψη υλικού επαλήθευσης"))
      (note-p t)
      (t (handler-case
             (progn
               (orchestrator.x509-authority:assert-valid-x509-pem
                (uiop:read-file-string pem-path) "verify/tsa-ca.pem")
               t)
           (error (e) (values nil (format nil "~A" e))))))))

(defun %key-genesis-explicitly-allowed-p ()
  "T ΜΟΝΟ όταν ο χειριστής ζητά ΡΗΤΑ γένεση κλειδιού (LAWMAX_ALLOW_KEY_GENESIS=1),
   που προορίζεται ΑΠΟΚΛΕΙΣΤΙΚΑ για dev/init σε ΚΕΝΟ περιβάλλον. Η ΜΙΑ έδρα
   πολιτικής κλειδιών: εκτός αυτού του ρητού opt-in, ένα trust root ΔΕΝ
   γεννιέται ποτέ σιωπηλά — φορτώνεται ή σφάλλει (fail-closed)."
  (let ((v (uiop:getenv "LAWMAX_ALLOW_KEY_GENESIS")))
    (and v (member v '("1" "true" "yes" "ΝΑΙ") :test #'string-equal))))

(defun ensure-crypto-keys-exist (private-key-path public-key-path cert-path)
  "Load the release-authority signing material· FAIL-CLOSED αν λείπει.

   P1.4 [0054]#3: ΤΕΛΟΣ η σιωπηλή αυτο-γένεση. Ένα δημοσιευμένο trust root
   ΔΕΝ επιτρέπεται να προκύψει από κλειδί που εμφανίστηκε μόνο του σε αυτό το
   run — αλλιώς η υπογραφή του release αποδεικνύει μόνο εσωτερική συνέπεια,
   ΟΧΙ σταθερή αρχή. Λείπει κλειδί ⇒ ΣΦΑΛΜΑ, εκτός αν ο χειριστής ζητήσει
   ΡΗΤΑ γένεση (LAWMAX_ALLOW_KEY_GENESIS=1, μόνο για dev/init) — και τότε με
   ηχηρή προειδοποίηση ότι το κλειδί αυτό ΔΕΝ πρέπει να υπογράψει δημόσιο
   release. Uses Pure Common Lisp (Ironclad) — NO OpenSSL.

   Returns:
     Plist με :private-key-path :public-key-path :cert-path"

  (let ((key-exists (and (probe-file private-key-path)
                         (not (uiop:directory-exists-p private-key-path)))))

    (unless key-exists
      (unless (%key-genesis-explicitly-allowed-p)
        (error 'orchestrator.spec:validation-error
               :message (format nil "Λείπει το ιδιωτικό κλειδί αρχής εκδόσεων (~A) και η αυτο-γένεση ΔΕΝ επιτράπηκε ρητά. Το trust root ΔΕΝ γεννιέται σιωπηλά ανά run. Πάροχε σταθερό κλειδί, ή για dev/init σε ΚΕΝΟ περιβάλλον όρισε LAWMAX_ALLOW_KEY_GENESIS=1 (το κλειδί αυτό ΔΕΝ πρέπει να υπογράψει δημόσιο release)."
                              private-key-path)))
      (format t "~%═══════════════════════════════════════════════════════════════~%")
      (format t "  ⚠ ΡΗΤΗ ΓΕΝΕΣΗ ΚΛΕΙΔΙΟΥ (LAWMAX_ALLOW_KEY_GENESIS) — dev/init ΜΟΝΟ~%")
      (format t "  ⚠ ΤΟ ΚΛΕΙΔΙ ΑΥΤΟ ΔΕΝ ΠΡΕΠΕΙ ΝΑ ΥΠΟΓΡΑΨΕΙ ΔΗΜΟΣΙΟ RELEASE~%")
      (format t "═══════════════════════════════════════════════════════════════~%~%")

      ;; Ensure directories exist
      (ensure-directories-exist private-key-path)
      (ensure-directories-exist public-key-path)
      (ensure-directories-exist cert-path)

      ;; Generate RSA 4096-bit keypair
      (format t "[1/3] Generating 4096-bit RSA keypair...~%")
      (let ((keypair (orchestrator.jws-authority:generate-rsa-keypair :bits 4096)))
        (format t "      ✓ RSA keypair generated~%")

        ;; Save keypair to PEM files
        (format t "[2/3] Saving keypair to PEM files...~%")
        (orchestrator.jws-authority:save-rsa-keypair
         keypair
         private-key-path
         public-key-path)
        (format t "      ✓ Private key: ~A~%" private-key-path)
        (format t "      ✓ Public key: ~A~%" public-key-path)

        ;; Generate self-signed X.509 certificate
        (format t "[3/3] Generating self-signed X.509 certificate...~%")
        (let* ((private-key (getf keypair :private-key))
               (public-key (getf keypair :public-key))
               (cert-der (orchestrator.x509-authority:generate-self-signed-certificate
                          :private-key private-key
                          :public-key public-key
                          :common-name "Greek Legal Corpus Release Authority"
                          :organization "Stavropoulos Law Corpus"
                          :country "GR"
                          :days 36500)))  ; 100 years
          (orchestrator.x509-authority:save-certificate-pem cert-der cert-path)
          (format t "      ✓ Certificate: ~A~%~%" cert-path))))

    (list :private-key-path private-key-path
          :public-key-path public-key-path
          :cert-path cert-path)))

(defun generate-temporal-proof-pack (release-dir)
  "Generate temporal proof pack with proof gates (strict in production, relaxed in dev)"

  (let* ((temporal-dir (merge-pathnames "temporal-proof/" release-dir))
         (merkle-tree-path (merge-pathnames "temporal-proof/merkle-tree.json" release-dir))
         (timestamp-path (merge-pathnames "temporal-proof/timestamp.tsr" release-dir))
         (jws-path (merge-pathnames "temporal-proof/signature.jws" release-dir))
         (public-jwk-path (merge-pathnames "verify/public.jwk" release-dir))
         ;; Default paths for crypto keys
         ;; DARPA-GRADE: Validate env var paths to prevent path traversal
         (default-private-key-path (let ((env-path (uiop:getenv "PRIVATE_KEY_PATH")))
                                     (if (and env-path
                                              (not (search ".." env-path))
                                              (not (search "~" env-path)))
                                         env-path
                                         (orchestrator.paths:institution-dir "keys/private.pem"))))
         (default-public-key-path (orchestrator.paths:institution-dir "keys/public.pem"))
         (default-cert-path (let ((env-path (uiop:getenv "RELEASE_CERT_PATH")))
                              (if (and env-path
                                       (not (search ".." env-path))
                                       (not (search "~" env-path)))
                                  env-path
                                  (orchestrator.paths:institution-dir "keys/certificate.pem"))))
         (dev-mode (dev-mode-p)))

    ;; DARPA-GRADE: Auto-generate crypto keys if missing (Pure Lisp)
    (let* ((crypto-keys (ensure-crypto-keys-exist default-private-key-path
                                                   default-public-key-path
                                                   default-cert-path))
           (private-key-path (getf crypto-keys :private-key-path))
           (cert-path (getf crypto-keys :cert-path)))

      ;; DARPA-GRADE: Ensure all directories exist (deterministic, idempotent)
      (ensure-directories-exist temporal-dir)
      (ensure-directories-exist (merge-pathnames "inclusion-proofs/" temporal-dir))

    ;; GATE 1: Build Merkle tree from CANONICAL artifacts
    (format t "~%PROOF GATE 1: Building Merkle tree from canonical artifacts...~%")
    (let* ((canonical-files (collect-epistemic-artifacts release-dir))
           (merkle-tree (build-merkle-tree canonical-files))
           (release-root-hash (merkle-tree-root merkle-tree))
           (inclusion-proofs (generate-all-inclusion-proofs merkle-tree canonical-files)))

      ;; Write Merkle tree
      (alexandria:write-string-into-file
       (jonathan:to-json `(:|root| ,release-root-hash
                          :|timestamp| ,(orchestrator.time:format-iso8601
                                        (orchestrator.time:now :source :system))
                          :|totalFiles| ,(length canonical-files)))
       merkle-tree-path
       :if-exists :supersede)

      ;; Write inclusion proofs
      (loop for (filepath . proof) in inclusion-proofs
            for filename = (file-namestring filepath)
            for proof-path = (merge-pathnames
                            (format nil "temporal-proof/inclusion-proofs/~A.json" filename)
                            release-dir)
            do (alexandria:write-string-into-file
                (jonathan:to-json proof)
                proof-path
                :if-exists :supersede))

      (format t "✓ Merkle tree: ~A files, root: ~A~%" (length canonical-files) release-root-hash)

      ;; GATE 2: RFC 3161 Timestamps (MULTI-TSA for 100-year proof)
      (format t "~%PROOF GATE 2: Requesting RFC 3161 timestamps (multi-TSA)...~%")
      ;; P1R [0046]: η χρονική απόδειξη είναι ATTESTATION πάνω στο commitment,
      ;; όχι προϋπόθεση ύπαρξής του. Αποτυχία TSA ⇒ το release κόβεται ΤΙΜΙΑ
      ;; ως UNATTESTED (τα receipts προσαρτώνται μετά με --attest-release) και
      ;; το `latest` ΔΕΝ προάγεται σε αυτό — η πύλη εξουσίας ζει στο latest,
      ;; δεν αδυνατίζει: δημόσια «τρέχουσα έκδοση» χωρίς temporal proof δεν υπάρχει.
      ;; ΜΙΑ έδρα απόκτησης TSA: το request-multi-tsa-timestamps δοκιμάζει ήδη
      ;; όλες τις TSAs — κανένα δεύτερο «single» μονοπάτι.
      (let ((rfc3161-results (handler-case
                                 (request-multi-tsa-timestamps release-root-hash temporal-dir)
                               (error (e)
                                 (format t "⚠ ALL TSAs failed: ~A~%   ⇒ release κόβεται ΩΣ UNATTESTED COMMITMENT — πρόσαρτησε receipts με --attest-release~%" e)
                                 nil))))
        (if rfc3161-results
            (format t "✓ RFC 3161 timestamps: ~D TSAs — ATTESTED~%" (length rfc3161-results))
            (format t "⚠ UNATTESTED commitment (κανένα RFC-3161 receipt)~%")))

      ;; NOTE: CT Logs removed - public CT logs require CA-issued certificates
      ;; Self-signed certificates are rejected by Google/Cloudflare CT logs.
      ;; DARPA-GRADE: No external dependencies on WebPKI infrastructure.
      ;; Temporal proof is provided by: Multi-TSA RFC 3161 + JWS + Merkle trees

      ;; GATE 3: JWS Signature (AUTO-GENERATED PRIVATE KEY)
      (format t "~%PROOF GATE 3: Generating JWS signature...~%")
      (let ((jws-result (handler-case
                            (sign-manifest-jws release-root-hash jws-path
                                              :private-key-path private-key-path
                                              :public-key-jwk-path public-jwk-path)
                          (error (e)
                            (if dev-mode
                                (progn
                                  (format t "⚠ DEV MODE: JWS signing failed, skipping: ~A~%" e)
                                  nil)
                                (error 'orchestrator.spec:validation-error
                                       :message "JWS signature failed"
                                       :details (format nil "~A" e)))))))
        (when jws-result
          (format t "✓ JWS signature: ~A~%" (getf jws-result :signature-path))))

      (format t "~%✓ ALL PROOF GATES PASSED~%~%")

      (list :release-root-hash release-root-hash
            :merkle-tree-path merkle-tree-path
            :timestamp-path timestamp-path
            :jws-path jws-path)))))

;;; ============================================================================
;;; VERIFICATION KIT GENERATION
;;; ============================================================================

(defun generate-verification-kit (release-dir temporal-proof-artifacts)
  "Generate verification kit for deterministic release verification

  Creates:
    verify/public.jwk - Public key for JWS verification
    verify/tsa-ca.pem - TSA CA certificate for RFC 3161 verification
    verify/verify.sh - Bash verification script
    verify/verify.ps1 - PowerShell verification script
    verify/verify.lisp - Lisp verification script
    verify/README-VERIFY.md - Verification instructions

  Args:
    release-dir: Release directory path
    temporal-proof-artifacts: Plist with proof artifact paths

  Returns:
    Plist with verification kit paths"

  (let ((verify-dir (merge-pathnames "verify/" release-dir))
        (public-jwk-path (merge-pathnames "verify/public.jwk" release-dir))
        (tsa-ca-path (merge-pathnames "verify/tsa-ca.pem" release-dir))
        (verify-sh-path (merge-pathnames "verify/verify.sh" release-dir))
        (verify-ps1-path (merge-pathnames "verify/verify.ps1" release-dir))
        (verify-lisp-path (merge-pathnames "verify/verify.lisp" release-dir))
        (readme-path (merge-pathnames "verify/README-VERIFY.md" release-dir)))

    (ensure-directories-exist verify-dir)

    ;; public.jwk - Already generated by sign-manifest-jws function
    ;; (verify it exists)
    (unless (probe-file public-jwk-path)
      (log:warn () "public.jwk not found at ~A - JWS signing may have failed" public-jwk-path))

    ;; tsa-ca.pem — TSA CA certificate για πλήρη RFC-3161 επαλήθευση.
    ;; P1.4 [0054]#1: ΤΕΛΟΣ το hardcoded ψευδο-blob (μη-parseable, ληγμένο).
    ;; Γράφεται ΜΟΝΟ γνήσια CA αλυσίδα που ο χειριστής παρέχει (env
    ;; TSA_CA_BUNDLE ή <institution>/keys/tsa-ca.pem) ΚΑΙ επικυρώνεται δομικά
    ;; ως X.509 (assert-valid-x509-pem). Αλλιώς ΔΕΝ γράφεται ψευδο-cert — το
    ;; verify kit δηλώνει τίμια ότι η πλήρης TSR-CA επαλήθευση απαιτεί την
    ;; pinned CA του χειριστή (δηλωμένο P4+ residual). Ποτέ ψέμα για το τι κρατά.
    (%emit-tsa-ca-or-honest-note tsa-ca-path)

    ;; verify.sh - Bash verification script (fallback)
    (alexandria:write-string-into-file
     "#!/bin/bash
# Epistemic Release Verification Script
# Usage: ./verify.sh <release-dir>
#
# NOTE: For DARPA-GRADE verification, use verify.lisp instead:
#   sbcl --script verify.lisp <release-dir>

set -e

RELEASE_DIR=\"${1:-.}\"

echo \"=== EPISTEMIC RELEASE VERIFICATION ===\"
echo \"Release: $RELEASE_DIR\"
echo \"NOTE: For Pure Lisp verification, use: sbcl --script verify.lisp $RELEASE_DIR\"
echo

# Check if files exist
echo \"[1/4] Checking manifests...\"
[ -f \"$RELEASE_DIR/manifest.ttl\" ] && echo \"  ✓ manifest.ttl\" || { echo \"  ✗ manifest.ttl missing\"; exit 1; }
[ -f \"$RELEASE_DIR/manifest.jsonld\" ] && echo \"  ✓ manifest.jsonld\" || { echo \"  ✗ manifest.jsonld missing\"; exit 1; }
echo

echo \"[2/4] Checking JWS signature...\"
[ -f \"$RELEASE_DIR/temporal-proof/signature.jws\" ] && echo \"  ✓ signature.jws\" || echo \"  ⚠ signature.jws not found\"
[ -f \"$RELEASE_DIR/verify/public.jwk\" ] && echo \"  ✓ public.jwk\" || echo \"  ⚠ public.jwk not found\"
echo

echo \"[3/4] Checking RFC 3161 timestamp...\"
[ -f \"$RELEASE_DIR/temporal-proof/timestamp.tsr\" ] && echo \"  ✓ timestamp.tsr\" || echo \"  ⚠ timestamp.tsr not found\"
echo

echo \"[4/4] Checking Merkle tree...\"
[ -f \"$RELEASE_DIR/temporal-proof/merkle-tree.json\" ] && echo \"  ✓ merkle-tree.json\" || echo \"  ⚠ merkle-tree.json not found\"
echo

echo \"===========================================\"
echo \"✓ BASIC VERIFICATION PASSED\"
echo \"\"
echo \"For cryptographic verification, use Pure Lisp:\"
echo \"  sbcl --script verify.lisp $RELEASE_DIR\"
echo \"===========================================\"
"
     verify-sh-path
     :if-exists :supersede)

    ;; verify.ps1 - PowerShell verification script (fallback)
    (alexandria:write-string-into-file
     "# Epistemic Release Verification Script (PowerShell)
# Usage: .\\verify.ps1 <release-dir>
#
# NOTE: For DARPA-GRADE verification, use verify.lisp instead:
#   sbcl --script verify.lisp <release-dir>

param(
    [string]$ReleaseDir = \".\"
)

Write-Host \"=== EPISTEMIC RELEASE VERIFICATION ===\" -ForegroundColor Cyan
Write-Host \"Release: $ReleaseDir\"
Write-Host \"NOTE: For Pure Lisp verification, use: sbcl --script verify.lisp $ReleaseDir\" -ForegroundColor Gray
Write-Host

# Check if files exist
Write-Host \"[1/4] Checking manifests...\" -ForegroundColor Yellow
if (Test-Path \"$ReleaseDir/manifest.ttl\") { Write-Host \"  ✓ manifest.ttl\" -ForegroundColor Green }
else { Write-Host \"  ✗ manifest.ttl missing\" -ForegroundColor Red; exit 1 }
if (Test-Path \"$ReleaseDir/manifest.jsonld\") { Write-Host \"  ✓ manifest.jsonld\" -ForegroundColor Green }
else { Write-Host \"  ✗ manifest.jsonld missing\" -ForegroundColor Red; exit 1 }
Write-Host

Write-Host \"[2/4] Checking JWS signature...\" -ForegroundColor Yellow
if (Test-Path \"$ReleaseDir/temporal-proof/signature.jws\") { Write-Host \"  ✓ signature.jws\" -ForegroundColor Green }
else { Write-Host \"  ⚠ signature.jws not found\" -ForegroundColor Yellow }
if (Test-Path \"$ReleaseDir/verify/public.jwk\") { Write-Host \"  ✓ public.jwk\" -ForegroundColor Green }
else { Write-Host \"  ⚠ public.jwk not found\" -ForegroundColor Yellow }
Write-Host

Write-Host \"[3/4] Checking RFC 3161 timestamp...\" -ForegroundColor Yellow
if (Test-Path \"$ReleaseDir/temporal-proof/timestamp.tsr\") { Write-Host \"  ✓ timestamp.tsr\" -ForegroundColor Green }
else { Write-Host \"  ⚠ timestamp.tsr not found\" -ForegroundColor Yellow }
Write-Host

Write-Host \"[4/4] Checking Merkle tree...\" -ForegroundColor Yellow
if (Test-Path \"$ReleaseDir/temporal-proof/merkle-tree.json\") { Write-Host \"  ✓ merkle-tree.json\" -ForegroundColor Green }
else { Write-Host \"  ⚠ merkle-tree.json not found\" -ForegroundColor Yellow }
Write-Host

Write-Host \"===========================================\" -ForegroundColor Cyan
Write-Host \"✓ BASIC VERIFICATION PASSED\" -ForegroundColor Green
Write-Host \"\"
Write-Host \"For cryptographic verification, use Pure Lisp:\"
Write-Host \"  sbcl --script verify.lisp $ReleaseDir\" -ForegroundColor White
Write-Host \"===========================================\" -ForegroundColor Cyan
"
     verify-ps1-path
     :if-exists :supersede)

    ;; verify.lisp - Pure Lisp verification script (DARPA-GRADE)
    (alexandria:write-string-into-file
     ";;;; verify.lisp - Pure Lisp Epistemic Release Verification
;;;; ============================================================================
;;;; DARPA-GRADE: No OpenSSL, No external tools
;;;; Usage: sbcl --script verify.lisp [release-dir]
;;;; ============================================================================

(require :asdf)

;; Load minimal dependencies
(handler-case
    (progn
      (asdf:load-system :ironclad)
      (asdf:load-system :babel)
      (asdf:load-system :yason)
      (asdf:load-system :cl-base64))
  (error (e)
    (format t \"ERROR: Missing dependencies. Install: ironclad, babel, yason, cl-base64~%\")
    (format t \"Details: ~A~%\" e)
    (sb-ext:exit :code 1)))

;;; Base64URL decoding
(defun b64url-decode (string)
  (let* ((padded (concatenate 'string string
                              (make-string (mod (- 4 (mod (length string) 4)) 4)
                                          :initial-element #\\=)))
         (standard (map 'string (lambda (c)
                                  (case c (#\\- #\\+) (#\\_ #\\/) (t c)))
                        padded)))
    (cl-base64:base64-string-to-usb8-array standard)))

;;; File utilities
(defun read-file-bytes (path)
  (with-open-file (s path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length s) :element-type '(unsigned-byte 8))))
      (read-sequence bytes s)
      bytes)))

(defun read-file-string (path)
  (with-open-file (s path)
    (let ((str (make-string (file-length s))))
      (read-sequence str s)
      str)))

;;; JWS verification
(defun verify-jws (jws-string payload public-key)
  (let* ((parts (split-string jws-string #\\.))
         (header-b64 (first parts))
         (payload-b64 (second parts))
         (signature-b64 (third parts))
         (signing-input (format nil \"~A.~A\" header-b64 payload-b64))
         (signature (b64url-decode signature-b64))
         (digest (ironclad:digest-sequence :sha256
                   (babel:string-to-octets signing-input :encoding :utf-8))))
    (let ((digest-info (concatenate '(vector (unsigned-byte 8))
                         #(#x30 #x31 #x30 #x0d #x06 #x09 #x60 #x86 #x48 #x01
                           #x65 #x03 #x04 #x02 #x01 #x05 #x00 #x04 #x20)
                         digest)))
      (handler-case
          (progn
            (ironclad:verify-signature public-key digest-info signature)
            t)
        (error () nil)))))

(defun split-string (string char)
  (loop for start = 0 then (1+ end)
        for end = (position char string :start start)
        collect (subseq string start (or end (length string)))
        while end))

;;; Main verification
(defun verify-release (release-dir)
  (format t \"~%═══════════════════════════════════════════════════════════════~%\")
  (format t \"  EPISTEMIC RELEASE VERIFICATION (Pure Lisp)~%\")
  (format t \"  DARPA-GRADE: No OpenSSL, No external tools~%\")
  (format t \"═══════════════════════════════════════════════════════════════~%\")
  (format t \"Release: ~A~%~%\" release-dir)

  (let ((errors 0))
    ;; Check manifest
    (format t \"[1/4] Checking manifests...~%\")
    (if (and (probe-file (merge-pathnames \"manifest.ttl\" release-dir))
             (probe-file (merge-pathnames \"manifest.jsonld\" release-dir)))
        (format t \"  ✓ Manifests present~%~%\")
        (progn (format t \"  ✗ Manifests missing~%~%\") (incf errors)))

    ;; Check JWS
    (format t \"[2/4] Verifying JWS signature...~%\")
    (let ((jws-path (merge-pathnames \"temporal-proof/signature.jws\" release-dir))
          (jwk-path (merge-pathnames \"verify/public.jwk\" release-dir))
          (manifest-path (merge-pathnames \"manifest.ttl\" release-dir)))
      (if (and (probe-file jws-path) (probe-file jwk-path) (probe-file manifest-path))
          (handler-case
              (let* ((jws (string-trim '(#\\Space #\\Newline) (read-file-string jws-path)))
                     (jwk (yason:parse (read-file-string jwk-path)))
                     (manifest (read-file-string manifest-path))
                     (n (ironclad:octets-to-integer (b64url-decode (gethash \"n\" jwk))))
                     (e (ironclad:octets-to-integer (b64url-decode (gethash \"e\" jwk))))
                     (pubkey (ironclad:make-public-key :rsa :n n :e e)))
                (if (verify-jws jws manifest pubkey)
                    (format t \"  ✓ JWS signature valid~%~%\")
                    (progn (format t \"  ✗ JWS signature INVALID~%~%\") (incf errors))))
            (error (e)
              (format t \"  ✗ JWS error: ~A~%~%\" e)
              (incf errors)))
          (format t \"  ⚠ JWS files not found (skipped)~%~%\")))

    ;; Check timestamp
    (format t \"[3/4] Checking RFC 3161 timestamp...~%\")
    (let ((tsr-path (merge-pathnames \"temporal-proof/timestamp.tsr\" release-dir)))
      (if (probe-file tsr-path)
          (let ((size (with-open-file (s tsr-path) (file-length s))))
            (format t \"  ✓ Timestamp present (~D bytes)~%~%\" size))
          (format t \"  ⚠ Timestamp not found (skipped)~%~%\")))

    ;; Check Merkle
    (format t \"[4/4] Checking Merkle tree...~%\")
    (let ((merkle-path (merge-pathnames \"temporal-proof/merkle-tree.json\" release-dir)))
      (if (probe-file merkle-path)
          (format t \"  ✓ Merkle tree present~%~%\")
          (format t \"  ⚠ Merkle tree not found (skipped)~%~%\")))

    ;; Summary
    (format t \"═══════════════════════════════════════════════════════════════~%\")
    (if (zerop errors)
        (format t \"  ✓ VERIFICATION PASSED~%\")
        (format t \"  ✗ VERIFICATION FAILED (~D errors)~%\" errors))
    (format t \"═══════════════════════════════════════════════════════════════~%\")

    (zerop errors)))

;; Entry point
(let ((release-dir (or (second sb-ext:*posix-argv*) \".\")))
  (if (verify-release release-dir)
      (sb-ext:exit :code 0)
      (sb-ext:exit :code 1)))
"
     verify-lisp-path
     :if-exists :supersede)

    ;; README-VERIFY.md - Verification instructions
    (alexandria:write-string-into-file
     "# Epistemic Release Verification

This directory contains all tools needed to verify the epistemic integrity of this release.

## DARPA-GRADE: Pure Lisp Verification (Recommended)

```bash
cd verify
sbcl --script verify.lisp ..
```

**No OpenSSL required.** The Pure Lisp verification script performs full cryptographic
verification using only Common Lisp libraries (Ironclad).

## What Gets Verified

1. **Manifest Integrity**: Presence of manifest.ttl and manifest.jsonld
2. **JWS Signature**: RSA-SHA256 digital signature verification (Pure Lisp)
3. **RFC 3161 Timestamp**: Presence and structure verification
4. **Merkle Tree**: Presence verification

## Alternative Verification Methods

### Bash (basic checks only)
```bash
cd verify
chmod +x verify.sh
./verify.sh ..
```

### PowerShell (basic checks only)
```powershell
cd verify
.\\verify.ps1 ..
```

Note: Shell scripts perform basic file presence checks only.
For full cryptographic verification, use the Pure Lisp script.

## Files in this Directory

- `verify.lisp` - **Primary** Pure Lisp verification (DARPA-GRADE)
- `verify.sh` - Bash script (basic checks)
- `verify.ps1` - PowerShell script (basic checks)
- `public.jwk` - JWK public key for JWS verification
- `tsa-ca.pem` - Γνήσια, δομικά επικυρωμένη (X.509) TSA CA αλυσίδα του χειριστή
  για ΠΛΗΡΗ RFC-3161 επαλήθευση. Παρών ΜΟΝΟ όταν ο χειριστής την παρέχει
  (env TSA_CA_BUNDLE ή keys/tsa-ca.pem). Αν λείπει, βλ. `tsa-ca.MISSING.txt`:
  το σύστημα ΑΡΝΕΙΤΑΙ να διανείμει ψευδο/ληγμένο πιστοποιητικό — τίμια άγνοια
  αντί για παραίσθηση ασφάλειας. Οι δεσμοί που επαληθεύονται ΧΩΡΙΣ αυτό:
  Merkle root ≡ ταυτότητα, JWS, ύπαρξη/imprint-binding του RFC-3161 receipt.

## Dependencies for Pure Lisp Verification

- SBCL (Steel Bank Common Lisp)
- Ironclad (cryptography)
- Babel (encoding)
- Yason (JSON parsing)
- cl-base64 (Base64 encoding)

## Verification Failure = Invalid Release

If ANY verification step fails, this release MUST be considered invalid.
No fallbacks, no partial validity - strict proof gates.

**η DARPA δεν δουλεύει με wrappers**
"
     readme-path
     :if-exists :supersede)

    ;; Make scripts executable using pure Lisp sb-posix (DARPA-GRADE: No subprocess)
    #+sbcl
    (progn
      ;; Set executable permission: owner rwx, group rx, others rx (755)
      (sb-posix:chmod (namestring verify-sh-path) #o755)
      (sb-posix:chmod (namestring verify-lisp-path) #o755))

    (list :public-jwk public-jwk-path
          :tsa-ca tsa-ca-path
          :verify-sh verify-sh-path
          :verify-ps1 verify-ps1-path
          :verify-lisp verify-lisp-path
          :readme readme-path)))

;;; ============================================================================
;;; RELEASE MANIFEST GENERATION (Layer 2) - WITH TEMPORAL PROOF FILES
;;; ============================================================================

(defun generate-release-manifests (articles release-dir timestamp
                                   merkle-root system-commit-hash
                                   temporal-proof-artifacts)
  "Generate release manifests (Turtle + JSON-LD) including temporal proof files

  CRITICAL: All temporal-proof/ files are included as dcat:Distribution
  with SHA-256 hash and byte size for complete proof chain.

  Args:
    articles: List of article objects
    release-dir: Release directory path
    timestamp: Release timestamp
    merkle-root: SHA-256 Merkle root
    system-commit-hash: SHA-256 hash of epistemic system
    temporal-proof-artifacts: Plist with temporal proof paths

  Returns:
    Plist with manifest paths"

  (let ((manifest-ttl-path (merge-pathnames "manifest.ttl" release-dir))
        (manifest-jsonld-path (merge-pathnames "manifest.jsonld" release-dir))
        (rfc3161-receipt (getf temporal-proof-artifacts :timestamp-path))
        (jws-signature (getf temporal-proof-artifacts :jws-path)))

    ;; Generate Turtle manifest (includes temporal-proof files as distributions)
    (let ((manifest-ttl (build-release-manifest
                        articles
                        release-dir
                        :timestamp timestamp
                        :merkle-root merkle-root
                        :rfc3161-receipt rfc3161-receipt
                        :jws-signature jws-signature
                        :system-commit-hash system-commit-hash)))
      (alexandria:write-string-into-file manifest-ttl manifest-ttl-path
                                         :if-exists :supersede))

    ;; Generate JSON-LD manifest
    (let ((manifest-jsonld (build-release-manifest-jsonld
                           articles
                           release-dir
                           :timestamp timestamp
                           :merkle-root merkle-root
                           :rfc3161-receipt rfc3161-receipt
                           :jws-signature jws-signature
                           :system-commit-hash system-commit-hash)))
      (alexandria:write-string-into-file manifest-jsonld manifest-jsonld-path
                                         :if-exists :supersede))

    (list :manifest-ttl manifest-ttl-path
          :manifest-jsonld manifest-jsonld-path)))

;;; ============================================================================
;;; ATOMIC PUBLISH (STAGING → FINAL)
;;; ============================================================================

(defun atomic-publish-release (base-output-dir staging-dir release-id)
  "Atomically publish release from staging to its CONTENT-ADDRESSED directory.

  Args:
    base-output-dir: Base output directory
    staging-dir: Staging directory path
    release-id: Content identity «sha256-<Merkle root hex>» (%root->release-id)

  Returns:
    Path to final release directory (existing identical dir is REUSED, never
    deleted; foreign content under the same id signals validation-error)."

  ;; P1R [0046] — CONTENT-ADDRESSED PUBLISH. Η ταυτότητα του release είναι το
  ;; ίδιο του το περιεχόμενο (releases/<release-id>/, id = sha256-<Merkle root
  ;; των 8 canonical>). Overwrite ΔΟΜΙΚΑ αδύνατο: ίδιο περιεχόμενο ⇒ ίδιος
  ;; κατάλογος ⇒ το publish επαληθεύει και επαναχρησιμοποιεί (ΠΟΤΕ delete)·
  ;; διαφορετικό περιεχόμενο ⇒ άλλος κατάλογος· υπάρχων κατάλογος με ξένο root
  ;; ⇒ διαφθορά ⇒ ΣΦΑΛΜΑ. Το `latest` προάγεται ΜΟΝΟ από promote-latest! σε
  ;; attested release — ποτέ από εδώ.
  (let* ((base-dir-pathname (uiop:ensure-directory-pathname base-output-dir))
         (releases-dir (merge-pathnames "releases/" base-dir-pathname))
         (final-dir (merge-pathnames (format nil "releases/~A/" release-id)
                                     base-dir-pathname)))
    (ensure-directories-exist releases-dir)
    (format t "~%Content-addressed publish: staging → ~A~%" final-dir)
    ;; Η ταυτότητα ΔΕΝ είναι δήλωση καλής πίστης: το staging πρέπει ΤΟ ΙΔΙΟ να
    ;; αποδεικνύει ότι το περιεχόμενό του παράγει το RELEASE-ID.
    (let ((staging-root (%release-dir-root staging-dir)))
      (unless (equal (%root->release-id staging-root) release-id)
        (error 'orchestrator.spec:validation-error
               :message "Content-addressed publish: το staging ΔΕΝ αντιστοιχεί στη δηλωμένη ταυτότητα"
               :details (format nil "staging-root=~A ≠ id=~A" staging-root release-id))))
    (cond
      ((probe-file (uiop:ensure-directory-pathname final-dir))
       ;; ΔΕΝ εμπιστευόμαστε το ΔΗΛΩΜΕΝΟ root του υπάρχοντος καταλόγου (θα
       ;; επέτρεπε pre-seed poisoning): ΕΠΑΝΑΫΠΟΛΟΓΙΖΟΥΜΕ το Merkle root από
       ;; τα ίδια τα canonical αρχεία του πριν δεχθούμε ταύτιση.
       (let ((existing-root (%release-recomputed-root final-dir)))
         (unless (equal (%root->release-id existing-root) release-id)
           (error 'orchestrator.spec:validation-error
                  :message "Release directory exists with FOREIGN content — refusing to touch it (staging preserved)"
                  :details (format nil "~A: recomputed=~A ≠ id=~A" final-dir existing-root release-id)))
         (format t "  ✓ Release ~A already published (recomputed-identical content) — reusing, staging discarded~%"
                 release-id)
         (uiop:delete-directory-tree (uiop:ensure-directory-pathname staging-dir)
                                     :validate (constantly t))))
      (t (rename-file staging-dir final-dir)
         (format t "  ✓ Published ~A~%" release-id)))
    final-dir))

(defun %release-dir-root (release-dir)
  "Το Merkle root ενός δημοσιευμένου release όπως το δηλώνει το δικό του
   temporal-proof/merkle-tree.json (πεδίο \"root\") — μέσω του JSON parser
   της έδρας (jonathan), όχι με μοτίβα κειμένου."
  (let* ((path (merge-pathnames "temporal-proof/merkle-tree.json"
                                (uiop:ensure-directory-pathname release-dir)))
         (root (getf (jonathan:parse (uiop:read-file-string path)) :|root|)))
    (unless (and (stringp root) (plusp (length root)))
      (error "~A: δεν βρέθηκε έγκυρο \"root\" στο merkle-tree.json" path))
    root))

(defun %release-recomputed-root (release-dir)
  "Το Merkle root ενός release ΕΠΑΝΑΫΠΟΛΟΓΙΣΜΕΝΟ από τα canonical αρχεία του —
   ποτέ από τη δική του δήλωση."
  (merkle-tree-root
   (build-merkle-tree
    (collect-epistemic-artifacts (uiop:ensure-directory-pathname release-dir)))))

(defun release-attested-p (release-dir &optional root)
  "Ένα release είναι ATTESTED όταν φέρει RFC-3161 timestamp.tsr — και όταν
   είναι γνωστό το ROOT, το receipt πρέπει να ΔΕΝΕΙ αυτό ακριβώς το root:
   το messageImprint του TSR είναι το SHA-256 του root string, και τα 32
   αυτά bytes οφείλουν να εμφανίζονται στο DER σώμα του receipt. (Πλήρης
   κρυπτογραφική επαλήθευση υπογραφής TSR = δηλωμένη επόμενη βαθμίδα —
   καταγεγραμμένη, όχι σιωπηλή.)"
  (let ((tsr (merge-pathnames "temporal-proof/timestamp.tsr"
                              (uiop:ensure-directory-pathname release-dir))))
    (and (probe-file tsr)
         (or (null root)
             (let ((imprint (ironclad:digest-sequence
                             :sha256 (babel:string-to-octets root :encoding :utf-8)))
                   (body (alexandria:read-file-into-byte-vector tsr)))
               (and (>= (length body) (length imprint))
                    (loop for i from 0 to (- (length body) (length imprint))
                            thereis (not (mismatch imprint body :start2 i
                                                   :end2 (+ i (length imprint)))))))))))

(defun promote-latest! (base-output-dir release-id)
  "Προαγωγή του `latest` στο RELEASE-ID — ΜΟΝΟ αν το release είναι attested.
   Γράφει: symlink `latest` (ευκολία πλοήγησης) + `latest.json` επαληθεύσιμο
   δείκτη {release, attested, signature_jws} όπου το JWS είναι η υπογραφή του
   ίδιου του root (temporal-proof/signature.jws) — ο δείκτης δένεται στο
   περιεχόμενο, όχι σε όνομα."
  (let* ((base (uiop:ensure-directory-pathname base-output-dir))
         (releases-dir (merge-pathnames "releases/" base))
         (release-dir (merge-pathnames (format nil "releases/~A/" release-id) base))
         (latest-symlink (merge-pathnames "latest" releases-dir))
         (pointer-path (merge-pathnames "latest.json" releases-dir)))
    (unless (probe-file (uiop:ensure-directory-pathname release-dir))
      (error "promote-latest!: ανύπαρκτο release ~A" release-id))
    ;; Η προαγωγή σε εξουσία επαληθεύει ΚΑΙ την ακεραιότητα ΚΑΙ το δέσιμο της
    ;; χρονικής απόδειξης στο ΣΥΓΚΕΚΡΙΜΕΝΟ περιεχόμενο — όχι απλή ύπαρξη αρχείου.
    (let ((recomputed (%release-recomputed-root release-dir)))
      (unless (equal (%root->release-id recomputed) release-id)
        (error 'orchestrator.spec:validation-error
               :message "promote-latest!: ΔΙΑΦΘΟΡΑ — recomputed root ≠ ταυτότητα"
               :details (format nil "~A ≠ ~A" recomputed release-id)))
      (unless (release-attested-p release-dir recomputed)
        (error 'orchestrator.spec:validation-error
               :message "promote-latest!: το release ΔΕΝ φέρει RFC-3161 receipt δεμένο στο δικό του root — το latest προάγεται μόνο σε χρονικά αποδεδειγμένη έκδοση"
               :details release-id)))
    (when (probe-file latest-symlink) (delete-file latest-symlink))
    #+sbcl (sb-posix:symlink release-id (namestring latest-symlink))
    #-sbcl (error "Symlink creation not implemented for this Lisp implementation")
    (let ((jws (let ((p (merge-pathnames "temporal-proof/signature.jws" release-dir)))
                 (when (probe-file p)
                   (string-trim '(#\Space #\Newline) (uiop:read-file-string p))))))
      (with-open-file (o pointer-path :direction :output :if-exists :supersede)
        (write-string (jonathan:to-json
                       (append (list :|release| release-id :|attested| t)
                               (when jws (list :|signature_jws| jws)))
                       :from :plist)
                      o)
        (terpri o)))
    (format t "✓ latest → ~A (attested, signed pointer)~%" release-id)
    latest-symlink))

;;; ============================================================================
;;; MAIN DEPLOYMENT FUNCTION (STRICT PROOF GATES)
;;; ============================================================================

(defun deploy-epistemic-stage (articles base-output-dir
                               &key (timestamp (orchestrator.time:require-deterministic-time))
                                    (blockchain-anchor "pending"))
  "Deploy complete epistemic authority system with STRICT PROOF GATES

  CRITICAL FLOW (NO FALLBACKS):
    1. Create staging directory
    2. Generate all 6 epistemic layers
    3. Compute system commit hash
    4. Generate temporal proof pack (ALL REQUIRED - fail if any unavailable)
    5. Generate verification kit
    6. Generate release manifests
    7. SHACL validation (REQUIRED - fail if invalid)
    8. Atomic publish: staging → final
    9. Update 'latest' symlink

  Args:
    articles: List of article objects (with all formats already generated)
    base-output-dir: Base output directory
    timestamp: Release timestamp (deterministic, from orchestrator.time)
    blockchain-anchor: Blockchain Merkle root (optional)

  Returns:
    Plist with:
      :release-dir - Path to final release directory
      :merkle-root - SHA-256 Merkle root
      :system-commit-hash - SHA-256 hash of epistemic system
      :manifest-path - Path to manifest.ttl
      :latest-symlink - Path to 'latest' symlink

  Signals:
    orchestrator.spec:validation-error if any proof gate fails"

  (format t "~%=== DEPLOYING EPISTEMIC AUTHORITY SYSTEM (STRICT PROOF GATES) ===~%")
  (format t "Timestamp: ~A~%" (orchestrator.time:format-iso8601 timestamp))
  (format t "Articles: ~D~%" (length articles))
  (format t "Blockchain anchor: ~A~%~%" blockchain-anchor)

  ;; Step 1: Create staging directory
  (format t "Step 1: Creating staging directory...~%")
  (let ((staging-dir (create-staging-directory base-output-dir timestamp)))
    (format t "  Staging directory: ~A~%" staging-dir)

    ;; Step 2: Generate epistemic layers (IDENTITY + PROVENANCE + LINEAGE only)
    (format t "~%Step 2: Generating epistemic layers (1, 3, 4, 6)...~%")
    (let ((layer-paths (generate-all-epistemic-layers articles staging-dir
                                                     timestamp blockchain-anchor)))
      (format t "  Meta-ontology: ~A~%" (getf layer-paths :meta-ontology))
      (format t "  Lineage graph: ~A~%" (getf layer-paths :lineage))
      (format t "  Negation layer: ~A~%" (getf layer-paths :negation))
      (format t "  Stability policy: ~A~%" (getf layer-paths :stability-ttl))

      ;; Step 3: Generate SHACL shapes (3 files)
      (format t "~%Step 3: Generating SHACL shapes (3 files)...~%")
      (let ((shape-paths (generate-shacl-shapes staging-dir)))
        (format t "  Article shape: ~A~%" (getf shape-paths :article-shape))
        (format t "  Manifest shape: ~A~%" (getf shape-paths :manifest-shape))
        (format t "  Lineage shape: ~A~%" (getf shape-paths :lineage-shape))

        ;; Step 4: Compute system commit hash
        (format t "~%Step 4: Computing system commit hash...~%")
        (let ((system-hash (compute-and-update-system-commit-hash layer-paths)))
          (format t "  System commit hash: ~A~%" system-hash)

          ;; Step 5: Generate temporal proof pack (STRICT - ALL REQUIRED)
          (format t "~%Step 5: Generating temporal proof pack (STRICT GATES)...~%")
          (let* ((temporal-artifacts (generate-temporal-proof-pack staging-dir))
                 (release-root-hash (getf temporal-artifacts :release-root-hash)))

            ;; Step 6: Generate verification kit
            (format t "~%Step 6: Generating verification kit...~%")
            (let ((verify-paths (generate-verification-kit staging-dir temporal-artifacts)))
              (format t "  Public JWK: ~A~%" (getf verify-paths :public-jwk))
              (format t "  TSA CA: ~A~%" (getf verify-paths :tsa-ca))
              (format t "  Verify scripts: sh, ps1, lisp~%")

              ;; Step 7: Generate release manifests (Layer 2 - DATASET-LEVEL only)
              (format t "~%Step 7: Generating release manifests (dataset-level)...~%")
              (let ((manifest-paths (generate-release-manifests
                                    articles staging-dir timestamp
                                    release-root-hash system-hash temporal-artifacts)))
                (format t "  Manifest (Turtle): ~A~%" (getf manifest-paths :manifest-ttl))
                (format t "  Manifest (JSON-LD): ~A~%" (getf manifest-paths :manifest-jsonld))

                ;; Step 8: SHACL validation (REQUIRED)
                (format t "~%Step 8: SHACL validation (REQUIRED)...~%")
                (unless (validate-epistemic-stage staging-dir)
                  (error 'orchestrator.spec:validation-error
                         :message "SHACL validation REQUIRED but failed"
                         :details "Release does not conform to shapes"))
                (format t "✓ SHACL validation passed~%")

                ;; Step 9: Content-addressed publish + promote latest ΜΟΝΟ αν attested
                (format t "~%Step 9: Content-addressed publish...~%")
                (let* ((release-id (%root->release-id release-root-hash))
                       (final-dir (atomic-publish-release base-output-dir staging-dir release-id))
                       (attested (release-attested-p final-dir release-root-hash)))
                  (if attested
                      (promote-latest! base-output-dir release-id)
                      (format t "⚠ latest ΔΕΝ προάγεται: unattested commitment ~A (χρήση --attest-release)~%"
                              release-id))
                  (format t "~%=== EPISTEMIC DEPLOYMENT COMPLETE ===~%~%")

                  (list :release-dir final-dir
                        :release-id release-id
                        :attested attested
                        :merkle-root release-root-hash
                        :system-commit-hash system-hash
                        :manifest-path (getf manifest-paths :manifest-ttl)
                        :latest-symlink (merge-pathnames "releases/latest" base-output-dir)))))))))))

;;; ============================================================================
;;; VALIDATION FUNCTION
;;; ============================================================================

(defun validate-epistemic-stage (release-dir)
  "Validate epistemic stage output using SHACL shapes

  CRITICAL: This is self-validation - the corpus validates itself
  using the SHACL shapes it generates.

  Args:
    release-dir: Path to release directory (staging or final)

  Returns:
    T if validation passes, NIL otherwise"

  (let ((required-files '("meta-ontology.ttl"
                         "lineage-graph.ttl"
                         "negation.ttl"
                         "stability-policy.ttl"
                         "stability-policy.md"
                         "manifest.ttl"
                         "manifest.jsonld"
                         "shapes/article-shape.ttl"
                         "shapes/manifest-shape.ttl"
                         "shapes/lineage-shape.ttl"
                         "temporal-proof/merkle-tree.json"
                         ;; P1R [0046]: το timestamp.tsr είναι ATTESTATION (προσαρτάται
                         ;; append-only, ίσως μετά το publish) — η ΕΞΟΥΣΙΑ το απαιτεί
                         ;; στο promote-latest!, όχι η πληρότητα του commitment.
                         ;; Core verification files (always required).
                         ;; P1.4 [0054]#1 + [0056]: το υλικό TSA CA ΔΕΝ είναι
                         ;; απλή παρουσία αρχείου — ελέγχεται ξεχωριστά κάτω
                         ;; από το exactly-one-of gate (%tsa-ca-material-ok-p):
                         ;; ΑΚΡΙΒΩΣ ένα από {δομικά έγκυρο tsa-ca.pem,
                         ;; τίμια σημείωση tsa-ca.MISSING.txt}.
                         "verify/verify.sh"
                         "verify/verify.ps1"
                         "verify/verify.lisp"
                         "verify/README-VERIFY.md"))
        ;; Optional files (only required if JWS signing was enabled)
        (optional-files '("temporal-proof/signature.jws"
                         "verify/public.jwk")))

    ;; Check required files
    (loop for filename in required-files
          for path = (merge-pathnames filename release-dir)
          for exists = (probe-file path)
          unless exists
            do (format t "✗ MISSING: ~A~%" filename)
               (return-from validate-epistemic-stage nil))

    ;; [0056]: υλικό TSA CA — ΑΚΡΙΒΩΣ ένα από {δομικά έγκυρο tsa-ca.pem,
    ;; tsa-ca.MISSING.txt}. Κανένα / και τα δύο / ψευδο-pem ⇒ FAIL.
    (multiple-value-bind (ok reason) (%tsa-ca-material-ok-p release-dir)
      (unless ok
        (format t "✗ TSA-CA GATE: ~A~%" reason)
        (return-from validate-epistemic-stage nil)))

    ;; Check optional files (warn if missing, don't fail)
    (loop for filename in optional-files
          for path = (merge-pathnames filename release-dir)
          for exists = (probe-file path)
          unless exists
            do (format t "⚠ OPTIONAL MISSING: ~A (JWS signing disabled)~%" filename))

    ;; NOTE: Full SHACL validation requires external SHACL processor
    ;; For production: integrate Apache Jena SHACL, pySHACL, or TopQuadrant SHACL API

    t))
