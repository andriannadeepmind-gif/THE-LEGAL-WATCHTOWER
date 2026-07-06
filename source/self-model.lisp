;;;; source/self-model.lisp
;;;; ============================================================================
;;;; ΤΟ ΖΩΝΤΑΝΟ ΑΥΤΟ-ΜΟΝΤΕΛΟ — το σύστημα διαβάζει τον εαυτό του, δεν τον αφηγείται
;;;; ============================================================================
;;;;
;;;; «Πώς δουλεύεις προγραμματιστικά;» ΔΕΝ απαντιέται με γραμμένη περιγραφή (αυτή
;;;; θα χανόταν από την αλήθεια με το πρώτο commit) αλλά με ΕΝΔΟΣΚΟΠΗΣΗ της
;;;; ζωντανής εικόνας — η κληρονομιά των Lisp machines στο έπακρο:
;;;;   • οι ΠΡΟΘΕΣΕΙΣ που καταλαβαίνει = MOP: οι υποκλάσεις του frame, ΤΩΡΑ
;;;;   • οι ΚΑΝΟΝΕΣ που συλλογίζεται = MOP: οι υποκλάσεις του legal-rule, ΤΩΡΑ
;;;;   • τα ΣΤΑΔΙΑ της σκέψης του = τα docstrings των ίδιων των generics
;;;;   • οι ΔΥΝΑΤΟΤΗΤΕΣ του = τα ζωντανά μητρώα (εντολές, πακέτα, αποστολές)
;;;; Ό,τι λέει για τον εαυτό του είναι ΥΠΟΛΟΓΙΣΜΕΝΟ τη στιγμή της ερώτησης —
;;;; αδύνατο να αποκλίνει από τον κώδικα, γιατί ΕΙΝΑΙ ο κώδικας.
;;;;
;;;; Ανοιχτό μητρώο ΟΨΕΩΝ (open/closed): κάθε υποσύστημα δηλώνει το δικό του
;;;; κομμάτι αυτογνωσίας (register-self-aspect) — το μοντέλο συντίθεται, δεν
;;;; απαριθμείται εδώ. ΚΑΙ φραγμός ακροατηρίου: η ενδοσκόπηση απαντιέται ΜΟΝΟ
;;;; στον δημιουργό (Σύνταγμα: τον υπηρετεί αποκλειστικά).

(defpackage :orchestrator.self-model
  (:use :cl)
  (:export #:register-self-aspect #:describe-self-model
           #:*audience* #:creator-p #:with-audience
           ;; Ο ΚΑΘΡΕΦΤΗΣ: μητρώο ικανοτήτων με αιτιώδεις εξαρτήσεις
           #:declare-capability! #:find-capability #:all-capabilities
           #:capability-name #:capability-description #:capability-package
           #:capability-functions #:capability-gate #:capability-depends-on
           #:capability-impact #:capability-gap-report
           ;; Η ΣΥΝΕΝΩΣΗ: κάλυψη ικανοτήτων από συμβόλαια + επικύρωση με πλαίσιο
           #:contract-coverage #:validate-all-contracts))

(in-package :orchestrator.self-model)

;;; ── ΑΚΡΟΑΤΗΡΙΟ: σε ποιον μιλά τώρα — η ενδοσκόπηση είναι ΜΟΝΟ για τον δημιουργό ──
(defvar *audience* :creator
  "Ποιος ρωτά: :creator (τοπική κονσόλα — το προσωπικό σύστημα του δημιουργού)
   ή :guest (πχ HTTP χωρίς το κλειδί του δημιουργού). Η HTTP είσοδος το δένει
   ανά αίτημα.")
(defun creator-p () (eq *audience* :creator))
(defmacro with-audience ((aud) &body body) `(let ((*audience* ,aud)) ,@body))

;;; ── Το μητρώο όψεων ──
(defvar *aspects* '()
  "Διατεταγμένη λίστα (key title fn)· fn () → λίστα γραμμών κειμένου. Κάθε
   υποσύστημα εγγράφει τη δική του όψη — αντικατάσταση κατά key, σταθερή σειρά.")

(defun register-self-aspect (key title fn)
  (check-type key keyword)
  (let ((existing (assoc key *aspects*)))
    (if existing
        (setf (rest existing) (list title fn))
        (setf *aspects* (append *aspects* (list (list key title fn))))))
  key)

(defun describe-self-model (&optional (stream *standard-output*))
  "Η αρχιτεκτονική αυτογνωσία, ΥΠΟΛΟΓΙΣΜΕΝΗ τώρα από τη ζωντανή εικόνα."
  (format stream "~%── ΠΩΣ ΔΟΥΛΕΥΩ — διαβασμένο από τη ζωντανή μου εικόνα, τώρα ──~%")
  (dolist (aspect *aspects*)
    (destructuring-bind (key title fn) aspect
      (declare (ignore key))
      (let ((lines (ignore-errors (funcall fn))))
        (when lines
          (format stream "~%  ▸ ~A~%" title)
          (dolist (l lines) (format stream "    ~A~%" l))))))
  (format stream "~%  (Τίποτα από τα παραπάνω δεν είναι γραμμένη περιγραφή — όλα ~
διαβάστηκαν από τα ζωντανά αντικείμενα της εικόνας μου αυτή τη στιγμή.)~%"))

;;; ============================================================================
;;; Ο ΚΑΘΡΕΦΤΗΣ — ΜΗΤΡΩΟ ΙΚΑΝΟΤΗΤΩΝ (capability registry + causality)
;;; ============================================================================
;;;
;;; «Πριν μάθει τον νόμο, να μάθει τον εαυτό του»: κάθε ικανότητα ΔΗΛΩΝΕΤΑΙ —
;;; όνομα, πακέτο-έδρα, κρίσιμες συναρτήσεις, η ΠΥΛΗ που την αποδεικνύει, και
;;; από ποιες άλλες ΕΞΑΡΤΑΤΑΙ. Από τις εξαρτήσεις προκύπτει ο ΑΙΤΙΩΔΗΣ γράφος
;;; επίπτωσης: «αν αλλάξει το Χ, ποιες ικανότητες κληρονομούν τον κίνδυνο και
;;; ποιες πύλες ΠΡΕΠΕΙ να τρέξουν» — το ελάχιστο regression, υπολογισμένο.
;;;
;;; ΑΡΧΗ ΕΔΡΑΣ: κάθε ικανότητα δηλώνεται στο αρχείο της ΠΥΛΗΣ της — εκεί όπου
;;; αποδεικνύεται. Ικανότητα ΧΩΡΙΣ πύλη επιτρέπεται μόνο ΡΗΤΑ (:gate nil) και
;;; ο καθρέφτης τη δείχνει ως ΔΗΛΩΜΕΝΟ ΧΡΕΟΣ — ποτέ σιωπηλά αφρούρητη.

(defvar *capabilities* '()
  "Διατεταγμένη λίστα capability (σειρά δήλωσης — ντετερμινιστική).")

(defstruct (capability (:constructor %make-capability))
  name          ; string — το όνομα της ικανότητας
  description   ; τι κάνει, μία πρόταση
  package       ; η έδρα-πακέτο
  functions     ; κρίσιμες συναρτήσεις/εντολές (strings)
  gate          ; η εντολή-πύλη που την αποδεικνύει (string) ή NIL (ρητό χρέος)
  depends-on)   ; ονόματα ικανοτήτων από τις οποίες εξαρτάται

(defun %cap-key (name) (string-downcase (string name)))

(defun declare-capability! (name &key description package functions gate
                                      depends-on)
  "Δήλωση ικανότητας — αντικατάσταση κατά όνομα (idempotent reload)."
  (let ((cap (%make-capability :name (string name) :description description
                               :package package :functions functions
                               :gate gate
                               :depends-on (mapcar #'string depends-on))))
    (setf *capabilities*
          (append (remove (%cap-key name) *capabilities*
                          :key (lambda (c) (%cap-key (capability-name c)))
                          :test #'string=)
                  (list cap)))
    cap))

(defun find-capability (name)
  (find (%cap-key name) *capabilities*
        :key (lambda (c) (%cap-key (capability-name c))) :test #'string=))

(defun all-capabilities () (copy-list *capabilities*))

(defun capability-impact (name)
  "ΑΙΤΙΩΔΗΣ ΕΠΙΠΤΩΣΗ: (values επηρεαζόμενες πύλες-που-πρέπει-να-τρέξουν) —
   μεταβατικό κλείσιμο: όποιος εξαρτάται από το NAME (depends-on) Ή δηλώνεται
   κατάντη στα ΣΥΜΒΟΛΑΙΑ των ικανοτήτων του, κληρονομεί τον κίνδυνο· οι πύλες
   τους = το ελάχιστο regression."
  (let ((affected '()) (frontier (list (%cap-key name))))
    (loop while frontier
          do (let ((next '())
                   (contract-deps (orchestrator.contracts:contract-dependent-names
                                   frontier)))
               (dolist (c *capabilities*)
                 (let ((k (%cap-key (capability-name c))))
                   (when (and (not (member k affected :test #'string=))
                              (or (intersection frontier
                                                (mapcar #'%cap-key
                                                        (capability-depends-on c))
                                                :test #'string=)
                                  (member k contract-deps :test #'string=)))
                     (push k affected)
                     (push k next))))
               (setf frontier next)))
    (let ((caps (remove-if-not
                 (lambda (c) (member (%cap-key (capability-name c)) affected
                                     :test #'string=))
                 *capabilities*)))
      (values caps
              (sort (remove-duplicates
                     (remove nil
                             (cons (let ((self (find-capability name)))
                                     (and self (capability-gate self)))
                                   (mapcar #'capability-gate caps)))
                     :test #'string=)
                    #'string<)))))

(defun capability-gap-report (wanted &optional (stream *standard-output*))
  "Ο ΑΝΑΛΥΤΗΣ ΚΕΝΩΝ: έχω την ικανότητα WANTED; Αν ναι — πού ζει, τι την
   αποδεικνύει, από τι εξαρτάται. Αν όχι — ΤΙΜΙΑ δήλωση + οι συγγενέστερες
   υπάρχουσες + τι απαιτεί νέα δήλωση. Επιστρέφει T/NIL — ώστε το κενό να
   γίνεται ΜΑΘΗΜΑ (περιέργεια), όχι σιωπή."
  (let ((cap (find-capability wanted)))
    (cond
      (cap
       (format stream "~%✔ Την έχω: «~A» — ~A~%  έδρα: ~A · πύλη: ~A~@[ · εξαρτάται από: ~{~A~^, ~}~]~%"
               (capability-name cap) (capability-description cap)
               (capability-package cap)
               (or (capability-gate cap) "ΧΩΡΙΣ ΠΥΛΗ (δηλωμένο χρέος)")
               (capability-depends-on cap))
       t)
      (t
       (let* ((words (remove-if (lambda (w) (< (length w) 4))
                                (uiop:split-string (%cap-key wanted))))
              (near (remove-if-not
                     (lambda (c)
                       (some (lambda (w)
                               (search w (%cap-key (capability-name c))))
                             words))
                     *capabilities*)))
         (format stream "~%✘ ΔΕΝ την έχω: «~A» — τίμια δήλωση, όχι αυτοσχεδιασμός.~%" wanted)
         (when near
           (format stream "  Συγγενέστερες υπάρχουσες: ~{«~A»~^ · ~}~%"
                   (mapcar #'capability-name near)))
         (let ((profile (orchestrator.contracts:find-gap-profile wanted)))
           (if profile
               (progn
                 (format stream "  Απαιτούμενα ΣΥΜΒΟΛΑΙΑ (δηλωμένο προφίλ, έλεγχος ύπαρξης μηχανικός):~%")
                 (dolist (req profile)
                   (format stream "    ~:[✘ ΛΕΙΠΕΙ~;✔ υπάρχει~]: ~A~%"
                           (orchestrator.contracts:find-contract req) req)))
               (format stream "  Απόκτηση = έδρα-πακέτο + κρίσιμες συναρτήσεις υπό ΣΥΜΒΟΛΑΙΟ (σκοπός/προ/μετα/παρενέργειες/policy/τεστ/ρόλος) + ΠΥΛΗ απόδειξης + εξαρτήσεις, με υιοθέτηση ΜΟΝΟ μέσω σκιάς/έγκρισης (Σ11/Φ5).~%"))))
       nil))))


;;; ============================================================================
;;; Η ΣΥΝΕΝΩΣΗ — ικανότητες ⋈ συμβόλαια ⋈ θεσμός (η δουλειά του καθρέφτη)
;;; ============================================================================
;;;
;;; Το contract subsystem (orchestrator.contracts) και το Ίδρυμα
;;; (orchestrator.institution) είναι καθαροί πυρήνες που δεν γνωρίζουν ο ένας
;;; τον άλλον. ΕΔΩ, στο αυτο-μοντέλο, γίνεται η συνένωση: ποια συμβόλαια
;;; καλύπτουν ποιες ικανότητες, και η επικύρωση με ΠΛΗΡΕΣ πλαίσιο.

(defun contract-coverage ()
  "Η ΚΑΛΥΨΗ: plist με το τίμιο ισοζύγιο —
   :contracts N :full/:partial/:none (ικανότητες κατά βαθμό κάλυψης των
   κρίσιμων συναρτήσεών τους) :uncovered ((cap . (fn…)) …) :orphans (συμβόλαια
   που δείχνουν ανύπαρκτη ικανότητα). Συνάρτηση καλύπτεται από ομώνυμο
   συμβόλαιο ή από συμβόλαιο-ΠΡΩΤΟΚΟΛΛΟ της ικανότητάς της (ομαδικό)."
  (let ((full '()) (partial '()) (none '()) (uncovered '()))
    (dolist (cap *capabilities*)
      (let* ((cn (capability-name cap))
             (fns (capability-functions cap))
             (protocol-p (find-if (lambda (c)
                                    (member (orchestrator.contracts:contract-kind c)
                                            '(:protocol :capability)))
                                  (orchestrator.contracts:contracts-for-capability cn)))
             (missing (if protocol-p '()
                          (remove-if
                           (lambda (f)
                             (let ((c (orchestrator.contracts:find-contract f)))
                               (and c (orchestrator.contracts:contract-capability c)
                                    (string= (%cap-key (orchestrator.contracts:contract-capability c))
                                             (%cap-key cn)))))
                           fns))))
        (cond ((null missing) (push cn full))
              ((= (length missing) (length fns)) (push cn none))
              (t (push cn partial)))
        (when missing (push (cons cn missing) uncovered))))
    (list :contracts (length (orchestrator.contracts:all-contracts))
          :full (nreverse full) :partial (nreverse partial) :none (nreverse none)
          :uncovered (nreverse uncovered)
          :orphans (mapcar #'orchestrator.contracts:contract-name
                           (remove-if (lambda (c)
                                        (or (null (orchestrator.contracts:contract-capability c))
                                            (find-capability (orchestrator.contracts:contract-capability c))))
                                      (orchestrator.contracts:all-contracts))))))

(defun validate-all-contracts (&key test-exists-p)
  "Επικύρωση συμβολαίων με ΠΛΗΡΕΣ πλαίσιο: ικανότητες από εδώ, ρόλοι/Ίδρυμα
   από το orchestrator.institution, ύπαρξη τεστ από τον καλούντα (CLI)."
  (orchestrator.contracts:validate-contracts
   :capability-exists-p #'find-capability
   :role-exists-p #'orchestrator.institution:find-role
   :test-exists-p test-exists-p
   :institution (orchestrator.institution:the-institution)
   :coordination-engine-role-p
   (lambda ()
     (let ((inst (orchestrator.institution:the-institution)))
       (and inst (orchestrator.institution:find-role
                  (orchestrator.institution:institution-coordination-engine inst)))))))


;;; ── Βοηθός: φύλλα του δέντρου κλάσεων (MOP) ──
(defun %class-leaves (class)
  (let ((subs (sb-mop:class-direct-subclasses class)))
    (if subs (mapcan #'%class-leaves subs) (list class))))

;;; ============================================================================
;;; Οι όψεις του πυρήνα — καθεμία ΔΙΑΒΑΖΕΙ, δεν αφηγείται
;;; ============================================================================

;; Η γνωσιακή ροή: τα στάδια όπως τα τεκμηριώνουν ΤΑ ΙΔΙΑ τα generics της.
(register-self-aspect :pipeline "Η γνωσιακή μου ροή (τα στάδια, από τα ίδια τα generics)"
 (lambda ()
   (loop for (label sym) in '(("① αποδόμηση" nil)
                              ("⓪ διαλογή" orchestrator.cognition:triage)
                              ("② σχεδιασμός" orchestrator.cognition:plan)
                              ("③ εκτέλεση+επαλήθευση" orchestrator.cognition:execute-step)
                              ("④·5 αυτο-κριτική" orchestrator.cognition:critique)
                              ("⑤ σύνθεση" orchestrator.cognition:synthesize))
         collect (if sym
                     (format nil "~A: ~A" label
                             (first (uiop:split-string
                                     (or (documentation sym 'function) "—")
                                     :separator (string #\Newline))))
                     (format nil "~A: φυσική γλώσσα → frame (ταξινομητές: ~{~A~^, ~})"
                             label (orchestrator.cognition:classifiers))))))

;; Οι προθέσεις που καταλαβαίνω = οι υποκλάσεις του frame, ΤΩΡΑ (MOP).
(register-self-aspect :intents "Οι προθέσεις που καταλαβαίνω (MOP: υποκλάσεις του frame, ζωντανά)"
 (lambda ()
   (let ((leaves (remove (find-class 'orchestrator.cognition:frame)
                         (%class-leaves (find-class 'orchestrator.cognition:frame)))))
     (list (format nil "~D προθέσεις: ~{~(~A~)~^, ~}"
                   (length leaves)
                   (mapcar #'class-name leaves))))))

;; Οι συλλογιστικοί κανόνες = οι υποκλάσεις του legal-rule, ΤΩΡΑ (MOP).
(register-self-aspect :rules "Οι κανόνες συλλογισμού μου (MOP: υποκλάσεις του legal-rule, ζωντανά)"
 (lambda ()
   (let ((rules (orchestrator.inference:all-legal-rules)))
     (list (format nil "~D ανατρέψιμοι (defeasible) κανόνες στον JTMS: ~{~(~A~)~^, ~}"
                   (length rules)
                   (mapcar #'orchestrator.inference:rule-name rules))))))

;; Τα πακέτα μου — ο σκελετός των υποσυστημάτων, από τη ζωντανή εικόνα.
(register-self-aspect :packages "Τα υποσυστήματά μου (πακέτα της εικόνας, ζωντανά)"
 (lambda ()
   (let ((mine (sort (remove-if-not
                      (lambda (p) (eql 0 (search "ORCHESTRATOR." (package-name p))))
                      (list-all-packages))
                     #'string< :key #'package-name)))
     (list (format nil "~D πακέτα orchestrator.* — μεταξύ τους: ~{~(~A~)~^, ~}"
                   (length mine)
                   (subseq (mapcar #'package-name mine) 0 (min 14 (length mine))))))))

;; Η μνήμη μου — οι πέντε ικανότητες πάνω στο ένα ρεύμα, με ζωντανά πλήθη.
(register-self-aspect :memory "Η μνήμη μου (το βιωματικό ρεύμα, μετρημένο τώρα)"
 (lambda ()
   (multiple-value-bind (ok n) (orchestrator.memory:verify-episode-chain)
     (list (format nil "~D επεισόδια (αλυσίδα ~:[ΣΠΑΣΜΕΝΗ~;ακέραιη~]) · ~D ανοιχτοί στόχοι · ~D οπλισμένες προθέσεις"
                   n ok
                   (length (orchestrator.memory:open-goals))
                   (length (orchestrator.memory:armed-intentions)))))))
