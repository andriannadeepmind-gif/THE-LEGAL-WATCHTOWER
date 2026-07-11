;;;; source/consolidation-feed.lisp
;;;; ============================================================================
;;;; CONSOLIDATION FEED  (ingestion -> codification loop)
;;;; ============================================================================
;;;;
;;;; Closes the loop between the ingestion scheduler and the consolidation
;;;; engine: as the scheduler discovers newly published amending acts, this
;;;; turns each one into an amendment and re-consolidates the corpus, so the
;;;; in-force consolidated text stays current automatically.
;;;;
;;;;   new item (scheduler) --> amending act --> appended to feed
;;;;                        --> re-consolidate base + acts
;;;;                        --> on-update callback (emit TTL / AKN / text, etc.)
;;;;
;;;; An ingest-item carries its amendment in its payload, either as a ready
;;;; AMENDING-ACT or as a config-shaped amendment record (which the bridge
;;;; converts). Items with no usable payload are ignored (the act is NIL), so a
;;;; pure notification still advances the scheduler without corrupting the feed.
;;;;
;;;; Deterministic: consolidation itself applies a total order over acts, so the
;;;; consolidated result depends only on the set of acts, not arrival order.
;;;; ============================================================================

(defpackage :orchestrator.consolidation.feed
  (:use :cl)
  (:import-from :orchestrator.consolidation
                #:consolidate #:amending-act-p #:legal-document-p)
  (:import-from :orchestrator.consolidation.bridge
                #:amendment-records->acts)
  (:import-from :orchestrator.ingestion
                #:ingest-item-payload #:ingest-item-id #:ingest-item-date)
  (:export
   #:consolidation-feed #:make-consolidation-feed
   #:consolidation-feed-base-document #:consolidation-feed-acts
   #:feed-apply-item #:feed-consolidated #:make-feed-dispatch))

(in-package :orchestrator.consolidation.feed)

(defstruct consolidation-feed
  "A base legal document plus the amending acts accumulated from ingestion."
  (base-document nil)
  (acts '() :type list))

(defun item->act (item)
  "Derive an AMENDING-ACT from ITEM's payload, or NIL if it carries none.
   Accepts a ready amending-act or a config-shaped amendment record."
  (let ((payload (ingest-item-payload item)))
    (cond
      ((null payload) nil)
      ((amending-act-p payload) payload)
      (t (first (amendment-records->acts (list payload)))))))

(defun feed-apply-item (feed item)
  "Convert ITEM to an amending act and append it to FEED. Returns the act (or
   NIL when the item carries no amendment)."
  (let ((act (item->act item)))
    (when act
      (setf (consolidation-feed-acts feed)
            (append (consolidation-feed-acts feed) (list act))))
    act))

(defun feed-consolidated (feed &key as-of-date)
  "The current consolidated document: base + all accumulated acts."
  (consolidate (consolidation-feed-base-document feed)
               (consolidation-feed-acts feed)
               :as-of-date as-of-date))

(defun make-feed-dispatch (feed &key on-update)
  "Return a scheduler dispatch function. For each new ingest-item it applies the
   item to FEED, re-consolidates, and (when supplied) calls
   ON-UPDATE with (consolidated-document item)."
  (lambda (item)
    (feed-apply-item feed item)
    (when on-update
      (funcall on-update (feed-consolidated feed) item))))
