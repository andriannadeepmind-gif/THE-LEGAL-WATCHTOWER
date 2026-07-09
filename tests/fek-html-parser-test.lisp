;;;; tests/fek-html-parser-test.lisp
;;;; Direct HTML reading: html->text + parse-fek-listing-html. Deterministic.

(in-package :orchestrator.gov-source)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== html->text ==~%")
(check "strips tags" (string= (html->text "<p>Γεια <b>σου</b></p>") "Γεια σου"))
(check "drops script/style"
       (string= (html->text "<style>x{}</style><p>Κείμενο</p><script>y()</script>") "Κείμενο"))
(check "decodes guillemet entities"
       (search "«άρθρο»" (html->text "<i>&laquo;άρθρο&raquo;</i>")))
;; documented behavior (docstring html->text): collapse ΜΕΣΑ στη γραμμή ΜΟΝΟ —
;; block tags/αλλαγές γραμμής διατηρούν τη δομή παραγράφων. Η παλιά προσδοκία
;; flatten «α β γ» ήταν stale — pre-existing CI-unblocker [0036].
(check "collapses whitespace ΜΕΣΑ στη γραμμή· η δομή γραμμών διατηρείται"
       (string= (html->text (format nil "<p>α   β~%~C γ</p>" #\Tab))
                (format nil "α β~%γ")))

(format t "~%== parse-fek-listing-html ==~%")
(let ((entries (parse-fek-listing-html
                "<ul>
                   <li><a href='/fek/4855-2021-A'>Νόμος 4855/2021 (12/11/2021) — ΠΚ</a></li>
                   <li><a href='/fek/4310-2014-A'>Ν. 4310/2014 της 8.12.2014</a></li>
                   <li><a href='/el/help'>Βοήθεια</a></li>
                 </ul>")))
  (check "two law entries (non-law link ignored)" (= 2 (length entries)))
  (check "first number = 4855/2021"
         (string= (cdr (assoc "number" (first entries) :test #'string=)) "4855/2021"))
  (check "first date normalised to ISO"
         (string= (cdr (assoc "publishDate" (first entries) :test #'string=)) "2021-11-12"))
  (check "first url captured"
         (string= (cdr (assoc "url" (first entries) :test #'string=)) "/fek/4855-2021-A"))
  (check "second number = 4310/2014"
         (string= (cdr (assoc "number" (second entries) :test #'string=)) "4310/2014"))
  (check "second date (dotted dd.mm.yyyy) normalised"
         (string= (cdr (assoc "publishDate" (second entries) :test #'string=)) "2014-12-08")))

(check "duplicate law references de-duplicated"
       (= 1 (length (parse-fek-listing-html
                     "<a href='/a'>ν. 5000/2023</a><a href='/b'>ν. 5000/2023 ξανά</a>"))))

(format t "~%========================================~%")
(format t "ΦΕΚ HTML parser tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
