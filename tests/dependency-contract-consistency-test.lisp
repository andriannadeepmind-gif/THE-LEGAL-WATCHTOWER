;;;; tests/dependency-contract-consistency-test.lisp
;;;; ============================================================================
;;;; [audit#14] DEPENDENCY-CONTRACT.md ↔ deps.lock συνέπεια (καμία drift)
;;;; ============================================================================
;;;; Ο κριτής: το DEPENDENCY-CONTRACT.md δήλωνε το parse-declarations-1.0 «MISSING /
;;;; manual intervention» ενώ το deps.lock το είχε ΗΔΗ pinned. Doc-vs-lock drift.
;;;; Αυτός ο έλεγχος επιβάλλει μηχανικά ότι ΚΑΝΕΝΑ dependency της ενότητας «Missing
;;;; Dependencies» του contract ΔΕΝ υπάρχει στο deps.lock (αλλιώς αντίφαση ⇒ κόκκινο).
;;;; Self-contained (καθαρή text σάρωση), runnable χωρίς full build.

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %slurp (path)
  (with-open-file (s path :external-format :utf-8)
    (let ((buf (make-string (file-length s))))
      (subseq buf 0 (read-sequence buf s)))))

(defun %lines (text)
  (loop with start = 0 for nl = (position #\Newline text :start start)
        collect (subseq text start (or nl (length text)))
        while nl do (setf start (1+ nl))))

(defun %lock-names (lock-text)
  "Σύνολο dep-ονομάτων από deps.lock: 1ο token κάθε μη-# γραμμής (πριν | ή κενό)."
  (let ((names '()))
    (dolist (ln (%lines lock-text))
      (let ((trim (string-left-trim '(#\Space #\Tab) ln)))
        (when (and (plusp (length trim)) (char/= (char trim 0) #\#))
          (let* ((end (position-if (lambda (c) (member c '(#\Space #\Tab #\|))) trim))
                 (name (string-right-trim '(#\Space #\Tab) (subseq trim 0 end))))
            (when (plusp (length name)) (push name names))))))
    names))

(defun %backtick-tokens (section)
  "Ονόματα σε `backticks` μέσα σε ένα κομμάτι κειμένου."
  (let ((out '()) (i 0) (n (length section)))
    (loop while (< i n) do
      (let ((a (position #\` section :start i)))
        (unless a (return))
        (let ((b (position #\` section :start (1+ a))))
          (unless b (return))
          (push (subseq section (1+ a) b) out)
          (setf i (1+ b)))))
    out))

(defun %section (text header)
  "Το κείμενο από HEADER μέχρι το επόμενο markdown heading («## » ή «### »)."
  (let ((start (search header text)))
    (when start
      (let* ((body-start (+ start (length header)))
             (nxt (loop for h in '("### " "## ")
                        for p = (search (format nil "~%~A" h) text :start2 body-start)
                        when p minimize p into m finally (return (and (< m most-positive-fixnum) m)))))
        (subseq text body-start (or nxt (length text)))))))

(let* ((here (or *load-truename* *load-pathname*))
       (root (merge-pathnames "../" (make-pathname :directory (pathname-directory here))))
       (lock (%lock-names (%slurp (merge-pathnames "deps.lock" root))))
       (contract (%slurp (merge-pathnames "DEPENDENCY-CONTRACT.md" root)))
       (missing-sec (%section contract "### 4. Missing Dependencies")))
  (check "deps.lock διαβάζεται (μη κενό σύνολο)" (plusp (length lock)))
  (check "βρέθηκε η ενότητα «Missing Dependencies»" (and missing-sec t))
  (check "parse-declarations-1.0 ΟΝΤΩΣ στο deps.lock (πραγματικότητα)"
         (member "parse-declarations-1.0" lock :test #'string=))
  ;; Η ΚΥΡΙΑ επιβολή: κανένα «missing» dep του contract να μην υπάρχει στο lock.
  ;; ΜΟΝΟ table-rows (γραμμές που ξεκινούν με «|») ΔΗΛΩΝΟΥΝ missing dep — η επεξηγηματική
  ;; πρόζα (π.χ. «now vendored») ΔΕΝ είναι δήλωση (αλλιώς κάθε αναφορά resolved dep θα
  ;; έδινε ψευδή αντίφαση).
  (let* ((rows (remove-if-not
                (lambda (ln) (let ((tl (string-left-trim '(#\Space #\Tab) ln)))
                               (and (plusp (length tl)) (char= (char tl 0) #\|))))
                (%lines (or missing-sec ""))))
         (declared-missing (loop for r in rows
                                 for toks = (%backtick-tokens r)
                                 when toks collect (first toks)))
         (contradiction (remove-if-not (lambda (d) (member d lock :test #'string=))
                                       declared-missing)))
    (format t "  (missing-section tokens: ~S)~%" declared-missing)
    (check "καμία αντίφαση: «missing» dep που ΥΠΑΡΧΕΙ στο deps.lock"
           (null contradiction))
    (when contradiction (format t "  ΑΝΤΙΦΑΣΗ: ~{~A~^, ~}~%" contradiction)))
  ;; NEG: ο ανιχνευτής όντως πιάνει μια συνθετική αντίφαση
  (check "NEG: synthetic «missing» dep που είναι στο lock ⇒ ανιχνεύεται"
         (let ((synthetic (%backtick-tokens "bla `ironclad-v0.61` bla")))
           (and (member "ironclad-v0.61" synthetic :test #'string=)
                (member "ironclad-v0.61" lock :test #'string=)))))

(format t "~%dependency-contract-consistency: ~D passed, ~D failed~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
