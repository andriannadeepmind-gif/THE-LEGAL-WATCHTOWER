;;;; tests/bpe-persistence-test.lisp
;;;; ============================================================================
;;;; DATA-ONLY BPE PERSISTENCE — data ≠ executable Lisp ([ARCH Phase 1])
;;;; ============================================================================
;;;; Κλειδώνει την αναβάθμιση του BPE persistence seat: το παλιό ζεύγος έγραφε
;;;; (setf *bpe-model* (make-bpe-model …)) και το φόρτωνε με cl:LOAD (ΕΚΤΕΛΕΣΗ αρχείου).
;;;; Τώρα: DATA-ONLY versioned schema, φόρτωση μέσω safe-read, typed decoder ΧΩΡΙΣ eval/load.
;;;; Αποδεικνύει:
;;;;   (α) save→load round-trip διατηρεί merges + trained-on (καμία εκτέλεση)·
;;;;   (β) #. reader-eval στο αρχείο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (safe-read denies #)·
;;;;   (γ) εκτελέσιμο (setf *bpe-model* …)/(make-bpe-model …) ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (schema/decoder)·
;;;;   (δ) λάθος version / άγνωστο πεδίο / λάθος τύπος merge ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (typed decoder).
;;;; Gated: τρέχει στο full build (in-package orchestrator.greek-tokenizer).

(in-package :orchestrator.greek-tokenizer)

(defvar *pt* 0) (defvar *ft* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *pt*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *ft*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *ft*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))
(defmacro ck-rejected (name form)
  `(ck ,name (handler-case (progn ,form nil)
               (bpe-decode-error () t) (orchestrator.safe-read:safe-read-error () t))))

(let ((tmp (format nil "/tmp/bpe-persist-~D.sexp" (get-internal-real-time))))
  (unwind-protect
       (progn
         ;; (α) round-trip: merges με strings που περιέχουν </w> και escapes
         (let ((m (make-bpe-model
                   :merges (list (cons (cons "α" "β") "αβ")
                                 (cons (cons "x\"q" "y</w>") "x\"qy</w>"))
                   :vocab (make-hash-table :test 'equal)
                   :trained-on 7)))
           (save-bpe-model m tmp)
           (let ((r (load-bpe-model tmp)))
             (ck "round-trip: bpe-model-p" (bpe-model-p r))
             (ck "round-trip: trained-on" (eql 7 (bpe-model-trained-on r)))
             (ck "round-trip: 2 merges" (= 2 (length (bpe-model-merges r))))
             (ck "round-trip: merge#1 pair+merged ακέραιο"
                 (let ((e (first (bpe-model-merges r))))
                   (and (equal (car e) (cons "α" "β")) (string= (cdr e) "αβ"))))
             (ck "round-trip: merge#2 με \" και </w> ακέραιο"
                 (let ((e (second (bpe-model-merges r))))
                   (and (equal (car e) (cons "x\"q" "y</w>")) (string= (cdr e) "x\"qy</w>"))))
             (ck "round-trip: vocab κενό (inference-only, όπως το παλιό save)"
                 (zerop (hash-table-count (bpe-model-vocab r))))
             ;; bpe-tokenize δουλεύει στο ανακτημένο μοντέλο (η ικανότητα διατηρείται)
             (ck "ανακτημένο μοντέλο tokenize-able (καμία εξάρτηση από vocab)"
                 (listp (bpe-tokenize "αβγ" r)))))
         ;; (β) #. reader-eval ⇒ rejected
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "#.(error \"PWNED\")~%"))
         (ck-rejected "ATTACK #. reader-eval ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (καμία εκτέλεση)" (load-bpe-model tmp))
         ;; (γ) εκτελέσιμο πρόγραμμα (το ΠΑΛΙΟ format) ⇒ rejected (schema/decoder)
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(setf *bpe-model* (make-bpe-model :merges 'nil :trained-on 0))~%"))
         (ck-rejected "ATTACK (setf *bpe-model* (make-bpe-model …)) ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-bpe-model tmp))
         ;; (δ) λάθος version / άγνωστο πεδίο / λάθος τύπος
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-bpe-model/999 :merges () :trained-on 0)~%"))
         (ck-rejected "ATTACK λάθος version ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-bpe-model tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-bpe-model/1 :merges () :trained-on 0 :evil 1)~%"))
         (ck-rejected "ATTACK άγνωστο πεδίο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-bpe-model tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-bpe-model/1 :merges ((\"a\" \"b\")) :trained-on 0)~%")) ; merge όχι ((a b) merged)
         (ck-rejected "ATTACK κακοσχηματισμένος merge ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-bpe-model tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-bpe-model/1 :merges () :trained-on -5)~%"))
         (ck-rejected "ATTACK trained-on αρνητικό ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-bpe-model tmp))
         ;; [κύκλος-2 STRICT] λείπον υποχρεωτικό πεδίο / μη-άρτιο plist ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-bpe-model/1 :trained-on 0)~%"))  ; ΛΕΙΠΕΙ :merges
         (ck-rejected "ATTACK λείπει :merges ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (όχι σιωπηλά κενό μοντέλο)"
                      (load-bpe-model tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-bpe-model/1 :merges ())~%"))  ; ΛΕΙΠΕΙ :trained-on
         (ck-rejected "ATTACK λείπει :trained-on ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-bpe-model tmp))
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "(:lawmax-bpe-model/1 :merges)~%"))  ; μη-άρτιο plist
         (ck-rejected "ATTACK μη-άρτιο plist ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (load-bpe-model tmp)))
    (ignore-errors (delete-file tmp))))

(format t "~%bpe-persistence: ~D passed, ~D failed~%" *pt* *ft*)
(sb-ext:exit :code (if (zerop *ft*) 0 1))
