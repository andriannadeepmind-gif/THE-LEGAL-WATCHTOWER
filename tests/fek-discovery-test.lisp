;;;; tests/fek-discovery-test.lisp
;;;; DISCOVERY: enumerate-new-fek finds newly-published ΦΕΚ by walking blob numbers
;;;; until a run of misses. The blob fetch is proven live (1975, 1985, 2023, 2024
;;;; all return 200); here we unit-test the ENUMERATION LOGIC with an injected
;;;; existence predicate, so gap-tolerance, the "only new ones" contract and the
;;;; stop conditions are verified deterministically without any network.

(in-package :orchestrator.document-fetch)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;; A mock "blob store": these ΦΕΚ Α'/2025 numbers are published.
(defun published-set (&rest numbers)
  (let ((s numbers)) (lambda (series number year)
                       (declare (ignore series year)) (member number s))))

(format t "~%== contiguous run ==~%")
(check "1..5 published → returns (1 2 3 4 5)"
       (equal '(1 2 3 4 5)
              (enumerate-new-fek "Α" 2025 :from 1 :max-gap 3
                                 :exists-fn (published-set 1 2 3 4 5))))

(format t "~%== gap tolerance (a hole smaller than max-gap is crossed) ==~%")
(check "1,2,3,(4 missing),5,6 with max-gap 3 → (1 2 3 5 6)"
       (equal '(1 2 3 5 6)
              (enumerate-new-fek "Α" 2025 :from 1 :max-gap 3
                                 :exists-fn (published-set 1 2 3 5 6))))
(check "a hole == max-gap stops (max-gap 2, missing 4,5) → (1 2 3)"
       (equal '(1 2 3)
              (enumerate-new-fek "Α" 2025 :from 1 :max-gap 2
                                 :exists-fn (published-set 1 2 3 6 7))))

(format t "~%== 'only the NEW ones' — daemon passes from = last-seen+1 ==~%")
(check "from 4 over 1..6 → (4 5 6)"
       (equal '(4 5 6)
              (enumerate-new-fek "Α" 2025 :from 4 :max-gap 3
                                 :exists-fn (published-set 1 2 3 4 5 6))))
(check "nothing new (last-seen at the ceiling) → NIL"
       (null (enumerate-new-fek "Α" 2025 :from 7 :max-gap 3
                                :exists-fn (published-set 1 2 3 4 5 6))))

(format t "~%== bounds ==~%")
(check "empty store → NIL" (null (enumerate-new-fek "Α" 2025 :from 1
                                                    :exists-fn (published-set))))
(check "limit caps the probes (limit 2, store huge) → at most 2 found"
       (>= 2 (length (enumerate-new-fek "Α" 2025 :from 1 :limit 2 :max-gap 99
                                        :exists-fn (lambda (s n y)
                                                     (declare (ignore s n y)) t)))))

(format t "~%========================================~%")
(format t "ΦΕΚ discovery (enumeration) tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
