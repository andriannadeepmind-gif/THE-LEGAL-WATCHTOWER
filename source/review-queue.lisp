;;;; source/review-queue.lisp
;;;; ============================================================================
;;;; HUMAN-IN-THE-LOOP REVIEW QUEUE  (the correctness guarantee, made operational)
;;;; ============================================================================
;;;;
;;;; The system applies and publishes HIGH-confidence changes automatically. Any
;;;; change it is not sure about — a medium/low-confidence amendment (addition,
;;;; new article, whole-law repeal), a duplicate that needed a version choice, a
;;;; parse anomaly — must NOT be published blindly. It is turned into a REVIEW
;;;; ITEM, blocked, and queued for a lawyer to APPROVE or REJECT. Only approved
;;;; items are then applied.
;;;;
;;;; This is built with CLOS + the MOP on purpose: an INTELLIGENT, extensible
;;;; design where new kinds of review are added declaratively and the queue
;;;; discovers, routes and audits them generically.
;;;;
;;;;   review-item-class   metaclass carrying :kind + :severity per item type
;;;;   define-review-kind  declarative item type (sets metaclass + summary method)
;;;;   item-summary        polymorphic, per-kind human description
;;;;   apply-decision      generic lifecycle; an :around method writes the audit
;;;;   review-item-kinds   MOP discovery (class-direct-subclasses)
;;;;   review-queue        persistent, de-duplicating store + decision API
;;;; ============================================================================

(defpackage :orchestrator.review
  (:use :cl)
  (:export
   ;; metaclass + base + discovery
   #:review-item-class #:review-item #:define-review-kind #:review-item-kinds
   #:item-kind #:item-severity
   ;; item types
   #:amendment-review #:duplicate-review #:anomaly-review #:source-conflict-review
   ;; item accessors / lifecycle
   #:item-id #:item-source #:item-target #:item-payload #:item-confidence
   #:item-status #:item-created-at #:item-decided-at #:item-decided-by #:item-note
   #:item-signature #:item-summary #:apply-decision #:auto-approvable-p
   ;; signed decision (τελική νομική αυθεντία — [audit#8 μέρος Β])
   #:*review-signing-key-path* #:*review-signer-id* #:*review-verify-key-path*
   #:decision-signature-status #:verify-decision-signature #:verify-item-decision
   #:restore-queue-error #:restore-queue-error-why
   ;; queue
   #:review-queue #:make-review-queue #:enqueue #:queue-items #:pending-items
   #:decide #:approved-operations #:queue-state #:restore-queue-state
   #:queue-pending-count #:queue-memory #:learned-count
   ;; integration
   #:amendment-record->review-items #:validation-report->review-items))

(in-package :orchestrator.review)

;;; ----------------------------------------------------------------------------
;;; MOP: a metaclass that carries each review type's KIND and SEVERITY
;;; ----------------------------------------------------------------------------

(defclass review-item-class (standard-class)
  ((kind     :initform :generic :accessor class-kind)
   (severity :initform :medium  :accessor class-severity))
  (:documentation "Metaclass for review items; carries the kind keyword and the
   default severity so the queue can route/sort generically."))

(defmethod closer-mop:validate-superclass
    ((class review-item-class) (super standard-class)) t)
(defmethod closer-mop:validate-superclass
    ((class standard-class) (super review-item-class)) t)

;;; ----------------------------------------------------------------------------
;;; base item
;;; ----------------------------------------------------------------------------

(defun %now ()
  "Transaction-time της ουράς ελέγχου μέσα από τη ΜΙΑ honest έδρα ρολογιού
   (iso-now). [0092/silent-fallback] Το παλιό find-symbol+ignore-errors με
   φαβρικαρισμένο «1970-01-01» fallback ΣΒΗΣΤΗΚΕ — γραμμή review χωρίς πραγματικό
   χρόνο είναι διεφθαρμένη, όχι σιωπηλά epoch. Ίδια έδρα με proposals/memory."
  (orchestrator.journal:iso-now))

;;; ----------------------------------------------------------------------------
;;; [audit#8 μέρος Β] Signed, non-repudiable decision record (τελική νομική αυθεντία)
;;; ----------------------------------------------------------------------------
;;; ΜΙΑ έδρα υπογραφής απόφασης: ΕΠΑΝΑΧΡΗΣΙΜΟΠΟΙΕΙ την orchestrator.jws-authority:sign-jws
;;; (RS256 detached, RFC 7515) — καμία δεύτερη κρυπτο-έδρα. Το κλειδί είναι ΤΟΥ ΔΙΚΗΓΟΡΟΥ
;;; (REVIEW_SIGNING_KEY): έτσι η υπογραφή αποδεικνύει ΠΟΙΟΣ αποφάσισε, όχι απλώς ότι έγινε
;;; μια απόφαση. Απόν κλειδί ⇒ :unsigned (ΤΙΜΙΑ: η ταυτότητα δεν αποδεικνύεται
;;; κρυπτογραφικά· ΠΟΤΕ σιωπηλή υπογραφή με κλειδί συστήματος που προσποιείται τον δικηγόρο).

(defvar *review-signing-key-path* nil
  "Path στο RSA private key ΤΟΥ ΔΙΚΗΓΟΡΟΥ. nil ⇒ αποφάσεις :unsigned (τίμια). ΚΑΘΑΡΗ
   ΕΔΡΑ: το var είναι η ΜΟΝΗ πηγή (μοτίβο legal-audit-system:*signing-private-key-path*)·
   το REVIEW_SIGNING_KEY env δένεται στο var στα entry points (serve-review/review-decide),
   ΟΧΙ εδώ — καμία σύζευξη της domain έδρας με env.")

(defvar *review-signer-id* "lawyer"
  "Key-id (kid) του υπογράφοντος δικηγόρου· δένεται από REVIEW_SIGNER_ID στα entry points.")

(defvar *review-verify-key-path* nil
  "Public key του δικηγόρου για ΕΠΑΛΗΘΕΥΣΗ υπογραφών ΠΡΙΝ τη δημοσίευση ([audit#10]).
   Set ⇒ ΜΟΝΟ εγκεκριμένες πράξεις με ΕΠΑΛΗΘΕΥΜΕΝΗ μη-αποποιήσιμη υπογραφή δημοσιεύονται
   (fail-closed: unsigned/αλλοιωμένη έγκριση ΔΕΝ φτάνει στο corpus). nil ⇒ καμία επαλήθευση
   configured (ΔΗΛΩΜΕΝΟ όριο· δένεται από REVIEW_VERIFY_KEY στο startup, μοτίβο signing key).")

(defun %canon-encode (&rest fields)
  "[re-review adv1-2] Η ΜΙΑ έδρα INJECTIVE κανονικής κωδικοποίησης πεδίων: prin1 τυπωμένης
   λίστας υπό standard-io-syntax + keyword package. Τα strings τυπώνονται quoted+escaped,
   άρα ΚΑΝΕΝΑ περιεχόμενο πεδίου δεν μπορεί να μιμηθεί το όριο άλλου πεδίου. Το παλιό
   «~A|~A|…» ΔΕΝ ήταν injective: (source=\"a\" target=\"b|c\") και (source=\"a|b\" target=\"c\")
   έδιναν ΙΔΙΟ string ⇒ μία υπογραφή εξουσιοδοτούσε ΔΥΟ διακριτές αλλαγές. Εδώ αυτό γίνεται
   δομικά αδύνατο (η κωδικοποίηση είναι αντιστρέψιμη/1-1)."
  (with-output-to-string (s)
    (with-standard-io-syntax
      (let ((*package* (find-package :keyword)))
        (prin1 fields s)))))

(defun %canonical-decision-statement (item-key decision by at)
  "Η ΚΑΝΟΝΙΚΗ δήλωση που υπογράφεται: δένει INJECTIVELY ταυτότητα/ρήμα/actor/χρόνο ώστε
   αλλαγή ΟΠΟΙΟΥΔΗΠΟΤΕ πεδίου να σπάει την υπογραφή (πλέον ΑΛΗΘΕΣ — καμία delimiter-alias).
   Το item-key περιέχει ΗΔΗ το πλήρες payload fingerprint (256-bit) — άρα η υπογραφή
   δένεται στο ΑΚΡΙΒΕΣ προτεινόμενο περιεχόμενο. Version /2 (breaking: injective + full hash)."
  (%canon-encode :review-decision/2
                 item-key (string-downcase (string decision)) (or by "") (or at "")))

(defun %sign-decision (item-key decision by at)
  "Signed decision record (data-only plist). FAIL-CLOSED: κλειδί ΠΑΡΟΝ αλλά αποτυχία
   υπογραφής ⇒ ΣΗΜΑ (καμία σιωπηλή υποβάθμιση σε unsigned — μοτίβο Blocker#1)."
  (let* ((stmt (%canonical-decision-statement item-key decision by at))
         (digest (orchestrator.journal:sha256-hex stmt))
         (key *review-signing-key-path*))
    (if key
        (let* ((kid *review-signer-id*)
               (res (orchestrator.jws-authority:sign-jws stmt key :algorithm :rs256 :kid kid)))
          (list :status :signed :alg "RS256" :kid kid
                :statement stmt :jws (getf res :jws) :digest digest))
        (list :status :unsigned :statement stmt :digest digest))))

(defun decision-signature-status (sig)
  "Το status ενός signed decision record: :signed | :unsigned | nil (καμία απόφαση)."
  (and sig (getf sig :status)))

(defun verify-decision-signature (sig public-key-path)
  "Επαληθεύει signed decision record κατά το PUBLIC-KEY-PATH του δικηγόρου (RS256 detached).
   (values ok-p reason). :unsigned ⇒ (values NIL :unsigned) (τίμια: μη αποδεδειγμένος actor).
   ΠΡΟΣΟΧΗ: επαληθεύει το jws κατά του ΑΠΟΘΗΚΕΥΜΕΝΟΥ :statement. Στο trust boundary
   (δημοσίευση) χρησιμοποίησε verify-item-decision που ΞΑΝΑ-ΠΑΡΑΓΕΙ τη δήλωση από το item —
   αλλιώς ένα signature-transplant (ίδιο :statement+:jws σε ΑΛΛΟ payload) θα «επαλήθευε»."
  (case (decision-signature-status sig)
    (:signed
     (handler-case
         (if (orchestrator.jws-authority:verify-jws
              (getf sig :jws) (getf sig :statement) public-key-path)
             ;; [re-review A-4 / κύκλος-2] Δέσε το ΑΠΟΘΗΚΕΥΜΕΝΟ :kid στο kid του
             ;; ΥΠΟΓΕΓΡΑΜΜΕΝΟΥ protected header — αλλιώς το recorded :kid είναι ανεπαλήθευτη
             ;; ετικέτα (θα μπορούσε να δηλώνει άλλον υπογράφοντα). ΑΠΑΙΤΕΙΤΑΙ ΠΑΡΟΝ, μη-κενό
             ;; kid και στις δύο πλευρές: το verify-jws ήδη απαιτεί μη-κενό signed kid, αλλά
             ;; ο έλεγχος εδώ πρέπει επίσης να απορρίπτει ΚΕΝΟ αποθηκευμένο :kid (nil==nil
             ;; θα περνούσε σιωπηλά — ανεπαλήθευτη ταυτότητα).
             (let ((stored-kid (getf sig :kid))
                   (signed-kid (orchestrator.jws-authority:jws-protected-kid (getf sig :jws))))
               (if (and (stringp stored-kid) (plusp (length stored-kid))
                        (stringp signed-kid) (plusp (length signed-kid))
                        (string= stored-kid signed-kid))
                   (values t :ok)
                   (values nil :kid-mismatch)))
             (values nil :bad-signature))
       (error (e) (values nil (format nil "~A" e)))))
    (t (values nil :unsigned))))

(defun %item-decision-verb (item)
  "Το ΡΗΜΑ της απόφασης από το ΤΡΕΧΟΝ status του item (:approved→:approve, :rejected→:reject)."
  (ecase (item-status item)
    (:approved :approve)
    (:rejected :reject)))

(defun verify-item-decision (item public-key-path)
  "[re-review CRITICAL] Επαληθεύει ότι η υπογραφή αντιστοιχεί στο ΤΡΕΧΟΝ ΠΕΡΙΕΧΟΜΕΝΟ του
   ITEM, όχι στο (μη-έμπιστο) αποθηκευμένο :statement. ΞΑΝΑ-ΠΑΡΑΓΕΙ την κανονική δήλωση από
   τα ΕΜΠΙΣΤΑ πεδία (%item-key με payload fingerprint | ρήμα | decided-by | decided-at) και
   ΑΠΑΙΤΕΙ ισότητα με το :statement ΠΡΙΝ εμπιστευτεί το jws. Έτσι ένα signature-transplant
   (γνήσιο (:statement+:jws) μεταφερμένο σε ΑΛΛΟ payload/item) ΑΠΟΤΥΓΧΑΝΕΙ: το recomputed
   statement δείχνει το ΝΕΟ περιεχόμενο, το jws έγινε για το ΠΑΛΙΟ ⇒ mismatch.
   (values ok-p reason)."
  (let ((sig (item-signature item)))
    (if (eq (decision-signature-status sig) :signed)
        (let ((expected (%canonical-decision-statement
                         (%item-key item) (%item-decision-verb item)
                         (item-decided-by item) (item-decided-at item))))
          (if (equal (getf sig :statement) expected)
              (verify-decision-signature sig public-key-path)  ; jws κατά (τώρα έμπιστου) statement
              (values nil :statement-item-mismatch)))
        (values nil :unsigned))))

(defclass review-item ()
  ((id         :initarg :id :accessor item-id)
   (source     :initarg :source :accessor item-source :initform nil
               :documentation "Originating act/law id (e.g. ΦΕΚ number).")
   (target     :initarg :target :accessor item-target :initform nil
               :documentation "Affected article eId / number.")
   (payload    :initarg :payload :accessor item-payload :initform nil
               :documentation "The proposed change (operation plist / details).")
   (confidence :initarg :confidence :accessor item-confidence :initform :medium)
   (status     :initarg :status :accessor item-status :initform :pending)
   (created-at :initarg :created-at :accessor item-created-at :initform (%now))
   (decided-at :initarg :decided-at :accessor item-decided-at :initform nil)
   (decided-by :initarg :decided-by :accessor item-decided-by :initform nil)
   (note       :initarg :note :accessor item-note :initform nil)
   ;; [audit#8 μέρος Β] signed decision record (data-only plist) — μη-αποποιήσιμη
   ;; υπογραφή της ανθρώπινης απόφασης· nil όσο εκκρεμεί.
   (signature  :initarg :signature :accessor item-signature :initform nil))
  (:metaclass review-item-class)
  (:documentation "One thing awaiting human approval before it can be published."))

(defgeneric item-kind (item)
  (:method ((item review-item)) (class-kind (class-of item))))
(defgeneric item-severity (item)
  (:method ((item review-item)) (class-severity (class-of item))))

(defgeneric item-summary (item)
  (:documentation "A one-line human description of what needs review.")
  (:method ((item review-item))
    (format nil "[~A/~A] ~A → ~A" (item-kind item) (item-confidence item)
            (or (item-source item) "?") (or (item-target item) "?"))))

(defgeneric auto-approvable-p (item)
  (:documentation "Whether ITEM may be applied without human approval. Default
   NIL — anything that reached the queue is, by definition, uncertain.")
  (:method ((item review-item)) nil))

(defgeneric apply-decision (item decision &key by note)
  (:documentation "Record DECISION (:approve | :reject) on ITEM, returning ITEM.")
  (:method ((item review-item) decision &key by note)
    (setf (item-status item) (ecase decision (:approve :approved) (:reject :rejected))
          (item-decided-at item) (%now)
          (item-decided-by item) (or by "unknown")
          (item-note item) note)
    item))

;; CLOS :around for a non-bypassable audit trail of every decision.
(defmethod apply-decision :around ((item review-item) decision &key by note)
  (declare (ignore note))
  (let ((result (call-next-method)))
    (when (find-package :log4cl)
      (ignore-errors
        (funcall (find-symbol "LOG-INFO" :log4cl-impl)
                 "REVIEW ~A ~A by ~A" (item-id item) decision (or by "?"))))
    result))

;;; ----------------------------------------------------------------------------
;;; declarative item kinds  (mirrors define-representation)
;;; ----------------------------------------------------------------------------

(defmacro define-review-kind (name (kind severity) &body summary-body)
  "Define review item type NAME with KIND + SEVERITY (stored on the metaclass)
   and an ITEM-SUMMARY method whose body is SUMMARY-BODY over the variable ITEM."
  `(progn
     (defclass ,name (review-item) () (:metaclass review-item-class))
     (setf (class-kind (find-class ',name)) ,kind
           (class-severity (find-class ',name)) ,severity)
     ,@(when summary-body
         `((defmethod item-summary ((item ,name)) ,@summary-body)))
     ',name))

(defun %op-phrase (op)
  (case (getf op :op)
    (:replace-text "αντικατάσταση κειμένου")
    (:repeal "κατάργηση")
    (:repeal-law "κατάργηση νόμου")
    (:mark-amended "τροποποίηση")
    (:insert (format nil "προσθήκη~@[ (~A)~]" (getf op :note)))
    (t (princ-to-string (getf op :op)))))

(define-review-kind amendment-review (:amendment :medium)
  (let ((op (item-payload item)))
    (format nil "Τροποποίηση προς έλεγχο [~A]: ~A στο ~A (νόμος ~A)"
            (item-confidence item) (%op-phrase op)
            (or (item-target item) (getf op :target)) (or (item-source item) "?"))))

(define-review-kind duplicate-review (:duplicate :high)
  (format nil "Διπλό άρθρο ~A — επιβεβαίωση τρέχουσας έκδοσης (νόμος ~A)"
          (item-target item) (or (item-source item) "?")))

(define-review-kind anomaly-review (:anomaly :high)
  (format nil "Ανωμαλία [~A]: ~A" (item-target item)
          (or (getf (item-payload item) :description) "δες λεπτομέρειες")))

(define-review-kind source-conflict-review (:source-conflict :high)
  ;; Sources disagree on a provision's authoritative text — the lawyer confirms
  ;; which channel is right (the acquisition layer never silently picks).
  (let ((cands (getf (item-payload item) :candidates)))
    (format nil "Διαφωνία πηγών για ~A: ~D εκδοχή(ές) [~A] — επιβεβαίωση αυθεντικού κειμένου"
            (or (item-target item) "?") (length cands) (or (item-source item) "?"))))

(defun review-item-kinds ()
  "All registered review item KIND keywords (discovered via the MOP)."
  (mapcar #'class-kind (closer-mop:class-direct-subclasses (find-class 'review-item))))

;;; ----------------------------------------------------------------------------
;;; the queue  (persistent, de-duplicating)
;;; ----------------------------------------------------------------------------

(defclass review-queue ()
  ((items :initarg :items :accessor queue-items :initform '())
   (index :accessor queue-index :initform (make-hash-table :test 'equal))
   ;; SELF-IMPROVEMENT: every decision is remembered by the item's stable
   ;; identity, so the same uncertain case is auto-resolved on a later run — the
   ;; lawyer teaches once, the machine applies it forever.
   (memory :accessor queue-memory :initform (make-hash-table :test 'equal)))
  (:documentation "An ordered, de-duplicating store of review items that LEARNS
   from past decisions and auto-applies them to identical future cases."))

(defun make-review-queue () (make-instance 'review-queue))

(defun %payload-fingerprint (item)
  "[re-review adv1-1] ΠΛΗΡΕΣ sha256 (64-hex, 256-bit) του κανονικού payload — ΟΧΙ πλέον
   truncated 16-hex/64-bit (birthday 2^32 ⇒ collision εφικτή από τον προτείνοντα). Στα
   256 bit η σύμπτωση δύο διαφορετικών payloads είναι ΔΟΜΙΚΑ αδύνατη. Ίδια κανονική μορφή
   με το save format (data-only prin1 υπό keyword package, μέσω της %canon-encode έδρας)."
  (orchestrator.journal:sha256-hex (%canon-encode (item-payload item))))

(defun %item-key (item)
  "Stable identity — INJECTIVE κωδικοποίηση (kind, source, target, full payload-fingerprint)
   μέσω της %canon-encode έδρας. [audit#9] Το payload ΑΝΗΚΕΙ στην ταυτότητα: δύο ΔΙΑΦΟΡΕΤΙΚΕΣ
   προτεινόμενες αλλαγές είναι ΔΥΟ ξεχωριστές προτάσεις (ξεχωριστός ανθρώπινος έλεγχος).
   [re-review adv1-2] Το παλιό «~A|~A» ΔΕΝ ήταν injective: μετατόπιση «|» μεταξύ source/target
   έδινε ΙΔΙΟ key για διακριτά items ⇒ μία έγκριση εξουσιοδοτούσε δύο αλλαγές. Πλέον αδύνατο."
  (%canon-encode :review-item/2
                 (item-kind item) (item-source item) (item-target item)
                 (%payload-fingerprint item)))

(defun enqueue (queue item)
  "Add ITEM unless an item with the same identity is already queued. Assigns a
   stable id from the identity. If a past decision for this identity is in the
   queue's memory, it is AUTO-APPLIED so the item never bothers the human again.
   Returns the (possibly existing) item."
  (let* ((key (%item-key item))
         (existing (gethash key (queue-index queue))))
    (or existing
        (progn
          (unless (and (slot-boundp item 'id) (item-id item))
            (setf (item-id item) key))
          (let ((learned (gethash key (queue-memory queue))))
            (when learned
              (apply-decision item (getf learned :decision)
                              :by (getf learned :by) :note (getf learned :note))
              ;; [re-review] Το decided-at πρέπει να είναι το ΑΡΧΙΚΟ decision-time (learned :at),
              ;; ΟΧΙ το %now της auto-εφαρμογής — αλλιώς το verify-item-decision recompute-άρει
              ;; στατεμεντ με ΑΛΛΟ χρόνο και η κληρονομημένη υπογραφή δεν content-verify-άρει.
              ;; Σημασιολογικά σωστό: ο άνθρωπος αποφάσισε στο :at· η auto-apply απλώς το επαναλαμβάνει.
              (when (getf learned :at)
                (setf (item-decided-at item) (getf learned :at)))
              ;; Η ταυτότητα (key) περιλαμβάνει το payload fingerprint ([audit#9]), άρα
              ;; η αποθηκευμένη υπογραφή ισχύει ΑΚΡΙΒΩΣ γι' αυτό το item — κληρονομείται.
              (setf (item-signature item) (getf learned :signature))))
          (setf (gethash key (queue-index queue)) item)
          (setf (queue-items queue) (append (queue-items queue) (list item)))
          item))))

(defun pending-items (queue)
  (remove-if-not (lambda (i) (eq (item-status i) :pending)) (queue-items queue)))

(defun queue-pending-count (queue) (length (pending-items queue)))

(defun decide (queue id decision &key by note)
  "Apply DECISION to the queued item whose id (or identity key) is ID, and REMEMBER
   it (keyed by the item's stable identity) so the same case auto-resolves later."
  (let ((item (or (gethash id (queue-index queue))
                  (find id (queue-items queue) :key #'item-id :test #'equal))))
    (when item
      (apply-decision item decision :by by :note note)
      ;; [audit#8 μέρος Β] Υπόγραψε την απόφαση (ΜΙΑ έδρα, στο μοναδικό choke point που
      ;; καλούν CLI/cockpit/web) και αποθήκευσέ την ΚΑΙ στο item ΚΑΙ στη μνήμη (durable).
      ;; [re-review adv1-4] Υπόγραψε/αποθήκευσε τον ΠΡΑΓΜΑΤΙΚΟ decided-by του item (που η
      ;; apply-decision έθεσε σε (or by "unknown")), ΟΧΙ τον raw by. Αλλιώς by=nil ⇒ statement
      ;; με "" αλλά item με "unknown" ⇒ verify-item-decision recompute mismatch ⇒ ΜΟΝΙΜΑ
      ;; αδημοσίευτη γνήσια έγκριση (δύο έδρες με διαφορετικό default = ΜΙΑ έδρα violation).
      (let* ((actor (item-decided-by item))
             (sig (%sign-decision (%item-key item) decision actor (item-decided-at item))))
        (setf (item-signature item) sig)
        (setf (gethash (%item-key item) (queue-memory queue))
              (list :decision decision :by actor :note note :at (item-decided-at item)
                    :signature sig))))
    item))

(defun learned-count (queue)
  "How many decisions the queue has memorised."
  (hash-table-count (queue-memory queue)))

(defun %decision-publishable-p (item)
  "[audit#10 + re-review] T αν η εγκεκριμένη πράξη επιτρέπεται να δημοσιευτεί.
     • verify key SET ⇒ ΑΠΑΙΤΕΙ content-bound επαληθευμένη υπογραφή (verify-item-decision,
       που ξανα-παράγει τη δήλωση από το item ⇒ signature-transplant ΑΠΟΤΥΓΧΑΝΕΙ). unsigned/
       αλλοιωμένη/μεταφερμένη έγκριση ΔΕΝ δημοσιεύεται.
     • verify key NIL + item :signed ⇒ FAIL-CLOSED: υπάρχει υπογραφή αλλά κανένα κλειδί για
       επαλήθευση ⇒ ΔΕΝ εμπιστευόμαστε (τέλος το fail-open «signing on, verify off» — κριτής A#3).
     • verify key NIL + item :unsigned/nil ⇒ t: δηλωμένο no-crypto mode (κανένα configured gate).
       ΤΙΜΙΟ ΟΡΙΟ: χωρίς verify key το review-queue αρχείο είναι ΕΜΠΙΣΤΗ είσοδος — η μόνη
       κρυπτογραφική προστασία ενεργοποιείται με REVIEW_VERIFY_KEY."
  (let ((sig (item-signature item)))
    (cond
      (*review-verify-key-path*
       (values (verify-item-decision item *review-verify-key-path*)))
      ((eq (decision-signature-status sig) :signed)
       nil)                              ; signed αλλά χωρίς κλειδί ⇒ μη επαληθεύσιμη ⇒ όχι δημοσίευση
      (t t))))                           ; no-crypto mode (δηλωμένο όριο)

(defun approved-operations (queue)
  "The operation payloads of APPROVED amendment items — ready to apply to the
   consolidation. (Rejected/pending items contribute nothing.) [audit#10] Όταν έχει
   ρυθμιστεί verify key, ΜΟΝΟ κρυπτογραφικά επαληθευμένες εγκρίσεις περνούν."
  (loop for i in (queue-items queue)
        when (and (typep i 'amendment-review) (eq (item-status i) :approved)
                  (%decision-publishable-p i))
        collect (item-payload i)))

;;; ----------------------------------------------------------------------------
;;; persistence (serializable plist; injected by the caller, like the scheduler)
;;; ----------------------------------------------------------------------------

(defun %kind->class (kind)
  (find-if (lambda (c) (eq (class-kind c) kind))
           (closer-mop:class-direct-subclasses (find-class 'review-item))))

;;; [audit#10] SCHEMA VALIDATION στο restore: το queue-state είναι θεσμική μνήμη
;;; ανθρώπινων αποφάσεων· ένα αλλοιωμένο/ασύμβατο record ΔΕΝ φορτώνεται σιωπηλά.
(defparameter +queue-state-version+ 2
  "Έκδοση σχήματος queue-state. v2: item-id δένεται στο payload ([audit#9]) + schema
   validation στο restore ([audit#10]).")

(defparameter +admissible-statuses+ '(:pending :approved :rejected)
  "Τα ΜΟΝΑ έγκυρα status ενός review item — οτιδήποτε άλλο = διεφθαρμένο record.")

(define-condition restore-queue-error (error)
  ((why :initarg :why :reader restore-queue-error-why :initform "μη έγκυρο queue-state"))
  (:report (lambda (c s) (format s "restore-queue: ~A" (restore-queue-error-why c)))))

(defun %resolve-kind-strict (kind)
  "Η κλάση για το KIND, ή ΣΗΜΑ. ΚΑΝΕΝΑ σιωπηλό downgrade σε γενικό review-item (ο κριτής
   #10: άγνωστο kind χανόταν ⇒ item χωρίς τη σωστή σημασιολογία summary/severity)."
  (or (%kind->class kind)
      (error 'restore-queue-error
             :why (format nil "άγνωστο review kind ~S — καμία σιωπηλή υποβάθμιση σε review-item" kind))))

(defun %validate-item-record (p)
  "Fail-closed έλεγχος ΕΝΟΣ persisted item plist. Σφάλμα ⇒ restore-queue-error."
  (let ((status (getf p :status))
        (kind (getf p :kind)))
    (unless (member status +admissible-statuses+)
      (error 'restore-queue-error :why (format nil "μη αποδεκτό status ~S (∈ ~S)" status +admissible-statuses+)))
    (%resolve-kind-strict kind)                         ; άγνωστο kind ⇒ σήμα
    ;; Decision provenance: αποφασισμένο item ΧΩΡΙΣ ποιος/πότε = διεφθαρμένη εγγραφή.
    (when (member status '(:approved :rejected))
      (unless (and (getf p :decided-by) (getf p :decided-at))
        (error 'restore-queue-error
               :why (format nil "~A item χωρίς decided-by/decided-at (καμία provenance)" status))))
    t))

(defun %validate-memory-entry (k v)
  "[re-review C#4a CRITICAL] Fail-closed έλεγχος ΜΙΑΣ learned-decision εγγραφής μνήμης.
   Η μνήμη auto-approve-άρει ΜΕΛΛΟΝΤΙΚΑ items (enqueue) ⇒ διεφθαρμένη/forged εγγραφή =
   αυτόματη έγκριση χωρίς ανθρώπινο έλεγχο. Δομικός έλεγχος: key string· :decision ∈
   {:approve :reject}· :at παρόν (provenance). (Η κρυπτογραφική εγγύηση προστίθεται όταν
   υπάρχει verify key: η κληρονομημένη :signature content-verify-άρεται στο publish gate.)"
  (unless (stringp k)
    (error 'restore-queue-error :why (format nil "memory key δεν είναι string: ~S" k)))
  (unless (and (listp v) (member (getf v :decision) '(:approve :reject)))
    (error 'restore-queue-error
           :why (format nil "memory[~A]: μη αποδεκτό :decision ~S" k (getf v :decision))))
  (unless (getf v :at)
    (error 'restore-queue-error :why (format nil "memory[~A]: λείπει :at (καμία provenance)" k)))
  t)

(defun queue-state (queue)
  "A serializable plist snapshot of the whole queue, including the learned decision
   memory. Φέρει :version για schema-aware restore ([audit#10])."
  (list :version +queue-state-version+
        :items
        (loop for i in (queue-items queue)
              collect (list :id (item-id i) :kind (item-kind i)
                            :source (item-source i) :target (item-target i)
                            :payload (item-payload i) :confidence (item-confidence i)
                            :status (item-status i) :created-at (item-created-at i)
                            :decided-at (item-decided-at i) :decided-by (item-decided-by i)
                            :note (item-note i) :signature (item-signature i)))
        :memory
        (let ((acc '()))
          (maphash (lambda (k v) (push (cons k v) acc)) (queue-memory queue))
          (sort acc #'string< :key #'car))))

(defun restore-queue-state (queue state)
  "Rebuild QUEUE from a plist produced by QUEUE-STATE, με FAIL-CLOSED schema validation
   ([audit#10]): μη αποδεκτό status / άγνωστο kind / έγκριση χωρίς provenance ⇒
   restore-queue-error (καμία σιωπηλή φόρτωση διεφθαρμένης θεσμικής μνήμης). Το item-id
   ΕΠΑΝΥΠΟΛΟΓΙΖΕΤΑΙ από το περιεχόμενο (%item-key, δένει payload [audit#9]) — ένα
   χειροκίνητα αλλαγμένο payload ΔΕΝ μπορεί να κληρονομήσει την ταυτότητα/έγκριση άλλου."
  ;; Πρώτα ΕΠΙΚΥΡΩΣΕ τα πάντα (items ΚΑΙ μνήμη)· καμία μερική μεταβολή αν κάτι είναι άκυρο.
  (dolist (p (getf state :items)) (%validate-item-record p))
  (loop for (k . v) in (getf state :memory) do (%validate-memory-entry k v))
  (setf (queue-items queue) '())
  (clrhash (queue-index queue))
  (clrhash (queue-memory queue))
  (loop for (k . v) in (getf state :memory)
        do (setf (gethash k (queue-memory queue)) v))
  (dolist (p (getf state :items) queue)
    (let* ((class (%resolve-kind-strict (getf p :kind)))
           (item (make-instance class
                                :source (getf p :source)
                                :target (getf p :target) :payload (getf p :payload)
                                :confidence (getf p :confidence) :status (getf p :status)
                                :created-at (getf p :created-at)
                                :decided-at (getf p :decided-at)
                                :decided-by (getf p :decided-by) :note (getf p :note)
                                :signature (getf p :signature))))
      ;; id ΑΠΟ ΤΟ ΠΕΡΙΕΧΟΜΕΝΟ (όχι εμπιστοσύνη του stored) — δομικό binding id↔payload.
      (setf (item-id item) (%item-key item))
      (setf (gethash (item-id item) (queue-index queue)) item)
      (setf (queue-items queue) (append (queue-items queue) (list item))))))

;;; ----------------------------------------------------------------------------
;;; integration: turn flagged data into review items
;;; ----------------------------------------------------------------------------

(defun %rget (record key)
  (cond ((hash-table-p record) (gethash key record))
        ((and (listp record) (consp (first record))) (cdr (assoc key record :test #'equal)))
        (t nil)))

(defun amendment-record->review-items (record)
  "From an amendment RECORD (consolidation-bridge shape), build review items for
   its flagged \"review\" operations (medium/low confidence). High-confidence
   \"operations\" are NOT queued — they apply automatically."
  (let ((source (%rget record "id")))
    (loop for op in (%rget record "review")
          collect (make-instance 'amendment-review
                                 :source source :target (getf op :target)
                                 :payload op :confidence (or (getf op :confidence) :medium)))))

(defun validation-report->review-items (report &key source)
  "From a codification validation REPORT (plist with :duplicates /
   :duplicate-details), build duplicate review items for human confirmation."
  (loop for d in (getf report :duplicates)
        collect (make-instance 'duplicate-review
                               :source source :target d
                               :confidence :high
                               :payload (cdr (assoc d (getf report :duplicate-details)
                                                    :test #'equal)))))
