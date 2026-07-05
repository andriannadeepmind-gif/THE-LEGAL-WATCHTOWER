;;;; source/legal-strategy.lisp
;;;; ============================================================================
;;;; Σ9 — ΣΤΡΑΤΗΓΙΚΗ: σχεδιασμός δικονομικής πορείας με αποδείξεις παραδεκτού
;;;; ============================================================================
;;;;
;;;; Κλασικός σχεδιασμός STRIPS-μορφής: οι ΤΕΛΕΣΤΕΣ είναι το δικονομικό δίκαιο
;;;; (πράξη: προϋποθέσεις → αποτελέσματα, με ΠΗΓΗ «corpus:article» και
;;;; προαιρετική ΠΡΟΘΕΣΜΙΑ από γεγονός-αφετηρία). Αναζήτηση: BFS στο πεπερασμένο
;;;; γράφημα καταστάσεων (κατάσταση = σύνολο γεγονότων) — ντετερμινιστική,
;;;; πλήρης εντός του δηλωμένου βάθους. Κάθε βήμα του πλάνου φέρει ΤΕΚΜΗΡΙΩΣΗ:
;;;; ποιες προϋποθέσεις το στήριξαν και, αν έχει προθεσμία, την απόδειξη
;;;; εμπροθέσμου (αφετηρία + όριο + σήμερα) μέσω της ΜΙΑΣ χρονικής έδρας
;;;; (orchestrator.temporal). Το ΕΚΠΡΟΘΕΣΜΟ δηλώνεται ρητά — ποτέ σιωπηλά.
;;;;
;;;; Οι τελεστές = ΓΝΩΣΗ (πακέτο :procedure) — το δικονομικό δίκαιο ως δηλώσεις.

(defpackage :orchestrator.strategy
  (:use :cl)
  (:export #:*operators* #:plan-course #:strategy-report #:operator-blocked-reason))

(in-package :orchestrator.strategy)

(defvar *operators* '()
  "Οι δικονομικοί τελεστές: plists
   (:id Κ :source «corpus:άρθρο» :pre (γεγονότα…) :add (γεγονότα…)
    [:deadline-days Ν :deadline-from ΚΑΤΗΓΟΡΗΜΑ]) — δηλωμένοι από πακέτο.")

(orchestrator.knowledge-packs:define-knowledge-kind :procedure
 :doc "Δικονομικοί τελεστές: (:operator ID ΠΗΓΗ ΠΡΟΫΠΟΘΕΣΕΙΣ ΑΠΟΤΕΛΕΣΜΑΤΑ
 [ΗΜΕΡΕΣ ΚΑΤΗΓΟΡΗΜΑ-ΑΦΕΤΗΡΙΑΣ]) — «η πράξη Χ χωρεί όταν … και παράγει …,
 εντός Ν ημερών από το γεγονός Ψ»."
 :install
 (lambda (entries)
   (dolist (e entries)
     (destructuring-bind (k id source pre add &optional days from) e
       (assert (eq k :operator) () "άγνωστο entry ~S στο :procedure" k)
       (assert (and source (find #\: source)) () "τελεστής ~S χωρίς πηγή" id)
       (setf *operators*
             (cons (list :id id :source source :pre pre :add add
                         :deadline-days days :deadline-from from)
                   (remove id *operators* :key (lambda (o) (getf o :id))))))))
 :snapshot (lambda () (copy-tree *operators*))
 :restore  (lambda (st) (setf *operators* st)))

(defun %deadline-check (op state today)
  "(values εντάξει-p αιτιολογία): αν ο τελεστής έχει προθεσμία, βρες το
   γεγονός-αφετηρία στην ΚΑΤΑΣΤΑΣΗ και έλεγξε today ≤ αφετηρία+Ν — μέσω της
   χρονικής έδρας. Χωρίς αφετηρία στην κατάσταση ⇒ ΑΓΝΟΙΑ, δηλωμένη."
  (let ((days (getf op :deadline-days))
        (from (getf op :deadline-from)))
    (if (null days)
        (values t "χωρίς προθεσμία")
        (let ((start (loop for f in state
                           when (and (consp f) (eq (second f) from)
                                     (stringp (third f)))
                             return (third f))))
          (cond
            ((null start)
             (values nil (format nil "ΑΓΝΩΣΤΗ αφετηρία προθεσμίας (~(~A~)) — δεν κρίνω εμπρόθεσμο χωρίς γεγονός" from)))
            ((null today)
             (values nil "χωρίς σημερινή ημερομηνία δεν κρίνεται προθεσμία — δώσε :today"))
            (t (let ((limit (orchestrator.temporal:date-plus-days start days)))
                 (if (orchestrator.temporal:date<= today limit)
                     (values t (format nil "ΕΜΠΡΟΘΕΣΜΟ: ~A ≤ ~A (~A + ~D ημέρες)"
                                       today limit start days))
                     (values nil (format nil "ΕΚΠΡΟΘΕΣΜΟ: ~A > ~A (~A + ~D ημέρες)"
                                         today limit start days))))))))))

(defun operator-blocked-reason (op state today)
  "Γιατί ΔΕΝ χωρεί ο τελεστής στην κατάσταση: (values λόγος|nil). nil = χωρεί."
  (let ((missing (remove-if (lambda (p) (member p state :test #'equal))
                            (getf op :pre))))
    (if missing
        (format nil "λείπουν προϋποθέσεις:~{ ~S~}" missing)
        (multiple-value-bind (ok why) (%deadline-check op state today)
          (if ok nil why)))))

(defun %apply-op (op state)
  (remove-duplicates (append state (getf op :add)) :test #'equal))

(defun plan-course (state goal &key today (max-depth 6)
                                    (operators *operators*))
  "BFS: από την ΚΑΤΑΣΤΑΣΗ στο ΓΕΓΟΝΟΣ-στόχο. Επιστρέφει (values πλάνο|nil
   εξηγήσεις-αποκλεισμών): πλάνο = λίστα βημάτων (:op id :source :why), όπου
   :why η τεκμηρίωση (προϋποθέσεις + απόδειξη εμπροθέσμου). Πλήρης εντός του
   ΔΗΛΩΜΕΝΟΥ βάθους — κάθε αποκλεισμένος τελεστής με τον λόγο του."
  (let ((seen (make-hash-table :test 'equal))
        (queue (list (list state '())))
        (blocked '()))
    (flet ((key (st) (sort (mapcar (lambda (f) (format nil "~S" f)) st) #'string<)))
      (setf (gethash (key state) seen) t)
      (loop while queue do
        (destructuring-bind (st path) (pop queue)
          (cond
            ((member goal st :test #'equal)
             (return-from plan-course (values (reverse path) (nreverse blocked))))
            ((>= (length path) max-depth))   ; δηλωμένο όριο βάθους
            (t
             (dolist (op operators)
               (let ((reason (operator-blocked-reason op st today)))
                 (if reason
                     (when (and (member goal (getf op :add) :test #'equal)
                                (not (assoc (getf op :id) blocked)))
                       ;; τελεστής που ΘΑ έδινε τον στόχο αλλά αποκλείεται —
                       ;; ο λόγος του ανήκει στην απάντηση
                       (push (cons (getf op :id) reason) blocked))
                     (let* ((nst (%apply-op op st)) (k (key nst)))
                       (unless (gethash k seen)
                         (setf (gethash k seen) t)
                         (multiple-value-bind (ok why) (%deadline-check op st today)
                           (declare (ignore ok))
                           (setf queue
                                 (nconc queue
                                        (list (list nst
                                                    (cons (list :op (getf op :id)
                                                                :source (getf op :source)
                                                                :why why)
                                                          path)))))))))))))))
      (values nil (nreverse blocked)))))

(defun strategy-report (state goal &key today (stream *standard-output*))
  "Η πορεία προς τον στόχο, βήμα-βήμα με τεκμηρίωση — ή ο ΛΟΓΟΣ που δεν υπάρχει."
  (multiple-value-bind (plan blocked) (plan-course state goal :today today)
    (cond
      (plan
       (format stream "~%── ΣΤΡΑΤΗΓΙΚΗ: ~D βήμα~:*~[τα~;~:;τα~] προς ~S ──~%" (length plan) goal)
       (loop for step in plan for i from 1 do
         (format stream "  ~D. ~A (πηγή: ~A) — ~A~%"
                 i (getf step :op) (getf step :source) (getf step :why)))
       0)
      (t
       (format stream "~%── ΣΤΡΑΤΗΓΙΚΗ: ΔΕΝ υπάρχει παραδεκτή πορεία προς ~S ──~%" goal)
       (if blocked
           (dolist (b blocked)
             (format stream "  ⊘ ~A: ~A~%" (car b) (cdr b)))
           (format stream "  Κανένας εγγεγραμμένος τελεστής δεν παράγει τον στόχο — τίμια.~%"))
       1))))
