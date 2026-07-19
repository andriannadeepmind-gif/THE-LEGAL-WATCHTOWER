;;;; tests/auto-update-verdict-test.lisp
;;;; ============================================================================
;;;; REGRESSION LOCK — τίμια ετυμηγορία του ΠΛΗΡΟΥΣ ΚΥΚΛΟΥ (--auto-update)
;;;; ============================================================================
;;;; Κλειδώνει την αναλλοίωτη που έσβησε το σιωπηλό fallback: το «όλα καθαρά»
;;;; (clean-p) ισχύει ΜΟΝΟ όταν καμία φάση δεν απέτυχε — ούτε κρίσιμη ούτε soft.
;;;; Μια καταπιεσμένη soft αποτυχία (rc=0 αλλά μη-κενές failures) ΔΕΝ επιτρέπεται
;;;; πλέον να μεταμφιεστεί σε «όλα καθαρά». Self-contained· exit 0/1.

(in-package :orchestrator.cli)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %verdict (rc fails) (multiple-value-list (%cycle-verdict rc fails)))

(format t "~%== ΠΛΗΡΗΣ ΚΥΚΛΟΣ: τίμια ετυμηγορία (anti-masquerade) ==~%")

(check "καμία αποτυχία -> rc 0 ΚΑΙ «όλα καθαρά»"
       (equal '(0 t) (%verdict 0 '())))

;; Η ΚΑΡΔΙΑ του σβησίματος: soft αποτυχία με rc=0 ΔΕΝ είναι «όλα καθαρά».
(check "soft αποτυχία σε rc=0 -> ΟΧΙ «όλα καθαρά» (anti-masquerade)"
       (equal '(0 nil) (%verdict 0 '(("λήψη πηγών" . "network down")))))

(check "κρίσιμη αποτυχία -> rc≠0 ΚΑΙ ΟΧΙ «όλα καθαρά»"
       (equal '(1 nil) (%verdict 1 '(("έκδοση αποδείξεων" . "boom")))))

(check "κρίσιμη rc διατηρείται (rc 2 δεν ισοπεδώνεται)"
       (equal '(2 nil) (%verdict 2 '(("ολομέλεια πυλών" . "rc=2")))))

(check "πολλαπλές soft αποτυχίες σε rc=0 -> ΟΧΙ «όλα καθαρά»"
       (equal '(0 nil) (%verdict 0 '(("παραπομπές" . "x") ("υπεργράφος" . "y")))))

(format t "~%Auto-update verdict tests: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
