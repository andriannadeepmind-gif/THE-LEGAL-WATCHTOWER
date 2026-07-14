;;;; tests/corpus-service-test.lisp
;;;; Verifies the AI-first corpus service: MOP-driven content negotiation,
;;;; routing, AI-first headers, and a real HTTP round-trip.

(in-package :orchestrator.corpus-service)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun build-doc ()
  (let ((c (find-package :orchestrator.consolidation)))
    (flet ((mp (&rest a) (apply (find-symbol "MAKE-PROVISION" c) a))
           (md (&rest a) (apply (find-symbol "MAKE-LEGAL-DOCUMENT" c) a))
           (ma (&rest a) (apply (find-symbol "MAKE-AMENDING-ACT" c) a))
           (cons* (&rest a) (apply (find-symbol "CONSOLIDATE" c) a)))
      (cons* (md :id "demo" :title "Demo Code" :language "el"
                 :provisions (list (mp :eid "art_1" :kind :article :num "1" :heading "Α" :text "Κ1.")
                                   (mp :eid "art_2" :kind :article :num "2" :heading "Β" :text "Κ2.")
                                   (mp :eid "art_3" :kind :article :num "3" :heading "Γ" :text "Κ3.")))
             (list (ma :id "L1" :effective "2010-01-01"
                       :operations (list (list :op :repeal :target "art_3"))))))))

(defpackage :orchestrator.corpus-service.test (:use :cl))
(defun req (path &key (method "GET") accept)
  ;; δέχεται και "?k=v" στο path — ο πραγματικός server τα χωρίζει στο accept
  ;; loop, εδώ τα χωρίζουμε ώστε τα route tests να περνούν από την ίδια μορφή
  (let* ((qpos (position #\? path))
         (pure (if qpos (subseq path 0 qpos) path))
         (query (when qpos
                  (loop for kv in (uiop:split-string (subseq path (1+ qpos))
                                                     :separator '(#\&))
                        for eq = (position #\= kv)
                        when eq collect (cons (subseq kv 0 eq) (subseq kv (1+ eq)))))))
    (funcall (find-symbol "MAKE-HTTP-REQUEST" :orchestrator.http)
             :method method :path pure :query query
             :headers (when accept (list (cons "accept" accept))))))
(defun rstatus (r) (funcall (find-symbol "HTTP-RESPONSE-STATUS" :orchestrator.http) r))
(defun rbody (r) (funcall (find-symbol "HTTP-RESPONSE-BODY" :orchestrator.http) r))
(defun rheader (r name) (cdr (assoc name (funcall (find-symbol "HTTP-RESPONSE-HEADERS" :orchestrator.http) r)
                                    :test #'string=)))

(let* ((doc (build-doc))
       (service (make-corpus-service (lambda () doc)))
       (handler (service-handler service)))

  (format t "~%== MOP-driven negotiation ==~%")
  (check "5 representations discovered via MOP" (= 5 (length (available-representations))))
  (check "negotiate akn -> akn-representation"
         (typep (negotiate "application/akn+xml") 'akn-representation))
  (check "negotiate turtle -> turtle-representation"
         (typep (negotiate "text/turtle") 'turtle-representation))
  (check "negotiate */* -> default (jsonl)"
         (typep (negotiate "*/*") 'jsonl-representation))
  (check "negotiate absent -> default (jsonl)"
         (typep (negotiate nil) 'jsonl-representation))
  (check "negotiate q-values: turtle preferred"
         (typep (negotiate "application/json;q=0.5, text/turtle;q=0.9") 'turtle-representation))

  (format t "~%== Routing (direct handler) ==~%")
  (let ((r (funcall handler (req "/" :accept "application/akn+xml"))))
    (check "root + Accept akn -> AKN body"
           (and (= 200 (rstatus r)) (search "<akomaNtoso" (rbody r))))
    (check "content-type reflects negotiated akn"
           (search "application/akn+xml" (rheader r "Content-Type"))))
  (let ((r (funcall handler (req "/" :accept nil))))
    (check "root default -> JSONL (AI-first)" (search "application/jsonl" (rheader r "Content-Type"))))
  (check "/catalog.jsonld -> dcat:Dataset"
         (search "dcat:Dataset" (rbody (funcall handler (req "/catalog.jsonld")))))
  (check "/corpus.jsonl -> jsonl lines"
         (search "\"eId\":\"art_1\"" (rbody (funcall handler (req "/corpus.jsonl")))))
  (check "/consolidated.ttl -> turtle"
         (search "eli:in_force" (rbody (funcall handler (req "/consolidated.ttl")))))
  (check "/article/art_1 -> JSON with eId"
         (search "\"eId\":\"art_1\"" (rbody (funcall handler (req "/article/art_1")))))
  (check "/article/art_3 reports repealed (in_force false)"
         (search "\"in_force\":false" (rbody (funcall handler (req "/article/art_3")))))
  (check "/article/missing -> 404" (= 404 (rstatus (funcall handler (req "/article/zzz")))))
  (check "POST -> 405" (= 405 (rstatus (funcall handler (req "/" :method "POST")))))

  (format t "~%== AI-first hygiene ==~%")
  (check "robots.txt welcomes GPTBot and ClaudeBot"
         (let ((b (rbody (funcall handler (req "/robots.txt")))))
           (and (search "GPTBot" b) (search "ClaudeBot" b))))
  (check "/.well-known/ai-corpus.json advertises ai_first"
         (search "\"ai_first\": true" (rbody (funcall handler (req "/.well-known/ai-corpus.json")))))
  (let ((d (rbody (funcall handler (req "/.well-known/ai-corpus.json")))))
    (check "discovery advertises the article endpoint" (search "\"article\":" d))
    (check "discovery advertises the search endpoint" (search "\"search\":" d))
    (check "discovery advertises the sparql endpoint" (search "\"sparql\":" d))
    (check "discovery advertises the diff endpoint" (search "\"diff\":" d))
    (check "discovery advertises the dataset endpoint" (search "\"dataset\":" d)))

  (format t "~%== AI training dataset (/dataset) ==~%")
  (let ((r (funcall handler (req "/dataset"))))
    (check "/dataset -> 200 JSON manifest"
           (and (= 200 (rstatus r)) (search "\"statistics\"" (rbody r))))
    (check "/dataset reports real article count" (search "\"total_articles\":3" (rbody r)))
    (check "/dataset content-type application/json"
           (search "application/json" (rheader r "Content-Type"))))
  (let ((r (funcall handler (req "/dataset.jsonl"))))
    (check "/dataset.jsonl -> 200 with HuggingFace records"
           (and (= 200 (rstatus r)) (search "\"article_id\":\"art_1\"" (rbody r))))
    (check "/dataset.jsonl content-type application/jsonl"
           (search "application/jsonl" (rheader r "Content-Type"))))
  (let ((r (funcall handler (req "/dataset.ttl"))))
    (check "/dataset.ttl -> 200 Turtle manifest"
           (and (= 200 (rstatus r)) (search "ingest:AIManifest" (rbody r)))))
  (let ((r (funcall handler (req "/dataset/train.jsonl"))))
    (check "/dataset/train.jsonl -> 200" (= 200 (rstatus r))))

  (format t "~%== PROV-O provenance (/provenance) ==~%")
  (let ((r (funcall handler (req "/provenance"))))
    (check "/provenance -> 200 Turtle PROV-O"
           (and (= 200 (rstatus r)) (search "prov:Bundle" (rbody r))))
    (check "/provenance records the amending act"
           (search "L1" (rbody r)))
    (check "/provenance content-type text/turtle"
           (search "text/turtle" (rheader r "Content-Type"))))
  (let ((r (funcall handler (req "/provenance.jsonld"))))
    (check "/provenance.jsonld -> 200 JSON-LD" (= 200 (rstatus r)))
    (check "/provenance.jsonld content-type ld+json"
           (search "ld+json" (rheader r "Content-Type"))))

  (format t "~%== National↔EU links (/eu-references) ==~%")
  (let ((r (funcall handler (req "/eu-references"))))
    (check "/eu-references -> 200 JSON" (= 200 (rstatus r)))
    (check "/eu-references has the envelope"
           (search "\"articles_with_references\":" (rbody r)))
    (check "/eu-references content-type json"
           (search "application/json" (rheader r "Content-Type"))))

  (let ((r (funcall handler (req "/catalog.jsonld"))))
    (check "CORS header present" (string= (rheader r "Access-Control-Allow-Origin") "*"))
    (check "Vary: Accept present" (string= (rheader r "Vary") "Accept"))
    (check "Link describedby present" (search "describedby" (rheader r "Link"))))

  (format t "~%== Real HTTP round-trip ==~%")
  (let ((srv (funcall (find-symbol "START-SERVER" :orchestrator.http) handler :port 0)))
    (unwind-protect
         (progn
           (sleep 0.3)
           (let ((port (funcall (find-symbol "SERVER-PORT" :orchestrator.http) srv)))
             (multiple-value-bind (body status)
                 (drakma:http-request (format nil "http://127.0.0.1:~D/catalog.jsonld" port))
               (check "HTTP GET /catalog.jsonld -> 200 + dcat:Dataset"
                      (and (= 200 status)
                           (search "dcat:Dataset" (if (stringp body) body
                                                      (babel:octets-to-string body :encoding :utf-8))))))
             (multiple-value-bind (body status)
                 (drakma:http-request (format nil "http://127.0.0.1:~D/corpus.jsonl" port))
               (check "HTTP GET /corpus.jsonl -> 200 + article lines"
                      (and (= 200 status)
                           (search "art_1" (if (stringp body) body
                                              (babel:octets-to-string body :encoding :utf-8))))))
             (multiple-value-bind (body status)
                 (drakma:http-request (format nil "http://127.0.0.1:~D/robots.txt" port))
               (declare (ignore body))
               (check "HTTP GET /robots.txt -> 200" (= 200 status)))))
      (funcall (find-symbol "STOP-SERVER" :orchestrator.http) srv))))

(format t "~%========================================~%")
;;; [0088 Φ5] TEMP honesty lock: αποτυχία as-of ⇒ typed as-of-unavailable —
;;; ΠΟΤΕ σιωπηλά το τρέχον έγγραφο μεταμφιεσμένο σε ιστορικό.
(check "[0088] document-at με provider που αποτυγχάνει στο as-of ⇒ AS-OF-UNAVAILABLE (όχι το τρέχον)"
       (let ((svc (make-corpus-service
                   (lambda (&optional as-of)
                     (if as-of (error "no history") :current-doc)))))
         (and (eq :current-doc (document-at svc))
              (handler-case (progn (document-at svc "1990-01-01") nil)
                (as-of-unavailable (e) (equal "1990-01-01" (as-of-date e)))))))

;;; [0088 Φ5β] /as-known — το διτεμπορικό boundary contract του service
(format t "~%== [0088 Φ5β] /as-known ==~%")
(let* ((doc (build-doc))
       (provider (lambda (article valid known)
                   (declare (ignorable known))
                   (cond ((string= article "16")
                          (if (string< valid "2019-11-25")
                              (error 'as-known-uncertain :why "revision gap 1986/2001/2008")
                              (list :text "Κείμενο 16." :heading "Παιδεία"
                                    :valid-from "2019-11-25" :valid-until :open
                                    :assurance :extracted-verified :basis :complete)))
                         ((string= article "999")
                          (error 'as-known-unknown :why "no such provision"))
                         (t (list :text nil :basis :no-coverage)))))
       (svc (make-corpus-service (lambda () doc) :as-known-provider provider))
       (h (service-handler svc))
       (svc-bare (make-corpus-service (lambda () doc)))
       (h-bare (service-handler svc-bare)))
  (check "/as-known χωρίς provider ⇒ 501 ΔΗΛΩΜΕΝΟ (όχι σιωπηλό 404)"
         (= 501 (rstatus (funcall h-bare (req "/as-known?article=16&valid=2020-01-01&known=2026-01-01T00:00:00Z")))))
  (check "/as-known χωρίς παραμέτρους ⇒ 400 με οδηγία"
         (let ((r (funcall h (req "/as-known"))))
           (and (= 400 (rstatus r)) (search "article" (rbody r)))))
  (let ((r (funcall h (req "/as-known?article=16&valid=2020-01-01&known=2026-01-01T00:00:00Z"))))
    (check "/as-known πλήρης τομή ⇒ 200 με text/basis/valid_from"
           (and (= 200 (rstatus r))
                (search "\"basis\":\"complete\"" (rbody r))
                (search "\"valid_from\":\"2019-11-25\"" (rbody r))
                (search "Κείμενο 16." (rbody r)))))
  (let ((r (funcall h (req "/as-known?article=16&valid=1990-01-01&known=2026-01-01T00:00:00Z"))))
    (check "/as-known σε κενό γνώσης ⇒ 422 ΡΗΤΗ αβεβαιότητα — ΠΟΤΕ το σημερινό κείμενο"
           (and (= 422 (rstatus r))
                (search "temporal uncertainty" (rbody r))
                (not (search "Κείμενο 16." (rbody r))))))
  (check "/as-known άγνωστη διάταξη ⇒ 404 typed"
         (= 404 (rstatus (funcall h (req "/as-known?article=999&valid=2020-01-01&known=2026-01-01T00:00:00Z")))))
  (check "/as-known χωρίς κάλυψη ⇒ 404 τίμιο κενό (όχι 200 με null)"
         (= 404 (rstatus (funcall h (req "/as-known?article=2&valid=1800-01-01&known=2026-01-01T00:00:00Z")))))
  (check "discovery διαφημίζει το as_known endpoint"
         (search "\"as_known\":" (ai-discovery-json svc))))

(format t "Corpus service tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
