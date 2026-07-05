;;;; tests/constitution-crawler-test.lisp
;;;; The Σύνταγμα lives on the Hellenic-Parliament site as ~120 sub-pages
;;;; (/…/syntagma/article-N/). This pins the real, no-band-aid Lisp crawler:
;;;;   · extract-constitution-article-links — the article links from the index
;;;;   · parse-constitution-article-page    — «<h1>Άρθρο N: (τίτλος)</h1>» + <br/> body,
;;;;       with the page's Latin homoglyphs (Tο, Eλλάδας) normalised to Greek
;;;;   · crawl-constitution                 — fetch (injected) → parse → ordered maps
;;;; Markup is the EXACT shape served by the live site.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;; the real sub-page shape (note Latin T/E/K/O homoglyphs and the &#39; before Άρθρο)
(defparameter *page1*
  "<html><body><h2>ΜΕΡΟΣ ΠΡΩΤΟ &gt; ΤΜΗΜΑ Α΄</h2><h1>&#39;Αρθρο 1: (Μορφή του πολιτεύματος)</h1><p>1. Tο πολίτευμα της Eλλάδας είναι Προεδρευόμενη Kοινοβουλευτική Δημοκρατία.<br />2. Θεμέλιο του πολιτεύματος είναι η λαϊκή κυριαρχία.<br />3. Όλες οι εξουσίες πηγάζουν από το Λαό.</p><a href=\"/x/syntagma/article-2/\">Επόμενο &gt;&gt;</a> <a href=\"/x\">Δείτε όλα τα άρθρα του συντάγματος &gt;&gt;</a> <a href=\"/x\">Επιστροφή &gt;&gt;</a><div class=\"nav\">end</div></body></html>")
(defparameter *page2*
  "<h1>Άρθρο 2: (Πρωταρχικές υποχρεώσεις)</h1><p>1. O σεβασμός και η προστασία της αξίας του ανθρώπου αποτελούν πρωταρχική υποχρέωση.</p><h2>ΤΜΗΜΑ Β΄</h2>")
(defparameter *index*
  "<ul><li><a name=\"a1\" href=\"/vouli/syntagma/article-1/\"><b>Άρθρο 1</b></a></li>
   <li><a href=\"/vouli/syntagma/article-2/\"><b>Άρθρο 2</b></a></li>
   <li><a href=\"/vouli/syntagma/article-1/\">duplicate link</a></li></ul>")

(defun mock-fetch (url)
  (cond ((search "article-1/" url) *page1*)
        ((search "article-2/" url) *page2*)
        (t nil)))

(format t "~%== index → article links (deduped, in order) ==~%")
(let ((links (extract-constitution-article-links *index*)))
  (check "two distinct links" (= 2 (length links)))
  (check "article-1 then article-2"
         (and (search "article-1/" (first links)) (search "article-2/" (second links)))))

(format t "~%== parse one sub-page (header, paragraphs, homoglyphs) ==~%")
(multiple-value-bind (num title paras) (parse-constitution-article-page *page1*)
  (check "number = 1" (eql 1 num))
  (check "title = «Μορφή του πολιτεύματος»" (equal "Μορφή του πολιτεύματος" title))
  (check "three paragraphs (navigation links excluded)" (= 3 (length paras)))
  (check "no «>>» navigation chrome leaked"
         (notany (lambda (p) (search ">>" p)) paras))
  (check "no nav phrase «Επόμενο/Επιστροφή/Δείτε όλα» leaked"
         (notany (lambda (p) (or (search "Επόμενο" p) (search "Επιστροφή" p)
                                 (search "Δείτε όλα" p))) paras))
  (check "Latin homoglyphs normalised (Tο→Το, Eλλάδας→Ελλάδας, Kοιν→Κοιν)"
         (let ((p (first paras)))
           (and (search "Το πολίτευμα" p) (search "Ελλάδας" p) (search "Κοινοβουλευτική" p)
                (not (find #\T p)) (not (find #\E p)) (not (find #\K p)))))  ; no Latin caps left
  (check "paragraph 2 present" (search "λαϊκή κυριαρχία" (second paras))))

(format t "~%== full crawl (injected fetch) ==~%")
(let ((arts (crawl-constitution *index* #'mock-fetch)))
  (check "crawled 2 articles" (= 2 (length arts)))
  (check "ordered + titled: «Άρθρο 1 - Μορφή του πολιτεύματος»"
         (equal "Άρθρο 1 - Μορφή του πολιτεύματος"
                (cdr (assoc "title" (first arts) :test #'string=))))
  (check "article 1 content has 3 paragraphs"
         (= 3 (length (cdr (assoc "content" (first arts) :test #'string=)))))
  (check "article 2 present and clean"
         (let ((p (cdr (assoc "content" (second arts) :test #'string=))))
           (and p (search "σεβασμός" (first p)) (not (find #\O (first p))))))  ; «O σεβασμός» → «Ο»
  ;; a dead link is skipped, not fatal
  (check "a fetch returning NIL is skipped, crawl still returns the rest"
         (= 1 (length (crawl-constitution
                       "<a href=\"/x/syntagma/article-1/\"></a><a href=\"/x/syntagma/article-9/\"></a>"
                       (lambda (u) (when (search "article-1/" u) *page1*)))))))

(format t "~%========================================~%")
(format t "Constitution crawler tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
