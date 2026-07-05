;;;; tests/government-source-test.lisp
;;;; Verifies the single government-source module: fetch + materialize + the
;;;; Diavgeia scheduler source — all defensive, one HTTP primitive.

(in-package :orchestrator.gov-source)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(let* ((sample "[{\"title\":\"Άρθρο 1\",\"content\":[\"Κείμενο από την πηγή.\"]},{\"title\":\"Άρθρο 2\",\"content\":[\"Δεύτερο.\"]}]")
       (srv (orchestrator.http:start-server
             (lambda (req) (declare (ignore req))
               (orchestrator.http:respond 200 sample "Content-Type" "application/json"))
             :port 0)))
  (sleep 0.3)
  (let* ((port (orchestrator.http:server-port srv))
         (url (format nil "http://127.0.0.1:~D/code.json" port))
         (out "/tmp/govtest_code.json"))

    (format t "~%== materialize from state source (json) ==~%")
    (multiple-value-bind (cnt status) (materialize-corpus :url url :format :json :json-path out)
      (check "materialize status OK" (eq status :ok))
      (check "materialize parsed 2 articles" (= 2 cnt))
      (check "clean JSON written with Greek text"
             (and (probe-file out)
                  (search "Κείμενο από την πηγή"
                          (with-open-file (s out :external-format :utf-8)
                            (let ((b (make-string (file-length s)))) (subseq b 0 (read-sequence b s))))))))

    (format t "~%== defensiveness ==~%")
    (check "fetch-url on unreachable host returns NIL, never throws"
           (null (handler-case (fetch-url "http://127.0.0.1:1/nope" :timeout 2)
                   (error () :threw))))
    (check "materialize with empty url -> :no-source-url"
           (multiple-value-bind (c s) (materialize-corpus :url "" :format :json :json-path out)
             (declare (ignore c)) (eq s :no-source-url)))

    (format t "~%== diavgeia source (single government module) ==~%")
    (let ((src (make-diavgeia-source)))
      (check "make-diavgeia-source returns an ingestion source"
             (funcall (find-symbol "INGESTION-SOURCE-P" :orchestrator.ingestion) src))
      (check "diavgeia fetch is defensive (list, never throws)"
             (listp (handler-case
                        (funcall (find-symbol "FETCH-ITEMS" :orchestrator.ingestion) src "2020-01-01")
                      (error () :threw))))))
  (orchestrator.http:stop-server srv))

(format t "~%========================================~%")
(format t "Government-source tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
