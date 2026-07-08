;;;; source/ingestion-daemon.lisp
;;;; ============================================================================
;;;; INGESTION DAEMON  (deployment wiring)
;;;; ============================================================================
;;;;
;;;; The runnable glue that turns the components into a running service: it wires
;;;; a source -> consolidation feed -> scheduler, and on every newly ingested
;;;; amending act re-emits the full set of consumption artifacts.
;;;;
;;;;   source (e.g. Diavgeia) --> scheduler --> feed (re-consolidate)
;;;;     --> on-update: write consolidated.{txt,ttl,akn.xml} + corpus.jsonl
;;;;                    + catalog.jsonld to the output directory
;;;;
;;;; Verifiable offline: pass a static source and an in-memory writer; the same
;;;; entry point drives the real feed with make-diavgeia-source and the default
;;;; (write-authority) writer in production.
;;;;
;;;; Persistence is injected (save-state-fn / restored state) so the daemon core
;;;; performs no direct file I/O and does not couple to a storage backend.
;;;; ============================================================================

(defpackage :orchestrator.ingestion.daemon
  (:use :cl)
  (:export #:corpus-updater #:run-update-daemon #:*default-artifact-writer*))

(in-package :orchestrator.ingestion.daemon)

(defun default-artifact-writer (content path)
  "Default writer: route through the GATE-2 write authority (provenance scope)."
  (funcall (find-symbol "EMIT-GRAPH" :orchestrator.write-authority)
           content path :authority :provenance))

(defparameter *default-artifact-writer* #'default-artifact-writer
  "Function (content path) used to persist each emitted artifact.")

(defun corpus-updater (output-dir &key (write-fn *default-artifact-writer*))
  "Return an on-update function (consolidated-document item) that writes the full
   set of consumption artifacts for the consolidated corpus into OUTPUT-DIR."
  (lambda (doc item)
    (declare (ignore item))
    (let ((dir (uiop:ensure-directory-pathname output-dir)))
      (flet ((w (content name) (funcall write-fn content (merge-pathnames name dir))))
        (w (funcall (find-symbol "RENDER-CONSOLIDATED-TEXT" :orchestrator.consolidation) doc)
           "consolidated.txt")
        (w (funcall (find-symbol "RENDER-CONSOLIDATION-PROVENANCE-TTL" :orchestrator.consolidation) doc)
           "consolidated.ttl")
        (w (funcall (find-symbol "EMIT-AKOMA-NTOSO" :orchestrator.akoma-ntoso) doc)
           "consolidated.akn.xml")
        (w (funcall (find-symbol "EMIT-CORPUS-JSONL" :orchestrator.ai-dump) doc)
           "corpus.jsonl")
        (w (funcall (find-symbol "EMIT-CORPUS-CATALOG" :orchestrator.ai-dump) doc)
           "catalog.jsonld")))))

(defun %payload-has-review-p (payload)
  "Does PAYLOAD (record in EITHER shape — string-keyed alist or keyword plist)
   carry flagged \"review\" operations? The old alist-only ASSOC guard silently
   skipped plist records, so live-feed flagged ops never reached the queue."
  (and (listp payload)
       (or (and (consp (first payload)) (assoc "review" payload :test #'equal))
           (and (keywordp (first payload)) (getf payload :review)))))

(defun %propose-item (item)
  "PROPOSE policy: a copy of ITEM whose payload has ALL operations moved under
   \"review\" — so every change, however confident, asks the human. Handles both
   record shapes; a non-record payload passes through unchanged."
  (let* ((copy (funcall (find-symbol "COPY-INGEST-ITEM" :orchestrator.ingestion) item))
         (p (funcall (find-symbol "INGEST-ITEM-PAYLOAD" :orchestrator.ingestion) copy)))
    (cond
      ((and (listp p) (consp (first p)))               ; alist record
       (let ((ops (cdr (assoc "operations" p :test #'equal)))
             (rev (cdr (assoc "review" p :test #'equal))))
         (when ops
           (setf p (remove-if (lambda (c) (member (car c) '("operations" "review")
                                                  :test #'equal))
                              p))
           (push (cons "review" (append rev ops)) p)
           (push (cons "operations" nil) p))))
      ((and (listp p) (keywordp (first p)))            ; plist record
       (let ((ops (getf p :operations)) (rev (getf p :review)))
         (when ops
           (setf p (copy-list p)
                 (getf p :review) (append rev ops)
                 (getf p :operations) nil)))))
    (funcall (fdefinition (list 'setf (find-symbol "INGEST-ITEM-PAYLOAD" :orchestrator.ingestion)))
             p copy)
    copy))

(defun %enqueue-item-review (item review-queue save-review-fn)
  "If ITEM's payload carries flagged (low/medium-confidence) operations, turn them
   into review items and enqueue them — so an uncertain change is sent for human
   approval rather than published blindly. High-confidence ops are unaffected
   (they auto-apply via the feed)."
  (when review-queue
    (let ((payload (funcall (find-symbol "INGEST-ITEM-PAYLOAD" :orchestrator.ingestion) item)))
      (when (%payload-has-review-p payload)
        (dolist (ri (funcall (find-symbol "AMENDMENT-RECORD->REVIEW-ITEMS" :orchestrator.review) payload))
          (funcall (find-symbol "ENQUEUE" :orchestrator.review) review-queue ri))
        (when save-review-fn (funcall save-review-fn review-queue))))))

(defun run-update-daemon (&key base-document source (output-dir (orchestrator.paths:institution-dir "output"))
                               (interval 3600) max-polls state save-state-fn
                               (write-fn *default-artifact-writer*)
                               review-queue save-review-fn
                               (policy :auto) cycle-hook)
  "Wire SOURCE -> consolidation feed -> scheduler and run the poll loop. On each
   newly ingested amending act, the consolidated corpus is re-emitted to
   OUTPUT-DIR. Returns the total number of items dispatched.

   BASE-DOCUMENT  - the base legal-document to consolidate against.
   SOURCE         - an orchestrator.ingestion source (static or Diavgeia).
   INTERVAL       - seconds between polls (production loop).
   MAX-POLLS      - stop after N polls (bounded / test runs); nil = run forever.
   STATE          - optional persisted scheduler state to restore on start.
   SAVE-STATE-FN  - optional persistence hook (state-plist) called after a poll.
   WRITE-FN       - artifact writer (content path); defaults to write authority.
   REVIEW-QUEUE   - optional orchestrator.review queue; flagged (uncertain) ops
                    from each item are enqueued for human approval (not published).
   SAVE-REVIEW-FN - optional persistence hook (queue) called after enqueuing."
  (let* ((feed (funcall (find-symbol "MAKE-CONSOLIDATION-FEED" :orchestrator.consolidation.feed)
                        :base-document base-document))
         (updater (corpus-updater output-dir :write-fn write-fn))
         (feed-dispatch (funcall (find-symbol "MAKE-FEED-DISPATCH" :orchestrator.consolidation.feed)
                                 feed :on-update updater))
         ;; Compose: first route any flagged change to the review queue, then
         ;; apply the high-confidence ops + re-emit.
         (dispatch (ecase policy
                     ;; AUTO: υψηλής βεβαιότητας πράξεις δημοσιεύονται από το feed,
                     ;; οι αμφίβολες πάνε στην ουρά έγκρισης (η ιστορική πολιτική).
                     (:auto (lambda (item)
                              (%enqueue-item-review item review-queue save-review-fn)
                              (funcall feed-dispatch item)))
                     ;; PROPOSE: ΤΙΠΟΤΑ δεν δημοσιεύεται μόνο του — κάθε πράξη,
                     ;; όσο βέβαιη κι αν είναι, γίνεται πρόταση στην ουρά και
                     ;; περιμένει το ανθρώπινο ΝΑΙ. Το feed δεν καλείται καν.
                     (:propose (lambda (item)
                                 (%enqueue-item-review (%propose-item item)
                                                       review-queue save-review-fn)))))
         (sch (funcall (find-symbol "MAKE-SCHEDULER" :orchestrator.ingestion)
                       :source source :dispatch dispatch :save-state-fn save-state-fn)))
    (when state
      (funcall (find-symbol "RESTORE-SCHEDULER-STATE" :orchestrator.ingestion) sch state))
    (funcall (find-symbol "RUN-SCHEDULER" :orchestrator.ingestion)
             sch :interval interval :max-polls max-polls :on-cycle cycle-hook)))
