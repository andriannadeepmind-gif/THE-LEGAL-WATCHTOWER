;;;; source/components.lisp
;;;; ============================================================================
;;;; ΤΟ ΜΗΤΡΩΟ ΣΥΣΤΑΤΙΚΩΝ — κάθε όργανο του Ιδρύματος ταυτοποιήσιμο ή άγνωστο
;;;; ============================================================================
;;;;
;;;; Το canonical component registry: κάθε συστατικό (σύστημα ASDF, αρχείο,
;;;; πακέτο, σύμβολο, πύλη) έχει ΤΑΥΤΟΤΗΤΑ (μοναδικό id), είδος, γονέα, ρόλο,
;;;; hash (όπου έχει ύλη), και μεταδεδομένα — και συνδέεται με ΑΚΜΕΣ σε γράφο
;;;; (σύστημα→αρχείο→πακέτο→σύμβολο→συμβόλαιο→ικανότητα→πύλη). «Αν κάτι δεν
;;;; μπορεί να ταυτοποιηθεί, δεν θεωρείται γνωστό από το σύστημα.»
;;;;
;;;; Εδώ ζουν ΜΟΝΟ οι δομές + το μητρώο + οι ερωτήσεις (καθαρός πυρήνας).
;;;; Η ΚΑΤΑΣΚΕΥΗ από τη ζωντανή εικόνα ζει στο component-scan (διαχωρισμός:
;;;; το μητρώο δεν ξέρει από ASDF/MOP — μόνο από ταυτότητες και ακμές).

(defpackage :orchestrator.components
  (:use :cl)
  (:export #:component #:register-component! #:find-component #:all-components
           #:components-of-kind #:clear-registry! #:duplicate-component-id
           #:component-id #:component-kind #:component-name #:component-parent
           #:component-role #:component-hash #:component-meta #:meta-get
           #:add-edge! #:all-edges #:edges-from #:edges-to #:reachable-from))

(in-package :orchestrator.components)

(defstruct (component (:constructor %make-component))
  id      ; string — ΜΟΝΑΔΙΚΟ, κανονικό: "system:x" "file:path" "package:p" "symbol:p::s" "gate:--x"
  kind    ; :system :file :package :symbol :gate
  name    ; το γυμνό όνομα
  parent  ; id γονέα (αρχείο→σύστημα, σύμβολο→πακέτο…)
  role    ; θεσμικός ρόλος/αίθουσα (string ή NIL — το NIL είναι ΟΡΑΤΟ χρέος)
  hash    ; SHA-256 για αρχεία· NIL όπου δεν έχει ύλη
  meta)   ; plist: :capabilities :contracts :tests :packages :exports :file …

(defvar *components* (make-hash-table :test 'equal)
  "id → component. Η ΜΙΑ πηγή ταυτότητας συστατικών.")

(defvar *edges* '()
  "Λίστα (kind from-id to-id) — ο γράφος εξαρτήσεων/παροχής, ντετερμινιστικός.")

(define-condition duplicate-component-id (error)
  ((id :initarg :id :reader dup-id))
  (:report (lambda (c s)
             (format s "ΔΙΠΛΗ ΤΑΥΤΟΤΗΤΑ ΣΥΣΤΑΤΙΚΟΥ: «~A» — δύο συστατικά δεν ~
μπορούν να διεκδικούν την ίδια κανονική ταυτότητα." (dup-id c)))))

(defun clear-registry! ()
  (clrhash *components*)
  (setf *edges* '()))

(defun register-component! (id kind name &key parent role hash meta)
  "Εγγραφή συστατικού. Διπλό id = ΣΦΑΛΜΑ (φωναχτά, ποτέ σιωπηλή αντικατάσταση)."
  (when (gethash id *components*)
    (error 'duplicate-component-id :id id))
  (setf (gethash id *components*)
        (%make-component :id id :kind kind :name name :parent parent
                         :role role :hash hash :meta meta)))

(defun find-component (id) (gethash id *components*))

(defun all-components ()
  (let ((out '()))
    (maphash (lambda (k v) (declare (ignore k)) (push v out)) *components*)
    (sort out #'string< :key #'component-id)))

(defun components-of-kind (kind)
  (remove-if-not (lambda (c) (eq (component-kind c) kind)) (all-components)))

(defun meta-get (c key) (getf (component-meta c) key))

(defun add-edge! (kind from to)
  (pushnew (list kind from to) *edges* :test #'equal))

(defun all-edges () (reverse *edges*))

(defun edges-from (id &optional kind)
  (remove-if-not (lambda (e) (and (equal (second e) id)
                                  (or (null kind) (eq (first e) kind))))
                 *edges*))

(defun edges-to (id &optional kind)
  (remove-if-not (lambda (e) (and (equal (third e) id)
                                  (or (null kind) (eq (first e) kind))))
                 *edges*))

(defun reachable-from (id &key (direction :forward))
  "Μεταβατικό κλείσιμο στον γράφο ακμών — BFS, ντετερμινιστικό."
  (let ((seen '()) (frontier (list id)))
    (loop while frontier
          do (let ((next '()))
               (dolist (f frontier)
                 (dolist (e (if (eq direction :forward)
                                (edges-from f) (edges-to f)))
                   (let ((other (if (eq direction :forward) (third e) (second e))))
                     (unless (or (equal other id) (member other seen :test #'equal))
                       (push other seen) (push other next)))))
               (setf frontier next)))
    (sort seen #'string<)))
