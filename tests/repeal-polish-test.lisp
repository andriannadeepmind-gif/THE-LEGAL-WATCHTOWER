;;;; tests/repeal-polish-test.lisp
;;;; A code that repeals articles states the range ONCE — «Άρθρα 3 - 4
;;;; (Καταργούνται)» — and never reprints them as headers. A naive parser then
;;;; reports a false GAP (2 → 5). Faithful codification materialises the repealed
;;;; articles as explicit «Καταργήθηκε.» stubs so the sequence is COMPLETE and the
;;;; repeal is recorded exactly as the legislator wrote it. This locks that:
;;;;   - ranges «Άρθρα X - Y (Καταργούνται)» become entries X..Y
;;;;   - singles «Άρθρο X (Καταργείται)» become entry X (suffix preserved)
;;;;   - the «(Καταργ…» may sit on the NEXT line
;;;;   - present articles are never duplicated
;;;;   - end-to-end, parse-fek-text leaves NO gaps after synthesis

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun nums-of (articles) (mapcar #'article-number articles))
(defun find-art (articles n) (find n articles :key #'article-number :test #'equal))
(defun body-of (art) (and art (article-paragraphs art)
                          (paragraph-text (first (article-paragraphs art)))))
(defun repealed-p (art) (and art (getf (node-metadata art) :repealed)))

;; A minimal real article (header already parsed) so synthesis sees it as present.
(defun present-article (n)
  (let ((a (make-instance 'fek-article :number (format nil "~D" n) :numeric n
                          :id (intern (format nil "A-~D" n)))))
    (setf (article-paragraphs a)
          (list (make-instance 'fek-paragraph :number 1 :text "Κείμενο." :id 'p)))
    a))

(format t "~%== a repeal RANGE becomes explicit entries ==~%")
(let* ((existing (list (present-article 1) (present-article 2) (present-article 5)))
       (text (format nil "Άρθρα 3 - 4~%(Καταργούνται)"))
       (merged (synthesize-repealed-articles text existing)))
  (check "range 3-4 fills the gap → 1,2,3,4,5"
         (equal '("1" "2" "3" "4" "5") (nums-of merged)))
  (check "synthesized 3 is marked repealed"  (repealed-p (find-art merged "3")))
  (check "synthesized 4 carries «Καταργήθηκε.»"
         (equal "Καταργήθηκε." (body-of (find-art merged "4"))))
  (check "present articles are not flagged repealed" (not (repealed-p (find-art merged "1")))))

(format t "~%== a SINGLE repeal (with suffix) becomes one entry ==~%")
(let* ((merged (synthesize-repealed-articles
                (format nil "Άρθρο 7 (Καταργείται)~%Άρθρο 9Α~%(Καταργήθηκε)")
                (list (present-article 6) (present-article 8)))))
  (check "single 7 added"                 (find-art merged "7"))
  (check "single 9Α added (suffix kept)"   (find-art merged "9Α"))
  (check "9Α numeric is 9"                 (eql 9 (article-numeric (find-art merged "9Α"))))
  (check "9Α sorts after 8 and after 9-less is fine"
         (equal '("6" "7" "8" "9Α") (nums-of merged))))

(format t "~%== real-world ΦΕΚ variants (from the actual Ποινικός dump) ==~%")
;; lower-case verb «(καταργείται)» — the form the first regex missed entirely
(check "lower-case «(καταργείται)» single is caught"
       (find-art (synthesize-repealed-articles "Άρθρο 274 (καταργείται)" nil) "274"))
;; en-dash range «Άρθρα 37 – 41»
(check "en-dash range 37–41 → 37,38,39,40,41"
       (equal '("37" "38" "39" "40" "41")
              (nums-of (synthesize-repealed-articles
                        (format nil "Άρθρα 37 – 41~%(Καταργούνται)") nil))))
;; no-space dash «Άρθρα 202-206»
(check "no-space dash 202-206 → 202..206"
       (equal '("202" "203" "204" "205" "206")
              (nums-of (synthesize-repealed-articles "Άρθρα 202-206 (Καταργούνται)" nil))))
;; space before paren «(Καταργούνται )»
(check "space before close-paren is tolerated"
       (find-art (synthesize-repealed-articles "Άρθρα 198 - 199 (Καταργούνται )" nil) "198"))
;; LETTERED same-base range «Άρθρα 137Β – 137Δ» → 137Β,137Γ,137Δ
(check "lettered range 137Β–137Δ → 137Β,137Γ,137Δ"
       (equal '("137Β" "137Γ" "137Δ")
              (nums-of (synthesize-repealed-articles
                        (format nil "Άρθρα 137Β – 137Δ~%(Καταργούνται)") nil))))
;; range ending in a letter «Άρθρα 182 - 182Α» → 182, 182Α
(check "range 182-182Α → 182,182Α"
       (equal '("182" "182Α")
              (nums-of (synthesize-repealed-articles "Άρθρα 182 - 182Α (Καταργούνται)" nil))))
;; range STARTING with a letter «Άρθρα 322Α – 323» → 322Α, 323 (never an invented 322)
(check "range 322Α–323 → 322Α,323 (no invented 322)"
       (equal '("322Α" "323")
              (nums-of (synthesize-repealed-articles
                        (format nil "Άρθρα 322Α – 323~%(Καταργούνται)") nil))))
;; lettered single «Άρθρο 237Β (Καταργείται)»
(check "lettered single 237Β caught"
       (find-art (synthesize-repealed-articles "Άρθρο 237Β (Καταργείται)" nil) "237Β"))
;; a whole-chapter «(Καταργήθηκε)» with NO number above must add nothing
(check "«(Καταργήθηκε)» with no article number adds nothing"
       (null (synthesize-repealed-articles
              (format nil "ΔΕΚΑΤΟ ΕΒΔΟΜΟ ΚΕΦΑΛΑΙΟ~%(Καταργήθηκε)") nil)))

(format t "~%== a present «Άρθρο N» header with only a «(καταργ…)» body is normalised ==~%")
;; «Άρθρο 274» IS a parseable header → the article is present, but its only body is
;; the bare repeal notice «(καταργείται)». It must read «Καταργήθηκε.» like the rest.
(let* ((bare (let ((a (make-instance 'fek-article :number "274" :numeric 274
                                     :id 'a274)))
               (setf (article-paragraphs a)
                     (list (make-instance 'fek-paragraph :number 0
                                          :text "(καταργείται)" :id 'p)))
               a))
       (merged (synthesize-repealed-articles "Άρθρο 274 (καταργείται)" (list bare)))
       (a (find-art merged "274")))
  (check "274 still present (not duplicated)" (= 1 (count "274" (nums-of merged) :test #'equal)))
  (check "274 normalised to «Καταργήθηκε.»"   (equal "Καταργήθηκε." (body-of a)))
  (check "274 now marked repealed"            (repealed-p a)))
;; an empty present header that the text marks repealed is also normalised
(let* ((empty (make-instance 'fek-article :number "364" :numeric 364 :id 'a364))
       (merged (synthesize-repealed-articles "Άρθρο 364 (Καταργείται)" (list empty))))
  (check "empty 364 normalised to «Καταργήθηκε.»"
         (equal "Καταργήθηκε." (body-of (find-art merged "364")))))
;; a present article with a REAL body is LEFT UNTOUCHED even when the text marks it
;; repealed — we record what the gazette says, we do not overwrite real content.
(let* ((real (let ((a (make-instance 'fek-article :number "299" :numeric 299 :id 'a299)))
               (setf (article-paragraphs a)
                     (list (make-instance 'fek-paragraph :number 0
                                          :text "Όποιος με πρόθεση σκότωσε άλλον τιμωρείται με κάθειρξη."
                                          :id 'p)))
               a))
       (merged (synthesize-repealed-articles "Άρθρο 299 (Καταργείται)" (list real)))
       (a (find-art merged "299")))
  (check "real 299 body is preserved (not judged)"
         (cl-ppcre:scan "κάθειρξη" (body-of a)))
  (check "real 299 is NOT marked repealed" (not (repealed-p a))))

(format t "~%== an already-present article is never duplicated ==~%")
(let* ((merged (synthesize-repealed-articles
                "Άρθρο 5 (Καταργείται)"
                (list (present-article 5)))))
  (check "no duplicate of present 5"  (= 1 (count "5" (nums-of merged) :test #'equal)))
  (check "present 5 keeps its real body, not «Καταργήθηκε.»"
         (equal "Κείμενο." (body-of (find-art merged "5")))))

(format t "~%== a header «Άρθρα» is NOT mistaken for a single «Άρθρο» ==~%")
(check "plural «Άρθρα» alone (no marker) adds nothing"
       (null (synthesize-repealed-articles "Άρθρα 3 - 4" nil)))

(format t "~%== end-to-end: parse-fek-text leaves NO false gaps ==~%")
(let* ((text (format nil "~
Άρθρο 1~%Πρώτο.~%~
Άρθρο 2~%Δεύτερο.~%~
Άρθρα 3 - 4~%(Καταργούνται)~%~
Άρθρο 5~%Πέμπτο.~%"))
       (articles (parse-fek-text text)))
  (check "sequence is complete 1..5"  (equal '("1" "2" "3" "4" "5") (nums-of articles)))
  (check "no gaps reported"           (null (validate-article-sequence articles)))
  (check "article 3 is the repealed stub" (repealed-p (find-art articles "3")))
  (check "article 5 is a real article (not repealed)"
         (not (repealed-p (find-art articles "5")))))

(format t "~%========================================~%")
(format t "Repeal-polish tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
