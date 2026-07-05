;;;; source/deliberation.lisp
;;;; ============================================================================
;;;; Ο ΣΤΟΧΑΣΤΗΣ — εσωτερικός διάλογος σε βήματα, ντετερμινιστικά, με MOP
;;;; ============================================================================
;;;;
;;;; Το σύστημα ΔΕΝ απαντά κατευθείαν: διατυπώνει υποθέσεις, δοκιμάζει την
;;;; καθεμία σε ΑΠΟΜΟΝΩΜΕΝΟ περιβάλλον, απορρίπτει όσες αποτυγχάνουν και
;;;; δοκιμάζει άλλη διαδρομή· απαντά ΜΟΝΟ ό,τι επαληθεύτηκε.
;;;;
;;;; Γιατί Metaobject Protocol: κάθε σκέψη είναι CLOS αντικείμενο με
;;;; metaclass THOUGHT-CLASS, και η ΚΑΤΑΓΡΑΦΗ της γίνεται στο
;;;; INITIALIZE-INSTANCE — δηλαδή στο ίδιο το πρωτόκολλο δημιουργίας του
;;;; αντικειμένου. Το σύστημα ΔΕΝ ΜΠΟΡΕΙ να σκεφτεί αόρατα: η ύπαρξη της
;;;; σκέψης και η ορατότητά της είναι το ίδιο γεγονός — το εγγυάται το
;;;; MOP, όχι η πειθαρχία του προγραμματιστή.
;;;;
;;;; Η απομόνωση: κάθε υπόθεση τρέχει με το *STANDARD-OUTPUT* δεσμευμένο
;;;; σε καραντίνα (dynamic extent — το εργαλείο της Common Lisp για
;;;; περιβάλλοντα με εγγυημένη επαναφορά). Ό,τι «θα έλεγε» μια διαδρομή
;;;; που απορρίφθηκε δεν φτάνει ποτέ στον χρήστη· μόνο η επαληθευμένη
;;;; διαδρομή απελευθερώνει το αποτέλεσμά της. Σφάλμα μέσα στην υπόθεση
;;;; δεν ρίχνει το σύστημα — γίνεται ΑΠΟΡΡΙΨΗ με αιτία.
;;;;
;;;; Καμία εξάρτηση πεδίου: ο στοχαστής δεν ξέρει από νόμους ή αποφάσεις —
;;;; δέχεται υποθέσεις ως κλεισίματα από τους καταναλωτές (no duplicate code).

(defpackage :orchestrator.deliberation
  (:use :cl)
  (:export #:with-deliberation #:think #:deliberate
           #:thought #:thought-step #:thought-text
           #:note #:hypothesis #:trial #:rejection #:verification
           #:deliberation-trace #:*think-aloud*))

(in-package :orchestrator.deliberation)

;;; ----------------------------------------------------------------------------
;;; MOP: η σκέψη ως metaclass
;;; ----------------------------------------------------------------------------

(defclass thought-class (standard-class) ()
  (:documentation "Metaclass των σκέψεων: η δημιουργία στιγμιοτύπου ΕΙΝΑΙ
   η καταγραφή στον εσωτερικό διάλογο — αδιαχώριστα, μέσω του MOP."))

(defmethod sb-mop:validate-superclass ((c thought-class) (s standard-class)) t)

(defvar *trace* nil "Ο τρέχων εσωτερικός διάλογος — σκέψεις, νεότερη πρώτη.")
(defvar *step* 0 "Αύξων αριθμός βήματος σκέψης μέσα σε μια στοχαστική συνεδρία.")
(defvar *think-aloud* t "Οι σκέψεις ορατές την στιγμή που γίνονται (άρθρο 3).")

(defclass thought ()
  ((step :reader thought-step)
   (text :initarg :text :reader thought-text))
  (:metaclass thought-class))

(defclass note (thought) () (:metaclass thought-class)
  (:documentation "Παρατήρηση/κατανόηση — τι βλέπω στο ερώτημα."))
(defclass hypothesis (thought) () (:metaclass thought-class)
  (:documentation "Υπόθεση — διαδρομή που αξίζει δοκιμή."))
(defclass trial (thought) () (:metaclass thought-class)
  (:documentation "Δοκιμή υπόθεσης στο απομονωμένο περιβάλλον."))
(defclass rejection (thought) () (:metaclass thought-class)
  (:documentation "Απόρριψη — η διαδρομή είχε λάθος· δοκιμάζω άλλη."))
(defclass verification (thought) () (:metaclass thought-class)
  (:documentation "Επαλήθευση — η διαδρομή στέκει· μόνο αυτή απαντιέται."))

(defgeneric thought-glyph (thought)
  (:documentation "Το σημάδι κάθε είδους σκέψης — CLOS dispatch, όχι case."))
(defmethod thought-glyph ((th note) ) "·")
(defmethod thought-glyph ((th hypothesis)) "?")
(defmethod thought-glyph ((th trial)) "⌁")
(defmethod thought-glyph ((th rejection)) "✗")
(defmethod thought-glyph ((th verification)) "✓")

(defmethod initialize-instance :after ((th thought) &key)
  ;; Εδώ ζει η εγγύηση: ΚΑΘΕ σκέψη, με το που υπάρχει, καταγράφεται
  ;; και (αν *think-aloud*) ακούγεται. Δεν υπάρχει άλλο μονοπάτι δημιουργίας.
  (setf (slot-value th 'step) (incf *step*))
  (push th *trace*)
  (when *think-aloud*
    (format t "  ~A ~A~%" (thought-glyph th) (thought-text th))))

(defun think (class fmt &rest args)
  "Μια σκέψη είδους CLASS με κείμενο (format FMT ARGS)."
  (make-instance class :text (apply #'format nil fmt args)))

(defun deliberation-trace () (reverse *trace*))

;;; ----------------------------------------------------------------------------
;;; Η στοχαστική συνεδρία και ο κύκλος υπόθεση→δοκιμή→απόρριψη/επαλήθευση
;;; ----------------------------------------------------------------------------

(defmacro with-deliberation ((question) &body body)
  "Μια στοχαστική συνεδρία: νέος εσωτερικός διάλογος, ορατός, με κεφαλίδα.
   Το BODY σκέφτεται (THINK/DELIBERATE) και επιστρέφει το αποτέλεσμά του."
  `(let ((*trace* nil) (*step* 0))
     (when *think-aloud*
       (format t "~%┌─ ΕΣΩΤΕΡΙΚΟΣ ΔΙΑΛΟΓΟΣ ─────────────────────────~%"))
     (think 'note "κατανόηση: ~A" ,question)
     (multiple-value-prog1 (progn ,@body)
       (when *think-aloud*
         (format t "└─ τέλος σκέψης (~D βήματα) ────────────────────~%~%" *step*)))))

(defun deliberate (candidates &key (on-exhausted "καμία διαδρομή δεν επαληθεύτηκε"))
  "Ο κύκλος του άρθρου 3. CANDIDATES: λίστα (ετικέτα . κλείσιμο)· κάθε
   κλείσιμο επιστρέφει (values ok-p payload) και τρέχει ΑΠΟΜΟΝΩΜΕΝΟ:
   ό,τι τυπώνει μπαίνει σε καραντίνα. Η ΠΡΩΤΗ υπόθεση που επαληθεύεται
   κερδίζει — ντετερμινιστική σειρά, ορατή αιτία για κάθε απόρριψη.
   Επιστρέφει (values ok-p payload επαληθευμένο-output): η απάντηση
   απελευθερώνεται από τον καλούντα ΜΕΤΑ το κλείσιμο της σκέψης, ώστε
   σκέψη και απάντηση να μένουν διακριτές. Καμία επαλήθευση ⇒ nil nil nil."
  (loop for (label . thunk) in candidates
        for i from 1
        do (think 'hypothesis "υπόθεση ~D: ~A" i label)
           (think 'trial "δοκιμάζω την υπόθεση ~D στο απομονωμένο περιβάλλον…" i)
           (let ((quarantine (make-string-output-stream)) ok payload)
             (handler-case
                 (let ((*standard-output* quarantine))
                   (multiple-value-setq (ok payload) (funcall thunk)))
               (error (e) (setf ok nil
                                payload (format nil "σφάλμα κατά την δοκιμή: ~A" e))))
             (cond
               (ok
                (think 'verification "η υπόθεση ~D επαληθεύτηκε — απαντώ μόνο αυτήν" i)
                (return (values t payload (get-output-stream-string quarantine))))
               (t
                (think 'rejection "απορρίφθηκε η υπόθεση ~D: ~A" i
                       (or payload "χωρίς εύρημα")))))
        finally
           (think 'note "~A — το δηλώνω τίμια" on-exhausted)
           (return (values nil nil nil))))
