;;;; tests/source-profile-test.lisp
;;;; Source authority: MOP channel ranking, availability, provenance stamping,
;;;; highest-authority selection, and multi-source consensus
;;;; (agree / sole / authority-override / genuine conflict -> review).
;;;; Fully deterministic and offline: acquirers are injected, no network.

(in-package :orchestrator.source-authority)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun static-profile (channel name records &key (enabled t) available-fn)
  "A profile on CHANNEL whose acquirer always yields RECORDS (a list of plists)."
  (make-source-profile channel :name name :enabled enabled :available-fn available-fn
                       :acquirer (lambda (since) (declare (ignore since)) records)))

(format t "~%== MOP: channel taxonomy + authority ranking ==~%")
(check "channels discovered via the MOP"
       (and (member :institutional-feed (source-channels))
            (member :open-data-api (source-channels))
            (member :eu-cellar (source-channels))
            (member :web-scraper (source-channels))
            (member :manual-drop (source-channels))))
(check "metaclass carries channel"
       (eq :web-scraper (profile-channel (make-source-profile :web-scraper))))
(check "authority strictly ranks the channels (institutional > ... > manual)"
       (> (profile-authority (make-source-profile :institutional-feed))
          (profile-authority (make-source-profile :open-data-api))
          (profile-authority (make-source-profile :eu-cellar))
          (profile-authority (make-source-profile :web-scraper))
          (profile-authority (make-source-profile :manual-drop))))
(check "scraper is the only non-redistributable channel"
       (and (not (profile-redistributable-p (make-source-profile :web-scraper)))
            (profile-redistributable-p (make-source-profile :institutional-feed))
            (profile-redistributable-p (make-source-profile :open-data-api))))

(format t "~%== availability ==~%")
(check "enabled + acquirer -> available"
       (profile-available-p (static-profile :open-data-api "x" '())))
(check "no acquirer -> unavailable"
       (not (profile-available-p (make-source-profile :open-data-api :name "x"))))
(check "disabled -> unavailable"
       (not (profile-available-p (static-profile :open-data-api "x" '() :enabled nil))))
(check "failing reachability probe -> unavailable (never throws)"
       (not (profile-available-p
             (static-profile :open-data-api "x" '()
                             :available-fn (lambda () (error "down"))))))

(format t "~%== acquire: provenance stamping + deterministic content hash ==~%")
(let* ((p (static-profile :open-data-api "diavgeia"
                          (list (list :identity "art_5" :content "ΚΕΙΜΕΝΟ"
                                      :payload '(:op :replace-text :target "art_5")))))
       (recs (acquire p))
       (r (first recs)))
  (check "one record acquired" (= 1 (length recs)))
  (check "identity preserved" (string= "art_5" (record-identity r)))
  (check "channel + authority stamped" (and (eq :open-data-api (record-channel r))
                                            (= 80 (record-authority r))))
  (check "source name stamped" (string= "diavgeia" (record-source-name r)))
  (check "content hash present" (and (stringp (record-content-hash r))
                                     (plusp (length (record-content-hash r)))))
  ;; REGRESSION LOCK (fail-closed authorities): the content-hash is a GENUINE
  ;; SHA-256 — exactly 64 lowercase hex chars — never the raw canonical string
  ;; masquerading as a hash. The old silent fallback would pass "present" above
  ;; but fails here, so the masquerade can never be reintroduced unnoticed.
  (check "content hash is a genuine sha256 (64 lowercase hex, not a masquerade)"
         (let ((h (record-content-hash r)))
           (and (= 64 (length h))
                (every (lambda (c) (or (digit-char-p c)
                                       (char<= #\a c #\f))) h))))
  ;; REGRESSION LOCK: the fetched-at stamp is a real timestamp from the time
  ;; authority, never the fabricated 1970 epoch fallback that was here before.
  (check "fetched-at is a real timestamp, never the fabricated 1970 epoch"
         (let ((ts (record-fetched-at r)))
           (and (stringp ts) (not (search "1970" ts)))))
  (check "provenance plist is complete"
         (let ((pv (record-provenance r)))
           (and (getf pv :source) (getf pv :channel) (getf pv :content-hash))))
  (check "content hash is deterministic (same content -> same hash)"
         (string= (record-content-hash r)
                  (record-content-hash (first (acquire p))))))

(check "acquire of an unavailable profile yields nothing"
       (null (acquire (make-source-profile :open-data-api :name "x"))))

(format t "~%== selection: highest-authority available ==~%")
(let ((profiles (list (static-profile :manual-drop "m" '())
                      (static-profile :web-scraper "s" '())
                      (static-profile :open-data-api "d" '()))))
  (check "selects the highest-authority available channel"
         (eq :open-data-api (profile-channel (select-source profiles))))
  (check "an unavailable higher channel is skipped"
         (eq :open-data-api
             (profile-channel
              (select-source (cons (make-source-profile :institutional-feed :name "off")
                                   profiles)))))
  (check "no available profile -> nil"
         (null (select-source (list (make-source-profile :web-scraper :name "x"))))))

(format t "~%== consensus: agreement across sources ==~%")
(let* ((rec '(:identity "art_5" :content "ΟΡΘΟ ΚΕΙΜΕΝΟ" :payload "X"))
       (a (static-profile :open-data-api "diavgeia" (list rec)))
       (b (static-profile :eu-cellar     "cellar"   (list rec))))
  (multiple-value-bind (trusted conflicts) (acquire-with-consensus (list a b))
    (check "agreement -> exactly one trusted record" (= 1 (length trusted)))
    (check "no conflicts when sources agree" (null conflicts))
    (check "trusted record credits the highest-authority source"
           (eq :open-data-api (record-channel (first trusted))))
    (check "consensus disposition is :agreed" (eq :agreed (record-consensus (first trusted))))
    (check "the corroborating source is recorded"
           (member "cellar" (record-corroboration (first trusted)) :test #'string=))))

(format t "~%== consensus: a sole source is trusted but marked :sole ==~%")
(let ((a (static-profile :open-data-api "diavgeia"
                         (list '(:identity "art_9" :content "ΜΟΝΟ" :payload "Y")))))
  (multiple-value-bind (trusted conflicts) (acquire-with-consensus (list a))
    (check "sole source -> one trusted, no conflict"
           (and (= 1 (length trusted)) (null conflicts)))
    (check "disposition is :sole" (eq :sole (record-consensus (first trusted))))))

(format t "~%== consensus: official source OVERRIDES a strictly-lower scraper ==~%")
(let* ((a (static-profile :open-data-api "diavgeia"
                          (list '(:identity "art_7" :content "ΕΠΙΣΗΜΟ" :payload "off"))))
       (b (static-profile :web-scraper "scraper"
                          (list '(:identity "art_7" :content "ΣΚΡΑΠΑΡΙΣΜΕΝΟ" :payload "scr")))))
  (multiple-value-bind (trusted conflicts) (acquire-with-consensus (list a b))
    (check "official beats scraper automatically -> one trusted, no conflict"
           (and (= 1 (length trusted)) (null conflicts)))
    (check "the official source wins" (eq :open-data-api (record-channel (first trusted))))
    (check "disposition is :authority-override"
           (eq :authority-override (record-consensus (first trusted))))
    (check "the overridden lower source is recorded in provenance"
           (= 1 (length (record-overrode (first trusted)))))))

(format t "~%== consensus: genuine disagreement -> conflict -> review item ==~%")
(let* ((a (static-profile :web-scraper "scraper"
                          (list '(:identity "art_3" :content "ΕΚΔΟΧΗ-Α" :payload "a"))))
       (b (static-profile :manual-drop "manual"
                          (list '(:identity "art_3" :content "ΕΚΔΟΧΗ-Β" :payload "b")))))
  (multiple-value-bind (trusted conflicts) (acquire-with-consensus (list a b))
    (check "two low-authority sources disagree -> NOT trusted" (null trusted))
    (check "the disagreement is surfaced as one conflict" (= 1 (length conflicts)))
    (check "conflict names the provision"
           (string= "art_3" (conflict-identity (first conflicts))))
    (check "conflict keeps both candidates" (= 2 (length (conflict-candidates (first conflicts)))))
    (let ((items (consensus-conflicts->review-items conflicts)))
      (check "a review item is produced for the lawyer" (= 1 (length items)))
      (check "the review item is high severity"
             (eq :high (orchestrator.review:item-severity (first items))))
      (check "the review item targets the disputed provision"
             (string= "art_3" (orchestrator.review:item-target (first items)))))))

(format t "~%== unavailable profiles contribute nothing to consensus ==~%")
(let* ((a (static-profile :open-data-api "diavgeia"
                          (list '(:identity "art_1" :content "ΚΕΙΜΕΝΟ" :payload "z"))))
       (dead (make-source-profile :web-scraper :name "dead")))   ; no acquirer
  (multiple-value-bind (trusted conflicts) (acquire-with-consensus (list a dead))
    (check "the dead channel is silently skipped"
           (and (= 1 (length trusted)) (null conflicts)))))

(format t "~%== registry: register / select over the configured stack ==~%")
(clear-registry)
(register-profile (static-profile :manual-drop "m" '()))
(register-profile (static-profile :open-data-api "d" '()))
(check "registry keeps both" (= 2 (length (registered-profiles))))
(check "re-registering same name replaces, not duplicates"
       (progn (register-profile (static-profile :open-data-api "d" '()))
              (= 2 (length (registered-profiles)))))
(check "select over the registry picks the highest authority"
       (eq :open-data-api (profile-channel (select-source (registered-profiles)))))
(clear-registry)

(format t "~%== default-source-profiles: an honest, ranked stack ==~%")
(let ((stack (default-source-profiles :diavgeia t :manual t :scrape nil)))
  (check "the stack is ordered highest-authority first"
         (equal (mapcar #'profile-authority stack)
                (sort (copy-list (mapcar #'profile-authority stack)) #'>)))
  (check "the unconfigured institutional feed is present but unavailable"
         (let ((inst (find :institutional-feed stack :key #'profile-channel)))
           (and inst (not (profile-available-p inst))))))

(format t "~%== daemon integration: consensus stack as one ingestion source ==~%")
(let* ((rec '(:identity "art_5" :content "ΟΡΘΟ" :payload (:op :replace-text :target "art_5")))
       (a (static-profile :open-data-api "diavgeia" (list rec)))
       (b (static-profile :eu-cellar "cellar" (list rec)))
       (src (make-consensus-source :name "test-consensus" :profiles (list a b)))
       (fetch (find-symbol "FETCH-ITEMS" :orchestrator.ingestion))
       (item-id (find-symbol "INGEST-ITEM-ID" :orchestrator.ingestion))
       (item-payload (find-symbol "INGEST-ITEM-PAYLOAD" :orchestrator.ingestion)))
  (check "consensus source is a real ingestion source" (and src fetch))
  (let ((items (funcall fetch src nil)))
    (check "agreed provision is dispatched as one ingest-item" (= 1 (length items)))
    (check "the item carries the provision identity"
           (string= "art_5" (funcall item-id (first items))))
    (check "the item carries the trusted payload (ready to consolidate)"
           (eq :replace-text (getf (funcall item-payload (first items)) :op)))))

(let* ((a (static-profile :web-scraper "scraper"
                          (list '(:identity "art_3" :content "Α" :payload "a"))))
       (b (static-profile :manual-drop "manual"
                          (list '(:identity "art_3" :content "Β" :payload "b"))))
       (seen-conflicts nil)
       (src (make-consensus-source :profiles (list a b)
                                   :on-conflict (lambda (cs) (setf seen-conflicts cs))))
       (fetch (find-symbol "FETCH-ITEMS" :orchestrator.ingestion)))
  (let ((items (funcall fetch src nil)))
    (check "a disputed provision is NOT dispatched (held for review)" (null items))
    (check "the conflict was routed to the on-conflict handler"
           (= 1 (length seen-conflicts)))))

(format t "~%========================================~%")
(format t "Source authority tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
