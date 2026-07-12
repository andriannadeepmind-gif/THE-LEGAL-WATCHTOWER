;;;; tests/auto-consolidate-test.lisp
;;;; THE LAST WIRE, end-to-end: an amending gazette's TEXT is read by the extractor,
;;;; its operations flow — untranslated — into the consolidation engine, and the
;;;; in-force corpus actually changes. discover → fetch → extract → ROUTE → APPLY.
;;;; The op plists from extract-operations ARE apply-operation clauses, so Lisp
;;;; carries them straight through; only high-confidence ops auto-apply, structural
;;;; ones defer to review.

(in-package :orchestrator.consolidation.bridge)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun build-pk ()
  "A tiny Penal-Code document with articles 5, 8 and 10."
  (make-legal-document
   :id "poinikos" :title "Ποινικός Κώδικας" :language "el"
   :provisions (list (make-provision :eid "art_5"  :kind :article :num "5"  :heading "Παλιός" :text "Παλιό κείμενο του άρθρου 5.")
                     (make-provision :eid "art_8"  :kind :article :num "8"  :heading "Οκτώ"   :text "Κείμενο του άρθρου 8.")
                     (make-provision :eid "art_10" :kind :article :num "10" :heading "Δέκα"   :text "Κείμενο του άρθρου 10."))))

(defparameter *fek-text*
  "Άρθρο 1. Το άρθρο 5 του Ποινικού Κώδικα (ν. 4619/2019) αντικαθίσταται ως εξής: «Άρθρο 5. Όποιος τελεί την πράξη τιμωρείται με κάθειρξη.» Άρθρο 2. Το άρθρο 10 του Ποινικού Κώδικα καταργείται. Άρθρο 3. Στο άρθρο 8 του Ποινικού Κώδικα προστίθεται παράγραφος 4 ως εξής: «4. Η νέα παράγραφος.»")

(format t "~%== read gazette → operations ==~%")
(let ((ops (orchestrator.amendment-extractor:extract-operations *fek-text*)))
  (check "extractor produced 3 operations" (= 3 (length ops)))

  (format t "~%== apply to the in-force corpus ==~%")
  (let ((base (build-pk)))
    (multiple-value-bind (updated applied deferred)
        (apply-extracted-amendments base ops :id "Ν.5000/2025" :effective "2025-06-01")
      (check "2 ops auto-applied (replace + repeal, both :high)" (= 2 (length applied)))
      (check "1 op deferred for review (the structural :insert, :medium)"
             (and (= 1 (length deferred)) (eq :insert (getf (first deferred) :op))))

      (format t "~%== the corpus actually changed ==~%")
      (check "art_5 now carries the NEW text"
             (search "τιμωρείται με κάθειρξη" (provision-text (find-provision updated "art_5"))))
      (check "art_5 no longer carries the OLD text"
             (not (search "Παλιό κείμενο" (provision-text (find-provision updated "art_5")))))
      (check "art_10 is now :repealed"
             (eq :repealed (provision-status (find-provision updated "art_10"))))
      (check "art_8 untouched (its insert was deferred, not auto-applied)"
             (search "Κείμενο του άρθρου 8" (provision-text (find-provision updated "art_8"))))

      (format t "~%== provenance + immutability + rendering ==~%")
      (check "the change is stamped with the act id"
             (equal "Ν.5000/2025" (provision-source-act (find-provision updated "art_5"))))
      (check "BASE document never mutated (art_10 still :original)"
             (eq :original (provision-status (find-provision base "art_10"))))
      (check "in-force render shows the new art_5 and OMITS the repealed art_10"
             (let ((txt (render-consolidated-text updated)))
               (and (search "τιμωρείται με κάθειρξη" txt)
                    (not (search "Κείμενο του άρθρου 10" txt))))))))

;;; safety: a gazette that amends NOTHING in this code leaves it byte-identical
(format t "~%== no-op gazette leaves the corpus identical ==~%")
(let* ((base (build-pk))
       (ops (orchestrator.amendment-extractor:extract-operations
             "Άρθρο 1. Η παρούσα αρχίζει να ισχύει από τη δημοσίευσή της.")))
  (multiple-value-bind (updated applied deferred) (apply-extracted-amendments base ops)
    (declare (ignore deferred))
    (check "nothing applied" (null applied))
    (check "render unchanged"
           (string= (render-consolidated-text (build-pk)) (render-consolidated-text updated)))))

;;; [FEK-COMPILER] round-trip: κάθε applied πράξη ΑΠΟΔΕΙΚΝΥΕΤΑΙ στο αποτέλεσμα,
;;; κάθε σιωπηλά προσπερασμένη (:if-missing :skip) ΑΝΑΦΕΡΕΤΑΙ — ποτέ αόρατη.
(format t "~%== round-trip report: applied ⇒ verified, skipped ⇒ SILENT ==~%")
(let* ((base (build-pk))
       (ops (list (list :op :replace-text :target "art_5" :if-missing :skip
                        :confidence :high :text "Νέο κείμενο πέντε.")
                  (list :op :repeal :target "art_10" :if-missing :skip :confidence :high)
                  ;; στόχος που ΔΕΝ υπάρχει στο corpus — ο engine τον προσπερνά
                  (list :op :repeal :target "art_999" :if-missing :skip :confidence :high))))
  (multiple-value-bind (updated applied deferred) (apply-extracted-amendments base ops)
    (declare (ignore deferred))
    (check "και οι 3 πράξεις ήταν auto-applicable" (= 3 (length applied)))
    (multiple-value-bind (verified skipped mismatched) (round-trip-report updated applied)
      (check "replace art_5 ⇒ VERIFIED (κείμενο ≡ op text)"
             (member "art_5" verified :key (lambda (o) (getf o :target)) :test #'equal))
      (check "repeal art_10 ⇒ VERIFIED (status :repealed)"
             (member "art_10" verified :key (lambda (o) (getf o :target)) :test #'equal))
      (check "repeal art_999 ⇒ SKIPPED (προσπεράστηκε — ΑΝΑΦΕΡΕΤΑΙ, δεν χάνεται)"
             (and (= 1 (length skipped))
                  (equal "art_999" (getf (first skipped) :target))))
      (check "καμία MISMATCHED (η μηχανή εφάρμοσε ό,τι ανέλαβε)"
             (null mismatched))
      (check "verified+skipped+mismatched = applied (καμία πράξη αόρατη)"
             (= (length applied)
                (+ (length verified) (length skipped) (length mismatched))))
      ;; mark-amended: επαληθεύεται από STATUS, όχι από σκέτη ύπαρξη (όχι ταυτολογία)
      (multiple-value-bind (v2 s2 m2)
          (round-trip-report updated
                             (list (list :op :mark-amended :target "art_8"
                                         :if-missing :skip :confidence :high)))
        (declare (ignore s2))
        (check "mark-amended σε ΑΝΕΓΓΙΧΤΟ άρθρο ⇒ MISMATCHED (status :original)"
               (and (null v2) (= 1 (length m2))))))))

;;; [FEK-COMPILER regression] Η δρομολόγηση ΟΦΕΙΛΕΙ να δένει ΚΑΙ στην κατανάλωση
;;; (law->record/laws->records) — όχι μόνο στη discovery. Χωρίς resolver, μια
;;; πράξη σε ΕΝΑΝ κώδικα εφαρμοζόταν σε ΚΑΘΕ κώδικα (sole-unrouted).
(format t "~%== law->record: per-code routing δένει στην κατανάλωση ==~%")
(let* ((rr (orchestrator.amendment-extractor:make-registry-resolver
            (list (orchestrator.legal-id:make-registry-entry "poinikos"
                   :law-number 4619 :year 2019 :name "Ποινικός Κώδικας"
                   :aliases '("Ποινικό Κώδικα" "Ποινικού Κώδικα"))
                  (orchestrator.legal-id:make-registry-entry "astikos"
                   :law-number 2250 :year 1940 :name "Αστικός Κώδικας"
                   :aliases '("Αστικό Κώδικα" "Αστικού Κώδικα")))))
       (law (list (cons "id" "ν. 5000/2025") (cons "date" "2025-01-01")
                  (cons "fek" "Α' 1/2025")
                  (cons "text" "Το άρθρο 5 του Ποινικού Κώδικα καταργείται."))))
  (check "ΜΕ resolver: η πράξη (poinikos) παράγει record ΓΙΑ poinikos"
         (law->record law "poinikos" :code-resolver rr))
  (check "ΜΕ resolver: η ΙΔΙΑ πράξη ΔΕΝ παράγει record για astikos (δεν διαρρέει)"
         (null (law->record law "astikos" :code-resolver rr)))
  (check "ΧΩΡΙΣ resolver (το παλιό σφάλμα): η αδρομολόγητη πράξη ΘΑ εφαρμοζόταν και στα δύο"
         (and (law->record law "poinikos")
              (law->record law "astikos"))))

(format t "~%========================================~%")
(format t "Auto-consolidate (closed loop) tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
