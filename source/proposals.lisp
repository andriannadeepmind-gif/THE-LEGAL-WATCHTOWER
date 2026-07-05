;;;; source/proposals.lisp
;;;; ============================================================================
;;;; ΤΟ ΜΗΤΡΩΟ ΠΡΟΤΑΣΕΩΝ — γενικός κύκλος ζωής πρότασης→έγκρισης, αγνός
;;;; ============================================================================
;;;;
;;;; Ο LAWMAX (η συνείδηση) καταθέτει προτάσεις· ο δημιουργός εγκρίνει ή
;;;; απορρίπτει. Αυτό το module ξέρει ΜΟΝΟ τον κύκλο ζωής: κατάθεση,
;;;; ταυτότητα, μόνιμο append-only ημερολόγιο, προσωρινή απόρριψη κατά
;;;; υπογραφή-αποδείξεων. ΔΕΝ ξέρει τι σημαίνει «υιοθέτηση γνώσης» ή
;;;; «ανάγκη» — αυτά τα ορίζουν οι ΚΑΤΑΝΑΛΩΤΕΣ μέσω REGISTER-PROPOSAL-KIND.
;;;;
;;;; OPEN/CLOSED: νέο είδος πρότασης = νέα εγγραφή, μηδέν αλλαγή εδώ. Καμία
;;;; λογική πεδίου, κανένας διπλός κώδικας — για το μέλλον, χωρίς refactoring.
;;;;
;;;; ΠΡΟΣΩΡΙΝΗ ΑΠΟΡΡΙΨΗ (η απόφαση #4 του δημιουργού): η ταυτότητα μιας
;;;; πρότασης είναι το SHA της ΥΠΟΓΡΑΦΗΣ ΑΠΟΔΕΙΞΕΩΝ της (sig). Ίδια στοιχεία
;;;; ⇒ ίδιο id ⇒ αν απορρίφθηκε, δεν επανέρχεται. Αλλάζουν τα στοιχεία ⇒
;;;; αλλάζει το sig ⇒ νέο id ⇒ νέα πρόταση. «Αν αλλάξουν τα στοιχεία,
;;;; αλλάζει και η απόφαση» — ως μηχανική ιδιότητα.

(defpackage :orchestrator.proposals
  (:use :cl)
  (:export #:*proposals-path* #:register-proposal-kind #:proposal-kind-registered-p
           #:propose! #:proposals #:open-proposals #:approve! #:reject! #:reconcile!
           #:describe-proposals
           #:proposal #:proposal-id #:proposal-sig #:proposal-kind
           #:proposal-why #:proposal-status #:proposal-payload #:proposal-at))

(in-package :orchestrator.proposals)

(defvar *proposals-path*
  (merge-pathnames "deployment/self/proposals.sexp" (uiop:getcwd))
  "Το ημερολόγιο προτάσεων — append-only, versioned στο repo.")

(defvar *kinds* (make-hash-table :test 'eq)
  "kind → plist (:on-approve fn :on-reject fn :describe fn). Ορίζεται από
   τους καταναλωτές· το module μένει αγνό.")

(defstruct (proposal (:constructor %make-proposal))
  id sig kind why status payload at)

(defun register-proposal-kind (kind &key on-approve on-reject describe)
  "Ένας καταναλωτής δηλώνει τι ΣΗΜΑΙΝΕΙ ένα είδος πρότασης: τι γίνεται στην
   έγκριση (ON-APPROVE (proposal)→), στην απόρριψη (ON-REJECT (proposal)→),
   και πώς περιγράφεται (DESCRIBE (proposal)→string). Όλα κλεισίματα."
  (check-type kind keyword)
  (setf (gethash kind *kinds*)
        (list :on-approve on-approve :on-reject on-reject :describe describe))
  kind)

(defun proposal-kind-registered-p (kind)
  (and (keywordp kind) (gethash kind *kinds*) t))

;;; Χρόνος/χασάρισμα/γραφή/ανάγνωση: από το ΕΝΑ ιδίωμα (orchestrator.journal).
(defun %sig-id (sig)
  "Ταυτότητα πρότασης = ΠΛΗΡΕΣ SHA-256 της υπογραφής-αποδείξεων. Σταθερή
   (κανένας χρόνος/τυχαιότητα μέσα) — ίδιο sig, ίδιο id, πάντα. Τα 8 hex
   συγκρούονται περί τις 65k προτάσεις (birthday bound) — η ταυτότητα δεν
   κουτσουρεύεται· για τον άνθρωπο υπάρχει η ανάλυση προθέματος στο %FIND."
  (orchestrator.journal:sha256-hex sig))

(defun %now () (orchestrator.journal:iso-now))

(defun %append-event (plist)
  ;; σκόπιμα ανεκτικό: αποτυχία εγγραφής δεν ρίχνει τη ροή που πρότεινε
  (ignore-errors (orchestrator.journal:append-line *proposals-path* plist)))

(defun %events () (orchestrator.journal:read-lines *proposals-path*))

(defun proposals ()
  "Η τρέχουσα κατάσταση: μία πρόταση ανά id, με το ΤΕΛΕΥΤΑΙΟ της status
   (fold του append-only ημερολογίου). Σειρά = σειρά πρώτης εμφάνισης."
  (let ((h (make-hash-table :test 'equal)) (order '()))
    (dolist (e (%events))
      (let ((id (getf e :id)))
        (when id
          (unless (gethash id h) (push id order))
          (setf (gethash id h)
                (%make-proposal :id id :sig (getf e :sig) :kind (getf e :kind)
                                :why (getf e :why) :status (getf e :status)
                                :payload (getf e :payload) :at (getf e :at))))))
    (mapcar (lambda (id) (gethash id h)) (nreverse order))))

(defun open-proposals ()
  (remove-if-not (lambda (p) (equal (proposal-status p) "open")) (proposals)))

(defun %find (id)
  "Βρες πρόταση: με ΠΛΗΡΕΣ id ή με ΜΟΝΟΣΗΜΑΝΤΟ πρόθεμά του (≥4 hex — όπως το
   git). (values πρόταση|nil αιτία): :ambiguous όταν το πρόθεμα ταιριάζει σε
   περισσότερες — ΠΟΤΕ σιωπηλή επιλογή λάθος πρότασης."
  (let ((ps (proposals)))
    (let ((exact (find id ps :key #'proposal-id :test #'equal)))
      (if exact
          exact
          (let ((hits (and (stringp id) (>= (length id) 4)
                           (remove-if-not
                            (lambda (p)
                              (let ((pid (proposal-id p)))
                                (and (<= (length id) (length pid))
                                     (string= id pid :end2 (length id)))))
                            ps))))
            (cond ((null hits) (values nil nil))
                  ((null (cdr hits)) (first hits))
                  (t (values nil :ambiguous))))))))

(defun propose! (&key sig kind why (payload ""))
  "Κατάθεσε πρόταση. Επιστρέφει το id, ή NIL αν ΚΑΤΑΠΝΙΓΕΤΑΙ: υπάρχει ήδη
   πρόταση ίδιου SIG (ανοιχτή/εγκεκριμένη/απορριφθείσα). Η προσωρινότητα της
   απόρριψης ζει εδώ: ίδιο sig ⇒ δεν επανέρχεται· αλλαγμένο sig ⇒ νέα.
   Η καταστολή κρίνεται στο ΙΔΙΟ το sig (όχι στο παράγωγο id) — έτσι μένει
   αληθινή και απέναντι σε παλαιές εγγραφές με κολοβά 8-hex ids."
  (check-type sig string)
  (check-type kind keyword)
  (let ((existing (find sig (proposals) :key #'proposal-sig :test #'equal)))
    (when (and existing
               (member (proposal-status existing) '("open" "approved" "rejected")
                       :test #'string=))
      (return-from propose! nil))
    (let ((id (%sig-id sig)))
      (%append-event (list :at (%now) :id id :sig sig :kind kind
                           :why why :status "open" :payload (or payload "")))
      id)))

(defun %transition (id new-status hook-key ok-kw fail-msg)
  (multiple-value-bind (p why) (%find id)
    (cond ((eq why :ambiguous) (values nil :ambiguous))
          ((null p) (values nil :not-found))
          ((not (equal (proposal-status p) "open")) (values nil :not-open))
          (t (let ((hook (getf (gethash (proposal-kind p) *kinds*) hook-key)))
               (declare (ignorable fail-msg))
               (when hook (ignore-errors (funcall hook p))))
             (%append-event (list :at (%now) :id (proposal-id p) :sig (proposal-sig p)
                                  :kind (proposal-kind p) :why (proposal-why p)
                                  :status new-status :payload (proposal-payload p)))
             (values (%find (proposal-id p)) ok-kw)))))

(defun approve! (id)
  "Έγκριση: τρέξε το ON-APPROVE του είδους και σφράγισε το νέο status.
   Επιστρέφει (values proposal :approved) ή (values nil αιτία)."
  (%transition id "approved" :on-approve :approved nil))

(defun reject! (id)
  "Απόρριψη (προσωρινή): σφράγισε rejected· ίδιο sig δεν επανέρχεται μέχρι
   ν' αλλάξουν τα στοιχεία. Επιστρέφει (values proposal :rejected) ή nil."
  (%transition id "rejected" :on-reject :rejected nil))

(defun reconcile! (live-sigs)
  "ΣΥΜΦΙΛΙΩΣΗ — το ανοιχτό σύνολο ΑΙΤΙΑΚΑ ΣΥΝΔΕΔΕΜΕΝΟ με την τρέχουσα
   αυτο-εικόνα: κάθε ΑΝΟΙΧΤΗ πρόταση της οποίας το sig ΔΕΝ είναι πλέον ζωντανό
   εύρημα κλείνει ως «superseded» — ο εαυτός δεν τη βλέπει πια, άρα αποσύρει
   την αξίωση. Οι εγκεκριμένες/απορριφθείσες ΔΕΝ αγγίζονται (τελικές). LIVE-SIGS:
   η λίστα των sig που παράγουν ΤΩΡΑ οι παρατηρητές. Επιστρέφει πλήθος κλεισμάτων."
  (let ((live (make-hash-table :test 'equal)) (n 0))
    (dolist (s live-sigs) (setf (gethash s live) t))
    (dolist (p (open-proposals))
      (unless (gethash (proposal-sig p) live)
        (%append-event (list :at (%now) :id (proposal-id p) :sig (proposal-sig p)
                             :kind (proposal-kind p) :why (proposal-why p)
                             :status "superseded" :payload (proposal-payload p)))
        (incf n)))
    n))

(defun %describe-one (p)
  (let ((d (getf (gethash (proposal-kind p) *kinds*) :describe)))
    (if d (or (ignore-errors (funcall d p)) (proposal-why p)) (proposal-why p))))

(defun describe-proposals (&optional (stream *standard-output*))
  "Οι ανοιχτές προτάσεις του LAWMAX — τι περιμένει την απόφαση του δημιουργού."
  (let ((open (open-proposals)))
    (if (null open)
        (format stream "~%(καμία ανοιχτή πρόταση — ο LAWMAX δεν ζητά κάτι αυτή τη στιγμή)~%")
        (progn
          (format stream "~%── ΠΡΟΤΑΣΕΙΣ ΤΟΥ LAWMAX (~D ανοιχτές) ──~%" (length open))
          (dolist (p open)
            ;; ο άνθρωπος βλέπει πρόθεμα 12 hex — τα approve!/reject! δέχονται
            ;; πρόθεμα (μονοσήμαντο) ή πλήρες id, όπως το git
            (format stream "  #~A [~A] ~A~%"
                    (subseq (proposal-id p) 0 (min 12 (length (proposal-id p))))
                    (string-downcase (symbol-name (proposal-kind p)))
                    (%describe-one p)))
          (format stream "~%(έγκριση: --approve <id|πρόθεμα> · απόρριψη: --reject <id|πρόθεμα>)~%")))
    0))
