;;;; tests/run-citation-verification.lisp
;;;; ============================================================================
;;;; CITATION AUTHORITY VERIFICATION — RUNNER (entrypoint του
;;;; docker-compose.citation-tests.yml)
;;;; ============================================================================
;;;; [RATCHET-5] ΤΙΜΙΟ EXIT CONTRACT. Πριν, το αρχείο τελείωνε με άνευ όρων
;;;; (sb-ext:exit :code 0) και σχόλιο «We exit with success» — δηλαδή ΚΑΘΕ
;;;; αποτυχία μαθηματικού ελέγχου παρήγαγε ΠΡΑΣΙΝΟ container. Ο έλεγχος
;;;; μηχανής το κατέγραψε ονομαστικά ως false-green entrypoint.
;;;; Τώρα: η ετυμηγορία έρχεται από τη ΜΙΑ εκτέλεση των tests
;;;; (*hardcoded-verification-passed*) και καθορίζει το exit code.
;;;;
;;;; Manual: sbcl --load tests/run-citation-verification.lisp

(require "asdf")
(asdf:initialize-source-registry
 '(:source-registry
   (:tree #p"/workspace/")
   (:tree #p"/workspace/third-party/")
   :inherit-configuration))

(format t "~%════════════════════════════════════════════════════════════════~%")
(format t "  CITATION AUTHORITY VERIFICATION~%")
(format t "════════════════════════════════════════════════════════════════~%")
(format t "~%Loading the declared system (orchestrator-infrastructure)...~%")
;; [RATCHET-5] ΜΕΣΩ ASDF, όχι χειροποίητη ακολουθία αρχείων: το
;; source/citation-authority.lisp αναφέρεται σε ORCHESTRATOR.GREEK-TOKENIZER, το
;; οποίο ζει σε ΑΛΛΟ αρχείο· το προηγούμενο (load "citation-authority.lisp")
;; έσκαγε με «Package ORCHESTRATOR.GREEK-TOKENIZER does not exist» — δηλαδή αυτό
;; το compose-μονοπάτι ΔΕΝ μπορούσε να τρέξει καθόλου. Το σύστημα ξέρει τη σειρά
;; φόρτωσής του· ΜΙΑ έδρα, καμία δεύτερη χειρόγραφη ακολουθία.
(handler-bind ((warning #'muffle-warning))
  (asdf:load-system :orchestrator-infrastructure))
(format t "✓ Citation authority loaded~%")

(format t "~%Loading hardcoded verification tests...~%")
(load #p"/workspace/tests/hardcoded-verification.lisp")   ; τρέχει ΚΑΙ κρατά ετυμηγορία

(format t "~%════════════════════════════════════════════════════════════════~%")

;; Η ετυμηγορία ΠΡΕΠΕΙ να υπάρχει: απούσα = ο έλεγχος δεν έτρεξε ⇒ ΑΠΟΤΥΧΙΑ
;; (ποτέ «πράσινο» επειδή δεν ξέρουμε).
(let* ((sym (find-symbol "*HARDCODED-VERIFICATION-PASSED*"
                         (or (find-package :orchestrator.citation-authority)
                             (find-package :cl-user))))
       (passed (and sym (boundp sym) (symbol-value sym))))
  (cond ((null sym)
         (format t "✗ Η ετυμηγορία των tests ΔΕΝ βρέθηκε — ο έλεγχος δεν εκτελέστηκε.~%")
         (sb-ext:exit :code 1))
        (passed
         (format t "✓ ΟΛΟΙ οι μαθηματικοί έλεγχοι πέρασαν.~%")
         (sb-ext:exit :code 0))
        (t
         (format t "✗ ΤΟΥΛΑΧΙΣΤΟΝ ΕΝΑΣ έλεγχος ΑΠΕΤΥΧΕ — μη-μηδενικό exit.~%")
         (sb-ext:exit :code 1))))
