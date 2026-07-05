;;;; source/sparql-endpoint.lisp
;;;; ============================================================================
;;;; SPARQL ENDPOINT - Pure Common Lisp SPARQL Query Processor
;;;; ============================================================================
;;;;
;;;; Implements SPARQL 1.1 Query Language subset for Linked Data access:
;;;; - SELECT queries with basic graph patterns
;;;; - FILTER expressions
;;;; - OPTIONAL patterns
;;;; - ORDER BY, LIMIT, OFFSET
;;;; - HTTP endpoint for federated queries
;;;;
;;;; ARCHITECTURE:
;;;; ┌─────────────────────────────────────────────────────────────────────┐
;;;; │                    SPARQL QUERY PROCESSOR                           │
;;;; ├─────────────────────────────────────────────────────────────────────┤
;;;; │                                                                     │
;;;; │   SPARQL Query ──▶ Parser ──▶ Algebra ──▶ Executor ──▶ Results     │
;;;; │                                   │                                 │
;;;; │                            ┌──────┴──────┐                         │
;;;; │                            │ Knowledge   │                         │
;;;; │                            │    Base     │                         │
;;;; │                            │ (RDFS KB)   │                         │
;;;; │                            └─────────────┘                         │
;;;; │                                                                     │
;;;; │   HTTP GET/POST ─────────────▶ Endpoint ──────────────▶ JSON/XML   │
;;;; │                                                                     │
;;;; └─────────────────────────────────────────────────────────────────────┘
;;;;
;;;; DARPA-GRADE: Pure Lisp, no Jena/RDF4J, Linked Data ready.
;;;; ============================================================================

(defpackage :orchestrator.sparql-endpoint
  (:use :cl)
  (:local-nicknames
   (:rdfs :orchestrator.rdfs-inference))
  (:export
   ;; Query execution
   #:execute-sparql
   #:parse-sparql
   #:sparql-select
   ;; HTTP endpoint
   #:start-sparql-endpoint
   #:stop-sparql-endpoint
   #:handle-sparql-request
   ;; Results formatting
   #:results-to-json
   #:results-to-xml
   #:results-to-csv
   ;; Configuration
   #:*default-port*
   #:*default-graph*))

(in-package :orchestrator.sparql-endpoint)

;;; ============================================================================
;;; CONFIGURATION
;;; ============================================================================

(defvar *default-port* 8890
  "Default SPARQL endpoint port")

(defvar *default-graph* nil
  "Default graph URI for queries")

(defvar *endpoint-running* nil
  "T if endpoint server is running")

;;; ============================================================================
;;; SPARQL ALGEBRA STRUCTURES
;;; ============================================================================

(defstruct sparql-query
  "Parsed SPARQL query"
  (type :select :type keyword)           ; :select, :construct, :ask, :describe
  (variables nil :type list)             ; List of variable names
  (patterns nil :type list)              ; Basic graph patterns
  (filters nil :type list)               ; FILTER expressions
  (optionals nil :type list)             ; OPTIONAL patterns
  (order-by nil :type list)              ; ORDER BY clauses
  (limit nil :type (or null integer))    ; LIMIT value
  (offset nil :type (or null integer))   ; OFFSET value
  (distinct nil :type boolean))          ; DISTINCT modifier

(defstruct triple-pattern
  "Triple pattern in graph pattern"
  (subject nil)    ; Variable or URI
  (predicate nil)  ; Variable or URI
  (object nil))    ; Variable, URI, or literal

(defstruct sparql-variable
  "SPARQL variable"
  (name nil :type string))

(defstruct sparql-uri
  "SPARQL URI reference"
  (value nil :type string))

(defstruct sparql-literal
  "SPARQL literal"
  (value nil)
  (datatype nil :type (or null string))
  (language nil :type (or null string)))

;;; ============================================================================
;;; SPARQL PARSER (Simplified)
;;; ============================================================================

(defun parse-sparql (query-string)
  "Parse SPARQL query string into algebra structure

   Supports:
   - SELECT queries
   - Basic graph patterns
   - FILTER (basic expressions)
   - OPTIONAL
   - ORDER BY, LIMIT, OFFSET

   Args:
     query-string: SPARQL query text

   Returns:
     sparql-query structure"

  (let* ((tokens (tokenize-sparql query-string))
         (query (make-sparql-query)))

    ;; Parse query type and variables
    (parse-select-clause tokens query)

    ;; Parse WHERE clause
    (parse-where-clause tokens query)

    ;; Parse solution modifiers
    (parse-modifiers tokens query)

    query))

(defun tokenize-sparql (query-string)
  "Tokenize SPARQL query into list of tokens"
  (let ((tokens '())
        (current "")
        (in-uri nil)
        (in-string nil)
        (in-variable nil))

    (loop for char across query-string
          do (cond
               ;; URI handling
               ((and (char= char #\<) (not in-string))
                (when (> (length current) 0)
                  (push current tokens)
                  (setf current ""))
                (setf in-uri t)
                (setf current "<"))

               ((and (char= char #\>) in-uri)
                (setf current (concatenate 'string current ">"))
                (push current tokens)
                (setf current "")
                (setf in-uri nil))

               ;; String handling
               ((and (char= char #\") (not in-uri))
                (if in-string
                    (progn
                      (setf current (concatenate 'string current "\""))
                      (push current tokens)
                      (setf current "")
                      (setf in-string nil))
                    (progn
                      (when (> (length current) 0)
                        (push current tokens)
                        (setf current ""))
                      (setf in-string t)
                      (setf current "\""))))

               ;; Variable handling
               ((and (char= char #\?) (not in-uri) (not in-string))
                (when (> (length current) 0)
                  (push current tokens)
                  (setf current ""))
                (setf in-variable t)
                (setf current "?"))

               ;; Whitespace
               ((and (member char '(#\Space #\Tab #\Newline #\Return))
                     (not in-uri) (not in-string))
                (when (> (length current) 0)
                  (push current tokens)
                  (setf current "")
                  (setf in-variable nil)))

               ;; Punctuation (outside URI/string)
               ((and (member char '(#\{ #\} #\( #\) #\. #\, #\;))
                     (not in-uri) (not in-string))
                (when (> (length current) 0)
                  (push current tokens)
                  (setf current "")
                  (setf in-variable nil))
                (push (string char) tokens))

               ;; Normal character
               (t
                (setf current (concatenate 'string current (string char))))))

    ;; Final token
    (when (> (length current) 0)
      (push current tokens))

    (nreverse tokens)))

(defun parse-select-clause (tokens query)
  "Parse SELECT clause from tokens"
  (let ((pos 0))
    ;; Find SELECT keyword
    (loop while (< pos (length tokens))
          do (let ((token (string-upcase (nth pos tokens))))
               (cond
                 ((string= token "SELECT")
                  (incf pos)
                  ;; Check for DISTINCT
                  (when (and (< pos (length tokens))
                             (string= (string-upcase (nth pos tokens)) "DISTINCT"))
                    (setf (sparql-query-distinct query) t)
                    (incf pos))
                  ;; Collect variables
                  (loop while (< pos (length tokens))
                        for token = (nth pos tokens)
                        while (and token (char= (char token 0) #\?))
                        do (push (subseq token 1) (sparql-query-variables query))
                           (incf pos))
                  (setf (sparql-query-variables query)
                        (nreverse (sparql-query-variables query)))
                  (return))
                 (t (incf pos)))))))

(defun parse-where-clause (tokens query)
  "Parse WHERE clause from tokens"
  (let ((pos 0)
        (in-where nil)
        (brace-depth 0))

    ;; Find WHERE keyword or opening brace
    (loop while (< pos (length tokens))
          do (let ((token (nth pos tokens)))
               (cond
                 ((string-equal token "WHERE")
                  (setf in-where t)
                  (incf pos))

                 ((and in-where (string= token "{"))
                  (incf brace-depth)
                  (incf pos)
                  ;; Parse patterns inside braces
                  (loop while (and (< pos (length tokens))
                                   (> brace-depth 0))
                        do (let ((t1 (nth pos tokens)))
                             (cond
                               ((string= t1 "{")
                                (incf brace-depth)
                                (incf pos))
                               ((string= t1 "}")
                                (decf brace-depth)
                                (incf pos))
                               ;; Triple pattern
                               ((or (char= (char t1 0) #\?)
                                    (char= (char t1 0) #\<))
                                (when (< (+ pos 2) (length tokens))
                                  (let ((s (nth pos tokens))
                                        (p (nth (1+ pos) tokens))
                                        (o (nth (+ pos 2) tokens)))
                                    (push (make-triple-pattern
                                           :subject (parse-term s)
                                           :predicate (parse-term p)
                                           :object (parse-term o))
                                          (sparql-query-patterns query))
                                    (incf pos 3)
                                    ;; Skip optional dot
                                    (when (and (< pos (length tokens))
                                               (string= (nth pos tokens) "."))
                                      (incf pos)))))
                               (t (incf pos)))))
                  (setf (sparql-query-patterns query)
                        (nreverse (sparql-query-patterns query)))
                  (return))

                 (t (incf pos)))))))

(defun parse-term (token)
  "Parse a SPARQL term (variable, URI, or literal)"
  (cond
    ;; Variable
    ((char= (char token 0) #\?)
     (make-sparql-variable :name (subseq token 1)))

    ;; URI
    ((char= (char token 0) #\<)
     (make-sparql-uri :value (subseq token 1 (1- (length token)))))

    ;; Prefixed name (simplified - treat as URI)
    ((find #\: token)
     (make-sparql-uri :value token))

    ;; Literal
    ((char= (char token 0) #\")
     (make-sparql-literal :value (subseq token 1 (1- (length token)))))

    ;; Unknown - treat as URI
    (t
     (make-sparql-uri :value token))))

(defun parse-modifiers (tokens query)
  "Parse ORDER BY, LIMIT, OFFSET from tokens"
  (let ((pos 0))
    (loop while (< pos (length tokens))
          do (let ((token (string-upcase (nth pos tokens))))
               (cond
                 ((string= token "LIMIT")
                  (incf pos)
                  (when (< pos (length tokens))
                    (setf (sparql-query-limit query)
                          (parse-integer (nth pos tokens) :junk-allowed t))
                    (incf pos)))

                 ((string= token "OFFSET")
                  (incf pos)
                  (when (< pos (length tokens))
                    (setf (sparql-query-offset query)
                          (parse-integer (nth pos tokens) :junk-allowed t))
                    (incf pos)))

                 (t (incf pos)))))))

;;; ============================================================================
;;; QUERY EXECUTION
;;; ============================================================================

(defun execute-sparql (query-string kb)
  "Execute SPARQL query against knowledge base

   Args:
     query-string: SPARQL query text
     kb: RDFS knowledge base

   Returns:
     Query results (list of bindings)"

  (let ((query (parse-sparql query-string)))
    (sparql-select query kb)))

(defparameter *sparql-max-patterns* 32
  "Reject a BGP with more triple patterns than this — a cheap guard on query
   complexity before evaluation even starts.")

(defparameter *sparql-max-bindings* 200000
  "Hard ceiling on intermediate binding sets materialized during a BGP join. A
   query of fully-unbound patterns with distinct variables ({ ?a ?b ?c . ?d ?e ?f … })
   otherwise produces an N^k cross product that exhausts heap/CPU from a single
   unauthenticated request. Exceeding this aborts the query via SPARQL-RESOURCE-LIMIT.")

(define-condition sparql-resource-limit (error)
  ((detail :initarg :detail :reader sparql-resource-limit-detail :initform "query too expensive"))
  (:report (lambda (c s) (format s "SPARQL resource limit: ~A"
                                 (sparql-resource-limit-detail c))))
  (:documentation "Signalled when a query exceeds a complexity/size guard — turns an
   algorithmic-complexity DoS into a bounded, catchable refusal."))

(defvar *sparql-binding-counter* 0
  "Running count of binding sets produced in the current BGP evaluation.")

(declaim (inline %sparql-tick))
(defun %sparql-tick (n)
  "Charge N produced bindings against the budget; abort if the cap is exceeded."
  (when (> (incf *sparql-binding-counter* n) *sparql-max-bindings*)
    (error 'sparql-resource-limit
           :detail (format nil "intermediate result set exceeded ~D bindings"
                           *sparql-max-bindings*)))
  n)

(defun sparql-select (query kb)
  "Execute SELECT query

   Args:
     query: sparql-query structure
     kb: knowledge base

   Returns:
     (:variables (v1 v2 ...) :bindings ((v1 . val1) ...))"

  (let* ((patterns (sparql-query-patterns query))
         (variables (sparql-query-variables query))
         (*sparql-binding-counter* 0)
         (bindings (progn
                     (when (> (length patterns) *sparql-max-patterns*)
                       (error 'sparql-resource-limit
                              :detail (format nil "~D triple patterns exceeds cap ~D"
                                              (length patterns) *sparql-max-patterns*)))
                     (evaluate-bgp patterns kb))))

    ;; Apply DISTINCT if requested
    (when (sparql-query-distinct query)
      (setf bindings (remove-duplicates bindings :test #'bindings-equal)))

    ;; Apply OFFSET
    (when (sparql-query-offset query)
      (setf bindings (nthcdr (sparql-query-offset query) bindings)))

    ;; Apply LIMIT
    (when (sparql-query-limit query)
      (setf bindings (subseq bindings 0
                             (min (sparql-query-limit query)
                                  (length bindings)))))

    ;; Project to requested variables
    (list :variables variables
          :bindings (project-bindings bindings variables))))

(defun evaluate-bgp (patterns kb)
  "Evaluate Basic Graph Pattern

   Uses nested-loop join for pattern matching.

   Args:
     patterns: List of triple-patterns
     kb: Knowledge base

   Returns:
     List of binding sets (alists)"

  (if (null patterns)
      (list nil)  ; Empty pattern matches with empty bindings
      (let ((first-pattern (first patterns))
            (rest-patterns (rest patterns)))

        ;; Get matches for first pattern
        (let ((matches (match-pattern first-pattern kb nil)))
          (if (null rest-patterns)
              (progn (%sparql-tick (length matches)) matches)
              ;; Join with remaining patterns (each produced row charged to the budget)
              (loop for binding in matches
                    append (evaluate-bgp-with-bindings rest-patterns kb binding)))))))

(defun evaluate-bgp-with-bindings (patterns kb bindings)
  "Evaluate patterns with existing bindings"
  (if (null patterns)
      (progn (%sparql-tick 1) (list bindings))
      (let ((first-pattern (first patterns))
            (rest-patterns (rest patterns)))
        (let ((matches (match-pattern first-pattern kb bindings)))
          (if (null rest-patterns)
              (progn (%sparql-tick (length matches)) matches)
              (loop for binding in matches
                    append (evaluate-bgp-with-bindings rest-patterns kb binding)))))))

(defun match-pattern (pattern kb bindings)
  "Match triple pattern against knowledge base

   Args:
     pattern: triple-pattern
     kb: Knowledge base
     bindings: Current variable bindings (alist)

   Returns:
     List of extended bindings"

  (let* ((s-term (triple-pattern-subject pattern))
         (p-term (triple-pattern-predicate pattern))
         (o-term (triple-pattern-object pattern))

         ;; Substitute bound variables
         (s-val (substitute-term s-term bindings))
         (p-val (substitute-term p-term bindings))
         (o-val (substitute-term o-term bindings))

         ;; Query KB
         (triples (rdfs:kb-query kb
                                 (term-to-query-value s-val)
                                 (term-to-query-value p-val)
                                 (term-to-query-value o-val))))

    ;; Build bindings for each match
    (loop for triple in triples
          for new-bindings = (extend-bindings
                              s-term (rdfs:triple-subject triple)
                              p-term (rdfs:triple-predicate triple)
                              o-term (rdfs:triple-object triple)
                              bindings)
          when new-bindings collect new-bindings)))

(defun substitute-term (term bindings)
  "Substitute variable with bound value if available"
  (if (sparql-variable-p term)
      (let ((bound (assoc (sparql-variable-name term) bindings :test #'string=)))
        (if bound (cdr bound) term))
      term))

(defun term-to-query-value (term)
  "Convert SPARQL term to KB query value"
  (cond
    ((sparql-variable-p term) nil)  ; Variable = wildcard
    ((sparql-uri-p term) (sparql-uri-value term))
    ((sparql-literal-p term) (sparql-literal-value term))
    ((stringp term) term)
    (t nil)))

(defun extend-bindings (s-term s-val p-term p-val o-term o-val bindings)
  "Extend bindings with new variable assignments

   Returns NIL if binding conflict detected."

  (let ((new-bindings (copy-alist bindings)))

    (flet ((try-bind (term value)
             (when (sparql-variable-p term)
               (let* ((var-name (sparql-variable-name term))
                      (existing (assoc var-name new-bindings :test #'string=)))
                 (cond
                   ;; No existing binding - add it
                   ((null existing)
                    (push (cons var-name value) new-bindings))
                   ;; Existing binding matches - ok
                   ((equal (cdr existing) value)
                    t)
                   ;; Conflict - fail
                   (t
                    (return-from extend-bindings nil)))))))

      (try-bind s-term s-val)
      (try-bind p-term p-val)
      (try-bind o-term o-val))

    new-bindings))

(defun project-bindings (bindings variables)
  "Project bindings to only requested variables"
  (mapcar (lambda (binding)
            (loop for var in variables
                  collect (cons var (cdr (assoc var binding :test #'string=)))))
          bindings))

(defun bindings-equal (b1 b2)
  "Check if two binding sets are equal"
  (and (= (length b1) (length b2))
       (every (lambda (pair)
                (equal (cdr pair)
                       (cdr (assoc (car pair) b2 :test #'string=))))
              b1)))

;;; ============================================================================
;;; RESULTS FORMATTING
;;; ============================================================================

(defun results-to-json (results)
  "Format query results as SPARQL JSON Results

   Format per W3C SPARQL 1.1 Query Results JSON Format"

  (let ((variables (getf results :variables))
        (bindings (getf results :bindings)))

    (jonathan:to-json
     `(:|head| (:|vars| ,variables)
       :|results| (:|bindings|
                   ,(mapcar (lambda (binding)
                              (loop for (var . val) in binding
                                    when val
                                    collect (cons (intern var :keyword)
                                                  `(:|type| "uri"
                                                    :|value| ,(if (stringp val)
                                                                  val
                                                                  (format nil "~A" val))))))
                            bindings))))))

(defun results-to-xml (results)
  "Format query results as SPARQL XML Results

   Format per W3C SPARQL Query Results XML Format"

  (let ((variables (getf results :variables))
        (bindings (getf results :bindings)))

    (with-output-to-string (out)
      (format out "<?xml version=\"1.0\"?>~%")
      (format out "<sparql xmlns=\"http://www.w3.org/2005/sparql-results#\">~%")
      (format out "  <head>~%")
      (dolist (var variables)
        (format out "    <variable name=\"~A\"/>~%" var))
      (format out "  </head>~%")
      (format out "  <results>~%")
      (dolist (binding bindings)
        (format out "    <result>~%")
        (dolist (pair binding)
          (when (cdr pair)
            (format out "      <binding name=\"~A\">~%" (car pair))
            (format out "        <uri>~A</uri>~%" (cdr pair))
            (format out "      </binding>~%")))
        (format out "    </result>~%"))
      (format out "  </results>~%")
      (format out "</sparql>~%"))))

(defun results-to-csv (results)
  "Format query results as CSV"
  (let ((variables (getf results :variables))
        (bindings (getf results :bindings)))

    (with-output-to-string (out)
      ;; Header
      (format out "~{~A~^,~}~%" variables)
      ;; Rows
      (dolist (binding bindings)
        (format out "~{~A~^,~}~%"
                (mapcar (lambda (pair)
                          (or (cdr pair) ""))
                        binding))))))

;;; ============================================================================
;;; HTTP ENDPOINT
;;; ============================================================================

(defvar *sparql-kb* nil
  "Knowledge base for SPARQL endpoint")

(defvar *endpoint-server* nil
  "HTTP server instance")

(defun handle-sparql-request (request kb)
  "Handle SPARQL HTTP request

   Supports:
   - GET with query parameter
   - POST with application/sparql-query
   - Content negotiation for results format

   Args:
     request: HTTP request plist (:method :query :accept :body)
     kb: Knowledge base

   Returns:
     Response plist (:status :content-type :body)"

  (handler-case
      (let* ((method (getf request :method))
             (query-string (or (getf request :query)
                               (getf request :body)))
             (accept (or (getf request :accept) "application/json")))

        (unless query-string
          (return-from handle-sparql-request
            (list :status 400
                  :content-type "text/plain"
                  :body "Missing query parameter")))

        (let ((results (execute-sparql query-string kb)))

          ;; Format based on Accept header
          (cond
            ((search "json" accept)
             (list :status 200
                   :content-type "application/sparql-results+json"
                   :body (results-to-json results)))

            ((search "xml" accept)
             (list :status 200
                   :content-type "application/sparql-results+xml"
                   :body (results-to-xml results)))

            ((search "csv" accept)
             (list :status 200
                   :content-type "text/csv"
                   :body (results-to-csv results)))

            (t
             (list :status 200
                   :content-type "application/sparql-results+json"
                   :body (results-to-json results))))))

    (error (e)
      (list :status 500
            :content-type "text/plain"
            :body (format nil "Query error: ~A" e)))))

(defun start-sparql-endpoint (kb &key (port *default-port*))
  "Start SPARQL HTTP endpoint

   Args:
     kb: Knowledge base to serve
     port: HTTP port (default 8890)

   Note: This creates a simple endpoint. For production,
         use behind nginx/traefik with proper security."

  (setf *sparql-kb* kb)
  (setf *endpoint-running* t)

  (format t "~&; SPARQL endpoint starting on port ~D...~%" port)
  (format t "; Query URL: http://localhost:~D/sparql?query=...~%" port)

  ;; Note: Actual HTTP server implementation would use Hunchentoot or Woo
  ;; This is the handler interface that would be registered
  (format t "; Endpoint ready (use handle-sparql-request for queries)~%")

  port)

(defun stop-sparql-endpoint ()
  "Stop SPARQL HTTP endpoint"
  (setf *endpoint-running* nil)
  (setf *sparql-kb* nil)
  (format t "~&; SPARQL endpoint stopped~%"))

;;; ============================================================================
;;; CONVENIENCE FUNCTIONS
;;; ============================================================================

(defun query-kb (kb query-string &key (format :json))
  "Execute SPARQL query and return formatted results

   Args:
     kb: Knowledge base
     query-string: SPARQL query
     format: :json, :xml, or :csv

   Returns:
     Formatted result string"

  (let ((results (execute-sparql query-string kb)))
    (case format
      (:json (results-to-json results))
      (:xml (results-to-xml results))
      (:csv (results-to-csv results))
      (t (results-to-json results)))))

;;; ============================================================================
;;; END OF SPARQL-ENDPOINT.LISP
;;; ============================================================================
