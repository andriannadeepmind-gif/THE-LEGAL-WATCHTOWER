;;;; tests/fek-rubric-test.lisp
;;;; The ΦΕΚ parser must capture each article's πλαγιότιτλος (marginal heading)
;;;; into the TITLE — exactly as the Isokratis path does for the Civil Code
;;;; ("Άρθρο 1 - Πηγές του δικαίου") — instead of fusing it into the body. The
;;;; capture is DEFERRED one line so a wrapped first body sentence is never
;;;; mistaken for a heading (the zero-false-title guarantee).
;;;;
;;;; Cases:
;;;;   (1) rubric + numbered paragraphs   → rubric promoted, kept out of body
;;;;   (2) rubric + single fused sentence → rubric promoted, NO fusion
;;;;   (3) repealed sole line "Καταργήθηκε." → body, NOT a fabricated title
;;;;   (4) wrapped body (lowercase next)  → NO rubric, body fused back together
;;;;   (5) colon lead-in "…δικαστήρια:"   → body, NOT a title

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun art1 (text)
  "Parse TEXT and return its first article."
  (first (parse-fek-text text)))

(defun para-texts (art)
  (mapcar #'paragraph-text (article-paragraphs art)))

(defun body-of (art)
  (format nil "~{~A~^ ~}" (para-texts art)))

;;; (1) rubric followed by numbered paragraphs — the art_2 shape
(format t "~%== (1) rubric + numbered paragraphs ==~%")
(let ((a (art1 (format nil "Άρθρο 2~%Αναδρομική ισχύς του ηπιότερου νόμου~%~
                            1. Αν ίσχυσαν περισσότερες διατάξεις εφαρμόζεται η ευμενέστερη.~%~
                            2. Αν νεότερος νόμος χαρακτήρισε την πράξη ανέγκλητη παύει η ποινή."))))
  (check "rubric captured"        (equal "Αναδρομική ισχύς του ηπιότερου νόμου" (article-rubric a)))
  (check "title carries rubric"   (search "Αναδρομική ισχύς του ηπιότερου νόμου" (resolve-article-title a)))
  (check "two numbered paragraphs" (= 2 (length (article-paragraphs a))))
  (check "rubric NOT in body"     (not (search "Αναδρομική ισχύς" (body-of a))))
  (check "body keeps paragraph 1" (search "ευμενέστερη" (body-of a))))

;;; (2) rubric fused with a single unnumbered sentence — the art_1 shape
(format t "~%== (2) rubric + single fused sentence ==~%")
(let ((a (art1 (format nil "Άρθρο 1~%Καμία ποινή χωρίς νόμο~%~
                            Έγκλημα δεν υπάρχει χωρίς νόμο που ίσχυε πριν από την τέλεση της πράξης."))))
  (check "rubric captured"        (equal "Καμία ποινή χωρίς νόμο" (article-rubric a)))
  (check "title carries rubric"   (search "Καμία ποινή χωρίς νόμο" (resolve-article-title a)))
  (check "body is the sentence"   (search "Έγκλημα δεν υπάρχει" (body-of a)))
  (check "rubric NOT fused in body" (not (search "Καμία ποινή" (body-of a)))))

;;; (3) a repealed article whose only line ends with a period → body, not title
(format t "~%== (3) repealed sole line ==~%")
(let ((a (art1 (format nil "Άρθρο 3~%Καταργήθηκε."))))
  (check "no rubric fabricated"   (null (article-rubric a)))
  (check "body holds the text"    (search "Καταργήθηκε" (body-of a))))

;;; (4) wrapped body: first line heading-shaped, but next line is lowercase
;;;     continuation → it was body, NOT a heading. Must not fabricate a title.
(format t "~%== (4) wrapped body (no false rubric) ==~%")
(let ((a (art1 (format nil "Άρθρο 7~%Όποιος με πρόθεση σκότωσε άλλον τιμωρείται~%~
                            με ισόβια κάθειρξη ή με πρόσκαιρη κάθειρξη."))))
  (check "no rubric captured"     (null (article-rubric a)))
  (check "body fused back together"
         (let ((b (body-of a))) (and (search "τιμωρείται" b) (search "ισόβια κάθειρξη" b))))
  (check "title falls back to bare article"
         (let ((title (resolve-article-title a))) (or (null title) (zerop (length title))))))

;;; (5) colon lead-in introducing a list → body, not a heading
(format t "~%== (5) colon lead-in ==~%")
(let ((a (art1 (format nil "Άρθρο 8~%Ποινική δικαιοδοσία ασκούν τα εξής δικαστήρια:~%~
                            1. Το Μικτό Ορκωτό Δικαστήριο."))))
  (check "no rubric captured"     (null (article-rubric a)))
  (check "lead-in stays in body"  (search "εξής δικαστήρια" (body-of a))))

;;; end-to-end: article-to-iir formats "Άρθρο N - <rubric>"
(format t "~%== (6) IIR title formatting ==~%")
(let* ((a (art1 (format nil "Άρθρο 2~%Αναδρομική ισχύς του ηπιότερου νόμου~%~
                             1. Αν ίσχυσαν περισσότερες διατάξεις εφαρμόζεται η ευμενέστερη.")))
       (iir (article-to-iir a "test")))
  (check "IIR title is 'Άρθρο 2 - <rubric>'"
         (search "Άρθρο 2 - Αναδρομική ισχύς" (orchestrator.model:article-title iir)))
  (check "IIR content excludes the rubric"
         (not (search "Αναδρομική ισχύς" (orchestrator.model:article-content iir)))))

(format t "~%========================================~%")
(format t "ΦΕΚ rubric (πλαγιότιτλος→title) tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
