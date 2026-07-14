;;;; source/corpus-service.lisp
;;;; ============================================================================
;;;; AI-FIRST CORPUS SERVICE  (CLOS + MOP content negotiation)
;;;; ============================================================================
;;;;
;;;; The consumption endpoint: an AI-first HTTP service that serves the
;;;; consolidated corpus in whatever machine-readable representation a client
;;;; asks for. It is AI-first by design:
;;;;   - default representation is structured data (JSONL / DCAT), never HTML;
;;;;   - permissive CORS + welcoming robots.txt for AI crawlers (GPTBot,
;;;;     ClaudeBot, Google-Extended, ...);
;;;;   - a /.well-known/ai-corpus.json discovery document;
;;;;   - Vary: Accept + Link rel="describedby" to the catalog.
;;;;
;;;; CLOS / MOP showcase: each output format is a REPRESENTATION class whose
;;;; media type is declared on a custom metaclass (REPRESENTATION-CLASS). The
;;;; content-negotiation table is built by reflecting over the representation
;;;; subclasses via the MOP (class-direct-subclasses), and serialization is a
;;;; generic function specialised per representation. Adding a new format is a
;;;; single defclass + defmethod — no negotiation code changes.
;;;; ============================================================================

(defpackage :orchestrator.corpus-service
  (:use :cl)
  (:export
   #:corpus-service #:make-corpus-service #:service-handler
   #:representation #:serialize #:representation-media-type
   #:available-representations #:negotiate
   #:multi-corpus-service #:make-multi-corpus-service #:multi-service-handler
   ;; [0088 Φ5β] /as-known — διτεμπορικό boundary contract του service
   #:as-known-uncertain #:as-known-unknown #:as-known-bad-request #:as-known-why
   ;; as-of ιστορική ανασυγκρότηση — το boundary contract του /diff & providers
   #:as-of-unavailable #:as-of-date #:as-of-cause
   ;; [0088 Φ5-κριτής Μ] typed corpus runtime — ΜΙΑ εγγραφή ανά σώμα
   #:corpus-runtime #:make-corpus-runtime #:corpus-runtime-p
   #:cr-name #:cr-corpus-id #:cr-doc-provider #:cr-as-known-provider))

(in-package :orchestrator.corpus-service)

;;; ============================================================================
;;; MOP: representation metaclass
;;; ============================================================================

(defclass representation-class (standard-class)
  ((media-type :initarg :media-type :initform nil :accessor class-media-type))
  (:documentation "Metaclass for output representations; carries the media type."))

(defmethod closer-mop:validate-superclass
    ((class representation-class) (super standard-class))
  t)
(defmethod closer-mop:validate-superclass
    ((class standard-class) (super representation-class))
  t)

(defclass representation () ()
  (:metaclass representation-class)
  (:documentation "Abstract base for all corpus output representations."))

(defgeneric serialize (representation document &optional base-uri)
  (:documentation "Serialize DOCUMENT in REPRESENTATION, returning a string.
   BASE-URI scopes any emitted resource URIs (per corpus)."))

(defun representation-media-type (rep)
  (class-media-type (class-of rep)))

(defparameter *fallback-base-uri* "https://stavropouloslaw.com/eli")

(defmacro define-representation (name media-type (doc-var &optional (base-var (gensym "BASE")))
                                 &body body)
  "Define a representation NAME with MEDIA-TYPE (set on its metaclass) and the
   SERIALIZE method body over DOC-VAR (and optional BASE-VAR for the per-corpus
   base URI). Negotiation discovers it automatically via the MOP."
  `(progn
     (defclass ,name (representation) () (:metaclass representation-class))
     (setf (class-media-type (find-class ',name)) ,media-type)
     (defmethod serialize ((r ,name) ,doc-var &optional ,base-var)
       (declare (ignorable ,base-var))
       ,@body)
     ',name))

;;; --- concrete representations (declarative; one form each) ------------------

(define-representation akn-representation "application/akn+xml" (doc)
  (funcall (find-symbol "EMIT-AKOMA-NTOSO" :orchestrator.akoma-ntoso) doc))

(define-representation turtle-representation "text/turtle" (doc)
  (funcall (find-symbol "RENDER-CONSOLIDATION-PROVENANCE-TTL" :orchestrator.consolidation) doc))

(define-representation jsonl-representation "application/jsonl" (doc base)
  (funcall (find-symbol "EMIT-CORPUS-JSONL" :orchestrator.ai-dump) doc
           :base-uri (or base *fallback-base-uri*)))

(define-representation catalog-representation "application/ld+json" (doc base)
  (funcall (find-symbol "EMIT-CORPUS-CATALOG" :orchestrator.ai-dump) doc
           :base-uri (or base *fallback-base-uri*)))

(define-representation text-representation "text/plain" (doc)
  (funcall (find-symbol "RENDER-CONSOLIDATED-TEXT" :orchestrator.consolidation) doc))

;;; ============================================================================
;;; CONTENT NEGOTIATION (driven by the MOP)
;;; ============================================================================

(defun available-representations ()
  "All concrete representation classes, discovered via the MOP."
  (closer-mop:class-direct-subclasses (find-class 'representation)))

(defun representation-by-media-type (media-type)
  (loop for class in (available-representations)
        when (equal (class-media-type class) media-type)
        return (make-instance class)))

(defparameter *default-representation* 'jsonl-representation
  "AI-first default: bulk machine-readable data when the client is indifferent.")

(defun %parse-q-value (string)
  "Parse an HTTP quality value (a decimal 0..1) from STRING using a STRICT
   numeric scanner — NEVER the Lisp reader. STRING is attacker-controlled
   (the `q=` fragment of a request Accept header); routing it through
   READ-FROM-STRING with *READ-EVAL* on is remote code execution via the
   `#.` reader macro. This consumes only [0-9.], clamps to [0,1], and
   defaults to 1.0 on anything malformed."
  (let ((end 0) (n (length string)) (seen-dot nil) (seen-digit nil))
    (loop while (< end n)
          for ch = (char string end)
          do (cond ((digit-char-p ch) (setf seen-digit t) (incf end))
                   ((and (char= ch #\.) (not seen-dot)) (setf seen-dot t) (incf end))
                   (t (return))))
    (if seen-digit
        ;; digits-and-one-dot only: fold to a rational by hand, no reader at all.
        (let ((int 0) (frac 0) (scale 1) (after-dot nil))
          (loop for i from 0 below end
                for ch = (char string i)
                do (cond ((char= ch #\.) (setf after-dot t))
                         (after-dot (setf frac (+ (* frac 10) (digit-char-p ch))
                                          scale (* scale 10)))
                         (t (setf int (+ (* int 10) (digit-char-p ch))))))
          (max 0.0 (min 1.0 (float (+ int (/ frac scale)) 1.0))))
        1.0)))

(defun parse-accept (accept-header)
  "Return a list of (media-type . q) from an Accept header, best first."
  (when (and accept-header (plusp (length accept-header)))
    (let ((entries
            (loop for part in (uiop:split-string accept-header :separator '(#\,))
                  for trimmed = (string-trim " " part)
                  when (plusp (length trimmed))
                  collect (let* ((semi (position #\; trimmed))
                                 (mt (string-trim " " (subseq trimmed 0 semi)))
                                 (q (if semi
                                        (let ((qp (search "q=" trimmed :start2 semi)))
                                          (if qp
                                              (%parse-q-value
                                               (string-trim " " (subseq trimmed (+ qp 2))))
                                              1.0))
                                        1.0)))
                            (cons mt q)))))
      (stable-sort entries #'> :key #'cdr))))

(defun negotiate (accept-header)
  "Pick a representation instance for ACCEPT-HEADER. Specific matches win;
   */* or absent falls back to the AI-first default."
  (or (loop for entry in (parse-accept accept-header)
            for mt = (car entry)
            thereis (if (or (string= mt "*/*") (string= mt "application/*"))
                        (make-instance *default-representation*)
                        (representation-by-media-type mt)))
      ;; nothing matched / no Accept -> default
      (make-instance *default-representation*)))

;;; ============================================================================
;;; SERVICE
;;; ============================================================================

(defclass corpus-service ()
  ((doc-provider :initarg :doc-provider :accessor service-doc-provider
                 :documentation "Thunk returning the current consolidated legal-document.")
   (as-known-provider :initarg :as-known-provider :initform nil
                      :accessor service-as-known-provider
                      :documentation "[0088 Φ5β] fn (article-label valid-at known-at)
                       → plist (:text :heading :valid-from :valid-until :assurance
                       :basis) ή σηματοδοτεί as-known-uncertain/as-known-unknown.
                       NIL ⇒ το /as-known απαντά 501 ΔΗΛΩΜΕΝΑ (όχι σιωπηλό 404).")
   (base-uri :initarg :base-uri :initform "https://stavropouloslaw.com/eli"
             :accessor service-base-uri))
  (:documentation "An AI-first HTTP service over the consolidated corpus."))

(defun make-corpus-service (doc-provider &key (base-uri "https://stavropouloslaw.com/eli")
                                              as-known-provider)
  "DOC-PROVIDER is a function of no args returning the current legal-document."
  (make-instance 'corpus-service
                 :doc-provider (if (functionp doc-provider) doc-provider
                                   (lambda () doc-provider))
                 :as-known-provider as-known-provider
                 :base-uri base-uri))

;;; [0088 Φ5β] Το boundary contract του /as-known: ο provider (καλωδιωμένος στο
;;; cli πάνω στην έδρα text-as-known) μεταφράζει τις συνθήκες του γράφου σε
;;; ΑΥΤΕΣ τις typed συνθήκες — το service δεν γνωρίζει τον γράφο, γνωρίζει το
;;; συμβόλαιο. Καμία αβεβαιότητα δεν σερβίρεται ως κείμενο.
(define-condition as-known-uncertain (error)
  ((why :initarg :why :initform nil :reader as-known-why))
  (:report (lambda (c s) (format s "temporal uncertainty: ~A" (as-known-why c)))))
(define-condition as-known-unknown (error)
  ((why :initarg :why :initform nil :reader as-known-why))
  (:report (lambda (c s) (format s "unknown provision: ~A" (as-known-why c)))))
(define-condition as-known-bad-request (error)
  ((why :initarg :why :initform nil :reader as-known-why))
  (:report (lambda (c s) (format s "invalid temporal parameters: ~A" (as-known-why c)))))

(define-condition as-of-unavailable (error)
  ((date :initarg :date :reader as-of-date)
   (cause :initarg :cause :reader as-of-cause))
  (:report (lambda (c s)
             (format s "Αδύνατη η ιστορική ανασυγκρότηση για ~A: ~A"
                     (as-of-date c) (as-of-cause c)))))

(defun document-at (service &optional as-of)
  "The consolidated document, optionally as it stood on AS-OF (ISO date).
   [0088 Φ5 — TEMP honesty]: η ΑΠΟΤΥΧΙΑ ιστορικής ανασυγκρότησης είναι ΕΥΘΥΝΗ
   ΤΟΥ PROVIDER να τη σηματοδοτήσει ως AS-OF-UNAVAILABLE — ΠΟΤΕ σιωπηλά το
   τρέχον κείμενο ως ιστορικό. [κριτής Β 3.1]: το document-at ΔΕΝ τυλίγει πια
   ΚΑΘΕ error σε as-of-unavailable — ένα προγραμματιστικό bug (NIL-funcall)
   ΔΕΝ είναι «άγνοια»· ανεβαίνει ως 500. Bug ≠ τίμια άγνοια."
  (let ((p (service-doc-provider service)))
    (if as-of (funcall p as-of) (funcall p))))

(defun current-document (service) (document-at service))

(defparameter +ai-robots+
  "# AI systems are welcome to crawl and learn from this corpus.
User-agent: GPTBot
Allow: /
User-agent: ClaudeBot
Allow: /
User-agent: Google-Extended
Allow: /
User-agent: CCBot
Allow: /
User-agent: PerplexityBot
Allow: /
User-agent: *
Allow: /
")

(defun ai-discovery-json (service)
  (let ((base (service-base-uri service)))
    (format nil "{~%  \"name\": \"Greek Legal Corpus\",~%  \"description\": \"Consolidated, in-force Greek legislation as machine-readable Linked Data (Akoma Ntoso, RDF/Turtle, JSON-LD, JSONL).\",~%  \"ai_first\": true,~%  \"catalog\": \"~A/catalog.jsonld\",~%  \"bulk\": \"~A/corpus.jsonl\",~%  \"formats\": [\"application/akn+xml\", \"text/turtle\", \"application/ld+json\", \"application/jsonl\", \"text/plain\"],~%  \"endpoints\": {~%    \"article\": \"~A/article/{eId}\",~%    \"search\": \"~A/search?q={greek terms}\",~%    \"sparql\": \"~A/sparql?query={SPARQL SELECT}\",~%    \"diff\": \"~A/diff?from={date}&to={date}\",~%    \"as_known\": \"~A/as-known?article={label}&valid={date}&known={datetime}\",~%    \"dataset\": \"~A/dataset\",~%    \"dataset_jsonl\": \"~A/dataset.jsonl\",~%    \"provenance\": \"~A/provenance\",~%    \"eu_references\": \"~A/eu-references\"~%  },~%  \"content_negotiation\": \"Send an Accept header on / to choose a representation.\"~%}~%"
            base base base base base base base base base base base)))

(defun ai-headers (service)
  "Common AI-first response headers."
  (list (cons "Access-Control-Allow-Origin" "*")
        (cons "X-Robots-Tag" "all")
        (cons "Vary" "Accept")
        (cons "Link" (format nil "<~A/catalog.jsonld>; rel=\"describedby\""
                             (service-base-uri service)))))

(defun ok (body content-type service)
  (apply (find-symbol "MAKE-HTTP-RESPONSE" :orchestrator.http)
         :status 200 :body body
         :headers (cons (cons "Content-Type" content-type) (ai-headers service))
         nil))

(defun find-article-json (jsonl eid)
  "Return the JSONL line whose eId equals EID, or NIL."
  (loop for line in (uiop:split-string jsonl :separator '(#\Newline))
        when (search (format nil "\"eId\":\"~A\"" eid) line)
        return line))

(defun service-handler (service)
  "Return an orchestrator.http handler closure for SERVICE."
  (lambda (req)
    (let* ((http (find-package :orchestrator.http))
           (path (funcall (find-symbol "HTTP-REQUEST-PATH" http) req))
           (method (funcall (find-symbol "HTTP-REQUEST-METHOD" http) req))
           (accept (funcall (find-symbol "HTTP-REQUEST-HEADER" http) req "accept"))
           (base (service-base-uri service))
           ;; [Κ1 route-first]: ΚΑΜΙΑ φόρτωση του consolidated document πριν
           ;; αναγνωριστεί το route — το /as-known (και κάθε route που δεν το
           ;; χρειάζεται) λειτουργεί ακόμη κι αν ο παλιός provider αποτυγχάνει.
           (doc-memo :unset))
      (flet ((doc () (if (eq doc-memo :unset)
                         (setf doc-memo (current-document service))
                         doc-memo))
             (resp (status body ct &rest extra)
               (apply (find-symbol "MAKE-HTTP-RESPONSE" http)
                      :status status :body body
                      :headers (append (list (cons "Content-Type" ct))
                                       (ai-headers service) extra)
                      nil)))
        (cond
          ((not (member method '("GET" "HEAD") :test #'string=))
           (resp 405 "Method Not Allowed" "text/plain"))

          ((string= path "/robots.txt")
           (resp 200 +ai-robots+ "text/plain; charset=utf-8"))

          ((string= path "/.well-known/ai-corpus.json")
           (resp 200 (ai-discovery-json service) "application/json; charset=utf-8"))

          ((or (string= path "/catalog.jsonld") (string= path "/catalog"))
           (resp 200 (serialize (make-instance 'catalog-representation) (doc) base)
                 "application/ld+json; charset=utf-8"))

          ((string= path "/corpus.jsonl")
           (resp 200 (serialize (make-instance 'jsonl-representation) (doc) base)
                 "application/jsonl; charset=utf-8"))

          ((string= path "/consolidated.akn.xml")
           (resp 200 (serialize (make-instance 'akn-representation) (doc) base)
                 "application/akn+xml; charset=utf-8"))

          ((string= path "/consolidated.ttl")
           (resp 200 (serialize (make-instance 'turtle-representation) (doc) base)
                 "text/turtle; charset=utf-8"))

          ((string= path "/consolidated.txt")
           (resp 200 (serialize (make-instance 'text-representation) (doc) base)
                 "text/plain; charset=utf-8"))

          ;; /diff?from=DATE&to=DATE — what changed in the law between two dates
          ((string= path "/diff")
           (let ((from (cdr (assoc "from" (funcall (find-symbol "HTTP-REQUEST-QUERY" http) req) :test #'string=)))
                 (to (cdr (assoc "to" (funcall (find-symbol "HTTP-REQUEST-QUERY" http) req) :test #'string=))))
             (if (and from to (plusp (length from)) (plusp (length to)))
                 (handler-case
                     (resp 200 (funcall (find-symbol "CORPUS-DIFF" :orchestrator.corpus-diff)
                                        (document-at service from) (document-at service to)
                                        from to :base-uri base)
                           "application/json; charset=utf-8")
                   ;; [0088 Φ5] τίμιο 422: η αποτυχία ανασυγκρότησης ΔΗΛΩΝΕΤΑΙ,
                   ;; δεν σερβίρεται το σήμερα μεταμφιεσμένο σε ιστορικό diff
                   (as-of-unavailable (e)
                     (resp 422 (format nil "{\"error\":\"as-of reconstruction unavailable\",\"date\":\"~A\"}"
                                       (as-of-date e))
                           "application/json; charset=utf-8")))
                 (resp 200 "{\"error\":\"missing ?from= and ?to= (ISO dates)\"}"
                       "application/json; charset=utf-8"))))

          ;; [0088 Φ5β] /as-known?article=LABEL&valid=DATE&known=ISO — η
          ;; διτεμπορική ερώτηση: «τι ήξερε το σύστημα κατά known για το άρθρο
          ;; κατά valid;». Αβεβαιότητα ⇒ 422 ΔΗΛΩΜΕΝΗ· άγνωστη διάταξη ⇒ 404·
          ;; χωρίς provider ⇒ 501 ΔΗΛΩΜΕΝΟ — ΠΟΤΕ το τρέχον ως ιστορικό.
          ((string= path "/as-known")
           (let* ((qy (funcall (find-symbol "HTTP-REQUEST-QUERY" http) req))
                  (article (cdr (assoc "article" qy :test #'string=)))
                  (valid (cdr (assoc "valid" qy :test #'string=)))
                  (known (cdr (assoc "known" qy :test #'string=)))
                  (provider (service-as-known-provider service)))
             (cond
               ((null provider)
                (resp 501 "{\"error\":\"as-known unavailable: no bitemporal provider configured for this corpus\"}"
                      "application/json; charset=utf-8"))
               ((not (and article valid known
                          (plusp (length article)) (plusp (length valid))
                          (plusp (length known))))
                (resp 400 "{\"error\":\"missing ?article= &valid= (ISO date) &known= (ISO datetime)\"}"
                      "application/json; charset=utf-8"))
               (t
                ;; [Υ4] JSON ΜΟΝΟ μέσω της ΜΙΑΣ canonical serialization έδρας
                ;; (RFC 8785 JCS) — κανένα χειροποίητο format/~S: εγγυημένο
                ;; escaping για ΚΑΘΕ control char/quote/backslash, ίδια μορφή
                ;; με κάθε άλλο canonical JSON του συστήματος.
                (flet ((cjson (alist)
                         (funcall (find-symbol "CANONICALIZE-JSON"
                                               :orchestrator.canonical-representation)
                                  alist)))
                  (handler-case
                      (let ((r (funcall provider article valid known)))
                        (if (getf r :text)
                            ;; [Φ7 Π5] typed in_force/basis (spec §6): αναστολή/
                            ;; εκκρεμότητα ΔΕΝ μπορεί να παρερμηνευθεί ως ισχύον —
                            ;; το basis είναι πλέον string-kind (το raw :basis
                            ;; μπορεί να είναι cons: ποτέ symbol-name πάνω του).
                            (resp 200 (cjson
                                       (append
                                        (list (cons "article" article)
                                              (cons "assurance" (string-downcase (symbol-name (getf r :assurance))))
                                              (cons "basis" (or (getf r :basis-kind)
                                                                (let ((b (getf r :basis)))
                                                                  (if (symbolp b)
                                                                      (string-downcase (symbol-name b))
                                                                      "complete"))))
                                              (cons "heading" (or (getf r :heading) :null))
                                              (cons "in_force" (if (getf r :in-force) t :false))
                                              (cons "known_at" known)
                                              (cons "text" (getf r :text))
                                              (cons "valid_at" valid)
                                              (cons "valid_from" (getf r :valid-from))
                                              (cons "valid_until" (let ((vu (getf r :valid-until)))
                                                                    (if (stringp vu) vu :null))))
                                        (let ((p (getf r :pending)))
                                          (when p
                                            (list (cons "pending_condition"
                                                        (list (cons "condition_id" (getf p :condition-id))
                                                              (cons "since" (getf p :since)))))))
                                        (let ((sb (getf r :suspended-by)))
                                          (when sb (list (cons "suspended_by" sb))))))
                                  "application/json; charset=utf-8")
                            ;; τίμιο κενό: καμία έκδοση δεν καλύπτει την τομή
                            (resp 404 (cjson
                                       (append
                                        (list (cons "basis" (or (getf r :basis-kind)
                                                                (let ((b (getf r :basis)))
                                                                  (if (symbolp b)
                                                                      (string-downcase (symbol-name (or b :none)))
                                                                      "no-version-in-force"))))
                                              (cons "error" "no version covers the requested cut")
                                              (cons "in_force" :false))
                                        (let ((p (getf r :pending)))
                                          (when p
                                            (list (cons "pending_condition"
                                                        (list (cons "condition_id" (getf p :condition-id))
                                                              (cons "since" (getf p :since)))))))))
                                  "application/json; charset=utf-8")))
                    (as-known-bad-request (e)
                      (resp 400 (cjson (list (cons "error" "invalid temporal parameters")
                                             (cons "why" (format nil "~A" (or (as-known-why e) "")))))
                            "application/json; charset=utf-8"))
                    (as-known-uncertain (e)
                      (resp 422 (cjson (list (cons "error" "temporal uncertainty — declared, not guessed")
                                             (cons "why" (format nil "~A" (or (as-known-why e) "")))))
                            "application/json; charset=utf-8"))
                    (as-known-unknown (e)
                      (resp 404 (cjson (list (cons "error" "unknown provision")
                                             (cons "why" (format nil "~A" (or (as-known-why e) "")))))
                            "application/json; charset=utf-8"))))))))

          ;; /search?q=...  — Greek full-text search over the corpus
          ((string= path "/search")
           (let ((qq (cdr (assoc "q" (funcall (find-symbol "HTTP-REQUEST-QUERY" http) req)
                                 :test #'string=))))
             (if (and qq (plusp (length qq)))
                 (resp 200 (funcall (find-symbol "SEARCH-CORPUS" :orchestrator.corpus-search)
                                    (doc) qq :base-uri base)
                       "application/json; charset=utf-8")
                 (resp 200 "{\"error\":\"missing ?q= (search terms)\"}"
                       "application/json; charset=utf-8"))))

          ;; /sparql?query=...  — live SPARQL over the consolidated corpus
          ((string= path "/sparql")
           (let ((q (cdr (assoc "query" (funcall (find-symbol "HTTP-REQUEST-QUERY" http) req)
                                :test #'string=))))
             (if (and q (plusp (length q)))
                 (resp 200 (funcall (find-symbol "SPARQL-QUERY" :orchestrator.corpus-sparql)
                                    (doc) base q)
                       "application/sparql-results+json; charset=utf-8")
                 (resp 200 "{\"error\":\"missing ?query= (SPARQL SELECT)\"}"
                       "application/json; charset=utf-8"))))

          ;; /dataset[.jsonl|.ttl] and /dataset/{train|validation|test}.jsonl
          ;; — the AI-first training dataset: a deterministic HuggingFace export
          ;;   computed from the real consolidated corpus.
          ((or (string= path "/dataset") (string= path "/dataset.json")
               (string= path "/dataset.jsonl") (string= path "/dataset.ttl")
               (and (>= (length path) 9) (string= (subseq path 0 9) "/dataset/")))
           (let ((mfst (funcall (find-symbol "BUILD-CORPUS-MANIFEST" :orchestrator.ai-ingest)
                                (doc) :base-uri base)))
             (cond
               ((string= path "/dataset.jsonl")
                (resp 200 (funcall (find-symbol "DATASET-JSONL-STRING" :orchestrator.ai-ingest)
                                   mfst :split :all)
                      "application/jsonl; charset=utf-8"))
               ((string= path "/dataset.ttl")
                (resp 200 (funcall (find-symbol "SERIALIZE-MANIFEST-RDF" :orchestrator.ai-ingest)
                                   mfst)
                      "text/turtle; charset=utf-8"))
               ((and (>= (length path) 9) (string= (subseq path 0 9) "/dataset/"))
                (let* ((tail (subseq path 9))
                       (split (cond ((string= tail "train.jsonl") :train)
                                    ((string= tail "validation.jsonl") :validation)
                                    ((string= tail "test.jsonl") :test)
                                    (t nil))))
                  (if split
                      (resp 200 (funcall (find-symbol "DATASET-JSONL-STRING" :orchestrator.ai-ingest)
                                         mfst :split split)
                            "application/jsonl; charset=utf-8")
                      (resp 404 "{\"error\":\"unknown split (use train|validation|test.jsonl)\"}"
                            "application/json; charset=utf-8"))))
               (t
                (resp 200 (funcall (find-symbol "MANIFEST->JSON-STRING" :orchestrator.ai-ingest)
                                   mfst)
                      "application/json; charset=utf-8")))))

          ;; /provenance[.ttl|.jsonld|.xml] — W3C PROV-O of how each article came
          ;; to read the way it does, built from the real amendment provenance.
          ((or (string= path "/provenance") (string= path "/provenance.ttl")
               (string= path "/provenance.jsonld") (string= path "/provenance.xml"))
           (let* ((fmt (cond ((string= path "/provenance.jsonld") :json-ld)
                             ((string= path "/provenance.xml") :xml)
                             (t :turtle)))
                  (ct (ecase fmt
                        (:turtle "text/turtle; charset=utf-8")
                        (:json-ld "application/ld+json; charset=utf-8")
                        (:xml "application/xml; charset=utf-8"))))
             (resp 200 (funcall (find-symbol "CORPUS-PROVENANCE" :orchestrator.corpus-provenance)
                                (doc) :base-uri base :format fmt)
                   ct)))

          ;; /eu-references — link each article to the EU law it cites,
          ;; via official CELEX / ELI / EUR-Lex identifiers.
          ((or (string= path "/eu-references") (string= path "/eu-links"))
           (resp 200 (funcall (find-symbol "CORPUS-EU-REFERENCES" :orchestrator.corpus-eu-links)
                              (doc) :base-uri base)
                 "application/json; charset=utf-8"))

          ;; /article/{eId}
          ((and (>= (length path) 9) (string= (subseq path 0 9) "/article/"))
           (let* ((eid (subseq path 9))
                  (line (find-article-json
                         (serialize (make-instance 'jsonl-representation) (doc) base) eid)))
             (if line
                 (resp 200 line "application/json; charset=utf-8")
                 (resp 404 (format nil "{\"error\":\"article not found\",\"eId\":\"~A\"}" eid)
                       "application/json; charset=utf-8"))))

          ;; root: content negotiation (AI-first default)
          ((or (string= path "/") (string= path ""))
           (let ((rep (negotiate accept)))
             (resp 200 (serialize rep (doc) base)
                   (format nil "~A; charset=utf-8" (representation-media-type rep)))))

          (t (resp 404 "{\"error\":\"not found\"}" "application/json; charset=utf-8")))))))

;;; ============================================================================
;;; MULTI-CORPUS SERVICE  (serve every κώδικας under its own path prefix)
;;; ============================================================================
;;;
;;; One endpoint that fronts several corpora, each isolated under /{corpus}/...:
;;;   GET /                          top index (all corpora)
;;;   GET /catalog.jsonld            DCAT Catalog of all corpora
;;;   GET /robots.txt                AI-welcoming (global)
;;;   GET /.well-known/ai-corpus.json discovery listing every corpus
;;;   GET /{corpus}/...              delegated to that corpus's service
;;;     e.g. /poinikos/corpus.jsonl , /constitution/article/art_5 ,
;;;          /poinikos/ (content-negotiated)

(defclass multi-corpus-service ()
  ((services :initarg :services :accessor multi-services)   ; alist (name . corpus-service)
   (base-uri :initarg :base-uri :accessor multi-base-uri)))

;;; [0088 Φ5-κριτής Μ] Η ΜΙΑ typed περιγραφή ενός σερβιριζόμενου σώματος —
;;; identity + providers δεμένα σε ΜΙΑ εγγραφή κατά την κατασκευή (καμία
;;; δεύτερη παράλληλη alist που ξανασυνδέεται με assoc — drift αδύνατο).
(defstruct (corpus-runtime (:conc-name cr-))
  name              ; δημόσιο short name (URL prefix) — string, μοναδικό
  corpus-id         ; εσωτερικό corpus id (config registry) — string
  doc-provider      ; fn (&optional as-of) → legal-document
  as-known-provider); fn (article valid known) → plist | NIL (μόνο migration profile)

(defun make-multi-corpus-service (runtimes &key (base-uri "https://stavropouloslaw.com/eli"))
  "RUNTIMES: λίστα corpus-runtime — Η typed αλήθεια κάθε σώματος (όνομα,
   ταυτότητα, providers) σε ΜΙΑ εγγραφή. Uniqueness gate στα ονόματα:
   διπλό short name = ΣΦΑΛΜΑ κατασκευής, όχι σιωπηλή σκίαση route."
  (let ((names (mapcar #'cr-name runtimes)))
    (unless (= (length names) (length (remove-duplicates names :test #'equal)))
      (error "multi-corpus-service: διπλά short names ~S — η ταυτότητα route δεν επιτρέπεται να σκιάζεται"
             names)))
  (make-instance 'multi-corpus-service
                 :base-uri base-uri
                 :services (mapcar (lambda (rt)
                                     (cons (cr-name rt)
                                           (make-corpus-service
                                            (cr-doc-provider rt)
                                            :base-uri (format nil "~A/~A" base-uri (cr-name rt))
                                            :as-known-provider (cr-as-known-provider rt))))
                                   runtimes)))

(defun %split-corpus-path (path)
  "For \"/corpus/rest...\" return (values corpus rest-path). REST-PATH starts
   with '/' (or is \"/\" when absent)."
  (let* ((p (if (and (plusp (length path)) (char= (char path 0) #\/))
                (subseq path 1) path))
         (slash (position #\/ p)))
    (if slash
        (values (subseq p 0 slash)
                (let ((r (subseq p slash))) (if (string= r "") "/" r)))
        (values p "/"))))

(defun %json-list (items render)
  (with-output-to-string (s)
    (write-string "[" s)
    (loop for it in items for firstp = t then nil
          do (unless firstp (write-string "," s))
             (write-string (funcall render it) s))
    (write-string "]" s)))

(defun multi-top-catalog (multi)
  "A DCAT Catalog (JSON-LD) listing every corpus as a dcat:dataset."
  (let ((base (multi-base-uri multi)))
    (format nil "{~%  \"@context\": {\"dcat\": \"http://www.w3.org/ns/dcat#\", \"dct\": \"http://purl.org/dc/terms/\"},~%  \"@type\": \"dcat:Catalog\",~%  \"@id\": ~S,~%  \"dct:title\": \"Greek Legal Codes\",~%  \"dcat:dataset\": ~A~%}~%"
            (format nil "~A/catalog.jsonld" base)
            (%json-list (multi-services multi)
                        (lambda (pair)
                          (format nil "{\"@type\": \"dcat:Catalog\", \"dct:identifier\": ~S, \"dcat:landingPage\": ~S, \"catalog\": ~S, \"bulk\": ~S}"
                                  (car pair)
                                  (format nil "~A/~A/" base (car pair))
                                  (format nil "~A/~A/catalog.jsonld" base (car pair))
                                  (format nil "~A/~A/corpus.jsonl" base (car pair))))))))

(defun multi-discovery-json (multi)
  (let ((base (multi-base-uri multi)))
    (format nil "{~%  \"name\": \"Greek Legal Codes\",~%  \"ai_first\": true,~%  \"catalog\": ~S,~%  \"corpora\": ~A~%}~%"
            (format nil "~A/catalog.jsonld" base)
            (%json-list (multi-services multi)
                        (lambda (pair) (format nil "~S" (car pair)))))))

(defun multi-service-handler (multi)
  "Return an orchestrator.http handler that fronts every corpus in MULTI."
  (let ((http (find-package :orchestrator.http))
        (handlers (mapcar (lambda (pair) (cons (car pair) (service-handler (cdr pair))))
                          (multi-services multi))))
    (flet ((mk-resp (status body ct)
             (funcall (find-symbol "MAKE-HTTP-RESPONSE" http)
                      :status status :body body
                      :headers (cons (cons "Content-Type" ct) (ai-headers
                                       (make-instance 'corpus-service
                                                      :doc-provider (lambda () nil)
                                                      :base-uri (multi-base-uri multi)))))))
      (lambda (req)
        (let* ((path (funcall (find-symbol "HTTP-REQUEST-PATH" http) req))
               (method (funcall (find-symbol "HTTP-REQUEST-METHOD" http) req)))
          (cond
            ((not (member method '("GET" "HEAD") :test #'string=))
             (mk-resp 405 "Method Not Allowed" "text/plain"))
            ((or (string= path "/") (string= path ""))
             (mk-resp 200 (multi-top-catalog multi) "application/ld+json; charset=utf-8"))
            ((string= path "/catalog.jsonld")
             (mk-resp 200 (multi-top-catalog multi) "application/ld+json; charset=utf-8"))
            ((string= path "/robots.txt")
             (mk-resp 200 +ai-robots+ "text/plain; charset=utf-8"))
            ((string= path "/.well-known/ai-corpus.json")
             (mk-resp 200 (multi-discovery-json multi) "application/json; charset=utf-8"))
            (t
             (multiple-value-bind (corpus rest) (%split-corpus-path path)
               (let ((h (cdr (assoc corpus handlers :test #'string=))))
                 (if h
                     ;; delegate with the corpus prefix stripped
                     (funcall h (funcall (find-symbol "MAKE-HTTP-REQUEST" http)
                                         :method method :path rest
                                         :query (funcall (find-symbol "HTTP-REQUEST-QUERY" http) req)
                                         :headers (funcall (find-symbol "HTTP-REQUEST-HEADERS" http) req)))
                     (mk-resp 404 (format nil "{\"error\":\"unknown corpus\",\"corpus\":~S}" corpus)
                              "application/json; charset=utf-8")))))))))))
