;;;; tests/json-escape-seat-test.lisp
;;;; ============================================================================
;;;; REGRESSION LOCK — Η ΜΙΑ έδρα JSON string escaping (orchestrator.spec)
;;;; ============================================================================
;;;; Κλειδώνει τη συμπεριφορά της ενοποιημένης json-string-escape που αντικατέστησε
;;;; 3 ταυτόσημες τοπικές έδρες (intelligence/citation/cli). Επίσης φυλάει τη
;;;; ΔΙΑΚΡΙΣΗ από την escape-json-string (XSS/HTML defense): η γενική έδρα escapeει
;;;; control chars αλλά ΟΧΙ <>&· η XSS έδρα το αντίστροφο. Self-contained· exit 0/1.

(in-package :orchestrator.spec)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== Η ΜΙΑ έδρα json-string-escape ==~%")

(check "quote → \\\""
       (string= "a\\\"b" (json-string-escape "a\"b")))
(check "backslash → \\\\"
       (string= "a\\\\b" (json-string-escape "a\\b")))
(check "newline → \\n, tab → \\t, return → \\r"
       (string= "\\n\\t\\r" (json-string-escape (format nil "~C~C~C" #\Newline #\Tab #\Return))))
(check "backspace → \\b, formfeed → \\f"
       (string= "\\b\\f" (json-string-escape (format nil "~C~C" #\Backspace #\Page))))
;; Διατηρημένη συμπεριφορά (byte-identical με τις 3 παλιές έδρες): control chars
;; → \uXXXX με ΚΕΦΑΛΑΙΑ hex γράμματα (~4,'0x χωρίς ~(~) downcase). Έγκυρο JSON.
(check "control char <0x20 → \\uXXXX (κεφαλαία hex, όπως οι αρχικές έδρες)"
       (string= "\\u0001\\u001F" (json-string-escape (format nil "~C~C" (code-char 1) (code-char 31)))))
(check "nil → «» (κενό), non-string → princ-to-string"
       (and (string= "" (json-string-escape nil))
            (string= "42" (json-string-escape 42))))
(check "πλ. unicode πάνω από 0x20 μένει ΑΝΕΠΑΦΟ (δεν escapeεται)"
       (string= "άρθρο 5Α" (json-string-escape "άρθρο 5Α")))

;; Η ΔΙΑΚΡΙΣΗ: η γενική έδρα ΔΕΝ αγγίζει <>& (αυτό είναι δουλειά της XSS έδρας).
(check "json-string-escape ΔΕΝ escapeει <>& (διακριτή από escape-json-string)"
       (string= "<a>&" (json-string-escape "<a>&")))
(check "escape-json-string (XSS) escapeει <>& αλλά ΟΧΙ control chars"
       (and (search "\\u003c" (escape-json-string "<"))
            (search (string #\Newline) (escape-json-string (string #\Newline)))))

(format t "~%JSON escape seat tests: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
