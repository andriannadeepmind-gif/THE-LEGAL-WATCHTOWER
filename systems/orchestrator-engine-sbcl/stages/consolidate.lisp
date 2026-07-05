;;;; systems/orchestrator-engine-sbcl/stages/consolidate.lisp
;;;; ============================================================================
;;;; CONSOLIDATION STAGE
;;;; ============================================================================
;;;;
;;;; Produces the CONSOLIDATED, in-force version of the corpus by applying the
;;;; configured amending acts to the parsed articles, and emits two artifacts:
;;;;
;;;;   consolidated.ttl  - ELI-aligned provenance per provision (in_force,
;;;;                       date_applicability, amended_by / repealed_by)
;;;;   consolidated.txt  - plain in-force text (repealed provisions omitted)
;;;;
;;;; Deterministic: the consolidation engine deep-copies the base, applies a
;;;; total order over acts, and uses no wall-clock, so two runs are identical.
;;;;
;;;; Amendments are read from the active corpus configuration
;;;; (orchestrator.eli-temporal:*amendments-config*, populated from the YAML
;;;; versioning.amendments section). A corpus with no configured amendments
;;;; consolidates to its base text, which is the correct identity behaviour.
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

(defun %consolidation-articles->triples (articles)
  "Map article model objects to (number title content) triples in deterministic
   article-number order."
  (mapcar (lambda (a)
            (list (orchestrator.model:article-number a)
                  (orchestrator.model:article-title a)
                  (orchestrator.model:article-content a)))
          (sort (copy-list articles) #'<
                :key #'orchestrator.model:article-number)))

(defun %consolidation-amendment-records ()
  "Return the configured amendment records, or NIL if none are configured.

   Primary source is the active corpus config (versioning.amendments in the
   YAML), read via config-get; this returns a list of records (hash-tables)
   that the bridge understands. Falls back to
   orchestrator.eli-temporal:*amendments-config* if the config path is absent."
  (or (ignore-errors (orchestrator.spec:config-get "versioning.amendments"))
      (let ((sym (and (find-package :orchestrator.eli-temporal)
                      (find-symbol "*AMENDMENTS-CONFIG*" :orchestrator.eli-temporal))))
        (when (and sym (boundp sym))
          (symbol-value sym)))))

(defun consolidate-stage (context)
  "Build the consolidated in-force corpus from the parsed articles and the
   configured amendments, and write consolidated.ttl + consolidated.txt."
  (let ((articles (orchestrator.core:get-context-value context :articles))
        (output-dir (or (orchestrator.core:get-context-value context :output-dir)
                        "/app/output")))
    (unless articles
      (error 'orchestrator.spec:config-error
             :message "No articles to consolidate"
             :config-key :articles))

    (let* ((triples (%consolidation-articles->triples articles))
           (records (%consolidation-amendment-records))
           (corpus-id (or (ignore-errors (orchestrator.spec:config-get "corpus.short_name"))
                          "corpus"))
           (corpus-title (ignore-errors (orchestrator.spec:config-get "corpus.name")))
           (consolidated
             (orchestrator.consolidation.bridge:consolidate-corpus
              triples records :id corpus-id :title corpus-title))
           (ttl (orchestrator.consolidation:render-consolidation-provenance-ttl
                 consolidated))
           (txt (orchestrator.consolidation:render-consolidated-text consolidated))
           (akn (orchestrator.akoma-ntoso:emit-akoma-ntoso
                 consolidated
                 :work-date (or (ignore-errors
                                 (orchestrator.spec:config-get "corpus.publication.date"))
                                "1970-01-01")))
           (dir (uiop:ensure-directory-pathname output-dir)))

      (log:info () "Consolidating ~D articles with ~D amending act(s)"
                (length triples) (length records))

      (orchestrator.write-authority:emit-graph
       ttl (merge-pathnames "consolidated.ttl" dir) :authority :provenance)
      (orchestrator.write-authority:emit-graph
       txt (merge-pathnames "consolidated.txt" dir) :authority :provenance)
      (orchestrator.write-authority:emit-graph
       akn (merge-pathnames "consolidated.akn.xml" dir) :authority :provenance)
      ;; AI consumption layer: streamable JSONL dump + DCAT catalog.
      (orchestrator.write-authority:emit-graph
       (orchestrator.ai-dump:emit-corpus-jsonl consolidated)
       (merge-pathnames "corpus.jsonl" dir) :authority :provenance)
      (orchestrator.write-authority:emit-graph
       (orchestrator.ai-dump:emit-corpus-catalog consolidated)
       (merge-pathnames "catalog.jsonld" dir) :authority :provenance)

      (orchestrator.core:set-context-value context :consolidated consolidated)
      (log:info () "Wrote consolidated.{ttl,txt,akn.xml}, corpus.jsonl and catalog.jsonld to ~A"
                output-dir)
      context)))
