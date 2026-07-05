;;;; source/legal-knowledge.lisp
;;;; ============================================================================
;;;; ΕΝΟΠΟΙΗΜΕΝΗ ΓΝΩΣΗ — το σύστημα συλλογίζεται πάνω σε ΟΛΗ την γνώση του
;;;; ============================================================================
;;;;
;;;; Ο McCarthy (Advice Taker, 1958) δεν ζήτησε πολλούς έξυπνους υπολογισμούς·
;;;; ζήτησε ΜΙΑ γνώση και ΕΝΑΝ συλλογισμό: μια ερώτηση ενεργοποιεί ό,τι σχετικό
;;;; ξέρει το σύστημα — απ' όλους τους εγκεφάλους μαζί — και η απάντηση βγαίνει
;;;; με ΜΙΑ απόδειξη που διασχίζει όλη την γνώση. Και, το κρίσιμο: το σύστημα
;;;; ΞΕΡΕΙ ΤΙ ΔΕΝ ΞΕΡΕΙ — «δεν το συμπεραίνω, γιατί μου λείπει το Χ».
;;;;
;;;; Οι κανόνες (L1–L4, σύγκρουση, χρόνος, ποινή) είναι ΗΔΗ καθολικοί: το
;;;; all-legal-rules τους ανακαλύπτει όλους μέσω του MOP. Άρα η ενοποίηση ΔΕΝ
;;;; είναι νέα μηχανή — είναι το να μπουν ΟΛΑ τα γεγονότα σε ΕΝΑΝ εγκέφαλο και
;;;; να ρωτηθεί. Εδώ ζει ΜΟΝΟ αυτό: η συνάθροιση, η ερώτηση, και η μετα-γνώση
;;;; (τι λείπει). Καμία συλλογιστική λογική δεν αντιγράφεται — μόνο ενορχηστρώνεται.

(defpackage :orchestrator.knowledge
  (:use :cl :orchestrator.inference)
  (:export #:reason-over #:ask #:missing-for #:knowledge-answer #:satisfy-patterns
           #:register-resolver #:clear-resolvers #:pursue #:*extra-rules* #:planning-rules
           #:plan-goal #:plan-satisfied-p #:plan-frontier #:plan-acquired #:plan->string
           #:chain-of-thought #:explain-chain #:think #:fact->string))

(in-package :orchestrator.knowledge)

(defvar *extra-rules* '()
  "Πρόσθετοι κανόνες για σχεδιασμό/μετα-γνώση/συλλογισμό, πέραν των
   MOP-ανακαλυπτόμενων — π.χ. η όψη των δεοντικών κανόνων (tatbestand) ως
   κανόνων σχεδιασμού. Δένεται δυναμικά από τον καλούντα· ΜΙΑ έδρα.")

(defun planning-rules ()
  "ΟΛΟΙ οι κανόνες που βλέπει ο συλλογιστής: οι MOP-ανακαλυπτόμενοι + οι
   δυναμικά δεμένοι πρόσθετοι. Το ΕΝΑ σημείο επιλογής κανόνων του πακέτου."
  (append (all-legal-rules) *extra-rules*))

(defun reason-over (facts)
  "Βάλε ΟΛΑ τα FACTS (από κάθε πηγή: παραπομπές, αποφάσεις, ιεραρχία, χρόνος,
   ποινή) σε ΕΝΑΝ εγκέφαλο και τρέξε ΟΛΟΥΣ τους κανόνες μαζί. Επιστρέφει τον
   engine — κάθε συμπέρασμα κουβαλά την απόδειξή του, ανεξάρτητα από το ποιος
   εγκέφαλος το γέννησε ή πόσοι συνεργάστηκαν."
  (let ((engine (make-inference-engine)))
    (add-facts engine facts)
    (run-inference engine :rules (planning-rules))
    engine))

(defun ask (engine pattern)
  "Ρώτα την γνώση: κάθε συμπέρασμα που ενοποιείται με PATTERN, ΜΕ την απόδειξή του.
   Επιστρέφει λίστα από (FACT . PROOF-STRING)."
  (loop for (fact . nil) in (query engine pattern)
        collect (cons fact (explanation->string
                            (explain (engine-jtms engine) fact) 4))))

;;; ----------------------------------------------------------------------------
;;; ΜΕΤΑ-ΓΝΩΣΗ — «τι θα χρειαζόμουν για να το ξέρω;»
;;; ----------------------------------------------------------------------------
;;;
;;; Ένα σύστημα που συλλογίζεται την γνώση του πρέπει να συλλογίζεται και τα ΟΡΙΑ
;;; της. Όταν ένα ερώτημα ΔΕΝ συμπεραίνεται, δεν αρκεί το «όχι»: για κάθε κανόνα
;;; που ΘΑ μπορούσε να το παραγάγει, βρίσκουμε ποιες προϋποθέσεις ικανοποιούνται
;;; ήδη και ποια γεγονότα ΛΕΙΠΟΥΝ — δηλαδή τι ακριβώς πρέπει να μάθει το σύστημα.

(defun %believed (engine)
  "Όλα τα γεγονότα που ΠΙΣΤΕΥΕΙ ο engine (jtms-believed-facts επιστρέφει ήδη τα
   δεδομένα, όχι κόμβους) — η τρέχουσα γνώση πάνω στην οποία μετρώ τι λείπει."
  (jtms-believed-facts (engine-jtms engine)))

(defun satisfy-patterns (patterns facts binding)
  "Greedy: ικανοποίησε όσες PATTERNS γίνεται από τα FACTS επεκτείνοντας το
   BINDING. Επιστρέφει (values FINAL-BINDING SATISFIED UNSATISFIED)."
  (let ((b binding) (ok '()) (missing '()))
    (dolist (p patterns)
      (let ((hit (loop for f in facts
                       for nb = (unify p f b)
                       unless (eq nb :fail) return nb)))
        (if hit (setf b hit ok (cons p ok)) (push p missing))))
    (values b (nreverse ok) (nreverse missing))))

(defun missing-for (engine goal)
  "Γιατί ΔΕΝ συμπεραίνεται το GOAL. Για κάθε κανόνα που το :then του ενοποιείται
   με το GOAL, επιστρέφει ένα plist:
     (:rule NAME :have (ικανοποιημένες προϋποθέσεις) :missing (ΤΙ ΛΕΙΠΕΙ)
      :blocked-by (defeaters που ΙΣΧΥΟΥΝ και θα το εμπόδιζαν))
   — δηλαδή ό,τι πρέπει να μάθει το σύστημα, ή τι το αναιρεί. Άδεια λίστα όταν
   κανένας κανόνας δεν οδηγεί στο GOAL (το ερώτημα είναι εκτός γνώσης-πεδίου)."
  (let ((facts (%believed engine)) (out '()))
    (dolist (rule (planning-rules) (nreverse out))
      (dolist (concl (if (listp (car (rule-then rule))) (rule-then rule) (list (rule-then rule))))
        (let ((b0 (unify concl goal)))
          (unless (eq b0 :fail)
            ;; Οι ΕΛΕΥΘΕΡΕΣ μεταβλητές του ερωτήματος δεν είναι περιορισμοί: κράτα
            ;; μόνο τις ground δεσμεύσεις, ώστε ο κανόνας να ταιριάξει τα άρθρα του
            ;; από τα γεγονότα (αλλιώς var-δένεται-σε-var και μπλοκάρει το match).
            (setf b0 (remove-if (lambda (pair) (var-p (cdr pair))) b0))
            (multiple-value-bind (b have missing) (satisfy-patterns (rule-when rule) facts b0)
              ;; defeaters (:unless) που ισχύουν κάτω από το ίδιο binding → μπλοκάρουν
              (let ((blockers
                      (loop for u in (rule-unless rule)
                            for iu = (instantiate u b)
                            when (member iu facts :test #'equal) collect iu)))
                (when (or missing blockers)
                  (push (list :rule (rule-name rule)
                              :have (mapcar (lambda (p) (instantiate p b)) have)
                              :missing (mapcar (lambda (p) (instantiate p b)) missing)
                              :blocked-by blockers)
                        out))))))))))

(defun knowledge-answer (facts goal &optional (stream *standard-output*))
  "Η ενοποιημένη απάντηση: συλλογίσου πάνω σε ΟΛΑ τα FACTS, και για το GOAL
   τύπωσε είτε τα συμπεράσματα ΜΕ αποδείξεις, είτε — αν δεν συμπεραίνεται — ΤΙ
   ΛΕΙΠΕΙ ή τι το αναιρεί. Επιστρέφει τον αριθμό των αποδεδειγμένων συμπερασμάτων."
  (let* ((engine (reason-over facts))
         (hits (ask engine goal)))
    (cond
      (hits
       (format stream "~&✓ ~D συμπέρασμα~:P — με απόδειξη:~%" (length hits))
       (dolist (h hits)
         (format stream "~%  ~S~%~A~%" (car h) (cdr h))))
      (t
       (format stream "~&✗ Δεν το συμπεραίνω. Η γνώση μου λέει:~%")
       (let ((gaps (missing-for engine goal)))
         (if gaps
             (dolist (g gaps)
               (format stream "~%  Ο κανόνας ~A θα το παρήγαγε — έχω~{ ~S~}·~%    ~:[δεν μου λείπει προϋπόθεση~;μου ΛΕΙΠΕΙ~{ ~S~}~]~@[~%    ΑΛΛΑ το αναιρεί:~{ ~S~}~]~%"
                       (getf g :rule) (getf g :have)
                       (getf g :missing) (getf g :missing)
                       (getf g :blocked-by)))
             (format stream "  (κανένας κανόνας δεν οδηγεί εκεί — το ερώτημα είναι εκτός του πεδίου γνώσης μου)~%")))))
    (length hits)))

;;; ============================================================================
;;; ΑΥΤΟ-ΚΑΤΕΥΘΥΝΟΜΕΝΗ ΕΡΕΥΝΑ — abductive backward-chaining με απόκτηση γνώσης
;;; ============================================================================
;;;
;;; Το forward reasoning (reason-over) απαντά «τι προκύπτει από όσα ξέρω». Εδώ το
;;; αντίστροφο, που είναι και το ανώτερο: δοσμένου ενός ΕΡΩΤΗΜΑΤΟΣ, δούλεψε
;;; ΑΝΑΠΟΔΑ μέσα από τον γράφο κανόνων και φτίαξε ΣΧΕΔΙΟ ΑΠΟΔΕΙΞΗΣ (δέντρο
;;; AND/OR). Κάθε υπο-στόχος: (α) είναι ήδη γνωστός, (β) παράγεται από άλλον
;;; κανόνα — αναδρομικά, πολλά βήματα, (γ) ΑΠΟΚΤΑΤΑΙ από τα ίδια τα δεδομένα
;;; (abduction: ρώτα το κείμενο/πηγή μέσω resolver), ή (δ) μένει στο ΜΕΤΩΠΟ της
;;; άγνοιας. Το σύστημα δεν λέει απλώς «δεν ξέρω» — κυνηγά μόνο του την γνώση που
;;; του λείπει, κι αν δεν την βρει, ΟΝΟΜΑΤΙΖΕΙ ακριβώς τι θα χρειαζόταν.

(defparameter *max-depth* 8
  "Φράγμα βάθους στην αναδρομική οπισθοδρόμηση — τερματισμός ακόμη κι αν οι
   κανόνες σχηματίζουν κύκλο που δεν κόβει ο visited έλεγχος.")

(defvar *resolvers* '()
  "Λίστα (PATTERN . FN): FN λαμβάνει (ground-goal context) και επιστρέφει το
   αποκτημένο γεγονός ή NIL. Καταχωρούνται από τους καλούντες (π.χ. ο CLI δίνει
   resolver που διαβάζει το κείμενο της απόφασης) — καμία σύζευξη εδώ.")

(defun register-resolver (pattern fn) (push (cons (copy-tree pattern) fn) *resolvers*))
(defun clear-resolvers () (setf *resolvers* '()))

(defun %ground-p (tuple) (notany #'var-p tuple))
(defun %keep-ground (bindings) (remove-if (lambda (p) (var-p (cdr p))) bindings))

(defun fact->string (x)
  "Αναγνώσιμη μορφή γεγονότος/στόχου για τον ΑΝΘΡΩΠΟ: μεταβλητές ως ?όνομα
   (χωρίς πακέτο), keywords πεζά, φωλιασμένα αναδρομικά. Η ΜΙΑ εκτύπωση
   της αλυσίδας — όχι ωμά package-qualified σύμβολα στον διάλογο."
  (cond ((var-p x) (format nil "?~(~A~)" (subseq (symbol-name x) 1)))
        ((keywordp x) (format nil "~(~S~)" x))
        ((consp x) (format nil "(~{~A~^ ~})" (mapcar #'fact->string x)))
        (t (princ-to-string x))))

(defun %acquire (goal context)
  "Abduction: ζήτα από τους resolvers να ΠΑΡΑΓΟΥΝ το ground GOAL από το CONTEXT
   (τα δεδομένα/κείμενο). Το πρώτο μη-NIL αποτέλεσμα."
  (loop for (pat . fn) in *resolvers*
        for b = (unify pat goal)
        unless (eq b :fail)
          do (let ((r (funcall fn goal context))) (when r (return r)))))

(defun plan-goal (goal facts context &optional (depth 0) (visited '()))
  "Σχέδιο απόδειξης για GOAL. Κόμβος = plist:
     (:goal G :via :fact|:derived|:acquire|:frontier :rule NAME :acquired F :children (…))
   OR στους κανόνες (ο πρώτος που κλείνει), AND στους υπο-στόχους. Αναδρομικό,
   με visited (κύκλοι) + φράγμα βάθους."
  (cond
    ((loop for f in facts thereis (not (eq (unify goal f) :fail)))
     (list :goal goal :via :fact))
    ((>= depth *max-depth*) (list :goal goal :via :frontier))
    ((member goal visited :test #'equal) (list :goal goal :via :frontier))
    (t
     (let* ((v (cons goal visited))
            ;; (β) όλες οι δυνατές παραγωγές — κρατάμε ΚΑΙ τις μερικές, ώστε το
            ;; μέτωπο της άγνοιας να δείχνει το ΑΚΡΙΒΕΣ φύλλο που λείπει βαθιά.
            (expansions
              (loop for rule in (planning-rules)
                    for b0 = (unify (rule-then rule) goal)
                    unless (eq b0 :fail)
                      collect (let* ((b (%keep-ground b0))
                                     (blocked (loop for u in (rule-unless rule)
                                                    for iu = (instantiate u b)
                                                    thereis (and (%ground-p iu)
                                                                 (member iu facts :test #'equal)))))
                                (if blocked
                                    (list :goal goal :via :blocked :rule (rule-name rule))
                                    (let* ((subs (mapcar (lambda (p) (instantiate p b)) (rule-when rule)))
                                           (kids (mapcar (lambda (s) (plan-goal s facts context (1+ depth) v))
                                                         subs)))
                                      (list :goal goal
                                            :via (if (every #'plan-satisfied-p kids) :derived :derived-partial)
                                            :rule (rule-name rule) :children kids))))))
            (win (find :derived expansions :key (lambda (n) (getf n :via))))
            (acq (and (%ground-p goal) (%acquire goal context))))
       (cond
         (win win)                                              ; κανόνας που κλείνει
         (acq (list :goal goal :via :acquire :acquired acq))    ; (γ) απόκτηση από δεδομένα
         ;; (δ) το ΚΑΛΥΤΕΡΟ μερικό (λιγότερα κενά) — για ακριβές μέτωπο άγνοιας
         (t (let ((partials (remove-if-not (lambda (n) (eq (getf n :via) :derived-partial))
                                           expansions)))
              (if partials
                  (first (stable-sort (copy-list partials) #'<
                                      :key (lambda (n) (length (plan-frontier n)))))
                  (list :goal goal :via :frontier)))))))))

(defun plan-satisfied-p (node)
  (member (getf node :via) '(:fact :derived :acquire)))

(defun plan-acquired (node)
  "Όλα τα γεγονότα που το σχέδιο θα ΑΠΟΚΤΗΣΕΙ μόνο του (τα :acquire φύλλα)."
  (let ((acc '()))
    (labels ((walk (n)
               (when (eq (getf n :via) :acquire) (push (getf n :acquired) acc))
               (mapc #'walk (getf n :children))))
      (walk node))
    (remove-duplicates (nreverse acc) :test #'equal)))

(defun plan-frontier (node)
  "Τα αδιάσπαστα κενά — τα φύλλα που ούτε παράγονται ούτε αποκτώνται."
  (let ((acc '()))
    (labels ((walk (n)
               (if (eq (getf n :via) :frontier)
                   (push (getf n :goal) acc)
                   (mapc #'walk (getf n :children)))))
      (walk node))
    (remove-duplicates (nreverse acc) :test #'equal)))

(defun plan->string (node &optional (indent 2))
  (with-output-to-string (s)
    (labels ((walk (n d)
               (format s "~v@T~A ~A~@[  «~A»~]~%"
                       d
                       (case (getf n :via)
                         (:fact "•") (:derived "⇐") (:derived-partial "⇐?")
                         (:acquire "✦") (:blocked "⊘") (t "✗"))
                       (fact->string (getf n :goal))
                       (case (getf n :via)
                         ((:derived :derived-partial) (getf n :rule))
                         (:acquire "το ανακάλυψα από τα δεδομένα")
                         (:blocked (format nil "~A — αναιρείται" (getf n :rule)))
                         (:frontier "ΛΕΙΠΕΙ")
                         (t nil)))
               (dolist (c (getf n :children)) (walk c (+ d 2)))))
      (walk node indent))))

(defun pursue (goal facts context &optional (stream *standard-output*))
  "ΚΥΝΗΓΑ την απάντηση: σχεδίασε απόδειξη ανάποδα, απόκτησε μόνος σου ό,τι λείπει
   από τα δεδομένα, και —αν κλείσει— δώσε την ΠΡΑΓΜΑΤΙΚΗ forward απόδειξη πάνω
   στην διευρυμένη γνώση. Αλλιώς ονομάτισε το μέτωπο της άγνοιας. Επιστρέφει
   (values PROVED-P ACQUIRED FRONTIER)."
  (let* ((plan (plan-goal goal facts context))
         (acquired (plan-acquired plan)))
    (cond
      ((plan-satisfied-p plan)
       (let* ((engine (reason-over (append acquired facts)))
              (hits (ask engine goal)))
         (format stream "~&✓ Το απέδειξα~:[~; — αφού πρώτα κάλυψα μόνος μου τα κενά~].~%" acquired)
         (when acquired
           (format stream "~%  Χρειάστηκε να ΜΑΘΩ (τα ανακάλυψα από τα δεδομένα):~%")
           (dolist (a acquired) (format stream "    ✦ ~A~%" (fact->string a))))
         (format stream "~%  Σχέδιο συλλογισμού:~%~A" (plan->string plan))
         (dolist (h hits) (format stream "~%  Απόδειξη:~%  ~S~%~A~%" (car h) (cdr h)))
         (values t acquired '())))
      (t
       (let ((frontier (plan-frontier plan)))
         (format stream "~&✗ Δεν το αποδεικνύω — αλλά ξέρω ΑΚΡΙΒΩΣ τι θα χρειαζόμουν.~%")
         (format stream "~%  Σχέδιο (πού κόλλησε):~%~A" (plan->string plan))
         (format stream "~%  Το μέτωπο της άγνοιάς μου:~%")
         (dolist (f frontier) (format stream "    ✗ ~A~%" (fact->string f)))
         (values nil acquired frontier))))))

;;; ============================================================================
;;; ΑΛΥΣΙΔΑ ΣΥΛΛΟΓΙΣΜΟΥ — chain of thought, όπως θα το έφτιαχνε ο McCarthy
;;; ============================================================================
;;;
;;; Όχι το «chain of thought» των LLM (πρόζα που παράγεται πιθανοτικά και μπορεί
;;; να είναι εκ των υστέρων δικαιολογία). Εδώ κάθε ΣΚΕΨΗ είναι ΔΕΔΟΜΕΝΟ: ένα
;;; τυποποιημένο βήμα δεμένο σε κανόνα ή γεγονός, που ΕΠΑΛΗΘΕΥΕΤΑΙ. Το σχέδιο
;;; απόδειξης ΕΙΝΑΙ η δομή της σκέψης· εδώ την γραμμικοποιούμε στην σειρά που
;;; σκέφτεται ο συλλογιστής — ερώτημα → τι χρειάζομαι → πώς το παίρνω → πού
;;; κόλλησα → συμπέρασμα. Homoiconic: η αλυσίδα είναι λίστα από βήματα-δεδομένα,
;;; άρα επαναπαίζεται, ελέγχεται, γίνεται audit — δεν «ελπίζεται».

(defun chain-of-thought (plan)
  "Γραμμικοποίησε το σχέδιο απόδειξης σε ΑΛΥΣΙΔΑ ΣΚΕΨΗΣ: ordered λίστα βημάτων,
   καθένα plist (:n :depth :kind :goal …). Τα βήματα είναι ΔΕΔΟΜΕΝΑ."
  (let ((steps '()) (n 0))
    (labels ((emit (kind depth &rest kv)
               (push (list* :n (incf n) :depth depth :kind kind kv) steps))
             (walk (node depth)
               (let ((g (getf node :goal)))
                 (case (getf node :via)
                   (:fact     (emit :known depth :goal g))
                   (:acquire  (emit :acquire depth :goal g :from (getf node :acquired)))
                   (:frontier (emit :missing depth :goal g))
                   (:blocked  (emit :blocked depth :goal g :rule (getf node :rule)))
                   (:derived  (emit :derive depth :goal g :rule (getf node :rule))
                              (dolist (c (getf node :children)) (walk c (1+ depth))))
                   (:derived-partial
                              (emit :attempt depth :goal g :rule (getf node :rule))
                              (dolist (c (getf node :children)) (walk c (1+ depth))))))))
      (emit :question 0 :goal (getf plan :goal))
      (walk plan 1)
      (nreverse steps))))

(defun %thought-phrase (step)
  (let ((g (fact->string (getf step :goal))))
    (ecase (getf step :kind)
      (:question (format nil "Ερώτημα: μπορώ να θεμελιώσω ~A ;" g))
      (:derive   (format nil "Το ~A προκύπτει από τον κανόνα ~(~A~) — αρκεί να ισχύουν:" g (getf step :rule)))
      (:attempt  (format nil "Δοκιμάζω τον κανόνα ~(~A~) για το ~A — θα χρειαζόταν:" (getf step :rule) g))
      (:known    (format nil "✓ ~A — το ξέρω ήδη (γεγονός)." g))
      (:acquire  (format nil "✦ ~A — δεν μου δόθηκε· το βρίσκω στα δεδομένα: ~A." g (fact->string (getf step :from))))
      (:missing  (format nil "✗ ~A — δεν το θεμελιώνω· βαρύνει εσένα να το αποδείξεις." g))
      (:blocked  (format nil "⊘ ο κανόνας ~(~A~) θα το έδινε, αλλά αναιρείται (defeater)." (getf step :rule))))))

(defun explain-chain (chain &optional (stream *standard-output*))
  "Τύπωσε την αλυσίδα σκέψης αριθμημένη, με εσοχή κατά βάθος — κάθε βήμα
   δικαιολογημένο και επαληθεύσιμο."
  (dolist (s chain (values))
    (format stream "~v@T~2D. ~A~%"
            (* 2 (getf s :depth)) (getf s :n) (%thought-phrase s))))

(defun think (goal facts context &optional (stream *standard-output*))
  "Ο πλήρης, ΔΙΑΦΑΝΗΣ συλλογισμός: (1) η αλυσίδα σκέψης βήμα-βήμα, (2) ό,τι
   χρειάστηκε να μάθει μόνο του, (3) το τελικό συμπέρασμα ΜΕ απόδειξη — ή το
   ακριβές μέτωπο της άγνοιας. Επιστρέφει (values PROVED-P CHAIN)."
  (let* ((plan (plan-goal goal facts context))
         (chain (chain-of-thought plan)))
    (format stream "~&═══ ΑΛΥΣΙΔΑ ΣΥΛΛΟΓΙΣΜΟΥ ═══~%")
    (explain-chain chain stream)
    (format stream "~%═══ ΕΤΥΜΗΓΟΡΙΑ ═══~%")
    (pursue goal facts context stream)
    (values (plan-satisfied-p plan) chain)))
