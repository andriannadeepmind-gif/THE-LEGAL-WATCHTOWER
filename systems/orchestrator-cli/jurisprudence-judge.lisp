;;;; systems/orchestrator-cli/jurisprudence-judge.lisp
;;;; ============================================================================
;;;; Ο ΚΡΙΤΗΣ-ΝΟΜΟΛΟΓΙΑ — μετρημένη ικανότητα, όχι ισχυρισμός
;;;; ============================================================================
;;;;
;;;; «Πόσο καλά ξέρει το δίκαιο ΣΤΗΝ ΠΡΑΞΗ;» δεν απαντιέται με λόγια — μετριέται.
;;;; Το ground truth είναι η ίδια η νομολογία: ποιες διατάξεις εφάρμοσαν ΠΡΑΓΜΑΤΙ
;;;; τα δικαστήρια μαζί. Πείραμα leave-one-out, πλήρως ντετερμινιστικό:
;;;;
;;;;   Για κάθε απόφαση που εφάρμοσε ≥2 διατάξεις: κρύψε μία· ζήτα από το σύστημα
;;;;   να την προβλέψει από τις υπόλοιπες, με γνώση ΜΟΝΟ των ΑΛΛΩΝ αποφάσεων
;;;;   (η κρινόμενη αφαιρείται από τη γνώση — καμία διαρροή). Πρόβλεψη = κατάταξη
;;;;   κατά συχνότητα συν-εφαρμογής. Μέτρο: hit@1 / hit@5 / hit@10.
;;;;
;;;; Ο αριθμός δημοσιεύεται ΜΑΖΙ με το τίμιο ταβάνι του (πόσες κρυμμένες ήταν καν
;;;; προβλέψιμες — εμφανίζονται σε άλλη απόφαση;) και με τις αποτυχίες ορατές.
;;;; Έτσι η «εξυπνάδα» του συστήματος αποκτά μονάδα μέτρησης — και κάθε βελτίωση
;;;; (πχ όταν μπουν τα :cites ή το δεοντικό επίπεδο στην κατάταξη) ΑΠΟΔΕΙΚΝΥΕΤΑΙ
;;;; με σύγκριση αριθμών, όχι με εντυπώσεις.
;;;;
;;;; Καμία νέα αποθήκη: διαβάζει τις σχέσεις «εφαρμόζει» από τον ενιαίο γράφο.

(in-package :orchestrator.cli)

(defun %judge-decision-citations ()
  "alist: decision-id → λίστα ΜΟΝΑΔΙΚΩΝ art:* που εφάρμοσε — από τον ενιαίο γράφο
   (ακμές :applies). Χτίζει τον γράφο αν δεν υπάρχει."
  (%graph-ensure)
  (let ((acc (make-hash-table :test 'equal)))
    (dolist (nd (orchestrator.graph:query-nodes
                 (lambda (n) (%prefix-p "dec:" (orchestrator.graph:node-id n)))))
      (let* ((id (orchestrator.graph:node-id nd))
             (arts (remove-duplicates
                    (orchestrator.graph:neighbors id :applies)
                    :test #'string=)))
        (when arts (setf (gethash id acc) arts))))
    (loop for k being the hash-keys of acc using (hash-value v) collect (cons k v))))

(defun %judge-pair-counts (dec-arts)
  "Ευρετήριο συν-εφαρμογών ΑΝΑ διάταξη (Φάση 2-χρέος: το «a|b»-hash απαιτούσε
   πλήρη σάρωση όλων των ζευγών για ΚΑΘΕ γνωστή διάταξη — O(K·P) ανά δοκιμή):
   hash διάταξη → hash συν-διάταξη → πλήθος αποφάσεων που εφάρμοσαν και τις δύο."
  (let ((nbrs (make-hash-table :test 'equal)))
    (flet ((bump (a b)
             (let ((h (or (gethash a nbrs)
                          (setf (gethash a nbrs) (make-hash-table :test 'equal)))))
               (incf (gethash b h 0)))))
      (dolist (entry dec-arts nbrs)
        (let ((arts (cdr entry)))
          (loop for (a . rest) on arts do
            (dolist (b rest)
              (bump a b)
              (bump b a))))))))

(defun %judge-predict (known pairs held-dec-arts k)
  "Κατάταξε υποψήφιες διατάξεις κατά άθροισμα συν-εφαρμογών με τις ΓΝΩΣΤΕΣ του
   τεστ (μείον τη συνεισφορά της κρινόμενης απόφασης — leave-one-out). Top-K.
   Ο(Σ γειτόνων των γνωστών) ανά δοκιμή — όχι σάρωση όλων των ζευγών."
  (let ((scores (make-hash-table :test 'equal)))
    (dolist (g known)
      (let ((h (gethash g pairs)))
        (when h
          (loop for other being the hash-keys of h using (hash-value c) do
            (let* (;; αφαίρεσε τη συνεισφορά της ΙΔΙΑΣ της κρινόμενης απόφασης
                   (leak (if (and (member g held-dec-arts :test #'string=)
                                  (member other held-dec-arts :test #'string=))
                             1 0))
                   (score (- c leak)))
              (when (and (plusp score)
                         (not (member other known :test #'string=)))
                (incf (gethash other scores 0) score)))))))
    (let ((ranked (sort (loop for a being the hash-keys of scores using (hash-value s)
                              collect (cons a s))
                        (lambda (x y) (or (> (cdr x) (cdr y))
                                          (and (= (cdr x) (cdr y)) (string< (car x) (car y))))))))
      (mapcar #'car (subseq ranked 0 (min k (length ranked)))))))

(defun run-judge ()
  "--judge : το πείραμα leave-one-out σε ΟΛΗ τη νομολογία του γράφου. Τυπώνει
   hit@1/5/10, το τίμιο ταβάνι, και τις χειρότερες αστοχίες. Ντετερμινιστικό."
  (let* ((dec-arts (%judge-decision-citations))
         (pairs (%judge-pair-counts dec-arts))
         ;; πόσες φορές εμφανίζεται κάθε διάταξη συνολικά (για το τίμιο ταβάνι)
         (occurs (make-hash-table :test 'equal)))
    (dolist (e dec-arts)
      (dolist (a (cdr e)) (incf (gethash a occurs 0))))
    (let ((trials 0) (predictable 0) (hit1 0) (hit5 0) (hit10 0) (misses '()))
      (dolist (e dec-arts)
        (destructuring-bind (dec . arts) e
          (when (>= (length arts) 2)
            (dolist (held arts)
              (incf trials)
              ;; τίμιο ταβάνι: προβλέψιμη ΜΟΝΟ αν υπάρχει και σε άλλη απόφαση
              (when (> (gethash held occurs 0) 1)
                (incf predictable)
                (let* ((known (remove held arts :test #'string=))
                       (top (%judge-predict known pairs arts 10))
                       (pos (position held top :test #'string=)))
                  (cond ((and pos (= pos 0)) (incf hit1) (incf hit5) (incf hit10))
                        ((and pos (< pos 5)) (incf hit5) (incf hit10))
                        (pos (incf hit10))
                        (t (push (list dec held) misses)))))))))
      (format t "~%── ΚΡΙΤΗΣ-ΝΟΜΟΛΟΓΙΑ: πρόβλεψη συν-εφαρμογής (leave-one-out) ──~%")
      (format t "  αποφάσεις με ≥2 διατάξεις: ~D · δοκιμές: ~D~%"
              (count-if (lambda (e) (>= (length (cdr e)) 2)) dec-arts) trials)
      (format t "  τίμιο ταβάνι (κρυμμένη υπάρχει αλλού): ~D/~D (~,1F%)~%"
              predictable trials (if (plusp trials) (* 100.0 (/ predictable trials)) 0))
      (when (plusp predictable)
        (format t "  hit@1:  ~D/~D (~,1F%)~%" hit1 predictable (* 100.0 (/ hit1 predictable)))
        (format t "  hit@5:  ~D/~D (~,1F%)~%" hit5 predictable (* 100.0 (/ hit5 predictable)))
        (format t "  hit@10: ~D/~D (~,1F%)~%" hit10 predictable (* 100.0 (/ hit10 predictable))))
      (when misses
        (format t "~%  Αστοχίες εκτός top-10 (~D) — οι πρώτες 8, ορατές:~%" (length misses))
        (dolist (m (subseq misses 0 (min 8 (length misses))))
          (format t "    • ~A δεν προέβλεψε ~A~%" (first m) (second m))))
      0)))

(register-command "--judge" (lambda (a) (declare (ignore a)) (run-judge)))
