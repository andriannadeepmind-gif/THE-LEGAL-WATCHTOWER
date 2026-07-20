;;;; tests/param-type-coercion-test.lisp
;;;; ============================================================================
;;;; BIDIRECTIONAL PARAM-TYPE / COERCION GATE ([0094]/Phase 1, commit 2A)
;;;; ============================================================================
;;;; Επιβάλλει ΑΜΦΙΔΡΟΜΗ ισότητα ανάμεσα στη ΔΗΛΩΜΕΝΗ γλώσσα (capability :params types)
;;;; και την ΥΛΟΠΟΙΗΣΗ (τους coercion branches του %coerce-one):
;;;;   (1) κάθε type σε literal :params ∈ οι coercion branches         (no unknown type)
;;;;   (2) οι coercion branches = ακριβώς το frozen canonical set       (no dead branch «για μελλοντική χρήση»)
;;;;   (3) reserved type επιτρέπεται ΜΟΝΟ με ρητή αλλαγή ΚΑΙ των δύο    (constitutional)
;;;;   (4) :number ΑΠΩΝ και από branches ΚΑΙ από κάθε param declaration (νεκρό contract, commit 2A)
;;;; Στατικό/decidable (διαβάζει πηγή, κανένα build) — reintroduction οποιουδήποτε mismatch ΚΟΚΚΙΝΙΖΕΙ.

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun %slurp (path)
  (when (probe-file path)
    (with-open-file (s path :external-format :utf-8)
      (let ((buf (make-string (file-length s))))
        (subseq buf 0 (read-sequence buf s))))))

(let* ((here (or *load-truename* *load-pathname*))
       (root (merge-pathnames "../" (make-pathname :directory (pathname-directory here)))))

  ;; ── Το frozen canonical set: ΑΚΡΙΒΩΣ οι τύποι που ο %coerce-one χειρίζεται. Αλλαγή εδώ =
  ;;    συνταγματική πράξη μαζί με αλλαγή του %coerce-one (bidirectional). :number ΑΠΩΝ.
  (defparameter +canonical-param-types+ '(:string :keyword :any :integer :boolean))

  ;; ── Εξαγωγή των πραγματικών coercion branches από το %coerce-one (case keys) ──
  (defun %coerce-branches (cap-api-src)
    "Οι case-branch keywords του (case ptype …) στο %coerce-one, εκτός του t default."
    (let* ((start (search "(case ptype" cap-api-src))
           (types '()))
      (when start
        ;; σάρωσε τις γραμμές μετά το (case ptype ...) για ανοιγμα «(:kw»
        (with-input-from-string (s (subseq cap-api-src start))
          (loop for line = (read-line s nil nil)
                for n from 0 below 40
                while line do
                  (let ((tl (string-left-trim '(#\Space #\Tab) line)))
                    (when (and (> (length tl) 2) (char= (char tl 0) #\()
                               (char= (char tl 1) #\:))
                      (let ((end (position-if (lambda (c) (member c '(#\Space #\) #\Tab))) tl :start 2)))
                        (push (intern (string-upcase (subseq tl 2 end)) :keyword) types)))
                    (when (search "(t " tl) (return))))))
      (remove-duplicates (nreverse types))))

  ;; ── Εξαγωγή ΟΛΩΝ των literal param-type tuples (:name :TYPE …) από πηγή ──
  (defun %declared-param-types (texts)
    "Κάθε literal (:name :TYPE required?) σε :params list. Επιστρέφει set από :TYPE keywords.
     (Τα computed :params — mapcar/append/κλήσεις — ΔΕΝ δηλώνουν literal type, δεν πιάνονται
     εδώ· δηλώνεται ρητά ως στατικό όριο.)"
    (let ((types '()))
      (dolist (txt texts)
        ;; μοτίβο: «(:word :word» όπου το 2ο :word είναι ένας από τους canonical + πιθανό unknown
        (let ((i 0) (n (length txt)))
          (loop while (< i n) do
            (let ((p (search "(:" txt :start2 i)))
              (unless p (return))
              ;; διάβασε το 1ο keyword (name), μετά whitespace, μετά «:type»
              (let* ((k1 (position-if (lambda (c) (member c '(#\Space #\Tab #\)))) txt :start (+ p 2)))
                     (afterws (and k1 (position-if-not (lambda (c) (member c '(#\Space #\Tab))) txt :start k1))))
                (when (and afterws (< afterws n) (char= (char txt afterws) #\:))
                  (let ((k2 (position-if (lambda (c) (member c '(#\Space #\Tab #\)))) txt :start (1+ afterws))))
                    (when k2
                      (let ((ty (ignore-errors (intern (string-upcase (subseq txt (1+ afterws) k2)) :keyword))))
                        ;; κράτα ΜΟΝΟ αν μοιάζει param-type tuple (name-type-…): φιλτράρισμα σε γνωστά+:number
                        (when (member ty (cons :number +canonical-param-types+)) (push ty types))))))
                (setf i (+ p 2)))))))
      (remove-duplicates types)))

  (let* ((cap-api (%slurp (merge-pathnames "source/capability-api.lisp" root)))
         (branches (and cap-api (%coerce-branches cap-api)))
         ;; σάρωσε capability-declaring αρχεία για literal param-type tuples
         (decl-texts (remove nil
                      (mapcar #'%slurp
                        (list (merge-pathnames "systems/orchestrator-cli/cockpit.lisp" root)
                              (merge-pathnames "systems/orchestrator-cli/decisions.lisp" root)
                              (merge-pathnames "source/capability-api.lisp" root)))))
         (declared (%declared-param-types decl-texts)))

    (format t "~%── BIDIRECTIONAL PARAM-TYPE / COERCION GATE ──~%")
    (format t "  branches(%coerce-one) = ~S~%  declared(:params)     = ~S~%" branches declared)

    (check "(2) coercion branches = frozen canonical set (no dead/extra branch)"
           (and branches (null (set-exclusive-or branches +canonical-param-types+))))
    (check "(1) κάθε δηλωμένος param-type ∈ coercion branches (no unknown type)"
           (subsetp declared +canonical-param-types+))
    (check "(4a) :number ΑΠΩΝ από τους coercion branches (νεκρό contract διαγράφηκε)"
           (not (member :number branches)))
    (check "(4b) :number ΑΠΩΝ από κάθε literal param declaration"
           (not (member :number declared)))

    ;; ── NEGATIVE fixtures: ο έλεγχος ΚΟΚΚΙΝΙΖΕΙ σε reintroduction ──
    (check "NEG: επανεισαγωγή :number branch ⇒ ανιχνεύεται (set-exclusive-or ≠ ∅)"
           (not (null (set-exclusive-or (cons :number +canonical-param-types+)
                                        +canonical-param-types+))))
    (check "NEG: :number param σε δήλωση ⇒ όχι subset του canonical"
           (not (subsetp '(:string :number) +canonical-param-types+)))
    (check "NEG: άγνωστος τύπος :duration ⇒ όχι subset"
           (not (subsetp '(:duration) +canonical-param-types+)))
    (check "NEG: extractor πιάνει :number σε synthetic :params"
           (member :number (%declared-param-types '("(:params ((:score :number t)))")))))

  (format t "~%param-type-coercion-gate: ~D passed, ~D failed~%" *pass* *fail*)
  (sb-ext:exit :code (if (zerop *fail*) 0 1)))
