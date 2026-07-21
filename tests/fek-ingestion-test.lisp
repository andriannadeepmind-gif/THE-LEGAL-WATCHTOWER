;;;; tests/fek-ingestion-test.lisp
;;;; ============================================================================
;;;; ΦΕΚ LAW INGESTION (END-TO-END, READING HTML DIRECTLY)
;;;; ============================================================================
;;;; The initial production feed: newly published LAWS from ΦΕΚ (Τεύχος Α'),
;;;; read straight from the search-results HTML (there is no public JSON API).
;;;;
;;;;   ΦΕΚ search HTML (listing of laws)        served at /el/
;;;;     -> parse-fek-listing-html -> entries with links
;;;;     -> fetch each law document (HTML)       served at /fek/<n>
;;;;     -> html->text -> extract operations
;;;;     -> scheduler -> consolidation feed -> artifacts reflect the new law
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
  (md :id "pk" :title "Ποινικός Κώδικας" :language "el" :work-date "2019-06-11"
      :provisions (list (mp :eid "art_1" :kind :article :num "1" :heading "Α" :text "Αρχικό 1.")
                        (mp :eid "art_2" :kind :article :num "2" :heading "Β" :text "Αρχικό 2.")
                        (mp :eid "art_3" :kind :article :num "3" :heading "Γ" :text "Αρχικό 3."))))

;; The ΦΕΚ search-results page: an HTML listing linking to each law document.
(defparameter *listing-html*
  "<html><body><table>
     <tr><td><a href=\"/fek/4855-2021-A\">Νόμος 4855/2021 (12/11/2021) — Τροποποιήσεις του Ποινικού Κώδικα</a></td></tr>
     <tr><td><a href=\"/fek/4999-2022-A\">Νόμος 4999/2022 (05/01/2022) — Άσχετος νόμος</a></td></tr>
     <tr><td><a href=\"/el/about\">Σχετικά με το Εθνικό Τυπογραφείο</a></td></tr>
   </table></body></html>")

;; The amending law document (HTML) — its body carries the nomotechnic formulas.
(defparameter *law-4855-html*
  "<html><body><h1>ΝΟΜΟΣ ΥΠ' ΑΡΙΘΜ. 4855/2021</h1>
   <p>Άρθρο 1. Το άρθρο 2 του Ποινικού Κώδικα αντικαθίσταται ως εξής: &laquo;Το νέο άρθρο 2 ισχύει.&raquo;</p>
   <p>Άρθρο 2. Το άρθρο 3 του Κώδικα καταργείται.</p></body></html>")

(defparameter *law-4999-html*
  "<html><body><h1>ΝΟΜΟΣ 4999/2022</h1>
   <p>Ρυθμίσεις για τη λειτουργία δημοσίων υπηρεσιών χωρίς τροποποίηση κωδίκων.</p></body></html>")

(defun route (path)
  (cond ((search "4855" path) *law-4855-html*)
        ((search "4999" path) *law-4999-html*)
        (t *listing-html*)))

;; [0036] Δ1: ο ΤΟΠΙΚΟΣ test server είναι loopback — ρητό, scoped binding (unwind ⇒ ξανά ΚΛΕΙΣΤΟ)
(let ((orchestrator.document-fetch:*allow-loopback-fetch* t)
      (srv (orchestrator.http:start-server
            (lambda (req)
              (orchestrator.http:respond
               200 (route (orchestrator.http:http-request-path req))
               "Content-Type" "text/html; charset=utf-8"))
            :port 0)))
  (sleep 0.3)
  (let* ((port (orchestrator.http:server-port srv))
         (search-url (format nil "http://127.0.0.1:~D/el/" port))
         (captured (make-hash-table :test 'equal)))
    (unwind-protect
         (progn
           (format t "~%== ΦΕΚ source reads the listing HTML + law documents ==~%")
           (let* ((src (orchestrator.gov-source:make-fek-source :url search-url))
                  (items (funcall (find-symbol "FETCH-ITEMS" :orchestrator.ingestion) src nil)))
             (check "two laws parsed from the listing (the 'about' link ignored)"
                    (= 2 (length items)))
             (let ((amending (find-if
                              (lambda (it)
                                (let ((p (funcall (find-symbol "INGEST-ITEM-PAYLOAD" :orchestrator.ingestion) it)))
                                  (and (listp p) (cdr (assoc "operations" p :test #'equal)))))
                              items)))
               (check "the amending law carried operations (from its document)" (not (null amending)))
               (check "law id is the ΦΕΚ number" (string= (funcall (find-symbol "INGEST-ITEM-ID" :orchestrator.ingestion) amending) "4855/2021"))
               (check "two operations extracted (replace art_2, repeal art_3)"
                      (= 2 (length (cdr (assoc "operations"
                                              (funcall (find-symbol "INGEST-ITEM-PAYLOAD" :orchestrator.ingestion) amending)
                                              :test #'equal)))))))

           (format t "~%== Full daemon: listing -> documents -> consolidate -> emit ==~%")
           (let* ((src (orchestrator.gov-source:make-fek-source :url search-url))
                  (write-fn (lambda (content path)
                              (setf (gethash (file-namestring path) captured) content)))
                  (total (run-update-daemon
                          :base-document (base-doc) :source src
                          :output-dir "/tmp/fek-html-out/" :max-polls 1 :write-fn write-fn)))
             (check "daemon polled both laws" (= 2 total))
             (check "consolidated text reflects the amendment to article 2"
                    (search "νέο άρθρο 2" (or (gethash "consolidated.txt" captured) "")))
             (check "untouched article 1 preserved"
                    (search "Αρχικό 1." (or (gethash "consolidated.txt" captured) "")))
             (check "PROV-O provenance cites ΦΕΚ law 4855/2021"
                    (search "4855/2021" (or (gethash "consolidated.ttl" captured) "")))
             (check "Akoma Ntoso emitted" (gethash "consolidated.akn.xml" captured))
             (check "bulk JSONL emitted" (gethash "corpus.jsonl" captured))))
      (orchestrator.http:stop-server srv))))

(format t "~%========================================~%")
(format t "ΦΕΚ HTML ingestion tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
