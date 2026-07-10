;;;; systems/orchestrator-engine-sbcl/stages/deploy.lisp
;;;; Deploy stage - SINGLE FILESYSTEM TRUTH
;;;;
;;;; ARCHITECTURE:
;;;; Multi-format output (W3C-compliant + AI-optimized):
;;;; 1. Writes .ttl (RDF/Turtle - machine-readable semantic data)
;;;; 2. Writes .jsonld (Standalone JSON-LD - AI ingestion)
;;;; 3. Writes .html (HTML+RDFa+JSON-LD - human & machine readable)
;;;; 4. Writes .hash (SHA-256 cryptographic hash)
;;;;
;;;; GUARANTEES:
;;;; - Single writer (write-corpus-files)
;;;; - JSON-LD byte-identity (standalone = embedded)
;;;; - UTF-8 encoding determinism
;;;; - Explicit dependency contracts (hashes validated before AI manifest)

(in-package :orchestrator.engine.sbcl)

(defun validate-artifact-contract (articles)
  "Validate explicit dependency contract: all required artifacts exist

  CRITICAL CONTRACT:
  Before generating AI manifest, MUST guarantee:
    - All articles have hashes
    - All articles have at least one format (TTL/JSON-LD/HTML)

  Args:
    articles: List of article objects

  Returns:
    T if valid, signals error if contract violated"
  (loop for article in articles
        for num = (orchestrator.model:article-number article)
        do (progn
             ;; GATE: Hash must exist
             (unless (orchestrator.model:article-hash article)
               (error 'orchestrator.spec:validation-error
                      :message (format nil "Artifact contract violation: Article ~D missing hash" num)
                      :details (list :article-number num
                                   :missing :hash)))

             ;; GATE: At least one format must exist
             (unless (or (orchestrator.model:article-rdf-turtle article)
                        (orchestrator.model:article-json-ld article)
                        (orchestrator.model:article-html article))
               (error 'orchestrator.spec:validation-error
                      :message (format nil "Artifact contract violation: Article ~D has no formats" num)
                      :details (list :article-number num
                                   :missing :formats)))))
  (log:info () "Artifact contract validated: all ~D articles have hashes and formats" (length articles))
  t)

(defun generate-ai-manifest-ndjson (articles corpus)
  "Generate AI ingest manifest as NDJSON string

  Uses existing orchestrator-ai-core generators with explicit contract validation.

  Args:
    articles: List of article objects
    corpus: Corpus object (for metadata)

  Returns:
    NDJSON string (newline-delimited JSON)"
  (with-output-to-string (stream)
    ;; P1b [0050]#3: κανονική διάταξη από τη ΜΙΑ έδρα (article-identity<):
    ;; βάση, μετά επίθημα (5, 5Α, 6, …) — όχι ο συνθετικός αριθμός.
    (let ((sorted-articles (sort (copy-list articles)
                                 #'orchestrator.model:article-identity<)))
      (loop for article in sorted-articles
            for entry = (orchestrator.ai-core:generate-article-manifest-entry article corpus)
            for json-line = (orchestrator.ai-core:manifest-entry-to-json entry)
            do (write-line json-line stream)))))

(defun deploy-stage (context)
  "Deploy all generated artifacts using SINGLE FILESYSTEM TRUTH

  Uses write-corpus-files (single writer) with:
    - Articles list from context
    - Dataset-level artifacts (manifest, void, ai-manifest)
    - JSON-LD byte-identity guarantee
    - UTF-8 encoding via babel
    - Explicit dependency contract validation

  WRITES PER ARTICLE (5 formats):
    - article-N.ttl (RDF/Turtle)
    - article-N.jsonld (Standalone JSON-LD - byte-identical to embedded)
    - article-N.html (HTML+RDFa+embedded JSON-LD)
    - article-N.hash (SHA-256)

  WRITES DATASET-LEVEL (3 files):
    - {corpus.short_name}-manifest.ttl (Corpus root node)
    - void.ttl (VoID dataset descriptor)
    - manifest.jsonl (AI ingest manifest)"
  (let ((articles (orchestrator.core:get-context-value context :articles))
        (manifest (orchestrator.core:get-context-value context :syntagma-manifest))
        (output-dir (orchestrator.core:get-context-value context :output-dir)))

    (unless articles
      (error 'orchestrator.spec:config-error
             :message "No articles to deploy"
             :config-key :articles))

    (unless output-dir
      (setf output-dir (orchestrator.paths:institution-dir "output")))

    (log:info () "Deploying ~D articles to ~A (5 formats per article + 3 dataset files)" (length articles) output-dir)

    ;; GATE: Validate artifact contract before AI manifest generation
    (validate-artifact-contract articles)

    ;; Generate dataset-level artifacts

    ;; 1. VoID descriptor
    (let ((void-descriptor (orchestrator.spec:generate-void-dataset-descriptor))

          ;; 2. AI manifest (requires hashes - contract validated above)
          (ai-manifest (generate-ai-manifest-ndjson
                        articles
                        (or (orchestrator.core:get-context-value context :corpus)
                            (make-instance 'orchestrator.model:corpus
                                          :name (or (orchestrator.spec:config-get "corpus.name")
                                                    (error "deploy-stage: corpus.name not configured"))
                                          :short-name (or (orchestrator.spec:config-get "corpus.short_name")
                                                          (error "deploy-stage: corpus.short_name not configured"))
                                          :eli-prefix (orchestrator.uris:get-eli-const-prefix)
                                          :publication-date (or (orchestrator.spec:config-get "corpus.publication.date")
                                                                (error "deploy-stage: corpus.publication.date not configured"))
                                          :language "el"
                                          :webid (orchestrator.spec:org-webid)
                                          :orcid (or (orchestrator.spec:config-get "identity.person.orcid") ""))))))

      ;; SINGLE FILESYSTEM TRUTH: write-corpus-files handles ALL writes
      ;; - Articles (5 formats each with byte-identity guarantee)
      ;; - Dataset-level files (manifest, void, ai-manifest)
      (write-corpus-files articles output-dir
                         :manifest manifest
                         :void-descriptor void-descriptor
                         :ai-manifest ai-manifest))

    (log:info () "Deployment complete: ~D articles × 5 formats + 3 dataset files"
              (length articles))
    context))
