;;;; source/provenance-link.lisp
;;;; ============================================================================
;;;; Ο ΔΕΣΜΟΣ ΠΡΟΕΛΕΥΣΗΣ — ίχνη ⋈ συμβόλαια ⋈ συστατικά ⋈ αποδείξεις
;;;; ============================================================================
;;;;
;;;; Ο πυρήνας ιχνών (orchestrator.trace) δεν γνωρίζει τίποτα. ΕΔΩ κάθε γεγονός
;;;; ίχνους επιλύεται σε: συμβόλαιο (τι υποσχόταν η εκτέλεση), συστατικό (ποιο
;;;; όργανο ήταν), ικανότητα/ρόλο (τι υπηρετούσε) — και ελέγχεται: κρίσιμη
;;;; εκτέλεση χωρίς συμβόλαιο/συστατικό/απόδειξη = ΠΑΡΑΒΑΣΗ, όχι σιωπή.

(defpackage :orchestrator.exec-provenance
  (:use :cl)
  (:export #:resolve-event #:validate-provenance #:trace-coverage
           #:declare-trace-debt! #:*trace-debts*
           #:last-conclusion-report))

(in-package :orchestrator.exec-provenance)

(defvar *trace-debts* '()
  "ΡΗΤΑ δηλωμένα χρέη ενοργάνωσης: legal-critical συναρτήσεις που ΔΕΝ
   αφήνουν ακόμη ίχνος — ορατά στον καθρέφτη, ποτέ σιωπηλά.")

(defun declare-trace-debt! (name reason)
  (setf *trace-debts*
        (cons (cons (string-downcase name) reason)
              (remove (string-downcase name) *trace-debts*
                      :key #'car :test #'string=))))

(defun resolve-event (ev)
  "Γεγονός ίχνους → plist δεσμών: :contract :capability :role :component-id
   :component-known. Ό,τι δεν επιλύεται μένει ΡΗΤΑ NIL."
  (let* ((sym (orchestrator.trace:tevent-symbol ev))
         (contract (and sym (orchestrator.contracts:find-contract sym)))
         (capability (or (and contract (orchestrator.contracts:contract-capability contract))
                         (getf (orchestrator.trace:tevent-data ev) :capability)))
         (pkg (orchestrator.trace:tevent-package ev))
         (component-id (and sym pkg (format nil "symbol:~A::~A"
                                            (string-downcase pkg)
                                            (string-downcase sym)))))
    (list :contract (and contract (orchestrator.contracts:contract-name contract))
          :capability capability
          :role (and contract (orchestrator.contracts:contract-role contract))
          :component-id component-id
          :component-known (and component-id
                                (orchestrator.components:find-component component-id)
                                t))))

(defun %symbol-kinds ()
  "Τα είδη γεγονότων που ΦΕΡΟΥΝ σύμβολο εκτέλεσης και οφείλουν δεσμούς."
  '(:conclusion :verification :legal-state :identity :artifact))

(defun validate-provenance (&key (events (orchestrator.trace:all-events))
                                 registry-built-p)
  "Ο ΕΠΙΚΥΡΩΤΗΣ ΠΡΟΕΛΕΥΣΗΣ: λίστα παραβάσεων. REGISTRY-BUILT-P: όταν το
   μητρώο συστατικών είναι φρέσκο, απαιτείται και επίλυση component-id."
  (let ((v '()))
    (flet ((bad (fmt &rest args) (push (apply #'format nil fmt args) v)))
      (when (eq orchestrator.trace:*trace-profile* :off)
        (bad "Το προφίλ ιχνών είναι :off — ο παραγωγικός νομικός τρόπος απαιτεί τουλάχιστον :legal-critical."))
      (dolist (ev events)
        (when (member (orchestrator.trace:tevent-kind ev) (%symbol-kinds))
          (let* ((sym (orchestrator.trace:tevent-symbol ev))
                 (links (resolve-event ev)))
            (cond
              ((null sym)
               (bad "Ίχνος #~D (~A) χωρίς σύμβολο εκτέλεσης."
                    (orchestrator.trace:tevent-id ev) (orchestrator.trace:tevent-kind ev)))
              ((and (null (getf links :contract))
                    (not (assoc (string-downcase sym) *trace-debts* :test #'string=)))
               (bad "Ίχνος #~D: το «~A» εκτελέστηκε ΧΩΡΙΣ συμβόλαιο και χωρίς δηλωμένο χρέος."
                    (orchestrator.trace:tevent-id ev) sym))
              ((and registry-built-p (getf links :component-id)
                    (not (getf links :component-known)))
               (bad "Ίχνος #~D: το συστατικό «~A» ΔΕΝ επιλύεται στο μητρώο."
                    (orchestrator.trace:tevent-id ev) (getf links :component-id))))
            ;; απόδειξη: συμπέρασμα χωρίς δεσμό απόδειξης = μισή προέλευση
            (when (and (eq (orchestrator.trace:tevent-kind ev) :conclusion)
                       (not (getf (orchestrator.trace:tevent-data ev) :proofs-p)))
              (bad "Ίχνος #~D: ΣΥΜΠΕΡΑΣΜΑ χωρίς δεσμό σε κόμβο απόδειξης."
                   (orchestrator.trace:tevent-id ev)))
            ;; ξεπερασμένη πηγή: το αρχείο του ίχνους ≠ δίσκος τώρα
            (let ((src (orchestrator.trace:tevent-source ev))
                  (h (getf (orchestrator.trace:tevent-data ev) :source-hash)))
              (when (and src h)
                (let ((now (orchestrator.component-scan:known-file-hash src)))
                  (when (and now (string/= now h))
                    (bad "Ίχνος #~D: αναφέρει ΞΕΠΕΡΑΣΜΕΝΟ hash πηγής «~A»."
                         (orchestrator.trace:tevent-id ev) src)))))))))
    (nreverse v)))

(defun trace-coverage ()
  "Η ΚΑΛΥΨΗ ΕΝΟΡΓΑΝΩΣΗΣ: (values traced via debts silent) — τα legal-critical
   :function συμβόλαια οφείλουν ίχνος (άμεσο, μέσω γονέα, ή ΡΗΤΟ χρέος).
   Το SILENT είναι το απαράδεκτο σύνολο: ούτε ίχνος ούτε δήλωση."
  (let ((traced '()) (via '()) (debts '()) (silent '()))
    (dolist (c (orchestrator.contracts:all-contracts))
      (when (and (eq (orchestrator.contracts:contract-kind c) :function)
                 (orchestrator.contracts:contract-legal-critical c))
        (let* ((n (orchestrator.contracts:contract-name c))
               (entry (orchestrator.trace:traced-entry n)))
          (cond ((and entry (eq (getf entry :how) :direct)) (push n traced))
                (entry (push (cons n (getf entry :via)) via))
                ((assoc (string-downcase n) *trace-debts* :test #'string=)
                 (push n debts))
                (t (push n silent))))))
    (values (nreverse traced) (nreverse via) (nreverse debts) (nreverse silent))))

(defun last-conclusion-report (&optional (stream *standard-output*))
  "trace-last-conclusion: από ποια ΠΡΑΓΜΑΤΙΚΗ εκτέλεση προήλθε το τελευταίο
   νομικό συμπέρασμα — ίχνος, κανόνες, γεγονότα, καταστάσεις, απόδειξη,
   συμβόλαιο, συστατικό, εντολή-ρίζα. Επιστρέφει T/NIL (τίμια)."
  (let* ((id (orchestrator.trace:last-conclusion-id))
         (ev (and id (orchestrator.trace:find-event id))))
    (cond
      ((null ev)
       (format stream "~%Κανένα συμπέρασμα με ίχνος σε αυτή τη συνεδρία — τίμια δήλωση.~%")
       nil)
      (t
       (let ((d (orchestrator.trace:tevent-data ev))
             (links (resolve-event ev)))
         (format stream "~%── ΠΡΟΕΛΕΥΣΗ ΤΕΛΕΥΤΑΙΟΥ ΣΥΜΠΕΡΑΣΜΑΤΟΣ (ίχνος #~D) ──~%" id)
         (format stream "  εντολή-ρίζα: ~A · χρόνος: ~D~%"
                 (or (orchestrator.trace:tevent-command ev) "—")
                 (orchestrator.trace:tevent-time ev))
         (format stream "  εκτέλεση: ~A::~A (~A)~%"
                 (orchestrator.trace:tevent-package ev)
                 (orchestrator.trace:tevent-symbol ev)
                 (orchestrator.trace:tevent-source ev))
         (format stream "  συμβόλαιο: ~A · ικανότητα: ~A · ρόλος: ~A~%"
                 (getf links :contract) (getf links :capability) (getf links :role))
         (format stream "  συστατικό: ~A~%" (getf links :component-id))
         (format stream "  γεγονότα-είσοδος: ~D · κανόνες που πυροδότησαν: ~{~A~^, ~}~%"
                 (or (getf d :facts-count) 0) (or (getf d :rules) '("—")))
         (format stream "  θέσεις: ~{~S~^ · ~}~%" (getf d :positions))
         (format stream "  δεσμός απόδειξης: ~:[ΟΧΙ~;ΝΑΙ — κάθε θέση φέρει δέντρο~]~%"
                 (getf d :proofs-p))
         (let ((states (orchestrator.trace:events-where :kind :legal-state :limit 3)))
           (when states
             (format stream "  έννομες καταστάσεις (τελευταία ίχνη):~%")
             (dolist (s states)
               (let ((sd (orchestrator.trace:tevent-data s)))
                 (format stream "    #~D: +~D/−~D~@[ − πχ ~S~]~%"
                         (orchestrator.trace:tevent-id s)
                         (getf sd :created-count) (getf sd :withdrawn-count)
                         (first (getf sd :withdrawn)))))))
         t)))))
