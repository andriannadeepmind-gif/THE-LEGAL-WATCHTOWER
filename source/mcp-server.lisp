;;;; source/mcp-server.lisp
;;;; ============================================================================
;;;; MCP SERVER — the AI-native interface: ask, get the law + citation + a proof,
;;;; and VERIFY it — directly from inside any AI agent.
;;;; ============================================================================
;;;;
;;;; Model Context Protocol over JSON-RPC 2.0 (stdio). An AI agent connects and:
;;;;   list_corpora        → the Greek codes we serve
;;;;   get_article         → {text, cite_as, eli, proof} for a provision
;;;;   verify_provision    → check a PCL-1 proof against a text (the trust root):
;;;;                         authentic iff it resolves to our signed Merkle root.
;;;;
;;;; This turns "cite us" into "verify against us": an agent's legal answer is
;;;; trustworthy only when it carries — and we confirm — a Proof-Carrying-Law proof.
;;;;
;;;; Top-tier shape: the PURE request→response dispatch (HANDLE-REQUEST) is fully
;;;; separated from the stdio loop (SERVE-MCP) so it is unit-tested deterministically;
;;;; tools are DECLARATIVE (define-mcp-tool); corpus access is an INJECTED resolver
;;;; (no hard coupling, mockable); every failure becomes a JSON-RPC error, never a
;;;; crash. Pure Common Lisp; JSON is emitted by a small typed serializer (no nil
;;;; ambiguity: :true/:false/:null are explicit).
;;;; ============================================================================

(defpackage :orchestrator.mcp
  (:use :cl)
  (:export #:handle-request #:handle-line #:serve-mcp
           #:define-mcp-tool #:*tools* #:to-json #:jobj
           #:*article-resolver* #:*corpus-list-fn* #:*corpus-audit-fn* #:*protocol-version*))

(in-package :orchestrator.mcp)

;;; ----------------------------------------------------------------------------
;;; minimal, unambiguous JSON value model + serializer
;;; ----------------------------------------------------------------------------

(defstruct (jobj (:constructor %jobj (pairs))) pairs)   ; pairs = ((key . value) …)
(defun jobj (&rest kvs)
  "Construct a JSON object from KEY VALUE … pairs (keys are strings)."
  (%jobj (loop for (k v) on kvs by #'cddr collect (cons k v))))

(defun %json-string (s)
  (with-output-to-string (o)
    (write-char #\" o)
    (loop for ch across (princ-to-string (or s ""))
          do (case ch
               (#\" (write-string "\\\"" o)) (#\\ (write-string "\\\\" o))
               (#\Newline (write-string "\\n" o)) (#\Return (write-string "\\r" o))
               (#\Tab (write-string "\\t" o)) (#\Backspace (write-string "\\b" o))
               (#\Page (write-string "\\f" o))
               (t (if (< (char-code ch) #x20)
                      (format o "\\u~4,'0x" (char-code ch))
                      (write-char ch o)))))
    (write-char #\" o)))

(defun to-json (v)
  "Serialize the typed value model to JSON. Objects = JOBJ, arrays = lists,
   booleans/null = :true/:false/:null (so NIL is unambiguously the empty array)."
  (cond
    ((eq v :true) "true") ((eq v :false) "false") ((eq v :null) "null")
    ((stringp v) (%json-string v))
    ((integerp v) (princ-to-string v))
    ((floatp v) (princ-to-string v))
    ((jobj-p v)
     (format nil "{~{~A~^,~}}"
             (mapcar (lambda (p) (format nil "~A:~A" (%json-string (car p)) (to-json (cdr p))))
                     (jobj-pairs v))))
    ((listp v) (format nil "[~{~A~^,~}]" (mapcar #'to-json v)))
    (t (%json-string (princ-to-string v)))))

(defun %aget (alist key &optional default)
  (let ((c (and (listp alist) (assoc key alist :test #'equal)))) (if c (cdr c) default)))

;;; ----------------------------------------------------------------------------
;;; declarative tools
;;; ----------------------------------------------------------------------------

(defvar *tools* '()
  "Registered MCP tools: each (name description input-schema-jobj handler-fn).")

(defmacro define-mcp-tool (name (args) description schema &body body)
  "Declare an MCP tool NAME with DESCRIPTION and SCHEMA (a JOBJ, JSON Schema for
   its arguments). BODY runs over ARGS (a string-keyed alist of arguments) and
   returns the text result the agent receives."
  `(progn
     (setf *tools* (remove ,name *tools* :key #'first :test #'string=))
     (setf *tools* (append *tools*
                           (list (list ,name ,description ,schema
                                       (lambda (,args)
                                         (declare (ignorable ,args))
                                         ,@body)))))
     ,name))

(defun %tool->jobj (tool)
  (destructuring-bind (name description schema handler) tool
    (declare (ignore handler))
    (jobj "name" name "description" description "inputSchema" schema)))

;;; ----------------------------------------------------------------------------
;;; injected corpus access (default resolvers; mockable in tests)
;;; ----------------------------------------------------------------------------

(defvar *corpus-list-fn*
  (lambda ()
    (let ((s (and (find-package :orchestrator.spec)
                  (find-symbol "*SERVED-CORPORA*" :orchestrator.cli))))
      (if (and s (boundp s)) (symbol-value s) '("syntagma" "poinikos"))))
  "(function () -> list of served corpus short-names).")

(defvar *article-resolver*
  (lambda (corpus id)
    "Default: read the emitted proof + text from output/<corpus>/."
    (let* ((base (or (and (find-package :uiop)
                          (uiop:getenv "ORCHESTRATOR_OUTPUT_DIR"))
                     "/app/output/"))
           (dir (format nil "~A~A/" (string-right-trim "/" base) corpus))
           (proof-path (format nil "~Aarticle-~A.proof.json" dir id))
           (text-path  (format nil "~Aarticle-~A.txt" dir id)))
      (when (probe-file proof-path)
        (list :proof (uiop:read-file-string proof-path :external-format :utf-8)
              :text (when (probe-file text-path)
                      (uiop:read-file-string text-path :external-format :utf-8))))))
  "(function (corpus id) -> plist (:text :cite :eli :proof)) or NIL if unknown.")

(defvar *corpus-audit-fn*
  (lambda (corpus) (declare (ignore corpus)) nil)
  "(function (corpus) -> plist quality report) or NIL. Injected by the CLI so a
   connected AI can AUDIT a codification: article count, numbering gaps, suspect
   articles (empty/very short), and lettered families — to cross-check fidelity
   against the source before publishing.")

;;; ----------------------------------------------------------------------------
;;; the tools
;;; ----------------------------------------------------------------------------

(define-mcp-tool "list_corpora" (args)
  "List the Greek legal codes this server provides (with proofs)."
  (jobj "type" "object" "properties" (jobj))
  (format nil "~{~A~^, ~}" (funcall *corpus-list-fn*)))

(define-mcp-tool "get_article" (args)
  "Get a provision: its text, canonical citation, ELI, and a Proof-Carrying-Law proof you can verify."
  (jobj "type" "object"
        "properties" (jobj "corpus" (jobj "type" "string")
                           "id" (jobj "type" "string"))
        "required" (list "corpus" "id"))
  (let* ((corpus (%aget args "corpus")) (id (%aget args "id"))
         (r (and corpus id (funcall *article-resolver* corpus id))))
    (if (null r)
        (format nil "Δεν βρέθηκε άρθρο ~A στον κώδικα ~A." id corpus)
        (format nil "~@[~A~%~]~@[Παραπομπή: ~A~%~]~@[ELI: ~A~%~]~@[~%PROOF (PCL-1, verify με verify_provision):~%~A~%~]"
                (getf r :text) (getf r :cite) (getf r :eli) (getf r :proof)))))

(define-mcp-tool "verify_provision" (args)
  "Check a Proof-Carrying-Law (PCL-1) proof against a text. This proves INCLUSION under the proof's own Merkle root; to prove AUTHENTICITY, verify that root's signature against our published key (pcl-public-key.jwk) with the public verifier."
  (jobj "type" "object"
        "properties" (jobj "text" (jobj "type" "string")
                           "proof" (jobj "type" "string" "description" "the article-N.proof.json contents"))
        "required" (list "text" "proof"))
  (let* ((text (%aget args "text")) (proof (%aget args "proof"))
         (fn (and (find-package :orchestrator.proof-carrying)
                  (find-symbol "VERIFY-PROOF-JSON" :orchestrator.proof-carrying))))
    (cond
      ((not (and text proof)) "Λείπει το text ή το proof.")
      ((null fn) "Ο verifier δεν είναι διαθέσιμος.")
      (t (multiple-value-bind (ok reason) (funcall fn text proof)
           (if ok
               (format nil "✓ ΣΥΝΕΠΕΣ — το κείμενο εντάσσεται στην ρίζα ~A που δηλώνει η απόδειξη.~%~
                            Για ΑΥΘΕΝΤΙΚΟΤΗΤΑ, επαλήθευσε την υπογραφή αυτής της ρίζας με το δημοσιευμένο κλειδί (pcl-public-key.jwk)."
                       (let ((r (ignore-errors
                                 (cdr (assoc "merkle_root"
                                             (jonathan:parse proof :as :alist) :test #'string=)))))
                         (if (stringp r) (subseq r 0 (min 23 (length r))) "—")))
               (format nil "✗ ΑΠΕΤΥΧΕ (~A) — το κείμενο ΔΕΝ εντάσσεται στην απόδειξη." reason)))))))

(define-mcp-tool "audit_corpus" (args)
  "QUALITY AUDIT of a code's codification, for an AI reviewer: returns the article
   count, the numbering gaps (so repealed-vs-missing can be judged), suspiciously
   empty/short articles, and lettered families. Use it to cross-check extraction
   fidelity against the source, then drill into specific articles with get_article."
  (jobj "type" "object"
        "properties" (jobj "corpus" (jobj "type" "string"))
        "required" (list "corpus"))
  (let* ((corpus (%aget args "corpus"))
         (r (and corpus (ignore-errors (funcall *corpus-audit-fn* corpus)))))
    (if (null r)
        (format nil "Δεν υπάρχει audit για ~A (ή ο corpus δεν βρέθηκε)." corpus)
        (format nil "ΕΛΕΓΧΟΣ ΚΩΔΙΚΟΠΟΙΗΣΗΣ: ~A~%  άρθρα: ~A~%  εύρος: ~A..~A~%  γράμματα (lettered): ~A~%  κενά αρίθμησης: ~A~%  ύποπτα (κενό/πολύ σύντομο): ~A~%  homoglyphs (λατινικά σε ελληνικά): ~A~%  σπασμένες ραφές (hyphenation): ~A~%~A"
                corpus (getf r :count) (getf r :min) (getf r :max) (getf r :lettered)
                (let ((g (getf r :gaps))) (if g (format nil "~{~A~^, ~}" g) "(κανένα)"))
                (let ((s (getf r :suspect))) (if s (format nil "~{~A~^, ~}" s) "(κανένα)"))
                (let ((h (getf r :homoglyphs))) (if h (format nil "~{~A~^, ~}" h) "(κανένα)"))
                (let ((b (getf r :hyphen-breaks))) (if b (format nil "~{~A~^, ~}" b) "(κανένα)"))
                (or (getf r :note) "")))))

;;; ----------------------------------------------------------------------------
;;; JSON-RPC 2.0 / MCP dispatch  (PURE: request alist -> response jobj or NIL)
;;; ----------------------------------------------------------------------------

(defparameter *protocol-version* "2024-11-05")
(defparameter *server-info* (jobj "name" "stavropoulos-law-gr" "version" "1.0.0"))

(defun %result (id value) (jobj "jsonrpc" "2.0" "id" (or id :null) "result" value))
(defun %error (id code message)
  (jobj "jsonrpc" "2.0" "id" (or id :null) "error" (jobj "code" code "message" message)))

(defun %call-tool (id params)
  (let* ((name (%aget params "name")) (args (%aget params "arguments"))
         (tool (find name *tools* :key #'first :test #'equal)))
    (if (null tool)
        (%error id -32602 (format nil "Unknown tool: ~A" name))
        (handler-case
            (%result id (jobj "content"
                              (list (jobj "type" "text" "text" (funcall (fourth tool) args)))))
          (error (e)
            (%result id (jobj "content" (list (jobj "type" "text" "text"
                                                    (format nil "error: ~A" e)))
                              "isError" :true)))))))

(defun handle-request (req)
  "Dispatch a parsed JSON-RPC request alist. Returns a response JOBJ, or NIL for a
   notification (a message with no id / the initialized notice)."
  (let ((id (%aget req "id")) (method (%aget req "method")) (params (%aget req "params")))
    (cond
      ((null method) (and id (%error id -32600 "Invalid Request")))
      ((string= method "initialize")
       (%result id (jobj "protocolVersion" *protocol-version*
                         "capabilities" (jobj "tools" (jobj))
                         "serverInfo" *server-info*)))
      ((string= method "notifications/initialized") nil)
      ((string= method "ping") (%result id (jobj)))
      ((string= method "tools/list")
       (%result id (jobj "tools" (mapcar #'%tool->jobj *tools*))))
      ((string= method "tools/call") (%call-tool id params))
      ((null id) nil)                                   ; unknown notification → ignore
      (t (%error id -32601 (format nil "Method not found: ~A" method))))))

(defun handle-line (line)
  "Parse one JSON-RPC LINE and return the response JSON string, or NIL (notification
   / blank / parse error on a notification). Never throws."
  (handler-case
      (let* ((req (jonathan:parse line :as :alist))
             (resp (handle-request req)))
        (and resp (to-json resp)))
    (error (e)
      (to-json (%error :null -32700 (format nil "Parse error: ~A" e))))))

(defun serve-mcp (&key (in *standard-input*) (out *standard-output*))
  "The stdio JSON-RPC loop (one JSON message per line). Thin wrapper over the pure
   HANDLE-LINE: read a line, write the response line, flush, until EOF. stdout must
   carry ONLY protocol frames, so any incidental output produced WHILE handling a
   request (e.g. a corpus-config line printed deep in live consolidation) is
   redirected to *error-output* — it must never corrupt the JSON-RPC stream."
  (let ((proto out))
    (loop for line = (read-line in nil :eof)
          until (eq line :eof)
          do (when (plusp (length (string-trim '(#\Space #\Tab #\Return) line)))
               (let ((resp (let ((*standard-output* *error-output*)
                                 (*trace-output* *error-output*))
                             (handle-line line))))
                 (when resp
                   (write-string resp proto) (write-char #\Newline proto)
                   (force-output proto)))))))
