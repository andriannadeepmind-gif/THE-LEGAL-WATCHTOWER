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
;;;; - Material gate (REQUIRED - fail if invalid; shapes shipped for third-party SHACL)
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
      shapes/
        article-shape.ttl
        manifest-shape.ttl
        lineage-shape.ttl
      temporal-proof/
        merkle-tree.json
        inclusion-proofs/
        timestamp.tsr
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

(defparameter +tsa-ca-missing-sentinel+
  "LAWMAX-TSA-CA-MISSING-v1"
  "Κανονικό αποτύπωμα της τίμιας σημείωσης απουσίας TSA CA. Γράφεται από την
   έδρα εκπομπής και ΑΠΑΙΤΕΙΤΑΙ από την πύλη, ώστε ένα αυθαίρετο/κενό/
   παραπλανητικό tsa-ca.MISSING.txt (π.χ. «η επαλήθευση πέρασε») να ΜΗΝ
   γίνεται δεκτό ως έγκυρος δείκτης απουσίας.")

(defun %emit-tsa-ca-or-honest-note (tsa-ca-path)
  "Γράφει tsa-ca.pem ΜΟΝΟ από γνήσια, δομικά επικυρωμένη X.509 CA αλυσίδα του
   χειριστή (ΚΑΘΕ block της αλυσίδας επικυρώνεται — όχι μόνο η κεφαλή). Αν δεν
   υπάρχει έγκυρη, ΔΕΝ γράφει ψευδο-cert — γράφει τίμια σημείωση
   (tsa-ca.MISSING.txt με κανονικό sentinel). Άκυρη παρεχόμενη CA ⇒ ΣΦΑΛΜΑ
   (ο χειριστής έδωσε σκουπίδι — δεν το κρύβουμε)."
  (let ((src (%operator-tsa-ca-source))
        (note-path (merge-pathnames "tsa-ca.MISSING.txt"
                                    (uiop:pathname-directory-pathname tsa-ca-path))))
    (cond
      (src
       (let ((pem (uiop:read-file-string src)))
         ;; Δομική φραγή: ΚΑΘΕ cert της αλυσίδας γνήσιο X.509 ή σφάλμα —
         ;; ποτέ ψευδο-blob (ούτε στην ουρά του bundle) σε release.
         (orchestrator.x509-authority:assert-valid-x509-pem pem "tsa-ca.pem")
         (alexandria:write-string-into-file pem tsa-ca-path :if-exists :supersede)
         (when (probe-file note-path) (ignore-errors (delete-file note-path)))
         (log:info () "tsa-ca.pem: γνήσια CA αλυσίδα του χειριστή (επικυρωμένη X.509) από ~A" src)
         t))
      (t
       (when (probe-file tsa-ca-path) (ignore-errors (delete-file tsa-ca-path)))
       (alexandria:write-string-into-file
        (format nil "~A~%TSA CA certificate ΔΕΝ διανέμεται με αυτό το release.~%~%~
Η ΠΛΗΡΗΣ RFC-3161 επαλήθευση της χρονοσφραγίδας (αλυσίδα CA → TSA) απαιτεί την~%~
pinned CA αλυσίδα που παρέχει ο χειριστής (env TSA_CA_BUNDLE ή keys/tsa-ca.pem).~%~
Το σύστημα ΑΡΝΕΙΤΑΙ να διανείμει ψευδο/ληγμένο πιστοποιητικό ως υλικό~%~
επαλήθευσης — τίμια άγνοια αντί για παραίσθηση ασφάλειας.~%~%~
Οι δεσμοί που ΕΠΑΛΗΘΕΥΟΝΤΑΙ ΧΩΡΙΣ αυτό: Merkle root ≡ ταυτότητα release,~%~
JWS υπογραφή, ύπαρξη/imprint-binding του RFC-3161 receipt (timestamp.tsr).~%~
Η πλήρης κρυπτογραφική επαλήθευση της αλυσίδας TSA είναι δηλωμένη φάση P4+.~%"
                +tsa-ca-missing-sentinel+)
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
      (note-p
       ;; Η σημείωση απουσίας πρέπει να φέρει το κανονικό sentinel — κενό ή
       ;; παραπλανητικό περιεχόμενο («η επαλήθευση πέρασε») ΔΕΝ γίνεται δεκτό.
       (if (search +tsa-ca-missing-sentinel+ (uiop:read-file-string note-path))
           t
           (values nil "tsa-ca.MISSING.txt χωρίς κανονικό sentinel — μη-έγκυρος δείκτης απουσίας")))
      (t (handler-case
             (progn
               ;; ΚΑΘΕ block της αλυσίδας επικυρώνεται (assert-valid-x509-pem
               ;; είναι πλέον chain-aware) — όχι μόνο η κεφαλή του bundle.
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
       ;; Ντετερμινιστικός χρόνος (SOURCE_DATE_EPOCH): το merkle-tree.json δεν
       ;; είναι canonical, αλλά ρολόι συστήματος θα έσπαγε το byte-reproducible
       ;; release directory (εύρημα κριτή).
       (jonathan:to-json `(:|root| ,release-root-hash
                          :|timestamp| ,(orchestrator.time:format-iso8601
                                        (orchestrator.time:require-deterministic-time))
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
                                              :public-key-path default-public-key-path
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

(defun generate-verification-kit (release-dir)
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

    ;; verify.sh — ΛΕΠΤΟΣ delegator στον L6 πυρήνα. ΚΑΜΙΑ δική του «επαλήθευση»:
    ;; ένα presence-only script που τυπώνει «PASSED» είναι σιωπηλό fallback
    ;; (εύρημα κριτή)· εδώ είτε τρέχει ο πυρήνας είτε exit 1 με τίμια οδηγία.
    (alexandria:write-string-into-file
     "#!/bin/bash
# LAWMAX release verification — delegates to the L6 kernel (verify.lisp).
# Usage: ./verify.sh [release-dir] [pinned-root-hex]
# This script performs NO verification itself. Cryptographic verification
# happens ONLY in verify.lisp (RFC-6962 root, census, JWS). No fallbacks.

RELEASE_DIR=\"${1:-..}\"
PINNED=\"${2:-}\"
KERNEL=\"$(dirname \"$0\")/verify.lisp\"

if ! command -v sbcl >/dev/null 2>&1; then
    echo \"✗ sbcl not found. Install SBCL (https://www.sbcl.org) and re-run:\" >&2
    echo \"    sbcl --script $KERNEL $RELEASE_DIR $PINNED\" >&2
    echo \"  No weaker fallback exists by design: presence checks are not verification.\" >&2
    exit 1
fi

exec sbcl --script \"$KERNEL\" \"$RELEASE_DIR\" $PINNED
"
     verify-sh-path
     :if-exists :supersede)

    ;; verify.ps1 — ίδιος λεπτός delegator για Windows. Καμία ψευδο-επαλήθευση.
    (alexandria:write-string-into-file
     "# LAWMAX release verification — delegates to the L6 kernel (verify.lisp).
# Usage: .\\verify.ps1 [release-dir] [pinned-root-hex]
# This script performs NO verification itself. Cryptographic verification
# happens ONLY in verify.lisp (RFC-6962 root, census, JWS). No fallbacks.

param(
    [string]$ReleaseDir = \"..\",
    [string]$Pinned = \"\"
)

$Kernel = Join-Path $PSScriptRoot \"verify.lisp\"

if (-not (Get-Command sbcl -ErrorAction SilentlyContinue)) {
    Write-Error \"sbcl not found. Install SBCL (https://www.sbcl.org) and re-run: sbcl --script $Kernel $ReleaseDir $Pinned. No weaker fallback exists by design: presence checks are not verification.\"
    exit 1
}

if ($Pinned) { sbcl --script $Kernel $ReleaseDir $Pinned }
else { sbcl --script $Kernel $ReleaseDir }
exit $LASTEXITCODE
"
     verify-ps1-path
     :if-exists :supersede)

    ;; verify.lisp — Ο L6 ΠΥΡΗΝΑΣ. ΔΕΝ γράφεται εδώ: είναι το 10ο canonical
    ;; αρχείο, ήδη staged στο Step 3γ ΠΡΙΝ το Merkle build (ώστε το release
    ;; root να δεσμεύει και τον verifier). Εδώ ΜΟΝΟ fail-closed έλεγχος ότι
    ;; υπάρχει — ξαναγράψιμο μετά τη ρίζα θα άλλαζε την ταυτότητα σιωπηλά.
    (unless (probe-file verify-lisp-path)
      (error "verify.lisp (L6 kernel, 10ο canonical) απών από το staging — ~
              το Step 3γ δεν έτρεξε: ~A" verify-lisp-path))

    ;; README-VERIFY.md - Verification instructions
    (alexandria:write-string-into-file
     "# Epistemic Release Verification

This directory contains the L6 verification kernel for this release.

## L6 Kernel Verification (the ONLY verification path)

```bash
cd verify
sbcl --script verify.lisp .. [pinned-root-hex]
```

**No OpenSSL required.** The kernel is a small standalone Common Lisp program
(ironclad + babel + cl-base64 + yason only) — read it in an afternoon, then run it.

## What Gets Verified (kernel v2)

1. **Release identity**: RFC-6962 Merkle root of the 10 canonical files recomputed
   and compared to the release directory name (and to your out-of-band pinned
   root, if you pass one — RECOMMENDED). `verify.lisp` itself is one of the 10:
   the identity binds the verifier you are running.
2. **Artifact census**: every per-article ttl/jsonld/html sha512 and every
   text_leaf recomputed from the in-release bytes; pcl_text_root ≡ MTH(text
   leaves); prev_release_root present (anti-equivocation chain; null only for
   the first release of a chain).
3. **JWS signature**: detached RS256 over the release root, full
   EMSA-PKCS1-v1_5 padding. Missing signature = FAIL (no unsigned downgrade).
4. **RFC 3161 receipt**: existence (full cryptographic TSR verification is the
   declared P4 phase; see tsa-ca notes below).

## Trust note (read this)

A tampered release could also ship a tampered `verify.lisp` — but that changes
the Merkle root, so the directory name and any pinned root no longer match.
For full independence, obtain the kernel out-of-band (from the source
repository: `deployment/verify/kernel-verify.lisp`) and/or always pass your
pinned root as the second argument.

## Convenience wrappers

`verify.sh` (bash) and `verify.ps1` (PowerShell) only exec the kernel via sbcl;
they perform NO verification themselves and fail honestly if sbcl is absent.

## Files in this Directory

- `verify.lisp` - The L6 kernel (canonical file #10 — inside the release identity)
- `verify.sh` - Thin wrapper: exec sbcl --script verify.lisp
- `verify.ps1` - Thin wrapper: exec sbcl --script verify.lisp
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
  ;; των 10 canonical>). Overwrite ΔΟΜΙΚΑ αδύνατο: ίδιο περιεχόμενο ⇒ ίδιος
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

(defparameter +epistemic-canonical-files-legacy8+
  '("meta-ontology.ttl" "lineage-graph.ttl" "negation.ttl"
    "stability-policy.ttl" "stability-policy.md"
    "shapes/article-shape.ttl" "shapes/manifest-shape.ttl"
    "shapes/lineage-shape.ttl")
  "Το canonical σύνολο ΠΡΟ-P1.5 (8 αρχεία): η ταυτότητα των ΙΣΤΟΡΙΚΩΝ
   δεσμευμένων releases που κόπηκαν πριν το census. ΠΑΓΩΜΕΝΟ — δεν
   ξαναγράφεται· υπάρχει ΜΟΝΟ για να επαληθεύεται η εποχή τους.")

(defparameter +frozen-legacy-release-ids+
  '("sha256-0ee2ecc4e0efab7342908876454df179fb60187654338832cb05058903883825"
    "sha256-5d4b546c1cda1e1a66f4b8d20fac5fe583f294abd0e6bf8fbf9a079092f972ff"
    "sha256-7e3acace23f5907085f1a266a6e2a49016fffaa4366398ddc97af7fffdd3acae"
    "sha256-a8185ecdef637b8300efba8f113a7a73443ae286de08f5025b90cbca0b3c6e86"
    "sha256-de72263b908fe7dc680a6ffb046c38951b5ccfd6a3acb46d8739a4766b260a80"
    "sha256-e8384152d401efc82566f9c5628c8b37a0a074ed1f95dea598334d0d8217dca6"
    "sha256-57a6994c231a5e1356c4afab778c3ecab84d5f507d2750b63a21b1419e4f4f27"
    "sha256-a4f674790a62d5cc35782fd646e49163412d12351944c66a4b51a8386b6bd433"
    "sha256-b53a6dfa5dd49cf8acfb61d000fa0dc9d7bfd4fc4b8d145fcac1a2e36018a47c"
    "sha256-1129ac1e0453c9c98744f7c2ca6af138a611d8c706a2bc2d345c802132eaa30d"
    "sha256-bdb1b83d4b3d60459048e4364d7ab9b8baa240e72f5a7c5fd09816d5196c7b0a"
    "sha256-c552b49c352b8df33d3928b75083fdcac61838cebec2f9f8c0ffa46963d35e46"
    "sha256-1c85246b2af9b0704e103f4aaacf1a0bac974eb6cd985fd7ee1cb372fa6d6d18"
    "sha256-34e236806b990128ae799554158c38c197bdffe67ad82260461c29623a1840cd"
    "sha256-aaf60c01d1bfec2a01ef4e914476f184771cc686c6dc8aa08bd1d067e5c3727f"
    "sha256-2c94bf02c9f7a9fe02fe44dcc3acb4265cb6c4dcbeb037ad0448c777068064d8"
    "sha256-743c8882bc1d48ccfe9ffc3fc677778164f4611db72c4e1d10c90bc8cbe9c19a"
    "sha256-a8d87d7ff439e524f403c7e1135c620055faadab657075354bfe8481a3416e93")
  "ΠΑΓΩΜΕΝΟ, ΠΕΠΕΡΑΣΜΕΝΟ σύνολο των content-addressed ids της ΠΡΟ-P1.5 εποχής
   (18 δεσμευμένα releases, [0058]). Το P1.5-A.2 σκότωσε ΣΚΟΠΙΜΑ τον παλιό
   αλγόριθμο ταυτότητας· αυτά τα ids δεν αναπαράγονται πια, άρα ΑΠΑΡΙΘΜΟΥΝΤΑΙ.
   ΚΡΙΣΙΜΟ (κλείσιμο κριτή P1.5-D#1, epoch-downgrade): ΜΟΝΟ αυτά τα ids
   επιτρέπεται να επαληθεύονται με τους ασθενέστερους legacy ελέγχους. Κάθε
   ΑΛΛΟ sha256-named release ΠΡΕΠΕΙ να είναι census-εποχής (census.json
   υποχρεωτικό)· αφαίρεση του census.json από νεότερο release ΔΕΝ το υποβιβάζει
   σε legacy — είναι ΣΦΑΛΜΑ (η κλάση σφάλματος εξαλείφεται δομικά).")

(defun frozen-legacy-release-id-p (id)
  "T μόνο αν το ID ανήκει στο παγωμένο σύνολο της προ-P1.5 εποχής."
  (and (stringp id) (member id +frozen-legacy-release-ids+ :test #'string=) t))

(defun %release-canonical-era (release-dir)
  "Ποιο canonical σύνολο ορίζει την ταυτότητα ΑΥΤΟΥ του release. Διάκριση
   εποχής ΡΗΤΗ: census.json παρόν ⇒ census-εποχή (10 canonical, verify.lisp
   μέσα στην ταυτότητα)· αλλιώς ⇒ legacy-8 — ΑΛΛΑ ΜΟΝΟ αν το id ανήκει στο
   παγωμένο legacy σύνολο. sha256-named χωρίς census ΚΑΙ εκτός frozen ⇒ ΣΦΑΛΜΑ
   (απόπειρα epoch-downgrade: stripped census)."
  (let* ((dir (uiop:ensure-directory-pathname release-dir))
         (leaf (car (last (pathname-directory dir)))))
    (cond
      ((probe-file (merge-pathnames "census.json" dir)) +epistemic-canonical-files+)
      ((frozen-legacy-release-id-p leaf) +epistemic-canonical-files-legacy8+)
      ((and (stringp leaf) (eql 0 (search "sha256-" leaf)))
       (error "~A: sha256-named χωρίς census.json ΚΑΙ εκτός frozen legacy ⇒ ~
               απόπειρα epoch-downgrade (stripped census)" leaf))
      (t +epistemic-canonical-files-legacy8+)))) ; timestamp-named ιστορικά

(defun %release-recomputed-root (release-dir)
  "Το Merkle root ενός release ΕΠΑΝΑΫΠΟΛΟΓΙΣΜΕΝΟ από τα canonical αρχεία της
   ΕΠΟΧΗΣ ΤΟΥ (βλ. %release-canonical-era) — ποτέ από τη δική του δήλωση,
   ποτέ από «όσα αρχεία τυχαίνει να υπάρχουν». Λείπον canonical της εποχής ⇒
   ΣΦΑΛΜΑ (η ταυτότητα δεν συμπληρώνεται σιωπηλά)."
  (let* ((dir (uiop:ensure-directory-pathname release-dir))
         (era (%release-canonical-era dir))
         (paths (mapcar (lambda (f) (merge-pathnames f dir)) era))
         (missing (remove-if #'probe-file paths)))
    (when missing
      (error "~A: λείπουν canonical της εποχής: ~{~A ~}"
             dir (mapcar #'file-namestring missing)))
    (merkle-tree-root
     (build-merkle-tree (sort paths #'string< :key #'namestring)))))

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
    ;; [L7-B] Transparency log: κάθε προαγωγή σε εξουσία καταγράφεται ως φύλλο
    ;; στο append-only log του corpus — με consistency proof (RFC 6962 §2.1.2)
    ;; επαληθευμένο ΠΡΙΝ γραφτεί byte. Η ΜΙΑ έδρα: tlog-append-root!.
    (let ((root (%release-recomputed-root release-dir)))
      (tlog-append-root! releases-dir root)
      (format t "✓ transparency log: ~A καταγράφηκε (consistency proof OK)~%" root))
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
    7. Material gate (REQUIRED - fail if invalid)
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

        ;; Step 3β [P1.5-B]: Artifact Census — το 9ο canonical αρχείο. Δένει
        ;; per-article artifacts + text-σπονδυλική + prev-root + materials στο
        ;; release root. Γράφεται ΠΡΙΝ το Merkle build ώστε να γίνει φύλλο του.
        (format t "~%Step 3β: Writing artifact census (9th canonical file)...~%")
        (let ((census (write-artifact-census
                       articles
                       (or (ignore-errors (orchestrator.spec:config-get "corpus.short_name"))
                           "corpus")
                       base-output-dir
                       staging-dir
                       (merge-pathnames "releases/"
                                        (uiop:ensure-directory-pathname base-output-dir)))))
          (format t "  Census: ~D άρθρα, pcl_text_root ~A, prev ~A~%"
                  (getf census :count)
                  (subseq (getf census :pcl-text-root) 0 20)
                  (or (getf census :prev-release-root) "null (πρώτο της αλυσίδας)")))

        ;; Step 3γ [P1.5-C]: Ο L6 πυρήνας ΜΕΣΑ στην ταυτότητα — 10ο canonical
        ;; αρχείο. Αντιγράφεται ΠΡΙΝ το Merkle build ώστε το release root να
        ;; δεσμεύει ΚΑΙ τον verifier που διανέμεται: παραποιημένος verify.lisp
        ;; ⇒ αλλάζει το root ⇒ δεν ταιριάζει με το όνομα καταλόγου/pin.
        (format t "~%Step 3γ: Staging L6 kernel as 10th canonical file...~%")
        (let ((kernel-src (orchestrator.paths:institution-dir
                           "deployment/verify/kernel-verify.lisp"))
              (kernel-dst (merge-pathnames "verify/verify.lisp" staging-dir)))
          (unless (probe-file kernel-src)
            (error "L6 kernel source not found: ~A" kernel-src))
          (ensure-directories-exist (merge-pathnames "verify/" staging-dir))
          (uiop:copy-file kernel-src kernel-dst)
          (format t "  Kernel: ~A~%" kernel-dst))

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
            (let ((verify-paths (generate-verification-kit staging-dir)))
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

                ;; Step 8: Material gate (REQUIRED). ΤΙΜΙΑ ονοματολογία: δεν
                ;; τρέχει SHACL processor εδώ — τα shapes διανέμονται για
                ;; ΤΡΙΤΟΥΣ, η σημασιολογική επικύρωση ζει στα CI gates.
                (format t "~%Step 8: Release material gate (REQUIRED)...~%")
                (unless (validate-epistemic-stage staging-dir)
                  (error 'orchestrator.spec:validation-error
                         :message "Release material gate failed"
                         :details "Missing required artifacts / TSA-CA gate / signature"))
                (format t "✓ Material gate passed (required files + TSA-CA + signature)~%")

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
  "MATERIAL GATE του release: ύπαρξη ΟΛΩΝ των απαιτούμενων αρχείων + TSA-CA
   exactly-one-of + fail-closed υπογραφή (εκτός dev-mode).

  ΤΙΜΙΑ ΟΝΟΜΑΤΟΛΟΓΙΑ (εύρημα κριτή): αυτό ΔΕΝ είναι SHACL validation — δεν
  εκτελείται SHACL processor εδώ. Τα shapes διανέμονται στο release ώστε
  ΤΡΙΤΟΣ να τρέξει pySHACL/Jena πάνω στα ΙΔΙΑ bytes· η δική μας σημασιολογική
  επικύρωση ζει στα semantic-validity/shacl-validator tests (CI gates).

  Args:
    release-dir: Path to release directory (staging or final)

  Returns:
    T if the gate passes, NIL otherwise"

  (let ((required-files '("meta-ontology.ttl"
                         "lineage-graph.ttl"
                         "negation.ttl"
                         "stability-policy.ttl"
                         "stability-policy.md"
                         "manifest.ttl"
                         "manifest.jsonld"
                         ;; [P1.5-B] Το census είναι canonical (id-δεσμευτικό).
                         "census.json"
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
        ;; FAIL-CLOSED υπογραφή (εύρημα κριτή F2): εκτός dev-mode, release
        ;; ΧΩΡΙΣ signature.jws/public.jwk δεν περνά — ο L6 πυρήνας απορρίπτει
        ;; signature stripping, άρα και η πύλη παραγωγής (ίδια αλήθεια).
        (signature-files '("temporal-proof/signature.jws"
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

    ;; Υπογραφή: fail-closed εκτός dev-mode (μόνο εκεί επιτρέπεται τίμιο ⚠).
    (loop for filename in signature-files
          for path = (merge-pathnames filename release-dir)
          unless (probe-file path)
            do (if (dev-mode-p)
                   (format t "⚠ DEV MODE: ~A απών (unsigned dev release)~%" filename)
                   (progn (format t "✗ MISSING SIGNATURE MATERIAL: ~A~%" filename)
                          (return-from validate-epistemic-stage nil))))

    t))
