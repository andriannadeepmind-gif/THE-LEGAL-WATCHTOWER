;;;; tests/consolidation-feed-test.lisp
;;;; Verifies the ingestion -> consolidation loop: newly ingested amending acts
;;;; automatically update the in-force consolidated document.

(in-package :orchestrator.consolidation.feed)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;; shorthands into the other packages
(defun base-doc ()
  (orchestrator.consolidation.bridge:articles->document
   (list (list 1 "Άρθρο 1" "Κείμενο 1.")
         (list 2 "Άρθρο 2" "Κείμενο 2.")
         (list 3 "Άρθρο 3" "Κείμενο 3."))
   :id "demo" :title "Demo"))

(defun status-of (doc eid) (orchestrator.consolidation:provision-status
                            (orchestrator.consolidation:find-provision doc eid)))
(defun source-of (doc eid) (orchestrator.consolidation:provision-source-act
                            (orchestrator.consolidation:find-provision doc eid)))

(defun rec (id date &key amended repealed)
  (list (cons "id" id) (cons "date" date) (cons "date_applicability" date)
        (cons "articles_amended" amended) (cons "articles_repealed" repealed)))

(defun item (id date payload)
  (orchestrator.ingestion:make-ingest-item :id id :date date :payload payload))

;;; ---------------------------------------------------------------------------

(let* ((feed (make-consolidation-feed :base-document (base-doc)))
       (latest nil)
       (updates 0)
       (dispatch (make-feed-dispatch
                  feed :on-update (lambda (doc it) (declare (ignore it))
                                    (setf latest doc) (incf updates))))
       (store (list (list (item "L100" "2010-01-01" (rec "L100" "2010-01-01" :repealed '(3)))
                          (item "L200" "2019-01-01" (rec "L200" "2019-01-01" :amended '(1))))))
       (source (orchestrator.ingestion:make-ingestion-source
                :name "feed-test"
                :fetcher (lambda (since)
                           (remove-if (lambda (x)
                                        (and since (orchestrator.ingestion:ingest-item-date x)
                                             (string<= (orchestrator.ingestion:ingest-item-date x) since)))
                                      (car store)))))
       (sch (orchestrator.ingestion:make-scheduler :source source :dispatch dispatch)))

  (format t "~%== Initial state (no acts) ==~%")
  (check "base: art_3 original" (eq (status-of (feed-consolidated feed) "art_3") :original))
  (check "feed starts with 0 acts" (null (consolidation-feed-acts feed)))

  (format t "~%== Poll ingests two amending acts ==~%")
  (let ((new (orchestrator.ingestion:poll-once sch)))
    (check "two items dispatched" (= 2 (length new)))
    (check "on-update fired twice" (= 2 updates))
    (check "feed accumulated 2 acts" (= 2 (length (consolidation-feed-acts feed)))))

  (format t "~%== Consolidated reflects ingested amendments ==~%")
  (let ((doc (feed-consolidated feed)))
    (check "art_3 now repealed by L100"
           (and (eq (status-of doc "art_3") :repealed)
                (string= (source-of doc "art_3") "L100")))
    (check "art_1 now amended by L200"
           (and (eq (status-of doc "art_1") :amended)
                (string= (source-of doc "art_1") "L200")))
    (check "art_2 untouched" (eq (status-of doc "art_2") :original))
    (check "repealed art_3 omitted from in-force text"
           (null (search "Κείμενο 3." (orchestrator.consolidation:render-consolidated-text doc)))))

  (format t "~%== Point-in-time over ingested feed ==~%")
  (check "as-of 2015: only L100 applied (art_1 still original)"
         (eq (status-of (feed-consolidated feed :as-of-date "2015-01-01") "art_1") :original))

  (format t "~%== Determinism ==~%")
  (check "consolidated text stable across calls"
         (string= (orchestrator.consolidation:render-consolidated-text (feed-consolidated feed))
                  (orchestrator.consolidation:render-consolidated-text (feed-consolidated feed))))

  (format t "~%== Notification-only item (no payload) is harmless ==~%")
  (let ((before (length (consolidation-feed-acts feed))))
    (feed-apply-item feed (item "NOTE" "2020-01-01" nil))
    (check "item with nil payload adds no act"
           (= before (length (consolidation-feed-acts feed))))))

(format t "~%========================================~%")
(format t "Consolidation feed tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
