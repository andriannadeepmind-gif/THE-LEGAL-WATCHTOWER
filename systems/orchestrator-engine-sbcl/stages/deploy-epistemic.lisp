;;;; systems/orchestrator-engine-sbcl/stages/deploy-epistemic.lisp
;;;; Epistemic Authority Deployment Stage
;;;;
;;;; PURPOSE: Deploy 6-layer epistemic authority system
;;;; DEPENDS: deploy stage (requires artifacts on filesystem)
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
;;;; - Blake3 Merkle tree with inclusion proofs
;;;; - RFC 3161 timestamp receipts (if TSA available)
;;;; - Certificate Transparency proofs (if CT logs available)
;;;; - JWS signatures (if private key available)
;;;;
;;;; OUTPUT:
;;;; - Candidate bundle directory: /candidates/sha256-<root>/
;;;; [ΑΝΑΚΛΗΣΗ] ΟΧΙ «immutable release»: ο producer είναι ΙΔΙΟΚΤΗΤΗΣ του
;;;; candidates/ και μπορεί να το αλλάξει ανά πάσα στιγμή. Το στάδιο ΔΕΝ
;;;; δημοσιεύει και ΔΕΝ προάγει latest — η έγκριση ανήκει ΑΠΟΚΛΕΙΣΤΙΚΑ στον
;;;; admission kernel της authority-v2, πάνω σε ΣΥΛΛΗΦΘΕΝ snapshot (quarantine).

(in-package :orchestrator.engine.sbcl)

(defun deploy-epistemic-stage (context)
  "Deploy epistemic authority system

  FLOW:
    1. Extract articles and config from context
    2. Determine base output directory
    3. Extract blockchain anchor (if available)
    4. Call orchestrator.epistemic:deploy-epistemic-stage
    5. Store release metadata in context
    6. Return context

  Context Requirements (from previous stages):
    :articles - List of article objects (with all formats generated)
    :output-dir - Base output directory (optional, defaults to the institution output dir)
    :blockchain-proof - Blockchain anchor from anchor-blockchain stage (optional)

  Context Updates:
    :epistemic-release-dir - Path to the CANDIDATE bundle (producer-owned, MUTABLE)
    :epistemic-merkle-root - Blake3 Merkle root of all artifacts
    :epistemic-system-hash - Blake3 hash of epistemic system
    :epistemic-manifest - Path to manifest.ttl
    :epistemic-latest - Path to 'latest' symlink"

  (let* ((articles (orchestrator.core:get-context-value context :articles))
         (output-dir (or (orchestrator.core:get-context-value context :output-dir)
                        (orchestrator.paths:institution-dir "output")))
         (blockchain-proof (orchestrator.core:get-context-value context :blockchain-proof))
         (blockchain-anchor (if blockchain-proof
                               (getf blockchain-proof :merkle-root)
                               "pending"))
         ;; P1R [0046]: output-bound χρόνος (release metadata) ΜΟΝΟ από δηλωμένη
         ;; αρχή — χωρίς ενεργό deterministic mode το require- ΣΦΑΛΛΕΙ αντί να
         ;; πέσει σιωπηλά στο ρολόι. Η ΤΑΥΤΟΤΗΤΑ του release είναι πλέον
         ;; content-addressed και δεν εξαρτάται από αυτό το timestamp.
         (timestamp (orchestrator.time:require-deterministic-time)))

    (unless articles
      (error 'orchestrator.spec:config-error
             :message "No articles to deploy (epistemic stage)"
             :config-key :articles))

    (log:info () "~%=== EPISTEMIC AUTHORITY DEPLOYMENT ===")
    (log:info () "Articles: ~D" (length articles))
    (log:info () "Output directory: ~A" output-dir)
    (log:info () "Blockchain anchor: ~A" blockchain-anchor)
    (log:info () "Timestamp: ~A" (orchestrator.time:format-iso8601 timestamp))

    ;; [0088 Φ5/PCL-02] Το temporal commitment (graph_root + receipt_set_root)
    ;; έρχεται από τον καλούντα (cli: corpus-temporal-commitment — η ΜΙΑ έδρα)
    ;; μέσω του context. Χωρίς αυτό ΔΕΝ κόβεται release — fail-closed εδώ ΚΑΙ
    ;; στο census (καμία σιωπηλή έκδοση χωρίς δεσμευμένη διτεμπορική ιστορία).
    (let ((temporal-commitment
            (orchestrator.core:get-context-value context :temporal-commitment)))
      (unless temporal-commitment
        (error 'orchestrator.spec:validation-error
               :message "deploy-epistemic: απόν :temporal-commitment στο context — το census-2 απαιτεί graph_root + receipt_set_root"))

    ;; Deploy epistemic system
    (let ((result (orchestrator.epistemic:deploy-epistemic-stage
                   articles
                   output-dir
                   :timestamp timestamp
                   :blockchain-anchor blockchain-anchor
                   :temporal-commitment temporal-commitment)))

      ;; Store results in context
      (orchestrator.core:set-context-value
       context :epistemic-release-dir (getf result :release-dir))

      (orchestrator.core:set-context-value
       context :epistemic-merkle-root (getf result :merkle-root))

      (orchestrator.core:set-context-value
       context :epistemic-system-hash (getf result :system-commit-hash))

      (orchestrator.core:set-context-value
       context :epistemic-manifest (getf result :manifest-path))

      (orchestrator.core:set-context-value
       context :epistemic-latest (getf result :latest-symlink))

      ;; P1b [0052]#Ε4: ταυτότητα + κατάσταση attestation στο context, ώστε
      ;; ΚΑΘΕ καταναλωτής του stage (pipeline, --cut-release) να διαβάζει το
      ;; αποτέλεσμα από την ΙΔΙΑ έδρα — χωρίς δεύτερη κλήση του inner deploy.
      (orchestrator.core:set-context-value
       context :epistemic-release-id (getf result :release-id))

      (orchestrator.core:set-context-value
       context :epistemic-attested (getf result :attested))

      (log:info () "~%=== EPISTEMIC DEPLOYMENT COMPLETE ===")
      (log:info () "Release directory: ~A" (getf result :release-dir))
      (log:info () "Merkle root: ~A" (getf result :merkle-root))
      (log:info () "System commit hash: ~A" (getf result :system-commit-hash))
      (log:info () "Latest symlink: ~A~%" (getf result :latest-symlink))

      ;; Validate epistemic stage output
      ;; EXECUTION PROOF VERIFICATION (PHASE 2 - DARPA HARDENING)
      (log:info () "~%Verifying test-escaping-stage execution proof...")

      ;; Check proof exists
      (unless *test-escaping-proof*
        (error 'orchestrator.spec:validation-error
               :message "FATAL: test-escaping-stage proof MISSING - pipeline integrity compromised"))

      ;; Validate proof structure
      (unless (orchestrator.engine.sbcl::valid-proof-p *test-escaping-proof*)
        (error 'orchestrator.spec:validation-error
               :message "FATAL: test-escaping-stage proof INVALID - failed validation"))

      ;; Verify proof hash
      (let ((expected-hash (orchestrator.engine.sbcl::compute-proof-hash *test-escaping-proof*))
            (actual-hash (orchestrator.engine.sbcl::test-escaping-proof-proof-hash *test-escaping-proof*)))
        (unless (string= expected-hash actual-hash)
          (error 'orchestrator.spec:validation-error
                 :message "FATAL: test-escaping-stage proof hash MISMATCH - tampering detected")))

      ;; Verify graph position
      (unless (equal (orchestrator.engine.sbcl::test-escaping-proof-graph-position *test-escaping-proof*)
                    '(:after generate-rdf :before validate-shacl))
        (error 'orchestrator.spec:validation-error
               :message "FATAL: test-escaping-stage graph position INCORRECT"))

      (log:info () "✓ Execution proof verified: test-escaping-stage executed with full attestation")
      (log:info () "✓ Legacy tripwire: ~A" *test-escaping-stage-executed*)

      (log:info () "~%Validating epistemic stage output...")
      (if (orchestrator.epistemic:validate-epistemic-stage (getf result :release-dir))
          (log:info () "✓ Epistemic validation passed~%")
          (log:warn () "✗ Epistemic validation failed - some files may be missing~%"))

      context))))
