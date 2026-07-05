;;;; tests/document-fetch-test.lisp
;;;; The pure-Lisp orchestration of an external (headless) document fetcher. The
;;;; real network/browser is mocked by local shell commands, so the orchestration
;;;; — command templating, running it, and (critically) validating that a REAL PDF
;;;; landed (not an anti-bot HTML page) — is exercised deterministically offline.

(in-package :orchestrator.document-fetch)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *dir* (format nil "/tmp/docfetch-test-~A/" (get-universal-time)))
(ensure-directories-exist *dir*)
(defun p (name) (concatenate 'string *dir* name))

;; fixtures: a real PDF (correct magic) and an anti-bot HTML page
(defparameter *pdf-fixture* (p "real.pdf"))
(defparameter *html-fixture* (p "blocked.html"))
(with-open-file (s *pdf-fixture* :direction :output :element-type '(unsigned-byte 8)
                                 :if-exists :supersede :if-does-not-exist :create)
  (write-sequence (map '(vector (unsigned-byte 8)) #'char-code
                       (format nil "%PDF-1.4~%1 0 obj<<>>endobj~%%%EOF~%")) s))
(with-open-file (s *html-fixture* :direction :output :if-exists :supersede :if-does-not-exist :create)
  (write-string "<html><body>Are you human? Access blocked.</body></html>" s))

(format t "~%== command templating ({{out}} substitution) ==~%")
(check "{{out}} is replaced with the destination path"
       (string= "wget -O /tmp/a.pdf https://x"
                (%substitute-out "wget -O {{out}} https://x" "/tmp/a.pdf")))
(check "multiple {{out}} are all replaced"
       (string= "/tmp/a /tmp/a" (%substitute-out "{{out}} {{out}}" "/tmp/a")))
(check "a command with no placeholder is unchanged"
       (string= "echo hi" (%substitute-out "echo hi" "/tmp/a")))

(format t "~%== PDF magic validation ==~%")
(check "a real PDF is recognised" (pdf-file-p *pdf-fixture*))
(check "an HTML page is NOT a PDF" (not (pdf-file-p *html-fixture*)))
(check "a missing file is NOT a PDF" (not (pdf-file-p (p "nope.pdf"))))

(format t "~%== run-fetch-command (exit codes, never throws) ==~%")
(check "a succeeding command returns 0" (eql 0 (run-fetch-command "exit 0")))
(check "a failing command returns its code" (eql 3 (run-fetch-command "exit 3")))

(format t "~%== fetch-pdf: the full acquisition contract ==~%")
(let ((out (p "got.pdf")))
  (multiple-value-bind (ok status) (fetch-pdf (format nil "cp ~A {{out}}" *pdf-fixture*) out)
    (check "a fetcher that produces a real PDF succeeds" ok)
    (check "status is :ok" (eq :ok status))
    (check "the PDF actually landed at the destination" (pdf-file-p out))))

(let ((out (p "blocked.pdf")))
  (multiple-value-bind (ok status) (fetch-pdf (format nil "cp ~A {{out}}" *html-fixture*) out)
    (check "an anti-bot HTML page is REJECTED (not ingested as a PDF)" (not ok))
    (check "status is :not-a-pdf" (eq :not-a-pdf status))))

(let ((out (p "fail.pdf")))
  (multiple-value-bind (ok status) (fetch-pdf "exit 1" out)
    (check "a failing fetcher is reported" (not ok))
    (check "status carries :fetch-failed" (eq :fetch-failed (first status)))))

(let ((out (p "empty.pdf")))
  (multiple-value-bind (ok status) (fetch-pdf "true" out)
    (check "a fetcher that produced no file is reported" (not ok))
    (check "status is :no-file-produced" (eq :no-file-produced status))))

(multiple-value-bind (ok status) (fetch-pdf "" (p "x.pdf"))
  (check "an empty command yields :no-command" (and (not ok) (eq :no-command status))))
(multiple-value-bind (ok status) (fetch-pdf nil (p "x.pdf"))
  (check "a NIL command yields :no-command" (and (not ok) (eq :no-command status))))

(format t "~%== ΦΕΚ public-blob URL (deterministic, pure Lisp) ==~%")
(check "poinikos Α 95/2019 → the exact confirmed blob URL"
       (string= (fek-blob-url "Α" 95 2019)
                "https://ia37rg02wpsa01.blob.core.windows.net/fek/01/2019/20190100095.pdf"))
(check "number is zero-padded to 5 digits"
       (search "/20190100095.pdf" (fek-blob-url "Α" 95 2019)))
(check "τεύχος Α→01, Β→02, Γ→03, Δ→04"
       (and (search "/fek/01/" (fek-blob-url "Α" 1 2020))
            (search "/fek/02/" (fek-blob-url "Β" 1 2020))
            (search "/fek/03/" (fek-blob-url "Γ" 1 2020))
            (search "/fek/04/" (fek-blob-url "Δ" 1 2020))))
(check "Latin 'A' is accepted as τεύχος Α" (search "/fek/01/" (fek-blob-url "A" 1 2020)))

;; cleanup
(ignore-errors (uiop:delete-directory-tree (pathname *dir*) :validate t))

(format t "~%========================================~%")
(format t "Document fetch tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
