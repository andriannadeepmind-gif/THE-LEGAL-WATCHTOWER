;;;; source/graph-reasoning.lisp
;;;; ============================================================================
;;;; Ο ΣΥΛΛΟΓΙΣΤΗΣ ΠΑΝΩ ΣΤΟΝ ΕΝΙΑΙΟ ΓΡΑΦΟ — «γιατί;» και «τι επηρεάζεται;»
;;;; ============================================================================
;;;;
;;;; Τώρα που εαυτός+κόσμος ζουν σε έναν γράφο με αιτιολόγηση (JTMS) εκ κατασκευής,
;;;; ο ΙΔΙΟΣ συλλογιστής απαντά και για τον νόμο και για τον εαυτό:
;;;;
;;;;   • EXPLAIN (γιατί;) — δέντρο απόδειξης από τις αιτιολογήσεις: :asserted
;;;;     (φύλλο: πηγή) · :derived (κόμβος: κανόνας + αναδρομή στις προϋποθέσεις).
;;;;   • IMPACT (τι επηρεάζεται αν αλλάξει το X;) — αντίστροφη ΜΕΤΑΒΑΤΙΚΗ
;;;;     προσπελασιμότητα μέσω των σχέσεων εξάρτησης, με τη ΔΙΑΔΡΟΜΗ ως απόδειξη.
;;;;
;;;; Point-in-time: όλα σέβονται το holds-p (μόνο ό,τι ΙΣΧΥΕΙ τη στιγμή :at).
;;;; Καθαρά πάνω στον γράφο — καμία διπλή αναπαράσταση.

(defpackage :orchestrator.graph-reason
  (:use :cl)
  (:export #:explain #:explanation->string #:impact))

(in-package :orchestrator.graph-reason)

;;; ── EXPLAIN: δέντρο απόδειξης της αιτιολόγησης ──
(defun explain (assertion &key (max-depth 8) (graph orchestrator.graph:*graph*))
  "Δέντρο απόδειξης: (:asserted source) ή (:derived rule (children…)). Οι
   προϋποθέσεις (antecedents) αναζητούνται ως κόμβοι στον γράφο και αναλύονται."
  (labels ((walk (a depth seen)
             (let ((j (orchestrator.graph:assertion-justification a)))
               (ecase (orchestrator.graph:justification-kind j)
                 (:asserted (list :asserted (orchestrator.graph:justification-basis j)))
                 (:derived
                  (list :derived (orchestrator.graph:justification-basis j)
                        (when (< depth max-depth)
                          (loop for ant in (orchestrator.graph:justification-antecedents j)
                                for nd = (orchestrator.graph:node ant graph)
                                unless (member ant seen :test #'equal)
                                collect (if nd (walk nd (1+ depth) (cons ant seen))
                                            (list :ref ant))))))))))
    (walk assertion 0 nil)))

(defun explanation->string (tree &optional (indent 0))
  (with-output-to-string (s)
    (labels ((pad (n) (make-string (* 2 n) :initial-element #\Space))
             (emit (node depth)
               (ecase (first node)
                 (:asserted (format s "~A• δηλωμένο από: ~A~%" (pad depth) (second node)))
                 (:ref      (format s "~A• ~A~%" (pad depth) (second node)))
                 (:derived
                  (format s "~A• κανόνας «~A»~%" (pad depth) (second node))
                  (dolist (c (third node)) (emit c (1+ depth)))))))
      (emit tree indent))))

;;; ── IMPACT: τι επηρεάζεται αν αλλάξει ο κόμβος ──
(defun impact (id &key rels at (max-depth 6) (graph orchestrator.graph:*graph*))
  "Αντίστροφη μεταβατική προσπελασιμότητα: ποιοι κόμβοι ΕΞΑΡΤΩΝΤΑΙ από τον ID
   (άρα επηρεάζονται αν αυτός αλλάξει). RELS: περιορισμός σχέσεων (nil=όλες).
   Επιστρέφει (values λίστα-(affected-id . διαδρομή-ακμών) πλήθος-πέραν-ορίζοντα).
   ΑΛΗΘΙΝΟ BFS (FIFO — Φάση 2: το παλαιό pop/push κεφαλής ήταν ΣΤΟΙΒΑ/DFS που,
   με όριο βάθους, έχανε σιωπηλά κόμβους εντός του ορίου): κάθε κόμβος
   ανακαλύπτεται στην ΕΛΑΧΙΣΤΗ απόστασή του, άρα η διαδρομή-απόδειξη είναι η
   συντομότερη και το όριο κόβει μόνο ό,τι είναι ΠΡΑΓΜΑΤΙΚΑ πιο μακριά — και
   αυτό ΔΗΛΩΝΕΤΑΙ (δεύτερη τιμή: πόσοι διακριτοί γείτονες έμειναν έξω από τον
   ορίζοντα· 0 ⇒ η κάλυψη είναι πλήρης). MAX-DEPTH nil ⇒ χωρίς όριο."
  (let ((seen (make-hash-table :test 'equal))
        (beyond (make-hash-table :test 'equal))
        (result '())
        (queue (list (list id '() 0)))
        (qtail nil))
    (setf qtail (last queue)
          (gethash id seen) t)
    (flet ((enq (x)
             (let ((cell (list x)))
               (if queue
                   (setf (cdr qtail) cell qtail cell)
                   (setf queue cell qtail cell)))))
      (loop while queue do
        (destructuring-bind (cur path depth) (pop queue)
          (when (null queue) (setf qtail nil))
          (dolist (e (orchestrator.graph:in-edges cur :at at :graph graph))
            (when (or (null rels) (member (orchestrator.graph:edge-rel e) rels))
              (let ((from (orchestrator.graph:edge-from e)))
                (unless (gethash from seen)
                  (cond ((or (null max-depth) (< depth max-depth))
                         (setf (gethash from seen) t)
                         (let ((npath (cons e path)))
                           (push (cons from (reverse npath)) result)
                           (enq (list from npath (1+ depth)))))
                        (t ;; πέραν του ορίζοντα — καταμέτρησε, μην σιωπήσεις
                         (setf (gethash from beyond) t))))))))))
    (values (nreverse result) (hash-table-count beyond))))

