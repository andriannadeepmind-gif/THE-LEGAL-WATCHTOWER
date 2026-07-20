;;;; tests/json-emit-test.lisp
;;;; ============================================================================
;;;; [audit#15] Η ΜΙΑ έδρα value→JSON παράγει ΕΓΓΥΗΜΕΝΑ έγκυρο JSON (RFC 8259)
;;;; ============================================================================
;;;; Ο κριτής: ο logger έγραφε τιμές με ~S ⇒ symbols/nil/t/control-chars έσπαγαν το JSON.
;;;; Αυτό κλειδώνει ότι κάθε τιμή γίνεται typed JSON. Self-contained (φορτώνει μόνο
;;;; source/json-emit.lisp, καθαρή CL), runnable χωρίς full build.

(let* ((here (or *load-truename* *load-pathname*))
       (seat (merge-pathnames "../source/json-emit.lisp"
                              (make-pathname :directory (pathname-directory here)))))
  (unless (probe-file seat)
    (format t "~%  SKIP — source/json-emit.lisp απών.~%") (sb-ext:exit :code 0))
  (handler-bind ((warning #'muffle-warning)) (load seat)))

(defpackage :json-emit-test (:use :cl :orchestrator.json-emit))
(in-package :json-emit-test)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%── value serialization (typed, έγκυρο JSON) ──~%")
(check "string ⇒ quoted" (string= "\"abc\"" (json-value "abc")))
(check "integer ⇒ numeric" (string= "42" (json-value 42)))
(check "NIL ⇒ null (όχι NIL)" (string= "null" (json-value nil)))
(check "T ⇒ true (όχι T)" (string= "true" (json-value t)))
(check "keyword ⇒ quoted string (princ ⇒ \"FOO\", έγκυρο JSON, όχι bare)"
       (string= "\"FOO\"" (json-value :foo)))
(check "symbol ⇒ quoted string (ΤΟ κρίσιμο: error_type=(type-of e))"
       (string= "\"SIMPLE-ERROR\"" (json-value 'simple-error)))
(check "λίστα ⇒ quoted (πάντα έγκυρο, καμία αδιαφυγάδευτη τιμή)"
       (char= #\" (char (json-value '(1 2)) 0)))

(format t "~%── string escaping (RFC 8259, incl. control chars) ──~%")
(check "διπλό εισαγωγικό ⇒ \\\"" (string= "a\\\"b" (json-escape "a\"b")))
(check "backslash ⇒ \\\\" (string= "a\\\\b" (json-escape "a\\b")))
(check "newline ⇒ \\n (όχι literal)" (string= "a\\nb" (json-escape (format nil "a~Cb" #\Newline))))
(check "tab ⇒ \\t" (string= "a\\tb" (json-escape (format nil "a~Cb" #\Tab))))
(check "return ⇒ \\r" (string= "a\\rb" (json-escape (format nil "a~Cb" #\Return))))
(check "control char (0x01) ⇒ \\u0001" (string= "\\u0001" (json-escape (string (code-char 1)))))
(check "control char (0x1F) ⇒ \\u001F" (string= "\\u001F" (json-escape (string (code-char #x1f)))))
(check "κανονικό unicode μένει ως έχει (ελληνικά)" (string= "νόμος" (json-escape "νόμος")))

(format t "~%── json-object (το σχήμα του logger) ──~%")
(check "object με string keys + escaped values"
       (string= "{\"level\": \"info\", \"n\": 3}"
                (json-object '(("level" . "info") ("n" . 3)))))
(check "object: symbol value ⇒ quoted (το bug του #15)"
       (string= "{\"error_type\": \"SIMPLE-ERROR\"}"
                (json-object '(("error_type" . simple-error)))))
(check "object: nil value ⇒ null"
       (string= "{\"x\": null}" (json-object '(("x" . nil)))))
(check "object: control char σε value ⇒ escaped (δεν σπάει το JSON)"
       (string= "{\"m\": \"a\\nb\"}"
                (json-object (list (cons "m" (format nil "a~Cb" #\Newline))))))
(check "κενό object" (string= "{}" (json-object '())))

;; ── ΑΝΤΙΠΑΡΑΘΕΣΗ με το ΠΑΛΙΟ ~S (τεκμηρίωση του bug) ──
(format t "~%── απόδειξη: το παλιό ~~S ΕΣΠΑΓΕ το JSON ──~%")
(check "παλιό ~S σε symbol ⇒ bare (άκυρο JSON)· νέο ⇒ quoted"
       (and (string= "SIMPLE-ERROR" (format nil "~S" 'simple-error))    ; bare (invalid)
            (string= "\"SIMPLE-ERROR\"" (json-value 'simple-error))))   ; quoted (valid)
(check "παλιό ~S σε NIL ⇒ NIL (άκυρο)· νέο ⇒ null"
       (and (string= "NIL" (format nil "~S" nil))
            (string= "null" (json-value nil))))

(format t "~%json-emit: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
