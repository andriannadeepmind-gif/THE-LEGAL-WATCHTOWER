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
   #:item-summary #:apply-decision #:auto-approvable-p
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
   (note       :initarg :note :accessor item-note :initform nil))
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

(defun %item-key (item)
  "Stable identity: kind|source|target — so the same flagged change is enqueued
   once even across repeated polls."
  (format nil "~A|~A|~A" (item-kind item) (item-source item) (item-target item)))

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
                              :by (getf learned :by) :note (getf learned :note))))
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
      (setf (gethash (%item-key item) (queue-memory queue))
            (list :decision decision :by by :note note :at (item-decided-at item))))
    item))

(defun learned-count (queue)
  "How many decisions the queue has memorised."
  (hash-table-count (queue-memory queue)))

(defun approved-operations (queue)
  "The operation payloads of APPROVED amendment items — ready to apply to the
   consolidation. (Rejected/pending items contribute nothing.)"
  (loop for i in (queue-items queue)
        when (and (typep i 'amendment-review) (eq (item-status i) :approved))
        collect (item-payload i)))

;;; ----------------------------------------------------------------------------
;;; persistence (serializable plist; injected by the caller, like the scheduler)
;;; ----------------------------------------------------------------------------

(defun %kind->class (kind)
  (find-if (lambda (c) (eq (class-kind c) kind))
           (closer-mop:class-direct-subclasses (find-class 'review-item))))

(defun queue-state (queue)
  "A serializable plist snapshot of the whole queue, including the learned
   decision memory."
  (list :items
        (loop for i in (queue-items queue)
              collect (list :id (item-id i) :kind (item-kind i)
                            :source (item-source i) :target (item-target i)
                            :payload (item-payload i) :confidence (item-confidence i)
                            :status (item-status i) :created-at (item-created-at i)
                            :decided-at (item-decided-at i) :decided-by (item-decided-by i)
                            :note (item-note i)))
        :memory
        (let ((acc '()))
          (maphash (lambda (k v) (push (cons k v) acc)) (queue-memory queue))
          (sort acc #'string< :key #'car))))

(defun restore-queue-state (queue state)
  "Rebuild QUEUE from a plist produced by QUEUE-STATE."
  (setf (queue-items queue) '())
  (clrhash (queue-index queue))
  (clrhash (queue-memory queue))
  (loop for (k . v) in (getf state :memory)
        do (setf (gethash k (queue-memory queue)) v))
  (dolist (p (getf state :items) queue)
    (let* ((class (or (%kind->class (getf p :kind)) (find-class 'review-item)))
           (item (make-instance class
                                :id (getf p :id) :source (getf p :source)
                                :target (getf p :target) :payload (getf p :payload)
                                :confidence (getf p :confidence) :status (getf p :status)
                                :created-at (getf p :created-at)
                                :decided-at (getf p :decided-at)
                                :decided-by (getf p :decided-by) :note (getf p :note))))
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
