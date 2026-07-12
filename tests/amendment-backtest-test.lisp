;;;; tests/amendment-backtest-test.lisp
;;;; [BACKTEST] Αυτο-επαληθευόμενη μέτρηση ακρίβειας του extractor σε ΠΡΑΓΜΑΤΙΚΟ
;;;; κείμενο ΦΕΚ — self-supervision, ΚΑΜΙΑ χειροκίνητη ετικέτα. Ground truth =
;;;; ήδη-committed αναλλοίωτες: (Α) η ΤΑΥΤΟΤΗΤΑ του σώματος (census: ποια άρθρα
;;;; υπάρχουν σε κάθε κώδικα) βαθμολογεί ΚΑΘΕ δρομολόγηση· (Β) η ΔΟΜΗ (νομοτεχνικά
;;;; ρήματα) μετρά το recall. Το σώμα βαθμολογεί τον εαυτό του.
;;;;
;;;; Fixtures: tests/fixtures/fek/*.txt = ΠΡΑΓΜΑΤΙΚΟ pdftotext (owner run 2026-07-12).

(in-package :orchestrator.amendment-extractor)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *fix*
  (merge-pathnames "fixtures/fek/"
                   (make-pathname :directory (pathname-directory
                                              (or *load-truename* *load-pathname*)))))

;; Registry ΟΠΩΣ το παράγει build-legal-id-registry από τα configs (δείγμα 3 κωδίκων
;; που αναφέρονται στο a103 ως cross-references).
(defvar *reg*
  (list (orchestrator.legal-id:make-registry-entry "kdioikitikis"
         :law-number 2717 :year 1999 :name "Κώδικας Διοικητικής Δικονομίας"
         :aliases '("Διοικητικής Δικονομίας"))
        (orchestrator.legal-id:make-registry-entry "kpoinikis"
         :law-number 4620 :year 2019 :name "Κώδικας Ποινικής Δικονομίας"
         :aliases '("Ποινικής Δικονομίας"))
        (orchestrator.legal-id:make-registry-entry "poinikos"
         :law-number 4619 :year 2019 :name "Ποινικός Κώδικας"
         :aliases '("Ποινικό Κώδικα" "Ποινικού Κώδικα"))))
(defvar *rr* (make-registry-resolver *reg*))
;; Census oracle = ΤΑ ΠΡΑΓΜΑΤΙΚΑ εύρη άρθρων των served κωδίκων (η ταυτότητά τους).
;; Census oracle από ΤΟ ΠΡΑΓΜΑΤΙΚΟ census (committed fixture served-census.json =
;; τα ΑΚΡΙΒΗ article-ids κάθε served κώδικα, εξηγμένα από τα attested census.json).
;; ΑΚΡΙΒΗΣ συμμετοχή — όχι εύρος: kdioikitikis έχει 244 αλλά ΟΧΙ 290· poinikos
;; έχει lettered άρθρα. Αυτό είναι το ground truth, όχι approximation.
(defparameter *census*
  (let ((doc (jonathan:parse
              (alexandria:read-file-into-string
               (merge-pathnames "served-census.json" *fix*))
              :as :hash-table))
        (h (make-hash-table :test 'equal)))
    (maphash (lambda (code ids)
               (let ((s (make-hash-table :test 'equal)))
                 (dolist (id ids) (setf (gethash id s) t))
                 (setf (gethash code h) s)))
             doc)
    h))
(defun oracle (code base)
  "(corpus-id base-article-id) → T / NIL / :unknown από το ΠΡΑΓΜΑΤΙΚΟ census.
   :unknown μόνο για κώδικα εκτός fixture (τίμια άγνοια)."
  (let ((s (gethash code *census*)))
    (cond ((null s) :unknown)
          ((gethash base s) t)
          (t nil))))

(format t "~%== [1] ΠΡΑΓΜΑΤΙΚΟ a103 (νέος Κώδικας Τοπ. Αυτοδιοίκησης) — self-verify ==~%")
(let* ((text (alexandria:read-file-into-string
              (merge-pathnames "a103-2026-excerpt.txt" *fix*)))
       (ops (extract-operations text :code-resolver *rr* :article-exists-fn #'oracle))
       (m (measure-extraction text :code-resolver *rr* :article-exists-fn #'oracle)))
  (format t "  μέτρηση: ~S~%" m)
  ;; Η ΕΓΓΥΗΣΗ: ένας ΞΕΝΟΣ νόμος (a103 δεν τροποποιεί served κώδικα) ⇒ ΜΗΔΕΝ
  ;; auto-applicable πράξεις σε served κώδικα. Fail-closed σε ΠΡΑΓΜΑΤΙΚΟ κείμενο.
  (ck "ΜΗΔΕΝ auto-applicable πράξη δρομολογημένη σε served κώδικα"
      (zerop (count-if (lambda (o) (and (getf o :code) (operation-applicable-p o))) ops)))
  ;; Η self-supervision: ο census ΕΠΙΑΣΕ μόνος του τη λάθος δρομολόγηση (773∉kpoinikis).
  (ck "census oracle ΕΠΙΑΣΕ ≥1 λάθος δρομολόγηση (contradicted) — αυτόματα, χωρίς ετικέτα"
      (plusp (getf m :identity-contradicted)))
  (ck "κάθε contradicted πράξη είναι :low ΚΑΙ ΟΧΙ auto-applicable"
      (every (lambda (o) (or (not (eq (getf o :identity) :contradicted))
                             (and (eq (getf o :confidence) :low)
                                  (not (operation-applicable-p o)))))
             ops))
  ;; Αυτο-αναφορές (δικά του άρθρα) εντοπίστηκαν σε πραγματικό κείμενο.
  (ck "αυτο-αναφορές δικών-του άρθρων εντοπίστηκαν (self-reference ≥2)"
      (>= (getf m :self-reference) 2))
  (ck "δομικό recall + verbs μετρήθηκαν (αριθμοί, όχι ισχυρισμός)"
      (and (plusp (getf m :structural-verbs)) (getf m :structural-recall))))

(format t "~%== [2] ΘΕΤΙΚΗ κατεύθυνση: γνήσια τροποποίηση ⇒ identity-precision 100% ==~%")
(let* ((text "Το άρθρο 5 του Ποινικού Κώδικα καταργείται.")
       (m (measure-extraction text :code-resolver *rr* :article-exists-fn #'oracle)))
  (ck "1 δρομολογημένη σε poinikos" (= 1 (getf m :routed)))
  (ck "census ΕΠΙΒΕΒΑΙΩΝΕΙ (art_5 ∈ poinikos) ⇒ identity-verified=1"
      (= 1 (getf m :identity-verified)))
  (ck "identity-precision = 1 (100%)" (eql 1 (getf m :identity-precision))))

(format t "~%== [3] ΑΝΙΧΝΕΥΣΗ ΣΦΑΛΜΑΤΟΣ: λάθος στόχος ⇒ contradicted, precision<1 ==~%")
(let* ((text "Το άρθρο 9999 του Ποινικού Κώδικα καταργείται.")
       (ops (extract-operations text :code-resolver *rr* :article-exists-fn #'oracle))
       (m (measure-extraction text :code-resolver *rr* :article-exists-fn #'oracle)))
  (ck "art_9999 ∉ poinikos ⇒ identity-contradicted=1" (= 1 (getf m :identity-contradicted)))
  (ck "identity-precision = 0 (η μία δρομολόγηση διαψεύστηκε)"
      (eql 0 (getf m :identity-precision)))
  (ck "η contradicted πράξη ΔΕΝ αυτο-εφαρμόζεται (fail-closed)"
      (notany #'operation-applicable-p ops)))

(format t "~%========================================~%")
(format t "Amendment backtest (self-verify): ~D passed, ~D failed~%" *p* *f*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *f*) 0 1))
