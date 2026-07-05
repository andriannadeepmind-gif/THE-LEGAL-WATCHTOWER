;;;; source/introspection.lisp
;;;; ============================================================================
;;;; Η ΜΗΧΑΝΗ ΑΝΑΣΤΟΧΑΣΜΟΥ — ο εσωτερικός βρόχος του LAWMAX, γενικός
;;;; ============================================================================
;;;;
;;;; Ο LAWMAX κοιτάζει τον εαυτό του: τρέχει ΠΑΡΑΤΗΡΗΤΕΣ (observers), σκέφτεται
;;;; ορατά (deliberation), και για κάθε εύρημα που είναι «proposable» καταθέτει
;;;; πρόταση (proposals). Αυτό το module ΔΕΝ ξέρει από νομική, οικονομικά ή
;;;; οτιδήποτε — ξέρει μόνο πώς να ενορχηστρώσει παρατηρητές και να μετατρέψει
;;;; ευρήματα σε προτάσεις, με ορατή σκέψη.
;;;;
;;;; OPEN/CLOSED: νέος τομέας ή νέος πράκτορας = REGISTER-OBSERVER, μηδέν αλλαγή
;;;; εδώ. Ένας παρατηρητής είναι κλείσιμο ()→ λίστα ευρημάτων, καθένα
;;;; plist (:sig :kind :why [:payload]). Αν το :kind είναι εγγεγραμμένο είδος
;;;; πρότασης ⇒ κατατίθεται· αλλιώς (π.χ. :note) ⇒ απλώς φαίνεται ως σκέψη.

(defpackage :orchestrator.introspection
  (:use :cl)
  (:export #:register-observer #:observers #:clear-observers #:run-introspection))

(in-package :orchestrator.introspection)

(defvar *observers* '()
  "Λίστα (name . fn) σε σταθερή σειρά εγγραφής — ντετερμινιστικός αναστοχασμός.")

(defun register-observer (name fn)
  "Δήλωσε έναν παρατηρητή: FN ()→ λίστα ευρημάτων plist(:sig :kind :why :payload).
   Επανεγγραφή ίδιου ονόματος αντικαθιστά (idempotent στο reload)."
  (setf *observers* (remove name *observers* :key #'car :test #'equal))
  (setf *observers* (append *observers* (list (cons name fn))))
  name)

(defun observers () (mapcar #'car *observers*))
(defun clear-observers () (setf *observers* '()))

(defun run-introspection (&key (question "Τι χρειάζομαι για να πλησιάσω την αποστολή μου;"))
  "Ο εσωτερικός βρόχος, ορατός, σε ΔΥΟ περάσματα:
     1) μάζεμα ευρημάτων από όλους τους παρατηρητές·
     2) ΣΥΜΦΙΛΙΩΣΗ: το ανοιχτό σύνολο προτάσεων ευθυγραμμίζεται με την τρέχουσα
        αυτο-εικόνα — ό,τι δεν είναι πια ζωντανό εύρημα αποσύρεται (η αξίωση
        παύει επειδή ο εαυτός δεν τη βλέπει)· και
     3) σκέψη+κατάθεση για κάθε ζωντανό εύρημα.
   Η συμφιλίωση τρέχει ΜΟΝΟ σε καθαρό κύκλο (κανένας παρατηρητής δεν απέτυχε),
   ώστε ένα παροδικό σφάλμα να ΜΗΝ αποσύρει κατά λάθος γνήσιες αξιώσεις.
   Επιστρέφει το πλήθος ΝΕΩΝ προτάσεων. Γενικό — δεν ξέρει από τομέα."
  (let ((new 0) (all-findings '()) (clean t))
    (orchestrator.deliberation:with-deliberation (question)
      ;; ── 1) μάζεμα ──
      (dolist (obs *observers*)
        (handler-case
            (setf all-findings (append all-findings (funcall (cdr obs))))
          (error (e)
            (setf clean nil)
            (orchestrator.deliberation:think 'orchestrator.deliberation:note
              "παρατηρητής «~A»: σφάλμα ~A — αναβάλλω τη συμφιλίωση αυτόν τον κύκλο" (car obs) e))))
      ;; ── 2) συμφιλίωση (μόνο σε καθαρό κύκλο) ──
      (when clean
        (let ((live (loop for f in all-findings
                          when (orchestrator.proposals:proposal-kind-registered-p (getf f :kind))
                          collect (getf f :sig))))
          (let ((closed (orchestrator.proposals:reconcile! live)))
            (when (plusp closed)
              (orchestrator.deliberation:think 'orchestrator.deliberation:verification
                "απέσυρα ~D προτάσεις που δεν ισχύουν πλέον — το ανοιχτό σύνολο ακολουθεί την τρέχουσα εικόνα" closed)))))
      ;; ── 3) σκέψη + κατάθεση ──
      (dolist (f all-findings)
        (let ((sig (getf f :sig)) (kind (getf f :kind)) (why (getf f :why))
              (payload (getf f :payload)))
          (let ((proposable (orchestrator.proposals:proposal-kind-registered-p kind)))
            (orchestrator.deliberation:think
             (if proposable 'orchestrator.deliberation:hypothesis
                 'orchestrator.deliberation:note)
             "~A" why)
            (when (and proposable sig)
              (let ((id (orchestrator.proposals:propose!
                         :sig sig :kind kind :why why :payload (or payload ""))))
                (if id
                    (progn (incf new)
                           (orchestrator.deliberation:think 'orchestrator.deliberation:verification
                             "κατέθεσα πρόταση #~A" id))
                    (orchestrator.deliberation:think 'orchestrator.deliberation:note
                      "ήδη γνωστή ή απορριφθείσα με ίδια στοιχεία — δεν επαναλαμβάνω")))))))
      new)))
