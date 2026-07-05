;;;; tests/amendment-routing-test.lisp
;;;; THE hard semantic step, end-to-end on realistic ΦΕΚ nomotechnic text: read an
;;;; amending gazette and produce the STRUCTURED picture — which code, which
;;;; article, which operation — then GROUP it by code so the discovery loop can
;;;; report and the consolidator can route. extract-operations + summarize-operations.

(in-package :orchestrator.amendment-extractor)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun op-for (ops target)
  (find target ops :key (lambda (o) (getf o :target)) :test #'equal))

;;; (1) one gazette, three operations on the Penal Code
(format t "~%== (1) ΦΕΚ amending the Penal Code (replace / insert / repeal) ==~%")
(let* ((fek "Άρθρο 1. Το άρθρο 5 του Ποινικού Κώδικα (ν. 4619/2019) αντικαθίσταται ως εξής: «Άρθρο 5. Όποιος τελεί την πράξη τιμωρείται με κάθειρξη.» Άρθρο 2. Το άρθρο 10 του Ποινικού Κώδικα καταργείται. Άρθρο 3. Στο άρθρο 8 του Ποινικού Κώδικα προστίθεται παράγραφος 4 ως εξής: «4. Η νέα παράγραφος.»")
       (ops (extract-operations fek)))
  (check "three operations extracted" (= 3 (length ops)))
  (check "art_5 → REPLACE-TEXT, code poinikos, high"
         (let ((o (op-for ops "art_5")))
           (and o (eq :replace-text (getf o :op)) (equal "poinikos" (getf o :code))
                (eq :high (getf o :confidence)))))
  (check "art_5 carries the NEW text"
         (search "τιμωρείται με κάθειρξη" (or (getf (op-for ops "art_5") :text) "")))
  (check "art_10 → REPEAL, code poinikos"
         (let ((o (op-for ops "art_10"))) (and o (eq :repeal (getf o :op)) (equal "poinikos" (getf o :code)))))
  (check "art_8 → INSERT (new paragraph), flagged medium"
         (let ((o (op-for ops "art_8"))) (and o (eq :insert (getf o :op)) (eq :medium (getf o :confidence)))))
  ;; the routing view
  (let ((summary (summarize-operations ops)))
    (check "summary groups all under a single code: poinikos"
           (and (= 1 (length summary)) (equal "poinikos" (caar summary))))
    (check "that bucket lists the 3 affected articles"
           (equal '("art_5" "art_8" "art_10")
                  (mapcar (lambda (o) (getf o :target)) (cdr (first summary)))))))

;;; (2) one gazette touching TWO codes → two buckets, correctly split
(format t "~%== (2) ΦΕΚ touching two codes → routed separately ==~%")
(let* ((fek "Άρθρο 1. Το άρθρο 3 του Αστικού Κώδικα αντικαθίσταται ως εξής: «Άρθρο 3. Νέα διάταξη.» Άρθρο 2. Το άρθρο 7 του Ποινικού Κώδικα καταργείται.")
       (summary (summarize-operations (extract-operations fek)))
       (codes (mapcar #'car summary)))
  (check "two code buckets" (= 2 (length summary)))
  (check "astikos present" (member "astikos" codes :test #'equal))
  (check "poinikos present" (member "poinikos" codes :test #'equal))
  (check "astikos bucket = art_3 (replace)"
         (let ((b (cdr (assoc "astikos" summary :test #'equal))))
           (and (= 1 (length b)) (equal "art_3" (getf (first b) :target))
                (eq :replace-text (getf (first b) :op)))))
  (check "poinikos bucket = art_7 (repeal)"
         (let ((b (cdr (assoc "poinikos" summary :test #'equal))))
           (and (= 1 (length b)) (equal "art_7" (getf (first b) :target))
                (eq :repeal (getf (first b) :op))))))

;;; (3) non-amending text → nothing
(format t "~%== (3) ordinary text → no operations ==~%")
(check "plain article text yields no operations"
       (null (extract-operations "Άρθρο 1. Η Ελλάδα είναι Προεδρευόμενη Κοινοβουλευτική Δημοκρατία.")))
(check "summary of nothing is empty" (null (summarize-operations '())))

(format t "~%========================================~%")
(format t "Amendment routing tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
