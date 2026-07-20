;;;; source/json-emit.lisp
;;;; ============================================================================
;;;; Η ΜΙΑ ΕΔΡΑ: αυθαίρετη Lisp τιμή → ΕΓΓΥΗΜΕΝΑ ΕΓΚΥΡΟ JSON (RFC 8259) ([audit#15])
;;;; ============================================================================
;;;; Ο κριτής (#15): ο «structured JSON logger» έγραφε τιμές με cl:~S μέσα σε χειροποίητα
;;;; braces — symbols (error_type → (type-of e)) έβγαιναν χωρίς εισαγωγικά, NIL→NIL, T→T,
;;;; control chars αδιαφυγάδευτοι ⇒ ΜΗ έγκυρο JSON για machine ingestion.
;;;;
;;;; Αυτή η έδρα εγγυάται ΕΓΚΥΡΟ JSON ΓΙΑ ΚΑΘΕ τιμή: πλήρες string escaping (RFC 8259:
;;;; \" \\ \n \r \t \b \f + κάθε control < 0x20 ως \uXXXX)· real→number· NIL→null· T→true·
;;;; οτιδήποτε άλλο (symbol/keyword/list/struct) → quoted princ-to-string (ΠΑΝΤΑ έγκυρο).
;;;;
;;;; Καθαρή CL (καμία εξάρτηση) — φορτώνεται νωρίς. Στόχος ενοποίησης [ΒΑΣΗ Β/#58]: οι
;;;; χειροποίητοι json-escapers (review-service/mcp-server/ai-corpus-dump/…) μεταναστεύουν
;;;; εδώ. (Το orchestrator.spec:escape-json-string είναι HTML-JSON-LD defense, ΔΙΑΦΟΡΕΤΙΚΟ
;;;; concern — XSS <>& \uXXXX — και δεν καλύπτει control chars/τιμές.)

(defpackage :orchestrator.json-emit
  (:use :cl)
  (:export #:json-escape #:write-json-value #:json-value #:json-object))

(in-package :orchestrator.json-emit)

(defun write-json-escape (s out)
  "Γράφει το S (string) στο OUT με ΠΛΗΡΕΣ RFC 8259 escaping (χωρίς τα περιβάλλοντα \")."
  (declare (type string s))
  (loop for ch across s
        for code = (char-code ch) do
    (cond ((char= ch #\") (write-string "\\\"" out))
          ((char= ch #\\) (write-string "\\\\" out))
          ((char= ch #\Newline) (write-string "\\n" out))
          ((char= ch #\Return) (write-string "\\r" out))
          ((char= ch #\Tab) (write-string "\\t" out))
          ((char= ch #\Backspace) (write-string "\\b" out))
          ((char= ch #\Page) (write-string "\\f" out))
          ((< code #x20) (format out "\\u~4,'0X" code))
          (t (write-char ch out)))))

(defun json-escape (s)
  "Το S με πλήρες JSON escaping (χωρίς περιβάλλοντα εισαγωγικά)."
  (with-output-to-string (out) (write-json-escape (string s) out)))

(defun write-json-value (v out)
  "Γράφει το V στο OUT ως ΕΓΚΥΡΗ JSON τιμή. Ολικό (total) πάνω σε κάθε Lisp τιμή:
   string→\"…\"· integer→ακέραιος· real→number· NIL→null· T→true· symbol/list/άλλο→
   quoted princ-to-string (πάντα έγκυρο· καμία αδιαφυγάδευτη τιμή)."
  (typecase v
    (string  (write-char #\" out) (write-json-escape v out) (write-char #\" out))
    (integer (princ v out))
    (real    (format out "~F" v))
    (null    (write-string "null" out))       ; NIL (και κενή λίστα) ⇒ null
    (t (if (eq v t)
           (write-string "true" out)
           (progn (write-char #\" out)
                  (write-json-escape (princ-to-string v) out)
                  (write-char #\" out))))))

(defun json-value (v)
  "Το V ως string ΕΓΚΥΡΗΣ JSON τιμής."
  (with-output-to-string (out) (write-json-value v out)))

(defun json-object (pairs)
  "PAIRS = λίστα από (key . value). Επιστρέφει ΕΓΚΥΡΟ JSON object string. Τα keys
   γίνονται πάντα JSON strings (escaped)· non-string key ⇒ princ-to-string."
  (with-output-to-string (out)
    (write-char #\{ out)
    (loop for (k . v) in pairs
          for first = t then nil do
      (unless first (write-string ", " out))
      (write-char #\" out)
      (write-json-escape (if (stringp k) k (princ-to-string k)) out)
      (write-char #\" out)
      (write-string ": " out)
      (write-json-value v out))
    (write-char #\} out)))
