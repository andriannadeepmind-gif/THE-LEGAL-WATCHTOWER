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
;;;; - Immutable timestamped release directory: /releases/2025-01-15T12:34:56Z/
;;;; - Atomic publish via 'latest' symlink

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
    :epistemic-release-dir - Path to immutable timestamped release
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
         ;; Output-bound: drives the immutable release directory name and
         ;; epistemic receipts, so it must be reproducible across runs.
         (timestamp (orchestrator.time:now :source :deterministic)))

    (unless articles
      (error 'orchestrator.spec:config-error
             :message "No articles to deploy (epistemic stage)"
             :config-key :articles))

    (log:info () "~%=== EPISTEMIC AUTHORITY DEPLOYMENT ===")
    (log:info () "Articles: ~D" (length articles))
    (log:info () "Output directory: ~A" output-dir)
    (log:info () "Blockchain anchor: ~A" blockchain-anchor)
    (log:info () "Timestamp: ~A" (orchestrator.time:format-iso8601 timestamp))

    ;; Deploy epistemic system
    (let ((result (orchestrator.epistemic:deploy-epistemic-stage
                   articles
                   output-dir
                   :timestamp timestamp
                   :blockchain-anchor blockchain-anchor)))

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

      context)))
