;;;; tests/version-chain-tc2-test.lisp
;;;; ============================================================================
;;;; REGRESSION LOCK — [T-C2] version-graph chain-fork race fix
;;;; ============================================================================
;;;; Κλειδώνει το διασωσμένο fix: το %journal! υπολογίζει το next-chain από το
;;;; ΠΡΑΓΜΑΤΙΚΟ tail (LAST) υπό το κλείδωμα, ΟΧΙ από pre-lock in-memory κεφαλή.
;;;;   (α) κανονική λειτουργία: append + verify-chain ΟΚ (behavior preserved)
;;;;   (β) desynced in-memory κεφαλή ⇒ version-chain-stale (fail-closed, κανένα
;;;;       σιωπηλό fork) — το ΑΚΡΙΒΩΣ σφάλμα που το παλιό (ignore last) έγραφε σιωπηλά
;;;;   (γ) μετά το fail-closed: το πραγματικό tail ΑΝΕΠΑΦΟ (verify-chain ΟΚ, ίδια κεφαλή)
;;;; Self-contained· exit 0/1.

(in-package :orchestrator.cli)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== [T-C2] version-graph chain-fork race fix ==~%")

(let* ((body (format nil "test/vg-tc2-~D" (get-internal-real-time)))
       (g (orchestrator.version-graph:make-graph body)))
  ;; (α) κανονική λειτουργία: genesis append γράφεται, verify-chain ΟΚ
  (orchestrator.version-graph:submit-genesis!
   g (orchestrator.version-graph:make-version-spec
      :provision-id "gr/test#art:1" :text "Αρχικό." :valid-from "2000-01-01"
      :assurance :attested-manual))
  (let ((head-before (orchestrator.version-graph:graph-chain-head g)))
    (check "α: κανονικό genesis append + verify-chain ΟΚ (behavior preserved)"
           (and (stringp head-before)
                (multiple-value-bind (ok head n) (orchestrator.version-graph:verify-chain body)
                  (and ok (equal head head-before) (>= n 1)))))

    ;; (β) desync της in-memory κεφαλής ⇒ το επόμενο %journal! ΠΡΕΠΕΙ να σκάσει
    ;; με version-chain-stale — ΟΧΙ να γράψει σιωπηλά forked αλυσίδα.
    (setf (orchestrator.version-graph::vg-chain g) "BOGUS-STALE-HEAD-0000")
    (check "β: desynced in-memory κεφαλή ⇒ version-chain-stale (fail-closed, κανένα fork)"
           (handler-case
               (progn
                 (orchestrator.version-graph::%journal!
                  g (list :kind :tc2-probe :at "2001-01-01T00:00:00Z"
                          :record-id "tc2" :provision-id "gr/test#art:1"))
                 nil)                         ; αν ΔΕΝ σκάσει → FAIL (σιωπηλό fork)
             (orchestrator.version-graph:version-chain-stale () t)))

    ;; (γ) το πραγματικό tail ΔΕΝ μολύνθηκε: επαναφορά κεφαλής + verify-chain ΟΚ, ίδια κεφαλή
    (setf (orchestrator.version-graph::vg-chain g) head-before)
    (check "γ: μετά το fail-closed το tail ΑΝΕΠΑΦΟ (verify-chain ΟΚ, ίδια κεφαλή)"
           (multiple-value-bind (ok head) (orchestrator.version-graph:verify-chain body)
             (and ok (equal head head-before))))))

(format t "~%version-chain T-C2 tests: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
