;;;; systems/orchestrator-cli/iq-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ IQ — αυστηρή μέτρηση του ΒΑΣΙΚΟΥ πυρήνα νόησης
;;;; ============================================================================
;;;;
;;;; Όχι «πόσα ξέρει» — ΠΟΣΟ ΣΩΣΤΑ ΣΚΕΦΤΕΤΑΙ σε προβλήματα που δεν έχει
;;;; ξαναδεί: γεννιούνται ΤΥΧΑΙΑ (ντετερμινιστικός σπόρος LCG — ίδια πύλη,
;;;; ίδια προβλήματα, πάντα) και η ορθή απάντηση υπολογίζεται από ΔΕΥΤΕΡΟ,
;;;; ΑΝΕΞΑΡΤΗΤΟ αλγόριθμο (αφελής fixpoint χωρίς ευρετήρια — άλλος κώδικας,
;;;; ίδια σημασιολογία). Διαφωνία μηχανής↔αλήθειας = αποτυχία.
;;;;
;;;;   ① ΠΑΡΑΓΩΓΗ: τυχαία στρωματοποιημένα προγράμματα (κανόνες με μεταβλητές,
;;;;      άρνηση κατά στρώμα) — το believed set της μηχανής ΤΑΥΤΙΖΕΤΑΙ με το
;;;;      αφελές κλείσιμο. ② ΑΝΑΓΩΓΗ: ο σχεδιαστής βρίσκει απόδειξη ΑΚΡΙΒΩΣ
;;;;      όταν υπάρχει. ③ ΒΑΘΟΣ: αλυσίδες 200 βημάτων, πλήρης μεταβατικότητα.
;;;;   ④ ΣΥΝΕΠΕΙΑ: τυχαίες ταξινομίες με φυτεμένες αντιφάσεις — βρίσκει ΟΛΕΣ
;;;;      και ΜΟΝΟ αυτές. Στον πυρήνα: 100% ή κόκκινο — δεν υπάρχει «σχεδόν».

(in-package :orchestrator.cli)

;;; ── Ντετερμινιστική τυχαιότητα: LCG — ο σπόρος ορίζει ΟΛΗ την πύλη ──
(defvar *iq-state* 20260705)
(defun %iq-rand (n) (setf *iq-state* (mod (+ (* *iq-state* 1103515245) 12345)
                                          2147483648))
  (mod (floor *iq-state* 65536) n))

(defun %iq-kw (prefix i) (intern (format nil "~A~D" prefix i) :keyword))

;;; ── Ο ΑΝΕΞΑΡΤΗΤΟΣ ΚΡΙΤΗΣ: αφελές στρωματοποιημένο κλείσιμο (χωρίς ευρετήρια,
;;;    χωρίς δέλτα, χωρίς JTMS — άλλος δρόμος προς την ίδια αλήθεια) ──
(defun %naive-match (pat fact b)
  (if (or (null pat) (null fact))
      (if (and (null pat) (null fact)) b :fail)
      (let ((p (car pat)) (f (car fact)))
        (cond ((and (symbolp p) (not (keywordp p))
                    (char= #\? (char (symbol-name p) 0)))
               (let ((cell (assoc p b)))
                 (cond ((null cell) (%naive-match (cdr pat) (cdr fact) (acons p f b)))
                       ((equal (cdr cell) f) (%naive-match (cdr pat) (cdr fact) b))
                       (t :fail))))
              ((equal p f) (%naive-match (cdr pat) (cdr fact) b))
              (t :fail)))))

(defun %naive-join (pats facts b)
  (if (null pats) (list b)
      (loop for f in facts
            for nb = (%naive-match (first pats) f b)
            unless (eq nb :fail)
              append (%naive-join (rest pats) facts nb))))

(defun %naive-inst (pat b)
  (mapcar (lambda (x) (let ((c (assoc x b))) (if c (cdr c) x))) pat))

(defun %naive-stratified (facts strata)
  "STRATA: λίστα στρωμάτων, καθένα λίστα (when unless then). Αφελές fixpoint
   ανά στρώμα· η άρνηση κρίνεται στο ΟΛΟΚΛΗΡΩΜΕΝΟ σύνολο του προηγούμενου."
  (let ((known (copy-list facts)))
    (dolist (stratum strata (remove-duplicates known :test #'equal))
      (let ((frozen (copy-list known)))
        (loop
          (let ((new '()))
            (dolist (r stratum)
              (destructuring-bind (whens unlesss then) r
                (dolist (b (%naive-join whens known '()))
                  (when (and (notany (lambda (u) (member (%naive-inst u b) frozen
                                                         :test #'equal))
                                     unlesss)
                             (not (member (%naive-inst then b) known :test #'equal)))
                    (push (%naive-inst then b) new)))))
            (if new (setf known (append new known)) (return))))))))

;;; ── Γεννήτρια προγραμμάτων ──
(defun %iq-program (i)
  "(values γεγονότα κανόνες-μηχανής στρώματα-κριτή): 2 στρώματα κανόνων με
   μεταβλητές, το 2ο με άρνηση πάνω στο βασικό κατηγόρημα."
  (let* ((*iq-state* (+ 777 (* 131 i)))
         (n (+ 4 (%iq-rand 4)))
         (facts (loop repeat (+ 5 (%iq-rand 6))
                      collect (list :ρ0 (%iq-kw "Κ" (%iq-rand n))
                                    (%iq-kw "Κ" (%iq-rand n)))))
         (r1 '(((:ρ0 ?x ?z) (:ρ0 ?z ?y)) () (:ρ1 ?x ?y)))
         (r2 `(((:ρ1 ?x ?y)) ((:ρ0 ?y ?x)) (:ρ2 ?x ?y))))
    (values (remove-duplicates facts :test #'equal)
            (list (make-instance 'orchestrator.inference:legal-rule
                    :name (intern (format nil "IQ-R1-~D" i) :keyword)
                    :when (first r1) :unless (second r1) :then (third r1))
                  (make-instance 'orchestrator.inference:legal-rule
                    :name (intern (format nil "IQ-R2-~D" i) :keyword)
                    :when (first r2) :unless (second r2) :then (third r2)))
            (list (list r1) (list r2)))))

(defun run-iq-gate ()
  "--iq-gate : η αυστηρή μέτρηση του βασικού IQ. Πυρήνας: 100% ή κόκκινο."
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ IQ: ο πυρήνας απέναντι σε ανεξάρτητο κριτή ──~%")
      ;; ① ΠΑΡΑΓΩΓΗ + ② ΑΝΑΓΩΓΗ σε 30 τυχαία προγράμματα
      (let ((ded-ok 0) (abd-ok 0) (abd-n 0) (atoms 0))
        (dotimes (i 30)
          (multiple-value-bind (facts rules strata) (%iq-program i)
            (let* ((truth (sort (copy-list (%naive-stratified facts strata))
                                #'string< :key (lambda (x) (format nil "~S" x))))
                   (engine (orchestrator.inference:make-inference-engine)))
              (orchestrator.inference:add-facts engine facts)
              (orchestrator.inference:run-inference engine :rules rules)
              (let ((mine (sort (copy-list
                                 (orchestrator.inference:jtms-believed-facts
                                  (orchestrator.inference:engine-jtms engine)))
                                #'string< :key (lambda (x) (format nil "~S" x)))))
                (incf atoms (length truth))
                (when (equal truth mine) (incf ded-ok))
                ;; ΑΝΑΓΩΓΗ: 2 αληθή + 2 ψευδή ερωτήματα ανά πρόγραμμα
                (let ((derived (set-difference truth facts :test #'equal))
                      (*iq-state* (+ 999 i)))
                  (dotimes (q 2)
                    (when derived
                      (incf abd-n)
                      (let ((g (nth (%iq-rand (length derived)) derived)))
                        (when (let ((orchestrator.knowledge:*extra-rules*
                                      (append rules
                                              orchestrator.knowledge:*extra-rules*)))
                                (orchestrator.knowledge:plan-satisfied-p
                                 (orchestrator.knowledge:plan-goal g facts nil)))
                          (incf abd-ok))))
                    (incf abd-n)
                    (let ((g (list :ρ2 (%iq-kw "Κ" (%iq-rand 3)) (%iq-kw "ΨΕΥΔΟΣ" q))))
                      (unless (member g truth :test #'equal)
                        (when (not (let ((orchestrator.knowledge:*extra-rules*
                                           (append rules
                                                   orchestrator.knowledge:*extra-rules*)))
                                     (orchestrator.knowledge:plan-satisfied-p
                                      (orchestrator.knowledge:plan-goal g facts nil))))
                          (incf abd-ok))))))))))
        (check (format nil "① ΠΑΡΑΓΩΓΗ: 30/30 τυχαία προγράμματα ΤΑΥΤΙΣΗ με ανεξάρτητο κριτή (~D άτομα)"
                       atoms)
               (= ded-ok 30))
        (check (format nil "② ΑΝΑΓΩΓΗ: ~D/~D ερωτήματα — απόδειξη ΑΚΡΙΒΩΣ όταν υπάρχει" abd-ok abd-n)
               (= abd-ok abd-n)))
      ;; ③ ΒΑΘΟΣ: αλυσίδα 200 βημάτων — πλήρης προσπελασιμότητα
      (let* ((edges (loop for i from 0 below 200
                          collect (list :ακμή (%iq-kw "Ν" i) (%iq-kw "Ν" (1+ i)))))
             (rule (make-instance 'orchestrator.inference:legal-rule
                     :name :iq-reach
                     :when '((:φτάνει ?x) (:ακμή ?x ?y)) :unless '()
                     :then '(:φτάνει ?y)))
             (engine (orchestrator.inference:make-inference-engine)))
        (orchestrator.inference:add-facts engine (cons '(:φτάνει :Ν0) edges))
        (orchestrator.inference:run-inference engine :rules (list rule))
        (check "③ ΒΑΘΟΣ: αλυσίδα 200 βημάτων — φτάνει στο τέρμα ΚΑΙ σε όλους τους 201 κόμβους"
               (and (orchestrator.inference:fact-status
                     (orchestrator.inference:engine-jtms engine) '(:φτάνει :Ν200))
                    (= 201 (loop for f in (orchestrator.inference:jtms-believed-facts
                                           (orchestrator.inference:engine-jtms engine))
                                 count (eq (first f) :φτάνει))))))
      ;; ④ ΣΥΝΕΠΕΙΑ: 15 τυχαίες ταξινομίες με φυτεμένες αντιφάσεις
      (let ((ok 0))
        (dotimes (i 15)
          (let* ((*iq-state* (+ 555 (* 37 i)))
                 (depth (+ 2 (%iq-rand 3)))
                 (chain-a (loop for d from 0 to depth collect (%iq-kw "Α" (+ (* i 10) d))))
                 (chain-b (loop for d from 0 to depth collect (%iq-kw "Β" (+ (* i 10) d))))
                 (genus (append (loop for (x y) on chain-a while y collect (list :γένος x y))
                                (loop for (x y) on chain-b while y collect (list :γένος x y))))
                 (division (list (list :διαίρεσις (car (last chain-a)) (car (last chain-b)))
                                 (list :διαίρεσις (car (last chain-b)) (car (last chain-a)))))
                 (planted (plusp (%iq-rand 2)))
                 (obj (%iq-kw "Ο" i))
                 (facts (append genus division
                                (list (list :γεγονός obj :είναι (first chain-a)))
                                (when planted
                                  (list (list :γεγονός obj :είναι (first chain-b))))))
                 (engine (orchestrator.inference:make-inference-engine)))
            (orchestrator.inference:add-facts engine facts)
            (orchestrator.inference:run-inference engine)
            (let ((found (plusp (length (orchestrator.inference:query
                                         engine (list :αντίφασις obj '?α '?β))))))
              (when (eq found planted) (incf ok)))))
        (check "④ ΣΥΝΕΠΕΙΑ: 15/15 ταξινομίες — βρίσκει την αντίφαση ΑΚΡΙΒΩΣ όταν φυτεύτηκε"
               (= ok 15))))
    (format t "~%── ΠΥΛΗ IQ: ~D/~D — στον πυρήνα δεν υπάρχει «σχεδόν» ──~%"
            (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--iq-gate" (lambda (a) (declare (ignore a)) (run-iq-gate)))
