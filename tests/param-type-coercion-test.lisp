;;;; tests/param-type-coercion-test.lisp
;;;; ============================================================================
;;;; BIDIRECTIONAL PARAM-TYPE / COERCION GATE ([0094]/Phase 1, commit 2A · re-review B-7)
;;;; ============================================================================
;;;; Επιβάλλει ΑΜΦΙΔΡΟΜΗ (τώρα ΤΡΙΠΛΗ) ισότητα ανάμεσα στη ΔΗΛΩΜΕΝΗ γλώσσα και ΚΑΘΕ
;;;; υλοποίηση που την καταναλώνει — ΚΑΜΙΑ έδρα εκτός ελέγχου:
;;;;   [A] +param-types+          — η ΜΙΑ frozen defparameter (capability-registry.lisp)
;;;;   [B] %type-ok-p (ecase)     — runtime type-check branches (capability-registry.lisp)
;;;;   [C] %coerce-one (case)     — coercion branches (capability-api.lisp)
;;;; ΝΟΜΟΣ: [A] ≡ [B] ≡ [C]. Το re-review B-7 έδειξε ότι το παλιό gate έλεγχε ΜΟΝΟ [C]↔
;;;; δηλώσεις· το [B] ήταν ΕΚΤΟΣ — τύπος στο +param-types+ χωρίς κλάδο στο ecase %type-ok-p
;;;; ⇒ control-error στο runtime (500/crash), σιωπηλό drift. Τώρα κλειδώνονται και τα τρία.
;;;; Επιπλέον:
;;;;   (1) κάθε type σε literal :params ∈ το canonical set               (no unknown type)
;;;;   (4) :number ΑΠΩΝ από branches ΚΑΙ από κάθε param declaration      (νεκρό contract, 2A)
;;;; Στατικό/decidable (διαβάζει πηγή με τον reader, *read-eval* NIL· κανένα build).
;;;; Reintroduction οποιουδήποτε mismatch ΚΟΚΚΙΝΙΖΕΙ.

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

;; ── Robust extraction: αφήνουμε τον reader να κάνει paren-matching (όχι line-scan) ──
(defun %read-form-at (src marker)
  "Διαβάζει ΤΟ ΕΝΑ s-expression που ξεκινά στο MARKER μέσα στο SRC (ο reader κάνει το
   paren-matching· *read-eval* NIL). NIL αν το marker λείπει ή δεν διαβάζεται."
  (let ((start (and src (search marker src))))
    (when start
      (let ((*read-eval* nil))
        (ignore-errors (values (read-from-string src t nil :start start)))))))

(defun %case-keys (case-form)
  "Τα keys των clauses ενός (e)case form: (car clause) για κάθε clause στο (cddr),
   εκτ. του t default. Επιστρέφει set από keywords."
  (remove-duplicates
   (remove t (remove nil (mapcar (lambda (cl) (and (consp cl) (car cl)))
                                 (cddr case-form))))))

;; ── Εξαγωγή ΟΛΩΝ των literal param-type tuples (:name :TYPE …) από πηγή ──
(defun %declared-param-types (texts canonical+num)
  "Κάθε literal (:name :TYPE required?) σε :params list. Επιστρέφει set από :TYPE keywords.
   (Τα computed :params — mapcar/append/κλήσεις — ΔΕΝ δηλώνουν literal type, δηλώνεται
   ρητά ως στατικό όριο.)"
  (let ((types '()))
    (dolist (txt texts)
      (let ((i 0) (n (length txt)))
        (loop while (< i n) do
          (let ((p (search "(:" txt :start2 i)))
            (unless p (return))
            (let* ((k1 (position-if (lambda (c) (member c '(#\Space #\Tab #\)))) txt :start (+ p 2)))
                   (afterws (and k1 (position-if-not (lambda (c) (member c '(#\Space #\Tab))) txt :start k1))))
              (when (and afterws (< afterws n) (char= (char txt afterws) #\:))
                (let ((k2 (position-if (lambda (c) (member c '(#\Space #\Tab #\)))) txt :start (1+ afterws))))
                  (when k2
                    (let ((ty (ignore-errors (intern (string-upcase (subseq txt (1+ afterws) k2)) :keyword))))
                      (when (member ty canonical+num) (push ty types))))))
              (setf i (+ p 2)))))))
    (remove-duplicates types)))

(defun set= (a b) (null (set-exclusive-or a b)))

(let* ((here (or *load-truename* *load-pathname*))
       (root (merge-pathnames "../" (make-pathname :directory (pathname-directory here)))))

  ;; Το ΑΝΑΜΕΝΟΜΕΝΟ canonical set (witness). Ο πραγματικός νόμος είναι [A]≡[B]≡[C]
  ;; εξαγόμενα από πηγή· αυτό εδώ ΕΠΙΠΛΕΟΝ κλειδώνει ότι το set δεν άλλαξε σιωπηλά.
  (defparameter +canonical-param-types+ '(:string :keyword :any :integer :boolean))

  (let* ((cap-reg (%slurp (merge-pathnames "source/capability-registry.lisp" root)))
         (cap-api (%slurp (merge-pathnames "source/capability-api.lisp" root)))
         ;; [A] η frozen defparameter: (defparameter +param-types+ '(...) "doc")
         (pt-form (%read-form-at cap-reg "(defparameter +param-types+"))
         (param-types (let ((q (and (consp pt-form) (third pt-form))))   ; (quote (...)) → (...)
                        (if (and (consp q) (eq (car q) 'quote)) (second q) q)))
         ;; [B] runtime type-check ecase
         (type-ok-keys (%case-keys (%read-form-at cap-reg "(ecase ptype")))
         ;; [C] coercion case
         (coerce-keys  (%case-keys (%read-form-at cap-api "(case ptype")))
         (decl-texts (remove nil
                      (mapcar #'%slurp
                        (list (merge-pathnames "systems/orchestrator-cli/cockpit.lisp" root)
                              (merge-pathnames "systems/orchestrator-cli/decisions.lisp" root)
                              (merge-pathnames "source/capability-api.lisp" root)))))
         (declared (%declared-param-types decl-texts (cons :number +canonical-param-types+))))

    (format t "~%── TRI-DIRECTIONAL PARAM-TYPE GATE ([A]+param-types+ ≡ [B]%type-ok-p ≡ [C]%coerce-one) ──~%")
    (format t "  [A] +param-types+  = ~S~%  [B] %type-ok-p     = ~S~%  [C] %coerce-one    = ~S~%  declared(:params)  = ~S~%"
            param-types type-ok-keys coerce-keys declared)

    ;; ── Οι τρεις έδρες ΥΠΑΡΧΟΥΝ και εξήχθησαν (όχι κενές λόγω αλλαγμένου marker) ──
    (check "[A] +param-types+ εξήχθη μη-κενό" (consp param-types))
    (check "[B] %type-ok-p ecase branches εξήχθησαν μη-κενά" (consp type-ok-keys))
    (check "[C] %coerce-one case branches εξήχθησαν μη-κενά" (consp coerce-keys))

    ;; ── Ο ΝΟΜΟΣ: [A] ≡ [B] ≡ [C] (καμία έδρα εκτός συγχρονισμού) ──
    (check "[A]≡[B]: +param-types+ = %type-ok-p ecase branches (B-7: το ecase ΔΕΝ ξεσυγχρονίζεται)"
           (and param-types type-ok-keys (set= param-types type-ok-keys)))
    (check "[A]≡[C]: +param-types+ = %coerce-one case branches"
           (and param-types coerce-keys (set= param-types coerce-keys)))
    (check "[B]≡[C]: %type-ok-p = %coerce-one (πλήρης αμφίδρομη κάλυψη)"
           (set= type-ok-keys coerce-keys))
    (check "witness: το frozen canonical set δεν άλλαξε σιωπηλά ([A] = expected)"
           (and param-types (set= param-types +canonical-param-types+)))

    ;; ── δηλωμένοι τύποι + :number νεκρό ──
    (check "(1) κάθε δηλωμένος param-type ∈ canonical set (no unknown type)"
           (subsetp declared +canonical-param-types+))
    (check "(4a) :number ΑΠΩΝ από [C] coercion branches" (not (member :number coerce-keys)))
    (check "(4b) :number ΑΠΩΝ από [B] %type-ok-p branches" (not (member :number type-ok-keys)))
    (check "(4c) :number ΑΠΩΝ από [A] +param-types+" (not (member :number param-types)))
    (check "(4d) :number ΑΠΩΝ από κάθε literal param declaration" (not (member :number declared)))

    ;; ── NEGATIVE fixtures: ο έλεγχος ΚΟΚΚΙΝΙΖΕΙ σε drift ──
    (check "NEG: %case-keys εξάγει σωστά keys + αγνοεί t default"
           (set= '(:string :integer) (%case-keys '(case x (:string 1) (:integer 2) (t 9)))))
    (check "NEG: ecase χωρίς t — όλα τα keys κρατιούνται"
           (set= '(:a :b) (%case-keys '(ecase x (:a 1) (:b 2)))))
    (check "NEG: drift [A]≠[B] ανιχνεύεται (set-exclusive-or ≠ ∅)"
           (not (set= '(:string :integer) '(:string :integer :boolean))))
    (check "NEG: επανεισαγωγή :number ⇒ ανιχνεύεται"
           (not (subsetp '(:string :number) +canonical-param-types+)))
    (check "NEG: extractor πιάνει :number σε synthetic :params"
           (member :number (%declared-param-types '("(:params ((:score :number t)))")
                                                  (cons :number +canonical-param-types+)))))

  (format t "~%param-type-coercion-gate: ~D passed, ~D failed~%" *pass* *fail*)
  (sb-ext:exit :code (if (zerop *fail*) 0 1)))
