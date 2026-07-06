;;;; source/execution-trace.lisp
;;;; ============================================================================
;;;; ΙΧΝΟΣ ΕΚΤΕΛΕΣΗΣ — legal execution provenance, ΟΧΙ logging
;;;; ============================================================================
;;;;
;;;; Κάθε κρίσιμη εκτέλεση αφήνει ΓΕΓΟΝΟΣ ΙΧΝΟΥΣ: ποια εντολή, ποιο σύμβολο,
;;;; ποια έδρα, ποια δεδομένα/κανόνες/έννομες καταστάσεις/αποδείξεις/πύλες.
;;;; Ο δεσμός με συμβόλαια/συστατικά γίνεται στο orchestrator.provenance
;;;; (στρωμάτωση: ο πυρήνας εδώ ΔΕΝ γνωρίζει τίποτα — φορτώνεται πρώτος ώστε
;;;; να τον καλούν ΟΛΕΣ οι έδρες, από τα URIs ως τη μηχανή συμπερασμού).
;;;;
;;;; ΑΣΦΑΛΕΙΑ: τα γεγονότα είναι ΜΟΝΟ δεδομένα (plists από strings/αριθμούς/
;;;; keywords/λίστες) — ποτέ κλεισίματα, ποτέ eval, ποτέ read εξωτερικής ύλης.
;;;; Το μαγαζί είναι append-only μέσα στη συνεδρία (μονότονα ids)· διαρκές
;;;; αρχείο ιχνών = ΔΗΛΩΜΕΝΟ ΧΡΕΟΣ (όχι σιωπηλά μισό).
;;;;
;;;; ΠΡΟΦΙΛ (φραγμένο κόστος): :off, :minimal (μόνο εντολές),
;;;; :legal-critical (προεπιλογή — παραγωγικός νομικός τρόπος), :full-debug.

(defpackage :orchestrator.trace
  (:use :cl)
  (:export #:*trace-profile* #:trace-enabled-p
           #:emit! #:with-span #:*current-span*
           #:tevent-id #:tevent-time #:tevent-kind #:tevent-severity
           #:tevent-command #:tevent-symbol #:tevent-package #:tevent-source
           #:tevent-data #:tevent-parent
           #:all-events #:event-count #:find-event #:last-event #:events-where
           #:last-conclusion-id #:note-conclusion!
           #:register-traced! #:traced-entry #:all-traced #:clear-events!))

(in-package :orchestrator.trace)

(defvar *trace-profile* :legal-critical
  "Ο παραγωγικός νομικός τρόπος έχει ΤΟΥΛΑΧΙΣΤΟΝ :legal-critical ενεργό.")

(defun trace-enabled-p (severity)
  (ecase *trace-profile*
    (:off nil)
    (:minimal (eq severity :command))
    (:legal-critical (member severity '(:command :legal-critical)))
    (:full-debug t)))

(defstruct (tevent (:constructor %make-tevent))
  id time kind severity command symbol package source data parent)

(defvar *events* (make-array 256 :adjustable t :fill-pointer 0)
  "Το μαγαζί ιχνών — append-only εντός συνεδρίας.")
(defvar *event-id* 0)
(defvar *current-span* nil "Το id του τρέχοντος span — ο γονέας των παιδιών.")
(defvar *current-command* nil "Η ρίζα: ποια εντολή τρέχει τώρα.")
(defvar *last-conclusion* nil "Το id του τελευταίου γεγονότος :conclusion.")
(defparameter +max-events+ 20000
  "Φραγμός μνήμης: πέραν αυτού, τα ΑΡΧΑΙΟΤΕΡΑ μισά συμπυκνώνονται (δηλωμένα).")

(defun %next-id () (incf *event-id*))

(defun emit! (kind &key (severity :legal-critical) symbol package source data
                        (id (%next-id)) (parent *current-span*))
  "Γεγονός ίχνους — ΜΟΝΟ δεδομένα. Επιστρέφει id ή NIL (προφίλ κλειστό)."
  (when (trace-enabled-p severity)
    (when (>= (fill-pointer *events*) +max-events+)
      (let ((keep (subseq *events* (floor +max-events+ 2))))
        (setf (fill-pointer *events*) 0)
        (loop for e across keep do (vector-push-extend e *events*))))
    (vector-push-extend
     (%make-tevent :id id :time (get-universal-time) :kind kind
                   :severity severity :command *current-command*
                   :symbol symbol :package package :source source
                   :data data :parent parent)
     *events*)
    id))

(defmacro with-span ((kind &key (severity :legal-critical) symbol package
                                source data-fn command) &body body)
  "Πειθαρχημένο δυναμικό πλαίσιο: δεσμεύει το span ως γονέα των εσωτερικών
   ιχνών, τρέχει το σώμα, και εκπέμπει ΕΝΑ γεγονός με το αποτέλεσμα (ή τη
   συνθήκη σφάλματος — που ΞΑΝΑσηματοδοτείται, ποτέ δεν καταπίνεται)."
  (let ((gid (gensym "ID")) (gout (gensym "OUT")) (gcond (gensym "C"))
        (gparent (gensym "P")))
    `(if (trace-enabled-p ,severity)
         (let* ((,gid (%next-id))
                (,gparent *current-span*)
                (*current-span* ,gid)
                (*current-command* (or ,command *current-command*)))
           (let ((,gout nil) (,gcond nil))
             (unwind-protect
                  (handler-bind ((serious-condition
                                   (lambda (c) (setf ,gcond (princ-to-string c)))))
                    (setf ,gout (multiple-value-list (progn ,@body))))
               (emit! ,kind :severity ,severity :symbol ,symbol :package ,package
                            :source ,source :id ,gid :parent ,gparent
                            :data (append (and ,data-fn (funcall ,data-fn (first ,gout)))
                                          (and ,gcond (list :condition ,gcond)))))
             (values-list ,gout)))
         (progn ,@body))))

(defun all-events () (coerce *events* 'list))
(defun event-count () (fill-pointer *events*))
(defun last-event () (and (plusp (fill-pointer *events*))
                          (aref *events* (1- (fill-pointer *events*)))))
(defun find-event (id)
  (find id (all-events) :key #'tevent-id))
(defun events-where (&key kind command symbol severity (limit 50))
  (let ((hits (remove-if-not
               (lambda (e)
                 (and (or (null kind) (eq (tevent-kind e) kind))
                      (or (null severity) (eq (tevent-severity e) severity))
                      (or (null command) (equal (tevent-command e) command))
                      (or (null symbol) (equal (tevent-symbol e) symbol))))
               (all-events))))
    (last hits limit)))

(defun note-conclusion! (id) (setf *last-conclusion* id))
(defun last-conclusion-id () *last-conclusion*)

(defun clear-events! ()
  "ΜΟΝΟ για πύλες/δοκιμές σε σκιά — η παραγωγή δεν σβήνει ίχνη."
  (setf (fill-pointer *events*) 0 *last-conclusion* nil))

;;; ── ΜΗΤΡΩΟ ΕΝΟΡΓΑΝΩΣΗΣ: ποια κρίσιμα σύμβολα αφήνουν ίχνος και ΠΩΣ ──────
;;; :direct = εκπέμπει το ίδιο· (:via "x") = καλύπτεται από το span του x·
;;; ό,τι legal-critical δεν είναι εδώ ούτε δηλωμένο χρέος ⇒ η πύλη κοκκινίζει.

(defvar *traced* (make-hash-table :test 'equal))

(defun register-traced! (name &key (how :direct) via)
  (setf (gethash (string-downcase name) *traced*)
        (list :how (if via :via how) :via via)))

(defun traced-entry (name) (gethash (string-downcase name) *traced*))

(defun all-traced ()
  (let ((out '()))
    (maphash (lambda (k v) (push (cons k v) out)) *traced*)
    (sort out #'string< :key #'car)))
