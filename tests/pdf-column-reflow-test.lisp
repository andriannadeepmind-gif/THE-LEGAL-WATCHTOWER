;;;; tests/pdf-column-reflow-test.lisp
;;;; The smart extractor must NEVER lose or interleave text, whatever the page
;;;; layout. poppler's get_text reads a two-column ΦΕΚ in a broken order — physical
;;;; rows spanning both columns are read together, so whole articles fall out at
;;;; column/page boundaries (the ΚΠΔ lost ~8 articles; «εκπροσώ-» was cut mid-word).
;;;; reflow-page-text rebuilds the true reading order from the per-character boxes
;;;; with a geometric XY-cut (columns before lines). This locks that logic with
;;;; synthetic glyph boxes — the only part that needs poppler is the box read.

(in-package :orchestrator.pdf-authority)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;;; A tiny page builder: each "cell" is (string x-left y-top), glyphs are laid out
;;; left-to-right with WIDTH/HEIGHT boxes. We then hand reflow the characters in a
;;; chosen (possibly broken) order to simulate what poppler emits.
(defparameter +gw+ 10) (defparameter +gh+ 10)

(defun cell-glyphs (str x y)
  "List of (char x1 y1 x2 y2) for STR starting at (X,Y), one box per char."
  (loop for ch across str for i from 0
        collect (list ch (+ x (* i +gw+)) y (+ x (* i +gw+) +gw+) (+ y +gh+))))

(defun assemble (glyph-lists)
  "Given GLYPH-LISTS already in poppler's (broken) emission order, return
   (values text rects-vector) as reflow-page-text expects."
  (let ((all (apply #'append glyph-lists)))
    (values (coerce (mapcar #'first all) 'string)
            (coerce (mapcar #'rest all) 'vector))))

(defun reflowed-letters (text rects)
  "reflow output with whitespace stripped — the pure reading-order of the glyphs."
  (remove-if (lambda (c) (member c '(#\Space #\Newline #\Return #\Tab)))
             (reflow-page-text text rects)))

(format t "~%== two columns, poppler interleaved row-by-row → restored column-major ==~%")
;; col1: AB / EF   (x 0..20)      col2: CD / GH  (x 100..120)
;; poppler emits physical rows across BOTH columns: ABCD then EFGH.
(multiple-value-bind (text rects)
    (assemble (list (cell-glyphs "AB" 0 0)   (cell-glyphs "CD" 100 0)
                    (cell-glyphs "EF" 0 20)  (cell-glyphs "GH" 100 20)))
  (check "interleaved ABCD/EFGH → reading order ABEFCDGH"
         (string= "ABEFCDGH" (reflowed-letters text rects))))

(format t "~%== a full-width heading above two columns comes FIRST ==~%")
;; heading HEAD spans x 30..70 (crosses the gutter 20..100, so it blocks a vertical
;; cut → the band cut separates it first), body cols as above.
(multiple-value-bind (text rects)
    (assemble (list (cell-glyphs "HEAD" 30 -20)
                    (cell-glyphs "AB" 0 0)  (cell-glyphs "CD" 100 0)
                    (cell-glyphs "EF" 0 20) (cell-glyphs "GH" 100 20)))
  (check "heading then col1 then col2 → HEADABEFCDGH"
         (string= "HEADABEFCDGH" (reflowed-letters text rects))))

(format t "~%== the ΚΠΔ failure mode: an article header lost at the column seam ==~%")
;; Simulate «…εκπροσώ-» at the bottom of col1 and «Άρθρο92» at the top of col2,
;; with poppler interleaving them so the raw stream reads «εκπροσώ-Άρθρο92…».
;; After reflow, col1 (…εκπροσώ-) must come before col2 (Άρθρο92) — recovered.
(multiple-value-bind (text rects)
    (assemble (list (cell-glyphs "εκπ" 0 40)    (cell-glyphs "Αρθ" 100 40)
                    (cell-glyphs "ροσ" 0 60)    (cell-glyphs "ρο9" 100 60)
                    (cell-glyphs "ω"   0 80)    (cell-glyphs "2"   100 80)))
  (check "col1 text fully precedes col2 (no article lost at the seam)"
         (string= "εκπροσωΑρθρο92" (reflowed-letters text rects))))

(format t "~%== a single-column page keeps its order (no spurious column split) ==~%")
;; Lines fill the width (x 0..60); no full-height vertical gap → no column cut.
(multiple-value-bind (text rects)
    (assemble (list (cell-glyphs "ALPHA" 0 0)
                    (cell-glyphs "BETA"  0 20)
                    (cell-glyphs "GAMMA" 0 40)))
  (check "single column stays ALPHABETAGAMMA"
         (string= "ALPHABETAGAMMA" (reflowed-letters text rects))))

(format t "~%== three columns are handled (recursion) ==~%")
(multiple-value-bind (text rects)
    (assemble (list (cell-glyphs "A" 0 0)  (cell-glyphs "B" 100 0) (cell-glyphs "C" 200 0)
                    (cell-glyphs "D" 0 20) (cell-glyphs "E" 100 20)(cell-glyphs "F" 200 20)))
  (check "3 columns → ADBECF"
         (string= "ADBECF" (reflowed-letters text rects))))

(format t "~%== safe fallback: no rectangles → text returned unchanged ==~%")
(check "nil rects → identity"  (string= "ναι όπως είναι"
                                        (reflow-page-text "ναι όπως είναι" nil)))
(check "length-mismatched rects → identity"
       (string= "abc" (reflow-page-text "abc" #((0 0 1 1)))))

(format t "~%== no characters are ever dropped (count is conserved) ==~%")
(multiple-value-bind (text rects)
    (assemble (list (cell-glyphs "AB" 0 0)  (cell-glyphs "CD" 100 0)
                    (cell-glyphs "EF" 0 20) (cell-glyphs "GH" 100 20)))
  (check "every non-whitespace glyph survives the reflow"
         (= (length (remove #\Space text))
            (length (reflowed-letters text rects)))))

(format t "~%========================================~%")
(format t "PDF column-reflow tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
