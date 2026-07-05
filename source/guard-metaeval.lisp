;;;; source/guard-metaeval.lisp
;;;; ============================================================================
;;;; Ο ΜΕΤΑΚΥΚΛΙΚΟΣ ΑΠΟΤΙΜΗΤΗΣ ΦΡΑΓΜΩΝ — τυπωμένος, αποδεικτικοφόρος,
;;;; με ΑΝΕΞΑΡΤΗΤΟ ΕΛΕΓΚΤΗ ΠΙΣΤΟΠΟΙΗΤΙΚΩΝ (κριτήριο de Bruijn)
;;;; ============================================================================
;;;;
;;;; Τέσσερα στρώματα, το καθένα το ανώτατο υπαρκτό του είδους του:
;;;;
;;;; 1. ΓΛΩΣΣΑ ΜΕ ΠΥΡΓΟ ΟΡΙΣΜΩΝ (McCarthy): πυρήνας εμπιστοσύνης ελάχιστος·
;;;;    κάθε σύνθετος τελεστής ορίζεται ΜΕΣΑ στη γλώσσα και αποτιμάται από
;;;;    τον ίδιο eval — μετακυκλικά. Στρωμάτωση: ορισμός θεμελιώνεται ΜΟΝΟ
;;;;    σε τελεστές ΠΡΟΓΕΝΕΣΤΕΡΟΥ στρώματος (αύξων αριθμός ορισμού) ⇒ κανείς
;;;;    κύκλος, ούτε μέσω επανορισμού — ο τερματισμός μένει ΘΕΩΡΗΜΑ.
;;;;
;;;; 2. ΤΥΠΟΙ, ΣΤΑΤΙΚΑ (:int :bool :str :any): κακότυπος ορισμός απορρίπτεται
;;;;    ΤΗ ΣΤΙΓΜΗ ΤΟΥ ΟΡΙΣΜΟΥ — συνθήκη IF υποχρεωτικά :bool (το 0 ΔΕΝ είναι
;;;;    αλήθεια εδώ), ITER με ενδομορφισμό op:α→α και συμβατό σπόρο, μόνο
;;;;    ακέραια literals, ελάχιστη πληθικότητα στους variadic.
;;;;
;;;; 3. ΟΛΙΚΗ ΕΚΦΡΑΣΤΙΚΟΤΗΤΑ (System T): IF/AND/OR ΟΚΝΗΡΑ (βραχυκύκλωμα —
;;;;    ο φρουρός (or (= ν 0) (> (floor χ ν) 2)) δεν σκάει ποτέ) και ITER
;;;;    φραγμένη πρωτογενής αναδρομή. Επιπλέον ΚΑΥΣΙΜΟ (*fuel*): ολικό ΚΑΙ
;;;;    φραγμένο συνολικό κόστος — όχι μόνο κατά βήμα.
;;;;
;;;; 4. ΚΡΙΤΗΡΙΟ DE BRUIJN: κάθε φραγμός εκδίδει ΠΙΣΤΟΠΟΙΗΤΙΚΟ (πλήρες ίχνος
;;;;    αναγωγών) ΚΑΙ επαληθεύεται διπλά: (α) ο ανεξάρτητος ελεγκτής — δικός
;;;;    του eval, ΔΙΚΟΣ του αλγόριθμος ημερολογίου — ΞΑΝΑΫΠΟΛΟΓΙΖΕΙ ΟΛΟΚΛΗΡΗ
;;;;    την υποκατεστημένη έκφραση από το μηδέν, (β) κάθε κόμβος του ίχνους
;;;;    ξαναϋπολογίζεται τοπικά (IF/AND/OR κουβαλούν την υποκατεστημένη
;;;;    έκφρασή τους ώστε και η ΕΠΙΛΟΓΗ κλάδου να επαληθεύεται).
;;;;
;;;; ΔΗΛΩΜΕΝΟ ΟΡΙΟ (Gödel, όχι οικονομία): πλήρης αυτο-ερμηνευτής μέσα σε
;;;; ΟΛΙΚΗ γλώσσα είναι ΑΔΥΝΑΤΟΣ (διαγώνιο επιχείρημα)· το σύστημα επιλέγει
;;;; συνειδητά την ολικότητα («0 λάθος») και παίρνει ως αντάλλαγμα το
;;;; ανώτατο συμβατό: ανεξάρτητη επαλήθευση κάθε υπολογισμού.

(defpackage :orchestrator.metaeval
  (:use :cl)
  (:export #:meta-eval #:guards-pass-p
           #:define-primitive #:define-derived
           #:find-op #:op-names #:describe-language
           #:ops-snapshot #:ops-restore
           #:verify-trace #:verify-guard #:*verify-certificates*
           #:*max-depth* #:*max-iter* #:*fuel*
           #:infer-guard-type))

(in-package :orchestrator.metaeval)

(defstruct (gop (:constructor %make-gop))
  name      ; string (κανονικοποιημένο όνομα)
  kind      ; :primitive | :derived
  arity     ; ακέραιος ή nil (μεταβλητή πληθικότητα)
  minargs   ; ελάχιστη πληθικότητα variadic (οι CL συναρτήσεις απαιτούν ≥1)
  fn        ; :primitive — η CL συνάρτηση
  params    ; :derived — ονόματα παραμέτρων (strings)
  ptypes    ; τύποι παραμέτρων
  rettype   ; τύπος αποτελέσματος (derived: συναγόμενος στατικά)
  vartype   ; :primitive variadic — κοινός τύπος ορισμάτων
  seq       ; ΣΤΡΩΜΑ: αύξων αριθμός ορισμού — σώμα αναφέρεται ΜΟΝΟ σε
            ; μικρότερα seq, και στον επανορισμό: μικρότερα από το ΔΙΚΟ του
  body      ; :derived — το σώμα ΣΤΗ ΓΛΩΣΣΑ
  doc)

(defvar *ops* (make-hash-table :test 'equal)
  "Το μητρώο της γλώσσας: όνομα → gop. Η ΜΙΑ έδρα των τελεστών.
   Οι εγκαταστάσεις πακέτων δουλεύουν σε ΑΝΤΙΓΡΑΦΟ και δημοσιεύουν ατομικά.")

(defvar *op-seq* 0 "Μετρητής στρωμάτων ορισμού.")

(defvar *max-depth* 64
  "Φράγμα βάθους αναγωγών — προστασία από παθολογικά βαθιά ΔΕΔΟΜΕΝΑ.")

(defvar *max-iter* 10000
  "Φράγμα επαναλήψεων ΕΝΟΣ ITER (≈27 χρόνια σε βήματα ημερών).")

(defvar *fuel* 200000
  "ΚΑΥΣΙΜΟ: φράγμα ΣΥΝΟΛΙΚΩΝ βημάτων αναγωγής ανά αποτίμηση φραγμού —
   φωλιασμένα ITER δεν γίνονται (max-iter)^βάθος. Δηλωμένο όριο.")

(defvar %fuel-left% most-positive-fixnum "Τρέχον καύσιμο αποτίμησης.")
(defvar %c-fuel-left% most-positive-fixnum "Τρέχον καύσιμο ελεγκτή.")

(defvar *verify-certificates* t
  "Προεπιλογή (καμία οικονομία): ΚΑΘΕ φραγμός επαληθεύεται από τον
   ανεξάρτητο ελεγκτή — πλήρης ανεξάρτητος επαναϋπολογισμός + έλεγχος
   κάθε κόμβου του πιστοποιητικού — ΠΡΙΝ μπει στην απόδειξη.")

(defun %key (s)
  "Κανονικοποιημένο όνομα: κεφαλαία + τελικό σίγμα ς→Σ (το char-upcase ΔΕΝ
   κεφαλαιώνει το ς — η φυσική ελληνική γραφή δεν χάνει ποτέ τον τελεστή)."
  (substitute #\Σ #\ς (string-upcase (if (symbolp s) (symbol-name s) (string s)))))

(defun find-op (name) (gethash (%key name) *ops*))

(defun op-names ()
  (sort (loop for k being the hash-keys of *ops* collect k) #'string<))

(defun %special-form-p (head)
  (member (%key head) '("IF" "ITER" "AND" "OR") :test #'string=))

;;; ── ΤΥΠΟΙ: στατική συναγωγή + θεμελίωση + στρώματα, ΜΑΖΙ ─────────────────

(defun %type-compat-p (a b) (or (eq a :any) (eq b :any) (eq a b)))
(defun %type-join (a b) (if (eq a b) a :any))

(defun %check-op-arity (g nargs)
  (when (and (gop-arity g) (/= nargs (gop-arity g)))
    (error "~A: ~D ορίσματα αντί ~D" (gop-name g) nargs (gop-arity g)))
  (when (and (gop-vartype g) (< nargs (or (gop-minargs g) 1)))
    (error "~A: τουλάχιστον ~D όρισμα(τα)" (gop-name g) (or (gop-minargs g) 1))))

(defun %infer-type (expr param-types &optional max-seq)
  "Στατική συναγωγή τύπου + καλή θεμελίωση + έλεγχος στρώματος: κάθε τελεστής
   του σώματος πρέπει να έχει seq < MAX-SEQ (όταν δίνεται) — έτσι ούτε ο
   ΕΠΑΝΟΡΙΣΜΟΣ δεν μπορεί να κλείσει κύκλο. Σφάλμα ⇒ ο ορισμός ΔΕΝ μπαίνει."
  (cond
    ((integerp expr) :int)
    ((numberp expr)
     (error "μη ακέραιο αριθμητικό literal ~S — η γλώσσα των φραγμών είναι ακέραια" expr))
    ((stringp expr) :str)
    ((keywordp expr) :any)                  ; κυριολεκτικό δεδομένο (αν δεν είναι παράμετρος)
    ((symbolp expr)
     (let ((n (%key expr)))
       (cond ((assoc n param-types :test #'string=)
              (cdr (assoc n param-types :test #'string=)))
             ((member n '("T" "NIL") :test #'string=) :bool)
             (t (error "άδετο σύμβολο ~A στον ορισμό" expr)))))
    ((consp expr)
     (let ((head (%key (first expr))))
       (cond
         ((string= head "IF")
          (unless (= 3 (length (rest expr)))
            (error "IF: τρία μέρη (συνθήκη τότε αλλιώς)"))
          ;; Η ΣΥΝΘΗΚΗ ΕΙΝΑΙ :bool — το 0 δεν είναι «αλήθεια» σε νομική γλώσσα
          (let ((ct (%infer-type (second expr) param-types max-seq)))
            (unless (%type-compat-p ct :bool)
              (error "IF: η συνθήκη έχει τύπο ~A αντί :bool" ct)))
          (%type-join (%infer-type (third expr) param-types max-seq)
                      (%infer-type (fourth expr) param-types max-seq)))
         ((member head '("AND" "OR") :test #'string=)
          (unless (rest expr) (error "~A: τουλάχιστον ένα όρισμα" head))
          (dolist (a (rest expr))
            (let ((at (%infer-type a param-types max-seq)))
              (unless (%type-compat-p at :bool)
                (error "~A: όρισμα τύπου ~A αντί :bool" head at))))
          :bool)
         ((string= head "ITER")
          (unless (= 3 (length (rest expr)))
            (error "ITER: (iter πλήθος τελεστής σπόρος)"))
          (destructuring-bind (n op seed) (rest expr)
            (unless (%type-compat-p (%infer-type n param-types max-seq) :int)
              (error "ITER: το πλήθος πρέπει να είναι :int"))
            (let ((g (find-op op)))
              (unless g (error "ITER: άγνωστος τελεστής ~A" op))
              (when (and max-seq (>= (gop-seq g) max-seq))
                (error "ITER: ο ~A δεν ανήκει σε προγενέστερο στρώμα" op))
              (unless (or (null (gop-arity g)) (= 1 (gop-arity g)))
                (error "ITER: ο τελεστής ~A πρέπει να είναι μοναδιαίος" op))
              ;; ΕΝΔΟΜΟΡΦΙΣΜΟΣ op:α→α + συμβατός σπόρος (System T)
              (let ((in (or (first (gop-ptypes g)) (gop-vartype g) :any))
                    (out (gop-rettype g))
                    (st (%infer-type seed param-types max-seq)))
                (unless (%type-compat-p out in)
                  (error "ITER: ο ~A δεν είναι ενδομορφισμός (~A→~A)" op in out))
                (unless (%type-compat-p st in)
                  (error "ITER: σπόρος τύπου ~A αντί ~A" st in))
                out))))
         (t
          (let ((g (find-op (first expr))))
            (unless g
              (error "άγνωστος τελεστής ~A — οι ορισμοί θεμελιώνονται ΜΟΝΟ σε ήδη ορισμένους (στρωμάτωση ⇒ τερματισμός)" (first expr)))
            (when (and max-seq (>= (gop-seq g) max-seq))
              (error "~A: αναφορά σε τελεστή ίδιου/μεταγενέστερου στρώματος — θα έσπαγε το θεώρημα τερματισμού" (gop-name g)))
            (let ((argts (mapcar (lambda (a) (%infer-type a param-types max-seq))
                                 (rest expr))))
              (%check-op-arity g (length argts))
              (cond ((gop-vartype g)
                     (dolist (at argts)
                       (unless (%type-compat-p at (gop-vartype g))
                         (error "~A: όρισμα τύπου ~A αντί ~A" (gop-name g) at (gop-vartype g)))))
                    ((gop-ptypes g)
                     (loop for at in argts for pt in (gop-ptypes g)
                           unless (%type-compat-p at pt)
                             do (error "~A: όρισμα τύπου ~A αντί ~A" (gop-name g) at pt))))
              (gop-rettype g)))))))
    (t (error "μη αποτιμήσιμη μορφή ~S" expr))))

(defun infer-guard-type (guard var-names)
  "Δημόσιος στατικός έλεγχος φραγμού ΚΑΝΟΝΑ: οι ?μεταβλητές ως :any παράμετροι.
   Επιστρέφει τον τύπο· σφάλμα αν ο φραγμός δεν τυπώνεται ή δεν είναι :bool."
  (let ((ty (%infer-type guard (mapcar (lambda (v) (cons (%key v) :any)) var-names))))
    (unless (%type-compat-p ty :bool)
      (error "φραγμός :where με τύπο ~A αντί :bool — δεν είναι συνθήκη" ty))
    ty))

;;; ── ΟΡΙΣΜΟΙ ───────────────────────────────────────────────────────────────

(defun define-primitive (name arity fn &key ptypes (rettype :any) vartype
                                            (minargs 1) doc)
  "Πρωτογενής τελεστής — ΠΥΡΗΝΑΣ ΕΜΠΙΣΤΟΣΥΝΗΣ (στρώμα 0). Κρατιέται ελάχιστος."
  (when (%special-form-p name)
    (error "~A: δεσμευμένη ειδική μορφή" name))
  (setf (gethash (%key name) *ops*)
        (%make-gop :name (%key name) :kind :primitive :arity arity :fn fn
                   :ptypes ptypes :rettype rettype :vartype vartype
                   :minargs minargs :seq 0 :doc doc))
  (%key name))

(defun %parse-params (params)
  (let (names types)
    (dolist (p params (values (nreverse names) (nreverse types)))
      (cond ((consp p) (push (%key (first p)) names)
                       (push (or (second p) :any) types))
            (t (push (%key p) names) (push :any types))))))

(defun define-derived (name params body &optional doc)
  "Νέος τελεστής ΓΡΑΜΜΕΝΟΣ ΣΤΗ ΓΛΩΣΣΑ — η μετακυκλικότητα. ΠΡΙΝ εγκατασταθεί:
   πλήρης στατική τυποσυναγωγή, θεμελίωση σε ΠΡΟΓΕΝΕΣΤΕΡΟ στρώμα (και στον
   επανορισμό: μόνο σε στρώματα ΚΑΤΩ από το δικό του — κύκλος αδύνατος,
   το θεώρημα τερματισμού διατηρείται), καμία σκίαση πρωτογενούς/ειδικής."
  (when (%special-form-p name)
    (error "define-derived ~A: δεσμευμένη ειδική μορφή" name))
  (let* ((k (%key name)) (old (gethash k *ops*)))
    (when (and old (eq (gop-kind old) :primitive))
      (error "define-derived ~A: δεν επανορίζεται ΠΡΩΤΟΓΕΝΗΣ τελεστής" k))
    (multiple-value-bind (names types) (%parse-params params)
      (unless (every (lambda (n) (plusp (length n))) names)
        (error "define-derived ~A: κενό όνομα παραμέτρου" k))
      (let* ((seq (if old (gop-seq old) (incf *op-seq*)))
             (ret (%infer-type body (pairlis names types) seq)))
        (setf (gethash k *ops*)
              (%make-gop :name k :kind :derived :arity (length names)
                         :params names :ptypes types :rettype ret
                         :seq seq :body body :doc doc))
        (values k ret)))))

;;; ── ΥΠΟΚΑΤΑΣΤΑΣΗ: η κλειστή μορφή μιας έκφρασης (για πιστοποιητικά) ──────

(defun %var-p (s)
  (and (symbolp s) (let ((n (symbol-name s)))
                     (and (plusp (length n)) (char= (char n 0) #\?)))))

(defun %subst-expr (form binding env)
  "Βαθιά υποκατάσταση ?μεταβλητών (binding) και παραμέτρων (env) με τις τιμές
   τους — δίνει την ΚΛΕΙΣΤΗ έκφραση που ο ανεξάρτητος ελεγκτής ξανατρέχει από
   το μηδέν. Οι θέσεις τελεστών (κεφαλές, το όνομα του ITER) ΔΕΝ αγγίζονται."
  (cond
    ((consp form)
     (if (and (symbolp (first form)) (string= (%key (first form)) "ITER"))
         (list (first form)
               (%subst-expr (second form) binding env)
               (third form)
               (%subst-expr (fourth form) binding env))
         (cons (first form)
               (mapcar (lambda (x) (%subst-expr x binding env)) (rest form)))))
    ((symbolp form)
     (let ((n (%key form)))
       (let ((c (assoc n env :test #'string=)))
         (cond (c (cdr c))
               (t (let ((c2 (find n binding :key (lambda (p) (%key (car p)))
                                            :test #'string=)))
                    (if c2 (cdr c2) form)))))))
    (t form)))

;;; ── Η ΑΠΟΤΙΜΗΣΗ: eval/apply με πιστοποιητικό ─────────────────────────────

(defun %burn (fuel-var)
  (when (<= (symbol-value fuel-var) 0)
    (error "εξαντλήθηκε το καύσιμο αναγωγών (~D) — δηλωμένο όριο" *fuel*))
  (set fuel-var (1- (symbol-value fuel-var))))

(defun %resolve-symbol (sym binding env)
  "Σύμβολο → τιμή: παράμετρος (env), μεταβλητή κανόνα (binding), T/NIL·
   ΑΔΕΣΜΕΥΤΟ keyword = κυριολεκτικό δεδομένο. Άλλο άδετο ⇒ σφάλμα."
  (let ((n (%key sym)))
    (let ((cell (assoc n env :test #'string=)))
      (when cell (return-from %resolve-symbol (cdr cell))))
    (let ((cell (find n binding :key (lambda (p) (%key (car p))) :test #'string=)))
      (when cell (return-from %resolve-symbol (cdr cell))))
    (cond ((string= n "T") t)
          ((string= n "NIL") nil)
          ((keywordp sym) sym)
          (t (error "άδετο σύμβολο ~A στους φραγμούς" sym)))))

(defun %require-boolean (v where)
  (unless (member v '(t nil))
    (error "~A: μη λογική τιμή ~S — η συνθήκη είναι :bool, όχι «truthy»" where v))
  v)

(defun %apply-op (op args depth)
  "(values τιμή ίχνος-σώματος): Η ΜΙΑ εφαρμογή τελεστή του αποτιμητή."
  (%burn '%fuel-left%)
  (%check-op-arity op (length args))
  (ecase (gop-kind op)
    (:primitive (values (apply (gop-fn op) args) nil))
    (:derived
     ;; Η ΜΕΤΑΚΥΚΛΙΚΗ ΣΤΙΓΜΗ: ο ορισμός αποτιμάται από τον ίδιο eval
     (%meta-eval (gop-body op)
                 :env (pairlis (gop-params op) args)
                 :depth depth))))

(defun %meta-eval (expr &key binding env (depth 0))
  "(values τιμή πιστοποιητικό): Ο ΜΕΤΑΚΥΚΛΙΚΟΣ ΑΠΟΤΙΜΗΤΗΣ. IF/AND/OR οκνηρά
   (βραχυκύκλωμα)· ITER φραγμένο· καύσιμο συνολικού κόστους. Οι ειδικές
   μορφές κουβαλούν στο πιστοποιητικό την ΥΠΟΚΑΤΕΣΤΗΜΕΝΗ έκφρασή τους,
   ώστε ο ανεξάρτητος ελεγκτής να ξανατρέχει ΚΑΙ την επιλογή κλάδου."
  (when (> depth *max-depth*)
    (error "υπέρβαση βάθους αναγωγών (~D) — δηλωμένο όριο" *max-depth*))
  (cond
    ((integerp expr) (values expr nil))
    ((numberp expr) (error "μη ακέραιος αριθμός ~S στη γλώσσα φραγμών" expr))
    ((stringp expr) (values expr nil))
    ((symbolp expr) (values (%resolve-symbol expr binding env) nil))
    ((consp expr)
     (let ((head (%key (first expr))))
       (cond
         ((string= head "IF")
          (destructuring-bind (c a b) (rest expr)
            (multiple-value-bind (cv ct) (%meta-eval c :binding binding :env env
                                                      :depth (1+ depth))
              (%require-boolean cv "IF")
              (multiple-value-bind (bv bt)
                  (%meta-eval (if cv a b) :binding binding :env env
                             :depth (1+ depth))
                (values bv
                        (list* :αναγωγή
                               (list :if (%subst-expr expr binding env) cv)
                               := bv
                               (let ((subs (remove nil (list ct bt))))
                                 (when subs (list :διά subs)))))))))
         ((member head '("AND" "OR") :test #'string=)
          ;; ΟΚΝΗΡΑ: αποτίμηση αριστερά→δεξιά, στάση στο αποφασιστικό όρισμα —
          ;; ο φρουρός (or (= ν 0) (> (floor χ ν) 2)) δεν αγγίζει ποτέ το floor
          (let ((and-p (string= head "AND"))
                (subs '()) (v nil))
            (setf v and-p)
            (dolist (a (rest expr))
              (multiple-value-bind (av at) (%meta-eval a :binding binding :env env
                                                        :depth (1+ depth))
                (%require-boolean av head)
                (when at (push at subs))
                (setf v av)
                (when (if and-p (not av) av) (return))))
            (setf v (and v t))
            (values v (list* :αναγωγή
                             (list (if and-p :and :or)
                                   (%subst-expr expr binding env))
                             := v
                             (let ((s (nreverse subs))) (when s (list :διά s)))))))
         ((string= head "ITER")
          (destructuring-bind (n-e op-name seed-e) (rest expr)
            (let ((op (or (find-op op-name)
                          (error "ITER: άγνωστος τελεστής ~A" op-name))))
              (multiple-value-bind (n nt) (%meta-eval n-e :binding binding :env env
                                                         :depth (1+ depth))
                (unless (and (integerp n) (<= 0 n *max-iter*))
                  (error "ITER: πλήθος ~S εκτός [0, ~D]" n *max-iter*))
                (multiple-value-bind (seed st) (%meta-eval seed-e :binding binding
                                                                 :env env
                                                                 :depth (1+ depth))
                  (let ((v seed))
                    (dotimes (i n)
                      (setf v (nth-value 0 (%apply-op op (list v) (1+ depth)))))
                    (values v (list* :αναγωγή
                                     (list :iter n (intern (gop-name op) :keyword)
                                           seed)
                                     := v
                                     (let ((s (remove nil (list nt st))))
                                       (when s (list :διά s)))))))))))
         (t
          (let ((op (find-op (first expr))))
            (unless op
              (error "μη επιτρεπτός τελεστής φραγμού ~S — δεν ανήκει στη γλώσσα" (first expr)))
            (let ((args '()) (sub '()))
              (dolist (a (rest expr))
                (multiple-value-bind (v tr) (%meta-eval a :binding binding :env env
                                                         :depth (1+ depth))
                  (push v args) (when tr (push tr sub))))
              (setf args (nreverse args) sub (nreverse sub))
              (let ((hd (cons (intern (gop-name op) :keyword) args)))
                (multiple-value-bind (v body-tr) (%apply-op op args (1+ depth))
                  (values v (list* :αναγωγή hd := v
                                   (let ((all (append sub (when body-tr
                                                            (list body-tr)))))
                                     (when all (list :διά all)))))))))))))
    (t (error "μη αποτιμήσιμη μορφή φραγμού ~S" expr))))

(defun meta-eval (expr &key binding env)
  "(values τιμή πιστοποιητικό): δημόσια είσοδος του αποτιμητή — ΦΡΕΣΚΟ καύσιμο
   ανά κορυφαία κλήση, ώστε το φράγμα συνολικού κόστους να ισχύει για ΚΑΘΕ
   αποτίμηση, όχι μόνο για τη διαδρομή των κανόνων."
  (let ((%fuel-left% *fuel*))
    (%meta-eval expr :binding binding :env env :depth 0)))

;;; ── Ο ΑΝΕΞΑΡΤΗΤΟΣ ΕΛΕΓΚΤΗΣ (κριτήριο de Bruijn) ──────────────────────────
;;; ΣΚΟΠΙΜΑ δεύτερος βρόχος αποτίμησης — αυτό ΕΙΝΑΙ το κριτήριο, όχι διπλός
;;; κώδικας: αν μοιραζόταν τον βρόχο του meta-eval θα κληρονομούσε τα λάθη
;;; του. Ό,τι δεν αφορά την ανεξαρτησία (επίλυση συμβόλων, μητρώο, φράγματα)
;;; είναι κοινό. Το ημερολόγιο: ΔΙΚΟΣ του αλγόριθμος (σωρευτικός, όχι Hinnant).

(defun %leap-p (y) (and (zerop (mod y 4)) (or (plusp (mod y 100)) (zerop (mod y 400)))))

(defparameter +month-days+ #(31 28 31 30 31 30 31 31 30 31 30 31))

(defun %month-length (y m)
  (+ (aref +month-days+ (1- m)) (if (and (= m 2) (%leap-p y)) 1 0)))

(defun %parse-ymd (s who)
  "(values y m d) ΜΕ επικύρωση: μορφή, μήνας 1-12, ημέρα ≤ μήκος μήνα (δίσεκτο).
   Η 2026-02-30 ΔΕΝ είναι ημερομηνία — απορρίπτεται, δεν κανονικοποιείται."
  (unless (and (stringp s) (= 10 (length s))
               (char= #\- (char s 4)) (char= #\- (char s 7)))
    (error "~A: μη έγκυρη μορφή ημερομηνίας ~S (YYYY-MM-DD)" who s))
  (let ((y (parse-integer s :start 0 :end 4))
        (m (parse-integer s :start 5 :end 7))
        (d (parse-integer s :start 8 :end 10)))
    (unless (<= 1 m 12) (error "~A: ανύπαρκτος μήνας στην ~S" who s))
    (unless (<= 1 d (%month-length y m))
      (error "~A: ανύπαρκτη ημέρα στην ~S" who s))
    (values y m d)))

(defun %ymd->day-independent (s)
  "ΔΕΥΤΕΡΗ υλοποίηση ημερολογίου, σωρευτική — επίτηδες ΑΛΛΟΣ αλγόριθμος από
   τον Hinnant του πυρήνα: ο ελεγκτής δεν κληρονομεί τα λάθη του ελεγχομένου."
  (multiple-value-bind (y m d) (%parse-ymd s "ελεγκτής")
    (let ((days 0))
      (if (>= y 1970)
          (loop for yy from 1970 below y do (incf days (if (%leap-p yy) 366 365)))
          (loop for yy from y below 1970 do (decf days (if (%leap-p yy) 366 365))))
      (loop for mm from 1 below m do (incf days (%month-length y mm)))
      (+ days (1- d)))))

(defun %check-primitive (opk args)
  "Ανεξάρτητη τιμή πρωτογενούς: το ημερολόγιο με τον ΔΙΚΟ του αλγόριθμο, τα
   λοιπά μέσω του (κοινού, ελάχιστου) αριθμητικού πυρήνα εμπιστοσύνης."
  (if (string= (%key opk) "YMD->DAY")
      (%ymd->day-independent (first args))
      (let ((op (or (find-op opk) (error "ελεγκτής: άγνωστος πρωτογενής ~A" opk))))
        (%check-op-arity op (length args))
        (apply (gop-fn op) args))))

(defun %c-eval (expr env &optional (depth 0))
  "Ο eval ΤΟΥ ΕΛΕΓΚΤΗ — με τα ΙΔΙΑ δηλωμένα φράγματα (βάθος, ITER, καύσιμο):
   ο ελεγκτής είναι κι αυτός ολικός, ακόμη και σε εχθρικά πιστοποιητικά."
  (%burn '%c-fuel-left%)
  (when (> depth *max-depth*)
    (error "ελεγκτής: υπέρβαση βάθους (~D)" *max-depth*))
  (cond
    ((integerp expr) expr)
    ((numberp expr) (error "ελεγκτής: μη ακέραιος ~S" expr))
    ((stringp expr) expr)
    ((symbolp expr) (%resolve-symbol expr nil env))
    ((consp expr)
     (let ((head (%key (first expr))))
       (cond
         ((string= head "IF")
          (if (%require-boolean (%c-eval (second expr) env (1+ depth)) "ελεγκτής-IF")
              (%c-eval (third expr) env (1+ depth))
              (%c-eval (fourth expr) env (1+ depth))))
         ((member head '("AND" "OR") :test #'string=)
          (let ((and-p (string= head "AND")))
            (let ((v and-p))
              (dolist (a (rest expr) (and v t))
                (setf v (%require-boolean (%c-eval a env (1+ depth)) head))
                (when (if and-p (not v) v) (return (and v t)))))))
         ((string= head "ITER")
          (destructuring-bind (n-e op-name seed-e) (rest expr)
            (let ((n (%c-eval n-e env (1+ depth)))
                  (v (%c-eval seed-e env (1+ depth))))
              (unless (and (integerp n) (<= 0 n *max-iter*))
                (error "ελεγκτής ITER: πλήθος ~S εκτός [0, ~D]" n *max-iter*))
              (dotimes (i n v)
                (%burn '%c-fuel-left%)
                (setf v (%c-apply op-name (list v) (1+ depth)))))))
         (t (%c-apply (first expr)
                      (mapcar (lambda (a) (%c-eval a env (1+ depth))) (rest expr))
                      depth)))))
    (t (error "ελεγκτής: μη αποτιμήσιμο ~S" expr))))

(defun %c-apply (opname args &optional (depth 0))
  (let ((op (or (find-op opname) (error "ελεγκτής: άγνωστος τελεστής ~A" opname))))
    (%check-op-arity op (length args))
    (ecase (gop-kind op)
      (:primitive (%check-primitive (gop-name op) args))
      (:derived (%c-eval (gop-body op) (pairlis (gop-params op) args) (1+ depth))))))

(defun %verify-node (tr depth)
  "Τοπική επαλήθευση κόμβου πιστοποιητικού: κάθε αναγωγή ξαναϋπολογίζεται.
   IF/AND/OR κουβαλούν την υποκατεστημένη έκφρασή τους ⇒ ξανατρέχουν ΟΛΟΚΛΗΡΑ
   (και η επιλογή κλάδου επαληθεύεται)· ITER ξανατρέχει από το κεφάλι του."
  (when (> depth *max-depth*)
    (error "ελεγκτής: πιστοποιητικό βαθύτερο από το δηλωμένο όριο (~D)" *max-depth*))
  (unless (and (consp tr) (eq (first tr) :αναγωγή))
    (error "χαλασμένο πιστοποιητικό: ~S" tr))
  (destructuring-bind (head eqs v &rest kv) (rest tr)
    (unless (eq eqs :=) (error "χαλασμένο πιστοποιητικό (λείπει :=): ~S" tr))
    (dolist (s (getf kv :διά)) (%verify-node s (1+ depth)))
    (let ((opk (%key (first head))) (args (rest head)))
      (cond
        ((member opk '("IF" "AND" "OR") :test #'string=)
         ;; το κεφάλι φέρει την ΚΛΕΙΣΤΗ έκφραση — πλήρης επαναϋπολογισμός
         (let* ((expr (first args))
                (v2 (%c-eval expr '())))
           (unless (equal v v2)
             (error "ελεγκτής διαφωνεί στο ~A: ~S ≠ ~S" opk v2 v))
           ;; IF: και η δηλωθείσα τιμή συνθήκης οφείλει να συμφωνεί
           (when (string= opk "IF")
             (let ((cv2 (%c-eval (second expr) '())))
               (unless (eq (not (second args)) (not cv2))
                 (error "ελεγκτής: η συνθήκη IF είναι ~S, το πιστοποιητικό λέει ~S"
                        cv2 (second args)))))))
        ((string= opk "ITER")
         (let ((v2 (%c-eval head '())))
           (unless (equal v v2)
             (error "ελεγκτής διαφωνεί στο ITER: ~S ≠ ~S" v2 v))))
        (t
         (let ((v2 (%c-apply opk args)))
           (unless (equal v v2)
             (error "Ο ΑΝΕΞΑΡΤΗΤΟΣ ΕΛΕΓΚΤΗΣ ΔΙΑΦΩΝΕΙ: ~S = ~S, το πιστοποιητικό λέει ~S"
                    head v2 v)))))))
  t)

(defun verify-trace (tr)
  "(values ok-p λόγος): τοπική επαλήθευση ΚΑΘΕ κόμβου πιστοποιητικού από τον
   ανεξάρτητο ελεγκτή. Παραποίηση/υπέρβαση ορίων ⇒ (nil «ποιο βήμα, γιατί») —
   ποτέ κατάρρευση (πιάνονται ΚΑΙ storage conditions, με φράγμα βάθους)."
  (let ((%c-fuel-left% *fuel*))
    (declare (special %c-fuel-left%))
    (handler-case (values (%verify-node tr 0) nil)
      (storage-condition () (values nil "εξάντληση πόρων στον ελεγκτή — απορρίπτεται"))
      (error (e) (values nil (format nil "~A" e))))))

(defun verify-guard (closed-expr claimed trace)
  "(values ok-p λόγος): Η ΠΛΗΡΗΣ επαλήθευση de Bruijn ενός φραγμού:
   ① ο ελεγκτής ξαναϋπολογίζει ΟΛΟΚΛΗΡΗ την κλειστή έκφραση από το μηδέν
     (καμία εμπιστοσύνη στη δομή του ίχνους), και
   ② κάθε κόμβος του πιστοποιητικού επαληθεύεται τοπικά (η ΕΞΗΓΗΣΗ τίμια)."
  (let ((%c-fuel-left% *fuel*))
    (declare (special %c-fuel-left%))
    (handler-case
        (let ((v2 (%c-eval closed-expr '())))
          (unless (equal claimed v2)
            (error "ανεξάρτητος επαναϋπολογισμός: ~S ≠ δηλωθέν ~S" v2 claimed))
          (when trace (%verify-node trace 0))
          (values t nil))
      (storage-condition () (values nil "εξάντληση πόρων στον ελεγκτή"))
      (error (e) (values nil (format nil "~A" e))))))

;;; ── ΦΡΑΓΜΟΙ ΚΑΝΟΝΩΝ ──────────────────────────────────────────────────────

(defun guards-pass-p (guards binding)
  "(values περνούν-όλοι-p γεγονότα-υπολογισμών): κάθε φραγμός αποτιμάται
   μετακυκλικά ΚΑΙ (προεπιλογή) επαληθεύεται ΠΛΗΡΩΣ κατά de Bruijn: πλήρης
   ανεξάρτητος επαναϋπολογισμός της κλειστής έκφρασης + τοπικός έλεγχος
   κάθε κόμβου. Ψευδές/σφάλμα/απορριφθέν πιστοποιητικό ⇒ (nil nil) —
   fail-closed, ποτέ εικασία (τα δομικά λάθη κανόνων πιάνονται ΣΤΑΤΙΚΑ
   στη δημιουργία τους — βλ. initialize-instance legal-rule)."
  (let ((facts '()))
    (dolist (g guards (values t (nreverse facts)))
      (handler-case
          (multiple-value-bind (v trace) (meta-eval g :binding binding)
              (unless v (return-from guards-pass-p (values nil nil)))
              (let ((closed (%subst-expr g binding nil)))
                (when *verify-certificates*
                  (multiple-value-bind (ok why) (verify-guard closed v trace)
                    (unless ok (error "ΠΙΣΤΟΠΟΙΗΤΙΚΟ ΑΠΕΡΡΙΦΘΗ: ~A" why))))
                (push (list* :υπολογισμός closed := v
                             (append (when trace (list :ίχνος trace))
                                     (when *verify-certificates*
                                       (list :επαλήθευση :ανεξάρτητη))))
                      facts)))
        (error () (return-from guards-pass-p (values nil nil)))))))

;;; ── Snapshot/restore — ατομική δημοσίευση (πακέτα :guard-ops) ────────────

(defun ops-snapshot ()
  (let (acc) (maphash (lambda (k v) (push (cons k v) acc)) *ops*)
    (list :seq *op-seq* :ops acc)))

(defun ops-restore (snap)
  "Copy-on-write: χτίζεται ΝΕΟΣ πίνακας και δημοσιεύεται ατομικά — αναγνώστες
   σε άλλα νήματα βλέπουν πάντα πλήρη γλώσσα, ποτέ μισο-γραμμένη."
  (let ((new (make-hash-table :test 'equal)))
    (dolist (c (getf snap :ops)) (setf (gethash (car c) new) (cdr c)))
    (setf *op-seq* (getf snap :seq)
          *ops* new)))

(defun describe-language (&optional (stream *standard-output*))
  "Η γλώσσα περιγράφει ΤΟΝ ΕΑΥΤΟ ΤΗΣ, ζωντανά: πρωτογενείς (πυρήνας
   εμπιστοσύνης), παράγωγοι ΜΕ ΟΡΙΣΜΟΥΣ/ΤΥΠΟΥΣ/ΣΤΡΩΜΑ, ειδικές μορφές."
  (format stream "~%── Η ΓΛΩΣΣΑ ΤΩΝ ΦΡΑΓΜΩΝ (~D τελεστές + IF/AND/OR/ITER· κάθε χρήση με ανεξάρτητα επαληθευμένο πιστοποιητικό) ──~%"
          (hash-table-count *ops*))
  (dolist (k (op-names))
    (let ((op (gethash k *ops*)))
      (ecase (gop-kind op)
        (:primitive
         (format stream "  ~A~@[/~D~] : ~A~@[ (variadic ~A, ≥~D)~]  ΠΡΩΤΟΓΕΝΗΣ~@[ — ~A~]~%"
                 k (gop-arity op) (gop-rettype op) (gop-vartype op)
                 (and (gop-vartype op) (gop-minargs op)) (gop-doc op)))
        (:derived
         (format stream "  ~A(~{~A~^ ~}) : ~A [στρώμα ~D] := ~S~@[ · ~A~]~%"
                 k (mapcar (lambda (n ty) (format nil "~A:~A" n ty))
                           (gop-params op) (gop-ptypes op))
                 (gop-rettype op) (gop-seq op) (gop-body op) (gop-doc op))))))
  (hash-table-count *ops*))

;;; ── Ο ΠΥΡΗΝΑΣ ΕΜΠΙΣΤΟΣΥΝΗΣ: ελάχιστος, ολικός, τυπωμένος ─────────────────

(defun %ymd->day (s)
  "ISO «YYYY-MM-DD» → αριθμός ημέρας (proleptic Gregorian, αλγόριθμος Hinnant)
   ΜΕ επικύρωση — ανύπαρκτη ημερομηνία απορρίπτεται, δεν κανονικοποιείται."
  (multiple-value-bind (y m d) (%parse-ymd s "ymd->day")
    (let* ((y2 (if (<= m 2) (1- y) y))
           (era (floor (if (>= y2 0) y2 (- y2 399)) 400))
           (yoe (- y2 (* era 400)))
           ;; doy = ⌊(153·mp + 2)/5⌋ + d−1 — το ορατό ίχνος αποκάλυψε την παλιά
           ;; παραδρομή (153·mp·2)· έκτοτε ο ελεγκτής ξαναμετρά με ΑΛΛΟΝ αλγόριθμο
           (doy (+ (floor (+ (* 153 (if (> m 2) (- m 3) (+ m 9))) 2) 5) (1- d)))
           (doe (+ (* yoe 365) (floor yoe 4) (- (floor yoe 100)) doy)))
      (+ (* era 146097) doe -719468))))

(define-primitive "<"  nil #'<  :vartype :int :rettype :bool :minargs 2)
(define-primitive "<=" nil #'<= :vartype :int :rettype :bool :minargs 2)
(define-primitive ">"  nil #'>  :vartype :int :rettype :bool :minargs 2)
(define-primitive ">=" nil #'>= :vartype :int :rettype :bool :minargs 2)
(define-primitive "="  nil #'=  :vartype :int :rettype :bool :minargs 2)
(define-primitive "/=" nil #'/= :vartype :int :rettype :bool :minargs 2)
(define-primitive "+"  nil #'+  :vartype :int :rettype :int :minargs 1)
(define-primitive "-"  nil #'-  :vartype :int :rettype :int :minargs 1)
(define-primitive "*"  nil #'*  :vartype :int :rettype :int :minargs 1)
(define-primitive "MIN" nil #'min :vartype :int :rettype :int :minargs 1)
(define-primitive "MAX" nil #'max :vartype :int :rettype :int :minargs 1)
(define-primitive "ABS" 1 #'abs :ptypes '(:int) :rettype :int)
(define-primitive "MOD" 2 #'mod :ptypes '(:int :int) :rettype :int)
(define-primitive "FLOOR" 2 (lambda (a b) (floor a b)) :ptypes '(:int :int) :rettype :int)
(define-primitive "NOT" 1 (lambda (x) (not x)) :ptypes '(:bool) :rettype :bool)
(define-primitive "YMD->DAY" 1 #'%ymd->day :ptypes '(:str) :rettype :int
                  :doc "ISO ημερομηνία → ακέραιος ημέρας (με επικύρωση)")

;;; ── Ο ΠΥΡΓΟΣ: οι νομικοί χρονικοί τελεστές, ΣΤΗ ΓΛΩΣΣΑ, ΤΥΠΩΜΕΝΟΙ ────────

(define-derived "DAYS-BETWEEN" '((α :str) (β :str))
  '(- (ymd->day β) (ymd->day α)) "ημέρες από α έως β")
(define-derived "DATE<"  '((α :str) (β :str)) '(<  (ymd->day α) (ymd->day β)))
(define-derived "DATE<=" '((α :str) (β :str)) '(<= (ymd->day α) (ymd->day β)))
(define-derived "DATE>"  '((α :str) (β :str)) '(>  (ymd->day α) (ymd->day β)))
(define-derived "DATE>=" '((α :str) (β :str)) '(>= (ymd->day α) (ymd->day β)))
(define-derived "WITHIN-DAYS" '((α :str) (β :str) (ν :int))
  '(<= 0 (days-between α β) ν)
  "το β απέχει από το α από 0 έως ν ημέρες — η προθεσμία ως λογισμός")
(define-derived "ΗΜΕΡΑ-ΕΒΔΟΜΑΔΑΣ" '((δ :int)) '(mod (+ δ 3) 7)
  "0=Δευτέρα … 6=Κυριακή (1970-01-01=Πέμπτη=3)")
(define-derived "ΕΡΓΑΣΙΜΗ-P" '((δ :int)) '(< (ημερα-εβδομαδασ δ) 5)
  "Δευτέρα-Παρασκευή (αργίες: μελλοντικό πακέτο γνώσης)")
(define-derived "ΕΠΟΜΕΝΗ-ΗΜΕΡΑ" '((δ :int)) '(+ δ 1))
(define-derived "ΕΠΟΜΕΝΗ-ΕΡΓΑΣΙΜΗ" '((δ :int))
  '(if (εργασιμη-p (+ δ 1)) (+ δ 1)
       (if (εργασιμη-p (+ δ 2)) (+ δ 2) (+ δ 3)))
  "η επόμενη εργάσιμη — IF στη γλώσσα, ολικό (μέγιστο άλμα Σ/Κ: 2 ημέρες)")
