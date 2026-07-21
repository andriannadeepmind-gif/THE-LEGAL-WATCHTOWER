;;;; tests/architecture-multiplicity-test.lisp
;;;; ============================================================================
;;;; [audit#12] justified-multiplicity: κάθε δηλωμένο ΑΡΧΕΙΟ-ΕΔΡΑ πρέπει να ΥΠΑΡΧΕΙ
;;;; ============================================================================
;;;; Ο κριτής βρήκε stale εγγραφή στο Σύνταγμα που δήλωνε ενεργή implementation το
;;;; source/canonical-article-id.lisp, ΔΙΑΓΡΑΜΜΕΝΟ από το branch. Η ⑫ πύλη έλεγχε ότι
;;;; υπάρχει :implementations, ΟΧΙ ότι τα αρχεία υπάρχουν.
;;;; [re-review C-5] Το παλιό heuristic «μοιάζει αρχείο;» (prefix/επέκταση) ΠΕΘΑΝΕ:
;;;; υπο-εκτιμούσε (bare lessons.jsonl ξέφευγε) ΚΑΙ υπερ-εκτιμούσε (bare name ≠ path).
;;;; Τώρα η ταυτότητα αρχείου-έδρας ΔΗΛΩΝΕΤΑΙ τυπωμένα ως (:file "σχετικό/path") — δεν
;;;; μαντεύεται. Αυτός ο έλεγχος κλειδώνει: (α) κάθε (:file …) ΥΠΑΡΧΕΙ· (β) καμία bare
;;;; implementation δεν ΜΟΙΑΖΕΙ αρχείο (γνωστή επέκταση) χωρίς τύπο (:file …) — αλλιώς
;;;; θα ήταν σιωπηλά ανέλεγκτο αρχείο-έδρα. Self-contained μέσω της ΜΙΑΣ safe-read έδρας.

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

(defun %suffix-p (suf s) (and (>= (length s) (length suf))
                              (string= suf s :start2 (- (length s) (length suf)))))
(defparameter +file-exts+ '(".lisp" ".sexp" ".jsonl" ".json" ".md" ".txt" ".py"
                            ".mjs" ".sh" ".yaml" ".yml" ".pem" ".asd"))
(defun %file-decl-p (impl)
  "Τυπωμένη δήλωση αρχείου-έδρας: (:file \"σχετικό/path\")."
  (and (consp impl) (eq (first impl) :file) (stringp (second impl)) (null (cddr impl))))
(defun %store-decl-p (impl)
  "Τυπωμένη δήλωση RUNTIME store: (:store \"σχετικό/path\") — ΔΕΝ απαιτείται
   ύπαρξη στον δίσκο (καθαρό image = νόμιμα απόν)· απαιτείται ΕΣΩΤΕΡΙΚΗ
   ΣΥΝΕΠΕΙΑ: το path ΟΦΕΙΛΕΙ να είναι εγγεγραμμένο στο :canonical-stores."
  (and (consp impl) (eq (first impl) :store) (stringp (second impl)) (null (cddr impl))))
(defun %tokens (s)
  "Tokens του S σε whitespace, χωρίς εξάρτηση από uiop (bare sbcl --script)."
  (let ((toks '()) (start nil) (n (length s)))
    (dotimes (i n)
      (let ((ws (member (char s i) '(#\Space #\Tab #\Newline #\Return))))
        (cond ((and (not ws) (null start)) (setf start i))
              ((and ws start) (push (subseq s start i) toks) (setf start nil)))))
    (when start (push (subseq s start n) toks))
    (nreverse toks)))
(defun %looks-like-file (s)
  "Bare string με γνωστή file-extension σε κάποιο token (lint: πρέπει να είναι τυπωμένο)."
  (and (stringp s)
       (some (lambda (tok) (some (lambda (e) (%suffix-p e tok)) +file-exts+)) (%tokens s))))

(let* ((here (or *load-truename* *load-pathname*))
       (root (merge-pathnames "../" (make-pathname :directory (pathname-directory here))))
       (path (merge-pathnames "deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp" root)))
  (multiple-value-bind (form status) (read-data-file path)
    (check "Σύνταγμα διαβάζεται data-only (safe-read :ok)" (eq status :ok))
    ;; top: (:lawmax-architecture-constitution :key val … :justified-multiplicity (…))
    (let* ((plist (if (keywordp (first form)) (rest form) form))
           (just (getf plist :justified-multiplicity))
           ;; [OWNER-RUN 2ος γύρος] canonical store paths — για τον (:store …) cross-check
           (canonical-store-paths
             (loop for e in (getf plist :canonical-stores)
                   for p = (getf e :path) when (stringp p) collect p))
           (missing '()) (checked 0))
      (check "υπάρχει :justified-multiplicity" (consp just))
      (check "υπάρχει :canonical-stores (για τον store cross-check)"
             (consp canonical-store-paths))
      (let ((untyped '()) (stores-checked 0) (uncanonical '()))
        (dolist (entry just)
          (dolist (impl (getf entry :implementations))
            (cond
              ((%file-decl-p impl)
               (incf checked)
               (unless (probe-file (merge-pathnames (second impl) root))
                 (push (list (getf entry :area) (second impl)) missing)))
              ;; RUNTIME store: όχι probe-file (καθαρό image = νόμιμα απόν)·
              ;; ΕΣΩΤΕΡΙΚΗ ΣΥΝΕΠΕΙΑ: πρέπει να είναι canonical store.
              ((%store-decl-p impl)
               (incf stores-checked)
               (unless (member (second impl) canonical-store-paths :test #'string=)
                 (push (list (getf entry :area) (second impl)) uncanonical)))
              ;; bare string που ΜΟΙΑΖΕΙ αρχείο αλλά ΔΕΝ τυπώθηκε (:file/:store …) = παράβαση
              ((%looks-like-file impl)
               (push (list (getf entry :area) impl) untyped)))))
        (format t "  (ελέγχθηκαν ~D τυπωμένα (:file) + ~D (:store) σε ~D εγγραφές)~%"
                checked stores-checked (length just))
        (check "ΚΑΘΕ (:file …) implementation του Συντάγματος ΥΠΑΡΧΕΙ (καμία stale)"
               (null missing))
        (when missing (format t "  ΛΕΙΠΟΥΝ: ~{~A~^, ~}~%" missing))
        (check "ΚΑΘΕ (:store …) είναι εγγεγραμμένο στο :canonical-stores (εσωτερική συνέπεια)"
               (and (plusp stores-checked) (null uncanonical)))
        (when uncanonical (format t "  ΜΗ-CANONICAL STORES: ~{~A~^, ~}~%" uncanonical))
        (check "καμία bare implementation δεν μοιάζει αρχείο χωρίς τύπο (:file/:store …) (κανένα ανέλεγκτο)"
               (null untyped))
        (when untyped (format t "  ΑΤΥΠΑ ΑΡΧΕΙΑ-ΕΔΡΕΣ: ~{~A~^, ~}~%" untyped)))
      ;; NEG: ο ανιχνευτής όντως πιάνει ανύπαρκτο τυπωμένο αρχείο (όχι tautology)
      (check "NEG: (:file ανύπαρκτο) ⇒ ανιχνεύεται ως missing"
             (and (%file-decl-p '(:file "source/DEFINITELY-NOT-THERE.lisp"))
                  (not (probe-file (merge-pathnames "source/DEFINITELY-NOT-THERE.lisp" root)))))
      ;; NEG: bare package-name (χωρίς επέκταση) ΔΕΝ θεωρείται αρχείο
      (check "NEG: package-name implementation ΔΕΝ μοιάζει αρχείο"
             (not (%looks-like-file "orchestrator.proposals (Σ11 γνώση)")))
      ;; NEG: bare filename ΜΕ επέκταση (lessons.jsonl) ΘΑ πιαστεί ως untyped (το κενό C-5)
      (check "NEG: bare lessons.jsonl (χωρίς τύπο) ⇒ μοιάζει αρχείο ⇒ θα κοκκίνιζε"
             (%looks-like-file "lessons.jsonl"))
      ;; NEG: dialogue surface με «/» ΔΕΝ είναι αρχείο (δεν λήγει σε επέκταση)
      (check "NEG: dialogue surface --ask/--ρώτα ΔΕΝ μοιάζει αρχείο"
             (not (%looks-like-file "--ask/--ρώτα")))
      ;; NEG: (:store εκτός canonical) ⇒ ΘΑ πιανόταν (ο cross-check δεν είναι tautology)
      (check "NEG: (:store μη-canonical) ⇒ ανιχνεύσιμο"
             (and (%store-decl-p '(:store "deployment/state/NOT-A-CANONICAL-STORE.jsonl"))
                  (not (member "deployment/state/NOT-A-CANONICAL-STORE.jsonl"
                               (loop for e in (getf (if (keywordp (first form)) (rest form) form)
                                                    :canonical-stores)
                                     for p = (getf e :path) when (stringp p) collect p)
                               :test #'string=)))))))

(format t "~%architecture-multiplicity: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
