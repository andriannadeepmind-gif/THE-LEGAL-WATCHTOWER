;;;; tests/article-number-fidelity-test.lisp
;;;; THE authentic-numbering guarantee: a code's articles MUST keep their real
;;;; numbers (and lettered suffixes) through consolidation — never be renumbered
;;;; 1..N by array position. The real id lives in the clean-JSON title
;;;; («Άρθρο 299 - Ανθρωποκτονία»); %parse-article-title recovers it. A regression
;;;; here silently moves «Άρθρο 299» to the wrong id and destroys every lettered
;;;; article (100Α), breaking citations and proofs.

(in-package :orchestrator.cli)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun id-of (title) (nth-value 0 (%parse-article-title title)))
(defun head-of (title) (nth-value 1 (%parse-article-title title)))

(format t "~%== the real article id is recovered from the title ==~%")
(check "Άρθρο 1 → id 1"            (equal "1"    (id-of "Άρθρο 1 - Καμία ποινή χωρίς νόμο")))
(check "Άρθρο 299 → id 299"        (equal "299"  (id-of "Άρθρο 299 - Ανθρωποκτονία")))
(check "Άρθρο 100Α → id 100Α (lettered preserved)"
       (equal "100Α" (id-of "Άρθρο 100Α - Αναστολή υπό όρο")))
(check "Άρθρο 5 with no heading → id 5" (equal "5" (id-of "Άρθρο 5")))
(check "lowercase suffix is upcased (100α → 100Α)" (equal "100Α" (id-of "Άρθρο 100α")))

(format t "~%== the heading is the text after the dash ==~%")
(check "heading stripped of «Άρθρο N -»" (equal "Ανθρωποκτονία" (head-of "Άρθρο 299 - Ανθρωποκτονία")))
(check "no-heading article → empty heading" (equal "" (head-of "Άρθρο 5")))

(format t "~%== non-article titles fall back (id NIL) ==~%")
(check "a title without «Άρθρο N» → NIL id" (null (id-of "Γενικές διατάξεις")))
(check "«Άρθρο» mentioned mid-text → NIL id" (null (id-of "Κατά το Άρθρο 5 ισχύει")))

(format t "~%== end-to-end: consolidated eids reflect the real numbers ==~%")
;; A synthetic corpus with a GAP (1,5) and a LETTERED article (100Α) — the eids
;; must be art_1, art_5, art_100, art_100Α (never art_1..art_4).
(let* ((bridge :orchestrator.consolidation.bridge)
       (cons :orchestrator.consolidation)
       (triples (loop for o in (list '(("title" . "Άρθρο 1 - Α") ("content" . "x"))
                                     '(("title" . "Άρθρο 5 - Ε") ("content" . "y"))
                                     '(("title" . "Άρθρο 100 - Ρ") ("content" . "z"))
                                     '(("title" . "Άρθρο 100Α - Σ") ("content" . "w")))
                      for n from 1
                      for title = (cdr (assoc "title" o :test #'string=))
                      collect (multiple-value-bind (aid h) (%parse-article-title title)
                                (list (or aid n) h (cdr (assoc "content" o :test #'string=))))))
       (doc (funcall (find-symbol "CONSOLIDATE-CORPUS" bridge) triples nil :id "t" :title "T"))
       (eids (mapcar (find-symbol "PROVISION-EID" cons)
                     (funcall (find-symbol "LEGAL-DOCUMENT-PROVISIONS" cons) doc))))
  (check "eids keep the real numbers + the gap + the lettered article"
         (equal '("art_1" "art_5" "art_100" "art_100Α") eids)))

(format t "~%========================================~%")
(format t "Article-number fidelity tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
