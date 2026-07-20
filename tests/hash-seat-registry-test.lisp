;;;; tests/hash-seat-registry-test.lisp
;;;; ============================================================================
;;;; [audit#13] ΚΑΜΙΑ ΚΡΥΦΗ hash έδρα: set-ισότητα repo ↔ δηλωμένο μητρώο
;;;; ============================================================================
;;;; Ο κριτής: το hash-authority δήλωνε «η ONLY hash» ενώ journal/merkle/… καλούν
;;;; ironclad:digest απευθείας. Δεν ενοποιούμε ασύμβατα πρωτόκολλα· αντ' αυτού
;;;; ΕΠΙΒΑΛΛΟΥΜΕ ΜΗΧΑΝΙΚΑ ότι ΚΑΘΕ αρχείο που κάνει hashing είναι ΔΗΛΩΜΕΝΟ στο
;;;; deployment/verify/hash-seat-registry.sexp:
;;;;   • undeclared (κάνει ironclad:digest αλλά ΕΚΤΟΣ μητρώου) ⇒ FAIL (κρυφή έδρα)
;;;;   • stale (στο μητρώο αλλά ΔΕΝ κάνει πια hashing) ⇒ FAIL (νεκρή δήλωση)
;;;; Self-contained: σαρώνει source/**/*.lisp + systems/**/*.lisp, διαβάζει το μητρώο
;;;; μέσω της ΜΙΑΣ safe-read έδρας (data-only). Runnable χωρίς full build.

(let* ((here (or *load-truename* *load-pathname*))
       (seat (merge-pathnames "../source/safe-read.lisp"
                              (make-pathname :directory (pathname-directory here)))))
  (unless (probe-file seat)
    (format t "~%  SKIP — safe-read seat απών.~%") (sb-ext:exit :code 0))
  (handler-bind ((warning #'muffle-warning)) (load seat)))

(defpackage :hash-seat-registry-test (:use :cl :orchestrator.safe-read))
(in-package :hash-seat-registry-test)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %slurp (path)
  (with-open-file (s path :external-format :utf-8)
    (let ((buf (make-string (file-length s))))
      (subseq buf 0 (read-sequence buf s)))))

(defun %rel (path)
  "Repo-relative posix path, anchored στο /source/ ή /systems/ (ανθεκτικό σε
   non-truename root· το enough-namestring απαιτεί ακριβές prefix)."
  (let* ((ns (substitute #\/ #\\ (namestring path)))
         (p (or (search "/source/" ns) (search "/systems/" ns))))
    (if p (subseq ns (1+ p)) ns)))

(let* ((here (or *load-truename* *load-pathname*))
       (root (merge-pathnames "../" (make-pathname :directory (pathname-directory here))))
       ;; ── (Α) repo: κάθε .lisp που καλεί ironclad:digest* ──
       (sources (append (directory (merge-pathnames "source/**/*.lisp" root))
                        (directory (merge-pathnames "systems/**/*.lisp" root))))
       (repo-seats '()))
  (dolist (f sources)
    (let ((txt (ignore-errors (%slurp f))))
      (when (and txt (or (search "ironclad:digest-sequence" txt)
                         (search "ironclad:digest-file" txt)))
        (push (%rel f) repo-seats))))
  (setf repo-seats (sort (remove-duplicates repo-seats :test #'string=) #'string<))

  ;; ── (Β) μητρώο ──
  (multiple-value-bind (form status)
      (read-data-file (merge-pathnames "deployment/verify/hash-seat-registry.sexp" root))
    (check "μητρώο διαβάζεται data-only (safe-read :ok)" (eq status :ok))
    (let* ((plist (if (keywordp (first form)) (rest form) form))
           (seats (getf plist :seats))
           (declared (sort (mapcar (lambda (e) (getf e :file)) seats) #'string<)))
      (check "κάθε εγγραφή μητρώου φέρει :file ΚΑΙ ρητό :reason"
             (every (lambda (e) (and (stringp (getf e :file))
                                     (stringp (getf e :reason))
                                     (plusp (length (getf e :reason))))) seats))
      (check "καμία διπλή εγγραφή στο μητρώο"
             (= (length declared) (length (remove-duplicates declared :test #'string=))))
      (format t "  (repo hash-έδρες: ~D · δηλωμένες: ~D)~%" (length repo-seats) (length declared))
      ;; UNDECLARED: repo κάνει hashing αλλά εκτός μητρώου ⇒ κρυφή έδρα
      (let ((undeclared (set-difference repo-seats declared :test #'string=)))
        (check "καμία ΑΔΗΛΩΤΗ hash έδρα (undeclared ⇒ κρυφή)" (null undeclared))
        (when undeclared (format t "  UNDECLARED: ~{~A~^, ~}~%" undeclared)))
      ;; STALE: μητρώο δηλώνει αρχείο που δεν κάνει πια hashing
      (let ((stale (set-difference declared repo-seats :test #'string=)))
        (check "καμία STALE δήλωση (δηλωμένο αλλά χωρίς hashing πλέον)" (null stale))
        (when stale (format t "  STALE: ~{~A~^, ~}~%" stale)))
      ;; NEG: ο σαρωτής όντως ανιχνεύει το ironclad:digest (όχι tautology)
      (check "NEG: sanity — το hash-authority.lisp περιέχει ironclad:digest"
             (search "ironclad:digest" (%slurp (merge-pathnames "source/hash-authority.lisp" root))))
      ;; τίμια docstring: το «ONLY authorized» ΔΕΝ υπάρχει πλέον ως ψευδής ισχυρισμός
      (check "τίμια εμβέλεια: καμία ψευδής «ONLY authorized hash» δήλωση"
             (not (search "ONLY authorized hash function"
                          (%slurp (merge-pathnames "source/hash-authority.lisp" root))))))))

(format t "~%hash-seat-registry: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
