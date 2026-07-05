;;;; tests/legislation-ingestion-test.lisp
;;;; Offline verification of the incremental ingestion scheduler.

(in-package :orchestrator.ingestion)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun item (id date) (make-ingest-item :id id :date date :title (format nil "Item ~A" id)))

;;; A mutable store so we can add new items between polls.
(defun mutable-source (store-box)
  (make-ingestion-source
   :name "test"
   :fetcher (lambda (since)
              (remove-if (lambda (it) (and since (ingest-item-date it)
                                           (string<= (ingest-item-date it) since)))
                         (car store-box)))))

(let* ((store (list (list (item "i1" "2020-01-01")
                          (item "i2" "2020-02-01")
                          (item "i3" "2020-01-15"))))
       (dispatched '())
       (saved '())
       (sch (make-scheduler
             :source (mutable-source store)
             :dispatch (lambda (it) (push (ingest-item-id it) dispatched))
             :save-state-fn (lambda (st) (push st saved)))))

  (format t "~%== First poll ==~%")
  (let ((new (poll-once sch)))
    (check "first poll dispatches all 3 items" (= 3 (length new)))
    (check "dispatched in chronological order (i1, i3, i2)"
           (equal (reverse dispatched) '("i1" "i3" "i2")))
    (check "cursor advanced to newest (2020-02-01)"
           (string= (scheduler-cursor sch) "2020-02-01"))
    (check "seen-count = 3" (= 3 (scheduler-seen-count sch)))
    (check "save-state-fn was called" (= 1 (length saved))))

  (format t "~%== Idempotent re-poll ==~%")
  (setf dispatched '())
  (let ((new (poll-once sch)))
    (check "re-poll dispatches nothing new" (null new))
    (check "no items re-dispatched" (null dispatched)))

  (format t "~%== New item appears ==~%")
  (setf (car store) (cons (item "i4" "2020-03-01") (car store)))
  (let ((new (poll-once sch)))
    (check "only the new item i4 is dispatched"
           (and (= 1 (length new)) (string= (ingest-item-id (first new)) "i4")))
    (check "cursor advanced to 2020-03-01" (string= (scheduler-cursor sch) "2020-03-01"))
    (check "seen-count = 4" (= 4 (scheduler-seen-count sch))))

  (format t "~%== State save / restore (simulated restart) ==~%")
  (let* ((state (scheduler-state sch))
         (store2 (list (car store)))           ; same items as the store currently holds
         (dispatched2 '())
         (sch2 (make-scheduler
                :source (mutable-source store2)
                :dispatch (lambda (it) (push (ingest-item-id it) dispatched2)))))
    (restore-scheduler-state sch2 state)
    (check "restored cursor matches" (string= (scheduler-cursor sch2) "2020-03-01"))
    (check "restored seen-count matches" (= 4 (scheduler-seen-count sch2)))
    (let ((new (poll-once sch2)))
      (check "after restart, no items re-dispatched" (and (null new) (null dispatched2))))
    ;; a brand-new item after restart is picked up
    (setf (car store2) (cons (item "i5" "2020-04-01") (car store2)))
    (let ((new (poll-once sch2)))
      (check "post-restart new item i5 dispatched"
             (and (= 1 (length new)) (string= (ingest-item-id (first new)) "i5"))))))

(format t "~%== Static source since-filtering ==~%")
(let ((src (make-static-source "s" (list (item "a" "2019-01-01") (item "b" "2021-01-01")))))
  (check "no since -> all items" (= 2 (length (fetch-items src))))
  (check "since 2020 -> only later item" (= 1 (length (fetch-items src "2020-01-01")))))

(format t "~%== run-scheduler bounded loop ==~%")
(let* ((store (list (list (item "x" "2020-01-01") (item "y" "2020-02-01"))))
       (sch (make-scheduler :source (mutable-source store) :dispatch (lambda (it) (declare (ignore it))))))
  (check "run-scheduler max-polls=1 dispatches 2 items"
         (= 2 (run-scheduler sch :interval 0 :max-polls 1))))

(format t "~%========================================~%")
(format t "Ingestion scheduler tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
