;;;; source/institution.lisp
;;;; ============================================================================
;;;; ΤΟ ΙΔΡΥΜΑ — η ανώτερη οντολογική ταυτότητα, πάνω από τον συντονιστή
;;;; ============================================================================
;;;;
;;;; Το σύστημα ΔΕΝ είναι «orchestrator» ως όλον: είναι Νομικό Ίδρυμα (LAWMAX
;;;; Legal Institution) και ο orchestrator είναι το εσωτερικό ΟΡΓΑΝΟ
;;;; συντονισμού του. Εδώ ζει η θεσμική οντολογία: το Ίδρυμα και οι
;;;; ρόλοι/αίθουσες (chambers) που το απαρτίζουν. ΚΑΝΕΝΑ global rename:
;;;; τα πακέτα orchestrator.* μένουν — είναι το όνομα του οργάνου, όχι του
;;;; Ιδρύματος. Η ταυτότητα δεν είναι φράση README: είναι δηλωμένα
;;;; αντικείμενα που το συμβόλαιο ταυτότητας και οι πύλες ελέγχουν μηχανικά.

(defpackage :orchestrator.institution
  (:use :cl)
  (:export #:declare-institution! #:the-institution
           #:institution-name #:institution-description
           #:institution-coordination-engine #:institution-organs
           #:declare-role! #:find-role #:all-roles
           #:role-name #:role-description))

(in-package :orchestrator.institution)

(defun %key (name) (string-downcase (string name)))

(defstruct (institution (:constructor %make-institution))
  name                  ; "LAWMAX Legal Institution"
  description
  coordination-engine   ; όνομα ΡΟΛΟΥ: το εσωτερικό όργανο συντονισμού
  organs)               ; ονόματα ρόλων/αιθουσών που απαρτίζουν το Ίδρυμα

(defvar *institution* nil "Το ΕΝΑ Ίδρυμα — δεν υπάρχει δεύτερο.")

(defun declare-institution! (&key name description coordination-engine organs)
  (setf *institution*
        (%make-institution :name name :description description
                           :coordination-engine coordination-engine
                           :organs (mapcar #'string organs))))

(defun the-institution () *institution*)

(defvar *roles* '()
  "Οι θεσμικοί ρόλοι/αίθουσες — διατεταγμένη λίστα role (σειρά δήλωσης).")

(defstruct (role (:constructor %make-role))
  name description)

(defun declare-role! (name &key description)
  "Δήλωση ρόλου — αντικατάσταση κατά όνομα (idempotent reload)."
  (let ((r (%make-role :name (string name) :description description)))
    (setf *roles*
          (append (remove (%key name) *roles*
                          :key (lambda (x) (%key (role-name x))) :test #'string=)
                  (list r)))
    r))

(defun find-role (name)
  (find (%key name) *roles*
        :key (lambda (r) (%key (role-name r))) :test #'string=))

(defun all-roles () (copy-list *roles*))
