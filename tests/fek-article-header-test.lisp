;;;; tests/fek-article-header-test.lisp
;;;; The ΦΕΚ article-header matcher must recognise BOTH real-world forms seen in
;;;; the gazette PDFs — "Άρθρο 5" (number alone, poinikos) and the inline-title
;;;; "Άρθρο 1. - Ποινικά Δικαστήρια." (kpoinikis) — WITHOUT misfiring on inline
;;;; cross-references ("κατά το άρθρο 489"), repeal ranges ("Άρθρα 3 - 4"), or
;;;; prose that merely starts with a number. Locks the fix that made kpoinikis
;;;; parse from 0 articles while keeping poinikos intact.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun num-of (line) (let ((r (match-article line))) (and r (first r))))
(defun suf-of (line) (let ((r (match-article line))) (and r (second r))))

(format t "~%== headers that MUST match ==~%")
(check "Άρθρο 5 (number alone)"            (equal "5"   (num-of "Άρθρο 5")))
(check "Άρθρο 100Α (lettered)"             (and (equal "100" (num-of "Άρθρο 100Α"))
                                                (equal "Α"   (suf-of "Άρθρο 100Α"))))
(check "Άρθρο 1. - Ποινικά Δικαστήρια."    (equal "1"   (num-of "Άρθρο 1. - Ποινικά Δικαστήρια.")))
(check "Άρθρο 2. - Εξαιρέσεις"             (equal "2"   (num-of "Άρθρο 2. - Εξαιρέσεις")))
(check "**Άρθρο 5Α (bold pdf marker)"      (equal "5"   (num-of "**Άρθρο 5Α")))

(format t "~%== lines that MUST NOT match (no false headers) ==~%")
(check "inline cross-reference"            (null (match-article "κατά το άρθρο 489.")))
(check "repeal range «Άρθρα 3 - 4»"        (null (match-article "Άρθρα 3 - 4")))
(check "number followed by prose"          (null (match-article "Άρθρο 489 ορίζει τα εξής")))
(check "plain body line"                   (null (match-article "Ποινική δικαιοδοσία ασκούν")))

(format t "~%========================================~%")
(format t "FEK article-header tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
