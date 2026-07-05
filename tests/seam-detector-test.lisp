;;;; tests/seam-detector-test.lisp
;;;; The audit's hyphenation-seam detector guarantees "0 σπασμένες ραφές": it must
;;;; flag REAL text-loss seams (δικαστη- αυτόν) while NOT false-flagging legitimate
;;;; Greek enumeration ranges («στοιχεία α΄- θ΄», «α- β») or separator dashes. The
;;;; discriminator is: a real word has TWO letters immediately before the hyphen,
;;;; an enumeration label does not (a tonos «α΄-» or a single letter «α-»).

(in-package :orchestrator.cli)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== NOT seams: legitimate dashes / enumeration ranges ==~%")
;; The exact poinikos art-122 false positive that this fix removes.
(check "enumeration «α΄- θ΄» (tonos before) is NOT a seam"
       (null (%text-hyphen-seam-p "τα μέτρα στα στοιχεία α΄- θ΄ της πρώτης")))
(check "single-letter range «α- β» is NOT a seam"
       (null (%text-hyphen-seam-p "μεταξύ α- β υπάρχει")))
(check "spaced separator dash «λέξη - λέξη» is NOT a seam"
       (null (%text-hyphen-seam-p "η μία λέξη - η άλλη λέξη")))
(check "joined compound «κοινωνικο-οικ.» is NOT a seam"
       (null (%text-hyphen-seam-p "ο κοινωνικο-οικονομικός παράγοντας")))

(format t "~%== ARE seams: real text-loss at a hyphenation break ==~%")
(check "«δικαστη- αυτόν» IS a seam"
       (%text-hyphen-seam-p "ο πρόεδρος του δικαστη- αυτόν άλλο συνήγορο"))
(check "«συ- πράξεις» IS a seam"
       (%text-hyphen-seam-p "και τις συ- πράξεις είναι δυνατόν"))
(check "a seam returns CONTEXT (a string), not just T"
       (stringp (%text-hyphen-seam-p "ο πρόεδρος του δικαστη- αυτόν")))

(format t "~%========================================~%")
(format t "Seam-detector tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
