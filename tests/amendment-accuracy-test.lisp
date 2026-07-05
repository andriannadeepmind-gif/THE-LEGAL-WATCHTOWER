;;;; tests/amendment-accuracy-test.lisp
;;;; ============================================================================
;;;; AMENDMENT EXTRACTION — ACCURACY HARNESS (honest measurement)
;;;; ============================================================================
;;;; Measures the extractor against realistic Greek nomotechnic formulas. Two
;;;; sections:
;;;;   GUARANTEED  — forms we commit to; a regression here FAILS the build.
;;;;   COVERAGE    — harder forms; reported as a transparent accuracy %, never
;;;;                 hidden. This is the honest picture of what is/ isn't covered.
;;;; ============================================================================

(in-package :orchestrator.amendment-extractor)

(defvar *g-pass* 0) (defvar *g-fail* 0)     ; guaranteed
(defvar *c-pass* 0) (defvar *c-fail* 0)     ; coverage

(defun ops-of (kind ops) (loop for o in ops when (eq (getf o :op) kind) collect (getf o :target)))

(defmacro guaranteed (name form)
  `(if ,form (progn (incf *g-pass*) (format t "  ok   ~A~%" ,name))
       (progn (incf *g-fail*) (format t "  FAIL ~A~%" ,name))))

(defmacro coverage (name form)
  `(if (ignore-errors ,form)
       (progn (incf *c-pass*) (format t "  ✓ covered   ~A~%" ,name))
       (progn (incf *c-fail*) (format t "  · gap       ~A~%" ,name))))

(format t "~%========== GUARANTEED FORMS (must pass) ==========~%")

(guaranteed "article replace + new text"
  (let ((o (extract-operations "Το άρθρο 5 αντικαθίσταται ως εξής: «Νέο κείμενο 5.»")))
    (and (equal (ops-of :replace-text o) '("art_5"))
         (string= (getf (first o) :text) "Νέο κείμενο 5."))))

(guaranteed "article replace, with intervening law citation"
  (equal (ops-of :replace-text
                 (extract-operations "Το άρθρο 5 του ν. 4619/2019 (Α' 95) αντικαθίσταται ως εξής: «Χ.»"))
         '("art_5")))

(guaranteed "article repeal — άρθρο Ν καταργείται"
  (equal (ops-of :repeal (extract-operations "Το άρθρο 7 του Κώδικα καταργείται.")) '("art_7")))

(guaranteed "article repeal — καταργείται το άρθρο Ν"
  (equal (ops-of :repeal (extract-operations "Καταργείται το άρθρο 9 του νόμου.")) '("art_9")))

(guaranteed "generic amendment -> mark-amended"
  (equal (ops-of :mark-amended (extract-operations "Το άρθρο 3 τροποποιείται.")) '("art_3")))

(guaranteed "structural 'Άρθρο 2.' header NOT mistaken for a reference"
  ;; The verb's subject is art_4; the header 'Άρθρο 2.' must not be repealed.
  (let ((o (extract-operations "Άρθρο 2. Το άρθρο 4 του Κώδικα καταργείται.")))
    (equal (ops-of :repeal o) '("art_4"))))

(guaranteed "no false positives on bare numbers"
  (null (extract-operations "Το ποσό 10/2 και η αναλογία 3/4 δεν αφορούν άρθρα.")))

(guaranteed "capitalised sentence-initial verb"
  (equal (ops-of :repeal (extract-operations "ΚΑΤΑΡΓΕΙΤΑΙ το άρθρο 12.")) '("art_12")))

(format t "~%========== COVERAGE (harder real forms — honest %) ==========~%")

(coverage "paragraph-level replace (παρ. 2 του άρθρου 5)"
  (member "art_5__para_2"
          (loop for o in (extract-operations
                          "Η παράγραφος 2 του άρθρου 5 αντικαθίσταται ως εξής: «Νέα παρ. 2.»")
                collect (getf o :target)) :test #'string=))

(coverage "paragraph repeal (η παρ. 3 του άρθρου 5 καταργείται)"
  (member "art_5__para_3"
          (loop for o in (extract-operations "Η παρ. 3 του άρθρου 5 καταργείται.")
                collect (getf o :target)) :test #'string=))

(coverage "addition of a paragraph (προστίθεται παράγραφος)"
  (some (lambda (o) (eq (getf o :op) :insert))
        (extract-operations "Στο άρθρο 5 προστίθεται παράγραφος 6 ως εξής: «Νέα παρ.»")))

(coverage "new article insertion (προστίθεται άρθρο 5Α)"
  (some (lambda (o) (eq (getf o :op) :insert))
        (extract-operations "Μετά το άρθρο 5 προστίθεται άρθρο 5Α ως εξής: «Νέο άρθρο.»")))

(coverage "whole-law repeal (ο ν. 4619/2019 καταργείται)"
  (extract-operations "Ο ν. 4619/2019 καταργείται στο σύνολό του."))

(coverage "perifrastic replacement (η περ. α' της παρ. 1 του άρθρου 5)"
  (extract-operations "Η περίπτωση α' της παραγράφου 1 του άρθρου 5 αντικαθίσταται ως εξής: «Α.»"))

(coverage "multi-article single sentence (άρθρα 5 και 6 καταργούνται)"
  (= 2 (length (ops-of :repeal (extract-operations "Τα άρθρα 5 και 6 καταργούνται.")))))

(format t "~%========================================~%")
(let* ((cov-total (+ *c-pass* *c-fail*))
       (pct (if (plusp cov-total) (/ (* 100.0 *c-pass*) cov-total) 0)))
  (format t "GUARANTEED: ~D/~D passed~%" *g-pass* (+ *g-pass* *g-fail*))
  (format t "COVERAGE  : ~D/~D harder forms (~,1F%)~%" *c-pass* cov-total pct)
  (format t "========================================~%")
  ;; The build fails ONLY on a guaranteed regression; coverage is informational.
  (sb-ext:exit :code (if (zerop *g-fail*) 0 1)))
