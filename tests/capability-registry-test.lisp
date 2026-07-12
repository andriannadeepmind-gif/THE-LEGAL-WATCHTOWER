;;;; tests/capability-registry-test.lisp
;;;; Η ΜΙΑ έδρα δυνατοτήτων: συμβόλαιο (params+τύποι), trust-επιβολή (δομική),
;;;; ντετερμινιστική προβολή, fail-closed σε άγνωστη/άκυρη. Καθαρή CL, gated.

(in-package :orchestrator.capability)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))
(defmacro ck-signals (name form)
  `(ck ,name (handler-case (progn ,form nil) (capability-error () t))))

(format t "~%== [1] δηλωτικός ορισμός + εγγραφή ==~%")
(clrhash *capabilities*)
(define-capability :echo
  :summary "επιστρέφει το κείμενο (trusted δοκιμαστική)"
  :params ((:q :string t) (:times :integer nil))
  :result :string :trust :trusted :proof t
  :fn (lambda (&key q times)
        (with-output-to-string (o)
          (dotimes (_ (or times 1)) (write-string q o)))))
(define-capability :suggest
  :summary "πρόταση συμβούλου (advisor — ΠΟΤΕ trusted)"
  :params ((:hint :string t))
  :result :string :trust :advisor
  :fn (lambda (&key hint) (format nil "πρόταση: ~A" hint)))

(ck "εγγράφηκαν 2" (= 2 (length (all-capabilities))))
(ck "find-capability :echo" (typep (find-capability :echo) 'capability))
(ck "άγνωστη → nil" (null (find-capability :nope)))
(ck ":echo είναι trusted" (trusted-capability-p (find-capability :echo)))
(ck ":suggest είναι advisor" (advisor-capability-p (find-capability :suggest)))
(ck "summary διατηρείται" (search "trusted" (capability-summary (find-capability :echo))))

(format t "~%== [2] κλήση + έλεγχος συμβολαίου (params + τύποι) ==~%")
(ck "invoke :echo βασικό" (string= "γεια" (invoke-capability :echo '(:q "γεια"))))
(ck "invoke :echo με times" (string= "αβαβαβ" (invoke-capability :echo '(:q "αβ" :times 3))))
(ck-signals "λείπει υποχρεωτικό :q" (invoke-capability :echo '(:times 2)))
(ck-signals "λάθος τύπος :times (string)" (invoke-capability :echo '(:q "x" :times "3")))
(ck-signals "άγνωστη δυνατότητα" (invoke-capability :nope '(:q "x")))

(format t "~%== [3] ΔΟΜΙΚΗ επιβολή trust (κανένα advisor σε trusted μονοπάτι) ==~%")
(ck "advisor invoke χωρίς require-trust ΟΚ"
    (string= "πρόταση: α" (invoke-capability :suggest '(:hint "α"))))
(ck-signals "advisor σε trusted μονοπάτι ΑΠΟΡΡΙΠΤΕΤΑΙ"
            (invoke-capability :suggest '(:hint "α") :require-trust t))
(ck "trusted σε trusted μονοπάτι περνά"
    (string= "ok" (invoke-capability :echo '(:q "ok") :require-trust t)))

(format t "~%== [4] fail-closed εγγραφή (άκυρα ορίσματα) ==~%")
(ck-signals "άκυρο trust απορρίπτεται στην εγγραφή"
            (register-capability (%make-capability :name :bad :trust :maybe
                                                   :fn (lambda (&rest _) (declare (ignore _)) nil))))
(ck-signals "άκυρο param spec απορρίπτεται"
            (register-capability (%make-capability :name :bad2 :trust :trusted
                                                   :params '((:q :string))
                                                   :fn (lambda (&rest _) (declare (ignore _)) nil))))
(ck "μη-function :fn απορρίπτεται"
    (handler-case (progn (register-capability
                          (%make-capability :name :bad3 :trust :trusted :fn 42)) nil)
      (capability-error () t) (error () t)))

(format t "~%== [5] ντετερμινιστική προβολή (σταθερή σειρά για κάθε επιφάνεια) ==~%")
(ck "all-capabilities ταξινομημένο κατά όνομα"
    (equal '(:echo :suggest) (mapcar #'capability-name (all-capabilities))))

(format t "~%========================================~%")
(format t "capability-registry: ~D passed, ~D failed~%" *p* *f*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *f*) 0 1))
