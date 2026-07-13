;;;; source/legal-casegrammar.lisp
;;;; ============================================================================
;;;; Σ4β — ΓΡΑΜΜΑΤΙΚΗ ΠΤΩΣΕΩΝ (Fillmore, whole-clause SVO-G): ΑΦΗΓΗΣΗ → γεγονότα
;;;; ============================================================================
;;;;
;;;; Η υπαγωγή (Σ4) δέχεται γεγονότα-tuples· εδώ χτίζεται η γέφυρα από τα φυσικά
;;;; ελληνικά. Αρχιτεκτονική [0082] — η εμπειρικά ανώτερη βάση (διαφορικό OLD↔NEW,
;;;; τυφλοί κριτές + απόλυτη βαθμολόγηση), ΟΧΙ clause-splitting σε κόμματα:
;;;;   · Ρόλοι κατά ΠΤΩΣΗ από ΜΟΝΟΣΗΜΑΝΤΟ άρθρο (*article-table*): ονομαστική=
;;;;     δράστης, αιτιατική=θέμα (και fronted ⇒ OVS), με ΘΕΣΙΑΚΗ εφεδρεία όταν
;;;;     δεν υπάρχει άρθρο. Τα αμφίσημα ουδέτερα (το/τα) ΔΕΝ οδηγούν ρόλο —
;;;;     δηλωμένο όριο, τα καλύπτει η θεσιακή εφεδρεία.
;;;;   · Θέμα = ΚΕΦΑΛΗ (τελευταίο περιεχόμενο) του πρώτου post-verb NP· το NP
;;;;     κλείνει σε πρόθεση/γενική/δείκτη/ρήμα ⇒ πλάγιο αιτιατικό ΔΕΝ κλέβει θέμα.
;;;;   · Κτήτορας από άρθρο ΓΕΝΙΚΗΣ ≠ δράστης ⇒ ΞΕΝΟ. Άρνηση προ ρήματος
;;;;     (+negators+) ⇒ ΜΟΝΟ (:άρνηση …), κανένα παράγωγο.
;;;;   · Νομικοί όροι-τέχνης: κεφαλή+επίθετα κλειδωμένα σε ΛΗΜΜΑΤΑ (morph-lemma,
;;;;     έδρα [0078]) ⇒ γενίκευση στην κλίση («νόμιμης άμυνας» ≡ «νόμιμη άμυνα»),
;;;;     με ΦΡΑΓΜΕΝΟ look-back αναιρετή (χωρίς/δεν) — δηλωμένα ΟΧΙ πλήρες c-command.
;;;;   · Συντονισμός: σπάει ΜΟΝΟ γνήσιες ανεξάρτητες προτάσεις («… και <καθαρή
;;;;     ονομαστική> … <ρήμα>») — ποτέ VP/NP-συντονισμό ή υποτακτικές· η ανάλυση
;;;;     ΔΕΝ σπάει σε κόμματα/PP (υποκείμενο/ρήμα μπορούν να απέχουν).
;;;;
;;;; ΟΛΗ η γλωσσική γνώση ΔΗΛΩΤΙΚΗ (πακέτο :verb-frames): ρήμα→κατηγόρημα,
;;;; ουσιαστικό→κατηγορία, επίθετο→κατηγορία, δείκτες, concepts. Η μορφολογία και τα
;;;; λήμματα είναι Η ΜΙΑ έδρα γλώσσας (orchestrator.citation-authority).
;;;;
;;;; ΤΙΜΙΟΤΗΤΑ: ό,τι δεν αναγνωρίζεται ΔΗΛΩΝΕΤΑΙ — ποτέ δεν εφευρίσκονται γεγονότα.
;;;; Δογματική χαρτογράφηση: κτήτορας ≠ δράστης ⇒ το πράγμα είναι ΞΕΝΟ.

(defpackage :orchestrator.casegrammar
  (:use :cl)
  (:import-from :orchestrator.citation-authority
                #:tokenize-greek #:known-lemma #:normalize-greek #:content-lemma-p
                #:surface-stem #:morph-lemma #:+negators+)
  (:export #:*verb-frames* #:*noun-classes* #:*markers* #:*concepts*
           #:parse-narrative #:narrative-report
           #:parse-definition #:+definitional-markers+
           #:parse-provision #:*adjectives*))

(in-package :orchestrator.casegrammar)

(defvar *verb-frames* '()
  "alist: ρηματικό λήμμα → κατηγόρημα γεγονότος (πχ \"αφαιρώ\" → :αφαιρεί).")
(defvar *noun-classes* '()
  "alist: ουσιαστικό λήμμα → κατηγορία των Κατηγοριών (πχ \"πορτοφόλι\" → :κινητό).")
(defvar *markers* '()
  "λίστα (λήμμα κατηγόρημα τιμή): δείκτες που γεννούν γεγονός για τον ΔΡΑΣΤΗ
   (πχ «ιδιοποιηθεί» ⇒ (:γεγονός Δ :σκοπός :παράνομη-ιδιοποίηση)).")
(defvar *adjectives* '()
  "alist: επιθετικό λήμμα → κατηγορία (πχ \"ξένος\" → :ξένο). Τα επίθετα της
   ονοματικής φράσης ΕΙΝΑΙ κατηγορήματα του αντικειμένου — «ξένο κινητό πράγμα» =
   πράγμα ∧ ξένο ∧ κινητό (οι Κατηγορίες στη σύνταξη).")

(defvar *concepts* '()
  "λίστα ((head-lemma . sorted-adj-lemmas) pred value): ΝΟΜΙΚΟΙ ΟΡΟΙ-ΤΕΧΝΗΣ —
   «νόμιμη άμυνα» = κεφαλή-λήμμα «άμυνα» + επίθετο-λήμμα «νόμιμος». Κλειδωμένο σε
   ΛΗΜΜΑΤΑ (μέσω morph-lemma, έδρα [0078]) ⇒ ΓΕΝΙΚΕΥΕΙ στην κλίση: «νόμιμης άμυνας»
   ≡ «νόμιμη άμυνα». Αντικαθιστά το exact-substring MWE (που ΗΤΑΝ μπάλωμα: δεν
   γενίκευε, [0076] verify). Η αναίρεση όρου («χωρίς»/«δεν» πριν το ΝΡ) ελέγχεται
   με ΦΡΑΓΜΕΝΟ look-back (%phrase-negated-p) — δηλωμένο όριο, όχι πλήρης δομή.")

(orchestrator.knowledge-packs:define-knowledge-kind :verb-frames
 :doc "Γλωσσική γνώση: (:frame ΡΗΜΑ ΚΑΤΗΓΟΡΗΜΑ) · (:noun-class ΛΗΜΜΑ ΚΑΤΗΓΟΡΙΑ) ·
 (:marker ΛΗΜΜΑ ΚΑΤΗΓΟΡΗΜΑ ΤΙΜΗ) · (:adjective ΛΗΜΜΑ ΚΑΤΗΓΟΡΙΑ) · (:concept
 ΚΕΦΑΛΗ-ΛΗΜΜΑ (ΕΠΙΘΕΤΟ-ΛΗΜΜΑΤΑ…) ΚΑΤΗΓΟΡΗΜΑ ΤΙΜΗ) — η γέφυρα αφήγησης→γεγονότων."
 :install
 (lambda (entries)
   (dolist (e entries)
     (ecase (first e)
       (:frame (destructuring-bind (k lemma pred) e
                 (declare (ignore k))
                 (setf *verb-frames*
                       (cons (cons lemma pred)
                             (remove lemma *verb-frames* :key #'car :test #'string=)))))
       (:noun-class (destructuring-bind (k lemma class) e
                      (declare (ignore k))
                      (setf *noun-classes*
                            (cons (cons lemma class)
                                  (remove lemma *noun-classes* :key #'car :test #'string=)))))
       (:marker (destructuring-bind (k lemma pred value) e
                  (declare (ignore k))
                  (setf *markers*
                        (cons (list lemma pred value)
                              (remove lemma *markers* :key #'first :test #'string=)))))
       (:adjective (destructuring-bind (k lemma cat) e
                     (declare (ignore k))
                     (setf *adjectives*
                           (cons (cons lemma cat)
                                 (remove lemma *adjectives* :key #'car :test #'string=)))))
       (:concept (destructuring-bind (k head adj-lemmas pred value) e
                   (declare (ignore k))
                   (let ((key (cons head (sort (copy-list adj-lemmas) #'string<))))
                     (setf *concepts*
                           (cons (list key pred value)
                                 (remove key *concepts* :key #'first :test #'equal)))))))))
 :snapshot (lambda () (list (copy-tree *verb-frames*)
                            (copy-tree *noun-classes*)
                            (copy-tree *markers*)
                            (copy-tree *adjectives*)
                            (copy-tree *concepts*)))
 :restore  (lambda (st) (destructuring-bind (vf nc mk &optional aj cn) st
                          (setf *verb-frames* vf *noun-classes* nc
                                *markers* mk *adjectives* aj *concepts* cn))))

;;; ── Τμηματοποίηση ──

(defun %split-sentences (text)
  (let ((sentences '()) (start 0))
    (loop for i from 0 below (length text)
          when (member (char text i) '(#\. #\; #\! #\? #\·))
            do (let ((s (string-trim " " (subseq text start i))))
                 (when (plusp (length s)) (push s sentences))
                 (setf start (1+ i))))
    (let ((s (string-trim " " (subseq text start))))
      (when (plusp (length s)) (push s sentences)))
    (nreverse sentences)))

(defun %content-token-p (token)
  "Λέξη ΠΕΡΙΕΧΟΜΕΝΟΥ (κλειστές γραμματικές κλάσεις στην έδρα της γλώσσας)."
  (content-lemma-p (or (known-lemma token) token)))

;; Η άρνηση έχει ΜΙΑ έδρα: orchestrator.citation-authority:+negators+ (γλωσσική
;; βάση). Η παλιά τοπική +negation-lemmas+ ΔΙΑΓΡΑΦΗΚΕ (διπλή έδρα). Ομοίως η γνώση
;; άρθρο→πτώση ζει ΑΠΟΚΛΕΙΣΤΙΚΑ στο *article-table*· οι +accusative/+nominative/
;; +genitive-articles+ ΔΙΑΓΡΑΦΗΚΑΝ.
(defparameter +prepositions+
  '("με" "σε" "από" "για" "προς" "κατά" "χωρίς" "δίχως" "μετά" "πριν" "ως" "έως"
    "μέχρι" "παρά" "αντί" "λόγω" "ένεκα" "στη" "στην" "στο" "στον" "στα" "στους"
    "στις" "εκ" "εξ" "ενώ")
  "Κλειστή κλάση προθέσεων/συνδέσμων: ΟΡΙΖΟΥΝ πλάγια φράση (PP) — το αντικείμενό
   τους ΔΕΝ είναι πυρηνικό όρισμα.")
(defparameter +phrase-negators+ '("χωρίς" "δίχως")
  "Προθέσεις ΑΠΟΚΛΕΙΣΜΟΥ: «χωρίς τη συναίνεση» ΑΝΑΙΡΕΙ τον όρο (καμία σιωπηλή
   αθώωση). Ελέγχονται με ΦΡΑΓΜΕΝΟ look-back πριν το ΝΡ του όρου
   (%phrase-negated-p) — δηλωμένα προσέγγιση, ΟΧΙ πλήρες δομικό c-command.")

;;; ── Ονοματοδοσία οντοτήτων (ΑΜΕΤΑΒΛΗΤΗ σύμβαση: λήμμα-λεξικού ή ανάκτηση
;;;    ονομαστικής κύριου ονόματος, ΚΑΝΟΝΙΚΟΠΟΙΗΜΕΝΗ) ──

(defun %recover-nominative (surface article)
  "Ανακτά την ΟΝΟΜΑΣΤΙΚΗ κύριου ονόματος από πλάγια πτώση, με βάση το οριστικό
   άρθρο — ώστε «ο Γιώργος»/«τον Γιώργο»/«του Γιώργου» = ΜΙΑ οντότητα (συναναφορά).
   ΔΗΛΩΜΕΝΑ best-effort για κύρια ονόματα· άγνωστο άρθρο ⇒ αμετάβλητο."
  (let ((n (normalize-greek surface))
        (a (and article (normalize-greek article)))
        (len (length surface)))
    (flet ((ends (suf) (let ((k (length suf)))
                         (and (>= (length n) k) (string= suf n :start2 (- (length n) k)))))
           (chop (k) (subseq surface 0 (- len k))))
      (cond
        ((or (null a) (zerop len)) surface)
        ((string= a "τον")
         (if (find (char n (1- (length n))) "αεηιουω")
             (concatenate 'string surface "ς") surface))
        ((and (string= a "του") (ends "ου")) (concatenate 'string (chop 2) "ος"))
        ((and (string= a "της") (or (ends "ας") (ends "ης"))) (chop 1))
        (t surface)))))

(defun %entity* (tokens i)
  "Οντότητα από τη θέση I, ΚΑΝΟΝΙΚΟΠΟΙΗΜΕΝΗ σε ονομαστική: λήμμα-λεξικού αν είναι
   γνωστό, αλλιώς ανάκτηση ονομαστικής κύριου ονόματος από το προηγούμενο άρθρο."
  (let* ((token (nth i tokens))
         (l (known-lemma token)))
    (if l
        (intern (string-upcase l) :keyword)
        (intern (string-upcase
                 (normalize-greek
                  (%recover-nominative token (when (> i 0) (nth (1- i) tokens)))))
                :keyword))))

;;; ── Λεξικό άρθρων με ΠΛΗΡΗ χαρακτηριστικά (η ΜΙΑ έδρα του, feature-bearing) ──
(defparameter *article-table*
  (let ((h (make-hash-table :test 'equal)))
    (flet ((a (k &rest cases) (setf (gethash (normalize-greek k) h) cases)))
      (a "ο" :nom)   (a "η" :nom)   (a "οι" :nom)
      (a "τον" :acc) (a "την" :acc) (a "τους" :acc) (a "τις" :acc)
      (a "το" :nom :acc) (a "τα" :nom :acc)          ; ουδέτερα αμφίσημα (nom=acc)
      (a "του" :gen) (a "της" :gen) (a "των" :gen)
      (a "τη" :acc))                                 ; «τη συναίνεση» (καθομιλουμένη)
    h)
  "normalize(άρθρο) → σύνολο πτώσεων. Τα ουδέτερα «το/τα» φέρουν {nom,acc}: τα
   αμφίσημα άρθρα ΔΕΝ οδηγούν ρόλο (%case-of ⇒ nil) — δηλωμένο όριο· τα καλύπτει
   η θεσιακή εφεδρεία του %role-indices.")

;;; ── Λεξική ταξινόμηση ──
(defun %morph-lemma (surface)
  "Λήμμα από τη μορφολογία-χαρακτηριστικών αν είναι μονοσήμαντο, αλλιώς από το
   λεξικό known-lemma, αλλιώς nil. ΓΙΑ ΤΑΙΡΙΑΣΜΑ (concepts/noun-class/adj) — ΟΧΙ για
   ονοματοδοσία (εκείνη μένει %entity*)."
  (let ((m (morph-lemma surface)))
    (if (stringp m) m (known-lemma surface))))

;;; ── Πτώση από το ΑΡΘΡΟ (η ΜΙΑ έδρα *article-table*) ──
(defun %article-cases (tok) (and tok (gethash (normalize-greek tok) *article-table*)))
(defun %genitive-article-p (tok) (equal '(:gen) (%article-cases tok)))
(defun %nominative-article-p (tok) (equal '(:nom) (%article-cases tok)))
(defun %article-skip-p (tok) (and (%article-cases tok) t))

(defun %case-of (tokens i)
  "Μονοσήμαντη πτώση του περιεχομένου στη θέση I από το ΠΡΟΗΓΟΥΜΕΝΟ άρθρο:
   :nom | :acc | :gen· nil αν το άρθρο είναι αμφίσημο (ουδέτερα το/τα) ή απόν —
   η αμφισημία ΔΕΝ οδηγεί ρόλο (δηλωμένο όριο, ταυτόσημο με το OLD base)."
  (when (> i 0)
    (let ((cases (%article-cases (nth (1- i) tokens))))
      (when (and cases (= (length cases) 1)) (first cases)))))

;;; ── ΘΕΣΙΑΚΟΙ/ΜΟΡΦΟΛΟΓΙΚΟΙ ρόλοι (whole-clause, OLD base — robust σε κόμματα/PP) ──
(defun %content-indices (tokens lo hi)
  "Δείκτες λέξεων περιεχομένου στο [LO, HI) — με τη σειρά τους."
  (loop for i from lo below hi when (%content-token-p (nth i tokens)) collect i))

(defun %role-indices (tokens vpos)
  "(values δείκτης-δράστη δείκτης-θέματος): πρώτα ΜΟΡΦΟΛΟΓΙΚΑ (ονομαστική=δράστης,
   αιτιατική=θέμα — «τον Α σκότωσε ο Β» σωστά)· αλλιώς ΘΕΣΙΑΚΑ (δράστης=τελευταίο
   περιεχόμενο πριν το ρήμα, θέμα=πρώτο μετά)."
  (let (nom acc)
    (loop for i from 0 below (length tokens)
          when (and (/= i vpos) (%content-token-p (nth i tokens)))
            do (case (%case-of tokens i)
                 (:nom (unless nom (setf nom i)))
                 (:acc (unless acc (setf acc i)))))
    (values (or nom (let ((cs (%content-indices tokens 0 vpos))) (car (last cs))))
            (or acc (first (%content-indices tokens (1+ vpos) (length tokens)))))))

(defun %post-verb-np (tokens vpos)
  "(values κεφαλή-index τροποποιητές-indices): η ΠΡΩΤΗ ονοματική φράση ΑΝΤΙΚΕΙΜΕΝΟΥ
   αμέσως μετά το ρήμα (άρθρα ονομ./αιτ. αγνοούνται, επίθετα+κεφαλή) ΩΣΠΟΥ πρόθεση /
   άρθρο ΓΕΝΙΚΗΣ / δείκτης / άλλο ρήμα-πλαίσιο. ΚΕΦΑΛΗ = ΤΕΛΕΥΤΑΙΑ λέξη περιεχομένου
   του NP (θάνατος του «θέμα=πρώτο επίθετο»). nil αν δεν υπάρχει NP αμέσως."
  (let ((content '()))
    (loop for i from (1+ vpos) below (length tokens)
          for tk = (nth i tokens)
          for l = (known-lemma tk)
          do (cond
               ((or (member (normalize-greek tk) +prepositions+
                            :key #'normalize-greek :test #'string=)
                    (%genitive-article-p tk)
                    (and l (assoc l *markers* :test #'string=))
                    (and l (assoc l *verb-frames* :test #'string=)))
                (return))
               ((%content-token-p tk) (push i content))
               (t nil)))
    (let ((idxs (nreverse content)))
      (values (car (last idxs)) (butlast idxs)))))

(defun %genitive-owner-index (tokens vpos)
  "Δείκτης ΚΤΗΤΟΡΑ: πρώτο περιεχόμενο μετά το ρήμα με ΠΡΟΗΓΟΥΜΕΝΟ άρθρο γενικής."
  (loop for i from (1+ vpos) below (length tokens)
        when (and (%content-token-p (nth i tokens)) (> i 0)
                  (%genitive-article-p (nth (1- i) tokens)))
          return i))

;;; ── Άρνηση (η ΜΙΑ έδρα +negators+ [0080]) ──
(defun %negated-p (before)
  "Άρνηση του ρήματος: δείκτης άρνησης ΠΡΙΝ το ρήμα-πλαίσιο (ίδια πρόταση)."
  (some (lambda (tk)
          (member (normalize-greek (or (known-lemma tk) tk)) +negators+ :test #'string=))
        before))

(defun %phrase-negated-p (tokens start)
  "ΠΡΙΝ τη φράση (θέση START) υπάρχει αναιρετής («χωρίς/δίχως») ή δείκτης άρνησης
   («δεν/μη/…») εντός άμεσης εμβέλειας; ⇒ ο όρος ΔΕΝ ισχύει καταφατικά. Εμβέλεια
   (bounded): προσπερνά άρθρα + προθέσεις + ΕΝΑ κυβερνών ρήμα· σταματά στην πρώτη
   άλλη λέξη. Θάνατος του Q2a («χωρίς τη συναίνεση» / «δεν τελούσε σε άμυνα»)."
  (let ((budget 1))
    (loop for i from (1- start) downto 0
          for tok = (nth i tokens)
          do (cond
               ((or (member (normalize-greek tok) +phrase-negators+
                            :key #'normalize-greek :test #'string=)
                    (member (normalize-greek (or (known-lemma tok) tok)) +negators+
                            :test #'string=))
                (return t))
               ((%article-skip-p tok))
               ((member (normalize-greek tok) +prepositions+
                        :key #'normalize-greek :test #'string=))
               ((plusp budget) (decf budget))
               (t (return nil))))))

;;; ── Νομικοί όροι-τέχνης ως ΣΥΣΤΑΤΙΚΑ, κλειδωμένοι σε ΛΗΜΜΑΤΑ (κέρδος [0079] #13) ──
(defun %np-span-start (tokens i)
  "Αριστερότερος δείκτης του συνεχόμενου ΝΡ που κλείνει στην κεφαλή I (προσπερνά
   άρθρα, μαζεύει περιεχόμενο· σταματά σε πρόθεση/στίξη/μη-ΝΡ)."
  (let ((start i))
    (loop for j from (1- i) downto 0
          for tk = (nth j tokens)
          do (cond ((%article-skip-p tk) (setf start j))
                   ((%content-token-p tk) (setf start j))
                   (t (return))))
    start))

(defun %concept-facts (tokens agent)
  "Για κάθε concept ((ΚΕΦΑΛΗ-λήμμα . ΕΠΙΘΕΤΑ-λήμματα) pred value): αν υπάρχει token
   με %morph-lemma=ΚΕΦΑΛΗ, ΜΗ αναιρεμένο, και τα ΕΠΙΘΕΤΑ-λήμματα εμφανίζονται στο ΝΡ
   πριν την κεφαλή ⇒ (:γεγονός ΔΡΑΣΤΗΣ pred value). Το ταίριασμα σε ΛΗΜΜΑΤΑ (μέσω της
   [0078] μορφολογίας) ΓΕΝΙΚΕΥΕΙ στην κλίση: «νόμιμης άμυνας» ≡ «νόμιμη άμυνα» — το
   κέρδος που ΕΧΑΝΕ το exact-substring MWE του OLD base."
  (let ((facts '()))
    (dolist (c *concepts* facts)
      (destructuring-bind ((head . adjs) pred value) c
        (loop for i from 0 below (length tokens)
              when (equal (%morph-lemma (nth i tokens)) head)
                do (let* ((start (%np-span-start tokens i))
                          (mods (loop for j from start below i
                                      for l = (and (%content-token-p (nth j tokens))
                                                   (%morph-lemma (nth j tokens)))
                                      when l collect l)))
                     (when (and (subsetp adjs mods :test #'string=)
                                (not (%phrase-negated-p tokens start)))
                       (pushnew (list :γεγονός agent pred value) facts :test #'equal))))))))

;;; ── Συντονισμός ΑΝΕΞΑΡΤΗΤΩΝ προτάσεων (κέρδος [0079] #17), OVS-safe ──
(defun %split-coordinate (tokens)
  "Χωρίζει ΜΟΝΟ γνήσια συντονισμένες ΑΝΕΞΑΡΤΗΤΕΣ προτάσεις: «… ΚΑΙ <ονομ.άρθρο>
   <υποκ> … <ρήμα> …» ⇒ δύο clauses. ΔΕΝ σπάει: VP-συντονισμό («αφαίρεσε ΚΑΙ
   θανάτωσε» — μετά το «και» ρήμα, όχι ονομ.άρθρο), NP-συντονισμό («εργαλεία ΚΑΙ τα
   αντικείμενα» — «τα» αμφίσημο, όχι καθαρή ονομαστική), υποτακτικές (ενώ/αλλά).
   ⇒ «Ο δράστης, ενώ …, θανάτωσε» ΜΕΝΕΙ ΕΝΙΑΙΟ (καμία απώλεια, OVS-safe)."
  (labels ((has-frame-verb (toks)
             (position-if (lambda (tk) (let ((l (known-lemma tk)))
                                         (and l (assoc l *verb-frames* :test #'string=))))
                          toks)))
    (loop for k from 1 below (length tokens)
          when (and (string= (normalize-greek (nth k tokens)) "και")
                    (< (1+ k) (length tokens))
                    (%nominative-article-p (nth (1+ k) tokens))
                    (has-frame-verb (subseq tokens 0 k))
                    (has-frame-verb (subseq tokens (1+ k))))
            do (return-from %split-coordinate
                 (cons (subseq tokens 0 k) (%split-coordinate (subseq tokens (1+ k))))))
    (list tokens)))

;;; ── Ανάλυση ΠΡΟΤΑΣΗΣ (whole-clause SVO-G, OLD base) ──
(defun %parse-clause-tokens (tokens)
  "(values γεγονότα αναγνωρίστηκε-p): πλαίσιο πτώσεων SVO(G) — δράστης/θέμα κατά
   ΜΟΡΦΟΛΟΓΙΑ (άρθρο) με θεσιακή εφεδρεία· θέμα=ΚΕΦΑΛΗ post-verb NP (fronted acc =
   OVS)· κτήτορας από γενική ⇒ ΞΕΝΟ· επίθετα→κλάσεις· δείκτες+concepts στον δράστη·
   ΑΡΝΗΣΗ ρητή (κανένα καταφατικό/παράγωγο για αρνημένη πράξη). Robust: ΔΕΝ σπάει σε
   κόμματα/PP — το υποκείμενο/αντικείμενο μπορεί να απέχει από το ρήμα."
  (let ((vpos (position-if (lambda (tk) (let ((l (known-lemma tk)))
                                          (and l (assoc l *verb-frames* :test #'string=))))
                           tokens)))
    (if (null vpos)
        (values '() nil)
        (let* ((pred (cdr (assoc (known-lemma (nth vpos tokens)) *verb-frames* :test #'string=)))
               (before (subseq tokens 0 vpos))
               (negated (%negated-p before))
               (owner-i (%genitive-owner-index tokens vpos))
               (owner-tok (and owner-i (nth owner-i tokens)))
               (facts '()))
          (multiple-value-bind (agent-i theme-i0) (%role-indices tokens vpos)
            (multiple-value-bind (np-head np-mods) (%post-verb-np tokens vpos)
              (let* ((frontedp (and theme-i0 (< theme-i0 vpos)))
                     (theme-i (if frontedp theme-i0 (or np-head theme-i0)))
                     (np-mods (if (and (not frontedp) np-head) np-mods '())))
                (when (and agent-i theme-i)
                  (let ((agent (%entity* tokens agent-i))
                        (theme (%entity* tokens theme-i))
                        (theme-tok (nth theme-i tokens)))
                    (if negated
                        (setf facts (list (list :άρνηση agent pred theme)))
                        (progn
                          (push (list :γεγονός agent pred theme) facts)
                          ;; κατηγορία θέματος (Barbara)
                          (let* ((tl (known-lemma theme-tok))
                                 (class (and tl (cdr (assoc tl *noun-classes* :test #'string=)))))
                            (when class (push (list :γεγονός theme :είναι class) facts)))
                          ;; κτήτορας ≠ δράστης ⇒ ΞΕΝΟ
                          (when (and owner-i
                                     (let ((ol (%entity* tokens owner-i)))
                                       (and (not (eq ol agent))
                                            (not (assoc (or (known-lemma owner-tok) "")
                                                        *markers* :test #'string=))
                                            (not (assoc (or (known-lemma owner-tok) "")
                                                        *verb-frames* :test #'string=)))))
                            (push (list :γεγονός theme :ανήκει-σε (%entity* tokens owner-i)) facts)
                            (push (list :γεγονός theme :είναι :ξένο) facts))
                          ;; επίθετα ΝΡ → κλάσεις θέματος
                          (dolist (mi np-mods)
                            (let* ((ml (known-lemma (nth mi tokens)))
                                   (cls (and ml (cdr (assoc ml *adjectives* :test #'string=)))))
                              (when cls (pushnew (list :γεγονός theme :είναι cls) facts :test #'equal))))
                          ;; δείκτες (σκοπός/τρόπος) οπουδήποτε → γεγονός ΔΡΑΣΤΗ
                          (dolist (tk tokens)
                            (let* ((l (known-lemma tk)) (m (and l (assoc l *markers* :test #'string=))))
                              (when m (pushnew (list :γεγονός agent (second m) (third m))
                                               facts :test #'equal))))
                          ;; νομικοί όροι-τέχνης (κλιτοί, κέρδος #13) → γεγονός ΔΡΑΣΤΗ
                          (dolist (f (%concept-facts tokens agent))
                            (pushnew f facts :test #'equal)))))))
              (values (nreverse facts) t)))))))

(defun %parse-sentence (sentence)
  "(values γεγονότα αναγνωρίστηκε-p): συντονισμός ανεξάρτητων προτάσεων (κέρδος #17)
   → κάθε αυτοτελής clause περνά από το whole-clause SVO-G (OLD base)."
  (let ((facts '()) (any nil))
    (dolist (cl (%split-coordinate (tokenize-greek sentence)))
      (multiple-value-bind (fs ok) (%parse-clause-tokens cl)
        (when ok (setf any t))
        (dolist (f fs) (pushnew f facts :test #'equal))))
    (values (nreverse facts) any)))

;;; ── Σ12β: ΟΡΙΣΜΟΙ ΝΟΜΟΥ (ταξινομία γένους-είδους) ──

(defparameter +definitional-markers+
  '("νοειται" "νοουνται" "θεωρειται" "θεωρουνται" "λογιζεται" "λογιζονται"
    "καλειται" "καλουνται" "ονομαζεται" "ονομαζονται")
  "Οι κλειστές ελληνικές ΟΡΙΣΤΙΚΕΣ διατυπώσεις του νόμου — η ΜΙΑ έδρα τους.")

(defun %def-entity (token)
  "Οντότητα ορισμού: λήμμα αν είναι γνωστό, αλλιώς η λέξη όπως στο κείμενο."
  (or (known-lemma token) (string-downcase token)))

(defun parse-definition (sentence term)
  "Από ΟΡΙΣΤΙΚΗ πρόταση νόμου («Γένος θεωρούνται (και) τα Είδη που…»): υποψήφια
   γεγονότα ταξινομίας (:γένος είδος γένος). ΔΗΛΩΜΕΝΟ ΟΡΙΟ: ονοματική φράση γένους
   ≤ 2 λέξεις περιεχομένου. Επιστρέφει tuples — ΠΟΤΕ χωρίς έγκριση δημιουργού (Σ11)."
  (let* ((stem (or (surface-stem term) (normalize-greek term)))
         (toks (tokenize-greek sentence))
         (folded (mapcar #'normalize-greek toks))
         (vpos (position-if (lambda (w) (member w +definitional-markers+ :test #'string=))
                            folded))
         (tpos (and stem
                    (position-if (lambda (w)
                                   (and (>= (length w) (length stem))
                                        (string= stem w :end2 (length stem))))
                                 folded))))
    (when (and vpos tpos (/= vpos tpos))
      (let* ((species (intern (string-upcase (or (known-lemma (nth tpos toks))
                                                 (string-downcase term)))
                              :keyword))
             (genus-toks
               (if (> tpos vpos)
                   (let ((acc '()))
                     (loop for i downfrom (1- vpos) to 0
                           for tk = (nth i toks)
                           while (< (length acc) 2)
                           do (if (%content-token-p tk) (push tk acc) (return))
                           finally (return))
                     acc)
                   (let ((acc '()))
                     (loop for i from (1+ vpos) below (length toks)
                           for tk = (nth i toks)
                           while (< (length acc) 2)
                           do (if (%content-token-p tk) (push tk acc)
                                  (when acc (return))))
                     (nreverse acc)))))
        (when genus-toks
          (let* ((parts (mapcar #'%def-entity genus-toks))
                 (genus (intern (string-upcase (format nil "~{~A~^-~}" parts)) :keyword))
                 (head-tok (first (last genus-toks)))
                 (head-lemma (known-lemma head-tok))
                 (differentia
                   (let ((rel (position "που" folded :test #'string=
                                        :start (1+ tpos)
                                        :end (min (length folded) (+ tpos 3)))))
                     (when rel
                       (let* ((vtok (loop for i from (1+ rel) below (length toks)
                                          for tk = (nth i toks)
                                          when (and (%content-token-p tk)
                                                    (let ((l (known-lemma tk)))
                                                      (and l (member (char l (1- (length l)))
                                                                     '(#\ω #\ώ)))))
                                            return (list i (known-lemma tk))))
                              (stok (and vtok
                                         (loop for i from (1+ (first vtok)) below (length toks)
                                               for tk = (nth i toks)
                                               when (%content-token-p tk)
                                                 return (%def-entity tk)))))
                         (when (and vtok stok)
                           (list (intern (string-upcase
                                          (format nil "~Aείται-από"
                                                  (subseq (second vtok) 0
                                                          (1- (length (second vtok))))))
                                         :keyword)
                                 (intern (string-upcase stok) :keyword)))))))
                 (out (list (if differentia
                                (list* :γένος-όταν species genus differentia)
                                (list :γένος species genus)))))
            (when (and (> (length parts) 1) head-lemma)
              (push (list :γένος genus
                          (intern (string-upcase head-lemma) :keyword))
                    out))
            (nreverse out)))))))

(defparameter +month-genitives+
  '(("ιανουαριου" . 1) ("φεβρουαριου" . 2) ("μαρτιου" . 3) ("απριλιου" . 4)
    ("μαιου" . 5) ("ιουνιου" . 6) ("ιουλιου" . 7) ("αυγουστου" . 8)
    ("σεπτεμβριου" . 9) ("οκτωβριου" . 10) ("νοεμβριου" . 11) ("δεκεμβριου" . 12))
  "Οι γενικές των μηνών (κανονικοποιημένες) — «στις 10 Ιανουαρίου 2026».")

(defun %sentence-date (sentence)
  "Η ημερομηνία μιας πρότασης ως ISO «YYYY-MM-DD», ή nil. ΔΕΝ επικυρώνεται εδώ —
   την εγκυρότητα την κρίνει ο ημερολογιακός λογισμός (μία έδρα επικύρωσης)."
  (let ((n (normalize-greek sentence)))
    (or (cl-ppcre:register-groups-bind (y m d)
            ("(\\d{4})-(\\d{2})-(\\d{2})" n)
          (format nil "~A-~A-~A" y m d))
        (cl-ppcre:register-groups-bind (d m y)
            ("(\\d{1,2})[/-](\\d{1,2})[/-](\\d{4})" n)
          (format nil "~A-~2,'0D-~2,'0D" y (parse-integer m) (parse-integer d)))
        (cl-ppcre:register-groups-bind (d mon y)
            ("(\\d{1,2})(?:ησ?)? +([α-ω]+) +(\\d{4})" n)
          (let ((mm (cdr (assoc mon +month-genitives+ :test #'string=))))
            (when mm (format nil "~A-~2,'0D-~2,'0D" y mm (parse-integer d))))))))

(defun parse-narrative (text)
  "(values γεγονότα μη-αναγνωσμένες-προτάσεις χρονολόγιο): κάθε πρόταση περνά από τη
   γραμματική πτώσεων (whole-clause SVO-G)· ό,τι δεν αναγνωρίζεται ΔΗΛΩΝΕΤΑΙ. Το
   χρονολόγιο: (iso-ημερομηνία . πρόταση) για ΚΑΘΕ πρόταση με ημερομηνία."
  (let ((facts '()) (unparsed '()) (timeline '()))
    (dolist (s (%split-sentences text))
      (let ((d (%sentence-date s)))
        (when d (push (cons d s) timeline)))
      (multiple-value-bind (fs ok) (%parse-sentence s)
        (if (and ok fs)
            (dolist (f fs) (pushnew f facts :test #'equal))
            (push s unparsed))))
    (values (nreverse facts) (nreverse unparsed) (nreverse timeline))))

(defun narrative-report (text &key (stream *standard-output*))
  "Αφήγηση → γεγονότα (τυπωμένα) → ΥΠΑΓΩΓΗ. Τα μη-αναγνωσμένα δηλώνονται."
  (multiple-value-bind (facts unparsed) (parse-narrative text)
    (format stream "~%── ΑΝΑΓΝΩΣΗ ΑΦΗΓΗΣΗΣ: ~D γεγονότα ──~%" (length facts))
    (dolist (f facts) (format stream "  • ~S~%" f))
    (dolist (u unparsed)
      (format stream "  ⚠ ΔΕΝ αναγνωρίστηκε (καμία εικασία): «~A»~%" u))
    (if (null facts)
        (progn (format stream "  Καμία αναγνωρισμένη πράξη — δεν χωρεί υπαγωγή.~%") 1)
        (progn (orchestrator.subsumption:subsumption-report facts) 0))))

;;; ── Σ12α: ΑΝΑΓΝΩΣΗ ΔΙΑΤΑΞΗΣ ΣΕ ΚΑΝΟΝΑ — η σύνταξη του νομοθέτη ──

(defparameter +sanction-modality+
  '(("τιμωρειται" . :prohibition) ("τιμωρουνται" . :prohibition)
    ("υποχρεουται" . :obligation) ("υποχρεουνται" . :obligation)
    ("δικαιουται" . :permission)  ("δικαιουνται" . :permission))
  "Ρήμα κύρωσης → δεοντική τροπικότητα (κλειστή τάξη).")

(defun %strip-parentheticals (text)
  "Οι παρενθέσεις του νομοθέτη είναι παρεμβολές — αφαιρούνται ΔΗΛΩΜΕΝΑ πριν τη
   συντακτική ανάλυση (α΄ κύμα: δεν διαβάζονται, δεν σπάνε την ονοματική φράση)."
  (with-output-to-string (o)
    (let ((depth 0))
      (loop for ch across text
            do (cond ((char= ch #\() (incf depth))
                     ((char= ch #\)) (when (plusp depth) (decf depth)))
                     ((zerop depth) (write-char ch o)))))))

(defun parse-provision (text* &key heading)
  "(values spec|nil λόγος): SPEC = plist (:modality :antecedent :consequent :act
   :caveats) από τη σύνταξη «όποιος … κύρωση». Ό,τι δεν διαβάζεται ΟΝΟΜΑΖΕΤΑΙ."
  (let* ((text (%strip-parentheticals text*))
         (toks (tokenize-greek text))
         (folded (mapcar #'normalize-greek toks))
         (opos (position "οποιοσ" folded :test #'string=))
         (spos (position-if (lambda (w) (assoc w +sanction-modality+ :test #'string=))
                            folded)))
    (cond
      ((null opos) (values nil "δεν βρίσκω «όποιος» — άλλο συντακτικό σχήμα (β΄ κύμα)"))
      ((null spos) (values nil "δεν βρίσκω ρήμα κύρωσης (τιμωρείται/υποχρεούται/δικαιούται)"))
      ((> opos spos) (values nil "το «όποιος» έπεται της κύρωσης — σχήμα εκτός α΄ κύματος"))
      (t
       (let* ((modality (cdr (assoc (nth spos folded) +sanction-modality+ :test #'string=)))
              (vpos (loop for i from (1+ opos) below spos
                          for l = (known-lemma (nth i toks))
                          when (and l (assoc l *verb-frames* :test #'string=))
                            return i))
              (pred (and vpos (cdr (assoc (known-lemma (nth vpos toks))
                                          *verb-frames* :test #'string=)))))
         (if (null vpos)
             (values nil "κανένα γνωστό ρήμα-πλαίσιο μετά το «όποιος» — χρειάζεται :frame στο πακέτο"
                     (loop for i from (1+ opos) below spos
                           for tk = (nth i toks)
                           when (%content-token-p tk)
                             return (normalize-greek tk)))
             (let ((cats '()) (head nil) (facts '()) (caveats '()))
               (loop for i from (1+ vpos) below spos
                     for tk = (nth i toks)
                     for l = (known-lemma tk)
                     while (null head)
                     do (cond ((and l (assoc l *adjectives* :test #'string=))
                               (push (cdr (assoc l *adjectives* :test #'string=)) cats))
                              ((and (%content-token-p tk)
                                    (not (and l (assoc l *markers* :test #'string=))))
                               (setf head (or l (normalize-greek tk))))))
               (unless head
                 (return-from parse-provision
                   (values nil "δεν βρίσκω κεφαλή ονοματικής φράσης αντικειμένου")))
               (push (list :γεγονός :?δράστης pred :?πράγμα) facts)
               (dolist (c (nreverse cats))
                 (push (list :γεγονός :?πράγμα :είναι c) facts))
               (loop for i from (1+ vpos) below spos
                     for l = (known-lemma (nth i toks))
                     for m = (and l (assoc l *markers* :test #'string=))
                     when m do (pushnew (list :γεγονός :?δράστης (second m) (third m))
                                        facts :test #'equal))
               (when (search "εκτοσ αν" (format nil "~{~A ~}" folded))
                 (push "η διάταξη έχει «εκτός αν …» — οι λόγοι άρσης θέλουν χέρι δημιουργού" caveats))
               (values (list :modality modality
                             :antecedent (nreverse facts)
                             :consequent (list :πράξη :?δράστης
                                               (%act-keyword heading pred) :?πράγμα)
                             :act (%act-keyword heading pred)
                             :caveats caveats)
                       nil))))))))

(defun %act-keyword (heading pred)
  "Το όνομα της πράξης: το πρώτο λήμμα περιεχομένου του ΤΙΤΛΟΥ του άρθρου, αλλιώς
   από το κατηγόρημα του ρήματος."
  (or (and heading
           (loop for tk in (tokenize-greek heading)
                 for l = (known-lemma tk)
                 when (and l (content-lemma-p l)
                           (not (member (normalize-greek l) '("αρθρο") :test #'string=)))
                   return (intern (string-upcase l) :keyword)))
      (intern (string-upcase (format nil "πράξη-~A" pred)) :keyword)))
