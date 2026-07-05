;;;; source/http-server.lisp
;;;; ============================================================================
;;;; PURE COMMON LISP HTTP/1.1 SERVER
;;;; ============================================================================
;;;;
;;;; A small, dependency-light HTTP server built directly on usocket +
;;;; bordeaux-threads (no Hunchentoot/Clack) — consistent with the project's
;;;; "100% Pure Common Lisp" stance. It is just enough to serve the AI-first
;;;; corpus service: GET/HEAD, request line + headers parsing, and a response
;;;; with correct Content-Length over a binary socket (UTF-8 bodies).
;;;;
;;;; A request is dispatched to a HANDLER function (request -> response). The
;;;; CLOS content-negotiation service lives in corpus-service.lisp.
;;;; ============================================================================

(defpackage :orchestrator.http
  (:use :cl)
  (:export
   #:http-request #:make-http-request #:http-request-method #:http-request-path
   #:http-request-query #:http-request-headers #:http-request-header
   #:http-response #:make-http-response #:http-response-status
   #:http-response-headers #:http-response-body #:respond
   #:start-server #:stop-server #:server-port #:with-server))

(in-package :orchestrator.http)

;;; ============================================================================
;;; REQUEST / RESPONSE
;;; ============================================================================

(defstruct http-request
  (method "GET" :type string)
  (path "/" :type string)
  (query nil)                            ; alist of (name . value)
  (headers nil))                         ; alist of (lowercased-name . value)

(defun http-request-header (req name)
  (cdr (assoc (string-downcase name) (http-request-headers req) :test #'string=)))

(defstruct http-response
  (status 200 :type integer)
  (headers nil)                          ; alist of (name . value)
  (body "" :type string))

(defun respond (status body &rest headers)
  "Convenience constructor: (respond 200 \"...\" \"Content-Type\" \"text/plain\")."
  (make-http-response
   :status status :body (or body "")
   :headers (loop for (k v) on headers by #'cddr collect (cons k v))))

(defparameter +status-text+
  '((200 . "OK") (204 . "No Content") (400 . "Bad Request")
    (404 . "Not Found") (405 . "Method Not Allowed") (406 . "Not Acceptable")
    (500 . "Internal Server Error")))

;;; ============================================================================
;;; REQUEST PARSING (binary-safe)
;;; ============================================================================

(defparameter *max-request-head-bytes* (* 64 1024)
  "Hard ceiling on the request head (request line + all headers). A client that
   never sends the CRLFCRLF terminator — an endless stream, or a slowloris
   drip-feed — would otherwise grow this buffer without bound and pin a thread.
   64 KiB is far beyond any legitimate header block; exceeding it aborts the
   connection (NIL) instead of letting one peer exhaust memory/threads.")

(defun read-request-head (stream)
  "Read bytes from STREAM up to and including CRLFCRLF; return the head as a
   latin-1 string (headers are ASCII). Returns NIL on EOF before any data, or
   when the head exceeds *MAX-REQUEST-HEAD-BYTES* (malformed / DoS)."
  (let ((bytes (make-array 0 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0))
        (state 0))                       ; matches \r \n \r \n
    (loop
      (let ((b (read-byte stream nil nil)))
        (when (null b)
          (return (when (plusp (length bytes))
                    (map 'string #'code-char bytes))))
        (when (>= (length bytes) *max-request-head-bytes*)
          ;; unterminated / oversized head — refuse rather than grow unboundedly.
          (return nil))
        (vector-push-extend b bytes)
        (setf state
              (cond ((and (= state 0) (= b 13)) 1)
                    ((and (= state 1) (= b 10)) 2)
                    ((and (= state 2) (= b 13)) 3)
                    ((and (= state 3) (= b 10)) 4)
                    ((= b 13) 1)
                    (t 0)))
        (when (= state 4)
          (return (map 'string #'code-char bytes)))))))

(defun split-once (string ch)
  (let ((i (position ch string)))
    (if i (values (subseq string 0 i) (subseq string (1+ i)))
        (values string nil))))

(defun url-decode (string)
  "Decode application/x-www-form-urlencoded STRING (%XX and '+' -> space)."
  (with-output-to-string (out)
    (let ((i 0) (n (length string)))
      (loop while (< i n)
            do (let ((ch (char string i)))
                 (cond
                   ((char= ch #\+) (write-char #\Space out) (incf i))
                   ((and (char= ch #\%) (< (+ i 2) n))
                    (let ((code (ignore-errors
                                 (parse-integer string :start (1+ i) :end (+ i 3) :radix 16))))
                      (if code
                          (progn
                            ;; collect a run of %XX bytes and UTF-8 decode them
                            (let ((bytes (make-array 0 :element-type '(unsigned-byte 8)
                                                       :adjustable t :fill-pointer 0)))
                              (loop while (and (< (+ i 2) n) (char= (char string i) #\%))
                                    for b = (ignore-errors
                                             (parse-integer string :start (1+ i) :end (+ i 3) :radix 16))
                                    while b do (vector-push-extend b bytes) (incf i 3))
                              (write-string (babel:octets-to-string bytes :encoding :utf-8) out)))
                          (progn (write-char ch out) (incf i)))))
                   (t (write-char ch out) (incf i))))))))

(defun parse-query (query-string)
  (when (and query-string (plusp (length query-string)))
    (loop for pair in (uiop:split-string query-string :separator '(#\&))
          for (k v) = (multiple-value-list (split-once pair #\=))
          collect (cons (url-decode k) (url-decode (or v ""))))))

(defun parse-request-head (head)
  "Parse a raw HTTP request head into an HTTP-REQUEST, or NIL if malformed."
  (let* ((lines (remove "" (uiop:split-string head :separator '(#\Newline))
                        :test (lambda (a b) (declare (ignore a))
                                (or (string= b "") (string= b (string #\Return))))))
         (lines (mapcar (lambda (l) (string-right-trim '(#\Return) l)) lines)))
    (when (null lines) (return-from parse-request-head nil))
    (destructuring-bind (request-line &rest header-lines) lines
      (let* ((parts (uiop:split-string request-line :separator '(#\Space)))
             (method (first parts))
             (target (second parts)))
        (unless (and method target) (return-from parse-request-head nil))
        (multiple-value-bind (path query) (split-once target #\?)
          (make-http-request
           :method (string-upcase method)
           :path path
           :query (parse-query query)
           :headers (loop for line in header-lines
                          for (k v) = (multiple-value-list (split-once line #\:))
                          when v
                          collect (cons (string-downcase (string-trim " " k))
                                        (string-trim " " v)))))))))

;;; ============================================================================
;;; RESPONSE WRITING
;;; ============================================================================

(defun write-response (stream response head-only)
  (let* ((body-octets (babel:string-to-octets (http-response-body response) :encoding :utf-8))
         (status (http-response-status response))
         (reason (or (cdr (assoc status +status-text+)) "OK"))
         (head (with-output-to-string (s)
                 (format s "HTTP/1.1 ~D ~A~A~A" status reason #\Return #\Newline)
                 (format s "Content-Length: ~D~A~A" (length body-octets) #\Return #\Newline)
                 (format s "Connection: close~A~A" #\Return #\Newline)
                 (loop for (k . v) in (http-response-headers response)
                       do (format s "~A: ~A~A~A" k v #\Return #\Newline))
                 (format s "~A~A" #\Return #\Newline))))
    (write-sequence (babel:string-to-octets head :encoding :latin-1) stream)
    (unless head-only (write-sequence body-octets stream))
    (finish-output stream)))

;;; ============================================================================
;;; SERVER
;;; ============================================================================

(defclass http-server ()
  ((listener :initarg :listener :accessor server-listener)
   (thread :initarg :thread :accessor server-thread)
   (port :initarg :port :accessor server-port)
   (running :initform t :accessor server-running-p)))

(defun handle-connection (socket handler)
  (let ((stream (usocket:socket-stream socket)))
    (handler-case
        (let* ((head (read-request-head stream))
               (req (and head (parse-request-head head))))
          (if (null req)
              (write-response stream (respond 400 "Bad Request"
                                              "Content-Type" "text/plain")
                              nil)
              (let ((resp (handler-case (funcall handler req)
                            (error (e)
                              (respond 500 (format nil "Internal error: ~A" e)
                                       "Content-Type" "text/plain")))))
                (write-response stream resp
                                (string= (http-request-method req) "HEAD")))))
      (error () nil))
    (ignore-errors (usocket:socket-close socket))))

(defparameter *max-connections*
  (or (ignore-errors (parse-integer (or (uiop:getenv "HTTP_MAX_CONN") "")))
      64)
  "Ανώτατος αριθμός ΤΑΥΤΟΧΡΟΝΩΝ συνδέσεων (Φάση 0): πάνω από αυτόν, άμεσο 503 —
   όχι απεριόριστα νήματα (slowloris/exhaustion).")

(defparameter *read-timeout-seconds* 15
  "Χρονικό όριο ανάγνωσης αιτήματος — αργός/βουβός πελάτης δεν κρατά νήμα αιώνια.")

(defun %reject-overload (socket)
  "Άμεση, φθηνή απάντηση 503 όταν ο server είναι στο όριο — χωρίς νέο νήμα."
  (ignore-errors
    (write-response (usocket:socket-stream socket)
                    (respond 503 "Server busy" "Content-Type" "text/plain"
                             "Retry-After" "1")
                    nil))
  (ignore-errors (usocket:socket-close socket)))

(defun start-server (handler &key (port 8080) (host "127.0.0.1"))
  "Start an HTTP server on HOST:PORT dispatching each request to HANDLER
   (an HTTP-REQUEST -> HTTP-RESPONSE function). Returns an HTTP-SERVER. When
   PORT is 0 the OS assigns a free port (readable via SERVER-PORT).
   Φάση 0: φραγμένος αριθμός νημάτων (semaphore), read timeout ανά σύνδεση,
   backoff σε σφάλματα accept (EMFILE) — ορθότητα υπό φορτίο, όχι ευχή."
  (let* ((listener (usocket:socket-listen host port :reuse-address t
                                          :element-type '(unsigned-byte 8)))
         (actual-port (usocket:get-local-port listener))
         (server (make-instance 'http-server :listener listener :port actual-port
                                             :thread nil))
         (slots (sb-thread:make-semaphore :count *max-connections*
                                          :name "http-conn-slots")))
    (setf (server-thread server)
          (bordeaux-threads:make-thread
           (lambda ()
             (loop while (server-running-p server)
                   do (handler-case
                          (let ((socket (usocket:socket-accept listener)))
                            ;; read timeout: βουβός πελάτης δεν δεσμεύει νήμα αιώνια
                            (ignore-errors
                              (setf (usocket:socket-option socket :receive-timeout)
                                    *read-timeout-seconds*))
                            (if (sb-thread:try-semaphore slots)
                                (bordeaux-threads:make-thread
                                 (lambda ()
                                   (unwind-protect
                                        (handle-connection socket handler)
                                     (sb-thread:signal-semaphore slots)))
                                 :name "http-conn")
                                (%reject-overload socket)))
                        ;; EMFILE κ.ά.: μικρό backoff αντί για busy-spin που καίει CPU
                        (error () (sleep 0.05)))))
           :name "http-accept"))
    server))

(defun stop-server (server)
  (setf (server-running-p server) nil)
  (ignore-errors (usocket:socket-close (server-listener server)))
  (ignore-errors (bordeaux-threads:destroy-thread (server-thread server)))
  t)

(defmacro with-server ((var handler &rest options) &body body)
  `(let ((,var (start-server ,handler ,@options)))
     (unwind-protect (progn ,@body)
       (stop-server ,var))))
