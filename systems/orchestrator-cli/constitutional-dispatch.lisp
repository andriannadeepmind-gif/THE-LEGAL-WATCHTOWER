;;;; systems/orchestrator-cli/constitutional-dispatch.lisp
;;;; ============================================================================
;;;; Η ΣΥΝΤΑΓΜΑΤΙΚΗ ΔΡΟΜΟΛΟΓΗΣΗ — ο φραγμός ως ΙΔΙΟΤΗΤΑ, με CLOS around
;;;; ============================================================================
;;;;
;;;; Κάθε εγγεγραμμένη εντολή δρομολογείται ΜΕΣΩ της EXECUTE-COMMAND. Η
;;;; πρωτεύουσα μέθοδος εκτελεί· η :AROUND μέθοδος ΕΙΝΑΙ ο συνταγματικός
;;;; φραγμός. Δεν είναι έλεγχος που «καλείται» — είναι το μεσολαβούν στρώμα του
;;;; ίδιου του πράττειν (CLOS method-combination): καμία πράξη δεν φτάνει στην
;;;; πρωτεύουσα μέθοδο χωρίς να περάσει από το σύνταγμα.
;;;;
;;;;   • Αντισυνταγματική πράξη → ΔΕΝ εκτελείται· αρνείται με απόδειξη στο άρθρο.
;;;;   • Ο δημιουργός (Άρθρο 1) μπορεί να παρακάμψει ΡΗΤΑ — και η υπέρβαση
;;;;     καταγράφεται στη βιογραφία. Ποτέ σιωπηλή παράβαση.
;;;;
;;;; Ο LAWMAX αποκτά έτσι την πιο νοήμονα ικανότητα: να ρωτά «ΠΡΕΠΕΙ;», όχι
;;;; μόνο «μπορώ;» — να αρνείται μια πράξη που αντιβαίνει στις αρχές του και να
;;;; απαιτεί συνειδητή δικαιολόγηση.

(in-package :orchestrator.cli)

(defgeneric execute-command (name fn args)
  (:documentation "Δρομολόγηση εντολής NAME (χειριστής FN, ορίσματα ARGS) ΜΕΣΩ
   του συντάγματος. Επιστρέφει exit-code."))

(defmethod execute-command (name fn args)
  "Πρωτεύουσα: η καθαυτό εκτέλεση της εντολής."
  (declare (ignore name))
  (funcall fn args))

(defun %constitutional-refusal (name article reason)
  (format t "~%── ΣΥΝΤΑΓΜΑΤΙΚΗ ΑΡΝΗΣΗ ──~%")
  (format t "Η πράξη «~A» αναστέλλεται — αντισυνταγματική τώρα.~%" name)
  (format t "  ∵ ~A~%" article)
  (format t "  ∵ κατάσταση: ~A~%" reason)
  (format t "  ∴ δεν εκτελείται.~%")
  (format t "~%Συνειδητή παράκαμψη — ΣΤΟΧΕΥΜΕΝΗ και ΑΙΤΙΟΛΟΓΗΜΕΝΗ (καταγράφεται στη βιογραφία):~%~
             ~4Tπρόσθεσε «--force» ΚΑΙ θέσε LAWMAX_OVERRIDE_REASON=\"γιατί\"~%~
             ~4Tή θέσε LAWMAX_OVERRIDE=\"~A\" ΚΑΙ LAWMAX_OVERRIDE_REASON=\"γιατί\"~%" name))

(defun %constitutional-override (name article reason token)
  (format t "~%── ΣΥΝΤΑΓΜΑΤΙΚΗ ΠΑΡΑΚΑΜΨΗ [~A] ──~%" token)
  (format t "Ο δημιουργός παρακάμπτει συνειδητά: ~A~%  κατάσταση: ~A~%" article reason)
  (ignore-errors
    (orchestrator.self-history:record!
     :constitutional-override
     (format nil "Παράκαμψη [~A] για «~A»: ~A (~A)" token name article reason))))

(defmethod execute-command :around (name fn args)
  "Ο ΣΥΝΤΑΓΜΑΤΙΚΟΣ ΦΡΑΓΜΟΣ + Η ΡΙΖΑ ΤΟΥ ΙΧΝΟΥΣ. Κάθε πράξη περνά από εδώ:
   ο φραγμός αποφασίζει, και η απόφασή του (μαζί με τον κωδικό εξόδου) γίνεται
   το γονικό span ΟΛΩΝ των ιχνών της εκτέλεσης — provenance από τη ρίζα."
  (multiple-value-bind (allowed article reason) (orchestrator.constitution:evaluate name)
    (orchestrator.trace:with-span
        (:command :severity :command :symbol (string name)
         :package "orchestrator.cli" :command (string name)
         :source "systems/orchestrator-cli/constitutional-dispatch.lisp"
         :data-fn (lambda (rc)
                    (list :exit rc :constitutional (if allowed :allowed :blocked)
                          :article (and (not allowed) article))))
      (if allowed
          (call-next-method)
          (multiple-value-bind (ovr token) (orchestrator.constitution:overridden-p args name)
            (if ovr
                (progn (%constitutional-override name article reason token)
                       (call-next-method))
                (progn (%constitutional-refusal name article reason)
                       1)))))))
