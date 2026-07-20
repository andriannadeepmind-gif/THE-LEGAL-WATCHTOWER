;;;; source/capability-registry.lisp
;;;; ============================================================================
;;;; CAPABILITY REGISTRY — Η ΜΙΑ έδρα δυνατοτήτων (μία είσοδος ανά λειτουργία)
;;;; ============================================================================
;;;;
;;;; Κάθε δυνατότητα του συστήματος (ρώτησε, δες τι έφερε ο δαίμονας, ενέκρινε,
;;;; δημοσίευσε, …) ορίζεται ΜΙΑ φορά, δηλωτικά, με πλήρες συμβόλαιο:
;;;;
;;;;   { name · summary · params (όνομα/τύπος/υποχρεωτικό) · result · trust · proof · fn }
;;;;
;;;; Οι επιφάνειες — HTTP cockpit, MCP (το AI-plug), CLI — είναι ΠΡΟΒΟΛΕΣ αυτής
;;;; της μίας έδρας, ΟΧΙ χειρόγραφοι adapters ανά επιφάνεια. Έτσι:
;;;;   • καμία τριπλή έδρα (HTTP/MCP/CLI): ένας ορισμός → τρεις όψεις·
;;;;   • ο νόμος «κανένα LLM/σύμβουλος στο trusted path» γίνεται ΙΔΙΟΤΗΤΑ της
;;;;     δυνατότητας (:trust) και επιβάλλεται ΔΟΜΙΚΑ, ίδια σε κάθε επιφάνεια·
;;;;   • καμία υπόσχεση εκτέλεσης χωρίς έλεγχο συμβολαίου (params + τύποι).
;;;;
;;;; ΚΑΝΕΝΑ wrapper: αυτή ΔΕΝ τυλίγει άλλον handler — είναι η πηγή. Οι domain
;;;; έδρες (run-ask, review-decide, discovery, emit-site) συνδέονται ως :fn.
;;;; ============================================================================

(defpackage :orchestrator.capability
  (:use :cl)
  (:export #:capability #:capability-name #:capability-summary #:capability-params
           #:capability-result #:capability-trust #:capability-proof #:capability-fn
           #:define-capability #:register-capability
           #:find-capability #:all-capabilities #:*capabilities*
           #:trusted-capability-p #:advisor-capability-p
           #:invoke-capability #:capability-error #:capability-error-cap
           #:capability-error-reason #:param-name #:param-type #:param-required-p
           #:+param-types+ #:capability-seat-collision #:capability-owner
           #:collision-capability-name #:collision-existing-owner #:collision-claimant))

(in-package :orchestrator.capability)

;;; ----------------------------------------------------------------------------
;;; Το συμβόλαιο μιας δυνατότητας
;;; ----------------------------------------------------------------------------

(defstruct (capability (:constructor %make-capability) (:copier nil))
  "Το πλήρες συμβόλαιο μιας δυνατότητας — αμετάβλητο μετά την εγγραφή."
  (name    nil :read-only t)   ; keyword — η ταυτότητα (π.χ. :ask)
  (summary ""  :read-only t)   ; ελληνική περιγραφή για άνθρωπο/AI
  (params  '() :read-only t)   ; λίστα από (όνομα-keyword τύπος υποχρεωτικό-p)
  (result  :any :read-only t)  ; τύπος αποτελέσματος (keyword)
  (trust   :trusted :read-only t) ; :trusted | :advisor
  (proof   nil :read-only t)   ; εκπέμπει επαληθεύσιμη απόδειξη;
  (fn      nil :read-only t))  ; (&key …) -> αποτέλεσμα — η domain έδρα

(defun param-name     (p) (first p))
(defun param-type     (p) (second p))
(defun param-required-p (p) (third p))

;; [audit#7] Το ΚΛΕΙΣΤΟ (frozen) σύνολο των επιτρεπτών param types — Η ΜΙΑ πηγή
;; αλήθειας. ΚΑΘΕ μονοπάτι (registration validation + runtime %type-ok-p + API
;; %coerce-one) οφείλει να καλύπτει ΑΚΡΙΒΩΣ αυτό — καμία fail-open «(t t)»/«(t s)».
;; Άγνωστος τύπος ⇒ ΑΠΟΡΡΙΨΗ στην εγγραφή (fail-closed), ποτέ σιωπηλή αποδοχή/υποβάθμιση.
;; (:number ΑΠΩΝ — καταργήθηκε [0094]/2A· η bidirectional gate το επιβάλλει.)
(defparameter +param-types+ '(:string :keyword :any :integer :boolean)
  "Το frozen canonical σύνολο param types. Αλλαγή = συνταγματική πράξη μαζί με
   %type-ok-p ΚΑΙ capability-api:%coerce-one (bidirectional, tests/param-type-coercion).")

(defparameter *capabilities* (make-hash-table :test 'eq)
  "Η ΜΙΑ έδρα: name (keyword) -> capability. Κανένα δεύτερο μητρώο.")

;; [audit#6] name (keyword) → namestring του αρχείου-ΙΔΙΟΚΤΗΤΗ. ΜΙΑ δυνατότητα,
;; ΕΝΑΣ ιδιοκτήτης: η σιωπηλή αντικατάσταση trusted↔advisor / fn / params / proof
;; από ΑΛΛΟ αρχείο γίνεται ΔΟΜΙΚΑ αδύνατη (ίδιο πρότυπο με command-seat-collision).
(defparameter *capability-owners* (make-hash-table :test 'eq)
  "name → owner file. Επανεγγραφή από ΑΛΛΟ αρχείο ⇒ capability-seat-collision.")

(define-condition capability-seat-collision (error)
  ((name     :initarg :name     :reader collision-capability-name)
   (owner    :initarg :owner    :reader collision-existing-owner)
   (claimant :initarg :claimant :reader collision-claimant))
  (:report (lambda (c s)
             (format s "ΣΥΓΚΡΟΥΣΗ ΕΔΡΑΣ ΔΥΝΑΤΟΤΗΤΑΣ «~A»: ιδιοκτήτης ~A, διεκδικητής ~A — ~
                        μία δυνατότητα έχει ΜΙΑ έδρα· καμία σιωπηλή αντικατάσταση trust/fn/schema."
                     (collision-capability-name c)
                     (collision-existing-owner c)
                     (collision-claimant c)))))

(define-condition capability-error (error)
  ((cap    :initarg :cap    :reader capability-error-cap)
   (reason :initarg :reason :reader capability-error-reason))
  (:report (lambda (c s)
             (format s "capability ~A: ~A"
                     (capability-error-cap c) (capability-error-reason c)))))

;;; ----------------------------------------------------------------------------
;;; Εγγραφή + δηλωτικός ορισμός
;;; ----------------------------------------------------------------------------

(defun %valid-trust-p (x) (member x '(:trusted :advisor)))

(defun %valid-param-spec-p (spec)
  "(:name :TYPE required-p) όπου :TYPE ∈ +param-types+ (ΚΛΕΙΣΤΟ σύνολο· άγνωστος
   τύπος = ΑΠΟΡΡΙΨΗ, όχι σιωπηλή αποδοχή — [audit#7])."
  (and (listp spec) (= 3 (length spec))
       (keywordp (first spec))
       (keywordp (second spec)) (member (second spec) +param-types+)
       (member (third spec) '(t nil))))

(defun register-capability (cap)
  "Εγγράφει μια δυνατότητα στη ΜΙΑ έδρα. Fail-closed έλεγχοι + ΝΟΜΟΣ ΜΙΑΣ ΕΔΡΑΣ:
   αν το NAME ανήκει ήδη σε ΑΛΛΟ αρχείο ⇒ capability-seat-collision (καμία σιωπηλή
   αντικατάσταση trust/fn/schema/proof). Επανεγγραφή από το ΙΔΙΟ αρχείο = idempotent
   reload (επιτρεπτή). [audit#6]"
  (let ((name (capability-name cap)))
    (unless (keywordp name)
      (error "capability: το όνομα πρέπει να είναι keyword, όχι ~S" name))
    (unless (%valid-trust-p (capability-trust cap))
      (error 'capability-error :cap name
             :reason ":trust πρέπει να είναι :trusted ή :advisor"))
    (unless (functionp (capability-fn cap))
      (error 'capability-error :cap name :reason ":fn πρέπει να είναι function"))
    (dolist (spec (capability-params cap))
      (unless (%valid-param-spec-p spec)
        (error 'capability-error :cap name
               :reason (format nil "άκυρο param spec ~S (θέλει (keyword τύπος∈~S t/nil))"
                               spec +param-types+))))
    ;; ΝΟΜΟΣ ΜΙΑΣ ΕΔΡΑΣ — owner binding (ίδιο πρότυπο & ίδια έδρα anonymity με
    ;; register-command). Fail-closed (re-review B-5): ανώνυμο runtime site ΔΕΝ
    ;; επαναδιεκδικεί υπάρχουσα έδρα — αλλιώς δύο runtime εγγραφές («<runtime>»≡
    ;; «<runtime>») θα αντικαθιστούσαν σιωπηλά trust/fn/schema/proof. Idempotent
    ;; reload ίδιου ΑΠΟΔΩΣΙΜΟΥ αρχείου επιτρέπεται.
    (let ((site  (orchestrator.paths:current-load-file))
          (owner (gethash name *capability-owners*)))
      (when (and owner (or (not (orchestrator.paths:load-site-attributable-p site))
                           (string/= owner site)))
        (error 'capability-seat-collision :name name :owner owner :claimant site))
      (setf (gethash name *capability-owners*) site))
    (setf (gethash name *capabilities*) cap)
    name))

(defun capability-owner (name)
  "Το αρχείο-έδρα της δυνατότητας NAME, ή NIL."
  (gethash name *capability-owners*))

(defmacro define-capability (name &key summary params (result :any) (trust :trusted)
                                       proof fn)
  "Ο ΕΝΑΣ δηλωτικός ορισμός δυνατότητας. HTTP/MCP/CLI είναι προβολές του — ποτέ
   ξεχωριστός χειρόγραφος ορισμός ανά επιφάνεια."
  `(register-capability
    (%make-capability :name ,name :summary ,(or summary "")
                      :params ',params :result ,result
                      :trust ,trust :proof ,proof :fn ,fn)))

;;; ----------------------------------------------------------------------------
;;; Ερωτήματα
;;; ----------------------------------------------------------------------------

(defun find-capability (name) (values (gethash name *capabilities*)))
(defun all-capabilities ()
  "Όλες, ταξινομημένες ντετερμινιστικά κατά όνομα (σταθερή προβολή σε κάθε επιφάνεια)."
  (sort (loop for c being the hash-values of *capabilities* collect c)
        #'string< :key (lambda (c) (string (capability-name c)))))
(defun trusted-capability-p (c) (eq (capability-trust c) :trusted))
(defun advisor-capability-p (c) (eq (capability-trust c) :advisor))

;;; ----------------------------------------------------------------------------
;;; Έλεγχος συμβολαίου + κλήση (με δομική επιβολή trust)
;;; ----------------------------------------------------------------------------

(defun %type-ok-p (ptype value)
  "Runtime type check ΑΚΡΙΒΩΣ πάνω στο +param-types+ (ecase ⇒ άγνωστος τύπος
   σφάλλει δομικά — καμία fail-open «(t t)» που αποδεχόταν κάθε άγνωστο τύπο [audit#7].
   Ο τύπος είναι ήδη εγγυημένος ∈ +param-types+ από την register-capability)."
  (ecase ptype
    (:string  (stringp value))
    (:integer (integerp value))
    (:boolean (member value '(t nil)))
    (:keyword (keywordp value))
    (:any     t)))

(defun %plist-has-key (plist key)
  (loop for (k v) on plist by #'cddr thereis (eq k key)))

(defun %check-params (cap args)
  "Επαληθεύει ARGS (plist) κατά το δηλωμένο συμβόλαιο: υποχρεωτικά παρόντα + τύποι.
   Σφάλμα ⇒ capability-error (fail-closed, ποτέ σιωπηλή αποδοχή)."
  (dolist (spec (capability-params cap) t)
    (let* ((pname (param-name spec))
           (ptype (param-type spec))
           (reqp  (param-required-p spec))
           (present (%plist-has-key args pname)))
      (cond
        ((and reqp (not present))
         (error 'capability-error :cap (capability-name cap)
                :reason (format nil "λείπει το υποχρεωτικό όρισμα ~A" pname)))
        ((and present (not (%type-ok-p ptype (getf args pname))))
         (error 'capability-error :cap (capability-name cap)
                :reason (format nil "όρισμα ~A: αναμενόταν ~A" pname ptype)))))))

(defun invoke-capability (name args &key require-trust)
  "Καλεί τη δυνατότητα NAME με ARGS (plist), αφού επαληθεύσει το συμβόλαιο.
   REQUIRE-TRUST t ⇒ αρνείται μη-:trusted δυνατότητα — η ΔΟΜΙΚΗ επιβολή του
   «κανένα LLM/σύμβουλος στο trusted path». Επιστρέφει το αποτέλεσμα του :fn."
  (let ((cap (find-capability name)))
    (unless cap
      (error 'capability-error :cap name :reason "άγνωστη δυνατότητα"))
    (when (and require-trust (not (trusted-capability-p cap)))
      (error 'capability-error :cap name
             :reason "advisor-only δυνατότητα ζητήθηκε σε trusted μονοπάτι — άρνηση"))
    (%check-params cap args)
    (apply (capability-fn cap) args)))
