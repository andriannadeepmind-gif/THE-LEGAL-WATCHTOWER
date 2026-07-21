;;;; tests/trace-persistence-test.lisp
;;;; ============================================================================
;;;; DATA-ONLY TRACE PERSISTENCE — data ≠ executable Lisp ([re-review adv2-F3])
;;;; ============================================================================
;;;; Κλειδώνει την ανώτατη closure του F3 (εντολή δημιουργού): trace serialization είναι
;;;; DATA-ONLY versioned schema, φορτώνεται μέσω της safe-read έδρας, ανασυγκροτείται από
;;;; typed decoder ΧΩΡΙΣ eval/load. Αποδεικνύει:
;;;;   (α) save→load round-trip διατηρεί τα πεδία (καμία εκτέλεση)·
;;;;   (β) trace αρχείο με #. reader-eval ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (safe-read denies #)·
;;;;   (γ) εκτελέσιμο (make-trace-info …)/(load …) στο αρχείο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (schema, όχι eval)·
;;;;   (δ) άγνωστο πεδίο / λάθος version / λάθος τύπος ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (typed decoder).
;;;; Gated: τρέχει στο full build (in-package orchestrator.trace-core, πραγματικές συναρτήσεις).

(in-package :orchestrator.trace-core)

(defvar *pt* 0) (defvar *ft* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *pt*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *ft*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *ft*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))
(defmacro ck-rejected (name form)
  `(ck ,name (handler-case (progn ,form nil)
               (trace-decode-error () t) (orchestrator.safe-read:safe-read-error () t))))

(let ((tmp (format nil "/tmp/trace-persist-~D.sexp" (get-internal-real-time))))
  (unwind-protect
       (progn
         ;; (α) round-trip
         (clear-trace-registry)
         (register-trace (make-trace-info :trace-id "T1" :raw-text "hello|world\"x"
                                          :layer :layout :timestamp 42 :source-pages '(1 2 3)))
         (save-traces-to-file tmp)
         (clear-trace-registry)
         (ck "load επιστρέφει count 1" (= 1 (load-traces-from-file tmp)))
         (let ((tr (lookup-trace "T1")))
           (ck "round-trip trace-id" (and tr (string= "T1" (trace-id tr))))
           (ck "round-trip raw-text (με | και \") ακέραιο" (string= "hello|world\"x" (trace-raw-text tr)))
           (ck "round-trip layer keyword" (eq :layout (trace-layer tr)))
           (ck "round-trip timestamp" (eql 42 (trace-timestamp tr)))
           (ck "round-trip pages list" (equal '(1 2 3) (trace-pages tr))))
         ;; (β) #. reader-eval ⇒ rejected
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "#.(error \"PWNED\")~%"))
         (ck-rejected "ATTACK #. reader-eval ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (καμία εκτέλεση)" (load-traces-from-file tmp))
         ;; (γ) εκτελέσιμο constructor call ⇒ rejected (schema, όχι eval)
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(make-trace-info :trace-id \"x\")~%"))
         (ck-rejected "ATTACK (make-trace-info …) ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (schema mismatch)" (load-traces-from-file tmp))
         ;; (δ) unknown field / wrong version / wrong type
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id \"x\" :evil 1)~%"))
         (ck-rejected "ATTACK άγνωστο πεδίο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-traces-from-file tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/999 :trace-id \"x\")~%"))
         (ck-rejected "ATTACK λάθος version ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-traces-from-file tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id 12345)~%"))  ; trace-id όχι string
         (ck-rejected "ATTACK λάθος τύπος (trace-id int) ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-traces-from-file tmp))
         ;; [κύκλος-2 SECURITY] λείπον ΥΠΟΧΡΕΩΤΙΚΟ πεδίο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (καμία fabrication
         ;; ταυτότητας/χρόνου/επιπέδου — το παλιό make-trace-info θα κατασκεύαζε νέα τιμή).
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :timestamp 42 :layer :layout)~%"))  ; ΛΕΙΠΕΙ trace-id
         (ck-rejected "ATTACK λείπει :trace-id ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (καμία fabricated ταυτότητα)"
                      (load-traces-from-file tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id \"x\" :layer :layout)~%"))  ; ΛΕΙΠΕΙ timestamp
         (ck-rejected "ATTACK λείπει :timestamp ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (κανένας fabricated χρόνος)"
                      (load-traces-from-file tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id \"x\" :timestamp 42)~%"))  ; ΛΕΙΠΕΙ layer
         (ck-rejected "ATTACK λείπει :layer ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-traces-from-file tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id)~%"))  ; μη-άρτιο plist
         (ck-rejected "ATTACK μη-άρτιο plist ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-traces-from-file tmp))
         ;; [κύκλος-2] deep element validation: block-ids ΠΡΕΠΕΙ να είναι strings
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id \"x\" :timestamp 42 :layer :l :layout-block-ids (1 2))~%"))
         (ck-rejected "ATTACK block-ids όχι strings (deep) ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-traces-from-file tmp))
         ;; [κύκλος-2] VALIDATE-ALL-FIRST / ATOMIC COMMIT: 2ο record άκυρο ⇒ ΚΑΝΕΝΑ εγγράφεται
         (clear-trace-registry)
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id \"GOOD\" :timestamp 1 :layer :l)~%")
           (format s "(:lawmax-trace/1 :trace-id \"BAD\" :timestamp 2)~%"))  ; 2ο: λείπει layer
         (ck-rejected "ATTACK partial-load (2ο record άκυρο) ⇒ σφάλμα" (load-traces-from-file tmp))
         (ck "ATOMIC: μετά την αποτυχία, ΚΑΝΕΝΑ record δεν μπήκε στο registry (transaction)"
             (null (lookup-trace "GOOD")))
         ;; [κύκλος-2] duplicate trace-id ΜΕΣΑ στο αρχείο ⇒ ΑΠΟΡΡΙΨΗ (κανένα σιωπηλό overwrite)
         (clear-trace-registry)
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id \"DUP\" :timestamp 1 :layer :l)~%")
           (format s "(:lawmax-trace/1 :trace-id \"DUP\" :timestamp 2 :layer :l)~%"))
         (ck-rejected "ATTACK duplicate trace-id στο αρχείο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-traces-from-file tmp))
         (ck "ATOMIC: duplicate-in-file ⇒ ΚΑΝΕΝΑ record στο registry" (null (lookup-trace "DUP")))
         ;; [κύκλος-2] collision policy vs υπάρχον registry
         (clear-trace-registry)
         (register-trace (make-trace-info :trace-id "X" :timestamp 100 :layer :orig))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-trace/1 :trace-id \"X\" :timestamp 200 :layer :new)~%"))
         (ck-rejected ":on-existing :error (default) ⇒ collision ΑΠΟΡΡΙΠΤΕΤΑΙ"
                      (load-traces-from-file tmp))
         (ck "collision :error: το υπάρχον ΔΕΝ αλλοιώθηκε (timestamp 100)"
             (eql 100 (trace-timestamp (lookup-trace "X"))))
         (ck ":on-existing :skip ⇒ κρατά το υπάρχον (0 committed)"
             (and (= 0 (load-traces-from-file tmp :on-existing :skip))
                  (eql 100 (trace-timestamp (lookup-trace "X")))))
         (ck ":on-existing :replace ⇒ αντικαθιστά (1 committed, timestamp 200)"
             (and (= 1 (load-traces-from-file tmp :on-existing :replace))
                  (eql 200 (trace-timestamp (lookup-trace "X")))))
         ;; [κύκλος-2] DETERMINISTIC save: ίδιο registry ⇒ byte-identical αρχείο
         (clear-trace-registry)
         (register-trace (make-trace-info :trace-id "B" :layer :l :timestamp 2))
         (register-trace (make-trace-info :trace-id "A" :layer :l :timestamp 1))
         (let ((f1 (format nil "~A.d1" tmp)) (f2 (format nil "~A.d2" tmp)))
           (unwind-protect
                (progn (save-traces-to-file f1) (save-traces-to-file f2)
                       (ck "DETERMINISTIC: δύο saves ⇒ byte-identical (ταξινομημένο κατά trace-id)"
                           (string= (with-open-file (s f1) (let ((x (make-string (file-length s)))) (read-sequence x s) x))
                                    (with-open-file (s f2) (let ((x (make-string (file-length s)))) (read-sequence x s) x)))))
             (ignore-errors (delete-file f1)) (ignore-errors (delete-file f2))))
         (clear-trace-registry)
         ;; θετικό: trace-to-data είναι data-only (κανένα non-keyword symbol στα κλειδιά)
         (let* ((tr (make-trace-info :trace-id "D" :layer :x))
                (d (trace-to-data tr)))
           (ck "trace-to-data: πρώτο στοιχείο = schema version" (eq +trace-schema+ (first d)))
           (ck "trace-to-data: κανένα constructor symbol (μόνο keywords στα odd θέσεις)"
               (loop for (k v) on (rest d) by #'cddr always (keywordp k)))))
    (ignore-errors (delete-file tmp))))

(format t "~%trace-persistence: ~D passed, ~D failed~%" *pt* *ft*)
(sb-ext:exit :code (if (zerop *ft*) 0 1))
