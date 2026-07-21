;;;; source/knowledge-graph.lisp
;;;; ============================================================================
;;;; Ο ΕΝΙΑΙΟΣ ΣΗΜΑΣΙΟΛΟΓΙΚΟΣ META-KNOWLEDGE GRAPH — CLOS/MOP
;;;; ============================================================================
;;;;
;;;; Ένα υπόστρωμα: μνήμη + γνώση + εαυτός. Κάθε ΙΣΧΥΡΙΣΜΟΣ (κόμβος ή ακμή)
;;;; γεννιέται με ΤΡΙΑ αναλλοίωτα, επιβαλλόμενα ΕΚ ΚΑΤΑΣΚΕΥΗΣ από το metaclass
;;;; ASSERTION-CLASS (initialize-instance) — όχι προαιρετικές σημειώσεις:
;;;;
;;;;   1. ΠΡΟΕΛΕΥΣΗ      — κανένας ισχυρισμός χωρίς πηγή. «Γεγονός» ανώνυμα =
;;;;                       αδύνατο. (0 λάθος στα δεδομένα.)
;;;;   2. ΧΡΟΝΙΚΟΤΗΤΑ    — κάθε ισχυρισμός φέρει διάστημα ισχύος [from,to)
;;;;                       (point-in-time law· nil άκρο = χωρίς όριο). Ο νόμος
;;;;                       αλλάζει· ο γράφος ξέρει ΠΟΤΕ ίσχυε τι.
;;;;   3. ΑΙΤΙΟΛΟΓΗΣΗ    — κάθε ισχυρισμός ξέρει ΓΙΑΤΙ: :asserted (από πηγή) ή
;;;;                       :derived (από κανόνα + προϋποθέσεις — σπόρος JTMS,
;;;;                       ανατρέψιμος). «Γιατί το πιστεύεις;» = δεδομένο.
;;;;
;;;; Και ο ΦΡΑΓΜΟΣ Self/World (anti-confusion): το επίπεδο :self (ταυτότητα,
;;;; σύνταγμα, κανόνες) είναι READ-ONLY στην εξωτερική προέλευση — το σύστημα δεν
;;;; μπερδεύει «νόμο για την απάτη» με τη δική του ταυτότητα.
;;;;
;;;; self-as-data: ο εαυτός ζει ως κόμβοι, ερωτήσιμος από τον ίδιο γράφο. Αλλά
;;;; ΠΡΟΤΑΣΗ αλλαγής, ΟΧΙ αυτόνομη μετάλλαξη — κάθε αλλαγή περνά από σκιώδη πύλη.

(defpackage :orchestrator.graph
  (:use :cl)
  (:export #:assertion #:assertion-source #:assertion-validity #:assertion-justification
           #:assertion-retracted #:why #:retract #:holds-p
           #:validity #:make-validity #:validity-from #:validity-to #:valid-at-p
           #:justification #:asserted #:derived #:justification-kind
           #:justification-basis #:justification-antecedents
           #:graph-node #:node-id #:node-label #:node-layer #:node-prop #:node-props
           #:graph-edge #:edge-from #:edge-rel #:edge-to
           #:knowledge-graph #:*graph* #:make-graph
           #:add-node #:node #:relate #:edges #:neighbors #:query-nodes
           #:in-edges #:predecessors #:node-count #:edge-count
           #:save-graph #:load-graph
           #:*origin* #:with-origin #:+self+ #:+world+ #:+meta+ #:layer-writable-p))

(in-package :orchestrator.graph)

(defconstant +self+ :self  "Επίπεδο ταυτότητας — READ-ONLY στην εξωτερική προέλευση.")
(defconstant +world+ :world "Επίπεδο κόσμου — τα δεδομένα του δικαίου.")
(defconstant +meta+ :meta  "Επίπεδο μετα-γνώσης — γνώση για τη γνώση.")

(defvar *origin* :system
  "Ποιος ΓΡΑΦΕΙ τώρα: :creator / :self / :world / :external / :system.")
(defmacro with-origin ((origin) &body body) `(let ((*origin* ,origin)) ,@body))

;;; ── ΧΡΟΝΙΚΟΤΗΤΑ: διάστημα ισχύος [from, to) — nil άκρο = χωρίς όριο ──
;;; Ημερομηνίες ISO-8601 (strings). ΚΑΜΙΑ δική μας αριθμητική διαστημάτων: η κρίση
;;; παραπέμπει στο L3 (orchestrator.temporal:date-in-interval-p) — το ίδιο μισάνοιχτο
;;; [from,to) με όλο το χρονικό δίκαιο του συστήματος. ΜΙΑ υλοποίηση.
(defstruct (validity (:constructor make-validity (&optional from to))) from to)

(defun valid-at-p (v when)
  "Ισχύει η V τη στιγμή WHEN (ISO-8601 string); WHEN nil ⇒ αγνόησε τον χρόνο.
   V nil ⇒ πάντα έγκυρο. Η σύγκριση διαστημάτων γίνεται από το orchestrator.temporal."
  (or (null when) (null v)
      (orchestrator.temporal:date-in-interval-p when (validity-from v) (validity-to v))))

;;; ── ΑΙΤΙΟΛΟΓΗΣΗ: :asserted (πηγή) ή :derived (κανόνας + προϋποθέσεις) ──
(defstruct (justification (:constructor %just)) kind basis antecedents)
(defun asserted (source) (%just :kind :asserted :basis source))
(defun derived (rule &rest antecedents) (%just :kind :derived :basis rule :antecedents antecedents))

;;; ── MOP: τα τρία αναλλοίωτα ως ιδιότητα εκ κατασκευής ──
(defclass assertion-class (standard-class) ()
  (:documentation "Metaclass ισχυρισμών: κανένας δεν υπάρχει χωρίς πηγή+αιτιολόγηση."))
(defmethod sb-mop:validate-superclass ((c assertion-class) (s standard-class)) t)

(defclass assertion ()
  ((source        :initarg :source        :reader assertion-source        :initform nil)
   (validity      :initarg :validity      :reader assertion-validity      :initform nil)
   (justification :initarg :justification :accessor assertion-justification :initform nil)
   (retracted     :initarg :retracted     :accessor assertion-retracted   :initform nil))
  (:metaclass assertion-class))

(defmethod initialize-instance :after ((a assertion) &key)
  (unless (assertion-source a)
    (error "ισχυρισμός ΧΩΡΙΣ ΠΗΓΗ — αδύνατο (προέλευση εκ κατασκευής)"))
  ;; κάθε ισχυρισμός ξέρει το ΓΙΑΤΙ· χωρίς ρητή αιτιολόγηση ⇒ ΔΗΛΩΜΕΝΟ από την πηγή
  (unless (assertion-justification a)
    (setf (assertion-justification a) (asserted (assertion-source a)))))

(defun why (a)
  "Η αιτιολόγηση ενός ισχυρισμού, αναγνώσιμη."
  (let ((j (assertion-justification a)))
    (ecase (justification-kind j)
      (:asserted (format nil "δηλωμένο από: ~A" (justification-basis j)))
      (:derived  (format nil "παράχθηκε από κανόνα «~A» βάσει: ~{~A~^, ~}"
                         (justification-basis j) (justification-antecedents j))))))

(defun retract (a &optional (reason t)) (setf (assertion-retracted a) reason) a)
(defun holds-p (a &optional when)
  "Ισχύει ΤΩΡΑ (ή τη στιγμή WHEN); μη-ανακληθέν ΚΑΙ χρονικά έγκυρο."
  (and (not (assertion-retracted a)) (valid-at-p (assertion-validity a) when)))

;;; ── Κόμβος & Ακμή ως ισχυρισμοί ──
(defclass graph-node (assertion)
  ((id    :initarg :id    :reader node-id)
   (label :initarg :label :reader node-label :initform nil)
   (layer :initarg :layer :reader node-layer :initform +world+)
   (props :initarg :props :accessor node-props :initform nil))
  (:metaclass assertion-class))
(defun node-prop (node key &optional default) (getf (node-props node) key default))

(defclass graph-edge (assertion)
  ((from :initarg :from :reader edge-from)
   (rel  :initarg :rel  :reader edge-rel)
   (to   :initarg :to   :reader edge-to))
  (:metaclass assertion-class))

;;; ── Ο γράφος ──
(defclass knowledge-graph ()
  ((nodes :initform (make-hash-table :test 'equal) :reader %nodes)
   (out   :initform (make-hash-table :test 'equal) :reader %out)
   (in    :initform (make-hash-table :test 'equal) :reader %in)))
(defun make-graph () (make-instance 'knowledge-graph))
(defvar *graph* (make-graph) "Ο ενεργός ενιαίος γράφος.")

(defun layer-writable-p (layer &optional (origin *origin*))
  "Ο φραγμός: :self είναι READ-ONLY όταν η προέλευση είναι :external."
  (not (and (eq layer +self+) (eq origin :external))))

(defun add-node (id &key label (layer +world+) source props validity justification
                      (graph *graph*))
  "Πρόσθεσε/ενημέρωσε κόμβο με τα τρία αναλλοίωτα. Ο φραγμός Self απορρίπτει
   εξωτερική εγγραφή στο :self."
  (unless (layer-writable-p layer)
    (error "ΑΡΝΗΣΗ φραγμού: εξωτερική προέλευση δεν γράφει στο επίπεδο ~A (ταυτότητα)" layer))
  (let ((n (make-instance 'graph-node :id id :label label :layer layer
                          :source (or source *origin*) :props props
                          :validity validity :justification justification)))
    (setf (gethash id (%nodes graph)) n)
    n))

(defun node (id &optional (graph *graph*)) (gethash id (%nodes graph)))

(defun relate (from rel to &key source validity justification (graph *graph*))
  "Σχέση FROM --REL--> TO ως ισχυρισμός (προέλευση+χρόνος+αιτιολόγηση εκ
   κατασκευής). Ακμή που θα άγγιζε κόμβο :self από εξωτερική προέλευση
   απορρίπτεται."
  (let ((fn (node from graph)))
    (when (and fn (eq (node-layer fn) +self+) (not (layer-writable-p +self+)))
      (error "ΑΡΝΗΣΗ φραγμού: εξωτερική προέλευση δεν τροποποιεί τον Εαυτό (~A)" from)))
  (let ((e (make-instance 'graph-edge :from from :rel rel :to to
                          :source (or source *origin*)
                          :validity validity :justification justification)))
    (push e (gethash from (%out graph)))
    (push e (gethash to (%in graph)))   ; αντίστροφο ευρετήριο — για «τι εξαρτάται από»
    e))

(defun edges (id &key at (graph *graph*))
  "Οι ακμές του κόμβου· με :AT φιλτράρει σε όσες ΙΣΧΥΟΥΝ τη στιγμή εκείνη
   (point-in-time). Χωρίς :AT, όσες ισχύουν τώρα (μη-ανακληθείσες)."
  (loop for e in (reverse (gethash id (%out graph)))
        when (holds-p e at) collect e))

(defun neighbors (id rel &key at (graph *graph*))
  (loop for e in (edges id :at at :graph graph)
        when (eql (edge-rel e) rel) collect (edge-to e)))

(defun in-edges (id &key at (graph *graph*))
  "Οι ΕΙΣΕΡΧΟΜΕΝΕΣ ακμές (ποιος δείχνει στο ID) — για «τι εξαρτάται από»."
  (loop for e in (reverse (gethash id (%in graph)))
        when (holds-p e at) collect e))

(defun predecessors (id rel &key at (graph *graph*))
  (loop for e in (in-edges id :at at :graph graph)
        when (eql (edge-rel e) rel) collect (edge-from e)))

(defun query-nodes (pred &optional (graph *graph*))
  (loop for n being the hash-values of (%nodes graph) when (funcall pred n) collect n))
(defun node-count (&optional (graph *graph*)) (hash-table-count (%nodes graph)))
(defun edge-count (&optional (graph *graph*))
  (loop for es being the hash-values of (%out graph) sum (length es)))

;;; ============================================================================
;;; ΣΕΙΡΙΟΠΟΙΗΣΗ (Φάση 3) — ο γράφος επιβιώνει της διεργασίας
;;; ============================================================================
;;;
;;; Ο γράφος είναι ΠΑΡΑΓΩΓΟ των εισόδων του (corpus, αποφάσεις, εαυτός) — το
;;; στιγμιότυπο δεν είναι δεύτερη αλήθεια, είναι cache με ΤΑΥΤΟΤΗΤΑ: ο καλών
;;; αποθηκεύει μαζί του τα μεταδεδομένα φρεσκάδας (:meta, πχ αποτύπωμα εισόδων)
;;; και ΔΕΝ το φορτώνει αν οι είσοδοι άλλαξαν. Μορφή: sexp-γραμμές (μία ανά
;;; ισχυρισμό), *read-eval* nil, ατομική γραφή (tmp+rename) — τα ιδιώματα του
;;; συστήματος, καμία νέα εφεύρεση. Διατηρούνται ΚΑΙ τα τρία αναλλοίωτα ΚΑΙ η
;;; κατάσταση ανάκλησης — τίποτα δεν «ξαναγεννιέται» αλλιώτικο στη φόρτωση.

(defun %validity->list (v) (when v (list (validity-from v) (validity-to v))))
(defun %list->validity (l) (when l (make-validity (first l) (second l))))

(defun %just->list (j)
  (when j
    (ecase (justification-kind j)
      (:asserted (list :asserted (justification-basis j)))
      (:derived  (list :derived (justification-basis j)
                       (justification-antecedents j))))))

(defun %list->just (l)
  (when l
    (ecase (first l)
      (:asserted (asserted (second l)))
      (:derived  (apply #'derived (second l) (third l))))))

(defun save-graph (path &key (graph *graph*) meta)
  "Γράψε ΟΛΟΚΛΗΡΟ τον γράφο στο PATH, ατομικά. META: plist του καλούντος
   (πχ (:stamp αποτύπωμα-εισόδων)) — επιστρέφεται αυτούσιο από το load-graph
   ώστε η φρεσκάδα να κρίνεται από ΑΥΤΟΝ που ξέρει τις εισόδους."
  (let ((content
          (with-output-to-string (s)
            (let ((*package* (find-package :keyword))
                  (*print-readably* nil) (*print-escape* t)
                  (*print-pretty* nil) (*print-circle* nil))
              (format s "~S~%" (list* :knowledge-graph 1 meta))
              (loop for n being the hash-values of (%nodes graph) do
                (format s "~S~%"
                        (list :node :id (node-id n) :label (node-label n)
                              :layer (node-layer n) :source (assertion-source n)
                              :props (node-props n)
                              :validity (%validity->list (assertion-validity n))
                              :retracted (assertion-retracted n)
                              :just (%just->list (assertion-justification n)))))
              (loop for es being the hash-values of (%out graph) do
                (dolist (e (reverse es))   ; σειρά εισαγωγής
                  (format s "~S~%"
                          (list :edge :from (edge-from e) :rel (edge-rel e)
                                :to (edge-to e) :source (assertion-source e)
                                :validity (%validity->list (assertion-validity e))
                                :retracted (assertion-retracted e)
                                :just (%just->list (assertion-justification e))))))))))
    (orchestrator.journal:write-file-atomic path content)
    path))

(defun load-graph (path)
  "Φόρτωσε γράφο από στιγμιότυπο. Επιστρέφει (values graph κόμβοι ακμές meta)
   ή NIL αν το αρχείο λείπει/δεν είναι στιγμιότυπο γράφου. Σφάλμα ανάγνωσης
   σηματοδοτείται — ο καλών αποφασίζει (συνήθως: πλήρες ξαναχτίσιμο)."
  ;; [κύκλος-2] ΜΙΑ safe-read έδρα: read-data-file-sequence (ΟΛΑ τα forms pre-scanned:
  ;; *read-eval* nil + wholesale #-deny + depth/atom/byte caps + total data-only) αντί
  ;; σκόρπιου streaming read· απόν/κενό → NIL, μη αναγνώσιμο → ΣΦΑΛΜΑ (ο καλών ξαναχτίζει).
  (multiple-value-bind (forms status)
      (orchestrator.safe-read:read-data-file-sequence path)
    (case status
      (:empty (return-from load-graph nil))
      (:ok nil)
      (t (error "load-graph: μη αναγνώσιμο στιγμιότυπο γράφου (~A): ~A" status path)))
    (let ((graph (make-graph)) (nn 0) (ne 0)
          (header (first forms)))
      (progn
        (unless (and (listp header) (eq (first header) :knowledge-graph))
          (return-from load-graph nil))
        (dolist (form (rest forms))
          (ecase (first form)
            (:node
             (destructuring-bind (&key id label layer source props validity retracted just)
                 (rest form)
               (let ((n (make-instance 'graph-node
                                       :id id :label label :layer layer :source source
                                       :props props
                                       :validity (%list->validity validity)
                                       :retracted retracted
                                       :justification (%list->just just))))
                 (setf (gethash id (%nodes graph)) n)
                 (incf nn))))
            (:edge
             (destructuring-bind (&key from rel to source validity retracted just)
                 (rest form)
               (let ((e (make-instance 'graph-edge
                                       :from from :rel rel :to to :source source
                                       :validity (%list->validity validity)
                                       :retracted retracted
                                       :justification (%list->just just))))
                 (push e (gethash from (%out graph)))
                 (push e (gethash to (%in graph)))
                 (incf ne))))))
        (values graph nn ne (cddr header))))))
