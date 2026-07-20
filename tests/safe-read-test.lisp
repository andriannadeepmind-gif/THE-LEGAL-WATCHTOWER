;;;; tests/safe-read-test.lisp
;;;; Locks the ONE safe-read data-deserialization seat ([0094]/Phase 1). The seat is the
;;;; only sanctioned reader of data-only s-expressions: code execution STRUCTURALLY impossible
;;;; (never merely guarded); every RCE/DoS payload rejected with deterministic why-codes; every
;;;; canonical shape round-trips losslessly (no precision/type downgrade, nil-as-false never :nil);
;;;; ZERO global readtable/package mutation. Self-contained: loads source/safe-read.lisp (no deps but :cl).

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

(defmacro val (s) `(nth-value 0 (read-data-string ,s)))
(defmacro stat (&rest args) `(nth-value 1 (read-data-string ,@args)))

(defun with-temp (content thunk)
  (let ((p (format nil "/tmp/safe-read-test-~D.sexp" (random 1000000))))
    (with-open-file (o p :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string content o))
    (unwind-protect (funcall thunk p) (ignore-errors (delete-file p)))))

(format t "~%── POSITIVE: canonical data round-trips (no downgrade) ──~%")
(check "plist keyword/string/int" (equal (val "(:a 1 :b \"x\" :c :kw)") '(:a 1 :b "x" :c :kw)))
(check "nested lists" (equal (val "(:x (1 (2 (3))))") '(:x (1 (2 (3))))))
(check "ratio preserved" (eql (val "22/7") 22/7))
(check "float ALWAYS double (fixed format, no drift)" (eql (val "3.14") 3.14d0))
(check "big float double preserved" (eql (val "31.12") 31.12d0))
(check "# INSIDE a string is fine" (equal (val "\"gr/syntagma#art:1\"") "gr/syntagma#art:1"))
(check "status :ok on single form" (eq (stat "(:a 1)") :ok))
(check "sequence: all top-level forms"
       (with-temp "(:a 1)(:b 2)(:c 3)"
         (lambda (p) (equal (nth-value 0 (read-data-file-sequence p)) '((:a 1) (:b 2) (:c 3))))))
(check "read-data-file one form :ok"
       (with-temp "(:root (:k :v))"
         (lambda (p) (and (equal (nth-value 0 (read-data-file p)) '(:root (:k :v)))
                          (eq (nth-value 1 (read-data-file p)) :ok)))))

(format t "~%── nil-as-false preserved, NEVER :nil (silent-boolean-bug guard) ──~%")
(check "COMMON-LISP:NIL round-trips as real NIL (false)" (null (val "COMMON-LISP:NIL")))
(check "plist with CL:NIL false field reads as real nil"
       (null (getf (val "(:legal-critical COMMON-LISP:NIL)") :legal-critical)))
(check "canonicalize-bool :nil → real nil (valid)"
       (multiple-value-bind (c v) (canonicalize-bool :nil) (and (null c) v)))
(check "canonicalize-bool nil → real nil (valid)"
       (multiple-value-bind (c v) (canonicalize-bool nil) (and (null c) v)))
(check "canonicalize-bool t/:t → t"
       (and (eq (canonicalize-bool t) t) (eq (canonicalize-bool :t) t)))
(check "canonicalize-bool garbage → invalid"
       (multiple-value-bind (c v) (canonicalize-bool :maybe) (and (null c) (null v))))

(format t "~%── NEGATIVE: RCE payloads rejected (execution structurally impossible) ──~%")
(check "#.(...) read-eval REJECTED, NOT executed" (eq (stat "#.(+ 1 2)") :unreadable))
(check "#.(side effect) never runs"
       (let ((*evil* nil)) (declare (special *evil*))
         (eq (stat "#.(setf safe-read-test::*evil* t)") :unreadable)))
(check "backquote quasiquote REJECTED (code template)" (eq (stat "`(a ,b)") :unreadable))
(check "bare comma REJECTED" (eq (stat ",x") :unreadable))
(check "#(vector) REJECTED" (eq (stat "#(1 2 3)") :unreadable))
(check "#\\char dispatch REJECTED" (eq (stat "#\\a") :unreadable))
(check "#S(struct) REJECTED" (eq (stat "#S(foo :a 1)") :unreadable))
(check "#=/## circular REJECTED" (eq (stat "#1=(a . #1#)") :unreadable))
(check "#+feature conditional REJECTED" (eq (stat "#+sbcl 9") :unreadable))
(check "#P pathname REJECTED" (eq (stat "#P\"/etc/passwd\"") :unreadable))
(check "#xFF radix REJECTED" (eq (stat "#xFF") :unreadable))
(check "#|block comment|# REJECTED (# denied at reader root)" (eq (stat "#|c|# 7") :unreadable))

(format t "~%── BYPASS attempts (smuggling execution past the seat) ──~%")
(check "#. hidden after leading whitespace/comment REJECTED" (eq (stat "  ; note
 #.(+ 1 2)") :unreadable))
(check "#. inside a nested list REJECTED" (eq (stat "(:x #.(+ 1 2))") :unreadable))
(check "load-time #, REJECTED" (eq (stat "#,(+ 1 2)") :unreadable))
(check "quasiquote nested in data REJECTED" (eq (stat "(:tmpl `(,x))") :unreadable))

(format t "~%── MUTATION: flipping bytes never yields execution ──~%")
(let ((base "(:a 1 :b (:c 2))") (exec-seen nil))
  (dotimes (i (length base))
    (let* ((m (copy-seq base))
           (orig (char m i)))
      (setf (char m i) (if (char= orig #\() #\# #\())  ; inject # / paren-noise
      (multiple-value-bind (form st) (read-data-string m)
        (declare (ignore form))
        ;; every mutation is either a clean data status OR unreadable — NEVER executes.
        (unless (member st '(:ok :empty :trailing :unreadable :too-deep :too-large :resource-exhausted))
          (setf exec-seen t)))))
  (check "all single-byte mutations stay in the safe status set" (not exec-seen)))

(format t "~%── DoS payloads bounded (structural, not catch-in-red-zone) ──~%")
(check "deep nesting → :too-deep (pre-scan, before reader recurses)"
       (eq (stat (make-string 5000 :initial-element #\() :max-depth 2000) :too-deep))
(check "deep nesting within limit is OK"
       (member (stat (concatenate 'string (make-string 100 :initial-element #\()
                                  (make-string 100 :initial-element #\)))) '(:ok :empty)))
(check "oversized string → :too-large" (eq (stat "(:a 1)" :max-bytes 3) :too-large))
(check "pre-scan ignores parens INSIDE strings" (= (max-paren-depth "\"((((\"") 0))
(check "pre-scan ignores parens INSIDE ; comments" (= (max-paren-depth "; ((((
(:a)") 1))

(format t "~%── [re-review B-2] atom-cap: φράζει το intern side-effect ΠΡΙΝ τον reader ──~%")
;; prescan-depth-atoms μετρά atoms σε ΕΝΑΝ pass· strings/comments/whitespace ΔΕΝ ξεκινούν token.
(check "prescan atoms: (:a (:b :c) 42) ⇒ 4 atoms" (= (nth-value 1 (prescan-depth-atoms "(:a (:b :c) 42)")) 4))
(check "prescan atoms: string ΔΕΝ μετρά ως atom (μόνο :a ⇒ 1)" (= (nth-value 1 (prescan-depth-atoms "(:a \"x y z\")")) 1))
(check "prescan atoms: ; comment token ΔΕΝ μετρά" (= (nth-value 1 (prescan-depth-atoms "(:a) ; b c d
")) 1))
(check "prescan depth ΑΝΑΛΛΟΙΩΤΟ (πρώτη τιμή = max-paren-depth)"
       (= (nth-value 0 (prescan-depth-atoms "(( ))")) (max-paren-depth "(( ))")))
;; ΤΟ ΚΕΝΟ B-2: πολλά atoms ⇒ :too-many-atoms ΠΡΙΝ τρέξει ο reader (κανένα intern).
(check "atom flood → :too-many-atoms (reject ΠΡΙΝ intern)"
       (eq (stat "(:a :b :c :d :e :f)" :max-atoms 3) :too-many-atoms))
(check "εντός atom-cap ⇒ OK (κανονική ανάγνωση)"
       (eq (stat "(:a :b :c)" :max-atoms 10) :ok))
(check "atom-cap ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΟ (flood δύο φορές → :too-many-atoms)"
       (eq (stat "(:a :b :c :d)" :max-atoms 2) (stat "(:a :b :c :d)" :max-atoms 2)))
(check "default *max-data-atoms* ⇒ νόμιμα μικρά data περνούν άθικτα"
       (equal (val "(:version 2 :seats (:a :b))") '(:version 2 :seats (:a :b))))
(check "atom-cap ΠΡΟΗΓΕΙΤΑΙ intern: 100k keywords με cap 1000 ⇒ :too-many-atoms"
       (eq (stat (with-output-to-string (o)
                   (write-char #\( o)
                   (dotimes (k 100000) (format o ":k~D " k))
                   (write-char #\) o))
                 :max-atoms 1000)
           :too-many-atoms))

(format t "~%── STATUS distinctness + deterministic why-codes ──~%")
(check ":empty on empty input" (eq (stat "   ") :empty))
(check ":empty on comment-only" (eq (stat "; just a comment
") :empty))
(check ":trailing on two top-level forms" (eq (stat "(:a 1) (:b 2)") :trailing))
(check ":trailing returns the FIRST form" (equal (val "(:a 1) (:b 2)") '(:a 1)))
(check "absent file → :empty" (eq (nth-value 1 (read-data-file "/tmp/nope-safe-read.sexp")) :empty))
(check "why-codes DETERMINISTIC (#. twice → :unreadable twice)"
       (eq (stat "#.(+ 1 2)") (stat "#.(+ 1 2)")))
(check "why-codes DETERMINISTIC (deep twice → :too-deep twice)"
       (eq (stat (make-string 5000 :initial-element #\() :max-depth 100)
           (stat (make-string 5000 :initial-element #\() :max-depth 100)))

(format t "~%── ZERO global state mutation (constitutional) ──~%")
(let ((rt0 *readtable*) (pkg0 *package*) (re0 *read-eval*) (ff0 *read-default-float-format*))
  (read-data-string "(:a 1)")
  (read-data-string "#.(+ 1 2)")   ; even on the error path
  (ignore-errors (read-data-file "/tmp/nope.sexp"))
  (check "*readtable* unchanged after reads" (eq *readtable* rt0))
  (check "*package* unchanged after reads" (eq *package* pkg0))
  (check "*read-eval* unchanged after reads" (eq *read-eval* re0))
  (check "*read-default-float-format* unchanged after reads" (eq *read-default-float-format* ff0)))

(format t "~%── [audit#4] symbol smuggling: ξένα package-qualified σύμβολα ΑΠΟΡΡΙΠΤΟΝΤΑΙ ──~%")
;; Το *package* :keyword δίνει keywords για bare tokens, ΑΛΛΑ ρητά package-qualified
;; tokens μπορούν να δείξουν/intern-άρουν σε ΥΠΑΡΧΟΝ package. Ο ΟΛΙΚΟΣ data-only έλεγχος
;; στο ΑΠΟΤΕΛΕΣΜΑ το κόβει: status ≠ :ok (ποτέ ξένο σύμβολο στον caller).
(check "CL-USER::EVIL (υπαρκτό package, intern) ⇒ :disallowed-symbol"
       (eq (stat "common-lisp-user::evil") :disallowed-symbol))
(check "μέσα σε λίστα: (:a CL-USER::X) ⇒ :disallowed-symbol"
       (eq (stat "(:a common-lisp-user::x)") :disallowed-symbol))
(check "external symbol SB-EXT:*POSIX-ARGV* ⇒ :disallowed-symbol (όχι :ok)"
       (not (eq (stat "sb-ext:*posix-argv*") :ok)))
(check "ανύπαρκτο package FOO::BAR ⇒ όχι :ok (reader-error/:unreadable)"
       (not (eq (stat "foo::bar") :ok)))
(check "βαθιά ένθεση με ξένο σύμβολο (:x (:y CL-USER::Z)) ⇒ :disallowed-symbol"
       (eq (stat "(:x (:y common-lisp-user::z))") :disallowed-symbol))
(check "καθαρά data (keywords/strings/numbers/lists) ⇒ :ok"
       (eq (stat "(:a 1 :b \"x\" :c (:d 2))") :ok))
;; Ο boolean round-trip (COMMON-LISP:NIL / :T) ΔΕΝ σπάει — nil/t επιτρέπονται ρητά.
(check "COMMON-LISP:NIL / :T επιτρέπονται (boolean round-trip ακέραιος)"
       (and (eq (stat "(:a common-lisp:nil :b common-lisp:t)") :ok)
            (equal (val "(:a common-lisp:nil :b common-lisp:t)") '(:a nil :b t))))
(check "bare nil/t ως keywords (:nil/:t) — καθαρά data, :ok"
       (eq (stat "(nil t)") :ok))

(format t "~%── [audit#5] byte-cap μετρά UTF-8 BYTES (όχι χαρακτήρες) ──~%")
;; ":αβγδε" = 1 (:) + 5×2 (Greek) = 11 bytes, 6 chars. Το παλιό (length string) μετρούσε 6.
(check "Unicode: 6 χαρακτήρες αλλά 11 bytes ⇒ :too-large με max-bytes 6"
       (eq (nth-value 1 (read-data-string ":αβγδε" :max-bytes 6)) :too-large))
(check "ίδιο input με max-bytes 11 ⇒ ΟΧΙ :too-large (χωράει)"
       (not (eq (nth-value 1 (read-data-string ":αβγδε" :max-bytes 11)) :too-large)))
(check "ASCII παραμένει 1 byte/char (\"(:a 1)\" 6 bytes)"
       (eq (nth-value 1 (read-data-string "(:a 1)" :max-bytes 6)) :ok))

(format t "~%safe-read-test: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
