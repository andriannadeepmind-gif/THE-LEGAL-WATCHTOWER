;;;; authority-v2/tests/probe-merkle-root-of-files.lisp
;;;; ============================================================================
;;;; ΔΙΑΦΟΡΙΚΟΣ ΜΑΡΤΥΡΑΣ — Η ΠΑΡΑΓΩΓΙΚΗ ΕΔΡΑ ΜΙΛΑΕΙ ΓΙΑ ΤΟΝ ΕΑΥΤΟ ΤΗΣ
;;;; ============================================================================
;;;; Δεν αντιγράφει τον αλγόριθμο — ΚΑΛΕΙ την orchestrator.merkle:merkle-root-of-files
;;;; (source/merkle-authority.lisp, hash-leaf-file = SHA-256(0x00 ‖ ΩΜΑ BYTES))
;;;; πάνω στα ΑΝΤΙΓΡΑΦΑ του quarantine, με τη ΣΕΙΡΑ που δίνεται.
;;;;
;;;;   sbcl --script probe-merkle-root-of-files.lisp <file1> <file2> ...
;;;; Έξοδος: μία γραμμή «RELEASE-ROOT sha256:…» (ή «ERROR …», exit 1).
;;;; ============================================================================

(require :asdf)
(require :sb-posix)

(defvar *root* (or (uiop:getenv-pathname "LAWMAX_REPO" :ensure-directory t)
                   (uiop:getcwd)))
(setf asdf:*central-registry*
      (append (list *root*) (directory (merge-pathnames "systems/*/" *root*))))
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(merge-pathnames "third-party/" *root*)) :inherit-configuration))
(locally (declare (sb-ext:muffle-conditions sb-ext:compiler-note style-warning warning))
  (handler-bind ((warning #'muffle-warning))
    (asdf:load-system :alexandria)
    (asdf:load-system :log4cl)
    (asdf:load-system :orchestrator-core-runtime)))

(let ((files (cdr sb-ext:*posix-argv*)))
  (handler-case
      (format t "~&RELEASE-ROOT ~A~%"
              (funcall (intern "MERKLE-ROOT-OF-FILES" :orchestrator.merkle) files))
    (error (e)
      (format t "~&ERROR ~A~%" e)
      (sb-ext:quit :unix-status 1))))
