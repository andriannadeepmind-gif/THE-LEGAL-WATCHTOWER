;;;; tests/legal-eval-test.lisp
;;;; ============================================================================
;;;; Η ΜΕΤΡΗΜΕΝΗ ΣΚΑΛΑ — κλειδωμένη (ratchet)
;;;; ============================================================================
;;;; Κλειδώνει ΤΟΝ ΑΡΙΘΜΟ (deterministic) ώστε:
;;;;   · ο συμβολικός δικαστής να μένει 100% στα gold (μηχανή + labels συνεπή)·
;;;;   · το end-to-end να ΜΗΝ πέφτει σιωπηλά κάτω από το σημερινό (ratchet)·
;;;;   · το harness να ΑΝΙΧΝΕΥΕΙ όντως το χάσμα γείωσης (καμία ταυτολογία)·
;;;;   · η μέτρηση να είναι ντετερμινιστική (ίδιος αριθμός σε κάθε τρέξιμο).
;;;; Όταν βελτιωθεί η γείωση, τα κάτω όρια ΑΝΕΒΑΙΝΟΥΝ — απόδειξη προόδου με αριθμό.
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(let* ((r  (%legal-eval-run))
       (r2 (%legal-eval-run))
       (eng-ok (getf r :engine-ok))   (eng-tot (getf r :engine-total))
       (e2e-ok (getf r :e2e-ok))
       (pos-tot (getf r :pos-total))  (eng-pos (getf r :engine-pos)) (e2e-pos (getf r :e2e-pos)))

  (format t "~%== ① gold-consistency (validity check, ΟΧΙ ανεξάρτητη ικανότητα) ==~%")
  ;; ΤΙΜΙΟ [0075 verify Q4]: τα gold είναι στιγμιότυπα των ΝΟΡΜΩΝ· το ①=100% δείχνει
  ;; ΜΟΝΟ ότι οι ετικέτες μας είναι συνεπείς με τη μηχανή (καμία gold-λάθος), ΟΧΙ
  ;; ανεξάρτητη «εξυπνάδα». Ο πραγματικός δείκτης είναι το ② end-to-end.
  (check "gold-consistency: ΟΛΑ τα expect σωστά στα gold (engine-ok = engine-total)"
         (= eng-ok eng-tot))
  (check "gold-consistency στα :in/:out: engine-pos = pos-total (καμία ασυνεπής ετικέτα)"
         (= eng-pos pos-tot))

  (format t "~%== ② end-to-end: ο ΤΙΜΙΟΣ αριθμός (με held-out), RATCHET (≥) ==~%")
  ;; [0079] ΓΡΑΜΜΑΤΙΚΗ ΣΥΣΤΑΤΙΚΩΝ: αντικατέστησε τα μπαλώματα (article-heuristics +
  ;; exact-substring MWE) με NP-συστατικά + ΣΥΜΦΩΝΙΑ πτώσης + concepts κλειδωμένα σε
  ;; ΛΗΜΜΑΤΑ. Η γενίκευση στην κλίση ΓΥΡΙΣΕ το held-out «νόμιμης άμυνας»
  ;; (defeater-inflected) → e2e-ok 7→8/13· ⊕ 5→6/11 = 54.5% (ΓΝΗΣΙΑ γενίκευση, όχι
  ;; capture). Το ratchet ΑΝΕΒΗΚΕ — κλειδώνει το κέρδος, δεν το αφήνει να ξεφύγει.
  (check "end-to-end (όλα): ≥ 8/13 (ratchet — ανεβασμένο μετά τη γραμματική συστατικών)"
         (>= e2e-ok 8))
  (check "end-to-end ΑΠΑΙΤΗΤΙΚΟ (:in/:out, ΜΕ held-out): ≥ 6/11 (54.5%)"
         (>= e2e-pos 6))
  (check "υπάρχουν held-out υποθέσεις (μετρούν ΓΕΝΙΚΕΥΣΗ, όχι in-distribution capture)"
         (some (lambda (row) (member :held-out (getf row :tags))) (getf r :rows)))

  (format t "~%== ③ το harness ΑΝΙΧΝΕΥΕΙ το χάσμα γείωσης — ΣΥΝΘΕΤΙΚΑ (όχι από την πρόοδο) ==~%")
  ;; Anti-tautology BY CONSTRUCTION: υπόθεση με ακατάληπτη αφήγηση (0 εξαγωγή) αλλά
  ;; gold που στοιχειοθετεί νόρμα ⇒ μηχανή=1, end-to-end=0. Έτσι αποδεικνύεται ότι
  ;; το μέτρο ΔΕΝ είναι τυφλό, ΑΝΕΞΑΡΤΗΤΑ από το πόσο καλή γίνεται η γείωση (αν
  ;; τέλεια, το ⊕ end-to-end πάει 100% — αυτό το lock ΔΕΝ σπάει, γιατί είναι
  ;; συνθετικό, όχι δεμένο στον ζωντανό αριθμό).
  (let ((synth (%legal-eval-case
                '(:id "synth" :tags (:synthetic)
                  :narrative "ξζψωθ κρβνμ ασδφγ"
                  :gold-facts ((:γεγονός :Β :θανατώνει :Γ) (:γεγονός :Β :ενεργεί-με :δόλο))
                  :expect ((:norm-anthropoktonia-299 . :in))))))
    (check "συνθετικό: μηχανή στοιχειοθετεί (engine-pos=1) αλλά end-to-end όχι (e2e-pos=0)"
           (and (= 1 (getf synth :engine-pos)) (= 0 (getf synth :e2e-pos)))))

  (format t "~%== ντετερμινισμός ==~%")
  (check "ίδιος αριθμός σε δύο διαδοχικά τρεξίματα"
         (and (= (getf r :engine-ok) (getf r2 :engine-ok))
              (= (getf r :e2e-ok) (getf r2 :e2e-ok))
              (= (getf r :e2e-pos) (getf r2 :e2e-pos))))
  (check "12 υποθέσεις στο benchmark (9 core/adversarial + 3 held-out)" (= 12 (length (getf r :rows)))))

(format t "~%========================================~%")
(format t "LEGAL-EVAL (μετρημένη σκάλα): ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
