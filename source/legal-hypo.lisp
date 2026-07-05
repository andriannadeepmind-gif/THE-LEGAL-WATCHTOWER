;;;; source/legal-hypo.lisp
;;;; ============================================================================
;;;; Σ7 — ΠΡΟΗΓΟΥΜΕΝΑ ΚΑΤΑ HYPO/CATO: ομοιότητα ΓΕΓΟΝΟΤΩΝ, όχι ευρετήριο
;;;; ============================================================================
;;;;
;;;; Υπόθεση = σύνολο γεγονότων. ΠΑΡΑΓΟΝΤΑΣ (factor) = γεγονός αφηρημένο από
;;;; τις οντότητες: (:γεγονός :Α :αφαιρεί :πορτοφόλι) ⇒ (:αφαιρεί) ως πράξη,
;;;; (:γεγονός :πορτοφόλι :είναι :κινητό) ⇒ (:είναι :κινητό) ως ιδιότητα.
;;;; Ομοιότητα = κοινοί παράγοντες / διακρίσεις = παράγοντες του ενός που
;;;; λείπουν από τον άλλον (οι ΔΙΑΚΡΙΣΕΙΣ του CATO — ό,τι επικαλείται ο
;;;; αντίδικος). Κατάταξη ντετερμινιστική: |κοινοί| φθίνον, μετά |διακρίσεις|
;;;; αύξον, μετά ταυτότητα υπόθεσης. Πρόβλεψη: πλειοψηφία διατακτικού των k
;;;; κοντινότερων — μετριέται ΜΟΝΟ με leave-one-out, ποτέ δεν δηλώνεται αλλιώς.
;;;; ΜΙΑ υλοποίηση: τη χρησιμοποιούν φάκελος, --precedents και η πύλη μέτρησης.

(defpackage :orchestrator.hypo
  (:use :cl)
  (:export #:case-factors #:shared-factors #:distinctions
           #:rank-precedents #:knn-verdict))

(in-package :orchestrator.hypo)

(defun case-factors (facts)
  "Οι ΠΑΡΑΓΟΝΤΕΣ μιας υπόθεσης: κάθε γεγονός χωρίς τις οντότητές του.
   (:γεγονός Χ πράξη Υ) ⇒ (πράξη) όταν το Υ είναι οντότητα, (πράξη τιμή)
   όταν το Υ είναι κατηγορία/τιμή του δικαίου (:είναι :κινητό, :σκοπός …)."
  (remove-duplicates
   (loop for f in facts
         when (and (consp f) (eq (first f) :γεγονός) (>= (length f) 3))
           collect (let ((pred (third f)) (obj (fourth f)))
                     ;; τιμές του δικαίου: keywords-έννοιες (κατηγορίες, σκοποί,
                     ;; τρόποι)· οντότητες: ό,τι δεν ξαναεμφανίζεται ως έννοια
                     (if (and obj (keywordp obj)
                              (loop for g in facts
                                    thereis (and (not (eq g f))
                                                 (member obj (cddr g)))))
                         (list pred)          ; obj = οντότητα (πρωταγωνιστεί αλλού)
                         (if obj (list pred obj) (list pred)))))
   :test #'equal))

(defun shared-factors (a b) (intersection a b :test #'equal))
(defun distinctions (a b)
  "(values μόνο-στην-Α μόνο-στη-Β) — οι διακρίσεις κατά CATO."
  (values (set-difference a b :test #'equal)
          (set-difference b a :test #'equal)))

(defun rank-precedents (query-factors precedents)
  "PRECEDENTS: ((id factors verdict)…). Κατάταξη ντετερμινιστική κατά
   |κοινά| ↓, |διακρίσεις| ↑, id. Επιστρέφει ((id κοινά δικές-του-διαφορές
   verdict)…) — μόνο όσα έχουν ≥1 κοινό παράγοντα (τα άσχετα ΔΕΝ προτείνονται)."
  (let ((scored
          (loop for (id factors verdict) in precedents
                for sh = (shared-factors query-factors factors)
                when sh
                  collect (multiple-value-bind (mine theirs)
                              (distinctions query-factors factors)
                            (declare (ignore mine))
                            (list id sh theirs verdict)))))
    (sort scored
          (lambda (x y)
            (let ((sx (length (second x))) (sy (length (second y)))
                  (dx (length (third x)))  (dy (length (third y))))
              (cond ((/= sx sy) (> sx sy))
                    ((/= dx dy) (< dx dy))
                    (t (string< (format nil "~A" (first x))
                                (format nil "~A" (first y))))))))))

(defun knn-verdict (query-factors precedents &key (k 3))
  "Πρόβλεψη διατακτικού: πλειοψηφία των k κοντινότερων (ισοπαλία ⇒ ο
   κοντινότερος). (values ετυμηγορία|nil γείτονες) — nil όταν κανένα
   προηγούμενο δεν μοιράζεται παράγοντα: ΤΙΜΙΑ αδυναμία, όχι εικασία."
  (let* ((ranked (rank-precedents query-factors precedents))
         (top (subseq ranked 0 (min k (length ranked)))))
    (if (null top)
        (values nil '())
        (let ((counts '()))
          (dolist (n top)
            (let ((c (assoc (fourth n) counts :test #'equal)))
              (if c (incf (cdr c)) (push (cons (fourth n) 1) counts))))
          (values (car (first (stable-sort
                               (sort counts (lambda (a b) (string< (format nil "~A" (car a))
                                                                    (format nil "~A" (car b)))))
                               #'> :key #'cdr)))
                  top)))))
