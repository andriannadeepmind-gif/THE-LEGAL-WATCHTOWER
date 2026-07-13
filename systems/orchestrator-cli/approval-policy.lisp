;;;; systems/orchestrator-cli/approval-policy.lisp
;;;; ============================================================================
;;;; ΠΟΛΙΤΙΚΕΣ ΕΓΚΡΙΣΗΣ ΚΑΤΑ ΚΛΑΣΗ (Φάση 5) — με ΜΕΤΡΗΜΕΝΗ ακρίβεια, ποτέ στα τυφλά
;;;; ============================================================================
;;;;
;;;; Το εύρημα της επιθεώρησης: 3016 επαληθευμένες ταξινομήσεις περίμεναν έγκριση
;;;; ΜΙΑ-ΜΙΑ — ο ένας εγκρίνων δεν κλιμακώνει. Η λύση ΔΕΝ είναι τυφλή αυτο-έγκριση:
;;;; ο δημιουργός εγκρίνει ΚΛΑΣΗ (τυπικότητα δεοντικού τελεστή), αφού δει την
;;;; ΑΚΡΙΒΕΙΑ της κλάσης μετρημένη πάνω στην ΚΛΕΙΔΩΜΕΝΗ σουίτα (40 περιπτώσεις,
;;;; 3 αντιπαραθετικοί γύροι κριτών). Η πολιτική:
;;;;   • καταγράφεται στο ΙΔΙΟ append-only ιδίωμα (deployment/self/policies.sexp,
;;;;     versioned — απόφαση του δημιουργού, όπως οι εγκρίσεις),
;;;;   • εγκρίνει αμέσως ό,τι ΕΚΚΡΕΜΕΙ στην κλάση και αυτο-εγκρίνει ό,τι ΝΕΟ
;;;;     περνά τον επαληθευτή στο εξής,
;;;;   • ανακαλείται ανά πάσα στιγμή (--policy-revoke) — νέο γεγονός, ίδιο fold,
;;;;   • ΔΕΝ ενεργοποιείται χωρίς μετρημένα δεδομένα — «δεν μαντεύω» και εδώ.

(in-package :orchestrator.cli)

(defvar *policies-path* nil
  "Override του ημερολογίου πολιτικών (gates→tmp). NIL ⇒ institution-root
   ([0086] ΜΙΑ ρίζα, τεμπέλικα).")

(defun %policies-path ()
  (or *policies-path*
      (merge-pathnames "deployment/self/policies.sexp"
                       (orchestrator.paths:institution-root))))

(defun %policy-events () (orchestrator.journal:read-lines (%policies-path)))

(defun active-policies ()
  "Οι ενεργές πολιτικές: fold ανά τυπικότητα (το τελευταίο γεγονός νικά)."
  (let ((h (make-hash-table :test 'eq)) (order '()))
    (dolist (e (%policy-events))
      (let ((m (getf e :modality)))
        (unless (gethash m h) (push m order))
        (setf (gethash m h) e)))
    (loop for m in (nreverse order)
          for e = (gethash m h)
          when (eq (getf e :status) :active) collect e)))

(defun policy-active-p (modality)
  (find modality (active-policies)
        :key (lambda (e) (getf e :modality)) :test #'eq))

(defun measured-modality-precision (modality)
  "(values σωστά σύνολο) πάνω στην ΚΛΕΙΔΩΜΕΝΗ σουίτα του δεοντικού: από όσες
   προτάσεις ο ταξινομητής ΧΑΡΑΚΤΗΡΙΖΕΙ ως MODALITY, πόσες είναι πράγματι —
   precision της κλάσης, το μέγεθος που μετρά για αυτο-έγκριση."
  (let ((correct 0) (total 0))
    (dolist (c *deontic-suite*)
      (destructuring-bind (s expect) c
        (let ((got (orchestrator.extraction:classify-deontic-sentence s)))
          (when (eq got modality)
            (incf total)
            (when (eq expect modality) (incf correct))))))
    (values correct total)))

(defparameter +dream-precision-suite+
  '(;; ── ΘΕΤΙΚΑ (8): έγκυρα όνειρα που εξηγούν την παρατηρημένη μαρτυρία ──
    ("προξενει" (:dream :lemma "προξενώ" :pred :προξενεί :forms ("προξενεί" "προξενούν")) t)
    ("ενεργει"  (:dream :lemma "ενεργώ"  :pred :ενεργεί  :forms ("ενεργεί" "ενεργούν")) t)
    ("προμηθευεται" (:dream :lemma "προμηθεύομαι" :pred :προμηθεύεται :forms ("προμηθεύεται")) t)
    ("παραβιαζουν"  (:dream :lemma "παραβιάζω" :pred :παραβιάζει :forms ("παραβιάζει" "παραβιάζουν")) t)
    ("αποκρυπτει"   (:dream :lemma "αποκρύπτω" :pred :αποκρύπτει :forms ("αποκρύπτει")) t)
    ("ζημιωνει"     (:dream :lemma "ζημιώνω"   :pred :ζημιώνει   :forms ("Ζημιώνει")) t) ; κανονικοποίηση τόνων/κεφαλαίων
    ("εκθετουν"     (:dream :lemma "εκθέτω"    :pred :εκθέτει    :forms ("εκθέτει" "εκθέτουν")) t)
    ("βιαιοπραγει"  (:dream :lemma "βιαιοπραγώ" :pred :βιαιοπραγεί :forms ("βιαιοπραγεί")) t)
    ;; ── ΑΡΝΗΤΙΚΑ (16): λάθος μαρτυρία, εχθρικά payloads, χαλασμένα σχήματα ──
    ("προξενει" (:dream :lemma "τρέχω"   :pred :τρέχει   :forms ("τρέχει")) nil)          ; δεν εξηγεί τη μαρτυρία
    ("προξενουν" (:dream :lemma "προξενώ" :pred :προξενεί :forms ("προξενεί")) nil)        ; μορφή-μαρτυρία εκτός forms
    ("" (:dream :lemma "προξενώ" :pred :προξενεί :forms ("προξενεί")) nil)                 ; κενή μαρτυρία
    ("προξενει" (:dream :lemma "../../x" :pred :χ :forms ("προξενει")) nil)                ; path traversal στο λήμμα
    ("κλεβει"   (:dream :lemma "κλέβ/ω"  :pred :κλέβει :forms ("κλέβει")) nil)             ; / μέσα στο λήμμα
    ("ενεργει"  (:dream :lemma "ενεργώ"  :pred :|RUN-CODE!| :forms ("ενεργεί")) nil)       ; εχθρικό κατηγόρημα
    ("ενεργει"  (:dream :lemma "ενεργώ"  :pred :|ΚΑΚΟ PRED| :forms ("ενεργεί")) nil)       ; κενό μέσα στο κατηγόρημα
    ("αφαιρει"  (:dream :lemma "αφαιρώ"  :pred "αφαιρεί" :forms ("αφαιρεί")) nil)          ; pred string, όχι keyword
    ("τραπεζι"  (:dream :lemma "τραπέζι" :pred :τραπέζι :forms ("τραπέζι")) nil)           ; λήμμα μη-ρηματικό
    ("κλεβει"   (:dream :lemma ""        :pred :κλέβει :forms ("κλέβει")) nil)             ; κενό λήμμα
    ("κλεβει"   (:dream :lemma "κλέβω"   :pred :κλέβει :forms ()) nil)                     ; κενές μορφές
    ("κλεβει"   (:dream :lemma "κλέβω"   :pred :κλέβει) nil)                               ; λείπουν οι μορφές
    ("κλεβει"   (:dream :lemma "κλέβω"   :pred :κλέβει :forms (42)) nil)                   ; μορφή μη-string
    ("κλεβει"   (:dream :lemma "κλέβω"   :pred :κλέβει :forms ("")) nil)                   ; κενή μορφή
    ("rm -rf /" (:dream :lemma "κλέβω"   :pred :κλέβει :forms ("rm -rf /")) nil)           ; κέλυφος μεταμφιεσμένο σε «μορφή»
    ("αφαιρει2" (:dream :lemma "αφαιρώ"  :pred :αφαιρεί :forms ("αφαιρει2")) nil))         ; ψηφία μέσα στη μορφή
  "ΚΛΕΙΔΩΜΕΝΗ σουίτα του δικαστή ονείρων: (τύπος-μαρτυρίας όνειρο δεκτό-p).
   24 περιπτώσεις — 8 θετικές, 16 αρνητικές/εχθρικές (επέκταση ×5 κατόπιν
   εξωτερικής επιθεώρησης 05-07-2026: τα εχθρικά «rm -rf /», ψηφία και
   path traversal κλειδώθηκαν αφού σκλήρυνε ο ίδιος ο validate-dream).
   Η ακρίβεια της κλάσης :dream-frame μετριέται ΕΔΩ — μπροστά στα μάτια
   του δημιουργού, πριν του ζητηθεί πολιτική αυτο-έγκρισης.")

(defun measured-evolution-precision (class)
  "(values σωστά σύνολο) για κλάση ΕΞΕΛΙΞΗΣ πάνω στην κλειδωμένη σουίτα της.
   Μη μετρήσιμη κλάση ⇒ (0 0) — καμία πολιτική χωρίς μέτρηση."
  (case class
    (:dream-frame
     (let ((correct 0) (total 0))
       (dolist (c +dream-precision-suite+)
         (destructuring-bind (vform dream expect) c
           (incf total)
           (when (eq (and (validate-dream vform dream) t) expect)
             (incf correct))))
       (values correct total)))
    (t (values 0 0))))

(defparameter +evolution-classes+ '(:dream-frame)
  "Κλάσεις αυτο-εξέλιξης που δέχονται πολιτική (μετρήσιμες). Οι υπόλοιπες
   (γειώσεις, ταξινομίες, λεξιλόγιο, κανόνες) μένουν ΠΑΝΤΑ στο χέρι του
   δημιουργού — δηλωμένο όριο, όχι παράλειψη.")

(defun %maybe-auto-approve (id modality)
  "Αν υπάρχει ενεργή πολιτική για την MODALITY, ενέργησε την έγκριση της
   πρότασης ID αμέσως. Επιστρέφει Τ αν αυτο-εγκρίθηκε."
  (when (and id (policy-active-p modality))
    (multiple-value-bind (p status) (orchestrator.proposals:approve! id)
      (declare (ignore p))
      (eq status :approved))))

(defun run-policies ()
  "--policies : μετρημένη ακρίβεια ανά κλάση + οι ενεργές πολιτικές."
  (format t "~%── ΚΛΑΣΕΙΣ ΤΑΞΙΝΟΜΗΣΗΣ (ακρίβεια στην κλειδωμένη σουίτα) ──~%")
  (dolist (m '(:prohibition :obligation :permission))
    (multiple-value-bind (c tot) (measured-modality-precision m)
      (format t "  ~(~A~): ~D/~D~@[ (~,1F%)~]~@[ · ΕΝΕΡΓΗ ΠΟΛΙΤΙΚΗ~]~%"
              m c tot (and (plusp tot) (* 100.0 (/ c tot)))
              (policy-active-p m))))
  (dolist (m +evolution-classes+)
    (multiple-value-bind (c tot) (measured-evolution-precision m)
      (format t "  ~(~A~): ~D/~D~@[ (~,1F%)~]~@[ · ΕΝΕΡΓΗ ΠΟΛΙΤΙΚΗ~]~%"
              m c tot (and (plusp tot) (* 100.0 (/ c tot)))
              (policy-active-p m))))
  (let ((open (remove-if-not
               (lambda (p) (eq (orchestrator.proposals:proposal-kind p) :norm-classification))
               (orchestrator.proposals:open-proposals))))
    (format t "~%  εκκρεμείς ταξινομήσεις: ~D~%" (length open)))
  (format t "  (ενεργοποίηση: --policy-approve <κλάση> · ανάκληση: --policy-revoke <κλάση>)~%")
  0)

(defun %parse-modality (s)
  (and s (find s '(:prohibition :obligation :permission :dream-frame)
               :key #'symbol-name :test #'string-equal)))

(defun %class-precision (class)
  "Η μετρημένη ακρίβεια της κλάσης — δεοντικές από τη σουίτα του δεοντικού,
   εξελικτικές από τις δικές τους κλειδωμένες σουίτες. Η ΜΙΑ πύλη μέτρησης."
  (if (member class +evolution-classes+)
      (measured-evolution-precision class)
      (measured-modality-precision class)))

(defun run-policy-approve (args)
  "--policy-approve <κλάση> : ενεργοποίησε πολιτική αυτο-έγκρισης για την κλάση —
   ΜΟΝΟ με μετρημένη ακρίβεια μπροστά στα μάτια του δημιουργού. Εγκρίνει αμέσως
   και ό,τι ήδη εκκρεμεί στην κλάση."
  (let ((m (%parse-modality (first args))))
    (unless m
      (format t "χρήση: --policy-approve prohibition|obligation|permission~%")
      (return-from run-policy-approve 1))
    (multiple-value-bind (c tot) (%class-precision m)
      (when (zerop tot)
        (format t "ΑΡΝΗΣΗ: καμία μετρημένη περίπτωση για ~(~A~) στη σουίτα — δεν ενεργοποιώ πολιτική χωρίς μέτρηση.~%" m)
        (return-from run-policy-approve 1))
      (orchestrator.journal:append-line (%policies-path)
        (list :at (orchestrator.journal:iso-now) :modality m
              :precision (format nil "~D/~D" c tot) :status :active))
      (format t "~%✓ Πολιτική ~(~A~) ΕΝΕΡΓΗ — μετρημένη ακρίβεια κλάσης: ~D/~D (~,1F%)~%"
              m c tot (* 100.0 (/ c tot)))
      ;; εγκρίνει ό,τι ήδη περιμένει στην κλάση — εδώ αδειάζει η ουρά των 3016
      (let ((n 0))
        (dolist (p (orchestrator.proposals:open-proposals))
          (when (if (member m +evolution-classes+)
                    ;; εξελικτική κλάση: :self-extension με δηλωμένη :class
                    (and (eq (orchestrator.proposals:proposal-kind p) :self-extension)
                         (eq (getf (%self-extension-payload p) :class) m))
                    ;; δεοντική κλάση: ταξινομήσεις κανόνων
                    (and (eq (orchestrator.proposals:proposal-kind p) :norm-classification)
                         (eq (getf (%norm-classification-payload p) :modality) m)))
            (multiple-value-bind (q status)
                (orchestrator.proposals:approve! (orchestrator.proposals:proposal-id p))
              (declare (ignore q))
              (when (eq status :approved) (incf n)))))
        (format t "  εγκρίθηκαν ~D εκκρεμείς της κλάσης~%" n))
      0)))

(defun run-policy-revoke (args)
  "--policy-revoke <κλάση> : ανάκληση πολιτικής — οι νέες προτάσεις της κλάσης
   ξαναπεριμένουν ατομική έγκριση (οι ήδη εγκεκριμένες μένουν — τελικές)."
  (let ((m (%parse-modality (first args))))
    (unless m
      (format t "χρήση: --policy-revoke prohibition|obligation|permission~%")
      (return-from run-policy-revoke 1))
    (orchestrator.journal:append-line (%policies-path)
      (list :at (orchestrator.journal:iso-now) :modality m :status :revoked))
    (format t "⨯ Πολιτική ~(~A~) ΑΝΑΚΛΗΘΗΚΕ — ατομική έγκριση στο εξής.~%" m)
    0))

(defun run-policy-gate ()
  "--policy-gate : η πύλη των πολιτικών — όλα σε ΠΡΟΣΩΡΙΝΑ ημερολόγια."
  (let* ((tmp-pol (merge-pathnames (format nil "polgate-~D.sexp" (get-universal-time))
                                   (uiop:temporary-directory)))
         (tmp-prop (merge-pathnames (format nil "polgate-prop-~D.sexp" (get-universal-time))
                                    (uiop:temporary-directory)))
         (*policies-path* tmp-pol)
         (orchestrator.proposals:*proposals-path* tmp-prop)
         ;; ΑΠΟΜΟΝΩΣΗ: οι δοκιμαστικές εγκρίσεις γράφουν στο L5 (register-norm) —
         ;; το μητρώο norms φωτογραφίζεται και επανέρχεται ΕΓΓΥΗΜΕΝΑ
         (norms-snapshot (orchestrator.deontic:all-norms))
         (fails '()) (total 0))
    (labels ((check (label ok)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails) (format t "  ✗ ~A~%" label)))))
      (format t "~%── ΠΥΛΗ ΠΟΛΙΤΙΚΩΝ ──~%")
      ;; 1 — η μέτρηση υπάρχει και είναι τέλεια πάνω στην πράσινη σουίτα
      (multiple-value-bind (c tot) (measured-modality-precision :prohibition)
        (check "μετρημένη ακρίβεια :prohibition από την κλειδωμένη σουίτα (σύνολο>0)"
               (and (plusp tot) (= c tot))))
      ;; 1β — η ΕΞΕΛΙΚΤΙΚΗ κλάση :dream-frame: 24/24 στη διευρυμένη σουίτα
      ;;      (8 θετικά + 16 αρνητικά/εχθρικά — κλειδωμένο μέγεθος ΚΑΙ τελειότητα)
      (multiple-value-bind (c tot) (measured-evolution-precision :dream-frame)
        (check "ακρίβεια :dream-frame 24/24 στη διευρυμένη εχθρική σουίτα"
               (and (= tot 24) (= c tot))))
      ;; 2 — χωρίς πολιτική: καμία αυτο-έγκριση
      (let ((id (orchestrator.proposals:propose!
                 :sig "polgate α" :kind :norm-classification :why "τεστ"
                 :payload (prin1-to-string '(:source "x:1" :modality :prohibition)))))
        (check "χωρίς πολιτική: η πρόταση μένει ΑΝΟΙΧΤΗ"
               (and id (not (%maybe-auto-approve id :prohibition))
                    (= 1 (length (orchestrator.proposals:open-proposals))))))
      ;; 3 — ενεργοποίηση πολιτικής: γράφεται, διαβάζεται, φαίνεται ενεργή
      (orchestrator.journal:append-line (%policies-path)
        (list :at (orchestrator.journal:iso-now) :modality :prohibition
              :precision "x/y" :status :active))
      (check "η πολιτική ενεργή μετά την καταγραφή" (and (policy-active-p :prohibition) t))
      ;; 4 — νέα πρόταση της κλάσης αυτο-εγκρίνεται
      (let ((id (orchestrator.proposals:propose!
                 :sig "polgate β" :kind :norm-classification :why "τεστ"
                 :payload (prin1-to-string '(:source "x:2" :modality :prohibition)))))
        (check "με πολιτική: αυτο-έγκριση της νέας πρότασης"
               (and id (%maybe-auto-approve id :prohibition))))
      ;; 5 — άλλη κλάση ΔΕΝ καλύπτεται
      (let ((id (orchestrator.proposals:propose!
                 :sig "polgate γ" :kind :norm-classification :why "τεστ"
                 :payload (prin1-to-string '(:source "x:3" :modality :obligation)))))
        (check "η πολιτική ΔΕΝ διαρρέει σε άλλη κλάση"
               (and id (not (%maybe-auto-approve id :obligation)))))
      ;; 6 — ανάκληση: νέες προτάσεις ξαναπεριμένουν
      (orchestrator.journal:append-line (%policies-path)
        (list :at (orchestrator.journal:iso-now) :modality :prohibition :status :revoked))
      (let ((id (orchestrator.proposals:propose!
                 :sig "polgate δ" :kind :norm-classification :why "τεστ"
                 :payload (prin1-to-string '(:source "x:4" :modality :prohibition)))))
        (check "μετά την ανάκληση: καμία αυτο-έγκριση"
               (and id (not (%maybe-auto-approve id :prohibition)))))
      ;; 7 — ΣΤΟΧΕΥΜΕΝΟ+ΑΙΤΙΟΛΟΓΗΜΕΝΟ override (επιθεώρηση 05-07-2026, κλειδωμένο)
      (let ((old-ovr (uiop:getenv "LAWMAX_OVERRIDE"))
            (old-rsn (uiop:getenv "LAWMAX_OVERRIDE_REASON")))
        (unwind-protect
             (progn
               (sb-posix:unsetenv "LAWMAX_OVERRIDE")
               (sb-posix:unsetenv "LAWMAX_OVERRIDE_REASON")
               (check "«--force» ΧΩΡΙΣ αιτιολογία ⇒ ΔΕΝ παρακάμπτει"
                      (not (orchestrator.constitution:overridden-p '("--force") "--x")))
               (sb-posix:setenv "LAWMAX_OVERRIDE_REASON" "δοκιμή πύλης" 1)
               (check "«--force» ΜΕ αιτιολογία ⇒ παρακάμπτει (εμβέλεια: η κλήση)"
                      (and (orchestrator.constitution:overridden-p '("--force") "--x") t))
               (sb-posix:setenv "LAWMAX_OVERRIDE" "--other" 1)
               (check "LAWMAX_OVERRIDE άλλης εντολής ⇒ ΔΕΝ διαρρέει στην τρέχουσα"
                      (not (orchestrator.constitution:overridden-p '() "--x")))
               (sb-posix:setenv "LAWMAX_OVERRIDE" "--other,--x" 1)
               (check "LAWMAX_OVERRIDE που περιέχει την εντολή + αιτιολογία ⇒ παρακάμπτει"
                      (and (orchestrator.constitution:overridden-p '() "--x") t))
               (sb-posix:setenv "LAWMAX_OVERRIDE" "1" 1)
               (check "το παλαιό καθολικό LAWMAX_OVERRIDE=1 ⇒ ΔΕΝ παρακάμπτει πλέον"
                      (not (orchestrator.constitution:overridden-p '() "--x"))))
          (if old-ovr (sb-posix:setenv "LAWMAX_OVERRIDE" old-ovr 1)
              (sb-posix:unsetenv "LAWMAX_OVERRIDE"))
          (if old-rsn (sb-posix:setenv "LAWMAX_OVERRIDE_REASON" old-rsn 1)
              (sb-posix:unsetenv "LAWMAX_OVERRIDE_REASON")))))
    (orchestrator.deontic:clear-norms)
    (dolist (n norms-snapshot) (orchestrator.deontic:register-norm n))
    (ignore-errors (delete-file tmp-pol))
    (ignore-errors (delete-file tmp-prop))
    (format t "~%── ΠΥΛΗ ΠΟΛΙΤΙΚΩΝ: ~D/~D πέρασαν ──~%" (- total (length fails)) total)
    (if fails 1 0)))

(register-command "--policies"      (lambda (a) (declare (ignore a)) (run-policies)))
(register-command "--policy-approve" (lambda (a) (run-policy-approve a)))
(register-command "--policy-revoke"  (lambda (a) (run-policy-revoke a)))
(register-command "--policy-gate"    (lambda (a) (declare (ignore a)) (run-policy-gate)))

(orchestrator.self-model:declare-capability! "πολιτικές-έγκρισης"
 :description "αυτο-έγκριση ΜΟΝΟ ανά κλάση με μετρημένη ακρίβεια σε κλειδωμένη σουίτα"
 :package :orchestrator.cli :functions '("run-policy-approve" "measured-evolution-precision")
 :gate "--policy-gate" :depends-on '("αυτοεπέκταση"))

;;; ── ΣΥΜΒΟΛΑΙΑ ΠΑΡΟΧΩΝ (δεσμευτική αυτοπεριγραφή — βλ. --contract-gate) ──

(orchestrator.contracts:defcontract "approval-policy-protocol" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "πολιτικές-έγκρισης" :role "σύνταγμα"
 :purpose "αυτο-έγκριση ΜΟΝΟ ανά κλάση με μετρημένη ακρίβεια σε κλειδωμένη σουίτα (run-policy-approve)"
 :side-effects '("έγκριση προτάσεων χωρίς άνθρωπο — μόνο εντός μετρημένης κλάσης")
 :preconditions '("η ακρίβεια της κλάσης μετρήθηκε στην κλειδωμένη σουίτα")
 :postconditions '("εκτός κλάσης ⇒ ο άνθρωπος αποφασίζει, πάντα")
 :legal-critical t :policy-level :ανθρώπινη-έγκριση
 :audit "κάθε αυτο-έγκριση καταγράφεται με την πολιτική που την επέτρεψε"
 :rollback "πολιτική ανακαλέσιμη· ό,τι ενέκρινε παραμένει αναστρέψιμο μέσω ledger"
 :tests '("--policy-gate"))
