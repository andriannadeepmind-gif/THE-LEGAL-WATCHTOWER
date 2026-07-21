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

(defun %consolidate-from-articles (articles)
  "[+3/0105] Η ΜΙΑ παραγωγή του consolidated από article objects — καλείται
   ΜΟΝΟ από το generate-rdf-stage (πριν από κάθε render, ώστε το κείμενο των
   artifacts να ΕΙΝΑΙ το consolidated). P1b [0052]#Ε6/Ε8: ταυτότητα corpus +
   νομική ημερομηνία από την έδρα required-config — ΠΟΤΕ σιωπηλά/πλαστά.
   [#34/0092] work-date στην ΤΑΥΤΟΤΗΤΑ του εγγράφου."
  (let ((triples (%consolidation-articles->triples articles))
        (records (%consolidation-amendment-records)))
    (log:info () "Consolidating ~D articles with ~D amending act(s)"
              (length triples) (length records))
    (orchestrator.consolidation.bridge:consolidate-corpus
     triples records
     :id (orchestrator.spec:required-config "corpus.short_name")
     :title (orchestrator.spec:required-config "corpus.name")
     :work-date (orchestrator.spec:required-config "corpus.publication.date"))))

(defun consolidate-stage (context)
  "Write the consolidated artifacts. [+3/0105 ΜΕΤΑΘΕΣΗ ΚΥΡΙΑΡΧΙΑΣ]: το
   consolidated ΔΕΝ ξανα-υπολογίζεται εδώ — παράγεται ΜΙΑ φορά στο
   generate-rdf-stage (πριν από κάθε render) και καταναλώνεται από το context.
   Απόν consolidated = ΣΦΑΛΜΑ (καμία σιωπηλή δεύτερη παραγωγή)."
  (let ((output-dir (or (orchestrator.core:get-context-value context :output-dir)
                        (orchestrator.paths:institution-dir "output"))))
    (let* ((consolidated
             (or (orchestrator.core:get-context-value context :consolidated)
                 (error 'orchestrator.spec:config-error
                        :message "consolidate-stage: ΚΑΝΕΝΑ :consolidated στο context — η ΜΙΑ παραγωγή γίνεται στο generate-rdf-stage (ΜΕΤΑΘΕΣΗ ΚΥΡΙΑΡΧΙΑΣ [0105])"
                        :config-key :consolidated)))
           (ttl (orchestrator.consolidation:render-consolidation-provenance-ttl
                 consolidated))
           (txt (orchestrator.consolidation:render-consolidated-text consolidated))
           ;; Το work-date ταξιδεύει ΜΕΣΑ στο έγγραφο (ΜΙΑ ροή) — ο emitter
           ;; παραμένει fail-closed αν λείπει.
           (akn (orchestrator.akoma-ntoso:emit-akoma-ntoso consolidated))
           (dir (uiop:ensure-directory-pathname output-dir)))

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

      (log:info () "Wrote consolidated.{ttl,txt,akn.xml}, corpus.jsonl and catalog.jsonld to ~A"
                output-dir)
      context)))
