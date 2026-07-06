;;;; source/adoption-decision.lisp
;;;; ============================================================================
;;;; Η ΑΠΟΦΑΣΗ ΥΙΟΘΕΤΗΣΗΣ — what-if governed adoption, όχι «πέρασαν τα τεστ»
;;;; ============================================================================
;;;;
;;;; «Καμία αλλαγή δεν γίνεται trusted επειδή δουλεύει. Γίνεται trusted μόνο
;;;; αν αποδεικνύεται: τι αλλάζει, γιατί, τι επηρεάζεται, τι βελτιώνεται, τι
;;;; κινδυνεύει, τι ελέγχθηκε, ποιος ενέκρινε, πώς αναστρέφεται.»
;;;;
;;;; Η απόφαση είναι ΔΟΜΗΜΕΝΟ αντικείμενο που καταναλώνει το what-if report
;;;; (το οποίο καταναλώνει ταυτότητα/ικανότητες/συμβόλαια/συστατικά/ίχνη) και
;;;; αφήνει ΥΠΟΓΕΓΡΑΜΜΕΝΟ (SHA-256) αρχείο απόφασης ΚΑΙ ίχνος εκτέλεσης.
;;;; Έλλειψη οποιουδήποτε προαπαιτούμενου σε legal-critical ⇒ ΔΕΝ υιοθετείται.

(defpackage :orchestrator.adoption
  (:use :cl)
  (:export #:can-adopt #:decision-get #:record-adoption!
           #:adoption-records #:validate-adoption-records))

(in-package :orchestrator.adoption)

(defun can-adopt (proposal &key (approvals nil approvals-p))
  "Η ΑΠΟΦΑΣΗ: plist με :verdict (:allowed/:requires-human/:shadow-only/:denied),
   :reasons, :missing, :regression, :whatif (η πλήρης αναφορά — η υιοθέτηση
   ΧΩΡΙΣ what-if είναι αδύνατη εκ κατασκευής). APPROVALS: εγκρίσεις της
   ΣΤΙΓΜΗΣ (πχ (:creator-cli)) που προστίθενται στης πρότασης."
  (let* ((proposal (if (stringp proposal)
                       (or (orchestrator.whatif:find-proposal proposal)
                           (return-from can-adopt
                             (list :verdict :denied
                                   :reasons (list (format nil "ανύπαρκτη πρόταση «~A»" proposal))
                                   :missing '(:proposal) :whatif nil)))
                       proposal))
         (effective (if approvals-p
                        (union approvals (orchestrator.whatif:proposal-approvals proposal)
                               :test #'equal)
                        (orchestrator.whatif:proposal-approvals proposal)))
         (report (orchestrator.whatif:what-if proposal))
         (missing (copy-list (orchestrator.whatif:report-get report :missing)))
         (reasons '()))
    ;; θεσμική ταυτότητα: χωρίς δηλωμένο Ίδρυμα δεν υπάρχει «ποιος αποφασίζει»
    (unless (orchestrator.institution:the-institution)
      (push "ΔΕΝ έχει δηλωθεί Ίδρυμα" missing))
    (unless (orchestrator.whatif:proposal-files proposal)
      (push "ΧΩΡΙΣ δηλωμένα επηρεαζόμενα αρχεία/συστατικά" missing))
    (unless (orchestrator.whatif:proposal-sandbox proposal)
      (push "ΧΩΡΙΣ σχέδιο σκιώδους δοκιμής" missing))
    (let* ((needs-human (orchestrator.whatif:report-get report :needs-human))
           (has-human (member :creator-cli effective))
           (has-policy (find :policy effective
                             :key (lambda (a) (if (consp a) (car a) a))))
           (verdict
             (cond (missing :denied)
                   ((and needs-human (not has-human) (not has-policy))
                    :requires-human)
                   (t :allowed))))
      (when (eq verdict :denied)
        (push "ελλείψεις προαπαιτουμένων — μένει σκιά/χρέος" reasons))
      (when (eq verdict :requires-human)
        (push "legal-critical/υψηλού κινδύνου — αποφασίζει ο δημιουργός (ή μετρημένη πολιτική κλάσης)" reasons))
      (when (eq verdict :allowed)
        (push (format nil "πλήρη προαπαιτούμενα· έγκριση: ~{~A~^, ~}" effective) reasons))
      (list :verdict verdict
            :proposal (orchestrator.whatif:proposal-id proposal)
            :reasons (nreverse reasons)
            :missing missing
            :regression (orchestrator.whatif:report-get report :regression)
            :affected-capabilities
            (append (orchestrator.whatif:report-get report :direct-impact)
                    (orchestrator.whatif:report-get report :downstream-impact))
            :affected-contracts (orchestrator.whatif:report-get report :contracts)
            :affected-traces (orchestrator.whatif:report-get report :affected-traces)
            :stale-proofs (orchestrator.whatif:report-get report :stale-proofs)
            :rollback (orchestrator.whatif:proposal-rollback proposal)
            :approvals effective
            :whatif report))))

(defun decision-get (decision key) (getf decision key))

(defvar *adoption-records* '()
  "Υπογεγραμμένα αρχεία αποφάσεων — append-only μέσα στη συνεδρία·
   διαρκές ledger = το ίδιο μονοπάτι βιογραφίας (self-history) που ήδη
   κρατά τις υιοθετήσεις γνώσης.")

(defun record-adoption! (decision)
  "Υπογεγραμμένο αρχείο απόφασης: SHA-256 πάνω στη σειριοποίηση (data-only)
   + ίχνος :adoption-decision. Επιστρέφει (values record sha trace-id)."
  (let* ((body (let ((*print-pretty* nil)) (prin1-to-string decision)))
         (sha (ironclad:byte-array-to-hex-string
               (ironclad:digest-sequence
                :sha256 (babel:string-to-octets body :encoding :utf-8))))
         (record (list :sha sha :decision decision
                       :time (get-universal-time))))
    (push record *adoption-records*)
    (let ((tid (orchestrator.trace:emit! :adoption-decision
                :symbol "can-adopt" :package "orchestrator.adoption"
                :source "source/adoption-decision.lisp"
                :data (list :proposal (decision-get decision :proposal)
                            :verdict (decision-get decision :verdict)
                            :sha sha))))
      (values record sha tid))))

(defun adoption-records () (copy-list *adoption-records*))

(defun validate-adoption-records ()
  "Ο ΕΛΕΓΚΤΗΣ ΤΟΥ LEDGER: κάθε αρχείο απόφασης δείχνει σε ΥΠΑΡΚΤΗ πρόταση,
   φέρει what-if, και η υπογραφή του επαληθεύεται. Λίστα παραβάσεων."
  (let ((v '()))
    (dolist (r *adoption-records*)
      (let* ((d (getf r :decision))
             (pid (decision-get d :proposal)))
        (unless (and pid (orchestrator.whatif:find-proposal pid))
          (push (format nil "αρχείο απόφασης δείχνει ΑΝΥΠΑΡΚΤΗ πρόταση «~A»" pid) v))
        (unless (decision-get d :whatif)
          (push (format nil "απόφαση «~A» ΧΩΡΙΣ what-if — παράκαμψη απαγορευμένη" pid) v))
        (let ((body (let ((*print-pretty* nil)) (prin1-to-string d))))
          (unless (string= (getf r :sha)
                           (ironclad:byte-array-to-hex-string
                            (ironclad:digest-sequence
                             :sha256 (babel:string-to-octets body :encoding :utf-8))))
            (push (format nil "απόφαση «~A»: η υπογραφή ΔΕΝ επαληθεύεται" pid) v)))))
    (nreverse v)))
