;;;; systems/orchestrator-cli/cognition-legal.lisp
;;;; ============================================================================
;;;; ΓΝΩΣΙΑΚΟ ΠΕΔΙΟ: νομικός διάλογος — άρθρα, νομολογία, αποφάσεις, δικαστές
;;;; ============================================================================
;;;;
;;;; Η ΠΛΗΡΗΣ μετάβαση: κάθε νομική πρόθεση είναι frame πάνω στα 5 στάδια. Η
;;;; παλιά cond του run-ask ΕΦΥΓΕ — εδώ ζει η αποδόμηση (ένας ταξινομητής που
;;;; εξάγει tag/άρθρο/αριθμό-απόφασης + μνήμη διαλόγου) και η σύνθεση (ανά frame,
;;;; ξαναχρησιμοποιώντας τους υπάρχοντες βοηθούς — κανένας διπλός κώδικας).
;;;; Το «άρθρο χωρίς κώδικα» γίνεται ΣΥΝΘΕΤΟ frame: σχέδιο=ένα βήμα ανά κώδικα,
;;;; επαλήθευση=υπάρχει το άρθρο; σύνθεση=απόφαση δι' αποκλεισμού. Ο στοχασμός
;;;; προκύπτει από την ΙΔΙΑ διαδικασία — όχι ξεχωριστός κώδικας.

(in-package :orchestrator.cli)

;;; ── Frames (νομικές προθέσεις) ──
(defclass article-lookup-frame     (orchestrator.cognition:frame) ())
(defclass article-ambiguous-frame  (orchestrator.cognition:frame) ())
(defclass jurisprudence-frame      (orchestrator.cognition:frame) ())
(defclass explain-decision-frame   (orchestrator.cognition:frame) ())
(defclass corpus-info-frame        (orchestrator.cognition:frame) ())
(defclass judge-profile-frame      (orchestrator.cognition:frame) ())
(defclass definition-frame         (orchestrator.cognition:frame) ())
(defparameter +definition-trigger-lemmas+ '("έννοια" "ορισμός" "σημαίνω" "θεωρώ")
  "Τα λήμματα που ΖΗΤΟΥΝ ορισμό — μέρος της σκανδάλης, όχι της έννοιας.")

(defclass concept-search-frame     (orchestrator.cognition:frame) ()
  (:documentation "«τι είναι Χ» για ΜΗ γειωμένη έννοια: αναζήτηση μνειών του Χ
   σε ΟΛΟ το corpus μέσω λημμάτων — απάντηση από τους νόμους, με τίμια δήλωση
   ότι γειωμένος ορισμός δεν υπάρχει (και καταγραφή του κενού)."))
(defclass compare-concepts-frame   (orchestrator.cognition:frame) ())
(defclass objection-frame          (orchestrator.cognition:frame) ())
(defclass clarify-candidates-frame (orchestrator.cognition:frame) ())

;;; ── ΘΕΜΕΛΙΩΣΗ ΕΝΝΟΙΩΝ: έννοια → η ΔΙΑΤΑΞΗ που την ορίζει (με πηγή) ──
;;;
;;; Το άλμα από «ξέρω τι λέει το άρθρο» σε «ξέρω τι σημαίνει η έννοια». Κάθε έννοια
;;; δείχνει στο άρθρο που την ορίζει· η απάντηση βγαίνει ΑΠΟ ΤΟΝ ΝΟΜΟ, όχι από δικά
;;; μου λόγια. ΕΠΑΛΗΘΕΥΜΕΝΗ εκ κατασκευής: ο όρος πρέπει να εμφανίζεται αυτολεξεί στο
;;; κείμενο του άρθρου (αλλιώς δεν απαντιέται — τίμια άγνοια, ποτέ εικασία). Μικρός,
;;; βέβαιος σπόρος· η κλιμάκωση σε όλο το corpus γίνεται από τον επαληθευμένο βρόχο
;;; εξαγωγής, ΟΧΙ με μάντεμα αριθμών.
;;; entry: (concept (εναλλακτικά-σύνολα-λημμάτων…) corpus article)
;;;   Η ταύτιση γίνεται ΣΕ ΛΗΜΜΑΤΑ, όχι σε γράμματα: κάθε σύνολο είναι λήμματα που
;;;   πρέπει ΟΛΑ να υπάρχουν στην ερώτηση (πχ «δημόσιος»+«τάξη»). Ανθεκτικό σε πτώση,
;;;   αριθμό, τόνο, τελικό σίγμα ΕΞ ΟΡΙΣΜΟΥ — γιατί δουλεύει πάνω στην ταυτότητα της
;;;   έννοιας, όχι στη μορφή της.
;;; Η ΣΧΕΣΗ έννοιας↔διάταξης έχει ΤΥΠΟ — επιστημική ακρίβεια, όχι υπερ-ισχυρισμός:
;;;   :defines    η διάταξη ΟΡΙΖΕΙ την έννοια
;;;   :regulates  η διάταξη ΡΥΘΜΙΖΕΙ την αρχή/έννοια (θέτει τον κανόνα της)
;;;   :grounds    η διάταξη την ΚΑΤΟΝΟΜΑΖΕΙ (πχ ως πηγή) — ΔΕΝ την ορίζει, και
;;;               αυτό ΛΕΓΕΤΑΙ ρητά (το ΑΚ 1 δεν ορίζει τον νόμο· τον μνημονεύει).
(defparameter *concept-grounding*
  '(("νόμος"             (("νόμος"))                          :grounds   "astikos" "1")
    ("έθιμο"             (("έθιμο"))                          :grounds   "astikos" "1")
    ("δίκαιο"            (("δίκαιο"))                         :grounds   "astikos" "1")
    ("κανόνας δικαίου"   (("κανόνας"))                        :grounds   "astikos" "1")
    ("πηγές του δικαίου" (("πηγή" "δίκαιο"))                  :defines   "astikos" "1")
    ("αναδρομικότητα"    (("αναδρομικότητα") ("αναδρομικός")) :regulates "astikos" "2")
    ("δημόσια τάξη"      (("δημόσιος" "τάξη"))                :grounds   "astikos" "3"))
  "έννοια · εναλλακτικά σύνολα-λημμάτων · τύπος-σχέσης · corpus · άρθρο.")

;;; Φάση 4: η γείωση εννοιών είναι ΓΝΩΣΗ — επεκτείνεται με πακέτο, όχι με
;;; επαναμεταγλώττιση. Entry: (:concept ΟΝΟΜΑ ΕΝΑΛΛΑΚΤΙΚΕΣ ΣΧΕΣΗ CORPUS ΑΡΘΡΟ)
;;; όπου ΕΝΑΛΛΑΚΤΙΚΕΣ = λίστα συνόλων λημμάτων και ΣΧΕΣΗ ∈ :defines/:regulates/
;;; :grounds — ίδια επαλήθευση στην πηγή (in-article κατά λήμματα) με τις
;;; ενσωματωμένες. Ίδιο όνομα ⇒ αντικατάσταση (η νεότερη γνώση νικά, ρητά).
(orchestrator.knowledge-packs:define-knowledge-kind :concept-grounding
 :doc "Γείωση εννοιών: (:concept ΟΝΟΜΑ ((λήμμα…)…) :defines|:regulates|:grounds CORPUS ΑΡΘΡΟ)."
 :install
 (lambda (entries)
   (dolist (e entries)
     (destructuring-bind (k name alts relation corpus article) e
       (declare (ignore k))
       (assert (member relation '(:defines :regulates :grounds)) ()
               "άγνωστη σχέση γείωσης ~S για «~A»" relation name)
       (setf *concept-grounding*
             (cons (list name alts relation corpus article)
                   (remove name *concept-grounding* :key #'first :test #'string=))))))
 :snapshot (lambda () (copy-tree *concept-grounding*))
 :restore  (lambda (st) (setf *concept-grounding* st)))

;; Το λεξιλόγιο λημμάτων ζει ΚΕΝΤΡΙΚΑ στην έδρα της γλωσσικής γνώσης
;; (greek-lemmatizer.lisp) — εδώ μόνο ΧΡΗΣΙΜΟΠΟΙΕΙΤΑΙ. Καμία τοπική λίστα.

(defun %q-lemmas (text)
  "Η ΣΕΙΡΑ λημμάτων ενός κειμένου (πρώτη-εμφάνιση): tokenize → known-lemma.
   ΜΟΝΟ το επιμελημένο λεξιλόγιο (κανονικοποιημένο: τόνοι/πεζά/τελικό σίγμα
   αδιάφορα) — οι μορφολογικοί κανόνες είναι lossy και ΔΕΝ είναι έμπιστη γνώση.
   Άγνωστες λέξεις απαλείφονται: δεν μαντεύονται. Ταυτότητα έννοιας, όχι γράμματα."
  (handler-bind ((warning #'muffle-warning))
    (remove-duplicates
     (remove nil
             (mapcar #'orchestrator.citation-authority:known-lemma
                     (orchestrator.citation-authority:tokenize-greek text)))
     :test #'string= :from-end t)))

(defun %concept-alts (concept)
  (second (assoc concept *concept-grounding* :test #'string=)))

(defun %live-provision-facts (corpus article)
  "Πρόταση ΣΥΝΤΙΘΕΜΕΝΗ από τα ζωντανά γεγονότα του γράφου για μια διάταξη —
   μετρημένα ΤΩΡΑ, με ρηματική και αριθμητική συμφωνία από τη γραμματική.
   NIL όταν ο γράφος δεν είναι χτισμένος (τίμια: δεν επινοώ αριθμούς)."
  (when (plusp (orchestrator.graph:node-count))
    (let* ((id (format nil "art:~A:~A" corpus article))
           (cites (length (orchestrator.graph:predecessors id :cites)))
           (applies (length (orchestrator.graph:predecessors id :applies)))
           (clauses (remove nil
                     (list (when (plusp cites)
                             (format nil "~A ~A"
                                     (orchestrator.generation:vp "παραπέμπω"
                                                                 (if (= cites 1) :sg :pl))
                                     (orchestrator.generation:count-np cites "άρθρο")))
                           (when (plusp applies)
                             (format nil "~A ~A"
                                     (orchestrator.generation:vp "εφαρμόζω"
                                                                 (if (= applies 1) :sg :pl))
                                     (orchestrator.generation:count-np applies "απόφαση")))))))
      (when clauses
        (orchestrator.generation:sentence
         "στον γράφο μου, σε αυτή τη διάταξη"
         (orchestrator.generation:enumerate-clauses clauses))))))

(defun %resolve-concepts-all (question)
  "ΟΛΕΣ οι θεμελιωμένες έννοιες που εμφανίζονται στην ερώτηση (για σύγκριση)."
  (let ((ql (%q-lemmas question)))
    (remove-if-not
     (lambda (entry)
       (some (lambda (alt) (every (lambda (l) (member l ql :test #'string=)) alt))
             (second entry)))
     *concept-grounding*)))

(defun %resolve-concept (question)
  "Η θεμελιωμένη έννοια που ζητά η ερώτηση, μέσω ΛΗΜΜΑΤΩΝ. Προτιμά το ΘΕΜΑ: την έννοια
   που εμφανίζεται ΝΩΡΙΤΕΡΑ (ώστε «αναδρομικότητα του νόμου» → αναδρομικότητα, όχι
   νόμος)· ισοπαλία → η ειδικότερη (περισσότερα λήμματα). Επιστρέφει (concept alts
   corpus article) ή nil."
  (let ((ql (%q-lemmas question)) (best nil)
        (best-pos most-positive-fixnum) (best-spec 0))
    (dolist (entry *concept-grounding* best)
      (dolist (alt (second entry))
        (when (every (lambda (l) (member l ql :test #'string=)) alt)
          (let ((pos (reduce #'min (mapcar (lambda (l) (position l ql :test #'string=)) alt))))
            (when (or (< pos best-pos) (and (= pos best-pos) (> (length alt) best-spec)))
              (setf best entry best-pos pos best-spec (length alt)))))))))

;;; ── ΣΤΑΔΙΟ 1 (πεδίο): αποδόμηση νομικής ερώτησης + μνήμη διαλόγου ──
(orchestrator.cognition:register-classifier "legal"
 (lambda (input)
   (let* ((q input)
          (folded (orchestrator.decisions:%fold q))
          (tag (%ask-find-tag folded))
          (artg (nth-value 1 (cl-ppcre:scan-to-strings
                              ;; γράμμα άρθρου (πχ 105β) ΜΟΝΟ αν δεν συνεχίζει λέξη
                              (orchestrator.decisions:%fold "άρθρου?\\s+(\\d+)\\s*((?:[α-ω](?![α-ω]))?)")
                              folded)))
          (article (and artg (concatenate 'string (aref artg 0)
                                          (string-upcase (aref artg 1)))))
          (decg (nth-value 1 (cl-ppcre:scan-to-strings "(\\d+)\\s*/\\s*(\\d{4})" folded))))
     ;; «άρθρο 1 Σ»: αν το «γράμμα άρθρου» είναι ΤΑΥΤΟΤΗΤΑ κώδικα στο μητρώο
     ;; (Σ = Σύνταγμα) και δεν βρέθηκε άλλος κώδικας, είναι Ο ΚΩΔΙΚΑΣ — δομική
     ;; αποσαφήνιση από το ίδιο το μητρώο tags, όχι μάντεμα.
     (when (and article (null tag) (> (length article) 1))
       (let ((hit (find (subseq article (1- (length article)))
                        orchestrator.decisions:+law-tag-corpus-map+
                        :key #'car :test #'string-equal)))
         (when hit
           (setf tag (car hit)
                 article (subseq article 0 (1- (length article)))))))
     ;; μνήμη διαλόγου (α): εκκρεμούσε «ποιου κώδικα;» και κατονομάζεται κώδικας
     (when (and (eq (%dialogue :awaiting) :which-code)
                (not article) (%dialogue :article))
       (let ((answered (%ask-code-answer folded)))
         (when answered
           (setf tag answered article (%dialogue :article)
                 (%dialogue :awaiting) nil))))
     ;; μνήμη διαλόγου (β): σκέτος αριθμός ενώ μιλούσαμε ήδη για κώδικα → άρθρο του
     (when (and (not article) (%dialogue :tag)
                (cl-ppcre:scan "^\\s*(\\d+)\\s*((?:[α-ω](?![α-ω]))?)\\s*;?\\s*$" folded))
       (multiple-value-bind (m g) (cl-ppcre:scan-to-strings "(\\d+)\\s*([α-ω]?)" folded)
         (declare (ignore m))
         (setf article (concatenate 'string (aref g 0) (string-upcase (aref g 1)))
               tag (or tag (%dialogue :tag)))))
     (let ((corpus (and tag (cdr (assoc tag orchestrator.decisions:+law-tag-corpus-map+
                                        :test #'string=)))))
       (cond
         ;; ΕΝΣΤΑΣΗ (πράξη λόγου, από κλειστές γραμματικές κλάσεις — όχι λίστες
         ;; λέξεων): δεν αρπάζουμε το «άρθρο 1» μέσα από μια αντίρρηση.
         ((eq (orchestrator.citation-authority:utterance-act q) :objection)
          (make-instance 'objection-frame :input input
            :slots (list :tag (%dialogue :tag) :article (%dialogue :article))))
         ;; ΑΝΑΦΟΡΑ ΣΤΗ ΔΙΚΗ ΜΟΥ ΕΚΦΟΡΑ (ρήμα λεκτικό — verba dicendi) ενώ
         ;; εκκρεμεί «ποιου κώδικα;»: «αυτόν που ανέφερες» δεν αρκεί όταν
         ;; ανέφερα ΠΟΛΛΟΥΣ — τίμια επαν-αποσαφήνιση με τους υποψηφίους.
         ((and (eq (%dialogue :awaiting) :which-code)
               (orchestrator.citation-authority:verbum-dicendi-p q))
          (make-instance 'clarify-candidates-frame :input input
            :slots (list :candidates (%dialogue :candidates) :article (%dialogue :article))))
         ;; «εξήγησέ μου / τι λέει η απόφαση N/ΕΤΟΣ»
         ((and decg (cl-ppcre:scan (orchestrator.decisions:%fold "εξήγησ|ανάλυσε|τι\\s+λέει\\s+η\\s+απόφαση|απόφαση") folded))
          (make-instance 'explain-decision-frame :input input
            :slots (list :court (if (cl-ppcre:scan (orchestrator.decisions:%fold "εφετεί") folded)
                                    "efeteio-peiraios" "areios-pagos")
                         :num (aref decg 0) :year (aref decg 1))))
         ;; «νομολογία / αποφάσεις για το άρθρο Ν του Χ»
         ((and article corpus (cl-ppcre:scan (orchestrator.decisions:%fold "νομολογ|αποφάσ") folded))
          (make-instance 'jurisprudence-frame :input input
            :slots (list :corpus corpus :article article :tag tag)))
         ;; «τι λέει το άρθρο Ν του Χ»
         ((and article corpus)
          (make-instance 'article-lookup-frame :input input
            :slots (list :corpus corpus :article article :tag tag)))
         ;; «άρθρο Ν» χωρίς κώδικα → ΣΥΝΘΕΤΟ (στοχασμός δι' αποκλεισμού)
         (article
          (make-instance 'article-ambiguous-frame :input input :slots (list :article article)))
         ;; «τι είναι ο Χ κώδικας»
         ((and tag (cl-ppcre:scan (orchestrator.decisions:%fold "τι\\s+είναι|τι\\s+ειναι|περι[εέ]χει|π[οό]σα\\s+[αά]ρθρα") folded))
          (make-instance 'corpus-info-frame :input input :slots (list :tag tag :corpus corpus)))
         ;; «διαφορά/διάκριση Χ από Ψ» με ≥2 θεμελιωμένες έννοιες → ΣΥΓΚΡΙΣΗ:
         ;; σκανδάλη ΣΕ ΛΗΜΜΑΤΑ (ίδιο υπόστρωμα με τις έννοιες), όχι σε regex.
         ((and (intersection (%q-lemmas q) '("διαφορά" "διαφέρω" "διάκριση") :test #'string=)
               (>= (length (%resolve-concepts-all q)) 2))
          (make-instance 'compare-concepts-frame :input input
            :slots (list :entries (%resolve-concepts-all q))))
         ;; «τι είναι / τι σημαίνει / ορισμός / έννοια <θεμελιωμένη έννοια>»
         ;; ΜΟΝΟ αν η έννοια είναι θεμελιωμένη σε διάταξη — αλλιώς πέφτει σε τίμια άγνοια.
         ((and (cl-ppcre:scan (orchestrator.decisions:%fold "τι\\s+είν|σημαίν|ορισμ|έννοια|τι\\s+θεωρ") folded)
               (%resolve-concept q))
          (destructuring-bind (concept alts relation corpus article) (%resolve-concept q)
            (declare (ignore alts))
            (make-instance 'definition-frame :input input
              :slots (list :concept concept :relation relation
                           :corpus corpus :article article))))
         ;; «τι είναι / τι σημαίνει Χ» ΧΩΡΙΣ γείωση: αν η ερώτηση έχει γνωστά
         ;; ΛΗΜΜΑΤΑ περιεχομένου, ψάξε τις μνείες τους σε ΟΛΟ το corpus — η
         ;; απάντηση βγαίνει από τους νόμους, όχι από άγνοια. (Δομικός μηχανισμός:
         ;; λήμματα → μορφές → άρθρα· καμία λίστα εννοιών κατά περίπτωση.)
         ((and (cl-ppcre:scan (orchestrator.decisions:%fold "τι\\s+είν|σημαίν|ορισμ|έννοια|τι\\s+θεωρ") folded)
               (let ((content (remove-if-not
                               ;; λέξεις ΠΕΡΙΕΧΟΜΕΝΟΥ μόνο — οι λειτουργικές
                               ;; (άρθρα/μόρια/προθέσεις) είναι κλειστή κλάση
                               ;; της γλώσσας, δηλωμένη στην έδρα της
                               #'orchestrator.citation-authority:content-lemma-p
                               (set-difference (%q-lemmas q) +definition-trigger-lemmas+
                                               :test #'string=))))
                 (when content
                   ;; η επιφάνεια της έννοιας: οι λέξεις της ερώτησης που έδωσαν τα λήμματα
                   (let ((surface (remove-if-not
                                   (lambda (w)
                                     (member (orchestrator.citation-authority:known-lemma w)
                                             content :test #'string=))
                                   (orchestrator.citation-authority:tokenize-greek q))))
                     (make-instance 'concept-search-frame :input input
                       :slots (list :lemmas content
                                    :label (if surface (format nil "~{~A~^ ~}" surface)
                                               (format nil "~{~A~^ ~}" content)))))))))
         ;; «προφίλ του δικαστή Χ»
         ((cl-ppcre:scan (orchestrator.decisions:%fold "δικαστ|εισηγητ|προφίλ") folded)
          (make-instance 'judge-profile-frame :input input
            :slots (list :name (find-if (lambda (w)
                                          (and (> (length w) 3) (upper-case-p (char w 0))
                                               (not (cl-ppcre:scan (orchestrator.decisions:%fold "^(?:ποιο|ποια|δικαστ|εισηγητ|προφίλ)")
                                                                   (orchestrator.decisions:%fold w)))))
                                        (reverse (cl-ppcre:split "[\\s;,.·?]+" q))))))
         (t nil))))))

;;; ── concept-search: ένα βήμα ανά κώδικα — μνείες της έννοιας στα κείμενα ──
(defmethod orchestrator.cognition:plan ((f concept-search-frame) cog)
  (declare (ignore cog))
  (let ((seen '()) (tags '()))
    (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
      (unless (member (cdr entry) seen :test #'string=)
        (push (cdr entry) seen) (push (car entry) tags)))
    (nreverse tags)))

(defmethod orchestrator.cognition:execute-step (step (f concept-search-frame) cog)
  (declare (ignore cog))
  (let ((corpus (cdr (assoc step orchestrator.decisions:+law-tag-corpus-map+ :test #'string=))))
    (multiple-value-bind (hits total)
        (%corpus-mentions corpus (orchestrator.cognition:frame-slot f :lemmas) :limit 3)
      (if hits (values t (list step corpus hits total)) (values nil step)))))

(defmethod orchestrator.cognition:synthesize ((f concept-search-frame) cog)
  (let* ((label (orchestrator.cognition:frame-slot f :label))
         (evidence (remove nil (orchestrator.cognition:cog-evidence cog)))
         (total (reduce #'+ evidence :key #'fourth :initial-value 0)))
    (cond
      ((null evidence)
       ;; ΟΥΤΕ μνεία στα κείμενα — τίμια άγνοια + καταγραφή του κενού
       (%lesson :concept-ungrounded label "καμία μνεία στο corpus")
       (format nil "Για «~A» δεν έχω ούτε γειωμένο ορισμό ούτε μνεία στα κείμενα που γνωρίζω — ~
τίμια, χωρίς μάντεμα. Καταγράφηκε ως κενό γνώσης." label))
      (t
       ;; μνείες ΥΠΑΡΧΟΥΝ: δείξε τες, με τίμια επιστημική ετικέτα
       (%lesson :concept-ungrounded label (format nil "~D μνείες — θέλει γείωση" total))
       (with-output-to-string (s)
         (format s "Δεν έχω γειωμένο ορισμό για «~A» — κανένα άρθρο απ' όσα γνωρίζω δεν μου έχει δηλωθεί ως ορισμός του.~%~
Στα κείμενα όμως το μνημονεύουν ~D άρθρα:~%" label total)
         (dolist (ev evidence)
           (destructuring-bind (tag corpus hits ctotal) ev
             (declare (ignore corpus))
             (format s "~%  ~A (~D):~%" tag ctotal)
             (dolist (h hits)
               (destructuring-bind (num heading in-heading) h
                 (format s "   • άρθρο ~A~@[ — ~A~]~@[  ← στον τίτλο του~]~%"
                         num heading in-heading)))))
         (format s "~%(πλήρες κείμενο: «τι λέει το άρθρο <Ν> <κώδικας>» · ~
για να αποκτήσω ορισμό, ο δημιουργός γειώνει την έννοια σε διάταξη — πακέτο :concept-grounding)"))))))

;;; ── ΣΤΑΔΙΟ 0: το ασαφές άρθρο είναι ΣΥΝΘΕΤΟ (ορατός στοχασμός) ──
(defmethod orchestrator.cognition:triage ((f article-ambiguous-frame)) :complex)

;;; ── ΣΤΑΔΙΑ 2/3 (ασαφές άρθρο): ένα βήμα ανά κώδικα, επαλήθευση ύπαρξης ──
(defmethod orchestrator.cognition:plan ((f article-ambiguous-frame) cog)
  (declare (ignore cog))
  (let ((seen '()) (tags '()))
    (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
      (unless (member (cdr entry) seen :test #'string=)
        (push (cdr entry) seen) (push (car entry) tags)))
    (nreverse tags)))

(defmethod orchestrator.cognition:execute-step (step (f article-ambiguous-frame) cog)
  (declare (ignore cog))
  (let* ((article (orchestrator.cognition:frame-slot f :article))
         (corpus (cdr (assoc step orchestrator.decisions:+law-tag-corpus-map+ :test #'string=)))
         (text (and corpus (%ask-article-text corpus article))))
    (if text (values t (cons step corpus)) (values nil step))))

;;; ── ΣΤΑΔΙΟ 5: σύνθεση ανά νομικό frame (ξαναχρήση βοηθών) ──

(defmethod orchestrator.cognition:synthesize ((f article-ambiguous-frame) cog)
  (let ((article (orchestrator.cognition:frame-slot f :article))
        (hits (orchestrator.cognition:cog-evidence cog)))
    (cond
      ((null hits)
       (%lesson :question-not-understood (format nil "άρθρο ~A χωρίς κώδικα" article)
                "άρθρο ανύπαρκτο σε όλους τους κώδικες")
       (format nil "Δεν υπάρχει άρθρο ~A σε κανέναν από τους κώδικες που γνωρίζω." article))
      ((= 1 (length hits))
       (destructuring-bind (tag . corpus) (first hits)
         (setf (%dialogue :tag) tag (%dialogue :article) article
               (%dialogue :awaiting) nil)
         (multiple-value-bind (text heading path) (%ask-article-text corpus article)
           (format nil "(μόνο ο ~A έχει άρθρο ~A — γι' αυτό απαντώ αυτό, χωρίς να ρωτήσω)~%~%— ~A —~%~%~A~%~%(πηγή: ~A · νομολογία: --ask \"νομολογία για το άρθρο ~A ~A\")"
                   tag article (or heading (format nil "~A άρθρο ~A" tag article)) text
                   (enough-namestring path (orchestrator.paths:institution-root)) article tag))))
      (t
       (setf (%dialogue :article) article (%dialogue :awaiting) :which-code
             ;; θυμάμαι ΤΙ πρότεινα — για το «αυτόν που ανέφερες» της επόμενης στροφής
             (%dialogue :candidates) (mapcar #'car hits))
       (format nil "Το άρθρο ~A υπάρχει σε: ~{~A~^, ~}. Ποιον από αυτούς εννοείς;"
               article (mapcar #'car hits))))))

(defmethod orchestrator.cognition:synthesize ((f article-lookup-frame) cog)
  (declare (ignore cog))
  (let* ((s (orchestrator.cognition:frame-slots f))
         (corpus (getf s :corpus)) (article (getf s :article)) (tag (getf s :tag)))
    (setf (%dialogue :tag) tag (%dialogue :article) article
          (%dialogue :awaiting) nil)
    (multiple-value-bind (text heading path) (%ask-article-text corpus article)
      (if text
          (format nil "— ~A —~%~%~A~%~%(πηγή: ~A · νομολογία: --ask \"νομολογία για το άρθρο ~A ~A\")"
                  (or heading (format nil "~A άρθρο ~A" tag article)) text
                  (enough-namestring path (orchestrator.paths:institution-root)) article tag)
          (format nil "Δεν βρέθηκε άρθρο ~A στον ~A — έλεγξε τον αριθμό." article tag)))))

(defmethod orchestrator.cognition:synthesize ((f jurisprudence-frame) cog)
  (declare (ignore cog))
  (let ((s (orchestrator.cognition:frame-slots f)))
    (string-right-trim '(#\Newline)
      (with-output-to-string (*standard-output*)
        (%ask-decisions-for (getf s :corpus) (getf s :article) (getf s :tag))))))

(defmethod orchestrator.cognition:synthesize ((f explain-decision-frame) cog)
  (declare (ignore cog))
  (let ((s (orchestrator.cognition:frame-slots f)))
    (string-right-trim '(#\Newline)
      (with-output-to-string (*standard-output*)
        (run-explain-decision (list (getf s :court) (getf s :num) (getf s :year)))))))

(defmethod orchestrator.cognition:synthesize ((f corpus-info-frame) cog)
  (declare (ignore cog))
  (let* ((s (orchestrator.cognition:frame-slots f)) (tag (getf s :tag)) (corpus (getf s :corpus)))
    (setf (%dialogue :tag) tag)
    (let ((n (%ask-corpus-article-count corpus)))
      (if n
          (format nil "~A (~A): ~D άρθρα, πλήρες επαληθευμένο κείμενο στο σύστημα.~%~
Ρώτα «τι λέει το άρθρο <Ν> ~A» ή «νομολογία για το άρθρο <Ν> ~A»."
                  (or (cdr (assoc tag +tag-full-names+ :test #'string=)) tag) tag n tag tag)
          (format nil "Τον ~A τον γνωρίζω ως όνομα, αλλά δεν έχει materialized corpus ακόμη." tag)))))

(defmethod orchestrator.cognition:synthesize ((f definition-frame) cog)
  (declare (ignore cog))
  (let* ((s (orchestrator.cognition:frame-slots f))
         (concept (getf s :concept))
         (corpus (getf s :corpus)) (article (getf s :article))
         (tag (car (rassoc corpus orchestrator.decisions:+law-tag-corpus-map+ :test #'string=))))
    (multiple-value-bind (text heading path) (%ask-article-text corpus article)
      (cond
        ;; ΕΠΑΛΗΘΕΥΣΗ εκ κατασκευής, ΣΕ ΛΗΜΜΑΤΑ: κάποιο σύνολο-λημμάτων της έννοιας
        ;; πρέπει να υπάρχει στα λήμματα του άρθρου (τίτλος+κείμενο)· αλλιώς ΔΕΝ απαντώ.
        ((and text
              (let ((alemmas (%q-lemmas (format nil "~@[~A ~]~A" heading text))))
                (some (lambda (alt) (every (lambda (l) (member l alemmas :test #'string=)) alt))
                      (%concept-alts concept))))
         (setf (%dialogue :tag) tag (%dialogue :article) article
               (%dialogue :awaiting) nil)
         ;; ΣΥΝΘΕΣΗ, όχι ανάσυρση: η πρόταση ΠΡΑΓΜΑΤΩΝΕΤΑΙ από τη σχέση (ορίζει/
         ;; ρυθμίζει/κατονομάζει), με κλίση+συμφωνία από τη γραμματική, και τα
         ;; ζωντανά γεγονότα του γράφου (ποιοι παραπέμπουν/εφάρμοσαν) μπαίνουν
         ;; ΜΕΤΡΗΜΕΝΑ τη στιγμή της ερώτησης. Το ΑΚ 1 δεν «ορίζει» τον νόμο —
         ;; τον κατονομάζει· καμία υπερβολή, καμία έτοιμη φράση.
         (let* ((relation (getf s :relation))
                (verb (ecase relation
                        (:defines "ορίζω") (:regulates "ρυθμίζω") (:grounds "κατονομάζω")))
                (in-lex (orchestrator.generation:noun-gender concept))
                (obj (if in-lex
                         (orchestrator.generation:np concept :case :acc)
                         (format nil "την έννοια «~A»" concept)))
                (pron (ecase (or in-lex :f)
                        (:m "τον") (:f "την") (:n "το")))
                (opener (orchestrator.generation:sentence
                         (format nil "το άρθρο ~A ~A~@[ («~A»)~]" article tag heading)
                         (orchestrator.generation:vp verb :sg) obj
                         (when (eq relation :grounds)
                           (format nil "— ~A μνημονεύει, δεν ~A ορίζει" pron pron))))
                (live (%live-provision-facts corpus article)))
           (format nil "~A~%~%~A~@[~%~%~A~]~%~%(πηγή: ~A)"
                   opener text live (enough-namestring path (orchestrator.paths:institution-root)))))
        (t
         (%lesson :question-not-understood (format nil "ορισμός «~A»" concept)
                  "έννοια θεμελιωμένη σε άρθρο που δεν επαληθεύεται στο κείμενο")
         (format nil "Την έννοια «~A» δεν μπορώ να την τεκμηριώσω στο κείμενο — δεν μαντεύω." concept))))))

(defmethod orchestrator.cognition:synthesize ((f compare-concepts-frame) cog)
  (declare (ignore cog))
  (let ((entries (orchestrator.cognition:frame-slot f :entries)))
    (with-output-to-string (out)
      (format out "Στη γνώση μου, θεμελιωμένα στο σώμα των νόμων:~%")
      (dolist (e entries)
        (destructuring-bind (concept alts relation corpus article) e
          (declare (ignore alts))
          (let ((tag (car (rassoc corpus orchestrator.decisions:+law-tag-corpus-map+
                                  :test #'string=))))
            (format out "~%  • «~A» — ~A στο ~A άρθρο ~A"
                    concept
                    (ecase relation
                      (:defines "ορίζεται") (:regulates "ρυθμίζεται")
                      (:grounds "κατονομάζεται (χωρίς ορισμό)"))
                    tag article))))
      ;; παράθεσε το κείμενο ΜΙΑ φορά ανά διακριτή διάταξη
      (let ((seen '()))
        (dolist (e entries)
          (destructuring-bind (concept alts relation corpus article) e
            (declare (ignore concept alts relation))
            (let ((key (format nil "~A:~A" corpus article)))
              (unless (member key seen :test #'string=)
                (push key seen)
                (multiple-value-bind (text heading) (%ask-article-text corpus article)
                  (when text
                    (format out "~%~%— ~A —~%~A" (or heading key) text))))))))
      (format out "~%~%Τη ΘΕΩΡΗΤΙΚΗ διάκριση μεταξύ τους δεν την έχω θεμελιωμένη ~
σε διάταξη — δεν θα την επινοήσω."))))

(defmethod orchestrator.cognition:synthesize ((f objection-frame) cog)
  (declare (ignore cog))
  (let* ((s (orchestrator.cognition:frame-slots f))
         (tag (getf s :tag)) (article (getf s :article)))
    (%lesson :user-objection (orchestrator.cognition:frame-input f)
             "ένσταση του δημιουργού — προς αναστοχασμό")
    (format nil "Δεκτή η παρατήρηση — καταγράφηκε για τον αναστοχασμό μου.~
~@[~%Για το ~A~@[ άρθρο ~A~] παρέθεσα το κείμενο ΟΠΩΣ ζει στο σώμα μου, με την πηγή του — ~
δεν πρόσθεσα δική μου ερμηνεία.~]~%~
Αν κάτι είναι λάθος ή ελλιπές, πες μου ΣΥΓΚΕΚΡΙΜΕΝΑ τι να ελέγξω — ~
διορθώνομαι με απόδειξη, όχι με εντύπωση." tag article)))

(defmethod orchestrator.cognition:synthesize ((f clarify-candidates-frame) cog)
  (declare (ignore cog))
  (let ((cands (orchestrator.cognition:frame-slot f :candidates))
        (article (orchestrator.cognition:frame-slot f :article)))
    (if cands
        (format nil "Ανέφερα ~D κώδικες~@[ για το άρθρο ~A~]: ~{~A~^, ~}. ~
«Αυτόν που ανέφερα» δεν αρκεί — ποιον από αυτούς εννοείς; (ένα όνομα αρκεί, πχ «του αστικού»)"
                (length cands) article cands)
        "Ποιον κώδικα εννοείς; (πχ «του ποινικού», «του αστικού»)")))

(defmethod orchestrator.cognition:synthesize ((f judge-profile-frame) cog)
  (declare (ignore cog))
  (let ((name (orchestrator.cognition:frame-slot f :name)))
    (if name
        (string-right-trim '(#\Newline)
          (with-output-to-string (*standard-output*) (run-judge-profile (list name))))
        "Ποιου δικαστή το προφίλ; Δώσε επώνυμο.")))

;;; ── Σ4β στον ΔΙΑΛΟΓΟ: αφήγηση περιστατικών ⇒ ζωντανή ΥΠΑΓΩΓΗ ──
;;; Ο ταξινομητής καταχωρείται ΜΕΤΑ τον «legal» (τρέχει μόνο όταν εκείνος
;;; δεν πιάσει): αν η γραμματική πτώσεων αναγνωρίσει έστω μία πράξη στην
;;; είσοδο, η απάντηση είναι η πλήρης υπαγωγή — γεγονότα, θέσεις με
;;; αποδείξεις, ρητά κενά. Καμία εικασία: χωρίς αναγνωρισμένη πράξη, nil.

(defclass narrative-subsumption-frame (orchestrator.cognition:frame) ()
  (:documentation "Αφήγηση πραγματικών περιστατικών προς υπαγωγή (Σ4β)."))

(orchestrator.cognition:register-classifier "narrative-subsumption"
 (lambda (input)
   (multiple-value-bind (facts) (orchestrator.casegrammar:parse-narrative input)
     (when facts
       (make-instance 'narrative-subsumption-frame :input input
         :slots (list :text input))))))

(defmethod orchestrator.cognition:synthesize ((f narrative-subsumption-frame) cog)
  (declare (ignore cog))
  (string-right-trim '(#\Newline)
    (with-output-to-string (*standard-output*)
      ;; πλήρης ΦΑΚΕΛΟΣ: η αφήγηση περνά σε ΟΛΟΥΣ τους ειδικούς (αρένα)
      (multiple-value-bind (facts unparsed)
          (orchestrator.casegrammar:parse-narrative
           (orchestrator.cognition:frame-slot f :text))
        (format t "~%── ΑΝΑΓΝΩΣΗ ΑΦΗΓΗΣΗΣ: ~D γεγονότα ──~%" (length facts))
        (dolist (fa facts) (format t "  • ~A~%" (orchestrator.knowledge:fact->string fa)))
        (dolist (u unparsed)
          (format t "  ⚠ ΔΕΝ αναγνωρίστηκε (καμία εικασία): «~A»~%" u))
        (when facts (case-workspace facts))))))

;;; ── ΑΛΥΣΙΔΑ ΣΥΛΛΟΓΙΣΜΟΥ στον ΔΙΑΛΟΓΟ: «τι χρειάζεται για να στοιχειοθετηθεί Χ;» ──
;;; Ο κοιμισμένος σχεδιαστής απόδειξης (orchestrator.knowledge: plan-goal/think)
;;; ξυπνά εδώ: το ερώτημα «τι προϋποθέτει/πώς αποδεικνύεται/τι χρειάζεται για
;;; την πράξη Χ» απαντιέται με την ΑΛΥΣΙΔΑ ΣΥΛΛΟΓΙΣΜΟΥ πάνω στο tatbestand —
;;; αριθμημένα βήματα-δεδομένα, με το ακριβές μέτωπο του τι πρέπει να αποδειχθεί.
;;; Σκανδάλη σε ΛΗΜΜΑΤΑ (κλειστό λεξιλόγιο), όχι σε regex ανά περίπτωση.

(defparameter +proof-quest-lemmas+
  '("στοιχειοθετώ" "προϋπόθεση" "χρειάζομαι" "αποδεικνύω")
  "Τα λήμματα-σκανδάλες του ερωτήματος θεμελίωσης.")

(defclass proof-quest-frame (orchestrator.cognition:frame) ()
  (:documentation "«Τι χρειάζεται για να στοιχειοθετηθεί <πράξη>;» — σχεδιασμός
   απόδειξης ανάποδα πάνω στους κανόνες ειδικής υπόστασης."))

(defun %norm-for-act-word (question)
  "Ο κανόνας του tatbestand του οποίου η ΠΡΑΞΗ (τρίτο στοιχείο του consequent)
   αναφέρεται στο ερώτημα — σύγκριση σε κανονικοποιημένα λήμματα/μορφές."
  (let ((toks (orchestrator.citation-authority:tokenize-greek question)))
    (loop for nm in (orchestrator.subsumption:case-norms)
          for act = (let ((c (orchestrator.deontic:norm-consequent nm)))
                      (and (consp c) (third c)))
          when (and (keywordp act)
                    (let ((an (orchestrator.citation-authority:normalize-greek
                               (symbol-name act))))
                      (loop for tk in toks
                            thereis (or (string= an (orchestrator.citation-authority:normalize-greek tk))
                                        (let ((l (orchestrator.citation-authority:known-lemma tk)))
                                          (and l (string= an (orchestrator.citation-authority:normalize-greek l))))))))
            return (list nm act))))

(orchestrator.cognition:register-classifier "proof-quest"
 (lambda (input)
   (when (intersection (%q-lemmas input) +proof-quest-lemmas+ :test #'string=)
     (let ((hit (%norm-for-act-word input)))
       (when hit
         (make-instance 'proof-quest-frame :input input
           :slots (list :norm-id (orchestrator.deontic:norm-id (first hit))
                        :act (second hit))))))))

(defmethod orchestrator.cognition:synthesize ((f proof-quest-frame) cog)
  (declare (ignore cog))
  (let* ((id (orchestrator.cognition:frame-slot f :norm-id))
         (nm (orchestrator.deontic:find-norm id)))
    (string-right-trim '(#\Newline)
      (with-output-to-string (*standard-output*)
        (format t "Για να στοιχειοθετηθεί ~(~A~) — κανόνας ~A (άρθρο ~A ~A):~%"
                (orchestrator.cognition:frame-slot f :act) id
                (orchestrator.deontic:norm-article nm)
                (orchestrator.deontic:norm-corpus nm))
        ;; ο σχεδιαστής βλέπει το tatbestand ως κανόνες σχεδιασμού· χωρίς
        ;; γεγονότα υπόθεσης, το «μέτωπο» ΕΙΝΑΙ η λίστα του τι πρέπει να αποδειχθεί
        (let ((orchestrator.knowledge:*extra-rules*
                (orchestrator.subsumption:norm-planning-rules (list nm))))
          (orchestrator.knowledge:think
           (orchestrator.inference:rule-then
            (first orchestrator.knowledge:*extra-rules*))
           '() nil))))))

;;; ── Η ΣΚΕΨΗ ΩΣ ΚΑΝΟΝΑΣ, ΟΧΙ ΩΣ ΕΞΑΙΡΕΣΗ ──
;;; 1. Κάθε frame που ΣΥΛΛΟΓΙΖΕΤΑΙ (υπαγωγή, σχεδιασμός απόδειξης, σύγκριση,
;;;    αποσαφήνιση) είναι :complex — τρέχει με ΟΡΑΤΗ σκέψη (with-deliberation,
;;;    καμία σκέψη αόρατη). Τα καθαρά ανακλητικά (κείμενο άρθρου) μένουν :simple
;;;    — εκεί η «αλυσίδα» θα ήταν θέατρο, και το θέατρο απαγορεύεται ρητά.
(defmethod orchestrator.cognition:triage ((f narrative-subsumption-frame)) :complex)
(defmethod orchestrator.cognition:triage ((f proof-quest-frame)) :complex)
(defmethod orchestrator.cognition:triage ((f compare-concepts-frame)) :complex)

;;; 2. ΟΡΙΖΟΝΤΑΣ ΠΡΑΞΕΩΝ — ύστατος ταξινομητής (τρέχει ΜΟΝΟ όταν όλοι οι
;;;    προηγούμενοι δεν έπιασαν): ερώτηση που αναφέρει πράξη του tatbestand
;;;    (κλοπή/υπεξαίρεση/ανθρωποκτονία/…) ΔΕΝ πέφτει σε «δεν κατάλαβα» —
;;;    απαντιέται με την αλυσίδα συλλογισμού του οικείου κανόνα: τι θα
;;;    χρειαζόταν να θεμελιωθεί. Σκέψη αντί για άγνοια, χωρίς καμία εικασία.
(orchestrator.cognition:register-classifier "act-horizon"
 (lambda (input)
   (when (eq (orchestrator.citation-authority:utterance-act input) :question)
     (let ((hit (%norm-for-act-word input)))
       (when hit
         (make-instance 'proof-quest-frame :input input
           :slots (list :norm-id (orchestrator.deontic:norm-id (first hit))
                        :act (second hit))))))))

;;; ── ΤΟ ΔΑΠΕΔΟ ΚΑΤΑΝΟΗΣΗΣ: question-agnostic, ύστατο, χωρίς καμία λίστα ──
;;; Καμία πρόβλεψη ερωτήσεων: για ΟΠΟΙΑΔΗΠΟΤΕ ερώτηση που κανένα εξειδικευμένο
;;; μονοπάτι δεν έπιασε, ΚΑΘΕ λέξη περιεχομένου — γνωστή (λήμμα) ή ΑΓΝΩΣΤΗ
;;; (επιφανειακό θέμα, δηλωμένο) — αναζητείται σε ΟΛΟΥΣ τους κώδικες. Ό,τι
;;; βρεθεί απαντιέται με τις πηγές του· ό,τι δεν βρεθεί ΚΑΤΑΓΡΑΦΕΤΑΙ ως κενό
;;; (τροφή του βρόχου αυτο-επέκτασης Σ11). Τίμια άγνοια μόνο όταν πράγματι
;;; δεν υπάρχει τίποτα — και τότε ΟΝΟΜΑΣΤΙΚΑ, όχι γενικό «δεν κατάλαβα».

(defclass general-inquiry-frame (orchestrator.cognition:frame) ()
  (:documentation "Ερώτηση εκτός εξειδικευμένων μονοπατιών: μνείες στα κείμενα
   για κάθε λέξη περιεχομένου (λήμμα ή επιφανειακό θέμα)."))

(defun %inquiry-findings (input)
  "((λέξη λήμμα|nil θέμα|nil ((tag num heading τίτλος-p)…))…) — μόνο λέξεις
   με ευρήματα. Σαρώνει ΟΛΟΥΣ τους κώδικες, με προτεραιότητα τίτλου."
  (let ((seen '()) (out '()))
    (dolist (tok (orchestrator.citation-authority:tokenize-greek input) (nreverse out))
      (let ((norm (orchestrator.citation-authority:normalize-greek tok)))
        (when (and (>= (length norm) 4)
                   (every #'alpha-char-p norm)
                   (not (member norm seen :test #'string=))
                   (orchestrator.citation-authority:content-lemma-p
                    (or (orchestrator.citation-authority:known-lemma tok) tok)))
          (push norm seen)
          (let* ((lemma (orchestrator.citation-authority:known-lemma tok))
                 (stem (unless lemma (orchestrator.citation-authority:surface-stem tok)))
                 (hits '()) (cseen '()))
            (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
              (destructuring-bind (tag . corpus) entry
                (unless (member corpus cseen :test #'string=)
                  (push corpus cseen)
                  (dolist (h (cond (lemma (%corpus-mentions corpus (list lemma) :limit 3))
                                   (stem  (%corpus-stem-mentions corpus stem :limit 3))))
                    (push (cons tag h) hits)))))
            (when hits
              (push (list tok lemma stem (nreverse hits)) out))))))))

(orchestrator.cognition:register-classifier "understanding-floor"
 (lambda (input)
   ;; Μνείες λέξης = απάντηση ΜΟΝΟ σε ερώτημα ΓΙΑ τον όρο (χρήση≠μνεία):
   ;; «τι είναι/σημαίνει/ορισμός/έννοια Χ». Στα λοιπά εκτός πεδίου, η ΤΙΜΙΑ
   ;; ΑΓΝΟΙΑ παραμένει η σωστή απάντηση — το κενό όμως ΚΑΤΑΓΡΑΦΕΤΑΙ.
   (when (and (eq (orchestrator.citation-authority:utterance-act input) :question)
              (cl-ppcre:scan (orchestrator.decisions:%fold
                              "τι +είναι|τι +σημαίνει|ορισμ|έννοια|τι +εννοε")
                             (orchestrator.decisions:%fold input)))
     (let ((findings (%inquiry-findings input)))
       (if findings
           (make-instance 'general-inquiry-frame :input input
             :slots (list :findings findings))
           ;; όρος χωρίς ΚΑΜΙΑ μνεία: κατέγραψε το κενό ονομαστικά — τίμια άγνοια
           (progn
             (dolist (tok (orchestrator.citation-authority:tokenize-greek input))
               (let ((norm (orchestrator.citation-authority:normalize-greek tok)))
                 (when (and (>= (length norm) 4) (every #'alpha-char-p norm)
                            (null (orchestrator.citation-authority:known-lemma tok))
                            (orchestrator.citation-authority:content-lemma-p tok))
                   (%lesson :concept-ungrounded tok "understanding-floor: καμία μνεία"))))
             nil))))))

(defun %propose-vocabulary (word forms)
  "Πρόταση Σ11: ΜΑΘΕ τη λέξη — λήμμα με μορφές ΜΑΡΤΥΡΗΜΕΝΕΣ στα κείμενα
   (καμία εικασία μορφολογίας). Η υιοθέτηση μένει στον δημιουργό (--approve)."
  (let ((others (remove word (mapcar #'car forms) :test #'string-equal)))
    (when others
      (orchestrator.proposals:propose!
       :sig (format nil "self-extension vocabulary ~A" word)
       :kind :self-extension
       :why (format nil "εκμάθηση λέξης «~A»: ~D μορφές μαρτυρημένες στα κείμενα" word (1+ (length others)))
       :payload (prin1-to-string
                 (list :filename (format nil "self-vocab-~A.sexp"
                                         (subseq (orchestrator.journal:sha256-hex word) 0 8))
                       :pack-text (with-output-to-string (o)
                                    (let ((*print-pretty* nil))
                                      (format o "(:knowledge-pack :lexicon 1~%")
                                      (format o " ;; ΑΥΤΟ-ΠΡΟΤΑΘΗΚΕ: μορφές μαρτυρημένες στα κείμενα των κωδίκων~%")
                                      (format o " (:lemma ~S (~{~S~^ ~})))~%" word others)))
                       :gap word))))))

(defmethod orchestrator.cognition:synthesize ((f general-inquiry-frame) cog)
  (declare (ignore cog))
  (let ((findings (orchestrator.cognition:frame-slot f :findings)))
    (string-right-trim '(#\Newline)
      (with-output-to-string (s)
        (dolist (w findings)
          (destructuring-bind (word lemma stem hits) w
            ;; ΜΕΛΕΤΗ του όρου στα ΙΔΙΑ τα κείμενα — όχι σκέτο ευρετήριο
            (let ((all-forms '()) (all-colls '()) (all-sents '()) (cseen '()))
              (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
                (destructuring-bind (tag . corpus) entry
                  (unless (member corpus cseen :test #'string=)
                    (push corpus cseen)
                    (multiple-value-bind (fs cs ss)
                        (%term-study corpus (or stem
                                                (orchestrator.citation-authority:normalize-greek word)))
                      (dolist (x fs) (let ((c (assoc (car x) all-forms :test #'string=)))
                                       (if c (incf (cdr c) (cdr x)) (push (copy-list x) all-forms))))
                      (dolist (x cs) (let ((c (assoc (car x) all-colls :test #'string=)))
                                       (if c (incf (cdr c) (cdr x)) (push (copy-list x) all-colls))))
                      (dolist (x ss) (push (cons tag x) all-sents))))))
              (setf all-colls (sort all-colls #'> :key #'cdr))
              (format s "«~A»~:[ — εκτός επιμελημένου λεξιλογίου· κατανόηση από τα ΙΔΙΑ τα κείμενα (θέμα «~A-»)~;~*~]:~%"
                      word lemma (or stem ""))
              ;; 1. ΤΙ ΕΙΝΑΙ — οριστικές διατυπώσεις των ίδιων των διατάξεων
              (let ((defs (remove-if-not (lambda (x) (fourth (cdr x))) all-sents)))
                (loop for d in defs repeat 2
                      do (format s "  ΟΡΙΖΕΤΑΙ στα κείμενα: «~A» (~A άρθρο ~A)~%"
                                 (third (cdr d)) (car d) (first (cdr d)))))
              ;; 2. ΠΩΣ ΛΕΙΤΟΥΡΓΕΙ — οι νομικοί ρόλοι του (συνάψεις με γενική)
              (when all-colls
                (format s "  Λειτουργεί στο δίκαιο ως:~{ «~A» (×~D)~^ ·~}~%"
                        (loop for c in all-colls repeat 3 append (list (car c) (cdr c)))))
              ;; 3. ΠΟΥ — οι πηγές (τίτλος πρώτα)
              (format s "  Πηγές:~{ ~A~^ ·~}~%"
                      (loop for h in hits repeat 6
                            collect (destructuring-bind (tag num heading title-p) h
                                      (format nil "~:[~;★ ~]~A ~A~@[ (~A)~]"
                                              title-p tag num
                                              (and title-p heading)))))
              ;; 4. ΜΑΘΗΣΗ — κενό καταγράφεται + πρόταση εκμάθησης της λέξης
              (unless (%resolve-concept word)
                (%lesson :concept-ungrounded word "understanding-floor")
                (if (and (null lemma) (%propose-vocabulary word all-forms))
                    (format s "  (κατέθεσα ΠΡΟΤΑΣΗ να μάθω τη λέξη — ~D μορφές μαρτυρημένες στα κείμενα· --thoughts / --approve)~%"
                            (length all-forms))
                    (format s "  (δεν έχω γειωμένο ορισμό — κατέγραψα το κενό)~%"))
                ;; ΑΦΟΜΟΙΩΣΗ: κάθε οριστική διατύπωση → πρόταση (:γένος …)
                ;; μέσω πλήρους σκιώδους πύλης — η υιοθέτηση δική σου
                (let* ((defs (loop for d in all-sents
                                   when (fourth (cdr d))
                                     collect (list (format nil "~A ~A" (car d) (first (cdr d)))
                                                   (third (cdr d)))))
                       (na (and defs (ignore-errors
                                       (propose-assimilations word (subseq defs 0 (min 3 (length defs))))))))
                  (when (and na (plusp na))
                    (format s "  (κατέθεσα ~D πρόταση~:[εις~;~] ΑΦΟΜΟΙΩΣΗΣ γένους από τους ορισμούς — --thoughts / --approve)~%"
                            na (= na 1))))))))
        (format s "Πλήρες κείμενο: «τι λέει το άρθρο <Ν> <κώδικας>».")))))

;;; ── Η ΟΥΡΑ ΤΟΥ ΔΙΑΛΟΓΟΥ — εγγράφεται ΕΔΩ (μετά από ΟΛΑ τα πεδία) ώστε να
;;; τρέχει τελευταία: ερώτηση που κανένα πεδίο δεν ανέλαβε = γενική γνώση,
;;; τίμια δηλωμένη ως μη εκτεθειμένη ικανότητα (έδρα: cognition-self.lisp).
(orchestrator.cognition:register-classifier "general-tail" #'%classify-general-tail)
