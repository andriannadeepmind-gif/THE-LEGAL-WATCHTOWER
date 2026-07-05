;;;; source/constitutional-gate.lisp
;;;; ============================================================================
;;;; Ο ΣΥΝΤΑΓΜΑΤΙΚΟΣ ΦΡΑΓΜΟΣ — γενικός κανόνας-μητρώο, αγνός
;;;; ============================================================================
;;;;
;;;; Ο υπέρτατος φραγμός ως ΙΔΙΟΤΗΤΑ του πράττειν: κάθε πράξη ελέγχεται έναντι
;;;; του συντάγματος ΠΡΙΝ εκτελεστεί. Αυτό το module ξέρει ΜΟΝΟ τον μηχανισμό:
;;;; ένα μητρώο κανόνων (άρθρο + κατηγόρημα + σε ποιες πράξεις ισχύει), την
;;;; αποτίμηση, και την ανίχνευση ΡΗΤΗΣ παράκαμψης του δημιουργού. Καμία λογική
;;;; πεδίου εδώ — τους κανόνες τους δηλώνουν οι καταναλωτές (open/closed).
;;;;
;;;; Η ίδια η μεσολάβηση (η «γύρω» πύλη στη δρομολόγηση) γίνεται με CLOS
;;;; method-combination στο επίπεδο του καταναλωτή — εδώ ζει μόνο η κρίση:
;;;; «επιτρέπεται αυτή η πράξη κατά το σύνταγμα;».

(defpackage :orchestrator.constitution
  (:use :cl)
  (:export #:register-rule #:evaluate #:overridden-p #:rules #:clear-rules))

(in-package :orchestrator.constitution)

(defvar *rules* '()
  "Λίστα plist (:id :article :applies-to :predicate) σε σταθερή σειρά.")

(defun register-rule (&key id article applies-to predicate)
  "Δήλωσε συνταγματικό κανόνα: ID keyword· ARTICLE η συνταγματική βάση (string,
   για την απόδειξη)· APPLIES-TO λίστα ονομάτων πράξεων· PREDICATE κλείσιμο
   ()→(values allowed-p reason). Επανεγγραφή ίδιου ID αντικαθιστά (idempotent)."
  (check-type id keyword)
  (setf *rules* (remove id *rules* :key (lambda (r) (getf r :id))))
  (setf *rules* (append *rules* (list (list :id id :article article
                                            :applies-to applies-to :predicate predicate))))
  id)

(defun rules () (mapcar (lambda (r) (getf r :id)) *rules*))
(defun clear-rules () (setf *rules* '()))

(defun evaluate (command)
  "Αποτίμησε κάθε κανόνα που ισχύει για την πράξη COMMAND. ΠΡΩΤΗ παράβαση →
   (values nil article reason id). Καμία → (values t nil nil nil)."
  (dolist (r *rules* (values t nil nil nil))
    (when (member command (getf r :applies-to) :test #'string=)
      (multiple-value-bind (ok reason)
          (handler-case (funcall (getf r :predicate))
            (error () (values t nil)))           ; σφάλμα κανόνα ⇒ ΜΗΝ μπλοκάρεις (fail-open, τίμια)
        (unless ok
          (return (values nil (getf r :article) reason (getf r :id))))))))

(defun overridden-p (args &optional command)
  "Ρητή, ΣΤΟΧΕΥΜΕΝΗ και ΑΙΤΙΟΛΟΓΗΜΕΝΗ παράκαμψη του δημιουργού (Άρθρο 1).
   Απαιτούνται ΚΑΙ τα δύο (εξωτερική επιθεώρηση 05-07-2026 — τέλος το
   καθολικό flag):
     (α) ΕΜΒΕΛΕΙΑ στη συγκεκριμένη πράξη: «--force» στα ορίσματα ΑΥΤΗΣ της
         κλήσης, ή LAWMAX_OVERRIDE=<εντολή>[,<εντολή>…] που περιέχει τη COMMAND·
     (β) ΑΙΤΙΟΛΟΓΙΑ: LAWMAX_OVERRIDE_REASON μη-κενή — γράφεται στη βιογραφία.
   (values bool token) — το token φέρει εμβέλεια ΚΑΙ αιτιολογία."
  (let* ((trimmed (lambda (s) (and s (let ((x (string-trim '(#\Space #\Tab #\Newline #\Return) s)))
                                       (and (plusp (length x)) x)))))
         (env (funcall trimmed (uiop:getenv "LAWMAX_OVERRIDE")))
         (reason (funcall trimmed (uiop:getenv "LAWMAX_OVERRIDE_REASON")))
         (scoped (and env command
                      (member command
                              (mapcar (lambda (s) (string-trim '(#\Space #\Tab) s))
                                      (uiop:split-string env :separator ","))
                              :test #'string-equal)))
         (forced (and (listp args) (member "--force" args :test #'string=))))
    (if (and (or scoped forced) reason)
        (values t (format nil "~A για «~A» — αιτιολογία: ~A"
                          (if forced "--force" (format nil "LAWMAX_OVERRIDE=~A" env))
                          (or command ";") reason))
        (values nil nil))))
