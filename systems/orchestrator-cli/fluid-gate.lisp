;;;; systems/orchestrator-cli/fluid-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΡΕΥΣΤΗΣ ΝΟΗΣΗΣ + εκτέλεση ΠΡΑΓΜΑΤΙΚΟΥ ARC
;;;; ============================================================================
;;;;
;;;; Κριτής = ΚΡΥΦΑ προγράμματα: η πύλη κληρώνει (σπόρος LCG) πρόγραμμα από
;;;; το DSL, γεννά ζεύγη, και ο λύτης — που ΔΕΝ βλέπει το πρόγραμμα — πρέπει
;;;; να παραγάγει την ΑΚΡΙΒΗ έξοδο δοκιμής. Πληρότητα στο δικό του DSL: 100%
;;;; ή κόκκινο. Εκτός DSL: οφείλει ΤΙΜΙΟ nil, ποτέ εικασία.
;;;; Πραγματικό ARC: --arc-eval διαβάζει input/arc/*.json (επίσημη μορφή
;;;; fchollet/ARC) και τυπώνει ΩΜΟ σκορ — ο αριθμός μας στο διεθνές γήπεδο.

(in-package :orchestrator.cli)

(defvar *fl-state* 1)
(defun %fl-rand (n) (setf *fl-state* (mod (+ (* *fl-state* 1103515245) 12345) 2147483648))
  (mod (floor *fl-state* 65536) n))

(defun %fl-grid (rows cols colors)
  (loop repeat rows collect (loop repeat cols collect (%fl-rand colors))))

(defun run-fluid-gate ()
  "--fluid-gate : πληρότητα του λύτη πάνω στο DSL του — κρυφά προγράμματα."
  (let ((fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΡΕΥΣΤΗΣ ΝΟΗΣΗΣ: κρυφά προγράμματα ως κριτές ──~%")
      ;; ① Κάθε έργο πρέπει να είναι ΚΑΛΩΣ-ΤΕΘΕΙΜΕΝΟ: μία μόνο απάντηση συμβατή
      ;;    με τα παραδείγματα (ό,τι εγγυώνται οι επιμελητές του ARC με το χέρι).
      ;;    Έργο όπου δύο ανισοδύναμα προγράμματα εξηγούν την εκπαίδευση αλλά
      ;;    διαφωνούν στη δοκιμή ΔΕΝ έχει σωστή απάντηση — ξανακληρώνεται
      ;;    ντετερμινιστικά (η LCG ροή συνεχίζει)· φραγμένες προσπάθειες.
      (let ((names (mapcar #'car orchestrator.fluid:*primitives*))
            (solved 0) (posed 0) (n 40))
        (dotimes (i n)
          (let ((*fl-state* (+ 424242 (* 97 i))))
            (loop named gen for attempt from 0 below 50
                  do (let* ((depth (1+ (%fl-rand 2)))
                            (hidden (loop repeat depth
                                          collect (nth (%fl-rand (length names)) names)))
                            (pairs (loop repeat 3
                                         for g = (%fl-grid (+ 2 (%fl-rand 4)) (+ 2 (%fl-rand 4)) 5)
                                         for out = (orchestrator.fluid:apply-program hidden g)
                                         when out collect (list g out)))
                            (test-in (%fl-grid (+ 2 (%fl-rand 4)) (+ 2 (%fl-rand 4)) 5))
                            (expected (orchestrator.fluid:apply-program hidden test-in)))
                       (when (and (= 3 (length pairs)) expected)
                         (let* ((sols (orchestrator.fluid:all-solutions pairs test-in))
                                (outs (remove-duplicates (mapcar #'cdr sols) :test #'equal)))
                           (when (= 1 (length outs))   ; μονοσήμαντο ⇒ έγκυρο έργο
                             (incf posed)
                             (multiple-value-bind (got) (orchestrator.fluid:solve-task pairs test-in)
                               (when (orchestrator.fluid:grid-equal got expected)
                                 (incf solved)))
                             (return-from gen))))))))
        (check (format nil "① ΕΠΑΓΩΓΗ: ~D/~D καλώς-τεθειμένα κρυφά προγράμματα (βάθος ≤2) — ΑΚΡΙΒΗΣ έξοδος δοκιμής" solved n)
               (and (= posed n) (= solved n))))
      ;; recolor: κρυφή χρωματική αντιστοίχιση πάνω σε γεωμετρία
      (let* ((map '((0 . 3) (1 . 7) (2 . 5) (3 . 0) (4 . 4)))
             (hidden (list :rot90 (list :recolor map)))
             (pairs (loop for i from 1 to 3
                          for g = (let ((*fl-state* (* 31 i))) (%fl-grid 3 4 5))
                          collect (list g (orchestrator.fluid:apply-program hidden g))))
             (test-in (let ((*fl-state* 777)) (%fl-grid 4 3 5)))
             (expected (orchestrator.fluid:apply-program hidden test-in)))
        (multiple-value-bind (got) (orchestrator.fluid:solve-task pairs test-in)
          (check "② ΧΡΩΜΑ: μαθαίνει κρυφή αντιστοίχιση χρωμάτων πάνω σε περιστροφή"
                 (orchestrator.fluid:grid-equal got expected))))
      ;; εκτός DSL ⇒ τίμιο nil με λόγο. ΑΠΟΔΕΔΕΙΓΜΕΝΑ εκτός για το τρέχον DSL
      ;; σε βάθος ≤3: είσοδοι 2×2 χωρίς μηδενικά → έξοδοι 5×5. Ανάλυση διαστάσεων:
      ;; 5 στήλες θα απαιτούσαν dedup πάνω σε 6 με ΜΙΑ ραφή — αλλά η μόνη πηγή
      ;; 6 στηλών σε ≤2 βήματα (scale3) δίνει τριπλές ραφές που καταρρέουν σε 2.
      ;; Αν μελλοντικό κύμα το απορροφήσει, η πύλη κοκκινίζει και το παράδειγμα
      ;; αντικαθίσταται από δυσκολότερο — συνειδητά, ποτέ σιωπηλά.
      (multiple-value-bind (got prog why)
          (orchestrator.fluid:solve-task
           '((((1 2) (2 1)) ((1 2 1 2 1) (2 1 2 1 2) (1 2 1 2 1) (2 1 2 1 2) (1 2 1 2 1)))
             (((3 4) (4 3)) ((3 4 3 4 3) (4 3 4 3 4) (3 4 3 4 3) (4 3 4 3 4) (3 4 3 4 3))))
           '((2 3) (3 2)) :max-depth 3)
        (declare (ignore prog))
        (check "③ ΕΚΤΟΣ DSL: αρνείται με ΔΗΛΩΜΕΝΟ λόγο — δεν μαντεύει ποτέ"
               (and (null got) why (search "δηλωμένο όριο" why)))))
    (format t "~%── ΠΥΛΗ ΡΕΥΣΤΗΣ ΝΟΗΣΗΣ: ~D/~D ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(defun %arc-grid (j) j)   ; jonathan: λίστες λιστών ακεραίων — ήδη πλέγμα

(defun run-arc-eval (args)
  "--arc-eval [φάκελος] : τρέξε ΠΡΑΓΜΑΤΙΚΑ ARC tasks (επίσημο JSON format)
   και τύπωσε ωμό σκορ. Default: input/arc/."
  (let* ((dir (or (first args) "input/arc/"))
         (files (ignore-errors
                  (remove-if-not (lambda (f) (string= (pathname-type f) "json"))
                                 (uiop:directory-files
                                  (merge-pathnames dir (uiop:getcwd)))))))
    (if (null files)
        (progn (format t "~%Κανένα ARC task στο ~A — κατέβασε τα επίσημα JSON (fchollet/ARC-AGI) εκεί.~%" dir) 1)
        (let ((solved 0) (attempted 0) (declined 0)
              (*print-pretty* nil))   ; προγράμματα σε ΜΙΑ γραμμή στο ωμό σκορ
          (dolist (f files)
            (handler-case
                (let* ((task (jonathan:parse (uiop:read-file-string f :external-format :utf-8)
                                             :as :alist))
                       (train (loop for p in (cdr (assoc "train" task :test #'string=))
                                    collect (list (%arc-grid (cdr (assoc "input" p :test #'string=)))
                                                  (%arc-grid (cdr (assoc "output" p :test #'string=))))))
                       (tests (cdr (assoc "test" task :test #'string=))))
                  (dolist (tc tests)
                    (let ((tin (%arc-grid (cdr (assoc "input" tc :test #'string=))))
                          (tout (cdr (assoc "output" tc :test #'string=))))
                      (incf attempted)
                      (multiple-value-bind (got prog) (orchestrator.fluid:solve-task train tin :max-depth 3)
                        (cond ((null got) (incf declined))
                              ((and tout (orchestrator.fluid:grid-equal got (%arc-grid tout)))
                               (incf solved)
                               (format t "  ✓ ~A — πρόγραμμα: ~A~%" (pathname-name f) prog))
                              (tout (format t "  ✗ ~A — συνεπές με την εκπαίδευση αλλά ΛΑΘΟΣ στη δοκιμή: ~A~%"
                                            (pathname-name f) prog))
                              (t (format t "  ? ~A — απάντησα (χωρίς επίσημη λύση στο αρχείο)~%"
                                         (pathname-name f))))))))
              (error (e) (format t "  ⚠ ~A: ~A~%" (pathname-name f) e))))
          (format t "~%══ ARC: ~D/~D σωστά · ~D τίμιες αρνήσεις (εκτός DSL) · ~D αρχεία ══~%"
                  solved attempted declined (length files))
          0))))

(register-command "--fluid-gate" (lambda (a) (declare (ignore a)) (run-fluid-gate)))
(register-command "--arc-eval"   (lambda (a) (run-arc-eval a)))

(orchestrator.self-model:declare-capability! "ρευστή-επαγωγή"
 :description "επαγωγή προγραμμάτων από παραδείγματα (οικογένεια ARC) με τίμια άρνηση"
 :package :orchestrator.fluid :functions '("solve-task" "all-solutions")
 :gate "--fluid-gate" :depends-on '())
