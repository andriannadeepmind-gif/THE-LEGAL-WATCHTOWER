;;;; tests/parliament-html-wiring-test.lisp
;;;; The Constitution (syntagma) materialises from the Hellenic Parliament HTML
;;;; (source.format: html). That path was broken by TWO wiring bugs:
;;;;   1. %html->articles called parse-parliament-html with ONE arg, but it
;;;;      required (html source-url) → "invalid number of arguments: 1".
;;;;   2. the adapter returns plists (:num :title :content …), but the serializer
;;;;      expects {"title","content"} alists → articles silently dropped.
;;;; This pins the fixed chain on synthetic Parliament-style HTML (no network).

(in-package :orchestrator.gov-source)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *html*
  "<html><body>
<p>Άρθρον 1</p>
<p>Η Ελλάδα είναι Προεδρευόμενη Κοινοβουλευτική Δημοκρατία.</p>
<p>Άρθρον 2</p>
<p>Ο σεβασμός και η προστασία της αξίας του ανθρώπου αποτελούν πρωταρχική υποχρέωση της Πολιτείας.</p>
</body></html>")

(format t "~%== arity: parse-parliament-html accepts 1 arg (was the bug) ==~%")
(check "parse-parliament-html callable with HTML only"
       (let ((fn (find-symbol "PARSE-PARLIAMENT-HTML" :orchestrator.engine.sbcl)))
         (and fn (fboundp fn) (progn (funcall fn *html*) t))))

(format t "~%== chain: source-content->articles → canonical alists ==~%")
(let ((arts (source-content->articles *html* :html
                                      "https://www.hellenicparliament.gr/...")))
  (check "extracted 2 articles" (= 2 (length arts)))
  (check "each is an alist with STRING keys (not plist)"
         (and arts (assoc "title" (first arts) :test #'string=)
                   (assoc "content" (first arts) :test #'string=)))
  (check "title built as «Άρθρο 1 …»"
         (search "Άρθρο 1" (or (cdr (assoc "title" (first arts) :test #'string=)) "")))
  (check "content carries the real legal text"
         (search "Προεδρευόμενη" (or (cdr (assoc "content" (first arts) :test #'string=)) "")))
  (format t "~%== serializer: articles->json emits valid clean-json ==~%")
  (let ((j (articles->json arts)))
    (check "starts as a JSON array" (and (plusp (length j)) (char= #\[ (char j 0))))
    (check "carries Άρθρο 1 + its text"
           (and (search "Άρθρο 1" j) (search "Προεδρευόμενη" j)))
    (check "carries Άρθρο 2 + its text"
           (and (search "Άρθρο 2" j) (search "αξίας του ανθρώπου" j)))))

(format t "~%========================================~%")
(format t "Parliament-HTML wiring tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
