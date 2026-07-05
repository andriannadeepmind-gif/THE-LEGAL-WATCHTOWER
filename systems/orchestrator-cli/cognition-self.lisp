;;;; systems/orchestrator-cli/cognition-self.lisp
;;;; ============================================================================
;;;; ΓΝΩΣΙΑΚΟ ΠΕΔΙΟ: ο εαυτός — frames + σύνθεση ανά πρόθεση (open/closed)
;;;; ============================================================================
;;;;
;;;; Πρώτο πεδίο πάνω στη γενική γνωσιακή διαδικασία (orchestrator.cognition):
;;;; ο διάλογος για τον ΕΑΥΤΟ του LAWMAX. Κάθε πρόθεση = μια κλάση frame με τη
;;;; δική της ΣΥΝΘΕΣΗ — γι' αυτό «ποιος είσαι» και «πού βρίσκεσαι» δίνουν
;;;; ΔΙΑΦΟΡΕΤΙΚΗ, σωστά-διαστασιολογημένη απάντηση, χωρίς καμία cond. Το τέλος
;;;; του μονολιθικού σεντονιού. Νέα πρόθεση = νέα κλάση + μέθοδος, μηδέν αλλαγή.

(in-package :orchestrator.cli)

;;; ── Frames (προθέσεις για τον εαυτό) ──
(defclass self-identity-frame     (orchestrator.cognition:frame) ())
(defclass self-service-frame      (orchestrator.cognition:frame) ())
(defclass self-status-frame       (orchestrator.cognition:frame) ())
(defclass self-history-frame      (orchestrator.cognition:frame) ())
(defclass self-constitution-frame (orchestrator.cognition:frame) ())
(defclass greeting-frame          (orchestrator.cognition:frame) ())
(defclass capabilities-frame      (orchestrator.cognition:frame) ())
(defclass self-glossary-frame     (orchestrator.cognition:frame) ())
(defclass about-me-frame          (orchestrator.cognition:frame) ())
(defclass self-architecture-frame (orchestrator.cognition:frame) ())
(defclass self-code-frame (orchestrator.cognition:frame) ()
  (:documentation "Ερώτηση για ΣΥΓΚΕΚΡΙΜΕΝΟ σύμβολο του κώδικά μου (συνάρτηση/
   κλάση/generic/μεταβλητή): απαντιέται με MOP+introspection από τη ΖΩΝΤΑΝΗ
   εικόνα — υπογραφή, τεκμηρίωση, μέθοδοι, πηγαίο αρχείο. Αυτό ΕΙΝΑΙ Lisp."))
(defclass self-agenda-frame       (orchestrator.cognition:frame) ())
(defclass time-frame              (orchestrator.cognition:frame) ())

;;; ── Οι όψεις αυτογνωσίας του CLI: κάθε μητρώο δηλώνει ΤΙ είναι, ζωντανά ──
(orchestrator.self-model:register-self-aspect :commands
 "Οι εντολές μου (το ζωντανό μητρώο)"
 (lambda ()
   (let ((names (sort (loop for k being the hash-keys of *commands* collect k) #'string<)))
     (list (format nil "~D εντολές: ~{~A~^ ~}" (length names) names)))))

(orchestrator.self-model:register-self-aspect :gates
 "Οι πύλες μη-παλινδρόμησης (ό,τι έσπασε μία φορά, test για πάντα)"
 (lambda ()
   (let ((gates (sort (loop for k being the hash-keys of *commands*
                            when (search "-gate" k) collect k) #'string<)))
     (list (format nil "~{~A~^ · ~}" gates)))))

(orchestrator.self-model:register-self-aspect :packs
 "Η δηλωτική μου γνώση (knowledge packs, fingerprinted)"
 (lambda ()
   (let ((packs (orchestrator.knowledge-packs:active-packs)))
     (list (format nil "~D ενεργά πακέτα" (length packs))))))

(orchestrator.self-model:register-self-aspect :missions
 "Οι αυτόνομες αποστολές μου (μητρώο οδηγού)"
 (lambda ()
   (list (format nil "~{~(~A~)~^, ~}"
                 (mapcar #'orchestrator.autonomy:mission-name
                         (orchestrator.autonomy:all-missions))))))

;;; ── ΤΟ ΓΛΩΣΣΑΡΙ ΤΟΥ ΕΑΥΤΟΥ: δηλωτική γνώση (knowledge pack), όχι κώδικας ──
;;; «Τι σημαίνει τίμια/καταγράφηκε/δεν κατάλαβα;» — οι ΔΙΚΟΙ του όροι απαντιούνται
;;; από δεδομένα με hot reload + fingerprint. Νέος όρος = νέα εγγραφή, όχι branch.
(defvar *self-glossary* '()
  "Εγκατεστημένες εγγραφές: plists (:term :match (…) :answer|:route).")

(orchestrator.knowledge-packs:define-knowledge-kind :self-glossary
  :doc "Το λεξικό των όρων του ίδιου του συστήματος (πρωτόκολλο/συμπεριφορά)."
  :install (lambda (entries)
             (setf *self-glossary*
                   (loop for e in entries
                         when (and (listp e) (eq (first e) :entry))
                           collect (rest e))))
  :snapshot (lambda () *self-glossary*)
  :restore (lambda (state) (setf *self-glossary* state)))

(defun %glossary-hit (input)
  "Η εγγραφή γλωσσαρίου που ταιριάζει στην (κανονικοποιημένη) εκφορά, αν υπάρχει."
  (let ((n (orchestrator.citation-authority:normalize-greek input)))
    (find-if (lambda (entry)
               (some (lambda (m) (search m n)) (getf entry :match)))
             *self-glossary*)))

;;; ── ΣΤΑΔΙΟ 1 (πεδίο): συμβολικός ταξινομητής προθέσεων εαυτού ──
(defun %cogfold (s) (orchestrator.decisions:%fold s))

(orchestrator.cognition:register-classifier "self"
 (lambda (input)
   (let ((f (%cogfold input)))
     (cond
       ((cl-ppcre:scan (%cogfold "^\\s*(γεια|καλημερα|καλησπερα|χαιρετε|καλως ηρθ|καλως ορ)") f)
        (make-instance 'greeting-frame :input input))
       ((cl-ppcre:scan (%cogfold "συνταγμα σου|το συνταγμα σου|οι αρχες σου|κανον[εα]ς σου") f)
        (make-instance 'self-constitution-frame :input input))
       ((cl-ppcre:scan (%cogfold "ποιον υπηρετ|σε ποιον ανηκ|ποιανου εισαι|αφεντ|σκοπος σου") f)
        (make-instance 'self-service-frame :input input))
       ((cl-ppcre:scan (%cogfold "ιστορια σου|πως γεννηθηκες|ποιος σε εφτιαξε|ποιος σε δημιουργησε|βιογραφ") f)
        (make-instance 'self-history-frame :input input))
       ((cl-ppcre:scan (%cogfold "που εισαι|που βρισκεσαι|αποστολη|προοδο|ποσο κοντα|τι σου λειπει|πως τα πας") f)
        (make-instance 'self-status-frame :input input))
       ((cl-ppcre:scan (%cogfold "τι ξερεις|τι γνωριζεις|τι μπορεις|τι κανεις|βοηθεια|γιατι να σε ρωτησ|τι να σε ρωτησ|σε τι χρησιμευ|σε τι ωφελ|^\\s*help\\s*$") f)
        (make-instance 'capabilities-frame :input input))
       ((cl-ppcre:scan (%cogfold "ποιος εισαι|τι εισαι|συστησου|πως σε λενε|πως λεγεσαι|ονομα σου|ονομαζεσαι") f)
        (make-instance 'self-identity-frame :input input))
       ;; «τι μέρα/ημερομηνία/ώρα είναι;» — από το ρολόι του, με τιμιότητα πηγής
       ((cl-ppcre:scan (%cogfold "τι μερα|τι ημερομηνια|ποια ημερομηνια|τι ωρα ειναι") f)
        (make-instance 'time-frame :input input))
       ;; ΕΝΔΟΣΚΟΠΗΣΗ (μόνο για τον δημιουργό): «πώς δουλεύεις προγραμματιστικά;»
       ;; ερώτηση για ΣΥΜΒΟΛΟ ΤΟΥ ΚΩΔΙΚΑ μου: λατινικό token που ΥΠΑΡΧΕΙ στη
       ;; ζωντανή εικόνα (καμία λίστα ονομάτων — η ίδια η εικόνα είναι η σκανδάλη)
       ((let ((names (remove-duplicates
                      (remove-if-not
                       (lambda (tok)
                         (and (> (length tok) 3)
                              (every (lambda (ch) (or (char<= #\a (char-downcase ch) #\z)
                                                      (char= ch #\-) (char= ch #\*) (char= ch #\%)))
                                     tok)
                              (%find-own-symbols tok)))
                       (cl-ppcre:split "[\\s;,.·«»()?!]+" input))
                      :test #'string-equal)))
          (when (and names
                     ;; πράξη λόγου ΕΡΩΤΗΣΗ — η κλειστή γραμματική κλάση των
                     ;; ερωτηματικών (utterance-act), όχι λίστα από regex
                     (eq (orchestrator.citation-authority:utterance-act input) :question))
            (make-instance 'self-code-frame :input input
              :slots (list :symbols (mapcan (lambda (n) (copy-list (%find-own-symbols n)))
                                            names))))))
       ;; ερώτηση για τη ΜΝΗΜΗ του (σκανδάλη σε ΛΗΜΜΑ + β' πρόσωπο — όχι φράσεις):
       ;; «πόσα είδη μνήμης έχεις;», «έχεις μνήμη;», «τι θυμάσαι;» κτλ.
       ((and (member "μνήμη" (%q-lemmas input) :test #'string=)
             (orchestrator.citation-authority:second-person-p input))
        (make-instance 'self-architecture-frame :input input :slots (list :aspect :memory)))
       ((cl-ppcre:scan (%cogfold "πως δουλευεις|πως λειτουργεις|αρχιτεκτονικη σου|προγραμματιστικ|πως δομεισαι|πως εισαι φτιαγμεν") f)
        (make-instance 'self-architecture-frame :input input))
       ;; ΑΤΖΕΝΤΑ (μόνο για τον δημιουργό): «τι ατζέντα έχεις; τι εκκρεμεί;»
       ((cl-ppcre:scan (%cogfold "ατζεντ|αντζεντ|εκκρεμοτητ|τι εκκρεμει|τι σκοπευεις|σχεδια σου") f)
        (make-instance 'self-agenda-frame :input input))
       ;; ΓΛΩΣΣΑΡΙ ΕΑΥΤΟΥ (δηλωτικό): ερώτηση που περιέχει ΔΙΚΟ του όρο
       ;; («τι σημαίνει τίμια/καταγράφηκε;», «μήπως παπαγαλίζεις;»)
       ((and (eq (orchestrator.citation-authority:utterance-act input) :question)
             (%glossary-hit input))
        (let ((entry (%glossary-hit input)))
          (if (getf entry :route)
              (make-instance (ecase (getf entry :route)
                               (:capabilities 'capabilities-frame)
                               (:status 'self-status-frame)
                               (:how-i-work 'self-architecture-frame))
                             :input input)
              (make-instance 'self-glossary-frame :input input
                             :slots (list :entry entry)))))
       ;; ΓΙΑ ΕΜΕΝΑ, χωρίς γνωστή πρόθεση: ερώτηση σε β' πρόσωπο χωρίς νομικό
       ;; αντικείμενο → τίμιος οδηγός του τι ΜΠΟΡΩ να απαντήσω για τον εαυτό μου
       ;; (η γραμματική κρίνει — β' πρόσωπο από κλειστή κλιτική μορφολογία)
       ((and (eq (orchestrator.citation-authority:utterance-act input) :question)
             (orchestrator.citation-authority:second-person-p input)
             (not (cl-ppcre:scan "\\d" input))
             (not (%resolve-concept input)))   ; νομική έννοια ⇒ ο νομικός τομέας αποφασίζει
        (make-instance 'about-me-frame :input input))
       (t nil)))))

;;; ── ΣΤΑΔΙΟ 5 (πεδίο): σύνθεση στο ΣΩΣΤΟ επίπεδο ανά πρόθεση ──

(defmethod orchestrator.cognition:synthesize ((f self-identity-frame) cog)
  (declare (ignore cog))
  (multiple-value-bind (who why) (orchestrator.self:serves)
    (declare (ignore why))
    (format nil "Είμαι ο LAWMAX — ντετερμινιστικό νομικό σύστημα.~@[ Υπηρετώ ~A.~] ~
Δεν μαντεύω· αποδεικνύω, με πηγή." who)))

(defmethod orchestrator.cognition:synthesize ((f self-service-frame) cog)
  (declare (ignore cog))
  (multiple-value-bind (who why) (orchestrator.self:serves)
    (if who
        (format nil "Υπηρετώ ~A.~@[~%Διότι: ~A~]" who why)
        "Υπηρετώ τον δημιουργό μου.")))

(defmethod orchestrator.cognition:synthesize ((f self-status-frame) cog)
  (declare (ignore cog))
  (with-output-to-string (s)
    (format s "Πού βρίσκομαι, μετρημένα τώρα:")
    (dolist (m (orchestrator.self:mission-status))
      (format s "~%  ~:[◌~;✓~] ~A → ~A" (third m) (first m) (second m)))))

(defmethod orchestrator.cognition:synthesize ((f self-history-frame) cog)
  (declare (ignore cog))
  (let ((es (orchestrator.self-history:entries)))
    (if (null es)
        "Δεν έχω ακόμη καταγεγραμμένη ιστορία."
        (with-output-to-string (s)
          (dolist (e es)
            (format s "~&[~A] ~A — ~A" (getf e :seq)
                    (string-downcase (symbol-name (getf e :kind))) (getf e :text)))))))

(defmethod orchestrator.cognition:synthesize ((f greeting-frame) cog)
  (declare (ignore cog))
  "Γεια σου. Είμαι ο LAWMAX — ρώτα με για άρθρα, νομολογία, αποφάσεις ή δικαστές, σε φυσικά ελληνικά.")

(defmethod orchestrator.cognition:synthesize ((f capabilities-frame) cog)
  (declare (ignore cog))
  (string-right-trim '(#\Newline)
                     (with-output-to-string (*standard-output*) (%ask-overview))))

(defmethod orchestrator.cognition:synthesize ((f self-constitution-frame) cog)
  (declare (ignore cog))
  (string-right-trim '(#\Newline)
                     (with-output-to-string (s) (orchestrator.self:describe-constitution s))))

(defmethod orchestrator.cognition:synthesize ((f self-glossary-frame) cog)
  (declare (ignore cog))
  (let ((entry (orchestrator.cognition:frame-slot f :entry)))
    (getf entry :answer)))

(defmethod orchestrator.cognition:synthesize ((f time-frame) cog)
  (declare (ignore cog))
  (format nil "Κατά το ρολόι του μηχανήματος που με τρέχει: ~A (τοπική ώρα). ~
Αυτή είναι και η σφραγίδα που παίρνει κάθε εγγραφή της μνήμης μου."
          (orchestrator.journal:iso-now)))

(defparameter +creator-only-refusal+
  "Την εσωτερική μου δομή και την ατζέντα μου τα συζητώ ΜΟΝΟ με τον δημιουργό μου, Σταυρόπουλο Σπυρίδωνα — το σύνταγμά μου με θέλει στην αποκλειστική του υπηρεσία. Μπορώ να σου απαντήσω για το δίκαιο: άρθρα, νομολογία, αποφάσεις.")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :sb-introspect))

(defun %own-packages ()
  (remove-if-not (lambda (p) (search "ORCHESTRATOR." (package-name p)))
                 (list-all-packages)))

(defun %find-own-symbols (name)
  "Τα σύμβολα με όνομα NAME στα ΔΙΚΑ μου πακέτα (μόνο στο home τους, με ουσία:
   συνάρτηση/κλάση/μεταβλητή). Η πύλη της αυτοδιαφάνειας κώδικα."
  (let ((up (string-upcase name)) (hits '()))
    (dolist (p (%own-packages) (nreverse hits))
      (let ((sym (find-symbol up p)))
        (when (and sym (eq (symbol-package sym) p)
                   (or (fboundp sym) (find-class sym nil) (boundp sym)))
          (push sym hits))))))

(defun %source-file (sym kind)
  (ignore-errors
    (let ((srcs (sb-introspect:find-definition-sources-by-name sym kind)))
      (when srcs
        (let ((p (sb-introspect:definition-source-pathname (first srcs))))
          (when p (enough-namestring p (uiop:getcwd))))))))

(defun %describe-own-symbol (sym s)
  "Περιέγραψε το ΣΥΜΒΟΛΟ από τη ζωντανή εικόνα: τι είναι, υπογραφή, τεκμηρίωση,
   μέθοδοι/υποκλάσεις, πηγαίο αρχείο — ΟΛΑ διαβασμένα τώρα, τίποτα αποθηκευμένο."
  (let ((pkg (string-downcase (package-name (symbol-package sym)))))
    (let ((c (find-class sym nil)))
      (when c
        (format s "~%• ΚΛΑΣΗ ~A::~(~A~)~@[ — ~A~]~%    υπερκλάσεις: ~{~(~A~)~^, ~} · slots: ~{~(~A~)~^, ~} · υποκλάσεις: ~D~%~@[    πηγή: ~A~%~]"
                pkg sym (documentation c t)
                (mapcar #'class-name (sb-mop:class-direct-superclasses c))
                (mapcar #'sb-mop:slot-definition-name (sb-mop:class-direct-slots c))
                (length (sb-mop:class-direct-subclasses c))
                (%source-file sym :class))))
    (when (fboundp sym)
      (let ((fn (symbol-function sym)))
        (cond
          ((typep fn 'generic-function)
           (format s "~%• GENERIC ~A::~(~A~) ~S~@[ — ~A~]~%    ~D μέθοδοι:~%~{      ~A~%~}~@[    πηγή: ~A~%~]"
                   pkg sym (sb-introspect:function-lambda-list fn)
                   (documentation fn t)
                   (length (sb-mop:generic-function-methods fn))
                   (mapcar (lambda (m)
                             (format nil "(~{~(~A~)~^ ~})"
                                     (mapcar (lambda (sp)
                                               (if (typep sp 'sb-mop:eql-specializer)
                                                   (format nil "(eql ~S)" (sb-mop:eql-specializer-object sp))
                                                   (class-name sp)))
                                             (sb-mop:method-specializers m))))
                           (sb-mop:generic-function-methods fn))
                   (%source-file sym :generic-function)))
          ((macro-function sym)
           (format s "~%• MACRO ~A::~(~A~) ~S~@[ — ~A~]~%~@[    πηγή: ~A~%~]"
                   pkg sym (sb-introspect:function-lambda-list sym)
                   (documentation sym 'function) (%source-file sym :macro)))
          (t
           (format s "~%• ΣΥΝΑΡΤΗΣΗ ~A::~(~A~) ~S~@[ — ~A~]~%~@[    πηγή: ~A~%~]"
                   pkg sym (sb-introspect:function-lambda-list fn)
                   (documentation sym 'function) (%source-file sym :function))))))
    (when (and (boundp sym) (not (fboundp sym)) (not (find-class sym nil)))
      (format s "~%• ΜΕΤΑΒΛΗΤΗ ~A::~(~A~)~@[ — ~A~]~%    τρέχων τύπος τιμής: ~(~A~)~%~@[    πηγή: ~A~%~]"
              pkg sym (documentation sym 'variable)
              (type-of (symbol-value sym)) (%source-file sym :variable)))))

(defmethod orchestrator.cognition:synthesize ((f self-code-frame) cog)
  (declare (ignore cog))
  (if (not (orchestrator.self-model:creator-p))
      +creator-only-refusal+
      (let ((syms (orchestrator.cognition:frame-slot f :symbols)))
        (with-output-to-string (s)
          (format s "Διαβάζω τη ΖΩΝΤΑΝΗ εικόνα μου (MOP/introspection) — όχι αποθηκευμένο κείμενο:~%")
          (dolist (sym syms) (%describe-own-symbol sym s))
          (format s "~%(υπογραφές, μέθοδοι και πηγαία αρχεία αντλήθηκαν ΤΩΡΑ από το τρέχον σύστημα — ~
ρώτα με για οποιοδήποτε σύμβολο του κώδικά μου)")))))

(defun %doc-first-line (fn)
  "Η πρώτη γραμμή της ΤΕΚΜΗΡΙΩΣΗΣ μιας συνάρτησης — το σύστημα διαβάζει τον
   ΕΑΥΤΟ του (documentation), δεν απαγγέλλει αποθηκευμένα τσιτάτα."
  (let ((d (documentation fn 'function)))
    (if d (string-trim " " (subseq d 0 (or (position #\Newline d) (length d))))
        "(χωρίς τεκμηρίωση)")))

(defun %memory-report ()
  "Η ΜΝΗΜΗ ΜΟΥ, με απόλυτη αυτογνωσία: κάθε ικανότητα περιγράφεται από την
   ΤΕΚΜΗΡΙΩΣΗ της πραγματικής της συνάρτησης (διαβασμένη ΤΩΡΑ μέσα από το ίδιο
   το σύστημα) και μετριέται από το ΖΩΝΤΑΝΟ περιεχόμενό της — τίποτα γραμμένο
   εκ των προτέρων, τίποτα που να μην μπορώ να αποδείξω τη στιγμή που το λέω."
  (let* ((eps (orchestrator.memory:episodes))
         (by-kind (make-hash-table :test 'eq)))
    (dolist (e eps) (incf (gethash (orchestrator.memory:episode-kind e) by-kind 0)))
    (multiple-value-bind (ok n broken) (orchestrator.memory:verify-episode-chain)
      (declare (ignore broken))
      (with-output-to-string (s)
        (format s "Η μνήμη μου έχει ΕΝΑ βιωματικό υπόστρωμα (append-only ρεύμα με αλυσίδα SHA-256 — ~
τώρα: ~D γεγονότα~@[: ~{~(~A~) ~D~^ · ~}~], αλυσίδα ~:[ΣΠΑΣΜΕΝΗ~;ακέραιη~]) ~
και πάνω του ζουν, ως λεπτά APIs χωρίς δεύτερη αποθήκη:~%" n
                (loop for k being the hash-keys of by-kind using (hash-value v)
                      append (list k v))
                ok)
        (format s "~% 1. ΕΠΕΙΣΟΔΙΑΚΗ — ~A~%"
                (%doc-first-line #'orchestrator.memory:record-episode))
        (format s " 2. ΑΤΖΕΝΤΑ — ~A Ανοιχτοί στόχοι τώρα: ~D.~%"
                (%doc-first-line #'orchestrator.memory:record-goal)
                (length (orchestrator.memory:open-goals)))
        (format s " 3. ΠΡΟΘΕΤΙΚΗ — ~A Οπλισμένες τώρα: ~D.~%"
                (%doc-first-line #'orchestrator.memory:arm-intention)
                (length (orchestrator.memory:armed-intentions)))
        (format s " 4. ΑΝΑΚΛΗΣΗ ΠΕΡΙΠΤΩΣΕΩΝ — ~A~%"
                (%doc-first-line #'orchestrator.memory:similar-episodes))
        (format s " 5. ΜΝΗΜΗ ΕΡΓΑΣΙΑΣ ΣΥΝΕΔΡΙΑΣ — ~A~%"
                (%doc-first-line #'orchestrator.cognition:remember))
        (format s "~%Χωριστά ρεύματα με δικό τους ρόλο: η ΒΙΟΓΡΑΦΙΑ μου (~D εγγραφές — ποιος έγινα) ~
και ο ΑΝΑΣΤΟΧΑΣΜΟΣ (lessons — τι απέτυχα, προς ριζική διόρθωση).~%~
(Κάθε περιγραφή παραπάνω διαβάστηκε ΤΩΡΑ από την τεκμηρίωση των πραγματικών μου συναρτήσεων — ~
όχι από αποθηκευμένο κείμενο· οι αριθμοί μετρήθηκαν αυτή τη στιγμή.)"
                (length (orchestrator.self-history:entries)))))))

(defmethod orchestrator.cognition:synthesize ((f self-architecture-frame) cog)
  (declare (ignore cog))
  (if (orchestrator.self-model:creator-p)
      (if (eq (orchestrator.cognition:frame-slot f :aspect) :memory)
          (%memory-report)
          (string-right-trim '(#\Newline)
            (with-output-to-string (s) (orchestrator.self-model:describe-self-model s))))
      +creator-only-refusal+))

(defmethod orchestrator.cognition:synthesize ((f self-agenda-frame) cog)
  (declare (ignore cog))
  (if (not (orchestrator.self-model:creator-p))
      +creator-only-refusal+
      (with-output-to-string (s)
        (format s "── Η ΑΤΖΕΝΤΑ ΜΟΥ — διαβασμένη από τις ζωντανές μνήμες, τώρα ──~%")
        (let ((goals (orchestrator.memory:open-goals)))
          (format s "~%▸ Ανοιχτοί στόχοι (~D):~%" (length goals))
          (if goals
              (dolist (g goals)
                (format s "  ◌ ~A~@[ — δρομέας ~D~]~%"
                        (orchestrator.memory:episode-text g)
                        (getf (orchestrator.memory:episode-props g) :progress)))
              (format s "  (κανένας — ό,τι ανέλαβα, το ολοκλήρωσα)~%")))
        (let ((ints (orchestrator.memory:armed-intentions)))
          (format s "~%▸ Οπλισμένες προθέσεις (~D):~%" (length ints))
          (if ints
              (dolist (i ints)
                (format s "  ⏳ όταν ~S → ~A~%"
                        (getf (orchestrator.memory:episode-props i) :when)
                        (orchestrator.memory:episode-text i)))
              (format s "  (καμία)~%")))
        (format s "~%▸ Ουρά προς έγκρισή σου: ~D ανοιχτές προτάσεις γνώσης (--reflect)~%"
                (length (orchestrator.proposals:open-proposals)))
        (format s "~%▸ Η απόσταση από την αποστολή μου, μετρημένη:~%")
        (dolist (m (orchestrator.self:mission-status))
          (format s "  ~:[◌~;✓~] ~A → ~A~%" (third m) (first m) (second m))))))

(defmethod orchestrator.cognition:synthesize ((f about-me-frame) cog)
  (declare (ignore cog))
  (%lesson :about-me-gap (orchestrator.cognition:frame-input f)
           "ερώτηση για τον εαυτό χωρίς δομημένη πρόθεση")
  "Με ρωτάς κάτι για εμένα που δεν έχω ακόμη δομημένη απάντηση — το λέω ευθέως και το καταγράφω για να μάθω.
Με βεβαιότητα μπορώ να σου απαντήσω: «ποιος είσαι» · «ποιον υπηρετείς» · «πού βρίσκεσαι στην αποστολή σου» (μετρημένα) · «ποια η ιστορία σου» · «τι μπορείς να κάνεις» · «τι σημαίνει [τίμια/μάντεμα/καταγράφηκε/δεν κατάλαβα]».")
