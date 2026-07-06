;;;; source/legal-inference-engine.lisp
;;;; ============================================================================
;;;; LEGAL INFERENCE ENGINE — L1 of the reasoning brain (deterministic, provable)
;;;; ============================================================================
;;;;
;;;; The corpus KNOWS the text; this module makes it REASON about the text — and,
;;;; unlike a statistical model, every conclusion carries a machine-checkable PROOF of
;;;; how it was derived. Law is inherently DEFEASIBLE (a rule holds UNLESS an exception
;;;; applies — lex specialis derogat legi generali), so the engine is a NON-MONOTONIC
;;;; truth-maintenance system, not a monotone one. Common Lisp is the historical home
;;;; of symbolic AI, and this engine exploits it directly:
;;;;
;;;;   ✓ HOMOICONICITY — a proof is DATA (a nested s-expression), the same substrate
;;;;     as the rules. EXPLAIN returns the derivation as a value you can re-check.
;;;;   ✓ A macro DSL — DEFRULE declares legal meta-rules declaratively, with :WHEN
;;;;     (support) and :UNLESS (defeaters). The rule is documentation and logic at once.
;;;;   ✓ CLOS + MOP — each rule is a class under LEGAL-RULE, discovered via the MOP
;;;;     class graph (SB-MOP:CLASS-DIRECT-SUBCLASSES). A new rule = a subclass.
;;;;   ✓ A non-monotonic JTMS with WELL-FOUNDED SEMANTICS — each justification has an
;;;;     IN-list (must hold) and an OUT-list (defeaters that must NOT hold). Belief is
;;;;     the canonical well-founded model, computed by the VAN GELDER ALTERNATING
;;;;     FIXPOINT: deterministic, order-independent, always terminating, and correct
;;;;     even on paradoxical (odd) loops (which resolve to OUT rather than looping).
;;;;     This is the golden standard for negation-as-failure, and it is what makes
;;;;     defeasible legal reasoning — and lex specialis / lex posterior — expressible.
;;;;
;;;; The engine is PURE: it reasons over FACTS (lists like (:references "pk" "42"
;;;; "pk" "50")). Thin adapters lift the citation graph / hypergraph / ledger into
;;;; facts — no legal structure is re-implemented here.

(defpackage :orchestrator.inference
  (:use :cl)
  (:export
   ;; JTMS
   #:jtms #:make-jtms #:tms-node #:node-datum #:node-label #:node-believed-p
   #:node-premise-p #:tms-find #:tms-intern #:tms-premise #:tms-justify
   #:tms-retract-premise #:jtms-believed-facts #:recompute-beliefs
   #:fact-status #:jtms-undefined-facts
   ;; unification
   #:var-p #:unify #:instantiate
   ;; fact index + η ΜΙΑ υλοποίηση συζευκτικού ταιριάσματος
   #:fact-index #:fact-index-p #:make-fact-index #:facts-list #:facts-with-head
   #:match-patterns
   ;; rules / DSL
   #:legal-rule #:rule-name #:rule-when #:rule-unless #:rule-where #:rule-then
   #:rule-matches #:all-legal-rules #:defrule
   ;; engine
   #:inference-engine #:make-inference-engine #:engine-jtms
   #:add-fact #:add-facts #:run-inference #:query #:explain #:explanation->string
   #:affected-by #:broken-references))

(in-package :orchestrator.inference)

;;; ============================================================================
;;; UNIFICATION — patterns with ?vars against ground fact tuples
;;; ============================================================================

(declaim (inline var-p))
(defun var-p (x)
  "A logic variable: a non-keyword symbol whose name starts with #\\? (e.g. ?code)."
  (and (symbolp x) (not (keywordp x))
       (let ((n (symbol-name x)))
         (and (plusp (length n)) (char= (char n 0) #\?)))))

(defun %unify-1 (p f bindings)
  (cond ((var-p p)
         (let ((cell (assoc p bindings :test #'eq)))
           (cond ((null cell) (acons p f bindings))
                 ((equal (cdr cell) f) bindings)
                 (t :fail))))
        ;; ΦΩΛΙΑΣΜΕΝΑ tuples (πχ το δεοντικό datum (:deontic Μ (:πράξη ?δ …) :by Ν)):
        ;; ενοποίηση ΑΝΑΔΡΟΜΙΚΑ, όχι σύγκριση equal — αλλιώς μεταβλητή μέσα σε
        ;; υπολίστα δεν ταιριάζει ποτέ. Ίδια κατεύθυνση: vars μόνο στο pattern.
        ((and (consp p) (consp f)) (unify p f bindings))
        ((equal p f) bindings)
        (t :fail)))

(defun unify (pattern fact &optional (bindings '()))
  "Unify PATTERN (may contain ?vars) with ground FACT, both proper lists; return the
   binding alist or :FAIL. Different lengths never unify."
  (loop
    (cond ((and (null pattern) (null fact)) (return bindings))
          ((or (null pattern) (null fact)) (return :fail))
          (t (let ((b (%unify-1 (car pattern) (car fact) bindings)))
               (when (eq b :fail) (return :fail))
               (setf bindings b pattern (cdr pattern) fact (cdr fact)))))))

(defun instantiate (template bindings)
  "Replace every ?var in TEMPLATE by its binding, ΣΕ ΚΑΘΕ ΒΑΘΟΣ (κατοπτρικό
   του αναδρομικού unify — η επιθεώρηση βρήκε ότι το ρηχό mapcar άφηνε
   φωλιασμένα ?vars αδέσμευτα μέσα στα παραγόμενα δεδομένα). Unbound vars as-is."
  (cond ((var-p template)
         (let ((cell (assoc template bindings :test #'eq)))
           (if cell (cdr cell) template)))
        ((consp template)
         (mapcar (lambda (x) (instantiate x bindings)) template))
        (t template)))

;;; ============================================================================
;;; FACT INDEX — ευρετήριο κατά κατηγόρημα (Φάση 2: τέλος στις πλήρεις σαρώσεις)
;;; ============================================================================
;;;
;;; Κάθε fact είναι λίστα με ΚΕΦΑΛΗ keyword ((:references …), (:changed …)).
;;; Το ταίριασμα ενός pattern δεν χρειάζεται ποτέ facts άλλης κεφαλής — άρα η
;;; ανάκτηση γίνεται από κάδο ανά κεφαλή, όχι από σάρωση όλης της γνώσης.
;;; Η σειρά ΜΕΣΑ στον κάδο δεν είναι μέρος του συμβολαίου (η σημασιολογία του
;;; well-founded μοντέλου είναι ούτως ή άλλως ανεξάρτητη σειράς).

(defstruct (fact-index (:constructor %make-fact-index))
  (by-head (make-hash-table :test 'equal))   ; κεφαλή → (πλήθος . λίστα facts)
  (by-arg  (make-hash-table :test 'equal))   ; (κεφαλή θέση τιμή) → (πλήθος . λίστα)
  (all '()))                                 ; όλα τα facts

(defun %fact-head (f) (if (consp f) (car f) f))

(defun index-add (idx fact)
  "Πρόσθεσε ΕΝΑ fact στο ευρετήριο — Ο(μήκος fact): κάδος κεφαλής + ένας κάδος
   διάκρισης ανά (κεφαλή, θέση, τιμή) για κάθε όρισμά του."
  (flet ((add (table key)
           (let ((cell (gethash key table)))
             (if cell
                 (setf (car cell) (1+ (car cell)) (cdr cell) (cons fact (cdr cell)))
                 (setf (gethash key table) (cons 1 (list fact)))))))
    (let ((head (%fact-head fact)))
      (add (fact-index-by-head idx) head)
      (when (consp fact)
        (loop for arg in (cdr fact) for i from 1
              do (add (fact-index-by-arg idx) (list head i arg))))))
  (push fact (fact-index-all idx))
  fact)

(defun make-fact-index (facts)
  "Χτίσε ευρετήριο από λίστα FACTS — Ο(ΣF·μήκος)."
  (let ((idx (%make-fact-index)))
    (dolist (f facts idx) (index-add idx f))))

(defun facts-list (idx) (fact-index-all idx))

(defun facts-with-head (idx head)
  (cdr (gethash head (fact-index-by-head idx))))

(defun %candidates (idx pattern binding)
  "Οι υποψήφιοι του PATTERN υπό το BINDING: από τον ΜΙΚΡΟΤΕΡΟ διαθέσιμο κάδο —
   της κεφαλής, ή όποιας (κεφαλή, θέση, δεσμευμένη-τιμή) διάκρισης είναι πιο
   επιλεκτική. Έτσι το join δεν σαρώνει ποτέ κάδο-γίγαντα όταν έστω ένα όρισμα
   είναι ήδη γνωστό (η ουσία της κλιμάκωσης του ημι-αφελούς matching)."
  (let ((head (%fact-head pattern)))
    (if (not (keywordp head))
        (facts-list idx)                     ; κεφαλή-μεταβλητή: όλα
        (let* ((best (gethash head (fact-index-by-head idx))))
          (cond
            ((null best) '())                ; κανένα fact αυτής της κεφαλής
            (t (labels ((ground-p (x)
                          ;; ΠΛΗΡΩΣ γειωμένο όρισμα — υπολίστα με ?var ΔΕΝ είναι
                          ;; κλειδί διάκρισης (η επιθεώρηση βρήκε σιωπηλή
                          ;; υπο-συναγωγή σε φωλιασμένα patterns του L5)
                          (cond ((var-p x) nil)
                                ((consp x) (and (ground-p (car x))
                                                (ground-p (cdr x))))
                                (t t))))
                 (loop for arg in (cdr pattern) for i from 1
                       for val = (if (var-p arg)
                                     (let ((cell (assoc arg binding :test #'eq)))
                                       (if cell (cdr cell) arg))
                                     arg)
                       when (ground-p val)
                         do (let ((b (gethash (list head i val) (fact-index-by-arg idx))))
                              (cond ((null b) (return-from %candidates '()))
                                    ((< (car b) (car best)) (setf best b))))))
               (cdr best)))))))

(defun %join (patterns candidates-of)
  "Συζευκτικό join: για κάθε pattern με τη σειρά, επέκτεινε κάθε μερικό binding
   με κάθε υποψήφιο fact που ενοποιείται. CANDIDATES-OF: (θέση pattern binding)
   → λίστα υποψηφίων (ανά ΚΑΤΑΣΤΑΣΗ — οι δεσμεύσεις της κάνουν τη διάκριση
   επιλεκτική). Επιστρέφει λίστα καταστάσεων (binding . used-facts-ανάποδα)."
  (let ((states (list (cons '() '()))))
    (loop for pat in patterns for i from 0 while states do
      (setf states
            (loop for (b . used) in states
                  nconc (loop for f in (funcall candidates-of i pat b)
                              for nb = (unify pat f b)
                              unless (eq nb :fail)
                              collect (cons nb (cons f used))))))
    states))

(defun match-patterns (patterns facts)
  "Η ΜΙΑ υλοποίηση συζευκτικού ταιριάσματος του συστήματος (τη χρησιμοποιούν οι
   κανόνες του DSL ΚΑΙ ο L5): όλα τα (binding . used-facts) που ικανοποιούν τη
   σύζευξη PATTERNS πάνω στα FACTS (λίστα ή fact-index). Τα used-facts είναι σε
   ΑΝΤΙΣΤΡΟΦΗ σειρά των patterns."
  (let ((idx (if (fact-index-p facts) facts (make-fact-index facts))))
    (%join patterns (lambda (i pat b) (declare (ignore i)) (%candidates idx pat b)))))

;;; ============================================================================
;;; JTMS — non-monotonic nodes + justifications with IN-list and OUT-list
;;; ============================================================================

(defstruct (justification
            (:constructor make-justification (informant consequent in-list out-list)))
  (informant nil)     ; the rule (symbol) that produced this derivation
  (consequent nil)    ; the tms-node it supports
  (in-list nil)       ; nodes that must be :in  (support)
  (out-list nil))     ; nodes that must be :out (defeaters — negation as failure)

(defclass tms-node ()
  ((datum          :initarg :datum :reader node-datum)
   (label          :initform :out  :accessor node-label)      ; :in / :out
   (premise        :initform nil   :accessor node-premise-p)
   (support        :initform nil   :accessor node-support)     ; just / :premise / nil
   (justifications :initform nil   :accessor node-justifications)
   ;; Φάση 2: αντίστροφο ευρετήριο — σε ποιες αιτιολογήσεις συμμετέχει ως
   ;; προϋπόθεση (in-list). Το %derive διαδίδει σε γραμμικό χρόνο αντί να
   ;; ξανασαρώνει όλους τους κόμβους σε κάθε πέρασμα.
   (feeds          :initform nil   :accessor node-feeds)
   ;; υπογραφές αιτιολογήσεων (hash) — το dedup που ανιχνεύει το fixpoint
   ;; γίνεται Ο(1), όχι γραμμική σάρωση με φρέσκο consing ανά έλεγχο
   (just-sigs      :initform nil   :accessor node-just-sigs))
  (:documentation "A belief node: a legal fact plus the justifications supporting it."))

(defun node-believed-p (n) (eq (node-label n) :in))

(defmethod print-object ((n tms-node) s)
  (print-unreadable-object (n s :type t)
    (format s "~A ~S" (node-label n) (node-datum n))))

(defclass jtms ()
  ((index :initform (make-hash-table :test 'equal) :reader jtms-index) ; datum -> node
   (nodes :initform nil :accessor jtms-nodes)
   ;; Φάση 2: όλες οι αιτιολογήσεις σε μία λίστα — το %derive αρχικοποιεί τους
   ;; μετρητές του σε Ο(ΣJ) χωρίς να διασχίζει κόμβο-κόμβο
   (justs :initform nil :accessor jtms-justs)))

(defun make-jtms () (make-instance 'jtms))
(defun tms-find (jtms datum) (gethash datum (jtms-index jtms)))

(defun tms-intern (jtms datum)
  "The node for DATUM, creating it (initially :out) if new."
  (or (gethash datum (jtms-index jtms))
      (let ((n (make-instance 'tms-node :datum datum)))
        (setf (gethash datum (jtms-index jtms)) n)
        (push n (jtms-nodes jtms))
        n)))

(defun tms-premise (jtms datum)
  "Assert DATUM as a premise (an externally-given fact, unconditionally believed)."
  (let ((n (tms-intern jtms datum)))
    (setf (node-premise-p n) t)
    n))

(defun tms-justify (jtms consequent-datum in-nodes out-nodes informant)
  "Record that INFORMANT derives CONSEQUENT-DATUM from IN-NODES (must be :in) with
   OUT-NODES as defeaters (must be :out). Returns T iff this adds a NEW justification
   (idempotent on identical ones) — the engine uses that to detect a fixpoint.
   Ο(1) dedup: υπογραφή (informant, in-datums, out-datums) σε hash ανά κόμβο."
  (let* ((c (tms-intern jtms consequent-datum))
         (sig (list informant
                    (mapcar #'node-datum in-nodes)
                    (mapcar #'node-datum out-nodes)))
         (sigs (or (node-just-sigs c)
                   (setf (node-just-sigs c) (make-hash-table :test 'equal)))))
    (cond ((gethash sig sigs) nil)
          (t (setf (gethash sig sigs) t)
             (let ((j (make-justification informant c in-nodes out-nodes)))
               (push j (node-justifications c))
               (push j (jtms-justs jtms))
               ;; αντίστροφο ευρετήριο για τη γραμμική διάδοση του %derive —
               ;; dedup ΜΟΝΟ των in-nodes ΑΥΤΗΣ της αιτιολόγησης (το j είναι
               ;; φρέσκο: δεν υπάρχει σε κανένα feeds· ένα pushnew πάνω σε
               ;; κόμβο-κόμβο θα σάρωνε γραμμικά τα feeds του — τετραγωνικό
               ;; στους κόμβους-κόμβους με χιλιάδες αιτιολογήσεις)
               (dolist (a (remove-duplicates in-nodes :test #'eq))
                 (push j (node-feeds a))))
             t))))

;;; ---------------------------------------------------------------------------
;;; WELL-FOUNDED SEMANTICS via the Van Gelder alternating fixpoint
;;; ---------------------------------------------------------------------------
;;;
;;; A(S) = the least set of nodes derivable when every node NOT in S is taken to be
;;; :out (optimistic wrt negation). A is antimonotone in S. The alternating sequence
;;;   K0 = ∅ ;  U_i = A(K_i) ;  K_{i+1} = A(U_i)
;;; is increasing in K, decreasing in U, and converges (finite lattice). K∞ is exactly
;;; the well-founded TRUE set; nodes outside it (false OR undefined) are :out. This is
;;; deterministic and always terminates — no order dependence, no infinite loops.

(defun %derive (jtms assumed-true)
  "A(ASSUMED-TRUE): least set of nodes derivable treating any node NOT in ASSUMED-TRUE
   as :out. ASSUMED-TRUE and the result are EQ hash-sets of tms-node. Premises are
   always derivable.
   Φάση 2 — ΓΡΑΜΜΙΚΗ διάδοση (worklist με μετρητές, κατά Doyle/Goodwin) αντί
   επαναληπτικών σαρώσεων όλων των κόμβων: κάθε αιτιολόγηση παίρνει μετρητή
   ανεκπλήρωτων προϋποθέσεων· όταν ένας κόμβος συναχθεί, μειώνει τους μετρητές
   των αιτιολογήσεων που τροφοδοτεί (node-feeds)· μετρητής 0 ⇒ συνάγεται ο
   συνεπαγόμενος. Ο(Ν + Σ|in-lists|) αντί Ο(Ν²·J)."
  (let ((d (make-hash-table :test 'eq))
        (counts (make-hash-table :test 'eq))
        (queue '()))
    (flet ((derive (n)
             (unless (gethash n d)
               (setf (gethash n d) t)
               (push n queue))))
      ;; σπόρος 1: τα δεδομένα (premises)
      (dolist (n (jtms-nodes jtms))
        (when (node-premise-p n) (derive n)))
      ;; σπόρος 2: μετρητές — μόνο για αιτιολογήσεις που ΔΕΝ μπλοκάρονται από
      ;; defeater του ASSUMED-TRUE· κενή in-list ⇒ άμεση συναγωγή
      (dolist (j (jtms-justs jtms))
        (when (notany (lambda (a) (gethash a assumed-true))
                      (justification-out-list j))
          (let ((c (length (remove-duplicates (justification-in-list j) :test #'eq))))
            (setf (gethash j counts) c)
            (when (zerop c) (derive (justification-consequent j))))))
      ;; διάδοση
      (loop while queue do
        (let ((n (pop queue)))
          (dolist (j (node-feeds n))
            (let ((c (gethash j counts)))
              (when (and c (zerop (decf (gethash j counts))))
                (derive (justification-consequent j))))))))
    d))

(defun %same-set (a b)
  (and (= (hash-table-count a) (hash-table-count b))
       (loop for k being the hash-keys of a always (gethash k b))))

(defun %valid-justification (n)
  "A justification of N whose in-list are all :in and out-list all :out — the current
   well-founded support (for EXPLAIN); NIL if none."
  (find-if (lambda (j)
             (and (every (lambda (a) (eq (node-label a) :in)) (justification-in-list j))
                  (every (lambda (a) (eq (node-label a) :out)) (justification-out-list j))))
           (node-justifications n)))

(defun recompute-beliefs (jtms)
  "Label every node :in/:out as the canonical WELL-FOUNDED model (alternating
   fixpoint). Deterministic and terminating. Retraction/assertion just calls this."
  (let ((k (make-hash-table :test 'eq)))          ; K0 = ∅
    (loop
      (let* ((u  (%derive jtms k))                ; optimistic
             (k2 (%derive jtms u)))               ; pessimistic
        (if (%same-set k2 k)
            (progn
              (dolist (n (jtms-nodes jtms))
                (setf (node-label n) (if (gethash n k2) :in :out)))
              (dolist (n (jtms-nodes jtms))
                (setf (node-support n)
                      (cond ((node-premise-p n) :premise)
                            ((eq (node-label n) :in) (%valid-justification n))
                            (t nil))))
              (return jtms))
            (setf k k2))))))

(defun %undefined-set (jtms)
  "Το ΑΝΑΠΟΦΑΣΙΣΤΟ τμήμα του well-founded μοντέλου: U∞ = A(K∞) — ό,τι είναι
   αισιόδοξα παραγώγιμο πάνω από τα βέβαια αλλά ΔΕΝ είναι βέβαιο. Στη νομική
   ανάγνωση (Σ5): η ισοπαλία επιχειρημάτων, δηλωμένη — ποτέ κρυμμένη ως «όχι»."
  (let ((k (make-hash-table :test 'eq)))
    (dolist (n (jtms-nodes jtms))
      (when (node-believed-p n) (setf (gethash n k) t)))
    (let ((u (%derive jtms k)) (out '()))
      (dolist (n (jtms-nodes jtms) out)
        (when (and (gethash n u) (not (node-believed-p n)))
          (push n out))))))

(defun jtms-undefined-facts (jtms)
  "Τα ΑΝΑΠΟΦΑΣΙΣΤΑ γεγονότα (τρίτη τιμή του well-founded μοντέλου)."
  (mapcar #'node-datum (%undefined-set jtms)))

(defun fact-status (jtms datum)
  "Η ΤΡΙΤΙΜΗ κατάσταση του DATUM: :in (αποδεδειγμένο) / :undefined (αναποφάσιστο
   — ισοπαλία επιχειρημάτων) / :out (δεν στηρίζεται) / :unknown (δεν υπάρχει καν
   ως κόμβος). Προϋπόθεση: έχει προηγηθεί recompute-beliefs."
  (let ((n (tms-find jtms datum)))
    (cond ((null n) :unknown)
          ((node-believed-p n) :in)
          ((member n (%undefined-set jtms) :test #'eq) :undefined)
          (t :out))))

(defun tms-retract-premise (jtms datum)
  "Withdraw DATUM as a premise and recompute — everything resting (transitively) on it
   drops out; anything a defeater blocked may now come in."
  (let ((n (tms-find jtms datum)))
    (when n (setf (node-premise-p n) nil))
    (recompute-beliefs jtms)))

(defun jtms-believed-facts (jtms)
  (loop for n in (jtms-nodes jtms) when (node-believed-p n) collect (node-datum n)))

;;; ============================================================================
;;; PROOF — the derivation of a fact, AS DATA (homoiconic)
;;; ============================================================================

(defun explain (jtms datum)
  "Return the derivation of DATUM as a nested s-expression:
     (:premise DATUM)
     (:derived DATUM :by RULE :from (SUBPROOF …) :unless-absent (DEFEATER-DATUM …))
     (:unsupported DATUM)
   :unless-absent lists the defeaters that were required to be OUT and correctly are —
   the defeasible part of the argument, shown explicitly.
   Cyclic support (A justified via B, B via A — legal in a well-founded JTMS
   when both rest on premises through another path) terminates as
   (:cycle DATUM): the datum was already shown higher in this same derivation,
   so the branch is cut instead of recursing forever."
  (labels ((walk (datum seen)
             (let ((n (tms-find jtms datum)))
               (cond ((or (null n) (not (node-believed-p n))) (list :unsupported datum))
                     ((node-premise-p n) (list :premise datum))
                     ((member n seen) (list :cycle datum))
                     (t (let ((j (%valid-justification n))
                              (seen* (cons n seen)))
                          (if j
                              (list :derived datum :by (justification-informant j)
                                    :from (mapcar (lambda (a) (walk (node-datum a) seen*))
                                                  (justification-in-list j))
                                    :unless-absent (mapcar #'node-datum (justification-out-list j)))
                              (list :unsupported datum))))))))
    (walk datum '())))

(defun explanation->string (proof &optional (indent 0))
  "Pretty-print a PROOF tree (from EXPLAIN) as an indented derivation."
  (with-output-to-string (s)
    (labels ((pad (k) (make-string (* 2 k) :initial-element #\Space))
             (walk (p k)
               (case (car p)
                 (:premise (format s "~A• [δεδομένο] ~S~%" (pad k) (second p)))
                 (:derived
                  (format s "~A• ~S~%~A    ⇐ κανόνας ~A~%" (pad k) (second p)
                          (pad k) (getf (cddr p) :by))
                  (dolist (d (getf (cddr p) :unless-absent))
                    (format s "~A    ∤ εφόσον ΔΕΝ ισχύει ~S~%" (pad k) d))
                  (dolist (sub (getf (cddr p) :from)) (walk sub (1+ k))))
                 (:cycle (format s "~A• [↺ ήδη αποδεδειγμένο παραπάνω] ~S~%" (pad k) (second p)))
                 (t (format s "~A• [ΑΤΕΚΜΗΡΙΩΤΟ] ~S~%" (pad k) (second p))))))
      (walk proof indent))))

;;; ============================================================================
;;; RULES — a CLOS class per rule, discovered via the MOP class graph
;;; ============================================================================

(defclass legal-rule ()
  ((name   :initarg :name   :reader rule-name   :initform 'anonymous)
   (when   :initarg :when   :reader rule-when   :initform nil)   ; support patterns
   (unless :initarg :unless :reader rule-unless :initform nil)   ; defeater patterns
   (where  :initarg :where  :reader rule-where  :initform nil)   ; αριθμ./χρον. φραγμοί
   (then   :initarg :then   :reader rule-then   :initform nil))  ; consequent template
  (:documentation "A defeasible production rule: when ALL :when patterns jointly match
   under one binding, ALL :where guards evaluate true under that binding, AND no
   instantiated :unless pattern holds, the :then template is asserted, justified by the
   matched support facts (plus the computed guards) with the :unless facts as defeaters."))

(defun %pattern-vars (form)
  "Όλες οι ?μεταβλητές μιας μορφής, σε κάθε βάθος."
  (cond ((var-p form) (list form))
        ((consp form) (mapcan #'%pattern-vars (copy-list form)))
        (t '())))

(defmethod initialize-instance :after ((r legal-rule) &key)
  "ΣΤΑΤΙΚΗ ΝΟΜΙΜΟΤΗΤΑ ΚΑΝΟΝΑ στη δημιουργία του — όχι στο ατύχημα (ευρήματα
   επιθεώρησης 05-07-2026): (α) ασφάλεια εμβέλειας: κάθε ?μεταβλητή των
   :unless/:where/:then δεσμεύεται από τα :when (αλλιώς ο defeater αδρανεί
   σιωπηλά ⇒ υπερ-συναγωγή)· (β) κάθε :where φραγμός τυπώνεται στατικά και
   είναι :bool (μη-bool φραγμός θα ήταν πάντα «αληθής»). Παράβαση ⇒ σφάλμα
   ΤΩΡΑ — ο κανόνας δεν υπάρχει ποτέ λάθος."
  (let ((when-vars (%pattern-vars (rule-when r))))
    (dolist (part (list (cons :unless (rule-unless r))
                        (cons :where (rule-where r))
                        (cons :then (list (rule-then r)))))
      (dolist (v (%pattern-vars (cdr part)))
        (unless (member v when-vars :test #'eq)
          (error "κανόνας ~A: η ~S στο ~A δεν δεσμεύεται από τα :when — μη ασφαλής κανόνας"
                 (rule-name r) v (car part)))))
    (dolist (g (rule-where r))
      (orchestrator.metaeval:infer-guard-type g when-vars))))

(defmacro defrule (name &key when unless where then)
  "Define a legal inference rule as a LEGAL-RULE subclass (auto-discovered via the MOP
   class graph). :WHEN — support patterns (with ?vars). :UNLESS — defeater patterns
   (safe: their vars must be bound by :when). :WHERE — αριθμητικοί/χρονικοί φραγμοί
   (safe Datalog built-ins) αποτιμώμενοι ΜΕΤΑ τη δέσμευση των μεταβλητών· κάθε
   φραγμός γράφεται ΚΑΙ στην απόδειξη ως υπολογισμός. :THEN — the consequent template.

     (defrule prothesmia-eforos
       :when  ((:επιδόθηκε ?πράξη ?d0) (:κατατέθηκε ?πράξη ?d1))
       :where ((within-days ?d0 ?d1 30))
       :then  (:εμπρόθεσμο ?πράξη))"
  `(progn
     (defclass ,name (legal-rule) ()
       (:default-initargs :name ',name :when ',when :unless ',unless
                          :where ',where :then ',then))
     ',name))

;;; ── :WHERE guards — Ο ΜΕΤΑΚΥΚΛΙΚΟΣ ΑΠΟΤΙΜΗΤΗΣ (orchestrator.metaeval) ──
;;; Η ΜΙΑ υλοποίηση αποτίμησης φραγμών ζει στο source/guard-metaeval.lisp:
;;; ελάχιστος πυρήνας εμπιστοσύνης + πύργος ορισμών ΣΤΗ γλώσσα (στρωμάτωση ⇒
;;; τερματισμός) + πλήρες ίχνος αναγωγών μέσα στην απόδειξη + επέκταση ως
;;; γνώση (:guard-ops πακέτα). Εδώ μόνο η κλήση — καμία δεύτερη υλοποίηση.

(defun all-legal-rules ()
  "Instantiate every concrete LEGAL-RULE subclass, discovered from the MOP class graph."
  (labels ((leaves (class)
             (let ((subs (sb-mop:class-direct-subclasses class)))
               (if subs (mapcan #'leaves subs) (list class)))))
    (mapcar #'make-instance
            (remove-duplicates (leaves (find-class 'legal-rule))))))

(defun %rule-matches-states (rule states)
  "Μετέτρεψε καταστάσεις join σε (CONSEQUENT IN-FACTS OUT-DATUMS). Οι :where
   φραγμοί αποτιμώνται από τον ΜΕΤΑΚΥΚΛΙΚΟ αποτιμητή: δεσμεύσεις που δεν τους
   ικανοποιούν φιλτράρονται· κάθε φραγμός που περνά μπαίνει στα IN-FACTS ως
   (:υπολογισμός <φραγμός-με-τιμές> := τιμή :ίχνος <ΠΛΗΡΗΣ πύργος αναγωγών>) —
   η απόδειξη δείχνει τον αριθμητικό/χρονικό λόγο μέχρι το τελευταίο βήμα."
  (let ((guards (rule-where rule)))
    (loop for (b . used) in states
          append (multiple-value-bind (ok computed)
                     (orchestrator.metaeval:guards-pass-p guards b)
                   (when ok
                     (list (list (instantiate (rule-then rule) b)
                                 (append computed (reverse used))
                                 (mapcar (lambda (pat) (instantiate pat b))
                                         (rule-unless rule)))))))))

(defgeneric rule-matches (rule facts)
  (:documentation "Return a list of (CONSEQUENT-DATUM IN-FACTS OUT-DATUMS) — one per
   way RULE's :when patterns jointly match FACTS. FACTS is a FACT-INDEX (or a plain
   list, which is indexed on entry — see MAKE-FACT-INDEX / FACTS-LIST /
   FACTS-WITH-HEAD for specialised methods). IN-FACTS are the matched support
   data; OUT-DATUMS are the :unless patterns instantiated under the same binding (the
   defeaters). Specialise for rules needing richer logic.")
  (:method ((rule legal-rule) facts)
    (%rule-matches-states rule (match-patterns (rule-when rule) facts))))

(defun %default-matcher ()
  "Η προεπιλεγμένη μέθοδος ταιριάσματος — βρίσκεται τη ΣΤΙΓΜΗ της κλήσης (όχι
   κρυσταλλωμένη στο load): επανα-αποτίμηση του defgeneric στο REPL δεν αφήνει
   ποτέ μπαγιάτικο αντικείμενο-μέθοδο να ταξινομεί σιωπηλά τους πάντες «slow»."
  (find-method #'rule-matches '() (list (find-class 'legal-rule) (find-class t)) nil))

(defun %custom-matcher-p (rule)
  "Έχει η κλάση του RULE ΔΙΚΗ της rule-matches; Τότε ο engine την καλεί αυτούσια
   σε κάθε γύρο (ορθότητα του open/closed) αντί του ημι-αφελούς μονοπατιού.
   Ανιχνεύεται ΚΑΙ με ευρετήριο ΚΑΙ με λίστα ως δεύτερο όρισμα — εξειδίκευση
   γραμμένη για (facts list)/(facts cons) δεν παρακάμπτεται σιωπηλά."
  (let ((dm (%default-matcher)))
    (flet ((custom-for (arg)
             (let ((ms (compute-applicable-methods #'rule-matches (list rule arg))))
               (and ms (not (eq (first ms) dm))))))
      (or (null dm)                          ; χωρίς default ⇒ όλα εξειδικεύσεις
          (custom-for (%make-fact-index))
          (custom-for (list '(:probe)))))))

(defun %match-rule-delta (rule base-idx delta-idx)
  "Ημι-αφελές ταίριασμα (Φάση 2): μόνο οι συνδυασμοί που χρησιμοποιούν ≥1 fact
   του ΔΕΛΤΑ (νέα γνώση αυτού του γύρου). Διαμέριση κατά pivot — η ΠΡΩΤΗ θέση
   που παίρνει fact από το δέλτα: πριν από αυτήν μόνο ΠΑΛΑΙΑ facts, μετά από
   αυτήν παλαιά+νέα. Κάθε νέος συνδυασμός παράγεται ΑΚΡΙΒΩΣ μία φορά· ό,τι
   αποτελείται μόνο από παλαιά facts έχει ήδη ταιριαστεί σε προηγούμενο γύρο."
  (let* ((pats (rule-when rule)) (n (length pats)))
    (loop for pivot from 0 below n
          ;; προέλεγχος: αν το δέλτα δεν έχει ΚΑΝΕΝΑ fact της κεφαλής του pivot,
          ;; το pivot δεν αποδίδει τίποτα — μην πληρώσεις το join των πριν από
          ;; αυτό θέσεων (αλλιώς: Ο(βάση) ανά γύρο, η διαρροή του ημι-αφελούς)
          unless (null (%candidates delta-idx (nth pivot pats) '()))
          nconc (%rule-matches-states
                 rule
                 (%join pats
                        (lambda (i pat b)
                          (cond ((< i pivot) (%candidates base-idx pat b))
                                ((= i pivot) (%candidates delta-idx pat b))
                                (t (append (%candidates base-idx pat b)
                                           (%candidates delta-idx pat b))))))))))

;;; ============================================================================
;;; ENGINE — forward-chain rules to a fixpoint over the well-founded JTMS
;;; ============================================================================

(defclass inference-engine ()
  ((jtms :initform (make-jtms) :reader engine-jtms)
   ;; Φάση 2: η ΓΕΙΩΣΗ είναι ΑΥΞΗΤΙΚΗ ανά μηχανή — νέο ερώτημα σε μακρόβια
   ;; μηχανή πληρώνει ΜΟΝΟ το δέλτα του (τα νέα premises), όχι ξανά τα πάντα.
   (ground-avail :initform (make-hash-table :test 'equal) :reader engine-ground-avail)
   (ground-idx   :initform (%make-fact-index) :reader engine-ground-idx)))

(defun make-inference-engine () (make-instance 'inference-engine))

(defun add-fact (engine datum) (tms-premise (engine-jtms engine) datum) engine)
(defun add-facts (engine data) (dolist (d data engine) (add-fact engine d)))

(defun run-inference (engine &key (rules (all-legal-rules)))
  "Δημόσια είσοδος: %run-inference-1 + ΙΧΝΟΣ ΠΡΟΕΛΕΥΣΗΣ. Σε προφίλ
   :legal-critical, κάθε κλήση που ΓΕΝΝΑ ή ΑΠΟΣΥΡΕΙ έννομες καταστάσεις
   (well-founded διαφορά πεποιθήσεων πριν/μετά) αφήνει γεγονός :legal-state —
   «μάθε πώληση ⇒ αποσύρεται κατοχή» με ορατό ίχνος, όχι σιωπηλά."
  (if (orchestrator.trace:trace-enabled-p :legal-critical)
      (let ((before (jtms-believed-facts (engine-jtms engine))))
        (prog1 (%run-inference-1 engine rules)
          (let* ((after (jtms-believed-facts (engine-jtms engine)))
                 (created (set-difference after before :test #'equal))
                 (withdrawn (set-difference before after :test #'equal)))
            (when (or created withdrawn)
              (orchestrator.trace:emit! :legal-state
               :symbol "run-inference" :package "orchestrator.inference"
               :source "source/legal-inference-engine.lisp"
               :data (list :created-count (length created)
                           :withdrawn-count (length withdrawn)
                           :created (subseq created 0 (min 12 (length created)))
                           :withdrawn (subseq withdrawn 0 (min 12 (length withdrawn)))))))))
      (%run-inference-1 engine rules)))

(defun %run-inference-1 (engine rules)
  "Εμπρόσθια αλυσίδωση σε fixpoint + well-founded πεποίθηση, ΧΩΡΙΣΤΑ (Φάση 2):

   1. ΓΕΙΩΣΗ, ημι-αφελής (semi-naive) και ΑΥΞΗΤΙΚΗ: οι κανόνες στιγμιοποιούνται
      πάνω στη ΘΕΤΙΚΗ προσπελασιμότητα (premises + ό,τι παράγεται αγνοώντας
      τους defeaters) — το κανονικό grounding των συστημάτων well-founded/ASP.
      Κάθε γύρος ταιριάζει ΜΟΝΟ συνδυασμούς με ≥1 fact του δέλτα
      (%match-rule-delta) μέσω του ευρετηρίου κατά κατηγόρημα. Η γείωση ΖΕΙ
      στη μηχανή (engine-ground-*): επόμενη κλήση σε μακρόβια μηχανή γειώνει
      ΜΟΝΟ τα νέα premises. Κανόνες με ΚΕΝΟ :when (αξιώματα/τεκμήρια) γειώνονται
      ρητά — δεν έχουν σώμα, άρα δεν περνούν από δέλτα.
   2. ΠΕΠΟΙΘΗΣΗ: ΕΝΑΣ υπολογισμός του well-founded μοντέλου στο τέλος.

   ΔΗΛΩΜΕΝΗ ΣΗΜΑΣΙΟΛΟΓΙΑ (όχι σιωπηλή): το μοντέλο είναι το ΚΑΝΟΝΙΚΟ
   well-founded του δηλωτικού προγράμματος. Σε μη-στρωματοποιημένα προγράμματα
   (defeater που παράγεται από κανόνα μέσα σε βρόχο άρνησης) η παλαιά,
   καθοδηγούμενη-από-πεποίθηση γείωση ΥΠΟΓΕΙΩΝΕ και «αποφάσιζε» αναποφάσιστα
   ως ψευδή· εδώ το αναποφάσιστο μένει μη-πιστευτό ΚΑΙ μεταδίδεται ορθά
   (κλειδωμένο στην πύλη --inference-gate). Οι 12 τρέχοντες κανόνες έχουν
   :unless μόνο σε δεδομένα (EDB) — καμία τρέχουσα έξοδος δεν αλλάζει.

   Κανόνες με ΔΙΚΗ τους rule-matches (open/closed) κρατούν το δημόσιο συμβόλαιο
   του generic: καλούνται ανά γύρο πάνω στα ΠΙΣΤΕΥΟΜΕΝΑ facts (recompute ανά
   γύρο ΜΟΝΟ όταν υπάρχουν τέτοιοι — δηλωμένο κόστος, καμία σήμερα).
   Τερματίζει: πεπερασμένος χώρος στιγμιοτύπων, κάθε αιτιολόγηση άπαξ."
  (let* ((jtms (engine-jtms engine))
         (fast (remove-if #'%custom-matcher-p rules))
         (slow (remove-if-not #'%custom-matcher-p rules))
         (avail (engine-ground-avail engine))
         (base-idx (engine-ground-idx engine))
         (delta '()))
    (labels ((know (datum)
               (unless (gethash datum avail)
                 (setf (gethash datum avail) t)
                 (push datum delta)))
             (record (m informant)
               (destructuring-bind (consequent in-facts out-datums) m
                 (when (and consequent
                            (tms-justify jtms consequent
                                         (mapcar (lambda (d)
                                                   ;; ο υπολογισμός φραγμού είναι
                                                   ;; ΠΡΟΚΕΙΜΕΝΗ: πιστεύεται αξιωματικά,
                                                   ;; φαίνεται στο δέντρο — και σημειώνεται
                                                   ;; ΓΕΙΩΜΕΝΟΣ χωρίς δέλτα (δεν ξαναμπαίνει
                                                   ;; στο join σε επόμενα run — εύρημα #31)
                                                   (if (and (consp d) (eq (car d) :υπολογισμός))
                                                       (progn (setf (gethash d avail) t)
                                                              (tms-premise jtms d))
                                                       (tms-intern jtms d)))
                                                 in-facts)
                                         (mapcar (lambda (d) (tms-intern jtms d)) out-datums)
                                         informant))
                   (know consequent)))))
      ;; σπόρος: ό,τι premises/συνέπειες ΔΕΝ έχουν ήδη γειωθεί (αυξητικότητα)
      (dolist (n (jtms-nodes jtms))
        (when (or (node-premise-p n) (node-justifications n))
          (know (node-datum n))))
      ;; ΑΞΙΩΜΑΤΑ: κανόνες χωρίς σώμα γειώνονται άπαξ εδώ (ιδεμποτές dedup)
      (dolist (rule fast)
        (when (null (rule-when rule))
          (dolist (m (%rule-matches-states rule (list (cons '() '()))))
            (record m (rule-name rule)))))
      (loop with first-round = t
            ;; οι εξειδικεύσεις τρέχουν τουλάχιστον έναν γύρο και σε κενό δέλτα
            while (or delta (and first-round slow)) do
        (setf first-round nil)
        (let ((delta-now delta))
          (setf delta '())
          (let ((delta-idx (make-fact-index delta-now)))
            (dolist (rule fast)
              (when (rule-when rule)
                (dolist (m (%match-rule-delta rule base-idx delta-idx))
                  (record m (rule-name rule)))))
            (when slow
              (recompute-beliefs jtms)
              ;; οι εξειδικεύσεις καλούνται με ΛΙΣΤΑ πιστευόμενων facts — το
              ;; ιστορικό δημόσιο συμβόλαιο του generic, εφαρμόσιμο και σε
              ;; μεθόδους που εξειδικεύουν (facts list)/(facts cons)
              (let ((believed (jtms-believed-facts jtms)))
                (dolist (rule slow)
                  (dolist (m (rule-matches rule believed))
                    (record m (rule-name rule))))))
            (dolist (f delta-now) (index-add base-idx f))))))
    (recompute-beliefs jtms)
    engine))

(defun query (engine pattern)
  "Every believed fact matching PATTERN, as a list of (FACT . BINDINGS)."
  (loop for d in (jtms-believed-facts (engine-jtms engine))
        for b = (unify pattern d '())
        unless (eq b :fail) collect (cons d b)))

(defun affected-by (engine code article)
  "Every provision derived as (transitively) affected by a change in CODE/ARTICLE,
   paired with its proof tree."
  (loop for (fact . nil) in (query engine (list :affected code '?src :by article))
        collect (cons (third fact) (explain (engine-jtms engine) fact))))

(defun broken-references (engine)
  "Every citation derived as pointing at a repealed provision, with proof."
  (loop for (fact . nil) in (query engine '(:broken-reference ?code ?src :to ?art))
        collect (cons fact (explain (engine-jtms engine) fact))))

;;; ============================================================================
;;; THE L1 RULE SET — consequential-amendment analysis (declarative DSL)
;;;
;;; Facts (premises) the adapters supply:
;;;   (:references CODE SRC TCODE TART)  — article SRC of CODE cites TART of TCODE
;;;   (:changed    CODE ART)            — ART of CODE was amended by the latest law
;;;   (:repealed   CODE ART)            — ART of CODE has been repealed
;;; ============================================================================

;; A provision citing a just-changed article is directly affected — UNLESS it is itself
;; repealed (a repealed provision is not "affected"; it is gone). This is the defeasible
;; form the new engine makes possible.
(defrule consequential-amendment
  :when   ((:changed ?code ?art)
           (:references ?code ?src ?code ?art))
  :unless ((:repealed ?code ?src))
  :then   (:affected ?code ?src :by ?art))

;; Impact cascades transitively, each step justified — again defeated for a repealed
;; intermediate provision.
(defrule cascade-amendment-impact
  :when   ((:affected ?code ?mid :by ?art)
           (:references ?code ?src ?code ?mid))
  :unless ((:repealed ?code ?src))
  :then   (:affected ?code ?src :by ?art))

;; A citation to a repealed provision is a dangling reference (an L2 consistency seed).
(defrule dangling-reference
  :when ((:references ?code ?src ?tcode ?tart)
         (:repealed ?tcode ?tart))
  :then (:broken-reference ?code ?src :to ?tart))
