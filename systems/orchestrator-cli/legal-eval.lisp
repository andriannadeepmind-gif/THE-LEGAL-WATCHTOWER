;;;; systems/orchestrator-cli/legal-eval.lisp
;;;; ============================================================================
;;;; Η ΜΕΤΡΗΜΕΝΗ ΣΚΑΛΑ — benchmark: αφήγηση → γεγονότα → υπαγωγή → διατακτικό
;;;; ============================================================================
;;;;
;;;; «Πόσο έξυπνο είναι;» δεν απαντιέται με λόγια — μετριέται, όπως στο --judge.
;;;; Το --judge μετρά τη ΝΟΜΟΛΟΓΙΑ (συν-εφαρμογή διατάξεων). Εδώ μετριέται ο
;;;; ΠΥΡΗΝΑΣ ΣΥΛΛΟΓΙΣΜΟΥ end-to-end, με τον άξονα που ήταν ΑΜΕΤΡΗΤΟΣ: η ΓΕΙΩΣΗ
;;;; (φυσική γλώσσα → γεγονότα). Καμία νέα μηχανή — προβολή των υπαρχουσών εδρών
;;;; (casegrammar:parse-narrative + subsumption:subsume/conclusion-status).
;;;;
;;;; ΤΡΕΙΣ αριθμοί, ο καθένας απομονώνει ένα στάδιο (πρότυπο AlphaProof: μέτρα
;;;; κάθε στάδιο ΧΩΡΙΣΤΑ ΚΑΙ end-to-end — έτσι ξέρεις ΠΟΥ χάνεται):
;;;;
;;;;   ① ΜΗΧΑΝΗ-ΣΕ-GOLD : δίνε τα ΣΩΣΤΑ (χειρόγραφα) γεγονότα → σωστό status;
;;;;                       (απομονώνει τον συμβολικό δικαστή· πρέπει ≈100%)
;;;;   ② END-TO-END      : δίνε την ΑΦΗΓΗΣΗ → parse → status· ο ΠΡΑΓΜΑΤΙΚΟΣ αριθμός
;;;;   ③ ΧΑΣΜΑ ①−②       : ΑΚΡΙΒΩΣ το κόστος της ατελούς γείωσης — ο δείκτης-στόχος
;;;;
;;;; Η ΤΙΜΙΟΤΗΤΑ ΤΟΥ ΜΕΤΡΟΥ: τα gold-facts γράφονται ΑΝΕΞΑΡΤΗΤΑ (τι ΠΡΕΠΕΙ να
;;;; εξαχθεί), ΟΧΙ αντιγράφοντας την έξοδο του parser (καμία ταυτολογία). Το
;;;; status κρίνεται με ΜΕΤΑΒΛΗΤΕΣ (?δράστης) — ανεξάρτητο από ονόματα οντοτήτων,
;;;; άρα έγκυρο. Υπάρχουν ΑΝΤΙΠΑΛΙΚΕΣ αφηγήσεις (:adversarial) που ο parser
;;;; ΞΕΡΟΥΜΕ ότι δυσκολεύεται — για να ΦΑΙΝΕΤΑΙ το χάσμα, όχι να κρύβεται.
;;;; ============================================================================

(in-package :orchestrator.cli)

(defparameter +legal-eval-cases+
  '((:id "klopi-full" :tags (:core :pk-372)
     :narrative "Ο δράστης αφαίρεσε τα ξένα κινητά εργαλεία με σκοπό την παράνομη ιδιοποίηση."
     :gold-facts ((:γεγονός :Α :αφαιρεί :εργαλεία)
                  (:γεγονός :εργαλεία :είναι :κινητό)
                  (:γεγονός :εργαλεία :είναι :ξένο)
                  (:γεγονός :Α :σκοπός :παράνομη-ιδιοποίηση))
     :expect ((:norm-klopi-372 . :in)))

    (:id "klopi-no-purpose" :tags (:core :pk-372)
     :narrative "Ο δράστης αφαίρεσε τα ξένα κινητά εργαλεία."
     :gold-facts ((:γεγονός :Α :αφαιρεί :εργαλεία)
                  (:γεγονός :εργαλεία :είναι :κινητό)
                  (:γεγονός :εργαλεία :είναι :ξένο))
     :expect ((:norm-klopi-372 . :not-triggered)))

    (:id "klopi-consent" :tags (:core :pk-372 :defeater)
     :narrative "Ο δράστης αφαίρεσε τα ξένα κινητά εργαλεία με σκοπό την παράνομη ιδιοποίηση, αλλά είχε τη συναίνεση του κατόχου."
     :gold-facts ((:γεγονός :Α :αφαιρεί :εργαλεία)
                  (:γεγονός :εργαλεία :είναι :κινητό)
                  (:γεγονός :εργαλεία :είναι :ξένο)
                  (:γεγονός :Α :σκοπός :παράνομη-ιδιοποίηση)
                  (:γεγονός :Α :έχει-συναίνεση-κατόχου :εργαλεία))
     :expect ((:norm-klopi-372 . :out)))

    (:id "ypexairesi" :tags (:core :pk-375)
     :narrative "Ο ταμίας ιδιοποιήθηκε το ξένο κινητό ποσό που ήταν στην κατοχή του."
     :gold-facts ((:γεγονός :Ζ :ιδιοποιείται :ποσό)
                  (:γεγονός :ποσό :είναι :κινητό)
                  (:γεγονός :ποσό :είναι :ξένο)
                  (:γεγονός :ποσό :στην-κατοχή-του :Ζ))
     :expect ((:norm-ypexairesi-375 . :in) (:norm-klopi-372 . :not-triggered)))

    (:id "anthr-dolus" :tags (:core :pk-299)
     :narrative "Ο δράστης θανάτωσε τον παθόντα με δόλο."
     :gold-facts ((:γεγονός :Β :θανατώνει :Γ)
                  (:γεγονός :Β :ενεργεί-με :δόλο))
     :expect ((:norm-anthropoktonia-299 . :in)))

    (:id "anthr-selfdefense" :tags (:core :pk-299 :defeater)
     :narrative "Ο δράστης θανάτωσε τον παθόντα με δόλο, ενώ τελούσε σε νόμιμη άμυνα."
     :gold-facts ((:γεγονός :Β :θανατώνει :Γ)
                  (:γεγονός :Β :ενεργεί-με :δόλο)
                  (:γεγονός :Β :τελεί-σε :νόμιμη-άμυνα))
     :expect ((:norm-anthropoktonia-299 . :out)))

    (:id "adikopraxia" :tags (:core :ak-914)
     :narrative "Ο εναγόμενος ζημίωσε τον ενάγοντα ενεργώντας παράνομα και υπαίτια."
     :gold-facts ((:γεγονός :Δ :ζημιώνει :Ε)
                  (:γεγονός :Δ :ενεργεί :παράνομα)
                  (:γεγονός :Δ :ενεργεί :υπαίτια))
     :expect ((:norm-adikopraxia-914 . :in)))

    ;; ── ΑΝΤΙΠΑΛΙΚΕΣ: ξέρουμε ότι η γείωση δυσκολεύεται· ο δικαστής (① gold) τις
    ;;    λύνει, το end-to-end (②) όχι — έτσι το ΧΑΣΜΑ γίνεται ορατό, όχι κρυφό.
    (:id "anthr-freeorder" :tags (:adversarial :pk-299 :word-order)
     :narrative "Σε βρασμό ψυχικής ορμής, τον παθόντα τον θανάτωσε με δόλο ο δράστης."
     :gold-facts ((:γεγονός :Β :θανατώνει :Γ)
                  (:γεγονός :Β :ενεργεί-με :δόλο))
     :expect ((:norm-anthropoktonia-299 . :in)))

    (:id "klopi-paraphrase" :tags (:adversarial :pk-372 :lexicon)
     :narrative "Υφαίρεσε ξένη κινητή περιουσία επιδιώκοντας να την οικειοποιηθεί παρανόμως."
     :gold-facts ((:γεγονός :Α :αφαιρεί :περιουσία)
                  (:γεγονός :περιουσία :είναι :κινητό)
                  (:γεγονός :περιουσία :είναι :ξένο)
                  (:γεγονός :Α :σκοπός :παράνομη-ιδιοποίηση))
     :expect ((:norm-klopi-372 . :in))))
  "Το gold benchmark (σπόρος, αυξάνεται). Κάθε υπόθεση: αφήγηση + ΑΝΕΞΑΡΤΗΤΑ
   γραμμένα gold-facts + αναμενόμενο status ανά νόρμα. :adversarial = γνωστά
   δύσκολη γείωση.")

;;; ── Έδρα κρίσης status (ΙΔΙΑ με την --subsumption-gate· καμία δεύτερη) ──

(defun %legal-eval-status (facts norm-id)
  "Status νόρμας δοθέντων γεγονότων — προβολή της subsumption έδρας."
  (let ((norm (orchestrator.deontic:find-norm norm-id)))
    (and norm
         (orchestrator.subsumption:conclusion-status
          (orchestrator.subsumption:subsume facts) norm facts))))

(defun %legal-eval-case (case)
  "Τρέχει ΜΙΑ υπόθεση. Επιστρέφει plist:
     :id :tags :expect-count
     :engine-ok  (πόσα expect status ταιριάζουν με ΤΑ GOLD facts)
     :e2e-ok     (πόσα ταιριάζουν με ΤΑ ΕΞΑΓΜΕΝΑ facts από την αφήγηση)
     :gold-fact-n :extracted-fact-n :unparsed-n"
  (let* ((gold (getf case :gold-facts))
         (expect (getf case :expect)))
    (multiple-value-bind (extracted unparsed)
        (orchestrator.casegrammar:parse-narrative (getf case :narrative))
      ;; ΑΥΣΤΗΡΟΤΗΤΑ: το :not-triggered περνά ΚΑΙ με κενή εξαγωγή (ψευδής πίστωση).
      ;; Γι' αυτό μετριέται ΞΕΧΩΡΙΣΤΑ το «θετικό» υποσύνολο (:in/:out) — εκεί η
      ;; υπο-εξαγωγή ΔΕΝ μπορεί να δώσει σωστό status τυχαία (ο απαιτητικός αριθμός).
      (let ((engine-ok 0) (e2e-ok 0) (pos-count 0) (engine-pos 0) (e2e-pos 0))
        (dolist (pair expect)
          (let* ((norm-id (car pair)) (want (cdr pair))
                 (positivep (member want '(:in :out)))
                 (eng (eq want (%legal-eval-status gold norm-id)))
                 (e2e (eq want (%legal-eval-status extracted norm-id))))
            (when eng (incf engine-ok)) (when e2e (incf e2e-ok))
            (when positivep
              (incf pos-count)
              (when eng (incf engine-pos)) (when e2e (incf e2e-pos)))))
        (list :id (getf case :id) :tags (getf case :tags)
              :expect-count (length expect)
              :engine-ok engine-ok :e2e-ok e2e-ok
              :pos-count pos-count :engine-pos engine-pos :e2e-pos e2e-pos
              :gold-fact-n (length gold)
              :extracted-fact-n (length extracted)
              :unparsed-n (length unparsed))))))

(defun %legal-eval-run (&optional (cases +legal-eval-cases+))
  "Ολόκληρο το benchmark ως ΔΕΔΟΜΕΝΑ (ντετερμινιστικά· καμία εκτύπωση). Το
   καταναλώνουν και η εντολή (τυπώνει) και το τεστ (κλειδώνει)."
  (orchestrator.knowledge-packs:ensure-fresh)   ; λεξικό casegrammar + νόρμες ζωντανά
  (let ((rows (mapcar #'%legal-eval-case cases))
        (etot 0) (eok 0) (tok 0) (ptot 0) (epok 0) (tpok 0))
    (dolist (r rows)
      (incf etot (getf r :expect-count)) (incf eok (getf r :engine-ok)) (incf tok (getf r :e2e-ok))
      (incf ptot (getf r :pos-count)) (incf epok (getf r :engine-pos)) (incf tpok (getf r :e2e-pos)))
    (list :engine-total etot :engine-ok eok
          :e2e-total etot :e2e-ok tok
          :pos-total ptot :engine-pos epok :e2e-pos tpok   ; ΤΟ ΑΠΑΙΤΗΤΙΚΟ (:in/:out μόνο)
          :rows rows)))

(defun %pct (n d) (if (zerop d) 0.0 (float (/ (* 100 n) d))))

(defun run-legal-eval ()
  "--legal-eval : η μετρημένη σκάλα. Τυπώνει ①μηχανή-σε-gold ②end-to-end ③χάσμα,
   ανά υπόθεση + συγκεντρωτικά, με το τίμιο ταβάνι (αδιάβαστες προτάσεις). Read-only."
  (let* ((res (%legal-eval-run))
         (eok (getf res :engine-ok)) (etot (getf res :engine-total))
         (tok (getf res :e2e-ok)) (ttot (getf res :e2e-total)))
    (format t "~%── ΜΕΤΡΗΜΕΝΗ ΣΚΑΛΑ: αφήγηση → γεγονότα → υπαγωγή (~D υποθέσεις) ──~%~%"
            (length (getf res :rows)))
    (format t "  ~4@A  ~4@A  ~5@A  ~A~%" "①μηχ" "②e2e" "άδιαβ" "υπόθεση (tags)")
    (dolist (r (getf res :rows))
      (format t "  ~2D/~D  ~2D/~D  ~5D  ~A ~(~A~)~@[  ⚠ΧΑΣΜΑ ΓΕΙΩΣΗΣ~]~%"
              (getf r :engine-ok) (getf r :expect-count)
              (getf r :e2e-ok) (getf r :expect-count)
              (getf r :unparsed-n) (getf r :id) (getf r :tags)
              (and (< (getf r :e2e-ok) (getf r :engine-ok)))))
    (let ((ptot (getf res :pos-total)) (epok (getf res :engine-pos)) (tpok (getf res :e2e-pos)))
      (format t "~%  ① ΜΗΧΑΝΗ-ΣΕ-GOLD (ο συμβολικός δικαστής): ~D/~D = ~,1F%~%"
              eok etot (%pct eok etot))
      (format t "  ② END-TO-END (ο πραγματικός αριθμός σήμερα): ~D/~D = ~,1F%~%"
              tok (getf res :e2e-total) (%pct tok (getf res :e2e-total)))
      (format t "  ③ ΧΑΣΜΑ ΓΕΙΩΣΗΣ ①−② = ~,1F μονάδες — ΑΚΡΙΒΩΣ το κόστος γλώσσα→γεγονότα~%"
              (- (%pct eok etot) (%pct tok (getf res :e2e-total))))
      (format t "~%  ⊕ ΑΠΑΙΤΗΤΙΚΟ (μόνο :in/:out — καμία ψευδής πίστωση από :not-triggered):~%")
      (format t "     μηχανή ~D/~D=~,1F%  ·  end-to-end ~D/~D=~,1F%  ·  χάσμα ~,1F μονάδες~%"
              epok ptot (%pct epok ptot) tpok ptot (%pct tpok ptot)
              (- (%pct epok ptot) (%pct tpok ptot))))
    0))

(register-command "--legal-eval" (lambda (a) (declare (ignore a)) (run-legal-eval)))
