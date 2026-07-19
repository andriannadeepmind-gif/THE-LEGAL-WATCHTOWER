;;;; systems/orchestrator-spec/escaping.lisp
;;;; Centralized escaping functions for all renderers
;;;;
;;;; PHASE 1 - DARPA HARDENING:
;;;; Single source of truth for escape logic
;;;; Greek UTF-8 transparency required

(in-package :orchestrator.spec)

;;; ============================================================
;;; HTML ESCAPING - Security
;;; ============================================================

(defun escape-html (text)
  "Escape HTML special characters to prevent XSS

  Preserves Greek UTF-8 characters (no entity encoding for Greek).

  Escaped characters:
    &  -> &amp;
    <  -> &lt;
    >  -> &gt;
    \"  -> &quot;
    '  -> &#39;"

  (let ((escaped text))
    (setf escaped (cl-ppcre:regex-replace-all "&" escaped "&amp;"))
    (setf escaped (cl-ppcre:regex-replace-all "<" escaped "&lt;"))
    (setf escaped (cl-ppcre:regex-replace-all ">" escaped "&gt;"))
    (setf escaped (cl-ppcre:regex-replace-all "\"" escaped "&quot;"))
    (setf escaped (cl-ppcre:regex-replace-all "'" escaped "&#39;"))
    escaped))

;;; ============================================================
;;; TURTLE ESCAPING - RDF Canonicalization
;;; ============================================================

(defun escape-turtle-string (text)
  "Escape special characters in Turtle string literals

  Preserves Greek UTF-8 characters (no Unicode escape for Greek).

  Escaped characters:
    \"  -> \\\"
    \\  -> \\\\
    \\n -> \\n (newline)
    \\r -> \\r (carriage return)
    \\t -> \\t (tab)

  NIL → NIL (total function): μια απούσα τιμή escape-άρει σε απούσα τιμή,
  ΟΜΟΙΟΜΟΡΦΑ με escape-html/escape-json-string. Χωρίς αυτό, ένα nil optional
  πεδίο στο RDF path (loop … across nil) θα προκαλούσε TYPE-ERROR crash ενώ το
  ίδιο nil στο HTML path περνά αθόρυβα — ασύμμετρη, λανθάνουσα αστοχία."

  (when text
   (with-output-to-string (s)
    (loop for char across text
          do (case char
               (#\" (write-string "\\\"" s))
               (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s))
               (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s))
               (#\Backspace (write-string "\\b" s))
               (#\Page (write-string "\\f" s))
               (otherwise (if (< (char-code char) #x20)
                              (format s "\\u~4,'0x" (char-code char))
                              (write-char char s))))))))

;;; ============================================================
;;; JSON ESCAPING - Defense-in-Depth for JSON-LD in HTML
;;; ============================================================

(defun escape-json-string (text)
  "Escape string for safe embedding in JSON-LD (defense-in-depth XSS prevention)

  Escapes < and > as Unicode escape sequences to prevent XSS in JSON strings
  embedded in HTML script tags. While JSON-LD in script tags is safe, this
  provides defense-in-depth against parser vulnerabilities.

  Escaped characters:
    \\  -> \\\\
    \"  -> \\\"
    <  -> \\u003c
    >  -> \\u003e
    &  -> \\u0026"

  (let ((escaped text))
    ;; Escape backslash first (so we don't double-escape)
    (setf escaped (cl-ppcre:regex-replace-all "\\\\" escaped "\\\\\\\\"))
    ;; Escape quote
    (setf escaped (cl-ppcre:regex-replace-all "\"" escaped "\\\\\""))
    ;; Escape < and > as Unicode sequences for XSS defense-in-depth
    (setf escaped (cl-ppcre:regex-replace-all "<" escaped "\\\\u003c"))
    (setf escaped (cl-ppcre:regex-replace-all ">" escaped "\\\\u003e"))
    ;; Escape & as Unicode sequence
    (setf escaped (cl-ppcre:regex-replace-all "&" escaped "\\\\u0026"))
    escaped))

(defun json-string-escape (s)
  "Η ΜΙΑ έδρα: escape ενός scalar σε ασφαλές JSON string BODY (χωρίς τα εξωτερικά
   quotes). Ρητά \\\" \\\\ \\n \\r \\t \\b \\f· κάθε άλλος control char (<0x20) →
   \\uXXXX (πεζά hex). Ό,τι δεν είναι string περνά από princ-to-string· nil → «».

   ΔΙΑΚΡΙΤΗ έννοια από την escape-json-string παραπάνω: εκείνη είναι XSS
   defense-in-depth για JSON-LD μέσα σε HTML (escapeει <>& αλλά ΟΧΙ control
   chars), ΟΧΙ γενικός JSON escaper. Αυτή εδώ είναι η γενική έδρα που καταναλώνουν
   οι deterministic JSON emitters (intelligence/citation/cli scalar)."
  (with-output-to-string (o)
    (loop for c across (princ-to-string (or s "")) do
      (case c (#\" (write-string "\\\"" o)) (#\\ (write-string "\\\\" o))
              (#\Newline (write-string "\\n" o)) (#\Return (write-string "\\r" o))
              (#\Tab (write-string "\\t" o)) (#\Backspace (write-string "\\b" o))
              (#\Page (write-string "\\f" o))
              (t (if (< (char-code c) #x20)
                     (format o "\\u~4,'0x" (char-code c))
                     (write-char c o)))))))
