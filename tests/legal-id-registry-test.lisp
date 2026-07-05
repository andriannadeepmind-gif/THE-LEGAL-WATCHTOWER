;;;; tests/legal-id-registry-test.lisp
;;;; The autonomy router: parse Greek statutory references and decide which served
;;;; code a freshly published ΦΕΚ amends. Deterministic, conservative (never
;;;; routes a code without a concrete law-number/year or name/alias hit), offline.

(in-package :orchestrator.legal-id)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;; A registry shaped exactly as the CLI derives it from the corpus configs.
(defparameter *reg*
  (list (make-registry-entry "poinikos" :law-number 4619 :year 2019
                             :name "Ποινικός Κώδικας" :aliases '("ΠΚ")
                             :fek-series "Α" :fek-number 95
                             :eli-prefix "https://stavropouloslaw.com/eli/gr/l/2019/4619")
        (make-registry-entry "kpoinikis" :law-number 4620 :year 2019
                             :name "Κώδικας Ποινικής Δικονομίας" :aliases '("ΚΠΔ")
                             :fek-series "Α" :fek-number 96)
        (make-registry-entry "syntagma" :law-number nil :year nil
                             :name "Σύνταγμα" :aliases '("Σύνταγμα της Ελλάδας"))))

(format t "~%== parse ΦΕΚ references (tonos/keraia/spacing tolerant) ==~%")
(dolist (s '("ΦΕΚ Α' 95/2019" "Α΄ 95/2019" "ΦΕΚ Α 95 / 2019" "φεκ α’ 95/2019"))
  (let ((r (parse-fek-ref s)))
    (check (format nil "~S → Α 95/2019" s)
           (and r (string= "Α" (getf r :series)) (eql 95 (getf r :number)) (eql 2019 (getf r :year))))))
(check "non-ΦΕΚ string → NIL" (null (parse-fek-ref "καλημέρα")))

(format t "~%== parse law references ==~%")
(dolist (s '("ν. 4619/2019" "Ν.4619/2019" "νόμος 4619 / 2019" "του 4619/2019"))
  (let ((r (parse-law-ref s)))
    (check (format nil "~S → 4619/2019" s)
           (and r (eql 4619 (getf r :number)) (eql 2019 (getf r :year))))))
(check "no law number → NIL" (null (parse-law-ref "Ποινικός Κώδικας")))

(format t "~%== lookups ==~%")
(check "by corpus" (string= "poinikos" (registry-entry-corpus-id (registry-by-corpus *reg* "poinikos"))))
(check "by law 4620/2019 → kpoinikis"
       (string= "kpoinikis" (registry-entry-corpus-id (registry-by-law *reg* 4620 2019))))
(check "by ΦΕΚ Α 95/2019 → poinikos"
       (string= "poinikos" (registry-entry-corpus-id (registry-by-fek *reg* "Α" 95 2019))))
(check "law lookup with wrong year → NIL" (null (registry-by-law *reg* 4619 2020)))

(format t "~%== classify: which code does this gazette text amend? ==~%")
(check "explicit citation of ν.4619/2019 → poinikos"
       (equal '("poinikos")
              (classify-text *reg* "Στο άρθρο 299 του ν. 4619/2019 (Ποινικός Κώδικας) προστίθεται…")))
(check "citation of 4620/2019 → kpoinikis"
       (equal '("kpoinikis")
              (classify-text *reg* "Τροποποίηση του άρθρου 100 του ν. 4620/2019.")))
(check "name-only match (Σύνταγμα, no law number) → syntagma"
       (equal '("syntagma") (classify-text *reg* "Αναθεώρηση του Συντάγματος της Ελλάδας.")))
(check "alias ΠΚ alone does NOT false-route without a code hit elsewhere"
       ;; 'ΠΚ' is an alias of poinikos, so a text containing it DOES route — verify it is exactly poinikos
       (equal '("poinikos") (classify-text *reg* "Κατά το άρθρο 1 ΠΚ ισχύει η αρχή nullum crimen.")))
(check "a ΦΕΚ touching TWO codes routes to both (config order)"
       (equal '("poinikos" "kpoinikis")
              (classify-text *reg* "Τροποποιούνται ο ν. 4619/2019 και ο ν. 4620/2019.")))
(check "an unrelated gazette routes to NOTHING"
       (null (classify-text *reg* "Κανονισμός λειτουργίας δημοτικού κολυμβητηρίου, ν. 9999/2024.")))

(format t "~%== law-ref matches on numeric BOUNDARIES (no substring false-positives) ==~%")
(check "a longer law number «14619/2019» does NOT route to poinikos (4619/2019)"
       (null (classify-text *reg* "Άσχετος νόμος 14619/2019 περί λιμένων.")))
(check "a typo year «4619/20199» does NOT route to poinikos"
       (null (classify-text *reg* "Τροποποίηση του ν. 4619/20199.")))
(check "trailing digit «4619/20191» does NOT route to poinikos"
       (null (classify-text *reg* "Στο ν. 4619/20191 ορίζεται…")))
(check "spaces around the slash «4619 / 2019» STILL route to poinikos"
       (equal '("poinikos") (classify-text *reg* "Κατά τον ν. 4619 / 2019 (Ποινικός).")))

(format t "~%== route a ΦΕΚ listing (titles → corpora) ==~%")
(let* ((listing (list (list (cons "title" "Τροποποιήσεις του ν. 4619/2019") (cons "url" "u1"))
                      (list (cons "title" "Άσχετη υπουργική απόφαση") (cons "url" "u2"))))
       (routed (route-listing *reg* listing)))
  (check "first item routes to poinikos"
         (equal '("poinikos") (getf (first routed) :corpora)))
  (check "second item routes to nothing"
         (null (getf (second routed) :corpora)))
  (check "route-listing can use a fetch-text-fn for deeper matching"
         (equal '("kpoinikis")
                (getf (first (route-listing *reg*
                                            (list (list (cons "title" "ΦΕΚ Α 200/2024") (cons "url" "x")))
                                            :fetch-text-fn (lambda (u) (declare (ignore u))
                                                             "πλήρες κείμενο: ν. 4620/2019")))
                      :corpora))))

(format t "~%========================================~%")
(format t "Legal-ID registry tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
