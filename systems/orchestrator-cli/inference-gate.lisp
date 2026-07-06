;;;; systems/orchestrator-cli/inference-gate.lisp
;;;; ============================================================================
;;;; ΠΥΛΗ ΣΥΜΠΕΡΑΣΜΟΥ — η μηχανή (L1/JTMS) και ο συλλογιστής γράφου, ελεγμένοι
;;;; ============================================================================
;;;;
;;;; Μέχρι τη Φάση 2 ΚΑΜΙΑ πύλη δεν κάλυπτε τη μηχανή συμπερασμού ή τη διάσχιση
;;;; επιπτώσεων του γράφου. Εδώ κλειδώνουν:
;;;;   • ενοποίηση (unify) — δέσμευση, σύγκρουση, μήκη
;;;;   • παραγωγή :affected με ΑΠΟΔΕΙΞΗ, cascade, defeaters (well-founded)
;;;;   • ανακυκλικές αιτιολογήσεις (περιττός/άρτιος βρόχος ⇒ :out, τερματίζει)
;;;;   • επαναχρησιμοποιήσιμη μηχανή: ανάκληση (:changed …) ⇒ μηδέν :affected
;;;;   • impact γράφου: ΑΛΗΘΙΝΟ BFS — πλήρης κάλυψη εντός ορίζοντα, ελάχιστες
;;;;     διαδρομές, ΡΗΤΗ δήλωση αποκοπής (η παλαιά DFS θα αποτύγχανε εδώ)
;;;;   • κλίμακα: αλυσίδα 3000 γεγονότων σε δευτερόλεπτα, ακριβές πλήθος
;;;; Μία αποτυχία ⇒ exit 1. Όλα σε προσωρινές δομές — τίποτα κοινό δεν αγγίζεται.

(in-package :orchestrator.cli)

(defun run-inference-gate ()
  "--inference-gate : ντετερμινιστικοί έλεγχοι μηχανής συμπερασμού + συλλογιστή γράφου."
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΣΥΜΠΕΡΑΣΜΟΥ ──~%")

      ;; ── 1. Ενοποίηση ──
      (check "unify: δέσμευση μεταβλητών"
             (equal (orchestrator.inference:unify '(:a ?x ?y) '(:a 1 2))
                    '((?y . 2) (?x . 1))))
      (check "unify: ασυνεπής επαναδέσμευση ⇒ :fail"
             (eq :fail (orchestrator.inference:unify '(:a ?x ?x) '(:a 1 2))))
      (check "unify: ΦΩΛΙΑΣΜΕΝΟ pattern — μεταβλητή μέσα σε υπολίστα δεσμεύεται"
             (let ((b (orchestrator.inference:unify '(:a (:b ?x) ?y) '(:a (:b 1) 2))))
               (and (not (eq b :fail))
                    (eql 1 (cdr (assoc '?x b)))
                    (eql 2 (cdr (assoc '?y b))))))
      (check "unify: φωλιασμένη αναντιστοιχία ⇒ :fail"
             (eq :fail (orchestrator.inference:unify '(:a (:b ?x)) '(:a (:c 1)))))
      (check "unify: διαφορετικά μήκη ⇒ :fail"
             (eq :fail (orchestrator.inference:unify '(:a ?x) '(:a 1 2))))

      ;; ── 2. Παραγωγή, cascade, defeater, dangling — με αποδείξεις ──
      (let ((e (orchestrator.inference:make-inference-engine)))
        (orchestrator.inference:add-facts e
          '((:references "pk" "b" "pk" "a")     ; b → a
            (:references "pk" "c" "pk" "b")     ; c → b
            (:references "pk" "d" "pk" "c")     ; d → c
            (:references "pk" "x" "pk" "a")     ; x → a, αλλά το x είναι καταργημένο
            (:references "pk" "y" "pk" "r")     ; y → r (καταργημένο) ⇒ κρέμεται
            (:repealed "pk" "x")
            (:repealed "pk" "r")
            (:changed "pk" "a")))
        (orchestrator.inference:run-inference e)
        (let ((affected (mapcar #'car (orchestrator.inference:affected-by e "pk" "a"))))
          (check "άμεση επίπτωση: το b επηρεάζεται" (member "b" affected :test #'equal))
          (check "cascade: c και d επηρεάζονται μεταβατικά"
                 (and (member "c" affected :test #'equal)
                      (member "d" affected :test #'equal)))
          (check "defeater (well-founded): το καταργημένο x ΔΕΝ επηρεάζεται"
                 (not (member "x" affected :test #'equal)))
          (check "ακριβές σύνολο επιπτώσεων {b c d}" (= 3 (length affected))))
        (let ((proof (cdr (assoc "d" (orchestrator.inference:affected-by e "pk" "a")
                                 :test #'equal))))
          (check "η απόδειξη του d είναι :derived με κανόνα cascade"
                 (and proof (eq (first proof) :derived)
                      (eq (getf (cddr proof) :by)
                          'orchestrator.inference::cascade-amendment-impact))))
        (check "dangling: η παραπομπή του y στο καταργημένο r εντοπίζεται"
               (= 1 (length (orchestrator.inference:broken-references e))))
        ;; ── 3. Ιδεμποτότητα + ανάκληση (μακρόβια μηχανή) ──
        (let ((before (length (orchestrator.inference:jtms-believed-facts
                               (orchestrator.inference:engine-jtms e)))))
          (orchestrator.inference:run-inference e)
          (check "ιδεμποτότητα: δεύτερο run-inference δεν αλλάζει τίποτα"
                 (= before (length (orchestrator.inference:jtms-believed-facts
                                    (orchestrator.inference:engine-jtms e))))))
        (orchestrator.inference:tms-retract-premise
         (orchestrator.inference:engine-jtms e) '(:changed "pk" "a"))
        (check "ανάκληση (:changed): μηδέν :affected — όλα κατέρρευσαν σωστά"
               (null (orchestrator.inference:query e '(:affected ?c ?s :by ?a))))
        (orchestrator.inference:add-fact e '(:changed "pk" "c"))
        (orchestrator.inference:run-inference e)
        (check "επαναχρήση μηχανής: νέο ερώτημα (:changed c) ⇒ μόνο το d"
               (equal '("d") (mapcar #'car (orchestrator.inference:affected-by e "pk" "c")))))

      ;; ── 4. Βρόχοι αιτιολογήσεων: το well-founded τερματίζει και απαντά :out ──
      (let ((j (orchestrator.inference:make-jtms)))
        ;; περιττός βρόχος: p ⇐ ΟΧΙ p (παράδοξο) ⇒ :out, όχι αιωνία ταλάντωση
        (let ((p (orchestrator.inference:tms-intern j '(:p))))
          (orchestrator.inference:tms-justify j '(:p) '() (list p) 'paradox)
          (orchestrator.inference:recompute-beliefs j)
          (check "περιττός βρόχος (p ⇐ ¬p): :out και τερματισμός"
                 (not (orchestrator.inference:node-believed-p p))))
        ;; άρτιος βρόχος: a ⇐ ¬b, b ⇐ ¬a (αμοιβαίος αποκλεισμός χωρίς έρεισμα)
        ;; ⇒ και τα δύο αναποφάσιστα ⇒ :out (το well-founded δεν μαντεύει)
        (let ((a (orchestrator.inference:tms-intern j '(:a)))
              (b (orchestrator.inference:tms-intern j '(:b))))
          (orchestrator.inference:tms-justify j '(:a) '() (list b) 'even-loop)
          (orchestrator.inference:tms-justify j '(:b) '() (list a) 'even-loop)
          (orchestrator.inference:recompute-beliefs j)
          (check "άρτιος βρόχος (a ⇐ ¬b, b ⇐ ¬a): κανένα πιστευτό — δεν μαντεύω"
                 (and (not (orchestrator.inference:node-believed-p a))
                      (not (orchestrator.inference:node-believed-p b))))))

      ;; ── 4β. ΑΞΙΩΜΑΤΑ (κενό :when) — η αντιπαλική επιθεώρηση Φ2 βρήκε ότι το
      ;; ημι-αφελές μονοπάτι τα προσπερνούσε σιωπηλά· κλειδωμένο εδώ ──
      (let ((ax (make-instance 'orchestrator.inference:legal-rule
                               :name 'gate-axiom :when '() :unless '((:blocked))
                               :then '(:axiom-holds))))
        (let ((e (orchestrator.inference:make-inference-engine)))
          (orchestrator.inference:add-fact e '(:seed))
          (orchestrator.inference:run-inference e :rules (list ax))
          (check "αξίωμα (κενό :when): πυροδοτείται"
                 (= 1 (length (orchestrator.inference:query e '(:axiom-holds))))))
        (let ((e (orchestrator.inference:make-inference-engine)))
          (orchestrator.inference:add-fact e '(:blocked))
          (orchestrator.inference:run-inference e :rules (list ax))
          (check "αξίωμα με παρόντα defeater: ΔΕΝ πυροδοτείται"
                 (null (orchestrator.inference:query e '(:axiom-holds))))))

      ;; ── 4β2. :WHERE ΦΡΑΓΜΟΙ — αριθμητική/χρόνος ΜΕΣΑ στο αποδεικτικό υπόστρωμα
      ;; (χάρτης Α4): «εμπρόθεσμο ⇐ εντός 30 ημερών», με απόδειξη-υπολογισμό. ──
      (let ((proth (make-instance 'orchestrator.inference:legal-rule
                     :name 'gate-prothesmia
                     :when '((:επιδόθηκε ?π ?d0) (:κατατέθηκε ?π ?d1))
                     :where '((within-days ?d0 ?d1 30))
                     :then '(:εμπρόθεσμο ?π))))
        ;; 29 ημέρες ⇒ εμπρόθεσμο, ΚΑΙ ο υπολογισμός φαίνεται στην απόδειξη
        (let ((e1 (orchestrator.inference:make-inference-engine)))
          (orchestrator.inference:add-facts e1
            '((:επιδόθηκε :έφεση "2026-01-01") (:κατατέθηκε :έφεση "2026-01-30")))
          (orchestrator.inference:run-inference e1 :rules (list proth))
          (check "φραγμός within-days: 29 ημέρες ⇒ ΕΜΠΡΟΘΕΣΜΟ (:in)"
                 (= 1 (length (orchestrator.inference:query e1 '(:εμπρόθεσμο :έφεση)))))
          (let ((s (string-upcase
                    (format nil "~S"
                            (orchestrator.inference:explain
                             (orchestrator.inference:engine-jtms e1)
                             '(:εμπρόθεσμο :έφεση))))))
            (check "η απόδειξη φέρει τον ΥΠΟΛΟΓΙΣΜΟ (:υπολογισμός (within-days …))"
                   (and (search "ΥΠΟΛΟΓΙΣΜ" s) (search "WITHIN-DAYS" s)))
            ;; Ο ΜΕΤΑΚΥΚΛΙΚΟΣ ΠΥΡΓΟΣ ΟΡΑΤΟΣ: το ίχνος δείχνει ΟΛΗ την κάθοδο
            ;; within-days → days-between → ymd->day → σύγκριση — όχι μαύρο κουτί
            ;; (προθέματα χωρίς τελικό σίγμα: το string-upcase δεν κεφαλαιώνει το ς)
            (check "ΜΕΤΑ-ΑΠΟΤΙΜΗΤΗΣ: το ίχνος δείχνει τον πύργο αναγωγών (days-between, ymd->day)"
                   (and (search "ΊΧΝΟ" s) (search "DAYS-BETWEEN" s)
                        (search "YMD->DAY" s) (search "ΑΝΑΓΩΓ" s)))
            (check "κάθε γεγονός φραγμού στην απόδειξη φέρει :επαλήθευση :ανεξάρτητη"
                   (and (search "ΕΠΑΛ" s) (search "ΑΝΕΞΆΡΤΗΤ" s)))))
        ;; 31 ημέρες ⇒ ΕΚΠΡΟΘΕΣΜΟ: ο κανόνας ΔΕΝ πυροδοτεί (η διαφορά 29↔31 μετρά)
        (let ((e2 (orchestrator.inference:make-inference-engine)))
          (orchestrator.inference:add-facts e2
            '((:επιδόθηκε :έφεση "2026-01-01") (:κατατέθηκε :έφεση "2026-02-01")))
          (orchestrator.inference:run-inference e2 :rules (list proth))
          (check "φραγμός within-days: 31 ημέρες ⇒ ΕΚΠΡΟΘΕΣΜΟ (κανένα :in)"
                 (null (orchestrator.inference:query e2 '(:εμπρόθεσμο :έφεση))))))
      ;; αριθμητικός φραγμός ποσού: αρμοδιότητα ⇐ ποσό > 120.000
      (let ((armod (make-instance 'orchestrator.inference:legal-rule
                     :name 'gate-armodiotita
                     :when '((:αγωγή ?α ?ποσό))
                     :where '((> ?ποσό 120000))
                     :then '(:αρμόδιο :πολυμελές ?α))))
        (let ((e (orchestrator.inference:make-inference-engine)))
          (orchestrator.inference:add-facts e '((:αγωγή :α1 150000) (:αγωγή :α2 80000)))
          (orchestrator.inference:run-inference e :rules (list armod))
          (check "φραγμός >: 150.000 ⇒ πολυμελές, 80.000 ⇒ ΟΧΙ (ακριβές όριο)"
                 (and (= 1 (length (orchestrator.inference:query e '(:αρμόδιο :πολυμελές :α1))))
                      (null (orchestrator.inference:query e '(:αρμόδιο :πολυμελές :α2)))))))
      ;; ημερολογιακή ορθότητα ΔΙΑ μηνών — το ίχνος του μετα-αποτιμητή αποκάλυψε
      ;; παρενθετική παραδρομή στο doy (153·mp·2 αντί 153·mp+2)· κλειδωμένο:
      (check "ημερολόγιο: 2026-01-01→2026-02-15 = 45 ημέρες (διά μηνών) και epoch 1970-01-01 = ημέρα 0"
             (and (= 45 (orchestrator.metaeval:meta-eval
                         '(days-between "2026-01-01" "2026-02-15")))
                  (= 0 (orchestrator.metaeval:meta-eval '(ymd->day "1970-01-01")))
                  (= 366 (orchestrator.metaeval:meta-eval
                          '(days-between "2024-01-01" "2025-01-01"))))) ; δίσεκτο
      ;; ── Ο ΜΕΤΑ-ΑΠΟΤΙΜΗΤΗΣ ΩΣ ΓΛΩΣΣΑ: επέκταση, στρωμάτωση, προστασία πυρήνα ──
      (let ((snap (orchestrator.metaeval:ops-snapshot)))
        (unwind-protect
             (progn
               ;; νέος τελεστής ΣΤΗ γλώσσα, θεμελιωμένος σε υπάρχοντες — και χρήση σε κανόνα
               (orchestrator.metaeval:define-derived
                "ΕΝΤΟΣ-ΔΙΜΗΝΟΥ" '(α β) '(within-days α β 60) "δικονομικό δίμηνο (απλοποιημένο)")
               (let ((r (make-instance 'orchestrator.inference:legal-rule
                          :name 'gate-dimino
                          :when '((:επιδόθηκε ?π ?d0) (:κατατέθηκε ?π ?d1))
                          :where '((εντοσ-διμηνου ?d0 ?d1))
                          :then '(:εντός-διμήνου ?π)))
                     (e (orchestrator.inference:make-inference-engine)))
                 (orchestrator.inference:add-facts e
                   '((:επιδόθηκε :αίτηση "2026-01-01") (:κατατέθηκε :αίτηση "2026-02-15")))
                 (orchestrator.inference:run-inference e :rules (list r))
                 (check "ΕΠΕΚΤΑΣΗ ΩΣ ΓΝΩΣΗ: νέος τελεστής ορισμένος ΣΤΗ γλώσσα πυροδοτεί κανόνα"
                        (= 1 (length (orchestrator.inference:query e '(:εντός-διμήνου :αίτηση))))))
               ;; στρωμάτωση: ορισμός με ΑΓΝΩΣΤΟ τελεστή απορρίπτεται (τερματισμός εγγυημένος)
               (check "ΣΤΡΩΜΑΤΩΣΗ: ορισμός θεμελιωμένος σε άγνωστο τελεστή ⇒ σφάλμα, όχι αποδοχή"
                      (null (ignore-errors
                              (orchestrator.metaeval:define-derived
                               "ΚΑΚΟΣ" '(χ) '(ανύπαρκτος-τελεστής χ)))))
               ;; ο πυρήνας εμπιστοσύνης δεν σκιάζεται
               (check "ΠΥΡΗΝΑΣ: επανορισμός πρωτογενούς (π.χ. <) ⇒ σφάλμα"
                      (null (ignore-errors
                              (orchestrator.metaeval:define-derived "<" '(α β) '(> β α)))))
               ;; ΤΥΠΟΙ: κακότυπη γνώση απορρίπτεται ΣΤΟΝ ΟΡΙΣΜΟ, όχι στο ατύχημα
               (check "ΤΥΠΟΙ: (ymd->day <:int>) ⇒ απορρίπτεται τη στιγμή του ορισμού"
                      (null (ignore-errors
                              (orchestrator.metaeval:define-derived
                               "ΚΑΚΟΤΥΠΟΣ" '((α :int)) '(ymd->day α))))))
          (orchestrator.metaeval:ops-restore snap)))
      ;; ΓΛΩΣΣΑ ΟΛΙΚΗ ΚΑΙ ΕΚΦΡΑΣΤΙΚΗ (System T): IF + ITER + mod στη γλώσσα —
      ;; ιστορικές άγκυρες: 1970-01-01=Πέμπτη(3), 1970-01-03=Σάββατο, 1970-01-05=Δευτέρα
      (check "ΓΛΩΣΣΑ: ημέρα-εβδομάδας/εργάσιμη-p/επόμενη-εργάσιμη/ITER — όλα ΣΤΗ γλώσσα, ολικά"
             (and (= 3 (orchestrator.metaeval:meta-eval '(ημερα-εβδομαδασ 0)))
                  (eql t (orchestrator.metaeval:meta-eval '(εργασιμη-p 0)))
                  (null (orchestrator.metaeval:meta-eval '(εργασιμη-p 2)))
                  (= 4 (orchestrator.metaeval:meta-eval '(επομενη-εργασιμη 2)))
                  (= 8 (orchestrator.metaeval:meta-eval '(iter 5 επομενη-ημερα 3)))))
      ;; ΚΡΙΤΗΡΙΟ DE BRUIJN: ανεξάρτητος ελεγκτής με ΔΕΥΤΕΡΟ αλγόριθμο ημερολογίου
      (multiple-value-bind (v tr)
          (orchestrator.metaeval:meta-eval '(within-days "2026-01-01" "2026-01-30" 30))
        (check "DE BRUIJN: το πιστοποιητικό επαληθεύεται ανεξάρτητα (2ος αλγόριθμος ημερολογίου)"
               (and v (orchestrator.metaeval:verify-trace tr)))
        (check "DE BRUIJN: ΠΑΡΑΠΟΙΗΜΕΝΟ πιστοποιητικό ⇒ απορρίπτεται ονομαστικά"
               (let ((bad (copy-list tr)))
                 (setf (fourth bad) :ψεύδος)
                 (not (orchestrator.metaeval:verify-trace bad)))))

      ;; ── ΘΩΡΑΚΙΣΗ ΚΑΤΟΠΙΝ ΑΝΤΙΠΑΛΙΚΗΣ ΕΠΙΘΕΩΡΗΣΗΣ (31 ευρήματα, 05-07-2026) ──
      (let ((snap (orchestrator.metaeval:ops-snapshot)))
        (unwind-protect
             (progn
               ;; #1/6/14: IF με ατομικό επιλεγμένο κλάδο — ΤΙΜΙΟ πιστοποιητικό ΠΕΡΝΑ
               (orchestrator.metaeval:define-derived "GATE-MAX2" '((α :int) (β :int))
                                                     '(if (< α β) β α))
               (check "IF με ατομικό κλάδο: αληθής φραγμός ΠΕΡΝΑ με επαληθευμένο πιστοποιητικό"
                      (multiple-value-bind (ok facts)
                          (orchestrator.metaeval:guards-pass-p '((= (gate-max2 3 7) 7)) '())
                        (and ok (= 1 (length facts)))))
               ;; #2/24: πλαστό IF — αλλαγμένη τιμή Ή συνθήκη ⇒ απόρριψη
               (multiple-value-bind (v2 tr2)
                   (orchestrator.metaeval:meta-eval '(if (< 1 2) (+ 2 3) (+ 9 9)))
                 (declare (ignore v2))
                 (check "πλαστό IF (αλλαγμένη τιμή) ⇒ ο ελεγκτής το απορρίπτει"
                        (let ((bad (copy-list tr2)))
                          (setf (fourth bad) 999)
                          (not (orchestrator.metaeval:verify-trace bad))))
                 (check "πλαστό IF (αλλαγμένη δηλωθείσα συνθήκη) ⇒ ο ελεγκτής το απορρίπτει"
                        (let* ((bad (copy-list tr2)) (h (copy-list (second bad))))
                          (setf (third h) nil (second bad) h)
                          (not (orchestrator.metaeval:verify-trace bad)))))
               ;; #10/21/28: ΟΚΝΗΡΟ OR/AND — ο φρουρός διαίρεσης δεν σκάει ποτέ
               (check "οκνηρό OR: (or (= ν 0) (> (floor 10 ν) 2)) με ν=0 ⇒ περνά χωρίς κατάρρευση"
                      (nth-value 0 (orchestrator.metaeval:guards-pass-p
                                    '((or (= ?ν 0) (> (floor 10 ?ν) 2))) '((?ν . 0)))))
               ;; #7: ανύπαρκτη ημερομηνία ⇒ σφάλμα, ΟΧΙ σιωπηλή κανονικοποίηση
               (check "ανύπαρκτες ημερομηνίες (2026-02-30, 2026-13-01) ⇒ απορρίπτονται"
                      (and (null (ignore-errors
                                   (orchestrator.metaeval:meta-eval '(ymd->day "2026-02-30"))))
                           (null (ignore-errors
                                   (orchestrator.metaeval:meta-eval '(ymd->day "2026-13-01"))))))
               ;; #19: τελικό σίγμα — η φυσική ελληνική γραφή βρίσκει τον τελεστή
               (orchestrator.metaeval:define-derived "ΕΝΤΟΣ-ΜΗΝΟΣ" '((α :str) (β :str))
                                                     '(within-days α β 30))
               (check "τελικό ς: (εντος-μηνος …) βρίσκει τον τελεστή ΕΝΤΟΣ-ΜΗΝΟΣ"
                      (eql t (orchestrator.metaeval:meta-eval
                              '(εντος-μηνος "2026-01-01" "2026-01-15"))))
               ;; #11/27: επανορισμός μόνο προς κατώτερα στρώματα — κύκλος ΑΔΥΝΑΤΟΣ
               (orchestrator.metaeval:define-derived "GATE-X1" '((δ :int)) '(+ δ 1))
               (orchestrator.metaeval:define-derived "GATE-X2" '((δ :int)) '(gate-x1 δ))
               (check "επανορισμός με κύκλο (Χ1 := Χ2 ενώ Χ2 := Χ1) ⇒ σφάλμα — ο τερματισμός μένει θεώρημα"
                      (null (ignore-errors
                              (orchestrator.metaeval:define-derived "GATE-X1" '((δ :int))
                                                                    '(gate-x2 δ)))))
               (check "καλόπιστος επανορισμός (θεμελίωση σε κατώτερο στρώμα) ⇒ δεκτός"
                      (and (orchestrator.metaeval:define-derived "GATE-X1" '((δ :int)) '(+ δ 2)) t))
               ;; #8: variadic κάτω από την ελάχιστη πληθικότητα ⇒ στατικό σφάλμα
               (check "variadic με ορίσματα κάτω από το ελάχιστο ⇒ σφάλμα στον ορισμό"
                      (and (null (ignore-errors
                                   (orchestrator.metaeval:define-derived "GATE-KENO" '() '(+))))
                           (null (ignore-errors
                                   (orchestrator.metaeval:define-derived "GATE-MONO" '((α :int))
                                                                         '(< α))))))
               ;; #13: μη ακέραιο literal ⇒ σφάλμα στον ορισμό (ακέραια γλώσσα)
               (check "μη ακέραιο literal (3/2) ⇒ σφάλμα στον ορισμό"
                      (null (ignore-errors
                              (orchestrator.metaeval:define-derived "GATE-FLOAT" '((α :int))
                                                                    '(+ α 3/2)))))
               ;; #5: IF με μη-bool συνθήκη ⇒ στατικά ΚΑΙ δυναμικά απόρριψη
               (check "IF με συνθήκη :int ⇒ στατικό σφάλμα· (if 0 1 2) ⇒ σφάλμα εκτέλεσης"
                      (and (null (ignore-errors
                                   (orchestrator.metaeval:define-derived "GATE-IF0" '((α :int))
                                                                         '(if α 1 2))))
                           (null (ignore-errors
                                   (orchestrator.metaeval:meta-eval '(if 0 1 2))))))
               ;; #17: ΚΑΥΣΙΜΟ — φωλιασμένα ITER ⇒ τίμιο σφάλμα ορίου, όχι (max-iter)^2
               (orchestrator.metaeval:define-derived "GATE-BIGSTEP" '((δ :int))
                                                     '(iter 9999 επομενη-ημερα δ))
               (check "καύσιμο: φωλιασμένα ITER (9999×9999) ⇒ δηλωμένο όριο, όχι αιωνιότητα"
                      (null (ignore-errors
                              (orchestrator.metaeval:meta-eval '(iter 9999 gate-bigstep 0)))))
               ;; #3/29: ο ελεγκτής επιβάλλει τα ΙΔΙΑ όρια στο ITER
               (check "πλαστό ITER (αρνητικό n) ⇒ ο ελεγκτής το απορρίπτει"
                      (not (orchestrator.metaeval:verify-trace
                            '(:αναγωγή (:iter -5 :ΕΠΟΜΕΝΗ-ΗΜΕΡΑ 3) := 3))))
               ;; #30: εχθρικά βαθύ πιστοποιητικό ⇒ ήρεμη απόρριψη με λόγο
               (check "πιστοποιητικό βάθους 10000 ⇒ (nil λόγος), ποτέ κατάρρευση"
                      (let ((tr3 '(:αναγωγή (:+ 1 1) := 2)))
                        (dotimes (i 10000)
                          (setf tr3 (list :αναγωγή '(:+ 1 1) := 2 :διά (list tr3))))
                        (multiple-value-bind (ok why)
                            (orchestrator.metaeval:verify-trace tr3)
                          (and (not ok) why t)))))
          (orchestrator.metaeval:ops-restore snap)))
      ;; ── ΜΗΧΑΝΗ: ευρήματα #22/#23/#26/#12 ──
      (check "φωλιασμένο pattern με ?vars σε υπολίστα: το ταίριασμα ΔΕΝ μηδενίζεται σιωπηλά"
             (= 1 (length (orchestrator.inference:match-patterns
                           '((:deontic :prohibition (:πράξη ?δ ?τ) :by ?n))
                           '((:deontic :prohibition (:πράξη :Α :κλοπή) :by :n1))))))
      (check "instantiate ΒΑΘΥ: φωλιασμένα ?vars δεσμεύονται σε κάθε βάθος"
             (equal '(:a (:b 1)) (orchestrator.inference::instantiate
                                  '(:a (:b ?x)) '((?x . 1)))))
      (check "μη ασφαλής κανόνας (:unless με ελεύθερη ?y) ⇒ απορρίπτεται στη ΔΗΜΙΟΥΡΓΙΑ"
             (null (ignore-errors
                     (make-instance 'orchestrator.inference:legal-rule
                                    :name 'gate-unsafe :when '((:p ?x))
                                    :unless '((:q ?y)) :then '(:r ?x)))))
      (check "μη-bool :where φραγμός ⇒ απορρίπτεται στη ΔΗΜΙΟΥΡΓΙΑ κανόνα"
             (null (ignore-errors
                     (make-instance 'orchestrator.inference:legal-rule
                                    :name 'gate-nonbool :when '((:p ?x))
                                    :where '((+ ?x 1)) :then '(:r ?x)))))

      ;; ── 4γ. ΜΗ-ΣΤΡΩΜΑΤΟΠΟΙΗΜΕΝΟ πρόγραμμα: το ΚΑΝΟΝΙΚΟ well-founded μοντέλο
      ;; (η αντιπαλική επιθεώρηση Φ2 απέδειξε ότι η παλαιά γείωση υπο-γείωνε και
      ;; «αποφάσιζε» το αναποφάσιστο ως ψευδές — εδώ κλειδώνει το ΣΩΣΤΟ):
      ;; R1: ff ⇐ aa, ¬ff  (περιττός βρόχος ⇒ ff ΑΝΑΠΟΦΑΣΙΣΤΟ)
      ;; R2: hh ⇐ ff       (μεταδίδεται ⇒ hh αναποφάσιστο)
      ;; R3: zz ⇐ aa, ¬hh  (defeater αναποφάσιστος ⇒ zz αναποφάσιστο, ΟΧΙ πιστευτό)
      (let ((r1 (make-instance 'orchestrator.inference:legal-rule
                               :name 'gate-r1 :when '((:aa)) :unless '((:ff)) :then '(:ff)))
            (r2 (make-instance 'orchestrator.inference:legal-rule
                               :name 'gate-r2 :when '((:ff)) :then '(:hh)))
            (r3 (make-instance 'orchestrator.inference:legal-rule
                               :name 'gate-r3 :when '((:aa)) :unless '((:hh)) :then '(:zz)))
            (e (orchestrator.inference:make-inference-engine)))
        (orchestrator.inference:add-fact e '(:aa))
        (orchestrator.inference:run-inference e :rules (list r1 r2 r3))
        (check "μη-στρωματοποιημένο: aa πιστευτό, ff/hh/zz αναποφάσιστα ⇒ ΜΗ πιστευτά (δεν μαντεύω)"
               (and (= 1 (length (orchestrator.inference:query e '(:aa))))
                    (null (orchestrator.inference:query e '(:ff)))
                    (null (orchestrator.inference:query e '(:hh)))
                    (null (orchestrator.inference:query e '(:zz))))))

      ;; ── 5. Η ΜΙΑ υλοποίηση ταιριάσματος: match-patterns και για τον L5 ──
      (let ((states (orchestrator.inference:match-patterns
                     '((:deontic :prohibition ?act :by ?n))
                     '((:deontic :prohibition (:κλοπή) :by :norm-1)
                       (:deontic :permission (:χρήση) :by :norm-2)))))
        (check "match-patterns: 1 ταίριασμα με σωστές δεσμεύσεις"
               (and (= 1 (length states))
                    (equal '(:κλοπή) (cdr (assoc '?act (car (first states))))))))

      ;; ── 6. Impact γράφου: ΑΛΗΘΙΝΟ BFS — εκεί που η DFS αποτύγχανε σιωπηλά ──
      ;; Δομή: ο X φτάνει στον Τ από ΚΟΝΤΙΝΟ δρόμο (βάθος 2) και από ΜΑΚΡΙΝΟ
      ;; (βάθος 5)· κάτω από τον X κρέμεται αλυσίδα Y1..Y4. Με max-depth 6 η
      ;; DFS που πρωτόβλεπε τον X στο βάθος 5 έκοβε τα Y2..Y4 — εντός ορίζοντα!
      (let ((orchestrator.graph:*graph* (orchestrator.graph:make-graph)))
        (flet ((n (id) (orchestrator.graph:add-node id))
               (dep (from to) (orchestrator.graph:relate from :cites to)))
          (mapc #'n '("T" "A" "B" "C" "D" "S" "X" "Y1" "Y2" "Y3" "Y4"))
          ;; μακρινός δρόμος: A→T, B→A, C→B, D→C, X→D  (X σε βάθος 5)
          (dep "A" "T") (dep "B" "A") (dep "C" "B") (dep "D" "C") (dep "X" "D")
          ;; κοντινός δρόμος: S→T, X→S  (X σε βάθος 2)
          (dep "S" "T") (dep "X" "S")
          ;; η αλυσίδα κάτω από τον X
          (dep "Y1" "X") (dep "Y2" "Y1") (dep "Y3" "Y2") (dep "Y4" "Y3"))
        (multiple-value-bind (affected beyond)
            (orchestrator.graph-reason:impact "T" :max-depth 6)
          (let ((ids (mapcar #'car affected)))
            (check "BFS: ΟΛΟΙ οι 10 εξαρτώμενοι κόμβοι βρίσκονται εντός ορίζοντα"
                   (= 10 (length ids)))
            (check "BFS: τα Y2..Y4 ΔΕΝ χάνονται (η παλαιά DFS τα έχανε)"
                   (and (member "Y2" ids :test #'equal)
                        (member "Y3" ids :test #'equal)
                        (member "Y4" ids :test #'equal)))
            (check "BFS: η διαδρομή-απόδειξη του X είναι η ΕΛΑΧΙΣΤΗ (2 ακμές)"
                   (= 2 (length (cdr (assoc "X" affected :test #'equal)))))
            (check "BFS: μηδενική αποκοπή δηλωμένη (πλήρης κάλυψη)"
                   (zerop beyond))))
        (multiple-value-bind (affected beyond)
            (orchestrator.graph-reason:impact "T" :max-depth 1)
          (check "BFS: όριο 1 ⇒ 2 άμεσοι + ΡΗΤΗ δήλωση των πέραν του ορίζοντα"
                 (and (= 2 (length affected)) (plusp beyond)))))

      ;; ── 6β. ΣΕΙΡΙΟΠΟΙΗΣΗ ΓΡΑΦΟΥ (Φάση 3): πλήρες round-trip — τίποτα δεν
      ;; «ξαναγεννιέται» αλλιώτικο: αναλλοίωτα, ανακλήσεις, αιτιολογήσεις,
      ;; χρονικότητα, και ίδιο αποτέλεσμα συλλογισμού στον φορτωμένο γράφο ──
      (let ((tmp (merge-pathnames (format nil "gate-graph-~D.sexp" (get-universal-time))
                                  (uiop:temporary-directory)))
            (orchestrator.graph:*graph* (orchestrator.graph:make-graph)))
        (orchestrator.graph:add-node "a" :label "Άλφα" :props '(:k "v"))
        (orchestrator.graph:add-node "b" :label "Βήτα"
          :validity (orchestrator.graph:make-validity "2020-01-01" nil))
        (orchestrator.graph:add-node "c")
        (orchestrator.graph:relate "b" :cites "a"
          :justification (orchestrator.graph:derived "παραπομπή" "τεκμ-1"))
        (orchestrator.graph:retract (orchestrator.graph:relate "c" :cites "a") "λόγος")
        (orchestrator.graph:save-graph tmp :meta '(:stamp (1 2 3)))
        (multiple-value-bind (g nn ne meta) (orchestrator.graph:load-graph tmp)
          (check "σειριοποίηση: πλήθη + meta επιστρέφουν ακέραια"
                 (and g (= nn 3) (= ne 2) (equal (getf meta :stamp) '(1 2 3))))
          (let ((a (orchestrator.graph:node "a" g))
                (b (orchestrator.graph:node "b" g)))
            (check "σειριοποίηση: label/props/validity διατηρούνται"
                   (and (equal "Άλφα" (orchestrator.graph:node-label a))
                        (equal "v" (orchestrator.graph:node-prop a :k))
                        (equal "2020-01-01"
                               (orchestrator.graph:validity-from
                                (orchestrator.graph:assertion-validity b))))))
          (check "σειριοποίηση: η ΑΝΑΚΛΗΣΗ διατηρείται — η ανακληθείσα ακμή δεν «ξαναζεί»"
                 (= 1 (length (orchestrator.graph:in-edges "a" :graph g))))
          (check "σειριοποίηση: η αιτιολόγηση :derived ακέραιη (κανόνας+προϋποθέσεις)"
                 (let ((e (first (orchestrator.graph:in-edges "a" :graph g))))
                   (and (eq :derived (orchestrator.graph:justification-kind
                                      (orchestrator.graph:assertion-justification e)))
                        (equal '("τεκμ-1")
                               (orchestrator.graph:justification-antecedents
                                (orchestrator.graph:assertion-justification e))))))
          (check "σειριοποίηση: ο συλλογισμός impact ΤΑΥΤΙΖΕΤΑΙ στον φορτωμένο γράφο"
                 (equal (mapcar #'car (orchestrator.graph-reason:impact "a"))
                        (mapcar #'car (orchestrator.graph-reason:impact "a" :graph g)))))
        (ignore-errors (delete-file tmp)))

      ;; ── 7. Κλίμακα: αλυσίδα 3000 — ακριβής, σε λογικό χρόνο ──
      (let ((e (orchestrator.inference:make-inference-engine))
            (nn 3000))
        (dotimes (i (1- nn))
          (orchestrator.inference:add-fact e
            (list :references "pk" (format nil "~D" (1+ i)) "pk" (format nil "~D" i))))
        (orchestrator.inference:add-fact e '(:changed "pk" "0"))
        (let ((t0 (get-internal-real-time)))
          (orchestrator.inference:run-inference e)
          (let ((secs (/ (- (get-internal-real-time) t0)
                         internal-time-units-per-second))
                (n (length (orchestrator.inference:query e '(:affected ?c ?s :by ?a)))))
            (check (format nil "κλίμακα: αλυσίδα ~D ⇒ ~D επιπτώσεις (ακριβώς) σε ~,1Fs"
                           nn (1- nn) (float secs))
                   (and (= (1- nn) n) (< secs 30)))))))
    (format t "~%── ΠΥΛΗ ΣΥΜΠΕΡΑΣΜΟΥ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--inference-gate" (lambda (a) (declare (ignore a)) (run-inference-gate)))
(register-command "--guard-language"
                  (lambda (a) (declare (ignore a))
                    ;; η γλώσσα των φραγμών περιγράφει ΤΟΝ ΕΑΥΤΟ ΤΗΣ — ζωντανά
                    (orchestrator.metaeval:describe-language) 0))

(orchestrator.self-model:declare-capability! "λογισμός-φραγμών"
 :description "αριθμητικός/χρονικός λογισμός με πιστοποιητικά de Bruijn (μετακυκλικός αποτιμητής)"
 :package :orchestrator.metaeval :functions '("meta-eval" "guards-pass-p" "verify-guard")
 :gate "--inference-gate" :depends-on '())
(orchestrator.self-model:declare-capability! "συμπερασμός-wfs"
 :description "μη-μονότονος συμπερασμός WFS/JTMS με δέντρα απόδειξης και ανάκληση"
 :package :orchestrator.inference :functions '("run-inference" "explain" "query")
 :gate "--inference-gate" :depends-on '("λογισμός-φραγμών"))

;;; ── ΣΥΜΒΟΛΑΙΑ ΠΑΡΟΧΩΝ (δεσμευτική αυτοπεριγραφή — βλ. --contract-gate) ──

(orchestrator.contracts:defcontract "meta-eval" :function
 :package :orchestrator.metaeval :system "orchestrator-infrastructure"
 :capability "λογισμός-φραγμών" :role "αποδείξεις"
 :purpose "μετακυκλική αποτίμηση κλειστής έκφρασης με ορατό ίχνος και καύσιμο"
 :inputs '("έκφραση της εσωτερικής γλώσσας") :outputs '("τιμή" "ίχνος")
 :preconditions '("η έκφραση περνά στατικό έλεγχο τύπων")
 :postconditions '("ίδια έκφραση ⇒ ίδια τιμή· το ίχνος αναπαράγει τον υπολογισμό")
 :legal-critical t :policy-level :φραγή
 :failure-modes '("εξάντληση καυσίμου — ρητή, ποτέ σιωπηλή")
 :tests '("--inference-gate"))

(orchestrator.contracts:defcontract "guards-pass-p" :function
 :package :orchestrator.metaeval :system "orchestrator-infrastructure"
 :capability "λογισμός-φραγμών" :role "αποδείξεις"
 :purpose "κρίση φρουρών κανόνων με πιστοποιητικά υπολογισμού στα γεγονότα"
 :inputs '("δεσμεύσεις μεταβλητών" "φρουροί") :outputs '("T/NIL" "γεγονότα :υπολογισμός με ίχνος")
 :postconditions '("κάθε επιτυχής φρουρός φέρει πιστοποιητικό με :επαλήθευση :ανεξάρτητη")
 :legal-critical t :policy-level :φραγή
 :proof-obligations '("το πιστοποιητικό επαληθεύεται από τον ανεξάρτητο ελεγκτή")
 :tests '("--inference-gate"))

(orchestrator.contracts:defcontract "verify-guard" :function
 :package :orchestrator.metaeval :system "orchestrator-infrastructure"
 :capability "λογισμός-φραγμών" :role "αποδείξεις"
 :purpose "ΑΝΕΞΑΡΤΗΤΗ επαλήθευση πιστοποιητικού — δεύτερος αλγόριθμος, όχι ο παραγωγός"
 :inputs '("πιστοποιητικό") :outputs '("T/NIL")
 :postconditions '("δεν εμπιστεύεται τον παραγωγό: πλήρης επαναϋπολογισμός + τοπικός έλεγχος κόμβων")
 :legal-critical t :policy-level :φραγή
 :tests '("--inference-gate"))

(orchestrator.contracts:defcontract "run-inference" :function
 :package :orchestrator.inference :system "orchestrator-infrastructure"
 :capability "συμπερασμός-wfs" :role "αποδείξεις"
 :purpose "μη-μονότονος συμπερασμός: ημι-αφελής γείωση + well-founded μοντέλο + JTMS"
 :inputs '("γεγονότα" "κανόνες") :outputs '("συμπεράσματα με δέντρα απόδειξης")
 :postconditions '("κάθε συμπέρασμα δικαιολογημένο· νέα γνώση ⇒ αυτόματη ανάκληση των εξαρτημένων")
 :legal-critical t :policy-level :φραγή
 :failure-modes '("βρόχοι άρνησης ⇒ WFS undefined — δηλωμένο, όχι αυθαίρετο")
 :tests '("--inference-gate" "--iq-gate"))

(orchestrator.contracts:defcontract "explain" :function
 :package :orchestrator.inference :system "orchestrator-infrastructure"
 :capability "συμπερασμός-wfs" :role "αποδείξεις"
 :purpose "το δέντρο απόδειξης ενός συμπεράσματος — η βάση κάθε νομικής αιτιολογίας"
 :inputs '("JTMS" "συμπέρασμα") :outputs '("δέντρο απόδειξης με πιστοποιητικά")
 :postconditions '("κάθε φύλλο = γεγονός ή πιστοποιητικό· ποτέ κρυφό βήμα")
 :legal-critical t :policy-level :φραγή
 :tests '("--inference-gate" "--event-gate"))

(orchestrator.contracts:defcontract "query" :function
 :package :orchestrator.inference :system "orchestrator-infrastructure"
 :capability "συμπερασμός-wfs" :role "αποδείξεις"
 :purpose "ερώτημα με μοτίβο στα IN συμπεράσματα της μηχανής"
 :inputs '("μηχανή" "μοτίβο με μεταβλητές") :outputs '("δεσμεύσεις")
 :postconditions '("επιστρέφει ΜΟΝΟ όσα είναι IN τώρα — ποτέ ανακληθέντα")
 :legal-critical t :policy-level :φραγή
 :tests '("--inference-gate"))
