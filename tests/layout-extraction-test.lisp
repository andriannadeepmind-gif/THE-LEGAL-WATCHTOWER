;;;; tests/layout-extraction-test.lisp
;;;; The pure region-filter that removes page header/footer chrome BY POSITION.
;;;; (The poppler rectangle read is exercised in the container; the algorithm
;;;;  that decides what to keep is exercised here, deterministically.)

(in-package :orchestrator.pdf-authority)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;; A page of height 100. Build text + a rectangle (x1 y1 x2 y2) per character.
;; y grows downward: header ~ y<6, footer ~ y>94, body in between.
(defun rects-at (string y)
  "One rect per char of STRING, all on the same horizontal line at vertical Y."
  (coerce (loop for i below (length string)
                collect (list (* i 5.0) (float y) (+ (* i 5.0) 4.0) (+ y 3.0)))
          'simple-vector))

(format t "~%== region filtering (height = 100) ==~%")
(let* ((header "ΟΘΟΝΗ")               ; at the very top
       (body   "Άρθρο 1 κείμενο")     ; in the body
       (footer "www.dsanet.gr 1/247") ; at the very bottom
       (text (concatenate 'string header body footer))
       (rects (concatenate 'simple-vector
                           (rects-at header 1)     ; y=1 → header band
                           (rects-at body 50)      ; y=50 → body
                           (rects-at footer 96)))) ; y=96 → footer band
  (let ((out (filter-text-by-region text rects 100.0 :header-frac 0.06 :footer-frac 0.06)))
    (check "body text kept" (search "Άρθρο 1 κείμενο" out))
    (check "header 'ΟΘΟΝΗ' dropped" (not (search "ΟΘΟΝΗ" out)))
    (check "footer 'dsanet' dropped" (not (search "dsanet" out)))
    (check "footer page-number dropped" (not (search "1/247" out)))
    (check "same length (dropped → spaces, no merge)" (= (length out) (length text)))))

(format t "~%== safety: no rects / misaligned → unchanged ==~%")
(check "nil rects → text unchanged" (string= "abc" (filter-text-by-region "abc" nil 100.0)))
(check "misaligned rects → text unchanged"
       (string= "abcd" (filter-text-by-region "abcd" (rects-at "ab" 50) 100.0)))
(check "zero height → unchanged" (string= "x" (filter-text-by-region "x" (rects-at "x" 1) 0.0)))

(format t "~%== body near edges stays in (conservative margins) ==~%")
(let* ((text "ΚΕΙΜΕΝΟ")
       (rects (rects-at "ΚΕΙΜΕΝΟ" 10))) ; y=10, just below a 6% header on h=100
  (check "text at y=10 (above footer, below header) kept"
         (string= text (filter-text-by-region text rects 100.0 :header-frac 0.06 :footer-frac 0.06))))

(format t "~%========================================~%")
(format t "Layout extraction tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
