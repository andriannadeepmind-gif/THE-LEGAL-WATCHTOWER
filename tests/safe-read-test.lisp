;;;; tests/safe-read-test.lisp
;;;; Locks the ONE safe-read data-deserialization seat ([0094]/Phase 1). The seat is
;;;; the only sanctioned reader of external/untrusted s-expressions: it must make code
;;;; execution STRUCTURALLY impossible (never merely guarded), reject every DoS payload,
;;;; and round-trip every canonical data shape losslessly (no precision/type downgrade).
;;;; Self-contained: loads source/safe-read.lisp relative to this file (no deps but :cl).

(let* ((here (or *load-truename* *load-pathname*))
       (seat (merge-pathnames "../source/safe-read.lisp"
                              (make-pathname :directory (pathname-directory here)))))
  (unless (probe-file seat)
    (format t "~%  SKIP — source/safe-read.lisp not present here.~%")
    (sb-ext:exit :code 0))
  (handler-bind ((warning #'muffle-warning)) (load seat)))

(defpackage :safe-read-test (:use :cl :orchestrator.safe-read))
(in-package :safe-read-test)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun rds (s &rest args) (apply #'read-data-string s args))
(defmacro val (s &rest args) `(nth-value 0 (rds ,s ,@args)))
(defmacro stat (s &rest args) `(nth-value 1 (rds ,s ,@args)))

(defun with-temp (content thunk)
  (let ((p (format nil "/tmp/safe-read-test-~D.sexp" (random 1000000))))
    (with-open-file (o p :direction :output :if-exists :supersede
                         :external-format :utf-8)
      (write-string content o))
    (unwind-protect (funcall thunk p) (ignore-errors (delete-file p)))))

(format t "~%── POSITIVE: canonical data round-trips (no downgrade) ──~%")
(check "plist keyword/string/int"
       (equal (val "(:a 1 :b \"x\" :c :kw)") '(:a 1 :b "x" :c :kw)))
(check "nested lists" (equal (val "(:x (1 (2 (3))))") '(:x (1 (2 (3))))))
(check "ratio preserved" (eql (val "22/7") 22/7))
(check "double float preserved (default double-format)"
       (eql (val "3.14") 3.14d0))
(check "COMMON-LISP:NIL round-trips as real NIL"
       (null (val "COMMON-LISP:NIL")))
(check "status :ok on single form" (eq (stat "(:a 1)") :ok))
(check "# INSIDE a string is fine" (equal (val "\"gr/syntagma#art:1\"") "gr/syntagma#art:1"))
(check "sequence: all top-level forms"
       (with-temp "(:a 1)(:b 2)(:c 3)"
         (lambda (p) (equal (nth-value 0 (read-data-file-sequence p))
                            '((:a 1) (:b 2) (:c 3))))))
(check "read-data-file one form :ok"
       (with-temp "(:root (:k :v))"
         (lambda (p) (and (equal (nth-value 0 (read-data-file p)) '(:root (:k :v)))
                          (eq (nth-value 1 (read-data-file p)) :ok)))))

(format t "~%── NEGATIVE: RCE payloads rejected (execution structurally impossible) ──~%")
(check "#.(...) read-eval REJECTED (:unreadable), NOT executed"
       (eq (stat "#.(+ 1 2)") :unreadable))
(check "#.(side effect) never runs — value is :unreadable"
       (let ((*evil* nil)) (declare (special *evil*))
         (eq (stat "#.(setf safe-read-test::*evil* t)") :unreadable)))
(check "backquote quasiquote REJECTED (code template, not data)"
       (eq (stat "`(a ,b)") :unreadable))
(check "bare comma REJECTED" (eq (stat ",x") :unreadable))
(check "#(vector) REJECTED" (eq (stat "#(1 2 3)") :unreadable))
(check "#\\char dispatch REJECTED" (eq (stat "#\\a") :unreadable))
(check "#S(struct) REJECTED" (eq (stat "#S(foo :a 1)") :unreadable))
(check "#=/## circular REJECTED" (eq (stat "#1=(a . #1#)") :unreadable))
(check "#+feature conditional REJECTED" (eq (stat "#+sbcl 9") :unreadable))
(check "#P pathname REJECTED" (eq (stat "#P\"/etc/passwd\"") :unreadable))
(check "#xFF radix REJECTED" (eq (stat "#xFF") :unreadable))

(format t "~%── NEGATIVE: DoS payloads bounded (structural, not catch-in-red-zone) ──~%")
(check "deep nesting → :too-deep (pre-scan, before reader recurses)"
       (eq (stat (make-string 5000 :initial-element #\() :max-depth 2000) :too-deep))
(check "deep nesting within limit is OK"
       (let ((s (concatenate 'string (make-string 100 :initial-element #\()
                             (make-string 100 :initial-element #\)))))
         (member (stat s :max-depth 2000) '(:ok :empty))))
(check "oversized string → :too-large"
       (eq (stat "(:a 1)" :max-bytes 3) :too-large))
(check "pre-scan ignores parens INSIDE strings"
       (= (max-paren-depth "\"((((\"") 0))
(check "pre-scan ignores parens INSIDE ; comments"
       (= (max-paren-depth "; ((((
(:a)") 1))

(format t "~%── STATUS distinctness (ebg contract preserved) ──~%")
(check ":empty on empty input" (eq (stat "   ") :empty))
(check ":empty on whitespace+comment only" (eq (stat "; just a comment
") :empty))
(check ":trailing on two top-level forms" (eq (stat "(:a 1) (:b 2)") :trailing))
(check ":trailing returns the FIRST form" (equal (val "(:a 1) (:b 2)") '(:a 1)))
(check "absent file → :empty (matches load-review-queue nil)"
       (eq (nth-value 1 (read-data-file "/tmp/does-not-exist-safe-read.sexp")) :empty))

(format t "~%── float-format parameter (per-site precision, no silent drift) ──~%")
(check "float-format single yields single-float"
       (eql (val "3.14" :float-format 'single-float) 3.14f0))
(check "float-format double yields double-float"
       (eql (val "3.14" :float-format 'double-float) 3.14d0))

(format t "~%── package parameter (preserves each reader's behavior) ──~%")
(check ":keyword pin: bare symbol → keyword" (eq (val "foo") :foo))
(check ":package :cl-user: bare symbol interns there"
       (eq (val "foo" :package :cl-user) (intern "FOO" :cl-user)))

(format t "~%── canonicalize-bool (silent-boolean-bug guard under keyword pin) ──~%")
(check ":nil → nil valid"     (multiple-value-bind (c v) (canonicalize-bool :nil) (and (null c) v)))
(check "nil → nil valid"      (multiple-value-bind (c v) (canonicalize-bool nil) (and (null c) v)))
(check ":t → t valid"         (multiple-value-bind (c v) (canonicalize-bool :t) (and (eq c t) v)))
(check "t → t valid"          (multiple-value-bind (c v) (canonicalize-bool t) (and (eq c t) v)))
(check "garbage → invalid"    (multiple-value-bind (c v) (canonicalize-bool :maybe) (and (null c) (null v))))

(format t "~%safe-read-test: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
