;;;; authority-v2/tests/probe-canonical-files.lisp
;;;; ============================================================================
;;;; Η ΣΤΑΘΕΡΑ ΤΟΥ ΠΑΡΑΓΩΓΙΚΟΥ ΠΥΡΗΝΑ, ΟΠΩΣ ΤΗ ΒΛΕΠΕΙ Ο ΙΔΙΟΣ
;;;; ============================================================================
;;;; Εκπέμπει τη ΣΕΙΡΑ που ΠΡΑΓΜΑΤΙΚΑ παράγει η collect-epistemic-artifacts:
;;;; τα ονόματα του +epistemic-canonical-files+ ταξινομημένα με ΤΟΝ ΙΔΙΟ
;;;; συγκριτή (string< πάνω στα namestrings). Καμία χειροκίνητη αντιγραφή —
;;;; ο έλεγχος ταύτισης με το authority-v2/capture/canonical-profile.json
;;;; γίνεται από το capture-seat-differential-test.sh.
;;;;
;;;;   sbcl --core <core> --script probe-canonical-files.lisp
;;;; Έξοδος: μία γραμμή ανά αρχείο, με πρόθεμα «CANON ».
;;;; ============================================================================

(let* ((ep (find-package :orchestrator.epistemic))
       (sym (and ep (find-symbol "+EPISTEMIC-CANONICAL-FILES+" ep))))
  (unless (and sym (boundp sym))
    (format t "~&ERROR η σταθερά +EPISTEMIC-CANONICAL-FILES+ ΔΕΝ ΒΡΕΘΗΚΕ~%")
    (sb-ext:quit :unix-status 1))
  ;; ΙΔΙΟΣ συγκριτής με τη collect-epistemic-artifacts (sort string< σε namestrings).
  (dolist (f (sort (copy-list (symbol-value sym)) #'string<))
    (format t "~&CANON ~A~%" f)))
(sb-ext:quit :unix-status 0)
