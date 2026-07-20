;;;; tests/architecture-multiplicity-test.lisp
;;;; ============================================================================
;;;; [audit#12] justified-multiplicity: κάθε δηλωμένο ΑΡΧΕΙΟ-ΕΔΡΑ πρέπει να ΥΠΑΡΧΕΙ
;;;; ============================================================================
;;;; Ο κριτής βρήκε stale εγγραφή στο Σύνταγμα που δήλωνε ενεργή implementation το
;;;; source/canonical-article-id.lisp, ΔΙΑΓΡΑΜΜΕΝΟ από το branch. Η ⑫ πύλη έλεγχε ότι
;;;; υπάρχει :implementations, ΟΧΙ ότι τα αρχεία υπάρχουν. Αυτός ο έλεγχος κλειδώνει την
;;;; source-level existence: κάθε implementation που ΜΟΙΑΖΕΙ αρχείο-έδρα (*.lisp ή
;;;; source//systems//deployment//tests/ prefix) ΠΡΕΠΕΙ να υπάρχει στο δέντρο.
;;;; Self-contained: διαβάζει το Σύνταγμα μέσω της ΜΙΑΣ safe-read έδρας (data-only).

(let* ((here (or *load-truename* *load-pathname*))
       (seat (merge-pathnames "../source/safe-read.lisp"
                              (make-pathname :directory (pathname-directory here)))))
  (unless (probe-file seat)
    (format t "~%  SKIP — source/safe-read.lisp not present.~%") (sb-ext:exit :code 0))
  (handler-bind ((warning #'muffle-warning)) (load seat)))

(defpackage :architecture-multiplicity-test (:use :cl :orchestrator.safe-read))
(in-package :architecture-multiplicity-test)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %prefix-p (p s) (and (>= (length s) (length p)) (string= p s :end2 (length p))))
(defun %file-impl-p (s)
  (and (stringp s)
       (or (search ".lisp" s)
           (%prefix-p "source/" s) (%prefix-p "systems/" s)
           (%prefix-p "deployment/" s) (%prefix-p "tests/" s))))

(let* ((here (or *load-truename* *load-pathname*))
       (root (merge-pathnames "../" (make-pathname :directory (pathname-directory here))))
       (path (merge-pathnames "deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp" root)))
  (multiple-value-bind (form status) (read-data-file path)
    (check "Σύνταγμα διαβάζεται data-only (safe-read :ok)" (eq status :ok))
    ;; top: (:lawmax-architecture-constitution :key val … :justified-multiplicity (…))
    (let* ((plist (if (keywordp (first form)) (rest form) form))
           (just (getf plist :justified-multiplicity))
           (missing '()) (checked 0))
      (check "υπάρχει :justified-multiplicity" (consp just))
      (dolist (entry just)
        (dolist (impl (getf entry :implementations))
          (when (%file-impl-p impl)
            (incf checked)
            (unless (probe-file (merge-pathnames impl root))
              (push (list (getf entry :area) impl) missing)))))
      (format t "  (ελέγχθηκαν ~D αρχεία-έδρες σε ~D εγγραφές)~%" checked (length just))
      (check "ΚΑΘΕ file-path implementation του Συντάγματος ΥΠΑΡΧΕΙ (καμία stale)"
             (null missing))
      (when missing
        (format t "  ΛΕΙΠΟΥΝ: ~{~A~^, ~}~%" missing))
      ;; NEG: ο ανιχνευτής όντως πιάνει ανύπαρκτο αρχείο (όχι tautology)
      (check "NEG: ανύπαρκτο file-path ⇒ ανιχνεύεται ως missing"
             (and (%file-impl-p "source/DEFINITELY-NOT-THERE.lisp")
                  (not (probe-file (merge-pathnames "source/DEFINITELY-NOT-THERE.lisp" root)))))
      ;; NEG: μη-file implementation (package/surface) ΔΕΝ θεωρείται αρχείο
      (check "NEG: package-name implementation ΔΕΝ ελέγχεται ως αρχείο"
             (not (%file-impl-p "orchestrator.proposals (Σ11 γνώση)"))))))

(format t "~%architecture-multiplicity: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
