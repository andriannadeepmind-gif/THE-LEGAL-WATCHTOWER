;;;; tests/clean-json-format-test.lisp
;;;; The codes must serialize to the SAME rich shape as the Constitution:
;;;; {title[, date], content[]} where content is a clean paragraph ARRAY (not one
;;;; raw blob) and date is the DD/MM/YYYY publication date. Locks the pure serializer.

(in-package :orchestrator.gov-source)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun contains (needle haystack) (search needle haystack))

(format t "~%== %normalize-date: ISO → DD/MM/YYYY (Constitution form) ==~%")
(check "2019-06-11 → 11/06/2019" (string= "11/06/2019" (%normalize-date "2019-06-11")))
(check "already DD/MM/YYYY passes through" (string= "14/03/1986" (%normalize-date "14/03/1986")))
(check "nil → nil" (null (%normalize-date nil)))

(format t "~%== %split-paragraphs: one raw blob → clean paragraph array ==~%")
(let ((ps (%split-paragraphs (format nil "1. Πρώτη.~%2. Δεύτερη.~%3. Τρίτη."))))
  (check "splits on newline into 3 elements" (= 3 (length ps)))
  (check "first paragraph clean" (string= "1. Πρώτη." (first ps)))
  (check "blank lines dropped"
         (= 2 (length (%split-paragraphs (format nil "Α.~%~%~%Β.")))))
  (check "a list is returned unchanged" (equal '("x") (%split-paragraphs '("x")))))

(format t "~%== articles->json: emits {title,date,content[]} like the Constitution ==~%")
(let ((j (articles->json
          (list (list (cons "title" "Άρθρο 1")
                      (cons "date" "11/06/2019")
                      (cons "content" (list "1. Πρώτη." "2. Δεύτερη.")))))))
  (check "has title"   (contains "\"title\":\"Άρθρο 1\"" j))
  (check "has date"    (contains "\"date\":\"11/06/2019\"" j))
  (check "content is an array of paragraphs"
         (contains "\"content\":[\"1. Πρώτη.\",\"2. Δεύτερη.\"]" j))
  (check "field order title,date,content"
         (< (contains "title" j) (contains "date" j) (contains "content" j))))

(format t "~%== date is omitted cleanly when absent (still valid) ==~%")
(let ((j (articles->json (list (list (cons "title" "Άρθρο 2")
                                     (cons "content" (list "μόνο σώμα")))))))
  (check "no date key when none given" (not (contains "\"date\"" j)))
  (check "still has title+content"
         (and (contains "\"title\":\"Άρθρο 2\"" j)
              (contains "\"content\":[\"μόνο σώμα\"]" j))))

(format t "~%========================================~%")
(format t "Clean-JSON format tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
