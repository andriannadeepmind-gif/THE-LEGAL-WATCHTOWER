;;;; tests/mcp-server-test.lisp
;;;; The MCP (JSON-RPC 2.0) server: AI agents ask → get law + citation + a proof,
;;;; and verify it. Tests the PURE dispatch and the line handler deterministically:
;;;; the protocol handshake, tools/list, a REAL proof verified through the tool,
;;;; tamper rejection, an injected article resolver, and JSON-RPC error handling.

(in-package :orchestrator.mcp)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun req (method id &optional params)
  (append (list (cons "jsonrpc" "2.0") (cons "method" method))
          (when id (list (cons "id" id)))
          (when params (list (cons "params" params)))))
(defun js (request) (to-json (handle-request request)))   ; response as JSON string

(format t "~%== typed JSON serializer (no nil ambiguity) ==~%")
(check "object" (string= "{\"a\":1}" (to-json (jobj "a" 1))))
(check "array" (string= "[1,2,3]" (to-json (list 1 2 3))))
(check "empty array is []" (string= "[]" (to-json nil)))
(check "booleans + null" (string= "[true,false,null]" (to-json (list :true :false :null))))
(check "string escaping" (string= "\"a\\\"b\"" (to-json "a\"b")))

(format t "~%== MCP handshake ==~%")
(let ((r (js (req "initialize" 1))))
  (check "initialize returns the protocol version" (search "protocolVersion" r))
  (check "initialize advertises tools capability" (search "\"tools\"" r))
  (check "initialize returns serverInfo" (search "stavropoulos-law-gr" r))
  (check "the response echoes the id" (search "\"id\":1" r)))
(check "the initialized notification gets NO response" (null (handle-request (req "notifications/initialized" nil))))
(check "ping works" (search "\"result\"" (js (req "ping" 9))))

(format t "~%== tools/list ==~%")
(let ((r (js (req "tools/list" 2))))
  (check "lists verify_provision" (search "verify_provision" r))
  (check "lists get_article" (search "get_article" r))
  (check "lists list_corpora" (search "list_corpora" r))
  (check "each tool carries an inputSchema" (search "inputSchema" r)))

(format t "~%== verify_provision: a REAL proof, checked through the tool ==~%")
(let* ((texts (list "Ανθρωποκτονία με πρόθεση." "Κλοπή." "Απάτη."))
       (leaves (mapcar #'orchestrator.proof-carrying:leaf-hash texts))
       (root (orchestrator.proof-carrying:build-merkle-root leaves))
       (proof (orchestrator.proof-carrying:make-provision-proof
               "299" (first texts) leaves 0 root))
       (proof-json (orchestrator.proof-carrying:proof-plist->json proof)))
  (let ((r (js (req "tools/call" 3
                    (list (cons "name" "verify_provision")
                          (cons "arguments" (list (cons "text" (first texts))
                                                  (cons "proof" proof-json))))))))
    (check "authentic text → ✓ ΑΥΘΕΝΤΙΚΟ" (search "ΑΥΘΕΝΤΙΚΟ" r))
    (check "result is content, not an error" (not (search "isError" r))))
  (let ((r (js (req "tools/call" 4
                    (list (cons "name" "verify_provision")
                          (cons "arguments" (list (cons "text" "Αλλοιωμένο.")
                                                  (cons "proof" proof-json))))))))
    (check "tampered text → ✗ ΑΠΕΤΥΧΕ" (search "ΑΠΕΤΥΧΕ" r))))

(format t "~%== get_article via an injected resolver (mockable) ==~%")
(let ((*article-resolver*
        (lambda (corpus id)
          (when (and (string= corpus "poinikos") (string= id "299"))
            (list :text "Ανθρωποκτονία με πρόθεση." :cite "Άρθρο 299 ΠΚ"
                  :eli "…/art/299" :proof "{\"version\":\"pcl-1\"}")))))
  (let ((r (js (req "tools/call" 5
                    (list (cons "name" "get_article")
                          (cons "arguments" (list (cons "corpus" "poinikos") (cons "id" "299"))))))))
    (check "returns the article text" (search "Ανθρωποκτονία" r))
    (check "returns the citation" (search "Άρθρο 299 ΠΚ" r))
    (check "returns a verifiable proof" (search "pcl-1" r)))
  (let ((r (js (req "tools/call" 6
                    (list (cons "name" "get_article")
                          (cons "arguments" (list (cons "corpus" "poinikos") (cons "id" "9999"))))))))
    (check "unknown article → a clean 'not found', not a crash" (search "Δεν βρέθηκε" r))))

(format t "~%== list_corpora via injected list ==~%")
(let ((*corpus-list-fn* (lambda () (list "constitution" "poinikos" "astikos"))))
  (check "list_corpora returns the served codes"
         (search "poinikos" (js (req "tools/call" 7
                                     (list (cons "name" "list_corpora") (cons "arguments" nil)))))))

(format t "~%== JSON-RPC error handling ==~%")
(check "unknown method → -32601" (search "-32601" (js (req "no/such/method" 8))))
(check "unknown tool → -32602"
       (search "-32602" (js (req "tools/call" 10 (list (cons "name" "nope") (cons "arguments" nil))))))
(check "a notification with no id and unknown method → no response"
       (null (handle-request (req "whatever/notify" nil))))

(format t "~%== handle-line: real wire behaviour ==~%")
(check "a valid JSON-RPC line yields a JSON response"
       (search "protocolVersion" (handle-line "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}")))
(check "a notification line yields NO line"
       (null (handle-line "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}")))
(check "malformed JSON → a parse-error response (never crashes)"
       (search "-32700" (handle-line "{not json")))

(format t "~%== serve-mcp: stdout stays JSON-only even if handling prints ==~%")
;; Regression: live consolidation can print incidental lines (e.g. a corpus-config
;; log) WHILE a request is handled. serve-mcp must redirect that to *error-output*
;; so it never corrupts the protocol stream on stdout.
(let ((*article-resolver*
        (lambda (corpus id)
          (declare (ignore corpus id))
          (format *standard-output* "POLLUTION-TO-STDOUT~%")  ; the hazard
          (list :text "Άρθρο." :cite "Άρθρο 1" :eli "…/1" :proof "{}"))))
  (let* ((req (concatenate 'string
                "{\"jsonrpc\":\"2.0\",\"id\":9,\"method\":\"tools/call\","
                "\"params\":{\"name\":\"get_article\",\"arguments\":{\"corpus\":\"x\",\"id\":\"1\"}}}"))
         (proto (make-string-output-stream))
         (errs (make-string-output-stream)))
    (let ((*error-output* errs))
      (serve-mcp :in (make-string-input-stream (concatenate 'string req (string #\Newline)))
                 :out proto))
    (let ((out (get-output-stream-string proto)))
      (check "protocol stdout contains exactly one JSON-RPC line"
             (and (search "\"id\":9" out) (= 1 (count #\Newline out))))
      (check "incidental print did NOT leak onto the protocol stream"
             (null (search "POLLUTION" out)))
      (check "the incidental print was redirected to stderr"
             (search "POLLUTION" (get-output-stream-string errs))))))

(format t "~%========================================~%")
(format t "MCP server tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
