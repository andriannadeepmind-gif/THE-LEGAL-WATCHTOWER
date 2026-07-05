;;;; source/legal-extraction-verify.lisp
;;;; ============================================================================
;;;; Ο ΕΠΑΛΗΘΕΥΤΗΣ ΕΞΑΓΩΓΗΣ — η πύλη «neural προτείνει / symbolic κρίνει»
;;;; ============================================================================
;;;;
;;;; Το θεμέλιο του αυτόνομου, ασφαλούς βρόχου: ο σύμβουλος (LLM) ΠΡΟΤΕΙΝΕΙ δεοντική
;;;; δομή για μια διάταξη· ο συμβολικός πυρήνας τη ΔΕΧΕΤΑΙ ΜΟΝΟ αν αποδεικνύεται.
;;;; Το neural ΔΕΝ εμπιστεύεται ποτέ — προτείνει· η αλήθεια είναι ο πυρήνας. Έτσι
;;;; γεμίζει το L5 από τους πραγματικούς κώδικες ΧΩΡΙΣ να πέφτει το «0 λάθος», και
;;;; έτσι ένας agent που τρέχει ώρες ΔΕΝ μπορεί να αποκλίνει: κάθε βήμα περνά από εδώ.
;;;;
;;;; Η διαφορά από «keyword→δόγμα» (που απορρίφθηκε): εκεί η κατεύθυνση ήταν λέξη→
;;;; ισχυρισμός. Εδώ είναι ΠΡΟΤΑΣΗ→ΑΠΑΙΤΗΣΗ-ΑΠΟΔΕΙΞΗΣ. Ο επαληθευτής ΔΕΝ παράγει
;;;; ποτέ κανόνα από λέξεις-κλειδιά· απαιτεί από την πρόταση να φέρει το ακριβές
;;;; χωρίο του νόμου και ελέγχει ότι αυτό ΟΝΤΩΣ τεκμηριώνει τη δεοντική τυπικότητα.
;;;;
;;;; Τέσσερις έλεγχοι, όλοι ντετερμινιστικοί:
;;;;   V1 ΠΡΟΕΛΕΥΣΗ  — η πηγή «corpus:article» έγκυρη (και, αν δοθεί γράφος, κόμβος).
;;;;   V2 ΘΕΜΕΛΙΩΣΗ  — το προτεινόμενο χωρίο-απόδειξη υπάρχει ΑΥΤΟΛΕΞΕΙ στο κείμενο
;;;;                    της διάταξης ΚΑΙ φέρει δεοντικό τελεστή συμβατό με τη modality.
;;;;   V3 ΤΥΠΟΣ      — έγκυρη δεοντική τυπικότητα + ρυθμιζόμενη πράξη (δομικά ορθό).
;;;;   V4 ΣΥΝΕΠΕΙΑ   — δεν αυτο-αντιφάσκει (O(a)∧F(a) από την ΙΔΙΑ πηγή) στο JTMS.
;;;; Μία αποτυχία ⇒ ΑΠΟΡΡΙΨΗ με ρητό λόγο (τίμια άγνοια, ποτέ σιωπηλή εικασία).

(defpackage :orchestrator.extraction
  (:use :cl :orchestrator.inference :orchestrator.deontic)
  (:import-from :orchestrator.citation-authority #:normalize-greek)  ; η ΜΙΑ υλοποίηση, από την έδρα της
  (:export #:*deontic-markers* #:normalize-greek #:deontic-marker-in
           #:classify-deontic-sentence #:split-sentences
           #:verdict #:verdict-accepted-p #:verdict-norm #:verdict-checks #:verdict-reasons
           #:verify-proposal #:verify-and-register))

(in-package :orchestrator.extraction)

;;; ============================================================================
;;; Γλωσσική θεμελίωση — δεοντικοί τελεστές (στελέχη), ανά τυπικότητα
;;; ============================================================================
;;;
;;; ΔΕΝ είναι ταξινομητής· είναι το ΑΠΟΔΕΙΚΤΙΚΟ που απαιτεί ο επαληθευτής. Ο τελεστής
;;; της υποχρέωσης/απαγόρευσης/άδειας είναι το ΓΛΩΣΣΙΚΟ σημείο του δεοντικού κανόνα —
;;; έτσι τεκμηριώνεται η δεοντική τυπικότητα στην έννομη τάξη (LegalRuleML/δεοντική
;;; λογική). Στελέχη (όχι πλήρεις τύποι) ώστε να πιάνουν κλίσεις: «απαγορ» →
;;; απαγορεύεται/απαγόρευση/απαγορευμένος.

;;; Η δομή προέκυψε από ΜΕΤΡΗΜΕΝΟ αντιπαραθετικό έλεγχο (163 δείγματα, 5 κριτές):
;;; τα σκέτα στελέχη έδιναν 56% ορθότητα, με 7 ριζικά πρότυπα αστοχίας. Διορθώσεις
;;; εδώ, όλες γλωσσολογικά αιτιολογημένες, καμία ad-hoc λίστα εξαιρέσεων:
;;;   • ΜΟΝΟ ρηματικοί τελεστές — το «ποινή/απαγόρευση» ως ΟΥΣΙΑΣΤΙΚΟ σε αναφορική
;;;     θέση («η ποινή που επιβλήθηκε») δεν προστάζει τίποτα, αναφέρεται.
;;;   • ΠΡΟΤΕΡΑΙΟΤΗΤΑ τελεστών στην πρόταση: κύρωση/απαγόρευση > τροπικό ευχέρειας
;;;     («μπορεί να») > ορισμικός φραγμός > υποχρέωση > αδύναμη άδεια. Έτσι το
;;;     «όποιος … τιμωρείται» κυριαρχεί των στοιχείων του αδίκου («χωρίς δικαίωμα»),
;;;     και το «μπορεί να υποχρεώσει» είναι ευχέρεια, όχι υποχρέωση.
;;;   • ΑΡΝΗΣΗ ως αντιστροφή, με σημασιολογία: ¬Επιτρέπεται = ΑΠΑΓΟΡΕΥΣΗ (¬P=F)·
;;;     ¬Υποχρεούται (προσωπικό καθήκον) = ΑΠΑΛΛΑΓΗ→ΑΔΕΙΑ (¬O=P¬)· αλλά αρνημένο
;;;     ΑΠΡΟΣΩΠΟ ρήμα πράξης («δεν επιβάλλεται») = η πράξη δεν γίνεται = ΑΠΑΓΟΡΕΥΣΗ.
;;;   • ΟΡΙΣΜΙΚΟΣ ΦΡΑΓΜΟΣ: «νοείται/θεωρείται/λογίζεται/πράττει όποιος» χωρίς ισχυρό
;;;     τελεστή = περιγραφή/ορισμός, ΟΧΙ δεοντικό περιεχόμενο.

(defparameter *deontic-markers*
  '(;; απαγόρευση — ρηματικοί τελεστές κύρωσης/απαγόρευσης, ΕΝΕΣΤΩΤΙΚΗ οριστική
    ;; («τιμωρήθηκαν» = περιγραφή προϋπόθεσης, όχι τελεστής — β' γύρος, πρότυπο Β)
    (:prohibition-verb . ("τιμωρειτ" "τιμωρουντ" "απαγορευετ" "απαγορευοντ" "κολαζετ"))
    ;; εγγενώς αρνητικοί τελεστές (η άρνηση ΕΙΝΑΙ ο τελεστής)
    ;; «δεν μπορεί/μπορούν» ΕΝΕΣΤΩΤΑΣ μόνο — το «δεν μπόρεσε» είναι αληθικό
    ;; παρελθόν (αδυναμία γεγονότος), όχι απαγόρευση (γ' γύρος, πρότυπο 7)
    (:prohibition-negative . ("δεν επιτρεπ" "δεν δυνατ" "δεν μπορει" "δεν μπορουν"
                              "ουδεις" "κανεις δεν"
                              "δεν εχει δικαιωμα" "δεν εχουν δικαιωμα" "δεν πρεπει"
                              "δεν συγχωρειτ" "δεν χωρει"))
    ;; τροπικά ευχέρειας/άδειας — άμεσα στελέχη (τα ασυνεχή «μπορεί … να» τα
    ;; χειρίζεται ο %modal-hits με φραγμένο κενό)
    (:permission-modal . ("επιτρεπετ" "επιτρεποντ" "δικαιουτ" "δικαιουντ"
                          "εχει το δικαιωμα" "εχουν το δικαιωμα" "εχει δικαιωμα να"
                          "κρινεται ελευθερα" "κρινει ελευθερα" "κρινουν ελευθερα"
                          "κατα την κριση" "κατα την ελευθερη κριση"
                          "αρκει να"))   ; κανόνας επάρκειας = απαλλαγή από τα πλείονα
    ;; ρήματα ευχέρειας με (πιθανώς ασυνεχές) να-συμπλήρωμα
    (:modal-verb . ("μπορει" "μπορουν" "δυναται" "δυνανται"))
    ;; αληθικά/γνωσιακά συμπληρώματα: «μπορεί να αποδειχθεί» = δυνατότητα γεγονότος,
    ;; ΟΧΙ άδεια (β' γύρος, πρότυπο Α) — μικρή, σημασιολογικά ορισμένη κατηγορία
    (:epistemic-complement . ("αποδειχθ" "εξακριβωθ" "διαπιστωθ" "ολοκληρωθ"
                              "υπαρξ" "νοηθ" "προκυψ"))
    ;; αδύναμη άδεια (μόνο όταν τίποτα ισχυρότερο δεν υπάρχει)
    (:permission-weak . ("δικαιωμα να" "ευχερεια"))
    ;; λεξική απαλλαγή = ¬O→P («απαλλάσσεται από την υποχρέωση»)
    (:obligation-release . ("απαλλασσετ" "απαλλασσοντ"))
    ;; υποχρέωση — ΠΡΟΣΩΠΙΚΟ καθήκον, ΡΗΜΑΤΙΚΑ αγκυρωμένο («η δέσμευση»/«ο
    ;; οφειλέτης» είναι ουσιαστικά, δεν προστάζουν — β' γύρος, πρότυπο Γ)
    (:obligation-personal . ("υποχρεουτ" "υποχρεουντ" "υποχρεωμεν" "υποχρεωτικ"
                             "οφειλει" "οφειλουν" "οφειλεται" "οφειλονται"
                             "δεσμευει" "δεσμευεται" "δεσμευονται"))
    ;; υποχρέωση — ΑΠΡΟΣΩΠΗ επιταγή (η άρνησή τους = η πράξη δεν γίνεται → απαγόρευση)
    (:obligation-impersonal . ("πρεπει" "επιβαλλετ" "επιβαλλοντ" "διατασσετ" "διατασσοντ"))
    ;; ορισμικός/διαπλαστικός/συστατικός/μετα-κανονιστικός λόγος — φραγμός, όχι
    ;; τελεστής (γ' γύρος, πρότυπα 1/2/5): ορισμοί («συνίσταται»), συστατικοί όροι
    ;; κύρους («για να έχει/είναι … πρέπει»), αποφαντικά ρήματα (το δεοντικό στο
    ;; συμπλήρωμά τους είναι ΠΕΡΙΕΧΟΜΕΝΟ της απόφασης), παραπομπές και επιφυλάξεις
    ;; νόμου (ο κανόνας ζει στο παραπεμπόμενο/μελλοντικό δίκαιο, όχι εδώ)
    (:definitional . ("νοειτ" "θεωρειτ" "λογιζετ" "σημαινει" "πραττει οποιοσ"
                      "ειναι αυτη κατα την οποια" "συνισταται"
                      "για να εχει" "για να ειναι"
                      "αποφαινετ" "γνωμοδοτ"
                      "εφαρμοζεται και" "εφαρμοζεται αναλογ" "εφαρμοζονται αναλογ"
                      "ισχυει και" "το ιδιο ισχυει"
                      "νομοσ οριζει" "οπωσ νομοσ οριζει" "νομοσ καθοριζει" "οπωσ ο νομοσ οριζει")))
  "Δεοντικοί τελεστές ανά ΛΕΙΤΟΥΡΓΙΚΗ κατηγορία (κανονικοποιημένα στελέχη). Η
   ταξινόμηση γίνεται από την CLASSIFY-DEONTIC-SENTENCE με προτεραιότητα ΚΑΙ
   θέση/εμβέλεια — ποτέ από γυμνό ταίριασμα στελέχους.")

(defun %ops (key) (cdr (assoc key *deontic-markers*)))

;;; ── ΕΜΒΕΛΕΙΕΣ: δευτερεύουσες προτάσεις δεν προστάζουν (β' γύρος, πρότυπα Α/Β) ──
;;; Τελεστής μέσα σε υπόθεση («αν/εφόσον/όταν …») ή αναφορική («που/ο οποίος …»)
;;; ΠΕΡΙΓΡΑΦΕΙ την προϋπόθεση ή το αντικείμενο — δεν είναι η προσταγή της διάταξης.
;;; Η κύρια πρόταση προηγείται· οι δευτερεύουσες μόνο ως ύστατη εφεδρεία.

(defparameter *conditional-starters* '("αν " "εαν " "εφοσον " "οταν " "αφου " "σε περιπτωση "
                                       "οτι ")
  "Εναρκτήρες ΥΠΟΘΕΣΗΣ/ΣΥΜΠΛΗΡΩΜΑΤΟΣ (χωρίς το προπορευόμενο κενό — ελέγχονται
   και στην αρχή της πρότασης: «Αν …, τότε …»). Το «ότι» καλύπτει τις ειδικές
   προτάσεις: «αποφαίνεται ΟΤΙ δεν πρέπει…» = περιεχόμενο απόφασης, όχι κανόνας.
   Η εμβέλεια κλείνει στο επόμενο σημείο στίξης.")

(defparameter *relative-starters* '(" που " " οποι")
  "Εναρκτήρες ΑΝΑΦΟΡΙΚΗΣ (με προπορευόμενο κενό — το «Όποιος» στην αρχή ποινικής
   πρότασης ΔΕΝ πιάνεται: είναι το υποκείμενο του κανόνα, όχι αναφορική).")

(defun %all-operator-stems ()
  "Όλα τα ρηματικά στελέχη-τελεστές — για τον τερματισμό αναφορικής: η αναφορική
   «…που ΤΙΜΩΡΟΥΝΤΑΙ με κάθειρξη…» κλείνει ΜΕΤΑ το δικό της ρήμα-τελεστή, ώστε η
   συνέχεια («…επιβάλλεται συνολική ποινή») να μείνει στην κύρια πρόταση."
  (append (%ops :prohibition-verb) (%ops :permission-modal) (%ops :modal-verb)
          (%ops :obligation-personal) (%ops :obligation-impersonal) (%ops :obligation-release)))

(defun %subordinate-spans (norm)
  "Τα διαστήματα [start,end) του NORM που ανήκουν σε δευτερεύουσες.
   ΥΠΟΘΕΣΗ (αν/εάν/εφόσον/όταν, και στην αρχή της πρότασης): έως το επόμενο σημείο
   στίξης. ΑΝΑΦΟΡΙΚΗ (που/ο οποίος): έως το σημείο στίξης Ή έως ΜΕΤΑ τον πρώτο
   ρηματικό τελεστή της (όποιο έρθει πρώτο) — ο τελεστής της αναφορικής περιγράφει
   το αντικείμενο, δεν προστάζει."
  (let ((spans '())
        (punct-at (lambda (from) (position-if (lambda (c) (member c '(#\, #\. #\· #\; #\:)))
                                              norm :start from))))
    ;; υποθέσεις — και στην αρχή (θέση 0), και μετά από κενό
    (dolist (st *conditional-starters*)
      (let ((spaced (concatenate 'string " " st)))
        (when (and (>= (length norm) (length st)) (string= st norm :end2 (length st)))
          (push (cons 0 (or (funcall punct-at 0) (length norm))) spans))
        (loop for pos = (search spaced norm) then (search spaced norm :start2 (1+ pos))
              while pos
              do (push (cons (1+ pos) (or (funcall punct-at (1+ pos)) (length norm))) spans))))
    ;; αναφορικές — κλείνουν μετά τον πρώτο τελεστή τους (ή στη στίξη)
    (dolist (st *relative-starters* spans)
      (loop for pos = (search st norm) then (search st norm :start2 (1+ pos))
            while pos
            do (let* ((from (1+ pos))
                      (punct (funcall punct-at from))
                      (op-end (loop for v in (%all-operator-stems)
                                    for p = (search (normalize-greek v) norm :start2 from)
                                    when p minimize (+ p (length v)) into m and count p into k
                                    finally (return (and (plusp k) m))))
                      (end (cond ((and punct op-end) (min punct op-end))
                                 (t (or punct op-end (length norm))))))
                 (push (cons from end) spans))))))

(defun %in-subordinate-p (pos spans)
  (loop for (from . end) in spans thereis (and (<= from pos) (< pos end))))

;;; Η κανονικοποίηση ελληνικών ζει στην έδρα της γλωσσικής γνώσης
;;; (orchestrator.citation-authority, greek-lemmatizer.lisp) — εδώ ΕΙΣΑΓΕΤΑΙ.

(defun %negated-at-p (norm-text pos)
  "Βρίσκεται η θέση POS του (κανονικοποιημένου) NORM-TEXT υπό ΑΡΝΗΣΗ; Κοιτάζει
   πίσω, ΕΝΤΟΣ της ίδιας φράσης (δεν διασχίζει , . · ; :), για αρνητικό μόριο
   (δεν/μη/μην/ούτε/ουδόλως). «Δεν επιτρέπεται» ⇒ το «επιτρεπ» ΔΕΝ τεκμηριώνει
   άδεια — η άρνηση αντιστρέφει τον τελεστή, δεν τον αγνοεί."
  (let* ((start (max 0 (- pos 30)))
         (window (subseq norm-text start pos))
         (b (position-if (lambda (c) (member c '(#\, #\. #\· #\; #\:))) window :from-end t))
         (clause (if b (subseq window (1+ b)) window)))
    (loop for tok in (uiop:split-string clause :separator " ")
            thereis (member tok '("δεν" "δε" "μη" "μην" "ουτε" "ουδολωσ") :test #'string=))))

(defun %inherently-negative-p (nstem)
  (or (search "δεν " nstem) (search "ουδ" nstem) (search "κανεισ" nstem)))

(defun %op-positions (norm stems spans &key subordinate)
  "(values positives negateds): θέσεις εμφάνισης των STEMS στο NORM, στην περιοχή
   που ζητήθηκε (κύρια όταν SUBORDINATE=nil, δευτερεύουσες όταν t). Εγγενώς
   αρνητικά στελέχη μετρούν στα positives — η άρνηση είναι ο τελεστής."
  (let ((pos+ '()) (pos- '()))
    (dolist (stem stems (values (sort pos+ #'<) (sort pos- #'<)))
      (let ((nstem (normalize-greek stem)))
        (loop for pos = (search nstem norm) then (search nstem norm :start2 (1+ pos))
              while pos
              do (when (eq (and (%in-subordinate-p pos spans) t) (and subordinate t))
                   (cond ((%inherently-negative-p nstem) (push pos pos+))
                         ((%negated-at-p norm pos)       (push pos pos-))
                         (t                              (push pos pos+)))))))))

(defun %modal-hits (norm spans &key subordinate)
  "(values positives negateds) για τα ρήματα ευχέρειας με να-συμπλήρωμα, ΚΑΙ
   ασυνεχή («μπορεί … να διατάξει», έως ~60 χαρακτήρες χωρίς στίξη). Συμπλήρωμα
   αληθικό/γνωσιακό («να αποδειχθεί») ⇒ ΔΕΝ είναι δεοντικός τελεστής (values
   επιστρέφει και τη θέση για τον έλεγχο του αποκλειστικού «μόνο»)."
  (let ((pos+ '()) (pos- '()))
    (dolist (verb (%ops :modal-verb))
      (loop for pos = (search verb norm) then (search verb norm :start2 (1+ pos))
            while pos
            do (when (eq (and (%in-subordinate-p pos spans) t) (and subordinate t))
                 ;; το «να»-συμπλήρωμα διαπερνά παρενθετικά κόμματα ΚΑΙ απαριθμήσεις
                 ;; («μπορεί: α) να διατάξει … β) να επιβάλει») — φραγμός μόνο η
                 ;; τελεία/άνω τελεία (γ' γύρος, πρότυπο 4)
                 (let* ((limit (min (length norm) (+ pos 60)))
                        (punct (position-if (lambda (c) (member c '(#\. #\· #\;)))
                                            norm :start pos :end limit))
                        (na (search " να " norm :start2 pos :end2 (or punct limit))))
                   (when na
                     ;; αληθικό συμπλήρωμα; («να αποδειχθεί/εξακριβωθεί…»)
                     (let* ((cstart (+ na 4))
                            (epistemic (some (lambda (e) (let ((p (search e norm :start2 cstart)))
                                                           (and p (< p (+ cstart 24)))))
                                             (%ops :epistemic-complement))))
                       (unless epistemic
                         (if (%negated-at-p norm pos)
                             (push pos pos-)
                             (push pos pos+)))))))))
    ;; και τα άμεσα τροπικά στελέχη (επιτρέπεται, δικαιούται, κατά την κρίση…)
    (multiple-value-bind (p+ p-) (%op-positions norm (%ops :permission-modal) spans
                                                :subordinate subordinate)
      (values (sort (append pos+ p+) #'<) (sort (append pos- p-) #'<)))))

(defun %exclusive-only-after-p (norm pos)
  "Ακολουθεί περιοριστικό « μονο » εντός της εμβέλειας του τελεστή στη θέση POS;
   «μπορεί να αποδειχθεί ΜΟΝΟ με τα πρακτικά» / «επιβάλλονται ΜΟΝΟ ύστερα από
   σύμφωνη γνώμη» = αποκλειστικός κανόνας ⇒ απαγόρευση του εκτός-όρου (¬άλλως).
   ΕΞΑΙΡΕΣΗ ο ποσοδείκτης μέσα σε ονοματική φράση («ένα ΜΟΝΟ αντίγραφο»): εκεί
   το «μόνο» μετρά ποσότητα, δεν περιορίζει την άδεια."
  (let* ((limit (min (length norm) (+ pos 100)))
         (punct (position-if (lambda (c) (member c '(#\. #\· #\;))) norm :start pos :end limit)))
    (loop for m = (search " μονο " norm :start2 pos :end2 (or punct limit))
            then (search " μονο " norm :start2 (1+ m) :end2 (or punct limit))
          while m
          do (let* ((before (subseq norm (max 0 (- m 12)) m))
                    (toks (uiop:split-string before :separator " "))
                    (prev (car (last (remove "" toks :test #'string=)))))
               (unless (member prev '("ενα" "μια" "εναν" "ενοσ" "μιασ" "δυο" "τρια")
                               :test #'equal)
                 (return m))))))

(defun split-sentences (text)
  "Τεμαχισμός σε προτάσεις (όρια: τελεία/άνω τελεία/ερωτηματικό + κενό, ή αλλαγή
   γραμμής). Κάθε πρόταση μένει ΑΥΤΟΛΕΞΕΙ υπόστρωμα του κειμένου — ο επαληθευτής
   την ελέγχει ανεξάρτητα, ό,τι κι αν κάνει ο τεμαχισμός."
  (let ((res '()) (start 0) (n (length text)))
    (loop for i from 0 below n do
      (let ((c (char text i)))
        (when (or (char= c #\Newline)
                  (and (member c '(#\. #\; #\·))
                       (or (= i (1- n))
                           (member (char text (1+ i)) '(#\Space #\Tab #\Newline)))))
          (push (subseq text start (1+ i)) res)
          (setf start (1+ i)))))
    (when (< start n) (push (subseq text start) res))
    (remove-if (lambda (s) (< (length s) 16))
               (mapcar (lambda (s) (string-trim '(#\Space #\Tab #\Newline) s))
                       (nreverse res)))))

(defun %classify-region (norm spans subordinate)
  "Η κλιμάκωση προτεραιότητας σε ΜΙΑ περιοχή (κύρια ή δευτερεύουσες).
   Επιστρέφει (values modality operator) ή (nil nil)."
  (flet ((ops+ (key) (nth-value 0 (%op-positions norm (%ops key) spans :subordinate subordinate)))
         (ops- (key) (nth-value 1 (%op-positions norm (%ops key) spans :subordinate subordinate))))
    (multiple-value-bind (modal+ modal-) (%modal-hits norm spans :subordinate subordinate)
      (let* ((prohib (append (ops+ :prohibition-verb) (ops+ :prohibition-negative)
                             modal- (ops- :obligation-impersonal)))
             (first-prohib (and prohib (reduce #'min prohib)))
             (first-modal  (and modal+ (reduce #'min modal+))))
        ;; ΑΠΟΚΛΕΙΣΤΙΚΟ «μόνο»: τελεστής + « μονο » στην εμβέλειά του = απαγόρευση
        ;; του εκτός-όρου — ελέγχεται σε ΩΜΕΣ τροπικές θέσεις (και τις αληθικές:
        ;; «μπορεί να αποδειχθεί ΜΟΝΟ με τα πρακτικά» αποκλείει κάθε άλλο μέσο).
        (let ((raw-op (append (nth-value 0 (%op-positions norm (%ops :modal-verb) spans
                                                          :subordinate subordinate))
                              modal+ (ops+ :obligation-impersonal))))
          (loop for p in raw-op
                when (%exclusive-only-after-p norm p)
                  do (return-from %classify-region (values :prohibition "μονο-αποκλειστικο"))))
        ;; 1 — απαγόρευση (νωρίτερη θέση κερδίζει το τροπικό: «τιμωρείται … και
        ;; μπορεί» ≠ «μπορεί να …» — κυριαρχεί όποιος προηγείται στην πρόταση)
        (when (and first-prohib (or (null first-modal) (< first-prohib first-modal)))
          (return-from %classify-region (values :prohibition "απαγορευτικος-τελεστης")))
        ;; 2 — άδεια: τροπικό ευχέρειας (κυριαρχεί του να-συμπληρώματός του) ·
        ;;     απαλλαγή: αρνημένο προσωπικό καθήκον ή λεξική απαλλαγή (¬O=P)
        (when first-modal
          (return-from %classify-region (values :permission "τροπικο-ευχερειας")))
        (when (or (ops- :obligation-personal) (ops+ :obligation-release))
          (return-from %classify-region (values :permission "απαλλαγη")))
        ;; 3 — ορισμικός φραγμός (επιστρέφει σήμα: μπλοκάρει και την εφεδρεία)
        (when (ops+ :definitional)
          (return-from %classify-region (values nil "ορισμικος-φραγμος")))
        ;; 4 — υποχρέωση
        (when (or (ops+ :obligation-personal) (ops+ :obligation-impersonal))
          (return-from %classify-region (values :obligation "τελεστης-καθηκοντος")))
        ;; 5 — αδύναμη άδεια
        (when (ops+ :permission-weak)
          (return-from %classify-region (values :permission "αδυναμη-αδεια")))
        (values nil nil)))))

(defun classify-deontic-sentence (sentence)
  "Η δεοντική τυπικότητα ΜΙΑΣ πρότασης: (values modality operator) ή (nil nil).
   Προτεραιότητα τελεστών ΚΑΙ εμβέλεια — μετρημένη σε δύο γύρους αντιπαραθετικού
   ελέγχου (56% → 81,5% → γ' γύρος με τα παρόντα):
     • Η ΚΥΡΙΑ πρόταση προστάζει· τελεστές σε υπόθεση/αναφορική περιγράφουν
       (εφεδρεία ΜΟΝΟ όταν η κύρια δεν φέρει τίποτα).
     • Κλιμάκωση: αποκλειστικό «μόνο» > απαγόρευση (κύρωση/εγγενής άρνηση/¬P/
       ¬απρόσωπη-επιταγή, με τη ΝΩΡΙΤΕΡΗ θέση να κυριαρχεί έναντι τροπικού) >
       άδεια (τροπικό ευχέρειας — και ασυνεχές «μπορεί … να» — ή απαλλαγή ¬O=P) >
       ορισμικός φραγμός > υποχρέωση > αδύναμη άδεια.
     • Αληθικό «μπορεί» («να αποδειχθεί/εξακριβωθεί…») δεν είναι τελεστής."
  (let* ((norm (normalize-greek sentence))
         (spans (%subordinate-spans norm)))
    (multiple-value-bind (m op) (%classify-region norm spans nil)
      (cond (m (values m op))
            (op (values nil nil))                 ; ορισμικός φραγμός — τέλος
            (t (%classify-region norm spans t)))))) ; ύστατη εφεδρεία: δευτερεύουσες

(defun deontic-marker-in (modality text)
  "Ο τελεστής που τεκμηριώνει τη MODALITY στο TEXT, ή nil — ΜΕΣΩ του ταξινομητή
   πρότασης (προτεραιότητα + άρνηση), ποτέ με γυμνό ταίριασμα στελέχους. Το TEXT
   κρίνεται ανά πρόταση: αρκεί μία πρόταση με αυτή την τυπικότητα."
  (loop for s in (or (split-sentences text) (list text))
        do (multiple-value-bind (m op) (classify-deontic-sentence s)
             (when (eq m modality) (return op)))))

;;; ============================================================================
;;; Η ετυμηγορία επαλήθευσης
;;; ============================================================================

(defstruct (verdict (:constructor %verdict))
  (accepted-p nil)   ; δεκτή η πρόταση;
  (norm nil)         ; ο επαληθευμένος κανόνας (αν δεκτή)
  (checks nil)       ; plist ελέγχων: (:v1 t/nil :v2 … :v3 … :v4 …)
  (reasons nil))     ; λόγοι απόρριψης (λίστα συμβολοσειρών)

(defun verify-proposal (&key modality consequent source scope text evidence
                             (graph nil) (against (all-norms)))
  "Επαλήθευσε μια ΠΡΟΤΑΣΗ δεοντικής δομής για μια διάταξη. Επιστρέφει VERDICT.
   TEXT: το πλήρες κείμενο της διάταξης. EVIDENCE: το ΑΚΡΙΒΕΣ χωρίο που παραθέτει
   ο σύμβουλος ως τεκμήριο. GRAPH: αν δοθεί, το V1 ελέγχει ύπαρξη κόμβου-πηγής.
   AGAINST: οι ήδη επαληθευμένοι κανόνες, για τον έλεγχο συνέπειας."
  (let ((checks '()) (reasons '()))
    (labels ((fail (key msg) (setf (getf checks key) nil) (push msg reasons))
             (pass (key) (setf (getf checks key) t)))
      ;; V1 — ΠΡΟΕΛΕΥΣΗ: έγκυρη «corpus:article» και, αν δοθεί γράφος, υπαρκτός κόμβος
      (cond ((not (and source (stringp source) (find #\: source)))
             (fail :v1 (format nil "άκυρη πηγή «~A» (αναμένεται corpus:article)" source)))
            ((and graph
                  (not (funcall (find-symbol "NODE" :orchestrator.graph)
                                (format nil "art:~A" source) graph)))
             (fail :v1 (format nil "η πηγή «~A» δεν αντιστοιχεί σε κόμβο «art:~A» του γράφου" source source)))
            (t (pass :v1)))
      ;; V3 — ΤΥΠΟΣ
      (cond ((not (member modality '(:obligation :prohibition :permission)))
             (fail :v3 (format nil "άγνωστη δεοντική τυπικότητα ~S" modality)))
            ((null consequent)
             (fail :v3 "χωρίς ρυθμιζόμενη πράξη (consequent)"))
            (t (pass :v3)))
      ;; V2 — ΘΕΜΕΛΙΩΣΗ (η καρδιά: απόδειξη στο κείμενο)
      (cond ((or (null text) (null evidence))
             (fail :v2 "λείπει κείμενο διάταξης ή χωρίο-απόδειξη"))
            ((not (search (normalize-greek evidence) (normalize-greek text)))
             (fail :v2 "το χωρίο-απόδειξη ΔΕΝ υπάρχει αυτολεξεί στη διάταξη — πιθανή επινόηση"))
            ((not (deontic-marker-in modality evidence))
             (fail :v2 (format nil "το χωρίο δεν φέρει δεοντικό τελεστή ~A — η τυπικότητα δεν τεκμηριώνεται"
                               modality)))
            (t (pass :v2)))
      ;; V4 — ΣΥΝΕΠΕΙΑ (αυτο-αντίφαση από την ΙΔΙΑ πηγή)
      (let ((clash (find-if (lambda (n)
                              (and (equal (norm-source n) source)
                                   (equal (norm-consequent n) consequent)
                                   (or (and (eq modality :obligation)  (eq (norm-modality n) :prohibition))
                                       (and (eq modality :prohibition) (eq (norm-modality n) :obligation)))))
                            against)))
        (if clash
            (fail :v4 (format nil "αυτο-αντίφαση: η πηγή «~A» ήδη ορίζει αντίθετη τυπικότητα για την ίδια πράξη" source))
            (pass :v4)))
      ;; ── ετυμηγορία ──
      (let ((ok (and (getf checks :v1) (getf checks :v2) (getf checks :v3) (getf checks :v4))))
        (%verdict :accepted-p ok
                  :norm (when ok (make-norm :id (intern (format nil "NORM-~A" source) :keyword)
                                            :modality modality :antecedent nil
                                            :consequent consequent :scope scope :source source))
                  :checks checks :reasons (nreverse reasons))))))

(defun verify-and-register (&rest args &key &allow-other-keys)
  "Επαλήθευσε και, ΜΟΝΟ αν δεκτή, κατέγραψε τον κανόνα στο L5. Επιστρέφει το VERDICT.
   Αυτό είναι το ένα βήμα του αυτόνομου βρόχου: ό,τι περνά μπαίνει με πηγή· ό,τι
   κόβεται μένει ρητά καταγεγραμμένο ως άγνοια προς επίλυση."
  (let ((v (apply #'verify-proposal args)))
    (when (verdict-accepted-p v) (register-norm (verdict-norm v)))
    v))
