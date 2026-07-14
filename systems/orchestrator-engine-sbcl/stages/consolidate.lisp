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
;;;; Amendments are read from the active corpus configuration (the YAML
;;;; versioning.amendments section) — Η ΜΙΑ πηγή. A corpus with no configured
;;;; amendments consolidates to its base text, which is the correct identity
;;;; behaviour.
;;;; ============================================================================

(in-package :orchestrator.engine.sbcl)

(defun %consolidation-articles->triples (articles)
  "Map article model objects to (id title content) triples in deterministic
   canonical order.

   P1b [0050]#2: το id είναι η ΚΑΝΟΝΙΚΗ ταυτότητα από τη ΜΙΑ έδρα
   (article-uri-id): «5», «5Α» — ΠΟΤΕ ο εσωτερικός συνθετικός αριθμός
   αποσαφήνισης (5Α ⇒ 5001), που μόλυνε τα eIds (art_5001) και έστελνε τα
   lettered άρθρα στο τέλος της ταξινόμησης. Σειρά: αριθμητική βάση, μετά
   γράμμα-επίθημα (5, 5Α, 6, …). Ο τίτλος περνά από την ΙΔΙΑ έδρα καθαρισμού
   με το RDF (extract-title-only): γυμνός τίτλος, όχι raw «Άρθρο Ν - …»."
  (mapcar (lambda (a)
            (list (orchestrator.model:article-uri a)
                  (extract-title-only (orchestrator.model:article-title a))
                  ;; Παράγραφοι από τη ΜΙΑ έδρα του κανόνα ορίου
                  ;; (split-article-paragraph-chunks) ώστε το consolidated
                  ;; να έχει ατομικά art_N__para_M όπως το RDF μονοπάτι.
                  (mapcar (lambda (c)
                            (string-trim '(#\Space #\Newline #\Tab) c))
                          (orchestrator.spec:split-article-paragraph-chunks
                           (orchestrator.model:article-content a)))))
          (orchestrator.model:articles-in-identity-order articles)))

(defun %consolidation-amendment-records ()
  "Return the configured amendment records, or NIL if none are configured.

   Η ΜΙΑ πηγή: το active corpus config (versioning.amendments στο YAML), μέσω
   config-get — που επιστρέφει NIL για απόν κλειδί ΧΩΡΙΣ να σηματοδοτεί, οπότε
   δεν χρειάζεται (και δεν επιτρέπεται) ignore-errors: πραγματική βλάβη
   φόρτωσης config πρέπει να ΣΚΑΕΙ.
   [0088 Φ6]: το σιωπηλό fallback στο orchestrator.eli-temporal:*amendments-config*
   ΠΕΘΑΝΕ μαζί με ολόκληρη την eli-temporal-metadata έδρα (grep-gate: ΚΑΝΕΙΣ
   δεν το έγραφε πια — ήταν νεκρή δεύτερη πηγή αλήθειας δίπλα στο config)."
  (orchestrator.spec:config-get "versioning.amendments"))

(defun consolidate-stage (context)
  "Build the consolidated in-force corpus from the parsed articles and the
   configured amendments, and write consolidated.ttl + consolidated.txt."
  (let ((articles (orchestrator.core:get-context-value context :articles))
        (output-dir (or (orchestrator.core:get-context-value context :output-dir)
                        (orchestrator.paths:institution-dir "output"))))
    (unless articles
      (error 'orchestrator.spec:config-error
             :message "No articles to consolidate"
             :config-key :articles))

    ;; P1b [0052]#Ε6/Ε8: ταυτότητα corpus + νομική ημερομηνία από την έδρα
    ;; required-config — ΠΟΤΕ σιωπηλά «"corpus"»/πλαστές τιμές, ΠΟΤΕ
    ;; ignore-errors γύρω από config-get (που δεν σηματοδοτεί για απόν κλειδί
    ;; — κατάπινε μόνο πραγματικές βλάβες φόρτωσης).
    (let* ((triples (%consolidation-articles->triples articles))
           (records (%consolidation-amendment-records))
           (corpus-id (orchestrator.spec:required-config "corpus.short_name"))
           (corpus-title (orchestrator.spec:required-config "corpus.name"))
           (consolidated
             (orchestrator.consolidation.bridge:consolidate-corpus
              triples records :id corpus-id :title corpus-title))
           (ttl (orchestrator.consolidation:render-consolidation-provenance-ttl
                 consolidated))
           (txt (orchestrator.consolidation:render-consolidated-text consolidated))
           ;; Νομική ημερομηνία ΠΟΤΕ δεν μαντεύεται: ρητά από το config ή
           ;; ΣΦΑΛΜΑ. Το παλιό σιωπηλό «1970-01-01» έγραφε πλαστή Unix-epoch
           ;; ημερομηνία σε νομικό αρτεφάκτ (Akoma Ntoso FRBRdate).
           (akn (orchestrator.akoma-ntoso:emit-akoma-ntoso
                 consolidated
                 :work-date (orchestrator.spec:required-config "corpus.publication.date")))
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
