;;;; tests/ingestion-daemon-test.lisp
;;;; Offline verification of the deployment daemon: ingested amending acts
;;;; trigger re-emission of the full consumption artifact set.

(in-package :orchestrator.ingestion.daemon)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun base-doc ()
  (orchestrator.consolidation.bridge:articles->document
   (list (list 1 "Άρθρο 1" "Κείμενο 1.")
         (list 2 "Άρθρο 2" "Κείμενο 2.")
         (list 3 "Άρθρο 3" "Κείμενο 3."))
   :id "demo" :title "Demo"))

(defun rec (id date &key amended repealed)
  (list (cons "id" id) (cons "date" date) (cons "date_applicability" date)
        (cons "articles_amended" amended) (cons "articles_repealed" repealed)))

(defun item (id date payload)
  (orchestrator.ingestion:make-ingest-item :id id :date date :payload payload))

(defun static-src (items)
  (orchestrator.ingestion:make-ingestion-source
   :name "t" :fetcher (lambda (since)
                        (remove-if (lambda (x)
                                     (and since (orchestrator.ingestion:ingest-item-date x)
                                          (string<= (orchestrator.ingestion:ingest-item-date x) since)))
                                   items))))

(defun run-capture ()
  "Run the daemon once over two amending items; capture artifacts in a hash."
  (let* ((store (make-hash-table :test 'equal))
         (write-fn (lambda (content path)
                     (setf (gethash (file-namestring path) store) content)))
         (src (static-src (list (item "L1" "2010-01-01" (rec "L1" "2010-01-01" :repealed '(3)))
                                (item "L2" "2019-01-01" (rec "L2" "2019-01-01" :amended '(1))))))
         (total (run-update-daemon :base-document (base-doc) :source src
                                   :output-dir "/tmp/daemon-out/"
                                   :interval 0 :max-polls 1 :write-fn write-fn)))
    (values store total)))

(multiple-value-bind (store total) (run-capture)
  (format t "~%== Daemon run ==~%")
  (check "two amending items dispatched" (= 2 total))
  (check "all five artifacts written"
         (every (lambda (n) (gethash n store))
                '("consolidated.txt" "consolidated.ttl" "consolidated.akn.xml"
                  "corpus.jsonl" "catalog.jsonld")))

  (format t "~%== Emitted corpus.jsonl reflects ingested amendments ==~%")
  (let* ((jsonl (gethash "corpus.jsonl" store))
         (objs (mapcar (lambda (l) (jonathan:parse l :as :alist))
                       (remove "" (uiop:split-string jsonl :separator '(#\Newline))
                               :test #'string=)))
         (a3 (find "art_3" objs :key (lambda (o) (cdr (assoc "eId" o :test #'string=)))
                   :test #'string=))
         (a1 (find "art_1" objs :key (lambda (o) (cdr (assoc "eId" o :test #'string=)))
                   :test #'string=)))
    (check "art_3 repealed (in_force false) in emitted dump"
           (eq (cdr (assoc "in_force" a3 :test #'string=)) nil))
    (check "art_1 amended_by L2 in emitted dump"
           (string= (cdr (assoc "amended_by" a1 :test #'string=)) "L2")))

  (format t "~%== AKN artifact is well-formed-ish (has akomaNtoso) ==~%")
  (check "consolidated.akn.xml emitted with AKN root"
         (search "<akomaNtoso" (gethash "consolidated.akn.xml" store)))
  (check "catalog.jsonld advertises Akoma Ntoso distribution"
         (search "application/akn+xml" (gethash "catalog.jsonld" store))))

(format t "~%== Determinism across daemon runs ==~%")
(let ((s1 (run-capture)) (s2 (run-capture)))
  (check "emitted corpus.jsonl identical across runs"
         (string= (gethash "corpus.jsonl" s1) (gethash "corpus.jsonl" s2)))
  (check "emitted consolidated.ttl identical across runs"
         (string= (gethash "consolidated.ttl" s1) (gethash "consolidated.ttl" s2))))

(format t "~%========================================~%")
(format t "Ingestion daemon tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
