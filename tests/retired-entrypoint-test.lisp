;;;; tests/retired-entrypoint-test.lisp
;;;; ============================================================================
;;;; [0115] TOMBSTONE STAGE — regression lock του πρωτοκόλλου απόσυρσης
;;;; ============================================================================
;;;; Κλειδώνει: (α) ΚΑΘΕ αποσυρμένο entrypoint σηματοδοτεί typed
;;;; retired-entrypoint (η παγίδα πιάνει ΚΑΙ ονομάζει το σύμβολο — καμία
;;;; σιωπηλή εκτέλεση legacy μονοπατιού)· (β) οι κανονικές ζωντανές έδρες
;;;; παραμένουν λειτουργικές· (γ) κανένα αποσυρμένο δεν είναι registered command.

(in-package :orchestrator.cli)

(defvar *re-pass* 0)
(defvar *re-fail* 0)
(defmacro re-check (name form)
  `(handler-case
       (if ,form (progn (incf *re-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *re-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *re-fail*) (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(defun %re-traps-p (thunk expected-symbol)
  "T αν το THUNK σηματοδοτεί retired-entrypoint που ονομάζει το EXPECTED-SYMBOL."
  (handler-case (progn (funcall thunk) nil)
    (orchestrator.spec:retired-entrypoint (c)
      (eq (orchestrator.spec:retired-symbol c) expected-symbol))
    (error () nil)))

(format t "~%── [0115] RETIRED ENTRYPOINTS: κάθε παγίδα πιάνει και ονομάζει ──~%")

;; (α) Οι 5 CLI wrappers υπό απόσυρση
(re-check "① run-full-build ⇒ retired-entrypoint με σωστό σύμβολο"
          (%re-traps-p (lambda () (run-full-build :corpus-name :gr-syntagma))
                       'run-full-build))
(re-check "② run-full-build-ai ⇒ retired-entrypoint"
          (%re-traps-p (lambda () (run-full-build-ai :corpus-name :gr-syntagma))
                       'run-full-build-ai))
(re-check "③ run-ai-export-only ⇒ retired-entrypoint"
          (%re-traps-p (lambda () (run-ai-export-only :corpus-name :gr-syntagma))
                       'run-ai-export-only))
(re-check "④ cli::validate-pipeline ⇒ retired-entrypoint"
          (%re-traps-p (lambda () (validate-pipeline :greek-constitution))
                       'validate-pipeline))
(re-check "⑤ cli::generate-report ⇒ retired-entrypoint"
          (%re-traps-p (lambda () (generate-report :greek-constitution "/tmp/x.json"))
                       'generate-report))

;; (β) Το HF cluster υπό απόσυρση
(re-check "⑥ export-corpus-dataset ⇒ retired-entrypoint"
          (%re-traps-p (lambda () (orchestrator.ai-ingest:export-corpus-dataset nil "/tmp/hf/"))
                       'orchestrator.ai-ingest:export-corpus-dataset))
(re-check "⑦ manifest->huggingface-formatter ⇒ retired-entrypoint"
          (%re-traps-p (lambda () (orchestrator.ai-ingest:manifest->huggingface-formatter nil))
                       'orchestrator.ai-ingest:manifest->huggingface-formatter))

;; (γ) Η ζωντανή έδρα που τα αντικαθιστά ΔΟΥΛΕΥΕΙ (spec generic validate)
(re-check "⑧ ζωντανό orchestrator.spec:validate-pipeline λειτουργεί (registered pipeline)"
          (progn (orchestrator.spec:select-corpus "syntagma")
                 (orchestrator.gr-syntagma:register-active-corpus)
                 (orchestrator.spec:validate-pipeline
                  (orchestrator.gr-syntagma:greek-constitution-pipeline))
                 t))

;; (δ) Κανένα αποσυρμένο δεν είναι registered command (το μητρώο μένει καθαρό)
(re-check "⑨ κανένα αποσυρμένο σύμβολο ως registered command"
          (let ((bad nil))
            (maphash (lambda (k v) (declare (ignore v))
                       (dolist (s '("full-build" "ai-export-only" "generate-report"))
                         (when (search s k) (setf bad k))))
                     *commands*)
            (null bad)))

;; (ε) Το report της condition ονομάζει σύμβολο ΚΑΙ κανονική έδρα (διαγνωσιμότητα)
(re-check "⑩ το μήνυμα της παγίδας κατονομάζει ΑΠΟΣΥΡΜΕΝΟ + κανονική έδρα"
          (handler-case (run-full-build)
            (orchestrator.spec:retired-entrypoint (c)
              (let ((msg (princ-to-string c)))
                (and (search "ΑΠΟΣΥΡΜΕΝΟ" msg)
                     (search "RUN-FULL-BUILD" msg)
                     (search "RUN-PIPELINE" msg))))
            (error () nil)))

(format t "~%========================================~%")
(format t "RETIRED-ENTRYPOINT tests: ~D passed, ~D failed~%" *re-pass* *re-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *re-fail*) 0 1))
