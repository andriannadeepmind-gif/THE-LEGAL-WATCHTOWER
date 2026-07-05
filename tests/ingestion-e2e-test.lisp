;;;; tests/ingestion-e2e-test.lisp
;;;; ============================================================================
;;;; END-TO-END LIVE INGESTION
;;;; ============================================================================
;;;; Drives the FULL production chain against a real (local) HTTP source:
;;;;
;;;;   Διαύγεια-shaped decision (served over HTTP)
;;;;     -> make-diavgeia-source (fetch + amendment extraction)
;;;;     -> scheduler (incremental, idempotent)
;;;;     -> consolidation feed (re-consolidate base + new act)
;;;;     -> corpus-updater (re-emit consumption artifacts)
;;;;
;;;; Proves the wired pipeline turns a published decision into correctly
;;;; consolidated output — the "stays up to date from the state source" path.
;;;; ============================================================================

(in-package :orchestrator.ingestion.daemon)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun mp (&rest a) (apply (find-symbol "MAKE-PROVISION" :orchestrator.consolidation) a))
(defun md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" :orchestrator.consolidation) a))

(defun base-doc ()
  (md :id "demo" :title "Demo Code" :language "el"
      :provisions (list (mp :eid "art_1" :kind :article :num "1" :heading "Α" :text "Αρχικό 1.")
                        (mp :eid "art_2" :kind :article :num "2" :heading "Β" :text "Αρχικό 2.")
                        (mp :eid "art_3" :kind :article :num "3" :heading "Γ" :text "Αρχικό 3."))))

;; A realistic Διαύγεια opendata response: one decision that AMENDS article 2
;; (standard nomotechnic formula) and one pure announcement (must be ignored).
(defparameter *decisions-json*
  "{\"decisions\":[
     {\"ada\":\"6ΞΞΞ-Α1Α\",\"submissionTimestamp\":\"2024-05-01\",
      \"documentUrl\":\"https://diavgeia.gov.gr/doc/6ΞΞΞ-Α1Α\",
      \"subject\":\"Το άρθρο 2 του Κώδικα αντικαθίσταται ως εξής: «Το αναμορφωμένο άρθρο 2 ισχύει.»\"},
     {\"ada\":\"7ΨΨΨ-Β2Β\",\"submissionTimestamp\":\"2024-05-02\",
      \"documentUrl\":\"https://diavgeia.gov.gr/doc/7ΨΨΨ-Β2Β\",
      \"subject\":\"Ανακοίνωση διενέργειας ηλεκτρονικού διαγωνισμού προμηθειών.\"}
   ]}")

(let ((srv (orchestrator.http:start-server
            (lambda (req) (declare (ignore req))
              (orchestrator.http:respond 200 *decisions-json*
                                         "Content-Type" "application/json"))
            :port 0)))
  (sleep 0.3)
  (let* ((port (orchestrator.http:server-port srv))
         (saved orchestrator.gov-source:*diavgeia-search-url*)
         (captured (make-hash-table :test 'equal)))
    (unwind-protect
         (progn
           ;; Point the Διαύγεια source at our local opendata endpoint.
           (setf orchestrator.gov-source:*diavgeia-search-url*
                 (format nil "http://127.0.0.1:~D/opendata/search.json" port))

           (format t "~%== Source produces a real amending act from the decision ==~%")
           (let* ((src (orchestrator.gov-source:make-diavgeia-source))
                  (items (funcall (find-symbol "FETCH-ITEMS" :orchestrator.ingestion) src nil)))
             (check "fetched exactly the 2 decisions" (= 2 (length items)))
             (let* ((amending (find-if
                               (lambda (it)
                                 (let ((p (funcall (find-symbol "INGEST-ITEM-PAYLOAD" :orchestrator.ingestion) it)))
                                   (and (listp p) (assoc "operations" p :test #'equal)
                                        (cdr (assoc "operations" p :test #'equal)))))
                               items)))
               (check "the amending decision carried structured operations" (not (null amending)))
               (check "the announcement carried NO operations"
                      (= 1 (count-if
                            (lambda (it)
                              (let ((p (funcall (find-symbol "INGEST-ITEM-PAYLOAD" :orchestrator.ingestion) it)))
                                (or (not (listp p)) (null (assoc "operations" p :test #'equal)))))
                            items)))))

           (format t "~%== Full daemon: poll -> consolidate -> emit artifacts ==~%")
           (let* ((src (orchestrator.gov-source:make-diavgeia-source))
                  (write-fn (lambda (content path)
                              (setf (gethash (file-namestring path) captured) content)))
                  (total (run-update-daemon
                          :base-document (base-doc) :source src
                          :output-dir "/tmp/e2e-out/" :max-polls 1 :write-fn write-fn)))
             (check "daemon polled both decisions (scheduler dispatches all)"
                    (= 2 total))
             (check "consolidated.txt was emitted" (gethash "consolidated.txt" captured))
             (check "consolidated text reflects the amendment to article 2"
                    (search "αναμορφωμένο άρθρο 2" (or (gethash "consolidated.txt" captured) "")))
             (check "untouched article 1 text preserved"
                    (search "Αρχικό 1." (or (gethash "consolidated.txt" captured) "")))
             (check "PROV-O provenance artifact emitted"
                    (gethash "consolidated.ttl" captured))
             (check "Akoma Ntoso artifact emitted"
                    (gethash "consolidated.akn.xml" captured))
             (check "bulk JSONL artifact emitted"
                    (gethash "corpus.jsonl" captured))))
      (setf orchestrator.gov-source:*diavgeia-search-url* saved)
      (orchestrator.http:stop-server srv))))

(format t "~%========================================~%")
(format t "Ingestion E2E tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
