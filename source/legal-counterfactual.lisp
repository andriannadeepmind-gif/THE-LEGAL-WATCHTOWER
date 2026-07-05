;;;; source/legal-counterfactual.lisp
;;;; ============================================================================
;;;; Σ6 — ΥΠΟΘΕΤΙΚΟΣ ΛΟΓΟΣ: ποια γεγονότα ΚΡΙΝΟΥΝ την έκβαση
;;;; ============================================================================
;;;;
;;;; Ablation πάνω στην υπαγωγή: για κάθε γεγονός της υπόθεσης, «τι θα ίσχυε
;;;; χωρίς αυτό;» — αν το συμπέρασμα πέφτει, το γεγονός είναι ΚΡΙΣΙΜΟ. Πάνω από
;;;; τα μονο-γεγονότα: ΕΛΑΧΙΣΤΑ ΣΥΝΟΛΑ ΦΡΑΓΗΣ (ποιοι συνδυασμοί, αν πέσουν,
;;;; ρίχνουν τη θέση) — η ουσία της αμυντικής στρατηγικής, με απόδειξη. Το
;;;; %derive είναι γραμμικό (Φάση 2), άρα η συστηματική δοκιμή είναι φθηνή.
;;;; ΔΗΛΩΜΕΝΟ ΟΡΙΟ: τα σύνολα αναζητούνται έως μέγεθος MAX-SIZE (προεπιλογή 2)
;;;; με πλήρη απαρίθμηση — ακριβές εντός του ορίου, το όριο τυπωμένο.

(defpackage :orchestrator.counterfactual
  (:use :cl)
  (:export #:critical-facts #:minimal-blockers #:what-if-report))

(in-package :orchestrator.counterfactual)

(defun %concluded-p (facts norm norms)
  "Στοιχειοθετείται (:in) το συμπέρασμα του NORM πάνω στα FACTS;"
  (multiple-value-bind (engine) (orchestrator.subsumption:subsume facts :norms norms)
    (eq :in (orchestrator.subsumption:conclusion-status engine norm facts))))

(defun critical-facts (facts norm &key (norms (orchestrator.subsumption:case-norms)))
  "Τα ΚΡΙΣΙΜΑ γεγονότα για το συμπέρασμα του NORM: όσων η αφαίρεση το ρίχνει.
   (values κρίσιμα αδιάφορα βάση-p) — βάση-p nil αν το συμπέρασμα δεν ίσταται
   ούτε με ΟΛΑ τα γεγονότα (τότε το ερώτημα είναι «τι λείπει», όχι «τι κρίνει»)."
  (if (not (%concluded-p facts norm norms))
      (values nil nil nil)
      (let ((critical '()) (idle '()))
        (dolist (f facts)
          (if (%concluded-p (remove f facts :test #'equal) norm norms)
              (push f idle)
              (push f critical)))
        (values (nreverse critical) (nreverse idle) t))))

(defun minimal-blockers (facts norm &key (norms (orchestrator.subsumption:case-norms))
                                         (max-size 2))
  "Τα ΕΛΑΧΙΣΤΑ σύνολα γεγονότων που, αν πέσουν, ρίχνουν το συμπέρασμα — έως
   μέγεθος MAX-SIZE (πλήρης απαρίθμηση: ακριβές εντός ορίου). Τα μονομελή είναι
   τα κρίσιμα· τα διμελή κ.ο.κ. αποκαλύπτουν τα «διπλά ερείσματα»."
  (unless (%concluded-p facts norm norms)
    (return-from minimal-blockers (values nil nil)))
  (let ((blockers '()))
    (labels ((minimal-p (set)
               (notany (lambda (b) (subsetp b set :test #'equal)) blockers))
             (try (subset)
               (when (and (minimal-p subset)
                          (not (%concluded-p (set-difference facts subset :test #'equal)
                                             norm norms)))
                 (push subset blockers))))
      (loop for size from 1 to max-size do
        (labels ((combos (items k acc)
                   (cond ((zerop k) (try (reverse acc)))
                         ((null items))
                         (t (combos (cdr items) (1- k) (cons (car items) acc))
                            (combos (cdr items) k acc)))))
          (combos facts size '()))))
    (values (nreverse blockers) max-size)))

(defun what-if-report (facts norm-id &key (stream *standard-output*)
                                          (max-size 2))
  "Η αναφορά του υποθετικού λόγου για τον κανόνα NORM-ID: κρίσιμα γεγονότα,
   αδιάφορα, και ελάχιστα σύνολα φραγής — καθένα ελεγμένο με ΠΡΑΓΜΑΤΙΚΗ
   επανυπαγωγή, όχι με εικασία."
  (let ((norm (orchestrator.deontic:find-norm norm-id)))
    (unless norm
      (format stream "Άγνωστος κανόνας ~S.~%" norm-id)
      (return-from what-if-report 1))
    (multiple-value-bind (critical idle basis-p) (critical-facts facts norm)
      (cond
        ((not basis-p)
         (format stream "~%Το συμπέρασμα του ~A ΔΕΝ ίσταται ούτε με όλα τα γεγονότα — το ερώτημα είναι «τι λείπει» (βλ. υπαγωγή), όχι «τι κρίνει».~%"
                 norm-id)
         1)
        (t
         (format stream "~%── ΥΠΟΘΕΤΙΚΟΣ ΛΟΓΟΣ για ~A (άρθρο ~A ~A) ──~%"
                 norm-id (orchestrator.deontic:norm-article norm)
                 (orchestrator.deontic:norm-corpus norm))
         (format stream "  ΚΡΙΣΙΜΑ (αν πέσει, πέφτει η θέση):~%~{    • ~S~%~}"
                 critical)
         (when idle
           (format stream "  Αδιάφορα για ΑΥΤΟΝ τον κανόνα:~%~{    · ~S~%~}" idle))
         (multiple-value-bind (blockers limit) (minimal-blockers facts norm :max-size max-size)
           (let ((multi (remove-if (lambda (b) (= 1 (length b))) blockers)))
             (when multi
               (format stream "  ΕΛΑΧΙΣΤΑ ΣΥΝΟΛΑ ΦΡΑΓΗΣ (διπλά ερείσματα):~%~{    ⊗ ~S~%~}" multi))
             (format stream "  (πλήρης απαρίθμηση έως μέγεθος ~D — δηλωμένο όριο)~%" limit)))
         0)))))
