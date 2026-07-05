;;;; source/legislation-ingestion.lisp
;;;; ============================================================================
;;;; LEGISLATION INGESTION + SCHEDULER
;;;; ============================================================================
;;;;
;;;; Continuous, incremental ingestion of newly published legislation. This is
;;;; the "stays up to date in real time" layer: a scheduler polls a source for
;;;; items newer than a persisted cursor, de-duplicates against already-seen
;;;; ids, dispatches the new items to a handler, and advances the cursor.
;;;;
;;;; Design for testability and honesty:
;;;;   - A SOURCE is just a name + a fetcher function (since) -> list of items.
;;;;     This makes the real network source (Diavgeia opendata, via Drakma) and
;;;;     an in-memory/static source interchangeable, so the scheduler logic is
;;;;     verified deterministically OFFLINE, and the same logic drives the real
;;;;     feed when a network source is configured.
;;;;   - The scheduler is incremental (cursor) and idempotent (seen-set), so
;;;;     re-runs never re-dispatch the same item.
;;;;   - Persistence is INJECTED (save-state-fn): the core does no file I/O, so
;;;;     it neither couples to a storage backend nor violates the write-authority
;;;;     gate. State is a plain serializable plist.
;;;;
;;;; Dependencies: pure Common Lisp for the core; the optional Diavgeia source
;;;; uses Drakma + Jonathan, invoked only when that source is constructed.
;;;; ============================================================================

(defpackage :orchestrator.ingestion
  (:use :cl)
  (:export
   #:ingest-item #:make-ingest-item #:ingest-item-p
   #:ingest-item-id #:ingest-item-title #:ingest-item-date
   #:ingest-item-source-uri #:ingest-item-kind #:ingest-item-payload
   #:ingestion-source #:make-ingestion-source #:ingestion-source-name
   #:ingestion-source-fetcher
   #:make-static-source #:fetch-items
   #:scheduler #:make-scheduler #:scheduler-cursor #:scheduler-source
   #:poll-once #:run-scheduler
   #:scheduler-state #:restore-scheduler-state #:scheduler-seen-count))

(in-package :orchestrator.ingestion)

;;; ============================================================================
;;; ITEM MODEL
;;; ============================================================================

(defstruct ingest-item
  "A single newly-published legislative item discovered by a source."
  (id nil :type (or null string))        ; stable unique id (e.g. Diavgeia ADA / FEK ref)
  (title nil :type (or null string))
  (date nil :type (or null string))      ; ISO-8601 publication date (sorts chronologically)
  (source-uri nil :type (or null string))
  (kind nil :type (or null string))      ; e.g. "law", "decision", "decree"
  (payload nil))                          ; opaque source-specific data (text, json, ...)

;;; ============================================================================
;;; SOURCE
;;; ============================================================================

(defstruct ingestion-source
  "A pluggable source. FETCHER is (function (since-iso-date-or-nil) -> list of
   ingest-item) returning items published strictly after SINCE (or all when
   SINCE is nil)."
  (name "source" :type string)
  (fetcher nil :type (or null function)))

(defun fetch-items (source &optional since)
  (funcall (ingestion-source-fetcher source) since))

(defun make-static-source (name items)
  "A source backed by an in-memory list of ITEMS (for tests and file feeds).
   Returns items with date strictly greater than SINCE (chronological by ISO date)."
  (make-ingestion-source
   :name name
   :fetcher (lambda (since)
              (remove-if (lambda (it)
                           (and since (ingest-item-date it)
                                (string<= (ingest-item-date it) since)))
                         items))))

;; The concrete Διαύγεια (government) source lives in orchestrator.gov-source —
;; all government interaction is in one module; this file stays source-agnostic.

;;; ============================================================================
;;; SCHEDULER
;;; ============================================================================

(defstruct scheduler
  "Incremental, idempotent poller over a SOURCE.
     CURSOR        - ISO date of the newest item dispatched so far (or nil)
     SEEN          - hash-set of dispatched item ids (idempotency)
     DISPATCH      - (function (ingest-item)) handler for each new item
     SAVE-STATE-FN - optional (function (state-plist)) persistence hook"
  (source nil :type (or null ingestion-source))
  (cursor nil :type (or null string))
  (seen (make-hash-table :test 'equal) :type hash-table)
  (dispatch nil :type (or null function))
  (save-state-fn nil :type (or null function)))

(defun scheduler-seen-count (sch) (hash-table-count (scheduler-seen sch)))

(defun item< (a b)
  "Deterministic total order over items: by date, then id."
  (let ((da (or (ingest-item-date a) "")) (db (or (ingest-item-date b) ""))
        (ia (or (ingest-item-id a) "")) (ib (or (ingest-item-id b) "")))
    (cond ((string< da db) t)
          ((string> da db) nil)
          (t (string< ia ib)))))

(defun poll-once (sch)
  "Fetch items newer than the cursor, drop already-seen ids, dispatch the rest
   in chronological order, advance the cursor and persist state. Returns the
   list of newly-dispatched items."
  (let* ((items (fetch-items (scheduler-source sch) (scheduler-cursor sch)))
         (new (sort (remove-if (lambda (it)
                                 (or (null (ingest-item-id it))
                                     (gethash (ingest-item-id it) (scheduler-seen sch))))
                               (copy-list items))
                    #'item<)))
    (dolist (it new)
      (when (scheduler-dispatch sch)
        (funcall (scheduler-dispatch sch) it))
      (setf (gethash (ingest-item-id it) (scheduler-seen sch)) t)
      (let ((d (ingest-item-date it)))
        (when (and d (or (null (scheduler-cursor sch))
                         (string> d (scheduler-cursor sch))))
          (setf (scheduler-cursor sch) d))))
    (when (scheduler-save-state-fn sch)
      (funcall (scheduler-save-state-fn sch) (scheduler-state sch)))
    new))

(defun run-scheduler (sch &key (interval 3600) (max-polls nil) on-cycle)
  "Run the poll loop. Sleeps INTERVAL seconds between polls. When MAX-POLLS is
   set, stops after that many polls (used by tests / bounded runs); otherwise
   runs until the process is stopped. ON-CYCLE, when given, is called with the
   0-based cycle number BEFORE each poll — the hook where a daemon runs its
   own per-cycle agents (discovery, proposals, heartbeat) without the
   scheduler knowing anything about them. Returns the total number of items
   dispatched."
  (let ((polls 0) (total 0))
    (loop
      (when on-cycle (funcall on-cycle polls))
      (incf total (length (poll-once sch)))
      (incf polls)
      (when (and max-polls (>= polls max-polls)) (return))
      (sleep interval))
    total))

;;; ============================================================================
;;; STATE (serializable, persistence injected by the caller)
;;; ============================================================================

(defun scheduler-state (sch)
  "A serializable plist snapshot of the scheduler's incremental state."
  (list :cursor (scheduler-cursor sch)
        :seen (sort (loop for k being the hash-keys of (scheduler-seen sch) collect k)
                    #'string<)))

(defun restore-scheduler-state (sch state)
  "Restore CURSOR and SEEN from a plist produced by SCHEDULER-STATE."
  (setf (scheduler-cursor sch) (getf state :cursor))
  (clrhash (scheduler-seen sch))
  (dolist (id (getf state :seen)) (setf (gethash id (scheduler-seen sch)) t))
  sch)
