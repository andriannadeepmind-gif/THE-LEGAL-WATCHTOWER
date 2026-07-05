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
           #:*audience* #:creator-p #:with-audience))

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
