;;;; Greek Constitution Pipeline

(in-package :orchestrator.gr-syntagma)

;; Define the pipeline using defpipeline macro
;; ΩΜΕΓΑ GRADE: Stage orthogonality with source-type routing
(orchestrator.spec:defpipeline greek-constitution
  (:corpus :gr-syntagma)
  (:config '(:parallel nil
             :max-retries 3
             ;; Source paths are corpus-configurable: source.pdf and source.json
             ;; are read from the active YAML config by source-normalize-stage.
             ;; Override at runtime: ORCHESTRATOR_PDF_INPUT_DIR, ORCHESTRATOR_JSON_PATH.
             :source-config (:type :deferred
                            :pdf-dir (orchestrator.paths:institution-dir "input/"))))
  (:stages
   ;; ================================================================
   ;; STAGE 0: SOURCE-NORMALIZE (Input-Type Detection)
   ;; Detects :source-type and writes canonical keys to context
   ;; ================================================================
   (source-normalize
    :function orchestrator.engine.sbcl:source-normalize-stage
    :produces (:source-type :source-path))

   ;; ================================================================
   ;; STAGE 1a: LOAD-JSON-SOURCE (JSON-Only)
   ;; Executes if :source-type = :json
   ;; Skips if :source-type ≠ :json
   ;; ================================================================
   (load-json-source
    :function orchestrator.engine.sbcl:load-json-source-stage
    :depends-on (source-normalize)
    :produces (:articles))

   ;; ================================================================
   ;; STAGE 1b: PARSE-PDF (PDF-Only)
   ;; Executes if :source-type = :pdf
   ;; Skips if :source-type ≠ :pdf
   ;; ================================================================
   (parse-pdf
    :function orchestrator.engine.sbcl:parse-pdf-stage
    :depends-on (source-normalize)
    :produces (:articles))

   ;; ================================================================
   ;; STAGE 1c: PARSE-RAW-TEXT (Raw text .txt files)
   ;; Executes if :source-type = :raw-text
   ;; Skips if :source-type ≠ :raw-text
   ;; Pipeline: Layout → Classifier → Canonicalizer → AST → IIR
   ;; ================================================================
   (parse-raw-text
    :function orchestrator.engine.sbcl:parse-raw-text-stage
    :depends-on (source-normalize)
    :produces (:articles))

   ;; ================================================================
   ;; STAGE 2+: Downstream stages (type-agnostic)
   ;; ================================================================
   (generate-rdf
    :function orchestrator.engine.sbcl:generate-rdf-stage
    :depends-on (load-json-source parse-pdf parse-raw-text)
    :produces (:rdf-turtle))

   ;; ================================================================
   ;; STAGE 2.1: CONSOLIDATE (CODIFICATION)
   ;; Applies the configured amending acts to the parsed articles and
   ;; emits the in-force consolidated text + ELI provenance:
   ;;   - consolidated.txt (in-force text, repealed provisions omitted)
   ;;   - consolidated.ttl (per-provision in_force / date_applicability /
   ;;                       amended_by / repealed_by)
   ;; Deterministic; a corpus with no amendments consolidates to its base.
   ;; ================================================================
   (consolidate
    :function orchestrator.engine.sbcl:consolidate-stage
    :depends-on (generate-rdf)
    :produces (:consolidated))

   ;; ================================================================
   ;; STAGE 2.5: TEST-ESCAPING (PIPELINE-EMBEDDED TESTS)
   ;; Executes WITHIN production pipeline (NOT ad-hoc)
   ;; Calls production entrypoints (render-canonical-html, etc.)
   ;; Crashes pipeline if escaping fails (exit ≠ 0)
   ;; ================================================================
   (test-escaping
    :function orchestrator.engine.sbcl:test-escaping-stage
    :depends-on (generate-rdf)
    :produces (:escaping-verified))

   (validate-shacl
    :function orchestrator.engine.sbcl:validate-shacl-stage
    :depends-on (test-escaping)
    :produces (:validation-report))

   (hash-artifacts
    :function orchestrator.engine.sbcl:hash-artifacts-stage
    :depends-on (validate-shacl)
    :produces (:hash))

   (anchor-blockchain
    :function orchestrator.engine.sbcl:anchor-blockchain-stage
    :depends-on (hash-artifacts)
    :produces (:blockchain-proof))

   ;; ================================================================
   ;; STAGE 7: DEPLOY (SINGLE FILESYSTEM TRUTH)
   ;; Writes ALL artifacts in one atomic operation:
   ;;   - Per-article: .ttl, .jsonld, .html, .hash (4 formats)
   ;;   - Dataset-level: manifest.ttl, void.ttl, manifest.jsonl
   ;; Guarantees:
   ;;   - JSON-LD byte-identity (standalone = embedded)
   ;;   - Explicit dependency contracts (hashes validated)
   ;;   - UTF-8 encoding determinism
   ;; ================================================================
   (deploy
    :function orchestrator.engine.sbcl:deploy-stage
    :depends-on (anchor-blockchain consolidate)
    :produces (:deployed :ai-manifest))

   ;; ================================================================
   ;; STAGE 8: DEPLOY-EPISTEMIC (6-LAYER AUTHORITY SYSTEM)
   ;; Generates epistemic authority framework with temporal proof:
   ;;   - Layer 1: Meta-ontology (OWL 2 DL system definition)
   ;;   - Layer 2: Release manifest (DCAT + temporal proof pack)
   ;;   - Layer 3: Lineage graph (PROV-O continuity)
   ;;   - Layer 4: Negation layer (defensive moat)
   ;;   - Layer 5: Epistemic boundaries (scope limits)
   ;;   - Layer 6: Stability policy (long-term guarantees)
   ;; Temporal proof:
   ;;   - Blake3 Merkle tree + inclusion proofs
   ;;   - RFC 3161 timestamps (if TSA available)
   ;;   - Certificate Transparency (if CT logs available)
   ;;   - JWS signatures (if private key available)
   ;; Output:
   ;;   - Candidate bundle: /candidates/sha256-<root>/  (ΟΧΙ δημοσίευση)
   ;;   [ΑΝΑΚΛΗΣΗ] ΟΧΙ «immutable release»: το candidates/ ανήκει στον producer
   ;;   και είναι ΜΕΤΑΒΛΗΤΟ· latest ΔΕΝ προάγεται από εδώ.
   ;; ================================================================
   (deploy-epistemic
    :function orchestrator.engine.sbcl:deploy-epistemic-stage
    :depends-on (deploy)
    :produces (:epistemic-release-dir
               :epistemic-merkle-root
               :epistemic-system-hash
               :epistemic-manifest
               :epistemic-latest))))

;; Create wrapper function that CLI expects
(defun greek-constitution-pipeline ()
  "Return the registered Greek Constitution pipeline"
  (orchestrator.spec:find-pipeline 'greek-constitution))
