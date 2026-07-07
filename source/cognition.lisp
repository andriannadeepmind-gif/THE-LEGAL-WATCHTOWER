;;;; source/cognition.lisp
;;;; ============================================================================
;;;; Η ΓΝΩΣΙΑΚΗ ΔΙΑΔΙΚΑΣΙΑ — τα 5 στάδια, γενικά (όχι λίστα περιπτώσεων)
;;;; ============================================================================
;;;;
;;;; Έτσι δουλεύει ο LAWMAX σε ΚΑΘΕ εντολή — η συμπεριφορά ΠΑΡΑΓΕΤΑΙ, δεν
;;;; αναζητείται σε cond:
;;;;   1. ΑΠΟΔΟΜΗΣΗ & ΠΡΟΘΕΣΗ  φυσική γλώσσα → δομημένο νόημα (frame)
;;;;   2. ΣΧΕΔΙΑΣΜΟΣ ΣΕ ΒΗΜΑΤΑ  frame → πλάνο πράξεων
;;;;   3. ΔΟΚΙΜΗ & ΕΠΑΛΗΘΕΥΣΗ   κάθε βήμα ΑΠΟΜΟΝΩΜΕΝΑ, ελεγμένο στην πηγή
;;;;   4. ΔΙΑΧΕΙΡΙΣΗ ΜΝΗΜΗΣ     διάλογος + μνήμη εργασίας, μέσα στα στάδια
;;;;   5. ΣΥΝΘΕΣΗ ΑΠΑΝΤΗΣΗΣ     επαληθευμένα ευρήματα → απάντηση στο ΣΩΣΤΟ επίπεδο
;;;;
;;;; Τα στάδια 2/3/5 είναι CLOS generics ανά frame: νέα πρόθεση = νέα κλάση
;;;; frame + μέθοδοι, μηδέν αλλαγή στον ορχηστρωτή (open/closed). Έτσι
;;;; διαφορετικές ερωτήσεις παίρνουν διαφορετικές, σωστά-διαστασιολογημένες
;;;; απαντήσεις — χωρίς καμία κατά-περίπτωση διακλάδωση.
;;;;
;;;; Ο ΣΥΜΒΟΥΛΟΣ (πχ DeepSeek) μπαίνει στο στάδιο 1 ΕΚΤΟΣ εμπιστοσύνης: προτείνει
;;;; αποδόμηση· ο πυρήνας την ΕΠΑΛΗΘΕΥΕΙ στο στάδιο 3 πριν την εμπιστευτεί. Έτσι
;;;; η κατανόηση είναι επιπέδου-LLM αλλά η απάντηση ντετερμινιστική, με απόδειξη.

(defpackage :orchestrator.cognition
  (:use :cl)
  (:export #:process-request #:*advisor* #:advise #:decompose
           #:frame #:frame-input #:frame-slots #:frame-slot
           #:register-classifier #:classifiers #:clear-classifiers #:build-frame-from-advice
           #:plan #:execute-step #:synthesize #:triage #:critique
           #:working-memory #:remember #:recall #:*current-memory*
           #:cognition #:cog-input #:cog-frame #:cog-plan #:cog-evidence #:cog-answer #:cog-memory))

(in-package :orchestrator.cognition)

;;; ── Το δομημένο νόημα (στάδιο 1) — υποκλάσεις ανά πρόθεση ──
(defclass frame ()
  ((input :initarg :input :reader frame-input :initform nil)
   (slots :initarg :slots :accessor frame-slots :initform nil)))

(defun frame-slot (frame key &optional default) (getf (frame-slots frame) key default))

;;; ── Μνήμη (στάδιο 4) — απλό key/value που περνά μέσα από τα στάδια ──
(defclass working-memory ()
  ;; synchronized: μια συνεδρία μπορεί να στείλει δύο αιτήματα ταυτόχρονα —
  ;; η μνήμη της δεν διαφθείρεται (Φάση 0: ορθότητα υπό ταυτοχρονία)
  ((store :initform (make-hash-table :test 'equal :synchronized t) :reader wm-store)))
(defun remember (mem key val)
  "Κράτησε KEY→VAL στη μνήμη εργασίας της συνεδρίας — τα συμφραζόμενα του τρέχοντος διαλόγου."
  (when mem (setf (gethash key (wm-store mem)) val))
  val)
(defun recall (mem key &optional default) (if mem (gethash key (wm-store mem) default) default))

(defvar *current-memory* nil
  "Η ΕΝΕΡΓΗ μνήμη εργασίας του τρέχοντος process-request — δεμένη δυναμικά ώστε
   και οι ΤΑΞΙΝΟΜΗΤΕΣ (στάδιο 1) να θυμούνται/ανακαλούν συμφραζόμενα διαλόγου.
   ΜΙΑ έδρα κατάστασης συνομιλίας: καμία παράλληλη global δίπλα της.")

;;; ── Το πλαίσιο που συσσωρεύει κατάσταση στα 5 στάδια ──
(defstruct (cognition (:conc-name cog-))
  input frame plan evidence answer memory)

;;; ── Ο ΣΥΜΒΟΥΛΟΣ (εκτός εμπιστοσύνης) ──
(defvar *advisor* nil
  "Κλείσιμο (purpose input)→spec|nil. Ο σύμβουλος (πχ τοπικό DeepSeek) ΠΡΟΤΕΙΝΕΙ·
   ο πυρήνας επαληθεύει. nil = καθαρά συμβολική λειτουργία (καμία εξάρτηση).")
(defun advise (purpose input)
  (and *advisor* (ignore-errors (funcall *advisor* purpose input))))

;;; ── ΣΤΑΔΙΟ 1: αποδόμηση + πρόθεση ──
(defvar *classifiers* '()
  "Λίστα (name . fn) — fn(input)→frame|nil, συμβολικοί ταξινομητές σε σειρά.")
(defun register-classifier (name fn)
  (setf *classifiers* (remove name *classifiers* :key #'car :test #'equal))
  (setf *classifiers* (append *classifiers* (list (cons name fn))))
  name)
(defun classifiers () (mapcar #'car *classifiers*))
(defun clear-classifiers () (setf *classifiers* '()))

(defgeneric build-frame-from-advice (spec input)
  (:documentation "Χτίσε frame από δομημένη πρόταση συμβούλου (επαληθεύεται μετά).")
  (:method (spec input) (declare (ignore spec input)) nil))

(defun decompose (input)
  "Πρώτα οι συμβολικοί ταξινομητές· αν κανείς δεν πιάσει, ο σύμβουλος (η
   πρότασή του επαληθεύεται στο στάδιο 3). frame ή nil (τίμια άγνοια)."
  (or (loop for (name . fn) in *classifiers*
            for fr = (ignore-errors (funcall fn input))
            when fr do (return fr))
      (let ((spec (advise :decompose input)))
        (and spec (build-frame-from-advice spec input)))))

;;; ── ΣΤΑΔΙΑ 2, 3, 5: generics ανά frame (open/closed) ──
(defgeneric plan (frame cog)
  (:documentation "Στάδιο 2: τα βήματα για να απαντηθεί το frame.")
  (:method (frame cog) (declare (ignore frame cog)) '(:answer)))

(defgeneric execute-step (step frame cog)
  (:documentation "Στάδιο 3: εκτέλεσε+επαλήθευσε ΕΝΑ βήμα, απομονωμένα.
   (values ok-p evidence-item). Προεπιλογή: τετριμμένα έγκυρο (self-frames).")
  (:method (step frame cog) (declare (ignore step frame cog)) (values t nil)))

(defgeneric synthesize (frame cog)
  (:documentation "Στάδιο 5: σύνθεσε την απάντηση στο ΣΩΣΤΟ επίπεδο για ΤΟΥΤΟ
   το frame. Εδώ πεθαίνει το μονολιθικό σεντόνι.")
  (:method (frame cog) (declare (ignore cog)) (format nil "~A" (frame-input frame))))

;;; ── ΣΤΑΔΙΟ 0: διαλογή βάθους (triage) ──
(defgeneric triage (frame)
  (:documentation "Στάδιο 0: απλή ή σύνθετη πρόθεση; Οι ΑΠΛΕΣ τρέχουν ΗΣΥΧΑ
   (καμία ορατή σκέψη — όχι θέατρο). Οι ΣΥΝΘΕΤΕΣ με πλήρη ορατό συλλογισμό.")
  (:method (frame) (declare (ignore frame)) :simple))

;;; ── ΣΤΑΔΙΟ 4.5: αυτο-κριτική πριν την οριστικοποίηση ──
(defgeneric critique (frame draft cog)
  (:documentation "Στάδιο 4.5: το ΠΡΟΣΧΕΔΙΟ (η υποψήφια απάντηση, ορατή εδώ)
   απαντά ΟΝΤΩΣ αυτό που ρωτήθηκε, στο σωστό επίπεδο, με πηγή;
   (values ok-p issue revised): ok-p nil ⇒ το ζήτημα ΔΗΛΩΝΕΤΑΙ στην απάντηση·
   αν δοθεί REVISED, αυτό γίνεται η απάντηση. Προεπιλογή: εντάξει.")
  (:method (frame draft cog) (declare (ignore frame draft cog)) (values t nil nil)))

(defun %intent-name (frame)
  (string-downcase (symbol-name (class-name (class-of frame)))))

(defun %run-stages (cog verbose)
  "Στάδια 2→5 (με 4.5). VERBOSE ⇒ ορατός συλλογισμός (deliberation)."
  (labels ((th (cls fmt &rest a)
             (when verbose (apply #'orchestrator.deliberation:think cls fmt a))))
    (let ((frame (cog-frame cog)) (note 'orchestrator.deliberation:note))
      (th note "πρόθεση: ~A" (%intent-name frame))
      ;; 2 — σχεδιασμός σε βήματα
      (setf (cog-plan cog) (plan frame cog))
      (th note "② σχέδιο: ~D βήμα(τα)" (length (cog-plan cog)))
      ;; 3 — δοκιμή & επαλήθευση (απομονωμένα)
      (th note "③ δοκιμή & επαλήθευση…")
      (setf (cog-evidence cog)
            (loop for step in (cog-plan cog)
                  for (ok item) = (multiple-value-list (execute-step step frame cog))
                  do (th (if ok 'orchestrator.deliberation:verification
                             'orchestrator.deliberation:rejection)
                         "βήμα ~A: ~:[απέτυχε~;επαληθεύτηκε~]" step ok)
                  when ok collect item))
      ;; 4 — διαχείριση μνήμης
      (remember (cog-memory cog) :last-frame frame)
      ;; 5α — προσχέδιο απάντησης
      (let ((draft (synthesize frame cog)))
        ;; 4.5 — αυτο-κριτική ΠΑΝΩ στο προσχέδιο: μπορεί να το εγκρίνει, να το
        ;; αναθεωρήσει, ή να το απορρίψει — και η απόρριψη ΔΗΛΩΝΕΤΑΙ, δεν
        ;; σιωπάται. Κενό προσχέδιο ⇒ τίμια άγνοια (nil), ποτέ κενή απάντηση.
        (multiple-value-bind (ok issue revised) (critique frame draft cog)
          (setf (cog-answer cog)
                (cond
                  ((not (and (stringp draft) (plusp (length draft))))
                   (th 'orchestrator.deliberation:rejection
                       "④·5 αυτο-κριτική: κενό προσχέδιο — τίμια άγνοια")
                   nil)
                  (ok draft)
                  ((and (stringp revised) (plusp (length revised)))
                   (th 'orchestrator.deliberation:note
                       "④·5 αυτο-κριτική: ~A — αναθεωρήθηκε" issue)
                   revised)
                  (t
                   (th 'orchestrator.deliberation:rejection "④·5 αυτο-κριτική: ~A" issue)
                   (format nil "~A~%~%⚠ ΑΥΤΟΚΡΙΤΙΚΗ: ~A" draft issue))))))
      ;; 4β — η ΤΕΛΙΚΗ εκφορά στη μνήμη συνεδρίας: το επόμενο γύρισμα μπορεί
      ;; να δέσει «τι εννοείς …;» πάνω σε ό,τι ΠΡΑΓΜΑΤΙΚΑ ειπώθηκε — η αναφορά
      ;; συνομιλίας γίνεται δεδομένο, όχι εικασία.
      (when (cog-answer cog)
        (remember (cog-memory cog) :last-answer (cog-answer cog))
        (remember (cog-memory cog) :last-question (cog-input cog))))))

;;; ── Ο ΟΡΧΗΣΤΡΩΤΗΣ: τα στάδια, με αναλογικό βάθος ──
(defun process-request (input &key memory)
  "Η γενική γνωσιακή διαδικασία. (values answer cognition)· answer nil ⇒ δεν
   αποδομήθηκε (τίμια άγνοια). Στάδιο 0 κρίνει το βάθος: απλές ερωτήσεις ήσυχα,
   σύνθετες με ορατό συλλογισμό — τα 5 βήματα δεν γίνονται θέατρο στις εύκολες."
  (let* ((cog (make-cognition :input input :memory (or memory (make-instance 'working-memory))))
         (*current-memory* (cog-memory cog)))   ; ορατή και στους ταξινομητές
    ;; ① αποδόμηση & πρόθεση (πάντα, ήσυχα)
    (setf (cog-frame cog) (decompose input))
    (unless (cog-frame cog) (return-from process-request (values nil cog)))
    ;; ⓪ διαλογή βάθους → ήσυχο ή ορατό μονοπάτι
    (if (eq (triage (cog-frame cog)) :complex)
        (orchestrator.deliberation:with-deliberation (input) (%run-stages cog t))
        (%run-stages cog nil))
    (values (cog-answer cog) cog)))
